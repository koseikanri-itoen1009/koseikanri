CREATE OR REPLACE PACKAGE BODY XXCOK008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A06C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F������ѐU�֏��̍쐬�i�U�֊����j �̔����� MD050_COK_008_A06
 * Version          : 1.5
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  upd_detail_no               ���הԍ��X�V(A-14)
 *  upd_slip_no                 �`�[�ԍ��X�V(A-13)
 *  get_slip_detail_target      �`�[�ԍ����הԍ��X�V�Ώے��o(A-12)
 *  ins_sales_exp               ������ѐU�փ��R�[�h�ǉ�(A-10)
 *  adj_data                    �Z�o�f�[�^�̒���(A-9)
 *  chk_data                    �Z�o�f�[�^�̐������`�F�b�N(A-8)
 *  chk_covered                 ����S���ݒ�̊m�F(A-7)
 *  get_offset_exp              ������ѐU�֌����E�f�[�^���o(A-11)
 *  get_sales_exp               �̔����я��e�[�u�����o(A-6)
 *  get_sales_exp_sum           �̔����я��e�[�u���W�v���o(A-5)
 *  upd_correction_flg          �U�߃t���O�X�V(A-4)
 *  ins_correction              ������ѐU�֏��U�߃f�[�^�쐬(A-3)
 *  get_period                  �����Ώۉ�v���Ԏ擾(A-2)
 *  init                        ��������(A-1)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   M.Hiruta         �V�K�쐬
 *  2009/02/18    1.1   T.OSADA          [��QCOK_042]�U�߃f�[�^�쐬���̏��nI/F�t���O�A�d��쐬�t���O�C��
 *  2009/04/02    1.2   M.Hiruta         [��QT1_0089]�U�֌��Ɛ悪�����ڋq�ł���ꍇ���A�W�v�������s���悤�C��
 *                                       [��QT1_0103]�S�����_�A�S���c�ƈ����ύX���ꂽ�ꍇ�̏��
 *                                                    ���m�Ɏ擾�ł���悤�C��
 *                                       [��QT1_0115]�̔����уe�[�u�����o���̍i���ݏ����ɂ����āA
 *                                                    �u�������v���u�[�i���v�ɏC��
 *                                       [��QT1_0190]��P�ʊ��Z���s���ɃG���[�I������悤�C��
 *                                       [��QT1_0196]�̔����уe�[�u�����o���̍i���ݏ����ɂ����āA
 *                                                    1.A-5�W�v�����u�[�i���v�̐��x��"�N��"�܂łɏC��
 *                                                    2.A-6�AA-11�W�v�����u����v����v��A-5�Ŏ擾�����u�[�i���v��
 *                                                      �̔N�����Q�Ƃ���悤�C��
 *  2009/04/27    1.3   M.Hiruta         [��QT1_0715]�U�֌��ƂȂ�f�[�^�̂������ʂ�1�̃f�[�^�ɂ����āA
 *                                                    1.�U�֊������΂��Ă���ꍇ�A�U�֊����̑傫���f�[�^��
 *                                                      ���z���񂹂�悤�C��
 *                                                    2.�U�֊������ϓ��ł���ꍇ�A�ڋq�R�[�h�̎Ⴂ���R�[�h��
 *                                                      ���z���񂹂�悤�C��
 *  2009/06/04    1.4   M.Hiruta         [��QT1_1325]�U�߃f�[�^�쐬�����ō쐬�����f�[�^�̓��t���A
 *                                                    �U�ߑΏۃf�[�^�̓��t�Ɋ�Â��Ď擾����悤�ύX
 *                                                    1.�U�߃f�[�^���挎�f�[�^�ł���ꍇ�ː挎�����t
 *                                                    2.�U�߃f�[�^�������f�[�^�ł���ꍇ�ˋƖ��������t
 *  2009/07/03    1.5   M.Hiruta         [��Q0000422]�U�߃f�[�^�쐬�����ō쐬�����Ɩ��o�^���t���A
 *                                                    �Ɩ��������t�֕ύX
 *
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  -- �X�e�[�^�X
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER       := FND_GLOBAL.USER_ID;         -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER       := FND_GLOBAL.USER_ID;         -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER       := FND_GLOBAL.LOGIN_ID;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := FND_GLOBAL.CONC_REQUEST_ID; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := FND_GLOBAL.PROG_APPL_ID;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := FND_GLOBAL.CONC_PROGRAM_ID; -- PROGRAM_ID
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)  := '.';
  -- �A�v���P�[�V�����Z�k��
  cv_appli_short_name_xxcok CONSTANT VARCHAR2(5)  := 'XXCOK'; -- ��_�A�v���P�[�V�����Z�k��
  cv_appli_short_name_xxccp CONSTANT VARCHAR2(5)  := 'XXCCP'; -- ����_�A�v���P�[�V�����Z�k��
  cv_appli_short_name_ar    CONSTANT VARCHAR2(2)  := 'AR';    -- ���|_�A�v���P�[�V�����Z�k��
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCOK008A06C'; -- �p�b�P�[�W��
  -- ���b�Z�[�W
  cv_token_name1            CONSTANT VARCHAR2(5)  := 'COUNT';            -- ���������̃g�[�N����
  cv_target_count_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
  cv_normal_count_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
  cv_err_count_msg          CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
  cv_skip_count_msg         CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  cv_err_msg                CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- �G���[�I���ꕔ�������b�Z�[�W
  cv_msg_xxcok1_00023       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00023'; -- A-1���b�Z�[�W
  cv_msg_xxcok1_10036       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10036'; -- A-1���b�Z�[�W
  cv_msg_xxcok1_00008       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00008'; -- A-1���b�Z�[�W
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- A-1���b�Z�[�W
  cv_msg_xxcok1_00042       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00042'; -- A-2���b�Z�[�W
  cv_msg_xxcok1_10033       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10033'; -- A-3���b�Z�[�W
  cv_msg_xxcok1_10012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10012'; -- A-4 A-12���b�Z�[�W
  cv_msg_xxcok1_10035       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10035'; -- A-4 A-12���b�Z�[�W
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  cv_msg_xxcok1_10452       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10452'; -- A-6 A-11���b�Z�[�W
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  cv_msg_xxcok1_00045       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00045'; -- A-7���b�Z�[�W
  cv_msg_xxcok1_10034       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10034'; -- A-10���b�Z�[�W
  -- �g�[�N����
  cv_info_class             CONSTANT VARCHAR2(10) := 'INFO_CLASS';     -- �����
  cv_proc_date              CONSTANT VARCHAR2(9)  := 'PROC_DATE';      -- �V�X�e�����t�̔N��
  cv_customer_code          CONSTANT VARCHAR2(13) := 'CUSTOMER_CODE';  -- �ڋq�R�[�h
  cv_customer_name          CONSTANT VARCHAR2(13) := 'CUSTOMER_NAME';  -- �ڋq��
  cv_tanto_loc_code         CONSTANT VARCHAR2(14) := 'TANTO_LOC_CODE'; -- ���㋒�_�R�[�h
  cv_tanto_code             CONSTANT VARCHAR2(10) := 'TANTO_CODE';     -- �S���c�ƈ�
  cv_sales_date             CONSTANT VARCHAR2(10) := 'SALES_DATE';     -- ����v���
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';  -- ���_�R�[�h
  cv_item_code              CONSTANT VARCHAR2(9)  := 'ITEM_CODE';      -- �i�ڃR�[�h
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  cv_dlv_uom_code           CONSTANT VARCHAR2(12) := 'DLV_UOM_CODE';   -- �P��
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
  -- �f�[�^�p�Œ�l
  cv_correction_off_flg     CONSTANT VARCHAR2(1)  := '0';  -- �U�߃I�t
  cv_correction_on_flg      CONSTANT VARCHAR2(1)  := '1';  -- �U�߃I��
  cv_report_news_flg        CONSTANT VARCHAR2(1)  := '0';  -- ����
  cv_report_decision_flg    CONSTANT VARCHAR2(1)  := '1';  -- �m��
  cv_info_if_flag           CONSTANT VARCHAR2(1)  := '0';  -- ���nI/F�t���O
  cv_gl_if_flag             CONSTANT VARCHAR2(1)  := '0';  -- �d��쐬�t���O
  cv_invoice_class_01       CONSTANT VARCHAR2(1)  := '1';  -- �[�i�`�[�敪:�[�i
  cv_invoice_class_02       CONSTANT VARCHAR2(1)  := '2';  -- �[�i�`�[�敪:�ԕi
  cv_invoice_class_03       CONSTANT VARCHAR2(1)  := '3';  -- �[�i�`�[�敪:�[�i����
  cv_invoice_class_04       CONSTANT VARCHAR2(1)  := '4';  -- �[�i�`�[�敪:�ԕi����
  cv_transfer_div           CONSTANT VARCHAR2(1)  := '1';  -- �U�֑Ώ�
  cv_cust_class_customer    CONSTANT VARCHAR2(2)  := '10'; -- �ڋq�敪:�ڋq
  cv_duns_number_c          CONSTANT VARCHAR2(2)  := '40'; -- �ڋq�X�e�[�^�X:�ڋq
  cv_invalid_1_flg          CONSTANT VARCHAR2(1)  := '1';  -- ����
  cv_invalid_0_flg          CONSTANT VARCHAR2(1)  := '0';  -- �L��
  cv_selling_trns_type      CONSTANT VARCHAR2(1)  := '0';          -- ���ѐU�֋敪
  cv_selling_type           CONSTANT VARCHAR2(1)  := '1';          -- ����敪:�ʏ�
  cv_selling_return_type    CONSTANT VARCHAR2(1)  := '1';          -- ����ԕi�敪:�[�i
  cv_dlv_from_type          CONSTANT VARCHAR2(1)  := '6';          -- �[�i�`�ԋ敪:���ѐU��
  cv_article_code           CONSTANT VARCHAR2(10) := '0000000000'; -- �����R�[�h
  cv_card_selling_type      CONSTANT VARCHAR2(1)  := '0';          -- �J�[�h����敪:����
  cv_h_c                    CONSTANT VARCHAR2(1)  := '1';          -- H��C:COLD
  cv_column_no              CONSTANT VARCHAR2(2)  := '00';         -- �R����No
  cv_detail_num_j           CONSTANT VARCHAR2(1)  := 'J';          -- ���הԍ��ړ�����
  cv_sequence_s02_size      CONSTANT VARCHAR2(10) := 'FM00000000'; -- �V�[�P���X�ϊ���̌���
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt        NUMBER      DEFAULT 0;     -- �Ώی���     A-6�ŃJ�E���g
  gn_normal_cnt        NUMBER      DEFAULT 0;     -- ���팏��     A-10�ŃJ�E���g
  gn_error_cnt         NUMBER      DEFAULT 0;     -- �G���[����   submain�ŃJ�E���g
  gn_skip_cnt          NUMBER      DEFAULT 0;     -- �X�L�b�v���� A-6�ŃJ�E���g
  gv_info_class        VARCHAR2(1) DEFAULT NULL;  -- �����
  gn_set_of_books_id   NUMBER      DEFAULT NULL;  -- ��v����ID
  gd_process_date      DATE        DEFAULT NULL;  -- �Ɩ����t
  gv_past_month        VARCHAR2(6) DEFAULT NULL;  -- �挎�̓��t
  gv_current_month     VARCHAR2(6) DEFAULT NULL;  -- �����̓��t
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  -- ���������ʗ�O
  global_process_expt    EXCEPTION;
  -- ���ʊ֐���O
  global_api_expt        EXCEPTION;
  -- ���ʊ֐�OTHERS��O
  global_api_others_expt EXCEPTION;
  -- ���b�N�G���[
  lock_expt              EXCEPTION;
  -- ===============================
  -- �v���O�}
  -- ===============================
  -- ���ʊ֐�OTHERS��O
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(lock_expt,-54);
--
  /**********************************************************************************
   * Procedure Name   : upd_detail_no
   * Description      : ���הԍ��X�V(A-14)
   ***********************************************************************************/
  PROCEDURE upd_detail_no(
    ov_errbuf    OUT VARCHAR2
  , ov_retcode   OUT VARCHAR2
  , ov_errmsg    OUT VARCHAR2
  , iv_slip_no   IN  VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'upd_detail_no';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ������ѐU�֏��e�[�u���X�V�i�X�V�Ɏ��s���ďꍇ�͗�O�����֑J�ځj
    -- ���הԍ�
    -- DENSE_RANK�֐��ł́A�u�[�i�P���������Ƀ\�[�g�������ԁv���擾����B
    -- ===============================
    UPDATE xxcok_selling_trns_info xsti
    SET    xsti.detail_no = (
             SELECT detail_no
             FROM   (
                    SELECT DENSE_RANK() OVER(ORDER BY xsti2.delivery_unit_price) detail_no
                         , xsti2.selling_trns_info_id
                    FROM   xxcok_selling_trns_info xsti2
                    WHERE  xsti2.slip_no    = iv_slip_no 
                    AND    xsti2.detail_no IS NULL
                    ) xsti3
             WHERE xsti.selling_trns_info_id = xsti3.selling_trns_info_id)
         , xsti.last_update_date    = SYSDATE
         , xsti.program_update_date = SYSDATE
    WHERE  xsti.slip_no    = iv_slip_no
    AND    xsti.detail_no IS NULL;
--
  EXCEPTION
    -- �f�[�^�X�V�G���[
    WHEN OTHERS THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10035
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
  END upd_detail_no;
--
  /**********************************************************************************
   * Procedure Name   : upd_slip_no
   * Description      : �`�[�ԍ��X�V(A-13)
   ***********************************************************************************/
  PROCEDURE upd_slip_no(
    ov_errbuf    OUT VARCHAR2
  , ov_retcode   OUT VARCHAR2
  , ov_errmsg    OUT VARCHAR2
  , iv_base_code IN  VARCHAR2
  , iv_cust_code IN  VARCHAR2
  , iv_item_code IN  VARCHAR2
  , iv_slip_no   IN  VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(11) := 'upd_slip_no';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ������ѐU�֏��e�[�u���X�V�i�X�V�Ɏ��s���ďꍇ�͗�O�����֑J�ځj
    -- �`�[�ԍ�
    -- ===============================
    UPDATE xxcok_selling_trns_info xsti
    SET    xsti.slip_no    = iv_slip_no
    WHERE  xsti.base_code  = iv_base_code
    AND    xsti.cust_code  = iv_cust_code
    AND    xsti.item_code  = iv_item_code
    AND    xsti.slip_no   IS NULL
    AND    xsti.detail_no IS NULL;
--
  EXCEPTION
    -- �f�[�^�X�V�G���[
    WHEN OTHERS THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10035
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
  END upd_slip_no;
--
  /**********************************************************************************
   * Procedure Name   : get_slip_detail_target
   * Description      : �`�[�ԍ����הԍ��X�V�Ώے��o(A-12)
   ***********************************************************************************/
  PROCEDURE get_slip_detail_target(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(22) := 'get_slip_detail_target';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;
    lv_slip_no  VARCHAR2(9)    DEFAULT NULL;
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    -- ���b�N�擾�p
    CURSOR upd_lock_cur
    IS
      SELECT xsti.base_code       AS base_code
           , xsti.cust_code       AS cust_code
           , xsti.item_code       AS item_code
      FROM   xxcok_selling_trns_info xsti
      WHERE  xsti.slip_no   IS NULL
      AND    xsti.detail_no IS NULL
      FOR UPDATE NOWAIT;
--
    -- �`�[�ԍ��X�V�J�[�\��
    CURSOR upd_slip_detail_cur
    IS
      SELECT xsti.base_code       AS base_code
           , xsti.cust_code       AS cust_code
           , xsti.item_code       AS item_code
      FROM   xxcok_selling_trns_info xsti
      WHERE  xsti.slip_no   IS NULL
      AND    xsti.detail_no IS NULL
      GROUP BY
             xsti.base_code
           , xsti.cust_code
           , xsti.item_code
      ORDER BY
             xsti.base_code
           , xsti.cust_code
           , xsti.item_code;
--
    -- �J�[�\���^���R�[�h
    upd_slip_detail_rec upd_slip_detail_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    update_error_expt EXCEPTION; -- ������ѐU�֏��e�[�u���A�b�v�f�[�g�G���[
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- ������ѐU�֏��e�[�u���̃��b�N�擾
    -- ===============================
    OPEN  upd_lock_cur;
    CLOSE upd_lock_cur;
--
    -- ===============================
    -- ������ѐU�֏��e�[�u���X�V�X�V�Ώے��o
    -- ===============================
    OPEN  upd_slip_detail_cur;
    LOOP
      FETCH upd_slip_detail_cur INTO upd_slip_detail_rec;
      EXIT WHEN upd_slip_detail_cur%NOTFOUND;
--
        -- �`�[�ԍ��擾
        SELECT cv_detail_num_j || TO_CHAR(xxcok_selling_trns_info_s02.NEXTVAL,cv_sequence_s02_size)
        INTO   lv_slip_no
        FROM   DUAL;
--
        -- =============================================================
        -- A-13.�`�[�ԍ��X�V
        -- =============================================================
        upd_slip_no(
          ov_errbuf    => lv_errbuf
        , ov_retcode   => lv_retcode
        , ov_errmsg    => lv_errmsg
        , iv_base_code => upd_slip_detail_rec.base_code  -- ���_�R�[�h
        , iv_cust_code => upd_slip_detail_rec.cust_code  -- �ڋq�R�[�h
        , iv_item_code => upd_slip_detail_rec.item_code  -- �i�ڃR�[�h
        , iv_slip_no   => lv_slip_no                     -- �`�[�ԍ�
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-14.���הԍ��X�V
        -- =============================================================
        upd_detail_no(
          ov_errbuf  => lv_errbuf
        , ov_retcode => lv_retcode
        , ov_errmsg  => lv_errmsg
        , iv_slip_no => lv_slip_no  -- �`�[�ԍ�
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
    END LOOP;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10012
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- ���������ʗ�O�n���h��
    WHEN global_process_expt THEN
      -- �����X�e�[�^�X���G���[�Ƃ���A-12���I������B
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( upd_slip_detail_cur%ISOPEN ) THEN
        CLOSE upd_slip_detail_cur;
      END IF;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( upd_slip_detail_cur%ISOPEN ) THEN
        CLOSE upd_slip_detail_cur;
      END IF;
  END get_slip_detail_target;
--
  /**********************************************************************************
   * Procedure Name   : ins_sales_exp
   * Description      : ������ѐU�փ��R�[�h�ǉ�(A-10)
   ***********************************************************************************/
  PROCEDURE ins_sales_exp(
    ov_errbuf              OUT VARCHAR2
  , ov_retcode             OUT VARCHAR2
  , ov_errmsg              OUT VARCHAR2
  , iv_delivery_date        IN VARCHAR2  -- ����v���
  , iv_to_base_code         IN VARCHAR2  -- ���_�R�[�h
  , iv_to_cust_code         IN VARCHAR2  -- �ڋq�R�[�h
  , iv_to_staff_code        IN VARCHAR2  -- �S���c�ƃR�[�h
  , iv_cust_gyotai_sho      IN VARCHAR2  -- �ڋq�Ƒԋ敪
  , iv_demand_to_cust_code  IN VARCHAR2  -- ������ڋq�R�[�h
  , iv_item_code            IN VARCHAR2  -- �i�ڃR�[�h
  , in_dlv_qty              IN NUMBER    -- ����
  , iv_dlv_uom_code         IN VARCHAR2  -- �P��
  , in_dlv_unit_price       IN NUMBER    -- �[�i�P��
  , in_sale_amount          IN NUMBER    -- ������z
  , in_pure_amount          IN NUMBER    -- ������z�i�Ŕ����j
  , in_business_cost        IN NUMBER    -- �c�ƌ���
  , iv_tax_code             IN VARCHAR2  -- ����ŃR�[�h
  , in_tax_rate             IN NUMBER    -- ����ŗ�
  , iv_from_base_code       IN VARCHAR2  -- ����U�֌����_�R�[�h
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'ins_sales_exp';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;
    lv_retcode              VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;
    -- �p�����[�^�ȊO�̕K�v�l�p
    ld_selling_date         DATE           DEFAULT NULL; -- ����v���
    lv_info_class           VARCHAR2(1)    DEFAULT NULL; -- ����m��t���O
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- �p�����[�^�ȊO�̕K�v�l���擾
    -- ===============================
    -- ����v���
    -- ����m��t���O
    IF ( iv_delivery_date = gv_current_month ) THEN
      ld_selling_date := gd_process_date;
      lv_info_class   := cv_report_news_flg;
    ELSIF ( gv_info_class   = cv_report_decision_flg AND
            iv_delivery_date = gv_past_month )
    THEN
      ld_selling_date := LAST_DAY(ADD_MONTHS(gd_process_date,-1));
      lv_info_class   := cv_report_decision_flg;
    ELSE
      ld_selling_date := LAST_DAY(ADD_MONTHS(gd_process_date,-1));
      lv_info_class   := cv_report_news_flg;
    END IF;
--
    -- ===============================
    -- 1.������ѐU�֏��e�[�u���ւ̃��R�[�h�ǉ�����
    -- ===============================
      INSERT INTO xxcok_selling_trns_info (
                    selling_trns_info_id  -- ������ѐU�֏��ID
                  , selling_trns_type     -- ���ѐU�֋敪
                  , slip_no               -- �`�[�ԍ�
                  , detail_no             -- ���הԍ�
                  , selling_date          -- ����v���
                  , selling_type          -- ����敪
                  , selling_return_type   -- ����ԕi�敪
                  , delivery_slip_type    -- �[�i�`�[�敪
                  , base_code             -- ���_�R�[�h
                  , cust_code             -- �ڋq�R�[�h
                  , selling_emp_code      -- �S���c�ƃR�[�h
                  , cust_state_type       -- �ڋq�Ƒԋ敪
                  , delivery_form_type    -- �[�i�`�ԋ敪
                  , article_code          -- �����R�[�h
                  , card_selling_type     -- �J�[�h����敪
                  , checking_date         -- ������
                  , demand_to_cust_code   -- ������ڋq�R�[�h
                  , h_c                   -- �g���b
                  , column_no             -- �R����No.
                  , item_code             -- �i�ڃR�[�h
                  , qty                   -- ����
                  , unit_type             -- �P��
                  , delivery_unit_price   -- �[�i�P��
                  , selling_amt           -- ������z
                  , selling_amt_no_tax    -- ������z�i�Ŕ����j
                  , trading_cost          -- �c�ƌ���
                  , selling_cost_amt      -- ���㌴�����z
                  , tax_code              -- ����ŃR�[�h
                  , tax_rate              -- ����ŗ�
                  , delivery_base_code    -- �[�i���_�R�[�h
                  , registration_date     -- �o�^�Ɩ����t
                  , correction_flag       -- �U�߃t���O
                  , report_decision_flag  -- ����m��t���O
                  , info_interface_flag   -- ���nI/F�t���O
                  , gl_interface_flag     -- �d��쐬�t���O
                  , org_slip_number       -- ���`�[�ԍ�
                  , created_by
                  , creation_date
                  , last_updated_by
                  , last_update_date
                  , last_update_login
                  , request_id
                  , program_application_id
                  , program_id
                  , program_update_date
                  ) VALUES (
                    xxcok_selling_trns_info_s01.NEXTVAL -- selling_trns_info_id
                  , cv_selling_trns_type                -- selling_trns_type
                  , NULL                                -- slip_no
                  , NULL                                -- detail_no
                  , ld_selling_date                     -- selling_date
                  , cv_selling_type                     -- selling_type
                  , cv_selling_return_type              -- selling_return_type
                  , cv_invoice_class_01                 -- delivery_slip_type
                  , iv_to_base_code                     -- base_code
                  , iv_to_cust_code                     -- cust_code
                  , iv_to_staff_code                    -- selling_emp_code
                  , iv_cust_gyotai_sho                  -- cust_state_type
                  , cv_dlv_from_type                    -- delivery_form_type
                  , cv_article_code                     -- article_code
                  , cv_card_selling_type                -- card_selling_type
                  , NULL                                -- checking_date
                  , iv_demand_to_cust_code              -- demand_to_cust_code
                  , cv_h_c                              -- h_c
                  , cv_column_no                        -- column_no
                  , iv_item_code                        -- item_code
                  , in_dlv_qty                          -- qty
                  , iv_dlv_uom_code                     -- unit_type
                  , in_dlv_unit_price                   -- delivery_unit_price
                  , in_sale_amount                      -- selling_amt
                  , in_pure_amount                      -- selling_amt_no_tax
                  , in_business_cost                    -- trading_cost
                  , NULL                                -- selling_cost_amt
                  , iv_tax_code                         -- tax_code
                  , in_tax_rate                         -- tax_rate
                  , iv_from_base_code                   -- delivery_base_code
                  , gd_process_date                     -- registration_date
                  , cv_correction_off_flg               -- correction_flag
                  , lv_info_class                       -- report_decision_flag
                  , cv_info_if_flag                     -- info_interface_flag
                  , cv_gl_if_flag                       -- gl_interface_flag
                  , NULL                                -- org_slip_number
                  , cn_created_by
                  , SYSDATE
                  , cn_last_updated_by
                  , SYSDATE
                  , cn_last_update_login
                  , cn_request_id
                  , cn_program_application_id
                  , cn_program_id
                  , SYSDATE
                  );
--
  EXCEPTION
    -- OTHERS��O�n���h���i�C���T�[�g�G���[�j
    WHEN OTHERS THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        cv_appli_short_name_xxcok
                      , cv_msg_xxcok1_10034
                      , cv_sales_date
                      , TO_CHAR( ld_selling_date , 'YYYY/MM/DD' )  -- ����v���
                      , cv_location_code
                      , iv_to_base_code                            -- ���_�R�[�h
                      , cv_customer_code
                      , iv_to_cust_code                            -- �ڋq�R�[�h
                      , cv_item_code
                      , iv_item_code                               -- �i�ڃR�[�h
                      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END ins_sales_exp;
--
  /**********************************************************************************
   * Procedure Name   : adj_data
   * Description      : �Z�o�f�[�^�̒���(A-9)
   ***********************************************************************************/
  PROCEDURE adj_data(
    ov_errbuf               OUT VARCHAR2
  , ov_retcode              OUT VARCHAR2
  , ov_errmsg               OUT VARCHAR2
  , in_dlv_qty_from          IN NUMBER   -- ����U�֌�����
  , in_sale_amount_from      IN NUMBER   -- ����U�֌�������z
  , in_pure_amount_from      IN NUMBER   -- ����U�֌�������z�i�Ŕ����j
  , in_business_cost_from    IN NUMBER   -- ����U�֌��c�ƌ���
  , in_dlv_qty_to            IN NUMBER   -- ����U�֐搔��
  , in_sale_amount_to        IN NUMBER   -- ����U�֐攄����z
  , in_pure_amount_to        IN NUMBER   -- ����U�֐攄����z�i�Ŕ����j
  , in_business_cost_to      IN NUMBER   -- ����U�֐�c�ƌ���
  , iv_from_base_code        IN VARCHAR2 -- ����U�֌����_�R�[�h
  , iv_from_cust_code        IN VARCHAR2 -- ����U�֌��ڋq�R�[�h
  , iv_to_base_code          IN VARCHAR2 -- ����U�֐拒�_�R�[�h
  , iv_to_cust_code          IN VARCHAR2 -- ����U�֐�ڋq�R�[�h
  , in_dlv_qty_detail        IN NUMBER   -- �ڍב�������_����
  , in_sale_amount_detail    IN NUMBER   -- �ڍב�������_������z
  , in_pure_amount_detail    IN NUMBER   -- �ڍב�������_������z�i�Ŕ����j
  , in_business_cost_detail  IN NUMBER   -- �ڍב�������_�c�ƌ���
  , ib_adj_flg               IN BOOLEAN  -- A-8_�����t���O
  , on_dlv_qty              OUT NUMBER   -- ������_����
  , on_sale_amount          OUT NUMBER   -- ������_������z
  , on_pure_amount          OUT NUMBER   -- ������_������z�i�Ŕ����j
  , on_business_cost        OUT NUMBER   -- ������_�c�ƌ���
  , on_dlv_unit_price       OUT NUMBER   -- �[�i�P��
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(8) := 'adj_data';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;
    lv_retcode              VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;
    -- �P���v�Z�p
    ln_unit_qty             NUMBER         DEFAULT NULL; -- �v�Z�p_����
    ln_unit_amt             NUMBER         DEFAULT NULL; -- �v�Z�p_������z
    -- �v�Z���ʊi�[�p�i�A�E�g�p�����[�^�j
    ln_dlv_qty              NUMBER         DEFAULT NULL; -- ������_����
    ln_sale_amount          NUMBER         DEFAULT NULL; -- ������_������z
    ln_pure_amount          NUMBER         DEFAULT NULL; -- ������_������z�i�Ŕ����j
    ln_business_cost        NUMBER         DEFAULT NULL; -- ������_�c�ƌ���
    ln_dlv_unit_price       NUMBER         DEFAULT NULL; -- �P��
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.�����l�̎Z�o�Ɖ��Z
    -- ===============================
    IF ( iv_from_base_code = iv_to_base_code AND
         iv_from_cust_code = iv_to_cust_code AND
         ib_adj_flg        = TRUE )
    THEN
      -- �p�^�[��1
      ln_dlv_qty       := ( in_dlv_qty_detail + ( in_dlv_qty_from - in_dlv_qty_to )
                          - in_dlv_qty_from );
      ln_sale_amount   := ( in_sale_amount_detail + ( in_sale_amount_from - in_sale_amount_to )
                          - in_sale_amount_from );
      ln_pure_amount   := ( in_pure_amount_detail + ( in_pure_amount_from - in_pure_amount_to )
                          - in_pure_amount_from );
      ln_business_cost := ( in_business_cost_detail + ( in_business_cost_from - in_business_cost_to )
                          - in_business_cost_from );
--
      -- �P���v�Z�p���l
      ln_unit_qty := ( in_dlv_qty_detail + ( in_dlv_qty_from - in_dlv_qty_to ));
      ln_unit_amt := ( in_sale_amount_detail + ( in_sale_amount_from - in_sale_amount_to ));
--
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
    -- �U�֌��̐��ʂ�1�Ŋ����ɂ��U�֌�̐��ʂ�0�ƂȂ郌�R�[�h�̋��z����
    ELSIF ( iv_from_base_code = iv_to_base_code AND
            iv_from_cust_code = iv_to_cust_code AND
            in_dlv_qty_detail = 0               AND
            ib_adj_flg        = FALSE )
    THEN
      --  �p�^�[��5
      ln_dlv_qty       := ( in_dlv_qty_from * -1 );
      ln_sale_amount   := ( in_sale_amount_from * -1 );
      ln_pure_amount   := ( in_pure_amount_from * -1 );
      ln_business_cost := ( in_business_cost_from * -1 );
--
      -- �P���v�Z�p���l
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    ELSIF ( iv_from_base_code = iv_to_base_code AND
            iv_from_cust_code = iv_to_cust_code AND
            ib_adj_flg        = FALSE )
    THEN
      --  �p�^�[��2
      ln_dlv_qty       := ( in_dlv_qty_detail - in_dlv_qty_from );
      ln_sale_amount   := ( in_sale_amount_detail - in_sale_amount_from );
      ln_pure_amount   := ( in_pure_amount_detail - in_pure_amount_from );
      ln_business_cost := ( in_business_cost_detail - in_business_cost_from );
--
      -- �P���v�Z�p���l
      ln_unit_qty := in_dlv_qty_detail;
      ln_unit_amt := in_sale_amount_detail;
--
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
    -- �U�֐�̐��ʂ�0�Ŋ����ɂ��U�֌�̐��ʂ�1�ƂȂ郌�R�[�h�̋��z����
    ELSIF ( iv_from_cust_code <> iv_to_cust_code   AND
            in_dlv_qty_detail  = 0                 AND
            ib_adj_flg         = TRUE )
    THEN
      --  �p�^�[��6
      ln_dlv_qty       := in_dlv_qty_from;
      ln_sale_amount   := in_sale_amount_from;
      ln_pure_amount   := in_pure_amount_from;
      ln_business_cost := in_business_cost_from;
--
      -- �P���v�Z�p���l
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    ELSIF ( iv_from_cust_code <> iv_to_cust_code AND
            ib_adj_flg         = TRUE )
    THEN
      --  �p�^�[��3
      ln_dlv_qty       := ( in_dlv_qty_detail + ( in_dlv_qty_from - in_dlv_qty_to ));
      ln_sale_amount   := ( in_sale_amount_detail + ( in_sale_amount_from - in_sale_amount_to ));
      ln_pure_amount   := ( in_pure_amount_detail + ( in_pure_amount_from - in_pure_amount_to ));
      ln_business_cost := ( in_business_cost_detail + ( in_business_cost_from - in_business_cost_to ));
--
      -- �P���v�Z�p���l
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
--
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
    -- �U�֌��̐��ʂ�1�Ŋ������΂��Ă��郌�R�[�h�̋��z����
    ELSIF ( iv_from_cust_code <> iv_to_cust_code   AND
            in_dlv_qty_from    = in_dlv_qty_detail AND
            ib_adj_flg         = FALSE )
    THEN
      --  �p�^�[��7
      ln_dlv_qty       := in_dlv_qty_from;
      ln_sale_amount   := in_sale_amount_from;
      ln_pure_amount   := in_pure_amount_from;
      ln_business_cost := in_business_cost_from;
--
      -- �P���v�Z�p���l
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    ELSIF ( iv_from_cust_code <> iv_to_cust_code AND
            ib_adj_flg         = FALSE )
    THEN
      --  �p�^�[��4
      ln_dlv_qty       := in_dlv_qty_detail;
      ln_sale_amount   := in_sale_amount_detail;
      ln_pure_amount   := in_pure_amount_detail;
      ln_business_cost := in_business_cost_detail;
--
      -- �P���v�Z�p���l
      ln_unit_qty := ln_dlv_qty;
      ln_unit_amt := ln_sale_amount;
    END IF;
--
    -- ===============================
    -- 2.�[�i�P���Z�o
    -- ===============================
    -- �Z�o�������ʂ�0�Ȃ�ΒP����NULL�Ƃ��A������ѐU�փ��R�[�h�ǉ����X�L�b�v���܂�
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--    IF ( ln_unit_qty <> 0 ) THEN
    IF ( ln_unit_qty <> 0 AND ln_dlv_qty <> 0 ) THEN
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
      ln_dlv_unit_price := ROUND( ln_unit_amt / ln_unit_qty , 1);
    END IF;
--
    -- ===============================
    -- 3.�l���p�����[�^�֊i�[
    -- ===============================
    on_dlv_qty        := ln_dlv_qty;        -- ������_����
    on_sale_amount    := ln_sale_amount;    -- ������_������z
    on_pure_amount    := ln_pure_amount;    -- ������_������z�i�Ŕ����j
    on_business_cost  := ln_business_cost;  -- ������_�c�ƌ���
    on_dlv_unit_price := ln_dlv_unit_price; -- �P��
--
  EXCEPTION
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END adj_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �Z�o�f�[�^�̐������`�F�b�N(A-8)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf             OUT VARCHAR2
  , ov_retcode            OUT VARCHAR2
  , ov_errmsg             OUT VARCHAR2
  , in_dlv_qty_from        IN NUMBER   -- ����U�֌�����
  , in_sale_amount_from    IN NUMBER   -- ����U�֌�������z
  , in_pure_amount_from    IN NUMBER   -- ����U�֌�������z�i�Ŕ����j
  , in_business_cost_from  IN NUMBER   -- ����U�֌��c�ƌ���
  , in_dlv_qty_to          IN NUMBER   -- ����U�֐搔��
  , in_sale_amount_to      IN NUMBER   -- ����U�֐攄����z
  , in_pure_amount_to      IN NUMBER   -- ����U�֐攄����z�i�Ŕ����j
  , in_business_cost_to    IN NUMBER   -- ����U�֐�c�ƌ���
  , ob_adj_flg            OUT BOOLEAN  -- �����t���O
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(8) := 'chk_data';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;
    lb_adj_flg   BOOLEAN       DEFAULT FALSE; -- �����t���O(Y�F�����v N�F�����s�v)
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.�Z�o�f�[�^�̐������`�F�b�N
    -- ===============================
    -- 1�ł��l���������Ȃ��ꍇ�A�����t���O�𗧂Ă�
    -- �[�i����
    IF ( in_dlv_qty_from <> in_dlv_qty_to )             THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- ������z
    IF ( in_sale_amount_from <> in_sale_amount_to )     THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- ������z�i�Ŕ����j
    IF ( in_pure_amount_from <> in_pure_amount_to )     THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- �c�ƌ���
    IF ( in_business_cost_from <> in_business_cost_to ) THEN
      lb_adj_flg := TRUE;
    END IF;
--
    -- ��r���ʂ��p�����[�^�Ɋi�[
    ob_adj_flg := lb_adj_flg;
--
  EXCEPTION
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_covered
   * Description      : ����S���ݒ�̊m�F(A-7)
   ***********************************************************************************/
  PROCEDURE chk_covered(
    ov_errbuf        OUT VARCHAR2
  , ov_retcode       OUT VARCHAR2
  , ov_errmsg        OUT VARCHAR2
  , iv_to_cust_code   IN VARCHAR2  -- �ڋq�R�[�h
  , iv_to_cust_name   IN VARCHAR2  -- �ڋq����
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
  , iv_delivery_date  IN VARCHAR2  -- ����v����i�[�i���j
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
  , ov_to_staff_code OUT VARCHAR2  -- �S���c�ƃR�[�h
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(11) := 'chk_covered';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;
    lv_out_msg       VARCHAR2(1000) DEFAULT NULL;  -- ���b�Z�[�W�o�͕ϐ�
    lb_msg_return    BOOLEAN        DEFAULT TRUE;  -- ���b�Z�[�W�֐��߂�l�p
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
    ld_coverd_period DATE           DEFAULT NULL;  -- �S���c�ƈ��擾�p���t�f�[�^
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
    -- �G���[���b�Z�[�W�p�ϐ�
    lv_to_base_code  VARCHAR2(10)   DEFAULT NULL;  -- ���㋒�_�R�[�h
    lv_to_staff_code VARCHAR2(10)   DEFAULT NULL;  -- �S���c�ƃR�[�h
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1.���㋒�_�R�[�h�擾
    -- ===============================
    BEGIN
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
--      SELECT xca.sale_base_code AS selling_to_base_code
      SELECT (
             CASE ( iv_delivery_date )
                 WHEN ( TO_CHAR( gd_process_date , 'YYYYMM' ) ) THEN
                     xca.sale_base_code
                 ELSE
                     xca.past_sale_base_code
             END
             ) AS selling_to_base_code
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
      INTO   lv_to_base_code
      FROM   hz_cust_accounts    hca
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id = xca.customer_id
      AND    hca.account_number  = iv_to_cust_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    -- ===============================
    -- 2.�S���c�ƈ��R�[�h�擾
    -- ===============================
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
    -- �S���c�ƈ��擾�p�̓��t�擾
    IF ( iv_delivery_date = TO_CHAR( gd_process_date ) ) THEN
        ld_coverd_period := gd_process_date;
    ELSE
        ld_coverd_period := LAST_DAY( TO_DATE( iv_delivery_date , 'YYYYMM' ) );
    END IF;
--
    -- �S���c�ƈ��擾���ʊ֐�
    lv_to_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
                          iv_to_cust_code
--                        , gd_process_date
                        , ld_coverd_period
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
                        );
--
    -- �l���p�����[�^�Ɋi�[
    ov_to_staff_code := lv_to_staff_code;
--
    -- ===============================
    -- 3.�ݒ���e�̊m�F
    -- ===============================
    IF ( lv_to_base_code IS NULL OR lv_to_staff_code IS NULL ) THEN
      -- �x������
      -- �x�����b�Z�[�W�o��
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_00045
                    , cv_customer_code
                    , iv_to_cust_code   -- �ڋq�R�[�h
                    , cv_customer_name
                    , iv_to_cust_name   -- �ڋq����
                    , cv_tanto_loc_code
                    , lv_to_base_code   -- ���㋒�_�R�[�h
                    , cv_tanto_code
                    , lv_to_staff_code  -- �S���c�ƃR�[�h
                    );
--
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_out_msg
                       , 0
                       );
--
      -- �Z�[�u�|�C���g�܂Ńf�[�^�����[���o�b�N
      ROLLBACK TO sales_exp_save;
--
      -- �X�e�[�^�X�Ɍx���t���O���Z�b�g
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- ���ʊ֐�OTHERS��O�n���h��
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END chk_covered;
--
  /**********************************************************************************
   * Procedure Name   : get_offset_exp
   * Description      : ������ѐU�֌����E�f�[�^���o(A-11)
   ***********************************************************************************/
  PROCEDURE get_offset_exp(
    ov_errbuf                 OUT VARCHAR2
  , ov_retcode                OUT VARCHAR2
  , ov_errmsg                 OUT VARCHAR2
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--  , iv_inspect_date            IN VARCHAR2  -- ����v����i�������j
  , iv_delivery_date           IN VARCHAR2  -- ����v����i�[�i���j
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
  , iv_selling_from_base_code  IN VARCHAR2  -- ����U�֌����_�R�[�h
  , iv_selling_from_cust_code  IN VARCHAR2  -- ����U�֌��ڋq�R�[�h
  , iv_bill_account_number     IN VARCHAR2  -- ������ڋq�R�[�h
  , iv_item_code               IN VARCHAR2  -- �i�ڃR�[�h
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(14) := 'get_offset_exp';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;
    ln_counter         NUMBER         DEFAULT 0;    -- ���������A�x�������p�J�E���^�[
    ln_dlv_unit_price  NUMBER         DEFAULT 0;    -- �[�i�P��
    lv_to_staff_code   VARCHAR2(10)   DEFAULT NULL; -- �S���c�ƃR�[�h
    lv_to_cust_code    VARCHAR2(10)   DEFAULT NULL; -- A-7�p����U�֐�ڋq�R�[�h
    lv_to_cust_name    VARCHAR2(30)   DEFAULT NULL; -- A-7�p����U�֐�ڋq����
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    ln_converted_qty   NUMBER         DEFAULT NULL; -- ����ʎ擾���ۃ`�F�b�N�p
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    -- ���E�Ώۃf�[�^
    CURSOR offset_exp_cur
    IS
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--      SELECT xseh.inspect_date                          AS inspect_date            -- ����v����i�������j
      SELECT TO_CHAR(xseh.delivery_date , 'YYYYMM' )     AS delivery_date            -- ����v����i�[�i���j
--           , xsel.sales_class                           AS sales_class             -- ����敪
--           , xseh.dlv_invoice_number                    AS dlv_invoice_number      -- �[�i�`�[�敪
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
           , xseh.sales_base_code                       AS selling_from_base_code  -- ����U�֌����_�R�[�h
           , xseh.ship_to_customer_code                 AS selling_from_cust_code  -- ����U�֌��ڋq�R�[�h
           , hp.party_name                              AS selling_from_cust_name  -- ����U�֌��ڋq����
           , xseh.cust_gyotai_sho                       AS cust_gyotai_sho         -- �ڋq�Ƒԋ敪
           , xsel.item_code                             AS item_code               -- �i�ڃR�[�h
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--           , ( xsel.dlv_qty * -1 )                      AS dlv_qty                 -- ����(���E)
--           , ( xsel.sale_amount * -1 )                  AS sale_amount             -- ������z(���E)
--           , ( xsel.pure_amount * -1 )                  AS pure_amount             -- ������z�i�Ŕ����j(���E)
           , SUM( xsel.dlv_qty * -1 )                   AS dlv_qty                 -- ����(���E)
           , SUM( xsel.sale_amount * -1 )               AS sale_amount             -- ������z(���E)
           , SUM( xsel.pure_amount * -1 )               AS pure_amount             -- ������z�i�Ŕ����j(���E)
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
           , xseh.tax_code                              AS tax_code                -- ����ŃR�[�h
           , xseh.tax_rate                              AS tax_rate                -- ����ŗ�
           , xsel.dlv_uom_code                          AS dlv_uom_code            -- �P��
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--           , ( xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(     -- ��P�ʊ��Z���ʊ֐�
--                                      xsel.item_code                               -- �i�ڃR�[�h
--                                    , xsel.dlv_uom_code                            -- �P��
--                                    , xsel.dlv_qty                                 -- ����
--                                    ) * -1 )            AS business_cost           -- �c�ƌ���(���E)
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1) AS unit_price                -- �P���i�f�o�b�O�p�j
           , SUM( xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(  -- ��P�ʊ��Z���ʊ֐�
                                         xsel.item_code                            -- �i�ڃR�[�h
                                       , xsel.dlv_uom_code                         -- �P��
                                       , xsel.dlv_qty                              -- ����
                                       ) * -1 )         AS business_cost           -- �c�ƌ���(���E)
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
      FROM   xxcos_sales_exp_lines   xsel
           , xxcos_sales_exp_headers xseh
           , hz_cust_accounts        hca  -- �ڋq�}�X�^
           , hz_parties              hp
           , xxcmm_cust_accounts     xca
      WHERE  xsel.sales_exp_header_id     = xseh.sales_exp_header_id
      AND    hca.party_id                 = hp.party_id
      AND    hca.cust_account_id          = xca.customer_id
      AND    xseh.ship_to_customer_code   = hca.account_number
      AND    xca.selling_transfer_div     = cv_transfer_div
      AND    xca.chain_store_code        IS NULL
      AND    hca.customer_class_code      = cv_cust_class_customer
      AND    hp.duns_number_c             = cv_duns_number_c
      AND    xseh.dlv_invoice_class      IN ( cv_invoice_class_01
                                            , cv_invoice_class_02
                                            , cv_invoice_class_03
                                            , cv_invoice_class_04
                                            )
      AND    xsel.business_cost          IS NOT NULL
-- Start 2009/04/02 Ver_1.2 T1_0196 M.Hiruta
--      AND    TO_CHAR(xseh.inspect_date , 'YYYYMM' ) IN ( gv_current_month , gv_past_month )
      AND    TO_CHAR(xseh.delivery_date , 'YYYYMM' ) = iv_delivery_date
-- End   2009/04/02 Ver_1.2 T1_0196 M.Hiruta
      AND    xseh.sales_base_code         = iv_selling_from_base_code
      AND    xseh.ship_to_customer_code   = iv_selling_from_cust_code
      AND    xsel.item_code               = iv_item_code
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
      GROUP BY
             TO_CHAR(xseh.delivery_date , 'YYYYMM' )
           , xseh.sales_base_code
           , xseh.ship_to_customer_code
           , hp.party_name
           , xseh.cust_gyotai_sho
           , xsel.item_code
           , xseh.tax_code
           , xseh.tax_rate
           , xsel.dlv_uom_code
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1);
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--
    -- �J�[�\���^���R�[�h
    l_offset_exp_rec offset_exp_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    warn_expt    EXCEPTION; -- A-7�x�������p��O
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    convert_expt EXCEPTION; -- ����ʎ擾�G���[
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.�̔����я��e�[�u�����o
    -- ===============================
    OPEN offset_exp_cur;
    LOOP
      FETCH offset_exp_cur INTO l_offset_exp_rec;
      EXIT WHEN offset_exp_cur%NOTFOUND;
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
        -- ===============================
        -- ����ʎ擾���۔���
        -- ===============================
        -- ��P�ʊ��Z���ʊ֐��R�[��
        ln_converted_qty := xxcok_common_pkg.get_uom_conversion_qty_f(
                              l_offset_exp_rec.item_code                -- �i�ڃR�[�h
                            , l_offset_exp_rec.dlv_uom_code             -- �P��
                            , l_offset_exp_rec.dlv_qty                  -- ����
                            );
--
        -- ��P�ʊ��Z���ʊ֐��̖߂�l��NULL�ł���ꍇ�G���[�����֑J��
        IF ( ln_converted_qty IS NULL ) THEN
          RAISE convert_expt;
        END IF;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
        -- �����Ώی����J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt +1;
--
        -- =============================================================
        -- A-7.����S���ݒ�̊m�F
        -- =============================================================
        -- ���[�v���A��x�������s����
        IF ( lv_to_cust_code IS NULL )
        THEN
          lv_to_cust_code := l_offset_exp_rec.selling_from_cust_code;
          lv_to_cust_name := l_offset_exp_rec.selling_from_cust_name;
          -- A-7
          chk_covered(
            ov_errbuf        => lv_errbuf
          , ov_retcode       => lv_retcode
          , ov_errmsg        => lv_errmsg
          , iv_to_cust_code  => lv_to_cust_code                -- �ڋq�R�[�h
          , iv_to_cust_name  => lv_to_cust_name                -- �ڋq����
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , iv_delivery_date => l_offset_exp_rec.delivery_date -- ����v����i�[�i���j
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , ov_to_staff_code => lv_to_staff_code               -- �S���c�ƃR�[�h
          );
        END IF;
--
        -- ���㋒�_�R�[�h���c�ƒS���������݂��Ȃ������ꍇ�i�x�������j
        IF ( lv_retcode = cv_status_warn )    THEN
          -- �X�L�b�v�����J�E���g�A�b�v
          gn_skip_cnt := gn_skip_cnt + ln_counter + 1;
          RAISE warn_expt;
        -- �G���[����
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-10.������ѐU�փ��R�[�h�ǉ�
        -- =============================================================
        -- �[�i�P�����Z�o����i����/������z�j
        ln_dlv_unit_price := ROUND(l_offset_exp_rec.sale_amount / l_offset_exp_rec.dlv_qty , 1);
--
        -- A-10
        ins_sales_exp(
          ov_errbuf               => lv_errbuf
        , ov_retcode              => lv_retcode
        , ov_errmsg               => lv_errmsg
-- Start 2009/04/02 Ver_1.2 T1_0089 M.Hiruta
--        , iv_inspect_date         => iv_inspect_date                         -- ����v���
        , iv_delivery_date        => l_offset_exp_rec.delivery_date          -- ����v���
-- End   2009/04/02 Ver_1.2 T1_0089 M.Hiruta
        , iv_to_base_code         => l_offset_exp_rec.selling_from_base_code -- ���_�R�[�h
        , iv_to_cust_code         => l_offset_exp_rec.selling_from_cust_code -- �ڋq�R�[�h
        , iv_to_staff_code        => lv_to_staff_code                        -- �S���c�ƃR�[�h
        , iv_cust_gyotai_sho      => l_offset_exp_rec.cust_gyotai_sho        -- �Ƒԏ�����
        , iv_demand_to_cust_code  => iv_bill_account_number                  -- ������ڋq�R�[�h
        , iv_item_code            => l_offset_exp_rec.item_code              -- �i�ڃR�[�h
        , in_dlv_qty              => l_offset_exp_rec.dlv_qty                -- ���ʁi���E�j
        , iv_dlv_uom_code         => l_offset_exp_rec.dlv_uom_code           -- �P��
        , in_dlv_unit_price       => ln_dlv_unit_price                       -- �[�i�P��
        , in_sale_amount          => l_offset_exp_rec.sale_amount            -- ������z�i���E�j
        , in_pure_amount          => l_offset_exp_rec.pure_amount            -- ������z�i�Ŕ����j�i���E�j
        , in_business_cost        => l_offset_exp_rec.business_cost          -- �c�ƌ����i���E�j
        , iv_tax_code             => l_offset_exp_rec.tax_code               -- ����ŃR�[�h
        , in_tax_rate             => l_offset_exp_rec.tax_rate               -- ����ŗ�
        , iv_from_base_code       => l_offset_exp_rec.selling_from_base_code -- ����U�֌����_�R�[�h
        );
--
        -- A-10�ŃG���[���N�����ꍇ�̏���
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �������������J�E���g�A�b�v
        ln_counter := ln_counter + 1;
--
    END LOOP;
--
    -- �������������i�[
    gn_normal_cnt := gn_normal_cnt + ln_counter;
--
  EXCEPTION
    -- A-7�x������
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
      -- �J�[�\���̃N���[�Y
      IF ( offset_exp_cur%ISOPEN ) THEN
        CLOSE offset_exp_cur;
      END IF;
--
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- ����ʎ擾�G���[
    WHEN convert_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10452
                    , cv_item_code
                    , l_offset_exp_rec.item_code
                    , cv_dlv_uom_code
                    , l_offset_exp_rec.dlv_uom_code
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--  -- ���ʊ֐�OTHERS��O�n���h��
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
    -- �@�\���v���V�[�W���G���[��O�n���h��
    WHEN global_process_expt THEN
      -- �����X�e�[�^�X���G���[�Ƃ���A-11���I������B
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( offset_exp_cur%ISOPEN ) THEN
        CLOSE offset_exp_cur;
      END IF;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( offset_exp_cur%ISOPEN ) THEN
        CLOSE offset_exp_cur;
      END IF;
  END get_offset_exp;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp
   * Description      : �̔����я��e�[�u�����o(A-6)
   ***********************************************************************************/
  PROCEDURE get_sales_exp(
    ov_errbuf                 OUT VARCHAR2
  , ov_retcode                OUT VARCHAR2
  , ov_errmsg                 OUT VARCHAR2
  , iv_delivery_date           IN VARCHAR2  -- ����v���
  , iv_selling_from_base_code  IN VARCHAR2  -- ����U�֌����_�R�[�h
  , iv_selling_from_cust_code  IN VARCHAR2  -- ����U�֌��ڋq�R�[�h
  , iv_bill_account_number     IN VARCHAR2  -- ������ڋq�R�[�h
  , iv_item_code               IN VARCHAR2  -- �i�ڃR�[�h
  , in_dlv_qty_from            IN NUMBER    -- ����U�֌�����
  , in_sale_amount_from        IN NUMBER    -- ����U�֌�������z
  , in_pure_amount_from        IN NUMBER    -- ����U�֌�������z�i�Ŕ����j
  , in_business_cost_from      IN NUMBER    -- ����U�֌��c�ƌ���
  , in_dlv_qty_to              IN NUMBER    -- ����U�֐搔��
  , in_sale_amount_to          IN NUMBER    -- ����U�֐攄����z
  , in_pure_amount_to          IN NUMBER    -- ����U�֐攄����z�i�Ŕ����j
  , in_business_cost_to        IN NUMBER    -- ����U�֐�c�ƌ���
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_sales_exp';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;
    ln_counter         NUMBER         DEFAULT 0;    -- ���������A�x�������p�J�E���^�[
    lv_to_staff_code   VARCHAR2(10)   DEFAULT NULL; -- �S���c�ƃR�[�h
    lv_to_cust_code    VARCHAR2(10)   DEFAULT NULL; -- A-7�p����U�֐�ڋq�R�[�h
    lv_to_cust_name    VARCHAR2(30)   DEFAULT NULL; -- A-7�p����U�֐�ڋq����
    lb_proc_start_flg  BOOLEAN        DEFAULT TRUE; -- A-8�p�������s����t���O(Y�F���s�v N�F���s�s�v)
    lb_data_adj_flg    BOOLEAN        DEFAULT TRUE; -- A-8�p�����t���O(Y�F�����v N�F�����s�v)
    ln_dlv_qty         NUMBER         DEFAULT 0;    -- A-9_�����㐔��
    ln_sale_amount     NUMBER         DEFAULT 0;    -- A-9_�����㔄����z
    ln_pure_amount     NUMBER         DEFAULT 0;    -- A-9_�����㔄����z�i�Ŕ��j
    ln_business_cost   NUMBER         DEFAULT 0;    -- A-9_������c�ƌ���
    ln_dlv_unit_price  NUMBER         DEFAULT 0;    -- A-9_�[�i�P��
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    ln_converted_qty   NUMBER         DEFAULT NULL; -- ����ʎ擾���ۃ`�F�b�N�p
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    -- �̔����я��
    CURSOR sales_exp_cur
    IS
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--      SELECT TO_CHAR(xseh.inspect_date , 'YYYYMM' )  AS inspect_date           -- ����v����i�������j
      SELECT TO_CHAR(xseh.delivery_date , 'YYYYMM' ) AS delivery_date          -- ����v����i�[�i���j
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , xseh.sales_base_code                    AS selling_from_base_code -- ����U�֌����_�R�[�h
           , xseh.ship_to_customer_code              AS selling_from_cust_code -- ����U�֌��ڋq�R�[�h
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
--           , xca.sale_base_code                      AS selling_to_base_code   -- ����U�֐拒�_�R�[�h
           , (
             CASE ( TO_CHAR( xseh.delivery_date , 'YYYYMM' ) )
                 WHEN ( TO_CHAR( gd_process_date , 'YYYYMM' ) ) THEN
                     xca.sale_base_code
                 ELSE
                     xca.past_sale_base_code
             END
             )                                       AS selling_to_base_code   -- ����U�֐拒�_�R�[�h
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
           , hca.account_number                      AS selling_to_cust_code   -- ����U�֐�ڋq�R�[�h
           , hp.party_name                           AS selling_to_cust_name   -- ����U�֐�ڋq����
           , xseh.cust_gyotai_sho                    AS cust_gyotai_sho        -- �ڋq�Ƒԋ敪
           , xsel.item_code                          AS item_code              -- �i�ڃR�[�h
           , xseh.tax_code                           AS tax_code               -- ����ŃR�[�h
           , xseh.tax_rate                           AS tax_rate               -- ����ŗ�
           , xsel.dlv_uom_code                       AS dlv_uom_code           -- �P��
           , ROUND(SUM(xsel.dlv_qty) * ( xsri.selling_trns_rate / 100 ))      AS dlv_qty     -- ����
           , ROUND(SUM(xsel.sale_amount) * ( xsri.selling_trns_rate / 100 ))  AS sale_amount -- ������z
           , ROUND(SUM(xsel.pure_amount) * ( xsri.selling_trns_rate / 100 ))  AS pure_amount -- ������z�i�Ŕ����j
           , ROUND((SUM(xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(      -- ��P�ʊ��Z���ʊ֐�
                                               xsel.item_code                                -- �i�ڃR�[�h
                                             , xsel.dlv_uom_code                             -- �P��
                                             , xsel.dlv_qty                                  -- ����
                                             )) * ( xsri.selling_trns_rate / 100 ))) AS business_cost -- �c�ƌ���
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1)                       AS unit_price  -- �P���i�f�o�b�O�p�j
           , ABS(ROUND(SUM(xsel.dlv_qty) * ( xsri.selling_trns_rate / 100 ))) AS abs_dlv_qty -- �[�i���ʁi��Βl�j
      FROM   xxcos_sales_exp_lines   xsel
           , xxcos_sales_exp_headers xseh
           , xxcok_selling_rate_info xsri
           , xxcok_selling_to_info   xsti
           , xxcok_selling_from_info xsfi
           , hz_cust_accounts        hca  -- �ڋq�}�X�^
           , hz_parties              hp
           , xxcmm_cust_accounts     xca
      WHERE  xsel.sales_exp_header_id     = xseh.sales_exp_header_id
      AND    hca.party_id                 = hp.party_id
      AND    hca.cust_account_id          = xca.customer_id
      AND    xsti.selling_to_cust_code    = hca.account_number
      AND    xsti.selling_from_info_id    = xsfi.selling_from_info_id
      AND    xsri.selling_from_base_code  = xsfi.selling_from_base_code
      AND    xsri.selling_from_cust_code  = xsfi.selling_from_cust_code
      AND    xsri.selling_to_cust_code    = xsti.selling_to_cust_code
      AND    xsri.selling_from_base_code  = xseh.sales_base_code
      AND    xsri.selling_from_cust_code  = xseh.ship_to_customer_code
      AND    xsti.start_month            <= gv_current_month
      AND    xca.selling_transfer_div     = cv_transfer_div
      AND    xca.chain_store_code        IS NULL
      AND    hca.customer_class_code      = cv_cust_class_customer
      AND    hp.duns_number_c             = cv_duns_number_c
      AND    xseh.dlv_invoice_class      IN ( cv_invoice_class_01
                                            , cv_invoice_class_02
                                            , cv_invoice_class_03
                                            , cv_invoice_class_04
                                            )
      AND    xsel.business_cost          IS NOT NULL
-- Start 2009/04/02 Ver_1.2 T1_0196 M.Hiruta
--      AND    TO_CHAR(xseh.inspect_date , 'YYYYMM' ) IN ( gv_current_month , gv_past_month )
      AND    TO_CHAR(xseh.delivery_date , 'YYYYMM' ) = iv_delivery_date
-- End   2009/04/02 Ver_1.2 T1_0196 M.Hiruta
      AND    xsri.invalid_flag            = cv_invalid_0_flg
      AND    xsti.invalid_flag            = cv_invalid_0_flg
      AND    xseh.sales_base_code         = iv_selling_from_base_code
      AND    xseh.ship_to_customer_code   = iv_selling_from_cust_code
      AND    xsel.item_code               = iv_item_code
      GROUP BY
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--             TO_CHAR(xseh.inspect_date , 'YYYYMM' )     -- ����v����i�������j
             TO_CHAR(xseh.delivery_date , 'YYYYMM' )    -- ����v����i�[�i���j
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , xseh.sales_base_code                       -- ����U�֌����_�R�[�h
           , xseh.ship_to_customer_code                 -- ����U�֌��ڋq�R�[�h
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
--           , xca.sale_base_code                         -- ����U�֐拒�_�R�[�h
           , (
             CASE ( TO_CHAR( xseh.delivery_date , 'YYYYMM' ) )
                 WHEN ( TO_CHAR( gd_process_date , 'YYYYMM' ) ) THEN
                     xca.sale_base_code
                 ELSE
                     xca.past_sale_base_code
             END
             )                                          -- ����U�֐拒�_�R�[�h
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
           , hca.account_number                         -- ����U�֐�ڋq�R�[�h
           , hp.party_name                              -- ����U�֐�ڋq����
           , xseh.cust_gyotai_sho                       -- �ڋq�Ƒԋ敪
           , xsel.item_code                             -- �i�ڃR�[�h
           , xseh.tax_code                              -- ����ŃR�[�h
           , xseh.tax_rate                              -- ����ŗ�
           , xsel.dlv_uom_code                          -- �P��
           , ROUND(xsel.sale_amount / xsel.dlv_qty , 1) -- �P��
           , xsri.selling_trns_rate                     -- ����U�֊���
      ORDER BY
             ABS(ROUND(SUM(xsel.dlv_qty) * ( xsri.selling_trns_rate / 100 ))) DESC
-- Start 2009/04/27 Ver_1.3 T1_0715 M.Hiruta
           , hca.account_number ASC;
-- End   2009/04/27 Ver_1.3 T1_0715 M.Hiruta
--
    -- �J�[�\���^���R�[�h
    l_sales_exp_rec sales_exp_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    warn_expt    EXCEPTION; -- A-7�x�������p��O
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    convert_expt EXCEPTION; -- ����ʎ擾�G���[
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.�̔����я��e�[�u�����o
    -- ===============================
    OPEN sales_exp_cur;
    LOOP
      FETCH sales_exp_cur INTO l_sales_exp_rec;
      EXIT WHEN sales_exp_cur%NOTFOUND;
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
        -- ===============================
        -- ����ʎ擾���۔���
        -- ===============================
        -- ��P�ʊ��Z���ʊ֐��R�[��
        ln_converted_qty := xxcok_common_pkg.get_uom_conversion_qty_f(
                              l_sales_exp_rec.item_code                -- �i�ڃR�[�h
                            , l_sales_exp_rec.dlv_uom_code             -- �P��
                            , l_sales_exp_rec.dlv_qty                  -- ����
                            );
--
        -- ��P�ʊ��Z���ʊ֐��̖߂�l��NULL�ł���ꍇ�G���[�����֑J��
        IF ( ln_converted_qty IS NULL ) THEN
          RAISE convert_expt;
        END IF;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
        -- �����Ώی����J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt +1;
--
        -- =============================================================
        -- A-7.����S���ݒ�̊m�F
        -- =============================================================
        -- ����U�֐�ڋq�R�[�h��ێ����A�����Ώۂł��邩���ʂ���
        -- ���ʉߎ��̔���U�֐�ڋq�R�[�h���O��ʉߎ��̔���U�֐�ڋq�R�[�h�Ɠ������ꍇ��
        --   A-7�̏������s��Ȃ��B
        IF ( lv_to_cust_code <> l_sales_exp_rec.selling_to_cust_code OR
             lv_to_cust_code IS NULL )
        THEN
          lv_to_cust_code := l_sales_exp_rec.selling_to_cust_code;
          lv_to_cust_name := l_sales_exp_rec.selling_to_cust_name;
          -- A-7
          chk_covered(
            ov_errbuf        => lv_errbuf
          , ov_retcode       => lv_retcode
          , ov_errmsg        => lv_errmsg
          , iv_to_cust_code  => lv_to_cust_code               -- �ڋq�R�[�h
          , iv_to_cust_name  => lv_to_cust_name               -- �ڋq����
-- Start 2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , iv_delivery_date => l_sales_exp_rec.delivery_date -- ����v����i�[�i���j
-- End   2009/04/02 Ver_1.2 T1_0103 M.Hiruta
          , ov_to_staff_code => lv_to_staff_code              -- �S���c�ƃR�[�h
          );
        END IF;
--
        -- ���㋒�_�R�[�h���c�ƒS���������݂��Ȃ������ꍇ�i�x�������j
        IF ( lv_retcode = cv_status_warn )    THEN
          -- �X�L�b�v�����J�E���g�A�b�v
          gn_skip_cnt := gn_skip_cnt + ln_counter + 1;
          RAISE warn_expt;
        -- �G���[����
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-8.�Z�o�f�[�^�̐������`�F�b�N
        -- =============================================================
        -- A-6���Ăяo����čŏ��̃��R�[�h�̂�A-8�̏��������s����B
        IF ( lb_proc_start_flg = TRUE ) THEN
          -- A-8
          chk_data(
            ov_errbuf             => lv_errbuf
          , ov_retcode            => lv_retcode
          , ov_errmsg             => lv_errmsg
          , in_dlv_qty_from       => in_dlv_qty_from        -- ����U�֌�����
          , in_sale_amount_from   => in_sale_amount_from    -- ����U�֌�������z
          , in_pure_amount_from   => in_pure_amount_from    -- ����U�֌�������z�i�Ŕ����j
          , in_business_cost_from => in_business_cost_from  -- ����U�֌��c�ƌ���
          , in_dlv_qty_to         => in_dlv_qty_to          -- ����U�֐搔��
          , in_sale_amount_to     => in_sale_amount_to      -- ����U�֐攄����z
          , in_pure_amount_to     => in_pure_amount_to      -- ����U�֐攄����z�i�Ŕ����j
          , in_business_cost_to   => in_business_cost_to    -- ����U�֐�c�ƌ���
          , ob_adj_flg            => lb_data_adj_flg        -- �����t���O(Y�F�����v N�F�����s�v)
          );
--
          -- A-8�ŃG���[���N�����ꍇ�̏���
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �ȍ~�̃��[�v�����ł�A-8�����s���Ȃ��悤�Ɏ��s�t���O��ύX����
          lb_proc_start_flg := FALSE;
        ELSIF ( lb_proc_start_flg = FALSE ) THEN
          -- A-8�����s���Ȃ������ꍇ�A�����t���O�Ɂu�����s�v�v��ݒ肷��
          lb_data_adj_flg := FALSE;
        END IF;
--
        -- =============================================================
        -- A-9.�Z�o�f�[�^�̒���
        -- =============================================================
        adj_data(
          ov_errbuf               => lv_errbuf
        , ov_retcode              => lv_retcode
        , ov_errmsg               => lv_errmsg
        , in_dlv_qty_from         => in_dlv_qty_from                        -- ����U�֌�����
        , in_sale_amount_from     => in_sale_amount_from                    -- ����U�֌�������z
        , in_pure_amount_from     => in_pure_amount_from                    -- ����U�֌�������z�i�Ŕ����j
        , in_business_cost_from   => in_business_cost_from                  -- ����U�֌��c�ƌ���
        , in_dlv_qty_to           => in_dlv_qty_to                          -- ����U�֐搔��
        , in_sale_amount_to       => in_sale_amount_to                      -- ����U�֐攄����z
        , in_pure_amount_to       => in_pure_amount_to                      -- ����U�֐攄����z�i�Ŕ����j
        , in_business_cost_to     => in_business_cost_to                    -- ����U�֐�c�ƌ���
        , iv_from_base_code       => l_sales_exp_rec.selling_from_base_code -- ����U�֌����_�R�[�h
        , iv_from_cust_code       => l_sales_exp_rec.selling_from_cust_code -- ����U�֌��ڋq�R�[�h
        , iv_to_base_code         => l_sales_exp_rec.selling_to_base_code   -- ����U�֐拒�_�R�[�h
        , iv_to_cust_code         => l_sales_exp_rec.selling_to_cust_code   -- ����U�֐�ڋq�R�[�h
        , in_dlv_qty_detail       => l_sales_exp_rec.dlv_qty                -- �ڍב�������_����
        , in_sale_amount_detail   => l_sales_exp_rec.sale_amount            -- �ڍב�������_������z
        , in_pure_amount_detail   => l_sales_exp_rec.pure_amount            -- �ڍב�������_������z�i�Ŕ����j
        , in_business_cost_detail => l_sales_exp_rec.business_cost          -- �ڍב�������_�c�ƌ���
        , ib_adj_flg              => lb_data_adj_flg                        -- A-8_�����t���O
        , on_dlv_qty              => ln_dlv_qty                             -- ������_����
        , on_sale_amount          => ln_sale_amount                         -- ������_������z
        , on_pure_amount          => ln_pure_amount                         -- ������_������z�i�Ŕ����j
        , on_business_cost        => ln_business_cost                       -- ������_�c�ƌ���
        , on_dlv_unit_price       => ln_dlv_unit_price                      -- �[�i�P��
        );
--
        -- A-9�ŃG���[���N�����ꍇ�̏���
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-10.������ѐU�փ��R�[�h�ǉ�
        -- =============================================================
        -- �Z�o�f�[�^�̒����Ŏ擾�����P���ɐ��l������ꍇ�A���R�[�h�̒ǉ����������s���܂��B
        -- ���l���Ȃ��ꍇ�A���R�[�h�̒ǉ������͂��܂���B
        IF ( ln_dlv_unit_price IS NOT NULL ) THEN
          ins_sales_exp(
            ov_errbuf               => lv_errbuf
          , ov_retcode              => lv_retcode
          , ov_errmsg               => lv_errmsg
          , iv_delivery_date        => iv_delivery_date                       -- ����v���
          , iv_to_base_code         => l_sales_exp_rec.selling_to_base_code   -- ���_�R�[�h
          , iv_to_cust_code         => l_sales_exp_rec.selling_to_cust_code   -- �ڋq�R�[�h
          , iv_to_staff_code        => lv_to_staff_code                       -- �S���c�ƃR�[�h
          , iv_cust_gyotai_sho      => l_sales_exp_rec.cust_gyotai_sho        -- �Ƒԏ�����
          , iv_demand_to_cust_code  => iv_bill_account_number                 -- ������ڋq�R�[�h
          , iv_item_code            => l_sales_exp_rec.item_code              -- �i�ڃR�[�h
          , in_dlv_qty              => ln_dlv_qty                             -- ����
          , iv_dlv_uom_code         => l_sales_exp_rec.dlv_uom_code           -- �P��
          , in_dlv_unit_price       => ln_dlv_unit_price                      -- �[�i�P��
          , in_sale_amount          => ln_sale_amount                         -- ������z
          , in_pure_amount          => ln_pure_amount                         -- ������z�i�Ŕ����j
          , in_business_cost        => ln_business_cost                       -- �c�ƌ���
          , iv_tax_code             => l_sales_exp_rec.tax_code               -- ����ŃR�[�h
          , in_tax_rate             => l_sales_exp_rec.tax_rate               -- ����ŗ�
          , iv_from_base_code       => l_sales_exp_rec.selling_from_base_code -- ����U�֌����_�R�[�h
          );
        END IF;
--
        -- A-10�ŃG���[���N�����ꍇ�̏���
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �������������J�E���g�A�b�v
        ln_counter := ln_counter + 1;
--
    END LOOP;
--
    -- �������������i�[
    gn_normal_cnt := gn_normal_cnt + ln_counter;
--
  EXCEPTION
    -- A-7�x������
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
      -- �J�[�\���̃N���[�Y
      IF ( sales_exp_cur%ISOPEN ) THEN
        CLOSE sales_exp_cur;
      END IF;
--
-- Start 2009/04/02 Ver_1.2 T1_0190 M.Hiruta
    -- ����ʎ擾�G���[
    WHEN convert_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10452
                    , cv_item_code
                    , l_sales_exp_rec.item_code
                    , cv_dlv_uom_code
                    , l_sales_exp_rec.dlv_uom_code
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--  -- ���ʊ֐�OTHERS��O�n���h��
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
-- End   2009/04/02 Ver_1.2 T1_0190 M.Hiruta
--
    -- �@�\���v���V�[�W���G���[��O�n���h��
    WHEN global_process_expt THEN
      -- �����X�e�[�^�X���G���[�Ƃ���A-6���I������B
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( sales_exp_cur%ISOPEN ) THEN
        CLOSE sales_exp_cur;
      END IF;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( sales_exp_cur%ISOPEN ) THEN
        CLOSE sales_exp_cur;
      END IF;
  END get_sales_exp;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_sum
   * Description      : �̔����я��e�[�u���W�v���o(A-5)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_sum(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_sales_exp_sum';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;
    lv_slip_no             VARCHAR2(9)    DEFAULT NULL;  -- �`�[�ԍ�
    lv_sequence_s02        VARCHAR2(8)    DEFAULT NULL;  -- �V�[�P���X�i�[�p
    lv_bill_account_number VARCHAR2(9)    DEFAULT NULL;  -- ������ڋq�R�[�h
    ln_offset_chk          NUMBER         DEFAULT NULL;  -- A-11���s�m�F�p
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    -- �̔����я��i�W�v�j
    CURSOR sales_exp_sum_cur
    IS
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--      SELECT in_A.inspect_date                 AS inspect_date            -- ����v����i�������j
      SELECT in_A.delivery_date                AS delivery_date           -- ����v����i�[�i���j
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , in_A.selling_from_base_code       AS selling_from_base_code  -- ����U�֌����_�R�[�h
           , in_A.selling_from_cust_code       AS selling_from_cust_code  -- ����U�֌��ڋq�R�[�h
           , in_A.item_code                    AS item_code               -- �i�ڃR�[�h
           , in_A.dlv_qty_from                 AS dlv_qty_from            -- ����U�֌�����
           , in_A.sale_amount_from             AS sale_amount_from        -- ����U�֌�������z
           , in_A.pure_amount_from             AS pure_amount_from        -- ����U�֌�������z�i�Ŕ����j
           , in_A.business_cost_from           AS business_cost_from      -- ����U�֌��c�ƌ���
           , SUM(ROUND(in_A.dlv_qty_to))       AS dlv_qty_to              -- ����U�֐搔��
           , SUM(ROUND(in_A.sale_amount_to))   AS sale_amount_to          -- ����U�֐攄����z
           , SUM(ROUND(in_A.pure_amount_to))   AS pure_amount_to          -- ����U�֐攄����z�i�Ŕ����j
           , SUM(ROUND(in_A.business_cost_to)) AS business_cost_to        -- ����U�֐�c�ƌ���
      FROM   (-- �C�����C���r���[A_START
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--             SELECT in_B.inspect_date                                       AS inspect_date
             SELECT in_B.delivery_date                                      AS delivery_date
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
                  , in_B.sales_base_code                                    AS selling_from_base_code
                  , in_B.ship_to_customer_code                              AS selling_from_cust_code
                  , in_B.item_code                                          AS item_code
                  , in_B.dlv_qty                                            AS dlv_qty_from
                  , in_B.sale_amount                                        AS sale_amount_from
                  , in_B.pure_amount                                        AS pure_amount_from
                  , in_B.business_cost                                      AS business_cost_from
                  , (in_B.dlv_qty * ( xsri.selling_trns_rate / 100 ))       AS dlv_qty_to
                  , (in_B.sale_amount * ( xsri.selling_trns_rate / 100 ))   AS sale_amount_to
                  , (in_B.pure_amount * ( xsri.selling_trns_rate / 100 ))   AS pure_amount_to
                  , (in_B.business_cost * ( xsri.selling_trns_rate / 100 )) AS business_cost_to
             FROM   xxcok_selling_rate_info xsri     -- ����U�֊������e�[�u��
                  , hz_cust_accounts        hca_from -- ����U�֌����p�ڋq�}�X�^
                  , hz_parties              hp_from
                  , xxcmm_cust_accounts     xca_from
                  , hz_cust_accounts        hca_to   -- ����U�֐���p�ڋq�}�X�^
                  , hz_parties              hp_to
                  , xxcmm_cust_accounts     xca_to
                  , xxcok_selling_from_info xsfi
                  , xxcok_selling_to_info   xsti
                  , (-- �C�����C���r���[B_START
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--                    SELECT TO_CHAR(xseh.inspect_date , 'YYYYMM')  AS inspect_date              -- ����v����̔N��
                    SELECT TO_CHAR(xseh.delivery_date , 'YYYYMM') AS delivery_date             -- ����v����̔N��
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
                         , xseh.sales_base_code                   AS sales_base_code           -- ���㋒�_�R�[�h
                         , xseh.ship_to_customer_code             AS ship_to_customer_code     -- �ڋq�y�[�i��z
                         , xsel.item_code                         AS item_code                 -- �i�ڃR�[�h
                         , SUM(xsel.dlv_qty)                      AS dlv_qty                   -- �[�i����
                         , SUM(xsel.sale_amount)                  AS sale_amount               -- ������z
                         , SUM(xsel.pure_amount)                  AS pure_amount               -- ������z�i�Ŕ����j
                         , SUM(xsel.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f( -- ��P�ʊ��Z���ʊ֐�
                                                      xsel.item_code                           -- �i�ڃR�[�h
                                                    , xsel.dlv_uom_code                        -- �P��
                                                    , xsel.dlv_qty                             -- ����
                                                    )) AS business_cost                        -- �c�ƌ���
                    FROM   xxcos_sales_exp_lines   xsel
                         , xxcos_sales_exp_headers xseh
                    WHERE  xsel.sales_exp_header_id  = xseh.sales_exp_header_id
                    AND    xsel.business_cost       IS NOT NULL
                    AND    xseh.dlv_invoice_class   IN ( cv_invoice_class_01
                                                       , cv_invoice_class_02
                                                       , cv_invoice_class_03
                                                       , cv_invoice_class_04
                                                       )
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--                    AND    TO_CHAR(xseh.inspect_date , 'YYYYMM') IN ( gv_current_month , gv_past_month )
                    AND    TO_CHAR(xseh.delivery_date , 'YYYYMM') IN ( gv_current_month , gv_past_month )
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
                    GROUP BY
-- Start 2009/04/02 Ver_1.2 T1_0196 M.Hiruta
--                           xseh.inspect_date
                           TO_CHAR(xseh.delivery_date , 'YYYYMM')
-- End   2009/04/02 Ver_1.2 T1_0196 M.Hiruta
                         , xseh.sales_base_code
                         , xseh.ship_to_customer_code
                         , xsel.item_code
                    ) in_B
                    -- �C�����C���r���[B_END
             WHERE  hca_from.party_id             = hp_from.party_id
             AND    hca_from.cust_account_id      = xca_from.customer_id
             AND    hca_to.party_id               = hp_to.party_id
             AND    hca_to.cust_account_id        = xca_to.customer_id
             AND    xsti.selling_to_cust_code     = hca_to.account_number
             AND    xsfi.selling_from_cust_code   = hca_from.account_number
             AND    xsti.selling_from_info_id     = xsfi.selling_from_info_id
             AND    xsri.selling_from_base_code   = xsfi.selling_from_base_code
             AND    xsri.selling_from_cust_code   = xsfi.selling_from_cust_code
             AND    xsri.selling_to_cust_code     = xsti.selling_to_cust_code
             AND    xsri.selling_from_base_code   = in_B.sales_base_code
             AND    xsri.selling_from_cust_code   = in_B.ship_to_customer_code
             AND    xsri.invalid_flag             = cv_invalid_0_flg
             AND    xca_to.selling_transfer_div   = cv_transfer_div
             AND    xca_to.chain_store_code      IS NULL
             AND    hca_to.customer_class_code    = cv_cust_class_customer
             AND    hp_to.duns_number_c           = cv_duns_number_c
             AND    xca_from.selling_transfer_div = cv_transfer_div
             AND    xca_from.chain_store_code    IS NULL
             AND    hca_from.customer_class_code  = cv_cust_class_customer
             AND    hp_from.duns_number_c         = cv_duns_number_c
             AND    xsti.invalid_flag             = cv_invalid_0_flg
             AND    xsti.start_month             <= gv_current_month
             ) in_A
             -- �C�����C���r���[A_END
      GROUP BY
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--             in_A.inspect_date
             in_A.delivery_date
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
           , in_A.selling_from_base_code
           , in_A.selling_from_cust_code
           , in_A.item_code
           , in_A.dlv_qty_from
           , in_A.sale_amount_from
           , in_A.pure_amount_from
           , in_A.business_cost_from;
--
    -- �J�[�\���^���R�[�h
    l_sales_exp_sum_rec sales_exp_sum_cur%ROWTYPE;
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.�̔����я��e�[�u���W�v���o
    -- ===============================
    OPEN sales_exp_sum_cur;
    LOOP
      FETCH sales_exp_sum_cur INTO l_sales_exp_sum_rec;
      EXIT WHEN sales_exp_sum_cur%NOTFOUND;
        -- �Z�[�u�|�C���g�ݒ�
        SAVEPOINT sales_exp_save;
--
        -- ������ڋq�R�[�h�擾
        lv_bill_account_number := xxcok_common_pkg.get_bill_to_cust_code_f(
                                    l_sales_exp_sum_rec.selling_from_cust_code
                                  );
--
        -- =============================================================
        -- A-6 �̔����я��e�[�u�����o
        -- =============================================================
        get_sales_exp(
          ov_errbuf                 => lv_errbuf
        , ov_retcode                => lv_retcode
        , ov_errmsg                 => lv_errmsg
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--        , iv_inspect_date           => l_sales_exp_sum_rec.inspect_date           -- ����v���
        , iv_delivery_date          => l_sales_exp_sum_rec.delivery_date          -- ����v���
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
        , iv_selling_from_base_code => l_sales_exp_sum_rec.selling_from_base_code -- ����U�֌����_�R�[�h
        , iv_selling_from_cust_code => l_sales_exp_sum_rec.selling_from_cust_code -- ����U�֌��ڋq�R�[�h
        , iv_bill_account_number    => lv_bill_account_number                     -- ������ڋq�R�[�h
        , iv_item_code              => l_sales_exp_sum_rec.item_code              -- �i�ڃR�[�h
        , in_dlv_qty_from           => l_sales_exp_sum_rec.dlv_qty_from           -- ����U�֌�����
        , in_sale_amount_from       => l_sales_exp_sum_rec.sale_amount_from       -- ����U�֌�������z
        , in_pure_amount_from       => l_sales_exp_sum_rec.pure_amount_from       -- ����U�֌�������z�i�Ŕ����j
        , in_business_cost_from     => l_sales_exp_sum_rec.business_cost_from     -- ����U�֌��c�ƌ���
        , in_dlv_qty_to             => l_sales_exp_sum_rec.dlv_qty_to             -- ����U�֐搔��
        , in_sale_amount_to         => l_sales_exp_sum_rec.sale_amount_to         -- ����U�֐攄����z
        , in_pure_amount_to         => l_sales_exp_sum_rec.pure_amount_to         -- ����U�֐攄����z�i�Ŕ����j
        , in_business_cost_to       => l_sales_exp_sum_rec.business_cost_to       -- ����U�֐�c�ƌ���
        );
--
        -- A-6�̏����X�e�[�^�X���x���̏ꍇ�AA-5�̏����X�e�[�^�X�Ɍx�����Z�b�g����B
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
--
        -- A-6�̏����X�e�[�^�X���G���[�̏ꍇ�A��O�����֑J�ڂ���B
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================================
        -- A-11 ������ѐU�֌����E�f�[�^���o
        -- =============================================================
        -- ���E�Ώۂł��邩�m�F���邽�߁A�U�֌��ƐU�֐悪�����ڋq�̐U�֊��������݂��邩�ǂ�����
        -- �`�F�b�N���܂��B
        BEGIN
          ln_offset_chk := NULL;
--
          SELECT ROWNUM
          INTO   ln_offset_chk
          FROM   xxcok_selling_rate_info xsri
          WHERE  xsri.selling_from_base_code  = l_sales_exp_sum_rec.selling_from_base_code -- ����U�֌����_�R�[�h
          AND    xsri.selling_from_cust_code  = l_sales_exp_sum_rec.selling_from_cust_code -- ����U�֌��ڋq�R�[�h
          AND    xsri.selling_to_cust_code    = l_sales_exp_sum_rec.selling_from_cust_code -- ����U�֌��ڋq�R�[�h
          AND    xsri.invalid_flag            = cv_invalid_0_flg
          AND    ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
--
        -- �`�F�b�N�������ʁA�U�֊��������݂��Ȃ��ꍇ�A������ѐU�֌����E�f�[�^���o�����s����B
        IF ( ln_offset_chk IS NULL ) THEN
          --A-11
          get_offset_exp(
            ov_errbuf                 => lv_errbuf
          , ov_retcode                => lv_retcode
          , ov_errmsg                 => lv_errmsg
-- Start 2009/04/02 Ver_1.2 T1_0115 M.Hiruta
--          , iv_inspect_date           => l_sales_exp_sum_rec.inspect_date           -- ����v���
          , iv_delivery_date          => l_sales_exp_sum_rec.delivery_date          -- ����v���
-- End   2009/04/02 Ver_1.2 T1_0115 M.Hiruta
          , iv_selling_from_base_code => l_sales_exp_sum_rec.selling_from_base_code -- ����U�֌����_�R�[�h
          , iv_selling_from_cust_code => l_sales_exp_sum_rec.selling_from_cust_code -- ����U�֌��ڋq�R�[�h
          , iv_bill_account_number    => lv_bill_account_number                     -- ������ڋq�R�[�h
          , iv_item_code              => l_sales_exp_sum_rec.item_code              -- �i�ڃR�[�h
          );
--
          -- A-11�̏����X�e�[�^�X���x���̏ꍇ�AA-5�̏����X�e�[�^�X�Ɍx�����Z�b�g����B
          IF ( lv_retcode = cv_status_warn ) THEN
            ov_retcode := cv_status_warn;
--
          -- A-11�̏����X�e�[�^�X���G���[�̏ꍇ�A��O�����֑J�ڂ���B
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- =============================================================
        -- A-12 �`�[�ԍ����הԍ��X�V�Ώے��o
        -- =============================================================
        get_slip_detail_target(
          ov_errbuf  => lv_errbuf
        , ov_retcode => lv_retcode
        , ov_errmsg  => lv_errmsg
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
    END LOOP;
--
  EXCEPTION
    -- �Ăяo�������W���[���ŃG���[���N�������ꍇ
    WHEN global_process_expt THEN
      -- �����X�e�[�^�X���G���[�Ƃ���A-5���I������B
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( sales_exp_sum_cur%ISOPEN ) THEN
        CLOSE sales_exp_sum_cur;
      END IF;
--
    -- ���ʊ֐�OTHERS��O�n���h��
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( sales_exp_sum_cur%ISOPEN ) THEN
        CLOSE sales_exp_sum_cur;
      END IF;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���̃N���[�Y
      IF ( sales_exp_sum_cur%ISOPEN ) THEN
        CLOSE sales_exp_sum_cur;
      END IF;
  END get_sales_exp_sum;
--
  /**********************************************************************************
   * Procedure Name   : upd_correction_flg
   * Description      : �U�߃t���O�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_correction_flg(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(18) := 'upd_correction_flg';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    -- ���b�N�擾�p
    CURSOR update_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_selling_trns_info xsti
      WHERE  xsti.correction_flag                   = cv_correction_off_flg -- �U�߃I�t
      AND    xsti.report_decision_flag              = cv_report_news_flg    -- ����
      AND    TO_CHAR(xsti.selling_date , 'YYYYMM') IN ( gv_current_month , gv_past_month )
      FOR UPDATE NOWAIT;
    -- ===============================
    -- ���[�J����O
    -- ===============================
    update_error_expt EXCEPTION; -- ������ѐU�֏��e�[�u���A�b�v�f�[�g�G���[
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.������ѐU�֏��e�[�u���X�V�Ώۃf�[�^�̃��b�N�擾�i���b�N�̎擾�Ɏ��s�����ꍇ�͗�O�����֑J�ځj
    -- ===============================
    OPEN  update_lock_cur;
    CLOSE update_lock_cur;
--
    -- ===============================
    -- 2.������ѐU�֏��e�[�u���X�V�i�X�V�Ɏ��s�����ꍇ�͗�O�����֑J�ځj
    -- ===============================
    BEGIN
      UPDATE xxcok_selling_trns_info xsti
      SET
          xsti.correction_flag        = cv_correction_on_flg -- �U�߃t���O:�I��
        , xsti.last_updated_by        = cn_last_updated_by
        , xsti.last_update_date       = SYSDATE
        , xsti.last_update_login      = cn_last_update_login
        , xsti.request_id             = cn_request_id
        , xsti.program_application_id = cn_program_application_id
        , xsti.program_id             = cn_program_id
        , xsti.program_update_date    = SYSDATE
      WHERE xsti.correction_flag      = cv_correction_off_flg
      AND   xsti.report_decision_flag = cv_report_news_flg
      AND   TO_CHAR(xsti.selling_date , 'YYYYMM') IN ( gv_current_month , gv_past_month );
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := cv_status_error;
    END;
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE update_error_expt;
    END IF;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10012
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- �f�[�^�X�V�G���[
    WHEN update_error_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_10035
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END upd_correction_flg;
--
  /**********************************************************************************
   * Procedure Name   : ins_correction
   * Description      : ������ѐU�֏��U�߃f�[�^�쐬(A-3)
   ***********************************************************************************/
  PROCEDURE ins_correction(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(14) := 'ins_correction';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.������ѐU�ֈȏ��e�[�u���֐U�߃f�[�^���쐬�i�f�[�^�쐬�G���[���͗�O�����֑J�ځj
    -- ===============================
    INSERT INTO xxcok_selling_trns_info (
                  selling_trns_info_id  -- ������ѐU�֏��ID
                , selling_trns_type     -- ���ѐU�֋敪
                , slip_no               -- �`�[�ԍ�
                , detail_no             -- ���הԍ�
                , selling_date          -- ����v���
                , selling_type          -- ����敪
                , selling_return_type   -- ����ԕi�敪
                , delivery_slip_type    -- �[�i�`�[�敪
                , base_code             -- ���_�R�[�h
                , cust_code             -- �ڋq�R�[�h
                , selling_emp_code      -- �S���c�ƃR�[�h
                , cust_state_type       -- �ڋq�Ƒԋ敪
                , delivery_form_type    -- �[�i�`�ԋ敪
                , article_code          -- �����R�[�h
                , card_selling_type     -- �J�[�h����敪
                , checking_date         -- ������
                , demand_to_cust_code   -- ������ڋq�R�[�h
                , h_c                   -- �g���b
                , column_no             -- �R����No.
                , item_code             -- �i�ڃR�[�h
                , qty                   -- ����
                , unit_type             -- �P��
                , delivery_unit_price   -- �[�i�P��
                , selling_amt           -- ������z
                , selling_amt_no_tax    -- ������z�i�Ŕ����j
                , trading_cost          -- �c�ƌ���
                , selling_cost_amt      -- ���㌴�����z
                , tax_code              -- ����ŃR�[�h
                , tax_rate              -- ����ŗ�
                , delivery_base_code    -- �[�i���_�R�[�h
                , registration_date     -- �o�^�Ɩ����t
                , correction_flag       -- �U�߃t���O
                , report_decision_flag  -- ����m��t���O
                , info_interface_flag   -- ���nI/F�t���O
                , gl_interface_flag     -- �d��쐬�t���O
                , org_slip_number       -- ���`�[�ԍ�
                , created_by
                , creation_date
                , last_updated_by
                , last_update_date
                , last_update_login
                , request_id
                , program_application_id
                , program_id
                , program_update_date
                )
                SELECT
                  xxcok_selling_trns_info_s01.NEXTVAL -- selling_trns_info_id
                , xsti.selling_trns_type              -- selling_trns_type
                , xsti.slip_no                        -- slip_no
                , xsti.detail_no                      -- detail_no
-- Start 2009/06/04 Ver_1.4 T1_1325 M.Hiruta
--                , xsti.selling_date                   -- selling_date
                , (
                  CASE
                    WHEN xsti.selling_date BETWEEN TO_DATE( gv_past_month , 'YYYYMM' )
                                               AND LAST_DAY( TO_DATE( gv_past_month , 'YYYYMM' ) )THEN
                      LAST_DAY(ADD_MONTHS(gd_process_date,-1))
                    WHEN  xsti.selling_date BETWEEN TO_DATE( gv_current_month , 'YYYYMM' )
                                               AND LAST_DAY( TO_DATE( gv_current_month , 'YYYYMM' ) )THEN
                      gd_process_date
                  END
                  )
-- End   2009/06/04 Ver_1.4 T1_1325 M.Hiruta
                , xsti.selling_type                   -- selling_type
                , selling_return_type                 -- selling_return_type
                , xsti.delivery_slip_type             -- delivery_slip_type
                , xsti.base_code                      -- base_code
                , xsti.cust_code                      -- cust_code
                , xsti.selling_emp_code               -- selling_emp_code
                , xsti.cust_state_type                -- cust_state_type
                , xsti.delivery_form_type             -- delivery_form_type
                , xsti.article_code                   -- article_code
                , xsti.card_selling_type              -- card_selling_type
                , xsti.checking_date                  -- checking_date
                , xsti.demand_to_cust_code            -- demand_to_cust_code
                , xsti.h_c                            -- h_c
                , xsti.column_no                      -- column_no
                , xsti.item_code                      -- item_code
                , xsti.qty                            -- qty
                , xsti.unit_type                      -- unit_type
                , xsti.delivery_unit_price            -- delivery_unit_price
                , ( xsti.selling_amt * -1 )           -- selling_amt
                , ( xsti.selling_amt_no_tax * -1 )    -- selling_amt_no_tax
                , ( xsti.trading_cost * -1 )          -- trading_cost
                , xsti.selling_cost_amt               -- selling_cost_amt
                , xsti.tax_code                       -- tax_code
                , xsti.tax_rate                       -- tax_rate
                , xsti.delivery_base_code             -- delivery_base_code
-- Start 2009/07/03 Ver_1.5 0000422 M.Hiruta REPAIR
--                , xsti.registration_date              -- registration_date
                , gd_process_date                     -- registration_date
-- End   2009/07/03 Ver_1.5 0000422 M.Hiruta REPAIR
                , cv_correction_on_flg                -- correction_flag
                , xsti.report_decision_flag           -- report_decision_flag
                , cv_info_if_flag                     -- info_interface_flag
                , cv_gl_if_flag                       -- gl_interface_flag
                , xsti.org_slip_number                -- org_slip_number
                , cn_created_by
                , SYSDATE
                , cn_last_updated_by
                , SYSDATE
                , cn_last_update_login
                , cn_request_id
                , cn_program_application_id
                , cn_program_id
                , SYSDATE
                FROM  xxcok_selling_trns_info xsti
                WHERE xsti.correction_flag        = cv_correction_off_flg
                AND   xsti.report_decision_flag   = cv_report_news_flg
                AND   TO_CHAR(xsti.selling_date , 'YYYYMM') IN ( gv_current_month , gv_past_month );
--
  EXCEPTION
    -- OTHERS��O�n���h���i�C���T�[�g�G���[�j
    WHEN OTHERS THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        cv_appli_short_name_xxcok
                      , cv_msg_xxcok1_10033
                      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END ins_correction;
--
  /**********************************************************************************
   * Procedure Name   : get_period
   * Description      : �����Ώۉ�v���Ԏ擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_period(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_period';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;
    lb_check_period_flg BOOLEAN        DEFAULT TRUE;  -- ��v���ԃI�[�v��/���I�[�v���`�F�b�N�t���O
    lv_proc_date        VARCHAR2(10)   DEFAULT NULL;  -- �Ɩ����t�̔N��
    ld_past_month       DATE           DEFAULT NULL;  -- �挎�̓��t
    -- ===============================
    -- ���[�J����O
    -- ===============================
    chk_period_open_expt  EXCEPTION; -- ��v���Ԗ��I�[�v���G���[
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.������v���Ԃ̏�ԃ`�F�b�N�i��v���Ԃ����I�[�v���ł���ꍇ�͗�O�����֑J�ځj
    -- ===============================
    lb_check_period_flg := xxcok_common_pkg.check_acctg_period_f(
                             in_set_of_books_id        => gn_set_of_books_id
                           , id_proc_date              => gd_process_date
                           , iv_application_short_name => cv_appli_short_name_ar
                           );
--
    IF ( lb_check_period_flg = TRUE ) THEN
      -- ������v���Ԃ��I�[�v����Ԃł���ꍇ�͓������t���O���[�o���ϐ��֊i�[
      gv_current_month := TO_CHAR(gd_process_date , 'YYYYMM');
    ELSE
      -- �G���[���b�Z�[�W�̃g�[�N���p�ɃV�X�e�����t�̔N�����擾����
      lv_proc_date := TO_CHAR(gd_process_date,'YYYY/MM');
      RAISE chk_period_open_expt;
    END IF;
--
    -- ===============================
    -- 2.�挎��v���Ԃ̏�ԃ`�F�b�N
    -- ===============================
    -- �o�b�`���s���̐挎�̓��t���擾
    -- ADD_MONTHS �p�����[�^1�̌��Ƀp�����[�^2�̌��𑫂��܂�
    -- TRUNC      �p�����[�^1�̒l�i���t�^�j���p�����[�^2�Ŏw�肵���P�ʈȉ���؎̂Ă܂�
    -- �ȉ��Ŏ擾�ł���̂́A���ɂ���1���̐挎��v���Ԃł�
    ld_past_month := TRUNC(ADD_MONTHS(gd_process_date,-1),'MONTH');
    lb_check_period_flg := xxcok_common_pkg.check_acctg_period_f(
                             in_set_of_books_id        => gn_set_of_books_id
                           , id_proc_date              => ld_past_month
                           , iv_application_short_name => cv_appli_short_name_ar
                           );
--
    -- �挎��v���Ԃ��I�[�v����Ԃł���ꍇ�͐挎���t���O���[�o���ϐ��֊i�[
    IF ( lb_check_period_flg = TRUE ) THEN
      gv_past_month := TO_CHAR(ld_past_month , 'YYYYMM');
    END IF;
--
  EXCEPTION
    -- ��v���Ԗ��I�[�v���G���[
    WHEN chk_period_open_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_00042
                    , cv_proc_date
                    , lv_proc_date
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- ���ʊ֐�OTHERS��O�n���h��
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END get_period;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(4) := 'init';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;
    lv_out_msg    VARCHAR2(1000) DEFAULT NULL;  -- ���b�Z�[�W�o�͕ϐ�
    lb_msg_return BOOLEAN        DEFAULT TRUE;  -- ���b�Z�[�W�֐��߂�l�p
    -- ��v������擾�̍ۂɎ���s�v�Ȉ����̎���p
    lv_sobn_dummy VARCHAR2(50); -- ��v���떼
    ln_cai_dummy  NUMBER;       -- ����̌nID
    lv_psn_dummy  VARCHAR2(50); -- �J�����_��
    ln_asc_dummy  NUMBER;       -- AFF�Z�O�����g��`��
    lv_cc_dummy   VARCHAR2(10); -- �@�\�ʉ݃R�[�h
    -- ===============================
    -- ���[�J����O
    -- ===============================
    chk_parameter_expt    EXCEPTION; -- �p�����[�^�`�F�b�N�G���[
    get_process_date_expt EXCEPTION; -- �Ɩ����t�擾�G���[
--
  BEGIN
    -- �����X�e�[�^�X�̏�����
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 1.�R���J�����g���̓p�����[�^�̃��b�Z�[�W�o��
    -- ===============================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxcok
                  , cv_msg_xxcok1_00023
                  , cv_info_class
                  , gv_info_class
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 1
                     );
--
    -- ===============================
    -- 2.����ʂ̒l���m�F�i�z�肵���l�Ŗ����ꍇ�͗�O�����֑J�ځj
    -- ===============================
    IF ( gv_info_class NOT IN ( cv_report_news_flg , cv_report_decision_flg ) ) THEN
      RAISE chk_parameter_expt;
    END IF;
--
    -- ===============================
    -- 3.��v����ID�擾
    -- ===============================
    xxcok_common_pkg.get_set_of_books_info_p(
      ov_errbuf            => lv_errbuf
    , ov_retcode           => lv_retcode
    , ov_errmsg            => lv_errmsg
    , on_set_of_books_id   => gn_set_of_books_id -- ��v����ID
    , ov_set_of_books_name => lv_sobn_dummy      -- �s�v
    , on_chart_acct_id     => ln_cai_dummy       -- �s�v
    , ov_period_set_name   => lv_psn_dummy       -- �s�v
    , on_aff_segment_cnt   => ln_asc_dummy       -- �s�v
    , ov_currency_code     => lv_cc_dummy        -- �s�v
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- ��v����ID�擾�G���[���b�Z�[�W�o��
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_short_name_xxcok
                    , cv_msg_xxcok1_00008
                    );
--
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_out_msg
                       , 0
                       );
--
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 4.�Ɩ����t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
--
  EXCEPTION
    -- �p�����[�^�`�F�b�N�G���[
    WHEN chk_parameter_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_appli_short_name_xxcok
                   , cv_msg_xxcok1_10036
                   , cv_info_class
                   , gv_info_class  -- �����
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- ���ʊ֐���O�n���h��(��v����ID�擾�G���[)
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- �Ɩ����t�擾�G���[
    WHEN get_process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_appli_short_name_xxcok
                   , cv_msg_xxcok1_00028
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- ���ʊ֐�OTHERS��O�n���h��
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2
  , ov_retcode OUT VARCHAR2
  , ov_errmsg  OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(7) := 'submain';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- �p�����[�^������
    ov_retcode := cv_status_normal;
--
    -- =============================================================
    -- A-1 �������� (���^�[���R�[�h���G���[�̏ꍇ�̓o�b�`�������G���[�I�����܂�)
    -- =============================================================
    init(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-2 �����Ώۉ�v���Ԏ擾 (���^�[���R�[�h���G���[�̏ꍇ�̓o�b�`�������G���[�I�����܂�)
    -- =============================================================
    get_period(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-3 ������ѐU�֏��U�߃f�[�^�쐬 (���^�[���R�[�h���G���[�̏ꍇ�̓o�b�`�������G���[�I�����܂�)
    -- =============================================================
    ins_correction(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-4 �U�߃t���O�X�V (���^�[���R�[�h���G���[�̏ꍇ�̓o�b�`�������G���[�I�����܂�)
    -- =============================================================
    upd_correction_flg(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================================
    -- A-5 �̔����я��e�[�u���W�v���o (���^�[���R�[�h���G���[�̏ꍇ�̓o�b�`�������G���[�I�����܂�)
    -- =============================================================
    get_sales_exp_sum(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error )   THEN
      RAISE global_process_expt;
--
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
    -- ���������ʗ�O�n���h��
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2
  , retcode       OUT VARCHAR2
  , iv_info_class  IN VARCHAR2
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';             -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;  -- �G���[���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�G���[���b�Z�[�W
    lv_out_msg      VARCHAR2(1000) DEFAULT NULL;  -- ���b�Z�[�W�ϐ�
    lv_message_code VARCHAR2(100)  DEFAULT NULL;  -- ���b�Z�[�W�R�[�h
    lb_msg_return   BOOLEAN        DEFAULT TRUE;
--
  BEGIN
    -- �p�����[�^���O���[�o���ϐ��֊i�[
    gv_info_class := iv_info_class; -- �����
--
    -- ===============================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_errmsg
                       , 1
                       );
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- submain�̌Ăяo��
    -- ==============================================================
    submain(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
--
    -- ===============================
    -- �G���[�o��
    -- ===============================
    -- ���^�[���R�[�h���G���[�ł���ꍇ�̓G���[���b�Z�[�W���o�͂���
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , lv_errmsg
                       , 1
                       );
--
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.LOG
                       , lv_errbuf
                       , 0
                       );
    END IF;
--
    -- ===============================
    -- �x����������s�o��
    -- ===============================
    -- ���^�[���R�[�h���x���ł���ꍇ�͋�s���o�͂���
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                       , NULL
                       , 1
                       );
    END IF;
--
    -- ===============================
    -- �Ώی����o��
    -- ===============================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_target_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_target_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- ===============================
    -- ���������o��
    -- ===============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_normal_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_normal_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- ===============================
    -- �G���[�����o��
    -- ===============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt  := 1;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_err_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_error_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- ===============================
    -- �X�L�b�v�����o��
    -- ===============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_skip_cnt := 0;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , cv_skip_count_msg
                  , cv_token_name1
                  , TO_CHAR( gn_skip_cnt )
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 1
                     );
--
    -- ===============================
    -- �I�����b�Z�[�W
    -- ===============================
    IF ( lv_retcode = cv_status_normal )   THEN
      lv_message_code := cv_normal_msg;
      retcode         := cv_status_normal;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_err_msg;
      retcode         := cv_status_error;
    ELSIF ( lv_retcode = cv_status_warn )  THEN
      lv_message_code := cv_warn_msg;
      retcode         := cv_status_warn;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_short_name_xxccp
                  , lv_message_code
                  );
--
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                     , lv_out_msg
                     , 0
                     );
--
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- ���ʊ֐���O�n���h��
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      retcode := cv_status_error;
--
    -- ���ʊ֐�OTHERS��O�n���h��
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
--
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
  END main;
END XXCOK008A06C;
/
