CREATE OR REPLACE PACKAGE BODY APPS.XXCSO013A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO013A01C(body)
 * Description      : ���̋@�Ǘ��V�X�e�����ł̈��g�̊�����A�ڋq�X�e�[�^�X���x�~�ɂ��܂��B
 *                    �܂��A���̋@-EBS�C���^�t�F�[�X�F(IN)�����}�X�^���(IB)�ɂ�
 *                    �ڋq�X�e�[�^�X���u�ڋq�v�ɂ��邱�Ƃ��ł��Ȃ������ꍇ�̃��J�o���Ƃ��āA
 *                    �ڋq�l�������ݒ肳��Ă��āA�ڋq�X�e�[�^�X���u���F�ρv�̏ꍇ�A
 *                    �ڋq�X�e�[�^�X���u�ڋq�v�ɍX�V���܂��B
 * MD.050           : MD050_CSO_013_A01_CSI��AR�C���^�t�F�[�X�F�iOUT�j�ڋq�}�X�^
 *
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_profile_info       �v���t�@�C���l�擾(A-2)
 *  get_cust_status        �ڋq�X�e�[�^�X���o(A-3)
 *  chk_ib_info            �������݃`�F�b�N����(A-5)
 *  get_cust_info          �ڋq��񒊏o����(A-6)
 *  chk_cust_ib            �ݒu��ڋq�E�����`�F�b�N����(A-7)
 *  update_cust_status     �ڋq�X�e�[�^�X�X�V����(A-9)
 *  work_data_lock         ��ƃf�[�^���b�N����(A-11)
 *  update_work_data       ��ƃf�[�^�X�V����(A-12)
 *  upd_xxcmm_cust_acnts   �ڋq�A�h�I���}�X�^�X�V����(A-15)
 *  submain                ���C�������v���V�[�W��
 *                           ��ƃf�[�^���o(A-4)
 *                           �Z�[�u�|�C���g�ݒ�(A-8)
 *                           �Z�[�u�|�C���g�Q�ݒ�(A-10)
 *                           �ڋq��񒊏o(A-13)
 *                           �Z�[�u�|�C���g�R�ݒ�(A-14)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-16)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-17    1.0   Noriyuki.Yabuki  �V�K�쐬
 *  2009-03-12    1.1   Daisuke.Abe      �ύX�˗�:IE_108�Ή�
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-07    1.3   Tomoko.Mori      �yT1_0439�Ή��z���̋@�̂݌ڋq�֘A���X�V
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO013A01C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cv_app_name_xxccp      CONSTANT VARCHAR2(5)   := 'XXCCP';         -- �A�v���P�[�V�����Z�k���i�A�h�I���F���ʁEIF�̈�j
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^���o�G���[���b�Z�[�W�i��ƃf�[�^�A�ڋq�j
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00056';  -- �������݃`�F�b�N�x�����b�Z�[�W
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00541';  -- �����}�X�^���o�G���[���b�Z�[�W�i�������݃`�F�b�N�j
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00385';  -- �����G���[���b�Z�[�W�i�ڋq��񒊏o�j
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00241';  -- ���b�N�G���[���b�Z�[�W
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00058';  -- �ڋq�E�����`�F�b�N�x��
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00534';  -- �����}�X�^���o�G���[���b�Z�[�W�i�ݒu��ڋq�E�����`�F�b�N�j
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00235';  -- �����G���[���b�Z�[�W�i�ڋq�X�e�[�^�X�X�V�j
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00169';  -- �ڋq�X�e�[�^�X�x�����b�Z�[�W
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00234';  -- �����������b�Z�[�W
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- �f�[�^���o�G���[���b�Z�[�W�i�p�[�e�B�}�X�^�A�ڋq�A�h�I���}�X�^�j
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00284';  -- �ڋq�X�e�[�^�X�X�V�������b�Z�[�W
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00285';  -- �ڋq�X�e�[�^�X�X�V�G���[���b�Z�[�W
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00321';  -- ��ƃf�[�^�����G���[���b�Z�[�W�i���b�N�G���[�j
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00322';  -- ��ƃf�[�^�����G���[���b�Z�[�W�i���o�A�X�V�j
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00385';  -- �����G���[���b�Z�[�W�i�ڋq�A�h�I���}�X�^�X�V�j
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00542';  -- �x�~�������b�Z�[�W
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00543';  -- ���F�ρ��ڋq�������b�Z�[�W
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00544';  -- �ڋq���Ȃ��x�����b�Z�[�W
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00545';  -- �Q�ƃ^�C�v���e�擾�G���[���b�Z�[�W
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00253';  -- �Q�ƃ^�C�v���o�G���[���b�Z�[�W
  --
  cv_tkn_num_xxccp_01    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  --
  -- �g�[�N���R�[�h
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_bukken          CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_kokyaku         CONSTANT VARCHAR2(20) := 'KOKYAKU';
  cv_tkn_action          CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_api_errmsg      CONSTANT VARCHAR2(20) := 'API_ERR_MSG';
  cv_tkn_task_nm         CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_slip_num        CONSTANT VARCHAR2(20) := 'SLIP_NUM';
  cv_tkn_slip_branch_num CONSTANT VARCHAR2(20) := 'SLIP_BRANCH_NUM';
  cv_tkn_line_num        CONSTANT VARCHAR2(20) := 'LINE_NUM';
  cv_tkn_account_id      CONSTANT VARCHAR2(20) := 'ACCOUNT_ID';
  cv_tkn_lookup_type_nm  CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  --
  -- �g�[�N���l
  cv_tkn_val_cust_info       CONSTANT VARCHAR2(30) := '�ڋq���';
  cv_tkn_val_wk_data_tbl     CONSTANT VARCHAR2(30) := '��ƃf�[�^�e�[�u��';
  cv_tkn_val_selection       CONSTANT VARCHAR2(30) := '���o';
  cv_tkn_val_lock            CONSTANT VARCHAR2(30) := '���b�N';
  cv_tkn_val_update          CONSTANT VARCHAR2(30) := '�X�V';
  cv_tkn_val_cust_sts        CONSTANT VARCHAR2(30) := '�ڋq�X�e�[�^�X';
  cv_tkn_val_upd_suspnd_sts  CONSTANT VARCHAR2(30) := '�X�V�i�ڋq���x�~�j';
  cv_tkn_val_upd_cust_sts    CONSTANT VARCHAR2(30) := '�X�V�i���F�ρ��ڋq�j';
  cv_tkn_val_party_mst       CONSTANT VARCHAR2(30) := '�p�[�e�B�}�X�^';
  cv_tkn_val_party_id        CONSTANT VARCHAR2(30) := '�p�[�e�BID';
  cv_tkn_val_cust_addon_mst  CONSTANT VARCHAR2(30) := '�ڋq�A�h�I���}�X�^';
  cv_tkn_val_cust_cd         CONSTANT VARCHAR2(30) := '�ڋq�R�[�h';
  cv_tkn_val_lkup_type       CONSTANT VARCHAR2(30) := '�Q�ƃ^�C�v';
  --
  -- �����敪
  cv_proc_kbn1               CONSTANT VARCHAR2(1) := '1';
  cv_proc_kbn2               CONSTANT VARCHAR2(1) := '2';
  -- �Ƒԁi�����ށj
  cv_business_low_type24               CONSTANT VARCHAR2(2) := '24';
  cv_business_low_type25               CONSTANT VARCHAR2(2) := '25';
  cv_business_low_type27               CONSTANT VARCHAR2(2) := '27';
  --
  -- ���̑�
  cv_true                    CONSTANT VARCHAR2(10) := 'TRUE';    -- ���ʊ֐��߂�l����p
  cv_false                   CONSTANT VARCHAR2(10) := 'FALSE';   -- ���ʊ֐��߂�l����p
  cv_suspend_proc_end        CONSTANT VARCHAR2(1) := '2';        -- �x�~�����σt���O�i�����ρj
  cv_suspend_proc_unprc      CONSTANT VARCHAR2(1) := '1';        -- �x�~�����σt���O�i�������j
  cv_job_kbn_withdraw        CONSTANT VARCHAR2(1) := '5';        -- ��Ƌ敪�i���g�j
  cv_completion_kbn_cmplt    CONSTANT VARCHAR2(1) := '1';        -- �����敪�i�����j
  cv_install2_proc_end       CONSTANT VARCHAR2(1) := 'Y';        -- �����Q�����σt���O�i�����ρj
  cv_withdrawal_type_nrml    CONSTANT VARCHAR2(1) := '1';        -- ���g�敪�i���g�j
  cv_category_kbn_withdraw   CONSTANT VARCHAR2(2) := '50';       -- �J�e�S���敪�i���g�j
  cv_case_arc_left           CONSTANT VARCHAR2(1)  := '(';
  cv_case_arc_right          CONSTANT VARCHAR2(1)  := ')';
  cv_msg_equal               CONSTANT VARCHAR2(1)  := '=';
/*20090507_mori_T1_0439 START*/
  cv_instance_type_vd        CONSTANT VARCHAR2(1) := '1';        -- �C���X�^���X�X�e�[�^�X�^�C�v�i���̋@�j
  cv_cust_upd_y              CONSTANT VARCHAR2(1) := 'Y';        -- �ڋq���X�V�t���O�i�X�V����j
  cv_cust_upd_n              CONSTANT VARCHAR2(1) := 'N';        -- �ڋq���X�V�t���O�i�X�V���Ȃ��j
/*20090507_mori_T1_0439 END*/
  --
  -- LOG�p���b�Z�[�W
  cv_log_msg1          CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_log_msg2          CONSTANT VARCHAR2(200) := 'od_process_date = ';
  cv_log_msg3          CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_log_msg4          CONSTANT VARCHAR2(200) := 'lv_cust_sts_suspended = ';
  cv_log_msg5          CONSTANT VARCHAR2(200) := 'lv_cust_sts_approved  = ';
  cv_log_msg6          CONSTANT VARCHAR2(200) := 'lv_cust_sts_customer  = ';
  cv_log_msg7          CONSTANT VARCHAR2(200) := 'lv_req_sts_approved   = ';
  cv_log_msg8          CONSTANT VARCHAR2(200) := 'lv_org_id = ' ;
  cv_log_msg9          CONSTANT VARCHAR2(200) := '<< �ڋq�X�e�[�^�X���o���� >>';
  cv_log_msg10         CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>';
  cv_log_msg_copn1     CONSTANT VARCHAR2(200) := '<< ��ƃf�[�^���o�J�[�\�����I�[�v�����܂��� >>';
  cv_log_msg_copn2     CONSTANT VARCHAR2(200) := '<< �ڋq��񒊏o�J�[�\�����I�[�v�����܂��� >>';
  cv_log_msg_ccls1     CONSTANT VARCHAR2(200) := '<< ��ƃf�[�^���o�J�[�\�����N���[�Y���܂��� >>';
  cv_log_msg_ccls2     CONSTANT VARCHAR2(200) := '<< �ڋq��񒊏o�J�[�\�����N���[�Y���܂��� >>';
  cv_log_msg_ccls1_ex  CONSTANT VARCHAR2(200) := '<< ��O�������ō�ƃf�[�^���o�J�[�\�����N���[�Y���܂��� >>';
  cv_log_msg_ccls2_ex  CONSTANT VARCHAR2(200) := '<< ��O�������Ōڋq��񒊏o�J�[�\�����N���[�Y���܂��� >>';
  cv_log_msg_err1      CONSTANT VARCHAR2(200) := 'process_warn_expt';
  cv_log_msg_err2      CONSTANT VARCHAR2(200) := 'global_process_expt';
  cv_log_msg_err3      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_log_msg_err4      CONSTANT VARCHAR2(200) := 'others��O';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���F�ρ��ڋq�����p
  gn_target_cnt2    NUMBER;    -- �Ώی���
  gn_normal_cnt2    NUMBER;    -- ���팏��
  gn_error_cnt2     NUMBER;    -- �G���[����
  gn_warn_cnt2      NUMBER;    -- �X�L�b�v����
/*20090507_mori_T1_0439 START*/
  gv_cust_upd_flg   VARCHAR2(1);  -- �ڋq���X�V�t���O
/*20090507_mori_T1_0439 END*/
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ��ƃf�[�^�i�[�v���R�[�h�^��`
  TYPE g_work_data_rtype IS RECORD(
      slip_no           xxcso_in_work_data.slip_no%TYPE          -- �`�[No
    , slip_branch_no    xxcso_in_work_data.slip_branch_no%TYPE   -- �`�[�}��
    , line_number       xxcso_in_work_data.line_number%TYPE      -- �s�ԍ�
    , install_code      xxcso_in_work_data.install_code2%TYPE    -- �����R�[�h
    , account_number    xxcso_in_work_data.account_number2%TYPE  -- �ڋq�R�[�h
    , actual_work_date  xxcso_in_work_data.actual_work_date%TYPE -- ����Ɠ�
  /*20090507_mori_T1_0439 START*/
    , instance_type_code  csi_item_instances.instance_type_code%TYPE -- �C���X�^���X�^�C�v�R�[�h
  /*20090507_mori_T1_0439 END*/
  );
  --
  -- �ڋq���i�[�p���R�[�h�^��`
  TYPE g_cust_rtype IS RECORD(
      object_version_number    hz_parties.object_version_number%TYPE  -- �I�u�W�F�N�g�o�[�W�����ԍ�
    , party_id                 hz_parties.party_id%TYPE               -- �p�[�e�BID
    , account_number           hz_cust_accounts.account_number%TYPE   -- �ڋq�R�[�h
    , cust_account_id          hz_cust_accounts.cust_account_id%TYPE  -- �A�J�E���gID
    , cnvs_date                xxcso_cust_accounts_v.cnvs_date%TYPE   -- �ڋq�l����
    , party_name               hz_parties.party_name%TYPE             -- �ڋq��
    , duns_number_c            hz_parties.duns_number_c%TYPE          -- DUNS�ԍ��i�ڋq�X�e�[�^�X�j
  );
  -- ===============================
  -- ���[�U�[��`�O���[�o����O
  -- ===============================
  global_lock_expt        EXCEPTION;    -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      od_process_date  OUT        DATE      -- �Ɩ��������t
    , ov_errbuf        OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg        OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100)  := 'init';    -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
--
    -- =====================
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    -- =====================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_name_xxccp    -- �A�v���P�[�V�����Z�k��
                   , iv_name        => cv_tkn_num_xxccp_01  -- ���b�Z�[�W�R�[�h
                 );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg
    );
    --
    -- =====================
    -- �Ɩ��������t�擾����
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg1 || CHR(10) ||
                 cv_log_msg2 || TO_CHAR( od_process_date, 'YYYY/MM/DD HH24:MI:SS' ) || CHR(10) ||
                 ''
    );
    --
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF ( od_process_date IS NULL ) THEN
      -- ��s�̑}��
      fnd_file.put_line(
          which => FND_FILE.OUTPUT
        , buff  => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_app_name       -- �A�v���P�[�V�����Z�k��
                     , iv_name        => cv_tkn_number_01  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
      ov_cust_sts_suspended  OUT NOCOPY VARCHAR2  -- �ڋq�X�e�[�^�X�i�x�~�j
    , ov_cust_sts_approved   OUT NOCOPY VARCHAR2  -- �ڋq�X�e�[�^�X�i���F�ρj
    , ov_cust_sts_customer   OUT NOCOPY VARCHAR2  -- �ڋq�X�e�[�^�X�i�ڋq�j
    , ov_req_sts_approved    OUT NOCOPY VARCHAR2  -- �����˗��X�e�[�^�X�R�[�h�i���F�ρj
    , ov_org_id              OUT NOCOPY VARCHAR2  -- �I���OID
    , ov_errbuf              OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode             OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg              OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_profile_info';  -- �v���O������
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
    -- XXCSO:�ڋq�X�e�[�^�X�i�x�~�j
    cv_cust_sts_suspended    CONSTANT VARCHAR2(30) := 'XXCSO1_CUST_STATUS_SUSPENDED';
    -- XXCSO:�ڋq�X�e�[�^�X�i���F�ρj
    cv_cust_sts_approved     CONSTANT VARCHAR2(30) := 'XXCSO1_CUST_STATUS_APPROVED';
    -- XXCSO:�ڋq�X�e�[�^�X�i�ڋq�j
    cv_cust_sts_customer     CONSTANT VARCHAR2(30) := 'XXCSO1_CUST_STATUS_CUSTOMER';
    -- XXCSO:�����˗��X�e�[�^�X�R�[�h�i���F�ρj
    cv_req_sts_approved      CONSTANT VARCHAR2(30) := 'XXCSO1_PO_REQ_STATUS_CD_APRVD';
    -- MO:�c�ƒP��
    cv_org_id                CONSTANT VARCHAR2(30) := 'ORG_ID';
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C���l�擾�߂�l�i�[�p
    lv_cust_sts_suspended    VARCHAR2(2000);  -- �ڋq�X�e�[�^�X�i�x�~�j
    lv_cust_sts_approved     VARCHAR2(2000);  -- �ڋq�X�e�[�^�X�i���F�ρj
    lv_cust_sts_customer     VARCHAR2(2000);  -- �ڋq�X�e�[�^�X�i�ڋq�j
    lv_req_sts_approved      VARCHAR2(2000);  -- �����˗��X�e�[�^�X�R�[�h�i���F�ρj
    lv_org_id                VARCHAR2(2000);  -- �I���OID
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value             VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg_fnm               VARCHAR2(5000);
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
    -- �ڋq�X�e�[�^�X�i�x�~�j
    FND_PROFILE.GET(
        name => cv_cust_sts_suspended
      , val  => lv_cust_sts_suspended
    );
    --
    -- �ڋq�X�e�[�^�X�i���F�ρj
    FND_PROFILE.GET(
        name => cv_cust_sts_approved
      , val  => lv_cust_sts_approved
    );
    --
    -- �ڋq�X�e�[�^�X�i�ڋq�j
    FND_PROFILE.GET(
        name => cv_cust_sts_customer
      , val  => lv_cust_sts_customer
    );
    --
    -- �����˗��X�e�[�^�X�R�[�h�i���F�ρj
    FND_PROFILE.GET(
        name => cv_req_sts_approved
      , val  => lv_req_sts_approved
    );
    --
    -- �I���OID
    FND_PROFILE.GET(
        name => cv_org_id
      , val  => lv_org_id
    );
--
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg3 || CHR(10) ||
                 cv_log_msg4 || lv_cust_sts_suspended || CHR(10) ||
                 cv_log_msg5 || lv_cust_sts_approved  || CHR(10) ||
                 cv_log_msg6 || lv_cust_sts_customer  || CHR(10) ||
                 cv_log_msg7 || lv_req_sts_approved   || CHR(10) ||
                 cv_log_msg8 || lv_org_id             || CHR(10) ||
                 ''
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- �ڋq�X�e�[�^�X�i�x�~�j�擾���s��
    IF ( lv_cust_sts_suspended IS NULL ) THEN
      lv_tkn_value := cv_cust_sts_suspended;
      --
    -- �ڋq�X�e�[�^�X�i���F�ρj�擾���s��
    ELSIF ( lv_cust_sts_approved IS NULL ) THEN
      lv_tkn_value := cv_cust_sts_approved;
      --
    -- �ڋq�X�e�[�^�X�i�ڋq�j�擾���s��
    ELSIF ( lv_cust_sts_customer IS NULL ) THEN
      lv_tkn_value := cv_cust_sts_customer;
      --
    -- �����˗��X�e�[�^�X�R�[�h�i���F�ρj�擾���s��
    ELSIF ( lv_req_sts_approved IS NULL ) THEN
      lv_tkn_value := cv_req_sts_approved;
      --
    -- �I���OID�擾���s��
    ELSIF ( lv_org_id IS NULL ) THEN
      lv_tkn_value := cv_org_id;
      --
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF ( lv_tkn_value IS NOT NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_02  -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_prof_nm    -- �g�[�N���R�[�h1
                     , iv_token_value1 => lv_tkn_value      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_cust_sts_suspended := lv_cust_sts_suspended;  -- �ڋq�X�e�[�^�X�i�x�~�j
    ov_cust_sts_approved  := lv_cust_sts_approved;   -- �ڋq�X�e�[�^�X�i���F�ρj
    ov_cust_sts_customer  := lv_cust_sts_customer;   -- �ڋq�X�e�[�^�X�i�ڋq�j
    ov_req_sts_approved   := lv_req_sts_approved;    -- �����˗��X�e�[�^�X�R�[�h�i���F�ρj
    ov_org_id             := lv_org_id;              -- �I���OID
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_status
   * Description      : �ڋq�X�e�[�^�X���o(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_status(
      it_cust_status_nm  IN         fnd_lookup_values_vl.meaning%TYPE  -- �ڋq�X�e�[�^�X��
    , id_process_date    IN         DATE                               -- �Ɩ��������t
    , ot_cust_status_cd  OUT NOCOPY hz_parties.duns_number_c%TYPE      -- �ڋq�X�e�[�^�X
    , ov_errbuf          OUT NOCOPY VARCHAR2                           -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2                           -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg          OUT NOCOPY VARCHAR2                           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_status';  -- �v���O������
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
    cv_lkup_tp_cust_status  CONSTANT VARCHAR2(30) := 'XXCMM_CUST_KOKYAKU_STATUS';
    cv_enabled_flag_yes     CONSTANT VARCHAR2(1)  := 'Y';
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    sql_expt    EXCEPTION;
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
    -- ====================================
    -- �ڋq�X�e�[�^�X���o
    -- ====================================
    BEGIN
      SELECT flvl.lookup_code  lookup_code    -- �R�[�h�i�ڋq�X�e�[�^�X�j
      INTO   ot_cust_status_cd                -- �R�[�h�i�ڋq�X�e�[�^�X�j
      FROM   fnd_lookup_values_vl  flvl       -- �N�C�b�N�R�[�h�r���[
      WHERE  flvl.lookup_type  = cv_lkup_tp_cust_status    -- �^�C�v
      AND    flvl.meaning      = it_cust_status_nm         -- ���e
      AND    TRUNC( id_process_date )
               BETWEEN TRUNC( NVL( flvl.start_date_active, id_process_date ) )  -- �L���J�n��
               AND     TRUNC( NVL( flvl.end_date_active, id_process_date ) )    -- �L���I����
      AND    flvl.enabled_flag = cv_enabled_flag_yes                            -- �g�p�\�t���O
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                                  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_22                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_task_nm                               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_lkup_type                         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_lookup_type_nm                        -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_cust_sts || cv_case_arc_left
                                              || it_cust_status_nm || cv_case_arc_right  -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                                  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_23                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_task_nm                               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_lkup_type                         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_lookup_type_nm                        -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_cust_sts || cv_case_arc_left
                                              || it_cust_status_nm || cv_case_arc_right  -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_errmsg                                -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
  EXCEPTION
    -- *** SQL��O�n���h�� ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cust_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_ib_info
   * Description      : �������݃`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE chk_ib_info(
      i_work_data_rec  IN         g_work_data_rtype    -- ��ƃf�[�^���
    , ov_errbuf        OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg        OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_ib_info';  -- �v���O������
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
    ln_cnt      NUMBER;
    --
    -- *** ���[�J����O ***
    sql_expt    EXCEPTION;
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      SELECT COUNT(0)  cnt    -- ����
      INTO  ln_cnt            -- ����
      FROM  csi_item_instances  cii    -- �C���X�g�[���x�[�X�}�X�^�i�����}�X�^�j
      WHERE cii.external_reference = i_work_data_rec.install_code  -- �O���Q�Ɓi�����R�[�h�j
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_05                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_slip_num                 -- �g�[�N���R�[�h1
                       , iv_token_value1 => i_work_data_rec.slip_no         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_work_data_rec.slip_branch_no  -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_line_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.line_number     -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_bukken                   -- �g�[�N���R�[�h4
                       , iv_token_value4 => i_work_data_rec.install_code    -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_errmsg                   -- �g�[�N���R�[�h5
                       , iv_token_value5 => SQLERRM                         -- �g�[�N���l5
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
    IF ln_cnt = 0 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_04                -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_bukken                   -- �g�[�N���R�[�h1
                     , iv_token_value1 => i_work_data_rec.install_code    -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_slip_num                 -- �g�[�N���R�[�h2
                     , iv_token_value2 => i_work_data_rec.slip_no         -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h3
                     , iv_token_value3 => i_work_data_rec.slip_branch_no  -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_line_num                 -- �g�[�N���R�[�h4
                     , iv_token_value4 => i_work_data_rec.line_number     -- �g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
      RAISE sql_expt;
      --
    END IF;
--
  EXCEPTION
    -- *** SQL��O�n���h�� ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_ib_info;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_info
   * Description      : �ڋq��񒊏o����(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_info(
      i_work_data_rec  IN         g_work_data_rtype    -- ��ƃf�[�^���
    , iv_cust_status   IN         VARCHAR2             -- �ڋq�X�e�[�^�X
    , o_cust_rec       OUT NOCOPY g_cust_rtype         -- �ڋq���
    , ov_errbuf        OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg        OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_info';  -- �v���O������
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
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    sql_expt    EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      SELECT hca.cust_account_id        cust_account_id        -- �A�J�E���gID
           , hca.account_number         account_number         -- �ڋq�R�[�h
           , hpa.object_version_number  object_version_number  -- �I�u�W�F�N�g�o�[�W�����ԍ�
           , hpa.party_id               party_id               -- �p�[�e�BID
           , hpa.party_name             party_name             -- �ڋq��
           , hpa.duns_number_c          duns_number_c          -- DUNS�ԍ��i�ڋq�X�e�[�^�X�j
      INTO  o_cust_rec.cust_account_id        -- �A�J�E���gID
          , o_cust_rec.account_number         -- �ڋq�R�[�h
          , o_cust_rec.object_version_number  -- �I�u�W�F�N�g�o�[�W�����ԍ�
          , o_cust_rec.party_id               -- �p�[�e�BID
          , o_cust_rec.party_name             -- �ڋq��
          , o_cust_rec.duns_number_c          -- DUNS�ԍ��i�ڋq�X�e�[�^�X�j
      FROM  hz_cust_accounts  hca    -- �ڋq�}�X�^
          , hz_parties               hpa    -- �p�[�e�B�}�X�^
      WHERE hca.party_id       = hpa.party_id                    -- �p�[�e�BID
      AND   hca.account_number = i_work_data_rec.account_number  -- �ڋq�R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_21                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_slip_num                 -- �g�[�N���R�[�h1
                       , iv_token_value1 => i_work_data_rec.slip_no         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_work_data_rec.slip_branch_no  -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_line_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.line_number     -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h4
                       , iv_token_value4 => i_work_data_rec.account_number  -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_06                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_cust_info            -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_action                   -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_selection            -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_slip_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_line_num                 -- �g�[�N���R�[�h5
                       , iv_token_value5 => i_work_data_rec.line_number     -- �g�[�N���l5
                       , iv_token_name6  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h6
                       , iv_token_value6 => i_work_data_rec.account_number  -- �g�[�N���l6
                       , iv_token_name7  => cv_tkn_errmsg                   -- �g�[�N���R�[�h7
                       , iv_token_value7 => SQLERRM                         -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
    -- �ڋq�X�e�[�^�X�̃`�F�b�N
    IF o_cust_rec.duns_number_c <> iv_cust_status THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_11                -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_slip_num                 -- �g�[�N���R�[�h1
                     , iv_token_value1 => i_work_data_rec.slip_no         -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h2
                     , iv_token_value2 => i_work_data_rec.slip_branch_no  -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_line_num                 -- �g�[�N���R�[�h3
                     , iv_token_value3 => i_work_data_rec.line_number     -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h4
                     , iv_token_value4 => i_work_data_rec.account_number  -- �g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
      RAISE sql_expt;
    END IF;
--
  EXCEPTION
    -- *** SQL��O�n���h�� ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_cust_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_cust_ib
   * Description      : �ݒu��ڋq�E�����`�F�b�N����(A-7)
   ***********************************************************************************/
  PROCEDURE chk_cust_ib(
      i_work_data_rec  IN         g_work_data_rtype    -- ��ƃf�[�^���
    , in_acnt_id       IN         NUMBER               -- �A�J�E���gID
    , ov_errbuf        OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg        OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cust_ib';  -- �v���O������
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
    --
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER;
    --
    -- *** ���[�J����O ***
    sql_expt    EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      SELECT COUNT(0)  cnt  -- ����
      INTO  ln_cnt          -- ����
      FROM  csi_item_instances  cii  -- �C���X�g�[���x�[�X�}�X�^�i�����}�X�^�j
      WHERE cii.owner_party_account_id  =  in_acnt_id                    -- ���L�҃A�J�E���gID�i�A�J�E���gID�j
    /*20090507_mori_T1_0439 START*/
--      AND   cii.external_reference      <> i_work_data_rec.install_code  -- �O���Q�Ɓi�����R�[�h�j
    /*20090507_mori_T1_0439 END*/
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_09                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_slip_num                 -- �g�[�N���R�[�h1
                       , iv_token_value1 => i_work_data_rec.slip_no         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_work_data_rec.slip_branch_no  -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_line_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.line_number     -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_account_id               -- �g�[�N���R�[�h4
                       , iv_token_value4 => in_acnt_id                      -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_errmsg                   -- �g�[�N���R�[�h5
                       , iv_token_value5 => SQLERRM                         -- �g�[�N���l5
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
    -- ���o������0���傫���ꍇ
    IF ln_cnt > 0 THEN
    /*20090507_mori_T1_0439 START*/
      gv_cust_upd_flg := cv_cust_upd_n;
    /*20090507_mori_T1_0439 END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                       -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_08                  -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_kokyaku                    -- �g�[�N���R�[�h1
                     , iv_token_value1 => i_work_data_rec.account_number    -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_bukken                     -- �g�[�N���R�[�h2
                     , iv_token_value2 => i_work_data_rec.install_code      -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_slip_num                   -- �g�[�N���R�[�h3
                     , iv_token_value3 => i_work_data_rec.slip_no           -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_slip_branch_num            -- �g�[�N���R�[�h4
                     , iv_token_value4 => i_work_data_rec.slip_branch_no    -- �g�[�N���l4
                     , iv_token_name5  => cv_tkn_line_num                   -- �g�[�N���R�[�h5
                     , iv_token_value5 => i_work_data_rec.line_number       -- �g�[�N���l5
                   );
      lv_errbuf := lv_errmsg;
        --
    /*20090507_mori_T1_0439 START*/
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      gv_cust_upd_flg := cv_cust_upd_n;
        -- �x�����e�����b�Z�[�W�A���O�֏o��
        fnd_file.put_line(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg    -- ���[�U�[�E�G���[���b�Z�[�W
        );
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => lv_errbuf    -- �G���[���b�Z�[�W
        );
--      RAISE sql_expt;
    /*20090507_mori_T1_0439 END*/
    END IF;
--
  EXCEPTION
    -- *** SQL��O�n���h�� ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_cust_ib;
--
  /**********************************************************************************
   * Procedure Name   : update_cust_status
   * Description      : �ڋq�X�e�[�^�X�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE update_cust_status(
      iv_proc_kbn       IN         VARCHAR2             -- �����敪
    , i_work_data_rec   IN         g_work_data_rtype    -- ��ƃf�[�^���
    , i_cust_rec        IN         g_cust_rtype         -- �ڋq���
    , iv_duns_number_c  IN         VARCHAR2             -- DUNS�ԍ��i�ڋq�X�e�[�^�X�j
    , ov_errbuf         OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode        OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg         OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cust_status';  -- �v���O������
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
    cv_encoded_false    CONSTANT VARCHAR2(1) := 'F';
    --
    -- *** ���[�J���ϐ� ***
    lv_init_msg_list     VARCHAR2(2000);    -- ���b�Z�[�W���X�g
    ln_obj_ver_num       NUMBER;            -- �I�u�W�F�N�g�o�[�W�����ԍ�
    --
    -- API���o�̓��R�[�h�l�i�[�p
    l_party_rec           hz_party_v2pub.party_rec_type;
    l_organization_rec    hz_party_v2pub.organization_rec_type;
    --
    -- �߂�l�i�[�p
    ln_profile_id       NUMBER;          -- �v���t�@�C��ID
    lv_return_status    VARCHAR2(10);    -- �߂�l�X�e�[�^�X
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(5000);
    ln_io_msg_count     NUMBER;
    lv_io_msg_data      VARCHAR2(5000);
    --
    -- *** ���[�J����O ***
    update_error_expt    EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�Z�[�W�X�^�b�N�̏�����
    FND_MSG_PUB.INITIALIZE;
    --
    -- �I�u�W�F�N�g�o�[�W�����ԍ��̐ݒ�
    ln_obj_ver_num := i_cust_rec.object_version_number;
    --
    -- �p�[�e�B���R�[�h�̍쐬
    l_party_rec.party_id := i_cust_rec.party_id;                      -- �p�[�e�BID
    --
    -- �ڋq��񃌃R�[�h�̍쐬
    l_organization_rec.organization_name := i_cust_rec.party_name;    -- �ڋq��
    l_organization_rec.duns_number_c     := iv_duns_number_c;         -- DUNS�ԍ��i�ڋq�X�e�[�^�X�j
    l_organization_rec.party_rec         := l_party_rec;              -- �p�[�e�B���R�[�h
    --
    -- �W��API���p�[�e�B�}�X�^���X�V����
    HZ_PARTY_V2PUB.UPDATE_ORGANIZATION(
        p_init_msg_list               => lv_init_msg_list
      , p_organization_rec            => l_organization_rec
      , p_party_object_version_number => ln_obj_ver_num
      , x_profile_id                  => ln_profile_id
      , x_return_status               => lv_return_status
      , x_msg_count                   => ln_msg_count
      , x_msg_data                    => lv_msg_data
    );
    --
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE update_error_expt;
      --
    END IF;
    --
    -- ========================================
    -- ����I���̏ꍇ
    -- ========================================
    IF iv_proc_kbn = cv_proc_kbn1 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_12                -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_table                    -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_tkn_val_cust_sts             -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_action                   -- �g�[�N���R�[�h2
                     , iv_token_value2 => cv_tkn_val_upd_suspnd_sts       -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_slip_num                 -- �g�[�N���R�[�h3
                     , iv_token_value3 => i_work_data_rec.slip_no         -- �g�[�N���l3
                     , iv_token_name4  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h4
                     , iv_token_value4 => i_work_data_rec.slip_branch_no  -- �g�[�N���l4
                     , iv_token_name5  => cv_tkn_line_num                 -- �g�[�N���R�[�h5
                     , iv_token_value5 => i_work_data_rec.line_number     -- �g�[�N���l5
                     , iv_token_name6  => cv_tkn_bukken                   -- �g�[�N���R�[�h6
                     , iv_token_value6 => i_work_data_rec.install_code    -- �g�[�N���l6
                     , iv_token_name7  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h7
                     , iv_token_value7 => i_work_data_rec.account_number  -- �g�[�N���l7
                   );
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_14           -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_tkn_val_cust_sts        -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_action              -- �g�[�N���R�[�h2
                     , iv_token_value2 => cv_tkn_val_upd_cust_sts    -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_kokyaku             -- �g�[�N���R�[�h3
                     , iv_token_value3 => i_cust_rec.account_number  -- �g�[�N���l3
                   );
    END IF;
    lv_errbuf := lv_errmsg;
--
    -- �ڋq�X�e�[�^�X�X�V�������b�Z�[�W�����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => lv_errmsg || CHR(10) ||
                 ''
    );
--
  EXCEPTION
    -- *** API�G���[�n���h�� ***
    WHEN update_error_expt THEN
      --
      IF ( FND_MSG_PUB.Count_Msg > 0 ) THEN
        FOR i IN 1..FND_MSG_PUB.COUNT_MSG LOOP
          FND_MSG_PUB.Get(
              p_msg_index     => i
            , p_encoded       => cv_encoded_false
            , p_data          => lv_io_msg_data
            , p_msg_index_out => ln_io_msg_count
          );
          lv_msg_data := lv_msg_data || lv_io_msg_data;
        END LOOP;
      END IF;
      IF iv_proc_kbn = cv_proc_kbn1 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_10                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_cust_sts             -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_action                   -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_upd_suspnd_sts       -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_slip_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_line_num                 -- �g�[�N���R�[�h5
                       , iv_token_value5 => i_work_data_rec.line_number     -- �g�[�N���l5
                       , iv_token_name6  => cv_tkn_bukken                   -- �g�[�N���R�[�h6
                       , iv_token_value6 => i_work_data_rec.install_code    -- �g�[�N���l6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h7
                       , iv_token_value7 => i_work_data_rec.account_number  -- �g�[�N���l7
                       , iv_token_name8  => cv_tkn_api_errmsg               -- �g�[�N���R�[�h8
                       , iv_token_value8 => lv_msg_data                     -- �g�[�N���l8
                     );
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_15           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_cust_sts        -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_action              -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_upd_cust_sts    -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_kokyaku             -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_cust_rec.account_number  -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_api_errmsg          -- �g�[�N���R�[�h4
                       , iv_token_value4 => lv_msg_data                -- �g�[�N���l4
                     );
      END IF;
      --
      lv_errbuf := lv_errmsg;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_cust_status;
--
  /**********************************************************************************
   * Procedure Name   : work_data_lock
   * Description      : ��ƃf�[�^���b�N����(A-11)
   ***********************************************************************************/
  PROCEDURE work_data_lock(
      i_work_data_rec    IN         g_work_data_rtype    -- ��ƃf�[�^���
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg          OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'work_data_lock';  -- �v���O������
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
    --
    -- *** ���[�J���ϐ� ***
    lt_slip_no    xxcso_in_work_data.slip_no%TYPE;
    --
    -- *** ���[�J����O ***
    sql_expt     EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      SELECT xiwd.slip_no  -- �`�[No
      INTO  lt_slip_no     -- �`�[No
      FROM  xxcso_in_work_data  xiwd  -- ��ƃf�[�^�e�[�u��
      WHERE xiwd.slip_no        = i_work_data_rec.slip_no         -- �`�[No
      AND   xiwd.slip_branch_no = i_work_data_rec.slip_branch_no  -- �`�[�}��
      AND   xiwd.line_number    = i_work_data_rec.line_number     -- �s�ԍ�
      FOR UPDATE NOWAIT
      ;
      --
    EXCEPTION
      -- *** ���b�N�Ɏ��s�����ꍇ ***
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_16                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_wk_data_tbl          -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_action                   -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_lock                 -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_slip_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_line_num                 -- �g�[�N���R�[�h5
                       , iv_token_value5 => i_work_data_rec.line_number     -- �g�[�N���l5
                       , iv_token_name6  => cv_tkn_bukken                   -- �g�[�N���R�[�h6
                       , iv_token_value6 => i_work_data_rec.install_code    -- �g�[�N���l6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h7
                       , iv_token_value7 => i_work_data_rec.account_number  -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
        --
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_17                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_wk_data_tbl          -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_action                   -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_selection            -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_slip_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_line_num                 -- �g�[�N���R�[�h5
                       , iv_token_value5 => i_work_data_rec.line_number     -- �g�[�N���l5
                       , iv_token_name6  => cv_tkn_bukken                   -- �g�[�N���R�[�h6
                       , iv_token_value6 => i_work_data_rec.install_code    -- �g�[�N���l6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h7
                       , iv_token_value7 => i_work_data_rec.account_number  -- �g�[�N���l7
                       , iv_token_name8  => cv_tkn_errmsg                   -- �g�[�N���R�[�h8
                       , iv_token_value8 => SQLERRM                         -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
  EXCEPTION
    -- *** SQL��O�n���h�� ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END work_data_lock;
--
  /**********************************************************************************
   * Procedure Name   : update_work_data
   * Description      : ��ƃf�[�^�X�V����(A-12)
   ***********************************************************************************/
  PROCEDURE update_work_data(
      i_work_data_rec    IN         g_work_data_rtype    -- ��ƃf�[�^���
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg          OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_work_data';  -- �v���O������
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
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    sql_expt     EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      UPDATE xxcso_in_work_data  xiwd  -- ��ƃf�[�^�e�[�u��
      SET   xiwd.suspend_processed_flag = cv_suspend_proc_end          -- �x�~�����σt���O
          , xiwd.last_updated_by        = cn_last_updated_by           -- �ŏI�X�V��
          , xiwd.last_update_date       = cd_last_update_date          -- �ŏI�X�V��
          , xiwd.last_update_login      = cn_last_update_login         -- �ŏI�X�V���O�C��
          , xiwd.request_id             = cn_request_id                -- �v��ID
          , xiwd.program_application_id = cn_program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , xiwd.program_id             = cn_program_id                -- �R���J�����g�E�v���O����ID
          , xiwd.program_update_date    = cd_program_update_date       -- �v���O�����X�V��
      WHERE xiwd.slip_no        = i_work_data_rec.slip_no         -- �`�[No
      AND   xiwd.slip_branch_no = i_work_data_rec.slip_branch_no  -- �`�[�}��
      AND   xiwd.line_number    = i_work_data_rec.line_number     -- �s�ԍ�
      ;
      --
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_17                -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_wk_data_tbl          -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_action                   -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_update               -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_slip_num                 -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- �g�[�N���R�[�h4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_line_num                 -- �g�[�N���R�[�h5
                       , iv_token_value5 => i_work_data_rec.line_number     -- �g�[�N���l5
                       , iv_token_name6  => cv_tkn_bukken                   -- �g�[�N���R�[�h6
                       , iv_token_value6 => i_work_data_rec.install_code    -- �g�[�N���l6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- �g�[�N���R�[�h7
                       , iv_token_value7 => i_work_data_rec.account_number  -- �g�[�N���l7
                       , iv_token_name8  => cv_tkn_errmsg                   -- �g�[�N���R�[�h8
                       , iv_token_value8 => SQLERRM                         -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
  EXCEPTION
    -- *** SQL��O�n���h�� ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_work_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_xxcmm_cust_acnts
   * Description      : �ڋq�A�h�I���}�X�^�X�V����(A-15)
   ***********************************************************************************/
  PROCEDURE upd_xxcmm_cust_acnts(
      iv_proc_kbn         IN         VARCHAR2        -- �����敪
    , i_cust_rec          IN         g_cust_rtype    -- �ڋq���
    , iv_duns_number_c    IN         VARCHAR2        -- DUNS�ԍ��i�ڋq�X�e�[�^�X�j
    , id_actual_work_date IN         DATE            -- ����Ɠ�
    , iv_account_number   IN         VARCHAR2        -- �ڋq�R�[�h
    , id_process_date     IN         DATE            -- �Ɩ��������t
    , ov_errbuf           OUT NOCOPY VARCHAR2        -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode          OUT NOCOPY VARCHAR2        -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg           OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxcmm_cust_acnts';  -- �v���O������
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
    --
    -- *** ���[�J���ϐ� ***
    lv_chk_rslt       VARCHAR2(10);
    ln_customer_id    NUMBER;
    --
    -- *** ���[�J����O ***
    sql_expt     EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================================
    -- 1.AR��v���ԃ`�F�b�N
    -- ========================================
    IF (iv_proc_kbn = cv_proc_kbn1) THEN
      --����Ɠ�
      lv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
                       id_standard_date => TO_DATE(id_actual_work_date)
                     );
    ELSE
      -- �ڋq�l����
      lv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
                       id_standard_date => i_cust_rec.cnvs_date
                     );
    END IF;
    --
    -- AR��v���Ԃ��N���[�Y�̏ꍇ
    IF ((iv_proc_kbn = cv_proc_kbn1 AND 
          TO_CHAR(id_actual_work_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
          lv_chk_rslt = cv_true
        ) OR
        (iv_proc_kbn = cv_proc_kbn2 AND
          TO_CHAR(i_cust_rec.cnvs_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
          lv_chk_rslt = cv_true
        ) OR
        (iv_proc_kbn = cv_proc_kbn2 AND lv_chk_rslt = cv_false)
       )
    THEN
      -- ========================================
      -- 2.�ڋq�A�h�I���}�X�^���b�N
      -- ========================================
      BEGIN
        SELECT xca.customer_id  customer_id  -- �ڋqID
        INTO  ln_customer_id                 -- �ڋqID
        FROM  xxcmm_cust_accounts  xca  -- �ڋq�A�h�I���}�X�^
        WHERE xca.customer_id = i_cust_rec.cust_account_id  -- �ڋqID�i�A�J�E���gID�j

        FOR UPDATE NOWAIT
        ;
        --
      EXCEPTION
        -- *** ���b�N�Ɏ��s�����ꍇ ***
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_07           -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_tkn_val_cust_addon_mst  -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_item                -- �g�[�N���R�[�h2
                         , iv_token_value2 => cv_tkn_val_cust_cd         -- �g�[�N���l2
                         , iv_token_name3  => cv_tkn_base_val            -- �g�[�N���R�[�h3
                         , iv_token_value3 => iv_account_number          -- �g�[�N���l3
                       );
          lv_errbuf := lv_errmsg;
          RAISE sql_expt;
          --
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_13           -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_task_nm             -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_tkn_val_cust_addon_mst  -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_item                -- �g�[�N���R�[�h2
                         , iv_token_value2 => cv_tkn_val_cust_cd         -- �g�[�N���l2
                         , iv_token_name3  => cv_tkn_base_val            -- �g�[�N���R�[�h3
                         , iv_token_value3 => iv_account_number          -- �g�[�N���l3
                         , iv_token_name4  => cv_tkn_errmsg              -- �g�[�N���R�[�h4
                         , iv_token_value4 => SQLERRM                    -- �g�[�N���l4
                       );
          lv_errbuf := lv_errmsg;
          RAISE sql_expt;
      END;
      --
      -- ========================================
      -- 3.�ڋq�A�h�I���}�X�^�X�V
      -- ========================================
      BEGIN
        -- (A-15-2�ɂćAb)�̏ꍇ
        IF (iv_proc_kbn = cv_proc_kbn2 AND lv_chk_rslt = cv_false ) THEN
          UPDATE xxcmm_cust_accounts  -- �ڋq�A�h�I���}�X�^
          SET   cnvs_date              = id_process_date              -- �ڋq�l����
              , last_updated_by        = cn_last_updated_by           -- �ŏI�X�V��
              , last_update_date       = cd_last_update_date          -- �ŏI�X�V��
              , last_update_login      = cn_last_update_login         -- �ŏI�X�V���O�C��
              , request_id             = cn_request_id                -- �v��ID
              , program_application_id = cn_program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              , program_id             = cn_program_id                -- �R���J�����g�E�v���O����ID
              , program_update_date    = cd_program_update_date       -- �v���O�����X�V��
          WHERE customer_id = i_cust_rec.cust_account_id  -- �ڋqID�i�A�J�E���gID�j
          ;
        -- A-15-2�ɂć@�̏ꍇ �܂���A-15-2�ɂćAa)�̏ꍇ
        ELSIF ((iv_proc_kbn = cv_proc_kbn1 AND 
                TO_CHAR(id_actual_work_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                lv_chk_rslt = cv_true 
               ) OR
               (iv_proc_kbn = cv_proc_kbn2 AND
                TO_CHAR(i_cust_rec.cnvs_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                lv_chk_rslt = cv_true 
               )
              )
        THEN
          UPDATE xxcmm_cust_accounts  -- �ڋq�A�h�I���}�X�^
          SET   past_customer_status   = iv_duns_number_c             -- DUNS�ԍ��i�ڋq�X�e�[�^�X�j
              , last_updated_by        = cn_last_updated_by           -- �ŏI�X�V��
              , last_update_date       = cd_last_update_date          -- �ŏI�X�V��
              , last_update_login      = cn_last_update_login         -- �ŏI�X�V���O�C��
              , request_id             = cn_request_id                -- �v��ID
              , program_application_id = cn_program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              , program_id             = cn_program_id                -- �R���J�����g�E�v���O����ID
              , program_update_date    = cd_program_update_date       -- �v���O�����X�V��
          WHERE customer_id = i_cust_rec.cust_account_id  -- �ڋqID�i�A�J�E���gID�j
          ;
        END IF;
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_18           -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_tkn_val_cust_addon_mst  -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_action              -- �g�[�N���R�[�h2
                         , iv_token_value2 => cv_tkn_val_update          -- �g�[�N���l2
                         , iv_token_name3  => cv_tkn_kokyaku             -- �g�[�N���R�[�h3
                         , iv_token_value3 => iv_account_number          -- �g�[�N���l3
                         , iv_token_name4  => cv_tkn_errmsg              -- �g�[�N���R�[�h4
                         , iv_token_value4 => SQLERRM                    -- �g�[�N���l4
                       );
          lv_errbuf := lv_errmsg;
          RAISE sql_expt;
      END;
      --
    END IF;
--
  EXCEPTION
    -- *** SQL��O�n���h�� ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_xxcmm_cust_acnts;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
      ov_errbuf   OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W            --# �Œ� #
    , ov_retcode  OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h              --# �Œ� #
    , ov_errmsg   OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain';    -- �v���O������
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
    lv_proc_kbn               VARCHAR2(1);
    --
    -- OUT�p�����[�^�i�[�p
    ld_sysdate                DATE;                                              -- �V�X�e�����t
    ld_process_date           DATE;                                              -- �Ɩ��������t
    ld_actual_work_date       DATE;                                              -- ����Ɠ�
    lt_cust_sts_nm_suspended  VARCHAR2(100);                                     -- �ڋq�X�e�[�^�X�i�x�~�j
    lt_cust_sts_nm_approved   VARCHAR2(100);                                     -- �ڋq�X�e�[�^�X�i���F�ρj
    lt_cust_sts_nm_customer   VARCHAR2(100);                                     -- �ڋq�X�e�[�^�X�i�ڋq�j
    lt_cust_sts_suspended     hz_parties.duns_number_c%TYPE;                     -- �ڋq�X�e�[�^�X�i�x�~�j
    lt_cust_sts_approved      hz_parties.duns_number_c%TYPE;                     -- �ڋq�X�e�[�^�X�i���F�ρj
    lt_cust_sts_customer      hz_parties.duns_number_c%TYPE;                     -- �ڋq�X�e�[�^�X�i�ڋq�j
    lt_req_sts_approved       po_requisition_headers.authorization_status%TYPE;  -- �����˗��X�e�[�^�X�R�[�h�i���F�ρj
    lv_org_id                 NUMBER;                                            -- �I���OID
    --
    -- *** ���[�J���E�J�[�\�� ***
    -- ��ƃf�[�^���o�J�[�\��
    CURSOR get_work_data_cur(
              id_process_date          IN DATE
            , it_auth_status_approved  IN po_requisition_headers.authorization_status%TYPE
           )
    IS
      SELECT xiwd.install_code2    install_code    -- �����R�[�h�Q�i���g�p�j
           , xiwd.account_number2  account_number  -- �ڋq�R�[�h�Q�i���ݒu��j
           , xiwd.slip_no          slip_no         -- �`�[No
           , xiwd.slip_branch_no   slip_branch_no  -- �`�[�}��
           , xiwd.line_number      line_number     -- �s�ԍ�
           , xiwd.actual_work_date actual_work_date -- ����Ɠ�
         /*20090507_mori_T1_0439 START*/
           , cii.instance_type_code instance_type_code           -- �C���X�^���X�^�C�v�R�[�h
         /*20090507_mori_T1_0439 END*/
      FROM   xxcso_in_work_data         xiwd    -- ��ƃf�[�^�e�[�u��
           , po_requisition_headers     prh     -- �����˗��w�b�_�r���[
           , xxcso_requisition_lines_v  xrlv    -- �����˗����׏��r���[
         /*20090507_mori_T1_0439 START*/
           , csi_item_instances         cii     -- �C���X�g�[���x�[�X�}�X�^�i�����}�X�^�j
         /*20090507_mori_T1_0439 END*/
      WHERE  xiwd.job_kbn                          = cv_job_kbn_withdraw       -- ��Ƌ敪�i���g�j
      AND    xiwd.completion_kbn                   = cv_completion_kbn_cmplt   -- �����敪�i�����j
      AND    xiwd.install2_processed_flag          = cv_install2_proc_end      -- �����Q�����σt���O�i�����ρj
      AND    xiwd.suspend_processed_flag           = cv_suspend_proc_unprc     -- �x�~�����σt���O�i�������j
      AND    SUBSTRB( xrlv.withdrawal_type, 1, 1 ) = cv_withdrawal_type_nrml   -- ���g�敪�i���g�j
      AND    xrlv.category_kbn                     = cv_category_kbn_withdraw  -- �J�e�S���敪�i���g�j
      AND    prh.authorization_status              = it_auth_status_approved   -- ���F�X�e�[�^�X
      AND    prh.segment1               = TO_CHAR( xiwd.po_req_number )    -- �����˗��ԍ�
      AND    xrlv.requisition_header_id = prh.requisition_header_id        -- �����˗��w�b�_ID
      AND    xrlv.line_num              = xiwd.line_num                    -- �����˗����הԍ�
      AND    xrlv.withdraw_install_code = xiwd.install_code2               -- ���g�p�����R�[�h�i�����R�[�h�j
    /*20090507_mori_T1_0439 START*/
      AND    cii.external_reference     = xiwd.install_code2               -- ���g�p�����R�[�h�i�����R�[�h�j
    /*20090507_mori_T1_0439 END*/
      ;
    --
    -- �ڋq��񒊏o�J�[�\��
    CURSOR get_cust_acnt_cur(
              it_cust_stat_approved  IN hz_parties.duns_number_c%TYPE
           )
    IS
      SELECT xcav.party_id              party_id               -- �p�[�e�BID
           , xcav.account_number        account_number         -- �ڋq�R�[�h
           , xcav.cust_account_id       cust_account_id        -- �A�J�E���gID
           , xcav.cnvs_date             cnvs_date              -- �ڋq�l����
           , xcav.party_name            party_name             -- �ڋq��
           , xcav.customer_status       customer_status        -- �ڋq�X�e�[�^�X
           , hpa.object_version_number  object_version_number  -- �I�u�W�F�N�g�o�[�W�����ԍ�
      FROM   xxcso_cust_accounts_v  xcav    -- �ڋq�}�X�^�r���[
           , hz_parties             hpa     -- �p�[�e�B�}�X�^
      WHERE  xcav.cnvs_date IS NOT NULL                    -- �ڋq�l����
      AND    xcav.customer_status = it_cust_stat_approved  -- ���F�X�e�[�^�X
      AND    xcav.party_id        = hpa.party_id           -- �p�[�e�BID
      AND    xcav.business_low_type IN (cv_business_low_type24,cv_business_low_type25,cv_business_low_type27)
      
      ;
    --
    -- *** ���[�J���E���R�[�h ***
    l_work_data_rec        g_work_data_rtype;
    l_cust_rec             g_cust_rtype;
    l_cust_rec2            g_cust_rtype;
    l_get_work_data_rec    get_work_data_cur%ROWTYPE;
    l_get_cust_acnt_rec    get_cust_acnt_cur%ROWTYPE;
    --
    -- *** ���[�J����O ***
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
    -- �����J�E���g�̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
    gn_target_cnt2 := 0;
    gn_normal_cnt2 := 0;
    gn_warn_cnt2   := 0;
    gn_error_cnt2  := 0;
--
    -- �����敪�̐ݒ�i�����敪=�u�x�~�����v�j
    lv_proc_kbn := cv_proc_kbn1;
    --
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
       od_process_date => ld_process_date  -- �Ɩ��������t
     , ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
     , ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
     , ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.�v���t�@�C���l�擾
    -- ========================================
    get_profile_info(
        ov_cust_sts_suspended => lt_cust_sts_nm_suspended  -- �ڋq�X�e�[�^�X�i�x�~�j
      , ov_cust_sts_approved  => lt_cust_sts_nm_approved   -- �ڋq�X�e�[�^�X�i���F�ρj
      , ov_cust_sts_customer  => lt_cust_sts_nm_customer   -- �ڋq�X�e�[�^�X�i�ڋq�j
      , ov_req_sts_approved   => lt_req_sts_approved       -- �����˗��X�e�[�^�X�R�[�h�i���F�ρj
      , ov_org_id             => lv_org_id                 -- �I���OID
      , ov_errbuf             => lv_errbuf                 -- �G���[�E���b�Z�[�W            --# �Œ� #
      , ov_retcode            => lv_retcode                -- ���^�[���E�R�[�h              --# �Œ� #
      , ov_errmsg             => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.�ڋq�X�e�[�^�X���o
    -- ========================================
--
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg9 || CHR(10)
    );
--
    -- �ڋq�X�e�[�^�X�F�u�x�~�v
    get_cust_status(
        it_cust_status_nm => lt_cust_sts_nm_suspended  -- �ڋq�X�e�[�^�X��
      , id_process_date   => ld_process_date           -- �Ɩ��������t
      , ot_cust_status_cd => lt_cust_sts_suspended     -- �ڋq�X�e�[�^�X
      , ov_errbuf         => lv_errbuf                 -- �G���[�E���b�Z�[�W            --# �Œ� #
      , ov_retcode        => lv_retcode                -- ���^�[���E�R�[�h              --# �Œ� #
      , ov_errmsg         => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    -- �擾�����ڋq�X�e�[�^�X�����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_tkn_val_cust_sts           || cv_case_arc_left
                   || lt_cust_sts_nm_suspended || cv_case_arc_right
                   || cv_msg_equal             || lt_cust_sts_suspended || CHR(10)
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- �ڋq�X�e�[�^�X�F�u���F�ρv
    get_cust_status(
        it_cust_status_nm => lt_cust_sts_nm_approved  -- �ڋq�X�e�[�^�X��
      , id_process_date   => ld_process_date          -- �Ɩ��������t
      , ot_cust_status_cd => lt_cust_sts_approved     -- �ڋq�X�e�[�^�X
      , ov_errbuf         => lv_errbuf                -- �G���[�E���b�Z�[�W            --# �Œ� #
      , ov_retcode        => lv_retcode               -- ���^�[���E�R�[�h              --# �Œ� #
      , ov_errmsg         => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    -- �擾�����ڋq�X�e�[�^�X�����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_tkn_val_cust_sts          || cv_case_arc_left
                   || lt_cust_sts_nm_approved || cv_case_arc_right
                   || cv_msg_equal            || lt_cust_sts_approved || CHR(10)
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- �ڋq�X�e�[�^�X�F�u�ڋq�v
    get_cust_status(
        it_cust_status_nm => lt_cust_sts_nm_customer  -- �ڋq�X�e�[�^�X��
      , id_process_date   => ld_process_date          -- �Ɩ��������t
      , ot_cust_status_cd => lt_cust_sts_customer     -- �ڋq�X�e�[�^�X
      , ov_errbuf         => lv_errbuf                -- �G���[�E���b�Z�[�W            --# �Œ� #
      , ov_retcode        => lv_retcode               -- ���^�[���E�R�[�h              --# �Œ� #
      , ov_errmsg         => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    -- �擾�����ڋq�X�e�[�^�X�����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_tkn_val_cust_sts          || cv_case_arc_left
                   || lt_cust_sts_nm_customer || cv_case_arc_right
                   || cv_msg_equal            || lt_cust_sts_customer || CHR(10)
                   || ''
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-4.��ƃf�[�^���o
    -- ========================================
    -- ��ƃf�[�^���o�J�[�\���I�[�v��
    OPEN get_work_data_cur(
        id_process_date         => ld_process_date
      , it_auth_status_approved => lt_req_sts_approved
    );
--
    -- ��ƃf�[�^���o�J�[�\�����I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_copn1 || CHR(10) ||
                 ''
    );
--
    << get_work_data_loop >>
    LOOP
      --
      BEGIN
        --
        FETCH get_work_data_cur INTO l_get_work_data_rec;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_03        -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table            -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_tkn_val_wk_data_tbl  -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_errmsg           -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM                 -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- �����Ώی����i�[
      gn_target_cnt := get_work_data_cur%ROWCOUNT;
      --
      -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
      EXIT WHEN get_work_data_cur%NOTFOUND
      OR  get_work_data_cur%ROWCOUNT = 0;
      --
      l_work_data_rec.slip_no        := l_get_work_data_rec.slip_no;
      l_work_data_rec.slip_branch_no := l_get_work_data_rec.slip_branch_no;
      l_work_data_rec.line_number    := l_get_work_data_rec.line_number;
      l_work_data_rec.install_code   := l_get_work_data_rec.install_code;
      l_work_data_rec.account_number := l_get_work_data_rec.account_number;
      l_work_data_rec.actual_work_date := l_get_work_data_rec.actual_work_date;
      /*20090507_mori_T1_0439 START*/
      l_work_data_rec.instance_type_code := l_get_work_data_rec.instance_type_code;
      /*20090507_mori_T1_0439 END*/
      --
      -- ����Ɠ���ݒ�
      ld_actual_work_date := TO_DATE(l_get_work_data_rec.actual_work_date,'YYYY/MM/DD');
      --
      -- ��ƃf�[�^�֘A�����X�L�b�v�p���[�v�J�n
      << wk_data_proc_skip_loop >>
      LOOP
      /*20090507_mori_T1_0439 START*/
        -- �ڋq���X�V�t���O������
        gv_cust_upd_flg := cv_cust_upd_y;
      /*20090507_mori_T1_0439 END*/
        -- ========================================
        -- A-5.�������݃`�F�b�N����
        -- ========================================
        chk_ib_info(
            i_work_data_rec => l_work_data_rec    -- ��ƃf�[�^���
          , ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
          , ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
          , ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���̃��R�[�h�֏������X�L�b�v
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6.�ڋq��񒊏o����
        -- ========================================
        get_cust_info(
            i_work_data_rec => l_work_data_rec         -- ��ƃf�[�^���
          , iv_cust_status  => lt_cust_sts_customer    -- �ڋq�X�e�[�^�X
          , o_cust_rec      => l_cust_rec              -- �ڋq���
          , ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W            --# �Œ� #
          , ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h              --# �Œ� #
          , ov_errmsg       => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���̃��R�[�h�֏������X�L�b�v
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
      /*20090507_mori_T1_0439 START*/
        -- ���g���������̋@�ł���ꍇ
        IF (l_work_data_rec.instance_type_code = cv_instance_type_vd) THEN
      /*20090507_mori_T1_0439 END*/
          -- ========================================
          -- A-7.�ݒu��ڋq�E�����`�F�b�N����
          -- ========================================
          chk_cust_ib(
              i_work_data_rec => l_work_data_rec               -- ��ƃf�[�^���
            , in_acnt_id      => l_cust_rec.cust_account_id    -- �A�J�E���gID
            , ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W            --# �Œ� #
            , ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h              --# �Œ� #
            , ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            -- ���̃��R�[�h�֏������X�L�b�v
            EXIT;
            --
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
            --
          END IF;
      /*20090507_mori_T1_0439 START*/
        END IF;
      /*20090507_mori_T1_0439 END*/
        --
        -- ========================================
        -- A-8.�Z�[�u�|�C���g�ݒ�
        -- ========================================
        SAVEPOINT g_save_pt;
        --
      /*20090507_mori_T1_0439 START*/
        -- ���g���������̋@�����ݒu��ڋq�̎��̋@�c����0���ł���ꍇ
        IF (
                (gv_cust_upd_flg = cv_cust_upd_y)
            AND (l_work_data_rec.instance_type_code = cv_instance_type_vd)
           ) THEN
      /*20090507_mori_T1_0439 END*/
          -- ========================================
          -- A-15.�ڋq�A�h�I���}�X�^�X�V����
          -- ========================================
          upd_xxcmm_cust_acnts(
              iv_proc_kbn       => cv_proc_kbn1                        -- �����敪
            , i_cust_rec        => l_cust_rec                          -- �ڋq���
            , iv_duns_number_c  => lt_cust_sts_suspended                -- DUNS�ԍ��i�ڋq�X�e�[�^�X�i�x�~�j�j
            , id_actual_work_date => ld_actual_work_date               -- ����Ɠ�
            , iv_account_number => l_work_data_rec.account_number      -- �ڋq�R�[�h
            , id_process_date   => ld_process_date                     -- �Ɩ��������t
            , ov_errbuf         => lv_errbuf                           -- �G���[�E���b�Z�[�W            --# �Œ� #
            , ov_retcode        => lv_retcode                          -- ���^�[���E�R�[�h              --# �Œ� #
            , ov_errmsg         => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            -- �Z�[�u�|�C���g�܂Ń��[���o�b�N���A���̃��R�[�h�֏������X�L�b�v
            ROLLBACK TO g_save_pt;
            EXIT;
            --
          ELSIF ( lv_retcode = cv_status_error ) THEN
            --
            RAISE global_process_expt;
            --
          END IF;
          -- ========================================
          -- A-9.�ڋq�X�e�[�^�X�X�V�����i�x�~�����j
          -- ========================================
          update_cust_status(
              iv_proc_kbn      => cv_proc_kbn1           -- �����敪
            , i_work_data_rec  => l_work_data_rec        -- ��ƃf�[�^���
            , i_cust_rec       => l_cust_rec             -- �ڋq���
            , iv_duns_number_c => lt_cust_sts_suspended  -- DUNS�ԍ��i�ڋq�X�e�[�^�X�i�x�~�j�j
            , ov_errbuf        => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
            , ov_retcode       => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
            , ov_errmsg        => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            -- �Z�[�u�|�C���g�܂Ń��[���o�b�N���A���̃��R�[�h�֏������X�L�b�v
            ROLLBACK TO g_save_pt;
            EXIT;
            --
          ELSIF ( lv_retcode = cv_status_error ) THEN
            --
            RAISE global_process_expt;
            --
          END IF;
      /*20090507_mori_T1_0439 START*/
        END IF;
      /*20090507_mori_T1_0439 END*/
        --
        -- ========================================
        -- A-10.�Z�[�u�|�C���g�Q�ݒ�
        -- ========================================
        SAVEPOINT g_save_pt2;
        --
        -- ========================================
        -- A-11.��ƃf�[�^���b�N����
        -- ========================================
        work_data_lock(
            i_work_data_rec => l_work_data_rec    -- ��ƃf�[�^���
          , ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
          , ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
          , ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- �Z�[�u�|�C���g�Q�܂Ń��[���o�b�N���A���̃��R�[�h�֏������X�L�b�v
          ROLLBACK TO g_save_pt2;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-12.��ƃf�[�^�X�V����
        -- ========================================
        update_work_data(
            i_work_data_rec => l_work_data_rec    -- ��ƃf�[�^���
          , ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
          , ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
          , ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- �Z�[�u�|�C���g�Q�܂Ń��[���o�b�N���A���̃��R�[�h�֏������X�L�b�v
          ROLLBACK TO g_save_pt2;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ��ƃf�[�^�֘A�����X�L�b�v�p���[�v����EXIT
        EXIT;
        --
      END LOOP;  -- ��ƃf�[�^�֘A�����X�L�b�v�p���[�v�I��
      --
      -- ���^�[���E�R�[�h������̏ꍇ
      IF ( lv_retcode = cv_status_normal ) THEN
      /*20090507_mori_T1_0439 START*/
        -- ���g���������̋@�����ݒu��ڋq�̎��̋@�c����0���ȏ�ł���ꍇ�A
        -- �������x���Ƃ��A�X�L�b�v�����ɃJ�E���g����B
        IF (
                (gv_cust_upd_flg = cv_cust_upd_n)
            AND (l_work_data_rec.instance_type_code = cv_instance_type_vd)
           ) THEN
          -- �X�L�b�v�����J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
          --
          -- ���^�[���R�[�h�Ɍx���X�e�[�^�X��ݒ�
          ov_retcode := cv_status_warn;
          --
        ELSE
          -- ���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--        -- ���������J�E���g
--        gn_normal_cnt := gn_normal_cnt + 1;
      /*20090507_mori_T1_0439 END*/
        --
      -- ���^�[���E�R�[�h���x���̏ꍇ
      ELSE
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
        --
        -- �x�����e�����b�Z�[�W�A���O�֏o��
        fnd_file.put_line(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg    -- ���[�U�[�E�G���[���b�Z�[�W
        );
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => lv_errbuf    -- �G���[���b�Z�[�W
        );
        --
        -- ���^�[���R�[�h�Ɍx���X�e�[�^�X��ݒ�
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    END LOOP;
    --
    -- ��ƃf�[�^���o�J�[�\���N���[�Y
    CLOSE get_work_data_cur;
--
    -- ��ƃf�[�^���o�J�[�\�����N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ��ƃf�[�^���A�ڋq���i�[�p�ϐ���������
    l_work_data_rec := NULL;
    l_cust_rec      := NULL;
    --
    -- �����敪�̐ݒ�i�����敪=�u���F�ρ��ڋq�����v�j
    lv_proc_kbn := cv_proc_kbn2;
--
    -- ========================================
    -- A-13.�ڋq��񒊏o
    -- ========================================
    -- �ڋq��񒊏o�J�[�\���I�[�v��
    OPEN get_cust_acnt_cur(
        it_cust_stat_approved => lt_cust_sts_approved
    );
--
    -- �ڋq��񒊏o�J�[�\�����I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_copn2 || CHR(10) ||
                 ''
    );
--
    << get_cust_acnt_loop >>
    LOOP
      --
      BEGIN
        --
        FETCH get_cust_acnt_cur INTO l_get_cust_acnt_rec;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_03      -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_tkn_val_cust_info  -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_errmsg         -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM               -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          --
          -- �X�L�b�v�����J�E���g
          gn_warn_cnt2 := gn_warn_cnt2 + 1;
          --
          -- �x�����e�����b�Z�[�W�A���O�֏o��
          fnd_file.put_line(
              which => FND_FILE.OUTPUT
            , buff  => lv_errmsg    -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
              which => FND_FILE.LOG
            , buff  => lv_errbuf    -- �G���[���b�Z�[�W
          );
          --
          -- ���^�[���R�[�h�Ɍx���X�e�[�^�X��ݒ�
          ov_retcode := cv_status_warn;
          --
          EXIT;
          --
      END;
      --
      -- �����Ώی����i�[
      gn_target_cnt2 := get_cust_acnt_cur%ROWCOUNT;
      --
      -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
      EXIT WHEN get_cust_acnt_cur%NOTFOUND
      OR  get_cust_acnt_cur%ROWCOUNT = 0;
      --
      l_cust_rec2.object_version_number := l_get_cust_acnt_rec.object_version_number;
      l_cust_rec2.party_id              := l_get_cust_acnt_rec.party_id;
      l_cust_rec2.account_number        := l_get_cust_acnt_rec.account_number;
      l_cust_rec2.cust_account_id       := l_get_cust_acnt_rec.cust_account_id;
      l_cust_rec2.cnvs_date             := l_get_cust_acnt_rec.cnvs_date;
      l_cust_rec2.party_name            := l_get_cust_acnt_rec.party_name;
      l_cust_rec2.duns_number_c         := l_get_cust_acnt_rec.customer_status;
      --
      -- �ڋq���֘A�����X�L�b�v�p���[�v�J�n
      << cust_proc_skip_loop >>
      LOOP
        -- ========================================
        -- A-14.�Z�[�u�|�C���g�R�ݒ�
        -- ========================================
        SAVEPOINT g_save_pt3;
        --
        -- ========================================
        -- A-15.�ڋq�A�h�I���}�X�^�X�V����
        -- ========================================
        upd_xxcmm_cust_acnts(
            iv_proc_kbn       => cv_proc_kbn2                        -- �����敪
          , i_cust_rec        => l_cust_rec2                         -- �ڋq���
          , iv_duns_number_c => lt_cust_sts_customer                 -- DUNS�ԍ��i�ڋq�X�e�[�^�X�i�ڋq�j�j
          , id_actual_work_date => ld_actual_work_date               -- ����Ɠ�
          , iv_account_number => l_get_cust_acnt_rec.account_number  -- �ڋq�R�[�h
          , id_process_date   => ld_process_date                     -- �Ɩ��������t
          , ov_errbuf         => lv_errbuf                           -- �G���[�E���b�Z�[�W            --# �Œ� #
          , ov_retcode        => lv_retcode                          -- ���^�[���E�R�[�h              --# �Œ� #
          , ov_errmsg         => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- �Z�[�u�|�C���g�R�܂Ń��[���o�b�N���A���̃��R�[�h�֏������X�L�b�v
          ROLLBACK TO g_save_pt3;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-9.�ڋq�X�e�[�^�X�X�V�����i���F�ρ��ڋq�����j
        -- ========================================
        update_cust_status(
            iv_proc_kbn      => cv_proc_kbn2          -- �����敪
          , i_work_data_rec  => l_work_data_rec       -- ��ƃf�[�^���
          , i_cust_rec       => l_cust_rec2           -- �ڋq���
          , iv_duns_number_c => lt_cust_sts_customer  -- DUNS�ԍ��i�ڋq�X�e�[�^�X�i�ڋq�j�j
          , ov_errbuf        => lv_errbuf             -- �G���[�E���b�Z�[�W            --# �Œ� #
          , ov_retcode       => lv_retcode            -- ���^�[���E�R�[�h              --# �Œ� #
          , ov_errmsg        => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- �Z�[�u�|�C���g�R�܂Ń��[���o�b�N���A���̃��R�[�h�֏������X�L�b�v
          ROLLBACK TO g_save_pt3;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --
          RAISE global_process_expt;
          --
        END IF;
        --
        -- �ڋq���֘A�����X�L�b�v�p���[�v����EXIT
        EXIT;
        --
      END LOOP;  -- �ڋq���֘A�����X�L�b�v�p���[�v�I��
      --
      -- ���^�[���E�R�[�h������̏ꍇ
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ���������J�E���g
        gn_normal_cnt2 := gn_normal_cnt2 + 1;
        --
      -- ���^�[���E�R�[�h���x���̏ꍇ
      ELSE
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt2 := gn_warn_cnt2 + 1;
        --
        -- �x�����e�����b�Z�[�W�A���O�֏o��
        fnd_file.put_line(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg    -- ���[�U�[�E�G���[���b�Z�[�W
        );
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => lv_errbuf    -- �G���[���b�Z�[�W
        );
        --
        -- ���^�[���R�[�h�Ɍx���X�e�[�^�X��ݒ�
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    END LOOP;
    --
    -- �ڋq��񒊏o�J�[�\���N���[�Y
    CLOSE get_cust_acnt_cur;
--
    -- �ڋq��񒊏o�J�[�\�����I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_ccls2 || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      IF ( lv_proc_kbn = cv_proc_kbn1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        gn_error_cnt2 := gn_error_cnt2 + 1;
        --
      END IF;
      --
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF ( get_work_data_cur%ISOPEN ) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_work_data_cur;
        --
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls1_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err2     || CHR(10)     ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF ( get_cust_acnt_cur%ISOPEN ) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_cust_acnt_cur;
        --
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls2_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err2     || CHR(10)     ||
                     ''
        );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      IF ( lv_proc_kbn = cv_proc_kbn1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        gn_error_cnt2 := gn_error_cnt2 + 1;
        --
      END IF;
      --
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF ( get_work_data_cur%ISOPEN ) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_work_data_cur;
        --
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls1_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err3     || CHR(10)     ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF ( get_cust_acnt_cur%ISOPEN ) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_cust_acnt_cur;
        --
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls2_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err3     || CHR(10)     ||
                     ''
        );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      IF ( lv_proc_kbn = cv_proc_kbn1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        gn_error_cnt2 := gn_error_cnt2 + 1;
        --
      END IF;
      --
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF ( get_work_data_cur%ISOPEN ) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_work_data_cur;
        --
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls1_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err4     || CHR(10)     ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF ( get_cust_acnt_cur%ISOPEN ) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_cust_acnt_cur;
        --
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls2_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err4     || CHR(10)     ||
                     ''
        );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      , ov_retcode => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      , ov_errmsg  => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
       --�G���[�o��
       fnd_file.put_line(
           which => FND_FILE.OUTPUT
         , buff  => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
           which => FND_FILE.LOG
         , buff  => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf                  -- �G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-16.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    --
    ----------------------------------------
    -- �x�~�����̊e�����o��
    ----------------------------------------
    -- ���o���o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                  , iv_name         => cv_tkn_number_19    -- ���b�Z�[�W�R�[�h
                );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    ----------------------------------------
    -- ���F�ρ��ڋq�����̊e�����o��
    ----------------------------------------
    -- ���o���o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                  , iv_name         => cv_tkn_number_20    -- ���b�Z�[�W�R�[�h
                );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    ----------------------------------------
    -- �I�����b�Z�[�W�o��
    ----------------------------------------
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => lv_message_code
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
      --
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
          which => FND_FILE.LOG
        , buff  => cv_log_msg10 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_log_msg10 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_log_msg10 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO013A01C;
/
