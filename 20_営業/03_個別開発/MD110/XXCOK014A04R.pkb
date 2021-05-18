CREATE OR REPLACE PACKAGE BODY XXCOK014A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A04R(body)
 * Description      : �u�x����v�u����v�㋒�_�v�u�ڋq�v�P�ʂɔ̎�c�������o��
 * MD.050           : ���̋@�̎�c���ꗗ MD050_COK_014_A04
 * Version          : 1.24
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_worktable_data     ���[�N�e�[�u���f�[�^�폜(A-9)
 *  start_svf              SVF�N��(A-8)
 *  upd_resv_payment_rec   �x���X�e�[�^�X�u�����ρv�X�V����(A-11)
 *  upd_resv_payment       �x���X�e�[�^�X�u�����J�z�v�X�V����(A-10)
 *  ins_worktable_data     ���[�N�e�[�u���f�[�^�o�^(A-7)
 *  upd_worktable_data     ���[�N�e�[�u���f�[�^�X�V����(A-12)
 *  break_judge            �u���C�N���菈��(A-6)
 *  get_bm_contract_err    �̎�G���[��񒊏o����(A-5)
 *  get_vendor_data        �d����E��s��񒊏o����(A-4)
 *  get_cust_data          ���㋒�_�E�ڋq��񒊏o����(A-3)
 *  get_target_data        �̎�c����񒊏o����(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   SCS T.Taniguchi  �V�K�쐬
 *  2009/02/18    1.1   SCS T.Taniguchi  [��QCOK_046]
 *                                       1.�d����擾�����C��
 *                                       2.���̓p�����[�^�x�����̃t�H�[�}�b�g�`�F�b�N�C��
 *  2009/02/25    1.2   SCS T.Taniguchi  [��QCOK_054] ���̓p�����[�^�̕\���Ώۖ���l�Z�b�g���擾
 *  2009/03/02    1.3   SCS M.Hiruta     [��QCOK_068]
 *                                       1.�����_�܂ނ̃f�[�^���o�����C��
 *                                       2.����BM�y�ѓd�C���𓖌����̂ݏW�v
 *  2009/04/17    1.4   SCS T.Taniguchi  [��QT1_0647] �����C��
 *  2009/04/23    1.5   SCS T.Taniguchi  [��QT1_0684] �⍇�����_�C��
 *  2009/05/19    1.6   SCS T.Taniguchi  [��QT1_1070] �O���[�o���J�[�\���̃\�[�g���ǉ�
 *  2009/07/15    1.7   SCS T.Taniguchi  [��Q0000689] ��s�萔�����S�ҁA�S�x���ۗ̕��t���O�̎擾��ύX
 *  2009/09/17    1.8   SCS S.Moriyama   [��Q0001390] �p�����[�^����ύX�ɔ�����������Ɩ��Ǘ����`�F�b�N���폜
 *  2009/10/02    1.9   SCS S.Moriyama   [��QE_T3_00630] VDBM�c���ꗗ�\���o�͂���Ȃ�
 *                                                        ��s�R�[�h�A�x�X�R�[�h�ُ̈팅���Ή�
 *  2009/12/15    1.10  SCS K.Nakamura   [��QE_�{�ғ�_00461] �\�[�g���Ή��ɂ��BM�x���敪(�R�[�h�l)�̒ǉ�
 *                                                            1�ڋq�ɑO���E������2���R�[�h���݂���ꍇ�A���߁E�x�������ɍŐV�̓��t��ݒ�
 *  2010/01/27    1.11  SCS K.Kiriu      [��QE_�{�ғ�_01176] ������ʒǉ��ɔ���������ʖ��擾���N�C�b�N�R�[�h�ύX
 *  2011/01/24    1.12  SCS S.Niki       [��QE_�{�ғ�_06199] �p�t�H�[�}���X���P�Ή�
 *  2011/03/15    1.13  SCS S.Niki       [��QE_�{�ғ�_05408,05409] �N���֑ؑΉ�
 *  2011/04/28    1.14  SCS S.Niki       [��QE_�{�ғ�_02100] �����x���̏ꍇ�A��s���ɌŒ蕶�����o�͂���Ή�
 *  2012/07/23    1.15  SCSK K.Onotsuka  [��QE_�{�ғ�_08365,08367] VDBM�c���ꗗ�̎x���X�e�[�^�X�Ɂu�����ρv�u�����J�z�v
 *                                                              �c���������u�O���܂Ŗ����v���z���o��
 *  2013/01/29    1.16  SCSK K.Taniguchi [��QE_�{�ғ�_10381] �x���X�e�[�^�X�u�����J�z�v�o�͏����ύX
 *  2013/04/04    1.17  SCSK K.Nakamura  [��QE_�{�ғ�_10595,10609] �x���X�e�[�^�X�u�ۗ��v�u�����ρv�o�͏����ύX
 *  2013/05/21    1.18  SCSK S.Niki      [��QE_�{�ғ�_10595��]�u�����ρv�o�͏����ύX
 *                                       [��QE_�{�ғ�_10411]   �p�����[�^�u�x����R�[�h�v�u�x���X�e�[�^�X�v�ǉ�
 *                                                              �ϓ��d�C�㖢���̓}�[�N�o�́A�\�[�g���ύX
 *  2013/05/24    1.19  SCSK S.Niki      [��QE_�{�ғ�_10411��] �x���X�e�[�^�X�\�[�g���ύX
 *  2013/05/28    1.20  SCSK S.Niki      [��QE_�{�ғ�_10411��] �G���[�t���O�X�V�����ύX
 *  2013/06/11    1.21  SCSK S.Niki      [��QE_�{�ғ�_10819]   �G���[�L��f�[�^�̃\�[�g���ύX
 *  2014/09/17    1.22  SCSK S.Niki      [��QE_�{�ғ�_12185]   �p�t�H�[�}���X���P�Ή�
 *  2020/12/21    1.23  SCSK N.Abe       [��QE_�{�ғ�_16860]   �x���X�e�[�^�X�u�����J�z�v�̕\�������Ή�
 *  2021/04/21    1.24  SCSK H.Futamura  [��QE_�{�ғ�_16946]   �c���ꗗ�֐ŋ敪�ǉ�
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCOK014A04R';
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W�R�[�h
  cv_msg_code_00001          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00001';          -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_code_00003          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';          -- �v���t�@�C���擾�G���[
  cv_msg_code_10337          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10337';          -- �x�����t�H�[�}�b�g�G���[
  cv_msg_code_10338          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10338';          -- �\���Ώۃ`�F�b�N�G���[
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL START
--  cv_msg_code_00012          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00012';          -- �������_�擾�G���[
--  cv_msg_code_10372          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10372';          -- ���_�Z�L�����e�B�[�G���[
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL END
  cv_msg_code_00048          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00048';          -- ����v�㋒�_���擾�G���[
  cv_msg_code_00047          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00047';          -- ����v�㋒�_��񕡐����G���[
  cv_msg_code_00035          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00035';          -- �ڋq���擾�G���[
  cv_msg_code_00046          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00046';          -- �ڋq��񕡐����G���[
-- Ver.1.22 DEL START
--  cv_msg_code_10333          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10333';          -- �d���E��s���擾�G���[
-- Ver.1.22 DEL END
  cv_msg_code_10334          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10334';          -- �d���E��s��񕡐����G���[
  cv_msg_code_00015          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00015';          -- �N�C�b�N�R�[�h�擾�G���[
  cv_msg_code_00071          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00071';          -- �p�����[�^(�x���N����)
  cv_msg_code_00073          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00073';          -- �p�����[�^(�⍇���S�����_)
  cv_msg_code_00074          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00074';          -- �p�����[�^(����v�㋒�_)
  cv_msg_code_00075          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00075';          -- �p�����[�^(�\���Ώ�)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  cv_msg_code_00094          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00094';          -- �p�����[�^(�x����R�[�h)
  cv_msg_code_00095          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00095';          -- �p�����[�^(�x���X�e�[�^�X)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
  cv_msg_code_00040          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00040';          -- SVF�N��API�G���[
  cv_msg_code_90000          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';          -- �Ώی���
  cv_msg_code_90001          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';          -- ��������
  cv_msg_code_90002          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';          -- �G���[����
  cv_msg_code_90004          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';          -- ����I��
  cv_msg_code_90005          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005';          -- �x���I��
  cv_msg_code_90006          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--  cv_msg_code_00013          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00013';          -- �݌ɑg�DID�擾�G���[
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
  cv_msg_code_10393          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10393';          -- �폜�G���[
  cv_msg_code_10394          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10394';          -- ���b�N�G���[
  cv_msg_code_00028          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';          -- �Ɩ��������t�擾�G���[
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  cv_msg_code_10535          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10535';          -- ���[���[�N�e�[�u���X�V�G���[
  cv_msg_code_10536          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10536';          -- ���[���[�N�e�[�u���폜�G���[
  cv_msg_code_10537          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10537';          -- ���[���[�N�e�[�u���o�^�G���[
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
  -- �g�[�N��
  cv_token_user_id           CONSTANT VARCHAR2(7)   := 'USER_ID';
  cv_token_sales_loc         CONSTANT VARCHAR2(9)   := 'SALES_LOC';
  cv_token_cust_code         CONSTANT VARCHAR2(9)   := 'CUST_CODE';
  cv_token_cost_code         CONSTANT VARCHAR2(9)   := 'COST_CODE';
  cv_token_vendor_code       CONSTANT VARCHAR2(11)  := 'VENDOR_CODE';
  cv_token_vendor_site_code  CONSTANT VARCHAR2(16)  := 'VENDOR_SITE_CODE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(16)  := 'LOOKUP_VALUE_SET';
  cv_token_location_code     CONSTANT VARCHAR2(13)  := 'LOCATION_CODE';
  cv_token_profile           CONSTANT VARCHAR2(7)   := 'PROFILE';
  cv_token_count             CONSTANT VARCHAR2(5)   := 'COUNT';
  cv_token_pay_date          CONSTANT VARCHAR2(8)   := 'PAY_DATE';
  cv_token_ref_base_cd       CONSTANT VARCHAR2(13)  := 'REF_BASE_CODE';
  cv_token_selling_base_cd   CONSTANT VARCHAR2(17)  := 'SELLING_BASE_CODE';
  cv_token_target_disp       CONSTANT VARCHAR2(11)  := 'TARGET_DISP';
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  cv_token_payment_cd        CONSTANT VARCHAR2(12)  := 'PAYMENT_CODE';
  cv_token_resv_payment      CONSTANT VARCHAR2(12)  := 'RESV_PAYMENT';
  cv_token_errmsg            CONSTANT VARCHAR2(6)   := 'ERRMSG';
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--  cv_token_org_code          CONSTANT VARCHAR2(8)   := 'ORG_CODE';
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
  cv_token_request_id        CONSTANT VARCHAR2(10)  := 'REQUEST_ID';
  -- �v���t�@�C��
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL START
--  cv_prof_aff2_dept_act      CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF2_DEPT_ACT';               --����R�[�h_�Ɩ��Ǘ���
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL END
  cv_prof_error_mark         CONSTANT VARCHAR2(32)  := 'XXCOK1_BL_LIST_PROMPT_ERROR_MARK';   --�c���ꗗ_�װϰ����o��
  cv_prof_pay_stop_name      CONSTANT VARCHAR2(35)  := 'XXCOK1_BL_LIST_PROMPT_PAY_STOP_NAME';--�c���ꗗ_��~�����o��
  cv_prof_bk_trns_fee_we     CONSTANT VARCHAR2(23)  := 'XXCOK1_BANK_TRNS_FEE_WE';            --�U���萔��_����
  cv_prof_bk_trns_fee_ctpty  CONSTANT VARCHAR2(26)  := 'XXCOK1_BANK_TRNS_FEE_CTPTY';         --�U���萔��_�����
  cv_prof_pay_res_name       CONSTANT VARCHAR2(34)  := 'XXCOK1_BL_LIST_PROMPT_PAY_RES_NAME'; --�c���ꗗ_�ۗ����o��
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD START
  cv_prof_pay_rec_name       CONSTANT VARCHAR2(34)  := 'XXCOK1_BL_LIST_PROMPT_PAY_REC_NAME';      --�c���ꗗ_�����ό��o��
  cv_prof_pay_auto_res_name  CONSTANT VARCHAR2(39)  := 'XXCOK1_BL_LIST_PROMPT_PAY_AUTO_RES_NAME'; --�c���ꗗ_�����J�z���o��
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD END
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD START
  cv_prof_trans_criterion    CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_TRANS_CRITERION';    --��s�萔��_�U���z�
  cv_prof_less_fee_criterion CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_LESS_CRITERION';     --��s�萔��_��z����
  cv_prof_more_fee_criterion CONSTANT VARCHAR2(35)  := 'XXCOK1_BANK_FEE_MORE_CRITERION';     --��s�萔��_��z�ȏ�
  cv_prof_bm_tax             CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_TAX';                      --�̔��萔��_����ŗ�
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD END
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';              --�݌ɑg�D�R�[�h_�c�Ƒg�D
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
  cv_prof_org_id             CONSTANT VARCHAR2(6)   := 'ORG_ID';                             --�c�ƒP��ID
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  cv_prof_unpaid_elec_mark   CONSTANT VARCHAR2(38)  := 'XXCOK1_BL_LIST_PROMPT_UNPAID_ELEC_MARK';
                                                                                             --�c���ꗗ_�ϓ��d�C�㖢��ϰ����o��
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
  -- �t�H�[�}�b�g
  cv_format_yyyymmdd         CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_format_yyyymmdd2        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
-- 2012/07/10 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka ADD START
  cv_format_mm               CONSTANT VARCHAR2(6)   := 'MM';
-- 2012/07/10 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka ADD END
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)   := '.';
  -- ���l
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  -- �ڋq�敪
  cv_cust_class_code1        CONSTANT VARCHAR2(1)   := '1';  -- ���_
  cv_cust_class_code10       CONSTANT VARCHAR2(2)   := '10'; -- �ڋq
  -- �t���O
  cv_flag_y                  CONSTANT VARCHAR2(1)   := 'Y';
  -- �Q�ƃ^�C�v
  cv_lookup_type_bm_kbn      CONSTANT VARCHAR2(20)  := 'XXCMM_BM_PAYMENT_KBN';
-- Ver.1.24 ADD START
  cv_lookup_type_bm_tax_kbn  CONSTANT VARCHAR2(20)  := 'XXCSO1_BM_TAX_KBN';
-- Ver.1.24 ADD END
-- 2010/01/27 Ver.1.11 [��QE_�{�ғ�_01176] SCS K.Kiriu START
--  cv_lookup_type_bank        CONSTANT VARCHAR2(20)  := 'JP_BANK_ACCOUNT_TYPE';
  cv_lookup_type_bank        CONSTANT VARCHAR2(16)  := 'XXCSO1_KOZA_TYPE';
-- 2010/01/27 Ver.1.11 [��QE_�{�ғ�_01176] SCS K.Kiriu END
  -- �l�Z�b�g
  cv_set_name                CONSTANT VARCHAR2(18)  := 'XXCOK1_TARGET_DISP';
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  cv_set_name_rp             CONSTANT VARCHAR2(19)  := 'XXCOK1_RESV_PAYMENT';
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD START
  cv_set_name_et             CONSTANT VARCHAR2(15)  := 'XXCOK1_ERR_TYPE';
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD END
  -- SVF�N���p�����[�^
  cv_file_id                 CONSTANT VARCHAR2(12)  := 'XXCOK014A04R';       -- ���[ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                  -- �o�͋敪(PDF�o��)
  cv_frm_file                CONSTANT VARCHAR2(16)  := 'XXCOK014A04S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                CONSTANT VARCHAR2(16)  := 'XXCOK014A04S.vrq';   -- �N�G���[�l���t�@�C����
  cv_pdf                     CONSTANT VARCHAR2(4)   := '.pdf';               -- �o�̓t�@�C���g���q
  -- �\���Ώ�
  cv_target_disp1            CONSTANT VARCHAR2(1)   := '1'; -- �����_�̂�
  cv_target_disp2            CONSTANT VARCHAR2(1)   := '2'; -- �����_�܂�
  cv_target_disp1_nm         CONSTANT VARCHAR2(1)   := '1'; -- �����_�̂�
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD START
  -- �Œ蕶��
  cv_em_dash                 CONSTANT VARCHAR2(2)   := '�\'; -- �S�p�_�b�V��
-- 20.1/04/26 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD END
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD START
  cv_proc_type0_upd          CONSTANT VARCHAR2(1)  := '0';  -- (UPDATE�p)�����敪�F�ۗ�����(�����l)
  cv_proc_type1_upd          CONSTANT VARCHAR2(1)  := '1';  -- (UPDATE�p)�����敪�F������
  cv_proc_type2_upd          CONSTANT VARCHAR2(1)  := '2';  -- (UPDATE�p)�����敪�F�ۗ�
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD END
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD START
  cv_bm_payment_type1        CONSTANT VARCHAR2(1)  := '1'; -- BM�x���敪(1�F�{�U�i�ē�������j)
  cv_bm_payment_type2        CONSTANT VARCHAR2(1)  := '2'; -- BM�x���敪(2�F�{�U�i�ē����Ȃ��j)
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD END
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  ct_status_comp             CONSTANT xxcso_contract_managements.status%TYPE           := '1';  -- �m���
  ct_cooperate_comp          CONSTANT xxcso_contract_managements.cooperate_flag%TYPE   := '1';  -- �A�g�ς�
  ct_electricity_type0       CONSTANT xxcso_sp_decision_headers.electricity_type%TYPE  := '0';  -- �d�C��Ȃ�
  ct_electricity_type2       CONSTANT xxcso_sp_decision_headers.electricity_type%TYPE  := '2';  -- �ϓ��d�C��
  cv_ja                      CONSTANT VARCHAR2(2)  := 'JA'; -- ���{��
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
-- Ver.1.24 ADD START
  cv_tax_included            CONSTANT VARCHAR2(1)  := '1';  -- �ō���
-- Ver.1.24 ADD END
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt              NUMBER        DEFAULT 0;    -- �Ώی���
  gn_normal_cnt              NUMBER        DEFAULT 0;    -- ���팏��
  gn_error_cnt               NUMBER        DEFAULT 0;    -- �G���[����
  gd_payment_date            DATE          DEFAULT NULL; -- �x����
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL START
--  gv_base_code               VARCHAR2(4)   DEFAULT NULL; -- �������_�R�[�h
--  gv_aff2_dept_act           VARCHAR2(4)   DEFAULT NULL; -- �Ɩ��Ǘ����̕���R�[�h
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL END
  gv_error_mark              VARCHAR2(2)   DEFAULT NULL; -- �G���[�}�[�N���o��
  gv_pay_stop_name           VARCHAR2(6)   DEFAULT NULL; -- ��~�����o��
  gv_bk_trns_fee_we          VARCHAR2(10)  DEFAULT NULL; -- �U���萔��_����
  gv_bk_trns_fee_ctpty       VARCHAR2(8)   DEFAULT NULL; -- �U���萔��_�����
  gv_pay_res_name            VARCHAR2(4)   DEFAULT NULL; -- �ۗ����o��
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD START
  gn_trans_fee               NUMBER        DEFAULT 0;    -- ��s�萔��(�U���z�)
  gn_less_fee                NUMBER        DEFAULT 0;    -- ��s�萔��(�����)
  gn_more_fee                NUMBER        DEFAULT 0;    -- ��s�萔��(��ȏ�)
  gn_bm_tax                  NUMBER        DEFAULT 0;    -- ����ŗ�
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD END
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD START
  gv_pay_rec_name            VARCHAR2(6)   DEFAULT NULL; -- �����ό��o��
  gv_pay_auto_res_name       VARCHAR2(8)   DEFAULT NULL; -- �����J�z���o��
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD END
  gv_ref_base_code           VARCHAR2(4)   DEFAULT NULL; -- �⍇���S�����_
  gv_selling_base_code       VARCHAR2(4)   DEFAULT NULL; -- ����v�㋒�_
  gv_target_disp             VARCHAR2(12)  DEFAULT NULL; -- �\���Ώ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  gv_unpaid_elec_mark        VARCHAR2(2)   DEFAULT NULL;                           -- �ϓ��d�C�㖢���}�[�N���o��
  gt_payment_code            xxcok_rep_bm_balance.payment_code%TYPE  DEFAULT NULL; -- �x����R�[�h
  gt_resv_payment            xxcok_rep_bm_balance.resv_payment%TYPE  DEFAULT NULL; -- �x���X�e�[�^�X
  gv_resv_payment_nm         VARCHAR2(10)  DEFAULT NULL;                           -- �x���X�e�[�^�X��
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--  gv_org_code                VARCHAR2(50)  DEFAULT NULL; -- �݌ɑg�D�R�[�h_�c�Ƒg�D
--  gn_organization_id         NUMBER        DEFAULT NULL; -- �݌ɑg�DID
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
  gv_no_data_msg             VARCHAR2(30)  DEFAULT NULL; -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  gn_index                   NUMBER        DEFAULT 0;    -- ����
  gn_org_id                  NUMBER        DEFAULT NULL; -- �c�ƒP��ID
  gd_process_date            DATE          DEFAULT NULL; -- �Ɩ��������t
  gv_target_disp_nm          VARCHAR2(20)  DEFAULT NULL; -- �\���Ώۖ�
  -- �ޔ�p
  gt_payment_code_bk         xxcok_rep_bm_balance.payment_code%TYPE               DEFAULT NULL; -- �x����R�[�h
  gt_payment_name_bk         xxcok_rep_bm_balance.payment_name%TYPE               DEFAULT NULL; -- �x���於
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD START
--  gt_bank_no_bk              xxcok_rep_bm_balance.bank_no%TYPE                    DEFAULT NULL; -- ��s�ԍ�
  gt_bank_no_bk              ap_bank_branches.bank_number%TYPE                    DEFAULT NULL; -- ��s�ԍ�
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD END
  gt_bank_name_bk            xxcok_rep_bm_balance.bank_name%TYPE                  DEFAULT NULL; -- ��s��
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD START
--  gt_bank_branch_no_bk       xxcok_rep_bm_balance.bank_branch_no%TYPE             DEFAULT NULL; -- ��s�x�X�ԍ�
  gt_bank_branch_no_bk       ap_bank_branches.bank_num%TYPE                       DEFAULT NULL; -- ��s�x�X�ԍ�
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD END
  gt_bank_branch_name_bk     xxcok_rep_bm_balance.bank_branch_name%TYPE           DEFAULT NULL; -- ��s�x�X��
  gt_bank_acct_type_bk       xxcok_rep_bm_balance.bank_acct_type%TYPE             DEFAULT NULL; -- �������
  gt_bank_acct_type_name_bk  xxcok_rep_bm_balance.bank_acct_type_name%TYPE        DEFAULT NULL; -- ������ʖ�
  gt_bank_acct_no_bk         xxcok_rep_bm_balance.bank_acct_no%TYPE               DEFAULT NULL; -- �����ԍ�
  gt_bank_acct_name_bk       xxcok_rep_bm_balance.bank_acct_name%TYPE             DEFAULT NULL; -- ��s������
  gt_ref_base_code_bk        xxcok_rep_bm_balance.ref_base_code%TYPE              DEFAULT NULL; -- �⍇���S�����_�R�[�h
  gt_ref_base_name_bk        xxcok_rep_bm_balance.ref_base_name%TYPE              DEFAULT NULL; -- �⍇���S�����_��
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi START
--  gt_bm_type_bk              xxcmn_lookup_values_v.lookup_code%TYPE               DEFAULT NULL; -- BM�x���敪
  gt_bm_type_bk              xxcok_lookups_v.lookup_code%TYPE                     DEFAULT NULL; -- BM�x���敪
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi END
  gt_bm_payment_type_bk      xxcok_rep_bm_balance.bm_payment_type%TYPE            DEFAULT NULL; -- BM�x���敪��
  gt_bank_trns_fee_bk        xxcok_rep_bm_balance.bank_trns_fee%TYPE              DEFAULT NULL; -- �U���萔��
  gt_payment_stop_bk         xxcok_rep_bm_balance.payment_stop%TYPE               DEFAULT NULL; -- �x����~
  gt_selling_base_code_bk    xxcok_rep_bm_balance.selling_base_code%TYPE          DEFAULT NULL; -- ����v�㋒�_�R�[�h
  gt_selling_base_name_bk    xxcok_rep_bm_balance.selling_base_name%TYPE          DEFAULT NULL; -- ����v�㋒�_��
  gt_warnning_mark_bk        xxcok_rep_bm_balance.warnning_mark%TYPE              DEFAULT NULL; -- �x���}�[�N
  gt_cust_code_bk            xxcok_rep_bm_balance.cust_code%TYPE                  DEFAULT NULL; -- �ڋq�R�[�h
  gt_cust_name_bk            xxcok_rep_bm_balance.cust_name%TYPE                  DEFAULT NULL; -- �ڋq��
  gt_resv_payment_bk         xxcok_rep_bm_balance.resv_payment%TYPE               DEFAULT NULL; -- �x���ۗ�
  gt_payment_date_bk         xxcok_rep_bm_balance.payment_date%TYPE               DEFAULT NULL; -- �x����
  gt_closing_date_bk         xxcok_rep_bm_balance.closing_date%TYPE               DEFAULT NULL; -- ���ߓ�
  gt_section_code_bk         xxcok_rep_bm_balance.selling_base_section_code%TYPE  DEFAULT NULL; -- �n��R�[�h
-- Ver.1.24 ADD START
  gt_bm_tax_kbn_name_bk      xxcok_rep_bm_balance.bm_tax_kbn_name%TYPE            DEFAULT NULL; -- BM�ŋ敪��
-- Ver.1.24 ADD END
  -- �W�v�p
  gt_unpaid_last_month_sum xxcok_rep_bm_balance.unpaid_last_month%TYPE          DEFAULT 0;  -- �O���܂ł̖���
  gt_bm_this_month_sum     xxcok_rep_bm_balance.bm_this_month%TYPE              DEFAULT 0;  -- ����BM
  gt_electric_amt_sum      xxcok_rep_bm_balance.electric_amt%TYPE               DEFAULT 0;  -- �d�C��
  gt_unpaid_balance_sum    xxcok_rep_bm_balance.unpaid_balance%TYPE             DEFAULT 0;  -- �����c��
  -- ===============================
  -- ���R�[�h�^�C�v�̐錾��
  -- ===============================
  TYPE rep_bm_balance_rec IS RECORD(
    PAYMENT_CODE                 VARCHAR2(9)   -- �x����R�[�h
   ,PAYMENT_NAME                 VARCHAR2(240) -- �x���於
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD START
--   ,BANK_NO                      VARCHAR2(4)   -- ��s�ԍ�
   ,BANK_NO                      VARCHAR2(30)  -- ��s�ԍ�
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD END
   ,BANK_NAME                    VARCHAR2(60)  -- ��s��
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD START
--   ,BANK_BRANCH_NO               VARCHAR2(4)   -- ��s�x�X�ԍ�
   ,BANK_BRANCH_NO               VARCHAR2(25)  -- ��s�x�X�ԍ�
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD END
   ,BANK_BRANCH_NAME             VARCHAR2(60)  -- ��s�x�X��
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD START
--   ,BANK_ACCT_TYPE               VARCHAR2(1)   -- �������
   ,BANK_ACCT_TYPE               VARCHAR2(2)   -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD END
   ,BANK_ACCT_TYPE_NAME          VARCHAR2(4)   -- ������ʖ�
-- 2009/04/17 Ver.1.4 [��QT1_0647] SCS T.Taniguchi START
--   ,BANK_ACCT_NO                 VARCHAR2(7)   -- �����ԍ�
   ,BANK_ACCT_NO                 VARCHAR2(30)  -- �����ԍ�
-- 2009/04/17 Ver.1.4 [��QT1_0647] SCS T.Taniguchi END
   ,BANK_ACCT_NAME               VARCHAR2(150) -- ��s������
   ,REF_BASE_CODE                VARCHAR2(4)   -- �⍇���S�����_�R�[�h
   ,REF_BASE_NAME                VARCHAR2(240) -- �⍇���S�����_��
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD START
   ,BM_PAYMENT_CODE              VARCHAR2(30)  -- BM�x���敪(�R�[�h�l)
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD END
   ,BM_PAYMENT_TYPE              VARCHAR2(80)  -- BM�x���敪
   ,BANK_TRNS_FEE                VARCHAR2(20)  -- �U���萔��
   ,PAYMENT_STOP                 VARCHAR2(20)  -- �x����~
   ,SELLING_BASE_CODE            VARCHAR2(4)   -- ����v�㋒�_�R�[�h
   ,SELLING_BASE_NAME            VARCHAR2(240) -- ����v�㋒�_��
   ,WARNNING_MARK                VARCHAR2(2)   -- �x���}�[�N
   ,CUST_CODE                    VARCHAR2(9)   -- �ڋq�R�[�h
   ,CUST_NAME                    VARCHAR2(360) -- �ڋq��
   ,BM_THIS_MONTH                NUMBER        -- ����BM
   ,ELECTRIC_AMT                 NUMBER        -- �d�C��
   ,UNPAID_LAST_MONTH            NUMBER        -- �O���܂ł̖���
   ,UNPAID_BALANCE               NUMBER        -- �����c��
-- 2012/07/11 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD START
--   ,RESV_PAYMENT                 VARCHAR2(4)   -- �x���ۗ�
   ,RESV_PAYMENT                 VARCHAR2(8)   -- �x���ۗ�
-- 2012/07/11 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD START
   ,PAYMENT_DATE                 DATE          -- �x����
   ,CLOSING_DATE                 DATE          -- ���ߓ�
   ,SELLING_BASE_SECTION_CODE    VARCHAR2(5)   -- �n��R�[�h�i����v�㋒�_�j
-- Ver.1.24 ADD START
   ,BM_TAX_KBN_NAME              VARCHAR2(80)  -- BM�ŋ敪��
-- Ver.1.24 ADD END
  );
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki ADD START
  TYPE g_target_rtype IS RECORD(
    bm_balance_id                xxcok_backmargin_balance.bm_balance_id%TYPE           -- ����ID
   ,base_code                    xxcok_backmargin_balance.base_code%TYPE               -- ���_�R�[�h
   ,supplier_code                xxcok_backmargin_balance.supplier_code%TYPE           -- �d����R�[�h
   ,supplier_site_code           xxcok_backmargin_balance.supplier_site_code%TYPE      -- �d����T�C�g�R�[�h
   ,cust_code                    xxcok_backmargin_balance.cust_code%TYPE               -- �ڋq�R�[�h
   ,closing_date                 xxcok_backmargin_balance.closing_date%TYPE            -- ���ߓ�
   ,backmargin                   xxcok_backmargin_balance.backmargin%TYPE              -- �̔��萔��
   ,backmargin_tax               xxcok_backmargin_balance.backmargin_tax%TYPE          -- �̔��萔���i����Ŋz�j
   ,electric_amt                 xxcok_backmargin_balance.electric_amt%TYPE            -- �d�C��
   ,electric_amt_tax             xxcok_backmargin_balance.electric_amt_tax%TYPE        -- �d�C���i����Ŋz�j
   ,expect_payment_date          xxcok_backmargin_balance.expect_payment_date%TYPE     -- �x���\���
   ,expect_payment_amt_tax       xxcok_backmargin_balance.expect_payment_amt_tax%TYPE  -- �x���\��z�i�ō��j
   ,resv_flag                    xxcok_backmargin_balance.resv_flag%TYPE               -- �ۗ��t���O
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD START
   ,payment_amt_tax              xxcok_backmargin_balance.payment_amt_tax%TYPE         -- �x���z�i�ō��j
   ,fb_interface_date            xxcok_backmargin_balance.fb_interface_date%TYPE       -- �A�g���i�{�U�pFB�j
   ,proc_type                    xxcok_backmargin_balance.proc_type%TYPE               -- �����敪
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD END
  );
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki ADD END
  -- ===============================
  -- �e�[�u���^�C�v�̐錾��
  -- ===============================
  TYPE rep_bm_balance_tbl IS TABLE OF rep_bm_balance_rec INDEX BY BINARY_INTEGER;
  g_bm_balance_ttype  rep_bm_balance_tbl;
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD START
--  CURSOR g_target_cur(
--    iv_target_disp_flg          IN VARCHAR2  -- �\���t���O
--  )
--  IS
--    SELECT bm_balance_id          -- ����ID
--          ,base_code              -- ���_�R�[�h
--          ,supplier_code          -- �d����R�[�h
--          ,supplier_site_code     -- �d����T�C�g�R�[�h
--          ,cust_code              -- �ڋq�R�[�h
--          ,closing_date           -- ���ߓ�
--          ,backmargin             -- �̔��萔��
--          ,backmargin_tax         -- �̔��萔���i����Ŋz
--          ,electric_amt           -- �d�C��
--          ,electric_amt_tax       -- �d�C���i����Ŋz�j
--          ,expect_payment_date    -- �x���\���
--          ,expect_payment_amt_tax -- �x���\��z�i�ō��j
--          ,resv_flag              -- �ۗ��t���O
--    FROM (SELECT  xbb.bm_balance_id                    AS  bm_balance_id         -- ����ID
--                 ,xbb.base_code                        AS base_code              -- ���_�R�[�h
--                 ,xbb.supplier_code                    AS supplier_code          -- �d����R�[�h
--                 ,xbb.supplier_site_code               AS supplier_site_code     -- �d����T�C�g�R�[�h
--                 ,xbb.cust_code                        AS cust_code              -- �ڋq�R�[�h
--                 ,xbb.closing_date                     AS closing_date           -- ���ߓ�
--                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- �̔��萔��
--                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- �̔��萔���i����Ŋz�j
--                 ,NVL( xbb.electric_amt ,0)            AS electric_amt           -- �d�C��
--                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- �d�C���i����Ŋz�j
--                 ,xbb.expect_payment_date              AS expect_payment_date    -- �x���\���
--                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- �x���\��z�i�ō��j
--                 ,xbb.resv_flag                        AS resv_flag              -- �ۗ��t���O
--          FROM   xxcok_backmargin_balance  xbb    -- �̎�c���e�[�u��
--                ,po_vendors                pv     -- �d����}�X�^
--                ,po_vendor_sites_all       pvsa   -- �d����T�C�g
--          WHERE  xbb.base_code                                 = NVL( gv_selling_base_code ,xbb.base_code)
--          AND    TRUNC( xbb.expect_payment_date )             <= gd_payment_date
--          AND    pv.vendor_id                                  = pvsa.vendor_id
--          AND    pv.segment1                                   = xbb.supplier_code
--          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
--          AND    cv_target_disp1                               = iv_target_disp_flg
--          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
--          AND    pvsa.org_id                                   = gn_org_id
--          UNION
--          SELECT  xbb.bm_balance_id                    AS bm_balance_id          -- ����ID
--                 ,xbb.base_code                        AS base_code              -- ���_�R�[�h
--                 ,xbb.supplier_code                    AS supplier_code          -- �d����R�[�h
--                 ,xbb.supplier_site_code               AS supplier_site_code     -- �d����T�C�g�R�[�h
--                 ,xbb.cust_code                        AS cust_code              -- �ڋq�R�[�h
--                 ,xbb.closing_date                     AS closing_date           -- ���ߓ�
--                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- �̔��萔��
--                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- �̔��萔���i����Ŋz�j
--                 ,NVL( xbb.electric_amt ,0 )           AS electric_amt           -- �d�C��
--                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- �d�C���i����Ŋz�j
--                 ,xbb.expect_payment_date              AS expect_payment_date    -- �x���\���
--                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- �x���\��z�i�ō��j
--                 ,xbb.resv_flag                        AS resv_flag              -- �ۗ��t���O
--          FROM   xxcok_backmargin_balance xbb     -- �̎�c���e�[�u��
--                ,po_vendors                pv     -- �d����}�X�^
--                ,po_vendor_sites_all       pvsa   -- �d����T�C�g
--          WHERE  xbb.supplier_code IN (SELECT supplier_code                 -- �d����R�[�h
--                                       FROM   xxcok_backmargin_balance      -- �̎�c���e�[�u��
--                                       WHERE  TRUNC( expect_payment_date ) <= gd_payment_date
--                                       AND    base_code = NVL( gv_selling_base_code ,base_code )
--                                  )
--          AND    TRUNC( xbb.expect_payment_date )             <= gd_payment_date
--          AND    pv.vendor_id                                  = pvsa.vendor_id
--          AND    pv.segment1                                   = xbb.supplier_code
--          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
--          AND    cv_target_disp2                               = iv_target_disp_flg
--          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
--          AND    pvsa.org_id                                   = gn_org_id
--          )
--    ORDER BY  supplier_code       -- �d����R�[�h
--             ,base_code           -- ���_�R�[�h
--             ,cust_code           -- �ڋq�R�[�h
---- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--             ,expect_payment_date -- �x���\���
---- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
---- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD START
--             ,closing_date        -- ���ߓ�
---- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD END
--    ;
----
--  g_target_rec g_target_cur%ROWTYPE;
  --
  -- ���̓p�����[�^���u���㋒�_��v���u�����_�̂݁v�̏ꍇ
  CURSOR g_target_cur1
  IS
-- Ver.1.22 MOD START
--    SELECT /*+
--             leading(xbb2 xbb pv pvsa)
--             use_nl (xbb2 xbb pv pvsa)
--             index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
--             index  (pv   PO_VENDORS_U3)
--             index  (pvsa PO_VENDOR_SITES_U2)
--           */
    SELECT
-- Ver.1.22 MOD END
           bm_balance_id          -- ����ID
          ,base_code              -- ���_�R�[�h
          ,supplier_code          -- �d����R�[�h
          ,supplier_site_code     -- �d����T�C�g�R�[�h
          ,cust_code              -- �ڋq�R�[�h
          ,closing_date           -- ���ߓ�
          ,backmargin             -- �̔��萔��
          ,backmargin_tax         -- �̔��萔���i����Ŋz
          ,electric_amt           -- �d�C��
          ,electric_amt_tax       -- �d�C���i����Ŋz�j
          ,expect_payment_date    -- �x���\���
          ,expect_payment_amt_tax -- �x���\��z�i�ō��j
          ,resv_flag              -- �ۗ��t���O
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD START
          ,payment_amt_tax        -- �x���z�i�ō��j
          ,fb_interface_date      -- �A�g���i�{�U�pFB�j
          ,proc_type              -- �����敪
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD END
    FROM (SELECT /*+
-- Ver.1.22 MOD START
--                   leading(xbb2 xbb pv pvsa)
--                   use_nl (xbb2 xbb pv pvsa)
--                   index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
--                   index  (pv   PO_VENDORS_U3)
--                   index  (pvsa PO_VENDOR_SITES_U2)
                   leading(xca)
                   use_nl (xca xbb)
-- Ver.1.22 MOD END
                 */
                  xbb.bm_balance_id                    AS bm_balance_id          -- ����ID
                 ,xbb.base_code                        AS base_code              -- ���_�R�[�h
                 ,xbb.supplier_code                    AS supplier_code          -- �d����R�[�h
                 ,xbb.supplier_site_code               AS supplier_site_code     -- �d����T�C�g�R�[�h
                 ,xbb.cust_code                        AS cust_code              -- �ڋq�R�[�h
                 ,xbb.closing_date                     AS closing_date           -- ���ߓ�
                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- �̔��萔��
                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- �̔��萔���i����Ŋz�j
                 ,NVL( xbb.electric_amt ,0)            AS electric_amt           -- �d�C��
                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- �d�C���i����Ŋz�j
                 ,xbb.expect_payment_date              AS expect_payment_date    -- �x���\���
                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- �x���\��z�i�ō��j
                 ,xbb.resv_flag                        AS resv_flag              -- �ۗ��t���O
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD START
                 ,NVL( xbb.payment_amt_tax ,0 )        AS payment_amt_tax        -- �x���z�i�ō��j
                 ,xbb.fb_interface_date                AS fb_interface_date      -- �A�g���i�{�U�pFB�j
                 ,xbb.proc_type                        AS proc_type              -- �����敪
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD END
          FROM   xxcok_backmargin_balance  xbb    -- �̎�c���e�[�u��
-- Ver.1.22 DEL START
--                ,po_vendors                pv     -- �d����}�X�^
--                ,po_vendor_sites_all       pvsa   -- �d����T�C�g
-- Ver.1.22 DEL END
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki ADD START
                ,xxcmm_cust_accounts       xca    -- �ڋq�ǉ����
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki ADD END
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki UPD START
--          WHERE  xbb.base_code                                 = NVL( gv_selling_base_code ,xbb.base_code)
          WHERE  xbb.cust_code                                 = xca.customer_code
-- Ver.1.22 MOD START
--          AND    xca.past_sale_base_code                       = NVL( gv_selling_base_code ,xca.past_sale_base_code)
          AND    xca.past_sale_base_code                       = gv_selling_base_code
-- Ver.1.22 MOD END
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki UPD END
          AND    xbb.expect_payment_date                      <= gd_payment_date
-- Ver.1.22 MOD START
--          AND    xbb.supplier_code                             = pv.segment1
---- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
--          AND    pv.segment1                                   = NVL( gt_payment_code ,pv.segment1 )
---- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
--          AND    pv.vendor_id                                  = pvsa.vendor_id
--          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
--          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
--          AND    pvsa.org_id                                   = gn_org_id
          AND    xbb.supplier_code                             = NVL( gt_payment_code ,xbb.supplier_code )
-- Ver.1.22 MOD END
          )
    ORDER BY  supplier_code       -- �d����R�[�h
             ,base_code           -- ���_�R�[�h
             ,cust_code           -- �ڋq�R�[�h
             ,expect_payment_date -- �x���\���
             ,closing_date        -- ���ߓ�
    ;
  --
  -- ���̓p�����[�^���u���㋒�_��v���u�����_���܂ށv�̏ꍇ
  CURSOR g_target_cur2
  IS
-- Ver.1.22 MOD START
--    SELECT /*+
--             leading(xbb2 xbb pv pvsa)
--             use_nl (xbb2 xbb pv pvsa)
--             index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
--             index  (pv   PO_VENDORS_U3)
--             index  (pvsa PO_VENDOR_SITES_U2)
--           */
    SELECT
-- Ver.1.22 MOD END
           bm_balance_id          -- ����ID
          ,base_code              -- ���_�R�[�h
          ,supplier_code          -- �d����R�[�h
          ,supplier_site_code     -- �d����T�C�g�R�[�h
          ,cust_code              -- �ڋq�R�[�h
          ,closing_date           -- ���ߓ�
          ,backmargin             -- �̔��萔��
          ,backmargin_tax         -- �̔��萔���i����Ŋz
          ,electric_amt           -- �d�C��
          ,electric_amt_tax       -- �d�C���i����Ŋz�j
          ,expect_payment_date    -- �x���\���
          ,expect_payment_amt_tax -- �x���\��z�i�ō��j
          ,resv_flag              -- �ۗ��t���O
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD START
          ,payment_amt_tax        -- �x���z�i�ō��j
          ,fb_interface_date      -- �A�g���i�{�U�pFB�j
          ,proc_type              -- �����敪
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD END
    FROM (SELECT /*+
-- Ver.1.22 MOD START
--                   leading(xbb2 xbb pv pvsa)
--                   use_nl (xbb2 xbb pv pvsa)
--                   index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
--                   index  (pv   PO_VENDORS_U3)
--                   index  (pvsa PO_VENDOR_SITES_U2)
                   leading(xca)
                   use_nl (xca xbb)
-- Ver.1.22 MOD END
                 */
                  xbb.bm_balance_id                    AS bm_balance_id          -- ����ID
                 ,xbb.base_code                        AS base_code              -- ���_�R�[�h
                 ,xbb.supplier_code                    AS supplier_code          -- �d����R�[�h
                 ,xbb.supplier_site_code               AS supplier_site_code     -- �d����T�C�g�R�[�h
                 ,xbb.cust_code                        AS cust_code              -- �ڋq�R�[�h
                 ,xbb.closing_date                     AS closing_date           -- ���ߓ�
                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- �̔��萔��
                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- �̔��萔���i����Ŋz�j
                 ,NVL( xbb.electric_amt ,0 )           AS electric_amt           -- �d�C��
                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- �d�C���i����Ŋz�j
                 ,xbb.expect_payment_date              AS expect_payment_date    -- �x���\���
                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- �x���\��z�i�ō��j
                 ,xbb.resv_flag                        AS resv_flag              -- �ۗ��t���O
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD START
                 ,NVL( xbb.payment_amt_tax ,0 )        AS payment_amt_tax        -- �x���z�i�ō��j
                 ,xbb.fb_interface_date                AS fb_interface_date      -- �A�g���i�{�U�pFB�j
                 ,xbb.proc_type                        AS proc_type              -- �����敪
-- 2012/07/23 Ver.1.15 [��QE_�{�ғ�_08365,08367] SCSK K.Onotsuka ADD END
          FROM   xxcok_backmargin_balance xbb     -- �̎�c���e�[�u��
-- Ver.1.22 DEL START
--                ,po_vendors                pv     -- �d����}�X�^
--                ,po_vendor_sites_all       pvsa   -- �d����T�C�g
-- Ver.1.22 DEL END
          WHERE  xbb.supplier_code IN (SELECT /*+
-- Ver.1.22 MOD START
--                                                index(xbb2 XXCOK_BACKMARGIN_BALANCE_N08)
                                                index(xbb2 XXCOK_BACKMARGIN_BALANCE_N07)
-- Ver.1.22 MOD END
                                              */
                                              xbb2.supplier_code            -- �d����R�[�h
                                       FROM   xxcok_backmargin_balance xbb2 -- �̎�c���e�[�u��
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki ADD START
                                             ,xxcmm_cust_accounts      xca  -- �ڋq�ǉ����
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki ADD END
                                       WHERE  xbb2.expect_payment_date <= gd_payment_date
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki UPD START
--                                       AND    xbb2.base_code = NVL( gv_selling_base_code ,xbb2.base_code )
                                       AND    xbb2.cust_code     = xca.customer_code
-- Ver.1.22 MOD START
--                                       AND    xca.past_sale_base_code = NVL( gv_selling_base_code ,xca.past_sale_base_code)
                                       AND    xca.past_sale_base_code = gv_selling_base_code
-- Ver.1.22 MOD END
-- 2011/03/15 Ver.1.13 [��QE_�{�ғ�_05408,05409] SCS S.Niki UPD END
                                  )
          AND    xbb.expect_payment_date                      <= gd_payment_date
-- Ver.1.22 MOD START
--          AND    xbb.supplier_code                             = pv.segment1
---- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
--          AND    pv.segment1                                   = NVL( gt_payment_code ,pv.segment1 )
---- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
--          AND    pv.vendor_id                                  = pvsa.vendor_id
--          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
--          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
--          AND    pvsa.org_id                                   = gn_org_id
          AND    xbb.supplier_code                             = NVL( gt_payment_code ,xbb.supplier_code )
-- Ver.1.22 MOD END
          )
    ORDER BY  supplier_code       -- �d����R�[�h
             ,base_code           -- ���_�R�[�h
             ,cust_code           -- �ڋq�R�[�h
             ,expect_payment_date -- �x���\���
             ,closing_date        -- ���ߓ�
    ;
--
-- Ver.1.22 ADD START
  -- ���̓p�����[�^���u�⍇�����_��v�̏ꍇ
  CURSOR g_target_cur3
  IS
    SELECT bm_balance_id          -- ����ID
          ,base_code              -- ���_�R�[�h
          ,supplier_code          -- �d����R�[�h
          ,supplier_site_code     -- �d����T�C�g�R�[�h
          ,cust_code              -- �ڋq�R�[�h
          ,closing_date           -- ���ߓ�
          ,backmargin             -- �̔��萔��
          ,backmargin_tax         -- �̔��萔���i����Ŋz
          ,electric_amt           -- �d�C��
          ,electric_amt_tax       -- �d�C���i����Ŋz�j
          ,expect_payment_date    -- �x���\���
          ,expect_payment_amt_tax -- �x���\��z�i�ō��j
          ,resv_flag              -- �ۗ��t���O
          ,payment_amt_tax        -- �x���z�i�ō��j
          ,fb_interface_date      -- �A�g���i�{�U�pFB�j
          ,proc_type              -- �����敪
    FROM (SELECT /*+
                   leading(pv)
                   use_nl (pv pvsa xbb)
                   index  (xbb  XXCOK_BACKMARGIN_BALANCE_N09)
                   index  (pvsa PO_VENDOR_SITES_U2)
                 */
                  xbb.bm_balance_id                    AS bm_balance_id          -- ����ID
                 ,xbb.base_code                        AS base_code              -- ���_�R�[�h
                 ,xbb.supplier_code                    AS supplier_code          -- �d����R�[�h
                 ,xbb.supplier_site_code               AS supplier_site_code     -- �d����T�C�g�R�[�h
                 ,xbb.cust_code                        AS cust_code              -- �ڋq�R�[�h
                 ,xbb.closing_date                     AS closing_date           -- ���ߓ�
                 ,NVL( xbb.backmargin ,0 )             AS backmargin             -- �̔��萔��
                 ,NVL( xbb.backmargin_tax ,0 )         AS backmargin_tax         -- �̔��萔���i����Ŋz�j
                 ,NVL( xbb.electric_amt ,0)            AS electric_amt           -- �d�C��
                 ,NVL( xbb.electric_amt_tax ,0 )       AS electric_amt_tax       -- �d�C���i����Ŋz�j
                 ,xbb.expect_payment_date              AS expect_payment_date    -- �x���\���
                 ,NVL( xbb.expect_payment_amt_tax ,0 ) AS expect_payment_amt_tax -- �x���\��z�i�ō��j
                 ,xbb.resv_flag                        AS resv_flag              -- �ۗ��t���O
                 ,NVL( xbb.payment_amt_tax ,0 )        AS payment_amt_tax        -- �x���z�i�ō��j
                 ,xbb.fb_interface_date                AS fb_interface_date      -- �A�g���i�{�U�pFB�j
                 ,xbb.proc_type                        AS proc_type              -- �����敪
          FROM   xxcok_backmargin_balance  xbb    -- �̎�c���e�[�u��
                ,po_vendors                pv     -- �d����}�X�^
                ,po_vendor_sites_all       pvsa   -- �d����T�C�g
          WHERE  xbb.expect_payment_date                      <= gd_payment_date
          AND    xbb.supplier_code                             = pv.segment1
          AND    pv.segment1                                   = NVL( gt_payment_code ,pv.segment1 )
          AND    pv.vendor_id                                  = pvsa.vendor_id
          AND    pvsa.attribute5                               = NVL( gv_ref_base_code ,pvsa.attribute5 )
          AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
          AND    pvsa.org_id                                   = gn_org_id
          )
    ORDER BY  supplier_code       -- �d����R�[�h
             ,base_code           -- ���_�R�[�h
             ,cust_code           -- �ڋq�R�[�h
             ,expect_payment_date -- �x���\���
             ,closing_date        -- ���ߓ�
    ;
-- Ver.1.22 ADD END
  --
  g_target_rec g_target_rtype;
  --
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD END
  -- ===============================================
  -- ���ʗ�O
  -- ===============================================
  --*** ���b�N�G���[ ***
  global_lock_fail          EXCEPTION;
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  /**********************************************************************************
   * Procedure Name   : del_worktable_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE del_worktable_data(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'del_worktable_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR bm_balance_cur
    IS
      SELECT 'X'
      FROM   xxcok_rep_bm_balance  xrbb
      WHERE  xrbb.request_id = cn_request_id
      FOR UPDATE OF xrbb.request_id NOWAIT;

  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���ꗗ���[���[�N�e�[�u�����b�N�擾
    -- ===============================================
    OPEN  bm_balance_cur;
    CLOSE bm_balance_cur;
    -- ===============================================
    -- �̎�c���ꗗ���[���[�N�e�[�u���f�[�^�폜
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_rep_bm_balance
      WHERE  request_id = cn_request_id
      ;
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
      -- *** �폜�����G���[ ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10393
                      , iv_token_name1  => cv_token_request_id
                      , iv_token_value1 => cn_request_id
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    --*** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10394
                    , iv_token_name1  => cv_token_request_id
                    , iv_token_value1 => cn_request_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_worktable_data;
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF�N��(A-8)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(9) := 'start_svf'; -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg    VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_retcode   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    lv_file_name VARCHAR2(50)   DEFAULT NULL;              -- �o�̓t�@�C����
    lv_date      VARCHAR2(8)    DEFAULT NULL;              -- ���t(YYYYMMDD)
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �o�̓t�@�C����(���[ID + YYYYMMDD + �v��ID)
    -- ===============================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    lv_file_name := cv_file_id || lv_date || TO_CHAR( cn_request_id ) || cv_pdf;
    -- ===============================================
    -- SVF�R���J�����g�N��
    -- ===============================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                     -- �G���[�o�b�t�@
      , ov_retcode       => lv_retcode                    -- ���^�[���R�[�h
      , ov_errmsg        => lv_errmsg                     -- �G���[���b�Z�[�W
      , iv_conc_name     => cv_pkg_name                   -- �R���J�����g��
      , iv_file_name     => lv_file_name                  -- �o�̓t�@�C����
      , iv_file_id       => cv_file_id                    -- ���[ID
      , iv_output_mode   => cv_output_mode                -- �o�͋敪
      , iv_frm_file      => cv_frm_file                   -- �t�H�[���l���t�@�C����
      , iv_vrq_file      => cv_vrq_file                   -- �N�G���[�l���t�@�C����
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--      , iv_org_id        => TO_CHAR( gn_organization_id ) -- ORG_ID
      , iv_org_id        => gn_org_id                     -- ORG_ID
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
      , iv_user_name     => fnd_global.user_name          -- ���O�C���E���[�U��
      , iv_resp_name     => fnd_global.resp_name          -- ���O�C���E���[�U�E�Ӗ�
      , iv_doc_name      => NULL                          -- ������
      , iv_printer_name  => NULL                          -- �v�����^��
      , iv_request_id    => TO_CHAR( cn_request_id )      -- �v��ID
      , iv_nodata_msg    => NULL                          -- �f�[�^�Ȃ����b�Z�[�W
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => cn_number_0
                    );
      RAISE global_api_expt;
    END IF;
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
-- 2013/04/04 Ver.1.17 [��QE_�{�ғ�_10595,10609] SCSK K.Nakamura ADD START
  /**********************************************************************************
   * Procedure Name   : upd_resv_payment_rec
   * Description      : �x���X�e�[�^�X�u�����ρv�X�V����(A-11)
   ***********************************************************************************/
  PROCEDURE upd_resv_payment_rec(
    ov_errbuf                OUT VARCHAR2           -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2           -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20) := 'upd_resv_payment_rec';    -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver.1.22 ADD START
    lv_proc_type             VARCHAR2(1)    DEFAULT NULL;              -- �����敪
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- �̎�c���ꗗ�f�[�^
    CURSOR l_worktable_cur
    IS
      SELECT xrbb.payment_code  AS payment_code  -- �x����R�[�h
           , xrbb.cust_code     AS cust_code     -- �ڋq�R�[�h
           , xrbb.closing_date  AS closing_date  -- ���ߓ�
      FROM   xxcok_rep_bm_balance xrbb  -- �̎�c���ꗗ���[���[�N�e�[�u��
      WHERE  xrbb.request_id  =  cn_request_id
      AND    xrbb.resv_payment   IS NULL         -- �x���ۗ�
      ;
-- Ver.1.22 ADD END
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �x���X�e�[�^�X�u�����ρv�X�V����
    -- ===============================================
    -- �Ώۂ̎x���X�e�[�^�X���u�����ρv�ɍX�V����
-- Ver.1.22 MOD START
--    UPDATE xxcok_rep_bm_balance xrbb              -- �̎�c���ꗗ���[���[�N�e�[�u��
--    SET    xrbb.resv_payment    = gv_pay_rec_name -- �x���X�e�[�^�X("������")
--    WHERE  xrbb.request_id      = cn_request_id   -- �v��ID(������s��)
--    AND    xrbb.resv_payment    IS NULL           -- �x���ۗ�
---- Ver.1.18 [��QE_�{�ғ�_10595��] SCSK S.Niki MOD START
----    AND    xrbb.unpaid_balance  = 0               -- �����c��
--    AND EXISTS ( SELECT 'X'
--                 FROM   xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
--                 WHERE  xbb.supplier_code  = xrbb.payment_code  -- �x����R�[�h
--                 AND    xbb.cust_code      = xrbb.cust_code     -- �ڋq�R�[�h
--                 AND    xbb.closing_date   = xrbb.closing_date  -- ���ߓ�
--                 AND    xbb.proc_type      = cv_proc_type1_upd  -- �����敪("������")
--               )
---- Ver.1.18 [��QE_�{�ғ�_10595��] SCSK S.Niki MOD END
--    ;
    -- ���[���[�N�f�[�^�����[�v
    FOR l_worktable_rec IN l_worktable_cur LOOP
      BEGIN
        SELECT xbb.proc_type AS proc_type
        INTO   lv_proc_type
        FROM   xxcok_backmargin_balance xbb  -- �̎�c���e�[�u��
        WHERE  xbb.supplier_code  = l_worktable_rec.payment_code -- �x����R�[�h
        AND    xbb.cust_code      = l_worktable_rec.cust_code    -- �ڋq�R�[�h
        AND    xbb.closing_date   = l_worktable_rec.closing_date -- ���ߓ�
        AND    xbb.proc_type      = cv_proc_type1_upd            -- �����敪("������")
        AND    ROWNUM             = cn_number_1
        ;
        -- �Ώۂ̎x���X�e�[�^�X���u�����ρv�ɍX�V����
        UPDATE  xxcok_rep_bm_balance xrbb  -- �̎�c���ꗗ���[���[�N�e�[�u��
        SET     xrbb.resv_payment  =  gv_pay_rec_name  -- �x���X�e�[�^�X("������")
        WHERE   xrbb.request_id    =  cn_request_id    -- �v��ID(������s��)
        AND     xrbb.payment_code  =  l_worktable_rec.payment_code
        AND     xrbb.cust_code     =  l_worktable_rec.cust_code
        AND     xrbb.closing_date  =  l_worktable_rec.closing_date
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          -- ���[���[�N�e�[�u���X�V�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10535
                        , iv_token_name1  => cv_token_errmsg
                        , iv_token_value1 => SQLERRM
                        );
          RAISE global_api_expt;
      END;
    END LOOP;
-- Ver.1.22 MOD END
--
  EXCEPTION
-- Ver.1.22 ADD START
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
-- Ver.1.22 ADD END
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_resv_payment_rec;
--
-- 2013/04/04 Ver.1.17 [��QE_�{�ғ�_10595,10609] SCSK K.Nakamura ADD END
--
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD START
  /**********************************************************************************
   * Procedure Name   : upd_resv_payment
   * Description      : �x���X�e�[�^�X�u�����J�z�v�X�V����(A-10)
   ***********************************************************************************/
  PROCEDURE upd_resv_payment(
    ov_errbuf                OUT VARCHAR2           -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2           -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'upd_resv_payment';    -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_transfer_fee          NUMBER DEFAULT 0;                         -- �U���萔��
    ln_transfer_amount       NUMBER DEFAULT 0;                         -- �U�����z
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- �x���悲�Ƃ̔̎�c���ꗗ�f�[�^
    -- (�{�U�A���������Ώ�)
    CURSOR l_payment_cur
    IS
-- Ver1.23 N.Abe Mod START
--      SELECT
      SELECT /*+ leading(xrbb sub) */
-- Ver1.23 N.Abe Mod END
            xrbb.payment_code                 AS  payment_code        -- �x����R�[�h
           ,xrbb.bm_payment_code              AS  bm_payment_code     -- BM�x���敪
           ,xrbb.bank_trns_fee                AS  bank_trns_fee       -- �U���萔�����S��
-- Ver1.23 N.Abe Mod START
--           ,NVL(SUM(xrbb.unpaid_balance), 0)  AS  unpaid_balance      -- �����c��
           ,NVL(sub.expect_payment_amt_tax, 0)  AS  unpaid_balance    -- �����c��
-- Ver1.23 N.Abe Mod END
      FROM
            xxcok_rep_bm_balance    xrbb  -- �̎�c���ꗗ���[���[�N�e�[�u��
-- Ver1.23 N.Abe Add START
           ,(SELECT xbb.supplier_code                       AS supplier_code                -- �d����R�[�h
                   ,NVL(SUM(xbb.expect_payment_amt_tax), 0) AS expect_payment_amt_tax       -- �x���\��z�i�ō��j
             FROM   xxcok_backmargin_balance xbb     -- �̎�c���e�[�u��
             WHERE  xbb.expect_payment_date <= gd_payment_date
             GROUP BY xbb.supplier_code
             HAVING SUM(NVL(xbb.expect_payment_amt_tax, 0))  >  0  -- ���������Ώ�
            ) sub
-- Ver1.23 N.Abe Add END
      WHERE
            xrbb.request_id           =  cn_request_id                              -- �v��ID(������s��)
      AND   xrbb.bm_payment_code     IN  (cv_bm_payment_type1, cv_bm_payment_type2) -- BM�x���敪(�{�U)
-- Ver1.23 N.Abe Add START
      AND   xrbb.payment_code         =  sub.supplier_code
-- Ver1.23 N.Abe Add END
      GROUP BY
            -- �x���悲��
            xrbb.payment_code                       -- �x����R�[�h
           ,xrbb.bm_payment_code                    -- BM�x���敪
           ,xrbb.bank_trns_fee                      -- �U���萔��(���S��)
-- Ver1.23 N.Abe Del START
           ,NVL(sub.expect_payment_amt_tax, 0)
--      HAVING
--            NVL(SUM(xrbb.unpaid_balance), 0)  >  0  -- ���������Ώ�
-- Ver1.23 N.Abe Del END
      ORDER BY
            xrbb.payment_code                       -- �x����R�[�h
    ;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �x���X�e�[�^�X�u�����J�z�v�X�V����
    -- ===============================================
    -- �x���悲�Ƃ̔̎�c���ꗗ�f�[�^�����[�v
    FOR l_payment_rec IN l_payment_cur LOOP
      --
      -- �U���萔���̎Z�o
      ln_transfer_fee := CASE WHEN ( l_payment_rec.unpaid_balance >= gn_trans_fee )
                           -- �����c������z�ȏ�̏ꍇ
                           THEN gn_more_fee * ( 1 + gn_bm_tax / 100 ) -- ��s�萔��(��ȏ�)�̐ō��z
                           -- �����c������z�����̏ꍇ
                           ELSE gn_less_fee * ( 1 + gn_bm_tax / 100 ) -- ��s�萔��(�����)�̐ō��z
                         END;
      --
      -- �U�����z�̎Z�o
      ln_transfer_amount := CASE WHEN ( l_payment_rec.bank_trns_fee = gv_bk_trns_fee_we )
                              -- �U���萔�����S�ҁ������̏ꍇ
                              THEN l_payment_rec.unpaid_balance                    -- �����c��
                              -- �U���萔�����S�ҁ������̏ꍇ
                              ELSE l_payment_rec.unpaid_balance - ln_transfer_fee  -- �����c���|�U���萔��
                            END;
      --
      -- �U�����z��0�~�ȉ��ɂȂ�ꍇ
      IF ( ln_transfer_amount <= 0 ) THEN
        --
        -- �Ώۂ̎x����̎x���X�e�[�^�X���u�����J�z�v�ɍX�V����
        UPDATE  xxcok_rep_bm_balance                        -- �̎�c���ꗗ���[���[�N�e�[�u��
        SET     resv_payment  =  gv_pay_auto_res_name       -- �x���X�e�[�^�X("�����J�z")
        WHERE   request_id    =  cn_request_id              -- �v��ID(������s��)
        AND     payment_code  =  l_payment_rec.payment_code -- �Ώۂ̎x����R�[�h
        ;
      END IF;
      --
    END LOOP;
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
  END upd_resv_payment;
--
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD END
  /**********************************************************************************
   * Procedure Name   : ins_worktable_data
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_worktable_data(
    ov_errbuf                OUT VARCHAR2           -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2           -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_index                 IN  NUMBER  DEFAULT 1  -- �C���f�b�N�X
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'ins_worktable_data';    -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�o�^
    -- ===============================================
    INSERT INTO xxcok_rep_bm_balance(
      p_payment_date                  -- �x����(���̓p�����[�^)
    , p_ref_base_code                 -- �⍇���S�����_(���̓p�����[�^)
    , p_selling_base_code             -- ����v�㋒�_(���̓p�����[�^)
    , p_target_disp                   -- �\���Ώ�(���̓p�����[�^)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , p_payment_code                  -- �x����R�[�h(���̓p�����[�^)
    , p_resv_payment                  -- �x���X�e�[�^�X(���̓p�����[�^)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    , h_warnning_mark                 -- �x���}�[�N(�w�b�_�o��)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , h_unpaid_elec_mark              -- �ϓ��d�C�㖢���}�[�N(�w�b�_�o��)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    , payment_code                    -- �x����R�[�h
    , payment_name                    -- �x���於
    , bank_no                         -- ��s�ԍ�
    , bank_name                       -- ��s��
    , bank_branch_no                  -- ��s�x�X�ԍ�
    , bank_branch_name                -- ��s�x�X��
    , bank_acct_type                  -- �������
    , bank_acct_type_name             -- ������ʖ�
    , bank_acct_no                    -- �����ԍ�
    , bank_acct_name                  -- ��s������
    , ref_base_code                   -- �⍇���S�����_�R�[�h
    , ref_base_name                   -- �⍇���S�����_��
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD START
    , bm_payment_code                 -- BM�x���敪(�R�[�h�l)
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD END
    , bm_payment_type                 -- BM�x���敪
    , bank_trns_fee                   -- �U���萔��
    , payment_stop                    -- �x����~
    , selling_base_code               -- ����v�㋒�_�R�[�h
    , selling_base_name               -- ����v�㋒�_��
    , warnning_mark                   -- �x���}�[�N
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , unpaid_elec_mark                -- �ϓ��d�C�㖢���}�[�N
    , err_flag                        -- �G���[�t���O
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD START
    , err_type_sort                   -- �G���[��ʕ��я�
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD END
    , cust_code                       -- �ڋq�R�[�h
    , cust_name                       -- �ڋq��
    , bm_this_month                   -- ����BM
    , electric_amt                    -- �d�C��
    , unpaid_last_month               -- �O���܂ł̖���
    , unpaid_balance                  -- �����c��
    , resv_payment                    -- �x���ۗ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , resv_payment_sort               -- �x���X�e�[�^�X���я�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    , payment_date                    -- �x����
    , closing_date                    -- ���ߓ�
    , selling_base_section_code       -- �n��R�[�h�i����v�㋒�_�j
-- Ver.1.24 ADD START
    , bm_tax_kbn_name                 -- BM�ŋ敪��
-- Ver.1.24 ADD END
    , no_data_message                 -- 0�����b�Z�[�W
    , created_by                      -- �쐬��
    , creation_date                   -- �쐬��
    , last_updated_by                 -- �ŏI�X�V��
    , last_update_date                -- �ŏI�X�V��
    , last_update_login               -- �ŏI�X�V���O�C��
    , request_id                      -- �v��ID
    , program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                      -- �R���J�����g�E�v���O����ID
    , program_update_date             -- �v���O�����X�V��
    ) VALUES (
      TO_CHAR( gd_payment_date ,cv_format_yyyymmdd )         -- �x����(���̓p�����[�^)
    , gv_ref_base_code                                       -- �⍇���S�����_(���̓p�����[�^)
    , gv_selling_base_code                                   -- ����v�㋒�_(���̓p�����[�^)
    , gv_target_disp_nm                                      -- �\���Ώ�(���̓p�����[�^)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , gt_payment_code                                        -- �x����R�[�h(���̓p�����[�^)
    , gv_resv_payment_nm                                     -- �x���X�e�[�^�X(���̓p�����[�^)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    , gv_error_mark                                          -- �x���}�[�N(�w�b�_�o��)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , gv_unpaid_elec_mark                                    -- �ϓ��d�C�㖢���}�[�N(�w�b�_�o��)
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    , g_bm_balance_ttype(in_index).PAYMENT_CODE              -- �x����R�[�h
    , g_bm_balance_ttype(in_index).PAYMENT_NAME              -- �x���於
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD START
--    , g_bm_balance_ttype(in_index).BANK_NO                   -- ��s�ԍ�
    , SUBSTRB( g_bm_balance_ttype(in_index).BANK_NO , 1 , 4 )-- ��s�ԍ�
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD END
    , g_bm_balance_ttype(in_index).BANK_NAME                 -- ��s��
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD START
--    , g_bm_balance_ttype(in_index).BANK_BRANCH_NO            -- ��s�x�X�ԍ�
    , SUBSTRB( g_bm_balance_ttype(in_index).BANK_BRANCH_NO , 1 , 4 ) -- ��s�x�X�ԍ�
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama UPD END
    , g_bm_balance_ttype(in_index).BANK_BRANCH_NAME          -- ��s�x�X��
    , g_bm_balance_ttype(in_index).BANK_ACCT_TYPE            -- �������
    , g_bm_balance_ttype(in_index).BANK_ACCT_TYPE_NAME       -- ������ʖ�
    , g_bm_balance_ttype(in_index).BANK_ACCT_NO              -- �����ԍ�
    , g_bm_balance_ttype(in_index).BANK_ACCT_NAME            -- ��s������
    , g_bm_balance_ttype(in_index).REF_BASE_CODE             -- �⍇���S�����_�R�[�h
    , g_bm_balance_ttype(in_index).REF_BASE_NAME             -- �⍇���S�����_��
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD START
    , g_bm_balance_ttype(in_index).BM_PAYMENT_CODE           -- BM�x���敪(�R�[�h�l)
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD END
    , g_bm_balance_ttype(in_index).BM_PAYMENT_TYPE           -- BM�x���敪
    , g_bm_balance_ttype(in_index).BANK_TRNS_FEE             -- �U���萔��
    , g_bm_balance_ttype(in_index).PAYMENT_STOP              -- �x����~
    , g_bm_balance_ttype(in_index).SELLING_BASE_CODE         -- ����v�㋒�_�R�[�h
    , g_bm_balance_ttype(in_index).SELLING_BASE_NAME         -- ����v�㋒�_��
    , g_bm_balance_ttype(in_index).WARNNING_MARK             -- �x���}�[�N
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , NULL                                                   -- �ϓ��d�C�㖢���}�[�N
    , NULL                                                   -- �G���[�t���O
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD START
    , NULL                                                   -- �G���[��ʕ��я�
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD END
    , g_bm_balance_ttype(in_index).CUST_CODE                 -- �ڋq�R�[�h
    , g_bm_balance_ttype(in_index).CUST_NAME                 -- �ڋq��
    , g_bm_balance_ttype(in_index).BM_THIS_MONTH             -- ����BM
    , g_bm_balance_ttype(in_index).ELECTRIC_AMT              -- �d�C��
    , g_bm_balance_ttype(in_index).UNPAID_LAST_MONTH         -- �O���܂ł̖���
    , g_bm_balance_ttype(in_index).UNPAID_BALANCE            -- �����c��
    , g_bm_balance_ttype(in_index).RESV_PAYMENT              -- �x���ۗ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , NULL                                                   -- �x���X�e�[�^�X���я�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    , g_bm_balance_ttype(in_index).PAYMENT_DATE              -- �x����
    , g_bm_balance_ttype(in_index).CLOSING_DATE              -- ���ߓ�
    , g_bm_balance_ttype(in_index).SELLING_BASE_SECTION_CODE -- �n��R�[�h�i����v�㋒�_�j
-- Ver.1.24 ADD START
    , g_bm_balance_ttype(in_index).BM_TAX_KBN_NAME           -- BM�ŋ敪��
-- Ver.1.24 ADD END
    , gv_no_data_msg                                         -- 0�����b�Z�[�W
    , cn_created_by                                          -- created_by
    , SYSDATE                                                -- creation_date
    , cn_last_updated_by                                     -- last_updated_by
    , SYSDATE                                                -- last_update_date
    , cn_last_update_login                                   -- last_update_login
    , cn_request_id                                          -- request_id
    , cn_program_application_id                              -- program_application_id
    , cn_program_id                                          -- program_id
    , SYSDATE                                                -- program_update_date
    );
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
  END ins_worktable_data;
--
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
--
  /**********************************************************************************
   * Procedure Name   : upd_worktable_data
   * Description      : ���[�N�e�[�u���f�[�^�X�V����(A-12)
   ***********************************************************************************/
  PROCEDURE upd_worktable_data(
    ov_errbuf                OUT VARCHAR2           -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2           -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(18) := 'upd_worktable_data';    -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode               BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    lv_electricity_type      VARCHAR2(1)    DEFAULT NULL;              -- �d�C��敪
    lv_err_flag              VARCHAR2(1)    DEFAULT NULL;              -- �G���[�t���O
    ln_worktable_cnt         NUMBER         DEFAULT 0;                 -- ���[�N�e�[�u������
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- �̎�c���ꗗ�f�[�^
    CURSOR l_worktable_cur
    IS
      SELECT  xrbb.payment_code            AS  payment_code       -- �x����R�[�h
            , xrbb.cust_code               AS  cust_code          -- �ڋq�R�[�h
            , xrbb.warnning_mark           AS  warnning_mark      -- �x���}�[�N
            , xrbb.electric_amt            AS  electric_amt       -- �d�C��
            , xrbb.resv_payment            AS  resv_payment       -- �x���X�e�[�^�X
      FROM    xxcok_rep_bm_balance  xrbb
      WHERE   xrbb.request_id  = cn_request_id
      ;
-- Ver.1.19 [��QE_�{�ғ�_10411��] SCSK S.Niki ADD START
    -- �x���X�e�[�^�X�L��f�[�^
    CURSOR l_resv_payment_cur
    IS
      SELECT  xrbb.payment_code              AS  payment_code       -- �x����R�[�h
            , MIN( xrbb.resv_payment_sort )  AS  resv_payment_sort  -- �x���X�e�[�^�X���я�
      FROM    xxcok_rep_bm_balance  xrbb
      WHERE   xrbb.request_id    = cn_request_id
      AND     xrbb.resv_payment  IS NOT NULL
      AND     xrbb.err_flag      IS NULL
      GROUP BY xrbb.payment_code
      ;
-- Ver.1.19 [��QE_�{�ғ�_10411��] SCSK S.Niki ADD END
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD START
    -- �G���[�L��f�[�^
    CURSOR l_err_cur
    IS
      -- �ϓ��d�C�㖢���f�[�^
      SELECT  DISTINCT
              xrbb1.payment_code             AS  payment_code       -- �x����R�[�h
            , xrbb1.unpaid_elec_mark         AS  err_type           -- �G���[���
            , TO_NUMBER( ffv.attribute1 )    AS  err_type_sort      -- �G���[��ʕ��я�
      FROM    xxcok_rep_bm_balance  xrbb1
            , fnd_flex_values       ffv
            , fnd_flex_values_tl    ffvt
            , fnd_flex_value_sets   ffvs
      WHERE   xrbb1.request_id         = cn_request_id
      AND     xrbb1.unpaid_elec_mark   IS NOT NULL
      AND     xrbb1.unpaid_elec_mark   = ffvt.description
      AND     ffv.flex_value_id        = ffvt.flex_value_id
      AND     ffvt.language            = cv_ja
      AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND     ffvs.flex_value_set_name = cv_set_name_et
      UNION ALL
      -- �ϓ��d�C�����ȊO���̎�����G���[�f�[�^
      SELECT  DISTINCT
              xrbb2.payment_code             AS  payment_code       -- �x����R�[�h
            , xrbb2.warnning_mark            AS  err_type           -- �G���[���
            , TO_NUMBER( ffv.attribute1 )    AS  err_type_sort      -- �G���[��ʕ��я�
      FROM    xxcok_rep_bm_balance  xrbb2
            , fnd_flex_values       ffv
            , fnd_flex_values_tl    ffvt
            , fnd_flex_value_sets   ffvs
      WHERE   xrbb2.request_id         = cn_request_id
      AND     xrbb2.warnning_mark      IS NOT NULL
      AND     xrbb2.warnning_mark      = ffvt.description
      AND     ffv.flex_value_id        = ffvt.flex_value_id
      AND     ffvt.language            = cv_ja
      AND     ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND     ffvs.flex_value_set_name = cv_set_name_et
      AND NOT EXISTS ( SELECT 'X'
                       FROM   xxcok_rep_bm_balance  xrbb3
                       WHERE  xrbb3.request_id       = cn_request_id
                       AND    xrbb3.payment_code     = xrbb2.payment_code
                       AND    xrbb3.unpaid_elec_mark IS NOT NULL
                     )
      ;
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD END
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 1. �ϓ��d�C�㖢���t���O�X�V
    -- ===============================================
    -- �̎�c���ꗗ�f�[�^�����[�v
    FOR l_worktable_rec IN l_worktable_cur LOOP
      --
      ----------------------------
      -- �d�C��敪�擾
      ----------------------------
      -- �ŐV�̊m��ς݌_��ɕR�t��SP�ꌈ�����擾
      BEGIN
        SELECT xsdh.electricity_type   AS electricity_type   -- �d�C��敪
        INTO   lv_electricity_type
        FROM   xxcso_sp_decision_headers   xsdh       -- SP�ꌈ�w�b�_
             , xxcso_contract_managements  xcm1       -- �_��Ǘ��e�[�u��
        WHERE  xsdh.sp_decision_header_id  = xcm1.sp_decision_header_id
        AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                               FROM   xxcso_contract_managements xcm2   -- �_��Ǘ��e�[�u��
                                               WHERE  xcm2.install_account_id = xcm1.install_account_id
                                               AND    xcm2.status             = ct_status_comp     -- �m���
                                               AND    xcm2.cooperate_flag     = ct_cooperate_comp  -- �}�X�^�A�g��
                                             )
        AND    xcm1.install_account_number = l_worktable_rec.cust_code    -- �Ώۂ̌ڋq�R�[�h
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �_���񂪎擾�ł��Ȃ��ꍇ�A�u0�F�d�C��Ȃ��v��ԋp
          lv_electricity_type := ct_electricity_type0;
      END;
      --
      ----------------------------
      -- �ϓ��d�C�㖢���}�[�N�X�V
      ----------------------------
      -- �ϓ��d�C��Ώیڋq���ABM1�x����R�[�h���A�d�C�オ0�~�̏ꍇ
      IF ( lv_electricity_type = ct_electricity_type2 )
        AND ( l_worktable_rec.electric_amt = 0 ) THEN
        --
        BEGIN
          -- �ϓ��d�C�㖢���}�[�N���X�V����
          UPDATE  xxcok_rep_bm_balance  xrbb
          SET     xrbb.unpaid_elec_mark = gv_unpaid_elec_mark          -- �ϓ��d�C�㖢���}�[�N
          WHERE   xrbb.request_id       = cn_request_id
          AND     xrbb.payment_code     = l_worktable_rec.payment_code -- �Ώۂ̎x����R�[�h
          AND     xrbb.cust_code        = l_worktable_rec.cust_code    -- �Ώۂ̌ڋq�R�[�h
          AND     EXISTS  ( SELECT 'X'
                            FROM   xxcmm_cust_accounts xca
                            WHERE  xca.contractor_supplier_code = xrbb.payment_code
                            AND    xca.customer_code            = xrbb.cust_code
                          )
          ;
        --
        EXCEPTION
          WHEN OTHERS THEN
            -- ���[���[�N�e�[�u���X�V�G���[
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_xxcok_appl_short_name
                          , iv_name         => cv_msg_code_10535
                          , iv_token_name1  => cv_token_errmsg
                          , iv_token_value1 => SQLERRM
                          );
            RAISE global_process_expt;
        END;
      END IF;
      --
    END LOOP;
    --
    -- ===============================================
    -- 2-1. �G���[�t���O�X�V(�x����P��)
    -- ===============================================
    -- �̎�����G���[�܂��͕ϓ��d�C�㖢���̏ꍇ�A�x����P�ʂɃG���[�t���O�X�V
    BEGIN
      UPDATE  xxcok_rep_bm_balance  xrbb1
      SET     xrbb1.err_flag    = cv_flag_y
      WHERE   xrbb1.request_id  = cn_request_id
      AND     EXISTS ( SELECT 'X'
                       FROM   xxcok_rep_bm_balance  xrbb2
                       WHERE  xrbb1.payment_code = xrbb2.payment_code
-- Ver.1.20 [��QE_�{�ғ�_10411��] SCSK S.Niki ADD START
                       AND    xrbb2.request_id   = cn_request_id
-- Ver.1.20 [��QE_�{�ғ�_10411��] SCSK S.Niki ADD END
                       AND  ( ( xrbb2.warnning_mark    IS NOT NULL )   -- �x���}�[�N
                         OR   ( xrbb2.unpaid_elec_mark IS NOT NULL ) ) -- �ϓ��d�C�㖢���}�[�N
                     )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- ���[���[�N�e�[�u���X�V�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10535
                      , iv_token_name1  => cv_token_errmsg
                      , iv_token_value1 => SQLERRM
                      );
        RAISE global_process_expt;
    END;
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD START
    --
    -- ===============================================
    -- 2-2. �G���[��ʕ��я��X�V
    -- ===============================================
    -- �G���[�L��f�[�^�����[�v
    FOR l_err_rec IN l_err_cur LOOP
      BEGIN
        -- �G���[��ʕ��я����X�V����
        UPDATE  xxcok_rep_bm_balance  xrbb
        SET     xrbb.err_type_sort  = l_err_rec.err_type_sort
        WHERE   xrbb.request_id     = cn_request_id
        AND     xrbb.payment_code   = l_err_rec.payment_code           -- �Ώۂ̎x����R�[�h
        ;
      --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���[���[�N�e�[�u���X�V�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10535
                        , iv_token_name1  => cv_token_errmsg
                        , iv_token_value1 => SQLERRM
                        );
          RAISE global_process_expt;
      END;
      --
    END LOOP;
-- Ver.1.21 [��QE_�{�ғ�_10819] SCSK S.Niki ADD END
    --
    -- ===============================================
    -- 3-1. �x���X�e�[�^�X���я��X�V
    -- ===============================================
    -- �x���X�e�[�^�X���̂���A�l�Z�b�gDFF1�́u�x���X�e�[�^�X���я��v��ݒ�
    BEGIN
      UPDATE  xxcok_rep_bm_balance   xrbb
      SET     xrbb.resv_payment_sort = ( SELECT TO_NUMBER( ffv.attribute1 )  -- �x���X�e�[�^�X���я�
                                         FROM   fnd_flex_values       ffv
                                              , fnd_flex_values_tl    ffvt
                                              , fnd_flex_value_sets   ffvs
                                         WHERE  xrbb.resv_payment        = ffvt.description
                                         AND    ffv.flex_value_id        = ffvt.flex_value_id
                                         AND    ffvt.language            = cv_ja
                                         AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
                                         AND    ffvs.flex_value_set_name = cv_set_name_rp         -- �x���X�e�[�^�X
                                       )
      WHERE   xrbb.request_id        = cn_request_id
      AND     xrbb.err_flag         IS NULL
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- ���[���[�N�e�[�u���X�V�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10535
                      , iv_token_name1  => cv_token_errmsg
                      , iv_token_value1 => SQLERRM
                      );
        RAISE global_process_expt;
    END;
-- Ver.1.19 [��QE_�{�ғ�_10411��] SCSK S.Niki ADD START
    --
    -- ===============================================
    -- 3-2. �x���X�e�[�^�X���я��X�V
    -- ===============================================
    -- �x���X�e�[�^�X�L��f�[�^�����[�v
    FOR l_resv_payment_rec IN l_resv_payment_cur LOOP
      BEGIN
        -- �x���X�e�[�^�X���я����X�V����
        UPDATE  xxcok_rep_bm_balance  xrbb
        SET     xrbb.resv_payment_sort = l_resv_payment_rec.resv_payment_sort  -- �x���X�e�[�^�X���я�
        WHERE   xrbb.request_id        = cn_request_id
        AND     xrbb.payment_code      = l_resv_payment_rec.payment_code       -- �Ώۂ̎x����R�[�h
        ;
      --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���[���[�N�e�[�u���X�V�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10535
                        , iv_token_name1  => cv_token_errmsg
                        , iv_token_value1 => SQLERRM
                        );
          RAISE global_process_expt;
      END;
      --
    END LOOP;
-- Ver.1.19 [��QE_�{�ғ�_10411��] SCSK S.Niki ADD END
    --
    -- ===============================================
    -- 4. �s�v�f�[�^�폜
    -- ===============================================
    IF ( gv_resv_payment_nm IS NOT NULL ) THEN
      BEGIN
        -- �p�����[�^�F�x���X�e�[�^�X�ɍ��v���Ȃ����R�[�h���폜
        DELETE
        FROM   xxcok_rep_bm_balance  xrbb
        WHERE  NVL( xrbb.resv_payment ,'X' ) <> gv_resv_payment_nm  -- �p�����[�^�F�x���X�e�[�^�X
        AND    xrbb.request_id                = cn_request_id
        ;
      --
      EXCEPTION
        WHEN OTHERS THEN
          -- ���[���[�N�e�[�u���폜�G���[
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10536
                        , iv_token_name1  => cv_token_errmsg
                        , iv_token_value1 => SQLERRM
                        );
          RAISE global_process_expt;
      END;
    END IF;
    --
-- Ver.1.22 ADD START
    -- ===============================================
    -- 5. �d������擾���s���R�[�h�폜
    -- ===============================================
    BEGIN
      -- �d������̎擾�Ɏ��s�������R�[�h���폜
      DELETE
      FROM   xxcok_rep_bm_balance  xrbb
      WHERE  xrbb.payment_name IS NULL
      AND    xrbb.request_id   = cn_request_id
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- ���[���[�N�e�[�u���폜�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10536
                      , iv_token_name1  => cv_token_errmsg
                      , iv_token_value1 => SQLERRM
                      );
        RAISE global_process_expt;
    END;
-- Ver.1.22 ADD END
    -- ===============================================
    -- 6. 0���f�[�^�o�^
    -- ===============================================
    -- ���[���[�N�̌������J�E���g
    SELECT COUNT(*)
    INTO   ln_worktable_cnt
    FROM   xxcok_rep_bm_balance   xrbb
    WHERE  xrbb.request_id      = cn_request_id
    ;
-- Ver.1.22 ADD START
    gn_target_cnt       := ln_worktable_cnt;
-- Ver.1.22 ADD END
    -- ���[���[�N������0���̏ꍇ�A0���f�[�^��o�^
    IF ln_worktable_cnt = 0 THEN
      -- �Ώۃf�[�^�Ȃ�
      gn_target_cnt     := 0;
      gn_index          := 1;
      -- ���ڂ̃N���A
      g_bm_balance_ttype( gn_index ).PAYMENT_CODE                := NULL;  -- �x����R�[�h
      g_bm_balance_ttype( gn_index ).PAYMENT_NAME                := NULL;  -- �x���於
      g_bm_balance_ttype( gn_index ).BANK_NO                     := NULL;  -- ��s�ԍ�
      g_bm_balance_ttype( gn_index ).BANK_NAME                   := NULL;  -- ��s��
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO              := NULL;  -- ��s�x�X�ԍ�
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NAME            := NULL;  -- ��s�x�X��
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE              := NULL;  -- �������
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE_NAME         := NULL;  -- ������ʖ�
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NO                := NULL;  -- �����ԍ�
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME              := NULL;  -- ��s������
      g_bm_balance_ttype( gn_index ).REF_BASE_CODE               := NULL;  -- �⍇���S�����_�R�[�h
      g_bm_balance_ttype( gn_index ).REF_BASE_NAME               := NULL;  -- �⍇���S�����_��
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_CODE             := NULL;  -- BM�x���敪(�R�[�h�l)
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_TYPE             := NULL;  -- BM�x���敪
      g_bm_balance_ttype( gn_index ).BANK_TRNS_FEE               := NULL;  -- �U���萔��
      g_bm_balance_ttype( gn_index ).PAYMENT_STOP                := NULL;  -- �x����~
      g_bm_balance_ttype( gn_index ).SELLING_BASE_CODE           := NULL;  -- ����v�㋒�_�R�[�h
      g_bm_balance_ttype( gn_index ).SELLING_BASE_NAME           := NULL;  -- ����v�㋒�_��
      g_bm_balance_ttype( gn_index ).WARNNING_MARK               := NULL;  -- �x���}�[�N
      g_bm_balance_ttype( gn_index ).CUST_CODE                   := NULL;  -- �ڋq�R�[�h
      g_bm_balance_ttype( gn_index ).CUST_NAME                   := NULL;  -- �ڋq��
      g_bm_balance_ttype( gn_index ).BM_THIS_MONTH               := NULL;  -- ����BM
      g_bm_balance_ttype( gn_index ).ELECTRIC_AMT                := NULL;  -- �d�C��
      g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH           := NULL;  -- �O���܂ł̖���
      g_bm_balance_ttype( gn_index ).UNPAID_BALANCE              := NULL;  -- �����c��
      g_bm_balance_ttype( gn_index ).RESV_PAYMENT                := NULL;  -- �x���ۗ�
      g_bm_balance_ttype( gn_index ).PAYMENT_DATE                := NULL;  -- �x����
      g_bm_balance_ttype( gn_index ).CLOSING_DATE                := NULL;  -- ���ߓ�
      g_bm_balance_ttype( gn_index ).SELLING_BASE_SECTION_CODE   := NULL;  -- �n��R�[�h
-- Ver.1.24 ADD START
      g_bm_balance_ttype( gn_index ).BM_TAX_KBN_NAME             := NULL;  -- BM�ŋ敪��
-- Ver.1.24 ADD END
--
      -- ===============================================
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      -- ===============================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�o�^(A-7)
      -- ===============================================
      ins_worktable_data(
          ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
        , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
        , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        -- ���[���[�N�e�[�u���o�^�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10537
                      , iv_token_name1  => cv_token_errmsg
                      , iv_token_value1 => lv_errbuf
                      );
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END upd_worktable_data;
--
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
--
  /**********************************************************************************
   * Procedure Name   : break_judge
   * Description      : �u���C�N���菈��(A-6)
   ***********************************************************************************/
  PROCEDURE break_judge(
    ov_errbuf                  OUT VARCHAR2             -- �G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2             -- ���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_last_record_flg         IN  VARCHAR2                                          DEFAULT NULL -- �ŏI���R�[�h�t���O
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD START
--  , i_target_rec               IN  g_target_cur%ROWTYPE                              DEFAULT NULL -- �J�[�\�����R�[�h
  , i_target_rec               IN  g_target_rtype                                    DEFAULT NULL -- �J�[�\�����R�[�h
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD END
  , it_bank_charge_bearer      IN  po_vendors.bank_charge_bearer%TYPE                DEFAULT NULL -- ��s�萔�����S��
  , it_hold_all_payments_flag  IN  po_vendors.hold_all_payments_flag%TYPE            DEFAULT NULL -- �S�x���ۗ̕��t���O
  , it_vendor_name             IN  po_vendors.vendor_name%TYPE                       DEFAULT NULL -- �d���於
  , it_bank_number             IN  ap_bank_branches.bank_number%TYPE                 DEFAULT NULL -- ��s�ԍ�
  , it_bank_name               IN  ap_bank_branches.bank_name%TYPE                   DEFAULT NULL -- ��s������
  , it_bank_num                IN  ap_bank_branches.bank_num%TYPE                    DEFAULT NULL -- ��s�x�X�ԍ�
  , it_bank_branch_name        IN  ap_bank_branches.bank_branch_name%TYPE            DEFAULT NULL -- ��s�x�X��
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--  , it_bank_account_type       IN  ap_bank_accounts_all.bank_account_type%TYPE       DEFAULT NULL -- �������
  , iv_bank_account_type       IN  VARCHAR2                                          DEFAULT NULL -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
  , iv_bk_account_type_nm      IN  VARCHAR2                                          DEFAULT NULL -- ������ʖ�
  , it_bank_account_num        IN  ap_bank_accounts_all.bank_account_num%TYPE        DEFAULT NULL -- ��s�����ԍ�
  , it_account_holder_name_alt IN  ap_bank_accounts_all.account_holder_name_alt%TYPE DEFAULT NULL -- �������`�l�J�i
  , iv_ref_base_code           IN  VARCHAR2                                          DEFAULT NULL -- �⍇���S�����_����
  , it_selling_base_name       IN  hz_cust_accounts.account_name%TYPE                DEFAULT NULL -- ����v�㋒�_��
  , iv_bm_kbn                  IN  VARCHAR2                                          DEFAULT NULL -- BM�x���敪
  , iv_bm_kbn_nm               IN  VARCHAR2                                          DEFAULT NULL -- BM�x���敪��
  , it_selling_base_code       IN  hz_cust_accounts.account_number%TYPE              DEFAULT NULL -- ����v�㋒�_�R�[�h
  , it_ref_base_name           IN  hz_cust_accounts.account_name%TYPE                DEFAULT NULL -- �⍇���S�����_��
  , it_account_number          IN  hz_cust_accounts.account_number%TYPE              DEFAULT NULL -- �ڋq�R�[�h
  , it_party_name              IN  hz_parties.party_name%TYPE                        DEFAULT NULL -- �ڋq��
  , it_address3                IN  hz_locations.address3%TYPE                        DEFAULT NULL -- �n��R�[�h
  , in_error_count             IN  NUMBER                                            DEFAULT 0    -- �̎�G���[����
-- Ver.1.24 ADD START
  , iv_bm_tax_kbn_name         IN  VARCHAR2                                          DEFAULT NULL -- BM�ŋ敪��
-- Ver.1.24 ADD END
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(11) := 'break_judge';     -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode               VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    cv_bm_payment_type3      CONSTANT VARCHAR2(1)  := '3'; -- BM�x���敪(3�FAP�x��)
    cv_bm_payment_type4      CONSTANT VARCHAR2(1)  := '4'; -- BM�x���敪(4�F�����x��)
    cv_bk_trns_fee_cd        CONSTANT VARCHAR2(1)  := 'I'; -- ��s�萔�����S��(����)
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �u���C�N���菈��(A-6)
    -- ===============================================
--
    IF ( gt_payment_code_bk      <> i_target_rec.supplier_code )
      OR ( gt_selling_base_code_bk <> i_target_rec.base_code )
      OR ( gt_cust_code_bk         <> i_target_rec.cust_code )
      OR ( iv_last_record_flg = cv_flag_y ) THEN
      -- �W�v�����O���܂ł̖����A����ѓ���BM�A�d�C����0�~�ȉ��̏ꍇ�͍쐬���Ȃ�
-- 2009/05/20 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--      IF ( gt_unpaid_last_month_sum <= 0 )
--        AND ( gt_bm_this_month_sum  <= 0 )
--        AND ( gt_electric_amt_sum   <= 0 )
      IF ( gt_unpaid_last_month_sum = 0 )
        AND ( gt_bm_this_month_sum  = 0 )
        AND ( gt_electric_amt_sum   = 0 )
-- 2009/05/20 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
        AND ( gn_index > 0 ) THEN
        -------------------------
        -- �ޔ��E�W�v���ڂ̏�����
        -------------------------
        gt_payment_code_bk        := NULL;
        gt_payment_name_bk        := NULL;
        gt_bank_no_bk             := NULL;
        gt_bank_name_bk           := NULL;
        gt_bank_branch_no_bk      := NULL;
        gt_bank_branch_name_bk    := NULL;
        gt_bank_acct_type_bk      := NULL;
        gt_bank_acct_type_name_bk := NULL;
        gt_bank_acct_no_bk        := NULL;
        gt_bank_acct_name_bk      := NULL;
        gt_bm_type_bk             := NULL;
        gt_bm_payment_type_bk     := NULL;
        gt_bank_trns_fee_bk       := NULL;
        gt_payment_stop_bk        := NULL;
        gt_selling_base_code_bk   := NULL;
        gt_selling_base_name_bk   := NULL;
        gt_warnning_mark_bk       := NULL;
        gt_cust_code_bk           := NULL;
        gt_cust_name_bk           := NULL;
        gt_unpaid_last_month_sum  := 0;
        gt_bm_this_month_sum      := 0;
        gt_electric_amt_sum       := 0;
        gt_unpaid_balance_sum     := 0;
        gt_resv_payment_bk        := NULL;
        gt_payment_date_bk        := NULL;
        gt_closing_date_bk        := NULL;
        gt_section_code_bk        := NULL;
-- Ver.1.24 ADD START
        gt_bm_tax_kbn_name_bk     := NULL;
-- Ver.1.24 ADD END
      ELSE
-- 2009/05/20 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
        IF ( gt_unpaid_last_month_sum <> 0 )
          OR ( gt_bm_this_month_sum  <> 0 )
          OR ( gt_electric_amt_sum   <> 0 ) THEN
-- 2009/05/20 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
          -- �C���f�b�N�X�̔���
          gn_index := gn_index + 1;
          ----------------
          -- PL/SQL�\�i�[
          ----------------
-- 2009/04/23 Ver.1.5 [��QT1_0684] SCS T.Taniguchi START
        -- BM�x���敪���A�⍇���S�����_�ɐݒ肷��l�𔻒肷��
--        IF ( gt_bm_type_bk IN ( cv_bm_payment_type3 ,cv_bm_payment_type4 ) ) THEN
--          g_bm_balance_ttype( gn_index ).REF_BASE_CODE := gt_selling_base_code_bk; -- �⍇���S�����_�R�[�h
--          g_bm_balance_ttype( gn_index ).REF_BASE_NAME := gt_selling_base_name_bk; -- �⍇���S�����_��
--        ELSE
          g_bm_balance_ttype( gn_index ).REF_BASE_CODE             := gt_ref_base_code_bk;       -- �⍇���S�����_�R�[�h
          g_bm_balance_ttype( gn_index ).REF_BASE_NAME             := gt_ref_base_name_bk;       -- �⍇���S�����_��
--        END IF;
-- 2009/04/23 Ver.1.5 [��QT1_0684] SCS T.Taniguchi END
--
          g_bm_balance_ttype( gn_index ).PAYMENT_CODE              := gt_payment_code_bk;        -- �x����R�[�h
          g_bm_balance_ttype( gn_index ).PAYMENT_NAME              := gt_payment_name_bk;        -- �x���於
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD START
        IF ( gt_bm_type_bk = cv_bm_payment_type4 ) THEN
          -- BM�x���敪�u4�F�����x���v�̏ꍇ�A�Œ蕶����ݒ肷��
          g_bm_balance_ttype( gn_index ).BANK_NO                   := cv_em_dash;                -- ��s�ԍ�
          g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO            := cv_em_dash;                -- ��s�x�X�ԍ�
          g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE            := cv_em_dash;                -- �������
          g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME            := cv_em_dash;                -- ��s������
        ELSE
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD END
          g_bm_balance_ttype( gn_index ).BANK_NO                   := gt_bank_no_bk;             -- ��s�ԍ�
          g_bm_balance_ttype( gn_index ).BANK_NAME                 := gt_bank_name_bk;           -- ��s��
          g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO            := gt_bank_branch_no_bk;      -- ��s�x�X�ԍ�
          g_bm_balance_ttype( gn_index ).BANK_BRANCH_NAME          := gt_bank_branch_name_bk;    -- ��s�x�X��
          g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE            := gt_bank_acct_type_bk;      -- �������
          g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE_NAME       := gt_bank_acct_type_name_bk; -- ������ʖ�
          g_bm_balance_ttype( gn_index ).BANK_ACCT_NO              := gt_bank_acct_no_bk;        -- �����ԍ�
          g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME            := gt_bank_acct_name_bk;      -- ��s������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD START
        END IF;
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki ADD END
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD START
          g_bm_balance_ttype( gn_index ).BM_PAYMENT_CODE           := gt_bm_type_bk;             -- BM�x���敪(�R�[�h�l)
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD END
          g_bm_balance_ttype( gn_index ).BM_PAYMENT_TYPE           := gt_bm_payment_type_bk;     -- BM�x���敪
          g_bm_balance_ttype( gn_index ).BANK_TRNS_FEE             := gt_bank_trns_fee_bk;       -- �U���萔��
          g_bm_balance_ttype( gn_index ).PAYMENT_STOP              := gt_payment_stop_bk;        -- �x����~
          g_bm_balance_ttype( gn_index ).SELLING_BASE_CODE         := gt_selling_base_code_bk;   -- ����v�㋒�_����
          g_bm_balance_ttype( gn_index ).SELLING_BASE_NAME         := gt_selling_base_name_bk;   -- ����v�㋒�_��
          g_bm_balance_ttype( gn_index ).WARNNING_MARK             := gt_warnning_mark_bk;       -- �x���}�[�N
          g_bm_balance_ttype( gn_index ).CUST_CODE                 := gt_cust_code_bk;           -- �ڋq�R�[�h
          g_bm_balance_ttype( gn_index ).CUST_NAME                 := gt_cust_name_bk;           -- �ڋq��
          g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH         := gt_unpaid_last_month_sum;  -- �O���܂ł̖���
          g_bm_balance_ttype( gn_index ).BM_THIS_MONTH             := gt_bm_this_month_sum;      -- ����BM
          g_bm_balance_ttype( gn_index ).ELECTRIC_AMT              := gt_electric_amt_sum;       -- �d�C��
          g_bm_balance_ttype( gn_index ).UNPAID_BALANCE            := gt_unpaid_balance_sum;     -- �����c��
          g_bm_balance_ttype( gn_index ).RESV_PAYMENT              := gt_resv_payment_bk;        -- �x���ۗ�
          g_bm_balance_ttype( gn_index ).PAYMENT_DATE              := gt_payment_date_bk;        -- �x����
          g_bm_balance_ttype( gn_index ).CLOSING_DATE              := gt_closing_date_bk;        -- ���ߓ�
          g_bm_balance_ttype( gn_index ).SELLING_BASE_SECTION_CODE := gt_section_code_bk;        -- �n��R�[�h
-- Ver.1.24 ADD START
          g_bm_balance_ttype( gn_index ).BM_TAX_KBN_NAME           := gt_bm_tax_kbn_name_bk;     -- BM�ŋ敪��
-- Ver.1.24 ADD END
-- Ver.1.22 DEL START
--          -- �Ώی����ϐ��Ɍ�����ݒ�
--          gn_target_cnt             := gn_index;
-- Ver.1.22 DEL END
        END IF;
        -------------------------
        -- �ޔ��E�W�v���ڂ̏�����
        -------------------------
        gt_payment_code_bk        := NULL;
        gt_payment_name_bk        := NULL;
        gt_bank_no_bk             := NULL;
        gt_bank_name_bk           := NULL;
        gt_bank_branch_no_bk      := NULL;
        gt_bank_branch_name_bk    := NULL;
        gt_bank_acct_type_bk      := NULL;
        gt_bank_acct_type_name_bk := NULL;
        gt_bank_acct_no_bk        := NULL;
        gt_bank_acct_name_bk      := NULL;
        gt_bm_type_bk             := NULL;
        gt_bm_payment_type_bk     := NULL;
        gt_bank_trns_fee_bk       := NULL;
        gt_payment_stop_bk        := NULL;
        gt_selling_base_code_bk   := NULL;
        gt_selling_base_name_bk   := NULL;
        gt_warnning_mark_bk       := NULL;
        gt_cust_code_bk           := NULL;
        gt_cust_name_bk           := NULL;
        gt_unpaid_last_month_sum  := 0;
        gt_bm_this_month_sum      := 0;
        gt_electric_amt_sum       := 0;
        gt_unpaid_balance_sum     := 0;
        gt_resv_payment_bk        := NULL;
        gt_payment_date_bk        := NULL;
        gt_closing_date_bk        := NULL;
        gt_section_code_bk        := NULL;
-- Ver.1.24 ADD START
        gt_bm_tax_kbn_name_bk     := NULL;
-- Ver.1.24 ADD END
      END IF;
    END IF;
    ----------------------------
    -- �u�O���܂ł̖����v�̏W�v
    ----------------------------
-- 2012/07/10 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD START
--    IF ( i_target_rec.expect_payment_date <= LAST_DAY( ADD_MONTHS( gd_payment_date ,-1 ) ) ) THEN
--      gt_unpaid_last_month_sum := gt_unpaid_last_month_sum + i_target_rec.expect_payment_amt_tax;
    IF i_target_rec.fb_interface_date IS NULL THEN
      IF ( i_target_rec.expect_payment_date <= LAST_DAY( ADD_MONTHS( gd_payment_date ,-1 ) ) ) THEN
        gt_unpaid_last_month_sum := gt_unpaid_last_month_sum
                                  + i_target_rec.expect_payment_amt_tax;
      END IF;
    ELSE
      IF ( i_target_rec.expect_payment_date <= LAST_DAY( ADD_MONTHS( gd_payment_date ,-1 ) ) )
        AND ( TRUNC(gd_payment_date ,cv_format_mm) <= TRUNC(i_target_rec.fb_interface_date ,cv_format_mm)) THEN
        gt_unpaid_last_month_sum := gt_unpaid_last_month_sum
                                  + i_target_rec.payment_amt_tax;
      END IF;
    END IF;
    --
-- 2012/07/10 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD END
    ----------------------------
    -- �u�����c���v�̏W�v
    ----------------------------
    IF ( i_target_rec.expect_payment_date <= gd_payment_date ) THEN
      gt_unpaid_balance_sum := gt_unpaid_balance_sum + i_target_rec.expect_payment_amt_tax;
    END IF;
    ----------------------------
    -- �u����BM�v�A�u�d�C���v�̏W�v
    ----------------------------
    IF ( TRUNC( i_target_rec.expect_payment_date ) BETWEEN TRUNC( gd_payment_date , 'MM' ) AND gd_payment_date ) THEN
      gt_bm_this_month_sum := gt_bm_this_month_sum + i_target_rec.backmargin + i_target_rec.backmargin_tax;
      gt_electric_amt_sum  := gt_electric_amt_sum + i_target_rec.electric_amt + i_target_rec.electric_amt_tax;
    END IF;
    ----------------------------
    -- �x���ۗ��̐ݒ�
    ----------------------------
-- 2012/07/20 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD START
--    IF ( gt_resv_payment_bk IS NULL ) AND ( i_target_rec.resv_flag = cv_flag_y ) THEN
    IF ( i_target_rec.resv_flag = cv_flag_y ) THEN
-- 2013/04/04 Ver.1.17 [��QE_�{�ғ�_10595,10609] SCSK K.Nakamura UPD START
---- 2012/07/20 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD END
---- 2012/07/11 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD START
----      gt_resv_payment_bk := gv_pay_res_name;
--      IF ( i_target_rec.proc_type = cv_proc_type0_upd ) THEN
---- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi UPD START
----      --�ۗ��t���O='Y'���A�����敪��'0'�̏ꍇ�́u�����J�z�v
----        gt_resv_payment_bk := gv_pay_auto_res_name; -- �����J�z
--        -- [��QE_�{�ғ�_10381] �����J�z�̏����ύX�iupd_resv_payment�Ŏ��{�j
--        NULL;
---- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi UPD END
--      ELSIF ( i_target_rec.proc_type = cv_proc_type2_upd ) THEN
--      --�ۗ��t���O='Y'���A�����敪��'2'�̏ꍇ�́u�ۗ��v
--        gt_resv_payment_bk := gv_pay_res_name; -- �ۗ�
--      END IF;
      --�ۗ��t���O='Y'�̏ꍇ�́u�ۗ��v
        gt_resv_payment_bk := gv_pay_res_name; -- �ۗ�
--    ELSIF ( i_target_rec.resv_flag IS NULL )
--      AND ( i_target_rec.proc_type = cv_proc_type1_upd ) THEN
--        --�ۗ��t���O=NULL���A�����敪��'1'�̏ꍇ�́u�����ρv
--        gt_resv_payment_bk := gv_pay_rec_name; -- ������
      -- [��QE_�{�ғ�_10609] �����ς̏����ύX�iupd_resv_payment_rec�Ŏ��{�j
-- 2013/04/04 Ver.1.17 [��QE_�{�ғ�_10595,10609] SCSK K.Nakamura UPD END
    ELSE
      -- �ۗ��������̎c���A�c���A�b�v���[�h�@�\�ȊO�ł̎c���X�V�f�[�^�̏ꍇ�A�����o�͂��Ȃ�
      gt_resv_payment_bk := NULL;
-- 2012/07/11 Ver.1.15 [��QE_�{�ғ�_08367] SCSK K.Onotsuka UPD END
    END IF;
    ----------------------------
    -- �x���}�[�N�̐ݒ�
    ----------------------------
    IF ( gt_warnning_mark_bk IS NULL ) AND ( in_error_count > 0 ) THEN
      gt_warnning_mark_bk := gv_error_mark;
    END IF;
    ----------------------------
    -- �U���萔���̐ݒ�
    ----------------------------
    IF it_bank_charge_bearer IS NOT NULL THEN
      IF ( it_bank_charge_bearer = cv_bk_trns_fee_cd ) THEN
        gt_bank_trns_fee_bk := gv_bk_trns_fee_we;    -- �U���萔��_����
      ELSE
        gt_bank_trns_fee_bk := gv_bk_trns_fee_ctpty; -- �U���萔��_�����
      END IF;
    END IF;
    ----------------------------
    -- �x����~�̐ݒ�
    ----------------------------
    IF ( it_hold_all_payments_flag = cv_flag_y ) THEN
      gt_payment_stop_bk := gv_pay_stop_name;
    END IF;
    ----------------------------
    -- ���̑��̑ޔ����ڐݒ�
    ----------------------------
    gt_payment_code_bk              := i_target_rec.supplier_code;       -- �x����R�[�h
    gt_payment_name_bk              := it_vendor_name;                   -- �x���於
    gt_bank_no_bk                   := it_bank_number;                   -- ��s�ԍ�
    gt_bank_name_bk                 := it_bank_name;                     -- ��s��
    gt_bank_branch_no_bk            := it_bank_num;                      -- ��s�x�X�ԍ�
    gt_bank_branch_name_bk          := it_bank_branch_name;              -- ��s�x�X��
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--    gt_bank_acct_type_bk            := it_bank_account_type;             -- �������
    gt_bank_acct_type_bk            := iv_bank_account_type;             -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
    gt_bank_acct_type_name_bk       := iv_bk_account_type_nm;            -- ������ʖ�
    gt_bank_acct_no_bk              := it_bank_account_num;              -- �����ԍ�
    gt_bank_acct_name_bk            := it_account_holder_name_alt;       -- ��s������
    gt_ref_base_code_bk             := iv_ref_base_code;                 -- �⍇���S�����_�R�[�h
    gt_ref_base_name_bk             := it_ref_base_name;                 -- �⍇���S�����_��
    gt_bm_type_bk                   := iv_bm_kbn;                        -- BM�x���敪
    gt_bm_payment_type_bk           := iv_bm_kbn_nm;                     -- BM�x���敪��
    gt_selling_base_code_bk         := it_selling_base_code;             -- ����v�㋒�_�R�[�h
    gt_selling_base_name_bk         := it_selling_base_name;             -- ����v�㋒�_��
    gt_cust_code_bk                 := it_account_number;                -- �ڋq�R�[�h
    gt_cust_name_bk                 := it_party_name;                    -- �ڋq��
    gt_payment_date_bk              := i_target_rec.expect_payment_date; -- �x����
    gt_closing_date_bk              := i_target_rec.closing_date;        -- ���ߓ�
    gt_section_code_bk              := it_address3;                      -- �n��R�[�h�i����v�㋒�_�j
-- Ver.1.24 ADD START
    gt_bm_tax_kbn_name_bk           := iv_bm_tax_kbn_name;               -- BM�ŋ敪��
-- Ver.1.24 ADD END
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
  END break_judge;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_contract_err
   * Description      : �̎�G���[��񒊏o����(A-5)
   ***********************************************************************************/
  PROCEDURE get_bm_contract_err(
    ov_errbuf                  OUT VARCHAR2              -- �G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2              -- ���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_selling_base_code       IN  VARCHAR2 DEFAULT NULL -- ����v�㋒�_�R�[�h
  , iv_cust_code               IN  VARCHAR2 DEFAULT NULL -- �ڋq�R�[�h
  , on_error_count             OUT NUMBER                -- �G���[�J�E���g
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(19) := 'get_bm_contract_err';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    SELECT COUNT(*)
    INTO   on_error_count
    FROM   xxcok_bm_contract_err -- �̎�����G���[�e�[�u��
    WHERE  base_code = iv_selling_base_code
    AND    cust_code = iv_cust_code
    ;
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
  END get_bm_contract_err;
--
  /**********************************************************************************
   * Procedure Name   : get_vendor_data
   * Description      : �d����E��s��񒊏o����(A-4)
   ***********************************************************************************/
  PROCEDURE get_vendor_data(
    ov_errbuf                  OUT VARCHAR2              -- �G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2              -- ���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_supplier_code           IN  VARCHAR2 DEFAULT NULL                              -- �d����R�[�h
  , iv_supplier_site_code      IN  VARCHAR2 DEFAULT NULL                              -- �d����T�C�g�R�[�h
  , ov_vendor_name             OUT po_vendors.vendor_name%TYPE                        -- �d���於
  , ov_bank_charge_bearer      OUT po_vendors.bank_charge_bearer%TYPE                 -- ��s�萔�����S��
  , ov_hold_all_payments_flag  OUT po_vendors.hold_all_payments_flag%TYPE             -- �S�x���ۗ̕��t���O
  , ov_ref_base_code           OUT po_vendor_sites_all.attribute5%TYPE                -- DFF5(�⍇���S�����_�R�[�h)
  , ov_bm_kbn_dff4             OUT po_vendor_sites_all.attribute4%TYPE                -- DFF4(BM�x���敪)
  , ov_bank_number             OUT ap_bank_branches.bank_number%TYPE                  -- ��s�ԍ�
  , ov_bank_name               OUT ap_bank_branches.bank_name%TYPE                    -- ��s������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--  , ov_bank_account_type       OUT ap_bank_accounts_all.bank_account_type%TYPE        -- �������
  , ov_bank_account_type       OUT VARCHAR2                                           -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
  , ov_bank_account_num        OUT ap_bank_accounts_all.bank_account_num%TYPE         -- ��s�����ԍ�
  , ov_account_holder_name_alt OUT ap_bank_accounts_all.account_holder_name_alt%TYPE  -- �������`�l�J�i
  , ov_bank_num                OUT ap_bank_branches.bank_num%TYPE                     -- ��s�x�X�ԍ�
  , ov_bank_branch_name        OUT ap_bank_branches.bank_branch_name%TYPE             -- ��s�x�X��
  , ov_account_name            OUT hz_cust_accounts.account_name%TYPE                 -- �⍇���S�����_��
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi START
--  , ov_bm_kbn                  OUT xxcmn_lookup_values_v.lookup_code%TYPE             -- BM�x���敪
--  , ov_bm_kbn_nm               OUT xxcmn_lookup_values_v.meaning%TYPE                 -- BM�x���敪��
--  , ov_bk_account_type         OUT xxcmn_lookup_values_v.lookup_code%TYPE             -- �������
--  , ov_bk_account_type_nm      OUT xxcmn_lookup_values_v.meaning%TYPE                 -- ������ʖ�
  , ov_bm_kbn                  OUT xxcok_lookups_v.lookup_code%TYPE                   -- BM�x���敪
  , ov_bm_kbn_nm               OUT xxcok_lookups_v.meaning%TYPE                       -- BM�x���敪��
  , ov_bk_account_type         OUT xxcok_lookups_v.lookup_code%TYPE                   -- �������
  , ov_bk_account_type_nm      OUT xxcok_lookups_v.meaning%TYPE                       -- ������ʖ�
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi END
-- Ver.1.24 ADD START
  , ov_bm_tax_kbn_name         OUT xxcok_lookups_v.meaning%TYPE                       -- BM�ŋ敪��
-- Ver.1.24 ADD END
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(15) := 'get_vendor_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    lt_bm_tax_kbn  po_vendor_sites_all.attribute6%TYPE;   -- DFF6(BM�ŋ敪)
    -- ��O�n���h��
    no_data_expt            EXCEPTION; -- �f�[�^�擾�G���[
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
-- Ver.1.24 ADD START
    lt_bm_tax_kbn := NULL;
-- Ver.1.24 ADD END
    -- ===============================================
    -- �d����E��s���
    -- ===============================================
    BEGIN
      SELECT pv.vendor_name                    -- �d���於
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi START
--            ,pv.bank_charge_bearer             -- ��s�萔�����S��
--            ,pv.hold_all_payments_flag         -- �S�x���ۗ̕��t���O
            ,pvsa.bank_charge_bearer           -- ��s�萔�����S��
            ,pvsa.hold_all_payments_flag       -- �S�x���ۗ̕��t���O
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi END
            ,pvsa.attribute4                   -- DFF4(BM�x���敪)
            ,pvsa.attribute5                   -- DFF5(�⍇���S�����_�R�[�h)
            ,bank_data.bank_number             -- ��s�ԍ�
            ,bank_data.bank_name               -- ��s������
            ,bank_data.bank_account_type       -- �������
            ,bank_data.bank_account_num        -- ��s�����ԍ�
            ,bank_data.account_holder_name_alt -- �������`�l�J�i
            ,bank_data.bank_num                -- ��s�x�X�ԍ�
            ,bank_data.bank_branch_name        -- ��s�x�X��
            ,hca.account_name                  -- ���́i�A�J�E���g���j
-- Ver.1.24 ADD START
            ,pvsa.attribute6                   -- DFF6(BM�ŋ敪)
-- Ver.1.24 ADD END
      INTO   ov_vendor_name
            ,ov_bank_charge_bearer
            ,ov_hold_all_payments_flag
            ,ov_bm_kbn_dff4
            ,ov_ref_base_code
            ,ov_bank_number
            ,ov_bank_name
            ,ov_bank_account_type
            ,ov_bank_account_num
            ,ov_account_holder_name_alt
            ,ov_bank_num
            ,ov_bank_branch_name
            ,ov_account_name
-- Ver.1.24 ADD START
            ,lt_bm_tax_kbn
-- Ver.1.24 ADD END
      FROM   po_vendors          pv       -- �d����}�X�^
            ,po_vendor_sites_all pvsa     -- �d����T�C�g
            ,hz_cust_accounts       hca   -- �ڋq�}�X�^
            ,(SELECT abaua.vendor_id              AS vendor_id               -- �d����ID
                    ,abaua.vendor_site_id         AS vendor_site_id          -- �d����T�C�gID
                    ,abaa.bank_account_type       AS bank_account_type       -- �������
                    ,abaa.bank_account_num        AS bank_account_num        -- ��s�����ԍ�
                    ,abaa.account_holder_name_alt AS account_holder_name_alt -- �������`�l�J�i
                    ,abb.bank_name                AS bank_name               -- ��s��
                    ,abb.bank_num                 AS bank_num                -- ��s�x�X�ԍ�
                    ,abb.bank_branch_name         AS bank_branch_name        -- ��s�x�X��
                    ,abb.bank_number              AS bank_number             -- ��s�ԍ�
              FROM   ap_bank_account_uses_all abaua -- ��s�����g�p���
                    ,ap_bank_accounts_all     abaa  -- ��s����
                    ,ap_bank_branches         abb   -- ��s�x�X
              WHERE abaa.bank_account_id                     = abaua.external_bank_account_id
              AND   abaa.bank_branch_id                      = abb.bank_branch_id
              AND   abaua.primary_flag                       = cv_flag_y
              AND   NVL( TRUNC( abaua.start_date ), TRUNC( gd_process_date ) ) <= TRUNC( gd_process_date )
              AND   NVL( TRUNC( abaua.end_date )  , TRUNC( gd_process_date ) ) >= TRUNC( gd_process_date )
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
              AND   abaua.org_id                             = gn_org_id
              AND   abaa.org_id                              = gn_org_id
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
              ) bank_data
      WHERE  pv.vendor_id             = pvsa.vendor_id
      AND    pvsa.vendor_id           = bank_data.vendor_id(+)
      AND    pvsa.vendor_site_id      = bank_data.vendor_site_id(+)
      AND    pv.segment1              = iv_supplier_code
      AND    hca.account_number       = pvsa.attribute5
      AND    pvsa.attribute5          = NVL( gv_ref_base_code ,pvsa.attribute5 )
      AND    hca.customer_class_code  = cv_cust_class_code1-- ���_
      AND    NVL( pvsa.inactive_date, gd_process_date + 1) > gd_process_date
      AND    pvsa.org_id                                   = gn_org_id
      ;
    EXCEPTION
      -- �d���E��s���擾�G���[
      WHEN NO_DATA_FOUND THEN
-- Ver.1.22 MOD START
--        lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_xxcok_appl_short_name
--                      , iv_name         => cv_msg_code_10333
--                      , iv_token_name1  => cv_token_vendor_code
--                      , iv_token_value1 => iv_supplier_code
--                      , iv_token_name2  => cv_token_vendor_site_code
--                      , iv_token_value2 => iv_supplier_site_code
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG
--                      , iv_message  => lv_errmsg
--                      , in_new_line => cn_number_0
--                      );
--        RAISE no_data_expt;
        ov_vendor_name              := NULL;
        ov_bank_charge_bearer       := NULL;
        ov_hold_all_payments_flag   := NULL;
        ov_bm_kbn_dff4              := NULL;
        ov_ref_base_code            := NULL;
        ov_bank_number              := NULL;
        ov_bank_name                := NULL;
        ov_bank_account_type        := NULL;
        ov_bank_account_num         := NULL;
        ov_account_holder_name_alt  := NULL;
        ov_bank_num                 := NULL;
        ov_bank_branch_name         := NULL;
        ov_account_name             := NULL;
-- Ver.1.22 MOD END
-- Ver.1.24 ADD START
        lt_bm_tax_kbn               := NULL;
-- Ver.1.24 ADD END
      -- �d���E��s��񕡐����G���[
      WHEN TOO_MANY_ROWS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10334
                      , iv_token_name1  => cv_token_vendor_code
                      , iv_token_value1 => iv_supplier_code
                      , iv_token_name2  => cv_token_vendor_site_code
                      , iv_token_value2 => iv_supplier_site_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
      RAISE no_data_expt;
    END;
    -- ===============================================
    -- BM�x���敪���
    -- ===============================================
-- Ver.1.22 ADD START
    IF ov_bm_kbn_dff4 IS NOT NULL THEN
-- Ver.1.22 ADD END
      BEGIN
        SELECt lookup_code  -- BM�x���敪
              ,meaning      -- BM�x���敪��
        INTO   ov_bm_kbn
              ,ov_bm_kbn_nm
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi START
--      FROM   xxcmn_lookup_values_v
        FROM   xxcok_lookups_v
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi END
        WHERE  lookup_type = cv_lookup_type_bm_kbn
        AND    lookup_code = ov_bm_kbn_dff4
        ;
      EXCEPTION
        -- BM�x���敪���擾�G���[
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00015
                        , iv_token_name1  => cv_token_lookup_value_set
                        , iv_token_value1 => cv_lookup_type_bm_kbn
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
      END;
-- Ver.1.22 ADD START
    ELSE
      ov_bm_kbn     := NULL;
      ov_bm_kbn_nm  := NULL;
    END IF;
-- Ver.1.22 ADD END
    -- ===============================================
    -- ������ʏ��
    -- ===============================================
    IF ov_bank_account_type IS NOT NULL THEN
      BEGIN
        SELECt lookup_code  -- �������
              ,meaning      -- ������ʖ�
        INTO   ov_bk_account_type
              ,ov_bk_account_type_nm
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi START
--        FROM   xxcmn_lookup_values_v
        FROM   xxcok_lookups_v
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi END
        WHERE  lookup_type = cv_lookup_type_bank
        AND    lookup_code = ov_bank_account_type
        ;
      EXCEPTION
        -- ������ʏ��擾�G���[
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00015
                        , iv_token_name1  => cv_token_lookup_value_set
                        , iv_token_value1 => cv_lookup_type_bank
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
      END;
    ELSE
      ov_bk_account_type    := NULL;
      ov_bk_account_type_nm := NULL;
    END IF;
-- Ver.1.24 ADD START
    -- ===============================================
    -- BM�ŋ敪���
    -- ===============================================
    IF lt_bm_tax_kbn IS NULL THEN
      lt_bm_tax_kbn         := cv_tax_included;
    END IF;
    BEGIN
      SELECT xlv.meaning      -- BM�ŋ敪��
      INTO   ov_bm_tax_kbn_name
      FROM   xxcok_lookups_v xlv
      WHERE  xlv.lookup_type = cv_lookup_type_bm_tax_kbn
      AND    xlv.lookup_code = lt_bm_tax_kbn
      AND    NVL(xlv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
      AND    NVL(xlv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
      ;
    EXCEPTION
      -- BM�ŋ敪���擾�G���[
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00015
                      , iv_token_name1  => cv_token_lookup_value_set
                      , iv_token_value1 => cv_lookup_type_bm_tax_kbn
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE no_data_expt;
    END;
-- Ver.1.24 ADD END
--
  EXCEPTION
    -- *** �f�[�^�擾��O ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END get_vendor_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_data
   * Description      : ���㋒�_�E�ڋq��񒊏o����(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_data(
    ov_errbuf            OUT VARCHAR2              -- �G���[�E���b�Z�[�W
  , ov_retcode           OUT VARCHAR2              -- ���^�[���E�R�[�h
  , ov_errmsg            OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_process_flg       IN  VARCHAR2 DEFAULT NULL -- �����t���O(1�F���㋒�_���A2�F�ڋq���)
  , iv_selling_base_code IN  VARCHAR2 DEFAULT NULL -- ���㋒�_
  , iv_cust_code         IN  VARCHAR2 DEFAULT NULL -- �ڋq�R�[�h
  , ov_selling_base_code OUT VARCHAR2              -- ����v�㋒�_�R�[�h
  , ov_account_name      OUT VARCHAR2              -- ����v�㋒�_��
  , ov_address3          OUT VARCHAR2              -- �n��R�[�h
  , ov_account_number    OUT VARCHAR2              -- �ڋq�R�[�h
  , ov_party_name        OUT VARCHAR2              -- �ڋq��
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(13) := 'get_cust_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg   VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_retcode  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    -- ��O�n���h��
    no_data_expt            EXCEPTION; -- �f�[�^�擾�G���[
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    IF iv_process_flg = '1' THEN
      -- ===============================================
      -- ���㋒�_���
      -- ===============================================
      BEGIN
        SELECT hca.account_number           -- ����v�㋒�_�R�[�h
              ,hca.account_name             -- ����v�㋒�_��
              ,hl.address3                  -- �n��R�[�h
        INTO   ov_selling_base_code
              ,ov_account_name
              ,ov_address3
        FROM   hz_cust_accounts       hca   -- �ڋq�}�X�^
              ,hz_cust_acct_sites_all hcasa -- �ڋq���ݒn�}�X�^
              ,hz_parties             hp    -- �p�[�e�B�}�X�^
              ,hz_party_sites         hps   -- �p�[�e�B�T�C�g�}�X�^
              ,hz_locations           hl    -- �ڋq���Ə��}�X�^
        WHERE  hca.party_id            = hp.party_id
        AND    hca.cust_account_id     = hcasa.cust_account_id
        AND    hp.party_id             = hps.party_id
        AND    hps.party_site_id       = hcasa.party_site_id
        AND    hps.location_id         = hl.location_id
        AND    hca.account_number      = iv_selling_base_code
        AND    hca.customer_class_code = cv_cust_class_code1-- ���_
        AND    hcasa.org_id            = gn_org_id
        ;
      EXCEPTION
        -- ����v�㋒�_���擾�G���[
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00048
                        , iv_token_name1  => cv_token_sales_loc
                        , iv_token_value1 => iv_selling_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        -- ����v�㋒�_��񕡐����G���[
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00047
                        , iv_token_name1  => cv_token_sales_loc
                        , iv_token_value1 => iv_selling_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
      END;
    ELSE
      -- ===============================================
      -- �ڋq���
      -- ===============================================
      BEGIN
        SELECT hca.account_number           -- �ڋq�R�[�h
               ,hp.party_name                -- �ڋq��
        INTO   ov_account_number
              ,ov_party_name
        FROM   hz_cust_accounts       hca   -- �ڋq�}�X�^
              ,hz_parties             hp    -- �p�[�e�B�}�X�^
        WHERE  hca.party_id        = hp.party_id
        AND    hca.account_number  = iv_cust_code
        AND    hca.customer_class_code = cv_cust_class_code10-- �ڋq
        ;
      EXCEPTION
        -- �ڋq���擾�G���[
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00035
                        , iv_token_name1  => cv_token_cust_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
        -- �ڋq��񕡐����G���[
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00046
                        , iv_token_name1  => cv_token_cost_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG
                        , iv_message  => lv_errmsg
                        , in_new_line => cn_number_0
                        );
          RAISE no_data_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** �f�[�^�擾��O ***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END get_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : �̎�c����񒊏o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf                OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name         CONSTANT VARCHAR2(15) := 'get_target_data';  -- �v���O������
    cv_process_flg1     CONSTANT VARCHAR2(1)  := '1'; -- �����t���O(1�F���㋒�_���)
    cv_process_flg2     CONSTANT VARCHAR2(1)  := '2'; -- �����t���O(2�F�ڋq���)
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg   VARCHAR2(5000)  DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki DEL START
--    lv_target_disp_flg          VARCHAR2(1)                                       DEFAULT NULL; -- �\���Ώۃt���O
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki DEL END
    lt_selling_base_code        hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- ����v�㋒�_�R�[�h
    lt_selling_base_name        hz_cust_accounts.account_name%TYPE                DEFAULT NULL; -- ����v�㋒�_��
    lt_address3                 hz_locations.address3%TYPE                        DEFAULT NULL; -- �n��R�[�h
    lt_selling_base_code_dummy  hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- ����v�㋒�_�R�[�h
    lt_selling_base_name_dummy  hz_cust_accounts.account_name%TYPE                DEFAULT NULL; -- ����v�㋒�_��
    lt_address3_dummy           hz_locations.address3%TYPE                        DEFAULT NULL; -- �n��R�[�h
    lt_account_number           hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- �ڋq�R�[�h
    lt_party_name               hz_parties.party_name%TYPE                        DEFAULT NULL; -- �ڋq��
    lt_account_number_dummy     hz_cust_accounts.account_number%TYPE              DEFAULT NULL; -- �ڋq�R�[�h
    lt_party_name_dummy         hz_parties.party_name%TYPE                        DEFAULT NULL; -- �ڋq��
    lt_vendor_name              po_vendors.vendor_name%TYPE                       DEFAULT NULL; -- �d���於
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi START
    lt_bank_charge_bearer       po_vendor_sites_all.bank_charge_bearer%TYPE       DEFAULT NULL; -- ��s�萔�����S��
    lt_hold_all_payments_flag   po_vendor_sites_all.hold_all_payments_flag%TYPE   DEFAULT NULL; -- �S�x���ۗ̕��t���O
-- 2009/07/15 Ver.1.7 [��Q0000689] SCS T.Taniguchi END
    lv_ref_base_code            VARCHAR2(4)                                       DEFAULT NULL; -- �⍇���S�����_����
    lv_bm_kbn_dff4              VARCHAR2(2)                                       DEFAULT NULL; -- DFF4(BM�x���敪)
    lt_bank_number              ap_bank_branches.bank_number%TYPE                 DEFAULT NULL; -- ��s�ԍ�
    lt_bank_name                ap_bank_branches.bank_name%TYPE                   DEFAULT NULL; -- ��s������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--    lt_bank_account_type        ap_bank_accounts_all.bank_account_type%TYPE       DEFAULT NULL; -- �������
    lv_bank_account_type        VARCHAR2(2)                                       DEFAULT NULL; -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
    lt_bank_account_num         ap_bank_accounts_all.bank_account_num%TYPE        DEFAULT NULL; -- ��s�����ԍ�
    lt_account_holder_name_alt  ap_bank_accounts_all.account_holder_name_alt%TYPE DEFAULT NULL; -- �������`�l�J�i
    lt_bank_num                 ap_bank_branches.bank_num%TYPE                    DEFAULT NULL; -- ��s�x�X�ԍ�
    lt_bank_branch_name         ap_bank_branches.bank_branch_name%TYPE            DEFAULT NULL; -- ��s�x�X��
    lt_ref_base_name            hz_cust_accounts.account_name%TYPE                DEFAULT NULL; -- ���́i�A�J�E���g���j
    lv_bm_kbn                   VARCHAR2(2)                                       DEFAULT NULL; -- BM�x���敪
    lv_bm_kbn_nm                VARCHAR2(30)                                      DEFAULT NULL; -- BM�x���敪��
    lv_bk_account_type_nm       VARCHAR2(4)                                       DEFAULT NULL; -- ������ʖ�
    lv_bk_account_type          VARCHAR2(1)                                       DEFAULT NULL; -- �������
    ln_error_count              NUMBER                                            DEFAULT 0;    -- �̎�G���[����
    ln_loop_cnt                 NUMBER                                            DEFAULT 0;    -- ���[�v�J�E���g
-- Ver.1.24 ADD START
    lv_bm_tax_kbn_name          VARCHAR2(30)                                      DEFAULT NULL; -- BM�ŋ敪��
-- Ver.1.24 ADD END
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c����񒊏o����
    -- ===============================================
    -- ���̓p�����[�^���u���㋒�_��v���u�����_�̂݁v�̏ꍇ
-- Ver.1.22 MOD START
--    IF ( gv_target_disp = cv_target_disp1_nm )
--      OR ( gv_target_disp IS NULL ) THEN
    IF ( gv_selling_base_code IS NOT NULL ) AND ( gv_target_disp = cv_target_disp1 ) THEN
-- Ver.1.22 MOD END
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD START
--      lv_target_disp_flg := cv_target_disp1;
      -- �̎�c�����擾�J�[�\��
      <<main_loop>>
      FOR g_target_rec IN g_target_cur1 LOOP
        --
        ln_loop_cnt := ln_loop_cnt + 1;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.base_code <> gt_selling_base_code_bk ) THEN
          -- ===============================================
          -- ���㋒�_��񒊏o����(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W
           ,ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h
           ,ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,iv_process_flg        => cv_process_flg1         -- �����t���O(1�F���㋒�_���)
           ,iv_selling_base_code  => g_target_rec.base_code  -- ���㋒�_
           ,iv_cust_code          => g_target_rec.cust_code  -- �ڋq�R�[�h
           ,ov_selling_base_code  => lt_selling_base_code    -- ����v�㋒�_�R�[�h
           ,ov_account_name       => lt_selling_base_name    -- ����v�㋒�_��
           ,ov_address3           => lt_address3             -- �n��R�[�h
           ,ov_account_number     => lt_account_number_dummy -- �ڋq�R�[�h
           ,ov_party_name         => lt_party_name_dummy     -- �ڋq��
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- �ڋq��񒊏o����(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf                  -- �G���[�E���b�Z�[�W
           ,ov_retcode            => lv_retcode                 -- ���^�[���E�R�[�h
           ,ov_errmsg             => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,iv_process_flg        => cv_process_flg2            -- �����t���O(2�F�ڋq���)
           ,iv_selling_base_code  => g_target_rec.base_code     -- ���㋒�_
           ,iv_cust_code          => g_target_rec.cust_code     -- �ڋq�R�[�h
           ,ov_selling_base_code  => lt_selling_base_code_dummy -- ����v�㋒�_�R�[�h
           ,ov_account_name       => lt_selling_base_name_dummy -- ����v�㋒�_��
           ,ov_address3           => lt_address3_dummy          -- �n��R�[�h
           ,ov_account_number     => lt_account_number          -- �ڋq�R�[�h
           ,ov_party_name         => lt_party_name              -- �ڋq��
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.supplier_code <> gt_payment_code_bk ) THEN
          -- ===============================================
          -- �d����E��s��񒊏o����(A-4)
          -- ===============================================
          get_vendor_data(
              ov_errbuf                  => lv_errbuf                       -- �G���[�E���b�Z�[�W
            , ov_retcode                 => lv_retcode                      -- ���^�[���E�R�[�h
            , ov_errmsg                  => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            , iv_supplier_code           => g_target_rec.supplier_code      -- �d����R�[�h
            , iv_supplier_site_code      => g_target_rec.supplier_site_code -- �d����T�C�g�R�[�h
            , ov_vendor_name             => lt_vendor_name                  -- �d���於
            , ov_bank_charge_bearer      => lt_bank_charge_bearer           -- ��s�萔�����S��
            , ov_hold_all_payments_flag  => lt_hold_all_payments_flag       -- �S�x���ۗ̕��t���O
            , ov_ref_base_code           => lv_ref_base_code                -- DFF5(�⍇���S�����_�R�[�h)
            , ov_bm_kbn_dff4             => lv_bm_kbn_dff4                  -- DFF4(BM�x���敪)
            , ov_bank_number             => lt_bank_number                  -- ��s�ԍ�
            , ov_bank_name               => lt_bank_name                    -- ��s������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--            , ov_bank_account_type       => lt_bank_account_type            -- �������
            , ov_bank_account_type       => lv_bank_account_type            -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
            , ov_bank_account_num        => lt_bank_account_num             -- ��s�����ԍ�
            , ov_account_holder_name_alt => lt_account_holder_name_alt      -- �������`�l�J�i
            , ov_bank_num                => lt_bank_num                     -- ��s�x�X�ԍ�
            , ov_bank_branch_name        => lt_bank_branch_name             -- ��s�x�X��
            , ov_account_name            => lt_ref_base_name                -- �⍇���S�����_��
            , ov_bm_kbn                  => lv_bm_kbn                       -- BM�x���敪
            , ov_bm_kbn_nm               => lv_bm_kbn_nm                    -- BM�x���敪��
            , ov_bk_account_type         => lv_bk_account_type              -- �������
            , ov_bk_account_type_nm      => lv_bk_account_type_nm           -- ������ʖ�
-- Ver.1.24 ADD START
            , ov_bm_tax_kbn_name         => lv_bm_tax_kbn_name              -- BM�ŋ敪��
-- Ver.1.24 ADD END
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 )
          OR ( g_target_rec.base_code <> gt_selling_base_code_bk )
          OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- �̎�G���[��񒊏o����(A-5)
          -- ===============================================
          get_bm_contract_err(
              ov_errbuf            => lv_errbuf                       -- �G���[�E���b�Z�[�W
            , ov_retcode           => lv_retcode                      -- ���^�[���E�R�[�h
            , ov_errmsg            => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            , iv_selling_base_code => g_target_rec.base_code          -- ����v�㋒�_�R�[�h
            , iv_cust_code         => g_target_rec.cust_code          -- �ڋq�R�[�h
            , on_error_count       => ln_error_count                  -- �G���[�J�E���g
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===============================================
        -- �u���C�N���菈��(A-6)
        -- ===============================================
        break_judge(
            ov_errbuf                  => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                 => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                  => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_target_rec               => g_target_rec               -- �J�[�\�����R�[�h
          , it_bank_charge_bearer      => lt_bank_charge_bearer      -- ��s�萔�����S��
          , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- �S�x���ۗ̕��t���O
          , it_vendor_name             => lt_vendor_name             -- �d���於
          , it_bank_number             => lt_bank_number             -- ��s�ԍ�
          , it_bank_name               => lt_bank_name               -- ��s������
          , it_bank_num                => lt_bank_num                -- ��s�x�X�ԍ�
          , it_bank_branch_name        => lt_bank_branch_name        -- ��s�x�X��
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--          , it_bank_account_type       => lt_bank_account_type       -- �������
          , iv_bank_account_type       => lv_bank_account_type       -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
          , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- ������ʖ�
          , it_bank_account_num        => lt_bank_account_num        -- ��s�����ԍ�
          , it_account_holder_name_alt => lt_account_holder_name_alt -- �������`�l�J�i
          , iv_ref_base_code           => lv_ref_base_code           -- DFF5(�⍇���S�����_�R�[�h)
          , it_selling_base_name       => lt_selling_base_name       -- ����v�㋒�_��
          , iv_bm_kbn                  => lv_bm_kbn                  -- BM�x���敪
          , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM�x���敪��
          , it_selling_base_code       => lt_selling_base_code       -- ����v�㋒�_�R�[�h
          , it_ref_base_name           => lt_ref_base_name           -- �⍇���S��s���_��
          , it_account_number          => lt_account_number          -- �ڋq�R�[�h
          , it_party_name              => lt_party_name              -- �ڋq��
          , it_address3                => lt_address3                -- �n��R�[�h
          , in_error_count             => ln_error_count             -- �̎�G���[����
-- Ver.1.24 ADD START
          , iv_bm_tax_kbn_name         => lv_bm_tax_kbn_name         -- BM�ŋ敪��
-- Ver.1.24 ADD END
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP main_loop;
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD END
    -- ���̓p�����[�^���u���㋒�_��v���u�����_���܂ށv���x����̎w�肪�Ȃ��ꍇ
-- Ver.1.22 MOD START
--    ELSE
    ELSIF ( gv_selling_base_code IS NOT NULL ) AND ( gv_target_disp = cv_target_disp2 ) THEN
-- Ver.1.22 MOD END
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD START
--      lv_target_disp_flg := cv_target_disp2;
      -- �̎�c�����擾�J�[�\��
      <<main_loop>>
      FOR g_target_rec IN g_target_cur2 LOOP
        --
        ln_loop_cnt := ln_loop_cnt + 1;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.base_code <> gt_selling_base_code_bk ) THEN
          -- ===============================================
          -- ���㋒�_��񒊏o����(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W
           ,ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h
           ,ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,iv_process_flg        => cv_process_flg1         -- �����t���O(1�F���㋒�_���)
           ,iv_selling_base_code  => g_target_rec.base_code  -- ���㋒�_
           ,iv_cust_code          => g_target_rec.cust_code  -- �ڋq�R�[�h
           ,ov_selling_base_code  => lt_selling_base_code    -- ����v�㋒�_�R�[�h
           ,ov_account_name       => lt_selling_base_name    -- ����v�㋒�_��
           ,ov_address3           => lt_address3             -- �n��R�[�h
           ,ov_account_number     => lt_account_number_dummy -- �ڋq�R�[�h
           ,ov_party_name         => lt_party_name_dummy     -- �ڋq��
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- �ڋq��񒊏o����(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf                  -- �G���[�E���b�Z�[�W
           ,ov_retcode            => lv_retcode                 -- ���^�[���E�R�[�h
           ,ov_errmsg             => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,iv_process_flg        => cv_process_flg2            -- �����t���O(2�F�ڋq���)
           ,iv_selling_base_code  => g_target_rec.base_code     -- ���㋒�_
           ,iv_cust_code          => g_target_rec.cust_code     -- �ڋq�R�[�h
           ,ov_selling_base_code  => lt_selling_base_code_dummy -- ����v�㋒�_�R�[�h
           ,ov_account_name       => lt_selling_base_name_dummy -- ����v�㋒�_��
           ,ov_address3           => lt_address3_dummy          -- �n��R�[�h
           ,ov_account_number     => lt_account_number          -- �ڋq�R�[�h
           ,ov_party_name         => lt_party_name              -- �ڋq��
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.supplier_code <> gt_payment_code_bk ) THEN
          -- ===============================================
          -- �d����E��s��񒊏o����(A-4)
          -- ===============================================
          get_vendor_data(
              ov_errbuf                  => lv_errbuf                       -- �G���[�E���b�Z�[�W
            , ov_retcode                 => lv_retcode                      -- ���^�[���E�R�[�h
            , ov_errmsg                  => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            , iv_supplier_code           => g_target_rec.supplier_code      -- �d����R�[�h
            , iv_supplier_site_code      => g_target_rec.supplier_site_code -- �d����T�C�g�R�[�h
            , ov_vendor_name             => lt_vendor_name                  -- �d���於
            , ov_bank_charge_bearer      => lt_bank_charge_bearer           -- ��s�萔�����S��
            , ov_hold_all_payments_flag  => lt_hold_all_payments_flag       -- �S�x���ۗ̕��t���O
            , ov_ref_base_code           => lv_ref_base_code                -- DFF5(�⍇���S�����_�R�[�h)
            , ov_bm_kbn_dff4             => lv_bm_kbn_dff4                  -- DFF4(BM�x���敪)
            , ov_bank_number             => lt_bank_number                  -- ��s�ԍ�
            , ov_bank_name               => lt_bank_name                    -- ��s������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--            , ov_bank_account_type       => lt_bank_account_type            -- �������
            , ov_bank_account_type       => lv_bank_account_type            -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
            , ov_bank_account_num        => lt_bank_account_num             -- ��s�����ԍ�
            , ov_account_holder_name_alt => lt_account_holder_name_alt      -- �������`�l�J�i
            , ov_bank_num                => lt_bank_num                     -- ��s�x�X�ԍ�
            , ov_bank_branch_name        => lt_bank_branch_name             -- ��s�x�X��
            , ov_account_name            => lt_ref_base_name                -- �⍇���S�����_��
            , ov_bm_kbn                  => lv_bm_kbn                       -- BM�x���敪
            , ov_bm_kbn_nm               => lv_bm_kbn_nm                    -- BM�x���敪��
            , ov_bk_account_type         => lv_bk_account_type              -- �������
            , ov_bk_account_type_nm      => lv_bk_account_type_nm           -- ������ʖ�
-- Ver.1.24 ADD START
            , ov_bm_tax_kbn_name         => lv_bm_tax_kbn_name              -- BM�ŋ敪��
-- Ver.1.24 ADD END
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 )
          OR ( g_target_rec.base_code <> gt_selling_base_code_bk )
          OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- �̎�G���[��񒊏o����(A-5)
          -- ===============================================
          get_bm_contract_err(
              ov_errbuf            => lv_errbuf                       -- �G���[�E���b�Z�[�W
            , ov_retcode           => lv_retcode                      -- ���^�[���E�R�[�h
            , ov_errmsg            => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            , iv_selling_base_code => g_target_rec.base_code          -- ����v�㋒�_�R�[�h
            , iv_cust_code         => g_target_rec.cust_code          -- �ڋq�R�[�h
            , on_error_count       => ln_error_count                  -- �G���[�J�E���g
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===============================================
        -- �u���C�N���菈��(A-6)
        -- ===============================================
        break_judge(
            ov_errbuf                  => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                 => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                  => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_target_rec               => g_target_rec               -- �J�[�\�����R�[�h
          , it_bank_charge_bearer      => lt_bank_charge_bearer      -- ��s�萔�����S��
          , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- �S�x���ۗ̕��t���O
          , it_vendor_name             => lt_vendor_name             -- �d���於
          , it_bank_number             => lt_bank_number             -- ��s�ԍ�
          , it_bank_name               => lt_bank_name               -- ��s������
          , it_bank_num                => lt_bank_num                -- ��s�x�X�ԍ�
          , it_bank_branch_name        => lt_bank_branch_name        -- ��s�x�X��
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--          , it_bank_account_type       => lt_bank_account_type       -- �������
          , iv_bank_account_type       => lv_bank_account_type       -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
          , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- ������ʖ�
          , it_bank_account_num        => lt_bank_account_num        -- ��s�����ԍ�
          , it_account_holder_name_alt => lt_account_holder_name_alt -- �������`�l�J�i
          , iv_ref_base_code           => lv_ref_base_code           -- DFF5(�⍇���S�����_�R�[�h)
          , it_selling_base_name       => lt_selling_base_name       -- ����v�㋒�_��
          , iv_bm_kbn                  => lv_bm_kbn                  -- BM�x���敪
          , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM�x���敪��
          , it_selling_base_code       => lt_selling_base_code       -- ����v�㋒�_�R�[�h
          , it_ref_base_name           => lt_ref_base_name           -- �⍇���S�����_��
          , it_account_number          => lt_account_number          -- �ڋq�R�[�h
          , it_party_name              => lt_party_name              -- �ڋq��
          , it_address3                => lt_address3                -- �n��R�[�h
          , in_error_count             => ln_error_count             -- �̎�G���[����
-- Ver.1.24 ADD START
          , iv_bm_tax_kbn_name         => lv_bm_tax_kbn_name         -- BM�ŋ敪��
-- Ver.1.24 ADD END
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP main_loop;
-- Ver.1.22 ADD START
    ELSE
      -- �̎�c�����擾�J�[�\��
      <<main_loop>>
      FOR g_target_rec IN g_target_cur3 LOOP
        --
        ln_loop_cnt := ln_loop_cnt + 1;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.base_code <> gt_selling_base_code_bk ) THEN
          -- ===============================================
          -- ���㋒�_��񒊏o����(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W
           ,ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h
           ,ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,iv_process_flg        => cv_process_flg1         -- �����t���O(1�F���㋒�_���)
           ,iv_selling_base_code  => g_target_rec.base_code  -- ���㋒�_
           ,iv_cust_code          => g_target_rec.cust_code  -- �ڋq�R�[�h
           ,ov_selling_base_code  => lt_selling_base_code    -- ����v�㋒�_�R�[�h
           ,ov_account_name       => lt_selling_base_name    -- ����v�㋒�_��
           ,ov_address3           => lt_address3             -- �n��R�[�h
           ,ov_account_number     => lt_account_number_dummy -- �ڋq�R�[�h
           ,ov_party_name         => lt_party_name_dummy     -- �ڋq��
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- �ڋq��񒊏o����(A-3)
          -- ===============================================
          get_cust_data(
            ov_errbuf             => lv_errbuf                  -- �G���[�E���b�Z�[�W
           ,ov_retcode            => lv_retcode                 -- ���^�[���E�R�[�h
           ,ov_errmsg             => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,iv_process_flg        => cv_process_flg2            -- �����t���O(2�F�ڋq���)
           ,iv_selling_base_code  => g_target_rec.base_code     -- ���㋒�_
           ,iv_cust_code          => g_target_rec.cust_code     -- �ڋq�R�[�h
           ,ov_selling_base_code  => lt_selling_base_code_dummy -- ����v�㋒�_�R�[�h
           ,ov_account_name       => lt_selling_base_name_dummy -- ����v�㋒�_��
           ,ov_address3           => lt_address3_dummy          -- �n��R�[�h
           ,ov_account_number     => lt_account_number          -- �ڋq�R�[�h
           ,ov_party_name         => lt_party_name              -- �ڋq��
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.supplier_code <> gt_payment_code_bk ) THEN
          -- ===============================================
          -- �d����E��s��񒊏o����(A-4)
          -- ===============================================
          get_vendor_data(
              ov_errbuf                  => lv_errbuf                       -- �G���[�E���b�Z�[�W
            , ov_retcode                 => lv_retcode                      -- ���^�[���E�R�[�h
            , ov_errmsg                  => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            , iv_supplier_code           => g_target_rec.supplier_code      -- �d����R�[�h
            , iv_supplier_site_code      => g_target_rec.supplier_site_code -- �d����T�C�g�R�[�h
            , ov_vendor_name             => lt_vendor_name                  -- �d���於
            , ov_bank_charge_bearer      => lt_bank_charge_bearer           -- ��s�萔�����S��
            , ov_hold_all_payments_flag  => lt_hold_all_payments_flag       -- �S�x���ۗ̕��t���O
            , ov_ref_base_code           => lv_ref_base_code                -- DFF5(�⍇���S�����_�R�[�h)
            , ov_bm_kbn_dff4             => lv_bm_kbn_dff4                  -- DFF4(BM�x���敪)
            , ov_bank_number             => lt_bank_number                  -- ��s�ԍ�
            , ov_bank_name               => lt_bank_name                    -- ��s������
            , ov_bank_account_type       => lv_bank_account_type            -- �������
            , ov_bank_account_num        => lt_bank_account_num             -- ��s�����ԍ�
            , ov_account_holder_name_alt => lt_account_holder_name_alt      -- �������`�l�J�i
            , ov_bank_num                => lt_bank_num                     -- ��s�x�X�ԍ�
            , ov_bank_branch_name        => lt_bank_branch_name             -- ��s�x�X��
            , ov_account_name            => lt_ref_base_name                -- �⍇���S�����_��
            , ov_bm_kbn                  => lv_bm_kbn                       -- BM�x���敪
            , ov_bm_kbn_nm               => lv_bm_kbn_nm                    -- BM�x���敪��
            , ov_bk_account_type         => lv_bk_account_type              -- �������
            , ov_bk_account_type_nm      => lv_bk_account_type_nm           -- ������ʖ�
-- Ver.1.24 ADD START
            , ov_bm_tax_kbn_name         => lv_bm_tax_kbn_name              -- BM�ŋ敪��
-- Ver.1.24 ADD END
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        IF ( ln_loop_cnt = 1 )
          OR ( g_target_rec.base_code <> gt_selling_base_code_bk )
          OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
          -- ===============================================
          -- �̎�G���[��񒊏o����(A-5)
          -- ===============================================
          get_bm_contract_err(
              ov_errbuf            => lv_errbuf                       -- �G���[�E���b�Z�[�W
            , ov_retcode           => lv_retcode                      -- ���^�[���E�R�[�h
            , ov_errmsg            => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            , iv_selling_base_code => g_target_rec.base_code          -- ����v�㋒�_�R�[�h
            , iv_cust_code         => g_target_rec.cust_code          -- �ڋq�R�[�h
            , on_error_count       => ln_error_count                  -- �G���[�J�E���g
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===============================================
        -- �u���C�N���菈��(A-6)
        -- ===============================================
        break_judge(
            ov_errbuf                  => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                 => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                  => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_target_rec               => g_target_rec               -- �J�[�\�����R�[�h
          , it_bank_charge_bearer      => lt_bank_charge_bearer      -- ��s�萔�����S��
          , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- �S�x���ۗ̕��t���O
          , it_vendor_name             => lt_vendor_name             -- �d���於
          , it_bank_number             => lt_bank_number             -- ��s�ԍ�
          , it_bank_name               => lt_bank_name               -- ��s������
          , it_bank_num                => lt_bank_num                -- ��s�x�X�ԍ�
          , it_bank_branch_name        => lt_bank_branch_name        -- ��s�x�X��
          , iv_bank_account_type       => lv_bank_account_type       -- �������
          , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- ������ʖ�
          , it_bank_account_num        => lt_bank_account_num        -- ��s�����ԍ�
          , it_account_holder_name_alt => lt_account_holder_name_alt -- �������`�l�J�i
          , iv_ref_base_code           => lv_ref_base_code           -- DFF5(�⍇���S�����_�R�[�h)
          , it_selling_base_name       => lt_selling_base_name       -- ����v�㋒�_��
          , iv_bm_kbn                  => lv_bm_kbn                  -- BM�x���敪
          , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM�x���敪��
          , it_selling_base_code       => lt_selling_base_code       -- ����v�㋒�_�R�[�h
          , it_ref_base_name           => lt_ref_base_name           -- �⍇���S�����_��
          , it_account_number          => lt_account_number          -- �ڋq�R�[�h
          , it_party_name              => lt_party_name              -- �ڋq��
          , it_address3                => lt_address3                -- �n��R�[�h
          , in_error_count             => ln_error_count             -- �̎�G���[����
-- Ver.1.24 ADD START
          , iv_bm_tax_kbn_name         => lv_bm_tax_kbn_name         -- BM�ŋ敪��
-- Ver.1.24 ADD END
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP main_loop;
-- Ver.1.22 ADD END
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki UPD END
    END IF;
--
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki DEL START
--    -- �̎�c�����擾�J�[�\��
--    <<main_loop>>
--    FOR g_target_rec IN g_target_cur( lv_target_disp_flg ) LOOP
----
--      ln_loop_cnt := ln_loop_cnt + 1;
----
--      IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.base_code <> gt_selling_base_code_bk ) THEN
--        -- ===============================================
--        -- ���㋒�_��񒊏o����(A-3)
--        -- ===============================================
--        get_cust_data(
--          ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W
--         ,ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h
--         ,ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
--         ,iv_process_flg        => cv_process_flg1         -- �����t���O(1�F���㋒�_���)
--         ,iv_selling_base_code  => g_target_rec.base_code  -- ���㋒�_
--         ,iv_cust_code          => g_target_rec.cust_code  -- �ڋq�R�[�h
--         ,ov_selling_base_code  => lt_selling_base_code    -- ����v�㋒�_�R�[�h
--         ,ov_account_name       => lt_selling_base_name    -- ����v�㋒�_��
--         ,ov_address3           => lt_address3             -- �n��R�[�h
--         ,ov_account_number     => lt_account_number_dummy -- �ڋq�R�[�h
--         ,ov_party_name         => lt_party_name_dummy     -- �ڋq��
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
--        -- ===============================================
--        -- �ڋq��񒊏o����(A-3)
--        -- ===============================================
--        get_cust_data(
--          ov_errbuf             => lv_errbuf                  -- �G���[�E���b�Z�[�W
--         ,ov_retcode            => lv_retcode                 -- ���^�[���E�R�[�h
--         ,ov_errmsg             => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--         ,iv_process_flg        => cv_process_flg2            -- �����t���O(2�F�ڋq���)
--         ,iv_selling_base_code  => g_target_rec.base_code     -- ���㋒�_
--         ,iv_cust_code          => g_target_rec.cust_code     -- �ڋq�R�[�h
--         ,ov_selling_base_code  => lt_selling_base_code_dummy -- ����v�㋒�_�R�[�h
--         ,ov_account_name       => lt_selling_base_name_dummy -- ����v�㋒�_��
--         ,ov_address3           => lt_address3_dummy          -- �n��R�[�h
--         ,ov_account_number     => lt_account_number          -- �ڋq�R�[�h
--         ,ov_party_name         => lt_party_name              -- �ڋq��
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      IF ( ln_loop_cnt = 1 ) OR ( g_target_rec.supplier_code <> gt_payment_code_bk ) THEN
--        -- ===============================================
--        -- �d����E��s��񒊏o����(A-4)
--        -- ===============================================
--        get_vendor_data(
--            ov_errbuf                  => lv_errbuf                       -- �G���[�E���b�Z�[�W
--          , ov_retcode                 => lv_retcode                      -- ���^�[���E�R�[�h
--          , ov_errmsg                  => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
--          , iv_supplier_code           => g_target_rec.supplier_code      -- �d����R�[�h
--          , iv_supplier_site_code      => g_target_rec.supplier_site_code -- �d����T�C�g�R�[�h
--          , ov_vendor_name             => lt_vendor_name                  -- �d���於
--          , ov_bank_charge_bearer      => lt_bank_charge_bearer           -- ��s�萔�����S��
--          , ov_hold_all_payments_flag  => lt_hold_all_payments_flag       -- �S�x���ۗ̕��t���O
--          , ov_ref_base_code           => lv_ref_base_code                -- DFF5(�⍇���S�����_�R�[�h)
--          , ov_bm_kbn_dff4             => lv_bm_kbn_dff4                  -- DFF4(BM�x���敪)
--          , ov_bank_number             => lt_bank_number                  -- ��s�ԍ�
--          , ov_bank_name               => lt_bank_name                    -- ��s������
--          , ov_bank_account_type       => lt_bank_account_type            -- �������
--          , ov_bank_account_num        => lt_bank_account_num             -- ��s�����ԍ�
--          , ov_account_holder_name_alt => lt_account_holder_name_alt      -- �������`�l�J�i
--          , ov_bank_num                => lt_bank_num                     -- ��s�x�X�ԍ�
--          , ov_bank_branch_name        => lt_bank_branch_name             -- ��s�x�X��
--          , ov_account_name            => lt_ref_base_name                -- �⍇���S�����_��
--          , ov_bm_kbn                  => lv_bm_kbn                       -- BM�x���敪
--          , ov_bm_kbn_nm               => lv_bm_kbn_nm                    -- BM�x���敪��
--          , ov_bk_account_type         => lv_bk_account_type              -- �������
--          , ov_bk_account_type_nm      => lv_bk_account_type_nm           -- ������ʖ�
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      IF ( ln_loop_cnt = 1 )
--        OR ( g_target_rec.base_code <> gt_selling_base_code_bk )
--        OR ( g_target_rec.cust_code <> gt_cust_code_bk ) THEN
--        -- ===============================================
--        -- �̎�G���[��񒊏o����(A-5)
--        -- ===============================================
--        get_bm_contract_err(
--            ov_errbuf            => lv_errbuf                       -- �G���[�E���b�Z�[�W
--          , ov_retcode           => lv_retcode                      -- ���^�[���E�R�[�h
--          , ov_errmsg            => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
--          , iv_selling_base_code => g_target_rec.base_code          -- ����v�㋒�_�R�[�h
--          , iv_cust_code         => g_target_rec.cust_code          -- �ڋq�R�[�h
--          , on_error_count       => ln_error_count                  -- �G���[�J�E���g
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      -- ===============================================
--      -- �u���C�N���菈��(A-6)
--      -- ===============================================
--      break_judge(
--          ov_errbuf                  => lv_errbuf                  -- �G���[�E���b�Z�[�W
--        , ov_retcode                 => lv_retcode                 -- ���^�[���E�R�[�h
--        , ov_errmsg                  => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--        , i_target_rec               => g_target_rec               -- �J�[�\�����R�[�h
--        , it_bank_charge_bearer      => lt_bank_charge_bearer      -- ��s�萔�����S��
--        , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- �S�x���ۗ̕��t���O
--        , it_vendor_name             => lt_vendor_name             -- �d���於
--        , it_bank_number             => lt_bank_number             -- ��s�ԍ�
--        , it_bank_name               => lt_bank_name               -- ��s������
--        , it_bank_num                => lt_bank_num                -- ��s�x�X�ԍ�
--        , it_bank_branch_name        => lt_bank_branch_name        -- ��s�x�X��
--        , it_bank_account_type       => lt_bank_account_type       -- �������
--        , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- ������ʖ�
--        , it_bank_account_num        => lt_bank_account_num        -- ��s�����ԍ�
--        , it_account_holder_name_alt => lt_account_holder_name_alt -- �������`�l�J�i
--        , iv_ref_base_code           => lv_ref_base_code           -- DFF5(�⍇���S�����_�R�[�h)
--        , it_selling_base_name       => lt_selling_base_name       -- ����v�㋒�_��
--        , iv_bm_kbn                  => lv_bm_kbn                  -- BM�x���敪
--        , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM�x���敪��
--        , it_selling_base_code       => lt_selling_base_code       -- ����v�㋒�_�R�[�h
--        , it_ref_base_name           => lt_ref_base_name           -- �⍇���S�����_��
--        , it_account_number          => lt_account_number          -- �ڋq�R�[�h
--        , it_party_name              => lt_party_name              -- �ڋq��
--        , it_address3                => lt_address3                -- �n��R�[�h
--        , in_error_count             => ln_error_count             -- �̎�G���[����
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- 
----
--    END LOOP main_loop;
----
-- 2011/01/24 Ver.1.12 [��QE_�{�ғ�_06199] SCS S.Niki DEL END
    -- ===============================================
    -- �u���C�N���菈�� �ŏI�s(A-6)
    -- ===============================================
    break_judge(
        ov_errbuf                  => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                 => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                  => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_last_record_flg         => cv_flag_y                  -- �ŏI���R�[�h�t���O
      , i_target_rec               => g_target_rec               -- �J�[�\�����R�[�h
      , it_bank_charge_bearer      => lt_bank_charge_bearer      -- ��s�萔�����S��
      , it_hold_all_payments_flag  => lt_hold_all_payments_flag  -- �S�x���ۗ̕��t���O
      , it_vendor_name             => lt_vendor_name             -- �d���於
      , it_bank_number             => lt_bank_number             -- ��s�ԍ�
      , it_bank_name               => lt_bank_name               -- ��s������
      , it_bank_num                => lt_bank_num                -- ��s�x�X�ԍ�
      , it_bank_branch_name        => lt_bank_branch_name        -- ��s�x�X��
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD START
--      , it_bank_account_type       => lt_bank_account_type       -- �������
      , iv_bank_account_type       => lv_bank_account_type       -- �������
-- 2011/04/28 Ver.1.14 [��QE_�{�ғ�_02100] SCS S.Niki UPD END
      , iv_bk_account_type_nm      => lv_bk_account_type_nm      -- ������ʖ�
      , it_bank_account_num        => lt_bank_account_num        -- ��s�����ԍ�
      , it_account_holder_name_alt => lt_account_holder_name_alt -- �������`�l�J�i
      , iv_ref_base_code           => lv_ref_base_code           -- DFF5(�⍇���S�����_�R�[�h)
      , it_selling_base_name       => lt_selling_base_name       -- ����v�㋒�_��
      , iv_bm_kbn                  => lv_bm_kbn                  -- BM�x���敪
      , iv_bm_kbn_nm               => lv_bm_kbn_nm               -- BM�x���敪��
      , it_selling_base_code       => lt_selling_base_code       -- ����v�㋒�_�R�[�h
      , it_ref_base_name           => lt_ref_base_name           -- �⍇���S�����_��
      , it_account_number          => lt_account_number          -- �ڋq�R�[�h
      , it_party_name              => lt_party_name              -- �ڋq��
      , it_address3                => lt_address3                -- �n��R�[�h
      , in_error_count             => ln_error_count             -- �̎�G���[����
-- Ver.1.24 ADD START
      , iv_bm_tax_kbn_name         => lv_bm_tax_kbn_name         -- BM�ŋ敪��
-- Ver.1.24 ADD END
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �o�^����
    -- ===============================================
    IF ( ln_loop_cnt = 0 )
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
      OR ( gn_index = 0 )
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
      OR ( ( g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH = 0 )
       AND ( g_bm_balance_ttype( gn_index ).BM_THIS_MONTH = 0 )
       AND ( g_bm_balance_ttype( gn_index ).ELECTRIC_AMT = 0 ) ) THEN
      -- �Ώۃf�[�^�Ȃ�
      gn_target_cnt := 0;
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
      gn_index      := 1;
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
      --���ڂ̃N���A(�W�v�����O���܂ł̖����A����ѓ���BM�A�d�C����0�~�ȉ��̏ꍇ���l��)
      g_bm_balance_ttype( gn_index ).REF_BASE_CODE             := NULL;
      g_bm_balance_ttype( gn_index ).REF_BASE_NAME             := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_CODE              := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_NAME              := NULL;
      g_bm_balance_ttype( gn_index ).BANK_NO                   := NULL;
      g_bm_balance_ttype( gn_index ).BANK_NAME                 := NULL;
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NO            := NULL;
      g_bm_balance_ttype( gn_index ).BANK_BRANCH_NAME          := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE            := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_TYPE_NAME       := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NO              := NULL;
      g_bm_balance_ttype( gn_index ).BANK_ACCT_NAME            := NULL;
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD START
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_CODE           := NULL;
-- 2009/12/15 Ver.1.10 [��QE_�{�ғ�_00461] SCS K.Nakamura ADD END
      g_bm_balance_ttype( gn_index ).BM_PAYMENT_TYPE           := NULL;
      g_bm_balance_ttype( gn_index ).BANK_TRNS_FEE             := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_STOP              := NULL;
      g_bm_balance_ttype( gn_index ).SELLING_BASE_CODE         := NULL;
      g_bm_balance_ttype( gn_index ).SELLING_BASE_NAME         := NULL;
      g_bm_balance_ttype( gn_index ).WARNNING_MARK             := NULL;
      g_bm_balance_ttype( gn_index ).CUST_CODE                 := NULL;
      g_bm_balance_ttype( gn_index ).CUST_NAME                 := NULL;
      g_bm_balance_ttype( gn_index ).UNPAID_LAST_MONTH         := NULL;
      g_bm_balance_ttype( gn_index ).BM_THIS_MONTH             := NULL;
      g_bm_balance_ttype( gn_index ).ELECTRIC_AMT              := NULL;
      g_bm_balance_ttype( gn_index ).UNPAID_BALANCE            := NULL;
      g_bm_balance_ttype( gn_index ).RESV_PAYMENT              := NULL;
      g_bm_balance_ttype( gn_index ).PAYMENT_DATE              := NULL;
      g_bm_balance_ttype( gn_index ).CLOSING_DATE              := NULL;
      g_bm_balance_ttype( gn_index ).SELLING_BASE_SECTION_CODE := NULL;
-- Ver.1.24 ADD START
      g_bm_balance_ttype( gn_index ).BM_TAX_KBN_NAME           := NULL;
-- Ver.1.24 ADD END
      -- ===============================================
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      -- ===============================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�o�^(A-7)
      -- ===============================================
      ins_worktable_data(
          ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
        , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
        , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<ins_loop>>
      FOR i IN g_bm_balance_ttype.FIRST .. g_bm_balance_ttype.LAST LOOP
        -- ===============================================
        -- ���[�N�e�[�u���f�[�^�o�^(A-7)
        -- ===============================================
        ins_worktable_data(
          ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
        , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
        , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
        , in_index                 =>  i                        -- �C���f�b�N�X
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP ins_loop;
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD START
      -- ===============================================
      -- �x���X�e�[�^�X�u�����J�z�v�X�V����(A-10)
      -- ===============================================
      upd_resv_payment(
        ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
      , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
      , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD END
-- 2013/04/04 Ver.1.17 [��QE_�{�ғ�_10595,10609] SCSK K.Nakamura ADD START
      -- ===============================================
      -- �x���X�e�[�^�X�u�����ρv�X�V����(A-11)
      -- ===============================================
      upd_resv_payment_rec(
        ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
      , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
      , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- 2013/04/04 Ver.1.17 [��QE_�{�ғ�_10595,10609] SCSK K.Nakamura ADD END
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�X�V(A-12)
      -- ===============================================
      upd_worktable_data(
        ov_errbuf                =>  lv_errbuf                -- �G���[�o�b�t�@
      , ov_retcode               =>  lv_retcode               -- ���^�[���R�[�h
      , ov_errmsg                =>  lv_errmsg                -- �G���[���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                OUT VARCHAR2              -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2              -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_payment_date          IN  VARCHAR2 DEFAULT NULL -- �x����
  , iv_ref_base_code         IN  VARCHAR2 DEFAULT NULL -- �⍇���S�����_
  , iv_selling_base_code     IN  VARCHAR2 DEFAULT NULL -- ����v�㋒�_
  , iv_target_disp           IN  VARCHAR2 DEFAULT NULL -- �\���Ώ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  , iv_payment_code          IN  VARCHAR2 DEFAULT NULL -- �x����R�[�h
  , iv_resv_payment          IN  VARCHAR2 DEFAULT NULL -- �x���X�e�[�^�X
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(4) := 'init';        -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg     VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_retcode    BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
    lv_profile_nm VARCHAR2(40)   DEFAULT NULL;              -- �v���t�@�C�����̂̊i�[�p
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���������G���[ ***
    init_fail_expt             EXCEPTION; -- ���������G���[
    no_profile_expt            EXCEPTION; -- �v���t�@�C���l�擾�G���[
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �v���O�������͍��ڂ��o��
    -- ===============================================
    -- �x���N����
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00071
                 , iv_token_name1  => cv_token_pay_date
                 , iv_token_value1 => iv_payment_date
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_outmsg         --���b�Z�[�W
                  , in_new_line => cn_number_0       --���s
                  );
    -- �⍇���S�����_
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00073
                 , iv_token_name1  => cv_token_ref_base_cd
                 , iv_token_value1 => iv_ref_base_code
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_outmsg         --���b�Z�[�W
                  , in_new_line => cn_number_0       --���s
                  );
    -- ����v�㋒�_
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00074
                 , iv_token_name1  => cv_token_selling_base_cd
                 , iv_token_value1 => iv_selling_base_code
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_outmsg         --���b�Z�[�W
                  , in_new_line => cn_number_0       --���s
                  );
    -- �\���Ώ�
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00075
                 , iv_token_name1  => cv_token_target_disp
                 , iv_token_value1 => iv_target_disp
                 );
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    -- �x����R�[�h
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00094
                 , iv_token_name1  => cv_token_payment_cd
                 , iv_token_value1 => iv_payment_code
                 );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_outmsg         --���b�Z�[�W
                  , in_new_line => cn_number_0       --���s
                  );
    -- �x���X�e�[�^�X
    lv_outmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcok_appl_short_name
                 , iv_name         => cv_msg_code_00095
                 , iv_token_name1  => cv_token_resv_payment
                 , iv_token_value1 => iv_resv_payment
                 );
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_outmsg         --���b�Z�[�W
                  , in_new_line => cn_number_1       --���s
                  );
--
    -- ===============================================
    -- ���t�t�H�[�}�b�g�`�F�b�N
    -- ===============================================
    BEGIN
      gd_payment_date := TO_DATE( iv_payment_date, cv_format_yyyymmdd2 ); -- ���̓p�����[�^�̎x����
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10337
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END;
    -- ===============================================
    -- 2.	�\���Ώۃ`�F�b�N
    -- ===============================================
    -- ����v�㋒�_�ɒl���ݒ肳��Ă��邪�A�\���Ώۂɒl���ݒ肳��Ă��Ȃ�
    IF ( iv_selling_base_code IS NOT NULL )
       AND ( iv_target_disp IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10338
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END IF;
--
    -- �\���Ώۂɒl���ݒ肳��Ă��邪�A����v�㋒�_�ɒl���ݒ肳��Ă��Ȃ�
    IF ( iv_target_disp IS NOT NULL )
       AND ( iv_selling_base_code IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10338
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE init_fail_expt;
    END IF;
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL START
--    -- ===============================================
--    -- �������_�擾
--    -- ===============================================
--    gv_base_code := xxcok_common_pkg.get_base_code_f( SYSDATE , cn_created_by );
--    IF ( gv_base_code IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00012
--                    , iv_token_name1  => cv_token_user_id
--                    , iv_token_value1 => cn_created_by
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG
--                    , iv_message  => lv_errmsg
--                    , in_new_line => cn_number_0
--                    );
--      RAISE init_fail_expt;
--    END IF;
--    -- ===============================================
--    -- �v���t�@�C���擾(����R�[�h_�Ɩ��Ǘ���)
--    -- ===============================================
--    gv_aff2_dept_act := FND_PROFILE.VALUE( cv_prof_aff2_dept_act );
--    IF ( gv_aff2_dept_act IS NULL ) THEN
--      lv_profile_nm := cv_prof_aff2_dept_act;
--      RAISE no_profile_expt;
--    END IF;
-- 2009/10/02 Ver.1.9 [��QE_T3_00630] SCS S.Moriyama DEL END
    -- ===============================================
    -- �v���t�@�C���擾(�c���ꗗ_�G���[�}�[�N���o��)
    -- ===============================================
    gv_error_mark := FND_PROFILE.VALUE( cv_prof_error_mark );
    IF ( gv_error_mark IS NULL ) THEN
      lv_profile_nm := cv_prof_error_mark;
      RAISE no_profile_expt;
    END IF;
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    -- ===============================================
    -- �v���t�@�C���擾(�c���ꗗ_�ϓ��d�C�㖢���}�[�N���o��)
    -- ===============================================
    gv_unpaid_elec_mark := FND_PROFILE.VALUE( cv_prof_unpaid_elec_mark );
    IF ( gv_unpaid_elec_mark IS NULL ) THEN
      lv_profile_nm := cv_prof_unpaid_elec_mark;
      RAISE no_profile_expt;
    END IF;

-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    -- ===============================================
    -- �v���t�@�C���擾(�c���ꗗ_��~�����o��)
    -- ===============================================
    gv_pay_stop_name := FND_PROFILE.VALUE( cv_prof_pay_stop_name );
    IF ( gv_pay_stop_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_stop_name;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�U���萔��_����)
    -- ===============================================
    gv_bk_trns_fee_we := FND_PROFILE.VALUE( cv_prof_bk_trns_fee_we );
    IF ( gv_bk_trns_fee_we IS NULL ) THEN
      lv_profile_nm := cv_prof_bk_trns_fee_we;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�U���萔��_�����)
    -- ===============================================
    gv_bk_trns_fee_ctpty := FND_PROFILE.VALUE( cv_prof_bk_trns_fee_ctpty );
    IF ( gv_bk_trns_fee_ctpty IS NULL ) THEN
      lv_profile_nm := cv_prof_bk_trns_fee_ctpty;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�c���ꗗ_�ۗ����o��)
    -- ===============================================
    gv_pay_res_name := FND_PROFILE.VALUE( cv_prof_pay_res_name );
    IF ( gv_pay_res_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_res_name;
      RAISE no_profile_expt;
    END IF;
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD START
    -- ===============================================
    -- �v���t�@�C���擾(�c���ꗗ_�����ό��o��)
    -- ===============================================
    gv_pay_rec_name := FND_PROFILE.VALUE( cv_prof_pay_rec_name );
    IF ( gv_pay_rec_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_rec_name;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�c���ꗗ_�����J�z���o��)
    -- ===============================================
    gv_pay_auto_res_name := FND_PROFILE.VALUE( cv_prof_pay_auto_res_name );
    IF ( gv_pay_auto_res_name IS NULL ) THEN
      lv_profile_nm := cv_prof_pay_auto_res_name;
      RAISE no_profile_expt;
    END IF;
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD START
    -- ===============================================
    -- �v���t�@�C���擾(��s�萔��(�U����z))
    -- ===============================================
    gn_trans_fee := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_trans_criterion ) );
    IF ( gn_trans_fee IS NULL ) THEN
      lv_profile_nm := cv_prof_trans_criterion;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(��s�萔���z(�����))
    -- ===============================================
    gn_less_fee := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_less_fee_criterion ) );
    IF ( gn_less_fee IS NULL ) THEN
      lv_profile_nm := cv_prof_less_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(��s�萔���z(��ȏ�))
    -- ===============================================
    gn_more_fee := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_more_fee_criterion ) );
    IF ( gn_more_fee IS NULL ) THEN
      lv_profile_nm := cv_prof_more_fee_criterion;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(����ŗ�)
    -- ===============================================
    gn_bm_tax := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_profile_nm := cv_prof_bm_tax;
      RAISE no_profile_expt;
    END IF;
-- 2013/01/29 Ver.1.16 [��QE_�{�ғ�_10381] SCSK K.Taniguchi ADD END
-- 2012/07/04 Ver.1.15 [��QE_�{�ғ�_08365] SCSK K.Onotsuka ADD END
    -- ===============================================
    -- �v���t�@�C���擾(�݌ɑg�D�R�[�h_�c�Ƒg�D)
    -- ===============================================
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
--    gv_org_code := FND_PROFILE.VALUE( cv_prof_org_code_sales );
--    IF ( gv_org_code IS NULL ) THEN
--      lv_profile_nm := cv_prof_org_code_sales;
--      RAISE no_profile_expt;
--    END IF;
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
    -- ===============================================
    -- �v���t�@�C���擾(�c�ƒP��ID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_nm := cv_prof_org_id;
      RAISE no_profile_expt;
    END IF;
    -- ===============================================
    -- �݌ɑg�DID�擾
    -- ===============================================
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi START
--    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_org_code );
--    IF ( gn_organization_id IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00013
--                    , iv_token_name1  => cv_token_org_code
--                    , iv_token_value1 => gv_org_code
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG
--                    , iv_message  => lv_errmsg
--                    , in_new_line => cn_number_0
--                    );
--      RAISE init_fail_expt;
--    END IF;
-- 2009/05/19 Ver.1.6 [��QT1_1070] SCS T.Taniguchi END
-- 2009/09/17 Ver.1.8 [��Q0001390] SCS S.Moriyama DEL START
--    -- ===============================================
--    -- ���_�Z�L�����e�B�[�`�F�b�N
--    -- ===============================================
--    IF ( gv_aff2_dept_act <> gv_base_code ) THEN
--      IF ( iv_selling_base_code IS NULL ) AND ( iv_ref_base_code IS NULL ) THEN
--        lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_xxcok_appl_short_name
--                      , iv_name         => cv_msg_code_10372
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG
--                      , iv_message  => lv_errmsg
--                      , in_new_line => cn_number_0
--                      );
--        RAISE init_fail_expt;
--      END IF;
--    END IF;
-- 2009/09/17 Ver.1.8 [��Q0001390] SCS S.Moriyama DEL END
    -- =============================================
    -- �Ɩ��������t�擾
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE init_fail_expt;
    END IF;
    -- =============================================
    -- ���̓p�����[�^�̕\���Ώۖ��擾
    -- =============================================
    IF ( iv_target_disp IS NOT NULL ) THEN
      SELECT ffvv.description
      INTO   gv_target_disp_nm
      FROM   fnd_flex_value_sets ffvs
            ,fnd_flex_values_vl  ffvv
      WHERE ffvs.flex_value_set_name = cv_set_name
      AND   ffvs.flex_value_set_id   = ffvv.flex_value_set_id
      AND   ffvv.enabled_flag        = cv_flag_y
      AND   ffvv.flex_value          = iv_target_disp
      ;
    END IF;
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    -- =============================================
    -- ���̓p�����[�^�̎x���X�e�[�^�X���擾
    -- =============================================
    IF ( iv_resv_payment IS NOT NULL ) THEN
      SELECT ffvv.description  AS resv_payment_nm
      INTO   gv_resv_payment_nm
      FROM   fnd_flex_value_sets ffvs
           , fnd_flex_values_vl  ffvv
      WHERE  ffvs.flex_value_set_name = cv_set_name_rp  -- �x���X�e�[�^�X
      AND    ffvs.flex_value_set_id   = ffvv.flex_value_set_id
      AND    ffvv.enabled_flag        = cv_flag_y
      AND    ffvv.flex_value          = iv_resv_payment
      ;
    END IF;
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    -- ===============================================
    -- ���̓p�����[�^�̑ޔ�
    -- ===============================================
    gv_ref_base_code     := iv_ref_base_code;     -- �⍇���S�����_
    gv_selling_base_code := iv_selling_base_code; -- ����v�㋒�_
    gv_target_disp       := iv_target_disp;       -- �\���Ώ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    gt_payment_code      := iv_payment_code;      -- �x����R�[�h
    gt_resv_payment      := iv_resv_payment;      -- �x���X�e�[�^�X
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
--
  EXCEPTION
    --*** �v���t�@�C���l�擾�G���[ ***
    WHEN no_profile_expt THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_appl_short_name,
                     iv_name         => cv_msg_code_00003,
                     iv_token_name1  => cv_token_profile,
                     iv_token_value1 => lv_profile_nm
                   );
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
    ov_errbuf                OUT VARCHAR2               -- �G���[�E���b�Z�[�W
  , ov_retcode               OUT VARCHAR2               -- ���^�[���E�R�[�h
  , ov_errmsg                OUT VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_payment_date          IN  VARCHAR2  DEFAULT NULL -- �x����
  , iv_ref_base_code         IN  VARCHAR2  DEFAULT NULL -- �⍇���S�����_
  , iv_selling_base_code     IN  VARCHAR2  DEFAULT NULL -- ����v�㋒�_
  , iv_target_disp           IN  VARCHAR2  DEFAULT NULL -- �\���Ώ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  , iv_payment_code          IN  VARCHAR2  DEFAULT NULL -- �x����R�[�h
  , iv_resv_payment          IN  VARCHAR2  DEFAULT NULL -- �x���X�e�[�^�X
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain';     -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      ov_errbuf                => lv_errbuf            -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode           -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_payment_date          => iv_payment_date      -- �x����
    , iv_ref_base_code         => iv_ref_base_code     -- �⍇���S�����_
    , iv_selling_base_code     => iv_selling_base_code -- ����v�㋒�_
    , iv_target_disp           => iv_target_disp       -- �\���Ώ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , iv_payment_code          => iv_payment_code      -- �x����R�[�h
    , iv_resv_payment          => iv_resv_payment      -- �x���X�e�[�^�X
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- �Ώۃf�[�^�擾(A-2)�E���Ϗ����擾(A-3)�E���[�N�e�[�u���f�[�^�o�^(A-4)
    -- ===============================================
    get_target_data(
      ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�m��
    -- ===============================================
    COMMIT;
    -- ===============================================
    -- SVF�N��(A-5)
    -- ===============================================
    start_svf(
      ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�폜(A-6)
    -- ===============================================
    del_worktable_data(
      ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
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
    errbuf                   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , retcode                  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , iv_payment_date          IN  VARCHAR2  -- 1:�x����
  , iv_ref_base_code         IN  VARCHAR2  -- 2:�⍇���S�����_
  , iv_selling_base_code     IN  VARCHAR2  -- 3:����v�㋒�_
  , iv_target_disp           IN  VARCHAR2  -- 4:�\���Ώ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
  , iv_payment_code          IN  VARCHAR2  -- 5:�x����R�[�h
  , iv_resv_payment          IN  VARCHAR2  -- 6:�x���X�e�[�^�X
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name        CONSTANT VARCHAR2(4) := 'main';         -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- �I�����b�Z�[�W�R�[�h
    lb_retcode       BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    -- ===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    , iv_which   => 'LOG'-- ���O�o��
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf                => lv_errbuf            -- �G���[�E���b�Z�[�W
    , ov_retcode               => lv_retcode           -- ���^�[���E�R�[�h
    , ov_errmsg                => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_payment_date          => iv_payment_date      -- �x����
    , iv_ref_base_code         => iv_ref_base_code     -- �⍇���S�����_
    , iv_selling_base_code     => iv_selling_base_code -- ����v�㋒�_
    , iv_target_disp           => iv_target_disp       -- �\���Ώ�
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD START
    , iv_payment_code          => iv_payment_code      -- �x����R�[�h
    , iv_resv_payment          => iv_resv_payment      -- �x���X�e�[�^�X
-- Ver.1.18 [��QE_�{�ғ�_10411] SCSK S.Niki ADD END
    );
    -- ===============================================
    -- �G���[�o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errmsg      -- ���b�Z�[�W
                    , in_new_line => cn_number_0    -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errbuf      -- ���b�Z�[�W
                    , in_new_line => cn_number_1    -- ���s
                    );
    END IF;
    -- ===============================================
    -- �Ώی����o��
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90000
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --�o�͋敪
                  , iv_message  => lv_outmsg        --���b�Z�[�W
                  , in_new_line => cn_number_0      --���s
                  );
    -- ===============================================
    -- ���������o��(�G���[�������A��������:0�� �G���[����:1��)
    -- ===============================================
    -- �Ώی�����0���̏ꍇ�A���팏����0���ɂ���
    IF gn_target_cnt = 0 THEN
      gn_normal_cnt := 0;
    END IF;
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
      gn_error_cnt  := cn_number_1;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90001
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --�o�͋敪
                  , iv_message  => lv_outmsg        --���b�Z�[�W
                  , in_new_line => cn_number_0      --���s
                  );
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90002
                  , iv_token_name1  => cv_token_count
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --�o�͋敪
                  , iv_message  => lv_outmsg        --���b�Z�[�W
                  , in_new_line => cn_number_1      --���s
                  );
    -- ===============================================
    -- �����I�����b�Z�[�W�o��
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    ELSIF ( lv_retcode = cv_status_warn )   THEN
      lv_message_code := cv_msg_code_90005;
    ELSIF ( lv_retcode = cv_status_error )  THEN
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG        --�o�͋敪
                  , iv_message  => lv_outmsg           --���b�Z�[�W
                  , in_new_line => cn_number_0         --���s
                  );
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
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
END XXCOK014A04R;
/
