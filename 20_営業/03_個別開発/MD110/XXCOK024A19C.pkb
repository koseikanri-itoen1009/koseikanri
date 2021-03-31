CREATE OR REPLACE PACKAGE BODY XXCOK024A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A19C_pkg(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F�T���f�[�^���z���z���� MD050_COK_024_A19
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  cre_num_recon_diff_ap  �T��No�ʍ��z�f�[�^�쐬(A-2)
 *  cre_item_recon_diff_wp ���i�ʌJ�z�f�[�^�쐬(A-3)
 *  cre_num_recon_diff_wp  �T��No�ʌJ�z�f�[�^�쐬(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/03/12    1.0   Y.Koh            �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ==============================
  -- �O���[�o���萔
  -- ==============================
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A19C';                      -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00028';                  -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_cok_00001            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00001';                  -- �ΏۂȂ����b�Z�[�W
  cv_msg_cok_10632            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10632';                  -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_cok_10744            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10744';                  -- �c���J�z�p�f�[�^��ގ擾�G���[
  -- �Q�ƃ^�C�v
  cv_lookup_data_type         CONSTANT VARCHAR2(50)         := 'XXCOK1_DEDUCTION_DATA_TYPE';        -- �T���f�[�^���
  -- �敪 / �t���O
  cv_div_ap                   CONSTANT VARCHAR2(2)          := 'AP';                                -- �A�g��(AP�x��)
  cv_div_wp                   CONSTANT VARCHAR2(2)          := 'WP';                                -- �A�g��(AP�≮�x��)
  cv_flag_d                   CONSTANT VARCHAR2(1)          := 'D';                                 -- �쐬���敪(���z����)
  cv_flag_o                   CONSTANT VARCHAR2(1)          := 'O';                                 -- �쐬���敪(�J�z����) / GL�A�g�t���O(�ΏۊO)
  cv_flag_y                   CONSTANT VARCHAR2(1)          := 'Y';                                 -- �Ώۃt���O(�Ώ�)
  cv_flag_n                   CONSTANT VARCHAR2(1)          := 'N';                                 -- �X�e�[�^�X(�V�K) / ����t���O(�����)
  -- �L��
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
  -- ==============================
  -- �O���[�o���ϐ�
  -- ==============================
  gd_process_month            xxcok_deduction_recon_head.gl_date%TYPE;          -- �Ɩ�������
  gv_recon_slip_num           xxcok_deduction_recon_head.recon_slip_num%TYPE;   -- �x���`�[�ԍ�
  gd_gl_date                  xxcok_deduction_recon_head.gl_date%TYPE;          -- GL�L����
  gd_gl_month                 xxcok_deduction_recon_head.gl_date%TYPE;          -- GL�L����
  gd_target_date_end          xxcok_deduction_recon_head.target_date_end%TYPE;  -- �Ώۊ���(TO)
  gv_interface_div            xxcok_deduction_recon_head.interface_div%TYPE;    -- �A�g��
  gv_data_type_030            xxcok_sales_deduction.data_type%TYPE;             -- �c���J�z�p�̃f�[�^���
  g_xxcok_sales_deduction_rec xxcok_sales_deduction%ROWTYPE;                    -- �̔��T�����
  -- ==============================
  -- �O���[�o����O
  -- ==============================
  -- *** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
  -- *** ���b�N�擾�G���[��O ***
  global_lock_failure_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_failure_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                           -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �Ɩ��������̎擾
    -- ============================================================
    gd_process_month  :=  TRUNC(xxccp_common_pkg2.get_process_date, 'MM');

    IF  gd_process_month  IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_00028
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �T�������w�b�_�[���̘A�g��̎擾
    -- ============================================================
    BEGIN
--
      SELECT  xdrh.gl_date                    gl_date         , -- GL�L����
              TRUNC(xdrh.gl_date, 'MM')       gl_month        , -- GL�L����
              LAST_DAY(xdrh.target_date_end)  target_date_end , -- �Ώۊ���(TO)
              xdrh.interface_div              interface_div     -- �A�g��
      INTO    gd_gl_date        ,
              gd_gl_month       ,
              gd_target_date_end,
              gv_interface_div
      FROM    xxcok_deduction_recon_head  xdrh
      WHERE   xdrh.recon_slip_num = gv_recon_slip_num;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_00001
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================================
    -- �c���J�z�p�̃f�[�^��ނ̎擾
    -- ============================================================
    IF  gv_interface_div  = cv_div_wp THEN
      BEGIN
--
        SELECT  dtyp.lookup_code        lookup_code         -- �f�[�^���
        INTO    gv_data_type_030
        FROM    fnd_lookup_values       dtyp
        WHERE   dtyp.lookup_type            =   cv_lookup_data_type
        AND     dtyp.language               =   'JA'
        AND     dtyp.enabled_flag           =   cv_flag_y
        AND     dtyp.attribute9             =   cv_flag_y ;
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_msg_cok_10744
                        );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : cre_num_recon_diff_ap
   * Description      : �T��No�ʍ��z�f�[�^�쐬(A-2)
   ***********************************************************************************/
  PROCEDURE cre_num_recon_diff_ap(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'cre_num_recon_diff_ap';          -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_difference_amt_rest              xxcok_deduction_num_recon.difference_amt%TYPE;              -- �������z(�Ŕ�)_�c�z
    ln_difference_tax_rest              xxcok_deduction_num_recon.difference_tax%TYPE;              -- �������z(�����)_�c�z
    --===============================
    -- ���[�J���J�[�\��
    --===============================
--
    CURSOR xxcok_sales_deduction_u_cur
    IS
      SELECT  xsd.sales_deduction_id    sales_deduction_id  , -- �̔��T��ID
              xsd.base_code_to          base_code_to        , -- �U�֐拒�_
              xsd.source_category       source_category     , -- �쐬���敪
              xca.sale_base_code        sale_base_code      , -- ���㋒�_�R�[�h
              xca.past_sale_base_code   past_sale_base_code , -- �O�����㋒�_�R�[�h
              xdnr.payment_tax_code     payment_tax_code      -- �������ŃR�[�h
      FROM    xxcok_deduction_num_recon xdnr                , -- �T��No�ʏ������
              xxcmm_cust_accounts       xca                 , -- �ڋq�ǉ����
              xxcok_sales_deduction     xsd                   -- �̔��T�����
      WHERE   xsd.recon_slip_num          =   gv_recon_slip_num
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     xdnr.recon_slip_num         =   gv_recon_slip_num
      AND     xdnr.condition_no           =   xsd.condition_no
      AND     xdnr.tax_code               =   xsd.tax_code
      FOR UPDATE OF xsd.recon_tax_code  NOWAIT;
--
    CURSOR xxcok_deduction_num_recon_cur
    IS
      SELECT  xdnr.condition_no         condition_no        , -- �T���ԍ�
              xdnr.tax_code             tax_code            , -- ����ŃR�[�h
              xdnr.payment_tax_code     payment_tax_code    , -- �x�����ŃR�[�h
              xdnr.deduction_amt        denominator         , -- ��_����
              xdnr.difference_amt * -1  difference_amt      , -- �������z(�Ŕ�)
              xdnr.difference_tax * -1  difference_tax        -- �������z(�����)
      FROM    xxcok_deduction_num_recon xdnr                  -- �T��No�ʏ������
      WHERE   xdnr.recon_slip_num       =   gv_recon_slip_num
      AND     xdnr.target_flag          =   cv_flag_y
      AND   ( xdnr.difference_amt       !=  0 OR
              xdnr.difference_tax       !=  0 )
      ORDER BY  xdnr.deduction_line_num ;
--
    CURSOR xxcok_sales_deduction_s_cur(
      p_condition_no  VARCHAR2                                                  -- �T���ԍ�
    , p_tax_code      VARCHAR2                                                  -- ����ŃR�[�h
    )
    IS
      SELECT  xsd.customer_code_to      customer_code_to      , -- �U�֐�ڋq�R�[�h
              xsd.deduction_chain_code  deduction_chain_code  , -- �T���p�`�F�[���R�[�h
              xsd.corp_code             corp_code             , -- ��ƃR�[�h
              xsd.condition_id          condition_id          , -- �T������ID
              xsd.data_type             data_type             , -- �f�[�^���
              xsd.item_code             item_code             , -- �i�ڃR�[�h
              xsd.recon_base_code       recon_base_code       , -- �������v�㋒�_
              SUM(xsd.deduction_amount) numerator               -- ��_���q
      FROM    xxcok_sales_deduction     xsd                     -- �̔��T�����
      WHERE   xsd.recon_slip_num  = gv_recon_slip_num
      AND     xsd.condition_no    = p_condition_no
      AND     xsd.tax_code        = p_tax_code
      GROUP BY  xsd.customer_code_to    ,
                xsd.deduction_chain_code,
                xsd.corp_code           ,
                xsd.condition_id        ,
                xsd.data_type           ,
                xsd.item_code           ,
                xsd.recon_base_code
      ORDER BY  xsd.customer_code_to,
                xsd.item_code       ;
--
    TYPE xxcok_sales_deduction_s_ttype  IS TABLE OF xxcok_sales_deduction_s_cur%ROWTYPE;
    xxcok_sales_deduction_s_tab         xxcok_sales_deduction_s_ttype;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �������ŃR�[�h�A�������v�㋒�_�̍X�V
    -- ============================================================
    FOR xxcok_sales_deduction_u_rec IN  xxcok_sales_deduction_u_cur LOOP
      UPDATE  xxcok_sales_deduction
      SET     recon_tax_code          = xxcok_sales_deduction_u_rec.payment_tax_code,
              recon_base_code         = CASE  WHEN  xxcok_sales_deduction_u_rec.source_category IN  ('F', 'U') THEN
                                                xxcok_sales_deduction_u_rec.base_code_to
                                              WHEN  gd_gl_month < gd_process_month                            THEN
                                                xxcok_sales_deduction_u_rec.past_sale_base_code
                                              ELSE
                                                xxcok_sales_deduction_u_rec.sale_base_code
                                        END,
              last_updated_by         = cn_user_id            ,
              last_update_date        = SYSDATE               ,
              last_update_login       = cn_login_id           ,
              request_id              = cn_conc_request_id    ,
              program_application_id  = cn_prog_appl_id       ,
              program_id              = cn_conc_program_id    ,
              program_update_date     = SYSDATE
      WHERE   SALES_DEDUCTION_ID  = xxcok_sales_deduction_u_rec.SALES_DEDUCTION_ID;
    END LOOP;
--
    -- ============================================================
    -- ���z�����f�[�^�쐬
    -- ============================================================
    FOR xxcok_deduction_num_recon_rec IN  xxcok_deduction_num_recon_cur LOOP
--
      ln_difference_amt_rest  :=  xxcok_deduction_num_recon_rec.difference_amt;
      ln_difference_tax_rest  :=  xxcok_deduction_num_recon_rec.difference_tax;
--
      OPEN  xxcok_sales_deduction_s_cur(xxcok_deduction_num_recon_rec.condition_no, xxcok_deduction_num_recon_rec.tax_code);
      FETCH xxcok_sales_deduction_s_cur BULK COLLECT INTO xxcok_sales_deduction_s_tab;
      CLOSE xxcok_sales_deduction_s_cur;
--
      FOR i IN 1..xxcok_sales_deduction_s_tab.COUNT LOOP
        IF i = xxcok_sales_deduction_s_tab.COUNT THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ln_difference_amt_rest;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ln_difference_tax_rest;
        ELSIF xxcok_deduction_num_recon_rec.denominator = 0 THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  0;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  0;
        ELSE
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ROUND(  xxcok_deduction_num_recon_rec.difference_amt
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ROUND(  xxcok_deduction_num_recon_rec.difference_tax
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
        END IF;
--
        IF  g_xxcok_sales_deduction_rec.deduction_amount  !=  0 OR  g_xxcok_sales_deduction_rec.deduction_tax_amount  !=0 THEN
          g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- �̔��T��ID
          g_xxcok_sales_deduction_rec.base_code_from          :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �U�֌����_
          g_xxcok_sales_deduction_rec.base_code_to            :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �U�֐拒�_
          g_xxcok_sales_deduction_rec.customer_code_from      :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- �U�֌��ڋq�R�[�h
          g_xxcok_sales_deduction_rec.customer_code_to        :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- �U�֐�ڋq�R�[�h
          g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_sales_deduction_s_tab(i).deduction_chain_code ;   -- �T���p�`�F�[���R�[�h
          g_xxcok_sales_deduction_rec.corp_code               :=  xxcok_sales_deduction_s_tab(i).corp_code            ;   -- ��ƃR�[�h
          g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- �v���
          g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_d                                           ;   -- �쐬���敪
          g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- �쐬������ID
          g_xxcok_sales_deduction_rec.condition_id            :=  xxcok_sales_deduction_s_tab(i).condition_id         ;   -- �T������ID
          g_xxcok_sales_deduction_rec.condition_no            :=  xxcok_deduction_num_recon_rec.condition_no          ;   -- �T���ԍ�
          g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- �T���ڍ�ID
          g_xxcok_sales_deduction_rec.data_type               :=  xxcok_sales_deduction_s_tab(i).data_type            ;   -- �f�[�^���
          g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- �X�e�[�^�X
          g_xxcok_sales_deduction_rec.item_code               :=  xxcok_sales_deduction_s_tab(i).item_code            ;   -- �i�ڃR�[�h
          g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- �̔��P��
          g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- �̔��P��
          g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- �̔�����
          g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- ����{�̋��z
          g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- �������Ŋz
          g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- �T���P��
          g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- �T���P��
          g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- �T������
--        g_xxcok_sales_deduction_rec.deduction_amount        :=  (��L�ŎZ�o��)                                      ;   -- �T���z
          g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_num_recon_rec.tax_code              ;   -- �ŃR�[�h
          g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- �ŗ�
          g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_num_recon_rec.payment_tax_code      ;   -- �������ŃR�[�h
          g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- �������ŗ�
--        g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  (��L�ŎZ�o��)                                      ;   -- �T���Ŋz
          g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- ���l
          g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- �\����No.
          g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL�A�g�t���O
          g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL�v�㋒�_
          g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL�L����
          g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- ���J�o���[���t
          g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- ����t���O
          g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- ������v�㋒�_
          g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- ���GL�L����
          g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- ������{���[�U
          g_xxcok_sales_deduction_rec.recon_base_code         :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �������v�㋒�_
          g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- �x���`�[�ԍ�
          g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- �J�z���x���`�[�ԍ�
          g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- ����m��t���O
          g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL�A�gID
          g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- ���GL�A�gID
          g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- �쐬��
          g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- �쐬��
          g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- �ŏI�X�V��
          g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- �ŏI�X�V��
          g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- �ŏI�X�V���O�C��
          g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- �v��ID
          g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- �R���J�����g�E�v���O����ID
          g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- �v���O�����X�V��
--
          INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
          ln_difference_amt_rest  :=  ln_difference_amt_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_AMOUNT    ;
          ln_difference_tax_rest  :=  ln_difference_tax_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_TAX_AMOUNT;
        END IF;
--
      END LOOP;
--
    END LOOP;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[��O ***
    WHEN  global_lock_failure_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10632
                    );
      lv_errbuf :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END cre_num_recon_diff_ap;
--
  /**********************************************************************************
   * Procedure Name   : cre_item_recon_diff_wp
   * Description      : ���i�ʌJ�z�f�[�^�쐬(A-3)
   ***********************************************************************************/
  PROCEDURE cre_item_recon_diff_wp(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'cre_item_recon_diff_wp';         -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    --===============================
    -- ���[�J���J�[�\��
    --===============================
--
    CURSOR xxcok_sales_deduction_u_cur
    IS
      SELECT  xsd.sales_deduction_id                                          , -- �̔��T��ID
              xsd.base_code_to                                                , -- �U�֐拒�_
              xsd.source_category                                             , -- �쐬���敪
              xca.sale_base_code                                              , -- ���㋒�_�R�[�h
              xca.past_sale_base_code                                         , -- �O�����㋒�_�R�[�h
              xdir.tax_code                                                     -- �������ŃR�[�h
      FROM    xxcok_deduction_item_recon  xdir                                , -- �T��No�ʏ������
              xxcmm_cust_accounts         xca                                 , -- �ڋq�ǉ����
              fnd_lookup_values           dtyp                                , -- �f�[�^���
              xxcok_sales_deduction       xsd                                   -- �̔��T�����
      WHERE   xsd.recon_slip_num          =   gv_recon_slip_num
      AND     dtyp.lookup_type            =   cv_lookup_data_type
      AND     dtyp.lookup_code            =   xsd.data_type
      AND     dtyp.language               =   'JA'
      AND     dtyp.enabled_flag           =   cv_flag_y
      AND     dtyp.attribute2             IN  ('030', '040')
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     xdir.recon_slip_num         =   gv_recon_slip_num
      AND     xdir.deduction_chain_code   IN  (xca.intro_chain_code2, xsd.deduction_chain_code)
      AND     xdir.item_code              =   xsd.item_code
      FOR UPDATE OF xsd.recon_tax_code  NOWAIT;
--
    CURSOR xxcok_deduction_item_recon_cur
    IS
      SELECT  xdir.deduction_chain_code   deduction_chain_code  , -- �T���p�`�F�[���R�[�h
              xdir.item_code              item_code             , -- �i�ڃR�[�h
              xdir.tax_code               tax_code              , -- ����ŃR�[�h
              xdir.deduction_030          deduction             , -- �T���z(�ʏ�)
              xdir.difference_amt * -1    difference_amt        , -- �������z(�Ŕ�)
              xdir.difference_tax * -1    difference_tax          -- �������z(�����)
      FROM    xxcok_deduction_item_recon  xdir                    -- �T��No�ʏ������
      WHERE   xdir.recon_slip_num       =   gv_recon_slip_num
      AND   ( xdir.difference_amt       !=  0 OR
              xdir.difference_tax       !=  0 )
      ORDER BY  xdir.deduction_chain_code ,
                xdir.item_code            ;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �������ŃR�[�h�A�������v�㋒�_�̍X�V
    -- ============================================================
    FOR xxcok_sales_deduction_u_rec IN  xxcok_sales_deduction_u_cur LOOP
      UPDATE  xxcok_sales_deduction
      SET     recon_tax_code          = xxcok_sales_deduction_u_rec.tax_code,
              recon_base_code         = CASE  WHEN  xxcok_sales_deduction_u_rec.source_category IN  ('F', 'U') THEN
                                                xxcok_sales_deduction_u_rec.base_code_to
                                              WHEN  gd_gl_month < gd_process_month                            THEN
                                                xxcok_sales_deduction_u_rec.past_sale_base_code
                                              ELSE
                                                xxcok_sales_deduction_u_rec.sale_base_code
                                        END,
              last_updated_by         = cn_user_id            ,
              last_update_date        = SYSDATE               ,
              last_update_login       = cn_login_id           ,
              request_id              = cn_conc_request_id    ,
              program_application_id  = cn_prog_appl_id       ,
              program_id              = cn_conc_program_id    ,
              program_update_date     = SYSDATE
      WHERE   SALES_DEDUCTION_ID  = xxcok_sales_deduction_u_rec.SALES_DEDUCTION_ID;
    END LOOP;
--
    -- ============================================================
    -- �c���J�z�f�[�^�쐬
    -- ============================================================
    FOR xxcok_deduction_item_recon_rec IN  xxcok_deduction_item_recon_cur LOOP
--
      g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- �̔��T��ID
      g_xxcok_sales_deduction_rec.base_code_from          :=  '-'                                                 ;   -- �U�֌����_
      g_xxcok_sales_deduction_rec.base_code_to            :=  '-'                                                 ;   -- �U�֐拒�_
      g_xxcok_sales_deduction_rec.customer_code_from      :=  NULL                                                ;   -- �U�֌��ڋq�R�[�h
      g_xxcok_sales_deduction_rec.customer_code_to        :=  NULL                                                ;   -- �U�֐�ڋq�R�[�h
      g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_deduction_item_recon_rec.deduction_chain_code ;   -- �T���p�`�F�[���R�[�h
      g_xxcok_sales_deduction_rec.corp_code               :=  NULL                                                ;   -- ��ƃR�[�h
      g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- �v���
      g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_o                                           ;   -- �쐬���敪
      g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- �쐬������ID
      g_xxcok_sales_deduction_rec.condition_id            :=  NULL                                                ;   -- �T������ID
      g_xxcok_sales_deduction_rec.condition_no            :=  NULL                                                ;   -- �T���ԍ�
      g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- �T���ڍ�ID
      g_xxcok_sales_deduction_rec.data_type               :=  gv_data_type_030                                    ;   -- �f�[�^���
      g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- �X�e�[�^�X
      g_xxcok_sales_deduction_rec.item_code               :=  xxcok_deduction_item_recon_rec.item_code            ;   -- �i�ڃR�[�h
      g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- �̔��P��
      g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- �̔��P��
      g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- �̔�����
      g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- ����{�̋��z
      g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- �������Ŋz
      g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- �T���P��
      g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- �T���P��
      g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- �T������
      g_xxcok_sales_deduction_rec.deduction_amount        :=  xxcok_deduction_item_recon_rec.difference_amt       ;   -- �T���z
      g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_item_recon_rec.tax_code             ;   -- �ŃR�[�h
      g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- �ŗ�
      g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_item_recon_rec.tax_code             ;   -- �������ŃR�[�h
      g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- �������ŗ�
      g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  xxcok_deduction_item_recon_rec.difference_tax       ;   -- �T���Ŋz
      g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- ���l
      g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- �\����No.
      g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL�A�g�t���O
      g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL�v�㋒�_
      g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL�L����
      g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- ���J�o���[���t
      g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- ����t���O
      g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- ������v�㋒�_
      g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- ���GL�L����
      g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- ������{���[�U
      g_xxcok_sales_deduction_rec.recon_base_code         :=  NULL                                                ;   -- �������v�㋒�_
      g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- �x���`�[�ԍ�
      g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- �J�z���x���`�[�ԍ�
      g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- ����m��t���O
      g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL�A�gID
      g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- ���GL�A�gID
      g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- �쐬��
      g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- �쐬��
      g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- �ŏI�X�V��
      g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- �ŏI�X�V��
      g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- �ŏI�X�V���O�C��
      g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- �v��ID
      g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- �R���J�����g�E�v���O����ID
      g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- �v���O�����X�V��
--
      INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
    END LOOP;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[��O ***
    WHEN  global_lock_failure_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10632
                    );
      lv_errbuf :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END cre_item_recon_diff_wp;
--
  /**********************************************************************************
   * Procedure Name   : cre_num_recon_diff_wp
   * Description      : �T��No�ʌJ�z�f�[�^�쐬(A-4)
   ***********************************************************************************/
  PROCEDURE cre_num_recon_diff_wp(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'cre_num_recon_diff_wp';          -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_difference_amt_rest              xxcok_deduction_num_recon.difference_amt%TYPE;              -- �������z(�Ŕ�)_�c�z
    ln_difference_tax_rest              xxcok_deduction_num_recon.difference_tax%TYPE;              -- �������z(�����)_�c�z
    --===============================
    -- ���[�J���J�[�\��
    --===============================
--
    CURSOR xxcok_sales_deduction_u_cur
    IS
      SELECT  xsd.sales_deduction_id    sales_deduction_id  , -- �̔��T��ID
              xsd.base_code_to          base_code_to        , -- �U�֐拒�_
              xsd.source_category       source_category     , -- �쐬���敪
              xca.sale_base_code        sale_base_code      , -- ���㋒�_�R�[�h
              xca.past_sale_base_code   past_sale_base_code , -- �O�����㋒�_�R�[�h
              xdnr.payment_tax_code     payment_tax_code      -- �������ŃR�[�h
      FROM    xxcok_deduction_num_recon xdnr                , -- �T��No�ʏ������
              xxcmm_cust_accounts       xca                 , -- �ڋq�ǉ����
              xxcok_sales_deduction     xsd                   -- �̔��T�����
      WHERE   xsd.recon_slip_num          =   gv_recon_slip_num
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     xdnr.recon_slip_num         =   gv_recon_slip_num
      AND     xdnr.deduction_chain_code   IN  (xca.intro_chain_code2, xsd.deduction_chain_code)
      AND     xdnr.condition_no           =   xsd.condition_no
      AND     xdnr.tax_code               =   xsd.tax_code
      FOR UPDATE OF xsd.recon_tax_code  NOWAIT;
--
    CURSOR xxcok_deduction_num_recon_cur(
      p_carryover_pay_off_flg VARCHAR2                            -- �J�z�z�S�z���Z�t���O
    )
    IS
      SELECT  xdnr.deduction_chain_code   deduction_chain_code  , -- �T���p�`�F�[���R�[�h
              xdnr.data_type              data_type             , -- �f�[�^���
              xdnr.condition_no           condition_no          , -- �T���ԍ�
              xdnr.tax_code               tax_code              , -- ����ŃR�[�h
              xdnr.payment_tax_code       payment_tax_code      , -- �x�����ŃR�[�h
              xdnr.deduction_amt          denominator           , -- ��_����
              xdnr.difference_amt * -1    difference_amt        , -- �������z(�Ŕ�)
              xdnr.difference_tax * -1    difference_tax          -- �������z(�����)
      FROM    xxcok_deduction_num_recon   xdnr                    -- �T��No�ʏ������
      WHERE   xdnr.recon_slip_num         =   gv_recon_slip_num
      AND     xdnr.target_flag            =   cv_flag_y
      AND     xdnr.carryover_pay_off_flg  =   p_carryover_pay_off_flg
      AND   ( xdnr.difference_amt         !=  0 OR
              xdnr.difference_tax         !=  0 )
      ORDER BY  xdnr.recon_line_num     ,
                xdnr.deduction_line_num ;
--
    CURSOR xxcok_sales_deduction_s_cur(
      p_chain_code    VARCHAR2                                  -- �T���p�`�F�[���R�[�h
    , p_condition_no  VARCHAR2                                  -- �T���ԍ�
    , p_tax_code      VARCHAR2                                  -- ����ŃR�[�h
    )
    IS
      SELECT  xsd.customer_code_to      customer_code_to      , -- �U�֐�ڋq�R�[�h
              xsd.deduction_chain_code  deduction_chain_code  , -- �T���p�`�F�[���R�[�h
              xsd.corp_code             corp_code             , -- ��ƃR�[�h
              xsd.condition_id          condition_id          , -- �T������ID
              xsd.data_type             data_type             , -- �f�[�^���
              xsd.item_code             item_code             , -- �i�ڃR�[�h
              xsd.recon_base_code       recon_base_code       , -- �������v�㋒�_
              SUM(xsd.deduction_amount) numerator               -- ��_���q
      FROM    xxcmm_cust_accounts       xca                   , -- �ڋq�ǉ����
              xxcok_sales_deduction     xsd                     -- �̔��T�����
      WHERE   xsd.recon_slip_num          = gv_recon_slip_num
      AND     xsd.condition_no            = p_condition_no
      AND     xsd.tax_code                = p_tax_code
      AND     xca.customer_code(+)        =   xsd.customer_code_to
      AND     p_chain_code                IN  (xca.intro_chain_code2, xsd.deduction_chain_code)
      GROUP BY  xsd.customer_code_to    ,
                xsd.deduction_chain_code,
                xsd.corp_code           ,
                xsd.condition_id        ,
                xsd.data_type           ,
                xsd.item_code           ,
                xsd.recon_base_code     
      ORDER BY  xsd.customer_code_to,
                xsd.item_code       ;
--
    TYPE xxcok_sales_deduction_s_ttype  IS TABLE OF xxcok_sales_deduction_s_cur%ROWTYPE;
    xxcok_sales_deduction_s_tab         xxcok_sales_deduction_s_ttype;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �������ŃR�[�h�A�������v�㋒�_�̍X�V
    -- ============================================================
    FOR xxcok_sales_deduction_u_rec IN  xxcok_sales_deduction_u_cur LOOP
      UPDATE  xxcok_sales_deduction
      SET     recon_tax_code          = xxcok_sales_deduction_u_rec.payment_tax_code,
              recon_base_code         = CASE  WHEN  xxcok_sales_deduction_u_rec.source_category IN  ('F', 'U') THEN
                                                xxcok_sales_deduction_u_rec.base_code_to
                                              WHEN  gd_gl_month < gd_process_month                            THEN
                                                xxcok_sales_deduction_u_rec.past_sale_base_code
                                              ELSE
                                                xxcok_sales_deduction_u_rec.sale_base_code
                                        END,
              last_updated_by         = cn_user_id            ,
              last_update_date        = SYSDATE               ,
              last_update_login       = cn_login_id           ,
              request_id              = cn_conc_request_id    ,
              program_application_id  = cn_prog_appl_id       ,
              program_id              = cn_conc_program_id    ,
              program_update_date     = SYSDATE
      WHERE   SALES_DEDUCTION_ID  = xxcok_sales_deduction_u_rec.SALES_DEDUCTION_ID;
    END LOOP;
--
    -- ============================================================
    -- �c���J�z�f�[�^�쐬
    -- ============================================================
    FOR xxcok_deduction_num_recon_rec IN  xxcok_deduction_num_recon_cur(cv_flag_n) LOOP
--
      g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- �̔��T��ID
      g_xxcok_sales_deduction_rec.base_code_from          :=  '-'                                                 ;   -- �U�֌����_
      g_xxcok_sales_deduction_rec.base_code_to            :=  '-'                                                 ;   -- �U�֐拒�_
      g_xxcok_sales_deduction_rec.customer_code_from      :=  NULL                                                ;   -- �U�֌��ڋq�R�[�h
      g_xxcok_sales_deduction_rec.customer_code_to        :=  NULL                                                ;   -- �U�֐�ڋq�R�[�h
      g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_deduction_num_recon_rec.deduction_chain_code  ;   -- �T���p�`�F�[���R�[�h
      g_xxcok_sales_deduction_rec.corp_code               :=  NULL                                                ;   -- ��ƃR�[�h
      g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- �v���
      g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_o                                           ;   -- �쐬���敪
      g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- �쐬������ID
      g_xxcok_sales_deduction_rec.condition_id            :=  NULL                                                ;   -- �T������ID
      g_xxcok_sales_deduction_rec.condition_no            :=  xxcok_deduction_num_recon_rec.condition_no          ;   -- �T���ԍ�
      g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- �T���ڍ�ID
      g_xxcok_sales_deduction_rec.data_type               :=  xxcok_deduction_num_recon_rec.data_type             ;   -- �f�[�^���
      g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- �X�e�[�^�X
      g_xxcok_sales_deduction_rec.item_code               :=  NULL                                                ;   -- �i�ڃR�[�h
      g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- �̔��P��
      g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- �̔��P��
      g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- �̔�����
      g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- ����{�̋��z
      g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- �������Ŋz
      g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- �T���P��
      g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- �T���P��
      g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- �T������
      g_xxcok_sales_deduction_rec.deduction_amount        :=  xxcok_deduction_num_recon_rec.difference_amt        ;   -- �T���z
      g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_num_recon_rec.tax_code              ;   -- �ŃR�[�h
      g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- �ŗ�
      g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_num_recon_rec.payment_tax_code      ;   -- �������ŃR�[�h
      g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- �������ŗ�
      g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  xxcok_deduction_num_recon_rec.difference_tax        ;   -- �T���Ŋz
      g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- ���l
      g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- �\����No.
      g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL�A�g�t���O
      g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL�v�㋒�_
      g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL�L����
      g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- ���J�o���[���t
      g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- ����t���O
      g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- ������v�㋒�_
      g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- ���GL�L����
      g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- ������{���[�U
      g_xxcok_sales_deduction_rec.recon_base_code         :=  NULL                                                ;   -- �������v�㋒�_
      g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- �x���`�[�ԍ�
      g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- �J�z���x���`�[�ԍ�
      g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- ����m��t���O
      g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL�A�gID
      g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- ���GL�A�gID
      g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- �쐬��
      g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- �쐬��
      g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- �ŏI�X�V��
      g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- �ŏI�X�V��
      g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- �ŏI�X�V���O�C��
      g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- �v��ID
      g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- �R���J�����g�E�v���O����ID
      g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- �v���O�����X�V��
--
      INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
    END LOOP;
--
    -- ============================================================
    -- ���z�����f�[�^�쐬
    -- ============================================================
    FOR xxcok_deduction_num_recon_rec IN  xxcok_deduction_num_recon_cur(cv_flag_y) LOOP
--
      ln_difference_amt_rest  :=  xxcok_deduction_num_recon_rec.difference_amt;
      ln_difference_tax_rest  :=  xxcok_deduction_num_recon_rec.difference_tax;
--
      OPEN  xxcok_sales_deduction_s_cur(xxcok_deduction_num_recon_rec.deduction_chain_code, xxcok_deduction_num_recon_rec.condition_no, xxcok_deduction_num_recon_rec.tax_code);
      FETCH xxcok_sales_deduction_s_cur BULK COLLECT INTO xxcok_sales_deduction_s_tab;
      CLOSE xxcok_sales_deduction_s_cur;
--
      FOR i IN 1..xxcok_sales_deduction_s_tab.COUNT LOOP
        IF i = xxcok_sales_deduction_s_tab.COUNT THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ln_difference_amt_rest;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ln_difference_tax_rest;
        ELSIF xxcok_deduction_num_recon_rec.denominator = 0 THEN
          g_xxcok_sales_deduction_rec.deduction_amount      :=  0;
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  0;
        ELSE
          g_xxcok_sales_deduction_rec.deduction_amount      :=  ROUND(  xxcok_deduction_num_recon_rec.difference_amt
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
          g_xxcok_sales_deduction_rec.deduction_tax_amount  :=  ROUND(  xxcok_deduction_num_recon_rec.difference_tax
                                                                      * xxcok_sales_deduction_s_tab(i).numerator
                                                                      / xxcok_deduction_num_recon_rec.denominator     );
        END IF;
--
        IF  g_xxcok_sales_deduction_rec.deduction_amount  !=  0 OR  g_xxcok_sales_deduction_rec.deduction_tax_amount  !=0 THEN
          g_xxcok_sales_deduction_rec.sales_deduction_id      :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- �̔��T��ID
          g_xxcok_sales_deduction_rec.base_code_from          :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �U�֌����_
          g_xxcok_sales_deduction_rec.base_code_to            :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �U�֐拒�_
          g_xxcok_sales_deduction_rec.customer_code_from      :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- �U�֌��ڋq�R�[�h
          g_xxcok_sales_deduction_rec.customer_code_to        :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- �U�֐�ڋq�R�[�h
          g_xxcok_sales_deduction_rec.deduction_chain_code    :=  xxcok_sales_deduction_s_tab(i).deduction_chain_code ;   -- �T���p�`�F�[���R�[�h
          g_xxcok_sales_deduction_rec.corp_code               :=  xxcok_sales_deduction_s_tab(i).corp_code            ;   -- ��ƃR�[�h
          g_xxcok_sales_deduction_rec.record_date             :=  gd_target_date_end                                  ;   -- �v���
          g_xxcok_sales_deduction_rec.source_category         :=  cv_flag_d                                           ;   -- �쐬���敪
          g_xxcok_sales_deduction_rec.source_line_id          :=  NULL                                                ;   -- �쐬������ID
          g_xxcok_sales_deduction_rec.condition_id            :=  xxcok_sales_deduction_s_tab(i).condition_id         ;   -- �T������ID
          g_xxcok_sales_deduction_rec.condition_no            :=  xxcok_deduction_num_recon_rec.condition_no          ;   -- �T���ԍ�
          g_xxcok_sales_deduction_rec.condition_line_id       :=  NULL                                                ;   -- �T���ڍ�ID
          g_xxcok_sales_deduction_rec.data_type               :=  xxcok_sales_deduction_s_tab(i).data_type            ;   -- �f�[�^���
          g_xxcok_sales_deduction_rec.status                  :=  cv_flag_n                                           ;   -- �X�e�[�^�X
          g_xxcok_sales_deduction_rec.item_code               :=  xxcok_sales_deduction_s_tab(i).item_code            ;   -- �i�ڃR�[�h
          g_xxcok_sales_deduction_rec.sales_uom_code          :=  NULL                                                ;   -- �̔��P��
          g_xxcok_sales_deduction_rec.sales_unit_price        :=  NULL                                                ;   -- �̔��P��
          g_xxcok_sales_deduction_rec.sales_quantity          :=  NULL                                                ;   -- �̔�����
          g_xxcok_sales_deduction_rec.sale_pure_amount        :=  NULL                                                ;   -- ����{�̋��z
          g_xxcok_sales_deduction_rec.sale_tax_amount         :=  NULL                                                ;   -- �������Ŋz
          g_xxcok_sales_deduction_rec.deduction_uom_code      :=  NULL                                                ;   -- �T���P��
          g_xxcok_sales_deduction_rec.deduction_unit_price    :=  NULL                                                ;   -- �T���P��
          g_xxcok_sales_deduction_rec.deduction_quantity      :=  NULL                                                ;   -- �T������
--        g_xxcok_sales_deduction_rec.deduction_amount        :=  (��L�ŎZ�o��)                                      ;   -- �T���z
          g_xxcok_sales_deduction_rec.tax_code                :=  xxcok_deduction_num_recon_rec.tax_code              ;   -- �ŃR�[�h
          g_xxcok_sales_deduction_rec.tax_rate                :=  NULL                                                ;   -- �ŗ�
          g_xxcok_sales_deduction_rec.recon_tax_code          :=  xxcok_deduction_num_recon_rec.payment_tax_code      ;   -- �������ŃR�[�h
          g_xxcok_sales_deduction_rec.recon_tax_rate          :=  NULL                                                ;   -- �������ŗ�
--        g_xxcok_sales_deduction_rec.deduction_tax_amount    :=  (��L�ŎZ�o��)                                      ;   -- �T���Ŋz
          g_xxcok_sales_deduction_rec.remarks                 :=  NULL                                                ;   -- ���l
          g_xxcok_sales_deduction_rec.application_no          :=  NULL                                                ;   -- �\����No.
          g_xxcok_sales_deduction_rec.gl_if_flag              :=  cv_flag_o                                           ;   -- GL�A�g�t���O
          g_xxcok_sales_deduction_rec.gl_base_code            :=  NULL                                                ;   -- GL�v�㋒�_
          g_xxcok_sales_deduction_rec.gl_date                 :=  NULL                                                ;   -- GL�L����
          g_xxcok_sales_deduction_rec.recovery_date           :=  NULL                                                ;   -- ���J�o���[���t
          g_xxcok_sales_deduction_rec.cancel_flag             :=  cv_flag_n                                           ;   -- ����t���O
          g_xxcok_sales_deduction_rec.cancel_base_code        :=  NULL                                                ;   -- ������v�㋒�_
          g_xxcok_sales_deduction_rec.cancel_gl_date          :=  NULL                                                ;   -- ���GL�L����
          g_xxcok_sales_deduction_rec.cancel_user             :=  NULL                                                ;   -- ������{���[�U
          g_xxcok_sales_deduction_rec.recon_base_code         :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- �������v�㋒�_
          g_xxcok_sales_deduction_rec.recon_slip_num          :=  gv_recon_slip_num                                   ;   -- �x���`�[�ԍ�
          g_xxcok_sales_deduction_rec.carry_payment_slip_num  :=  gv_recon_slip_num                                   ;   -- �J�z���x���`�[�ԍ�
          g_xxcok_sales_deduction_rec.report_decision_flag    :=  NULL                                                ;   -- ����m��t���O
          g_xxcok_sales_deduction_rec.gl_interface_id         :=  NULL                                                ;   -- GL�A�gID
          g_xxcok_sales_deduction_rec.cancel_gl_interface_id  :=  NULL                                                ;   -- ���GL�A�gID
          g_xxcok_sales_deduction_rec.created_by              :=  cn_user_id                                          ;   -- �쐬��
          g_xxcok_sales_deduction_rec.creation_date           :=  SYSDATE                                             ;   -- �쐬��
          g_xxcok_sales_deduction_rec.last_updated_by         :=  cn_user_id                                          ;   -- �ŏI�X�V��
          g_xxcok_sales_deduction_rec.last_update_date        :=  SYSDATE                                             ;   -- �ŏI�X�V��
          g_xxcok_sales_deduction_rec.last_update_login       :=  cn_login_id                                         ;   -- �ŏI�X�V���O�C��
          g_xxcok_sales_deduction_rec.request_id              :=  cn_conc_request_id                                  ;   -- �v��ID
          g_xxcok_sales_deduction_rec.program_application_id  :=  cn_prog_appl_id                                     ;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          g_xxcok_sales_deduction_rec.program_id              :=  cn_conc_program_id                                  ;   -- �R���J�����g�E�v���O����ID
          g_xxcok_sales_deduction_rec.program_update_date     :=  SYSDATE                                             ;   -- �v���O�����X�V��
--
          INSERT  INTO  xxcok_sales_deduction VALUES  g_xxcok_sales_deduction_rec;
--
          ln_difference_amt_rest  :=  ln_difference_amt_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_AMOUNT    ;
          ln_difference_tax_rest  :=  ln_difference_tax_rest  - g_xxcok_sales_deduction_rec.DEDUCTION_TAX_AMOUNT;
        END IF;
--
      END LOOP;
--
    END LOOP;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[��O ***
    WHEN  global_lock_failure_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10632
                    );
      lv_errbuf :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END cre_num_recon_diff_wp;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- =============================================================
    -- ��������(A-1)�̌Ăяo��
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    IF  gv_interface_div  = cv_div_ap THEN
      -- ============================================================
      -- �T��No�ʍ��z�f�[�^�쐬(A-2)�̌Ăяo��
      -- ============================================================
      cre_num_recon_diff_ap(
        ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
      , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
      , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF  lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF  gv_interface_div  = cv_div_wp THEN
      -- ============================================================
      -- ���i�ʌJ�z�f�[�^�쐬(A-3)�̌Ăяo��
      -- ============================================================
      cre_item_recon_diff_wp(
        ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
      , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
      , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF  lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================================
      -- �T��No�ʌJ�z�f�[�^�쐬(A-4)�̌Ăяo��
      -- ============================================================
      cre_num_recon_diff_wp(
        ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
      , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
      , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF  lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--    COMMIT;                           -- �R�~�b�g�͌Ăь��ōs�Ȃ��B
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    ov_errbuf                           OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                          OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                           OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_recon_slip_num                   IN  VARCHAR2        -- �x���`�[�ԍ�
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';       -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    gv_recon_slip_num :=  iv_recon_slip_num;                -- �x���`�[�ԍ�
    ov_retcode        :=  cv_status_normal;
--
    -- ============================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ============================================================
    submain(
      ov_errbuf         =>  lv_errbuf                       -- �G���[�E���b�Z�[�W
    , ov_retcode        =>  lv_retcode                      -- ���^�[���E�R�[�h
    , ov_errmsg         =>  lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    ov_errbuf   :=  lv_errbuf;
    ov_retcode  :=  lv_retcode;
    ov_errmsg   :=  lv_errmsg;
--
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF  ov_retcode  = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ROLLBACK;
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
  END main;
END XXCOK024A19C;
/
