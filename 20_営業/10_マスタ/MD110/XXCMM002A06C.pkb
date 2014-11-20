CREATE OR REPLACE PACKAGE BODY XXCMM002A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A06C(body)
 * Description      : �Ј��}�X�^IF�o��(HHT)
 * MD.050           : �Ј��}�X�^IF�o��(HHT) MD050_CMM_002_A06
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���������v���V�[�W��(A-1)
 *  get_rs_data            ���\�[�X�}�X�^���擾�v���V�[�W��(A-2)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W��(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   SCS ���� �M�q    ����쐬
 *  2009/04/24    1.1   Yutaka.Kuboshima ��QT1_0799�̑Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A06C';               -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_HHT_OUT_DIR';         -- HHTCSV�t�@�C���o�͐�
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A06_OUT_FILE';     -- �A�g�pCSV�t�@�C����
  cv_cal_code               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A06_SYS_CAL_CODE'; -- �V�X�e���ғ����J�����_�R�[�h�l
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- �v���t�@�C����
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C���o�͐�';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C����';
  cv_tkn_cal_code           CONSTANT VARCHAR2(30)  := '�V�X�e���ғ����J�����_�R�[�h�l';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- ���ږ�
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '�c�ƈ��ԍ�';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- �f�[�^
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- �t�@�C����
  cv_tkn_param              CONSTANT VARCHAR2(5)   := 'PARAM';                      -- �p�����[�^��
  cv_tkn_param1             CONSTANT VARCHAR2(20)  := '�ŏI�X�V��(�J�n)';
  cv_tkn_param2             CONSTANT VARCHAR2(20)  := '�ŏI�X�V��(�I��)';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '���̓p�����[�^';
  cv_tkn_value              CONSTANT VARCHAR2(5)   := 'VALUE';                      -- �p�����[�^�l
  -- ���b�Z�[�W�敪
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- ���b�Z�[�W
  cv_msg_00038              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- ���̓p�����[�^�o�̓��b�Z�[�W
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- �v���t�@�C���擾�G���[
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- �Ɩ����t�擾�G���[
  cv_msg_00035              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00035';           -- �O�̃V�X�e���ғ����擾�G���[
  cv_msg_00036              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00036';           -- ���̃V�X�e���ғ����擾�G���[
  cv_msg_00030              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00030';           -- �Ώۊ��Ԑ����G���[
  cv_msg_00019              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';           -- �Ώۊ��Ԏw��G���[
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- �t�@�C���p�X�s���G���[
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- �t�@�C���A�N�Z�X�����G���[
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSV�f�[�^�o�̓G���[
  -- �Œ�l(�ݒ�l�A���o����)
  cv_kbn_souko              CONSTANT VARCHAR2(1)   := '1';                          -- �ۊǏꏊ�敪(�q��)
  cv_category               CONSTANT VARCHAR2(10)  := 'EMPLOYEE';                   -- �J�e�S��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_filepath               VARCHAR2(255);        -- �A�g�pCSV�t�@�C���o�͐�
  gv_filename               VARCHAR2(255);        -- �A�g�pCSV�t�@�C����
  gv_cal_code               VARCHAR2(30);         -- �V�X�e���ғ����J�����_�R�[�h�l
  gd_process_date           DATE;                 -- �Ɩ����t
  gd_select_start_date      DATE;                 -- �擾�J�n��
  gd_select_start_datetime  DATE;                 -- �擾�J�n��(���� 00:00:00)
  gd_select_end_date        DATE;                 -- �擾�I����
  gd_select_end_datetime    DATE;                 -- �擾�I����(���� 23:59:59)
  gd_select_next_date       DATE;                 -- �擾���̃V�X�e���ғ���
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- �t�@�C���E�n���h���̐錾
  gv_update_sdate           VARCHAR2(10);         -- ���̓p�����[�^�F�ŏI�X�V��(�J�n)
  gv_update_edate           VARCHAR2(10);         -- ���̓p�����[�^�F�ŏI�X�V��(�I��)
  gv_attribute1             VARCHAR2(4);          -- ���_�R�[�h
  gv_param_output_flg       VARCHAR2(1);          -- ���̓p�����[�^�o�̓t���O(�o�͑O:0�A�o�͌�:1)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR get_rs_data_cur
  IS
    SELECT   SUBSTRB(r.source_number,1,5) AS source_number,
             SUBSTRB(r.source_name,1,20) AS source_name,
             TO_CHAR(s.actual_termination_date,'YYYYMMDD') AS actual_termination_date,
             TO_CHAR(r.last_update_date,'YYYY/MM/DD HH24:MI:SS') AS last_update_date,
             r.resource_id AS resource_id
    FROM     per_periods_of_service s,
             (SELECT   ss.person_id AS person_id,
                       MAX(ss.date_start) as date_start
              FROM     per_periods_of_service ss
              GROUP BY ss.person_id) ss,
-- 2009/04/24 Ver1.1 modify start by Yutaka.Kuboshima
--             jtf_rs_defresources_vl r
             jtf_rs_resource_extns r,
             jtf_rs_salesreps jrs
-- 2009/04/24 Ver1.1 modify end by Yutaka.Kuboshima
    WHERE    r.category = cv_category
    AND      r.last_update_date >= gd_select_start_datetime
    AND      r.last_update_date <= gd_select_end_datetime
    AND      r.source_id = ss.person_id
    AND      ss.person_id = s.person_id
    AND      ss.date_start = s.date_start
-- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
    AND      jrs.resource_id = r.resource_id(+)
    AND      jrs.org_id      = FND_GLOBAL.ORG_ID
-- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
    UNION
    SELECT   SUBSTRB(r.source_number,1,5) AS source_number,
             SUBSTRB(r.source_name,1,20) AS source_name,
             TO_CHAR(s.actual_termination_date,'YYYYMMDD') AS actual_termination_date,
             TO_CHAR(r.last_update_date,'YYYY/MM/DD HH24:MI:SS') AS last_update_date,
             r.resource_id AS resource_id
-- 2009/04/24 Ver1.1 modify start by Yutaka.Kuboshima
--    FROM     jtf_rs_defresources_vl r,
    FROM     jtf_rs_resource_extns r,
             jtf_rs_salesreps jrs,
-- 2009/04/24 Ver1.1 modify end by Yutaka.Kuboshima
             per_periods_of_service s,
             (SELECT   ss.person_id AS person_id,
                       MAX(ss.date_start) as date_start
              FROM     per_periods_of_service ss
              GROUP BY ss.person_id) ss
    WHERE    ss.person_id = s.person_id
    AND      ss.date_start = s.date_start
    AND      s.actual_termination_date >= gd_select_end_date
    AND      s.actual_termination_date < gd_select_next_date
    AND      r.source_id = s.person_id
-- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
    AND      jrs.resource_id = r.resource_id(+)
    AND      jrs.org_id      = FND_GLOBAL.ORG_ID
-- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
  ;
  TYPE g_rs_data_ttype IS TABLE OF get_rs_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_rs_data            g_rs_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- �v���O������
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
    -- �t�@�C���I�[�v�����[�h
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- �㏑��
--
    -- *** ���[�J���ϐ� ***
    lb_fexists              BOOLEAN;              -- �t�@�C�������݂��邩�ǂ���
    ln_file_size            NUMBER;               -- �t�@�C���̒���
    ln_block_size           NUMBER;               -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
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
    -- =========================================================
    -- �v���t�@�C��(�V�X�e���ғ����J�����_�̃J�����_�R�[�h�l)���擾
    -- =========================================================
    gv_cal_code := fnd_profile.value(cv_cal_code);
    IF (gv_cal_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile       -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_cal_code      -- �v���t�@�C����(�V�X�e���ғ����J�����_�R�[�h�l)
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- =========================================================
    --  �擾�J�n���A�擾�I�����A�擾���̃V�X�e���ғ����̎擾
    -- =========================================================
    -- �Ɩ����t�̎擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00018           -- �Ɩ��������t�擾�G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �擾�J�n���̎擾
    IF (gv_update_sdate IS NULL) THEN
      -- �Ɩ����t�̑O�̃V�X�e���ғ����̎��̓����Z�b�g
      gd_select_start_date := xxccp_common_pkg2.get_working_day(gd_process_date,-1,gv_cal_code) + 1;
      IF (gd_select_start_date IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00035         -- �O�̃V�X�e���ғ����擾�G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSE
      -- �ŏI�X�V��(�J�n)���Z�b�g
      gd_select_start_date := TO_DATE(gv_update_sdate,'YYYY/MM/DD');
    END IF;
    -- �擾�I�����̎擾
    IF (gv_update_edate IS NULL) THEN
      -- �Ɩ����t���Z�b�g
      gd_select_end_date := gd_process_date;
    ELSE
      -- �ŏI�X�V��(�I��)���Z�b�g
      gd_select_end_date := TO_DATE(gv_update_edate,'YYYY/MM/DD');
    END IF;
    -- ���������p�Ɏ������Z�b�g
    gd_select_start_datetime := TO_DATE(TO_CHAR(gd_select_start_date,'YYYY/MM/DD') || ' 00:00:00','YYYY/MM/DD HH24:MI:SS');
    gd_select_end_datetime := TO_DATE(TO_CHAR(gd_select_end_date,'YYYY/MM/DD') || ' 23:59:59','YYYY/MM/DD HH24:MI:SS');
    -- �擾���̃V�X�e���ғ������擾
    gd_select_next_date := xxccp_common_pkg2.get_working_day(gd_select_end_date,1,gv_cal_code);
    IF (gd_select_next_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00036         -- ���̃V�X�e���ғ����擾�G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- =========================================================
    --  �Œ�o��(���̓p�����[�^��)
    -- =========================================================
    -- ���̓p�����[�^
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                    ,iv_token_value1 => cv_tkn_param3          -- �p�����[�^��(���̓p�����[�^)
                    ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                    ,iv_token_value2 => gv_update_sdate || '.' || gv_update_edate
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- �擾�J�n��
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                    ,iv_token_value1 => cv_tkn_param1          -- �p�����[�^��(�ŏI�X�V��(�J�n))
                    ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                    ,iv_token_value2 => TO_CHAR(gd_select_start_date,'YYYY/MM/DD')
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- �擾�I����
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                    ,iv_token_value1 => cv_tkn_param2          -- �p�����[�^��(�ŏI�X�V��(�I��))
                    ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                    ,iv_token_value2 => TO_CHAR(gd_select_end_date,'YYYY/MM/DD')
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- ��s�}��(���̓p�����[�^�̉�)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ���̓p�����[�^�o�̓t���O�Ɂu�o�͌�v���Z�b�g
    gv_param_output_flg := '1';
    --
    -- =========================================================
    --  �Ώۊ��Ԏw��`�F�b�N
    -- =========================================================
    IF (gd_select_start_date > gd_select_end_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00019           -- �Ώۊ��Ԏw��G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  �Ώۊ��Ԑ����`�F�b�N
    -- =========================================================
    IF (gd_select_start_date > gd_process_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00030           -- �Ώۊ��Ԑ����G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    IF (gd_select_end_date > gd_process_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00030           -- �Ώۊ��Ԑ����G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  �v���t�@�C���̎擾(CSV�t�@�C���o�͐�ACSV�t�@�C����)
    -- =========================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile         -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm     -- �v���t�@�C����(CSV�t�@�C���o�͐�)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile         -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm     -- �v���t�@�C����(CSV�t�@�C����)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- =========================================================
    --  �Œ�o��(I/F�t�@�C������)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp           -- 'XXCCP'
                    ,iv_name         => cv_msg_05102             -- �t�@�C�����o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_filename          -- �g�[�N��(FILE_NAME)
                    ,iv_token_value1 => gv_filename              -- �t�@�C����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��(I/F�t�@�C�����̉�)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- =========================================================
    --  CSV�t�@�C�����݃`�F�b�N
    -- =========================================================
    UTL_FILE.FGETATTR(gv_filepath,
                      gv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
    IF (lb_fexists = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00010           -- �t�@�C���쐬�ς݃G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  �t�@�C���I�[�v��
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00003         -- �t�@�C���p�X�s���G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_rs_data
   * Description      : ���\�[�X�}�X�^���擾�v���V�[�W��(A-2)
   ***********************************************************************************/
  PROCEDURE get_rs_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rs_data';       -- �v���O������
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
--
   -- �J�[�\���I�[�v��
    OPEN get_rs_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_rs_data_cur BULK COLLECT INTO gt_rs_data;
--
    -- �Ώی������Z�b�g
    gn_target_cnt := gt_rs_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_rs_data_cur;
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
  END get_rs_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�t�@�C���o�̓v���V�[�W��(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';            -- �v���O������
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
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt         NUMBER;                   -- ���[�v�J�E���^
    lv_csv_text         VARCHAR2(32000);          -- �o�͂P�s��������ϐ�
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    <<out_loop>>
    FOR ln_loop_cnt IN gt_rs_data.FIRST..gt_rs_data.LAST LOOP
      --==============================================================
      -- ���_�R�[�h�̎擾(A-3)
      --==============================================================
      BEGIN
        SELECT   SUBSTRB(g.attribute1,1,4) INTO gv_attribute1
        FROM     jtf_rs_group_members_vl m,
                 jtf_rs_groups_vl g
        WHERE    m.resource_id = gt_rs_data(ln_loop_cnt).resource_id
        AND      m.DELETE_FLAG = 'N'
        AND      m.group_id = g.group_id
-- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
        AND      ROWNUM = 1;
-- 2009/04/24 Ver1.1 add end by Yutaka.Kuboshima
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gv_attribute1 := NULL;
-- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
        WHEN TOO_MANY_ROWS THEN
          gv_attribute1 := NULL;
-- 2009/04/24 Ver1.1 add end by Yutaka.Kuboshima
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      lv_csv_text := cv_enclosed || gt_rs_data(ln_loop_cnt).source_number || cv_enclosed || cv_delimiter  -- �c�ƈ��R�[�h
        || cv_enclosed || gt_rs_data(ln_loop_cnt).source_name || cv_enclosed || cv_delimiter              -- �c�ƈ�����
        || cv_enclosed || gv_attribute1 || cv_enclosed || cv_delimiter                                    -- ���\�[�X�O���[�v
        || gt_rs_data(ln_loop_cnt).actual_termination_date || cv_delimiter                                -- �ސE�N����
        || cv_enclosed || gt_rs_data(ln_loop_cnt).last_update_date || cv_enclosed                         -- �X�V����
      ;
      BEGIN
        -- �t�@�C����������
        UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
      EXCEPTION
        -- �t�@�C���A�N�Z�X�����G���[
        WHEN UTL_FILE.INVALID_OPERATION THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
                          ,iv_name         => cv_msg_00007                             -- �t�@�C���A�N�Z�X�����G���[
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        --
        -- CSV�f�[�^�o�̓G���[
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
                          ,iv_name         => cv_msg_00009                             -- CSV�f�[�^�o�̓G���[
                          ,iv_token_name1  => cv_tkn_word                              -- �g�[�N��(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                              -- �g�[�N��(NG_DATA)
                          ,iv_token_value2 => gt_rs_data(ln_loop_cnt).source_number    -- NG_WORD��DATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
      -- ���������̃J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP out_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
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
    gv_param_output_flg := '0';
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- =====================================================
    --  ���������v���V�[�W��(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  ���\�[�X�}�X�^���擾�v���V�[�W��(A-2)
    -- =====================================================
    get_rs_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSV�t�@�C���o�̓v���V�[�W��(A-4)
    -- =====================================================
    IF (gn_target_cnt > 0) THEN
      output_csv(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =====================================================
    --  �I�������v���V�[�W��(A-5)
    -- =====================================================
    -- CSV�t�@�C�����N���[�Y����
    UTL_FILE.FCLOSE(gf_file_hand);
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
   * Description      : �R���J�����g���s�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_date_from  IN  VARCHAR2,      --   1.�ŏI�X�V��(�J�n)
    iv_date_to    IN  VARCHAR2       --   2.�ŏI�X�V��(�I��)
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
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
    -- ���̓p�����[�^�̎擾
    -- ===============================================
    gv_update_sdate := iv_date_from;
    gv_update_edate := iv_date_to;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf   -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      -- ��s�}��(�����������̏�)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ���̓p�����[�^�o�͌�́A�G���[���b�Z�[�W�Ƃ̊Ԃɋ�s�}��
      IF (gv_param_output_flg = '1') THEN
        -- ��s�}��(���̓p�����[�^�ƃG���[���b�Z�[�W�̊�)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --�Ώی����o��
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
    --���������o��
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
    --�G���[�����o��
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
    -- ��s�}��(�I�����b�Z�[�W�̏�)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --CSV�t�@�C�����N���[�Y����Ă��Ȃ������ꍇ�A�N���[�Y����
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
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
END XXCMM002A06C;
/
