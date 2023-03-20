CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCSO010A08C(body)
 * Description      : ���̋@�ڋq�x���Ǘ����쐬
 * MD.050           : MD050_CSO_010_A08_���̋@�ڋq�x���Ǘ����쐬
 *
 * Version          : 1.0
 *
 * Program List
 * ------------------------  -------------------------------------------------------------
 *  Name                     Description
 * ------------------------ --------------------------------------------------------------
 *  init                     ��������(A-1)
 *  get_plan_cust_pay_mng    ���̋@�ڋq�x���Ǘ����i�\��j�擾(A-2)
 *                           GL�x����p����̋��z�擾(A-3)
 *                           ���̋@�ڋq�x���Ǘ����i���сj�X�V(A-4)
 *  ins_achieve_cust_pay_mng ���̋@�ڋq�x���Ǘ����i���сj�o�^(A-5)
 *  submain                  ���C�������v���V�[�W��
 *  main                     ���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-6)
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2022-07-21    1.0   M.Akachi         �V�K�쐬 E_�{�ғ�_18060�i���т̌��ʈ��Ή��j
 *
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
  --
  --################################  �Œ蕔 END   ##################################
  --
  --#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
  --
  gv_out_msg           VARCHAR2(2000) DEFAULT NULL;
  gn_cust_pay_mng_target_cnt NUMBER   := 0; -- �Ώی���(���̋@�ڋq�x���Ǘ����쐬)
  gn_cust_pay_mng_normal_cnt NUMBER   := 0; -- ���팏��(���̋@�ڋq�x���Ǘ����쐬)
  gn_cust_pay_mng_error_cnt  NUMBER   := 0; -- �G���[����(���̋@�ڋq�x���Ǘ����쐬)
  --
  --################################  �Œ蕔 END   ##################################
  --
  --##########################  �Œ苤�ʗ�O�錾�� START  ###########################
  --
  --*** ���������ʗ�O ***
  global_process_expt EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt EXCEPTION;
  --
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO010A08C';                      -- �p�b�P�[�W��
  cv_sales_appl_short_name  CONSTANT VARCHAR2(5)   := 'XXCSO';                             -- �c�Ɨp�A�v���P�[�V�����Z�k��
  cn_number_zero            CONSTANT NUMBER        := 0;
  cn_number_one             CONSTANT NUMBER        := 1;
  cv_flag_yes               CONSTANT VARCHAR2(1)   := 'Y';                                 -- �t���OY
  cv_flag_off               CONSTANT VARCHAR2(1)   := '0';                                 -- �t���OOFF
  cv_flag_on                CONSTANT VARCHAR2(1)   := '1';                                 -- �t���OON
  cv_date_format1           CONSTANT VARCHAR2(21)  := 'YYYY/MM';                           -- ���t�t�H�[�}�b�g
  cv_month_format           CONSTANT VARCHAR2(21)  := 'MM';                                -- ���t�t�H�[�}�b�g�i���j
  cv_acct_code_type         CONSTANT fnd_lookup_values_vl.lookup_type%TYPE        := 'XXCSO1_ACCT_CODE';  -- ���̋@�ڋq�x���Ǘ��̊���Ȗ�
  cv_send_flag_0            CONSTANT xxcso_cust_pay_mng.send_flag%TYPE            := '0';  -- ���M�Ώ�
  cv_send_flag_1            CONSTANT xxcso_cust_pay_mng.send_flag%TYPE            := '1';  -- ���M�ΏۊO
  cv_actual_kbn_plan        CONSTANT xxcso_cust_pay_mng.plan_actual_kbn%TYPE      := '1';  -- �\��
  cv_actual_kbn_actual      CONSTANT xxcso_cust_pay_mng.plan_actual_kbn%TYPE      := '2';  -- ����
  --
  -- ���b�Z�[�W�R�[�h
  cv_msg_cso_00011          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011'; -- �Ɩ��������t�擾�G���[
  cv_msg_cso_00014          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014'; -- �v���t�@�C���擾�G���[ 
  cv_msg_cso_00921          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00921'; -- �f�[�^�X�V�G���[
  cv_msg_cso_00173          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173'; -- �Q�ƃ^�C�v�Ȃ��G���[���b�Z�[�W
  cv_msg_cso_00922          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00922'; -- �f�[�^�o�^�G���[
  cv_msg_cso_00505          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00505'; -- �Ώی������b�Z�[�W
  cv_msg_cso_00506          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00506'; -- �����������b�Z�[�W
  cv_msg_cso_00507          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00507'; -- �G���[�������b�Z�[�W
  --
  -- �g�[�N���R�[�h
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_task_name          CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_lookup_type_name   CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_proc_name          CONSTANT VARCHAR2(20) := 'PROC_NAME';
  cv_tkn_error_message      CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_count              CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_account_number     CONSTANT VARCHAR2(20) := 'ACCOUNT_NUMBER';
  cv_tkn_plan_actual_kbn    CONSTANT VARCHAR2(20) := 'PLAN_ACTUAL_KBN';
  cv_tkn_data_kbn           CONSTANT VARCHAR2(20) := 'DATA_KBN';
  cv_tkn_pay_start_date     CONSTANT VARCHAR2(20) := 'PAY_START_DATE';
  cv_tkn_pay_end_date       CONSTANT VARCHAR2(20) := 'PAY_END_DATE';
  cv_tkn_send_flag          CONSTANT VARCHAR2(20) := 'SEND_FLAG';
  --
  --�v���t�@�C��
  cv_set_of_bks_id          CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';  -- ��v����ID
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date              DATE     DEFAULT NULL;   -- �Ɩ����t
  gn_set_of_bks_id          NUMBER   DEFAULT NULL;   -- ��v����ID
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_token_value  VARCHAR2(100)  DEFAULT NULL; -- �g�[�N����
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    --
    --===============================
    --���[�J����O
    --===============================
    profile_expt  EXCEPTION;  -- �v���t�@�C���擾�G���[
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ======================
    -- �Ɩ����t�`�F�b�N
    -- ======================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    --
    IF (gd_proc_date IS NULL) THEN
      -- �Ɩ����t�������͂̏ꍇ�G���[
      lv_errbuf := xxccp_common_pkg.get_msg(
                    iv_application => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                    ,iv_name        => cv_msg_cso_00011          -- ���b�Z�[�W�R�[�h
                    );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    --==============================================================
    --�v���t�@�C�����擾
    --==============================================================
    gn_set_of_bks_id  := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id )); -- ��v����ID
    --
    IF( gn_set_of_bks_id IS NULL ) THEN
      lv_token_value := TO_CHAR( cv_set_of_bks_id );
      RAISE profile_expt;
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
        -- *** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      cv_sales_appl_short_name
                    , cv_msg_cso_00014
                    , cv_tkn_profile
                    , lv_token_value
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END init;
  --
  /**********************************************************************************
   * Procedure Name   : ins_achieve_cust_pay_mng
   * Description      : ���̋@�ڋq�x���Ǘ����i���сj�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE ins_achieve_cust_pay_mng(
     iv_account_number         IN         xxcso_cust_pay_mng.account_number%TYPE          -- �ڋq�R�[�h
    ,iv_data_kbn               IN         xxcso_cust_pay_mng.data_kbn%TYPE                -- �f�[�^�敪
    ,iv_plan_actual_kbn        IN         xxcso_cust_pay_mng.plan_actual_kbn%TYPE         -- �\���敪��
    ,id_pay_start_date         IN         xxcso_cust_pay_mng.pay_start_date%TYPE          -- �x�����ԊJ�n��
    ,id_pay_end_date           IN         xxcso_cust_pay_mng.pay_end_date%TYPE            -- �x�����ԏI����
    ,in_total_amt              IN         xxcso_cust_pay_mng.total_amt%TYPE               -- �Ŕ������z
    ,iv_contract_number        IN         xxcso_cust_pay_mng.contract_number%TYPE         -- �_�񏑔ԍ�
    ,iv_base_code              IN         xxcso_cust_pay_mng.base_code%TYPE               -- ���_�R�[�h
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                        -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT    VARCHAR2(100) := 'ins_achieve_cust_pay_mng'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- �g�[�N���p�萔
    cv_tkn_value_acct           CONSTANT VARCHAR2(50)  := '����Ȗڂ�';
    cv_tkn_value_sub_acct       CONSTANT VARCHAR2(50)  := '�⏕�Ȗڂ�';
    --
    cv_date_format              CONSTANT VARCHAR2(21)  := 'YYYYMMDD';     -- ���t�t�H�[�}�b�g
    cv_first_day                CONSTANT VARCHAR2(2)   := '01';           -- ����
    -- *** ���[�J���E���R�[�h ***
--
--    -- *** ���[�J���ϐ� ***
    ln_crt_data_cnt        NUMBER;                                 -- �o�^���R�[�h��
    ln_loop_cnt            NUMBER;                                 -- ���[�v�J�E���g��
    ln_payment_amt         xxcso_cust_pay_mng.payment_amt%TYPE;    -- �����z
    ln_first_payment_amt   xxcso_cust_pay_mng.payment_amt%TYPE;    -- �����z�i�����j
    ln_set_payment_amt     xxcso_cust_pay_mng.payment_amt%TYPE;    -- �����z�i�C���T�[�g�p�j
    lv_payment_date        xxcso_cust_pay_mng.payment_date%TYPE;   -- �N��
    lv_acct_code           xxcso_cust_pay_mng.acct_code%TYPE;      -- ����Ȗ�
    lv_sub_acct_code       xxcso_cust_pay_mng.sub_acct_code%TYPE;  -- �⏕�Ȗ�
    lv_acct_name           xxcso_cust_pay_mng.acct_name%TYPE;      -- ����Ȗږ�
    lv_sub_acct_name       xxcso_cust_pay_mng.sub_acct_name%TYPE;  -- �⏕�Ȗږ�
    ld_acct_day            DATE;                                   -- ����Ȗڔ����
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �ϐ��̏�����
    ln_crt_data_cnt       := 0;
    ln_loop_cnt           := 0;
    ln_payment_amt        := 0;
    ln_first_payment_amt  := 0;
    ln_set_payment_amt    := 0;
    --
    -- �쐬���R�[�h���擾
    ln_crt_data_cnt := MONTHS_BETWEEN( TRUNC( id_pay_end_date, cv_month_format ), TRUNC( id_pay_start_date, cv_month_format ) ) + 1;
    --
    -- ���z��0�ȊO�̏ꍇ�Ɉ�����
    IF ( in_total_amt = 0 ) THEN
      ln_payment_amt       := 0;
      ln_first_payment_amt := 0;
    ELSE
      -- �����z�̎Z�o
      ln_payment_amt := ROUND( in_total_amt / ln_crt_data_cnt );
      --
      -- �����z�i�����j�̎Z�o
      -- �����z�i�����j�������z�i�����j�{�iGL�x����p���� - �����z���v�j
      ln_first_payment_amt := ln_payment_amt + ( in_total_amt - ( ln_payment_amt * ln_crt_data_cnt ));
      --
    END IF;
    -- ======================================
    -- ���̋@�ڋq�x���Ǘ����e�[�u���쐬����
    -- ======================================
    <<cust_pay_mng_loop>>
    FOR j IN 1..ln_crt_data_cnt LOOP
      -- �ϐ��̏�����
      lv_payment_date       := NULL;
      lv_acct_code          := NULL;
      lv_sub_acct_code      := NULL;
      lv_acct_name          := NULL;
      lv_sub_acct_name      := NULL;
      --
      -- �N���̕ҏW
      lv_payment_date := SUBSTRB( TO_CHAR( ADD_MONTHS( id_pay_start_date, ln_loop_cnt ), cv_date_format ), 1,6 );
      --
      -- ����Ȗڎ擾
      -- ����Ȗڔ�����ݒ�
      ld_acct_day := TO_DATE( lv_payment_date || cv_first_day, cv_date_format );
      --
      BEGIN
        SELECT  flvv.attribute2                 acct_code,      -- ����Ȗ�
                flvv.attribute3                 sub_acct_code,  -- �⏕�Ȗ�
                xaav.aff_account_name           acct_name,      -- ����Ȗږ�
                xasav.aff_sub_account_name      sub_acct_name   -- �⏕�Ȗږ�
        INTO    lv_acct_code,
                lv_sub_acct_code,
                lv_acct_name,
                lv_sub_acct_name
        FROM    fnd_lookup_values_vl flvv,                      -- �Q�ƃ^�C�v�e�[�u��
                xxcff_aff_account_v  xaav,                      -- �Ȗڃ}�X�^
                xxcff_aff_sub_account_v xasav                   -- �⏕�Ȗڃ}�X�^
        WHERE   flvv.lookup_type          =  cv_acct_code_type
        AND     flvv.attribute1           =  iv_data_kbn
        AND     flvv.enabled_flag         =  cv_flag_yes
        AND     flvv.start_date_active    <= ld_acct_day        -- �J�n��
        AND     (flvv.end_date_active     IS NULL               -- �I����
                  OR flvv.end_date_active >=  ld_acct_day       -- �I����
                )
        AND     flvv.attribute2           = xaav.aff_account_code
        AND     flvv.attribute2           = xasav.aff_account_name
        AND     flvv.attribute3           = xasav.aff_sub_account_code;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00173         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_value_acct        -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_acct_code_type        -- �g�[�N���l2
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- �����z���Z�b�g
      IF ( ln_loop_cnt = 0 ) THEN
        ln_set_payment_amt := ln_first_payment_amt;
      ELSE
        ln_set_payment_amt := ln_payment_amt;
      END IF;
      --
      BEGIN
        -- ���̋@�ڋq�x���Ǘ����e�[�u���쐬����
        INSERT INTO xxcso_cust_pay_mng(
                       cust_pay_mng_id                                 -- �ڋq�x���Ǘ�ID
                      ,account_number                                  -- �ڋq�R�[�h
                      ,payment_date                                    -- �N��
                      ,plan_actual_kbn                                 -- �\���敪��
                      ,acct_code                                       -- ����Ȗ�
                      ,acct_name                                       -- ����Ȗږ�
                      ,sub_acct_code                                   -- �⏕�Ȗ�
                      ,sub_acct_name                                   -- �⏕�Ȗږ�
                      ,payment_amt                                     -- ���z
                      ,data_kbn                                        -- �f�[�^�敪
                      ,pay_start_date                                  -- �x�����ԊJ�n��
                      ,pay_end_date                                    -- �x�����ԏI����
                      ,total_amt                                       -- �Ŕ������z
                      ,send_flag                                       -- ���M�t���O
                      ,contract_number                                 -- �_�񏑔ԍ�
                      ,created_by                                      -- �쐬��
                      ,creation_date                                   -- �쐬��
                      ,last_updated_by                                 -- �ŏI�X�V��
                      ,last_update_date                                -- �ŏI�X�V��
                      ,last_update_login                               -- �ŏI�X�V���O�C��
                      ,request_id                                      -- �v��ID
                      ,program_application_id                          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                      ,program_id                                      -- �R���J�����g�E�v���O����ID
                      ,program_update_date                             -- �v���O�����X�V��
                      ,base_code                                       -- ���_�R�[�h
                    )
           VALUES (
                       xxcso_cust_pay_mng_s01.NEXTVAL                  -- �ڋq�x���Ǘ�ID
                      ,iv_account_number                               -- �ڋq�R�[�h
                      ,lv_payment_date                                 -- �N��
                      ,iv_plan_actual_kbn                              -- �\���敪��
                      ,lv_acct_code                                    -- ����Ȗ�
                      ,lv_acct_name                                    -- ����Ȗږ�
                      ,lv_sub_acct_code                                -- �⏕�Ȗ�
                      ,lv_sub_acct_name                                -- �⏕�Ȗږ�
                      ,ln_set_payment_amt                              -- ���z
                      ,iv_data_kbn                                     -- �f�[�^�敪
                      ,id_pay_start_date                               -- �x�����ԊJ�n��
                      ,id_pay_end_date                                 -- �x�����ԏI����
                      ,in_total_amt                                    -- �Ŕ������z
                      ,cv_send_flag_0                                  -- ���M�Ώ�
                      ,iv_contract_number                              -- �_�񏑔ԍ�
                      ,cn_created_by                                   -- �쐬��
                      ,cd_creation_date                                -- �쐬��
                      ,cn_last_updated_by                              -- �ŏI�X�V��
                      ,cd_last_update_date                             -- �ŏI�X�V��
                      ,cn_last_update_login                            -- �ŏI�X�V���O�C��
                      ,cn_request_id                                   -- �v��ID
                      ,cn_program_application_id                       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                      ,cn_program_id                                   -- �R���J�����g�E�v���O����ID
                      ,cd_program_update_date                          -- �v���O�����X�V��
                      ,iv_base_code
                 );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name                    -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00922                            -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_account_number                       -- �g�[�N���R�[�h1
                         ,iv_token_value1 => iv_account_number                           -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_plan_actual_kbn                      -- �g�[�N���R�[�h2
                         ,iv_token_value2 => iv_plan_actual_kbn                          -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_data_kbn                             -- �g�[�N���R�[�h3
                         ,iv_token_value3 => iv_data_kbn                                 -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_pay_start_date                       -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(id_pay_start_date, cv_date_format1)  -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_pay_end_date                         -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(id_pay_end_date, cv_date_format1)    -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_send_flag                            -- �g�[�N���R�[�h6
                         ,iv_token_value6 => cv_send_flag_0                              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_error_message                        -- �g�[�N���R�[�h7
                         ,iv_token_value7 => SQLERRM                                     -- �g�[�N���l7
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- �J�E���g�A�b�v
      ln_loop_cnt := ln_loop_cnt + 1;
    END LOOP cust_pay_mng_loop;
    --
    --�o�^�Ώی���
    gn_cust_pay_mng_normal_cnt := gn_cust_pay_mng_normal_cnt + cn_number_one;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END ins_achieve_cust_pay_mng;
  --
   /**********************************************************************************
   * Procedure Name   : get_plan_cust_pay_mng
   * Description      : ���̋@�ڋq�x���Ǘ����i�\��j�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_plan_cust_pay_mng(
     ov_errbuf                 OUT NOCOPY VARCHAR2                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                        -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_plan_cust_pay_mng'; -- �v���O������
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ���̋@�ڋq�x���Ǘ����(�\��)
    CURSOR plan_cust_pay_mng_cur
    IS
      SELECT
      DISTINCT
       xcpm.account_number   AS account_number  -- �ڋq�R�[�h
      ,xcpm.data_kbn         AS data_kbn        -- �f�[�^�敪 (1�F�ݒu���^���A2�F�s�����Y�g�p��)
      ,xcpm.pay_start_date   AS pay_start_date  -- �x�����ԊJ�n��
      ,xcpm.pay_end_date     AS pay_end_date    -- �x�����ԏI����
      ,xcpm.contract_number  AS contract_number -- �_�񏑔ԍ�
      FROM xxcso_cust_pay_mng xcpm              -- ���̋@�ڋq�x���Ǘ����e�[�u��
      WHERE
      xcpm.plan_actual_kbn = cv_actual_kbn_plan -- �\���敪(1�F�\��)
      AND xcpm.send_flag   = cv_send_flag_0     -- ���M�t���O(0�F���M�Ώ�)
      AND TO_DATE�ixcpm.payment_date, cv_date_format1�j
            BETWEEN  TO_DATE(TO_CHAR(ADD_MONTHS(gd_proc_date,-1),cv_date_format1),cv_date_format1) 
                 AND TO_DATE(TO_CHAR(gd_proc_date,cv_date_format1),cv_date_format1)
      ;
--
    -- *** ���[�J���ϐ� ***
    ln_actual_gl_total_amt gl_balances.period_net_dr%TYPE;           -- GL�Ŕ������z(����)
    ln_actual_total_amt    xxcso_cust_pay_mng.total_amt%TYPE;        -- �Ŕ������z(����)
    lv_base_code           xxcso_cust_pay_mng.base_code%TYPE;        -- ���_�R�[�h
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �ϐ��̏�����
    ln_actual_gl_total_amt := NULL;
    ln_actual_total_amt := NULL;
    lv_base_code := NULL;
    --
    -- ���̋@�ڋq�x���Ǘ����(�\��)
    <<plan_cust_pay_mng_loop>>
    FOR lt_plan_cust_pay_mng_rec IN plan_cust_pay_mng_cur LOOP
      -- ��������
      gn_cust_pay_mng_target_cnt := gn_cust_pay_mng_target_cnt + cn_number_one;
      --
      -- ==============================
      -- A-3.GL�x����p����̋��z�擾
      -- ==============================
      BEGIN
        SELECT
           xca.sale_base_code                                             -- ���㋒�_�R�[�h
          ,SUM(NVL(gb.period_net_dr,0)) - SUM(NVL(gb.period_net_cr,0))    -- �ؕ����z - �ݕ����z
        INTO
           lv_base_code
          ,ln_actual_gl_total_amt
        FROM    gl_balances gb
               ,gl_code_combinations gcc
               ,gl_periods glp
               ,xxcmm_cust_accounts xca
        WHERE  gb.set_of_books_id       = gn_set_of_bks_id
        AND    gb.currency_code         = 'JPY'
        AND    gb.actual_flag           = 'A'
        AND    gb.code_combination_id   = gcc.code_combination_id
        AND    glp.period_name          = gb.period_name
        AND    glp.period_set_name      = 'SALES_CALENDAR'
        AND    glp.start_date BETWEEN TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_start_date,cv_date_format1),cv_date_format1)
                                      AND LAST_DAY(TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_end_date,cv_date_format1),cv_date_format1))
        AND    glp.end_date   BETWEEN TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_start_date,cv_date_format1),cv_date_format1) 
                                      AND LAST_DAY(TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_end_date,cv_date_format1),cv_date_format1))
        AND    gcc.segment1 = '001'                                                                            -- 001:�ɓ����i�Œ�j
        AND    (gcc.segment3,gcc.segment4) IN (SELECT  flvv.attribute2           AS acct_code                                 -- ����Ȗ�
                                                      ,flvv.attribute3           AS sub_acct_code                             -- �⏕�Ȗ�
                                               FROM    fnd_lookup_values_vl flvv                                              -- �Q�ƃ^�C�v�e�[�u��
                                               WHERE   flvv.lookup_type          =  cv_acct_code_type
                                               AND     flvv.attribute1           =  lt_plan_cust_pay_mng_rec.data_kbn
                                               AND     flvv.enabled_flag         =  cv_flag_yes
                                               AND     flvv.start_date_active    <= lt_plan_cust_pay_mng_rec.pay_end_date     -- �J�n��
                                               AND     (flvv.end_date_active     IS NULL                                      -- �I����
                                                         OR flvv.end_date_active >=  lt_plan_cust_pay_mng_rec.pay_start_date  -- �I����
                                                       )
                                               )
        AND gcc.segment5 = lt_plan_cust_pay_mng_rec.account_number    -- �ڋq�R�[�h
        AND gcc.segment5 = xca.customer_code(+)
        GROUP BY
        xca.sale_base_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_actual_gl_total_amt := NULL;
      END;
      --
      -- ���̋@�ڋq�x���Ǘ����i���сj�`�F�b�N
      -- GL�x���p����̋��z���擾�ł����ꍇ�A
      -- ���̋@�ڋq�x���Ǘ����e�[�u���Ɏ��уf�[�^�i�\���敪��2�F���сj�����邩�`�F�b�N
      IF ( ln_actual_gl_total_amt IS NOT NULL ) THEN
        BEGIN
          SELECT sum(xcpm.payment_amt)                                        -- ���z
          INTO   ln_actual_total_amt
          FROM  xxcso_cust_pay_mng xcpm                                       -- ���̋@�ڋq�x���Ǘ����e�[�u��
          WHERE xcpm.plan_actual_kbn = cv_actual_kbn_actual                   -- �\���敪(2�F����)
          AND   xcpm.send_flag = cv_send_flag_0                               -- ���M�t���O(0�F���M�Ώ�)
          AND   xcpm.account_number = lt_plan_cust_pay_mng_rec.account_number -- �ڋq�R�[�h
          AND   xcpm.data_kbn       = lt_plan_cust_pay_mng_rec.data_kbn       -- �f�[�^�敪
          AND   xcpm.pay_start_date = lt_plan_cust_pay_mng_rec.pay_start_date -- �x�����ԊJ�n��
          AND   xcpm.pay_end_date   = lt_plan_cust_pay_mng_rec.pay_end_date   -- �x�����ԏI����
          GROUP by 
           xcpm.account_number
          ,xcpm.data_kbn
          ,xcpm.pay_start_date
          ,xcpm.pay_end_date
          ,xcpm.contract_number;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          ln_actual_total_amt := NULL;
        END;
        --
        -- GL�x���p����̋��z�ƐŔ������z(����)���قȂ�ꍇ
        IF ( ln_actual_total_amt IS NOT NULL AND ln_actual_gl_total_amt <> ln_actual_total_amt ) THEN
        -- ���̋@�ڋq�x���Ǘ����i���сj�X�V(A-4)
        -- ���̋@�ڋq�x���Ǘ������эX�V���s��
            BEGIN
              UPDATE xxcso_cust_pay_mng xcpm
              SET    xcpm.send_flag              =  cv_send_flag_1,                              -- ���M�ΏۊO
                     xcpm.last_updated_by        =  cn_last_updated_by,                          -- �ŏI�X�V��
                     xcpm.last_update_date       =  cd_last_update_date,                         -- �ŏI�X�V��
                     xcpm.last_update_login      =  cn_last_update_login,                        -- �ŏI�X�V���O�C��
                     xcpm.request_id             =  cn_request_id,                               -- �v��ID
                     xcpm.program_application_id =  cn_program_application_id,                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                     xcpm.program_id             =  cn_program_id,                               -- �R���J�����g�E�v���O����ID
                     xcpm.program_update_date    =  cd_program_update_date                       -- �v���O�����X�V��
              WHERE  xcpm.plan_actual_kbn        =  cv_actual_kbn_actual                         -- �\���敪(2�F����)
              AND    xcpm.send_flag              =  cv_send_flag_0                               -- ���M�t���O(0�F���M�Ώ�)
              AND    xcpm.account_number         =  lt_plan_cust_pay_mng_rec.account_number      -- �ڋq�R�[�h
              AND    xcpm.data_kbn               =  lt_plan_cust_pay_mng_rec.data_kbn            -- �f�[�^�敪
              AND    xcpm.pay_start_date         =  lt_plan_cust_pay_mng_rec.pay_start_date      -- �x�����ԊJ�n��
              AND    xcpm.pay_end_date           =  lt_plan_cust_pay_mng_rec.pay_end_date        -- �x�����ԏI����
              ;
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name                    -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_msg_cso_00921                            -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_account_number                       -- �g�[�N���R�[�h1
                               ,iv_token_value1 => lt_plan_cust_pay_mng_rec.account_number     -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_plan_actual_kbn                      -- �g�[�N���R�[�h2
                               ,iv_token_value2 => cv_actual_kbn_actual                        -- �g�[�N���l2
                               ,iv_token_name3  => cv_tkn_data_kbn                             -- �g�[�N���R�[�h3
                               ,iv_token_value3 => lt_plan_cust_pay_mng_rec.data_kbn           -- �g�[�N���l3
                               ,iv_token_name4  => cv_tkn_pay_start_date                       -- �g�[�N���R�[�h4
                               ,iv_token_value4 => TO_CHAR(lt_plan_cust_pay_mng_rec.pay_start_date, cv_date_format1)  -- �g�[�N���l4
                               ,iv_token_name5  => cv_tkn_pay_end_date                                               -- �g�[�N���R�[�h5
                               ,iv_token_value5 => TO_CHAR(lt_plan_cust_pay_mng_rec.pay_end_date, cv_date_format1)    -- �g�[�N���l5
                               ,iv_token_name6  => cv_tkn_send_flag                            -- �g�[�N���R�[�h6
                               ,iv_token_value6 => cv_send_flag_0                              -- �g�[�N���l6
                               ,iv_token_name7  => cv_tkn_error_message                        -- �g�[�N���R�[�h7
                               ,iv_token_value7 => SQLERRM                                     -- �g�[�N���l7
                            );
                --
                RAISE global_api_expt;
                --
            END;
           -- ���̋@�ڋq�x���Ǘ������ѓo�^���s���B
           -- =======================================
           -- A-5.���̋@�ڋq�x���Ǘ����i���сj�o�^
           -- =======================================
           ins_achieve_cust_pay_mng(
              iv_account_number         => lt_plan_cust_pay_mng_rec.account_number           -- �ڋq�R�[�h
             ,iv_data_kbn               => lt_plan_cust_pay_mng_rec.data_kbn                 -- �f�[�^�敪
             ,iv_plan_actual_kbn        => cv_actual_kbn_actual                              -- �\���敪���i���сj
             ,id_pay_start_date         => lt_plan_cust_pay_mng_rec.pay_start_date           -- �x�����ԊJ�n��
             ,id_pay_end_date           => lt_plan_cust_pay_mng_rec.pay_end_date             -- �x�����ԏI����
             ,in_total_amt              => ln_actual_gl_total_amt                            -- �Ŕ������z
             ,iv_contract_number        => lt_plan_cust_pay_mng_rec.contract_number          -- �_�񏑔ԍ�
             ,iv_base_code              => lv_base_code                                      -- ���_�R�[�h
             ,ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
           );
           IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
                --
           END IF;
        END IF;
        -- �Ŕ������z(����)���擾�ł��Ȃ��ꍇ
        IF ( ln_actual_total_amt IS NULL ) THEN
        -- ���̋@�ڋq�x���Ǘ������ѓo�^���s���B
           -- =======================================
           -- A-5.���̋@�ڋq�x���Ǘ����i���сj�o�^
           -- =======================================
           ins_achieve_cust_pay_mng(
              iv_account_number         => lt_plan_cust_pay_mng_rec.account_number           -- �ڋq�R�[�h
             ,iv_data_kbn               => lt_plan_cust_pay_mng_rec.data_kbn                 -- �f�[�^�敪
             ,iv_plan_actual_kbn        => cv_actual_kbn_actual                              -- �\���敪���i���сj
             ,id_pay_start_date         => lt_plan_cust_pay_mng_rec.pay_start_date           -- �x�����ԊJ�n��
             ,id_pay_end_date           => lt_plan_cust_pay_mng_rec.pay_end_date             -- �x�����ԏI����
             ,in_total_amt              => ln_actual_gl_total_amt                            -- �Ŕ������z
             ,iv_contract_number        => lt_plan_cust_pay_mng_rec.contract_number          -- �_�񏑔ԍ�
             ,iv_base_code              => lv_base_code                                      -- ���_�R�[�h
             ,ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
           );
           IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
                --
           END IF;
        END IF;
      END IF;
      -- 
    END LOOP plan_cust_pay_mng_loop;
    --
  EXCEPTION
    --
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_plan_cust_pay_mng;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ============
    -- A-1.��������
    -- ============
    init(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================================
    -- A-2.���̋@�ڋq�x���Ǘ����i�\��j�擾
    -- ===================================
    get_plan_cust_pay_mng(
       ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    --
    END IF;
    --
    COMMIT;
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W --# �Œ� #
    ,retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h   --# �Œ� #
  )
  --
  --###########################  �Œ蕔 START   ###########################
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
    --
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    --TODO
    cv_tkn_value_cust_pay_mng CONSTANT VARCHAR2(50) := '���̋@�ڋq�x���Ǘ����쐬';
    --
    -- *** ���[�J���ϐ� ***
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
      --
    END IF;
    --
    --###########################  �Œ蕔 END   #############################
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
       -- �G���[�o��
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --�G���[���b�Z�[�W
       );
       --
    END IF;
    --
    -- =======================
    -- A-6.�I������
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    --�G���[�̏ꍇ���A���������A�������N���A�A�G���[�����Œ�
    IF ( lv_retcode = cv_status_error ) THEN
      gn_cust_pay_mng_target_cnt := cn_number_zero;
      gn_cust_pay_mng_normal_cnt := cn_number_zero;
      gn_cust_pay_mng_error_cnt  := cn_number_one;
    END IF;
    --
    -- �Ώی����o��(���̋@�ڋq�x���Ǘ����쐬)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_msg_cso_00505
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_cust_pay_mng
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_cust_pay_mng_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ���������o��(���̋@�ڋq�x���Ǘ����쐬)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_msg_cso_00506
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_cust_pay_mng
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_cust_pay_mng_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �G���[�����o��(���̋@�ڋq�x���Ǘ����쐬)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_msg_cso_00507
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_cust_pay_mng
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_cust_pay_mng_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- �X�e�[�^�X�Z�b�g
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    --
  EXCEPTION
    --
    --###########################  �Œ蕔 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  �Œ蕔 END   #######################################################
  --
END XXCSO010A08C;
/
