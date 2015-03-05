CREATE OR REPLACE PACKAGE BODY APPS.XXCOI016A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A08C(body)
 * Description      : �����������A�b�v���[�h
 * MD.050           : �����������A�b�v���[�h MD050_COI_016_A08
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                              (A-1)
 *  get_if_data                  IF�f�[�^�擾                          (A-2)
 *  delete_if_data               IF�f�[�^�폜                          (A-3)
 *  divide_item                  �A�b�v���[�h�t�@�C�����ڕ���          (A-4)
 *  ins_upload_wk                �����������A�b�v���[�h�ꎞ�\�o�^    (A-5)
 *  get_upload_wk                �����������A�b�v���[�h�ꎞ�\�擾    (A-6)
 *  check_item_value             �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N          (A-7)
 *  get_reserve_info             �����O���擾                        (A-8)
 *  del_reserve_info             �������폜                          (A-9)
 *  check_item_changes           ���ڕύX�`�F�b�N                      (A-10)
 *  check_code_value             �e��R�[�h�l�`�F�b�N                  (A-11)
 *  check_item_validation        ���ڊ֘A�`�F�b�N                      (A-12)
 *  check_cese_singly_qty        �P�[�X���A�o�����`�F�b�N              (A-13)
 *  chack_reserve_availablity    �����\�`�F�b�N                      (A-14)
 *  get_user_info                ���s�ҏ��擾                        (A-15)
 *  ins_reserve_info             �������o�^                          (A-16)
 *  check_reserve_qty            �������ύX�`�F�b�N                    (A-17)
 *
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/12/10    1.0   S.Yamashita      �V�K�쐬
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI016A08C'; -- �p�b�P�[�W��
--
  cv_csv_delimiter      CONSTANT VARCHAR2(1) := ',';   -- �J���}
  cv_colon              CONSTANT VARCHAR2(2) := '�F';  -- �R����
  cv_space              CONSTANT VARCHAR2(2) := ' ';   -- ���p�X�y�[�X
  cv_const_y            CONSTANT VARCHAR2(1) := 'Y';   -- 'Y'
  cv_const_n            CONSTANT VARCHAR2(1) := 'N';   -- 'N'
  cv_shipping_status_20 CONSTANT VARCHAR2(2) := '20';  -- �o�׏��X�e�[�^�X�F'20'�i�����ρj
  cv_cust_class_code_10 CONSTANT VARCHAR2(2) := '10';  -- �ڋq�敪�F'10'�i�ڋq�j
  cv_cust_class_code_12 CONSTANT VARCHAR2(2) := '12';  -- �ڋq�敪�F'12'�i��l�ڋq�j
  cv_cust_class_code_18 CONSTANT VARCHAR2(2) := '18';  -- �ڋq�敪�F'18'�i�`�F�[���X�j
  cv_char_a             CONSTANT VARCHAR2(1) := 'A';   -- �����F'A'
  cv_tran_type_code_170 CONSTANT VARCHAR2(3) := '170'; -- ����������^�C�v�R�[�h�F'170'
  cv_tran_type_code_320 CONSTANT VARCHAR2(3) := '320'; -- ����������^�C�v�R�[�h�F'320'
  cv_tran_type_code_340 CONSTANT VARCHAR2(3) := '340'; -- ����������^�C�v�R�[�h�F'340'
  cv_tran_type_code_360 CONSTANT VARCHAR2(3) := '360'; -- ����������^�C�v�R�[�h�F'360'
--
  cv_regular_sale_class_line_01 CONSTANT VARCHAR2(2) := '01'; -- ��ԓ����敪�F01
  cv_regular_sale_class_line_02 CONSTANT VARCHAR2(2) := '02'; -- ��ԓ����敪�F02
--
  cv_sale_class_1               CONSTANT VARCHAR2(1) := '1'; -- �ʏ�
  cv_sale_class_2               CONSTANT VARCHAR2(1) := '2'; -- ����
  cv_sale_class_3               CONSTANT VARCHAR2(1) := '3'; -- �x���_����
  cv_sale_class_4               CONSTANT VARCHAR2(1) := '4'; -- �����EVD����
  cv_sale_class_5               CONSTANT VARCHAR2(1) := '5'; -- ���^
  cv_sale_class_6               CONSTANT VARCHAR2(1) := '6'; -- ���{
  cv_sale_class_7               CONSTANT VARCHAR2(1) := '7'; -- �L����`��
  cv_sale_class_9               CONSTANT VARCHAR2(1) := '9'; -- ��U���i�̔̔�
--
  cv_lot_tran_kbn_0             CONSTANT VARCHAR2(1) := '0'; -- ���b�g�ʎ�����ז��쐬
--
  cn_c_slip_num                CONSTANT NUMBER  := 1;  -- �`�[No
  cn_c_order_number            CONSTANT NUMBER  := 2;  -- �󒍔ԍ�
  cn_c_parent_shipping_status  CONSTANT NUMBER  := 3;  -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
  cn_c_base_code               CONSTANT NUMBER  := 5;  -- ���_�R�[�h
  cn_c_whse_code               CONSTANT NUMBER  := 7;  -- �ۊǏꏊ�R�[�h
  cn_c_location_code           CONSTANT NUMBER  := 9;  -- ���P�[�V�����R�[�h
  cn_c_shipping_status         CONSTANT NUMBER  := 11; -- �o�׏��X�e�[�^�X
  cn_c_chain_code              CONSTANT NUMBER  := 13; -- �`�F�[���X�R�[�h
  cn_c_shop_code               CONSTANT NUMBER  := 15; -- �X�܃R�[�h
  cn_c_shop_name               CONSTANT NUMBER  := 16; -- �X�ܖ�
  cn_c_customer_code           CONSTANT NUMBER  := 17; -- �ڋq�R�[�h
  cn_c_customer_name           CONSTANT NUMBER  := 18; -- �ڋq��
  cn_c_center_code             CONSTANT NUMBER  := 19; -- �Z���^�[�R�[�h
  cn_c_center_name             CONSTANT NUMBER  := 20; -- �Z���^�[��
  cn_c_area_code               CONSTANT NUMBER  := 21; -- �n��R�[�h
  cn_c_area_name               CONSTANT NUMBER  := 22; -- �n�於��
  cn_c_shipped_date            CONSTANT NUMBER  := 23; -- �o�ד�
  cn_c_arrival_date            CONSTANT NUMBER  := 24; -- ����
  cn_c_item_div                CONSTANT NUMBER  := 25; -- ���i�敪
  cn_c_parent_item_code        CONSTANT NUMBER  := 27; -- �e�i�ڃR�[�h
  cn_c_item_code               CONSTANT NUMBER  := 29; -- �q�i�ڃR�[�h
  cn_c_lot                     CONSTANT NUMBER  := 31; -- �ܖ�����
  cn_c_difference_summary_code CONSTANT NUMBER  := 32; -- �ŗL�L��
  cn_c_case_in_qty             CONSTANT NUMBER  := 33; -- ����
  cn_c_case_qty                CONSTANT NUMBER  := 34; -- �P�[�X��
  cn_c_singly_qty              CONSTANT NUMBER  := 35; -- �o����
  cn_c_summary_qty             CONSTANT NUMBER  := 36; -- ����
  cn_c_ordered_quantity        CONSTANT NUMBER  := 37; -- �󒍐���
  cn_c_regular_sale_class_line CONSTANT NUMBER  := 38; -- ��ԓ����敪
  cn_c_edi_received_date       CONSTANT NUMBER  := 40; -- EDI��M��
  cn_c_delivery_order_edi      CONSTANT NUMBER  := 41; -- �z����(EDI)
  cn_c_header                  CONSTANT NUMBER  := 41; -- CSV�t�@�C�����ڐ��i�擾�Ώہj
  cn_c_header_all              CONSTANT NUMBER  := 43; -- CSV�t�@�C�����ڐ��i�S���ځj
--
  -- �o�̓^�C�v
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';      --�o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';         --���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- �����}�X�N
  cv_date_format        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- ���t����
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI'; --�A�h�I���F�݌ɗ̈�
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)   := 'XXCOS'; --�A�h�I���F�̔��̈�
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP'; --���ʂ̃��b�Z�[�W
--
  -- �v���t�@�C��
  cv_inv_org_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- �݌ɑg�D�R�[�h
  cv_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                   -- �c�ƒP��
  cv_lot_reverse_mark   CONSTANT VARCHAR2(30)  := 'XXCOI1_LOT_REVERSE_MARK';  -- XXCOI:���b�g�t�]�L��
--
  -- �Q�ƃ^�C�v
  cv_type_upload_obj    CONSTANT VARCHAR2(30)  :='XXCCP1_FILE_UPLOAD_OBJ'; -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_type_bargain_class CONSTANT VARCHAR2(30)  :='XXCOS1_BARGAIN_CLASS';   -- ��ԓ����敪
--
  -- ����R�[�h
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ���b�Z�[�W��
  cv_msg_ccp_90000      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_msg_ccp_90002      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_msg_ccp_90003      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
--
  cv_msg_coi_00005      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';  -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_coi_00006      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_coi_00011      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';  -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_coi_00028      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';  -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_coi_00032      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00032';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_coi_10232      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10232';  -- �R���J�����g���̓p�����[�^
  cv_msg_coi_10541      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10541';  -- ���b�N�ΏەۊǏꏊ���݃G���[���b�Z�[�W
  cv_msg_coi_10543      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10543';  -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[���b�Z�[�W
  cv_msg_coi_10568      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10568';  -- �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[�G���[���b�Z�[�W
  cv_msg_coi_10570      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10570';  -- ���ڕύX�`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10571      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10571';  -- �e��R�[�h�l�`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10572      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10572';  -- ���t�`���`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10573      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10573';  -- �������`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10574      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10574';  -- �o�׏��X�e�[�^�X�G���[���b�Z�[�W
  cv_msg_coi_10575      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10575';  -- ���b�g�t�]�`�F�b�N�x�����b�Z�[�W
  cv_msg_coi_10576      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10576';  -- �i�ڃR�[�h���o�G���[���b�Z�[�W
  cv_msg_coi_10577      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10577';  -- ���i�敪�A�e�i�ځA�q�i�ڊ֘A�`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10578      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10578';  -- �P�[�X���A�o�����`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10579      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10579';  -- �����\�`�F�b�N�G���[
  cv_msg_coi_10580      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10580';  -- �������ύX�`�F�b�N�G���[
  cv_msg_coi_10593      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10593';  -- �����\���Z�o�G���[���b�Z�[�W���b�Z�[�W
  cv_msg_coi_10594      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10594';  -- ���_�A�ڋq�֘A�`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10595      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10595';  -- �`�F�[���X�A�ڋq�֘A�`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10611      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10611';  -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
  cv_msg_coi_10629      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10629';  -- ������
  cv_msg_coi_10633      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10633';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_coi_10635      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10635';  -- �f�[�^���o�G���[���b�Z�[�W
--
  cv_msg_cos_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ���b�N�G���[���b�Z�[�W
  cv_msg_cos_00013      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_cos_11293      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11293';  -- �t�@�C���A�b�v���[�h���̎擾�G���[
  cv_msg_cos_11294      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11294';  -- CSV�t�@�C�����擾�G���[
  cv_msg_cos_11295      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';  -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
--
  -- ���b�Z�[�W��(�g�[�N��)
  cv_tkn_coi_10496      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10496';  -- �e�i�ڃR�[�h
  cv_tkn_coi_10502      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10502';  -- ���_�R�[�h
  cv_tkn_coi_10503      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10503';  -- �ۊǏꏊ�R�[�h
  cv_tkn_coi_10581      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10581';  -- ���P�[�V�����R�[�h
  cv_tkn_coi_10612      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10612';  -- �s�ԍ�
  cv_tkn_coi_10613      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10613';  -- �󒍔ԍ�
  cv_tkn_coi_10614      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10614';  -- �e�i��
  cv_tkn_coi_10499      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10499';  -- �`�[No
  cv_tkn_coi_10615      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10615';  -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
  cv_tkn_coi_10616      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10616';  -- �o�׏��X�e�[�^�X
  cv_tkn_coi_10617      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10617';  -- �`�F�[���X�R�[�h
  cv_tkn_coi_10618      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10618';  -- �X�܃R�[�h
  cv_tkn_coi_10619      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10619';  -- �ڋq�R�[�h
  cv_tkn_coi_10620      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10620';  -- �Z���^�[�R�[�h
  cv_tkn_coi_10621      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10621';  -- �n��R�[�h
  cv_tkn_coi_10622      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10622';  -- �o�ד�
  cv_tkn_coi_10623      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10623';  -- ����
  cv_tkn_coi_10624      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10624';  -- ���i�敪
  cv_tkn_coi_10625      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10625';  -- ��ԓ����敪
  cv_tkn_coi_10626      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10626';  -- EDI��M��
  cv_tkn_coi_10627      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10627';  -- �z����(EDI)
  cv_tkn_coi_10628      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10628';  -- �q�i�ڃR�[�h
  cv_tkn_coi_10632      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10632';  -- �����������A�b�v���[�h�ꎞ�\
  cv_tkn_coi_10634      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10634';  -- �t�@�C���A�b�v���[�hIF
  cv_tkn_coi_10636      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10636';  -- ���b�g���ێ��}�X�^
--
  cv_tkn_cos_11282      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11282';  -- �t�@�C���A�b�v���[�hIF
--
  -- �g�[�N����
  cv_tkn_pro_tok        CONSTANT VARCHAR2(100) := 'PRO_TOK';         -- �v���t�@�C����
  cv_tkn_org_code_tok   CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';    -- �݌ɑg�D�R�[�h
  cv_tkn_file_id        CONSTANT VARCHAR2(100) := 'FILE_ID';         -- �t�@�C��ID
  cv_tkn_file_name      CONSTANT VARCHAR2(100) := 'FILE_NAME';       -- �t�@�C����
  cv_tkn_file_upld_name CONSTANT VARCHAR2(100) := 'FILE_UPLD_NAME';  -- �t�@�C���A�b�v���[�h����
  cv_tkn_format_ptn     CONSTANT VARCHAR2(100) := 'FORMAT_PTN';      -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_base_code      CONSTANT VARCHAR2(100) := 'BASE_CODE';       -- ���_�R�[�h
  cv_tkn_key_data       CONSTANT VARCHAR2(100) := 'KEY_DATA';        -- �L�[�f�[�^
  cv_tkn_table          CONSTANT VARCHAR2(100) := 'TABLE';           -- �e�[�u����
  cv_tkn_table_name     CONSTANT VARCHAR2(100) := 'TABLE_NAME';      -- �e�[�u����
  cv_tkn_item_name      CONSTANT VARCHAR2(100) := 'ITEM_NAME';       -- ���ږ�
  cv_tkn_err_msg        CONSTANT VARCHAR2(100) := 'ERR_MSG';         -- �G���[���b�Z�[�W
  cv_tkn_data           CONSTANT VARCHAR2(100) := 'DATA';            -- �f�[�^
--
  -- �_�~�[�l
  cv_dummy_char         CONSTANT VARCHAR2(100) := 'DUMMY99999999';   -- ������p�_�~�[�l
  cd_dummy_date         CONSTANT DATE          := TO_DATE( '1900/01/01', 'YYYY/MM/DD' );
                                                                     -- ���t�p�_�~�[�l
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �������ڕ�����f�[�^�i�[�p
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER; -- 1�����z��
  g_if_data_tab             g_var_data_ttype;                                   -- �����p�ϐ�
--
  -- �����������f�[�^�i�[�p
  TYPE g_upload_data_rtype IS RECORD(
    slip_num                xxcoi_tmp_lot_resv_info_upld.slip_num%TYPE,                -- �`�[No
    row_number              xxcoi_tmp_lot_resv_info_upld.row_number%TYPE,              -- �s�ԍ�
    order_number            xxcoi_tmp_lot_resv_info_upld.order_number%TYPE,            -- �󒍔ԍ�
    parent_shipping_status  xxcoi_tmp_lot_resv_info_upld.parent_shipping_status%TYPE,  -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
    base_code               xxcoi_tmp_lot_resv_info_upld.base_code%TYPE,               -- ���_�R�[�h
    whse_code               xxcoi_tmp_lot_resv_info_upld.whse_code%TYPE,               -- �ۊǏꏊ�R�[�h
    location_code           xxcoi_tmp_lot_resv_info_upld.location_code%TYPE,           -- ���P�[�V�����R�[�h
    shipping_status         xxcoi_tmp_lot_resv_info_upld.shipping_status%TYPE,         -- �o�׏��X�e�[�^�X
    chain_code              xxcoi_tmp_lot_resv_info_upld.chain_code%TYPE,              -- �`�F�[���X�R�[�h
    shop_code               xxcoi_tmp_lot_resv_info_upld.shop_code%TYPE,               -- �X�܃R�[�h
    shop_name               xxcoi_tmp_lot_resv_info_upld.shop_name%TYPE,               -- �X�ܖ�
    customer_code           xxcoi_tmp_lot_resv_info_upld.customer_code%TYPE,           -- �ڋq�R�[�h
    customer_name           xxcoi_tmp_lot_resv_info_upld.customer_name%TYPE,           -- �ڋq��
    center_code             xxcoi_tmp_lot_resv_info_upld.center_code%TYPE,             -- �Z���^�[�R�[�h
    center_name             xxcoi_tmp_lot_resv_info_upld.center_name%TYPE,             -- �Z���^�[��
    area_code               xxcoi_tmp_lot_resv_info_upld.area_code%TYPE,               -- �n��R�[�h
    area_name               xxcoi_tmp_lot_resv_info_upld.area_name%TYPE,               -- �n�於��
    shipped_date            xxcoi_tmp_lot_resv_info_upld.shipped_date%TYPE,            -- �o�ד�
    arrival_date            xxcoi_tmp_lot_resv_info_upld.arrival_date%TYPE,            -- ����
    item_div                xxcoi_tmp_lot_resv_info_upld.item_div%TYPE,                -- ���i�敪
    parent_item_code        xxcoi_tmp_lot_resv_info_upld.parent_item_code%TYPE,        -- �e�i�ڃR�[�h
    item_code               xxcoi_tmp_lot_resv_info_upld.item_code%TYPE,               -- �q�i�ڃR�[�h
    lot                     xxcoi_tmp_lot_resv_info_upld.lot%TYPE,                     -- ���b�g�i�ܖ������j
    difference_summary_code xxcoi_tmp_lot_resv_info_upld.difference_summary_code%TYPE, -- �ŗL�L��
    case_in_qty             xxcoi_tmp_lot_resv_info_upld.case_in_qty%TYPE,             -- ����
    case_qty                xxcoi_tmp_lot_resv_info_upld.case_qty%TYPE,                -- �P�[�X��
    singly_qty              xxcoi_tmp_lot_resv_info_upld.singly_qty%TYPE,              -- �o����
    summary_qty             xxcoi_tmp_lot_resv_info_upld.summary_qty%TYPE,             -- ����
    ordered_quantity        xxcoi_tmp_lot_resv_info_upld.ordered_quantity%TYPE,        -- �󒍐���
    regular_sale_class_line xxcoi_tmp_lot_resv_info_upld.regular_sale_class_line%TYPE, -- ��ԓ����敪
    edi_received_date       xxcoi_tmp_lot_resv_info_upld.edi_received_date%TYPE,       -- EDI��M��
    delivery_order_edi      xxcoi_tmp_lot_resv_info_upld.delivery_order_edi%TYPE,      -- �z����(EDI)
    mark                    xxcoi_lot_reserve_info.mark%TYPE                           -- �L��
    );
  -- �����������f�[�^���R�[�h�z��
  TYPE g_upload_data_ttype IS TABLE OF g_upload_data_rtype INDEX BY BINARY_INTEGER;
--
-- ���b�g�ʈ������i�[�p
  TYPE g_reserve_info_rtype IS RECORD(
    slip_num                      xxcoi_lot_reserve_info.slip_num%TYPE,                      -- �`�[No
    parent_shipping_status        xxcoi_lot_reserve_info.parent_shipping_status%TYPE,        -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
    parent_shipping_status_name   xxcoi_lot_reserve_info.parent_shipping_status_name%TYPE,   -- �o�׏��X�e�[�^�X��(�󒍔ԍ��P��)
    shipping_status               xxcoi_lot_reserve_info.shipping_status%TYPE,               -- �o�׏��X�e�[�^�X
    shipping_status_name          xxcoi_lot_reserve_info.shipping_status_name%TYPE,          -- �o�׏��X�e�[�^�X��
    chain_code                    xxcoi_lot_reserve_info.chain_code%TYPE,                    -- �`�F�[���X�R�[�h
    chain_name                    xxcoi_lot_reserve_info.chain_name%TYPE,                    -- �`�F�[���X��
    shop_code                     xxcoi_lot_reserve_info.shop_code%TYPE,                     -- �X�܃R�[�h
    shop_name                     xxcoi_lot_reserve_info.shop_name%TYPE,                     -- �X�ܖ�
    customer_code                 xxcoi_lot_reserve_info.customer_code%TYPE,                 -- �ڋq�R�[�h
    customer_name                 xxcoi_lot_reserve_info.customer_name%TYPE,                 -- �ڋq��
    center_code                   xxcoi_lot_reserve_info.center_code%TYPE,                   -- �Z���^�[�R�[�h
    center_name                   xxcoi_lot_reserve_info.center_name%TYPE,                   -- �Z���^�[��
    area_code                     xxcoi_lot_reserve_info.area_code%TYPE,                     -- �n��R�[�h
    area_name                     xxcoi_lot_reserve_info.area_name%TYPE,                     -- �n�於��
    shipped_date                  xxcoi_lot_reserve_info.shipped_date%TYPE,                  -- �o�ד�
    arrival_date                  xxcoi_lot_reserve_info.arrival_date%TYPE,                  -- ����
    item_div                      xxcoi_lot_reserve_info.item_div%TYPE,                      -- ���i�敪
    item_div_name                 xxcoi_lot_reserve_info.item_div_name%TYPE,                 -- ���i�敪��
    regular_sale_class_line       xxcoi_lot_reserve_info.regular_sale_class_line%TYPE,       -- ��ԓ����敪
    regular_sale_class_name_line  xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE,  -- ��ԓ����敪��
    edi_received_date             xxcoi_lot_reserve_info.edi_received_date%TYPE,             -- EDI��M��
    delivery_order_edi            xxcoi_lot_reserve_info.delivery_order_edi%TYPE,            -- �z����(EDI)
    mark                          xxcoi_lot_reserve_info.mark%TYPE,                          -- �L��
    header_id                     xxcoi_lot_reserve_info.header_id%TYPE,                     -- �󒍃w�b�_ID
    line_id                       xxcoi_lot_reserve_info.line_id%TYPE,                       -- �󒍖���ID
    customer_id                   xxcoi_lot_reserve_info.customer_id%TYPE,                   -- �ڋqID
    parent_item_id                xxcoi_lot_reserve_info.parent_item_id%TYPE,                -- �e�i��ID
    parent_item_name              xxcoi_lot_reserve_info.parent_item_name%TYPE,              -- �e�i�ږ���
    reserve_transaction_type_code xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE, -- ����������^�C�v�R�[�h
    order_quantity_uom            xxcoi_lot_reserve_info.order_quantity_uom%TYPE             -- �󒍒P��
    );
  -- ���b�g�ʈ������f�[�^���R�[�h�z��
  TYPE g_reserve_info_ttype IS TABLE OF g_reserve_info_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_inv_org_code         VARCHAR2(100); -- �݌ɑg�D�R�[�h
  gn_inv_org_id           NUMBER;        -- �݌ɑg�DID
  gn_org_id               NUMBER;        -- �c�ƒP��
  gn_same_key_count       NUMBER;        -- ����L�[�̃��[�v��
  gn_del_count            NUMBER;        -- ����L�[�̍폜����
  gd_process_date         DATE;          -- �Ɩ����t
  gb_update_flag          BOOLEAN;       -- �X�V�t���O
  gb_header_err_flag      BOOLEAN;       -- �w�b�_�G���[�t���O
  gb_line_err_flag        BOOLEAN;       -- ���׃G���[�t���O
  gb_get_info_err_flag    BOOLEAN;       -- �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[�t���O
  gb_err_flag             BOOLEAN;       -- �z����G���[�t���O
  gv_shipping_status_name VARCHAR2(10);  -- �o�׏��X�e�[�^�X���F'������'
  gv_key_data             VARCHAR2(200); -- �L�[���
  gv_mark                 VARCHAR2(10);  -- ���b�g�t�]�L��
--
  -- ���b�g�ʈ������i�������j�i�[�p
  gn_sum_before_ordered_quantity NUMBER; -- �����O�󒍐��ʍ��v
  gn_sum_ordered_quantity        NUMBER; -- �󒍐��ʍ��v
  gn_sum_before_case_qty         NUMBER; -- �����O�P�[�X��
  gn_sum_before_singly_qty       NUMBER; -- �����O�o����
  gn_sum_before_summary_qty      NUMBER; -- �����O����
--
  -- �W�v�p�ϐ�
  gn_sum_case_qty                NUMBER; -- �P�[�X���W�v�p�ϐ�
  gn_sum_singly_qty              NUMBER; -- �o�����W�v�p�ϐ�
  gn_sum_summary_qty             NUMBER; -- ���ʏW�v�p�ϐ�
--
  -- �������o�^�p
  gt_base_name               xxcos_login_base_info_v.base_name%TYPE;                    -- ���_��
  gt_subinv_name             mtl_secondary_inventories.description%TYPE;                -- �ۊǏꏊ��
  gt_location_name           xxcoi_mst_warehouse_location.location_name%TYPE;           -- ���P�[�V��������
  gt_chain_name              hz_parties.party_name%TYPE;                                -- �`�F�[���X��
  gt_account_name            hz_cust_accounts.account_name%TYPE;                        -- �ڋq��
  gt_customer_id             hz_cust_accounts.cust_account_id%TYPE;                     -- �ڋqID
  gt_delivery_base_code      xxcmm_cust_accounts.delivery_base_code%TYPE;               -- ���_�R�[�h
  gt_chain_store_code        xxcmm_cust_accounts.chain_store_code%TYPE;                 -- �`�F�[���X�R�[�h
  gt_store_code              xxcmm_cust_accounts.store_code%TYPE;                       -- �X�܃R�[�h
  gt_cust_store_name         xxcmm_cust_accounts.cust_store_name%TYPE;                  -- �X�ܖ���
  gt_deli_center_code        xxcmm_cust_accounts.deli_center_code%TYPE;                 -- �Z���^�[�R�[�h
  gt_deli_center_name        xxcmm_cust_accounts.deli_center_name%TYPE;                 -- �Z���^�[��
  gt_edi_district_code       xxcmm_cust_accounts.edi_district_code%TYPE;                -- �n��R�[�h
  gt_edi_district_name       xxcmm_cust_accounts.edi_district_name%TYPE;                -- �n�於
  gt_delivery_order          xxcmm_cust_accounts.delivery_order%TYPE;                   -- �z�����iEDI)
  gt_shipped_date            xxcoi_lot_reserve_info.shipped_date%TYPE;                  -- �o�ד�
  gt_parent_item_name        xxcmn_item_mst_b.item_short_name%TYPE;                     -- �e�i�ږ���
  gt_parent_item_id          mtl_system_items_b.inventory_item_id%TYPE;                 -- �e�i��ID
  gt_child_item_name         xxcmn_item_mst_b.item_short_name%TYPE;                     -- �q�i�ږ���
  gt_child_item_id           mtl_system_items_b.inventory_item_id%TYPE;                 -- �q�i��ID
  gt_last_deliver_lot_e      xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE;           -- �[�i���b�g�i�c�Ɓj
  gt_delivery_date_e         xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;              -- �[�i���i�c�Ɓj
  gt_last_deliver_lot_s      xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE;           -- �[�i���b�g�i���Y�j
  gt_delivery_date_s         xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;              -- �[�i���i���Y�j
  gt_user_name               fnd_user.user_name%TYPE;                                   -- ���[�U��
  gt_per_information18       per_all_people_f.per_information18%TYPE;                   -- ��������(�]�ƈ����18)
  gt_per_information19       per_all_people_f.per_information19%TYPE;                   -- ��������(�]�ƈ����19)
  gt_item_div_name           mtl_categories_vl.description%TYPE;                        -- ���i�敪��
  gt_regular_sale_class_name xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE;  -- ��ԓ����敪��
  gt_resv_tran_type_code     xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE; -- ����������^�C�v�R�[�h
--
  -- �t�@�C���A�b�v���[�hIF�f�[�^
  gt_file_line_data_tab      xxccp_common_pkg2.g_file_data_tbl;
  -- �����������f�[�^�i�[�z��
  g_upload_data_tab          g_upload_data_ttype;
  -- ���b�g�ʈ������f�[�^�i�[�z��
  g_reserve_info_tab         g_reserve_info_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER,       --   �t�@�C��ID
    iv_file_format IN  VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_dummy                NUMBER; -- �_�~�[�l
    ln_ins_lock_cnt         NUMBER; -- ���b�N����e�[�u���}������
--
    -- ���b�N�ΏەۊǏꏊ�i�[�p���R�[�h�^
    TYPE l_subinv_rtype IS RECORD(
      base_code            mtl_secondary_inventories.attribute7%TYPE,  -- ���_�R�[�h
      subinventory_code    mtl_secondary_inventories.secondary_inventory_name%TYPE -- �ۊǏꏊ�R�[�h
    );
    -- ���b�N�ΏەۊǏꏊ�i�[�p���R�[�h�z��
    TYPE l_subinv_ttype IS TABLE OF l_subinv_rtype INDEX BY BINARY_INTEGER;
    -- ���b�N�ΏەۊǏꏊ�i�[�p�e�[�u���^
    l_subinv_tab           l_subinv_ttype;
    -- ���b�N����e�[�u���o�^�p�e�[�u���^
    l_ins_lock_tab         l_subinv_ttype;
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
    ln_dummy        := 0;     -- �_�~�[�l
    ln_ins_lock_cnt := 0;     -- ���b�N����e�[�u���o�^����
--
    -- �݌ɑg�D�R�[�h�̎擾
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00005, -- �݌ɑg�D�R�[�h�擾�G���[
                     iv_token_name1   => cv_tkn_pro_tok,
                     iv_token_value1  => cv_inv_org_code  -- �v���t�@�C���F�݌ɑg�D�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �݌ɑg�DID�̎擾
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => gv_inv_org_code
                     );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi,
                     iv_name         => cv_msg_coi_00006, -- �݌ɑg�DID�擾�G���[
                     iv_token_name1  => cv_tkn_org_code_tok,
                     iv_token_value1 => gv_inv_org_code -- �݌ɑg�D�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �c�ƒP�ʂ̎擾
    gn_org_id := FND_PROFILE.VALUE( cv_org_id );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00032, -- �v���t�@�C���擾�G���[
                     iv_token_name1   => cv_tkn_pro_tok,
                     iv_token_value1  => cv_org_id  -- �c�ƒP��
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ɩ����t�擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�ł��Ȃ��ꍇ
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00011 -- �Ɩ����t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g���̓p�����[�^�o��(���O)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi,
                 iv_name          => cv_msg_coi_10232, -- �R���J�����g���̓p�����[�^
                 iv_token_name1   => cv_tkn_file_id,
                 iv_token_value1  => TO_CHAR(in_file_id), -- �t�@�C��ID
                 iv_token_name2   => cv_tkn_format_ptn,
                 iv_token_value2  => iv_file_format -- �t�H�[�}�b�g�p�^�[��
               )
    );
--
    -- �R���J�����g���̓p�����[�^�o��(�o��)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi,
                 iv_name          => cv_msg_coi_10232, -- �R���J�����g���̓p�����[�^
                 iv_token_name1   => cv_tkn_file_id,
                 iv_token_value1  => TO_CHAR(in_file_id), -- �t�@�C��ID
                 iv_token_name2   => cv_tkn_format_ptn,
                 iv_token_value2  => iv_file_format -- �t�H�[�}�b�g�p�^�[��
                )
    );
    -- ��s���o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- ��s���o�́i�o�́j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    -- ���_�ɕR�t���ۊǏꏊ���擾
    SELECT  msi.attribute7               AS base_code         -- ���_�R�[�h
           ,msi.secondary_inventory_name AS subinventory_code -- �ۊǏꏊ�R�[�h
    BULK COLLECT INTO l_subinv_tab  -- �ۊǏꏊ�i�e�[�u���^�j
      FROM  mtl_secondary_inventories msi -- �ۊǏꏊ�}�X�^
     WHERE  msi.attribute14     = cv_const_y       -- �q�ɊǗ��Ώۋ敪
       AND  NVL(msi.disable_date, gd_process_date + 1) > gd_process_date -- ������
       AND  msi.organization_id = gn_inv_org_id    -- �݌ɑg�DID
       AND  msi.attribute7      IN  ( SELECT xlbiv.base_code AS base_code     -- ���_�R�[�h
                                        FROM xxcos_login_base_info_v xlbiv  ) -- ���O�C�����[�U�����_�r���[
    ;
--
    -- ���݃`�F�b�N���[�v
    << ins_chk_loop >>
    FOR i IN 1 .. l_subinv_tab.COUNT LOOP
      BEGIN
        SELECT  1
          INTO  ln_dummy
          FROM  xxcoi_lot_lock_control xllc
         WHERE  xllc.organization_id   = gn_inv_org_id
           AND  xllc.base_code         = l_subinv_tab(i).base_code
           AND  xllc.subinventory_code = l_subinv_tab(i).subinventory_code
        ;
      EXCEPTION
        -- �擾�ł��Ȃ��ꍇ�́A�V�K�o�^�p�ɕێ�
        WHEN NO_DATA_FOUND THEN
          ln_ins_lock_cnt := ln_ins_lock_cnt + 1;
          l_ins_lock_tab(ln_ins_lock_cnt).base_code         := l_subinv_tab(i).base_code;
          l_ins_lock_tab(ln_ins_lock_cnt).subinventory_code := l_subinv_tab(i).subinventory_code;
      END;
    END LOOP ins_chk_loop;
--
    -- ���b�g�ʈ������b�N����e�[�u���o�^
    -- �o�^���������݂���ꍇ
    IF ( ln_ins_lock_cnt > 0 ) THEN
      -- �o�^���[�v
      << ins_target_loop >>
      FOR i IN 1 .. l_ins_lock_tab.COUNT LOOP
        BEGIN
          INSERT INTO xxcoi_lot_lock_control(
              lot_lock_control_id                 -- ���b�g�ʈ������b�N����ID
            , organization_id                     -- �݌ɑg�DID
            , base_code                           -- ���_�R�[�h
            , subinventory_code                   -- �ۊǏꏊ�R�[�h
            , created_by                          -- �쐬��
            , creation_date                       -- �쐬��
            , last_updated_by                     -- �ŏI�X�V��
            , last_update_date                    -- �ŏI�X�V��
            , last_update_login                   -- �ŏI�X�V���O�C��
            , request_id                          -- �v��ID
            , program_application_id              -- �v���O�����A�v���P�[�V����ID
            , program_id                          -- �v���O����ID
            , program_update_date                 -- �v���O�����X�V��
          ) VALUES (
              xxcoi_lot_lock_control_s01.NEXTVAL  -- ���b�g�ʈ������b�N����ID
            , gn_inv_org_id                       -- �݌ɑg�DID
            , l_ins_lock_tab(i).base_code         -- ���_�R�[�h
            , l_ins_lock_tab(i).subinventory_code -- �ۊǏꏊ�R�[�h
            , cn_created_by                       -- �쐬��
            , cd_creation_date                    -- �쐬��
            , cn_last_updated_by                  -- �ŏI�X�V��
            , cd_last_update_date                 -- �ŏI�X�V��
            , cn_last_update_login                -- �ŏI�X�V���O�C��
            , cn_request_id                       -- �v��ID
            , cn_program_application_id           -- �v���O�����A�v���P�[�V����ID
            , cn_program_id                       -- �v���O����ID
            , cd_program_update_date              -- �v���O�����X�V��
          );
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            -- ��Ӑ���ᔽ
            -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                           , iv_name         => cv_msg_coi_10543 -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[
                           , iv_token_name1  => cv_tkn_base_code
                           , iv_token_value1 => l_subinv_tab(i).base_code -- ���_�R�[�h
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP ins_target_loop;
--
      -- �S���o�^���COMMIT���s
      COMMIT;
    END IF;
--
    -- ���b�g�ʈ������b�N����e�[�u�����b�N�擾
    << lock_loop >>
    FOR i IN 1 .. l_subinv_tab.COUNT LOOP
      BEGIN
        -- ���b�N�擾
        SELECT 1
        INTO   ln_dummy
        FROM   xxcoi_lot_lock_control xllc
        WHERE  xllc.organization_id   = gn_inv_org_id
        AND    xllc.base_code         = l_subinv_tab(i).base_code
        AND    xllc.subinventory_code = l_subinv_tab(i).subinventory_code
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN lock_expt THEN
        -- ���b�N�擾�Ɏ��s
          -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10543 -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => l_subinv_tab(i).base_code -- ���_�R�[�h
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP lock_loop;
--
    -- XXCOI:���b�g�t�]�L���̎擾
    gv_mark := FND_PROFILE.VALUE( cv_lot_reverse_mark );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gv_mark IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00032,   -- �v���t�@�C���擾�G���[
                     iv_token_name1   => cv_tkn_pro_tok,
                     iv_token_value1  => cv_lot_reverse_mark -- XXCOI:���b�g�t�]�L��
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
    in_file_id     IN  NUMBER,       --   �t�@�C��ID
    iv_file_format IN  VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���[�J���ϐ�������
    lt_file_name        := NULL; -- �t�@�C����
    lt_file_upload_name := NULL; -- �t�@�C���A�b�v���[�h����
--
    -- �t�@�C���A�b�v���[�hIF�f�[�^���b�N
    BEGIN
      SELECT  xfu.file_name AS file_name -- �t�@�C����
        INTO  lt_file_name -- �t�@�C����
        FROM  xxccp_mrp_file_ul_interface  xfu -- �t�@�C���A�b�v���[�hIF
       WHERE  xfu.file_id = in_file_id -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ���b�N���擾�ł��Ȃ��ꍇ
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_cos,
                       iv_name          => cv_msg_cos_00001, -- ���b�N�G���[���b�Z�[�W
                       iv_token_name1   => cv_tkn_table,
                       iv_token_value1  => cv_tkn_cos_11282  -- �t�@�C���A�b�v���[�hIF
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̏��擾
    BEGIN
      SELECT  flv.meaning AS file_upload_name -- �t�@�C���A�b�v���[�h����
        INTO  lt_file_upload_name -- �t�@�C���A�b�v���[�h����
        FROM  fnd_lookup_values flv -- �N�C�b�N�R�[�h
       WHERE  flv.lookup_type  = cv_type_upload_obj
         AND  flv.lookup_code  = iv_file_format
         AND  flv.enabled_flag = cv_const_y
         AND  flv.language     = ct_lang
         AND  NVL(flv.start_date_active, gd_process_date) <= gd_process_date
         AND  NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      -- �t�@�C���A�b�v���[�h���̂��擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_cos,
                       iv_name          => cv_msg_cos_11294, -- �t�@�C���A�b�v���[�h���̎擾�G���[���b�Z�[�W
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => iv_file_format  -- �t�H�[�}�b�g�p�^�[��
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �擾�����t�@�C�����A�t�@�C���A�b�v���[�h���̂��o��
    -- �t�@�C�������o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi,
                  iv_name          => cv_msg_coi_00028, -- �t�@�C�����o�̓��b�Z�[�W
                  iv_token_name1   => cv_tkn_file_name,
                  iv_token_value1  => lt_file_name      -- �t�@�C����
                )
    );
    -- �t�@�C�������o�́i�o�́j
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
     ,buff    => xxccp_common_pkg.get_msg(
                   iv_application   => cv_msg_kbn_coi,
                   iv_name          => cv_msg_coi_00028, -- �t�@�C�����o�̓��b�Z�[�W
                   iv_token_name1   => cv_tkn_file_name,
                   iv_token_value1  => lt_file_name      -- �t�@�C����
                 )
    );
--
    -- �t�@�C���A�b�v���[�h���̂��o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi,
                  iv_name          => cv_msg_coi_10611, -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                  iv_token_name1   => cv_tkn_file_upld_name,
                  iv_token_value1  => lt_file_upload_name  -- �t�@�C���A�b�v���[�h����
                )
    );
    -- �t�@�C���A�b�v���[�h���̂��o�́i�o�́j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi,
                  iv_name          => cv_msg_coi_10611, -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                  iv_token_name1   => cv_tkn_file_upld_name,
                  iv_token_value1  => lt_file_upload_name  -- �t�@�C���A�b�v���[�h����
                )
    );
--
    -- ��s���o�́i���O�j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- ��s���o�́i�o�́j
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    -- �t�@�C���A�b�v���[�hIF�f�[�^���擾
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- �t�@�C��ID
     ,ov_file_data => gt_file_line_data_tab -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���ʊ֐��G���[�A�܂��͒��o�s����2�s�ȏ�Ȃ������ꍇ
    IF ( (lv_retcode <> cv_status_normal)
      OR (gt_file_line_data_tab.COUNT < 2) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_cos,
                     iv_name          => cv_msg_cos_00013, -- �f�[�^���o�G���[���b�Z�[�W
                     iv_token_name1   => cv_tkn_table_name,
                     iv_token_value1  => cv_tkn_cos_11282, -- �t�@�C���A�b�v���[�hIF
                     iv_token_name2   => cv_tkn_key_data,
                     iv_token_value2  => NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����ݒ�i1�s�ڂ̓J�����s�̂��ߌ����Ƃ��ăJ�E���g���Ȃ��j
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
    in_file_id       IN  NUMBER,       -- �t�@�C��ID
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10633, -- �f�[�^�폜�G���[���b�Z�[�W
                       iv_token_name1   => cv_tkn_table_name,
                       iv_token_value1  => cv_tkn_coi_10634, -- �t�@�C���A�b�v���[�hIF
                       iv_token_name2   => cv_tkn_key_data,
                       iv_token_value2  => NULL
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
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
    in_file_if_loop_cnt    IN  NUMBER,   --   IF���[�v�J�E���^
    ov_errbuf              OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_rec_data     VARCHAR2(32765); -- ���R�[�h�f�[�^
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
    -- ���[�J���ϐ�������--
    lv_rec_data  := NULL; -- ���R�[�h�f�[�^
--
    -- ���ڐ��`�F�b�N
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) <> ( cn_c_header_all - 1 ) )
    THEN
      -- ���ڐ��s��v�̏ꍇ
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_cos,
                     iv_name          => cv_msg_cos_11295, -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
                     iv_token_name1   => cv_tkn_data,
                     iv_token_value1  => lv_rec_data  -- �t�H�[�}�b�g�p�^�[��
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �������[�v
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     => gt_file_line_data_tab(in_file_if_loop_cnt),
                                    iv_delim    => cv_csv_delimiter,
                                    in_part_num => i
                                  );
    END LOOP data_split_loop;
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
   * Procedure Name   : ins_upload_wk
   * Description      : �����������A�b�v���[�h�ꎞ�\�쐬����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_upload_wk(
    in_file_id     IN  NUMBER,   -- �t�@�C��ID
    in_if_loop_cnt IN  NUMBER,   -- IF���[�v�J�E���^
    ov_errbuf      OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �����������A�b�v���[�h�ꎞ�\�쐬
    INSERT INTO xxcoi_tmp_lot_resv_info_upld (
      file_id                 -- �t�@�C��ID
     ,row_number              -- �s�ԍ�
     ,slip_num                -- �`�[No
     ,order_number            -- �󒍔ԍ�
     ,parent_shipping_status  -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
     ,base_code               -- ���_�R�[�h
     ,whse_code               -- �ۊǏꏊ�R�[�h
     ,location_code           -- ���P�[�V�����R�[�h
     ,shipping_status         -- �o�׏��X�e�[�^�X
     ,chain_code              -- �`�F�[���X�R�[�h
     ,shop_code               -- �X�܃R�[�h
     ,shop_name               -- �X�ܖ�
     ,customer_code           -- �ڋq�R�[�h
     ,customer_name           -- �ڋq��
     ,center_code             -- �Z���^�[�R�[�h
     ,center_name             -- �Z���^�[��
     ,area_code               -- �n��R�[�h
     ,area_name               -- �n�於��
     ,shipped_date            -- �o�ד�
     ,arrival_date            -- ����
     ,item_div                -- ���i�敪
     ,parent_item_code        -- �e�i�ڃR�[�h
     ,item_code               -- �q�i�ڃR�[�h
     ,lot                     -- �ܖ�����
     ,difference_summary_code -- �ŗL�L��
     ,case_in_qty             -- ����
     ,case_qty                -- �P�[�X��
     ,singly_qty              -- �o����
     ,summary_qty             -- ����
     ,ordered_quantity        -- �󒍐���
     ,regular_sale_class_line -- ��ԓ����敪
     ,edi_received_date       -- EDI��M��
     ,delivery_order_edi      -- �z����(EDI)
    )
    VALUES (
      in_file_id                                                    -- �t�@�C��ID
     ,in_if_loop_cnt - 1                                            -- �s�ԍ�(2�s�ڂ��珈�����邽��-1����)
     ,g_if_data_tab(cn_c_slip_num)                                  -- �`�[No
     ,g_if_data_tab(cn_c_order_number)                              -- �󒍔ԍ�
     ,g_if_data_tab(cn_c_parent_shipping_status)                    -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
     ,g_if_data_tab(cn_c_base_code)                                 -- ���_�R�[�h
     ,g_if_data_tab(cn_c_whse_code)                                 -- �ۊǏꏊ�R�[�h
     ,g_if_data_tab(cn_c_location_code)                             -- ���P�[�V�����R�[�h
     ,g_if_data_tab(cn_c_shipping_status)                           -- �o�׏��X�e�[�^�X
     ,g_if_data_tab(cn_c_chain_code)                                -- �`�F�[���X�R�[�h
     ,g_if_data_tab(cn_c_shop_code)                                 -- �X�܃R�[�h
     ,g_if_data_tab(cn_c_shop_name)                                 -- �X�ܖ�
     ,g_if_data_tab(cn_c_customer_code)                             -- �ڋq�R�[�h
     ,g_if_data_tab(cn_c_customer_name)                             -- �ڋq��
     ,g_if_data_tab(cn_c_center_code)                               -- �Z���^�[�R�[�h
     ,g_if_data_tab(cn_c_center_name)                               -- �Z���^�[��
     ,g_if_data_tab(cn_c_area_code)                                 -- �n��R�[�h
     ,g_if_data_tab(cn_c_area_name)                                 -- �n�於��
     ,TO_DATE(g_if_data_tab(cn_c_shipped_date),cv_date_format)      -- �o�ד�
     ,TO_DATE(g_if_data_tab(cn_c_arrival_date),cv_date_format)      -- ����
     ,g_if_data_tab(cn_c_item_div )                                 -- ���i�敪
     ,g_if_data_tab(cn_c_parent_item_code)                          -- �e�i�ڃR�[�h
     ,g_if_data_tab(cn_c_item_code)                                 -- �q�i�ڃR�[�h
     ,g_if_data_tab(cn_c_lot)                                       -- �ܖ�����
     ,g_if_data_tab(cn_c_difference_summary_code)                   -- �ŗL�L��
     ,g_if_data_tab(cn_c_case_in_qty)                               -- ����
     ,g_if_data_tab(cn_c_case_qty)                                  -- �P�[�X��
     ,g_if_data_tab(cn_c_singly_qty)                                -- �o����
     ,g_if_data_tab(cn_c_summary_qty)                               -- ����
     ,g_if_data_tab(cn_c_ordered_quantity)                          -- �󒍐���
     ,g_if_data_tab(cn_c_regular_sale_class_line)                   -- ��ԓ����敪
     ,TO_DATE(g_if_data_tab(cn_c_edi_received_date),cv_date_format) -- EDI��M��
     ,g_if_data_tab(cn_c_delivery_order_edi)                        -- �z����(EDI)
    );
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
  END ins_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_wk
   * Description      : �����������A�b�v���[�h�ꎞ�\�擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_upload_wk(
    in_file_id    IN  NUMBER,       --   �t�@�C��ID
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
    CURSOR get_upload_wk_cur
    IS
      SELECT  xtlriu.slip_num                  AS slip_num                -- �`�[No
             ,xtlriu.row_number                AS row_number              -- �s�ԍ�
             ,xtlriu.order_number              AS order_number            -- �󒍔ԍ�
             ,xtlriu.parent_shipping_status    AS parent_shipping_status  -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
             ,xtlriu.base_code                 AS base_code               -- ���_�R�[�h
             ,xtlriu.whse_code                 AS whse_code               -- �ۊǏꏊ�R�[�h
             ,xtlriu.location_code             AS location_code           -- ���P�[�V�����R�[�h
             ,xtlriu.shipping_status           AS shipping_status         -- �o�׏��X�e�[�^�X
             ,xtlriu.chain_code                AS chain_code              -- �`�F�[���X�R�[�h
             ,xtlriu.shop_code                 AS shop_code               -- �X�܃R�[�h
             ,xtlriu.shop_name                 AS shop_name               -- �X�ܖ�
             ,xtlriu.customer_code             AS customer_code           -- �ڋq�R�[�h
             ,xtlriu.customer_name             AS customer_name           -- �ڋq��
             ,xtlriu.center_code               AS center_code             -- �Z���^�[�R�[�h
             ,xtlriu.center_name               AS center_name             -- �Z���^�[��
             ,xtlriu.area_code                 AS area_code               -- �n��R�[�h
             ,xtlriu.area_name                 AS area_name               -- �n�於��
             ,xtlriu.shipped_date              AS shipped_date            -- �o�ד�
             ,xtlriu.arrival_date              AS arrival_date            -- ����
             ,xtlriu.item_div                  AS item_div                -- ���i�敪
             ,xtlriu.parent_item_code          AS parent_item_code        -- �e�i�ڃR�[�h
             ,xtlriu.item_code                 AS item_code               -- �q�i�ڃR�[�h
             ,xtlriu.lot                       AS lot                     -- �ܖ�����
             ,xtlriu.difference_summary_code   AS difference_summary_code -- �ŗL�L��
             ,xtlriu.case_in_qty               AS case_in_qty             -- ����
             ,xtlriu.case_qty                  AS case_qty                -- �P�[�X��
             ,xtlriu.singly_qty                AS singly_qty              -- �o����
             ,xtlriu.summary_qty               AS summary_qty             -- ����
             ,xtlriu.ordered_quantity          AS ordered_quantity        -- �󒍐���
             ,xtlriu.regular_sale_class_line   AS regular_sale_class_line -- ��ԓ����敪
             ,xtlriu.edi_received_date         AS edi_received_date       -- EDI��M��
             ,xtlriu.delivery_order_edi        AS delivery_order_edi      -- �z����(EDI)
             ,NULL                             AS mark                    -- �L��
        FROM  xxcoi_tmp_lot_resv_info_upld xtlriu                         -- �����������A�b�v���[�h�ꎞ�\
       WHERE  xtlriu.file_id = in_file_id                                 --�t�@�C��ID
       ORDER BY xtlriu.order_number            -- �󒍔ԍ�
               ,xtlriu.parent_item_code        -- �e�i�ڃR�[�h
               ,xtlriu.shipped_date            -- �o�ד�
               ,xtlriu.arrival_date            -- ����
               ,xtlriu.regular_sale_class_line -- ��ԓ����敪
               ,xtlriu.edi_received_date       -- EDI��M��
               ,xtlriu.delivery_order_edi      -- �z����(EDI)
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
    -- �����������A�b�v���[�h�ꎞ�\�擾
    OPEN  get_upload_wk_cur;
    FETCH get_upload_wk_cur BULK COLLECT INTO g_upload_data_tab;
    CLOSE get_upload_wk_cur;
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
      IF ( get_upload_wk_cur%ISOPEN ) THEN
        CLOSE get_upload_wk_cur;
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
   * Procedure Name   : check_item_value
   * Description      : �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N(A-7)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_target_loop_cnt IN  NUMBER,    --   �����Ώۍs
    ov_errbuf          OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �ϐ�������
    g_reserve_info_tab.DELETE;
--
    -- ���b�g�ʈ��������擾
    SELECT xlri.slip_num                      AS slip_num                      -- �`�[No
          ,xlri.parent_shipping_status        AS parent_shipping_status        -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
          ,xlri.parent_shipping_status_name   AS parent_shipping_status_name   -- �o�׏��X�e�[�^�X��(�󒍔ԍ��P��)
          ,xlri.shipping_status               AS shipping_status               -- �o�׏��X�e�[�^�X
          ,xlri.shipping_status_name          AS shipping_status_name          -- �o�׏��X�e�[�^�X��
          ,xlri.chain_code                    AS chain_code                    -- �`�F�[���X�R�[�h
          ,xlri.chain_name                    AS chain_name                    -- �`�F�[���X��
          ,xlri.shop_code                     AS shop_code                     -- �X�܃R�[�h
          ,xlri.shop_name                     AS shop_name                     -- �X�ܖ�
          ,xlri.customer_code                 AS customer_code                 -- �ڋq�R�[�h
          ,xlri.customer_name                 AS customer_name                 -- �ڋq��
          ,xlri.center_code                   AS center_code                   -- �Z���^�[�R�[�h
          ,xlri.center_name                   AS center_name                   -- �Z���^�[��
          ,xlri.area_code                     AS area_code                     -- �n��R�[�h
          ,xlri.area_name                     AS area_name                     -- �n�於��
          ,TRUNC(xlri.shipped_date)           AS shipped_date                  -- �o�ד�
          ,TRUNC(xlri.arrival_date)           AS arrival_date                  -- ����
          ,xlri.item_div                      AS item_div                      -- ���i�敪
          ,xlri.item_div_name                 AS item_div_name                 -- ���i�敪��
          ,xlri.regular_sale_class_line       AS regular_sale_class_line       -- ��ԓ����敪
          ,xlri.regular_sale_class_name_line  AS regular_sale_class_name_line  -- ��ԓ����敪��
          ,TRUNC(xlri.edi_received_date)      AS edi_received_date             -- EDI��M��
          ,xlri.delivery_order_edi            AS delivery_order_edi            -- �z����(EDI)
          ,xlri.mark                          AS mark                          -- �L��
          ,xlri.header_id                     AS header_id                     -- �󒍃w�b�_ID
          ,xlri.line_id                       AS line_id                       -- �󒍖���ID
          ,xlri.customer_id                   AS customer_id                   -- �ڋqID
          ,xlri.parent_item_id                AS parent_item_id                -- �e�i��ID
          ,xlri.parent_item_name              AS parent_item_name              -- �e�i�ږ���
          ,xlri.reserve_transaction_type_code AS reserve_transaction_type_code -- ����������^�C�v�R�[�h
          ,xlri.order_quantity_uom            AS order_quantity_uom            -- �󒍒P��
    BULK COLLECT INTO g_reserve_info_tab -- ���b�g�ʈ������f�[�^
    FROM   xxcoi_lot_reserve_info xlri -- ���b�g�ʈ������
    WHERE  xlri.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- �󒍔ԍ�
      AND  xlri.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- �e�i�ڃR�[�h
    ORDER BY  xlri.shipped_date            -- �o�ד�
             ,xlri.arrival_date            -- ����
             ,xlri.regular_sale_class_line -- ��ԓ����敪
             ,xlri.edi_received_date       -- EDI��M��
             ,xlri.delivery_order_edi      -- �z����(EDI)
    ;
--
    -- �擾�ł��Ȃ������ꍇ
    IF ( g_reserve_info_tab.COUNT = 0 ) THEN
      -- �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10568, -- �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data -- �L�[���
                   );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �G���[�t���O���X�V
      gb_header_err_flag   := TRUE; -- �w�b�_�G���[�t���O
      gb_get_info_err_flag := TRUE; -- �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[�t���O
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
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_info
   * Description      : �����O���擾(A-8)
   ***********************************************************************************/
  PROCEDURE get_reserve_info(
    in_target_loop_cnt IN  NUMBER,   --   �����Ώۍs
    ov_errbuf          OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_reserve_info'; -- �v���O������
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
    -- �X�e�[�^�X�`�F�b�N
    -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)��'20'�ȊO�̏ꍇ�̓G���[
    IF ( g_reserve_info_tab(1).parent_shipping_status <> cv_shipping_status_20 ) THEN
      -- �o�׏��X�e�[�^�X�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10574  -- �o�׏��X�e�[�^�X�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data  -- �L�[���
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �w�b�_�G���[�t���O���X�V
      gb_header_err_flag := TRUE;
--
    END IF;
--
    -- �����O�̈��������擾
    SELECT  SUM(xlri.before_ordered_quantity) AS before_ordered_quantity -- �����O�󒍐��ʍ��v
           ,SUM(xlri.ordered_quantity)        AS ordered_quantity        -- �󒍐��ʍ��v
           ,SUM(xlri.case_qty)                AS case_qty                -- �����O�P�[�X��
           ,SUM(xlri.singly_qty)              AS singly_qTy              -- �����O�o����
           ,SUM(xlri.summary_qty)             AS summary_qty             -- �����O����
      INTO  gn_sum_before_ordered_quantity -- �����O�󒍐��ʍ��v
           ,gn_sum_ordered_quantity        -- �󒍐��ʍ��v
           ,gn_sum_before_case_qty         -- �����O�P�[�X��
           ,gn_sum_before_singly_qty       -- �����O�o����
           ,gn_sum_before_summary_qty      -- �����O����
     FROM   xxcoi_lot_reserve_info xlri -- ���b�g�ʈ������
     WHERE  xlri.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- �󒍔ԍ�
       AND  xlri.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- �e�i�ڃR�[�h
    ;
--
    -- �W�v�p�ϐ��̏�����
    gn_sum_case_qty    := 0; -- �P�[�X���W�v�p�ϐ�
    gn_sum_singly_qty  := 0; -- �o�����W�v�p�ϐ�
    gn_sum_summary_qty := 0; -- ���ʏW�v�p�ϐ�
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
  END get_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : del_reserve_info
   * Description      : �������폜(A-9)
   ***********************************************************************************/
  PROCEDURE del_reserve_info(
    in_target_loop_cnt  IN  NUMBER,       --   �t�@�C��ID
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_reserve_info'; -- �v���O������
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
    -- ���b�g�ʈ������폜
    DELETE FROM xxcoi_lot_reserve_info xlri -- ���b�g�ʈ������
    WHERE  xlri.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- �󒍔ԍ�
      AND  xlri.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- �e�i�ڃR�[�h
    ;
    -- �폜����
    gn_del_count := SQL%ROWCOUNT;
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
  END del_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : check_item_changes
   * Description      : ���ڕύX�`�F�b�N(A-10)
   ***********************************************************************************/
  PROCEDURE check_item_changes(
    in_target_loop_cnt  IN  NUMBER,    --   �����Ώۍs
    ov_errbuf           OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_changes'; -- �v���O������
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
    ln_count NUMBER; -- �����A�b�v���[�h�s�����擾
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
    -- �ϐ�������
    ln_count := 0; -- �����A�b�v���[�h�s�����擾
--
    -- �����������f�[�^�̊e���ڂ�A-8�Ŏ擾���������O���Ɣ�r
    -- �`�[No
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).slip_num, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).slip_num, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10499 -- �`�[No
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).parent_shipping_status, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).parent_shipping_status, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10615 -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �o�׏��X�e�[�^�X
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).shipping_status, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).shipping_status, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10616 -- �o�׏��X�e�[�^�X
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �`�F�[���X�R�[�h
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).chain_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).chain_code, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10617 -- �`�F�[���X�R�[�h
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �X�܃R�[�h
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).shop_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).shop_code, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10618 -- �X�܃R�[�h
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �ڋq�R�[�h
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).customer_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).customer_code, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10619 -- �ڋq�R�[�h
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �Z���^�[�R�[�h
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).center_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).center_code, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10620 -- �Z���^�[�R�[�h
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �n��R�[�h
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).area_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).area_code, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10621 -- �n��R�[�h
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- ���i�敪
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).item_div, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).item_div, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10624 -- ���i�敪
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- EDI��M��
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).edi_received_date, cd_dummy_date )
          <> NVL( g_reserve_info_tab(1).edi_received_date, cd_dummy_date ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10626 -- EDI��M��
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �z����(EDI)
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).delivery_order_edi, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).delivery_order_edi, cv_dummy_char ) )
    THEN
      -- ���ڕύX�`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- �L�[���
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10627 -- �z����(EDI)
      );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �����A�b�v���[�h�̎󒍔ԍ�-�e�i�ڂ̑g���������擾
    SELECT COUNT(1) AS cnt
      INTO ln_count
      FROM xxcoi_tmp_lot_resv_info_upld xtlriu                                              -- �����������A�b�v���[�h�ꎞ�\
     WHERE xtlriu.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- �󒍔ԍ�
       AND xtlriu.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- �e�i�ڃR�[�h
    ;
    -- �󒍔ԍ�-�e�i�ڂ̑g�����Ō��������R�[�h�ƒ����A�b�v���[�h�̌���������̏ꍇ�̂�
    IF ( gn_del_count = ln_count ) THEN
--
      -- �o�ד�
      IF ( NVL( g_upload_data_tab(in_target_loop_cnt).shipped_date, cd_dummy_date )
            <> NVL( g_reserve_info_tab(gn_same_key_count).shipped_date, cd_dummy_date ) )
      THEN
        -- ���ڕύX�`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => gv_key_data    -- �L�[���
                      ,iv_token_name2  => cv_tkn_item_name
                      ,iv_token_value2 => cv_tkn_coi_10622 -- �o�ד�
        );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
      END IF;
--
      -- ����
      IF ( NVL( g_upload_data_tab(in_target_loop_cnt).arrival_date, cd_dummy_date )
            <> NVL( g_reserve_info_tab(gn_same_key_count).arrival_date, cd_dummy_date ) )
      THEN
        -- ���ڕύX�`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => gv_key_data    -- �L�[���
                      ,iv_token_name2  => cv_tkn_item_name
                      ,iv_token_value2 => cv_tkn_coi_10623 -- ����
        );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
      END IF;
--
      -- ��ԓ����敪��1�A2�̏ꍇ��0��t�^
      IF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN ( cv_sale_class_1, cv_sale_class_2 ) ) THEN
        -- 0��t�^
        g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line
          := '0' || g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line;
      END IF;
      --
      -- ��ԓ����敪(�ϊ���̒l�ɂĔ�r)
      IF ( NVL( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line, cv_dummy_char )
            <> NVL( g_reserve_info_tab(gn_same_key_count).regular_sale_class_line, cv_dummy_char ) )
      THEN
        -- ���ڕύX�`�F�b�N�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10570  -- ���ڕύX�`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => gv_key_data    -- �L�[���
                      ,iv_token_name2  => cv_tkn_item_name
                      ,iv_token_value2 => cv_tkn_coi_10625 -- ��ԓ����敪
        );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
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
  END check_item_changes;
--
  /**********************************************************************************
   * Procedure Name   : check_code_value
   * Description      : �e��R�[�h�l�`�F�b�N(A-11)
   ***********************************************************************************/
  PROCEDURE check_code_value(
    in_target_loop_cnt  IN  NUMBER,    -- �����Ώۍs
    ov_errbuf           OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_code_value'; -- �v���O������
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
    lv_dummy_date       VARCHAR2(10);  -- ���t�`�F�b�N�p
    lt_customer_id      xxcoi_mst_lot_hold_info.customer_id%TYPE;        -- �ڋqID
    lt_parent_item_id   xxcoi_mst_lot_hold_info.parent_item_id%TYPE;     -- �e�i��ID
    lt_last_deliver_lot xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE; -- �[�i���b�g
    lt_delivery_date    xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;    -- �[�i��
    lb_lot_check_flag   BOOLEAN;       -- ���b�g�t�]�`�F�b�N�t���O
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
    -- ���[�J���ϐ�������
    lv_dummy_date       := NULL; -- ���t�`�F�b�N�p
    lt_customer_id      := NULL; -- �ڋqID
    lt_parent_item_id   := NULL; -- �e�i��ID
    lt_last_deliver_lot := NULL; -- �[�i���b�g
    lt_delivery_date    := NULL; -- �[�i��
    lb_lot_check_flag   := TRUE; -- ���b�g�t�]�`�F�b�N�t���O
--
    -- ���_�R�[�h�`�F�b�N
    BEGIN
      SELECT  xlbiv.base_name AS base_name -- ���_��
        INTO  gt_base_name  -- ���_��
        FROM  xxcos_login_base_info_v xlbiv -- ���O�C�����[�U�����_�r���[
       WHERE  xlbiv.base_code =  g_upload_data_tab(in_target_loop_cnt).base_code -- ���_�R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �擾�ł��Ȃ��ꍇ
        -- �e��R�[�h�l�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- �L�[���
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10502 -- ���_�R�[�h
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
    END;
--
    -- �ۊǏꏊ�R�[�h�`�F�b�N
    BEGIN
      SELECT  msi.description AS subinv_name -- �ۊǏꏊ��
        INTO  gt_subinv_name -- �ۊǏꏊ��
        FROM  mtl_secondary_inventories msi -- �ۊǏꏊ�}�X�^
       WHERE  msi.organization_id = gn_inv_org_id                                            -- �݌ɑg�DID
         AND  msi.attribute7      = g_upload_data_tab(in_target_loop_cnt).base_code          -- ���_�R�[�h
         AND  msi.secondary_inventory_name = g_upload_data_tab(in_target_loop_cnt).whse_code -- �ۊǏꏊ�R�[�h
         AND  msi.attribute14     = cv_const_y                                               -- �q�ɊǗ��Ώۋ敪
         AND  (msi.disable_date IS NULL
           OR msi.disable_date > gd_process_date)                                            -- ������
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �擾�ł��Ȃ��ꍇ
        -- �e��R�[�h�l�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- �L�[���
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10503 -- �ۊǏꏊ�R�[�h
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
    END;
--
    -- ���P�[�V�����R�[�h�`�F�b�N
    BEGIN
      SELECT  xwlmv.location_name AS location_name -- ���P�[�V��������
        INTO  gt_location_name
        FROM  xxcoi_warehouse_location_mst_v xwlmv -- �q�Ƀ��P�[�V�����}�X�^�r���[
       WHERE  xwlmv.organization_id   = gn_inv_org_id                                       -- �݌ɑg�DID
         AND  xwlmv.base_code         = g_upload_data_tab(in_target_loop_cnt).base_code     -- ���_�R�[�h
         AND  xwlmv.subinventory_code = g_upload_data_tab(in_target_loop_cnt).whse_code     -- �ۊǏꏊ�R�[�h
         AND  xwlmv.location_code     = g_upload_data_tab(in_target_loop_cnt).location_code -- ���P�[�V�����R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �擾�ł��Ȃ��ꍇ
        -- �e��R�[�h�l�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- �L�[���
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10581 -- ���P�[�V�����R�[�h
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
    END;
--
    -- �V�K�f�[�^�̏ꍇ
    IF ( gb_update_flag = FALSE ) THEN
--
      -- �`�F�[���X�R�[�h��NULL�łȂ��ꍇ
      IF ( g_upload_data_tab(in_target_loop_cnt).chain_code IS NOT NULL ) THEN
        -- �`�F�[���X�R�[�h�`�F�b�N
        BEGIN
          SELECT  hp.party_name AS party_name -- �p�[�e�B��
            INTO  gt_chain_name -- �`�F�[���X��
            FROM  hz_parties hp           -- �p�[�e�B
                 ,hz_cust_accounts hca    -- �ڋq�}�X�^
                 ,xxcmm_cust_accounts xca -- �ڋq�ǉ����
           WHERE  xca.edi_chain_code       = g_upload_data_tab(in_target_loop_cnt).chain_code -- �`�F�[���X�R�[�h
             AND  hca.cust_account_id      = xca.customer_id                                  -- �ڋqID
             AND  hca.customer_class_code  = cv_cust_class_code_18                            -- �ڋq�敪�i�`�F�[���X�j
             AND  hp.party_id              = hca.party_id                                     -- �p�[�e�BID
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          -- �擾�ł��Ȃ��ꍇ
            -- �e��R�[�h�l�`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_msg_kbn_coi,
                           iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                           iv_token_name1   => cv_tkn_key_data,
                           iv_token_value1  => gv_key_data, -- �L�[���
                           iv_token_name2   => cv_tkn_item_name,
                           iv_token_value2  => cv_tkn_coi_10617 -- �`�F�[���X�R�[�h
                         );
            -- �G���[���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- ���׃G���[�t���O���X�V
            gb_line_err_flag := TRUE;
        END;
      END IF;
--
      -- �ڋq�R�[�h�`�F�b�N
      BEGIN
        SELECT  hca.account_name       AS account_name       -- �ڋq��
               ,hca.cust_account_id    AS cust_account_id    -- �ڋqID
               ,xca.delivery_base_code AS delivery_base_code -- �[�i���_�R�[�h
               ,xca.chain_store_code   AS chain_store_code   -- �`�F�[���X�R�[�h
               ,xca.store_code         AS store_code         -- �X�܃R�[�h
               ,xca.cust_store_name    AS cust_store_name    -- �ڋq�X�ܖ���
               ,xca.deli_center_code   AS deli_center_code   -- EDI�[�i�Z���^�[�R�[�h
               ,xca.deli_center_name   AS deli_center_name   -- EDI�[�i�Z���^�[��
               ,xca.edi_district_code  AS edi_district_code  -- EDI�n��R�[�h(EDI)
               ,xca.edi_district_name  AS edi_district_name  -- EDI�n�於(EDI)
               ,xca.delivery_order     AS delivery_order     -- �z�����iEDI)
          INTO  gt_account_name       -- �ڋq��
               ,gt_customer_id        -- �ڋqID
               ,gt_delivery_base_code -- ���_�R�[�h
               ,gt_chain_store_code   -- �`�F�[���X�R�[�h
               ,gt_store_code         -- �X�܃R�[�h
               ,gt_cust_store_name    -- �X�ܖ���
               ,gt_deli_center_code   -- �Z���^�[�R�[�h
               ,gt_deli_center_name   -- �Z���^�[��
               ,gt_edi_district_code  -- �n��R�[�h
               ,gt_edi_district_name  -- �n�於
               ,gt_delivery_order     -- �z�����iEDI)
          FROM   xxcmm_cust_accounts xca -- �ڋq�ǉ����
                ,hz_cust_accounts hca    -- �ڋq�}�X�^
         WHERE  hca.account_number      = g_upload_data_tab(in_target_loop_cnt).customer_code -- �ڋq�R�[�h
           AND  hca.customer_class_code IN (cv_cust_class_code_10,cv_cust_class_code_12)      -- �ڋq�敪�i�ڋq/��l�ڋq�j
           AND  hca.cust_account_id     = xca.customer_id                                     -- �ڋqID
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ��ꍇ
          -- �e��R�[�h�l�`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- �L�[���
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10619 -- �ڋq�R�[�h
                       );
          -- �G���[���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- ���׃G���[�t���O���X�V
          gb_line_err_flag := TRUE;
      END;
--
      -- �o�ד���NULL�łȂ��ꍇ
      IF ( g_upload_data_tab(in_target_loop_cnt).shipped_date IS NOT NULL ) THEN
        -- �o�ד��i���t�`���j�`�F�b�N
        BEGIN
          lv_dummy_date := TO_CHAR(g_upload_data_tab(in_target_loop_cnt).shipped_date,cv_date_format);
        EXCEPTION
          WHEN OTHERS THEN
          -- ���t�`���łȂ��ꍇ
            -- �e��R�[�h�l�`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_msg_kbn_coi,
                           iv_name          => cv_msg_coi_10572, -- ���t�`���`�F�b�N�G���[
                           iv_token_name1   => cv_tkn_key_data,
                           iv_token_value1  => gv_key_data, -- �L�[���
                           iv_token_name2   => cv_tkn_item_name,
                           iv_token_value2  => cv_tkn_coi_10622 -- �o�ד�
                         );
            -- �G���[���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- ���׃G���[�t���O���X�V
            gb_line_err_flag := TRUE;
        END;
        -- �o�ד��i�������t�j�`�F�b�N
        IF ( g_upload_data_tab(in_target_loop_cnt).shipped_date < gd_process_date ) THEN
          -- �������`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10573, -- �������`�F�b�N�G���[
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- �L�[���
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10622 -- �o�ד�
                       );
          -- �G���[���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- ���׃G���[�t���O���X�V
          gb_line_err_flag := TRUE;
        END IF;
      END IF;
--
      -- �����i���t�`���j�`�F�b�N
      BEGIN
        lv_dummy_date := TO_CHAR(g_upload_data_tab(in_target_loop_cnt).arrival_date,cv_date_format);
      EXCEPTION
        WHEN OTHERS THEN
        -- ���t�`���łȂ��ꍇ
          -- �e��R�[�h�l�`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10572, -- ���t�`���`�F�b�N�G���[
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- �L�[���
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10623 -- ����
                       );
          -- �G���[���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- ���׃G���[�t���O���X�V
          gb_line_err_flag := TRUE;
      END;
      -- �����i�������t�j�`�F�b�N
      IF ( g_upload_data_tab(in_target_loop_cnt).arrival_date < gd_process_date ) THEN
        -- �������`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10573, -- �������`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- �L�[���
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10623 -- ����
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
      END IF;
--
      -- �e�i�ڃR�[�h�`�F�b�N
      BEGIN
        SELECT  ximb.item_short_name   AS item_short_name   -- ����
               ,msib.inventory_item_id AS inventory_item_id -- �i��ID
          INTO  gt_parent_item_name -- �e�i�ږ���
               ,gt_parent_item_id   -- �e�i��iD
          FROM  xxcmn_item_mst_b   ximb  -- OPM�i�ڃA�h�I���}�X�^
               ,ic_item_mst_b      iimb  -- OPM�i�ڃ}�X�^
               ,mtl_system_items_b msib  -- Disc�i�ڃ}�X�^
         WHERE  msib.organization_id   = gn_inv_org_id                                          -- �݌ɑg�DID
           AND  msib.segment1          = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- �e�i�ڃR�[�h
           AND  iimb.item_no           = msib.segment1                                          -- �i�ڃR�[�h
           AND  ximb.item_id           = iimb.item_id                                           -- �i��ID
           AND  ximb.start_date_active <= gd_process_date                                       -- �L���J�n��
           AND  ximb.end_date_active   >= gd_process_date                                       -- �L���I����
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ��ꍇ
          -- �e��R�[�h�l�`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- �L�[���
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10496 -- �e�i�ڃR�[�h
                       );
          -- �G���[���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- ���׃G���[�t���O���X�V
          gb_line_err_flag := TRUE;
      END;
--
    END IF;
--
    -- �q�i�ڃR�[�h�`�F�b�N
    BEGIN
      SELECT  ximb.item_short_name   AS item_short_name   -- ����
             ,msib.inventory_item_id AS inventory_item_id -- �i��ID
        INTO  gt_child_item_name -- �q�i�ږ���
             ,gt_child_item_id   -- �q�i��iD
        FROM  xxcmn_item_mst_b   ximb  -- OPM�i�ڃA�h�I���}�X�^
             ,ic_item_mst_b      iimb  -- OPM�i�ڃ}�X�^
             ,mtl_system_items_b msib  -- Disc�i�ڃ}�X�^
       WHERE  msib.organization_id   = gn_inv_org_id                                   -- �݌ɑg�DID
         AND  msib.segment1          = g_upload_data_tab(in_target_loop_cnt).item_code -- �q�i�ڃR�[�h
         AND  iimb.item_no           = msib.segment1                                   -- �i�ڃR�[�h
         AND  ximb.item_id           = iimb.item_id                                    -- �i��ID
         AND  ximb.start_date_active <= gd_process_date                                -- �L���J�n��
         AND  ximb.end_date_active   >= gd_process_date                                -- �L���I����
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �擾�ł��Ȃ��ꍇ
        -- �e��R�[�h�l�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- �L�[���
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10628 -- �q�i�ڃR�[�h
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
    END;
--
    -- �ܖ������i���b�g�t�]�j�`�F�b�N
    -- �ڋqID�A�e�i��ID�̐ݒ�
    IF ( gb_update_flag = TRUE ) THEN
      -- �X�V�f�[�^�̏ꍇ��A-8.�����O���擾�Ŏ擾�����l�������Ɏg�p
      lt_customer_id    := g_reserve_info_tab(1).customer_id;
      lt_parent_item_id := g_reserve_info_tab(1).parent_item_id;
    ELSE
      -- �V�K�f�[�^�̏ꍇ��A-11.�e��R�[�h�l�`�F�b�N�Ŏ擾�����l�������Ɏg�p
      lt_customer_id    := gt_customer_id;
      lt_parent_item_id := gt_parent_item_id;
    END IF;
--
    -- ���b�g�̎擾
    BEGIN
      SELECT  xmlhi.last_deliver_lot_e  AS last_deliver_lot_e -- �[�i���b�g�i�c�Ɓj
             ,xmlhi.delivery_date_e     AS delivery_date_e    -- �[�i���i�c�Ɓj
             ,xmlhi.last_deliver_lot_s  AS last_deliver_lot_s -- �[�i���b�g�i���Y�j
             ,xmlhi.delivery_date_s     AS delivery_date_s    -- �[�i���i���Y�j
        INTO  gt_last_deliver_lot_e -- �[�i���b�g�i�c�Ɓj
             ,gt_delivery_date_e    -- �[�i���i�c�Ɓj
             ,gt_last_deliver_lot_s -- �[�i���b�g�i���Y�j
             ,gt_delivery_date_s    -- �[�i���i���Y�j
        FROM  xxcoi_mst_lot_hold_info  xmlhi   -- ���b�g���ێ��}�X�^
       WHERE  xmlhi.customer_id     = lt_customer_id    -- �ڋqID
         AND  xmlhi.parent_item_id  = lt_parent_item_id -- �e�i��ID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �擾�ł��Ȃ��ꍇ
        -- ���b�g�t�]�`�F�b�N�t���O���X�V
        lb_lot_check_flag := FALSE;
    END;
--
    -- ���b�g�t�]�`�F�b�N�t���O��TRUE�̏ꍇ
    IF ( lb_lot_check_flag = TRUE ) THEN
      -- �c�ƁA���Y�̂����[�i�����������̕���ϐ��ɐݒ�
      -- �[�i��_���Y��NULL�A�܂��͔[�i��_�c��>�[�i��_���Y�̏ꍇ
      IF ( (gt_delivery_date_s IS NULL)
        OR (gt_delivery_date_e > gt_delivery_date_s) )
      THEN
        lt_last_deliver_lot := gt_last_deliver_lot_e;
        lt_delivery_date    := gt_delivery_date_e;
      ELSIF ( (gt_delivery_date_e IS NULL)
        OR (gt_delivery_date_s > gt_delivery_date_e) )
      THEN
        -- �[�i��_�c�Ƃ�NULL�A�܂��͔[�i��_���Y>�[�i��_�c�Ƃ̏ꍇ
        lt_last_deliver_lot := gt_last_deliver_lot_s;
        lt_delivery_date    := gt_delivery_date_s;
      ELSE
        -- �[�i��_�c�� = �[�i��_���Y�̏ꍇ�A���b�g���������̕���ϐ��ɐݒ�
        IF ( TO_DATE(gt_last_deliver_lot_e,cv_date_format)
               > TO_DATE(gt_last_deliver_lot_s,cv_date_format) )
        THEN
          -- ���b�g_�c��>���b�g_���Y�̏ꍇ
          lt_last_deliver_lot := gt_last_deliver_lot_e;
          lt_delivery_date    := gt_delivery_date_e;
        ELSE
          -- ���b�g_���Y>���b�g_�c�ƁA�܂��̓��b�g���������ꍇ
          lt_last_deliver_lot := gt_last_deliver_lot_s;
          lt_delivery_date    := gt_delivery_date_s;
        END IF;
      END IF;
--
      -- ���b�g�t�]�`�F�b�N
      IF ( (lt_delivery_date < g_upload_data_tab(in_target_loop_cnt).arrival_date)
        AND (TO_DATE(lt_last_deliver_lot,cv_date_format)
               > TO_DATE(g_upload_data_tab(in_target_loop_cnt).lot,cv_date_format)) )
      THEN
        -- �������ŐV�[�i������A���A�ܖ��������ŐV���b�g���O�̏ꍇ�A���b�g�t�]�`�F�b�N�x��
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10575, -- ���b�g�t�]�`�F�b�N�x��
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data -- �L�[���
                     );
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
--
      ELSIF ( ( lt_delivery_date > g_upload_data_tab( in_target_loop_cnt ).arrival_date ) 
        AND ( TO_DATE( lt_last_deliver_lot, cv_date_format )
               < TO_DATE( g_upload_data_tab( in_target_loop_cnt ).lot, cv_date_format ) )
      ) THEN
        -- �������ŐV�[�i�����O�A���A�ܖ��������ŐV���b�g����̏ꍇ�A�L����t�^
        g_upload_data_tab( in_target_loop_cnt ).mark := gv_mark;
      END IF;
--
    END IF;
--
    -- ��ԓ����敪�`�F�b�N
    -- '1'�A'2'�̏ꍇ�͑O0��t�^���A���ʊ֐�����ԓ����敪�����擾
    IF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN ( cv_sale_class_1, cv_sale_class_2 ) ) THEN
      -- �O0��t�^
      g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line := '0' || g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line;
      -- ��ԓ����敪�����擾
      gt_regular_sale_class_name := xxcoi_common_pkg.get_meaning(
                                        iv_lookup_type => cv_type_bargain_class
                                       ,iv_lookup_code => g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line
                                    );
      -- �擾�ł��Ȃ��ꍇ
      IF ( gt_regular_sale_class_name IS NULL ) THEN
        -- �e��R�[�h�l�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- �L�[���
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10625 -- ��ԓ����敪
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
      END IF;
    END IF;
--
    -- '01'�A'02'�ȊO�̏ꍇ�͒�ԓ����敪����NULL��ݒ�
    IF( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN (cv_sale_class_3,cv_sale_class_4,cv_sale_class_5,cv_sale_class_6,cv_sale_class_7,cv_sale_class_9) )THEN
      gt_regular_sale_class_name := NULL;
    END IF;
    --
    -- ����������^�C�v�R�[�h�ݒ�
    IF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN ( cv_regular_sale_class_line_01, cv_regular_sale_class_line_02, cv_sale_class_3, cv_sale_class_4, cv_sale_class_9 ) ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_170;
    ELSIF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line = cv_sale_class_6 ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_320;
    ELSIF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line = cv_sale_class_5 ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_340;
    ELSIF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line = cv_sale_class_7 ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_360;
    ELSE
      -- �e��R�[�h�l�`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10571, -- �e��R�[�h�l�`�F�b�N�G���[
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data, -- �L�[���
                     iv_token_name2   => cv_tkn_item_name,
                     iv_token_value2  => cv_tkn_coi_10625 -- ��ԓ����敪
                   );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �V�K�f�[�^�̏ꍇ
    IF ( gb_update_flag = FALSE ) THEN
      -- EDI��M����NULL�łȂ��ꍇ
      IF ( g_upload_data_tab(in_target_loop_cnt).edi_received_date IS NOT NULL ) THEN
        -- EDI��M���i���t�`���j�`�F�b�N
        BEGIN
          lv_dummy_date := TO_CHAR(g_upload_data_tab(in_target_loop_cnt).edi_received_date,cv_date_format);
        EXCEPTION
          -- ���t�`���łȂ��ꍇ
          WHEN OTHERS THEN
            -- ���t�`���`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_msg_kbn_coi,
                           iv_name          => cv_msg_coi_10572, -- ���t�`���`�F�b�N�G���[
                           iv_token_name1   => cv_tkn_key_data,
                           iv_token_value1  => gv_key_data, -- �L�[���
                           iv_token_name2   => cv_tkn_item_name,
                           iv_token_value2  => cv_tkn_coi_10626 -- EDI��M��
                         );
            -- �G���[���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- ���׃G���[�t���O���X�V
            gb_line_err_flag := TRUE;
        END;
      END IF;
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
  END check_code_value;
--
  /**********************************************************************************
   * Procedure Name   : check_item_validation
   * Description      : ���ڊ֘A�`�F�b�N(A-12)
   ***********************************************************************************/
  PROCEDURE check_item_validation(
    in_target_loop_cnt    IN  NUMBER,       --   �����Ώۍs
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_validation'; -- �v���O������
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
    lt_item_info_tab  xxcoi_common_pkg.item_info_ttype;   -- �i�ڏ��i�e�[�u���^�j
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
    -- �V�K�f�[�^�i�����������f�[�^�̎󒍔ԍ���NULL�j�̏ꍇ
    IF ( g_upload_data_tab(in_target_loop_cnt).order_number IS NULL ) THEN
      -- ���_�A�`�F�[���X�A�ڋq�R�[�h�̊֘A�`�F�b�N
      -- �����������f�[�^.���_�R�[�h���AA-11�Ŏ擾�������_�R�[�h�ƈقȂ�ꍇ
      IF ( g_upload_data_tab(in_target_loop_cnt).base_code <> gt_delivery_base_code ) THEN
        -- ���_�A�ڋq�֘A�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10594, -- ���_�A�ڋq�֘A�`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data -- �L�[���
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
      END IF;
--
      -- �����������f�[�^.�`�F�[���X�R�[�h��NULL�łȂ��ꍇ
      IF ( g_upload_data_tab(in_target_loop_cnt).chain_code IS NOT NULL ) THEN
        -- �����������f�[�^.�`�F�[���X�R�[�h���AA-11�Ŏ擾�����`�F�[���X�R�[�h�ƈقȂ�ꍇ
        IF ( g_upload_data_tab(in_target_loop_cnt).chain_code <> gt_chain_store_code ) THEN
          -- �`�F�[���X�A�ڋq�֘A�`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10595, -- �`�F�[���X�A�ڋq�֘A�`�F�b�N�G���[
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data -- �L�[���
                       );
          -- �G���[���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- ���׃G���[�t���O���X�V
          gb_line_err_flag := TRUE;
        END IF;
      END IF;
    END IF;
--
    -- ���i�敪�A�e�i�ځA�q�i�ڂ̊֘A�`�F�b�N
    xxcoi_common_pkg.get_parent_child_item_info(
      id_date           => gd_process_date  -- ���t
     ,in_inv_org_id     => gn_inv_org_id    -- �݌ɑg�DID
     ,in_parent_item_id => NULL             -- �e�i��ID(DISC)
     ,in_child_item_id  => gt_child_item_id -- �q�i��ID(DISC)
     ,ot_item_info_tab  => lt_item_info_tab -- �i�ڏ��
     ,ov_errbuf         => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                     );
    -- ���^�[���R�[�h��'0'�i����j�ȊO�̏ꍇ�̓G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �i�ڃR�[�h���o�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10576, -- �`�F�[���X�A�ڋq�֘A�`�F�b�N�G���[
                     iv_token_name1   => cv_tkn_err_msg,
                     iv_token_value1  => lv_errmsg -- �G���[���b�Z�[�W
                   );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    ELSE
    -- ���^�[���R�[�h��'0'�i����j�̏ꍇ
      -- ���i�敪����ϐ��Ɋi�[�i���b�g�ʈ������o�^���Ɏg�p�j
      gt_item_div_name := lt_item_info_tab(1).item_kbn_name;
--
      -- �����������f�[�^.�e�i�ڃR�[�h,���i�敪���A���ʊ֐��Ŏ擾�����i�ڏ��ƈقȂ�ꍇ
      IF ( (g_upload_data_tab(in_target_loop_cnt).parent_item_code <> lt_item_info_tab(1).item_no)
        OR (g_upload_data_tab(in_target_loop_cnt).item_div <> lt_item_info_tab(1).item_kbn) )
      THEN
        -- ���i�敪�A�e�i�ځA�q�i�ڊ֘A�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10577, -- ���i�敪�A�e�i�ځA�q�i�ڊ֘A�`�F�b�N�G���[
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data -- �L�[���
                     );
        -- �G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- ���׃G���[�t���O���X�V
        gb_line_err_flag := TRUE;
      END IF;
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
  END check_item_validation;
--
  /**********************************************************************************
   * Procedure Name   : check_cese_singly_qty
   * Description      : �P�[�X���A�o�����`�F�b�N(A-13)
   ***********************************************************************************/
  PROCEDURE check_cese_singly_qty(
    in_target_loop_cnt    IN  NUMBER,       --   �����Ώۍs
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cese_singly_qty'; -- �v���O������
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
    -- �����������f�[�^�̐��ʂ��u�����~�P�[�X���{�o�����v�łȂ��ꍇ�̓G���[
    IF ( g_upload_data_tab(in_target_loop_cnt).summary_qty           --����
           <> (  g_upload_data_tab(in_target_loop_cnt).case_in_qty   -- ����
               * g_upload_data_tab(in_target_loop_cnt).case_qty      -- �P�[�X��
               + g_upload_data_tab(in_target_loop_cnt).singly_qty) ) -- �o����
    THEN
      -- �P�[�X���A�o�����`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10578, -- �P�[�X���A�o�����`�F�b�N�G���[
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data -- �L�[���
                   );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �W�v�p�ϐ��ɉ��Z
    gn_sum_case_qty    :=  gn_sum_case_qty    + g_upload_data_tab(in_target_loop_cnt).case_qty;    -- �P�[�X���W�v�p�ϐ�
    gn_sum_singly_qty  :=  gn_sum_singly_qty  + g_upload_data_tab(in_target_loop_cnt).singly_qty;  -- �o�����W�v�p�ϐ�
    gn_sum_summary_qty :=  gn_sum_summary_qty + g_upload_data_tab(in_target_loop_cnt).summary_qty; -- ���ʏW�v�p�ϐ�
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
  END check_cese_singly_qty;
--
  /**********************************************************************************
   * Procedure Name   : chack_reserve_availablity
   * Description      : �����\�`�F�b�N(A-14)
   ***********************************************************************************/
  PROCEDURE chack_reserve_availablity(
    in_target_loop_cnt    IN  NUMBER,       --   �����Ώۍs
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chack_reserve_availablity'; -- �v���O������
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
    ln_case_in_qty NUMBER; -- ����
    ln_case_qty    NUMBER; -- �P�[�X��
    ln_singly_qty  NUMBER; -- �o����
    ln_summary_qty NUMBER; -- ����
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
    -- ���[�J���ϐ�������
    ln_case_in_qty := 0; -- ����
    ln_case_qty    := 0; -- �P�[�X��
    ln_singly_qty  := 0; -- �o����
    ln_summary_qty := 0; -- ����
--
    -- ���ʊ֐��u�����\���Z�o�v
    xxcoi_common_pkg.get_reserved_quantity(
      in_inv_org_id    => gn_inv_org_id    -- �݌ɑg�DID
     ,iv_base_code     => g_upload_data_tab(in_target_loop_cnt).base_code     -- ���_�R�[�h
     ,iv_subinv_code   => g_upload_data_tab(in_target_loop_cnt).whse_code     -- �ۊǏꏊ�R�[�h
     ,iv_loc_code      => g_upload_data_tab(in_target_loop_cnt).location_code -- ���P�[�V�����R�[�h
     ,in_child_item_id => gt_child_item_id -- �q�i��ID
     ,iv_lot           => g_upload_data_tab(in_target_loop_cnt).lot           -- ���b�g�i�ܖ������j
     ,iv_diff_sum_code => g_upload_data_tab(in_target_loop_cnt).difference_summary_code -- �ŗL�L��
     ,on_case_in_qty   => ln_case_in_qty   -- ����
     ,on_case_qty      => ln_case_qty      -- �P�[�X��
     ,on_singly_qty    => ln_singly_qty    -- �o����
     ,on_summary_qty   => ln_summary_qty   -- �������
     ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���^�[���R�[�h��'0'�i����j�ȊO�̏ꍇ�̓G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �����\���Z�o�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10593, -- �����\���Z�o�G���[
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data, -- �L�[���
                     iv_token_name2   => cv_tkn_err_msg,
                     iv_token_value2  => lv_errmsg -- �G���[���b�Z�[�W
                   );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
    END IF;
--
    -- �����������f�[�^.�P�[�X���܂��͐��ʂ������\���𒴂���ꍇ
    IF ( (g_upload_data_tab(in_target_loop_cnt).case_qty    > ln_case_qty)     -- �P�[�X��
      OR (g_upload_data_tab(in_target_loop_cnt).summary_qty > ln_summary_qty) )-- �������
    THEN
      -- �����\�`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10579, -- �����\�`�F�b�N�G���[
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data -- �L�[���
                   );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ���׃G���[�t���O���X�V
      gb_line_err_flag := TRUE;
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
  END chack_reserve_availablity;
--
  /**********************************************************************************
   * Procedure Name   : get_user_info
   * Description      : ���s�ҏ��擾(A-15)
   ***********************************************************************************/
  PROCEDURE get_user_info(
    in_target_loop_cnt    IN  NUMBER,       --   �����Ώۍs
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_info'; -- �v���O������
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
    -- �]�ƈ����擾
    SELECT  fnu.user_name AS user_name-- ���[�U��
           ,papf.per_information18 AS per_info_18 -- ��������(�]�ƈ����18)
           ,papf.per_information19 AS per_info_19 -- ��������(�]�ƈ����19)
      INTO  gt_user_name         -- ���[�U��
           ,gt_per_information18 -- ��������(�]�ƈ����18)
           ,gt_per_information19 -- ��������(�]�ƈ����19)
      FROM  per_all_people_f papf -- �]�ƈ��}�X�^
           ,fnd_user         fnu  -- ���[�U�[�}�X�^
     WHERE  fnu.user_id    = cn_created_by    -- ���[�UID
       AND  papf.person_id = fnu.employee_id  -- �]�ƈ�ID
       AND  papf.effective_start_date <= gd_process_date -- �L���J�n��
       AND  papf.effective_end_date   >= gd_process_date -- �L���I����
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
  END get_user_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_reserve_info
   * Description      : �������o�^(A-16)
   ***********************************************************************************/
  PROCEDURE ins_reserve_info(
    in_target_loop_cnt    IN  NUMBER,       --   �����Ώۍs
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_reserve_info'; -- �v���O������
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
    ln_sqs_value_order NUMBER; -- �V�[�P���X�l�i�V�K�󒍔ԍ��j
--
    lt_slip_num                xxcoi_lot_reserve_info.slip_num%TYPE;                      -- �`�[No
    lt_order_number            xxcoi_lot_reserve_info.order_number%TYPE;                  -- �󒍔ԍ�
    lt_chain_name              xxcoi_lot_reserve_info.chain_name%TYPE;                    -- �`�F�[���X��
    lt_shop_code               xxcoi_lot_reserve_info.shop_code%TYPE;                     -- �X�܃R�[�h
    lt_shop_name               xxcoi_lot_reserve_info.shop_name%TYPE;                     -- �X�ܖ�
    lt_customer_name           xxcoi_lot_reserve_info.customer_name%TYPE;                 -- �ڋq��
    lt_center_code             xxcoi_lot_reserve_info.center_code%TYPE;                   -- �Z���^�[�R�[�h
    lt_center_name             xxcoi_lot_reserve_info.center_name%TYPE;                   -- �Z���^�[��
    lt_area_code               xxcoi_lot_reserve_info.area_code%TYPE;                     -- �n��R�[�h
    lt_area_name               xxcoi_lot_reserve_info.area_name%TYPE;                     -- �n�於��
    lt_item_div_name           xxcoi_lot_reserve_info.item_div_name%TYPE;                 -- ���i�敪��
    lt_parent_item_name        xxcoi_lot_reserve_info.parent_item_name%TYPE;              -- �e�i�ږ���
    lt_reg_sale_class_name     xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE;  -- ��ԓ����敪��(����)
    lt_delivery_order_edi      xxcoi_lot_reserve_info.delivery_order_edi%TYPE;            -- �z����(EDI)
    lt_mark                    xxcoi_lot_reserve_info.mark%TYPE;                          -- �L��
    lt_header_id               xxcoi_lot_reserve_info.header_id%TYPE;                     -- �󒍃w�b�_ID
    lt_line_id                 xxcoi_lot_reserve_info.line_id%TYPE;                       -- �󒍖���ID
    lt_customer_id             xxcoi_lot_reserve_info.customer_id%TYPE;                   -- �ڋqID
    lt_parent_item_id          xxcoi_lot_reserve_info.parent_item_id%TYPE;                -- �e�i��ID
    lt_resv_tran_type_code     xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE; -- ����������^�C�v�R�[�h
    lt_order_quantity_uom      xxcoi_lot_reserve_info.order_quantity_uom%TYPE;            -- �󒍒P��
    lt_before_ordered_quantity xxcoi_lot_reserve_info.before_ordered_quantity%TYPE;       -- �����O�󒍐���
    lt_sum_ordered_quantity    xxcoi_lot_reserve_info.ordered_quantity%TYPE;              -- �󒍐���
--
    lt_lot_e                   xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE; -- �ŐV�[�i���b�g_�c��
    lt_deli_date_e             xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;    -- �[�i��_�c��
    lt_lot_s                   xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE; -- �ŐV�[�i���b�g_���Y
    lt_deli_date_s             xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;    -- �[�i��_���Y
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
    -- �ϐ��̐ݒ�
    IF ( gb_update_flag = TRUE ) THEN
      -- �X�V�̏ꍇ
      lt_slip_num             := g_reserve_info_tab(1).slip_num;                     -- �`�[No
      lt_order_number         := g_upload_data_tab(in_target_loop_cnt).order_number; -- �󒍔ԍ�
      lt_chain_name           := g_reserve_info_tab(1).chain_name;                   -- �`�F�[���X��
      lt_shop_code            := g_reserve_info_tab(1).shop_code;                    -- �X�܃R�[�h
      lt_shop_name            := g_reserve_info_tab(1).shop_name;                    -- �X�ܖ�
      lt_customer_name        := g_reserve_info_tab(1).customer_name;                -- �ڋq��
      lt_center_code          := g_reserve_info_tab(1).center_code;                  -- �Z���^�[�R�[�h
      lt_center_name          := g_reserve_info_tab(1).center_name;                  -- �Z���^�[��
      lt_area_code            := g_reserve_info_tab(1).area_code;                    -- �n��R�[�h
      lt_area_name            := g_reserve_info_tab(1).area_name;                    -- �n�於��
      lt_item_div_name        := g_reserve_info_tab(1).item_div_name;                -- ���i�敪��
      lt_parent_item_name     := g_reserve_info_tab(1).parent_item_name;             -- �e�i�ږ���
      lt_reg_sale_class_name  := gt_regular_sale_class_name;                         -- ��ԓ����敪��(����)
      lt_delivery_order_edi   := g_reserve_info_tab(1).delivery_order_edi;           -- �z����(EDI)
      lt_header_id            := g_reserve_info_tab(1).header_id;                    -- �󒍃w�b�_ID
      lt_line_id              := g_reserve_info_tab(1).line_id;                      -- �󒍖���ID
      lt_customer_id          := g_reserve_info_tab(1).customer_id;                  -- �ڋqID
      lt_parent_item_id       := g_reserve_info_tab(1).parent_item_id;               -- �e�i��ID
      lt_resv_tran_type_code  := gt_resv_tran_type_code;                             -- ����������^�C�v�R�[�h
      lt_order_quantity_uom   := g_reserve_info_tab(1).order_quantity_uom;           -- �󒍒P��
      -- �����O�󒍐��ʁA�󒍐��ʂ͓���L�[�ōŏ���1���R�[�h�̂ݓo�^
      IF ( gn_same_key_count = 1 ) THEN
        lt_before_ordered_quantity := gn_sum_before_ordered_quantity; -- �����O�󒍐���
        lt_sum_ordered_quantity    := gn_sum_ordered_quantity;        -- �󒍐���
      ELSE
        lt_before_ordered_quantity := NULL; -- �����O�󒍐���
        lt_sum_ordered_quantity    := NULL; -- �󒍐���
      END IF;
    ELSE
      -- �o�^�̏ꍇ
      -- �V�[�P���X�l
      SELECT  xxcoi_lot_reserve_info_s02.NEXTVAL  -- �V�[�P���X�l�i�V�K�󒍔ԍ��j
        INTO  ln_sqs_value_order -- �V�[�P���X�l�i�V�K�󒍔ԍ��j
        FROM  DUAL;
--
      lt_slip_num                := g_upload_data_tab(in_target_loop_cnt).slip_num; -- �`�[No
      lt_order_number            := cv_char_a || TO_CHAR(ln_sqs_value_order);       -- �󒍔ԍ�
      lt_chain_name              := gt_chain_name;                                  -- �`�F�[���X��
      lt_shop_code               := gt_store_code;                                  -- �X�܃R�[�h
      lt_shop_name               := gt_cust_store_name;                             -- �X�ܖ�
      lt_customer_name           := gt_account_name;                                -- �ڋq��
      lt_center_code             := gt_deli_center_code;                            -- �Z���^�[�R�[�h
      lt_center_name             := gt_deli_center_name;                            -- �Z���^�[��
      lt_area_code               := gt_edi_district_code;                           -- �n��R�[�h
      lt_area_name               := gt_edi_district_name;                           -- �n�於��
      lt_item_div_name           := gt_item_div_name;                               -- ���i�敪��
      lt_parent_item_name        := gt_parent_item_name;                            -- �e�i�ږ���
      lt_reg_sale_class_name     := gt_regular_sale_class_name;                     -- ��ԓ����敪��(����)
      lt_delivery_order_edi      := gt_delivery_order;                              -- �z����(EDI)
      lt_header_id               := NULL;                                           -- �󒍃w�b�_ID
      lt_line_id                 := NULL;                                           -- �󒍖���ID
      lt_customer_id             := gt_customer_id;                                 -- �ڋqID
      lt_parent_item_id          := gt_parent_item_id;                              -- �e�i��ID
      lt_resv_tran_type_code     := gt_resv_tran_type_code;                         -- ����������^�C�v�R�[�h
      lt_order_quantity_uom      := NULL;                                           -- �󒍒P��
      lt_before_ordered_quantity := NULL;                                           -- �����O�󒍐���
      lt_sum_ordered_quantity    := NULL;                                           -- �󒍐���
    END IF;
--
    -- ���b�g�ʈ������o�^
    INSERT INTO xxcoi_lot_reserve_info(
      lot_reserve_info_id            -- ���b�g�ʈ������ID
     ,slip_num                       -- �`�[NO
     ,order_number                   -- �󒍔ԍ�
     ,org_id                         -- �c�ƒP��
     ,parent_shipping_status         -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
     ,parent_shipping_status_name    -- �o�׏��X�e�[�^�X���i�󒍔ԍ��P�ʁj
     ,base_code                      -- ���_�R�[�h
     ,base_name                      -- ���_��
     ,whse_code                      -- �ۊǏꏊ�R�[�h
     ,whse_name                      -- �ۊǏꏊ��
     ,location_code                  -- ���P�[�V�����R�[�h
     ,location_name                  -- ���P�[�V��������
     ,shipping_status                -- �o�׏��X�e�[�^�X
     ,shipping_status_name           -- �o�׏��X�e�[�^�X��
     ,chain_code                     -- �`�F�[���X�R�[�h
     ,chain_name                     -- �`�F�[���X��
     ,shop_code                      -- �X�܃R�[�h
     ,shop_name                      -- �X�ܖ�
     ,customer_code                  -- �ڋq�R�[�h
     ,customer_name                  -- �ڋq��
     ,center_code                    -- �Z���^�[�R�[�h
     ,center_name                    -- �Z���^�[��
     ,area_code                      -- �n��R�[�h
     ,area_name                      -- �n�於��
     ,shipped_date                   -- �o�ד�
     ,arrival_date                   -- ����
     ,item_div                       -- ���i�敪
     ,item_div_name                  -- ���i�敪��
     ,parent_item_code               -- �e�i�ڃR�[�h
     ,parent_item_name               -- �e�i�ږ���
     ,item_code                      -- �q�i�ڃR�[�h
     ,item_name                      -- �q�i�ږ���
     ,lot                            -- ���b�g
     ,difference_summary_code        -- �ŗL�L��
     ,case_in_qty                    -- ����
     ,case_qty                       -- �P�[�X��
     ,singly_qty                     -- �o����
     ,summary_qty                    -- ����
     ,regular_sale_class_line        -- ��ԓ����敪(����)
     ,regular_sale_class_name_line   -- ��ԓ����敪��(����)
     ,edi_received_date              -- edi��M��
     ,delivery_order_edi             -- �z����(EDI)
     ,before_ordered_quantity        -- �����O�󒍐���
     ,reserve_performer_code         -- �������s�҃R�[�h
     ,reserve_performer_name         -- �������s�Җ�
     ,mark                           -- �L��
     ,lot_tran_kbn                   -- ���b�g�ʎ�����טA�g�敪
     ,header_id                      -- �󒍃w�b�_ID
     ,line_id                        -- �󒍖���ID
     ,customer_id                    -- �ڋqID
     ,parent_item_id                 -- �e�i��ID
     ,item_id                        -- �q�i��ID
     ,reserve_transaction_type_code  -- ����������^�C�v�R�[�h
     ,order_quantity_uom             -- �󒍒P��
     ,ordered_quantity               -- �󒍐���
     ,short_case_in_qty              -- �����i�s�����j
     ,short_case_qty                 -- �P�[�X���i�s�����j
     ,short_singly_qty               -- �o�����i�s�����j
     ,short_summary_qty              -- ���ʁi�s�����j
     ,created_by                     -- �쐬��
     ,creation_date                  -- �쐬��
     ,last_updated_by                -- �ŏI�X�V��
     ,last_update_date               -- �ŏI�X�V��
     ,last_update_login              -- �ŏI�X�V���O�C��
     ,request_id                     -- �v��ID
     ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id                     -- �R���J�����g�E�v���O����ID
     ,program_update_date            -- �v���O�����X�V��
    )VALUES(
      xxcoi_lot_reserve_info_s01.NEXTVAL                            -- ���b�g�ʈ������ID
     ,lt_slip_num                                                   -- �`�[No
     ,lt_order_number                                               -- �󒍔ԍ�
     ,gn_org_id                                                     -- �c�ƒP��
     ,cv_shipping_status_20                                         -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
     ,gv_shipping_status_name                                       -- �o�׏��X�e�[�^�X���i�󒍔ԍ��P�ʁj
     ,g_upload_data_tab(in_target_loop_cnt).base_code               -- ���_�R�[�h
     ,gt_base_name                                                  -- ���_��
     ,g_upload_data_tab(in_target_loop_cnt).whse_code               -- �ۊǏꏊ�R�[�h
     ,gt_subinv_name                                                -- �ۊǏꏊ��
     ,g_upload_data_tab(in_target_loop_cnt).location_code           -- ���P�[�V�����R�[�h
     ,gt_location_name                                              -- ���P�[�V��������
     ,cv_shipping_status_20                                         -- �o�׏��X�e�[�^�X
     ,gv_shipping_status_name                                       -- �o�׏��X�e�[�^�X��
     ,g_upload_data_tab(in_target_loop_cnt).chain_code              -- �`�F�[���X�R�[�h
     ,lt_chain_name                                                 -- �`�F�[���X��
     ,lt_shop_code                                                  -- �X�܃R�[�h
     ,lt_shop_name                                                  -- �X�ܖ�
     ,g_upload_data_tab(in_target_loop_cnt).customer_code           -- �ڋq�R�[�h
     ,lt_customer_name                                              -- �ڋq��
     ,lt_center_code                                                -- �Z���^�[�R�[�h
     ,lt_center_name                                                -- �Z���^�[��
     ,lt_area_code                                                  -- �n��R�[�h
     ,lt_area_name                                                  -- �n�於��
     ,g_upload_data_tab(in_target_loop_cnt).shipped_date            -- �o�ד�
     ,g_upload_data_tab(in_target_loop_cnt).arrival_date            -- ����
     ,g_upload_data_tab(in_target_loop_cnt).item_div                -- ���i�敪
     ,lt_item_div_name                                              -- ���i�敪��
     ,g_upload_data_tab(in_target_loop_cnt).parent_item_code        -- �e�i�ڃR�[�h
     ,lt_parent_item_name                                           -- �e�i�ږ���
     ,g_upload_data_tab(in_target_loop_cnt).item_code               -- �q�i�ڃR�[�h
     ,gt_child_item_name                                            -- �q�i�ږ���
     ,g_upload_data_tab(in_target_loop_cnt).lot                     -- ���b�g
     ,g_upload_data_tab(in_target_loop_cnt).difference_summary_code -- �ŗL�L��
     ,g_upload_data_tab(in_target_loop_cnt).case_in_qty             -- ����
     ,g_upload_data_tab(in_target_loop_cnt).case_qty                -- �P�[�X��
     ,g_upload_data_tab(in_target_loop_cnt).singly_qty              -- �o����
     ,g_upload_data_tab(in_target_loop_cnt).summary_qty             -- ����
     ,g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line -- ��ԓ����敪(����)
     ,lt_reg_sale_class_name                                        -- ��ԓ����敪��(����)
     ,g_upload_data_tab(in_target_loop_cnt).edi_received_date       -- EDI��M��
     ,lt_delivery_order_edi                                         -- �z����(EDI)
     ,lt_before_ordered_quantity                                    -- �����O�󒍐���
     ,gt_user_name                                                  -- �������s�҃R�[�h
     ,gt_per_information18 || cv_space || gt_per_information19      -- �������s�Җ�
     ,g_upload_data_tab( in_target_loop_cnt ).mark                  -- �L��
     ,cv_lot_tran_kbn_0                                             -- ���b�g�ʎ�����טA�g�敪
     ,lt_header_id                                                  -- �󒍃w�b�_ID
     ,lt_line_id                                                    -- �󒍖���ID
     ,lt_customer_id                                                -- �ڋqID
     ,lt_parent_item_id                                             -- �e�i��ID
     ,gt_child_item_id                                              -- �q�i��ID
     ,lt_resv_tran_type_code                                        -- ����������^�C�v�R�[�h
     ,lt_order_quantity_uom                                         -- �󒍒P��
     ,lt_sum_ordered_quantity                                       -- �󒍐���
     ,0                                                             -- �����i�s�����j
     ,0                                                             -- �P�[�X���i�s�����j
     ,0                                                             -- �o�����i�s�����j
     ,0                                                             -- ���ʁi�s�����j
     ,cn_created_by                                                 -- �쐬��
     ,cd_creation_date                                              -- �쐬��
     ,cn_last_updated_by                                            -- �ŏI�X�V��
     ,cd_last_update_date                                           -- �ŏI�X�V��
     ,cn_last_update_login                                          -- �ŏI�X�V���O�C��
     ,cn_request_id                                                 -- �v��ID
     ,cn_program_application_id                                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,cn_program_id                                                 -- �R���J�����g�E�v���O����ID
     ,cd_program_update_date                                        -- �v���O�����X�V��
    );
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
  END ins_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : check_reserve_qty
   * Description      : �������ύX�`�F�b�N(A-17)
   ***********************************************************************************/
  PROCEDURE check_reserve_qty(
    in_target_loop_cnt    IN  NUMBER,       --   �����Ώۍs
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_reserve_qty'; -- �v���O������
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
    lv_key_data     VARCHAR2(200); -- �L�[���
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
    -- ���[�J���ϐ�������
    lv_key_data         := NULL; -- �L�[���
--
    -- �P�[�X���A�o�����A���ʂ̂����ꂩ���ύX���ꂽ�ꍇ
    IF ( (gn_sum_before_case_qty <>  gn_sum_case_qty)         -- �P�[�X��
      OR (gn_sum_before_singly_qty <>  gn_sum_singly_qty)     -- �o����
      OR (gn_sum_before_summary_qty <>  gn_sum_summary_qty) ) -- ����
    THEN
      -- �L�[���i�󒍔ԍ��A�e�i�ځj���쐬
      lv_key_data := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10613
                     ) || cv_colon || g_upload_data_tab(in_target_loop_cnt).order_number || cv_csv_delimiter || -- �󒍔ԍ�
                     xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10614
                     ) || cv_colon || g_upload_data_tab(in_target_loop_cnt).parent_item_code -- �e�i��
                     ;
      -- �������ύX�`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10580, -- �������ύX�`�F�b�N�G���[
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => lv_key_data -- �L�[���
                   );
      -- �G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- �w�b�_�G���[�t���O���X�V
      gb_header_err_flag := TRUE;
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
  END check_reserve_qty;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       --   �t�@�C��ID
    iv_file_format  IN   VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
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
    -- ���[�v���̃J�E���g
    ln_file_if_loop_cnt  NUMBER; -- �t�@�C��IF���[�v�J�E���^
    ln_target_loop_cnt   NUMBER; -- �����������f�[�^���[�v�J�E���^
    ln_line_err_cnt      NUMBER; -- ����L�[���[�v���ł̖��׃G���[����
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
    gn_target_cnt        := 0; -- �Ώی���
    gn_normal_cnt        := 0; -- ���팏��
    gn_error_cnt         := 0; -- �G���[����
    gn_warn_cnt          := 0; -- �X�L�b�v����
    gn_same_key_count    := 0; -- ����L�[���[�v�J�E���^
    gb_update_flag       := FALSE; -- TRUE:�X�V,FALSE:�o�^
    gb_header_err_flag   := FALSE; -- TRUE:�G���[,FALSE:����
    gb_line_err_flag     := FALSE; -- TRUE:�G���[,FALSE:����
    gb_get_info_err_flag := FALSE; -- TRUE:�G���[,FALSE:����
    gb_err_flag          := FALSE; -- TRUE:�G���[,FALSE:����
    gv_key_data          := NULL;  -- �L�[���
--
    -- �o�׏��X�e�[�^�X��
    gv_shipping_status_name:= xxccp_common_pkg.get_msg(
                                iv_application => cv_msg_kbn_coi,   -- �A�v���P�[�V�����Z�k��
                                iv_name        => cv_msg_coi_10629  -- '������'
                              );
--
    -- ���[�J���ϐ��̏�����
    ln_file_if_loop_cnt := 0; -- �t�@�C��IF���[�v�J�E���^
    ln_target_loop_cnt  := 0; -- �����������f�[�^���[�v�J�E���^
    ln_line_err_cnt     := 0; -- ����L�[���[�v���ł̖��׃G���[����
--
    -- ============================================
    -- A-1�D��������
    -- ============================================
    init(
       in_file_id        -- �t�@�C��ID
      ,iv_file_format    -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�DIF�f�[�^�擾
    -- ============================================
    get_if_data(
       in_file_id        -- �t�@�C��ID
      ,iv_file_format    -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�DIF�f�[�^�폜
    -- ============================================
    delete_if_data(
       in_file_id        -- �t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ����I���̏ꍇ�̓R�~�b�g
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���A�b�v���[�hIF���[�v
    <<file_if_loop>>
    --�P�s�ڂ̓J�����s�ׁ̈A�Q�s�ڂ��珈������
    FOR ln_file_if_loop_cnt IN 2 .. gt_file_line_data_tab.COUNT LOOP
      -- ============================================
      -- A-4�D�A�b�v���[�h�t�@�C�����ڕ���
      -- ============================================
      divide_item(
         ln_file_if_loop_cnt -- IF���[�v�J�E���^
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-5�D�����������A�b�v���[�h�ꎞ�\�쐬
      -- ============================================
      ins_upload_wk(
         in_file_id          -- �t�@�C��ID
        ,ln_file_if_loop_cnt -- IF���[�v�J�E���^
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP file_if_loop;
--
    -- ============================================
    -- A-6�D�����������A�b�v���[�h�ꎞ�\�擾
    -- ============================================
    get_upload_wk(
       in_file_id        -- �t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����������f�[�^���[�v�J�E���^�̐ݒ�
    ln_target_loop_cnt := 1;
--
    -- �����������f�[�^���[�v
    <<target_loop>>
    LOOP
      -- �����������f�[�^�̐��������[�v
      EXIT target_loop WHEN ln_target_loop_cnt > g_upload_data_tab.COUNT;
--
      -- �ϐ�������
      gn_same_key_count    := 0;      -- ����L�[���[�v��
      ln_line_err_cnt      := 0;      -- ����L�[���[�v���ł̖��׃G���[����
      gb_header_err_flag   := FALSE;  -- �w�b�_�G���[�t���O
      gb_line_err_flag     := FALSE;  -- ���׃G���[�t���O
      gb_get_info_err_flag := FALSE;  -- �󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[�t���O
      gb_update_flag       := FALSE;  -- �X�V�t���O
--
      -- �X�V�t���O�̐ݒ�
      -- �����������f�[�^�̎󒍔ԍ���NULL�ȊO�̏ꍇ�͍X�V
      IF ( g_upload_data_tab(ln_target_loop_cnt).order_number IS NOT NULL ) THEN
        gb_update_flag := TRUE;
      END IF;
--
      -- �L�[���i�s�ԍ��A�󒍔ԍ��A�e�i�ځj���쐬�i�G���[���b�Z�[�W�o�͗p�j
      gv_key_data := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10612
                     ) || cv_colon || g_upload_data_tab(ln_target_loop_cnt).row_number || cv_csv_delimiter || -- �s�ԍ�
                     xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10613
                     ) || cv_colon || g_upload_data_tab(ln_target_loop_cnt).order_number || cv_csv_delimiter || -- �󒍔ԍ�
                     xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10614
                     ) || cv_colon || g_upload_data_tab(ln_target_loop_cnt).parent_item_code -- �e�i��
      ;
--
      -- �X�V�̏ꍇ
      IF ( gb_update_flag = TRUE ) THEN
        -- ============================================
        -- A-7�D�󒍔ԍ��A�e�i�ڑ��݃`�F�b�N
        -- ============================================
        check_item_value(
           ln_target_loop_cnt  -- �����Ώۍs
          ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- A-7�Ŏ󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[���������Ă��Ȃ��ꍇ
        IF ( gb_get_info_err_flag = FALSE ) THEN
          -- ============================================
          -- A-8�D�����O�������擾
          -- ============================================
          get_reserve_info(
             ln_target_loop_cnt  -- �����Ώۍs
            ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-9�D�������폜
          -- ============================================
          del_reserve_info(
             ln_target_loop_cnt  -- �����Ώۍs
            ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      -- �󒍔ԍ��A�e�i�ړ���L�[���[�v
      <<same_key_loop>>
      LOOP
        -- ����L�[���[�v�񐔂����Z
        gn_same_key_count := gn_same_key_count + 1;
--
        -- A-7�Ŏ󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[���������Ă��Ȃ��ꍇ
        IF ( gb_get_info_err_flag = FALSE ) THEN
--
          --�X�V�̏ꍇ�i�����������f�[�^�̎󒍔ԍ���NULL�ȊO�j
          IF ( gb_update_flag = TRUE ) THEN
            -- �w�b�_�G���[�A���׃G���[���������Ă��Ȃ��ꍇ
            IF ( (gb_header_err_flag = FALSE)
              AND (gb_line_err_flag = FALSE) )
            THEN
              -- ============================================
              -- A-10�D���ڕύX�`�F�b�N
              -- ============================================
              check_item_changes(
                 ln_target_loop_cnt  -- �����Ώۍs
                ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END IF;
--
          -- �w�b�_�G���[�A���׃G���[���������Ă��Ȃ��ꍇ
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-11�D�e��R�[�h�l�`�F�b�N
            -- ============================================
            check_code_value(
               ln_target_loop_cnt  -- �����Ώۍs
              ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- �w�b�_�G���[�A���׃G���[���������Ă��Ȃ��ꍇ
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-12�D���ڊ֘A�`�F�b�N
            -- ============================================
            check_item_validation(
               ln_target_loop_cnt  -- �����Ώۍs
              ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- �w�b�_�G���[�A���׃G���[���������Ă��Ȃ��ꍇ
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-13�D�P�[�X���A�o�����`�F�b�N
            -- ============================================
            check_cese_singly_qty(
               ln_target_loop_cnt  -- �����Ώۍs
              ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- �w�b�_�G���[�A���׃G���[���������Ă��Ȃ��ꍇ
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-14�D�����\�`�F�b�N
            -- ============================================
            chack_reserve_availablity(
               ln_target_loop_cnt  -- �����Ώۍs
              ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- �w�b�_�G���[�A���׃G���[���������Ă��Ȃ��ꍇ
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-15�D���s�ҏ��擾
            -- ============================================
            get_user_info(
               ln_target_loop_cnt  -- �����Ώۍs
              ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-16�D�������o�^
            -- ============================================
            ins_reserve_info(
               ln_target_loop_cnt  -- �����Ώۍs
              ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode = cv_status_normal ) THEN
              -- ���������̃J�E���g
              gn_normal_cnt := gn_normal_cnt + 1;
            ELSE
              RAISE global_process_expt;
            END IF;
          END IF;
--
        END IF;
--
        -- ���׃G���[�����������ꍇ
        IF ( gb_line_err_flag = TRUE ) THEN
          ln_line_err_cnt := ln_line_err_cnt + 1; -- ���׃G���[����
        END IF;
        -- ���׃G���[�t���O������
        gb_line_err_flag       := FALSE; -- ���׃G���[�t���O
--
        -- ���[�v�ϐ��̉��Z
        ln_target_loop_cnt := ln_target_loop_cnt + 1;
--
        -- �f�[�^�I�[�̏ꍇ�̓��[�v�𔲂���
        EXIT same_key_loop WHEN ln_target_loop_cnt > g_upload_data_tab.COUNT;
--
        -- �L�[���قȂ�ꍇ�A�܂��͎󒍔ԍ���NULL�̏ꍇ�̓��[�v�𔲂���
        IF ( ((g_upload_data_tab(ln_target_loop_cnt - 1).order_number
              <> g_upload_data_tab(ln_target_loop_cnt).order_number) -- �󒍔ԍ�
           OR (g_upload_data_tab(ln_target_loop_cnt - 1).parent_item_code
                <> g_upload_data_tab(ln_target_loop_cnt).parent_item_code)) -- �e�i��
          OR (g_upload_data_tab(ln_target_loop_cnt).order_number IS NULL) )
        THEN
          EXIT same_key_loop;
        END IF;
--
      END LOOP same_key_loop;
--
      -- �X�V�̏ꍇ
      IF ( gb_update_flag = TRUE ) THEN
        -- A-7�Ŏ󒍔ԍ��A�e�i�ڑ��݃`�F�b�N�G���[���������Ă��Ȃ��A�����׃G���[���������Ă��Ȃ��ꍇ
        IF ( (gb_get_info_err_flag = FALSE)
          AND (ln_line_err_cnt = 0) )
        THEN
--
          -- ============================================
          -- A-17�D�������ύX�`�F�b�N
          -- ============================================
          check_reserve_qty(
             ln_target_loop_cnt - 1 -- �����Ώۍs
            ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      -- �G���[�����̐ݒ�
      IF ( gb_header_err_flag = TRUE ) THEN
        -- �w�b�_�G���[���������Ă���ꍇ�A����L�[���[�v�񐔁i���ׂ̌����j���J�E���g
        gn_error_cnt := gn_error_cnt + gn_same_key_count;
      ELSE
        -- �w�b�_�G���[���������Ă��Ȃ��ꍇ�A����L�[���[�v���ł̖��׃G���[�������J�E���g
        gn_error_cnt := gn_error_cnt + ln_line_err_cnt;
      END IF;
--
    END LOOP target_loop;
--
    -- �G���[���R�[�h�����݂���ꍇ
    IF ( gn_error_cnt <> 0 ) THEN
      gb_err_flag := TRUE; -- �z����G���[�t���O:TRUE
      ov_retcode := cv_status_error; -- �I���X�e�[�^�X�F�ُ�I��
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
    iv_file_id       IN    VARCHAR2,        --   1.�t�@�C��ID(�K�{)
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
       TO_NUMBER(iv_file_id) -- 1.�t�@�C��ID
      ,iv_file_format        -- 2.�t�@�C���t�H�[�}�b�g
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
    IF ( gb_err_flag = TRUE ) THEN
      gn_normal_cnt := 0; -- ��������
      gn_warn_cnt  := ( gn_target_cnt - gn_error_cnt ); -- �X�L�b�v����
    -- �z��O�G���[�̏ꍇ
    ELSIF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0; -- �Ώی���
      gn_normal_cnt := 0; -- ��������
      gn_error_cnt  := 1; -- �G���[����
      gn_warn_cnt   := 0; -- �X�L�b�v����
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_ccp_90003
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
END XXCOI016A08C;
/
