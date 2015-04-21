CREATE OR REPLACE PACKAGE BODY APPS.XXCOS012A05R
AS
 /*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCOS012A05R(body)
 * Description      : ���b�g�ʃs�b�N���X�g�i�`�F�[���E���i�ʃg�[�^���j
 * MD.050           : MD050_COS_012_A05_���b�g�ʃs�b�N���X�g�i�`�F�[���E���i�ʃg�[�^���j
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_parameter        �p�����[�^�`�F�b�N����(A-2)
 *  get_data               �f�[�^�擾(A-3)
 *  insert_rpt_wrk_data    ���[���[�N�e�[�u���o�^(A-4)
 *  execute_svf            �r�u�e�N��(A-5)
 *  delete_rpt_wrk_data    ���[���[�N�e�[�u���폜(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/07    1.0   S.Itou           �V�K�쐬
 *  2015/04/10    1.1   S.Yamashita      �yE_�{�ғ�_13004�z�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
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
  global_proc_date_err_expt EXCEPTION;
  global_call_api_expt      EXCEPTION;
  global_date_reversal_expt EXCEPTION;
  global_insert_data_expt   EXCEPTION;
  global_delete_data_expt   EXCEPTION;
  global_get_profile_expt   EXCEPTION;
  global_lookup_code_expt   EXCEPTION;
  global_data_lock_expt     EXCEPTION;
  global_get_basecode_expt  EXCEPTION;
  global_get_chaincode_expt EXCEPTION;
--  Add Ver1.1 S.Yamashita Start
  global_get_custcode_expt  EXCEPTION;
--  Add Ver1.1 S.Yamashita End
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS012A05R';          -- �p�b�P�[�W��
--
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS012A05R';          -- �R���J�����g��
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS012A05R';          -- ���[�h�c
  cv_extension_pdf          CONSTANT VARCHAR2(100) := '.pdf';                  -- �g���q�i�o�c�e�j
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS012A05S.xml';      -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS012A05S.vrq';      -- �N�G���[�l���t�@�C����
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                     -- �o�͋敪�i�o�c�e�j
--
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOS';                      --�̕��Z�k�A�v����
  cv_xxcoi_short_name       CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOI';                      --�݌ɗ̈�Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_lock_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';           --���b�N�擾�G���[���b�Z�[�W
  ct_msg_get_profile_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00004';           --�v���t�@�C���擾�G���[
  ct_msg_date_reversal_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00005';           --���t�t�]�G���[
  ct_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';           --�f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_delete_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';           --�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';           --�f�[�^�擾�G���[���b�Z�[�W
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00014';           --�Ɩ����t�擾�G���[
  ct_msg_call_api_err       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00017';           --API�ďo�G���[���b�Z�[�W
  ct_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';           --����0���p���b�Z�[�W
  ct_msg_bace_code          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00035';           --���_���擾�G���[���b�Z�[�W
  ct_msg_chain_code         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00036';           --EDI�`�F�[���X���擾�G���[���b�Z�[�W
  ct_msg_svf_api            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00041';           --�r�u�e�N���`�o�h
  ct_msg_request            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00042';           --�v���h�c
  ct_msg_max_date           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00056';           --XXCOS:MAX���t
  ct_msg_parameter          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14801';           --�p�����[�^�o�̓��b�Z�[�W
  ct_msg_req_dt_from        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12652';           --����(From)
  ct_msg_req_dt_to          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12653';           --����(To)
  ct_msg_rpt_wrk_tbl        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14803';           --���[���[�N�e�[�u��
  ct_msg_bargain_cls_tblnm  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12655';           --��ԓ����敪�N�C�b�N�R�[�h�}�X�^
  ct_msg_shipping_sts_tblnm CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14802';           --�o�׏��X�e�[�^�X�N�C�b�N�R�[�h�}�X�^
--  Add Ver1.1 S.Yamashita Start
  ct_msg_customer_tblnm     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00049';           --�ڋq�}�X�^
--  Add Ver1.1 S.Yamashita End
  --�g�[�N��
  cv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';                  --�e�[�u��
  cv_tkn_date_from          CONSTANT VARCHAR2(100) := 'DATE_FROM';              --���t�iFrom)
  cv_tkn_date_to            CONSTANT VARCHAR2(100) := 'DATE_TO';                --���t�iTo)
  cv_tkn_profile            CONSTANT VARCHAR2(100) := 'PROFILE';                --�v���t�@�C��
  cv_tkn_table_name         CONSTANT VARCHAR2(100) := 'TABLE_NAME';             --�e�[�u������
  cv_tkn_key_data           CONSTANT VARCHAR2(100) := 'KEY_DATA';               --�L�[�f�[�^
  cv_tkn_code               CONSTANT VARCHAR2(100) := 'CODE';                   --���_�R�[�h
  cv_tkn_chain_code         CONSTANT VARCHAR2(100) := 'CHAIN_SHOP_CODE';        --�`�F�[���X�R�[�h
  cv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';               --�`�o�h����
  cv_tkn_param1             CONSTANT VARCHAR2(100) := 'PARAM1';                 --��P���̓p�����[�^�^���e
  cv_tkn_param2             CONSTANT VARCHAR2(100) := 'PARAM2';                 --��Q���̓p�����[�^�^���e
  cv_tkn_param3             CONSTANT VARCHAR2(100) := 'PARAM3';                 --��R���̓p�����[�^�^���e
  cv_tkn_param4             CONSTANT VARCHAR2(100) := 'PARAM4';                 --��S���̓p�����[�^
  cv_tkn_param5             CONSTANT VARCHAR2(100) := 'PARAM5';                 --��T���̓p�����[�^
  cv_tkn_param6             CONSTANT VARCHAR2(100) := 'PARAM6';                 --��U���̓p�����[�^�^���e
  cv_tkn_param7             CONSTANT VARCHAR2(100) := 'PARAM7';                 --��V���̓p�����[�^
  cv_tkn_param8             CONSTANT VARCHAR2(100) := 'PARAM8';                 --��W���̓p�����[�^�^���e
--  Add Ver1.1 S.Yamashita Start
  cv_tkn_param9             CONSTANT VARCHAR2(100) := 'PARAM9';                 --��X���̓p�����[�^
--  Add Ver1.1 S.Yamashita End

  cv_tkn_request            CONSTANT VARCHAR2(100) := 'REQUEST';                --�v���h�c
  --�v���t�@�C������
  ct_prof_max_date          CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_MAX_DATE';
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_bargain_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_BARGAIN_CLASS';
  ct_qct_shipping_staus     CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOI1_SHIPPING_STATUS';
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                          --�g�p�\
  --��ԓ����敪
  cv_bargain_class_all      CONSTANT VARCHAR2(2)   := '00';           --�S��
  --�t�H�[�}�b�g
  cv_fmt_date8              CONSTANT VARCHAR2(8)   := 'RRRRMMDD';
  cv_fmt_date               CONSTANT VARCHAR2(30)  := 'RRRR/MM/DD';
  cv_fmt_datetime           CONSTANT VARCHAR2(30)  := 'RRRR/MM/DD HH24:MI:SS';
  -- ����R�[�h
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  -- ���ԁi�ŏ��A�ő�)
  cv_time_min               CONSTANT VARCHAR2(8)  := '00:00:00';
  cv_time_max               CONSTANT VARCHAR2(8)  := '23:59:59';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���[���[�N�p�e�[�u���^��`
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_lot_pick_chain_pro%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�p�����[�^
  gv_login_base_code                  VARCHAR2(4);                    -- ���_
  gv_login_chain_store_code           VARCHAR2(4);                    -- �`�F�[���X
--  Add Ver1.1 S.Yamashita Start
  gv_login_customer_code              VARCHAR2(9);                    -- �ڋq
--  Add Ver1.1 S.Yamashita End
  gd_request_date_from                DATE;                           -- ����(From)
  gd_request_date_to                  DATE;                           -- ����(To)
  gd_edi_received_date                DATE := NULL;                   -- EDI��M��
  gt_bargain_class                    fnd_lookup_values.lookup_code%TYPE;
                                                                      -- ��ԓ����敪
  gt_bargain_class_name               fnd_lookup_values.meaning%TYPE; -- ��ԓ����敪�i�w�b�_�j����
  gv_order_number                     VARCHAR2(10);                   -- �󒍔ԍ�
  --�����擾
  gd_process_date                     DATE;                           -- �Ɩ����t
  gd_max_date                         DATE;                           -- MAX���t
  gt_shipping_sts_cd1                 fnd_lookup_values.attribute1%TYPE;
                                                                      -- �o�׏��X�e�[�^�X�R�[�h1
  gt_shipping_sts_cd2                 fnd_lookup_values.attribute2%TYPE;
                                                                      -- �o�׏��X�e�[�^�X�R�[�h2
  gt_shipping_sts_cd3                 fnd_lookup_values.attribute3%TYPE;
                                                                      -- �o�׏��X�e�[�^�X�R�[�h3
--  Add Ver1.1 S.Yamashita Start
  gv_login_customer_name              VARCHAR2(40);                   -- �ڋq��
--  Add Ver1.1 S.Yamashita End
  --���[���[�N�����e�[�u��
  g_rpt_data_tab                      g_rpt_data_ttype;
--
  -- ===============================
  -- ���[�U�[��`�֐�
  -- ===============================
  --���l��r
  FUNCTION comp_num(
    in_arg1                   IN      NUMBER,
    in_arg2                   IN      NUMBER)
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( in_arg1 IS NULL ) AND ( in_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( in_arg1 IS NULL ) AND ( in_arg2 IS NOT NULL ) ) THEN
        RETURN  FALSE;
    ELSIF ( ( in_arg1 IS NOT NULL ) AND ( in_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( in_arg1 = in_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
  --�������r
  FUNCTION comp_char(
    iv_arg1                   IN      VARCHAR2
   ,iv_arg2                   IN      VARCHAR2
  )
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( iv_arg1 IS NOT NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( iv_arg1 = iv_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
  --���t��r
  FUNCTION comp_date(
    id_arg1                   IN      DATE
   ,id_arg2                   IN      DATE
  )
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( id_arg1 IS NOT NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( id_arg1 = id_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_login_base_code        IN  VARCHAR2    -- 1.���_
   ,iv_login_chain_store_code IN  VARCHAR2    -- 2.�`�F�[���X
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN  VARCHAR2    -- 3.�ڋq
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN  VARCHAR2    -- 4.�����iFrom�j
   ,iv_request_date_to        IN  VARCHAR2    -- 5.�����iTo�j
   ,iv_bargain_class          IN  VARCHAR2    -- 6.��ԓ����敪
   ,iv_edi_received_date      IN  VARCHAR2    -- 7.EDI��M��
   ,iv_shipping_status        IN  VARCHAR2    -- 8.�X�e�[�^�X
   ,iv_order_number           IN  VARCHAR2    -- 9.�󒍔ԍ�
   ,ov_errbuf                 OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                 OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    cv_cust_cls_cd_base       CONSTANT VARCHAR2(1) := '1';
    cv_cust_cls_cd_chain      CONSTANT VARCHAR2(2) := '18';
--
    -- *** ���[�J���ϐ� ***
    lv_profile_name           VARCHAR2(5000);
    lv_table_name             VARCHAR2(5000);
    lv_max_date               VARCHAR2(5000);
    lt_shipping_sts_name      fnd_lookup_values.meaning%TYPE;  -- �o�׏��X�e�[�^�X�E�v
    lv_login_base_name        VARCHAR2(40);
    lv_login_chain_store_name VARCHAR2(40);
--  Add Ver1.1 S.Yamashita Start
    lt_customer_name          hz_parties.party_name%TYPE  DEFAULT NULL; -- �ڋq��
--  Add Ver1.1 S.Yamashita End
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
    --==================================
    -- 1.�Ɩ����t�擾
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.XXCOS:MAX���t�擾
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_date IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 3.���_�A�`�F�[���X���̎擾
    --==================================
--
    --���_��
    BEGIN
      SELECT
        hp.party_name         base_name
      INTO
        lv_login_base_name
      FROM
        xxcmm_cust_accounts xca
       ,hz_cust_accounts hca
       ,hz_parties hp
      WHERE
        hca.cust_account_id     = xca.customer_id
      AND
        hca.party_id            = hp.party_id
      AND
        hca.account_number      = iv_login_base_code
      AND
        hca.customer_class_code = cv_cust_cls_cd_base
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_login_base_name := NULL;
    END;
    
    --�p�����[�^�̃`�F�[���X�R�[�h���ݒ肳��Ă���ꍇ�A���̂��擾����
    IF ( iv_login_chain_store_code IS NOT NULL )THEN
      BEGIN
        SELECT
          hp.party_name       chain_store_name
        INTO
          lv_login_chain_store_name
        FROM
          xxcmm_cust_accounts xca
         ,hz_cust_accounts hca
         ,hz_parties hp
        WHERE
          hca.cust_account_id     = xca.customer_id
        AND
          hca.party_id            = hp.party_id
        AND
          xca.chain_store_code    = iv_login_chain_store_code
        AND
          hca.customer_class_code = cv_cust_cls_cd_chain
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_login_chain_store_name := NULL;
      END;
    END IF;
--
--  Add Ver1.1 S.Yamashita Start
    --�p�����[�^�̌ڋq�R�[�h���ݒ肳��Ă���ꍇ�A���̂��擾����
    IF ( iv_login_customer_code IS NOT NULL ) THEN
      BEGIN
        SELECT hp.party_name       AS customer_name
        INTO   lt_customer_name
        FROM   hz_cust_accounts    hca
             , hz_parties          hp
             , xxcmm_cust_accounts xca
        WHERE  hca.party_id            = hp.party_id
        AND    hca.account_number      = iv_login_customer_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lt_customer_name := NULL;
      END;
    END IF;
--  Add Ver1.1 S.Yamashita End
--
    --==================================
    -- 4.��ԓ����敪�i�w�b�_�j�`�F�b�N
    --==================================
--
    BEGIN
      SELECT
        flv.meaning                     bargain_class_name
      INTO
        gt_bargain_class_name
      FROM
        fnd_lookup_values               flv
      WHERE
          flv.lookup_type               = ct_qct_bargain_class
      AND flv.lookup_code               = iv_bargain_class
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
      AND flv.language                  = ct_lang
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        gt_bargain_class_name := NULL;
    END;
--
    --==================================
    -- 5.�o�׏��X�e�[�^�X�擾
    --==================================
--
    BEGIN
      SELECT
        flv.attribute1                  shipping_status_code1         --�o�׏��X�e�[�^�X�R�[�h1
       ,flv.attribute2                  shipping_status_code2         --�o�׏��X�e�[�^�X�R�[�h2
       ,flv.attribute3                  shipping_status_code3         --�o�׏��X�e�[�^�X�R�[�h3
       ,flv.meaning                     shipping_status_name          --�o�׏��X�e�[�^�X�E�v
      INTO
        gt_shipping_sts_cd1
       ,gt_shipping_sts_cd2
       ,gt_shipping_sts_cd3
       ,lt_shipping_sts_name
      FROM
        fnd_lookup_values               flv
      WHERE
          flv.lookup_type               = ct_qct_shipping_staus
      AND flv.lookup_code               = iv_shipping_status         --�p�����[�^_�o�׏��X�e�[�^�X
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
      AND flv.language                  = ct_lang
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_shipping_sts_name := NULL;
    END;
--
     --==================================
    -- 6.�p�����[�^�o��
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_parameter
                                  ,iv_token_name1        => cv_tkn_param1
                                  ,iv_token_value1       => iv_login_base_code || cv_msg_sla || lv_login_base_name
                                  ,iv_token_name2        => cv_tkn_param2
                                  ,iv_token_value2       => iv_login_chain_store_code || cv_msg_sla || lv_login_chain_store_name
--  Mod Ver1.1 S.Yamashita Start
--                                  ,iv_token_name3        => cv_tkn_param3
--                                  ,iv_token_value3       => iv_request_date_from
--                                  ,iv_token_name4        => cv_tkn_param4
--                                  ,iv_token_value4       => iv_request_date_to
--                                  ,iv_token_name5        => cv_tkn_param5
--                                  ,iv_token_value5       => iv_bargain_class || cv_msg_sla || gt_bargain_class_name
--                                  ,iv_token_name6        => cv_tkn_param6
--                                  ,iv_token_value6       => iv_edi_received_date
--                                  ,iv_token_name7        => cv_tkn_param7
--                                  ,iv_token_value7       => iv_shipping_status || cv_msg_sla || lt_shipping_sts_name
--                                  ,iv_token_name8        => cv_tkn_param8
--                                  ,iv_token_value8       => iv_order_number
                                  ,iv_token_name3        => cv_tkn_param3
                                  ,iv_token_value3       => iv_login_customer_code || cv_msg_sla || lt_customer_name
                                  ,iv_token_name4        => cv_tkn_param4
                                  ,iv_token_value4       => iv_request_date_from
                                  ,iv_token_name5        => cv_tkn_param5
                                  ,iv_token_value5       => iv_request_date_to
                                  ,iv_token_name6        => cv_tkn_param6
                                  ,iv_token_value6       => iv_bargain_class || cv_msg_sla || gt_bargain_class_name
                                  ,iv_token_name7        => cv_tkn_param7
                                  ,iv_token_value7       => iv_edi_received_date
                                  ,iv_token_name8        => cv_tkn_param8
                                  ,iv_token_value8       => iv_shipping_status || cv_msg_sla || lt_shipping_sts_name
--  Mod Ver1.1 S.Yamashita End
--  Add Ver1.1 S.Yamashita Start
                                  ,iv_token_name9        => cv_tkn_param9
                                  ,iv_token_value9       => iv_order_number
--  Add Ver1.1 S.Yamashita End
                                 );
    --
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
    --1�s��
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => NULL
    );
--
    -- ���̎擾�G���[�n���h�����O
    CASE
      -- ���_���擾�G���[��
      WHEN lv_login_base_name IS NULL
        THEN
          RAISE global_get_basecode_expt;
      -- �`�F�[���X���擾�G���[��
      WHEN iv_login_chain_store_code IS NOT NULL
      AND  lv_login_chain_store_name IS NULL
        THEN
          RAISE global_get_chaincode_expt;
--  Add Ver1.1 S.Yamashita Start
      -- �ڋq���擾�G���[��
      WHEN iv_login_customer_code IS NOT NULL
      AND  lt_customer_name       IS NULL
        THEN
          lv_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_customer_tblnm
                                 );
          RAISE global_get_custcode_expt;
--  Add Ver1.1 S.Yamashita End
      -- ��ԓ����敪�i�w�b�_�j�擾�G���[��
      WHEN gt_bargain_class_name IS NULL
        THEN
          lv_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_bargain_cls_tblnm
                                 );
          RAISE global_lookup_code_expt;
      -- �o�׏��X�e�[�^�X�擾�G���[��
      WHEN lt_shipping_sts_name IS NULL
        THEN
          lv_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_shipping_sts_tblnm
                                 );
          RAISE global_lookup_code_expt;
      ELSE
        NULL;
    END CASE ;
--
    --==================================
    -- 7.�p�����[�^�ϊ�
    --==================================
    gv_login_base_code        := iv_login_base_code;
    gv_login_chain_store_code := iv_login_chain_store_code;
--  Add Ver1.1 S.Yamashita Start
    gv_login_customer_code    := iv_login_customer_code;
    gv_login_customer_name    := SUBSTRB(lt_customer_name,1,40);
--  Add Ver1.1 S.Yamashita End
    gt_bargain_class          := iv_bargain_class;
    gv_order_number           := iv_order_number;
    --�����b�t�^
    gd_request_date_from      := TO_DATE( TO_CHAR( TO_DATE(iv_request_date_from, cv_fmt_date)
                                                  ,cv_fmt_date) || cv_time_min
                                         ,cv_fmt_datetime );
    gd_request_date_to        := TO_DATE( TO_CHAR( TO_DATE(iv_request_date_to,   cv_fmt_date)
                                                  ,cv_fmt_date) || cv_time_max
                                         ,cv_fmt_datetime );
    IF ( iv_edi_received_date IS NOT NULL )THEN
      gd_edi_received_date    := TO_DATE( TO_CHAR( TO_DATE(iv_edi_received_date,   cv_fmt_date)
                                                  ,cv_fmt_date) || cv_time_min
                                         ,cv_fmt_datetime );
    END IF;
    --�p�����[�^�̒�ԓ����敪���u�S�āv�̏ꍇ�A���̂�NULL�N���A����B
    IF ( gt_bargain_class = cv_bargain_class_all ) THEN
      gt_bargain_class_name   := NULL;
    END IF;
--
  EXCEPTION
--
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_get_profile_err
                                  ,iv_token_name1        => cv_tkn_profile
                                  ,iv_token_value1       => lv_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���_�R�[�h�擾��O�n���h�� ***
    WHEN global_get_basecode_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_bace_code
                                  ,iv_token_name1        => cv_tkn_code
                                  ,iv_token_value1       => iv_login_base_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �`�F�[���X�R�[�h�擾��O�n���h�� ***
    WHEN global_get_chaincode_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_chain_code
                                  ,iv_token_name1        => cv_tkn_chain_code
                                  ,iv_token_value1       => iv_login_chain_store_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--  Add Ver1.1 S.Yamashita Start
    -- *** �ڋq�R�[�h�擾��O�n���h�� ***
    WHEN global_get_custcode_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_select_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--  Add Ver1.1 S.Yamashita End
    -- *** �N�C�b�N�R�[�h�}�X�^��O�n���h�� ***
    WHEN global_lookup_code_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_select_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : �p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter';        -- �v���O������
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
    lv_req_dt_from   VARCHAR2(5000);
    lv_req_dt_to     VARCHAR2(5000);
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
    --==================================
    -- ���t�t�]�`�F�b�N
    --==================================
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      RAISE global_date_reversal_expt;
    END IF;
--
  EXCEPTION
    -- *** ���t�t�]��O�n���h�� ***
    WHEN global_date_reversal_expt THEN
      lv_req_dt_from          := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_req_dt_from
                                 );
      lv_req_dt_to            := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_req_dt_to
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_date_reversal_err
                                  ,iv_token_name1        => cv_tkn_date_from
                                  ,iv_token_value1       => lv_req_dt_from
                                  ,iv_token_name2        => cv_tkn_date_to
                                  ,iv_token_value2       => lv_req_dt_to
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
    --�W�v�p�ϐ�
    ln_case_qty      NUMBER;
    ln_singly_qty    NUMBER;
    ln_summary_qty   NUMBER;
--
    --�L�[�u���C�N�ϐ�
    lt_key_base_code               xxcoi_lot_reserve_info.base_code%TYPE;
    lt_key_base_name               xxcoi_lot_reserve_info.base_name%TYPE;
    lt_key_whse_code               xxcoi_lot_reserve_info.whse_code%TYPE;
    lt_key_whse_name               xxcoi_lot_reserve_info.whse_name%TYPE;
    lt_key_chain_code              xxcoi_lot_reserve_info.chain_code%TYPE;
    lt_key_chain_name              xxcoi_lot_reserve_info.chain_name%TYPE;
    lt_key_center_code             xxcoi_lot_reserve_info.center_code%TYPE;
    lt_key_center_name             xxcoi_lot_reserve_info.center_name%TYPE;
    lt_key_area_code               xxcoi_lot_reserve_info.area_code%TYPE;
    lt_key_area_name               xxcoi_lot_reserve_info.area_name%TYPE;
    lt_key_shipped_date            xxcoi_lot_reserve_info.shipped_date%TYPE;
    lt_key_arrival_date            xxcoi_lot_reserve_info.arrival_date%TYPE;
    lt_key_item_code               xxcoi_lot_reserve_info.item_code%TYPE;
    lt_key_item_name               xxcoi_lot_reserve_info.item_name%TYPE;
    lt_key_content                 xxcoi_lot_reserve_info.case_in_qty%TYPE;
    lt_key_reg_sal_cls_name_line   xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE;
    lt_key_item_div                xxcoi_lot_reserve_info.item_div%TYPE;
    lt_key_item_div_name           xxcoi_lot_reserve_info.item_div_name%TYPE;
    lt_key_location_code           xxcoi_lot_reserve_info.location_code%TYPE;
    lt_key_location_name           xxcoi_lot_reserve_info.location_name%TYPE;
    lt_key_lot                     xxcoi_lot_reserve_info.lot%TYPE;
    lt_key_difference_summary_code xxcoi_lot_reserve_info.difference_summary_code%TYPE;
    lt_key_shipping_sts_name       xxcoi_lot_reserve_info.shipping_status_name%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR data_cur
    IS
      SELECT
        xlri.base_code                  base_code                     --���_�R�[�h
       ,xlri.base_name                  base_name                     --���_����
       ,xlri.whse_code                  whse_code                     --�ۊǏꏊ�R�[�h�i�q�Ɂj
       ,xlri.whse_name                  whse_name                     --�ۊǏꏊ���i�q�ɖ��j
       ,xlri.chain_code                 chain_code                    --�`�F�[���X�R�[�h
       ,xlri.chain_name                 chain_name                    --�`�F�[���X��
       ,xlri.center_code                center_code                   --�Z���^�[�R�[�h
       ,xlri.center_name                center_name                   --�Z���^�[��
       ,xlri.area_code                  area_code                     --�n��R�[�h
       ,xlri.area_name                  area_name                     --�n�於
       ,xlri.shipped_date               shipped_date                  --�o�ד�
       ,xlri.arrival_date               arrival_date                  --����
       ,xlri.item_code                  item_code                     --���i�R�[�h
       ,xlri.item_name                  item_name                     --���i��
       ,xlri.case_in_qty                case_in_qty                   --����
       ,xlri.case_qty                   case_qty                      --�P�[�X
       ,xlri.singly_qty                 singly_qty                    --�o��
       ,xlri.summary_qty                summary_qty                   --����
       ,xlri.regular_sale_class_line    regular_sale_class_line       --��ԓ����敪(����)
       ,xlri.regular_sale_class_name_line regular_sale_class_name_line --��ԓ����敪��(����)
       ,xlri.item_div                   item_div                      --���i�敪
       ,xlri.item_div_name              item_div_name                 --���i�敪��
       ,xlri.location_code              location_code                 --���P�[�V�����R�[�h
       ,xlri.location_name              location_name                 --���P�[�V��������
       ,xlri.lot                        lot                           --���b�g�i�ܖ������j
       ,xlri.difference_summary_code    difference_summary_code       --�ŗL�L��
       ,xlri.shipping_status            shipping_status               --�o�׏��X�e�[�^�X
       ,xlri.shipping_status_name       shipping_sts_name             --�o�׏��X�e�[�^�X����
      FROM
        xxcoi_lot_reserve_info          xlri                          --���b�g�ʈ������
      WHERE
        xlri.base_code                  = gv_login_base_code 
      AND  ( gv_login_chain_store_code  IS NULL
        OR   xlri.chain_code            = gv_login_chain_store_code
           )
--  Add Ver1.1 S.Yamashita Start
      AND  ( gv_login_customer_code     IS NULL
        OR   xlri.customer_code         = gv_login_customer_code
           )
--  Add Ver1.1 S.Yamashita End
      AND    xlri.arrival_date    BETWEEN gd_request_date_from AND gd_request_date_to
      AND  ( gt_bargain_class           =  cv_bargain_class_all
        OR   xlri.regular_sale_class_line = gt_bargain_class
           )
      AND  ( gd_edi_received_date      IS NULL
        OR  ( xlri.edi_received_date   >= gd_edi_received_date
          AND xlri.edi_received_date    < gd_edi_received_date + 1
            )
          )
      AND  xlri.parent_shipping_status IN ( gt_shipping_sts_cd1
                                           ,gt_shipping_sts_cd2
                                           ,gt_shipping_sts_cd3
                                          )
      AND  ( gv_order_number           IS NULL
        OR   xlri.order_number          = gv_order_number
           )
      ORDER BY
        xlri.base_code                                                --���_�R�[�h
       ,xlri.whse_code                                                --�q��
       ,xlri.chain_code                                               --�`�F�[���X�R�[�h
       ,xlri.center_code                                              --�Z���^�[�R�[�h
       ,xlri.area_code                                                --�n��R�[�h
       ,xlri.shipped_date                                             --�o�ד�
       ,xlri.arrival_date                                             --����
       ,xlri.regular_sale_class_line                                  --��ԓ����敪(����)
       ,xlri.item_div                                                 --���i�敪
       ,xlri.location_code                                            --���P�[�V�����R�[�h
       ,xlri.item_code                                                --���i�R�[�h
       ,xlri.lot                                                      --�ܖ�����
       ,xlri.difference_summary_code                                  --�ŗL�L��
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_data_rec                          data_cur%ROWTYPE;
--
    -- *** ���[�J���E�v���V�[�W�� ***
    --==================================
    --�L�[�u���C�N���ڃZ�b�g
    --==================================
    PROCEDURE set_key_item
    IS
    BEGIN
      lt_key_base_code               := l_data_rec.base_code;
      lt_key_base_name               := l_data_rec.base_name;
      lt_key_whse_code               := l_data_rec.whse_code;
      lt_key_whse_name               := l_data_rec.whse_name ;
      lt_key_chain_code              := l_data_rec.chain_code;
      lt_key_chain_name              := l_data_rec.chain_name;
      lt_key_center_code             := l_data_rec.center_code;
      lt_key_center_name             := l_data_rec.center_name;
      lt_key_area_code               := l_data_rec.area_code;
      lt_key_area_name               := l_data_rec.area_name ;
      lt_key_shipped_date            := l_data_rec.shipped_date;
      lt_key_arrival_date            := l_data_rec.arrival_date;
      lt_key_item_code               := l_data_rec.item_code;
      lt_key_item_name               := l_data_rec.item_name;
      lt_key_content                 := l_data_rec.case_in_qty;
      lt_key_reg_sal_cls_name_line   := l_data_rec.regular_sale_class_name_line;
      lt_key_item_div                := l_data_rec.item_div;
      lt_key_item_div_name           := l_data_rec.item_div_name;
      lt_key_location_code           := l_data_rec.location_code;
      lt_key_location_name           := l_data_rec.location_name;
      lt_key_lot                     := l_data_rec.lot;
      lt_key_difference_summary_code := l_data_rec.difference_summary_code;
      lt_key_shipping_sts_name       := l_data_rec.shipping_sts_name;
    END;
--
    --==================================
    --�����e�[�u���Z�b�g
    --==================================
    PROCEDURE set_internal_table
    IS
    BEGIN
      -- ���R�[�hID�̎擾
      BEGIN
        SELECT
          xxcos_rep_l_pick_chain_pro_s01.NEXTVAL          record_id
        INTO
          ln_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx := ln_idx + 1;
      --
      g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;
      g_rpt_data_tab(ln_idx).base_code                    := lt_key_base_code;
      g_rpt_data_tab(ln_idx).base_name                    := lt_key_base_name;
      g_rpt_data_tab(ln_idx).whse_code                    := lt_key_whse_code;
      g_rpt_data_tab(ln_idx).whse_name                    := lt_key_whse_name;
      g_rpt_data_tab(ln_idx).chain_code                   := lt_key_chain_code;
      g_rpt_data_tab(ln_idx).chain_name                   := lt_key_chain_name;
--  Add Ver1.1 S.Yamashita Start
      g_rpt_data_tab(ln_idx).customer_code                := gv_login_customer_code;
      g_rpt_data_tab(ln_idx).customer_name                := gv_login_customer_name;
--  Add Ver1.1 S.Yamashita End
      g_rpt_data_tab(ln_idx).center_code                  := lt_key_center_code;
      g_rpt_data_tab(ln_idx).center_name                  := lt_key_center_name;
      g_rpt_data_tab(ln_idx).area_code                    := lt_key_area_code;
      g_rpt_data_tab(ln_idx).area_name                    := lt_key_area_name;
      g_rpt_data_tab(ln_idx).shipped_date                 := lt_key_shipped_date;
      g_rpt_data_tab(ln_idx).arrival_date                 := lt_key_arrival_date;
      g_rpt_data_tab(ln_idx).item_code                    := lt_key_item_code;
      g_rpt_data_tab(ln_idx).item_name                    := lt_key_item_name;
      g_rpt_data_tab(ln_idx).content                      := lt_key_content;
      g_rpt_data_tab(ln_idx).case_num                     := ln_case_qty;
      g_rpt_data_tab(ln_idx).indivi                       := ln_singly_qty;
      g_rpt_data_tab(ln_idx).quantity                     := ln_summary_qty;
      g_rpt_data_tab(ln_idx).regular_sale_class_head      := gt_bargain_class_name;
      g_rpt_data_tab(ln_idx).regular_sale_class_line      := lt_key_reg_sal_cls_name_line;
      g_rpt_data_tab(ln_idx).edi_received_date            := gd_edi_received_date;
      g_rpt_data_tab(ln_idx).item_class                   := lt_key_item_div;
      g_rpt_data_tab(ln_idx).item_class_name              := lt_key_item_div_name;
      g_rpt_data_tab(ln_idx).location_code                := lt_key_location_code;
      g_rpt_data_tab(ln_idx).location_name                := lt_key_location_name;
      g_rpt_data_tab(ln_idx).lot                          := lt_key_lot;
      g_rpt_data_tab(ln_idx).difference_summary_code      := lt_key_difference_summary_code;
      g_rpt_data_tab(ln_idx).shipping_status              := lt_key_shipping_sts_name;
      g_rpt_data_tab(ln_idx).order_number                 := gv_order_number;
      g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
      g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
      g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
      g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
      g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
      g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
      g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
      g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
      g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
    END;
--
    --==================================
    --���ʏW�v
    --==================================
    PROCEDURE add_quantity
    IS
    BEGIN
      --�W�v
      ln_case_qty    := ln_case_qty    + l_data_rec.case_qty;
      ln_singly_qty  := ln_singly_qty  + l_data_rec.singly_qty;
      ln_summary_qty := ln_summary_qty + l_data_rec.summary_qty;
    END;
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
    -- 0.���ڏ�����
    --==================================
    ln_idx         := 0;
    ln_case_qty    := 0;
    ln_singly_qty  := 0;
    ln_summary_qty := 0;
    --
    lt_key_base_code               := NULL;                 --���_�R�[�h
    lt_key_base_name               := NULL;                 --���_����
    lt_key_whse_code               := NULL;                 --�q��
    lt_key_whse_name               := NULL;                 --�q�ɖ�
    lt_key_chain_code              := NULL;                 --�`�F�[���X�R�[�h
    lt_key_chain_name              := NULL;                 --�`�F�[���X��
    lt_key_center_code             := NULL;                 --�Z���^�[�R�[�h
    lt_key_center_name             := NULL;                 --�Z���^�[��
    lt_key_area_code               := NULL;                 --�n��R�[�h
    lt_key_area_name               := NULL;                 --�n�於
    lt_key_shipped_date            := NULL;                 --�o�ד�
    lt_key_arrival_date            := NULL;                 --����
    lt_key_item_code               := NULL;                 --���i�R�[�h
    lt_key_item_name               := NULL;                 --���i��
    lt_key_content                 := NULL;                 --����
    lt_key_reg_sal_cls_name_line   := NULL;                 --��ԓ����敪
    lt_key_item_div                := NULL;                 --���i�敪
    lt_key_item_div_name           := NULL;                 --���i�敪��
    lt_key_location_code           := NULL;                 --���P�[�V�����R�[�h
    lt_key_location_name           := NULL;                 --���P�[�V������
    lt_key_lot                     := NULL;                 --�ܖ�����
    lt_key_difference_summary_code := NULL;                 --�ŗL�L��
    lt_key_shipping_sts_name       := NULL;                 --�o�׏��X�e�[�^�X
--
    --==================================
    -- 1.�f�[�^�擾
    --==================================
    <<loop_get_data>>
    FOR l_get_data_rec IN data_cur
    LOOP
      l_data_rec := l_get_data_rec;
      IF ( (  lt_key_base_code               IS NULL )      --���_�R�[�h
        AND ( lt_key_base_name               IS NULL )      --���_����
        AND ( lt_key_whse_code               IS NULL )      --�q��
        AND ( lt_key_whse_name               IS NULL )      --�q�ɖ�
        AND ( lt_key_chain_code              IS NULL )      --�`�F�[���X�R�[�h
        AND ( lt_key_chain_name              IS NULL )      --�`�F�[���X��
        AND ( lt_key_center_code             IS NULL )      --�Z���^�[�R�[�h
        AND ( lt_key_center_name             IS NULL )      --�Z���^�[��
        AND ( lt_key_area_code               IS NULL )      --�n��R�[�h
        AND ( lt_key_area_name               IS NULL )      --�n�於
        AND ( lt_key_shipped_date            IS NULL )      --�o�ד�
        AND ( lt_key_arrival_date            IS NULL )      --����
        AND ( lt_key_item_code               IS NULL )      --���i�R�[�h
        AND ( lt_key_item_name               IS NULL )      --���i��
        AND ( lt_key_content                 IS NULL )      --����
        AND ( lt_key_reg_sal_cls_name_line   IS NULL )      --��ԓ����敪
        AND ( lt_key_item_div                IS NULL )      --���i�敪
        AND ( lt_key_item_div_name           IS NULL )      --���i�敪��
        AND ( lt_key_location_code           IS NULL )      --���P�[�V�����R�[�h
        AND ( lt_key_location_name           IS NULL )      --���P�[�V������
        AND ( lt_key_lot                     IS NULL )      --�ܖ�����
        AND ( lt_key_difference_summary_code IS NULL )      --�ŗL�L��
        AND ( lt_key_shipping_sts_name       IS NULL ) )    --�o�׏��X�e�[�^�X
      THEN
        --�L�[�u���C�N���ڃZ�b�g
        set_key_item;
        --���ʏW�v
        add_quantity;
      ELSE
        IF ( (  comp_char(lt_key_base_code               , l_data_rec.base_code))               --���_�R�[�h
          AND ( comp_char(lt_key_base_name               , l_data_rec.base_name))               --���_����
          AND ( comp_char(lt_key_whse_code               , l_data_rec.whse_code))               --�q��
          AND ( comp_char(lt_key_whse_name               , l_data_rec.whse_name))               --�q�ɖ�
          AND ( comp_char(lt_key_chain_code              , l_data_rec.chain_code))              --�`�F�[���X�R�[�h
          AND ( comp_char(lt_key_chain_name              , l_data_rec.chain_name))              --�`�F�[���X��
          AND ( comp_char(lt_key_center_code             , l_data_rec.center_code))             --�Z���^�[�R�[�h
          AND ( comp_char(lt_key_center_name             , l_data_rec.center_name))             --�Z���^�[��
          AND ( comp_char(lt_key_area_code               , l_data_rec.area_code))               --�n��R�[�h
          AND ( comp_char(lt_key_area_name               , l_data_rec.area_name))               --�n�於
          AND ( comp_date(lt_key_shipped_date            , l_data_rec.shipped_date))            --�o�ד�
          AND ( comp_date(lt_key_arrival_date            , l_data_rec.arrival_date))            --����
          AND ( comp_char(lt_key_item_code               , l_data_rec.item_code))               --���i�R�[�h
          AND ( comp_char(lt_key_item_name               , l_data_rec.item_name))               --���i��
          AND ( comp_num (lt_key_content                 , l_data_rec.case_in_qty))             --����
          AND ( comp_char(lt_key_reg_sal_cls_name_line   , l_data_rec.regular_sale_class_name_line)) --��ԓ����敪
          AND ( comp_char(lt_key_item_div                , l_data_rec.item_div))                --���i�敪
          AND ( comp_char(lt_key_item_div_name           , l_data_rec.item_div_name))           --���i�敪��
          AND ( comp_char(lt_key_location_code           , l_data_rec.location_code))           --���P�[�V�����R�[�h
          AND ( comp_char(lt_key_location_name           , l_data_rec.location_name))           --���P�[�V������
          AND ( comp_char(lt_key_lot                     , l_data_rec.lot))                     --�ܖ�����
          AND ( comp_char(lt_key_difference_summary_code , l_data_rec.difference_summary_code)) --�ŗL�L��
          AND ( comp_char(lt_key_shipping_sts_name       , l_data_rec.shipping_sts_name)))      --�o�׏��X�e�[�^�X
        THEN
          --���ʏW�v
          add_quantity;
        ELSE
          --�����e�[�u���Z�b�g
          set_internal_table;
          --������
          lt_key_content := NULL;
          ln_case_qty    := 0;
          ln_singly_qty  := 0;
          ln_summary_qty := 0;
          --�L�[�u���C�N���ڃZ�b�g
          set_key_item;
          --���Z����
          add_quantity;
        END IF;
--
      END IF;
--
    END LOOP loop_get_data;
--
    --==================================
    -- 2.�L�[�u���C�N���ڂ̃`�F�b�N
    --==================================
    IF ( (  lt_key_base_code               IS NULL )      --���_�R�[�h
      AND ( lt_key_base_name               IS NULL )      --���_����
      AND ( lt_key_whse_code               IS NULL )      --�q��
      AND ( lt_key_whse_name               IS NULL )      --�q�ɖ�
      AND ( lt_key_chain_code              IS NULL )      --�`�F�[���X�R�[�h
      AND ( lt_key_chain_name              IS NULL )      --�`�F�[���X��
      AND ( lt_key_center_code             IS NULL )      --�Z���^�[�R�[�h
      AND ( lt_key_center_name             IS NULL )      --�Z���^�[��
      AND ( lt_key_area_code               IS NULL )      --�n��R�[�h
      AND ( lt_key_area_name               IS NULL )      --�n�於
      AND ( lt_key_shipped_date            IS NULL )      --�o�ד�
      AND ( lt_key_arrival_date            IS NULL )      --����
      AND ( lt_key_item_code               IS NULL )      --���i�R�[�h
      AND ( lt_key_item_name               IS NULL )      --���i��
      AND ( lt_key_content                 IS NULL )      --����
      AND ( lt_key_reg_sal_cls_name_line   IS NULL )      --��ԓ����敪
      AND ( lt_key_item_div                IS NULL )      --���i�敪
      AND ( lt_key_item_div_name           IS NULL )      --���i�敪��
      AND ( lt_key_location_code           IS NULL )      --���P�[�V�����R�[�h
      AND ( lt_key_location_name           IS NULL )      --���P�[�V������
      AND ( lt_key_lot                     IS NULL )      --�ܖ�����
      AND ( lt_key_difference_summary_code IS NULL )      --�ŗL�L��
      AND ( lt_key_shipping_sts_name       IS NULL ) )    --�o�׏��X�e�[�^�X
    THEN
      --����擾�f�[�^�Ȃ�
      NULL;
    ELSE
      --�ŏI�擾���R�[�h�̓����e�[�u���Z�b�g
      set_internal_table;
    END IF;
--
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      NULL;
    ELSE
      --�Ώی���
      gn_target_cnt := g_rpt_data_tab.COUNT;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���o�^(A-4)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- �v���O������
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    --==================================
    -- 1.���[���[�N�e�[�u���o�^����
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT
      INSERT INTO
        xxcos_rep_lot_pick_chain_pro
      VALUES
        g_rpt_data_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- ���팏��
    gn_normal_cnt := g_rpt_data_tab.COUNT;
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      --�e�[�u�����擾
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_insert_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : �r�u�e�N��(A-5)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_svf_api       VARCHAR2(5000);
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
    --==================================
    -- 1.����0���p���b�Z�[�W�擾
    --==================================
    lv_nodata_msg             := xxccp_common_pkg.get_msg(
                                   iv_application          => ct_xxcos_appl_short_name
                                  ,iv_name                 => ct_msg_nodata_err
                                 );
--
    lv_file_name              := cv_file_id ||
                                   TO_CHAR( SYSDATE, cv_fmt_date8 ) ||
                                   TO_CHAR( cn_request_id ) ||
                                   cv_extension_pdf
                                 ;
    --==================================
    -- 2.SVF�N��
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode
     ,ov_errbuf               => lv_errbuf
     ,ov_errmsg               => lv_errmsg
     ,iv_conc_name            => cv_conc_name
     ,iv_file_name            => lv_file_name
     ,iv_file_id              => cv_file_id
     ,iv_output_mode          => cv_output_mode_pdf
     ,iv_frm_file             => cv_frm_file
     ,iv_vrq_file             => cv_vrq_file
     ,iv_org_id               => NULL
     ,iv_user_name            => NULL
     ,iv_resp_name            => NULL
     ,iv_doc_name             => NULL
     ,iv_printer_name         => NULL
     ,iv_request_id           => TO_CHAR( cn_request_id )
     ,iv_nodata_msg           => lv_nodata_msg
     ,iv_svf_param1           => NULL
     ,iv_svf_param2           => NULL
     ,iv_svf_param3           => NULL
     ,iv_svf_param4           => NULL
     ,iv_svf_param5           => NULL
     ,iv_svf_param6           => NULL
     ,iv_svf_param7           => NULL
     ,iv_svf_param8           => NULL
     ,iv_svf_param9           => NULL
     ,iv_svf_param10          => NULL
     ,iv_svf_param11          => NULL
     ,iv_svf_param12          => NULL
     ,iv_svf_param13          => NULL
     ,iv_svf_param14          => NULL
     ,iv_svf_param15          => NULL
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_call_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_call_api_expt THEN
      lv_svf_api              := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_svf_api
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_call_api_err
                                  ,iv_token_name1        => cv_tkn_api_name
                                  ,iv_token_value1       => lv_svf_api
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���폜(A-6)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- �v���O������
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT
        xrlpcp.record_id                record_id
      FROM
        xxcos_rep_lot_pick_chain_pro    xrlpcp              --���b�g�ʃs�b�N���X�g_�`�F�[���E���i�ʃg�[�^�����[���[�N�e�[�u��
      WHERE
        xrlpcp.request_id               = cn_request_id     --�v��ID
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.���[���[�N�e�[�u���f�[�^���b�N
    --==================================
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN lock_cur;
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.���[���[�N�e�[�u���폜
    --==================================
    BEGIN
      DELETE FROM
        xxcos_rep_lot_pick_chain_pro    xrlpcp
      WHERE
        xrlpcp.request_id               = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�v��ID������擾
        lv_key_info           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_request
                                  ,iv_token_name1        => cv_tkn_request
                                  ,iv_token_value1       => TO_CHAR( cn_request_id )
                                 );
--
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --�e�[�u�����擾
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_lock_err
                                  ,iv_token_name1        => cv_tkn_table
                                  ,iv_token_value1       => lv_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_delete_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => lv_key_info
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_login_base_code        IN    VARCHAR2         -- 1.���_
   ,iv_login_chain_store_code IN    VARCHAR2         -- 2.�`�F�[���X
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN    VARCHAR2         -- 3.�ڋq
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN    VARCHAR2         -- 4.�����iFrom�j
   ,iv_request_date_to        IN    VARCHAR2         -- 5.�����iTo�j
   ,iv_bargain_class          IN    VARCHAR2         -- 6.��ԓ����敪
   ,iv_edi_received_date      IN    VARCHAR2         -- 7.EDI��M��
   ,iv_shipping_status        IN    VARCHAR2         -- 8.�X�e�[�^�X
   ,iv_order_number           IN    VARCHAR2         -- 9.�󒍔ԍ�
   ,ov_errbuf                 OUT   VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                OUT   VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                 OUT   VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
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
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
--
--###########################  �Œ蕔 END   ####################################
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
      iv_login_base_code        => iv_login_base_code          -- 1.���_
     ,iv_login_chain_store_code => iv_login_chain_store_code   -- 2.�`�F�[���X
--  Add Ver1.1 S.Yamashita Start
     ,iv_login_customer_code    => iv_login_customer_code      -- 3.�ڋq
--  Add Ver1.1 S.Yamashita End
     ,iv_request_date_from      => iv_request_date_from        -- 4.�����iFrom�j
     ,iv_request_date_to        => iv_request_date_to          -- 5.�����iTo�j
     ,iv_bargain_class          => iv_bargain_class            -- 6.��ԓ����敪
     ,iv_edi_received_date      => iv_edi_received_date        -- 7.EDI��M��
     ,iv_shipping_status        => iv_shipping_status          -- 8.�X�e�[�^�X
     ,iv_order_number           => iv_order_number             -- 9.�󒍔ԍ�
     ,ov_errbuf                 => lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                  -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �p�����[�^�`�F�b�N����
    -- ===============================
    check_parameter(
      ov_errbuf                 => lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                  -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  �f�[�^�擾
    -- ===============================
    get_data(
      ov_errbuf                 => lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                  -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  ���[���[�N�e�[�u���o�^
    -- ===============================
    insert_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                  -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-5  �r�u�e�N��
    -- ===============================
    execute_svf(
      ov_errbuf                 => lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                  -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
--
    -- ===============================
    -- A-6  ���[���[�N�e�[�u���폜
    -- ===============================
    delete_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                  -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
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
    errbuf                    OUT     VARCHAR2     --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                   OUT     VARCHAR2     --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_login_base_code        IN      VARCHAR2     -- 1.���_
   ,iv_login_chain_store_code IN      VARCHAR2     -- 2.�`�F�[���X
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN      VARCHAR2     -- 3.�ڋq
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN      VARCHAR2     -- 4.�����iFrom�j
   ,iv_request_date_to        IN      VARCHAR2     -- 5.�����iTo�j
   ,iv_bargain_class          IN      VARCHAR2     -- 6.��ԓ����敪
   ,iv_edi_received_date      IN      VARCHAR2     -- 7.EDI��M��
   ,iv_shipping_status        IN      VARCHAR2     -- 8.�X�e�[�^�X
   ,iv_order_number           IN      VARCHAR2     -- 9.�󒍔ԍ�
  )
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
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
      iv_which    => cv_log_header_log
     ,ov_retcode  => lv_retcode
     ,ov_errbuf   => lv_errbuf
     ,ov_errmsg   => lv_errmsg
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
       iv_login_base_code                  -- 1.���_
      ,iv_login_chain_store_code           -- 2.�`�F�[���X
--  Add Ver1.1 S.Yamashita Start
      ,iv_login_customer_code              -- 3.�ڋq
--  Add Ver1.1 S.Yamashita End
      ,iv_request_date_from                -- 4.�����iFrom�j
      ,iv_request_date_to                  -- 5.�����iTo�j
      ,iv_bargain_class                    -- 6.��ԓ����敪
      ,iv_edi_received_date                -- 7.EDI��M��
      ,iv_shipping_status                  -- 8.�X�e�[�^�X
      ,iv_order_number                     -- 9.�󒍔ԍ�
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      gn_error_cnt := 1;
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
       ,buff    => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
       ,buff    => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG
     ,buff    => NULL
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => gv_out_msg
    );
    --
    --1�s��
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => NULL
    );
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
    fnd_file.put_line(
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
END XXCOS012A05R;
/
