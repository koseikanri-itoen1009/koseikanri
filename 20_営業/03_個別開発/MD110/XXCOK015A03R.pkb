CREATE OR REPLACE PACKAGE BODY XXCOK015A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A03R(body)
 * Description      : �x����̌ڋq���⍇�����������ꍇ�A
 *                    ��������ʂ̋��z���󎚂��ꂽ�x���ē�����������܂��B
 * MD.050           : �x���ē�������i���ׁj MD050_COK_015_A03
 * Version          : 1.16
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  delete_xbsrw         �o�͑Ώۃ��[�N�폜(A-10)
 *  delete_xrbpd         ���[�N�e�[�u���f�[�^�폜(A-7)
 *  start_svf            SVF�N��(A-6)
 *  update_xrbpd         �x���ē����i���ׁj���[���[�N�e�[�u���X�V(A-5)
 *  get_xrbpd            ���[�N�e�[�u���x���斈�W��f�[�^�擾(A-4)
 *  insert_xrbpd         �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
 *  init                 ��������(A-1)
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   K.Yamaguchi      �V�K�쐬
 *  2009/02/18    1.1   K.Yamaguchi      [��QCOK_045] �ŐV�̎d����T�C�g�����擾����悤�ύX
 *                                                     ���̓p�����[�^�̏�����ύX�iYYYYMM => YYYY/MM�j
 *  2009/03/03    1.2   M.Hiruta         [��QCOK_067] �e��敪�擾���@�ύX
 *  2009/05/11    1.3   K.Yamaguchi      [��QT1_0841] �x���z�i�ō��j�̎擾���@��ύX
 *                                       [��QT1_0866] �{�U�i�ē�������j�̏ꍇ�̒��o������ύX
 *  2009/05/25    1.4   M.Hiruta         [��QT1_1168] �x���ē���(����)�̔��s�����V�X�e�����t����Ɩ��������t�֕ύX
 *  2009/09/10    1.5   S.Moriyama       [��Q0000060] �Z���̌����ύX�Ή�
 *  2009/10/14    1.6   S.Moriyama       [�ύX�˗�I_E_573] �d���於�́A�Z���̐ݒ���e�ύX�Ή�
 *  2009/12/15    1.7   K.Nakamura       [��QE_�{�ғ�_00477] �x���ۗ�����BM�A�܂��̔��萔����0�~�̏ꍇ�́A�o�͂��Ȃ��悤�C��
 *  2010/03/02    1.8   S.Moriyama       [��QE_�{�ғ�_01299] �g�ݖ߂���̖{�U�c���o�͑Ή�
 *  2010/03/16    1.9   S.Moriyama       [��QE_�{�ғ�_01897] �U���萔���o�͑Ή�
 *  2010/04/06    1.9   K.Yamaguchi      [��QE_�{�ғ�_01897] �������Q�̃V�X�e���e�X�g�Ŕ��o������Q
 *                                                            �U���萔�����S�҂��ݒ肳��Ă��Ȃ��ꍇ���l��
 *  2011/01/05    1.10  S.Niki           [��QE_�{�ғ�_01950] �\�[�g����{���R�[�h�A���㋒�_�R�[�h�A���������A�ڋq�R�[�h�ɕύX
 *  2011/03/28    1.11  S.Ochiai         [��QE_�{�ғ�_05408,05409] �N���֑ؑΉ�
 *  2017/12/29    1.12  K.Nara           [��QE_�{�ғ�_14789] �����Z���_�[�Ή�
 *  2018/01/18    1.13  K.Nara           [��QE_�{�ғ�_14836] �����Z���_�[�Ή��i�{�U�ē����Ȃ��j
 *  2018/02/27    1.14  N.Watanabe       [��QE_�{�ғ�_14897] �x���ē���PT�Ή�
 *  2018/03/15    1.15  Y.Sekine         [��QE_�{�ғ�_14900] �����Z���^�[�Č��i�x���ē����o�͕ύX�j
 *  2018/07/17    1.16  K.Nara           [��QE_�{�ғ�_15005] �����Z���^�[�Č��i�x���ē����A�̔��񍐏��ꊇ�o�́j
 *
 *****************************************************************************************/
  --==================================================
  -- �O���[�o���萔
  --==================================================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03R';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- ����I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
  cv_msg_cok_00003                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00085                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00085';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00086';
  cv_msg_cok_00087                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00087';
  cv_msg_cok_00040                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00040';
  cv_msg_cok_10309                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10309';
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  cv_msg_cok_10545                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10545';
  cv_msg_cok_10546                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10546';
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  -- �g�[�N��
  cv_tkn_errmsg                    CONSTANT VARCHAR2(30)    := 'ERRMSG';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_base_code                 CONSTANT VARCHAR2(30)    := 'BASE_CODE';
  cv_tkn_target_ym                 CONSTANT VARCHAR2(30)    := 'TARGET_YM';
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  cv_tkn_request_id                CONSTANT VARCHAR2(30)    := 'REQUEST_ID';
  cv_tkn_output_num                CONSTANT VARCHAR2(30)    := 'OUTPUT_NUM';
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  -- �Z�p���[�^
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM';   -- XXCOK:�x���ē���_�̔��萔�����o��
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_EP';   -- XXCOK:�x���ē���_�d�C�����o��
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'ORG_ID';                       -- MO: �c�ƒP��
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_FE';      -- XXCOK:�x���ē���_�U���萔��
  cv_profile_name_05               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF3_FEE';                 -- XXCOK:����Ȗ�_�萔��
  cv_profile_name_06               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF4_TRANSFER_FEE';        -- XXCOK:�⏕�Ȗ�_�萔��_�U���萔��
  cv_profile_name_07               CONSTANT VARCHAR2(50)    := 'XXCOK1_GL_CATEGORY_BM';           -- XXCOK:�d��J�e�S��_�̔��萔��
  cv_profile_name_08               CONSTANT VARCHAR2(50)    := 'XXCOK1_GL_SOURCE_COK';            -- XXCOK:�d��\�[�X_�ʊJ��
  cv_profile_name_09               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                -- GL��v����ID
  cv_profile_name_10               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION'; -- ��s�萔��_�U���z�
  cv_profile_name_11               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';  -- ��s�萔��_��z����
  cv_profile_name_12               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';  -- ��s�萔��_��z�ȏ�
  cv_profile_name_13               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_TAX';                   -- �̔��萔��_����ŗ�
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD START
  cv_profile_name_14               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF2_DEPT_JIMU';           -- XXCOK:����R�[�h_�����Z���^�[
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD END
  -- �Q�ƃ^�C�v��
-- Start 2009/03/03 M.Hiruta
--  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCMM_YOKI_KUBUN';    -- �e��敪
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCSO1_SP_RULE_BOTTLE'; -- �e��敪
-- End   2009/03/03 M.Hiruta
  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_CALC_TYPE';   -- �̎�v�Z����
  -- ���ʊ֐����b�Z�[�W�o�͋敪
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- SVF�N���p�����[�^
  cv_file_id                       CONSTANT VARCHAR2(20)    := 'XXCOK015A03R';       -- ���[ID
  cv_output_mode                   CONSTANT VARCHAR2(1)     := '1';                  -- �o�͋敪(PDF�o��)
  cv_extension                     CONSTANT VARCHAR2(10)    := '.pdf';               -- �o�̓t�@�C�����g���q(PDF�o��)
  cv_frm_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03S.vrq';   -- �N�G���[�l���t�@�C����
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  cv_excl_code                     CONSTANT VARCHAR2(10)    := 'EXCL1';              -- SVF��p�}�l�[�W���R�[�h
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  -- �����t�H�[�}�b�g
  cv_format_fxrrrrmm               CONSTANT VARCHAR2(50)    := 'FXRRRR/MM';
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRRMMDD';
  cv_format_date                   CONSTANT VARCHAR2(50)    := 'RRRR"�N"MM"��"DD"��"';
  cv_format_ee_month               CONSTANT VARCHAR2(50)    := 'EERR"�N"MM"����"';
  cv_format_ee_date                CONSTANT VARCHAR2(50)    := 'EERR"�N"MM"��"DD"��"';
  -- �e����T�|�[�g�p�����[�^
  cv_nls_param                     CONSTANT VARCHAR2(50)    := 'nls_calendar=''japanese imperial''';
  -- BM�x���敪
  cv_bm_type_1                     CONSTANT VARCHAR2(1)     := '1';                  -- �{�U�i�ē��L�j
  cv_bm_type_2                     CONSTANT VARCHAR2(1)     := '2';                  -- �{�U�i�ē����j
  cv_bm_type_3                     CONSTANT VARCHAR2(1)     := '3';                  -- AP�x��
  cv_bm_type_4                     CONSTANT VARCHAR2(1)     := '4';                  -- �����x��
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
  -- ��s�萔�����S��
  cv_bank_charge_bearer            CONSTANT VARCHAR2(1)     := 'I';                  -- ����
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  ct_rep_id_bm                     CONSTANT xxcok_bm_sales_rep_work.output_rep%TYPE := 1;   -- �x���ē���
  ct_output_num_init               CONSTANT xxcok_bm_sales_rep_work.output_num%TYPE := -1;  -- �J�����g�o�͔ԍ������l
  cv_slash                         CONSTANT VARCHAR2(1)     := '/';
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  --==================================================
  -- �O���[�o���ϐ�
  --==================================================
  -- �J�E���^
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- �ُ팏��
  -- ���̓p�����[�^
  gv_param_base_code               VARCHAR2(4)   DEFAULT NULL;  -- �⍇����
  gv_param_target_ym               VARCHAR2(7)   DEFAULT NULL;  -- �ē������s�N��
  gv_param_vendor_code             VARCHAR2(9)   DEFAULT NULL;  -- �x����
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  gn_param_request_id              NUMBER        DEFAULT NULL;  -- �v��ID
  gn_param_output_num              NUMBER        DEFAULT NULL;  -- �o�͔ԍ��i�Ώێ擾�������̂ݎg�p�j
  -- �A�b�v���[�h�l
  gt_upload_cust_code              xxcok_bm_sales_rep_work.customer_code%TYPE  DEFAULT NULL;  -- �ڋq
  gt_upload_output_num             xxcok_bm_sales_rep_work.output_num%TYPE     DEFAULT NULL;  -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  -- ���������擾�l
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gn_org_id                        NUMBER        DEFAULT NULL;   -- �c�ƒP��ID
  gv_prompt_bm                     VARCHAR2(100) DEFAULT NULL;   -- �x���ē���_�̔��萔�����o��
  gv_prompt_ep                     VARCHAR2(100) DEFAULT NULL;   -- �x���ē���_�d�C�����o��
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
  gv_prompt_fe                     VARCHAR2(100) DEFAULT NULL;                  -- �x���ē���_�U���萔��
  gt_aff3_fee                      gl_code_combinations.segment3%TYPE;          -- ����ȖځF�萔��
  gt_aff4_transfer_fee             gl_code_combinations.segment4%TYPE;          -- �⏕�ȖځF�萔��-�U���萔��
  gt_category_bm                   gl_je_categories.user_je_category_name%TYPE; -- �d��J�e�S��_�̔��萔��
  gt_source_cok                    gl_je_sources.user_je_source_name%TYPE;      -- �d��\�[�X_�ʊJ��
  gt_set_of_books_id               gl_sets_of_books.set_of_books_id%TYPE;       -- ��v����ID
  gn_bank_fee_trans                NUMBER;                                      -- ��s�萔��_�U���z�
  gn_bank_fee_less                 NUMBER;                                      -- ��s�萔��_��z����
  gn_bank_fee_more                 NUMBER;                                      -- ��s�萔��_��z�ȏ�
  gn_bm_tax                        NUMBER;                                      -- �̔��萔��_����ŗ�
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD START
  gv_dept_jimu                     VARCHAR2(4);                                 -- ����R�[�h_�����Z���^�[
  gv_belong_base_cd                VARCHAR2(4);                                 -- ���s���[�U�������_
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD END
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  CURSOR g_summary_cur IS
    SELECT xrbpd.payment_code                     AS payment_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
         , xrbpd.contact_base_code                AS contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
         , SUM( xrbpd.selling_amt )               AS selling_amt_sum
         , gv_prompt_bm                           AS bm_index_1
         , SUM( CASE
                WHEN xrbpd.calc_type <> 50 THEN
                  xrbpd.backmargin
                END
           )                                      AS bm_amt_1
         , gv_prompt_ep                           AS bm_index_2
         , SUM( CASE
                WHEN xrbpd.calc_type = 50 THEN
                  xrbpd.backmargin
                END
           )                                      AS bm_amt_2
         , SUM( xrbpd.payment_amt_tax )           AS payment_amt_tax
         , MAX( xrbpd.closing_date )              AS closing_date
         , MIN( xrbpd.term_from_wk )              AS term_from
         , MAX( xrbpd.term_to_wk )                AS term_to
         , MAX( xrbpd.payment_date_wk )           AS payment_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
         , gv_prompt_fe                           AS bm_index_3
         , CASE WHEN xrbpd.org_slip_number IS NOT NULL THEN
-- Ver1.14 Mod Start
--               (SELECT SUM( NVL(gjl.entered_cr,0) - NVL(gjl.entered_dr,0) )
               (SELECT /*+ INDEX( gjl GL_JE_LINES_N1 ) */
                       SUM( NVL(gjl.entered_cr,0) - NVL(gjl.entered_dr,0) )
-- Ver1.14 Mod End
                  FROM gl_sets_of_books     gsob
                      ,gl_je_sources        gjs
                      ,gl_je_categories     gjc
                      ,gl_je_headers        gjh
                      ,gl_je_lines          gjl
                      ,gl_code_combinations gcc
                      ,gl_period_statuses   gps
                      ,fnd_application      fa
                 WHERE gsob.set_of_books_id      = gt_set_of_books_id
                   AND gjs.user_je_source_name   = gt_source_cok
                   AND gjc.user_je_category_name = gt_category_bm
                   AND gjs.language              = userenv('LANG')
                   AND gjs.source_lang           = gjs.language
                   AND gjs.source_lang           = gjc.language
                   AND gjs.source_lang           = gjc.source_lang
                   AND gsob.set_of_books_id      = gjh.set_of_books_id
                   AND gjs.je_source_name        = gjh.je_source
                   AND gjh.je_header_id          = gjl.je_header_id
                   AND gjl.code_combination_id   = gcc.code_combination_id
                   AND gcc.segment3              = gt_aff3_fee
                   AND gcc.segment4              = gt_aff4_transfer_fee
                   AND gjl.attribute7            = xrbpd.payment_code
                   AND gjl.attribute3            = xrbpd.org_slip_number
                   AND xrbpd.payment_date_wk     BETWEEN gps.start_date AND gps.end_date
                   AND gps.set_of_books_id       = gsob.set_of_books_id
                   AND gps.period_name           = gjh.period_name
-- Ver1.14 Add Start
                   AND gps.period_name           = gjl.period_name
-- Ver1.14 Add End
                   AND fa.application_short_name = cv_appl_short_name_gl
                   AND fa.application_id         = gps.application_id
               )
           ELSE CASE WHEN xrbpd.bank_charge_bearer = cv_bank_charge_bearer THEN 0
                     WHEN xrbpd.balance_cancel_date IS NOT NULL THEN 0
                ELSE(SELECT CASE WHEN SUM( CASE WHEN xrbpd2.calc_type <> 50
                                                 AND xrbpd2.balance_cancel_date IS NULL THEN xrbpd2.backmargin
                                           ELSE 0 END
                                         + CASE WHEN xrbpd2.calc_type =  50
                                                 AND xrbpd2.balance_cancel_date IS NULL THEN xrbpd2.backmargin
                                           ELSE 0 END
                                         ) < gn_bank_fee_trans THEN gn_bank_fee_less
                            ELSE gn_bank_fee_more END
                       FROM xxcok_rep_bm_pg_detail xrbpd2
                      WHERE xrbpd2.payment_code    = xrbpd.payment_code
                        AND xrbpd2.payment_date_wk = xrbpd.payment_date_wk
                    )
                END
           END * ( 1 + gn_bm_tax / 100 )          AS bm_amt_3
         , xrbpd.org_slip_number
         , xrbpd.payment_date_wk
         , xrbpd.bank_charge_bearer
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , xrbpd.output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_rep_bm_pg_detail    xrbpd
    WHERE xrbpd.request_id = cn_request_id
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xrbpd.output_num = gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    GROUP BY xrbpd.payment_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
            ,xrbpd.contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
            ,xrbpd.org_slip_number
            ,xrbpd.payment_date_wk
            ,xrbpd.bank_charge_bearer
            ,xrbpd.balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
            ,xrbpd.output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    ;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  --�A�b�v���[�h�o�͑Ώێ擾
  CURSOR g_upload_cur IS
    SELECT xbsrw.output_num                    AS output_num
          ,xbsrw.target_ym                     AS target_ym
          ,xbsrw.vendor_code                   AS vendor_code
          ,xbsrw.customer_code                 AS customer_code
    FROM  xxcok_bm_sales_rep_work    xbsrw
    WHERE xbsrw.request_id = gn_param_request_id
    AND   xbsrw.output_num = NVL(gn_param_output_num, xbsrw.output_num)
    AND   xbsrw.output_rep = ct_rep_id_bm
    ORDER BY xbsrw.output_num
    ;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  --==================================================
  -- �O���[�o���R���N�V�����^�ϐ�
  --==================================================
  TYPE g_summary_ttype             IS TABLE OF g_summary_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_summary_tab                    g_summary_ttype;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  TYPE g_upload_ttype             IS TABLE OF g_upload_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_upload_tab                    g_upload_ttype;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  --==================================================
  -- ���ʗ�O
  --==================================================
  --*** ���������ʗ�O ***
  global_process_expt              EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                  EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt           EXCEPTION;
  --==================================================
  -- ��O
  --==================================================
  --*** �G���[�I�� ***
  error_proc_expt                  EXCEPTION;
--
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  /**********************************************************************************
   * Procedure Name   : delete_xbsrw
   * Description      : �o�͑Ώۃ��[�N�폜(A-10)
   ***********************************************************************************/
  PROCEDURE delete_xbsrw(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xbsrw';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR lock_xbsrw_cur
    IS
      SELECT 'X'
      FROM xxcok_bm_sales_rep_work    xbsrw
      WHERE xbsrw.request_id = gn_param_request_id
      AND   xbsrw.output_num = NVL(gn_param_output_num, xbsrw.output_num)
      AND   xbsrw.output_rep = ct_rep_id_bm
      FOR UPDATE OF xbsrw.output_num NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ���b�N�擾
    --==================================================
    OPEN  lock_xbsrw_cur;
    CLOSE lock_xbsrw_cur;
    --==================================================
    -- ���[�N�e�[�u���f�[�^�폜
    --==================================================
    DELETE
    FROM xxcok_bm_sales_rep_work    xbsrw
    WHERE xbsrw.request_id = gn_param_request_id
    AND   xbsrw.output_num = NVL(gn_param_output_num, xbsrw.output_num)
    AND   xbsrw.output_rep = ct_rep_id_bm
    ;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END delete_xbsrw;
--
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  /**********************************************************************************
   * Procedure Name   : delete_xrbpd
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xrbpd';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR lock_xrbpd_cur
    IS
      SELECT 'X'
      FROM xxcok_rep_bm_pg_detail  xrbpd
      WHERE xrbpd.request_id = cn_request_id
      FOR UPDATE OF xrbpd.payment_code NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ���b�N�擾
    --==================================================
    OPEN  lock_xrbpd_cur;
    CLOSE lock_xrbpd_cur;
    --==================================================
    -- ���[�N�e�[�u���f�[�^�폜
    --==================================================
    DELETE
    FROM xxcok_rep_bm_pg_detail  xrbpd
    WHERE xrbpd.request_id = cn_request_id
    ;
    --==================================================
    -- ���������擾
    --==================================================
    gn_target_cnt := SQL%ROWCOUNT;
    gn_normal_cnt := SQL%ROWCOUNT;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END delete_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF�N��(A-6)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'start_svf';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_date                        VARCHAR2(8)    DEFAULT NULL;                 -- �o�̓t�@�C�����p���t
    lv_file_name                   VARCHAR2(100)  DEFAULT NULL;                 -- �o�̓t�@�C����
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �V�X�e�����t�^�ϊ�
    --==================================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    --==================================================
    -- �o�̓t�@�C����(���[ID + YYYYMMDD + �v��ID)
    --==================================================
    lv_file_name := cv_file_id
                 || TO_CHAR( SYSDATE, cv_format_fxrrrrmmdd )
                 || TO_CHAR( cn_request_id )
                 || cv_extension
                 ;
    --==================================================
    -- SVF�R���J�����g�N��
    --==================================================
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--    xxccp_svfcommon_pkg.submit_svf_request(
    xxccp_svfcommon_excl_pkg.submit_svf_request(
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
      ov_errbuf                => lv_errbuf                 -- �G���[�o�b�t�@
    , ov_retcode               => lv_retcode                -- ���^�[���R�[�h
    , ov_errmsg                => lv_errmsg                 -- �G���[���b�Z�[�W
    , iv_conc_name             => cv_pkg_name               -- �R���J�����g��
    , iv_file_name             => lv_file_name              -- �o�̓t�@�C����
    , iv_file_id               => cv_file_id                -- ���[ID
    , iv_output_mode           => cv_output_mode            -- �o�͋敪
    , iv_frm_file              => cv_frm_file               -- �t�H�[���l���t�@�C����
    , iv_vrq_file              => cv_vrq_file               -- �N�G���[�l���t�@�C����
    , iv_org_id                => NULL                      -- ORG_ID
    , iv_user_name             => fnd_global.user_name      -- ���O�C���E���[�U��
    , iv_resp_name             => fnd_global.resp_name      -- ���O�C���E���[�U�E�Ӗ�
    , iv_doc_name              => NULL                      -- ������
    , iv_printer_name          => NULL                      -- �v�����^��
    , iv_request_id            => TO_CHAR( cn_request_id )  -- �v��ID
    , iv_nodata_msg            => NULL                      -- �f�[�^�Ȃ����b�Z�[�W
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    , iv_excl_code             => cv_excl_code              -- SVF��p�}�l�[�W���R�[�h
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cok
                    , iv_name         => cv_msg_cok_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => 0
                    );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : update_xrbpd
   * Description      : �x���ē����i���ׁj���[���[�N�e�[�u���X�V(A-5)
   ***********************************************************************************/
  PROCEDURE update_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xrbpd';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J����O
    --==================================================
    --*** �G���[�I�� ***
    error_proc_expt                EXCEPTION;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �x���斈�W��f�[�^���������[�v
    --==================================================
    << g_summary_tab_loop >>
    FOR i IN 1 .. g_summary_tab.COUNT LOOP
      --==================================================
      -- ���[���[�N�e�[�u���X�V
      --==================================================
      UPDATE xxcok_rep_bm_pg_detail     xrbpd
      SET xrbpd.selling_amt_sum    = g_summary_tab(i).selling_amt_sum
        , xrbpd.bm_index_1         = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0 THEN
                                       g_summary_tab(i).bm_index_1
                                     ELSE
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD START
--                                       g_summary_tab(i).bm_index_2
                                       CASE WHEN g_summary_tab(i).bm_amt_2 > 0 THEN
                                         g_summary_tab(i).bm_index_2
                                       ELSE g_summary_tab(i).bm_index_3
                                       END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD END
                                     END
        , xrbpd.bm_amt_1           = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0 THEN
                                       g_summary_tab(i).bm_amt_1
                                     ELSE
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD START
--                                       g_summary_tab(i).bm_amt_2
                                       CASE WHEN g_summary_tab(i).bm_amt_2 > 0 THEN
                                         g_summary_tab(i).bm_amt_2
                                       ELSE g_summary_tab(i).bm_amt_3
                                       END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD END
                                     END
        , xrbpd.bm_index_2         = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0
                                      AND g_summary_tab(i).bm_amt_2 > 0 THEN
                                       g_summary_tab(i).bm_index_2
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD START
--                                     ELSE
--                                       NULL
                                     ELSE
                                       CASE WHEN(g_summary_tab(i).bm_amt_1 > 0
                                                 OR g_summary_tab(i).bm_amt_2 > 0)
                                             AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                              g_summary_tab(i).bm_index_3
                                       ELSE NULL
                                       END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD END
                                     END
        , xrbpd.bm_amt_2           = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0
                                      AND g_summary_tab(i).bm_amt_2 > 0 THEN
                                       g_summary_tab(i).bm_amt_2
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD START
--                                     ELSE
--                                       NULL
                                     ELSE
                                       CASE WHEN(g_summary_tab(i).bm_amt_1 > 0
                                                 OR g_summary_tab(i).bm_amt_2 > 0)
                                             AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                              g_summary_tab(i).bm_amt_3 * -1
                                       ELSE NULL
                                       END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD END
                                     END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD START
--        , xrbpd.payment_amt_tax    = g_summary_tab(i).payment_amt_tax
        , xrbpd.payment_amt_tax    = g_summary_tab(i).payment_amt_tax - NVL(g_summary_tab(i).bm_amt_3 , 0)
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama UPD END
        , xrbpd.target_month       = TO_CHAR( g_summary_tab(i).closing_date
                                            , cv_format_ee_month
                                            , cv_nls_param )
        , xrbpd.term_from          = TO_CHAR( g_summary_tab(i).term_from
                                            , cv_format_ee_date
                                            , cv_nls_param )
        , xrbpd.term_to            = TO_CHAR( g_summary_tab(i).term_to
                                            , cv_format_ee_date
                                            , cv_nls_param )
        , xrbpd.payment_date       = TO_CHAR( g_summary_tab(i).payment_date
                                            , cv_format_ee_date
                                            , cv_nls_param )
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
        , xrbpd.bm_index_3         = CASE WHEN g_summary_tab(i).bm_amt_1 > 0
                                           AND g_summary_tab(i).bm_amt_2 > 0
                                           AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                          g_summary_tab(i).bm_index_3
                                     ELSE NULL END
        , xrbpd.bm_amt_3           = CASE WHEN g_summary_tab(i).bm_amt_1 > 0
                                           AND g_summary_tab(i).bm_amt_2 > 0
                                           AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                          g_summary_tab(i).bm_amt_3 * -1
                                     ELSE NULL END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
      WHERE xrbpd.request_id       = cn_request_id
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
        AND xrbpd.output_num       = gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
        AND xrbpd.payment_code     = g_summary_tab(i).payment_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
        AND xrbpd.contact_base_code = g_summary_tab(i).contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
-- 2010/04/06 Ver.1.9 [��QE_�{�ғ�_01897] SCS K.Yamaguchi UPD START
---- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
--        AND NVL(xrbpd.org_slip_number,'X') = NVL(g_summary_tab(i).org_slip_number,'X')
--        AND xrbpd.payment_date_wk    = g_summary_tab(i).payment_date_wk
--        AND xrbpd.bank_charge_bearer = g_summary_tab(i).bank_charge_bearer
---- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
        AND (    ( xrbpd.org_slip_number                  = g_summary_tab(i).org_slip_number            )
              OR ( xrbpd.org_slip_number IS NULL        AND g_summary_tab(i).org_slip_number IS NULL    )
            )
        AND (    ( xrbpd.payment_date_wk                  = g_summary_tab(i).payment_date_wk            )
              OR ( xrbpd.payment_date_wk IS NULL        AND g_summary_tab(i).payment_date_wk IS NULL    )
            )
        AND (    ( xrbpd.bank_charge_bearer               = g_summary_tab(i).bank_charge_bearer         )
              OR ( xrbpd.bank_charge_bearer IS NULL     AND g_summary_tab(i).bank_charge_bearer IS NULL )
            )
-- 2010/04/06 Ver.1.9 [��QE_�{�ғ�_01897] SCS K.Yamaguchi UPD END
      ;
    END LOOP;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : get_xrbpd
   * Description      : ���[�N�e�[�u���x���斈�W��f�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_xrbpd';        -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J����O
    --==================================================
    --*** �G���[�I�� ***
    error_proc_expt                EXCEPTION;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �x���斈�W��f�[�^�擾
    --==================================================
    OPEN  g_summary_cur;
    FETCH g_summary_cur BULK COLLECT INTO g_summary_tab;
    CLOSE g_summary_cur;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : insert_xrbpd
   * Description      : �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE insert_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xrbpd';     -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �{�U�i�ē��L�j
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- ���v���o��3
    , bm_amt_3                         -- ���v�萔��3
    , org_slip_number                  -- ���`�[�ԍ�
    , bank_charge_bearer               -- �萔�����S��
    , balance_cancel_date              -- �c�������
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
    , start_tran_date                  -- ��������
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    , output_num                       -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    )
    SELECT xbb.supplier_code                                    AS payment_code
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 20 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21, 20 )                     AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca2.contact_area_code                               AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
         , hca2.contact_code                                    AS contact_base_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca2.contact_name                                    AS contact_base_name
--         , hca2.contact_address1                                AS contact_addr_1
--         , hca2.contact_address2                                AS contact_addr_2
--         , hca2.contact_phone_num                               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--                ,    hl.state
--                  || hl.city 
--                  || hl.address1                 AS contact_address1
--                , hl.address2                    AS contact_address2
                ,    hl.city 
                  || hl.address1
                  || hl.address2                 AS contact_address1
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_1
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR START
---- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR START
----      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
----                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
--      AND (    (     xbb.fb_interface_status      = '0'
--                 AND xbb.fb_interface_date       IS NULL
--                 AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                                AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
--               )
--            OR
--               (     xbb.fb_interface_status      = '1'
--                 AND xbb.fb_interface_date  BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                                AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
--               )
--          )
---- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR END
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR END
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL START
--           , hca2.contact_address2
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL END
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END 
                ) <> 0
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
-- 2018/03/15 Ver.1.15 [��QE_�{�ғ�_14900] SCSK Y.Sekine ADD START
    UNION ALL
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca2.contact_code                                    AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date     -- ���x����
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city 
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_1
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
      AND gv_belong_base_cd            = gv_dept_jimu   -- ���s���[�U�̏������傪�����Z���^
      AND xbb.publication_date         IS NULL          -- �̎�c���e�[�u���D�ē�����������NULL
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END 
                ) <> 0
-- 2018/03/15 Ver.1.15 [��QE_�{�ғ�_14900] SCSK Y.Sekine ADD END
    ;
    --==================================================
    -- �{�U�i�ē����j
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- ���v���o��3
    , bm_amt_3                         -- ���v�萔��3
    , org_slip_number                  -- ���`�[�ԍ�
    , bank_charge_bearer               -- �萔�����S��
    , balance_cancel_date              -- �c�������
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
    , start_tran_date                  -- ��������
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    , output_num                       -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    )
    SELECT xbb.supplier_code                                    AS payment_code
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 20 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21, 20 )                     AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca2.contact_area_code                               AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
         , hca2.contact_code                                    AS contact_base_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca2.contact_name                                    AS contact_base_name
--         , hca2.contact_address1                                AS contact_addr_1
--         , hca2.contact_address2                                AS contact_addr_2
--         , hca2.contact_phone_num                               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--                ,    hl.state
--                  || hl.city 
--                  || hl.address1                 AS contact_address1
--                , hl.address2                    AS contact_address2
                ,    hl.city 
                  || hl.address1
                  || hl.address2                 AS contact_address1
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
               , flv.meaning                     AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_2
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR START
--      AND xbb.fb_interface_date  BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                      AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR END
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
-- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR START
--      AND xbb.edi_interface_status     = '1'
      AND xbb.fb_interface_status      = '1'
-- 2009/05/11 Ver.1.3 [��QT1_0866] SCS K.Yamaguchi REPAIR END
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL START
--           , hca2.contact_address2
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL END
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
-- Ver.1.13 [��QE_�{�ғ�_14836] SCSK K.Nara ADD START
    UNION ALL
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca2.contact_code                                    AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date  --���x����
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
               , flv.meaning                     AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_2
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
      AND gv_belong_base_cd            = gv_dept_jimu  --���s���[�U�̏������傪�����Z���^
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )  --�x���\���
                                        AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
      AND xbb.fb_interface_status      = '0'           --FB���A�g
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- Ver.1.13 [��QE_�{�ғ�_14836] SCSK K.Nara ADD END
    ;
    --==================================================
    -- AP�x��
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- ���v���o��3
    , bm_amt_3                         -- ���v�萔��3
    , org_slip_number                  -- ���`�[�ԍ�
    , bank_charge_bearer               -- �萔�����S��
    , balance_cancel_date              -- �c�������
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
    , start_tran_date                  -- ��������
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    , output_num                       -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    )
    SELECT xbb.supplier_code                                    AS payment_code
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 20 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21, 20 )                     AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = hca3.base_code
              WHERE   xdv.flex_value  = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , hca3.base_code                                       AS contact_base_code
         , hca1.contact_base_code                               AS contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS contact_base_name
--         , hca3.base_address1                                   AS contact_addr_1
--         , hca3.base_address2                                   AS contact_addr_2
--         , hca3.base_phone_num                                  AS contact_phone_no
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , SUBSTR( hca3.base_name , 1 , 20 )                    AS contact_base_name
--         , SUBSTR( hca3.base_address1 , 1 , 20 )                AS contact_addr_1
--         , SUBSTR( hca3.base_address1 , 21, 20 )                AS contact_addr_2
--         , SUBSTRB( hca3.base_phone_num , 1 ,15 )               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara MOD START
--         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , cv_bank_charge_bearer                                AS bank_charge_bearer  --�U���萔�����o�͂��Ȃ����߂ɓ����Ƃ���
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara MOD END
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date 
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
         )                        hca1
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--                ,    hl.state
--                  || hl.city
--                  || hl.address1                 AS base_address1
--                , hl.address2                    AS base_address2
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
      AND hca2.contact_code            = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_3
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--      AND xbb.base_code                = gv_param_base_code
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND hca1.base_code                = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR START
--      AND xbb.balance_cancel_date BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                      AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR END
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
      AND xbb.expect_payment_amt_tax   = 0
      AND xbb.payment_amt_tax          > 0
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--           , hca3.base_code
--           , hca3.base_name
--           , hca3.base_area_code
--           , hca3.base_address1
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL START
--           , hca3.base_address2
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai DEL START
--           , hca3.base_phone_num
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai DEL END
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD START
    UNION ALL
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca1.contact_base_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca1.contact_base_code                               AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , cv_bank_charge_bearer                                AS bank_charge_bearer  --�U���萔�����o�͂��Ȃ����߂ɓ����Ƃ���
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date 
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND hca2.contact_code            = hca1.contact_base_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_3
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND hca1.base_code               = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
      AND gv_belong_base_cd            = gv_dept_jimu  --���s���[�U�������Z���^
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )  --�x���\������Ώۓ�
                                        AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
      AND xbb.expect_payment_amt_tax   > 0  --�������ł���
      AND xbb.payment_amt_tax          = 0  --�������ł���
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD END
    ;
    --==================================================
    -- �����x��
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- �x����R�[�h
    , publication_date                 -- ���s��
    , payment_zip_code                 -- �x����X�֔ԍ�
    , payment_addr_1                   -- �x����Z��1
    , payment_addr_2                   -- �x����Z��2
    , payment_name_1                   -- �x���戶��1
    , payment_name_2                   -- �x���戶��2
    , contact_base                     -- �n��R�[�h�i�A���拒�_�j
    , contact_base_code                -- �A���拒�_�R�[�h
    , contact_base_name                -- �A���拒�_��
    , contact_addr_1                   -- �A����Z��1
    , contact_addr_2                   -- �A����Z��2
    , contact_phone_no                 -- �A����d�b�ԍ�
    , selling_amt_sum                  -- �̔����z���v
    , bm_index_1                       -- ���v���o��1
    , bm_amt_1                         -- ���v�萔��1
    , bm_index_2                       -- ���v���o��2
    , bm_amt_2                         -- ���v�萔��2
    , payment_amt_tax                  -- �x�����z�i�ō��j
    , closing_date                     -- ���ߓ�
    , term_from_wk                     -- �Ώۊ��ԁiFrom�j_���[�N
    , term_to_wk                       -- �Ώۊ��ԁiTo�j_���[�N
    , payment_date_wk                  -- ���x����_���[�N
    , cust_code                        -- �ڋq�R�[�h
    , cust_name                        -- �ڋq��
    , selling_base                     -- �n��R�[�h�i����v�㋒�_�j
    , selling_base_code                -- ����v�㋒�_�R�[�h
    , selling_base_name                -- ����v�㋒�_��
    , calc_type                        -- �v�Z����
    , calc_type_sort                   -- �v�Z�����\�[�g��
    , container_type_code              -- �e��敪�R�[�h
    , selling_price                    -- ����
    , detail_name                      -- ���ז�
    , selling_amt                      -- �̔����z
    , selling_qty                      -- �̔�����
    , backmargin                       -- �̔��萔��
    , created_by                       -- �쐬��
    , creation_date                    -- �쐬��
    , last_updated_by                  -- �ŏI�X�V��
    , last_update_date                 -- �ŏI�X�V��
    , last_update_login                -- �ŏI�X�V���O�C��
    , request_id                       -- �v��ID
    , program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                       -- �R���J�����g�E�v���O����ID
    , program_update_date              -- �v���O�����X�V��
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- ���v���o��3
    , bm_amt_3                         -- ���v�萔��3
    , org_slip_number                  -- ���`�[�ԍ�
    , bank_charge_bearer               -- �萔�����S��
    , balance_cancel_date              -- �c�������
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
    , start_tran_date                  -- ��������
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    , output_num                       -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    )
    SELECT xbb.supplier_code                                    AS payment_code
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1 , 8 )                          AS payment_zip_code
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1 , 20 )                    AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21 , 20 )                    AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1 , 20 )                   AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21 , 20 )                   AS payment_name_2
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = hca3.base_code
              WHERE   xdv.flex_value  = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , hca3.base_code                                       AS contact_base_code
         , hca1.contact_base_code                               AS contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS contact_base_name
--         , hca3.base_address1                                   AS contact_addr_1
--         , hca3.base_address2                                   AS contact_addr_2
--         , hca3.base_phone_num                                  AS contact_phone_no
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , SUBSTR( hca3.base_name , 1 , 20 )                    AS contact_base_name
--         , SUBSTR( hca3.base_address1 , 1 , 20 )                AS contact_addr_1
--         , SUBSTR( hca3.base_address1 , 21, 20 )                AS contact_addr_2
--         , SUBSTRB( hca3.base_phone_num , 1 ,15 )               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [��QT1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [��QE_�{�ғ�_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
         )                        hca1
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD START
--                ,    hl.state 
--                  || hl.city
--                  || hl.address1                 AS base_address1
--                , hl.address2                    AS base_address2
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD START
      AND hca2.contact_code            = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai ADD END
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_4
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--      AND xbb.base_code                = gv_param_base_code
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND hca1.base_code               = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPS START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama UPS END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--           , hca3.base_code
--           , hca3.base_name
--           , hca3.base_area_code
--           , hca3.base_address1
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL START
--           , hca3.base_address2
-- 2009/09/10 Ver.1.5 [��Q0000060] SCS S.Moriyama DEL END
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai DEL START
--           , hca3.base_phone_num
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai DEL END
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [��QE_�{�ғ�_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [��QE_�{�ғ�_01950] SCS S.Niki ADD END
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD START
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2009/12/15 Ver.1.7 [��QE_�{�ғ�_00477] SCS K.Nakamura ADD END
-- 2018/03/15 Ver.1.15 [��QE_�{�ғ�_14900] SCSK Y.Sekine ADD START
    UNION ALL
    SELECT xbb.supplier_code                                    AS payment_code
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1 , 8 )                          AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1 , 20 )                   AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21 , 20 )                   AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca1.contact_base_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca1.contact_base_code                               AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date     -- ���x����
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- �{���R�[�h(��)
                        ELSE xdv.attribute9 -- �{���R�[�h(�V)
                      END
              FROM    xx03_departments_v  xdv -- ����r���[
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    FROM xxcok_cond_bm_support    xcbs -- �����ʔ̎�̋��e�[�u��
       , xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
       , po_vendors               pv   -- �d����}�X�^
       , po_vendor_sites_all      pvsa -- �d����T�C�g�}�X�^
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , xxcmm_cust_accounts         xca       -- �ڋq�A�h�I��
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- �ڋq�}�X�^
              , hz_cust_acct_sites_all      hcasa     -- �ڋq���ݒn�}�X�^
              , hz_parties                  hp        -- �p�[�e�B�}�X�^
              , hz_party_sites              hps       -- �p�[�e�B�T�C�g�}�X�^
              , hz_locations                hl        -- �ڋq���Ə��}�X�^
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- �N�C�b�N�R�[�h
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND hca2.contact_code            = hca1.contact_base_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_4
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--      AND hca1.base_code               = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
      AND gv_belong_base_cd            = gv_dept_jimu   -- ���s���[�U�̏������傪�����Z���^
      AND xbb.publication_date         IS NULL          -- �̎�c���e�[�u���D�ē�����������NULL
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2018/03/15 Ver.1.15 [��QE_�{�ғ�_14900] SCSK Y.Sekine ADD END
    ;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- �v��ID
  , in_output_num                  IN  NUMBER          -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_chk_date                    DATE           DEFAULT NULL;                 -- ���t�^�`�F�b�N�p�ϐ�
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �v���O�������͍��ڂ��o��
    --==================================================
    -- �⍇��
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00087
                  , iv_token_name1          => cv_tkn_base_code
                  , iv_token_value1         => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- �ē������s�N��
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00085
                  , iv_token_name1          => cv_tkn_target_ym
                  , iv_token_value1         => iv_target_ym
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- �x����
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00086
                  , iv_token_name1          => cv_tkn_vendor_code
                  , iv_token_value1         => iv_vendor_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--                  , in_new_line             => 1
                  , in_new_line             => 0
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
                  );
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    -- �v��ID
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_10545
                  , iv_token_name1          => cv_tkn_request_id
                  , iv_token_value1         => TO_CHAR(in_request_id)
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- �o�͔ԍ�
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_10546
                  , iv_token_name1          => cv_tkn_output_num
                  , iv_token_value1         => TO_CHAR(in_output_num)
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 1
                  );
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �ē������s�N���^�`�F�b�N
    --==================================================
    BEGIN
      ld_chk_date := TO_DATE( iv_target_ym, cv_format_fxrrrrmm );
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_10309
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.LOG
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
    END;
    --==================================================
    -- �v���t�@�C���擾(MO: �c�ƒP��)
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x���ē���_�̔��萔�����o��)
    --==================================================
    gv_prompt_bm := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_prompt_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x���ē���_�d�C�����o��)
    --==================================================
    gv_prompt_ep := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_prompt_ep IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD START
    --==================================================
    -- �v���t�@�C���擾(�x���ē���_�U���萔��)
    --==================================================
    gv_prompt_fe := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_prompt_fe IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_04
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(����Ȗ�_�萔��)
    --==================================================
    gt_aff3_fee := FND_PROFILE.VALUE( cv_profile_name_05 );
    IF( gt_aff3_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_05
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�⏕�Ȗ�_�萔��_�U���萔��)
    --==================================================
    gt_aff4_transfer_fee := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF( gt_aff4_transfer_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_06
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d��J�e�S��_�̔��萔��)
    --==================================================
    gt_category_bm := FND_PROFILE.VALUE( cv_profile_name_07 );
    IF( gt_category_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_07
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d��\�[�X_�ʊJ��)
    --==================================================
    gt_source_cok := FND_PROFILE.VALUE( cv_profile_name_08 );
    IF( gt_source_cok IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_08
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(GL��v����ID)
    --==================================================
    gt_set_of_books_id := FND_PROFILE.VALUE( cv_profile_name_09 );
    IF( gt_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_09
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��s�萔��_�U���z�)
    --==================================================
    gn_bank_fee_trans := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_10 ) );
    IF( gn_bank_fee_trans IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_10
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��s�萔��_��z����)
    --==================================================
    gn_bank_fee_less := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_11 ) );
    IF( gn_bank_fee_less IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_11
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��s�萔��_��z�ȏ�)
    --==================================================
    gn_bank_fee_more := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_12 ) );
    IF( gn_bank_fee_more IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_12
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�̔��萔��_����ŗ�)
    --==================================================
    gn_bm_tax := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_13 ) );
    IF( gn_bm_tax IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_13
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/03/16 Ver.1.9 [��QE_�{�ғ�_01897] SCS S.Moriyama ADD END
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD START
    --==================================================
    -- �v���t�@�C���擾(XXCOK:����R�[�h_�����Z���^�[)
    --==================================================
    gv_dept_jimu := FND_PROFILE.VALUE( cv_profile_name_14 );
    IF( gv_dept_jimu IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_14
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- ���s���[�U�̏����������擾
    --==================================================
    gv_belong_base_cd := NVL( xxcok_common_pkg.get_base_code_f( gd_process_date, fnd_global.user_id ), '@' );
-- 2017/12/29 Ver.1.12 [��QE_�{�ғ�_14789] SCSK K.Nara ADD END
    gv_param_base_code   := iv_base_code;
    gv_param_target_ym   := iv_target_ym;
    gv_param_vendor_code := iv_vendor_code;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    gn_param_request_id  := in_request_id;
    gn_param_output_num  := in_output_num;
    gt_upload_output_num := ct_output_num_init;    --�J�����g�o�͔ԍ�������
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- �v��ID
  , in_output_num                  IN  NUMBER          -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';          -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ��������(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_base_code            => iv_base_code          -- �⍇����
    , iv_target_ym            => iv_target_ym          -- �ē������s�N��
    , iv_vendor_code          => iv_vendor_code        -- �x����
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    , in_request_id           => in_request_id         -- �v��ID
    , in_output_num           => in_output_num         -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD START
--    --==================================================
--    -- �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
--    --==================================================
--    insert_xrbpd(
--      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
--    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
--    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
    IF in_request_id IS NOT NULL THEN
      --�A�b�v���[�h�N���̏ꍇ
      --==================================================
      -- �o�͑Ώۃ��[�N�擾(A-8)
      --==================================================
      OPEN  g_upload_cur;
      FETCH g_upload_cur BULK COLLECT INTO g_upload_tab;
      CLOSE g_upload_cur;
      --==================================================
      -- �A�b�v���[�h�o�͑Ώی��������[�v
      --==================================================
      << g_upload_tab_loop >>
      FOR i IN 1 .. g_upload_tab.COUNT LOOP
        --�o�͔ԍ����ς�����ꍇ
        IF gt_upload_output_num <> g_upload_tab(i).output_num
        AND gt_upload_output_num <> ct_output_num_init THEN
          --==================================================
          -- ���[�N�e�[�u���x���斈�W��f�[�^�擾(A-4)
          --==================================================
          get_xrbpd(
            ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
          , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
          , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- �x���ē����i���ׁj���[���[�N�e�[�u���X�V(A-5)
          --==================================================
          update_xrbpd(
            ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
          , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
          , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --==================================================
        -- ���������A�o�^�l�X�V(A-9)
        --==================================================
        gv_param_base_code   := NULL;
        gv_param_target_ym   := SUBSTRB(TO_CHAR(g_upload_tab(i).target_ym), 1, 4) || cv_slash || SUBSTRB(TO_CHAR(g_upload_tab(i).target_ym), 5, 2);
        gv_param_vendor_code := g_upload_tab(i).vendor_code;
        gt_upload_cust_code  := g_upload_tab(i).customer_code;
        gt_upload_output_num := g_upload_tab(i).output_num;
        --==================================================
        -- �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
        --==================================================
        insert_xrbpd(
          ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
        , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
        , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP;
      --
    ELSE
      --��ʋN���̏ꍇ
      --�����l�ݒ�
      gt_upload_cust_code := NULL;
      --==================================================
      -- �f�[�^�擾(A-2)�E���[�N�e�[�u���f�[�^�o�^(A-3)
      --==================================================
      insert_xrbpd(
        ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara MOD END
    --==================================================
    -- ���[�N�e�[�u���x���斈�W��f�[�^�擾(A-4)
    --==================================================
    get_xrbpd(
      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �x���ē����i���ׁj���[���[�N�e�[�u���X�V(A-5)
    --==================================================
    update_xrbpd(
      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �m��
    --==================================================
    COMMIT;
    --==================================================
    -- SVF�N��(A-6)
    --==================================================
    start_svf(
      ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- ���[�N�e�[�u���f�[�^�폜(A-7)
    --==================================================
    delete_xrbpd(
      ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    IF in_request_id IS NOT NULL THEN
      --==================================================
      -- �o�͑Ώۃ��[�N�폜(A-10)
      --==================================================
      delete_xbsrw(
        ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- �v��ID
  , in_output_num                  IN  NUMBER          -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- �I�����b�Z�[�W�R�[�h
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    , iv_which                => cv_which_log
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_base_code            => iv_base_code          -- �⍇����
    , iv_target_ym            => iv_target_ym          -- �ē������s�N��
    , iv_vendor_code          => iv_vendor_code        -- �x����
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
    , in_request_id           => in_request_id         -- �v��ID
    , in_output_num           => in_output_num         -- �o�͔ԍ�
-- Ver.1.16 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
    );
    --==================================================
    -- �G���[�o��
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG   -- �o�͋敪
                    , iv_message               => lv_errmsg      -- ���b�Z�[�W
                    , in_new_line              => 0              -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 1
                    );
    END IF;
    --==================================================
    -- �Ώی����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �G���[�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- �����I�����b�Z�[�W�o��
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�e�[�^�X�Z�b�g
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK015A03R;
/
