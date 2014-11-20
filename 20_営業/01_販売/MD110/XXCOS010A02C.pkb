CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A02C(body)
 * Description      : ��OIF�ւ̎捞�@�\
 * MD.050           : ��OIF�ւ̎捞(MD050_COS_010_A02)
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              ��������(A-1)
 *  proc_get_edi_headers   EDI�w�b�_���e�[�u���f�[�^���o(A-2)
 *  proc_data_validate_1   �f�[�^�Ó����`�F�b�N1(A-3)
 *  proc_set_oif_headers   �󒍃w�b�_OIF�p�ϐ��i�[(A-4)
 *  proc_get_edi_lines     EDI���׏��e�[�u���f�[�^���o(A-5)
 *  proc_data_validate_2   �f�[�^�Ó����`�F�b�N2(A-6)
 *  proc_set_oif_lines     �󒍖���OIF�p�ϐ��i�[(A-7)
 *  proc_set_oif_actions   �󒍏���OIF�p�ϐ��i�[(A-8)
 *  proc_upd_edi_headers   EDI�w�b�_���e�[�u���X�V(A-9)
 *  proc_ins_oif_headers   �󒍃w�b�_OIF�e�[�u���o�^(A-10)
 *  proc_ins_oif_lines     �󒍖���OIF�e�[�u���o�^(A-11)
 *  proc_ins_oif_actions   �󒍏���OIF�e�[�u���o�^(A-12)
 *  proc_end               �I������(A-13)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   T.Oura           �V�K�쐬
 *  2009/02/05    1.1   M.Yamaki         [COS_033]�ʉߍ݌Ɍ^�敪�Q�ƃo�O�̑Ή�
 *                                       [COS_044]�󒍃C���|�[�g�A�g�s��Ή�
 *  2009/02/10    1.2   T.Oura           [COS_046]��OIF(�w�b�_�A����)��CONTEXT�l�ݒ�Ή�
 *  2009/02/24    1.3   T.Nakamura       [COS_133]���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/04/15    1.4   T.Kitajima       [T1_0484]�����p���_�擾���@�ύX
 *                                       [T1_0469]�󒍖���OIF.�ڋq�����ԍ��̕ҏW�C��
 *  2009/05/08    1.5   T.Kitajima       [T1_0780]���i�v�Z�t���O�ݒ���@�ύX
 *  2009/06/17    1.6   K.Kiriu          [T1_1462]���b�N�s���Ή�
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  lock_expt                 EXCEPTION;       -- ���b�N�G���[
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  data_lock_expt            EXCEPTION;       -- ���b�N�G���[
  get_data_expt             EXCEPTION;       -- �f�[�^���o�G���[
  non_data_expt             EXCEPTION;       -- �Ώۃf�[�^�Ȃ��G���[
  ue_no_data_found          EXCEPTION;       -- �Ώۃf�[�^0���G���[
  upd_edi_headers_expt      EXCEPTION;       -- �f�[�^�X�V�G���[
  ins_data_expt             EXCEPTION;       -- �f�[�^�o�^�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS010A02C';                 -- �p�b�P�[�W��
  cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';                        -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_operation_unit     CONSTANT VARCHAR2(50)  := 'XXCOS1_ITOE_OU_MFG';           -- MO:�c�ƒP�ʁiITOE-OU-MFG�j
  -- �Q�ƃR�[�h
  cv_order_class            CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ORDER_CLASS';       -- �󒍃f�[�^(�󒍔[�i�m��敪11,12,24)
  cv_delivered_class        CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_DELIVERED_CLASS';   -- �[�i�m��f�[�^(�󒍔[�i�m��敪13)
  cv_err_item_type          CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';     -- EDI�i�ڃG���[�^�C�v
  -- �G���[�R�[�h
  cv_msg_order_source       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12004';             -- �󒍃\�[�X�擾�G���[���b�Z�[�W
  cv_msg_transaction_type   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12005';             -- �󒍃^�C�v�擾�G���[���b�Z�[�W
  cv_msg_trans_line_type    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12006';             -- �󒍖��׃^�C�v�擾�G���[���b�Z�[�W
  cv_msg_sales_type         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12007';             -- �Ώ۔���敪�擾�G���[���b�Z�[�W
  cv_msg_profile            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';             -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_getdata            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';             -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_nodata             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';             -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_lock               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';             -- ���b�N�G���[���b�Z�[�W
  cv_msg_shop_code          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12001';             -- �X�R�[�hNULL���b�Z�[�W
  cv_msg_order_qty          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12002';             -- ��������NULL���b�Z�[�W
  cv_msg_order_price        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12003';             -- �����P��NULL���b�Z�[�W
  cv_msg_insert             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';             -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_update             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';             -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_targetcnt          CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';             -- �Ώی������b�Z�[�W
  cv_msg_successcnt         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';             -- �����������b�Z�[�W
  cv_msg_errorcnt           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';             -- �G���[�������b�Z�[�W
  cv_msg_normal             CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';             -- ����I�����b�Z�[�W
  cv_msg_warning            CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';             -- �x���I�����b�Z�[�W
  cv_msg_error              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';             -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_no_param           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';             -- �R���J�����g���̓p�����[�^�Ȃ�
--
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(20)  := 'PROFILE';                      -- �v���t�@�C��
  cv_tkn_column             CONSTANT VARCHAR2(20)  := 'COLUMN';                       -- ���ږ�
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';                        -- �e�[�u����
  cv_tkn_order_no           CONSTANT VARCHAR2(20)  := 'ORDER_NO';                     -- �`�[�ԍ�
  cv_tkn_line_no            CONSTANT VARCHAR2(20)  := 'LINE_NO';                      -- �s�ԍ�
  cv_tkn_table_name         CONSTANT VARCHAR2(20)  := 'TABLE_NAME';                   -- �e�[�u����
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';                     -- �L�[���
  cv_tkn_count              CONSTANT VARCHAR2(20)  := 'COUNT';                        -- �Ώی���
--
  cv_edi_header_tab         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00114';             -- EDI�w�b�_���e�[�u��
  cv_oif_headers_tab        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00132';             -- �󒍃w�b�_�[OIF
  cv_oif_lines_tab          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00133';             -- �󒍖���OIF
  cv_oif_actions_tab        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00134';             -- �󒍏���OIF
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qck_type               CONSTANT VARCHAR2(50)  := 'XXCOS1_ODR_SRC_MST_010_A02';   -- �^�C�v
  cv_qck_code               CONSTANT VARCHAR2(50)  := 'XXCOS_010_A02_01';             -- �R�[�h
  cv_qck_type_2             CONSTANT VARCHAR2(50)  := 'XXCOS1_TXN_TYPE_MST_010_A02';  -- �^�C�v
  cv_qck_code_3             CONSTANT VARCHAR2(50)  := 'XXCOS_010_A02_02';             -- �R�[�h
  cv_qck_type_3             CONSTANT VARCHAR2(50)  := 'XXCOS1_SALE_CLASS';            -- �^�C�v
  cv_qck_code_2             CONSTANT VARCHAR2(50)  := '1';                              -- �R�[�h
  cv_qck_type_4             CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_CREATE_CLASS';      -- �^�C�v
  cv_qck_code_4             CONSTANT VARCHAR2(50)  := '10';                             -- �R�[�h
  cv_qck_code_5             CONSTANT VARCHAR2(50)  := '20';                             -- �R�[�h
  -- ���̑��萔
  cv_order_forward_flag     CONSTANT VARCHAR2(10)  := 'N';                            -- �󒍘A�g�σt���O(N)
  cv_cust_class_18          CONSTANT VARCHAR2(10)  := '18';                             -- �ڋq�敪(�`�F�[���X)
  cv_cust_class_10          CONSTANT VARCHAR2(10)  := '10';                             -- �ڋq�敪(�ڋq)
  cv_info_class_10          CONSTANT VARCHAR2(10)  := '10';                             -- ���敪
  cv_creat_class_order      CONSTANT VARCHAR2(10)  := '01';                             -- �쐬���敪(�󒍃f�[�^)
  cv_tsukagatazaiko_11      CONSTANT VARCHAR2(10)  := '11';                             -- �ʉݍ݌Ɍ^�敪
  cv_tsukagatazaiko_12      CONSTANT VARCHAR2(10)  := '12';                             -- �ʉݍ݌Ɍ^�敪
  cv_tsukagatazaiko_24      CONSTANT VARCHAR2(10)  := '24';                             -- �ʉݍ݌Ɍ^�敪
  cv_data_type_code_11      CONSTANT VARCHAR2(10)  := '11';                             -- �f�[�^��R�[�h
  cv_creat_class_deliv      CONSTANT VARCHAR2(10)  := '02';                             -- �쐬���敪(�[�i�m��f�[�^)
  cv_tsukagatazaiko_13      CONSTANT VARCHAR2(10)  := '13';                             -- �ʉݍ݌Ɍ^�敪
  cv_data_type_code_31      CONSTANT VARCHAR2(10)  := '31';                             -- �f�[�^��R�[�h
--
  cv_trans_type_code        CONSTANT VARCHAR2(50)  := 'ORDER';                        -- ����^�C�v�R�[�h
  cv_order_category         CONSTANT VARCHAR2(50)  := 'MIXED';                        -- �󒍃J�e�S��
  cv_book_order             CONSTANT VARCHAR2(50)  := 'BOOK_ORDER';                   -- �I�y���[�V�����R�[�h�u�L���v
  cv_language               CONSTANT VARCHAR2(50)  := USERENV('lang');                -- ���� 
  cv_trans_type_code_2      CONSTANT VARCHAR2(50)  := 'LINE';                         -- ����^�C�v�R�[�h(����)
  cv_order_category_2       CONSTANT VARCHAR2(50)  := 'ORDER';                        -- �󒍃J�e�S��
--
  cv_order_forward_flag_y   CONSTANT VARCHAR2(10)  := 'Y';                            -- �󒍘A�g�σt���O(Y)
  cv_dummy_item_flg_n       CONSTANT VARCHAR2(10)  := 'N';                            -- �_�~�[�i�ڃR�[�h
--
  cv_no_target_cnt          CONSTANT NUMBER        :=  0;                             -- ���o�Ώۃf�[�^0��
  cv_flg_y                  CONSTANT VARCHAR2(10)  := 'Y';                            -- 'Y'
  cv_flg_n                  CONSTANT VARCHAR2(10)  := 'N';                            -- 'N'
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  gv_operation_unit                  fnd_profile_option_values.profile_option_value%TYPE;   -- �c�ƒP��
  gv_order_source_id                 VARCHAR2(100);                                         -- �󒍃C���|�[�g�\�[�X
  gv_transaction_type_id             VARCHAR2(100);                                         -- ����^�C�vID
  gv_name_h                          VARCHAR2(100);                                         -- ����^�C�v���́i�w�b�_�j
  gv_trans_line_type_id              VARCHAR2(100);                                         -- ������׃^�C�vID
  gv_name_l                          VARCHAR2(100);                                         -- ������׃^�C�v���́i���ׁj
  gv_sales_type                      VARCHAR2(100);                                         -- ����敪
  gn_idx                             NUMBER;                                                -- �J�[�\���ϐ��i�w�b�_�p�j
  gn_l_idx                           NUMBER;                                                -- �J�[�\���ϐ��i���חp�j
  gn_ac_idx                          NUMBER;                                                -- �J�[�\���ϐ��i�󒍏����p�j
  gv_dummy_item_flg                  VARCHAR2(100);                                         -- �_�~�[�i��
  gn_org_id                          NUMBER;                                                -- �c�ƒP��ID
  gn_l_target_cnt                    NUMBER;                                                -- �Ώی����i���חp�j
  gn_l_idx_all                       NUMBER;                                                -- �Ώی����i���חp�j
  -- ���b�Z�[�W�p
  gv_edi_header_tab                  VARCHAR2(100);                                         -- APP-XXCOS1-00114
  -- EDI�w�b�_�A�g�σt���O�X�V�p�ϐ�
  gv_edi_forward_flag                VARCHAR2(100);
--
  -- EDI�w�b�_���e�[�u���J�[�\��
  CURSOR edi_headers_cur
  IS
  SELECT   xeh.edi_header_info_id            edi_header_info_id             -- EDI�w�b�_���ID
         , xeh.conv_customer_code            conv_customer_code             -- �ϊ���ڋq�R�[�h
         , xeh.edi_chain_code                edi_chain_code                 -- EDI�`�F�[���X�R�[�h
         , xeh.shop_code                     shop_code                      -- �X�R�[�h
         , xeh.invoice_number                invoice_number                 -- �`�[�ԍ�
         , xeh.order_date                    order_date                     -- ������
         , xeh.price_list_header_id          price_list_header_id           -- ���i�\�w�b�_ID
         , xeh.order_connection_number       order_connection_number        -- �󒍊֘A�ԍ�
         , xeh.order_forward_flag            order_forward_flag             -- �󒍘A�g�σt���O
         , xeh.shop_delivery_date            shop_delivery_date             -- �X�ܔ[�i��
         , xeh.creation_date                 creation_date                  -- �쐬��
         , xeh.center_delivery_date          center_delivery_date           -- �Z���^�[�[�i��
         , xeh.creation_class                creation_class                 -- �쐬���敪
         , xca.ship_storage_code             ship_storage_code              -- �o�׌��ۊǏꏊ(EDI)
         , CASE
--****************************** 2009/04/15 1.4 T.Kitajima ADD START ******************************--
             WHEN (xca.rsv_sale_base_act_date IS NULL ) THEN
               xca.sale_base_code
--****************************** 2009/04/15 1.4 T.Kitajima ADD  END  ******************************--
             WHEN (xca.rsv_sale_base_act_date <= xeh.order_date ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
             END                             sale_base_code                 -- ���㋒�_�R�[�h
         , xca.tsukagatazaiko_div            tsukagatazaiko_div             -- �ʉߍ݌Ɍ^�敪�iEDI�j
  FROM     xxcos_edi_headers     xeh                                        -- EDI�w�b�_���e�[�u��
         , hz_cust_accounts      hca                                        -- �ڋq�}�X�^
         , xxcmm_cust_accounts   xca                                        -- �ڋq�ǉ����
         , xxcos_lookup_values_v xlvv                                       -- �N�C�b�N�R�[�h
         , xxcos_lookup_values_v xlvv2                                      -- �N�C�b�N�R�[�h
  WHERE    xeh.order_forward_flag    =  cv_order_forward_flag
  AND     (( xeh.info_class          IS NULL )
  OR       ( xeh.info_class          = cv_info_class_10  ))
  AND      hca.account_number        =  xeh.conv_customer_code
  AND      hca.cust_account_id       =  xca.customer_id
  AND      hca.customer_class_code   = cv_cust_class_10
  AND     ((    xeh.creation_class        = xlvv2.meaning
          AND  xlvv.lookup_type           = cv_order_class
          AND  xca.tsukagatazaiko_div     = xlvv.meaning                    -- �Q�ƃ^�C�v�R�[�h
          AND  xeh.data_type_code         = cv_data_type_code_11
          AND  xlvv2.lookup_type          = cv_qck_type_4
          AND  xlvv2.lookup_code          = cv_qck_code_4)
          OR
          (    xeh.creation_class         = xlvv2.meaning
          AND  xlvv.lookup_type           = cv_delivered_class
          AND  xca.tsukagatazaiko_div     = xlvv.meaning                    -- �Q�ƃ^�C�v�R�[�h
          AND  xeh.data_type_code         = cv_data_type_code_31
          AND  xlvv2.lookup_type          = cv_qck_type_4
          AND  xlvv2.lookup_code          = cv_qck_code_5))
    ORDER BY
      xeh.invoice_number
/* 2009/06/17 Ver1.6 Mod Start */
--    FOR UPDATE NOWAIT;
    FOR UPDATE OF
      xeh.edi_header_info_id NOWAIT;
/* 2009/06/17 Ver1.6 Mod End   */
--
  -- EDI�w�b�_���e�[�u�� �e�[�u���^�C�v��`
  TYPE  g_tab_edi_headers                IS TABLE OF edi_headers_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- EDI�w�b�_���e�[�u���p�ϐ��i�J�[�\�����R�[�h�^�j
  gt_edi_headers                          g_tab_edi_headers;
--
    -- EDI���׏��e�[�u���J�[�\��
    CURSOR edi_lines_cur ( gn_l_idx NUMBER )
    IS
      SELECT   xel.line_no            line_no                  -- �sNo
             , xel.item_code          item_code                -- �i�ڃR�[�h
             , xel.line_uom           line_uom                 -- ���גP��
             , xel.sum_order_qty      sum_order_qty            -- ��������(���v�A�o��)
             , xel.order_unit_price   order_unit_price         -- ���P��(����)
             , NVL2(xlvv.lookup_code
                  , cv_flg_y
                  , cv_flg_n        ) err_item_flg             -- �G���[�i�ڃt���O
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
             , xel.taking_unit_price  taking_unit_price        -- �捞�����P���i�����j
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
      FROM     xxcos_edi_lines       xel                       -- EDI���׏��e�[�u��
             , xxcos_lookup_values_v xlvv                      -- �N�C�b�N�R�[�h(�G���[�i��)
      WHERE    xel.edi_header_info_id    =  gt_edi_headers ( gn_idx ).edi_header_info_id
        AND    xel.item_code             =  xlvv.lookup_code (+)
        AND    cv_err_item_type          =  xlvv.lookup_type (+);
--
  -- EDI���׏��e�[�u�� �e�[�u���^�C�v��`
  TYPE  g_tab_edi_lines                  IS TABLE OF edi_lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- EDI���׏��e�[�u���p�ϐ��i�J�[�\�����R�[�h�^�j
  gt_edi_lines                            g_tab_edi_lines;
--
  -- �󒍃w�b�_OIF�e�[�u�����R�[�h�^�C�v��`
  TYPE g_rec_order_oif_header  IS RECORD
    (
      order_source_id               oe_headers_iface_all.order_source_id%TYPE,            -- �C���|�[�g�\�[�XID
      order_source                  oe_headers_iface_all.order_source%TYPE,               -- �C���|�[�g�\�[�X��
      orig_sys_document_ref         oe_headers_iface_all.orig_sys_document_ref%TYPE,      -- �O���V�X�e���󒍔ԍ�
      customer_po_number            oe_headers_iface_all.customer_po_number%TYPE,         -- �ڋq�����ԍ�
      ordered_date                  oe_headers_iface_all.ordered_date%TYPE,               -- �󒍓�
      order_type_id                 oe_headers_iface_all.order_type_id%TYPE,              -- �󒍃^�C�vID
      order_type                    oe_headers_iface_all.order_type%TYPE,                 -- �󒍃^�C�v��
      org_id                        oe_headers_iface_all.org_id%TYPE,                     -- �c�ƒP��ID
      order_category                oe_headers_iface_all.order_category%TYPE,             -- �󒍃J�e�S��
      price_list_id                 oe_headers_iface_all.price_list_id%TYPE,              -- ���i�\ID
      price_list                    oe_headers_iface_all.price_list%TYPE,                 -- ���i�\��
      salesrep                      oe_headers_iface_all.salesrep%TYPE,                   -- �c�ƒS��
      payment_term_id               oe_headers_iface_all.payment_term_id%TYPE,            -- �x�����@ID
      payment_term                  oe_headers_iface_all.payment_term%TYPE,               -- �x�����@
      customer_id                   oe_headers_iface_all.customer_id%TYPE,                -- �ڋqID
      customer_number               oe_headers_iface_all.customer_number%TYPE,            -- �ڋq�R�[�h
      customer_name                 oe_headers_iface_all.customer_name%TYPE,              -- �ڋq��
      context                       oe_headers_iface_all.context%TYPE,                    -- �R���e�L�X�g
      request_date                  oe_headers_iface_all.request_date%TYPE                -- �v����
    );
--
  -- �󒍖���OIF�e�[�u�����R�[�h�^�C�v��`
  TYPE g_rec_order_oif_line  IS RECORD
    (
      order_source_id               oe_lines_iface_all.order_source_id%TYPE,              -- �C���|�[�g�\�[�XID
      inventory_item                oe_lines_iface_all.inventory_item%TYPE,               -- �󒍕i��
      ordered_quantity              oe_lines_iface_all.ordered_quantity%TYPE,             -- �󒍐���
      order_quantity_uom            oe_lines_iface_all.order_quantity_uom%TYPE,           -- �󒍒P��
      unit_selling_price            oe_lines_iface_all.unit_selling_price%TYPE,           -- �̔��P��
      request_date                  oe_lines_iface_all.request_date%TYPE,                 -- �v����
      schedule_ship_date            oe_lines_iface_all.schedule_ship_date%TYPE,           -- �\��o�ד�
      customer_po_number            oe_lines_iface_all.customer_po_number%TYPE,           -- �ڋq�����ԍ�
      customer_line_number          oe_lines_iface_all.customer_line_number%TYPE,         -- �ڋq�������הԍ�
      orig_sys_document_ref         oe_lines_iface_all.orig_sys_document_ref%TYPE,        -- �O���V�X�e���󒍔ԍ�
      orig_sys_line_ref             oe_lines_iface_all.orig_sys_line_ref%TYPE,            -- �O���V�X�e���󒍖��הԍ�
      line_type_id                  oe_lines_iface_all.line_type_id%TYPE,                 -- ���׃^�C�vID
      attribute5                    oe_lines_iface_all.attribute5%TYPE,                   -- ����敪
      context                       oe_lines_iface_all.context%TYPE                       -- �R���e�L�X�g
      );
--
  -- �󒍏���OIF�e�[�u�����R�[�h�^�C�v��`
  TYPE g_rec_order_oif_actions  IS RECORD
    (
      order_source_id               oe_actions_iface_all.order_source_id%TYPE,            -- �C���|�[�g�\�[�XID
      orig_sys_document_ref         oe_actions_iface_all.orig_sys_document_ref%TYPE,      -- �O���V�X�e���󒍔ԍ�
      operation_code                oe_actions_iface_all.operation_code%TYPE              -- �I�y���[�V�����R�[�h
      );
--
  -- EDI�w�b�_���e�[�u�����R�[�h�^�C�v��`(EDI�w�b�_���ID)
  TYPE g_rec_edi_forward_flag  IS RECORD
    (
      edi_header_info_id                 xxcos_edi_headers.edi_header_info_id%TYPE             -- EDI�w�b�_���ID
      );
--
  TYPE g_order_oif_header                IS TABLE OF g_rec_order_oif_header;
--
  TYPE g_order_oif_line                  IS TABLE OF g_rec_order_oif_line;
--
  TYPE g_order_oif_actions               IS TABLE OF g_rec_order_oif_actions;
--
  TYPE g_edi_forward_flag                IS TABLE OF g_rec_edi_forward_flag;
--
  -- �󒍃w�b�_OIF�e�[�u���p�ϐ�
  gt_order_oif_header                     g_order_oif_header;
  -- �󒍖���OIF�e�[�u���p�ϐ�
  gt_order_oif_line                       g_order_oif_line;
  -- �󒍏���OIF�e�[�u���p�ϐ�
  gt_order_oif_actions                    g_order_oif_actions;
  -- EDI�A�g�t���O�X�V�p�ϐ�
  gt_edi_forward_flag                     g_edi_forward_flag;
--
  -- �󒍃w�b�_OIF �e�[�u���^�C�v��`
  TYPE  g_tab_order_source_id            IS TABLE OF oe_headers_iface_all.order_source_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �C���|�[�g�\�[�XID
  TYPE  g_tab_orig_sys_document_ref      IS TABLE OF oe_headers_iface_all.orig_sys_document_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �O���V�X�e���󒍔ԍ�
  TYPE  g_tab_customer_po_number_h       IS TABLE OF oe_headers_iface_all.customer_po_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �ڋq�����ԍ�
  TYPE  g_tab_ordered_date               IS TABLE OF oe_headers_iface_all.ordered_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �󒍓�
  TYPE  g_tab_order_type_id              IS TABLE OF oe_headers_iface_all.order_type_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �󒍃^�C�vID
  TYPE  g_tab_org_id                     IS TABLE OF oe_headers_iface_all.org_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �c�ƒP��ID
  TYPE  g_tab_price_list_id              IS TABLE OF oe_headers_iface_all.price_list_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- ���i�\ID
  TYPE  g_tab_customer_number            IS TABLE OF oe_headers_iface_all.customer_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �ڋq�R�[�h
  TYPE  g_tab_request_date               IS TABLE OF oe_headers_iface_all.request_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �v����
  TYPE  g_tab_sale_base_code             IS TABLE OF oe_headers_iface_all.attribute12%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- ���㋒�_�R�[�h
  TYPE  g_tab_name_h                     IS TABLE OF oe_headers_iface_all.context%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- ����^�C�v����
  -- �󒍖���OIF �e�[�u���^�C�v��`
  TYPE  g_tab_order_source_id_l          IS TABLE OF oe_lines_iface_all.order_source_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �C���|�[�g�\�[�XID
  TYPE  g_tab_inventory_item             IS TABLE OF oe_lines_iface_all.inventory_item%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �󒍕i��
  TYPE  g_tab_ordered_quantity           IS TABLE OF oe_lines_iface_all.ordered_quantity%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �󒍐���
  TYPE  g_tab_order_quantity_uom         IS TABLE OF oe_lines_iface_all.order_quantity_uom%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �󒍒P��
  TYPE  g_tab_unit_selling_price         IS TABLE OF oe_lines_iface_all.unit_selling_price%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �̔��P��
  TYPE  g_tab_request_date_l             IS TABLE OF oe_lines_iface_all.request_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �v����
  TYPE  g_tab_schedule_ship_date         IS TABLE OF oe_lines_iface_all.schedule_ship_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �\��o�ד�
  TYPE  g_tab_customer_po_number_l       IS TABLE OF oe_lines_iface_all.customer_po_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �ڋq�����ԍ�
  TYPE  g_tab_customer_line_number       IS TABLE OF oe_lines_iface_all.customer_line_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �ڋq�������הԍ�
  TYPE  g_tab_orig_sys_document_ref_l    IS TABLE OF oe_lines_iface_all.orig_sys_document_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �O���V�X�e���󒍔ԍ�
  TYPE  g_tab_orig_sys_line_ref          IS TABLE OF oe_lines_iface_all.orig_sys_line_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �O���V�X�e���󒍖��הԍ�
  TYPE  g_tab_line_type_id               IS TABLE OF oe_lines_iface_all.line_type_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- ���׃^�C�vID
  TYPE  g_tab_attribute5                 IS TABLE OF oe_lines_iface_all.attribute5%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- ����敪
  TYPE  g_tab_name_l                     IS TABLE OF oe_lines_iface_all.context%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- ������׃^�C�v����
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
  TYPE  g_tab_calculate_price_flag       IS TABLE OF oe_lines_iface_all.calculate_price_flag%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- ���i�v�Z�t���O
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
  -- �󒍏���OIF �e�[�u���^�C�v��`
  TYPE  g_tab_order_source_id_ac         IS TABLE OF oe_actions_iface_all.order_source_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �C���|�[�g�\�[�XID
  TYPE  g_tab_orig_sys_document_ref_ac   IS TABLE OF oe_actions_iface_all.orig_sys_document_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �O���V�X�e���󒍔ԍ�
  TYPE  g_tab_operation_code_ac          IS TABLE OF oe_actions_iface_all.operation_code%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- �I�y���[�V�����R�[�h
  -- EDI�w�b�_���e�[�u�� �e�[�u���^�C�v��`
  TYPE  g_tab_edi_header_info_id         IS TABLE OF xxcos_edi_headers.edi_header_info_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- EDI�w�b�_���ID
--
  -- �󒍃w�b�_OIF�C���T�[�g�p�ϐ�
  gt_order_source_id                      g_tab_order_source_id;             -- �C���|�[�g�\�[�XID
  gt_orig_sys_document_ref                g_tab_orig_sys_document_ref;       -- �O���V�X�e���󒍔ԍ�
  gt_customer_po_number_h                 g_tab_customer_po_number_h;        -- �ڋq�������הԍ�
  gt_ordered_date                         g_tab_ordered_date;                -- �󒍓�
  gt_order_type_id                        g_tab_order_type_id;               -- �󒍃^�C�vID
  gt_org_id                               g_tab_org_id;                      -- �c�ƒP��ID
  gt_price_list_id                        g_tab_price_list_id;               -- ���i�\ID
  gt_customer_number                      g_tab_customer_number;             -- �ڋq�R�[�h
  gt_request_date                         g_tab_request_date;                -- �v����
  gt_sale_base_code                       g_tab_sale_base_code;              -- ���㋒�_�R�[�h
  gt_name_h                               g_tab_name_h;                      -- ����^�C�v����
--
  -- �󒍖���OIF�C���T�[�g�p�ϐ�
  gt_order_source_id_l                    g_tab_order_source_id_l;           -- �C���|�[�g�\�[�XID
  gt_inventory_item                       g_tab_inventory_item;              -- �󒍕i��
  gt_ordered_quantity                     g_tab_ordered_quantity;            -- �󒍐���
  gt_order_quantity_uom                   g_tab_order_quantity_uom;          -- �󒍒P��
  gt_unit_selling_price                   g_tab_unit_selling_price;          -- �̔��P��
  gt_request_date_l                       g_tab_request_date_l;              -- �v����
  gt_schedule_ship_date                   g_tab_schedule_ship_date;          -- �\��o�ד�
  gt_customer_po_number_l                 g_tab_customer_po_number_l;        -- �ڋq�����ԍ�
  gt_customer_line_number                 g_tab_customer_line_number;        -- �ڋq�������הԍ�
  gt_orig_sys_document_ref_l              g_tab_orig_sys_document_ref_l;     -- �O���V�X�e���󒍔ԍ�
  gt_orig_sys_line_ref                    g_tab_orig_sys_line_ref;           -- �O���V�X�e���󒍖��הԍ�
  gt_line_type_id                         g_tab_line_type_id;                -- ���׃^�C�vID
  gt_attribute5                           g_tab_attribute5;                  -- ����敪
  gt_name_l                               g_tab_name_l;                      -- ������׃^�C�v����
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
  gt_calculate_price_flag                 g_tab_calculate_price_flag;        -- ���i�v�Z�t���O
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
--
  -- �󒍏���OIF�C���T�[�g�p�ϐ�
  gt_order_source_id_ac                   g_tab_order_source_id_ac;          -- �C���|�[�g�\�[�XID
  gt_orig_sys_document_ref_ac             g_tab_orig_sys_document_ref_ac;    -- �O���V�X�e���󒍔ԍ�
  gt_operation_code_ac                    g_tab_operation_code_ac;           -- �I�y���[�V�����R�[�h
--
  -- �󒍘A�g�t���O�X�V�p�ϐ�
  gt_edi_header_info_id                   g_tab_edi_header_info_id;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_msg_output
   * Description      : ���b�Z�[�W�A���O�o��
   ***********************************************************************************/
  PROCEDURE proc_msg_output(
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
  END proc_msg_output;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';           -- �v���O������
    cv_appl_short_name_ccp CONSTANT VARCHAR2(10)  := 'XXCCP';      -- �A�h�I���F���ʁEIF�̈�
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
    lv_order_source_id        VARCHAR2(100);   -- �C���|�[�g�\�[�XID
    lv_name                   VARCHAR2(100);   -- �C���|�[�g�\�[�X��
    lv_transaction_type_id    VARCHAR2(100);   -- ����^�C�vID
    lv_name_h                 VARCHAR2(100);   -- ����^�C�v���́i�w�b�_�j
    lv_trans_line_type_id     VARCHAR2(100);   -- ������׃^�C�vID
    lv_name_l                 VARCHAR2(100);   -- ������׃^�C�v���́i���ׁj
    lv_sales_type             VARCHAR2(100);   -- ����敪 
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    -- �ϐ�������
    gv_operation_unit      := NULL;
--
   -- ==============================================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o��
   -- ==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name_ccp
                    , iv_name        => cv_msg_no_param
                  );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
    );
--
    -- ==============================================================
    -- �󒍃C���|�[�g�\�[�X���擾
    -- ==============================================================
    BEGIN
--
      SELECT   oos.order_source_id  order_source_id      -- �C���|�[�g�\�[�XID
             , oos.name             name                 -- �C���|�[�g�\�[�X��
      INTO     lv_order_source_id
             , lv_name
      FROM     oe_order_sources      oos                 -- �󒍃\�[�X
             , xxcos_lookup_values_v flv                 -- �N�C�b�N�R�[�h
      WHERE    oos.name          =  flv.meaning
      AND      flv.lookup_type   =  cv_qck_type
      AND      flv.lookup_code   =  cv_qck_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_source
                      );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_order_source_id  :=  lv_order_source_id;
--
    -- ==============================================================
    -- �󒍃^�C�v���擾
    -- ==============================================================
    BEGIN
--
      SELECT   otta.transaction_type_id  transaction_type_id      -- ����^�C�vID
             , ottt.name                 name_h                   -- ����^�C�v����
      INTO     lv_transaction_type_id
             , lv_name_h
      FROM     oe_transaction_types_all  otta                     -- �󒍎���^�C�v
             , oe_transaction_types_tl   ottt                     -- �󒍎���^�C�v�i�E�v�j
             , xxcos_lookup_values_v     flv                      -- �N�C�b�N�R�[�h
      WHERE    otta.transaction_type_id     =  ottt.transaction_type_id
      AND      otta.transaction_type_code   =  cv_trans_type_code
      AND      otta.order_category_code     =  cv_order_category
      AND      ottt.name                    =  flv.meaning
      AND      ottt.language                =  cv_language
      AND      flv.lookup_type              =  cv_qck_type_2
      AND      flv.lookup_code              =  cv_qck_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_transaction_type
                      );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_transaction_type_id  :=  lv_transaction_type_id;
    gv_name_h               :=  lv_name_h;
--
    -- ==============================================================
    -- �󒍖��׃^�C�v���擾
    -- ==============================================================
    BEGIN
--
      SELECT   otta.transaction_type_id  trans_line_type_id       -- ������׃^�C�vID
             , ottt.name                 name_l                   -- ������׃^�C�v����
      INTO     lv_trans_line_type_id
             , lv_name_l
      FROM     oe_transaction_types_all  otta                     -- �󒍎���^�C�v
             , oe_transaction_types_tl   ottt                     -- �󒍎���^�C�v�i�E�v�j
             , xxcos_lookup_values_v     flv                      -- �N�C�b�N�R�[�h
      WHERE    otta.transaction_type_id     =  ottt.transaction_type_id
      AND      otta.transaction_type_code   =  cv_trans_type_code_2
      AND      otta.order_category_code     =  cv_order_category_2
      AND      ottt.name                    =  flv.meaning
      AND      ottt.language                =  cv_language
      AND      flv.lookup_type              =  cv_qck_type_2
      AND      flv.lookup_code              =  cv_qck_code_3;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_trans_line_type
                      );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_trans_line_type_id  :=  lv_trans_line_type_id;
    gv_name_l              :=  lv_name_l;
--
    -- ==============================================================
    -- ����敪���擾
    -- ==============================================================
    BEGIN
--
      SELECT   flv.lookup_code    sales_type                     -- ����敪
      INTO     lv_sales_type
      FROM     xxcos_lookup_values_v  flv                        -- �N�C�b�N�R�[�h
      WHERE    flv.lookup_type      =  cv_qck_type_3
      AND      flv.lookup_code      =  cv_qck_code_2;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_sales_type
                      );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_sales_type  :=  lv_sales_type;
--
    -- ==============================================================
    -- �v���t�@�C���̎擾(MO:�c�ƒP��)
    -- ==============================================================
    gv_operation_unit := FND_PROFILE.VALUE(cv_prf_operation_unit);
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ
    IF ( gv_operation_unit IS NULL ) THEN
      -- �v���t�@�C���i�c�ƒP�ʁj�擾�G���[���o��
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_profile
                       , iv_token_name1  => cv_tkn_profile
                       , iv_token_value1 => cv_prf_operation_unit
                      );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    gn_org_id := fnd_global.org_id;
--
    -- �uAPP-XXCOS1-00114�v(EDI�w�b�_���e�[�u��)���b�Z�[�W�̎擾
    lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_edi_header_tab
                      );
    gv_edi_header_tab := cv_edi_header_tab;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_headers
   * Description      : EDI�w�b�_���e�[�u���f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_headers(
    on_target_cnt OUT NOCOPY NUMBER,       --   �Ώۃf�[�^����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_headers'; -- �v���O������
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
    -- OUT�p�����[�^������
    on_target_cnt := 0;
--
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN edi_headers_cur;
      -- �o���N�t�F�b�`
      FETCH edi_headers_cur BULK COLLECT INTO gt_edi_headers;
      -- ���o�����Z�b�g
      on_target_cnt := edi_headers_cur%ROWCOUNT;
      -- �J�[�\���N���[�Y
      CLOSE edi_headers_cur;
--
    EXCEPTION
      -- ���b�N�G���[
      WHEN lock_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_lock
                       , iv_token_name1  => cv_tkn_table
                       , iv_token_value1 => gv_edi_header_tab
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      -- �f�[�^���o�G���[
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_getdata
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => gv_edi_header_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ
    IF ( on_target_cnt = cv_no_target_cnt ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_nodata
                    );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_normal;
-- 2009/02/24 T.Nakamura Ver.1.1 add start
      --��s�}��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_get_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_data_validate_1
   * Description      : �f�[�^�Ó����`�F�b�N1(A-3)
   ***********************************************************************************/
  PROCEDURE proc_data_validate_1(
    ov_errbuf        OUT NOCOPY VARCHAR2,            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,            --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_validate_1'; -- �v���O������
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
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
--
  BEGIN
--
    -- A-2�Ŏ擾�����쐬���敪���[�i�m��f�[�^���ʉߍ݌Ɍ^�敪��11(�ʉߌ^��)�̏ꍇ
    IF ( gt_edi_headers ( gn_idx ).creation_class = cv_creat_class_deliv )
      AND ( gt_edi_headers ( gn_idx ).tsukagatazaiko_div != cv_tsukagatazaiko_11 )
      AND ( gt_edi_headers ( gn_idx ).shop_code IS NULL )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                   , iv_name         => cv_msg_shop_code
                   , iv_token_name1  => cv_tkn_order_no
                   , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                  );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
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
  END proc_data_validate_1;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_oif_headers
   * Description      : �󒍃w�b�_OIF�p�ϐ��i�[(A-4)
   ***********************************************************************************/
  PROCEDURE proc_set_oif_headers(
    ov_errbuf          OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔 
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_oif_headers'; -- �v���O������
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
    gt_order_source_id ( gn_idx )        :=  gv_order_source_id;                       -- �C���|�[�g�\�[�XID
    gt_orig_sys_document_ref ( gn_idx )  :=  gt_edi_headers ( gn_idx ).order_connection_number;
                                                                                       -- �O���V�X�e���󒍔ԍ�
    gt_customer_po_number_h ( gn_idx )   :=  gt_edi_headers ( gn_idx ).invoice_number; -- �ڋq�����ԍ�
    gt_ordered_date ( gn_idx )           :=  gt_edi_headers ( gn_idx ).order_date;     -- �󒍓�
    gt_order_type_id ( gn_idx )          :=  gv_transaction_type_id;                   -- �󒍃^�C�vID
    gt_org_id ( gn_idx )                 :=  gn_org_id;                                -- �c�ƒP��ID
    gt_price_list_id ( gn_idx )          :=  gt_edi_headers ( gn_idx ).price_list_header_id;
                                                                                       -- ���i�\ID
    gt_customer_number ( gn_idx )        :=  gt_edi_headers ( gn_idx ).conv_customer_code;
                                                                                       -- �ϊ���ڋq�R�[�h
    gt_request_date ( gn_idx )           :=  NVL( gt_edi_headers ( gn_idx ).shop_delivery_date, 
                                               NVL( gt_edi_headers ( gn_idx ).center_delivery_date,
                                                  NVL( gt_edi_headers ( gn_idx ).order_date,
                                                    gt_edi_headers ( gn_idx ).creation_date )));
                                                                                       -- �v����
    gt_sale_base_code ( gn_idx )         :=  gt_edi_headers ( gn_idx ).sale_base_code; -- ���㋒�_�R�[�h
    gt_name_h ( gn_idx )                 :=  gv_name_h;                                -- ����^�C�v����
--
    -- EDI�A�g�t���O�X�V�p�ϐ��Ɋi�[
    gt_edi_header_info_id ( gn_idx )     :=  gt_edi_headers ( gn_idx ).edi_header_info_id;  -- EDI�w�b�_���ID
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END proc_set_oif_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_lines
   * Description      : EDI���׏��e�[�u���f�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_lines(
    on_l_target_cnt OUT NOCOPY NUMBER,       --   �Ώۃf�[�^����
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_lines'; -- �v���O������
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
    ln_l_target_cnt NUMBER;
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
--
    -- OUT�p�����[�^������
    on_l_target_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN edi_lines_cur( gn_l_idx ) ;
    -- �o���N�t�F�b�`
    FETCH edi_lines_cur BULK COLLECT INTO gt_edi_lines;
    -- ���o�����Z�b�g
    on_l_target_cnt := edi_lines_cur%ROWCOUNT;
    -- �J�[�\���N���[�Y
    CLOSE edi_lines_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_get_edi_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_data_validate_2
   * Description      : �f�[�^�Ó����`�F�b�N2(A-6)
   ***********************************************************************************/
  PROCEDURE proc_data_validate_2(
    ov_errbuf        OUT NOCOPY VARCHAR2,            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,            --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_validate_2'; -- �v���O������
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
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
    -- A-2�Ŏ擾�����쐬���敪���󒍃f�[�^�̏ꍇ
    IF ( gt_edi_headers ( gn_idx ).creation_class = cv_creat_class_order ) THEN
--
      -- A-5�Ŏ擾������������(���v�E�o��)��NULL�̏ꍇ
      IF ( gt_edi_lines ( gn_l_idx ).sum_order_qty IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_qty
                       , iv_token_name1  => cv_tkn_order_no
                       , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                       , iv_token_name2  => cv_tkn_line_no
                       , iv_token_value2 => gt_edi_lines( gn_l_idx ).line_no
                      );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_warn;
      END IF;
--
    -- A-2�Ŏ擾�����쐬���敪���[�i�m��f�[�^�̏ꍇ
    ELSIF   ( gt_edi_headers ( gn_idx ).creation_class = cv_creat_class_deliv ) THEN
--
      -- A-5�Ŏ擾������������(���v�E�o��)��NULL�̏ꍇ
      IF ( gt_edi_lines ( gn_l_idx ).sum_order_qty IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_qty
                       , iv_token_name1  => cv_tkn_order_no
                       , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                       , iv_token_name2  => cv_tkn_line_no
                       , iv_token_value2 => gt_edi_lines( gn_l_idx ).line_no
                      );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_warn;
--
      -- A-5�Ŏ擾�������P��(����)��NULL�̏ꍇ
      ELSIF ( gt_edi_lines ( gn_l_idx ).order_unit_price IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_price
                       , iv_token_name1  => cv_tkn_order_no
                       , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                       , iv_token_name2  => cv_tkn_line_no
                       , iv_token_value2 => gt_edi_lines( gn_l_idx ).line_no
                      );
        lv_errbuf  := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_warn;
      END IF;
--
    END IF;
--
    -- A-5�Ŏ擾�����u�i�ڃR�[�h�v�Ƀ_�~�[�i�ڃR�[�h���ݒ肳��Ă����ꍇ
    -- �܂��́A���P��(����)��NULL�̏ꍇ(EDI�󒍂̂݁BEDI�[�i�m��̓G���[�ɂȂ�)
    IF  (( gt_edi_lines ( gn_l_idx ).err_item_flg     = cv_flg_y)
      OR ( gt_edi_lines ( gn_l_idx ).order_unit_price IS NULL ))
    THEN
      gv_dummy_item_flg := cv_dummy_item_flg_n;
    END IF;
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
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
  END proc_data_validate_2;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_oif_lines
   * Description      : �󒍖���OIF�p�ϐ��i�[(A-7)
   ***********************************************************************************/
  PROCEDURE proc_set_oif_lines(
    ov_errbuf          OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔 
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_oif_lines'; -- �v���O������
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
    CV_1     CONSTANT NUMBER  := 1;
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
    gt_order_source_id_l( gn_l_idx_all )           :=  gv_order_source_id;                        -- �C���|�[�g�\�[�XID
    gt_inventory_item( gn_l_idx_all )              :=  gt_edi_lines( gn_l_idx ).item_code;        -- �󒍕i��
    gt_ordered_quantity( gn_l_idx_all )            :=  gt_edi_lines( gn_l_idx ).sum_order_qty;    -- �󒍐���
    gt_order_quantity_uom( gn_l_idx_all )          :=  gt_edi_lines( gn_l_idx ).line_uom;         -- �󒍒P��
    gt_request_date_l( gn_l_idx_all )              :=  NVL( gt_edi_headers ( gn_idx ).shop_delivery_date,
                                                         NVL( gt_edi_headers ( gn_idx ).center_delivery_date,
                                                           NVL( gt_edi_headers ( gn_idx ).order_date,
                                                             gt_edi_headers ( gn_idx ).creation_date ))); 
                                                                                                  -- �v����
    gt_schedule_ship_date( gn_l_idx_all )          :=  NVL( gt_edi_headers ( gn_idx ).shop_delivery_date,
                                                         NVL( gt_edi_headers ( gn_idx ).center_delivery_date,
                                                           NVL( gt_edi_headers ( gn_idx ).order_date,
                                                             gt_edi_headers ( gn_idx ).creation_date ))); 
                                                                                                  -- �\��o�ד�
--****************************** 2009/04/15 1.4 T.Kitajima MOD START ******************************--
--    gt_customer_po_number_l( gn_l_idx_all )        :=  gt_edi_headers ( gn_idx ).conv_customer_code;   -- �ڋq�����ԍ�
    gt_customer_po_number_l( gn_l_idx_all )        :=  gt_edi_headers ( gn_idx ).invoice_number;  -- �ڋq�����ԍ�
--****************************** 2009/04/15 1.4 T.Kitajima MOD START ******************************--
    gt_customer_line_number( gn_l_idx_all )        :=  gt_edi_lines( gn_l_idx ).line_no;          -- �ڋq�������הԍ�
    gt_orig_sys_document_ref_l( gn_l_idx_all )     :=  gt_edi_headers ( gn_idx ).order_connection_number;
                                                                                                  -- �O���V�X�e���󒍔ԍ�
    gt_orig_sys_line_ref( gn_l_idx_all )           :=  gt_edi_lines( gn_l_idx ).line_no;          -- �O���V�X�e���󒍖��הԍ�
    gt_line_type_id( gn_l_idx_all )                :=  gv_trans_line_type_id;                     -- ���׃^�C�vID
    gt_attribute5( gn_l_idx_all )                  :=  gv_sales_type;                             -- ����敪
    gt_name_l( gn_l_idx_all )                      :=  gv_name_l;                                 -- ������׃^�C�v����
    -- A-5�Ŏ擾�������P��(����)��0�̏ꍇ
    IF ( gt_edi_lines( gn_l_idx ).order_unit_price  =  0 ) THEN                                   -- �̔��P��
      gt_unit_selling_price ( gn_l_idx_all )       := CV_1;
    -- ��L�ȊO�̏ꍇ
    ELSE
      gt_unit_selling_price ( gn_l_idx_all )       := gt_edi_lines( gn_l_idx ).order_unit_price;
    END IF;
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
    --EDI���� �u�捞�����P���i�����j�v��NULL�Ȃ��
    IF ( gt_edi_lines( gn_l_idx ).taking_unit_price IS NULL ) THEN
      --�󒍖���OIF�u���i�v�Z�t���O�v���uY�v
      gt_calculate_price_flag( gn_l_idx_all )      := cv_flg_y;
    ELSE
      --����ȊO�́uN�v
      gt_calculate_price_flag( gn_l_idx_all )      := cv_flg_n;
    END IF;
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END proc_set_oif_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_oif_actions
   * Description      : �󒍏���OIF�p�ϐ��i�[(A-8)
   ***********************************************************************************/
  PROCEDURE proc_set_oif_actions(
    ov_errbuf          OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔 
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_oif_actions'; -- �v���O������
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
    gt_order_source_id_ac( gn_ac_idx )        :=  gv_order_source_id;                       -- �C���|�[�g�\�[�XID
    gt_orig_sys_document_ref_ac( gn_ac_idx )  :=  gt_edi_headers ( gn_idx ).order_connection_number;
                                                                                            -- �O���V�X�e���󒍖��הԍ�
    gt_operation_code_ac( gn_ac_idx )         :=  cv_book_order;                            -- �I�y���[�V�����R�[�h
    
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END proc_set_oif_actions;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_edi_headers
   * Description      : EDI�w�b�_���e�[�u���X�V(A-9)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_headers(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_headers'; -- �v���O������
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
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    ln_upd_cnt NUMBER;
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
    --EDI�w�b�_���e�[�u���X�V����
    BEGIN
      FORALL ln_upd_cnt IN 1..gn_target_cnt
        UPDATE  xxcos_edi_headers  xeh
        SET     xeh.order_forward_flag       =  cv_order_forward_flag_y,           -- �󒍘A�g�σt���O�uY�v
                xeh.last_updated_by          =  cn_last_updated_by,                -- �ŏI�X�V��
                xeh.last_update_date         =  cd_last_update_date,               -- �ŏI�X�V��
                xeh.last_update_login        =  cn_last_update_login,              -- �ŏI�X�V۸޲�
                xeh.request_id               =  cn_request_id,                     -- �v��ID
                xeh.program_application_id   =  cn_program_application_id,         -- �ݶ��ĥ��۸��ѥ���ع����ID
                xeh.program_id               =  cn_program_id,                     -- �ݶ��ĥ��۸���ID
                xeh.program_update_date      =  cd_program_update_date             -- ��۸��эX�V��
        WHERE   xeh.edi_header_info_id       =  gt_edi_header_info_id ( ln_upd_cnt );
--
    EXCEPTION
      WHEN OTHERS THEN
        RAISE upd_edi_headers_expt;
--
    END;
--
  EXCEPTION
--
    -- �f�[�^�X�V�G���[
    WHEN upd_edi_headers_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_update
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => gv_edi_header_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_upd_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_oif_headers
   * Description      : �󒍃w�b�_OIF�e�[�u���o�^(A-10)
   ***********************************************************************************/
  PROCEDURE proc_ins_oif_headers(
    on_normal_cnt OUT NOCOPY NUMBER,         --   ���팏��
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_oif_headers'; -- �v���O������
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
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
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
    -- OUT�p�����[�^������
    on_normal_cnt := 0;
--
    -- �󒍃w�b�_OIF�e�[�u���֓o�^
    BEGIN
      -- �o���N�C���T�[�g����
      FORALL gn_idx IN 1 .. gt_order_source_id.COUNT 
       INSERT INTO oe_headers_iface_all(
           order_source_id                                              -- �C���|�[�g�\�[�XID
         , orig_sys_document_ref                                        -- �O���V�X�e���󒍔ԍ�
         , customer_po_number                                           -- �ڋq�����ԍ�
         , ordered_date                                                 -- �󒍓�
         , order_type_id                                                -- �󒍃^�C�vID
         , org_id                                                       -- �c�ƒP��ID
         , price_list_id                                                -- ���i�\ID
         , customer_number                                              -- �ڋq�R�[�h
         , request_date                                                 -- �v����
         , context                                                      -- �R���e�L�X�g
         , attribute12                                                  -- �����p���_�R�[�h(DFF12)
         , created_by                                                   -- �쐬��
         , creation_date                                                -- �쐬��
         , last_updated_by                                              -- �ŏI�X�V��
         , last_update_date                                             -- �ŏI�X�V��
         , last_update_login                                            -- �ŏI�X�V۸޲�
         , request_id                                                   -- �v��ID
         , program_application_id                                       -- �ݶ��ĥ��۸��ѥ���ع����ID
         , program_id                                                   -- �ݶ��ĥ��۸���ID
         , program_update_date                                          -- ��۸��эX�V��
       )
       VALUES(
           gt_order_source_id ( gn_idx )                                -- �C���|�[�g�\�[�XID
         , gt_orig_sys_document_ref ( gn_idx )                          -- �O���V�X�e���󒍔ԍ�
         , gt_customer_po_number_h ( gn_idx )                           -- �ڋq�����ԍ�
         , gt_ordered_date ( gn_idx )                                   -- �󒍓�
         , gt_order_type_id ( gn_idx )                                  -- �󒍃^�C�vID
         , gt_org_id ( gn_idx )                                         -- �c�ƒP��ID
         , gt_price_list_id ( gn_idx )                                  -- ���i�\ID
         , gt_customer_number ( gn_idx )                                -- �ڋq�R�[�h
         , gt_request_date ( gn_idx )                                   -- �v����
         , gt_name_h ( gn_idx )                                         -- �R���e�L�X�g
         , gt_sale_base_code ( gn_idx )                                 -- �����p���_�R�[�h(DFF12)
         , cn_created_by                                                -- �쐬��
         , cd_creation_date                                             -- �쐬��
         , cn_last_updated_by                                           -- �ŏI�X�V��
         , cd_last_update_date                                          -- �ŏI�X�V��
         , cn_last_update_login                                         -- �ŏI�X�V۸޲�
         , NULL                                                         -- �v��ID
         , cn_program_application_id                                    -- �ݶ��ĥ��۸��ѥ���ع����ID
         , cn_program_id                                                -- �ݶ��ĥ��۸���ID
         , cd_program_update_date                                       -- ��۸��эX�V��
       );
--
      EXCEPTION
        -- �f�[�^�o�^�G���[
        WHEN OTHERS THEN
          RAISE ins_data_expt;
--
    END;
--
    -- �o�^������ݒ�
    on_normal_cnt := gt_order_source_id.COUNT;
--
  EXCEPTION
--
    -- �f�[�^�o�^�G���[
    WHEN ins_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_insert
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => cv_oif_headers_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_ins_oif_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_oif_lines
   * Description      : �󒍖���OIF�e�[�u���o�^(A-11)
   ***********************************************************************************/
  PROCEDURE proc_ins_oif_lines(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_oif_lines'; -- �v���O������
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
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    ln_ins_idx NUMBER;
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
    -- �󒍖���OIF�e�[�u���֓o�^
    BEGIN
      -- �o���N�C���T�[�g����
      FORALL ln_ins_idx IN 1 ..gn_l_idx_all 
        INSERT INTO oe_lines_iface_all(
            order_source_id                                               -- �C���|�[�g�\�[�XID
          , inventory_item                                                -- �󒍕i��
          , ordered_quantity                                              -- �󒍐���
          , order_quantity_uom                                            -- �󒍒P��
          , unit_selling_price                                            -- �̔��P��
          , unit_list_price                                               -- �艿
          , calculate_price_flag                                          -- ���i�v�Z�t���O
          , request_date                                                  -- �v����
          , schedule_ship_date                                            -- �\��o�ד�
          , customer_po_number                                            -- �ڋq�����ԍ�
          , customer_line_number                                          -- �ڋq�������הԍ�
          , orig_sys_document_ref                                         -- �O���V�X�e���󒍔ԍ�
          , orig_sys_line_ref                                             -- �O���V�X�e���󒍖��הԍ�
          , line_type_id                                                  -- ���׃^�C�vID
          , attribute5                                                    -- ����敪
          , context                                                       -- �R���e�L�X�g
          , created_by                                                    -- �쐬��
          , creation_date                                                 -- �쐬��
          , last_updated_by                                               -- �ŏI�X�V��
          , last_update_date                                              -- �ŏI�X�V��
          , last_update_login                                             -- �ŏI�X�V۸޲�
          , request_id                                                    -- �v��ID
          , program_application_id                                        -- �ݶ��ĥ��۸��ѥ���ع����ID
          , program_id                                                    -- �ݶ��ĥ��۸���ID
          , program_update_date                                           -- ��۸��эX�V��
        )
        VALUES(
            gt_order_source_id_l( ln_ins_idx )                            -- �C���|�[�g�\�[�XID
          , gt_inventory_item( ln_ins_idx )                               -- �󒍕i��
          , gt_ordered_quantity( ln_ins_idx )                             -- �󒍐���
          , gt_order_quantity_uom( ln_ins_idx )                           -- �󒍒P��
          , gt_unit_selling_price( ln_ins_idx )                           -- �̔��P��
          , gt_unit_selling_price( ln_ins_idx )                           -- �艿
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
--          , cv_flg_n                                                      -- ���i�v�Z�t���O
          , gt_calculate_price_flag( ln_ins_idx )                         -- ���i�v�Z�t���O
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
          , gt_request_date_l( ln_ins_idx )                               -- �v����
          , gt_schedule_ship_date( ln_ins_idx )                           -- �\��o�ד�
          , gt_customer_po_number_l( ln_ins_idx )                         -- �ڋq�����ԍ�
          , gt_customer_line_number( ln_ins_idx )                         -- �ڋq�������הԍ�
          , gt_orig_sys_document_ref_l( ln_ins_idx )                      -- �O���V�X�e���󒍔ԍ�
          , gt_orig_sys_line_ref( ln_ins_idx )                            -- �O���V�X�e���󒍖��הԍ�
          , gt_line_type_id( ln_ins_idx )                                 -- ���׃^�C�vID
          , gt_attribute5( ln_ins_idx )                                   -- ����敪
          , gt_name_l( gn_l_idx_all )                                     -- �R���e�L�X�g
          , cn_created_by                                                 -- �쐬��
          , cd_creation_date                                              -- �쐬��
          , cn_last_updated_by                                            -- �ŏI�X�V��
          , cd_last_update_date                                           -- �ŏI�X�V��
          , cn_last_update_login                                          -- �ŏI�X�V۸޲�
          , NULL                                                          -- �v��ID
          , cn_program_application_id                                     -- �ݶ��ĥ��۸��ѥ���ع����ID
          , cn_program_id                                                 -- �ݶ��ĥ��۸���ID
          , cd_program_update_date                                        -- ��۸��эX�V��
        );
--
    EXCEPTION
      -- �f�[�^�o�^�G���[
      WHEN OTHERS THEN
        RAISE ins_data_expt;
--
    END;
--
  EXCEPTION
--
    WHEN ins_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_insert
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => cv_oif_lines_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_ins_oif_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_oif_actions
   * Description      : �󒍏���OIF�e�[�u���o�^(A-12)
   ***********************************************************************************/
  PROCEDURE proc_ins_oif_actions(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_oif_actions'; -- �v���O������
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
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
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
    -- �󒍏���OIF�e�[�u���֓o�^
    BEGIN
      -- �o���N�C���T�[�g����
      FORALL gn_ac_idx IN 1 .. gt_order_source_id_ac.COUNT 
        INSERT INTO oe_actions_iface_all(
            order_source_id                                             -- �C���|�[�g�\�[�XID
          , orig_sys_document_ref                                       -- �O���V�X�e���󒍔ԍ�
          , operation_code                                              -- �I�y���[�V�����R�[�h
        )
        VALUES(
            gt_order_source_id_ac( gn_ac_idx )                          -- �C���|�[�g�\�[�XID
          , gt_orig_sys_document_ref_ac( gn_ac_idx )                    -- �O���V�X�e���󒍔ԍ�
          , gt_operation_code_ac( gn_ac_idx )                           -- �I�y���[�V�����R�[�h
        );
--
    EXCEPTION
      -- �f�[�^�o�^�G���[
      WHEN OTHERS THEN
        RAISE ins_data_expt;
--
    END;
--
  EXCEPTION
--
    WHEN ins_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_insert
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => cv_oif_actions_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_ins_oif_actions;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_ins_normal_cnt         NUMBER;             -- ���팏���i�o�^�p�j
    ln_upd_normal_cnt         NUMBER;             -- ���팏���i�X�V�p�j
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt     := 0;
    gn_l_target_cnt   := 0;
    gn_normal_cnt     := 0;
    gn_warn_cnt       := 0;
    gn_error_cnt      := 0;
    gv_dummy_item_flg := 'Y';
    gn_idx            := 0;
    gn_l_idx          := 0;
    gn_ac_idx         := 0;
    gn_l_idx_all      := 0;
--
    -- ============================================
    -- ��������(A-1)
    -- ============================================
    proc_init(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_retcode := lv_retcode;
      -- �G���[����
      gn_error_cnt := gn_error_cnt + 1;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI�w�b�_���e�[�u���f�[�^���o(A-2)
    -- ============================================
    proc_get_edi_headers(
      on_target_cnt => gn_target_cnt,
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ���o�����f�[�^��0���������ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    <<edi_headers_loop>>
    FOR ln_cnt IN 1..gn_target_cnt LOOP
--
      -- ============================================
      -- �f�[�^�Ó����`�F�b�N1(A-3)
      -- ============================================
--
      -- �O���[�o���ϐ��֊i�[
      gn_idx := ln_cnt;
--
      proc_data_validate_1(
        ov_errbuf   => lv_errbuf,
        ov_retcode  => lv_retcode,
        ov_errmsg   => lv_errmsg
      );
--
      -- �x���̏ꍇ
      IF ( lv_retcode = cv_status_warn ) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = cv_status_error ) THEN
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
        -- �G���[����
        gn_error_cnt := gn_error_cnt + 1;
        RETURN;
      END IF;
--
      -- ============================================
      --�󒍃w�b�_OIF�p�ϐ��i�[(A-4)
      -- ============================================
      proc_set_oif_headers(
        ov_errbuf      => lv_errbuf,
        ov_retcode     => lv_retcode,
        ov_errmsg      => lv_errmsg
      );
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = cv_status_error ) THEN
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
        -- �G���[����
        gn_error_cnt := gn_error_cnt + 1;
        RETURN;
      END IF;
--
      -- ============================================
      --EDI���׏��e�[�u���f�[�^���o(A-5)
      -- ============================================
      proc_get_edi_lines(
        on_l_target_cnt  => gn_l_target_cnt,
        ov_errbuf      => lv_errbuf,
        ov_retcode     => lv_retcode,
        ov_errmsg      => lv_errmsg
        );
--
      -- �G���[�̏ꍇ
      IF ( lv_retcode = cv_status_error ) THEN
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
        -- �G���[����
        gn_error_cnt := gn_error_cnt + 1;
        RETURN;
      END IF;
--
      -- �ϐ��̏�����
      gv_dummy_item_flg  := 'Y';
--
      <<edi_lines_loop>>
      FOR ln_l_cnt IN 1..gn_l_target_cnt LOOP
--
        -- ============================================
        --�f�[�^�Ó����`�F�b�N2(A-6)
        -- ============================================
--
        -- �O���[�o���ϐ��֊i�[
        gn_l_idx := ln_l_cnt;
        gn_l_idx_all := gn_l_idx_all + 1;
--
        proc_data_validate_2(
          ov_errbuf   => lv_errbuf,
          ov_retcode  => lv_retcode,
          ov_errmsg   => lv_errmsg
        );
--
        -- �x���̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
        -- ============================================
        -- �󒍖���OIF�p�ϐ��i�[(A-7)
        -- ============================================
        proc_set_oif_lines(
          ov_errbuf   => lv_errbuf,
          ov_retcode  => lv_retcode,
          ov_errmsg   => lv_errmsg
        );
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
      END LOOP edi_lines_loop;
--
      -- �_�~�[�i�ڃR�[�h���ݒ肳��Ă��Ȃ��ꍇ
      IF ( gv_dummy_item_flg != cv_dummy_item_flg_n ) THEN
--
        -- ============================================
        -- �󒍏���OIF�p�ϐ��i�[(A-8)
        -- ============================================
--
        -- �O���[�o���ϐ��֊i�[
        gn_ac_idx := gn_ac_idx + 1;
--
        proc_set_oif_actions(
          ov_errbuf   => lv_errbuf,
          ov_retcode  => lv_retcode,
          ov_errmsg   => lv_errmsg
        );
--
        -- �G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- �G���[����
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
      END IF; 
--
    END LOOP edi_headers_loop;
--
    -- ============================================
    -- EDI�w�b�_���e�[�u���X�V(A-9)
    -- ============================================
    proc_upd_edi_headers(
      ov_errbuf      => lv_errbuf,
      ov_retcode     => lv_retcode,
      ov_errmsg      => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      -- �G���[����
      gn_error_cnt := gn_error_cnt + 1;
      RETURN;
    END IF;
--
    -- ============================================
    -- �󒍃w�b�_OIF�e�[�u���o�^(A-10)
    -- ============================================
    proc_ins_oif_headers(
      on_normal_cnt  => ln_ins_normal_cnt,
      ov_errbuf      => lv_errbuf,
      ov_retcode     => lv_retcode,
      ov_errmsg      => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ���팏����ݒ�
    gn_normal_cnt := ln_ins_normal_cnt;
--
    -- ============================================
    -- �󒍖���OIF�e�[�u���o�^(A-11)
    -- ============================================
    proc_ins_oif_lines(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- �󒍏���OIF�e�[�u���o�^(A-12)
    -- ============================================
    proc_ins_oif_actions(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- �G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,              --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2               --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- �x���������b�Z�[�W�i���i�R�[�h�G���[�j
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
--
    -- �x��������1���ȏ゠��ꍇ�A�I���X�e�[�^�X���x���ɐݒ�
    IF ( gn_warn_cnt != 0 ) THEN
      lv_retcode  := cv_status_warn;
    END IF;
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
END XXCOS010A02C;
/
