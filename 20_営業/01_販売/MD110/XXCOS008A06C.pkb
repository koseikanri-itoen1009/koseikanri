CREATE OR REPLACE PACKAGE BODY APPS.XXCOS008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A06C(body)
 * Description      : �o�׈˗����т���̎󒍍쐬
 * MD.050           : �o�׈˗����т���̎󒍍쐬 MD050_COS_008_A06
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_qty            ���Z����
 *  get_unit_price         �P���擾
 *  chk_price_list_id      ���i�\ID�`�F�b�N
 *  chk_cover_salesman     �S���c�ƈ��`�F�b�N
 *  chk_cust_po_no         �ڋq�����ԍ��`�F�b�N
 *  output_param           ���̓p�����[�^�o��              (A-1)
 *  chk_param              ���̓p�����[�^�`�F�b�N          (A-2)
 *  init                   ��������                        (A-3)
 *  get_data               �Ώۃf�[�^�擾                  (A-4)
 *  chk_line               ���גP�ʃ`�F�b�N                (A-5)
 *  chk_hdr                �w�b�_�P�ʃ`�F�b�N              (A-6)
 *  set_hdr_oif            �󒍃w�b�_OIF�o�^�f�[�^�ҏW     (A-7)
 *  set_line_oif           �󒍖���OIF�o�^�f�[�^�ҏW       (A-8)
 *  ins_oif                �󒍃f�[�^�o�^                  (A-9)
 *  call_imp_data          �󒍃C���|�[�g�G���[���m�N������(A-10)
 *  target_data_loop       �Ώۃf�[�^LOOP
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/23    1.0   H.Itou           �V�K�쐬
 *  2010/05/10    1.1   H.Itou           E_�{�ғ�_02532,E_�{�ғ�_02595
 *  2012/06/25    1.2   D.Sugahara       [E_�{�ғ�_09744]��OIF��肱�ڂ��Ή��i�ďo�R���J�����g��
 *                                                       �󒍃C���|�[�g�G���[���m(Online�p�j�ɕύX�j
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
  no_data EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOS008A06C'; -- �p�b�P�[�W��
  cv_fmt_yyyymmdd            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';   -- ���t�t�H�[�}�b�g
  cv_fmt_yyyymm              CONSTANT VARCHAR2(100) := 'YYYYMM';       -- ���t�t�H�[�}�b�g
  cv_lang_ja                 CONSTANT VARCHAR2(100) := 'JA';           -- ���{��
--
  -- �A�v���P�[�V�����Z�k��
  cv_xxcos_appl_short_name   CONSTANT VARCHAR2(100) := 'XXCOS';        -- �̔�
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(100) := 'XXCCP';        -- ����
--
  -- ���b�Z�[�W�R�[�h
  cv_msg_get_profile_err     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00004';                -- �v���t�@�C���擾�G���[
  cv_msg_chk_param_err       CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14052';                -- �p�����[�^�K�{�G���[
  cv_msg_get_api_call_err    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00017';                -- API�ďo�G���[���b�Z�[�W
  cv_msg_get_master_chk_err  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14062';                -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_get_process_date    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14060';                -- �Ɩ��������擾�G���[
  cv_msg_get_param_msg1      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14051';                -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_get_param_msg2      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14064';                -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_get_param_msg3      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14072';                -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_get_acct_period_err CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14061';                -- �݌ɉ�v���Ԏ擾�G���[
  cv_msg_cover_sales_err     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14057';                -- �S���c�ƈ����ݒ�G���[
  cv_msg_separator           CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14063';                -- ���b�Z�[�W�Z�p���[�^
  cv_msg_no_price_tbl_err    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14056';                -- ���i�\���o�^�G���[���b�Z�[�W
  cv_msg_no_price_lis_id_err CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14055';                -- �ڋq�}�X�^���i�\���ݒ�G���[���b�Z�[�W
  cv_msg_imp_err             CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14053';                -- �R���J�����g�G���[���b�Z�[�W
  cv_msg_imp_warn            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14054';                -- �R���J�����g���[�j���O���b�Z�[�W
  cv_msg_err_msg_title       CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14058';                -- �G���[���b�Z�[�W�^�C�g��
  cv_msg_warn_msg_title      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14059';                -- �x�����b�Z�[�W�^�C�g��
  cv_msg_target_hdr_cnt      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14065';                -- �Ώۏo�׈˗������i�w�b�_�j
  cv_msg_normal_hdr_cnt      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14066';                -- ���������i�w�b�_�j
  cv_msg_normal_line_cnt     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14067';                -- ���������i���ׁj
  cv_msg_err_hdr_cnt         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14068';                -- �G���[�����i�w�b�_�j
  cv_msg_err_line_cnt        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14069';                -- �G���[�����i���ׁj
  cv_msg_price_1yen_hdr_cnt  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14070';                -- �̔��P���P�~�����i�w�b�_�j
  cv_msg_price_1yen_line_cnt CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14071';                -- �̔��P���P�~�����i���ׁj
  cv_msg_insert_data_err     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00010';                -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_no_data_err         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00003';                -- �Ώۃf�[�^�����G���[
  cv_msg_cust_po_no_title    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14073';                -- �x�����b�Z�[�W�^�C�g���i�ڋq�����ԍ��ҏW�j
  cv_msg_cust_po_err1        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14074';                -- �ڋq�����ԍ������G���[
  cv_msg_cust_po_err2        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14075';                -- �ڋq�����ԍ��J���}�G���[
--
  -- �g�[�N��
  cv_tkn_profile             CONSTANT VARCHAR2(100) := 'PROFILE';                         -- �v���t�@�C����
  cv_tkn_api_name            CONSTANT VARCHAR2(100) := 'API_NAME';                        -- ���ʊ֐���
  cv_tkn_column              CONSTANT VARCHAR2(100) := 'COLMUN';                          -- ���ږ�
  cv_tkn_table               CONSTANT VARCHAR2(100) := 'TABLE';                           -- �e�[�u����
  cv_tkn_param01             CONSTANT VARCHAR2(100) := 'PARAM1';                          -- �p�����[�^1
  cv_tkn_param02             CONSTANT VARCHAR2(100) := 'PARAM2';                          -- �p�����[�^2
  cv_tkn_param03             CONSTANT VARCHAR2(100) := 'PARAM3';                          -- �p�����[�^3
  cv_tkn_param04             CONSTANT VARCHAR2(100) := 'PARAM4';                          -- �p�����[�^4
  cv_tkn_param05             CONSTANT VARCHAR2(100) := 'PARAM5';                          -- �p�����[�^5
  cv_tkn_param06             CONSTANT VARCHAR2(100) := 'PARAM6';                          -- �p�����[�^6
  cv_tkn_param07             CONSTANT VARCHAR2(100) := 'PARAM7';                          -- �p�����[�^7
  cv_tkn_param08             CONSTANT VARCHAR2(100) := 'PARAM8';                          -- �p�����[�^8
  cv_tkn_param09             CONSTANT VARCHAR2(100) := 'PARAM9';                          -- �p�����[�^9
  cv_tkn_param10             CONSTANT VARCHAR2(100) := 'PARAM10';                         -- �p�����[�^10
  cv_tkn_param11             CONSTANT VARCHAR2(100) := 'PARAM11';                         -- �p�����[�^11
  cv_tkn_param12             CONSTANT VARCHAR2(100) := 'PARAM12';                         -- �p�����[�^12
  cv_tkn_param13             CONSTANT VARCHAR2(100) := 'PARAM13';                         -- �p�����[�^13
  cv_tkn_param14             CONSTANT VARCHAR2(100) := 'PARAM14';                         -- �p�����[�^14
  cv_tkn_param15             CONSTANT VARCHAR2(100) := 'PARAM15';                         -- �p�����[�^15
  cv_tkn_param16             CONSTANT VARCHAR2(100) := 'PARAM16';                         -- �p�����[�^16
  cv_tkn_param17             CONSTANT VARCHAR2(100) := 'PARAM17';                         -- �p�����[�^17
  cv_tkn_param18             CONSTANT VARCHAR2(100) := 'PARAM18';                         -- �p�����[�^18
  cv_tkn_param19             CONSTANT VARCHAR2(100) := 'PARAM19';                         -- �p�����[�^19
  cv_tkn_param20             CONSTANT VARCHAR2(100) := 'PARAM20';                         -- �p�����[�^20
  cv_tkn_request_no          CONSTANT VARCHAR2(100) := 'REQUEST_NO';                      -- �˗�No
  cv_tkn_item_code           CONSTANT VARCHAR2(100) := 'ITEM_CODE';                       -- �i�ڃR�[�h
  cv_tkn_uom_code_from       CONSTANT VARCHAR2(100) := 'UOM_CODE_FROM';                   -- ��P��
  cv_tkn_uom_code_to         CONSTANT VARCHAR2(100) := 'UOM_CODE_TO';                     -- ���o�Ɋ��Z�P��
  cv_tkn_quantity            CONSTANT VARCHAR2(100) := 'QUANTITY';                        -- ����
  cv_tkn_case_num            CONSTANT VARCHAR2(100) := 'CASE_NUM';                        -- �P�[�X����
  cv_tkn_cust_code           CONSTANT VARCHAR2(100) := 'CUST_CODE';                       -- �ڋq�R�[�h
  cv_tkn_deliv_date          CONSTANT VARCHAR2(100) := 'DELIV_DATE';                      -- ���ד�
  cv_tkn_price_list          CONSTANT VARCHAR2(100) := 'PRICE_LIST';                      -- ���i�\��
  cv_tkn_request_id          CONSTANT VARCHAR2(100) := 'REQUEST_ID';                      -- �v��ID
  cv_tkn_dev_status          CONSTANT VARCHAR2(100) := 'STATUS';                          -- �X�e�[�^�X
  cv_tkn_message             CONSTANT VARCHAR2(100) := 'MESSAGE';                         -- ���b�Z�[�W
  cv_tkn_table_name          CONSTANT VARCHAR2(100) := 'TABLE_NAME';                      -- �e�[�u����
  cv_tkn_key_data            CONSTANT VARCHAR2(100) := 'KEY_DATA';                        -- �L�[���e���R�����g
  cv_tkn_cust_po_no_f        CONSTANT VARCHAR2(100) := 'CUST_PO_NUMBER_F';                -- �ڋq�����ԍ�(�ҏW�O)
  cv_tkn_cust_po_no_t        CONSTANT VARCHAR2(100) := 'CUST_PO_NUMBER_T';                -- �ڋq�����ԍ�(�ҏW��)
--
  -- �v���t�@�C���I�v�V����
  cv_prof_interval           CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL';                 -- XXCOS:�ҋ@�Ԋu
  cv_prof_max_wait           CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT';                 -- XXCOS:�ő�ҋ@����
  cv_prof_prod_ou            CONSTANT VARCHAR2(100) := 'XXCOS1_ITOE_OU_MFG';              -- XXCOS:���Y�c�ƒP�ʎ擾����
  cv_prof_org_id             CONSTANT VARCHAR2(100) := 'ORG_ID';                          -- �c�ƒP��
  cv_inv_org_code            CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';        -- XXCOI:�݌ɑg�D�R�[�h
--
  -- �v���t�@�C���I�v�V������
  cv_prof_interval_name      CONSTANT VARCHAR2(100) := 'XXCOS:�ҋ@�Ԋu';
  cv_prof_max_wait_name      CONSTANT VARCHAR2(100) := 'XXCOS:�ő�ҋ@����';
  cv_prof_prod_ou_name       CONSTANT VARCHAR2(100) := 'XXCOS:���Y�c�ƒP�ʎ擾����';
  cv_prof_org_id_name        CONSTANT VARCHAR2(100) := '�c�ƒP��';
  cv_prof_inv_org_name       CONSTANT VARCHAR2(100) := 'XXCOI:�݌ɑg�D�R�[�h';
--
  -- API��
  cv_get_org_id_name         CONSTANT VARCHAR2(100) := '�݌ɑg�DID�擾';
  cv_get_process_date_name   CONSTANT VARCHAR2(100) := '�Ɩ����t�擾';
--
  -- �e�[�u����
  cv_order_source_tbl_name   CONSTANT VARCHAR2(100) := '�󒍃\�[�X';
  cv_order_type_tbl_name     CONSTANT VARCHAR2(100) := '�󒍃^�C�v';
  cv_lookup_values_tbl_name  CONSTANT VARCHAR2(100) := '�N�C�b�N�R�[�h';
  cv_hdr_oif_tbl_name        CONSTANT VARCHAR2(100) := '�󒍃w�b�_�[OIF';
  cv_line_oif_tbl_name       CONSTANT VARCHAR2(100) := '�󒍖���OIF';
--
  -- ���ږ�
  cv_order_source_name       CONSTANT VARCHAR2(100) := '�󒍃\�[�X��';
  cv_order_type_name         CONSTANT VARCHAR2(100) := '�󒍃^�C�v��';
  cv_order_headers_name      CONSTANT VARCHAR2(100) := '�󒍃\�[�X�Q�Ɛ擪����';
--
  -- �N�C�b�N�R�[�h �^�C�v
  cv_look_source_type        CONSTANT VARCHAR2(100) := 'XXCOS1_ODR_SRC_TYPE_008_A06';      -- �󒍃\�[�X
  cv_look_order_type         CONSTANT VARCHAR2(100) := 'XXCOS1_TRAN_TYPE_MST_008_A06';     -- �󒍃^�C�v
  cv_no_inv_item_type        CONSTANT VARCHAR2(100) := 'XXCOS1_NO_INV_ITEM_CODE';          -- ��݌ɕi�ڃR�[�h
  cv_look_document_ref       CONSTANT VARCHAR2(100) := 'XXCOS1_ORDER_HEADERS_008_A06';     -- �󒍃\�[�X�Q�Ɛ擪����
--
  -- �N�C�b�N�R�[�h �R�[�h
  cv_order_type_normal_hdr   CONSTANT VARCHAR2(100) := 'XXCOS_008_A06_01';                 -- �󒍃^�C�v�R�[�h�F00_�ʏ��
  cv_order_type_normal_line  CONSTANT VARCHAR2(100) := 'XXCOS_008_A06_02';                 -- �󒍃^�C�v�R�[�h�F10_�ʏ�o��
  cv_source_type_online      CONSTANT VARCHAR2(100) := 'XXCOS_008_A06_10';                 -- �󒍃\�[�X�R�[�h�FOnline
  cv_document_ref            CONSTANT VARCHAR2(100) := '10';                               -- �󒍃\�[�X�Q�Ɛ擪�����R�[�h�F10
--
  -- �󒍃^�C�v�敪
  cv_order                   CONSTANT VARCHAR2(100) := 'ORDER';                            -- ORDER
  cv_line                    CONSTANT VARCHAR2(100) := 'LINE';                             -- LINE
--
  -- �݌ɉ�v���Ԏ擾��v�敪
  cv_inv                     CONSTANT VARCHAR2(100) := '01';                               -- 01:INV
  cv_ar                      CONSTANT VARCHAR2(100) := '02';                               -- 02:AR
--
  -- �˗�No�P�ʓo�^�t���O
  cv_input_oif_n             CONSTANT VARCHAR2(100) := 'N';                                -- �o�^���Ȃ�
  cv_input_oif_y             CONSTANT VARCHAR2(100) := 'Y';                                -- �o�^����
--
  -- �ڋq�g�p�ړI
  cv_site_user_ship_to       CONSTANT VARCHAR2(100) := 'SHIP_TO';                          -- �o�א�
--
  -- �ڋq�g�p�ړI�F��t���O
  cv_primary_flag_y          CONSTANT VARCHAR2(100) := 'Y';                                -- ��
--
  -- �ڋq�n�X�e�[�^�X
  cv_active_status           CONSTANT VARCHAR2(100) := 'A';                                -- �L��
--
  -- �ڋq�F�ڋq�敪
  cv_customer_class_base     CONSTANT VARCHAR2(100) := '1';                                -- ���_
  cv_customer_class_cust     CONSTANT VARCHAR2(100) := '10';                               -- �ڋq
--
  -- �󒍃w�b�_�A�h�I���F�X�e�[�^�X
  cv_req_status_04           CONSTANT VARCHAR2(100) := '04';                               -- �o�׎��ьv���
  cv_req_status_03           CONSTANT VARCHAR2(100) := '03';                               -- ���ߍ�
  cv_req_status_02           CONSTANT VARCHAR2(100) := '02';                               -- ���_�m��
  cv_req_status_01           CONSTANT VARCHAR2(100) := '01';                               -- ���͍�
  cv_req_status_99           CONSTANT VARCHAR2(100) := '99';                               -- ���
--
  -- �󒍃w�b�_�A�h�I���F�ŐV�t���O
  cv_latest_flag_y           CONSTANT VARCHAR2(100) := 'Y';                                -- �󒍃w�b�_�A�h�I��.�ŐV�t���O���uY�v
  cv_latest_flag_n           CONSTANT VARCHAR2(100) := 'N';                                -- �󒍃w�b�_�A�h�I��.�ŐV�t���O���uN�v
--
  -- �󒍖��׃A�h�I���F�폜�t���O
  cv_delete_flag_n           CONSTANT VARCHAR2(100) := 'N';                                -- �폜
  cv_delete_flag_y           CONSTANT VARCHAR2(100) := 'Y';                                -- �폜�łȂ�
--
  -- �i�ځF�����t���O
  cv_item_active             CONSTANT  VARCHAR2(10)  := '1';                               -- 1�F����
--
  -- �i�ځF�p�~�敪
  cv_no_obsolete             CONSTANT  VARCHAR2(10)  := '1';                               -- 1�F�p�~
--
  -- �ۊǏꏊ����
  cv_kbn_direct              CONSTANT VARCHAR2(100) := '11';                               -- ����
--
  -- �����q��
  cv_location_code_direct    CONSTANT VARCHAR2(100) := 'Z';                                -- 
--
  -- ����敪
  cv_sales_kbn_normal        CONSTANT VARCHAR2(100) := '1';                                -- �ʏ�
--
  -- �󒍖��׃X�e�[�^�X
  cv_entered                 CONSTANT VARCHAR2(100) := 'ENTERED';                          -- �󒍖���.�X�e�[�^�X���uENTERED:���͍ρv
  cv_booked                  CONSTANT VARCHAR2(100) := 'BOOKED';                           -- �󒍖���.�X�e�[�^�X���uBOOKED:�L���ρv
  cv_closed                  CONSTANT VARCHAR2(100) := 'CLOSED';                           -- �󒍖���.�X�e�[�^�X���uCLOSED:�N���[�Y�v
--
  -- �N�C�b�N�R�[�h�L���t���O
  cv_enabled_flag_y          CONSTANT VARCHAR2(100) := 'Y';                                -- �L��
--
  -- ����Ώۋ敪
  cv_sale_flg_y              CONSTANT VARCHAR2(100) := '1';                                -- ����Ώ�
--
  -- ���Z�P�ʋ敪
  cv_uom_type_hon            CONSTANT VARCHAR2(100) := '1';                                -- �{�i���Z�Ȃ��j
  cv_uom_type_cs             CONSTANT VARCHAR2(100) := '0';                                -- �P�[�X�i���Z����j
--
  -- �ڋq�����ԍ��敪
  cv_cust_po_set_type_req    CONSTANT VARCHAR2(100) := '0';                                -- �o�׈˗�No
  cv_cust_po_set_type_po     CONSTANT VARCHAR2(100) := '1';                                -- �ڋq�����ԍ�
--
  -- ���i�v�Z�t���O
  cv_calc_unit_price_flg_y   CONSTANT VARCHAR2(100) := 'Y';                                -- ���i�\����擾����
  cv_calc_unit_price_flg_n   CONSTANT VARCHAR2(100) := 'N';                                -- ���i�\����擾���Ȃ�
--
  -- �R���J�����g�I���X�e�[�^�X
  cv_con_status_normal       CONSTANT  VARCHAR2(10)  := 'NORMAL';                          -- �X�e�[�^�X�i����j
  cv_con_status_error        CONSTANT  VARCHAR2(10)  := 'ERROR';                           -- �X�e�[�^�X�i�ُ�j
  cv_con_status_warning      CONSTANT  VARCHAR2(10)  := 'WARNING';                         -- �X�e�[�^�X�i�x���j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[���R�[�h�^
  TYPE g_param_rtype IS RECORD(
    delivery_base_code          hz_cust_accounts.account_number                 %TYPE    -- 01.�[�i���_�R�[�h
   ,input_sales_branch          xxwsh_order_headers_all.input_sales_branch      %TYPE    -- 02.���͋��_�R�[�h
   ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch       %TYPE    -- 03.�Ǌ����_�R�[�h
   ,request_no                  xxwsh_order_headers_all.request_no              %TYPE    -- 04.�o�׈˗�No
   ,entered_by_code             per_all_people_f.employee_number                %TYPE    -- 05.�o�׈˗����͎�
   ,customer_code               hz_cust_accounts.account_number                 %TYPE    -- 06.�ڋq�R�[�h
   ,deliver_to                  xxwsh_order_headers_all.deliver_to              %TYPE    -- 07.�z����R�[�h
   ,deliver_from                xxwsh_order_headers_all.deliver_from            %TYPE    -- 08.�o�Ɍ��R�[�h
   ,ship_date_from              DATE                                                     -- 09.�o�ɓ��iFROM�j
   ,ship_date_to                DATE                                                     -- 10.�o�ɓ��iTO�j
   ,request_date_from           DATE                                                     -- 11.�����iFROM�j
   ,request_date_to             DATE                                                     -- 12.�����iTO�j
   ,cust_po_number              xxwsh_order_headers_all.cust_po_number          %TYPE    -- 13.�ڋq�����ԍ�
   ,customer_po_set_type        VARCHAR2(1)                                              -- 14.�ڋq�����ԍ��敪
   ,uom_type                    VARCHAR2(1)                                              -- 15.���Z�P�ʋ敪
   ,prod_class_code             xxcmn_item_categories5_v.prod_class_code        %TYPE    -- 16.���i�敪
   ,order_type_id               xxwsh_order_headers_all.order_type_id           %TYPE    -- 17.�o�Ɍ`��
   ,sales_chain_code            xxcmm_cust_accounts.sales_chain_code            %TYPE    -- 18.�̔���`�F�[��
   ,delivery_chain_code         xxcmm_cust_accounts.delivery_chain_code         %TYPE    -- 19.�[�i��`�F�[��
  );
--
  -- �Ώۃf�[�^�i�[���R�[�h�^
  TYPE g_target_data_rtype IS RECORD(
    request_no               xxwsh_order_headers_all.request_no                 %TYPE    -- �˗��m��
   ,cust_po_number           xxwsh_order_headers_all.cust_po_number             %TYPE    -- �ڋq�����ԍ�
   ,order_number             oe_order_headers_all.attribute19                   %TYPE    -- �I�[�_�[No
   ,customer_id              hz_cust_accounts.cust_account_id                   %TYPE    -- �ڋqID
   ,customer_code            hz_cust_accounts.account_number                    %TYPE    -- �ڋq�ԍ�
   ,arrival_date             xxwsh_order_headers_all.arrival_date               %TYPE    -- ���ד�
   ,sale_base_code           xxcmm_cust_accounts.sale_base_code                 %TYPE    -- ���㋒�_�R�[�h
   ,past_sale_base_code      xxcmm_cust_accounts.past_sale_base_code            %TYPE    -- �O�����㋒�_�R�[�h
   ,rsv_sale_base_code       xxcmm_cust_accounts.rsv_sale_base_code             %TYPE    -- �\�񔄏㋒�_�R�[�h
   ,rsv_sale_base_act_date   xxcmm_cust_accounts.rsv_sale_base_act_date         %TYPE    -- �\�񔄏㋒�_�L���J�n��
   ,price_list_id            hz_cust_site_uses_all.price_list_id                %TYPE    -- ���i�\�h�c
   ,arrival_time_from        xxwsh_order_headers_all.arrival_time_from          %TYPE    -- ���׎���FROM
   ,arrival_time_to          xxwsh_order_headers_all.arrival_time_to            %TYPE    -- ���׎���TO
   ,shipping_instructions    xxwsh_order_headers_all.shipping_instructions      %TYPE    -- �o�׎w��
   ,order_line_number        xxwsh_order_lines_all.order_line_number            %TYPE    -- ���הԍ�
   ,quantity                 xxwsh_order_lines_all.quantity                     %TYPE    -- ����
   ,conv_quantity            xxwsh_order_lines_all.quantity                     %TYPE    -- ���Z�㐔��
   ,unit_price               oe_lines_iface_all.unit_list_price                 %TYPE    -- �P��
   ,calc_unit_price_flg      oe_lines_iface_all.calculate_price_flag            %TYPE    -- ���i�v�Z�t���O
   ,child_item_no            ic_item_mst_b.item_no                              %TYPE    -- �q�i�ڃR�[�h
   ,parent_item_no           ic_item_mst_b.item_no                              %TYPE    -- �e�i�ڃR�[�h
   ,parent_num_of_cases      NUMBER                                                      -- �e�i�ڃP�[�X����
   ,parent_item_um           ic_item_mst_b.item_um                              %TYPE    -- �e�i�ڊ�P��
   ,parent_conv_unit         ic_item_mst_b.attribute24                          %TYPE    -- �e�i�ړ��o�Ɋ��Z�P�ʁi���Z��P�ʁj
   ,parent_inv_item_id       mtl_system_items_b.inventory_item_id               %TYPE    -- �e�i�ڂh�m�u�i�ڂh�c
  );
--
  -- �Ώۃf�[�^�i�[�z��^
  TYPE g_target_data_ttype IS TABLE OF g_target_data_rtype          INDEX BY BINARY_INTEGER;
--
  -- �󒍃w�b�_OIF�i�[�z��^
  TYPE g_hdr_oif_ttype     IS TABLE OF oe_headers_iface_all%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- �󒍖���OIF�i�[�z��^
  TYPE g_line_oif_ttype    IS TABLE OF oe_lines_iface_all  %ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- �x�����b�Z�[�W�z��^
  TYPE g_message_ttype     IS TABLE OF VARCHAR2(5000)               INDEX BY BINARY_INTEGER;
--
  -- �J�[�\���^
  TYPE ref_cur             IS REF CURSOR ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_param_rec                       g_param_rtype;                                                   -- ���̓p�����[�^�i�[���R�[�h�ϐ�
  g_hdr_oif_tab                     g_hdr_oif_ttype;                                                 -- �󒍃w�b�_OIF�i�[�z��^
  g_line_oif_tab                    g_line_oif_ttype;                                                -- �󒍖���OIF�i�[�z��^
  g_warn_msg_tab                    g_message_ttype;                                                 -- �x�����b�Z�[�W�z��^
  g_err_msg_tab                     g_message_ttype;                                                 -- �o�^�G���[���b�Z�[�W�z��^
  g_cust_po_no_msg_tab              g_message_ttype;                                                 -- �ڋq�����ԍ��ҏW�x�����b�Z�[�W�z��^
--
  gn_hdr_oif_cnt                    NUMBER;                                                          -- �󒍃w�b�_OIF�i�[�z��^INDEX
  gn_line_oif_cnt                   NUMBER;                                                          -- �󒍖���OIF�i�[�z��^INDEX
  gn_warn_msg_cnt                   NUMBER;                                                          -- �x�����b�Z�[�W�z��^INDEX
  gn_err_msg_cnt                    NUMBER;                                                          -- �o�^�G���[���b�Z�[�W�z��^INDEX
  gn_cust_po_no_msg_cnt             NUMBER;                                                          -- �ڋq�����ԍ��ҏW�x�����b�Z�[�W�z��^INDEX
--
  gn_interval                       NUMBER;                                                          -- �ҋ@�Ԋu
  gn_max_wait                       NUMBER;                                                          -- �ő�ҋ@����
  gv_prod_ou_nm                     VARCHAR2(128);                                                   -- ���Y�c�ƒP�ʖ�
  gn_org_id                         NUMBER;                                                          -- �c�ƒP��
  gv_inv_org_code                   VARCHAR2(128);                                                   -- �݌ɑg�D�R�[�h
  gt_prod_org_id                    hr_operating_units.organization_id%TYPE;                         -- ���Y�c�ƒP��ID
  gn_inv_org_id                     NUMBER;                                                          -- �c�Ɨp�݌ɑg�DID
  gd_open_date_from                 DATE;                                                            -- �݌ɉ�v����(FROM)
  gd_open_date_to                   DATE;                                                            -- �݌ɉ�v����(TO)
  gd_process_date                   DATE;                                                            -- �Ɩ����t
  gt_order_source_name              fnd_lookup_values.description   %TYPE;                           -- �󒍃\�[�X��(Online)
  gt_order_source_id                oe_order_sources.order_source_id%TYPE;                           -- �󒍃\�[�XID
  gt_order_type_hdr                 oe_transaction_types_tl.name    %TYPE;                           -- �w�b�_�p�󒍃^�C�v
  gt_order_type_line                oe_transaction_types_tl.name    %TYPE;                           -- ���חp�󒍃^�C�v
  gt_orig_sys_document_ref          fnd_lookup_values.meaning       %TYPE;                           -- �󒍃\�[�X�Q�ƌŒ�l
--
  gn_target_hdr_cnt                 NUMBER;                                                          -- �Ώۏo�׈˗������i�w�b�_�j
  gn_target_line_cnt                NUMBER;                                                          -- �Ώۏo�׈˗������i���ׁj
  gn_normal_hdr_cnt                 NUMBER;                                                          -- ���������i�w�b�_�j
  gn_normal_line_cnt                NUMBER;                                                          -- ���������i���ׁj
  gn_err_hdr_cnt                    NUMBER;                                                          -- �G���[�����i�w�b�_�j
  gn_err_line_cnt                   NUMBER;                                                          -- �G���[�����i���ׁj
  gn_price_1yen_hdr_cnt             NUMBER;                                                          -- �̔��P���P�~�����i�w�b�_�j
  gn_price_1yen_line_cnt            NUMBER;                                                          -- �̔��P���P�~�����i���ׁj
--
  -- ���ʃ��b�Z�[�W
  gv_separator                      VARCHAR2(100);                                                   -- �Z�p���[�^���b�Z�[�W
--
  /**********************************************************************************
   * Procedure Name   : convert_qty
   * Description      : ���Z����
   ***********************************************************************************/
  PROCEDURE convert_qty(
    i_data_rec               IN OUT   g_target_data_rtype  -- �Ώۃf�[�^�i�[���R�[�h�^
   ,ov_errbuf                OUT      VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT      VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT      VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_qty'; -- �v���O������
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
    lv_before_uom_code   VARCHAR2(100);        -- �P�ʊ��Z�֐��Ɏg�p IN     ��P��
    ln_before_quantity   NUMBER;               -- �P�ʊ��Z�֐��Ɏg�p IN     �o����
    lv_item_code         VARCHAR2(100);        -- �P�ʊ��Z�֐��Ɏg�p IN OUT �i�ڃR�[�h
    lv_organization_code VARCHAR2(100);        -- �P�ʊ��Z�֐��Ɏg�p IN OUT �݌ɑg�D�R�[�h
    ln_inventory_item_id NUMBER;               -- �P�ʊ��Z�֐��Ɏg�p IN OUT INV�i��ID
    ln_organization_id   NUMBER;               -- �P�ʊ��Z�֐��Ɏg�p IN OUT �݌ɑg�D�h�c
    lv_after_uom_code    VARCHAR2(100);        -- �P�ʊ��Z�֐��Ɏg�p IN OUT ���Z��P�ʃR�[�h
    ln_after_quantity    NUMBER;               -- �P�ʊ��Z�֐��Ɏg�p OUT    ���Z�㐔��
    ln_out_content       NUMBER;               -- �P�ʊ��Z�֐��Ɏg�p OUT    ����
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
    -- ���Z�p�^�[������ START
    -- ���̓p�����[�^.���Z�P�ʋ敪���u1:�{�v�̏ꍇ�A���Z���Ȃ��B
    IF (g_param_rec.uom_type = cv_uom_type_hon) THEN
--
      i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- ���Z��P�ʁ��e�i�ڊ�P��
      i_data_rec.conv_quantity    := i_data_rec.quantity;       -- ���Z�㐔�ʁ��o����
--
    -- �E���̓p�����[�^.���Z�P�ʋ敪���u0:�P�[�X�v
    -- �E���o�Ɋ��Z�P�ʂ�NULL
    -- ��L�̏ꍇ�A���Z���Ȃ��B
    ELSIF ((g_param_rec.uom_type = cv_uom_type_cs)
    AND    (i_data_rec.parent_conv_unit IS NULL)) THEN
--
      i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- ���Z��P�ʁ��e�i�ڊ�P��
      i_data_rec.conv_quantity    := i_data_rec.quantity;       -- ���Z�㐔�ʁ��o����
--
    -- �E���̓p�����[�^.���Z�P�ʋ敪���u0:�P�[�X�v
    -- �E���o�Ɋ��Z�P�ʂɒl����
    -- �E�o�������P�[�X��������؂�Ȃ�
    -- ��L�̏ꍇ�A���Z���Ȃ��B
    ELSIF ((g_param_rec.uom_type       = cv_uom_type_cs)
    AND    (i_data_rec.parent_conv_unit IS NOT NULL)
    AND    (MOD(i_data_rec.quantity, i_data_rec.parent_num_of_cases) <> 0)) THEN
--
      i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- ���Z��P�ʁ��e�i�ڊ�P��
      i_data_rec.conv_quantity    := i_data_rec.quantity;       -- ���Z�㐔�ʁ��o����
--
    -- �E���̓p�����[�^.���Z�P�ʋ敪���u0:�P�[�X�v
    -- �E���o�Ɋ��Z�P�ʂɒl����
    -- �E�o�������P�[�X��������؂��
    -- ��L�̏ꍇ�A���Z�}�X�^�`�F�b�N
    ELSIF ((g_param_rec.uom_type       = cv_uom_type_cs)
    AND    (i_data_rec.parent_conv_unit IS NOT NULL)
    AND    (MOD(i_data_rec.quantity, i_data_rec.parent_num_of_cases) = 0)) THEN
--
      lv_before_uom_code   := i_data_rec.parent_item_um;      -- �P�ʊ��Z�֐��Ɏg�p IN     ��P��        ���e�i�ڊ�P��
      ln_before_quantity   := i_data_rec.quantity;            -- �P�ʊ��Z�֐��Ɏg�p IN     �o����          ������
      lv_item_code         := i_data_rec.parent_item_no ;     -- �P�ʊ��Z�֐��Ɏg�p IN OUT �i�ڃR�[�h      ���e�i�ڃR�[�h
      lv_organization_code := gv_inv_org_code;                -- �P�ʊ��Z�֐��Ɏg�p IN OUT �݌ɑg�D�R�[�h
      ln_inventory_item_id := i_data_rec.parent_inv_item_id;  -- �P�ʊ��Z�֐��Ɏg�p IN OUT INV�i��ID       ���e�i��INV�i��ID
      ln_organization_id   := gn_inv_org_id;                  -- �P�ʊ��Z�֐��Ɏg�p IN OUT �݌ɑg�D�h�c
      lv_after_uom_code    := i_data_rec.parent_conv_unit;    -- �P�ʊ��Z�֐��Ɏg�p IN OUT ���Z��P�ʃR�[�h���e�i�ړ��o�Ɋ��Z�P��
--
      -- ���Z�}�X�^�`�F�b�N(�P�ʊ��Z�֐�)
      xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => lv_before_uom_code          -- IN  ���Z�O�P�ʃR�[�h
       ,in_before_quantity    => ln_before_quantity          -- IN  ���Z�O����
       ,iov_item_code         => lv_item_code                -- IN OUT �i�ڃR�[�h
       ,iov_organization_code => lv_organization_code        -- IN OUT �݌ɑg�D�R�[�h
       ,ion_inventory_item_id => ln_inventory_item_id        -- IN OUT �i�ڂh�c
       ,ion_organization_id   => ln_organization_id          -- IN OUT �݌ɑg�D�h�c
       ,iov_after_uom_code    => lv_after_uom_code           -- IN OUT ���Z��P�ʃR�[�h
       ,on_after_quantity     => ln_after_quantity           -- OUT  ���Z�㐔��
       ,on_content            => ln_out_content              -- OUT  ����
       ,ov_errbuf             => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �P�ʊ��Z�֐����G���[�I���̏ꍇ�A���Z���Ȃ��B
      IF ( lv_retcode = cv_status_error ) THEN
--
        i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- ���Z��P�ʁ��e�i�ڊ�P��
        i_data_rec.conv_quantity    := i_data_rec.quantity;       -- ���Z�㐔�ʁ��o����
--
      -- �P�ʊ��Z�֐����G���[�I���łȂ��ꍇ�A���Z����B
      ELSE
--
        i_data_rec.parent_conv_unit := lv_after_uom_code; -- ���Z��P�ʁ����Z��P�ʃR�[�h�i�e�i�ړ��o�Ɋ��Z�P�ʁj
        i_data_rec.conv_quantity    := ln_after_quantity; -- ���Z�㐔�ʁ����Z�㐔��
--
      END IF;
--
    END IF; -- ���Z�p�^�[������ END
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
  END convert_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_unit_price
   * Description      : �P���擾
   ***********************************************************************************/
  PROCEDURE get_unit_price(
    i_data_rec               IN OUT   g_target_data_rtype  -- �Ώۃf�[�^�i�[���R�[�h�^
   ,ov_errbuf                OUT      VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT      VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT      VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_unit_price'; -- �v���O������
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
    lt_name        qp_list_headers_tl.name%TYPE; -- ���i�\����
    ln_unit_price  NUMBER;                       -- �P��
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
  -- ���i�\ID���� START
  -- ���i�\ID�ɒl���Ȃ��ꍇ�A�P��1�~�Ƃ���B(���i�\ID��NULL�̌x�����b�Z�[�W�̓w�b�_�P�ʂŏo�͂���̂ŁA�����ł͏o���Ȃ��B)
  IF (i_data_rec.price_list_id IS NULL) THEN
--
    gn_price_1yen_line_cnt := gn_price_1yen_line_cnt + 1; -- �̔��P���P�~�����i���ׁj
--
    i_data_rec.unit_price          := 1;                         -- �P����1�~
    i_data_rec.calc_unit_price_flg := cv_calc_unit_price_flg_n;  -- ���i�v�Z�t���O���uN�F���i�\����擾���Ȃ��v
--
  -- ���i�\ID�ɒl������ꍇ
  ELSE
    -- ���Z��P�ʂŉ��i�\������
    ln_unit_price := xxcos_common2_pkg.get_unit_price(
                       in_inventory_item_id    => i_data_rec.parent_inv_item_id    -- Disc�i��ID���e�i��INV�i��ID
                      ,in_price_list_header_id => i_data_rec.price_list_id         -- ���i�\�w�b�_ID�����i�\ID
                      ,iv_uom_code             => i_data_rec.parent_conv_unit      -- �P�ʃR�[�h���e�i�ړ��o�Ɋ��Z�P�ʁi���Z��P�ʁj
                     );
--
    -- ���Z��P�ʂ̒P����0�~�ȉ��ŁA���Z��P�ʂƊ���ׂ��Ⴄ�ꍇ�A�Č���
    IF ((ln_unit_price <= 0)
    AND (i_data_rec.parent_conv_unit <> i_data_rec.parent_item_um)) THEN
--
      -- ��P�ʂŉ��i�\������
      ln_unit_price := xxcos_common2_pkg.get_unit_price(
                         in_inventory_item_id    => i_data_rec.parent_inv_item_id    -- Disc�i��ID���e�i��INV�i��ID
                        ,in_price_list_header_id => i_data_rec.price_list_id         -- ���i�\�w�b�_ID�����i�\ID
                        ,iv_uom_code             => i_data_rec.parent_item_um        -- �P�ʃR�[�h���e�i�ڊ�P��
                       );
--
    END IF;
--
    -- ���i�\ID�ɒl������ꍇ�̉��i���蕪�� START
    -- �P����0�~���傫���ꍇ�A���i�v�Z�t���OON
    IF (ln_unit_price > 0) THEN
--
      i_data_rec.unit_price          := NULL;                      -- �P����NULL(���i�\����v�Z����)
      i_data_rec.calc_unit_price_flg := cv_calc_unit_price_flg_y;  -- ���i�v�Z�t���O���uY�F���i�\����擾����v
--
    -- �P����0�~�ȉ��̏ꍇ�A�P��1�~�i�x�����b�Z�[�W�o�́j
    ELSE
--
      gn_price_1yen_line_cnt := gn_price_1yen_line_cnt + 1; -- �̔��P���P�~�����i���ׁj
--
      i_data_rec.unit_price          := 1;                         -- �P����1�~
      i_data_rec.calc_unit_price_flg := cv_calc_unit_price_flg_n;  -- ���i�v�Z�t���O���uN�F���i�\����擾���Ȃ��v
--
      SELECT qlht.name           name -- ���i�\����
      INTO   lt_name
      FROM   qp_list_headers_tl  qlht -- ���i�\�w�b�_�|��
      WHERE  qlht.list_header_id = i_data_rec.price_list_id
      AND    qlht.language       = cv_lang_ja
      ;
--
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      g_warn_msg_tab(gn_warn_msg_cnt) := gv_separator  -- �Z�p���[�^
                                      || CHR(10)       -- ���s
                                      || xxccp_common_pkg.get_msg( -- ���i�\���o�^�G���[���b�Z�[�W
                                           iv_application  => cv_xxcos_appl_short_name
                                          ,iv_name         => cv_msg_no_price_tbl_err
                                          ,iv_token_name1  => cv_tkn_cust_code       -- �ڋq�R�[�h
                                          ,iv_token_value1 => i_data_rec.customer_code
                                          ,iv_token_name2  => cv_tkn_price_list      -- ���i�\��
                                          ,iv_token_value2 => lt_name
                                          ,iv_token_name3  => cv_tkn_request_no      -- �˗�No
                                          ,iv_token_value3 => i_data_rec.request_no
                                          ,iv_token_name4  => cv_tkn_deliv_date      -- ���ד�
                                          ,iv_token_value4 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                          ,iv_token_name5  => cv_tkn_item_code       -- �i�ڃR�[�h
                                          ,iv_token_value5 => i_data_rec.parent_item_no
                                        )
                                      || CHR(10)       -- ���s
                                      ;
--
      ov_retcode := cv_status_warn; -- �x��
--
    END IF; -- ���i�\ID�ɒl������ꍇ�̉��i���蕪�� END
--
  END IF; -- ���i�\ID���� END
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
  END get_unit_price;
--
  /**********************************************************************************
   * Procedure Name   : chk_price_list_id
   * Description      : �˗�No�P�ʉ��i�\�`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_price_list_id(
    i_data_tab               IN       g_target_data_ttype   -- �Ώۃf�[�^�i�[�z��^
   ,in_start_cnt             IN       NUMBER                -- �擪INDEX
   ,in_end_cnt               IN       NUMBER                -- �ŏIINDEX
   ,ov_errbuf                OUT      VARCHAR2              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT      VARCHAR2              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT      VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_price_list_id'; -- �v���O������
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
  -- �̔��P���P�~�����i�w�b�_�j�擾
  <<request_no_loop>>
  FOR ln_loop_cnt IN in_start_cnt..in_end_cnt LOOP
--
    -- ���i�v�Z�t���O���uN�F���i�\����擾���Ȃ��v������˗�No���ɂ���ꍇ�A�̔��P���P�~�����i�w�b�_�j���J�E���g
    IF (i_data_tab(ln_loop_cnt).calc_unit_price_flg = cv_calc_unit_price_flg_n) THEN
      gn_price_1yen_hdr_cnt := gn_price_1yen_hdr_cnt + 1; -- �̔��P���P�~�����i�w�b�_�j
      EXIT;
    END IF;
--
  END LOOP request_no_loop;
--
  -- ���i�\ID�ɒl���Ȃ��ꍇ�A�x�����b�Z�[�W�擾
  IF (i_data_tab(in_end_cnt).price_list_id IS NULL) THEN
--
    gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
    g_warn_msg_tab(gn_warn_msg_cnt) := gv_separator  -- �Z�p���[�^
                                    || CHR(10)       -- ���s
                                    || xxccp_common_pkg.get_msg( -- �ڋq�}�X�^���i�\���ݒ�G���[���b�Z�[�W
                                         iv_application  => cv_xxcos_appl_short_name
                                        ,iv_name         => cv_msg_no_price_lis_id_err
                                        ,iv_token_name1  => cv_tkn_cust_code       -- �ڋq�R�[�h
                                        ,iv_token_value1 => i_data_tab(in_end_cnt).customer_code
                                        ,iv_token_name2  => cv_tkn_request_no      -- �˗�No
                                        ,iv_token_value2 => i_data_tab(in_end_cnt).request_no
                                        ,iv_token_name3  => cv_tkn_deliv_date      -- ���ד�
                                        ,iv_token_value3 => TO_CHAR(i_data_tab(in_end_cnt).arrival_date, cv_fmt_yyyymmdd)
                                      )
                                    || CHR(10)       -- ���s
                                    ;
--
    ov_retcode := cv_status_warn; -- �x��
--
  END IF;
--
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
  END chk_price_list_id;
--
  /**********************************************************************************
   * Procedure Name   : chk_cover_salesman
   * Description      : �S���c�ƈ��`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_cover_salesman(
    i_data_rec               IN       g_target_data_rtype   -- �Ώۃf�[�^�i�[���R�[�h�^
   ,ov_errbuf                OUT      VARCHAR2              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT      VARCHAR2              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT      VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cover_salesman'; -- �v���O������
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
    ln_tmp NUMBER;
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
    -- �S���c�ƈ�����
    SELECT COUNT(1)          cnt
    INTO   ln_tmp
    FROM   xxcos_salesreps_v xsv -- �S���c�ƈ��r���[
    WHERE  xsv.cust_account_id       = i_data_rec.customer_id  -- �ڋqID
    AND    xsv.effective_start_date <= i_data_rec.arrival_date -- �K�p�J�n������I���������ד�
    AND    NVL(xsv.effective_end_date, i_data_rec.arrival_date) >= i_data_rec.arrival_date
    AND    ROWNUM = 1
    ;
--
    -- �擾�ł��Ȃ��ꍇ�A�x�����b�Z�[�W�o��
    IF (ln_tmp = 0) THEN
      gn_err_msg_cnt := gn_err_msg_cnt + 1;
      g_err_msg_tab(gn_err_msg_cnt) := gv_separator  -- �Z�p���[�^
                                    || CHR(10)       -- ���s
                                    || xxccp_common_pkg.get_msg( -- �S���c�ƈ����ݒ�G���[
                                         iv_application  => cv_xxcos_appl_short_name
                                        ,iv_name         => cv_msg_cover_sales_err
                                        ,iv_token_name1  => cv_tkn_cust_code       -- �ڋq�R�[�h
                                        ,iv_token_value1 => i_data_rec.customer_code
                                        ,iv_token_name2  => cv_tkn_request_no      -- �˗�No
                                        ,iv_token_value2 => i_data_rec.request_no
                                        ,iv_token_name3  => cv_tkn_deliv_date      -- ���ד�
                                        ,iv_token_value3 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                       )
                                    || CHR(10)       -- ���s
                                    ;
--
      -- �X�e�[�^�X���x���ɕύX
      ov_retcode := cv_status_warn;
--
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
  END chk_cover_salesman;
--
  /**********************************************************************************
   * Procedure Name   : chk_cust_po_no
   * Description      : �ڋq�����ԍ��`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_cust_po_no(
    i_data_rec               IN OUT   g_target_data_rtype   -- �Ώۃf�[�^�i�[�z��^
   ,ov_errbuf                OUT      VARCHAR2              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT      VARCHAR2              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT      VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cust_po_no'; -- �v���O������
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
    cn_cust_po_no_end   CONSTANT NUMBER      := 12;  -- �ڋq�����ԍ��I������
    cn_cust_po_no_start CONSTANT NUMBER      := 1;   -- �ڋq�����ԍ��J�n����
    cv_comma            CONSTANT VARCHAR2(1) := ','; -- �J���}
    cv_underscore       CONSTANT VARCHAR2(1) := '_'; -- �A���_�[�X�R�A
--
    -- *** ���[�J���ϐ� ***
    lt_after_cust_po_number1 xxwsh_order_headers_all.cust_po_number%TYPE; -- �ڋq�����ԍ�(�J���}�ҏW��)
    lt_after_cust_po_number2 xxwsh_order_headers_all.cust_po_number%TYPE; -- �ڋq�����ԍ�(�����ҏW��)
    lt_before_cust_po_number xxwsh_order_headers_all.cust_po_number%TYPE; -- �ڋq�����ԍ�(�ҏW�O)
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
    -- �ڋq�����ԍ���NULL�łȂ��ꍇ START
    IF (i_data_rec.cust_po_number IS NOT NULL) THEN
--
      -- ============================================
      -- �ҏW�O�ڋq�����ԍ����擾
      -- ============================================
      lt_before_cust_po_number := i_data_rec.cust_po_number;
--
      -- ============================================
      -- �J���}�`�F�b�N
      -- ============================================
      --�J���}���A���_�[�X�R�A�ɒu��
      lt_after_cust_po_number1 := REPLACE(lt_before_cust_po_number, cv_comma, cv_underscore);
      i_data_rec.order_number  := lt_after_cust_po_number1; -- �I�[�_�[No
--
      -- �ڋq�����ԍ��ɃJ���}������ꍇ�A�x��
      IF (lt_before_cust_po_number <> lt_after_cust_po_number1) THEN
--
        gn_cust_po_no_msg_cnt := gn_cust_po_no_msg_cnt + 1;
        g_cust_po_no_msg_tab(gn_cust_po_no_msg_cnt) := gv_separator  -- �Z�p���[�^
                                                    || CHR(10)       -- ���s
                                                    || xxccp_common_pkg.get_msg( -- �ڋq�����ԍ��J���}�G���[
                                                         iv_application  => cv_xxcos_appl_short_name
                                                        ,iv_name         => cv_msg_cust_po_err2
                                                        ,iv_token_name1  => cv_tkn_cust_code         -- �ڋq�R�[�h
                                                        ,iv_token_value1 => i_data_rec.customer_code
                                                        ,iv_token_name2  => cv_tkn_request_no        -- �˗�No
                                                        ,iv_token_value2 => i_data_rec.request_no
                                                        ,iv_token_name3  => cv_tkn_deliv_date        -- ���ד�
                                                        ,iv_token_value3 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                                        ,iv_token_name4  => cv_tkn_cust_po_no_f      -- �ڋq�����ԍ�(�ҏW�O)
                                                        ,iv_token_value4 => lt_before_cust_po_number
                                                        ,iv_token_name5  => cv_tkn_cust_po_no_t      -- �ڋq�����ԍ�(�ҏW��)
                                                        ,iv_token_value5 => lt_after_cust_po_number1
                                                      )
                                                    || CHR(10)       -- ���s
                                                    ;
--
        ov_retcode := cv_status_warn; -- �x��
--
      END IF;
--
      -- �ڋq�����ԍ��敪���u1:�ڋq�����ԍ��v�̏ꍇ START
      IF (g_param_rec.customer_po_set_type = cv_cust_po_set_type_po) THEN
        -- ============================================
        -- �����`�F�b�N
        -- ============================================
        -- 13���ȍ~��؂�̂�
        lt_after_cust_po_number2  := SUBSTRB(lt_after_cust_po_number1, cn_cust_po_no_start, cn_cust_po_no_end);
        i_data_rec.cust_po_number := lt_after_cust_po_number2; -- �ڋq�����ԍ�
--
        -- 13���ȍ~��؂�̂Ă��ꍇ�A�x��
        IF (lt_after_cust_po_number1 <> lt_after_cust_po_number2) THEN
--
          gn_cust_po_no_msg_cnt := gn_cust_po_no_msg_cnt + 1;
          g_cust_po_no_msg_tab(gn_cust_po_no_msg_cnt) := gv_separator  -- �Z�p���[�^
                                                      || CHR(10)       -- ���s
                                                      || xxccp_common_pkg.get_msg( -- �ڋq�����ԍ������G���[
                                                           iv_application  => cv_xxcos_appl_short_name
                                                          ,iv_name         => cv_msg_cust_po_err1
                                                          ,iv_token_name1  => cv_tkn_cust_code         -- �ڋq�R�[�h
                                                          ,iv_token_value1 => i_data_rec.customer_code
                                                          ,iv_token_name2  => cv_tkn_request_no        -- �˗�No
                                                          ,iv_token_value2 => i_data_rec.request_no
                                                          ,iv_token_name3  => cv_tkn_deliv_date        -- ���ד�
                                                          ,iv_token_value3 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                                          ,iv_token_name4  => cv_tkn_cust_po_no_f      -- �ڋq�����ԍ�(�ҏW�O)
                                                          ,iv_token_value4 => lt_before_cust_po_number
                                                          ,iv_token_name5  => cv_tkn_cust_po_no_t      -- �ڋq�����ԍ�(�ҏW��)
                                                          ,iv_token_value5 => lt_after_cust_po_number2
                                                        )
                                                      || CHR(10)       -- ���s
                                                      ;
--
          ov_retcode := cv_status_warn; -- �x��
--
        END IF;
--
      END IF; -- �ڋq�����ԍ��敪���u1:�ڋq�����ԍ��v�̏ꍇ END
--
    END IF; -- �ڋq�����ԍ���NULL�łȂ��ꍇ END
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
  END chk_cust_po_no;
--
  /**********************************************************************************
   * Procedure Name   : output_param
   * Description      : ���̓p�����[�^�o��(A-1)
   ***********************************************************************************/
  PROCEDURE output_param(
    iv_delivery_base_code          IN   VARCHAR2        -- 01.�[�i���_�R�[�h
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.���͋��_�R�[�h
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.�Ǌ����_�R�[�h
   ,iv_request_no                  IN   VARCHAR2        -- 04.�o�׈˗�No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.�o�׈˗����͎�
   ,iv_cust_code                   IN   VARCHAR2        -- 06.�ڋq�R�[�h
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.�z����R�[�h
   ,iv_location_code               IN   VARCHAR2        -- 08.�o�Ɍ��R�[�h
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.�o�ɓ��iFROM�j
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.�o�ɓ��iTO�j
   ,iv_request_date_from           IN   VARCHAR2        -- 11.�����iFROM�j
   ,iv_request_date_to             IN   VARCHAR2        -- 12.�����iTO�j
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.�ڋq�����ԍ�
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.�ڋq�����ԍ��敪
   ,iv_uom_type                    IN   VARCHAR2        -- 15.���Z�P�ʋ敪
   ,iv_item_type                   IN   VARCHAR2        -- 16.���i�敪
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.�o�Ɍ`��
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.�̔���`�F�[��
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.�[�i��`�F�[��
   ,ov_errbuf                      OUT  VARCHAR2        --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                     OUT  VARCHAR2        --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                      OUT  VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_param'; -- �v���O������
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
    lt_order_type_name xxwsh_oe_transaction_types_v.transaction_type_name%TYPE; -- �o�Ɍ`�Ԗ�
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
    -- ========================================
    -- �o�Ɍ`�Ԗ��̎擾
    -- ========================================
    -- �o�Ɍ`�ԂɎw�肪����ꍇ�̂ݖ��̂��擾�B
    IF (iv_transaction_type_id IS NOT NULL) THEN
      SELECT ottt.name                  order_type_name
      INTO   lt_order_type_name
      FROM   oe_transaction_types_tl    ottt -- �󒍃^�C�v�|��
      WHERE  ottt.transaction_type_id = TO_NUMBER(iv_transaction_type_id)
      AND    ottt.language            = cv_lang_ja
      ;
    END IF;
--
    -- ========================================
    -- ���̓p�����[�^�o��
    -- ========================================
    lv_errmsg := xxccp_common_pkg.get_msg( -- �p�����[�^�o�̓��b�Z�[�W
                   iv_application  => cv_xxcos_appl_short_name
                  ,iv_name         => cv_msg_get_param_msg1
                  ,iv_token_name1  => cv_tkn_param01
                  ,iv_token_value1 => iv_delivery_base_code     -- 01.�[�i���_�R�[�h
                  ,iv_token_name2  => cv_tkn_param02
                  ,iv_token_value2 => iv_input_sales_branch     -- 02.���͋��_�R�[�h
                  ,iv_token_name3  => cv_tkn_param03
                  ,iv_token_value3 => iv_head_sales_branch      -- 03.�Ǌ����_�R�[�h
                  ,iv_token_name4  => cv_tkn_param04
                  ,iv_token_value4 => iv_request_no             -- 04.�o�׈˗�No
                  ,iv_token_name5  => cv_tkn_param05
                  ,iv_token_value5 => iv_entered_by_code        -- 05.�o�׈˗����͎�
                  ,iv_token_name6  => cv_tkn_param06
                  ,iv_token_value6 => iv_cust_code              -- 06.�ڋq�R�[�h
                  ,iv_token_name7  => cv_tkn_param07
                  ,iv_token_value7 => iv_deliver_to             -- 07.�z����R�[�h
                 );
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg );
--
    lv_errmsg := xxccp_common_pkg.get_msg( -- �p�����[�^�o�̓��b�Z�[�W
                   iv_application  => cv_xxcos_appl_short_name
                  ,iv_name         => cv_msg_get_param_msg2
                  ,iv_token_name1  => cv_tkn_param08
                  ,iv_token_value1 => iv_location_code                -- 08.�o�Ɍ��R�[�h
                  ,iv_token_name2  => cv_tkn_param09
                  ,iv_token_value2 => iv_schedule_ship_date_from      -- 09.�o�ɓ��iFROM�j
                  ,iv_token_name3  => cv_tkn_param10
                  ,iv_token_value3 => iv_schedule_ship_date_to        -- 10.�o�ɓ��iTO�j
                  ,iv_token_name4  => cv_tkn_param11
                  ,iv_token_value4 => iv_request_date_from            -- 11.�����iFROM�j
                  ,iv_token_name5  => cv_tkn_param12
                  ,iv_token_value5 => iv_request_date_to              -- 12.�����iTO�j
                  ,iv_token_name6  => cv_tkn_param13
                  ,iv_token_value6 => iv_cust_po_number               -- 13.�ڋq�����ԍ�
                 );
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg );
--
    lv_errmsg := xxccp_common_pkg.get_msg( -- �p�����[�^�o�̓��b�Z�[�W
                   iv_application  => cv_xxcos_appl_short_name
                  ,iv_name         => cv_msg_get_param_msg3
                  ,iv_token_name1  => cv_tkn_param14
                  ,iv_token_value1 => iv_customer_po_set_type   -- 14.�ڋq�����ԍ��敪
                  ,iv_token_name2  => cv_tkn_param15
                  ,iv_token_value2 => iv_uom_type               -- 15.���Z�P�ʋ敪
                  ,iv_token_name3  => cv_tkn_param16
                  ,iv_token_value3 => iv_item_type              -- 16.���i�敪
                  ,iv_token_name4  => cv_tkn_param17
                  ,iv_token_value4 => lt_order_type_name        -- 17.�o�Ɍ`��
                  ,iv_token_name5  => cv_tkn_param18
                  ,iv_token_value5 => iv_chain_code_sales       -- 18.�̔���`�F�[��
                  ,iv_token_name6  => cv_tkn_param19
                  ,iv_token_value6 => iv_chain_code_deliv       -- 19.�[�i��`�F�[��
                 );
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '' );
--
    -- ========================================
    -- ���̓p�����[�^�Z�b�g
    -- ========================================
    g_param_rec.delivery_base_code         := iv_delivery_base_code;                                -- 01.�[�i���_�R�[�h
    g_param_rec.input_sales_branch         := iv_input_sales_branch;                                -- 02.���͋��_�R�[�h
    g_param_rec.head_sales_branch          := iv_head_sales_branch;                                 -- 03.�Ǌ����_�R�[�h
    g_param_rec.request_no                 := iv_request_no;                                        -- 04.�o�׈˗�No
-- 2010/05/10 Ver1.1 H.Itou Mod Start E_�{�ғ�_02595
--    g_param_rec.entered_by_code            := TO_NUMBER(iv_entered_by_code);                        -- 05.�o�׈˗����͎�
    g_param_rec.entered_by_code            := iv_entered_by_code;                                   -- 05.�o�׈˗����͎�
-- 2010/05/10 Ver1.1 H.Itou Mod End E_�{�ғ�_02595
    g_param_rec.customer_code              := iv_cust_code;                                         -- 06.�ڋq�R�[�h
    g_param_rec.deliver_to                 := iv_deliver_to;                                        -- 07.�z����R�[�h
    g_param_rec.deliver_from               := iv_location_code;                                     -- 08.�o�Ɍ��R�[�h
    g_param_rec.ship_date_from             := TO_DATE(iv_schedule_ship_date_from, cv_fmt_yyyymmdd); -- 09.�o�ɓ��iFROM�j
    g_param_rec.ship_date_to               := TO_DATE(iv_schedule_ship_date_to,   cv_fmt_yyyymmdd); -- 10.�o�ɓ��iTO�j
    g_param_rec.request_date_from          := TO_DATE(iv_request_date_from, cv_fmt_yyyymmdd);       -- 11.�����iFROM�j
    g_param_rec.request_date_to            := TO_DATE(iv_request_date_to,   cv_fmt_yyyymmdd);       -- 12.�����iTO�j
    g_param_rec.cust_po_number             := iv_cust_po_number;                                    -- 13.�ڋq�����ԍ�
    g_param_rec.customer_po_set_type       := iv_customer_po_set_type;                              -- 14.�ڋq�����ԍ��敪
    g_param_rec.uom_type                   := iv_uom_type;                                          -- 15.���Z�P�ʋ敪
    g_param_rec.prod_class_code            := iv_item_type;                                         -- 16.���i�敪
    g_param_rec.order_type_id              := TO_NUMBER(iv_transaction_type_id);                    -- 17.�o�Ɍ`��
    g_param_rec.sales_chain_code           := iv_chain_code_sales;                                  -- 18.�̔���`�F�[��
    g_param_rec.delivery_chain_code        := iv_chain_code_deliv;                                  -- 19.�[�i��`�F�[��
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
  END output_param;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : ���̓p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf                OUT  VARCHAR2        --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT  VARCHAR2        --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT  VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
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
    -- ========================================
    -- ���͋��_�R�[�h�Ɣ[�i���_�R�[�h��NULL�̏ꍇ�A�G���[
    -- ========================================
    IF   ((g_param_rec.input_sales_branch IS NULL)
      AND (g_param_rec.delivery_base_code IS NULL)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- �p�����[�^�K�{�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_chk_param_err
                   );
      RAISE global_api_expt;
--
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-3)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                OUT  VARCHAR2        --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT  VARCHAR2        --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT  VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_status VARCHAR2(100); -- �݌ɉ�v���ԎZ�o�֐� �߂�l�̃X�e�[�^�X
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
    -- ========================================
    -- �v���t�@�C���I�v�V�����擾
    -- ========================================
    gn_interval     := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_interval ) );    -- XXCOS:�ҋ@�Ԋu
    gn_max_wait     := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_max_wait ) );    -- XXCOS:�ő�ҋ@����
    gv_prod_ou_nm   := FND_PROFILE.VALUE( cv_prof_prod_ou );                  -- XXCOS:���Y�c�ƒP�ʎ擾����
    gn_org_id       := FND_PROFILE.VALUE( cv_prof_org_id );                   -- �c�ƒP��
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );                  -- XXCOI:�݌ɑg�D�R�[�h
--
    -- XXCOS:�ҋ@�Ԋu�̎擾���ł��Ȃ��ꍇ�A�G���[�I��
    IF ( gn_interval IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- �v���t�@�C���擾�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_interval_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- XXCOS:�ő�ҋ@���Ԃ̎擾���ł��Ȃ��ꍇ�A�G���[�I��
    IF ( gn_max_wait IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- �v���t�@�C���擾�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_max_wait_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- XXCOS:���Y�c�ƒP�ʎ擾���̂̎擾���ł��Ȃ��ꍇ�A�G���[�I��
    IF ( gv_prod_ou_nm IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- �v���t�@�C���擾�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_prod_ou_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- �c�ƒP�ʂ̎擾���ł��Ȃ��ꍇ�A�G���[�I��
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- �v���t�@�C���擾�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_org_id_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- XXCOI:�݌ɑg�D�R�[�h�̎擾���ł��Ȃ��ꍇ�A�G���[�I��
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- �v���t�@�C���擾�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_inv_org_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- ���Y�c�ƒP��ID�擾
    -- ========================================
    BEGIN
      SELECT hou.organization_id organization_id -- �c�ƒP��ID
      INTO   gt_prod_org_id
      FROM   hr_operating_units  hou             -- ���샆�j�b�g
      WHERE  hou.name         = gv_prod_ou_nm    -- ���Y�c�ƒP�ʖ�
      ;
    EXCEPTION
      -- �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�I��
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg( -- �v���t�@�C���擾�G���[
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_profile_err
                      ,iv_token_name1  => cv_tkn_profile
                      ,iv_token_value1 => cv_prof_prod_ou_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- �c�Ɨp�݌ɑg�DID�擾
    -- ========================================
    --�c�Ɨp�݌ɑg�DID�̎擾
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(gv_inv_org_code);
--
    -- �݌ɑg�DID�擾�G���[�̏ꍇ�A�G���[�I��
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- API�ďo�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_api_call_err
                    ,iv_token_name1  => cv_tkn_api_name
                    ,iv_token_value1 => cv_get_org_id_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- �݌ɉ�v���Ԏ擾
    -- ========================================
    xxcos_common_pkg.get_account_period(
      iv_account_period         => cv_inv              -- ��v�敪
     ,id_base_date              => NULL                -- ���
     ,ov_status                 => lv_status           -- �X�e�[�^�X
     ,od_start_date             => gd_open_date_from   -- ��v(FROM)
     ,od_end_date               => gd_open_date_to     -- ��v(TO)
     ,ov_errbuf                 => lv_errbuf           -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
     ,ov_retcode                => lv_retcode          -- ���^�[���E�R�[�h               #�Œ�#
     ,ov_errmsg                 => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
--
    -- �߂�l���G���[�̏ꍇ�A�G���[�I��
    IF ( lv_retcode = cv_status_error ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- �݌ɉ�v���Ԏ擾�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_acct_period_err
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- �Ɩ����t�擾
    -- ========================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������擾�G���[�̏ꍇ�A�G���[�I��
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- API�ďo�G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_process_date
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- Online�󒍃\�[�X���擾
    -- ========================================
    gt_order_source_name := xxcoi_common_pkg.get_meaning(cv_look_source_type, cv_source_type_online);
--
    IF (gt_order_source_name IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- �}�X�^�`�F�b�N�G���[
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_source_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_lookup_values_tbl_name
                     );
        RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- Online�󒍃\�[�XID�擾
    -- ========================================
    BEGIN
      SELECT oos.order_source_id  order_source_id        -- �󒍃\�[�XID
      INTO   gt_order_source_id
      FROM   oe_order_sources     oos                    -- �󒍃\�[�X
      WHERE  oos.name           = gt_order_source_name   -- �󒍃\�[�X���FOnline
      ;
    EXCEPTION
      -- �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�I��
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- �}�X�^�`�F�b�N�G���[
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_source_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_order_source_tbl_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- �w�b�_�p�󒍃^�C�v�擾
    -- ========================================
    BEGIN
      SELECT ott.name                    order_type_name           -- �󒍃^�C�v��
      INTO   gt_order_type_hdr                                     -- �w�b�_�p�󒍃^�C�v
      FROM   oe_transaction_types_tl     ott                       -- �󒍃^�C�v�|��
            ,oe_transaction_types_all    otl                       -- �󒍃^�C�v
      WHERE  ott.name                  = xxcoi_common_pkg.get_meaning(cv_look_order_type, cv_order_type_normal_hdr)
      AND    ott.transaction_type_id   = otl.transaction_type_id
      AND    otl.transaction_type_code = cv_order                  -- ORDER
      AND    ott.language              = cv_lang_ja                -- ����
      ;
    EXCEPTION
      -- �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�I��
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- �}�X�^�`�F�b�N�G���[
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_type_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_order_type_tbl_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- ���חp�󒍃^�C�v�擾
    -- ========================================
    BEGIN
      SELECT ott.name                    order_type_name           -- �󒍃^�C�v��
      INTO   gt_order_type_line                                    -- ���חp�󒍃^�C�v
      FROM   oe_transaction_types_tl     ott                       -- �󒍃^�C�v�|��
            ,oe_transaction_types_all    otl                       -- �󒍃^�C�v
      WHERE  ott.name                  = xxcoi_common_pkg.get_meaning(cv_look_order_type, cv_order_type_normal_line)
      AND    ott.transaction_type_id   = otl.transaction_type_id
      AND    otl.transaction_type_code = cv_line                   -- LINE
      AND    ott.language              = cv_lang_ja                -- ����
      ;
    EXCEPTION
      -- �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�I��
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- �}�X�^�`�F�b�N�G���[
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_type_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_order_type_tbl_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- �󒍃\�[�X�Q�ƌŒ�l
    -- ========================================
    gt_orig_sys_document_ref := xxcoi_common_pkg.get_meaning(cv_look_document_ref, cv_document_ref);
--
    IF (gt_orig_sys_document_ref IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- �}�X�^�`�F�b�N�G���[
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_headers_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_lookup_values_tbl_name
                     );
        RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- ���b�Z�[�W�Z�p���[�^
    -- ========================================
    gv_separator := xxccp_common_pkg.get_msg(-- ���b�Z�[�W�Z�p���[�^
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_separator
                     );
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
   * Procedure Name   : get_data
   * Description      : �Ώۃf�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_data(
    o_data_tab               OUT  g_target_data_ttype -- �Ώۃf�[�^�i�[�z��ϐ�
   ,ov_errbuf                OUT  VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT  VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT  VARCHAR2)           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    cv_union_all          CONSTANT VARCHAR2(32767) := ' UNION ALL';
--
    -- *** ���[�J���ϐ� ***
    lv_main_sql                    VARCHAR2(32767);        -- ���C��SQL����
-- 2010/05/10 Ver1.1 H.Itou Add Start E_�{�ғ�_02532
    lv_main_sql2                   VARCHAR2(32767);        -- ���C��SQL����
-- 2010/05/10 Ver1.1 H.Itou Add End E_�{�ғ�_02532
    lv_select                      VARCHAR2(32767);        -- SELECT��
    lv_from                        VARCHAR2(32767);        -- FROM��
    lv_where                       VARCHAR2(32767);        -- WHERE��(����)
    lv_where_result                VARCHAR2(32767);        -- WHERE��(���׎��ѓ��ɒl������ꍇ(���уx�[�X))
    lv_where_schedule              VARCHAR2(32767);        -- WHERE��(���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X))
    lv_where_delivery_base_code    VARCHAR2(32767);        -- WHERE��(�p�����[�^����)01.�[�i���_�R�[�h
    lv_where_input_sales_branch    VARCHAR2(32767);        -- WHERE��(�p�����[�^����)02.���͋��_�R�[�h
    lv_where_head_sales_branch     VARCHAR2(32767);        -- WHERE��(�p�����[�^����)03.�Ǌ����_�R�[�h
    lv_where_request_no            VARCHAR2(32767);        -- WHERE��(�p�����[�^����)04.�o�׈˗�No
    lv_where_entered_by_code       VARCHAR2(32767);        -- WHERE��(�p�����[�^����)05.�o�׈˗����͎�
    lv_where_customer_code         VARCHAR2(32767);        -- WHERE��(�p�����[�^����)06.�ڋq�R�[�h
    lv_where_result_deliver_to     VARCHAR2(32767);        -- WHERE��(�p�����[�^����)07.�z����R�[�h(����)
    lv_where_schedule_deliver_to   VARCHAR2(32767);        -- WHERE��(�p�����[�^����)07.�z����R�[�h(�w��)
    lv_where_deliver_from          VARCHAR2(32767);        -- WHERE��(�p�����[�^����)08.�o�Ɍ��R�[�h
    lv_where_result_s_date_from    VARCHAR2(32767);        -- WHERE��(�p�����[�^����)09.�o�ɓ��iFROM�j(����)
    lv_where_schedule_s_date_from  VARCHAR2(32767);        -- WHERE��(�p�����[�^����)09.�o�ɓ��iFROM�j(�w��)
    lv_where_result_s_date_to      VARCHAR2(32767);        -- WHERE��(�p�����[�^����)10.�o�ɓ��iTO�j(����)
    lv_where_schedule_s_date_to    VARCHAR2(32767);        -- WHERE��(�p�����[�^����)10.�o�ɓ��iTO�j(�w��)
    lv_where_result_a_date_from    VARCHAR2(32767);        -- WHERE��(�p�����[�^����)11.�����iFROM�j(����)
    lv_where_schedule_a_date_from  VARCHAR2(32767);        -- WHERE��(�p�����[�^����)11.�����iFROM�j(�w��)
    lv_where_result_a_date_to      VARCHAR2(32767);        -- WHERE��(�p�����[�^����)12.�����iTO�j(����)
    lv_where_schedule_a_date_to    VARCHAR2(32767);        -- WHERE��(�p�����[�^����)12.�����iTO�j(�w��)
    lv_where_cust_po_number        VARCHAR2(32767);        -- WHERE��(�p�����[�^����)13.�ڋq�����ԍ�
    lv_where_prod_class_code       VARCHAR2(32767);        -- WHERE��(�p�����[�^����)16.���i�敪
    lv_where_order_type_id         VARCHAR2(32767);        -- WHERE��(�p�����[�^����)17.�o�Ɍ`��
    lv_where_sales_chain_code      VARCHAR2(32767);        -- WHERE��(�p�����[�^����)18.�̔���`�F�[��
    lv_where_delivery_chain_code   VARCHAR2(32767);        -- WHERE��(�p�����[�^����)19.�[�i��`�F�[��
    lv_order_by                    VARCHAR2(32767);        -- ORDER BY��
--
    -- *** ���[�J���E�J�[�\�� ***
    main_data_cur                  ref_cur ;
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
    -- ========================================
    -- SELECT��쐬
    -- ========================================
    lv_select :=
      '
       SELECT  xoha.request_no                                     request_no                   -- �˗��m��
              ,xoha.cust_po_number                                 cust_po_number               -- �ڋq�����ԍ�
              ,xoha.cust_po_number                                 order_number                 -- �I�[�_�[�m��
              ,hca_cust.cust_account_id                            customer_id                  -- �ڋqID
              ,hca_cust.account_number                             customer_code                -- �ڋq�R�[�h
              ,NVL(xoha.arrival_date, xoha.schedule_arrival_date)  arrival_date                 -- ���ד�
              ,xca_cust.sale_base_code                             sale_base_code               -- ���㋒�_�R�[�h
              ,xca_cust.past_sale_base_code                        past_sale_base_code          -- �O�����㋒�_�R�[�h
              ,xca_cust.rsv_sale_base_code                         rsv_sale_base_code           -- �\�񔄏㋒�_�R�[�h
              ,xca_cust.rsv_sale_base_act_date                     rsv_sale_base_act_date       -- �\�񔄏㋒�_�L���J�n��
              ,hcsa_sales.price_list_id                            price_list_id                -- ���i�\�h�c
              ,xoha.arrival_time_from                              arrival_time_from            -- ���׎���FROM
              ,xoha.arrival_time_to                                arrival_time_to              -- ���׎���TO
              ,xoha.shipping_instructions                          shipping_instructions        -- �o�׎w��
              ,xola.order_line_number                              order_line_number            -- ���הԍ�
              ,NVL(xola.shipped_quantity, xola.quantity)           quantity                     -- ����
              ,NULL                                                conv_quantity                -- ���Z�㐔��
              ,NULL                                                unit_price                   -- �P��
              ,NULL                                                calc_unit_price_flg          -- ���i�v�Z�t���O
              ,xola.request_item_code                              child_item_no                -- �q�i�ڃR�[�h
              ,iimb_parent.item_no                                 parent_item_no               -- �e�i�ڃR�[�h
              ,TO_NUMBER(iimb_parent.attribute11)                  parent_num_of_cases          -- �e�i�ڃP�[�X����
              ,iimb_parent.item_um                                 parent_item_um               -- �e�i�ڊ�P��
              ,iimb_parent.attribute24                             parent_conv_unit             -- �e�i�ړ��o�Ɋ��Z�P��
              ,msib_parent.inventory_item_id                       parent_inv_item_id           -- �e�i�ڂh�m�u�i�ڂh�c
      ';
--
    -- ========================================
    -- FROM��쐬
    -- ========================================
    lv_from :=
      '
       FROM    xxwsh_order_headers_all                             xoha                  -- �󒍃w�b�_�A�h�I��
              ,xxwsh_order_lines_all                               xola                  -- �󒍖��׃A�h�I��
              ,hz_locations                                        hl_prod               -- �ڋq���Ə��}�X�^(���Y�c�Ƒg�D)
              ,hz_party_sites                                      hps_prod              -- �p�[�e�B�T�C�g�}�X�^(���Y�c�Ƒg�D)
              ,hz_cust_acct_sites_all                              hcasa_prod            -- �ڋq���ݒn�}�X�^(���Y�c�Ƒg�D)
              ,hz_cust_site_uses_all                               hcsa_prod             -- �ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D)
              ,xxcmm_cust_accounts                                 xca_cust              -- �ڋq�ǉ����}�X�^(�ڋq)
              ,hz_cust_accounts                                    hca_cust              -- �ڋq�}�X�^(�ڋq)
              ,hz_parties                                          hp_cust               -- �p�[�e�B�}�X�^(�ڋq)
              ,hz_cust_accounts                                    hca_deli_base         -- �ڋq�}�X�^(�[�i���_)
              ,hz_cust_acct_sites_all                              hcasa_sales           -- �ڋq���ݒn�}�X�^(�c�Ƒg�D)
              ,hz_cust_site_uses_all                               hcsa_sales            -- �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D)
              ,ic_item_mst_b                                       iimb_child            -- OPM�i�ڃ}�X�^(�q�i��)
              ,xxcmn_item_mst_b                                    ximb_child            -- OPM�i�ڃ}�X�^�A�h�I��(�q�i��)
              ,ic_item_mst_b                                       iimb_parent           -- OPM�i�ڃ}�X�^(�e�i��)
              ,mtl_system_items_b                                  msib_parent           -- DISC�i�ڃ}�X�^(�e�i��)
              ,xxcmn_item_categories5_v                            xicv_parent           -- �i�ڃJ�e�S���������VIEW5(�e�i��)
              ,fnd_user                                            fu                    -- ���[�U�[
              ,per_all_people_f                                    papf                  -- �]�ƈ�
      ';
--
    -- ========================================
    -- WHERE��(���ʏ���)�쐬
    -- ========================================
    lv_where :=
      '
       WHERE   xoha.order_header_id                       = xola.order_header_id         -- �˗��ɕR�Â����׎擾
       AND     hl_prod.location_id                        = hps_prod.location_id         -- �z����̃p�[�e�B�T�C�g�}�X�^(���Y�c�Ƒg�D)�擾
       AND     hps_prod.party_site_id                     = hcasa_prod.party_site_id     -- �z����̌ڋq���ݒn�}�X�^(���Y�c�Ƒg�D)�擾
       AND     hcasa_prod.cust_acct_site_id               = hcsa_prod.cust_acct_site_id  -- �z����̌ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D)�擾
       AND     hps_prod.party_id                          = hca_cust.party_id            -- �z����̌ڋq�擾
       AND     hca_cust.party_id                          = hp_cust.party_id             -- �z����̌ڋq�̃p�[�e�B�}�X�^�擾
       AND     hca_cust.cust_account_id                   = xca_cust.customer_id         -- �z����̌ڋq�̌ڋq�ǉ����}�X�^�擾
       AND     xca_cust.delivery_base_code                = hca_deli_base.account_number -- �z����̌ڋq�̔[�i�ꏊ�擾
       AND     hca_cust.cust_account_id                   = hcasa_sales.cust_account_id  -- �z����̌ڋq���ݒn�}�X�^(�c�Ƒg�D)�擾
       AND     hcasa_sales.cust_acct_site_id              = hcsa_sales.cust_acct_site_id -- �z����̌ڋq�g�p�ړI�}�X�^(�c�Ƒg�D)�擾
       AND     xola.request_item_code                     = iimb_child.item_no           -- �˗��i��(�q�i��)��OPM�i�ڃ}�X�^�擾
       AND     iimb_child.item_id                         = ximb_child.item_id           -- �˗��i��(�q�i��)��OPM�i�ڃ}�X�^�A�h�I���擾
       AND     ximb_child.parent_item_id                  = iimb_parent.item_id          -- �˗��i��(�q�i��)��OPM�i�ڃ}�X�^(�e�i��)�擾
       AND     iimb_parent.item_no                        = msib_parent.segment1         -- �˗��i��(�q�i��)��DISC�i�ڃ}�X�^(�e�i��)�擾
       AND     iimb_parent.item_id                        = xicv_parent.item_id          -- �˗��i��(�q�i��)�̕i�ڃJ�e�S���������VIEW5(�e�i��)�擾
       AND     xoha.created_by                            = fu.user_id                   -- �󒍃w�b�_�A�h�I���̍쐬���[�U�[�擾
       AND     fu.employee_id                             = papf.person_id               -- �󒍃w�b�_�A�h�I���̍쐬�]�ƈ��擾
       AND     msib_parent.organization_id                = :inv_org_id                  -- DISC�i�ڃ}�X�^(�e�i��).�c�ƒP�ʁ��c�Ɨp�݌ɑg�DID
       AND     iimb_parent.attribute26                    = :sales_flg                   -- OPM�i�ڃ}�X�^(�e�i��).����Ώۋ敪���u1:����Ώہv
       AND     iimb_child.inactive_ind                   <> :active                      -- OPM�i�ڃ}�X�^(�q�i��)�����łȂ�����
       AND     iimb_parent.inactive_ind                  <> :active                      -- OPM�i�ڃ}�X�^(�e�i��)�����łȂ�����
       AND     ximb_child.obsolete_class                 <> :no_obsolete                 -- OPM�i�ڃ}�X�^�A�h�I��(�q�i��)�p�~�łȂ�����
       AND     hcasa_prod.org_id                          = :prod_org_id                 -- �ڋq���ݒn�}�X�^(���Y�c�Ƒg�D).�c�ƒP�ʁ����Y�c�ƒP��ID
       AND     hcsa_prod.site_use_code                    = :site_use                    -- �ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D).�g�p�ړI���uSHIP_TO:�o�א�v
       AND     hcasa_prod.status                          = :status                      -- �ڋq���ݒn�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
       AND     hcsa_prod.status                           = :status                      -- �ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
       AND     hps_prod.status                            = :status                      -- �p�[�e�B�T�C�g�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
       AND     hp_cust.status                             = :status                      -- �p�[�e�B�}�X�^(�ڋq).�X�e�[�^�X���uA:�L���v
       AND     hca_cust.status                            = :status                      -- �ڋq�}�X�^(�ڋq).�X�e�[�^�X���uA:�L���v
       AND     hca_deli_base.status                       = :status                      -- �ڋq�}�X�^(�[�i���_).�X�e�[�^�X���uA:�L���v
       AND     hca_deli_base.customer_class_code          = :customer_class_base         -- �ڋq�}�X�^(�[�i���_).�ڋq�敪���u1:���_�v
       AND     hca_cust.customer_class_code               = :customer_class_cust         -- �ڋq�}�X�^(�ڋq).�ڋq�敪���u10:�ڋq�v
       AND     hcasa_sales.org_id                         = :org_id                      -- �ڋq���ݒn�}�X�^(�c�Ƒg�D).�c�ƒP�ʁ��c�ƒP��ID
       AND     hcsa_sales.site_use_code                   = :site_use                    -- �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).�g�p�ړI���uSHIP_TO:�o�א�v
       AND     hcasa_sales.status                         = :status                      -- �ڋq���ݒn�}�X�^(�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
       AND     hcsa_sales.status                          = :status                      -- �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
       AND     hcsa_sales.primary_flag                    = :primary_flag                -- �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).��t���O���uY�v
       AND     xoha.latest_external_flag                  = :latest_flag                 -- �󒍃w�b�_�A�h�I��.�ŐV�t���O���uY�v
       AND     xoha.req_status                           <> :req_status_99               -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u99:����v�ȊO
       AND     xola.delete_flag                           = :delete_flag_n               -- �󒍖��׃A�h�I��.�폜�t���O���uN�v
       AND     NVL(xola.shipped_quantity, xola.quantity) <> 0                            -- �󒍖��׃A�h�I��.���ʂ�0�łȂ�
       AND     NOT EXISTS(
                 SELECT 1
                 FROM   oe_order_headers_all       ooha                                  -- �󒍃w�b�_
                       ,oe_order_lines_all         oola                                  -- �󒍖���
                       ,mtl_secondary_inventories  mtsi                                  -- �ۊǏꏊ�}�X�^
                 WHERE  ooha.header_id            = oola.header_id                       -- �󒍃w�b�_�ɕR�Â��󒍖��׎擾
                 AND    oola.subinventory         = mtsi.secondary_inventory_name        -- �󒍖���.�ۊǏꏊ���ۊǏꏊ�}�X�^.�ۊǏꏊ�R�[�h
                 AND    oola.ship_from_org_id     = mtsi.organization_id                 -- �󒍖���.�o�׌��g�DID���ۊǏꏊ�}�X�^.�g�DID
                 AND    ooha.org_id               = :org_id                              -- �󒍃w�b�_.�g�DID���c�ƒP��
                 AND    mtsi.attribute13          = :kbn_direct                          -- �ۊǏꏊ�}�X�^.�ۊǏꏊ���ށ��u11:�����v
                 AND    oola.packing_instructions = xoha.request_no                      -- �󒍖���.����w�����󒍃w�b�_�A�h�I��.�˗�No
                 AND    oola.request_date        >= :open_date                           -- �󒍖���.�v�������݌ɉ�v����(FROM)�ȍ~
                 AND    oola.flow_status_code     IN (:entered,:booked,:closed)          -- �󒍖���.�X�e�[�^�X���uENTERED:���͍ρv�uBOOKED:�L���ρv�uCLOSED:�N���[�Y�v
                 AND    NOT EXISTS ( -- �q�i�ڂ��e�i�ڂ���݌ɕi�ڂ̏ꍇ�A����
                          SELECT 1
                          FROM   fnd_lookup_values  flv
                          WHERE  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code -- �q�i�ڂ��e�i�ڂ���݌ɕi
                          AND    flv.lookup_type             = :no_inv_item_type          -- XXCOS1_NO_INV_ITEM_CODE�F��݌ɕi�ڃR�[�h
                          AND    NVL(flv.start_date_active, :open_date) <= :open_date
                          AND    NVL(flv.end_date_active, :open_date)   >= :open_date
                          AND    flv.enabled_flag            = :enabled_flag_y            -- �L���t���O�uY�v
                          AND    flv.language                = :lang_ja                   -- ����uJA�v
                        )
               )
      ';
--
    -- ===================================================
    -- WHERE��(���׎��ѓ��ɒl������ꍇ(���уx�[�X))�쐬
    -- ===================================================
    lv_where_result :=
      '
       AND     xoha.result_deliver_to        = hl_prod.province                           -- �z����_���тŌڋq���Ə�������
       AND     xoha.arrival_date            IS NOT NULL                                   -- �w�b�_�Ɏ��т��o�^����Ă���f�[�^
       AND  (((xoha.req_status               = :req_status_04))                           -- �X�e�[�^�X��04��
         OR  ((xoha.req_status               = :req_status_03)                            -- �X�e�[�^�X��03�Œ��ח\����ɒl������
         AND  (xoha.schedule_arrival_date   IS NOT NULL      )))                          -- (�w���Ȃ����тŃX�e�[�^�X03�͏����ΏۂƂ��Ȃ�)
       AND     xoha.arrival_date            >= :open_date                                 -- ���ד����݌ɉ�v����(FROM)�ȍ~
       AND     ximb_child.start_date_active <= TRUNC(SYSDATE)                             -- �˗��i��(�q�i��)��OPM�i�ڃ}�X�^�A�h�I���擾
       AND     ximb_child.end_date_active   >= TRUNC(SYSDATE)                             -- �˗��i��(�q�i��)��OPM�i�ڃ}�X�^�A�h�I���擾
       AND     fu.start_date                <= xoha.arrival_date                          -- �󒍃w�b�_�A�h�I���̍쐬���[�U�[�擾
       AND     NVL(fu.end_date, xoha.arrival_date) >= xoha.arrival_date                   -- �󒍃w�b�_�A�h�I���̍쐬���[�U�[�擾
       AND     papf.effective_start_date    <= xoha.arrival_date                          -- �󒍃w�b�_�A�h�I���̍쐬�]�ƈ��擾
       AND     NVL(papf.effective_end_date, xoha.arrival_date) >= xoha.arrival_date       -- �󒍃w�b�_�A�h�I���̍쐬�]�ƈ��擾
      ';
--
    -- ===================================================
    -- WHERE��(���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X))�쐬
    -- ===================================================
    lv_where_schedule :=
      '
       AND     xoha.deliver_to               = hl_prod.province                           -- �z����_�\��Ōڋq���Ə�������
       AND     xoha.arrival_date            IS NULL                                       -- �w�b�_�Ɏ��т��o�^����Ă��Ȃ��f�[�^
       AND     xoha.req_status              IN (:req_status01,:req_status02,:req_status03)-- �X�e�[�^�X01��02��03
       AND     xoha.schedule_arrival_date   >= :open_date                                 -- ���ד����݌ɉ�v����(FROM)�ȍ~
       AND     ximb_child.start_date_active <= TRUNC(SYSDATE)                             -- �˗��i��(�q�i��)��OPM�i�ڃ}�X�^�A�h�I���擾
       AND     ximb_child.end_date_active   >= TRUNC(SYSDATE)                             -- �˗��i��(�q�i��)��OPM�i�ڃ}�X�^�A�h�I���擾
       AND     fu.start_date                <= xoha.schedule_arrival_date                 -- �󒍃w�b�_�A�h�I���̍쐬���[�U�[�擾
       AND     NVL(fu.end_date, xoha.schedule_arrival_date) >= xoha.schedule_arrival_date -- �󒍃w�b�_�A�h�I���̍쐬���[�U�[�擾
       AND     papf.effective_start_date    <= xoha.schedule_arrival_date                 -- �󒍃w�b�_�A�h�I���̍쐬�]�ƈ��擾
       AND     NVL(papf.effective_end_date, xoha.schedule_arrival_date) >= xoha.schedule_arrival_date -- �󒍃w�b�_�A�h�I���̍쐬�]�ƈ��擾
      ';
--
    -- ===================================================
    -- WHERE��(�p�����[�^����)�쐬
    -- ===================================================
--
    -- 01.�[�i���_�R�[�h
    IF (g_param_rec.delivery_base_code IS NOT NULL) THEN
      lv_where_delivery_base_code :=
        ' AND     xca_cust.delivery_base_code   = :delivery_base_code                    -- �ڋq�ǉ����}�X�^(�ڋq).�[�i���_�R�[�h���p�����[�^.�[�i���_�R�[�h
      ';
--
    ELSE
      lv_where_delivery_base_code :=
        ' AND     :delivery_base_code          IS NULL
      ';
    END IF;
--
    -- 02.���͋��_�R�[�h
    IF (g_param_rec.input_sales_branch IS NOT NULL) THEN
      lv_where_input_sales_branch :=
        ' AND     xoha.input_sales_branch       = :input_sales_branch                    -- �󒍃w�b�_�A�h�I��.���͋��_���p�����[�^.���͋��_
      ';
--
    ELSE
      lv_where_input_sales_branch :=
        ' AND     :input_sales_branch          IS NULL
      ';
    END IF;
--
    -- 03.�Ǌ����_�R�[�h
    IF (g_param_rec.head_sales_branch IS NOT NULL) THEN
      lv_where_head_sales_branch  :=
        ' AND     xoha.head_sales_branch        = :head_sales_branch                     -- �󒍃w�b�_�A�h�I��.�Ǌ����_���p�����[�^.�Ǌ����_
      ';
--
    ELSE
      lv_where_head_sales_branch  :=
        ' AND     :head_sales_branch           IS NULL
      ';
    END IF;
--
    -- 04.�o�׈˗�No
    IF (g_param_rec.request_no IS NOT NULL) THEN
      lv_where_request_no         :=
        ' AND     xoha.request_no               = :request_no                            -- �󒍃w�b�_�A�h�I��.�˗�No���p�����[�^.�o�׈˗�No
      ';
--
    ELSE
      lv_where_request_no         :=
        ' AND     :request_no                  IS NULL
      ';
    END IF;
--
    -- 05.�o�׈˗����͎�
    IF (g_param_rec.entered_by_code IS NOT NULL) THEN
      lv_where_entered_by_code         :=
        ' AND     papf.employee_number          = :entered_by_code                       -- �]�ƈ�.�]�ƈ��ԍ����p�����[�^.�o�׈˗����͎�
      ';
--
    ELSE
      lv_where_entered_by_code         :=
        ' AND     :entered_by_code             IS NULL
      ';
    END IF;
--
    -- 06.�ڋq�R�[�h
    IF (g_param_rec.customer_code IS NOT NULL) THEN
      lv_where_customer_code      :=
        ' AND     hca_cust.account_number       = :customer_code                         -- �ڋq�}�X�^(�ڋq).�ڋq�ԍ����p�����[�^.�ڋq�R�[�h
      ';
--
    ELSE
      lv_where_customer_code      :=
        ' AND     :customer_code               IS NULL
      ';
    END IF;
--
    -- 07.�z����R�[�h
    IF (g_param_rec.deliver_to IS NOT NULL) THEN
      lv_where_result_deliver_to :=
        ' AND     xoha.result_deliver_to        = :deliver_to                            -- �󒍃w�b�_�A�h�I��.�z����_���с��p�����[�^.�z����R�[�h
      ';
      lv_where_schedule_deliver_to :=
        ' AND     xoha.deliver_to               = :deliver_to                            -- �󒍃w�b�_�A�h�I��.�z����_�w�����p�����[�^.�z����R�[�h
      ';
--
    ELSE
      lv_where_result_deliver_to :=
        ' AND     :deliver_to                  IS NULL
      ';
      lv_where_schedule_deliver_to :=
        ' AND     :deliver_to                  IS NULL
      ';
    END IF;
--
    -- 08.�o�Ɍ��R�[�h
    IF (g_param_rec.deliver_from IS NOT NULL) THEN
      lv_where_deliver_from       :=
        ' AND     xoha.deliver_from             = :deliver_from                          -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ���p�����[�^.�o�Ɍ��R�[�h
      ';
--
    ELSE
      lv_where_deliver_from       :=
        ' AND     :deliver_from                IS NULL
      ';
    END IF;
--
    -- 09.�o�ɓ��iFROM�j
    IF (g_param_rec.ship_date_from IS NOT NULL) THEN
      lv_where_result_s_date_from  :=
        ' AND     xoha.shipped_date            >= :ship_date_from                        -- �󒍃w�b�_�A�h�I��.�o�ɓ������p�����[�^.�o�ɓ��iFROM�j
      ';
      lv_where_schedule_s_date_from  :=
        ' AND     xoha.schedule_ship_date      >= :ship_date_from                        -- �󒍃w�b�_�A�h�I��.�o�ɗ\��������p�����[�^.�o�ɓ��iFROM�j
      ';
--
    ELSE
      lv_where_result_s_date_from  :=
        ' AND     :ship_date_from              IS NULL
      ';
      lv_where_schedule_s_date_from  :=
        ' AND     :ship_date_from              IS NULL
      ';
    END IF;
--
    -- 10.�o�ɓ��iTO�j
    IF (g_param_rec.ship_date_to IS NOT NULL) THEN
      lv_where_result_s_date_to :=
        ' AND     xoha.shipped_date            <= :ship_date_to                          -- �󒍃w�b�_�A�h�I��.�o�ɓ������p�����[�^.�o�ɓ��iTO�j
      ';
      lv_where_schedule_s_date_to :=
        ' AND     xoha.schedule_ship_date      <= :ship_date_to                          -- �󒍃w�b�_�A�h�I��.�o�ɗ\��������p�����[�^.�o�ɓ��iTO�j
      ';
--
    ELSE
      lv_where_result_s_date_to :=
        ' AND     :ship_date_to                IS NULL
      ';
      lv_where_schedule_s_date_to :=
        ' AND     :ship_date_to                IS NULL
      ';
    END IF;
--
    -- 11.�����iFROM�j
    IF (g_param_rec.request_date_from IS NOT NULL) THEN
      lv_where_result_a_date_from  :=
        ' AND     xoha.arrival_date            >= :request_date_from                     -- �󒍃w�b�_�A�h�I��.���������p�����[�^.�����iFROM�j
      ';
      lv_where_schedule_a_date_from  :=
        ' AND     xoha.schedule_arrival_date   >= :request_date_from                     -- �󒍃w�b�_�A�h�I��.�����\��������p�����[�^.�����iFROM�j
      ';
--
    ELSE
      lv_where_result_a_date_from  :=
        ' AND     :request_date_from           IS NULL
      ';
      lv_where_schedule_a_date_from  :=
        ' AND     :request_date_from           IS NULL
      ';
    END IF;
--
    -- 12.�����iTO�j
    IF (g_param_rec.request_date_to IS NOT NULL) THEN
      lv_where_result_a_date_to :=
        ' AND     xoha.arrival_date            <= :request_date_to                       -- �󒍃w�b�_�A�h�I��.���������p�����[�^.�����iTO�j
      ';
      lv_where_schedule_a_date_to :=
        ' AND     xoha.schedule_arrival_date   <= :request_date_to                       -- �󒍃w�b�_�A�h�I��.�����\��������p�����[�^.�����iTO�j
      ';
--
    ELSE
      lv_where_result_a_date_to :=
        ' AND     :request_date_to             IS NULL
      ';
      lv_where_schedule_a_date_to :=
        ' AND     :request_date_to             IS NULL
      ';
    END IF;
--
    -- 13.�ڋq�����ԍ�
    IF (g_param_rec.cust_po_number IS NOT NULL) THEN
      lv_where_cust_po_number     :=
        ' AND     xoha.cust_po_number           = :cust_po_number                        -- �󒍃w�b�_�A�h�I��.�ڋq�����ԍ����p�����[�^.�ڋq�����ԍ�
      ';
--
    ELSE
      lv_where_cust_po_number     :=
        ' AND     :cust_po_number              IS NULL
      ';
    END IF;
--
    -- 16.���i�敪
    IF (g_param_rec.prod_class_code IS NOT NULL) THEN
      lv_where_prod_class_code     :=
        ' AND     xicv_parent.prod_class_code   = :prod_class_code                       -- �i�ڃJ�e�S���������VIEW5.���i�敪���p�����[�^.���i�敪
      ';
--
    ELSE
      lv_where_prod_class_code     :=
        ' AND     :prod_class_code             IS NULL
      ';
    END IF;
--
    -- 17.�o�Ɍ`��
    IF (g_param_rec.order_type_id IS NOT NULL) THEN
      lv_where_order_type_id     :=
        ' AND     xoha.order_type_id            = :order_type_id                         -- �󒍃w�b�_�A�h�I��.�󒍃^�C�v���p�����[�^.�o�Ɍ`��
      ';
--
    ELSE
      lv_where_order_type_id     :=
        ' AND     :order_type_id               IS NULL
      ';
    END IF;
--
    -- 18.�̔���`�F�[��
    IF (g_param_rec.sales_chain_code IS NOT NULL) THEN
      lv_where_sales_chain_code         :=
        ' AND     xca_cust.sales_chain_code     = :sales_chain_code                      -- �ڋq�ǉ����}�X�^(�ڋq).�̔���`�F�[���R�[�h���p�����[�^.�̔���`�F�[��
      ';
--
    ELSE
      lv_where_sales_chain_code         :=
        ' AND     :sales_chain_code            IS NULL
      ';
    END IF;
--
    -- 19.�[�i��`�F�[��
    IF (g_param_rec.delivery_chain_code IS NOT NULL) THEN
      lv_where_delivery_chain_code :=
        ' AND     xca_cust.delivery_chain_code  = :delivery_chain_code                   -- �ڋq�ǉ����}�X�^(�ڋq).�[�i��`�F�[���R�[�h���p�����[�^.�[�i��`�F�[��
       ';
--
    ELSE
      lv_where_delivery_chain_code :=
        ' AND     :delivery_chain_code         IS NULL
      ';
    END IF;
--
    -- ===================================================
    -- WHERE��(�p�����[�^����)�쐬
    -- ===================================================
    lv_order_by :=
      '
       ORDER BY request_no
               ,order_line_number
     ';
--
    -- ======================================
    -- SQL�쐬
    -- ======================================
    lv_main_sql :=  --------------------------------------------------------------------------------------
                    -- ���׎��ѓ��ɒl������ꍇ(���уx�[�X)���w���Ȃ����тŃX�e�[�^�X03�͑ΏۂƂ��Ȃ�
                    --------------------------------------------------------------------------------------
                    lv_select                              -- SELECT��
                ||  lv_from                                -- FROM��
                ||  lv_where                               -- WHERE��(����)
                ||  lv_where_result                        -- WHERE��(���׎��ѓ��ɒl������ꍇ(���уx�[�X))
                ||  lv_where_delivery_base_code            -- WHERE��(�p�����[�^����)01.�[�i���_�R�[�h
                ||  lv_where_input_sales_branch            -- WHERE��(�p�����[�^����)02.���͋��_�R�[�h
                ||  lv_where_head_sales_branch             -- WHERE��(�p�����[�^����)03.�Ǌ����_�R�[�h
                ||  lv_where_request_no                    -- WHERE��(�p�����[�^����)04.�o�׈˗�No
                ||  lv_where_entered_by_code               -- WHERE��(�p�����[�^����)05.�o�׈˗����͎�
                ||  lv_where_customer_code                 -- WHERE��(�p�����[�^����)06.�ڋq�R�[�h
                ||  lv_where_result_deliver_to             -- WHERE��(�p�����[�^����)07.�z����R�[�h(����)
                ||  lv_where_deliver_from                  -- WHERE��(�p�����[�^����)08.�o�Ɍ��R�[�h
                ||  lv_where_result_s_date_from            -- WHERE��(�p�����[�^����)09.�o�ɓ��iFROM�j(����)
                ||  lv_where_result_s_date_to              -- WHERE��(�p�����[�^����)10.�o�ɓ��iTO�j(����)
                ||  lv_where_result_a_date_from            -- WHERE��(�p�����[�^����)11.�����iFROM�j(����)
                ||  lv_where_result_a_date_to              -- WHERE��(�p�����[�^����)12.�����iTO�j(����)
                ||  lv_where_cust_po_number                -- WHERE��(�p�����[�^����)13.�ڋq�����ԍ�
                ||  lv_where_prod_class_code               -- WHERE��(�p�����[�^����)16.���i�敪
                ||  lv_where_order_type_id                 -- WHERE��(�p�����[�^����)17.�o�Ɍ`��
                ||  lv_where_sales_chain_code              -- WHERE��(�p�����[�^����)18.�̔���`�F�[��
                ||  lv_where_delivery_chain_code           -- WHERE��(�p�����[�^����)19.�[�i��`�F�[��
-- 2010/05/10 Ver1.1 H.Itou Mod Start E_�{�ғ�_02532
                ;
    lv_main_sql2 :=
                    --------------------------------------------------------------------------------------
                    -- ���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X)
                    --------------------------------------------------------------------------------------
--                ||  cv_union_all                           -- UNION ALL
                    cv_union_all                           -- UNION ALL
-- 2010/05/10 Ver1.1 H.Itou Mod End E_�{�ғ�_02532
                ||  lv_select                              -- SELECT��
                ||  lv_from                                -- FROM��
                ||  lv_where                               -- WHERE��(����)
                ||  lv_where_schedule                      -- WHERE��(���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X))
                ||  lv_where_delivery_base_code            -- WHERE��(�p�����[�^����)01.�[�i���_�R�[�h
                ||  lv_where_input_sales_branch            -- WHERE��(�p�����[�^����)02.���͋��_�R�[�h
                ||  lv_where_head_sales_branch             -- WHERE��(�p�����[�^����)03.�Ǌ����_�R�[�h
                ||  lv_where_request_no                    -- WHERE��(�p�����[�^����)04.�o�׈˗�No
                ||  lv_where_entered_by_code               -- WHERE��(�p�����[�^����)05.�o�׈˗����͎�
                ||  lv_where_customer_code                 -- WHERE��(�p�����[�^����)06.�ڋq�R�[�h
                ||  lv_where_schedule_deliver_to           -- WHERE��(�p�����[�^����)07.�z����R�[�h(�w��)
                ||  lv_where_deliver_from                  -- WHERE��(�p�����[�^����)08.�o�Ɍ��R�[�h
                ||  lv_where_schedule_s_date_from          -- WHERE��(�p�����[�^����)09.�o�ɓ��iFROM�j(�w��)
                ||  lv_where_schedule_s_date_to            -- WHERE��(�p�����[�^����)10.�o�ɓ��iTO�j(�w��)
                ||  lv_where_schedule_a_date_from          -- WHERE��(�p�����[�^����)11.�����iFROM�j(�w��)
                ||  lv_where_schedule_a_date_to            -- WHERE��(�p�����[�^����)12.�����iTO�j(�w��)
                ||  lv_where_cust_po_number                -- WHERE��(�p�����[�^����)13.�ڋq�����ԍ�
                ||  lv_where_prod_class_code               -- WHERE��(�p�����[�^����)16.���i�敪
                ||  lv_where_order_type_id                 -- WHERE��(�p�����[�^����)17.�o�Ɍ`��
                ||  lv_where_sales_chain_code              -- WHERE��(�p�����[�^����)18.�̔���`�F�[��
                ||  lv_where_delivery_chain_code           -- WHERE��(�p�����[�^����)19.�[�i��`�F�[��
                ||  lv_order_by                            -- ORDER BY��
           ;
--
    -- ======================================
    -- �J�[�\��OPEN
    -- ======================================
-- 2010/05/10 Ver1.1 H.Itou Mod Start E_�{�ғ�_02532
--    OPEN  main_data_cur FOR lv_main_sql
    OPEN  main_data_cur FOR lv_main_sql || lv_main_sql2
-- 2010/05/10 Ver1.1 H.Itou Mod End E_�{�ғ�_02532
    USING --------------------------------------------------------------------------------------
          -- ���׎��ѓ��ɒl������ꍇ(���уx�[�X)���w���Ȃ����тŃX�e�[�^�X03�͑ΏۂƂ��Ȃ�
          --------------------------------------------------------------------------------------
          gn_inv_org_id                        -- WHERE��(����)  DISC�i�ڃ}�X�^(�e�i��).�c�ƒP�ʁ��c�Ɨp�݌ɑg�DID
         ,cv_sale_flg_y                        -- WHERE��(����)  OPM�i�ڃ}�X�^(�e�i��).����Ώۋ敪���u1:����Ώہv
         ,cv_item_active                       -- WHERE��(����)  OPM�i�ڃ}�X�^(�q�i��)�����łȂ�����
         ,cv_item_active                       -- WHERE��(����)  OPM�i�ڃ}�X�^(�e�i��)�����łȂ�����
         ,cv_no_obsolete                       -- WHERE��(����)  OPM�i�ڃ}�X�^�A�h�I��(�q�i��)�p�~�łȂ�����
         ,gt_prod_org_id                       -- WHERE��(����)  �ڋq���ݒn�}�X�^(���Y�c�Ƒg�D).�c�ƒP�ʁ����Y�c�ƒP��ID
         ,cv_site_user_ship_to                 -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D).�g�p�ړI���uSHIP_TO:�o�א�v
         ,cv_active_status                     -- WHERE��(����)  �ڋq���ݒn�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �p�[�e�B�T�C�g�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �p�[�e�B�}�X�^(�ڋq).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�}�X�^(�ڋq).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�}�X�^(�[�i���_).�X�e�[�^�X���uA:�L���v
         ,cv_customer_class_base               -- WHERE��(����)  �ڋq�}�X�^(�[�i���_).�ڋq�敪���u1:���_�v
         ,cv_customer_class_cust               -- WHERE��(����)  �ڋq�}�X�^(�ڋq).�ڋq�敪���u10:�ڋq�v
         ,gn_org_id                            -- WHERE��(����)  �ڋq���ݒn�}�X�^(�c�Ƒg�D).�c�ƒP�ʁ��c�ƒP��ID
         ,cv_site_user_ship_to                 -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).�g�p�ړI���uSHIP_TO:�o�א�v
         ,cv_active_status                     -- WHERE��(����)  �ڋq���ݒn�}�X�^(�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_primary_flag_y                    -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).��t���O���uY�v
         ,cv_latest_flag_y                     -- WHERE��(����)  �󒍃w�b�_�A�h�I��.�ŐV�t���O���uY�v
         ,cv_req_status_99                     -- WHERE��(����)  �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u99:����v�ȊO
         ,cv_delete_flag_n                     -- WHERE��(����)  �󒍖��׃A�h�I��.�폜�t���O���uN�v
         ,gn_org_id                            -- WHERE��(����)  �󒍃w�b�_.�g�DID���c�ƒP��
         ,cv_kbn_direct                        -- WHERE��(����)  �ۊǏꏊ�}�X�^.�ۊǏꏊ���ށ��u11:�����v
         ,gd_open_date_from                    -- WHERE��(����)  �󒍖���.�v�������݌ɉ�v����(FROM)�ȍ~
         ,cv_entered                           -- WHERE��(����)  �󒍖���.�X�e�[�^�X���uENTERED:���͍ρv
         ,cv_booked                            -- WHERE��(����)  �󒍖���.�X�e�[�^�X���uBOOKED:�L���ρv
         ,cv_closed                            -- WHERE��(����)  �󒍖���.�X�e�[�^�X���uCLOSED:�N���[�Y�v
         ,cv_no_inv_item_type                  -- WHERE��(����)  XXCOS1_NO_INV_ITEM_CODE�F��݌ɕi�ڃR�[�h
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�J�n��
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�J�n��
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�I����
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�I����
         ,cv_enabled_flag_y                    -- WHERE��(����)  �L���t���O�uY�v
         ,cv_lang_ja                           -- WHERE��(����)  ����uJA�v
         ,cv_req_status_04                     -- WHERE��(���׎��ѓ��ɒl������ꍇ(���уx�[�X))  �X�e�[�^�X��04��
         ,cv_req_status_03                     -- WHERE��(���׎��ѓ��ɒl������ꍇ(���уx�[�X))  �X�e�[�^�X��03�Œ��ח\����ɒl������
         ,gd_open_date_from                    -- WHERE��(���׎��ѓ��ɒl������ꍇ(���уx�[�X))  ���ד����݌ɉ�v����(FROM)�ȍ~
         ,g_param_rec.delivery_base_code       -- WHERE��(�p�����[�^����)  01.�[�i���_�R�[�h
         ,g_param_rec.input_sales_branch       -- WHERE��(�p�����[�^����)  02.���͋��_�R�[�h
         ,g_param_rec.head_sales_branch        -- WHERE��(�p�����[�^����)  03.�Ǌ����_�R�[�h
         ,g_param_rec.request_no               -- WHERE��(�p�����[�^����)  04.�o�׈˗�No
         ,g_param_rec.entered_by_code          -- WHERE��(�p�����[�^����)  05.�o�׈˗����͎�
         ,g_param_rec.customer_code            -- WHERE��(�p�����[�^����)  06.�ڋq�R�[�h
         ,g_param_rec.deliver_to               -- WHERE��(�p�����[�^����)  07.�z����R�[�h
         ,g_param_rec.deliver_from             -- WHERE��(�p�����[�^����)  08.�o�Ɍ��R�[�h
         ,g_param_rec.ship_date_from           -- WHERE��(�p�����[�^����)  09.�o�ɓ��iFROM�j
         ,g_param_rec.ship_date_to             -- WHERE��(�p�����[�^����)  10.�o�ɓ��iTO�j
         ,g_param_rec.request_date_from        -- WHERE��(�p�����[�^����)  11.�����iFROM�j
         ,g_param_rec.request_date_to          -- WHERE��(�p�����[�^����)  12.�����iTO�j
         ,g_param_rec.cust_po_number           -- WHERE��(�p�����[�^����)  13.�ڋq�����ԍ�
         ,g_param_rec.prod_class_code          -- WHERE��(�p�����[�^����)  16.���i�敪
         ,g_param_rec.order_type_id            -- WHERE��(�p�����[�^����)  17.�o�Ɍ`��
         ,g_param_rec.sales_chain_code         -- WHERE��(�p�����[�^����)  18.�̔���`�F�[��
         ,g_param_rec.delivery_chain_code      -- WHERE��(�p�����[�^����)  19.�[�i��`�F�[��
          --------------------------------------------------------------------------------------
          -- ���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X)
          --------------------------------------------------------------------------------------
         ,gn_inv_org_id                        -- WHERE��(����)  DISC�i�ڃ}�X�^(�e�i��).�c�ƒP�ʁ��c�Ɨp�݌ɑg�DID
         ,cv_sale_flg_y                        -- WHERE��(����)  OPM�i�ڃ}�X�^(�e�i��).����Ώۋ敪���u1:����Ώہv
         ,cv_item_active                       -- WHERE��(����)  OPM�i�ڃ}�X�^(�q�i��)�����łȂ�����
         ,cv_item_active                       -- WHERE��(����)  OPM�i�ڃ}�X�^(�e�i��)�����łȂ�����
         ,cv_no_obsolete                       -- WHERE��(����)  OPM�i�ڃ}�X�^�A�h�I��(�q�i��)�p�~�łȂ�����
         ,gt_prod_org_id                       -- WHERE��(����)  �ڋq���ݒn�}�X�^(���Y�c�Ƒg�D).�c�ƒP�ʁ����Y�c�ƒP��ID
         ,cv_site_user_ship_to                 -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D).�g�p�ړI���uSHIP_TO:�o�א�v
         ,cv_active_status                     -- WHERE��(����)  �ڋq���ݒn�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �p�[�e�B�T�C�g�}�X�^(���Y�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �p�[�e�B�}�X�^(�ڋq).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�}�X�^(�ڋq).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�}�X�^(�[�i���_).�X�e�[�^�X���uA:�L���v
         ,cv_customer_class_base               -- WHERE��(����)  �ڋq�}�X�^(�[�i���_).�ڋq�敪���u1:���_�v
         ,cv_customer_class_cust               -- WHERE��(����)  �ڋq�}�X�^(�ڋq).�ڋq�敪���u10:�ڋq�v
         ,gn_org_id                            -- WHERE��(����)  �ڋq���ݒn�}�X�^(�c�Ƒg�D).�c�ƒP�ʁ��c�ƒP��ID
         ,cv_site_user_ship_to                 -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).�g�p�ړI���uSHIP_TO:�o�א�v
         ,cv_active_status                     -- WHERE��(����)  �ڋq���ݒn�}�X�^(�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_active_status                     -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).�X�e�[�^�X���uA:�L���v
         ,cv_primary_flag_y                    -- WHERE��(����)  �ڋq�g�p�ړI�}�X�^(�c�Ƒg�D).��t���O���uY�v
         ,cv_latest_flag_y                     -- WHERE��(����)  �󒍃w�b�_�A�h�I��.�ŐV�t���O���uY�v
         ,cv_req_status_99                     -- WHERE��(����)  �󒍃w�b�_�A�h�I��.�X�e�[�^�X���u99:����v�ȊO
         ,cv_delete_flag_n                     -- WHERE��(����)  �󒍖��׃A�h�I��.�폜�t���O���uN�v
         ,gn_org_id                            -- WHERE��(����)  �󒍃w�b�_.�g�DID���c�ƒP��
         ,cv_kbn_direct                        -- WHERE��(����)  �ۊǏꏊ�}�X�^.�ۊǏꏊ���ށ��u11:�����v
         ,gd_open_date_from                    -- WHERE��(����)  �󒍖���.�v�������݌ɉ�v����(FROM)�ȍ~
         ,cv_entered                           -- WHERE��(����)  �󒍖���.�X�e�[�^�X���uENTERED:���͍ρv
         ,cv_booked                            -- WHERE��(����)  �󒍖���.�X�e�[�^�X���uBOOKED:�L���ρv
         ,cv_closed                            -- WHERE��(����)  �󒍖���.�X�e�[�^�X���uCLOSED:�N���[�Y�v
         ,cv_no_inv_item_type                  -- WHERE��(����)  XXCOS1_NO_INV_ITEM_CODE�F��݌ɕi�ڃR�[�h
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�J�n��
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�J�n��
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�I����
         ,gd_open_date_from                    -- WHERE��(����)  �N�C�b�N�R�[�h.�E�v�I����
         ,cv_enabled_flag_y                    -- WHERE��(����)  �L���t���O�uY�v
         ,cv_lang_ja                           -- WHERE��(����)  ����uJA�v
         ,cv_req_status_03                     -- WHERE��(���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X))  �X�e�[�^�X��03��
         ,cv_req_status_02                     -- WHERE��(���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X))  �X�e�[�^�X��02��
         ,cv_req_status_01                     -- WHERE��(���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X))  �X�e�[�^�X��01
         ,gd_open_date_from                    -- WHERE��(���׎��ѓ��ɒl���Ȃ��ꍇ(�w���x�[�X))  ���ד����݌ɉ�v����(FROM)�ȍ~
         ,g_param_rec.delivery_base_code       -- WHERE��(�p�����[�^����)  01.�[�i���_�R�[�h
         ,g_param_rec.input_sales_branch       -- WHERE��(�p�����[�^����)  02.���͋��_�R�[�h
         ,g_param_rec.head_sales_branch        -- WHERE��(�p�����[�^����)  03.�Ǌ����_�R�[�h
         ,g_param_rec.request_no               -- WHERE��(�p�����[�^����)  04.�o�׈˗�No
         ,g_param_rec.entered_by_code          -- WHERE��(�p�����[�^����)  05.�o�׈˗����͎�
         ,g_param_rec.customer_code            -- WHERE��(�p�����[�^����)  06.�ڋq�R�[�h
         ,g_param_rec.deliver_to               -- WHERE��(�p�����[�^����)  07.�z����R�[�h
         ,g_param_rec.deliver_from             -- WHERE��(�p�����[�^����)  08.�o�Ɍ��R�[�h
         ,g_param_rec.ship_date_from           -- WHERE��(�p�����[�^����)  09.�o�ɓ��iFROM�j
         ,g_param_rec.ship_date_to             -- WHERE��(�p�����[�^����)  10.�o�ɓ��iTO�j
         ,g_param_rec.request_date_from        -- WHERE��(�p�����[�^����)  11.�����iFROM�j
         ,g_param_rec.request_date_to          -- WHERE��(�p�����[�^����)  12.�����iTO�j
         ,g_param_rec.cust_po_number           -- WHERE��(�p�����[�^����)  13.�ڋq�����ԍ�
         ,g_param_rec.prod_class_code          -- WHERE��(�p�����[�^����)  16.���i�敪
         ,g_param_rec.order_type_id            -- WHERE��(�p�����[�^����)  17.�o�Ɍ`��
         ,g_param_rec.sales_chain_code         -- WHERE��(�p�����[�^����)  18.�̔���`�F�[��
         ,g_param_rec.delivery_chain_code      -- WHERE��(�p�����[�^����)  19.�[�i��`�F�[��
    ;
--
    -- ======================================
    -- �J�[�\��FETCH
    -- ======================================
    FETCH main_data_cur BULK COLLECT INTO o_data_tab ;
--
    -- ======================================
    -- �J�[�\��CLOSE
    -- ======================================
    CLOSE main_data_cur ;
--
    -- ======================================
    -- �Ώۏo�׈˗������i���ׁj�J�E���g
    -- ======================================
    gn_target_line_cnt := o_data_tab.COUNT;
--
    -- �Ώۃf�[�^���Ȃ��ꍇ�͌x���I��
    IF (gn_target_line_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(-- �Ώۃf�[�^�����G���[
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_no_data_err
                   );
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg); -- ��s
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (main_data_cur%ISOPEN) THEN
        CLOSE main_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (main_data_cur%ISOPEN) THEN
        CLOSE main_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (main_data_cur%ISOPEN) THEN
        CLOSE main_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_line
   * Description      : ���גP�ʃ`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE chk_line(
    i_data_rec               IN OUT   g_target_data_rtype  -- �Ώۃf�[�^�i�[���R�[�h�^
   ,ov_errbuf                OUT      VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT      VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT      VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_line'; -- �v���O������
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
    lv_conv_unit VARCHAR2(100);
    lv_conv_qty  NUMBER;
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
    -- ========================================
    -- ���Z����
    -- ========================================
    convert_qty(
      i_data_rec              => i_data_rec                  -- �Ώۃf�[�^�i�[���R�[�h�^
     ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- �P���擾
    -- ========================================
    get_unit_price(
      i_data_rec              => i_data_rec                  -- �Ώۃf�[�^�i�[���R�[�h�^
     ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
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
  END chk_line;
--
  /**********************************************************************************
   * Procedure Name   : chk_hdr
   * Description      : �w�b�_�P�ʃ`�F�b�N(A-6)
   ***********************************************************************************/
  PROCEDURE chk_hdr(
    i_data_tab               IN OUT   g_target_data_ttype   -- �Ώۃf�[�^�i�[�z��^
   ,in_start_cnt             IN       NUMBER                -- �擪INDEX
   ,in_end_cnt               IN       NUMBER                -- �ŏIINDEX
   ,ov_input_oif_flg         OUT      VARCHAR2              -- �˗�No�P�ʓo�^�t���O
   ,ov_errbuf                OUT      VARCHAR2              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT      VARCHAR2              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT      VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_hdr'; -- �v���O������
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
--
    ov_input_oif_flg  := cv_input_oif_y;        -- �˗�No�P�ʓo�^�t���O
    gn_target_hdr_cnt := gn_target_hdr_cnt + 1; -- �Ώۏo�׈˗������i�w�b�_�j�J�E���g
--
    -- ========================================
    -- �˗�No�P�ʉ��i�\�`�F�b�N
    -- ========================================
    chk_price_list_id(
      i_data_tab              => i_data_tab                     -- �Ώۃf�[�^�i�[���R�[�h�^�z��
     ,in_start_cnt            => in_start_cnt                -- �擪INDEX
     ,in_end_cnt              => in_end_cnt                  -- �ŏIINDEX
     ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ========================================
    -- �S���c�ƈ��`�F�b�N
    -- ========================================
    chk_cover_salesman(
      i_data_rec              => i_data_tab(in_end_cnt)      -- �Ώۃf�[�^�i�[���R�[�h�^�z��
     ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_input_oif_flg := cv_input_oif_n; -- �˗�No�P�ʓo�^���Ȃ��B
      ov_retcode       := cv_status_warn;
    END IF;
--
    -- ========================================
    -- �ڋq�����ԍ��`�F�b�N
    -- ========================================
    chk_cust_po_no(
      i_data_rec              => i_data_tab(in_end_cnt)      -- �Ώۃf�[�^�i�[���R�[�h�^�z��
     ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
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
  END chk_hdr;
--
  /**********************************************************************************
   * Procedure Name   : set_hdr_oif
   * Description      : �󒍃w�b�_OIF�o�^�f�[�^�ҏW(A-7)
   ***********************************************************************************/
  PROCEDURE set_hdr_oif(
    i_data_rec               IN   g_target_data_rtype  -- �Ώۃf�[�^�i�[���R�[�h�^
   ,ov_errbuf                OUT  VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT  VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT  VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_hdr_oif'; -- �v���O������
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
    gn_hdr_oif_cnt := gn_hdr_oif_cnt + 1; -- �w�b�_OIF�z��INDEX
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).order_source_id       := gt_order_source_id; --  �󒍃\�[�XID
--
    SELECT gt_orig_sys_document_ref
        || xxcos_order_headers_s01.NEXTVAL orig_sys_document_ref
    INTO   g_hdr_oif_tab(gn_hdr_oif_cnt).orig_sys_document_ref --  �󒍃\�[�X�Q��
    FROM   DUAL;
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).org_id                := gn_org_id;         --  �g�DID
    g_hdr_oif_tab(gn_hdr_oif_cnt).ordered_date          := SYSDATE;           --  �󒍓�
    g_hdr_oif_tab(gn_hdr_oif_cnt).order_type            := gt_order_type_hdr; --  �󒍃^�C�v
    g_hdr_oif_tab(gn_hdr_oif_cnt).context               := gt_order_type_hdr; --  �R���e�L�X�g
--
    -- �ڋq�����ԍ��敪���u0�F�o�׈˗�No�v�̏ꍇ�A�ڋq�����ԍ����˗�No
    IF (g_param_rec.customer_po_set_type = cv_cust_po_set_type_req) THEN
      g_hdr_oif_tab(gn_hdr_oif_cnt).customer_po_number    := i_data_rec.request_no; --  �ڋq�����ԍ����˗�No
--
    -- �ڋq�����ԍ��敪���u0�F�o�׈˗�No�v�łȂ��ꍇ�A�ڋq�����ԍ���NVL(�ڋq�����ԍ�,�˗�No)
    ELSE
      g_hdr_oif_tab(gn_hdr_oif_cnt).customer_po_number    := NVL(i_data_rec.cust_po_number, i_data_rec.request_no); --  �ڋq�����ԍ���NVL(�ڋq�����ԍ�,�˗�No)
    END IF;
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).customer_number       := i_data_rec.customer_code;  --  �ڋq
    g_hdr_oif_tab(gn_hdr_oif_cnt).request_date          := i_data_rec.arrival_date;   --  �v����
--
    -- ���ד��̔N�����Ɩ����t�N���̏ꍇ�A�����p���_�����㋒�_
    IF (TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymm) = TO_CHAR(gd_process_date, cv_fmt_yyyymm)) THEN
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.sale_base_code; --  �����p���_�����㋒�_�R�[�h
--
    -- ���ד��̔N�����Ɩ����t�N���|1���̏ꍇ�A�����p���_���O�����㋒�_
    ELSIF (TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymm) = TO_CHAR(ADD_MONTHS(gd_process_date, -1), cv_fmt_yyyymm)) THEN
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.past_sale_base_code; --  �����p���_���O�����㋒�_�R�[�h
--
    -- ���ד��̔N�����Ɩ����t�N���{1������
    -- ���ד������\�񔄏㋒�_�L���J�n���̏ꍇ�A�����p���_���\�񔄏㋒�_
    ELSIF ((TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymm) = TO_CHAR(ADD_MONTHS(gd_process_date, 1), cv_fmt_yyyymm))
      AND  (i_data_rec.arrival_date                        >= i_data_rec.rsv_sale_base_act_date)
      AND  (i_data_rec.rsv_sale_base_act_date              IS NOT NULL))THEN
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.rsv_sale_base_code; --  �����p���_���\�񔄏㋒�_�R�[�h
--
    -- ��L�ȊO�̏ꍇ�A�����p���_�����㋒�_
    ELSE
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.sale_base_code; --  �����p���_�����㋒�_�R�[�h
--
    END IF;
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).attribute13            := i_data_rec.arrival_time_from;     --  ���Ԏw��(From)�����׎���FROM
    g_hdr_oif_tab(gn_hdr_oif_cnt).attribute14            := i_data_rec.arrival_time_to;       --  ���Ԏw��(To)�����׎���TO
    g_hdr_oif_tab(gn_hdr_oif_cnt).attribute19            := i_data_rec.order_number;          --  �I�[�_�[No���ڋq�����ԍ��`�F�b�N�ŕҏW�����I�[�_�[No
    g_hdr_oif_tab(gn_hdr_oif_cnt).shipping_instructions  := i_data_rec.shipping_instructions; --  �o�׎w��
    g_hdr_oif_tab(gn_hdr_oif_cnt).created_by             := cn_created_by;                    --  �쐬��
    g_hdr_oif_tab(gn_hdr_oif_cnt).creation_date          := SYSDATE;                          --  �쐬��
    g_hdr_oif_tab(gn_hdr_oif_cnt).last_updated_by        := cn_last_updated_by;               --  �X�V��
    g_hdr_oif_tab(gn_hdr_oif_cnt).last_update_date       := SYSDATE;                          --  �ŏI�X�V��
    g_hdr_oif_tab(gn_hdr_oif_cnt).last_update_login      := cn_last_update_login;             --  �ŏI���O�C��
    g_hdr_oif_tab(gn_hdr_oif_cnt).program_application_id := cn_program_application_id;        --  �v���O�����A�v���P�[�V����ID
    g_hdr_oif_tab(gn_hdr_oif_cnt).program_id             := cn_program_id;                    --  �v���O����ID
    g_hdr_oif_tab(gn_hdr_oif_cnt).program_update_date    := SYSDATE;                          --  �v���O�����X�V��
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
  END set_hdr_oif;
--
  /**********************************************************************************
   * Procedure Name   : set_line_oif
   * Description      : �󒍖���OIF�o�^�f�[�^�ҏW(A-8)
   ***********************************************************************************/
  PROCEDURE set_line_oif(
    i_data_tab               IN   g_target_data_ttype   -- �Ώۃf�[�^�i�[�z��^
   ,in_start_cnt             IN   NUMBER                -- �擪INDEX
   ,in_end_cnt               IN   NUMBER                -- �ŏIINDEX
   ,ov_errbuf                OUT  VARCHAR2              --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT  VARCHAR2              --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT  VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_line_oif'; -- �v���O������
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
    ln_line_number NUMBER; -- �˗�No���Ƃ̘A��
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
    ln_line_number := 0;
--
    -- ========================================
    -- �˗�No���Ɛ擪INDEX����ŏIINDEX�܂�LOOP
    -- ========================================
    <<request_loop>>
    FOR ln_loop_cnt IN in_start_cnt..in_end_cnt LOOP
--
      gn_line_oif_cnt := gn_line_oif_cnt + 1; -- ����OIF�z��INDEX
--
      ln_line_number := ln_line_number + 1; -- �˗�No���Ƃ̘A��
--
      g_line_oif_tab(gn_line_oif_cnt).order_source_id       := gt_order_source_id;                                   -- �󒍃\�[�XID
      g_line_oif_tab(gn_line_oif_cnt).orig_sys_document_ref := g_hdr_oif_tab(gn_hdr_oif_cnt).orig_sys_document_ref;  -- �󒍃\�[�X�Q�Ɓ��w�b�_�̎󒍃\�[�X�Q��
      g_line_oif_tab(gn_line_oif_cnt).orig_sys_line_ref     := ln_line_number;                                       -- �󒍃\�[�X���׎Q�Ɓ��˗�No���Ƃ̘A��
      g_line_oif_tab(gn_line_oif_cnt).org_id                := gn_org_id;                                            -- �g�DID
      g_line_oif_tab(gn_line_oif_cnt).line_type             := gt_order_type_line;                                   -- ���׃^�C�v
      g_line_oif_tab(gn_line_oif_cnt).context               := gt_order_type_line;                                   -- �R���e�L�X�g
      g_line_oif_tab(gn_line_oif_cnt).inventory_item        := i_data_tab(ln_loop_cnt).parent_item_no;               -- �i�ځ��e�i�ڃR�[�h
      g_line_oif_tab(gn_line_oif_cnt).ordered_quantity      := i_data_tab(ln_loop_cnt).conv_quantity;                -- �󒍐��ʁ����Z�㐔��
      g_line_oif_tab(gn_line_oif_cnt).order_quantity_uom    := i_data_tab(ln_loop_cnt).parent_conv_unit;             -- �󒍒P�ʁ��e�i�ړ��o�Ɋ��Z�P�ʁi���Z��P�ʁj
      g_line_oif_tab(gn_line_oif_cnt).customer_po_number    := g_hdr_oif_tab(gn_hdr_oif_cnt).customer_po_number;     -- �ڋq�����ԍ����ڋq�����ԍ�
      g_line_oif_tab(gn_line_oif_cnt).customer_line_number  := ln_line_number;                                       -- �ڋq���הԍ����˗�No���Ƃ̘A��
      g_line_oif_tab(gn_line_oif_cnt).request_date          := i_data_tab(ln_loop_cnt).arrival_date;                 -- �[�i�\��������ד�
      g_line_oif_tab(gn_line_oif_cnt).packing_instructions  := i_data_tab(ln_loop_cnt).request_no;                   -- �o�׈˗�No���˗�No
      g_line_oif_tab(gn_line_oif_cnt).unit_list_price       := i_data_tab(ln_loop_cnt).unit_price;                   -- �P�����P��
      g_line_oif_tab(gn_line_oif_cnt).unit_selling_price    := i_data_tab(ln_loop_cnt).unit_price;                   -- �̔��P�����P��
      g_line_oif_tab(gn_line_oif_cnt).calculate_price_flag  := i_data_tab(ln_loop_cnt).calc_unit_price_flg;          -- ���i�v�Z�t���O
      g_line_oif_tab(gn_line_oif_cnt).subinventory          := cv_location_code_direct;                              -- �ۊǏꏊ�������q��
      g_line_oif_tab(gn_line_oif_cnt).attribute5            := cv_sales_kbn_normal;                                  -- ����敪���u1:�ʏ�v
--
      -- �e�i�ڃR�[�h�Ǝq�i�ڃR�[�h���Ⴄ�ꍇ�A�q�R�[�h���q�i�ڃR�[�h
      IF (i_data_tab(ln_loop_cnt).parent_item_no <> i_data_tab(ln_loop_cnt).child_item_no) THEN
        g_line_oif_tab(gn_line_oif_cnt).attribute6            := i_data_tab(ln_loop_cnt).child_item_no;  --   �q�R�[�h���q�i�ڃR�[�h
      END IF;
--
      g_line_oif_tab(gn_line_oif_cnt).created_by             := cn_created_by;                 --  �쐬��
      g_line_oif_tab(gn_line_oif_cnt).creation_date          := SYSDATE;                       --  �쐬��
      g_line_oif_tab(gn_line_oif_cnt).last_updated_by        := cn_last_updated_by;            --  �X�V��
      g_line_oif_tab(gn_line_oif_cnt).last_update_date       := SYSDATE;                       --  �ŏI�X�V��
      g_line_oif_tab(gn_line_oif_cnt).last_update_login      := cn_last_update_login;          --  �ŏI���O�C��
      g_line_oif_tab(gn_line_oif_cnt).program_application_id := cn_program_application_id;     --  �v���O�����A�v���P�[�V����ID
      g_line_oif_tab(gn_line_oif_cnt).program_id             := cn_program_id;                 --  �v���O����ID
      g_line_oif_tab(gn_line_oif_cnt).program_update_date    := SYSDATE;                       --  �v���O�����X�V��
--
    END LOOP request_loop;
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
  END set_line_oif;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif
   * Description      : �󒍃f�[�^�o�^(A-9)
   ***********************************************************************************/
  PROCEDURE ins_oif(
    ov_errbuf                OUT  VARCHAR2        --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT  VARCHAR2        --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT  VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif'; -- �v���O������
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
    -- ========================================
    -- �󒍃w�b�_OIF�o�^
    -- ========================================
    BEGIN
      FORALL ln_loop_cnt IN 1..g_hdr_oif_tab.COUNT
        INSERT INTO oe_headers_iface_all VALUES g_hdr_oif_tab(ln_loop_cnt);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg( -- �f�[�^�o�^�G���[���b�Z�[�W
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => cv_hdr_oif_tbl_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => ''
                   );
--
        lv_errbuf := SQLERRM;
--
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- �󒍖���OIF�o�^
    -- ========================================
    BEGIN
      FORALL ln_loop_cnt IN 1..g_line_oif_tab.COUNT
        INSERT INTO oe_lines_iface_all VALUES g_line_oif_tab(ln_loop_cnt);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg( -- �f�[�^�o�^�G���[���b�Z�[�W
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => cv_line_oif_tbl_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => ''
                   );
--
        lv_errbuf := SQLERRM;
--
        RAISE global_api_expt;
    END;
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
  END ins_oif;
--
  /**********************************************************************************
   * Procedure Name   : call_imp_data
   * Description      : �󒍃C���|�[�g�G���[���m�N������(A-10)
   ***********************************************************************************/
  PROCEDURE call_imp_data(
    ov_errbuf                OUT  VARCHAR2        --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode               OUT  VARCHAR2        --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                OUT  VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_imp_data'; -- �v���O������
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
    --�R���J�����g�萔
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';         -- Application
--2012/06/25 Ver.1.2 Mod Start 
--  �󒍃C���|�[�g�G���[���m(CSV�󒍎捞�p�j���Ăяo���悤�ɂɕύX
--    cv_program                CONSTANT VARCHAR2(12)  := 'XXCOS010A06C';  -- Program
    cv_program                CONSTANT VARCHAR2(13)  := 'XXCOS010A062C';  -- Program
--2012/06/25 Ver.1.2 Mod End 
    cv_description            CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;           -- Sub_request
--    -- *** ���[�J���ϐ� ***
    ln_process_set            NUMBER;          -- �����Z�b�g
    ln_request_id             NUMBER;          -- �v��ID
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
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
    -- =====================================================
    -- �󒍃C���|�[�g�G���[���m�N��
    -- =====================================================
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application
                      ,program      => cv_program
                      ,description  => cv_description
                      ,start_time   => cv_start_time
                      ,sub_request  => cb_sub_request
                      ,argument1    => gt_order_source_name     --�󒍃\�[�X��
                     );
--
    -- �v��ID���擾�ł��Ȃ������Ƃ��A�G���[
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_imp_err
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => TO_CHAR( ln_request_id )
                    ,iv_token_name2  => cv_tkn_dev_status
                    ,iv_token_value2 => NULL
                    ,iv_token_name3  => cv_tkn_message
                    ,iv_token_value3 => NULL
                   );
      RAISE global_api_expt;
    END IF;
--
    -- =====================================================
    --�R���J�����g�N���̂��߃R�~�b�g
    -- =====================================================
    COMMIT;
--
    -- =====================================================
    --�R���J�����g�̏I���ҋ@
    -- =====================================================
    lb_wait_result := fnd_concurrent.wait_for_request(
                        request_id   => ln_request_id
                       ,interval     => gn_interval
                       ,max_wait     => gn_max_wait
                       ,phase        => lv_phase
                       ,status       => lv_status
                       ,dev_phase    => lv_dev_phase
                       ,dev_status   => lv_dev_status
                       ,message      => lv_message
                      );
--
    -- �R���J�����g�̏I�����ʂ��G���[���ҋ@���ԓ��ɏI���Ȃ������ꍇ
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status = cv_con_status_error ) ) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_imp_err
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => TO_CHAR( ln_request_id )
                    ,iv_token_name2  => cv_tkn_dev_status
                    ,iv_token_value2 => lv_dev_status
                    ,iv_token_name3  => cv_tkn_message
                    ,iv_token_value3 => lv_message
                   );
      RAISE global_api_expt;
--
    -- �R���J�����g�̏I�����ʂ��x���̏ꍇ
    ELSIF ( lv_dev_status = cv_con_status_warning ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_imp_warn
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => TO_CHAR( ln_request_id )
                    ,iv_token_name2  => cv_tkn_dev_status
                    ,iv_token_value2 => lv_dev_status
                    ,iv_token_name3  => cv_tkn_message
                    ,iv_token_value3 => lv_message
                   );
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
      ov_retcode := cv_status_warn;
--
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
  END call_imp_data;
--
  /**********************************************************************************
   * Procedure Name   : target_data_loop
   * Description      : �Ώۃf�[�^LOOP
   ***********************************************************************************/
  PROCEDURE target_data_loop(
    i_data_tab    IN OUT g_target_data_ttype -- �Ώۃf�[�^�i�[�z��ϐ�
   ,ov_errbuf     OUT    VARCHAR2            --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT    VARCHAR2            --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT    VARCHAR2)           --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'target_data_loop'; -- �v���O������
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
    lv_input_oif_flg  VARCHAR2(1);      -- �˗�No�P�ʓo�^�t���O
    ln_start_cnt      NUMBER;           -- �˗�No���Ɛ擪INDEX
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
    <<target_data_loop>>
    FOR ln_loop_cnt IN 1..i_data_tab.COUNT LOOP
--
      -- �˗�No���Ɛ擪INDEX�擾 START
      IF  ((ln_loop_cnt = 1)
        OR (i_data_tab(ln_loop_cnt).request_no <> i_data_tab(ln_loop_cnt - 1).request_no)) THEN
--
        lv_input_oif_flg := cv_input_oif_y; -- �˗�No�P�ʓo�^�t���O�������uY:�o�^����v
        ln_start_cnt     := ln_loop_cnt;    -- �˗�No���Ɛ擪INDEX
--
      END IF; -- �˗�No���Ɛ擪INDEX�擾 END
--
      -- ================================================
      -- A-5.���גP�ʃ`�F�b�N
      -- ================================================
      chk_line(
        i_data_rec              => i_data_tab(ln_loop_cnt)     -- �Ώۃf�[�^�i�[���R�[�h�^
       ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
--
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
      -- �����R�[�h���˗�No�u���C�N������ START
      IF  ((ln_loop_cnt = i_data_tab.LAST)
        OR (i_data_tab(ln_loop_cnt).request_no <> i_data_tab(ln_loop_cnt + 1).request_no)) THEN
--
        -- ================================================
        -- A-6.�w�b�_�P�ʃ`�F�b�N
        -- ================================================
        chk_hdr(
          i_data_tab              => i_data_tab                     -- �Ώۃf�[�^�i�[���R�[�h�^�z��
         ,in_start_cnt            => ln_start_cnt                -- �擪INDEX
         ,in_end_cnt              => ln_loop_cnt                 -- �ŏIINDEX
         ,ov_input_oif_flg        => lv_input_oif_flg            -- �˗�No�P�ʓo�^�t���O
         ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
--
        ELSIF (lv_retcode = cv_status_warn) THEN
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �˗�No�P�ʓo�^�t���O���uY:�o�^����v�̏ꍇ�A�o�^���镪�� START
        IF (lv_input_oif_flg = cv_input_oif_y) THEN
          -- ================================================
          -- A-7.�󒍃w�b�_OIF�o�^�f�[�^�ҏW
          -- ================================================
          set_hdr_oif(
            i_data_rec              => i_data_tab(ln_loop_cnt)     -- �Ώۃf�[�^�i�[���R�[�h�^
           ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ================================================
          -- A-8.�󒍖���OIF�o�^�f�[�^�ҏW
          -- ================================================
          set_line_oif(
            i_data_tab              => i_data_tab                  -- �Ώۃf�[�^�i�[���R�[�h�^�z��
           ,in_start_cnt            => ln_start_cnt                -- �擪INDEX
           ,in_end_cnt              => ln_loop_cnt                 -- �ŏIINDEX
           ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF; -- �˗�No�P�ʓo�^�t���O���uY:�o�^����v�̏ꍇ�A�o�^���镪�� END
--
      END IF; -- �����R�[�h���˗�No�u���C�N������ END
--
    END LOOP target_data_loop;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END target_data_loop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_delivery_base_code          IN   VARCHAR2        -- 01.�[�i���_�R�[�h
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.���͋��_�R�[�h
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.�Ǌ����_�R�[�h
   ,iv_request_no                  IN   VARCHAR2        -- 04.�o�׈˗�No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.�o�׈˗����͎�
   ,iv_cust_code                   IN   VARCHAR2        -- 06.�ڋq�R�[�h
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.�z����R�[�h
   ,iv_location_code               IN   VARCHAR2        -- 08.�o�Ɍ��R�[�h
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.�o�ɓ��iFROM�j
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.�o�ɓ��iTO�j
   ,iv_request_date_from           IN   VARCHAR2        -- 11.�����iFROM�j
   ,iv_request_date_to             IN   VARCHAR2        -- 12.�����iTO�j
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.�ڋq�����ԍ�
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.�ڋq�����ԍ��敪
   ,iv_uom_type                    IN   VARCHAR2        -- 15.���Z�P�ʋ敪
   ,iv_item_type                   IN   VARCHAR2        -- 16.���i�敪
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.�o�Ɍ`��
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.�̔���`�F�[��
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.�[�i��`�F�[��
   ,ov_errbuf                      OUT  VARCHAR2        --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                     OUT  VARCHAR2        --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                      OUT  VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    l_target_data_tab            g_target_data_ttype; -- �Ώۃf�[�^�i�[�z��ϐ�
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_hdr_oif_cnt         := 0;  -- �󒍃w�b�_OIF�i�[�z��^INDEX
    gn_line_oif_cnt        := 0;  -- �󒍖���OIF�i�[�z��^INDEX
    gn_warn_msg_cnt        := 0;  -- �x�����b�Z�[�W�z��^INDEX
    gn_err_msg_cnt         := 0;  -- �o�^�G���[���b�Z�[�W�z��^INDEX
    gn_cust_po_no_msg_cnt  := 0;  -- �ڋq�����ԍ��ҏW�x�����b�Z�[�W�z��^INDEX
--
    gn_target_hdr_cnt      := 0;  -- �Ώۏo�׈˗������i�w�b�_�j
    gn_target_line_cnt     := 0;  -- �Ώۏo�׈˗������i���ׁj
    gn_normal_hdr_cnt      := 0;  -- ���������i�w�b�_�j
    gn_normal_line_cnt     := 0;  -- ���������i���ׁj
    gn_err_hdr_cnt         := 0;  -- �G���[�����i�w�b�_�j
    gn_err_line_cnt        := 0;  -- �G���[�����i���ׁj
    gn_price_1yen_hdr_cnt  := 0;  -- �̔��P���P�~�����i�w�b�_�j
    gn_price_1yen_line_cnt := 0;  -- �̔��P���P�~�����i���ׁj
--
    g_hdr_oif_tab.       DELETE;  -- �󒍃w�b�_OIF�i�[�z��^
    g_line_oif_tab.      DELETE;  -- �󒍖���OIF�i�[�z��^
    g_warn_msg_tab.      DELETE;  -- �x�����b�Z�[�W�z��^
    g_err_msg_tab.       DELETE;  -- �o�^�G���[���b�Z�[�W�z��^
    g_cust_po_no_msg_tab.DELETE;  -- �ڋq�����ԍ��x�����b�Z�[�W
--
    -- ===============================================
    -- A-1.���̓p�����[�^�o��
    -- ===============================================
    output_param(
      iv_delivery_base_code          => iv_delivery_base_code       -- 01.�[�i���_�R�[�h
     ,iv_input_sales_branch          => iv_input_sales_branch       -- 02.���͋��_�R�[�h
     ,iv_head_sales_branch           => iv_head_sales_branch        -- 03.�Ǌ����_�R�[�h
     ,iv_request_no                  => iv_request_no               -- 04.�o�׈˗�No
     ,iv_entered_by_code             => iv_entered_by_code          -- 05.�o�׈˗����͎�
     ,iv_cust_code                   => iv_cust_code                -- 06.�ڋq�R�[�h
     ,iv_deliver_to                  => iv_deliver_to               -- 07.�z����R�[�h
     ,iv_location_code               => iv_location_code            -- 08.�o�Ɍ��R�[�h
     ,iv_schedule_ship_date_from     => iv_schedule_ship_date_from  -- 09.�o�ɓ��iFROM�j
     ,iv_schedule_ship_date_to       => iv_schedule_ship_date_to    -- 10.�o�ɓ��iTO�j
     ,iv_request_date_from           => iv_request_date_from        -- 11.�����iFROM�j
     ,iv_request_date_to             => iv_request_date_to          -- 12.�����iTO�j
     ,iv_cust_po_number              => iv_cust_po_number           -- 13.�ڋq�����ԍ�
     ,iv_customer_po_set_type        => iv_customer_po_set_type     -- 14.�ڋq�����ԍ��敪
     ,iv_uom_type                    => iv_uom_type                 -- 15.���Z�P�ʋ敪
     ,iv_item_type                   => iv_item_type                -- 16.���i�敪
     ,iv_transaction_type_id         => iv_transaction_type_id      -- 17.�o�Ɍ`��
     ,iv_chain_code_sales            => iv_chain_code_sales         -- 18.�̔���`�F�[��
     ,iv_chain_code_deliv            => iv_chain_code_deliv         -- 19.�[�i��`�F�[��
     ,ov_errbuf                      => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode                     => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                      => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2.���̓p�����[�^�`�F�b�N
    -- ===============================================
    chk_param(
      ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3.��������
    -- ===============================================
    init(
      ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-4.�Ώۃf�[�^�擾
    -- ===============================================
    get_data(
      o_data_tab              => l_target_data_tab           -- �Ώۃf�[�^�i�[�z��ϐ�
     ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      RAISE no_data;
    END IF;
--
    -- ===============================================
    -- �Ώۃf�[�^LOOP(A-5,A-6,A-7,A-8)
    -- ===============================================
    target_data_loop(
      i_data_tab              => l_target_data_tab           -- �Ώۃf�[�^�i�[�z��ϐ�
     ,ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    IF (gn_hdr_oif_cnt <> 0) THEN
      -- ===============================================
      -- A-9.�󒍃f�[�^�o�^
      -- ===============================================
      ins_oif(
       ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
       RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- A-10.�󒍃C���|�[�g�G���[���m�N������
      -- ===============================================
      call_imp_data(
       ov_errbuf               => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode              => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
       RAISE global_process_expt;
--
      ELSIF ( lv_retcode = cv_status_warn ) THEN
       ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--
    WHEN no_data THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
    errbuf                         OUT  VARCHAR2        --   �G���[���b�Z�[�W #�Œ�#
   ,retcode                        OUT  VARCHAR2        --   �G���[�R�[�h     #�Œ�#
   ,iv_delivery_base_code          IN   VARCHAR2        -- 01.�[�i���_�R�[�h
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.���͋��_�R�[�h
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.�Ǌ����_�R�[�h
   ,iv_request_no                  IN   VARCHAR2        -- 04.�o�׈˗�No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.�o�׈˗����͎�
   ,iv_cust_code                   IN   VARCHAR2        -- 06.�ڋq�R�[�h
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.�z����R�[�h
   ,iv_location_code               IN   VARCHAR2        -- 08.�o�Ɍ��R�[�h
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.�o�ɓ��iFROM�j
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.�o�ɓ��iTO�j
   ,iv_request_date_from           IN   VARCHAR2        -- 11.�����iFROM�j
   ,iv_request_date_to             IN   VARCHAR2        -- 12.�����iTO�j
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.�ڋq�����ԍ�
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.�ڋq�����ԍ��敪
   ,iv_uom_type                    IN   VARCHAR2        -- 15.���Z�P�ʋ敪
   ,iv_item_type                   IN   VARCHAR2        -- 16.���i�敪
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.�o�Ɍ`��
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.�̔���`�F�[��
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.�[�i��`�F�[��
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
       iv_delivery_base_code            -- 01.�[�i���_�R�[�h
      ,iv_input_sales_branch            -- 02.���͋��_�R�[�h
      ,iv_head_sales_branch             -- 03.�Ǌ����_�R�[�h
      ,iv_request_no                    -- 04.�o�׈˗�No
      ,iv_entered_by_code               -- 05.�o�׈˗����͎�
      ,iv_cust_code                     -- 06.�ڋq�R�[�h
      ,iv_deliver_to                    -- 07.�z����R�[�h
      ,iv_location_code                 -- 08.�o�Ɍ��R�[�h
      ,iv_schedule_ship_date_from       -- 09.�o�ɓ��iFROM�j
      ,iv_schedule_ship_date_to         -- 10.�o�ɓ��iTO�j
      ,iv_request_date_from             -- 11.�����iFROM�j
      ,iv_request_date_to               -- 12.�����iTO�j
      ,iv_cust_po_number                -- 13.�ڋq�����ԍ�
      ,iv_customer_po_set_type          -- 14.�ڋq�����ԍ��敪
      ,iv_uom_type                      -- 15.���Z�P�ʋ敪
      ,iv_item_type                     -- 16.���i�敪
      ,iv_transaction_type_id           -- 17.�o�Ɍ`��
      ,iv_chain_code_sales              -- 18.�̔���`�F�[��
      ,iv_chain_code_deliv              -- 19.�[�i��`�F�[��
      ,lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===================================================
    -- A-11.���b�Z�[�W�o��
    -- ===================================================
    -- �G���[���b�Z�[�W
    IF (g_err_msg_tab.COUNT > 0) THEN
--
      gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_appl_short_name, cv_msg_err_msg_title);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg); -- �G���[���b�Z�[�W�^�C�g��
--
      <<err_msg_loop>>
      FOR ln_loop_cnt IN 1..g_err_msg_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, g_err_msg_tab(ln_loop_cnt)); -- OIF�o�^�G���[���b�Z�[�W
      END LOOP err_msg_loop;
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- ��s
--
    -- �x�����b�Z�[�W
    IF (g_warn_msg_tab.COUNT > 0) THEN
--
      gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_appl_short_name, cv_msg_warn_msg_title);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg); -- �x�����b�Z�[�W�^�C�g��
--
      <<warn_msg_loop>>
      FOR ln_loop_cnt IN 1..g_warn_msg_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, g_warn_msg_tab(ln_loop_cnt)); -- �x�����b�Z�[�W
      END LOOP warn_msg_loop;
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- ��s
--
    -- �ڋq�����ԍ��x�����b�Z�[�W
    IF (g_cust_po_no_msg_tab.COUNT > 0) THEN
--
      gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_appl_short_name, cv_msg_cust_po_no_title);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg); -- �x�����b�Z�[�W�^�C�g���i�ڋq�����ԍ��ҏW�j
--
      <<warn_msg_loop>>
      FOR ln_loop_cnt IN 1..g_cust_po_no_msg_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, g_cust_po_no_msg_tab(ln_loop_cnt)); -- �ڋq�����ԍ��x�����b�Z�[�W
      END LOOP warn_msg_loop;
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- ��s
--
    -- ===================================================
    -- A-12.���������o��
    -- ===================================================
    -- �Ώۏo�׈˗������i�w�b�_�j
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_target_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_target_hdr_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- ���������i�w�b�_�j�󒍃w�b�_OIF�ɍ쐬��������
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_normal_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_hdr_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- ���������i���ׁj�󒍖���OIF�ɍ쐬��������
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_normal_line_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_line_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- �G���[�����i�w�b�_�j�Ώۈ˗������i�w�b�_)�|�󒍃w�b�_OIF�ɍ쐬��������
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_err_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_target_hdr_cnt - gn_hdr_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- �G���[�����i���ׁj�Ώۏo�׈˗������i���ׁj�|�󒍖���OIF�ɍ쐬��������
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_err_line_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_target_line_cnt - gn_line_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- �̔��P���P�~�����i�w�b�_�j
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_price_1yen_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_price_1yen_hdr_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- �̔��P���P�~�����i���ׁj
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_price_1yen_line_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_price_1yen_line_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- ��s
--
-- �Œ茏���o�͎͂g�p���Ȃ��B
--    --�Ώی����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_target_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --���������o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --�G���[�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_error_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
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
END XXCOS008A06C;
/
