CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A04C(body)
 * Description      : EBS�ɓo�^���ꂽ�K����уf�[�^�����n�V�X�e���ɘA�g���邽�߂�
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           :  MD050_CSO_016_A04_���n-EBS�C���^�[�t�F�[�X�F
 *                     (OUT)�K����уf�[�^
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  set_param_default      �p�����[�^�f�t�H���g�Z�b�g(A-2)
 *  chk_param              �p�����[�^�`�F�b�N(A-3)
 *  get_profile_info       �v���t�@�C���l�擾(A-4)
 *  open_csv_file          �K����уf�[�^CSV�t�@�C���I�[�v��(A-5)
 *  get_accounts_data      �ڋq�}�X�^�E�ڋq�A�h�I���}�X�^���o(A-7)
 *  get_extrnl_rfrnc       �C���X�g�[���x�[�X�}�X�^���o(A-8)
 *  get_sl_rslts_data      �̔����уw�b�_�[�e�[�u���E�̔����і��׃e�[�u�����o(A-9)
 *  create_csv_rec         �K����уf�[�^CSV�o��(A-11)
 *  close_csv_file         CSV�t�@�C���N���[�Y����(A-13)
 *  submain                ���C�������v���V�[�W��
 *                         �K����уf�[�^���o(A-6)
 *                         �O��K������o(A-10)
 *                         �^�X�N�f�[�^�X�V (A-15)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-14)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-19    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2009-02-26    1.1   K.Sai            ���r���[���ʔ��f 
 *  2009-03-05    1.1   Mio.Maruyama     �̔����уe�[�u���d�l�ύX�ɂ��
 *                                       �f�[�^���o�����ύX�Ή�
 *  2009-04-22    1.2   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(T1_0478,T1_0740)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-21    1.4   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(T1_1036)
 *  2009-06-05    1.5   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(T1_0478�ďC��)
 *  2009-07-21    1.6   Kazuo.Satomura   �����e�X�g��Q�Ή�(0000070)
 *  2009-09-09    1.7   Daisuke.Abe      �����e�X�g��Q�Ή�(0001323)
 *  2009-10-07    1.8   Daisuke.Abe      ��Q�Ή�(0001454)
 *  2009-10-23    1.9   Daisuke.Abe      ��Q�Ή�(E_T4_00056)
 *  2009-11-24    1.10  Daisuke.Abe      ��Q�Ή�(E_�{�ғ�_00026)
 *  2009-12-02    1.11  T.Maruyama       ��Q�Ή�(E_�{�ғ�_00081)
 *  2009-12-11    1.12  K.Hosoi          ��Q�Ή�(E_�{�ғ�_00413)
 *  2010-04-08    1.13  Daisuke.Abe      ��Q�Ή�(E_�{�ғ�_02021)
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
  /* 2009.10.07 D.Abe 0001454�Ή� START */
  --gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_skip_cnt      NUMBER;                    -- �X�L�b�v����
  /* 2009.10.07 D.Abe 0001454�Ή� END */
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A04C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00145';  -- �p�����[�^�X�V�� FROM
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00146';  -- �p�����[�^�X�V�� TO
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00150';  -- �p�����[�^�f�t�H���g�Z�b�g
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00384';  -- ���t�����G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00013';  -- �p�����[�^�������G���[
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[���b�Z�[�W
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';  -- �f�[�^���o�G���[
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00127';  -- �f�[�^���o�x�����b�Z�[�W
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00022';  -- CSV�t�@�C���o�̓G���[���b�Z�[�W(�K�����)
  /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00386';  -- �^�X�N�e�[�u�����b�N�G���[
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00332';  -- �^�X�NAPI�X�V�G���[
  /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
  -- �g�[�N���R�[�h
  cv_tkn_frm_val         CONSTANT VARCHAR2(20) := 'FROM_VALUE';
  cv_tkn_to_val          CONSTANT VARCHAR2(20) := 'TO_VALUE';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_csv_fnm         CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc         CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage      CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prcss_nm        CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_vst_dt          CONSTANT VARCHAR2(20) := 'VISIT_DATE';
  cv_tkn_tsk_id          CONSTANT VARCHAR2(20) := 'TASK_ID';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';
  /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_errmsg1         CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_api_name        CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg         CONSTANT VARCHAR2(20) := 'API_MSG';
  /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := 'od_process_date = ';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg7          CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg8          CONSTANT VARCHAR2(200) := 'lv_csv_nm = ';
  cv_debug_msg9          CONSTANT VARCHAR2(200) := 'lv_tsk_stts = ';
  cv_debug_msg10         CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg12         CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg13         CONSTANT VARCHAR2(200) := '<< �N���p�����[�^ >>';
  cv_debug_msg14         CONSTANT VARCHAR2(200) := '�X�V��FROM : ';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := '�X�V��TO : ';
  cv_debug_msg16         CONSTANT VARCHAR2(200) := 'lv_tsk_stts = ';
  cv_debug_msg17         CONSTANT VARCHAR2(200) := 'lv_ib_del_stts = ';
  /* 2009.10.07 D.Abe 0001454�Ή� START */
  cv_debug_msg18         CONSTANT VARCHAR2(200) := '�K��� = ';
  cv_debug_msg19         CONSTANT VARCHAR2(200) := '�p�[�e�BID = ';
  cv_debug_msg20         CONSTANT VARCHAR2(200) := '�K�⎞�ڋq�X�e�[�^�X = ';
  cv_debug_msg21         CONSTANT VARCHAR2(200) := '�K��� = ';
  /* 2009.10.07 D.Abe 0001454�Ή� END */
  cv_debug_msg_fnm       CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls      CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls1     CONSTANT VARCHAR2(200) := '<< ��O�������ŖK����уf�[�^���o�J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2     CONSTANT VARCHAR2(200) := '<< ��O�������őO��K������o�J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_skip      CONSTANT VARCHAR2(200) := '<< �f�[�^�擾���s�̂��߃X�L�b�v���܂��� >>';
  cv_debug_msg_err1      CONSTANT VARCHAR2(200) := 'global_process_expt';
  cv_debug_msg_err2      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err3      CONSTANT VARCHAR2(200) := 'others��O';
  /* 2009.10.07 D.Abe 0001454�Ή� START */
  cv_debug_msg_skip1     CONSTANT VARCHAR2(200) := '<< MC�K��̂��߃X�L�b�v���܂��� >>';
  /* 2009.10.07 D.Abe 0001454�Ή� END */
/* 2009.10.23 D.Abe E_T4_00056�Ή� START */
  cv_debug_msg_skip2     CONSTANT VARCHAR2(200) := '<< �^�X�N�X�V���s�̂��߃X�L�b�v���܂��� >>';
/* 2009.10.23 D.Abe E_T4_00056�Ή� END */
/* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� START */
  cv_debug_msg_skip3     CONSTANT VARCHAR2(200) := '<< �ڋq�}�X�^�s���̂��߃X�L�b�v���܂��� >>';
/* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� END */
--
  cv_w                   CONSTANT VARCHAR2(1)   := 'w';  -- CSV�t�@�C���I�[�v�����[�h
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand           UTL_FILE.FILE_TYPE;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`
  TYPE g_get_data_rtype IS RECORD(
     company_cd                VARCHAR2(3)                                      -- ��ЃR�[�h
    ,actual_end_date           jtf_tasks_b.actual_end_date%TYPE                 -- ���яI����
    ,task_id                   jtf_tasks_b.task_id%TYPE                         -- �K���
    ,account_number            hz_cust_accounts.account_number%TYPE             -- �ڋq�R�[�h
    ,employee_number           per_people_f.employee_number%TYPE                -- �c�ƈ��R�[�h
    ,external_reference        csi_item_instances.external_reference%TYPE       -- �����R�[�h
    ,attribute1                jtf_tasks_b.attribute1%TYPE                      -- �K��敪�R�[�h1 
    ,attribute2                jtf_tasks_b.attribute2%TYPE                      -- �K��敪�R�[�h2 
    ,attribute3                jtf_tasks_b.attribute3%TYPE                      -- �K��敪�R�[�h3 
    ,attribute4                jtf_tasks_b.attribute4%TYPE                      -- �K��敪�R�[�h4 
    ,attribute5                jtf_tasks_b.attribute5%TYPE                      -- �K��敪�R�[�h5 
    ,attribute6                jtf_tasks_b.attribute6%TYPE                      -- �K��敪�R�[�h6 
    ,attribute7                jtf_tasks_b.attribute7%TYPE                      -- �K��敪�R�[�h7 
    ,attribute8                jtf_tasks_b.attribute8%TYPE                      -- �K��敪�R�[�h8 
    ,attribute9                jtf_tasks_b.attribute9%TYPE                      -- �K��敪�R�[�h9 
    ,attribute10               jtf_tasks_b.attribute10%TYPE                     -- �K��敪�R�[�h10
    ,attribute12               jtf_tasks_b.attribute12%TYPE                     -- �o�^���敪
    ,attribute13               jtf_tasks_b.attribute13%TYPE                     -- �o�^���\�[�X�ԍ�
    ,source_object_id          jtf_tasks_b.source_object_id%TYPE                -- �p�[�e�BID
    ,sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE          -- ���_�R�[�h
    ,act_vst_dvsn              VARCHAR2(1)                                      -- �L���K��敪
    ,active_column_number      NUMBER(3)                                        -- �L���R������
    ,missing_column_number     NUMBER(3)                                        -- ���i�R������
    ,missing_part_time         NUMBER(6)                                        -- ���i����
    ,change_out_time_100       xxcos_sales_exp_headers.change_out_time_100%TYPE -- ��K�؂ꎞ��(100�~)
    ,change_out_time_10        xxcos_sales_exp_headers.change_out_time_10%TYPE  -- ��K�؂ꎞ��(10�~)
    ,actual_end_hour           VARCHAR2(4)                                      -- �K�⎞��
    ,actual_end_date_lt        jtf_tasks_b.actual_end_date%TYPE                 -- �O��K���
    ,act_vst_dvsn_lt           VARCHAR2(1)                                      -- �L���K��敪(�O��K�⎞)
    ,deleted_flag              jtf_tasks_b.deleted_flag%TYPE                    -- �폜�t���O
    ,cprtn_date                DATE                                             -- �A������
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_from_value       IN  VARCHAR2         -- �p�����[�^�X�V�� FROM
    ,iv_to_value         IN  VARCHAR2         -- �p�����[�^�X�V�� TO
    ,od_sysdate          OUT DATE             -- �V�X�e�����t
    ,od_process_date     OUT DATE             -- �Ɩ��������t
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg_from         VARCHAR2(5000);
    lv_msg_to           VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �N���p�����[�^���b�Z�[�W�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    lv_msg_from := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_frm_val        --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_from_value         --�g�[�N���l1
                   );
    lv_msg_to := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_03      --���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_to_val         --�g�[�N���R�[�h1
                  ,iv_token_value1 => iv_to_value           --�g�[�N���l1
                 );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_from
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_to
    );
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (od_process_date IS NULL) THEN
      -- ��s�̑}��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : set_param_default
   * Description      : �p�����[�^�f�t�H���g�Z�b�g(A-2)
   ***********************************************************************************/
  PROCEDURE set_param_default(
     io_from_value       IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� FROM
    ,io_to_value         IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� TO
    ,id_process_date     IN DATE                 -- �Ɩ��������t
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'set_param_default';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg_set_param    VARCHAR2(5000);
    -- �N���p�����[�^�f�t�H���g�Z�b�g�t���O
    lb_set_param_flg    BOOLEAN DEFAULT FALSE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �N���p�����[�^NULL�`�F�b�N
    -- ===========================
    -- �X�V��FROM ��NULL�̏ꍇ
    IF (io_from_value IS NULL) THEN
      -- �X�V��FROM �ɋƖ��������t���Z�b�g
      io_from_value := TO_CHAR(id_process_date,'yyyymmdd');
      lb_set_param_flg := cb_true;
    END IF;
    -- �X�V��TO ��NULL�̏ꍇ
    IF (io_to_value IS NULL) THEN
      -- �X�V��TO �ɋƖ��������t���Z�b�g
      io_to_value := TO_CHAR(id_process_date,'yyyymmdd');
      lb_set_param_flg := cb_true;
    END IF;
--
    IF (lb_set_param_flg = cb_true) THEN
      -- ==========================================
      -- �p�����[�^�f�t�H���g�Z�b�g���b�Z�[�W�o��
      -- ==========================================
      lv_msg_set_param := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_04      --���b�Z�[�W�R�[�h
                          );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg_set_param
      );
    END IF;
--
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- *** DEBUG_LOG ***
    -- �p�����[�^�f�t�H���g�Z�b�g��̋N���p�����[�^�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg13 || CHR(10) ||
                 cv_debug_msg14 || io_from_value || CHR(10) ||
                 cv_debug_msg15 || io_to_value   || CHR(10) ||
                 ''
    );
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
  END set_param_default;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_param(
     io_from_value       IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� FROM
    ,io_to_value         IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� TO
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_date_format CONSTANT VARCHAR2(8) := 'YYYYMMDD';
    cv_false       CONSTANT VARCHAR2(5) := 'FALSE';
    -- *** ���[�J���ϐ� ***
    -- �p�����[�^�`�F�b�N�߂�l�i�[�p
    lb_chk_date_from BOOLEAN DEFAULT TRUE;
    lb_chk_date_to   BOOLEAN DEFAULT TRUE;
    -- *** ���[�J����O ***
    chk_param_expt   EXCEPTION;  -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ���t�����`�F�b�N
    -- ===========================
    lb_chk_date_from := xxcso_util_common_pkg.check_date(
                          iv_date         => io_from_value
                         ,iv_date_format  => cv_date_format
                        );
    lb_chk_date_to := xxcso_util_common_pkg.check_date(
                        iv_date         => io_to_value
                       ,iv_date_format  => cv_date_format
                      );
--
    -- �p�����[�^�X�V�� FROM �̓��t������'YYYYMMDD'�`���łȂ��ꍇ
    IF (lb_chk_date_from = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_05             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_val                   --�g�[�N���R�[�h1
                    ,iv_token_value1 => io_from_value                --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_status                --�g�[�N���R�[�h2
                    ,iv_token_value2 => cv_false                     --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    -- �p�����[�^�X�V�� TO �̓��t������'YYYYMMDD'�`���łȂ��ꍇ
    ELSIF (lb_chk_date_to = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_05             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_val                   --�g�[�N���R�[�h1
                    ,iv_token_value1 => io_to_value                  --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_status                --�g�[�N���R�[�h2
                    ,iv_token_value2 => cv_false                     --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ===========================
    -- ���t�召�֌W�`�F�b�N
    -- ===========================
    IF (TO_DATE(io_from_value,'yyyymmdd') > TO_DATE(io_to_value,'yyyymmdd')) THEN
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_frm_val               --�g�[�N���R�[�h1
                       ,iv_token_value1 => io_from_value                --�g�[�N���l1
                       ,iv_token_name2  => cv_tkn_to_val                --�g�[�N���R�[�h2
                       ,iv_token_value2 => io_to_value                  --�g�[�N���l2
                      );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
--
  EXCEPTION
    -- *** �p�����[�^�`�F�b�N��O ***
    WHEN chk_param_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
     ov_company_cd     OUT NOCOPY VARCHAR2  -- ��ЃR�[�h(�Œ�l001)
    ,ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSV�t�@�C���o�͐�
    ,ov_csv_nm         OUT NOCOPY VARCHAR2  -- CSV�t�@�C����(�K�����)
    ,ov_tsk_stts_cls   OUT NOCOPY VARCHAR2  -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    ,ov_ib_del_stts    OUT NOCOPY VARCHAR2  -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_info';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################

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
    -- �v���t�@�C����
    -- XXCSO:���n�A�g�p��ЃR�[�h
    cv_prfnm_cmp_cd          CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_COMPANY_CD';
    -- XXCSO:���n�A�g�pCSV�t�@�C���o�͐�
    cv_prfnm_csv_dir         CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_DIR';
    -- XXCSO:���n�A�g�pCSV�t�@�C����(�K�����)
    cv_prfnm_csv_fnm         CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_VISIT';
    -- XXCSO:�^�X�N�X�e�[�^�XID(�N���[�Y)
    cv_prfnm_tsk_stts_cls    CONSTANT VARCHAR2(30)   := 'XXCSO1_TASK_STATUS_CLOSED_ID';
    -- XXCSO:�C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
    cv_ib_del_stts           CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_DELETE_STATUS';
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C���l�擾�߂�l�i�[�p
    lv_company_cd               VARCHAR2(2000);      -- ��ЃR�[�h(�Œ�l001)
    lv_csv_dir                  VARCHAR2(2000);      -- CSV�t�@�C���o�͐�
    lv_csv_nm                   VARCHAR2(2000);      -- CSV�t�@�C����(�K�����)
    lv_tsk_stts                 VARCHAR2(2000);      -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    lv_ib_del_stts              VARCHAR2(2000);      -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg_fnm                  VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �ϐ����������� 
    -- =======================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    name => cv_prfnm_cmp_cd
                   ,val  => lv_company_cd
                   ); -- ��ЃR�[�h�i�Œ�l001�j
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_dir
                   ,val  => lv_csv_dir
                   ); -- CSV�t�@�C���o�͐�
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_fnm
                   ,val  => lv_csv_nm
                   ); -- CSV�t�@�C����(�K�����)
    FND_PROFILE.GET(
                    name => cv_prfnm_tsk_stts_cls
                   ,val  => lv_tsk_stts
                   ); -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    FND_PROFILE.GET(
                    name => cv_ib_del_stts
                   ,val  => lv_ib_del_stts
                   ); -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
--
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || lv_company_cd || CHR(10) ||
                 cv_debug_msg7  || lv_csv_dir    || CHR(10) ||
                 cv_debug_msg8  || lv_csv_nm     || CHR(10) ||
                 cv_debug_msg16 || lv_tsk_stts   || CHR(10) ||
                 cv_debug_msg17 || lv_ib_del_stts|| CHR(10) ||
                 ''
    );
--
    -- �擾����CSV�t�@�C���������b�Z�[�W�o�͂���
    lv_msg_fnm := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_07      --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_csv_fnm        --�g�[�N���R�[�h1
                   ,iv_token_value1 => lv_csv_nm             --�g�[�N���l1
                  );
--
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_fnm
    );
--
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- ��ЃR�[�h�擾���s��
    IF (lv_company_cd IS NULL) THEN
      lv_tkn_value := cv_prfnm_cmp_cd;
    -- CSV�t�@�C���o�͐�擾���s��
    ELSIF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_dir;
    -- CSV�t�@�C�����擾���s��
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_fnm;
    -- �^�X�N�X�e�[�^�XID(�N���[�Y)�擾���s��
    ELSIF (lv_tsk_stts IS NULL) THEN
      lv_tkn_value := cv_prfnm_tsk_stts_cls;
    -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)�擾���s��
    ELSIF (lv_ib_del_stts IS NULL) THEN
      lv_tkn_value := cv_ib_del_stts;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_08             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_company_cd     :=  lv_company_cd;       -- ��ЃR�[�h�i�Œ�l001�j
    ov_csv_dir        :=  lv_csv_dir;          -- CSV�t�@�C���o�͐�
    ov_csv_nm         :=  lv_csv_nm;           -- CSV�t�@�C����
    ov_tsk_stts_cls   :=  lv_tsk_stts;         -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    ov_ib_del_stts    :=  lv_ib_del_stts;      -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : �K����уf�[�^CSV�t�@�C���I�[�v��(A-5)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_09             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                    ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand := UTL_FILE.FOPEN(
                        location    => iv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg10   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_10     --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc       --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm            --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_accounts_data
   * Description      : �ڋq�}�X�^�E�ڋq�A�h�I���}�X�^���o(A-7)
   ***********************************************************************************/
  PROCEDURE get_accounts_data(
     io_get_data_rec    IN OUT NOCOPY g_get_data_rtype     -- �K����уf�[�^
    ,id_process_date    IN     DATE                        -- �Ɩ��������t
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_accounts_data';  -- �v���O������
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
    cv_prcss_nm   CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�E�ڋq�A�h�I���}�X�^';
    /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� START */
    cv_basecode_nm CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�E�ڋq�A�h�I���}�X�^(���_�R�[�h)';
    /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� END */
    -- *** ���[�J���ϐ� ***
    --�ҏW����яI����
    ld_actual_end_date  DATE;
    --�ҏW��Ɩ��������t
    ld_process_date     DATE;
    --�擾�f�[�^�i�[�p
    lt_account_number   hz_cust_accounts.account_number%TYPE;
    lv_base_code        VARCHAR(4);
    -- *** ���[�J����O ***
    act_end_date_expt    EXCEPTION;                                  -- ���яI������������O
    warn_data_expt       EXCEPTION;                                  -- �Ώۃf�[�^�x����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================
    -- �ڋq�}�X�^�E�ڋq�A�h�I���}�X�^���o
    -- ====================================
    -- ���яI������ҏW
    ld_actual_end_date := TRUNC(io_get_data_rec.actual_end_date,'mm');
    -- �Ɩ��������t��ҏW
    ld_process_date    := TRUNC(id_process_date,'mm');
    --
    BEGIN
--
      -- �ڋq�R�[�h�A���_�R�[�h���擾
      SELECT hca.account_number   account_number  -- �ڋq�R�[�h
             /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� START */
             --,(CASE
             --   WHEN ld_actual_end_date
             --         >= ld_process_date  THEN  xca.sale_base_code      -- ���㋒�_�R�[�h
             --   ELSE xca.past_sale_base_code                            -- �O�����㋒�_�R�[�h
             --   END
             -- ) base_code   -- ���_�R�[�h
             /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� END */
      INTO  lt_account_number
           /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� START */
           --,lv_base_code
           /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� END */
      FROM  hz_cust_accounts      hca -- �ڋq�}�X�^
           ,xxcmm_cust_accounts   xca -- �ڋq�A�h�I���}�X�^
           /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� START */
           ,hz_cust_acct_sites    hcas --�ڋq�A�J�E���g�T�C�g
           /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� END */
      WHERE  hca.party_id        = io_get_data_rec.source_object_id
        AND  hca.cust_account_id = xca.customer_id
        /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� START */
        AND  hcas.cust_account_id = hca.cust_account_id
        /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� END */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND OR 
           TOO_MANY_ROWS THEN
        -- �x�����b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_13                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_vst_dt                          --�g�[�N���R�[�h2
                      ,iv_token_value2 => TO_CHAR(
                                            io_get_data_rec.actual_end_date,'yyyymmdd'
                                          )                                      --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_tsk_id                          --�g�[�N���R�[�h3
                      ,iv_token_value3 => TO_CHAR(io_get_data_rec.task_id)       --�g�[�N���l3
                      ,iv_token_name4  => cv_tkn_errmsg                          --�g�[�N���R�[�h4
                      ,iv_token_value4 => SQLERRM                                --�g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
--
        RAISE warn_data_expt;
      -- OTHERS��O�n���h�� 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_11                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage                      --�g�[�N���R�[�h4
                      ,iv_token_value2 => SQLERRM                                --�g�[�N���l4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� START */
    BEGIN
--
      -- ���_�R�[�h���擾
      SELECT CASE
               WHEN TO_DATE(paf.ass_attribute2, 'YYYYMMDD')  -- ���ߓ�
                      > TRUNC(io_get_data_rec.actual_end_date)
                 THEN paf.ass_attribute6 -- �Ζ��n���_�R�[�h�i���j
                 ELSE paf.ass_attribute5 -- �Ζ��n���_�R�[�h�i�V�j
             END  base_code
      INTO   lv_base_code
      FROM   per_people_f ppf
            ,per_assignments_f paf
      WHERE  ppf.employee_number = io_get_data_rec.employee_number
      AND    ppf.person_id       = paf.person_id
      AND    io_get_data_rec.actual_end_date
               BETWEEN TRUNC(ppf.effective_start_date)
                   AND TRUNC(ppf.effective_end_date)
      AND    io_get_data_rec.actual_end_date
               BETWEEN TRUNC(paf.effective_start_date)
                   AND TRUNC(paf.effective_end_date)
      ;
      
    EXCEPTION
      -- OTHERS��O�n���h�� 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_13                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_basecode_nm                         --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_vst_dt                          --�g�[�N���R�[�h2
                      ,iv_token_value2 => TO_CHAR(
                                            io_get_data_rec.actual_end_date,'yyyymmdd'
                                          )                                      --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_tsk_id                          --�g�[�N���R�[�h3
                      ,iv_token_value3 => TO_CHAR(io_get_data_rec.task_id)       --�g�[�N���l3
                      ,iv_token_name4  => cv_tkn_errmsg                          --�g�[�N���R�[�h4
                      ,iv_token_value4 => SQLERRM                                --�g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE warn_data_expt;
    END;
    /* 2010.04.08 D.Abe E_�{�ғ�_02021�Ή� END */
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    io_get_data_rec.account_number := lt_account_number;         -- �ڋq�R�[�h
    io_get_data_rec.sale_base_code := lv_base_code;              -- ���_�R�[�h
--
  EXCEPTION
    -- *** �Ώۃf�[�^�x����O�n���h�� ***
    WHEN warn_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END get_accounts_data;
--
  /**********************************************************************************
   * Procedure Name   : get_extrnl_rfrnc
   * Description      : �C���X�g�[���x�[�X�}�X�^���o(A-8)
   ***********************************************************************************/
  PROCEDURE get_extrnl_rfrnc(
     io_get_data_rec    IN OUT NOCOPY g_get_data_rtype     -- �K����уf�[�^
    ,iv_ib_del_stts     IN            VARCHAR2             -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_extrnl_rfrnc';  -- �v���O������
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
    cv_onr_pty_srce_tbl      CONSTANT VARCHAR2(10)  := 'HZ_PARTIES';
    cv_prcss_nm   CONSTANT VARCHAR2(100)            := '�C���X�g�[���x�[�X�}�X�^';
    -- *** ���[�J���ϐ� ***
    --�擾�f�[�^�i�[�p
    lt_external_reference    csi_item_instances.external_reference%TYPE;    -- �����R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ============================
    -- �C���X�g�[���x�[�X�}�X�^���o
    -- ============================
    BEGIN
      SELECT ciib.external_reference                                  -- �����R�[�h
      INTO   lt_external_reference
      FROM  ( SELECT  ciia.external_reference     external_reference  -- �����R�[�h
              FROM    csi_item_instances    ciia                      -- �C���X�g�[���x�[�X
                     ,csi_instance_statuses cis                       -- �C���X�g�[���x�[�X�X�e�[�^�X
              WHERE   ciia.owner_party_source_table = cv_onr_pty_srce_tbl
                AND   ciia.owner_party_id           = io_get_data_rec.source_object_id
                AND   ciia.instance_status_id       = cis.instance_status_id
                AND   cis.name                      <> iv_ib_del_stts
              ORDER BY  ciia.install_date
            ) ciib
      WHERE   ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �f�[�^�����݂��Ȃ��ꍇ��NULL��ݒ�
      lt_external_reference := NULL;
      -- OTHERS��O�n���h�� 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_11                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage                      --�g�[�N���R�[�h4
                      ,iv_token_value2 => SQLERRM                                --�g�[�N���l4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    io_get_data_rec.external_reference := lt_external_reference;              -- �����R�[�h
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
  END get_extrnl_rfrnc;
--
  /**********************************************************************************
   * Procedure Name   : get_sl_rslts_data
   * Description      : �̔����уw�b�_�[�e�[�u���E�̔����і��׃e�[�u�����o(A-9)
   ***********************************************************************************/
  PROCEDURE get_sl_rslts_data(
     io_get_data_rec    IN OUT NOCOPY g_get_data_rtype     -- �K����уf�[�^
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sl_rslts_data';  -- �v���O������
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
    cv_sld_out_clss1  CONSTANT VARCHAR2(1) := '1';   -- 1:���؋敪�L��(���؂�L��)
    cv_sld_out_clss2  CONSTANT VARCHAR2(1) := '2';   -- 2:���؋敪����(���؂ꖳ��)
    cv_prcss_nm       CONSTANT VARCHAR2(100) := '�̔����уw�b�_�e�[�u���E�̔����і��׃e�[�u��';
    /* 2009.04.22 K.Satomura T1_0740�Ή� START */
    cv_dlv_gds_info CONSTANT VARCHAR2(1) := '3'; -- �o�^�敪=3:�[�i���
    cv_abrb_clclt   CONSTANT VARCHAR2(1) := '5'; -- �o�^�敪=5:�����v�Z
    /* 2009.04.22 K.Satomura T1_0740�Ή� END */
    -- *** ���[�J���ϐ� ***
    --�擾�f�[�^�i�[�p
    ln_missing_column_number  NUMBER;
    ln_active_column_number   NUMBER;
    ln_missing_part_time      NUMBER;
    lt_change_out_time_100    xxcos_sales_exp_headers.change_out_time_100%TYPE;
    lt_change_out_time_10     xxcos_sales_exp_headers.change_out_time_10%TYPE;
    -- *** ���[�J����O ***
    no_data_expt         EXCEPTION;                 -- �Ώۃf�[�^0����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �̔����уw�b�_�[�e�[�u���E�̔����і��׃e�[�u�����o
    -- =====================================================
    BEGIN
      /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
      --SELECT (SELECT COUNT(xsv1.sold_out_class) sold_out_class1
      --        FROM   xxcso_sales_v xsv1  -- ������уr���[
      --        WHERE  xsv1.sold_out_class = cv_sld_out_clss1
      --        AND    xsv1.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
      --        /* 2009.05.21 K.Satomura T1_1036�Ή� START */
      --        --AND    xsv1.cancel_correct_class IS NULL
      --        AND    xsv1.digestion_ln_number = 0
      --        /* 2009.05.21 K.Satomura T1_1036�Ή� END */
      --        ) missing_column_number                            -- ���i�R������
      --      ,(SELECT COUNT(xsv2.sold_out_class) sold_out_class2
      --        FROM   xxcso_sales_v xsv2  -- ������уr���[
      --        WHERE  xsv2.sold_out_class = cv_sld_out_clss2
      --        AND    xsv2.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
      --        /* 2009.05.21 K.Satomura T1_1036�Ή� START */
      --        --AND    xsv2.cancel_correct_class IS NULL
      --        AND    xsv2.digestion_ln_number = 0
      --        /* 2009.05.21 K.Satomura T1_1036�Ή� END */
      --        ) active_column_number                             -- �L���R������
      --        /* 2009.04.22 K.Satomrua T1_0478�Ή� START */
      --       --,(SELECT SUM(xsv3.sold_out_time) sold_out_time
      --      ,(SELECT SUM(NVL(xsv3.sold_out_time, 0)) sold_out_time
      --        /* 2009.04.22 K.Satomrua T1_0478�Ή� END */
      --        FROM   xxcso_sales_v  xsv3  -- ������уr���[
      --        WHERE  xsv3.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
      --        /* 2009.05.21 K.Satomura T1_1036�Ή� START */
      --        --AND    xsv3.cancel_correct_class IS NULL
      --        AND    xsv3.digestion_ln_number = 0
      --        /* 2009.05.21 K.Satomura T1_1036�Ή� END */
      --        ) missing_part_time                                -- ���i����
      SELECT (SELECT COUNT(xsv1.sold_out_class) sold_out_class1
              FROM   xxcso_sales_of_task_v xsv1  -- �L���K��̔����уr���[
              /* 2009.12.11 K.Hosoi E_�{�ғ�_00413�Ή� START */
              --WHERE  xsv1.sold_out_class = cv_sld_out_clss1
              WHERE  xsv1.sold_out_class = cv_sld_out_clss2
              /* 2009.12.11 K.Hosoi E_�{�ғ�_00413�Ή� END */
              AND    xsv1.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
              AND    xsv1.digestion_ln_number = 0
              ) missing_column_number                            -- ���i�R������
            ,(SELECT COUNT(xsv2.sold_out_class) sold_out_class2
              FROM   xxcso_sales_of_task_v xsv2  -- �L���K��̔����уr���[
              /* 2009.12.11 K.Hosoi E_�{�ғ�_00413�Ή� START */
              --WHERE  xsv2.sold_out_class = cv_sld_out_clss2
              WHERE  (xsv2.sold_out_class = cv_sld_out_clss1
                      OR  xsv2.sold_out_class = cv_sld_out_clss2)
              /* 2009.12.11 K.Hosoi E_�{�ғ�_00413�Ή� END */
              AND    xsv2.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
              AND    xsv2.digestion_ln_number = 0
              ) active_column_number                             -- �L���R������
            ,(SELECT SUM(NVL(xsv3.sold_out_time, 0)) sold_out_time
              FROM   xxcso_sales_of_task_v  xsv3  -- �L���K��̔����уr���[
              WHERE  xsv3.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
              AND    xsv3.digestion_ln_number = 0
              ) missing_part_time                                -- ���i����
      /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
             ,xsv.change_out_time_100  change_out_time_100      -- ��K�؂ꎞ��(100�~)
             ,xsv.change_out_time_10   change_out_time_10       -- ��K�؂ꎞ��(10�~)
      INTO  ln_missing_column_number
           ,ln_active_column_number
           ,ln_missing_part_time
           ,lt_change_out_time_100
           ,lt_change_out_time_10
      /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
      --FROM  xxcso_sales_v  xsv   -- ������уr���[
      FROM  xxcso_sales_of_task_v  xsv   -- �L���K��̔����уr���[
      /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
      WHERE xsv.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
        /* 2009.05.21 K.Satomura T1_1036�Ή� START */
        --AND xsv.cancel_correct_class IS NULL
        AND xsv.digestion_ln_number = 0
        /* 2009.05.21 K.Satomura T1_1036�Ή� END */
        AND ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �x�����b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_13                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_vst_dt                          --�g�[�N���R�[�h2
                      ,iv_token_value2 => TO_CHAR(
                                            io_get_data_rec.actual_end_date,'yyyymmdd'
                                          )                                      --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_tsk_id                          --�g�[�N���R�[�h3
                      ,iv_token_value3 => TO_CHAR(io_get_data_rec.task_id)       --�g�[�N���l3
                      ,iv_token_name4  => cv_tkn_errmsg                          --�g�[�N���R�[�h4
                      ,iv_token_value4 => SQLERRM                                --�g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
--
      RAISE no_data_expt;
      -- OTHERS��O�n���h�� 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_11                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage                      --�g�[�N���R�[�h4
                      ,iv_token_value2 => SQLERRM                                --�g�[�N���l4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    io_get_data_rec.active_column_number  := ln_active_column_number;          -- �L���R������
    io_get_data_rec.missing_column_number := ln_missing_column_number;         -- ���i�R������
    io_get_data_rec.missing_part_time     := ln_missing_part_time;             -- ���i����
    io_get_data_rec.change_out_time_100   := lt_change_out_time_100;           -- ��K�؂ꎞ��(100�~)
    io_get_data_rec.change_out_time_10    := lt_change_out_time_10;            -- ��K�؂ꎞ��(10�~)
--
  EXCEPTION
    -- *** �Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END get_sl_rslts_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : �K����уf�[�^CSV�o��(A-11)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     i_get_data_rec      IN  g_get_data_rtype        -- �K����уf�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- �v���O������
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
    cv_sep_com         CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot       CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_data            VARCHAR2(5000);       -- �ҏW�f�[�^�i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_vst_rslt_data_rec  g_get_data_rtype;   -- IN�p�����[�^.�K����уf�[�^�i�[
    -- *** ���[�J����O ***
    file_put_line_expt   EXCEPTION;          -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����R�[�h�ϐ��Ɋi�[
    l_vst_rslt_data_rec := i_get_data_rec;       -- �K����уf�[�^
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- �f�[�^�쐬
      lv_data := cv_sep_wquot||l_vst_rslt_data_rec.company_cd||cv_sep_wquot -- ��ЃR�[�h
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.actual_end_date, 'yyyymmdd')            -- ���яI����
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.task_id)                                -- �K���
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.account_number  ||cv_sep_wquot    -- �ڋq�R�[�h
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.employee_number ||cv_sep_wquot    -- �c�ƈ��R�[�h
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.external_reference||cv_sep_wquot  -- �����R�[�h
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute1      ||cv_sep_wquot    -- �K��敪�R�[�h1 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute2      ||cv_sep_wquot    -- �K��敪�R�[�h2 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute3      ||cv_sep_wquot    -- �K��敪�R�[�h3 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute4      ||cv_sep_wquot    -- �K��敪�R�[�h4 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute5      ||cv_sep_wquot    -- �K��敪�R�[�h5 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute6      ||cv_sep_wquot    -- �K��敪�R�[�h6 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute7      ||cv_sep_wquot    -- �K��敪�R�[�h7 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute8      ||cv_sep_wquot    -- �K��敪�R�[�h8 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute9      ||cv_sep_wquot    -- �K��敪�R�[�h9 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute10     ||cv_sep_wquot    -- �K��敪�R�[�h10
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.sale_base_code  ||cv_sep_wquot    -- ���_�R�[�h
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.act_vst_dvsn    ||cv_sep_wquot    -- �L���K��敪
       ||cv_sep_com||TO_CHAR(NVL(l_vst_rslt_data_rec.active_column_number, 0))           -- �L���R������
       ||cv_sep_com||TO_CHAR(NVL(l_vst_rslt_data_rec.missing_column_number, 0))          -- ���i�R������
       ||cv_sep_com||TO_CHAR(NVL(l_vst_rslt_data_rec.missing_part_time, 0))              -- ���i����
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.change_out_time_100||cv_sep_wquot -- ��K�؂ꎞ��(100�~)
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.change_out_time_10 ||cv_sep_wquot -- ��K�؂ꎞ��(10�~)
       ||cv_sep_com||NVL(l_vst_rslt_data_rec.actual_end_hour, 0000)                      -- �K�⎞��
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.actual_end_date_lt, 'yyyymmdd')         -- �O��K���
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.act_vst_dvsn_lt ||cv_sep_wquot    -- �L���K��敪(�O��K�⎞)
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.deleted_flag||cv_sep_wquot        -- �폜�t���O
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.cprtn_date, 'yyyymmddhh24miss')         -- �A������
      ;
--
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_14                         --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_vst_dt                            --�g�[�N���R�[�h1
                      ,iv_token_value1 => TO_CHAR(i_get_data_rec.actual_end_date,'yyyymmdd')    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_tsk_id                            --�g�[�N���R�[�h2
                      ,iv_token_value2 => TO_CHAR(i_get_data_rec.task_id)          --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_cstm_cd                           --�g�[�N���R�[�h3
                      ,iv_token_value3 => i_get_data_rec.account_number            --�g�[�N���l3
                      ,iv_token_name4  => cv_tkn_errmsg                            --�g�[�N���R�[�h4
                      ,iv_token_value4 => SQLERRM                                  --�g�[�N���l4
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y����(A-12)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- �v���O������
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
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END close_csv_file;
--
/* 2009.10.23 D.Abe E_T4_00056�Ή� START */
  /**********************************************************************************
   * Procedure Name   : update_task
   * Description      : �^�X�N�f�[�^�X�V (A-15)
   ***********************************************************************************/
  PROCEDURE update_task(
     in_task_id           IN  NUMBER                      -- �^�X�NID
    ,in_obj_ver_num       IN  NUMBER                      -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ,iv_attribute15       IN  VARCHAR2                    -- DFF15
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'update_task';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_task_id           CONSTANT VARCHAR2(30) := '�^�X�NID:';
    cv_task_id2          CONSTANT VARCHAR2(30) := '�^�X�NID';
    cv_task_table_nm     CONSTANT VARCHAR2(30) := '�^�X�N�e�[�u��';
    --
    -- *** ���[�J���ϐ� ***
    ln_task_id          NUMBER;
--
    -- *** ���[�J����O ***
    g_lock_expt                   EXCEPTION;   -- ���b�N��O
    api_expt                      EXCEPTION;   -- �^�X�NAPI��O
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--

    -- =======================
    -- �^�X�N�f�[�^���b�N
    -- =======================
    BEGIN
      SELECT task_id
      INTO   ln_task_id
      FROM   jtf_tasks_b  jtb -- �^�X�N�e�[�u��
      WHERE  jtb.task_id = in_task_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_15           --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table               --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_task_table_nm           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmsg1             --�g�[�N���R�[�h2
                      ,iv_token_value2 => cv_task_id ||  in_task_id  --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_lock_expt;
    END;

    -- =======================
    -- �^�X�N�f�[�^�X�V 
    -- =======================
    xxcso_task_common_pkg.update_task2(
       in_task_id
      ,in_obj_ver_num
      ,iv_attribute15
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    -- ����ł͂Ȃ��ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_16            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_api_name             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_task_id2                 -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_api_msg              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => in_task_id || ',' || lv_errmsg -- �g�[�N���l2
                   );
      lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    WHEN g_lock_expt THEN
      -- *** SQL���b�N�G���[�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- *** �^�X�N�X�VAPI��O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_task;
--
/* 2009.10.23 D.Abe E_T4_00056�Ή� END */
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_from_value       IN  VARCHAR2          -- �p�����[�^�X�V�� FROM
    ,iv_to_value         IN  VARCHAR2          -- �p�����[�^�X�V�� TO
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
    cv_src_obj_tp_cd    CONSTANT VARCHAR2(100)   := 'PARTY';        -- �\�[�X�^�C�v
    cv_owner_tp_cd      CONSTANT VARCHAR2(100)   := 'RS_EMPLOYEE';  -- �I�[�i�[�^�C�v
    cv_category         CONSTANT VARCHAR2(100)   := 'EMPLOYEE';     -- �J�e�S���[
    cv_yes              CONSTANT VARCHAR2(1)     := 'Y';            -- �폜�t���O:Y
    cv_no               CONSTANT VARCHAR2(1)     := 'N';            -- �폜�t���O:N
    cv_normal           CONSTANT VARCHAR2(1)     := '0';            -- �폜�t���O 0:�ʏ�
    cv_delete           CONSTANT VARCHAR2(1)     := '1';            -- �폜�t���O 1:�폜
    cv_active           CONSTANT VARCHAR2(1)     := '1';            -- �L���K��敪 1:�L��
    cv_invalid          CONSTANT VARCHAR2(1)     := '0';            -- �L���K��敪 0:����
    cv_dlv_gds_info     CONSTANT VARCHAR2(1)     := '3';            -- �o�^�敪     3:�[�i���
    cv_abrb_clclt       CONSTANT VARCHAR2(1)     := '5';            -- �o�^�敪     5:�����v�Z
    /* 2009.04.22 K.Satomura T1_0478�Ή� START */
    cv_task_type_visit    CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_TYPE_VISIT';
    cv_src_obj_tp_cd_opp  CONSTANT VARCHAR2(100) := 'OPPORTUNITY'; -- �\�[�X�^�C�v
    /* 2009.04.22 K.Satomura T1_0478�Ή� END */
    /* 2009.10.07 D.Abe 0001454�Ή� START */
    cv_cust_status10    CONSTANT VARCHAR2(2)     := '10';           -- �ڋq�X�e�[�^�X(MC���)
    cv_cust_status20    CONSTANT VARCHAR2(2)     := '20';           -- �ڋq�X�e�[�^�X(MC)
    cv_cust_status25    CONSTANT VARCHAR2(2)     := '25';           -- �ڋq�X�e�[�^�X(SP���F)
    cv_cust_status30    CONSTANT VARCHAR2(2)     := '30';           -- �ڋq�X�e�[�^�X(���F��)
    /* 2009.10.07 D.Abe 0001454�Ή� END */
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    lv_from_value   VARCHAR2(2000); -- �p�����[�^�X�V�� FROM
    lv_to_value     VARCHAR2(2000); -- �p�����[�^�X�V�� TO
    ld_from_value   DATE;           -- �ҏW��p�����[�^�X�V�� FROM �i�[�p
    ld_to_value     DATE;           -- �ҏW��p�����[�^�X�V�� TO   �i�[�p
    ld_sysdate      DATE;           -- �V�X�e�����t
    ld_process_date DATE;           -- �Ɩ��������t
    lv_company_cd   VARCHAR2(2000); -- ��ЃR�[�h�i�Œ�l001�j
    lv_csv_dir      VARCHAR2(2000); -- CSV�t�@�C���o�͐�
    lv_csv_nm       VARCHAR2(2000); -- CSV�t�@�C����
    lv_tsk_stts_cls VARCHAR2(2000); -- �^�X�N�X�e�[�^�XID(�N���[�Y)
    lv_ib_del_stts  VARCHAR2(2000); -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    --
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �K����уf�[�^���o�J�[�\��
    CURSOR get_vst_rslt_data_cur
    IS
      /* 2009.04.22 K.Satomura T1_0478�Ή� START */
      --SELECT  jtb.actual_end_date           actual_end_date              -- �K���
      --       ,jtb.task_id                   task_id                      -- �K���
      --       ,jtb.attribute1                attribute1                   -- �K��敪�R�[�h1
      --       ,jtb.attribute2                attribute2                   -- �K��敪�R�[�h2
      --       ,jtb.attribute3                attribute3                   -- �K��敪�R�[�h3
      --       ,jtb.attribute4                attribute4                   -- �K��敪�R�[�h4
      --       ,jtb.attribute5                attribute5                   -- �K��敪�R�[�h5
      --       ,jtb.attribute6                attribute6                   -- �K��敪�R�[�h6
      --       ,jtb.attribute7                attribute7                   -- �K��敪�R�[�h7
      --       ,jtb.attribute8                attribute8                   -- �K��敪�R�[�h8
      --       ,jtb.attribute9                attribute9                   -- �K��敪�R�[�h9
      --       ,jtb.attribute10               attribute10                  -- �K��敪�R�[�h10
      --       ,TO_CHAR(jtb.actual_end_date,'hh24mi')  actual_end_hour     -- �K�⎞��
      --       ,jtb.deleted_flag              deleted_flag                 -- �폜�t���O
      --       ,jtb.source_object_type_code   source_object_type_code      -- �\�[�X�^�C�v
      --       ,jtb.source_object_id          source_object_id             -- �p�[�e�BID
      --       ,jtb.attribute11               attribute11                  -- �L���K��敪
      --       ,jtb.attribute12               attribute12                  -- �o�^���敪
      --       ,jtb.attribute13               attribute13                  -- �o�^���\�[�X�ԍ�
      --       ,ppf.employee_number           employee_number              -- �c�ƈ��R�[�h
      --FROM    jtf_tasks_b           jtb   -- �^�X�N�e�[�u��
      --       ,per_people_f          ppf   -- �]�ƈ��}�X�^
      --       ,jtf_rs_resource_extns jrre  -- ���\�[�X�}�X�^
      --WHERE  (TRUNC(jtb.last_update_date)
      --         BETWEEN ld_from_value AND ld_to_value
      --       )
      --  AND  jtb.source_object_type_code = cv_src_obj_tp_cd
      --  AND  jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      --  AND  jtb.owner_type_code         = cv_owner_tp_cd
      --  AND  jtb.owner_id                = jrre.resource_id
      --  AND  jrre.category               = cv_category
      --  AND  jrre.source_id              = ppf.person_id
      -- �N���[�Y����Ă���^�X�N
      -- �w�肵�����t�ō쐬/�X�V���������K�����/�K��\��f�[�^�i�ڋq�j
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- �K���
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n21) */
             jtb.actual_end_date                   actual_end_date         -- �K���
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
            ,jtb.task_id                           task_id                 -- �K���
            ,jtb.attribute1                        attribute1              -- �K��敪�R�[�h1
            ,jtb.attribute2                        attribute2              -- �K��敪�R�[�h2
            ,jtb.attribute3                        attribute3              -- �K��敪�R�[�h3
            ,jtb.attribute4                        attribute4              -- �K��敪�R�[�h4
            ,jtb.attribute5                        attribute5              -- �K��敪�R�[�h5
            ,jtb.attribute6                        attribute6              -- �K��敪�R�[�h6
            ,jtb.attribute7                        attribute7              -- �K��敪�R�[�h7
            ,jtb.attribute8                        attribute8              -- �K��敪�R�[�h8
            ,jtb.attribute9                        attribute9              -- �K��敪�R�[�h9
            ,jtb.attribute10                       attribute10             -- �K��敪�R�[�h10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- �K�⎞��
            /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� START */
            --,jtb.deleted_flag                      deleted_flag            -- �폜�t���O
            ,(CASE
                WHEN (TRUNC(jtb.actual_end_date) > ld_process_date) THEN
                  cv_yes
                WHEN (jtb.task_status_id <> lv_tsk_stts_cls) THEN
                  cv_yes
                WHEN (jtb.deleted_flag = cv_yes) THEN
                  cv_yes
                ELSE
                  cv_no
              END
             )                                     deleted_flag            -- �폜�t���O
            /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� END */
            ,jtb.source_object_type_code           source_object_type_code -- �\�[�X�^�C�v
            ,jtb.source_object_id                  source_object_id        -- �p�[�e�BID
            ,jtb.attribute11                       attribute11             -- �L���K��敪
            ,jtb.attribute12                       attribute12             -- �o�^���敪
            ,jtb.attribute13                       attribute13             -- �o�^���\�[�X�ԍ�
            ,ppf.employee_number                   employee_number         -- �c�ƈ��R�[�h
            /* 2009.10.07 D.Abe 0001454�Ή� START */
            ,jtb.attribute14                       attribute14             -- �ڋq�X�e�[�^�X
            /* 2009.10.07 D.Abe 0001454�Ή� END */
            /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
            ,jtb.attribute15                       attribute15             -- ���n�A�g�G���[�X�e�[�^�X
            ,jtb.object_version_number             obj_ver_num             -- �I�u�W�F�N�g�o�[�W�����ԍ�
            /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      FROM   jtf_tasks_b           jtb -- �^�X�N�e�[�u��
            ,per_people_f          ppf -- �]�ƈ��}�X�^
            ,jtf_rs_resource_extns jrr -- ���\�[�X�}�X�^
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code = cv_src_obj_tp_cd
      --AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         = cv_owner_tp_cd
      --AND    jtb.owner_id                = jrr.resource_id
      --AND    jrr.category                = cv_category
      --AND    jrr.source_id               = ppf.person_id
      --AND    jtb.actual_end_date         IS NOT NULL
      --AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.source_object_type_code = cv_src_obj_tp_cd
      AND    jtb.actual_end_date         IS NOT NULL
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      /* 2009.09.09 D.Abe 0001323�Ή� START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      /* 2009.09.09 D.Abe 0001323�Ή� END */
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� END */
      /* 2009.07.21 K.Satomura 0000070�Ή� START */
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = lv_tsk_stts_cls
      AND    jtb.deleted_flag            = cv_no
      /* 2009.07.21 K.Satomura 0000070�Ή� END */
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      -- �N���[�Y�ȊO�̉ߋ����t�̃^�X�N
      -- �w�肵�����t�����ߋ��ɍ쐬/�X�V���ꂽ���R�[�h�œ������K������̖K����уf�[�^�i�ڋq�j
      UNION ALL
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- �K���
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n20) */
             jtb.actual_end_date                   actual_end_date         -- �K���
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
            ,jtb.task_id                           task_id                 -- �K���
            ,jtb.attribute1                        attribute1              -- �K��敪�R�[�h1
            ,jtb.attribute2                        attribute2              -- �K��敪�R�[�h2
            ,jtb.attribute3                        attribute3              -- �K��敪�R�[�h3
            ,jtb.attribute4                        attribute4              -- �K��敪�R�[�h4
            ,jtb.attribute5                        attribute5              -- �K��敪�R�[�h5
            ,jtb.attribute6                        attribute6              -- �K��敪�R�[�h6
            ,jtb.attribute7                        attribute7              -- �K��敪�R�[�h7
            ,jtb.attribute8                        attribute8              -- �K��敪�R�[�h8
            ,jtb.attribute9                        attribute9              -- �K��敪�R�[�h9
            ,jtb.attribute10                       attribute10             -- �K��敪�R�[�h10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- �K�⎞��
            /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� START */
            --,cv_yes                                deleted_flag            -- �폜�t���O
            ,cv_no                                 deleted_flag            -- �폜�t���O
            /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� END */
            ,jtb.source_object_type_code           source_object_type_code -- �\�[�X�^�C�v
            ,jtb.source_object_id                  source_object_id        -- �p�[�e�BID
            ,jtb.attribute11                       attribute11             -- �L���K��敪
            ,jtb.attribute12                       attribute12             -- �o�^���敪
            ,jtb.attribute13                       attribute13             -- �o�^���\�[�X�ԍ�
            ,ppf.employee_number                   employee_number         -- �c�ƈ��R�[�h
            /* 2009.10.07 D.Abe 0001454�Ή� START */
            ,jtb.attribute14                       attribute14             -- �ڋq�X�e�[�^�X
            /* 2009.10.07 D.Abe 0001454�Ή� END */
            /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
            ,jtb.attribute15                       attribute15             -- ���n�A�g�G���[�X�e�[�^�X
            ,jtb.object_version_number             obj_ver_num             -- �I�u�W�F�N�g�o�[�W�����ԍ�
            /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      FROM   jtf_tasks_b           jtb -- �^�X�N�e�[�u��
            ,per_people_f          ppf -- �]�ƈ��}�X�^
            ,jtf_rs_resource_extns jrr -- ���\�[�X�}�X�^
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code =  cv_src_obj_tp_cd
      --AND    jtb.task_status_id          <> TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         =  cv_owner_tp_cd
      --AND    jtb.owner_id                =  jrr.resource_id
      --AND    jrr.category                =  cv_category
      --AND    jrr.source_id               =  ppf.person_id
      --AND    jtb.task_type_id            =  fnd_profile.value(cv_task_type_visit)
      --AND    TRUNC(jtb.actual_end_date)  <= TRUNC(ld_process_date)
      WHERE  TRUNC(jtb.last_update_date)  < ld_from_value
      AND    jtb.task_type_id             = fnd_profile.value(cv_task_type_visit)
      AND    jtb.task_status_id           = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.source_object_type_code  = cv_src_obj_tp_cd
      AND    TRUNC(jtb.actual_end_date)   = ld_process_date
      AND    jtb.owner_type_code          = cv_owner_tp_cd
      AND    jtb.owner_id                 = jrr.resource_id
      AND    jrr.category                 = cv_category
      AND    jrr.source_id                = ppf.person_id
      /* 2009.09.09 D.Abe 0001323�Ή� START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    jtb.deleted_flag            = cv_no
      /* 2009.09.09 D.Abe 0001323�Ή� END */
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� END */
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      UNION ALL
      -- �N���[�Y����Ă��鏤�k�^�X�N
      -- �w�肵�����t�ō쐬/�X�V���������K�����/�K��\��f�[�^�i���k�j
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- �K���
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n21) */
             jtb.actual_end_date                   actual_end_date         -- �K���
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
            ,jtb.task_id                           task_id                 -- �K���
            ,jtb.attribute1                        attribute1              -- �K��敪�R�[�h1
            ,jtb.attribute2                        attribute2              -- �K��敪�R�[�h2
            ,jtb.attribute3                        attribute3              -- �K��敪�R�[�h3
            ,jtb.attribute4                        attribute4              -- �K��敪�R�[�h4
            ,jtb.attribute5                        attribute5              -- �K��敪�R�[�h5
            ,jtb.attribute6                        attribute6              -- �K��敪�R�[�h6
            ,jtb.attribute7                        attribute7              -- �K��敪�R�[�h7
            ,jtb.attribute8                        attribute8              -- �K��敪�R�[�h8
            ,jtb.attribute9                        attribute9              -- �K��敪�R�[�h9
            ,jtb.attribute10                       attribute10             -- �K��敪�R�[�h10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- �K�⎞��
            /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� START */
            --,jtb.deleted_flag                      deleted_flag            -- �폜�t���O
            ,(CASE
                WHEN (TRUNC(jtb.actual_end_date) > ld_process_date) THEN
                  cv_yes
                WHEN (jtb.task_status_id <> TO_NUMBER(lv_tsk_stts_cls)) THEN
                  cv_yes
                WHEN (jtb.deleted_flag = cv_yes) THEN
                  cv_yes
                ELSE
                  cv_no
              END
             )                                     deleted_flag            -- �폜�t���O
            /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� END */
            ,jtb.source_object_type_code           source_object_type_code -- �\�[�X�^�C�v
            ,ala.customer_id                       source_object_id        -- �p�[�e�BID
            ,jtb.attribute11                       attribute11             -- �L���K��敪
            ,jtb.attribute12                       attribute12             -- �o�^���敪
            ,jtb.attribute13                       attribute13             -- �o�^���\�[�X�ԍ�
            ,ppf.employee_number                   employee_number         -- �c�ƈ��R�[�h
            /* 2009.10.07 D.Abe 0001454�Ή� START */
            ,jtb.attribute14                       attribute14             -- �ڋq�X�e�[�^�X
            /* 2009.10.07 D.Abe 0001454�Ή� END */
            /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
            ,jtb.attribute15                       attribute15             -- ���n�A�g�G���[�X�e�[�^�X
            ,jtb.object_version_number             obj_ver_num             -- �I�u�W�F�N�g�o�[�W�����ԍ�
            /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      FROM   jtf_tasks_b           jtb -- �^�X�N�e�[�u��
            ,per_people_f          ppf -- �]�ƈ��}�X�^
            ,jtf_rs_resource_extns jrr -- ���\�[�X�}�X�^
            ,as_leads_all          ala -- ���k�e�[�u��
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code = cv_src_obj_tp_cd_opp
      --AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         = cv_owner_tp_cd
      --AND    jtb.owner_id                = jrr.resource_id
      --AND    jrr.category                = cv_category
      --AND    jrr.source_id               = ppf.person_id
      --AND    jtb.actual_end_date         IS NOT NULL
      --AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      --AND    ala.lead_id                 = jtb.source_object_id
      WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.source_object_type_code = cv_src_obj_tp_cd_opp
      AND    jtb.actual_end_date         IS NOT NULL
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      /* 2009.09.09 D.Abe 0001323�Ή� START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      /* 2009.09.09 D.Abe 0001323�Ή� END */
      AND    ala.lead_id                 = jtb.source_object_id
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� END */
      /* 2009.07.21 K.Satomura 0000070�Ή� START */
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = lv_tsk_stts_cls
      AND    jtb.deleted_flag            = cv_no
      /* 2009.07.21 K.Satomura 0000070�Ή� END */
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      UNION ALL
      -- �N���[�Y�ȊO�̉ߋ����t�̏��k�^�X�N
      -- �w�肵�����t�����ߋ��ɍ쐬/�X�V���ꂽ���R�[�h�œ������K������̖K����уf�[�^�i���k�j
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- �K���
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n20) */
             jtb.actual_end_date                   actual_end_date         -- �K���
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
            ,jtb.task_id                           task_id                 -- �K���
            ,jtb.attribute1                        attribute1              -- �K��敪�R�[�h1
            ,jtb.attribute2                        attribute2              -- �K��敪�R�[�h2
            ,jtb.attribute3                        attribute3              -- �K��敪�R�[�h3
            ,jtb.attribute4                        attribute4              -- �K��敪�R�[�h4
            ,jtb.attribute5                        attribute5              -- �K��敪�R�[�h5
            ,jtb.attribute6                        attribute6              -- �K��敪�R�[�h6
            ,jtb.attribute7                        attribute7              -- �K��敪�R�[�h7
            ,jtb.attribute8                        attribute8              -- �K��敪�R�[�h8
            ,jtb.attribute9                        attribute9              -- �K��敪�R�[�h9
            ,jtb.attribute10                       attribute10             -- �K��敪�R�[�h10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- �K�⎞��
            /* 2009.09.09 D.Abe 0001323�Ή� START */
            --,cv_yes                                deleted_flag            -- �폜�t���O
            ,cv_no                                 deleted_flag            -- �폜�t���O
            /* 2009.09.09 D.Abe 0001323�Ή� END */
            ,jtb.source_object_type_code           source_object_type_code -- �\�[�X�^�C�v
            ,ala.customer_id                       source_object_id        -- �p�[�e�BID
            ,jtb.attribute11                       attribute11             -- �L���K��敪
            ,jtb.attribute12                       attribute12             -- �o�^���敪
            ,jtb.attribute13                       attribute13             -- �o�^���\�[�X�ԍ�
            ,ppf.employee_number                   employee_number         -- �c�ƈ��R�[�h
            /* 2009.10.07 D.Abe 0001454�Ή� START */
            ,jtb.attribute14                       attribute14             -- �ڋq�X�e�[�^�X
            /* 2009.10.07 D.Abe 0001454�Ή� END */
            /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
            ,jtb.attribute15                       attribute15             -- ���n�A�g�G���[�X�e�[�^�X
            ,jtb.object_version_number             obj_ver_num             -- �I�u�W�F�N�g�o�[�W�����ԍ�
            /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      FROM   jtf_tasks_b           jtb -- �^�X�N�e�[�u��
            ,per_people_f          ppf -- �]�ƈ��}�X�^
            ,jtf_rs_resource_extns jrr -- ���\�[�X�}�X�^
            ,as_leads_all          ala -- ���k�e�[�u��
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code =  cv_src_obj_tp_cd_opp
      --AND    jtb.task_status_id          <> TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         =  cv_owner_tp_cd
      --AND    jtb.owner_id                =  jrr.resource_id
      --AND    jrr.category                =  cv_category
      --AND    jrr.source_id               =  ppf.person_id
      --AND    TRUNC(jtb.actual_end_date)  <= TRUNC(ld_process_date)
      --AND    jtb.task_type_id            =  fnd_profile.value(cv_task_type_visit)
      --AND    ala.lead_id                 =  jtb.source_object_id
      WHERE  TRUNC(jtb.last_update_date)  < ld_from_value
      AND    jtb.task_type_id             = fnd_profile.value(cv_task_type_visit)
      AND    jtb.task_status_id           = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.source_object_type_code  = cv_src_obj_tp_cd_opp
      AND    TRUNC(jtb.actual_end_date)   = ld_process_date
      AND    jtb.owner_type_code         =  cv_owner_tp_cd
      AND    jtb.owner_id                =  jrr.resource_id
      AND    jrr.category                =  cv_category
      AND    jrr.source_id               =  ppf.person_id
      /* 2009.09.09 D.Abe 0001323�Ή� START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    jtb.deleted_flag            = cv_no
      /* 2009.09.09 D.Abe 0001323�Ή� END */
      AND    ala.lead_id                 =  jtb.source_object_id
      /* 2009.06.05 K.Satomura T1_0478�ďC���Ή� END */
      /* 2009.04.22 K.Satomura T1_0478�Ή� END */
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
      UNION ALL
      --�A�g�G���[�f�[�^�i�ڋq�K��^�X�N�j�擾
      SELECT /*+ leading(jtb) use_concat index(jtb xxcso_jtf_tasks_b_n22) */
             jtb.actual_end_date                   actual_end_date         -- �K���
            ,jtb.task_id                           task_id                 -- �K���
            ,jtb.attribute1                        attribute1              -- �K��敪�R�[�h1
            ,jtb.attribute2                        attribute2              -- �K��敪�R�[�h2
            ,jtb.attribute3                        attribute3              -- �K��敪�R�[�h3
            ,jtb.attribute4                        attribute4              -- �K��敪�R�[�h4
            ,jtb.attribute5                        attribute5              -- �K��敪�R�[�h5
            ,jtb.attribute6                        attribute6              -- �K��敪�R�[�h6
            ,jtb.attribute7                        attribute7              -- �K��敪�R�[�h7
            ,jtb.attribute8                        attribute8              -- �K��敪�R�[�h8
            ,jtb.attribute9                        attribute9              -- �K��敪�R�[�h9
            ,jtb.attribute10                       attribute10             -- �K��敪�R�[�h10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- �K�⎞��
            ,cv_no                                 deleted_flag            -- �폜�t���O
            ,jtb.source_object_type_code           source_object_type_code -- �\�[�X�^�C�v
            ,jtb.source_object_id                  source_object_id        -- �p�[�e�BID
            ,jtb.attribute11                       attribute11             -- �L���K��敪
            ,jtb.attribute12                       attribute12             -- �o�^���敪
            ,jtb.attribute13                       attribute13             -- �o�^���\�[�X�ԍ�
            ,ppf.employee_number                   employee_number         -- �c�ƈ��R�[�h
            ,jtb.attribute14                       attribute14             -- �ڋq�X�e�[�^�X
            ,jtb.attribute15                       attribute15             -- ���n�A�g�G���[�X�e�[�^�X
            ,jtb.object_version_number             obj_ver_num             -- �I�u�W�F�N�g�o�[�W�����ԍ�
      FROM   jtf_tasks_b           jtb -- �^�X�N�e�[�u��
            ,per_people_f          ppf -- �]�ƈ��}�X�^
            ,jtf_rs_resource_extns jrr -- ���\�[�X�}�X�^
      WHERE  jtb.source_object_type_code = cv_src_obj_tp_cd
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.deleted_flag            = cv_no
      AND    (
              (jtb.attribute15           = cv_yes)
              OR
              (jtb.attribute15 BETWEEN TO_CHAR(ld_from_value,'YYYYMMDD')
                                   AND TO_CHAR(ld_to_value  ,'YYYYMMDD')
              )
             )
      UNION ALL
      --�A�g�G���[�f�[�^�i���k�^�X�N�j�擾
      SELECT /*+ leading(jtb) use_concat index(jtb xxcso_jtf_tasks_b_n22) */
             jtb.actual_end_date                   actual_end_date         -- �K���
            ,jtb.task_id                           task_id                 -- �K���
            ,jtb.attribute1                        attribute1              -- �K��敪�R�[�h1
            ,jtb.attribute2                        attribute2              -- �K��敪�R�[�h2
            ,jtb.attribute3                        attribute3              -- �K��敪�R�[�h3
            ,jtb.attribute4                        attribute4              -- �K��敪�R�[�h4
            ,jtb.attribute5                        attribute5              -- �K��敪�R�[�h5
            ,jtb.attribute6                        attribute6              -- �K��敪�R�[�h6
            ,jtb.attribute7                        attribute7              -- �K��敪�R�[�h7
            ,jtb.attribute8                        attribute8              -- �K��敪�R�[�h8
            ,jtb.attribute9                        attribute9              -- �K��敪�R�[�h9
            ,jtb.attribute10                       attribute10             -- �K��敪�R�[�h10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- �K�⎞��
            ,cv_no                                 deleted_flag            -- �폜�t���O
            ,jtb.source_object_type_code           source_object_type_code -- �\�[�X�^�C�v
            ,ala.customer_id                       source_object_id        -- �p�[�e�BID
            ,jtb.attribute11                       attribute11             -- �L���K��敪
            ,jtb.attribute12                       attribute12             -- �o�^���敪
            ,jtb.attribute13                       attribute13             -- �o�^���\�[�X�ԍ�
            ,ppf.employee_number                   employee_number         -- �c�ƈ��R�[�h
            ,jtb.attribute14                       attribute14             -- �ڋq�X�e�[�^�X
            ,jtb.attribute15                       attribute15             -- ���n�A�g�G���[�X�e�[�^�X
            ,jtb.object_version_number             obj_ver_num             -- �I�u�W�F�N�g�o�[�W�����ԍ�
      FROM   jtf_tasks_b           jtb -- �^�X�N�e�[�u��
            ,per_people_f          ppf -- �]�ƈ��}�X�^
            ,jtf_rs_resource_extns jrr -- ���\�[�X�}�X�^
            ,as_leads_all          ala -- ���k�e�[�u��
      WHERE  jtb.source_object_type_code = cv_src_obj_tp_cd_opp
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.deleted_flag            = cv_no
      AND    (
              (jtb.attribute15           = cv_yes)
              OR
              (jtb.attribute15 BETWEEN TO_CHAR(ld_from_value,'YYYYMMDD')
                                   AND TO_CHAR(ld_to_value  ,'YYYYMMDD')
              )
             )
      AND    ala.lead_id                 = jtb.source_object_id
      /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
      ;
    -- �O��K������o�J�[�\��
    CURSOR get_lst_vst_dt_cur(
              it_srce_objct_id  IN jtf_tasks_b.source_object_id%TYPE -- �p�[�e�BID
             ,it_task_id        IN jtf_tasks_b.task_id%TYPE          -- �^�X�NID
             ,it_act_end_dt     IN jtf_tasks_b.actual_end_date%TYPE  -- ���яI����
           )
    IS
      SELECT  jtb.actual_end_date   actual_end_date   -- �O��K���
             ,jtb.attribute11       attribute11       -- �L���K��敪
             ,jtb.attribute12       attribute12       -- �o�^�敪
      FROM   jtf_tasks_b    jtb                       -- �^�X�N�e�[�u��
      WHERE  jtb.source_object_type_code = cv_src_obj_tp_cd
        AND  jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
        AND  jtb.owner_type_code         = cv_owner_tp_cd
        AND  jtb.source_object_id        = it_srce_objct_id
        AND  jtb.task_id                <> it_task_id
        AND  jtb.actual_end_date        <= it_act_end_dt
        AND  jtb.deleted_flag            = cv_no
      /* 2009.04.22 K.Satomura T1_0478�Ή� START */
      UNION ALL
      SELECT jtb.actual_end_date actual_end_date -- �O��K���
            ,jtb.attribute11     attribute11     -- �L���K��敪
            ,jtb.attribute12     attribute12     -- �o�^�敪
      FROM   jtf_tasks_b  jtb -- �^�X�N�e�[�u��
            ,as_leads_all ala -- ���k�e�[�u��
      WHERE  jtb.source_object_type_code =  cv_src_obj_tp_cd_opp
      AND    jtb.task_status_id          =  TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.owner_type_code         =  cv_owner_tp_cd
      AND    jtb.task_id                 <> it_task_id
      AND    jtb.actual_end_date         <= it_act_end_dt
      AND    jtb.deleted_flag            =  cv_no
      AND    ala.lead_id                 =  jtb.source_object_id
      AND    ala.customer_id             =  it_srce_objct_id
      /* 2009.04.22 K.Satomura T1_0478�Ή� END */
      ORDER BY actual_end_date DESC
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_get_vst_rslt_dt_rec     get_vst_rslt_data_cur%ROWTYPE;
    l_get_lst_vst_dt_rec      get_lst_vst_dt_cur%ROWTYPE;
    l_get_data_rec            g_get_data_rtype;
    -- *** ���[�J����O ***
    error_skip_data_expt           EXCEPTION;   -- �����X�L�b�v��O
    /* 2009.10.07 D.Abe 0001454�Ή� START */
    status_skip_data_expt          EXCEPTION;   -- �����ΏۊO��O
    /* 2009.10.07 D.Abe 0001454�Ή� END */
    /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
    update_skip_data_expt          EXCEPTION;   -- �X�V��O
    /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
    /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� START */
    cust_error_skip_expt           EXCEPTION;   --  �ڋq�}�X�^�s���X�L�b�v
    /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� END */
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
    /* 2009.10.07 D.Abe 0001454�Ή� START */
    gn_skip_cnt  := 0;
    /* 2009.10.07 D.Abe 0001454�Ή� END */
    -- IN�p�����[�^�i�[
    lv_from_value := iv_from_value;  -- �p�����[�^�X�V�� FROM
    lv_to_value   := iv_to_value;    -- �p�����[�^�X�V�� TO
--
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
      iv_from_value    => lv_from_value       -- �p�����[�^�X�V�� FROM
     ,iv_to_value      => lv_to_value         -- �p�����[�^�X�V�� TO
     ,od_sysdate       => ld_sysdate          -- �V�X�e�����t
     ,od_process_date  => ld_process_date     -- �Ɩ��������t
     ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-2.�p�����[�^�f�t�H���g�Z�b�g
    -- ========================================
    set_param_default(
      io_from_value    => lv_from_value       -- �p�����[�^�X�V�� FROM
     ,io_to_value      => lv_to_value         -- �p�����[�^�X�V�� TO
     ,id_process_date  => ld_process_date     -- �Ɩ��������t
     ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-3.�p�����[�^�`�F�b�N
    -- ========================================
    chk_param(
      io_from_value    => lv_from_value       -- �p�����[�^�X�V�� FROM
     ,io_to_value      => lv_to_value         -- �p�����[�^�X�V�� TO
     ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );                                        
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-4.�v���t�@�C���l�擾
    -- ========================================
    get_profile_info(
      ov_company_cd     =>  lv_company_cd    -- ��ЃR�[�h(�Œ�l001)
     ,ov_csv_dir        =>  lv_csv_dir       -- CSV�t�@�C���o�͐�
     ,ov_csv_nm         =>  lv_csv_nm        -- CSV�t�@�C����(�K�����)
     ,ov_tsk_stts_cls   =>  lv_tsk_stts_cls  -- �^�X�N�X�e�[�^�XID(�N���[�Y)
     ,ov_ib_del_stts    =>  lv_ib_del_stts   -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
     ,ov_errbuf         =>  lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode        =>  lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg         =>  lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-5.�K����уf�[�^CSV�t�@�C���I�[�v��
    -- ========================================
    open_csv_file(
      iv_csv_dir       => lv_csv_dir          -- CSV�t�@�C���o�͐�
     ,iv_csv_nm        => lv_csv_nm           -- CSV�t�@�C����
     ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-6.�K����уf�[�^���o
    -- ========================================
    -- �p�����[�^�X�V�� �ҏW
    ld_from_value := TO_DATE(lv_from_value,'yyyymmdd');
    ld_to_value   := TO_DATE(lv_to_value,'yyyymmdd');
--
    -- �J�[�\���I�[�v��
    OPEN get_vst_rslt_data_cur;
--
    <<get_vst_rslt_data_loop>>
    LOOP
--
      BEGIN
--
        FETCH get_vst_rslt_data_cur INTO l_get_vst_rslt_dt_rec;
        -- �����Ώی����i�[
        gn_target_cnt := get_vst_rslt_data_cur%ROWCOUNT;
--
        -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
        EXIT WHEN get_vst_rslt_data_cur%NOTFOUND
        OR  get_vst_rslt_data_cur%ROWCOUNT = 0;
--

        /* 2009.10.07 D.Abe 0001454�Ή� START */
        -- �ڋq�X�e�[�^�X��NOT NULL����,10(MC���),20(MC),25(SP���F��),30(���F��)�̏ꍇ�X�L�b�v
        IF ((l_get_vst_rslt_dt_rec.attribute14 IS NOT NULL) AND 
            (l_get_vst_rslt_dt_rec.attribute14 IN ( cv_cust_status10,
                                                    cv_cust_status20,
                                                    cv_cust_status25,
                                                    cv_cust_status30))) THEN
          RAISE status_skip_data_expt;
        END IF;
        /* 2009.10.07 D.Abe 0001454�Ή� END */
        -- ���R�[�h�ϐ�������
        l_get_data_rec := NULL;
        -- �擾�f�[�^���i�[
        l_get_data_rec.company_cd           :=  lv_company_cd;                             -- ��ЃR�[�h
        l_get_data_rec.actual_end_date      :=  l_get_vst_rslt_dt_rec.actual_end_date;     -- ���яI����
        l_get_data_rec.task_id              :=  l_get_vst_rslt_dt_rec.task_id;             -- �K���
        l_get_data_rec.employee_number      :=  l_get_vst_rslt_dt_rec.employee_number;     -- �c�ƈ��R�[�h
        l_get_data_rec.attribute1           :=  l_get_vst_rslt_dt_rec.attribute1;          -- �K��敪�R�[�h1 
        l_get_data_rec.attribute2           :=  l_get_vst_rslt_dt_rec.attribute2;          -- �K��敪�R�[�h2 
        l_get_data_rec.attribute3           :=  l_get_vst_rslt_dt_rec.attribute3;          -- �K��敪�R�[�h3 
        l_get_data_rec.attribute4           :=  l_get_vst_rslt_dt_rec.attribute4;          -- �K��敪�R�[�h4 
        l_get_data_rec.attribute5           :=  l_get_vst_rslt_dt_rec.attribute5;          -- �K��敪�R�[�h5 
        l_get_data_rec.attribute6           :=  l_get_vst_rslt_dt_rec.attribute6;          -- �K��敪�R�[�h6 
        l_get_data_rec.attribute7           :=  l_get_vst_rslt_dt_rec.attribute7;          -- �K��敪�R�[�h7 
        l_get_data_rec.attribute8           :=  l_get_vst_rslt_dt_rec.attribute8;          -- �K��敪�R�[�h8 
        l_get_data_rec.attribute9           :=  l_get_vst_rslt_dt_rec.attribute9;          -- �K��敪�R�[�h9 
        l_get_data_rec.attribute10          :=  l_get_vst_rslt_dt_rec.attribute10;         -- �K��敪�R�[�h10
        l_get_data_rec.attribute12          :=  l_get_vst_rslt_dt_rec.attribute12;         -- �o�^���敪
        l_get_data_rec.attribute13          :=  l_get_vst_rslt_dt_rec.attribute13;         -- �o�^���\�[�X�ԍ�
        l_get_data_rec.source_object_id     :=  l_get_vst_rslt_dt_rec.source_object_id;    -- �p�[�e�BID
        --
        -- �L���K��敪=1(�L��)���o�^�敪=3(�[�i���)��������5(�����v�Z)�̏ꍇ
        IF (l_get_vst_rslt_dt_rec.attribute11 = cv_active) THEN
          IF ((l_get_vst_rslt_dt_rec.attribute12 = cv_dlv_gds_info)
            OR (l_get_vst_rslt_dt_rec.attribute12 = cv_abrb_clclt))
          THEN
            -- �L���K��敪��1(�L��)��ݒ�
            l_get_data_rec.act_vst_dvsn := cv_active;
          ELSE
            -- �L���K��敪��0(����)��ݒ�
            l_get_data_rec.act_vst_dvsn := cv_invalid;
          END IF;
        ELSE
          -- �L���K��敪��0(����)��ݒ�
          l_get_data_rec.act_vst_dvsn := cv_invalid;
        END IF;
        l_get_data_rec.actual_end_hour      :=  l_get_vst_rslt_dt_rec.actual_end_hour;     -- �K�⎞��
        --
        -- �폜�t���O��'Y'�̏ꍇ
        IF (l_get_vst_rslt_dt_rec.deleted_flag = cv_yes) THEN
          -- �폜�t���O�� 1:�폜 ��ݒ�
          l_get_data_rec.deleted_flag       :=  cv_delete;  -- �폜�t���O
        -- �폜�t���O��'N'�̏ꍇ
        ELSIF (l_get_vst_rslt_dt_rec.deleted_flag = cv_no) THEN
          -- �폜�t���O�� 0:�ʏ� ��ݒ�
          l_get_data_rec.deleted_flag       :=  cv_normal;  -- �폜�t���O
        END IF;
        l_get_data_rec.cprtn_date           :=   ld_sysdate;                               -- �A������
--
        -- ========================================
        -- A-7.�ڋq�}�X�^�E�ڋq�A�h�I���}�X�^���o
        -- ========================================
        get_accounts_data(
           io_get_data_rec    => l_get_data_rec     -- �K����уf�[�^
          ,id_process_date    => ld_process_date    -- �Ɩ��������t
          ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_warn) THEN
          /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� START */
          --RAISE error_skip_data_expt;
          RAISE cust_error_skip_expt;
          /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� END */
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ========================================
        -- A-8.�C���X�g�[���x�[�X�}�X�^���o
        -- ========================================
        get_extrnl_rfrnc(
           io_get_data_rec    => l_get_data_rec     -- �K����уf�[�^
          ,iv_ib_del_stts     => lv_ib_del_stts     -- �C���X�g�[���x�[�X�X�e�[�^�X(�����폜��)
          ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �L���K��敪���L��(1)���o�^�敪���[�i���(3)�̂������͏����v�Z(5)�ꍇ 
        IF (l_get_vst_rslt_dt_rec.attribute11 = cv_active) THEN
          /* 2009.04.22 K.Satomur T1_0740�Ή� START */
          --IF ((l_get_vst_rslt_dt_rec.attribute12 = cv_dlv_gds_info)
          --  OR (l_get_vst_rslt_dt_rec.attribute12 = cv_abrb_clclt))
          --THEN
          IF (l_get_vst_rslt_dt_rec.attribute12 = cv_dlv_gds_info) THEN
          /* 2009.04.22 K.Satomur T1_0740�Ή� END */
            -- ========================================
            -- A-9.�̔����уw�b�_�[�e�[�u���E�̔����і��׃e�[�u�����o
            -- ========================================
            get_sl_rslts_data(
              io_get_data_rec    =>  l_get_data_rec   -- �K����уf�[�^
             ,ov_errbuf          =>  lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
             ,ov_retcode         =>  lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
             ,ov_errmsg          =>  lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
            );
--
            IF (lv_retcode = cv_status_warn) THEN
              RAISE error_skip_data_expt;
            ELSIF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
        END IF;
        -- ========================================
        -- A-10.�O��K������o
        -- ========================================
        -- �J�[�\���I�[�v��
        OPEN get_lst_vst_dt_cur(
              it_srce_objct_id  => l_get_data_rec.source_object_id  -- �p�[�e�BID
             ,it_task_id        => l_get_data_rec.task_id           -- �^�X�NID
             ,it_act_end_dt     => l_get_data_rec.actual_end_date   -- ���яI����
             );
--
        <<get_lst_vst_dt_loop>>
        LOOP
          FETCH get_lst_vst_dt_cur INTO l_get_lst_vst_dt_rec;
          -- �����Ώۃf�[�^�����݂��Ȃ������ꍇ�A1���ڂ𒊏o���I�����ꍇ EXIT
          EXIT WHEN get_lst_vst_dt_cur%NOTFOUND
          OR  get_lst_vst_dt_cur%ROWCOUNT = 0;
--
          -- �O��K������i�[
          l_get_data_rec.actual_end_date_lt := l_get_lst_vst_dt_rec.actual_end_date;
--
        -- �L���K��敪���L��(1)���o�^�敪���[�i���(3)�������͏����v�Z(5)�̏ꍇ 
          IF (l_get_lst_vst_dt_rec.attribute11 = cv_active) THEN
            IF (l_get_lst_vst_dt_rec.attribute12 IN (cv_dlv_gds_info,cv_abrb_clclt)) THEN
              -- �L���K��敪��1(�L��)��ݒ�
              l_get_data_rec.act_vst_dvsn_lt := cv_active;
            ELSE
              -- �L���K��敪��0(����)��ݒ�
              l_get_data_rec.act_vst_dvsn_lt := cv_invalid;
            END IF;
          ELSE
            -- �L���K��敪��0(����)��ݒ�
            l_get_data_rec.act_vst_dvsn_lt := cv_invalid;
          END IF;
--
          -- �ꌏ�ڎ擾�ł������_�Ń��[�v�𔲂��܂��B
          EXIT WHEN get_lst_vst_dt_cur%NOTFOUND
          OR  get_lst_vst_dt_cur%ROWCOUNT <> 0;
--
        END LOOP get_lst_vst_dt_loop;
        -- �O��K������o�J�[�\���ŁA�Ώۃf�[�^�����݂��Ȃ������ꍇ
        IF (get_lst_vst_dt_cur%ROWCOUNT = 0) THEN
          l_get_data_rec.actual_end_date_lt := NULL;  -- �O��K���
          l_get_data_rec.act_vst_dvsn_lt    := NULL;  -- �L���K��敪
        END IF;
        -- �J�[�\���N���[�Y
        CLOSE get_lst_vst_dt_cur;

        -- ========================================
        -- A-11.�K����уf�[�^CSV�o��
        -- ========================================
        create_csv_rec(
          i_get_data_rec      =>  l_get_data_rec   -- �K����уf�[�^
         ,ov_errbuf           =>  lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
         ,ov_retcode          =>  lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
         ,ov_errmsg           =>  lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;

        /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
        -- ���n�A�g�G���[�X�e�[�^�X��'Y'�̏ꍇ
        IF (l_get_vst_rslt_dt_rec.attribute15 = cv_yes ) THEN
          -- ========================================
          -- A-15.�^�X�N�f�[�^�X�V
          -- ========================================
          update_task(
            in_task_id          =>  l_get_vst_rslt_dt_rec.task_id     --�^�X�NID
           ,in_obj_ver_num      =>  l_get_vst_rslt_dt_rec.obj_ver_num  --�I�u�W�F�N�g�o�[�W�����ԍ�
           ,iv_attribute15      =>  TO_CHAR(ld_process_date,'YYYYMMDD')-- DFF15
           ,ov_errbuf           =>  lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
           ,ov_retcode          =>  lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
           ,ov_errmsg           =>  lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE update_skip_data_expt;
          END IF;
          --
        END IF;
        /* 2009.10.23 D.Abe E_T4_00056�Ή� END */

        -- �����������J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- �擾���s�̂��߃X�L�b�v
        WHEN error_skip_data_expt THEN
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        -- �G���[�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- *** DEBUG_LOG ***
        -- �f�[�^�X�L�b�v�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_skip  || CHR(10) ||
                     lv_errbuf          || CHR(10) ||
                     ''
        );
        /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
        -- ========================================
        -- A-15.�^�X�N�f�[�^�X�V
        -- ========================================
        update_task(
          in_task_id          =>  l_get_vst_rslt_dt_rec.task_id     --�^�X�NID
         ,in_obj_ver_num      =>  l_get_vst_rslt_dt_rec.obj_ver_num  --�I�u�W�F�N�g�o�[�W�����ԍ�
         ,iv_attribute15      =>  cv_yes           -- DFF15
         ,ov_errbuf           =>  lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
         ,ov_retcode          =>  lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
         ,ov_errmsg           =>  lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          -- �G���[�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
          -- ��s�̑}��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          -- *** DEBUG_LOG ***
          -- �f�[�^�X�L�b�v�������Ƃ����O�o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_debug_msg_skip2 || CHR(10) ||
                       lv_errbuf          || CHR(10) ||
                       ''
          );
        END IF;
        /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
        -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
        ov_retcode := cv_status_warn;
--
        /* 2009.10.07 D.Abe 0001454�Ή� START */
        -- MC�K��̂��߃X�L�b�v
        WHEN status_skip_data_expt THEN
        -- �X�L�b�v�����J�E���g
        gn_skip_cnt := gn_skip_cnt + 1;
        -- *** DEBUG_LOG ***
        -- �f�[�^�X�L�b�v�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_skip1 || CHR(10) ||
                     cv_debug_msg18 || l_get_vst_rslt_dt_rec.task_id || CHR(10) ||
                     cv_debug_msg19 || l_get_vst_rslt_dt_rec.source_object_id || CHR(10) ||
                     cv_debug_msg20 || l_get_vst_rslt_dt_rec.attribute14 || CHR(10) ||
                     cv_debug_msg21 || TO_CHAR(l_get_vst_rslt_dt_rec.actual_end_date ,'yyyymmdd')|| CHR(10) ||
                     ''
        );
        /* 2009.10.07 D.Abe 0001454�Ή� END */
--      
        /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� START */
        -- �ڋq�}�X�^�s���̂��߃X�L�b�v
        WHEN cust_error_skip_expt THEN
          -- �G���[�����J�E���g
          gn_error_cnt := gn_error_cnt + 1;
          -- �G���[�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
          -- *** DEBUG_LOG ***
          -- �f�[�^�X�L�b�v�������Ƃ����O�o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_debug_msg_skip3 || CHR(10) ||
                     cv_debug_msg18 || l_get_vst_rslt_dt_rec.task_id || CHR(10) ||
                     cv_debug_msg19 || l_get_vst_rslt_dt_rec.source_object_id || CHR(10) ||
                     cv_debug_msg20 || l_get_vst_rslt_dt_rec.attribute14 || CHR(10) ||
                     cv_debug_msg21 || TO_CHAR(l_get_vst_rslt_dt_rec.actual_end_date ,'yyyymmdd')|| CHR(10) ||
                     ''
          );
          -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
          ov_retcode := cv_status_warn;
        /* 2009.12.02 T.Maruyama E_�{�ғ�_00081�Ή� END */
--
        /* 2009.10.23 D.Abe E_T4_00056�Ή� START */
--
        -- �^�X�N�X�V�G���[�̂��߃X�L�b�v
        WHEN update_skip_data_expt THEN
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        -- *** DEBUG_LOG ***
        -- �f�[�^�X�L�b�v�������Ƃ����O�o��
        -- �G���[�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
        );
          -- ��s�̑}��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        -- *** DEBUG_LOG ***
        -- �f�[�^�X�L�b�v�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_skip2 || CHR(10) ||
                     lv_errbuf          || CHR(10) ||
                     ''
        );
        -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
        ov_retcode := cv_status_warn;
        /* 2009.10.23 D.Abe E_T4_00056�Ή� END */
--
      END;
--
    END LOOP get_vst_rslt_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_vst_rslt_data_cur;
--
    -- ========================================
    -- A-12.CSV�t�@�C���N���[�Y����
    -- ========================================
    close_csv_file(
      iv_csv_dir    => lv_csv_dir       -- CSV�t�@�C���o�͐�
     ,iv_csv_nm     => lv_csv_nm        -- CSV�t�@�C����
     ,ov_errbuf     => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode    => lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg     => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_vst_rslt_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_vst_rslt_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_lst_vst_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_lst_vst_dt_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_vst_rslt_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_vst_rslt_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_lst_vst_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_lst_vst_dt_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_vst_rslt_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_vst_rslt_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_lst_vst_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_lst_vst_dt_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_from_value IN  VARCHAR2           --   �p�����[�^�X�V�� FROM
    ,iv_to_value   IN  VARCHAR2           --   �p�����[�^�X�V�� TO
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
       iv_from_value  => iv_from_value
      ,iv_to_value    => iv_to_value
      ,ov_errbuf      => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-8.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    /* 2009.10.07 D.Abe 0001454�Ή� START */
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    /* 2009.10.07 D.Abe 0001454�Ή� END */
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO016A04C;
/
