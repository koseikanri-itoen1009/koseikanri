CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO010A02C(body)
 * Description      : �����̔��@�ݒu�_����o�^/�X�V��ʂɂ���ēo�^�E�X�V���ꂽ�����̔�
 *                    �@�ݒu�_�񏑏����ڋq�}�X�^�ɍX�V���܂��B�܂�BM�d��������d����}
 *                    �X�^�A��s�����}�X�^�A�̎�����}�X�^�ɓo�^�E�X�V���܂��B�܂��I�[�i�[
 *                    �ύX���w������Ă����ꍇ�A���������C���X�g�[���x�[�X�}�X�^�ɍX�V��
 *                    �܂��B
 * MD.050           : MD050_CSO_010_A02_�}�X�^�A�g�@�\
 *
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc             ��������(A-1)
 *  upd_cont_manage_bef    �_��Ǘ����X�V����(A-2)
 *  reg_vendor_if          �x���_�[����I/F�e�[�u���o�^����(A-5)
 *  reg_vendor             �d������o�^/�X�V����(A-6)
 *  confirm_reg_vendor     �d������o�^/�X�V�����m�F����(A-7)
 *  error_reg_vendor       �d������o�^/�X�V�G���[������(A-8)
 *  associate_vendor_id    �d����ID�֘A�t������(A-9)
 *  reg_backmargin         �̔��萔�����o�^/�X�V����(A-10)
 *  upd_install_at         �ݒu��ڋq���X�V����(A-11)
 *  upd_install_base       �������X�V����(A-12)
 *  upd_cont_manage_aft    �_����X�V����(A-13)
 *  submain                ���C�������v���V�[�W��
 *                           �_��Ǘ����擾����(A-3)
 *                           �d������擾����(A-4)
 *  main                   ���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-14)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-07    1.0   Kazuo.Satomura   �V�K�쐬
 *  2009-02-13          Kazuo.Satomura   �E�d����ύX���A�ύX�O�̌�����񂪑��݂��Ȃ��ꍇ
 *                                         �G���[�ƂȂ�Ȃ��悤�C��
 *                                       �EA-8�̃J�[�\���̏����ɗv���h�c��ǉ�
 *                                       �E�d�b�ԍ��̎s�O�ǔԂɃn�C�t����ǉ�
 *  2009-02-19          Kazuo.Satomura   ������Q�Ή�(�s�ID17)
 *                                       �E�����R�[�h�������͂̏ꍇ�AA-12�̏������s��Ȃ�
 *                                         �悤�C��
 *  2009-02-20          Kazuo.Satomura   ������Q�Ή�(�s�ID18,19,20)
 *                                       �E�l���z���Ȃ��ł����������1,2�̏ꍇ�́A�̎��
 *                                         ���}�X�^��o�^�X�V�ΏۂƂ���悤�C��
 *                                       �E�p�[�e�B�}�X�^���X�V����悤�C��
 *                                       �E�x���_�[����I/F�̗\���J�e�S���ɑg�D�h�c��ݒ�
 *  2009-02-23          Kazuo.Satomura   ������Q�Ή�(�s�ID24)
 *                                       �E��������敪��5�̏ꍇ�A�̎�����̓o�^�X�V���s
 *                                         ��Ȃ��悤�C��
 *  2009-02-24          Kazuo.Satomura   ������Q�Ή�(�s�ID26)
 *                                       �E���������}�X�^�p�~�p���ԃe�[�u���o�^�����ɁA��
 *                                         ���ԍ����ς�����ꍇ��ǉ�
 *  2009-03-06          Kazuo.Satomura   �����ۑ�Ή�
 *                                       �E�����}�X�^�X�V���ڂɁA�p�[�e�B�T�C�g�h�c��ǉ�
 *                                       �E�̎�����p�~�������Ɩ����������܂ނ悤�ɏC��
 *                                       �E�s�ID24�̏C�������
 *                                         (��������敪��5�̃P�[�X�������Ȃ�����)
 *                                       �E�̎�����̍쐬�X�V�����ύX
 *                                         (�a�l�P�`�R�̓��͂������A����0�̏ꍇ�͏������s
 *                                         ��Ȃ�)
 *  2009-03-24    1.1   Kazuo.Satomura   �V�X�e���e�X�g��Q(��Q�ԍ�T1_0135,0136,0140)
 *  2009-04-02    1.2   Kazuo.Satomura   �V�X�e���e�X�g��Q(��Q�ԍ�T1_0227)
 *  2009-04-08    1.3   Kazuo.Satomura   �V�X�e���e�X�g��Q(��Q�ԍ�T1_0287)
 *  2009-04-08    1.4   Kazuo.Satomura   �V�X�e���e�X�g��Q(��Q�ԍ�T1_0617)
 *  2009-04-27    1.5   Kazuo.Satomura   �V�X�e���e�X�g��Q(��Q�ԍ�T1_0766)
 *  2009-04-28    1.6   Kazuo.Satomura   �V�X�e���e�X�g��Q(��Q�ԍ�T1_0733)
 *  2009-05-01    1.7   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-15    1.8   Kazuo.Satomura   �V�X�e���e�X�g��Q(��Q�ԍ�T1_1010)
 *  2009-09-25    1.9   Daisuke.Abe      ���ʉۑ�IE548
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
  --
  --################################  �Œ蕔 END   ##################################
  --
  --#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
  --
  gv_out_msg           VARCHAR2(2000);
  gv_sep_msg           VARCHAR2(2000);
  gv_exec_user         VARCHAR2(100);
  gv_conc_name         VARCHAR2(30);
  gv_conc_status       VARCHAR2(30);
  gn_vendor_target_cnt NUMBER; -- �Ώی���(�d����捞)
  gn_mst_target_cnt    NUMBER; -- �Ώی���(�}�X�^�A�g)
  gn_vendor_normal_cnt NUMBER; -- ���팏��(�d����捞)
  gn_mst_normal_cnt    NUMBER; -- ���팏��(�}�X�^�A�g)
  gn_vendor_error_cnt  NUMBER; -- �G���[����(�d����捞)
  gn_mst_error_cnt     NUMBER; -- �G���[����(�}�X�^�A�g)
  gn_vendor_warn_cnt   NUMBER; -- �X�L�b�v����(�d����捞)
  gn_mst_warn_cnt      NUMBER; -- �X�L�b�v����(�}�X�^�A�g)
  --
  --################################  �Œ蕔 END   ##################################
  --
  --##########################  �Œ苤�ʗ�O�錾�� START  ###########################
  --
  --*** ���������ʗ�O ***
  global_process_expt EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt EXCEPTION;
  --
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO010A02C';                                    -- �p�b�P�[�W��
  cv_sales_appl_short_name  CONSTANT VARCHAR2(5)   := 'XXCSO';                                           -- �c�Ɨp�A�v���P�[�V�����Z�k��
  cn_number_zero            CONSTANT NUMBER        := 0;
  cn_number_one             CONSTANT NUMBER        := 1;
  cv_create_flag            CONSTANT VARCHAR2(1)   := 'I';
  cv_update_flag            CONSTANT VARCHAR2(1)   := 'U';
  cv_flag_yes               CONSTANT VARCHAR2(1)   := 'Y';                                               -- �t���OY
  cv_flag_no                CONSTANT VARCHAR2(1)   := 'N';                                               -- �t���ON
  cv_flag_off               CONSTANT VARCHAR2(1)   := '0';                                               -- �t���OOFF
  cv_flag_on                CONSTANT VARCHAR2(1)   := '1';                                               -- �t���OON
  cv_date_format1           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';                           -- ���t�t�H�[�}�b�g
  cv_date_format2           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD';                                      -- ���t�t�H�[�}�b�g
  cv_year_format            CONSTANT VARCHAR2(21)  := 'YYYY';                                            -- ���t�t�H�[�}�b�g�i�N�j
  cv_month_format           CONSTANT VARCHAR2(21)  := 'MM';                                              -- ���t�t�H�[�}�b�g�i���j
  cv_day_format             CONSTANT VARCHAR2(21)  := 'DD';                                              -- ���t�t�H�[�}�b�g�i���j
  cd_sysdate                CONSTANT DATE          := SYSDATE;                                           -- �V�X�e�����t
  cd_process_date           CONSTANT DATE          := xxccp_common_pkg2.get_process_date;                -- �Ɩ��������t
  cv_lang                   CONSTANT VARCHAR2(2)   := USERENV('LANG');                                   -- ����
  cn_org_id                 CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ���O�C���g�D�h�c
  cv_batch_proc_status_norm CONSTANT xxcso_contract_managements.batch_proc_status%TYPE := '0';           -- �o�b�`�����X�e�[�^�X������
  cv_batch_proc_status_coa  CONSTANT xxcso_contract_managements.batch_proc_status%TYPE := '1';           -- �o�b�`�����X�e�[�^�X���A�g��
  cv_batch_proc_status_err  CONSTANT xxcso_contract_managements.batch_proc_status%TYPE := '2';           -- �o�b�`�����X�e�[�^�X���G���[
  cv_status                 CONSTANT VARCHAR2(1)   := '1';                                               -- �X�e�[�^�X���m���
  cv_un_cooperate           CONSTANT VARCHAR2(1)   := '0';                                               -- �}�X�^�A�g�t���O�����A�g
  cv_finish_cooperate       CONSTANT VARCHAR2(1)   := '1';                                               -- �}�X�^�A�g�t���O���A�g��
  ct_bm_payment_type_no     CONSTANT xxcso_sp_decision_custs.bm_payment_type%TYPE := '5';                -- �x���Ȃ�
  ct_sp_dec_cust_class_bm1  CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '3';     -- �r�o�ꌈ�ڋq�a�l�P
  ct_sp_dec_cust_class_bm2  CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '4';     -- �r�o�ꌈ�ڋq�a�l�Q
  ct_sp_dec_cust_class_bm3  CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '5';     -- �r�o�ꌈ�ڋq�a�l�R
  ct_delivery_div_bm1       CONSTANT xxcso_destinations.delivery_div%TYPE                    := '1';     -- ���t��a�l�P
  ct_delivery_div_bm2       CONSTANT xxcso_destinations.delivery_div%TYPE                    := '2';     -- ���t��a�l�Q
  ct_delivery_div_bm3       CONSTANT xxcso_destinations.delivery_div%TYPE                    := '3';     -- ���t��a�l�R
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011'; -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00337'; -- �f�[�^�X�V�G���[
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00500'; -- �r�o�ꌈ�ڋq���݃G���[
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173'; -- �Q�ƃ^�C�v�Ȃ��G���[���b�Z�[�W
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00329'; -- �f�[�^�擾�G���[
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00330'; -- �f�[�^�o�^�G���[
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00383'; -- �V�[�P���X�擾�G���[
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00456'; -- �R���J�����g�N���G���[
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00457'; -- �R���J�����g�I���m�F�G���[
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00458'; -- �R���J�����g�ُ�I���G���[
  cv_tkn_number_11 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00459'; -- �R���J�����g�x���I���G���[
  cv_tkn_number_12 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00389'; -- �ڋq�}�X�^�X�V���G���[
  cv_tkn_number_13 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00343'; -- ����^�C�vID���o�G���[���b�Z�[�W
  cv_tkn_number_14 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00504'; -- �����}�X�^�X�V���G���[
  cv_tkn_number_15 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00505'; -- �Ώی������b�Z�[�W
  cv_tkn_number_16 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00506'; -- �����������b�Z�[�W
  cv_tkn_number_17 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00507'; -- �G���[�������b�Z�[�W
  cv_tkn_number_18 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I�����b�Z�[�W
  --
  -- �g�[�N���R�[�h
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_action           CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_error_message    CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_cont_manage_id   CONSTANT VARCHAR2(20) := 'CONT_MANAGE_ID';
  cv_tkn_sp_dec_head_id   CONSTANT VARCHAR2(20) := 'SP_DEC_HEAD_ID';
  cv_tkn_task_name        CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_key_name         CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_id           CONSTANT VARCHAR2(20) := 'KEY_ID';
  cv_tkn_api_name         CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg          CONSTANT VARCHAR2(20) := 'API_MSG';
  cv_tkn_proc_name        CONSTANT VARCHAR2(20) := 'PROC_NAME';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_sequence         CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  --
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1  CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg2  CONSTANT VARCHAR2(200) := 'cd_process_date = ';
  cv_debug_msg3  CONSTANT VARCHAR2(200) := '<< �_��Ǘ���� >>';
  cv_debug_msg4  CONSTANT VARCHAR2(200) := 'contract_management_id = ';
  cv_debug_msg5  CONSTANT VARCHAR2(200) := 'sp_decision_header_id  = ';
  cv_debug_msg6  CONSTANT VARCHAR2(200) := 'install_account_id     = ';
  cv_debug_msg7  CONSTANT VARCHAR2(200) := 'install_account_number = ';
  cv_debug_msg8  CONSTANT VARCHAR2(200) := 'install_party_name     = ';
  cv_debug_msg9  CONSTANT VARCHAR2(200) := 'install_postal_code    = ';
  cv_debug_msg10 CONSTANT VARCHAR2(200) := 'install_state          = ';
  cv_debug_msg11 CONSTANT VARCHAR2(200) := 'install_city           = ';
  cv_debug_msg12 CONSTANT VARCHAR2(200) := 'install_address1       = ';
  cv_debug_msg13 CONSTANT VARCHAR2(200) := 'install_address2       = ';
  cv_debug_msg14 CONSTANT VARCHAR2(200) := '<< �d������ >>';
  cv_debug_msg15 CONSTANT VARCHAR2(200) := 'supplier_id                  = ';
  cv_debug_msg16 CONSTANT VARCHAR2(200) := 'delivery_div                 = ';
  cv_debug_msg17 CONSTANT VARCHAR2(200) := 'payment_name                 = ';
  cv_debug_msg18 CONSTANT VARCHAR2(200) := 'payment_name_alt             = ';
  cv_debug_msg19 CONSTANT VARCHAR2(200) := 'bank_transfer_fee_charge_div = ';
  cv_debug_msg20 CONSTANT VARCHAR2(200) := 'belling_details_div          = ';
  cv_debug_msg21 CONSTANT VARCHAR2(200) := 'inquery_charge_hub_cd        = ';
  cv_debug_msg22 CONSTANT VARCHAR2(200) := 'post_code                    = ';
  cv_debug_msg23 CONSTANT VARCHAR2(200) := 'prefectures                  = ';
  cv_debug_msg24 CONSTANT VARCHAR2(200) := 'city_ward                    = ';
  cv_debug_msg25 CONSTANT VARCHAR2(200) := 'address_1                    = ';
  cv_debug_msg26 CONSTANT VARCHAR2(200) := 'address_2                    = ';
  cv_debug_msg27 CONSTANT VARCHAR2(200) := 'address_lines_phonetic       = ';
  cv_debug_msg28 CONSTANT VARCHAR2(200) := 'bank_number                  = ';
  cv_debug_msg29 CONSTANT VARCHAR2(200) := 'bank_name                    = ';
  cv_debug_msg30 CONSTANT VARCHAR2(200) := 'branch_number                = ';
  cv_debug_msg31 CONSTANT VARCHAR2(200) := 'branch_name                  = ';
  cv_debug_msg32 CONSTANT VARCHAR2(200) := 'bank_account_type            = ';
  cv_debug_msg33 CONSTANT VARCHAR2(200) := 'bank_account_number          = ';
  cv_debug_msg34 CONSTANT VARCHAR2(200) := 'bank_account_name_kana       = ';
  cv_debug_msg35 CONSTANT VARCHAR2(200) := 'bank_account_name_kanji      = ';
  cv_debug_msg36 CONSTANT VARCHAR2(200) := '<< �r�o�ꌈ�ڋq��� >>';
  cv_debug_msg37 CONSTANT VARCHAR2(200) := 'customer_id     = ';
  cv_debug_msg38 CONSTANT VARCHAR2(200) := 'bm_payment_type = ';
  cv_debug_msg39 CONSTANT VARCHAR2(200) := '<< �a����ږ� >>';
  cv_debug_msg40 CONSTANT VARCHAR2(200) := 'bank_account_type_name = ';
  cv_debug_msg41 CONSTANT VARCHAR2(200) := '<< �d������ >>';
  cv_debug_msg42 CONSTANT VARCHAR2(200) := 'vendor_number  = ';
  cv_debug_msg43 CONSTANT VARCHAR2(200) := 'vendor_site_id = ';
  cv_debug_msg44 CONSTANT VARCHAR2(200) := '<< �X�V�O������� >>';
  cv_debug_msg45 CONSTANT VARCHAR2(200) := 'bank_number = ';
  cv_debug_msg46 CONSTANT VARCHAR2(200) := 'bank_num    = ';
  cv_debug_msg47 CONSTANT VARCHAR2(200) := '<< �_�~�[������� >>';
  cv_debug_msg48 CONSTANT VARCHAR2(200) := 'bank_number = ';
  cv_debug_msg49 CONSTANT VARCHAR2(200) := 'bank_num    = ';
  cv_debug_msg50 CONSTANT VARCHAR2(200) := '<< �̔Ԏd����ԍ� >>';
  cv_debug_msg51 CONSTANT VARCHAR2(200) := 'vendor_number = ';
  cv_debug_msg52 CONSTANT VARCHAR2(200) := '<< �v���h�c >>';
  cv_debug_msg53 CONSTANT VARCHAR2(200) := 'request_id = ';
  cv_debug_msg54 CONSTANT VARCHAR2(200) := '<< �d����o�^�G���[��� >>';
  cv_debug_msg55 CONSTANT VARCHAR2(200) := 'vendor_name            = ';
  cv_debug_msg56 CONSTANT VARCHAR2(200) := 'error_reason           = ';
  cv_debug_msg57 CONSTANT VARCHAR2(200) := '<< �d����h�c >>';
  cv_debug_msg58 CONSTANT VARCHAR2(200) := 'vendor_id = ';
  cv_debug_msg59 CONSTANT VARCHAR2(200) := '<< �r�o�ꌈ�ڋq�h�c >>';
  cv_debug_msg60 CONSTANT VARCHAR2(200) := 'customer_id = ';
  cv_debug_msg61 CONSTANT VARCHAR2(200) := ' << �r�o�ꌈ��� >> ';
  cv_debug_msg62 CONSTANT VARCHAR2(200) := 'condition_business_type = ';
  cv_debug_msg63 CONSTANT VARCHAR2(200) := 'electricity_type        = ';
  cv_debug_msg64 CONSTANT VARCHAR2(200) := 'electricity_amount      = ';
  cv_debug_msg65 CONSTANT VARCHAR2(200) := 'sp_container_type       = ';
  cv_debug_msg66 CONSTANT VARCHAR2(200) := 'sales_price             = ';
  cv_debug_msg67 CONSTANT VARCHAR2(200) := 'bm1_bm_rate             = ';
  cv_debug_msg68 CONSTANT VARCHAR2(200) := 'bm1_bm_amount           = ';
  cv_debug_msg69 CONSTANT VARCHAR2(200) := 'bm2_bm_rate             = ';
  cv_debug_msg70 CONSTANT VARCHAR2(200) := 'bm2_bm_amount           = ';
  cv_debug_msg71 CONSTANT VARCHAR2(200) := 'bm3_bm_rate             = ';
  cv_debug_msg72 CONSTANT VARCHAR2(200) := 'bm3_bm_amount           = ';
  cv_debug_msg73 CONSTANT VARCHAR2(200) := 'bm_container_type       = ';
  cv_debug_msg74 CONSTANT VARCHAR2(200) := 'contract_number        = ';
  cv_debug_msg75 CONSTANT VARCHAR2(200) := 'discount_amt            = ';
  cv_debug_msg76 CONSTANT VARCHAR2(200) := ' << �d����o�^�����J�n�i�a�e�`�N���j >> ';
  cv_debug_msg77 CONSTANT VARCHAR2(200) := ' << �d����o�^�����I�� >> ';
  cv_debug_msg78 CONSTANT VARCHAR2(200) := ' << �d����o�^���������m�F�����J�n >> ';
  cv_debug_msg79 CONSTANT VARCHAR2(200) := ' << �d����o�^���������m�F�����I�� >> ';
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �_��Ǘ����\����
  TYPE g_mst_regist_info_rtype IS RECORD(
    -- �_��Ǘ����
     contract_management_id xxcso_contract_managements.contract_management_id%TYPE -- �����̔��@�ݒu�_�񏑂h�c
    ,contract_number        xxcso_contract_managements.contract_number%TYPE        -- �_�񏑔ԍ�
    ,sp_decision_header_id  xxcso_contract_managements.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    ,install_account_id     xxcso_contract_managements.install_account_id%TYPE     -- �ݒu��ڋq�h�c
    ,install_account_number xxcso_contract_managements.install_account_number%TYPE -- �ݒu��ڋq�R�[�h
    ,install_party_name     xxcso_contract_managements.install_party_name%TYPE     -- �ݒu��ڋq��
    ,install_postal_code    xxcso_contract_managements.install_postal_code%TYPE    -- �ݒu��X�֔ԍ�
    ,install_state          xxcso_contract_managements.install_state%TYPE          -- �ݒu��s���{��
    ,install_city           xxcso_contract_managements.install_city%TYPE           -- �ݒu��s��
    ,install_address1       xxcso_contract_managements.install_address1%TYPE       -- �ݒu��Z���P
    ,install_address2       xxcso_contract_managements.install_address2%TYPE       -- �ݒu��Z���Q
    ,install_date           xxcso_contract_managements.install_date%TYPE           -- �ݒu��
    ,install_code           xxcso_contract_managements.install_code%TYPE           -- �����R�[�h
    -- ���t����
    ,supplier_id                  xxcso_destinations.supplier_id%TYPE                  -- �d����h�c
    ,delivery_div                 xxcso_destinations.delivery_div%TYPE                 -- ���t��敪
    ,payment_name                 xxcso_destinations.payment_name%TYPE                 -- �x���於
    ,payment_name_alt             xxcso_destinations.payment_name_alt%TYPE             -- �x���於�J�i
    ,bank_transfer_fee_charge_div xxcso_destinations.bank_transfer_fee_charge_div%TYPE -- �U���萔�����S�敪
    ,belling_details_div          xxcso_destinations.belling_details_div%TYPE          -- �x�����׏��敪
    ,inquery_charge_hub_cd        xxcso_destinations.inquery_charge_hub_cd%TYPE        -- �⍇���S�����_�R�[�h
    ,post_code                    xxcso_destinations.post_code%TYPE                    -- �X�֔ԍ�
    ,prefectures                  xxcso_destinations.prefectures%TYPE                  -- �s���{��
    ,city_ward                    xxcso_destinations.city_ward%TYPE                    -- �s��
    ,address_1                    xxcso_destinations.address_1%TYPE                    -- �Z���P
    ,address_2                    xxcso_destinations.address_2%TYPE                    -- �Z���Q
    ,address_lines_phonetic       xxcso_destinations.address_lines_phonetic%TYPE       -- �d�b�ԍ�
    -- ��s�������
    ,bank_number             xxcso_bank_accounts.bank_number%TYPE             -- ��s�ԍ�
    ,bank_name               xxcso_bank_accounts.bank_name%TYPE               -- ��s��
    ,branch_number           xxcso_bank_accounts.branch_number%TYPE           -- �x�X�ԍ�
    ,branch_name             xxcso_bank_accounts.branch_name%TYPE             -- �x�X��
    ,bank_account_type       xxcso_bank_accounts.bank_account_type%TYPE       -- �������
    ,bank_account_number     xxcso_bank_accounts.bank_account_number%TYPE     -- �����ԍ�
    ,bank_account_name_kana  xxcso_bank_accounts.bank_account_name_kana%TYPE  -- �������`�J�i
    ,bank_account_name_kanji xxcso_bank_accounts.bank_account_name_kanji%TYPE -- �������`����
    ,bank_account_dummy_flag xxcso_bank_accounts.bank_account_dummy_flag%TYPE -- ��s�����_�~�[�t���O
  );
  --
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_proc'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_tkn_value_processdate CONSTANT VARCHAR2(30) := '�Ɩ����t';
    --
    -- *** ���[�J���ϐ� ***
    lv_msg_from VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ======================
    -- �Ɩ����t�`�F�b�N
    -- ======================
    IF (cd_process_date IS NULL) THEN
      -- �Ɩ����t�������͂̏ꍇ�G���[
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item              -- �g�[�N�R�[�h1
                     ,iv_token_value1 => cv_tkn_value_processdate -- �g�[�N���l1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG START ***
    -- �Ɩ����t�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(cd_process_date, 'YYYY/MM/DD') || CHR(10) || ''
    );
    -- *** DEBUG_LOG END ***
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END start_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_cont_manage_bef
   * Description      : �_��Ǘ����X�V����(A-2)
   ***********************************************************************************/
  PROCEDURE upd_cont_manage_bef(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_cont_manage_bef'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_value_cont_manage CONSTANT VARCHAR2(50) := '�_��Ǘ��e�[�u��';
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
    -- ==============================
    -- �_��Ǘ����X�V
    -- ==============================
    -- �����Ώی����J�E���g
    SELECT COUNT(1) count
    INTO   gn_vendor_target_cnt
    FROM   xxcso_contract_managements xcm
    WHERE  xcm.status         = cv_status
    AND    xcm.cooperate_flag = cv_un_cooperate
    ;
    --
    BEGIN
      UPDATE xxcso_contract_managements xcm -- �_��Ǘ��e�[�u��
      SET    xcm.batch_proc_status = cv_batch_proc_status_coa
      WHERE  xcm.status         = cv_status
      AND    xcm.cooperate_flag = cv_un_cooperate
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_cont_manage -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END upd_cont_manage_bef;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_vendor_if
   * Description      : �x���_�[����I/F�e�[�u���o�^����(A-5)
   ***********************************************************************************/
  PROCEDURE reg_vendor_if(
     it_mst_regist_info_rec IN         g_mst_regist_info_rtype -- �}�X�^�o�^���
    ,ov_errbuf              OUT NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_vendor_if';  -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_bank_account_type     CONSTANT VARCHAR2(30)                          := 'JP_BANK_ACCOUNT_TYPE'; -- �a����ڎQ�ƃR�[�h�^�C�v
    ct_dummy_bank            CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'XXCSO1_DUMMY_BANK';    -- �_�~�[��s�Q�ƃR�[�h�^�C�v
    ct_dummy_bank_number     CONSTANT fnd_lookup_values_vl.lookup_code%TYPE := 'BANK_NUMBER';          -- �_�~�[��s�N�C�b�N�R�[�h
    ct_dummy_bank_num        CONSTANT fnd_lookup_values_vl.lookup_code%TYPE := 'BANK_NUM';             -- �_�~�[�x�X�N�C�b�N�R�[�h
    cv_vendor_type           CONSTANT VARCHAR2(30)                          := 'VD';                   -- �d����^�C�v
    cv_country_code          CONSTANT VARCHAR2(30)                          := 'JP';                   -- ���R�[�h
    cv_currency_code         CONSTANT VARCHAR2(3)                           := 'JPY';                  -- �ʉ݃R�[�h
    cv_hyphen                CONSTANT VARCHAR2(1)                           := '-';
    cv_diagonal              CONSTANT VARCHAR2(1)                           := '/';
    cv_status                CONSTANT VARCHAR2(1)                           := '0';
    --
    -- �_�~�[�����p
    cv_dummy_bank_acct_name       CONSTANT ap_bank_accounts.bank_account_name%TYPE       := '�_�~�[��s/�c�ƃ_�~�[�x�X/����'; -- ��������
    cv_dummy_bank_acct_num        CONSTANT ap_bank_accounts.bank_account_num%TYPE        := 'D000001';        -- �����ԍ�
    cv_dummy_bank_acct_type       CONSTANT ap_bank_accounts.bank_account_type%TYPE       := '1';              -- �a�����
    cv_dummy_acct_holder_name     CONSTANT ap_bank_accounts.account_holder_name%TYPE     := '�c�ƃ_�~�[����'; -- �������`�l�� 
    cv_dummy_acct_holder_name_alt CONSTANT ap_bank_accounts.account_holder_name_alt%TYPE := '����ֳ��а����'; -- �������`�l���i�J�i�j
    --
    -- �g�[�N���p�萔
    cv_tkn_value_task_name1    CONSTANT VARCHAR2(50) := '�\����ږ��̂�';
    cv_tkn_value_task_name2    CONSTANT VARCHAR2(50) := '�_�~�[��s�R�[�h��';
    cv_tkn_value_task_name3    CONSTANT VARCHAR2(50) := '�_�~�[�x�X�R�[�h��';
    cv_tkn_value_action_vendor CONSTANT VARCHAR2(50) := '�d������';
    cv_tkn_value_action_bank   CONSTANT VARCHAR2(50) := '�������';
    cv_tkn_value_key_name      CONSTANT VARCHAR2(50) := '�d����h�c';
    cv_tkn_value_table         CONSTANT VARCHAR2(50) := '�x���_�[����I/F�e�[�u��';
    cv_tkn_value_sequence      CONSTANT VARCHAR2(40) := '�d����ԍ�';
    --
    -- *** ���[�J���ϐ� ***
    lt_customer_id             xxcso_sp_decision_custs.customer_id%TYPE;      -- �ڋq�h�c
    lt_bm_payment_type         xxcso_sp_decision_custs.bm_payment_type%TYPE;  -- �a�l�x���敪
    ln_sp_dec_custs_count      NUMBER;                                        -- �r�o�ꌈ�ڋq�e�[�u������
    lv_bank_account_type_name  fnd_lookup_values_vl.meaning%TYPE;             -- �a����ږ���
    lt_vendor_number           po_vendors.segment1%TYPE;                      -- �d����ԍ�
    lt_vendor_site_id          po_vendor_sites.vendor_site_id%TYPE;           -- �d����T�C�g�h�c
    ln_before_bank_count       NUMBER;                                        -- �ύX�O��������
    lt_bank_number             ap_bank_branches.bank_number%TYPE;             -- ��s�R�[�h
    lt_bank_num                ap_bank_branches.bank_num%TYPE;                -- �x�X�R�[�h
    lt_bank_account_name       ap_bank_accounts.bank_account_name%TYPE;       -- ��������
    lt_bank_account_num        ap_bank_accounts.bank_account_num%TYPE;        -- �����ԍ�
    lt_bank_account_type       ap_bank_accounts.bank_account_type%TYPE;       -- �a�����
    lt_account_holder_name     ap_bank_accounts.account_holder_name%TYPE;     -- �������`�l
    lt_account_holder_name_alt ap_bank_accounts.account_holder_name_alt%TYPE; -- �������`�l�i�J�i�j
    ld_start_date              ap_bank_account_uses.start_date%TYPE;          -- �L���J�n��
    ln_phone_number_length     NUMBER;                                        -- �d�b�ԍ��o�C�g��
    lv_area_code               VARCHAR2(100);                                 -- �s�O�ǔ�
    lv_phone_number            VARCHAR2(100);                                 -- �s���ǔ�
    ln_work_count              NUMBER := cn_number_zero;                      -- ���[�N�J�E���g
    --
    -- *** ���[�J���E�J�[�\�� ***
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    ln_sp_dec_custs_count := cn_number_zero;
    --
    -- ============================
    -- �r�o�ꌈ�ڋq�e�[�u���`�F�b�N
    -- ============================
    BEGIN
      SELECT xsd.customer_id     customer_id     -- �ڋq�h�c
            ,xsd.bm_payment_type bm_payment_type -- �a�l�x���敪
      INTO   lt_customer_id
            ,lt_bm_payment_type
      FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
      AND    xsd.sp_decision_customer_class = DECODE(it_mst_regist_info_rec.delivery_div
                                                    ,ct_delivery_div_bm1, ct_sp_dec_cust_class_bm1
                                                    ,ct_delivery_div_bm2, ct_sp_dec_cust_class_bm2
                                                    ,ct_delivery_div_bm3, ct_sp_dec_cust_class_bm3
                                                    ) -- �r�o�ꌈ�ڋq�敪
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �r�o�ꌈ�ڋq�����݂��Ȃ��ꍇ�͏����𒆒f����B
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03                              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_cont_manage_id                         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => it_mst_regist_info_rec.contract_management_id -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_sp_dec_head_id                         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => it_mst_regist_info_rec.sp_decision_header_id  -- �g�[�N���l2
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- *** DEBUG_LOG START ***
    -- �r�o�ꌈ�ڋq�������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg36 || CHR(10) ||
                 cv_debug_msg37 || lt_customer_id     || CHR(10) ||
                 cv_debug_msg38 || lt_bm_payment_type || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    IF (lt_bm_payment_type <> ct_bm_payment_type_no) THEN
      -- �a�l�x���敪��5�F�x���Ȃ��̏ꍇ�͏����͍s��Ȃ�
      -- ============================
      -- �a����ږ��擾
      -- ============================
      IF it_mst_regist_info_rec.bank_account_type IS NOT NULL THEN
        BEGIN
          SELECT flv.meaning bank_account_type_name -- �a����ږ�
          INTO   lv_bank_account_type_name
          FROM   fnd_lookup_values_vl flv -- �Q�ƃR�[�h
          WHERE  flv.lookup_type                            =  cv_bank_account_type
          AND    flv.lookup_code                            =  it_mst_regist_info_rec.bank_account_type
          AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
          AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
          AND    flv.enabled_flag                           = cv_flag_yes
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_task_name1  -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_bank_account_type     -- �g�[�N���l2
                         );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- *** DEBUG_LOG START ***
        -- �a����ږ������O�o��
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg39 || CHR(10) ||
                     cv_debug_msg40 || lv_bank_account_type_name || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
      END IF;
      --
      -- ===================
      -- �d�b�ԍ���������
      -- ===================
      /* 2009.09.25 D.Abe IE548�Ή� START */
      ---- �d�b�ԍ��̃o�C�g�����擾
      --ln_phone_number_length := LENGTHB(it_mst_regist_info_rec.address_lines_phonetic);
      ----
      ---- �ŏ��̃n�C�t���̂���o�C�g�����擾
      --ln_work_count := INSTRB(it_mst_regist_info_rec.address_lines_phonetic, cv_hyphen, 1);
      ----
      ---- �d�b�ԍ����s�O�ǔԂƎs���ǔԂɕ���
      --lv_area_code    := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, 1, ln_work_count);
      --lv_phone_number := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, ln_work_count + 1, ln_phone_number_length);
      lv_phone_number := it_mst_regist_info_rec.address_lines_phonetic;
      /* 2009.09.25 D.Abe IE548�Ή� END   */
      --
      IF lt_customer_id IS NOT NULL THEN
        -- �擾�����ڋq�h�c�����͂���Ă���ꍇ
        -- ================================
        -- �d����ԍ��E�d����T�C�g�h�c�擾
        -- ================================
        BEGIN
          SELECT pve.segment1       vendor_number  -- �d����ԍ�
                ,pvs.vendor_site_id vendor_site_id -- �d����T�C�g�h�c
          INTO   lt_vendor_number
                ,lt_vendor_site_id
          FROM   po_vendors      pve -- �d����
                ,po_vendor_sites pvs -- �d����T�C�g�r���[
          WHERE  pve.vendor_id = it_mst_regist_info_rec.supplier_id
          AND    pve.vendor_id = pvs.vendor_id
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_05                   -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_action                      -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_action_vendor         -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_key_name                    -- �g�[�N���R�[�h2
                           ,iv_token_value2 => cv_tkn_value_key_name              -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_key_id                      -- �g�[�N���R�[�h3
                           ,iv_token_value3 => it_mst_regist_info_rec.supplier_id -- �g�[�N���l3
                         );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- *** DEBUG_LOG START ***
        -- �d����������O�o��
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg41 || CHR(10) ||
                     cv_debug_msg42 || lt_vendor_number  || CHR(10) ||
                     cv_debug_msg43 || lt_vendor_site_id || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
        -- ================================
        -- �ύX�O�������擾
        -- ================================
        SELECT COUNT(1) count
        INTO   ln_before_bank_count
        FROM   ap_bank_account_uses aba -- ���������}�X�^�r���[
        WHERE  aba.vendor_id      = it_mst_regist_info_rec.supplier_id
        AND    aba.vendor_site_id = lt_vendor_site_id
        ;
        --
        IF ln_before_bank_count >= cn_number_one THEN
          -- �ύX�O�̌��������݂���ꍇ
          BEGIN
            SELECT bbr.bank_number                      bank_number             -- ��s�R�[�h
                  ,bbr.bank_num                         bank_num                -- �x�X�R�[�h
                  ,bac.bank_account_name                bank_account_name       -- ��������
                  ,bac.bank_account_num                 bank_account_num        -- �����ԍ�
                  ,bac.bank_account_type                bank_account_type       -- �a�����
                  ,bac.account_holder_name              account_holder_name     -- �������`�l
                  ,bac.account_holder_name_alt          account_holder_name_alt -- �������`�l�i�J�i�j
                  ,NVL(bau.start_date, cd_process_date) start_date              -- �L���J�n��
            INTO   lt_bank_number
                  ,lt_bank_num
                  ,lt_bank_account_name
                  ,lt_bank_account_num
                  ,lt_bank_account_type
                  ,lt_account_holder_name
                  ,lt_account_holder_name_alt
                  ,ld_start_date
            FROM   ap_bank_branches     bbr -- ��s�}�X�^
                  ,ap_bank_accounts     bac -- �����}�X�^�r���[
                  ,ap_bank_account_uses bau -- ���������}�X�^�r���[
            WHERE  bau.vendor_id                               =  it_mst_regist_info_rec.supplier_id
            AND    TRUNC(NVL(bau.start_date, cd_process_date)) <= TRUNC(cd_process_date)
            AND    bau.end_date                                IS NULL
            AND    bau.external_bank_account_id                =  bac.bank_account_id
            AND    bac.bank_branch_id                          =  bbr.bank_branch_id
            ;
            --
          EXCEPTION
            WHEN OTHERS THEN
              lv_errbuf := xxccp_common_pkg.get_msg(
                              iv_application  => cv_sales_appl_short_name           -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_number_05                   -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_action                      -- �g�[�N���R�[�h1
                             ,iv_token_value1 => cv_tkn_value_action_bank           -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_key_name                    -- �g�[�N���R�[�h2
                             ,iv_token_value2 => cv_tkn_value_key_name              -- �g�[�N���l2
                             ,iv_token_name3  => cv_tkn_key_id                      -- �g�[�N���R�[�h3
                             ,iv_token_value3 => it_mst_regist_info_rec.supplier_id -- �g�[�N���l3
                           );
              --
              RAISE global_api_expt;
              --
          END;
          --
          -- *** DEBUG_LOG START ***
          -- �X�V�O�����������O�o��
          fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => cv_debug_msg44 || CHR(10) ||
                       cv_debug_msg45 || lt_bank_number || CHR(10) ||
                       cv_debug_msg46 || lt_bank_num    || CHR(10) ||
                       ''
          );
          -- *** DEBUG_LOG END ***
          --
          IF ((NVL(it_mst_regist_info_rec.bank_number, fnd_api.g_miss_char) <> lt_bank_number)
            OR (NVL(it_mst_regist_info_rec.branch_number, fnd_api.g_miss_char) <> lt_bank_num)
            OR (NVL(it_mst_regist_info_rec.bank_account_number, fnd_api.g_miss_char) <> lt_bank_account_num))
          THEN
            -- �擾������s�E�x�X�R�[�h�ƕύX�O�̋�s�E�x�X�R�[�h�E�����ԍ����ς���Ă����ꍇ
            -- ===================================================
            -- �x���_�[����I/F�e�[�u���o�^�i���������}�X�^�p�~�p�j
            -- ===================================================
            BEGIN
              INSERT INTO xx03_vendors_interface(
                 vendors_interface_id         -- �d����C���^�[�t�F�[�X�h�c
                ,insert_update_flag           -- �ǉ��X�V�t���O
                ,vndr_vendor_id               -- �d����d����h�c
                ,vndr_vendor_name             -- �d����d���於
                ,vndr_segment1                -- �d����d����ԍ�
                ,vndr_vendor_type_lkup_code   -- �d����d����^�C�v
                ,vndr_vendor_name_alt         -- �d����d����J�i����
                ,site_vendor_site_id          -- �d����T�C�g�d����T�C�g�h�c
                ,site_vendor_site_code        -- �d����T�C�g�d����T�C�g��
                ,site_address_line1           -- �d����T�C�g���ݒn1
                ,site_address_line2           -- �d����T�C�g���ݒn2
                ,site_city                    -- �d����T�C�g�Z���E�S�s��
                ,site_state                   -- �d����T�C�g�Z���E�s���{��
                ,site_zip                     -- �d����T�C�g�Z���E�X�֔ԍ�
                ,site_country                 -- �d����T�C�g��
                ,site_area_code               -- �d����T�C�g�s�O�ǔ�
                ,site_phone                   -- �d����T�C�g�d�b�ԍ�
                ,site_bank_account_name       -- �d����T�C�g��������
                ,site_bank_account_num        -- �d����T�C�g�����ԍ�
                ,site_bank_num                -- �d����T�C�g��s�R�[�h
                ,site_bank_account_type       -- �d����T�C�g�a�����
                ,site_attribute_category      -- �d����T�C�g�\���J�e�S��
                ,site_attribute1              -- �d����T�C�g�\��1
                ,site_attribute3              -- �d����T�C�g�\��3
                ,site_attribute4              -- �d����T�C�g�\��4
                ,site_attribute5              -- �d����T�C�g�\��5
                ,site_bank_number             -- �d����T�C�g��s�x�X�R�[�h
                ,site_vendor_site_code_alt    -- �d����T�C�g�d����T�C�g���i�J�i�j
                ,site_bank_charge_bearer      -- �d����T�C�g��s�萔�����S��
                ,acnt_bank_number             -- ��s������s�x�X�R�[�h
                ,acnt_bank_num                -- ��s������s�R�[�h
                ,acnt_bank_account_name       -- ��s������������
                ,acnt_bank_account_num        -- ��s���������ԍ�
                ,acnt_currency_code           -- ��s�����ʉ݃R�[�h
                ,acnt_bank_account_type       -- ��s�����a�����
                ,acnt_account_holder_name     -- ��s�����������`�l��
                ,acnt_account_holder_name_alt -- ��s�����������`�l���i�J�i�j
                ,uses_start_date              -- ��s���������J�n��
                ,uses_end_date                -- ��s���������I����
                ,status_flag                  -- �X�e�[�^�X�t���O
                ,creation_date                -- �쐬��
                ,created_by                   -- �쐬��
                ,last_update_date             -- �ŏI�X�V��
                ,last_updated_by              -- �ŏI�X�V��
                ,last_update_login            -- �ŏI�X�V���O�C��
                ,request_id                   -- ���N�G�X�g�h�c
                ,program_application_id       -- �v���O�����A�v���P�[�V�����h�c
                ,program_id                   -- �v���O�����h�c
                ,program_update_date          -- �v���O�����X�V��
              )
              VALUES(
                 xxcso_xx03_vendors_if_s01.NEXTVAL                             -- �d����C���^�[�t�F�[�X�h�c
                ,cv_update_flag                                                -- �ǉ��X�V�t���O
                ,it_mst_regist_info_rec.supplier_id                            -- �d����d����h�c
                ,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 80)           -- �d����d���於
                ,SUBSTRB(lt_vendor_number, 1, 30)                              -- �d����d����ԍ�
                ,SUBSTRB(cv_vendor_type, 1, 30)                                -- �d����d����^�C�v
                ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- �d����d����J�i����
                ,lt_vendor_site_id                                             -- �d����T�C�g�d����T�C�g�h�c
                ,SUBSTRB(lt_vendor_number, 1, 320)                             -- �d����T�C�g�d����T�C�g��
                ,SUBSTRB(it_mst_regist_info_rec.address_1, 1, 35)              -- �d����T�C�g���ݒn1
                ,SUBSTRB(it_mst_regist_info_rec.address_2, 1, 35)              -- �d����T�C�g���ݒn2
                ,SUBSTRB(it_mst_regist_info_rec.city_ward, 1, 25)              -- �d����T�C�g�Z���E�S�s��
                ,SUBSTRB(it_mst_regist_info_rec.prefectures, 1, 25)            -- �d����T�C�g�Z���E�s���{��
                ,SUBSTRB(it_mst_regist_info_rec.post_code, 1, 20)              -- �d����T�C�g�Z���E�X�֔ԍ�
                ,SUBSTRB(cv_country_code, 1, 25)                               -- �d����T�C�g��
                ,SUBSTRB(lv_area_code, 1, 10)                                  -- �d����T�C�g�s�O�ǔ�
                ,SUBSTRB(lv_phone_number, 1, 15)                               -- �d����T�C�g�d�b�ԍ�
                ,SUBSTRB(lt_bank_account_name, 1, 80)                          -- �d����T�C�g��������
                ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- �d����T�C�g�����ԍ�
                ,SUBSTRB(lt_bank_number, 1, 25)                                -- �d����T�C�g��s�R�[�h
                ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- �d����T�C�g�a�����
                ,cn_org_id                                                     -- �d����T�C�g�\���J�e�S��
                ,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 150)          -- �d����T�C�g�\��1
                ,SUBSTRB(cv_flag_yes, 1, 150)                                  -- �d����T�C�g�\��3
                ,SUBSTRB(it_mst_regist_info_rec.belling_details_div, 1, 150)   -- �d����T�C�g�\��4
                ,SUBSTRB(it_mst_regist_info_rec.inquery_charge_hub_cd, 1, 150) -- �d����T�C�g�\��5
                ,SUBSTRB(lt_bank_num, 1, 30)                                   -- �d����T�C�g�x�X�R�[�h
                ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- �d����T�C�g�d����T�C�g���i�J�i�j
                ,it_mst_regist_info_rec.bank_transfer_fee_charge_div           -- �d����T�C�g��s�萔�����S��
                ,SUBSTRB(lt_bank_num, 1, 30)                                   -- ��s������s�x�X�R�[�h
                ,SUBSTRB(lt_bank_number, 1, 25)                                -- ��s������s�R�[�h
                ,SUBSTRB(lt_bank_account_name, 1, 80)                          -- ��s������������
                ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- ��s���������ԍ�
                ,cv_currency_code                                              -- ��s�����ʉ݃R�[�h
                ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- ��s�����a�����
                ,SUBSTRB(lt_account_holder_name, 1, 240)                       -- ��s�����������`�l��
                ,SUBSTRB(lt_account_holder_name_alt, 1, 150)                   -- ��s�����������`�l���i�J�i�j
                ,ld_start_date                                                 -- ��s���������J�n��
                ,cd_process_date                                               -- ��s���������I����
                ,cv_status                                                     -- �X�e�[�^�X�t���O
                ,cd_creation_date                                              -- �쐬��
                ,cn_created_by                                                 -- �쐬��
                ,cd_last_update_date                                           -- �ŏI�X�V��
                ,cn_last_updated_by                                            -- �ŏI�X�V��
                ,cn_last_update_login                                          -- �ŏI�X�V���O�C��
                ,cn_request_id                                                 -- ���N�G�X�g�h�c
                ,cn_program_application_id                                     -- �v���O�����A�v���P�[�V�����h�c
                ,cn_program_id                                                 -- �v���O�����h�c
                ,cd_program_update_date                                        -- �v���O�����X�V��
              );
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                               ,iv_token_value1 => cv_tkn_value_table       -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                               ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                            );
                --
                RAISE global_api_expt;
                --
            END;
            --
          END IF;
          --
        END IF;
        --
      END IF;
      --
      IF (it_mst_regist_info_rec.bank_account_dummy_flag = cv_flag_on) THEN
        -- ��s�����_�~�[�t���O��ON�̏ꍇ
        -- ================================
        -- �_�~�[��s�R�[�h�擾
        -- ================================
        BEGIN
          SELECT flv.meaning bank_number -- ��s�R�[�h
          INTO   lt_bank_number
          FROM   fnd_lookup_values_vl flv -- �Q�ƃR�[�h
          WHERE  flv.lookup_type                            =  ct_dummy_bank
          AND    flv.lookup_code                            =  ct_dummy_bank_number
          AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
          AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
          AND    flv.enabled_flag                           = cv_flag_yes
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_task_name2  -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                           ,iv_token_value2 => ct_dummy_bank            -- �g�[�N���l2
                         );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- ================================
        -- �_�~�[�x�X�R�[�h�擾
        -- ================================
        BEGIN
          SELECT flv.meaning bank_number -- �x�X�R�[�h
          INTO   lt_bank_num
          FROM   fnd_lookup_values_vl flv -- �Q�ƃR�[�h
          WHERE  flv.lookup_type                            =  ct_dummy_bank
          AND    flv.lookup_code                            =  ct_dummy_bank_num
          AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
          AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
          AND    flv.enabled_flag                           = cv_flag_yes
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_task_name3  -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                           ,iv_token_value2 => ct_dummy_bank            -- �g�[�N���l2
                         );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- *** DEBUG_LOG START ***
        -- �_�~�[�����������O�o��
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg47 || CHR(10) ||
                     cv_debug_msg48 || lt_bank_number || CHR(10) ||
                     cv_debug_msg49 || lt_bank_num    || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
        lt_bank_account_name       := cv_dummy_bank_acct_name;       -- ��������
        lt_bank_account_num        := cv_dummy_bank_acct_num;        -- �����ԍ�
        lt_bank_account_type       := cv_dummy_bank_acct_type;       -- �a�����
        lt_account_holder_name     := cv_dummy_acct_holder_name;     -- �������`�l��
        lt_account_holder_name_alt := cv_dummy_acct_holder_name_alt; -- �������`�l���i�J�i�j
        --
      ELSE
        lt_bank_number             := it_mst_regist_info_rec.bank_number;             -- ��s�R�[�h
        lt_bank_num                := it_mst_regist_info_rec.branch_number;           -- ��s�x�X�R�[�h
        lt_bank_account_name       := it_mst_regist_info_rec.bank_name   || cv_diagonal ||
                                      it_mst_regist_info_rec.branch_name || cv_diagonal ||
                                      lv_bank_account_type_name;                      -- ��������
        lt_bank_account_num        := it_mst_regist_info_rec.bank_account_number;     -- �����ԍ�
        lt_bank_account_type       := it_mst_regist_info_rec.bank_account_type;       -- �a�����
        lt_account_holder_name     := it_mst_regist_info_rec.bank_account_name_kanji; -- �������`�l��
        lt_account_holder_name_alt := it_mst_regist_info_rec.bank_account_name_kana;  -- �������`�l���i�J�i�j
        --
      END IF;
      --
      -- ===================================================
      -- �x���_�[����I/F�e�[�u���o�^�i�o�^�E�X�V�p�j
      -- ===================================================
      IF lt_customer_id IS NULL THEN
        -- �ڋq�h�c��NULL�̏ꍇ�A�d����ԍ����̔�
        BEGIN
          SELECT xxcso_po_vendors_s01.NEXTVAL vendor_number
          INTO   lt_vendor_number
          FROM   DUAL
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_07         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_sequence          -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_sequence    -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- *** DEBUG_LOG START ***
        -- �̔Ԃ����d����ԍ������O�o��
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg50 || CHR(10) ||
                     cv_debug_msg51 || lt_vendor_number || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
      END IF;
      --
      BEGIN
        INSERT INTO xx03_vendors_interface(
           vendors_interface_id         -- �d����C���^�[�t�F�[�X�h�c
          ,insert_update_flag           -- �ǉ��X�V�t���O
          ,vndr_vendor_id               -- �d����d����h�c
          ,vndr_vendor_name             -- �d����d���於
          ,vndr_segment1                -- �d����d����ԍ�
          ,vndr_vendor_type_lkup_code   -- �d����d����^�C�v
          ,vndr_vendor_name_alt         -- �d����d����J�i����
          ,site_vendor_site_id          -- �d����T�C�g�d����T�C�g�h�c
          ,site_vendor_site_code        -- �d����T�C�g�d����T�C�g��
          ,site_address_line1           -- �d����T�C�g���ݒn1
          ,site_address_line2           -- �d����T�C�g���ݒn2
          ,site_city                    -- �d����T�C�g�Z���E�S�s��
          ,site_state                   -- �d����T�C�g�Z���E�s���{��
          ,site_zip                     -- �d����T�C�g�Z���E�X�֔ԍ�
          ,site_country                 -- �d����T�C�g��
          ,site_area_code               -- �d����T�C�g�s�O�ǔ�
          ,site_phone                   -- �d����T�C�g�d�b�ԍ�
          ,site_bank_account_name       -- �d����T�C�g��������
          ,site_bank_account_num        -- �d����T�C�g�����ԍ�
          ,site_bank_num                -- �d����T�C�g��s�R�[�h
          ,site_bank_account_type       -- �d����T�C�g�a�����
          ,site_attribute_category      -- �d����T�C�g�\���J�e�S��
          ,site_attribute1              -- �d����T�C�g�\��1
          ,site_attribute3              -- �d����T�C�g�\��3
          ,site_attribute4              -- �d����T�C�g�\��4
          ,site_attribute5              -- �d����T�C�g�\��5
          ,site_bank_number             -- �d����T�C�g��s�x�X�R�[�h
          ,site_vendor_site_code_alt    -- �d����T�C�g�d����T�C�g���i�J�i�j
          ,site_bank_charge_bearer      -- �d����T�C�g��s�萔�����S��
          ,acnt_bank_number             -- ��s������s�x�X�R�[�h
          ,acnt_bank_num                -- ��s������s�R�[�h
          ,acnt_bank_account_name       -- ��s������������
          ,acnt_bank_account_num        -- ��s���������ԍ�
          ,acnt_currency_code           -- ��s�����ʉ݃R�[�h
          ,acnt_bank_account_type       -- ��s�����a�����
          ,acnt_account_holder_name     -- ��s�����������`�l��
          ,acnt_account_holder_name_alt -- ��s�����������`�l���i�J�i�j
          ,uses_start_date              -- ��s���������J�n��
          ,status_flag                  -- �X�e�[�^�X�t���O
          ,creation_date                -- �쐬��
          ,created_by                   -- �쐬��
          ,last_update_date             -- �ŏI�X�V��
          ,last_updated_by              -- �ŏI�X�V��
          ,last_update_login            -- �ŏI�X�V���O�C��
          ,request_id                   -- ���N�G�X�g�h�c
          ,program_application_id       -- �v���O�����A�v���P�[�V�����h�c
          ,program_id                   -- �v���O�����h�c
          ,program_update_date          -- �v���O�����X�V��
        )
        VALUES(
           xxcso_xx03_vendors_if_s01.NEXTVAL                             -- �d����C���^�[�t�F�[�X�h�c
          ,DECODE(lt_customer_id
                 ,NULL, cv_create_flag
                 ,cv_update_flag)                                        -- �ǉ��X�V�t���O
          ,DECODE(lt_customer_id
                 ,NULL, NULL
                 ,it_mst_regist_info_rec.supplier_id)                    -- �d����d����h�c
          ,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 80)           -- �d����d���於
          ,SUBSTRB(lt_vendor_number, 1, 30)                              -- �d����d����ԍ�
          ,SUBSTRB(cv_vendor_type, 1, 30)                                -- �d����d����^�C�v
          ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- �d����d����J�i����
          ,DECODE(lt_customer_id
                 ,NULL, NULL
                 ,lt_vendor_site_id)                                     -- �d����T�C�g�d����T�C�g�h�c
          ,SUBSTRB(lt_vendor_number, 1, 320)                             -- �d����T�C�g�d����T�C�g��
          ,SUBSTRB(it_mst_regist_info_rec.address_1, 1, 35)              -- �d����T�C�g���ݒn1
          ,SUBSTRB(it_mst_regist_info_rec.address_2, 1, 35)              -- �d����T�C�g���ݒn2
          ,SUBSTRB(it_mst_regist_info_rec.city_ward, 1, 25)              -- �d����T�C�g�Z���E�S�s��
          ,SUBSTRB(it_mst_regist_info_rec.prefectures, 1, 25)            -- �d����T�C�g�Z���E�s���{��
          ,SUBSTRB(it_mst_regist_info_rec.post_code, 1, 20)              -- �d����T�C�g�Z���E�X�֔ԍ�
          ,SUBSTRB(cv_country_code, 1, 25)                               -- �d����T�C�g��
          ,SUBSTRB(lv_area_code, 1, 10)                                  -- �d����T�C�g�s�O�ǔ�
          ,SUBSTRB(lv_phone_number, 1, 15)                               -- �d����T�C�g�d�b�ԍ�
          ,SUBSTRB(it_mst_regist_info_rec.bank_name || cv_diagonal ||
           it_mst_regist_info_rec.branch_name       || cv_diagonal ||
           lt_bank_account_name, 1, 80)                                  -- �d����T�C�g��������
          ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- �d����T�C�g�����ԍ�
          ,SUBSTRB(lt_bank_number, 1, 25)                                -- �d����T�C�g��s�R�[�h
          ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- �d����T�C�g�a�����
          ,cn_org_id                                                     -- �d����T�C�g�\���J�e�S��
          ,SUBSTRB(it_mst_regist_info_rec.payment_name, 1, 150)          -- �d����T�C�g�\��1
          ,SUBSTRB(cv_flag_yes, 1, 150)                                  -- �d����T�C�g�\��3
          ,SUBSTRB(it_mst_regist_info_rec.belling_details_div, 1, 150)   -- �d����T�C�g�\��4
          ,SUBSTRB(it_mst_regist_info_rec.inquery_charge_hub_cd, 1, 150) -- �d����T�C�g�\��5
          ,SUBSTRB(lt_bank_num, 1, 30)                                   -- �d����T�C�g�x�X�R�[�h
          ,SUBSTRB(it_mst_regist_info_rec.payment_name_alt, 1, 320)      -- �d����T�C�g�d����T�C�g���i�J�i�j
          ,it_mst_regist_info_rec.bank_transfer_fee_charge_div           -- �d����T�C�g��s�萔�����S��
          ,SUBSTRB(lt_bank_num, 1, 30)                                   -- ��s������s�x�X�R�[�h
          ,SUBSTRB(lt_bank_number, 1, 25)                                -- ��s������s�R�[�h
          ,SUBSTRB(lt_bank_account_name, 1, 80)                          -- ��s������������
          ,SUBSTRB(lt_bank_account_num, 1, 30)                           -- ��s���������ԍ�
          ,cv_currency_code                                              -- ��s�����ʉ݃R�[�h
          ,SUBSTRB(lt_bank_account_type, 1, 25)                          -- ��s�����a�����
          ,SUBSTRB(lt_account_holder_name, 1, 240)                       -- ��s�����������`�l��
          ,SUBSTRB(lt_account_holder_name_alt, 1, 150)                   -- ��s�����������`�l���i�J�i�j
          ,cd_process_date                                               -- ��s���������J�n��
          ,cv_status                                                     -- �X�e�[�^�X�t���O
          ,cd_creation_date                                              -- �쐬��
          ,cn_created_by                                                 -- �쐬��
          ,cd_last_update_date                                           -- �ŏI�X�V��
          ,cn_last_updated_by                                            -- �ŏI�X�V��
          ,cn_last_update_login                                          -- �ŏI�X�V���O�C��
          ,cn_request_id                                                 -- ���N�G�X�g�h�c
          ,cn_program_application_id                                     -- �v���O�����A�v���P�[�V�����h�c
          ,cn_program_id                                                 -- �v���O�����h�c
          ,cd_program_update_date                                        -- �v���O�����X�V��
        );
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_table       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END reg_vendor_if;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_vendor
   * Description      : �d������o�^/�X�V����(A-6)
   ***********************************************************************************/
  PROCEDURE reg_vendor(
     on_request_id OUT NOCOPY NUMBER   -- �v���h�c
    ,ov_errbuf     OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_vendor';  -- �v���O������
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
    cv_application CONSTANT VARCHAR2(4)  := 'XX03';
    cv_program     CONSTANT VARCHAR2(20) := 'XX03PVI001C';
    cv_argument1   CONSTANT VARCHAR2(1)  := '0';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_proc_name CONSTANT VARCHAR2(100) := 'I009_XX03_�ڍs_�d����_�C���|�[�g����';
    --
    -- *** ���[�J���ϐ� ***
    ln_request_id NUMBER;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    -- *** DEBUG_LOG START ***
    -- �a�e�`�N���J�n�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg76 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    --
    -- ============================
    -- �����˗��w�b�_�E���דo�^����
    -- ============================
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_program
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => cv_argument1
                       ,argument2   => cd_process_date
                     );
    --
    IF (ln_request_id = 0) THEN
      -- �v���h�c��0�̏ꍇ�G���[���b�Z�[�W���擾���܂��B
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_08         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_proc_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h1
                     ,iv_token_value2 => lv_errbuf                -- �g�[�N���l1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    -- *** DEBUG_LOG START ***
    -- �a�e�`�N���I�������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg77 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    --
    -- *** DEBUG_LOG START ***
    -- �v���h�c�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg52 || CHR(10) ||
                 cv_debug_msg53 || ln_request_id || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    --
    on_request_id := ln_request_id;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : confirm_reg_vendor
   * Description      : �d������o�^/�X�V�����m�F����(A-7)
   ***********************************************************************************/
  PROCEDURE confirm_reg_vendor(
     in_request_id IN         NUMBER   -- �v���h�c
    ,ov_errbuf     OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode    OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg     OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'confirm_reg_vendor';  -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_profile_option_name1 CONSTANT VARCHAR2(30) := 'XXCSO1_MST_LINK_WAIT_TIME';
    cv_profile_option_name2 CONSTANT VARCHAR2(30) := 'XXCSO1_CONC_MAX_WAIT_TIME';
    --
    -- ���s�t�F�[�Y
    cv_phase_complete CONSTANT VARCHAR2(20) := 'COMPLETE'; -- ����
    --
    -- �g�[�N���p�萔
    cv_tkn_value_proc_name CONSTANT VARCHAR2(50) := 'I009_XX03_�ڍs_�d����_�C���|�[�g����';
    --
    -- *** ���[�J���ϐ� ***
    lb_return     BOOLEAN;
    lv_phase      VARCHAR2(5000);
    lv_status     VARCHAR2(5000);
    lv_dev_phase  VARCHAR2(5000);
    lv_dev_status VARCHAR2(5000);
    lv_message    VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    -- *** DEBUG_LOG START ***
    -- �d����o�^���������m�F�����J�n�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg78 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    --
    -- ================================
    -- �d������o�^/�X�V�����m�F
    -- ================================
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => in_request_id
                   ,interval   => fnd_profile.value(cv_profile_option_name1)
                   ,max_wait   => fnd_profile.value(cv_profile_option_name2)
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF NOT (lb_return) THEN
      -- �߂�l��FALSE�̏ꍇ
      fnd_message.retrieve(msgout => lv_errbuf);
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_09         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_proc_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h1
                     ,iv_token_value2 => lv_errbuf                -- �g�[�N���l1
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    -- *** DEBUG_LOG START ***
    -- �d����o�^���������m�F�����I�������O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg79 || CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    IF (lv_dev_phase <> cv_phase_complete) THEN
      -- ���s�t�F�[�Y������ȊO�̏ꍇ
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_proc_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_proc_name   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_proc_name         -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_dev_phase             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_proc_name         -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_dev_status            -- �g�[�N���l3
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END confirm_reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : error_reg_vendor
   * Description      : �d������o�^/�X�V�G���[������(A-8)
   ***********************************************************************************/
  PROCEDURE error_reg_vendor(
     it_contract_management_id IN         xxcso_contract_managements.contract_management_id%TYPE -- �����̔��@�ݒu�_�񏑂h�c
    ,it_contract_number        IN         xxcso_contract_managements.contract_number%TYPE        -- �_�񏑔ԍ�
    ,in_request_id             IN         NUMBER                                                 -- �v���h�c
    ,ov_err_flag               OUT NOCOPY VARCHAR2                                               -- �d����G���[�t���O
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'error_reg_vendor'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_msg_lookup_type CONSTANT VARCHAR2(100) := 'XX03_VENDOR_IF_ERROR_REASON';
    cv_status_flag     CONSTANT xx03_vendors_interface.status_flag%TYPE := 'E';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_cont_manage CONSTANT VARCHAR2(50) := '�_��Ǘ��e�[�u��';
    --
    -- *** ���[�J���ϐ� ***
    lv_update_flag VARCHAR2(1) := cv_flag_no; -- �X�V�σt���O
    --
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR destinations_cur
    IS
      SELECT xx03_get_error_message_pkg.get_error_message(cv_msg_lookup_type, xvi.error_reason) err_msg -- �G���[���R
            ,xvi.vndr_vendor_name vendor_name -- �d����d���於
      FROM   xxcso_destinations     xde -- ���t��e�[�u��
            ,xx03_vendors_interface xvi -- �x���_�[����I/F�e�[�u��
      WHERE  xde.contract_management_id = it_contract_management_id  -- �����̔��@�ݒu�_�񏑂h�c
      /* 2009.04.02 K.Satomura ��Q�ԍ�T1_0227�Ή� START */
      --AND    xvi.vndr_vendor_name       LIKE xde.payment_name || '%' -- �d���於
      AND    xvi.vndr_vendor_name       = xde.payment_name           -- �d���於
      /* 2009.04.02 K.Satomura ��Q�ԍ�T1_0227�Ή� END */
      AND    xvi.status_flag            = cv_status_flag             -- �X�e�[�^�X�t���O
      AND    xvi.request_id             = in_request_id              -- �v���h�c
      ;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    ov_err_flag := cv_flag_no;
    --
    -- ================================
    -- �G���[���擾
    -- ================================
    <<error_data_get_loop>>
    FOR lt_destinations_rec IN destinations_cur LOOP
      ov_err_flag := cv_flag_yes;
      --
      -- ================================
      -- �G���[���X�V
      -- ================================
      IF (lv_update_flag = cv_flag_no) THEN
        BEGIN
          UPDATE xxcso_contract_managements xcm -- �_��Ǘ��e�[�u��
          SET    xcm.batch_proc_status      = cv_batch_proc_status_err  -- �o�b�`�����X�e�[�^�X
                ,xcm.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
                ,xcm.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
                ,xcm.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
                ,xcm.request_id             = cn_request_id             -- �v��ID
                ,xcm.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,xcm.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
                ,xcm.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
          WHERE xcm.contract_management_id = it_contract_management_id -- �����̔��@�ݒu�_�񏑂h�c
          ;
          --
          lv_update_flag := cv_flag_yes;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_cont_manage -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      END IF;
      --
      -- *** DEBUG_LOG START ***
      -- �G���[���b�Z�[�W�����O�o��
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg54 || CHR(10) ||
                   cv_debug_msg74 || it_contract_number               || CHR(10) ||
                   cv_debug_msg55 || lt_destinations_rec.vendor_name  || CHR(10) ||
                   cv_debug_msg56 || lt_destinations_rec.err_msg      || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
    END LOOP error_data_get_loop;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END error_reg_vendor;
  --
  --
  /**********************************************************************************
   * Procedure Name   : associate_vendor_id
   * Description      : �d����ID�֘A�t������(A-9)
   ***********************************************************************************/
  PROCEDURE associate_vendor_id(
     it_contract_management_id IN         xxcso_contract_managements.contract_management_id%TYPE -- �����̔��@�ݒu�_�񏑂h�c
    ,it_sp_decision_header_id  IN         xxcso_contract_managements.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- �G���[�E���b�Z�[�W --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- ���^�[���E�R�[�h   --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'associate_vendor_id'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    /* 2009.04.27 K.Satomura T1_0766�Ή� START */
    cv_bm1_send_type_other CONSTANT xxcso_sp_decision_headers.bm1_send_type%TYPE := '3'; -- �a�l�P���t��敪=���̑�
    /* 2009.04.27 K.Satomura T1_0766�Ή� END */
    --
    -- �g�[�N���p�萔
    cv_tkn_value_action_vendor CONSTANT VARCHAR2(50) := '�d����h�c�֘A�t���������F�d����}�X�^';
    cv_tkn_value_key_name_ven  CONSTANT VARCHAR2(50) := '�x���於';
    cv_tkn_value_sp_dec_cust   CONSTANT VARCHAR2(50) := '�r�o�ꌈ�ڋq�e�[�u��';
    cv_tkn_value_key_name_sp   CONSTANT VARCHAR2(50) := '�r�o�ꌈ�w�b�_�h�c';
    cv_tkn_value_destination   CONSTANT VARCHAR2(50) := '���t��e�[�u��';
    /* 2009.04.27 K.Satomura T1_0766�Ή� START */
    cv_tkn_value_sp_dec_head   CONSTANT VARCHAR2(50) := '�r�o�ꌈ�w�b�_�e�[�u��';
    /* 2009.04.27 K.Satomura T1_0766�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    lt_vendor_id               po_vendors.vendor_id%TYPE;
    lt_sp_decision_customer_id xxcso_sp_decision_custs.sp_decision_customer_id%TYPE;
    lt_customer_id             xxcso_sp_decision_custs.customer_id%TYPE;
    --
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR destinations_cur
    IS
      SELECT xde.delivery_id  delivery_id  -- ���t��h�c
            ,xde.payment_name payment_name -- �x���於
            ,xde.delivery_div delivery_div -- ���t�敪
      FROM   xxcso_destinations xde -- ���t��e�[�u��
      WHERE  xde.contract_management_id = it_contract_management_id -- �����̔��@�ݒu�_�񏑂h�c
      ORDER BY xde.delivery_div ASC
      ;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ================================
    -- ���t��e�[�u���擾
    -- ================================
    <<destinations_loop>>
    FOR lt_destinations_rec IN destinations_cur LOOP
      lt_customer_id := NULL;
      --
      -- ================================
      -- �d����h�c�擾
      -- ================================
      BEGIN
        SELECT pve.vendor_id vendor_id -- �d����h�c
        INTO   lt_vendor_id
        FROM   po_vendors pve -- �d����}�X�^
        /* 2009.04.02 K.Satomura ��Q�ԍ�T1_0227�Ή� START */
        --WHERE  pve.vendor_name LIKE lt_destinations_rec.payment_name || '%'
        WHERE  pve.vendor_name = lt_destinations_rec.payment_name
        /* 2009.04.02 K.Satomura ��Q�ԍ�T1_0227�Ή� END */
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name         -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_05                 -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action                    -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_action_vendor       -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_key_name                  -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_value_key_name_ven        -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_key_id                    -- �g�[�N���R�[�h3
                         ,iv_token_value3 => lt_destinations_rec.payment_name -- �g�[�N���l3
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- *** DEBUG_LOG START ***
      -- �d����h�c�����O�o��
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg57 || CHR(10) ||
                   cv_debug_msg58 || lt_vendor_id || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
      -- ================================
      -- �r�o�ꌈ�ڋq�ڋq�h�c�X�V
      -- ================================
      BEGIN
        SELECT xsd.sp_decision_customer_id sp_decision_customer_id -- �r�o�ꌈ�ڋq�h�c
              ,xsd.customer_id             customer_id             -- �ڋq�h�c
        INTO   lt_sp_decision_customer_id
              ,lt_customer_id
        FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
        WHERE  xsd.sp_decision_header_id      = it_sp_decision_header_id -- �r�o�ꌈ�w�b�_�h�c
        AND    xsd.sp_decision_customer_class = DECODE(lt_destinations_rec.delivery_div
                                                      ,ct_delivery_div_bm1, ct_sp_dec_cust_class_bm1
                                                      ,ct_delivery_div_bm2, ct_sp_dec_cust_class_bm2
                                                      ,ct_delivery_div_bm3, ct_sp_dec_cust_class_bm3
                                                )
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_sp_dec_cust -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_tkn_value_key_name_sp -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                         ,iv_token_value3 => it_sp_decision_header_id -- �g�[�N���l3
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- *** DEBUG_LOG START ***
      -- �ڋq�h�c�����O�o��
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg59 || CHR(10)        ||
                   cv_debug_msg60 || lt_customer_id || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
      IF (lt_customer_id IS NULL) THEN
        -- �ڋq�h�c��NULL�̏ꍇ�̂݌ڋq�h�c�E�d����h�c���X�V����B
        BEGIN
          UPDATE xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
          SET    xsd.customer_id            = lt_vendor_id              -- �ڋq�h�c
                ,xsd.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
                ,xsd.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
                ,xsd.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
                ,xsd.request_id             = cn_request_id             -- �v��ID
                ,xsd.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,xsd.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
                ,xsd.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
          WHERE xsd.sp_decision_customer_id = lt_sp_decision_customer_id
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_sp_dec_cust -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
        -- ================================
        -- ���t��d����h�c�X�V
        -- ================================
        BEGIN
          UPDATE xxcso_destinations xde -- ���t��e�[�u��
          SET    xde.supplier_id            = lt_vendor_id              -- �d����h�c
                ,xde.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
                ,xde.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
                ,xde.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
                ,xde.request_id             = cn_request_id             -- �v��ID
                ,xde.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,xde.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
                ,xde.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
          WHERE xde.delivery_id = lt_destinations_rec.delivery_id -- ���t��h�c
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_destination -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      END IF;
      --
      /* 2009.04.27 K.Satomura T1_0766�Ή� START */
      IF (lt_destinations_rec.delivery_div = ct_delivery_div_bm1) THEN
        -- ���t��敪��1:BM1�̏ꍇ
        -- ================================
        -- �a�l�P���t��敪�X�V
        -- ================================
        BEGIN
          UPDATE xxcso_sp_decision_headers xsd -- �r�o�ꌈ�w�b�_�e�[�u��
          SET    xsd.bm1_send_type = cv_bm1_send_type_other -- �a�l�P���t��敪
          WHERE  xsd.sp_decision_header_id = it_sp_decision_header_id
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_sp_dec_head -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      END IF;
      /* 2009.04.27 K.Satomura T1_0766�Ή� END */
    END LOOP destinations_loop;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END associate_vendor_id;
  --
  --
  /**********************************************************************************
   * Procedure Name   : reg_backmargin
   * Description      : �̔��萔�����o�^/�X�V����(A-10)
   ***********************************************************************************/
  PROCEDURE reg_backmargin(
     it_sp_decision_header_id  IN         xxcso_contract_managements.sp_decision_header_id%TYPE  -- �r�o�ꌈ�w�b�_�h�c
    ,it_install_account_number IN         xxcso_contract_managements.install_account_number%TYPE -- �ݒu��ڋq�R�[�h
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'reg_backmargin'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_cond_business_type_01 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '1';   -- �����ʏ���
    cv_cond_business_type_02 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '2';   -- �����ʏ���[��t���o�^�p]
    cv_cond_business_type_03 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '3';   -- �ꗥ�E�e��ʏ���
    cv_cond_business_type_04 CONSTANT xxcso_sp_decision_headers.condition_business_type%TYPE := '4';   -- �ꗥ�E�e��ʏ���[��t���o�^�p]
    cv_electricity_type_1    CONSTANT xxcso_sp_decision_headers.electricity_type%TYPE        := '1';   -- ��z
    cv_sp_container_type_all CONSTANT xxcso_sp_decision_lines.sp_container_type%TYPE         := 'ALL'; -- �S�e��
    cv_electricity_amount_01 CONSTANT xxcso_sp_decision_headers.electricity_amount%TYPE      := '1';   -- ��z
    cv_calc_type_01          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '10';  -- �����ʏ���
    cv_calc_type_02          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '20';  -- �e��敪�ʏ���
    /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0136�� START */
    --cv_calc_type_03          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '40';  -- �藦����
    cv_calc_type_03          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '30';  -- �藦����
    /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0136�Ή� END */
    cv_calc_type_04          CONSTANT xxcok_mst_bm_contract.calc_type%TYPE                   := '50';  -- �d�C��(�Œ�)
    cv_lookup_type           CONSTANT fnd_lookup_values_vl.lookup_type%TYPE                  := 'XXCSO1_SP_RULE_BOTTLE';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_mst_bm  CONSTANT VARCHAR2(100) := '�̎�����}�X�^';
    cv_tkn_value_sp_info CONSTANT VARCHAR2(100) := '�̔��萔�����o�^/�X�V�������F�r�o�ꌈ�w�b�_�e�[�u���E�r�o�ꌈ����';
    cv_tkn_value_sp_id   CONSTANT VARCHAR2(100) := '�r�o�ꌈ�w�b�_�h�c';
    --
    -- *** ���[�J���ϐ� ***
    ln_sp_decision_count  NUMBER := 0;
    lt_electricity_type   xxcso_sp_decision_headers.electricity_type%TYPE;
    lt_electricity_amount xxcso_sp_decision_headers.electricity_amount%TYPE;
    lv_mst_bm_flag        VARCHAR2(1);
    ln_rowid              ROWID;
    lv_no_data_found_flag VARCHAR2(1);
    --
    -- *** ���[�J���J�[�\�� ***
    CURSOR sp_decision_cur
    IS
      SELECT sdh.condition_business_type condition_business_type -- ��������敪
            ,sdh.electricity_type        electricity_type        -- �d�C��敪
            ,sdh.electricity_amount      electricity_amount      -- �d�C��
            ,sdl.sp_container_type       sp_container_type       -- �r�o�e��敪
            ,sdl.sales_price             sales_price             -- ����
            ,sdl.discount_amt            discount_amt            -- �l���z
            ,sdl.bm1_bm_rate             bm1_bm_rate             -- �a�l���P
            ,sdl.bm1_bm_amount           bm1_bm_amount           -- �a�l�P���z
            ,sdl.bm2_bm_rate             bm2_bm_rate             -- �a�l���Q
            ,sdl.bm2_bm_amount           bm2_bm_amount           -- �a�l�Q���z
            ,sdl.bm3_bm_rate             bm3_bm_rate             -- �a�l���R
            ,sdl.bm3_bm_amount           bm3_bm_amount           -- �a�l�R���z
            ,lup.bm_container_type       bm_container_type       -- �̎�e��敪
      FROM   xxcso_sp_decision_headers sdh -- �r�o�ꌈ�w�b�_�e�[�u��
            ,xxcso_sp_decision_lines   sdl -- �r�o�ꌈ���׃e�[�u��
            ,(
               SELECT flv.lookup_code lookup_code
                     ,flv.attribute1  bm_container_type
               FROM   fnd_lookup_values_vl flv -- �Q�ƃR�[�h
               WHERE  flv.lookup_type                            =  cv_lookup_type
               AND    TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
               AND    TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
               AND    flv.enabled_flag                           =  cv_flag_yes
             ) lup
      WHERE  sdh.sp_decision_header_id =  it_sp_decision_header_id
      AND    sdh.sp_decision_header_id =  sdl.sp_decision_header_id
      AND    sdl.sp_container_type     =  lup.lookup_code(+)
      ;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ================================
    -- �̎�����}�X�^������
    -- ================================
    BEGIN
      UPDATE xxcok_mst_bm_contract xmb -- �̎�����}�X�^
      SET    xmb.calc_target_flag       = cv_flag_no                -- �v�Z�Ώۃt���O
            ,xmb.end_date_active        = cd_process_date           -- �L����(To)
            ,xmb.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,xmb.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,xmb.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,xmb.request_id             = cn_request_id             -- ���N�G�X�g�h�c
            ,xmb.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V�����h�c
            ,xmb.program_id             = cn_program_id             -- �v���O�����h�c
            ,xmb.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE xmb.cust_code                =  it_install_account_number -- �ڋq�R�[�h
      AND   xmb.calc_target_flag         =  cv_flag_yes               -- �v�Z�Ώۃt���O
      AND   TRUNC(xmb.start_date_active) <= TRUNC(cd_process_date)    -- �L����(From)
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_mst_bm      -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================
    -- �r�o�ꌈ���擾
    -- ================================
    <<sp_decision_info_loop>>
    FOR lt_sp_decision_rec IN sp_decision_cur LOOP
      ln_sp_decision_count  := ln_sp_decision_count + cn_number_one;
      lt_electricity_type   := lt_sp_decision_rec.electricity_type;
      lt_electricity_amount := lt_sp_decision_rec.electricity_amount;
      --
      -- *** DEBUG_LOG START ***
      -- �r�o�ꌈ�������O�o��
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg61 || CHR(10) ||
                   cv_debug_msg62 || lt_sp_decision_rec.condition_business_type || CHR(10) ||
                   cv_debug_msg63 || lt_sp_decision_rec.electricity_type        || CHR(10) ||
                   cv_debug_msg64 || lt_sp_decision_rec.electricity_amount      || CHR(10) ||
                   cv_debug_msg65 || lt_sp_decision_rec.sp_container_type       || CHR(10) ||
                   cv_debug_msg66 || lt_sp_decision_rec.sales_price             || CHR(10) ||
                   cv_debug_msg67 || lt_sp_decision_rec.bm1_bm_rate             || CHR(10) ||
                   cv_debug_msg68 || lt_sp_decision_rec.bm1_bm_amount           || CHR(10) ||
                   cv_debug_msg69 || lt_sp_decision_rec.bm2_bm_rate             || CHR(10) ||
                   cv_debug_msg70 || lt_sp_decision_rec.bm2_bm_amount           || CHR(10) ||
                   cv_debug_msg71 || lt_sp_decision_rec.bm3_bm_rate             || CHR(10) ||
                   cv_debug_msg72 || lt_sp_decision_rec.bm3_bm_amount           || CHR(10) ||
                   cv_debug_msg73 || lt_sp_decision_rec.bm_container_type       || CHR(10) ||
                   cv_debug_msg75 || lt_sp_decision_rec.discount_amt            || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
      IF (NVL(lt_sp_decision_rec.bm1_bm_rate, cn_number_zero) = cn_number_zero
        AND NVL(lt_sp_decision_rec.bm1_bm_amount, cn_number_zero) = cn_number_zero
        AND NVL(lt_sp_decision_rec.bm2_bm_rate, cn_number_zero) = cn_number_zero
        AND NVL(lt_sp_decision_rec.bm2_bm_amount, cn_number_zero) = cn_number_zero
        AND NVL(lt_sp_decision_rec.bm3_bm_rate, cn_number_zero) = cn_number_zero
        AND NVL(lt_sp_decision_rec.bm3_bm_amount, cn_number_zero) = cn_number_zero)
      THEN
        -- �a�l�P�`�R�̒l���S�Ė����͖��́A�O�̏ꍇ�͔̎�����̏������s��Ȃ�
        NULL;
        --
      ELSE
        IF ((lt_sp_decision_rec.condition_business_type IN (cv_cond_business_type_01, cv_cond_business_type_02))
          OR ((lt_sp_decision_rec.discount_amt IS NOT NULL)
          AND (lt_sp_decision_rec.condition_business_type IN (cv_cond_business_type_03, cv_cond_business_type_04))))
        THEN
          -- ======================================
          -- �̎�����}�X�^���݃`�F�b�N(���������)
          -- ======================================
          BEGIN
            SELECT ROWID row_id
            INTO   ln_rowid
            FROM   xxcok_mst_bm_contract xmb -- �̎�����}�X�^
            WHERE  xmb.cust_code = it_install_account_number -- �ڋq�R�[�h
            AND    xmb.calc_type = DECODE(lt_sp_decision_rec.condition_business_type
                                         ,cv_cond_business_type_01, cv_calc_type_01
                                         ,cv_cond_business_type_02, cv_calc_type_01
                                         ,cv_cond_business_type_03, DECODE(NVL(lt_sp_decision_rec.sp_container_type, fnd_api.g_miss_char)
                                                                          ,cv_sp_container_type_all, cv_calc_type_03
                                                                          ,cv_calc_type_02)
                                         ,cv_cond_business_type_04, DECODE(NVL(lt_sp_decision_rec.sp_container_type, fnd_api.g_miss_char)
                                                                          ,cv_sp_container_type_all, cv_calc_type_03
                                                                          ,cv_calc_type_02)
                                         ) -- �v�Z����
            AND    NVL(xmb.selling_price, fnd_api.g_miss_num)        = NVL(lt_sp_decision_rec.sales_price, fnd_api.g_miss_num) -- ����
            AND    NVL(xmb.container_type_code, fnd_api.g_miss_char) = NVL(lt_sp_decision_rec.bm_container_type, fnd_api.g_miss_char) -- �e��敪
            AND    TRUNC(xmb.start_date_active)                      = TRUNC(cd_process_date)               -- �L����(From)
            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0140�Ή� START */
            --AND    xmb.calc_target_flag                              = cv_flag_yes                          -- �v�Z�Ώۃt���O
            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0140�Ή� END */
            ;
            --
            lv_no_data_found_flag := cv_flag_no;
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_no_data_found_flag := cv_flag_yes;
              --
          END;
          --
          IF (lv_no_data_found_flag = cv_flag_yes) THEN
            -- �̎�����}�X�^�����݂��Ȃ��ꍇ
            -- ================================
            -- �̔��萔�����o�^(���������)
            -- ================================
            BEGIN
              INSERT INTO xxcok_mst_bm_contract(
                 bm_contract_id         -- �̎�����h�c
                ,cust_code              -- �ڋq�R�[�h
                ,calc_type              -- �v�Z����
                ,container_type_code    -- �e��敪
                ,selling_price          -- ����
                ,bm1_pct                -- BM1��(%)
                ,bm1_amt                -- BM1���z
                ,bm2_pct                -- BM2��(%)
                ,bm2_amt                -- BM2���z
                ,bm3_pct                -- BM3��(%)
                ,bm3_amt                -- BM3���z
                ,calc_target_flag       -- �v�Z�Ώۃt���O
                ,start_date_active      -- �L����(From)
                ,created_by             -- �쐬��
                ,creation_date          -- �쐬��
                ,last_updated_by        -- �ŏI�X�V��
                ,last_update_date       -- �ŏI�X�V��
                ,last_update_login      -- �ŏI�X�V���O�C��
                ,request_id             -- �v��ID
                ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id             -- �R���J�����g�E�v���O����ID
                ,program_update_date)   -- �v���O�����X�V��
              VALUES(
                 xxcok_mst_bm_contract_s01.NEXTVAL -- �̎�����h�c
                ,it_install_account_number         -- �ڋq�R�[�h
                ,DECODE(lt_sp_decision_rec.condition_business_type
                       ,cv_cond_business_type_01, cv_calc_type_01
                       ,cv_cond_business_type_02, cv_calc_type_01
                       ,cv_cond_business_type_03, DECODE(lt_sp_decision_rec.sp_container_type
                                                        ,cv_sp_container_type_all, cv_calc_type_03
                                                        ,cv_calc_type_02)
                       ,cv_cond_business_type_04, DECODE(lt_sp_decision_rec.sp_container_type
                                                        ,cv_sp_container_type_all, cv_calc_type_03
                                                        ,cv_calc_type_02)
                       ) -- �v�Z����
                ,DECODE(lt_sp_decision_rec.condition_business_type
                       ,cv_cond_business_type_03, lt_sp_decision_rec.bm_container_type
                       ,cv_cond_business_type_04, lt_sp_decision_rec.bm_container_type
                       ,NULL
                       ) -- �e��敪
                ,DECODE(lt_sp_decision_rec.condition_business_type
                       ,cv_cond_business_type_01, lt_sp_decision_rec.sales_price
                       ,cv_cond_business_type_02, lt_sp_decision_rec.sales_price
                       ,NULL
                       ) -- ����
                ,lt_sp_decision_rec.bm1_bm_rate   -- BM1��(%)
                ,lt_sp_decision_rec.bm1_bm_amount -- BM1���z
                ,lt_sp_decision_rec.bm2_bm_rate   -- BM2��(%)
                ,lt_sp_decision_rec.bm2_bm_amount -- BM2���z
                ,lt_sp_decision_rec.bm3_bm_rate   -- BM3��(%)
                ,lt_sp_decision_rec.bm3_bm_amount -- BM3���z
                ,cv_flag_yes                      -- �v�Z�Ώۃt���O
                ,cd_process_date                  -- �L����(From)
                ,cn_created_by                    -- �쐬��
                ,cd_creation_date                 -- �쐬��
                ,cn_last_updated_by               -- �ŏI�X�V��
                ,cd_last_update_date              -- �ŏI�X�V��
                ,cn_last_update_login             -- �ŏI�X�V���O�C��
                ,cn_request_id                    -- �v��ID
                ,cn_program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,cn_program_id                    -- �R���J�����g�E�v���O����ID
                ,cd_program_update_date           -- �v���O�����X�V��
              );
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                               ,iv_token_value1 => cv_tkn_value_mst_bm      -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                               ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                            );
                --
                RAISE global_api_expt;
                --
            END;
            --
          ELSE
            -- �̎�����}�X�^�����݂����ꍇ
            -- ================================
            -- �̔��萔�����X�V(���������)
            -- ================================
            BEGIN
              UPDATE xxcok_mst_bm_contract xmb -- �̎�����}�X�^
              SET    xmb.bm1_pct                = lt_sp_decision_rec.bm1_bm_rate   -- BM1��(%)
                    ,xmb.bm1_amt                = lt_sp_decision_rec.bm1_bm_amount -- BM1���z
                    ,xmb.bm2_pct                = lt_sp_decision_rec.bm2_bm_rate   -- BM2��(%)
                    ,xmb.bm2_amt                = lt_sp_decision_rec.bm2_bm_amount -- BM2���z
                    ,xmb.bm3_pct                = lt_sp_decision_rec.bm3_bm_rate   -- BM3��(%)
                    ,xmb.bm3_amt                = lt_sp_decision_rec.bm3_bm_amount -- BM3���z
                    ,xmb.calc_target_flag       = cv_flag_yes                      -- �v�Z�Ώۃt���O
                    ,xmb.last_updated_by        = cn_last_updated_by               -- �ŏI�X�V��
                    ,xmb.last_update_date       = cd_last_update_date              -- �ŏI�X�V��
                    ,xmb.last_update_login      = cn_last_update_login             -- �ŏI�X�V���O�C��
                    ,xmb.request_id             = cn_request_id                    -- �v��ID
                    ,xmb.program_application_id = cn_program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                    ,xmb.program_id             = cn_program_id                    -- �R���J�����g�E�v���O����ID
                    ,xmb.program_update_date    = cd_program_update_date           -- �v���O�����X�V��
              WHERE  ROWID = ln_rowid
              ;
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                               ,iv_token_value1 => cv_tkn_value_mst_bm      -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                               ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                            );
                --
                RAISE global_api_expt;
                --
            END;
            --
          END IF;
          --
        END IF;
        --
      END IF;
      --
      lt_sp_decision_rec := NULL;
      --
    END LOOP sp_decision_info_loop;
    --
    IF (ln_sp_decision_count <= cn_number_zero) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_sp_info     -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_tkn_value_sp_id       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                     ,iv_token_value3 => it_sp_decision_header_id -- �g�[�N���l3
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ========================================
    -- �̎�����}�X�^���݃`�F�b�N(�d�C��敪��)
    -- ========================================
    IF (lt_electricity_type =  cv_electricity_type_1) THEN
      -- �d�C��敪��1(��z)�̏ꍇ
      BEGIN
        SELECT ROWID row_id
        INTO   ln_rowid
        FROM   xxcok_mst_bm_contract xmb -- �̎�����}�X�^
        WHERE  xmb.cust_code                = it_install_account_number -- �ڋq�R�[�h
        AND    xmb.calc_type                = cv_calc_type_04           -- �v�Z����
        AND    TRUNC(xmb.start_date_active) = TRUNC(cd_process_date)    -- �L����(From)
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0140�Ή� START */
        --AND    xmb.calc_target_flag         = cv_flag_yes               -- �v�Z�Ώۃt���O
        /* 2009.04.27 K.Satomura ��Q�ԍ�T1_0766�Ή� START */
        --AND    xmb.calc_target_flag         = cv_flag_yes               -- �v�Z�Ώۃt���O
        /* 2009.04.27 K.Satomura ��Q�ԍ�T1_0766�Ή� START */
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0140�Ή� END */
        ;
        --
        lv_no_data_found_flag := cv_flag_no;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_no_data_found_flag := cv_flag_yes;
          --
      END;
      --
      IF (lv_no_data_found_flag = cv_flag_yes) THEN
        -- �̎�����}�X�^�����݂��Ȃ��ꍇ
        -- ================================
        -- �̔��萔�����o�^(�d�C��敪��)
        -- ================================
        BEGIN
          INSERT INTO xxcok_mst_bm_contract(
             bm_contract_id         -- �̎�����h�c
            ,cust_code              -- �ڋq�R�[�h
            ,calc_type              -- �v�Z����
            ,bm1_amt                -- BM1���z
            ,calc_target_flag       -- �v�Z�Ώۃt���O
            ,start_date_active      -- �L����(From)
            ,created_by             -- �쐬��
            ,creation_date          -- �쐬��
            ,last_updated_by        -- �ŏI�X�V��
            ,last_update_date       -- �ŏI�X�V��
            ,last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             -- �v��ID
            ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id             -- �R���J�����g�E�v���O����ID
            ,program_update_date)   -- �v���O�����X�V��
          VALUES(
             xxcok_mst_bm_contract_s01.NEXTVAL -- �̎�����h�c
            ,it_install_account_number         -- �ڋq�R�[�h
            ,cv_calc_type_04                   -- �v�Z����
            ,lt_electricity_amount             -- BM1���z
            ,cv_flag_yes                       -- �v�Z�Ώۃt���O
            ,cd_process_date                   -- �L����(From)
            ,cn_created_by                     -- �쐬��
            ,cd_creation_date                  -- �쐬��
            ,cn_last_updated_by                -- �ŏI�X�V��
            ,cd_last_update_date               -- �ŏI�X�V��
            ,cn_last_update_login              -- �ŏI�X�V���O�C��
            ,cn_request_id                     -- �v��ID
            ,cn_program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,cn_program_id                     -- �R���J�����g�E�v���O����ID
            ,cd_program_update_date            -- �v���O�����X�V��
          );
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_mst_bm      -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      ELSE
        -- �̎�����}�X�^�����݂����ꍇ
        -- ================================
        -- �̔��萔�����X�V(�d�C��敪��)
        -- ================================
        BEGIN
          UPDATE xxcok_mst_bm_contract xmb -- �̎�����}�X�^
          SET    xmb.bm1_amt                = lt_electricity_amount     -- BM1���z
                ,xmb.calc_target_flag       = cv_flag_yes               -- �v�Z�Ώۃt���O
                ,xmb.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
                ,xmb.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
                ,xmb.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
                ,xmb.request_id             = cn_request_id             -- �v��ID
                ,xmb.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,xmb.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
                ,xmb.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
          WHERE  ROWID = ln_rowid
          ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_tkn_value_mst_bm      -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                        );
            --
            RAISE global_api_expt;
            --
        END;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END reg_backmargin;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_install_at
   * Description      : �ݒu��ڋq���X�V����(A-11)
   ***********************************************************************************/
  PROCEDURE upd_install_at(
     it_mst_regist_info_rec IN  g_mst_regist_info_rtype         -- �}�X�^�o�^���
    ,ot_party_id            OUT NOCOPY hz_parties.party_id%TYPE -- �p�[�e�B�h�c
    ,ov_errbuf              OUT NOCOPY VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_install_at'; -- �v���O������
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_territory_code        CONSTANT VARCHAR2(2) := 'JP'; -- ���R�[�h
    /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� START */
    cv_business_low_type     CONSTANT xxcmm_cust_accounts.business_low_type%TYPE := '24';
    /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� END */
    cv_vendor_contact_code1  CONSTANT VARCHAR2(8) := 'FLVDDMY1';
    cv_vendor_contact_code2  CONSTANT VARCHAR2(8) := 'FLVDDMY2';
    cv_vendor_contact_code3  CONSTANT VARCHAR2(8) := 'FLVDDMY3';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_cust_acct       CONSTANT VARCHAR2(50) := '�ݒu��ڋq���X�V�������F�ڋq�}�X�^';
    cv_tkn_value_location        CONSTANT VARCHAR2(50) := '�ݒu��ڋq���X�V�������F�ڋq���Ə��}�X�^';
    cv_tkn_value_cust_acct_id    CONSTANT VARCHAR2(50) := '�ڋq�h�c';
    cv_tkn_value_account_update  CONSTANT VARCHAR2(50) := '�ڋq�}�X�^�X�V';
    cv_tkn_value_location_update CONSTANT VARCHAR2(50) := '�ڋq���Ə��}�X�^�X�V';
    cv_tkn_value_cust_addon      CONSTANT VARCHAR2(50) := '�A�J�E���g�A�h�I���}�X�^�X�V';
    cv_tkn_value_party           CONSTANT VARCHAR2(50) := '�ݒu��ڋq���X�V�������F�p�[�e�B�}�X�^';
    cv_tkn_value_party_id        CONSTANT VARCHAR2(50) := '�p�[�e�B�h�c';
    cv_tkn_value_party_update    CONSTANT VARCHAR2(50) := '�p�[�e�B�}�X�^�X�V';
    --
    -- *** ���[�J���ϐ� ***
    ln_object_version_number NUMBER;
    lt_cust_account_rec      hz_cust_account_v2pub.cust_account_rec_type;
    lt_location_rec          hz_location_v2pub.location_rec_type;
    lt_location_id           hz_locations.location_id%TYPE;
    lt_party_id              hz_party_sites.party_id%TYPE;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_vendor_number1        po_vendors.segment1%TYPE;
    lt_vendor_number2        po_vendors.segment1%TYPE;
    lt_vendor_number3        po_vendors.segment1%TYPE;
    lt_organization_rec      hz_party_v2pub.organization_rec_type;
    lt_profile_id            hz_organization_profiles.organization_profile_id%TYPE;
    --
    -- �ڋq�}�X�^�p�`�o�h�ϐ�
    --
    -- *** ���[�J���E�J�[�\�� ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ====================================
    -- �ڋq�}�X�^���擾
    -- ====================================
    BEGIN
      SELECT hca.object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   ln_object_version_number
      FROM   hz_cust_accounts hca -- �ڋq�}�X�^
      WHERE  hca.cust_account_id = it_mst_regist_info_rec.install_account_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_cust_acct                    -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_cust_acct_id                 -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                             -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_mst_regist_info_rec.install_account_id -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- �ڋq�}�X�^�X�V
    -- ====================================
    lt_cust_account_rec.cust_account_id := it_mst_regist_info_rec.install_account_id;                  -- �ڋq�h�c
    lt_cust_account_rec.account_name    := SUBSTRB(it_mst_regist_info_rec.install_party_name, 1, 240); -- �ڋq��
    --
    hz_cust_account_v2pub.update_cust_account(
       p_init_msg_list         => fnd_api.g_true
      ,p_cust_account_rec      => lt_cust_account_rec
      ,p_object_version_number => ln_object_version_number
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- ���^�[���R�[�h��S�ȊO�̏ꍇ
      IF (ln_msg_count > cn_number_one) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_api_name             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_account_update -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_api_msg              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg_data                 -- �g�[�N���l2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ====================================
    -- �ڋq���Ə��}�X�^���擾
    -- ====================================
    BEGIN
      SELECT hlo.location_id           -- �ڋq���Ə��h�c
            ,hlo.object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
            ,hps.party_id              -- �p�[�e�B�h�c
      INTO   lt_location_id
            ,ln_object_version_number
            ,lt_party_id
      FROM   hz_locations     hlo -- �ڋq���Ə��}�X�^
            ,hz_party_sites   hps -- �p�[�e�B�T�C�g�}�X�^
            ,hz_cust_accounts hca -- �ڋq�}�X�^
      WHERE  hca.cust_account_id = it_mst_regist_info_rec.install_account_id
      AND    hca.party_id        = hps.party_id
      AND    hps.location_id     = hlo.location_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_location                     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_cust_acct_id                 -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                             -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_mst_regist_info_rec.install_account_id -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- �ڋq���Ə��}�X�^�X�V
    -- ====================================
    lt_location_rec.location_id            := lt_location_id;                                             -- �ڋq���Ə��h�c
    lt_location_rec.country                := cv_territory_code;                                          -- ���R�[�h
    lt_location_rec.postal_code            := SUBSTRB(it_mst_regist_info_rec.install_postal_code, 1, 60); -- �X�֔ԍ�
    lt_location_rec.state                  := SUBSTRB(it_mst_regist_info_rec.install_state, 1, 60);       -- �s���{��
    lt_location_rec.city                   := SUBSTRB(it_mst_regist_info_rec.install_city, 1, 60);        -- �s�E��
    lt_location_rec.address1               := SUBSTRB(it_mst_regist_info_rec.install_address1, 1, 240);   -- �Z���P
    lt_location_rec.address2               := SUBSTRB(it_mst_regist_info_rec.install_address2, 1, 240);   -- �Z���Q
    --
    hz_location_v2pub.update_location(
       p_init_msg_list         => fnd_api.g_true
      ,p_location_rec          => lt_location_rec
      ,p_object_version_number => ln_object_version_number
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- ���^�[���R�[�h��S�ȊO�̏ꍇ
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name     -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_api_name              -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_location_update -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_api_msg               -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg_data                  -- �g�[�N���l2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ====================================
    -- �d����ԍ��擾
    -- ====================================
    BEGIN
      SELECT pve.segment1 -- �d����ԍ�
      INTO   lt_vendor_number1 -- �d����ԍ��P
      FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
            ,po_vendors              pve -- �d����}�X�^
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_bm1
      AND    xsd.customer_id                = pve.vendor_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� START */
        --lt_vendor_number1 := cv_vendor_contact_code1;
        lt_vendor_number1 := NULL;
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� END */
        --
    END;
    --
    BEGIN
      SELECT pve.segment1 -- �d����ԍ�
      INTO   lt_vendor_number2 -- �d����ԍ��Q
      FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
            ,po_vendors              pve -- �d����}�X�^
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_bm2
      AND    xsd.customer_id                = pve.vendor_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� START */
        --lt_vendor_number2 := cv_vendor_contact_code2;
        lt_vendor_number2 := NULL;
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� END */
        --
    END;
    --
    BEGIN
      SELECT pve.segment1 -- �d����ԍ�
      INTO   lt_vendor_number3 -- �d����ԍ��R
      FROM   xxcso_sp_decision_custs xsd -- �r�o�ꌈ�ڋq�e�[�u��
            ,po_vendors              pve -- �d����}�X�^
      WHERE  xsd.sp_decision_header_id      = it_mst_regist_info_rec.sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_bm3
      AND    xsd.customer_id                = pve.vendor_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� START */
        --lt_vendor_number3 := cv_vendor_contact_code3;
        lt_vendor_number3 := NULL;
        /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� END */
        --
    END;
    --
    -- ====================================
    -- �ڋq�A�h�I���}�X�^�X�V
    -- ====================================
    BEGIN
      UPDATE xxcmm_cust_accounts xca -- �ڋq�A�h�I���}�X�^
      /* 2009.04.08 K.Satomura ��Q�ԍ�T1_0287�Ή� START */
      --SET    xca.contractor_supplier_code = DECODE(xca.business_low_type
      --                                            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� START */
      --                                            --,cv_business_low_type, lt_vendor_number1
      --                                            --,cv_vendor_contact_code1) -- �_��Ҏd����R�[�h
      --                                            ,cv_business_low_type, cv_vendor_contact_code1
      --                                            ,lt_vendor_number1) -- �_��Ҏd����R�[�h
      --                                            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� END */
      --      ,xca.bm_pay_supplier_code1    = DECODE(xca.business_low_type
      --                                            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� START */
      --                                            --,cv_business_low_type, lt_vendor_number2
      --                                            --,cv_vendor_contact_code2) -- �Љ��BM�x���d����R�[�h�P
      --                                            ,cv_business_low_type, cv_vendor_contact_code2
      --                                            ,lt_vendor_number2) -- �Љ��BM�x���d����R�[�h�P
      --                                            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� END */
      --      ,xca.bm_pay_supplier_code2    = DECODE(xca.business_low_type
      --                                            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� START */
      --                                            --,cv_business_low_type, lt_vendor_number3
      --                                            --,cv_vendor_contact_code3) -- �Љ��BM�x���d����R�[�h�Q
      --                                            ,cv_business_low_type, cv_vendor_contact_code3
      --                                            ,lt_vendor_number3) -- �Љ��BM�x���d����R�[�h�Q
      --                                            /* 2009.03.24 K.Satomura ��Q�ԍ�T1_0135�Ή� END */
      SET    xca.contractor_supplier_code = DECODE(xca.business_low_type
                                                  ,cv_business_low_type,
                                                    CASE
                                                      WHEN (
                                                        SELECT SUM(NVL(sdl.bm1_bm_rate,0)) + SUM(NVL(sdl.bm1_bm_amount,0))
                                                        FROM   xxcso_sp_decision_lines sdl
                                                        WHERE  sdl.sp_decision_header_id = it_mst_regist_info_rec.sp_decision_header_id
                                                      ) <= cn_number_zero THEN
                                                        NULL
                                                      ELSE
                                                        cv_vendor_contact_code1
                                                    END
                                                  ,lt_vendor_number1) -- �_��Ҏd����R�[�h
            ,xca.bm_pay_supplier_code1    = DECODE(xca.business_low_type
                                                  ,cv_business_low_type,
                                                    CASE
                                                      WHEN (
                                                        SELECT SUM(NVL(sdl.bm2_bm_rate,0)) + SUM(NVL(sdl.bm2_bm_amount,0))
                                                        FROM   xxcso_sp_decision_lines sdl
                                                        WHERE  sdl.sp_decision_header_id = it_mst_regist_info_rec.sp_decision_header_id
                                                      ) <= cn_number_zero THEN
                                                        NULL
                                                      ELSE
                                                        cv_vendor_contact_code2
                                                    END
                                                  ,lt_vendor_number2) -- �Љ��BM�x���d����R�[�h�P
            ,xca.bm_pay_supplier_code2    = DECODE(xca.business_low_type
                                                  ,cv_business_low_type,
                                                    CASE
                                                      WHEN (
                                                        SELECT SUM(NVL(sdl.bm3_bm_rate,0)) + SUM(NVL(sdl.bm3_bm_amount,0))
                                                        FROM   xxcso_sp_decision_lines sdl
                                                        WHERE  sdl.sp_decision_header_id = it_mst_regist_info_rec.sp_decision_header_id
                                                      ) <= cn_number_zero THEN
                                                        NULL
                                                      ELSE
                                                        cv_vendor_contact_code3
                                                    END
                                                  ,lt_vendor_number3) -- �Љ��BM�x���d����R�[�h�Q
      /* 2009.04.08 K.Satomura ��Q�ԍ�T1_0287�Ή� END */
            /* 2009.04.28 K.Satomura ��Q�ԍ�T1_0733�Ή� START */
            /* 2009.05.15 K.Satomura ��Q�ԍ�T1_1010�Ή� START */
            --,xca.cnvs_date                = cd_process_date           -- �ڋq�l����
            ,xca.cnvs_date                = DECODE(it_mst_regist_info_rec.install_code
                                                  ,NULL, xca.cnvs_date
                                                  ,cd_process_date)   -- �ڋq�l����
            /* 2009.05.15 K.Satomura ��Q�ԍ�T1_1010�Ή� END */
            /* 2009.04.28 K.Satomura ��Q�ԍ�T1_0733�Ή� END */
            ,xca.last_update_date         = cd_last_update_date       -- �ŏI�X�V��
            ,xca.last_updated_by          = cn_last_updated_by        -- �ŏI�X�V��
            ,xca.last_update_login        = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,xca.request_id               = cn_request_id             -- ���N�G�X�g�h�c
            ,xca.program_application_id   = cn_program_application_id -- �v���O�����A�v���P�[�V�����h�c
            ,xca.program_id               = cn_program_id             -- �v���O�����h�c
            ,xca.program_update_date      = cd_program_update_date    -- �v���O�����X�V��
      WHERE  xca.customer_id = it_mst_regist_info_rec.install_account_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_cust_addon  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- �p�[�e�B�}�X�^���擾
    -- ====================================
    BEGIN
      SELECT hpa.object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   ln_object_version_number
      FROM   hz_parties hpa -- �p�[�e�B�}�X�^
      WHERE  hpa.party_id = lt_party_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_party       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_party_id    -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lt_party_id              -- �g�[�N���l3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ====================================
    -- �p�[�e�B�}�X�^�X�V
    -- ====================================
    lt_organization_rec.organization_name  := SUBSTRB(it_mst_regist_info_rec.install_party_name, 1, 360); -- �ڋq��
    lt_organization_rec.party_rec.party_id := lt_party_id;                                                -- �p�[�e�B�h�c
    --
    hz_party_v2pub.update_organization(
       p_init_msg_list               => fnd_api.g_true
      ,p_organization_rec            => lt_organization_rec
      ,p_party_object_version_number => ln_object_version_number
      ,x_profile_id                  => lt_profile_id
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- ���^�[���R�[�h��S�ȊO�̏ꍇ
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_api_name           -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_party_update -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_api_msg            -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg_data               -- �g�[�N���l2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    ot_party_id := lt_party_id;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END upd_install_at;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_install_base
   * Description      : �������X�V����(A-12)
   ***********************************************************************************/
  PROCEDURE upd_install_base(
     it_mst_regist_info_rec IN         g_mst_regist_info_rtype  -- �}�X�^�o�^���
    ,it_party_id            IN         hz_parties.party_id%TYPE -- �p�[�e�B�h�c
    ,ov_errbuf              OUT NOCOPY VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_install_base'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_api_version            CONSTANT NUMBER        := 1.0;
    cv_party_source_table     CONSTANT VARCHAR2(100) := 'HZ_PARTIES';
    cv_relationship_type_code CONSTANT VARCHAR2(100) := 'OWNER';
    cv_src_tran_type          CONSTANT VARCHAR2(5)   := 'IB_UI';
    cv_location_type_code     CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_task_name         CONSTANT VARCHAR2(50) := '����^�C�v�̎���^�C�vID';
    cv_tkn_value_install_base      CONSTANT VARCHAR2(50) := '�������X�V�������F�C���X�g�[���x�[�X�}�X�^';
    cv_tkn_value_install_code      CONSTANT VARCHAR2(50) := '�����R�[�h';
    cv_tkn_value_instance_party    CONSTANT VARCHAR2(50) := '�������X�V�������F�C���X�^���X�p�[�e�B�}�X�^';
    cv_tkn_value_instance_id       CONSTANT VARCHAR2(50) := '�C���X�^���X�h�c';
    cv_tkn_value_instance_acct     CONSTANT VARCHAR2(50) := '�������X�V�������F�C���X�^���X�A�J�E���g�}�X�^';
    cv_tkn_value_instance_party_id CONSTANT VARCHAR2(50) := '�C���X�^���X�p�[�e�B�h�c';
    cv_tkn_value_party_site        CONSTANT VARCHAR2(50) := '�������X�V�������F�p�[�e�B�T�C�g�}�X�^';
    cv_tkn_value_party_id          CONSTANT VARCHAR2(50) := '�p�[�e�B�h�c';
    cv_tkn_value_ib_update         CONSTANT VARCHAR2(50) := '�C���X�g�[���x�[�X�}�X�^�X�V';
    --
    -- *** ���[�J���ϐ� ***
    lt_instance_id                csi_item_instances.instance_id%TYPE;
    ln_instance_object_vnum       csi_item_instances.object_version_number%TYPE;
    lt_instance_party_id          csi_i_parties.instance_party_id%TYPE;
    ln_instance_party_object_vnum csi_i_parties.object_version_number%TYPE;
    lt_ip_account_id              csi_ip_accounts.ip_account_id%TYPE;
    ln_instance_acct_object_vnum  csi_ip_accounts.object_version_number%TYPE;
    lt_transaction_type_id        csi_txn_types.transaction_type_id%TYPE;
    lt_party_site_id              hz_party_sites.party_site_id%TYPE;
    --
    -- �������X�V�p�`�o�h
    lt_instance_rec          csi_datastructures_pub.instance_rec;
    lt_ext_attrib_values_tbl csi_datastructures_pub.extend_attrib_values_tbl;
    lt_party_tbl             csi_datastructures_pub.party_tbl;
    lt_account_tbl           csi_datastructures_pub.party_account_tbl;
    lt_pricing_attrib_tbl    csi_datastructures_pub.pricing_attribs_tbl;
    lt_org_assignments_tbl   csi_datastructures_pub.organization_units_tbl;
    lt_asset_assignment_tbl  csi_datastructures_pub.instance_asset_tbl;
    lt_txn_rec               csi_datastructures_pub.transaction_rec;
    lt_instance_id_lst       csi_datastructures_pub.id_tbl;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ================================================
    -- �C���X�^���X���擾
    -- ================================================
    BEGIN
      SELECT cii.instance_id           -- �C���X�^���X�h�c
            ,cii.object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   lt_instance_id
            ,ln_instance_object_vnum
      FROM   csi_item_instances cii -- �C���X�g�[���x�[�X�}�X�^
      WHERE  cii.external_reference = it_mst_regist_info_rec.install_code
      AND    cii.attribute4         = cv_flag_no
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05                    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_install_base           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_install_code           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_mst_regist_info_rec.install_code -- �g�[�N���l3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- �C���X�^���X�p�[�e�B���擾
    -- ================================================
    BEGIN
      SELECT cip.instance_party_id     -- �C���X�^���X�p�[�e�B�h�c
            ,cip.object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   lt_instance_party_id
            ,ln_instance_party_object_vnum
      FROM   csi_i_parties cip -- �C���X�^���X�p�[�e�B�}�X�^
      WHERE  cip.instance_id = lt_instance_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_instance_party -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_instance_id    -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lt_instance_id              -- �g�[�N���l3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- �C���X�^���X�A�J�E���g���擾
    -- ================================================
    BEGIN
      SELECT cia.ip_account_id         -- �C���X�^���X�A�J�E���g�h�c
            ,cia.object_version_number -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   lt_ip_account_id
            ,ln_instance_acct_object_vnum
      FROM   csi_ip_accounts cia -- �C���X�^���X�A�J�E���g�}�X�^
      WHERE  cia.instance_party_id = lt_instance_party_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_instance_acct     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_instance_party_id -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id                  -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lt_instance_party_id           -- �g�[�N���l3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- �p�[�e�B�T�C�g�h�c�擾
    -- ================================================
    BEGIN
      SELECT hps.party_site_id -- �p�[�e�B�T�C�g�h�c
      INTO   lt_party_site_id
      FROM   hz_party_sites hps -- �p�[�e�B�T�C�g�}�X�^
      WHERE  hps.party_id = it_party_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_party_site  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_name          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_value_party_id    -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_key_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => it_party_id              -- �g�[�N���l3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- ����^�C�v�h�c�擾
    -- ================================================
    BEGIN
      SELECT ctt.transaction_type_id transaction_type_id -- ����^�C�v�h�c
      INTO   lt_transaction_type_id
      FROM   csi_txn_types ctt -- ����^�C�v�e�[�u��
      WHERE  ctt.source_transaction_type = cv_src_tran_type
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_13         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_task_name   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_tran_type         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                  -- �g�[�N���l3
                     );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ================================================
    -- �������X�V
    -- ================================================
    -- �\���̏�����
    lt_ext_attrib_values_tbl.DELETE;
    lt_party_tbl.DELETE;
    lt_account_tbl.DELETE;
    lt_pricing_attrib_tbl.DELETE;
    lt_org_assignments_tbl.DELETE;
    lt_asset_assignment_tbl.DELETE;
    lt_instance_id_lst.DELETE;
    --
    -- �C���X�g�[���x�[�����
    lt_instance_rec.instance_id           := lt_instance_id;                      -- �C���X�^���X�h�c
    lt_instance_rec.external_reference    := it_mst_regist_info_rec.install_code; -- �����R�[�h
    lt_instance_rec.install_date          := it_mst_regist_info_rec.install_date; -- �ݒu��
    lt_instance_rec.location_type_code    := cv_location_type_code;               -- ���s���Ə��^�C�v
    lt_instance_rec.location_id           := lt_party_site_id;                    -- ���s���Ə��h�c
    lt_instance_rec.object_version_number := ln_instance_object_vnum;             -- �I�u�W�F�N�g�o�[�W�����ԍ�
    --
    -- �C���X�^���X�p�[�e�B���
    lt_party_tbl(1).instance_party_id      := lt_instance_party_id;          -- �C���X�^���X�p�[�e�B�h�c
    lt_party_tbl(1).party_source_table     := cv_party_source_table;         -- �p�[�e�B�\�[�X�e�[�u��
    lt_party_tbl(1).party_id               := it_party_id;                   -- �p�[�e�B�h�c
    lt_party_tbl(1).relationship_type_code := cv_relationship_type_code;     -- �����[�V�����^�C�v�R�[�h
    lt_party_tbl(1).contact_flag           := cv_flag_no;                    -- �R���^�N�g�t���O
    lt_party_tbl(1).object_version_number  := ln_instance_party_object_vnum; -- �I�u�W�F�N�g�o�[�W�����ԍ�
    --
    -- �C���X�^���X�A�J�E���g���
    lt_account_tbl(1).ip_account_id          := lt_ip_account_id;                          -- �C���X�^���X�A�J�E���g�h�c
    lt_account_tbl(1).instance_party_id      := lt_instance_party_id;                      -- �C���X�^���X�p�[�e�B�h�c 
    lt_account_tbl(1).parent_tbl_index       := cn_number_one;                             -- �C���f�b�N�X
    lt_account_tbl(1).party_account_id       := it_mst_regist_info_rec.install_account_id; -- �ڋq�h�c
    lt_account_tbl(1).relationship_type_code := cv_relationship_type_code;                 -- �����[�V�����^�C�v�R�[�h
    lt_account_tbl(1).object_version_number  := ln_instance_acct_object_vnum;              -- �I�u�W�F�N�g�o�[�W�����ԍ�
    --
    -- �g�����U�N�V�����^�C�v�\����
    lt_txn_rec.transaction_date        := SYSDATE;
    lt_txn_rec.source_transaction_date := SYSDATE;
    lt_txn_rec.transaction_type_id     := lt_transaction_type_id;
    --
    csi_item_instance_pub.update_item_instance(
       p_api_version           => cn_api_version
      ,p_commit                => fnd_api.g_false
      ,p_init_msg_list         => fnd_api.g_true
      ,p_validation_level      => fnd_api.g_valid_level_full
      ,p_instance_rec          => lt_instance_rec
      ,p_ext_attrib_values_tbl => lt_ext_attrib_values_tbl
      ,p_party_tbl             => lt_party_tbl
      ,p_account_tbl           => lt_account_tbl
      ,p_pricing_attrib_tbl    => lt_pricing_attrib_tbl
      ,p_org_assignments_tbl   => lt_org_assignments_tbl
      ,p_asset_assignment_tbl  => lt_asset_assignment_tbl
      ,p_txn_rec               => lt_txn_rec
      ,x_instance_id_lst       => lt_instance_id_lst
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
    --
    IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
      -- ���^�[���R�[�h��S�ȊO�̏ꍇ
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                          p_msg_index => cn_number_one
                         ,p_encoded   => fnd_api.g_true
                       );
        --
      END IF;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_14         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_api_name          -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_ib_update   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_api_msg           -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg_data              -- �g�[�N���l2
                  );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END upd_install_base;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_cont_manage_aft
   * Description      : �_����X�V����(A-13)
   ***********************************************************************************/
  PROCEDURE upd_cont_manage_aft(
     it_contract_management_id IN         xxcso_contract_managements.contract_management_id%TYPE -- �����̔��@�ݒu�_�񏑂h�c
    ,iv_err_flag               IN         VARCHAR2                                               -- �G���[�t���O
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                               -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_cont_manage_aft'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- �g�[�N���p�萔
    cv_tkn_value_cont_manage CONSTANT VARCHAR2(50) := '�_��Ǘ��e�[�u��';
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
    -- ================================================
    -- �_����X�V
    -- ================================================
    BEGIN
      UPDATE xxcso_contract_managements xcm -- �_��Ǘ��e�[�u��
      SET    xcm.cooperate_flag         = cv_finish_cooperate -- �}�X�^�A�g�t���O
            ,xcm.batch_proc_status      = DECODE(iv_err_flag
                                                ,cv_flag_no, cv_batch_proc_status_norm
                                                ,cv_batch_proc_status_err
                                          ) -- �o�b�`�����X�e�[�^�X
            ,xcm.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,xcm.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,xcm.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,xcm.request_id             = cn_request_id             -- �v��ID
            ,xcm.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xcm.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
            ,xcm.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE xcm.contract_management_id = it_contract_management_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_action            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_cont_manage -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_error_message     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END upd_cont_manage_aft;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
    lt_mst_regist_info_rec    g_mst_regist_info_rtype;
    lt_contract_management_id xxcso_contract_managements.contract_management_id%TYPE;
    ln_request_id             NUMBER;
    ln_work_count             NUMBER;
    lv_vendor_err_flag        VARCHAR2(1);
    lv_mst_err_flag           VARCHAR2(1);
    lt_party_id               hz_parties.party_id%TYPE;
    --
    -- *** ���[�J���E�J�[�\�� ***
    -- A-3,A-8�p�J�[�\��
    CURSOR contract_management_cur
    IS
      SELECT xcm.contract_management_id contract_management_id -- �����̔��@�ݒu�_�񏑂h�c
            ,xcm.contract_number        contract_number        -- �_�񏑔ԍ�
            ,xcm.sp_decision_header_id  sp_decision_header_id  -- �r�o�ꌈ�w�b�_�h�c
            ,xcm.install_account_id     install_account_id     -- �ݒu��ڋq�h�c
            ,xcm.install_account_number install_account_number -- �ݒu��ڋq�R�[�h
            ,xcm.install_party_name     install_party_name     -- �ݒu��ڋq��
            ,xcm.install_postal_code    install_postal_code    -- �ݒu��X�֔ԍ�
            ,xcm.install_state          install_state          -- �ݒu��s���{��
            ,xcm.install_city           install_city           -- �ݒu��s��
            ,xcm.install_address1       install_address1       -- �ݒu��Z���P
            ,xcm.install_address2       install_address2       -- �ݒu��Z���Q
            ,xcm.install_date           install_date           -- �ݒu��
            ,xcm.install_code           install_code           -- �����R�[�h
      FROM   xxcso_contract_managements xcm -- �_��Ǘ��e�[�u��
      WHERE  xcm.status            = cv_status                -- �X�e�[�^�X
      AND    xcm.cooperate_flag    = cv_un_cooperate          -- �}�X�^�A�g�t���O
      AND    xcm.batch_proc_status = cv_batch_proc_status_coa -- �o�b�`�����X�e�[�^�X
      ORDER BY xcm.contract_management_id
      ;
    --
    -- A-4�p�J�[�\��
    CURSOR vendor_info_cur
    IS
      SELECT xde.supplier_id                  supplier_id                  -- �d����h�c
            ,xde.delivery_div                 delivery_div                 -- ���t��敪
            ,xde.payment_name                 payment_name                 -- �x���於
            ,xde.payment_name_alt             payment_name_alt             -- �x���於�J�i
            ,xde.bank_transfer_fee_charge_div bank_transfer_fee_charge_div -- �U���萔�����S�敪
            ,xde.belling_details_div          belling_details_div          -- �x�����׏��敪
            ,xde.inquery_charge_hub_cd        inquery_charge_hub_cd        -- �⍇���S�����_�R�[�h
            ,xde.post_code                    post_code                    -- �X�֔ԍ�
            ,xde.prefectures                  prefectures                  -- �s���{��
            ,xde.city_ward                    city_ward                    -- �s��
            ,xde.address_1                    address_1                    -- �Z���P
            ,xde.address_2                    address_2                    -- �Z���Q
            ,xde.address_lines_phonetic       address_lines_phonetic       -- �d�b�ԍ�
            ,xba.bank_number                  bank_number                  -- ��s�ԍ�
            ,xba.bank_name                    bank_name                    -- ��s��
            ,xba.branch_number                branch_number                -- �x�X�ԍ�
            ,xba.branch_name                  branch_name                  -- �x�X��
            ,xba.bank_account_type            bank_account_type            -- �������
            ,xba.bank_account_number          bank_account_number          -- �����ԍ�
            ,xba.bank_account_name_kana       bank_account_name_kana       -- �������`�J�i
            ,xba.bank_account_name_kanji      bank_account_name_kanji      -- �������`����
            ,xba.bank_account_dummy_flag      bank_account_dummy_flag      -- ��s�����_�~�[�t���O
      FROM   xxcso_destinations  xde -- ���t��e�[�u��
            ,xxcso_bank_accounts xba -- ��s�����A�h�I���}�X�^
      WHERE  xde.contract_management_id = lt_contract_management_id -- �����̔��@�ݒu�_�񏑂h�c
      AND    xde.delivery_id            = xba.delivery_id           -- ���t��h�c
      ;
    --
    -- *** ���[�J���E���R�[�h ***
    --
    -- *** ���[�J����O ***
    mst_coalition_expt EXCEPTION;
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
    gn_vendor_target_cnt := cn_number_zero;
    gn_mst_target_cnt    := cn_number_zero;
    gn_vendor_normal_cnt := cn_number_zero;
    gn_mst_normal_cnt    := cn_number_zero;
    gn_vendor_error_cnt  := cn_number_zero;
    gn_mst_error_cnt     := cn_number_zero;
    /* 2009.04.17 K.Satomura T1_0617�Ή� START */
    ln_work_count        := cn_number_zero;
    /* 2009.04.17 K.Satomura T1_0617�Ή� END */
    --
    -- ============
    -- A-1.��������
    -- ============
    start_proc(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================================
    -- A-2. �_��Ǘ����X�V����
    -- ===================================
    upd_cont_manage_bef(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      ROLLBACK;
      RAISE global_process_expt;
      --
    ELSE
      COMMIT;
      --
    END IF;
    --
    -- **************************************************
    --
    -- �d����E�������o�^����
    --
    -- **************************************************
    -- ==========================
    -- A-3.�_��Ǘ����擾����
    -- ==========================
    <<contract_management_loop1>>
    FOR lt_contract_management_rec IN contract_management_cur LOOP
      lt_mst_regist_info_rec.contract_management_id := lt_contract_management_rec.contract_management_id;
      lt_mst_regist_info_rec.contract_number        := lt_contract_management_rec.contract_number;
      lt_mst_regist_info_rec.sp_decision_header_id  := lt_contract_management_rec.sp_decision_header_id;
      lt_mst_regist_info_rec.install_account_id     := lt_contract_management_rec.install_account_id;
      lt_mst_regist_info_rec.install_account_number := lt_contract_management_rec.install_account_number;
      lt_mst_regist_info_rec.install_party_name     := lt_contract_management_rec.install_party_name;
      lt_mst_regist_info_rec.install_postal_code    := lt_contract_management_rec.install_postal_code;
      lt_mst_regist_info_rec.install_state          := lt_contract_management_rec.install_state;
      lt_mst_regist_info_rec.install_city           := lt_contract_management_rec.install_city;
      lt_mst_regist_info_rec.install_address1       := lt_contract_management_rec.install_address1;
      lt_mst_regist_info_rec.install_address2       := lt_contract_management_rec.install_address2;
      lt_contract_management_id                     := lt_contract_management_rec.contract_management_id;
      --
      -- *** DEBUG_LOG START ***
      -- �_��Ǘ��������O�o��
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => cv_debug_msg3  || CHR(10) ||
                   cv_debug_msg4  || lt_contract_management_rec.contract_management_id || CHR(10) ||
                   cv_debug_msg74 || lt_mst_regist_info_rec.contract_number            || CHR(10) ||
                   cv_debug_msg5  || lt_contract_management_rec.sp_decision_header_id  || CHR(10) ||
                   cv_debug_msg6  || lt_contract_management_rec.install_account_id     || CHR(10) ||
                   cv_debug_msg7  || lt_contract_management_rec.install_account_number || CHR(10) ||
                   cv_debug_msg8  || lt_contract_management_rec.install_party_name     || CHR(10) ||
                   cv_debug_msg9  || lt_contract_management_rec.install_postal_code    || CHR(10) ||
                   cv_debug_msg10 || lt_contract_management_rec.install_state          || CHR(10) ||
                   cv_debug_msg11 || lt_contract_management_rec.install_city           || CHR(10) ||
                   cv_debug_msg12 || lt_contract_management_rec.install_address1       || CHR(10) ||
                   cv_debug_msg13 || lt_contract_management_rec.install_address2       || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG END ***
      --
      -- ============================================
      -- A-4.�d������擾����
      -- ============================================
      /* 2009.04.17 K.Satomura T1_0617�Ή� START */
      --ln_work_count := cn_number_zero;
      /* 2009.04.17 K.Satomura T1_0617�Ή� END */
      --
      <<vendor_info_loop>>
      FOR lt_vendor_info_rec IN vendor_info_cur LOOP
        ln_work_count := ln_work_count + cn_number_one;
        --
        lt_mst_regist_info_rec.supplier_id                  := lt_vendor_info_rec.supplier_id;
        lt_mst_regist_info_rec.delivery_div                 := lt_vendor_info_rec.delivery_div;
        lt_mst_regist_info_rec.payment_name                 := lt_vendor_info_rec.payment_name;
        lt_mst_regist_info_rec.payment_name_alt             := lt_vendor_info_rec.payment_name_alt;
        lt_mst_regist_info_rec.bank_transfer_fee_charge_div := lt_vendor_info_rec.bank_transfer_fee_charge_div;
        lt_mst_regist_info_rec.belling_details_div          := lt_vendor_info_rec.belling_details_div;
        lt_mst_regist_info_rec.inquery_charge_hub_cd        := lt_vendor_info_rec.inquery_charge_hub_cd;
        lt_mst_regist_info_rec.post_code                    := lt_vendor_info_rec.post_code;
        lt_mst_regist_info_rec.prefectures                  := lt_vendor_info_rec.prefectures;
        lt_mst_regist_info_rec.city_ward                    := lt_vendor_info_rec.city_ward;
        lt_mst_regist_info_rec.address_1                    := lt_vendor_info_rec.address_1;
        lt_mst_regist_info_rec.address_2                    := lt_vendor_info_rec.address_2;
        lt_mst_regist_info_rec.address_lines_phonetic       := lt_vendor_info_rec.address_lines_phonetic;
        lt_mst_regist_info_rec.bank_number                  := lt_vendor_info_rec.bank_number;
        lt_mst_regist_info_rec.bank_name                    := lt_vendor_info_rec.bank_name;
        lt_mst_regist_info_rec.branch_number                := lt_vendor_info_rec.branch_number;
        lt_mst_regist_info_rec.branch_name                  := lt_vendor_info_rec.branch_name;
        lt_mst_regist_info_rec.bank_account_type            := lt_vendor_info_rec.bank_account_type;
        lt_mst_regist_info_rec.bank_account_number          := lt_vendor_info_rec.bank_account_number;
        lt_mst_regist_info_rec.bank_account_name_kana       := lt_vendor_info_rec.bank_account_name_kana;
        lt_mst_regist_info_rec.bank_account_name_kanji      := lt_vendor_info_rec.bank_account_name_kanji;
        --
        -- *** DEBUG_LOG START ***
        -- �d����������O�o��
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => cv_debug_msg14 || CHR(10) ||
                     cv_debug_msg15 || lt_vendor_info_rec.supplier_id                  || CHR(10) ||
                     cv_debug_msg16 || lt_vendor_info_rec.delivery_div                 || CHR(10) ||
                     cv_debug_msg17 || lt_vendor_info_rec.payment_name                 || CHR(10) ||
                     cv_debug_msg18 || lt_vendor_info_rec.payment_name_alt             || CHR(10) ||
                     cv_debug_msg19 || lt_vendor_info_rec.bank_transfer_fee_charge_div || CHR(10) ||
                     cv_debug_msg20 || lt_vendor_info_rec.belling_details_div          || CHR(10) ||
                     cv_debug_msg21 || lt_vendor_info_rec.inquery_charge_hub_cd        || CHR(10) ||
                     cv_debug_msg22 || lt_vendor_info_rec.post_code                    || CHR(10) ||
                     cv_debug_msg23 || lt_vendor_info_rec.prefectures                  || CHR(10) ||
                     cv_debug_msg24 || lt_vendor_info_rec.city_ward                    || CHR(10) ||
                     cv_debug_msg25 || lt_vendor_info_rec.address_1                    || CHR(10) ||
                     cv_debug_msg26 || lt_vendor_info_rec.address_2                    || CHR(10) ||
                     cv_debug_msg27 || lt_vendor_info_rec.address_lines_phonetic       || CHR(10) ||
                     cv_debug_msg28 || lt_vendor_info_rec.bank_number                  || CHR(10) ||
                     cv_debug_msg29 || lt_vendor_info_rec.bank_name                    || CHR(10) ||
                     cv_debug_msg30 || lt_vendor_info_rec.branch_number                || CHR(10) ||
                     cv_debug_msg31 || lt_vendor_info_rec.branch_name                  || CHR(10) ||
                     cv_debug_msg32 || lt_vendor_info_rec.bank_account_type            || CHR(10) ||
                     cv_debug_msg33 || lt_vendor_info_rec.bank_account_number          || CHR(10) ||
                     cv_debug_msg34 || lt_vendor_info_rec.bank_account_name_kana       || CHR(10) ||
                     cv_debug_msg35 || lt_vendor_info_rec.bank_account_name_kanji      || CHR(10) ||
                     ''
        );
        -- *** DEBUG_LOG END ***
        --
        -- ===================================
        -- A-5.�x���_�[����I/F�e�[�u���o�^����
        -- ===================================
        reg_vendor_if(
           it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
          ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          ROLLBACK;
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one;
          RAISE global_process_expt;
          --
        END IF;
        --
        lt_vendor_info_rec := NULL;
        --
      END LOOP vendor_info_loop;
      --
      lt_contract_management_rec := NULL;
      lt_mst_regist_info_rec     := NULL;
      --
    END LOOP contract_management_loop1;
    --
    IF (gn_vendor_target_cnt > cn_number_zero) THEN
      IF (ln_work_count > cn_number_zero) THEN
        -- ==========================
        -- A-6.�d������o�^/�X�V����
        -- ==========================
        reg_vendor(
           on_request_id => ln_request_id -- �v���h�c
          ,ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          ROLLBACK;
          RAISE global_process_expt;
          --
        ELSE
          COMMIT;
          --
        END IF;
        --
        -- =========================================
        -- A-7.�d������o�^/�X�V�����m�F����
        -- =========================================
        confirm_reg_vendor(
           in_request_id => ln_request_id -- �v���h�c
          ,ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one;
          RAISE global_process_expt;
          --
        END IF;
        --
      END IF;
      --
      <<contract_management_loop2>>
      FOR lt_contract_management_rec IN contract_management_cur LOOP
        lv_vendor_err_flag                            := cv_flag_no;
        lt_mst_regist_info_rec.contract_management_id := lt_contract_management_rec.contract_management_id;
        lt_mst_regist_info_rec.contract_number        := lt_contract_management_rec.contract_number;
        lt_mst_regist_info_rec.sp_decision_header_id  := lt_contract_management_rec.sp_decision_header_id ;
        lt_mst_regist_info_rec.install_account_id     := lt_contract_management_rec.install_account_id;
        lt_mst_regist_info_rec.install_account_number := lt_contract_management_rec.install_account_number;
        lt_mst_regist_info_rec.install_party_name     := lt_contract_management_rec.install_party_name;
        lt_mst_regist_info_rec.install_postal_code    := lt_contract_management_rec.install_postal_code;
        lt_mst_regist_info_rec.install_state          := lt_contract_management_rec.install_state;
        lt_mst_regist_info_rec.install_city           := lt_contract_management_rec.install_city;
        lt_mst_regist_info_rec.install_address1       := lt_contract_management_rec.install_address1;
        lt_mst_regist_info_rec.install_address2       := lt_contract_management_rec.install_address2;
        lt_mst_regist_info_rec.install_date           := lt_contract_management_rec.install_date;
        lt_mst_regist_info_rec.install_code           := lt_contract_management_rec.install_code;
        --
        -- ===================================
        -- A-8.�d������o�^/�X�V�G���[������
        -- ===================================
        error_reg_vendor(
           it_contract_management_id => lt_contract_management_rec.contract_management_id -- �����̔��@�ݒu�_�񏑂h�c
          ,it_contract_number        => lt_contract_management_rec.contract_number        -- �_�񏑔ԍ�
          ,in_request_id             => ln_request_id                                     -- �v���h�c
          ,ov_err_flag               => lv_vendor_err_flag                                -- �d����捞�G���[�t���O
          ,ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          ROLLBACK;
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one;
          RAISE global_process_expt;
          --
        ELSE
          COMMIT;
          --
        END IF;
        --
        -- **************************************************
        --
        -- �}�X�^���o�^�E�X�V����
        --
        -- **************************************************
        IF (lv_vendor_err_flag = cv_flag_no) THEN
          -- A-8�̏����ŃG���[���Ȃ������f�[�^�݈̂ȍ~�̏������s���B
          gn_vendor_normal_cnt := gn_vendor_normal_cnt + cn_number_one; -- �d����捞������ɓo�^���ꂽ���̂��J�E���g
          gn_mst_target_cnt    := gn_mst_target_cnt + cn_number_one;    -- �}�X�^�A�g�����Ώی����J�E���g
          SAVEPOINT msg_coalition;
          --
          BEGIN
            -- ================================
            -- A-9.�d����ID�֘A�t������
            -- ================================
            associate_vendor_id(
               it_contract_management_id => lt_contract_management_rec.contract_management_id -- �����̔��@�ݒu�_�񏑂h�c
              ,it_sp_decision_header_id  => lt_contract_management_rec.sp_decision_header_id  -- �r�o�ꌈ�w�b�_�h�c
              ,ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            --
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE mst_coalition_expt;
              --
            END IF;
            --
            -- =========================================
            -- A-10.�̔��萔�����o�^/�X�V����
            -- =========================================
            reg_backmargin(
               it_sp_decision_header_id  => lt_contract_management_rec.sp_decision_header_id  -- �r�o�ꌈ�w�b�_�h�c
              ,it_install_account_number => lt_contract_management_rec.install_account_number -- �ݒu��ڋq�R�[�h
              ,ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            --
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE mst_coalition_expt;
              --
            END IF;
            --
            -- =========================================
            -- A-11.�ݒu��ڋq���X�V����
            -- =========================================
            upd_install_at(
               it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
              ,ot_party_id            => lt_party_id            -- �p�[�e�B�h�c
              ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            --
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE mst_coalition_expt;
              --
            END IF;
            --
            -- =========================================
            -- A-12.�������X�V����
            -- =========================================
            IF (TRIM(lt_mst_regist_info_rec.install_code)) IS NOT NULL THEN
              upd_install_base(
                 it_mst_regist_info_rec => lt_mst_regist_info_rec -- �}�X�^�o�^���
                ,it_party_id            => lt_party_id            -- �p�[�e�B�h�c
                ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              --
              IF (lv_retcode <> cv_status_normal) THEN
                RAISE mst_coalition_expt;
                --
              END IF;
              --
            END IF;
            --
            lv_mst_err_flag   := cv_flag_no;
            gn_mst_normal_cnt := gn_mst_normal_cnt + cn_number_one; -- �}�X�^�A�g�Ő���ɓo�^���ꂽ���̂��J�E���g
            --
          EXCEPTION
            WHEN mst_coalition_expt THEN
              -- �}�X�^�A�g�ŃG���[���������ꍇ�A���[���o�b�N�������b�Z�[�W���o��
              ROLLBACK TO msg_coalition;
              --
              fnd_file.put_line(
                 which  => fnd_file.output
                ,buff   => lv_errbuf
              );
              --
              lv_mst_err_flag  := cv_flag_yes;
              gn_mst_error_cnt := gn_mst_error_cnt + cn_number_one; -- �}�X�^�A�g�ŃG���[�����������̂��J�E���g
              --
          END;
          --
        ELSE
          gn_vendor_error_cnt := gn_vendor_error_cnt + cn_number_one; -- �d����捞�ŃG���[�����������̂��J�E���g
          --
        END IF;
        --
        -- =============================================
        -- A-13.�_����X�V����
        -- =============================================
        upd_cont_manage_aft(
           it_contract_management_id => lt_contract_management_rec.contract_management_id -- �����̔��@�ݒu�_�񏑂h�c
          ,iv_err_flag               => lv_mst_err_flag                                   -- �G���[�t���O
          ,ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        lt_contract_management_rec := NULL;
        --
      END LOOP contract_management_loop2;
      --
    END IF;
    --
    IF ((gn_mst_error_cnt > cn_number_zero)
      OR (gn_vendor_error_cnt > cn_number_zero))
    THEN
      -- �}�X�^�A�g���͎d����捞�ŃG���[���������ꍇ
      ov_retcode := cv_status_warn;
      --
    END IF;
    --
    COMMIT;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** ���������ʗ�O�n���h�� ***
      -- �_��Ǘ��e�[�u����S�čX�V
      UPDATE xxcso_contract_managements xcm -- �_��Ǘ��e�[�u��
      SET    xcm.cooperate_flag         = cv_finish_cooperate       -- �}�X�^�A�g�t���O
            ,xcm.batch_proc_status      = cv_batch_proc_status_err  -- �o�b�`�����X�e�[�^�X
            ,xcm.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,xcm.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,xcm.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,xcm.request_id             = cn_request_id             -- �v��ID
            ,xcm.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xcm.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
            ,xcm.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE  xcm.status            = cv_status                -- �X�e�[�^�X
      AND    xcm.cooperate_flag    = cv_un_cooperate          -- �}�X�^�A�g�t���O
      AND    xcm.batch_proc_status = cv_batch_proc_status_coa -- �o�b�`�����X�e�[�^�X
      ;
      COMMIT;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      -- �_��Ǘ��e�[�u����S�čX�V
      UPDATE xxcso_contract_managements xcm -- �_��Ǘ��e�[�u��
      SET    xcm.cooperate_flag         = cv_finish_cooperate       -- �}�X�^�A�g�t���O
            ,xcm.batch_proc_status      = cv_batch_proc_status_err  -- �o�b�`�����X�e�[�^�X
            ,xcm.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,xcm.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,xcm.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,xcm.request_id             = cn_request_id             -- �v��ID
            ,xcm.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xcm.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
            ,xcm.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE  xcm.status            = cv_status                -- �X�e�[�^�X
      AND    xcm.cooperate_flag    = cv_un_cooperate          -- �}�X�^�A�g�t���O
      AND    xcm.batch_proc_status = cv_batch_proc_status_coa -- �o�b�`�����X�e�[�^�X
      ;
      COMMIT;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h   --# �Œ� #
  )
  --
  --###########################  �Œ蕔 START   ###########################
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_value_vendor CONSTANT VARCHAR2(50) := '�d����捞';
    cv_tkn_value_mst    CONSTANT VARCHAR2(50) := '�}�X�^�A�g';
    --
    -- *** ���[�J���ϐ� ***
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
      --
    END IF;
    --
    --###########################  �Œ蕔 END   #############################
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
       -- �G���[�o��
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --�G���[���b�Z�[�W
       );
       --
    END IF;
    --
    -- =======================
    -- A-14.�I������
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    -- �Ώی����o��(�d����捞)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_15
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_vendor
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_vendor_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �Ώی����o��(�}�X�^�A�g)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_15
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_mst
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_mst_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ���������o��(�d����捞)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_16
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_vendor
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_vendor_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ���������o��(�}�X�^�A�g)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_16
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_mst
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_mst_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �G���[�����o��(�d����捞)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_17
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_vendor
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_vendor_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- �G���[�����o��(�}�X�^�A�g)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_tkn_number_17
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_mst
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_mst_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
      --
    ELSIF(lv_retcode = cv_status_error) THEN
      IF ((gn_vendor_normal_cnt = cn_number_zero)
        AND (gn_mst_normal_cnt = cn_number_zero))
      THEN
        -- ����̌�����1�����Ȃ��ꍇ
        lv_message_code := cv_error_msg;
        --
      ELSE
        lv_message_code := cv_tkn_number_18;
        --
      END IF;
      --
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �X�e�[�^�X�Z�b�g
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    --
  EXCEPTION
    --
    --###########################  �Œ蕔 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  �Œ蕔 END   #######################################################
  --
END XXCSO010A02C;
/
