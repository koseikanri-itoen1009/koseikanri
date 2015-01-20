CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A01C(body)
 * Description      : HHT�����[�i�\��f�[�^�쐬
 * MD.050           : HHT�����[�i�\��f�[�^�쐬 MD050_COS_003_A01
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  proc_break_process     �󒍃w�b�_���ID�u���C�N��̏����i�t�@�C���o�́A�X�e�[�^�X�X�V�j
 *  proc_main_loop         ���[�v�� A-2�f�[�^���o
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/26   1.0    K.Okaguchi       �V�K�쐬
 *  2009/02/24   1.1    T.Nakamura       [��QCOS_130] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/04/15   1.2    N.Maeda          [ST��QNo.T1_0067�Ή�] �t�@�C���o�͎���CHAR�^VARCHAR�^�ȊO�ւ̢"��t���̍폜
 *  2009/05/01   1.3    T.Kitajima       [T1_0678]�}�b�s���O�s���Ή�
 *  2009/07/08   1.4    K.Kiriu          [0000063]���敪�̉ۑ�Ή�
 *                                       [0000064]�󒍃w�b�_DFF���ژR��Ή�
 *  2009/08/06   1.4    M.Sano           [0000426]�wHHT�����[�i�\��f�[�^�쐬�xPT�̍l��
 *  2009/09/01   1.5    M.Sano           [0001066]�wHHT�����[�i�\��f�[�^�쐬�xPT�̍l��
 *  2010/03/30   1.6    S.Miyakoshi      [E_�{�ғ�_02058]�P�ʊ��Z�����̒ǉ�
 *  2014/03/04   1.7    T.Nakano         [E_�{�ғ�_11551]�p�t�H�[�}���X�Ή�
 *  2015/01/08   1.8    H.Wajima         [E_�{�ғ�_12806]�P�ʊ��Z�����̏C��
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  gn_set_cnt       NUMBER;                    -- �ݒ�J�E���^
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
  global_data_check_expt    EXCEPTION;     -- �f�[�^�`�F�b�N���̃G���[
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
  global_change_err_expt    EXCEPTION;     -- �P�ʊ��Z�G���[
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A01C'; -- �p�b�P�[�W��
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- �A�v���P�[�V������
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_delimit              CONSTANT VARCHAR2(1)  := ',';            -- ��؂蕶��
  cv_quot                 CONSTANT VARCHAR2(1)  := '"';            -- �R�[�e�[�V����
--
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_order                CONSTANT VARCHAR2(20) := 'ORDER';
  cv_brank                CONSTANT VARCHAR2(1)  := ' ';
  cv_minus                CONSTANT VARCHAR2(1)  := '-';
--
  cv_booked               CONSTANT VARCHAR2(10) := 'BOOKED';
  cv_sales_car            CONSTANT VARCHAR2(1)  := '5';
  cv_non_tran             CONSTANT VARCHAR2(1)  := 'N';
  cv_customer             CONSTANT VARCHAR2(1)  := '1';
  cv_output_flag          CONSTANT VARCHAR2(1)  := 'Y';
  cv_error_status         CONSTANT VARCHAR2(1)  := '1';
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';                     -- ���b�N�G���[
  cv_tkn_order_number     CONSTANT VARCHAR2(20) := 'ORDER_NUMBER';
  cv_tkn_line_number      CONSTANT VARCHAR2(20) := 'LINE_NUMBER';
  cv_tkn_item_name        CONSTANT VARCHAR2(20) := 'ITEM_NAME';
  cv_tkn_item_value       CONSTANT VARCHAR2(20) := 'ITEM_VALUE';
  cv_tkn_filename         CONSTANT VARCHAR2(20) := 'FILE_NAME';
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';                   -- �G���[���e
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';          -- ���b�N�G���[
  cv_msg_file_open        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';          -- 
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';          -- 
  cv_msg_filename         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';          -- �t�@�C�����i�^�C�g���j
  cv_msg_notnull          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10651';          -- �K�{�G���[
  cv_msg_overflow         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10652';          -- �����ӂ�G���[
  cv_delivery_base_code   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10653';          -- ���_�R�[�h
  cv_order_number         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10654';          -- �󒍔ԍ�
  cv_line_number          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10655';          -- ���הԍ�
  cv_ordered_item         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10656';          -- �i�ڃR�[�h
  cv_customer_item_number CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10657';          -- �ڋq�i�ڃR�[�h
  cv_customer_item_desc   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10658';          -- �ڋq�i�ړE�v
  cv_ordered_quantity     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10659';          -- �󒍐���
  cv_unit_selling_price   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10660';          -- �̔��P��
  cv_selling_price        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10661';          -- ���P��
  cv_tkn_lock_table       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00115';          -- EDI���׏��e�[�u��
  cv_tkn_dir_path         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10662';          -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_tkn_h_filename       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10663';          -- EOS�w�b�_�t�@�C����
  cv_tkn_l_filename       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10664';          -- EOS���׃t�@�C����
  cv_tkn_h_file           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10665';          -- EOS�w�b�_�t�@�C��
  cv_tkn_l_file           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10666';          -- EOS���׃t�@�C��
  cv_tkn_org_id           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10667';          -- MO:�c�ƒP��
  cv_tkn_organization_cd  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00048';          -- XXCOI:�݌ɑg�D�R�[�h
  cv_tkn_update_table     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10668';          -- EDI���׏��e�[�u��
  cv_edi_line_id          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10669';          -- �󒍖��׏��ID
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
  cv_msg_change_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10670';          -- �P�ʊ��Z�G���[
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
/* 2014/03/04 Ver1.7 Add Start */
  cv_msg_proc_date_err    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014';         -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_ord_keep_day     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10671';         -- HHT�[�i�p�󒍕ێ�����
/* 2014/03/04 Ver1.7 Add End */
  -- ���̑�
  cv_file_access_mode     CONSTANT VARCHAR2(10) := 'W';                         -- �t�@�C���A�N�Z�X���[�h
  cv_cust_class_cust      CONSTANT VARCHAR2(10) := '10';                        -- �ڋq�敪�i�ڋq�j
  cv_cust_class_chain     CONSTANT VARCHAR2(10) := '18';                        -- �ڋq�敪�i�`�F�[���X�j
  cv_enabled              CONSTANT VARCHAR2(10) := 'Y';                         -- �L���t���O
  cv_default_language     CONSTANT VARCHAR2(10) := USERENV('LANG');             -- �W������^�C�v
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--  cv_number_format8       CONSTANT VARCHAR2(20) := 'FM99999999.00';             -- ���l�t�H�[�}�b�g�W��
--  cv_number_format7       CONSTANT VARCHAR2(20) := 'FM9999999.00';              -- ���l�t�H�[�}�b�g�V��
  cv_number_format8       CONSTANT VARCHAR2(20) := 'FM99999990.00';             -- ���l�t�H�[�}�b�g�W��
  cv_number_format7       CONSTANT VARCHAR2(20) := 'FM9999990.00';              -- ���l�t�H�[�}�b�g�V��
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
/* 2009/07/08 Ver1.4 Add Start */
  --���敪
  cv_target_order_01      CONSTANT  VARCHAR2(2) := '01';                        -- �󒍍쐬�Ώ�01
/* 2009/07/08 Ver1.4 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id                   NUMBER;
  gv_organization_code        mtl_parameters.organization_code%TYPE         ;--�݌ɑg�D�R�[�h
  gv_delivery_base_code       xxcmm_cust_accounts.delivery_base_code%TYPE   ;--�[�i���_�R�[�h
  gv_order_number             oe_order_headers_all.order_number%TYPE        ;--��No
  gv_conv_customer_code       xxcos_edi_headers.conv_customer_code%TYPE     ;--�ڋq�R�[�h
  gv_invoice_number           xxcos_edi_headers.invoice_number%TYPE         ;--�`�[�ԍ�
  gd_request_date             oe_order_headers_all.request_date%TYPE        ;--�[�i��
  gv_big_classification_code  xxcos_edi_headers.big_classification_code%TYPE;--���㕪�ދ敪
  gv_invoice_class            xxcos_edi_headers.invoice_class%TYPE          ;--����`�[�敪
  gv_company_name_alt         xxcos_edi_headers.company_name_alt%TYPE       ;--�Ж��i�J�i�j
  gv_shop_name_alt            xxcos_edi_headers.shop_name_alt%TYPE          ;--�X���i�J�i�j
  gv_edi_chain_code           xxcos_edi_headers.edi_chain_code%TYPE         ;--�`�F�[���X�R�[�h
  gn_edi_header_info_id       xxcos_edi_headers.edi_header_info_id%TYPE     ;--�󒍃w�b�_���ID
  gv_customer_item_number     mtl_customer_items.customer_item_number%TYPE  ;--�ڋq�i�ڔԍ�
  gv_customer_item_desc       mtl_customer_items.customer_item_desc%TYPE    ;--�ڋq�i�ړE�v
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--���b�Z�[�W�o�͗p�L�[���
  gv_msg_delivery_base_code   fnd_new_messages.message_text%TYPE   ;--'���_�R�[�h'
  gv_msg_order_number         fnd_new_messages.message_text%TYPE   ;--'�󒍔ԍ�'
  gv_msg_line_number          fnd_new_messages.message_text%TYPE   ;--'���הԍ�'
  gv_msg_ordered_item         fnd_new_messages.message_text%TYPE   ;--'�i�ڃR�[�h'
  gv_msg_customer_item_number fnd_new_messages.message_text%TYPE   ;--'�ڋq�i�ڃR�[�h'
  gv_msg_customer_item_desc   fnd_new_messages.message_text%TYPE   ;--'�ڋq�i�ړE�v'
  gv_msg_ordered_quantity     fnd_new_messages.message_text%TYPE   ;--'�󒍐���'
  gv_msg_unit_selling_price   fnd_new_messages.message_text%TYPE   ;--'�̔��P��'
  gv_msg_selling_price        fnd_new_messages.message_text%TYPE   ;--'���P��'
  gv_msg_tkn_lock_table       fnd_new_messages.message_text%TYPE   ;--'EDI���׏��e�[�u��
  gv_msg_tkn_dir_path         fnd_new_messages.message_text%TYPE   ;--'HHT�A�E�g�o�E���h�p�f�B���N�g���p�X'
  gv_msg_tkn_h_filename       fnd_new_messages.message_text%TYPE   ;--'EOS�w�b�_�t�@�C����'
  gv_msg_tkn_l_filename       fnd_new_messages.message_text%TYPE   ;--'EOS���׃t�@�C����'
  gv_msg_tkn_h_file           fnd_new_messages.message_text%TYPE   ;--'EOS�w�b�_�t�@�C��'
  gv_msg_tkn_l_file           fnd_new_messages.message_text%TYPE   ;--'EOS���׃t�@�C��'
  gv_msg_tkn_org_id           fnd_new_messages.message_text%TYPE   ;--'MO:�c�ƒP��'
  gv_msg_tkn_organization_cd  fnd_new_messages.message_text%TYPE   ;--'XXCOI:�݌ɑg�D�R�[�h'
  gv_msg_tkn_update_table     fnd_new_messages.message_text%TYPE   ;--'EDI���׏��e�[�u��'
  gv_msg_edi_line_id          fnd_new_messages.message_text%TYPE   ;--'�󒍖��׏��ID'
  gv_h_file_data              VARCHAR2(2000);
  gv_l_file_data              VARCHAR2(2000);
  gv_edi_order_source         fnd_lookup_values.meaning%TYPE;       -- �󒍃\�[�X
  gv_transaction_status       VARCHAR2(1);                          -- �`�F�b�N�X�e�[�^�X
/* 2014/03/04 Ver1.7 Add Start */
  gd_proc_date                DATE;                                 -- �Ɩ����t
  gn_hht_deli_ord_keep_day    NUMBER;                               -- HHT�[�i�p�󒍕ێ�����
  gv_msg_tkn_ord_keep_day     fnd_new_messages.message_text%TYPE;   -- 'HHT�[�i�p�󒍕ێ�����'
/* 2014/03/04 Ver1.7 Add End */
--
  --�J�[�\��
  CURSOR main_cur
  IS
/* 2009/08/06 Ver1.4 Add Start */
--    SELECT ooha.order_number               order_number               --�󒍃w�b�_�e�[�u���D�󒍔ԍ�
/* 2009/09/01 Ver1.5 Mod Start */
--    SELECT /*+ leading(ooha)
--               use_nl(xieh)
--               index(ooha xxcos_oe_order_headers_all_n12)
--               index(xiel xxcos_edi_lines_n01) */
/* 2014/03/04 Ver1.7 Mod Start */
--      SELECT /*+ leading(oosa)
--                 use_nl(ooha)
--                 use_nl(xieh)
--                 use_nl(xiel)
--                 use_nl(msiv)
--                 index(ooha xxcos_oe_order_headers_all_n12)
--                 index(oola oe_order_lines_n1)
--                 index(xiel xxcos_edi_lines_n01)
--              */
    SELECT /*+   leading(ooha)
                 index(ooha xxcos_oe_order_headers_all_n10)
                 use_nl(xieh xiel ooha oola oosc msiv xcac)
                 index(oola oe_order_lines_n1)
              */
/* 2014/03/04 Ver1.7 Mod End */
/* 2009/09/01 Ver1.5 Mod End   */
           ooha.order_number               order_number               --�󒍃w�b�_�e�[�u���D�󒍔ԍ�
/* 2009/08/06 Ver1.4 Add End   */
         , ooha.request_date               request_date               --�󒍃w�b�_�e�[�u���D�v����
         , xieh.edi_chain_code             edi_chain_code             --EDI�w�b�_���e�[�u���DEDI�`�F�[���X�R�[�h
         , xieh.conv_customer_code         conv_customer_code         --EDI�w�b�_���e�[�u���D�ϊ���ڋq�R�[�h
         , xieh.shop_name_alt              shop_name_alt              --EDI�w�b�_���e�[�u���D�X���i�J�i�j
         , xcac.delivery_base_code         delivery_base_code         --�ڋq�ǉ����D�[�i���_�R�[�h
         , xieh.company_name_alt           company_name_alt           --EDI�w�b�_���e�[�u���D�Ж��i�J�i�j
/* 2009/07/08 Ver1.4 Mod Start */
--         , xieh.big_classification_code    big_classification_code    --EDI�w�b�_���e�[�u���D�啪�ރR�[�h
--         , xieh.invoice_class              invoice_class              --EDI�w�b�_���e�[�u���D�`�[�敪
         , ooha.attribute20                big_classification_code    --�󒍃w�b�_�e�[�u���D���ދ敪
         , ooha.attribute5                 invoice_class              --�󒍃w�b�_�e�[�u���D�`�[�敪
/* 2009/07/08 Ver1.4 Mod End   */
         , xieh.invoice_number             invoice_number             --EDI�w�b�_���e�[�u���D�`�[�ԍ��̉�9��
         , xieh.edi_header_info_id         edi_header_info_id         --EDI�w�b�_���e�[�u���D�󒍃w�b�_���ID
         , xiel.selling_price              selling_price              --EDI���׏��e�[�u���D�����P��
         , xiel.edi_line_info_id           edi_line_info_id           --EDI���׏��e�[�u���DEDI���׏��ID
--******************************* 2009/05/01 1.3 T.Kitajima ADD START *******************************--
         , xiel.product_code2              product_code2              --EDI���׏��e�[�u���D���i�R�[�h�Q
         , NVL(  xiel.product_name2_alt
                ,xiel.product_name1_alt 
              )                            product_name_alt           --EDI���׏��e�[�u���D���i���Q�i�J�i�jor ���i���P�i�J�i�j
--******************************* 2009/05/01 1.3 T.Kitajima ADD  END  *******************************--
         , oola.ordered_quantity           ordered_quantity           --�󒍖��׃e�[�u���D����
         , oola.unit_selling_price         unit_selling_price         --�󒍖��׃e�[�u���D�̔��P��
         , oola.line_number                line_number                --�󒍖��׃e�[�u���D���הԍ�
         , oola.ordered_item               ordered_item               --�󒍖��׃e�[�u���D�󒍕i��
         , oola.line_category_code         line_category_code         --�󒍖��׃e�[�u���D�󒍃J�e�S�����׃J�e�S���R�[�h
         , oola.order_quantity_uom         order_quantity_uom         --�󒍖��׃e�[�u���D�P��
         , oola.inventory_item_id          inventory_item_id          --�i��ID
         , oola.ship_from_org_id           ship_from_org_id           --�o�א�ڋq
         , ooha.sold_to_org_id             sold_to_org_id             --�����ڋq
    FROM   oe_order_headers_all            ooha                       --�󒍃w�b�_�e�[�u��
         , oe_order_lines_all              oola                       --�󒍖��׃e�[�u��
         , xxcos_edi_headers               xieh                       --EDI�w�b�_���e�[�u��
         , xxcos_edi_lines                 xiel                       --EDI���׏��e�[�u��
         , oe_order_sources                oosc                       --�󒍃\�[�X�e�[�u��
         , mtl_secondary_inventories       msiv                       --�ۊǏꏊ�}�X�^
         , xxcmm_cust_accounts             xcac                       --�ڋq�ǉ����
    WHERE
          ooha.order_source_id              =  oosc.order_source_id
    AND   oosc.name                         =  gv_edi_order_source
    AND   ooha.org_id                       =  gn_org_id
    AND   ooha.flow_status_code             =  cv_booked
    AND   ooha.header_id                    =  oola.header_id
    AND   oola.subinventory                 =  msiv.secondary_inventory_name
    AND   oola.ship_from_org_id             =  msiv.organization_id
    AND   msiv.attribute13                  =  cv_sales_car
    AND   xieh.order_connection_number      =  ooha.orig_sys_document_ref
    AND   xiel.edi_header_info_id           =  xieh.edi_header_info_id
    AND   xiel.order_connection_line_number =  oola.orig_sys_line_ref
    AND   xiel.hht_delivery_schedule_flag   =  cv_non_tran
    AND   xcac.customer_id(+)               =  oola.sold_to_org_id
/* 2009/07/08 Ver1.4 Add Start */
    AND   (
            ooha.global_attribute3          IS NULL
          OR
            ooha.global_attribute3          = cv_target_order_01
          )
/* 2009/07/08 Ver1.4 Add End   */
/* 2014/03/04 Ver1.7 Add Start */
    AND   ooha.ordered_date >=  gd_proc_date - gn_hht_deli_ord_keep_day + 1
    AND   ooha.ordered_date <   gd_proc_date + 1
/* 2014/03/04 Ver1.7 Add End */
    ORDER BY
          xieh.edi_header_info_id
        , xiel.line_no
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  g_h_handle       UTL_FILE.FILE_TYPE;
  g_l_handle       UTL_FILE.FILE_TYPE;
--
  TYPE g_rec_vndor_deli_l_rtype IS RECORD
    (
      delivery_base_code   xxcmm_cust_accounts.delivery_base_code%TYPE,    -- ���_�R�[�h
      order_number         oe_order_headers_all.order_number%TYPE,         -- ��No
      line_number          oe_order_lines_all.line_number%TYPE,            -- �sNo
      conv_customer_code   xxcos_edi_headers.conv_customer_code%TYPE,      -- �ڋq�R�[�h
      invoice_number       xxcos_edi_headers.invoice_number%TYPE,          -- �`�[�ԍ�
      ordered_item         oe_order_lines_all.ordered_item%TYPE,           -- ���Еi���R�[�h
      customer_item_number mtl_customer_items.customer_item_number%TYPE,   -- ���Еi���R�[�h
      customer_item_desc   mtl_customer_items.customer_item_desc%TYPE,     -- ���Еi��
      quantity_sign        VARCHAR2(1),                                    -- ���ʃT�C���i���׃J�e�S���R�[�h�j
      ordered_quantity     oe_order_lines_all.ordered_quantity%TYPE,       -- ����
      unit_selling_price   oe_order_lines_all.unit_selling_price%TYPE,     -- ���P��
      selling_price        xxcos_edi_lines.selling_price%TYPE,             -- ���P��
      edi_line_info_id     xxcos_edi_lines.edi_line_info_id%TYPE           -- �󒍖��׏��ID
    );
--
  TYPE g_tab_vndor_deli_l_ttype IS TABLE OF g_rec_vndor_deli_l_rtype INDEX BY PLS_INTEGER;
--
  gt_vndor_deli_lines         g_tab_vndor_deli_l_ttype; -- �[�i���׃��[�N�e�[�u�����o�f�[�^
--
  /**********************************************************************************
   * Procedure Name   : log_output
   * Description      : ���O�o��
   ***********************************************************************************/
  PROCEDURE log_output(
    iv_program      IN  VARCHAR2,            -- �v���O������
    iv_message      IN  VARCHAR2)            -- ���[�U�[�E�G���[���b�Z�[�W
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => iv_message
    );
--
    -- ���O���b�Z�[�W����
    lv_errbuf := SUBSTRB( cv_pkg_name||cv_msg_cont||iv_program||cv_msg_part||iv_message, 1, 5000 );
--
    -- ���O�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
--
  END log_output;
--
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
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �v���t�@�C��
    cv_prf_dir_path          CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_HHT_DIR';    -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
    cv_prf_h_filename        CONSTANT VARCHAR2(50) := 'XXCOS1_EOS_HEADER_FILE_NAME';-- EOS�w�b�_�t�@�C����
    cv_prf_l_filename        CONSTANT VARCHAR2(50) := 'XXCOS1_EOS_LINE_FILE_NAME';  -- EOS���׃t�@�C����
    cv_prf_org_id            CONSTANT VARCHAR2(50) := 'ORG_ID';                     -- MO:�c�ƒP��
    cv_prf_organization_code CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';   -- XXCOI:�݌ɑg�D�R�[�h
/* 2014/03/04 Ver1.7 Add Start */
    cv_prof_ord_keep_day     CONSTANT VARCHAR2(50) := 'XXCOS1_HHT_DELI_ORD_KEEP_DAY';  -- XXCOS:HHT�[�i�p�󒍕ێ�����
/* 2014/03/04 Ver1.7 Add End */
    -- �N�C�b�N�R�[�h�^�C�v
    cv_qck_odr_src_mst_type  CONSTANT VARCHAR2(50) := 'XXCOS1_ODR_SRC_MST_003_A01'; -- �󒍃\�[�X����^�C�v
    cv_qck_odr_src_mst_code  CONSTANT VARCHAR2(50) := 'XXCOS_003_A01_01';           -- �󒍃\�[�X����R�[�h
    -- ���b�Z�[�WID
    cv_msg_no_parameter      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';           -- �p�����[�^�Ȃ�
    cv_msg_pro               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';           -- �v���t�@�C���擾�G���[
    cv_msgfile_open          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';           -- �t�@�C���I�[�v���G���[
    cv_msg_mst_notfound      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10002';           -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
    cv_msg_lookup_value      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00046';           -- �N�C�b�N�R�[�h
    cv_msg_order_source      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00158';           -- �󒍃\�[�X
    -- �g�[�N��
    cv_tkn_profile           CONSTANT VARCHAR2(20) := 'PROFILE';                    -- �v���t�@�C����
    cv_tkn_file_name         CONSTANT VARCHAR2(20) := 'FILE_NAME';                  -- �t�@�C����
    cv_tkn_table             CONSTANT VARCHAR2(20) := 'TABLE';                      -- �e�[�u����
    cv_tkn_column            CONSTANT VARCHAR2(20) := 'COLMUN';                     -- �J������
--
    -- *** ���[�J���ϐ� ***
    lv_dir_path              VARCHAR2(100);                                         -- HHT�A�E�g�o�E���h�p�f�B���N�g���p�X
    lv_h_filename            VARCHAR2(100);                                         -- EOS�w�b�_�t�@�C����
    lv_l_filename            VARCHAR2(100);                                         -- EOS���׃t�@�C����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �󒍃\�[�X�J�[�\��
    CURSOR order_source_cur
    IS
      SELECT  lup_values.meaning       meaning
      FROM    fnd_lookup_values        lup_values
      WHERE   lup_values.language      = cv_default_language
      AND     lup_values.enabled_flag  = cv_enabled
      AND     lup_values.lookup_type   = cv_qck_odr_src_mst_type
      AND     lup_values.lookup_code   = cv_qck_odr_src_mst_code
      AND     TRUNC(SYSDATE)
      BETWEEN lup_values.start_date_active
      AND     NVL(lup_values.end_date_active, TRUNC(SYSDATE));
--
    -- *** ���[�J���E���R�[�h ***
    lt_order_source_rec      order_source_cur%ROWTYPE;                              -- EDI�쐬���敪�J�[�\�� ���R�[�h�ϐ�
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --��s
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_msg_no_parameter
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --��s
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
--
    --==============================================================
    -- �}���`�o�C�g�̌Œ�l�����b�Z�[�W���擾
    --==============================================================
    gv_msg_delivery_base_code   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_delivery_base_code
                                                           );
    gv_msg_order_number         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_order_number
                                                           );
    gv_msg_ordered_item         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_ordered_item
                                                           );
    gv_msg_customer_item_number := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_customer_item_number
                                                           );
    gv_msg_customer_item_desc   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_customer_item_desc
                                                           );
    gv_msg_ordered_quantity     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_ordered_quantity
                                                           );
    gv_msg_unit_selling_price   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_unit_selling_price
                                                           );
    gv_msg_selling_price        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_selling_price
                                                           );
    gv_msg_tkn_lock_table       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lock_table
                                                           );
    gv_msg_tkn_dir_path         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_dir_path
                                                           );
    gv_msg_tkn_h_filename       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_h_filename
                                                           );
    gv_msg_tkn_l_filename       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_l_filename
                                                           );
    gv_msg_tkn_h_file           := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_h_file
                                                           );
    gv_msg_tkn_l_file           := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_l_file
                                                           );
    gv_msg_tkn_org_id           := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_org_id
                                                           );
    gv_msg_tkn_organization_cd  := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_organization_cd
                                                           );
    gv_msg_tkn_update_table     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_update_table
                                                           );
    gv_msg_edi_line_id          := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_edi_line_id
                                                           );
/* 2014/03/04 Ver1.7 Add Start */
    gv_msg_tkn_ord_keep_day := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                       ,iv_name         => cv_msg_ord_keep_day
                                                           );
/* 2014/03/04 Ver1.7 Add End */
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:HHT�A�E�g�o�E���h�p�f�B���N�g���p�X)
    --==============================================================
    lv_dir_path := FND_PROFILE.VALUE(cv_prf_dir_path);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_dir_path IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_dir_path
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:EOS�w�b�_�t�@�C����)
    --==============================================================
    lv_h_filename := FND_PROFILE.VALUE(cv_prf_h_filename);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_h_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_h_filename
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:EOS���׃t�@�C����)
    --==============================================================
    lv_l_filename := FND_PROFILE.VALUE(cv_prf_l_filename);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (lv_l_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_l_filename);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �t�@�C�����̃��O�o��
    --==============================================================
    --EOS�w�b�_�t�@�C����
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_h_filename
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
--
    --EOS���׃t�@�C����
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_l_filename
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
--
    --��s
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
--
    --==============================================================
    -- EOS�w�b�_�t�@�C�� �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      g_h_handle := UTL_FILE.FOPEN(lv_dir_path
                                 , lv_h_filename
                                 , cv_file_access_mode);
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , gv_msg_tkn_h_file);
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- EOS���׃t�@�C�� �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      g_l_handle := UTL_FILE.FOPEN(lv_dir_path, lv_l_filename, cv_file_access_mode);
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , gv_msg_tkn_l_file);
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- �v���t�@�C���̎擾(MO:�c�ƒP��)
    --==============================================================
    gn_org_id := FND_PROFILE.VALUE(cv_prf_org_id);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_org_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(�݌ɑg�D�R�[�h)
    --==============================================================
    gv_organization_code := FND_PROFILE.VALUE(cv_prf_organization_code);
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF (gv_organization_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_organization_cd);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �󒍃\�[�X�擾
    --==============================================================
    gv_edi_order_source := NULL;
    -- �N�C�b�N�R�[�h����󒍃\�[�X���擾
    <<loop_set_order_source>>
    FOR lt_order_source_rec IN order_source_cur LOOP
      gv_edi_order_source := lt_order_source_rec.meaning;
    END LOOP;
--
    -- �󒍃\�[�X���擾�ł��Ȃ������ꍇ
    IF ( gv_edi_order_source IS NULL ) THEN
      -- �}�X�^�`�F�b�N�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_order_source );
      lv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_value );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application
                                           , cv_msg_mst_notfound
                                           , cv_tkn_column
                                           , lv_tkn1
                                           , cv_tkn_table
                                           , lv_tkn2 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
/* 2014/03/04 Ver1.7 Add Start */
    --==============================================================
    -- �Ɩ����t�擾
    --==============================================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(cv_application
                                           , cv_msg_proc_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- HHT�[�i�p�󒍕ێ�����
    --==============================================================
    gn_hht_deli_ord_keep_day := FND_PROFILE.VALUE( cv_prof_ord_keep_day );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_hht_deli_ord_keep_day IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_ord_keep_day );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2014/03/04 Ver1.7 Add End */
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : proc_break_process
   * Description      : �󒍃w�b�_���ID�u���C�N��̏����i�t�@�C���o�́A�X�e�[�^�X�X�V�j
   ***********************************************************************************/
  PROCEDURE proc_break_process(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_break_process'; -- �v���O������
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
    cn_lock_error_code   CONSTANT NUMBER := -54;
--
    -- *** ���[�J���ϐ� ***
    lv_edi_line_info_id      xxcos_edi_lines.edi_line_info_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ��O���� ***
    break_process_expt EXCEPTION;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- Loop2 ����
    -- ===============================
    <<lines_update_loop>>
    FOR i IN 1..gt_vndor_deli_lines.COUNT LOOP
      -- ===============================
      -- A-3 EDI���׏��e�[�u�����R�[�h���b�N
      -- ===============================
      BEGIN
        SELECT xels.edi_line_info_id
        INTO   lv_edi_line_info_id
        FROM   xxcos_edi_lines xels
        WHERE  xels.edi_line_info_id = gt_vndor_deli_lines(i).edi_line_info_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          IF (SQLCODE = cn_lock_error_code) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_lock
                                                , cv_tkn_lock
                                                , gv_msg_tkn_lock_table
                                                 );
            -- ���O�o��
            log_output( cv_prg_name, lv_errmsg );
          ELSE
            lv_errmsg  := NULL;
          END IF;
          RAISE break_process_expt;
      END;
--
      -- ===============================
      -- A-4 EDI���׏��e�[�u���o�͍σt���O�X�V
      -- ===============================
      BEGIN
        UPDATE xxcos_edi_lines
        SET    hht_delivery_schedule_flag = cv_output_flag
              ,last_updated_by            = cn_last_updated_by
              ,last_update_date           = cd_last_update_date
              ,last_update_login          = cn_last_update_login
              ,request_id                 = cn_request_id
              ,program_application_id     = cn_program_application_id
              ,program_id                 = cn_program_id
              ,program_update_date        = cd_program_update_date
        WHERE  edi_line_info_id           = gt_vndor_deli_lines(i).edi_line_info_id
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                              -- �G���[�E���b�Z�[�W
                                          ,ov_retcode     => lv_retcode                             -- ���^�[���E�R�[�h
                                          ,ov_errmsg      => lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W
                                          ,ov_key_info    => gv_key_info                            -- �L�[���
                                          ,iv_item_name1  => gv_msg_edi_line_id                     -- ���ږ���1
                                          ,iv_data_value1 => gt_vndor_deli_lines(i).edi_line_info_id-- �f�[�^�̒l1
                                          );
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_update_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_update_table
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          -- ���O�o��
          log_output( cv_prg_name, lv_errmsg );
          RAISE break_process_expt;
      END;
    END LOOP lines_update_loop;
--
      -- ===============================
      -- A-5 EOS�w�b�_�t�@�C���f�[�^�o��
      -- ===============================
    BEGIN
      --�f�[�^�ҏW
      gv_h_file_data :=        cv_quot || gv_delivery_base_code               || cv_quot--�[�i���_�R�[�h
              || cv_delimit ||  TO_CHAR(gv_order_number)                                --��No
              || cv_delimit || cv_quot || gv_conv_customer_code               || cv_quot--�ڋq�R�[�h
              || cv_delimit || cv_quot || gv_invoice_number                   || cv_quot--�`�[�ԍ�
              || cv_delimit ||  TO_CHAR(gd_request_date,'YYYYMMDD')                     --�[�i��
              || cv_delimit || cv_quot || gv_big_classification_code          || cv_quot--���㕪�ދ敪
              || cv_delimit || cv_quot || gv_invoice_class                    || cv_quot--����`�[�敪
              || cv_delimit || cv_quot || gv_company_name_alt                 || cv_quot--�Ж��i�J�i�j
              || cv_delimit || cv_quot || gv_shop_name_alt                    || cv_quot--�X���i�J�i�j
              || cv_delimit || cv_quot || gv_edi_chain_code                   || cv_quot--�`�F�[���X�R�[�h
      ;
      UTL_FILE.PUT_LINE(g_h_handle
                       ,gv_h_file_data
                       );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        RAISE;
    END;
--
   --   ===============================
   --   Loop3 ����(�t�@�C��)
   --   ===============================
    <<lins_out_loop>>
    FOR i IN 1..gt_vndor_deli_lines.COUNT LOOP
--
      -- ===============================
      -- A-6 EOS���׃t�@�C���f�[�^�o��
      -- ===============================
      BEGIN
        --�f�[�^�ҏW
        gv_l_file_data :=        cv_quot || gt_vndor_deli_lines(i).delivery_base_code    || cv_quot --�[�i���_�R�[�h
                || cv_delimit ||  gt_vndor_deli_lines(i).order_number                               --��No
                || cv_delimit ||  gt_vndor_deli_lines(i).line_number                                --�sNo
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).conv_customer_code    || cv_quot --�ڋq�R�[�h
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).invoice_number        || cv_quot --�`�[�ԍ�
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).ordered_item          || cv_quot --���Еi���R�[�h
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).customer_item_number  || cv_quot --���Еi���R�[�h
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).customer_item_desc    || cv_quot --���Еi��
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).quantity_sign         || cv_quot --���ʃT�C��
                || cv_delimit || TO_CHAR(gt_vndor_deli_lines(i).ordered_quantity, cv_number_format8)--����
                || cv_delimit || TO_CHAR(gt_vndor_deli_lines(i).unit_selling_price, cv_number_format7)  --���P��
                || cv_delimit || TO_CHAR(gt_vndor_deli_lines(i).selling_price)                      --���P��
        ;
        UTL_FILE.PUT_LINE(g_l_handle
                         ,gv_l_file_data
                         );
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          RAISE;
      END;
    END LOOP lins_out_loop;
--
    -- ===============================
    -- A-7 �g�����U�N�V��������
    -- ===============================
    COMMIT;
--
  EXCEPTION
    WHEN break_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ROLLBACK;
      -- �x�������ɖ��א������Z
      gn_warn_cnt := gn_warn_cnt + gt_vndor_deli_lines.COUNT;
      ov_retcode  := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- �x�������ɖ��א������Z
      gn_warn_cnt := gn_warn_cnt + gt_vndor_deli_lines.COUNT;
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_break_process;
--
  /**********************************************************************************
   * Procedure Name   : proc_main_loop�i���[�v���j
   * Description      : A-2�f�[�^���o
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- ���C�����[�v����
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
    cn_max_val_order_number       NUMBER := 999999999;      -- �󒍔ԍ��ő�l
    cn_max_val_line_number        NUMBER := 999;            -- ���הԍ��ő�l
    cn_max_len_ordered_item       NUMBER := 7;              -- �󒍕i�ڍő包��
    cn_max_len_customer_item_num  NUMBER := 13;             -- �ڋq�i�ڃR�[�h�ő包��
    cn_max_len_customer_item_desc NUMBER := 15;             -- �ڋq�i�ړE�v�ő包��
    cn_max_val_ordered_quantity   NUMBER := 99999999.99;    -- �󒍐��ʍő�l
    cn_max_val_unit_selling_price NUMBER := 9999999.99;     -- �̔��P���ő�l
    cn_max_val_selling_price      NUMBER := 9999999;        -- ���P���ő�l
    cn_max_len_invoice_number     NUMBER := 9;              -- �`�[�ԍ��ő包��
    cn_cut_len_invoice_number     NUMBER := -9;             -- �`�[�ԍ��؂�o�������i���9���j
--
    -- *** ���[�J���ϐ� ***
    lv_sign                VARCHAR2(1);
    lv_invoice_number      VARCHAR2(9);
    lv_item_name           VARCHAR2(20);
    lv_message_code        VARCHAR2(20);
    lv_item_value          VARCHAR2(100);
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
    lv_organization_id     VARCHAR2(10);                    -- �݌ɑg�D�h�c
    lv_after_uom_code      VARCHAR2(10);                    -- ���Z��P�ʃR�[�h
    ln_after_quantity      NUMBER;                          -- ���Z�㐔��
    ln_content             NUMBER;                          -- ����
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
/* 2015/01/08 Ver1.8 Add Start */
    ln_tmp_selling_price      xxcos_edi_lines.selling_price%TYPE;          -- ���P��(�ꎞ)
    ln_tmp_unit_selling_price oe_order_lines_all.unit_selling_price%TYPE;  -- ���P��(�ꎞ)
/* 2015/01/08 Ver1.8 Add End */
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �`�F�b�N�X�e�[�^�X������
    gv_transaction_status := NULL;
    gn_edi_header_info_id := NULL;
--
    <<main_loop>>
    FOR main_rec in main_cur LOOP
--
      -- �Ώی������C���N�������g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- �󒍃w�b�_���ID�u���C�N����
      -- ===============================
      IF (gn_edi_header_info_id IS NULL                          -- ���C�����[�v����
      OR main_rec.edi_header_info_id = gn_edi_header_info_id)    -- �u���C�N���ĂȂ�
      THEN
        NULL;
      ELSE
        -- �󒍃w�b�_���ID���ɃG���[����
        IF (gv_transaction_status IS NULL) THEN
          proc_break_process(
             lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            --�x������
            ov_retcode := lv_retcode;
          END IF;
--
        ELSE
          -- �x�������ɃG���[���א������Z
          gn_warn_cnt := gn_warn_cnt + gn_set_cnt;
--
        END IF;
--
        -- �ݒ�J�E���^������
        gn_set_cnt := 0;
        -- PL/SQL�\�N���A
        gt_vndor_deli_lines.DELETE;
        -- �󒍃w�b�_���ID���̃G���[����X�e�[�^�X�̏�����
        gv_transaction_status := NULL;
      END IF;
--
--****************************** 2009/05/01 1.3 T.Kitajima MOD START ******************************--
--      BEGIN
--        SELECT mcis.customer_item_number
--              ,mcis.customer_item_desc
--        INTO   gv_customer_item_number
--              ,gv_customer_item_desc
--        FROM   mtl_customer_items              mcis                   -- �ڋq�i��
--              ,mtl_customer_item_xrefs         mcix                   -- �ڋq�i�ڑ��ݎQ��
--              ,mtl_parameters                  mtpa
--              ,hz_cust_accounts                cust_acct              -- �ڋq�}�X�^�i10�F�ڋq�j
--              ,hz_cust_accounts                chain_acct             -- �ڋq�}�X�^�i18�F�`�F�[���X�j
--              ,xxcmm_cust_accounts             cust_addon             -- �ڋq�A�h�I���i10�F�ڋq�j
--              ,xxcmm_cust_accounts             chain_addon            -- �ڋq�A�h�I���i18�F�`�F�[���X�j
--        WHERE  mcix.inventory_item_id          =  main_rec.inventory_item_id
--        AND    mcix.customer_item_id           =  mcis.customer_item_id
--        AND    mcix.master_organization_id     =  mtpa.master_organization_id
--        AND    cust_addon.customer_id          =  main_rec.sold_to_org_id
--        AND    cust_addon.customer_id          =  cust_acct.cust_account_id
--        AND    cust_acct.customer_class_code   =  cv_cust_class_cust
--        AND    cust_addon.chain_store_code     =  chain_addon.chain_store_code
--        AND    chain_acct.cust_account_id      =  chain_addon.customer_id
--        AND    chain_acct.customer_class_code  =  cv_cust_class_chain
--        AND    mcis.customer_id                =  chain_addon.customer_id
--        AND    mcis.attribute1                 =  main_rec.order_quantity_uom
--        AND    mcis.item_definition_level      =  cv_customer
--        AND    mtpa.organization_code          =  gv_organization_code
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          gv_customer_item_number := NULL;
--          gv_customer_item_desc   := NULL;
--      END;
      gv_customer_item_number := main_rec.product_code2;
      gv_customer_item_desc   := main_rec.product_name_alt;
--****************************** 2009/05/01 1.3 T.Kitajima MOD  END  ******************************--
--
      -- ===============================
      -- A-10 �f�[�^�`�F�b�N
      -- ===============================
      BEGIN
        --------------------
        -- �K�{�`�F�b�N
        --------------------
        --���_�R�[�h
        IF ( main_rec.delivery_base_code IS NULL ) THEN
          lv_message_code := cv_msg_notnull;
          lv_item_name    := gv_msg_delivery_base_code;
          lv_item_value   := main_rec.delivery_base_code; --�K��null�ɂȂ邪�A�����`�F�b�N�ƃp�����[�^�𑵂���ׁB
          RAISE global_data_check_expt;
        END IF;
--
        --------------------
        -- �����`�F�b�N
        --------------------
        -- �󒍃w�b�_�e�[�u���F�󒍔ԍ�
        IF ( main_rec.order_number > cn_max_val_order_number ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_order_number;
          lv_item_value   := main_rec.order_number;
          RAISE global_data_check_expt;
        END IF;
--
        -- �󒍖��׃e�[�u���F���הԍ�
        IF  (main_rec.line_number > cn_max_val_line_number ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_line_number;
          lv_item_value   := main_rec.line_number;
          RAISE global_data_check_expt;
        END IF;
--
        -- �󒍖��׃e�[�u���F�󒍕i��
        IF ( LENGTHB(main_rec.ordered_item) > cn_max_len_ordered_item ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_ordered_item;
          lv_item_value   := main_rec.ordered_item;
          RAISE global_data_check_expt;
        END IF;
--
        -- �ڋq�i�ځF�ڋq�i�ڃR�[�h
        IF ( LENGTHB(gv_customer_item_number) > cn_max_len_customer_item_num ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_customer_item_number;
          lv_item_value   := gv_customer_item_number;
          RAISE global_data_check_expt;
        END IF;
--
        -- �ڋq�i�ځF�ڋq�i�ړE�v
        IF ( LENGTHB(gv_customer_item_desc) > cn_max_len_customer_item_desc ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_customer_item_desc;
          lv_item_value   := gv_customer_item_desc;
          RAISE global_data_check_expt;
        END IF;
--
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
        -- �󒍐��ʂ̒P�ʊ��Z
        lv_organization_id := NULL;  --NULL��ݒ�i���ʊ֐����œ��o�j
        lv_after_uom_code  := NULL;  --���Z��P�ʃR�[�h�̏�����
/* 2015/01/08 Ver1.8 Add Start */
        ln_tmp_unit_selling_price := NULL;  --���P���̏�����
        ln_tmp_selling_price      := NULL;  --���P���̏�����
/* 2015/01/08 Ver1.8 Add End */
        xxcos_common_pkg.get_uom_cnv(
                                     main_rec.order_quantity_uom,   -- ���Z�O�P�ʃR�[�h
                                     main_rec.ordered_quantity,     -- ���Z�O����
                                     main_rec.ordered_item,         -- �i�ڃR�[�h
                                     gv_organization_code,          -- �݌ɑg�D�R�[�h
                                     main_rec.inventory_item_id,    -- �i��ID
                                     lv_organization_id,            -- �݌ɑg�D�h�c
                                     lv_after_uom_code,             -- ���Z��P�ʃR�[�h
                                     ln_after_quantity,             -- ���Z�㐔��
                                     ln_content,                    -- ����
                                     lv_errbuf,                     -- �G���[����b�Z�[�W
                                     lv_retcode,                    -- ���^�[���R�[�h
                                     lv_errmsg                      -- ���[�U��G���[����b�Z�[�W
                                    );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_change_err_expt;
        END IF;
/* 2015/01/08 Ver1.8 Add Start */
        -- ���Z�O���ʂƊ��Z�㐔�ʂ��قȂ�ꍇ
        IF ( main_rec.ordered_quantity <> ln_after_quantity ) THEN
           ln_tmp_unit_selling_price := TRUNC(main_rec.unit_selling_price / ln_content, 2);--���P��
           ln_tmp_selling_price      := TRUNC(main_rec.selling_price      / ln_content);   --���P��
        -- ���Z�O��Ő��ʂ��������ꍇ
        ELSE
           ln_tmp_unit_selling_price   := main_rec.unit_selling_price   ;--���P��
           ln_tmp_selling_price        := main_rec.selling_price        ;--���P��
        END IF;
/* 2015/01/08 Ver1.8 Add End */
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
--
        -- �󒍖��׃e�[�u���F�󒍐���
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--        IF ( main_rec.ordered_quantity > cn_max_val_ordered_quantity ) THEN
        IF ( ln_after_quantity > cn_max_val_ordered_quantity ) THEN
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
          lv_message_code := cv_msg_overflow;
          lv_item_name := gv_msg_ordered_quantity;
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--          lv_item_value   := main_rec.ordered_quantity;
          lv_item_value   := ln_after_quantity;
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
          RAISE global_data_check_expt;
        END IF;
--
        -- �󒍖��׃e�[�u���F�̔��P��
/* 2015/01/08 Ver1.8 Mod Start */
--        IF ( main_rec.unit_selling_price > cn_max_val_unit_selling_price ) THEN
        IF ( ln_tmp_unit_selling_price > cn_max_val_unit_selling_price ) THEN
/* 2015/01/08 Ver1.8 Mod End */
          lv_message_code := cv_msg_overflow;
          lv_item_name := gv_msg_unit_selling_price;
          lv_item_value   := main_rec.unit_selling_price;
          RAISE global_data_check_expt;
        END IF;
--
        -- EDI���׏��e�[�u���F���P��
/* 2015/01/08 Ver1.8 Mod Start */
--        IF ( main_rec.selling_price > cn_max_val_selling_price ) THEN
        IF ( ln_tmp_selling_price > cn_max_val_selling_price ) THEN
/* 2015/01/08 Ver1.8 Mod End */
          lv_message_code := cv_msg_overflow;
          lv_item_name := gv_msg_selling_price;
          lv_item_value   := main_rec.selling_price;
          RAISE global_data_check_expt;
        END IF;
--
      EXCEPTION
        WHEN global_data_check_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                               ,lv_message_code
                                               ,cv_tkn_order_number
                                               ,main_rec.order_number
                                               ,cv_tkn_line_number
                                               ,main_rec.line_number
                                               ,cv_tkn_item_name
                                               ,lv_item_name
                                               ,cv_tkn_item_value
                                               ,lv_item_value
                                               );
                                               
          -- ���O�o��
          log_output( cv_prg_name, lv_errmsg );
          ov_errmsg := lv_errmsg;
          ov_errbuf := lv_errmsg;
          gv_transaction_status := cv_error_status;
          ov_retcode  := cv_status_warn;
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
        WHEN global_change_err_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                               ,cv_msg_change_err
                                               ,cv_tkn_order_number
                                               ,main_rec.order_number
                                               ,cv_tkn_line_number
                                               ,main_rec.line_number
                                               ,cv_tkn_err_msg
                                               ,lv_errmsg
                                               );
--
          -- ���O�o��
          log_output( cv_prg_name, lv_errmsg );
          ov_errmsg := lv_errmsg;
          ov_errbuf := lv_errmsg;
          gv_transaction_status := cv_error_status;
          ov_retcode  := cv_status_warn;
--
          --��s
          FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                           ,buff   => ''
                           );
          FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                           ,buff   => ''
                           );
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
      END;
--
      -- ===============================
      -- A-8 EOS���׃t�@�C���o�͗p�ɕϐ��ݒ�
      -- ===============================
      -- ���ʃT�C���̕ҏW
      IF ( main_rec.line_category_code = cv_order ) THEN
        lv_sign := cv_brank;
      ELSE
        lv_sign := cv_minus;
      END IF;
--
      -- �`�[�ԍ��̕ҏW
      IF ( LENGTHB(main_rec.invoice_number) > cn_max_len_invoice_number ) THEN
        -- �`�[�ԍ���9�����̏ꍇ�́A����9�������o��
        lv_invoice_number := SUBSTRB( main_rec.invoice_number, cn_cut_len_invoice_number );
      ELSE
        -- �`�[�ԍ���9���ȉ��̏ꍇ�́A���̂܂܏o��
        lv_invoice_number := main_rec.invoice_number;
      END IF;
--
      -- �ݒ�J�E���^���C���N�������g
      gn_set_cnt := gn_set_cnt + 1;
--
      gt_vndor_deli_lines(gn_set_cnt).delivery_base_code   := main_rec.delivery_base_code   ;--���_�R�[�h
      gt_vndor_deli_lines(gn_set_cnt).order_number         := main_rec.order_number         ;--��No
      gt_vndor_deli_lines(gn_set_cnt).line_number          := main_rec.line_number          ;--�sNo
      gt_vndor_deli_lines(gn_set_cnt).conv_customer_code   := main_rec.conv_customer_code   ;--�ڋq�R�[�h
      gt_vndor_deli_lines(gn_set_cnt).invoice_number       := lv_invoice_number             ;--�`�[�ԍ�
      gt_vndor_deli_lines(gn_set_cnt).ordered_item         := main_rec.ordered_item         ;--���Еi���R�[�h
      gt_vndor_deli_lines(gn_set_cnt).customer_item_number := gv_customer_item_number       ;--���Еi���R�[�h
      gt_vndor_deli_lines(gn_set_cnt).customer_item_desc   := gv_customer_item_desc         ;--���Еi��
      gt_vndor_deli_lines(gn_set_cnt).quantity_sign        := lv_sign                       ;--���ʃT�C���i���׃J�e�S���R�[�h�j
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--      gt_vndor_deli_lines(gn_set_cnt).ordered_quantity     := main_rec.ordered_quantity     ;--����
      gt_vndor_deli_lines(gn_set_cnt).ordered_quantity     := ln_after_quantity             ;--����
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
/* 2015/01/08 Ver1.8 Mod Start */
--      gt_vndor_deli_lines(gn_set_cnt).unit_selling_price   := main_rec.unit_selling_price   ;--���P��
--      gt_vndor_deli_lines(gn_set_cnt).selling_price        := main_rec.selling_price        ;--���P��
      gt_vndor_deli_lines(gn_set_cnt).unit_selling_price   := ln_tmp_unit_selling_price     ;--���P��
      gt_vndor_deli_lines(gn_set_cnt).selling_price        := ln_tmp_selling_price          ;--���P��
/* 2015/01/08 Ver1.8 Mod End */
      gt_vndor_deli_lines(gn_set_cnt).edi_line_info_id     := main_rec.edi_line_info_id     ;--EDI���׏��ID
--
      --�����[�v���Ɏg�p���邽�߂Ƀw�b�_�t�@�C���o�͗p�ɕϐ��ݒ�
      gv_delivery_base_code      := main_rec.delivery_base_code     ;--�[�i���_�R�[�h
      gv_order_number            := main_rec.order_number           ;--��No
      gv_conv_customer_code      := main_rec.conv_customer_code     ;--�ڋq�R�[�h
      gv_invoice_number          := lv_invoice_number               ;--�`�[�ԍ�
      gd_request_date            := main_rec.request_date           ;--�[�i��
      gv_big_classification_code := main_rec.big_classification_code;--���㕪�ދ敪
      gv_invoice_class           := main_rec.invoice_class          ;--����`�[�敪
      gv_company_name_alt        := main_rec.company_name_alt       ;--�Ж��i�J�i�j
      gv_shop_name_alt           := main_rec.shop_name_alt          ;--�X���i�J�i�j
      gv_edi_chain_code          := main_rec.edi_chain_code         ;--�`�F�[���X�R�[�h
      gn_edi_header_info_id      := main_rec.edi_header_info_id     ;--�󒍃w�b�_���ID
    END LOOP main_loop;
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
  END proc_main_loop;

--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    gn_set_cnt    := 0;
--
    -- ===============================================
    -- ��������
    -- ===============================================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- Loop1 ���C�� A-2�f�[�^���o
    -- ===============================
--
    proc_main_loop(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (gn_target_cnt > 0) THEN
--
      IF (lv_retcode != cv_status_normal) THEN
        -- ���^�[���R�[�h�ݒ�
        ov_retcode := lv_retcode;
      END IF;
--
      -- �󒍃w�b�_���ID���ɃG���[����
      IF (gv_transaction_status IS NULL) THEN
--
        --(�x�������܂��͐��폈��)
        proc_break_process(
           lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        IF (lv_retcode != cv_status_normal) THEN
          -- ���^�[���R�[�h�ݒ�
          ov_retcode := lv_retcode;
        END IF;
--
      ELSE
          -- �x�������ɃG���[���א������Z
          gn_warn_cnt := gn_warn_cnt + gn_set_cnt;
--
      END IF;
--
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- �I������
    -- ===============================================
    --�t�@�C���̃N���[�Y
    UTL_FILE.FCLOSE(g_h_handle);
    UTL_FILE.FCLOSE(g_l_handle);
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
    --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
    --�Ώی����o��
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
    --
    --���������o��
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
    --
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
END XXCOS003A01C;
/
