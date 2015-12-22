CREATE OR REPLACE PACKAGE BODY APPS.XXCCP003A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP003A01C(body)
 * Description      : �≮�����f�[�^�o��
 * MD.070           : �≮�����f�[�^�o�� (MD070_IPO_CCP_003_A01)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/09/15    1.0   S.Yamashita      [E_�{�ғ�_11083]�V�K�쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP003A01C'; -- �p�b�P�[�W��
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********	************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_payment_date_from  IN  VARCHAR2      --   1.�x���\���FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   2.�x���\���TO
   ,ov_errbuf             OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
    cv_msg_no_parameter     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- �p�����[�^�Ȃ�
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
    ld_process_date              DATE := xxccp_common_pkg2.get_process_date; -- �Ɩ����t
    --==================================================
    -- �֐��擾�l
    --==================================================
    lov_errbuf                   VARCHAR2(32767) DEFAULT NULL;  -- �G���[�o�b�t�@
    lov_retcode                  VARCHAR2(32767) DEFAULT NULL;  -- ���^�[���R�[�h
    lov_errmsg                   VARCHAR2(32767) DEFAULT NULL;  -- �G���[���b�Z�[�W
    lov_estimated_no             VARCHAR2(32767) DEFAULT NULL;  -- ���Ϗ�No
    lon_quote_line_id            NUMBER          DEFAULT NULL;  -- �≮����������ID
    lov_emp_code                 VARCHAR2(32767) DEFAULT NULL;  -- �S���҃R�[�h
    lon_market_amt               NUMBER          DEFAULT NULL;  -- ���l
    lon_allowance_amt            NUMBER          DEFAULT NULL;  -- �l��(���߂�)
    lon_normal_store_deliver_amt NUMBER          DEFAULT NULL;  -- �ʏ�X�[
    lon_once_store_deliver_amt   NUMBER          DEFAULT NULL;  -- �����X�[
    lon_net_selling_price        NUMBER          DEFAULT NULL;  -- NET���i
    lon_normal_net_selling_price NUMBER          DEFAULT NULL;  -- �ʏ�NET���i
    lov_estimated_type           VARCHAR2(32767) DEFAULT NULL;  -- ���ϋ敪
    lon_backmargin_amt           NUMBER          DEFAULT NULL;  -- �̔��萔��
    lon_sales_support_amt        NUMBER          DEFAULT NULL;  -- �̔����^��
    --==================================================
    -- �o�͗p����
    --==================================================
    lv_file_output_info     VARCHAR2(3000)                                          DEFAULT NULL;  -- �o�̓f�[�^
    lv_wholesale_payment_id VARCHAR2(20)                                            DEFAULT NULL;  -- �≮�x��ID
    lv_payment_date         VARCHAR2(20)                                            DEFAULT NULL;  -- �x���\���
    lv_selling_month        xxcok.xxcok_wholesale_payment.selling_month%TYPE        DEFAULT NULL;  -- ����Ώ۔N��
    lv_base_code            xxcok.xxcok_wholesale_payment.base_code%TYPE            DEFAULT NULL;  -- ���_�R�[�h
    lv_supplier_code        xxcok.xxcok_wholesale_payment.supplier_code%TYPE        DEFAULT NULL;  -- �d����R�[�h
    lv_emp_code             xxcok.xxcok_wholesale_payment.emp_code%TYPE             DEFAULT NULL;  -- �S���҃R�[�h
    lv_wholesale_code_admin xxcok.xxcok_wholesale_payment.wholesale_code_admin%TYPE DEFAULT NULL;  -- �≮�Ǘ��R�[�h
    lv_oprtn_status_code    xxcok.xxcok_wholesale_payment.oprtn_status_code%TYPE    DEFAULT NULL;  -- �ƑԃR�[�h
    lv_cust_code            xxcok.xxcok_wholesale_payment.cust_code%TYPE            DEFAULT NULL;  -- �ڋq�R�[�h
    lv_sales_outlets_code   xxcok.xxcok_wholesale_payment.sales_outlets_code%TYPE   DEFAULT NULL;  -- �≮������R�[�h
    lv_estimated_type       xxcok.xxcok_wholesale_payment.estimated_type%TYPE       DEFAULT NULL;  -- ���ϋ敪
    lv_estimated_no         xxcok.xxcok_wholesale_payment.estimated_no%TYPE         DEFAULT NULL;  -- ���ϔԍ�
    lv_container_group_code xxcok.xxcok_wholesale_payment.container_group_code%TYPE DEFAULT NULL;  -- �e��Q�R�[�h
    lv_case_qty             VARCHAR2(20)                                            DEFAULT NULL;  -- �P�[�X����
    lv_item_code            xxcok.xxcok_wholesale_payment.item_code%TYPE            DEFAULT NULL;  -- ���i�R�[�h
    lv_market_amt           VARCHAR2(20)                                            DEFAULT NULL;  -- ���l
    lv_selling_discount     VARCHAR2(20)                                            DEFAULT NULL;  -- ����l��
    lv_normal_dlv_amt       VARCHAR2(20)                                            DEFAULT NULL;  -- �ʏ�X�[
    lv_once_dlv_amt         VARCHAR2(20)                                            DEFAULT NULL;  -- ����X�[
    lv_net_selling_price    VARCHAR2(20)                                            DEFAULT NULL;  -- NET���i
    lv_coverage_amt         VARCHAR2(20)                                            DEFAULT NULL;  -- ��U
    lv_wholesale_margin_amt VARCHAR2(20)                                            DEFAULT NULL;  -- �≮�}�[�W��
    lv_expansion_sales_amt  VARCHAR2(20)                                            DEFAULT NULL;  -- �g����
    lv_list_price           VARCHAR2(20)                                            DEFAULT NULL;  -- �艿
    lv_demand_unit_type     xxcok.xxcok_wholesale_payment.demand_unit_type%TYPE     DEFAULT NULL;  -- �����P��
    lv_demand_qty           VARCHAR2(20)                                            DEFAULT NULL;  -- ��������
    lv_demand_unit_price    VARCHAR2(20)                                            DEFAULT NULL;  -- �����P��
    lv_demand_amt           VARCHAR2(20)                                            DEFAULT NULL;  -- �������z(�Ŕ�)
    lv_payment_qty          VARCHAR2(20)                                            DEFAULT NULL;  -- �x������
    lv_payment_unit_price   VARCHAR2(20)                                            DEFAULT NULL;  -- �x���P��
    lv_payment_amt          VARCHAR2(20)                                            DEFAULT NULL;  -- �x�����z(�Ŕ�)
    lv_acct_code            xxcok.xxcok_wholesale_payment.acct_code%TYPE            DEFAULT NULL;  -- ����ȖڃR�[�h
    lv_sub_acct_code        xxcok.xxcok_wholesale_payment.sub_acct_code%TYPE        DEFAULT NULL;  -- �⏕�ȖڃR�[�h
    lv_coverage_amt_sum     VARCHAR2(20)                                            DEFAULT NULL;  -- ��U�z
    lv_wholesale_margin_sum VARCHAR2(20)                                            DEFAULT NULL;  -- �≮�}�[�W���z
    lv_expansion_sales_sum  VARCHAR2(20)                                            DEFAULT NULL;  -- �g����z
    lv_misc_acct_amt        VARCHAR2(20)                                            DEFAULT NULL;  -- ���̑��Ȗڊz
    lv_sysdate              VARCHAR2(14)                                            DEFAULT NULL;  -- �V�X�e�����t
    ln_fraction_amount      NUMBER                                                  DEFAULT NULL;  -- �[���v�Z�p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �≮�������R�[�h�擾
    CURSOR main_cur( iv_payment_date_from IN VARCHAR2, iv_payment_date_to IN VARCHAR2 )
    IS
      SELECT /*+ LEADING(xwbh xwbl iimb ximb xsib)
                 INDEX (xwbh xxcok_wholesale_bill_head_n03)
                 USE_NL(xwbh xwbl iimb ximb xsib) */
             xwbh.base_code                   AS base_code                  -- ���_�R�[�h
           , xwbh.cust_code                   AS cust_code                  -- �ڋq�R�[�h
           , xca1.wholesale_ctrl_code         AS wholesale_ctrl_code        -- �≮�Ǘ��R�[�h
           , xwbh.expect_payment_date         AS expect_payment_date        -- �x���\���
           , xwbh.supplier_code               AS supplier_code              -- �d����R�[�h
           , xwbl.selling_month               AS selling_month              -- ����Ώ۔N��
           , xwbl.sales_outlets_code          AS sales_outlets_code         -- �≮������R�[�h
           , xwbl.item_code                   AS item_code                  -- �i�ڃR�[�h
           , xwbl.acct_code                   AS acct_code                  -- ����ȖڃR�[�h
           , xwbl.sub_acct_code               AS sub_acct_code              -- �⏕�ȖڃR�[�h
           , xwbl.demand_unit_type            AS demand_unit_type           -- �����P��
           , xwbl.demand_qty                  AS demand_qty                 -- ��������
           , xwbl.demand_unit_price           AS demand_unit_price          -- �����P��
           , xwbl.payment_qty                 AS payment_qty                -- �x������
           , xwbl.payment_unit_price          AS payment_unit_price         -- �x���P��
           , flv_gyotai.attribute1            AS gyotai_chu                 -- �ƑԒ�����(�≮������)
           , xsib.vessel_group                AS vessel_group               -- �e��Q�R�[�h
           , iimb.attribute11                 AS case_qty                   -- �P�[�X���萔
           , CASE WHEN NVL( TO_DATE( iimb.attribute6, 'YYYY/MM/DD' ), ld_process_date ) > ld_process_date
                    THEN
                      iimb.attribute4  -- �艿�i���j
                    ELSE
                      iimb.attribute5  -- �艿�i�V�j
                  END                         AS list_price                 -- �艿
      FROM   xxcok_wholesale_bill_head     xwbh           -- �≮�������w�b�_�e�[�u��
           , xxcok_wholesale_bill_line     xwbl           -- �≮���������׃e�[�u��
           , xxcmm_cust_accounts           xca1           -- �ڋq�ǉ����i�ڋq�j
           , xxcmm_cust_accounts           xca2           -- �ڋq�ǉ����i�≮������j
           , fnd_lookup_values             flv_gyotai     -- �N�C�b�N�R�[�h�i�Ƒԏ����ށj
           , xxcmm_system_items_b          xsib -- Disc�i�ڃA�h�I��
           , ic_item_mst_b                 iimb -- OPM�i�ڃ}�X�^
           , xxcmn_item_mst_b              ximb -- OPM�i�ڃA�h�I��
      WHERE xwbl.wholesale_bill_header_id     = xwbh.wholesale_bill_header_id
        AND xwbh.cust_code                    = xca1.customer_code
        AND xwbl.sales_outlets_code           = xca2.customer_code
        AND flv_gyotai.lookup_code            = xca2.business_low_type
        AND flv_gyotai.language               = USERENV( 'LANG' )
        AND flv_gyotai.lookup_type            = 'XXCMM_CUST_GYOTAI_SHO'         -- �Q�ƃ^�C�v�F�Ƒԁi�����ށj
        AND xwbh.expect_payment_date    BETWEEN NVL ( ximb.start_date_active, xwbh.expect_payment_date )
                                            AND NVL ( ximb.end_date_active  , xwbh.expect_payment_date )
        AND xwbl.item_code                    = iimb.item_no(+)
        AND xsib.item_id(+)                   = iimb.item_id
        AND iimb.item_id                      = ximb.item_id(+)
        AND NVL(xwbl.status,'X')              <> 'D'
        AND xwbl.payment_qty * xwbl.payment_unit_price <> 0
        AND xwbh.expect_payment_date BETWEEN TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' )
                                         AND TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' )
      ;
    -- ���C���J�[�\�����R�[�h�^
    main_rec  main_cur%ROWTYPE;
    -- �≮�������R�[�h�^
    l_xwp_rec xxcok.xxcok_wholesale_payment%ROWTYPE;
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
    -- ===============================
    -- init��
    -- ===============================
    --==============================================================
    -- ���̓p�����[�^�o��
    --==============================================================
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�x���\���FROM : ' || TO_CHAR( TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' ), 'YYYY/MM/DD' )
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�x���\���TO   : ' || TO_CHAR( TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' ), 'YYYY/MM/DD' )
                     );
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- �x���\���FROM > �x���\���TO �̏ꍇ
    IF ( TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' ) > TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' ) ) THEN
      ov_errbuf  := '�x���\���FROM �� �x���\���TO �ȑO�̓��t���w�肵�ĉ������B';
      ov_retcode := cv_status_error;
    ELSE
      -- ===============================
      -- ������
      -- ===============================
--
      -- ���ږ��o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>           '"' || '�≮�x��ID'         || '"' -- �≮�x��ID
                   || ',' || '"' || '��ЃR�[�h'         || '"' -- ��ЃR�[�h
                   || ',' || '"' || '�x���\���'         || '"' -- �x���\���
                   || ',' || '"' || '����Ώ۔N��'       || '"' -- ����Ώ۔N��
                   || ',' || '"' || '���_�R�[�h'         || '"' -- ���_�R�[�h
                   || ',' || '"' || '�d����R�[�h'       || '"' -- �d����R�[�h
                   || ',' || '"' || '�S���҃R�[�h'       || '"' -- �S���҃R�[�h
                   || ',' || '"' || '�≮�Ǘ��R�[�h'     || '"' -- �≮�Ǘ��R�[�h
                   || ',' || '"' || '�ƑԃR�[�h'         || '"' -- �ƑԃR�[�h
                   || ',' || '"' || '�ڋq�R�[�h'         || '"' -- �ڋq�R�[�h
                   || ',' || '"' || '�≮������R�[�h'   || '"' -- �≮������R�[�h
                   || ',' || '"' || '���ϋ敪'           || '"' -- ���ϋ敪
                   || ',' || '"' || '���ϔԍ�'           || '"' -- ���ϔԍ�
                   || ',' || '"' || '�e��Q�R�[�h'       || '"' -- �e��Q�R�[�h
                   || ',' || '"' || '�P�[�X����'         || '"' -- �P�[�X����
                   || ',' || '"' || '���i�R�[�h'         || '"' -- ���i�R�[�h
                   || ',' || '"' || '���l'               || '"' -- ���l
                   || ',' || '"' || '����l��'           || '"' -- ����l��
                   || ',' || '"' || '�ʏ�X�['           || '"' -- �ʏ�X�[
                   || ',' || '"' || '����X�['           || '"' -- ����X�[
                   || ',' || '"' || 'NET���i'            || '"' -- NET���i
                   || ',' || '"' || '��U'               || '"' -- ��U
                   || ',' || '"' || '�≮�}�[�W��'       || '"' -- �≮�}�[�W��
                   || ',' || '"' || '�g����'             || '"' -- �g����
                   || ',' || '"' || '�艿'               || '"' -- �艿
                   || ',' || '"' || '�����P��'           || '"' -- �����P��
                   || ',' || '"' || '��������'           || '"' -- ��������
                   || ',' || '"' || '�����P��'           || '"' -- �����P��
                   || ',' || '"' || '�������z(�Ŕ�)'     || '"' -- �������z(�Ŕ�)
                   || ',' || '"' || '�x������'           || '"' -- �x������
                   || ',' || '"' || '�x���P��'           || '"' -- �x���P��
                   || ',' || '"' || '�x�����z(�Ŕ�)'     || '"' -- �x�����z(�Ŕ�)
                   || ',' || '"' || '����ȖڃR�[�h'     || '"' -- ����ȖڃR�[�h
                   || ',' || '"' || '�⏕�ȖڃR�[�h'     || '"' -- �⏕�ȖڃR�[�h
                   || ',' || '"' || '��U�z'             || '"' -- ��U�z
                   || ',' || '"' || '�≮�}�[�W���z'     || '"' -- �≮�}�[�W���z
                   || ',' || '"' || '�g����z'           || '"' -- �g����z
                   || ',' || '"' || '���̑��Ȗڊz'       || '"' -- ���̑��Ȗڊz
                   || ',' || '"' || '�V�X�e�����t'       || '"' -- �V�X�e�����t
      );
      -- �f�[�^���o��(CSV)
      FOR main_rec IN main_cur( iv_payment_date_from, iv_payment_date_to ) LOOP
        --�����Z�b�g
        gn_target_cnt := gn_target_cnt + 1;
        --==================================================
        -- ������
        --==================================================
        l_xwp_rec                    := NULL; -- �≮�������R�[�h
        lov_errbuf                   := NULL; -- �G���[�o�b�t�@
        lov_retcode                  := NULL; -- ���^�[���R�[�h
        lov_errmsg                   := NULL; -- �G���[���b�Z�[�W
        lov_estimated_no             := NULL; -- ���Ϗ�No
        lon_quote_line_id            := NULL; -- �≮����������ID
        lov_emp_code                 := NULL; -- �S���҃R�[�h
        lon_market_amt               := NULL; -- ���l
        lon_allowance_amt            := NULL; -- �l��(���߂�)
        lon_normal_store_deliver_amt := NULL; -- �ʏ�X�[
        lon_once_store_deliver_amt   := NULL; -- �����X�[
        lon_net_selling_price        := NULL; -- NET���i
        lon_normal_net_selling_price := NULL; -- �ʏ�NET���i
        lov_estimated_type           := NULL; -- ���ϋ敪
        lon_backmargin_amt           := NULL; -- �̔��萔��
        lon_sales_support_amt        := NULL; -- �̔����^��
        lv_file_output_info          := NULL; -- �o�̓f�[�^
        lv_wholesale_payment_id      := NULL; -- �≮�x��ID
        lv_payment_date              := NULL; -- �x���\���
        lv_selling_month             := NULL; -- ����Ώ۔N��
        lv_base_code                 := NULL; -- ���_�R�[�h
        lv_supplier_code             := NULL; -- �d����R�[�h
        lv_emp_code                  := NULL; -- �S���҃R�[�h
        lv_wholesale_code_admin      := NULL; -- �≮�Ǘ��R�[�h
        lv_oprtn_status_code         := NULL; -- �ƑԃR�[�h
        lv_cust_code                 := NULL; -- �ڋq�R�[�h
        lv_sales_outlets_code        := NULL; -- �≮������R�[�h
        lv_estimated_type            := NULL; -- ���ϋ敪
        lv_estimated_no              := NULL; -- ���ϔԍ�
        lv_container_group_code      := NULL; -- �e��Q�R�[�h
        lv_case_qty                  := NULL; -- �P�[�X����
        lv_item_code                 := NULL; -- ���i�R�[�h
        lv_market_amt                := NULL; -- ���l
        lv_selling_discount          := NULL; -- ����l��
        lv_normal_dlv_amt            := NULL; -- �ʏ�X�[
        lv_once_dlv_amt              := NULL; -- ����X�[
        lv_net_selling_price         := NULL; -- NET���i
        lv_coverage_amt              := NULL; -- ��U�z
        lv_wholesale_margin_amt      := NULL; -- �≮�}�[�W��
        lv_expansion_sales_amt       := NULL; -- �g����
        lv_list_price                := NULL; -- �艿
        lv_demand_unit_type          := NULL; -- �����P��
        lv_demand_qty                := NULL; -- ��������
        lv_demand_unit_price         := NULL; -- �����P��
        lv_demand_amt                := NULL; -- �������z(�Ŕ�)
        lv_payment_qty               := NULL; -- �x������
        lv_payment_unit_price        := NULL; -- �x���P��
        lv_payment_amt               := NULL; -- �x�����z(�Ŕ�)
        lv_acct_code                 := NULL; -- ����ȖڃR�[�h
        lv_sub_acct_code             := NULL; -- �⏕�ȖڃR�[�h
        lv_coverage_amt_sum          := NULL; -- ��U�z
        lv_wholesale_margin_sum      := NULL; -- �≮�}�[�W���z
        lv_expansion_sales_sum       := NULL; -- �g����z
        lv_misc_acct_amt             := NULL; -- ���̑��Ȗڊz
        lv_sysdate                   := NULL; -- �V�X�e�����t
        ln_fraction_amount           := NULL; -- �[���v�Z�p
        --==================================================
        -- ���ʊ֐��u�≮�������Ϗƍ��v�Ăяo��
        --==================================================
        xxcok_common_pkg.get_wholesale_req_est_p(
          ov_errbuf                    => lov_errbuf                    -- �G���[�o�b�t�@
        , ov_retcode                   => lov_retcode                   -- ���^�[���R�[�h
        , ov_errmsg                    => lov_errmsg                    -- �G���[���b�Z�[�W
        , iv_wholesale_code            => main_rec.wholesale_ctrl_code  -- �≮�Ǘ��R�[�h
        , iv_sales_outlets_code        => main_rec.sales_outlets_code   -- �≮������R�[�h
        , iv_item_code                 => main_rec.item_code            -- �i�ڃR�[�h
        , in_demand_unit_price         => main_rec.payment_unit_price   -- �����P��
        , iv_demand_unit_type          => main_rec.demand_unit_type     -- �����P��
        , iv_selling_month             => main_rec.selling_month        -- ����Ώ۔N��
        , ov_estimated_no              => lov_estimated_no              -- ���Ϗ�No
        , on_quote_line_id             => lon_quote_line_id             -- �≮����������ID
        , ov_emp_code                  => lov_emp_code                  -- �S���҃R�[�h
        , on_market_amt                => lon_market_amt                -- ���l
        , on_allowance_amt             => lon_allowance_amt             -- �l��(���߂�)
        , on_normal_store_deliver_amt  => lon_normal_store_deliver_amt  -- �ʏ�X�[
        , on_once_store_deliver_amt    => lon_once_store_deliver_amt    -- �����X�[
        , on_net_selling_price         => lon_net_selling_price         -- NET���i
        , on_normal_net_selling_price  => lon_normal_net_selling_price  -- �ʏ�NET���i
        , ov_estimated_type            => lov_estimated_type            -- ���ϋ敪
        , on_backmargin_amt            => lon_backmargin_amt            -- �̔��萔��
        , on_sales_support_amt         => lon_sales_support_amt         -- �̔����^��
        );
        --==================================================
        -- �≮�������R�[�h�쐬
        --==================================================
        l_xwp_rec.base_code                    := main_rec.base_code;                                            -- ���_�R�[�h
        l_xwp_rec.emp_code                     := lov_emp_code;                                                  -- �S���҃R�[�h
        l_xwp_rec.oprtn_status_code            := main_rec.gyotai_chu;                                           -- �ƑԃR�[�h
        l_xwp_rec.item_code                    := main_rec.item_code;                                            -- �i�ڃR�[�h
        l_xwp_rec.container_group_code         := main_rec.vessel_group;                                         -- �e��Q�R�[�h
        l_xwp_rec.estimated_type               := lov_estimated_type;                                            -- ���ϋ敪
        l_xwp_rec.market_amt                   := lon_market_amt;                                                -- ���l
        l_xwp_rec.normal_store_deliver_amt     := lon_normal_store_deliver_amt;                                  -- �ʏ�X�[
        l_xwp_rec.once_store_deliver_amt       := lon_once_store_deliver_amt;                                    -- ����X�[
        l_xwp_rec.coverage_amt                 := lon_market_amt - lon_normal_store_deliver_amt;                 -- ��U
        l_xwp_rec.expansion_sales_amt          := lon_normal_store_deliver_amt - lon_once_store_deliver_amt;     -- �g����
        l_xwp_rec.net_selling_price            := lon_net_selling_price;                                         -- NET���i
        IF( lon_once_store_deliver_amt = 0 OR lon_once_store_deliver_amt IS NULL ) THEN
          l_xwp_rec.wholesale_margin_sum       := lon_normal_store_deliver_amt - lon_net_selling_price;
        ELSE
          l_xwp_rec.wholesale_margin_sum       := lon_once_store_deliver_amt   - lon_net_selling_price;
        END IF;                                                                                                  -- �≮�}�[�W��
        l_xwp_rec.selling_discount             := lon_allowance_amt;                                             -- ����l��
        l_xwp_rec.acct_code                    := main_rec.acct_code;                                            -- ����ȖڃR�[�h
        l_xwp_rec.sub_acct_code                := main_rec.sub_acct_code;                                        -- �⏕�ȖڃR�[�h
        l_xwp_rec.selling_month                := main_rec.selling_month;                                        -- ����Ώ۔N��
        l_xwp_rec.wholesale_code_admin         := main_rec.wholesale_ctrl_code;                                  -- �≮�Ǘ��R�[�h
        l_xwp_rec.cust_code                    := main_rec.cust_code;                                            -- �ڋq�R�[�h
        l_xwp_rec.sales_outlets_code           := main_rec.sales_outlets_code;                                   -- �≮������R�[�h
        l_xwp_rec.payment_qty                  := main_rec.payment_qty;                                          -- �x������
        l_xwp_rec.payment_unit_price           := main_rec.payment_unit_price;                                   -- �x���P��
        l_xwp_rec.payment_amt                  := TRUNC( main_rec.payment_qty * main_rec.payment_unit_price );   -- �x�����z
        l_xwp_rec.estimated_no                 := lov_estimated_no;                                              -- ���ϔԍ�
        l_xwp_rec.estimated_detail_id          := lon_quote_line_id;                                             -- ���Ϗ�����ID
        l_xwp_rec.supplier_code                := main_rec.supplier_code;                                        -- �d����R�[�h
        l_xwp_rec.demand_qty                   := main_rec.demand_qty;                                           -- ��������
        l_xwp_rec.demand_unit_type             := main_rec.demand_unit_type;                                     -- �����P��
        l_xwp_rec.demand_unit_price            := main_rec.demand_unit_price;                                    -- �����P��
        l_xwp_rec.demand_amt                   := TRUNC( main_rec.demand_qty  * main_rec.demand_unit_price  );   -- �������z
        l_xwp_rec.expect_payment_date          := main_rec.expect_payment_date;                                  -- �x���\���
        IF( main_rec.acct_code IS NOT NULL ) THEN
          l_xwp_rec.misc_acct_amt              := TRUNC( main_rec.payment_qty * main_rec.payment_unit_price );   -- ���̑��Ȗ�
        END IF;
        l_xwp_rec.backmargin                   := lon_backmargin_amt;                                            -- �̔��萔��
        l_xwp_rec.sales_support_amt            := lon_sales_support_amt;                                         -- �̔����^��
        --==================================================
        -- �o�͗p���ڐݒ�
        --==================================================
        lv_wholesale_payment_id := TO_CHAR( l_xwp_rec.wholesale_payment_id );     -- �≮�x��ID
        lv_payment_date         := TO_CHAR( l_xwp_rec.expect_payment_date
                                          , 'YYYY/MM/DD' );                       -- �x���\���
        lv_selling_month        := l_xwp_rec.selling_month;                       -- ����Ώ۔N��
        lv_base_code            := l_xwp_rec.base_code;                           -- ���_�R�[�h
        lv_supplier_code        := l_xwp_rec.supplier_code;                       -- �d����R�[�h
        lv_emp_code             := NVL( l_xwp_rec.emp_code, '00000' );            -- �S���҃R�[�h
        lv_wholesale_code_admin := l_xwp_rec.wholesale_code_admin;                -- �≮�Ǘ��R�[�h
        lv_oprtn_status_code    := l_xwp_rec.oprtn_status_code;                   -- �ƑԃR�[�h
        lv_cust_code            := l_xwp_rec.cust_code;                           -- �ڋq�R�[�h
        lv_sales_outlets_code   := l_xwp_rec.sales_outlets_code;                  -- �≮������R�[�h
        lv_estimated_type       := NVL( l_xwp_rec.estimated_type, '1' );          -- ���ϋ敪
        lv_estimated_no         := NVL( l_xwp_rec.estimated_no, '���ςȂ�' );     -- ���ϔԍ�
        lv_container_group_code := l_xwp_rec.container_group_code;                -- �e��Q�R�[�h
        lv_case_qty             := TO_CHAR( main_rec.case_qty );                  -- �P�[�X����
        lv_item_code            := l_xwp_rec.item_code;                           -- ���i�R�[�h
        lv_market_amt           := TO_CHAR( l_xwp_rec.market_amt );               -- ���l
        lv_selling_discount     := TO_CHAR( l_xwp_rec.selling_discount );         -- ����l��
        lv_normal_dlv_amt       := TO_CHAR( l_xwp_rec.normal_store_deliver_amt ); -- �ʏ�X�[
        lv_once_dlv_amt         := TO_CHAR( l_xwp_rec.once_store_deliver_amt );   -- ����X�[
        lv_net_selling_price    := TO_CHAR( l_xwp_rec.net_selling_price );        -- NET���i
        lv_coverage_amt         := TO_CHAR( l_xwp_rec.coverage_amt );             -- ��U
        lv_wholesale_margin_amt := TO_CHAR( l_xwp_rec.wholesale_margin_sum );     -- �≮�}�[�W��
        lv_expansion_sales_amt  := TO_CHAR( l_xwp_rec.expansion_sales_amt );      -- �g����
        lv_list_price           := TO_CHAR( main_rec.list_price );                -- �艿
        lv_demand_unit_type     := l_xwp_rec.demand_unit_type;                    -- �����P��
        lv_demand_qty           := TO_CHAR( l_xwp_rec.demand_qty );               -- ��������
        lv_demand_unit_price    := TO_CHAR( l_xwp_rec.demand_unit_price );        -- �����P��
        lv_demand_amt           := TO_CHAR( l_xwp_rec.demand_amt );               -- �������z(�Ŕ�)
        lv_payment_qty          := TO_CHAR( l_xwp_rec.payment_qty );              -- �x������
        lv_payment_unit_price   := TO_CHAR( l_xwp_rec.payment_unit_price );       -- �x���P��
        lv_payment_amt          := TO_CHAR( l_xwp_rec.payment_amt );              -- �x�����z(�Ŕ�)
        lv_acct_code            := l_xwp_rec.acct_code;                           -- ����ȖڃR�[�h
        lv_sub_acct_code        := l_xwp_rec.sub_acct_code;                       -- �⏕�ȖڃR�[�h
        -- ��U�z
        IF (    (   NVL( l_xwp_rec.market_amt              , 0 )
                  - NVL( l_xwp_rec.selling_discount        , 0 )
                  - NVL( l_xwp_rec.normal_store_deliver_amt, 0 ) <= 0
                )
             OR ( l_xwp_rec.backmargin IS NULL )
             OR ( l_xwp_rec.backmargin <= 0    )
           )
        THEN
          lv_coverage_amt_sum := '0';
        ELSE
          lv_coverage_amt_sum :=
            TO_CHAR( ROUND( (   NVL( l_xwp_rec.market_amt              , 0 )
                              - NVL( l_xwp_rec.selling_discount        , 0 )
                              - NVL( l_xwp_rec.normal_store_deliver_amt, 0 )
                            ) * NVL( l_xwp_rec.payment_qty             , 0 )
                     )
            );
        END IF;
        -- �≮�}�[�W���z
        IF ( l_xwp_rec.backmargin >= 0 ) THEN
          lv_wholesale_margin_sum :=
            TO_CHAR( TRUNC(   NVL( l_xwp_rec.backmargin , 0  )
                            * NVL( l_xwp_rec.payment_qty, 0  )
                            - TO_NUMBER( lv_coverage_amt_sum )
                     )
             );
        ELSE
          lv_wholesale_margin_sum :=
            TO_CHAR( TRUNC(   NVL( l_xwp_rec.backmargin , 0 )
                            * NVL( l_xwp_rec.payment_qty, 0 )
                     )
            );
        END IF;
        -- �g����z
        lv_expansion_sales_sum := TO_CHAR( TRUNC(   NVL( l_xwp_rec.sales_support_amt, 0 )
                                                  * NVL( l_xwp_rec.payment_qty      , 0 )
                                           )
                                  );
        -- ===============================================
        -- �[������
        -- �x�����z=��U+�≮�}�[�W��+�g����𖞂����Ȃ��ꍇ
        -- �≮�}�[�W���ɂċ��z�������s��
        -- ===============================================
        IF( l_xwp_rec.acct_code IS NULL ) THEN
          ln_fraction_amount :=   TO_NUMBER( lv_coverage_amt_sum     )
                                + TO_NUMBER( lv_wholesale_margin_sum )
                                + TO_NUMBER( lv_expansion_sales_sum  );
          IF ( NVL( l_xwp_rec.payment_amt
                  , l_xwp_rec.demand_amt ) != ln_fraction_amount ) THEN
            lv_wholesale_margin_sum := TO_CHAR(   TO_NUMBER( lv_wholesale_margin_sum )
                                                + ( NVL( l_xwp_rec.payment_amt
                                                       , l_xwp_rec.demand_amt  ) - ln_fraction_amount )
                                       );
          END IF;
        END IF;
        IF( l_xwp_rec.acct_code IS NOT NULL ) THEN
          IF (     l_xwp_rec.acct_code     = '83110'    -- ����Ȗ�
               AND l_xwp_rec.sub_acct_code = '05103'    -- �⏕�Ȗ�
          ) THEN
            lv_wholesale_margin_sum := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- �≮�}�[�W���z
          ELSIF (     l_xwp_rec.acct_code     = '83111' -- ����Ȗ�
                  AND l_xwp_rec.sub_acct_code = '05132' -- �⏕�Ȗ�
          ) THEN
            lv_expansion_sales_sum  := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- �g����z
          ELSE
            lv_misc_acct_amt        := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- ���̑��Ȗڊz
          END IF;
        ELSE
          lv_misc_acct_amt          := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- ���̑��Ȗڊz
        END IF;
        lv_sysdate                  := TO_CHAR( SYSDATE, 'YYYYMMDDHH24MISS' );       -- �V�X�e�����t
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   =>           '"' || lv_wholesale_payment_id  || '"' -- �≮�x��ID
                     || ',' || '"' || '001'                    || '"' -- ��ЃR�[�h
                     || ',' || '"' || lv_payment_date          || '"' -- �x���\���
                     || ',' || '"' || lv_selling_month         || '"' -- ����Ώ۔N��
                     || ',' || '"' || lv_base_code             || '"' -- ���_�R�[�h
                     || ',' || '"' || lv_supplier_code         || '"' -- �d����R�[�h
                     || ',' || '"' || lv_emp_code              || '"' -- �S���҃R�[�h
                     || ',' || '"' || lv_wholesale_code_admin  || '"' -- �≮�Ǘ��R�[�h
                     || ',' || '"' || lv_oprtn_status_code     || '"' -- �ƑԃR�[�h
                     || ',' || '"' || lv_cust_code             || '"' -- �ڋq�R�[�h
                     || ',' || '"' || lv_sales_outlets_code    || '"' -- �≮������R�[�h
                     || ',' || '"' || lv_estimated_type        || '"' -- ���ϋ敪
                     || ',' || '"' || lv_estimated_no          || '"' -- ���ϔԍ�
                     || ',' || '"' || lv_container_group_code  || '"' -- �e��Q�R�[�h
                     || ',' || '"' || lv_case_qty              || '"' -- �P�[�X����
                     || ',' || '"' || lv_item_code             || '"' -- ���i�R�[�h
                     || ',' || '"' || lv_market_amt            || '"' -- ���l
                     || ',' || '"' || lv_selling_discount      || '"' -- ����l��
                     || ',' || '"' || lv_normal_dlv_amt        || '"' -- �ʏ�X�[
                     || ',' || '"' || lv_once_dlv_amt          || '"' -- ����X�[
                     || ',' || '"' || lv_net_selling_price     || '"' -- NET���i
                     || ',' || '"' || lv_coverage_amt          || '"' -- ��U
                     || ',' || '"' || lv_wholesale_margin_amt  || '"' -- �≮�}�[�W��
                     || ',' || '"' || lv_expansion_sales_amt   || '"' -- �g����
                     || ',' || '"' || lv_list_price            || '"' -- �艿
                     || ',' || '"' || lv_demand_unit_type      || '"' -- �����P��
                     || ',' || '"' || lv_demand_qty            || '"' -- ��������
                     || ',' || '"' || lv_demand_unit_price     || '"' -- �����P��
                     || ',' || '"' || lv_demand_amt            || '"' -- �������z(�Ŕ�)
                     || ',' || '"' || lv_payment_qty           || '"' -- �x������
                     || ',' || '"' || lv_payment_unit_price    || '"' -- �x���P��
                     || ',' || '"' || lv_payment_amt           || '"' -- �x�����z(�Ŕ�)
                     || ',' || '"' || lv_acct_code             || '"' -- ����ȖڃR�[�h
                     || ',' || '"' || lv_sub_acct_code         || '"' -- �⏕�ȖڃR�[�h
                     || ',' || '"' || lv_coverage_amt_sum      || '"' -- ��U�z
                     || ',' || '"' || lv_wholesale_margin_sum  || '"' -- �≮�}�[�W���z
                     || ',' || '"' || lv_expansion_sales_sum   || '"' -- �g����z
                     || ',' || '"' || lv_misc_acct_amt         || '"' -- ���̑��Ȗڊz
                     || ',' || '"' || lv_sysdate               || '"' -- �V�X�e�����t
        );
      END LOOP;
--
      -- �����������Ώی���
      gn_normal_cnt  := gn_target_cnt;
      -- �Ώی���=0�ł���΃��b�Z�[�W�o��
      IF (gn_target_cnt = 0) THEN
       FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => CHR(10) || '�Ώۃf�[�^�͂���܂���B'
       );
      END IF;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_payment_date_from  IN  VARCHAR2      --   1.�x���\���FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   2.�x���\���TO
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
       iv_which   => 'LOG'
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
       iv_payment_date_from  --   1.�x���\���FROM
      ,iv_payment_date_to    --   2.�x���\���TO
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP003A01C;
/