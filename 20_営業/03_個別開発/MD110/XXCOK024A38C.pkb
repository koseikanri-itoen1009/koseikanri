CREATE OR REPLACE PACKAGE BODY      XXCOK024A38C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A38C(body)
 * Description      : �������l���f�[�^IF�o�́i���n�j
 * MD.050           : �������l���f�[�^IF�o�́i���n�j MD050_COK_024_A38
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_discount_data_p    �������l���f�[�^���o(A-2)
 *  put_discount_data_p    �������l���f�[�^�o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/06/22    1.0   Y.Koh            �V�K�쐬
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
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A38C';                      -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_discount_data_filepath   CONSTANT VARCHAR2(30)         := 'XXCFR1_SALES_DATA_FILEPATH';        -- �������l���f�[�^�t�@�C���p�X(������уf�[�^�Ɠ����p�X)
  cv_discount_data_filename   CONSTANT VARCHAR2(30)         := 'XXCOK1_DISCOUNT_DATA_FILE_NAME';    -- �������l���f�[�^�t�@�C����
  cv_aff1_company_code        CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF1_COMPANY_CODE';          -- ��ЃR�[�h
  cv_ra_trx_type_general      CONSTANT VARCHAR2(30)         := 'XXCOK1_RA_TRX_TYPE_GENERAL';        -- ����^�C�v_�����l��_��ʓX
  cv_sd_sold_return_type      CONSTANT VARCHAR2(35)         := 'XXCFR1_SD_SOLD_RETURN_TYPE';        -- ������уf�[�^����ԕi�敪
  cv_sd_sales_class           CONSTANT VARCHAR2(35)         := 'XXCFR1_SD_SALES_CLASS';             -- ������уf�[�^����敪
  cv_sd_delivery_ptn_class    CONSTANT VARCHAR2(35)         := 'XXCFR1_SD_DELIVERY_PTN_CLASS';      -- ������уf�[�^�[�i�`�ԋ敪
  -- �A�v���P�[�V�����Z�k��
  cv_appli_xxccp_name         CONSTANT VARCHAR2(50)         := 'XXCCP';                             -- �A�v���P�[�V�����Z�k��(����)
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- �A�v���P�[�V�����Z�k��(�ʊJ��)
  cv_appli_xxcfr_name         CONSTANT VARCHAR2(50)         := 'XXCFR';                             -- �A�v���P�[�V�����Z�k��(AR)
  -- ���b�Z�[�W
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- �����������b�Z�[�W
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90003';                  -- �X�L�b�v�������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- �G���[�������b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- ����I�����b�Z�[�W
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90005';                  -- �x���I�����b�Z�[�W
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90006';                  -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_cok_00001            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00001';                  -- �ΏۂȂ����b�Z�[�W
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00003';                  -- �v���t�@�C���擾�G���[
  cv_msg_cok_00009            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00009';                  -- �t�@�C�����݃G���[
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00028';                  -- �Ɩ��������t�擾�G���[
  cv_msg_cfr_00058            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00058';                  -- ���i�R�[�h���ݒ胁�b�Z�[�W
  -- �g�[�N����
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- �����̃g�[�N����
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROFILE';                           -- �v���t�@�C�����̃g�[�N����
  cv_tkn_file_name            CONSTANT VARCHAR2(15)         := 'FILE_NAME';                         -- �t�@�C�����̃g�[�N����
  cv_tkn_trx_type             CONSTANT VARCHAR2(15)         := 'TRX_TYPE';                          -- ����^�C�v�̃g�[�N����
  -- �Q�ƃ^�C�v
  cv_lookup_data_type         CONSTANT VARCHAR2(50)         := 'XXCOK1_DEDUCTION_DATA_TYPE';        -- �T���f�[�^���
  -- �t���O��
  cv_lang_ja                  CONSTANT VARCHAR2(2)          := 'JA';                                -- ���� JA
  cv_flag_y                   CONSTANT VARCHAR2(1)          := 'Y';                                 -- �L�� Y
  -- �L��
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
--
  cv_trx_number               CONSTANT VARCHAR2(10)         := '9999999999';                                            -- �[�i�`�[No
  cv_object_code              CONSTANT VARCHAR2(10)         := '0000000000';                                            -- �����R�[�h
  cv_hc_code                  CONSTANT VARCHAR2(1)          := '1';                                                     -- �g���b�i�R�[���h�j
  cv_score_member_code        CONSTANT VARCHAR2(5)          := '00000';                                                 -- ���ю҃R�[�h
  cv_sales_card_type          CONSTANT VARCHAR2(1)          := '0';                                                     -- �J�[�h����敪�i�����j
  cv_delivery_base_code       CONSTANT VARCHAR2(4)          := '0000';                                                  -- �[�i���_�R�[�h
  cv_unit_sales               CONSTANT VARCHAR2(1)          := '0';                                                     -- ���㐔��
  cv_column_no                CONSTANT VARCHAR2(2)          := '00';                                                    -- �R����No
  cn_zero                     CONSTANT NUMBER               := 0;                                                       -- ��P���i�ō��j,������z�i�ō��j�o�͌Œ�l
--
  cv_format_date_ymd          CONSTANT VARCHAR2(8)          := 'YYYYMMDD';                                              -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymdhns       CONSTANT VARCHAR2(16)         := 'YYYYMMDDHH24MISS';                                      -- ���t�t�H�[�}�b�g�i�N���������b�j
--
  -- ==============================
  -- �O���[�o���ϐ�
  -- ==============================
  gn_target_cnt               NUMBER    DEFAULT 0;                                                  -- �Ώی���
  gn_normal_cnt               NUMBER    DEFAULT 0;                                                  -- ���팏��
  gn_skip_cnt                 NUMBER    DEFAULT 0;                                                  -- �X�L�b�v����
  gn_error_cnt                NUMBER    DEFAULT 0;                                                  -- �G���[����
--
  gd_process_date             DATE;                                                                 -- �Ɩ��������t
  gd_process_month            DATE;                                                                 -- �Ώ۔N��(��)
--
  gv_discount_data_filepath   VARCHAR2(500);                                                        -- �������l���f�[�^�t�@�C���i�[�p�X
  gv_discount_data_filename   VARCHAR2(100);                                                        -- �������l���f�[�^�t�@�C����
  gf_file_hand                UTL_FILE.FILE_TYPE;                                                   -- �t�@�C���E�n���h���̐錾
--
  gv_aff1_company_code        VARCHAR2(30);                                                         -- ��ЃR�[�h
  gv_ra_trx_type_general      VARCHAR2(30);                                                         -- ����^�C�v_�����l��_��ʓX
  gv_item_code                VARCHAR2(30);                                                         -- �������l���̏��n�V�X�e���A�g���i�R�[�h
  gv_sd_sold_return_type      VARCHAR2(30);                                                         -- ������уf�[�^����ԕi�敪
  gv_sd_sales_class           VARCHAR2(30);                                                         -- ������уf�[�^����敪
  gv_sd_delivery_ptn_class    VARCHAR2(30);                                                         -- ������уf�[�^�[�i�`�ԋ敪
--
  -- ==============================
  -- �O���[�o����O
  -- ==============================
  -- *** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
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
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';       -- �v���O������
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
    -- �Ɩ��������t�̎擾
    -- ============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF  gd_process_date IS  NULL  THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_appli_xxcok_name
                                             ,cv_msg_cok_00028
                                             );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    gd_process_month  :=  trunc(gd_process_date,'MM') - 1;
--
    -- ============================================================
    -- �o�̓t�@�C���p�X�擾
    -- ============================================================
    gv_discount_data_filepath := FND_PROFILE.VALUE(cv_discount_data_filepath);
    -- �擾�G���[��
    IF  gv_discount_data_filepath  IS NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_discount_data_filepath
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �o�̓t�@�C�����擾
    -- ============================================================
    gv_discount_data_filename := FND_PROFILE.VALUE(cv_discount_data_filename);
    -- �擾�G���[��
    IF  gv_discount_data_filename IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_discount_data_filename
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- ��ЃR�[�h�擾
    -- ============================================================
    gv_aff1_company_code      := FND_PROFILE.VALUE( cv_aff1_company_code );
    IF  gv_aff1_company_code	IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff1_company_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �������l���̎���^�C�v�擾
    -- ============================================================
    gv_ra_trx_type_general    := FND_PROFILE.VALUE( cv_ra_trx_type_general );
    IF  gv_ra_trx_type_general  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_ra_trx_type_general
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �������l���̏��n�V�X�e���A�g���i�R�[�h�擾
    -- ============================================================
    select  max(attribute3)
    into    gv_item_code
    from    ra_cust_trx_types_all rctta
    where   rctta.name  = gv_ra_trx_type_general;
--
    IF  gv_item_code  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00058
                     ,cv_tkn_trx_type
                     ,gv_ra_trx_type_general
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- ������уf�[�^����ԕi�敪�擾
    -- ============================================================
    gv_sd_sold_return_type    := FND_PROFILE.VALUE( cv_sd_sold_return_type );
    IF  gv_sd_sold_return_type  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_sd_sold_return_type
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- ������уf�[�^����敪�擾
    -- ============================================================
    gv_sd_sales_class         := FND_PROFILE.VALUE( cv_sd_sales_class );
    IF  gv_sd_sales_class IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_sd_sales_class
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- ������уf�[�^�[�i�`�ԋ敪�擾
    -- ============================================================
    gv_sd_delivery_ptn_class  := FND_PROFILE.VALUE( cv_sd_delivery_ptn_class );
    IF  gv_sd_delivery_ptn_class  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_sd_delivery_ptn_class
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
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
   * Procedure Name   : put_discount_data_p
   * Description      : �������l���f�[�^�o��(A-3)
   ***********************************************************************************/
  PROCEDURE put_discount_data_p(
    ov_errbuf               OUT VARCHAR2                    -- �G���[�E���b�Z�[�W
  , ov_retcode              OUT VARCHAR2                    -- ���^�[���E�R�[�h
  , ov_errmsg               OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_base_code_to         IN  VARCHAR2                    -- �U�֐拒�_
  , iv_customer_code_to     IN  VARCHAR2                    -- �U�֐�ڋq�R�[�h
  , iv_tax_code             IN  VARCHAR2                    -- �ŃR�[�h
  , in_deduction_amount     IN  NUMBER                      -- �T���z
  , in_deduction_tax_amount IN  NUMBER                      -- �T���Ŋz
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'put_discount_data_p'; -- �v���O������
--
    cv_delimiter    CONSTANT VARCHAR2(1)    := ',';                             -- CSV��؂蕶��
    cv_enclosed     CONSTANT VARCHAR2(2)    := '"';                             -- �P��͂ݕ���
--
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_base_code              VARCHAR2(4);                            -- �S�����_
    lv_errbuf                 VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode                BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_csv_text               VARCHAR2(32000);                        -- CSV�f�[�^
    -- �ڋq���
    lv_bill_to_cust_code      VARCHAR2(30)        DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    lv_sales_staff_code       VARCHAR2(30)        DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �S���c�ƈ��R�[�h�擾
    -- ============================================================
    lv_sales_staff_code   :=  xxcok_common_pkg.get_sales_staff_code_f( iv_customer_code_to, gd_process_month );
--
    -- ============================================================
    -- ������ڋq�R�[�h�擾
    -- ============================================================
    lv_bill_to_cust_code  :=  xxcok_common_pkg.get_bill_to_cust_code_f( iv_customer_code_to );
--
    -- ============================================================
    -- �������l���f�[�^�o��
    -- ============================================================
    lv_csv_text := cv_enclosed || gv_aff1_company_code || cv_enclosed || cv_delimiter               -- ��ЃR�[�h
                || TO_CHAR ( gd_process_month, cv_format_date_ymd ) || cv_delimiter                 -- �[�i��(GL�L����)
                || cv_enclosed || cv_trx_number || cv_enclosed || cv_delimiter                      -- �[�i�`�[No
                || '1' || cv_delimiter                                                              -- �[�i�`�[�sNo
                || cv_enclosed || iv_customer_code_to || cv_enclosed || cv_delimiter                -- �ڋq�R�[�h
                || cv_enclosed || gv_item_code || cv_enclosed || cv_delimiter                       -- ���i�R�[�h
                || cv_enclosed || cv_object_code || cv_enclosed || cv_delimiter                     -- �����R�[�h
                || cv_enclosed || cv_hc_code || cv_enclosed || cv_delimiter                         -- �g���b
                || cv_enclosed || iv_base_code_to || cv_enclosed || cv_delimiter                    -- ���㋒�_�R�[�h
                || cv_enclosed || lv_sales_staff_code || cv_enclosed || cv_delimiter                -- ���ю҃R�[�h
                || cv_enclosed || cv_sales_card_type || cv_enclosed || cv_delimiter                 -- �J�[�h����敪
                || cv_enclosed || cv_delivery_base_code || cv_enclosed || cv_delimiter              -- �[�i���_�R�[�h
                || TO_CHAR ( - in_deduction_amount ) || cv_delimiter                                -- ������z
                || cv_unit_sales || cv_delimiter                                                    -- ���㐔��
                || TO_CHAR ( - in_deduction_tax_amount ) || cv_delimiter                            -- �Ŋz
                || cv_enclosed || gv_sd_sold_return_type || cv_enclosed || cv_delimiter             -- ����ԕi�敪
                || cv_enclosed || gv_sd_sales_class || cv_enclosed || cv_delimiter                  -- ����敪
                || cv_enclosed || gv_sd_delivery_ptn_class || cv_enclosed || cv_delimiter           -- �[�i�`�ԋ敪
                || cv_enclosed || cv_column_no || cv_enclosed || cv_delimiter                       -- �R����No
                || TO_CHAR ( gd_process_month, cv_format_date_ymd ) || cv_delimiter                 -- �����\���(�����)
                || cv_delimiter                                                                     -- �[�i�P��
                || cv_enclosed || iv_tax_code || cv_enclosed || cv_delimiter                        -- �ŃR�[�h
                || cv_enclosed || lv_bill_to_cust_code || cv_enclosed || cv_delimiter               -- ������ڋq�R�[�h
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- �����`�[�ԍ�
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- �`�[�敪
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- �`�[���ރR�[�h
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- ��K�؂ꎞ��100�~
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- ��K�؂ꎞ��10�~
                || cn_zero                    || cv_delimiter                                       -- ��P���i�ō��j
                || cn_zero                    || cv_delimiter                                       -- ������z�i�ō��j
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- ���؋敪
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- ���؎���
                || TO_CHAR ( SYSDATE, cv_format_date_ymdhns)                                        -- �A�g����
    ;
--
    -- ============================================================
    -- �t�@�C����������
    -- ============================================================
    UTL_FILE.PUT_LINE( gf_file_hand, lv_csv_text ) ;
    gn_normal_cnt :=  gn_normal_cnt + 1;                    -- ���팏��
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
  END put_discount_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_discount_data_p
   * Description      : �������l���f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_discount_data_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'get_sales_exp_p';               -- �v���O������
--
    cv_open_mode_w  CONSTANT VARCHAR2(10)   := 'w';                             -- �t�@�C���I�[�v�����[�h�i�㏑���j
--
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
--
    lb_fexists      BOOLEAN;                                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size    NUMBER;                                 -- �t�@�C���̒���
    ln_block_size   NUMBER;                                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    -- ==============================
    -- ���[�J���J�[�\��
    -- ==============================
    -- �������l�����
    CURSOR l_discount_data_cur
    IS
      WITH
        flvc1 AS
        ( SELECT  /*+ MATERIALIZED */ lookup_code
          FROM    fnd_lookup_values flvc
          WHERE   flvc.lookup_type  = cv_lookup_data_type
          AND     flvc.language     = cv_lang_ja
          AND     flvc.enabled_flag = cv_flag_y
          AND     flvc.attribute10  = cv_flag_y
        )
      SELECT  xsd.base_code_to            base_code_to        ,                 -- �U�֐拒�_
              xsd.customer_code_to        customer_code_to    ,                 -- �U�֐�ڋq�R�[�h
              xsd.tax_code                tax_code            ,                 -- �ŃR�[�h
              SUM(deduction_amount)       deduction_amount    ,                 -- �T���z
              SUM(deduction_tax_amount)   deduction_tax_amount                  -- �T���Ŋz
      FROM    xxcok_sales_deduction   xsd ,
              flvc1                   flv
      WHERE   xsd.data_type           =   flv.lookup_code
      AND     xsd.cancel_gl_date      IS  NULL
      AND     xsd.gl_date             =   gd_process_month
      GROUP BY  xsd.base_code_to    ,
                xsd.customer_code_to,
                xsd.tax_code
    UNION ALL
      SELECT  xsd.base_code_to            base_code_to        ,                 -- �U�֐拒�_
              xsd.customer_code_to        customer_code_to    ,                 -- �U�֐�ڋq�R�[�h
              xsd.tax_code                tax_code            ,                 -- �ŃR�[�h
              -SUM(deduction_amount)      deduction_amount    ,                 -- �T���z
              -SUM(deduction_tax_amount)  deduction_tax_amount                  -- �T���Ŋz
      FROM    xxcok_sales_deduction   xsd ,
              flvc1                   flv
      WHERE   xsd.data_type           =   flv.lookup_code
      AND     xsd.cancel_gl_date      =   gd_process_month
      GROUP BY  xsd.base_code_to    ,
                xsd.customer_code_to,
                xsd.tax_code        ;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ====================================================
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR(gv_discount_data_filepath,
                      gv_discount_data_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- �O��t�@�C�������݂��Ă���
    IF  lb_fexists  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00009
                     ,cv_tkn_file_name
                     ,gv_discount_data_filename
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    gf_file_hand := UTL_FILE.FOPEN
                      ( gv_discount_data_filepath
                       ,gv_discount_data_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ============================================================
    -- �������l����񒊏o
    -- ============================================================
    FOR l_discount_data_rec IN  l_discount_data_cur LOOP
--
      gn_target_cnt :=  gn_target_cnt + 1;                  -- �Ώی���
      -- ============================================================
      -- �������l�����o��(A-3)�̌Ăяo��
      -- ============================================================
      put_discount_data_p(
        ov_errbuf               =>  lv_errbuf                                 -- �G���[�E���b�Z�[�W
      , ov_retcode              =>  lv_retcode                                -- ���^�[���E�R�[�h
      , ov_errmsg               =>  lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_base_code_to         =>  l_discount_data_rec.base_code_to          -- �U�֐拒�_
      , iv_customer_code_to     =>  l_discount_data_rec.customer_code_to      -- �U�֐�ڋq�R�[�h
      , iv_tax_code             =>  l_discount_data_rec.tax_code              -- �ŃR�[�h
      , in_deduction_amount     =>  l_discount_data_rec.deduction_amount      -- �T���z
      , in_deduction_tax_amount =>  l_discount_data_rec.deduction_tax_amount  -- �T���Ŋz
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
    -- ============================================================
    -- �ΏۂȂ��̏ꍇ
    -- ============================================================
    IF gn_normal_cnt = 0 THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_00001
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT   -- �o�͋敪
                      , lv_out_msg        -- ���b�Z�[�W
                      , 1                 -- ���s
                      );
      ov_retcode  :=  cv_status_warn;
    END IF;
--
    -- ============================================================
    -- �t�@�C���N���[�Y
    -- ============================================================
    UTL_FILE.FCLOSE( gf_file_hand ) ;
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
  END get_discount_data_p;
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
    -- ============================================================
    -- �O���[�o���ϐ��̏�����
    -- ============================================================
    gn_target_cnt :=  0;
    gn_normal_cnt :=  0;
    gn_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- =============================================================
    -- init�̌Ăяo��
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
    -- ============================================================
    -- �������l���f�[�^���o�̌Ăяo��
    -- ============================================================
    get_discount_data_p(
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
    errbuf  OUT VARCHAR2                                    -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2                                    -- ���^�[���E�R�[�h
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
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�ϐ�
--
  BEGIN
--
    -- ============================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , NULL               -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
--
    -- ============================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf                               -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                              -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- ============================================================
    -- �G���[�o��
    -- ============================================================
    IF  lv_retcode  = cv_status_error THEN
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT -- �o�͋敪
                      , lv_errmsg       -- ���b�Z�[�W
                      , 1               -- ���s
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.LOG    -- �o�͋敪
                      , lv_errbuf       -- ���b�Z�[�W
                      , 0               -- ���s
                      );
      gn_target_cnt :=  0;
      gn_normal_cnt :=  0;
      gn_skip_cnt   :=  0;
      gn_error_cnt  :=  1;
    END IF;
--
    -- ============================================================
    -- �Ώی����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90000
                    , cv_tkn_count
                    , TO_CHAR( gn_target_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- ���������o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90001
                    , cv_tkn_count
                    , TO_CHAR( gn_normal_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- �X�L�b�v�����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90003
                    , cv_tkn_count
                    , TO_CHAR( gn_skip_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- �G���[�����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90002
                    , cv_tkn_count
                    , TO_CHAR( gn_error_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 1                 -- ���s
                    );
--
    -- ============================================================
    -- �I�����b�Z�[�W
    -- ============================================================
    retcode :=  lv_retcode;
    IF  retcode   = cv_status_normal  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90004
                      );
    ELSIF retcode = cv_status_warn  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90005
                      );
    ELSIF retcode = cv_status_error THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90006
                      );
    END IF;
--
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF  retcode = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
  END main;
END XXCOK024A38C;
/
