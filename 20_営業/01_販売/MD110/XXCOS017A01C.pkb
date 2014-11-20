CREATE OR REPLACE PACKAGE BODY XXCOS017A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS017A01C(spec)
 * Description      : ��U�E�����P���`�F�b�N���W�v
 * MD.050           : ��U�E�����P���`�F�b�N���W�v MD050_COS_017_A01
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  results_total          ��U�E�����P���`�F�b�N���W�v(A-2)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/17    1.0   T.Nakabayashi    �V�K�쐬
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
  --  ===============================
  --  ���[�U�[��`��O
  --  ===============================
  --  *** �v���t�@�C���擾��O�n���h�� ***
  global_get_profile_expt       EXCEPTION;
  --  *** ���b�N�G���[��O�n���h�� ***
  global_data_lock_expt         EXCEPTION;
  --  *** �Ώۃf�[�^�����G���[��O�n���h�� ***
  global_no_data_warm_expt      EXCEPTION;
  --  *** �f�[�^�o�^�G���[��O�n���h�� ***
  global_insert_data_expt       EXCEPTION;
  --  *** �f�[�^�X�V�G���[��O�n���h�� ***
  global_update_data_expt       EXCEPTION;--
  --  *** �f�[�^�폜�G���[��O�n���h�� ***
  global_delete_data_expt       EXCEPTION;--
--
  --
  PRAGMA  EXCEPTION_INIT(global_data_lock_expt, -54);
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�萔
  -- ===============================
--  �p�b�P�[�W��
  cv_pkg_name                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS017A01C';
--
  --�����ʊ֘A
  --  �R���J�����g��
  cv_conc_name                  CONSTANT  VARCHAR2(100)                                   :=  'XXCOS017A01C';
--
  --���A�v���P�[�V�����Z�k��
  --  �̕��Z�k�A�v����
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE     :=  'XXCOS';
--
  --���̕����b�Z�[�W
  --  ���b�N�擾�G���[���b�Z�[�W
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00001';
  --  �v���t�@�C���擾�G���[
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00004';
  --  �f�[�^�o�^�G���[
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00010';
  --  �f�[�^�X�V�G���[
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00011';
  --  �f�[�^�폜�G���[���b�Z�[�W
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00012';
  --  API�ďo�G���[���b�Z�[�W
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00017';
  --  ����0���p���b�Z�[�W
  ct_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00003';
  --  �r�u�e�N���`�o�h
  ct_msg_svf_api                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00041';
  --  �v���h�c
  ct_msg_request                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00042';
--
  --���@�\�ŗL���b�Z�[�W
  --  �p�����[�^�o��
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13701';
  --  �i�ڃR�[�h�E�����P���K�{�w��G���[
  ct_msg_must_unit_and_price    CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13702';
  --  �����P���s���G���[
  ct_msg_invalid_unit_price     CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13703';
  --  ��U�E���P���`�F�b�N���쐬����
  ct_msg_count_create           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13704';
  --  �i�ڑ��݃`�F�b�N�G���[
  ct_msg_err_no_item_found      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-13705';
--
  --���N�C�b�N�R�[�h
  --  �N�C�b�N�R�[�h�i����敪�j
  ct_qct_sale_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';
  --  �N�C�b�N�R�[�h�i����敪����}�X�^�j
  ct_qct_sale_mst_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS_MST_017_A01';
  ct_qcc_sale_mst_base_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_017_A01_';
  --  �N�C�b�N�R�[�h�i��݌ɕi�ڃ}�X�^�j
  ct_qct_no_inv_item
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_NO_INV_ITEM_CODE';
  --  �N�C�b�N�R�[�h�i�o�̓w�b�_�j
  ct_qct_output_header
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_OUTPUT_HEADER_017_A01';
--
  --���Œ�l
  --  �����p�imatch any�j
  cv_match_any                  CONSTANT  VARCHAR2(1) := '%';
  ct_max_unit_price             CONSTANT  xxcos_sales_exp_lines.standard_unit_price%TYPE := 99999999999.99;
  cv_tab                        CONSTANT  VARCHAR2(1) := CHR(9);
--
  --��Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1) := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1) := 'N';
--
  --���p�����[�^���t�w�菑��
  cv_fmt_date_default           CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_time_default           CONSTANT  VARCHAR2(7) := 'HH24:MI';
  cv_fmt_date                   CONSTANT  VARCHAR2(8) := 'YYYYMMDD';
  cv_fmt_date_profile           CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years_in               CONSTANT  VARCHAR2(7) := 'YYYY/MM';
  cv_fmt_years                  CONSTANT  VARCHAR2(6) := 'YYYYMM';
--
  --���g�[�N��
  --  �W�v�Ώ۔N��
  cv_tkn_para_years_for_total   CONSTANT  VARCHAR2(020) := 'PARAM1';
  --  �����敪
  cv_tkn_para_processing_class  CONSTANT  VARCHAR2(020) := 'PARAM2';
  -- �i�ڃR�[�h
  cv_tkn_para_item_code         CONSTANT  VARCHAR2(020) := 'PARAM3';
  --  �����P��
  cv_tkn_para_unit_price        CONSTANT  VARCHAR2(020) := 'PARAM4';
  --  �쐬����
  cv_tkn_create_count           CONSTANT  VARCHAR2(020) := 'CREATE_COUNT';
  -- �i�ڃR�[�h
  cv_tkn_item_code              CONSTANT  VARCHAR2(020) := 'ITEM_CODE';
--
  --���p�����[�^���ʗp
  --  �u1�F��U�v
  cv_para_amends                CONSTANT  VARCHAR2(1) := '1';
  --  �u2�F�����P���`�F�b�N���W�v�v
  cv_para_unit_price_check      CONSTANT  VARCHAR2(1) := '2';
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�^
  --  ===============================
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�ϐ�
  --  ===============================
  --�����ʃf�[�^�i�[�p
  --  ���ʃf�[�^�D���o�N������(date�^)
  gt_common_first_date                    xxcos_sales_exp_headers.delivery_date%TYPE;
  --  ���ʃf�[�^�D���o�N������(date�^)
  gt_common_last_date                     xxcos_sales_exp_headers.delivery_date%TYPE;
  --  ���ʃf�[�^�D�Q�ƃR�[�h
  gt_common_lookup_code                   fnd_lookup_values.lookup_code%TYPE;
  --  ���ʃf�[�^�D�i�ڃR�[�h
  gt_common_item_no                       ic_item_mst_b.item_no%TYPE;
  --  ���ʃf�[�^�D���P��
  gt_common_wholesale_unit_price          xxcos_sales_exp_lines.standard_unit_price%TYPE;
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�E�J�[�\��
  --  ===============================
  --  �o�̓w�b�_���
  CURSOR  header_cur
  IS
    SELECT
            xlhe.description              AS  description
    FROM    xxcos_lookup_values_v     xlhe
    WHERE   xlhe.lookup_type          =       ct_qct_output_header
    ORDER BY
            xlhe.lookup_code
    ;
--
  --  �̔����я��
  CURSOR  sales_cur     (
                        icp_first_date          DATE,
                        icp_last_date           DATE,
                        icp_item_no             VARCHAR2,
                        icp_unit_price          NUMBER,
                        icp_017a01_lookup_code  VARCHAR2
                        )
  IS
    SELECT
            saeh.sales_base_code          AS  base_code,
            base.account_name             AS  base_name,
            saeh.ship_to_customer_code    AS  party_num,
            hzca.account_name             AS  party_name,
            sael.item_code                AS  item_code,
            ximb.item_short_name          AS  item_name,
            SUM(
                CASE  xlsa.attribute5
                  WHEN  cv_no             THEN  sael.standard_qty
                                          ELSE  0
                END
                )                         AS  sale_qty,
            SUM(sael.pure_amount)         AS  pure_amount,
            DECODE(
                  SUM(
                      CASE  xlsa.attribute5
                        WHEN  cv_no             THEN  sael.standard_qty
                                                ELSE  0
                      END
                      )
                  , 0,  0
                     ,  ROUND(SUM(sael.pure_amount) 
                            / SUM(
                                  CASE  xlsa.attribute5
                                    WHEN  cv_no             THEN  sael.standard_qty
                                                            ELSE  0
                                  END
                                  )
                              , 2))             AS  wholesale_unit_price,
            SUM(
                CASE  xlsa.attribute5
                  WHEN  cv_yes            THEN  sael.standard_qty
                                          ELSE  0
                END
                )                         AS  support_qty,
            DECODE(SUM(sael.standard_qty), 0,  0
                  ,ROUND(SUM(sael.pure_amount) / SUM(sael.standard_qty), 2))
                                          AS  real_wholesale_unit_price
    FROM    xxcos_sales_exp_headers   saeh,
            xxcos_sales_exp_lines     sael,
            hz_cust_accounts          hzca,
            hz_cust_accounts          base,
            ic_item_mst_b             iimb,
            xxcmn_item_mst_b          ximb,
            xxcos_lookup_values_v     xlsa,
            xxcos_lookup_values_v     xltk
    WHERE   saeh.delivery_date        BETWEEN icp_first_date
                                      AND     icp_last_date
    AND     sael.sales_exp_header_id  =       saeh.sales_exp_header_id
    AND     hzca.account_number       =       saeh.ship_to_customer_code
    AND     base.account_number       =       saeh.sales_base_code
    AND     sael.item_code            LIKE    icp_item_no
    AND     iimb.item_no              =       sael.item_code
    AND     ximb.item_id              =       iimb.item_id
    AND     icp_last_date             BETWEEN ximb.start_date_active
                                      AND     NVL(ximb.end_date_active, icp_last_date)
    AND     xlsa.lookup_type          =       ct_qct_sale_type
    AND     xlsa.lookup_code          =       sael.sales_class
    AND     icp_last_date             BETWEEN NVL(xlsa.start_date_active, icp_last_date)
                                      AND     NVL(xlsa.end_date_active,   icp_last_date)
    AND     xltk.lookup_type          =       ct_qct_sale_mst_type
    AND     xltk.lookup_code          LIKE    icp_017a01_lookup_code
    AND     xltk.meaning              =       sael.sales_class
    AND     icp_last_date             BETWEEN NVL(xltk.start_date_active, icp_last_date)
                                      AND     NVL(xltk.end_date_active,   icp_last_date)
    AND NOT EXISTS  (
                    SELECT  xlni.ROWID
                    FROM    xxcos_lookup_values_v     xlni
                    WHERE   xlni.lookup_type          =       ct_qct_no_inv_item
                    AND     xlni.lookup_code          =       sael.item_code
                    AND     icp_last_date             BETWEEN NVL(xlni.start_date_active, icp_last_date)
                                                      AND     NVL(xlni.end_date_active,   icp_last_date)
                    AND     ROWNUM                    =       1
                    )
    GROUP BY
            saeh.sales_base_code,
            base.account_name,
            saeh.ship_to_customer_code,
            hzca.account_name,
            sael.item_code,
            ximb.item_short_name
    HAVING  DECODE(SUM(sael.standard_qty), 0,  0
                  ,ROUND(SUM(sael.pure_amount) / SUM(sael.standard_qty), 2))  < icp_unit_price
    ORDER BY
            saeh.sales_base_code,
            saeh.ship_to_customer_code,
            sael.item_code
    ;
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�^
  --  ===============================
  --  �̔����ю��я�� �e�[�u���^�C�v
  TYPE  g_sales_ttype             IS  TABLE OF  sales_cur%ROWTYPE              INDEX BY  PLS_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_years_for_total            IN      VARCHAR2,         --  1.�W�v�Ώ۔N��
    iv_processing_class           IN      VARCHAR2,         --  2.�����敪
    iv_item_code                  IN      VARCHAR2,         --  3.�i�ڃR�[�h
    iv_real_wholesale_unit_price  IN      VARCHAR2,         --  4.�����P��
    ov_errbuf                     OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                    OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                     OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�p�����[�^�o�͗p
    lv_para_msg                 VARCHAR2(5000);
--
    --�i�ڃ}�X�^���݃`�F�b�N�p
    lt_item_no                  ic_item_mst_b.item_no%TYPE;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==================================
    -- 1.���̓p�����[�^�o��
    --==================================
    lv_para_msg     :=  xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_para_years_for_total,
      iv_token_value1  =>  iv_years_for_total,
      iv_token_name2   =>  cv_tkn_para_processing_class,
      iv_token_value2  =>  iv_processing_class,
      iv_token_name3   =>  cv_tkn_para_item_code,
      iv_token_value3  =>  iv_item_code,
      iv_token_name4   =>  cv_tkn_para_unit_price,
      iv_token_value4  =>  iv_real_wholesale_unit_price
      );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    --  1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  NULL
    );
--
    --==================================
    -- 2.����t�擾
    --==================================
    gt_common_first_date  :=  TO_DATE(iv_years_for_total, cv_fmt_years_in);
    gt_common_last_date   :=  LAST_DAY(gt_common_first_date);
    gt_common_lookup_code :=  ct_qcc_sale_mst_base_code
                          ||  iv_processing_class
                          ||  cv_match_any;
--
    IF  ( iv_processing_class = cv_para_unit_price_check  ) THEN
      --  ����t�擾(�u2�F�����P���`�F�b�N���W�v�v�̏ꍇ)
      gt_common_item_no   :=  iv_item_code;
--
      BEGIN
        gt_common_wholesale_unit_price    :=  ROUND(TO_NUMBER(iv_real_wholesale_unit_price), 2);
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application        =>  ct_xxcos_appl_short_name,
            iv_name               =>  ct_msg_invalid_unit_price
            );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      --  ����t�擾(�u2�F�����P���`�F�b�N���W�v�v�ȊO�̏ꍇ)
      gt_common_item_no               :=  cv_match_any;
      gt_common_wholesale_unit_price  :=  ct_max_unit_price;
    END IF;
--
    --==================================
    -- 3.���̓p�����[�^�`�F�b�N
    --==================================
    IF  ( iv_processing_class             =   cv_para_unit_price_check  ) THEN
      --  �o�͋敪���u2�F�����P���`�F�b�N���W�v�v�̎��A�i�ځE�����P���Ɏw�肪�����ꍇ�̓G���[
      IF  (   iv_item_code                  IS  NULL 
          OR  iv_real_wholesale_unit_price  IS  NULL  ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application        =>  ct_xxcos_appl_short_name,
          iv_name               =>  ct_msg_must_unit_and_price
          );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      --  �o�͋敪���u2�F�����P���`�F�b�N���W�v�v�̎��A�i�ڂ��}�X�^�ɖ����ꍇ�̓G���[
      BEGIN
        SELECT  iimb.item_no
        INTO    lt_item_no
        FROM    ic_item_mst_b             iimb,
                xxcmn_item_mst_b          ximb
        WHERE   iimb.item_no              =       gt_common_item_no
        AND     ximb.item_id              =       iimb.item_id
        AND     gt_common_last_date       BETWEEN ximb.start_date_active
                                          AND     NVL(ximb.end_date_active, gt_common_last_date)
        ;
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application        =>  ct_xxcos_appl_short_name,
            iv_name               =>  ct_msg_err_no_item_found,
            iv_token_name1        =>  cv_tkn_item_code,
            iv_token_value1       =>  gt_common_item_no
            );
          lv_errbuf := SQLERRM;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
   * Procedure Name   : summary_sales_results
   * Description      : ��U�E�����P���`�F�b�N���W�v (A-2)
   ***********************************************************************************/
  PROCEDURE summary_sales_results(
    ov_errbuf             OUT     VARCHAR2,         --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode            OUT     VARCHAR2,         --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg             OUT     VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'summary_sales_results'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- �[�i���я�� �e�[�u���^
    l_sales_tab                           g_sales_ttype;
--
    -- �o�͓��e�ҏW
    lv_output                             VARCHAR2(5000);
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --  ===============================
    --  A-2.1 �w�b�_�o��
    --  ===============================
    --  �w�b�_�ҏW
    FOR l_header_rec  IN  header_cur
    LOOP
      IF  ( header_cur%ROWCOUNT = 1 ) THEN
        lv_output :=  l_header_rec.description;
      ELSE
        lv_output :=  lv_output
                  ||  cv_tab
                  ||  l_header_rec.description;
      END IF;
    END LOOP;
--
    --  �w�b�_�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_output
    );
--
    --  ===============================
    --  A-2.2 ��U�E�����P���`�F�b�N���W�v
    --  ===============================
    --  �J�[�\���I�[�v��
    OPEN  sales_cur (
                    gt_common_first_date,
                    gt_common_last_date,
                    gt_common_item_no,
                    gt_common_wholesale_unit_price,
                    gt_common_lookup_code
                    );
--
    -- ���R�[�h�ǂݍ���
    FETCH sales_cur BULK COLLECT  INTO  l_sales_tab;
--
    -- �Ώی����擾
    gn_target_cnt   :=  l_sales_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE sales_cur;
--
--
    --  0���̏ꍇ�o�^�������X�L�b�v
    IF  ( l_sales_tab.COUNT <>  0 ) THEN
--
      <<sales_data_create>>
      FOR lp_idx IN l_sales_tab.FIRST..l_sales_tab.LAST LOOP
        lv_output :=  l_sales_tab(lp_idx).base_code
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).base_name
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).party_num
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).party_name
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).item_code
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).item_name
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).sale_qty
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).pure_amount
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).wholesale_unit_price
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).support_qty
                  ||  cv_tab
                  ||  l_sales_tab(lp_idx).real_wholesale_unit_price
        ;
--
          FND_FILE.PUT_LINE(
             which  =>  FND_FILE.OUTPUT
            ,buff   =>  lv_output
          );
      END LOOP  sales_data_create;
--
    --  0���̏ꍇ�o�^�������X�L�b�v
    END IF;
--
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END summary_sales_results;
--
  /**********************************************************************************
   * Procedure Name   : end_process
   * Description      : �I������(A-3)
   ***********************************************************************************/
  PROCEDURE end_process(
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_process'; -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==================================
    -- 1.�����������b�Z�[�W�ҏW  �i��U�E���P���`�F�b�N���j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_create,
      iv_token_name1 => cv_tkn_create_count,
      iv_token_value1=> gn_target_cnt
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END end_process;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_years_for_total            IN      VARCHAR2,         --  1.�W�v�Ώ۔N��
    iv_processing_class           IN      VARCHAR2,         --  2.�����敪
    iv_item_code                  IN      VARCHAR2,         --  3.�i�ڃR�[�h
    iv_real_wholesale_unit_price  IN      VARCHAR2,         --  4.�����P��
    ov_errbuf                     OUT     VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                    OUT     VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                     OUT     VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --  ===============================
    --  <�������A���[�v����> (�������ʂɂ���Č㑱�����𐧌䂷��ꍇ)
    --  ===============================
    init(
      iv_years_for_total
      ,iv_processing_class
      ,iv_item_code
      ,iv_real_wholesale_unit_price
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  ��U�E�����P���`�F�b�N���W�v(A-2)
    --  ===============================
   summary_sales_results(
      lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --(�G���[����)
--
      --  �J�[�\���N���[�Y
      IF  ( sales_cur%ISOPEN ) THEN
        CLOSE sales_cur;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  �I������(A-3)
    --  ===============================
    end_process(
      lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  �{�@�\�͑Ώی��������팏���Ƃ���
    gn_normal_cnt :=  gn_target_cnt;
--
    --���ׂO�����̌x���I������
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
      --  �Ώۃf�[�^�Ȃ�
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                                            iv_application          => ct_xxcos_appl_short_name,
                                            iv_name                 => ct_msg_nodata_err
                                            );
      --  ��s�o��
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.LOG
        ,buff   =>  NULL
      );
      --  �Ώۃf�[�^�Ȃ����b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.LOG
        ,buff   =>  lv_errmsg
      );
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
    errbuf                        OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode                       OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_years_for_total            IN      VARCHAR2,         --  1.�W�v�Ώ۔N��
    iv_processing_class           IN      VARCHAR2,         --  2.�����敪
    iv_item_code                  IN      VARCHAR2,         --  3.�i�ڃR�[�h
    iv_real_wholesale_unit_price  IN      VARCHAR2          --  4.�����P��
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
--    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-91003'; -- �G���[�I��
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
/*
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
*/
--###########################  �Œ蕔 END   #############################
--
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_years_for_total
      ,iv_processing_class
      ,iv_item_code
      ,iv_real_wholesale_unit_price
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCOS017A01C;
/
