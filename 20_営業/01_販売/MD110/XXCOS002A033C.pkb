CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A033C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOS002A033C (body)
 * Description      : �c�Ɛ��ѕ\�W�v(�O�N)
 * MD.050           : �c�Ɛ��ѕ\�W�v(�O�N) MD050_COS_002_A03
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(C-1)
 *  count_delete_inv_py    �����؂�W�v�f�[�^�폜����(C-4)
 *  bus_s_group_sum_sales  �̔����я��W�v(�O�N)����(C-2)
 *  bus_s_group_sum_trans  ���ѐU�֏��W�v(�O�N)����(C-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(C-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/05/10    1.0   S.Niki           main�V�K�쐬
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- *** �v���t�@�C���擾��O�n���h�� ***
  global_get_profile_expt       EXCEPTION;
  -- *** ���b�N�G���[��O�n���h�� ***
  global_data_lock_expt         EXCEPTION;
  -- *** �f�[�^�o�^�G���[��O�n���h�� ***
  global_insert_data_expt       EXCEPTION;
  -- *** �f�[�^�X�V�G���[��O�n���h�� ***
  global_update_data_expt       EXCEPTION;
  -- *** �f�[�^�폜�G���[��O�n���h�� ***
  global_delete_data_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_data_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS002A033C';
  -- �A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE := 'XXCOS';
--
  -- ���̕����b�Z�[�W
  -- �Ɩ����t�擾�G���[
  ct_msg_process_date_err       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014';
  -- �v���t�@�C���擾�G���[
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';
  -- ���b�N�G���[
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';
  -- �f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010';
  -- �f�[�^�X�V�G���[���b�Z�[�W
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';
  -- �f�[�^�폜�G���[���b�Z�[�W
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';
  -- �������`�F�b�N�G���[
  ct_msg_future_date_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00205';
--
  -- ���@�\�ŗL���b�Z�[�W
  -- �c�Ɛ��ѕ\�W�v(�O�N)�p�����[�^�o��
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10594';
  -- XXCOS:�ϓ��d�C���i�ڃR�[�h
  ct_msg_electric_fee_item_cd   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10572';
  -- XXCOS:�c�Ɛ��яW����ۑ�����
  ct_msg_002a03_keeping_period  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10574';
  -- XXCOS:�J�����_�R�[�h
  ct_msg_business_calendar_code CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15054';
  -- �c�Ɛ��ѕ\ ����Q�ʎ��яW�v�i�O�N�j�e�[�u��
  ct_msg_s_group_sum_py_tbl     CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10595';
  -- �̔����я��W�v(�O�N)��������
  ct_msg_count_s_group_sales    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10597';
  -- ���ѐU�֏��W�v(�O�N)��������
  ct_msg_count_s_group_trans    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10598';
  -- �����؂�W�v���i�O�N�j�폜����
  ct_msg_delete_invalidity      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10599';
  -- �Ώ۔N���ғ���
  ct_msg_target_param_note      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10600';
  -- �����ΏۊO���b�Z�[�W
  ct_msg_not_excute             CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15051';
  -- �����ς݃X�L�b�v���b�Z�[�W
  ct_msg_skip_excute            CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15052';
  -- �ꕔ������G���[���b�Z�[�W
  ct_msg_part_comp_err          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15053';
--
  -- ���N�C�b�N�R�[�h
  -- ����敪
  ct_qct_sale_type              CONSTANT  fnd_lookup_types.lookup_type%TYPE  := 'XXCOS1_SALE_CLASS';
--
  -- ��Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1)  := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1)  := 'N';
  -- �����t�w�菑��
  cv_fmt_date                   CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years                  CONSTANT  VARCHAR2(6)  := 'YYYYMM';
--
  -- ���v���t�@�C������
  -- XXCOS:�ϓ��d�C���i�ڃR�[�h
  ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
  -- XXCOS:�c�Ɛ��яW����ۑ�����
  ct_prof_002a03_keeping_period
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_002A03_KEEPING_PERIOD';
  -- XXCOS:�J�����_�R�[�h
  ct_prof_business_calendar_code
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE';
--
  -- ���g�[�N��
  -- �[�i��
  cv_tkn_para_delivery_date     CONSTANT  VARCHAR2(20) := 'PARAM1';
  -- �����敪
  cv_tkn_para_processing_class  CONSTANT  VARCHAR2(20) := 'PARAM2';
  -- �v���t�@�C����
  cv_tkn_profile                CONSTANT  VARCHAR2(20) := 'PROFILE';
  -- �L�[���
  cv_tkn_key_data               CONSTANT  VARCHAR2(20) := 'KEY_DATA';
  -- �e�[�u������
  cv_tkn_table                  CONSTANT  VARCHAR2(20) := 'TABLE';
  -- �e�[�u������
  cv_tkn_table_name             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';
  -- �ۑ�����
  cv_tkn_keeping_period         CONSTANT  VARCHAR2(20) := 'KEEPING_PERIOD';
  -- �폜�Ώ۔N��
  cv_tkn_deletion_object        CONSTANT  VARCHAR2(20) := 'DELETION_OBJECT';
  -- �Ώ۔N��
  cv_tkn_target_month           CONSTANT  VARCHAR2(20) := 'TARGET_MONTH';
  -- �Ώۉғ���
  cv_tkn_target_work_days       CONSTANT  VARCHAR2(20) := 'TARGET_WORK_DAYS';
  -- �쐬��
  cv_tkn_creation_date          CONSTANT  VARCHAR2(20) := 'CREATION_DATE';
  -- �̔����я��i�O�N�j�폜����
  cv_tkn_delete_sales           CONSTANT  VARCHAR2(20) := 'DELETE_SALES';
  -- ���ѐU�֏��i�O�N�j�폜����
  cv_tkn_delete_trans           CONSTANT  VARCHAR2(20) := 'DELETE_TRANS';
--
  -- ���p�����[�^���ʗp
  -- �S��
  cv_para_cls_all               CONSTANT  VARCHAR2(1)  := '0';
  -- �c�ƈ��ʁE����Q�ʔ̔����я��W�v���o�^����(�O�N)
  cv_para_cls_s_group_sum_sales CONSTANT  VARCHAR2(1)  := '1';
  -- �c�ƈ��ʁE����Q�ʎ��ѐU�֏��W�v���o�^����(�O�N)
  cv_para_cls_s_group_sum_trans CONSTANT  VARCHAR2(1)  := '2';
--
  -- ���̔��U�֋敪
  -- �̔�����
  cv_dlv_sales                  CONSTANT  VARCHAR2(1)  := '0';
  -- ���ѐU��
  cv_dlv_trans                  CONSTANT  VARCHAR2(1)  := '1';
--
  -- �����l
  cn_0                          CONSTANT  NUMBER       := 0;
  cn_1                          CONSTANT  NUMBER       := 1;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �Ώۓ��t���i�[���郌�R�[�h
  TYPE g_target_date_rtype IS RECORD(
    target_date                 DATE     -- �Ώۓ��t
  );
  -- �Ώۓ��t���i�[����z��
  TYPE g_target_date_ttype  IS TABLE OF g_target_date_rtype   INDEX BY BINARY_INTEGER;
  gt_target_date_tab        g_target_date_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �Ɩ����t
  gd_process_date               DATE;
  -- �Ώۓ��t
  gd_target_date                DATE;
  -- �Ώ۔N��
  gv_target_month               VARCHAR2(6);
  -- �����؂��N���N��
  gv_invalidity_month           VARCHAR2(6);
  -- ���݉ғ�����
  gn_target_work_days           NUMBER;
  -- �����敪
  gv_processing_class           VARCHAR2(1);
  -- �������s�t���O
  gv_any_time_flag              VARCHAR2(1);
  -- �ꕔ������G���[�t���O
  gv_part_comp_err_flag         VARCHAR2(1);
--
  -- ���v���t�@�C���i�[�p
  -- XXCOS:�ϓ��d�C���i�ڃR�[�h
  gt_prof_electric_fee_item_cd      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCOS:�c�Ɛ��яW����ۑ�����
  gt_prof_002a03_keeping_period     fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCOS:�J�����_�R�[�h
  gt_prof_business_calendar_code    fnd_profile_option_values.profile_option_value%TYPE;
--
  -- ���J�E���g�p
  -- �̔����ѓo�^����
  gn_ins_sales_cnt              NUMBER;
  -- ���ѐU�֓o�^����
  gn_ins_trans_cnt              NUMBER;
  -- �����؂�̔����э폜����
  gn_del_sales_cnt              NUMBER;
  -- �����؂���ѐU�֍폜����
  gn_del_trans_cnt              NUMBER;
--
  --  ===============================
  --  ���[�U�[��`�O���[�o���J�[�\��
  --  ===============================
--
  -- �쐬�ς݃f�[�^���b�N�擾�p
  CURSOR  lock_bus_s_group_sum_cur(
                                   icp_sales_trans_div  VARCHAR2   -- �̔��U�֋敪
                                  )
  IS
    SELECT  /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
            xp.rowid    AS  xp_rowid
    FROM    xxcos_rep_bus_s_group_sum_py  xp
    WHERE   xp.dlv_month            = gv_target_month
    AND     xp.work_days            = gn_target_work_days
    AND     xp.sales_transfer_div   = icp_sales_trans_div
        -- �������s�̏ꍇ�͏�L����
    AND ( ( gv_any_time_flag        = cv_yes )
      OR
        -- ������s�̏ꍇ�́A���s��=�쐬���̏����t�^
        ( ( gv_any_time_flag        = cv_no )
        AND
          ( TRUNC(xp.creation_date) = TRUNC(SYSDATE) ) )
        )
    FOR UPDATE NOWAIT
    ;
--
  -- �����؂��񃍃b�N�擾�p
  CURSOR  lock_count_sum_invalidity_cur(
                                        icp_dlv_month        VARCHAR2   -- �����؂��N��
                                       ,icp_sales_trans_div  VARCHAR2   -- �̔��U�֋敪
                                       )
  IS
    SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
           xp.rowid    AS  xp_rowid
    FROM   xxcos_rep_bus_s_group_sum_py  xp
    WHERE  xp.dlv_month          <=  icp_dlv_month
    AND    xp.sales_transfer_div  =  icp_sales_trans_div
    FOR UPDATE NOWAIT
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(C-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_delivery_date    IN  VARCHAR2,     -- 1.�[�i��
    iv_processing_class IN  VARCHAR2,     -- 2.�����敪
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_process_date             DATE;            -- ���ݓ��t
    lv_process_month            VARCHAR2(6);     -- ���ݔN��
    --�p�����[�^�o�͗p
    lv_para_msg                 VARCHAR2(5000);
    lv_profile_name             VARCHAR2(5000);
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    --==================================
    -- 1.���̓p�����[�^�o��
    --==================================
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_para_delivery_date,
      iv_token_value1  =>  iv_delivery_date,
      iv_token_name2   =>  cv_tkn_para_processing_class,
      iv_token_value2  =>  iv_processing_class
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ���b�Z�[�W���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    --==================================
    -- 2.�Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- �擾���ʊm�F
    IF ( gd_process_date IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_process_date_err
      );
      lv_errbuf := ov_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 3.�ϐ��Z�b�g
    --==================================
    -- ���ݓ��t
    -- �莞���s�̏ꍇ
    IF ( iv_delivery_date IS NULL) THEN
      -- �Ɩ����t���Z�b�g
      ld_process_date  := gd_process_date;
    -- �������s�̏ꍇ
    ELSE
      -- �p�����[�^.�[�i�����Z�b�g
      ld_process_date  := TO_DATE(iv_delivery_date ,cv_fmt_date);
      -- �������s�t���O��'Y'���Z�b�g
      gv_any_time_flag := cv_yes;
    END IF;
--
    -- ���ݓ��t >= �V�X�e�����t�̏ꍇ�G���[
    IF ( ld_process_date >= TRUNC(SYSDATE) ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_future_date_err
      );
      lv_errbuf := ov_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���ݔN��
    lv_process_month    := TO_CHAR(ld_process_date ,cv_fmt_years);
    -- �Ώۓ��t(�O�N������)���Z�b�g
    gd_target_date      := ADD_MONTHS(ld_process_date, -12);
    -- �Ώ۔N��(�O�N����)���Z�b�g
    gv_target_month     := TO_CHAR(gd_target_date ,cv_fmt_years);
    -- �����敪���Z�b�g
    gv_processing_class := iv_processing_class;
--
    --==================================
    -- 4.�v���t�@�C���擾
    --==================================
    -- (1)�ϓ��d�C���i�ڃR�[�h
    gt_prof_electric_fee_item_cd := FND_PROFILE.VALUE( ct_prof_electric_fee_item_cd );
    --
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_prof_electric_fee_item_cd IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_electric_fee_item_cd
      );
      --
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_electric_fee_item_cd);
      RAISE global_get_profile_expt;
    END IF;
--
    -- (2)�c�Ɛ��яW����ۑ�����
    gt_prof_002a03_keeping_period := FND_PROFILE.VALUE( ct_prof_002a03_keeping_period );
    --
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_prof_002a03_keeping_period IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_002a03_keeping_period
      );
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_002a03_keeping_period);
      RAISE global_get_profile_expt;
    END IF;
--
    -- (3)�J�����_�R�[�h
    gt_prof_business_calendar_code := FND_PROFILE.VALUE( ct_prof_business_calendar_code );
    --
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_prof_business_calendar_code IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_business_calendar_code
      );
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_business_calendar_code);
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 5.���݉ғ������擾
    --==================================
    BEGIN
      SELECT COUNT(1)                AS work_days
      INTO   gn_target_work_days
      FROM   bom_calendar_dates bcd
           ,(SELECT bcd.calendar_date  AS calendar_date
             FROM   bom_calendar_dates bcd
             WHERE  TO_CHAR(bcd.calendar_date ,cv_fmt_years) = lv_process_month               -- ���ݔN��
             AND    bcd.calendar_code                        = gt_prof_business_calendar_code -- �J�����_�R�[�h
             ) cal_work
      WHERE  bcd.calendar_date                        <= cal_work.calendar_date
      AND    TO_CHAR(bcd.calendar_date ,cv_fmt_years)  = lv_process_month                     -- ���ݔN��
      AND    bcd.calendar_code                         = gt_prof_business_calendar_code       -- �J�����_�R�[�h
      AND    bcd.seq_num                               IS NOT NULL
      AND    cal_work.calendar_date                    = ld_process_date                      -- ���ݓ��t
      GROUP BY
             cal_work.calendar_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ��ꍇ�́u�ғ������[���v�Ɣ���
        gn_target_work_days := 0;
    END;
--
    -- �Ώ۔N���ғ������o��
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_target_param_note,
      iv_token_name1   =>  cv_tkn_target_month,
      iv_token_value1  =>  gv_target_month,
      iv_token_name2   =>  cv_tkn_target_work_days,
      iv_token_value2  =>  gn_target_work_days
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ������
    gt_target_date_tab.DELETE;
--
    -- �u�ғ������[���v�ȊO�̏ꍇ�A�Ώۓ��t���擾
    IF ( gn_target_work_days <> 0 ) THEN
      --==================================
      -- 6.�Ώۓ��t�擾
      --==================================
      SELECT cal.calendar_date  AS target_date
      BULK COLLECT INTO gt_target_date_tab
      FROM  (SELECT cal_work.calendar_date1    AS calendar_date
                   ,COUNT(1)                   AS work_days
             FROM   bom_calendar_dates bcd
                   ,(SELECT bcd1.calendar_date AS calendar_date1
                           ,bcd2.calendar_date AS calendar_date2
                     FROM   bom_calendar_dates bcd1
                           ,bom_calendar_dates bcd2
                     WHERE  TO_CHAR(bcd1.calendar_date ,cv_fmt_years) = gv_target_month
                     AND    bcd1.calendar_code                        = gt_prof_business_calendar_code
                     AND    bcd1.next_seq_num                         = bcd2.seq_num
                     AND    bcd2.calendar_code                        = gt_prof_business_calendar_code
                    ) cal_work
             WHERE  bcd.calendar_date                        <= cal_work.calendar_date2
             AND    TO_CHAR(bcd.calendar_date ,cv_fmt_years)  = gv_target_month
             AND    bcd.calendar_code                         = gt_prof_business_calendar_code
             AND    bcd.seq_num                               IS NOT NULL
             GROUP BY
                    cal_work.calendar_date1
                   ,cal_work.calendar_date2
      ) cal
      WHERE  cal.work_days    =   gn_target_work_days
      ORDER BY
             cal.calendar_date
      ;
    END IF;
--
    -- �Ώۓ��t���擾�ł��Ȃ��ꍇ�́u�����ΏۊO�v�Ɣ���
    IF ( gt_target_date_tab.COUNT = 0 ) THEN
      -- �����ΏۊO���b�Z�[�W���o��
      lv_para_msg := xxccp_common_pkg.get_msg(
        iv_application   =>  ct_xxcos_appl_short_name,
        iv_name          =>  ct_msg_not_excute
      );
--
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.OUTPUT
        ,buff   =>  lv_para_msg
      );
    END IF;
--
  EXCEPTION
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_profile_name
      );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN
    -- *** ���ʊ֐���O ***
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
   * Procedure Name   : count_delete_inv_py
   * Description      : �����؂�W�v�f�[�^�폜����(C-4)
   ***********************************************************************************/
  PROCEDURE count_delete_inv_py(
    iv_sales_trans_div    IN  VARCHAR2,        --  1.�̔��U�֋敪
    ov_errbuf             OUT VARCHAR2,        --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,        --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_delete_inv_py'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;   -- �e�[�u����
    ld_invalidity_date                    DATE;                             -- �����؂��N����
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
    --==================================
    -- (1)�����؂��N���Z�o
    --==================================
    -- �����؂��N�����Z�o
    ld_invalidity_date
      := LAST_DAY(ADD_MONTHS(gd_target_date ,TO_NUMBER(gt_prof_002a03_keeping_period) * -1));
--
    -- �����؂��N���Z�o
    gv_invalidity_month := TO_CHAR(ld_invalidity_date, cv_fmt_years);
--
    --==================================
    -- (2)���b�N����
    --==================================
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_count_sum_invalidity_cur (
                                           gv_invalidity_month    -- �����؂��N��
                                          ,iv_sales_trans_div     -- �̔��U�֋敪
                                          );
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_count_sum_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
        );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- (3)�f�[�^�폜
    --==================================
    BEGIN
      DELETE /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
      FROM   xxcos_rep_bus_s_group_sum_py   xp
      WHERE  xp.dlv_month          <=  gv_invalidity_month
      AND    xp.sales_transfer_div  =  iv_sales_trans_div
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_delete_data_err,
          iv_token_name1        => cv_tkn_table_name,
          iv_token_value1       => lt_table_name,
          iv_token_name2        => cv_tkn_key_data,
          iv_token_value2       => NULL
        );
        -- �G���[���e�擾
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    -- �폜�����J�E���g
    IF ( iv_sales_trans_div = cv_dlv_sales ) THEN
      -- �����؂�̔����э폜����
      gn_del_sales_cnt := SQL%ROWCOUNT;
    ELSE
      -- �����؂���ѐU�֍폜����
      gn_del_trans_cnt := SQL%ROWCOUNT;
    END IF;
--
    -- �R�~�b�g
    COMMIT;
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_delete_inv_py;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_sales
   * Description      : �̔����я��W�v(�O�N)����(C-2)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_sales(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_sales'; -- �v���O������
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
    ln_dummy             NUMBER;                            -- �J�E���g�p�_�~�[�ϐ�
    lt_table_name        dba_tab_comments.comments%TYPE;    -- �e�[�u����
    lv_creation_date     VARCHAR2(10);                      -- �쐬��
    lv_skip_msg          VARCHAR2(5000);                    -- �����X�L�b�v���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔����я��(�O�N)�擾�J�[�\��
    CURSOR bus_s_group_sum_sales_cur (
      id_delivery_date DATE
    ) IS
       SELECT
           /*+ USE_NL(xseh xsel iimb) */
           TO_CHAR(xseh.delivery_date ,cv_fmt_years)      AS dlv_month             -- �[�i��
          ,xseh.ship_to_customer_code                     AS customer_code         -- �ڋq�R�[�h
          ,iimb.attribute2                                AS policy_group_code     -- ����Q�R�[�h
          ,SUM(xsel.pure_amount)                          AS sale_amount           -- �{�̋��z
          ,SUM(
               CASE xlvs.attribute3  -- �c�ƌ����Z���Ώ�
                 WHEN cv_yes THEN
                   xsel.business_cost * xsel.standard_qty
                 ELSE
                   cn_0
               END
           )                                              AS business_cost         -- �c�ƌ���
       FROM    xxcos_sales_exp_headers   xseh
              ,xxcos_sales_exp_lines     xsel
              ,xxcos_lookup_values_v     xlvs
              ,ic_item_mst_b             iimb
       WHERE   xseh.delivery_date           =       id_delivery_date
       AND     xseh.sales_exp_header_id     =       xsel.sales_exp_header_id
       AND     xsel.item_code               <>      gt_prof_electric_fee_item_cd   -- �ϓ��d�C��͏���
       AND     xlvs.lookup_type             =       ct_qct_sale_type               -- ����敪
       AND     xlvs.lookup_code             =       xsel.sales_class
       AND     gd_process_date              BETWEEN NVL(xlvs.start_date_active, gd_process_date)
                                            AND     NVL(xlvs.end_date_active,   gd_process_date)
       AND     iimb.item_no                 =       xsel.item_code
       GROUP BY
               TO_CHAR(xseh.delivery_date ,cv_fmt_years)     -- �[�i��
              ,xseh.ship_to_customer_code                    -- �ڋq�R�[�h
              ,iimb.attribute2                               -- ����Q�R�[�h
       ;
--
    -- *** ���[�J���E���R�[�h ***
    bus_s_group_sum_sales_rec  bus_s_group_sum_sales_cur%ROWTYPE;
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
    -- ������
    ln_dummy := 0;
--
    --==================================
    -- 1.�쐬�ς݃f�[�^�폜
    --==================================
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_bus_s_group_sum_cur(
                                    cv_dlv_sales      -- �̔�����
                                    );
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_bus_s_group_sum_cur;
    --
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
        );
        RAISE global_data_lock_expt;
    END;
--
    BEGIN
      DELETE  /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
      FROM    xxcos_rep_bus_s_group_sum_py xp
      WHERE   xp.dlv_month            =  gv_target_month
      AND     xp.work_days            =  gn_target_work_days
      AND     xp.sales_transfer_div   =  cv_dlv_sales             -- �̔�����
          -- �������s�̏ꍇ�͏�L����
      AND ( ( gv_any_time_flag        = cv_yes )
        OR
          -- ������s�̏ꍇ�́A���s��=�쐬���̏����t�^
          ( ( gv_any_time_flag        = cv_no )
          AND
            ( TRUNC(xp.creation_date) = TRUNC(SYSDATE) ) )
          )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_delete_data_err,
          iv_token_name1        => cv_tkn_table_name,
          iv_token_value1       => lt_table_name,
          iv_token_name2        => cv_tkn_key_data,
          iv_token_value2       => NULL
        );
        -- �G���[���e�擾
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    -- �R�~�b�g
    COMMIT;
--
    -- ������s�̏ꍇ
    IF ( gv_any_time_flag = cv_no ) THEN
--
      -- ===============================
      -- 2.�����؂�W�v�f�[�^�폜����(C-4)
      -- ===============================
      count_delete_inv_py(
        cv_dlv_sales,      -- �̔�����
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- 3.�쐬�ς݃f�[�^�m�F(�̔�����)
      --==================================
      BEGIN
        SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
               TO_CHAR(xp.creation_date ,cv_fmt_date) AS creation_date
        INTO   lv_creation_date
        FROM   xxcos_rep_bus_s_group_sum_py xp
        WHERE  xp.dlv_month          = gv_target_month
        AND    xp.work_days          = gn_target_work_days
        AND    xp.sales_transfer_div = cv_dlv_sales           -- �̔�����
        AND    ROWNUM                = cn_1
        ;
--
        -- �f�[�^�����݂���ꍇ�͖{�������X�L�b�v
        lv_skip_msg := xxccp_common_pkg.get_msg(
          iv_application   =>  ct_xxcos_appl_short_name,
          iv_name          =>  ct_msg_skip_excute,
          iv_token_name1   =>  cv_tkn_creation_date,
          iv_token_value1  =>  lv_creation_date
        );
--
        FND_FILE.PUT_LINE(
           which  =>  FND_FILE.OUTPUT
          ,buff   =>  lv_skip_msg
        );
        RETURN;
      EXCEPTION
        -- �f�[�^�����݂��Ȃ��ꍇ�͌p��
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
    END IF;
--
    --==================================
    -- 4.�̔����я��o�^�^�X�V����
    --==================================
    -- �Ώۓ��t���[�v
    <<cal_loop>>
    FOR i IN 1 .. gt_target_date_tab.COUNT LOOP
--
      -- ##### debug log #####
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '�yC-2�ztarget_date '|| TO_CHAR(gt_target_date_tab(i).target_date,'YYYY/MM/DD') ||' '||'start '|| TO_CHAR(SYSDATE ,'HH24:MI:SS')
      );
--
      -- �̔����у��[�v
      OPEN bus_s_group_sum_sales_cur(
        gt_target_date_tab(i).target_date
      );
      <<sales_loop>>
      LOOP
        FETCH bus_s_group_sum_sales_cur INTO bus_s_group_sum_sales_rec;
        EXIT WHEN bus_s_group_sum_sales_cur%NOTFOUND;
--
          -- ������
          ln_dummy := 0;
--
          -- ����N���^�ғ����^�ڋq�^����Q�f�[�^�m�F
          SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                 COUNT(1)  AS dummy
          INTO   ln_dummy
          FROM   xxcos_rep_bus_s_group_sum_py xp
          WHERE  xp.dlv_month          = gv_target_month
          AND    xp.work_days          = gn_target_work_days
          AND    xp.customer_code      = bus_s_group_sum_sales_rec.customer_code
          AND    xp.policy_group_code  = bus_s_group_sum_sales_rec.policy_group_code
          AND    xp.sales_transfer_div = cv_dlv_sales                               -- �̔�����
          ;
--
        -- �f�[�^�����݂��Ȃ��ꍇ�͓o�^
        IF ( ln_dummy = 0 ) THEN
--
          -- �Ώی����J�E���g
          gn_target_cnt := gn_target_cnt + 1;
--
          BEGIN
            INSERT INTO xxcos_rep_bus_s_group_sum_py(
               sales_transfer_div
              ,dlv_month
              ,work_days
              ,customer_code
              ,policy_group_code
              ,sale_amount
              ,business_cost
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            ) VALUES
            (
               cv_dlv_sales                                       -- �̔��U�֋敪(�̔�����)
              ,bus_s_group_sum_sales_rec.dlv_month                -- �[�i��
              ,gn_target_work_days                                -- �c�Ɠ�
              ,bus_s_group_sum_sales_rec.customer_code            -- �ڋq�R�[�h
              ,bus_s_group_sum_sales_rec.policy_group_code        -- ����Q�R�[�h
              ,bus_s_group_sum_sales_rec.sale_amount              -- ��������z
              ,bus_s_group_sum_sales_rec.business_cost            -- �c�ƌ���
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
--
            -- ���팏���J�E���g
            gn_normal_cnt    := gn_normal_cnt + 1;
            gn_ins_sales_cnt := gn_ins_sales_cnt + 1;
--
          EXCEPTION
            WHEN OTHERS THEN
              -- �e�[�u�����擾
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_insert_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- �G���[���e�擾
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
--
        -- �f�[�^�����݂���ꍇ�͍X�V(���Z)
        ELSE
--
          BEGIN
            UPDATE /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                   xxcos_rep_bus_s_group_sum_py xp
            SET    xp.sale_amount        = xp.sale_amount   + bus_s_group_sum_sales_rec.sale_amount
                  ,xp.business_cost      = xp.business_cost + bus_s_group_sum_sales_rec.business_cost
            WHERE  xp.dlv_month          = gv_target_month
            AND    xp.work_days          = gn_target_work_days
            AND    xp.customer_code      = bus_s_group_sum_sales_rec.customer_code
            AND    xp.policy_group_code  = bus_s_group_sum_sales_rec.policy_group_code
            AND    xp.sales_transfer_div = cv_dlv_sales                                -- �̔�����
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- �e�[�u�����擾
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_update_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- �G���[���e�擾
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
        END IF;
      END LOOP sales_loop;
      CLOSE bus_s_group_sum_sales_cur;
--
      -- �[�i���P�ʂŃR�~�b�g
      COMMIT;
--
    END LOOP cal_loop;
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END bus_s_group_sum_sales;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_trans
   * Description      : ���ѐU�֏��W�v(�O�N)����(C-3)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_trans(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_trans'; -- �v���O������
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
    ln_dummy             NUMBER;                            -- �J�E���g�p�_�~�[�ϐ�
    lt_table_name        dba_tab_comments.comments%TYPE;    -- �e�[�u����
    lv_creation_date     VARCHAR2(10);                      -- �쐬��
    lv_skip_msg          VARCHAR2(5000);                    -- �����X�L�b�v���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ѐU�֏��(�O�N)�擾�J�[�\��
    CURSOR bus_s_group_sum_trans_cur (
      id_delivery_date DATE
    ) IS
       SELECT
           /*+ USE_NL(xsti iimb) */
           TO_CHAR(xsti.registration_date ,cv_fmt_years)  AS dlv_month             -- �[�i��
          ,xsti.cust_code                                 AS customer_code         -- �ڋq�R�[�h
          ,iimb.attribute2                                AS policy_group_code     -- ����Q�R�[�h
          ,SUM(xsti.selling_amt_no_tax)                   AS sale_amount           -- �{�̋��z
          ,SUM(
               CASE xlvs.attribute3  -- �c�ƌ����Z���Ώ�
                 WHEN cv_yes THEN
                   xsti.trading_cost
                 ELSE
                   cn_0
               END
           )                                              AS business_cost         -- �c�ƌ���
       FROM    xxcok_selling_trns_info   xsti
              ,xxcos_lookup_values_v     xlvs
              ,ic_item_mst_b             iimb
       WHERE   xsti.registration_date       =       id_delivery_date
       AND     xsti.item_code               <>      gt_prof_electric_fee_item_cd   -- �ϓ��d�C��͏���
       AND     xlvs.lookup_type             =       ct_qct_sale_type               -- ����敪
       AND     xlvs.lookup_code             =       xsti.selling_type
       AND     gd_process_date              BETWEEN NVL(xlvs.start_date_active, gd_process_date)
                                            AND     NVL(xlvs.end_date_active,   gd_process_date)
       AND     iimb.item_no                 =       xsti.item_code
       GROUP BY
               TO_CHAR(xsti.registration_date ,cv_fmt_years) -- �[�i��
              ,xsti.cust_code                                -- �ڋq�R�[�h
              ,iimb.attribute2                               -- ����Q�R�[�h
       ;
--
    -- *** ���[�J���E���R�[�h ***
    bus_s_group_sum_trans_rec  bus_s_group_sum_trans_cur%ROWTYPE;
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
    -- ������
    ln_dummy := 0;
--
    --==================================
    -- 1.�쐬�ς݃f�[�^�폜
    --==================================
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_bus_s_group_sum_cur(
                                    cv_dlv_trans  -- ���ѐU��
                                    );
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_bus_s_group_sum_cur;
    --
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
        );
        RAISE global_data_lock_expt;
    END;
--
    BEGIN
      DELETE  /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
      FROM    xxcos_rep_bus_s_group_sum_py xp
      WHERE   xp.dlv_month            =  gv_target_month
      AND     xp.work_days            =  gn_target_work_days
      AND     xp.sales_transfer_div   =  cv_dlv_trans             -- ���ѐU��
          -- �������s�̏ꍇ�͏�L����
      AND ( ( gv_any_time_flag        = cv_yes )
        OR
          -- ������s�̏ꍇ�́A���s��=�쐬���̏����t�^
          ( ( gv_any_time_flag        = cv_no )
          AND
            ( TRUNC(xp.creation_date) = TRUNC(SYSDATE) ) )
          )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_delete_data_err,
          iv_token_name1        => cv_tkn_table_name,
          iv_token_value1       => lt_table_name,
          iv_token_name2        => cv_tkn_key_data,
          iv_token_value2       => NULL
        );
        -- �G���[���e�擾
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    -- �R�~�b�g
    COMMIT;
--
    -- ������s�̏ꍇ
    IF ( gv_any_time_flag = cv_no ) THEN
--
      -- ===============================
      -- 2.�����؂�W�v�f�[�^�폜����(C-4)
      -- ===============================
      count_delete_inv_py(
        cv_dlv_trans,      -- ���ѐU��
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- 3.�쐬�ς݃f�[�^�m�F(���ѐU��)
      --==================================
      BEGIN
        SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
               TO_CHAR(xp.creation_date ,cv_fmt_date) AS creation_date
        INTO   lv_creation_date
        FROM   xxcos_rep_bus_s_group_sum_py xp
        WHERE  xp.dlv_month          = gv_target_month
        AND    xp.work_days          = gn_target_work_days
        AND    xp.sales_transfer_div = cv_dlv_trans           -- ���ѐU��
        AND    ROWNUM                = cn_1
        ;
--
        -- �f�[�^�����݂���ꍇ�͖{�������X�L�b�v
        lv_skip_msg := xxccp_common_pkg.get_msg(
          iv_application   =>  ct_xxcos_appl_short_name,
          iv_name          =>  ct_msg_skip_excute,
          iv_token_name1   =>  cv_tkn_creation_date,
          iv_token_value1  =>  lv_creation_date
        );
--
        FND_FILE.PUT_LINE(
           which  =>  FND_FILE.OUTPUT
          ,buff   =>  lv_skip_msg
        );
--
        RETURN;
      EXCEPTION
        -- �f�[�^�����݂��Ȃ��ꍇ�͌p��
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    --==================================
    -- 4.���ѐU�֏��o�^�^�X�V����
    --==================================
    -- �Ώۓ��t���[�v
    <<cal_loop>>
    FOR i IN 1 .. gt_target_date_tab.COUNT LOOP
      -- ���ѐU�փ��[�v
      OPEN bus_s_group_sum_trans_cur(
        gt_target_date_tab(i).target_date
      );
--
      -- ##### debug log #####
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '�yC-3�ztarget_date '|| TO_CHAR(gt_target_date_tab(i).target_date,'YYYY/MM/DD') ||' '||'start '|| TO_CHAR(SYSDATE ,'HH24:MI:SS')
      );
--
      <<sales_loop>>
      LOOP
        FETCH bus_s_group_sum_trans_cur INTO bus_s_group_sum_trans_rec;
        EXIT WHEN bus_s_group_sum_trans_cur%NOTFOUND;
--
          -- ������
          ln_dummy := 0;
--
          -- ����N���^�ғ����^�ڋq�^����Q�f�[�^�m�F
          SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                 COUNT(1)  AS dummy
          INTO   ln_dummy
          FROM   xxcos_rep_bus_s_group_sum_py xp
          WHERE  xp.dlv_month          = gv_target_month
          AND    xp.work_days          = gn_target_work_days
          AND    xp.customer_code      = bus_s_group_sum_trans_rec.customer_code
          AND    xp.policy_group_code  = bus_s_group_sum_trans_rec.policy_group_code
          AND    xp.sales_transfer_div = cv_dlv_trans                               -- ���ѐU��
          ;
--
        -- �f�[�^�����݂��Ȃ��ꍇ�͓o�^
        IF ( ln_dummy = 0 ) THEN
--
          -- �Ώی����J�E���g
          gn_target_cnt := gn_target_cnt + 1;
--
          BEGIN
            INSERT INTO xxcos_rep_bus_s_group_sum_py(
               sales_transfer_div
              ,dlv_month
              ,work_days
              ,customer_code
              ,policy_group_code
              ,sale_amount
              ,business_cost
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            ) VALUES
            (
               cv_dlv_trans                                       -- �̔��U�֋敪(���ѐU��)
              ,bus_s_group_sum_trans_rec.dlv_month                -- �[�i��
              ,gn_target_work_days                                -- �c�Ɠ�
              ,bus_s_group_sum_trans_rec.customer_code            -- �ڋq�R�[�h
              ,bus_s_group_sum_trans_rec.policy_group_code        -- ����Q�R�[�h
              ,bus_s_group_sum_trans_rec.sale_amount              -- ��������z
              ,bus_s_group_sum_trans_rec.business_cost            -- �c�ƌ���
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
--
            -- ���팏���J�E���g
            gn_normal_cnt    := gn_normal_cnt + 1;
            gn_ins_trans_cnt := gn_ins_trans_cnt + 1;
--
          EXCEPTION
            WHEN OTHERS THEN
              -- �e�[�u�����擾
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_insert_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- �G���[���e�擾
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
--
        -- �f�[�^�����݂���ꍇ�͍X�V(���Z)
        ELSE
--
          BEGIN
            UPDATE /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                   xxcos_rep_bus_s_group_sum_py xp
            SET    xp.sale_amount        = xp.sale_amount   + bus_s_group_sum_trans_rec.sale_amount
                  ,xp.business_cost      = xp.business_cost + bus_s_group_sum_trans_rec.business_cost
            WHERE  xp.dlv_month          = gv_target_month
            AND    xp.work_days          = gn_target_work_days
            AND    xp.customer_code      = bus_s_group_sum_trans_rec.customer_code
            AND    xp.policy_group_code  = bus_s_group_sum_trans_rec.policy_group_code
            AND    xp.sales_transfer_div = cv_dlv_trans                                -- ���ѐU��
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- �e�[�u�����擾
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_update_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- �G���[���e�擾
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
        END IF;
      END LOOP sales_loop;
      CLOSE bus_s_group_sum_trans_cur;
--
      -- �ғ����P�ʂŃR�~�b�g
      COMMIT;
--
    END LOOP cal_loop;
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END bus_s_group_sum_trans;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_delivery_date       IN  VARCHAR2,     -- 1.�[�i��
    iv_processing_class    IN  VARCHAR2,     -- 2.�����敪
    ov_errbuf              OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_table_name        dba_tab_comments.comments%TYPE;    -- �e�[�u����
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
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
    -- �����t���O
    gv_any_time_flag       := cv_no;
    gv_part_comp_err_flag  := cv_no;
    -- �e��������
    gn_ins_sales_cnt := 0;
    gn_ins_trans_cnt := 0;
    gn_del_sales_cnt := 0;
    gn_del_trans_cnt := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(C-1)
    -- ===============================
    init(
      iv_delivery_date,     -- 1.�[�i��
      iv_processing_class,  -- 2.�����敪
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����敪��'0'(�S��)�A�܂���'1'(�̔����я��W�v(�O�N))�̏ꍇ
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_sales ) ) THEN
      -- ===============================
      -- �̔����я��W�v(�O�N)����(C-2)
      --   �����؂�W�v�f�[�^�폜����(C-4)
      -- ===============================
      bus_s_group_sum_sales(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        -- �ꕔ������G���[�t���O��'Y'���Z�b�g
        gv_part_comp_err_flag := cv_yes;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �����敪��'0'(�S��)�A�܂���'2'(���ѐU�֏��W�v(�O�N))�̏ꍇ
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_trans ) ) THEN
      -- ===============================
      -- ���ѐU�֏��W�v(�O�N)����(C-3)
      --   �����؂�W�v�f�[�^�폜����(C-4)
      -- ===============================
      bus_s_group_sum_trans(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        -- �ꕔ������G���[�t���O��'Y'���Z�b�g
        gv_part_comp_err_flag := cv_yes;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      NULL;
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
    errbuf                 OUT  VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT  VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_delivery_date       IN   VARCHAR2,      -- 1.�[�i��
    iv_processing_class    IN   VARCHAR2       -- 2.�����敪
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
    lt_table_name      dba_tab_comments.comments%TYPE;    -- �e�[�u����
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
       iv_delivery_date
      ,iv_processing_class
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- �I������(C-5)
    -- ===============================
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����Z�b�g
      -- ���r���ŃR�~�b�g����̂ő��������N���A���Ȃ�
      gn_error_cnt := 1;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg -- ���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf -- �G���[���b�Z�[�W
      );
      -- ��s�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    -- �����敪��'0'(�S��)�A�܂���'1'(�̔����я��W�v(�O�N))�̏ꍇ
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_sales ) ) THEN
      -- �̔����я��W�v(�O�N)���������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_count_s_group_sales
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_ins_sales_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
--
    -- �����敪��'0'(�S��)�A�܂���'2'(���ѐU�֏��W�v(�O�N))�̏ꍇ
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_trans ) ) THEN
      -- ���ѐU�֏��W�v(�O�N)���������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_count_s_group_trans
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_ins_trans_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ������s�̏ꍇ
    IF ( gv_any_time_flag = cv_no ) THEN
      -- �����؂�W�v���i�O�N�j�폜�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_delete_invalidity
                      ,iv_token_name1  => cv_tkn_keeping_period
                      ,iv_token_value1 => gt_prof_002a03_keeping_period
                      ,iv_token_name2  => cv_tkn_deletion_object
                      ,iv_token_value2 => gv_invalidity_month
                      ,iv_token_name3  => cv_tkn_delete_sales
                      ,iv_token_value3 => TO_CHAR(gn_del_sales_cnt)
                      ,iv_token_name4  => cv_tkn_delete_trans
                      ,iv_token_value4 => TO_CHAR(gn_del_trans_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- ��s�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    -- �Ώی����o��
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
    -- ���������o��
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
    -- �G���[�����o��
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
    -- ���b�Z�[�W�R�[�h�ݒ�
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    -- C-2�ȍ~�ŃG���[�����̏ꍇ�̓��b�Z�[�W�ύX
    IF ( gv_part_comp_err_flag = cv_yes ) THEN
      -- �e�[�u�����擾
      lt_table_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_s_group_sum_py_tbl
      );
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_part_comp_err
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lt_table_name
                     );
    -- �ʏ탁�b�Z�[�W
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => lv_message_code
                     );
    END IF;
--
    -- �I�����b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOS002A033C;
/
