CREATE OR REPLACE PACKAGE BODY XXCOK016A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK016A02C(body)
 * Description      : �{�@�\�͏����p�����[�^�ɂāA�ȉ��̂Q�@�\��؂�ւ��ď������܂��B
 *
 *                    �y�U���������O�`�F�b�N�pFB�쐬�z
 *                    ���ۂ̐U�������O�ɁA�U�������������������`�F�b�N���邽�߂̃f�[�^���쐬���܂��B
 *
 *                    �y�{�U�pFB�f�[�^�쐬�z
 *                    ���̋@�̔��萔����U�荞�ނ��߂�FB�f�[�^���쐬���܂��B
 *
 * MD.050           : FB�f�[�^�t�@�C���쐬�iFB�f�[�^�쐬�j MD050_COK_016_A02
 * Version          : 1.14
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                             Description
 * -------------------------------- ----------------------------------------------------------
 *  init                             �������� (A-1)
-- Ver.1.13 DEL START
-- *  get_bank_acct_chk_fb_line        FB�쐬���׃f�[�^�̎擾�i�U���������O�`�F�b�N�pFB�쐬�����j(A-2)
-- *  get_fb_line                      FB�쐬���׃f�[�^�̎擾�i�{�U�pFB�f�[�^�쐬�����j(A-3)
-- Ver.1.13 DEL END
 *  get_fb_header                    FB�쐬�w�b�_�[�f�[�^�̎擾(A-4)
 *  storage_fb_header                FB�쐬�w�b�_�[�f�[�^�̊i�[(A-5)
 *  storage_bank_acct_chk_fb_line    FB�쐬���׃f�[�^�̊i�[�i�U���������O�`�F�b�N�pFB�쐬�����j(A-7)
 *  get_fb_line_add_info             FB�쐬���׃f�[�^�t�����̎擾�i�{�U�pFB�f�[�^�쐬�����j(A-8)
 *  storage_fb_line                  FB�쐬���׃f�[�^�̊i�[�i�{�U�pFB�f�[�^�쐬�����j(A-9)
 *  upd_backmargin_balance           FB�쐬�f�[�^�o�͌��ʂ̍X�V(A-11)
 *  storage_fb_trailer_data          FB�쐬�g���[�����R�[�h�̊i�[(A-12)
 *  storage_fb_end_data              FB�쐬�G���h���R�[�h�̊i�[(A-14)
 *  output_data                      FB�쐬�w�b�_�[�f�[�^�̏o��(A-6)
 *                                   FB�쐬�f�[�^���R�[�h�̏o��(A-10)
 *                                   FB�쐬�g���[�����R�[�h�̏o��(A-13)
 *                                   FB�쐬�G���h���R�[�h�̏o��(A-15)
 *  upd_carried_forward_data         �����J��z���f�[�^�̍X�V(A-17)
 *  dmy_acct_chk                     FB�쐬�ΏۊO�_�~�[��������
-- Ver.1.13 ADD START
 *  insert_data                      FB�f�[�^���׃��[�N�e�[�u���o�^(A-10B)
 *  delete_data                      ���[�N�e�[�u���f�[�^�폜(A-18)
-- Ver.1.13 ADD END
 *  submain                          ���C�������v���V�[�W��
 *  main                             �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/06    1.0   T.Abe            �V�K�쐬
 *  2009/03/25    1.1   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/04/27    1.2   M.Hiruta         [��QT1_0817�Ή�]�{�U�pFB�f�[�^�쐬�������̋��_�R�[�h���o���e�[�u����ύX
 *  2009/05/12    1.3   M.Hiruta         [��QT1_0832�Ή�]�{�U�pFB�f�[�^�쐬�������A
 *                                                        �ȉ��̏����̃��R�[�h���o�͂��Ȃ��悤�ɕύX
 *                                                          1.�U���萔�����S�҂��ɓ����A���x���\��z <= 0
 *                                                          2.�U���萔�����S�҂��ɓ����ł͂Ȃ��A
 *                                                            ���x���\��z - �U���萔�� <= 0
 *  2009/05/29    1.4   K.Yamaguchi      [��QT1_1147�Ή�]�̎�c���e�[�u���X�V���ڒǉ�
 *  2009/07/02    1.5   K.Yamaguchi      [��Q0000291�Ή�]�p�t�H�[�}���X��Q�Ή�
 *  2009/08/03    1.6   M.Hiruta         [��Q0000843�Ή�]�U�����������̎擾�����̎擾�������C��
 *  2009/12/16    1.7   S.Moriyama       [E_�{�ғ�_00512�Ή�]�U�葊�蕉�S���ɐU���z����U������z���ďo�͂���悤�ɏC��
 *  2009/12/16    1.8   S.Moriyama       [E_�{�ғ�_00512�Ή�]FB�g���[�����R�[�h�ɐݒ肵�Ă���o�͌�����Ώی�������o�͌����֏C��
 *  2009/12/17    1.9   S.Moriyama       [E_�{�ғ�_00511�Ή�]FB���׃��R�[�h�̐U�����z�̎����ڂƂ���
 *                                                           91byte�ڂɔ��p���l0��ݒ肷��悤�ɏC��
 *                                                           �ڋq�R�[�h1�A�ڋq�R�[�h2�ɂ��Ă�10byte�O0���߂��s���悤�ɏC��
 *  2010/09/30    1.10  S.Arizumi        [E_�{�ғ�_01144�Ή�]�����ۗ����𗂌��̃C�Z�g�[�o�R�̎x���ē����Ɋ܂ޏC��
 *                                                           ���z�m��X�e�[�^�X���m��ς̃��R�[�h�̂ݑΏۂƂ���悤�ɏC��
 *  2018/08/07    1.11  K.Nara           [E_�{�ғ�_15203�Ή�]�{�U�pFB�f�[�^�쐬�ŐU���悪�_�~�[�����͍쐬�ΏۊO�Ƃ���
 *  2023/06/06    1.12  Y.Ooyama         [E_�{�ғ�_19179�Ή�]�C���{�C�X�Ή��iBM�֘A�j
 *  2023/10/25    1.13  T.Okuyama        [E_�{�ғ�_19540�Ή�]�u�U�蕪�����v�A�v���̑�ւ��Ή�
 *  2024/02/02    1.14  T.Okuyama        [E_�{�ғ�_19496�Ή�] �O���[�v��БΉ�
 *****************************************************************************************/
--
  --===============================
  -- �O���[�o���萔
  --===============================
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn              CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
-- Ver.1.13 ADD START
  cd_creation_date            CONSTANT DATE          := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date         CONSTANT DATE          := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date      CONSTANT DATE          := SYSDATE;                            -- PROGRAM_UPDATE_DATE
-- Ver.1.13 ADD END
  --
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';                              -- �R����
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';                                -- �s���I�h
  --
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK016A02C';                     -- �p�b�P�[�W��
  -- �v���t�@�C��
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--  cv_prof_bm_acc_number       CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_OUR_BANK_ACC_NUMBER';    -- ���Ћ�s�����ԍ�
--  cv_prof_bm_bra_number       CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_OUR_BANK_BRA_NUMBER';    -- ���Ћ�s�x�X�ԍ�
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
  cv_prof_bm_request_code     CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_OUR_REQUEST_CODE';       -- ���Ј˗��l�R�[�h
  cv_prof_trans_criterion     CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- ��s�萔��(�U����z)
  cv_prof_less_fee_criterion  CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- ��s�萔���z(�����)
  cv_prof_more_fee_criterion  CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- ��s�萔���z(��ȏ�)
  cv_prof_fb_term_name        CONSTANT VARCHAR2(35)  := 'XXCOK1_FB_TERM_NAME';              -- FB�x������
  cv_prof_bm_tax              CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_TAX';                    -- ����ŗ�
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_prof_org_id              CONSTANT VARCHAR2(35)  := 'ORG_ID';                           -- �c�ƒP��
  cv_prof_bank_trns_fee_we    CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_TRNS_FEE_WE';          -- �U���萔��_����
  cv_prof_bank_trns_fee_ctpty CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_TRNS_FEE_CTPTY';       -- �U���萔��_�����
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  cv_prof_acc_type_internal   CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_ACC_TYPE_INTERNAL';      -- �U���萔��_����_�����g�p
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  -- �A�v���P�[�V������
  cv_appli_xxccp              CONSTANT VARCHAR2(5)   := 'XXCCP';               -- 'XXCCP'
  cv_appli_xxcok              CONSTANT VARCHAR2(5)   := 'XXCOK';               -- 'XXCOK'
  -- ���b�Z�[�W
  cv_msg_cok_00044            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00044';    -- �R���J�����g���̓p�����[�^���b�Z�[�W
-- Ver.1.14 Add Start
  cv_msg_cok_10878            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10878';    -- �R���J�����g���̓p�����[�^�i��ЃR�[�h�j
  cv_msg_cok_10879            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10879';    -- ��ЃR�[�h�擾�G���[���b�Z�[�W
-- Ver.1.14 Add End
  cv_msg_cok_00003            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';    -- �v���t�@�C���l�擾�G���[���b�Z�[�W
  cv_msg_cok_00028            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';    -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_cok_00014            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00014';    -- �l�Z�b�g�l�擾�G���[
  cv_msg_cok_00036            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00036';    -- ���߁E�x�����t�̎擾�G���[
  cv_msg_cok_10254            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10254';    -- FB�쐬���׏��擾�G���[
  cv_msg_cok_10255            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10255';    -- FB�쐬�w�b�_�[���擾�G���[
  cv_msg_cok_10256            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10256';    -- FB�쐬�w�b�_�[���d���G���[
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR START
--  cv_msg_cok_10243            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10243';    -- FB�쐬���ʍX�V���b�N�G���[
--  cv_msg_cok_10244            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10244';    -- FB�쐬���ʍX�V�G���[
  cv_msg_cok_00053            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00053';    -- �̎�c���e�[�u���X�V���b�N�G���[
  cv_msg_cok_00054            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00054';    -- �̎�c���e�[�u���X�V�G���[
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR END
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
  cv_msg_cok_10561            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10561';    -- FB�f�[�^�̃_�~�[�����x��
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
  cv_msg_ccp_90000            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';    -- ���o�������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';    -- �G���[�������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';    -- �t�@�C���o�͌������b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';    -- ����I�����b�Z�[�W
  cv_msg_ccp_90006            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';    -- �G���[�I���S���[���o�b�N���b�Z�[�W
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_msg_cok_10453            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10453';    -- FB�f�[�^�̎x�����z0�~�ȉ��x��
  cv_msg_ccp_90003            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90003';    -- �X�L�b�v�������b�Z�[�W
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.13 ADD START
  cv_msg_cok_10861            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10861';    -- �f�[�^�o�^�G���[
  cv_msg_cok_10862            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10862';    -- �f�[�^�폜�G���[
  cv_msg_cok_10863            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10863';    -- �e�[�u�����b�N�擾�G���[
-- Ver.1.13 ADD END
  -- ���b�Z�[�W�E�g�[�N��
-- Ver.1.14 Add Start
  cv_token_company_code       CONSTANT VARCHAR2(15)  := 'COMPANY_CODE';        -- ��ЃR�[�h�p�����[�^
-- Ver.1.14 Add End
  cv_token_proc_type          CONSTANT VARCHAR2(15)  := 'PROC_TYPE';           -- �����p�����[�^
  cv_token_profile            CONSTANT VARCHAR2(15)  := 'PROFILE';             -- �J�X�^���v���t�@�C���̕�����
  cv_token_flex_value_set     CONSTANT VARCHAR2(15)  := 'FLEX_VALUE_SET';      -- �l�Z�b�g�̕�����
  cv_token_count              CONSTANT VARCHAR2(15)  := 'COUNT';               -- ����
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_token_conn_loc           CONSTANT VARCHAR2(15)  := 'CONN_LOC';            -- �⍇���S�����_
  cv_token_vendor_code        CONSTANT VARCHAR2(15)  := 'VENDOR_CODE';         -- �x����R�[�h
  cv_token_payment_amt        CONSTANT VARCHAR2(15)  := 'PAYMENT_AMT';         -- �x�����z
  cv_token_bank_charge_bearer CONSTANT VARCHAR2(20)  := 'BANK_CHARGE_BEARER';  -- ��s�萔�����S��
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
  cv_token_bank_number       CONSTANT VARCHAR2(15)  := 'BANK_NUMBER';          -- ��s�ԍ�
  cv_token_bank_num          CONSTANT VARCHAR2(15)  := 'BANK_NUM';             -- ��s�x�X�ԍ�
  cv_token_account_type      CONSTANT VARCHAR2(15)  := 'ACCOUNT_TYPE';         -- �a�����
  cv_token_account_num       CONSTANT VARCHAR2(20)  := 'ACCOUNT_NUM';          -- ��s�����ԍ�
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
-- Ver.1.13 ADD START
  cv_tkn_tbl                 CONSTANT VARCHAR2(30)  := 'TABLE';                -- �e�[�u����
  cv_tkn_err_msg             CONSTANT VARCHAR2(30)  := 'ERR_MSG';              -- �G���[���b�Z�[�W
  cv_tbl_nm                  CONSTANT VARCHAR2(100) := 'FB�f�[�^���׃��[�N�e�[�u��';
-- Ver.1.13 ADD END
  -- �l�Z�b�g
  cv_value_cok_fb_proc_type   CONSTANT VARCHAR2(30)  := 'XXCOK1_FB_PROC_TYPE'; -- �l�Z�b�g��
  -- �萔
  cv_log                      CONSTANT VARCHAR2(3)   := 'LOG';                 -- ���O�o�͎w��
  cv_yes                      CONSTANT VARCHAR2(1)   := 'Y';                   -- �t���O:'Y'
  cv_no                       CONSTANT VARCHAR2(1)   := 'N';                   -- �t���O:'N'
  cv_space                    CONSTANT VARCHAR2(1)   := ' ';                   -- �X�y�[�X1����
  cv_zero                     CONSTANT VARCHAR2(1)   := '0';                   -- �����^�����F'0'
  cv_1                        CONSTANT VARCHAR2(1)   := '1';                   -- �����^�����F'1'
  cv_2                        CONSTANT VARCHAR2(1)   := '2';                   -- �����^�����F'2'
--
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD START
  cn_zero                     CONSTANT NUMBER        := 0;                     -- ���l�F0
  cn_1                        CONSTANT NUMBER        := 1;                     -- ���l�F1
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD END
--
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  cv_i                        CONSTANT VARCHAR2(1)   := 'I';                   -- ��s�萔�����S�ҁF'I'�i�����j
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  cv_lookup_type_bank         CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_BANK_ACCOUNT'; -- �Q�ƃ^�C�v�F���Ћ�s�������
  cv_lookup_code_bank         CONSTANT VARCHAR2(10)  := 'VDBM_FB';                -- �Q�ƃR�[�h�FVDBM�U��������
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
  cv_lookup_type_fb_not       CONSTANT VARCHAR2(50)  := 'XXCOK1_FB_NOT_TARGET';   -- �Q�ƃ^�C�v�FFB�쐬�ΏۊO�_�~�[����
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
-- Ver.1.12 ADD START
  cv_tax_rounding_rule_down   CONSTANT VARCHAR2(4)   := 'DOWN';                   -- �[�������敪�F�؎̂�
  cv_get_target_amt_with_tax  CONSTANT VARCHAR2(1)   := '3';                      -- �擾�Ώۋ��z�F�x�����z(�ō�)
  cv_snapshot_timing_2_bd     CONSTANT VARCHAR2(1)   := '1';                      -- �X�i�b�v�V���b�g�^�C�~���O�F2�c
  cv_tax_calc_kbn_line        CONSTANT VARCHAR2(1)   := '2';                      -- �Ōv�Z�敪�F���גP��
  cv_tax_kbn_with_tax         CONSTANT VARCHAR2(1)   := '1';                      -- �ŋ敪�F�ō���
-- Ver.1.12 ADD END
-- Ver.1.14 Add Start
  cv_sob_id                   CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';       -- GL��v����ID
  cv_settlement_kbn           CONSTANT VARCHAR2(1)   := '7';                      -- �U���w��敪�i���ϗD��x�j7:�d�M�U��
-- Ver.1.14 Add End
  --
  --===============================
  -- �O���[�o���ϐ�
  --===============================
  -- �o�̓��b�Z�[�W
  gv_out_msg                  VARCHAR2(2000) DEFAULT NULL;                            -- �o�̓��b�Z�[�W
  -- �J�E���^
  gn_target_cnt               NUMBER         DEFAULT NULL;                            -- �Ώی���
  gn_normal_cnt               NUMBER         DEFAULT NULL;                            -- ���팏��
  gn_error_cnt                NUMBER         DEFAULT NULL;                            -- �G���[����
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--  gn_warn_cnt                 NUMBER         DEFAULT NULL;                            -- �X�L�b�v����
  gn_skip_cnt                 NUMBER         DEFAULT NULL;                            -- �X�L�b�v����
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  gn_out_cnt                  NUMBER         DEFAULT NULL;                            -- ��������
  -- �v���t�@�C��
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--  gt_prof_bm_acc_number       fnd_profile_option_values.profile_option_value%TYPE;    -- ��s�����ԍ�
--  gt_prof_bm_bra_number       fnd_profile_option_values.profile_option_value%TYPE;    -- ��s�x�X�ԍ�
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
  gt_prof_bm_request_code     fnd_profile_option_values.profile_option_value%TYPE;    -- �˗��l�R�[�h
  gt_prof_trans_fee_criterion fnd_profile_option_values.profile_option_value%TYPE;    -- �U���z�̊���z
  gt_prof_less_fee_criterion  fnd_profile_option_values.profile_option_value%TYPE;    -- ��s�萔���z(�����)
  gt_prof_more_fee_criterion  fnd_profile_option_values.profile_option_value%TYPE;    -- ��s�萔���z(��ȏ�)
  gt_prof_fb_term_name        fnd_profile_option_values.profile_option_value%TYPE;    -- FB�x������
  gt_prof_bm_tax              fnd_profile_option_values.profile_option_value%TYPE;    -- ����ŗ�
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  gt_prof_org_id              fnd_profile_option_values.profile_option_value%TYPE;    -- �c�ƒP��
  gt_prof_bank_trns_fee_we    fnd_profile_option_values.profile_option_value%TYPE;    -- �U���萔��_����
  gt_prof_bank_trns_fee_ctpty fnd_profile_option_values.profile_option_value%TYPE;    -- �U���萔��_�����
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  gt_prof_acc_type_internal   fnd_profile_option_values.profile_option_value%TYPE;    -- �U���萔��_����_�����g�p
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
  -- ��ʃR�[�h
  gt_values_type_code         fnd_flex_values.attribute1%TYPE;                        -- ��ʃR�[�h
  -- ���t
  gd_pay_date                 DATE;                                                   -- �����̎x����
  gd_proc_date                DATE;                                                   -- �Ɩ��������t
-- Ver.1.14 Add Start
  gt_set_of_books_id          gl_sets_of_books.set_of_books_id%TYPE;                  -- GL��v����ID
  gv_company_code             xxcfo_company_v.company_code%TYPE;                      -- �p�����[�^.��ЃR�[�h
-- Ver.1.14 Add End
  --===============================
  -- �O���[�o���E�J�[�\��
  --===============================
  -- FB�쐬���׃f�[�^�i�U���������O�`�F�b�N�pFB�쐬�����j
  CURSOR bac_fb_line_cur
  IS
  SELECT  pv.segment1                  AS segment1                  -- �d����R�[�h
         ,pvsa.vendor_site_code        AS vendor_site_code          -- �d����T�C�g�R�[�h
         ,abb.bank_number              AS bank_number               -- ��s�ԍ�
         ,abb.bank_name_alt            AS bank_name_alt             -- ��s���J�i
         ,abb.bank_num                 AS bank_num                  -- ��s�x�X�ԍ�
         ,abb.bank_branch_name_alt     AS bank_branch_name_alt      -- ��s�x�X���J�i
         ,abaa.bank_account_type       AS bank_account_type         -- �a�����
         ,abaa.bank_account_num        AS bank_account_num          -- ��s�����ԍ�
         ,abaa.account_holder_name_alt AS account_holder_name_alt   -- �������`�l�J�i
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD START
         ,pvsa.attribute5              AS base_code                 -- �⍇���S�����_�R�[�h
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD END
  FROM    po_vendors                      pv                        -- �d����}�X�^
         ,po_vendor_sites_all             pvsa                      -- �d����T�C�g�}�X�^
         ,ap_bank_account_uses_all        abaua                     -- ��s�����g�p���
         ,ap_bank_accounts_all            abaa                      -- ��s�����}�X�^
         ,ap_bank_branches                abb                       -- ��s�x�X�}�X�^
-- Ver.1.14 Add Start
         ,xxcfr_bd_dept_comp_info_v       xbdciv                    -- �S�����_��Џ��r���[
-- Ver.1.14 Add End
  WHERE pv.vendor_id                   = pvsa.vendor_id
  AND   TRUNC( pvsa.creation_date )    BETWEEN ADD_MONTHS( gd_proc_date, -1 ) AND gd_proc_date
  AND   pvsa.vendor_id                 = abaua.vendor_id
  AND   pvsa.vendor_site_id            = abaua.vendor_site_id
  AND   abaua.external_bank_account_id = abaa.bank_account_id
  AND   abaa.bank_branch_id            = abb.bank_branch_id
  AND   ( pvsa.inactive_date           IS NULL  OR pvsa.inactive_date >= gd_pay_date )
  AND   pvsa.attribute4                IN( cv_1, cv_2 )
  AND   abaua.primary_flag             = cv_yes
  AND   ( gd_pay_date                 >= abaua.start_date  OR abaua.start_date IS NULL )
  AND   ( gd_pay_date                 <= abaua.end_date    OR abaua.end_date   IS NULL )
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  AND    pvsa.org_id                   = TO_NUMBER( gt_prof_org_id )
  AND    abaua.org_id                  = TO_NUMBER( gt_prof_org_id )
  AND    abaa.org_id                   = TO_NUMBER( gt_prof_org_id )
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.14 Add Start
  AND    xbdciv.company_code_bd = gv_company_code                          -- �p�����[�^.��ЃR�[�h
  AND    xbdciv.set_of_books_id = gt_set_of_books_id                       -- GL��v����ID
  AND    xbdciv.dept_code       = pvsa.attribute5                          -- �S�����_
  AND    gd_proc_date BETWEEN NVL(xbdciv.comp_start_date, gd_proc_date)    -- FB�쐬���s���i�Ɩ����t�j
                          AND NVL(xbdciv.comp_end_date,   gd_proc_date)
-- Ver.1.14 Add End
  ORDER BY pv.segment1 ASC;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE START
--  bac_fb_line_rec  bac_fb_line_cur%ROWTYPE;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE END
  -- FB�쐬���׃f�[�^�i�{�U�pFB�f�[�^�쐬�����j
  CURSOR fb_line_cur
  IS
-- Start 2009/04/27 Ver_1.2 T1_0817 M.Hiruta
--  SELECT pv.attribute5                                   AS base_code                -- ���_�R�[�h
  SELECT pvsa.attribute5                                 AS base_code                -- ���_�R�[�h
-- End   2009/04/27 Ver_1.2 T1_0817 M.Hiruta
        ,xbb.supplier_code                               AS supplier_code            -- �d����R�[�h
        ,xbb.supplier_site_code                          AS supplier_site_code       -- �d����T�C�g�R�[�h
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--        ,SUM( xbb.backmargin )                           AS backmargin               -- �̔��萔��
--        ,SUM( xbb.backmargin_tax )                       AS backmargin_tax           -- �̔��萔������Ŋz
--        ,SUM( xbb.electric_amt )                         AS electric_amt             -- �d�C��
--        ,SUM( xbb.electric_amt_tax )                     AS electric_amt_tax         -- �d�C������Ŋz
--        ,SUM( xbb.backmargin + xbb.backmargin_tax +
--              xbb.electric_amt + xbb.electric_amt_tax )  AS trns_amt                 -- �U���z
-- Ver.1.12 MOD START
--        ,SUM( xbb.expect_payment_amt_tax )               AS trns_amt                 -- �U���z
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
        ,xxcok_common_pkg.recalc_pay_amt_f(                       -- [�x�����z�Čv�Z�t�@���N�V����]
           MAX(pvsa.attribute4)                                   -- �x���敪
         , NVL(MAX(xbbs.tax_calc_kbn), cv_tax_calc_kbn_line)      -- �Ōv�Z�敪 ��NULL�̏ꍇ:���גP��
         , NVL(MAX(pvsa.attribute6), cv_tax_kbn_with_tax)         -- �ŋ敪     ��NULL�̏ꍇ:�ō���
         , cv_tax_rounding_rule_down                              -- �[�������敪
         , gt_prof_bm_tax                                         -- �ŗ�
         , NVL(SUM(xbb.backmargin + xbb.electric_amt), 0)         -- �x�����z�i�Ŕ��j   <= �̔��萔�� + �d�C��
         , NVL(SUM(xbb.backmargin_tax + xbb.electric_amt_tax), 0) -- �x�����z�i����Łj <= �̔��萔���i����Ŋz�j + �d�C���i����Ŋz�j
         , NVL(SUM(xbb.expect_payment_amt_tax), 0)                -- �x�����z�i�ō��j   <= �x���\��z�i�ō��j
         , cv_get_target_amt_with_tax                             -- �擾�Ώۋ��z
         )                                               AS trns_amt                 -- �U���z
-- Ver.1.12 MOD END
        ,pvsa.bank_charge_bearer                         AS bank_charge_bearer       -- ��s�萔�����S��
        ,abb.bank_number                                 AS bank_number              -- ��s�ԍ�
        ,abb.bank_name_alt                               AS bank_name_alt            -- ��s���J�i
        ,abb.bank_num                                    AS bank_num                 -- ��s�x�X�ԍ�
        ,abb.bank_branch_name_alt                        AS bank_branch_name_alt     -- ��s�x�X���J�i
        ,abaa.bank_account_type                          AS bank_account_type        -- �a�����
        ,abaa.bank_account_num                           AS bank_account_num         -- ��s�����ԍ�
        ,abaa.account_holder_name_alt                    AS account_holder_name_alt  -- �������`�l�J�i
-- Ver.1.14 Add Start
        ,xbdciv.company_code_bd                          AS company_code             -- ��ЃR�[�h
-- Ver.1.14 Add End
  FROM   xxcok_backmargin_balance      xbb                                           -- �̎�c���e�[�u��
-- Ver.1.12 ADD START
        ,xxcok_bm_balance_snap         xbbs                                          -- �̎�c���e�[�u���X�i�b�v�V���b�g
-- Ver.1.12 ADD END
        ,po_vendors                    pv                                            -- �d����}�X�^
        ,po_vendor_sites_all           pvsa                                          -- �d����T�C�g�}�X�^
        ,ap_bank_account_uses_all      abaua                                         -- ��s�����g�p���
        ,ap_bank_accounts_all          abaa                                          -- ��s�����}�X�^
        ,ap_bank_branches              abb                                           -- ��s�x�X�}�X�^
-- Ver.1.14 Add Start
        ,xxcfr_bd_dept_comp_info_v     xbdciv                                        -- �S�����_��Џ��r���[
-- Ver.1.14 Add End
  WHERE  xbb.fb_interface_status        = cv_zero
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD START
  AND    xbb.gl_interface_status        = cv_zero
  AND    xbb.amt_fix_status             = cv_1
  AND    xbb.payment_amt_tax            = cn_zero
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD END
  AND    xbb.resv_flag                 IS NULL
  AND    xbb.expect_payment_date       <= gd_pay_date
  AND    xbb.supplier_code              = pv.segment1
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE START
--  AND    xbb.supplier_site_code         = pvsa.vendor_site_code
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE END
  AND    pvsa.hold_all_payments_flag    = cv_no
  AND    ( pvsa.inactive_date          IS NULL OR pvsa.inactive_date >= gd_pay_date )
  AND    pvsa.attribute4               IN( cv_1, cv_2 )
  AND    pv.vendor_id                   = pvsa.vendor_id
  AND    pvsa.vendor_id                 = abaua.vendor_id
  AND    pvsa.vendor_site_id            = abaua.vendor_site_id
  AND    abaua.external_bank_account_id = abaa.bank_account_id
  AND    abaa.bank_branch_id            = abb.bank_branch_id
  AND    abaua.primary_flag             = cv_yes
  AND    ( gd_pay_date                 >= abaua.start_date  OR abaua.start_date IS NULL )
  AND    ( gd_pay_date                 <= abaua.end_date    OR abaua.end_date   IS NULL )
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  AND    pvsa.org_id                    = TO_NUMBER( gt_prof_org_id )
  AND    abaua.org_id                   = TO_NUMBER( gt_prof_org_id )
  AND    abaa.org_id                    = TO_NUMBER( gt_prof_org_id )
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Ver.1.12 ADD START
  AND    xbb.bm_balance_id              = xbbs.bm_balance_id(+)            -- �̎�c��ID
  AND    xbbs.snapshot_create_ym(+)     = TO_CHAR(gd_proc_date, 'YYYYMM')  -- �X�i�b�v�V���b�g�쐬�N��   = �Ɩ����t�̔N��
  AND    xbbs.snapshot_timing(+)        = cv_snapshot_timing_2_bd          -- �X�i�b�v�V���b�g�^�C�~���O = 2�c
-- Ver.1.12 ADD END
-- Ver.1.14 Add Start
  AND    xbdciv.company_code_bd = gv_company_code                          -- �p�����[�^.��ЃR�[�h
  AND    xbdciv.set_of_books_id = gt_set_of_books_id                       -- GL��v����ID
  AND    xbdciv.dept_code       = pvsa.attribute5                          -- �S�����_
  AND    gd_proc_date BETWEEN NVL(xbdciv.comp_start_date, gd_proc_date)    -- FB�쐬���s���i�Ɩ����t�j
                          AND NVL(xbdciv.comp_end_date,   gd_proc_date)
-- Ver.1.14 Add End
-- Start 2009/04/27 Ver_1.2 T1_0817 M.Hiruta
--  GROUP BY pv.attribute5
  GROUP BY pvsa.attribute5
-- End   2009/04/27 Ver_1.2 T1_0817 M.Hiruta
          ,xbb.supplier_code
          ,xbb.supplier_site_code
          ,pvsa.bank_charge_bearer
          ,abb.bank_number
          ,abb.bank_name_alt
          ,abb.bank_num
          ,abb.bank_branch_name_alt
          ,abaa.bank_account_type
          ,abaa.bank_account_num
          ,abaa.account_holder_name_alt
-- Ver.1.14 Add Start
          ,xbdciv.company_code_bd
-- Ver.1.14 Add End
-- Start 2009/04/27 Ver_1.2 T1_0817 M.Hiruta
--  ORDER BY pv.attribute5 ASC
  ORDER BY pvsa.attribute5 ASC
-- End   2009/04/27 Ver_1.2 T1_0817 M.Hiruta
          ,xbb.supplier_code  ASC;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE START
--  fb_line_rec  fb_line_cur%ROWTYPE;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE END
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
  -- FB�쐬�ΏۊO�_�~�[�����擾�J�[�\��
  CURSOR dmy_acct_cur
  IS
  SELECT flv.attribute1  AS  bank_number         --��s�ԍ�
        ,flv.attribute2  AS  bank_num            --�x�X�ԍ�
        ,flv.attribute3  AS  bank_account_type   --�������
        ,flv.attribute4  AS  bank_account_num    --�����ԍ�
  FROM   fnd_lookup_values flv
  WHERE  flv.lookup_type  = cv_lookup_type_fb_not
  AND    flv.enabled_flag = cv_yes
  AND    gd_pay_date BETWEEN NVL(flv.start_date_active, gd_pay_date)
                         AND NVL(flv.end_date_active, gd_pay_date)
  AND    flv.language     = USERENV('LANG')
  ;
  TYPE g_dmy_acct_ttype IS TABLE OF dmy_acct_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_dmy_acct_tab       g_dmy_acct_ttype;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
  --================================
  -- �O���[�o���ETABLE�^
  --================================
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE START
--  -- FB�쐬���׃f�[�^�i�U���������O�`�F�b�N�pFB�쐬�����j
--  TYPE bac_fb_line_ttpye IS TABLE OF bac_fb_line_cur%ROWTYPE
--  INDEX BY BINARY_INTEGER;
--  gt_bac_fb_line_tab    bac_fb_line_ttpye;
--  -- FB�쐬���׃f�[�^�i�{�U�pFB�f�[�^�쐬�����j
--  TYPE fb_line_ttpye IS TABLE OF fb_line_cur%ROWTYPE
--  INDEX BY BINARY_INTEGER;
--  gt_fb_line_tab        fb_line_ttpye;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE END
  --=================================
  -- ���ʗ�O
  --=================================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ���b�N�擾���ʗ�O ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- �v���O�}
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver.1.14 Add Start
    ,iv_company_code IN  VARCHAR2   -- �p�����[�^�F��ЃR�[�h
-- Ver.1.14 Add End
    ,iv_proc_type  IN  VARCHAR2     -- �����p�����[�^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name      CONSTANT       VARCHAR2(100) := 'init';     -- �v���O������
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE START
--    cn_zero          CONSTANT       NUMBER        := 0;          -- ���l:0
--    cn_1             CONSTANT       NUMBER        := 1;          -- ���l:1
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE END
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;          -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;          -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;          -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000) DEFAULT NULL;          -- ���b�Z�[�W
    ld_close_date    DATE;                                 -- ���ߓ�
    ld_pay_date      DATE;                                 -- �x����
    lv_profile       VARCHAR2(35)   DEFAULT NULL;          -- �v���t�@�C��
    lb_retcode       BOOLEAN;                              -- ���^�[���E�R�[�h
    --===============================
    -- ���[�J����O
    --===============================
    --*** �Ɩ��������t�擾��O ***
    no_process_date_expt     EXCEPTION;
    --*** �v���t�@�C���̎擾��O ***
    no_profile_expt          EXCEPTION;
    --*** �l�Z�b�g�擾��O ***
    values_err_expt          EXCEPTION;
    --*** �x�����擾��O ***
    no_pay_date_expt         EXCEPTION;
-- Ver.1.14 Add Start
    --*** ����������O ***
    init_expt                EXCEPTION;
-- Ver.1.14 Add End
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --==========================================================
    --�R���J�����g�v���O�������͍��ڂ����b�Z�[�W�o�͂���
    --==========================================================
-- Ver.1.14 Add Start
    -- �p�����[�^�F��ЃR�[�h�̏o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok
                   ,iv_name         => cv_msg_cok_10878
                   ,iv_token_name1  => cv_token_company_code
                   ,iv_token_value1 => iv_company_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG         -- �o�͋敪
                   ,iv_message  => lv_out_msg           -- ���b�Z�[�W
                   ,in_new_line => 0                    -- ���s
                  );
    -- �p�����[�^�F���s�敪�̏o��
-- Ver.1.14 Add End
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok
                   ,iv_name         => cv_msg_cok_00044
                   ,iv_token_name1  => cv_token_proc_type
                   ,iv_token_value1 => iv_proc_type
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG         -- �o�͋敪
                   ,iv_message  => lv_out_msg           -- ���b�Z�[�W
                   ,in_new_line => 1                    -- ���s
                  );
    --==========================================================
    --�Ɩ��������t�擾
    --==========================================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF( gd_proc_date IS NULL ) THEN
      -- �Ɩ��������t�擾�G���[���b�Z�[�W
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00028
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      RAISE no_process_date_expt;
    END IF;
    --==========================================================
    --�J�X�^���E�v���t�@�C���̎擾
    --==========================================================
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--    gt_prof_bm_acc_number       := FND_PROFILE.VALUE( cv_prof_bm_acc_number );        -- ��s�����ԍ�
--    gt_prof_bm_bra_number       := FND_PROFILE.VALUE( cv_prof_bm_bra_number );        -- ��s�x�X�ԍ�
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
    gt_prof_bm_request_code     := FND_PROFILE.VALUE( cv_prof_bm_request_code );      -- �˗��l�R�[�h
    gt_prof_trans_fee_criterion := FND_PROFILE.VALUE( cv_prof_trans_criterion );      -- �U���z�̊���z
    gt_prof_less_fee_criterion  := FND_PROFILE.VALUE( cv_prof_less_fee_criterion );   -- ��s�萔���z(�����)
    gt_prof_more_fee_criterion  := FND_PROFILE.VALUE( cv_prof_more_fee_criterion );   -- ��s�萔���z(��ȏ�)
    gt_prof_fb_term_name        := FND_PROFILE.VALUE( cv_prof_fb_term_name );         -- FB�x������
    gt_prof_bm_tax              := FND_PROFILE.VALUE( cv_prof_bm_tax );               -- ����ŗ�
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    gt_prof_org_id              := FND_PROFILE.VALUE( cv_prof_org_id );               -- �c�ƒP��
    gt_prof_bank_trns_fee_we    := FND_PROFILE.VALUE( cv_prof_bank_trns_fee_we );     -- �U���萔��_����
    gt_prof_bank_trns_fee_ctpty := FND_PROFILE.VALUE( cv_prof_bank_trns_fee_ctpty );  -- �U���萔��_�����
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
    gt_prof_acc_type_internal   := FND_PROFILE.VALUE( cv_prof_acc_type_internal );    -- �U���萔��_����_�����g�p
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
-- Ver.1.14 Add Start
    gt_set_of_books_id          := FND_PROFILE.VALUE( cv_sob_id );                    -- GL��v����ID
-- Ver.1.14 Add End
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
--    -- �v���t�@�C���l�擾�G���[
--    IF( gt_prof_bm_acc_number IS NULL ) THEN
--      lv_profile := cv_prof_bm_acc_number;
--      RAISE no_profile_expt;
--    END IF;
--    -- �v���t�@�C���l�擾�G���[
--    IF( gt_prof_bm_bra_number IS NULL ) THEN
--      lv_profile := cv_prof_bm_bra_number;
--      RAISE no_profile_expt;
--    END IF;
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta DELETE
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_bm_request_code IS NULL ) THEN
      lv_profile := cv_prof_bm_request_code;
      RAISE no_profile_expt;
    END IF;
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_trans_fee_criterion IS NULL ) THEN
      lv_profile := cv_prof_trans_criterion;
      RAISE no_profile_expt;
    END IF;
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_less_fee_criterion IS NULL ) THEN
      lv_profile := cv_prof_less_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_more_fee_criterion IS NULL ) THEN
      lv_profile := cv_prof_more_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_fb_term_name IS NULL ) THEN
      lv_profile := cv_prof_fb_term_name;
      RAISE no_profile_expt;
    END IF;
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_bm_tax IS NULL ) THEN
      lv_profile := cv_prof_bm_tax;
      RAISE no_profile_expt;
    END IF;
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_org_id IS NULL ) THEN
      lv_profile := cv_prof_org_id;
      RAISE no_profile_expt;
    END IF;
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_bank_trns_fee_we IS NULL ) THEN
      lv_profile := cv_prof_bank_trns_fee_we;
      RAISE no_profile_expt;
    END IF;
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_bank_trns_fee_ctpty IS NULL ) THEN
      lv_profile := cv_prof_bank_trns_fee_ctpty;
      RAISE no_profile_expt;
    END IF;
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
    -- �v���t�@�C���l�擾�G���[
    IF( gt_prof_acc_type_internal IS NULL ) THEN
      lv_profile := cv_prof_acc_type_internal;
      RAISE no_profile_expt;
    END IF;
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta ADD
-- Ver.1.14 Add Start
    -- �v���t�@�C���l�擾�G���[
    IF( gt_set_of_books_id IS NULL ) THEN
      lv_profile := cv_sob_id;
      RAISE no_profile_expt;
    END IF;
--
    -- ��ЃR�[�h�`�F�b�N
    BEGIN
      SELECT company_code AS company_code INTO gv_company_code
      FROM   xxcfo_company_v
      WHERE  company_code  = iv_company_code;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        gv_company_code := NULL;
      WHEN OTHERS THEN
        gv_company_code := NULL;
    END;
    IF( gv_company_code IS NULL ) THEN
      -- ��ЃR�[�h�擾�G���[���b�Z�[�W
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_10879
                     ,iv_token_name1  => cv_token_company_code
                     ,iv_token_value1 => iv_company_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      RAISE init_expt;
    END IF;
-- Ver.1.14 Add End
    --=========================================================
    --�����̎x�������擾����
    --=========================================================
    -- ���߁E�x�����擾
    xxcok_common_pkg.get_close_date_p(
      ov_errbuf     => lv_errbuf
     ,ov_retcode    => lv_retcode
     ,ov_errmsg     => lv_errmsg
     ,iv_pay_cond   => gt_prof_fb_term_name
     ,od_close_date => ld_close_date
     ,od_pay_date   => ld_pay_date
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- ���߁E�x�����擾�G���[���b�Z�[�W
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_00036
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      RAISE no_pay_date_expt;
    END IF;
    -- �c�Ɠ��擾
    gd_pay_date := xxcok_common_pkg.get_operating_day_f(
                     id_proc_date => ld_pay_date
                    ,in_days      => cn_zero
                    ,in_proc_type => cn_1
                   );
--
    BEGIN
      --=========================================================
      -- ��ʃR�[�h���擾����
      --=========================================================
      SELECT ffv.attribute1     AS type_code   -- ��ʃR�[�h
      INTO   gt_values_type_code               -- ��ʃR�[�h
      FROM   fnd_flex_value_sets   ffvs        -- �l�Z�b�g
            ,fnd_flex_values       ffv         -- �l�Z�b�g�l
      WHERE ffv.value_category     = cv_value_cok_fb_proc_type
      AND   ffvs.flex_value_set_id = ffv.flex_value_set_id
      AND   ffv.flex_value         = iv_proc_type
      AND   ffv.enabled_flag       = cv_yes
      AND   gd_proc_date BETWEEN NVL( ffv.start_date_active, gd_proc_date )
                         AND     NVL( ffv.end_date_active, gd_proc_date );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                       ,iv_name         => cv_msg_cok_00014
                       ,iv_token_name1  => cv_token_flex_value_set
                       ,iv_token_value1 => cv_value_cok_fb_proc_type
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG       -- �o�͋敪
                       ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                       ,in_new_line => 0                  -- ���s
                      );
      RAISE values_err_expt;
    END;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
    --=========================================================
    --FB�쐬�ΏۊO�_�~�[�������擾����
    --=========================================================
    OPEN dmy_acct_cur;
    FETCH dmy_acct_cur BULK COLLECT INTO g_dmy_acct_tab;
    CLOSE dmy_acct_cur;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
--
  EXCEPTION
-- Ver.1.14 Add Start
    WHEN init_expt THEN
    --*** ����������O ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
-- Ver.1.14 Add End
    WHEN no_process_date_expt THEN
      -- *** �Ɩ��������t�擾��O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN no_profile_expt THEN
      -- *** �v���t�@�C���擾��O�n���h�� ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_00003
                     ,iv_token_name1  => cv_token_profile
                     ,iv_token_value1 => lv_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN no_pay_date_expt THEN
      -- *** ���߁E�x�����擾��O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN values_err_expt THEN
      -- *** �l�Z�b�g�擾��O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END init;
--
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE START
--  /**********************************************************************************
--   * Procedure Name   : get_bank_acct_chk_fb_line
--   * Description      : FB�쐬���׃f�[�^�̎擾�i�U���������O�`�F�b�N�pFB�쐬�����j(A-2)
--   ***********************************************************************************/
--  PROCEDURE get_bank_acct_chk_fb_line(
--     ov_errbuf  OUT VARCHAR2            -- �G���[�E���b�Z�[�W
--    ,ov_retcode OUT VARCHAR2            -- ���^�[���E�R�[�h
--    ,ov_errmsg  OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
--  )
--  IS
--    --===============================
--    -- ���[�J���萔
--    --===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bank_acct_chk_fb_line'; -- FB�쐬���׃f�[�^�̎擾
--    --===============================
--    -- ���[�J���ϐ�
--    --===============================
--    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;          -- �G���[�E���b�Z�[�W
--    lv_retcode    VARCHAR2(1)    DEFAULT NULL;          -- ���^�[���E�R�[�h
--    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;          -- ���[�U�[�E�G���[�E���b�Z�[�W
--    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;          -- ���b�Z�[�W
--    lb_retcode    BOOLEAN;                              -- ���^�[���E�R�[�h
--    --===============================
--    -- ���[�J����O
--    --===============================
--    --*** �f�[�^�擾��O ***
--    no_data_expt  EXCEPTION;
----
--  BEGIN
--    -- �X�e�[�^�X������
--    ov_retcode := cv_status_normal;
----
--    OPEN bac_fb_line_cur;
--      FETCH bac_fb_line_cur BULK COLLECT INTO gt_bac_fb_line_tab;
--    CLOSE bac_fb_line_cur;
--    --==================================================
--    -- FB�쐬���׏��擾�G���[
--    --==================================================
--    IF( gt_bac_fb_line_tab.COUNT = 0 ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application => cv_appli_xxcok
--                      ,iv_name        => cv_msg_cok_10254
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG       -- �o�͋敪
--                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
--                     ,in_new_line => 1                  -- ���s
--                    );
--      RAISE no_data_expt;
--    END IF;
----
--  EXCEPTION
--    WHEN no_data_expt THEN
--    -- *** FB�쐬���׏��擾��O�n���h�� ****
--      ov_errmsg  := lv_errmsg;
--      ov_retcode := cv_status_normal;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END get_bank_acct_chk_fb_line;
----
--  /**********************************************************************************
--   * Procedure Name   : get_fb_line
--   * Description      : FB�쐬���׃f�[�^�̎擾�i�{�U�pFB�f�[�^�쐬�����j(A-3)
--   ***********************************************************************************/
--  PROCEDURE get_fb_line(
--     ov_errbuf  OUT VARCHAR2       -- �G���[�E���b�Z�[�W
--    ,ov_retcode OUT VARCHAR2       -- ���^�[���E�R�[�h
--    ,ov_errmsg  OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W
--  )
--  IS
--    --===============================
--    -- ���[�J���萔
--    --===============================
--    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_fb_line'; -- �v���O������
--    --================================
--    -- ���[�J���ϐ�
--    --================================
--    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
--    lv_retcode   VARCHAR2(1)    DEFAULT NULL;              -- ���^�[���E�R�[�h
--    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--    lv_out_msg   VARCHAR2(2000) DEFAULT NULL;              -- ���b�Z�[�W
--    lb_retcode   BOOLEAN;                                  -- ���^�[���E�R�[�h
--    --===============================
--    -- ���[�J����O
--    --===============================
--    --*** �f�[�^�擾��O ***
--    no_data_expt  EXCEPTION;
----
--  BEGIN
--    -- �X�e�[�^�X������
--    ov_retcode := cv_status_normal;
--    --
--    OPEN fb_line_cur;
--      FETCH fb_line_cur BULK COLLECT INTO gt_fb_line_tab;
--    CLOSE fb_line_cur;
--    --======================================================
--    -- FB�쐬���׏��擾�G���[
--    --======================================================
--    IF( gt_fb_line_tab.COUNT = 0 ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application => cv_appli_xxcok
--                      ,iv_name        => cv_msg_cok_10254
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG       -- �o�͋敪
--                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
--                     ,in_new_line => 1                  -- ���s
--                    );
--      RAISE no_data_expt;
--    END IF;
----
--  EXCEPTION
--    WHEN no_data_expt THEN
--      -- *** FB�쐬���׏��擾��O�n���h�� ****
--      ov_errmsg  := lv_errmsg;
--      ov_retcode := cv_status_normal;
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END get_fb_line;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi DELETE END
--
  /**********************************************************************************
   * Procedure Name   : get_fb_header
   * Description      : FB�쐬�w�b�_�[�f�[�^�̎擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_fb_header(
     ov_errbuf                  OUT VARCHAR2                                            -- �G���[�E���b�Z�[�W
    ,ov_retcode                 OUT VARCHAR2                                            -- ���^�[���E�R�[�h
    ,ov_errmsg                  OUT VARCHAR2                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ot_bank_number             OUT ap_bank_branches.bank_number%TYPE                   -- ��s�ԍ�
    ,ot_bank_name_alt           OUT ap_bank_branches.bank_name_alt%TYPE                 -- ��s���J�i
    ,ot_bank_num                OUT ap_bank_branches.bank_num%TYPE                      -- ��s�x�X�ԍ�
    ,ot_bank_branch_name_alt    OUT ap_bank_branches.bank_branch_name_alt%TYPE          -- ��s�x�X���J�i
    ,ot_bank_account_type       OUT ap_bank_accounts_all.bank_account_type%TYPE         -- �a�����
    ,ot_bank_account_num        OUT ap_bank_accounts_all.bank_account_num%TYPE          -- ��s�����ԍ�
    ,ot_account_holder_name_alt OUT ap_bank_accounts_all.account_holder_name_alt%TYPE   -- �������`�l�J�i
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fb_header';                            -- �v���O������
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;                            -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;                            -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                  VARCHAR2(2000) DEFAULT NULL;                            -- ���b�Z�[�W
    lb_retcode                  BOOLEAN;                                                -- ���^�[���E�R�[�h
    lt_bank_number              ap_bank_branches.bank_number%TYPE;                      -- ��s�ԍ�
    lt_bank_name_alt            ap_bank_branches.bank_name_alt%TYPE;                    -- ��s���J�i
    lt_bank_num                 ap_bank_branches.bank_num%TYPE;                         -- ��s�x�X�ԍ�
    lt_bank_branch_name_alt     ap_bank_branches.bank_branch_name_alt%TYPE;             -- ��s�x�X���J�i
    lt_bank_account_type        ap_bank_accounts_all.bank_account_type%TYPE;            -- �a�����
    lt_bank_account_num         ap_bank_accounts_all.bank_account_num%TYPE;             -- ��s�����ԍ�
    lt_account_holder_name_alt  ap_bank_accounts_all.account_holder_name_alt%TYPE;      -- �������`�l�J�i
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --=========================================
    -- FB�쐬�w�b�_�[�f�[�^�̎擾(A-4)
    --=========================================
-- Start 2009/08/03 Ver.1.6 0000843 M.Hiruta REPAIR
--    SELECT  abb.bank_number               AS  bank_number             -- ��s�ԍ�
--           ,abb.bank_name_alt             AS  bank_name_alt           -- ��s���J�i
--           ,abb.bank_num                  AS  bank_num                -- ��s�x�X�ԍ�
--           ,abb.bank_branch_name_alt      AS  bank_branch_name_alt    -- ��s�x�X���J�i
--           ,abaa.bank_account_type        AS  bank_account_type       -- �a�����
--           ,abaa.bank_account_num         AS  bank_account_num        -- ��s�����ԍ�
--           ,abaa.account_holder_name_alt  AS  account_holder_name_alt -- �������`�l�J�i
--    INTO    lt_bank_number                                            -- ��s�ԍ�
--           ,lt_bank_name_alt                                          -- ��s���J�i
--           ,lt_bank_num                                               -- ��s�x�X�ԍ�
--           ,lt_bank_branch_name_alt                                   -- ��s�x�X���J�i
--           ,lt_bank_account_type                                      -- �a�����
--           ,lt_bank_account_num                                       -- ��s�����ԍ�
--           ,lt_account_holder_name_alt                                -- �������`�l�J�i
--    FROM    ap_bank_accounts_all          abaa                        -- ��s�����}�X�^
--           ,ap_bank_branches              abb                         -- ��s�x�X�}�X�^
--    WHERE  abaa.bank_account_num = gt_prof_bm_acc_number
--    AND    abaa.bank_branch_id   = abb.bank_branch_id
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    AND    abaa.org_id           = TO_NUMBER( gt_prof_org_id )
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    AND    abb.bank_num          = gt_prof_bm_bra_number;
    SELECT  abb.bank_number               AS  bank_number             -- ��s�ԍ�
           ,abb.bank_name_alt             AS  bank_name_alt           -- ��s���J�i
           ,abb.bank_num                  AS  bank_num                -- ��s�x�X�ԍ�
           ,abb.bank_branch_name_alt      AS  bank_branch_name_alt    -- ��s�x�X���J�i
           ,abaa.bank_account_type        AS  bank_account_type       -- �a�����
           ,abaa.bank_account_num         AS  bank_account_num        -- ��s�����ԍ�
           ,abaa.account_holder_name_alt  AS  account_holder_name_alt -- �������`�l�J�i
    INTO    lt_bank_number                                            -- ��s�ԍ�
           ,lt_bank_name_alt                                          -- ��s���J�i
           ,lt_bank_num                                               -- ��s�x�X�ԍ�
           ,lt_bank_branch_name_alt                                   -- ��s�x�X���J�i
           ,lt_bank_account_type                                      -- �a�����
           ,lt_bank_account_num                                       -- ��s�����ԍ�
           ,lt_account_holder_name_alt                                -- �������`�l�J�i
    FROM    ap_bank_accounts_all          abaa                        -- ��s�����}�X�^
           ,ap_bank_branches              abb                         -- ��s�x�X�}�X�^
           ,fnd_lookup_values             flv                         -- �Q�ƃR�[�h
    WHERE  abaa.bank_branch_id    = abb.bank_branch_id
    AND    abb.bank_number        = flv.attribute1            -- ��s�ԍ�
    AND    abb.bank_num           = flv.attribute2            -- ��s�x�X�ԍ�
    AND    abaa.account_type      = gt_prof_acc_type_internal -- �����g�p
    AND    abaa.bank_account_type = flv.attribute3            -- �������
    AND    abaa.bank_account_num  = flv.attribute4            -- ��s�����ԍ�
    AND    abaa.org_id            = TO_NUMBER( gt_prof_org_id )
    AND    flv.lookup_type        = cv_lookup_type_bank
    AND    flv.lookup_code        = cv_lookup_code_bank
    AND    flv.enabled_flag       = cv_yes
    AND    gd_proc_date           BETWEEN flv.start_date_active
                                  AND     NVL( flv.end_date_active, gd_proc_date )
    AND    flv.language           = USERENV('LANG');
-- End   2009/08/03 Ver.1.6 0000843 M.Hiruta REPAIR
--
    ot_bank_number             := lt_bank_number;                    -- ��s�ԍ�
    ot_bank_name_alt           := lt_bank_name_alt;                  -- ��s���J�i
    ot_bank_num                := lt_bank_num;                       -- ��s�x�X�ԍ�
    ot_bank_branch_name_alt    := lt_bank_branch_name_alt;           -- ��s�x�X���J�i
    ot_bank_account_type       := lt_bank_account_type;              -- �a�����
    ot_bank_account_num        := lt_bank_account_num;               -- ��s�����ԍ�
    ot_account_holder_name_alt := lt_account_holder_name_alt;        -- �������`�l�J�i
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** FB�쐬�w�b�_�[���擾��O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10255
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** FB�쐬�w�b�_�[���d����O�n���h�� ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10256
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_fb_header;
--
  /**********************************************************************************
   * Procedure Name   : storage_fb_header
   * Description      : FB�쐬�w�b�_�[�f�[�^�̊i�[(A-5)
   ***********************************************************************************/
  PROCEDURE storage_fb_header(
     ov_errbuf                  OUT VARCHAR2                                            -- �G���[�E���b�Z�[�W
    ,ov_retcode                 OUT VARCHAR2                                            -- ���^�[���E�R�[�h
    ,ov_errmsg                  OUT VARCHAR2                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_fb_header_data          OUT VARCHAR2                                            -- FB�쐬�w�b�_�[���R�[�h
    ,it_bank_number             IN  ap_bank_branches.bank_number%TYPE                   -- ��s�ԍ�
    ,it_bank_name_alt           IN  ap_bank_branches.bank_name_alt%TYPE                 -- ��s���J�i
    ,it_bank_num                IN  ap_bank_branches.bank_num%TYPE                      -- ��s�x�X�ԍ�
    ,it_bank_branch_name_alt    IN  ap_bank_branches.bank_branch_name_alt%TYPE          -- ��s�x�X���J�i
    ,it_bank_account_type       IN  ap_bank_accounts_all.bank_account_type%TYPE         -- �a�����
    ,it_bank_account_num        IN  ap_bank_accounts_all.bank_account_num%TYPE          -- ��s�����ԍ�
    ,it_account_holder_name_alt IN  ap_bank_accounts_all.account_holder_name_alt%TYPE   -- �������`�l�J�i
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'storage_fb_header';   -- �v���O������
    cv_code_type   CONSTANT VARCHAR2(1)   := '0';                   -- �R�[�h�敪
    cv_zero        CONSTANT VARCHAR2(1)   := '0';                   -- '0'
    cv_data_type   CONSTANT VARCHAR2(1)   := '1';                   -- �f�[�^�敪
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                  VARCHAR2(2000) DEFAULT NULL;       -- ���b�Z�[�W
    lv_data_type                VARCHAR2(1)    DEFAULT NULL;       -- �f�[�^�敪
    lv_type_code                VARCHAR2(2)    DEFAULT NULL;       -- ��ʃR�[�h
    lv_code_type                VARCHAR2(1)    DEFAULT NULL;       -- �R�[�h�敪
    lv_sc_client_code           VARCHAR2(10)   DEFAULT NULL;       -- �˗��l�R�[�h
    lv_client_name              VARCHAR2(40)   DEFAULT NULL;       -- �˗��l��
    lv_pay_date                 VARCHAR2(4)    DEFAULT NULL;       -- �U���w���
    lv_bank_number              VARCHAR2(4)    DEFAULT NULL;       -- �d�����Z�@�֔ԍ�
    lv_bank_name_alt            VARCHAR2(15)   DEFAULT NULL;       -- �d�����Z�@�֖�
    lv_bank_num                 VARCHAR2(3)    DEFAULT NULL;       -- �d���x�X�ԍ�
    lv_bank_branch_name_alt     VARCHAR2(15)   DEFAULT NULL;       -- �d���x�X��
    lv_bank_account_type        VARCHAR2(1)    DEFAULT NULL;       -- �a����ځi�˗��l�j
    lv_bank_account_num         VARCHAR2(7)    DEFAULT NULL;       -- �����ԍ��i�˗��l�j
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;       -- �_�~�[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
--
    lv_data_type            := cv_data_type;                                              -- �f�[�^�敪
    lv_type_code            := LPAD( gt_values_type_code, 2, cv_zero );                   -- ��ʃR�[�h
    lv_code_type            := cv_code_type;                                              -- �R�[�h�敪
    lv_sc_client_code       := LPAD( gt_prof_bm_request_code, 10, cv_zero );              -- �˗��l�R�[�h
    lv_client_name          := RPAD( NVL( it_account_holder_name_alt, cv_space ), 40 );   -- �˗��l��
    lv_pay_date             := TO_CHAR( gd_pay_date, 'MMDD' );                            -- �U���w���
    lv_bank_number          := LPAD( NVL( it_bank_number, cv_zero ), 4, cv_zero );        -- �d�����Z�@�֔ԍ�
    lv_bank_name_alt        := RPAD( NVL( it_bank_name_alt, cv_space ), 15 );             -- �d�����Z�@�֖�
    lv_bank_num             := LPAD( NVL( it_bank_num, cv_zero ), 3, cv_zero );           -- �d���x�X�ԍ�
    lv_bank_branch_name_alt := RPAD( NVL( it_bank_branch_name_alt, cv_space ), 15 );      -- �d���x�X��
    lv_bank_account_type    := NVL( it_bank_account_type, cv_zero );                      -- �a�����(�˗��l)
    lv_bank_account_num     := LPAD( NVL( it_bank_account_num, cv_zero ), 7, cv_zero );   -- �����ԍ�(�˗��l)
    lv_dummy                := LPAD( cv_space, 17, cv_space );                            -- �_�~�[
--
    ov_fb_header_data       := lv_data_type            ||                     -- �f�[�^�敪
                               lv_type_code            ||                     -- ��ʃR�[�h
                               lv_code_type            ||                     -- �R�[�h�敪
                               lv_sc_client_code       ||                     -- �˗��l�R�[�h
                               lv_client_name          ||                     -- �˗��l��
                               lv_pay_date             ||                     -- �U���w���
                               lv_bank_number          ||                     -- �d�����Z�@�֔ԍ�
                               lv_bank_name_alt        ||                     -- �d�����Z�@�֖�
                               lv_bank_num             ||                     -- �d���x�X�ԍ�
                               lv_bank_branch_name_alt ||                     -- �d���x�X��
                               lv_bank_account_type    ||                     -- �a�����(�˗��l)
                               lv_bank_account_num     ||                     -- �����ԍ�(�˗��l)
                               lv_dummy;                                      -- �_�~�[
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_header;
--
  /**********************************************************************************
   * Procedure Name   : storage_bank_acct_chk_fb_line
   * Description      : FB�쐬���׃f�[�^�̊i�[�i�U���������O�`�F�b�N�pFB�쐬�����j(A-7)
   ***********************************************************************************/
  PROCEDURE storage_bank_acct_chk_fb_line(
     ov_errbuf       OUT VARCHAR2           -- �G���[�E���b�Z�[�W
    ,ov_retcode      OUT VARCHAR2           -- ���^�[���E�R�[�h
    ,ov_errmsg       OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_fb_line_data OUT VARCHAR2           -- FB�쐬���׃��R�[�h
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt          IN  NUMBER             -- �����J�E���^
    ,i_bac_fb_line_rec IN  bac_fb_line_cur%ROWTYPE  -- FB�쐬���׃f�[�^
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'storage_bank_acct_chk_fb_line';  -- FB�쐬���׃f�[�^�̊i�[
    cv_data_type       CONSTANT VARCHAR2(1)   := '2';                              -- '2' �f�[�^�敪
    --=================================
    -- ���[�J���ϐ�
    --=================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;         -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;         -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;         -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    lv_data_type                VARCHAR2(1)    DEFAULT NULL;         -- �f�[�^�敪
    lv_bank_number              VARCHAR2(4)    DEFAULT NULL;         -- ��d�����Z�@�֔ԍ�
    lv_bank_name_alt            VARCHAR2(15)   DEFAULT NULL;         -- ��d�����Z�@�֖�
    lv_bank_num                 VARCHAR2(3)    DEFAULT NULL;         -- ��d���x�X�ԍ�
    lv_bank_branch_name_alt     VARCHAR2(15)   DEFAULT NULL;         -- ��d���x�X��
    lv_clearinghouse_no         VARCHAR2(4)    DEFAULT NULL;         -- ��`�������ԍ�
    lv_bank_account_type        VARCHAR2(1)    DEFAULT NULL;         -- �a�����
    lv_bank_account_num         VARCHAR2(7)    DEFAULT NULL;         -- �����ԍ�
    lv_account_holder_name_alt  VARCHAR2(30)   DEFAULT NULL;         -- ���l��
    lv_transfer_amount          VARCHAR2(17)   DEFAULT NULL;         -- �U�����z
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD START
--    lv_base_code                VARCHAR2(4)    DEFAULT NULL;         -- ���_�R�[�h
--    lv_supplier_code            VARCHAR2(9)    DEFAULT NULL;         -- �d����R�[�h
    lv_base_code                VARCHAR2(10)   DEFAULT NULL;         -- ���_�R�[�h
    lv_supplier_code            VARCHAR2(10)   DEFAULT NULL;         -- �d����R�[�h
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD END
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;         -- �_�~�[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
--
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    lv_data_type               := cv_data_type;                                                                      -- �f�[�^�敪
--    lv_bank_number             := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_number, cv_zero ), 4, cv_zero );      -- ��d�����Z�@�֔ԍ�
--    lv_bank_name_alt           := RPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_name_alt, cv_space ), 15 );           -- ��d�����Z�@�֖�
--    lv_bank_num                := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_num, cv_zero ), 3, cv_zero );         -- ��d���x�X�ԍ�
--    lv_bank_branch_name_alt    := RPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_branch_name_alt, cv_space ), 15 );    -- ��d���x�X��
--    lv_clearinghouse_no        := LPAD( cv_space, 4, cv_space );                                                     -- ��`�������ԍ�
--    lv_bank_account_type       := NVL( gt_bac_fb_line_tab( in_cnt ).bank_account_type, cv_zero );                    -- �a�����
--    lv_bank_account_num        := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).bank_account_num, cv_zero ), 7, cv_zero ); -- �����ԍ�
--    lv_account_holder_name_alt := RPAD( NVL( gt_bac_fb_line_tab( in_cnt ).account_holder_name_alt, cv_space ), 30 ); -- ���l��
--    lv_transfer_amount         := LPAD( cv_zero, 10, cv_zero );                                                      -- �U�����z
--    lv_base_code               := LPAD( cv_space, 4, cv_space );                                                     -- ���_�R�[�h
--    lv_supplier_code           := LPAD( NVL( gt_bac_fb_line_tab( in_cnt ).segment1, cv_space ), 9 );                 -- �d����R�[�h
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                    -- �_�~�[
    lv_data_type               := cv_data_type;                                                                      -- �f�[�^�敪
    lv_bank_number             := LPAD( NVL( i_bac_fb_line_rec.bank_number, cv_zero ), 4, cv_zero );      -- ��d�����Z�@�֔ԍ�
    lv_bank_name_alt           := RPAD( NVL( i_bac_fb_line_rec.bank_name_alt, cv_space ), 15 );           -- ��d�����Z�@�֖�
    lv_bank_num                := LPAD( NVL( i_bac_fb_line_rec.bank_num, cv_zero ), 3, cv_zero );         -- ��d���x�X�ԍ�
    lv_bank_branch_name_alt    := RPAD( NVL( i_bac_fb_line_rec.bank_branch_name_alt, cv_space ), 15 );    -- ��d���x�X��
    lv_clearinghouse_no        := LPAD( cv_space, 4, cv_space );                                                     -- ��`�������ԍ�
    lv_bank_account_type       := NVL( i_bac_fb_line_rec.bank_account_type, cv_zero );                    -- �a�����
    lv_bank_account_num        := LPAD( NVL( i_bac_fb_line_rec.bank_account_num, cv_zero ), 7, cv_zero ); -- �����ԍ�
    lv_account_holder_name_alt := RPAD( NVL( i_bac_fb_line_rec.account_holder_name_alt, cv_space ), 30 ); -- ���l��
    lv_transfer_amount         := LPAD( cv_zero, 10, cv_zero );                                                      -- �U�����z
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD START
--    lv_base_code               := LPAD( cv_space, 4, cv_space );                                                     -- ���_�R�[�h
--    lv_supplier_code           := LPAD( NVL( i_bac_fb_line_rec.segment1, cv_space ), 9 );                 -- �d����R�[�h
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                    -- �_�~�[
    lv_base_code               := LPAD( NVL( i_bac_fb_line_rec.base_code, cv_space ), 10 , cv_zero );     -- ���_�R�[�h
    lv_supplier_code           := LPAD( NVL( i_bac_fb_line_rec.segment1, cv_space ), 10 , cv_zero );      -- �d����R�[�h
-- Ver.1.14 Mod Start
--    lv_dummy                   := LPAD( cv_space, 9, cv_space );                                          -- �_�~�[
    lv_dummy                   := LPAD( cv_space, 8, cv_space );                                          -- �_�~�[
-- Ver.1.14 Mod End
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD END
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
--
    ov_fb_line_data            := lv_data_type               ||          -- �f�[�^�敪
                                  lv_bank_number             ||          -- ��d�����Z�@�֔ԍ�
                                  lv_bank_name_alt           ||          -- ��d�����Z�@�֖�
                                  lv_bank_num                ||          -- ��d���x�X�ԍ�
                                  lv_bank_branch_name_alt    ||          -- ��d���x�X��
                                  lv_clearinghouse_no        ||          -- ��`�������ԍ�
                                  lv_bank_account_type       ||          -- �a�����
                                  lv_bank_account_num        ||          -- �����ԍ�
                                  lv_account_holder_name_alt ||          -- ���l��
                                  lv_transfer_amount         ||          -- �U�����z
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD START
                                  cv_zero                    ||          -- �V�K���R�[�h
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD END
                                  lv_base_code               ||          -- ���_�R�[�h
                                  lv_supplier_code           ||          -- �d����R�[�h
-- Ver.1.14 Add Start
                                  cv_settlement_kbn          ||         -- �U���w��敪�i���ϗD��x�j
-- Ver.1.14 Add End
                                  lv_dummy;                              -- �_�~�[
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END storage_bank_acct_chk_fb_line;
--
  /**********************************************************************************
   * Procedure Name   : get_fb_line_add_info
   * Description      : FB�쐬���׃f�[�^�t�����̎擾�i�{�U�pFB�f�[�^�쐬�����j(A-8)
   ***********************************************************************************/
  PROCEDURE get_fb_line_add_info(
     ov_errbuf          OUT VARCHAR2       -- �G���[�E���b�Z�[�W
    ,ov_retcode         OUT VARCHAR2       -- ���^�[���E�R�[�h
    ,ov_errmsg          OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,on_transfer_amount OUT NUMBER         -- �U�����z
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    ,on_fee             OUT NUMBER         -- ��s�萔���i�U���萔���j
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt             IN  NUMBER         -- �����J�E���^
    ,i_fb_line_rec      IN  fb_line_cur%ROWTYPE      -- FB�쐬���׃��R�[�h
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'get_fb_line_add_info';  -- �v���O������
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    -- �O���[�o���萔��
--    cv_i               CONSTANT VARCHAR2(1)   := 'I';                     -- ����
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE START
--    cn_zero            CONSTANT NUMBER        := 0;                       -- ���l�F0
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE END
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;                       -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;                       -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg         VARCHAR2(2000) DEFAULT NULL;                       -- ���b�Z�[�W
    ln_transfer_amount NUMBER;                                            -- �U�����z
    ln_bm_tax          NUMBER;                                            -- ����ŗ�
    ln_fee             NUMBER;                                            -- �萔��
    ln_fee_no_tax      NUMBER;                                            -- �萔��(�Ŕ���)
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode         := cv_status_normal;
    ln_transfer_amount := 0;
    on_transfer_amount := 0;
    ln_bm_tax          := 0;
    ln_fee             := 0;
    ln_fee_no_tax      := 0;
--
    ln_bm_tax := TO_NUMBER( gt_prof_bm_tax );                       -- ����ŗ�
--
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
/*
    -- �{�U�pFB�쐬���׏��.��s�萔�����S�҂������̏ꍇ
    IF( gt_fb_line_tab( in_cnt ).bank_charge_bearer = cv_i ) THEN
      -- �{�U�pFB�쐬���׏��.�U���z���A�u��s�萔��_�U���z��v�����̏ꍇ
      IF( NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero ) < TO_NUMBER( gt_prof_trans_fee_criterion )) THEN
        ln_fee_no_tax := TO_NUMBER( gt_prof_less_fee_criterion );
        ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
      -- �{�U�pFB�쐬���׏��.�U���z���A�u��s�萔��_�U���z��v�ȏ�̏ꍇ
      ELSIF( NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero ) >= gt_prof_trans_fee_criterion ) THEN
        ln_fee_no_tax := TO_NUMBER( gt_prof_more_fee_criterion );
        ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
      END IF;
      -- �U�����z�ɋ�s�萔�������Z����
      ln_transfer_amount := NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero );
      IF( ln_transfer_amount > 0 ) THEN
        on_transfer_amount := ln_transfer_amount + ln_fee;
      END IF;
    ELSE
      ln_transfer_amount := NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero );
      on_transfer_amount := ln_transfer_amount;
    END IF;
*/
    -- �x�����z��ϐ��֊i�[
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    ln_transfer_amount := NVL( gt_fb_line_tab( in_cnt ).trns_amt, cn_zero );
    ln_transfer_amount := NVL( i_fb_line_rec.trns_amt, cn_zero );
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
--
    -- �{�U�pFB�쐬���׏��.�U���z���A�u��s�萔��_�U���z��v�����̏ꍇ
    IF( ln_transfer_amount < TO_NUMBER( gt_prof_trans_fee_criterion )) THEN
      ln_fee_no_tax := TO_NUMBER( gt_prof_less_fee_criterion );
      ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
    -- �{�U�pFB�쐬���׏��.�U���z���A�u��s�萔��_�U���z��v�ȏ�̏ꍇ
    ELSE
      ln_fee_no_tax := TO_NUMBER( gt_prof_more_fee_criterion );
      ln_fee        := ln_fee_no_tax * ( ln_bm_tax / 100 + 1 );
    END IF;
--
-- 2009/12/16 Ver.1.7 [E_�{�ғ�_00512] SCS S.Moriyama UPD START
--    -- �{�U�pFB�쐬���׏��.��s�萔�����S�҂������̏ꍇ�A�U�����z�ɋ�s�萔�������Z����
---- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
----    IF( gt_fb_line_tab( in_cnt ).bank_charge_bearer = cv_i AND ln_transfer_amount > 0 ) THEN
--    IF( i_fb_line_rec.bank_charge_bearer = cv_i AND ln_transfer_amount > 0 ) THEN
---- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
--      on_transfer_amount := ln_transfer_amount + ln_fee;
--    ELSE
--      on_transfer_amount := ln_transfer_amount;
--    END IF;
--
    -- �U���萔�����S�����蕉�S�̏ꍇ�͐U���z���萔�������z����
    IF( i_fb_line_rec.bank_charge_bearer != cv_i AND ln_transfer_amount > 0 ) THEN
      on_transfer_amount := ln_transfer_amount + ( ln_fee * -1 );
    ELSE
      on_transfer_amount := ln_transfer_amount;
    END IF;
-- 2009/12/16 Ver.1.7 [E_�{�ғ�_00512] SCS S.Moriyama UPD END
--
    -- ��s�萔���i�U���萔���j���A�E�g�p�����[�^�Ɋi�[
    on_fee := ln_fee;
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_fb_line_add_info;
--
   /**********************************************************************************
   * Procedure Name   : storage_fb_line
   * Description      : FB�쐬���׃f�[�^�̊i�[�i�{�U�pFB�f�[�^�쐬�����j(A-9)
   ***********************************************************************************/
  PROCEDURE storage_fb_line(
     ov_errbuf                OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode               OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg                OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_fb_line_data          OUT VARCHAR2     -- FB����
    ,in_transfer_amount       IN  NUMBER       -- �U�����z
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt                   IN  NUMBER       -- �����J�E���^
    ,i_fb_line_rec            IN  fb_line_cur%ROWTYPE     -- FB�쐬���׃��R�[�h
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'storage_fb_line';   -- �v���O������
    --
    cv_data_type       CONSTANT VARCHAR2(1)   := '2';                 -- �f�[�^�敪
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE END
--    cn_zero            CONSTANT NUMBER        := 0;                   -- ���l�F0
--    cn_1               CONSTANT NUMBER        := 1;                   -- ���l�F1
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE END
    --=================================
    -- ���[�J���ϐ�
    --=================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;      -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;      -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                  VARCHAR2(2000) DEFAULT NULL;      -- ���b�Z�[�W�o��
    lv_data_type                VARCHAR2(1)    DEFAULT NULL;      -- �f�[�^�敪
    lv_bank_number              VARCHAR2(4)    DEFAULT NULL;      -- ��d�����Z�@�֔ԍ�
    lv_bank_name_alt            VARCHAR2(15)   DEFAULT NULL;      -- ��d�����Z�@�֖�
    lv_bank_num                 VARCHAR2(3)    DEFAULT NULL;      -- ��d���x�X�ԍ�
    lv_bank_branch_name_alt     VARCHAR2(15)   DEFAULT NULL;      -- ��d���x�X��
    lv_clearinghouse_no         VARCHAR2(4)    DEFAULT NULL;      -- ��`�������ԍ�
    lv_bank_account_type        VARCHAR2(1)    DEFAULT NULL;      -- �a�����
    lv_bank_account_num         VARCHAR2(7)    DEFAULT NULL;      -- �����ԍ�
    lv_account_holder_name_alt  VARCHAR2(30)   DEFAULT NULL;      -- ���l��
    lv_transfer_amount          VARCHAR2(10)   DEFAULT NULL;      -- �U�����z
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD START
--    lv_base_code                VARCHAR2(1)    DEFAULT NULL;      -- ���_�R�[�h
--    lv_supplier_code            VARCHAR2(9)    DEFAULT NULL;      -- �d����R�[�h
    lv_base_code                VARCHAR2(10)   DEFAULT NULL;      -- ���_�R�[�h
    lv_supplier_code            VARCHAR2(10)   DEFAULT NULL;      -- �d����R�[�h
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD END
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;      -- �_�~�[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
--
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    lv_data_type               := cv_data_type;                                                                  -- �f�[�^�敪
--    lv_bank_number             := LPAD( NVL( gt_fb_line_tab( in_cnt ).bank_number, cv_zero ), 4, cv_zero );      -- ��d�����Z�@�֔ԍ�
--    lv_bank_name_alt           := RPAD( NVL( gt_fb_line_tab( in_cnt ).bank_name_alt, cv_space ), 15 );           -- ��d�����Z�@�֖�
--    lv_bank_num                := LPAD( NVL( gt_fb_line_tab( in_cnt ).bank_num, cv_zero ), 3, cv_zero );         -- ��d���x�X�ԍ�
--    lv_bank_branch_name_alt    := RPAD( NVL( gt_fb_line_tab( in_cnt ).bank_branch_name_alt, cv_space ), 15 );    -- ��d���x�X��
--    lv_clearinghouse_no        := LPAD( cv_space, 4 );                                                           -- ��`�������ԍ�
--    lv_bank_account_type       := NVL( gt_fb_line_tab( in_cnt ).bank_account_type, cv_zero );                    -- �a�����
--    lv_bank_account_num        := LPAD( NVL( gt_fb_line_tab( in_cnt ).bank_account_num, cv_zero ), 7, cv_zero ); -- �����ԍ�
--    lv_account_holder_name_alt := RPAD( NVL( gt_fb_line_tab( in_cnt ).account_holder_name_alt, cv_space ), 30 ); -- ���l��
--    lv_transfer_amount         := TO_CHAR( NVL( in_transfer_amount, cn_zero ), 'FM0000000000');                  -- �U�����z
--    lv_base_code               := LPAD( NVL( gt_fb_line_tab( in_cnt ).base_code, cv_space ), 4 );                -- ���_�R�[�h
--    lv_supplier_code           := LPAD( NVL( gt_fb_line_tab( in_cnt ).supplier_code, cv_space ), 9 );            -- �d����R�[�h
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                -- �_�~�[
    lv_data_type               := cv_data_type;                                                                  -- �f�[�^�敪
    lv_bank_number             := LPAD( NVL( i_fb_line_rec.bank_number, cv_zero ), 4, cv_zero );      -- ��d�����Z�@�֔ԍ�
    lv_bank_name_alt           := RPAD( NVL( i_fb_line_rec.bank_name_alt, cv_space ), 15 );           -- ��d�����Z�@�֖�
    lv_bank_num                := LPAD( NVL( i_fb_line_rec.bank_num, cv_zero ), 3, cv_zero );         -- ��d���x�X�ԍ�
    lv_bank_branch_name_alt    := RPAD( NVL( i_fb_line_rec.bank_branch_name_alt, cv_space ), 15 );    -- ��d���x�X��
    lv_clearinghouse_no        := LPAD( cv_space, 4 );                                                           -- ��`�������ԍ�
    lv_bank_account_type       := NVL( i_fb_line_rec.bank_account_type, cv_zero );                    -- �a�����
    lv_bank_account_num        := LPAD( NVL( i_fb_line_rec.bank_account_num, cv_zero ), 7, cv_zero ); -- �����ԍ�
    lv_account_holder_name_alt := RPAD( NVL( i_fb_line_rec.account_holder_name_alt, cv_space ), 30 ); -- ���l��
    lv_transfer_amount         := TO_CHAR( NVL( in_transfer_amount, cn_zero ), 'FM0000000000');                  -- �U�����z
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD START
--    lv_base_code               := LPAD( NVL( i_fb_line_rec.base_code, cv_space ), 4 );                -- ���_�R�[�h
--    lv_supplier_code           := LPAD( NVL( i_fb_line_rec.supplier_code, cv_space ), 9 );            -- �d����R�[�h
--    lv_dummy                   := LPAD( cv_space, 17, cv_space );                                                    -- �_�~�[
    lv_base_code               := LPAD( NVL( i_fb_line_rec.base_code, cv_space ), 10 , cv_zero );     -- ���_�R�[�h
    lv_supplier_code           := LPAD( NVL( i_fb_line_rec.supplier_code, cv_space ), 10 , cv_zero ); -- �d����R�[�h
-- Ver.1.14 Mod Start
--    lv_dummy                   := LPAD( cv_space, 9, cv_space );                                      -- �_�~�[
    lv_dummy                   := LPAD( cv_space, 8, cv_space );                                      -- �_�~�[
-- Ver.1.14 Mod End
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD END
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
--
    ov_fb_line_data            := lv_data_type               ||         -- �f�[�^�敪
                                  lv_bank_number             ||         -- ��d�����Z�@�֔ԍ�
                                  lv_bank_name_alt           ||         -- ��d�����Z�@�֖�
                                  lv_bank_num                ||         -- ��d���x�X�ԍ�
                                  lv_bank_branch_name_alt    ||         -- ��d���x�X��
                                  lv_clearinghouse_no        ||         -- ��`�������ԍ�
                                  lv_bank_account_type       ||         -- �a�����
                                  lv_bank_account_num        ||         -- �����ԍ�
                                  lv_account_holder_name_alt ||         -- ���l��
                                  lv_transfer_amount         ||         -- �U�����z
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD START
                                  cv_zero                    ||         -- �V�K���R�[�h
-- 2009/12/17 Ver.1.9 [E_�{�ғ�_00511] SCS S.Moriyama UPD END
                                  lv_base_code               ||         -- ���_�R�[�h
                                  lv_supplier_code           ||         -- �d����R�[�h
-- Ver.1.14 Add Start
                                  cv_settlement_kbn          ||         -- �U���w��敪�i���ϗD��x�j
-- Ver.1.14 Add End
                                  lv_dummy;                             -- �_�~�[
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_line;
--
   /**********************************************************************************
   * Procedure Name   : upd_backmargin_balance
   * Description      : FB�쐬�f�[�^�o�͌��ʂ̍X�V(A-11)
   ***********************************************************************************/
  PROCEDURE upd_backmargin_balance(
     ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    ,in_cnt        IN  NUMBER       -- �����J�E���^
    ,i_fb_line_rec IN  fb_line_cur%ROWTYPE       -- FB�쐬���׃��R�[�h
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_backmargin_balance'; -- �v���O������
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE START
--    cn_zero       CONSTANT NUMBER        := 0;                        -- ���l�F0
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi DELETE END
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;          -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;          -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;          -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;          -- ���b�Z�[�W
    lb_retcode    BOOLEAN;                              -- ���^�[���E�R�[�h
    --=================================
    -- ���[�J���J�[�\��
    --=================================
    -- ���b�N�擾
    CURSOR lock_bm_bal_cur
    IS
    SELECT xbb.bm_balance_id  AS bm_balance_id          -- �̎�c��ID
    FROM   xxcok_backmargin_balance  xbb                -- �̎�c���e�[�u��
    WHERE  xbb.fb_interface_status  = cv_zero
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD START
    AND    xbb.gl_interface_status  = cv_zero
    AND    xbb.amt_fix_status       = cv_1
    AND    xbb.payment_amt_tax      = cn_zero
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD END
    AND    xbb.resv_flag           IS NULL
    AND    xbb.expect_payment_date <= gd_pay_date
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--    AND    xbb.supplier_code        = gt_fb_line_tab( in_cnt ).supplier_code
--    AND    xbb.supplier_site_code   = gt_fb_line_tab( in_cnt ).supplier_site_code
    AND    xbb.supplier_code        = i_fb_line_rec.supplier_code
    AND    xbb.supplier_site_code   = i_fb_line_rec.supplier_site_code
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
    FOR UPDATE NOWAIT;
    --=================================
    -- ���[�J����O
    --=================================
    --*** �X�V������O ***
    update_err_expt           EXCEPTION;
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- ���b�N�擾
    OPEN  lock_bm_bal_cur;
    CLOSE lock_bm_bal_cur;
--
    BEGIN
      --�X�V����
      UPDATE xxcok_backmargin_balance   xbb                                            -- �̎�c���e�[�u��
      SET  xbb.expect_payment_amt_tax = cv_zero                                        -- �x���\��z
          ,xbb.payment_amt_tax        = NVL( xbb.expect_payment_amt_tax, cn_zero )     -- �x���z
          ,xbb.fb_interface_status    = cv_1                                           -- �A�g�X�e�[�^�X�i�{�U�pFB�j
          ,xbb.fb_interface_date      = gd_proc_date                                   -- �A�g���i�{�U�pFB�j
-- 2009/05/29 Ver.1.4 [��QT1_1147] SCS K.Yamaguchi ADD START
          ,xbb.publication_date       = gd_pay_date                                    -- �ē���������
          ,xbb.edi_interface_status   = cv_1                                           -- �A�g�X�e�[�^�X�iEDI�x���ē����j
          ,xbb.edi_interface_date     = gd_proc_date                                   -- �A�g���iEDI�x���ē����j
          ,xbb.request_id             = cn_request_id
          ,xbb.program_application_id = cn_program_application_id
          ,xbb.program_id             = cn_program_id
          ,xbb.program_update_date    = SYSDATE
-- 2009/05/29 Ver.1.4 [��QT1_1147] SCS K.Yamaguchi ADD END
          ,xbb.last_updated_by        = cn_last_updated_by                             -- �ŏI�X�V��
          ,xbb.last_update_date       = SYSDATE                                        -- �ŏI�X�V��
          ,xbb.last_update_login      = cn_last_update_login                           -- �ŏI�X�V���O�C��ID
      WHERE xbb.fb_interface_status   = cv_zero
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD START
      AND   xbb.gl_interface_status   = cv_zero
      AND   xbb.amt_fix_status        = cv_1
      AND   xbb.payment_amt_tax       = cn_zero
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD END
      AND   xbb.resv_flag            IS NULL
      AND   xbb.expect_payment_date  <= gd_pay_date
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--      AND   xbb.supplier_code         = gt_fb_line_tab( in_cnt ).supplier_code
--      AND   xbb.supplier_site_code    = gt_fb_line_tab( in_cnt ).supplier_site_code;
      AND   xbb.supplier_code         = i_fb_line_rec.supplier_code
      AND   xbb.supplier_site_code    = i_fb_line_rec.supplier_site_code;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
--
    EXCEPTION
      -- *** �X�V��O�n���h�� ***
      WHEN OTHERS THEN
        RAISE update_err_expt;
    END;
--
  EXCEPTION
    WHEN global_lock_err_expt THEN
      -- *** ���b�N�擾��O�n���h�� ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR START
--                      ,iv_name         => cv_msg_cok_10243
                      ,iv_name         => cv_msg_cok_00053
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR END
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN update_err_expt THEN
      -- *** �X�V��O�n���h�� ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR START
--                      ,iv_name         => cv_msg_cok_10244
                      ,iv_name         => cv_msg_cok_00054
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR END
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END upd_backmargin_balance;
--
   /**********************************************************************************
   * Procedure Name   : storage_fb_trailer_data
   * Description      : FB�쐬�g���[�����R�[�h�̊i�[(A-12)
   ***********************************************************************************/
  PROCEDURE storage_fb_trailer_data(
     ov_errbuf                OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode               OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg                OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_fb_trailer_data       OUT VARCHAR2     -- FB�쐬�g���[�����R�[�h
    ,iv_proc_type             IN  VARCHAR2     -- �f�[�^�敪
    ,in_total_transfer_amount IN  NUMBER       -- �U�����z�v
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'storage_fb_trailer_data';  -- �v���O������
    cv_data_type  CONSTANT VARCHAR2(1)   := '8';                         -- �f�[�^�敪
    --=================================
    -- ���[�J���ϐ�
    --=================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;         -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;         -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;         -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg   VARCHAR2(2000) DEFAULT NULL;         -- ���b�Z�[�W
    lv_data_type VARCHAR2(1)    DEFAULT NULL;         -- �f�[�^�敪
    lv_total_cnt VARCHAR2(6)    DEFAULT NULL;         -- ���v����
    lv_total_amt VARCHAR2(12)   DEFAULT NULL;         -- ���v���z
    lv_dummy     VARCHAR2(101)  DEFAULT NULL;         -- �_�~�[
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �����敪��1�̏ꍇ
    IF( iv_proc_type = cv_1 ) THEN
      lv_total_amt := LPAD( cv_zero, 12, cv_zero );                              -- �U�����z�v
    -- �����敪��2�̏ꍇ
    ELSIF( iv_proc_type = cv_2 ) THEN
      lv_total_amt := LPAD( TO_CHAR( in_total_transfer_amount ), 12, cv_zero );  -- �U�����z�v
    END IF;
--
    lv_data_type := cv_data_type;                                -- �f�[�^�敪
-- 2009/12/16 Ver.1.8 [E_�{�ғ�_00512] SCS S.Moriyama UPD START
--    lv_total_cnt := LPAD( gn_target_cnt, 6, cv_zero );           -- ���v����
    lv_total_cnt := LPAD( gn_out_cnt, 6, cv_zero );           -- ���v����
-- 2009/12/16 Ver.1.8 [E_�{�ғ�_00512] SCS S.Moriyama UPD END
    lv_dummy     := LPAD( cv_space, 101, cv_space );             -- �_�~�[
--
    ov_fb_trailer_data := lv_data_type ||            -- �f�[�^�敪
                          lv_total_cnt ||            -- ���v����
                          lv_total_amt ||            -- �U�����z�v
                          lv_dummy;                  -- �_�~�[
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_trailer_data;
--
   /**********************************************************************************
   * Procedure Name   : storage_fb_end_data
   * Description      : FB�쐬�G���h���R�[�h�̊i�[(A-14)
   ***********************************************************************************/
  PROCEDURE storage_fb_end_data(
     ov_errbuf      OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode     OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg      OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_fb_end_data OUT VARCHAR2     -- FB�쐬�G���h���R�[�h
  )
  IS
    --================================
    -- ���[�J���萔
    --================================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'storage_fb_end_data';    -- �v���O������
    cv_data_type CONSTANT VARCHAR2(1)   := '9';                      -- �f�[�^�敪
    cv_at_mark   CONSTANT VARCHAR2(1)   := CHR( 64 );                -- �A�b�g�}�[�N
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;        -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;        -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg   VARCHAR2(2000) DEFAULT NULL;        -- ���b�Z�[�W
    lv_data_type VARCHAR2(1)    DEFAULT NULL;        -- �f�[�^�敪
    lv_dummy1    VARCHAR2(117)  DEFAULT NULL;        -- �_�~�[1
    lv_dummy2    VARCHAR2(1)    DEFAULT NULL;        -- �_�~�[2
    lv_dummy3    VARCHAR2(1)    DEFAULT NULL;        -- �_�~�[3
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    lv_data_type := cv_data_type;                    -- �f�[�^�敪
    lv_dummy1    := LPAD( cv_space, 117, cv_space ); -- �_�~�[1
    lv_dummy2    := cv_at_mark;                      -- �_�~�[2
    lv_dummy3    := cv_space;                        -- �_�~�[3
--
    ov_fb_end_data := lv_data_type ||                -- �f�[�^�敪
                      lv_dummy1    ||                -- �_�~�[1
                      lv_dummy2    ||                -- �_�~�[2
                      lv_dummy3;                     -- �_�~�[3
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END storage_fb_end_data;
--
   /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : FB�쐬�w�b�_�[�f�[�^�̏o��  (A-6)
   *                    FB�쐬�f�[�^���R�[�h�̏o��  (A-10)
   *                    FB�쐬�g���[�����R�[�h�̏o��(A-13)
   *                    FB�쐬�G���h���R�[�h�̏o��  (A-15)
   ***********************************************************************************/
  PROCEDURE output_data(
     ov_errbuf  OUT VARCHAR2          -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2          -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_data    IN  VARCHAR2          -- �o�͂���f�[�^
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;         -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;         -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;         -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;         -- ���b�Z�[�W
    lb_retcode    BOOLEAN;                             -- ���^�[���E�R�[�h
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --=======================================================
    -- �f�[�^�o��
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- �o�͋敪
                   ,iv_message  => iv_data             -- ���b�Z�[�W
                   ,in_new_line => 0                   -- ���s
                  );
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END output_data;
--
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR START
--  /**********************************************************************************
--   * Procedure Name   : submain
--   * Description      : ���C�������v���V�[�W��
--   **********************************************************************************/
--  PROCEDURE submain(
--     ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W
--    ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h
--    ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
--    ,iv_proc_type  IN  VARCHAR2     -- �����p�����[�^
--  )
--  IS
--    --===============================
--    -- ���[�J���萔
--    --===============================
--    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';  -- �v���O������
--    --
--    -- ===============================
--    -- ���[�J���ϐ�
--    -- ===============================
--    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E���b�Z�[�W
--    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- ���^�[���E�R�[�h
--    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ���[�U�[�E�G���[�E���b�Z�[�W
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- ���b�Z�[�W
--    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- ���b�Z�[�W�E���^�[���E�R�[�h
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    --
--    ln_cnt                     NUMBER         DEFAULT NULL;                        -- �����J�E���^
--    --
--    lt_bank_number             ap_bank_branches.bank_number%TYPE;                  -- ��s�ԍ�
--    lt_bank_name_alt           ap_bank_branches.bank_name_alt%TYPE;                -- ��s���J�i
--    lt_bank_num                ap_bank_branches.bank_num%TYPE;                     -- ��s�x�X�ԍ�
--    lt_bank_branch_name_alt    ap_bank_branches.bank_branch_name_alt%TYPE;         -- ��s�x�X���J�i
--    lt_bank_account_type       ap_bank_accounts_all.bank_account_type%TYPE;        -- �a�����
--    lt_bank_account_num        ap_bank_accounts_all.bank_account_num%TYPE;         -- ��s�����ԍ�
--    lt_account_holder_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE;  -- �������`�l�J�i
--    --
--    lv_fb_header_data          VARCHAR2(2000) DEFAULT NULL;                        -- FB�쐬�w�b�_�[�f�[�^
--    lv_fb_line_data            VARCHAR2(5000) DEFAULT NULL;                        -- FB�쐬���׃f�[�^
--    lv_fb_trailer_data         VARCHAR2(2000) DEFAULT NULL;                        -- FB�쐬�g���[�����R�[�h
--    lv_fb_end_data             VARCHAR2(2000) DEFAULT NULL;                        -- FB�쐬�G���h���R�[�h
--    ln_transfer_amount         NUMBER;                                             -- �U�����z
--    ln_total_transfer_amount   NUMBER;                                             -- �U�����z�v
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    ln_fee                     NUMBER;                                             -- ��s�萔���i�U���萔���j
--    lv_bank_charge_bearer      VARCHAR2(30)   DEFAULT NULL;                        -- ��s�萔�����S��
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
----
--  BEGIN
--    -- �X�e�[�^�X������
--    ov_retcode := cv_status_normal;
--    -- �O���[�o���ϐ��̏�����
--    gn_target_cnt            := 0;        -- �Ώی���
--    gn_normal_cnt            := 0;        -- ���팏��
--    gn_error_cnt             := 0;        -- �G���[����
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    -- ���g�p�̂��߃R�����g�A�E�g
----    gn_warn_cnt              := 0;        -- �x������
--    gn_skip_cnt              := 0;        -- �X�L�b�v����
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    gn_out_cnt               := 0;        -- ��������
--    -- ���[�J���ϐ��̏�����
--    ln_total_transfer_amount := 0;        -- �U�����z�v
--    --===============================
--    -- A-1.��������
--    --===============================
--    init(
--       ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
--      ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
--      ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
--      ,iv_proc_type => iv_proc_type      -- �����p�����[�^
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- �����敪��'1'(�U���������O�`�F�b�NFB�쐬����)�̏ꍇ
--    IF( iv_proc_type = cv_1 ) THEN
--      --===============================================================
--      -- A-2.FB�쐬���׃f�[�^�̎擾�i�U���������O�`�F�b�N�pFB�쐬�����j
--      --===============================================================
--      get_bank_acct_chk_fb_line(
--         ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W
--        ,ov_retcode => lv_retcode   -- ���^�[���E�R�[�h
--        ,ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- �Ώی���
--      gn_target_cnt := gt_bac_fb_line_tab.COUNT;
--    -- �����敪��'2'(�{�U�pFB�f�[�^�쐬����)�̏ꍇ
--    ELSIF( iv_proc_type = cv_2 ) THEN
--      --===============================================================
--      -- A-3.FB�쐬���׃f�[�^�̎擾�i�{�U�pFB�f�[�^�쐬�����j
--      --===============================================================
--      get_fb_line(
--         ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W
--        ,ov_retcode => lv_retcode   -- ���^�[���E�R�[�h
--        ,ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- �Ώی���
--      gn_target_cnt := gt_fb_line_tab.COUNT;
--    END IF;
--    -- �U���������O�`�F�b�N�pFB�쐬
--    IF( iv_proc_type = cv_1 ) THEN
--      --=================================================
--      -- A-4.FB�쐬�w�b�_�[�f�[�^�̎擾
--      --=================================================
--      get_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- �G���[�E���b�Z�[�W
--        ,ov_retcode                 => lv_retcode                    -- ���^�[���E�R�[�h
--        ,ov_errmsg                  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
--        ,ot_bank_number             => lt_bank_number                -- ��s�ԍ�
--        ,ot_bank_name_alt           => lt_bank_name_alt              -- ��s���J�i
--        ,ot_bank_num                => lt_bank_num                   -- ��s�x�X�ԍ�
--        ,ot_bank_branch_name_alt    => lt_bank_branch_name_alt       -- ��s�x�X���J�i
--        ,ot_bank_account_type       => lt_bank_account_type          -- �a�����
--        ,ot_bank_account_num        => lt_bank_account_num           -- ��s�����ԍ�
--        ,ot_account_holder_name_alt => lt_account_holder_name_alt    -- �������`�l�J�i
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-5.FB�쐬�w�b�_�[�f�[�^�̊i�[
--      --=================================================
--      storage_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- �G���[�E���b�Z�[�W
--        ,ov_retcode                 => lv_retcode                    -- ���^�[���E�R�[�h
--        ,ov_errmsg                  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
--        ,ov_fb_header_data          => lv_fb_header_data             -- FB�쐬�w�b�_�[�f�[�^
--        ,it_bank_number             => lt_bank_number                -- ��s�ԍ�
--        ,it_bank_name_alt           => lt_bank_name_alt              -- ��s���J�i
--        ,it_bank_num                => lt_bank_num                   -- ��s�x�X�ԍ�
--        ,it_bank_branch_name_alt    => lt_bank_branch_name_alt       -- ��s�x�X���J�i
--        ,it_bank_account_type       => lt_bank_account_type          -- �a�����
--        ,it_bank_account_num        => lt_bank_account_num           -- ��s�����ԍ�
--        ,it_account_holder_name_alt => lt_account_holder_name_alt    -- �������`�l�J�i
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-6.FB�쐬�w�b�_�[�f�[�^�̏o��
--      --=================================================
--      output_data(
--         ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
--        ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
--        ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
--        ,iv_data    => lv_fb_header_data   -- �o�͂���f�[�^
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      <<bac_fb_line_loop>>
--      FOR ln_cnt IN 1 .. gt_bac_fb_line_tab.COUNT LOOP
--        --===============================================================
--        -- A-7.FB�쐬���׃f�[�^�̊i�[�i�U���������O�`�F�b�N�pFB�쐬�����j
--        --===============================================================
--        storage_bank_acct_chk_fb_line(
--           ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W
--          ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h
--          ,ov_errmsg       => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
--          ,ov_fb_line_data => lv_fb_line_data      -- FB�쐬���׃��R�[�h
--          ,in_cnt          => ln_cnt               -- �����J�E���^
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        --===============================
--        -- A-10.FB�쐬�f�[�^���R�[�h�̏o��
--        --===============================
--        output_data(
--          ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
--         ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
--         ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
--         ,iv_data    => lv_fb_line_data      -- �o�͂���f�[�^
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- ��������
--        gn_out_cnt := gn_out_cnt + 1;
--      END LOOP bac_fb_line_loop;
--    -- �{�U�pFB�f�[�^�쐬
--    ELSIF( iv_proc_type = cv_2 ) THEN
--      --=================================================
--      -- A-4.FB�쐬�w�b�_�[�f�[�^�̎擾
--      --=================================================
--      get_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- �G���[�E���b�Z�[�W
--        ,ov_retcode                 => lv_retcode                    -- ���^�[���E�R�[�h
--        ,ov_errmsg                  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
--        ,ot_bank_number             => lt_bank_number                -- ��s�ԍ�
--        ,ot_bank_name_alt           => lt_bank_name_alt              -- ��s���J�i
--        ,ot_bank_num                => lt_bank_num                   -- ��s�x�X�ԍ�
--        ,ot_bank_branch_name_alt    => lt_bank_branch_name_alt       -- ��s�x�X���J�i
--        ,ot_bank_account_type       => lt_bank_account_type          -- �a�����
--        ,ot_bank_account_num        => lt_bank_account_num           -- ��s�����ԍ�
--        ,ot_account_holder_name_alt => lt_account_holder_name_alt    -- �������`�l�J�i
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-5.FB�쐬�w�b�_�[�f�[�^�̊i�[
--      --=================================================
--      storage_fb_header(
--         ov_errbuf                  => lv_errbuf                     -- �G���[�E���b�Z�[�W
--        ,ov_retcode                 => lv_retcode                    -- ���^�[���E�R�[�h
--        ,ov_errmsg                  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
--        ,ov_fb_header_data          => lv_fb_header_data             -- FB�쐬�w�b�_�[���R�[�h
--        ,it_bank_number             => lt_bank_number                -- ��s�ԍ�
--        ,it_bank_name_alt           => lt_bank_name_alt              -- ��s���J�i
--        ,it_bank_num                => lt_bank_num                   -- ��s�x�X�ԍ�
--        ,it_bank_branch_name_alt    => lt_bank_branch_name_alt       -- ��s�x�X���J�i
--        ,it_bank_account_type       => lt_bank_account_type          -- �a�����
--        ,it_bank_account_num        => lt_bank_account_num           -- ��s�����ԍ�
--        ,it_account_holder_name_alt => lt_account_holder_name_alt    -- �������`�l�J�i
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --=================================================
--      -- A-6.FB�쐬�w�b�_�[�f�[�^�̏o��
--      --=================================================
--      output_data(
--         ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
--        ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
--        ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
--        ,iv_data    => lv_fb_header_data    -- �o�͂���f�[�^
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      <<fb_loop>>
--      FOR ln_cnt IN 1 .. gt_fb_line_tab.COUNT LOOP
--        --==========================================================
--        -- A-8.FB�쐬���׃f�[�^�t�����̎擾�i�{�U�pFB�f�[�^�쐬�����j
--        --==========================================================
--        get_fb_line_add_info(
--           ov_errbuf          => lv_errbuf               -- �G���[�E���b�Z�[�W
--          ,ov_retcode         => lv_retcode              -- ���^�[���E�R�[�h
--          ,ov_errmsg          => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
--          ,on_transfer_amount => ln_transfer_amount      -- �U�����z
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--          ,on_fee             => ln_fee                  -- ��s�萔���i�U���萔���j
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--          ,in_cnt             => ln_cnt                  -- �����J�E���^
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
---- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--        IF(( gt_fb_line_tab( ln_cnt ).bank_charge_bearer = cv_i   AND
--             gt_fb_line_tab( ln_cnt ).trns_amt <= 0
--           ) OR
--           ( gt_fb_line_tab( ln_cnt ).bank_charge_bearer <> cv_i  AND
--             ( gt_fb_line_tab( ln_cnt ).trns_amt - ln_fee ) <= 0
--           )
--          )
--        THEN
--          -- �X�L�b�v�����̃J�E���g�A�b�v
--          gn_skip_cnt := gn_skip_cnt + 1;
----
--          -- �o�͗p�̋�s�萔�����S�҂�I��
--          IF ( gt_fb_line_tab( ln_cnt ).bank_charge_bearer = cv_i ) THEN
--            lv_bank_charge_bearer := gt_prof_bank_trns_fee_we;
--          ELSE
--            lv_bank_charge_bearer := gt_prof_bank_trns_fee_ctpty;
--          END IF;
----
--          -- FB�f�[�^�̎x�����z0�~�ȉ��x�����b�Z�[�W�o��
--         lv_out_msg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_appli_xxcok
--                         ,iv_name         => cv_msg_cok_10453
--                         ,iv_token_name1  => cv_token_conn_loc
--                         ,iv_token_value1 => gt_fb_line_tab( ln_cnt ).base_code      -- �⍇���S�����_
--                         ,iv_token_name2  => cv_token_vendor_code
--                         ,iv_token_value2 => gt_fb_line_tab( ln_cnt ).supplier_code  -- �x����R�[�h
--                         ,iv_token_name3  => cv_token_payment_amt
--                         ,iv_token_value3 => TO_CHAR( gt_fb_line_tab( ln_cnt ).trns_amt ) -- �U���z
--                         ,iv_token_name4  => cv_token_bank_charge_bearer
--                         ,iv_token_value4 => lv_bank_charge_bearer                   -- ��s�萔��
--                       );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.LOG       -- �o�͋敪
--                        ,iv_message  => lv_out_msg         -- ���b�Z�[�W
--                        ,in_new_line => 0                  -- ���s
--                       );
----
--        ELSE
--          -- �U�����z�v
--          ln_total_transfer_amount := ln_total_transfer_amount + ln_transfer_amount;
--          --=============================================================
--          -- A-9.FB�쐬���׃f�[�^�̊i�[�i�{�U�pFB�f�[�^�쐬�����j
--          --=============================================================
--          storage_fb_line(
--            ov_errbuf                => lv_errbuf                   -- �G���[�E���b�Z�[�W
--           ,ov_retcode               => lv_retcode                  -- ���^�[���E�R�[�h
--           ,ov_errmsg                => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--           ,ov_fb_line_data          => lv_fb_line_data             -- FB����
--           ,in_transfer_amount       => ln_transfer_amount          -- �U�����z
--           ,in_cnt                   => ln_cnt                      -- �����J�E���^
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
--          --
--          --================================
--          -- A-10.FB�쐬�f�[�^���R�[�h�̏o��
--          --================================
--          output_data(
--            ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
--           ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
--           ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�WF
--           ,iv_data    => lv_fb_line_data     -- �o�͂���f�[�^
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
--          --===================================
--          -- A-11.FB�쐬�f�[�^�o�͌��ʂ̍X�V
--          --===================================
--          upd_backmargin_balance(
--             ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W
--            ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h
--            ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
--            ,in_cnt     => ln_cnt             -- �����J�E���^
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
--          -- ��������
--          gn_out_cnt := gn_out_cnt + 1;
--        END IF;
---- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--      END LOOP fb_loop;
--    END IF;
--    --=======================================
--    -- A-12.FB�쐬�g���[�����R�[�h�̊i�[
--    --=======================================
--    storage_fb_trailer_data(
--       ov_errbuf                => lv_errbuf                  -- �G���[�E���b�Z�[�W
--      ,ov_retcode               => lv_retcode                 -- ���^�[���E�R�[�h
--      ,ov_errmsg                => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--      ,ov_fb_trailer_data       => lv_fb_trailer_data         -- FB�쐬�g���[�����R�[�h
--      ,iv_proc_type             => iv_proc_type               -- �f�[�^�敪
--      ,in_total_transfer_amount => ln_total_transfer_amount   -- �U�����z�v
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
--    --=======================================
--    -- A-13.FB�쐬�g���[�����R�[�h�̏o��
--    --=======================================
--    output_data(
--       ov_errbuf  => lv_errbuf               -- �G���[�E���b�Z�[�W
--      ,ov_retcode => lv_retcode              -- ���^�[���E�R�[�h
--      ,ov_errmsg  => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
--      ,iv_data    => lv_fb_trailer_data      -- �o�͂���f�[�^
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
--    --=======================================
--    -- A-14.FB�쐬�G���h���R�[�h�̊i�[
--    --=======================================
--    storage_fb_end_data(
--       ov_errbuf      => lv_errbuf            -- �G���[�E���b�Z�[�W
--      ,ov_retcode     => lv_retcode           -- ���^�[���E�R�[�h
--      ,ov_errmsg      => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
--      ,ov_fb_end_data => lv_fb_end_data       -- FB�쐬�G���h���R�[�h
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
--    --=======================================
--    -- A-15.FB�쐬�G���h���R�[�h�̏o��
--    --=======================================
--    output_data(
--       ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W
--      ,ov_retcode => lv_retcode        -- ���^�[���E�R�[�h
--      ,ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
--      ,iv_data    => lv_fb_end_data    -- �o�͂���f�[�^
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      IF( lv_errbuf IS NOT NULL ) THEN
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      END IF;
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--  END submain;
--
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD START
   /**********************************************************************************
   * Procedure Name   : upd_carried_forward_data
   * Description      : �����J��z���f�[�^�̍X�V(A-17)
   ***********************************************************************************/
  PROCEDURE upd_carried_forward_data(
      ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
    , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
    , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
   , iv_proc_type IN  VARCHAR2  -- �����p�����[�^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100)  := 'upd_carried_forward_data';  -- �v���O������
    --================================
    -- ���[�J���ϐ�
    --================================
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL; -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE; -- ���^�[���E�R�[�h
    --=================================
    -- ���[�J���J�[�\��
    --=================================
    -- ���b�N�擾
    CURSOR xbb_update_lock_cur
    IS
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR START
--      SELECT  /*+ INDEX( xbb xxcok_backmargin_balance_n10 ) */
--              xbb.bm_balance_id AS bm_balance_id  -- �̎�c��ID
--      FROM    xxcok_backmargin_balance  xbb -- �̎�c���e�[�u��
--      WHERE   xbb.fb_interface_status     =  '0'  -- �A�g�X�e�[�^�X�i�{�U�pFB�j     �F���A�g
--        AND   xbb.gl_interface_status     =  '0'  -- �A�g�X�e�[�^�X�iGL�j           �F���A�g
--        AND   xbb.edi_interface_status    =  '1'  -- �A�g�X�e�[�^�X�iEDI�x���ē����j�F�A�g��
--        AND   xbb.expect_payment_amt_tax  <> 0
--        AND   xbb.payment_amt_tax         =  0
--        AND   (     xbb.publication_date  IS NOT NULL
--                 OR xbb.org_slip_number   IS NOT NULL
--              )
      SELECT  /*+
               */
              xbb.bm_balance_id AS bm_balance_id  -- �̎�c��ID
      FROM    xxcok_backmargin_balance  xbb -- �̎�c���e�[�u��
      WHERE   xbb.expect_payment_date     <= gd_pay_date
        AND   xbb.amt_fix_status          =  cv_1     -- ���z�m��X�e�[�^�X             �F�m���
        AND   xbb.fb_interface_status     =  cv_zero  -- �A�g�X�e�[�^�X�i�{�U�pFB�j     �F���A�g
        AND   xbb.gl_interface_status     =  cv_zero  -- �A�g�X�e�[�^�X�iGL�j           �F���A�g
        AND   xbb.edi_interface_status    =  cv_1     -- �A�g�X�e�[�^�X�iEDI�x���ē����j�F�A�g��
        AND   xbb.expect_payment_amt_tax  <> cn_zero
        AND   xbb.payment_amt_tax         =  cn_zero
        AND   (     xbb.publication_date  IS NOT NULL
                 OR xbb.org_slip_number   IS NOT NULL
              )
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi REPAIR END
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
--
    --==================================================
    -- �����敪��'2'(�{�U�pFB�f�[�^�쐬����)�̏ꍇ
    --==================================================
    IF( iv_proc_type = cv_2 ) THEN
      <<update_lock_loop>>
      FOR xbb_update_lock_rec IN xbb_update_lock_cur LOOP
        UPDATE  xxcok_backmargin_balance  xbb -- �̎�c���e�[�u��
        SET xbb.publication_date        = NULL                      -- �ē���������
          , xbb.edi_interface_status    = cv_zero                   -- �A�g�X�e�[�^�X�iEDI�x���ē����j
          , xbb.edi_interface_date      = NULL                      -- �A�g��        �iEDI�x���ē����j
          , xbb.org_slip_number         = NULL                      -- ���`�[�ԍ�
          , xbb.request_id              = cn_request_id             -- �v��ID
          , xbb.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , xbb.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
          , xbb.program_update_date     = SYSDATE                   -- �v���O�����X�V��
          , xbb.last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
          , xbb.last_update_date        = SYSDATE                   -- �ŏI�X�V��
          , xbb.last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
        WHERE xbb.bm_balance_id =  xbb_update_lock_rec.bm_balance_id
        ;
      END LOOP update_lock_loop;
    END IF;
--
  EXCEPTION
    -- *** ���b�N�擾��O�n���h�� ***
    WHEN global_lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                      , iv_name         => cv_msg_cok_00053
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which         => FND_FILE.LOG
                     , iv_message       => lv_out_msg
                     , in_new_line      => 0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                      , iv_name         => cv_msg_cok_00054
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which         => FND_FILE.LOG
                     , iv_message       => lv_out_msg
                     , in_new_line      => 0
                    );
  END upd_carried_forward_data;
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD END
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
--
  /**********************************************************************************
   * Procedure Name   : dmy_acct_chk
   * Description      : �_�~�[�����`�F�b�N
   **********************************************************************************/
  PROCEDURE dmy_acct_chk(
     ov_errbuf            OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode           OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg            OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_base_code         IN  VARCHAR2     -- �⍇���S�����_
    ,iv_supplier_code     IN  VARCHAR2     -- �x����R�[�h
    ,it_bank_number       IN  ap_bank_branches.bank_number%TYPE            -- ��s�ԍ�
    ,it_bank_num          IN  ap_bank_branches.bank_num%TYPE               -- ��s�x�X�ԍ�
    ,it_bank_account_type IN  ap_bank_accounts_all.bank_account_type%TYPE  -- �a�����
    ,it_bank_account_num  IN  ap_bank_accounts_all.bank_account_num%TYPE   -- ��s�����ԍ�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'dmy_acct_chk';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- ���b�Z�[�W
    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- ���b�Z�[�W�E���^�[���E�R�[�h
    --===============================
    -- ���[�J����O
    --===============================
    dmy_acct_expt              EXCEPTION; -- �X�L�b�v����
    --
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    ov_retcode := cv_status_normal;
    --==================================================
    -- �_�~�[�����`�F�b�N
    --==================================================
    << dmy_acct_loop >>
    FOR i IN 1..g_dmy_acct_tab.COUNT LOOP
      IF    ( NVL(it_bank_number, cv_space)       = NVL(g_dmy_acct_tab(i).bank_number, cv_space) )
        AND ( NVL(it_bank_num, cv_space)          = NVL(g_dmy_acct_tab(i).bank_num, cv_space) )
        AND ( NVL(it_bank_account_type, cv_space) = NVL(g_dmy_acct_tab(i).bank_account_type, cv_space) )
        AND ( NVL(it_bank_account_num, cv_space)  = NVL(g_dmy_acct_tab(i).bank_account_num, cv_space) )
      THEN
        RAISE dmy_acct_expt;
      END IF;
    END LOOP dmy_acct_loop;
  EXCEPTION
    WHEN dmy_acct_expt THEN
      -- FB�쐬�ΏۊO�_�~�[�����x�����b�Z�[�W�o��
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                    , iv_name         => cv_msg_cok_10561
                    , iv_token_name1  => cv_token_conn_loc
                    , iv_token_value1 => iv_base_code          -- �⍇���S�����_
                    , iv_token_name2  => cv_token_vendor_code
                    , iv_token_value2 => iv_supplier_code      -- �x����R�[�h
                    , iv_token_name3  => cv_token_bank_number
                    , iv_token_value3 => it_bank_number        -- ��s�ԍ�
                    , iv_token_name4  => cv_token_bank_num
                    , iv_token_value4 => it_bank_num           -- ��s�x�X�ԍ�
                    , iv_token_name5  => cv_token_account_type
                    , iv_token_value5 => it_bank_account_type  -- �a�����
                    , iv_token_name6  => cv_token_account_num
                    , iv_token_value6 => it_bank_account_num   -- ��s�����ԍ�
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      -- �x���X�e�[�^�X�̐ݒ�
      ov_retcode := cv_status_warn;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END dmy_acct_chk;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
-- Ver.1.13 ADD START
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : FB�f�[�^���׃��[�N�e�[�u���o�^(A-10B)
   ***********************************************************************************/
  PROCEDURE insert_data(
     ov_errbuf          OUT NOCOPY VARCHAR2                      -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode         OUT NOCOPY VARCHAR2                      -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg          OUT NOCOPY VARCHAR2                      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    ,it_bank_number     IN  ap_bank_branches.bank_number%TYPE    -- �d�����Z�@�֔ԍ�
    ,in_transfer_amount IN  NUMBER                               -- �U�����z
    ,i_fb_line_rec      IN  fb_line_cur%ROWTYPE                  -- FB�쐬���׃��R�[�h
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_data';     -- �v���O������
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
    cv_header_rec_type   CONSTANT VARCHAR2(1)   := '1';      -- �w�b�_�[���R�[�h�敪
    cv_date_rec_type     CONSTANT VARCHAR2(1)   := '2';      -- �f�[�^���R�[�h�敪
    cv_code_type         CONSTANT VARCHAR2(1)   := '0';      -- �R�[�h�敪
    cv_zero              CONSTANT VARCHAR2(1)   := '0';      -- '0'
    cv_space             CONSTANT VARCHAR2(1)   := ' ';      -- �X�y�[�X1����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- ���[�N�e�[�u���ɓo�^
      INSERT INTO xxcok_fb_lines_work
-- Ver.1.14 Mod Start
        (  company_code                            -- ��ЃR�[�h
          ,internal_bank_number                    -- �d�����Z�@�֔ԍ�
--        (  internal_bank_number                    -- �d�����Z�@�֔ԍ�
-- Ver.1.14 Mod End
          ,header_data_type                        -- �w�b�_�[���R�[�h�敪
          ,type_code                               -- ��ʃR�[�h
          ,code_type                               -- �R�[�h�敪
          ,pay_date                                -- �U���w���
          ,data_type                               -- �f�[�^���R�[�h�敪
          ,bank_number                             -- ��d�����Z�@�֔ԍ�
          ,bank_name_alt                           -- ��d�����Z�@�֖�
          ,bank_num                                -- ��d���x�X�ԍ�
          ,bank_branch_name_alt                    -- ��d���x�X��
          ,clearinghouse_no                        -- ��`�������ԍ�
          ,bank_account_type                       -- �a�����
          ,bank_account_num                        -- �����ԍ�
          ,account_holder_name_alt                 -- ���l��
          ,transfer_amount                         -- �U�����z
          ,record_type                             -- �V�K���R�[�h
          ,base_code                               -- ���_�R�[�h
          ,supplier_code                           -- �d����R�[�h
-- Ver.1.14 Add Start
          ,settlement_priority                     -- �U���w��敪�i���ϗD��x�j
-- Ver.1.14 Add End
          ,implemented_flag                        -- FB�U�����s�ϋ敪
          ,created_by                              -- �쐬��
          ,creation_date                           -- �쐬��
          ,last_updated_by                         -- �ŏI�X�V��
          ,last_update_date                        -- �ŏI�X�V��
          ,last_update_login                       -- �ŏI�X�V���O�C��
          ,request_id                              -- �v��ID
          ,program_application_id                  -- �A�v���P�[�V����ID
          ,program_id                              -- �v���O����ID
          ,program_update_date                     -- �v���O�����X�V��
        )
      VALUES
-- Ver.1.14 Mod Start
        (  gv_company_code                                                         -- �p�����[�^.��ЃR�[�h
          ,SUBSTRB(it_bank_number, 1,4)                                            -- �d�����Z�@�֔ԍ�
--        (  SUBSTRB(it_bank_number, 1,4)                                            -- �d�����Z�@�֔ԍ�
-- Ver.1.14 Mod End
          ,cv_header_rec_type                                                      -- �w�b�_�[���R�[�h�敪
          ,LPAD( gt_values_type_code, 2, cv_zero )                                 -- ��ʃR�[�h
          ,cv_code_type                                                            -- �R�[�h�敪
          ,TO_CHAR( gd_pay_date, 'MMDD' )                                          -- �U���w���
          ,cv_date_rec_type                                                        -- �f�[�^���R�[�h�敪
          ,LPAD( NVL( i_fb_line_rec.bank_number, cv_zero ), 4, cv_zero )           -- ��d�����Z�@�֔ԍ�
          ,RPAD( NVL( i_fb_line_rec.bank_name_alt, cv_space ), 15 )                -- ��d�����Z�@�֖�
          ,LPAD( NVL( i_fb_line_rec.bank_num, cv_zero ), 3, cv_zero )              -- ��d���x�X�ԍ�
          ,RPAD( NVL( i_fb_line_rec.bank_branch_name_alt, cv_space ), 15 )         -- ��d���x�X��
          ,LPAD( cv_space, 4 )                                                     -- ��`�������ԍ�
          ,SUBSTRB(NVL( i_fb_line_rec.bank_account_type, cv_zero ), 1, 1)          -- �a�����
          ,LPAD( NVL( i_fb_line_rec.bank_account_num, cv_zero ), 7, cv_zero )      -- �����ԍ�
          ,RPAD( NVL( i_fb_line_rec.account_holder_name_alt, cv_space ), 30 )      -- ���l��
          ,in_transfer_amount                                                      -- �U�����z
          ,cv_zero                                                                 -- �V�K���R�[�h
          ,LPAD( NVL( i_fb_line_rec.base_code, cv_space ), 10 , cv_zero )          -- ���_�R�[�h
          ,LPAD( NVL( i_fb_line_rec.supplier_code, cv_space ), 10 , cv_zero )      -- �d����R�[�h
-- Ver.1.14 Add Start
          ,cv_settlement_kbn                                                       -- �U���w��敪�i���ϗD��x�j
-- Ver.1.14 Add End
          ,NULL                                                                    -- FB�U�����s�ϋ敪
          ,cn_created_by                                                           -- �쐬��
          ,cd_creation_date                                                        -- �쐬��
          ,cn_last_updated_by                                                      -- �ŏI�X�V��
          ,cd_last_update_date                                                     -- �ŏI�X�V��
          ,cn_last_update_login                                                    -- �ŏI�X�V���O�C��
          ,cn_request_id                                                           -- �v��ID
          ,cn_program_application_id                                               -- �A�v���P�[�V����ID
          ,cn_program_id                                                           -- �v���O����ID
          ,cd_program_update_date                                                  -- �v���O�����X�V��
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10861                     --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tbl_nm                            --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
    WHEN global_process_expt THEN
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_data;
-- Ver.1.13 ADD END
--
-- Ver.1.13 ADD START
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-18)
   ***********************************************************************************/
  PROCEDURE delete_data(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver.1.14 Add Start
  ,iv_company_code   IN  VARCHAR2  -- �p�����[�^�F��ЃR�[�h
-- Ver.1.14 Add End
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_data';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
-- Ver.1.14 Mod Start
--      WHERE  xflw.request_id < cn_request_id
      WHERE  xflw.request_id <> cn_request_id
      AND    xflw.company_code = iv_company_code  -- �p�����[�^�F��ЃR�[�h
-- Ver.1.14 Mod End
      FOR UPDATE OF xflw.request_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- FB�f�[�^���׃��[�N�e�[�u�����b�N�擾
    -- ===============================================
    OPEN  fb_lines_cur;
    CLOSE fb_lines_cur;
    -- ===============================================
    -- FB�f�[�^���׃��[�N�e�[�u���f�[�^�폜
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id <> cn_request_id
-- Ver.1.14 Add Start
      AND    xflw.company_code = iv_company_code  -- �p�����[�^�F��ЃR�[�h
-- Ver.1.14 Add End
      ;
--
    EXCEPTION
      -- *** �폜�����G���[ ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_cok_10862                     --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tbl_nm                            --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
  --*** ���b�N�G���[ ***
  WHEN global_lock_err_expt THEN
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => CHR(10)
    );
    lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appli_xxcok                       --�A�v���P�[�V�����Z�k��
               ,iv_name         => cv_msg_cok_10863                     --���b�Z�[�W�R�[�h
               ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
               ,iv_token_value1 => cv_tbl_nm                            --�g�[�N���l1
               ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
               ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
              );
      lv_errbuf := lv_errmsg;
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END delete_data;
-- Ver.1.13 ADD END
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver.1.14 Add Start
    ,iv_company_code IN  VARCHAR2   -- �p�����[�^�F��ЃR�[�h
-- Ver.1.14 Add End
    ,iv_proc_type  IN  VARCHAR2     -- �����p�����[�^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';  -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- ���b�Z�[�W
    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- ���b�Z�[�W�E���^�[���E�R�[�h
    --
    ln_cnt                     NUMBER         DEFAULT NULL;                        -- �����J�E���^
    --
    lt_bank_number             ap_bank_branches.bank_number%TYPE;                  -- ��s�ԍ�
    lt_bank_name_alt           ap_bank_branches.bank_name_alt%TYPE;                -- ��s���J�i
    lt_bank_num                ap_bank_branches.bank_num%TYPE;                     -- ��s�x�X�ԍ�
    lt_bank_branch_name_alt    ap_bank_branches.bank_branch_name_alt%TYPE;         -- ��s�x�X���J�i
    lt_bank_account_type       ap_bank_accounts_all.bank_account_type%TYPE;        -- �a�����
    lt_bank_account_num        ap_bank_accounts_all.bank_account_num%TYPE;         -- ��s�����ԍ�
    lt_account_holder_name_alt ap_bank_accounts_all.account_holder_name_alt%TYPE;  -- �������`�l�J�i
    --
    lv_fb_header_data          VARCHAR2(2000) DEFAULT NULL;                        -- FB�쐬�w�b�_�[�f�[�^
    lv_fb_line_data            VARCHAR2(5000) DEFAULT NULL;                        -- FB�쐬���׃f�[�^
    lv_fb_trailer_data         VARCHAR2(2000) DEFAULT NULL;                        -- FB�쐬�g���[�����R�[�h
    lv_fb_end_data             VARCHAR2(2000) DEFAULT NULL;                        -- FB�쐬�G���h���R�[�h
    ln_transfer_amount         NUMBER;                                             -- �U�����z
    ln_total_transfer_amount   NUMBER         DEFAULT 0;                           -- �U�����z�v
    ln_fee                     NUMBER;                                             -- ��s�萔���i�U���萔���j
    lv_bank_charge_bearer      VARCHAR2(30)   DEFAULT NULL;                        -- ��s�萔�����S��
    --
    --===============================
    -- ���[�J����O
    --===============================
    skip_expt                      EXCEPTION; -- �X�L�b�v����
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
    dmy_acct_skip_expt             EXCEPTION; -- �_�~�[�����X�L�b�v����
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    ov_retcode := cv_status_normal;
    --==================================================
    -- �O���[�o���ϐ��̏�����
    --==================================================
    gn_target_cnt            := 0;        -- �Ώی���
    gn_normal_cnt            := 0;        -- ���팏��
    gn_error_cnt             := 0;        -- �G���[����
    gn_skip_cnt              := 0;        -- �X�L�b�v����
    gn_out_cnt               := 0;        -- ��������
    --==================================================
    -- A-1.��������
    --==================================================
    init(
      ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
    , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
    , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver.1.14 Add Start
    , iv_company_code => iv_company_code  -- �p�����[�^�F��ЃR�[�h
-- Ver.1.14 Add End
    , iv_proc_type => iv_proc_type      -- �����p�����[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-4.FB�쐬�w�b�_�[�f�[�^�̎擾
    --==================================================
    get_fb_header(
      ov_errbuf                  => lv_errbuf                     -- �G���[�E���b�Z�[�W
    , ov_retcode                 => lv_retcode                    -- ���^�[���E�R�[�h
    , ov_errmsg                  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
    , ot_bank_number             => lt_bank_number                -- ��s�ԍ�
    , ot_bank_name_alt           => lt_bank_name_alt              -- ��s���J�i
    , ot_bank_num                => lt_bank_num                   -- ��s�x�X�ԍ�
    , ot_bank_branch_name_alt    => lt_bank_branch_name_alt       -- ��s�x�X���J�i
    , ot_bank_account_type       => lt_bank_account_type          -- �a�����
    , ot_bank_account_num        => lt_bank_account_num           -- ��s�����ԍ�
    , ot_account_holder_name_alt => lt_account_holder_name_alt    -- �������`�l�J�i
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-5.FB�쐬�w�b�_�[�f�[�^�̊i�[
    --==================================================
    storage_fb_header(
      ov_errbuf                  => lv_errbuf                     -- �G���[�E���b�Z�[�W
    , ov_retcode                 => lv_retcode                    -- ���^�[���E�R�[�h
    , ov_errmsg                  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
    , ov_fb_header_data          => lv_fb_header_data             -- FB�쐬�w�b�_�[�f�[�^
    , it_bank_number             => lt_bank_number                -- ��s�ԍ�
    , it_bank_name_alt           => lt_bank_name_alt              -- ��s���J�i
    , it_bank_num                => lt_bank_num                   -- ��s�x�X�ԍ�
    , it_bank_branch_name_alt    => lt_bank_branch_name_alt       -- ��s�x�X���J�i
    , it_bank_account_type       => lt_bank_account_type          -- �a�����
    , it_bank_account_num        => lt_bank_account_num           -- ��s�����ԍ�
    , it_account_holder_name_alt => lt_account_holder_name_alt    -- �������`�l�J�i
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-6.FB�쐬�w�b�_�[�f�[�^�̏o��
    --==================================================
    output_data(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_data    => lv_fb_header_data   -- �o�͂���f�[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �����敪��'1'(�U���������O�`�F�b�NFB�쐬����)�̏ꍇ
    --==================================================
    IF( iv_proc_type = cv_1 ) THEN
      << bac_fb_line_loop >>
      FOR bac_fb_line_rec IN bac_fb_line_cur LOOP
        gn_target_cnt := gn_target_cnt + 1;
        --==================================================
        -- ���׍쐬
        --==================================================
        BEGIN
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
          --==================================================
          -- FB�쐬�ΏۊO�_�~�[��������
          --==================================================
          dmy_acct_chk(
            ov_errbuf            => lv_errbuf                      -- �G���[�E���b�Z�[�W
          , ov_retcode           => lv_retcode                     -- ���^�[���E�R�[�h
          , ov_errmsg            => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
          , iv_base_code         => bac_fb_line_rec.base_code      -- ���_�R�[�h
          , iv_supplier_code     => bac_fb_line_rec.segment1       -- �d����R�[�h
          , it_bank_number       => bac_fb_line_rec.bank_number        -- ��s�ԍ�
          , it_bank_num          => bac_fb_line_rec.bank_num           -- ��s�x�X�ԍ�
          , it_bank_account_type => bac_fb_line_rec.bank_account_type  -- �a�����
          , it_bank_account_num  => bac_fb_line_rec.bank_account_num   -- ��s�����ԍ�
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE dmy_acct_skip_expt;
          END IF;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
          --==================================================
          -- A-7.FB�쐬���׃f�[�^�̊i�[�i�U���������O�`�F�b�N�pFB�쐬�����j
          --==================================================
          storage_bank_acct_chk_fb_line(
            ov_errbuf         => lv_errbuf            -- �G���[�E���b�Z�[�W
          , ov_retcode        => lv_retcode           -- ���^�[���E�R�[�h
          , ov_errmsg         => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
          , ov_fb_line_data   => lv_fb_line_data      -- FB�쐬���׃��R�[�h
          , i_bac_fb_line_rec => bac_fb_line_rec      -- FB�쐬���׃��R�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- A-10.FB�쐬�f�[�^���R�[�h�̏o��
          --==================================================
          output_data(
            ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
          , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
          , ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
          , iv_data    => lv_fb_line_data      -- �o�͂���f�[�^
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          -- ��������
          gn_out_cnt := gn_out_cnt + 1;
        EXCEPTION
          WHEN skip_expt THEN
            gn_skip_cnt := gn_skip_cnt + 1;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
          WHEN dmy_acct_skip_expt THEN
            gn_skip_cnt := gn_skip_cnt + 1;
            ov_retcode  := cv_status_warn;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
        END;
      END LOOP bac_fb_line_loop;
    --==================================================
    -- �����敪��'2'(�{�U�pFB�f�[�^�쐬����)�̏ꍇ
    --==================================================
    ELSIF( iv_proc_type = cv_2 ) THEN
      << fb_loop >>
      FOR fb_line_rec IN fb_line_cur LOOP
        gn_target_cnt := gn_target_cnt + 1;
        --==================================================
        -- ���׍쐬
        --==================================================
        BEGIN
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
          --==================================================
          -- FB�쐬�ΏۊO�_�~�[��������
          --==================================================
          dmy_acct_chk(
            ov_errbuf            => lv_errbuf                      -- �G���[�E���b�Z�[�W
          , ov_retcode           => lv_retcode                     -- ���^�[���E�R�[�h
          , ov_errmsg            => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
          , iv_base_code         => fb_line_rec.base_code          -- ���_�R�[�h
          , iv_supplier_code     => fb_line_rec.supplier_code      -- �d����R�[�h
          , it_bank_number       => fb_line_rec.bank_number        -- ��s�ԍ�
          , it_bank_num          => fb_line_rec.bank_num           -- ��s�x�X�ԍ�
          , it_bank_account_type => fb_line_rec.bank_account_type  -- �a�����
          , it_bank_account_num  => fb_line_rec.bank_account_num   -- ��s�����ԍ�
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE dmy_acct_skip_expt;
          END IF;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
          --==================================================
          -- A-8.FB�쐬���׃f�[�^�t�����̎擾�i�{�U�pFB�f�[�^�쐬�����j
          --==================================================
          get_fb_line_add_info(
            ov_errbuf          => lv_errbuf               -- �G���[�E���b�Z�[�W
          , ov_retcode         => lv_retcode              -- ���^�[���E�R�[�h
          , ov_errmsg          => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
          , on_transfer_amount => ln_transfer_amount      -- �U�����z
          , on_fee             => ln_fee                  -- ��s�萔���i�U���萔���j
          , i_fb_line_rec      => fb_line_rec             -- FB�쐬���׃��R�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- 0�~�ȉ��x������
          --==================================================
          IF(    (     ( fb_line_rec.bank_charge_bearer  = cv_i )
                   AND ( fb_line_rec.trns_amt           <= 0    )
                 )
              OR (     ( fb_line_rec.bank_charge_bearer <> cv_i )
                   AND ( fb_line_rec.trns_amt - ln_fee  <= 0    )
                 )
          ) THEN
            RAISE skip_expt;
          END IF;
          -- �U�����z�v
          ln_total_transfer_amount := ln_total_transfer_amount + ln_transfer_amount;
          --==================================================
          -- A-9.FB�쐬���׃f�[�^�̊i�[�i�{�U�pFB�f�[�^�쐬�����j
          --==================================================
          storage_fb_line(
            ov_errbuf                => lv_errbuf                   -- �G���[�E���b�Z�[�W
          , ov_retcode               => lv_retcode                  -- ���^�[���E�R�[�h
          , ov_errmsg                => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
          , ov_fb_line_data          => lv_fb_line_data             -- FB����
          , in_transfer_amount       => ln_transfer_amount          -- �U�����z
          , i_fb_line_rec            => fb_line_rec                 -- FB�쐬���׃��R�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
          --==================================================
          -- A-10.FB�쐬�f�[�^���R�[�h�̏o��
          --==================================================
          output_data(
            ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
          , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
          , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�WF
          , iv_data    => lv_fb_line_data     -- �o�͂���f�[�^
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
-- Ver.1.13 ADD START
          -- ========================================
          -- A-10B.FB�f�[�^���׃��[�N�e�[�u���o�^
          -- ========================================
          insert_data(
             ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W
           , ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h
           , ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
           , it_bank_number         => lt_bank_number         -- �d�����Z�@�֔ԍ�
           , in_transfer_amount     => ln_transfer_amount     -- �U�����z
           , i_fb_line_rec          => fb_line_rec            -- FB�쐬���׃��R�[�h
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
-- Ver.1.13 ADD END
          --==================================================
          -- A-11.FB�쐬�f�[�^�o�͌��ʂ̍X�V
          --==================================================
          upd_backmargin_balance(
            ov_errbuf      => lv_errbuf          -- �G���[�E���b�Z�[�W
          , ov_retcode     => lv_retcode         -- ���^�[���E�R�[�h
          , ov_errmsg      => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_fb_line_rec  => fb_line_rec        -- FB�쐬���׃��R�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          -- ��������
          gn_out_cnt := gn_out_cnt + 1;
        EXCEPTION
          WHEN skip_expt THEN
            -- �o�͗p�̋�s�萔�����S�҂�I��
            IF ( fb_line_rec.bank_charge_bearer = cv_i ) THEN
              lv_bank_charge_bearer := gt_prof_bank_trns_fee_we;
            ELSE
              lv_bank_charge_bearer := gt_prof_bank_trns_fee_ctpty;
            END IF;
            -- FB�f�[�^�̎x�����z0�~�ȉ��x�����b�Z�[�W�o��
            lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_xxcok
                          , iv_name         => cv_msg_cok_10453
                          , iv_token_name1  => cv_token_conn_loc
                          , iv_token_value1 => fb_line_rec.base_code      -- �⍇���S�����_
                          , iv_token_name2  => cv_token_vendor_code
                          , iv_token_value2 => fb_line_rec.supplier_code  -- �x����R�[�h
                          , iv_token_name3  => cv_token_payment_amt
                          , iv_token_value3 => TO_CHAR( fb_line_rec.trns_amt ) -- �U���z
                          , iv_token_name4  => cv_token_bank_charge_bearer
                          , iv_token_value4 => lv_bank_charge_bearer                   -- ��s�萔��
                          );
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which    => FND_FILE.LOG       -- �o�͋敪
                           ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                           ,in_new_line => 0                  -- ���s
                          );
            -- �X�L�b�v�����̃J�E���g�A�b�v
            gn_skip_cnt := gn_skip_cnt + 1;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD START
          WHEN dmy_acct_skip_expt THEN
            gn_skip_cnt := gn_skip_cnt + 1;
            ov_retcode  := cv_status_warn;
-- Ver.1.11 [��QE_�{�ғ�_15203] SCSK K.Nara ADD END
        END;
      END LOOP fb_loop;
    END IF;
    --======================================================
    -- FB�쐬���׏��擾�G���[
    --======================================================
    IF( gn_target_cnt = 0 ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_appli_xxcok
                      ,iv_name        => cv_msg_cok_10254
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 1                  -- ���s
                    );
-- Ver.1.14 Add Start
      ov_retcode  := cv_status_warn;
-- Ver.1.14 Add End
    END IF;
    --==================================================
    -- A-12.FB�쐬�g���[�����R�[�h�̊i�[
    --==================================================
    storage_fb_trailer_data(
      ov_errbuf                => lv_errbuf                  -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode                 -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    , ov_fb_trailer_data       => lv_fb_trailer_data         -- FB�쐬�g���[�����R�[�h
    , iv_proc_type             => iv_proc_type               -- �f�[�^�敪
    , in_total_transfer_amount => ln_total_transfer_amount   -- �U�����z�v
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-13.FB�쐬�g���[�����R�[�h�̏o��
    --==================================================
    output_data(
      ov_errbuf  => lv_errbuf               -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode              -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_data    => lv_fb_trailer_data      -- �o�͂���f�[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-14.FB�쐬�G���h���R�[�h�̊i�[
    --==================================================
    storage_fb_end_data(
      ov_errbuf      => lv_errbuf            -- �G���[�E���b�Z�[�W
    , ov_retcode     => lv_retcode           -- ���^�[���E�R�[�h
    , ov_errmsg      => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    , ov_fb_end_data => lv_fb_end_data       -- FB�쐬�G���h���R�[�h
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-15.FB�쐬�G���h���R�[�h�̏o��
    --==================================================
    output_data(
      ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_data    => lv_fb_end_data    -- �o�͂���f�[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD START
    --==================================================
    -- A-17.�����J��z���f�[�^�̍X�V
    --==================================================
    upd_carried_forward_data(
        ov_errbuf     => lv_errbuf    -- �G���[�E���b�Z�[�W
      , ov_retcode    => lv_retcode   -- ���^�[���E�R�[�h
      , ov_errmsg     => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_proc_type  => iv_proc_type -- �����p�����[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2010/09/30 Ver.1.10 [E_�{�ғ�_01144] SCS S.Arizumi ADD END
-- Ver.1.14 Add/Mod Start
    --==================================================
    -- �����敪��'2'(�{�U�pFB�f�[�^�쐬����)�̏ꍇ
    --==================================================
    IF( iv_proc_type = cv_2 ) THEN
-- Ver.1.13 ADD START
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�폜(A-18)
      -- ===============================================
      delete_data(
        ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
      , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
      , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_company_code => iv_company_code  -- �p�����[�^�F��ЃR�[�h
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- Ver.1.13 ADD END
    END IF;
-- Ver.1.14 Add/Mod End
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF( lv_errbuf IS NOT NULL ) THEN
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      END IF;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END submain;
-- 2009/07/02 Ver.1.5 [��Q0000291] SCS K.Yamaguchi REPAIR END
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
     errbuf        OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,retcode       OUT VARCHAR2      -- ���^�[���E�R�[�h
-- Ver.1.14 Add Start
    ,iv_company_code IN  VARCHAR2    -- �p�����[�^�F��ЃR�[�h
-- Ver.1.14 Add End
    ,iv_proc_type  IN  VARCHAR2      -- �����p�����[�^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';   -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_out_msg    VARCHAR2(2000) DEFAULT NULL;
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;        -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;        -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode    BOOLEAN;                            -- ���b�Z�[�W
--
  BEGIN
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver.1.14 Add Start
      ,iv_company_code => iv_company_code        -- ��ЃR�[�h�p�����[�^
-- Ver.1.14 Add End
      ,iv_proc_type => iv_proc_type   -- �����p�����[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- ��������
      gn_out_cnt := 0;
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
      gn_skip_cnt := 0;
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
      -- �G���[����
      gn_error_cnt := 1;
    END IF;
    IF( lv_retcode = cv_status_error ) THEN
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- �o�͋敪
                   ,iv_message  => lv_errmsg          -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- �o�͋敪
                   ,iv_message  => lv_errbuf          -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
    END IF;
    --================================================
    -- A-16.�I������
    --================================================
    -- ��s
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
--    IF( lv_retcode = cv_status_error ) THEN
    IF( lv_retcode = cv_status_error OR gn_skip_cnt > 0 ) THEN
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,NULL
                     ,1
                    );
    END IF;
    -- �Ώی���
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90000
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
    --��������
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90001
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_out_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
-- Start 2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    --�X�L�b�v����
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90003
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
-- End   2009/05/12 Ver_1.3 T1_0832 M.Hiruta
    --�G���[����
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG       -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 1                  -- ���s
                  );
    --�I�����b�Z�[�W
    IF( lv_retcode = cv_status_normal ) THEN
      --���b�Z�[�W�o��
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxccp
                     ,iv_name         => cv_msg_ccp_90004
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
    END IF;
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
      --�G���[�I��
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appli_xxccp
                     ,iv_name        => cv_msg_ccp_90006
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
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
END XXCOK016A02C;
/
