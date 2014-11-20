CREATE OR REPLACE PACKAGE BODY XXCOS003A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A02C(body)
 * Description      : �P���}�X�^IF�o�́i�f�[�^���o�j
 * MD.050           : �P���}�X�^IF�o�́i�f�[�^���o�j MD050_COS_003_A02
 * Version          : 1.2
 *
 * Program List     
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-0�D��������
 *  proc_main_loop         A-1�D�f�[�^���o
 *  proc_insert_upm_work   A-4�D�P���}�X�^���[�N�e�[�u���o�^
 *  proc_update_upm_work   A-3�D�P���}�X�^���[�N�e�[�u���X�V
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05   1.0    K.Okaguchi       �V�K�쐬
 *  2009/02/23   1.1    K.Okaguchi       [��QCOS_111] ��݌ɕi�ڂ𒊏o���Ȃ��悤�ɂ���B
 *  2009/02/24   1.2    T.Nakamura       [��QCOS_130] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
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
  gn_target_cnt    NUMBER DEFAULT 0;                    -- �Ώی���
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0;                    -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- �X�L�b�v����
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A02C'; -- �p�b�P�[�W��
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- �A�v���P�[�V������
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
  cv_correct              CONSTANT VARCHAR2(30) := '1';                   --��������敪�@=�@1�i�����j
  cv_invoice_class_dliv   CONSTANT VARCHAR2(1)  := '1';                   --�[�i�`�[�敪 = 1(�[�i)
  cv_invoice_class_d_co   CONSTANT VARCHAR2(1)  := '3';                   --�[�i�`�[�敪 = 3(�[�i����)
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ���b�N�G���[
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    --���b�N�擾�G���[
  cv_msg_insert_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';    --�f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_select_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    --�f�[�^���o�G���[���b�Z�[�W
  cv_tkn_tm_w_tbl         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10852';    -- �P���}�X�^���[�N�e�[�u��  
  cv_tkn_exp_l_tbl        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10701';    -- �̔����і��׃e�[�u��
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- �ڋq�R�[�h
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- �i���R�[�h
  cv_tkn_exp_line_id      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10702';    -- �̔����і���ID
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- �p�����[�^�Ȃ�
  cv_tkn_sales_cls_nml    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10703';    -- �ʏ�
  cv_tkn_sales_cls_sls    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10704';    -- ����
  cv_tkn_fnd_lookup_v     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00066';    -- �N�C�b�N�R�[�h�e�[�u��
  cv_tkn_lookup_type      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00075';    -- �N�C�b�N�R�[�h.�Q�ƃ^�C�v
  cv_tkn_meaning          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00089';    -- �N�C�b�N�R�[�h.���e
  cv_lookup_type_gyotai   CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A02'; --�Q�ƃ^�C�v�@�Ƒԏ�����
  cv_lookup_type_no_inv   CONSTANT VARCHAR2(30) := 'XXCOS1_NO_INV_ITEM_CODE'; --�Q�ƃ^�C�v�@��݌ɕi��
  cv_lookup_type_sals_cls CONSTANT VARCHAR2(30) := 'XXCOS1_SALE_CLASS';   -- �Q�ƃ^�C�v�@����敪
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--���b�Z�[�W�o�͗p�L�[���
  gv_msg_tkn_tm_w_tbl         fnd_new_messages.message_text%TYPE   ;--'�P���}�X�^���[�N�e�[�u��'
  gv_msg_tkn_exp_l_tbl        fnd_new_messages.message_text%TYPE   ;--'�̔����і��׃e�[�u��'
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ;--'�ڋq�R�[�h'
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ;--'�i���R�[�h'
  gv_msg_tkn_exp_line_id      fnd_new_messages.message_text%TYPE   ;--'�̔����і���ID'
  gv_msg_tkn_sales_cls_nml    fnd_new_messages.message_text%TYPE   ;--�ʏ�
  gv_msg_tkn_sales_cls_sls    fnd_new_messages.message_text%TYPE   ;--����
  gv_msg_tkn_fnd_lookup_v     fnd_new_messages.message_text%TYPE   ;--�N�C�b�N�R�[�h
  gv_msg_tkn_lookup_type      fnd_new_messages.message_text%TYPE   ;--�Q�ƃ^�C�v
  gv_msg_tkn_meaning          fnd_new_messages.message_text%TYPE   ;--���e
  gv_customer_number          xxcos_unit_price_mst_work.customer_number%TYPE;
  gv_item_code                xxcos_unit_price_mst_work.item_code%TYPE;
  gv_tkn_lock_table           fnd_new_messages.message_text%TYPE   ;

  gd_nml_prev_dlv_date        xxcos_unit_price_mst_work.nml_prev_dlv_date%TYPE;     --�ʏ� �O�� �[�i��
  gd_nml_bef_prev_dlv_date    xxcos_unit_price_mst_work.nml_bef_prev_dlv_date%TYPE; --�ʏ� �O�X�� �[�i��
  gd_sls_prev_dlv_date        xxcos_unit_price_mst_work.sls_prev_dlv_date%TYPE;     --���� �O�� �[�i��
  gd_sls_bef_prev_dlv_date    xxcos_unit_price_mst_work.sls_bef_prev_dlv_date%TYPE; --���� �O�X�� �[�i��
  gd_nml_prev_clt_date        xxcos_unit_price_mst_work.nml_prev_clt_date%TYPE;     --�ʏ� �O�� �쐬��
  gd_nml_bef_prev_clt_date    xxcos_unit_price_mst_work.nml_bef_prev_clt_date%TYPE; --�ʏ� �O�X�� �쐬��
  gd_sls_prev_clt_date        xxcos_unit_price_mst_work.sls_prev_clt_date%TYPE;     --���� �O�� �쐬��
  gd_sls_bef_prev_clt_date    xxcos_unit_price_mst_work.sls_bef_prev_clt_date%TYPE; --���� �O�X�� �쐬��
  gv_sales_cls_nml            fnd_lookup_values.lookup_code%TYPE;
  gv_sales_cls_sls            fnd_lookup_values.lookup_code%TYPE;
  gv_bf_sales_exp_header_id   xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
  gn_warn_tran_count          NUMBER DEFAULT 0;
  gn_new_warn_count           NUMBER DEFAULT 0;
  gn_tran_count               NUMBER DEFAULT 0;
  gn_unit_price               NUMBER;
  gn_skip_cnt                 NUMBER DEFAULT 0;                    -- �P���}�X�^�X�V�ΏۊO����
--
--�J�[�\��
  CURSOR main_cur
  IS
    SELECT  xseh.sales_exp_header_id          sales_exp_header_id               --�̔����уw�b�_ID
           ,xseh.ship_to_customer_code        ship_to_customer_code             --�ڋq�y�[�i��z
           ,xseh.orig_delivery_date           delivery_date                     --�[�i���i�I���W�i���[�i���j
           ,xseh.tax_rate                     tax_rate                          --����ŗ�
           ,xsel.item_code                    item_code                         --�i�ڃR�[�h
           ,xsel.standard_unit_price_excluded standard_unit_price_excluded      --�Ŕ���P��
           ,xsel.standard_unit_price          standard_unit_price               --��P��
           ,xsel.standard_qty                 standard_qty                      --�����
           ,xsel.creation_date                creation_date                     --�쐬��
           ,xsel.sales_exp_line_id            sales_exp_line_id                 --�̔����і���ID
           ,xsel.sales_class                  sales_class                       --����敪
    FROM    xxcos_sales_exp_headers xseh
           ,xxcos_sales_exp_lines   xsel
    WHERE   (xseh.cancel_correct_class IS NULL
           OR 
             xseh.order_no_hht         IS NULL )
    AND     xseh.dlv_invoice_class = cv_invoice_class_dliv
    AND     xseh.sales_exp_header_id =  xsel.sales_exp_header_id
    AND     xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls)
    AND     xsel.unit_price_mst_flag = cv_flag_off
    AND     NOT EXISTS
            (SELECT NULL 
             FROM   fnd_lookup_values flvl
             WHERE  flvl.lookup_type         = cv_lookup_type_gyotai
             AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
             AND    flvl.language            = USERENV('LANG')
             AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                              AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
             AND     flvl.enabled_flag        = cv_flag_on
             AND xseh.cust_gyotai_sho = meaning ) 
    AND     NOT EXISTS
            (SELECT NULL 
             FROM   fnd_lookup_values flvl
             WHERE  flvl.lookup_type         = cv_lookup_type_no_inv
             AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
             AND    flvl.language            = USERENV('LANG')
             AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                              AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
             AND     flvl.enabled_flag        = cv_flag_on
             AND xsel.item_code = lookup_code ) 
    UNION
    SELECT  xseh.sales_exp_header_id          sales_exp_header_id               --�̔����уw�b�_ID
           ,xseh.ship_to_customer_code        ship_to_customer_code             --�ڋq�y�[�i��z
           ,xseh.orig_delivery_date           delivery_date                     --�[�i���i�I���W�i���[�i���j
           ,xseh.tax_rate                     tax_rate                          --����ŗ�
           ,xsel.item_code                    item_code                         --�i�ڃR�[�h
           ,xsel.standard_unit_price_excluded standard_unit_price_excluded      --�Ŕ���P��
           ,xsel.standard_unit_price          standard_unit_price               --��P��
           ,xsel.standard_qty                 standard_qty                      --�����
           ,xsel.creation_date                creation_date                     --�쐬��
           ,xsel.sales_exp_line_id            sales_exp_line_id                 --�̔����і���ID
           ,xsel.sales_class                  sales_class                       --����敪
    FROM    xxcos_sales_exp_headers xseh
           ,xxcos_sales_exp_lines   xsel
           ,(SELECT  MAX(xseh.digestion_ln_number) digestion_ln_number
                    ,inl2.order_no_hht
             FROM   xxcos_sales_exp_headers xseh
                   ,(SELECT xseh.order_no_hht order_no_hht
                     FROM    xxcos_sales_exp_headers xseh
                            ,xxcos_sales_exp_lines   xsel
                     WHERE   xseh.cancel_correct_class = cv_correct
                     AND     xseh.digestion_ln_number  = 1
                     AND     xseh.dlv_invoice_class IN (cv_invoice_class_dliv,cv_invoice_class_d_co)
                     AND     xsel.unit_price_mst_flag  = cv_flag_off
                     AND     NOT EXISTS(SELECT NULL
                                        FROM   fnd_lookup_values       flvl
                                        WHERE  flvl.lookup_type       = cv_lookup_type_gyotai
                                        AND    flvl.security_group_id = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type
                                                                                                ,flvl.view_application_id)
                                        AND     flvl.language             = USERENV('LANG')
                                        AND     TRUNC(SYSDATE)            BETWEEN flvl.start_date_active
                                                                          AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
                                        AND     flvl.enabled_flag         = cv_flag_on
                                        AND     xseh.cust_gyotai_sho      = flvl.meaning)
                     AND     xseh.sales_exp_header_id  =  xsel.sales_exp_header_id
                   ) inl2
             WHERE   xseh.order_no_hht = inl2.order_no_hht
             GROUP BY inl2.order_no_hht
            ) inl1
    WHERE   inl1.order_no_hht        = xseh.order_no_hht
    AND     inl1.digestion_ln_number = xseh.digestion_ln_number
    AND     xseh.sales_exp_header_id = xsel.sales_exp_header_id
    AND     xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls)
    AND     NOT EXISTS(SELECT NULL 
                       FROM   fnd_lookup_values flvl
                       WHERE  flvl.lookup_type         = cv_lookup_type_no_inv
                       AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
                       AND    flvl.language            = USERENV('LANG')
                       AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                                        AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
                       AND     flvl.enabled_flag        = cv_flag_on
                       AND xsel.item_code = lookup_code ) 
    ORDER BY sales_exp_header_id
    ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
    main_rec main_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
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
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***

    -- *** ���[�J���ϐ� ***
    lv_msg_tkn_sales_cls fnd_new_messages.message_text%TYPE;
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

-- 2009/02/24 T.Nakamura Ver.1.2 add start
    --��s
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --��s
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- �}���`�o�C�g�̌Œ�l�����b�Z�[�W���擾
    --==============================================================
    gv_msg_tkn_tm_w_tbl         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_w_tbl
                                                           );
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
    gv_msg_tkn_exp_l_tbl        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_l_tbl
                                                           );
    gv_msg_tkn_exp_line_id      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_line_id
                                                           );
    gv_msg_tkn_sales_cls_nml    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_nml
                                                           );
    gv_msg_tkn_sales_cls_sls    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_sls
                                                           );
    gv_msg_tkn_fnd_lookup_v     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_fnd_lookup_v
                                                           );
    gv_msg_tkn_lookup_type      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lookup_type
                                                           );
    gv_msg_tkn_meaning          := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_meaning
                                                           );
    --==============================================================
    -- ����敪���Q�ƃ^�C�v���擾
    --==============================================================
    BEGIN
   --�ʏ�
      lv_msg_tkn_sales_cls := gv_msg_tkn_sales_cls_nml; --���b�Z�[�W�p�ϐ��Ɋi�[
      SELECT flvl.lookup_code lookup_code
      INTO   gv_sales_cls_nml
      FROM   fnd_lookup_values       flvl
      WHERE  flvl.lookup_type         = cv_lookup_type_sals_cls
      AND    flvl.meaning             = gv_msg_tkn_sales_cls_nml
      AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
      AND    flvl.language            = USERENV('LANG')
      AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                      AND NVL(flvl.end_date_active,TRUNC(SYSDATE))
      AND    flvl.enabled_flag        = cv_flag_on
      ;
      
     --����
      lv_msg_tkn_sales_cls := gv_msg_tkn_sales_cls_sls; --���b�Z�[�W�p�ϐ��Ɋi�[
      SELECT flvl.lookup_code lookup_code
      INTO   gv_sales_cls_sls
      FROM   fnd_lookup_values flvl
      WHERE  flvl.lookup_type         = cv_lookup_type_sals_cls
      AND    flvl.meaning             = gv_msg_tkn_sales_cls_sls
      AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
      AND    flvl.language            = USERENV('LANG')
      AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                      AND NVL(flvl.end_date_active,TRUNC(SYSDATE))
      AND    flvl.enabled_flag        = cv_flag_on
      ;
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info                    --�L�[���
                                        ,iv_item_name1  => gv_msg_tkn_lookup_type         --���ږ���1
                                        ,iv_data_value1 => cv_lookup_type_sals_cls        --�f�[�^�̒l1
                                        ,iv_item_name2  => gv_msg_tkn_meaning             --���ږ���2
                                        ,iv_data_value2 => lv_msg_tkn_sales_cls           --�f�[�^�̒l2                                            
                                        );
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_select_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_fnd_lookup_v
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        RAISE;
    END;
--
--
  EXCEPTION
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
   * Procedure Name   : proc_insert_upm_work
   * Description      : A-4�D�P���}�X�^���[�N�e�[�u���o�^
   ***********************************************************************************/
  PROCEDURE proc_insert_upm_work(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_insert_upm_work'; -- �v���O������
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
      -- ===============================
      --A-4�D�P���}�X�^���[�N�e�[�u���o�^
      -- ===============================
        BEGIN
          CASE 
            WHEN main_rec.sales_class   = gv_sales_cls_nml THEN
              INSERT INTO xxcos_unit_price_mst_work(
                 customer_number          --�ڋq�R�[�h
                ,item_code                --�i���R�[�h
                ,nml_prev_unit_price      --�ʏ�@�O��@�P���@
                ,nml_prev_dlv_date        --�ʏ�@�O��@�[�i�N�����@
                ,nml_prev_qty             --�ʏ�@�O��@���ʁ@
                ,nml_prev_clt_date        --�ʏ�@�O��@�쐬��
                ,file_output_flag         --�t�@�C���o�͍σt���O
                --WHO�J����
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )VALUES(
                 main_rec.ship_to_customer_code        --�ڋq�R�[�h
                ,main_rec.item_code                    --�i���R�[�h
                ,gn_unit_price                         --�ʏ�@�O��@�P���@
                ,main_rec.delivery_date                --�ʏ�@�O��@�[�i�N�����@
                ,main_rec.standard_qty                 --�ʏ�@�O��@���ʁ@
                ,main_rec.creation_date                --�ʏ�@�O��@�쐬��
                ,cv_flag_off                           --�t�@�C���o�͍σt���O
                ,cn_created_by
                ,cd_creation_date
                ,cn_last_updated_by
                ,cd_last_update_date
                ,cn_last_update_login
                ,cn_request_id
                ,cn_program_application_id
                ,cn_program_id
                ,cd_program_update_date
               );
            WHEN main_rec.sales_class   = gv_sales_cls_sls THEN
              INSERT INTO xxcos_unit_price_mst_work(
                 customer_number          --�ڋq�R�[�h
                ,item_code                --�i���R�[�h
                ,sls_prev_unit_price      --�����@�O��@�P���@
                ,sls_prev_dlv_date        --�����@�O��@�[�i�N�����@
                ,sls_prev_qty             --�����@�O��@���ʁ@
                ,sls_prev_clt_date        --�����@�O��@�쐬��
                ,file_output_flag         --�t�@�C���o�͍σt���O
                --WHO�J����
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )VALUES(
                 main_rec.ship_to_customer_code        --�ڋq�R�[�h
                ,main_rec.item_code                    --�i���R�[�h
                ,gn_unit_price                         --�����@�O��@�P���@
                ,main_rec.delivery_date                --�����@�O��@�[�i�N�����@
                ,main_rec.standard_qty                 --�����@�O��@���ʁ@
                ,main_rec.creation_date                --�����@�O��@�쐬��
                ,cv_flag_off                           --�t�@�C���o�͍σt���O
                ,cn_created_by
                ,cd_creation_date
                ,cn_last_updated_by
                ,cd_last_update_date
                ,cn_last_update_login
                ,cn_request_id
                ,cn_program_application_id
                ,cn_program_id
                ,cd_program_update_date
               );
          END CASE;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                    --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_cust_code           --���ږ���1
                                            ,iv_data_value1 => main_rec.ship_to_customer_code --�f�[�^�̒l1
                                            ,iv_item_name2  => gv_msg_tkn_item_code           --���ږ���2
                                            ,iv_data_value2 => main_rec.item_code             --�f�[�^�̒l2                                            
                                            );
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_insert_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_tm_w_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            ov_retcode := cv_status_warn;
            ov_errmsg  := lv_errmsg;
        END;
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
  END proc_insert_upm_work;
  
  /**********************************************************************************
   * Procedure Name   : proc_update_upm_work
   * Description      : A-3�D�P���}�X�^���[�N�e�[�u���X�V
   ***********************************************************************************/
  PROCEDURE proc_update_upm_work(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_update_upm_work'; -- �v���O������
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
    ln_update_pattern NUMBER;
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
    ln_update_pattern := '';
      -- ===============================
      --A-3�D�P���}�X�^���[�N�e�[�u���X�V
      -- ===============================
 --�@����敪���ʏ킩�A�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@
 --�����V�������R�[�h�����������ꍇ
    IF    (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date > gd_nml_prev_dlv_date)
    THEN 
      ln_update_pattern := 1;
      
 --�A����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@
 --�����Â��A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date >  gd_nml_bef_prev_dlv_date)
    THEN 
      ln_update_pattern := 2;
      
 --�B����敪���������A�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@
 --�����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls 
    AND    main_rec.delivery_date > gd_sls_prev_dlv_date)
    THEN 
      ln_update_pattern := 3;
      
 --�C����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@
 --�����Â��A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls 
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date)
    THEN 
      ln_update_pattern := 4;
      
 --�D����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���Ɂu�ʏ�@�O��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date > gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_prev_clt_date)
    THEN 
      ln_update_pattern := 1;
      
 --�E����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date > gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date)
    THEN 
      ln_update_pattern := 2;
      
 --�F����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_prev_clt_date)
    THEN 
      ln_update_pattern := 1;
      
 --�G����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date
    AND    main_rec.creation_date > gd_nml_bef_prev_clt_date)
    THEN 
      ln_update_pattern := 2;
      
 --�H����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date
    AND    main_rec.creation_date < gd_nml_bef_prev_clt_date)
    THEN 
      NULL;
      
 --�I����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls 
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_prev_clt_date)
    THEN 
      ln_update_pattern := 3;
      
 --�J����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls 
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date)
    THEN 
      ln_update_pattern := 4;
      
 --�K����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls 
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_prev_clt_date)
    THEN 
      ln_update_pattern := 3;
      
 --�L����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls 
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date
    AND    main_rec.creation_date > gd_sls_bef_prev_clt_date)
    THEN 
      ln_update_pattern := 4;
      
 --�M����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls 
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date
    AND    main_rec.creation_date < gd_sls_bef_prev_clt_date)
    THEN 
      NULL;

 --�N����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 --�����Â����R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml 
    AND    main_rec.delivery_date   <  gd_nml_prev_dlv_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 2;

 --�O����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_bef_prev_clt_date)
    THEN 
      ln_update_pattern := 2;
      
 --�P����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml 
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_bef_prev_clt_date)
    THEN 
      NULL;
      
 --�Q����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@
 -- �����Â����R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   <  gd_sls_prev_dlv_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 4;
      
 --�R����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_bef_prev_clt_date)
    THEN 
      ln_update_pattern := 4;
      
 --�S����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_bef_prev_clt_date)
    THEN 
      NULL;
      
 --21.����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����ݒ�A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml 
    AND    main_rec.delivery_date   =  gd_nml_prev_dlv_date
    AND    main_rec.creation_date   >  gd_nml_prev_clt_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 1;
      
 --22.����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����ݒ�A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml 
    AND    main_rec.delivery_date   =  gd_nml_prev_dlv_date
    AND    main_rec.creation_date   <  gd_nml_prev_clt_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 2;
      
 --23.����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����ݒ�A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   =  gd_sls_prev_dlv_date
    AND    main_rec.creation_date   >  gd_sls_prev_clt_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 3;
            
 --24.����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����ݒ�A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   =  gd_sls_prev_dlv_date
    AND    main_rec.creation_date   <  gd_sls_prev_clt_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 4;
      
 --25.����敪���ʏ킩�A�P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class =  gv_sales_cls_nml 
    AND    gd_nml_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 1;
      
 --26.����敪���������A�P���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class =  gv_sales_cls_sls
    AND    gd_sls_prev_dlv_date IS NULL)
    THEN 
      ln_update_pattern := 3;
            
  --��L�ȊO
    ELSE
      NULL;
    END IF;
    BEGIN
    --�p�^�[���P
      CASE 
        WHEN ln_update_pattern = 1 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    nml_prev_unit_price        = gn_unit_price                         --�ʏ�@�O��@�P���@
                ,nml_prev_dlv_date          = main_rec.delivery_date                --�ʏ�@�O��@�[�i�N�����@
                ,nml_prev_qty               = main_rec.standard_qty                 --�ʏ�@�O��@���ʁ@
                ,nml_prev_clt_date          = main_rec.creation_date                --�ʏ�@�O��@�쐬��
                ,nml_bef_prev_dlv_date      = nml_prev_dlv_date                     --�ʏ�@�O�X��@�[�i�N�����@
                ,nml_bef_prev_qty           = nml_prev_qty                          --�ʏ�@�O�X��@���ʁ@
                ,nml_bef_prev_clt_date      = nml_prev_clt_date                     --�ʏ�@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number                    
          AND    item_code                  = gv_item_code                          
          ;
        WHEN ln_update_pattern = 2 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    nml_bef_prev_dlv_date      = main_rec.delivery_date                --�ʏ�@�O�X��@�[�i�N�����@
                ,nml_bef_prev_qty           = main_rec.standard_qty                 --�ʏ�@�O�X��@���ʁ@
                ,nml_bef_prev_clt_date      = main_rec.creation_date                --�ʏ�@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number                    
          AND    item_code                  = gv_item_code                          
          ;
        WHEN ln_update_pattern = 3 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    sls_prev_unit_price        = gn_unit_price                         --�����@�O��@�P���@
                ,sls_prev_dlv_date          = main_rec.delivery_date                --�����@�O��@�[�i�N�����@
                ,sls_prev_qty               = main_rec.standard_qty                 --�����@�O��@���ʁ@
                ,sls_prev_clt_date          = main_rec.creation_date                --�����@�O��@�쐬��
                ,sls_bef_prev_dlv_date      = sls_prev_dlv_date                     --�����@�O�X��@�[�i�N�����@
                ,sls_bef_prev_qty           = sls_prev_qty                          --�����@�O�X��@���ʁ@
                ,sls_bef_prev_clt_date      = sls_prev_clt_date                     --�����@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number                    
          AND    item_code                  = gv_item_code                          
          ;
        WHEN ln_update_pattern = 4 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    sls_bef_prev_dlv_date      = main_rec.delivery_date                --�����@�O�X��@�[�i�N�����@
                ,sls_bef_prev_qty           = main_rec.standard_qty                 --�����@�O�X��@���ʁ@
                ,sls_bef_prev_clt_date      = main_rec.creation_date                --�����@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number                    
          AND    item_code                  = gv_item_code                          
          ;
        ELSE
          gn_skip_cnt := gn_skip_cnt + 1;
      END CASE;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode               -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info              --�L�[���
                                        ,iv_item_name1  => gv_msg_tkn_cust_code     --���ږ���1
                                        ,iv_data_value1 => gv_customer_number       --�f�[�^�̒l1
                                        ,iv_item_name2  => gv_msg_tkn_item_code     --���ږ���2
                                        ,iv_data_value2 => main_rec.item_code       --�f�[�^�̒l2                                            
                                        );
        lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_update_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_tm_w_tbl
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        ov_retcode := cv_status_warn;
        ov_errmsg  := lv_errmsg;
    END;
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
  END proc_update_upm_work;
--
  /**********************************************************************************
   * Procedure Name   : proc_main_loop�i���[�v���j
   * Description      : A-1�f�[�^���o
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
    upm_work_exp      EXCEPTION;
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message_code          VARCHAR2(20);
    ln_update_pattrun        NUMBER;
    lv_sales_exp_line_id     xxcos_sales_exp_lines.sales_exp_line_id%TYPE; --�����p�_�~�[�ϐ�
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
    <<main_loop>>
    LOOP 
      FETCH main_cur INTO main_rec;
      EXIT WHEN main_cur%NOTFOUND;
      BEGIN
        -- ===============================
        --�̔����уw�b�_ID�u���C�N����
        -- ===============================
        --�G���[�J�E���g
        gn_warn_tran_count     := gn_warn_tran_count + gn_new_warn_count;
        --1���[�v���G���[������
        gn_new_warn_count := 0;
        
        IF (main_rec.sales_exp_header_id <> gv_bf_sales_exp_header_id) THEN
          IF (gn_warn_tran_count > 0) THEN
            ROLLBACK;
            gn_warn_cnt := gn_warn_cnt + gn_tran_count;
          ELSE
            COMMIT;
            gn_normal_cnt := gn_normal_cnt + gn_tran_count;
          END IF;
          gn_warn_tran_count := 0;
          gn_tran_count      := 0;
        END IF;

        --�u���C�N����L�[����ւ�
        gv_bf_sales_exp_header_id := main_rec.sales_exp_header_id;
        

        --�����J�E���^
        gn_target_cnt := gn_target_cnt + 1;
        gn_tran_count := gn_tran_count + 1;

        -- ===============================
        --�P���̓��o
        -- ===============================
        IF main_rec.standard_unit_price_excluded = main_rec.standard_unit_price THEN
          gn_unit_price := trunc(main_rec.standard_unit_price_excluded * (1 + (main_rec.tax_rate / 100)),0);
        ELSE
          gn_unit_price := main_rec.standard_unit_price;
        END IF;

        -- ===============================
        -- A-2�D�P���}�X�^���[�N�e�[�u�����R�[�h���b�N
        -- ===============================
        BEGIN
          gv_tkn_lock_table := gv_msg_tkn_tm_w_tbl;
          SELECT  xupm.customer_number       customer_number       --�ڋq�R�[�h
                 ,xupm.item_code             item_code             --�i�ڃR�[�h
                 ,xupm.nml_prev_dlv_date     nml_prev_dlv_date     --�ʏ�@�O��@�[�i�N����
                 ,xupm.nml_bef_prev_dlv_date nml_bef_prev_dlv_date --�ʏ�@�O�X��@�[�i�N����
                 ,xupm.sls_prev_dlv_date     sls_prev_dlv_date     --�����@�O��@�[�i�N����
                 ,xupm.sls_bef_prev_dlv_date sls_bef_prev_dlv_date --�����@�O�X��@�[�i�N����
                 ,xupm.nml_prev_clt_date     nml_prev_clt_date     --�ʏ�@�O��@�쐬��
                 ,xupm.nml_bef_prev_clt_date nml_bef_prev_clt_date --�ʏ�@�O�X��@�쐬��
                 ,xupm.sls_prev_clt_date     sls_prev_clt_date     --�����@�O��@�쐬��
                 ,xupm.sls_bef_prev_clt_date sls_bef_prev_clt_date --�����@�O�X��@�쐬��
          INTO    gv_customer_number       --�ڋq�R�[�h
                 ,gv_item_code             --�i�ڃR�[�h
                 ,gd_nml_prev_dlv_date     --�ʏ�@�O��@�[�i�N����
                 ,gd_nml_bef_prev_dlv_date --�ʏ�@�O�X��@�[�i�N����
                 ,gd_sls_prev_dlv_date     --�����@�O��@�[�i�N����
                 ,gd_sls_bef_prev_dlv_date --�����@�O�X��@�[�i�N����
                 ,gd_nml_prev_clt_date        --�ʏ�@�O��@�쐬��
                 ,gd_nml_bef_prev_clt_date    --�ʏ�@�O�X��@�쐬��
                 ,gd_sls_prev_clt_date        --�����@�O��@�쐬��
                 ,gd_sls_bef_prev_clt_date    --�����@�O�X��@�쐬��
          FROM    xxcos_unit_price_mst_work xupm
          WHERE   xupm.customer_number = main_rec.ship_to_customer_code
          AND     xupm.item_code       = main_rec.item_code
          FOR UPDATE NOWAIT
          ;
          
        -- ===============================
        --A-3�D�P���}�X�^���[�N�e�[�u���X�V
        -- ===============================
          proc_update_upm_work(
                               lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                              ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE upm_work_exp;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
        -- ===============================
        --A-4�D�P���}�X�^���[�N�e�[�u���o�^
        -- ===============================
            proc_insert_upm_work(
                                 lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE upm_work_exp;
            END IF;
        END;
        BEGIN
          -- ===============================
          --A-5�D�̔����і��׃e�[�u�����R�[�h���b�N
          -- ===============================
          gv_tkn_lock_table := gv_msg_tkn_exp_l_tbl;
          SELECT  xsel.sales_exp_line_id sales_exp_line_id       --�̔����і���ID
          INTO    lv_sales_exp_line_id                           --�̔����і���ID
          FROM    xxcos_sales_exp_lines  xsel
          WHERE   xsel.sales_exp_line_id = main_rec.sales_exp_line_id
          FOR UPDATE NOWAIT
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                    --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_exp_line_id         --���ږ���1
                                            ,iv_data_value1 => main_rec.sales_exp_line_id     --�f�[�^�̒l1
                                            );
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_select_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_exp_l_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            RAISE;
        END;
        
        -- ===============================
        --A-6�D �̔����і��׃e�[�u���X�e�[�^�X�X�V
        -- ===============================
        BEGIN
          UPDATE xxcos_sales_exp_lines
          SET    unit_price_mst_flag        = cv_flag_on                            --�P���}�X�^�쐬�σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  sales_exp_line_id          = main_rec.sales_exp_line_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

                             
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  -- �G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                 -- ���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_exp_line_id     --���ږ���1
                                            ,iv_data_value1 => main_rec.sales_exp_line_id --�f�[�^�̒l1
                                            );
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_exp_l_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --�G���[���b�Z�[�W
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --�G���[���b�Z�[�W
                             );
            ov_retcode := cv_status_warn;
            gn_new_warn_count := gn_new_warn_count + 1;
        END;

      EXCEPTION
        WHEN upm_work_exp THEN
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_errmsg --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --�G���[���b�Z�[�W
                           );
                           
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := lv_errbuf;
          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
          
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          IF (SQLCODE = cn_lock_error_code) THEN
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_lock
                                                , cv_tkn_lock
                                                , gv_tkn_lock_table
                                                 );
          ELSE
            ov_errmsg  := NULL;
          END IF;
          
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
      END;
      
    END LOOP main_loop;
    
    --�G���[�J�E���g
    gn_warn_tran_count     := gn_warn_tran_count + gn_new_warn_count;
    
    IF (gn_warn_tran_count > 0) THEN
      ROLLBACK;
      gn_warn_cnt := gn_warn_cnt + gn_tran_count;
      ov_errmsg := NULL;
      ov_errbuf := NULL;
    ELSE
      COMMIT;
      gn_normal_cnt := gn_normal_cnt + gn_tran_count;
    END IF;

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
--
    -- ===============================
    -- Loop1 ���C���@A-1�f�[�^���o
    -- ===============================
    open main_cur;
    proc_main_loop(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
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
    -- A-0�D��������
    -- ===============================================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
      -- ===============================================
      submain(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
    
--
    -- ===============================================
    -- A-7�D�I������
    -- ===============================================
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
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
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
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
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
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
END XXCOS003A02C;
/
