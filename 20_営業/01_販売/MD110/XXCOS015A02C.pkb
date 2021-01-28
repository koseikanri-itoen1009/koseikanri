CREATE OR REPLACE PACKAGE BODY APPS.XXCOS015A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOS015A02C(body)
 * Description      : ���n�V�X�e�������󒍏��̍쐬���s��
 * MD.050           : �󒍏��̏��n�A�g MD050_COS_015_A02
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                        ��������(A-1)
 *  file_open                   �t�@�C���I�[�v��(A-2)
 *  open_order_info_cur         �󒍏�񒊏o(A-3)
 *  output_for_order            �󒍏��CSV�쐬(A-4)
 *  file_colse                  �t�@�C���N���[�Y(A-5)
 *  expt_proc                   ��O����(A-6)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/06/22    1.0   N.Koyama         [E_�{�ғ�_16429]�V�K�쐬
 *  2021/01/12    1.1   N.Koyama         [E_�{�ғ�_16897]�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100)    := 'XXCOS015A02C';       -- �p�b�P�[�W��
  cv_xxcos_short_name         CONSTANT VARCHAR2(10)     := 'XXCOS';              -- �A�v���P�[�V�����Z�k��:XXCOS
  cv_xxccp_short_name         CONSTANT VARCHAR2(10)     := 'XXCCP';              -- �A�v���P�[�V�����Z�k��:XXCCP
  cv_xxcoi_short_name         CONSTANT VARCHAR2(10)     := 'XXCOI';              -- �A�v���P�[�V�����Z�k��:XXCOI
  -- ���b�Z�[�W
  cv_msg_non_parameter        CONSTANT VARCHAR2(20)     := 'APP-XXCCP1-90008';    -- ���͍��ڂȂ�
  cv_msg_notfound_data        CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00003';    -- �����Ώۃf�[�^�Ȃ�
  cv_msg_notfound_profile     CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[
  cv_msg_file_open_error      CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00009';    -- �t�@�C���I�[�v���G���[
  cv_msg_data_extra_error     CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00013';    -- �f�[�^���o�G���[
  cv_msg_non_business_date    CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[
  cv_msg_file_name            CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00044';    -- �t�@�C����
  cv_msg_org_id               CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00047';    -- �c�ƒP��
  cv_msg_sales_line           CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-13303';    -- �̔�����
  cv_msg_count                CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-15301';    -- �������b�Z�[�W
  cv_msg_details              CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-13322';    -- ���b�Z�[�W�p������:�u�ڍׁv
  cv_msg_org_cd_err           CONSTANT VARCHAR2(20)     := 'APP-XXCOI1-00005';    -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_org_id_err           CONSTANT VARCHAR2(20)     := 'APP-XXCOI1-00006';    -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_period_err           CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-15302';    -- AR��v���ԃI�[�v�����Ԏ擾�G���[
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)     := 'PROFILE';             -- �v���t�@�C����
  cv_tkn_pro_tok1             CONSTANT VARCHAR2(20)     := 'PRO_TOK';             -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20)     := 'TABLE';               -- �e�[�u����
  cv_tkn_key_data             CONSTANT VARCHAR2(20)     := 'KEY_DATA';            -- �L�[����
  cv_tkn_table_name           CONSTANT VARCHAR2(20)     := 'TABLE_NAME';          -- �e�[�u����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)     := 'FILE_NAME';           -- �t�@�C����
  cv_tkn_nm_org_cd            CONSTANT  VARCHAR2(100)   := 'ORG_CODE_TOK';        --�݌ɑg�D�R�[�h
  cv_tkn_count                CONSTANT VARCHAR2(20)     := 'COUNT';               -- ����
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)     := 'LOOKUP_TYPE';         -- �Q�ƃ^�C�v
  cv_tkn_meaning              CONSTANT VARCHAR2(20)     := 'MEANING';             -- �Ӗ�
  cv_tkn_count_1              CONSTANT VARCHAR2(20)     := 'COUNT1';              -- ����1
  cv_tkn_count_2              CONSTANT VARCHAR2(20)     := 'COUNT2';              -- ����2
  cv_tkn_count_3              CONSTANT VARCHAR2(20)     := 'COUNT3';              -- ����3
  -- �v���t�@�C��
  cv_pf_output_directory      CONSTANT VARCHAR2(50)     := 'XXCOS1_OUTBOUND_ZYOHO_DIR';        -- �f�B���N�g���p�X
  cv_pf_company_code          CONSTANT VARCHAR2(50)     := 'XXCOI1_COMPANY_CODE';              -- ��ЃR�[�h
  cv_pf_csv_file_name         CONSTANT VARCHAR2(50)     := 'XXCOS1_KB_ORDER_FILE_NAME';        -- �󒍏��t�@�C����
  cv_pf_month                 CONSTANT VARCHAR2(50)     := 'XXCOS1_KB_ORDER_MONTH';            -- �󒍓��Ώۊ��Ԍ���
-- Ver1.1 Add Start
  cv_pf_month_to              CONSTANT VARCHAR2(50)     := 'XXCOS1_KB_ORDER_MONTH_TO';         -- �󒍓��Ώۊ��Ԍ���(TO)
-- Ver1.1 Add End
  cv_pf_org_id                CONSTANT VARCHAR2(50)     := 'ORG_ID';                           -- MO:�c�ƒP��
  cv_pf_org                   CONSTANT VARCHAR2(50)     := 'XXCOI1_ORGANIZATION_CODE';         -- �݌ɑg�D�R�[�h
  cv_pf_gl_set_of_bks_id      CONSTANT VARCHAR2(50)     := 'GL_SET_OF_BKS_ID';                 -- GL��v����ID
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qck_typ_sale    CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS';         -- ����敪
  -- ���t�t�H�[�}�b�g
  cv_date_format              CONSTANT VARCHAR2(20)     := 'YYYY/MM/DD';
  cv_date_format_non_sep      CONSTANT VARCHAR2(20)     := 'YYYYMMDD';
  cv_datetime_format          CONSTANT VARCHAR2(20)     := 'YYYYMMDDHH24MISS';
  -- �؎̂Ď��ԗv�f
  cv_trunc_fmt                CONSTANT VARCHAR2(2)      := 'MM';
  -- �L�������t���O
  cv_enabled_flag             CONSTANT VARCHAR2(1)      := 'Y';             -- �L��
  cv_enabled_flag_a           CONSTANT VARCHAR2(1)      := 'A';             -- �L��
  -- ����
  cv_lang                     CONSTANT VARCHAR2(100)    :=  USERENV( 'LANG' );
  -- ����
  cv_blank                    CONSTANT VARCHAR2(1)      := '';             -- �u�����N
  cv_flag_no                  CONSTANT VARCHAR2(1)      := 'N';            -- �t���O:No
  cv_delimiter                CONSTANT VARCHAR2(1)      := ',';            -- �f���~�^
  cv_val_y                    CONSTANT VARCHAR2(1)      := 'Y';            -- �l�FY
  cv_val_n                    CONSTANT VARCHAR2(1)      := 'N';            -- �l�FN
  cv_d_cot                    CONSTANT VARCHAR2(1)      := '"';            -- �_�u���N�H�[�e�[�V����
  -- �g�p�ړI
  cv_site_ship_to             CONSTANT VARCHAR2(10)     := 'SHIP_TO';      -- �o�א�
  -- ��v����
  cv_ar                       CONSTANT VARCHAR2(10)     := 'AR';           -- AR
  cv_open                     CONSTANT VARCHAR2(10)     := 'O';            -- O:�I�[�v��
  -- �]�ƈ��J�e�S��
  cv_category_employee        CONSTANT VARCHAR2(8)      := 'EMPLOYEE';     -- �]�ƈ�
  -- �󒍃X�e�[�^�X
  cv_header_closed            CONSTANT VARCHAR2(10)      := 'CLOSED';       -- �N���[�Y
  cv_header_cancelled         CONSTANT VARCHAR2(10)      := 'CANCELLED';    -- �L�����Z��
  cv_line_closed              CONSTANT VARCHAR2(10)      := 'CLOSED';       -- �N���[�Y
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_system_date        DATE;                                                     -- �V�X�e�����t
  gd_business_date      DATE;                                                     -- �Ɩ����t
  gd_date_from          DATE;                                                     -- ��v�iFROM�j
  gd_date_to            DATE;                                                     -- ��v�iTO�j
  gt_output_directory   fnd_profile_option_values.profile_option_value%TYPE;      -- �f�B���N�g���p�X
  gt_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;      -- �󒍏��t�@�C����
  gn_kb_month           NUMBER;                                                   -- ���n�󒍘A�g�Ώی���
-- Ver1.1 Add Stasrt
  gn_kb_month_to        NUMBER;                                                   -- ���n�󒍘A�g�Ώی���(TO)
-- Ver1.1 Add End
  gt_company_code       fnd_profile_option_values.profile_option_value%TYPE;      -- ��ЃR�[�h
  gt_org_id             fnd_profile_option_values.profile_option_value%TYPE;      -- MO:�c�ƒP��
  gt_file_handle        UTL_FILE.FILE_TYPE;                                       -- �t�@�C���n���h��
  gn_inv_org_id         NUMBER;                                                   -- �݌ɑg�DID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
    -- �󒍏��擾
    CURSOR get_order_info_cur
      IS
        SELECT /*+ USE_NL(oeh oel oeht sel oelt oos selk ) */
                oeht.name                       AS   header_type_name              -- �󒍃w�b�_�^�C�v
               ,oos.name                        AS   source_name                   -- �󒍃\�[�X
               ,oeh.order_number                AS   order_number                  -- �󒍔ԍ�
               ,hca.account_number              AS   account_number                -- �ڋq�R�[�h
               ,xca.sale_base_code              AS   sale_base_code                -- ���㋒�_
               ,xca.past_sale_base_code         AS   past_sale_base_code           -- �O�����㋒�_
               ,xca.delivery_base_code          AS   delivery_base_code            -- �[�i���_
               ,pri_h.name                      AS   h_price_list_name             -- ���i�\(�w�b�_)
               ,sel.salesrep_number             AS   salesrep_number               -- �c�ƒS���ԍ�
               ,res.resource_name               AS   resource_name                 -- �c�ƒS��
               ,oeh.ordered_date                AS   ordered_date                  -- �󒍓�
               ,oeh.cust_po_number              AS   cust_po_number                -- �ڋq�����ԍ� 
               ,oeh.request_date                AS   h_request_date                -- �[�i�\���(�w�b�_)
               ,oeh.flow_status_code            AS   flow_status_code              -- �󒍃w�b�_�X�e�[�^�X
               ,oeh.booked_date                 AS   booked_date                   -- �L����
               ,oeh.global_attribute4           AS   h_global_attribute4           -- ��No.(HHT)
               ,oeh.global_attribute5           AS   h_global_attribute5           -- �������敪
               ,oel.line_number                 AS   line_number                   -- �󒍖��ԍ�
               ,oel.shipment_number             AS   shipment_number               -- �󒍖��׏o�הԍ�
               ,itm.segment1                    AS   segment1                      -- �󒍕i��
               ,oel.attribute6                  AS   l_attribute6                  -- �q�R�[�h
               ,oelt.name                       AS   line_type_name                -- �󒍖��׃^�C�v
               ,oel.ordered_quantity            AS   ordered_quantity              -- �󒍐�
               ,oel.order_quantity_uom          AS   order_quantity_uom            -- �󒍒P��
               ,oel.unit_selling_price          AS   unit_selling_price            -- �̔��P��
               ,pri_l.name                      AS   l_price_list_name             -- ���i�\(����)
               ,oel.schedule_ship_date          AS   schedule_ship_date            -- �\��o�ד�
               ,oel.request_date                AS   l_request_date                -- �[�i�\���(����)
               ,oel.subinventory                AS   subinventory                  -- �ۊǏꏊ
               ,oel.packing_instructions        AS   packing_instructions          -- �o�׈˗�No
               ,oel.context                     AS   l_context                     -- �R���e�L�X�g�l(����)
               ,SUBSTRB(oel.attribute4,1,10)    AS   l_attribute4                  -- �����\���
               ,oel.attribute5                  AS   l_attribute5                  -- ����敪
               ,selk.meaning                    AS   meaning                       -- ����敪�E�v
               ,oel.attribute10                 AS   l_attribute10                 -- ���P��
               ,oel.flow_status_code            AS   l_flow_status_code            -- �󒍖��׃X�e�[�^�X
        FROM    oe_order_lines_all              oel    -- �󒍖���
               ,oe_order_headers_all            oeh    -- �󒍃w�b�_
               ,mtl_system_items_b              itm    -- �i��
               ,oe_transaction_types_tl         oeht   -- �󒍃^�C�v(�w�b�_)
               ,oe_transaction_types_tl         oelt   -- �󒍃^�C�v(����)
               ,hz_cust_accounts                hca    -- �ڋq�}�X�^
               ,xxcmm_cust_accounts             xca    -- �ڋq�A�h�I��
               ,qp_list_headers_vl              pri_h  -- ���i�\(�w�b�_)
               ,qp_list_headers_vl              pri_l  -- ���i�\(����)
               ,jtf_rs_salesreps                sel    -- �c�ƒS��
               ,jtf_rs_resource_extns_vl        res    -- ���\�[�X
               ,fnd_lookup_values               selk   -- ����敪
               ,oe_order_sources                oos    -- �󒍃\�[�X
        WHERE   oeh.header_id                   = oel.header_id
        AND     oeh.org_id                      = gt_org_id
        AND     oel.inventory_item_id           = itm.inventory_item_id
        AND     itm.organization_id             = gn_inv_org_id
        AND     oeh.order_type_id               = oeht.transaction_type_id
        AND     oeht.language                   = cv_lang
        AND     oel.line_type_id                = oelt.transaction_type_id
        AND     oelt.language                   = cv_lang
        AND     oeh.sold_to_org_id              = hca.cust_account_id
        AND     hca.cust_account_id             = xca.customer_id
        AND     pri_l.list_header_id(+)         = oel.price_list_id
        AND     pri_h.list_header_id(+)         = oeh.price_list_id
        AND     sel.salesrep_id                 = oeh.salesrep_id
        AND     res.resource_id                 = sel.resource_id 
        AND     res.category                    = cv_category_employee
        AND     oel.attribute5                  = selk.lookup_code(+)
        AND     selk.LOOKUP_TYPE(+)             = cv_qck_typ_sale
        AND     selk.language(+)                = cv_lang
        AND     oos.order_source_id             = oel.order_source_id
-- Ver1.1 Mod Start
--        AND     oeh.ordered_date BETWEEN ADD_MONTHS(gd_business_date,gn_kb_month * -1) AND gd_business_date + 86399/86400
        AND     oeh.ordered_date BETWEEN ADD_MONTHS(gd_business_date,gn_kb_month * -1) AND ADD_MONTHS(gd_business_date,gn_kb_month_to) + 86399/86400
-- Ver1.1 Mod End
        AND     oel.request_date BETWEEN gd_date_from                                  AND gd_date_to       + 86399/86400
        AND     oeh.flow_status_code       NOT IN (cv_header_closed,cv_header_cancelled)
        AND     oel.flow_status_code           <>  cv_line_closed
        ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  get_order_info_rec  get_order_info_cur%ROWTYPE;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���R�[�h���b�N�G���[
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_directory_path            VARCHAR2(100);                          -- �f�B���N�g���E�p�X
    lt_inv_org_cd                mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
    ln_gl_set_of_bks_id          NUMBER;                                 -- ��v����ID
    lv_status                    VARCHAR2(6);                            -- �X�e�[�^�X
    ld_date_from                 DATE;                                   -- ��v�iFROM�j
    ld_date_to                   DATE;                                   -- ��v�iTO�j
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J����O ***
    non_business_date_expt       EXCEPTION;     -- �Ɩ����t�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.���͍��ڂȂ��̃��b�Z�[�W�쐬
    --==================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_msg_non_parameter);
    --
    --==================================
    -- �R���J�����g�E���b�Z�[�W�o��
    --==================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
    --==================================
    -- �R���J�����g�E���O�o��
    --==================================
    -- ��s�o�� 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => cv_blank
    ); 
-- 
    -- ���b�Z�[�W���O 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => gv_out_msg
    ); 
-- 
    -- ��s�o�� 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => cv_blank
    ); 
--
    --==================================
    -- �V�X�e�����t�擾
    --==================================
    gd_system_date := SYSDATE;
--
    --==================================
    -- 2.�Ɩ����t�擾
    --==================================
    gd_business_date :=  xxccp_common_pkg2.get_process_date;
--
    IF ( gd_business_date IS NULL ) THEN
      -- �Ɩ����t���擾�ł��Ȃ��ꍇ
      RAISE non_business_date_expt;
    END IF;
--
    --==================================
    -- 3.MO:�c�ƒP�ʎ擾
    --==================================
    gt_org_id := FND_PROFILE.VALUE( cv_pf_org_id );
--
    IF ( gt_org_id IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
        ,iv_token_value1 => cv_pf_org_id);              -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 4.�f�B���N�g���p�X�擾
    --==================================
    gt_output_directory := FND_PROFILE.VALUE( cv_pf_output_directory );
--
    IF ( gt_output_directory IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
        ,iv_token_value1 => cv_pf_output_directory);    -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 5.�󒍏��t�@�C�����擾
    --==================================
    gt_csv_file_name := FND_PROFILE.VALUE( cv_pf_csv_file_name );
--
    IF ( gt_csv_file_name IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
        ,iv_token_value1 => cv_pf_csv_file_name);       -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �t�@�C�����o��
    --==================================
    SELECT ad.directory_path
    INTO   lv_directory_path
    FROM   all_directories  ad
    WHERE  ad.directory_name = gt_output_directory;
    --
    gv_out_msg :=  xxccp_common_pkg.get_msg(
       iv_application  => cv_xxcos_short_name           -- �A�v���P�[�V�����Z�k��
      ,iv_name         => cv_msg_file_name              -- ���b�Z�[�W
      ,iv_token_name1  => cv_tkn_file_name              -- �g�[�N��1��
      ,iv_token_value1 => lv_directory_path 
                          || '/' 
                          || gt_csv_file_name);         -- �g�[�N��1�l
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
--
    --==================================
    -- 6.���n�󒍘A�g�Ώی����擾
    --==================================
    gn_kb_month := TO_NUMBER(FND_PROFILE.VALUE( cv_pf_month ));
--
    IF ( gn_kb_month IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
        ,iv_token_value1 => cv_pf_month);               -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Ver1.1 Add Start
    gn_kb_month_to := TO_NUMBER(FND_PROFILE.VALUE( cv_pf_month_to ));
--
    IF ( gn_kb_month_to IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
        ,iv_token_value1 => cv_pf_month_to);               -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Ver1.1 Add End
--
    --==================================
    -- 7.��ЃR�[�h�擾
    --==================================
    gt_company_code := FND_PROFILE.VALUE( cv_pf_company_code );
--
    IF ( gt_company_code IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_pro_tok              -- �g�[�N��1��
        ,iv_token_value1 => cv_pf_company_code);        -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
    --========================================
    -- 8.�݌ɑg�D�R�[�h�擾����
    --========================================
    lt_inv_org_cd := FND_PROFILE.VALUE( cv_pf_org );
    IF ( lt_inv_org_cd IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   => cv_xxcoi_short_name        -- �A�v���P�[�V�����Z�k��
        ,iv_name          => cv_msg_org_cd_err          -- ���b�Z�[�W
        ,iv_token_name1   => cv_tkn_pro_tok1            -- �g�[�N��1��
        ,iv_token_value1  => cv_pf_org);                -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- �݌ɑg�DID�擾����
    --========================================
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id( lt_inv_org_cd );
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   =>  cv_xxcoi_short_name       -- �A�v���P�[�V�����Z�k��
        ,iv_name          =>  cv_msg_org_id_err         -- ���b�Z�[�W
        ,iv_token_name1   =>  cv_tkn_nm_org_cd          -- �g�[�N��1��
        ,iv_token_value1  =>  lt_inv_org_cd);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 9.��v����ID�擾����
    --========================================
    ln_gl_set_of_bks_id := FND_PROFILE.VALUE( cv_pf_gl_set_of_bks_id );
    IF ( lt_inv_org_cd IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   => cv_xxcoi_short_name        -- �A�v���P�[�V�����Z�k��
        ,iv_name          => cv_msg_notfound_profile    -- ���b�Z�[�W
        ,iv_token_name1   => cv_tkn_pro_tok             -- �g�[�N��1��
        ,iv_token_value1  => cv_pf_gl_set_of_bks_id);   -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 10�DOPEN��v���ԏ��擾
    --==============================================================
    BEGIN
      SELECT  MIN(gps.start_date)  date_from,
              MAX(gps.end_date)    date_to
        INTO  ld_date_from,
              ld_date_to
        FROM  gl_period_statuses  gps,
              fnd_application_vl  fav
       WHERE   gps.application_id  = fav.application_id
         AND   gps.set_of_books_id = ln_gl_set_of_bks_id
         AND   gps.closing_status  = cv_open
         AND   gps.adjustment_period_flag = cv_val_n
         AND   fav.application_short_name = cv_ar;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
           iv_application   =>  cv_xxcoi_short_name       -- �A�v���P�[�V�����Z�k��
          ,iv_name          =>  cv_msg_period_err);       -- ���b�Z�[�W
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    --�G���[�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --��v����FROM-TO
    gd_date_from := ld_date_from;
    gd_date_to   := ld_date_to;
  EXCEPTION
    --*** �Ɩ����t�擾�G���[ ***
    WHEN non_business_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_non_business_date    -- ���b�Z�[�W
      );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--#################################  �Œ��O������ START   ####################################
--
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : �t�@�C���I�[�v��(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf      OUT NOCOPY VARCHAR2,             --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,             --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- �v���O������
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
    cv_file_mode_overwrite      CONSTANT VARCHAR2(1) := 'W';     -- �㏑
--
    -- *** ���[�J����O ***
    file_open_expt              EXCEPTION;      -- �t�@�C���I�[�v���G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- �t�@�C���I�[�v��
    --==================================
    BEGIN
      gt_file_handle := UTL_FILE.FOPEN(
                          location  => gt_output_directory           -- �f�B���N�g��
                         ,filename  => gt_csv_file_name              -- �t�@�C����
                         ,open_mode => cv_file_mode_overwrite);      -- �t�@�C�����[�h
    EXCEPTION
      WHEN OTHERS THEN
        RAISE file_open_expt;
    END;
    --
    --==================================
    -- �t�@�C���ԍ��̃`�F�b�N
    --==================================
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = FALSE ) THEN
      RAISE file_open_expt;
    END IF;
--
  EXCEPTION
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN file_open_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_file_open_error      -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_file_name            -- �g�[�N��1��
                     ,iv_token_value1 => gt_csv_file_name);          -- �g�[�N��1�l
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : open_order_info_cur
   * Description      : �󒍏��J�[�\���I�[�v��(A-3)
   ***********************************************************************************/
  PROCEDURE open_order_info_cur(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_order_info_cur'; -- �v���O������
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
    lv_table_name      VARCHAR2(50);
    lv_type_name       VARCHAR2(50);
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    order_extra_expt       EXCEPTION;    -- �󒍃f�[�^���o�G���[
    non_lookup_value_expt  EXCEPTION;    -- LOOKUP�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- �󒍏��J�[�\���I�[�v��
    --==================================
    BEGIN
      OPEN get_order_info_cur;
    EXCEPTION
      -- �f�[�^���o�G���[
      WHEN OTHERS THEN
        RAISE order_extra_expt;
    END;
--
  EXCEPTION
    --
    --*** �󒍏��J�[�\���I�[�v���G���[ ***
    WHEN order_extra_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- �A�v���P�[�V�����Z�k��
         ,iv_name        => cv_msg_sales_line               -- ���b�Z�[�WID
      );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_data_extra_error
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => lv_table_name
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => cv_blank);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000||SQLERRM);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_order_info_cur;
--
  /**********************************************************************************
   * Procedure Name   : output_for_order
   * Description      : CSV�t�@�C���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_for_order(
    it_order  IN  get_order_info_cur%ROWTYPE, --   �󒍏��
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_for_order'; -- �v���O������
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
    lv_buffer               VARCHAR2(5000);             -- �o�̓f�[�^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- CSV�t�@�C���f�[�^�o��
    -- ===============================
    lv_buffer :=
      cv_d_cot    || gt_company_code                                              || cv_d_cot    || cv_delimiter    -- �w�b�_�^�C�v
      || cv_d_cot || it_order.header_type_name                                    || cv_d_cot    || cv_delimiter    -- �w�b�_�^�C�v
      || cv_d_cot || it_order.source_name                                         || cv_d_cot    || cv_delimiter    -- �󒍃\�[�X
      || cv_d_cot || it_order.order_number                                        || cv_d_cot    || cv_delimiter    -- �󒍔ԍ�
      || cv_d_cot || it_order.account_number                                      || cv_d_cot    || cv_delimiter    -- �ڋq�R�[�h
      || cv_d_cot || it_order.sale_base_code                                      || cv_d_cot    || cv_delimiter    -- ���㋒�_
      || cv_d_cot || it_order.past_sale_base_code                                 || cv_d_cot    || cv_delimiter    -- �O�����㋒�_
      || cv_d_cot || it_order.delivery_base_code                                  || cv_d_cot    || cv_delimiter    -- �[�i���_
      || cv_d_cot || it_order.h_price_list_name                                   || cv_d_cot    || cv_delimiter    -- ���i�\(�w�b�_)
      || cv_d_cot || it_order.salesrep_number                                     || cv_d_cot    || cv_delimiter    -- �c�ƒS���ԍ�
      || cv_d_cot || it_order.resource_name                                       || cv_d_cot    || cv_delimiter    -- �c�ƒS��
      || cv_d_cot || TO_CHAR(it_order.ordered_date,cv_date_format_non_sep)        || cv_d_cot    || cv_delimiter    -- �󒍓�
      || cv_d_cot || it_order.cust_po_number                                      || cv_d_cot    || cv_delimiter    -- �ڋq�����ԍ� 
      || cv_d_cot || TO_CHAR(it_order.h_request_date,cv_date_format_non_sep)      || cv_d_cot    || cv_delimiter    -- �[�i�\���(�w�b�_)
      || cv_d_cot || it_order.flow_status_code                                    || cv_d_cot    || cv_delimiter    -- �󒍃w�b�_�X�e�[�^�X
      || cv_d_cot || TO_CHAR(it_order.booked_date,cv_datetime_format)             || cv_d_cot    || cv_delimiter    -- �L����
      || cv_d_cot || it_order.h_global_attribute4                                 || cv_d_cot    || cv_delimiter    -- ��No.(HHT)
      || cv_d_cot || it_order.h_global_attribute5                                 || cv_d_cot    || cv_delimiter    -- �������敪
      || cv_d_cot || it_order.line_number                                         || cv_d_cot    || cv_delimiter    -- �󒍖��ԍ�
      || cv_d_cot || it_order.shipment_number                                     || cv_d_cot    || cv_delimiter    -- �󒍖��׏o�הԍ�
      || cv_d_cot || it_order.segment1                                            || cv_d_cot    || cv_delimiter    -- �󒍕i��
      || cv_d_cot || it_order.l_attribute6                                        || cv_d_cot    || cv_delimiter    -- �q�R�[�h
      || cv_d_cot || it_order.line_type_name                                      || cv_d_cot    || cv_delimiter    -- �󒍖��׃^�C�v
      ||             it_order.ordered_quantity                                                   || cv_delimiter    -- �󒍐�
      ||             it_order.order_quantity_uom                                                 || cv_delimiter    -- �󒍒P��
      ||             it_order.unit_selling_price                                                 || cv_delimiter    -- �̔��P��
      || cv_d_cot || it_order.l_price_list_name                                   || cv_d_cot    || cv_delimiter    -- ���i�\(����)
      || cv_d_cot || TO_CHAR(it_order.schedule_ship_date,cv_date_format_non_sep)  || cv_d_cot    || cv_delimiter    -- �\��o�ד�
      || cv_d_cot || TO_CHAR(it_order.l_request_date,cv_date_format_non_sep)      || cv_d_cot    || cv_delimiter    -- �[�i�\���(����)
      || cv_d_cot || it_order.subinventory                                        || cv_d_cot    || cv_delimiter    -- �ۊǏꏊ
      || cv_d_cot || it_order.packing_instructions                                || cv_d_cot    || cv_delimiter    -- �o�׈˗�No
      || cv_d_cot || it_order.l_attribute4                                        || cv_d_cot    || cv_delimiter    -- �����\���
      || cv_d_cot || it_order.l_attribute5                                        || cv_d_cot    || cv_delimiter    -- ����敪
      || cv_d_cot || it_order.meaning                                             || cv_d_cot    || cv_delimiter    -- ����敪�E�v
      ||             TO_NUMBER(NVL(it_order.l_attribute10,'0'))                                  || cv_delimiter    -- ���P��
      || cv_d_cot || it_order.l_flow_status_code                                  || cv_d_cot    || cv_delimiter    -- �󒍖��׃X�e�[�^�X
      || cv_d_cot || TO_CHAR(gd_system_date,'YYYYMMDDHH24MISS')                   || cv_d_cot                       -- �A�g����
      ;
--
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => 'Data Put Start'
--    );
    -- CSV�t�@�C���o��
    UTL_FILE.PUT_LINE(
       file   => gt_file_handle
      ,buffer => lv_buffer
    );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => 'Data Put End'
--    );
    -- �o�͌����J�E���g
    gn_normal_cnt := gn_normal_cnt + 1;
    --
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END output_for_order;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : �t�@�C���N���[�Y(A-8)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    -- ===============================
    -- �t�@�C���N���[�Y
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gt_file_handle
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : expt_proc
   * Description      : ��O����(A-6)
   ***********************************************************************************/
  PROCEDURE expt_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'expt_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
      -- �t�@�C�����I�[�v������Ă���ꍇ
      UTL_FILE.FCLOSE(
        file => gt_file_handle
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END expt_proc;
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
    lv_buffer  VARCHAR2(5000);  -- �o�̓f�[�^
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_errbuf_wk  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_wk VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_wk  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_index      VARCHAR2(30);    -- �C���f�b�N�X�E�L�[
-- 2010/02/02 Ver.2.15 Add Start
    ld_pre_digestion_due_date     DATE;
    ld_digestion_due_date         DATE;
-- 2010/02/02 Ver.2.15 Add Start
--
    -- *** ���[�J����O ***
    sub_program_expt      EXCEPTION;
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
--
    BEGIN
      -- ===============================
      -- A-1.��������
      -- ===============================
      init(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      -- ===============================
      -- A-2.�t�@�C���I�[�v��
      -- ===============================
      file_open(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_buffer
    );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => 'Header Put End'
--    );
      -- ===============================
      -- A-3.�󒍏��J�[�\���I�[�v��
      -- ===============================
      open_order_info_cur(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      <<order_loop>>
      LOOP
        FETCH get_order_info_cur INTO get_order_info_rec;
        EXIT WHEN get_order_info_cur%NOTFOUND;
        gn_target_cnt := gn_target_cnt + 1;
--
        --==================================
        -- A-4.CSV�t�@�C���o�͏���
        --==================================
        output_for_order(
           it_order => get_order_info_rec     -- ������у��R�[�h�^
          ,ov_errbuf       => lv_errbuf              -- �G���[�E���b�Z�[�W
          ,ov_retcode      => lv_retcode             -- ���^�[���E�R�[�h
          ,ov_errmsg       => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE sub_program_expt;
        END IF;
--
      END LOOP order_loop;
      --
      CLOSE get_order_info_cur;
--
      -- ===============================
      -- A-5.�t�@�C���N���[�Y
      -- ===============================
      file_close(
         ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
    EXCEPTION
      WHEN sub_program_expt THEN
        -- �v���V�[�W�����ُ�I��
        -- ���b�Z�[�W��ޔ�
        lv_errbuf_wk := lv_errbuf;
        lv_retcode_wk := lv_retcode;
        lv_errmsg_wk := lv_errmsg;
--
        -- ===============================
        -- A-6.��O����
        -- ===============================
        expt_proc(
           ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W
          ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h
          ,ov_errmsg   => lv_errmsg);      -- ���[�U�E�G���[�E���b�Z�[�W
        IF ( lv_retcode = cv_status_error ) THEN
          IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
            -- �t�@�C�����I�[�v������Ă���ꍇ
            UTL_FILE.FCLOSE(
              file => gt_file_handle
            );
          END IF;
        END IF;
        gn_error_cnt := 1;
--
        -- ���b�Z�[�W��߂�
        lv_errbuf  := lv_errbuf_wk;
        lv_retcode := lv_retcode_wk;
        lv_errmsg  := lv_errmsg_wk;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
          IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
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
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_count
                    ,iv_token_name1  => cv_tkn_count_1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                    ,iv_token_name2  => cv_tkn_count_2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name3  => cv_tkn_count_3
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)
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
END XXCOS015A02C;
/
