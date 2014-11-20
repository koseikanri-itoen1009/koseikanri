CREATE OR REPLACE PACKAGE BODY APPS.XXCOS_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcos_common2_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_COS_���ʊ֐�
 * Version                : 1.5
 *
 * Program List
 *  --------------------          ---- ----- --------------------------------------------------
 *   Name                         Type  Ret   Description
 *  --------------------          ---- ----- --------------------------------------------------
 *  get_unit_price                  F  NUMBER   �P���擾�֐�
 *  conv_ebs_cust_code              P           �ڋq�R�[�h�ϊ��iEDI��EBS)
 *  conv_edi_cust_code              P           �ڋq�R�[�h�ϊ��iEBS��EDI)
 *  conv_ebs_item_code              P           �i�ڃR�[�h�ϊ��iEDI��EBS)
 *  conv_edi_item_code              P           �i�ڃR�[�h�ϊ��iEBS��EDI)
 *  get_layout_info                 P           ���C�A�E�g��`���擾
 *  makeup_data_record              P           �f�[�^���R�[�h�ҏW
 *  convert_quantity                P           EDI���[�������ʊ��Z�֐�
 *  get_deliv_slip_flag             F           �[�i�����s�t���O�擾�֐�
 *  get_deliv_slip_flag_area        F           �[�i�����s�t���O�S�̎擾�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/27    1.0  SCS              �V�K�쐬
 *  2009/02/24    1.1  H.Fujimoto       �����s�No.129
 *  2009/03/11    1.2  K.Kumamoto       I_E_048(�S�ݓX�����)�P�̃e�X�g��Q�Ή� (SPEC�C��)
 *  2009/03/31    1.3  T.Kitajima       [T1_0113]makeup_data_record��NUMBER,DATE�ҏW�ύX
 *  2009/04/16    1.4  T.Kitajima       [T1_0543]conv_edi_item_code �P�[�XJAN�AJAN�R�[�hNULL�Ή�
 *  2009/06/23    1.5  K.Kiriu          [T1_1359]EDI���[�������ʊ��Z�֐��̒ǉ�
 *
 *****************************************************************************************/
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
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  gv_msg_part VARCHAR2(100) := ' : ';
  gv_msg_cont CONSTANT VARCHAR2(3) := '.';
--
  gv_cnst_period         CONSTANT VARCHAR2(1)   := '.';                 -- �s���I�h
  gv_cnst_err_msg_space  CONSTANT VARCHAR2(6)   := '      ';            -- �X�y�[�X
  gv_pkg_name                                 CONSTANT VARCHAR2(100) := 'XXCOS_COMMON_PKG';  -- �p�b�P�[�W��
  gv_cust_code_no10                           CONSTANT VARCHAR2(100) := '10'; --�ڋq�敪�i�ڋq�j
  gv_cust_code_no18                           CONSTANT VARCHAR2(100) := '18'; --�ڋq�敪�i�`�F�[���X�j
  gv_edi_district_code_no1                    CONSTANT VARCHAR2(100) := '1';  --EDI�A�g�i�ځi�ڋq���i�R�[�h�j
  gv_edi_district_code_no2                    CONSTANT VARCHAR2(100) := '2';  --EDI�A�g�i�ځiJAN�R�[�h�j
  --
  gv_param_err                                CONSTANT VARCHAR2(2) := '01';   --���̓p�����[�^�G���[
  gv_no_data_found_err                        CONSTANT VARCHAR2(2) := '02';   --�Ώۃf�[�^�Ȃ��G���[
  --
  gv_char_n                                   CONSTANT VARCHAR2(1) := 'N';
  gv_char_double_cort                         CONSTANT VARCHAR2(1) := chr( 34 ); --�_�u���R�[�e�[�V����
  gv_char_comma                               CONSTANT VARCHAR2(1) := chr( 44 ); --�J���}
  gv_char_period                              CONSTANT VARCHAR2(1) := chr( 46 ); --�s���I�h
  gv_char_space                               CONSTANT VARCHAR2(1) := ' ';       --��
  gv_retcode_ok                               CONSTANT VARCHAR2(1) := ' ';    --�߂�l����
  gv_retcode_ng                               CONSTANT VARCHAR2(1) := 'E';    --�߂�l�ُ�
  --
  cv_number_null                              CONSTANT VARCHAR2(1) := '0';       --���lNULL
  cv_date_null                                CONSTANT VARCHAR2(8) := '00000000';--����NULL
--
  --���R�[�h���ʎq
  gv_record_kb_d                              CONSTANT VARCHAR2(1) := 'D';    --�f�[�^
--
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name                    CONSTANT  fnd_application.application_short_name%TYPE
                                              := 'XXCOS';                         -- �̕��Z�k�A�v����
  --�G���[���b�Z�[�W�o�̓G���A
  gv_application                              CONSTANT VARCHAR2(5)  := 'XXCOS';  --�A�v���P�[�V������
  gv_app_xxcos1_00019                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00019';
  gv_app_xxcos1_00040                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00040';
  gv_app_xxcos1_00071                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00071';
  gv_app_xxcos1_00072                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00072';
  gv_app_xxcos1_00073                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00073';
  gv_app_xxcos1_00102                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00102';
  gv_app_xxcos1_00103                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00103';
  --
  ct_msg_customer_id                          CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13583';              -- �ڋq�}�X�^�����G���[
  ct_msg_cust_item_code                       CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13585';              -- �ڋq�i�ڌ����G���[
  ct_msg_jan_code                             CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13586';              -- JAN�R�[�h�����G���[
  ct_msg_in_uom_code                          CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13587';              -- ���̓p�����[�^�P�ʃR�[�h�s��
--****************************** 2009/04/16 1.4 T.Kitajima ADD START ******************************--
  ct_msg_jan_null_err                         CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13590';              -- JAN�R�[�hNULL�G���[
  ct_msg_case_jan_null_err                    CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13591';              -- �P�[�XJAN�R�[�hNULL�G���[
--****************************** 2009/04/16 1.4 T.Kitajima ADD  ENd  ******************************--
/* 2009/06/15 Ver1.5 Add Start */
  ct_msg_bad_calculation_err                  CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13592';              -- �o�א��ʁA���i���ʁA�v�Z�s�G���[
/* 2009/06/15 Ver1.5 Add End   */
 -- �g�[�N��
  gv_token_name_layout                        CONSTANT VARCHAR2(6)  := 'LAYOUT';
  gv_token_name_in_param                      CONSTANT VARCHAR2(8)  := 'IN_PARAM';
  --
  cv_tkn_edi_chain_code                       CONSTANT  VARCHAR2(100) := 'EDI_CHAIN_CODE';      -- EDI�`�F�[���X�R�[�h
  cv_tkn_edi_item_code_div                    CONSTANT  VARCHAR2(100) := 'EDI_ITEM_CODE_DIV';   -- EDI�A�g�i�ڃR�[�h�敪
  cv_tkn_uom_code                             CONSTANT  VARCHAR2(100) := 'UOM_CODE';            -- �P�ʃR�[�h
  cv_tkn_jan_code                             CONSTANT  VARCHAR2(100) := 'JAN_CODE';            -- JAN�R�[�h
--****************************** 2009/04/16 1.4 T.Kitajima ADD START ******************************--
  cv_tkn_item_code                            CONSTANT  VARCHAR2(100) := 'ITEM_CODE';           -- �i�ڃR�[�h
--****************************** 2009/04/16 1.4 T.Kitajima ADD  ENd  ******************************--
  --
  --�v���t�@�C��ID
  ct_prof_case_uom_code                       CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                                         := 'XXCOS1_CASE_UOM_CODE';          -- �P�[�X�P�ʃR�[�h

--
  -- ===============================
  -- ���ʗ�O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--
  /************************************************************************
   * Function Name   : get_unit_price
   * Description     : �P���擾�֐�
   ************************************************************************/
  FUNCTION get_unit_price(
     in_inventory_item_id      IN           NUMBER                           -- Disc�i��ID
    ,in_price_list_header_id   IN           NUMBER                           -- ���i�\�w�b�_ID
    ,iv_uom_code               IN           VARCHAR2                         -- �P�ʃR�[�h
  ) RETURN  NUMBER
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
    -- ���i�\�Œ�l
    cv_y                      CONSTANT   VARCHAR2(1)    :=  'Y';
    cv_pll                    CONSTANT   VARCHAR2(3)    :=  'PLL';
    cv_prl                    CONSTANT   VARCHAR2(3)    :=  'PRL';
    cv_line                   CONSTANT   VARCHAR2(4)    :=  'LINE';
    cv_c                      CONSTANT   VARCHAR2(1)    :=  'C';
    cv_unit_price             CONSTANT   VARCHAR2(10)   :=  'UNIT_PRICE';
    cv_item                   CONSTANT   VARCHAR2(4)    :=  'ITEM';
    cv_modlist                CONSTANT   VARCHAR2(7)    :=  'MODLIST';
    cv_order                  CONSTANT   VARCHAR2(5)    :=  'ORDER';
    -- ���i����
    cv_product_attribute1     CONSTANT   VARCHAR2(18)   :=  'PRICING_ATTRIBUTE1';  -- �i�ڔԍ�
    cv_product_attribute3     CONSTANT   VARCHAR2(18)   :=  'PRICING_ATTRIBUTE3';  -- AllItems
    -- QUALIFIER_ATTRIBUTE
    cv_qf_attribute4          CONSTANT   VARCHAR2(21)   :=  'QUALIFIER_ATTRIBUTE4';
    cv_qf_attribute11         CONSTANT   VARCHAR2(22)   :=  'QUALIFIER_ATTRIBUTE11';
    -- �Ɩ����t
    cd_process_date           CONSTANT   DATE           :=  xxccp_common_pkg2.get_process_date;
--
    -- *** ���[�J���ϐ� ***
    ln_list_header_id                    qp_list_headers_b.list_header_id%TYPE;        -- ���i�\�w�b�_ID
    ln_unit_price                        qp_list_lines.operand%TYPE;                   -- �P��
    ln_product_attribute                 qp_pricing_attributes.product_attribute%TYPE; -- ���i����
    ln_inventory_item_id                 mtl_system_items_b.inventory_item_id%TYPE;    -- Disc�i��ID
    lv_uom_code                          mtl_system_items_b.primary_uom_code%TYPE;     -- �P�ʃR�[�h
    --
    ln_price_list_cnt                    NUMBER DEFAULT 0;                             -- ��񉿊i�\����
    --
    ln_check_flg                         VARCHAR2(1);                                  -- �����t���O
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ��񉿊i�\
    CURSOR sec_price_list_cur( ln_arg_inventory_item_id NUMBER
                              ,ln_arg_list_header_id    NUMBER
                              ,lv_arg_uom_code          VARCHAR2)
    IS
        SELECT
           qll.operand           unit_price     -- �P��
        FROM
           qp_list_headers_b     qphb           -- ���i�\�w�b�_
          ,qp_qualifiers         qpqr           -- �N�I���t�B�A
          ,qp_list_lines         qll            -- ���i�\����
          ,qp_pricing_attributes qpa            -- ���i�\�ڍ�
        WHERE
               qpqr.qualifier_attr_value      =  TO_CHAR( ln_arg_list_header_id )
          AND  TO_CHAR( qphb.list_header_id ) <> qpqr.qualifier_attr_value
          AND  qphb.list_header_id            =  qpqr.list_header_id
          AND  ((( qphb.start_date_active     IS NOT NULL )
            AND  ( qphb.start_date_active     <= cd_process_date  ))
              OR ( qphb.start_date_active     IS NULL     ))
          AND  ((( qphb.end_date_active       IS NOT NULL )
            AND  ( qphb.end_date_active       >= cd_process_date  ))
              OR ( qphb.end_date_active       IS NULL     ))
          AND  qphb.list_header_id            =  qll.list_header_id
          AND  ((( qll.start_date_active      IS NOT NULL )
            AND  ( qll.start_date_active      <= cd_process_date  ))
              OR ( qll.start_date_active      IS NULL     ))
          AND  ((( qll.end_date_active        IS NOT NULL )
            AND  ( qll.end_date_active        >= cd_process_date  ))
              OR ( qll.end_date_active        IS NULL     ))
          AND  qll.list_line_id               =  qpa.list_line_id
          AND  qll.list_line_type_code        =  cv_pll
          AND  qll.modifier_level_code        =  cv_line
          AND  qpa.product_attribute_datatype =  cv_c
          AND  qll.arithmetic_operator        =  cv_unit_price
          AND  qpa.product_attribute_context  =  cv_item
          AND  qpa.product_uom_code           =  lv_arg_uom_code
          AND  qpa.product_attr_value         =  decode ( qpa.product_attribute
                                                         ,cv_product_attribute1
                                                         ,to_char( ln_arg_inventory_item_id )
                                                         ,qpa.product_attr_value )
          AND  qphb.list_type_code            =  cv_prl
          AND  qpqr.qualifier_rule_id         IS NULL
          AND ( ( qpqr.qualifier_context      =  cv_modlist
              AND qpqr.qualifier_attribute    =  cv_qf_attribute4)
            OR ( qpqr.qualifier_context       =  cv_order
              AND qpqr.qualifier_attribute    =  cv_qf_attribute11) )
        ORDER BY
           qpqr.qualifier_precedence
          ,qll.product_precedence
        ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ================
    -- ���[�U�[��`��O
    -- ================
    price_list_err_expt                       EXCEPTION;                 --�����G���[
--
  BEGIN
  --
    --���̓p�����[�^�`�F�b�N
    IF (( in_inventory_item_id    IS NULL )
      OR
        ( in_price_list_header_id IS NULL )
      OR
        ( iv_uom_code             IS NULL ))
    THEN
      RETURN -1;
    ELSE
      ln_inventory_item_id  := in_inventory_item_id;
      ln_list_header_id     := in_price_list_header_id;
      lv_uom_code           := iv_uom_code;
    END IF;
    --
    --���i�\�̌����i��ꉿ�i�\�j �D��x�̈�ԍ������̂P����
    BEGIN
      SELECT  up.unit_price           unit_price     -- �P��
      INTO    ln_unit_price
      FROM (
        SELECT  qll.operand           unit_price     -- �P��

        FROM    qp_list_headers_b     qlhb           -- ���i�\�w�b�_
               ,qp_list_lines         qll            -- ���i�\����
               ,qp_pricing_attributes qpa            -- ���i�\�ڍ�
        WHERE   qlhb.list_header_id            = ln_list_header_id
          AND   qlhb.active_flag               = cv_y
          AND  ((( qlhb.start_date_active     IS NOT NULL )
            AND  ( qlhb.start_date_active     <= cd_process_date  ))
              OR ( qlhb.start_date_active     IS NULL     ))
          AND  ((( qlhb.end_date_active       IS NOT NULL )
            AND  ( qlhb.end_date_active       >= cd_process_date  ))
              OR ( qlhb.end_date_active       IS NULL     ))
          AND   qll.list_header_id             = qlhb.list_header_id
          AND  ((( qll.start_date_active      IS NOT NULL )
            AND  ( qll.start_date_active      <= cd_process_date  ))
              OR ( qll.start_date_active      IS NULL     ))
          AND  ((( qll.end_date_active        IS NOT NULL )
            AND  ( qll.end_date_active        >= cd_process_date  ))
              OR ( qll.end_date_active        IS NULL     ))
          AND   qll.list_line_id               = qpa.list_line_id
          AND   qll.list_line_type_code        = cv_pll
          AND   qll.modifier_level_code        = cv_line
          AND   qpa.product_attribute_datatype = cv_c
          AND   qll.arithmetic_operator        = cv_unit_price
          AND   qpa.product_attribute_context  = cv_item
          AND   qpa.product_attribute          IN ( cv_product_attribute1 ,cv_product_attribute3 )
          AND   qpa.product_uom_code           = lv_uom_code
          AND   qpa.product_attr_value         =  decode ( qpa.product_attribute
                                                          ,cv_product_attribute1
                                                          ,to_char( ln_inventory_item_id )
                                                          ,qpa.product_attr_value )
        ORDER BY
          qll.product_precedence
        ) up
      WHERE  ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_check_flg := 'Y';
      WHEN OTHERS THEN
        RETURN -2;
    END;
    -- DEBUG
--
    -- ������Ȃ������ꍇ�́A
    IF ( ln_check_flg = 'Y' ) THEN
      -- DEBUG
--
      -- ���i�\�̌����i��񉿊i�\�j�D��x�̈�ԍ������̂P����
      --
      <<main_loop>>
      FOR sec_price_list_rec IN sec_price_list_cur( ln_inventory_item_id
                                                   ,ln_list_header_id
                                                   ,lv_uom_code         )
      LOOP
        ln_unit_price:=sec_price_list_rec.unit_price;
        ln_price_list_cnt := sec_price_list_cur%ROWCOUNT;
        --
        IF ( ln_price_list_cnt = 1 ) THEN
          EXIT main_loop;
        END IF;
      END LOOP main_loop;
      --
      IF ( ln_price_list_cnt = 0 ) THEN
        RETURN -3;
      ELSE
        RETURN ln_unit_price;
      END IF;
    ELSE
      RETURN ln_unit_price;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_unit_price;
--
--
--
  /**********************************************************************************
   * Procedure Name   : conv_ebs_cust_code
   * Description      : �ڋq�R�[�h�ϊ��iEDI��EBS)
   ***********************************************************************************/
  PROCEDURE conv_ebs_cust_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDI�`�F�[���X�R�[�h
              ,iv_store_code                       IN  VARCHAR2 DEFAULT NULL  --�X�R�[�h
              ,ov_account_number                   OUT NOCOPY VARCHAR2        --�ڋq�R�[�h
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[���b�Z�[�W              #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���R�[�h                #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W  #�Œ�#
              )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
                                                                              --�v���O����
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'conv_ebs_cust_code';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --���b�Z�[�W�G���A
   -- ================
    -- ���[�U�[��`��O
    -- ================
    iv_param_expt                                      EXCEPTION;             --�����G���[
    --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
  --
--
  BEGIN
--
    --�v���O�������ݒ�
    --�o�͈���������
    ov_retcode  := xxccp_common_pkg.set_status_normal;
    --���͈����`�F�b�N<EDI�`�F�[���X�R�[�h:�X�R�[�h>
    IF   ( iv_edi_chain_code IS NULL )
      OR ( iv_store_code     IS NULL )
    THEN
      lv_message1 := gv_param_err;
      RAISE iv_param_expt;
    END IF;
    --
    -- EDI�`�F�[���X�R�[�h�ƓX�܃R�[�h����ڋq�R�[�h������
    BEGIN
      SELECT
        hca.account_number                                                      --�ڋq�R�[�h
      INTO
        ov_account_number
      FROM
        HZ_CUST_ACCOUNTS hca,                                                   --�ڋq�}�X�^
        XXCMM_CUST_ACCOUNTS xca                                                 --�ڋq�ǉ����
      WHERE hca.cust_account_id     = xca.customer_id                           --�ڋq�ڋqID
        AND hca.customer_class_code = gv_cust_code_no10                         --�ڋq�敪
        AND xca.chain_store_code    = iv_edi_chain_code                         --EDI�`�F�[���X�R�[�h
        AND xca.store_code          = iv_store_code                             --�X�܃R�[�h
      ;
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        lv_message1 := gv_no_data_found_err;
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;
      WHEN NO_DATA_FOUND THEN
        lv_message1 := gv_no_data_found_err;
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
    -- *** �����G���[ ***
    WHEN iv_param_expt  THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt  THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END conv_ebs_cust_code;
--
--
  /**********************************************************************************
   * Procedure Name   : conv_edi_item_code
   * Description      : �i�ڃR�[�h�ϊ��iEBS��EDI)
   ***********************************************************************************/
  --�i�ڃR�[�h�ϊ��iEBS��EDI)
  PROCEDURE conv_edi_item_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDI�`�F�[���X�R�[�h
              ,iv_item_code                        IN  VARCHAR2 DEFAULT NULL  --�i�ڃR�[�h
              ,iv_organization_id                  IN  VARCHAR2 DEFAULT NULL  --�݌ɑg�DID
              ,iv_uom_code                         IN  VARCHAR2 DEFAULT NULL  --�P�ʃR�[�h
              ,ov_product_code2                    OUT NOCOPY VARCHAR2        --���i�R�[�h�Q
              ,ov_jan_code                         OUT NOCOPY VARCHAR2        --JAN�R�[�h
              ,ov_case_jan_code                    OUT NOCOPY VARCHAR2        --�P�[�XJAN�R�[�h
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[���b�Z�[�W              #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���R�[�h                #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W  #�Œ�#
              )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'conv_ebs_item_code';  --�v���O����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --���b�Z�[�W�G���A
                                                                              --����pEDI�A�g�i�ڃR�[�h�敪
    ln_customer_id                                     xxcmm_cust_accounts.customer_id%TYPE;
                                                                              --����p�ڋqID
    lv_edi_item_code_div                               xxcmm_cust_accounts.edi_item_code_div%TYPE;
    --
    lv_case_uom_code                                   mtl_units_of_measure_tl.uom_code%TYPE; -- �P�[�X�P�ʃR�[�h
    --
    lv_uom_code                                        mtl_units_of_measure_tl.uom_code%TYPE; -- �P�ʃR�[�h
    -- ================
    -- ���[�U�[��`��O
    -- ================
    lv_err_expt                                        EXCEPTION;             --�}�X�^�f�[�^����
    iv_param_expt                                      EXCEPTION;             --�����G���[
    --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
  --
--
  BEGIN
--
    --�o�͈���������
    ov_retcode  := xxccp_common_pkg.set_status_normal;
--
    --���͈����`�F�b�N<EDI�`�F�[���X�R�[�h:���i�R�[�h�Q:�݌ɑg�DID>
    IF  (( iv_edi_chain_code   IS NULL )
      OR ( iv_item_code        IS NULL )
      OR ( iv_organization_id  IS NULL ))
    THEN
      lv_message1 := gv_param_err;
      RAISE iv_param_expt;
    END IF;
    --
    -- EDI�A�g�i�ڃR�[�h�敪�̎擾
    BEGIN
      SELECT
        xca.edi_item_code_div,                                                --EDI�A�g�i�ڃR�[�h�敪
        xca.customer_id                                                       --�ڋqID
      INTO
        lv_edi_item_code_div,
        ln_customer_id
      FROM
        hz_cust_accounts hca,                                                 --�ڋq�}�X�^
        xxcmm_cust_accounts xca                                               --�ڋq�ǉ����
      WHERE hca.cust_account_id     = xca.customer_id                         --�ڋq�ڋqID
        AND hca.customer_class_code = gv_cust_code_no18                       --�ڋq�敪
        AND xca.edi_chain_code      = iv_edi_chain_code                       --EDI�`�F�[���X�R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Ώۃf�[�^�Ȃ��G���[(�ڋq)
        lv_message1 := xxccp_common_pkg.get_msg(
                         iv_application        => ct_xxcos_appl_short_name,
                         iv_name               => ct_msg_customer_id,
                         iv_token_name1        => cv_tkn_edi_chain_code,
                         iv_token_value1       => iv_edi_chain_code
                       );
        RAISE lv_err_expt;
    END;
    --
    -- �ڋq�i�ڂ̏ꍇ
    CASE lv_edi_item_code_div
      WHEN gv_edi_district_code_no1 THEN
        BEGIN
          SELECT
            mci.customer_item_number                                            --�ڋq�R�[�h
          INTO
            ov_product_code2
          FROM
            mtl_customer_items       mci,                                       --�ڋq�i��
            mtl_customer_item_xrefs  mcix,                                      --�ڋq�i�ڑ��ݎQ��
            mtl_system_items_b       msib                                       --DISC�i��
          WHERE mci.customer_id          = ln_customer_id                       --�P�ʃR�[�h(�����P��)
            AND mci.attribute1           = NVL(iv_uom_code, mci.attribute1 )    --�ڋq�i��ID
            AND mci.customer_item_id     = mcix.customer_item_id                --�ڋq�i��ID
            AND msib.inventory_item_id   = mcix.inventory_item_id               --�i��ID
            AND msib.organization_id     = iv_organization_id                   --�g�DID
            AND msib.segment1            = iv_item_code                         --�i�ڃR�[�h
/* 2009/02/20 Ver1.1 Del Start */
--          AND msib.primary_uom_code    = NVL(iv_uom_code, mci.attribute1 )    --�P�ʃR�[�h(��1�P��)
/* 2009/02/20 Ver1.1 Del  End  */
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_cust_item_code,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code,
                             iv_token_name2        => cv_tkn_uom_code,
                             iv_token_value2       => iv_uom_code
                           );
            RAISE lv_err_expt;
        END;
      -- JAN�R�[�h�̏ꍇ
      WHEN gv_edi_district_code_no2 THEN
        -- CS�P�ʃR�[�h�̎擾
        lv_case_uom_code := FND_PROFILE.VALUE( ct_prof_case_uom_code );
        --
        -- JAN�R�[�h�̎擾
        BEGIN
          SELECT
            iimb.attribute21,                                                     --JAN�R�[�h
            xsib.case_jan_code,                                                   --�P�[�XJAN�R�[�h
            iimb.item_um
          INTO
            ov_jan_code,
            ov_case_jan_code,
            lv_uom_code
          FROM
            ic_item_mst_b iimb,                                                   --OPM�i��
            xxcmm_system_items_b xsib                                             --DISC�i�ڃA�h�I��
          WHERE iimb.item_no          = iv_item_code                              --�i�ڃR�[�h
            AND iimb.item_id          = xsib.item_id                              --�i��ID
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_jan_code,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code
                           );
            RAISE lv_err_expt;
        END;
        --
--****************************** 2009/04/16 1.4 T.Kitajima MOD START ******************************--
--        -- ���̓p�����[�^�u�P�ʃR�[�h�v�ɂ��A���i�R�[�h�Q�ɃZ�b�g����l��ς��܂�
--        IF ( iv_uom_code = lv_case_uom_code ) THEN
--          -- �P�ʁuCS�v�̏ꍇ
--          ov_product_code2 := ov_case_jan_code;
--        ELSIF ( lv_uom_code = lv_uom_code ) THEN
--          -- �P�ʂ��i�ڃ}�X�^�̒P�ʂƓ����ꍇ
--          ov_product_code2 := ov_jan_code;
--        ELSE
--          -- ��L�ȊO�̏ꍇ->�G���[
--          lv_message1 := xxccp_common_pkg.get_msg(
--                           iv_application        => ct_xxcos_appl_short_name,
--                           iv_name               => ct_msg_in_uom_code,
--                           iv_token_name1        => cv_tkn_edi_chain_code,
--                           iv_token_value1       => iv_edi_chain_code,
--                           iv_token_name2        => cv_tkn_jan_code,
--                           iv_token_value2       => ov_jan_code,
--                           iv_token_name3        => cv_tkn_uom_code,
--                           iv_token_value3       => iv_uom_code
--                         );
--          RAISE lv_err_expt;
--        END IF;
--
        -- ���̓p�����[�^�u�P�ʃR�[�h�v�ɂ��A���i�R�[�h�Q�ɃZ�b�g����l��ς��܂�
        IF ( iv_uom_code = lv_case_uom_code ) THEN
          -- �P�ʁuCS�v�̏ꍇ
          --�P�[�XJAN�R�[�h��NULL�̏ꍇ�G���[
          IF ( ov_case_jan_code IS NULL ) THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_case_jan_null_err,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code,
                             iv_token_name2        => cv_tkn_item_code,
                             iv_token_value2       => iv_item_code
                           );
            RAISE lv_err_expt;
          END IF;
          ov_product_code2 := ov_case_jan_code;
        ELSE 
          -- �P�ʂ��i�ڃ}�X�^�̒P�ʂƓ����ꍇ
          IF ( ov_jan_code IS NULL ) THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_jan_null_err,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code,
                             iv_token_name2        => cv_tkn_item_code,
                             iv_token_value2       => iv_item_code
                           );
            RAISE lv_err_expt;
          END IF;
          ov_product_code2 := ov_jan_code;
        END IF;
--****************************** 2009/04/16 1.4 T.Kitajima MOD  END  ******************************--
      ELSE
        -- EDI�A�g�i�ڃR�[�h�敪�̕s��
        lv_message1 := xxccp_common_pkg.get_msg(
                         iv_application        => ct_xxcos_appl_short_name,
                         iv_name               => ct_msg_customer_id,
                         iv_token_name1        => cv_tkn_edi_chain_code,
                         iv_token_value1       => iv_edi_chain_code,
                         iv_token_name2        => cv_tkn_edi_item_code_div,
                         iv_token_value2       => lv_edi_item_code_div
                       );
        RAISE lv_err_expt;
    END CASE;
--
  EXCEPTION
--
    -- *** �����G���[ ***
    WHEN iv_param_expt  THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** ���i�R�[�h�ϊ��G���[ ***
    WHEN lv_err_expt    THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END conv_edi_item_code;
--
--
  /**********************************************************************************
   * Procedure Name   : get_layout_info
   * Description      : ���C�A�E�g��`���擾
   ***********************************************************************************/
  --���C�A�E�g��`���擾
  PROCEDURE get_layout_info(
               iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --�t�@�C���`��
              ,iv_layout_class                     IN  VARCHAR2 DEFAULT NULL  --���C�A�E�g�敪
              ,ov_data_type_table                  OUT NOCOPY g_record_layout_ttype  --�f�[�^�^�\
              ,ov_csv_header                       OUT NOCOPY VARCHAR2        --CSV�w�b�_
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[���b�Z�[�W              #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���R�[�h                #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W  #�Œ�#
              )
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
                                                                              --�v���O����
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'get_layout_info';
    --���C�A�E�g�敪�Ή��\��`
    cv_layout_type_order                      CONSTANT VARCHAR2(100) := 'XXCOS1_OM_TAB_COLUMNS';
                                                                              --�󒍌n
    cv_layout_type_stock                      CONSTANT VARCHAR2(100) := 'XXCOS1_INV_TAB_COLUMNS';
                                                                              --�݌�
    --
    cv_token_file_type                        CONSTANT VARCHAR2(12) := 'iv_file_type';
    cv_token_layout_class                     CONSTANT VARCHAR2(15) := 'iv_layout_class';
    --
    cv_apl_name                               CONSTANT VARCHAR2(100) := 'XXCOS'; --�A�v���P�[�V������
    ct_rec_type                               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00159';        --���b�Z�[�W�p������.���R�[�h���ʎq
--add start 1/21
    ct_prf_if_data                            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';--XXCCP:�f�[�^���R�[�h���ʎq
--add end 1/21
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --���b�Z�[�W�G���A
    lv_prg_name                                        VARCHAR2(100);         --���b�Z�[�W�p�v���O�������ݒ�G���A
    lv_csv_header                                      VARCHAR2(32767);       --�w�b�_�ҏW�G���A
    lv_token                                           VARCHAR2(100);         --�g�[�N��������
    i                                                  NUMBER;                --�Y��
                                                                              --�^��`
    lv_look_up                                         fnd_lookup_values.lookup_type%type;
    lv_layout                                          VARCHAR2(100);         --���b�Z�[�W�ҏW�G���A
    lt_rec_type                       fnd_new_messages.message_text%TYPE;     --���b�Z�[�W�o�̓G���A�F���R�[�h���ʎq
    -- PL/SQL�\�^
    l_data_ttype g_record_layout_ttype;
--
    --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
  --
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR
      cur_xlvv
    IS
    SELECT
      xlvv.lookup_code,                                                       --�R�[�h
      xlvv.meaning,                                                           --���e
      xlvv.description,                                                       --�E�v
      xlvv.attribute1,                                                        --DEF1
      xlvv.attribute2                                                         --DEF2
    FROM
      xxcos_lookup_values_v xlvv                                                  --�N�C�b�N�R�[�h
    WHERE lv_look_up    = xlvv.lookup_type                                    --���敪
    ORDER BY xlvv.lookup_code                                                 --�\�[�g��/�R�[�h
    ;
    -- ================
    -- ���[�U�[��`��O
    -- ================
    iv_param_expt                                      EXCEPTION;             --�����G���[
--
  BEGIN
--
    --�v���O�������ݒ�
    lv_prg_name := gv_pkg_name || cv_prg_name;
    --�o�͈���������
    ov_retcode  := xxccp_common_pkg.set_status_normal;
    --���͈����`�F�b�N<�t�@�C���`��>
    IF  ( iv_file_type != gv_file_type_fix )                                   --�Œ蒷
    AND ( iv_file_type != gv_file_type_variable )                              --�ϒ�
      THEN
        lv_errmsg  := xxccp_common_pkg.get_msg( iv_application     => gv_application
                                               ,iv_name            => gv_app_xxcos1_00019
                                               ,iv_token_name1     => gv_token_name_in_param
                                               ,iv_token_value1    => cv_token_file_type
                                               );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    --���͈����`�F�b�N<���C�A�E�g�敪�F�J�[�\�����o�Ώېݒ�>
    CASE iv_layout_class
      WHEN gv_layout_class_order THEN                                         --�󒍌n
        lv_look_up := cv_layout_type_order;
      WHEN gv_layout_class_stock THEN                                         --�݌�
        lv_look_up := cv_layout_type_stock;
      ELSE
        lv_errmsg  := xxccp_common_pkg.get_msg( iv_application     => gv_application
                                               ,iv_name            => gv_app_xxcos1_00019
                                               ,iv_token_name1     => gv_token_name_in_param
                                               ,iv_token_value1    => cv_token_layout_class
                                               );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END CASE;
    --
    --
    BEGIN
--add start 1/21
      lt_rec_type := FND_PROFILE.VALUE(ct_prf_if_data);
--add end 1/21
      OPEN  cur_xlvv;                                                           --�J�[�\��OPEN
      FETCH cur_xlvv BULK COLLECT INTO l_data_ttype;                            --�J�[�\��FETCH
      CLOSE cur_xlvv;                                                           --�J�[�\��CLOSE
      --
      FOR i in 1..l_data_ttype.count LOOP
      --�o�͏��ҏW
        ov_data_type_table(i).lookup_code   := l_data_ttype(i).lookup_code;
        ov_data_type_table(i).meaning       := l_data_ttype(i).meaning;
        ov_data_type_table(i).description   := l_data_ttype(i).description;
        ov_data_type_table(i).attribute1    := l_data_ttype(i).attribute1;
        ov_data_type_table(i).attribute2    := l_data_ttype(i).attribute2;
      --
      --�t�@�C���`���ώ��̂�CSV�w�b�_�쐬
        IF ( iv_file_type = gv_file_type_variable ) THEN
          IF ( i = 1 ) THEN
            --���b�Z�[�W������(���R�[�h���ʎq)�擾
--del start 1/21
--            lt_rec_type  := xxccp_common_pkg.get_msg(cv_apl_name, ct_rec_type);
--del end 1/21
            lv_csv_header                     := gv_char_double_cort
                                              || lt_rec_type 
                                              || gv_char_double_cort
                                              || gv_char_comma;
          END IF;
          lv_csv_header                       := lv_csv_header
                                              || gv_char_double_cort
                                              || l_data_ttype(i).description
                                              || gv_char_double_cort
                                              || gv_char_comma;
        END IF;
      --
      END LOOP;
      --
      IF ( iv_file_type = gv_file_type_variable ) THEN
        ov_csv_header := SUBSTRB( lv_csv_header
                                , 1
                                , LENGTHB( lv_csv_header ) - 1
                                );
      ---
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        --
        CASE iv_layout_class
          WHEN gv_layout_class_order THEN
            lv_token  := xxccp_common_pkg.get_msg( iv_application => gv_application
                                                   ,iv_name        => gv_app_xxcos1_00071
                                                  );
          WHEN gv_layout_class_stock THEN
            lv_token  := xxccp_common_pkg.get_msg( iv_application => gv_application
                                                   ,iv_name        => gv_app_xxcos1_00072
                                                  );
          --ELSE
        END CASE;
        lv_errmsg  := xxccp_common_pkg.get_msg( iv_application     => gv_application
                                               ,iv_name            => gv_app_xxcos1_00040
                                               ,iv_token_name1     => gv_token_name_layout
                                               ,iv_token_value1    => lv_token
                                               );
        lv_errbuf := lv_errmsg;
        RAISE  global_api_expt;
    END;
    --
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_layout_info;
--
  /**********************************************************************************
   * Procedure Name   : makeup_data_record
   * Description      : �f�[�^���R�[�h�ҏW
   ***********************************************************************************/
  --�f�[�^���R�[�h�ҏW
  PROCEDURE makeup_data_record(
               iv_edit_data                        IN  g_layout_ttype         --�o�̓f�[�^
              ,iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --�t�@�C���`��
              ,iv_data_type_table                  IN  g_record_layout_ttype  --�f�[�^�^�\
              ,iv_record_type                      IN  VARCHAR2 DEFAULT NULL  --���R�[�h���ʎq
              ,ov_data_record                      OUT NOCOPY VARCHAR2        --�f�[�^���R�[�h
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --�G���[���b�Z�[�W              #�Œ�#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --���^�[���R�[�h                #�Œ�#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --���[�U�[�E�G���[�E���b�Z�[�W  #�Œ�#
              )
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
                                                                              --�v���O����
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'makeup_data_record';
    cv_character                              CONSTANT VARCHAR2(4) := 'CHAR';    --������^
    cv_date                                   CONSTANT VARCHAR2(4) := 'DATE';    --���t�^
    cv_number                                 CONSTANT VARCHAR2(6) := 'NUMBER';  --���l�^
    cv_varchar                                CONSTANT VARCHAR2(7) := 'VARCHAR'; --���{��^�i�S�p�j
    cv_fmt                                    CONSTANT VARCHAR2(2) := 'FM';      --�ϒ��o�͗p�t�H�[�}�b�g
    cv_nine                                   CONSTANT VARCHAR2(1) := '9';       --<�t�H�[�}�b�g�p�X>
    cv_zero                                   CONSTANT VARCHAR2(1) := '0';       --<�t�H�[�}�b�g�p�O>
    cv_comma                                  CONSTANT VARCHAR2(1) := '.';       --�J���}
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --���b�Z�[�W�G���A
    lv_prg_name                                        VARCHAR2(100);         --���b�Z�[�W�p�v���O�������ݒ�G���A
    lv_csv_header                                      VARCHAR2(1000);        --�w�b�_�ҏW�G���A
    lv_out_unit_data                                   VARCHAR2(1000);        --�o�͗p�G���A
    lv_edit_data                                       VARCHAR2(1000);        --�ҏW�p�G���A
    lv_number_type                                     VARCHAR2(1000);        --�ҏW���l�G���A
    lv_minus_data                                      VARCHAR2(1000);        --�ϊ��p�G���A
    lv_number_fmt                                      VARCHAR2(100);         --�ϒ��p�t�H�[�}�b�g
    ln_under_point                                     NUMBER;                --�����_�ȉ����l
    ln_power_num                                       NUMBER;                --�ׂ���Ώےl
    ln_decimal_num                                     NUMBER;                --���l�G���A<������>
    ln_under_num                                       NUMBER;                --���l�G���A<������>
    i                                                  binary_integer := 0;   --�Y��
    -- PL/SQL�\�^
    l_outdata_ttype g_layout_ttype;
    l_data_ttype    g_record_layout_ttype;
  --
    -- ================
    -- ���[�U�[��`��O
    -- ================
  --
    --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
  --
--
  BEGIN
--
  --�v���O�������ݒ�
    lv_prg_name  := gv_pkg_name || cv_prg_name;
  --�o�͈���������
    ov_retcode   := xxccp_common_pkg.set_status_normal;
  --�e�[�u���W�J
    l_data_ttype    := iv_data_type_table;
    l_outdata_ttype := iv_edit_data;
  --���R�[�h���ʎq�ݒ�
    IF ( iv_file_type =  gv_file_type_fix ) THEN
                                                                              --�Œ蒷
      ov_data_record := iv_record_type;
    ELSE                                                                      --�ϒ�
      ov_data_record := gv_char_double_cort
                        ||  iv_record_type  ||
                        gv_char_double_cort
                        ||  gv_char_comma;
    END IF;
  --
    FOR i in 1..l_data_ttype.count LOOP
    --�e�[�u���ݒ�Ȃ��̑Ή�
      BEGIN
        lv_out_unit_data := l_outdata_ttype( l_data_ttype(i).meaning );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_out_unit_data := NULL;
      END;
    --< NUMBER�^�̏����_�ȉ��̌����Z�o >
      ln_power_num := 0;
      IF ( l_data_ttype(i).attribute1 = cv_number ) THEN
       --�����̕ێ�
        lv_number_type     := l_data_ttype(i).attribute2;
       --�����_�L���̔���G���A
        ln_under_point     := INSTRB( lv_number_type
                                     ,cv_comma
                                     ,1
                                     ,1 );
       --�����_��
        IF ( ln_under_point = 0 ) THEN
          --������
          ln_under_num     := 0;
          --������
          ln_decimal_num   := TO_NUMBER( lv_number_type );
          --�ϒ��o�͗p�t�H�[�}�b�g
          lv_number_fmt    := RPAD( cv_fmt
                                   ,ln_decimal_num + LENGTHB( cv_fmt )
                                   ,cv_nine );
       --�����_�L
       ELSE
          --������
          ln_under_num     := TO_NUMBER( SUBSTRB( lv_number_type
                                                 ,INSTRB( lv_number_type,cv_comma,1,1 ) +1
                                                 ) );
          --������
          ln_decimal_num   := TO_NUMBER( SUBSTRB( lv_number_type
                                                 ,1
                                                 ,INSTRB( lv_number_type,cv_comma,1,1 ) -1
                                                 ) );
          --�ϒ��o�͗p�t�H�[�}�b�g
          lv_number_fmt    := RPAD( cv_fmt
                                   ,ln_decimal_num - 1 + LENGTHB( cv_fmt )
                                   ,cv_nine )
                           || cv_zero
                           || RPAD( cv_comma
                                   ,ln_under_num   + LENGTHB( cv_comma )
                                   ,cv_zero );
        END IF;
        --�����_�ȉ��̐��l�𐮐��ɖ߂��{���̎Z�o
        ln_power_num   := 10 ** ln_under_num;
        --�Œ蒷�p�������Z�o
        lv_number_type := ln_under_num  + ln_decimal_num;
      END IF;
    --�o�̓G���A�ҏW
      IF ( iv_file_type = gv_file_type_fix )                                  --�Œ蒷
      THEN
      --���̓f�[�^(iv_edit_data)�ɑΏۂ��Ȃ��ꍇ�̍l��
        IF ( lv_out_unit_data IS NULL ) THEN
          IF ( l_data_ttype(i).attribute1 IN ( cv_character
                                              ,cv_varchar ) )
          THEN
            lv_out_unit_data := gv_char_space;
          ELSE
            lv_out_unit_data := 0;
          END IF;
        END IF;
      --
        IF ( l_data_ttype(i).attribute1 IN ( cv_character
                                            ,cv_varchar ) )
        THEN
            ov_data_record := ov_data_record
                           || RPAD( lv_out_unit_data
                                   ,l_data_ttype(i).attribute2
                                   );
        ELSIF ( l_data_ttype(i).attribute1 = cv_number )
          THEN
       --�����_�ȉ����݃`�F�b�N
            IF ( ln_under_point != 0 ) THEN
       --�����l�ɕϊ�
              lv_out_unit_data := ln_power_num * to_number(lv_out_unit_data);
            END IF;
       --�[���ȉ��̕ҏW���@
            IF ( TO_NUMBER( lv_out_unit_data ) < 0 ) THEN
              lv_out_unit_data := TO_NUMBER(lv_out_unit_data) * -1;
              lv_minus_data    := LPAD( lv_out_unit_data
                                       ,lv_number_type - 1
                                       ,0 );
              ov_data_record   := ov_data_record
                               || '-'
                               || lv_minus_data ;
            ELSE
              ov_data_record   := ov_data_record
                               || LPAD( lv_out_unit_data
                                       ,lv_number_type
                                       ,0 );
            END IF;
        ELSIF ( l_data_ttype(i).attribute1 = cv_date )
          THEN
            ov_data_record     := ov_data_record
                               || LPAD( lv_out_unit_data
                                       ,l_data_ttype(i).attribute2
                                       ,0 );
      --ELSE
        END IF;
      ELSE                                                                    --�ϒ�
--*********************************** 2009/03/31 1.3 T.Kitajima MOD START *********************************************
--        IF ( l_data_ttype(i).attribute1 IN ( cv_character
--                                            ,cv_date
--                                            ,cv_varchar ) )
        IF ( l_data_ttype(i).attribute1 IN ( cv_character
                                            ,cv_varchar ) )
--*********************************** 2009/03/31 1.3 T.Kitajima MOD  END  *********************************************
        THEN
          ov_data_record   := ov_data_record
                           || gv_char_double_cort
                           || SUBSTRB( lv_out_unit_data
                                      ,1
                                      ,l_data_ttype(i).attribute2 )
                           || gv_char_double_cort;
--*********************************** 2009/03/31 1.3 T.Kitajima ADD START *********************************************
        ELSIF l_data_ttype(i).attribute1 = cv_date
          THEN
          ov_data_record   := ov_data_record
                           || gv_char_double_cort
                           || NVL( SUBSTRB( lv_out_unit_data
                                       ,1
                                       ,l_data_ttype(i).attribute2 ),
                                   cv_date_null )
                           || gv_char_double_cort;
--*********************************** 2009/03/31 1.3 T.Kitajima ADD  END  *********************************************
        ELSIF l_data_ttype(i).attribute1 = cv_number
          THEN
            ov_data_record := ov_data_record
--*********************************** 2009/03/31 1.3 T.Kitajima MOD START *********************************************
--                           || TO_CHAR( TO_NUMBER( lv_out_unit_data ), lv_number_fmt );
                           || NVL( TO_CHAR(  TO_NUMBER( lv_out_unit_data ), lv_number_fmt ), cv_number_null);
--*********************************** 2009/03/31 1.3 T.Kitajima MOD  END  *********************************************
      --ELSE
        END IF;
      --�J���}�t��
        IF ( i <  l_data_ttype.count ) THEN
            ov_data_record := ov_data_record
                           || gv_char_comma;
        END IF;
      END IF;
  --
    END LOOP;
  --
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END makeup_data_record;
  --
--
/* 2009/06/23 Ver1.5 Add Start */
  /**********************************************************************************
   * Procedure Name   : convert_quantity
   * Description      : EDI���[�������ʊ��Z�֐�
   ***********************************************************************************/
  PROCEDURE convert_quantity(
               iv_uom_code           IN  VARCHAR2  DEFAULT NULL  --�P�ʃR�[�h
              ,in_case_qty           IN  NUMBER    DEFAULT NULL  --�P�[�X����
              ,in_ball_qty           IN  NUMBER    DEFAULT NULL  --�{�[������
              ,in_sum_indv_order_qty IN  NUMBER    DEFAULT NULL  --��������(���v�E�o��)
              ,in_sum_shipping_qty   IN  NUMBER    DEFAULT NULL  --�o�א���(���v�E�o��)
              ,on_indv_shipping_qty  OUT NOCOPY NUMBER           --�o�א���(�o��)
              ,on_case_shipping_qty  OUT NOCOPY NUMBER           --�o�א���(�P�[�X)
              ,on_ball_shipping_qty  OUT NOCOPY NUMBER           --�o�א���(�{�[��)
              ,on_indv_stockout_qty  OUT NOCOPY NUMBER           --���i����(�o��)
              ,on_case_stockout_qty  OUT NOCOPY NUMBER           --���i����(�P�[�X)
              ,on_ball_stockout_qty  OUT NOCOPY NUMBER           --���i����(�{�[��)
              ,on_sum_stockout_qty   OUT NOCOPY NUMBER           --���i����(���v�E�o��)
              ,ov_errbuf             OUT NOCOPY VARCHAR2         --�G���[�E���b�Z�[�W�G���[       #�Œ�#
              ,ov_retcode            OUT NOCOPY VARCHAR2         --���^�[���E�R�[�h               #�Œ�#
              ,ov_errmsg             OUT NOCOPY VARCHAR2         --���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'convert_quantity';   --�v���O����
    cn_zero                                   CONSTANT NUMBER(1)     := 0;                    --���l�F0
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_case_uom_code                                   mtl_units_of_measure_tl.uom_code%TYPE; -- �P�[�X�P�ʃR�[�h
    --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
  --
--
  BEGIN
--
    --���^�[���E�R�[�h������
    ov_retcode := cv_status_normal;
--
    --�P�ʃR�[�h�`�F�b�N
    IF ( iv_uom_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                              ,iv_name         => ct_msg_bad_calculation_err
                                            );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�P�[�X�P�ʃR�[�h�擾
    lv_case_uom_code := FND_PROFILE.VALUE( ct_prof_case_uom_code );
--
    --���i����(���v�E�o��) = ��������(���v�E�o��) - �o�א���(���v�E�o��)
    on_sum_stockout_qty  := in_sum_indv_order_qty - in_sum_shipping_qty;
--
    --�P�[�X�ȊO�̏ꍇ
    IF ( iv_uom_code <> lv_case_uom_code ) THEN
--
      --�P�[�X��������A���A0�ȊO
      IF ( in_case_qty IS NOT NULL )
        AND ( in_case_qty <> cn_zero )THEN
        --�o�א���(�o��)   = �o�א���(���v�E�o��) / �P�[�X�����̗]��
        on_indv_shipping_qty := MOD( in_sum_shipping_qty, in_case_qty );
        --�o�א���(�P�[�X) = �o�א���(���v�E�o��) / �P�[�X�����̏�
        on_case_shipping_qty := TRUNC( in_sum_shipping_qty / in_case_qty );
        --���i����(�o��)   = ���i����(���v�E�o��) / �P�[�X�����̗]��
        on_indv_stockout_qty := MOD( on_sum_stockout_qty, in_case_qty );
        --���i����(�P�[�X) = ���i����(���v�E�o��) / �P�[�X�����̏�
        on_case_stockout_qty := TRUNC( on_sum_stockout_qty / in_case_qty );
      --�P�[�X�����Ȃ�
      ELSE
        --�o�א���(�o��)   = �o�א���(���v�E�o��)
        on_indv_shipping_qty := in_sum_shipping_qty;
        --�o�א���(�P�[�X) = 0
        on_case_shipping_qty := cn_zero;
        --���i����(�o��)   = ���i����(���v�E�o��) 
        on_indv_stockout_qty := on_sum_stockout_qty;
        --���i����(�P�[�X) = 0
        on_case_stockout_qty := cn_zero;
      END IF;
--
      --�{�[����������A���A0�ȊO
      IF ( in_ball_qty IS NOT NULL )
        AND ( in_ball_qty <> cn_zero )THEN
        --�o�א���(�{�[��) = �o�א���(���v�E�o��) / �{�[�������̏�
        on_ball_shipping_qty := TRUNC( in_sum_shipping_qty / in_ball_qty );
        --���i����(�{�[��) = ���i����(���v�E�o��) / �{�[�������̏�
        on_ball_stockout_qty := TRUNC( on_sum_stockout_qty / in_ball_qty );
      --�{�[�������Ȃ�
      ELSE
        --�o�א���(�{�[��) = 0
        on_ball_shipping_qty := cn_zero;
        --���i����(�{�[��) = 0
        on_ball_stockout_qty := cn_zero;
      END IF;
--
    --�P�[�X�̏ꍇ
    ELSE
--
      --�o�א���(�o��)   = �o�א���(���v�E�o��)
      on_indv_shipping_qty := in_sum_shipping_qty;
      --�o�א���(�P�[�X) = 0
      on_case_shipping_qty := cn_zero;
      --�o�א���(�{�[��) = 0
      on_ball_shipping_qty := cn_zero;
      --���i����(�o��)   = ���i����(���v�E�o��)
      on_indv_stockout_qty := on_sum_stockout_qty;
      --���i����(�P�[�X) = 0
      on_case_stockout_qty := cn_zero;
      --���i����(�{�[��) = 0
      on_ball_stockout_qty := cn_zero;
--
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END convert_quantity;
  --
/* 2009/06/23 Ver1.5 Add End */
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_slip_flag
   * Description      : �[�i�����s�t���O�擾�֐�
   ***********************************************************************************/
  FUNCTION get_deliv_slip_flag(
               iv_publish_sequence                 IN  NUMBER   DEFAULT NULL  --�[�i�����s�t���O�ݒ菇��
              ,iv_publish_area                     IN  VARCHAR2 DEFAULT NULL  --�[�i�����s�t���O�G���A
              )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
                                                                              --�v���O����
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'get_deliv_slip_flag';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_start_possition                                 NUMBER(3);             --�J�n�ʒu
    lv_publish_area                                    VARCHAR2(1);           --�[�i�����s�t���O
    --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
  --
--
  BEGIN
--
    --�ϐ�������
    ln_start_possition  := 0;
    lv_publish_area     := gv_char_n;
    --NULL�`�F�b�N
    IF ( iv_publish_area IS NULL ) THEN
      RETURN gv_char_n;
    END IF;
    --�ʒu�`�F�b�N
    CASE iv_publish_sequence
    --���͔��s���ԂO���y�ԋp�z
      WHEN 0 THEN
        RETURN gv_char_n;
    --���͔��s���ԂP���y�ԋp�z
      WHEN 1 THEN
        lv_publish_area := SUBSTRB( iv_publish_area
                                   ,1
                                   ,1
                                   );
      ELSE
    --���͔��s���ԂQ�ȏ㎞�y�ԋp�z
        ln_start_possition := iv_publish_sequence * 2 - 1;
        lv_publish_area := SUBSTRB( iv_publish_area
                                   ,ln_start_possition
                                   ,1
                                   );
    END CASE;
    --�[�i�����s�t���O�ݒ�
    IF   ( lv_publish_area = gv_char_comma )
      OR ( lv_publish_area IS NULL )
    THEN
      RETURN gv_char_n;
    ELSE
      RETURN lv_publish_area;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_deliv_slip_flag;
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_slip_flag_area
   * Description      : �[�i�����s�t���O�S�̎擾�֐�
   ***********************************************************************************/
  FUNCTION get_deliv_slip_flag_area(
               iv_publish_sequence                  IN NUMBER   DEFAULT NULL  --�[�i�����s�t���O�ݒ菇��
              ,iv_publish_area                      IN VARCHAR2 DEFAULT NULL  --�[�i�����s�t���O�G���A
              ,iv_publish_flag                      IN VARCHAR2 DEFAULT NULL  --�[�i�����s�t���O
              )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
                                                                              --�v���O����
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'get_deliv_slip_flag_area';
    cv_demiliter_flg_on                       CONSTANT VARCHAR2(2)   := 'ON';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_length                                          binary_integer := 0;   --���͈��������O�X
    ln_publish_sequence                                binary_integer := 0;   --���Έʒu�J�E���^
    ln_count                                           binary_integer := 0;   --�f�~���^�����J�E���^
    ln_data_sequence                                   binary_integer := 0;   --�o�͈��������O�X
    i                                                  binary_integer := 0;   --�Y�����@
    j                                                  binary_integer := 1;   --�Y�����A
    lv_publish_area                                    VARCHAR2(1000) DEFAULT NULL; --�ݒ��[�i�����s�t���O�G���A
    lv_byte_area                                       VARCHAR2(1000) DEFAULT NULL; --����G���A
    lv_demiliter_flg                                   VARCHAR2(1000) DEFAULT NULL; --�f�~���^����t���O
    --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
  --
--
  BEGIN
--
  --���͈����`�F�b�N
    IF   ( iv_publish_sequence IS NULL )
      OR ( iv_publish_flag     IS NULL )
    THEN
      RETURN iv_publish_area;
    END IF;
  --�[�i�����s�t���O�G���A     �F���͈����ŏI�ʒu����
    ln_length := LENGTHB( iv_publish_area );
    IF ( ln_length IS NULL ) THEN
      ln_length := 0;
    END IF;
  --�f�~���^��������
    LOOP
      i := i + 1;
      IF ( i >= ln_length ) THEN
        EXIT;
      ELSE
        IF ( SUBSTRB( iv_publish_area,i,1 ) = gv_char_comma ) THEN
          ln_count := ln_count + 1;
        END IF;
      END IF;
    END LOOP;
  --�[�i�����s�t���O�ݒ菇��   �F���Έʒu����
    IF ( iv_publish_sequence = 0 ) THEN
      ln_publish_sequence := iv_publish_sequence - 1;
    ELSE
      ln_publish_sequence := iv_publish_sequence * 2 - 1;
    END IF;  
  --�o�͔[�i�����s�t���O�G���A�F���Έʒu����
    IF ( ln_count != 0 ) THEN
      ln_data_sequence := ln_count * 2 + 1;
    END IF;      
    IF (ln_publish_sequence > ln_data_sequence ) THEN
      ln_data_sequence := ln_publish_sequence;
    END IF;
  --�o�͔[�i�����s�t���O�G���A�ݒ�
    FOR i IN 1..ln_data_sequence LOOP
      lv_byte_area := SUBSTRB( iv_publish_area,j,1 );
      IF ( lv_demiliter_flg = cv_demiliter_flg_on ) THEN
        lv_publish_area := lv_publish_area || gv_char_comma;
        lv_demiliter_flg := NULL;
        j := j + 1;
      ELSE
        IF ( lv_byte_area = gv_char_comma ) THEN
          IF ( i = ln_publish_sequence ) THEN
            lv_publish_area := lv_publish_area || iv_publish_flag;
          ELSE
            lv_publish_area := lv_publish_area || gv_char_n;
          END IF;
        ELSE
          IF ( i = ln_publish_sequence ) THEN
            lv_publish_area := lv_publish_area || iv_publish_flag;
          ELSE
            IF ( iv_publish_area IS NULL ) THEN
              lv_publish_area := lv_publish_area || gv_char_n;
            ELSE
--mod start 1/21
--              lv_publish_area := lv_publish_area || SUBSTRB( iv_publish_area,j,1 );
              lv_publish_area := lv_publish_area || NVL(SUBSTRB( iv_publish_area,j,1 ),gv_char_n);
--mod end 1/21
            END IF;
          END IF;
          j := j + 1;
        END IF;
        lv_demiliter_flg := cv_demiliter_flg_on;
      END IF;
    END LOOP;
----  
    RETURN lv_publish_area;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_deliv_slip_flag_area;
--
END XXCOS_COMMON2_PKG;
/
