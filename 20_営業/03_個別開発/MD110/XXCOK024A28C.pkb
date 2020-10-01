CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A28C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A28C (body)
 * Description      : �T���f�[�^�p���ѐU��(EDI)�쐬
 * MD.050           : �T���f�[�^�p���ѐU��(EDI)�쐬 MD050_COK_024_A28
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_ins_data           ���ѐU��(EDI)�f�[�^���o�E�o�^(A-2)
 *  purge_data             �T���f�[�^�p���ѐU��(EDI)�p�[�W(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/06/05    1.0   N.Koyama         �V�K�쐬
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  --
  cv_ins                    CONSTANT VARCHAR2(1) := '1';                                -- 1:�ǉ�
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_conc_status   VARCHAR2(30);
  gn_proc_cnt      NUMBER;                    -- ��������
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  --*** ���b�N�G���[��O�n���h�� ***
  global_data_lock_expt     EXCEPTION;
  --*** ���O�̂ݏo�͗�O ***
  global_api_expt_log       EXCEPTION;
  --*** �Ώۃf�[�^�����G���[��O�n���h�� ***
  global_no_data_expt       EXCEPTION;
  --
  -- ���b�N�G���[
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) :=  'XXCOK024A28C';        -- �p�b�P�[�W��
  cv_xxcok_short_name            CONSTANT  VARCHAR2(100) :=  'XXCOK';               -- �̕��̈�Z�k�A�v����
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) :=  'XXCCP';               -- ���ʗ̈�Z�k�A�v����
  --���b�Z�[�W
  cv_msg_lock_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10732';    -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-00001';    -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-00003';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_delete_err              CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10730';    -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-00028';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_parameter               CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10728';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_proc_count              CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10737';    -- �����������b�Z�[�W
  cv_msg_error_count             CONSTANT  VARCHAR2(100) :=  'APP-XXCCP1-90002';    -- �G���[�������b�Z�[�W
  --���b�Z�[�W�p������
  cv_str_purge_term              CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10729';    -- XXCOK:�T���f�[�^�p�̔����ѕێ�����
--
  --�g�[�N����
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE';               -- �e�[�u������
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            -- �L�[�f�[�^
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';             -- �v���t�@�C���� 
  cv_tkn_nm_param1               CONSTANT  VARCHAR2(100) :=  'PARAM1';              -- ���̓p�����[�^�P
  cv_tkn_nm_param2               CONSTANT  VARCHAR2(100) :=  'PARAM2';              -- ���̓p�����[�^�Q
  cv_tkn_nm_param3               CONSTANT  VARCHAR2(100) :=  'PARAM3';              -- ���̓p�����[�^�R
  cv_tkn_nm_count                CONSTANT  VARCHAR2(100) :=  'COUNT';               -- ����
  --�g�[�N���l
  cv_msg_table                   CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10736';    -- �T���f�[�^�p���ѐU��(EDI)
--
  --�N�C�b�N�R�[�h�Q�Ɨp
  --�Q�ƃ^�C�v��
  cv_type_gyotai                 CONSTANT  VARCHAR2(100) :=  'XXCMM_CUST_GYOTAI_SHO';          --�Ƒԏ�����
  --�g�p�\�t���O�萔
  ct_enabled_flg_y               CONSTANT  fnd_lookup_values.enabled_flag%TYPE 
                                                         :=  'Y';       --�g�p�\
  cv_lang                        CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );               --����
--
  -- �v���t�@�C��
  ct_prof_errlist_purge_term     CONSTANT  fnd_profile_options.profile_option_name%TYPE 
                                                         := 'XXCOK1_SALES_EXP_KEEP';  -- XXCOK:�T���f�[�^�p�̔����ѕێ�����
--
  --���t�t�H�[�}�b�g
  cv_yyyy_mm_dd                  CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date                DATE;                                              --�Ɩ����t
  gd_from_date                DATE;                                              --�������t�J�n
  gd_to_date                  DATE;                                              --�������t�I��
  gn_purge_term               NUMBER;                                            --�ėp�G���[���X�g�폜����
  gn_delete_cnt               NUMBER;                                            --�폜����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_kind                    IN     VARCHAR2,  -- �����敪
    iv_from_date                    IN     VARCHAR2,  -- �������tFrom
    iv_to_date                      IN     VARCHAR2,  -- �������tTo
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- �v���O������
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
    lv_para_msg            VARCHAR2(5000);                         -- �p�����[�^�o�̓��b�Z�[�W
    lv_purge_term          NUMBER;                                 -- �T���f�[�^�p�̔����ѕێ�����
    lv_profile_name        fnd_new_messages.message_text%TYPE;     -- �v���t�@�C����
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
    --========================================
    -- �p�����[�^�o�͏���
    --========================================
    lv_para_msg             :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcok_short_name,
      iv_name               =>  cv_msg_parameter,
      iv_token_name1        =>  cv_tkn_nm_param1,
      iv_token_value1       =>  iv_proc_kind,
      iv_token_name2        =>  cv_tkn_nm_param2,
      iv_token_value2       =>  iv_from_date,
      iv_token_name3        =>  cv_tkn_nm_param3,
      iv_token_value3       =>  iv_to_date
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- �Ɩ����t�擾����
    --========================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
    --==================================
    -- XXCOK:�T���f�[�^�p�̔����ѕێ�����
    --==================================
    lv_purge_term := FND_PROFILE.VALUE( ct_prof_errlist_purge_term );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_purge_term IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcok_short_name,
        iv_name        => cv_str_purge_term
      );
      --�v���t�@�C����������擾
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcok_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf    := lv_errmsg;
      RAISE global_api_expt_log;
    ELSE
      gn_purge_term := TO_NUMBER(lv_purge_term);
    END IF;
    --
--
    --==================================
    -- 4.�������̐ݒ�
    --==================================
    IF ( iv_proc_kind = cv_ins ) THEN
      IF ( iv_from_date IS NOT NULL ) THEN
        gd_from_date := TO_DATE(iv_from_date,cv_yyyy_mm_dd);
      ELSE
        gd_from_date := gd_proc_date;
      END IF;
      IF ( iv_to_date IS NOT NULL ) THEN
        gd_to_date := TO_DATE(iv_to_date,cv_yyyy_mm_dd);
      ELSE
        gd_to_date := gd_proc_date;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���O����o�͗p��O�n���h�� ***
    WHEN global_api_expt_log THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_ins_data
   * Description      : ���ѐU��(EDI)�f�[�^���o�E�o�^(A-2)
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ins_data'; -- �v���O������
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
    cv_1              constant varchar2(1)  := '1' ;
    cv_item_category  constant varchar2(30) := '�{�Џ��i�敪' ; 
--
    -- *** ���[�J���ϐ� ***
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
    -- �P�D���ѐU��(EDI)���̎擾�E�T���f�[�^�p���ѐU��(EDI)�̍쐬
    INSERT INTO xxcok_dedu_edi_sell_trns(
             selling_trns_info_id
            ,selling_trns_type
            ,report_decision_flag
            ,delivery_base_code
            ,selling_from_cust_code
            ,base_code
            ,cust_code
            ,selling_date
            ,item_code
            ,product_class
            ,unit_type
            ,delivery_unit_price
            ,qty
            ,selling_amt_no_tax
            ,tax_code
            ,tax_rate
            ,selling_amt
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date    )
    (SELECT  xsi.selling_trns_info_id
            ,xsi.selling_trns_type
            ,xsi.report_decision_flag
            ,xsi.delivery_base_code
            ,xsi.selling_from_cust_code
            ,xsi.base_code
            ,xsi.cust_code
            ,xsi.selling_date
            ,xsi.item_code
            ,SUBSTRB(mcv.segment1,1,1)
            ,xsi.unit_type
            ,xsi.delivery_unit_price
            ,xsi.qty
            ,xsi.selling_amt_no_tax
            ,xsi.tax_code
            ,xsi.tax_rate
            ,xsi.selling_amt
            ,cn_created_by
            ,cd_creation_date
            ,cn_last_updated_by
            ,cd_last_update_date
            ,cn_last_update_login
            ,cn_request_id
            ,cn_program_application_id
            ,cn_program_id
            ,cd_program_update_date
       FROM  mtl_categories_vl        mcv
            ,gmi_item_categories      gic 
            ,mtl_category_sets_vl     mcsv
            ,xxcmm_system_items_b     xsib
            ,xxcok_selling_trns_info  xsi             -- ������ѐU�֏��
            ,fnd_lookup_values        flvc1           -- �Ƒԏ����ރ}�X�^
      WHERE  xsi.registration_date   >= gd_from_date
        AND  xsi.registration_date   <= gd_to_date
        AND  xsi.report_decision_flag = cv_1     -- �m��
        AND  xsi.selling_trns_type    = cv_1     -- EDI
        AND  xsib.item_code           = xsi.item_code
        AND  gic.item_id              = xsib.item_id
        AND  mcsv.category_set_id     = gic.category_set_id
        AND  mcsv.category_set_name   = cv_item_category  -- �{�Џ��i�敪
        AND  mcv.category_id          = gic.category_id
        AND  xsi.cust_state_type      = flvc1.lookup_code
        AND  flvc1.lookup_type        = cv_type_gyotai
        AND  flvc1.language           = cv_lang
        AND  flvc1.enabled_flag       = ct_enabled_flg_y
        AND  flvc1.attribute2         = ct_enabled_flg_y);
    --���������i�[
    gn_proc_cnt := SQL%ROWCOUNT;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_ins_data;
--
  /**********************************************************************************
   * Procedure Name   : purge_data
   * Description      : �T���f�[�^�p���ѐU��(EDI)�p�[�W(A-3)
   ***********************************************************************************/
  PROCEDURE purge_data(
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_data'; -- �v���O������
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
    lv_table_name fnd_new_messages.message_text%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR purge_cur
      IS
        SELECT xdest.selling_trns_info_id
        FROM   xxcok_dedu_edi_sell_trns xdest
        WHERE xdest.selling_date < TRUNC(ADD_MONTHS(gd_proc_date,gn_purge_term * -1),'MM')
        FOR UPDATE NOWAIT;
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
    -- ===============================
    -- ���b�N�̎擾
    -- ===============================
    BEGIN
      OPEN  purge_cur;
      CLOSE purge_cur;
    EXCEPTION
      -- *** ���b�N�G���[�n���h�� ***
      WHEN global_data_lock_expt THEN
        IF ( purge_cur%ISOPEN ) THEN
          CLOSE purge_cur;
        END IF;
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcok_short_name  -- �A�v���P�[�V�����Z�k��
                           ,iv_name        => cv_msg_table         -- ���b�Z�[�W�R�[�h
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_short_name     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_lock_err         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_nm_table_name    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_table_name           -- �g�[�N���l1
                     );
        --
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �T���f�[�^�p���ѐU��(EDI)�̍폜
    -- ===============================
    BEGIN
      DELETE 
        FROM  xxcok_dedu_edi_sell_trns xdest
       WHERE  xdest.selling_date < TRUNC(ADD_MONTHS(gd_proc_date,gn_purge_term * -1),'MM')
      ;
--
    --���������i�[
      gn_proc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      -- *** �p�[�W�G���[�n���h�� ***
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcok_short_name  -- �A�v���P�[�V�����Z�k��
                           ,iv_name        => cv_msg_table         -- ���b�Z�[�W�R�[�h
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_short_name     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_delete_err       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_nm_table_name    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_table_name           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_nm_key_data      -- �g�[�N���R�[�h1
                       ,iv_token_value2 => SQLERRM                 -- �g�[�N���l1
                     );
        --
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( purge_cur%ISOPEN ) THEN
        CLOSE purge_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END purge_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_kind                    IN     VARCHAR2,  -- �����敪
    iv_from_date                    IN     VARCHAR2,  -- �������tFrom
    iv_to_date                      IN     VARCHAR2,  -- �������tTo
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_process_date                   DATE;            -- �������t
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
    gn_proc_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
       iv_proc_kind                    -- �����敪
      ,iv_from_date                    -- �������tFrom
      ,iv_to_date                      -- �������tTo
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- �����敪����
    IF ( iv_proc_kind = cv_ins ) THEN
      -- ===============================
      -- A-2  ���ѐU��(EDI)��񒊏o�E�o�^
      -- ===============================
      get_ins_data(
         lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    ELSE
      -- ===============================
      -- A-3  ���ѐU��(EDI)���p�[�W
      -- ===============================
      purge_data(
         lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �G���[���b�Z�[�W������0��
    IF ( gn_proc_cnt = 0 ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_no_data
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώ�0����O�n���h�� ***
    WHEN global_no_data_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg, 1, 5000 );
      -- ���^�[���R�[�h���ꎞ�I�Ɍx���ɂ���
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf                          OUT    VARCHAR2,         -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                         OUT    VARCHAR2,         -- ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_kind                    IN     VARCHAR2,         -- �����敪
    iv_from_date                    IN     VARCHAR2,         -- �������tFrom
    iv_to_date                      IN     VARCHAR2          -- �������tTo
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
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
       iv_proc_kind                    -- �����敪
      ,iv_from_date                    -- �������tFrom
      ,iv_to_date                      -- �������tTo
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
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
    --
    -- ===============================================
    -- �X�e�[�^�X�̍X�V
    -- ===============================================
    IF (lv_retcode <> cv_status_error ) THEN
      IF   ( gn_proc_cnt > 0 ) THEN
        -- ���������w�b�_���P���ȏ゠��ꍇ�̓X�e�[�^�X�𐳏�
        lv_retcode := cv_status_normal;
      ELSIF( gn_proc_cnt = 0 ) THEN
        -- ���������w�b�_���O���̏ꍇ�̓X�e�[�^�X���x��
        lv_retcode := cv_status_warn;
      END IF;
    ELSE
      -- �G���[�����ݒ�
      gn_error_cnt  := gn_error_cnt + 1;
      gn_proc_cnt   := 0;
    END IF;
    --
    -- ===============================================
    -- �����o��
    -- ===============================================
    -- ���������ƍ폜�����̏o��
    -- ��������
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_msg_proc_count
                    ,iv_token_name1  => cv_tkn_nm_count
                    ,iv_token_value1 => gn_proc_cnt
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
   --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_msg_error_count
                    ,iv_token_name1  => cv_tkn_nm_count
                    ,iv_token_value1 => gn_error_cnt
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
        --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- �I�����b�Z�[�W�o��
    -- ===============================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOK024A28C;
/
