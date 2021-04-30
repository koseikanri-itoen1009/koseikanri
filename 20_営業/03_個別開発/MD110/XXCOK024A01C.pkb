CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A01C(body)
 * Description      : �T���}�X�^CSV�A�b�v���[�h
 * MD.050           : �T���}�X�^CSV�A�b�v���[�h MD050_COK_024_A01
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                                       (A-1)
 *  get_if_data                  IF�f�[�^�擾                                   (A-2)
 *  delete_if_data               IF�f�[�^�폜                                   (A-3)
 *  divide_item                  �A�b�v���[�h�t�@�C�����ڕ���                   (A-4)
 *  exclusive_check              �T���}�X�^�r�����䏈��                         (A-5)
 *  ins_exclusive_ctl_info       �r������Ǘ��e�[�u���o�^                       (A-5-1)
 *  validity_check               �Ó����`�F�b�N                                 (A-6)
 *  delete_process               �T���}�X�^�폜                                 (A-7)
 *  up_ins_chk                   �폜��`�F�b�N                                 (A-8)
 *  ins_up_process               �T���}�X�^�o�^��ύX����                        (A-9)
 *  condition_recovery           �T���f�[�^���J�o���R���J�����g���s����         (A-10)
 *
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/03/11    1.0   Y.Sasaki         �V�K�쐬
 *  2020/09/25    1.0   H.Ishii          �ǉ��ۑ�Ή�
 *  2021/04/06    1.1   H.Futamura       E_�{�ғ�_16026
 *  2021/04/28    1.2   A.AOKI           E_�{�ғ�_16026 �≮�}�[�W���C���i�~�j��0�~������
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
  gn_chk_cnt       NUMBER;
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
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
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
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCOK024A01C'; -- �p�b�P�[�W��
--
  ct_language                       CONSTANT fnd_lookup_values.language%TYPE  := USERENV('LANG'); -- ����
--
  cv_csv_delimiter                  CONSTANT VARCHAR2(1)  := ',';   -- �J���}
  cv_colon                          CONSTANT VARCHAR2(2)  := '�F';  -- �R����
  cv_space                          CONSTANT VARCHAR2(2)  := ' ';   -- ���p�X�y�[�X
  cv_const_y                        CONSTANT VARCHAR2(1)  := 'Y';   -- 'Y'
  cv_const_n                        CONSTANT VARCHAR2(1)  := 'N';   -- 'N'
--
  -- ���l
  cn_zero                           CONSTANT NUMBER := 0;   -- 0
  cn_one                            CONSTANT NUMBER := 1;   -- 1
  cn_100                            CONSTANT NUMBER := 100; -- 100
  cn_minus_one                      CONSTANT NUMBER := -1;  -- -1
--
  cn_process_type                   CONSTANT NUMBER := 1;   -- �����敪
  cn_condition_no                   CONSTANT NUMBER := 2;   -- �T���ԍ�
  cn_corp_code                      CONSTANT NUMBER := 3;   -- ��ƃR�[�h
  cn_deduction_chain_code           CONSTANT NUMBER := 4;   -- �T���p�`�F�[���R�[�h
  cn_customer_code                  CONSTANT NUMBER := 5;   -- �ڋq�R�[�h
  cn_data_type                      CONSTANT NUMBER := 6;   -- �f�[�^���
  cn_tax_code                       CONSTANT NUMBER := 7;   -- �ŃR�[�h
  cn_start_date_active              CONSTANT NUMBER := 8;   -- �J�n��
  cn_end_date_active                CONSTANT NUMBER := 9;   -- �I����
  cn_content                        CONSTANT NUMBER := 10;  -- ���e
  cn_decision_no                    CONSTANT NUMBER := 11;  -- ����No
  cn_agreement_no                   CONSTANT NUMBER := 12;  -- �_��ԍ�
  cn_detail_number                  CONSTANT NUMBER := 13;  -- ���הԍ�
  cn_target_category                CONSTANT NUMBER := 14;  -- �Ώۋ敪
  cn_product_class                  CONSTANT NUMBER := 15;  -- ���i�敪
  cn_item_code                      CONSTANT NUMBER := 16;  -- �i�ڃR�[�h
  cn_uom_code                       CONSTANT NUMBER := 17;  -- �P��
  cn_shop_pay_1                     CONSTANT NUMBER := 18;  -- �X�[(��)_1
  cn_material_rate_1                CONSTANT NUMBER := 19;  -- ����(��)_1
  cn_demand_en_3                    CONSTANT NUMBER := 20;  -- ����(�~)_3
  cn_shop_pay_en_3                  CONSTANT NUMBER := 21;  -- �X�[(�~)_3
  cn_wholesale_margin_en_3          CONSTANT NUMBER := 22;  -- �≮�}�[�W��(�~)_3
  cn_wholesale_margin_per_3         CONSTANT NUMBER := 23;  -- �≮�}�[�W��(��)_3
  cn_normal_shop_pay_en_4           CONSTANT NUMBER := 24;  -- �ʏ�X�[(�~)_4
  cn_just_shop_pay_en_4             CONSTANT NUMBER := 25;  -- ����X�[(�~)_4
  cn_wholesale_adj_margin_en_4      CONSTANT NUMBER := 26;  -- �≮�}�[�W���C��(�~)_4
  cn_wholesale_adj_margin_per_4     CONSTANT NUMBER := 27;  -- �≮�}�[�W���C��(��)_4
  cn_prediction_qty_5_6             CONSTANT NUMBER := 28;  -- �\������(�{)_5_6
  cn_support_amount_sum_en_5        CONSTANT NUMBER := 29;  -- ���^�����v(�~)_5
  cn_condition_unit_price_en_2_6    CONSTANT NUMBER := 30;  -- �����P��(�~)_6
  cn_target_rate_6                  CONSTANT NUMBER := 31;  -- �Ώۗ�(��)_6
-- 2021/04/06 Ver1.1 MOD Start
--  cn_accounting_base                CONSTANT NUMBER := 32;  -- �v�㋒�_
  cn_accounting_customer_code       CONSTANT NUMBER := 32;  -- �v��ڋq
-- 2021/04/06 Ver1.1 MOD End
  cn_deduction_amount               CONSTANT NUMBER := 33;  -- �T���z(�{��)
  cn_deduction_tax_amount           CONSTANT NUMBER := 34;  -- �T���Ŋz
  cn_c_header                       CONSTANT NUMBER := 35;  -- CSV�t�@�C�����ڐ��i�擾�Ώہj
  cn_c_header_all                   CONSTANT NUMBER := 36;  -- CSV�t�@�C�����ڐ��i�S���ځj
--
  cv_process_delete                 CONSTANT VARCHAR2(1)  :=  'D';    -- �����敪(�폜)
  cv_process_update                 CONSTANT VARCHAR2(1)  :=  'U';    -- �����敪(�X�V)
  cv_process_insert                 CONSTANT VARCHAR2(1)  :=  'I';    -- �����敪(�o�^)
  cv_process_decision               CONSTANT VARCHAR2(1)  :=  'Z';      -- �����敪(����)
  cv_csv_delete                     CONSTANT VARCHAR2(4)  :=  '�폜';   -- CSV�����敪(�폜)
  cv_csv_update                     CONSTANT VARCHAR2(4)  :=  '�C��';   -- CSV�����敪(�C��)
  cv_csv_insert                     CONSTANT VARCHAR2(4)  :=  '�o�^';   -- CSV�����敪(�o�^)
  cv_csv_decision                   CONSTANT VARCHAR2(4)  :=  '����';   -- CSV�����敪(����)
--
  cv_condition_type_req             CONSTANT VARCHAR2(3)  :=  '010';  -- �T���^�C�v(�����z�~����(��))
  cv_condition_type_sale            CONSTANT VARCHAR2(3)  :=  '020';  -- �T���^�C�v(�̔����ʁ~���z)
  cv_condition_type_ws_fix          CONSTANT VARCHAR2(3)  :=  '030';  -- �T���^�C�v(�≮�����i��z�j)
  cv_condition_type_ws_add          CONSTANT VARCHAR2(3)  :=  '040';  -- �T���^�C�v(�≮�����i�ǉ��j)
  cv_condition_type_spons           CONSTANT VARCHAR2(3)  :=  '050';  -- �T���^�C�v(��z���^��)
  cv_condition_type_pre_spons       CONSTANT VARCHAR2(3)  :=  '060';  -- �T���^�C�v(�Ώې��ʗ\�����^��)
  cv_condition_type_fix_con         CONSTANT VARCHAR2(3)  :=  '070';  -- �T���^�C�v(��z�T��)
  cv_cust_cls_10                    CONSTANT VARCHAR2(2)  :=  '10';   -- �ڋq�敪(10)
  cv_cust_accounts_status           CONSTANT VARCHAR2(1)  :=  'A';    -- �ڋq�X�e�[�^�X
  cv_parties_status                 CONSTANT VARCHAR2(1)  :=  'A';    -- �p�[�e�B�X�e�[�^�X
  cv_cust_class_base                CONSTANT VARCHAR2(2)  :=  '1';    -- ���_�i�ڋq�敪�j
  cv_cust_class_cust                CONSTANT VARCHAR2(2)  :=  '10';   -- �ڋq�i�ڋq�敪�j
--
  cv_uom_hon                        CONSTANT VARCHAR2(3)  :=  '�{';   -- �P�ʁi�{�j
  cv_uom_cs                         CONSTANT VARCHAR2(2)  :=  'CS';   -- �P�ʁiCS�j
  cv_uom_bl                         CONSTANT VARCHAR2(2)  :=  'BL';   -- �P�ʁiBL�j
--
  cv_shop_pay                       CONSTANT VARCHAR2(6)  :=  '�X�['; -- �X�[
--
  cv_month_jan                      CONSTANT VARCHAR2(2)  :=  '01';   -- 1��
  cv_month_feb                      CONSTANT VARCHAR2(2)  :=  '02';   -- 2��
  cv_month_mar                      CONSTANT VARCHAR2(2)  :=  '03';   -- 3��
  cv_month_apr                      CONSTANT VARCHAR2(2)  :=  '04';   -- 4��
--
  cv_data_rec_conc                  CONSTANT VARCHAR2(50) := 'XXCOK024A09C';  -- �T���f�[�^���J�o���R���J�����g
--
  -- �o�̓^�C�v
  cv_file_type_out                  CONSTANT VARCHAR2(10) := 'OUTPUT';        -- �o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log                  CONSTANT VARCHAR2(10) := 'LOG';           -- ���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- �����}�X�N
  cv_date_format                    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';    -- ���t����
  cv_date_year                      CONSTANT VARCHAR2(4)  := 'YYYY';          -- �N
  cv_date_month                     CONSTANT VARCHAR2(2)  := 'MM';            -- ��
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cok                    CONSTANT VARCHAR2(5)  := 'XXCOK'; -- �A�h�I���F�ʊJ��
  cv_msg_kbn_cos                    CONSTANT VARCHAR2(5)  := 'XXCOS'; -- �A�h�I���F�̔�
  cv_msg_kbn_coi                    CONSTANT VARCHAR2(5)  := 'XXCOI'; -- �A�h�I���F�݌�
  cv_msg_kbn_csm                    CONSTANT VARCHAR2(5)  := 'XXCSM'; -- �A�h�I���F�o�c
  cv_msg_kbn_ccp                    CONSTANT VARCHAR2(5)  := 'XXCCP'; -- ���ʂ̃��b�Z�[�W
--
  -- �v���t�@�C��
  cv_set_of_bks_id                  CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';          -- ��v����ID
  cv_item_div_h                     CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';         -- �{�Џ��i�敪
  cv_prf_org                        CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_org_id                     CONSTANT VARCHAR2(30) := 'ORG_ID';                    -- �g�DID
--
  -- �Q�ƃ^�C�v
  cv_type_upload_obj                CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';      -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_type_deduction_data            CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- �T���f�[�^���
  cv_type_chain_code                CONSTANT VARCHAR2(30) := 'XXCMM_CHAIN_CODE';            -- �`�F�[���R�[�h
  cv_type_business_type             CONSTANT VARCHAR2(30) := 'XX03_BUSINESS_TYPE';          -- ��ƃ^�C�v
  cv_type_deduction_1_kbn           CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_1_KBN';      -- �����z�~�����i���j�敪
  cv_type_dec_pri_base              CONSTANT VARCHAR2(30) := 'XXCOK1_DEC_PRIVILEGE_BASE';   -- �T���}�X�^�������_
  cv_type_dec_del_dept              CONSTANT VARCHAR2(30) := 'XXCOK1_DEC_DEL_PRI_DEPT';     -- �T���}�X�^�폜��������
  cv_type_deduction_type            CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_TYPE';       -- �T���^�C�v
  cv_type_deduction_kbn             CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_KBN';        -- �T���敪
  cv_type_column_digit_chk          CONSTANT VARCHAR2(30) := 'XXCOK1_XXCOK024A01C_DIGIT_CHK'; -- csv�A�b�v���[�h���ڌ����`�F�b�N
--
  -- ����R�[�h
  ct_lang                           CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ���b�Z�[�W��
  cv_msg_ccp_90000                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_msg_ccp_90002                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_msg_ccp_90003                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
  cv_msg_ccp_00001                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00001';  -- �x���������b�Z�[�W
--
  cv_msg_cok_00016                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00016';  -- �t�@�C��ID�o�͗p���b�Z�[�W
  cv_msg_cok_00017                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00017';  -- �t�@�C���p�^�[���o�͗p���b�Z�[�W
  cv_msg_cok_00028                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';  -- �Ɩ����t�擾�G���[
  cv_msg_cos_00001                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';  -- ���b�N�G���[
  cv_msg_cos_11294                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11294';  -- CSV�t�@�C�����擾�G���[
  cv_msg_cok_00006                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00006';  -- �t�@�C�����o�͗p���b�Z�[�W
  cv_msg_cok_00106                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00106';  -- �t�@�C���A�b�v���[�h���̏o�͗p���b�Z�[�W
  cv_msg_cok_00039                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00039';  -- CSV�t�@�C���f�[�^�Ȃ��G���[���b�Z�[�W
  cv_msg_cok_00003                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cok_00005                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00005';  -- �]�ƈ��擾�G���[���b�Z�[�W
  cv_msg_cos_00013                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_coi_10633                  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10633';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_cos_11295                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11295';  -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
  cv_msg_cok_10622                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10622';  -- ���[�N�e�[�u���o�^�G���[
  cv_msg_cok_10586                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10586';  -- �f�[�^�o�^�G���[
  cv_msg_cok_10587                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10587';  -- �f�[�^�X�V�G���[
--
  cv_msg_cok_10596                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10596';  -- �T���}�X�^CSV������
  cv_msg_cok_10597                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10597';  -- �Œ�l�s���G���[
  cv_msg_cok_10598                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10598';  -- �ݒ�s�G���[
  cv_msg_cok_10599                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10599';  -- �g�ݍ��킹�G���[
  cv_msg_cok_10600                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10600';  -- �}�X�^���o�^�G���[
  cv_msg_cok_10602                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10602';  -- ���t�s���G���[
  cv_msg_cok_10604                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10604';  -- �L�����ԓ�����s�G���[
  cv_msg_cok_10605                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10605';  -- �K�{���ږ��ݒ�G���[(����)
  cv_msg_cok_10606                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10606';  -- �K�{���ږ��ݒ�G���[
  cv_msg_cok_10607                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10607';  -- �K�{���ږ��ݒ�G���[(�I��)
  cv_msg_cok_10608                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10608';  -- �d���G���[
  cv_msg_cok_10609                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10609';  -- �ݒ�l�s��v�G���[
  cv_msg_cok_10612                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10612';  -- �Z�L�����e�B�G���[
  cv_msg_cok_10613                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10613';  -- �������_�Z�L�����e�B�G���[
  cv_msg_cok_10614                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10614';  -- �r������G���[
  cv_msg_cok_10615                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10615';  -- �R���J�����g�Ăяo���G���[
  cv_msg_cok_10670                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10670';  -- �T���ԍ������G���[
  cv_msg_cok_10671                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10671';  -- �P�ʕs���G���[
  cv_msg_cok_00015                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00015';  -- �N�C�b�N�R�[�h�擾�G���[
  cv_msg_cok_10623                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10623';  -- �V�[�P���X�擾�G���[
  cv_msg_cok_00012                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00012';  -- �������_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cok_00030                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00030';  -- ��������R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cok_10676                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10676';  -- �T���ԍ��V�[�P���X�G���[
  cv_msg_cok_10677                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10677';  -- �f�[�^���J�o���R���J�����g���s���b�Z�[�W
  cv_msg_cok_10678                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10678';  -- �����敪�g�ݍ��킹�G���[
  cv_msg_cok_10682                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10682';  -- �Q�ƕ\���ݒ�G���[
  cv_msg_cok_10709                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10709';  -- ���ڕs���G���[���b�Z�[�W
  cv_msg_cok_10703                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10703';  -- �J�n���C���ۃG���[
  cv_msg_cok_10704                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10704';  -- �I�����C���ۃG���[
  cv_msg_cok_10705                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10705';  -- �I�����C���͈̓G���[
  cv_msg_cok_10710                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10710';  -- ��z�T���}�X�^�o�^�G���[
-- 2021/04/06 Ver1.1 ADD Start
  cv_msg_cok_10794                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10794';  -- �q�i�ڃG���[
  cv_msg_cok_10795                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10795';  -- �o�^���
-- 2021/04/06 Ver1.1 ADD End
--
  cv_tkn_coi_10634                  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10634';  -- �t�@�C���A�b�v���[�hIF
  cv_prf_org_err_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';  -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_err_msg                 CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
--
  -- �g�[�N����
  cv_file_id_tok                    CONSTANT VARCHAR2(20) := 'FILE_ID';           -- �t�@�C��ID
  cv_format_tok                     CONSTANT VARCHAR2(20) := 'FORMAT';            -- �t�H�[�}�b�g
  cv_table_tok                      CONSTANT VARCHAR2(20) := 'TABLE';             -- �e�[�u����
  cv_key_data_tok                   CONSTANT VARCHAR2(20) := 'KEY_DATA';          -- ����ł���L�[���e���R�����g�����ăZ�b�g���܂��B
  cv_file_name_tok                  CONSTANT VARCHAR2(20) := 'FILE_NAME';         -- �t�@�C����
  cv_upload_object_tok              CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';     -- �A�b�v���[�h�t�@�C����
  cv_profile_tok                    CONSTANT VARCHAR2(20) := 'PROFILE';           -- �v���t�@�C����
  cv_empcd_tok                      CONSTANT VARCHAR2(20) := 'JUGYOIN_CD';        -- �]�ƈ��R�[�h
  cv_gcd_tok                        CONSTANT VARCHAR2(20) := 'GET_CUSTOM_DATE';   -- �ڋq�l����
  cv_table_name_tok                 CONSTANT VARCHAR2(20) := 'TABLE_NAME';        -- �e�[�u����
  cv_data_tok                       CONSTANT VARCHAR2(20) := 'DATA';              -- �f�[�^
  cv_col_name_tok                   CONSTANT VARCHAR2(20) := 'COLUMN_NAME';       -- ���ږ�
  cv_col_value_tok                  CONSTANT VARCHAR2(20) := 'COLUMN_VALUE';      -- ���ڒl
  cv_start_date_tok                 CONSTANT VARCHAR2(20) := 'START_DATE';        -- �J�n��
  cv_end_date_tok                   CONSTANT VARCHAR2(20) := 'END_DATE';          -- �I����
  cv_if_value_tok                   CONSTANT VARCHAR2(20) := 'IF_VALUE';          -- ����
  cv_line_num_tok                   CONSTANT VARCHAR2(20) := 'LINE_NUM';          -- CSV�̍s�ԍ�
  cv_col_name_2_tok                 CONSTANT VARCHAR2(20) := 'COLUMN_NAME2';      -- ���ږ�
  cv_pg_name_tok                    CONSTANT VARCHAR2(20) := 'PG_NAME';           -- �R���J�����g��
  cv_lookup_value_set               CONSTANT VARCHAR2(20) := 'LOOKUP_VALUE_SET';  -- �Q�ƕ\��
  cv_tkn_err_msg                    CONSTANT VARCHAR2(20) := 'ERR_MSG';           -- �G���[���b�Z�[�W
  cv_tkn_user_id                    CONSTANT VARCHAR2(7)  := 'USER_ID';           -- ���[�U�[ID
  cv_tkn_process_type               CONSTANT VARCHAR2(12) := 'PROCESS_TYPE';      -- �����敪
  cv_tkn_request_id                 CONSTANT VARCHAR2(10) := 'REQUEST_ID';        -- �v���h�c
  cv_tkn_condition_type             CONSTANT VARCHAR2(14) := 'CONDITION_TYPE';    -- �T���^�C�v
  cv_tkn_pro                        CONSTANT VARCHAR2(20) := 'PRO_TOK';           -- �v���t�@�C���g�[�N��
  cv_tkn_org                        CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';      -- ORG_CODE�g�[�N��
  cv_tkn_code                       CONSTANT VARCHAR2(20) := 'CODE';              -- �R�[�h�l
  cv_tkn_item                       CONSTANT VARCHAR2(20) := 'ITEM';              -- ����
  cv_tkn_record_no                  CONSTANT VARCHAR2(20) := 'RECORD_NO';         -- ���R�[�hNo
  cv_tkn_errmsg                     CONSTANT VARCHAR2(20) := 'ERRMSG';            -- �G���[���e�ڍ�

--
  --���b�Z�[�W����
  cv_msg_condition_h                CONSTANT VARCHAR2(16) := '�T�������e�[�u��';
  cv_msg_condition_l                CONSTANT VARCHAR2(16) := '�T���ڍ׃e�[�u��';
  cv_msg_delete                     CONSTANT VARCHAR2(4)  := '�폜';
  cv_msg_insert                     CONSTANT VARCHAR2(4)  := '�o�^';
  cv_msg_update                     CONSTANT VARCHAR2(4)  := '�X�V';
  cv_msg_decision                   CONSTANT VARCHAR2(4)  := '����';
  cv_msg_pro_type                   CONSTANT VARCHAR2(8)  := '�����敪';
  cv_msg_dtl_pro_type               CONSTANT VARCHAR2(12) := '���׏����敪';
  cv_msg_condition_no               CONSTANT VARCHAR2(8)  := '�T���ԍ�';
  cv_msg_detail_num                 CONSTANT VARCHAR2(8)  := '���הԍ�';
  cv_msg_kigyo_code                 CONSTANT VARCHAR2(10) := '��ƃR�[�h';
  cv_msg_chain_code                 CONSTANT VARCHAR2(20) := '�T���p�`�F�[���R�[�h';
  cv_msg_cust_code                  CONSTANT VARCHAR2(10) := '�ڋq�R�[�h';
  cv_msg_data_type                  CONSTANT VARCHAR2(10) := '�f�[�^���';
  cv_msg_condition_type             CONSTANT VARCHAR2(10) := '�T���^�C�v';
  cv_msg_condition_cls              CONSTANT VARCHAR2(10) := '�T���敪';
  cv_msg_agreement_no               CONSTANT VARCHAR2(8)  := '�_��ԍ�';
  cv_msg_item_kbn                   CONSTANT VARCHAR2(8)  := '���i�敪';
  cv_msg_target_cate                CONSTANT VARCHAR2(8)  := '�Ώۋ敪';
  cv_msg_start_date                 CONSTANT VARCHAR2(6)  := '�J�n��';
  cv_msg_end_date                   CONSTANT VARCHAR2(6)  := '�I����';
  cv_msg_item_code                  CONSTANT VARCHAR2(10) := '�i�ڃR�[�h';
  cv_msg_item_mst                   CONSTANT VARCHAR2(10) := '�i�ڃ}�X�^';
  cv_msg_case_in_qty                CONSTANT VARCHAR2(4)  := '����';
  cv_msg_sup_amt_sum                CONSTANT VARCHAR2(16) := '���^�����v�i�~�j';
  cv_delimiter                      CONSTANT VARCHAR2(2)  := '�A';
  cv_msg_shop_pay                   CONSTANT VARCHAR2(50) := '�X�[';
  cv_msg_meter_rate                 CONSTANT VARCHAR2(50) := '����';
  cv_msg_con_u_p_en                 CONSTANT VARCHAR2(50) := '�����P��';
  cv_msg_uom_code                   CONSTANT VARCHAR2(50) := '�P��';
  cv_msg_demand_en                  CONSTANT VARCHAR2(50) := '����';
  cv_msg_who_margin                 CONSTANT VARCHAR2(50) := '�≮�}�[�W��';
  cv_msg_normal_sp                  CONSTANT VARCHAR2(50) := '�ʏ�X�[';
  cv_msg_just_sp                    CONSTANT VARCHAR2(50) := '����X�[';
  cv_msg_prediction                 CONSTANT VARCHAR2(50) := '�\������';
  cv_msg_tar_rate                   CONSTANT VARCHAR2(50) := '�Ώۗ�';
-- 2021/04/06 Ver1.1 MOD Start
--  cv_msg_accounting_base            CONSTANT VARCHAR2(50) := '�v�㋒�_';
  cv_msg_account_customer_code      CONSTANT VARCHAR2(50) := '�v��ڋq';
  cv_msg_content                    CONSTANT VARCHAR2(50) := '���e';
-- 2021/04/06 Ver1.1 MOD End
  cv_msg_con_amout                  CONSTANT VARCHAR2(50) := '�T���z�i�{�́j';
  cv_msg_tax_code                   CONSTANT VARCHAR2(50) := '�ŃR�[�h';
  cv_msg_con_tax                    CONSTANT VARCHAR2(50) := '�T���Ŋz';
  cv_msg_header                     CONSTANT VARCHAR2(50) := '�w�b�_�[';
  cv_msg_line                       CONSTANT VARCHAR2(50) := '����';
  cv_msg_csv_line                   CONSTANT VARCHAR2(50) := '�s��';
-- 2021/04/06 Ver1.1 ADD Start
  cv_msg_child_item_code            CONSTANT VARCHAR2(50) := '�q�i��';
-- 2021/04/06 Ver1.1 ADD End
--
  cv_msg_parsent                    CONSTANT VARCHAR2(9)  := '�i���j';
  cv_msg_yen                        CONSTANT VARCHAR2(9)  := '�i�~�j';
  cv_msg_hon                        CONSTANT VARCHAR2(9)  := '�i�{�j';
  cv_msg_ja_to                      CONSTANT VARCHAR2(3)  := '��';
  cv_msg_ja_ga                      CONSTANT VARCHAR2(3)  := '��';
  cv_msg_adj                        CONSTANT VARCHAR2(6)  := '�C��';
  cv_msg_tonya                      CONSTANT VARCHAR2(50) := '�≮����';
  cv_msg_condition_mst              CONSTANT VARCHAR2(20) := '�T���}�X�^�f�[�^';
  cv_msg_lookup_d_kbn               CONSTANT VARCHAR2(20) := '�Q�ƕ\�F�T���敪';
  cv_msg_lookup_d_type              CONSTANT VARCHAR2(20) := '�Q�ƕ\�F�T���^�C�v';
--
  -- �_�~�[�l
  cv_dummy_char                     CONSTANT VARCHAR2(100)  := 'DUMMY99999999'; -- ������p�_�~�[�l
  cd_dummy_date                     CONSTANT DATE           := TO_DATE( '1900/01/01', 'YYYY/MM/DD' );
                                                                                -- ���t�p�_�~�[�l(�ŏ�)
  cd_max_date                       CONSTANT DATE           := TO_DATE( '9999/12/31', 'YYYY/MM/DD' );
                                                                                -- ���t�p�_�~�[�l(�ő�)
  cv_dummy_base                     CONSTANT VARCHAR2(1)    := 'Z';             -- ���_�R�[�h�̃_�~�[�l
  cv_dummy_code                     CONSTANT VARCHAR2(2)    := '-1';            -- �_�~�[�R�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �������ڕ�����f�[�^�i�[�p
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;   -- 1�����z��
  g_if_data_tab             g_var_data_ttype;                                     -- �����p�ϐ�
  gt_file_line_data_tab     xxccp_common_pkg2.g_file_data_tbl;                    -- CSV�f�[�^�i1�s�j
  --  �G���[���b�Z�[�W�ێ��p  �C���f�b�N�X��CSV�s�ԍ� �`�F�b�N�ԍ�
  TYPE g_csv_column IS TABLE OF VARCHAR2(4000)  INDEX BY BINARY_INTEGER;
  TYPE g_check_no   IS TABLE OF g_csv_column    INDEX BY BINARY_INTEGER;
  g_message_list_tab    g_check_no;
--
  -- ���ڃ`�F�b�N�i�[���R�[�h
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- ���ږ���
    , attribute1              fnd_lookup_values.attribute1%TYPE -- ���ڂ̒���
    , attribute2              fnd_lookup_values.attribute2%TYPE -- ���ڂ̒����i�����_�ȉ��j
    , attribute3              fnd_lookup_values.attribute3%TYPE -- �K�{�t���O
    , attribute4              fnd_lookup_values.attribute4%TYPE -- ����
  );
--
  -- �e�[�u���^�C�v
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_check_result       VARCHAR2(2);       -- �`�F�b�N����
  gv_item_div_h         VARCHAR(20);       -- �{�Џ��i�敪
  gv_emp_code           VARCHAR(30);       -- ���O�C�����[�U�̏]�ƈ��ԍ�
  gv_user_base          VARCHAR(150);      -- ���_�R�[�h
  gn_skip_cnt           NUMBER;            -- �X�L�b�v����
  gn_privilege_delete   NUMBER;            -- �폜�����i0�F�����Ȃ��A1�F��������j
  gn_privilege_up_ins   NUMBER;            -- �o�^�E�X�V�����i0�F�����Ȃ��A1�F��������j
  gd_process_date       DATE;              -- �Ɩ����t
  gn_set_of_bks_id      NUMBER;            -- ��v����ID
  gn_message_cnt        NUMBER;            -- �ő僁�b�Z�[�W��
  gt_org_code           mtl_parameters.organization_code%TYPE;
                                           -- �݌ɑg�D�R�[�h
  gt_org_id             mtl_parameters.organization_id%TYPE;
                                           -- �݌ɑg�DID
  gt_login_user_id      fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID;
                                           -- ���O�C�����[�U��ID
  gn_org_id2            NUMBER;            -- �g�DID
  g_chk_item_tab        g_chk_item_ttype;  -- ���ڃ`�F�b�N
--
  -- ===============================
  -- ���[�U��`�O���[�o���J�[�\��
  -- ===============================
  -- �d���`�F�b�N�p�J�[�\��
  CURSOR g_cond_tmp_cur
    IS
      SELECT  xct.csv_no                          AS csv_no                       --  CSV�s��
            , xct.request_id                      AS request_id                   --  �v��ID
            , xct.csv_process_type                AS csv_process_type             --  CSV�����敪
            , xct.process_type                    AS process_type                 --  �����敪
            , xct.condition_no                    AS condition_no                 --  �T���ԍ�
            , xct.corp_code                       AS corp_code                    --  ��ƃR�[�h
            , xct.deduction_chain_code            AS deduction_chain_code         --  �T���p�`�F�[���R�[�h
            , xct.customer_code                   AS customer_code                --  �ڋq�R�[�h
            , xct.data_type                       AS data_type                    --  �f�[�^���
            , xct.start_date_active               AS start_date_active            --  �J�n��
            , xct.end_date_active                 AS end_date_active              --  �I����
            , xct.content                         AS content                      --  ���e
            , xct.decision_no                     AS decision_no                  --  ����No
            , xct.agreement_no                    AS agreement_no                 --  �_��ԍ�
            , xct.process_type_line               AS process_type_line            --  ���׏����敪
            , xct.detail_number                   AS detail_number                --  ���הԍ�
            , xct.target_category                 AS target_category              --  �Ώۋ敪
            , xct.product_class                   AS product_class                --  ���i�敪
            , xct.product_class_code              AS product_class_code           --  ���i�敪�R�[�h
            , xct.item_code                       AS item_code                    --  �i�ڃR�[�h
            , xct.uom_code                        AS uom_code                     --  �P��
            , xct.shop_pay_1                      AS shop_pay_1                   --  �X�[(��)_1
            , xct.material_rate_1                 AS material_rate_1              --  ����(��)_1
            , xct.demand_en_3                     AS demand_en_3                  --  ����(�~)_3
            , xct.shop_pay_en_3                   AS shop_pay_en_3                --  �X�[(�~)_3
            , xct.wholesale_margin_en_3           AS wholesale_margin_en_3        --  �≮�}�[�W��(�~)_3
            , xct.wholesale_margin_per_3          AS wholesale_margin_per_3       --  �≮�}�[�W��(��)_3
            , xct.normal_shop_pay_en_4            AS normal_shop_pay_en_4         --  �ʏ�X�[(�~)_4
            , xct.just_shop_pay_en_4              AS just_shop_pay_en_4           --  ����X�[(�~)_4
            , xct.wholesale_adj_margin_en_4       AS wholesale_adj_margin_en_4    --  �≮�}�[�W���C��(�~)_4
            , xct.wholesale_adj_margin_per_4      AS wholesale_adj_margin_per_4   --  �≮�}�[�W���C��(��)_4
            , xct.prediction_qty_5_6              AS prediction_qty_5_6           --  �\������(�{)_5_6
            , xct.support_amount_sum_en_5         AS support_amount_sum_en_5      --  ���^�����v(�~)_5
            , xct.condition_unit_price_en_2_6     AS condition_unit_price_en_2_6  --  �����P��(�~)_6
            , xct.target_rate_6                   AS target_rate_6                --  �Ώۗ�(��)_6
-- 2021/04/06 Ver1.1 MOD Start
--            , xct.accounting_base                 AS accounting_base              --  �v�㋒�_
            , xct.accounting_customer_code        AS accounting_customer_code     --  �v��ڋq
-- 2021/04/06 Ver1.1 MOD End
            , xct.deduction_amount                AS deduction_amount             --  �T���z(�{��)
            , xct.tax_code                        AS tax_code                     --  �ŃR�[�h
            , xct.deduction_tax_amount            AS deduction_tax_amount         --  �T���Ŋz
            , xct.condition_cls                   AS condition_cls                --  �T���敪
            , xct.condition_type                  AS condition_type               --  �T���^�C�v
            , rowid                               AS row_id
      FROM    xxcok_condition_temp  xct
      WHERE   xct.request_id  = cn_request_id
      ORDER BY  xct.process_type_line
              , xct.process_type
      ;
    g_cond_tmp_rec    g_cond_tmp_cur%ROWTYPE;
--
  -- ���C���J�[�\��
  CURSOR g_cond_tmp_chk_cur
    IS
      SELECT  xct.csv_no                          AS csv_no                       --  CSV�s��
            , xct.request_id                      AS request_id                   --  �v��ID
            , xct.csv_process_type                AS csv_process_type             --  CSV�����敪
            , xct.process_type                    AS process_type                 --  �����敪
            , xct.condition_no                    AS condition_no                 --  �T���ԍ�
            , xct.corp_code                       AS corp_code                    --  ��ƃR�[�h
            , xct.deduction_chain_code            AS deduction_chain_code         --  �T���p�`�F�[���R�[�h
            , xct.customer_code                   AS customer_code                --  �ڋq�R�[�h
            , xct.data_type                       AS data_type                    --  �f�[�^���
            , xct.start_date_active               AS start_date_active            --  �J�n��
            , xct.end_date_active                 AS end_date_active              --  �I����
            , xct.content                         AS content                      --  ���e
            , xct.decision_no                     AS decision_no                  --  ����No
            , xct.agreement_no                    AS agreement_no                 --  �_��ԍ�
            , xct.process_type_line               AS process_type_line            --  ���׏����敪
            , xct.detail_number                   AS detail_number                --  ���הԍ�
            , xct.target_category                 AS target_category              --  �Ώۋ敪
            , xct.product_class                   AS product_class                --  ���i�敪
            , xct.product_class_code              AS product_class_code           --  ���i�敪�R�[�h
            , xct.item_code                       AS item_code                    --  �i�ڃR�[�h
            , xct.uom_code                        AS uom_code                     --  �P��
            , xct.shop_pay_1                      AS shop_pay_1                   --  �X�[(��)_1
            , xct.material_rate_1                 AS material_rate_1              --  ����(��)_1
            , xct.demand_en_3                     AS demand_en_3                  --  ����(�~)_3
            , xct.shop_pay_en_3                   AS shop_pay_en_3                --  �X�[(�~)_3
            , xct.wholesale_margin_en_3           AS wholesale_margin_en_3        --  �≮�}�[�W��(�~)_3
            , xct.wholesale_margin_per_3          AS wholesale_margin_per_3       --  �≮�}�[�W��(��)_3
            , xct.normal_shop_pay_en_4            AS normal_shop_pay_en_4         --  �ʏ�X�[(�~)_4
            , xct.just_shop_pay_en_4              AS just_shop_pay_en_4           --  ����X�[(�~)_4
            , xct.wholesale_adj_margin_en_4       AS wholesale_adj_margin_en_4    --  �≮�}�[�W���C��(�~)_4
            , xct.wholesale_adj_margin_per_4      AS wholesale_adj_margin_per_4   --  �≮�}�[�W���C��(��)_4
            , xct.prediction_qty_5_6              AS prediction_qty_5_6           --  �\������(�{)_5_6
            , xct.support_amount_sum_en_5         AS support_amount_sum_en_5      --  ���^�����v(�~)_5
            , xct.condition_unit_price_en_2_6     AS condition_unit_price_en_2_6  --  �����P��(�~)_6
            , xct.target_rate_6                   AS target_rate_6                --  �Ώۗ�(��)_6
-- 2021/04/06 Ver1.1 MOD Start
--            , xct.accounting_base                 AS accounting_base              --  �v�㋒�_
            , xct.accounting_customer_code        AS accounting_customer_code     --  �v��ڋq
-- 2021/04/06 Ver1.1 MOD End
            , xct.deduction_amount                AS deduction_amount             --  �T���z(�{��)
            , xct.tax_code                        AS tax_code                     --  �ŃR�[�h
            , xct.tax_rate                        AS tax_rate                     --  �ŗ�
            , xct.deduction_tax_amount            AS deduction_tax_amount         --  �T���Ŋz
            , xct.condition_cls                   AS condition_cls                --  �T���敪
            , xct.condition_type                  AS condition_type               --  �T���^�C�v
            , xct.condition_id                    AS condition_id                 --  �T������ID
            , DECODE( xct.corp_code, NULL, 0, 1 )
              + DECODE( xct.deduction_chain_code, NULL, 0, 1 )
              + DECODE( xct.customer_code, NULL, 0, 1 )
                                                  AS data_count
            , rowid                               AS row_id
      FROM    xxcok_condition_temp  xct
      WHERE   xct.request_id  = cn_request_id
      ORDER BY  xct.condition_no
               ,DECODE(xct.process_type,'N',2,1)
      ;
    g_cond_tmp_chk_rec    g_cond_tmp_chk_cur%ROWTYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �r������Ǘ��e�[�u���o�^�p�J�[�\��
    CURSOR g_exclusive_ctl_cur
    IS
      SELECT DISTINCT
              xct.condition_no      AS  condition_no
            , xct.request_id        AS  request_id
      FROM    xxcok_condition_temp xct
      WHERE   xct.request_id     = cn_request_id
      AND     xct.condition_no  IS NOT NULL
      ;
    g_exclusive_ctl_rec   g_exclusive_ctl_cur%ROWTYPE;
--

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER     --   �t�@�C��ID
   ,iv_file_format IN  VARCHAR2   --   �t�@�C���t�H�[�}�b�g
   ,ov_errbuf      OUT VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lb_retcode              BOOLEAN;        -- ���茋��
    lt_file_name            xxccp_mrp_file_ul_interface.file_name%TYPE;
    lt_file_upload_name     fnd_lookup_values.meaning%TYPE;
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
    -- ���[�J���ϐ�������
    lb_retcode          :=  FALSE;
    lt_file_name        :=  NULL;               -- �t�@�C����
    lt_file_upload_name :=  NULL;               -- �t�@�C���A�b�v���[�h����
--
    -- �O���[�o���ϐ�������
    gv_check_result :=  cv_const_y;             -- �`�F�b�N����
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��(���O)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00016  -- �t�@�C��ID�o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_file_id_tok
                   ,iv_token_value1 =>  in_file_id        -- �t�@�C��ID
                  )
    );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��(�o��)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00016  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_file_id_tok
                   ,iv_token_value1 =>  in_file_id        -- �t�@�C����
                  )
    );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��(���O)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00017  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_format_tok
                   ,iv_token_value1 =>  iv_file_format    -- �t�@�C����
                  )
    );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��(�o��)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00017  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_format_tok
                   ,iv_token_value1 =>  iv_file_format    -- �t�@�C����
                  )
    );
--
    -- ��s���o�́i���O�j
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.LOG
     ,buff  =>  ''
    );
    -- ��s���o�́i�o�́j
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.OUTPUT
     ,buff  =>  ''
    );
--
    --==============================================================
    -- �Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�ł��Ȃ��ꍇ
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00028 -- �Ɩ����t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^���b�N
    --==============================================================
    BEGIN
      SELECT  xfu.file_name     AS  file_name     -- �t�@�C����
      INTO    lt_file_name                        -- �t�@�C����
      FROM    xxccp_mrp_file_ul_interface  xfu    -- �t�@�C���A�b�v���[�hIF
      WHERE   xfu.file_id = in_file_id            -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ���b�N���擾�ł��Ȃ��ꍇ
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_cos_00001  -- ���b�N�G���[���b�Z�[�W
                       ,iv_token_name1  =>  cv_table_tok
                       ,iv_token_value1 =>  cv_tkn_coi_10634  -- �t�@�C���A�b�v���[�hIF
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- �t�@�C���A�b�v���[�h���̏��擾
    --==============================================================
    BEGIN
      SELECT  flv.meaning     AS  file_upload_name  -- �t�@�C���A�b�v���[�h����
      INTO    lt_file_upload_name                   -- �t�@�C���A�b�v���[�h����
      FROM    fnd_lookup_values flv                 -- �N�C�b�N�R�[�h
      WHERE   flv.lookup_type  = cv_type_upload_obj
      AND     flv.lookup_code  = iv_file_format
      AND     flv.enabled_flag = cv_const_y
      AND     flv.language     = ct_lang
      AND     NVL(flv.start_date_active, gd_process_date) <= gd_process_date
      AND     NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
      ;
    EXCEPTION
      -- �t�@�C���A�b�v���[�h���̂��擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cos
                       ,iv_name         =>  cv_msg_cos_11294  -- �t�@�C���A�b�v���[�h���̎擾�G���[���b�Z�[�W
                       ,iv_token_name1  =>  cv_key_data_tok
                       ,iv_token_value1 =>  iv_file_format    -- �t�H�[�}�b�g�p�^�[��
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- �擾�����t�@�C�����A�t�@�C���A�b�v���[�h���̂��o��
    --==============================================================
    -- �t�@�C�������o�́i���O�j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- �t�@�C����
                  )
    );
    -- �t�@�C�������o�́i�o�́j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- �t�@�C����
                  )
    );
--
    -- �t�@�C���A�b�v���[�h���̂��o�́i���O�j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- �t�@�C���A�b�v���[�h����
                  )
    );
    -- �t�@�C���A�b�v���[�h���̂��o�́i�o�́j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- �t�@�C���A�b�v���[�h����
                  )
    );
--
    -- ��s���o�́i���O�j
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.LOG
     ,buff  =>  ''
    );
    -- ��s���o�́i�o�́j
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.OUTPUT
     ,buff  =>  ''
    );
--
    --==============================================================
    -- �{�Џ��i�敪�̎擾
    --==============================================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gv_item_div_h IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00003
                     ,iv_token_name1  =>  cv_profile_tok
                     ,iv_token_value1 =>  cv_item_div_h   -- �v���t�@�C���F�{�Џ��i�敪
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C�������v����ID�擾
    --==============================================================
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- �擾�ł��Ȃ��ꍇ
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00003
                     ,iv_token_name1  =>  cv_profile_tok
                     ,iv_token_value1 =>  cv_set_of_bks_id   -- �v���t�@�C���F��v����ID
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����݌ɑg�D�R�[�h�擾
    --==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_prf_org_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���ʊ֐����݌ɑg�DID�擾
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_org_id_err_msg
                     , iv_token_name1  => cv_tkn_org
                     , iv_token_value1 => gt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C������g�DID�擾
    --==============================================================
    gn_org_id2 :=  TO_NUMBER(fnd_profile.value(cv_prf_org_id));
    IF (gn_org_id2 IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg( 
                      iv_application  => cv_msg_kbn_coi
                    , iv_name         => cv_prf_org_err_msg
                    , iv_token_name1  => cv_tkn_pro
                    , iv_token_value1 => cv_prf_org_id
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ���O�C�����[�U�̏������_���擾
    --==============================================================
    gv_user_base      :=  xxcok_common_pkg.get_base_code_f(
      id_proc_date            =>  gd_process_date,
      in_user_id              =>  gt_login_user_id
      );
    IF ( gv_user_base IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_00012
                   , iv_token_name1  => cv_tkn_user_id
                   , iv_token_value1 => gt_login_user_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    END IF;
--
    --==============================================================
    -- �폜�����̂��郆�[�U�[���m�F
    --==============================================================
    BEGIN
      SELECT  COUNT(1)      AS  cnt
      INTO    gn_privilege_delete
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type   = cv_type_dec_pri_base
      AND     flv.lookup_code   = gv_user_base
      AND     flv.enabled_flag  = cv_const_y
      AND     flv.language      = ct_language
      AND     gd_process_date BETWEEN flv.start_date_active 
                              AND     NVL(flv.end_date_active,gd_process_date)
      ;
    END;
--
    --==============================================================
    -- �������_�̏������[�U���m�F
    --==============================================================
    BEGIN
      SELECT  COUNT(1)      AS  cnt
      INTO    gn_privilege_up_ins
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type   = cv_type_dec_pri_base
      AND     flv.lookup_code   = gv_user_base
      AND     flv.enabled_flag  = cv_const_y
      AND     flv.language      = ct_language
      AND     gd_process_date BETWEEN flv.start_date_active 
                              AND     NVL(flv.end_date_active,gd_process_date)
      ;
    END;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
    /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : IF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id     IN  NUMBER     --   �t�@�C��ID
   ,iv_file_format IN  VARCHAR2   --   �t�@�C���t�H�[�}�b�g
   ,ov_errbuf      OUT VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
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
    lt_file_name        xxccp_mrp_file_ul_interface.file_name%TYPE;        -- �t�@�C����
    lt_file_upload_name fnd_lookup_values.description%TYPE;                -- �t�@�C���A�b�v���[�h����
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
    -- �t�@�C���A�b�v���[�hIF�f�[�^���擾
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- �t�@�C��ID
     ,ov_file_data => gt_file_line_data_tab -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���ʊ֐��G���[�̏ꍇ
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_cos_00013  -- �f�[�^���o�G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_table_name_tok
                     ,iv_token_value1 =>  cv_tkn_coi_10634  -- �t�@�C���A�b�v���[�hIF
                     ,iv_token_name2  =>  cv_key_data_tok
                     ,iv_token_value2 =>  NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����ݒ�
    gn_target_cnt := gt_file_line_data_tab.COUNT - 1;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : IF�f�[�^�폜(A-3)
   ***********************************************************************************/
  PROCEDURE delete_if_data(
    in_file_id       IN  NUMBER     -- �t�@�C��ID
   ,ov_errbuf        OUT VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode       OUT VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg        OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_if_data'; -- �v���O������
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
    -- �t�@�C���A�b�v���[�hIF�f�[�^�폜
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface  xfu -- �t�@�C���A�b�v���[�hIF
      WHERE xfu.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        -- �폜�Ɏ��s�����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10633  -- �f�[�^�폜�G���[���b�Z�[�W
                       ,iv_token_name1  =>  cv_table_name_tok
                       ,iv_token_value1 =>  cv_tkn_coi_10634  -- �t�@�C���A�b�v���[�hIF
                       ,iv_token_name2  =>  cv_key_data_tok
                       ,iv_token_value2 =>  SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- �f�[�^�����o���݂̂̏ꍇ�G���[
    IF gn_target_cnt = cn_zero THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00039  -- CSV�t�@�C���f�[�^�Ȃ��G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_file_id_tok
                     ,iv_token_value1 =>  in_file_id        -- �t�@�C��ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : �A�b�v���[�h�t�@�C�����ڕ���(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_file_if_loop_cnt   IN  NUMBER    --   IF���[�v�J�E���^
   ,ov_errbuf             OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_rec_data         VARCHAR2(32765);  -- ���R�[�h�f�[�^
    lv_cast_date_flag   VARCHAR2(1);
    lv_data_type        fnd_lookup_values.lookup_code%TYPE; -- �f�[�^���
    lv_condition_cls    fnd_lookup_values.attribute1%TYPE;  -- �T���敪
    lv_condition_type   fnd_lookup_values.attribute2%TYPE;  -- �T���^�C�v
    ln_dummy            NUMBER;
    ln_err_chk          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ڃ`�F�b�N�J�[�\��
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- ���ږ���
           , flv.attribute1    AS attribute1  -- ���ڂ̒���
           , flv.attribute2    AS attribute2  -- ���ڂ̒����i�����_�ȉ��j
           , flv.attribute3    AS attribute3  -- �K�{�t���O
           , flv.attribute4    AS attribute4  -- ����
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_type_column_digit_chk
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_const_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
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
    -- ���[�J���ϐ�������--
    lv_rec_data  := NULL; -- ���R�[�h�f�[�^
--
    -- ���ڐ��`�F�b�N
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) < ( cn_c_header_all - 1 ) )
    THEN
      -- ���ڐ��s��v�̏ꍇ
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cos
                     ,iv_name         =>  cv_msg_cos_11295  -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_data_tok
                     ,iv_token_value1 =>  lv_rec_data       -- �t�H�[�}�b�g�p�^�[��
                   );
      ov_errbuf := chr(10) || lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �������[�v
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                              iv_char     =>  gt_file_line_data_tab(in_file_if_loop_cnt)
                            , iv_delim    =>  cv_csv_delimiter
                            , in_part_num =>  i
                          );
    END LOOP data_split_loop;
--
    IF (g_if_data_tab(cn_process_type) IS NOT NULL ) THEN
      -- �T���敪�A�T���^�C�v�擾
      BEGIN
        SELECT  flv.lookup_code     AS  data_type
              , flv.attribute1      AS  condition_class
              , flv.attribute2      AS  condition_type
        INTO    lv_data_type
              , lv_condition_cls
              , lv_condition_type
        FROM    fnd_lookup_values flv
        WHERE   flv.lookup_type       = cv_type_deduction_data
        AND     flv.language          = ct_language
        AND     flv.meaning           = g_if_data_tab(cn_data_type)
        AND     flv.enabled_flag      = cv_const_y
        AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                AND     NVL(flv.end_date_active, gd_process_date)
        ;
--
        -- �T���敪�̃`�F�b�N
        IF  lv_condition_cls IS NOT NULL THEN
          BEGIN
            SELECT  COUNT(1)
            INTO    ln_dummy
            FROM    fnd_lookup_values flv
            WHERE   flv.lookup_type       = cv_type_deduction_kbn
            AND     flv.language          = ct_language
            AND     flv.lookup_code       = lv_condition_cls
            AND     flv.enabled_flag      = cv_const_y
            AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                AND     NVL(flv.end_date_active, gd_process_date)
            ;
          END;
        END IF;
--
        IF  lv_condition_cls IS NULL OR ln_dummy = 0 THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_cok
                         ,iv_name         =>  cv_msg_cok_10682
                         ,iv_token_name1  =>  cv_table_tok
                         ,iv_token_value1 =>  cv_msg_lookup_d_kbn
                         ,iv_token_name2  =>  cv_tkn_code
                         ,iv_token_value2 =>  lv_condition_cls
                         ,iv_token_name3  =>  cv_col_name_tok
                         ,iv_token_value3 =>  cv_msg_data_type
                         ,iv_token_name4  =>  cv_col_value_tok
                         ,iv_token_value4 =>  g_if_data_tab(cn_data_type)
                       );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
        END IF;
        -- �T���^�C�v�̃`�F�b�N
        IF  lv_condition_type IS NOT NULL THEN
          BEGIN
            SELECT  COUNT(1)
            INTO    ln_dummy
            FROM    fnd_lookup_values flv
            WHERE   flv.lookup_type       = cv_type_deduction_type
            AND     flv.language          = ct_language
            AND     flv.lookup_code       = lv_condition_type
            AND     flv.enabled_flag      = cv_const_y
            AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                    AND     NVL(flv.end_date_active, gd_process_date)
            ;
            END;
        END IF;
--
        IF  lv_condition_cls IS NULL OR ln_dummy = 0 THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_cok
                         ,iv_name         =>  cv_msg_cok_10682
                         ,iv_token_name1  =>  cv_table_tok
                         ,iv_token_value1 =>  cv_msg_lookup_d_type
                         ,iv_token_name2  =>  cv_tkn_code
                         ,iv_token_value2 =>  lv_condition_type
                         ,iv_token_name3  =>  cv_col_name_tok
                         ,iv_token_value3 =>  cv_msg_data_type
                         ,iv_token_name4  =>  cv_col_value_tok
                         ,iv_token_value4 =>  g_if_data_tab(cn_data_type)
                       );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_cok
                         ,iv_name         =>  cv_msg_cok_00015
                         ,iv_token_name1  =>  cv_lookup_value_set
                         ,iv_token_value1 =>  cv_msg_data_type
                       );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --********************************************************
      --* �����`�F�b�N����
      --********************************************************
      -- �J�[�\���I�[�v��
      OPEN chk_item_cur;
      -- �f�[�^�̈ꊇ�擾
      FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
      -- �J�[�\���N���[�Y
      CLOSE chk_item_cur;
      -- �N�C�b�N�R�[�h���擾�ł��Ȃ��ꍇ
      IF ( g_chk_item_tab.COUNT = 0 ) THEN
        -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_cok_00015          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_lookup_value_set       -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_type_column_digit_chk  -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      << item_check_loop >>
      FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
        -- �^���`�F�b�N���ʊ֐��Ăяo��
        xxccp_common_pkg2.upload_item_check(
          iv_item_name     => g_chk_item_tab(i).meaning    -- 1.���ږ���
         ,iv_item_value    => g_if_data_tab(i)             -- 2.���ڂ̒l
         ,in_item_len      => g_chk_item_tab(i).attribute1 -- ���ڂ̒���
         ,in_item_decimal  => g_chk_item_tab(i).attribute2 -- ���ڂ̒���(�����_�ȉ�)
         ,iv_item_nullflg  => g_chk_item_tab(i).attribute3 -- �K�{�t���O
         ,iv_item_attr     => g_chk_item_tab(i).attribute4 -- ���ڑ���
         ,ov_errbuf        => lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode       => lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg        => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        --���[�j���O
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���ڕs���G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cok            -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_cok_10709          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                     , iv_token_value1 => g_chk_item_tab(i).meaning -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_record_no          -- �g�[�N���R�[�h2
                     , iv_token_value2 => g_if_data_tab(i)          -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_errmsg             -- �g�[�N���R�[�h3
                     , iv_token_value3 => lv_errmsg                 -- �g�[�N���l3
                      );
--
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => (in_file_if_loop_cnt-1)||cv_msg_csv_line || lv_errmsg
          );
          gn_chk_cnt := 1;
-- 2021/04/06 Ver1.1 ADD Start
					gn_warn_cnt	:=  gn_warn_cnt + 1;
-- 2021/04/06 Ver1.1 ADD End
--
        --���ʊ֐��G���[
        ELSIF ( lv_retcode = cv_status_error ) THEN
          gn_chk_cnt := 1;
        --����I��
        END IF;
      END LOOP item_check_loop;
--
      IF  gn_chk_cnt = 0 THEN
--
      --********************************************************
      --* ���[�N�e�[�u���o�^����
      --********************************************************
--
      -- ���[�N�e�[�u���Ƀf�[�^���i�[����
      BEGIN
        INSERT INTO xxcok_condition_temp(
          csv_no                          -- CSV�s��
        , request_id                      -- �v��ID
        , csv_process_type                -- CSV�����敪
        , process_type                    -- �����敪
        , condition_no                    -- �T���ԍ�
        , corp_code                       -- ��ƃR�[�h
        , deduction_chain_code            -- �`�F�[���X�R�[�h
        , customer_code                   -- �ڋq�R�[�h
        , data_type                       -- �f�[�^���
        , start_date_active               -- �J�n��
        , end_date_active                 -- �I����
        , content                         -- ���e
        , decision_no                     -- ����No
        , agreement_no                    -- �_��ԍ�
        , process_type_line               -- ���׏����敪
        , detail_number                   -- ���הԍ�
        , target_category                 -- �Ώۋ敪
        , product_class                   -- ���i�敪
        , item_code                       -- �i�ڃR�[�h
        , uom_code                        -- �P��
        , shop_pay_1                      -- �X�[(��)_1
        , material_rate_1                 -- ����(��)_1
        , demand_en_3                     -- ����(�~)_3
        , shop_pay_en_3                   -- �X�[(�~)_3
        , wholesale_margin_en_3           -- �≮�}�[�W��(�~)_3
        , wholesale_margin_per_3          -- �≮�}�[�W��(��)_3
        , normal_shop_pay_en_4            -- �ʏ�X�[(�~)_4
        , just_shop_pay_en_4              -- ����X�[(�~)_4
        , wholesale_adj_margin_en_4       -- �≮�}�[�W���C��(�~)_4
        , wholesale_adj_margin_per_4      -- �≮�}�[�W���C��(��)_4
        , prediction_qty_5_6              -- �\������(�{)_5_6
        , support_amount_sum_en_5         -- ���^�����v(�~)_5
        , condition_unit_price_en_2_6     -- �����P��(�~)_2_6
        , target_rate_6                   -- �Ώۗ�(��)_6
-- 2021/04/06 Ver1.1 MOD Start
--        , accounting_base                 -- �v�㋒�_
        , accounting_customer_code        -- �v��ڋq
-- 2021/04/06 Ver1.1 MOD End
        , deduction_amount                -- �T���z(�{��)
        , tax_code                        -- �ŃR�[�h
        , deduction_tax_amount            -- �T���Ŋz
        , condition_cls                   -- �T���敪
        , condition_type                  -- �T���^�C�v
        , created_by                      -- �쐬��
        , creation_date                   -- �쐬��
        , last_updated_by                 -- �ŏI�X�V��
        , last_update_date                -- �ŏI�X�V��
        , last_update_login               -- �ŏI�X�V���O�C��
        , program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                      -- �R���J�����g�E�v���O����ID
        , program_update_date             -- �v���O�����X�V��
        )VALUES(
          in_file_if_loop_cnt                                                     -- CSV�s��
        , cn_request_id                                                           -- �v��ID
        , g_if_data_tab(cn_process_type)                                          -- CSV�����敪
        , CASE
            -- CSV�����敪���u�V�K�v�ōT���ԍ������ݒ�̏ꍇ�uI�v��ݒ�
            WHEN g_if_data_tab(cn_process_type) = cv_csv_insert AND g_if_data_tab(cn_condition_no) IS NULL THEN
              cv_process_insert
            -- CSV�����敪���u�C���v�̏ꍇ�uU�v��ݒ�
            WHEN g_if_data_tab(cn_process_type) = cv_csv_update THEN
              cv_process_update
            -- CSV�����敪���u���فv�̏ꍇ�uZ�v��ݒ�
            WHEN g_if_data_tab(cn_process_type) = cv_csv_decision THEN
              cv_process_decision
            -- ��L�ȊO�̏ꍇ�uN�v��ݒ�
            ELSE
              cv_const_n
          END
        , g_if_data_tab(cn_condition_no)                                          -- �T���ԍ�
        , g_if_data_tab(cn_corp_code)                                             -- ��ƃR�[�h
        , g_if_data_tab(cn_deduction_chain_code)                                  -- �`�F�[���X�R�[�h
        , g_if_data_tab(cn_customer_code)                                         -- �ڋq�R�[�h
        , lv_data_type                                                            -- �f�[�^���
        , g_if_data_tab(cn_start_date_active)                                     -- �J�n��
        , g_if_data_tab(cn_end_date_active)                                       -- �I����
        , g_if_data_tab(cn_content)                                               -- ���e
        , g_if_data_tab(cn_decision_no)                                           -- ����No
        , g_if_data_tab(cn_agreement_no)                                          -- �_��ԍ�
        , CASE
            -- CSV�����敪���u�V�K�v�̏ꍇ�uI�v��ݒ�
            WHEN g_if_data_tab(cn_process_type) = cv_csv_insert THEN
              cv_process_insert
            -- CSV�����敪���u�폜�v�̏ꍇ�uD�v��ݒ�
            WHEN g_if_data_tab(cn_process_type) = cv_csv_delete THEN
              cv_process_delete
            -- ��L�ȊO�̏ꍇ�uN�v��ݒ�
            ELSE
              cv_const_n
          END                                                                     -- ���׏����敪
        , g_if_data_tab(cn_detail_number)                                         -- ���הԍ�
        , g_if_data_tab(cn_target_category)                                       -- �Ώۋ敪
        , g_if_data_tab(cn_product_class)                                         -- ���i�敪
        , g_if_data_tab(cn_item_code)                                             -- �i�ڃR�[�h
        , g_if_data_tab(cn_uom_code)                                              -- �P��
        , TO_NUMBER(g_if_data_tab(cn_shop_pay_1))                                 -- �X�[(��)_1
        , TO_NUMBER(g_if_data_tab(cn_material_rate_1))                            -- ����(��)_1
        , TO_NUMBER(g_if_data_tab(cn_demand_en_3))                                -- ����(�~)_3
        , TO_NUMBER(g_if_data_tab(cn_shop_pay_en_3))                              -- �X�[(�~)_3
        , TO_NUMBER(g_if_data_tab(cn_wholesale_margin_en_3))                      -- �≮�}�[�W��(�~)_3
        , TO_NUMBER(g_if_data_tab(cn_wholesale_margin_per_3))                     -- �≮�}�[�W��(��)_3
        , TO_NUMBER(g_if_data_tab(cn_normal_shop_pay_en_4))                       -- �ʏ�X�[(�~)_4
        , TO_NUMBER(g_if_data_tab(cn_just_shop_pay_en_4))                         -- ����X�[(�~)_4
        , TO_NUMBER(g_if_data_tab(cn_wholesale_adj_margin_en_4))                  -- �≮�}�[�W���C��(�~)_4
        , TO_NUMBER(g_if_data_tab(cn_wholesale_adj_margin_per_4))                 -- �≮�}�[�W���C��(��)_4
        , TO_NUMBER(g_if_data_tab(cn_prediction_qty_5_6))                         -- �\������(�{)_5_6
        , TO_NUMBER(g_if_data_tab(cn_support_amount_sum_en_5))                    -- ���^�����v(�~)_5
        , TO_NUMBER(g_if_data_tab(cn_condition_unit_price_en_2_6))                -- �����P��(�~)_2_6
        , TO_NUMBER(g_if_data_tab(cn_target_rate_6))                              -- �Ώۗ�(��)_6
-- 2021/04/06 Ver1.1 MOD Start
--        , g_if_data_tab(cn_accounting_base)                                       -- �v�㋒�_
        , g_if_data_tab(cn_accounting_customer_code)                              -- �v��ڋq
-- 2021/04/06 Ver1.1 MOD End
        , TO_NUMBER(g_if_data_tab(cn_deduction_amount))                           -- �T���z(�{��)
        , TO_NUMBER(g_if_data_tab(cn_tax_code))                                   -- �ŃR�[�h
        , TO_NUMBER(g_if_data_tab(cn_deduction_tax_amount))                       -- �T���Ŋz
        , lv_condition_cls                                                        -- �T���敪
        , lv_condition_type                                                       -- �T���^�C�v
        , cn_created_by                                                           -- �쐬��
        , cd_creation_date                                                        -- �쐬��
        , cn_last_updated_by                                                      -- �ŏI�X�V��
        , cd_last_update_date                                                     -- �ŏI�X�V��
        , cn_last_update_login                                                    -- �ŏI�X�V���O�C��
        , cn_program_application_id                                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , cn_program_id                                                           -- �R���J�����g�E�v���O����ID
        , cd_program_update_date                                                  -- �v���O�����X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�̎擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10622
                       , iv_token_name1  => cv_tkn_err_msg
                       , iv_token_value1 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      ELSE
        ov_retcode := cv_status_warn;
      END IF;
    --
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : ins_exclusive_ctl_info
   * Description      : �r������Ǘ��e�[�u���o�^(A-5-1)
   ***********************************************************************************/
  PROCEDURE ins_exclusive_ctl_info(
    ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_exclusive_ctl_info'; -- �v���O������
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
    PRAGMA AUTONOMOUS_TRANSACTION;  -- �����^�錾
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
    INSERT INTO xxcok_exclusive_ctl_info(
      condition_no
    , request_id                                -- �v��ID
    )VALUES(
      g_exclusive_ctl_rec.condition_no  -- �T���ԍ�
    , g_exclusive_ctl_rec.request_id    -- �v��ID
    );
    
    COMMIT;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10622
           , iv_token_name1  => cv_tkn_err_msg
           , iv_token_value1 => SQLERRM
           );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_exclusive_ctl_info;
--
    /**********************************************************************************
   * Procedure Name   : exclusive_check
   * Description      : �T���}�X�^�r�����䏈��(A-5)
   ***********************************************************************************/
  PROCEDURE exclusive_check(
    ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exclusive_check'; -- �v���O������
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
    cv_msg_exclusive_ctl    CONSTANT VARCHAR2(20)  := '�r������Ǘ��e�[�u��';
--
    -- *** ���[�J���ϐ� ***
    ln_count       NUMBER;
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
    -- ���[�J���ϐ�������
    ln_count  :=  0;
--
    -- �f�[�^�����b�N����Ă��Ȃ����m�F
    BEGIN
      SELECT
        COUNT(1)      AS  cnt
      INTO ln_count
      FROM
          xxcok_exclusive_ctl_info  xeci
        , xxcok_condition_temp      xct
      WHERE xct.condition_no  =   xeci.condition_no
      ;
    END;
--
    IF ln_count = 0 THEN
--
      --********************************************************
      --* �r������Ǘ��e�[�u���o�^����
      --********************************************************
      -- �J�[�\���I�[�v��
      OPEN g_exclusive_ctl_cur;
--
      LOOP
        FETCH g_exclusive_ctl_cur INTO g_exclusive_ctl_rec;
        EXIT WHEN g_exclusive_ctl_cur%NOTFOUND;
--
          -- ============================================
          -- A-5-1�D�r������Ǘ��e�[�u���o�^
          -- ============================================
          ins_exclusive_ctl_info(
              ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
      END LOOP;
      -- �J�[�\���N���[�Y
      CLOSE g_exclusive_ctl_cur;
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10614
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      RAISE global_process_expt;
--
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END exclusive_check;
--
    /**********************************************************************************
   * Procedure Name   : validity_check
   * Description      : �Ó����`�F�b�N(A-6)
   ***********************************************************************************/
  PROCEDURE validity_check(
      ov_errbuf       OUT VARCHAR2                    -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2                    -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2)                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validity_check'; -- �v���O������
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
    lv_token_name             VARCHAR2(1000); -- �g�[�N����
    lv_token_value            VARCHAR2(100);  -- �g�[�N���l
    lv_base_code_h            VARCHAR2(10);   -- �S�����_
    lv_cast_date_flag         VARCHAR2(1);    -- ���t�������t���O
    ln_dummy                  NUMBER;         -- �_�~�[�ꎞ�i�[�ϐ�
    ln_dummy_condition_no     NUMBER;         -- �_�~�[�T���ԍ�
    ld_start_date             DATE;           -- �J�n��
    ld_end_date               DATE;           -- �I����
    ln_tax_rate               NUMBER;         -- �ŗ�
    ln_tax_rate_1             NUMBER;         -- �ŗ�(�T�������擾�p)
    ld_before_start_date      DATE;           -- �C���O�J�n��
    ld_before_end_date        DATE;           -- �C���O�I����
    lt_prev_condition_no1     xxcok_condition_temp.condition_no%TYPE;         -- �O�񏈗��T���ԍ�
    lt_prev_condition_no2     xxcok_condition_temp.condition_no%TYPE;         -- �O�񏈗��T���ԍ�
    lt_exists_header          xxcok_condition_temp.condition_no%TYPE;         -- �T������ID
    lt_exists_line            xxcok_condition_temp.detail_number%TYPE;        -- �T���ڍ�ID
    lt_max_detail_number      xxcok_condition_temp.detail_number%TYPE;        -- �ő喾�הԍ�
    lt_set_detail_number      xxcok_condition_temp.detail_number%TYPE;        -- ���הԍ�
    lt_master_start_date      xxcok_condition_header.start_date_active%TYPE;  -- �}�X�^�J�n��
    lt_business_low_type      xxcmm_cust_accounts.business_low_type%TYPE;     -- �Ƒԏ�����
    ln_cnt                    NUMBER;
    lt_product_class_code     mtl_categories_vl.segment1%TYPE;                -- ���i�敪�R�[�h
    lt_target_category        xxcok_condition_temp.target_category%TYPE;      -- �Ώۋ敪
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
    -- ���[�J���ϐ�������(���[�v��)
    lv_errbuf             :=  NULL;
    lv_base_code_h        :=  cv_dummy_base;
    lv_token_name         :=  NULL;
    ln_dummy              :=  NULL;
    ln_dummy_condition_no :=  0;
    lt_prev_condition_no1 :=  NULL;
    g_message_list_tab.DELETE;
--
    --  ******************************************
    --  �_�~�[�T���ԍ��̔�
    --  ******************************************
--
    DECLARE
      -- �T���^�C�v070�p
      CURSOR  dummy_con_1_cur
      IS
        SELECT DISTINCT 
                xct.corp_code                   AS corp_code                -- ��ƃR�[�h
              , xct.deduction_chain_code        AS deduction_chain_code     -- �`�F�[���X�R�[�h
              , xct.customer_code               AS customer_code            -- �ڋq�R�[�h
              , xct.data_type                   AS data_type                -- �f�[�^���
              , xct.tax_code                    AS tax_code                 -- ����ŃR�[�h
              , xct.start_date_active           AS start_date_active        -- �J�n��
              , xct.end_date_active             AS end_date_active          -- �I����
              , xct.content                     AS content                  -- ���e
              , xct.decision_no                 AS decision_no              -- ����No
              , xct.agreement_no                AS agreement_no             -- �_��ԍ�
        FROM    xxcok_condition_temp    xct
        WHERE   xct.process_type      =   cv_process_insert
        AND     xct.condition_type    =   cv_condition_type_fix_con
        ;
      dummy_con_1_rec   dummy_con_1_cur%ROWTYPE;
      -- �T���^�C�v070�ȊO�p
      CURSOR  dummy_con_2_cur
      IS
        SELECT  DISTINCT
                xct.corp_code                   AS corp_code                -- ��ƃR�[�h
              , xct.deduction_chain_code        AS deduction_chain_code     -- �`�F�[���X�R�[�h
              , xct.customer_code               AS customer_code            -- �ڋq�R�[�h
              , xct.data_type                   AS data_type                -- �f�[�^���
              , xct.tax_code                    AS tax_code                 -- ����ŃR�[�h
              , xct.start_date_active           AS start_date_active        -- �J�n��
              , xct.end_date_active             AS end_date_active          -- �I����
              , xct.content                     AS content                  -- ���e
              , xct.decision_no                 AS decision_no              -- ����No
              , xct.agreement_no                AS agreement_no             -- �_��ԍ�
        FROM    xxcok_condition_temp    xct
        WHERE   xct.process_type      =   cv_process_insert
        AND     xct.condition_type    <> cv_condition_type_fix_con
        ;
      dummy_con_2_rec   dummy_con_2_cur%ROWTYPE;
--
    BEGIN
      -- �T���^�C�v��070�̏ꍇ
      FOR dummy_con_1_rec IN dummy_con_1_cur LOOP
        ln_dummy_condition_no :=  ln_dummy_condition_no - 1;
        UPDATE  xxcok_condition_temp xct
        SET     xct.condition_no    =   TO_CHAR(ln_dummy_condition_no)
        WHERE   NVL(xct.corp_code, cv_dummy_code)               =   NVL(dummy_con_1_rec.corp_code, cv_dummy_code)
        AND     NVL(xct.deduction_chain_code, cv_dummy_code)    =   NVL(dummy_con_1_rec.deduction_chain_code, cv_dummy_code)
        AND     NVL(xct.customer_code, cv_dummy_code)           =   NVL(dummy_con_1_rec.customer_code, cv_dummy_code)
        AND     xct.data_type                                   =   dummy_con_1_rec.data_type
        AND     xct.tax_code                                    =   dummy_con_1_rec.tax_code
        AND     xct.start_date_active                           =   dummy_con_1_rec.start_date_active
        AND     xct.end_date_active                             =   dummy_con_1_rec.end_date_active
        AND     NVL(xct.content, cv_dummy_code)                 =   NVL(dummy_con_1_rec.content, cv_dummy_code)
        AND     NVL(xct.decision_no, cv_dummy_code)             =   NVL(dummy_con_1_rec.decision_no, cv_dummy_code)
        AND     NVL(xct.agreement_no, cv_dummy_code)            =   NVL(dummy_con_1_rec.agreement_no, cv_dummy_code)
        AND     xct.process_type                                =   cv_process_insert
        AND     xct.request_id                                  =   cn_request_id
        ;
--
      END LOOP;
      -- �T���^�C�v��070�ȊO�̏ꍇ
      FOR dummy_con_2_rec IN dummy_con_2_cur LOOP
--
          ln_dummy_condition_no :=  ln_dummy_condition_no - 1;
--
        UPDATE  xxcok_condition_temp xct
        SET     condition_no  =   TO_CHAR(ln_dummy_condition_no)
        WHERE   NVL(xct.corp_code, cv_dummy_code)               =   NVL(dummy_con_2_rec.corp_code, cv_dummy_code)
        AND     NVL(xct.deduction_chain_code, cv_dummy_code)    =   NVL(dummy_con_2_rec.deduction_chain_code, cv_dummy_code)
        AND     NVL(xct.customer_code, cv_dummy_code)           =   NVL(dummy_con_2_rec.customer_code, cv_dummy_code)
        AND     NVL(xct.tax_code, cv_dummy_code)                =   NVL(dummy_con_2_rec.tax_code, cv_dummy_code)
        AND     xct.data_type                                   =   dummy_con_2_rec.data_type
        AND     xct.start_date_active                           =   dummy_con_2_rec.start_date_active
        AND     xct.end_date_active                             =   dummy_con_2_rec.end_date_active
        AND     NVL(xct.content, cv_dummy_code)                 =   NVL(dummy_con_2_rec.content, cv_dummy_code)
        AND     NVL(xct.decision_no, cv_dummy_code)             =   NVL(dummy_con_2_rec.decision_no, cv_dummy_code)
        AND     NVL(xct.agreement_no, cv_dummy_code)            =   NVL(dummy_con_2_rec.agreement_no, cv_dummy_code)
        AND     xct.process_type                                =   cv_process_insert
        AND     xct.request_id                                  =   cn_request_id
        ;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    <<g_cond_tmp_chk_loop>>
    FOR g_cond_tmp_chk_rec IN g_cond_tmp_chk_cur LOOP
--
      --  ���b�Z�[�W�C���f�b�N�X������
      ln_cnt  :=  0;
--
      --  CSV�����敪���o�^,�폜,�C��,���� �ȊO�̏ꍇ
      IF  NVL(g_cond_tmp_chk_rec.csv_process_type, cv_const_n ) NOT IN ( cv_csv_delete, cv_csv_update, cv_csv_insert, cv_csv_decision, cv_const_n ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10597
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_pro_type
           , iv_token_name2  => cv_col_value_tok
           , iv_token_value2 => g_cond_tmp_chk_rec.csv_process_type
        );
        ln_cnt  :=  ln_cnt + 1;
        g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
      END IF;
--
      IF ( ln_cnt <> 0 ) THEN
        --  ���b�Z�[�W����̏ꍇ
        gv_check_result :=  'N';
        IF ( gn_message_cnt = 0 OR gn_message_cnt < ln_cnt ) THEN
          gn_message_cnt  :=  ln_cnt;
        END IF;
        gn_warn_cnt     :=  gn_warn_cnt + 1;
        ov_retcode      :=  cv_status_warn;
      END IF;
      --  ******************************************
      --  �}�X�^�f�[�^�擾
      --  ******************************************
      --  NULL/NULL�̏ꍇ�A�ȍ~�S�ăX�L�b�v
      IF g_cond_tmp_chk_rec.process_type = cv_const_n AND g_cond_tmp_chk_rec.process_type_line = cv_const_n THEN
        gn_skip_cnt := gn_skip_cnt + 1;
        CONTINUE g_cond_tmp_chk_loop;
      ELSE
        --  ������
        lv_cast_date_flag :=  cv_const_y;
        lt_exists_header  :=  NULL;
        lt_exists_line    :=  NULL;
        lt_max_detail_number  :=  0;
        ln_tax_rate           :=  0;              -- �ŗ�
        ln_tax_rate_1         :=  0;              -- �ŗ�(�T�������擾�p)
        ld_before_start_date  :=  NULL;           -- �C���O�J�n��
        ld_before_end_date    :=  NULL;           -- �C���O�I����
        --
        -- �����敪��U�i�ύX�j�A�܂��͖��׏����敪��D�i�폜�j�̏ꍇ�A�ύX�O�J�n���A�ύX�O�I�������擾
        IF g_cond_tmp_chk_rec.process_type_line IN( cv_process_delete )
          OR g_cond_tmp_chk_rec.process_type IN  (cv_process_update,cv_process_decision) THEN
          BEGIN
            SELECT xch.start_date_active    -- �J�n��
                  ,xch.end_date_active      -- �I����
            INTO   ld_before_start_date
                  ,ld_before_end_date
            FROM   xxcok_condition_header xch
            WHERE  xch.condition_no    = g_cond_tmp_chk_rec.condition_no  -- �T��No
            AND    xch.enabled_flag_h  = cv_const_y                   -- �L���t���O
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ld_before_start_date := NULL;
              ld_before_end_date   := NULL;
          END;
        END IF;
--
        --  �T���}�X�^�i�w�b�_�j�f�[�^���擾����
        --  �����敪��'I'(�o�^)�ȊO ���� 1�f�[�^�� ���� �T���ԍ����ύX���ꂽ�ꍇ
        IF    ( g_cond_tmp_chk_rec.process_type <> cv_process_insert
          AND ( lt_prev_condition_no1 IS NULL
            OR  lt_prev_condition_no1 <> g_cond_tmp_chk_rec.condition_no ) )
        THEN
          BEGIN
            --
            SELECT  xch.condition_id          AS  condition_id
                  , NVL( (  SELECT MAX( sub.detail_number )     AS  max_detail_number
                            FROM xxcok_condition_lines sub
                            WHERE sub.condition_no = xch.condition_no ), 0 )
                                              AS  max_detail_number
                  , xch.start_date_active     AS  start_date_active
            INTO    lt_exists_header
                  , lt_max_detail_number
                  , lt_master_start_date
            FROM    xxcok_condition_header    xch
            WHERE   xch.condition_no      =   g_cond_tmp_chk_rec.condition_no
            AND     xch.enabled_flag_h    =   cv_const_y
            ;
            --
            IF ( lt_exists_header IS NOT NULL ) THEN
              --  �T������ID���擾���ꂽ�ꍇ�ATEMP�ɕێ��i���ב}�����Ɏg�p�j:����T���ԍ��Ɉꗥ�ݒ�
              UPDATE  xxcok_condition_temp    xct
              SET     xct.condition_id    =   lt_exists_header
              WHERE   xct.condition_no    =   g_cond_tmp_chk_rec.condition_no
              ;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_exists_header  :=  NULL;
              lt_max_detail_number  :=  0;
          END;
          --
        END IF;
--
        --  �T���}�X�^�i���ׁj�f�[�^���擾����
        --  �����敪��'I'(�o�^)�ȊO ���� ���׏����敪��'I'(�o�^)�ȊO�̏ꍇ
        IF    ( g_cond_tmp_chk_rec.process_type <> cv_process_insert
          AND ( g_cond_tmp_chk_rec.process_type_line <> cv_process_insert ) )
        THEN
          BEGIN
            --
            SELECT  xcl.condition_line_id     AS  condition_line_id
            INTO    lt_exists_line
            FROM    xxcok_condition_lines     xcl
            WHERE   xcl.condition_no      =   g_cond_tmp_chk_rec.condition_no
            AND     xcl.detail_number     =   g_cond_tmp_chk_rec.detail_number
            AND     xcl.enabled_flag_l    =   cv_const_y
            ;
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_exists_line    :=  NULL;
          END;
          --
        END IF;
--
        --  ���הԍ��̔�
        --  ����INSERT�̏ꍇ�̂ݍ̔�
        IF  ( g_cond_tmp_chk_rec.process_type_line = cv_process_insert) THEN
          IF  (    lt_prev_condition_no1 IS NULL
                OR lt_prev_condition_no1 <> g_cond_tmp_chk_rec.condition_no ) THEN
            --  1�f�[�^�� or �T���ԍ����ς�����ꍇ
            --  ���הԍ��̏����l�ݒ�
            lt_prev_condition_no1   :=  g_cond_tmp_chk_rec.condition_no;
            --
            IF ( g_cond_tmp_chk_rec.process_type = cv_process_insert ) THEN
              --  �w�b�_INSERT�̏ꍇ�A���׏����l�� 1
              lt_set_detail_number  :=  1;
            ELSE
              --  �w�b�_INSERT�ȊO�̏ꍇ�A�}�X�^�ɐݒ�ς݂̖��הԍ�+1
              lt_set_detail_number  :=  lt_max_detail_number + 1;
            END IF;
          ELSE
            --  ����T���ԍ��̏ꍇ�A���הԍ������Z
            lt_set_detail_number  :=  lt_set_detail_number + 1;
          END IF;
          --  ���הԍ��ݒ�
          g_cond_tmp_chk_rec.detail_number  :=  lt_set_detail_number;
        END IF;
--
        --  ******************************************
        --  ���ʃ`�F�b�N
        --  ******************************************
        --  �����ׂ��폜�̏ꍇ
        IF  g_cond_tmp_chk_rec.process_type_line = cv_process_delete THEN
--
          -- �C���O�J�n�����Ɩ����t������̏ꍇ
          IF ld_before_start_date <= gd_process_date THEN
            -- ���苒�_�̏����҂łȂ��ꍇNG
            IF  gn_privilege_delete = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10612
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
--
        BEGIN
          --  1�f�[�^�� or �T���ԍ����ς�����ꍇ
          IF  (    lt_prev_condition_no2 IS NULL
                OR lt_prev_condition_no2 <> g_cond_tmp_chk_rec.condition_no ) THEN
            --  �T���ԍ���ێ�
            lt_prev_condition_no2 :=  g_cond_tmp_chk_rec.condition_no;
            --  �w�b�_�̏����敪���X�V�̏ꍇ
--
-- 2021/04/06 Ver1.1 DEL Start
--            -- �F
--            IF  g_cond_tmp_chk_rec.condition_type = cv_condition_type_fix_con THEN
--              --  �L���Ȗ��׏��2�s�ȏ゠��ꍇ
--              SELECT  COUNT(1) AS cnt
--              INTO    ln_dummy
--              FROM    xxcok_condition_temp xct
--              WHERE   xct.condition_no                                  =   g_cond_tmp_chk_rec.condition_no
--              AND     xct.request_id                                    =   cn_request_id
--              ;
--              IF ln_dummy >= 2 THEN
--                lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cok
--                   , iv_name         => cv_msg_cok_10608
--                   , iv_token_name1  => cv_col_name_tok
--                   , iv_token_value1 => cv_msg_condition_no
--                   );
--                  ln_cnt  :=  ln_cnt + 1;
--                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--              END IF;
--            END IF;
-- 2021/04/06 Ver1.1 DEL End
--
          END IF;
--
        END;
--
        BEGIN
          -- 8-1.����ƃR�[�h�Ń`�F�b�N
          IF  g_cond_tmp_chk_rec.corp_code IS NOT NULL THEN
            lv_token_name :=  cv_msg_kigyo_code;
            lv_token_value  := g_cond_tmp_chk_rec.corp_code;
--
            SELECT  ffv.attribute2      AS  base_code   -- �{���S�����_
            INTO    lv_base_code_h
            FROM    fnd_flex_value_sets ffvs
                  , fnd_flex_values     ffv
                  , fnd_flex_values_tl  ffvt
            WHERE ffvs.flex_value_set_id    = ffv.flex_value_set_id
            AND   ffv.flex_value_id         = ffvt.flex_value_id
            AND   ffvs.flex_value_set_name  = cv_type_business_type
            AND   ffvt.language             = ct_language
            AND   ffv.summary_flag          = cv_const_n
            AND   ffv.flex_value            = g_cond_tmp_chk_rec.corp_code
            ;
--
          END IF;
--
          -- 8-2.���T���p�`�F�[���R�[�h�Ń`�F�b�N
          IF g_cond_tmp_chk_rec.deduction_chain_code IS NOT NULL THEN
--
            lv_token_name :=  cv_msg_chain_code;
            lv_token_value  := g_cond_tmp_chk_rec.deduction_chain_code;
--
            SELECT  flv.attribute3      AS  base_code   -- �{���S�����_
            INTO    lv_base_code_h
            FROM    fnd_lookup_values flv
            WHERE   flv.language          = ct_language
            AND     flv.lookup_type       = cv_type_chain_code
            AND     flv.lookup_code       = g_cond_tmp_chk_rec.deduction_chain_code
            AND     flv.enabled_flag      = cv_const_y
            AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                    AND     NVL(flv.end_date_active, gd_process_date)
            ;
--
          END IF;
--
          -- 8-3.���ڋq�R�[�h�Ń`�F�b�N
          IF g_cond_tmp_chk_rec.customer_code IS NOT NULL THEN
--
            lv_token_name :=  cv_msg_cust_code;
            lv_token_value  := g_cond_tmp_chk_rec.customer_code;
--
            SELECT  xca.sale_base_code      AS  base_code           --  ����S�����_
                  , xca.business_low_type   AS  business_low_type   --  �Ƒԏ�����
            INTO    lv_base_code_h
                  , lt_business_low_type
            FROM    hz_cust_accounts          hca
                  , xxcmm.xxcmm_cust_accounts xca
            WHERE   hca.cust_account_id =  xca.customer_id
            AND     hca.status              = cv_cust_accounts_status
            AND     hca.customer_class_code = cv_cust_class_cust
            AND     hca.account_number      = g_cond_tmp_chk_rec.customer_code
            ;
          END IF;
--
          -- 8-4.���擾�����S�����_�ƃ��O�C�����[�U�̏������_���قȂ��Ă���΃G���[
          IF gn_privilege_up_ins = 0
            AND gv_user_base <> lv_base_code_h
            AND lv_token_name IS NOT NULL THEN
--
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10613
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => lv_token_name
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => lv_token_value
                           );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
--
          -- 8-5.���t��VD�A�t��VD�����A��������ڋq�A�S�ݓX�A���X�̌ڋq���w�肵�Ă���
          IF    g_cond_tmp_chk_rec.customer_code IS NOT NULL 
            AND lt_business_low_type IN( '20','21','22','24','25' ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10597
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_cust_code
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.customer_code
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
--
          --  �����ׂ��폜�̏ꍇ
          IF    g_cond_tmp_chk_rec.process_type_line = cv_process_delete THEN
            --  �}�X�^�̊J�n�����Ɩ����t�����O�̏ꍇ
            IF ld_before_start_date > gd_process_date THEN
              -- 8-7.�S�����_�ƃ��O�C�����[�U�̏������_���قȂ��Ă���ꍇ
              IF gn_privilege_up_ins = 0
                AND gv_user_base <> lv_base_code_h
                AND lv_token_name IS NOT NULL THEN
--
                -- ���苒�_�̏����҂łȂ��ꍇNG
                IF  gn_privilege_delete = 0 THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10612
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
                END IF;
              END IF;
            END IF;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 8-6.����ƁA�`�F�[���A�ڋq���}�X�^�ɑ��݂��Ȃ�
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => lv_token_name
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => lv_token_value
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END;
--
        --  ******************************************
        --  �w�b�_�`�F�b�N
        --  ******************************************
        --  �������敪�g�ݍ��킹
        --  �T���ԍ����݃`�F�b�N
        --  CSV�����敪���C��,�폜,���ق̏ꍇ
        IF    g_cond_tmp_chk_rec.csv_process_type IN ( cv_csv_update, cv_csv_delete, cv_csv_decision ) THEN
          --  11.�T���ԍ����w�肳��Ă��Ȃ��ꍇ
          IF  g_cond_tmp_chk_rec.condition_no     IS  NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cok
                            , iv_name         => cv_msg_cok_10605
                            , iv_token_name1  => cv_if_value_tok
                            , iv_token_value1 => cv_msg_pro_type || cv_msg_ja_ga || cv_msg_update || cv_delimiter || cv_msg_delete || cv_delimiter || cv_msg_decision
                            , iv_token_name2  => cv_col_name_tok
                            , iv_token_value2 => cv_msg_condition_no
                            );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          ELSE
--
            -- 10.�}�X�^�ɗL���ȃf�[�^�����݂��Ȃ��ꍇ
            SELECT COUNT(1)    AS  dummy
            INTO   ln_dummy
            FROM   xxcok_condition_header  xch -- �T������
            WHERE  xch.condition_no   = g_cond_tmp_chk_rec.condition_no  -- �T���ԍ�
            AND    xch.enabled_flag_h = cv_const_y                       -- �L���t���O
            ;
--
            -- 0���������ꍇ�A�}�X�^���o�^�G���[
            IF ln_dummy = 0 OR (ld_before_start_date IS NULL AND  ld_before_end_date IS NULL )THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10600
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_condition_no
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.condition_no
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
--
        -- 10.CSV�����敪���o�^�ōT���ԍ����w�肳��Ă���ꍇ
        ELSIF g_cond_tmp_chk_rec.csv_process_type  =   cv_csv_insert 
          AND g_cond_tmp_chk_rec.condition_no     IS  NOT NULL
          AND TO_NUMBER(g_cond_tmp_chk_rec.condition_no) >  0  THEN
--
          SELECT COUNT(1)    AS  dummy
          INTO   ln_dummy
          FROM   xxcok_condition_header  xch -- �T������
          WHERE  xch.condition_no   = g_cond_tmp_chk_rec.condition_no  -- �T���ԍ�
          AND    xch.enabled_flag_h = cv_const_y                       -- �L���t���O
          ;
--
          -- 0���������ꍇ�A�}�X�^���o�^�G���[
          IF ln_dummy = 0 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_condition_no
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.condition_no
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        --  ���w�b�_�A���ׂ̉��ꂩ���X�V�̏ꍇ�A�}�X�^�f�[�^�̊J�n���ȍ~�̏ꍇNG
        IF  ( (     g_cond_tmp_chk_rec.process_type = cv_process_update 
                OR g_cond_tmp_chk_rec.process_type_line = cv_process_update )
              AND
              ( lt_master_start_date <= TRUNC(gd_process_date) )
            )
        THEN
          IF  (ld_before_start_date = TO_DATE(g_cond_tmp_chk_rec.start_date_active,cv_date_format)
          AND  ld_before_end_date = TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format)) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10604
                         , iv_token_name1  => cv_tkn_process_type
                         , iv_token_value1 => cv_msg_update
                         );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        --  12.����ƃR�[�h�A�`�F�[���X�R�[�h�A�ڋq�R�[�h��1���w�肳��Ă��Ȃ�
        IF (    g_cond_tmp_chk_rec.data_count = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10607
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_kigyo_code || cv_delimiter || cv_msg_chain_code || cv_delimiter ||
                                  cv_msg_cust_code
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        --  13.����ƃR�[�h�A�`�F�[���X�R�[�h�A�ڋq�R�[�h�̂���2�ȏオ�w�肳��Ă���
        ELSIF ( g_cond_tmp_chk_rec.data_count <> 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10599
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_kigyo_code || cv_delimiter || cv_msg_chain_code || cv_delimiter ||
                                  cv_msg_cust_code
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        --  14.���T���^�C�v���B�C�Ŋ�ƃR�[�h���ݒ肳��Ă���i�`�F�[���A�ڋq�����ݒ�j
        ELSIF (     g_cond_tmp_chk_rec.condition_type IN( cv_condition_type_ws_fix, cv_condition_type_ws_add)
                AND g_cond_tmp_chk_rec.corp_code IS NOT NULL )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10598
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_kigyo_code
             );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
        --  15.���T���^�C�v���B�C�ŐŃR�[�h���ݒ肳��Ă���
        ELSIF (     g_cond_tmp_chk_rec.condition_type IN( cv_condition_type_ws_fix, cv_condition_type_ws_add)
                AND g_cond_tmp_chk_rec.tax_code IS NOT NULL )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10598
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_tax_code
             );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
        --  16.���T���^�C�v���F�ŐŃR�[�h���ݒ肳��Ă��Ȃ�
        ELSIF (     g_cond_tmp_chk_rec.condition_type = cv_condition_type_fix_con
                AND g_cond_tmp_chk_rec.tax_code IS NULL )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10606
                       , iv_token_name1  => cv_col_name_tok
                       , iv_token_value1 => cv_msg_tax_code
                       );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
--
        --  17.���T���^�C�v���B�C�ȊO�ŐŃR�[�h���ݒ肳��Ă��āA�ŃR�[�h���}�X�^�ɑ��݂��Ȃ��ꍇ
        IF (     g_cond_tmp_chk_rec.condition_type NOT IN( cv_condition_type_ws_fix, cv_condition_type_ws_add)
                AND g_cond_tmp_chk_rec.tax_code IS NOT NULL )  THEN
          BEGIN
            SELECT  tax_rate       AS  tax_rate
            INTO    ln_tax_rate
            FROM    ar_vat_tax_all_b avtab
            WHERE   avtab.tax_code        = g_cond_tmp_chk_rec.tax_code
            AND     avtab.set_of_books_id = gn_set_of_bks_id
            AND     avtab.org_id          = gn_org_id2
            AND     avtab.enabled_flag    = cv_const_y
            AND     TO_DATE( g_cond_tmp_chk_rec.start_date_active, cv_date_format )
                        BETWEEN TRUNC( avtab.start_date ) AND TRUNC( NVL( avtab.end_date, cd_max_date) )
            AND     TO_DATE( g_cond_tmp_chk_rec.end_date_active, cv_date_format )
                        BETWEEN TRUNC( avtab.start_date ) AND TRUNC( NVL( avtab.end_date, cd_max_date ) )
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10600
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_tax_code
                             , iv_token_name2  => cv_col_value_tok
                             , iv_token_value2 => g_cond_tmp_chk_rec.tax_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END;
        ELSIF ( g_cond_tmp_chk_rec.tax_code IS NULL )  THEN
          ln_tax_rate := NULL;
        END IF;
            ld_start_date :=  TO_DATE( g_cond_tmp_chk_rec.start_date_active ,cv_date_format);
            ld_end_date   :=  TO_DATE( g_cond_tmp_chk_rec.end_date_active ,cv_date_format);
--
        --  18.���J�n�����I���������������i�����͉j
        IF ( ld_start_date > ld_end_date AND lv_cast_date_flag = cv_const_y )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10602
             , iv_token_name1  => cv_start_date_tok
             , iv_token_value1 => g_cond_tmp_chk_rec.start_date_active
             , iv_token_name2  => cv_end_date_tok
             , iv_token_value2 => g_cond_tmp_chk_rec.end_date_active
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
--
        --  �����敪���X�V�̏ꍇ
        IF (    g_cond_tmp_chk_rec.csv_process_type = cv_csv_update ) THEN
--
          -- 19.���C���O�J�n�����Ɩ����t���O���J�n�����C������ꍇ
          IF (ld_before_start_date != TO_DATE(g_cond_tmp_chk_rec.start_date_active,cv_date_format)) THEN
             IF (ld_before_start_date <= gd_process_date) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_kbn_cok
                  , iv_name         => cv_msg_cok_10703
               );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
             END IF; 
          END IF;
--
          --  20.���C���O�I�������Ɩ����t�����O���I�������C������ꍇ
          IF (ld_before_end_date != TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format)) THEN
             IF (ld_before_end_date < gd_process_date) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10704
               );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
             END IF; 
          END IF;
--
          --  21.���I�������Ɩ����t���ߋ����̏ꍇ
          IF (ld_before_end_date != TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format)) THEN
            IF (TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format) < gd_process_date) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10705
               );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
             END IF; 
          END IF;
        END IF;
--
        -- 22.���׏����敪��D�i�폜�j�̏ꍇ
        IF  g_cond_tmp_chk_rec.process_type_line  = cv_process_delete THEN
          -- ���הԍ������ݒ�̏ꍇ
          IF  g_cond_tmp_chk_rec.detail_number IS NULL THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cok
                          , iv_name         => cv_msg_cok_10605
                          , iv_token_name1  => cv_if_value_tok
                          , iv_token_value1 => cv_msg_dtl_pro_type || cv_msg_ja_ga || cv_msg_delete
                          , iv_token_name2  => cv_col_name_tok
                          , iv_token_value2 => cv_msg_detail_num
                          );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
          -- 23.DB��ɊY�����閾�הԍ������݂��邩�m�F
          ELSE
            SELECT COUNT(1)    AS  dummy
            INTO   ln_dummy
            FROM   xxcok_condition_lines  xcl -- �T���ڍ�
            WHERE  xcl.condition_no   = g_cond_tmp_chk_rec.condition_no   -- �T���ԍ�
            AND    xcl.detail_number  = g_cond_tmp_chk_rec.detail_number  -- ���הԍ�
            AND    xcl.enabled_flag_l = cv_const_y                        -- �L���t���O
            ;
---- 0���������ꍇ�A�}�X�^���o�^�G���[
            IF ln_dummy = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cok
                            , iv_name         => cv_msg_cok_10600
                            , iv_token_name1  => cv_col_name_tok
                            , iv_token_value1 => cv_msg_condition_no || cv_delimiter || cv_msg_detail_num
                            , iv_token_name2  => cv_col_value_tok
                            , iv_token_value2 => g_cond_tmp_chk_rec.condition_no || cv_delimiter || 
                                                 g_cond_tmp_chk_rec.detail_number
                            );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
--
        IF (  g_cond_tmp_chk_rec.process_type_line NOT IN (cv_process_delete, cv_const_n) ) THEN
          --  ******************************************
          --  �@�����z�~�����i���j
          --  ******************************************
          IF ( g_cond_tmp_chk_rec.condition_type  = cv_condition_type_req )  THEN
--
            -- 25.�i�ڃR�[�h�Ə��i�敪�̗��������ݒ�̏ꍇ�G���[
            IF    g_cond_tmp_chk_rec.item_code      IS NULL
              AND g_cond_tmp_chk_rec.product_class  IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_delimiter || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
            -- 26.�i�ڃR�[�h�Ə��i�敪�̗������w�肳��Ă���ꍇ�G���[
            IF    g_cond_tmp_chk_rec.item_code      IS NOT NULL
              AND g_cond_tmp_chk_rec.product_class  IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_msg_ja_to || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
            -- 27.�i�ڃR�[�h���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[ -- ����
            IF  g_cond_tmp_chk_rec.item_code  IS NOT NULL THEN
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 27.1.�i�ڃR�[�h���q�i�ڂ̏ꍇ�G���[
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
            END IF;
--
              -- 28-1.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 28-2.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 29.���i�敪���i�ڃJ�e�S���ɓo�^����Ă��Ȃ��ꍇ�G���[
            IF g_cond_tmp_chk_rec.product_class IS NOT NULL THEN
              BEGIN
                SELECT  mcv.segment1
                INTO    lt_product_class_code
                FROM    mtl_category_sets_vl mcsv -- �i�ڃJ�e�S���Z�b�g�r���[
                      , mtl_categories_vl    mcv  -- �i�ڃJ�e�S���r���[
                WHERE   mcsv.category_set_name  =   gv_item_div_h         -- �J�e�S���Z�b�g�� XXCOS:�{�Џ��i�敪
                AND     mcsv.structure_id       =   mcv.structure_id
                AND     mcv.description         =   g_cond_tmp_chk_rec.product_class
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                                , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_kbn
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.product_class
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
              -- 30-1.���i�敪�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A���ꏤ�i�敪�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.product_class  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.product_class        = g_cond_tmp_chk_rec.product_class     -- ���i�敪
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 30-2.���i�敪�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A���ꏤ�i�敪�̃f�[�^�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.product_class        = lt_product_class_code                -- ���i�敪
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 31.�Ώۋ敪�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.target_category IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_target_cate
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 32.�Ώۋ敪���Q�ƕ\�ɑ��݂��Ȃ��ꍇ�G���[
            ELSE
              BEGIN
                SELECT  flv.lookup_code     AS  target_category
                INTO    lt_target_category
                FROM    fnd_lookup_values   flv
                WHERE   flv.language          = ct_language
                AND     flv.lookup_type       = cv_type_deduction_1_kbn
                AND     flv.meaning           = g_cond_tmp_chk_rec.target_category
                AND     flv.enabled_flag      = cv_const_y
                AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_target_cate
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.target_category
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
            -- 33.�Ώۋ敪���u�X�[�v�ŁA�X�[(��)�����ݒ�̏ꍇ�G���[
            IF    g_cond_tmp_chk_rec.target_category  = cv_shop_pay
              AND g_cond_tmp_chk_rec.shop_pay_1       IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10605
                           , iv_token_name1  => cv_if_value_tok
                           , iv_token_value1 => cv_msg_target_cate || cv_msg_ja_ga || cv_msg_shop_pay
                           , iv_token_name2  => cv_col_name_tok
                           , iv_token_value2 => cv_msg_shop_pay || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 34.�X�[(��)�̒l��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.shop_pay_1 <= 0 
              OR TRUNC(g_cond_tmp_chk_rec.shop_pay_1, 2) <> g_cond_tmp_chk_rec.shop_pay_1  THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_shop_pay || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.shop_pay_1
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 35.����(��)�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.material_rate_1  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_meter_rate || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 36.����(��)�̒l��0�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.material_rate_1 = 0 
              OR TRUNC(g_cond_tmp_chk_rec.material_rate_1, 2) <> g_cond_tmp_chk_rec.material_rate_1  THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_meter_rate || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.material_rate_1
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          --  ***************************************
          --  �A�̔����ʁ~���z
          --  ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_sale  THEN
--
            -- 37.�i�ڃR�[�h�Ə��i�敪�̗��������ݒ�̏ꍇ�G���[
            IF    g_cond_tmp_chk_rec.item_code      IS NULL
              AND g_cond_tmp_chk_rec.product_class  IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_delimiter || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 38.�i�ڃR�[�h�Ə��i�敪�̗������w�肳��Ă���ꍇ�G���[
            IF    g_cond_tmp_chk_rec.item_code      IS NOT NULL
              AND g_cond_tmp_chk_rec.product_class  IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_msg_ja_to || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 39.�i�ڃR�[�h���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[ -- ����
            IF  g_cond_tmp_chk_rec.item_code  IS NOT NULL THEN
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 39.1.�i�ڃR�[�h���q�i�ڂ̏ꍇ�G���[
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
            END IF;
--
            -- 40-1.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 40-2.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 41.���i�敪���i�ڃJ�e�S���ɓo�^����Ă��Ȃ��ꍇ�G���[
            IF g_cond_tmp_chk_rec.product_class IS NOT NULL THEN
--
              BEGIN
                SELECT  mcv.segment1
                INTO    lt_product_class_code
                FROM    mtl_category_sets_vl mcsv -- �i�ڃJ�e�S���Z�b�g�r���[
                      , mtl_categories_vl    mcv  -- �i�ڃJ�e�S���r���[
                WHERE   mcsv.category_set_name  =   gv_item_div_h         -- �J�e�S���Z�b�g�� XXCOS:�{�Џ��i�敪
                AND     mcsv.structure_id       =   mcv.structure_id
                AND     mcv.description         =   g_cond_tmp_chk_rec.product_class
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                                , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_kbn
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.product_class
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
              -- 42-1.���i�敪�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A���ꏤ�i�敪�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.product_class  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.product_class        = g_cond_tmp_chk_rec.product_class     -- ���i�敪
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 42-2.���i�敪�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A���ꏤ�i�敪�̃f�[�^�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.product_class        = lt_product_class_code                -- ���i�敪
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 43.�����P���i�~�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 44.�����P���i�~�j��0�܂��̓}�C�i�X�l�܂��͏����_��2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6 = 0 
              OR  TRUNC(g_cond_tmp_chk_rec.condition_unit_price_en_2_6, 2)  <>  g_cond_tmp_chk_rec.condition_unit_price_en_2_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.condition_unit_price_en_2_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * �B�≮�����i��z�j�̃`�F�b�N
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_ws_fix  THEN
--
            -- 45.�i�ڃR�[�h�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.item_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 46.�i�ڃR�[�h���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[ -- ����
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 46.1.�i�ڃR�[�h���q�i�ڂ̏ꍇ�G���[
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 48.�i�ڃR�[�h�ɕR�t���A�P�ʊ��Z���擾�ł��Ȃ��ꍇ�G���[
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => g_cond_tmp_chk_rec.uom_code
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 47-1.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10608
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 47-2.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 49.�P�ʂ����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.uom_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_uom_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            ELSE
              -- 50.�P�ʂ��u�{�v�uCS�v�uBL�v�ȊO�̏ꍇ�G���[
              IF g_cond_tmp_chk_rec.uom_code  NOT IN (cv_uom_hon, cv_uom_cs, cv_uom_bl) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10597
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_uom_code
                             , iv_token_name2  => cv_col_value_tok
                             , iv_token_value2 => g_cond_tmp_chk_rec.uom_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 51.�����i�~�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.demand_en_3 IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_demand_en || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 52.�X�[�i�~�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.shop_pay_en_3 IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_shop_pay || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 53.�≮�}�[�W���i�~�j�Ɩ≮�}�[�W��(��)�̗��������ݒ�̏ꍇ�G���[
            IF    g_cond_tmp_chk_rec.wholesale_margin_en_3  IS NULL
              AND g_cond_tmp_chk_rec.wholesale_margin_per_3 IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen || cv_delimiter ||
                                                cv_msg_who_margin || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 54.�≮�}�[�W���i�~�j�Ɩ≮�}�[�W��(��)�̗������ݒ肳��Ă���ꍇ�G���[
            IF    g_cond_tmp_chk_rec.wholesale_margin_en_3    IS NOT NULL
              AND g_cond_tmp_chk_rec.wholesale_margin_per_3   IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen || cv_msg_ja_to ||
                                                cv_msg_who_margin || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.�����i�~�j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.demand_en_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.demand_en_3 ,2)  <>  g_cond_tmp_chk_rec.demand_en_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_demand_en || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.demand_en_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.�X�[�i�~�j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.shop_pay_en_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.shop_pay_en_3 ,2)  <>  g_cond_tmp_chk_rec.shop_pay_en_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_shop_pay || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.shop_pay_en_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.�≮�}�[�W���i�~�j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.wholesale_margin_en_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_margin_en_3 ,2)  <>  g_cond_tmp_chk_rec.wholesale_margin_en_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_margin_en_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.�≮�}�[�W��(��)��0�܂��̓}�C�i�X�l�𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.wholesale_margin_per_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_margin_per_3 ,2)  <>  g_cond_tmp_chk_rec.wholesale_margin_per_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_margin_per_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * �C�≮�����i�ǉ��j�̃`�F�b�N
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_ws_add  THEN
--
            -- 56.�i�ڃR�[�h�����ݒ�̏ꍇ�G���[ -- ����
            IF g_cond_tmp_chk_rec.item_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 57.�i�ڃR�[�h���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 57.1.�i�ڃR�[�h���q�i�ڂ̏ꍇ�G���[
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 59.�i�ڃR�[�h�ɕR�t���A�P�ʊ��Z���擾�ł��Ȃ��ꍇ�G���[
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => g_cond_tmp_chk_rec.uom_code
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 58-1.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
--
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 58-2.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 60.�P�ʂ����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.uom_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_uom_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            ELSE
              -- 61.�P�ʂ��u�{�v�uCS�v�uBL�v�ȊO�̏ꍇ�G���[
              IF g_cond_tmp_chk_rec.uom_code  NOT IN (cv_uom_hon, cv_uom_cs, cv_uom_bl) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10597
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_uom_code
                             , iv_token_name2  => cv_col_value_tok
                             , iv_token_value2 => g_cond_tmp_chk_rec.uom_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 62.�ʏ�X�[�i�~�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.normal_shop_pay_en_4  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_normal_sp || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 63.����X�[�i�~�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.just_shop_pay_en_4  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_just_sp || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 64.�≮�}�[�W���C���i�~�j�Ɩ≮�}�[�W���C��(��)�̗��������ݒ�̏ꍇ�G���[
            IF    g_cond_tmp_chk_rec.wholesale_adj_margin_en_4    IS NULL
              AND g_cond_tmp_chk_rec.wholesale_adj_margin_per_4   IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen || cv_delimiter ||
                                                cv_msg_who_margin || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 65.�≮�}�[�W���C���i�~�j�Ɩ≮�}�[�W���C��(��)�̗������ݒ肳��Ă���ꍇ�G���[
            IF    g_cond_tmp_chk_rec.wholesale_adj_margin_en_4    IS NOT NULL
              AND g_cond_tmp_chk_rec.wholesale_adj_margin_per_4   IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_adj || cv_msg_yen ||
                                                cv_delimiter || cv_msg_who_margin || cv_msg_adj || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 66.�ʏ�X�[�i�~�j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.normal_shop_pay_en_4 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.normal_shop_pay_en_4 ,2)  <>  g_cond_tmp_chk_rec.normal_shop_pay_en_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_normal_sp || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.normal_shop_pay_en_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 66.����X�[�i�~�j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.just_shop_pay_en_4 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.just_shop_pay_en_4 ,2)  <>  g_cond_tmp_chk_rec.just_shop_pay_en_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_just_sp || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.just_shop_pay_en_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
-- 2021/04/28 Ver1.2 MOD Start
--            -- 66.�≮�}�[�W���C���i�~�j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            -- 66.�≮�}�[�W���C���i�~�j���}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[

--            IF g_cond_tmp_chk_rec.wholesale_adj_margin_en_4  <= 0
            IF g_cond_tmp_chk_rec.wholesale_adj_margin_en_4  < 0
-- 2021/04/28 Ver1.2 MOD End
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_adj_margin_en_4 ,2)  <>  g_cond_tmp_chk_rec.wholesale_adj_margin_en_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_adj || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_adj_margin_en_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
-- 2021/04/28 Ver1.2 MOD Start
--            -- 66.�≮�}�[�W���C��(��)��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            -- 66.�≮�}�[�W���C��(��)���}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
--            IF g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 <= 0
            IF g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 < 0
-- 2021/04/28 Ver1.2 MOD End
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 ,2)  <>  g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_adj || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_adj_margin_per_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * �D��z���^���̃`�F�b�N
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_spons  THEN
--
            -- 67.�i�ڃR�[�h�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.item_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 68.�i�ڃR�[�h���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[ -- ����
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 68.1.�i�ڃR�[�h���q�i�ڂ̏ꍇ�G���[
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 70.�i�ڃR�[�h�ɕR�t���A�P�ʊ��Z���擾�ł��Ȃ��ꍇ�G���[
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => cv_uom_hon
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 69-1.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
--
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 69-2.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 71.�\�����ʁi�{�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 72.���^�����v�i�~�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.support_amount_sum_en_5  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_sup_amt_sum
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 73.�\�����ʁi�{�j��0�܂��̓}�C�i�X�l�܂��͏�����������ꍇ�G���[
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.prediction_qty_5_6)  <>  g_cond_tmp_chk_rec.prediction_qty_5_6  THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.prediction_qty_5_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 74.���^�����v�i�~�j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.support_amount_sum_en_5  <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.support_amount_sum_en_5  ,2)  <>  g_cond_tmp_chk_rec.support_amount_sum_en_5 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_sup_amt_sum
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.support_amount_sum_en_5
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * �E�Ώې��ʗ\�����^���̃`�F�b�N
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_pre_spons  THEN
--
            -- 75.�i�ڃR�[�h�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.item_code IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 76.�i�ڃR�[�h���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[ -- ����
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
--
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 76.1.�i�ڃR�[�h���q�i�ڂ̏ꍇ�G���[
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 78.�i�ڃR�[�h�ɕR�t���A�P�ʊ��Z���擾�ł��Ȃ��ꍇ�G���[
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => cv_uom_hon
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 77-1.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̃f�[�^�Ŗ��ׂ̏����敪������̏ꍇ
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- ���׏����敪
              ;
--
              -- 2���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy > 1 THEN
--
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 77-2.�i�ڃR�[�h�d���`�F�b�N�F���ׂ̏����敪���o�^�ŁA����T���ԍ��A����i�ڃR�[�h�̏ꍇ
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- �T���ԍ�
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- �i�ڃR�[�h
              AND     xcl.enabled_flag_l       = cv_const_y                           -- �L���t���O
              ;
--
              -- 1���ȏ�擾�����ꍇ�A�i�ڏd���G���[
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 79.�\�����ʁi�{�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 80.�����P���i�~�j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 81.�Ώۗ�(��)�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.target_rate_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_tar_rate || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 82.�\�����ʁi�{�j��0�܂��͏�����������ꍇ�G���[
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.prediction_qty_5_6)  <>  g_cond_tmp_chk_rec.prediction_qty_5_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.prediction_qty_5_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 83.�����P���i�~�j��0�܂��̓}�C�i�X�l�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6  <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.condition_unit_price_en_2_6  ,2)  <>  g_cond_tmp_chk_rec.condition_unit_price_en_2_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.condition_unit_price_en_2_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 83.�Ώۗ�(��)��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.target_rate_6  <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.target_rate_6  ,2)  <>  g_cond_tmp_chk_rec.target_rate_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_tar_rate || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.target_rate_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * �F��z�T���̃`�F�b�N
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_fix_con  THEN
--
-- 2021/04/06 Ver1.1 MOD Start
--            -- 84.�v�㋒�_�����ݒ�̏ꍇ�G���[
--            IF g_cond_tmp_chk_rec.accounting_base IS NULL THEN
            -- 84.�v��ڋq�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.accounting_customer_code IS NULL THEN
-- 2021/04/06 Ver1.1 MOD End
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
-- 2021/04/06 Ver1.1 MOD Start
--                           , iv_token_value1 => cv_msg_accounting_base
                           , iv_token_value1 => cv_msg_account_customer_code
-- 2021/04/06 Ver1.1 MOD End
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
-- 2021/04/06 Ver1.1 MOD Start
--            -- 89.�v�㋒�_���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
            -- 89.�v��ڋq���}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
-- 2021/04/06 Ver1.1 MOD End
            ELSE
              BEGIN
                SELECT 1      AS  dummy
                INTO   ln_dummy
                FROM   hz_cust_accounts                  base_hzca      --�ڋq�}�X�^
-- 2021/04/06 Ver1.1 MOD Start
--                WHERE  base_hzca.account_number      = g_cond_tmp_chk_rec.accounting_base
--                AND    base_hzca.customer_class_code = cv_cust_class_base
                WHERE  base_hzca.account_number      = g_cond_tmp_chk_rec.accounting_customer_code
                AND    base_hzca.customer_class_code = cv_cust_class_cust
-- 2021/04/06 Ver1.1 MOD End
                AND    base_hzca.status              = cv_cust_accounts_status
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10600
                              , iv_token_name1  => cv_col_name_tok
-- 2021/04/06 Ver1.1 MOD Start
--                              , iv_token_value1 => cv_msg_accounting_base
--                              , iv_token_name2  => cv_col_value_tok
--                              , iv_token_value2 => g_cond_tmp_chk_rec.accounting_base
                              , iv_token_value1 => cv_msg_account_customer_code
                              , iv_token_name2  => cv_col_value_tok
                              , iv_token_value2 => g_cond_tmp_chk_rec.accounting_customer_code
                              );
-- 2021/04/06 Ver1.1 MOD End
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
            --85.�T���z�i�{�́j�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.deduction_amount IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_amout
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 86.�T���Ŋz�����ݒ�̏ꍇ�G���[
            IF g_cond_tmp_chk_rec.deduction_tax_amount IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_tax
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 87.�T���z�i�{�́j��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.deduction_amount <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.deduction_amount ,2)  <>  g_cond_tmp_chk_rec.deduction_amount THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_amout
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.deduction_amount
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 87.�T���Ŋz��0�܂��̓}�C�i�X�l�܂��͏�������2���𒴂���ꍇ�G���[
            IF g_cond_tmp_chk_rec.deduction_tax_amount <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.deduction_tax_amount ,2)  <>  g_cond_tmp_chk_rec.deduction_tax_amount THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_tax
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.deduction_tax_amount
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- �ŗ��擾
      BEGIN
        SELECT xch.tax_rate  tax_rate
        INTO   ln_tax_rate_1
        FROM   xxcok_condition_header  xch
        WHERE  xch.condition_no = g_cond_tmp_chk_rec.condition_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_tax_rate_1 := NULL;
      END;
--
      --  90.�T���ԍ��A�Ώۋ敪�A���i�敪�A�ŗ��̍X�V
      UPDATE  xxcok_condition_temp  xct
      SET     xct.detail_number        =   CASE WHEN xct.process_type_line = cv_process_insert THEN g_cond_tmp_chk_rec.detail_number ELSE xct.detail_number END
            , xct.product_class_code   =   CASE WHEN xct.product_class IS NOT NULL THEN lt_product_class_code ELSE NULL END
            , xct.target_category      =   CASE WHEN xct.target_category  IS NOT NULL THEN  lt_target_category  ELSE NULL END
            , xct.tax_rate             =   CASE
                                              WHEN NVL(g_cond_tmp_chk_rec.csv_process_type, cv_const_n ) IN (cv_csv_update,cv_csv_insert)
                                              AND g_cond_tmp_chk_rec.condition_type                NOT IN (cv_condition_type_ws_fix,cv_condition_type_ws_add) THEN
                                                ln_tax_rate
                                             ELSE 
                                                ln_tax_rate_1
                                           END
      WHERE   xct.ROWID                =   g_cond_tmp_chk_rec.row_id
      ;
--
      IF ( ln_cnt <> 0 ) THEN
        --  ���b�Z�[�W����̏ꍇ
        gv_check_result :=  'N';
        IF ( gn_message_cnt = 0 OR gn_message_cnt < ln_cnt ) THEN
          gn_message_cnt  :=  ln_cnt;
        END IF;
        gn_warn_cnt     :=  gn_warn_cnt + 1;
        ov_retcode      :=  cv_status_warn;
      END IF;
    END LOOP g_cond_tmp_chk_loop;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END validity_check;
--
    /**********************************************************************************
   * Procedure Name   : up_ins_chk
   * Description      : �폜��`�F�b�N(A-8)
   ***********************************************************************************/
  PROCEDURE up_ins_chk(
    ov_errbuf         OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2)                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'up_ins_chk'; -- �v���O������
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
    -- �_�~�[�l
    ln_dummy                      NUMBER;       -- �_�~�[�l
--
    -- �`�F�b�N�p�ꎞ�ێ��ϐ�
    ln_exists_header              NUMBER;
    ln_exists_line                NUMBER;
--
    -- ���b�Z�[�W�J�E���^
    ln_cnt                        NUMBER;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    g_message_list_tab.DELETE;
--
    --  ���b�Z�[�W�C���f�b�N�X������
    ln_cnt  :=  0;
--
    <<up_ins_chk_loop>>
    FOR g_cond_tmp_rec IN g_cond_tmp_cur LOOP
      IF g_cond_tmp_rec.process_type_line  IN ( cv_process_delete) THEN
        -- �Ɩ����t������ɍ폜���s���ꍇ
        IF ( TO_DATE(g_cond_tmp_rec.start_date_active,cv_date_format) <= gd_process_date ) THEN
          -- �T���^�C�v���u�D��z���^���v�̏ꍇ
          IF  g_cond_tmp_rec.condition_type     =  cv_condition_type_spons THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10678
               , iv_token_name1  => cv_tkn_condition_type
               , iv_token_value1 => g_cond_tmp_rec.condition_type
            );
--
            ln_cnt  :=  ln_cnt + 1;

            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        CONTINUE up_ins_chk_loop;
      END IF;
--
      -- �Ɩ����t������ɓo�^���s���ꍇ
      IF ( TO_DATE(g_cond_tmp_rec.start_date_active,cv_date_format) <= gd_process_date ) THEN
        -- �����敪���u�o�^�v�ȊO�A���׏����敪���u�o�^�v�A���T���^�C�v���u�D��z���^���v�̏ꍇ
        IF  g_cond_tmp_rec.condition_type     =  cv_condition_type_spons
        AND NVL(g_cond_tmp_rec.process_type, cv_const_n )      !=  cv_process_insert
        AND NVL(g_cond_tmp_rec.process_type_line, cv_const_n )  =  cv_process_insert THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10678
             , iv_token_name1  => cv_tkn_condition_type
             , iv_token_value1 => g_cond_tmp_rec.condition_type
          );
--
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      --  ************************************************
      --  UPDATE�Ώۂ̑��݃`�F�b�N�i�}�X�^�j
      --  ************************************************
      ln_exists_header  :=  0;
      ln_exists_line    :=  0;
      --  ��̍폜�����ŏ������\�������邽�߁A�폜��Ƀ`�F�b�N
      IF ( g_cond_tmp_rec.process_type IN( cv_process_update, cv_const_n ) ) THEN
        --  �w�b�_�̏����敪�� U or NULL �̏ꍇ�A�T���ԍ�����v����L���ȃ}�X�^�����݂��邩
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_exists_header
        FROM    xxcok_condition_header    xch
        WHERE   xch.condition_no    =   g_cond_tmp_rec.condition_no
        AND     xch.enabled_flag_h  =   cv_const_y
        ;
      END IF;
      --
      --  �F
      IF ( g_cond_tmp_rec.condition_type =  cv_condition_type_fix_con ) THEN
        -- �����敪���C���܂���NULL�i�ΏۊO�j
        IF  g_cond_tmp_rec.process_type IN( cv_process_update, cv_const_n ) THEN
--
          --  �w�b�_��U or NULL�̏ꍇ�A�L���ȃw�b�_�����݂��Ȃ�
          IF  ln_exists_header = 0  THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_condition_no
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_rec.condition_no
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
      --  �@or�Aor�Bor�Cor�Dor�E
      IF ( g_cond_tmp_rec.condition_type IN( cv_condition_type_req ,cv_condition_type_sale ,cv_condition_type_ws_fix
                                            , cv_condition_type_ws_add, cv_condition_type_spons, cv_condition_type_pre_spons ) ) THEN
        --  �w�b�_��U or NULL�̏ꍇ�A�L���ȃw�b�_�����݂��Ȃ�
        IF  ( g_cond_tmp_rec.process_type IN( cv_process_update, cv_const_n )
          AND ln_exists_header  =   0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_condition_no
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_rec.condition_no
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      --  **************************************
      --   �d���`�F�b�N
      --  **************************************
--
      -- �@
      IF ( g_cond_tmp_rec.condition_type = cv_condition_type_req ) THEN
        -- �Ώۋ敪�̕s��v�`�F�b�N
--
        IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
          --  CSV���d��(�L�[���ڌ���)
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_temp    xct
          WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
          AND     xct.target_category                             <>  g_cond_tmp_rec.target_category
          AND     xct.request_id                                  =   cn_request_id
          AND     xct.process_type                                =   cv_process_insert
          AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
          ;
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10609
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_target_cate
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.condition_type = cv_condition_type_req ) THEN
        -- �Ώۋ敪�̕s��v�`�F�b�N
--
        IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
          --  �}�X�^�d��(�T���ԍ������j
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_header    xch
                , xxcok_condition_lines     xcl
          WHERE   xch.condition_no       =  xcl.condition_no                   -- �T���ԍ�
          AND     xcl.target_category   <>  g_cond_tmp_rec.target_category     -- �Ώۋ敪
          AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- �T���ԍ�
          AND     xcl.enabled_flag_l     =  cv_const_y                         -- �L���t���O
          AND     xcl.detail_number     <>  g_cond_tmp_rec.detail_number       -- ���הԍ�
          ;
--
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10608
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_target_cate
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
          --  CSV���ňقȂ�s���Ȃ����`�F�b�N
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_temp    xct
          WHERE   xct.condition_no        =  g_cond_tmp_rec.condition_no
          AND     xct.target_category    <>  g_cond_tmp_rec.target_category
          AND     xct.request_id          =  cn_request_id
          AND     xct.process_type_line   =  cv_process_insert
          AND     xct.rowid              <>  g_cond_tmp_rec.row_id
          ;
--
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10609
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_target_cate
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
--
      -- �@�A�A�̏ꍇ
      IF ( g_cond_tmp_rec.condition_type IN ( cv_condition_type_req, cv_condition_type_sale ) ) THEN
        --  ���i�敪�̏d�����`�F�b�N

        IF  ( g_cond_tmp_rec.product_class IS NOT NULL
              AND
              g_cond_tmp_rec.process_type_line = cv_process_insert
            )
        THEN
          IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
            --  CSV���d��(�L�[���ڌ���)
            ln_dummy  :=  0;
            SELECT  COUNT(1)      AS  cnt
            INTO    ln_dummy
            FROM    xxcok_condition_temp    xct
            WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
            AND     xct.product_class_code                          =   g_cond_tmp_rec.product_class_code
            AND     xct.request_id                                  =   cn_request_id
            AND     xct.process_type                                =   cv_process_insert
            AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
            ;
            IF ( ln_dummy <> 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10608
               , iv_token_name1  => cv_col_name_tok
               , iv_token_value1 => cv_msg_item_kbn
               );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  �}�X�^�d��(�T���ԍ������j
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_header    xch
              , xxcok_condition_lines     xcl
        WHERE   xch.condition_no       =  xcl.condition_no                   -- �T���ԍ�
        AND     xcl.product_class      =  g_cond_tmp_rec.product_class       -- ���i�敪
        AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- �T���ԍ�
        AND     xcl.enabled_flag_l     =  cv_const_y                         -- �L���t���O
        AND     xcl.detail_number     <>  g_cond_tmp_rec.detail_number       -- ���הԍ�
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10608
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  CSV���ňقȂ�s���Ȃ����`�F�b�N
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_temp    xct
        WHERE   xct.condition_no        =  g_cond_tmp_rec.condition_no
        AND     xct.product_class       =  g_cond_tmp_rec.product_class
        AND     xct.request_id          =  cn_request_id
        AND     xct.process_type_line   =  cv_process_insert
        AND     xct.rowid              <>  g_cond_tmp_rec.row_id
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10609
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      --  �@or�Aor�Bor�Cor�Dor�E
      IF ( g_cond_tmp_rec.condition_type IN( cv_condition_type_req, cv_condition_type_sale, cv_condition_type_ws_fix
                                        , cv_condition_type_ws_add, cv_condition_type_spons, cv_condition_type_pre_spons ) ) THEN
        --  �i�ڃR�[�h�̏d�����`�F�b�N
        IF  ( g_cond_tmp_rec.item_code IS NOT NULL
            )
        THEN
          IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
            --  CSV���d��(�L�[���ڌ���)
            ln_dummy  :=  0;
            SELECT  COUNT(1)      AS  cnt
            INTO    ln_dummy
            FROM    xxcok_condition_temp    xct
            WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
            AND     xct.item_code                                   =   g_cond_tmp_rec.item_code
            AND     xct.request_id                                  =   cn_request_id
            AND     xct.process_type                                =   cv_process_insert
            AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
            ;
--
            IF ( ln_dummy <> 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10608
               , iv_token_name1  => cv_col_name_tok
               , iv_token_value1 => cv_msg_item_code
               );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  �}�X�^�d��(�T���ԍ������j
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_header    xch
              , xxcok_condition_lines     xcl
        WHERE   xch.condition_no       =  xcl.condition_no                   -- �T���ԍ�
        AND     xcl.item_code          =  g_cond_tmp_rec.item_code           -- �i�ڃR�[�h
        AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- �T���ԍ�
        AND     xcl.enabled_flag_l     =  cv_const_y                         -- �L���t���O
        AND     xcl.detail_number     <>  g_cond_tmp_rec.detail_number       -- ���הԍ�
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10608
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  CSV���ňقȂ�s���Ȃ����`�F�b�N
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_temp    xct
        WHERE   xct.condition_no        =  g_cond_tmp_rec.condition_no
        AND     xct.item_code           =  g_cond_tmp_rec.item_code
        AND     xct.request_id          =  cn_request_id
        AND     xct.process_type_line   =  cv_process_insert
        AND     xct.rowid              <>  g_cond_tmp_rec.row_id
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10609
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      -- �D�̏ꍇ
      IF  g_cond_tmp_rec.condition_type =  cv_condition_type_spons  THEN
        -- ��z���^�����v�̕s��v�`�F�b�N
        IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
--
          --  CSV���d��(�L�[���ڌ���)
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_temp    xct
          WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
          AND     xct.support_amount_sum_en_5                     <>  g_cond_tmp_rec.support_amount_sum_en_5
          AND     xct.request_id                                  =   cn_request_id
          AND     xct.process_type                                =   cv_process_insert
          AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
          ;
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10609
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_sup_amt_sum
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
      --
-- 2021/04/06 Ver1.1 DEL Start
--      IF  g_cond_tmp_rec.condition_type =  cv_condition_type_fix_con  THEN
----
--        IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
--          --  �}�X�^�d��(�T���ԍ������j
--          ln_dummy  :=  0;
--          SELECT  COUNT(1)      AS  cnt
--          INTO    ln_dummy
--          FROM    xxcok_condition_header    xch
--                , xxcok_condition_lines     xcl
--          WHERE   xch.condition_no       =  xcl.condition_no                   -- �T���ԍ�
--          AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- �T���ԍ�
--          AND     xcl.enabled_flag_l     =  cv_const_y                         -- �L���t���O
--          ;
----
--          IF ( ln_dummy <> 0 ) THEN
--            lv_errmsg := xxccp_common_pkg.get_msg(
--               iv_application  => cv_msg_kbn_cok
--             , iv_name         => cv_msg_cok_10710
--             );
--            ln_cnt  :=  ln_cnt + 1;
--            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--          END IF;
--        END IF;
--      END IF;
-- 2021/04/06 Ver1.1 DEL End
--
      IF ( ln_cnt <> 0 ) THEN
        --  ���b�Z�[�W����̏ꍇ
        gv_check_result :=  'N';
        IF ( gn_message_cnt = 0 OR gn_message_cnt < ln_cnt ) THEN
          gn_message_cnt  :=  ln_cnt;
        END IF;
        gn_warn_cnt     :=  gn_warn_cnt + 1;
        ov_retcode      :=  cv_status_warn;
      END IF;
    END LOOP up_ins_chk_loop;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END up_ins_chk;
--
    /**********************************************************************************
   * Procedure Name   : ins_up_process
   * Description      : �T���}�X�^�o�^��ύX����(A-9)
   ***********************************************************************************/
  PROCEDURE up_ins_process(
    ov_errbuf         OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2)                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'up_ins_process'; -- �v���O������
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
    lt_condition_id               xxcok_condition_header.condition_id%TYPE;
    lt_condition_no               xxcok_condition_header.condition_no%TYPE;
    lt_condition_line_id          xxcok_condition_lines.condition_line_id%TYPE;
    lt_uom_code                   xxcok_condition_lines.uom_code%TYPE;
    lt_compensation_en_3          xxcok_condition_lines.compensation_en_3%TYPE;
    lt_wholesale_margin_en_3      xxcok_condition_lines.wholesale_margin_en_3%TYPE;
    lt_wholesale_margin_per_3     xxcok_condition_lines.wholesale_margin_per_3%TYPE;
    lt_accrued_en_3               xxcok_condition_lines.accrued_en_3%TYPE;
    lt_just_condition_en_4        xxcok_condition_lines.just_condition_en_4%TYPE;
    lt_wholesale_adj_margin_en_4  xxcok_condition_lines.wholesale_adj_margin_en_4%TYPE;
    lt_wholesale_adj_margin_per_4 xxcok_condition_lines.wholesale_adj_margin_per_4%TYPE;
    lt_accrued_en_4               xxcok_condition_lines.accrued_en_4%TYPE;
    lt_deduction_unit_price_en_6  xxcok_condition_lines.deduction_unit_price_en_6%TYPE;
    ln_prediction_qty_sum         NUMBER;                                                     -- �\�����ʍ��v
    lt_ratio_per                  xxcok_condition_lines.ratio_per_5%TYPE;                     -- �䗦
    lt_amount_prorated_en         xxcok_condition_lines.amount_prorated_en_5%TYPE;            -- ���z��
    lt_cond_unit_price_en         xxcok_condition_lines.condition_unit_price_en_5%TYPE;       -- �����P��
-- 2021/04/06 Ver1.1 ADD Start
    lv_condition_no_out           VARCHAR2(1000);
    lv_agreement_no_out           VARCHAR2(1000);
    lv_data_type_out              VARCHAR2(1000);
    lv_content_out                VARCHAR2(1000);
-- 2021/04/06 Ver1.1 ADD End
--
    -- �O�񏈗��̃L�[����
    lt_prev_condition_no          xxcok_condition_temp.condition_no%TYPE;        -- �T���ԍ�
--
    ld_start_date                 DATE;
    ld_end_date                   DATE;
--
    -- �T���ԍ������p
    lt_sql_str                    VARCHAR2(100);
    lv_process_year               VARCHAR2(4);
    --
    -- *** ���[�J���E�J�[�\�� ***
    -- �T���}�X�^�̎擾�J�[�\��(�Čv�Z�p)
    --  ���񏈗��Ŗ��ׂ��A�o�^�E�X�V�E�폜���ꂽ�T���ԍ����擾
    CURSOR target_condition_cur
    IS
      SELECT  DISTINCT  xcl.condition_no
      FROM    xxcok_condition_lines   xcl
      WHERE   xcl.request_id      =   cn_request_id
      ;
    target_condition_rec    target_condition_cur%ROWTYPE;
    --
    CURSOR get_cond_cur (lt_condition_no IN VARCHAR2)
    IS
      SELECT  xcl.ROWID                       AS  row_id
            , xcl.prediction_qty_5            AS  prediction_qty_5
            , xcl.support_amount_sum_en_5     AS  support_amount_sum_en_5
      FROM  xxcok_condition_lines   xcl
      WHERE   xcl.condition_no    = lt_condition_no
      AND     xcl.enabled_flag_l  = cv_const_y
      ORDER BY  xcl.detail_number
    ;
    get_cond_rec  get_cond_cur%ROWTYPE;
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
    -- ���[�J���ϐ�������
    lt_condition_id       :=  NULL;
    lt_condition_no       :=  NULL;
    lt_prev_condition_no  :=  cv_space;
--
    --  �N�x���擾
    lv_process_year   :=  CASE  WHEN  TO_CHAR( gd_process_date, cv_date_month ) IN( cv_month_jan, cv_month_feb, cv_month_mar, cv_month_apr )
                                  THEN  TO_CHAR( TO_NUMBER( TO_CHAR( gd_process_date, cv_date_year ) ) - 1 )
                                  ELSE  TO_CHAR( gd_process_date, cv_date_year )
                          END;
--
    <<get_cond_tm_loop3>>
    FOR g_cond_tmp_chk_rec IN g_cond_tmp_chk_cur LOOP
      --
      --  CSV�̊J�n���A�I�������^�ϊ����ĕێ�
      ld_start_date   :=  TO_DATE(g_cond_tmp_chk_rec.start_date_active, cv_date_format);
      ld_end_date     :=  TO_DATE(g_cond_tmp_chk_rec.end_date_active, cv_date_format);
--
      --  ************************************************
      --  �T�����e�[�u���̕ύX
      --  ************************************************
      --  �w�b�_�����͓���T���ԍ����ƂɂP��̂ݏ�������(����͕K����������)
      IF (  lt_prev_condition_no <> g_cond_tmp_chk_rec.condition_no ) THEN
        --  �����ύT���ԍ���ێ�(INSERT�̏ꍇ�̓_�~�[�T���ԍ��Ŕ��f����邽�߁A�V�K�ō̔Ԃ����T���ԍ����l������K�v�͂Ȃ��j
        lt_prev_condition_no :=  g_cond_tmp_chk_rec.condition_no;
        lt_condition_id   :=  g_cond_tmp_chk_rec.condition_id;
        lt_condition_no   :=  g_cond_tmp_chk_rec.condition_no;
        --
        -- �����敪���X�V�̏ꍇ
        IF ( g_cond_tmp_chk_rec.process_type = cv_process_update ) THEN
          --
          --  ************************************************
          --  �w�b�_�̍X�V
          --  ************************************************
          BEGIN
            UPDATE  xxcok_condition_header xch
            SET     xch.corp_code                 =   g_cond_tmp_chk_rec.corp_code                                    --  ��ƃR�[�h
                  , xch.deduction_chain_code      =   g_cond_tmp_chk_rec.deduction_chain_code                         --  �`�F�[���X�R�[�h
                  , xch.customer_code             =   g_cond_tmp_chk_rec.customer_code                                --  �ڋq�R�[�h
                  , xch.data_type                 =   g_cond_tmp_chk_rec.data_type                                    --  �f�[�^���
                  , xch.tax_code                  =   g_cond_tmp_chk_rec.tax_code                                     --  �ŃR�[�h
                  , xch.tax_rate                  =   g_cond_tmp_chk_rec.tax_rate                                     --  �ŗ�
                  , xch.start_date_active         =   ld_start_date                                                   --  �J�n��
                  , xch.end_date_active           =   ld_end_date                                                     --  �I����
                  , xch.header_recovery_flag      =   g_cond_tmp_chk_rec.process_type                                 --  ���J�o���Ώۃt���O
                  , xch.last_updated_by           =   cn_last_updated_by
                  , xch.last_update_date          =   cd_last_update_date
                  , xch.last_update_login         =   cn_last_update_login
                  , xch.request_id                =   cn_request_id
                  , xch.program_application_id    =   cn_program_application_id
                  , xch.program_id                =   cn_program_id
                  , xch.program_update_date       =   cd_program_update_date
            WHERE   xch.condition_no              =   g_cond_tmp_chk_rec.condition_no
            ;
            IF ( ld_start_date  <= gd_process_date ) THEN
              --  �w�b�_���X�V���ꂽ���Ƃɔ����A���ׂ̃��J�o���Ώۃt���O��ύX
              UPDATE  xxcok_condition_lines  xcl
              SET     xcl.line_recovery_flag        = CASE  WHEN  ld_start_date  <= gd_process_date
                                                        THEN  g_cond_tmp_chk_rec.process_type
                                                        ELSE  cv_const_n
                                                      END                                           --  ���J�o���Ώۃt���O
                    , xcl.last_updated_by           =   cn_last_updated_by
                    , xcl.last_update_date          =   cd_last_update_date
                    , xcl.last_update_login         =   cn_last_update_login
                    , xcl.request_id                =   cn_request_id
                    , xcl.program_application_id    =   cn_program_application_id
                    , xcl.program_id                =   cn_program_id
                    , xcl.program_update_date       =   cd_program_update_date
              WHERE   xcl.condition_no    = g_cond_tmp_chk_rec.condition_no
              AND     xcl.enabled_flag_l  = cv_const_y
              ;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10587
                         , iv_token_name1  => cv_table_name_tok
                         , iv_token_value1 => cv_msg_condition_h
                         , iv_token_name2  => cv_key_data_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_process_expt;
          END;
        -- �����敪�����ق̏ꍇ
        ELSIF ( g_cond_tmp_chk_rec.process_type = cv_process_decision ) THEN
          --
          --  ************************************************
          --  �w�b�_�̍X�V
          --  ************************************************
          BEGIN
            UPDATE  xxcok_condition_header
            SET     content                   =   g_cond_tmp_chk_rec.content                                      --  ���e
                  , decision_no               =   g_cond_tmp_chk_rec.decision_no                                  --  ����No
                  , header_recovery_flag      =   'Z'                                                             --  ���J�o���Ώۃt���O
                  , agreement_no              =   g_cond_tmp_chk_rec.agreement_no                                 --  �_��ԍ�
                  , last_updated_by           =   cn_last_updated_by
                  , last_update_date          =   cd_last_update_date
                  , last_update_login         =   cn_last_update_login
                  , request_id                =   cn_request_id
                  , program_application_id    =   cn_program_application_id
                  , program_id                =   cn_program_id
                  , program_update_date       =   cd_program_update_date
            WHERE   condition_no              =   g_cond_tmp_chk_rec.condition_no
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10587
                         , iv_token_name1  => cv_table_name_tok
                         , iv_token_value1 => cv_msg_condition_h
                         , iv_token_name2  => cv_key_data_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_process_expt;
          END;
        ELSIF ( g_cond_tmp_chk_rec.process_type   = cv_process_insert ) THEN
          --  �����敪���}���̏ꍇ
          --  ***************************************
          --  �w�b�_��񐶐�
          --  ***************************************
          --  lt_condition_id, lt_condition_no�͍T���ڍׁi���ׁj�ɂ��g�p����
          --  �T������ID�̎擾
          --  �T���ԍ��𔭍s
          SELECT  xxcok.xxcok_condition_header_s01.nextval      AS  condition_id
          INTO    lt_condition_id
          FROM    dual
          ;
          --  �T���ԍ������i�N�x���ƂɈقȂ�V�[�P���X���g�p����j
          DECLARE
            lt_sql_str      VARCHAR2(100);
            --
            TYPE  cur_type  IS  REF CURSOR;
            condition_no_cur  cur_type;
            --
            TYPE  rec_type  IS RECORD(
              condition_no        xxcok_condition_header.condition_no%TYPE
            );
            condition_no_rec  rec_type;
          BEGIN
            lt_sql_str  :=    'SELECT XXCOK.XXCOK_CONDITION_NO_' || lv_process_year || '_S01.NEXTVAL  AS  condition_no FROM DUAL';
            OPEN  condition_no_cur FOR lt_sql_str;
            FETCH condition_no_cur INTO condition_no_rec;
            CLOSE condition_no_cur;
            --
            IF ( LENGTHB( condition_no_rec.condition_no ) > 8 ) THEN
              lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10676
                            );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            ELSE
              lt_condition_no               :=  lv_process_year || LPAD( condition_no_rec.condition_no, 8, '0' );
              condition_no_rec.condition_no :=  lt_condition_no;
            END IF;
            --
            --  ���������T���ԍ������b�N
            INSERT INTO xxcok_exclusive_ctl_info(
                condition_no
              , request_id
            ) VALUES (
                lt_condition_no
              , cn_request_id
            );
          END;
          --
          --  ***************************************
          --  �w�b�_�̑}��
          --  ***************************************
          BEGIN
            INSERT INTO xxcok_condition_header(
                condition_id                --  �T������ID
              , condition_no                --  �T���ԍ�
              , enabled_flag_h              --  �L���t���O
              , corp_code                   --  ��ƃR�[�h
              , deduction_chain_code        --  �`�F�[���X�R�[�h
              , customer_code               --  �ڋq�R�[�h
              , data_type                   --  �f�[�^���
              , tax_code                    --  �ŃR�[�h
              , tax_rate                    --  �ŗ�
              , start_date_active           --  �J�n��
              , end_date_active             --  �I����
              , content                     --  ���e
              , decision_no                 --  ����No
              , agreement_no                --  �_��ԍ�
              , header_recovery_flag        --  ���J�o���Ώۃt���O
              , created_by                  --  �쐬��
              , creation_date               --  �쐬��
              , last_updated_by             --  �ŏI�X�V��
              , last_update_date            --  �ŏI�X�V��
              , last_update_login           --  �ŏI�X�V���O�C��
              , request_id                  --  �v��ID
              , program_application_id      --  �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              , program_id                  --  �R���J�����g�E�v���O����ID
              , program_update_date         --  �v���O�����X�V��
            )VALUES(
                lt_condition_id                                                       -- �T������ID
              , lt_condition_no                                                       -- �T���ԍ�
              , cv_const_y                                                            -- �L���t���O
              , g_cond_tmp_chk_rec.corp_code                                          -- ��ƃR�[�h
              , g_cond_tmp_chk_rec.deduction_chain_code                               -- �`�F�[���X�R�[�h
              , g_cond_tmp_chk_rec.customer_code                                      -- �ڋq�R�[�h
              , g_cond_tmp_chk_rec.data_type                                          -- �f�[�^���
              , g_cond_tmp_chk_rec.tax_code                                           -- �ŃR�[�h
              , g_cond_tmp_chk_rec.tax_rate                                           -- �ŗ�
              , ld_start_date                                                         -- �J�n��
              , ld_end_date                                                           -- �I����
              , g_cond_tmp_chk_rec.content                                            -- ���e
              , g_cond_tmp_chk_rec.decision_no                                        -- ����No
              , g_cond_tmp_chk_rec.agreement_no                                       -- �_��ԍ�
              , g_cond_tmp_chk_rec.process_type                                       -- ���J�o���Ώۃt���O
              , cn_created_by                                                         -- �쐬��
              , cd_creation_date                                                      -- �쐬��
              , cn_last_updated_by                                                    -- �ŏI�X�V��
              , cd_last_update_date                                                   -- �ŏI�X�V��
              , cn_last_update_login                                                  -- �ŏI�X�V���O�C��
              , cn_request_id                                                         -- �v��ID
              , cn_program_application_id                                             -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              , cn_program_id                                                         -- �R���J�����g�E�v���O����ID
              , cd_program_update_date                                                -- �v���O�����X�V��
            )
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- �G���[���b�Z�[�W�̎擾
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10586
                           , iv_token_name1  => cv_table_name_tok
                           , iv_token_value1 => cv_msg_condition_h
                           , iv_token_name2  => cv_key_data_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                           );
              lv_errbuf :=  lv_errmsg;
              RAISE global_process_expt;
          END;
-- 2021/04/06 Ver1.1 ADD Start
-- �w�b�_�ɑ}������ꍇ�u�T���ԍ��v�u�_��ԍ��v�u�f�[�^��ށv�u���e�v���o�͂���
          --�T���ԍ�
          lv_condition_no_out  := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_condition_no
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => lt_condition_no
                                  );
          --�_��ԍ�
          lv_agreement_no_out  := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_agreement_no
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => g_cond_tmp_chk_rec.agreement_no
                                  );
          --�f�[�^���
          lv_data_type_out     := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_data_type
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => g_cond_tmp_chk_rec.data_type
                                  );
          --���e
          lv_content_out       := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_content
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => g_cond_tmp_chk_rec.content
                                  );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ''                   || CHR(10) ||
                      lv_condition_no_out  || CHR(10) ||
                      lv_agreement_no_out  || CHR(10) ||
                      lv_data_type_out     || CHR(10) ||
                      lv_content_out       || CHR(10)
          );
-- 2021/04/06 Ver1.1 ADD End
        END IF;
      END IF;
--
      --  ************************************************
      --  �T���ڍ׃e�[�u���̕ύX
      --  ************************************************
      --  ************************************************
      --  �T���ڍ׃e�[�u���̐ݒ�l�v�Z
      --  ************************************************
      --  �P�ʁF�T���^�C�v�u030(�≮�����i��z�j)�v�u040(�≮�����i�ǉ��j)�v�̏ꍇ��CSV�̒l���g�p
      --        ��L�ȊO�̏ꍇ�́u�{�v�Œ�
      lt_uom_code :=  CASE  WHEN  g_cond_tmp_chk_rec.condition_type IN( cv_condition_type_ws_fix, cv_condition_type_ws_add )
                        THEN  g_cond_tmp_chk_rec.uom_code
                        ELSE  cv_uom_hon
                      END;
      --  �T���^�C�v�u030(�≮�����i��z�j)�v�̏ꍇ�A��U(�~)�A�≮�}�[�W��(�~)�A�≮�}�[�W��(��)�A�����v�R(�~)���v�Z
      IF ( g_cond_tmp_chk_rec.condition_type = cv_condition_type_ws_fix ) THEN
        lt_compensation_en_3            :=  g_cond_tmp_chk_rec.demand_en_3 - g_cond_tmp_chk_rec.shop_pay_en_3;
        lt_wholesale_margin_en_3        :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_margin_en_3 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_margin_en_3
                                              ELSE  g_cond_tmp_chk_rec.shop_pay_en_3 * (g_cond_tmp_chk_rec.wholesale_margin_per_3 / cn_100)
                                            END;
        lt_wholesale_margin_per_3       :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_margin_per_3 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_margin_per_3
                                              ELSE (g_cond_tmp_chk_rec.wholesale_margin_en_3 / g_cond_tmp_chk_rec.shop_pay_en_3) * cn_100
                                            END;
        lt_accrued_en_3                 :=  lt_compensation_en_3 + lt_wholesale_margin_en_3;
        --  ���ׂČv�Z��Ɏl�̌ܓ�
        lt_compensation_en_3            :=  ROUND( lt_compensation_en_3, 2 );
        lt_wholesale_margin_en_3        :=  ROUND( lt_wholesale_margin_en_3, 2 );
        lt_wholesale_margin_per_3       :=  ROUND( lt_wholesale_margin_per_3, 2 );
        lt_accrued_en_3                 :=  ROUND( lt_accrued_en_3, 2 );
      ELSE
        lt_compensation_en_3            :=  NULL;
        lt_wholesale_margin_en_3        :=  NULL;
        lt_wholesale_margin_per_3       :=  NULL;
        lt_accrued_en_3                 :=  NULL;
      END IF;
      --  �T���^�C�v�u040(�≮�����i�ǉ��j)�v�̏ꍇ�A�������(�~)�A�≮�}�[�W���C��(�~)�A�≮�}�[�W���C��(��)�A�����v�S(�~)���v�Z
      IF ( g_cond_tmp_chk_rec.condition_type = cv_condition_type_ws_add ) THEN
        lt_just_condition_en_4          :=  g_cond_tmp_chk_rec.normal_shop_pay_en_4 - g_cond_tmp_chk_rec.just_shop_pay_en_4;
        lt_wholesale_adj_margin_en_4    :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_adj_margin_en_4 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_adj_margin_en_4
                                              ELSE  ( lt_just_condition_en_4 * (g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 / cn_100))
                                            END;
        lt_wholesale_adj_margin_per_4   :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_adj_margin_per_4
                                              ELSE  ( ( lt_wholesale_adj_margin_en_4 ) / lt_just_condition_en_4) * cn_100
                                            END;
        lt_accrued_en_4                 :=  lt_just_condition_en_4 - lt_wholesale_adj_margin_en_4;
        --  ���ׂČv�Z��Ɏl�̌ܓ�
        lt_just_condition_en_4          :=  ROUND( lt_just_condition_en_4, 2 );
        lt_wholesale_adj_margin_en_4    :=  ROUND( lt_wholesale_adj_margin_en_4, 2 );
        lt_wholesale_adj_margin_per_4   :=  ROUND( lt_wholesale_adj_margin_per_4, 2 );
        lt_accrued_en_4                 :=  ROUND( lt_accrued_en_4, 2 );
      ELSE
        lt_just_condition_en_4          :=  NULL;
        lt_wholesale_adj_margin_en_4    :=  NULL;
        lt_wholesale_adj_margin_per_4   :=  NULL;
        lt_accrued_en_4                 :=  NULL;
      END IF;
      --  �T���^�C�v�u060(�Ώې��ʗ\�����^��)�v�̏ꍇ�A�T���P��(�~)���v�Z
      IF ( g_cond_tmp_chk_rec.condition_type = cv_condition_type_pre_spons ) THEN
        lt_deduction_unit_price_en_6    :=  ROUND(g_cond_tmp_chk_rec.condition_unit_price_en_2_6 * (g_cond_tmp_chk_rec.target_rate_6 / cn_100), 2);
      ELSE
        lt_deduction_unit_price_en_6    :=  NULL;
      END IF;
      --
      IF ( g_cond_tmp_chk_rec.process_type_line = cv_process_insert ) THEN
        --  �T���ڍ�ID�擾
        SELECT  xxcok.xxcok_condition_lines_s01.nextval     AS  condition_line_id
        INTO    lt_condition_line_id
        FROM    dual
        ;
        --
        --  ************************************************
        --  ���ׂ̑}��
        --  ************************************************
        BEGIN
          INSERT INTO xxcok_condition_lines(
              CONDITION_LINE_ID
            , CONDITION_ID
            , CONDITION_NO
            , DETAIL_NUMBER
            , ENABLED_FLAG_L
            , TARGET_CATEGORY
            , PRODUCT_CLASS
            , ITEM_CODE
            , UOM_CODE
            , LINE_RECOVERY_FLAG
            , SHOP_PAY_1
            , MATERIAL_RATE_1
            , CONDITION_UNIT_PRICE_EN_2
            , DEMAND_EN_3
            , SHOP_PAY_EN_3
            , COMPENSATION_EN_3
            , WHOLESALE_MARGIN_EN_3
            , WHOLESALE_MARGIN_PER_3
            , ACCRUED_EN_3
            , NORMAL_SHOP_PAY_EN_4
            , JUST_SHOP_PAY_EN_4
            , JUST_CONDITION_EN_4
            , WHOLESALE_ADJ_MARGIN_EN_4
            , WHOLESALE_ADJ_MARGIN_PER_4
            , ACCRUED_EN_4
            , PREDICTION_QTY_5
            , RATIO_PER_5
            , AMOUNT_PRORATED_EN_5
            , CONDITION_UNIT_PRICE_EN_5
            , SUPPORT_AMOUNT_SUM_EN_5
            , PREDICTION_QTY_6
            , CONDITION_UNIT_PRICE_EN_6
            , TARGET_RATE_6
            , DEDUCTION_UNIT_PRICE_EN_6
-- 2021/04/06 Ver1.1 MOD Start
--            , ACCOUNTING_BASE
            , ACCOUNTING_CUSTOMER_CODE
-- 2021/04/06 Ver1.1 MOD End
            , DEDUCTION_AMOUNT
            , DEDUCTION_TAX_AMOUNT
            , DL_WHOLESALE_MARGIN_EN
            , DL_WHOLESALE_MARGIN_PER
            , DL_WHOLESALE_ADJ_MARGIN_EN
            , DL_WHOLESALE_ADJ_MARGIN_PER
            , CREATED_BY
            , CREATION_DATE
            , LAST_UPDATED_BY
            , LAST_UPDATE_DATE
            , LAST_UPDATE_LOGIN
            , REQUEST_ID
            , PROGRAM_APPLICATION_ID
            , PROGRAM_ID
            , PROGRAM_UPDATE_DATE
          )VALUES(
              lt_condition_line_id
            , lt_condition_id
            , lt_condition_no
            , g_cond_tmp_chk_rec.detail_number
            , cv_const_y
            , g_cond_tmp_chk_rec.target_category
            , g_cond_tmp_chk_rec.product_class_code
            , g_cond_tmp_chk_rec.item_code
            , lt_uom_code
            , g_cond_tmp_chk_rec.process_type_line
            , g_cond_tmp_chk_rec.shop_pay_1
            , g_cond_tmp_chk_rec.material_rate_1
            , g_cond_tmp_chk_rec.condition_unit_price_en_2_6
            , g_cond_tmp_chk_rec.demand_en_3
            , g_cond_tmp_chk_rec.shop_pay_en_3
            , lt_compensation_en_3
            , lt_wholesale_margin_en_3
            , lt_wholesale_margin_per_3
            , lt_accrued_en_3
            , g_cond_tmp_chk_rec.normal_shop_pay_en_4
            , g_cond_tmp_chk_rec.just_shop_pay_en_4
            , lt_just_condition_en_4
            , lt_wholesale_adj_margin_en_4
            , lt_wholesale_adj_margin_per_4
            , lt_accrued_en_4
            , g_cond_tmp_chk_rec.prediction_qty_5_6
            , NULL
            , NULL
            , NULL
            , g_cond_tmp_chk_rec.support_amount_sum_en_5
            , g_cond_tmp_chk_rec.prediction_qty_5_6
            , g_cond_tmp_chk_rec.condition_unit_price_en_2_6
            , g_cond_tmp_chk_rec.target_rate_6
            , lt_deduction_unit_price_en_6
-- 2021/04/06 Ver1.1 MOD Start
--            , g_cond_tmp_chk_rec.accounting_base
            , g_cond_tmp_chk_rec.accounting_customer_code
-- 2021/04/06 Ver1.1 MOD End
            , g_cond_tmp_chk_rec.deduction_amount
            , g_cond_tmp_chk_rec.deduction_tax_amount
            , g_cond_tmp_chk_rec.wholesale_margin_en_3
            , g_cond_tmp_chk_rec.wholesale_margin_per_3
            , g_cond_tmp_chk_rec.wholesale_adj_margin_en_4
            , g_cond_tmp_chk_rec.wholesale_adj_margin_per_4
            , cn_created_by
            , cd_creation_date
            , cn_last_updated_by
            , cd_last_update_date
            , cn_last_update_login
            , cn_request_id
            , cn_program_application_id
            , cn_program_id
            , cd_program_update_date
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- �G���[���b�Z�[�W�̎擾
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10586
                         , iv_token_name1  => cv_table_name_tok
                         , iv_token_value1 => cv_msg_condition_l
                         , iv_token_name2  => cv_key_data_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- �w�b�_����WHO�J�������X�V
        UPDATE  xxcok_condition_header xch
        SET     xch.last_updated_by           =   cn_last_updated_by
              , xch.last_update_date          =   cd_last_update_date
              , xch.last_update_login         =   cn_last_update_login
              , xch.request_id                =   cn_request_id
              , xch.program_application_id    =   cn_program_application_id
              , xch.program_id                =   cn_program_id
              , xch.program_update_date       =   cd_program_update_date
        WHERE   xch.condition_no       = lt_condition_no
        ;
      END IF;
      --
    END LOOP  get_cond_tm_loop3;
    --
    --  ******************************************************
    --  �T���^�C�v�u050(��z���^��)�v�̍Čv�Z
    --  ******************************************************
    --  �䗦�i���j�A���z���i�~�j�A�����P���i���j���Čv�Z���T���ԍ����ƂɍČv�Z
    <<upd_005_loop>>
    FOR target_condition_rec IN target_condition_cur LOOP
      BEGIN
        SELECT  SUM(prediction_qty_5)     AS  prediction_qty_sum     -- �\�����ʍ��v
        INTO    ln_prediction_qty_sum
        FROM    xxcok_condition_lines   xcl
        WHERE   xcl.condition_no    =   target_condition_rec.condition_no
        AND     xcl.enabled_flag_l  =   cv_const_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --  �S���׍폜�̏ꍇ�̂�NO_DATA_FOUND�ɂȂ�
          CONTINUE  upd_005_loop;
      END;
      --
      <<get_cond_tm_loop4>>
      FOR get_cond_rec IN get_cond_cur(target_condition_rec.condition_no) LOOP
        -- �Čv�Z����
        lt_ratio_per  :=  (get_cond_rec.prediction_qty_5 / ln_prediction_qty_sum) * cn_100;    -- �䗦�i���j
        lt_amount_prorated_en :=  get_cond_rec.support_amount_sum_en_5 *  (lt_ratio_per / cn_100);     -- ���z���i�~�j
        lt_cond_unit_price_en :=  lt_amount_prorated_en / get_cond_rec.prediction_qty_5;    -- �����P���i�~�j
--
        -- �Čv�Z�����l�ōX�V
        UPDATE  xxcok_condition_lines xcl
        SET     xcl.ratio_per_5               = ROUND(lt_ratio_per, 2)
              , xcl.amount_prorated_en_5      = ROUND(lt_amount_prorated_en, 2)
              , xcl.condition_unit_price_en_5 = ROUND(lt_cond_unit_price_en, 2)
        WHERE   xcl.ROWID   =   get_cond_rec.row_id
        ;
      END LOOP get_cond_tm_loop4;
--
    END LOOP upd_005_loop;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END up_ins_process;
--
    /**********************************************************************************
   * Procedure Name   : condition_data
   * Description      : �T���}�X�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_process(
    ov_errbuf         OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2)                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_process'; -- �v���O������
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
    lv_condition_no               VARCHAR2(10);
    ln_counter                    NUMBER;
    ln_max_index                  NUMBER;
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
    -- ���[�J���ϐ�������
    lv_condition_no      :=  cv_space;
    ln_counter           :=  0;
    ln_max_index         :=  0;
--
    --  ************************************************
    --  �T���}�X�^�폜����
    --  ************************************************
--
    --  ���׍폜    TEMP�Ŗ��׍폜�ƂȂ��Ă���T���ԍ��A���הԍ��ƈ�v����T�����ׂ�S�Ė�����
    --      �܂��́ATEMP�Ńw�b�_�폜�ƂȂ��Ă���T���ԍ��ƈ�v����T�����ׂ�S�Ė�����
    UPDATE  xxcok_condition_lines     xcl
    SET     xcl.enabled_flag_l          =   cv_const_n
          , xcl.line_recovery_flag      =   cv_process_delete
          , xcl.last_updated_by         =   fnd_global.user_id
          , xcl.last_update_date        =   cd_last_update_date
          , xcl.last_update_login       =   cn_last_update_login
          , xcl.request_id              =   cn_request_id
          , xcl.program_application_id  =   cn_program_application_id
          , xcl.program_id              =   cn_program_id
          , xcl.program_update_date     =   cd_program_update_date
    WHERE ( EXISTS( SELECT  1     AS  dummy
                    FROM    xxcok_condition_temp    xct
                    WHERE   xct.condition_no        =   xcl.condition_no
                    AND     xct.detail_number       =   xcl.detail_number
                    AND     xct.request_id          =   cn_request_id
                    AND     xct.process_type_line   =   cv_process_delete
            )
          )
    ;
--
    --
    UPDATE  xxcok_condition_header    xch
    SET     xch.last_updated_by         =   fnd_global.user_id
          , xch.last_update_date        =   cd_last_update_date
          , xch.last_update_login       =   cn_last_update_login
          , xch.request_id              =   cn_request_id
          , xch.program_application_id  =   cn_program_application_id
          , xch.program_id              =   cn_program_id
          , xch.program_update_date     =   cd_program_update_date
    WHERE  EXISTS( SELECT  1     AS  dummy
                   FROM    xxcok_condition_lines    xcl
                          ,xxcok_condition_temp     xct
                   WHERE   xct.condition_no        =   xcl.condition_no
                   AND     xct.detail_number       =   xcl.detail_number
                   AND     xcl.condition_no        =   xch.condition_no
                   AND     xct.process_type_line   =   cv_process_delete
                  )
    ;
--
    --  �w�b�_�폜  TEMP�Ńw�b�_�폜�ƂȂ��Ă���T���ԍ��ƈ�v����T���w�b�_��S�Ė�����
    UPDATE  xxcok_condition_header    xch
    SET     xch.enabled_flag_h          =   cv_const_n
          , xch.header_recovery_flag    =   cv_process_delete
          , xch.last_updated_by         =   fnd_global.user_id
          , xch.last_update_date        =   cd_last_update_date
          , xch.last_update_login       =   cn_last_update_login
          , xch.request_id              =   cn_request_id
          , xch.program_application_id  =   cn_program_application_id
          , xch.program_id              =   cn_program_id
          , xch.program_update_date     =   cd_program_update_date
    WHERE  EXISTS( SELECT  1     AS  dummy
                   FROM    xxcok_condition_temp     xct
                   WHERE   xct.condition_no  =  xch.condition_no
                   AND     NOT EXISTS( SELECT  1     AS  dummy
                                       FROM    xxcok_condition_lines    xcl
                                       WHERE   xcl.condition_no   =   xct.condition_no
                                       AND     xcl.enabled_flag_l =   cv_const_y
                                       )
                   )
    ;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_process;
--
    /**********************************************************************************
   * Procedure Name   : condition_recovery
   * Description      : �T���f�[�^���J�o���R���J�����g���s����(A-10)
   ***********************************************************************************/
  PROCEDURE condition_recovery(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'condition_recovery'; -- �v���O������
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
    cv_recover_name     CONSTANT VARCHAR2(30) := '�T���f�[�^���J�o���R���J�����g';
--
    -- *** ���[�J���ϐ� ***
    lv_out_msg      VARCHAR2(1000);
    ln_request_id   NUMBER;
    lb_retcode      BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    submit_conc_expt EXCEPTION;
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
    -- ���[�J���ϐ�������
    lb_retcode := false;
--
    -- �u�T���f�[�^���J�o���v�R���J�����g���s
    ln_request_id := fnd_request.submit_request(
      application   => cv_msg_kbn_cok
     ,program       => cv_data_rec_conc -- �T���f�[�^���J�o���w��
     ,description   => NULL
     ,start_time    => NULL
     ,sub_request   => FALSE
     ,argument1     => cn_request_id    -- �v��ID
    );
    -- ����ȊO�̏ꍇ
    IF ( ln_request_id = 0 ) THEN
      RAISE submit_conc_expt;
    END IF;
--
    -- �R���J�����g���s���m�肳���邽�߃R�~�b�g
    COMMIT;
--
    -- �R���J�����g���s���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_cok_10677
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => ln_request_id
                    )
    );
    -- �R���J�����g���s���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_cok_10677
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => ln_request_id
                    )
    );
--
  EXCEPTION
--
    ----------------------------------------------------------
    -- �R���J�����g���s��O�n���h��
    ----------------------------------------------------------
    WHEN submit_conc_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_cok_10615
                    ,iv_token_name1  => cv_pg_name_tok
                    ,iv_token_value1 => cv_recover_name
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT
                      ,iv_message    => lv_out_msg       -- ���b�Z�[�W
                      ,in_new_line   => cn_one           -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END condition_recovery;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER     --   �t�@�C��ID
   ,iv_file_format  IN   VARCHAR2   --   �t�@�C���t�H�[�}�b�g
   ,ov_errbuf       OUT  VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT  VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT  VARCHAR2   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_chk_cnt           := 0; 
    gn_target_cnt        := 0; -- �Ώی���
    gn_normal_cnt        := 0; -- ���팏��
    gn_error_cnt         := 0; -- �G���[����
    gn_warn_cnt          := 0; -- �X�L�b�v����
    gn_skip_cnt          := 0; -- �X�L�b�v����
    gn_message_cnt       := 0; -- �ő僁�b�Z�[�W��
--
    -- ============================================
    -- A-1�D��������
    -- ============================================
    init(
        in_file_id        =>  in_file_id          --  �t�@�C��ID
      , iv_file_format    =>  iv_file_format      --  �t�@�C���t�H�[�}�b�g
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�DIF�f�[�^�擾
    -- ============================================
    get_if_data(
        in_file_id        =>  in_file_id          --  �t�@�C��ID
      , iv_file_format    =>  iv_file_format      --  �t�@�C���t�H�[�}�b�g
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_warn ) THEN
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�DIF�f�[�^�폜
    -- ============================================
    delete_if_data(
        in_file_id        =>  in_file_id          --  �t�@�C��ID
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4�D�A�b�v���[�h�t�@�C�����ڕ���(TMP�e�[�u���쐬)
    -- ============================================
    <<file_if_loop>>
    --�P�s�ڂ̓J�����s�ׁ̈A�Q�s�ڂ��珈������
    FOR ln_file_if_loop_cnt IN 2 .. gt_file_line_data_tab.COUNT LOOP
      divide_item(
          in_file_if_loop_cnt =>  ln_file_if_loop_cnt   --  I/F���[�v�J�E���^
        , ov_errbuf           =>  lv_errbuf             --  �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode          =>  lv_retcode            --  ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg           =>  lv_errmsg             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END LOOP file_if_loop;
--
-- 2021/04/06 Ver1.1 MOD Start
    IF gn_warn_cnt > 0 THEN
      RAISE global_api_warn_expt;
    END IF;
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      RAISE global_process_expt;
--    END IF;
-- 2021/04/06 Ver1.1 MOD End
--
    -- ============================================
    -- A-5�D�T���}�X�^�r�����䏈��
    -- ============================================
    exclusive_check(
        ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6�D�Ó����`�F�b�N
    -- ============================================
    validity_check(
        ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  (lv_retcode = cv_status_warn)  THEN
      ov_retcode := lv_retcode;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7.�T���}�X�^�폜
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      delete_process(
          ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ============================================
    --  A-8.�폜��`�F�b�N
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      up_ins_chk(
          ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
--
    IF (lv_retcode = cv_status_warn) THEN
      ROLLBACK;
--
      DELETE FROM xxcok_exclusive_ctl_info xeci
      WHERE  xeci.request_id = cn_request_id
      ;
--
      COMMIT;
      ov_retcode := lv_retcode;
    ELSIF lv_retcode <> cv_status_normal THEN
      ROLLBACK;
--
      DELETE FROM xxcok_exclusive_ctl_info xeci
      WHERE  xeci.request_id = cn_request_id
      ;
--
      COMMIT;
--
      RAISE global_process_expt;
    END IF;
    -- ============================================
    --  A-9.�T���}�X�^�o�^�E�X�V����
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      up_ins_process(
          ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF lv_retcode <> cv_status_normal THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ============================================
    -- A-10�D�T���f�[�^���J�o���R���J�����g���s����
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      COMMIT;   --  �T���}�X�^�̕ύX���m��
      --
      condition_recovery(
          ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF lv_retcode <> cv_status_normal THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- ============================================
    -- �`�F�b�N���ʂ̃��b�Z�[�W�o��
    -- ============================================
    IF ( gv_check_result = 'N' ) THEN
      --  �`�F�b�N�G���[���������Ă���ꍇ�A���b�Z�[�W���o�͂��āAROLLBACK
      FOR cnv_no IN 2 .. gt_file_line_data_tab.COUNT LOOP
        --  �Y��CSV�s�ԍ��Ƀ��b�Z�[�W���ݒ肳��Ă���ꍇ
        IF ( g_message_list_tab.EXISTS( cnv_no ) ) THEN
          --  ���b�Z�[�W�w�b�_�[  �T���}�X�^CSV������
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cok
                        , iv_name         => cv_msg_cok_10596
                        , iv_token_name1  => cv_line_num_tok
                        , iv_token_value1 => TO_CHAR(cnv_no)
                       )
          );
          FOR column_no IN 1 .. gn_message_cnt LOOP
            IF ( g_message_list_tab( cnv_no ).EXISTS( column_no ) ) THEN
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => g_message_list_tab( cnv_no )( column_no )
              );
            END IF;
          END LOOP;
        END IF;
      END LOOP;
      --
      ROLLBACK;
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
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( g_cond_tmp_cur%ISOPEN ) THEN
        CLOSE g_cond_tmp_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( g_cond_tmp_cur%ISOPEN ) THEN
        CLOSE g_cond_tmp_cur;
      END IF;
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
    errbuf           OUT   VARCHAR2 --   �G���[���b�Z�[�W #�Œ�#
   ,retcode          OUT   VARCHAR2 --   �G���[�R�[�h     #�Œ�#
   ,iv_file_id       IN    VARCHAR2 --   1.�t�@�C��ID(�K�{)
   ,iv_file_format   IN    VARCHAR2 --   2.�t�@�C���t�H�[�}�b�g(�K�{)
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  :=  'main';             -- �v���O������
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)   :=  'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg   CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg  CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg    CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg     CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_const_normal_msg CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg         CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg        CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token        CONSTANT VARCHAR2(10)   :=  'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
      ov_retcode  =>  lv_retcode
     ,ov_errbuf   =>  lv_errbuf
     ,ov_errmsg   =>  lv_errmsg
     ,iv_which    =>  cv_file_type_out
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
       TO_NUMBER(iv_file_id)  -- 1.�t�@�C��ID
      ,iv_file_format         -- 2.�t�@�C���t�H�[�}�b�g
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (  lv_retcode = cv_status_normal
       OR lv_retcode = cv_status_warn 
       OR lv_retcode = cv_status_error ) THEN
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
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ����I���ȊO�̏ꍇ�A���[���o�b�N�𔭍s
      ROLLBACK;
    END IF;
--
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================
    -- �G���[���̏o�͌����ݒ�
    -- ===============================================
    -- �z����G���[�̏ꍇ
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_target_cnt  - gn_skip_cnt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      gn_normal_cnt := 0; -- ��������
    -- �z��O�G���[�̏ꍇ
    ELSIF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0; -- �Ώی���
      gn_normal_cnt := 0; -- ��������
      gn_error_cnt  := 1; -- �G���[����
      gn_warn_cnt   := 0; -- �x������
      gn_normal_cnt := 0; -- �X�L�b�v����
    END IF;
--
    -- ===============================================================
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_ccp_90000
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
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_ccp_00001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
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
      lv_message_code := cv_const_normal_msg;
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
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOK024A01C;
/
