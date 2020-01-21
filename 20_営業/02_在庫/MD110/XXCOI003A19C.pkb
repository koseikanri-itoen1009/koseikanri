CREATE OR REPLACE PACKAGE BODY APPS.XXCOI003A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCOI003A19C(body)
 * Description      : �o�Ɉ˗�CSV�A�b�v���[�h�i�c�Ǝԁj
 * MD.050           : �o�Ɉ˗�CSV�A�b�v���[�h�i�c�Ǝԁj MD050_COI_003_A19
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                                       (A-1)
 *  get_if_data                  IF�f�[�^�擾                                   (A-2)
 *  delete_if_data               IF�f�[�^�폜                                   (A-3)
 *  divide_item                  �A�b�v���[�h�t�@�C�����ڕ���                   (A-4)
 *  quantity_check               ���ʃ`�F�b�N                                   (A-5)
 *  err_check                    �G���[�`�F�b�N                                 (A-5)
 *  cre_inv_transactions         ���o�ɏ��̍쐬                               (A-6)
 *  cre_lot_transactions         ���b�g�ʎ�����ׂ̍쐬�A���b�g�ʎ莝���ʂ̕ύX (A-7)
 *
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/11/15    1.0   T.Nakano         �V�K�쐬
 *  2020/01/16    1.1   H.Sasaki         E_�{�ғ�_15992 ����w�E�Ή��i�`�F�b�N�ǉ��F��v���ԁA����0�j
 *  2020/01/21    1.2   T.Nakano         E_�{�ғ�_16191 �o�Ɉ˗��A�b�v���[�h��Q�Ή�
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI003A19C'; -- �p�b�P�[�W��
--
  ct_language           CONSTANT fnd_lookup_values.language%TYPE  := USERENV('LANG'); -- ����
--
  cv_csv_delimiter            CONSTANT VARCHAR2(1)  := ',';   -- �J���}
  cv_colon                    CONSTANT VARCHAR2(2)  := '�F';  -- �R����
  cv_space                    CONSTANT VARCHAR2(2)  := ' ';   -- ���p�X�y�[�X
  cv_const_y                  CONSTANT VARCHAR2(1)  := 'Y';   -- 'Y'
  cv_const_n                  CONSTANT VARCHAR2(1)  := 'N';   -- 'N'
--
  cv_subinventory_class_1     CONSTANT VARCHAR2(1)  := '1';   -- �ۊǏꏊ�敪:�q��
--
  cv_location_type_1          CONSTANT VARCHAR2(1)  := '1';   -- ���P�[�V�����^�C�v:�ʏ�
  cv_location_type_2          CONSTANT VARCHAR2(1)  := '2';   -- ���P�[�V�����^�C�v:�D��
-- V1.2 2020/01/21 T.Nakano MOD START --
  cv_location_type_3          CONSTANT VARCHAR2(1)  := '3';   -- ���P�[�V�����^�C�v:�ꎞ�ۊ�
  cv_9                        CONSTANT VARCHAR2(1)  := '9';   -- ���P�[�V�����^�C�v�D��̃_�~�[�l
  cv_8                        CONSTANT VARCHAR2(1)  := '8';   -- ���P�[�V�����^�C�v�ꎞ�ۊǂ̃_�~�[�l
-- V1.2 2020/01/21 T.Nakano MOD END ----
  cn_slip_no                  CONSTANT NUMBER       := 1;     -- �`�[�ԍ�
  cn_invoice_date             CONSTANT NUMBER       := 2;     -- �`�[���t
  cn_outside_base_code        CONSTANT NUMBER       := 3;     -- �o�ɑ����_�R�[�h
  cn_outside_subinv_code      CONSTANT NUMBER       := 4;     -- �o�ɑ��ۊǏꏊ
  cn_inside_base_code         CONSTANT NUMBER       := 5;     -- ���ɑ����_�R�[�h
  cn_inside_subinv_code       CONSTANT NUMBER       := 6;     -- ���ɑ��ۊǏꏊ
  cn_parent_item_code         CONSTANT NUMBER       := 7;     -- �e�i��
  cn_child_item_code          CONSTANT NUMBER       := 8;     -- �q�i��
  cn_lot                      CONSTANT NUMBER       := 9;     -- �ܖ�����
  cn_difference_summary_code  CONSTANT NUMBER       := 10;    -- �ŗL�L��
  cn_location_code            CONSTANT NUMBER       := 11;    -- ���P�[�V����
  cn_case_qty                 CONSTANT NUMBER       := 12;    -- �P�[�X��
  cn_singly_qty               CONSTANT NUMBER       := 13;    -- �o����
  cn_check_flg                CONSTANT NUMBER       := 14;    -- �`�F�b�N�t���O
  cn_c_header                 CONSTANT NUMBER       := 14;    -- CSV�t�@�C�����ڐ��i�擾�Ώہj
  cn_c_header_all             CONSTANT NUMBER       := 14;    -- CSV�t�@�C�����ڐ��i�S���ځj
--
  cn_zero                     CONSTANT NUMBER       := 0;     -- 0
--
  cv_segment1_1               CONSTANT VARCHAR2(1)  := '1';   -- �J�e�S���R�[�h
  cv_segment1_2               CONSTANT VARCHAR2(1)  := '2';   -- �J�e�S���R�[�h
  cv_record_type              CONSTANT VARCHAR2(2)  := '30';  -- ���R�[�h��ʁF���o��
  cv_invoice_type             CONSTANT VARCHAR2(1)  := '1';   -- �`�[�敪�F�q�ɂ���c�ƎԂ�
  cv_invoice_type2            CONSTANT VARCHAR2(1)  := '9';   -- �`�[�敪�F�����_�֏o��
  cv_department_flag          CONSTANT VARCHAR2(2)  := '99';  -- �S�ݓX�t���O�F�_�~�[
  cv_program_div_2            CONSTANT VARCHAR2(1)  := '2';   -- ���o�ɃW���[�i�������敪�F���_�ԑq��
  cv_program_div_5            CONSTANT VARCHAR2(1)  := '5';   -- ���o�ɃW���[�i�������敪�F���̑����o�Ɂi����VD��[�܂ށj
  cv_transaction_type_20      CONSTANT VARCHAR2(2)  := '20';  -- ����^�C�v�R�[�h�F�q��
  cv_sign_div_0               CONSTANT VARCHAR2(1)  := '0';   -- �����敪(0:�o��)
  cv_program_div_0            CONSTANT VARCHAR2(1)  := '0';   -- ���o�ɃW���[�i�������敪(0:�����ΏۊO)
  cv_status_1                 CONSTANT VARCHAR2(1)  := '1';   -- �����X�e�[�^�X(1:������)
  cv_status_0                 CONSTANT VARCHAR2(1)  := '0';   -- �����X�e�[�^�X(0:������)
  cv_source_code              CONSTANT VARCHAR2(12) := 'XXCOI003A19C';  -- �\�[�X�R�[�h
--
  cv_column_name1             CONSTANT VARCHAR2(12) :=  '�`�[�ԍ�';         -- �K�{���ږ�1
  cv_column_name2             CONSTANT VARCHAR2(12) :=  '�`�[���t';         -- �K�{���ږ�2
  cv_column_name3             CONSTANT VARCHAR2(24) :=  '�o�ɑ����_�R�[�h'; -- �K�{���ږ�3
  cv_column_name4             CONSTANT VARCHAR2(21) :=  '�o�ɑ��ۊǏꏊ';   -- �K�{���ږ�4
  cv_column_name5             CONSTANT VARCHAR2(24) :=  '���ɑ����_�R�[�h'; -- �K�{���ږ�5
  cv_column_name6             CONSTANT VARCHAR2(21) :=  '���ɑ��ۊǏꏊ';   -- �K�{���ږ�6
--
  cv_key_data                 CONSTANT VARCHAR2(12) :=  'CSV�s��:';         -- �L�[���
--
  cv_api_belogin              CONSTANT VARCHAR2(100) := 'GET_BELONGING_BASE';    -- �g�[�N���uAPI�Z�b�g���e�v
--
  -- �o�̓^�C�v
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';      -- �o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';         -- ���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- �����}�X�N
  cv_date_format        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- ���t����
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI'; -- �A�h�I���F�݌ɗ̈�
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)   := 'XXCOS'; -- �A�h�I���F�̔��̈�
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP'; -- ���ʂ̃��b�Z�[�W
--
  -- �v���t�@�C��
  cv_inv_org_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';     -- �݌ɑg�D�R�[�h
  cv_goods_product_cls  CONSTANT VARCHAR2(30)  := 'XXCOI1_GOODS_PRODUCT_CLASS';   -- ���i���i�敪�J�e�S���Z�b�g��
--
  -- �Q�ƃ^�C�v
  cv_type_upload_obj    CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';       -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_type_bargain_class CONSTANT VARCHAR2(30)  := 'XXCOI1_OTHER_BASE_INOUT_CAR';  -- �����_�c�Ǝԓ��o�ɃZ�L�����e�B�}�X�^�i�o�Ɉ˗��p�j
--
  -- ����R�[�h
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ���b�Z�[�W��
  cv_msg_ccp_90000      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
  cv_msg_ccp_90002      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
  cv_msg_ccp_90003      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';   -- �X�L�b�v�������b�Z�[�W
--
  cv_msg_coi_00005      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';   -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_coi_00006      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';   -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_coi_00011      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';   -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_coi_00028      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';   -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_cos_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';   -- ���b�N�G���[
  cv_msg_coi_10611      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10611';   -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
  cv_msg_coi_10149      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10149';   -- ���̓p�����[�^�K�{�`�F�b�N�G���[
  cv_msg_coi_10212      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10212';   -- �c�ƎԕۊǏꏊ�̎擾�G���[
  cv_msg_coi_10206      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10206';   -- �ۊǏꏊ�̎擾�G���[
  cv_msg_coi_10132      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10132';   -- �i�ڃ}�X�^�擾�G���[
  cv_msg_coi_10227      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10227';   -- �i�ڃ}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10276      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10276';   -- ���ɑ��ۊǏꏊ�擾�G���[���b�Z�[�W
  cv_msg_coi_10277      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10277';   -- ���ɑ����_�擾�G���[���b�Z�[�W
  cv_msg_coi_10278      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10278';   -- �o�ɑ��ۊǏꏊ�擾�G���[���b�Z�[�W
  cv_msg_coi_10279      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10279';   -- �o�ɑ����_�擾�G���[���b�Z�[�W
  cv_msg_coi_10294      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10294';   -- ���o�Ɉꎞ�\ID�G���[���b�Z�[�W
  cv_msg_coi_10295      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10295';   -- ��ʓ��͗p�w�b�_ID�G���[���b�Z�[�W
  cv_msg_coi_10701      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10701';   -- HHT���o�Ɉꎞ�\�o�^�G���[���b�Z�[�W
  cv_msg_coi_10489      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10489';   -- ���b�g�ʎ�����׍쐬�G���[
  cv_msg_coi_10490      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10490';   -- ���b�g�ʎ莝���ʔ��f�G���[
  cv_msg_cos_11294      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11294';   -- CSV�t�@�C�����擾�G���[
  cv_msg_cos_00013      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';   -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_coi_10633      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10633';   -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_cos_11295      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';   -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
  cv_msg_coi_10593      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10593';   -- �����\���Z�o�G���[���b�Z�[�W���b�Z�[�W
  cv_msg_coi_10232      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10232';   -- �R���J�����g���̓p�����[�^
  cv_msg_coi_10284      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10284';   -- �f�t�H���g�`�[No�擾�G���[���b�Z�[�W
  cv_msg_coi_10665      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10665';   -- �����ϐ����߃G���[���b�Z�[�W
  cv_msg_coi_10680      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10680';   -- �����擾�G���[���b�Z�[�W
  cv_msg_coi_10739      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10739';   -- ���ɑ����C���q�ɊǗ��ΏۊO�G���[
  cv_msg_coi_10740      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10740';   -- �o�ɑ��q�ɊǗ��ΏۃG���[
  cv_msg_coi_10741      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10741';   -- �Z�L�����e�B�}�X�^���o�^�G���[
  cv_msg_coi_10742      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10742';   -- ���ʃ`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_10743      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10743';   -- ���b�g�ʎ�����׃f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_coi_10744      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10744';   -- �o�ɑ����_�Ɠ��ɑ����_�̈�v�G���[
  cv_msg_coi_10745      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10745';   -- ���b�g�ʈ����\���ʈꎞ�\�o�^�G���[���b�Z�[�W
  cv_msg_coi_10746      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10746';   -- ���b�g�ʈ����\���ʈꎞ�\�X�V�G���[���b�Z�[�W
  cv_msg_coi_10747      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10747';   -- �A�b�v���[�h����0�����b�Z�[�W
  cv_msg_coi_10748      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10748';   -- �o�^�`�[�ԍ����b�Z�[�W
  cv_msg_coi_10749      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10749';   -- �o�Ɉ˗�CSV�G���[���b�Z�[�W
  cv_msg_coi_00010      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00010';   -- API�G���[���b�Z�[�W
--
  cv_tkn_cos_11282      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11282';   -- �t�@�C���A�b�v���[�hIF
  cv_tkn_coi_10634      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10634';   -- �t�@�C���A�b�v���[�hIF
  cv_tkn_cos_10628      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10628';   -- �q�i�ڃR�[�h
  cv_tkn_cos_10496      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10496';   -- �e�i�ڃR�[�h
--  V1.1 Added START
  cv_msg_coi_10226      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10226';   -- ���{�����Z�G���[
  cv_msg_coi_00026      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00026';   -- �݌ɉ�v���ԃX�e�[�^�X�擾�G���[
  cv_msg_coi_10231      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10231';   -- �݌ɉ�v���ԃ`�F�b�N�G���[
--  V1.1 Added END
--
  -- �g�[�N����
  cv_tkn_pro_tok          CONSTANT VARCHAR2(15) := 'PRO_TOK';         -- �v���t�@�C��
  cv_tkn_org_code_tok     CONSTANT VARCHAR2(15) := 'ORG_CODE_TOK';    -- �݌ɑg�D�R�[�h
  cv_tkn_format_ptn       CONSTANT VARCHAR2(15) := 'FORMAT_PTN';      -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_file_name        CONSTANT VARCHAR2(15) := 'FILE_NAME';       -- �t�@�C����
  cv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';           -- �e�[�u����
  cv_tkn_file_upld_name   CONSTANT VARCHAR2(15) := 'FILE_UPLD_NAME';  -- �t�@�C���A�b�v���[�h����
  cv_tkn_key_data         CONSTANT VARCHAR2(15) := 'KEY_DATA';        -- ����ł���L�[���e���R�����g�����ăZ�b�g���܂��B
  cv_tkn_table_name       CONSTANT VARCHAR2(15) := 'TABLE_NAME';      -- �e�[�u����
  cv_tkn_param            CONSTANT VARCHAR2(15) := 'PARAM';           -- �p�����[�^��
  cv_tkn_param2           CONSTANT VARCHAR2(15) := 'PARAM2';          -- �p�����[�^��2
  cv_tkn_param3           CONSTANT VARCHAR2(15) := 'PARAM3';          -- �p�����[�^��3
  cv_tkn_param4           CONSTANT VARCHAR2(15) := 'PARAM4';          -- �p�����[�^��4
  cv_tkn_param5           CONSTANT VARCHAR2(15) := 'PARAM5';          -- �p�����[�^��5
  cv_tkn_param6           CONSTANT VARCHAR2(15) := 'PARAM6';          -- �p�����[�^��6
  cv_tkn_param7           CONSTANT VARCHAR2(15) := 'PARAM7';          -- �p�����[�^��7
  cv_tkn_param8           CONSTANT VARCHAR2(15) := 'PARAM8';          -- �p�����[�^��8
  cv_tkn_param9           CONSTANT VARCHAR2(15) := 'PARAM9';          -- �p�����[�^��9
  cv_tkn_dept_code        CONSTANT VARCHAR2(15) := 'DEPT_CODE';       -- ���_�R�[�h
  cv_tkn_whouse_code      CONSTANT VARCHAR2(15) := 'WHOUSE_CODE';     -- �ۊǏꏊ�R�[�h
  cv_tkn_item_code        CONSTANT VARCHAR2(15) := 'ITEM_CODE';       -- �i�ڃR�[�h
  cv_tkn_record_type      CONSTANT VARCHAR2(15) := 'RECORD_TYPE';     -- ���R�[�h���
  cv_tkn_invoice_type     CONSTANT VARCHAR2(15) := 'INVOICE_TYPE';    -- �`�[�敪
  cv_tkn_department_flag  CONSTANT VARCHAR2(15) := 'DEPARTMENT_FLAG'; -- �S�ݓX�t���O
  cv_tkn_base_code        CONSTANT VARCHAR2(15) := 'BASE_CODE';       -- ���_�R�[�h
  cv_tkn_code             CONSTANT VARCHAR2(15) := 'CODE';            -- ���ɑ��R�[�h
  cv_tkn_transaction_id   CONSTANT VARCHAR2(15) := 'TRANSACTION_ID';  -- ���ID
  cv_tkn_err_msg          CONSTANT VARCHAR2(15) := 'ERR_MSG';         -- �G���[���b�Z�[�W
  cv_tkn_data             CONSTANT VARCHAR2(15) := 'DATA';            -- �f�[�^
  cv_tkn_file_id          CONSTANT VARCHAR2(15) := 'FILE_ID';         -- �t�@�C��ID
  cv_tkn_api_name         CONSTANT VARCHAR2(15) := 'API_NAME';        -- API��
--  V1.1 Added START
  cv_tkn_target_date      CONSTANT VARCHAR2(15) := 'TARGET_DATE';     -- �Ώۓ�
  cv_tkn_invoice_date     CONSTANT VARCHAR2(15) := 'INVOICE_DATE';    -- �`�[���t
--  V1.1 Added END
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
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;   -- 1�����z��
  g_if_data_tab             g_var_data_ttype;                                     -- �����p�ϐ�
--
  -- ���b�g���f�[�^�i�[�p
  TYPE g_lot_info_rtype IS RECORD(
      slip_no                 VARCHAR2(100)                                       -- �`�[�ԍ�
     ,invoice_date            xxcoi_lot_transactions.transaction_date%TYPE        -- �`�[���t
     ,csv_no                  NUMBER                                              -- CSV�̍s��
     ,lot                     xxcoi_lot_transactions.lot%TYPE                     -- ���b�g�i�ܖ������j
     ,difference_summary_code xxcoi_lot_transactions.difference_summary_code%TYPE -- �ŗL�L��
     ,location_code           xxcoi_lot_transactions.location_code%TYPE           -- ���P�[�V����
     ,parent_item_id          xxcoi_lot_transactions.parent_item_id%TYPE          -- �e�i��ID
     ,parent_item_code        xxcoi_lot_onhand_quantites_v.parent_item_code%TYPE  -- �e�i��
     ,child_item_id           xxcoi_lot_transactions.child_item_id%TYPE           -- �q�i��ID
     ,child_item_code         xxcoi_lot_onhand_quantites_v.item_code%TYPE         -- �q�i��
     ,case_qty                xxcoi_lot_transactions.case_qty%TYPE                -- �P�[�X��
     ,singly_qty              xxcoi_lot_transactions.singly_qty%TYPE              -- �o����
     ,summary_quantity        xxcoi_lot_transactions.summary_qty%TYPE             -- �������
     ,case_in_quantity        xxcoi_lot_transactions.case_in_qty%TYPE             -- ����
     ,outside_base_code       xxcoi_lot_transactions.base_code%TYPE               -- �o�ɑ����_�R�[�h
     ,via_subinv_code         xxcoi_lot_transactions.transfer_subinventory%TYPE   -- �]����ۊǏꏊ�R�[�h
     ,program_div             xxcoi_hht_ebs_convert_v.program_div%TYPE            -- ���o�ɃW���[�i�������敪
     ,consume_vd_flag         xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE        -- ����VD��[�Ώۃt���O
     ,start_subinv_code       xxcoi_lot_transactions.subinventory_code%TYPE       -- �o�ɑ��ۊǏꏊ�R�[�h
     ,transaction_id          xxcoi_lot_transactions.relation_key%TYPE            -- ���o�Ɉꎞ�\ID
     ,inside_warehouse_code   xxcoi_lot_transactions.inside_warehouse_code%TYPE   -- �]����q��
     ,invoice_no              xxcoi_hht_inv_transactions.invoice_no%TYPE          -- �`�[No
    );
  -- ���b�g���f�[�^���R�[�h�z��
  TYPE g_lot_info_ttype IS TABLE OF g_lot_info_rtype INDEX BY BINARY_INTEGER;
--
  -- ���o�ɏ��f�[�^�i�[�p
  TYPE g_inout_info_rtype IS RECORD(
      slip_no                     VARCHAR2(100)                                             -- �`�[�ԍ�
     ,invoice_date                xxcoi_hht_inv_transactions.invoice_date%TYPE              -- �`�[���t
     ,parent_item_id              xxcoi_hht_inv_transactions.inventory_item_id%TYPE         -- �e�i��ID
     ,parent_item_code            xxcoi_lot_onhand_quantites_v.parent_item_code%TYPE        -- �e�i��
     ,outside_subinv_code         xxcoi_hht_inv_transactions.outside_code%TYPE              -- �o�ɑ��R�[�h
     ,inside_subinv_code          xxcoi_hht_inv_transactions.inside_code%TYPE               -- ���ɑ��R�[�h
     ,case_qty                    xxcoi_hht_inv_transactions.case_quantity%TYPE             -- �P�[�X��
     ,singly_qty                  xxcoi_hht_inv_transactions.quantity%TYPE                  -- �o����
     ,case_in_quantity            xxcoi_hht_inv_transactions.case_in_quantity%TYPE          -- ����
     ,outside_base_code           xxcoi_hht_inv_transactions.base_code%TYPE                 -- �o�ɑ����_�R�[�h
     ,inside_base_code            xxcoi_hht_inv_transactions.base_code%TYPE                 -- ���ɑ����_�R�[�h
     ,chg_start_subinv_code       mtl_secondary_inventories.secondary_inventory_name%TYPE   -- �o�ɑ��ۊǏꏊ�R�[�h�i�����_�֏o�Ɂj
     ,chg_via_subinv_code         mtl_secondary_inventories.secondary_inventory_name%TYPE   -- ���ɑ��ۊǏꏊ�R�[�h�i�����_�֏o�Ɂj
     ,chg_start_base_code         mtl_secondary_inventories.attribute7%TYPE                 -- �o�ɑ����_�R�[�h�i�����_�֏o�Ɂj
     ,chg_via_base_code           mtl_secondary_inventories.attribute7%TYPE                 -- ���ɑ����_�R�[�h�i�����_�֏o�Ɂj
     ,chg_outside_subinv_conv     xxcoi_hht_ebs_convert_v.outside_subinv_code_conv_div%TYPE -- �o�ɑ��ۊǏꏊ�ϊ��敪�i�����_�֏o�Ɂj
     ,chg_inside_subinv_conv      xxcoi_hht_ebs_convert_v.inside_subinv_code_conv_div%TYPE  -- ���ɑ��ۊǏꏊ�ϊ��敪�i�����_�֏o�Ɂj
     ,chg_program_div             xxcoi_hht_ebs_convert_v.program_div%TYPE                  -- ���o�ɃW���[�i�������敪�i�����_�֏o�Ɂj
     ,chg_consume_vd_flag         xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE              -- ����VD��[�Ώۃt���O�i�����_�֏o�Ɂj
     ,chg_item_convert_div        xxcoi_hht_ebs_convert_v.item_convert_div%TYPE             -- ���i�U�֋敪�i�����_�֏o�Ɂj
     ,chg_stock_uncheck_list_div  xxcoi_hht_ebs_convert_v.stock_uncheck_list_div%TYPE       -- ���ɖ��m�F���X�g�Ώۋ敪�i�����_�֏o�Ɂj
     ,chg_stock_balance_list_div  xxcoi_hht_ebs_convert_v.stock_balance_list_div%TYPE       -- ���ɍ��يm�F���X�g�Ώۋ敪�i�����_�֏o�Ɂj
     ,chg_other_base_code         xxcoi_hht_inv_transactions.other_base_code%TYPE           -- �����_�R�[�h�i�����_�֏o�Ɂj
     ,io_start_subinv_code        mtl_secondary_inventories.secondary_inventory_name%TYPE   -- �o�ɑ��ۊǏꏊ�R�[�h�i�q�ɂ���c�ƎԂցj
     ,io_via_subinv_code          mtl_secondary_inventories.secondary_inventory_name%TYPE   -- ���ɑ��ۊǏꏊ�R�[�h�i�q�ɂ���c�ƎԂցj
     ,io_start_base_code          mtl_secondary_inventories.attribute7%TYPE                 -- �o�ɑ����_�R�[�h�i�q�ɂ���c�ƎԂցj
     ,io_via_base_code            mtl_secondary_inventories.attribute7%TYPE                 -- ���ɑ����_�R�[�h�i�q�ɂ���c�ƎԂցj
     ,io_outside_subinv_conv      xxcoi_hht_ebs_convert_v.outside_subinv_code_conv_div%TYPE -- �o�ɑ��ۊǏꏊ�ϊ��敪�i�q�ɂ���c�ƎԂցj
     ,io_inside_subinv_conv       xxcoi_hht_ebs_convert_v.inside_subinv_code_conv_div%TYPE  -- ���ɑ��ۊǏꏊ�ϊ��敪�i�q�ɂ���c�ƎԂցj
     ,io_program_div              xxcoi_hht_ebs_convert_v.program_div%TYPE                  -- ���o�ɃW���[�i�������敪�i�q�ɂ���c�ƎԂցj
     ,io_consume_vd_flag          xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE              -- ����VD��[�Ώۃt���O�i�q�ɂ���c�ƎԂցj
     ,io_item_convert_div         xxcoi_hht_ebs_convert_v.item_convert_div%TYPE             -- ���i�U�֋敪�i�q�ɂ���c�ƎԂցj
     ,io_stock_uncheck_list_div   xxcoi_hht_ebs_convert_v.stock_uncheck_list_div%TYPE       -- ���ɖ��m�F���X�g�Ώۋ敪�i�q�ɂ���c�ƎԂցj
     ,io_stock_balance_list_div   xxcoi_hht_ebs_convert_v.stock_balance_list_div%TYPE       -- ���ɍ��يm�F���X�g�Ώۋ敪�i�q�ɂ���c�ƎԂցj
    );
  -- ���b�g���f�[�^���R�[�h�z��
  TYPE g_inout_info_ttype IS TABLE OF g_inout_info_rtype INDEX BY BINARY_INTEGER;
--
  -- �t�@�C���A�b�v���[�hIF�f�[�^
  gt_file_line_data_tab     xxccp_common_pkg2.g_file_data_tbl;
  -- ���b�g���f�[�^�i�[�z��
  gt_lot_info_tab           g_lot_info_ttype;
  gt_inout_info_tab         g_inout_info_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_inv_org_code       VARCHAR2(100);                              -- �݌ɑg�D�R�[�h
  gd_process_date       DATE;                                       -- �Ɩ����t
  gn_inv_org_id         NUMBER;                                     -- �݌ɑg�DID
  gn_lot_count          NUMBER;                                     -- ���b�g�ʎ�����̌����J�E���g
  gn_inout_count        NUMBER;                                     -- HHT���o�Ɉꎞ�\�̌����J�E���g
  gv_key_data           VARCHAR2(200);                              -- �L�[���
  gb_err_flag           BOOLEAN;                                    -- �z����G���[�t���O
  gb_insert_flg         BOOLEAN;                                    -- �o�^�t���O
  gv_check_result       VARCHAR2(1);                                -- �`�F�b�N����
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
    ln_dummy                NUMBER; -- �_�~�[�l
    ln_ins_lock_cnt         NUMBER; -- ���b�N����e�[�u���}������
    ln_login_user_id        NUMBER; -- ���O�C�����[�UID
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
    ln_dummy          :=  0;                  -- �_�~�[�l
    ln_ins_lock_cnt   :=  0;                  -- ���b�N����e�[�u���o�^����
    ln_login_user_id  :=  fnd_global.user_id; -- ���O�C�����[�UID
--
    -- �O���[�o���ϐ�������
    gn_inout_count  :=  1;                    -- ���o�ɕ\�쐬�p�f�[�^���R�[�h�̌���
    gn_lot_count    :=  1;                    -- ���b�g����쐬�p�f�[�^���R�[�h�̌���
    gb_insert_flg   :=  TRUE;                 -- �o�^�t���O
    gv_check_result :=  cv_const_y;           -- �`�F�b�N����
--
    -- �݌ɑg�D�R�[�h�̎擾
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_00005  -- �݌ɑg�D�R�[�h�擾�G���[
                     ,iv_token_name1  =>  cv_tkn_pro_tok
                     ,iv_token_value1 =>  cv_inv_org_code   -- �v���t�@�C���F�݌ɑg�D�R�[�h
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
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_00006    -- �݌ɑg�DID�擾�G���[
                     ,iv_token_name1  =>  cv_tkn_org_code_tok
                     ,iv_token_value1 =>  gv_inv_org_code     -- �݌ɑg�D�R�[�h
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
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_00011 -- �Ɩ����t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g���̓p�����[�^�o��(���O)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_10232    -- �R���J�����g���̓p�����[�^
                 ,iv_token_name1   => cv_tkn_file_id
                 ,iv_token_value1  => TO_CHAR(in_file_id) -- �t�@�C��ID
                 ,iv_token_name2   => cv_tkn_format_ptn
                 ,iv_token_value2  => iv_file_format      -- �t�H�[�}�b�g�p�^�[��
               )
    );
--
    -- �R���J�����g���̓p�����[�^�o��(�o��)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_10232    -- �R���J�����g���̓p�����[�^
                 ,iv_token_name1   => cv_tkn_file_id
                 ,iv_token_value1  => TO_CHAR(in_file_id) -- �t�@�C��ID
                 ,iv_token_name2   => cv_tkn_format_ptn
                 ,iv_token_value2  => iv_file_format      -- �t�H�[�}�b�g�p�^�[��
                )
    );
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
    -- ���[�J���ϐ�������
    lt_file_name        := NULL; -- �t�@�C����
    lt_file_upload_name := NULL; -- �t�@�C���A�b�v���[�h����
--
    -- �t�@�C���A�b�v���[�hIF�f�[�^���b�N
    BEGIN
      SELECT  xfu.file_name   AS file_name      -- �t�@�C����
      INTO    lt_file_name                      -- �t�@�C����
      FROM    xxccp_mrp_file_ul_interface  xfu  -- �t�@�C���A�b�v���[�hIF
      WHERE   xfu.file_id = in_file_id          -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ���b�N���擾�ł��Ȃ��ꍇ
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cos
                       ,iv_name         =>  cv_msg_cos_00001  -- ���b�N�G���[���b�Z�[�W
                       ,iv_token_name1  =>  cv_tkn_table
                       ,iv_token_value1 =>  cv_tkn_cos_11282  -- �t�@�C���A�b�v���[�hIF
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̏��擾
    BEGIN
      SELECT  flv.meaning   AS file_upload_name -- �t�@�C���A�b�v���[�h����
      INTO    lt_file_upload_name               -- �t�@�C���A�b�v���[�h����
      FROM    fnd_lookup_values flv             -- �N�C�b�N�R�[�h
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
                       ,iv_token_name1  =>  cv_tkn_key_data
                       ,iv_token_value1 =>  iv_file_format    -- �t�H�[�}�b�g�p�^�[��
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �擾�����t�@�C�����A�t�@�C���A�b�v���[�h���̂��o��
    -- �t�@�C�������o�́i���O�j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_00028  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_tkn_file_name
                   ,iv_token_value1 =>  lt_file_name      -- �t�@�C����
                  )
    );
    -- �t�@�C�������o�́i�o�́j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_00028  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_tkn_file_name
                   ,iv_token_value1 =>  lt_file_name      -- �t�@�C����
                  )
    );
--
    -- �t�@�C���A�b�v���[�h���̂��o�́i���O�j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_10611      -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_tkn_file_upld_name
                   ,iv_token_value1 =>  lt_file_upload_name   -- �t�@�C���A�b�v���[�h����
                  )
    );
    -- �t�@�C���A�b�v���[�h���̂��o�́i�o�́j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_10611      -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_tkn_file_upld_name
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
                      iv_application  =>  cv_msg_kbn_cos
                     ,iv_name         =>  cv_msg_cos_00013  -- �f�[�^���o�G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_tkn_table_name
                     ,iv_token_value1 =>  cv_tkn_cos_11282  -- �t�@�C���A�b�v���[�hIF
                     ,iv_token_name2  =>  cv_tkn_key_data
                     ,iv_token_value2 =>  NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���o�s����2�s�ȏ�Ȃ������ꍇ
    IF (gt_file_line_data_tab.COUNT < 2) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10747  -- �A�b�v���[�h����0�����b�Z�[�W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_warn_expt;
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
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
                       ,iv_token_name1  =>  cv_tkn_table_name
                       ,iv_token_value1 =>  cv_tkn_coi_10634  -- �t�@�C���A�b�v���[�hIF
                       ,iv_token_name2  =>  cv_tkn_key_data
                       ,iv_token_value2 =>  NULL
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
                      iv_application  =>  cv_msg_kbn_cos
                     ,iv_name         =>  cv_msg_cos_11295  -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_tkn_data
                     ,iv_token_value1 =>  lv_rec_data       -- �t�H�[�}�b�g�p�^�[��
                   );
      ov_errbuf := chr(10) || lv_errmsg;
    END IF;
--
    -- �������[�v
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     =>  gt_file_line_data_tab(in_file_if_loop_cnt)
                                   ,iv_delim    =>  cv_csv_delimiter
                                   ,in_part_num =>  i
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
   * Procedure Name   : quantity_check
   * Description      : ���ʃ`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE quantity_check(
    it_child_item_id              IN  mtl_system_items_b.inventory_item_id%TYPE -- �q�i��ID
   ,it_parent_item_id             IN  mtl_system_items_b.inventory_item_id%TYPE -- �e�i��ID
   ,it_inout_info                 IN  g_inout_info_rtype                        -- ���b�g���f�[�^���R�[�h
   ,in_reserved_quantity_req      IN  NUMBER                                    -- �����˗���
   ,ov_errbuf                     OUT VARCHAR2                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                    OUT VARCHAR2                                  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                     OUT VARCHAR2)                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'quantity_check'; -- �v���O������
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
    ln_dummy                        NUMBER;         -- �_�~�[
    ln_case_qty                     NUMBER;         -- �P�[�X��
    ln_singly_qty                   NUMBER;         -- �o����
    lv_errbuf_pkg                   VARCHAR2(5000); -- �G���[�E���b�Z�[�W�i���ʊ֐��߂�l�p�j
    ln_summary_qty                  NUMBER;         -- �������
    ln_reserved_quantity_req        NUMBER;         -- �����˗���
    ln_case_in_qty                  NUMBER;         -- �P�[�X����
    ln_child_item_id                NUMBER;         -- �q�i��ID
    ln_parent_item_id               NUMBER;         -- �e�i��ID
    lt_primary_uom_code             xxcoi_txn_enable_item_info_v.primary_uom_code%TYPE; -- ��P�ʃR�[�h
    lv_goods_product_class          VARCHAR2(100);  -- �v���t�@�C���F�J�e�S���Z�b�g��
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �e�i�ڂɕR�Â����b�g���̎擾�J�[�\��
    CURSOR get_lot_info_cur(
      iv_outside_base_code        xxcoi_lot_onhand_quantites_v.base_code%TYPE
     ,iv_outside_subinv_code      xxcoi_lot_onhand_quantites_v.subinventory_code%TYPE
     ,iv_parent_item_id           mtl_system_items_b.inventory_item_id%TYPE
     ,id_invoice_date             DATE )
    IS
      SELECT  xloq.location_code            AS location_code            -- ���P�[�V�����R�[�h
             ,xloq.lot                      AS lot                      -- ���b�g
             ,xloq.difference_summary_code  AS difference_summary_code  -- �ŗL�L��
             ,xaiciv.parent_item_id         AS parent_item_id           -- �e�i��ID
             ,xaiciv.parent_item_code       AS parent_item_code         -- �e�i��
             ,xaiciv.child_item_id          AS item_id                  -- �q�i��ID
             ,xaiciv.child_item_code        AS item_code                -- �q�i��
-- V1.2 2020/01/21 T.Nakano MOD START --
             -- �������Ă�D�揇�ʂ́A���P�[�V�����^�C�v���i�D��j�A�i�ʏ�E�ꎞ�ۊǁj�ƂȂ邽�߁A
             -- �D��Ƃ���ȊO�Őݒ肷�鐔�l�𕪂���
             --,xwlmv.location_type           AS location_type            -- ���P�[�V�����^�C�v
             ,DECODE(xwlmv.location_type, cv_location_type_2, cv_9, cv_8)
                                            AS location_type            -- ���P�[�V�����^�C�v
-- V1.2 2020/01/21 T.Nakano MOD END --
-- V1.2 2020/01/21 T.Nakano ADD START --
             ,xnwl.priority                 AS priority                 -- �D�揇��
-- V1.2 2020/01/21 T.Nakano ADD END --
             ,xaiciv.primary_uom_code       AS primary_uom_code         -- ��P�ʃR�[�h
      FROM    (
                SELECT  msib.inventory_item_id      AS child_item_id
                       ,msib.segment1               AS child_item_code
                       ,msib_p.inventory_item_id    AS parent_item_id
                       ,msib_p.segment1             AS parent_item_code
                       ,xteiiv.primary_uom_code     AS primary_uom_code
                FROM    ic_item_mst_b          iimb
                       ,xxcmn_item_mst_b       ximb
                       ,mtl_system_items_b     msib
                       ,xxcmm_system_items_b   xsib
                       ,mtl_system_items_b     msib_p
                       ,ic_item_mst_b          iimb_p
                       ,xxcoi_txn_enable_item_info_v  xteiiv
                       ,mtl_category_sets_tl          mcst
                       ,mtl_category_sets_b           mcsb
                       ,mtl_categories_b              mcb
                       ,mtl_item_categories           mic
                WHERE   msib_p.inventory_item_id  = iv_parent_item_id
                AND     iimb.item_id              = ximb.item_id
                AND     iimb.item_no              = xsib.item_code
                AND     iimb.item_no              = msib.segment1
                AND     msib.organization_id      = gn_inv_org_id
                AND     gd_process_date           BETWEEN ximb.start_date_active AND ximb.end_date_active
                AND     ximb.parent_item_id       = iimb_p.item_id
                AND     iimb_p.item_no            = msib_p.segment1
                AND     msib.organization_id      = msib_p.organization_id
                AND     xsib.item_status          IN ( '30' ,'40' ,'50' )
                AND     mcst.category_set_name    = lv_goods_product_class
                AND     mcst.language             = ct_language
                AND     mcsb.category_set_id      = mcst.category_set_id
                AND     mcb.structure_id          = mcsb.structure_id
                AND     mcb.segment1              IN ( cv_segment1_1, cv_segment1_2 )
                AND     mic.category_id           = mcb.category_id
                AND     mic.inventory_item_id     = xteiiv.inventory_item_id
                AND     mic.organization_id       = xteiiv.organization_id
                AND     TO_CHAR(id_invoice_date, cv_date_format)
                                                  BETWEEN TO_CHAR(xteiiv.start_date_active, cv_date_format)
                                                  AND     TO_CHAR(NVL(xteiiv.end_date_active, id_invoice_date), cv_date_format)
                AND     mic.inventory_item_id     = msib_p.inventory_item_id
              )                               xaiciv  -- �݌ɒ��������_�q�i�ڃr���[_�ȈՔ�
             ,xxcoi_lot_onhand_quantites      xloq    -- ���b�g�ʎ莝����
             ,xxcoi_warehouse_location_mst_v  xwlmv   -- �q�Ƀ��P�[�V�����}�X�^�r���[
-- V1.2 2020/01/21 T.Nakano ADD START --
             ,xxcoi_mst_warehouse_location    xnwl    -- �q�Ƀ��P�[�V�����}�X�^
-- V1.2 2020/01/21 T.Nakano ADD END --
      WHERE   xaiciv.child_item_id    = xloq.child_item_id
      AND     xloq.base_code          = iv_outside_base_code
      AND     xloq.subinventory_code  = iv_outside_subinv_code
      AND     xloq.organization_id    = gn_inv_org_id
      AND     xwlmv.organization_id   = xloq.organization_id
      AND     xwlmv.base_code         = xloq.base_code
      AND     xwlmv.subinventory_code = xloq.subinventory_code
      AND     xwlmv.location_code     = xloq.location_code
-- V1.2 2020/01/21 T.Nakano MOD START --
      --AND     xwlmv.location_type     IN (cv_location_type_1, cv_location_type_2)
      AND     xwlmv.location_type     IN (cv_location_type_1, cv_location_type_2, cv_location_type_3)
      AND     xwlmv.warehouse_location_id = xnwl.warehouse_location_id
-- V1.2 2020/01/21 T.Nakano MOD END --
    ;
--
    -- �ꎞ�\�Ɋi�[���������\���ʂ̎擾�J�[�\��
    CURSOR get_lot_temp_cur(
      iv_child_item_id            mtl_system_items_b.inventory_item_id%TYPE
     ,iv_parent_item_id           mtl_system_items_b.inventory_item_id%TYPE
     ,iv_lot                      xxcoi_lot_onhand_quantites_v.lot%TYPE
     ,iv_difference_summary_code  xxcoi_lot_onhand_quantites_v.difference_summary_code%TYPE
     ,iv_location_code            xxcoi_lot_onhand_quantites_v.location_code%TYPE
     ,iv_subinv_code              mtl_secondary_inventories.secondary_inventory_name%TYPE  )
    IS
      SELECT  xtlr.location_code            AS location_code            -- ���P�[�V�����R�[�h
             ,xtlr.lot                      AS lot                      -- ���b�g
             ,xtlr.difference_summary_code  AS difference_summary_code  -- �ŗL�L��
             ,xtlr.parent_item_id           AS parent_item_id           -- �e�i��ID
             ,xtlr.parent_item_code         AS parent_item_code         -- �e�i��
             ,xtlr.child_item_id            AS item_id                  -- �q�i��ID
             ,xtlr.child_item_code          AS item_code                -- �q�i��
             ,xtlr.case_in_qty              AS case_in_qty              -- ����
             ,xtlr.reserved_quantity        AS reserved_quantity        -- �����\��
      FROM    xxcoi_tmp_lot_reserve_qty xtlr    -- ���b�g�ʈ����\���ʈꎞ�\
      WHERE   (   iv_lot    IS NULL
              OR  xtlr.lot  = iv_lot  )
      AND     (   iv_difference_summary_code    IS NULL
              OR  xtlr.difference_summary_code  = iv_difference_summary_code  )
      AND     (   iv_location_code    IS NULL
              OR  xtlr.location_code  = iv_location_code  )
      AND     xtlr.subinventory_code  = iv_subinv_code
      AND     xtlr.child_item_id      = NVL(iv_child_item_id, xtlr.child_item_id)
      AND     xtlr.parent_item_id     = iv_parent_item_id
      AND     xtlr.reserved_quantity  > cn_zero
      ORDER BY  xtlr.location_type  DESC
               ,xtlr.lot            ASC
-- V1.2 2020/01/21 T.Nakano ADD START --
               ,xtlr.priority       ASC
-- V1.2 2020/01/21 T.Nakano ADD END --
    ;
--
    -- *** ���[�J���E���R�[�h ***
    get_lot_info_rec  get_lot_info_cur%ROWTYPE;
    get_lot_temp_rec  get_lot_temp_cur%ROWTYPE;
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
    lv_goods_product_class    :=  FND_PROFILE.VALUE(cv_goods_product_cls);
    lt_primary_uom_code       :=  NULL;
--
    -- �o�ɑ��ۊǏꏊ�̈����\���b�g�̏����ꎞ�\�֊i�[����
    OPEN get_lot_info_cur(
      iv_outside_base_code    =>  it_inout_info.chg_start_base_code
     ,iv_outside_subinv_code  =>  it_inout_info.chg_start_subinv_code
     ,iv_parent_item_id       =>  it_inout_info.parent_item_id
     ,id_invoice_date         =>  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
    );
--
    <<get_lot_info_loop>>
    LOOP
      -- ���R�[�h�Ǎ�
      FETCH get_lot_info_cur INTO get_lot_info_rec;
--
      -- ���R�[�h���擾�ł��Ȃ���΃��[�v�𔲂���
      IF get_lot_info_cur%NOTFOUND THEN
        EXIT;
      END IF;
--
      -- ��P�ʃR�[�h��ێ�
      lt_primary_uom_code :=  get_lot_info_rec.primary_uom_code;
--
      BEGIN
--
        -- �J�[�\������擾�����i�ځA���b�g���Ńe�[�u������������
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_tmp_lot_reserve_qty xtlr
        WHERE   xtlr.location_code            = get_lot_info_rec.location_code
        AND     xtlr.lot                      = get_lot_info_rec.lot
        AND     xtlr.difference_summary_code  = get_lot_info_rec.difference_summary_code
        AND     xtlr.child_item_id            = get_lot_info_rec.item_id
        AND     xtlr.subinventory_code        = it_inout_info.chg_start_subinv_code
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ��v����f�[�^�������i���o�^�̃��b�g�j�ł���΁A�ꎞ�\�Ƀf�[�^��o�^����
--
          -- �����\���̎擾
          -- �ϐ��̏�����
          ln_case_in_qty  :=  0;
          ln_case_qty     :=  0;
          ln_singly_qty   :=  0;
          ln_summary_qty  :=  0;
          lv_errbuf_pkg   :=  NULL;
          lv_retcode      :=  NULL;
          lv_errmsg       :=  NULL;
--
          xxcoi_common_pkg.get_reserved_quantity(
            in_inv_org_id     => gn_inv_org_id                              -- �݌ɑg�DID
           ,iv_base_code      => it_inout_info.chg_start_base_code          -- ���_�R�[�h
           ,iv_subinv_code    => it_inout_info.chg_start_subinv_code        -- �ۊǏꏊ�R�[�h
           ,iv_loc_code       => get_lot_info_rec.location_code             -- ���P�[�V�����R�[�h
           ,in_child_item_id  => get_lot_info_rec.item_id                   -- �q�i��ID
           ,iv_lot            => get_lot_info_rec.lot                       -- ���b�g(�ܖ�����)
           ,iv_diff_sum_code  => get_lot_info_rec.difference_summary_code   -- �ŗL�L��
           ,on_case_in_qty    => ln_case_in_qty                             -- ����
           ,on_case_qty       => ln_case_qty                                -- �P�[�X��
           ,on_singly_qty     => ln_singly_qty                              -- �o����
           ,on_summary_qty    => ln_summary_qty                             -- �������
           ,ov_errbuf         => lv_errbuf_pkg                              -- �G���[���b�Z�[�W
           ,ov_retcode        => lv_retcode                                 -- ���^�[���E�R�[�h(0:����A2:�G���[)
           ,ov_errmsg         => lv_errmsg                                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
--
          -- ���^�[���R�[�h��'0'�i����j�ȊO�̏ꍇ�̓G���[
          IF ( lv_retcode <> cv_status_normal ) THEN
            -- �����\���Z�o�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_msg_kbn_coi
                           ,iv_name         =>  cv_msg_coi_10593  -- �����\���Z�o�G���[
                           ,iv_token_name1  =>  cv_tkn_key_data
                           ,iv_token_value1 =>  gv_key_data || gn_inout_count  -- �L�[���
                           ,iv_token_name2  =>  cv_tkn_err_msg
                           ,iv_token_value2 =>  lv_errmsg         -- �G���[���b�Z�[�W
                         );
            RAISE global_process_expt;
--
          ELSE
            -- ���ʂ�����Ɏ擾�ł����ꍇ�͓o�^���������{
            BEGIN
              INSERT INTO xxcoi_tmp_lot_reserve_qty(
                subinventory_code         -- �ۊǏꏊ�R�[�h
               ,base_code                 -- ���_�R�[�h
               ,parent_item_id            -- �e�i��ID
               ,parent_item_code          -- �e�i��
               ,child_item_id             -- �q�i��ID
               ,child_item_code           -- �q�i��
               ,lot                       -- ���b�g
               ,location_code             -- ���P�[�V�����R�[�h
               ,difference_summary_code   -- �ŗL�L��
               ,location_type             -- ���P�[�V�����^�C�v
-- V1.2 2020/01/21 T.Nakano ADD START --
               ,priority                  -- �D�揇��
-- V1.2 2020/01/21 T.Nakano ADD END --
               ,case_in_qty               -- ����
               ,reserved_quantity)        -- �����\��
              VALUES(
                it_inout_info.chg_start_subinv_code           -- �ۊǏꏊ�R�[�h
               ,it_inout_info.chg_start_base_code             -- ���_�R�[�h
               ,get_lot_info_rec.parent_item_id               -- �e�i��ID
               ,get_lot_info_rec.parent_item_code             -- �e�i��
               ,get_lot_info_rec.item_id                      -- �q�i��ID
               ,get_lot_info_rec.item_code                    -- �q�i��
               ,get_lot_info_rec.lot                          -- ���b�g
               ,get_lot_info_rec.location_code                -- ���P�[�V�����R�[�h
               ,get_lot_info_rec.difference_summary_code      -- �ŗL�L��
               ,get_lot_info_rec.location_type                -- ���P�[�V�����^�C�v
-- V1.2 2020/01/21 T.Nakano ADD START --
               ,get_lot_info_rec.priority                     -- �D�揇��
-- V1.2 2020/01/21 T.Nakano ADD END --
               ,ln_case_in_qty                                -- ����
               ,ln_summary_qty                                -- �����\��
              )
              ;
            EXCEPTION
              WHEN OTHERS THEN
                -- �G���[���b�Z�[�W�̎擾
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_coi
                             , iv_name         => cv_msg_coi_10745
                             , iv_token_name1  => cv_tkn_err_msg
                             , iv_token_value1 => SQLERRM
                             );
                RAISE global_process_expt;
            END;
--
          END IF;
--
      END;
--
    END LOOP get_lot_info_loop;
--
    IF ( get_lot_info_cur%ISOPEN ) THEN
      CLOSE get_lot_info_cur;
    END IF;
--
    -- �ꎞ�\�ɓo�^�����f�[�^�����Ɉ������ʂ��`�F�b�N����
    -- �ϐ��̏�����
    ln_reserved_quantity_req  :=  0;
--
    -- �e�i��ID��ݒ�
    ln_parent_item_id :=  it_parent_item_id;
--
    -- �q�i�ڂ��ݒ肳��Ă���΁A�q�i��ID��ݒ�
    ln_child_item_id  :=  NULL;
    IF it_child_item_id IS NOT NULL THEN
      ln_child_item_id  :=  it_child_item_id;
    END IF;
--
    -- �����˗���ݒ�
    ln_reserved_quantity_req  :=  in_reserved_quantity_req;
--
    -- �ꎞ�\�Ɋi�[���������\���ʂ̎擾
    OPEN get_lot_temp_cur(
      iv_child_item_id            =>  ln_child_item_id
     ,iv_parent_item_id           =>  ln_parent_item_id
     ,iv_lot                      =>  g_if_data_tab(cn_lot)
     ,iv_difference_summary_code  =>  g_if_data_tab(cn_difference_summary_code)
     ,iv_location_code            =>  g_if_data_tab(cn_location_code)
     ,iv_subinv_code              =>  it_inout_info.chg_start_subinv_code
    );
--
    <<get_lot_temp_loop>>
    LOOP
      -- ���R�[�h�Ǎ�
      FETCH get_lot_temp_cur INTO get_lot_temp_rec;
--
      -- ���R�[�h���擾�ł��Ȃ��ꍇ�́A�����\�����s�����Ă��邽�߁A���ʃG���[�Ƃ���
--
      IF get_lot_temp_cur%NOTFOUND THEN
        IF g_if_data_tab(cn_child_item_code) IS NOT NULL THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10742
                         ,iv_token_name1  =>  cv_tkn_param
                         ,iv_token_value1 =>  cv_tkn_cos_10628
                         ,iv_token_name2  =>  cv_tkn_item_code
                         ,iv_token_value2 =>  g_if_data_tab(cn_child_item_code)
                         ,iv_token_name3  =>  cv_tkn_data
                         ,iv_token_value3 =>  TO_CHAR(ln_reserved_quantity_req) || lt_primary_uom_code
                       );
        ELSE
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10742
                         ,iv_token_name1  =>  cv_tkn_param
                         ,iv_token_value1 =>  cv_tkn_cos_10496
                         ,iv_token_name2  =>  cv_tkn_item_code
                         ,iv_token_value2 =>  g_if_data_tab(cn_parent_item_code)
                         ,iv_token_name3  =>  cv_tkn_data
                         ,iv_token_value3 =>  TO_CHAR(ln_reserved_quantity_req) || lt_primary_uom_code
                       );
        END IF;
--
        RAISE global_process_expt;
      END IF;
--
      -- �e�[�u���^�ϐ��Ƀ��b�g�̏���ۑ�����
      gt_lot_info_tab(gn_lot_count).slip_no                   :=  it_inout_info.slip_no;                    -- �`�[�ԍ�
      gt_lot_info_tab(gn_lot_count).invoice_date              :=  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format);
                                                                                                            -- �`�[���t
      gt_lot_info_tab(gn_lot_count).csv_no                    :=  gn_inout_count;                           -- CSV�̍s��
      gt_lot_info_tab(gn_lot_count).lot                       :=  get_lot_temp_rec.lot;                     -- ���b�g�i�ܖ������j
      gt_lot_info_tab(gn_lot_count).difference_summary_code   :=  get_lot_temp_rec.difference_summary_code; -- �ŗL�L��
      gt_lot_info_tab(gn_lot_count).location_code             :=  get_lot_temp_rec.location_code;           -- ���P�[�V����
      gt_lot_info_tab(gn_lot_count).parent_item_id            :=  get_lot_temp_rec.parent_item_id;          -- �e�i��ID
      gt_lot_info_tab(gn_lot_count).parent_item_code          :=  get_lot_temp_rec.parent_item_code;        -- �e�i��
      gt_lot_info_tab(gn_lot_count).child_item_id             :=  get_lot_temp_rec.item_id;                 -- �q�i��ID
      gt_lot_info_tab(gn_lot_count).child_item_code           :=  get_lot_temp_rec.item_code;               -- �q�i��
      gt_lot_info_tab(gn_lot_count).case_in_quantity          :=  get_lot_temp_rec.case_in_qty;             -- ����
--
      -- �q�ցiCHANGE�j
      gt_lot_info_tab(gn_lot_count).outside_base_code         :=  it_inout_info.chg_start_base_code;        -- �o�ɑ����_�R�[�h�i�����_�֏o�Ɂj
      gt_lot_info_tab(gn_lot_count).program_div               :=  it_inout_info.chg_program_div;            -- ���o�ɃW���[�i�������敪�i�����_�֏o�Ɂj
      gt_lot_info_tab(gn_lot_count).consume_vd_flag           :=  it_inout_info.chg_consume_vd_flag;        -- ����VD��[�Ώۃt���O�i�����_�֏o�Ɂj
      gt_lot_info_tab(gn_lot_count).start_subinv_code         :=  it_inout_info.chg_start_subinv_code;      -- �o�ɑ��ۊǏꏊ�i�����_�֏o�Ɂj
      gt_lot_info_tab(gn_lot_count).via_subinv_code           :=  it_inout_info.chg_via_subinv_code;        -- ���ɑ��ۊǏꏊ�i�����_�֏o�Ɂj
      gt_lot_info_tab(gn_lot_count).inside_warehouse_code     :=  it_inout_info.io_via_subinv_code;         -- �]����q��
--
      -- �����\�����������������ɒB���Ă��邩���`�F�b�N
      IF  ln_reserved_quantity_req  <=  get_lot_temp_rec.reserved_quantity  THEN
        -- ���b�g�ʎ�����דo�^�p�ɃP�[�X���ƃo�����Ǝ�����ʂ��L�^����
--
        -- ������0�̏ꍇ��0���Z�ɂȂ�̂ŏ��Z�����Ȃ�
        IF get_lot_temp_rec.case_in_qty <> cn_zero THEN
          -- �P�[�X���̊��Z
          gt_lot_info_tab(gn_lot_count).case_qty    :=  ( ln_reserved_quantity_req - MOD( ln_reserved_quantity_req, get_lot_temp_rec.case_in_qty ) ) / get_lot_temp_rec.case_in_qty;
          -- �o�����̊��Z
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  MOD( ln_reserved_quantity_req, get_lot_temp_rec.case_in_qty );
        ELSE
          -- �P�[�X���̊��Z
          gt_lot_info_tab(gn_lot_count).case_qty    :=  0;
          -- �o�����̊��Z
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  ln_reserved_quantity_req;
        END IF;
        -- ������ʂ̐ݒ�
        gt_lot_info_tab(gn_lot_count).summary_quantity  :=  ln_reserved_quantity_req;
--
        -- �Ȍ�̃��R�[�h�œ��ꃍ�b�g���������Ă�\�������邽�߁A����������Ă������ꎞ�\�̈����\�����猸�炷
        BEGIN
--
          UPDATE  xxcoi_tmp_lot_reserve_qty   xtlr
          SET     xtlr.reserved_quantity        = get_lot_temp_rec.reserved_quantity - ln_reserved_quantity_req
          WHERE   xtlr.location_code            = get_lot_temp_rec.location_code
          AND     xtlr.lot                      = get_lot_temp_rec.lot
          AND     xtlr.difference_summary_code  = get_lot_temp_rec.difference_summary_code
          AND     xtlr.child_item_id            = get_lot_temp_rec.item_id
          AND     xtlr.subinventory_code        = it_inout_info.chg_start_subinv_code
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_msg_kbn_coi
                           ,iv_name         =>  cv_msg_coi_10746
                           ,iv_token_name1  =>  cv_tkn_err_msg
                           ,iv_token_value1 =>  SQLERRM
                         );
            RAISE global_process_expt;
        END;
--
        -- ���̃��b�g�����쐬���邽�߃J�E���g���グ��
        gn_lot_count  :=  gn_lot_count + 1;
--
        -- �����\�������肽���߁A���[�v�𔲂���
        EXIT;
--
      ELSE
        -- �����\��������Ȃ��ꍇ�́A���̃��b�g�̈����\����S�Ĉ������Ă�
--
        -- ������0�̏ꍇ��0���Z�ɂȂ�̂ŏ��Z�����Ȃ�
        IF get_lot_temp_rec.case_in_qty <> cn_zero THEN
          -- �P�[�X���̊��Z
          gt_lot_info_tab(gn_lot_count).case_qty    :=  ( get_lot_temp_rec.reserved_quantity - MOD( get_lot_temp_rec.reserved_quantity, get_lot_temp_rec.case_in_qty ) ) / get_lot_temp_rec.case_in_qty;
          -- �o�����̊��Z
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  MOD( get_lot_temp_rec.reserved_quantity, get_lot_temp_rec.case_in_qty );
        ELSE
          -- �P�[�X���̊��Z
          gt_lot_info_tab(gn_lot_count).case_qty    :=  0;
          -- �o�����̊��Z
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  get_lot_temp_rec.reserved_quantity;
        END IF;
        -- ������ʂ̐ݒ�
        gt_lot_info_tab(gn_lot_count).summary_quantity  :=  get_lot_temp_rec.reserved_quantity;
--
        -- ���̃��b�g�����쐬���邽�߃J�E���g���グ��
        gn_lot_count  :=  gn_lot_count + 1;
--
        -- �������Ă���������A���̃��b�g�ň������Ă�ꂽ��������
        ln_reserved_quantity_req  :=  ln_reserved_quantity_req - get_lot_temp_rec.reserved_quantity;
--
        -- �Ȍ�̃��R�[�h�œ��ꃍ�b�g���������Ă�\�������邽�߁A����������Ă������ꎞ�\�̈����\�����猸�炷
        -- ���S�Ĉ������ĂĂ��邽�߁A0�ɂȂ�
        BEGIN
--
          UPDATE  xxcoi_tmp_lot_reserve_qty   xtlr
          SET     xtlr.reserved_quantity        = 0
          WHERE   xtlr.location_code            = get_lot_temp_rec.location_code
          AND     xtlr.lot                      = get_lot_temp_rec.lot
          AND     xtlr.difference_summary_code  = get_lot_temp_rec.difference_summary_code
          AND     xtlr.child_item_id            = get_lot_temp_rec.item_id
          AND     xtlr.subinventory_code        = it_inout_info.chg_start_subinv_code
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_msg_kbn_coi
                           ,iv_name         =>  cv_msg_coi_10746
                           ,iv_token_name1  =>  cv_tkn_err_msg
                           ,iv_token_value1 =>  SQLERRM
                         );
            RAISE global_process_expt;
        END;
--
      END IF;
--
    END LOOP get_lot_temp_loop;
--
    IF ( get_lot_temp_cur%ISOPEN ) THEN
      CLOSE get_lot_temp_cur;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END quantity_check;
--
    /**********************************************************************************
   * Procedure Name   : err_check
   * Description      : �G���[�`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE err_check(
    in_file_if_loop_cnt   IN  NUMBER    --   IF���[�v�J�E���^
   ,ov_errbuf             OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_check'; -- �v���O������
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
    ln_dummy                        NUMBER;                                                             -- �_�~�[
    lt_base_code                    xxcoi_storage_information.base_code%TYPE;                           -- ���_�R�[�h
    lt_inside_warehouse_flag        xxcoi_subinventory_info_v.warehouse_flag%TYPE;                      -- ���ɑ��q�ɂ̑q�ɊǗ��Ώۋ敪
    lt_outside_warehouse_flag       xxcoi_subinventory_info_v.warehouse_flag%TYPE;                      -- �o�ɑ��q�ɂ̑q�ɊǗ��Ώۋ敪
    lt_parent_item_code             mtl_system_items_b.segment1%TYPE;                                   -- �e�i��
    lt_parent_item_id               mtl_system_items_b.inventory_item_id%TYPE;                          -- �e�i��ID
    lt_child_item_id                mtl_system_items_b.inventory_item_id%TYPE;                          -- �q�i��ID
    lv_err_column                   VARCHAR2(100);                                                      -- �K�{�G���[�̍��ږ�
    lv_errbuf2                      VARCHAR2(5000);                                                     -- �G���[�E���b�Z�[�W�i�ϊ��֐��߂�l�p�j
    ln_reserved_quantity_req        NUMBER;                                                             -- �����˗���
    ln_parent_case_in_qty           NUMBER;                                                             -- �e�̃P�[�X����
    ln_child_case_in_qty            NUMBER;                                                             -- �q�̃P�[�X����
    lt_chg_start_subinv_code        xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- �o�ɑ��ۊǏꏊ�R�[�h�i�����_�֏o�Ɂj
    lt_chg_via_subinv_code          xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- ���ɑ��ۊǏꏊ�R�[�h�i�����_�֏o�Ɂj
    lt_chg_start_base_code          xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- �o�ɑ����_�R�[�h�i�����_�֏o�Ɂj
    lt_chg_via_base_code            xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- ���ɑ����_�R�[�h�i�����_�֏o�Ɂj
    lt_chg_outside_subinv_conv      xxcoi.xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- �o�ɑ��ۊǏꏊ�ϊ��敪�i�����_�֏o�Ɂj
    lt_chg_inside_subinv_conv       xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;  -- ���ɑ��ۊǏꏊ�ϊ��敪�i�����_�֏o�Ɂj
    lt_chg_program_div              xxcoi.xxcoi_hht_inv_transactions.hht_program_div%TYPE;              -- ���o�ɃW���[�i�������敪�i�����_�֏o�Ɂj
    lt_chg_consume_vd_flag          xxcoi.xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;              -- ����VD��[�Ώۃt���O�i�����_�֏o�Ɂj
    lt_chg_item_convert_div         xxcoi.xxcoi_hht_inv_transactions.item_convert_div%TYPE;             -- ���i�U�֋敪�i�����_�֏o�Ɂj
    lt_chg_stock_uncheck_list_div   xxcoi.xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;       -- ���ɖ��m�F���X�g�Ώۋ敪�i�����_�֏o�Ɂj
    lt_chg_stock_balance_list_div   xxcoi.xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;       -- ���ɍ��يm�F���X�g�Ώۋ敪�i�����_�֏o�Ɂj
    lt_io_start_subinv_code         xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- �o�ɑ��ۊǏꏊ�R�[�h�i�q�ɂ���c�ƎԂցj
    lt_io_via_subinv_code           xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- ���ɑ��ۊǏꏊ�R�[�h�i�q�ɂ���c�ƎԂցj
    lt_io_start_base_code           xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- �o�ɑ����_�R�[�h�i�q�ɂ���c�ƎԂցj
    lt_io_via_base_code             xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- ���ɑ����_�R�[�h�i�q�ɂ���c�ƎԂցj
    lt_io_outside_subinv_conv       xxcoi.xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- �o�ɑ��ۊǏꏊ�ϊ��敪�i�q�ɂ���c�ƎԂցj
    lt_io_inside_subinv_conv        xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;  -- ���ɑ��ۊǏꏊ�ϊ��敪�i�q�ɂ���c�ƎԂցj
    lt_io_program_div               xxcoi.xxcoi_hht_inv_transactions.hht_program_div%TYPE;              -- ���o�ɃW���[�i�������敪�i�q�ɂ���c�ƎԂցj
    lt_io_consume_vd_flag           xxcoi.xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;              -- ����VD��[�Ώۃt���O�i�q�ɂ���c�ƎԂցj
    lt_io_item_convert_div          xxcoi.xxcoi_hht_inv_transactions.item_convert_div%TYPE;             -- ���i�U�֋敪�i�q�ɂ���c�ƎԂցj
    lt_io_stock_uncheck_list_div    xxcoi.xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;       -- ���ɖ��m�F���X�g�Ώۋ敪�i�q�ɂ���c�ƎԂցj
    lt_io_stock_balance_list_div    xxcoi.xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;       -- ���ɍ��يm�F���X�g�Ώۋ敪�i�q�ɂ���c�ƎԂցj
    lt_io_item_convert_div_d        xxcoi_hht_ebs_convert_v.item_convert_div%TYPE;                      -- ���i�U�֋敪
    lt_io_stock_uncheck_list_div_d  xxcoi_hht_ebs_convert_v.stock_uncheck_list_div%TYPE;                -- ���ɖ��m�F���X�g�Ώۋ敪
    lt_io_stock_balance_list_div_d  xxcoi_hht_ebs_convert_v.stock_balance_list_div%TYPE;                -- ���ɍ��يm�F���X�g�Ώۋ敪
    lt_io_consume_vd_flag_d         xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE;                       -- ����VD��[�Ώۃt���O
    -- �ȉ��͋��ʊ֐��̖߂�l���󂯎�邽�߂̃_�~�[�ϐ�(�o�^�ɂ͎g�p���Ȃ�)
    lt_outside_business_low_type    xxcmm_cust_accounts.business_low_type%TYPE;                         -- �o�ɑ��Ƒԏ�����
    lt_inside_business_low_type     xxcmm_cust_accounts.business_low_type%TYPE;                         -- ���ɑ��Ƒԏ�����
    lt_outside_cust_code            xxcoi_hht_inv_transactions.outside_code%TYPE;                       -- �o�ɑ��ڋq�R�[�h
    lt_inside_cust_code             xxcoi_hht_inv_transactions.inside_code%TYPE;                        -- ���ɑ��ڋq�R�[�h
    lt_outside_subinv_div           mtl_secondary_inventories.attribute5%TYPE;                          -- �o�ɑ��I���Ώ�
    lt_inside_subinv_div            mtl_secondary_inventories.attribute5%TYPE;                          -- ���ɑ��I���Ώ�
--  V1.1 Added START
    lb_org_acct_period_flg          BOOLEAN;                                                            --  �݌ɉ�v���Ԃ̃`�F�b�N����
--  V1.1 Added END
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf :=  NULL;
--
    -- ============================================
    -- A-4�D�A�b�v���[�h�t�@�C�����ڕ���
    -- ============================================
    divide_item(
       in_file_if_loop_cnt -- IF���[�v�J�E���^
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �`�F�b�N�t���O�������Ă���΁A�o�^�t���O��FALSE�ɐݒ肷��
    IF g_if_data_tab(cn_check_flg) = cv_const_y THEN
      gb_insert_flg  :=  FALSE;
    END IF;
--
    -- �K�{���ڂ̃`�F�b�N
    IF    g_if_data_tab(cn_slip_no)             IS NULL
      OR  g_if_data_tab(cn_invoice_date)        IS NULL
      OR  g_if_data_tab(cn_outside_base_code)   IS NULL
      OR  g_if_data_tab(cn_outside_subinv_code) IS NULL
      OR  g_if_data_tab(cn_inside_base_code)    IS NULL
      OR  g_if_data_tab(cn_inside_subinv_code)  IS NULL
    THEN
      -- �K�{���ڂ�NULL�̏ꍇ
      IF g_if_data_tab(cn_slip_no) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name1;
        ELSE
          lv_err_column :=  cv_column_name1;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_invoice_date) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name2;
        ELSE
          lv_err_column :=  cv_column_name2;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_outside_base_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name3;
        ELSE
          lv_err_column :=  cv_column_name3;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_outside_subinv_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name4;
        ELSE
          lv_err_column :=  cv_column_name4;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_inside_base_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name5;
        ELSE
          lv_err_column :=  cv_column_name5;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_inside_subinv_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name6;
        ELSE
          lv_err_column :=  cv_column_name6;
        END IF;
      END IF;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10149
                     ,iv_token_name1  =>  cv_tkn_param
                     ,iv_token_value1 =>  lv_err_column
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- �o�ɑ����_�R�[�h�Ɠ��ɑ����_�R�[�h�̃`�F�b�N
    IF g_if_data_tab(cn_outside_base_code) = g_if_data_tab(cn_inside_base_code) THEN
      -- ���_�R�[�h����v���Ă�����G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10744
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- �i�ڃ}�X�^�̃`�F�b�N
    -- �e�i�ڂ��w�肳��Ă���ꍇ
    IF g_if_data_tab(cn_parent_item_code) IS NOT NULL THEN
--
      lt_parent_item_code :=  g_if_data_tab(cn_parent_item_code);
--
      BEGIN
--
        ln_parent_case_in_qty :=  0;
--
        SELECT  msib.inventory_item_id
               ,NVL(TO_NUMBER(iimb.attribute11), 0)
        INTO    lt_parent_item_id
               ,ln_parent_case_in_qty
        FROM    mtl_system_items_b  msib
               ,ic_item_mst_b       iimb
        WHERE   msib.organization_id  = gn_inv_org_id
        AND     msib.segment1         = g_if_data_tab(cn_parent_item_code)
        AND     iimb.item_no          = msib.segment1
        ;
--
        -- ������NULL��0�Ȃ�G���[
        IF ln_parent_case_in_qty = cn_zero THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10680
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_parent_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
        END IF;
--
        ln_reserved_quantity_req  :=  ( NVL(TO_NUMBER(g_if_data_tab(cn_case_qty)), 0) * ln_parent_case_in_qty ) + NVL(TO_NUMBER(g_if_data_tab(cn_singly_qty)), 0);
--
      EXCEPTION
        -- �擾���ʂ�0���̏ꍇ
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10227
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_parent_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      END;
--
    END IF;
--
    -- �q�i�ڂ��w�肳��Ă���ꍇ
    IF g_if_data_tab(cn_child_item_code) IS NOT NULL THEN
--
      BEGIN
--
        ln_parent_case_in_qty :=  0;
        ln_child_case_in_qty  :=  0;
--
        SELECT  msib.inventory_item_id
               ,msib_p.inventory_item_id
               ,msib_p.segment1
               ,NVL(TO_NUMBER(iimb_p.attribute11), 0)
               ,NVL(TO_NUMBER(iimb.attribute11), 0)
        INTO    lt_child_item_id
               ,lt_parent_item_id
               ,lt_parent_item_code
               ,ln_parent_case_in_qty
               ,ln_child_case_in_qty
        FROM    ic_item_mst_b          iimb
               ,mtl_system_items_b     msib
               ,xxcmn_item_mst_b       ximb
               ,xxcmm_system_items_b   xsib
               ,mtl_system_items_b     msib_p
               ,ic_item_mst_b          iimb_p
        WHERE   iimb.item_no          = g_if_data_tab(cn_child_item_code)
        AND     iimb.item_id          = ximb.item_id
        AND     gd_process_date BETWEEN ximb.start_date_active AND ximb.end_date_active
        AND     iimb.item_no          = msib.segment1
        AND     msib.organization_id  = gn_inv_org_id
        AND     iimb.item_no          = xsib.item_code
        AND     xsib.item_status      IN ( '30' ,'40' ,'50' )
        AND     ximb.parent_item_id   = iimb_p.item_id
        AND     iimb_p.item_no        = msib_p.segment1
        AND     msib.organization_id  = msib_p.organization_id
        ;
--
        -- ������NULL��0�Ȃ�G���[
        IF ln_parent_case_in_qty = cn_zero THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10680
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  lt_parent_item_code
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
        END IF;
--
        IF ln_child_case_in_qty = cn_zero THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10680
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_child_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
        END IF;
--
        ln_reserved_quantity_req  :=  ( NVL(TO_NUMBER(g_if_data_tab(cn_case_qty)), 0) * ln_child_case_in_qty ) + NVL(TO_NUMBER(g_if_data_tab(cn_singly_qty)), 0);
--
      EXCEPTION
        -- �擾���ʂ�0���̏ꍇ
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10227
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_child_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      END;
--
    END IF;
--
--  V1.1 Added START
    --  ������0�`�F�b�N�i����0����̍쐬�s�j
    IF ln_reserved_quantity_req = 0 THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                      , iv_name         =>  cv_msg_coi_10226
                    );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
    --
    lv_errbuf2  :=  NULL;
    --  �݌ɉ�v���Ԃ̃`�F�b�N
    IF g_if_data_tab(cn_invoice_date) IS NOT NULL THEN
      xxcoi_common_pkg.org_acct_period_chk(
          in_organization_id  =>  gn_inv_org_id                                               --  �݌ɑg�DID
        , id_target_date      =>  TO_DATE( g_if_data_tab(cn_invoice_date), cv_date_format )   --  �`�[���t
        , ob_chk_result       =>  lb_org_acct_period_flg                                      --  �`�F�b�N����
        , ov_errbuf           =>  lv_errbuf2
        , ov_retcode          =>  lv_retcode
        , ov_errmsg           =>  lv_errmsg
      );
      --  �݌ɉ�v���ԃX�e�[�^�X�̎擾�Ɏ��s�����ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_00026
                        , iv_token_name1    =>  cv_tkn_target_date
                        , iv_token_value1   =>  g_if_data_tab(cn_invoice_date)
                      );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      ELSIF ( NOT lb_org_acct_period_flg ) THEN
        --  �݌ɉ�v���Ԃ��N���[�Y�̏ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10231
                        , iv_token_name1    =>  cv_tkn_invoice_date
                        , iv_token_value1   =>  g_if_data_tab(cn_invoice_date)
                      );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      END IF;
    END IF;
--  V1.1 Added END
--
    -- �o�ɑ����_�A�o�ɑ��ۊǏꏊ�R�[�h�A���ɑ����_�A���ɑ��ۊǏꏊ�R�[�h�̎擾�i�����_�֏o�Ɂj
    lv_errbuf2  :=  NULL;
--
    xxcoi_common_pkg.convert_subinv_code(
      iv_record_type                =>  cv_record_type                        -- ���R�[�h���
     ,iv_invoice_type               =>  cv_invoice_type2                      -- �`�[�敪
     ,iv_department_flag            =>  cv_department_flag                    -- �S�ݓX�t���O
     ,iv_base_code                  =>  g_if_data_tab(cn_outside_base_code)   -- ���_�R�[�h
     ,iv_outside_code               =>  g_if_data_tab(cn_outside_subinv_code) -- �o�ɑ��R�[�h
     ,iv_inside_code                =>  g_if_data_tab(cn_inside_base_code)    -- ���ɑ��R�[�h
     ,id_transaction_date           =>  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
                                                                              -- �����
     ,in_organization_id            =>  gn_inv_org_id                         -- �݌ɑg�DID
     ,iv_hht_form_flag              =>  cv_const_y                            -- HHT������͉�ʃt���O
     ,ov_outside_subinv_code        =>  lt_chg_start_subinv_code              -- �o�ɑ��ۊǏꏊ�R�[�h
     ,ov_inside_subinv_code         =>  lt_chg_via_subinv_code                -- ���ɑ��ۊǏꏊ�R�[�h
     ,ov_outside_base_code          =>  lt_chg_start_base_code                -- �o�ɑ����_�R�[�h
     ,ov_inside_base_code           =>  lt_chg_via_base_code                  -- ���ɑ����_�R�[�h
     ,ov_outside_subinv_code_conv   =>  lt_chg_outside_subinv_conv            -- �o�ɑ��ۊǏꏊ�ϊ��敪
     ,ov_inside_subinv_code_conv    =>  lt_chg_inside_subinv_conv             -- ���ɑ��ۊǏꏊ�ϊ��敪
     ,ov_outside_business_low_type  =>  lt_outside_business_low_type          -- �o�ɑ��Ƒԏ�����(�g�p���Ȃ�)
     ,ov_inside_business_low_type   =>  lt_inside_business_low_type           -- ���ɑ��Ƒԏ�����(�g�p���Ȃ�)
     ,ov_outside_cust_code          =>  lt_outside_cust_code                  -- �o�ɑ��ڋq�R�[�h(�g�p���Ȃ�)
     ,ov_inside_cust_code           =>  lt_inside_cust_code                   -- ���ɑ��ڋq�R�[�h(�g�p���Ȃ�)
     ,ov_hht_program_div            =>  lt_chg_program_div                    -- ���o�ɃW���[�i�������敪
     ,ov_item_convert_div           =>  lt_chg_item_convert_div               -- ���i�U�֋敪
     ,ov_stock_uncheck_list_div     =>  lt_chg_stock_uncheck_list_div         -- ���ɖ��m�F���X�g�Ώۋ敪
     ,ov_stock_balance_list_div     =>  lt_chg_stock_balance_list_div         -- ���ɍ��يm�F���X�g�Ώۋ敪
     ,ov_consume_vd_flag            =>  lt_chg_consume_vd_flag                -- ����VD��[�Ώۃt���O
     ,ov_outside_subinv_div         =>  lt_outside_subinv_div                 -- �o�ɑ��I���Ώ�(�g�p���Ȃ�)
     ,ov_inside_subinv_div          =>  lt_inside_subinv_div                  -- ���ɑ��I���Ώ�(�g�p���Ȃ�)
     ,ov_retcode                    =>  lv_retcode                            -- ���^�[���E�R�[�h(1:����A2:�G���[)
     ,ov_errbuf                     =>  lv_errbuf2                            -- �G���[���b�Z�[�W
     ,ov_errmsg                     =>  lv_errmsg                             -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �o�ɑ��ۊǏꏊ��NULL�̏ꍇ
    IF ( lt_chg_start_subinv_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                   , iv_name         => cv_msg_coi_10278
                   , iv_token_name1  => cv_tkn_record_type
                   , iv_token_value1 => cv_record_type
                   , iv_token_name2  => cv_tkn_invoice_type
                   , iv_token_value2 => cv_invoice_type2
                   , iv_token_name3  => cv_tkn_department_flag
                   , iv_token_value3 => cv_department_flag
                   , iv_token_name4  => cv_tkn_base_code
                   , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                   , iv_token_name5  => cv_tkn_code
                   , iv_token_value5 => g_if_data_tab(cn_outside_subinv_code)
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- �o�ɑ����_��NULL�̏ꍇ
    ELSIF ( lt_chg_start_base_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10279
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type2
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_outside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- ���ɑ��ۊǏꏊ��NULL�̏ꍇ
    ELSIF ( lt_chg_via_subinv_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10276
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type2
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- ���ɑ����_��NULL�̏ꍇ
    ELSIF ( lt_chg_via_base_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10277
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type2
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- �o�ɑ����_�A�o�ɑ��ۊǏꏊ�R�[�h�A���ɑ����_�A���ɑ��ۊǏꏊ�R�[�h�̎擾(�q�ɂ���c�ƎԂ�)
    lv_errbuf2  :=  NULL;
--
    xxcoi_common_pkg.convert_subinv_code(
      iv_record_type                =>  cv_record_type                        -- ���R�[�h���
     ,iv_invoice_type               =>  cv_invoice_type                       -- �`�[�敪
     ,iv_department_flag            =>  cv_department_flag                    -- �S�ݓX�t���O
     ,iv_base_code                  =>  lt_chg_via_base_code                  -- ���_�R�[�h
     ,iv_outside_code               =>  SUBSTR(lt_chg_via_subinv_code, -2)    -- �o�ɑ��R�[�h
     ,iv_inside_code                =>  g_if_data_tab(cn_inside_subinv_code)  -- ���ɑ��R�[�h
     ,id_transaction_date           =>  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
                                                                              -- �����
     ,in_organization_id            =>  gn_inv_org_id                         -- �݌ɑg�DID
     ,iv_hht_form_flag              =>  cv_const_y                            -- HHT������͉�ʃt���O
     ,ov_outside_subinv_code        =>  lt_io_start_subinv_code               -- �o�ɑ��ۊǏꏊ�R�[�h
     ,ov_inside_subinv_code         =>  lt_io_via_subinv_code                 -- ���ɑ��ۊǏꏊ�R�[�h
     ,ov_outside_base_code          =>  lt_io_start_base_code                 -- �o�ɑ����_�R�[�h
     ,ov_inside_base_code           =>  lt_io_via_base_code                   -- ���ɑ����_�R�[�h
     ,ov_outside_subinv_code_conv   =>  lt_io_outside_subinv_conv             -- �o�ɑ��ۊǏꏊ�ϊ��敪
     ,ov_inside_subinv_code_conv    =>  lt_io_inside_subinv_conv              -- ���ɑ��ۊǏꏊ�ϊ��敪
     ,ov_outside_business_low_type  =>  lt_outside_business_low_type          -- �o�ɑ��Ƒԏ�����(�g�p���Ȃ�)
     ,ov_inside_business_low_type   =>  lt_inside_business_low_type           -- ���ɑ��Ƒԏ�����(�g�p���Ȃ�)
     ,ov_outside_cust_code          =>  lt_outside_cust_code                  -- �o�ɑ��ڋq�R�[�h(�g�p���Ȃ�)
     ,ov_inside_cust_code           =>  lt_inside_cust_code                   -- ���ɑ��ڋq�R�[�h(�g�p���Ȃ�)
     ,ov_hht_program_div            =>  lt_io_program_div                     -- ���o�ɃW���[�i�������敪
     ,ov_item_convert_div           =>  lt_io_item_convert_div                -- ���i�U�֋敪
     ,ov_stock_uncheck_list_div     =>  lt_io_stock_uncheck_list_div          -- ���ɖ��m�F���X�g�Ώۋ敪
     ,ov_stock_balance_list_div     =>  lt_io_stock_balance_list_div          -- ���ɍ��يm�F���X�g�Ώۋ敪
     ,ov_consume_vd_flag            =>  lt_io_consume_vd_flag                 -- ����VD��[�Ώۃt���O
     ,ov_outside_subinv_div         =>  lt_outside_subinv_div                 -- �o�ɑ��I���Ώ�(�g�p���Ȃ�)
     ,ov_inside_subinv_div          =>  lt_inside_subinv_div                  -- ���ɑ��I���Ώ�(�g�p���Ȃ�)
     ,ov_retcode                    =>  lv_retcode                            -- ���^�[���E�R�[�h(1:����A2:�G���[)
     ,ov_errbuf                     =>  lv_errbuf2                            -- �G���[���b�Z�[�W
     ,ov_errmsg                     =>  lv_errmsg                             -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �o�ɑ��ۊǏꏊ��NULL�̏ꍇ
    IF ( lt_io_start_subinv_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                   , iv_name         => cv_msg_coi_10278
                   , iv_token_name1  => cv_tkn_record_type
                   , iv_token_value1 => cv_record_type
                   , iv_token_name2  => cv_tkn_invoice_type
                   , iv_token_value2 => cv_invoice_type
                   , iv_token_name3  => cv_tkn_department_flag
                   , iv_token_value3 => cv_department_flag
                   , iv_token_name4  => cv_tkn_base_code
                   , iv_token_value4 => lt_chg_via_base_code
                   , iv_token_name5  => cv_tkn_code
                   , iv_token_value5 => SUBSTR(lt_chg_via_subinv_code, -2)
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- �o�ɑ����_��NULL�̏ꍇ
    ELSIF ( lt_io_start_base_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10279
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => lt_chg_via_base_code
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => SUBSTR(lt_chg_via_subinv_code, -2)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- ���ɑ��ۊǏꏊ��NULL�̏ꍇ
    ELSIF ( lt_io_via_subinv_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10276
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => lt_chg_via_base_code
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- ���ɑ����_��NULL�̏ꍇ
    ELSIF ( lt_io_via_base_code IS NULL ) THEN
      -- �G���[���b�Z�[�W�̎擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10277
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => lt_chg_via_base_code
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- �����_�c�Ǝԓ��o�ɃZ�L�����e�B�}�X�^�i�o�Ɉ˗��p�j�̊m�F
--
    -- ===============================
    -- ���O�C�����[�U�̏������_���擾
    -- ===============================
    xxcoi_common_pkg.get_belonging_base(
        in_user_id     => cn_created_by     -- 1.���[�U�[ID
      , id_target_date => cd_creation_date  -- 2.�Ώۓ�
      , ov_base_code   => lt_base_code      -- 3.���_�R�[�h
      , ov_errbuf      => lv_errbuf2        -- 4.�G���[�E���b�Z�[�W
      , ov_retcode     => lv_retcode        -- 5.���^�[���E�R�[�h
      , ov_errmsg      => lv_errmsg         -- 6.���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_00010
                     , iv_token_name1  => cv_tkn_api_name
                     , iv_token_value1 => cv_api_belogin
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      lt_base_code  :=  NULL;
    END IF;
--
    BEGIN
      SELECT  1
      INTO    ln_dummy
      FROM    fnd_lookup_values   flv   -- �N�C�b�N�R�[�h
            , xxcoi_base_info2_v  xbiv
      WHERE   flv.lookup_type               =   cv_type_bargain_class
      AND     SUBSTR(flv.lookup_code, 1, 4) =   g_if_data_tab(cn_outside_base_code)
      AND     SUBSTR(flv.meaning, 1, 4)     =   g_if_data_tab(cn_inside_base_code)
      AND     flv.enabled_flag              =   cv_const_y
      AND     flv.language                  =   ct_lang
      AND     NVL(flv.start_date_active, TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)) <= TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
      AND     NVL(flv.end_date_active, TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format))   >= TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
      AND     xbiv.focus_base_code          =   lt_base_code
      AND     SUBSTR(flv.lookup_code, 1, 4) =   xbiv.base_code
      ;
    EXCEPTION
      -- �擾���ʂ�0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10741
                     );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END;
--
    -- ���ɑ��ۊǏꏊ�̃`�F�b�N
    -- ���C���q�ɂ̑q�ɊǗ��Ώۋ敪���擾
    BEGIN
      SELECT  xsiv.warehouse_flag
      INTO    lt_inside_warehouse_flag
      FROM    xxcoi_subinventory_info_v  xsiv
      WHERE   xsiv.organization_id      = gn_inv_org_id
      AND     xsiv.subinventory_code    = lt_chg_via_subinv_code
      AND     xsiv.management_base_code = g_if_data_tab(cn_inside_base_code)
      AND     TRUNC( NVL(xsiv.disable_date , SYSDATE+1 ) ) > TRUNC(SYSDATE)
      AND     xsiv.main_store_class     = cv_const_y
      ;
    EXCEPTION
      -- �擾���ʂ�0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10206
                       ,iv_token_name1  =>  cv_tkn_dept_code
                       ,iv_token_value1 =>  lt_chg_via_base_code
                       ,iv_token_name2  =>  cv_tkn_whouse_code
                       ,iv_token_value2 =>  lt_chg_via_subinv_code
                     );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END;
--
    -- �q�ɊǗ��Ώۋ敪���u�Ώہv�Ȃ�G���[
    IF NVL(lt_inside_warehouse_flag, cv_const_n) = cv_const_y  THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10739
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- �o�ɑ��ۊǏꏊ�̃`�F�b�N
    -- �o�ɑ��ۊǏꏊ�̑q�ɊǗ��Ώۋ敪���擾
    BEGIN
      SELECT  xsiv.warehouse_flag
      INTO    lt_outside_warehouse_flag
      FROM    xxcoi_subinventory_info_v  xsiv
      WHERE   xsiv.organization_id      = gn_inv_org_id
      AND     xsiv.subinventory_code    = lt_chg_start_subinv_code
      AND     TRUNC( NVL(xsiv.disable_date, SYSDATE+1 ) )  >  TRUNC( SYSDATE )
      AND     xsiv.subinventory_class   = cv_subinventory_class_1
      ;
    EXCEPTION
      -- �擾���ʂ�0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10206
                       ,iv_token_name1  =>  cv_tkn_dept_code
                       ,iv_token_value1 =>  lt_chg_start_base_code
                       ,iv_token_name2  =>  cv_tkn_whouse_code
                       ,iv_token_value2 =>  lt_chg_start_subinv_code
                     );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END;
--
    -- �q�ɊǗ��Ώۋ敪���u�Ώہv�łȂ��Ȃ�G���[
    IF NVL(lt_outside_warehouse_flag, cv_const_n)  <>  cv_const_y  THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10740
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- ���o�Ɉꎞ�\�o�^�p�̃f�[�^���L�^����
    gt_inout_info_tab(gn_inout_count).slip_no                     :=  g_if_data_tab(cn_slip_no);                        -- �`�[�ԍ�
    gt_inout_info_tab(gn_inout_count).invoice_date                :=  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format);
                                                                                                                        -- �`�[���t
    gt_inout_info_tab(gn_inout_count).outside_subinv_code         :=  g_if_data_tab(cn_outside_subinv_code);            -- �o�ɑ��R�[�h
    gt_inout_info_tab(gn_inout_count).inside_subinv_code          :=  g_if_data_tab(cn_inside_subinv_code);             -- ���ɑ��R�[�h
--
    -- ������0�̏ꍇ��0���Z�ɂȂ�̂ŏ��Z�����Ȃ�
    IF ln_parent_case_in_qty <> cn_zero THEN
      -- �P�[�X��
      gt_inout_info_tab(gn_inout_count).case_qty                    :=  ( ln_reserved_quantity_req - MOD( ln_reserved_quantity_req, ln_parent_case_in_qty ) ) / ln_parent_case_in_qty;
      -- �o����
      gt_inout_info_tab(gn_inout_count).singly_qty                  :=  MOD( ln_reserved_quantity_req, ln_parent_case_in_qty );
    ELSE
      -- �P�[�X��
      gt_inout_info_tab(gn_inout_count).case_qty                    :=  0;
      -- �o����
      gt_inout_info_tab(gn_inout_count).singly_qty                  :=  ln_reserved_quantity_req;
    END IF;
    gt_inout_info_tab(gn_inout_count).case_in_quantity            :=  ln_parent_case_in_qty;                            -- ����
    gt_inout_info_tab(gn_inout_count).parent_item_id              :=  lt_parent_item_id;                                -- �e�i��ID
    gt_inout_info_tab(gn_inout_count).parent_item_code            :=  lt_parent_item_code;                              -- �e�i��
    gt_inout_info_tab(gn_inout_count).outside_base_code           :=  g_if_data_tab(cn_outside_base_code);              -- �o�ɑ����_�R�[�h
    gt_inout_info_tab(gn_inout_count).inside_base_code            :=  g_if_data_tab(cn_inside_base_code);               -- ���ɑ����_�R�[�h
--
    -- �q�ցiCHANGE�j
    gt_inout_info_tab(gn_inout_count).chg_start_subinv_code       :=  lt_chg_start_subinv_code;                         -- �o�ɑ��ۊǏꏊ�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_via_subinv_code         :=  lt_chg_via_subinv_code;                           -- ���ɑ��ۊǏꏊ�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_start_base_code         :=  lt_chg_start_base_code;                           -- �o�ɑ����_�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_via_base_code           :=  lt_chg_via_base_code;                             -- ���ɑ����_�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_outside_subinv_conv     :=  lt_chg_outside_subinv_conv;                       -- �o�ɑ��ۊǏꏊ�ϊ��敪�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_inside_subinv_conv      :=  lt_chg_inside_subinv_conv;                        -- ���ɑ��ۊǏꏊ�ϊ��敪�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_program_div             :=  lt_chg_program_div;                               -- ���o�ɃW���[�i�������敪�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_consume_vd_flag         :=  lt_chg_consume_vd_flag;                           -- ����VD��[�Ώۃt���O�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_item_convert_div        :=  lt_chg_item_convert_div;                          -- ���i�U�֋敪�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_stock_uncheck_list_div  :=  lt_chg_stock_uncheck_list_div;                    -- ���ɖ��m�F���X�g�Ώۋ敪�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_stock_balance_list_div  :=  lt_chg_stock_balance_list_div;                    -- ���ɍ��يm�F���X�g�Ώۋ敪�i�����_�֏o�Ɂj
    gt_inout_info_tab(gn_inout_count).chg_other_base_code         :=  lt_chg_via_base_code;                             -- �����_�R�[�h�i�����_�֏o�Ɂj
--
    -- ���o�ɁiIN/OUT�j
    gt_inout_info_tab(gn_inout_count).io_start_subinv_code        :=  lt_io_start_subinv_code;                          -- �o�ɑ��ۊǏꏊ�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_via_subinv_code          :=  lt_io_via_subinv_code;                            -- ���ɑ��ۊǏꏊ�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_start_base_code          :=  lt_io_start_base_code;                            -- �o�ɑ����_�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_via_base_code            :=  lt_io_via_base_code;                              -- ���ɑ����_�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_outside_subinv_conv      :=  lt_io_outside_subinv_conv;                        -- �o�ɑ��ۊǏꏊ�ϊ��敪�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_inside_subinv_conv       :=  lt_io_inside_subinv_conv;                         -- ���ɑ��ۊǏꏊ�ϊ��敪�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_program_div              :=  lt_io_program_div;                                -- ���o�ɃW���[�i�������敪�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_consume_vd_flag          :=  lt_io_consume_vd_flag;                            -- ����VD��[�Ώۃt���O�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_item_convert_div         :=  lt_io_item_convert_div;                           -- ���i�U�֋敪�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_stock_uncheck_list_div   :=  lt_io_stock_uncheck_list_div;                     -- ���ɖ��m�F���X�g�Ώۋ敪�i�q�ɂ���c�ƎԂցj
    gt_inout_info_tab(gn_inout_count).io_stock_balance_list_div   :=  lt_io_stock_balance_list_div;                     -- ���ɍ��يm�F���X�g�Ώۋ敪�i�q�ɂ���c�ƎԂցj
--
    lv_errbuf2  :=  NULL;
    -- ���ʂ̃`�F�b�N�̌Ăяo��
    quantity_check(
        it_child_item_id          =>  lt_child_item_id                  -- �q�i��ID
       ,it_parent_item_id         =>  lt_parent_item_id                 -- �e�i��ID
       ,it_inout_info             =>  gt_inout_info_tab(gn_inout_count) -- ���b�g���f�[�^���R�[�h
       ,in_reserved_quantity_req  =>  ln_reserved_quantity_req          -- �����˗���
       ,ov_errbuf                 =>  lv_errbuf2                        -- �G���[�E���b�Z�[�W
       ,ov_retcode                =>  lv_retcode                        -- ���^�[���E�R�[�h
       ,ov_errmsg                 =>  lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- ���^�[���R�[�h��'0'�i����j�ȊO�̏ꍇ�̓G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- ���̓��o�ɕ\���쐬���邽�߁A�J�E���g��������
    gn_inout_count :=  gn_inout_count + 1;
--
    -- �G���[�����̐ݒ�
    IF ( lv_errbuf IS NOT NULL ) THEN
      -- �G���[���������Ă���ꍇ�A�G���[�������J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      -- �`�F�b�N���ʂ�NG�ɂ���B
      gv_check_result :=  cv_const_n;
      -- �G���[���b�Z�[�W���o�͂ɕ\������B
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10749
                     ,iv_token_name1  =>  cv_tkn_param
                     ,iv_token_value1 =>  in_file_if_loop_cnt
                     ,iv_token_name2  =>  cv_tkn_param2
                     ,iv_token_value2 =>  g_if_data_tab(cn_slip_no)
                     ,iv_token_name3  =>  cv_tkn_param3
                     ,iv_token_value3 =>  g_if_data_tab(cn_invoice_date)
                     ,iv_token_name4  =>  cv_tkn_param4
                     ,iv_token_value4 =>  g_if_data_tab(cn_outside_base_code)
                     ,iv_token_name5  =>  cv_tkn_param5
                     ,iv_token_value5 =>  g_if_data_tab(cn_outside_subinv_code)
                     ,iv_token_name6  =>  cv_tkn_param6
                     ,iv_token_value6 =>  g_if_data_tab(cn_inside_base_code)
                     ,iv_token_name7  =>  cv_tkn_param7
                     ,iv_token_value7 =>  g_if_data_tab(cn_inside_subinv_code)
                     ,iv_token_name8  =>  cv_tkn_param8
                     ,iv_token_value8 =>  g_if_data_tab(cn_parent_item_code)
                     ,iv_token_name9  =>  cv_tkn_param9
                     ,iv_token_value9 =>  g_if_data_tab(cn_child_item_code)
                   );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => chr(10) || lv_errmsg || lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
--
    -- ���������̐ݒ�
    ELSE
      -- �G���[�������ꍇ�́A���������Ƃ��ăJ�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END err_check;
--
    /**********************************************************************************
   * Procedure Name   : cre_inv_transactions
   * Description      : ���o�ɏ��̍쐬(A-6)
   ***********************************************************************************/
  PROCEDURE cre_inv_transactions(
    ov_errbuf             OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_inv_transactions'; -- �v���O������
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
    ln_count                  NUMBER;         -- �J�E���g�p�ϐ�
    ln_count2                 NUMBER;         -- �J�E���g�p�ϐ�2
    lv_chg_slip_no            VARCHAR2(100);  -- �`�[�ԍ�(�q��)
    lv_io_slip_no             VARCHAR2(100);  -- �`�[�ԍ�(���o��)
    lv_output_slip_no         VARCHAR2(100);  -- �`�[�ԍ�(�o�͊m�F�p)
    ld_interface_date         DATE;           -- ��M����
    ln_transaction_id         NUMBER;         -- ���o�Ɉꎞ�\ID
    lv_status                 VARCHAR2(1);    -- �����X�e�[�^�X
    lt_primary_uom_code       xxcoi_txn_enable_item_info_v.primary_uom_code%TYPE; -- ��P�ʃR�[�h
    lv_goods_product_class    VARCHAR2(100);                                      -- �v���t�@�C���F�J�e�S���Z�b�g��
    lv_chg_invoice_no         xxcoi_hht_inv_transactions.invoice_no%TYPE;         -- �`�[No(�q��)
    lv_io_invoice_no          xxcoi_hht_inv_transactions.invoice_no%TYPE;         -- �`�[No(���o��)
    lv_message_slip           VARCHAR2(5000); -- ���[No�o�̓��b�Z�[�W
    lb_err_flg                BOOLEAN;        -- �G���[����
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
    -- ���[�J���ϐ�������
    lv_goods_product_class  :=  FND_PROFILE.VALUE(cv_goods_product_cls);
    ln_count                :=  1;
    ld_interface_date       :=  SYSDATE;
    lv_errbuf               :=  NULL;
    lv_chg_invoice_no       :=  NULL;
    lv_io_invoice_no        :=  NULL;
    lv_chg_slip_no          :=  ' ';
    lv_io_slip_no           :=  ' ';
    lv_output_slip_no       :=  ' ';
--
    <<inv_transactions_loop>>
    LOOP
--
      -- �J�E���g�����R�[�h�^�ϐ��ɓo�^���������̍ő�l�ɒB���Ă����烋�[�v�𔲂���
      IF ln_count = gn_inout_count THEN
        EXIT;
      END IF;
--
      -- ���o�Ɉꎞ�\ID�̎擾
      BEGIN
--
        SELECT  xxcoi.xxcoi_hht_inv_transactions_s01.nextval
        INTO    ln_transaction_id
        FROM    dual
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �G���[���b�Z�[�W�̎擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10294
                       );
          RAISE global_process_expt;
      END;
--
      -- �`�[No�擾�i���łɁA����`�[�ԍ��œ`�[No�𔭍s���Ă���ꍇ�͐V���ɍ̔Ԃ��Ȃ��j
      IF gt_inout_info_tab(ln_count).slip_no <> lv_chg_slip_no THEN
--
        lv_chg_invoice_no :=  NULL;
--
        BEGIN
--
          SELECT  'E' || LTRIM(TO_CHAR(xxcoi.xxcoi_invoice_no_s01.nextval,'00000000'))
          INTO    lv_chg_invoice_no
          FROM    dual
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �G���[���b�Z�[�W�̎擾
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                           , iv_name         => cv_msg_coi_10284
                         );
            RAISE global_process_expt;
        END;
--
        lv_chg_slip_no  :=  gt_inout_info_tab(ln_count).slip_no;
--
      END IF;
--
      -- ���b�g���ɕK�v�ȏ���ێ�����
      ln_count2 :=  1;
      <<lot_info_loop>>
      LOOP
--
        -- �o�ɏ��ƈ�v���郍�b�g���Ƀf�[�^��o�^����
        -- (�`�[�ԍ��ł́A�����s�ɓ���̔ԍ������݂��邽�߁ACSV�̍s���œ��ꃌ�R�[�h�𔻒f����)
        IF gt_lot_info_tab(ln_count2).csv_no = ln_count THEN
--
          gt_lot_info_tab(ln_count2).transaction_id :=  ln_transaction_id;
          gt_lot_info_tab(ln_count2).invoice_no     :=  lv_chg_invoice_no;
--
        END IF;
--
        ln_count2 :=  ln_count2 + 1;
--
        IF ln_count2 = gn_lot_count THEN
          EXIT;
        END IF;
--
      END LOOP lot_info_loop;
--
      -- ��P�ʃR�[�h�̎擾
      BEGIN
        SELECT  xteiiv.primary_uom_code
        INTO    lt_primary_uom_code
        FROM    xxcoi_txn_enable_item_info_v  xteiiv
               ,mtl_category_sets_tl          mcst
               ,mtl_category_sets_b           mcsb
               ,mtl_categories_b              mcb
               ,mtl_item_categories           mic
        WHERE   mcst.category_set_name  = lv_goods_product_class
        AND     mcst.language           = ct_language
        AND     mcsb.category_set_id    = mcst.category_set_id
        AND     mcb.structure_id        = mcsb.structure_id
        AND     mcb.segment1            IN ( cv_segment1_1, cv_segment1_2 )
        AND     mic.category_id         = mcb.category_id
        AND     mic.inventory_item_id   = xteiiv.inventory_item_id
        AND     mic.organization_id     = xteiiv.organization_id
        AND     TO_CHAR(gt_inout_info_tab(ln_count).invoice_date, cv_date_format)
                                        BETWEEN TO_CHAR(xteiiv.start_date_active, cv_date_format)
                                        AND     TO_CHAR(NVL(xteiiv.end_date_active, gt_inout_info_tab(ln_count).invoice_date), cv_date_format)
        AND     mic.inventory_item_id   = gt_inout_info_tab(ln_count).parent_item_id
        ;
--
      EXCEPTION
        -- �擾���ʂ�0���̏ꍇ
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10132
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  gt_inout_info_tab(ln_count).parent_item_code
                       );
          RAISE global_process_expt;
      END;
--
      -- ���o�ɃW���[�i�������敪�̒l�ɂ��A�����X�e�[�^�X��ݒ�
      IF gt_inout_info_tab(ln_count).chg_program_div = cv_program_div_0 THEN
        lv_status :=  cv_status_1;
      ELSE
        lv_status :=  cv_status_0;
      END IF;
--
      BEGIN
        -- HHT���o�Ɉꎞ�\�ւ̓o�^(�����_�֏o��)
        INSERT INTO xxcoi_hht_inv_transactions(
          transaction_id                        -- ���o�Ɉꎞ�\ID
         ,interface_id                          -- �C���^�[�t�F�[�XID
         ,form_header_id                        -- ��ʓ��͗p�w�b�_ID
         ,base_code                             -- ���_�R�[�h
         ,record_type                           -- ���R�[�h���
         ,employee_num                          -- �c�ƈ��R�[�h
         ,invoice_no                            -- �`�[��
         ,item_code                             -- �i�ڃR�[�h�i�i���R�[�h�j
         ,case_quantity                         -- �P�[�X��
         ,case_in_quantity                      -- ����
         ,quantity                              -- �{��
         ,invoice_type                          -- �`�[�敪
         ,base_delivery_flag                    -- ���_�ԑq�փt���O
         ,outside_code                          -- �o�ɑ��R�[�h
         ,inside_code                           -- ���ɑ��R�[�h
         ,invoice_date                          -- �`�[���t
         ,column_no                             -- �R������
         ,unit_price                            -- �P��
         ,hot_cold_div                          -- H/C
         ,department_flag                       -- �S�ݓX�t���O
         ,interface_date                        -- ��M����
         ,other_base_code                       -- �����_�R�[�h
         ,outside_subinv_code                   -- �o�ɑ��ۊǏꏊ
         ,inside_subinv_code                    -- ���ɑ��ۊǏꏊ
         ,outside_base_code                     -- �o�ɑ����_
         ,inside_base_code                      -- ���ɑ����_
         ,total_quantity                        -- ���{��
         ,inventory_item_id                     -- �i��ID
         ,primary_uom_code                      -- ��P��
         ,outside_subinv_code_conv_div          -- �o�ɑ��ۊǏꏊ�ϊ��敪
         ,inside_subinv_code_conv_div           -- ���ɑ��ۊǏꏊ�ϊ��敪
         ,outside_business_low_type             -- �o�ɑ��Ƒԋ敪
         ,inside_business_low_type              -- ���ɑ��Ƒԋ敪
         ,outside_cust_code                     -- �o�ɑ��ڋq�R�[�h
         ,inside_cust_code                      -- ���ɑ��ڋq�R�[�h
         ,hht_program_div                       -- ���o�ɃW���[�i�������敪
         ,consume_vd_flag                       -- ����VD��[�Ώۃt���O
         ,item_convert_div                      -- ���i�U�֋敪
         ,stock_uncheck_list_div                -- ���ɖ��m�F���X�g�Ώۋ敪
         ,stock_balance_list_div                -- ���ɍ��يm�F���X�g�Ώۋ敪
         ,status                                -- �����X�e�[�^�X
         ,column_if_flag                        -- �R�����ʓ]���σt���O
         ,column_if_date                        -- �R�����ʓ]����
         ,sample_if_flag                        -- ���{�]���σt���O
         ,sample_if_date                        -- ���{�]����
         ,output_flag                           -- �o�͍σt���O
         ,last_update_date                      -- �ŏI�X�V��
         ,last_updated_by                       -- �ŏI�X�V��
         ,creation_date                         -- �쐬��
         ,created_by                            -- �쐬��
         ,last_update_login                     -- �ŏI�X�V���[�U
         ,request_id                            -- �v��ID
         ,program_application_id                -- �v���O�����A�v���P�[�V����ID
         ,program_id                            -- �v���O����ID
         ,program_update_date)                  -- �v���O�����X�V��
        VALUES(
          ln_transaction_id                                       -- ���o�Ɉꎞ�\ID
         ,NULL                                                    -- �C���^�[�t�F�[�XID
         ,NULL                                                    -- ��ʓ��͗p�w�b�_ID
         ,gt_inout_info_tab(ln_count).outside_base_code           -- ���_�R�[�h
         ,cv_record_type                                          -- ���R�[�h���
         ,NULL                                                    -- �c�ƈ��R�[�h
         ,lv_chg_invoice_no                                       -- �`�[��
         ,gt_inout_info_tab(ln_count).parent_item_code            -- �i�ڃR�[�h�i�i���R�[�h�j
         ,gt_inout_info_tab(ln_count).case_qty                    -- �P�[�X��
         ,gt_inout_info_tab(ln_count).case_in_quantity            -- ����
         ,gt_inout_info_tab(ln_count).singly_qty                  -- �{��
         ,cv_invoice_type2                                        -- �`�[�敪
         ,cn_zero                                                 -- ���_�ԑq�փt���O
         ,gt_inout_info_tab(ln_count).outside_subinv_code         -- �o�ɑ��R�[�h
         ,gt_inout_info_tab(ln_count).inside_base_code            -- ���ɑ��R�[�h
         ,gt_inout_info_tab(ln_count).invoice_date                -- �`�[���t
         ,NULL                                                    -- �R������
         ,0                                                       -- �P��
         ,NULL                                                    -- H/C
         ,cv_department_flag                                      -- �S�ݓX�t���O
         ,ld_interface_date                                       -- ��M����
         ,gt_inout_info_tab(ln_count).chg_other_base_code         -- �����_�R�[�h
         ,gt_inout_info_tab(ln_count).chg_start_subinv_code       -- �o�ɑ��ۊǏꏊ
         ,gt_inout_info_tab(ln_count).chg_via_subinv_code         -- ���ɑ��ۊǏꏊ
         ,gt_inout_info_tab(ln_count).chg_start_base_code         -- �o�ɑ����_
         ,gt_inout_info_tab(ln_count).chg_via_base_code           -- ���ɑ����_
         ,(gt_inout_info_tab(ln_count).case_in_quantity * gt_inout_info_tab(ln_count).case_qty) + gt_inout_info_tab(ln_count).singly_qty
                                                                  -- ���{��
         ,gt_inout_info_tab(ln_count).parent_item_id              -- �i��ID
         ,lt_primary_uom_code                                     -- ��P��
         ,gt_inout_info_tab(ln_count).chg_outside_subinv_conv     -- �o�ɑ��ۊǏꏊ�ϊ��敪
         ,gt_inout_info_tab(ln_count).chg_inside_subinv_conv      -- ���ɑ��ۊǏꏊ�ϊ��敪
         ,NULL                                                    -- �o�ɑ��Ƒԋ敪
         ,NULL                                                    -- ���ɑ��Ƒԋ敪
         ,NULL                                                    -- �o�ɑ��ڋq�R�[�h
         ,NULL                                                    -- ���ɑ��ڋq�R�[�h
         ,gt_inout_info_tab(ln_count).chg_program_div             -- ���o�ɃW���[�i�������敪
         ,gt_inout_info_tab(ln_count).chg_consume_vd_flag         -- ����VD��[�Ώۃt���O
         ,gt_inout_info_tab(ln_count).chg_item_convert_div        -- ���i�U�֋敪
         ,gt_inout_info_tab(ln_count).chg_stock_uncheck_list_div  -- ���ɖ��m�F���X�g�Ώۋ敪
         ,gt_inout_info_tab(ln_count).chg_stock_balance_list_div  -- ���ɍ��يm�F���X�g�Ώۋ敪
         ,lv_status                                               -- �����X�e�[�^�X�i�������j
         ,cv_const_n                                              -- �R�����ʓ]���σt���O�i���]���j
         ,NULL                                                    -- �R�����ʓ]����
         ,cv_const_n                                              -- ���{�]���σt���O�i���]���j
         ,NULL                                                    -- ���{�]����
         ,cv_const_n                                              -- �o�͍σt���O�i���o�́j
         ,cd_last_update_date                                     -- �ŏI�X�V��
         ,cn_last_updated_by                                      -- �ŏI�X�V��
         ,cd_creation_date                                        -- �쐬��
         ,cn_created_by                                           -- �쐬��
         ,cn_last_update_login                                    -- �ŏI�X�V���O�C��
         ,cn_request_id                                           -- �v��ID
         ,cn_program_application_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                                           -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date                                  -- �v���O�����X�V��
        )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�̎擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                       , iv_name         => cv_msg_coi_10701
                       , iv_token_name1  => cv_tkn_err_msg
                       , iv_token_value1 => SQLERRM
                       );
          RAISE global_process_expt;
      END;
--
      -- ���o�Ɉꎞ�\ID�̎擾
      BEGIN
        ln_transaction_id :=  NULL;
--
        SELECT  xxcoi.xxcoi_hht_inv_transactions_s01.nextval
        INTO    ln_transaction_id
        FROM    dual
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �G���[���b�Z�[�W�̎擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10294
                       );
          RAISE global_process_expt;
      END;
--
      -- �`�[No�擾�i���łɁA����`�[�ԍ��œ`�[No�𔭍s���Ă���ꍇ�͐V���ɍ̔Ԃ��Ȃ��j
      IF gt_inout_info_tab(ln_count).slip_no <> lv_io_slip_no THEN
--
        lv_io_invoice_no :=  NULL;
--
        BEGIN
--
          SELECT  'E' || LTRIM(TO_CHAR(xxcoi.xxcoi_invoice_no_s01.nextval,'00000000'))
          INTO    lv_io_invoice_no
          FROM    dual
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �G���[���b�Z�[�W�̎擾
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                           , iv_name         => cv_msg_coi_10284
                         );
            RAISE global_process_expt;
        END;
--
        lv_io_slip_no :=  gt_inout_info_tab(ln_count).slip_no;
--
      END IF;
--
      -- ���o�ɃW���[�i�������敪�̒l�ɂ��A�����X�e�[�^�X��ݒ�
      IF gt_inout_info_tab(ln_count).io_program_div = cv_program_div_0 THEN
        lv_status :=  cv_status_1;
      ELSE
        lv_status :=  cv_status_0;
      END IF;
--
      BEGIN
        -- HHT���o�Ɉꎞ�\�ւ̓o�^(�q�ɂ���c�ƎԂ�)
        INSERT INTO xxcoi_hht_inv_transactions(
          transaction_id                        -- ���o�Ɉꎞ�\ID
         ,interface_id                          -- �C���^�[�t�F�[�XID
         ,form_header_id                        -- ��ʓ��͗p�w�b�_ID
         ,base_code                             -- ���_�R�[�h
         ,record_type                           -- ���R�[�h���
         ,employee_num                          -- �c�ƈ��R�[�h
         ,invoice_no                            -- �`�[��
         ,item_code                             -- �i�ڃR�[�h�i�i���R�[�h�j
         ,case_quantity                         -- �P�[�X��
         ,case_in_quantity                      -- ����
         ,quantity                              -- �{��
         ,invoice_type                          -- �`�[�敪
         ,base_delivery_flag                    -- ���_�ԑq�փt���O
         ,outside_code                          -- �o�ɑ��R�[�h
         ,inside_code                           -- ���ɑ��R�[�h
         ,invoice_date                          -- �`�[���t
         ,column_no                             -- �R������
         ,unit_price                            -- �P��
         ,hot_cold_div                          -- H/C
         ,department_flag                       -- �S�ݓX�t���O
         ,interface_date                        -- ��M����
         ,other_base_code                       -- �����_�R�[�h
         ,outside_subinv_code                   -- �o�ɑ��ۊǏꏊ
         ,inside_subinv_code                    -- ���ɑ��ۊǏꏊ
         ,outside_base_code                     -- �o�ɑ����_
         ,inside_base_code                      -- ���ɑ����_
         ,total_quantity                        -- ���{��
         ,inventory_item_id                     -- �i��ID
         ,primary_uom_code                      -- ��P��
         ,outside_subinv_code_conv_div          -- �o�ɑ��ۊǏꏊ�ϊ��敪
         ,inside_subinv_code_conv_div           -- ���ɑ��ۊǏꏊ�ϊ��敪
         ,outside_business_low_type             -- �o�ɑ��Ƒԋ敪
         ,inside_business_low_type              -- ���ɑ��Ƒԋ敪
         ,outside_cust_code                     -- �o�ɑ��ڋq�R�[�h
         ,inside_cust_code                      -- ���ɑ��ڋq�R�[�h
         ,hht_program_div                       -- ���o�ɃW���[�i�������敪
         ,consume_vd_flag                       -- ����VD��[�Ώۃt���O
         ,item_convert_div                      -- ���i�U�֋敪
         ,stock_uncheck_list_div                -- ���ɖ��m�F���X�g�Ώۋ敪
         ,stock_balance_list_div                -- ���ɍ��يm�F���X�g�Ώۋ敪
         ,status                                -- �����X�e�[�^�X
         ,column_if_flag                        -- �R�����ʓ]���σt���O
         ,column_if_date                        -- �R�����ʓ]����
         ,sample_if_flag                        -- ���{�]���σt���O
         ,sample_if_date                        -- ���{�]����
         ,output_flag                           -- �o�͍σt���O
         ,last_update_date                      -- �ŏI�X�V��
         ,last_updated_by                       -- �ŏI�X�V��
         ,creation_date                         -- �쐬��
         ,created_by                            -- �쐬��
         ,last_update_login                     -- �ŏI�X�V���[�U
         ,request_id                            -- �v��ID
         ,program_application_id                -- �v���O�����A�v���P�[�V����ID
         ,program_id                            -- �v���O����ID
         ,program_update_date)                  -- �v���O�����X�V��
        VALUES(
          ln_transaction_id                                     -- ���o�Ɉꎞ�\ID
         ,NULL                                                  -- �C���^�[�t�F�[�XID
         ,NULL                                                  -- ��ʓ��͗p�w�b�_ID
         ,gt_inout_info_tab(ln_count).inside_base_code          -- ���_�R�[�h
         ,cv_record_type                                        -- ���R�[�h���
         ,NULL                                                  -- �c�ƈ��R�[�h
         ,lv_io_invoice_no                                      -- �`�[��
         ,gt_inout_info_tab(ln_count).parent_item_code          -- �i�ڃR�[�h�i�i���R�[�h�j
         ,gt_inout_info_tab(ln_count).case_qty                  -- �P�[�X��
         ,gt_inout_info_tab(ln_count).case_in_quantity          -- ����
         ,gt_inout_info_tab(ln_count).singly_qty                -- �{��
         ,cv_invoice_type                                       -- �`�[�敪
         ,cn_zero                                               -- ���_�ԑq�փt���O
         ,SUBSTR(gt_inout_info_tab(ln_count).io_start_subinv_code, -2)
                                                                -- �o�ɑ��R�[�h
         ,gt_inout_info_tab(ln_count).inside_subinv_code        -- ���ɑ��R�[�h
         ,gt_inout_info_tab(ln_count).invoice_date              -- �`�[���t
         ,NULL                                                  -- �R������
         ,0                                                     -- �P��
         ,NULL                                                  -- H/C
         ,cv_department_flag                                    -- �S�ݓX�t���O
         ,ld_interface_date                                     -- ��M����
         ,NULL                                                  -- �����_�R�[�h
         ,gt_inout_info_tab(ln_count).io_start_subinv_code      -- �o�ɑ��ۊǏꏊ
         ,gt_inout_info_tab(ln_count).io_via_subinv_code        -- ���ɑ��ۊǏꏊ
         ,gt_inout_info_tab(ln_count).io_start_base_code        -- �o�ɑ����_
         ,gt_inout_info_tab(ln_count).io_via_base_code          -- ���ɑ����_
         ,(gt_inout_info_tab(ln_count).case_in_quantity * gt_inout_info_tab(ln_count).case_qty) + gt_inout_info_tab(ln_count).singly_qty
                                                                -- ���{��
         ,gt_inout_info_tab(ln_count).parent_item_id            -- �i��ID
         ,lt_primary_uom_code                                   -- ��P��
         ,gt_inout_info_tab(ln_count).io_outside_subinv_conv    -- �o�ɑ��ۊǏꏊ�ϊ��敪
         ,gt_inout_info_tab(ln_count).io_inside_subinv_conv     -- ���ɑ��ۊǏꏊ�ϊ��敪
         ,NULL                                                  -- �o�ɑ��Ƒԋ敪
         ,NULL                                                  -- ���ɑ��Ƒԋ敪
         ,NULL                                                  -- �o�ɑ��ڋq�R�[�h
         ,NULL                                                  -- ���ɑ��ڋq�R�[�h
         ,gt_inout_info_tab(ln_count).io_program_div            -- ���o�ɃW���[�i�������敪
         ,gt_inout_info_tab(ln_count).io_consume_vd_flag        -- ����VD��[�Ώۃt���O
         ,gt_inout_info_tab(ln_count).io_item_convert_div       -- ���i�U�֋敪
         ,gt_inout_info_tab(ln_count).io_stock_uncheck_list_div -- ���ɖ��m�F���X�g�Ώۋ敪
         ,gt_inout_info_tab(ln_count).io_stock_balance_list_div -- ���ɍ��يm�F���X�g�Ώۋ敪
         ,lv_status                                             -- �����X�e�[�^�X�i�������j
         ,cv_const_n                                            -- �R�����ʓ]���σt���O�i���]���j
         ,NULL                                                  -- �R�����ʓ]����
         ,cv_const_n                                            -- ���{�]���σt���O�i���]���j
         ,NULL                                                  -- ���{�]����
         ,cv_const_n                                            -- �o�͍σt���O�i���o�́j
         ,cd_last_update_date                                   -- �ŏI�X�V��
         ,cn_last_updated_by                                    -- �ŏI�X�V��
         ,cd_creation_date                                      -- �쐬��
         ,cn_created_by                                         -- �쐬��
         ,cn_last_update_login                                  -- �ŏI�X�V���O�C��
         ,cn_request_id                                         -- �v��ID
         ,cn_program_application_id                             -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                                         -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date                                -- �v���O�����X�V��
        )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�̎擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                       , iv_name         => cv_msg_coi_10701
                       , iv_token_name1  => cv_tkn_err_msg
                       , iv_token_value1 => SQLERRM
                       );
          RAISE global_process_expt;
      END;
--
      -- �`�[No�̏o�́i���łɁA����`�[�ԍ��ŏo�͂��Ă���ꍇ�̓X�L�b�v�j
      IF gt_inout_info_tab(ln_count).slip_no <> lv_output_slip_no THEN
--
        lv_message_slip :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10748
                         , iv_token_name1  => cv_tkn_param
                         , iv_token_value1 => gt_inout_info_tab(ln_count).slip_no
                         , iv_token_name2  => cv_tkn_param2
                         , iv_token_value2 => lv_chg_invoice_no
                         , iv_token_name3  => cv_tkn_param3
                         , iv_token_value3 => lv_io_invoice_no
                       );
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
          ,buff   => lv_message_slip
        );
--
        lv_output_slip_no :=  gt_inout_info_tab(ln_count).slip_no;
--
      END IF;
--
      ln_count  :=  ln_count + 1;
--
    END LOOP inv_transactions_loop;
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
  END cre_inv_transactions;
--
    /**********************************************************************************
   * Procedure Name   : cre_lot_transactions
   * Description      : ���b�g�ʎ�����ׂ̍쐬�A���b�g�ʎ莝���ʂ̕ύX(A-7)
   ***********************************************************************************/
  PROCEDURE cre_lot_transactions(
    ov_errbuf             OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_lot_transactions'; -- �v���O������
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
    ln_count            NUMBER;                                     -- �J�E���g�p�ϐ�
    ln_count2           NUMBER;                                     -- �J�E���g�p�ϐ�2
    lv_transaction_type VARCHAR2(2);                                -- ����^�C�v
    lt_trx_id           xxcoi_lot_transactions.transaction_id%TYPE; -- ���b�g�ʎ��ID
    lb_err_flg          BOOLEAN;                                    -- �G���[����
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
    -- ���[�J���ϐ�������
    ln_count  :=  1;
    lv_errbuf :=  NULL;
--
    <<lot_info_loop>>
    LOOP
--
      -- �J�E���g�����R�[�h�^�ϐ��ɓo�^���������̍ő�l�ɒB���Ă����烋�[�v�𔲂���
      IF ln_count = gn_lot_count THEN
        EXIT;
      END IF;
--
      -- �u�����_�֏o�Ɂv�f�[�^�̍쐬
--
      -- ���b�g�ʎ�����׍쐬
      -- ���ʊ֐��F���b�g�ʎ�����׍쐬
      xxcoi_common_pkg.cre_lot_trx(
          in_trx_set_id            => NULL                                                      -- ����Z�b�gID
         ,iv_parent_item_code      => gt_lot_info_tab(ln_count).parent_item_code                -- �e�i�ڃR�[�h
         ,iv_child_item_code       => gt_lot_info_tab(ln_count).child_item_code                 -- �q�i�ڃR�[�h
         ,iv_lot                   => gt_lot_info_tab(ln_count).lot                             -- ���b�g(�ܖ�����)
         ,iv_diff_sum_code         => gt_lot_info_tab(ln_count).difference_summary_code         -- �ŗL�L��
         ,iv_trx_type_code         => cv_transaction_type_20                                    -- ����^�C�v�R�[�h
         ,id_trx_date              => gt_lot_info_tab(ln_count).invoice_date                    -- �����
         ,iv_slip_num              => gt_lot_info_tab(ln_count).invoice_no                      -- �`�[No
         ,in_case_in_qty           => gt_lot_info_tab(ln_count).case_in_quantity                -- ����
         ,in_case_qty              => gt_lot_info_tab(ln_count).case_qty * (-1)                 -- �P�[�X��
         ,in_singly_qty            => gt_lot_info_tab(ln_count).singly_qty * (-1)               -- �o����
         ,in_summary_qty           => gt_lot_info_tab(ln_count).summary_quantity * (-1)         -- �������
         ,iv_base_code             => gt_lot_info_tab(ln_count).outside_base_code               -- ���_�R�[�h
         ,iv_subinv_code           => gt_lot_info_tab(ln_count).start_subinv_code               -- �ۊǏꏊ�R�[�h
         ,iv_loc_code              => gt_lot_info_tab(ln_count).location_code                   -- ���P�[�V�����R�[�h
         ,iv_tran_subinv_code      => gt_lot_info_tab(ln_count).via_subinv_code                 -- �]����ۊǏꏊ�R�[�h
         ,iv_tran_loc_code         => NULL                                                      -- �]���惍�P�[�V�����R�[�h
         ,iv_sign_div              => cv_sign_div_0                                             -- �����敪
         ,iv_source_code           => cv_source_code                                            -- �\�[�X�R�[�h
         ,iv_relation_key          => gt_lot_info_tab(ln_count).transaction_id                  -- �R�t���L�[
         ,iv_reason                => NULL                                                      -- ���R
         ,iv_reserve_trx_type_code => NULL                                                      -- ����������^�C�v�R�[�h
         ,on_trx_id                => lt_trx_id                                                 -- ���b�g�ʎ��ID
         ,ov_errbuf                => lv_errbuf                                                 -- �G���[���b�Z�[�W
         ,ov_retcode               => lv_retcode                                                -- ���^�[���E�R�[�h(0:����A2:�G���[)
         ,ov_errmsg                => lv_errmsg                                                 -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- �߂�l�̃��^�[���R�[�h������ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �G���[���b�Z�[�W�̎擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10489
                     , iv_token_name1  => cv_tkn_err_msg
                     , iv_token_value1 => lv_errmsg
                     );
        RAISE global_process_expt;
      END IF;
--
      -- �]����q�ɂ��X�V
      BEGIN
--
        UPDATE  xxcoi_lot_transactions
        SET     inside_warehouse_code = gt_lot_info_tab(ln_count).inside_warehouse_code
        WHERE   transaction_id    = lt_trx_id
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10743
                         ,iv_token_name1  =>  cv_tkn_transaction_id
                         ,iv_token_value1 =>  lt_trx_id
                       );
          RAISE global_process_expt;
      END;
--
      -- ���ʊ֐��F���b�g�ʎ莝���ʔ��f
      xxcoi_common_pkg.ins_upd_del_lot_onhand(
          in_inv_org_id       => gn_inv_org_id                                      -- �݌ɑg�DID
         ,iv_base_code        => gt_lot_info_tab(ln_count).outside_base_code        -- ���_�R�[�h
         ,iv_subinv_code      => gt_lot_info_tab(ln_count).start_subinv_code        -- �ۊǏꏊ�R�[�h
         ,iv_loc_code         => gt_lot_info_tab(ln_count).location_code            -- ���P�[�V�����R�[�h
         ,in_child_item_id    => gt_lot_info_tab(ln_count).child_item_id            -- �q�i��ID
         ,iv_lot              => gt_lot_info_tab(ln_count).lot                      -- ���b�g(�ܖ�����)
         ,iv_diff_sum_code    => gt_lot_info_tab(ln_count).difference_summary_code  -- �ŗL�L��
         ,in_case_in_qty      => gt_lot_info_tab(ln_count).case_in_quantity         -- ����
         ,in_case_qty         => gt_lot_info_tab(ln_count).case_qty * (-1)          -- �P�[�X��
         ,in_singly_qty       => gt_lot_info_tab(ln_count).singly_qty * (-1)        -- �o����
         ,in_summary_qty      => ((gt_lot_info_tab(ln_count).case_in_quantity * NVL(gt_lot_info_tab(ln_count).case_qty, 0)) + NVL(gt_lot_info_tab(ln_count).singly_qty, 0)) * (-1)
                                                                                    -- �������
         ,ov_errbuf           => lv_errbuf                                          -- �G���[���b�Z�[�W
         ,ov_retcode          => lv_retcode                                         -- ���^�[���E�R�[�h(0:����A2:�G���[)
         ,ov_errmsg           => lv_errmsg                                          -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- �߂�l�̃��^�[���R�[�h������ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �G���[���b�Z�[�W�̎擾
        
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10490
                     , iv_token_name1  => cv_tkn_err_msg
                     , iv_token_value1 => lv_errmsg
                     );
        RAISE global_process_expt;
      END IF;
--
      ln_count  :=  ln_count + 1;
--
    END LOOP lot_info_loop;
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
  END cre_lot_transactions;
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
    -- ���[�v���̃J�E���g
    ln_file_if_loop_cnt  NUMBER; -- �t�@�C��IF���[�v�J�E���^
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
    gv_key_data          := cv_key_data;  -- �L�[���
--
    -- ���[�J���ϐ��̏�����
    ln_file_if_loop_cnt := 0; -- �t�@�C��IF���[�v�J�E���^
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
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_api_warn_expt;
    END IF;
--
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
--
      -- A-4.�̏����́A�G���[�`�F�b�N�̒�����Ă�
      -- ============================================
      -- A-5�D�G���[�`�F�b�N
      -- ============================================
      err_check(
         ln_file_if_loop_cnt -- IF���[�v�J�E���^
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
    -- �o�^�t���O��TRUE�ŁA�G���[���ꌏ�������ꍇ�̂݁A�ȉ��̓o�^���������{
    IF gb_insert_flg  AND gv_check_result = cv_const_y THEN
      -- ============================================
      -- A-6�D���o�ɏ��̍쐬
      -- ============================================
      cre_inv_transactions(
         lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-7�D���b�g�ʎ�����ׂ̍쐬�A���b�g�ʎ莝���ʂ̕ύX
      -- ============================================
      cre_lot_transactions(
         lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
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
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
    IF (  lv_retcode = cv_status_error
       OR lv_retcode = cv_status_warn ) THEN
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
      gn_warn_cnt   := ( gn_target_cnt - gn_error_cnt ); -- �X�L�b�v����
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
END XXCOI003A19C;
/