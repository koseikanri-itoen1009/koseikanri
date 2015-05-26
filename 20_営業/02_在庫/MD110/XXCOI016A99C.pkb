CREATE OR REPLACE PACKAGE BODY APPS.XXCOI016A99C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A99C(body)
 * Description      : ���b�g�ʏo�׏��쐬_�ڍs�p
 * MD.050           : -
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_tran_type          ����^�C�v�擾�i���b�g�ʎ��TEMP�o�^�����܂���A-12����̋��ʏ����j
 *  ins_lot_tran_temp      ���b�g�ʎ��TEMP�o�^�����iA-4�܂���A-17����̋��ʏ����j
 *  reserve_process        ���������iA-7����̋��ʏ����j
 *  init                   ��������(A-1)
 *  get_lock               ���b�N���䏈��(A-2)
 *  get_reserve_data       �����Ώۃf�[�^�擾����(A-4)
 *  get_reserve_other_data �����ȊO�f�[�^�擾����(A-17)
 *  chk_reserve_data       �����Ώۃf�[�^�`�F�b�N����(A-5)
 *  get_item               �q�i�ڏ��擾����(A-6)
 *  inventory_reservation  �����Ώۍ݌ɔ��菈��(A-7)
 *  chk_order              �󒍒����`�F�b�N����(A-8)
 *  ins_lot_transactions   ���b�g�ʎ�����דo�^����(A-9)
 *  ref_lot_onhand         ���b�g�ʎ莝���ʔ��f����(A-10)
 *  ref_mst_lot_hold_info  ���b�g���ێ��}�X�^���f����(A-11)
 *  ins_lot_reserve_info   ���b�g�ʈ������o�^����(A-12)
 *  del_lot_reserve_info   ���b�g�ʈ������폜����(A-13)
 *  upd_lot_reserve_info   ���b�g�ʈ������X�V����(A-14)
 *  upd_lot_reserve_info2  ���b�g�ʈ������X�V�����i�o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj�j(A-15)
 *  upd_xcc                �f�[�^�A�g����e�[�u���X�V����(A-18)
 *  submain                ���C�������v���V�[�W��
 *                           ���b�g�ʈ������擾����(A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/05/12    1.0   S.Yamashita       �V�K�쐬
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
  global_lock_expt          EXCEPTION; -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOI016A06C'; -- �p�b�P�[�W��  -- �ԕi�E�����E�ߋ��f�[�^�p
-- Add Ver1.1 Start
  cv_pkg_name2              CONSTANT VARCHAR2(20) := 'XXCOI016B06C'; -- �p�b�P�[�W��2 -- �����p
-- Add Ver1.1 End
  -- �A�v���P�[�V�����Z�k��
  cv_application            CONSTANT VARCHAR2(5)  := 'XXCOI';        -- �A�v���P�[�V����XXCOI
  cv_application_xxcos      CONSTANT VARCHAR2(5)  := 'XXCOS';        -- �A�v���P�[�V����XXCOS
  -- �v���t�@�C��
  cv_org_id                 CONSTANT VARCHAR2(30) := 'ORG_ID';                        -- MO:�c�ƒP��
  cv_organization_code      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- XXCOI:�݌ɑg�D�R�[�h
  cv_lot_reverse_mark       CONSTANT VARCHAR2(30) := 'XXCOI1_LOT_REVERSE_MARK';       -- XXCOI:���b�g�t�]�L��
  cv_edi_order_source       CONSTANT VARCHAR2(30) := 'XXCOS1_EDI_ORDER_SOURCE';       -- XXCOS:EDI�󒍃\�[�X
-- Add Ver1.1 Start
  cv_period_xxcoi016a06c1   CONSTANT VARCHAR2(30) := 'XXCOI1_PERIOD_XXCOI016A06C1';   -- XXCOI:�����f�[�^�擾����
  cv_period_xxcoi016a06c5   CONSTANT VARCHAR2(30) := 'XXCOI1_PERIOD_XXCOI016A06C5';   -- XXCOI:�ԕi�E�����E�ߋ��f�[�^�擾����
-- Add Ver1.1 End
  -- �N�C�b�N�R�[�h�i�^�C�v�j
  cv_priority_flag          CONSTANT VARCHAR2(30) := 'XXCOI1_PRIORITY_FLAG';          -- �D�惍�P�[�V�����g�p
  cv_lot_reversal_flag      CONSTANT VARCHAR2(30) := 'XXCOI1_LOT_REVERSAL_FLAG';      -- ���b�g�t�]��
  cv_xxcoi016a06_kbn        CONSTANT VARCHAR2(30) := 'XXCOI1_XXCOI016A06_KBN';        -- ���b�g�ʏo�׏��쐬����敪
  cv_shipping_status        CONSTANT VARCHAR2(30) := 'XXCOI1_SHIPPING_STATUS';        -- �o�׏��X�e�[�^�X
  cv_order_type_mst         CONSTANT VARCHAR2(30) := 'XXCOI1_ORDER_TYPE_MST_016_A06'; -- �󒍃^�C�v����}�X�^_016_A06
  cv_no_inv_item_code       CONSTANT VARCHAR2(30) := 'XXCOS1_NO_INV_ITEM_CODE';       -- ��݌ɕi��
  cv_bargain_class          CONSTANT VARCHAR2(30) := 'XXCOS1_BARGAIN_CLASS';          -- ��ԓ����敪
  cv_sale_class_mst         CONSTANT VARCHAR2(30) := 'XXCOS1_SALE_CLASS_MST';         -- ����敪����}�X�^
  cv_sale_class_mst_012a02  CONSTANT VARCHAR2(30) := 'XXCOS1_SALE_CLASS_MST_012_A02'; -- ����敪����}�X�^_012_A02
  cv_red_black_flag         CONSTANT VARCHAR2(30) := 'XXCOS1_RED_BLACK_FLAG_007';     -- �ԍ��t���O
  -- �N�C�b�N�R�[�h�i�R�[�h�j
  cv_xxcoi_016_a06          CONSTANT VARCHAR2(30) := 'XXCOI_016_A06%';                -- �󒍃^�C�v����
  cv_xxcos                  CONSTANT VARCHAR2(30) := 'XXCOS_%';                       -- �R�[�h
  -- ���b�Z�[�W�iCOI�j
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_00011        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_00032        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00032'; -- �v���t�@�C���l�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10130        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10130'; -- �]�ƈ��}�X�^�擾�G���[
  cv_msg_xxcoi_10530        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10530'; -- �o�׏��X�e�[�^�X���擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10531        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10531'; -- �����t�]�G���[���b�Z�[�W
  cv_msg_xxcoi_10532        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10532'; -- �����ߋ����G���[���b�Z�[�W
  cv_msg_xxcoi_10533        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10533'; -- ���b�g�ʏo�׏��쐬�i�����j�R���J�����g���̓p�����[�^1
  cv_msg_xxcoi_10534        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10534'; -- ���b�g�ʏo�׏��쐬�i�����j�R���J�����g���̓p�����[�^2
  cv_msg_xxcoi_10535        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10535'; -- ���b�g�ʏo�׏��쐬�i�����ȊO�j�R���J�����g���̓p�����[�^1
  cv_msg_xxcoi_10536        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10536'; -- ���b�g�ʏo�׏��쐬�i�����ȊO�j�R���J�����g���̓p�����[�^2
  cv_msg_xxcoi_10537        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10537'; -- ���b�g�ʎ��TEMP�쐬�i�ԕi�����ߋ��j���b�Z�[�W
  cv_msg_xxcoi_10538        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10538'; -- ���b�g�ʎ��TEMP�쐬�i���m�������j���b�Z�[�W
  cv_msg_xxcoi_10539        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10539'; -- �󒍃w�b�_ID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10540        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10540'; -- ���b�g�ʏo�׏��쐬�����Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi_10541        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10541'; -- ���b�N�ΏەۊǏꏊ���݃G���[���b�Z�[�W
  cv_msg_xxcoi_10542        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10542'; -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w�肠��j���b�N�G���[���b�Z�[�W
  cv_msg_xxcoi_10543        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10543'; -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[���b�Z�[�W
  cv_msg_xxcoi_10544        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10544'; -- �ڋq�ʑN�x�����R�[�h�ݒ�Ȃ��G���[���b�Z�[�W
  cv_msg_xxcoi_10545        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10545'; -- ���ʊ֐��G���[���b�Z�[�W
  cv_msg_xxcoi_10546        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10546'; -- �D��������P�[�V�������݃G���[���b�Z�[�W
  cv_msg_xxcoi_10547        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10547'; -- �݌ɐ��ʕs���G���[���b�Z�[�W
  cv_msg_xxcoi_10548        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10548'; -- ���b�g�t�]�G���[���b�Z�[�W
  cv_msg_xxcoi_10549        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10549'; -- ���b�g�t�]�i�������j���b�Z�[�W
  cv_msg_xxcoi_10550        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10550'; -- �ڋq�N�x�����G���[���b�Z�[�W
  cv_msg_xxcoi_10553        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10553'; -- ������񍷈كG���[���b�Z�[�W
  cv_msg_xxcoi_10554        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10554'; -- �ԍ��t���O�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10600        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10600'; -- ���b�g�ʎ莝���ʑ��݃G���[���b�Z�[�W
  cv_msg_xxcoi_10660        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10660'; -- ���b�g�ʎ��TEMP�쐬�ΏۂȂ����b�Z�[�W
  cv_msg_xxcoi_10662        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10662'; -- ���b�g�ʈ�����������b�Z�[�W
-- Mod Ver1.3 Start
  cv_msg_xxcoi_10703        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10703'; -- �p�����[�^�K�{�G���[���b�Z�[�W
-- Mod Ver1.3 End
  -- ���b�Z�[�W�iCOS�j
  cv_msg_xxcos_00186        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00186'; -- ��ԏ��擾�G���[
  cv_msg_xxcos_00187        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00187'; -- �������擾�G���[
  cv_msg_xxcos_11538        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-11538'; -- �󒍃\�[�X�擾�G���[
  cv_msg_xxcos_12005        CONSTANT VARCHAR2(16) := 'APP-XXCOS1-12005'; -- �󒍃^�C�v�擾�G���[���b�Z�[�W
  -- ���b�Z�[�W�i�Œ蕶���j
  cv_msg_xxcoi_10495        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10495'; -- ���b�g�ʎ�����׍쐬
  cv_msg_xxcoi_10552        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10552'; -- �P�ʊ��Z�擾
  cv_msg_xxcoi_10559        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10559'; -- ���b�g�ʎ莝���ʔ��f
  cv_msg_xxcoi_10560        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10560'; -- �N�x��������Z�o
  cv_msg_xxcoi_10561        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10561'; -- �����\���Z�o
  cv_msg_xxcoi_10562        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10562'; -- �i�ڏ�񓱏o�i�e�^�q�j
  cv_msg_xxcoi_10563        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10563'; -- ���b�g���ێ��}�X�^���f
  -- �g�[�N��
  cv_tkn_pro_tok            CONSTANT VARCHAR2(20) := 'PRO_TOK';             -- �v���t�@�C��
  cv_tkn_org_code_tok       CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';        -- �݌ɑg�D�R�[�h
  cv_tkn_order_source_name  CONSTANT VARCHAR2(20) := 'ORDER_SOURCE_NAME';   -- �󒍃\�[�X��
  cv_tkn_lookup_type        CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';         -- �Q�ƃ^�C�v
  cv_tkn_lookup_code        CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';         -- �Q�ƃR�[�h
  cv_tkn_param1             CONSTANT VARCHAR2(20) := 'PARAM1';              -- �p�����[�^1
  cv_tkn_param2             CONSTANT VARCHAR2(20) := 'PARAM2';              -- �p�����[�^2
  cv_tkn_param3             CONSTANT VARCHAR2(20) := 'PARAM3';              -- �p�����[�^3
  cv_tkn_param4             CONSTANT VARCHAR2(20) := 'PARAM4';              -- �p�����[�^4
  cv_tkn_param5             CONSTANT VARCHAR2(20) := 'PARAM5';              -- �p�����[�^5
  cv_tkn_param6             CONSTANT VARCHAR2(20) := 'PARAM6';              -- �p�����[�^6
  cv_tkn_param7             CONSTANT VARCHAR2(20) := 'PARAM7';              -- �p�����[�^7
  cv_tkn_param8             CONSTANT VARCHAR2(20) := 'PARAM8';              -- �p�����[�^8
  cv_tkn_param9             CONSTANT VARCHAR2(20) := 'PARAM9';              -- �p�����[�^9
  cv_tkn_param10            CONSTANT VARCHAR2(20) := 'PARAM10';             -- �p�����[�^10
  cv_tkn_param_name1        CONSTANT VARCHAR2(20) := 'PARAM_NAME1';         -- �p�����[�^�l1
  cv_tkn_param_name2        CONSTANT VARCHAR2(20) := 'PARAM_NAME2';         -- �p�����[�^�l2
  cv_tkn_param_name3        CONSTANT VARCHAR2(20) := 'PARAM_NAME3';         -- �p�����[�^�l3
  cv_tkn_param_name4        CONSTANT VARCHAR2(20) := 'PARAM_NAME4';         -- �p�����[�^�l4
  cv_tkn_param_name5        CONSTANT VARCHAR2(20) := 'PARAM_NAME5';         -- �p�����[�^�l5
  cv_tkn_param_name6        CONSTANT VARCHAR2(20) := 'PARAM_NAME6';         -- �p�����[�^�l6
  cv_tkn_param_name7        CONSTANT VARCHAR2(20) := 'PARAM_NAME7';         -- �p�����[�^�l7
  cv_tkn_param_name8        CONSTANT VARCHAR2(20) := 'PARAM_NAME8';         -- �p�����[�^�l8
  cv_tkn_param_name9        CONSTANT VARCHAR2(20) := 'PARAM_NAME9';         -- �p�����[�^�l9
  cv_tkn_param_name10       CONSTANT VARCHAR2(20) := 'PARAM_NAME10';        -- �p�����[�^�l10
  cv_tkn_process            CONSTANT VARCHAR2(20) := 'PROCESS';             -- ����
  cv_tkn_base_code          CONSTANT VARCHAR2(20) := 'BASE_CODE';           -- ���_�R�[�h
  cv_tkn_subinventory_code  CONSTANT VARCHAR2(20) := 'SUBINVENTORY_CODE';   -- �ۊǏꏊ�R�[�h
  cv_tkn_order_number       CONSTANT VARCHAR2(20) := 'ORDER_NUMBER';        -- �󒍔ԍ�
  cv_tkn_order_number2      CONSTANT VARCHAR2(20) := 'ORDER_NUMBER_TARGET'; -- �������󒍔ԍ�
  cv_tkn_line_number        CONSTANT VARCHAR2(20) := 'LINE_NUMBER';         -- �󒍖��הԍ�
  cv_tkn_chain_store_code   CONSTANT VARCHAR2(20) := 'CHAIN_STORE_CODE';    -- �`�F�[���X�R�[�h
  cv_tkn_customer_code      CONSTANT VARCHAR2(20) := 'CUSTOMER_CODE';       -- �ڋq�R�[�h
  cv_tkn_item_code          CONSTANT VARCHAR2(20) := 'ITEM_CODE';           -- �i�ڃR�[�h
  cv_tkn_order_quantity     CONSTANT VARCHAR2(20) := 'ORDER_QUANTITY';      -- �󒍐���
  cv_tkn_quantity           CONSTANT VARCHAR2(20) := 'QUANTITY';            -- ����
  cv_tkn_fresh_condition    CONSTANT VARCHAR2(20) := 'FRESH_CONDITION';     -- �N�x����
  cv_tkn_common_pkg         CONSTANT VARCHAR2(20) := 'COMMON_PKG';          -- ���ʊ֐����ڒl
  cv_tkn_errmsg             CONSTANT VARCHAR2(20) := 'ERR_MSG';             -- �G���[���b�Z�[�W
  cv_tkn_line_type          CONSTANT VARCHAR2(20) := 'LINE_TYPE';           -- ���׃^�C�v
  --
  cv_flag_y                 CONSTANT VARCHAR2(1)  := 'Y';
  cv_flag_n                 CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_c                 CONSTANT VARCHAR2(1)  := 'C';
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����
  -- ������
  cv_space                  CONSTANT VARCHAR2(1)  := ' ';     -- ���p�X�y�[�X
  cv_under                  CONSTANT VARCHAR2(1)  := '_';     -- �A���_�[�X�R�A
  cv_dummy_item             CONSTANT VARCHAR2(5)  := 'DUMMY'; -- ����p�_�~�[�l
  -- ����
  cv_yyyymmdd               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';            -- YYYY/MM/DD����
  cv_yyyymmdd_hh24miss      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS'; -- YYYY/MM/DD HH24:MI:SS����
  cv_weekno                 CONSTANT VARCHAR2(1)  := 'D';                     -- �j���ԍ�
  -- �ڋq�敪
  cv_customer_class_code_10 CONSTANT VARCHAR2(2)  := '10'; -- �ڋq
  cv_customer_class_code_12 CONSTANT VARCHAR2(2)  := '12'; -- ��l�ڋq
  cv_customer_class_code_18 CONSTANT VARCHAR2(2)  := '18'; -- �`�F�[���X
  -- ����敪�i�p�����[�^���画�肷�锻��j
  cv_kbn_1                  CONSTANT VARCHAR2(1)  := '1';  -- ����
  cv_kbn_2                  CONSTANT VARCHAR2(1)  := '2';  -- ��������
  cv_kbn_3                  CONSTANT VARCHAR2(1)  := '3';  -- �o�׉��m��
  cv_kbn_4                  CONSTANT VARCHAR2(1)  := '4';  -- �o�׊m��
  cv_kbn_5                  CONSTANT VARCHAR2(1)  := '5';  -- �ԕi�E�����E�ߋ��f�[�^
  cv_kbn_6                  CONSTANT VARCHAR2(1)  := '6';  -- ���m������
  -- �o�׏��X�e�[�^�X
  cv_shipping_status_10     CONSTANT VARCHAR2(2)  := '10'; -- ������
  cv_shipping_status_20     CONSTANT VARCHAR2(2)  := '20'; -- ������
  cv_shipping_status_25     CONSTANT VARCHAR2(2)  := '25'; -- �o�׉��m��
  cv_shipping_status_30     CONSTANT VARCHAR2(2)  := '30'; -- �o�׊m��
  -- �󒍃X�e�[�^�X
  cv_entered                CONSTANT VARCHAR2(10) := 'ENTERED';   -- ���͒�
  cv_booked                 CONSTANT VARCHAR2(10) := 'BOOKED';    -- �L����
  cv_cancelled              CONSTANT VARCHAR2(10) := 'CANCELLED'; -- ���
  -- �󒍃^�C�v�R�[�h
  cv_order                  CONSTANT VARCHAR2(5)  := 'ORDER';
  cv_line                   CONSTANT VARCHAR2(5)  := 'LINE';
  cv_cancellation           CONSTANT VARCHAR2(15) := 'CANCELLATION';
  -- �j���ԍ�
  cv_weekno_sunday          CONSTANT VARCHAR2(1)  := '1'; -- ���j��
  cv_weekno_monday          CONSTANT VARCHAR2(1)  := '2'; -- ���j��
  cv_weekno_tuesday         CONSTANT VARCHAR2(1)  := '3'; -- �Ηj��
  cv_weekno_wednesday       CONSTANT VARCHAR2(1)  := '4'; -- ���j��
  cv_weekno_thursday        CONSTANT VARCHAR2(1)  := '5'; -- �ؗj��
  cv_weekno_friday          CONSTANT VARCHAR2(1)  := '6'; -- ���j��
  cv_weekno_saturday        CONSTANT VARCHAR2(1)  := '7'; -- �y�j��
  -- ����敪�i����^�C�v����p�j
  cv_tran_kbn_1             CONSTANT VARCHAR2(1)  := '1'; -- ��
  cv_tran_kbn_2             CONSTANT VARCHAR2(1)  := '2'; -- �ԕi�E�ԕi����
  cv_tran_kbn_3             CONSTANT VARCHAR2(1)  := '3'; -- ����
  -- �����敪�i���������p�j
  cv_process_kbn_1          CONSTANT VARCHAR2(1)  := '1'; -- �D�����
  cv_process_kbn_2          CONSTANT VARCHAR2(1)  := '2'; -- �D������ȊO
  -- �c�Ɛ��Y�敪
  cv_eigyo                  CONSTANT VARCHAR2(1)  := '1'; -- �c��
  -- ����敪
  cv_cancel_kbn_0           CONSTANT VARCHAR2(1)  := '0'; -- ����łȂ�
  -- ���b�g�ʎ�����׍쐬�敪
  cv_lot_tran_kbn_0         CONSTANT VARCHAR2(1)  := '0'; -- ���b�g�ʎ�����ז��쐬
  cv_lot_tran_kbn_1         CONSTANT VARCHAR2(1)  := '1'; -- ���b�g�ʎ�����׍쐬��
  cv_lot_tran_kbn_9         CONSTANT VARCHAR2(1)  := '9'; -- �ΏۊO�i���b�g�ʎ��TEMP�ɍ쐬�j
  -- ���P�[�V����
  cv_normal                 CONSTANT VARCHAR2(1)  := '1'; -- �ʏ탍�P�[�V����
  cv_priority               CONSTANT VARCHAR2(1)  := '2'; -- �D��������P�[�V����
  cv_dummy                  CONSTANT VARCHAR2(1)  := '3'; -- �_�~�[���P�[�V����
  -- �ԍ��t���O
  cv_red                    CONSTANT VARCHAR2(1)  := '0'; -- �ԓ`�[
  cv_black                  CONSTANT VARCHAR2(1)  := '1'; -- ���`�[
  -- ����敪
  cv_sale_class_1           CONSTANT VARCHAR2(1)  := '1'; -- �ʏ�
  cv_sale_class_2           CONSTANT VARCHAR2(1)  := '2'; -- ����
  cv_sale_class_3           CONSTANT VARCHAR2(1)  := '3'; -- �x���_����
  cv_sale_class_4           CONSTANT VARCHAR2(1)  := '4'; -- �����EVD����
  cv_sale_class_5           CONSTANT VARCHAR2(1)  := '5'; -- ���^
  cv_sale_class_6           CONSTANT VARCHAR2(1)  := '6'; -- ���{
  cv_sale_class_7           CONSTANT VARCHAR2(1)  := '7'; -- �L����`��
  cv_sale_class_9           CONSTANT VARCHAR2(1)  := '9'; -- ��U���i�̔̔�
  -- ��ԓ����敪
  cv_teiban                 CONSTANT VARCHAR2(2)  := '01';  -- ���
  cv_tokubai                CONSTANT VARCHAR2(2)  := '02';  -- ����
  -- �N�x����
  cv_cust_fresh_con_code_00 CONSTANT VARCHAR2(2)  := '00';  -- ���
  -- ����^�C�v
  cv_tran_type_380          CONSTANT VARCHAR2(3)  := '380'; -- �o�׊m��i�����j
  -- ����������^�C�v�R�[�h
  cv_tran_type_code_170     CONSTANT VARCHAR2(3)  := '170'; -- ����o��
  cv_tran_type_code_180     CONSTANT VARCHAR2(3)  := '180'; -- ����o�ɐU��
  cv_tran_type_code_190     CONSTANT VARCHAR2(3)  := '190'; -- �ԕi
  cv_tran_type_code_200     CONSTANT VARCHAR2(3)  := '200'; -- �ԕi�U��
  cv_tran_type_code_320     CONSTANT VARCHAR2(3)  := '320'; -- �ڋq���{�o��
  cv_tran_type_code_330     CONSTANT VARCHAR2(3)  := '330'; -- �ڋq���{�o�ɐU��
  cv_tran_type_code_340     CONSTANT VARCHAR2(3)  := '340'; -- �ڋq���^���{�o��
  cv_tran_type_code_350     CONSTANT VARCHAR2(3)  := '350'; -- �ڋq���^���{�o�ɐU��
  cv_tran_type_code_360     CONSTANT VARCHAR2(3)  := '360'; -- �ڋq�L����`��A���Џ��i
  cv_tran_type_code_370     CONSTANT VARCHAR2(3)  := '370'; -- �ڋq�L����`��A���Џ��i�U��
  -- �����敪
  cv_sign_div_0             CONSTANT VARCHAR2(1)  := '0';   -- �o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  gt_item_info_tab          xxcoi_common_pkg.item_info_ttype; -- �i�ڏ��i�[�z��
  --
  TYPE g_meaning_ttype IS TABLE OF fnd_lookup_values.meaning%TYPE INDEX BY PLS_INTEGER;
  gt_correct_tab            g_meaning_ttype;                -- �����󒍃^�C�v�i�[�z��
  gt_return_tab             g_meaning_ttype;                -- �ԕi�󒍃^�C�v�i�[�z��
  --
  TYPE g_reserve_rtype IS RECORD(
      location_code           xxcoi_lot_reserve_info.location_code%TYPE
    , location_name           xxcoi_lot_reserve_info.location_name%TYPE
    , item_div                xxcoi_lot_reserve_info.item_div%TYPE
    , item_div_name           xxcoi_lot_reserve_info.item_div_name%TYPE
    , item_code               xxcoi_lot_reserve_info.item_code%TYPE
    , item_name               xxcoi_lot_reserve_info.item_name%TYPE
    , lot                     xxcoi_lot_reserve_info.lot%TYPE
    , difference_summary_code xxcoi_lot_reserve_info.difference_summary_code%TYPE
    , case_in_qty             xxcoi_lot_reserve_info.case_in_qty%TYPE
    , case_qty                xxcoi_lot_reserve_info.case_qty%TYPE
    , singly_qty              xxcoi_lot_reserve_info.singly_qty%TYPE
    , summary_qty             xxcoi_lot_reserve_info.summary_qty%TYPE
    , mark                    xxcoi_lot_reserve_info.mark%TYPE
    , item_id                 xxcoi_lot_reserve_info.item_id%TYPE
    , short_case_in_qty       xxcoi_lot_reserve_info.short_case_in_qty%TYPE
    , short_case_qty          xxcoi_lot_reserve_info.short_case_qty%TYPE
    , short_singly_qty        xxcoi_lot_reserve_info.short_singly_qty%TYPE
    , short_summary_qty       xxcoi_lot_reserve_info.short_summary_qty%TYPE
  );
  TYPE g_reserve_ttype      IS TABLE OF g_reserve_rtype INDEX BY PLS_INTEGER;
  gt_reserve_tab            g_reserve_ttype;
  --
  TYPE g_order_number_ttype IS TABLE OF xxcoi_lot_reserve_info.order_number%TYPE INDEX BY PLS_INTEGER;
  gt_order_number_tab       g_order_number_ttype;
  --
  TYPE g_lot_id_ttype IS TABLE OF xxcoi_lot_reserve_info.lot_reserve_info_id%TYPE INDEX BY PLS_INTEGER;
  gt_lot_id_tab             g_lot_id_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_debug_cnt              NUMBER                                                    DEFAULT 0;     -- �f�o�b�O���O�o�͗p
  gn_target_10_cnt          NUMBER                                                    DEFAULT 0;     -- �Ώی����i�������j
  gn_target_20_cnt          NUMBER                                                    DEFAULT 0;     -- �Ώی����i�����ρj
  gn_normal_10_cnt          NUMBER                                                    DEFAULT 0;     -- ���������i�������j
  gn_normal_20_cnt          NUMBER                                                    DEFAULT 0;     -- ���������i�����ρj
  gn_create_temp_cnt        NUMBER                                                    DEFAULT 0;     -- ���b�g�ʎ��TEMP�쐬����
  gn_reserve_cnt            NUMBER                                                    DEFAULT 0;     -- �������i�[�z��p�Y����
  gv_retcode                VARCHAR2(1)                                               DEFAULT NULL;  -- �������ʓo�^�p����R�[�h
  gv_reserve_err_msg        VARCHAR2(16)                                              DEFAULT NULL;  -- ���������ɂăG���[�������̃��b�Z�[�W�R�[�h���i�[
  gb_warn_flag              BOOLEAN                                                   DEFAULT FALSE; -- �x���t���O
  gd_process_date           DATE                                                      DEFAULT NULL;  -- �Ɩ����t
  gd_last_deliver_lot       DATE                                                      DEFAULT NULL;  -- ���b�g���ێ��}�X�^_�[�i���b�g
  gd_delivery_date          DATE                                                      DEFAULT NULL;  -- ���b�g���ێ��}�X�^_�[�i��
  gt_organization_code      mtl_parameters.organization_code%TYPE                     DEFAULT NULL;  -- �݌ɑg�D�R�[�h
  gt_organization_id        mtl_parameters.organization_id%TYPE                       DEFAULT NULL;  -- �݌ɑg�DID
  gt_org_id                 fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- MO:�c�ƒP��
  gt_lot_reverse_mark       fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- XXCOI:���b�g�t�]�L��
  gt_order_source_id        oe_order_sources.order_source_id%TYPE                     DEFAULT NULL;  -- EDI�󒍃\�[�XID
-- Add Ver1.1 Start
  gt_period_xxcoi016a06c1   fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- XXCOI:�����f�[�^�擾����
  gt_period_xxcoi016a06c5   fnd_profile_option_values.profile_option_value%TYPE       DEFAULT NULL;  -- XXCOI:�ԕi�E�����E�ߋ��f�[�^�擾����
-- Add Ver1.1 End
  gt_teiban_name            fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- ��ԓ����敪�F���
  gt_tokubai_name           fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- ��ԓ����敪�F����
  gt_shipping_status_10     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- �o�׏��X�e�[�^�X�F������
  gt_shipping_status_20     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- �o�׏��X�e�[�^�X�F������
  gt_shipping_status_25     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- �o�׏��X�e�[�^�X�F�o�׉��m��
  gt_shipping_status_30     fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- �o�׏��X�e�[�^�X�F�o�׊m���
  gt_employee_number        per_all_people_f.employee_number%TYPE                     DEFAULT NULL;  -- �]�ƈ��R�[�h
  gv_employee_name          VARCHAR2(301)                                             DEFAULT NULL;  -- �]�ƈ���
  gt_max_header_id          xxcoi_lot_reserve_info.header_id%TYPE                     DEFAULT NULL;  -- �󒍃w�b�_ID
  gt_cust_fresh_con_code    xxcmm_cust_accounts.cust_fresh_con_code%TYPE              DEFAULT NULL;  -- �ڋq�ʑN�x�����R�[�h
  gt_order_case_in_qty      xxcoi_lot_reserve_info.case_in_qty%TYPE                   DEFAULT 0;     -- �󒍓���
  gt_order_case_qty         xxcoi_lot_reserve_info.case_qty%TYPE                      DEFAULT 0;     -- �󒍃P�[�X��
  gt_order_singly_qty       xxcoi_lot_reserve_info.singly_qty%TYPE                    DEFAULT 0;     -- �󒍃o����
  gt_order_summary_qty      xxcoi_lot_reserve_info.summary_qty%TYPE                   DEFAULT 0;     -- �󒍑���
  -- �p�����[�^
  gv_login_base_code        VARCHAR2(4)                                               DEFAULT NULL;  -- ���_
  gd_delivery_date_from     DATE                                                      DEFAULT NULL;  -- ����From
  gd_delivery_date_to       DATE                                                      DEFAULT NULL;  -- ����To
  gv_login_chain_store_code VARCHAR2(4)                                               DEFAULT NULL;  -- �`�F�[���X
  gv_login_customer_code    VARCHAR2(9)                                               DEFAULT NULL;  -- �ڋq
  gv_customer_po_number     VARCHAR2(12)                                              DEFAULT NULL;  -- �ڋq�����ԍ�
  gv_subinventory_code      VARCHAR2(10)                                              DEFAULT NULL;  -- �ۊǏꏊ
  gv_priority_flag          VARCHAR2(1)                                               DEFAULT NULL;  -- �D�惍�P�[�V�����g�p
  gv_lot_reversal_flag      VARCHAR2(1)                                               DEFAULT NULL;  -- ���b�g�t�]��
  gv_kbn                    VARCHAR2(1)                                               DEFAULT NULL;  -- ����敪
  gt_base_name              xxcos_login_base_info_v.base_name%TYPE                    DEFAULT NULL;  -- ���_��
  gt_xxcoi016a06_kbn        fnd_lookup_values.meaning%TYPE                            DEFAULT NULL;  -- ����敪_���e
-- Add Ver1.3 Start
  TYPE g_del_id_ttype       IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  g_del_id_tab              g_del_id_ttype; -- ���b�g�ʈ������폜���
-- Add Ver1.3 End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �����Ώێ擾�J�[�\��
  CURSOR g_kbn_1_cur
  IS
    SELECT xtlri.slip_num                     AS slip_num                     -- �`�[No
         , xtlri.order_number                 AS order_number                 -- �󒍔ԍ�
         , xtlri.whse_code                    AS whse_code                    -- �ۊǏꏊ�R�[�h
         , xtlri.whse_name                    AS whse_name                    -- �ۊǏꏊ��
         , xtlri.chain_code                   AS chain_code                   -- �`�F�[���X�R�[�h
         , xtlri.chain_name                   AS chain_name                   -- �`�F�[���X��
         , xtlri.cust_fresh_con_code_chain    AS cust_fresh_con_code_chain    -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
         , xtlri.shop_code                    AS shop_code                    -- �X�܃R�[�h
         , xtlri.shop_name                    AS shop_name                    -- �X�ܖ�
         , xtlri.customer_code                AS customer_code                -- �ڋq�R�[�h
         , xtlri.customer_name                AS customer_name                -- �ڋq��
         , xtlri.cust_fresh_con_code_cust     AS cust_fresh_con_code_cust     -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
         , xtlri.center_code                  AS center_code                  -- �Z���^�[�R�[�h
         , xtlri.center_name                  AS center_name                  -- �Z���^�[��
         , xtlri.area_code                    AS area_code                    -- �n��R�[�h
         , xtlri.area_name                    AS area_name                    -- �n�於
         , xtlri.shipped_date                 AS shipped_date                 -- �o�ד�
         , xtlri.arrival_date                 AS arrival_date                 -- ����
         , xtlri.parent_item_id               AS parent_item_id               -- �e�i��ID
         , xtlri.parent_item_code             AS parent_item_code             -- �e�i�ڃR�[�h
         , xtlri.parent_item_name             AS parent_item_name             -- �e�i�ږ���
         , xtlri.item_code                    AS item_code                    -- �q�i�ڃR�[�h
         , xtlri.regular_sale_class_line      AS regular_sale_class_line      -- ��ԓ����敪(����)
         , xtlri.regular_sale_class_name_line AS regular_sale_class_name_line -- ��ԓ����敪��(����)
         , xtlri.edi_received_date            AS edi_received_date            -- EDI��M��
         , xtlri.delivery_order_edi           AS delivery_order_edi           -- �z����(EDI)
         , xtlri.before_ordered_quantity      AS before_ordered_quantity      -- �����O�󒍐���
         , xtlri.header_id                    AS header_id                    -- �󒍃w�b�_ID
         , xtlri.line_id                      AS line_id                      -- �󒍖���ID
         , xtlri.line_number                  AS line_number                  -- �󒍖��הԍ�
         , xtlri.line_type                    AS line_type                    -- ���׃^�C�v
         , xtlri.customer_id                  AS customer_id                  -- �ڋqID
         , xtlri.ordered_quantity             AS ordered_quantity             -- �󒍐�
         , xtlri.order_quantity_uom           AS order_quantity_uom           -- �󒍒P��
    FROM   xxcoi_tmp_lot_reserve_info xtlri
    ORDER BY xtlri.arrival_date
           , xtlri.chain_code
           , xtlri.shop_code
           , xtlri.customer_code
           , xtlri.order_number
           , xtlri.line_number
  ;
  -- ���������Ώێ擾�J�[�\��
  CURSOR g_kbn_2_cur
  IS
    SELECT xlri.rowid             AS xlri_rowid      -- ROWID
         , xlri.shipping_status   AS shipping_status -- �o�׏��X�e�[�^�X
    FROM   xxcoi_lot_reserve_info xlri
    WHERE  xlri.shipping_status IN ( cv_shipping_status_10, cv_shipping_status_20 )
    AND    xlri.base_code       = gv_login_base_code
    AND    xlri.arrival_date   >= gd_delivery_date_from
    AND    xlri.arrival_date   <  gd_delivery_date_to + 1
    AND ( ( gv_login_chain_store_code IS NULL )
       OR ( xlri.chain_code     = gv_login_chain_store_code ) )
    AND ( ( gv_login_customer_code IS NULL )
       OR ( xlri.customer_code  = gv_login_customer_code ) )
    AND ( ( gv_customer_po_number IS NULL )
       OR ( xlri.slip_num       = gv_customer_po_number ) )
    AND EXISTS ( SELECT 1
                 FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                 WHERE  xtlrs.subinventory_code = xlri.whse_code )
  ;
  -- �o�׉��m��Ώێ擾�J�[�\��
  CURSOR g_kbn_3_cur
  IS
    SELECT xlri.lot_reserve_info_id           AS lot_reserve_info_id            -- ���b�g�ʈ������ID
         , xlri.slip_num                      AS slip_num                       -- �`�[No
         , xlri.order_number                  AS order_number                   -- �󒍔ԍ�
-- Add Ver1.3 Start
         , xlri.parent_shipping_status        AS parent_shipping_status         -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
-- Add Ver1.3 End
         , xlri.whse_code                     AS whse_code                      -- �ۊǏꏊ�R�[�h
         , xlri.location_code                 AS location_code                  -- ���P�[�V�����R�[�h
         , xlri.arrival_date                  AS arrival_date                   -- ����
         , xlri.parent_item_id                AS parent_item_id                 -- �e�i��ID
         , xlri.parent_item_code              AS parent_item_code               -- �e�i�ڃR�[�h
         , xlri.item_id                       AS item_id                        -- �q�i��ID
         , xlri.item_code                     AS item_code                      -- �q�i�ڃR�[�h
         , xlri.lot                           AS lot                            -- ���b�g
         , xlri.difference_summary_code       AS difference_summary_code        -- �ŗL�L��
         , xlri.case_in_qty                   AS case_in_qty                    -- ����
         , xlri.case_qty                      AS case_qty                       -- �P�[�X��
         , xlri.singly_qty                    AS singly_qty                     -- �o����
         , xlri.summary_qty                   AS summary_qty                    -- ����
         , xlri.header_id                     AS header_id                      -- �󒍃w�b�_ID
         , xlri.line_id                       AS line_id                        -- �󒍖���ID
         , xlri.customer_id                   AS customer_id                    -- �ڋqID
         , xlri.reserve_transaction_type_code AS reserve_transaction_type_code  -- ����������^�C�v�R�[�h
         , xlri.ordered_quantity              AS ordered_quantity               -- �󒍐���
    FROM   xxcoi_lot_reserve_info             xlri
-- Mod Ver1.3 Start
--    WHERE  xlri.parent_shipping_status = cv_shipping_status_20
    WHERE  xlri.parent_shipping_status IN ( cv_shipping_status_10, cv_shipping_status_20 )
-- Mod Ver1.3 End
    AND    xlri.base_code              = gv_login_base_code
    AND    xlri.arrival_date          >= gd_delivery_date_from
    AND    xlri.arrival_date          <  gd_delivery_date_to + 1
    AND ( ( gv_login_chain_store_code IS NULL )
       OR ( xlri.chain_code            = gv_login_chain_store_code ) )
    AND ( ( gv_login_customer_code IS NULL )
       OR ( xlri.customer_code         = gv_login_customer_code ) )
    AND ( ( gv_customer_po_number IS NULL )
       OR ( xlri.slip_num              = gv_customer_po_number ) )
    AND EXISTS ( SELECT 1
                 FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                 WHERE  xtlrs.subinventory_code = xlri.whse_code )
    ORDER BY xlri.order_number
  ;
-- Add Ver1.1 Start
  -- �o�׊m��X�V�J�[�\��
  CURSOR g_kbn_4_2_cur
  IS
    SELECT xlri.lot_reserve_info_id AS lot_reserve_info_id
         , xlri.lot_tran_kbn        AS lot_tran_kbn
    FROM   xxcoi_lot_reserve_info   xlri
    WHERE  xlri.parent_shipping_status = cv_shipping_status_25
    AND    xlri.arrival_date           < gd_delivery_date_from + 1
  ;
-- Add Ver1.1 End
  -- �o�׊m��Ώێ擾�J�[�\��
  CURSOR g_kbn_4_cur
  IS
    SELECT xlri.lot_reserve_info_id           AS lot_reserve_info_id
         , xlri.slip_num                      AS slip_num
         , xlri.order_number                  AS order_number
         , xlri.base_code                     AS base_code
         , xlri.whse_code                     AS whse_code
         , xlri.location_code                 AS location_code
         , xlri.arrival_date                  AS arrival_date
         , xlri.parent_item_id                AS parent_item_id
         , xlri.parent_item_code              AS parent_item_code
         , xlri.item_id                       AS item_id
         , xlri.item_code                     AS item_code
         , xlri.lot                           AS lot
         , xlri.difference_summary_code       AS difference_summary_code
         , xlri.case_in_qty                   AS case_in_qty
         , xlri.case_qty                      AS case_qty
         , xlri.singly_qty                    AS singly_qty
         , xlri.summary_qty                   AS summary_qty
         , xlri.header_id                     AS header_id
         , xlri.line_id                       AS line_id
         , xlri.customer_id                   AS customer_id
         , xlri.reserve_transaction_type_code AS reserve_transaction_type_code
         , xlri.ordered_quantity              AS ordered_quantity
    FROM   xxcoi_lot_reserve_info             xlri
-- Mod Ver1.1 Start
--    WHERE  xlri.parent_shipping_status = cv_shipping_status_25
    WHERE  xlri.parent_shipping_status = cv_shipping_status_30
    AND    xlri.lot_tran_kbn           = cv_lot_tran_kbn_1
    AND    xlri.request_id             = cn_request_id
-- Mod Ver1.1 End
    AND    xlri.arrival_date           < gd_delivery_date_from + 1
  ;
--
  /**********************************************************************************
   * Procedure Name   : get_tran_type
   * Description      : ����^�C�v�擾�i���b�g�ʎ��TEMP�o�^�����܂���A-12����̋��ʏ����j
   ***********************************************************************************/
  PROCEDURE get_tran_type(
      iv_tran_kbn                IN  VARCHAR2  -- ����敪
    , iv_line_name               IN  VARCHAR2  -- ���דE�v
    , iv_sale_class              IN  VARCHAR2  -- ����敪
    , ion_order_case_qty         IN OUT NUMBER -- �P�[�X��
    , ion_order_singly_qty       IN OUT NUMBER -- �o����
    , ion_after_quantity         IN OUT NUMBER -- ����
    , ov_tran_type_code_temp     OUT VARCHAR2  -- ����^�C�v�R�[�h
    , ov_tran_type_code          OUT VARCHAR2  -- ����������^�C�v�R�[�h
    , ov_errbuf                  OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                 OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                  OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tran_type'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lt_red_black_flag          fnd_lookup_values.attribute1%TYPE                         DEFAULT NULL; -- �ԍ��t���O
    lt_tran_type_code_temp     xxcoi_lot_transactions_temp.transaction_type_code%TYPE    DEFAULT NULL; -- ����^�C�v�R�[�h
    lt_tran_type_code          xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE DEFAULT NULL; -- ����������^�C�v�R�[�h
--
    -- *** ���[�J���J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ԍ��t���O�擾
    BEGIN
      SELECT flv.attribute1    AS attribute1
      INTO   lt_red_black_flag
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type                            = cv_red_black_flag
      AND    flv.meaning                                = iv_line_name
      AND    flv.language                               = ct_lang
      AND    flv.enabled_flag                           = cv_flag_y
      AND    flv.start_date_active                     <= gd_process_date
      AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10554
                       , iv_token_name1  => cv_tkn_line_type
                       , iv_token_value1 => iv_line_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- �ԕi�E�ԕi����
    IF ( iv_tran_kbn = cv_tran_kbn_2 ) THEN
      lt_tran_type_code_temp := cv_tran_type_380;
      -- ���`�[
      IF ( lt_red_black_flag = cv_black ) THEN
        lt_tran_type_code    := cv_tran_type_code_190;
        -- �ԕi�̍��͐��ʔ��]
        ion_order_case_qty   := ion_order_case_qty   * (-1);
        ion_order_singly_qty := ion_order_singly_qty * (-1);
        ion_after_quantity   := ion_after_quantity   * (-1);
      -- �ԓ`�[
      ELSIF ( lt_red_black_flag = cv_red ) THEN
        lt_tran_type_code    := cv_tran_type_code_200;
        -- �ԕi�̐Ԃ͂��̂܂�
        ion_order_case_qty   := ion_order_case_qty;
        ion_order_singly_qty := ion_order_singly_qty;
        ion_after_quantity   := ion_after_quantity;
      END IF;
    -- �󒍁E����
    ELSE
      lt_tran_type_code_temp := cv_tran_type_380;
      IF ( lt_red_black_flag = cv_black ) THEN
        IF ( iv_sale_class IN ( cv_teiban, cv_tokubai, cv_sale_class_1, cv_sale_class_2, cv_sale_class_3, cv_sale_class_4, cv_sale_class_9 ) ) THEN
          lt_tran_type_code := cv_tran_type_code_170;
        ELSIF ( iv_sale_class = cv_sale_class_6 ) THEN
          lt_tran_type_code := cv_tran_type_code_320;
        ELSIF ( iv_sale_class = cv_sale_class_5 ) THEN
          lt_tran_type_code := cv_tran_type_code_340;
        ELSIF ( iv_sale_class = cv_sale_class_7 ) THEN
          lt_tran_type_code := cv_tran_type_code_360;
        END IF;
        -- �󒍂̍��͂��̂܂�
        ion_order_case_qty   := ion_order_case_qty;
        ion_order_singly_qty := ion_order_singly_qty;
        ion_after_quantity   := ion_after_quantity;
      ELSIF ( lt_red_black_flag = cv_red ) THEN
        IF ( iv_sale_class IN ( cv_teiban, cv_tokubai, cv_sale_class_1, cv_sale_class_2, cv_sale_class_3, cv_sale_class_4, cv_sale_class_9 ) ) THEN
          lt_tran_type_code := cv_tran_type_code_180;
        ELSIF ( iv_sale_class = cv_sale_class_6 ) THEN
          lt_tran_type_code := cv_tran_type_code_330;
        ELSIF ( iv_sale_class = cv_sale_class_5 ) THEN
          lt_tran_type_code := cv_tran_type_code_350;
        ELSIF ( iv_sale_class = cv_sale_class_7 ) THEN
          lt_tran_type_code := cv_tran_type_code_370;
        END IF;
        -- �󒍂̐Ԃ͐��ʔ��]
        ion_order_case_qty   := ion_order_case_qty   * (-1);
        ion_order_singly_qty := ion_order_singly_qty * (-1);
        ion_after_quantity   := ion_after_quantity   * (-1);
      END IF;
    END IF;
    --
    -- �߂�l
    ov_tran_type_code_temp := lt_tran_type_code_temp;
    ov_tran_type_code      := lt_tran_type_code;
--
  EXCEPTION
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
  END get_tran_type;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_tran_temp
   * Description      : ���b�g�ʎ��TEMP�o�^�����iA-4�܂���A-17����̋��ʏ����j
   ***********************************************************************************/
  PROCEDURE ins_lot_tran_temp(
      iv_tran_kbn           IN  VARCHAR2  -- ����敪
    , in_header_id          IN  NUMBER    -- �󒍃w�b�_ID
    , in_line_id            IN  NUMBER    -- �󒍖���ID
    , iv_slip_num           IN  VARCHAR2  -- �`�[No
    , iv_order_number       IN  VARCHAR2  -- �󒍔ԍ�
    , iv_line_number        IN  VARCHAR2  -- �󒍖��׍�
    , id_arrival_date       IN  DATE      -- ����
    , iv_parent_item_code   IN  VARCHAR2  -- �e�i�ڃR�[�h
    , iv_item_code          IN  VARCHAR2  -- �q�i�ڃR�[�h
    , in_parent_item_id     IN  NUMBER    -- �e�i��ID
    , iv_order_quantity_uom IN  VARCHAR2  -- �󒍒P��
    , in_ordered_quantity   IN  NUMBER    -- �󒍐���
    , iv_base_code          IN  VARCHAR2  -- ���_�R�[�h
    , iv_subinventory_code  IN  VARCHAR2  -- �ۊǏꏊ�R�[�h
    , iv_line_name          IN  VARCHAR2  -- ���דE�v
    , iv_sale_class         IN  VARCHAR2  -- ��ԓ����敪(����)
    , iv_flow_status_code   IN  VARCHAR2  -- ���׃X�e�[�^�X
    , ov_errbuf             OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode            OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg             OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_tran_temp'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lt_item_code               mtl_system_items_b.segment1%TYPE                          DEFAULT NULL; -- �i�ڃR�[�h
    lt_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE                 DEFAULT NULL; -- �i��ID
    lt_after_uom_code          mtl_units_of_measure_tl.uom_code%TYPE                     DEFAULT NULL; -- ���Z��P�ʃR�[�h
    ln_after_quantity          NUMBER                                                    DEFAULT 0;    -- ���Z�㐔��
    ln_content                 NUMBER                                                    DEFAULT 0;    -- �󒍓���
    ln_order_case_qty          NUMBER                                                    DEFAULT 0;    -- �󒍃P�[�X��
    ln_order_singly_qty        NUMBER                                                    DEFAULT 0;    -- �󒍃o����
    lt_tran_type_code_temp     xxcoi_lot_transactions_temp.transaction_type_code%TYPE    DEFAULT NULL; -- ����^�C�v�R�[�h
    lt_tran_type_code          xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE DEFAULT NULL; -- ����������^�C�v�R�[�h
    lt_trx_id                  xxcoi_lot_transactions_temp.transaction_id%TYPE           DEFAULT NULL; -- ���ID
--
    -- *** ���[�J���J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D���b�g�ʎ��TEMP�폜
    --==============================================================
    DELETE FROM xxcoi_lot_transactions_temp xltt
    WHERE xltt.source_code  = cv_pkg_name
    AND   xltt.relation_key = in_header_id || cv_under || in_line_id
    ;
    -- ����̏ꍇ�A�폜�̂�
    IF ( iv_flow_status_code = cv_cancelled ) THEN
      -- ���m�������̏ꍇ
      IF ( gv_kbn = cv_kbn_6 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10662
                       , iv_token_name1  => cv_tkn_order_number
                       , iv_token_value1 => iv_order_number
                       , iv_token_name2  => cv_tkn_line_number
                       , iv_token_value2 => iv_line_number
                     );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg
        );
      END IF;
    -- ����ȊO�̏ꍇ
    ELSE
      -- �q�i�ڃR�[�h��NULL�̏ꍇ
      IF ( iv_item_code IS NULL ) THEN
        lt_item_code         := iv_parent_item_code;
        lt_inventory_item_id := in_parent_item_id;
      ELSE
        lt_item_code         := iv_item_code;
        lt_inventory_item_id := NULL;
      END IF;
      --
      --==============================================================
      -- 2�D�P�ʊ��Z�擾
      --==============================================================
      xxcos_common_pkg.get_uom_cnv(
          iv_before_uom_code    => iv_order_quantity_uom -- ���Z�O�P�ʃR�[�h
        , in_before_quantity    => in_ordered_quantity   -- ���Z�O����
        , iov_item_code         => lt_item_code          -- �i�ڃR�[�h
        , iov_organization_code => gt_organization_code  -- �݌ɑg�D�R�[�h
        , ion_inventory_item_id => lt_inventory_item_id  -- �i�ڂh�c
        , ion_organization_id   => gt_organization_id    -- �݌ɑg�D�h�c
        , iov_after_uom_code    => lt_after_uom_code     -- ���Z��P�ʃR�[�h
        , on_after_quantity     => ln_after_quantity     -- ���Z�㐔��
        , on_content            => ln_content            -- ����
        , ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
        , ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h               #�Œ�#
        , ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
      );
      -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10545
                       , iv_token_name1  => cv_tkn_common_pkg
                       , iv_token_value1 => cv_msg_xxcoi_10552
                       , iv_token_name2  => cv_tkn_errmsg
                       , iv_token_value2 => lv_errmsg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      --==============================================================
      -- 3�D�����擾
      --==============================================================
      -- �P�ʊ��Z�̓����͐������Ȃ����ߎ擾
      SELECT TO_NUMBER(iimb.attribute11) AS attribute11
      INTO   ln_content
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no = lt_item_code
      ;
      -- �P�[�X���E�o�����ϊ�
      ln_order_case_qty   := TRUNC( ln_after_quantity / ln_content );
      ln_order_singly_qty := MOD( ln_after_quantity, ln_content );
      --
      --==============================================================
      -- 4�D����^�C�v�擾
      --==============================================================
      get_tran_type(
          iv_tran_kbn            => iv_tran_kbn            -- ����敪
        , iv_line_name           => iv_line_name           -- ���דE�v
        , iv_sale_class          => iv_sale_class          -- ����敪
        , ion_order_case_qty     => ln_order_case_qty      -- �P�[�X��
        , ion_order_singly_qty   => ln_order_singly_qty    -- �o����
        , ion_after_quantity     => ln_after_quantity      -- ����
        , ov_tran_type_code_temp => lt_tran_type_code_temp -- ����^�C�v�R�[�h
        , ov_tran_type_code      => lt_tran_type_code      -- ����������^�C�v�R�[�h
        , ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W
        , ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h
        , ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      --==============================================================
      -- 5�D���b�g�ʎ��TEMP�쐬
      --==============================================================
      xxcoi_common_pkg.cre_lot_trx_temp(
          in_trx_set_id       => NULL                                   -- ����Z�b�gID
        , iv_parent_item_code => iv_parent_item_code                    -- �e�i�ڃR�[�h
        , iv_child_item_code  => iv_item_code                           -- �q�i�ڃR�[�h
        , iv_lot              => NULL                                   -- ���b�g(�ܖ�����)
        , iv_diff_sum_code    => NULL                                   -- �ŗL�L��
        , iv_trx_type_code    => lt_tran_type_code                      -- ����^�C�v�R�[�h
        , id_trx_date         => id_arrival_date                        -- �����
        , iv_slip_num         => iv_slip_num                            -- �`�[No
        , in_case_in_qty      => ln_content                             -- ����
        , in_case_qty         => ln_order_case_qty                      -- �P�[�X��
        , in_singly_qty       => ln_order_singly_qty                    -- �o����
        , in_summary_qty      => ln_after_quantity                      -- �������
        , iv_base_code        => iv_base_code                           -- ���_�R�[�h
        , iv_subinv_code      => iv_subinventory_code                   -- �ۊǏꏊ�R�[�h
        , iv_tran_subinv_code => NULL                                   -- �]����ۊǏꏊ�R�[�h
        , iv_tran_loc_code    => NULL                                   -- �]���惍�P�[�V�����R�[�h
        , iv_inout_code       => NULL                                   -- ���o�ɃR�[�h
        , iv_source_code      => cv_pkg_name                            -- �\�[�X�R�[�h
        , iv_relation_key     => in_header_id || cv_under || in_line_id -- �R�t���L�[
        , on_trx_id           => lt_trx_id                              -- ���b�g�ʎ������
        , ov_errbuf           => lv_errbuf                              -- �G���[���b�Z�[�W
        , ov_retcode          => lv_retcode                             -- ���^�[���R�[�h
        , ov_errmsg           => lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- ���^�[���R�[�h������̏ꍇ
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ����
        gn_create_temp_cnt := gn_create_temp_cnt + 1;
        -- �ԕi�E�����E�ߋ��f�[�^�̏ꍇ
        IF ( gv_kbn = cv_kbn_5 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10537
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => iv_order_number
                         , iv_token_name2  => cv_tkn_line_number
                         , iv_token_value2 => iv_line_number
                       );
        -- ���m�������̏ꍇ
        ELSIF ( gv_kbn = cv_kbn_6 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10538
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => iv_order_number
                         , iv_token_name2  => cv_tkn_line_number
                         , iv_token_value2 => iv_line_number
                       );
        END IF;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg
        );
      -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10545
                       , iv_token_name1  => cv_tkn_common_pkg
                       , iv_token_value1 => cv_msg_xxcoi_10495
                       , iv_token_name2  => cv_tkn_errmsg
                       , iv_token_value2 => lv_errmsg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
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
  END ins_lot_tran_temp;
--
  /**********************************************************************************
   * Procedure Name   : reserve_process
   * Description      : ���������iA-7����̋��ʏ����j
   ***********************************************************************************/
  PROCEDURE reserve_process(
      iv_process_kbn             IN  VARCHAR2  -- �����敪
    , iv_subinventory_code       IN  VARCHAR2  -- �ۊǏꏊ�R�[�h
    , iv_location_code           IN  VARCHAR2  -- ���P�[�V�����R�[�h
    , iv_location_name           IN  VARCHAR2  -- ���P�[�V������
    , iv_item_div                IN  VARCHAR2  -- ���i�敪
    , iv_item_div_name           IN  VARCHAR2  -- ���i�敪��
    , in_item_id                 IN  NUMBER    -- �q�i��ID
    , iv_item_code               IN  VARCHAR2  -- �q�i�ڃR�[�h
    , iv_item_name               IN  VARCHAR2  -- �q�i�ږ�
    , iv_lot                     IN  VARCHAR2  -- ���b�g
    , iv_difference_summary_code IN  VARCHAR2  -- �ŗL�L��
    , id_production_date         IN  DATE      -- ������
    , id_arrival_date            IN  DATE      -- �[�i��
    , iv_order_number            IN  VARCHAR2  -- �󒍔ԍ�
    , iv_customer_code           IN  VARCHAR2  -- �ڋq�R�[�h
    , iv_parent_item_code        IN  VARCHAR2  -- �e�i�ڃR�[�h
    , ion_short_case_qty         IN OUT NUMBER -- �P�[�X���i�s�����j
    , ion_short_singly_qty       IN OUT NUMBER -- �o�����i�s�����j
    , ion_short_summary_qty      IN OUT NUMBER -- �����i�s�����j
    , ov_errbuf                  OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                 OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                  OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reserve_process'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_reserve_err_msg         VARCHAR2(16)                                DEFAULT NULL; -- ���������ɂăG���[�������̃��b�Z�[�W�R�[�h���i�[
    ld_fresh_condition_date    DATE                                        DEFAULT NULL; -- �N�x�������
    lt_lot_reverse_mark        xxcoi_lot_reserve_info.mark%TYPE            DEFAULT NULL; -- �L��
    --
    lt_case_in_qty             xxcoi_lot_onhand_quantites.case_in_qty%TYPE DEFAULT 0;    -- ����
    lt_case_qty                xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- �P�[�X���i�����\���j
    lt_singly_qty              xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- �o�����i�����\���j
    lt_summary_qty             xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- �����i�����\���j
    --
    lt_reserve_case_qty        xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- �P�[�X���i�������j
    lt_reserve_singly_qty      xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- �o�����i�������j
    lt_reserve_summary_qty     xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- �����i�������j
    --
    lt_short_case_qty          xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- �P�[�X���i�s�����j
    lt_short_singly_qty        xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- �o�����i�s�����j
    lt_short_summary_qty       xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- �����i�s�����j
    --
    lt_after_case_qty          xxcoi_lot_onhand_quantites.case_qty%TYPE    DEFAULT 0;    -- �P�[�X���i�����㐔�j
    lt_after_singly_qty        xxcoi_lot_onhand_quantites.singly_qty%TYPE  DEFAULT 0;    -- �o�����i�����㐔�j
    lt_after_summary_qty       xxcoi_lot_onhand_quantites.summary_qty%TYPE DEFAULT 0;    -- �����i�����㐔�j
--
    -- *** ���[�J���J�[�\�� ***
    -- ���������b�g�J�[�\��
    CURSOR l_status_20_cur( iv_order_number     VARCHAR2
                          , iv_customer_code    VARCHAR2
                          , iv_parent_item_code VARCHAR2
                          , id_arrival_date     DATE
                          , iv_lot              VARCHAR2 )
    IS
      SELECT xlri.order_number      AS order_number
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status          IN (cv_shipping_status_20, cv_shipping_status_25)
      AND    xlri.order_number             <> iv_order_number
      AND    xlri.customer_code             = iv_customer_code
      AND    xlri.parent_item_code          = iv_parent_item_code
      AND    xlri.arrival_date              < id_arrival_date
      AND    TO_DATE(xlri.lot, cv_yyyymmdd) > TO_DATE(iv_lot, cv_yyyymmdd)
      ORDER BY xlri.order_number
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
    -- ������
    lt_short_case_qty    := ion_short_case_qty;
    lt_short_singly_qty  := ion_short_singly_qty;
    lt_short_summary_qty := ion_short_summary_qty;
    -- �����\���Z�o
    xxcoi_common_pkg.get_reserved_quantity(
        in_inv_org_id    => gt_organization_id         -- �݌ɑg�DID
      , iv_base_code     => gv_login_base_code         -- ���_�R�[�h
      , iv_subinv_code   => iv_subinventory_code       -- �ۊǏꏊ�R�[�h
      , iv_loc_code      => iv_location_code           -- ���P�[�V�����R�[�h
      , in_child_item_id => in_item_id                 -- �q�i��ID
      , iv_lot           => iv_lot                     -- ���b�g
      , iv_diff_sum_code => iv_difference_summary_code -- �ŗL�L��
      , on_case_in_qty   => lt_case_in_qty             -- ����
      , on_case_qty      => lt_case_qty                -- �P�[�X��
      , on_singly_qty    => lt_singly_qty              -- �o����
      , on_summary_qty   => lt_summary_qty             -- �������
      , ov_errbuf        => lv_errbuf                  -- �G���[���b�Z�[�W
      , ov_retcode       => lv_retcode                 -- ���^�[���R�[�h
      , ov_errmsg        => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10561
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => '�������� �����\��' ||
                  ' �����F'             || lt_case_in_qty ||
                  ' �P�[�X���F'         || lt_case_qty    ||
                  ' �o�����F'           || lt_singly_qty  ||
                  ' ������ʁF'         || lt_summary_qty
    );
    -- �����\�������݂���ꍇ
    IF ( lt_summary_qty > 0 ) THEN
      -- �ŐV�̔[�i���E���b�g��NULL�̏ꍇ�͓���l��ݒ�
      IF ( gd_last_deliver_lot IS NULL ) THEN
        gd_last_deliver_lot := TO_DATE(iv_lot, cv_yyyymmdd);
      END IF;
      IF ( gd_delivery_date IS NULL ) THEN
        gd_delivery_date    := id_arrival_date;
      END IF;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => '�������� ���b�g�t�]����' ||
                    ' �ŐV�ܖ������F'         || TO_CHAR(gd_last_deliver_lot, cv_yyyymmdd) || ' �ŐV�[�i���F' || TO_CHAR(gd_delivery_date, cv_yyyymmdd) ||
                    ' �ܖ������F'             || iv_lot                                    || ' �[�i���F'     || TO_CHAR(id_arrival_date, cv_yyyymmdd)
      );
      --
      -- ���b�g�t�]����
      --   �@�ŐV�[�i�����O���ŐV���b�g�ȑO  �F�Ӑ}�I�ɍs�Ȃ���p�^�[��
      --   �A�ŐV�[�i�����O���ŐV���b�g����F������̒ʏ�ȂǁA�ォ��Â����b�g�������p�^�[���͋L�����o��
      --   �B�ŐV�[�i���Ɠ���                    �F��{�p�^�[���B���������b�g�t�]�Ƃ��Ȃ�
      --   �C�ŐV�[�i�����ォ�ŐV���b�g���O�F���b�g�t�]
      --                                            �P�D�D�惍�P�[�V�����܂��͒ʏ탍�P�[�V���������b�g�t�]�F���b�Z�[�W�o�͍͂s���A��������
      --                                            �Q�D�ʏ탍�P�[�V�����Ń��b�g�t�]�ہF�������Ȃ��i���������b�Z�[�W�o�͂͑S�Ă̕i�ڂň����ł��Ȃ������ꍇ�̂݁j
      --   �D�ŐV�[�i�����ォ�ŐV���b�g�ȍ~  �F��{�p�^�[��
      IF    ( ( gd_delivery_date > id_arrival_date )  AND ( gd_last_deliver_lot >= TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        NULL;
      ELSIF ( ( gd_delivery_date > id_arrival_date )  AND ( gd_last_deliver_lot < TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        -- ���b�g�t�]�L��
        lt_lot_reverse_mark := gt_lot_reverse_mark;
      ELSIF ( gd_delivery_date = id_arrival_date ) THEN
        NULL;
      ELSIF ( ( gd_delivery_date < id_arrival_date ) AND ( gd_last_deliver_lot > TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        -- �D�惍�P�[�V��������̈���
        -- �܂��� �ʏ�܂��̓_�~�[���P�[�V��������̈����Ń��b�g�t�]�̏ꍇ�̓��b�Z�[�W�o�͂ň����\
        IF ( ( iv_process_kbn = cv_process_kbn_1 )
          OR ( ( iv_process_kbn = cv_process_kbn_2 ) AND ( gv_lot_reversal_flag = cv_flag_y ) ) ) THEN
          -- ���b�g�t�]�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10548
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => iv_order_number
                         , iv_token_name2  => cv_tkn_customer_code
                         , iv_token_value2 => iv_customer_code
                         , iv_token_name3  => cv_tkn_item_code
                         , iv_token_value3 => iv_parent_item_code
                       );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg
          );
        ELSE
          lv_reserve_err_msg := cv_msg_xxcoi_10548;
          gv_reserve_err_msg := lv_reserve_err_msg;
        END IF;
      ELSIF ( ( gd_delivery_date < id_arrival_date ) AND ( gd_last_deliver_lot <= TO_DATE(iv_lot, cv_yyyymmdd) ) ) THEN
        NULL;
      END IF;
      --
      -- ���b�g�t�]�ۂ̏ꍇ�͈������s�Ȃ�Ȃ����߁A�N�x�����`�F�b�N���s�Ȃ�Ȃ�
      IF ( lv_reserve_err_msg IS NULL ) THEN
        -- �N�x��������Z�o
        xxcoi_common_pkg.get_fresh_condition_date(
           id_use_by_date          => TO_DATE(iv_lot, cv_yyyymmdd) -- �ܖ�����
         , id_product_date         => id_production_date           -- �����N����
         , iv_fresh_condition      => gt_cust_fresh_con_code       -- �N�x����
         , od_fresh_condition_date => ld_fresh_condition_date      -- �N�x�������
         , ov_errbuf               => lv_errbuf                    -- �G���[���b�Z�[�W
         , ov_retcode              => lv_retcode                   -- ���^�[���E�R�[�h(0:����A2:�G���[)
         , ov_errmsg               => lv_errmsg                    -- ���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '�������� �N�x������� ' || TO_CHAR(ld_fresh_condition_date, cv_yyyymmdd)
        );
        -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10545
                         , iv_token_name1  => cv_tkn_common_pkg
                         , iv_token_value1 => cv_msg_xxcoi_10560
                         , iv_token_name2  => cv_tkn_errmsg
                         , iv_token_value2 => lv_errmsg
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        -- �[�i�����N�x��������𖞂����Ă��Ȃ��ꍇ
        IF ( id_arrival_date >= ld_fresh_condition_date ) THEN
          -- �D�惍�P�[�V��������̈����̏ꍇ
          IF ( iv_process_kbn = cv_process_kbn_1 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10550
                           , iv_token_name1  => cv_tkn_order_number
                           , iv_token_value1 => iv_order_number
                           , iv_token_name2  => cv_tkn_item_code
                           , iv_token_value2 => iv_parent_item_code
                           , iv_token_name3  => cv_tkn_fresh_condition
                           , iv_token_value3 => gt_cust_fresh_con_code
                         );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg
            );
          ELSE
            lv_reserve_err_msg := cv_msg_xxcoi_10550;
            gv_reserve_err_msg := lv_reserve_err_msg;
          END IF;
        END IF;
      END IF;
      --
      -- ���b�g�t�]�ۂŃ��b�g�t�]���Ă���A�܂��́A�N�x����NG�̏ꍇ�͈������s�Ȃ�Ȃ�
      --   ���D�惍�P�[�V��������̈����́A���b�g�t�]��N�x����NG�ł����Ă���������
      --   ���ʏ�܂��̓_�~�[���P�[�V��������̈����́A���b�g�t�]�ł���΃��b�g�t�]���Ă���������
      IF ( lv_reserve_err_msg IS NULL ) THEN
        -- �P�[�X��
        -- �P�[�X���i�s�����j = 0
        IF ( lt_short_case_qty = 0 ) THEN
          lt_reserve_case_qty := 0;           -- �P�[�X���i�������j
          lt_short_case_qty   := 0;           -- �P�[�X���i�s�����j
          lt_after_case_qty   := lt_case_qty; -- �P�[�X���i�����㐔�j
        ELSE
          -- �P�[�X���i�s�����j >= �����\�P�[�X��
          IF ( lt_short_case_qty >= lt_case_qty ) THEN
            lt_reserve_case_qty := lt_case_qty;                       -- �P�[�X���i�������j
            lt_short_case_qty   := lt_short_case_qty - lt_case_qty  ; -- �P�[�X���i�s�����j
            lt_after_case_qty   := 0;                                 -- �P�[�X���i�����㐔�j
          -- �P�[�X���i�s�����j  < �����\�P�[�X��
          ELSE
            lt_reserve_case_qty := lt_short_case_qty;                 -- �P�[�X���i�������j
            lt_short_case_qty   := 0;                                 -- �P�[�X���i�s�����j
            lt_after_case_qty   := lt_case_qty - lt_reserve_case_qty; -- �P�[�X���i�����㐔�j
          END IF;
        END IF;
        --
        -- �o����
        -- �o�����i�s�����j = 0
        IF ( lt_short_singly_qty = 0 ) THEN
          lt_reserve_singly_qty := 0;           -- �P�[�X���i�������j
          lt_short_singly_qty   := 0;           -- �P�[�X���i�s�����j
          lt_after_singly_qty   := lt_singly_qty; -- �P�[�X���i�����㐔�j
        ELSE
          -- �o�����i�s�����j >= �����\�o����
          IF ( lt_short_singly_qty >= lt_singly_qty ) THEN
            lt_reserve_singly_qty := lt_singly_qty;                       -- �o�����i�������j
            lt_short_singly_qty   := lt_short_singly_qty - lt_singly_qty; -- �o�����i�s�����j
            lt_after_singly_qty   := 0;                                   -- �o�����i�����㐔�j
            --
            -- �o�����i�s�����j�����݂��A�P�[�X���Ɉ����\�������݂���ꍇ
            IF ( ( lt_short_singly_qty > 0 ) AND ( lt_after_case_qty > 0 ) ) THEN
              lt_after_case_qty     := lt_after_case_qty - 1;                                          -- �P�[�X���i�����㐔�j
              lt_reserve_singly_qty := lt_reserve_singly_qty + lt_short_singly_qty;                    -- �o�����i�������j
              lt_after_singly_qty   := lt_after_singly_qty + ( lt_case_in_qty - lt_short_singly_qty ); -- �o�����i�����㐔�j
              lt_short_singly_qty   := 0;                                                              -- �o�����i�s�����j
            END IF;
          -- �o�����i�s�����j < �����\�o����
          ELSE
            lt_reserve_singly_qty := lt_short_singly_qty;                   -- �o�����i�������j
            lt_short_singly_qty   := 0;                                     -- �o�����i�s�����j
            lt_after_singly_qty   := lt_singly_qty - lt_reserve_singly_qty; -- �o�����i�����㐔�j
          END IF;
        END IF;
        --
        -- ������
        lt_reserve_summary_qty := ( lt_case_in_qty * lt_reserve_case_qty ) + lt_reserve_singly_qty; -- �����i�������j
        lt_short_summary_qty   := ( lt_case_in_qty * lt_short_case_qty ) + lt_short_singly_qty;     -- �����i�s�����j
        lt_after_summary_qty   := ( lt_case_in_qty * lt_after_case_qty ) + lt_after_singly_qty;     -- �����i�����㐔�j
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '�������� ������' ||
                      ' �����F'         || lt_case_in_qty         ||
                      ' �P�[�X���F'     || lt_reserve_case_qty    ||
                      ' �o�����F'       || lt_reserve_singly_qty  ||
                      ' ������ʁF'     || lt_reserve_summary_qty
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '�������� �s����' ||
                      ' �����F'         || lt_case_in_qty       ||
                      ' �P�[�X���F'     || lt_short_case_qty    ||
                      ' �o�����F'       || lt_short_singly_qty  ||
                      ' ������ʁF'     || lt_short_summary_qty
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '�������� ������݌ɐ�' ||
                      ' �����F'               || lt_case_in_qty       ||
                      ' �P�[�X���F'           || lt_after_case_qty    ||
                      ' �o�����F'             || lt_after_singly_qty  ||
                      ' ������ʁF'           || lt_after_summary_qty
        );
        --
        -- �������i�[�z��F���b�g�ʈ������ւ̓o�^���e
        IF ( lt_reserve_summary_qty > 0 ) THEN
          gn_reserve_cnt                                         := gn_reserve_cnt + 1;
          gt_reserve_tab(gn_reserve_cnt).location_code           := iv_location_code;
          gt_reserve_tab(gn_reserve_cnt).location_name           := iv_location_name;
          gt_reserve_tab(gn_reserve_cnt).item_div                := iv_item_div;
          gt_reserve_tab(gn_reserve_cnt).item_div_name           := iv_item_div_name;
          gt_reserve_tab(gn_reserve_cnt).item_code               := iv_item_code;
          gt_reserve_tab(gn_reserve_cnt).item_name               := iv_item_name;
          gt_reserve_tab(gn_reserve_cnt).lot                     := iv_lot;
          gt_reserve_tab(gn_reserve_cnt).difference_summary_code := iv_difference_summary_code;
          gt_reserve_tab(gn_reserve_cnt).case_in_qty             := lt_case_in_qty;
          gt_reserve_tab(gn_reserve_cnt).case_qty                := lt_reserve_case_qty;
          gt_reserve_tab(gn_reserve_cnt).singly_qty              := lt_reserve_singly_qty;
          gt_reserve_tab(gn_reserve_cnt).summary_qty             := lt_reserve_summary_qty;
          gt_reserve_tab(gn_reserve_cnt).mark                    := lt_lot_reverse_mark;
          gt_reserve_tab(gn_reserve_cnt).item_id                 := in_item_id;
          IF ( lt_short_summary_qty <> 0 ) THEN
            gt_reserve_tab(gn_reserve_cnt).short_case_in_qty     := lt_case_in_qty;
          ELSE
            gt_reserve_tab(gn_reserve_cnt).short_case_in_qty     := 0;
          END IF;
          gt_reserve_tab(gn_reserve_cnt).short_case_qty          := lt_short_case_qty;
          gt_reserve_tab(gn_reserve_cnt).short_singly_qty        := lt_short_singly_qty;
          gt_reserve_tab(gn_reserve_cnt).short_summary_qty       := lt_short_summary_qty;
          --
          -- ���������b�g�̃��b�g�t�]���b�Z�[�W�o��
          << status_20_loop >>
          FOR l_status_20_rec IN l_status_20_cur( iv_order_number     => iv_order_number
                                                , iv_customer_code    => iv_customer_code
                                                , iv_parent_item_code => iv_parent_item_code
                                                , id_arrival_date     => id_arrival_date
                                                , iv_lot              => iv_lot ) LOOP
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10549
                           , iv_token_name1  => cv_tkn_order_number2
                           , iv_token_value1 => l_status_20_rec.order_number
                           , iv_token_name2  => cv_tkn_order_number
                           , iv_token_value2 => iv_order_number
                           , iv_token_name3  => cv_tkn_customer_code
                           , iv_token_value3 => iv_customer_code
                           , iv_token_name4  => cv_tkn_item_code
                           , iv_token_value4 => iv_parent_item_code
                         );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg
            );
          END LOOP status_20_loop;
          --
        END IF;
        --
      ELSE
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '�������� �������{NG' || ' �G���[�R�[�h�F' || lv_reserve_err_msg
        );
      END IF;
      --
    ELSE
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => '�������� �������{NG �����\��0'
      );
    END IF;
    --
    -- �߂�
    ion_short_case_qty    := lt_short_case_qty;
    ion_short_singly_qty  := lt_short_singly_qty;
    ion_short_summary_qty := lt_short_summary_qty;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END reserve_process;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_login_base_code        IN  VARCHAR2 -- ���_
    , iv_delivery_date_from     IN  VARCHAR2 -- ����From
    , iv_delivery_date_to       IN  VARCHAR2 -- ����To
    , iv_login_chain_store_code IN  VARCHAR2 -- �`�F�[���X
    , iv_login_customer_code    IN  VARCHAR2 -- �ڋq
    , iv_customer_po_number     IN  VARCHAR2 -- �ڋq�����ԍ�
    , iv_subinventory_code      IN  VARCHAR2 -- �ۊǏꏊ
    , iv_priority_flag          IN  VARCHAR2 -- �D�惍�P�[�V�����g�p
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ���b�g�t�]��
    , iv_kbn                    IN  VARCHAR2 -- ����敪
    , ov_errbuf                 OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                 OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_errmsg2              VARCHAR2(5000);                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W2
    lt_edi_order_source     fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- EDI�󒍃\�[�X
    lt_chain_store_name     hz_parties.party_name%TYPE                          DEFAULT NULL; -- �`�F�[���X��
    lt_customer_name        hz_parties.party_name%TYPE                          DEFAULT NULL; -- �ڋq��
    lt_subinventory_name    mtl_secondary_inventories.description%TYPE          DEFAULT NULL; -- �ۊǏꏊ��
    lt_priority_flag        fnd_lookup_values.meaning%TYPE                      DEFAULT NULL; -- �D�惍�P�[�V�����g�p_���e
    lt_lot_reversal_flag    fnd_lookup_values.meaning%TYPE                      DEFAULT NULL; -- ���b�g�t�]��_���e
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^���O���[�o���ϐ��ɕێ�
    gv_login_base_code        := iv_login_base_code;                                   -- ���_
    gd_delivery_date_from     := TO_DATE(iv_delivery_date_from, cv_yyyymmdd_hh24miss); -- ����From
    gd_delivery_date_to       := TO_DATE(iv_delivery_date_to, cv_yyyymmdd_hh24miss);   -- ����To
    gv_login_chain_store_code := iv_login_chain_store_code;                            -- �`�F�[���X
    gv_login_customer_code    := iv_login_customer_code;                               -- �ڋq
    gv_customer_po_number     := iv_customer_po_number;                                -- �ڋq�����ԍ�
    gv_subinventory_code      := iv_subinventory_code;                                 -- �ۊǏꏊ
    gv_priority_flag          := iv_priority_flag;                                     -- �D�惍�P�[�V�����g�p
    gv_lot_reversal_flag      := iv_lot_reversal_flag;                                 -- ���b�g�t�]��
    gv_kbn                    := iv_kbn;                                               -- ����敪
--
    --==============================================================
    -- 1�D�Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application
                     , iv_name        => cv_msg_xxcoi_00011
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ������NULL�̏ꍇ
    IF ( gd_delivery_date_from IS NULL ) THEN
      gd_delivery_date_from := gd_process_date;
      gd_delivery_date_to   := gd_process_date;
    END IF;
--
    --==============================================================
    -- 2�D�݌ɑg�DID�擾
    --==============================================================
    -- �v���t�@�C���擾
    gt_organization_code := FND_PROFILE.VALUE(cv_organization_code);
    --
    IF ( gt_organization_code IS NULL ) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00005
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �݌ɑg�DID�擾
    gt_organization_id := xxcoi_common_pkg.get_organization_id(gt_organization_code);
    --
    IF ( gt_organization_id IS NULL ) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00006
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => gt_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 3�D�c�ƒP�ʎ擾
    --==============================================================
    gt_org_id := FND_PROFILE.VALUE(cv_org_id);
    --
    IF ( gt_org_id IS NULL ) THEN
      -- �v���t�@�C���l�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_org_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4�D���b�g�t�]�L���擾
    --==============================================================
    gt_lot_reverse_mark := FND_PROFILE.VALUE(cv_lot_reverse_mark);
    --
    IF ( gt_lot_reverse_mark IS NULL ) THEN
      -- �v���t�@�C���l�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_lot_reverse_mark
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 5�DEDI�󒍃\�[�X�擾
    --==============================================================
    -- �v���t�@�C���擾
    lt_edi_order_source := FND_PROFILE.VALUE(cv_edi_order_source);
    --
    IF ( lt_edi_order_source IS NULL ) THEN
      -- �v���t�@�C���l�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_edi_order_source
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �󒍃\�[�XID�擾
    BEGIN
      SELECT oos.order_source_id AS order_source_id
      INTO   gt_order_source_id
      FROM   oe_order_sources    oos
      WHERE  oos.name = lt_edi_order_source
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �󒍃\�[�X�擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_xxcos
                       , iv_name         => cv_msg_xxcos_11538
                       , iv_token_name1  => cv_tkn_order_source_name
                       , iv_token_value1 => lt_edi_order_source
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
-- Add Ver1.1 Start
    --==============================================================
    --    �����f�[�^�擾����
    --==============================================================
    BEGIN
      gt_period_xxcoi016a06c1 := TO_NUMBER(FND_PROFILE.VALUE(cv_period_xxcoi016a06c1));
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_00032
                       , iv_token_name1  => cv_tkn_pro_tok
                       , iv_token_value1 => cv_period_xxcoi016a06c1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    IF ( gt_period_xxcoi016a06c1 IS NULL ) THEN
      -- �v���t�@�C���l�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_period_xxcoi016a06c1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --    �ԕi�E�����E�ߋ��f�[�^�擾����
    --==============================================================
    BEGIN
      gt_period_xxcoi016a06c5 := TO_NUMBER(FND_PROFILE.VALUE(cv_period_xxcoi016a06c5));
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_00032
                       , iv_token_name1  => cv_tkn_pro_tok
                       , iv_token_value1 => cv_period_xxcoi016a06c5
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    IF ( gt_period_xxcoi016a06c5 IS NULL ) THEN
      -- �v���t�@�C���l�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_xxcoi_00032
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_period_xxcoi016a06c5
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Add Ver1.1 End
--
    --==============================================================
    -- 6�D��ԓ����敪���擾
    --==============================================================
    -- ���
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gt_teiban_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type                            = cv_bargain_class
      AND    flv.attribute1                             = cv_flag_y
      AND    flv.language                               = ct_lang
      AND    flv.enabled_flag                           = cv_flag_y
      AND    flv.start_date_active                     <= gd_process_date
      AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ��ԏ��擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_xxcos
                       , iv_name         => cv_msg_xxcos_00186
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- ����
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gt_tokubai_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type                            = cv_bargain_class
      AND    flv.attribute1                             = cv_flag_n
      AND    flv.language                               = ct_lang
      AND    flv.enabled_flag                           = cv_flag_y
      AND    flv.start_date_active                     <= gd_process_date
      AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �������擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_xxcos
                       , iv_name         => cv_msg_xxcos_00187
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 7�D�����󒍃^�C�v���擾
    --==============================================================
    -- �ԕi�A�ԕi����
    SELECT flv.meaning       AS meaning
    BULK COLLECT INTO gt_return_tab
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type                            = cv_order_type_mst
    AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
    AND    flv.attribute2                             = cv_flag_y
    AND    flv.language                               = ct_lang
    AND    flv.enabled_flag                           = cv_flag_y
    AND    flv.start_date_active                     <= gd_process_date
    AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
    ;
    --
    IF ( gt_return_tab.COUNT = 0 ) THEN
      -- �󒍃^�C�v�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_xxcos
                     , iv_name         => cv_msg_xxcos_12005
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ����
    SELECT flv.meaning       AS meaning
    BULK COLLECT INTO gt_correct_tab
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type                            = cv_order_type_mst
    AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
    AND    flv.attribute1                             = cv_flag_y
    AND    flv.language                               = ct_lang
    AND    flv.enabled_flag                           = cv_flag_y
    AND    flv.start_date_active                     <= gd_process_date
    AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
    ;
    --
    IF ( gt_correct_tab.COUNT = 0 ) THEN
      -- �󒍃^�C�v�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_xxcos
                     , iv_name         => cv_msg_xxcos_12005
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 8�D���_���擾
    --==============================================================
    -- ���_���ݒ肳��Ă���ꍇ
    IF ( gv_login_base_code IS NOT NULL ) THEN
      SELECT xlbiv.base_name         AS base_name
      INTO   gt_base_name
      FROM   xxcos_login_base_info_v xlbiv
      WHERE  xlbiv.base_code = gv_login_base_code
      ;
    END IF;
--
    --==============================================================
    -- 9�D�`�F�[���X���擾
    --==============================================================
    -- �`�F�[���X���ݒ肳��Ă���ꍇ
    IF ( gv_login_chain_store_code IS NOT NULL ) THEN
      SELECT hp.party_name       AS chain_store_name
      INTO   lt_chain_store_name
      FROM   hz_cust_accounts    hca
           , hz_parties          hp
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.party_id            = hp.party_id
      AND    xca.chain_store_code IN
               ( SELECT DISTINCT xca1.chain_store_code AS chain_store_code
                 FROM   hz_cust_accounts               hca1
                      , xxcmm_cust_accounts            xca1
                      , xxcos_login_base_info_v        xlbiv
                 WHERE  hca1.cust_account_id     = xca1.customer_id
                 AND    xca1.delivery_base_code  = xlbiv.base_code
                 AND    hca1.customer_class_code IN ( cv_customer_class_code_10, cv_customer_class_code_12 )
                 AND    xca1.delivery_base_code  = gv_login_base_code )
      AND    hca.customer_class_code = cv_customer_class_code_18
      AND    xca.chain_store_code    = gv_login_chain_store_code
      ;
    END IF;
--
    --==============================================================
    -- 10�D�ڋq���擾
    --==============================================================
    -- �ڋq���ݒ肳��Ă���ꍇ
    IF ( gv_login_customer_code IS NOT NULL ) THEN
      SELECT hp.party_name       AS customer_name
      INTO   lt_customer_name
      FROM   hz_cust_accounts    hca
           , hz_parties          hp
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.party_id            = hp.party_id
      AND    hca.customer_class_code IN ( cv_customer_class_code_10, cv_customer_class_code_12 )
      AND    xca.delivery_base_code  = gv_login_base_code
      AND    hca.account_number      = gv_login_customer_code
      ;
    END IF;
--
    --==============================================================
    -- 11�D�ۊǏꏊ���擾
    --==============================================================
    -- �ۊǏꏊ���ݒ肳��Ă���ꍇ
    IF ( gv_subinventory_code IS NOT NULL ) THEN
      SELECT msi.description           AS subinventory_name
      INTO   lt_subinventory_name
      FROM   mtl_secondary_inventories msi
           , xxcoi_base_info2_v        xbiv
      WHERE  msi.attribute7                             = xbiv.base_code
      AND    msi.attribute14                            = cv_flag_y
      AND    msi.organization_id                        = gt_organization_id
      AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
      AND    xbiv.focus_base_code                       = gv_login_base_code
      AND    msi.secondary_inventory_name               = gv_subinventory_code
      ;
    END IF;
--
    --==============================================================
    -- 12�D�D�惍�P�[�V�����g�p�擾
    --==============================================================
    -- �����̏ꍇ
    IF ( gv_kbn = cv_kbn_1 ) THEN
      lt_priority_flag := xxcoi_common_pkg.get_meaning(
                              iv_lookup_type => cv_priority_flag
                            , iv_lookup_code => gv_priority_flag
                          );
    END IF;
--
    --==============================================================
    -- 13�D���b�g�t�]�ێ擾
    --==============================================================
    -- �����̏ꍇ
    IF ( gv_kbn = cv_kbn_1 ) THEN
      lt_lot_reversal_flag := xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type => cv_lot_reversal_flag
                                , iv_lookup_code => gv_lot_reversal_flag
                              );
    END IF;
--
    --==============================================================
    -- 14�D����敪�擾
    --==============================================================
    gt_xxcoi016a06_kbn := xxcoi_common_pkg.get_meaning(
                              iv_lookup_type => cv_xxcoi016a06_kbn
                            , iv_lookup_code => gv_kbn
                          );
--
    --==============================================================
    -- 15�D�o�׏��X�e�[�^�X�擾
    --==============================================================
    -- �����̏ꍇ
    IF ( gv_kbn = cv_kbn_1 ) THEN
      -- ������
      gt_shipping_status_10 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_10
                            );
      --
      IF ( gt_shipping_status_10 IS NULL ) THEN
        -- �o�׏��X�e�[�^�X���擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_10
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- ������
      gt_shipping_status_20 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_20
                            );
      --
      IF ( gt_shipping_status_20 IS NULL ) THEN
        -- �o�׏��X�e�[�^�X���擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_20
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
    -- �o�׉��m��̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_3 ) THEN
      -- �o�׉��m��
      gt_shipping_status_25 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_25
                            );
      --
      IF ( gt_shipping_status_25 IS NULL ) THEN
        -- �o�׏��X�e�[�^�X���擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_25
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    -- �o�׊m��̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_4 ) THEN
      -- �o�׊m���
      gt_shipping_status_30 := xxcoi_common_pkg.get_meaning(
                                iv_lookup_type => cv_shipping_status
                              , iv_lookup_code => cv_shipping_status_30
                            );
      --
      IF ( gt_shipping_status_30 IS NULL ) THEN
        -- �o�׏��X�e�[�^�X���擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10530
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_shipping_status
                       , iv_token_name2  => cv_tkn_lookup_code
                       , iv_token_value2 => cv_shipping_status_30
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 16�D�����`�F�b�N
    --==============================================================
    -- ����From-To�̋t�]�`�F�b�N
    IF ( gd_delivery_date_from > gd_delivery_date_to ) THEN
      -- �����t�]�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10531
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- Mod Ver1.3 Start
--    -- �����܂��͈��������̏ꍇ
--    IF ( ( gv_kbn = cv_kbn_1 ) OR ( gv_kbn = cv_kbn_2 ) ) THEN
    -- �����̏ꍇ
    IF ( gv_kbn = cv_kbn_1 ) THEN
-- Mod Ver1.3 End
      -- ����From�܂��͒���To�̋Ɩ����t���ߋ����`�F�b�N
      IF ( ( gd_delivery_date_from < gd_process_date )
        OR ( gd_delivery_date_to < gd_process_date ) ) THEN
        -- �����ߋ����G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10532
                       , iv_token_name1  => cv_tkn_process
                       , iv_token_value1 => gt_xxcoi016a06_kbn
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
-- 2015/05/12 �ڍs�p Del Start
-- Mod Ver1.3 Start
--    --==============================================================
--    --     �K�{�`�F�b�N
--    --==============================================================
--    -- �������s�i���_�R�[�h���w�肳��Ă���j�̏ꍇ
--    IF ( gv_login_base_code IS NOT NULL ) THEN
--      -- �`�F�[���Xor�ڋqor�ڋq�����ԍ��̂�������w�肳��Ă��Ȃ��ꍇ
--      IF (  ( gv_login_chain_store_code IS NULL )
--        AND ( gv_login_customer_code IS NULL )
--        AND ( gv_customer_po_number IS NULL ) ) THEN
--        -- �p�����[�^�K�{�G���[���b�Z�[�W
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application
--                       , iv_name         => cv_msg_xxcoi_10703
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      END IF;
--    END IF;
-- Mod Ver1.3 End
-- 2015/05/12 �ڍs�p Del End
--
    --==============================================================
    -- 17�D�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    --==============================================================
    -- �����̏ꍇ
    IF ( gv_kbn = cv_kbn_1 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application                              -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcoi_10533                          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_param1                               -- �g�[�N���R�[�h1
                     , iv_token_value1 => gv_login_base_code                          -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_param_name1                          -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_base_name                                -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_param2                               -- �g�[�N���R�[�h3
                     , iv_token_value3 => TO_CHAR(gd_delivery_date_from, cv_yyyymmdd) -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_param3                               -- �g�[�N���R�[�h4
                     , iv_token_value4 => TO_CHAR(gd_delivery_date_to, cv_yyyymmdd)   -- �g�[�N���l4
                     , iv_token_name5  => cv_tkn_param4                               -- �g�[�N���R�[�h5
                     , iv_token_value5 => gv_login_chain_store_code                   -- �g�[�N���l5
                     , iv_token_name6  => cv_tkn_param_name4                          -- �g�[�N���R�[�h6
                     , iv_token_value6 => lt_chain_store_name                         -- �g�[�N���l6
                     , iv_token_name7  => cv_tkn_param5                               -- �g�[�N���R�[�h7
                     , iv_token_value7 => gv_login_customer_code                      -- �g�[�N���l7
                     , iv_token_name8  => cv_tkn_param_name5                          -- �g�[�N���R�[�h8
                     , iv_token_value8 => lt_customer_name                            -- �g�[�N���l8
                     , iv_token_name9  => cv_tkn_param6                               -- �g�[�N���R�[�h9
                     , iv_token_value9 => gv_customer_po_number                       -- �g�[�N���l9
                   );
      lv_errmsg2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application                             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcoi_10534                         -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_param7                              -- �g�[�N���R�[�h1
                      , iv_token_value1 => gv_subinventory_code                       -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_param_name7                         -- �g�[�N���R�[�h2
                      , iv_token_value2 => lt_subinventory_name                       -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_param8                              -- �g�[�N���R�[�h3
                      , iv_token_value3 => gv_priority_flag                           -- �g�[�N���l3
                      , iv_token_name4  => cv_tkn_param_name8                         -- �g�[�N���R�[�h4
                      , iv_token_value4 => lt_priority_flag                           -- �g�[�N���l4
                      , iv_token_name5  => cv_tkn_param9                              -- �g�[�N���R�[�h5
                      , iv_token_value5 => gv_lot_reversal_flag                       -- �g�[�N���l5
                      , iv_token_name6  => cv_tkn_param_name9                         -- �g�[�N���R�[�h6
                      , iv_token_value6 => lt_lot_reversal_flag                       -- �g�[�N���l6
                      , iv_token_name7  => cv_tkn_param10                             -- �g�[�N���R�[�h7
                      , iv_token_value7 => gv_kbn                                     -- �g�[�N���l7
                      , iv_token_name8  => cv_tkn_param_name10                        -- �g�[�N���R�[�h8
                      , iv_token_value8 => gt_xxcoi016a06_kbn                         -- �g�[�N���l8
                    );
    -- ���������A�o�׉��m��A�o�׊m��A�ԕi�E�����E�ߋ��f�[�^�A���m�������̏ꍇ
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application                              -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcoi_10535                          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_param1                               -- �g�[�N���R�[�h1
                     , iv_token_value1 => gv_login_base_code                          -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_param_name1                          -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_base_name                                -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_param2                               -- �g�[�N���R�[�h3
                     , iv_token_value3 => TO_CHAR(gd_delivery_date_from, cv_yyyymmdd) -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_param3                               -- �g�[�N���R�[�h4
                     , iv_token_value4 => TO_CHAR(gd_delivery_date_to, cv_yyyymmdd)   -- �g�[�N���l4
                     , iv_token_name5  => cv_tkn_param4                               -- �g�[�N���R�[�h5
                     , iv_token_value5 => gv_login_chain_store_code                   -- �g�[�N���l5
                     , iv_token_name6  => cv_tkn_param_name4                          -- �g�[�N���R�[�h6
                     , iv_token_value6 => lt_chain_store_name                         -- �g�[�N���l6
                     , iv_token_name7  => cv_tkn_param5                               -- �g�[�N���R�[�h7
                     , iv_token_value7 => gv_login_customer_code                      -- �g�[�N���l7
                     , iv_token_name8  => cv_tkn_param_name5                          -- �g�[�N���R�[�h8
                     , iv_token_value8 => lt_customer_name                            -- �g�[�N���l8
                     , iv_token_name9  => cv_tkn_param6                               -- �g�[�N���R�[�h9
                     , iv_token_value9 => gv_customer_po_number                       -- �g�[�N���l9
                   );
      lv_errmsg2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application                             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcoi_10536                         -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_param7                              -- �g�[�N���R�[�h1
                      , iv_token_value1 => gv_subinventory_code                       -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_param_name7                         -- �g�[�N���R�[�h2
                      , iv_token_value2 => lt_subinventory_name                       -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_param8                              -- �g�[�N���R�[�h3
                      , iv_token_value3 => gv_kbn                                     -- �g�[�N���l3
                      , iv_token_name4  => cv_tkn_param_name8                         -- �g�[�N���R�[�h4
                      , iv_token_value4 => gt_xxcoi016a06_kbn                         -- �g�[�N���l4
                    );
    END IF;
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg2
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => lv_errmsg2
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => ''
    );
--
    --==============================================================
    -- 18�D�]�ƈ����擾
    --==============================================================
    -- �����̏ꍇ
    IF ( gv_kbn = cv_kbn_1 ) THEN
      BEGIN
        SELECT papf.employee_number                                         AS employee_number
             , papf.per_information18 || cv_space || papf.per_information19 AS employee_name
        INTO   gt_employee_number
             , gv_employee_name
        FROM   fnd_user         fu
             , per_all_people_f papf
        WHERE  fu.employee_id             = papf.person_id
        AND    papf.effective_start_date <= gd_process_date
        AND    papf.effective_end_date   >= gd_process_date
        AND    fu.user_id                 = cn_created_by
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �]�ƈ��}�X�^�擾�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application => cv_application
                         , iv_name        => cv_msg_xxcoi_10130
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N���䏈��(A-2)
   ***********************************************************************************/
  PROCEDURE get_lock(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_dummy                NUMBER DEFAULT 0; -- �_�~�[�l
    ln_cnt                  NUMBER DEFAULT 0; -- ����
    -- ���b�N�ΏەۊǏꏊ�i�[��`
    TYPE l_subinventory_code_ttype IS TABLE OF mtl_secondary_inventories.secondary_inventory_name%TYPE INDEX BY PLS_INTEGER;
    -- ���b�N�ΏەۊǏꏊ�i�[�z��
    l_subinventory_code_tab l_subinventory_code_ttype;
    -- ���b�g�ʈ������b�N����e�[�u���o�^�p�i�[�z��
    l_ins_lock_control_tab  l_subinventory_code_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D���b�N�Ώ۔���
    --==============================================================
    -- �ۊǏꏊ�w�肠��
    IF ( gv_subinventory_code IS NOT NULL ) THEN
      l_subinventory_code_tab(1) := gv_subinventory_code;
    -- �ۊǏꏊ�w��Ȃ�
    ELSE
      SELECT msi.secondary_inventory_name AS secondary_inventory_name
      BULK COLLECT INTO l_subinventory_code_tab
      FROM   mtl_secondary_inventories    msi
      WHERE  msi.attribute14     = cv_flag_y
      AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
      AND    msi.organization_id = gt_organization_id
      AND    msi.attribute7      = gv_login_base_code
      ;
      -- �ۊǏꏊ���擾�ł��Ȃ��ꍇ
      IF ( l_subinventory_code_tab.COUNT = 0 ) THEN
        -- ���b�N�ΏەۊǏꏊ���݃G���[���b�Z�[�W�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10541
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => gv_login_base_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 2�D���b�g�ʈ������b�N����e�[�u���`�F�b�N
    --==============================================================
    -- ���݃`�F�b�N���[�v
    << ins_chk_loop >>
    FOR i IN 1 .. l_subinventory_code_tab.COUNT LOOP
      BEGIN
        SELECT 1
        INTO   ln_dummy
        FROM   xxcoi_lot_lock_control xllc
        WHERE  xllc.organization_id   = gt_organization_id
        AND    xllc.base_code         = gv_login_base_code
        AND    xllc.subinventory_code = l_subinventory_code_tab(i)
        ;
      EXCEPTION
        -- �擾�ł��Ȃ��ۊǏꏊ�̂݁A�V�K�o�^���邽�ߕێ�
        WHEN NO_DATA_FOUND THEN
          ln_cnt                         := ln_cnt + 1;
          l_ins_lock_control_tab(ln_cnt) := l_subinventory_code_tab(i);
      END;
    END LOOP ins_chk_loop;
--
    --==============================================================
    -- 3�D���b�g�ʈ������b�N����e�[�u���o�^
    --==============================================================
    -- �o�^���������݂���ꍇ
    IF ( ln_cnt > 0 ) THEN
      -- �o�^���[�v
      << ins_target_loop >>
      FOR i IN 1 .. l_ins_lock_control_tab.COUNT LOOP
        BEGIN
          INSERT INTO xxcoi_lot_lock_control(
              lot_lock_control_id                -- ���b�g�ʈ������b�N����ID
            , organization_id                    -- �݌ɑg�DID
            , base_code                          -- ���_�R�[�h
            , subinventory_code                  -- �ۊǏꏊ�R�[�h
            , created_by                         -- �쐬��
            , creation_date                      -- �쐬��
            , last_updated_by                    -- �ŏI�X�V��
            , last_update_date                   -- �ŏI�X�V��
            , last_update_login                  -- �ŏI�X�V���O�C��
            , request_id                         -- �v��ID
            , program_application_id             -- �v���O�����A�v���P�[�V����ID
            , program_id                         -- �v���O����ID
            , program_update_date                -- �v���O�����X�V��
          ) VALUES (
              xxcoi_lot_lock_control_s01.NEXTVAL -- ���b�g�ʈ������b�N����ID
            , gt_organization_id                 -- �݌ɑg�DID
            , gv_login_base_code                 -- ���_�R�[�h
            , l_ins_lock_control_tab(i)          -- �ۊǏꏊ�R�[�h
            , cn_created_by                      -- �쐬��
            , cd_creation_date                   -- �쐬��
            , cn_last_updated_by                 -- �ŏI�X�V��
            , cd_last_update_date                -- �ŏI�X�V��
            , cn_last_update_login               -- �ŏI�X�V���O�C��
            , cn_request_id                      -- �v��ID
            , cn_program_application_id          -- �v���O�����A�v���P�[�V����ID
            , cn_program_id                      -- �v���O����ID
            , cd_program_update_date             -- �v���O�����X�V��
          );
        EXCEPTION
          -- ��Ӑ���ᔽ
          WHEN DUP_VAL_ON_INDEX THEN
            -- �ۊǏꏊ�w�肠��
            IF ( gv_subinventory_code IS NOT NULL ) THEN
              -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w�肠��j���b�N�G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application
                             , iv_name         => cv_msg_xxcoi_10542
                             , iv_token_name1  => cv_tkn_subinventory_code
                             , iv_token_value1 => gv_subinventory_code
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            -- �ۊǏꏊ�w��Ȃ�
            ELSE
              -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application
                             , iv_name         => cv_msg_xxcoi_10543
                             , iv_token_name1  => cv_tkn_base_code
                             , iv_token_value1 => gv_login_base_code
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            END IF;
        END;
      END LOOP ins_target_loop;
      --
      -- �S���o�^���COMMIT
      COMMIT;
      --
    END IF;
--
    --==============================================================
    -- 4�D���b�g�ʈ������b�N����e�[�u�����b�N�擾
    --==============================================================
    -- ���b�N���[�v
    -- �o�^�����f�[�^���܂߂đS�����b�N�擾
    << lock_loop >>
    FOR i IN 1 .. l_subinventory_code_tab.COUNT LOOP
      BEGIN
        -- ���b�N�擾
        SELECT 1
        INTO   ln_dummy
        FROM   xxcoi_lot_lock_control xllc
        WHERE  xllc.organization_id   = gt_organization_id
        AND    xllc.base_code         = gv_login_base_code
        AND    xllc.subinventory_code = l_subinventory_code_tab(i)
        FOR UPDATE NOWAIT
        ;
        -- ���b�g�ʈ����ۊǏꏊ�ꎞ�\�o�^
        INSERT INTO xxcoi_tmp_lot_reserve_subinv(
          subinventory_code -- �ۊǏꏊ�R�[�h
        ) VALUES (
          l_subinventory_code_tab(i)
        );
      EXCEPTION
        -- ���b�N�擾�Ɏ��s
        WHEN global_lock_expt THEN
          -- �ۊǏꏊ�w�肠��
          IF ( gv_subinventory_code IS NOT NULL ) THEN
            -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w�肠��j���b�N�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10542
                           , iv_token_name1  => cv_tkn_subinventory_code
                           , iv_token_value1 => gv_subinventory_code
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          -- �ۊǏꏊ�w��Ȃ�
          ELSE
            -- ���b�g�ʏo�׏��쐬�i�ۊǏꏊ�w��Ȃ��j���b�N�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10543
                           , iv_token_name1  => cv_tkn_base_code
                           , iv_token_value1 => gv_login_base_code
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
      END;
    END LOOP lock_loop;
    -- �f�o�b�O�p
    SELECT COUNT(1)
    INTO   gn_debug_cnt
    FROM   xxcoi_tmp_lot_reserve_subinv
    ;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-2.4 ���b�g�ʈ����ۊǏꏊ�ꎞ�\�o�^�����F' || gn_debug_cnt
    );
--
  EXCEPTION
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
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_data
   * Description      : �����Ώۃf�[�^�擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_reserve_data(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_reserve_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_cnt                     NUMBER                                                       DEFAULT NULL; -- �_�~�[�l
    lt_sale_class              xxcoi_tmp_lot_reserve_info.regular_sale_class_line%TYPE      DEFAULT NULL; -- ��ԓ����敪(����)
    lt_sale_class_name         xxcoi_tmp_lot_reserve_info.regular_sale_class_name_line%TYPE DEFAULT NULL; -- ��ԓ����敪��(����)
    lt_delivery_order_edi      xxcoi_tmp_lot_reserve_info.delivery_order_edi%TYPE           DEFAULT NULL; -- �z����(EDI)
-- Add Ver1.3 Start
    ln_cursor_no               NUMBER                                                       DEFAULT NULL; -- �J�[�\������
-- Add Ver1.3 End
--
    -- *** ���[�J���J�[�\�� ***
    -- �����Ώۃf�[�^�擾�J�[�\��
    CURSOR l_kbn_1_cur
    IS
      SELECT /*+ LEADING(ooha oola) */
             ooha.header_id                                AS header_id                 -- �󒍃w�b�_ID
           , ottt1.name                                    AS header_name               -- �󒍃^�C�v����
           , ooha.cust_po_number                           AS slip_num                  -- �`�[No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- �󒍔ԍ�
           , ooha.order_source_id                          AS order_source_id           -- �󒍃\�[�XID
           , xca2.chain_store_code                         AS chain_code                -- �`�F�[���X�R�[�h
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- �`�F�[���X��
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
           , xca1.store_code                               AS shop_code                 -- �X�܃R�[�h
           , xca1.cust_store_name                          AS shop_name                 -- �X�ܖ�
           , hca1.cust_account_id                          AS cust_account_id           -- �ڋqID
           , hca1.account_number                           AS customer_code             -- �ڋq�R�[�h
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- �ڋq��
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
           , xca1.deli_center_code                         AS center_code               -- �Z���^�[�R�[�h
           , xca1.deli_center_name                         AS center_name               -- �Z���^�[��
           , xca1.edi_district_code                        AS area_code                 -- �n��R�[�h
           , xca1.edi_district_name                        AS area_name                 -- �n�於
           , oola.line_id                                  AS line_id                   -- �󒍖���ID
           , oola.line_number                              AS line_number               -- �󒍖��הԍ�
           , oola.inventory_item_id                        AS parent_item_id            -- �e�i��ID
           , iimb.item_no                                  AS parent_item_code          -- �e�i�ڃR�[�h
           , ximb.item_short_name                          AS parent_item_name          -- �e�i�ږ�
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- ����敪
           , oola.attribute6                               AS item_code                 -- �q�i�ڃR�[�h
           , oola.ordered_quantity                         AS ordered_quantity          -- �󒍐���
           , oola.order_quantity_uom                       AS order_quantity_uom        -- �󒍒P��
           , oola.schedule_ship_date                       AS schedule_ship_date        -- �o�ד�
           , TRUNC(oola.request_date)                      AS arrival_date              -- ����
           , oola.subinventory                             AS whse_code                 -- �ۊǏꏊ�R�[�h
           , msi.description                               AS whse_name                 -- �ۊǏꏊ��
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- �O���V�X�e���󒍖��הԍ�
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- �z�����i���A���A���j
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- �z�����i�΁A�؁A�y�j
           , ottt2.name                                    AS line_name                 -- ���׃^�C�v
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code           = cv_booked
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                  > gt_max_header_id
-- Add Ver1.1 Start
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
-- Add Ver1.1 End
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( hca1.account_number            = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( ooha.cust_po_number            = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
    ;
-- Add Ver1.3 Start
    -- �����Ώۃf�[�^�擾�J�[�\��2
    CURSOR l_kbn_11_cur
    IS
      SELECT /*+ LEADING(xca1) */
             ooha.header_id                                AS header_id                 -- �󒍃w�b�_ID
           , ottt1.name                                    AS header_name               -- �󒍃^�C�v����
           , ooha.cust_po_number                           AS slip_num                  -- �`�[No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- �󒍔ԍ�
           , ooha.order_source_id                          AS order_source_id           -- �󒍃\�[�XID
           , xca2.chain_store_code                         AS chain_code                -- �`�F�[���X�R�[�h
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- �`�F�[���X��
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
           , xca1.store_code                               AS shop_code                 -- �X�܃R�[�h
           , xca1.cust_store_name                          AS shop_name                 -- �X�ܖ�
           , hca1.cust_account_id                          AS cust_account_id           -- �ڋqID
           , hca1.account_number                           AS customer_code             -- �ڋq�R�[�h
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- �ڋq��
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
           , xca1.deli_center_code                         AS center_code               -- �Z���^�[�R�[�h
           , xca1.deli_center_name                         AS center_name               -- �Z���^�[��
           , xca1.edi_district_code                        AS area_code                 -- �n��R�[�h
           , xca1.edi_district_name                        AS area_name                 -- �n�於
           , oola.line_id                                  AS line_id                   -- �󒍖���ID
           , oola.line_number                              AS line_number               -- �󒍖��הԍ�
           , oola.inventory_item_id                        AS parent_item_id            -- �e�i��ID
           , iimb.item_no                                  AS parent_item_code          -- �e�i�ڃR�[�h
           , ximb.item_short_name                          AS parent_item_name          -- �e�i�ږ�
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- ����敪
           , oola.attribute6                               AS item_code                 -- �q�i�ڃR�[�h
           , oola.ordered_quantity                         AS ordered_quantity          -- �󒍐���
           , oola.order_quantity_uom                       AS order_quantity_uom        -- �󒍒P��
           , oola.schedule_ship_date                       AS schedule_ship_date        -- �o�ד�
           , TRUNC(oola.request_date)                      AS arrival_date              -- ����
           , oola.subinventory                             AS whse_code                 -- �ۊǏꏊ�R�[�h
           , msi.description                               AS whse_name                 -- �ۊǏꏊ��
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- �O���V�X�e���󒍖��הԍ�
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- �z�����i���A���A���j
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- �z�����i�΁A�؁A�y�j
           , ottt2.name                                    AS line_name                 -- ���׃^�C�v
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code           = cv_booked
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                  > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND    xca1.chain_store_code           = gv_login_chain_store_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
    ;
    -- �����Ώۃf�[�^�擾�J�[�\��3
    CURSOR l_kbn_12_cur
    IS
      SELECT /*+ LEADING(hca1) */
             ooha.header_id                                AS header_id                 -- �󒍃w�b�_ID
           , ottt1.name                                    AS header_name               -- �󒍃^�C�v����
           , ooha.cust_po_number                           AS slip_num                  -- �`�[No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- �󒍔ԍ�
           , ooha.order_source_id                          AS order_source_id           -- �󒍃\�[�XID
           , xca2.chain_store_code                         AS chain_code                -- �`�F�[���X�R�[�h
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- �`�F�[���X��
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
           , xca1.store_code                               AS shop_code                 -- �X�܃R�[�h
           , xca1.cust_store_name                          AS shop_name                 -- �X�ܖ�
           , hca1.cust_account_id                          AS cust_account_id           -- �ڋqID
           , hca1.account_number                           AS customer_code             -- �ڋq�R�[�h
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- �ڋq��
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
           , xca1.deli_center_code                         AS center_code               -- �Z���^�[�R�[�h
           , xca1.deli_center_name                         AS center_name               -- �Z���^�[��
           , xca1.edi_district_code                        AS area_code                 -- �n��R�[�h
           , xca1.edi_district_name                        AS area_name                 -- �n�於
           , oola.line_id                                  AS line_id                   -- �󒍖���ID
           , oola.line_number                              AS line_number               -- �󒍖��הԍ�
           , oola.inventory_item_id                        AS parent_item_id            -- �e�i��ID
           , iimb.item_no                                  AS parent_item_code          -- �e�i�ڃR�[�h
           , ximb.item_short_name                          AS parent_item_name          -- �e�i�ږ�
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- ����敪
           , oola.attribute6                               AS item_code                 -- �q�i�ڃR�[�h
           , oola.ordered_quantity                         AS ordered_quantity          -- �󒍐���
           , oola.order_quantity_uom                       AS order_quantity_uom        -- �󒍒P��
           , oola.schedule_ship_date                       AS schedule_ship_date        -- �o�ד�
           , TRUNC(oola.request_date)                      AS arrival_date              -- ����
           , oola.subinventory                             AS whse_code                 -- �ۊǏꏊ�R�[�h
           , msi.description                               AS whse_name                 -- �ۊǏꏊ��
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- �O���V�X�e���󒍖��הԍ�
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- �z�����i���A���A���j
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- �z�����i�΁A�؁A�y�j
           , ottt2.name                                    AS line_name                 -- ���׃^�C�v
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code           = cv_booked
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                  > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND    hca1.account_number             = gv_login_customer_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
    ;
-- Add Ver1.3 End
    -- EDI���擾�J�[�\��
    CURSOR l_edi_cur( iv_order_number      VARCHAR2
                    , iv_order_line_number VARCHAR2 )
    IS
      SELECT xeh.edi_received_date AS edi_received_date
           , xeh.ar_sale_class     AS ar_sale_class
      FROM   xxcos_edi_headers     xeh
           , xxcos_edi_lines       xel
      WHERE  xel.edi_header_info_id           = xeh.edi_header_info_id
      AND    xeh.order_connection_number      = iv_order_number
      AND    xel.order_connection_line_number = iv_order_line_number
    ;
    l_edi_rec               l_edi_cur%ROWTYPE;
-- Add Ver1.3 Start
    l_kbn_1_rec             l_kbn_1_cur%ROWTYPE;
-- Add Ver1.3 End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D�����Ώۃf�[�^�擾
    --==============================================================
-- Mod Ver1.3 End
--    -- �������[�v
--    << kbn_1_loop >>
--    FOR l_kbn_1_rec IN l_kbn_1_cur LOOP
    -- �ڋq�����ԍ����w�肳�ꂽ�ꍇ
    -- �܂��̓`�F�[���X�R�[�h�ƌڋq�R�[�h���Ƃ��Ɏw�肳��Ă��Ȃ��ꍇ
    IF ( ( gv_customer_po_number IS NOT NULL )
      OR ( gv_login_chain_store_code IS NULL ) AND ( gv_login_customer_code IS NULL ) ) THEN
       ln_cursor_no := 1;
       OPEN l_kbn_1_cur;
    ELSE
      -- �ڋq���w�肳��Ă��Ȃ��ꍇ
      IF ( gv_login_customer_code IS NULL ) THEN
        ln_cursor_no := 2;
        OPEN l_kbn_11_cur;
      -- �ڋq���w�肳��Ă���ꍇ
      ELSE
        ln_cursor_no := 3;
        OPEN l_kbn_12_cur;
      END IF;
    END IF;
    --
    -- �������[�v
    << kbn_1_loop >>
    LOOP
    -- �ڋq�����ԍ����w�肳�ꂽ�ꍇ
    -- �܂��̓`�F�[���X�R�[�h�ƌڋq�R�[�h���Ƃ��Ɏw�肳��Ă��Ȃ��ꍇ
    IF ( ln_cursor_no = 1 ) THEN
      FETCH l_kbn_1_cur INTO l_kbn_1_rec;
      EXIT WHEN l_kbn_1_cur%NOTFOUND;
    ELSE
      -- �ڋq���w�肳��Ă��Ȃ��ꍇ
      IF ( ln_cursor_no = 2 ) THEN
        FETCH l_kbn_11_cur INTO l_kbn_1_rec;
        EXIT WHEN l_kbn_11_cur%NOTFOUND;
      -- �ڋq���w�肳��Ă���ꍇ
      ELSE
        FETCH l_kbn_12_cur INTO l_kbn_1_rec;
        EXIT WHEN l_kbn_12_cur%NOTFOUND;
      END IF;
    END IF;
-- Mod Ver1.3 End
      -- ������
      lt_sale_class                        := NULL;
      lt_sale_class_name                   := NULL;
      lt_delivery_order_edi                := NULL;
      --
      --==============================================================
      -- 2,3,4�DEDI���擾�A��ԓ����敪�ݒ�A�����O�󒍐��ʎ擾�A�z����(EDI)�擾
      --==============================================================
      -- EDI�󒍂̏ꍇ
      IF ( l_kbn_1_rec.order_source_id = gt_order_source_id ) THEN
        OPEN l_edi_cur( iv_order_number      => l_kbn_1_rec.orig_sys_document_ref
                      , iv_order_line_number => l_kbn_1_rec.orig_sys_line_ref );
        FETCH l_edi_cur INTO l_edi_rec;
        CLOSE l_edi_cur;
        -- ��ԓ����敪(����)�ϐ��ݒ�
        lt_sale_class := l_edi_rec.ar_sale_class;
        -- ��ԓ����敪��(����)�ϐ��ݒ�
        IF ( l_edi_rec.ar_sale_class IN ( cv_teiban, cv_sale_class_1 ) ) THEN
          lt_sale_class      := cv_teiban;
          lt_sale_class_name := gt_teiban_name;
        ELSIF ( l_edi_rec.ar_sale_class IN ( cv_tokubai, cv_sale_class_2 ) ) THEN
          lt_sale_class      := cv_tokubai;
          lt_sale_class_name := gt_tokubai_name;
        ELSE
          lt_sale_class      := NULL;
          lt_sale_class_name := NULL;
        END IF;
      END IF;
      --
      -- EDI�󒍈ȊO�܂���EDI�󒍂�NULL�̏ꍇ
      IF ( ( l_kbn_1_rec.order_source_id <> gt_order_source_id )
        OR ( ( l_kbn_1_rec.order_source_id = gt_order_source_id ) AND ( lt_sale_class IS NULL ) ) ) THEN
        -- ��ԓ����敪(����)�ϐ��ݒ�
        lt_sale_class := l_kbn_1_rec.sale_class;
        -- ��ԓ����敪��(����)�ϐ��ݒ�
        IF ( l_kbn_1_rec.sale_class = cv_sale_class_1 ) THEN
          lt_sale_class      := cv_teiban;
          lt_sale_class_name := gt_teiban_name;
        ELSIF ( l_kbn_1_rec.sale_class = cv_sale_class_2 ) THEN
          lt_sale_class      := cv_tokubai;
          lt_sale_class_name := gt_tokubai_name;
        ELSE
          lt_sale_class_name := NULL;
        END IF;
      END IF;
      --
      -- �z����(EDI)�ϐ��ݒ�
      IF ( TO_CHAR(l_kbn_1_rec.arrival_date, cv_weekno) IN ( cv_weekno_monday, cv_weekno_wednesday, cv_weekno_friday ) ) THEN
        lt_delivery_order_edi := l_kbn_1_rec.delivery_order1;
      ELSIF ( TO_CHAR(l_kbn_1_rec.arrival_date, cv_weekno) IN ( cv_weekno_tuesday, cv_weekno_thursday, cv_weekno_saturday ) ) THEN
        lt_delivery_order_edi := l_kbn_1_rec.delivery_order2;
      ELSE
        lt_delivery_order_edi := NULL;
      END IF;
      --
      --
      --==============================================================
      -- 5�D���b�g�ʈ������ꎞ�\�o�^�X�V
      --==============================================================
      INSERT INTO xxcoi_tmp_lot_reserve_info(
          slip_num                              -- �`�[No
        , order_number                          -- �󒍔ԍ�
        , whse_code                             -- �ۊǏꏊ�R�[�h
        , whse_name                             -- �ۊǏꏊ��
        , chain_code                            -- �`�F�[���X�R�[�h
        , chain_name                            -- �`�F�[���X��
        , cust_fresh_con_code_chain             -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
        , shop_code                             -- �X�܃R�[�h
        , shop_name                             -- �X�ܖ�
        , customer_code                         -- �ڋq�R�[�h
        , customer_name                         -- �ڋq��
        , cust_fresh_con_code_cust              -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
        , center_code                           -- �Z���^�[�R�[�h
        , center_name                           -- �Z���^�[��
        , area_code                             -- �n��R�[�h
        , area_name                             -- �n�於
        , shipped_date                          -- �o�ד�
        , arrival_date                          -- ����
        , parent_item_id                        -- �e�i��ID
        , parent_item_code                      -- �e�i�ڃR�[�h
        , parent_item_name                      -- �e�i�ږ���
        , item_code                             -- �q�i�ڃR�[�h
        , regular_sale_class_line               -- ��ԓ����敪(����)
        , regular_sale_class_name_line          -- ��ԓ����敪��(����)
        , edi_received_date                     -- EDI��M��
        , delivery_order_edi                    -- �z����(EDI)
        , before_ordered_quantity               -- �����O�󒍐���
        , header_id                             -- �󒍃w�b�_ID
        , line_id                               -- �󒍖���ID
        , line_number                           -- �󒍖��הԍ�
        , line_type                             -- ���׃^�C�v
        , customer_id                           -- �ڋqID
        , ordered_quantity                      -- �󒍐�
        , order_quantity_uom                    -- �󒍒P��
      ) VALUES (
          l_kbn_1_rec.slip_num                  -- �`�[No
        , l_kbn_1_rec.order_number              -- �󒍔ԍ�
        , l_kbn_1_rec.whse_code                 -- �ۊǏꏊ�R�[�h
        , l_kbn_1_rec.whse_name                 -- �ۊǏꏊ��
        , l_kbn_1_rec.chain_code                -- �`�F�[���X�R�[�h
        , l_kbn_1_rec.chain_name                -- �`�F�[���X��
        , l_kbn_1_rec.cust_fresh_con_code_chain -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
        , l_kbn_1_rec.shop_code                 -- �X�܃R�[�h
        , l_kbn_1_rec.shop_name                 -- �X�ܖ�
        , l_kbn_1_rec.customer_code             -- �ڋq�R�[�h
        , l_kbn_1_rec.customer_name             -- �ڋq��
        , l_kbn_1_rec.cust_fresh_con_code_cust  -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
        , l_kbn_1_rec.center_code               -- �Z���^�[�R�[�h
        , l_kbn_1_rec.center_name               -- �Z���^�[��
        , l_kbn_1_rec.area_code                 -- �n��R�[�h
        , l_kbn_1_rec.area_name                 -- �n�於
        , l_kbn_1_rec.schedule_ship_date        -- �o�ד�
        , l_kbn_1_rec.arrival_date              -- ����
        , l_kbn_1_rec.parent_item_id            -- �e�i��ID
        , l_kbn_1_rec.parent_item_code          -- �e�i�ڃR�[�h
        , l_kbn_1_rec.parent_item_name          -- �e�i�ږ���
        , l_kbn_1_rec.item_code                 -- �q�i�ڃR�[�h
        , lt_sale_class                         -- ��ԓ����敪(����)
        , lt_sale_class_name                    -- ��ԓ����敪��(����)
        , l_edi_rec.edi_received_date           -- EDI��M��
        , lt_delivery_order_edi                 -- �z����(EDI)
        , NULL                                  -- �����O�󒍐���
        , l_kbn_1_rec.header_id                 -- �󒍃w�b�_ID
        , l_kbn_1_rec.line_id                   -- �󒍖���ID
        , l_kbn_1_rec.line_number               -- �󒍖��הԍ�
        , l_kbn_1_rec.line_name                 -- ���׃^�C�v
        , l_kbn_1_rec.cust_account_id           -- �ڋqID
        , l_kbn_1_rec.ordered_quantity          -- �󒍐�
        , l_kbn_1_rec.order_quantity_uom        -- �󒍒P��
      );
    END LOOP kbn_1_loop;
--
  EXCEPTION
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
      IF ( l_kbn_1_cur%ISOPEN ) THEN
        CLOSE l_kbn_1_cur;
-- Add Ver1.3 Start
      ELSIF ( l_kbn_11_cur%ISOPEN ) THEN
        CLOSE l_kbn_11_cur;
      ELSIF ( l_kbn_12_cur%ISOPEN ) THEN
        CLOSE l_kbn_12_cur;
-- Add Ver1.3 End
      END IF;
      IF ( l_edi_cur%ISOPEN ) THEN
        CLOSE l_edi_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_reserve_data;
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_other_data
   * Description      : �����ȊO�f�[�^�擾����(A-17)
   ***********************************************************************************/
  PROCEDURE get_reserve_other_data(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_reserve_other_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_lot_tran_cnt            NUMBER      DEFAULT 0;    -- ���b�g�ʎ�����׌���
    lv_tran_kbn                VARCHAR2(1) DEFAULT NULL; -- ����敪
-- Add Ver1.3 Start
    ln_cursor_no               NUMBER      DEFAULT NULL; -- �J�[�\������
-- Add Ver1.3 End
--
    -- *** ���[�J���J�[�\�� ***
    -- �����ȊO�f�[�^�擾�J�[�\��
    CURSOR l_kbn_4_cur
    IS
      SELECT /*+ LEADING(ooha oola) */
             ooha.header_id                                AS header_id                 -- �󒍃w�b�_ID
           , ottt1.name                                    AS header_name               -- �󒍃^�C�v����
           , ooha.cust_po_number                           AS slip_num                  -- �`�[No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- �󒍔ԍ�
           , ooha.order_source_id                          AS order_source_id           -- �󒍃\�[�XID
           , xca2.chain_store_code                         AS chain_code                -- �`�F�[���X�R�[�h
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- �`�F�[���X��
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
           , xca1.store_code                               AS shop_code                 -- �X�܃R�[�h
           , xca1.cust_store_name                          AS shop_name                 -- �X�ܖ�
           , hca1.cust_account_id                          AS cust_account_id           -- �ڋqID
           , hca1.account_number                           AS customer_code             -- �ڋq�R�[�h
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- �ڋq��
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
           , xca1.deli_center_code                         AS center_code               -- �Z���^�[�R�[�h
           , xca1.deli_center_name                         AS center_name               -- �Z���^�[��
           , xca1.edi_district_code                        AS area_code                 -- �n��R�[�h
           , xca1.edi_district_name                        AS area_name                 -- �n�於
           , oola.line_id                                  AS line_id                   -- �󒍖���ID
           , oola.line_number                              AS line_number               -- �󒍖��הԍ�
           , oola.inventory_item_id                        AS parent_item_id            -- �e�i��ID
           , iimb.item_no                                  AS parent_item_code          -- �e�i�ڃR�[�h
           , ximb.item_short_name                          AS parent_item_name          -- �e�i�ږ�
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- ����敪
           , oola.attribute6                               AS item_code                 -- �q�i�ڃR�[�h
           , oola.ordered_quantity                         AS ordered_quantity          -- �󒍐���
           , oola.order_quantity_uom                       AS order_quantity_uom        -- �󒍒P��
           , oola.schedule_ship_date                       AS schedule_ship_date        -- �o�ד�
           , TRUNC(oola.request_date)                      AS arrival_date              -- ����
           , msi.attribute7                                AS base_code                 -- ���_�R�[�h
           , oola.subinventory                             AS whse_code                 -- �ۊǏꏊ�R�[�h
           , msi.description                               AS whse_name                 -- �ۊǏꏊ��
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- �O���V�X�e���󒍖��הԍ�
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- �z�����i���A���A���j
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- �z�����i�΁A�؁A�y�j
           , ottt2.name                                    AS line_name                 -- ���׃^�C�v
           , oola.flow_status_code                         AS flow_status_code          -- ���׃X�e�[�^�X
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code          <> cv_entered
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                 > gt_max_header_id
-- Add Ver1.1 Start
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
-- Add Ver1.1 End
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( hca1.account_number            = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( ooha.cust_po_number            = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
      ORDER BY ooha.order_number
             , oola.line_number
    ;
-- Add Ver1.3 Start
    -- �����ȊO�f�[�^�擾�J�[�\��2
    CURSOR l_kbn_41_cur
    IS
      SELECT /*+ LEADING(xca1) */
             ooha.header_id                                AS header_id                 -- �󒍃w�b�_ID
           , ottt1.name                                    AS header_name               -- �󒍃^�C�v����
           , ooha.cust_po_number                           AS slip_num                  -- �`�[No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- �󒍔ԍ�
           , ooha.order_source_id                          AS order_source_id           -- �󒍃\�[�XID
           , xca2.chain_store_code                         AS chain_code                -- �`�F�[���X�R�[�h
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- �`�F�[���X��
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
           , xca1.store_code                               AS shop_code                 -- �X�܃R�[�h
           , xca1.cust_store_name                          AS shop_name                 -- �X�ܖ�
           , hca1.cust_account_id                          AS cust_account_id           -- �ڋqID
           , hca1.account_number                           AS customer_code             -- �ڋq�R�[�h
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- �ڋq��
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
           , xca1.deli_center_code                         AS center_code               -- �Z���^�[�R�[�h
           , xca1.deli_center_name                         AS center_name               -- �Z���^�[��
           , xca1.edi_district_code                        AS area_code                 -- �n��R�[�h
           , xca1.edi_district_name                        AS area_name                 -- �n�於
           , oola.line_id                                  AS line_id                   -- �󒍖���ID
           , oola.line_number                              AS line_number               -- �󒍖��הԍ�
           , oola.inventory_item_id                        AS parent_item_id            -- �e�i��ID
           , iimb.item_no                                  AS parent_item_code          -- �e�i�ڃR�[�h
           , ximb.item_short_name                          AS parent_item_name          -- �e�i�ږ�
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- ����敪
           , oola.attribute6                               AS item_code                 -- �q�i�ڃR�[�h
           , oola.ordered_quantity                         AS ordered_quantity          -- �󒍐���
           , oola.order_quantity_uom                       AS order_quantity_uom        -- �󒍒P��
           , oola.schedule_ship_date                       AS schedule_ship_date        -- �o�ד�
           , TRUNC(oola.request_date)                      AS arrival_date              -- ����
           , msi.attribute7                                AS base_code                 -- ���_�R�[�h
           , oola.subinventory                             AS whse_code                 -- �ۊǏꏊ�R�[�h
           , msi.description                               AS whse_name                 -- �ۊǏꏊ��
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- �O���V�X�e���󒍖��הԍ�
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- �z�����i���A���A���j
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- �z�����i�΁A�؁A�y�j
           , ottt2.name                                    AS line_name                 -- ���׃^�C�v
           , oola.flow_status_code                         AS flow_status_code          -- ���׃X�e�[�^�X
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code          <> cv_entered
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                 > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND    xca1.chain_store_code          = gv_login_chain_store_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
      ORDER BY ooha.order_number
             , oola.line_number
    ;
    -- �����ȊO�f�[�^�擾�J�[�\��2
    CURSOR l_kbn_42_cur
    IS
      SELECT /*+ LEADING(hca1) */
             ooha.header_id                                AS header_id                 -- �󒍃w�b�_ID
           , ottt1.name                                    AS header_name               -- �󒍃^�C�v����
           , ooha.cust_po_number                           AS slip_num                  -- �`�[No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- �󒍔ԍ�
           , ooha.order_source_id                          AS order_source_id           -- �󒍃\�[�XID
           , xca2.chain_store_code                         AS chain_code                -- �`�F�[���X�R�[�h
           , SUBSTRB(hp2.party_name, 1, 40)                AS chain_name                -- �`�F�[���X��
           , xca2.cust_fresh_con_code                      AS cust_fresh_con_code_chain -- �ڋq�ʑN�x�����R�[�h�i�`�F�[���X�j
           , xca1.store_code                               AS shop_code                 -- �X�܃R�[�h
           , xca1.cust_store_name                          AS shop_name                 -- �X�ܖ�
           , hca1.cust_account_id                          AS cust_account_id           -- �ڋqID
           , hca1.account_number                           AS customer_code             -- �ڋq�R�[�h
           , SUBSTRB(hp1.party_name, 1, 40)                AS customer_name             -- �ڋq��
           , xca1.cust_fresh_con_code                      AS cust_fresh_con_code_cust  -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j
           , xca1.deli_center_code                         AS center_code               -- �Z���^�[�R�[�h
           , xca1.deli_center_name                         AS center_name               -- �Z���^�[��
           , xca1.edi_district_code                        AS area_code                 -- �n��R�[�h
           , xca1.edi_district_name                        AS area_name                 -- �n�於
           , oola.line_id                                  AS line_id                   -- �󒍖���ID
           , oola.line_number                              AS line_number               -- �󒍖��הԍ�
           , oola.inventory_item_id                        AS parent_item_id            -- �e�i��ID
           , iimb.item_no                                  AS parent_item_code          -- �e�i�ڃR�[�h
           , ximb.item_short_name                          AS parent_item_name          -- �e�i�ږ�
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- ����敪
           , oola.attribute6                               AS item_code                 -- �q�i�ڃR�[�h
           , oola.ordered_quantity                         AS ordered_quantity          -- �󒍐���
           , oola.order_quantity_uom                       AS order_quantity_uom        -- �󒍒P��
           , oola.schedule_ship_date                       AS schedule_ship_date        -- �o�ד�
           , TRUNC(oola.request_date)                      AS arrival_date              -- ����
           , msi.attribute7                                AS base_code                 -- ���_�R�[�h
           , oola.subinventory                             AS whse_code                 -- �ۊǏꏊ�R�[�h
           , msi.description                               AS whse_name                 -- �ۊǏꏊ��
           , ooha.orig_sys_document_ref                    AS orig_sys_document_ref     -- �O���V�X�e���󒍔ԍ�
           , oola.orig_sys_line_ref                        AS orig_sys_line_ref         -- �O���V�X�e���󒍖��הԍ�
           , TRIM(SUBSTRB(xca1.delivery_order, 1, 7))      AS delivery_order1           -- �z�����i���A���A���j
           , TRIM(NVL(SUBSTRB(xca1.delivery_order, 8, 7)
                    , SUBSTRB(xca1.delivery_order, 1, 7))) AS delivery_order2           -- �z�����i�΁A�؁A�y�j
           , ottt2.name                                    AS line_name                 -- ���׃^�C�v
           , oola.flow_status_code                         AS flow_status_code          -- ���׃X�e�[�^�X
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND    oola.flow_status_code          <> cv_entered
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND NOT EXISTS ( SELECT 1
                       FROM   xxcoi_tmp_lot_reserve_na xtlrn
                       WHERE  xtlrn.header_id = ooha.header_id
                       AND    xtlrn.line_id   = oola.line_id )
      AND    ooha.header_id                 > gt_max_header_id
      AND    ooha.ordered_date              >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1)) - 1
      AND    ooha.ordered_date              <  gd_process_date + 1
      AND    oola.request_date              >= gd_delivery_date_from
      AND    oola.request_date              <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xca1.chain_store_code          = gv_login_chain_store_code ) )
      AND    hca1.account_number             = gv_login_customer_code
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = oola.subinventory )
      ORDER BY ooha.order_number
             , oola.line_number
    ;
    l_kbn_4_rec             l_kbn_4_cur%ROWTYPE;
-- Add Ver1.3 End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D�����ȊO�f�[�^�擾
    --==============================================================
-- Mod Ver1.3 End
--    -- �����ȊO���[�v
--    << kbn_4_loop >>
--    FOR l_kbn_4_rec IN l_kbn_4_cur LOOP
    -- �ڋq�����ԍ����w�肳�ꂽ�ꍇ
    -- �܂��̓`�F�[���X�R�[�h�ƌڋq�R�[�h���Ƃ��Ɏw�肳��Ă��Ȃ��ꍇ
    IF ( ( gv_customer_po_number IS NOT NULL )
      OR ( gv_login_chain_store_code IS NULL ) AND ( gv_login_customer_code IS NULL ) ) THEN
      ln_cursor_no := 1;
      OPEN l_kbn_4_cur;
    ELSE
      -- �ڋq���w�肳��Ă��Ȃ��ꍇ
      IF ( gv_login_customer_code IS NULL ) THEN
        ln_cursor_no := 2;
        OPEN l_kbn_41_cur;
      -- �ڋq���w�肳��Ă���ꍇ
      ELSE
        ln_cursor_no := 3;
        OPEN l_kbn_42_cur;
      END IF;
    END IF;
    --
    -- �����ȊO���[�v
    << kbn_4_loop >>
    LOOP
    -- �ڋq�����ԍ����w�肳�ꂽ�ꍇ
    -- �܂��̓`�F�[���X�R�[�h�ƌڋq�R�[�h���Ƃ��Ɏw�肳��Ă��Ȃ��ꍇ
    IF ( ln_cursor_no = 1 ) THEN
      FETCH l_kbn_4_cur INTO l_kbn_4_rec;
      EXIT WHEN l_kbn_4_cur%NOTFOUND;
    ELSE
      -- �ڋq���w�肳��Ă��Ȃ��ꍇ
      IF ( ln_cursor_no = 2 ) THEN
        FETCH l_kbn_41_cur INTO l_kbn_4_rec;
        EXIT WHEN l_kbn_41_cur%NOTFOUND;
      -- �ڋq���w�肳��Ă���ꍇ
      ELSE
        FETCH l_kbn_42_cur INTO l_kbn_4_rec;
        EXIT WHEN l_kbn_42_cur%NOTFOUND;
      END IF;
    END IF;
-- Mod Ver1.3 End
      -- ������
      ln_lot_tran_cnt := 0;
      lv_tran_kbn     := NULL;
      --==============================================================
      -- 2�D�󒍃^�C�v����
      --==============================================================
      -- 2-1�D�󒍃^�C�v���u�ԕi�v�u�ԕi�����v�̏ꍇ
      --      ���ԕi�A�ԕi�����A�S�ݓX�ԕi�A�S�ݓX�ԕi����
      << return_loop >>
      FOR i IN 1 .. gt_return_tab.COUNT LOOP
        IF ( l_kbn_4_rec.header_name = gt_return_tab(i) ) THEN
          lv_tran_kbn := cv_tran_kbn_2;
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => '�ԕi'        ||
                        ' �󒍔ԍ��F' || l_kbn_4_rec.order_number ||
                        ' ���הԍ��F' || l_kbn_4_rec.line_number
          );
          --
          EXIT return_loop;
        END IF;
      END LOOP return_loop;
      --
      -- 2-2�D�󒍃^�C�v���u�����v�̏ꍇ
      --      ���ʏ�����A���{�����A�L����`������A�S�ݓX�����A�S�ݓX���{����
      IF ( lv_tran_kbn IS NULL ) THEN
        << correct_loop >>
        FOR i IN 1 .. gt_correct_tab.COUNT LOOP
          IF ( l_kbn_4_rec.header_name = gt_correct_tab(i) ) THEN
            lv_tran_kbn := cv_tran_kbn_3;
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '����'        ||
                          ' �󒍔ԍ��F' || l_kbn_4_rec.order_number ||
                          ' ���הԍ��F' || l_kbn_4_rec.line_number
            );
            --
            EXIT correct_loop;
          END IF;
        END LOOP correct_loop;
      END IF;
      --
      -- 2-3�D�󒍂̏ꍇ
      --      ���ʏ�󒍁A���{�A�L����`��A�S�ݓX�󒍁A�S�ݓX���{
      IF ( ( lv_tran_kbn IS NULL ) AND ( l_kbn_4_rec.arrival_date < gd_process_date ) ) THEN
        lv_tran_kbn := cv_tran_kbn_1;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '��'        ||
                      ' �󒍔ԍ��F' || l_kbn_4_rec.order_number ||
                      ' ���הԍ��F' || l_kbn_4_rec.line_number
        );
      END IF;
      -- �o�^�Ώۂ̏ꍇ
      IF ( lv_tran_kbn IS NOT NULL ) THEN
        -- ���b�g�ʎ�����׌���
        SELECT COUNT(1)
        INTO   ln_lot_tran_cnt
        FROM   xxcoi_lot_transactions xlt
        WHERE  xlt.source_code  = cv_pkg_name
        AND    xlt.relation_key = l_kbn_4_rec.header_id || cv_under || l_kbn_4_rec.line_id
        ;
        -- ���b�g�ʎ�����ׂ����݂��Ȃ��ꍇ
        IF ( ln_lot_tran_cnt = 0 ) THEN
          -- ���b�g�ʎ��TEMP�o�^����
          ins_lot_tran_temp(
              iv_tran_kbn           => lv_tran_kbn                    -- ����敪
            , in_header_id          => l_kbn_4_rec.header_id          -- �󒍃w�b�_ID
            , in_line_id            => l_kbn_4_rec.line_id            -- �󒍖���ID
            , iv_slip_num           => l_kbn_4_rec.slip_num           -- �`�[No
            , iv_order_number       => l_kbn_4_rec.order_number       -- �󒍔ԍ�
            , iv_line_number        => l_kbn_4_rec.line_number        -- �󒍖��הԍ�
            , id_arrival_date       => l_kbn_4_rec.arrival_date       -- ����
            , iv_parent_item_code   => l_kbn_4_rec.parent_item_code   -- �e�i�ڃR�[�h
            , iv_item_code          => l_kbn_4_rec.item_code          -- �q�i�ڃR�[�h
            , in_parent_item_id     => l_kbn_4_rec.parent_item_id     -- �i��ID
            , iv_order_quantity_uom => l_kbn_4_rec.order_quantity_uom -- �󒍒P��
            , in_ordered_quantity   => l_kbn_4_rec.ordered_quantity   -- �󒍐���
            , iv_base_code          => l_kbn_4_rec.base_code          -- ���_�R�[�h
            , iv_subinventory_code  => l_kbn_4_rec.whse_code          -- �ۊǏꏊ�R�[�h
            , iv_line_name          => l_kbn_4_rec.line_name          -- ���דE�v
            , iv_sale_class         => l_kbn_4_rec.sale_class         -- ��ԓ����敪(����)
            , iv_flow_status_code   => l_kbn_4_rec.flow_status_code   -- ���׃X�e�[�^�X
            , ov_errbuf             => lv_errbuf                      -- �G���[�E���b�Z�[�W
            , ov_retcode            => lv_retcode                     -- ���^�[���E�R�[�h
            , ov_errmsg             => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSE
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => 'A-17 ���b�g�ʎ�����ב���' ||
                        ' �󒍔ԍ��F'               || l_kbn_4_rec.order_number ||
                        ' �󒍖��הԍ��F'           || l_kbn_4_rec.line_number
          );
        END IF;
      ELSE
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => '�o�^�ΏۊO'  ||
                      ' �󒍔ԍ��F' || l_kbn_4_rec.order_number ||
                      ' ���הԍ��F' || l_kbn_4_rec.line_number
        );
      END IF;
      --
    END LOOP kbn_4_loop;
--
  EXCEPTION
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
      IF ( l_kbn_4_cur%ISOPEN ) THEN
        CLOSE l_kbn_4_cur;
-- Add Ver1.3 Start
      ELSIF ( l_kbn_41_cur%ISOPEN ) THEN
        CLOSE l_kbn_41_cur;
      ELSIF ( l_kbn_42_cur%ISOPEN ) THEN
        CLOSE l_kbn_42_cur;
-- Add Ver1.3 End
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_reserve_other_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_reserve_data
   * Description      : �����Ώۃf�[�^�`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE chk_reserve_data(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- �������R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_reserve_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ld_last_deliver_lot_e   DATE DEFAULT NULL; -- �[�i���b�g_���Y
    ld_delivery_date_e      DATE DEFAULT NULL; -- �[�i��_���Y
    ld_last_deliver_lot_s   DATE DEFAULT NULL; -- �[�i���b�g_�c��
    ld_delivery_date_s      DATE DEFAULT NULL; -- �[�i��_�c��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D�ڋq�ʑN�x�����R�[�h�`�F�b�N
    --==============================================================
    IF (  ( it_kbn_1_rec.cust_fresh_con_code_chain IS NULL )
      AND ( it_kbn_1_rec.cust_fresh_con_code_cust IS NULL ) ) THEN
      -- �N�x�����́u00:��ʁv�ň�������
      gt_cust_fresh_con_code := cv_cust_fresh_con_code_00;
    ELSE
      -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j���ݒ肳��Ă���ꍇ�͌ڋq
      IF ( it_kbn_1_rec.cust_fresh_con_code_cust IS NOT NULL ) THEN
        gt_cust_fresh_con_code := it_kbn_1_rec.cust_fresh_con_code_cust;
      -- �ڋq�ʑN�x�����R�[�h�i�ڋq�j���ݒ肳��Ă��Ȃ��ꍇ�̓`�F�[���X
      ELSE
        gt_cust_fresh_con_code := it_kbn_1_rec.cust_fresh_con_code_chain;
      END IF;
    END IF;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-5 �ڋq�ʑN�x�����R�[�h�F' || gt_cust_fresh_con_code
    );
--
    --==============================================================
    -- 2�D���b�g���ێ��}�X�^�擾
    --==============================================================
    BEGIN
      SELECT TO_DATE(xmlhi.last_deliver_lot_e, cv_yyyymmdd) AS last_deliver_lot_e -- �[�i���b�g_�c��
           , xmlhi.delivery_date_e                          AS delivery_date_e    -- �[�i��_�c��
           , TO_DATE(xmlhi.last_deliver_lot_s, cv_yyyymmdd) AS last_deliver_lot_s -- �[�i���b�g_���Y
           , xmlhi.delivery_date_s                          AS delivery_date_s    -- �[�i��_���Y
      INTO   ld_last_deliver_lot_e
           , ld_delivery_date_e
           , ld_last_deliver_lot_s
           , ld_delivery_date_s
      FROM   xxcoi_mst_lot_hold_info  xmlhi
      WHERE  xmlhi.customer_id    = it_kbn_1_rec.customer_id
      AND    xmlhi.parent_item_id = it_kbn_1_rec.parent_item_id
      ;
      -- �ێ����t����F�[�i�����V��������ݒ肷��
      IF ( ( ld_delivery_date_s IS NULL )
        OR ( ld_delivery_date_e > ld_delivery_date_s )
        OR ( ld_delivery_date_e = ld_delivery_date_s ) AND ( ld_last_deliver_lot_e >= ld_last_deliver_lot_s ) ) THEN
        gd_last_deliver_lot := ld_last_deliver_lot_e;
        gd_delivery_date    := ld_delivery_date_e;
      ELSE
        gd_last_deliver_lot := ld_last_deliver_lot_s;
        gd_delivery_date    := ld_delivery_date_s;
      END IF;
      --
    EXCEPTION
      -- �擾�ł��Ȃ��ꍇ�i�V�K�̌ڋq��i�ځj�́A�㑱�Őݒ肷�邽��NULL�Ƃ��Ă���
      WHEN NO_DATA_FOUND THEN
        gd_last_deliver_lot := NULL;
        gd_delivery_date    := NULL;
    END;
--
  EXCEPTION
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
  END chk_reserve_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item
   * Description      : �q�i�ڏ��擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_item(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- �������R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    --
    lt_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- �i��ID
    lt_item_code               mtl_system_items_b.segment1%TYPE          DEFAULT NULL; -- �i�ڃR�[�h
    lt_after_uom_code          mtl_units_of_measure_tl.uom_code%TYPE     DEFAULT NULL; -- ���Z��P�ʃR�[�h
    ln_after_quantity          NUMBER                                    DEFAULT 0;    -- ���Z�㐔��
    ln_content                 NUMBER                                    DEFAULT 0;    -- ����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D�q�i�ڏ��擾
    --==============================================================
    xxcoi_common_pkg.get_parent_child_item_info(
        id_date           => it_kbn_1_rec.arrival_date   -- ���t
      , in_inv_org_id     => gt_organization_id          -- �݌ɑg�DID
      , in_parent_item_id => it_kbn_1_rec.parent_item_id -- �e�i��ID
      , in_child_item_id  => NULL                        -- �q�i��ID
      , ot_item_info_tab  => gt_item_info_tab            -- �i�ڏ��i�e�[�u���^�j
      , ov_errbuf         => lv_errbuf                   -- �G���[���b�Z�[�W
      , ov_retcode        => lv_retcode                  -- ���^�[���R�[�h
      , ov_errmsg         => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10562
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    -- 2�D���b�g�ʈ����q�i�ڈꎞ�\�폜
    --==============================================================
    DELETE FROM xxcoi_tmp_lot_reserve_item xtlri
    ;
    --
    --==============================================================
    -- 3�D���b�g�ʈ����q�i�ڈꎞ�\�o�^
    --==============================================================
    -- �q�i�ڃR�[�h��NULL�̏ꍇ�i�󒍂��e�i�ڂ����Ȃ��ꍇ�j
    IF ( it_kbn_1_rec.item_code IS NULL ) THEN
      -- �e�i�ړo�^���[�v
      << ins_parent_item_loop >>
      FOR i IN 1 .. gt_item_info_tab.COUNT LOOP
        INSERT INTO xxcoi_tmp_lot_reserve_item(
            item_id       -- �q�i��ID
          , item_code     -- �q�i�ڃR�[�h
          , item_name     -- �q�i�ږ���
          , item_div      -- ���i�敪
          , item_div_name -- ���i�敪��
        ) VALUES (
            gt_item_info_tab(i).item_id
          , gt_item_info_tab(i).item_no
          , gt_item_info_tab(i).item_short_name
          , gt_item_info_tab(i).item_kbn
          , gt_item_info_tab(i).item_kbn_name
        );
      END LOOP ins_parent_item_loop;
      -- �ϐ��ݒ�
      lt_inventory_item_id := it_kbn_1_rec.parent_item_id;
      lt_item_code         := it_kbn_1_rec.parent_item_code;
    -- �q�i�ڃR�[�h��NOT NULL�̏ꍇ
    ELSE
      -- �q�i�ړo�^���[�v
      << ins_item_loop >>
      FOR i IN 1 .. gt_item_info_tab.COUNT LOOP
        -- �q�R�[�h�ƈ�v����f�[�^�̂݁A�o�^�E�ϐ��ݒ肵�ă��[�v�𔲂���
        IF ( gt_item_info_tab(i).item_no = it_kbn_1_rec.item_code ) THEN
          INSERT INTO xxcoi_tmp_lot_reserve_item(
              item_id       -- �q�i��ID
            , item_code     -- �q�i�ڃR�[�h
            , item_name     -- �q�i�ږ���
            , item_div      -- ���i�敪
            , item_div_name -- ���i�敪��
          ) VALUES (
              gt_item_info_tab(i).item_id
            , gt_item_info_tab(i).item_no
            , gt_item_info_tab(i).item_short_name
            , gt_item_info_tab(i).item_kbn
            , gt_item_info_tab(i).item_kbn_name
          );
          --
          lt_inventory_item_id := gt_item_info_tab(i).item_id;
          lt_item_code         := gt_item_info_tab(i).item_no;
          --
          EXIT ins_item_loop;
          --
        END IF;
      END LOOP ins_item_loop;
    END IF;
    --
    -- �z��폜
    gt_item_info_tab.DELETE;
    --
    -- �f�o�b�O�p
    SELECT COUNT(1)
    INTO   gn_debug_cnt
    FROM   xxcoi_tmp_lot_reserve_item
    ;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-6.3 ���b�g�ʈ����q�i�ڈꎞ�\�o�^�����F' || gn_debug_cnt
    );
--
    --==============================================================
    -- 4�D�P�ʊ��Z�擾
    --==============================================================
    -- �P�ʊ��Z�擾
    xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => it_kbn_1_rec.order_quantity_uom -- ���Z�O�P�ʃR�[�h
      , in_before_quantity    => it_kbn_1_rec.ordered_quantity   -- ���Z�O����
      , iov_item_code         => lt_item_code                    -- �i�ڃR�[�h
      , iov_organization_code => gt_organization_code            -- �݌ɑg�D�R�[�h
      , ion_inventory_item_id => lt_inventory_item_id            -- �i�ڂh�c
      , ion_organization_id   => gt_organization_id              -- �݌ɑg�D�h�c
      , iov_after_uom_code    => lt_after_uom_code               -- ���Z��P�ʃR�[�h
      , on_after_quantity     => ln_after_quantity               -- ���Z�㐔��
      , on_content            => ln_content                      -- ����
      , ov_errbuf             => lv_errbuf                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      , ov_retcode            => lv_retcode                      -- ���^�[���E�R�[�h               #�Œ�#
      , ov_errmsg             => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
    -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10552
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 5�D�����擾
    --==============================================================
    -- �P�ʊ��Z�̓����͐������Ȃ����ߎ擾
    SELECT TO_NUMBER(iimb.attribute11) AS attribute11
    INTO   ln_content
    FROM   ic_item_mst_b iimb
    WHERE  iimb.item_no = lt_item_code
    ;
    gt_order_case_in_qty  := ln_content;
    -- �P�[�X���E�o�����ϊ�
    gt_order_case_qty   := TRUNC( ln_after_quantity / ln_content );
    gt_order_singly_qty := MOD( ln_after_quantity, ln_content );
    -- ����
    gt_order_summary_qty := ln_after_quantity;
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => 'A-6.4 �󒍏��' ||
                  ' �󒍔ԍ��F'    || it_kbn_1_rec.order_number                       ||
                  ' �i�ڃR�[�h�F'  || lt_item_code                                    ||
                  ' �����F'        || TO_CHAR(it_kbn_1_rec.arrival_date, cv_yyyymmdd) ||
                  ' �����F'        || gt_order_case_in_qty                            ||
                  ' �P�[�X���F'    || gt_order_case_qty                               ||
                  ' �o�����F'      || gt_order_singly_qty                             ||
                  ' �����F'        || gt_order_summary_qty
    );
--
  EXCEPTION
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
  END get_item;
--
  /**********************************************************************************
   * Procedure Name   : inventory_reservation
   * Description      : �����Ώۍ݌ɔ��菈��(A-7)
   ***********************************************************************************/
  PROCEDURE inventory_reservation(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- �������R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inventory_reservation'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_priority_cnt            NUMBER                                          DEFAULT 0;    -- �D��������P�[�V�������R�[�h����
    ln_location_cnt            NUMBER                                          DEFAULT 0;    -- �ʏ�܂��̓_�~�[���P�[�V�������R�[�h����
    --
    lt_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE       DEFAULT NULL; -- �i��ID
    lt_item_code               mtl_system_items_b.segment1%TYPE                DEFAULT NULL; -- �i�ڃR�[�h
    lt_item_name               xxcmn_item_mst_b.item_short_name%TYPE           DEFAULT NULL; -- �i�ږ���
    lt_item_kbn                mtl_categories_vl.segment1%TYPE                 DEFAULT NULL; -- ���i�敪
    lt_item_kbn_name           mtl_categories_vl.description%TYPE              DEFAULT NULL; -- ���i�敪��
    --
    lt_location_code           xxcoi_mst_warehouse_location.location_code%TYPE DEFAULT NULL; -- ���P�[�V�����R�[�h
    lt_location_name           xxcoi_mst_warehouse_location.location_name%TYPE DEFAULT NULL; -- ���P�[�V������
    --
    lt_short_case_qty          xxcoi_lot_onhand_quantites.case_qty%TYPE        DEFAULT 0;    -- �P�[�X���i�s�����j
    lt_short_singly_qty        xxcoi_lot_onhand_quantites.singly_qty%TYPE      DEFAULT 0;    -- �o�����i�s�����j
    lt_short_summary_qty       xxcoi_lot_onhand_quantites.summary_qty%TYPE     DEFAULT 0;    -- �����i�s�����j
--
    -- *** ���[�J���J�[�\�� ***
    -- �D�惍�P�[�V�����J�[�\��
    CURSOR l_priority_cur( iv_whse_code     VARCHAR2
                         , iv_location_code VARCHAR2 )
    IS
      SELECT xtlri.item_id                              AS item_id                 -- �q�i��ID
           , xtlri.item_code                            AS item_code               -- �q�i�ڃR�[�h
           , xtlri.item_name                            AS item_name               -- �q�i�ږ���
           , xtlri.item_div                             AS item_div                -- ���i�敪
           , xtlri.item_div_name                        AS item_div_name           -- ���i�敪��
           , xloq.subinventory_code                     AS subinventory_code       -- �ۊǏꏊ�R�[�h
           , xloq.location_code                         AS location_code           -- ���P�[�V�����R�[�h
           , xloq.lot                                   AS lot                     -- ���b�g
           , xloq.difference_summary_code               AS difference_summary_code -- �ŗL�L��
           , TO_DATE(xloq.production_date, cv_yyyymmdd) AS production_date         -- ������
      FROM   xxcoi_lot_onhand_quantites   xloq
           , xxcoi_tmp_lot_reserve_item   xtlri
      WHERE  xloq.organization_id   = gt_organization_id
      AND    xloq.base_code         = gv_login_base_code
      AND    xloq.subinventory_code = iv_whse_code
      AND    xloq.location_code     = iv_location_code
      AND    xloq.child_item_id     = xtlri.item_id
      ORDER BY xloq.lot
             , xtlri.item_code
             , xloq.difference_summary_code
    ;
    -- �ʏ�܂��̓_�~�[���P�[�V�����J�[�\��
    CURSOR l_location_cur( iv_whse_code VARCHAR2 )
    IS
      SELECT xtlri.item_id                              AS item_id                 -- �q�i��ID
           , xtlri.item_code                            AS item_code               -- �q�i�ڃR�[�h
           , xtlri.item_name                            AS item_name               -- �q�i�ږ���
           , xtlri.item_div                             AS item_div                -- ���i�敪
           , xtlri.item_div_name                        AS item_div_name           -- ���i�敪��
           , xloq.subinventory_code                     AS subinventory_code       -- �ۊǏꏊ�R�[�h
           , xloq.location_code                         AS location_code           -- ���P�[�V�����R�[�h
           , ( SELECT xwlmv.location_name
               FROM   xxcoi_warehouse_location_mst_v xwlmv
               WHERE  xwlmv.organization_id   = xloq.organization_id
               AND    xwlmv.base_code         = xloq.base_code
               AND    xwlmv.subinventory_code = xloq.subinventory_code
               AND    xwlmv.location_code     = xloq.location_code
             )                                          AS location_name           -- ���P�[�V������
           , xmwlv.priority                             AS priority                -- �D�揇��
           , xloq.lot                                   AS lot                     -- ���b�g
           , xloq.difference_summary_code               AS difference_summary_code -- �ŗL�L��
           , TO_DATE(xloq.production_date, cv_yyyymmdd) AS production_date         -- ������
      FROM   xxcoi_lot_onhand_quantites                 xloq
           , xxcoi_tmp_lot_reserve_item                 xtlri
           , ( SELECT xmwl.organization_id         AS organization_id
                    , xmwl.base_code               AS base_code
                    , xmwl.subinventory_code       AS subinventory_code
                    , xmwl.location_code           AS location_code
                    , MIN(xmwl.priority)           AS priority
               FROM   xxcoi_mst_warehouse_location xmwl
               WHERE  xmwl.location_type IN ( cv_normal, cv_dummy )
               GROUP BY xmwl.organization_id
                      , xmwl.base_code
                      , xmwl.subinventory_code
                      , xmwl.location_code )       xmwlv
      WHERE  xloq.organization_id   = xmwlv.organization_id
      AND    xloq.base_code         = xmwlv.base_code
      AND    xloq.subinventory_code = xmwlv.subinventory_code
      AND    xloq.location_code     = xmwlv.location_code
      AND    xloq.child_item_id     = xtlri.item_id
      AND    xloq.organization_id   = gt_organization_id
      AND    xloq.base_code         = gv_login_base_code
      AND    xloq.subinventory_code = iv_whse_code
      ORDER BY xloq.lot
             , xmwlv.priority
             , xtlri.item_code
             , xloq.difference_summary_code
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
    -- ������
    gv_reserve_err_msg   := NULL;
    lt_short_case_qty    := gt_order_case_qty;    -- �P�[�X���i�s�����j
    lt_short_singly_qty  := gt_order_singly_qty;  -- �o�����i�s�����j
    lt_short_summary_qty := gt_order_summary_qty; -- �����i�s�����j
    --
    --==============================================================
    -- 1�D�D�惍�P�[�V��������̈���
    --==============================================================
    -- �D�惍�P�[�V�����g�p��Y�̏ꍇ�A�D��������P�[�V��������̈���
    IF ( gv_priority_flag = cv_flag_y ) THEN
      -- 1-1�D�D��������P�[�V�����擾
      BEGIN
        SELECT xmwl.location_code             AS location_code -- ���P�[�V���R�[�h
             , xmwl.location_name             AS location_name -- ���P�[�V������
        INTO   lt_location_code
             , lt_location_name
        FROM   xxcoi_warehouse_location_mst_v xmwl
        WHERE  xmwl.organization_id   = gt_organization_id
        AND    xmwl.base_code         = gv_login_base_code
        AND    xmwl.subinventory_code = it_kbn_1_rec.whse_code
        AND    xmwl.location_type     = cv_priority
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �D��������P�[�V�������݃G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10546
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_subinventory_code
                         , iv_token_value2 => it_kbn_1_rec.whse_code
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- 1-2�D�D��������P�[�V��������̈���
      << priority_loop >>
      FOR l_priority_rec IN l_priority_cur( iv_whse_code     => it_kbn_1_rec.whse_code
                                          , iv_location_code => lt_location_code ) LOOP
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-7.1 �D�惍�P�[�V�������' ||
                      ' �ۊǏꏊ�R�[�h�F'          || l_priority_rec.subinventory_code                     ||
                      ' ���P�[�V�����R�[�h�F'      || l_priority_rec.location_code                         ||
                      ' �q�i�ڃR�[�h�F'            || l_priority_rec.item_code                             ||
                      ' �ܖ������F'                || l_priority_rec.lot                                   ||
                      ' �ŗL�L���F'                || l_priority_rec.difference_summary_code               ||
                      ' �������F'                  || TO_CHAR(l_priority_rec.production_date, cv_yyyymmdd)
        );
        -- ���R�[�h����
        ln_priority_cnt := ln_priority_cnt + 1;
        -- ��������
        reserve_process(
            iv_process_kbn             => cv_process_kbn_1                       -- �����敪
          , iv_subinventory_code       => l_priority_rec.subinventory_code       -- �ۊǏꏊ�R�[�h
          , iv_location_code           => l_priority_rec.location_code           -- ���P�[�V�����R�[�h
          , iv_location_name           => lt_location_name                       -- ���P�[�V������
          , iv_item_div                => l_priority_rec.item_div                -- ���i�敪
          , iv_item_div_name           => l_priority_rec.item_div_name           -- ���i�敪��
          , in_item_id                 => l_priority_rec.item_id                 -- �q�i��ID
          , iv_item_code               => l_priority_rec.item_code               -- �q�i�ڃR�[�h
          , iv_item_name               => l_priority_rec.item_name               -- �q�i�ږ�
          , iv_lot                     => l_priority_rec.lot                     -- ���b�g
          , iv_difference_summary_code => l_priority_rec.difference_summary_code -- �ŗL�L��
          , id_production_date         => l_priority_rec.production_date         -- ������
          , id_arrival_date            => it_kbn_1_rec.arrival_date              -- �[�i��
          , iv_order_number            => it_kbn_1_rec.order_number              -- �󒍔ԍ�
          , iv_customer_code           => it_kbn_1_rec.customer_code             -- �ڋq�R�[�h
          , iv_parent_item_code        => it_kbn_1_rec.parent_item_code          -- �e�i�ڃR�[�h
          , ion_short_case_qty         => lt_short_case_qty                      -- �P�[�X���i�s�����j
          , ion_short_singly_qty       => lt_short_singly_qty                    -- �o�����i�s�����j
          , ion_short_summary_qty      => lt_short_summary_qty                   -- �����i�s�����j
          , ov_errbuf                  => lv_errbuf                              -- �G���[�E���b�Z�[�W
          , ov_retcode                 => lv_retcode                             -- ���^�[���E�R�[�h
          , ov_errmsg                  => lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- �󒍐��ɒB���� or �擾��������S�Ċ��������ꍇ�Ƀ��[�v�𔲂���
        IF ( lt_short_summary_qty = 0 ) THEN
          EXIT priority_loop;
        END IF;
        --
      END LOOP priority_loop;
      --
    END IF;
--
    --==============================================================
    -- 2�D�ʏ탍�P�[�V�����܂��̓_�~�[���P�[�V��������̈���
    --==============================================================
    -- �D�惍�P�[�V�����g�p��N�̏ꍇ 
    -- �܂��� �D�惍�P�[�V��������̈�����ɕs�����i�����ł��Ă��Ȃ��󒍐��j�����݂���ꍇ
    IF ( ( gv_priority_flag = cv_flag_n )
      OR ( lt_short_summary_qty > 0 ) ) THEN
      -- 2-1�D�ʏ�܂��̓_�~�[���P�[�V��������̈���
      << location_loop >>
      FOR l_location_rec IN l_location_cur( iv_whse_code => it_kbn_1_rec.whse_code ) LOOP
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-7.2 ���P�[�V�������' ||
                      ' �ۊǏꏊ�R�[�h�F'      || l_location_rec.subinventory_code                     ||
                      ' ���P�[�V�����R�[�h�F'  || l_location_rec.location_code                         ||
                      ' �q�i�ڃR�[�h�F'        || l_location_rec.item_code                             ||
                      ' �ܖ������F'            || l_location_rec.lot                                   ||
                      ' �ŗL�L���F'            || l_location_rec.difference_summary_code               ||
                      ' �������F'              || TO_CHAR(l_location_rec.production_date, cv_yyyymmdd)
        );
        -- ���R�[�h����
        ln_location_cnt := ln_location_cnt + 1;
        -- ��������
        reserve_process(
            iv_process_kbn             => cv_process_kbn_2                       -- �����敪
          , iv_subinventory_code       => l_location_rec.subinventory_code       -- �ۊǏꏊ�R�[�h
          , iv_location_code           => l_location_rec.location_code           -- ���P�[�V�����R�[�h
          , iv_location_name           => l_location_rec.location_name           -- ���P�[�V������
          , iv_item_div                => l_location_rec.item_div                -- ���i�敪
          , iv_item_div_name           => l_location_rec.item_div_name           -- ���i�敪��
          , in_item_id                 => l_location_rec.item_id                 -- �q�i��ID
          , iv_item_code               => l_location_rec.item_code               -- �q�i�ڃR�[�h
          , iv_item_name               => l_location_rec.item_name               -- �q�i�ږ�
          , iv_lot                     => l_location_rec.lot                     -- ���b�g
          , iv_difference_summary_code => l_location_rec.difference_summary_code -- �ŗL�L��
          , id_production_date         => l_location_rec.production_date         -- ������
          , id_arrival_date            => it_kbn_1_rec.arrival_date              -- �[�i��
          , iv_order_number            => it_kbn_1_rec.order_number              -- �󒍔ԍ�
          , iv_customer_code           => it_kbn_1_rec.customer_code             -- �ڋq�R�[�h
          , iv_parent_item_code        => it_kbn_1_rec.parent_item_code          -- �e�i�ڃR�[�h
          , ion_short_case_qty         => lt_short_case_qty                      -- �P�[�X���i�s�����j
          , ion_short_singly_qty       => lt_short_singly_qty                    -- �o�����i�s�����j
          , ion_short_summary_qty      => lt_short_summary_qty                   -- �����i�s�����j
          , ov_errbuf                  => lv_errbuf                              -- �G���[�E���b�Z�[�W
          , ov_retcode                 => lv_retcode                             -- ���^�[���E�R�[�h
          , ov_errmsg                  => lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- �󒍐��ɒB���� or �擾��������S�Ċ��������ꍇ�Ƀ��[�v�𔲂���
        IF ( lt_short_summary_qty = 0 ) THEN
          EXIT location_loop;
        END IF;
        --
      END LOOP location_loop;
      --
    END IF;
--
    --==============================================================
    -- 3�D���b�Z�[�W�o��
    --==============================================================
    -- �擾��������S�Ċ���������ɕs�����i�����ł��Ă��Ȃ��󒍐��j�����݂���ꍇ
    IF ( lt_short_summary_qty > 0 ) THEN
      -- �q�i�ڃR�[�h��NULL�̏ꍇ�i�󒍂��e�i�ڂ����Ȃ��ꍇ�j�́A�e�i��
      -- �q�i�ڃR�[�h��NOT NULL�̏ꍇ�́A�q�i��
      SELECT item_id       AS item_id
           , item_code     AS item_code
           , item_name     AS item_name
           , item_div      AS item_div
           , item_div_name AS item_div_name
      INTO   lt_inventory_item_id
           , lt_item_code
           , lt_item_name
           , lt_item_kbn
           , lt_item_kbn_name
      FROM   xxcoi_tmp_lot_reserve_item
      WHERE  ROWNUM = 1
      ;
      IF ( it_kbn_1_rec.item_code IS NULL ) THEN
        lt_item_code         := it_kbn_1_rec.parent_item_code;
        lt_inventory_item_id := it_kbn_1_rec.parent_item_id;
        lt_item_name         := it_kbn_1_rec.parent_item_name;
      END IF;
      --
      -- �����Ώۂ̕ۊǏꏊ�Ƀ��b�g�ʎ莝���ʂ����݂��Ȃ��ꍇ
      IF ( ( ln_priority_cnt = 0 ) AND ( ln_location_cnt = 0 ) ) THEN
        -- �������i�[�z��F���b�g�ʈ������ւ̓o�^���e
        gn_reserve_cnt                                         := gn_reserve_cnt + 1;
        gt_reserve_tab(gn_reserve_cnt).location_code           := NULL;
        gt_reserve_tab(gn_reserve_cnt).location_name           := NULL;
        gt_reserve_tab(gn_reserve_cnt).item_div                := lt_item_kbn;
        gt_reserve_tab(gn_reserve_cnt).item_div_name           := lt_item_kbn_name;
        gt_reserve_tab(gn_reserve_cnt).item_code               := lt_item_code;
        gt_reserve_tab(gn_reserve_cnt).item_name               := lt_item_name;
        gt_reserve_tab(gn_reserve_cnt).lot                     := NULL;
        gt_reserve_tab(gn_reserve_cnt).difference_summary_code := NULL;
        gt_reserve_tab(gn_reserve_cnt).case_in_qty             := NULL;
        gt_reserve_tab(gn_reserve_cnt).case_qty                := NULL;
        gt_reserve_tab(gn_reserve_cnt).singly_qty              := NULL;
        gt_reserve_tab(gn_reserve_cnt).summary_qty             := NULL;
        gt_reserve_tab(gn_reserve_cnt).mark                    := NULL;
        gt_reserve_tab(gn_reserve_cnt).item_id                 := lt_inventory_item_id;
        gt_reserve_tab(gn_reserve_cnt).short_case_in_qty       := gt_order_case_in_qty;
        gt_reserve_tab(gn_reserve_cnt).short_case_qty          := gt_order_case_qty;
        gt_reserve_tab(gn_reserve_cnt).short_singly_qty        := gt_order_singly_qty;
        gt_reserve_tab(gn_reserve_cnt).short_summary_qty       := gt_order_summary_qty;
        -- ���b�g�ʎ莝���ʑ��݃G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10600
                       , iv_token_name1  => cv_tkn_order_number
                       , iv_token_value1 => it_kbn_1_rec.order_number
                       , iv_token_name2  => cv_tkn_subinventory_code
                       , iv_token_value2 => it_kbn_1_rec.whse_code
                       , iv_token_name3  => cv_tkn_item_code
                       , iv_token_value3 => lt_item_code
                     );
      -- ���b�g�ʎ莝���ʂ͑��݂��邪�A�����ł��Ă��Ȃ����ʂ����݂���ꍇ
      ELSE
        -- �󒍐��ƕs��������v����i1���������ł��Ă��Ȃ��ꍇ�j�ꍇ
        IF ( gn_reserve_cnt = 0 ) THEN
          -- �������i�[�z��F���b�g�ʈ������ւ̓o�^���e
          gn_reserve_cnt                                         := gn_reserve_cnt + 1;
          gt_reserve_tab(gn_reserve_cnt).location_code           := NULL;
          gt_reserve_tab(gn_reserve_cnt).location_name           := NULL;
          gt_reserve_tab(gn_reserve_cnt).item_div                := lt_item_kbn;
          gt_reserve_tab(gn_reserve_cnt).item_div_name           := lt_item_kbn_name;
          gt_reserve_tab(gn_reserve_cnt).item_code               := lt_item_code;
          gt_reserve_tab(gn_reserve_cnt).item_name               := lt_item_name;
          gt_reserve_tab(gn_reserve_cnt).lot                     := NULL;
          gt_reserve_tab(gn_reserve_cnt).difference_summary_code := NULL;
          gt_reserve_tab(gn_reserve_cnt).case_in_qty             := NULL;
          gt_reserve_tab(gn_reserve_cnt).case_qty                := NULL;
          gt_reserve_tab(gn_reserve_cnt).singly_qty              := NULL;
          gt_reserve_tab(gn_reserve_cnt).summary_qty             := NULL;
          gt_reserve_tab(gn_reserve_cnt).mark                    := NULL;
          gt_reserve_tab(gn_reserve_cnt).item_id                 := lt_inventory_item_id;
          gt_reserve_tab(gn_reserve_cnt).short_case_in_qty       := gt_order_case_in_qty;
          gt_reserve_tab(gn_reserve_cnt).short_case_qty          := gt_order_case_qty;
          gt_reserve_tab(gn_reserve_cnt).short_singly_qty        := gt_order_singly_qty;
          gt_reserve_tab(gn_reserve_cnt).short_summary_qty       := gt_order_summary_qty;
        END IF;
        -- ���������ɂă`�F�b�N�G���[�͂Ȃ��ꍇ
        IF ( gv_reserve_err_msg IS NULL ) THEN
          -- �݌ɐ��ʕs���G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10547
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_item_code
                         , iv_token_value2 => lt_item_code
                         , iv_token_name3  => cv_tkn_order_quantity
                         , iv_token_value3 => gt_order_summary_qty
                         , iv_token_name4  => cv_tkn_quantity
                         , iv_token_value4 => lt_short_summary_qty
                       );
        ELSIF ( gv_reserve_err_msg = cv_msg_xxcoi_10548 ) THEN
          -- ���b�g�t�]�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10548
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_customer_code
                         , iv_token_value2 => it_kbn_1_rec.customer_code
                         , iv_token_name3  => cv_tkn_item_code
                         , iv_token_value3 => it_kbn_1_rec.parent_item_code
                       );
        ELSIF ( gv_reserve_err_msg = cv_msg_xxcoi_10550 ) THEN
          -- �ڋq�N�x�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10550
                         , iv_token_name1  => cv_tkn_order_number
                         , iv_token_value1 => it_kbn_1_rec.order_number
                         , iv_token_name2  => cv_tkn_item_code
                         , iv_token_value2 => it_kbn_1_rec.parent_item_code
                         , iv_token_name3  => cv_tkn_fresh_condition
                         , iv_token_value3 => gt_cust_fresh_con_code
                       );
        END IF;
      END IF;
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
      -- �x���t���O
      gb_warn_flag := TRUE;
      -- �x���ŕԂ�
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
  END inventory_reservation;
--
  /**********************************************************************************
   * Procedure Name   : chk_order
   * Description      : �󒍒����`�F�b�N����(A-8)
   ***********************************************************************************/
  PROCEDURE chk_order(
      iv_order_number           IN  VARCHAR2 -- �󒍔ԍ�
-- Add Ver1.3 Start
    , iv_parent_shipping_status IN VARCHAR2 -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
-- Add Ver1.3 End
    , ov_errbuf                 OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                 OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_order'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_lot_tran_cnt            NUMBER                                    DEFAULT 0;     -- ���b�g�ʎ�����׌���
    ln_subinv_cnt              NUMBER                                    DEFAULT 0;     -- �ۊǏꏊ�`�F�b�N����
    ln_ins_cnt                 NUMBER                                    DEFAULT 0;     -- ���b�g�ʎ��TEMP�o�^����
    ln_dummy                   NUMBER                                    DEFAULT NULL;  -- �_�~�[�l
    lb_chk_flag                BOOLEAN                                   DEFAULT FALSE; -- �C������t���O
    lt_parent_item_id          oe_order_lines_all.inventory_item_id%TYPE DEFAULT NULL;  -- �i�ڃR�[�h
    lt_subinventory            oe_order_lines_all.subinventory%TYPE      DEFAULT NULL;  -- �ۊǏꏊ�R�[�h
    lt_after_uom_code          mtl_units_of_measure_tl.uom_code%TYPE     DEFAULT NULL;  -- ���Z��P�ʃR�[�h
    ln_after_quantity          NUMBER                                    DEFAULT 0;     -- ���Z�㐔��
    ln_order_summary_qty       NUMBER                                    DEFAULT 0;     -- ���Z�㐔�ʑ���
-- Add Ver1.2 Start
    ln_order_summary_qty2      NUMBER                                    DEFAULT 0;     -- ���Z�㐔�ʑ���2
    ln_subinv_cnt2             NUMBER                                    DEFAULT 0;     -- �ۊǏꏊ�`�F�b�N����
-- Add Ver1.2 End
    -- *** ���[�J���J�[�\�� ***
    -- �󒍃J�[�\��
    CURSOR l_order_cur( in_order_number NUMBER )
    IS
      SELECT ooha.header_id                                AS header_id                 -- �󒍃w�b�_ID
           , ooha.cust_po_number                           AS slip_num                  -- �`�[No
           , TO_CHAR(ooha.order_number)                    AS order_number              -- �󒍔ԍ�
           , ooha.order_source_id                          AS order_source_id           -- �󒍃\�[�XID
           , xca2.chain_store_code                         AS chain_code                -- �`�F�[���X�R�[�h
           , hca1.cust_account_id                          AS cust_account_id           -- �ڋqID
           , hca1.account_number                           AS customer_code             -- �ڋq�R�[�h
           , oola.line_id                                  AS line_id                   -- �󒍖���ID
           , oola.line_number                              AS line_number               -- �󒍖��הԍ�
           , oola.inventory_item_id                        AS parent_item_id            -- �e�i��ID
           , iimb.item_no                                  AS parent_item_code          -- �e�i�ڃR�[�h
           , ximb.item_short_name                          AS parent_item_name          -- �e�i�ږ�
           , NVL(oola.attribute5, scmd.sale_class_default) AS sale_class                -- ����敪
           , oola.attribute6                               AS item_code                 -- �q�i�ڃR�[�h
           , oola.ordered_quantity                         AS ordered_quantity          -- �󒍐���
           , oola.order_quantity_uom                       AS order_quantity_uom        -- �󒍒P��
           , oola.schedule_ship_date                       AS schedule_ship_date        -- �o�ד�
           , TRUNC(oola.request_date)                      AS arrival_date              -- ����
           , msi.attribute7                                AS base_code                 -- ���_�R�[�h
           , oola.subinventory                             AS whse_code                 -- �ۊǏꏊ�R�[�h
           , ottt2.name                                    AS line_name                 -- ���׃^�C�v
           , oola.flow_status_code                         AS flow_status_code          -- ���׃X�e�[�^�X
      FROM   oe_order_headers_all      ooha
           , oe_order_lines_all        oola
           , oe_transaction_types_all  otta1
           , oe_transaction_types_all  otta2
           , oe_transaction_types_tl   ottt1
           , oe_transaction_types_tl   ottt2
           , mtl_secondary_inventories msi
           , hz_cust_accounts          hca1
           , hz_cust_accounts          hca2
           , hz_parties                hp1
           , hz_parties                hp2
           , xxcmm_cust_accounts       xca1
           , xxcmm_cust_accounts       xca2
           , ic_item_mst_b             iimb
           , xxcmn_item_mst_b          ximb
           , mtl_system_items_b        msib
           , ( SELECT flv.meaning                               AS line_type_name
                    , flv.attribute1                            AS sale_class_default
               FROM   fnd_lookup_values                         flv
               WHERE  flv.lookup_type  = cv_sale_class_mst
               AND    flv.lookup_code  LIKE cv_xxcos
               AND    flv.language     = ct_lang
               AND    flv.enabled_flag = cv_flag_y
               AND    flv.start_date_active                     <= gd_process_date
               AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
             ) scmd
      WHERE  ooha.header_id                  = oola.header_id
      AND    ooha.org_id                     = gt_org_id
      AND    ooha.order_type_id              = otta1.transaction_type_id
      AND    otta1.transaction_type_code     = cv_order
      AND    otta1.transaction_type_id       = ottt1.transaction_type_id
      AND    ottt1.language                  = ct_lang
      AND    oola.line_type_id               = otta2.transaction_type_id
      AND    otta2.transaction_type_code     = cv_line
      AND    otta2.transaction_type_id       = ottt2.transaction_type_id
      AND    ottt2.language                  = ct_lang
      AND    ottt2.name                      = scmd.line_type_name
      AND    oola.ship_from_org_id           = gt_organization_id
      AND    oola.subinventory               = msi.secondary_inventory_name
      AND    oola.ship_from_org_id           = msi.organization_id
      AND    oola.inventory_item_id          = msib.inventory_item_id
      AND    oola.ship_from_org_id           = msib.organization_id
      AND    msib.segment1                   = iimb.item_no
      AND    iimb.item_id                    = ximb.item_id
      AND    ximb.start_date_active         <= TRUNC(oola.request_date)
      AND    ximb.end_date_active           >= TRUNC(oola.request_date)
      AND    oola.sold_to_org_id             = hca1.cust_account_id
      AND    hca1.party_id                   = hp1.party_id
      AND    hca1.cust_account_id            = xca1.customer_id
      AND    xca1.chain_store_code           = xca2.edi_chain_code(+)
      AND    xca2.customer_id                = hca2.cust_account_id(+)
      AND    hca2.party_id                   = hp2.party_id(+)
      AND EXISTS ( SELECT 1
                   FROM   fnd_lookup_values flv
                   WHERE  flv.lookup_type                            = cv_order_type_mst
                   AND    flv.lookup_code                         LIKE cv_xxcoi_016_a06
                   AND    flv.attribute1 IS NULL
                   AND    flv.attribute2 IS NULL
                   AND    flv.language                               = ct_lang
                   AND    flv.enabled_flag                           = cv_flag_y
                   AND    flv.start_date_active                     <= gd_process_date
                   AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date
                   AND    flv.meaning                                = ottt1.name )
      AND NOT EXISTS ( SELECT 1
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type                            = cv_no_inv_item_code
                       AND    flv.lookup_code                            = msib.segment1
                       AND    flv.language                               = ct_lang
                       AND    flv.enabled_flag                           = cv_flag_y
                       AND    flv.start_date_active                     <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date) >= gd_process_date )
      AND    ooha.order_number               = in_order_number
      ORDER BY oola.line_number
    ;
    -- �������i�w�b�_�j�J�[�\��
    CURSOR l_reserve_cur( in_header_id      NUMBER
                        , in_parent_item_id NUMBER )
    IS
      SELECT DISTINCT
             xlri.slip_num          AS slip_num     -- �`�[No
           , xlri.customer_id       AS customer_id  -- �ڋqID
           , xlri.arrival_date      AS arrival_date -- ����
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.header_id      = in_header_id
      AND    xlri.parent_item_id = in_parent_item_id
    ;
    -- �󒍐e�i�ڑ����擾�J�[�\��
    CURSOR l_parent_item_cur( in_order_number      NUMBER
                            , in_inventory_item_id NUMBER
                            , iv_subinventory      VARCHAR2 )
    IS
      SELECT oola.ordered_quantity   AS ordered_quantity   -- �󒍐���
           , oola.order_quantity_uom AS order_quantity_uom -- �󒍒P��
      FROM   oe_order_headers_all    ooha
           , oe_order_lines_all      oola
      WHERE  ooha.header_id         = oola.header_id
      AND    ooha.org_id            = gt_org_id
      AND    oola.flow_status_code <> cv_cancelled
      AND    ooha.order_number      = in_order_number
      AND    oola.inventory_item_id = in_inventory_item_id
      AND    oola.subinventory      = iv_subinventory
    ;
    -- �����e�i�ڑ����擾�J�[�\��
    CURSOR l_reserve_item_cur( in_header_id      NUMBER
                             , in_parent_item_id NUMBER
                             , iv_subinventory   VARCHAR2 )
    IS
      SELECT NVL(SUM(xlri.summary_qty), 0)  AS summary_qty  -- ��������
      FROM   xxcoi_lot_reserve_info         xlri
      WHERE  xlri.header_id      = in_header_id
      AND    xlri.parent_item_id = in_parent_item_id
      AND    xlri.whse_code      = iv_subinventory
    ;
-- Add Ver1.2 Start
    -- �����e�i�ڑ����擾�J�[�\��2
    CURSOR l_reserve_item2_cur( in_header_id     NUMBER
                             , in_parent_item_id NUMBER
                             , iv_subinventory   VARCHAR2 )
    IS
      SELECT NVL(SUM(xlri.summary_qty), 0)  AS summary_qty  -- ��������
      FROM   xxcoi_lot_reserve_info         xlri
      WHERE  xlri.header_id      = in_header_id
      AND    xlri.parent_item_id = in_parent_item_id
      AND    xlri.whse_code      = iv_subinventory
    ;
-- Add Ver1.2 End
    -- ���b�g�ʈ������X�V�p�J�[�\��
    CURSOR l_upd_reserve_cur( in_header_id NUMBER
                            , in_line_id   NUMBER )
    IS
      SELECT xlri.lot_reserve_info_id  AS lot_reserve_info_id
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.header_id = in_header_id
      AND    xlri.line_id   = in_line_id
    ;
    l_reserve_rec          l_reserve_cur%ROWTYPE;
    l_parent_item_rec      l_parent_item_cur%ROWTYPE;
    l_reserve_item_rec     l_reserve_item_cur%ROWTYPE;
-- Add Ver1.2 Start
    l_reserve_item2_rec    l_reserve_item2_cur%ROWTYPE;
-- Add Ver1.2 End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    gt_lot_id_tab.DELETE;
    --
    --==============================================================
    -- 1�D�󒍎擾
    --==============================================================
    -- �󒍎擾���[�v
    << order_loop >>
    FOR l_order_rec IN l_order_cur( in_order_number => TO_NUMBER(iv_order_number) ) LOOP
      -- ������
      ln_lot_tran_cnt := 0;
      lb_chk_flag     := FALSE;
      l_reserve_rec   := NULL;
      --
      -- �o�׉��m��̏ꍇ�A�`�F�b�N�Ȃ�
      -- ���m�������̏ꍇ�A���b�g�ʎ�����ׂ̑��݃`�F�b�N
      IF ( gv_kbn = cv_kbn_6 ) THEN
        SELECT COUNT(1)
        INTO   ln_lot_tran_cnt
        FROM   xxcoi_lot_transactions xlt
        WHERE  xlt.source_code  = cv_pkg_name
        AND    xlt.relation_key = l_order_rec.header_id || cv_under || l_order_rec.line_id
        ;
      END IF;
      --
      -- ���b�g�ʎ�����ׂ����݂���ꍇ
      IF ( ln_lot_tran_cnt > 0 ) THEN
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-8 ���b�g�ʎ�����ב���' ||
                      ' �󒍔ԍ��F'              || l_order_rec.order_number ||
                      ' �󒍖��הԍ��F'          || l_order_rec.line_number
        );
      -- ���b�g�ʎ�����ׂ����݂��Ȃ��ꍇ
      ELSE
        --
        --==============================================================
        -- 2�D�C���󒍃`�F�b�N
        --==============================================================
        -- �������i�w�b�_�j�擾
        OPEN l_reserve_cur( in_header_id      => l_order_rec.header_id
                          , in_parent_item_id => l_order_rec.parent_item_id );
        FETCH l_reserve_cur INTO l_reserve_rec;
        CLOSE l_reserve_cur;
        -- �󒍂ƈ��������Ⴗ��ꍇ�i�w�b�_�j
        IF ( ( l_order_rec.slip_num        <> l_reserve_rec.slip_num )
          OR ( l_order_rec.cust_account_id <> l_reserve_rec.customer_id )
          OR ( l_order_rec.arrival_date    <> l_reserve_rec.arrival_date ) ) THEN
          -- �C������
          lb_chk_flag := TRUE;
        END IF;
        --
        IF ( lb_chk_flag = FALSE ) THEN
          -- ������
          ln_order_summary_qty := 0;
          -- �ݒ�
          lt_parent_item_id    := l_order_rec.parent_item_id;
          lt_subinventory      := l_order_rec.whse_code;
          --
          -- �󒍐e�i�ڑ����擾���[�v
          << parent_item_loop >>
          FOR l_parent_item_rec IN l_parent_item_cur( in_order_number      => TO_NUMBER(l_order_rec.order_number)
                                                    , in_inventory_item_id => lt_parent_item_id
                                                    , iv_subinventory      => lt_subinventory ) LOOP
            -- ������
            ln_after_quantity    := 0;
            -- �P�ʊ��Z�擾
            xxcos_common_pkg.get_uom_cnv(
                iv_before_uom_code    => l_parent_item_rec.order_quantity_uom -- ���Z�O�P�ʃR�[�h
              , in_before_quantity    => l_parent_item_rec.ordered_quantity   -- ���Z�O����
              , iov_item_code         => l_order_rec.parent_item_code         -- �i�ڃR�[�h
              , iov_organization_code => gt_organization_code                 -- �݌ɑg�D�R�[�h
              , ion_inventory_item_id => lt_parent_item_id                    -- �i�ڂh�c
              , ion_organization_id   => gt_organization_id                   -- �݌ɑg�D�h�c
              , iov_after_uom_code    => lt_after_uom_code                    -- ���Z��P�ʃR�[�h
              , on_after_quantity     => ln_after_quantity                    -- ���Z�㐔��
              , on_content            => ln_dummy                             -- ����
              , ov_errbuf             => lv_errbuf                            -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
              , ov_retcode            => lv_retcode                           -- ���^�[���E�R�[�h               #�Œ�#
              , ov_errmsg             => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
            );
            -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
            IF ( lv_retcode <> cv_status_normal ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application
                             , iv_name         => cv_msg_xxcoi_10545
                             , iv_token_name1  => cv_tkn_common_pkg
                             , iv_token_value1 => cv_msg_xxcoi_10552
                             , iv_token_name2  => cv_tkn_errmsg
                             , iv_token_value2 => lv_errmsg
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
            --
            -- �e�i�ڃR�[�h�̑������Z
            ln_order_summary_qty := ln_order_summary_qty + ln_after_quantity;
            --
          END LOOP parent_item_loop;
          --
          -- �����e�i�ڑ����擾
          OPEN l_reserve_item_cur( in_header_id      => l_order_rec.header_id
                                 , in_parent_item_id => lt_parent_item_id
                                 , iv_subinventory   => lt_subinventory );
          FETCH l_reserve_item_cur INTO l_reserve_item_rec;
          CLOSE l_reserve_item_cur;
          --
          --==============================================================
          -- 2�D�C���󒍃`�F�b�N
          --==============================================================
-- Add Ver1.3 Start
          -- �o�׉��m�肩��
          -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj���������̏ꍇ
          IF (  ( gv_kbn = cv_kbn_3 )
            AND ( iv_parent_shipping_status = cv_shipping_status_10 ) ) THEN
            -- �󒍂̑�����0�̏ꍇ�i�������Ă���ꍇ�j
            IF ( ln_order_summary_qty = 0 ) THEN
              -- �w�肳�ꂽ�ۊǏꏊ�ƈ�v����ꍇ
              IF ( gv_subinventory_code = lt_subinventory ) THEN
                -- ���b�g�ʈ������폜�p���[�v
                << del_reserve_loop >>
                FOR l_del_reserve_rec IN l_upd_reserve_cur( in_header_id => l_order_rec.header_id
                                                          , in_line_id   => l_order_rec.line_id ) LOOP
                  -- ����ID���擾���Ă��Ȃ��ꍇ
                  IF ( g_del_id_tab.EXISTS( l_del_reserve_rec.lot_reserve_info_id ) = FALSE ) THEN
                    -- ID��ێ�
                    g_del_id_tab( l_del_reserve_rec.lot_reserve_info_id ) := 1;
                    --
                    FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                      , buff   => 'A-8 �폜 ���b�g�ʈ������ID ' || l_del_reserve_rec.lot_reserve_info_id
                    );
                  END IF;
                  --
                END LOOP del_reserve_loop;
              END IF;
            -- �󒍂̑�����0�ł͂Ȃ�
            ELSE
              -- �󒍂ƈ����̑��������Ⴕ�Ȃ��ꍇ
              IF ( ln_order_summary_qty <> l_reserve_item_rec.summary_qty ) THEN
                -- �w�肳�ꂽ�ۊǏꏊ�ƈ�v����ꍇ�A�C������x��
                IF ( gv_subinventory_code = lt_subinventory ) THEN
                  -- �C������
                  lb_chk_flag := TRUE;
                -- �w�肳�ꂽ�ۊǏꏊ�ƈ�v���Ȃ��ꍇ
                ELSE
                  -- ���b�g�ʈ������폜�p���[�v
                  << del_reserve_loop >>
                  FOR l_del_reserve_rec IN l_upd_reserve_cur( in_header_id => l_order_rec.header_id
                                                            , in_line_id   => l_order_rec.line_id ) LOOP
                    -- ����ID���擾���Ă��Ȃ��ꍇ
                    IF ( g_del_id_tab.EXISTS( l_del_reserve_rec.lot_reserve_info_id ) = FALSE ) THEN
                      -- ID��ێ�
                      g_del_id_tab( l_del_reserve_rec.lot_reserve_info_id ) := 1;
                      --
                      FND_FILE.PUT_LINE(
                          which  => FND_FILE.LOG
                        , buff   => 'A-8 �폜 ���b�g�ʈ������ID ' || l_del_reserve_rec.lot_reserve_info_id
                      );
                    END IF;
                    --
                  END LOOP del_reserve_loop;
                END IF;
              END IF;
            END IF;
          -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj�������ς̏ꍇ
          -- �܂��͉��m�������̏ꍇ
          ELSE
-- Add Ver1.3 End
            -- �󒍂ƈ����̑��������Ⴗ��ꍇ
            IF ( ln_order_summary_qty <> l_reserve_item_rec.summary_qty ) THEN
-- Mod Ver1.2 Start
--              -- �C������
--              lb_chk_flag := TRUE;
--              --
--              -- �q�ɊǗ��ΏۂŖ�����΍폜�̂�
--              SELECT COUNT(1)                     AS cnt
--              INTO   ln_subinv_cnt
--              FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
--              WHERE  xtlrs.subinventory_code = lt_subinventory
--              ;
--              IF ( ln_subinv_cnt = 0 ) THEN
--                l_order_rec.flow_status_code := cv_cancelled;
--              END IF;
              -- �ۊǏꏊ�w��̏ꍇ
              IF ( gv_subinventory_code IS NOT NULL ) THEN
                -- �w�肳�ꂽ�ۊǏꏊ�ƈ�v����ꍇ�A�C������x��
                IF ( gv_subinventory_code = lt_subinventory ) THEN
                  -- �C������
                  lb_chk_flag := TRUE;
                -- �w�肳�ꂽ�ۊǏꏊ�ƈ�v���Ȃ��ꍇ
                ELSE
                  -- ������
                  ln_order_summary_qty2 := 0;
                  -- �󒍐e�i�ڑ����擾���[�v
                  << parent_item_loop2 >>
                  FOR l_parent_item_rec IN l_parent_item_cur( in_order_number      => TO_NUMBER(l_order_rec.order_number)
                                                            , in_inventory_item_id => lt_parent_item_id
                                                            , iv_subinventory      => gv_subinventory_code ) LOOP
                    -- ������
                    ln_after_quantity    := 0;
                    -- �P�ʊ��Z�擾
                    xxcos_common_pkg.get_uom_cnv(
                        iv_before_uom_code    => l_parent_item_rec.order_quantity_uom -- ���Z�O�P�ʃR�[�h
                      , in_before_quantity    => l_parent_item_rec.ordered_quantity   -- ���Z�O����
                      , iov_item_code         => l_order_rec.parent_item_code         -- �i�ڃR�[�h
                      , iov_organization_code => gt_organization_code                 -- �݌ɑg�D�R�[�h
                      , ion_inventory_item_id => lt_parent_item_id                    -- �i�ڂh�c
                      , ion_organization_id   => gt_organization_id                   -- �݌ɑg�D�h�c
                      , iov_after_uom_code    => lt_after_uom_code                    -- ���Z��P�ʃR�[�h
                      , on_after_quantity     => ln_after_quantity                    -- ���Z�㐔��
                      , on_content            => ln_dummy                             -- ����
                      , ov_errbuf             => lv_errbuf                            -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
                      , ov_retcode            => lv_retcode                           -- ���^�[���E�R�[�h               #�Œ�#
                      , ov_errmsg             => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
                    );
                    -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
                    IF ( lv_retcode <> cv_status_normal ) THEN
                      lv_errmsg := xxccp_common_pkg.get_msg(
                                       iv_application  => cv_application
                                     , iv_name         => cv_msg_xxcoi_10545
                                     , iv_token_name1  => cv_tkn_common_pkg
                                     , iv_token_value1 => cv_msg_xxcoi_10552
                                     , iv_token_name2  => cv_tkn_errmsg
                                     , iv_token_value2 => lv_errmsg
                                   );
                      lv_errbuf := lv_errmsg;
                      RAISE global_api_expt;
                    END IF;
                    --
                    -- �e�i�ڃR�[�h�̑������Z
                    ln_order_summary_qty2 := ln_order_summary_qty2 + ln_after_quantity;
                    --
                  END LOOP parent_item_loop2;
                  --
                  -- �����e�i�ڑ����擾2
                  OPEN l_reserve_item2_cur( in_header_id      => l_order_rec.header_id
                                          , in_parent_item_id => lt_parent_item_id
                                          , iv_subinventory   => gv_subinventory_code );
                  FETCH l_reserve_item2_cur INTO l_reserve_item2_rec;
                  CLOSE l_reserve_item2_cur;
                  --
                  -- �󒍐��ʂ�����A�w�肳�ꂽ�ۊǏꏊ�Ŏ󒍂ƈ������Ⴄ
                  IF ( ( ( l_reserve_item_rec.summary_qty > 0 ) OR ( l_reserve_item2_rec.summary_qty > 0 ) )
                    AND  ( ln_order_summary_qty2 <> l_reserve_item2_rec.summary_qty ) ) THEN
                    -- �C������
                    lb_chk_flag := TRUE;
                  END IF;
                END IF;
              -- �ۊǏꏊ�w��Ȃ��̏ꍇ
              ELSE
                ln_subinv_cnt := 0;
                -- �q�ɊǗ��Ώۂ̃`�F�b�N
                SELECT COUNT(1)                     AS cnt
                INTO   ln_subinv_cnt
                FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                WHERE  xtlrs.subinventory_code = lt_subinventory
                ;
                -- �q�ɊǗ��ΏۂŖ�����΍폜�̂݁i�q�ɊǗ��Ώۂ�ύX���ꂽ�ꍇ���l���j
                IF ( ln_subinv_cnt = 0 ) THEN
                  l_order_rec.flow_status_code := cv_cancelled;
                -- �q�ɊǗ��Ώۂ̏ꍇ�A�C������x��
                ELSE
                  -- �C������
                  lb_chk_flag := TRUE;
                END IF;
              END IF;
-- Mod Ver1.2 End
            END IF;
-- Add Ver1.3 Start
          END IF;
-- Add Ver1.3 End
        END IF;
        --
        -- �C��������ꍇ
        IF ( lb_chk_flag = TRUE ) THEN
          -- �o�׉��m��̏ꍇ
          IF ( gv_kbn = cv_kbn_3 ) THEN
            -- ������񍷈كG���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                           , iv_name         => cv_msg_xxcoi_10553
                           , iv_token_name1  => cv_tkn_order_number
                           , iv_token_value1 => l_order_rec.order_number
                           , iv_token_name2  => cv_tkn_line_number
                           , iv_token_value2 => l_order_rec.line_number
                         );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg
            );
            -- �x���ŕԂ�
            ov_retcode   := cv_status_warn;
            gb_warn_flag := TRUE;
          -- ���m�������̏ꍇ
          ELSIF ( gv_kbn = cv_kbn_6 ) THEN
-- Mod Ver1.2 Start
            -- �ۊǏꏊ�w��̏ꍇ
            IF ( gv_subinventory_code IS NOT NULL ) THEN
              -- �q�ɊǗ��Ώۂ̃`�F�b�N
              SELECT COUNT(1)                     AS cnt
              INTO   ln_subinv_cnt2
              FROM   mtl_secondary_inventories    msi
              WHERE  msi.attribute14     = cv_flag_y
              AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
              AND    msi.organization_id = gt_organization_id
              AND    msi.secondary_inventory_name = lt_subinventory
              ;
              -- �q�ɊǗ��ΏۂŖ�����΍폜�̂݁i�q�ɊǗ��Ώۂ�ύX���ꂽ�ꍇ���l���j
              IF ( ln_subinv_cnt2 = 0 ) THEN
                l_order_rec.flow_status_code := cv_cancelled;
              END IF;
            END IF;
-- Mod Ver1.2 End
            -- ���b�g�ʎ��TEMP�o�^����
            ins_lot_tran_temp(
                iv_tran_kbn           => cv_tran_kbn_1                  -- ����敪
              , in_header_id          => l_order_rec.header_id          -- �󒍃w�b�_ID
              , in_line_id            => l_order_rec.line_id            -- �󒍖���ID
              , iv_slip_num           => l_order_rec.slip_num           -- �`�[No
              , iv_order_number       => l_order_rec.order_number       -- �󒍔ԍ�
              , iv_line_number        => l_order_rec.line_number        -- �󒍖��הԍ�
              , id_arrival_date       => l_order_rec.arrival_date       -- ����
              , iv_parent_item_code   => l_order_rec.parent_item_code   -- �e�i�ڃR�[�h
              , iv_item_code          => l_order_rec.item_code          -- �q�i�ڃR�[�h
              , in_parent_item_id     => l_order_rec.parent_item_id     -- �i��ID
              , iv_order_quantity_uom => l_order_rec.order_quantity_uom -- �󒍒P��
              , in_ordered_quantity   => l_order_rec.ordered_quantity   -- �󒍐���
              , iv_base_code          => l_order_rec.base_code          -- ���_�R�[�h
              , iv_subinventory_code  => l_order_rec.whse_code          -- �ۊǏꏊ�R�[�h
              , iv_line_name          => l_order_rec.line_name          -- ���דE�v
              , iv_sale_class         => l_order_rec.sale_class         -- ��ԓ����敪(����)
              , iv_flow_status_code   => l_order_rec.flow_status_code   -- ���׃X�e�[�^�X
              , ov_errbuf             => lv_errbuf                      -- �G���[�E���b�Z�[�W
              , ov_retcode            => lv_retcode                     -- ���^�[���E�R�[�h
              , ov_errmsg             => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            --
            -- ���b�g�ʈ������X�V�p���[�v
            << upd_reserve_loop >>
            FOR l_upd_reserve_rec IN l_upd_reserve_cur( in_header_id => l_order_rec.header_id
                                                      , in_line_id   => l_order_rec.line_id ) LOOP
              ln_ins_cnt := ln_ins_cnt + 1;
              gt_lot_id_tab(ln_ins_cnt) := l_upd_reserve_rec.lot_reserve_info_id;
            END LOOP upd_reserve_loop;
          END IF;
          --
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => 'A-8 ���ق���'    ||
                        ' �󒍔ԍ��F'     || l_order_rec.order_number ||
                        ' �󒍖��הԍ��F' || l_order_rec.line_number
          );
          IF  ( l_order_rec.slip_num <> l_reserve_rec.slip_num ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '�`�[No�F' || l_order_rec.slip_num  || ' ' || l_reserve_rec.slip_num
            );
          ELSIF ( l_order_rec.cust_account_id <> l_reserve_rec.customer_id ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '�ڋqID�F' || l_order_rec.cust_account_id  || ' ' || l_reserve_rec.customer_id
            );
          ELSIF  ( l_order_rec.arrival_date <> l_reserve_rec.arrival_date ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => '�����F' || TO_CHAR(l_order_rec.arrival_date, cv_yyyymmdd)  || ' ' || TO_CHAR(l_reserve_rec.arrival_date, cv_yyyymmdd)
            );
          ELSIF  ( NVL(ln_order_summary_qty, 0) <> NVL(l_reserve_item_rec.summary_qty, 0) ) THEN
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
-- Mod Ver1.2 Start
--              , buff   => '�󒍐��ʁF' || ln_order_summary_qty  || ' ' || l_reserve_item_rec.summary_qty
              , buff   => '�󒍐��ʁF' || ln_order_summary_qty  || ' ' || l_reserve_item_rec.summary_qty || ' ' || ln_order_summary_qty2 || ' ' || NVL(l_reserve_item2_rec.summary_qty, 0)
-- Mod Ver1.2 End
            );
          END IF;
        ELSE
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => 'A-8 ���قȂ�'    ||
                        ' �󒍔ԍ��F'     || l_order_rec.order_number ||
                        ' �󒍖��הԍ��F' || l_order_rec.line_number
          );
        END IF;
      END IF;
    END LOOP xtlri_loop;
--
  EXCEPTION
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
      IF ( l_order_cur%ISOPEN ) THEN
        CLOSE l_order_cur;
      END IF;
      IF ( l_reserve_cur%ISOPEN ) THEN
        CLOSE l_reserve_cur;
      END IF;
      IF ( l_parent_item_cur%ISOPEN ) THEN
        CLOSE l_parent_item_cur;
      END IF;
      IF ( l_reserve_item_cur%ISOPEN ) THEN
        CLOSE l_reserve_item_cur;
      END IF;
-- Add Ver1.2 Start
      IF ( l_reserve_item2_cur%ISOPEN ) THEN
        CLOSE l_reserve_item2_cur;
      END IF;
-- Add Ver1.2 End
      IF ( l_upd_reserve_cur%ISOPEN ) THEN
        CLOSE l_upd_reserve_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_order;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_transactions
   * Description      : ���b�g�ʎ�����דo�^����(A-9)
   ***********************************************************************************/
  PROCEDURE ins_lot_transactions(
      it_kbn_4_rec IN  g_kbn_4_cur%ROWTYPE -- �o�׊m�背�R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_transactions'; -- �v���O������
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
    lt_trx_id               xxcoi_lot_transactions.transaction_id%TYPE DEFAULT NULL; -- ���ID
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D���b�g�ʎ�����׍쐬
    --==============================================================
    xxcoi_common_pkg.cre_lot_trx(
        in_trx_set_id            => NULL                                                       -- ����Z�b�gID
      , iv_parent_item_code      => it_kbn_4_rec.parent_item_code                              -- �e�i�ڃR�[�h
      , iv_child_item_code       => it_kbn_4_rec.item_code                                     -- �q�i�ڃR�[�h
      , iv_lot                   => it_kbn_4_rec.lot                                           -- ���b�g(�ܖ�����)
      , iv_diff_sum_code         => it_kbn_4_rec.difference_summary_code                       -- �ŗL�L��
      , iv_trx_type_code         => it_kbn_4_rec.reserve_transaction_type_code                 -- ����^�C�v�R�[�h
      , id_trx_date              => it_kbn_4_rec.arrival_date                                  -- �����
      , iv_slip_num              => it_kbn_4_rec.slip_num                                      -- �`�[No
      , in_case_in_qty           => it_kbn_4_rec.case_in_qty                                   -- ����
      , in_case_qty              => it_kbn_4_rec.case_qty * (-1)                               -- �P�[�X��
      , in_singly_qty            => it_kbn_4_rec.singly_qty * (-1)                             -- �o����
      , in_summary_qty           => it_kbn_4_rec.summary_qty * (-1)                            -- �������
      , iv_base_code             => it_kbn_4_rec.base_code                                     -- ���_�R�[�h
      , iv_subinv_code           => it_kbn_4_rec.whse_code                                     -- �ۊǏꏊ�R�[�h
      , iv_loc_code              => it_kbn_4_rec.location_code                                 -- ���P�[�V�����R�[�h
      , iv_tran_subinv_code      => NULL                                                       -- �]����ۊǏꏊ�R�[�h
      , iv_tran_loc_code         => NULL                                                       -- �]���惍�P�[�V�����R�[�h
      , iv_sign_div              => cv_sign_div_0                                              -- �����敪
      , iv_source_code           => cv_pkg_name                                                -- �\�[�X�R�[�h
      , iv_relation_key          => it_kbn_4_rec.header_id || cv_under || it_kbn_4_rec.line_id -- �R�t���L�[
      , iv_reason                => NULL                                                       -- ���R
      , iv_reserve_trx_type_code => NULL                                                       -- ����������^�C�v�R�[�h
      , on_trx_id                => lt_trx_id                                                  -- ���b�g�ʎ������
      , ov_errbuf                => lv_errbuf                                                  -- �G���[���b�Z�[�W
      , ov_retcode               => lv_retcode                                                 -- ���^�[���R�[�h
      , ov_errmsg                => lv_errmsg                                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10495
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END ins_lot_transactions;
--
  /**********************************************************************************
   * Procedure Name   : ref_lot_onhand
   * Description      : ���b�g�ʎ莝���ʔ��f����(A-10)
   ***********************************************************************************/
  PROCEDURE ref_lot_onhand(
      it_kbn_4_rec IN  g_kbn_4_cur%ROWTYPE -- �o�׊m�背�R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ref_lot_onhand'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D���b�g�ʎ莝���ʔ��f
    --==============================================================
    xxcoi_common_pkg.ins_upd_del_lot_onhand(
        in_inv_org_id    => gt_organization_id                   -- �݌ɑg�DID
      , iv_base_code     => it_kbn_4_rec.base_code               -- ���_�R�[�h
      , iv_subinv_code   => it_kbn_4_rec.whse_code               -- �ۊǏꏊ�R�[�h
      , iv_loc_code      => it_kbn_4_rec.location_code           -- ���P�[�V�����R�[�h
      , in_child_item_id => it_kbn_4_rec.item_id                 -- �q�i��ID
      , iv_lot           => it_kbn_4_rec.lot                     -- ���b�g(�ܖ�����)
      , iv_diff_sum_code => it_kbn_4_rec.difference_summary_code -- �ŗL�L��
      , in_case_in_qty   => it_kbn_4_rec.case_in_qty             -- ����
      , in_case_qty      => it_kbn_4_rec.case_qty * (-1)         -- �P�[�X��
      , in_singly_qty    => it_kbn_4_rec.singly_qty * (-1)       -- �o����
      , in_summary_qty   => it_kbn_4_rec.summary_qty * (-1)      -- �������
      , ov_errbuf        => lv_errbuf                            -- �G���[���b�Z�[�W
      , ov_retcode       => lv_retcode                           -- ���^�[���R�[�h
      , ov_errmsg        => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10559
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END ref_lot_onhand;
--
  /**********************************************************************************
   * Procedure Name   : ref_mst_lot_hold_info
   * Description      : ���b�g���ێ��}�X�^���f����(A-11)
   ***********************************************************************************/
  PROCEDURE ref_mst_lot_hold_info(
      it_kbn_3_rec IN  g_kbn_3_cur%ROWTYPE -- �o�׊m�背�R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ref_mst_lot_hold_info'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D���b�g���ێ��}�X�^���f
    --==============================================================
    xxcoi_common_pkg.ins_upd_lot_hold_info(
        in_customer_id    => it_kbn_3_rec.customer_id    -- �ڋqID
      , in_deliver_to_id  => NULL                        -- �o�א�ID
      , in_parent_item_id => it_kbn_3_rec.parent_item_id -- �e�i��ID
      , iv_deliver_lot    => it_kbn_3_rec.lot            -- �[�i���b�g
      , id_delivery_date  => it_kbn_3_rec.arrival_date   -- �[�i��
      , iv_e_s_kbn        => cv_eigyo                    -- �c�Ɛ��Y�敪
      , iv_cancel_kbn     => cv_cancel_kbn_0             -- ����敪
      , ov_errbuf         => lv_errbuf                   -- �G���[���b�Z�[�W
      , ov_retcode        => lv_retcode                  -- ���^�[���R�[�h
      , ov_errmsg         => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- ���^�[���R�[�h������ȊO�̏ꍇ�A�G���[
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10545
                     , iv_token_name1  => cv_tkn_common_pkg
                     , iv_token_value1 => cv_msg_xxcoi_10563
                     , iv_token_name2  => cv_tkn_errmsg
                     , iv_token_value2 => lv_errmsg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END ref_mst_lot_hold_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_reserve_info
   * Description      : ���b�g�ʈ������o�^����(A-12)
   ***********************************************************************************/
  PROCEDURE ins_lot_reserve_info(
      it_kbn_1_rec IN  g_kbn_1_cur%ROWTYPE -- �������R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_reserve_info'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_dummy                VARCHAR(3)                                                DEFAULT NULL; -- �_�~�[�l
    ln_dummy                NUMBER                                                    DEFAULT NULL; -- �_�~�[�l
    lt_red_black_flag       fnd_lookup_values.attribute1%TYPE                         DEFAULT NULL; -- �ԍ��t���O
    lt_shipping_status      xxcoi_lot_reserve_info.shipping_status%TYPE               DEFAULT NULL; -- �o�׏��X�e�[�^�X
    lt_shipping_status_name xxcoi_lot_reserve_info.shipping_status_name%TYPE          DEFAULT NULL; -- �o�׏��X�e�[�^�X��
    lt_tran_type_code       xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE DEFAULT NULL; -- ����������^�C�v�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- 1�D���b�g�ʈ������o�^
    --==============================================================
    IF ( gv_retcode = cv_status_normal ) THEN
      -- ����^�C�v�擾
      get_tran_type(
          iv_tran_kbn            => cv_tran_kbn_1                        -- ����敪
        , iv_line_name           => it_kbn_1_rec.line_type               -- ���דE�v
        , iv_sale_class          => it_kbn_1_rec.regular_sale_class_line -- ����敪
        , ion_order_case_qty     => ln_dummy                             -- �P�[�X��
        , ion_order_singly_qty   => ln_dummy                             -- �o����
        , ion_after_quantity     => ln_dummy                             -- ����
        , ov_tran_type_code_temp => lv_dummy                             -- ����^�C�v�R�[�h
        , ov_tran_type_code      => lt_tran_type_code                    -- ����������^�C�v�R�[�h
        , ov_errbuf              => lv_errbuf                            -- �G���[�E���b�Z�[�W
        , ov_retcode             => lv_retcode                           -- ���^�[���E�R�[�h
        , ov_errmsg              => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �o�׏��X�e�[�^�X�ݒ�
    -- �������펞
    IF ( gv_retcode = cv_status_normal ) THEN
      lt_shipping_status      := cv_shipping_status_20;
      lt_shipping_status_name := gt_shipping_status_20;
    -- �������s��
    ELSE
      lt_shipping_status      := cv_shipping_status_10;
      lt_shipping_status_name := gt_shipping_status_10;
    END IF;
--
    -- ���b�g�ʈ������o�^���[�v
    << ins_lot_reserve_loop >>
    FOR i IN 1 .. gt_reserve_tab.COUNT LOOP
      INSERT INTO xxcoi_lot_reserve_info(
          lot_reserve_info_id                       -- ���b�g�ʈ������ID
        , slip_num                                  -- �`�[No
        , order_number                              -- �󒍔ԍ�
        , org_id                                    -- �c�ƒP��
        , parent_shipping_status                    -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
        , parent_shipping_status_name               -- �o�׏��X�e�[�^�X����(�󒍔ԍ��P��)
        , base_code                                 -- ���_�R�[�h
        , base_name                                 -- ���_��
        , whse_code                                 -- �ۊǏꏊ�R�[�h
        , whse_name                                 -- �ۊǏꏊ��
        , location_code                             -- ���P�[�V�����R�[�h
        , location_name                             -- ���P�[�V��������
        , shipping_status                           -- �o�׏��X�e�[�^�X
        , shipping_status_name                      -- �o�׏��X�e�[�^�X����
        , chain_code                                -- �`�F�[���X�R�[�h
        , chain_name                                -- �`�F�[���X��
        , shop_code                                 -- �X�܃R�[�h
        , shop_name                                 -- �X�ܖ�
        , customer_code                             -- �ڋq�R�[�h
        , customer_name                             -- �ڋq��
        , center_code                               -- �Z���^�[�R�[�h
        , center_name                               -- �Z���^�[��
        , area_code                                 -- �n��R�[�h
        , area_name                                 -- �n�於��
        , shipped_date                              -- �o�ד�
        , arrival_date                              -- ����
        , item_div                                  -- ���i�敪
        , item_div_name                             -- ���i�敪��
        , parent_item_code                          -- �e�i�ڃR�[�h
        , parent_item_name                          -- �e�i�ږ���
        , item_code                                 -- �q�i�ڃR�[�h
        , item_name                                 -- �q�i�ږ���
        , lot                                       -- ���b�g
        , difference_summary_code                   -- �ŗL�L��
        , case_in_qty                               -- ����
        , case_qty                                  -- �P�[�X��
        , singly_qty                                -- �o����
        , summary_qty                               -- ����
        , regular_sale_class_line                   -- ��ԓ����敪(����)
        , regular_sale_class_name_line              -- ��ԓ����敪��(����)
        , edi_received_date                         -- EDI��M��
        , delivery_order_edi                        -- �z����(EDI)
        , before_ordered_quantity                   -- �����O�󒍐���
        , reserve_performer_code                    -- �������s�҃R�[�h
        , reserve_performer_name                    -- �������s�Җ�
        , mark                                      -- �L��
        , lot_tran_kbn                              -- ���b�g�ʎ�����׍쐬�敪
        , header_id                                 -- �󒍃w�b�_ID
        , line_id                                   -- �󒍖���ID
        , customer_id                               -- �ڋqID
        , parent_item_id                            -- �e�i��ID
        , item_id                                   -- �q�i��ID
        , reserve_transaction_type_code             -- ����������^�C�v�R�[�h
        , order_quantity_uom                        -- �󒍒P��
        , ordered_quantity                          -- �󒍐���
        , short_case_in_qty                         -- �����i�s�����j
        , short_case_qty                            -- �P�[�X���i�s�����j
        , short_singly_qty                          -- �o�����i�s�����j
        , short_summary_qty                         -- ���ʁi�s�����j
        , created_by                                -- �쐬��
        , creation_date                             -- �쐬��
        , last_updated_by                           -- �ŏI�X�V��
        , last_update_date                          -- �ŏI�X�V��
        , last_update_login                         -- �ŏI�X�V���O�C��
        , request_id                                -- �v��ID
        , program_application_id                    -- �v���O�����A�v���P�[�V����ID
        , program_id                                -- �v���O����ID
        , program_update_date                       -- �v���O�����X�V��
      ) VALUES (
          xxcoi_lot_reserve_info_s01.NEXTVAL        -- ���b�g�ʈ������ID
        , it_kbn_1_rec.slip_num                     -- �`�[No
        , it_kbn_1_rec.order_number                 -- �󒍔ԍ�
        , gt_org_id                                 -- �c�ƒP��
        , NULL                                      -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
        , NULL                                      -- �o�׏��X�e�[�^�X����(�󒍔ԍ��P��)
        , gv_login_base_code                        -- ���_�R�[�h
        , gt_base_name                              -- ���_��
        , it_kbn_1_rec.whse_code                    -- �ۊǏꏊ�R�[�h
        , it_kbn_1_rec.whse_name                    -- �ۊǏꏊ��
        , gt_reserve_tab(i).location_code           -- ���P�[�V�����R�[�h
        , gt_reserve_tab(i).location_name           -- ���P�[�V��������
        , lt_shipping_status                        -- �o�׏��X�e�[�^�X
        , lt_shipping_status_name                   -- �o�׏��X�e�[�^�X����
        , it_kbn_1_rec.chain_code                   -- �`�F�[���X�R�[�h
        , it_kbn_1_rec.chain_name                   -- �`�F�[���X��
        , it_kbn_1_rec.shop_code                    -- �X�܃R�[�h
        , it_kbn_1_rec.shop_name                    -- �X�ܖ�
        , it_kbn_1_rec.customer_code                -- �ڋq�R�[�h
        , it_kbn_1_rec.customer_name                -- �ڋq��
        , it_kbn_1_rec.center_code                  -- �Z���^�[�R�[�h
        , it_kbn_1_rec.center_name                  -- �Z���^�[��
        , it_kbn_1_rec.area_code                    -- �n��R�[�h
        , it_kbn_1_rec.area_name                    -- �n�於��
        , it_kbn_1_rec.shipped_date                 -- �o�ד�
        , it_kbn_1_rec.arrival_date                 -- ����
        , gt_reserve_tab(i).item_div                -- ���i�敪
        , gt_reserve_tab(i).item_div_name           -- ���i�敪��
        , it_kbn_1_rec.parent_item_code             -- �e�i�ڃR�[�h
        , it_kbn_1_rec.parent_item_name             -- �e�i�ږ���
        , gt_reserve_tab(i).item_code               -- �q�i�ڃR�[�h
        , gt_reserve_tab(i).item_name               -- �q�i�ږ���
        , gt_reserve_tab(i).lot                     -- ���b�g
        , gt_reserve_tab(i).difference_summary_code -- �ŗL�L��
        , gt_reserve_tab(i).case_in_qty             -- ����
        , gt_reserve_tab(i).case_qty                -- �P�[�X��
        , gt_reserve_tab(i).singly_qty              -- �o����
        , gt_reserve_tab(i).summary_qty             -- ����
        , it_kbn_1_rec.regular_sale_class_line      -- ��ԓ����敪(����)
        , it_kbn_1_rec.regular_sale_class_name_line -- ��ԓ����敪��(����)
        , it_kbn_1_rec.edi_received_date            -- EDI��M��
        , it_kbn_1_rec.delivery_order_edi           -- �z����(EDI)
        , gt_order_summary_qty                      -- �����O�󒍐��ʁF�o�ג������s����悤�A�������_�̎󒍐��ʂ�ݒ肷��
        , gt_employee_number                        -- �������s�҃R�[�h
        , gv_employee_name                          -- �������s�Җ�
        , gt_reserve_tab(i).mark                    -- �L��
        , cv_lot_tran_kbn_0                         -- ���b�g�ʎ�����׍쐬�敪
        , it_kbn_1_rec.header_id                    -- �󒍃w�b�_ID
        , it_kbn_1_rec.line_id                      -- �󒍖���ID
        , it_kbn_1_rec.customer_id                  -- �ڋqID
        , it_kbn_1_rec.parent_item_id               -- �e�i��ID
        , gt_reserve_tab(i).item_id                 -- �q�i��ID
        , lt_tran_type_code                         -- ����������^�C�v�R�[�h
        , it_kbn_1_rec.order_quantity_uom           -- �󒍒P��
        , it_kbn_1_rec.ordered_quantity             -- �󒍐���
        , gt_reserve_tab(i).short_case_in_qty       -- �����i�s�����j
        , gt_reserve_tab(i).short_case_qty          -- �P�[�X���i�s�����j
        , gt_reserve_tab(i).short_singly_qty        -- �o�����i�s�����j
        , gt_reserve_tab(i).short_summary_qty       -- ���ʁi�s�����j
        , cn_created_by                             -- �쐬��
        , cd_creation_date                          -- �쐬��
        , cn_last_updated_by                        -- �ŏI�X�V��
        , cd_last_update_date                       -- �ŏI�X�V��
        , cn_last_update_login                      -- �ŏI�X�V���O�C��
        , cn_request_id                             -- �v��ID
        , cn_program_application_id                 -- �v���O�����A�v���P�[�V����ID
        , cn_program_id                             -- �v���O����ID
        , cd_program_update_date                    -- �v���O�����X�V��
      );
      -- �f�o�b�O�p
      IF ( gv_retcode = cv_status_normal ) THEN
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-12.3 ���b�g�ʈ������o�^��������' ||
                      ' �󒍔ԍ��F'                         || it_kbn_1_rec.order_number     ||
                      ' �e�i�ڃR�[�h�F'                     || it_kbn_1_rec.parent_item_code ||
                      ' �q�i�ڃR�[�h�F'                     || gt_reserve_tab(i).item_code
        );
      ELSE
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-12.3 ���b�g�ʈ������o�^��������' ||
                      ' �󒍔ԍ��F'                         || it_kbn_1_rec.order_number     ||
                      ' �e�i�ڃR�[�h�F'                     || it_kbn_1_rec.parent_item_code ||
                      ' �q�i�ڃR�[�h�F'                     || gt_reserve_tab(i).item_code
        );
      END IF;
    END LOOP ins_lot_reserve_loop;
    --
    -- ���������ݒ�
    IF ( gv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_normal_cnt + 1;
    -- ���s�����ݒ�
    ELSE
      gn_warn_cnt   := gn_warn_cnt + 1;
    END IF;
    --
    -- �z��폜�E�Y����������
    gn_reserve_cnt := 0;
    gt_reserve_tab.DELETE;
--
  EXCEPTION
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
  END ins_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : del_lot_reserve_info
   * Description      : ���b�g�ʈ������폜����(A-13)
   ***********************************************************************************/
  PROCEDURE del_lot_reserve_info(
      it_kbn_2_rec IN  g_kbn_2_cur%ROWTYPE -- �����������R�[�h
    , ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lot_reserve_info'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ώی����ݒ�
    -- ������
    IF ( it_kbn_2_rec.shipping_status = cv_shipping_status_10 ) THEN
      gn_target_10_cnt := gn_target_10_cnt + 1;
    -- ������
    ELSIF ( it_kbn_2_rec.shipping_status = cv_shipping_status_20 ) THEN
      gn_target_20_cnt := gn_target_20_cnt + 1;
    END IF;
    --
    --==============================================================
    -- 1�D���b�g�ʈ������폜
    --==============================================================
    DELETE FROM xxcoi_lot_reserve_info xlri
    WHERE       xlri.rowid = it_kbn_2_rec.xlri_rowid
    ;
    -- ���������ݒ�
    -- ������
    IF ( it_kbn_2_rec.shipping_status = cv_shipping_status_10 ) THEN
      gn_normal_10_cnt := gn_normal_10_cnt + 1;
    -- ������
    ELSIF ( it_kbn_2_rec.shipping_status = cv_shipping_status_20 ) THEN
      gn_normal_20_cnt := gn_normal_20_cnt + 1;
    END IF;
--
  EXCEPTION
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
  END del_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_reserve_info
   * Description      : ���b�g�ʈ������X�V����(A-14)
   ***********************************************************************************/
  PROCEDURE upd_lot_reserve_info(
      iv_lot_tran_kbn        IN  VARCHAR2 -- ���b�g�ʎ�����׍쐬�敪
    , in_lot_reserve_info_id IN  NUMBER   -- ���b�g�ʈ������ID
    , ov_errbuf              OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode             OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg              OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_reserve_info'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lt_parent_shipping_status       xxcoi_lot_reserve_info.parent_shipping_status%TYPE      DEFAULT NULL; -- �o�׏��X�e�[�^�X
    lt_parent_shipping_status_name  xxcoi_lot_reserve_info.parent_shipping_status_name%TYPE DEFAULT NULL; -- �o�׏��X�e�[�^�X��
    lt_lot_tran_kbn                 xxcoi_lot_reserve_info.lot_tran_kbn%TYPE                DEFAULT NULL; -- ���b�g�ʎ�����׍쐬�敪
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �o�׉��m��A�o�׊m��̏ꍇ
    IF ( ( gv_kbn = cv_kbn_3 ) OR ( gv_kbn = cv_kbn_4 ) ) THEN
      -- �o�׉��m��̏ꍇ
      IF ( gv_kbn = cv_kbn_3 ) THEN
        lt_parent_shipping_status      := cv_shipping_status_25;
        lt_parent_shipping_status_name := gt_shipping_status_25;
      -- �o�׊m��̏ꍇ
      ELSIF ( gv_kbn = cv_kbn_4 ) THEN
        lt_parent_shipping_status      := cv_shipping_status_30;
        lt_parent_shipping_status_name := gt_shipping_status_30;
        -- ���쐬�̏ꍇ
        IF ( iv_lot_tran_kbn = cv_lot_tran_kbn_0 ) THEN
          lt_lot_tran_kbn              := cv_lot_tran_kbn_1;
        END IF;
      END IF;
      --==============================================================
      -- 1�D���b�g�ʈ������X�V�i�o�׉��m��A�o�׊m��j
      --==============================================================
      UPDATE xxcoi_lot_reserve_info xlri
      SET    xlri.parent_shipping_status      = lt_parent_shipping_status             -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
           , xlri.parent_shipping_status_name = lt_parent_shipping_status_name        -- �o�׏��X�e�[�^�X���i�󒍔ԍ��P�ʁj
           , xlri.shipping_status             = lt_parent_shipping_status             -- �o�׏��X�e�[�^�X
           , xlri.shipping_status_name        = lt_parent_shipping_status_name        -- �o�׏��X�e�[�^�X��
           , xlri.lot_tran_kbn                = CASE WHEN lt_lot_tran_kbn IS NOT NULL
                                                     THEN lt_lot_tran_kbn
                                                     ELSE xlri.lot_tran_kbn
                                                END                                   -- ���b�g�ʎ�����׍쐬�敪
           , xlri.last_updated_by             = cn_last_updated_by                   -- �ŏI�X�V��
           , xlri.last_update_date            = cd_last_update_date                  -- �ŏI�X�V��
           , xlri.last_update_login           = cn_last_update_login                 -- �ŏI�X�V���O�C��
           , xlri.request_id                  = cn_request_id                        -- �v��ID
           , xlri.program_application_id      = cn_program_application_id            -- �v���O�����A�v���P�[�V����ID
           , xlri.program_id                  = cn_program_id                        -- �v���O����ID
           , xlri.program_update_date         = cd_program_update_date               -- �v���O�����X�V��
      WHERE  xlri.lot_reserve_info_id         = in_lot_reserve_info_id               -- ���b�g�ʈ������ID
      ;
    -- ���m�������̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_6 ) THEN
      --==============================================================
      -- 2�D���b�g�ʈ������X�V�i���m�������j
      --==============================================================
      << upd_id_loop >>
      FOR i IN 1 .. gt_lot_id_tab.COUNT LOOP
        UPDATE xxcoi_lot_reserve_info xlri
        SET    xlri.lot_tran_kbn                = cv_lot_tran_kbn_9         -- ���b�g�ʎ�����׍쐬�敪
             , xlri.last_updated_by             = cn_last_updated_by        -- �ŏI�X�V��
             , xlri.last_update_date            = cd_last_update_date       -- �ŏI�X�V��
             , xlri.last_update_login           = cn_last_update_login      -- �ŏI�X�V���O�C��
             , xlri.request_id                  = cn_request_id             -- �v��ID
             , xlri.program_application_id      = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
             , xlri.program_id                  = cn_program_id             -- �v���O����ID
             , xlri.program_update_date         = cd_program_update_date    -- �v���O�����X�V��
        WHERE  xlri.lot_reserve_info_id         = gt_lot_id_tab(i)          -- ���b�g�ʈ������ID
        ;
      END LOOP upd_id_loop;
    END IF;
--
  EXCEPTION
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
  END upd_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_reserve_info2
   * Description      : ���b�g�ʈ������X�V�����i�o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj�j(A-15)
   ***********************************************************************************/
  PROCEDURE upd_lot_reserve_info2(
      ov_errbuf    OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_reserve_info2'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �o�׏��X�e�[�^�X����^
    TYPE l_shipping_status_rec IS RECORD(
        order_number        xxcoi_lot_reserve_info.order_number%TYPE     -- �󒍔ԍ�
      , shipping_status     xxcoi_lot_reserve_info.shipping_status%TYPE  -- �o�׏��X�e�[�^�X
    );
    TYPE l_shipping_status_type IS TABLE OF l_shipping_status_rec INDEX BY BINARY_INTEGER;
    l_shipping_status_tab   l_shipping_status_type;
    -- *** ���[�J���J�[�\�� ***
    -- �󒍔ԍ��J�[�\��
    CURSOR l_order_number_cur( in_request_id NUMBER )
    IS
      SELECT DISTINCT
             xlri.order_number      AS order_number
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.request_id = in_request_id
      ORDER BY xlri.order_number
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
    --==============================================================
    -- 1�D�o�׏��X�e�[�^�X����
    --==============================================================
    << order_number_loop >>
    FOR l_order_number_rec IN l_order_number_cur( in_request_id => cn_request_id ) LOOP
      -- �󒍔ԍ��Əo�׏��X�e�[�^�X�P�ʁF�����ρ��������̏��Ń\�[�g
      SELECT xlri.order_number      AS order_number
           , xlri.shipping_status   AS shipping_status
      BULK COLLECT INTO l_shipping_status_tab
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status IN ( cv_shipping_status_10, cv_shipping_status_20 )
      AND    xlri.order_number = l_order_number_rec.order_number
      GROUP BY xlri.order_number
             , xlri.shipping_status
      ORDER BY xlri.order_number
             , xlri.shipping_status DESC
      ;
      --==============================================================
      -- 2�D���b�g�ʈ������X�V�i�������A�����ρj
      --==============================================================
      -- �X�V���[�v
      << upd_loop >>
      FOR i IN 1 .. l_shipping_status_tab.COUNT LOOP
        -- �����R�[�h�������ꍇ�i�󒍔ԍ����؂�ւ�����ꍇ�j
        IF ( l_shipping_status_tab.NEXT(i) IS NULL ) THEN
          -- ���s���R�[�h�̒l�ōX�V
          UPDATE xxcoi_lot_reserve_info xlri
          SET    xlri.parent_shipping_status      = l_shipping_status_tab(i).shipping_status               -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
               , xlri.parent_shipping_status_name = DECODE( l_shipping_status_tab(i).shipping_status
                                                          , cv_shipping_status_10, gt_shipping_status_10
                                                          , cv_shipping_status_20, gt_shipping_status_20 ) -- �o�׏��X�e�[�^�X���i�󒍔ԍ��P�ʁj
               , xlri.last_updated_by             = cn_last_updated_by                                     -- �ŏI�X�V��
               , xlri.last_update_date            = cd_last_update_date                                    -- �ŏI�X�V��
               , xlri.last_update_login           = cn_last_update_login                                   -- �ŏI�X�V���O�C��
               , xlri.request_id                  = cn_request_id                                          -- �v��ID
               , xlri.program_application_id      = cn_program_application_id                              -- �v���O�����A�v���P�[�V����ID
               , xlri.program_id                  = cn_program_id                                          -- �v���O����ID
               , xlri.program_update_date         = cd_program_update_date                                 -- �v���O�����X�V��
          WHERE  xlri.order_number                = l_shipping_status_tab(i).order_number                  -- �󒍔ԍ�
          ;
        END IF;
        --
      END LOOP upd_loop;
      --
    END LOOP order_number_loop;
--
  EXCEPTION
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
  END upd_lot_reserve_info2;
--
  /**********************************************************************************
   * Procedure Name   : upd_xcc
   * Description      : �f�[�^�A�g����e�[�u���X�V����(A-18)
   ***********************************************************************************/
  PROCEDURE upd_xcc(
      ov_errbuf              OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode             OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg              OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xcc'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lt_transaction_id        xxcoi_cooperation_control.transaction_id%TYPE DEFAULT NULL; -- �󒍃w�b�_ID
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- Mod Ver1.1 Start
--    --==============================================================
--    -- 1�D�󒍃w�b�_ID�擾
--    --==============================================================
--    SELECT MAX(ooha.header_id)  AS header_id
--    INTO   lt_transaction_id
--    FROM   oe_order_headers_all ooha
--    WHERE  ooha.header_id > gt_max_header_id
--    AND    ooha.org_id     = gt_org_id
--    ;
--    --==============================================================
--    -- 2�D�f�[�^�A�g����e�[�u���X�V
--    --==============================================================
--    UPDATE xxcoi_cooperation_control xcc
--    SET    xcc.last_cooperation_date  = gd_process_date           -- �Ɩ����t
--         , xcc.transaction_id         = lt_transaction_id         -- �󒍃w�b�_ID
--         , xcc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
--         , xcc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
--         , xcc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
--         , xcc.request_id             = cn_request_id             -- �v��ID
--         , xcc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
--         , xcc.program_id             = cn_program_id             -- �v���O����ID
--         , xcc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
--    WHERE  xcc.program_short_name     = cv_pkg_name
--    ;
    -- �o�׊m��̏ꍇ
    IF ( gv_kbn = cv_kbn_4 ) THEN
      --==============================================================
      -- 1�D�󒍃w�b�_ID�擾
      --==============================================================
      SELECT MIN(ooha.header_id)  AS header_id
      INTO   lt_transaction_id
      FROM   oe_order_headers_all ooha
           , oe_order_lines_all   oola
      WHERE  ooha.header_id     = oola.header_id
      AND    ooha.org_id        = gt_org_id
      AND    ooha.ordered_date >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c1 * -1))
      AND    ooha.ordered_date <  gd_process_date + 1
      AND    oola.request_date >= gd_process_date + 1
      ;
      --==============================================================
      -- 2�D�f�[�^�A�g����e�[�u���X�V
      --==============================================================
      UPDATE xxcoi_cooperation_control xcc
      SET    xcc.last_cooperation_date  = gd_process_date           -- �Ɩ����t
           , xcc.transaction_id         = CASE WHEN ( lt_transaction_id IS NOT NULL )
                                               THEN lt_transaction_id - 1
                                               ELSE xcc.transaction_id
                                          END                       -- �󒍃w�b�_ID
           , xcc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           , xcc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           , xcc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           , xcc.request_id             = cn_request_id             -- �v��ID
           , xcc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           , xcc.program_id             = cn_program_id             -- �v���O����ID
           , xcc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE  xcc.program_short_name     = cv_pkg_name2
      ;
    -- �ԕi�E�����E�ߋ��f�[�^�̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_5 ) THEN
      --==============================================================
      -- 1�D�󒍃w�b�_ID�擾
      --==============================================================
      SELECT MIN(ooha.header_id)  AS header_id
      INTO   lt_transaction_id
      FROM   oe_order_headers_all ooha
      WHERE  ooha.org_id         = gt_org_id
      AND    ooha.ordered_date  >= ADD_MONTHS(gd_process_date, (gt_period_xxcoi016a06c5 * -1))
      AND    ooha.ordered_date  <  gd_process_date + 1
      ;
      --==============================================================
      -- 2�D�f�[�^�A�g����e�[�u���X�V
      --==============================================================
      UPDATE xxcoi_cooperation_control xcc
      SET    xcc.last_cooperation_date  = gd_process_date           -- �Ɩ����t
           , xcc.transaction_id         = CASE WHEN ( lt_transaction_id IS NOT NULL )
                                               THEN lt_transaction_id - 1
                                               ELSE xcc.transaction_id
                                          END                       -- �󒍃w�b�_ID
           , xcc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
           , xcc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
           , xcc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
           , xcc.request_id             = cn_request_id             -- �v��ID
           , xcc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
           , xcc.program_id             = cn_program_id             -- �v���O����ID
           , xcc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE  xcc.program_short_name     = cv_pkg_name
      ;
    END IF;
-- Mod Ver1.1 End
--
  EXCEPTION
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
  END upd_xcc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf                 OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                 OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , iv_login_base_code        IN  VARCHAR2 -- ���_
    , iv_delivery_date_from     IN  VARCHAR2 -- ����From
    , iv_delivery_date_to       IN  VARCHAR2 -- ����To
    , iv_login_chain_store_code IN  VARCHAR2 -- �`�F�[���X
    , iv_login_customer_code    IN  VARCHAR2 -- �ڋq
    , iv_customer_po_number     IN  VARCHAR2 -- �ڋq�����ԍ�
    , iv_subinventory_code      IN  VARCHAR2 -- �ۊǏꏊ
    , iv_priority_flag          IN  VARCHAR2 -- �D�惍�P�[�V�����g�p
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ���b�g�t�]��
    , iv_kbn                    IN  VARCHAR2 -- ����敪
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
    -- *** ���[�J���ϐ� ***
    lt_order_number         xxcoi_tmp_lot_reserve_info.order_number%TYPE DEFAULT NULL; -- �󒍔ԍ�
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
    gn_target_cnt      := 0; -- �Ώی���
    gn_normal_cnt      := 0; -- ���팏��
    gn_warn_cnt        := 0; -- �X�L�b�v����
    gn_error_cnt       := 0; -- �G���[����
    gn_target_10_cnt   := 0; -- �Ώی����i�������j
    gn_target_20_cnt   := 0; -- �Ώی����i�����ρj
    gn_normal_10_cnt   := 0; -- ���������i�������j
    gn_normal_20_cnt   := 0; -- ���������i�����ρj
    gn_create_temp_cnt := 0; -- ���b�g�ʎ��TEMP�쐬����
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
        iv_login_base_code        => iv_login_base_code        -- ���_
      , iv_delivery_date_from     => iv_delivery_date_from     -- ����From
      , iv_delivery_date_to       => iv_delivery_date_to       -- ����To
      , iv_login_chain_store_code => iv_login_chain_store_code -- �`�F�[���X
      , iv_login_customer_code    => iv_login_customer_code    -- �ڋq
      , iv_customer_po_number     => iv_customer_po_number     -- �ڋq�����ԍ�
      , iv_subinventory_code      => iv_subinventory_code      -- �ۊǏꏊ
      , iv_priority_flag          => iv_priority_flag          -- �D�惍�P�[�V�����g�p
      , iv_lot_reversal_flag      => iv_lot_reversal_flag      -- ���b�g�t�]��
      , iv_kbn                    => iv_kbn                    -- ����敪
      , ov_errbuf                 => lv_errbuf                 -- �G���[�E���b�Z�[�W
      , ov_retcode                => lv_retcode                -- ���^�[���E�R�[�h
      , ov_errmsg                 => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���_�R�[�h��NOT NULL�̏ꍇ�i�������s�j
    IF ( gv_login_base_code IS NOT NULL ) THEN
      -- ===============================================
      -- ���b�N���䏈��(A-2)
      -- ===============================================
      get_lock(
          ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================================
    -- ���b�g�ʈ������擾����(A-3)
    -- ===============================================
    -- �eA-4�����̑O�Ŏ��{
--
    -- �����̏ꍇ
    IF ( gv_kbn = cv_kbn_1 ) THEN
      --==============================================================
      -- 1�D�󒍃w�b�_ID�擾
      --==============================================================
-- Mod Ver1.1 Start
--      SELECT MAX(xlri.header_id)    AS header_id
--      INTO   gt_max_header_id
--      FROM   xxcoi_lot_reserve_info xlri
--      WHERE  xlri.parent_shipping_status = cv_shipping_status_30
--      AND    xlri.base_code              = gv_login_base_code
--      AND    xlri.arrival_date           < gd_delivery_date_from
--      AND    xlri.header_id IS NOT NULL
--      ;
--      --
--      IF ( gt_max_header_id IS NULL ) THEN
--        -- �󒍃w�b�_ID�擾�G���[���b�Z�[�W
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application
--                       , iv_name         => cv_msg_xxcoi_10539
--                       , iv_token_name1  => cv_tkn_base_code
--                       , iv_token_value1 => gv_login_base_code
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END IF;
      BEGIN
        SELECT xcc.transaction_id        AS transaction_id
        INTO   gt_max_header_id
        FROM   xxcoi_cooperation_control xcc
        WHERE  xcc.program_short_name = cv_pkg_name2
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �󒍃w�b�_ID�擾�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10539
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
-- Mod Ver1.1 End
      --
      --==============================================================
      -- 2�D�����ΏۊO�f�[�^�擾�o�^
      --==============================================================
      INSERT INTO xxcoi_tmp_lot_reserve_na(
          header_id -- �w�b�_ID
        , line_id   -- ����ID
      )
      SELECT DISTINCT
             xlri.header_id         AS header_id
           , xlri.line_id           AS line_id
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status IN ( cv_shipping_status_20, cv_shipping_status_25, cv_shipping_status_30 )
      AND    xlri.base_code        = gv_login_base_code
      AND    xlri.arrival_date    >= gd_delivery_date_from
      AND    xlri.arrival_date    <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xlri.chain_code      = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( xlri.customer_code   = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( xlri.slip_num        = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = xlri.whse_code )
      AND    xlri.header_id IS NOT NULL
      ;
      -- �f�o�b�O�p
      SELECT COUNT(1)
      INTO   gn_debug_cnt
      FROM   xxcoi_tmp_lot_reserve_na
      ;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.2 ���b�g�ʈ����ΏۊO�ꎞ�\�o�^�����F' || gn_debug_cnt
      );
      --
      --==============================================================
      -- 3�D�������f�[�^�폜�擾�o�^
      --==============================================================
      DELETE FROM xxcoi_lot_reserve_info xlri
      WHERE  xlri.shipping_status  = cv_shipping_status_10
      AND    xlri.base_code        = gv_login_base_code
      AND    xlri.arrival_date    >= gd_delivery_date_from
      AND    xlri.arrival_date    <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xlri.chain_code      = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( xlri.customer_code   = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( xlri.slip_num        = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = xlri.whse_code )
      ;
      -- �f�o�b�O�p
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.3 �������f�[�^�폜�����F' || SQL%ROWCOUNT
      );
      --
      -- ===============================================
      -- �����Ώۃf�[�^�擾����(A-4)
      -- ===============================================
      get_reserve_data(
          ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- �����Ώۃ��[�v
      << kbn_1_loop >>
      FOR l_kbn_1_rec IN g_kbn_1_cur LOOP
        -- ������
        gv_retcode := cv_status_normal;
        -- �Ώی����ݒ�
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ===============================================
        -- �����Ώۃf�[�^�`�F�b�N����(A-5)
        -- ===============================================
        chk_reserve_data(
            it_kbn_1_rec => l_kbn_1_rec -- �������R�[�h
          , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- �q�i�ڏ��擾����(A-6)
        -- ===============================================
        get_item(
            it_kbn_1_rec => l_kbn_1_rec -- �������R�[�h
          , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- �����Ώۍ݌ɔ��菈��(A-7)
        -- ===============================================
        inventory_reservation(
            it_kbn_1_rec => l_kbn_1_rec -- �������R�[�h
          , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          gv_retcode := cv_status_warn;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- ���b�g�ʈ������o�^����(A-12)
        -- ===============================================
        ins_lot_reserve_info(
            it_kbn_1_rec => l_kbn_1_rec -- �������R�[�h
          , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP kbn_1_loop;
      --
      -- �Ώی��������݂���ꍇ
      IF ( gn_target_cnt > 0 ) THEN
        -- ===============================================
        -- ���b�g�ʈ������X�V�����i�o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj�j(A-15)
        -- ===============================================
        upd_lot_reserve_info2(
            ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
--
    -- ���������̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_2 ) THEN
      --==============================================================
      -- 1�D���������Ώۃf�[�^�擾
      --==============================================================
      -- �����������[�v
      << kbn_2_loop >>
      FOR l_kbn_2_rec IN g_kbn_2_cur LOOP
        -- ===============================================
        -- ���b�g�ʈ������폜����(A-13)
        -- ===============================================
        del_lot_reserve_info(
            it_kbn_2_rec => l_kbn_2_rec -- �����������R�[�h
          , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP kbn_2_loop;
--
    -- �o�׉��m��̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_3 ) THEN
      --==============================================================
      -- 1�D�o�׉��m��Ώۃf�[�^�擾
      --==============================================================
      -- �o�׉��m�胋�[�v
      << kbn_3_loop >>
      FOR l_kbn_3_rec IN g_kbn_3_cur LOOP
        -- �Ώی����ݒ�
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- �󒍃w�b�_ID�����ݒ�i�����������A�b�v���[�h�ł̐V�K�o�^�j
        IF ( l_kbn_3_rec.header_id IS NULL ) THEN
          -- ������
          gv_retcode      := cv_status_normal;
        -- �󒍃w�b�_ID���ݒ肳��Ă���A���񃌃R�[�h�܂��͎󒍔ԍ����؂�ւ�����ꍇ
        ELSIF ( ( l_kbn_3_rec.header_id IS NOT NULL )
          AND   ( ( lt_order_number IS NULL ) OR ( lt_order_number <> l_kbn_3_rec.order_number ) ) ) THEN
          -- ������
          gv_retcode      := cv_status_normal;
          -- �󒍔ԍ��ݒ�
          lt_order_number := l_kbn_3_rec.order_number;
          --
          -- ===============================================
          -- �󒍒����`�F�b�N����(A-8)
          -- ===============================================
          -- ���������œ���󒍔ԍ��̃��R�[�h��S�ă`�F�b�N����
          chk_order(
              iv_order_number           => l_kbn_3_rec.order_number -- �󒍔ԍ�
-- Add Ver1.3 Start
            , iv_parent_shipping_status => l_kbn_3_rec.parent_shipping_status -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
-- Add Ver1.3 End
            , ov_errbuf                 => lv_errbuf                -- �G���[�E���b�Z�[�W
            , ov_retcode                => lv_retcode               -- ���^�[���E�R�[�h
            , ov_errmsg                 => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            gv_retcode := cv_status_warn;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
        -- ����󒍔ԍ��̃��R�[�h������̏ꍇ
        -- �`�F�b�N��A-8�Ŏ��{��
        IF ( gv_retcode = cv_status_normal ) THEN
-- Add Ver1.3 Start
          -- ID��ێ����Ă���ꍇ
          IF ( g_del_id_tab.EXISTS( l_kbn_3_rec.lot_reserve_info_id ) ) THEN
            -- ���b�g�ʈ������폜
            DELETE FROM xxcoi_lot_reserve_info xlri
            WHERE  xlri.lot_reserve_info_id = l_kbn_3_rec.lot_reserve_info_id
            ;
          ELSE
-- Add Ver1.3 End
            -- ===============================================
            -- ���b�g���ێ��}�X�^���f����(A-11)
            -- ===============================================
            ref_mst_lot_hold_info(
                it_kbn_3_rec => l_kbn_3_rec -- �o�׊m�背�R�[�h
              , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
              , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
              , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            --
            -- ===============================================
            -- ���b�g�ʈ������X�V����(A-14)
            -- ===============================================
            upd_lot_reserve_info(
                iv_lot_tran_kbn        => NULL                            -- ���b�g�ʎ�����׍쐬�敪
              , in_lot_reserve_info_id => l_kbn_3_rec.lot_reserve_info_id -- ���b�g�ʈ������ID
              , ov_errbuf              => lv_errbuf                       -- �G���[�E���b�Z�[�W
              , ov_retcode             => lv_retcode                      -- ���^�[���E�R�[�h
              , ov_errmsg              => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
-- Add Ver1.3 Start
          END IF;
-- Add Ver1.3 End
          --
          -- �����ݒ�
          -- ���펞
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          -- ���s��
          gn_warn_cnt   := gn_warn_cnt + 1;
        END IF;
      END LOOP kbn_3_loop;
--
    -- �o�׊m��̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_4 ) THEN
-- Mod Ver1.1 Start
--      -- �o�׊m�胋�[�v
--      << kbn_4_loop >>
--      FOR l_kbn_4_rec IN g_kbn_4_cur LOOP
--        -- �Ώی����ݒ�
--        gn_target_cnt := gn_target_cnt + 1;
      -- �o�׊m��X�V���[�v
      << kbn_4_2_loop >>
      FOR l_kbn_4_2_rec IN g_kbn_4_2_cur LOOP
        -- �Ώی����ݒ�
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ===============================================
        -- ���b�g�ʈ������X�V����(A-14)
        -- ===============================================
        upd_lot_reserve_info(
            iv_lot_tran_kbn        => l_kbn_4_2_rec.lot_tran_kbn        -- ���b�g�ʎ�����׍쐬�敪
          , in_lot_reserve_info_id => l_kbn_4_2_rec.lot_reserve_info_id -- ���b�g�ʈ������ID
          , ov_errbuf              => lv_errbuf                         -- �G���[�E���b�Z�[�W
          , ov_retcode             => lv_retcode                        -- ���^�[���E�R�[�h
          , ov_errmsg              => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      END LOOP kbn_4_2_loop;
-- Mod Ver1.1 End
      --
      -- �o�׊m�胋�[�v
      << kbn_4_loop >>
      FOR l_kbn_4_rec IN g_kbn_4_cur LOOP
-- Del Ver1.1 Start
--        -- ���쐬�̏ꍇ
--        IF ( l_kbn_4_rec.lot_tran_kbn = cv_lot_tran_kbn_0 ) THEN
-- Del Ver1.1 End
        -- ===============================================
        -- ���b�g�ʎ�����דo�^����(A-9)
        -- ===============================================
        ins_lot_transactions(
            it_kbn_4_rec => l_kbn_4_rec -- �o�׊m�背�R�[�h
          , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================================
        -- ���b�g�ʎ莝���ʔ��f����(A-10)
        -- ===============================================
        ref_lot_onhand(
            it_kbn_4_rec => l_kbn_4_rec -- �o�׊m�背�R�[�h
          , ov_errbuf    => lv_errbuf   -- �G���[�E���b�Z�[�W
          , ov_retcode   => lv_retcode  -- ���^�[���E�R�[�h
          , ov_errmsg    => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
-- Mod Ver1.1 Start
--          --
--        END IF;
--        -- ===============================================
--        -- ���b�g�ʈ������X�V����(A-14)
--        -- ===============================================
--        upd_lot_reserve_info(
--            iv_lot_tran_kbn        => l_kbn_4_rec.lot_tran_kbn        -- ���b�g�ʎ�����׍쐬�敪
--          , in_lot_reserve_info_id => l_kbn_4_rec.lot_reserve_info_id -- ���b�g�ʈ������ID
--          , ov_errbuf              => lv_errbuf                       -- �G���[�E���b�Z�[�W
--          , ov_retcode             => lv_retcode                      -- ���^�[���E�R�[�h
--          , ov_errmsg              => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
--        );
-- Mod Ver1.1 End
        -- ���펞
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP kbn_4_loop;
-- Add Ver1.1 Start
      -- ===============================================
      -- �f�[�^�A�g����e�[�u���X�V����(A-18)
      -- ===============================================
      upd_xcc(
          ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- Add Ver1.1 End
--
    -- �ԕi�E�����E�ߋ��f�[�^
    ELSIF ( gv_kbn = cv_kbn_5 ) THEN
      --==============================================================
      -- 1�D�󒍃w�b�_ID�擾
      --==============================================================
-- Mod Ver1.1 Start
--      -- ���_�R�[�h��NULL�̏ꍇ�i������s�j
--      IF ( gv_login_base_code IS NULL ) THEN
--        BEGIN
--          SELECT xcc.transaction_id        AS transaction_id
--          INTO   gt_max_header_id
--          FROM   xxcoi_cooperation_control xcc
--          WHERE  xcc.program_short_name = cv_pkg_name
--          ;
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            -- �󒍃w�b�_ID�擾�G���[���b�Z�[�W
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                             iv_application  => cv_application
--                           , iv_name         => cv_msg_xxcoi_10539
--                           , iv_token_name1  => cv_tkn_base_code
--                           , iv_token_value1 => gv_login_base_code
--                         );
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
--        END;
      BEGIN
        SELECT xcc.transaction_id        AS transaction_id
        INTO   gt_max_header_id
        FROM   xxcoi_cooperation_control xcc
        WHERE  xcc.program_short_name = cv_pkg_name
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �󒍃w�b�_ID�擾�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                         , iv_name         => cv_msg_xxcoi_10539
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- ���_�R�[�h��NULL�̏ꍇ�i������s�j
      IF ( gv_login_base_code IS NULL ) THEN
-- Mod Ver1.1 End
        -- ���b�g�ʈ����ۊǏꏊ�ꎞ�\�o�^
        INSERT INTO xxcoi_tmp_lot_reserve_subinv(
          subinventory_code -- �ۊǏꏊ�R�[�h
        )
        SELECT msi.secondary_inventory_name AS secondary_inventory_name
        FROM   mtl_secondary_inventories    msi
        WHERE  msi.attribute14     = cv_flag_y
        AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
        AND    msi.organization_id = gt_organization_id
        ;
        -- �f�o�b�O�p
        SELECT COUNT(1)
        INTO   gn_debug_cnt
        FROM   xxcoi_tmp_lot_reserve_subinv
        ;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-3 ���b�g�ʈ����ۊǏꏊ�ꎞ�\�o�^�����F' || gn_debug_cnt
        );
-- Del Ver1.1 Start
--      -- ���_�R�[�h��NOT NULL�̏ꍇ�i�������s�j
--      ELSE
--        SELECT MAX(xlri.header_id)    AS header_id
--        INTO   gt_max_header_id
--        FROM   xxcoi_lot_reserve_info xlri
--        WHERE  xlri.parent_shipping_status = cv_shipping_status_30
--        AND    xlri.base_code              = gv_login_base_code
--        AND    xlri.arrival_date           < gd_delivery_date_from
--        AND    xlri.header_id IS NOT NULL
--        ;
--        --
--        IF ( gt_max_header_id IS NULL ) THEN
--          -- �󒍃w�b�_ID�擾�G���[���b�Z�[�W
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_application
--                         , iv_name         => cv_msg_xxcoi_10539
--                         , iv_token_name1  => cv_tkn_base_code
--                         , iv_token_value1 => gv_login_base_code
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
-- Del Ver1.1 End
      END IF;
      --
      --==============================================================
      -- 2�D�����f�[�^�擾�o�^
      --==============================================================
      INSERT INTO xxcoi_tmp_lot_reserve_na(
          header_id -- �w�b�_ID
        , line_id   -- ����ID
      )
      SELECT DISTINCT
             xlri.header_id         AS header_id
           , xlri.line_id           AS line_id
      FROM   xxcoi_lot_reserve_info xlri
      WHERE  xlri.base_code        = gv_login_base_code
      AND    xlri.arrival_date    >= gd_delivery_date_from
      AND    xlri.arrival_date    <  gd_delivery_date_to + 1
      AND ( ( gv_login_chain_store_code IS NULL )
         OR ( xlri.chain_code      = gv_login_chain_store_code ) )
      AND ( ( gv_login_customer_code IS NULL )
         OR ( xlri.customer_code   = gv_login_customer_code ) )
      AND ( ( gv_customer_po_number IS NULL )
         OR ( xlri.slip_num        = gv_customer_po_number ) )
      AND EXISTS ( SELECT 1
                   FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                   WHERE  xtlrs.subinventory_code = xlri.whse_code )
      AND    xlri.header_id IS NOT NULL
      ;
      -- �f�o�b�O�p
      SELECT COUNT(1)
      INTO   gn_debug_cnt
      FROM   xxcoi_tmp_lot_reserve_na
      ;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.2 �����ΏۊO�����F' || gn_debug_cnt
      );
      --
      -- ===============================================
      -- �����ȊO�f�[�^�擾����(A-17)
      -- ===============================================
      get_reserve_other_data(
          ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ���_�R�[�h��NULL�̏ꍇ�i������s�j
      IF ( gv_login_base_code IS NULL ) THEN
        -- ===============================================
        -- �f�[�^�A�g����e�[�u���X�V����(A-18)
        -- ===============================================
        upd_xcc(
            ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
          , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
          , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    -- ���m�������̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_6 ) THEN
      --==============================================================
      -- 6�D�o�׉��m��f�[�^�擾
      --==============================================================
      -- ���_�R�[�h��NOT NULL�̏ꍇ�i�������s�j
      IF ( gv_login_base_code IS NOT NULL ) THEN
        SELECT DISTINCT
               xlri.order_number          AS order_number
        BULK COLLECT INTO gt_order_number_tab
        FROM   xxcoi_lot_reserve_info     xlri
        WHERE  xlri.shipping_status  = cv_shipping_status_25
        AND    xlri.base_code        = gv_login_base_code
        AND    xlri.arrival_date    >= gd_delivery_date_from
        AND    xlri.arrival_date    <  gd_delivery_date_to + 1
        AND ( ( gv_login_chain_store_code IS NULL )
           OR ( xlri.chain_code      = gv_login_chain_store_code ) )
        AND ( ( gv_login_customer_code IS NULL )
           OR ( xlri.customer_code   = gv_login_customer_code ) )
        AND ( ( gv_customer_po_number IS NULL )
           OR ( xlri.slip_num        = gv_customer_po_number ) )
        AND EXISTS ( SELECT 1
                     FROM   xxcoi_tmp_lot_reserve_subinv xtlrs
                     WHERE  xtlrs.subinventory_code = xlri.whse_code )
        AND    xlri.header_id IS NOT NULL
        ORDER BY xlri.order_number
        ;
      -- ���_�R�[�h��NULL�̏ꍇ�i������s�j
      ELSE
        SELECT DISTINCT
               xlri.order_number          AS order_number
        BULK COLLECT INTO gt_order_number_tab
        FROM   xxcoi_lot_reserve_info     xlri
        WHERE  xlri.shipping_status  = cv_shipping_status_25
        AND    xlri.arrival_date    >= gd_delivery_date_from
        AND    xlri.arrival_date    <  gd_delivery_date_to + 1
        AND    xlri.header_id IS NOT NULL
        ;
        --
        -- ���b�g�ʈ����ۊǏꏊ�ꎞ�\�o�^
        INSERT INTO xxcoi_tmp_lot_reserve_subinv(
          subinventory_code -- �ۊǏꏊ�R�[�h
        )
        SELECT msi.secondary_inventory_name AS secondary_inventory_name
        FROM   mtl_secondary_inventories    msi
        WHERE  msi.attribute14     = cv_flag_y
        AND    NVL(msi.disable_date, gd_process_date + 1) > gd_process_date
        AND    msi.organization_id = gt_organization_id
        ;
        -- �f�o�b�O�p
        SELECT COUNT(1)
        INTO   gn_debug_cnt
        FROM   xxcoi_tmp_lot_reserve_subinv
        ;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => 'A-3 ���b�g�ʈ����ۊǏꏊ�ꎞ�\�o�^�����F' || gn_debug_cnt
        );
      END IF;
      -- �f�o�b�O�p
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => 'A-3.6 �o�׉��m�茏���F' || gt_order_number_tab.COUNT
      );
      --
      -- �Ώ�0�����b�Z�[�W���\�����邽��
      gn_target_cnt := gt_order_number_tab.COUNT;
      --
      << g_kbn_6_loop>>
      FOR i IN 1 .. gt_order_number_tab.COUNT LOOP
        -- ===============================================
        -- �󒍒����`�F�b�N����(A-8)
        -- ===============================================
        chk_order(
            iv_order_number           => gt_order_number_tab(i) -- �󒍔ԍ�
-- Add Ver1.3 Start
          , iv_parent_shipping_status => NULL                   -- �o�׏��X�e�[�^�X�i�󒍔ԍ��P�ʁj
-- Add Ver1.3 End
          , ov_errbuf                 => lv_errbuf              -- �G���[�E���b�Z�[�W
          , ov_retcode                => lv_retcode             -- ���^�[���E�R�[�h
          , ov_errmsg                 => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ���b�g�ʎ��TEMP��o�^�����ꍇ
        IF ( gt_lot_id_tab.COUNT > 0 ) THEN
          -- ===============================================
          -- ���b�g�ʈ������X�V����(A-14)
          -- ===============================================
          upd_lot_reserve_info(
              iv_lot_tran_kbn        => NULL       -- ���b�g�ʎ�����׍쐬�敪
            , in_lot_reserve_info_id => NULL       -- ���b�g�ʈ������ID
            , ov_errbuf              => lv_errbuf  -- �G���[�E���b�Z�[�W
            , ov_retcode             => lv_retcode -- ���^�[���E�R�[�h
            , ov_errmsg              => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
      END LOOP g_kbn_6_loop;
      --
      -- �o�׉��m��f�[�^�͑��݂��邪�A���b�g�ʎ��TEMP�쐬������0���̏ꍇ
      IF ( ( gn_target_cnt > 0 ) AND ( gn_create_temp_cnt = 0 ) ) THEN
        -- �����Ώۃf�[�^�������b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcoi_10660
                     );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg
        );
      END IF;
    END IF;
--
    -- �Ώی���0���̏ꍇ
    IF ( ( gn_target_cnt = 0 ) AND ( gn_target_10_cnt = 0 ) AND ( gn_target_20_cnt = 0 ) AND ( gn_create_temp_cnt = 0 ) ) THEN
      -- �����Ώۃf�[�^�������b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcoi_10540
                     , iv_token_name1  => cv_tkn_process
                     , iv_token_value1 => gt_xxcoi016a06_kbn
                   );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg
      );
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
      IF ( g_kbn_1_cur%ISOPEN ) THEN
        CLOSE g_kbn_1_cur;
      ELSIF ( g_kbn_2_cur%ISOPEN ) THEN
        CLOSE g_kbn_2_cur;
      ELSIF ( g_kbn_3_cur%ISOPEN ) THEN
        CLOSE g_kbn_3_cur;
      ELSIF ( g_kbn_4_cur%ISOPEN ) THEN
        CLOSE g_kbn_4_cur;
      END IF;
-- Mod Ver1.1 Start
      IF ( g_kbn_4_2_cur%ISOPEN ) THEN
        CLOSE g_kbn_4_2_cur;
      END IF;
-- Mod Ver1.1 End
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
      errbuf                    OUT VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    , retcode                   OUT VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    , iv_login_base_code        IN  VARCHAR2 -- ���_
    , iv_delivery_date_from     IN  VARCHAR2 -- ����From
    , iv_delivery_date_to       IN  VARCHAR2 -- ����To
    , iv_login_chain_store_code IN  VARCHAR2 -- �`�F�[���X
    , iv_login_customer_code    IN  VARCHAR2 -- �ڋq
    , iv_customer_po_number     IN  VARCHAR2 -- �ڋq�����ԍ�
    , iv_subinventory_code      IN  VARCHAR2 -- �ۊǏꏊ
    , iv_priority_flag          IN  VARCHAR2 -- �D�惍�P�[�V�����g�p
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ���b�g�t�]��
    , iv_kbn                    IN  VARCHAR2 -- ����敪
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    -- ���b�Z�[�W
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_msg_xxcoi_10555 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10555'; -- �Ώی����i�������j�������b�Z�[�W
    cv_msg_xxcoi_10556 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10556'; -- ���������i�������j�������b�Z�[�W
    cv_msg_xxcoi_10557 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10557'; -- �Ώی����i�����ρj�������b�Z�[�W
    cv_msg_xxcoi_10558 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10558'; -- ���������i�����ρj�������b�Z�[�W
    cv_msg_xxcoi_10569 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10569'; -- ���s�������b�Z�[�W
    cv_msg_xxcoi_10551 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10551'; -- ���b�g�ʎ��TEMP�쐬�������b�Z�[�W
    -- �g�[�N��
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_errbuf                 => lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                => lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                 => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      , iv_login_base_code        => iv_login_base_code        -- ���_
      , iv_delivery_date_from     => iv_delivery_date_from     -- ����From
      , iv_delivery_date_to       => iv_delivery_date_to       -- ����To
      , iv_login_chain_store_code => iv_login_chain_store_code -- �`�F�[���X
      , iv_login_customer_code    => iv_login_customer_code    -- �ڋq
      , iv_customer_po_number     => iv_customer_po_number     -- �ڋq�����ԍ�
      , iv_subinventory_code      => iv_subinventory_code      -- �ۊǏꏊ
      , iv_priority_flag          => iv_priority_flag          -- �D�惍�P�[�V�����g�p
      , iv_lot_reversal_flag      => iv_lot_reversal_flag      -- ���b�g�t�]��
      , iv_kbn                    => iv_kbn                    -- ����敪
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
--
    -- �G���[���������݂���ꍇ
    IF ( gn_error_cnt > 0 ) THEN
      -- �G���[���̌����ݒ�
      gn_target_cnt      := 0;
      gn_normal_cnt      := 0;
      gn_warn_cnt        := 0;
      gn_target_10_cnt   := 0;
      gn_normal_10_cnt   := 0;
      gn_target_20_cnt   := 0;
      gn_normal_20_cnt   := 0;
      gn_create_temp_cnt := 0;
      -- �I���X�e�[�^�X���G���[�ɂ���
      lv_retcode := cv_status_error;
    -- �G���[������0���ŁA�x�����������݂܂��͌x���t���O��TRUE�̏ꍇ
    ELSIF ( ( gn_error_cnt = 0 )
      AND   ( ( gn_warn_cnt > 0 ) OR ( gb_warn_flag = TRUE ) ) ) THEN
      -- �I���X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    -- �G���[�����A�x�����������݂��Ȃ��ꍇ
    ELSE
      -- �I���X�e�[�^�X�𐳏�ɂ���
      lv_retcode := cv_status_normal;
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- �����܂��͏o�׊m��̏ꍇ
    IF ( ( gv_kbn = cv_kbn_1 ) OR ( gv_kbn = cv_kbn_3 ) OR ( gv_kbn = cv_kbn_4 ) ) THEN
      -- �Ώی����o��
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
      -- ���������o��
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
      -- ���s�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10569
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    -- ���������̏ꍇ
    ELSIF ( gv_kbn = cv_kbn_2 ) THEN
      -- �Ώی����i�������j�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10555
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_target_10_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- ���������i�������j�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10556
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_normal_10_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �Ώی����i�����ρj�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10557
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_target_20_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- ���������i�����ρj�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10558
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_normal_20_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    -- �ԕi�E�����E�ߋ��f�[�^�A���m�������̏ꍇ
    ELSIF ( ( gv_kbn = cv_kbn_5 ) OR ( gv_kbn = cv_kbn_6 ) ) THEN
      -- ���b�g�ʎ��TEMP�쐬����
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcoi_10551
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_create_temp_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    -- �G���[�����o��
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
    --
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI016A99C;
/
