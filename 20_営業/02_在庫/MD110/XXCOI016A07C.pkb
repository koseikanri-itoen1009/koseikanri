CREATE OR REPLACE PACKAGE BODY XXCOI016A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI016A07C(body)
 * Description      : ���b�g�ʈ������������ꂩ�̃X�e�[�^�X�ɂ�CSV�o�͂��s���܂��B
 * MD.050           : ���b�g�ʏo�׏��CSV�o��<MD050_COI_016_A07>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                             (A-1)
 *  chk_parameter          �p�����[�^�`�F�b�N                   (A-2)
 *  out_csv_base           ���b�g�ʈ������f�[�^���o           (A-3)
 *                         ���b�g�ʈ������CSV�ҏW�E�v���o��    (A-4)
 *  submain                ���C�������v���V�[�W��
 *                         �I������                             (A-5)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/28    1.0   Y.Koh            ���ō쐬
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
  cv_msg_sla                CONSTANT VARCHAR2(3) := '�^';
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
  -- ���[�U�[��`��O
  -- ===============================
  csv_no_data_expt          EXCEPTION;      -- CSV�Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI016A07C'; -- �p�b�P�[�W��
  -- �Q�ƃ^�C�v
  cv_type_list_header   CONSTANT VARCHAR2(30) :=  'XXCOI1_LOT_SHIP_INF_LISTHEADER';-- ���b�g�ʏo�׏�񌩏o��
  -- �Q�ƃ^�C�v�R�[�h
  cv_list_header_1      CONSTANT VARCHAR2(1)  :=  '1';                              -- ���b�g�ʏo�׏��CSV���o��1
  cv_list_header_2      CONSTANT VARCHAR2(1)  :=  '2';                              -- ���b�g�ʏo�׏��CSV���o��2
  cv_list_header_3      CONSTANT VARCHAR2(1)  :=  '3';                              -- ���b�g�ʏo�׏��CSV���o��3
  -- ���b�Z�[�W�֘A
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';                -- �A�v���P�[�V�����Z�k��(�݌�)
  cv_short_name_S       CONSTANT VARCHAR2(30) :=  'XXCOS';                -- �A�v���P�[�V�����Z�k��(�̔�)
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';     -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10471   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10471';     -- �p�����[�^. ��ԓ����敪���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10472   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10472';     -- �p�����[�^. �X�e�[�^�X���擾�G���[���b�Z�[�W
  ct_msg_parameter      CONSTANT VARCHAR2(30) :=  'APP-XXCOS1-14801';     -- �p�����[�^�o�̓��b�Z�[�W
  ct_msg_bace_code      CONSTANT VARCHAR2(30) :=  'APP-XXCOS1-00035';     -- ���_���擾�G���[���b�Z�[�W
  ct_msg_chain_code     CONSTANT VARCHAR2(30) :=  'APP-XXCOS1-00036';     -- �`�F�[���X���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10474   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10474';     -- �����iFrom�j�̌^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10475   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10475';     -- �����iTo�j�̌^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10606   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10606';     -- EDI��M���̌^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10370   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10370';     -- ���o�����擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10476   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10476';     -- �����������`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_00008   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00008';     -- �Ώۃf�[�^�������b�Z�[�W
  --�g�[�N��
  cv_tkn_code           CONSTANT VARCHAR2(100) := 'CODE';                   --���_�R�[�h
  cv_tkn_chain_code     CONSTANT VARCHAR2(100) := 'CHAIN_SHOP_CODE';        --�`�F�[���X�R�[�h
  cv_tkn_param1         CONSTANT VARCHAR2(100) := 'PARAM1';                 --��P���̓p�����[�^�^���e
  cv_tkn_param2         CONSTANT VARCHAR2(100) := 'PARAM2';                 --��Q���̓p�����[�^�^���e
  cv_tkn_param3         CONSTANT VARCHAR2(100) := 'PARAM3';                 --��R���̓p�����[�^
  cv_tkn_param4         CONSTANT VARCHAR2(100) := 'PARAM4';                 --��S���̓p�����[�^
  cv_tkn_param5         CONSTANT VARCHAR2(100) := 'PARAM5';                 --��T���̓p�����[�^�^���e
  cv_tkn_param6         CONSTANT VARCHAR2(100) := 'PARAM6';                 --��U���̓p�����[�^
  cv_tkn_param7         CONSTANT VARCHAR2(100) := 'PARAM7';                 --��V���̓p�����[�^�^���e
  cv_tkn_param8         CONSTANT VARCHAR2(100) := 'PARAM8';                 --��W���̓p�����[�^
--
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_bargain_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_BARGAIN_CLASS';
  ct_qct_sales_class        CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_SALE_CLASS';
  ct_qct_shipping_staus     CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOI1_SHIPPING_STATUS';
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                                  --�g�p�\
  -- ����R�[�h
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  --��ԓ����敪
  cv_bargain_class_all      CONSTANT VARCHAR2(2)  := '00';                    --�S��
  cv_bargain_class_teiban   CONSTANT VARCHAR2(2)  := '01';                    --���
  cv_bargain_class_tokubai  CONSTANT VARCHAR2(2)  := '02';                    --����
  --�t�H�[�}�b�g
  cv_fmt_date               CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  cv_fmt_datetime           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  -- ���̑�
  cv_cust_cls_cd_base       CONSTANT VARCHAR2(1)  := '1';                     -- �ڋq�N���X�R�[�h(1:���_)
  cv_cust_cls_cd_chain      CONSTANT VARCHAR2(2)  := '18';                    -- �ڋq�N���X�R�[�h(18:�`�F�[���X)
  cv_log                    CONSTANT VARCHAR2(3)  :=  'LOG';                  -- �R���J�����g�w�b�_�o�͐�
  cv_space                  CONSTANT VARCHAR2(1)  :=  ' ';                    -- ���p�X�y�[�X�P��
  cv_separate_code          CONSTANT VARCHAR2(1)  :=  ',';                    -- ��؂蕶���i�J���}�j
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���������ݒ�l
  gd_process_date           DATE;               -- �Ɩ��������t
--
  TYPE csv_data_type  IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;
  gt_csv_data         csv_data_type;                  -- CSV�f�[�^
--
  gr_lookup_values1   xxcoi_common_pkg.lookup_rec;    -- �N�C�b�N�R�[�h�}�X�^���i�[���R�[�h
  gr_lookup_values2   xxcoi_common_pkg.lookup_rec;    -- �N�C�b�N�R�[�h�}�X�^���i�[���R�[�h
  gr_lookup_values3   xxcoi_common_pkg.lookup_rec;    -- �N�C�b�N�R�[�h�}�X�^���i�[���R�[�h
--
  --�p�����[�^
  gv_login_base_code                  VARCHAR2(4);                    -- ���_
  gv_login_chain_store_code           VARCHAR2(4);                    -- �`�F�[���X
  gd_request_date_from                DATE;                           -- ����(From)
  gd_request_date_to                  DATE;                           -- ����(To)
  gt_bargain_class                    fnd_lookup_values.lookup_code%TYPE;
                                                                      -- ��ԓ����敪
  gt_bargain_class_name               fnd_lookup_values.meaning%TYPE; -- ��ԓ����敪����
  gd_edi_received_date                DATE;                           -- EDI��M��
  gt_shipping_sts_cd1                 fnd_lookup_values.attribute1%TYPE;
                                                                      -- �o�׏��X�e�[�^�X�R�[�h1
  gt_shipping_sts_cd2                 fnd_lookup_values.attribute2%TYPE;
                                                                      -- �o�׏��X�e�[�^�X�R�[�h2
  gt_shipping_sts_cd3                 fnd_lookup_values.attribute3%TYPE;
                                                                      -- �o�׏��X�e�[�^�X�R�[�h3
  gv_order_number                     VARCHAR2(10);                   -- �󒍔ԍ�
--
  gv_regular_sale_class_name          VARCHAR2(100);                  -- ��ԓ����敪��
--
  -- ===============================
  -- �J�[�\����`
  -- ===============================
  -- ���b�g�ʈ������f�[�^���o
  CURSOR  base_cur
  IS
    SELECT  xlri.slip_num                     slip_num
           ,xlri.order_number                 order_number
           ,xlri.parent_shipping_status       parent_shipping_status
           ,xlri.parent_shipping_status_name  parent_shipping_status_name
           ,xlri.base_code                    base_code
           ,xlri.base_name                    base_name
           ,xlri.whse_code                    whse_code
           ,xlri.whse_name                    whse_name
           ,xlri.location_code                location_code
           ,xlri.location_name                location_name
           ,xlri.shipping_status              shipping_status
           ,xlri.shipping_status_name         shipping_status_name
           ,xlri.chain_code                   chain_code
           ,xlri.chain_name                   chain_name
           ,xlri.shop_code                    shop_code
           ,xlri.shop_name                    shop_name
           ,xlri.customer_code                customer_code
           ,xlri.customer_name                customer_name
           ,xlri.center_code                  center_code
           ,xlri.center_name                  center_name
           ,xlri.area_code                    area_code
           ,xlri.area_name                    area_name
           ,xlri.shipped_date                 shipped_date
           ,xlri.arrival_date                 arrival_date
           ,xlri.item_div                     item_div
           ,xlri.item_div_name                item_div_name
           ,xlri.parent_item_code             parent_item_code
           ,xlri.parent_item_name             parent_item_name
           ,xlri.item_code                    item_code
           ,xlri.item_name                    item_name
           ,xlri.lot                          lot
           ,xlri.difference_summary_code      difference_summary_code
           ,xlri.case_in_qty                  case_in_qty
           ,xlri.case_qty                     case_qty
           ,xlri.singly_qty                   singly_qty
           ,xlri.summary_qty                  summary_qty
           ,xlri.before_ordered_quantity      before_ordered_quantity
           ,xlri.regular_sale_class_line      regular_sale_class_line
           ,xlri.regular_sale_class_name_line regular_sale_class_name_line
           ,xlri.edi_received_date            edi_received_date
           ,xlri.delivery_order_edi           delivery_order_edi
           ,xlri.reserve_performer_code       reserve_performer_code
           ,xlri.reserve_performer_name       reserve_performer_name
    FROM    xxcoi_lot_reserve_info  xlri
    WHERE   xlri.base_code = gv_login_base_code
    AND     ( xlri.chain_code  = gv_login_chain_store_code OR  gv_login_chain_store_code IS NULL )
    AND     TRUNC(xlri.arrival_date) BETWEEN gd_request_date_from  AND gd_request_date_to
    AND     ( xlri.regular_sale_class_line = gt_bargain_class  OR  gt_bargain_class = cv_bargain_class_all )
    AND     ( TRUNC(xlri.edi_received_date) = gd_edi_received_date OR  gd_edi_received_date IS NULL )
    AND     xlri.parent_shipping_status IN (gt_shipping_sts_cd1,gt_shipping_sts_cd2,gt_shipping_sts_cd3) 
    AND     ( xlri.order_number  = gv_order_number OR  gv_order_number IS NULL )
    ORDER BY  xlri.slip_num
             ,xlri.order_number
             ,xlri.base_code
             ,xlri.whse_code
             ,xlri.location_code
             ,xlri.parent_item_code
             ,xlri.item_code;
  --
  g_lot_reserve_info_rec      base_cur%ROWTYPE;
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������                             (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_login_base_code        IN  VARCHAR2        -- 1.���_
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.�`�F�[���X
   ,iv_request_date_from      IN  VARCHAR2        -- 3.�����iFrom�j
   ,iv_request_date_to        IN  VARCHAR2        -- 4.�����iTo�j
   ,iv_bargain_class          IN  VARCHAR2        -- 5.��ԓ����敪
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI��M��
   ,iv_shipping_status        IN  VARCHAR2        -- 7.�X�e�[�^�X
   ,iv_order_number           IN  VARCHAR2        -- 8.�󒍔ԍ�
   ,ov_errbuf                 OUT VARCHAR2        --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                OUT VARCHAR2        --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                 OUT VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_login_base_name        VARCHAR2(40);
    lv_login_chain_store_name VARCHAR2(40);
    lt_shipping_sts_name      fnd_lookup_values.meaning%TYPE;  -- �o�׏��X�e�[�^�X�E�v
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�Ɩ��������t�擾
    -- ===================================
    gd_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      -- �Ɩ��������t�擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --==================================
    -- 2.���_�A�`�F�[���X���̎擾
    --==================================
--
    --���_��
    BEGIN
      SELECT
        hp.party_name         base_name
      INTO
        lv_login_base_name
      FROM
        hz_parties hp
       ,hz_cust_accounts hca
      WHERE
        hca.customer_class_code = cv_cust_cls_cd_base
      AND
        hca.account_number      = iv_login_base_code
      AND
        hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_login_base_name := NULL;
    END;
--
    --�p�����[�^�̃`�F�[���X�R�[�h���ݒ肳��Ă���ꍇ�A���̂��擾����
    IF ( iv_login_chain_store_code IS NOT NULL )THEN
      BEGIN
        SELECT
          hp.party_name       chain_store_name
        INTO
          lv_login_chain_store_name
        FROM
          hz_parties          hp
         ,hz_cust_accounts    hca
         ,xxcmm_cust_accounts xca
        WHERE
          xca.chain_store_code    = iv_login_chain_store_code
        AND
          hca.cust_account_id     = xca.customer_id
        AND
          hca.customer_class_code = cv_cust_cls_cd_chain
        AND
          hp.party_id             = hca.party_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_login_chain_store_name := NULL;
      END;
    END IF;
--
    --==================================
    -- 3.��ԓ����敪���̎擾
    --==================================
--
    gt_bargain_class_name :=  xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type  =>  ct_qct_bargain_class  -- �Q�ƃ^�C�v
                                 ,iv_lookup_code  =>  iv_bargain_class      -- �Q�ƃR�[�h
                              );
--
    --==================================
    -- 4.�o�׏��X�e�[�^�X���̎擾
    --==================================
--
    gr_lookup_values1 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  ct_qct_shipping_staus
                           ,iv_lookup_code    =>  iv_shipping_status
                           ,id_enabled_date   =>  gd_process_date
                          );
--
    lt_shipping_sts_name  :=  gr_lookup_values1.meaning;
    gt_shipping_sts_cd1   :=  gr_lookup_values1.attribute1;
    gt_shipping_sts_cd2   :=  gr_lookup_values1.attribute2;
    gt_shipping_sts_cd3   :=  gr_lookup_values1.attribute3;
--
     --==================================
    -- 5.�p�����[�^�o��
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => cv_short_name_S
                                  ,iv_name               => ct_msg_parameter
                                  ,iv_token_name1        => cv_tkn_param1
                                  ,iv_token_value1       => iv_login_base_code || cv_msg_sla || lv_login_base_name
                                  ,iv_token_name2        => cv_tkn_param2
                                  ,iv_token_value2       => iv_login_chain_store_code || cv_msg_sla || lv_login_chain_store_name
                                  ,iv_token_name3        => cv_tkn_param3
                                  ,iv_token_value3       => iv_request_date_from
                                  ,iv_token_name4        => cv_tkn_param4
                                  ,iv_token_value4       => iv_request_date_to
                                  ,iv_token_name5        => cv_tkn_param5
                                  ,iv_token_value5       => iv_bargain_class || cv_msg_sla || gt_bargain_class_name
                                  ,iv_token_name6        => cv_tkn_param6
                                  ,iv_token_value6       => iv_edi_received_date
                                  ,iv_token_name7        => cv_tkn_param7
                                  ,iv_token_value7       => iv_shipping_status || cv_msg_sla || lt_shipping_sts_name
                                  ,iv_token_name8        => cv_tkn_param8
                                  ,iv_token_value8       => iv_order_number
                                 );
    --
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
    --1�s��
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => NULL
    );
--
    -- ���̎擾�G���[�n���h�����O
--
    -- ���_���擾�G���[��
    IF (lv_login_base_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name_S
                        ,iv_name          => ct_msg_bace_code
                        ,iv_token_name1   => cv_tkn_code
                        ,iv_token_value1  => iv_login_base_code
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �`�F�[���X���擾�G���[��
    IF (iv_login_chain_store_code IS NOT NULL AND lv_login_chain_store_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name_S
                        ,iv_name          => ct_msg_chain_code
                        ,iv_token_name1   => cv_tkn_chain_code
                        ,iv_token_value1  => iv_login_chain_store_code
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��ԓ����敪���擾�G���[��
    IF (gt_bargain_class_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name
                        ,iv_name          => cv_msg_xxcoi1_10471
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �o�׏��X�e�[�^�X���擾�G���[��
    IF (lt_shipping_sts_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name
                        ,iv_name          => cv_msg_xxcoi1_10472
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 6.�p�����[�^�ϊ�
    --==================================
    gv_login_base_code        := iv_login_base_code;
    gv_login_chain_store_code := iv_login_chain_store_code;
    gt_bargain_class          := iv_bargain_class;
    gv_order_number           := iv_order_number;
--
    BEGIN
      gd_request_date_from      := TO_DATE(iv_request_date_from,  cv_fmt_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                           iv_application   => cv_short_name
                          ,iv_name          => cv_msg_xxcoi1_10474
                        );
        lv_errbuf   :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    BEGIN
      gd_request_date_to        := TO_DATE(iv_request_date_to,    cv_fmt_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                           iv_application   => cv_short_name
                          ,iv_name          => cv_msg_xxcoi1_10475
                        );
        lv_errbuf   :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF ( iv_edi_received_date IS NOT NULL )THEN
      BEGIN
        gd_edi_received_date    := TO_DATE(iv_edi_received_date,  cv_fmt_datetime);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg   :=  xxccp_common_pkg.get_msg(
                             iv_application   => cv_short_name
                            ,iv_name          => cv_msg_xxcoi1_10606
                          );
          lv_errbuf   :=  lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    -- ===================================
    --  7.���o�����擾
    -- ===================================
    gr_lookup_values1 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_1
                           ,id_enabled_date   =>  gd_process_date
                          );
    --
    IF (gr_lookup_values1.meaning IS NULL) THEN
      -- ���o�����擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    gr_lookup_values2 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_2
                           ,id_enabled_date   =>  gd_process_date
                          );
    --
    IF (gr_lookup_values2.meaning IS NULL) THEN
      -- ���o�����擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    gr_lookup_values3 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_3
                           ,id_enabled_date   =>  gd_process_date
                          );
    --
    IF (gr_lookup_values3.meaning IS NULL) THEN
      -- ���o�����擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : �p�����[�^�`�F�b�N                   (A-2)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- ���t�t�]�`�F�b�N
    --==================================
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      -- ���o�����擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10476
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
  END chk_parameter;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_base
   * Description      : ���b�g�ʈ������f�[�^���o           (A-3)
   *                    ���b�g�ʈ������CSV�ҏW�E�v���o��    (A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_base(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_base'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_cnt        NUMBER;                                 -- CSV���R�[�h�s�ԍ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --
    OPEN  base_cur;
    FETCH base_cur  INTO  g_lot_reserve_info_rec;
    --
    IF (base_cur%NOTFOUND) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- ��s���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- �Ώۃf�[�^���擾����Ȃ������ꍇ�A�������I��
      CLOSE base_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  �P�s�ڕҏW�i���o���j
    -- ===================================
    gt_csv_data(1)  :=     gr_lookup_values1.attribute1                -- ���o���P
                        || cv_separate_code
                        || gr_lookup_values1.attribute2                -- ���o���Q
                        || cv_separate_code
                        || gr_lookup_values1.attribute3                -- ���o���R
                        || cv_separate_code
                        || gr_lookup_values1.attribute4                -- ���o���S
                        || cv_separate_code
                        || gr_lookup_values1.attribute5                -- ���o���T
                        || cv_separate_code
                        || gr_lookup_values1.attribute6                -- ���o���U
                        || cv_separate_code
                        || gr_lookup_values1.attribute7                -- ���o���V
                        || cv_separate_code
                        || gr_lookup_values1.attribute8                -- ���o���W
                        || cv_separate_code
                        || gr_lookup_values1.attribute9                -- ���o���X
                        || cv_separate_code
                        || gr_lookup_values1.attribute10               -- ���o���P�O
                        || cv_separate_code
                        || gr_lookup_values1.attribute11               -- ���o���P�P
                        || cv_separate_code
                        || gr_lookup_values1.attribute12               -- ���o���P�Q
                        || cv_separate_code
                        || gr_lookup_values1.attribute13               -- ���o���P�R
                        || cv_separate_code
                        || gr_lookup_values1.attribute14               -- ���o���P�S
                        || cv_separate_code
                        || gr_lookup_values1.attribute15               -- ���o���P�T
                        || cv_separate_code
                        || gr_lookup_values2.attribute1                -- ���o���P�U
                        || cv_separate_code
                        || gr_lookup_values2.attribute2                -- ���o���P�V
                        || cv_separate_code
                        || gr_lookup_values2.attribute3                -- ���o���P�W
                        || cv_separate_code
                        || gr_lookup_values2.attribute4                -- ���o���P�X
                        || cv_separate_code
                        || gr_lookup_values2.attribute5                -- ���o���Q�O
                        || cv_separate_code
                        || gr_lookup_values2.attribute6                -- ���o���Q�P
                        || cv_separate_code
                        || gr_lookup_values2.attribute7                -- ���o���Q�Q
                        || cv_separate_code
                        || gr_lookup_values2.attribute8                -- ���o���Q�R
                        || cv_separate_code
                        || gr_lookup_values2.attribute9                -- ���o���Q�S
                        || cv_separate_code
                        || gr_lookup_values2.attribute10               -- ���o���Q�T
                        || cv_separate_code
                        || gr_lookup_values2.attribute11               -- ���o���Q�U
                        || cv_separate_code
                        || gr_lookup_values2.attribute12               -- ���o���Q�V
                        || cv_separate_code
                        || gr_lookup_values2.attribute13               -- ���o���Q�W
                        || cv_separate_code
                        || gr_lookup_values2.attribute14               -- ���o���Q�X
                        || cv_separate_code
                        || gr_lookup_values2.attribute15               -- ���o���R�O
                        || cv_separate_code
                        || gr_lookup_values3.attribute1                -- ���o���R�P
                        || cv_separate_code
                        || gr_lookup_values3.attribute2                -- ���o���R�Q
                        || cv_separate_code
                        || gr_lookup_values3.attribute3                -- ���o���R�R
                        || cv_separate_code
                        || gr_lookup_values3.attribute4                -- ���o���R�S
                        || cv_separate_code
                        || gr_lookup_values3.attribute5                -- ���o���R�T
                        || cv_separate_code
                        || gr_lookup_values3.attribute6                -- ���o���R�U
                        || cv_separate_code
                        || gr_lookup_values3.attribute7                -- ���o���R�V
                        || cv_separate_code
                        || gr_lookup_values3.attribute8                -- ���o���R�W
                        || cv_separate_code
                        || gr_lookup_values3.attribute9                -- ���o���R�X
                        || cv_separate_code
                        || gr_lookup_values3.attribute10               -- ���o���S�O
                        || cv_separate_code
                        || gr_lookup_values3.attribute11               -- ���o���S�P
                        || cv_separate_code
                        || gr_lookup_values3.attribute12               -- ���o���S�Q
                        || cv_separate_code
                        || gr_lookup_values3.attribute13;              -- ���o���S�R
    --
    -- ===================================
    --  �Q�s�ڈȍ~�ҏW�i���b�g�ʏo�׏��j
    -- ===================================
    ln_cnt  :=  2;
    --
    <<set_csv_base_loop>>
    LOOP
      -- �I������
      EXIT set_csv_base_loop WHEN base_cur%NOTFOUND;
      --
      -- ��ԓ����敪��'01'�A'02'�̏ꍇ�͑O'0'���폜���ADB�l���o�͂���B
      IF( g_lot_reserve_info_rec.regular_sale_class_line IN( cv_bargain_class_teiban,cv_bargain_class_tokubai ) )THEN
        g_lot_reserve_info_rec.regular_sale_class_line 
          := SUBSTRB( g_lot_reserve_info_rec.regular_sale_class_line, 2, 1 );
        gv_regular_sale_class_name := g_lot_reserve_info_rec.regular_sale_class_name_line;
      -- ��L�ȊO�̏ꍇ�́A���̂��擾����
      ELSE
        gv_regular_sale_class_name
          := xxcoi_common_pkg.get_meaning( iv_lookup_type  => ct_qct_sales_class                              -- �Q�ƃ^�C�v
                                          ,iv_lookup_code  => g_lot_reserve_info_rec.regular_sale_class_line  -- �Q�ƃR�[�h
                                          );
      END IF;
      --
      -- ���׃��R�[�h�ݒ�
      gt_csv_data(ln_cnt) :=  g_lot_reserve_info_rec.slip_num                     -- �`�[No
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.order_number                 -- �󒍔ԍ�
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_shipping_status       -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_shipping_status_name  -- �o�׏��X�e�[�^�X��(�󒍔ԍ��P��)
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.base_code                    -- ���_�R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.base_name                    -- ���_��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.whse_code                    -- �ۊǏꏊ�R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.whse_name                    -- �ۊǏꏊ��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.location_code                -- ���P�[�V�����R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.location_name                -- ���P�[�V������
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shipping_status              -- �o�׏��X�e�[�^�X
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shipping_status_name         -- �o�׏��X�e�[�^�X��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.chain_code                   -- �`�F�[���X�R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.chain_name                   -- �`�F�[���X��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shop_code                    -- �X�܃R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shop_name                    -- �X�ܖ�
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.customer_code                -- �ڋq�R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.customer_name                -- �ڋq��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.center_code                  -- �Z���^�[�R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.center_name                  -- �Z���^�[��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.area_code                    -- �n��R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.area_name                    -- �n�於��
                          ||  cv_separate_code
                          ||  TO_CHAR(g_lot_reserve_info_rec.shipped_date,cv_fmt_date)
                                                                                  -- �o�ד�
                          ||  cv_separate_code
                          ||  TO_CHAR(g_lot_reserve_info_rec.arrival_date,cv_fmt_date)
                                                                                  -- ����
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_div                     -- ���i�敪
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_div_name                -- ���i�敪��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_item_code             -- �e�i�ڃR�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_item_name             -- �e�i�ږ���
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_code                    -- �q�i�ڃR�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_name                    -- �q�i�ږ���
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.lot                          -- �ܖ�����
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.difference_summary_code      -- �ŗL�L��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.case_in_qty                  -- ����
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.case_qty                     -- �P�[�X��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.singly_qty                   -- �o����
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.summary_qty                  -- ����
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.before_ordered_quantity      -- �����O�󒍐���
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.regular_sale_class_line      -- ��ԓ����敪
                          ||  cv_separate_code
                          ||  gv_regular_sale_class_name                          -- ��ԓ����敪��
                          ||  cv_separate_code
                          ||  TO_CHAR(g_lot_reserve_info_rec.edi_received_date,cv_fmt_date)
                                                                                  -- EDI��M��
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.delivery_order_edi           -- �z����(EDI)
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.reserve_performer_code       -- �������s�҃R�[�h
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.reserve_performer_name;      -- �������s�Җ�
      --
      -- �ϐ��J�E���g�A�b�v
      ln_cnt  :=  ln_cnt + 1;
      --
      -- ���������J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- �f�[�^�擾
      FETCH base_cur  INTO  g_lot_reserve_info_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE base_cur;
    --
    -- ===================================
    --  CSV�o��
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--
    -- *** CSV�Ώۃf�[�^�Ȃ���O ***
    WHEN csv_no_data_expt THEN
      -- ����ŁA�{�v���V�[�W�����I��
      NULL;
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
      IF (base_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv_base;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   *                    �I������                             (A-5)
   **********************************************************************************/
  PROCEDURE submain(
    iv_login_base_code        IN  VARCHAR2        -- 1.���_
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.�`�F�[���X
   ,iv_request_date_from      IN  VARCHAR2        -- 3.�����iFrom�j
   ,iv_request_date_to        IN  VARCHAR2        -- 4.�����iTo�j
   ,iv_bargain_class          IN  VARCHAR2        -- 5.��ԓ����敪
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI��M��
   ,iv_shipping_status        IN  VARCHAR2        -- 7.�X�e�[�^�X
   ,iv_order_number           IN  VARCHAR2        -- 8.�󒍔ԍ�
   ,ov_errbuf                 OUT VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                OUT VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                 OUT VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --  1.��������(A-1)
    -- ===============================
    init(
      iv_login_base_code        =>  iv_login_base_code        -- 1.���_
     ,iv_login_chain_store_code =>  iv_login_chain_store_code -- 2.�`�F�[���X
     ,iv_request_date_from      =>  iv_request_date_from      -- 3.�����iFrom�j
     ,iv_request_date_to        =>  iv_request_date_to        -- 4.�����iTo�j
     ,iv_bargain_class          =>  iv_bargain_class          -- 5.��ԓ����敪
     ,iv_edi_received_date      =>  iv_edi_received_date      -- 6.EDI��M��
     ,iv_shipping_status        =>  iv_shipping_status        -- 7.�X�e�[�^�X
     ,iv_order_number           =>  iv_order_number           -- 8.�󒍔ԍ�
     ,ov_errbuf                 =>  lv_errbuf                 --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode                =>  lv_retcode                --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                 =>  lv_errmsg                 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  2.�p�����[�^�`�F�b�N(A-2)
    -- ===============================
    chk_parameter(
      ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    --  3.���b�g�ʈ������CSV�ҏW�E�v���o��(A-3, A-4)
    -- ====================================
    out_csv_base(
      ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  4.�I������(A-5)
    -- ===============================
    -- ���팏����ݒ�
    gn_normal_cnt := gn_target_cnt;
    --
  EXCEPTION
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
    errbuf                    OUT VARCHAR2        -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                   OUT VARCHAR2        -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_login_base_code        IN  VARCHAR2        -- 1.���_
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.�`�F�[���X
   ,iv_request_date_from      IN  VARCHAR2        -- 3.�����iFrom�j
   ,iv_request_date_to        IN  VARCHAR2        -- 4.�����iTo�j
   ,iv_bargain_class          IN  VARCHAR2        -- 5.��ԓ����敪
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI��M��
   ,iv_shipping_status        IN  VARCHAR2        -- 7.�X�e�[�^�X
   ,iv_order_number           IN  VARCHAR2        -- 8.�󒍔ԍ�
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
       iv_which   =>  cv_log
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
        iv_login_base_code        =>  iv_login_base_code        -- 1.���_
       ,iv_login_chain_store_code =>  iv_login_chain_store_code -- 2.�`�F�[���X
       ,iv_request_date_from      =>  iv_request_date_from      -- 3.�����iFrom�j
       ,iv_request_date_to        =>  iv_request_date_to        -- 4.�����iTo�j
       ,iv_bargain_class          =>  iv_bargain_class          -- 5.��ԓ����敪
       ,iv_edi_received_date      =>  iv_edi_received_date      -- 6.EDI��M��
       ,iv_shipping_status        =>  iv_shipping_status        -- 7.�X�e�[�^�X
       ,iv_order_number           =>  iv_order_number           -- 8.�󒍔ԍ�
       ,ov_errbuf                 =>  lv_errbuf                 -- �G���[�E���b�Z�[�W             --# �Œ� #
       ,ov_retcode                =>  lv_retcode                -- ���^�[���E�R�[�h               --# �Œ� #
       ,ov_errmsg                 =>  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      -- ��������
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- ��s���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_space
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
       which  => FND_FILE.LOG
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
END XXCOI016A07C;
/
