CREATE OR REPLACE PACKAGE BODY APPS.XXCFO016A04C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO016A04C(body)
 * Description      : ���Ə��}�X�^�A�g�f�[�^���o_EBS�R���J�����g
 * MD.050           : T_MD050_CFO_016_A04_���Ə��}�X�^�A�g�f�[�^���o_EBS�R���J�����g
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    ��������(A-1)
 *  output_office           �A�g�f�[�^���o(A-2)
 *                          I/F�t�@�C���o��(A-3)
 *  upd_oipm                �Ǘ��e�[�u���o�^�X�V(A-4)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �I������(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-11-28    1.0   N.Fujiwara       �V�K�쐬
 *  2022-12-07    1.1   N.Fujiwara       E106,E109�`E111�Ή�
 *  2022-12-14    1.2   N.Fujiwara       E112,E116�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                    -- �Ώی���
  gn_normal_cnt      NUMBER;                    -- ���팏��
  gn_error_cnt       NUMBER;                    -- �G���[����
  gn_warn_cnt        NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  -- *** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFO016A04'; -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo        CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI';
  -- �v���t�@�C��
  cv_data_filedir       CONSTANT VARCHAR2(50)  := 'XXCFO1_OIC_OUT_FILE_DIR';     -- OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  cv_filename           CONSTANT VARCHAR2(50)  := 'XXCFO1_OIC_LOC_MST_OUT_FILE'; -- ���Ə��}�X�^�A�g�f�[�^�t�@�C����
  -- ���b�Z�[�W
  cv_msg_coi_00029      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029'; -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001'; -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00015      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00019      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00019'; -- ���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00020'; -- �X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00024'; -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_00027      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027'; -- �t�@�C�����݃G���[
  cv_msg_cfo_00029      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029'; -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030'; -- �t�@�C���������݃G���[
  cv_msg_cfo_60001      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60001'; -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_cfo_60002      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60002'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_60003      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60003'; -- ���������o�̓��b�Z�[�W
  cv_msg_cfo_60004      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60004'; -- �����ΏہE�������b�Z�[�W
  cv_msg_cfo_60005      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60005'; -- �t�@�C���o�͑ΏہE�������b�Z�[�W
  cv_msg_cfo_60006      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60006'; -- "�Ɩ����t�i���J�o���p�j"
  cv_msg_cfo_60007      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60007'; -- "���Ə��}�X�^���"
  cv_msg_cfo_60008      CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60008'; -- "OIC�A�g�����Ǘ��e�[�u��"
  -- �g�[�N���R�[�h
  cv_tkn_param_name     CONSTANT VARCHAR2(20)  := 'PARAM_NAME'; -- �p�����[�^��
  cv_tkn_param_val      CONSTANT VARCHAR2(20)  := 'PARAM_VAL';  -- �p�����[�^�l
  cv_tkn_prof_name      CONSTANT VARCHAR2(20)  := 'PROF_NAME';  -- �v���t�@�C����
  cv_tkn_dir_tok        CONSTANT VARCHAR2(20)  := 'DIR_TOK';    -- �f�B���N�g����
  cv_tkn_file_name      CONSTANT VARCHAR2(20)  := 'FILE_NAME';  -- �f�B���N�g���p�X�t���t�@�C����
  cv_tkn_table          CONSTANT VARCHAR2(20)  := 'TABLE';      -- �e�[�u��
  cv_tkn_date1          CONSTANT VARCHAR2(20)  := 'DATE1';      -- �O�񏈗�����
  cv_tkn_date2          CONSTANT VARCHAR2(20)  := 'DATE2';      -- ���񏈗�����
  cv_tkn_target         CONSTANT VARCHAR2(20)  := 'TARGET';     -- �����Ώ�
  cv_tkn_count          CONSTANT VARCHAR2(20)  := 'COUNT';      -- ��������
  cv_tkn_err_msg        CONSTANT VARCHAR2(20)  := 'ERRMSG';    -- �G���[���e
  -- ���t�t�H�[�}�b�g
  cv_dateformat_ymdhms  CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS'; -- �A�g���t�t�H�[�}�b�g
  -- �Œ�l
  cv_slash              CONSTANT VARCHAR2(1)   := '/'; -- �X���b�V��
  cv_delimit            CONSTANT VARCHAR2(1)   := '|'; -- �p�C�v
  -- �t�@�C���o��
  cv_file_type_out      CONSTANT VARCHAR2(30)  := 'OUTPUT'; -- ���b�Z�[�W�o��
  cv_file_type_log      CONSTANT VARCHAR2(30)  := 'LOG';    -- ���O�o��
  cv_open_mode_w        CONSTANT VARCHAR2(30)  := 'W';      -- �������݃��[�h
  cn_max_linesize       CONSTANT BINARY_INTEGER := 32767;   -- �t�@�C���T�C�Y
-- Ver1.2 Add Start
  --���o����
  cv_loc_code_1         CONSTANT VARCHAR2(30)  := 'ITOE_LOC'; -- �����Z�b�g�A�b�v�o�^�σf�[�^1
  cv_loc_code_2         CONSTANT VARCHAR2(30)  := 'X999';     -- �����Z�b�g�A�b�v�o�^�σf�[�^2
  --�f�[�^���o�E�o�͌Œ�l
  cv_setcode            CONSTANT VARCHAR2(100) := 'ITO_SALES_DSET01'; -- �o�א掖�Ə��Z�b�g�E�R�[�h�A�Z�b�g�R�[�h
-- Ver1.2 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date    DATE;                                                              -- �Ɩ����t
  gd_coop_date       DATE;                                                              -- �A�g���t
  gt_pre_prodate     xxccp_oic_if_process_mng.pre_process_date%TYPE DEFAULT NULL;       -- �O�񏈗�����
  gd_prodate         DATE DEFAULT NULL;                                                 -- ���񏈗�����
  gf_file_hand       UTL_FILE.FILE_TYPE;                                                -- �t�@�C���E�n���h���̐錾
  gt_ccrt_proname    fnd_concurrent_programs.concurrent_program_name%TYPE DEFAULT NULL; -- �R���J�����g�v���O������
  -- �v���t�@�C���p
  gv_dir_name        VARCHAR2(100) DEFAULT NULL; -- OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  gv_file_name       VARCHAR2(100) DEFAULT NULL; -- ���Ə��}�X�^�A�g�f�[�^�t�@�C����
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
  -- �Ώۃf�[�^���o�p�J�[�\��
  CURSOR  get_office_cur
  IS
    SELECT    hl.attribute3           AS hl_purchasing_flag     -- �w���S���t���O
            , hl.attribute4           AS hl_shipping_flag       -- �o�גS���t���O
            , hl.attribute5           AS hl_rsp_name1           -- �S���E��1
            , hl.attribute6           AS hl_rsp_name2           -- �S���E��2
            , hl.attribute7           AS hl_rsp_name3           -- �S���E��3
            , hl.attribute8           AS hl_rsp_name4           -- �S���E��4
            , hl.attribute9           AS hl_rsp_name5           -- �S���E��5
            , hl.attribute10          AS hl_rsp_name6           -- �S���E��6
            , hl.attribute11          AS hl_rsp_name7           -- �S���E��7
            , hl.attribute12          AS hl_rsp_name8           -- �S���E��8
            , hl.attribute13          AS hl_rsp_name9           -- �S���E��9
            , hl.attribute14          AS hl_rsp_name10          -- �S���E��10
            , hl.attribute17          AS hl_locations_name      -- �e���Ə�ID
            , hl.attribute18          AS hl_include_exclude     -- �����_�o�׈˗��쐬�ۋ敪
            , hl.attribute20          AS hl_area                -- �n�於
            , hl.ship_to_site_flag    AS hl_ship_to_site_flag   -- �o�א�t���O
            , hl.receiving_site_flag  AS hl_receiving_site_flag -- �����t���O
            , hl.bill_to_site_flag    AS hl_bill_to_site_flag   -- ������t���O
            , hl.office_site_flag     AS hl_office_site_flag    -- �Г���t���O
            , hl.location_code        AS hl_location_code       -- ���Ə��R�[�h
            , hl.description          AS hl_description         -- �E�v
            , xla.location_name        AS xla_location_name      -- ������
            , xla.location_short_name  AS xla_location_shortname -- ����
            , xla.location_name_alt    AS xla_location_name_alt  -- �J�i��
            , xla.zip                  AS xla_zip                -- �X�֔ԍ�
            , xla.address_line1        AS xla_address            -- �Z��
            , xla.phone                AS xla_phone              -- �d�b�ԍ�
            , xla.fax                  AS xla_fax                -- FAX�ԍ�
            , xla.division_code        AS xla_division_code      -- �{���R�[�h
            -- �L���X�e�[�^�X
            , CASE
                WHEN  hl.inactive_date <= gd_coop_date THEN 'I'
                  ELSE 'A'
                END AS active_status
-- Ver1.1 Add Start
            -- NVL�ϊ��l
            , CASE
                WHEN gt_pre_prodate IS NULL THEN NULL
                WHEN hl.creation_date > gt_pre_prodate THEN NULL
                  ELSE '#NULL'
                END AS nvl_conversion
-- Ver1.1 Add End
-- Ver1.2 Add Start
            , hl.location_id          AS hl_location_id         -- ���P�[�V����ID
            --�o�א掖�Ə��R�[�h
            , CASE
                WHEN hl.ship_to_site_flag = 'N' THEN 
                  ( SELECT hl2.location_code AS hl2_location_code
                    FROM   hr_locations hl2
                    WHERE  hl.ship_to_location_id = hl2.location_id
                   )
                  ELSE NULL
                END AS ship_to_loc_code
            --�o�א掖�Ə��Z�b�g�E�R�[�h
            , CASE
                WHEN hl.ship_to_site_flag = 'N' THEN cv_setcode
                  ELSE NULL
                END AS ship_to_loc_setcode
-- Ver1.2 Add End
    FROM      hr_locations        hl  --���Ə��}�X�^
            , xxcmn_locations_all xla --���Ə��A�h�I���}�X�^
    WHERE
-- Ver1.2 Add Start
              hl.location_code NOT IN ( cv_loc_code_1,cv_loc_code_2 )
-- Ver1.2 Add End
      AND     hl.location_id = xla.location_id (+)
      AND     xla.start_date_active (+) <= gd_coop_date
      AND     NVL(xla.end_date_active (+) , gd_coop_date ) >= gd_coop_date
      AND     (
                (gt_pre_prodate IS NULL)
                OR
                (hl.last_update_date > gt_pre_prodate )
                OR
                (hl.inactive_date = gd_coop_date )
                OR
                (EXISTS (SELECT 1
                         FROM   xxcmn_locations_all xla2
                         WHERE  xla2.location_id = hl.location_id
                           AND  (
                                  (xla2.last_update_date > gt_pre_prodate )
                                  OR
                                  (xla2.start_date_active = gd_coop_date )
                                )
                        )
                )
              )
    ORDER BY  hl.location_code
    ;
--
  -- ===============================
  -- �O���[�o�����R�[�h�^
  -- ===============================
  -- ���Ə��}�X�^�i�[�p
  g_office_rec    get_office_cur%ROWTYPE;
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_proc_date_for_recovery          IN  VARCHAR2  -- 1.�Ɩ����t(���J�o���p)
    , ov_errbuf                          OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                         OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                          OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_msg            VARCHAR2(300)   DEFAULT NULL;                     -- ���b�Z�[�W�o�͗p
    lv_msg_preprodate VARCHAR2(100)   DEFAULT NULL;                     -- ���b�Z�[�W�o�͗p�O�񏈗�����
    lv_msg_prodate    VARCHAR2(100)   DEFAULT NULL;                     -- ���b�Z�[�W�o�͗p���񏈗�����
    lv_full_name      VARCHAR2(200)   DEFAULT NULL;                     -- �f�B���N�g���p�X�{�t�@�C�����A���l
    lt_dir_path       all_directories.directory_path%TYPE DEFAULT NULL; -- �f�B���N�g���p�X
    -- �t�@�C�����݃`�F�b�N�p
    lb_exists         BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length    NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size     BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- �p�����[�^�o��
    --==============================================================
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo            -- 'XXCFO'
                                       , cv_msg_cfo_60001          -- �p�����[�^�o�̓��b�Z�[�W
                                       , cv_tkn_param_name         -- 'PARAM_NAME'
                                       , cv_msg_cfo_60006          -- '�Ɩ����t�i���J�o���p�j'
                                       , cv_tkn_param_val          -- 'PARAM_VAL'
                                       , iv_proc_date_for_recovery -- �Ɩ����t�i���J�o���p�j
                                      );
    --���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    --���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    -- OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
    gv_dir_name := FND_PROFILE.VALUE( cv_data_filedir );
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    , cv_tkn_prof_name -- 'PROF_NAME'
                                                    , cv_data_filedir  -- 'XXCFO1_OIC_OUT_FILE_DIR'
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ���Ə��}�X�^�A�g�f�[�^�t�@�C����
    gv_file_name := FND_PROFILE.VALUE( cv_filename );
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    , cv_tkn_prof_name -- 'PROF_NAME'
                                                    , cv_filename      -- 'XXCFO1_OIC_LOC_MST_OUT_FILE'
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    BEGIN
      SELECT    RTRIM(ad.directory_path, cv_slash) AS directory_path
      INTO      lt_dir_path
      FROM      all_directories   ad
      WHERE     ad.directory_name = gv_dir_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_coi   -- 'XXCOI'
                                                      , cv_msg_coi_00029 -- �f�B���N�g���t���p�X�擾�G���[
                                                      , cv_tkn_dir_tok   -- 'DIR_TOK'
                                                      , gv_dir_name      -- OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
                                                     )
                             , 1
                             , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00015 -- �Ɩ����t�擾�G���[
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �A�g���t�ݒ�
    --==================================
    IF ( iv_proc_date_for_recovery IS NOT NULL ) THEN
      gd_coop_date := TO_DATE( iv_proc_date_for_recovery , cv_dateformat_ymdhms ) + 1;
    ELSE
      gd_coop_date := gd_process_date + 1;
    END IF; 
--
    --==================================
    -- �t�@�C�����o��
    --==================================
    lv_full_name := lt_dir_path || cv_slash || gv_file_name;
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                       , cv_msg_cfo_60002 -- �t�@�C�����o�̓��b�Z�[�W
                                       , cv_tkn_file_name -- 'FILE_NAME'
                                       , lv_full_name     -- �f�B���N�g���p�X�ƃt�@�C�����̘A������
                                      );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==================================
    -- ����t�@�C�����݃`�F�b�N
    --==================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gv_dir_name
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF ( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                    , cv_msg_cfo_00027 -- ����t�@�C������
                                                   )
                           , 1
                           , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �O�񏈗������擾
    --==============================================================
    BEGIN
      SELECT   fcp.concurrent_program_name  AS fcp_ccrt_pronam  -- �R���J�����g�v���O������
             , oipm.pre_process_date        AS oipm_pre_prodate -- �O�񏈗�����
      INTO     gt_ccrt_proname                                  -- �R���J�����g�v���O������
             , gt_pre_prodate                                   -- �O�񏈗�����
      FROM     fnd_concurrent_programs     fcp                  -- �R���J�����g�v���O����
             , xxccp_oic_if_process_mng    oipm                 -- OIC�A�g�����Ǘ��e�[�u��
      WHERE    fcp.concurrent_program_id = cn_program_id
        AND    fcp.concurrent_program_name = oipm.program_name (+)
      FOR UPDATE OF oipm.pre_process_date NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                      , cv_msg_cfo_00019 -- ���b�N�G���[���b�Z�[�W
                                                      , cv_tkn_table     -- 'TABLE'
                                                      , cv_msg_cfo_60008 -- 'OIC�A�g�Ǘ��e�[�u��'
                                                     )
                             , 1
                             , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ���񏈗������擾
    --==============================================================
    gd_prodate := SYSDATE;
--
    --==============================================================
    -- �O��E���񏈗������o��
    --==============================================================
    --���t�����ϊ�
    lv_msg_preprodate := TO_CHAR(gt_pre_prodate ,cv_dateformat_ymdhms);
    lv_msg_prodate    := TO_CHAR(gd_prodate     ,cv_dateformat_ymdhms);
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo    -- 'XXCFO'
                                       , cv_msg_cfo_60003  -- ���������o�̓��b�Z�[�W
                                       , cv_tkn_date1      -- 'DATE1'
                                       , lv_msg_preprodate -- �O�񏈗�����
                                       , cv_tkn_date2      -- 'DATE2'
                                       , lv_msg_prodate    -- ���񏈗�����
                                      );
     -- ���b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==============================================================
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(  location     => gv_dir_name
                                     , filename     => gv_file_name
                                     , open_mode    => cv_open_mode_w
                                     , max_linesize => cn_max_linesize
                                    );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                      , cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                     )
                             , 1
                             , 5000);
        lv_errbuf  := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
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
      ov_errmsg  := lv_errmsg;                                                  -- # �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            -- # �C�� #
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
   * Procedure Name   : output_office
   * Description      : �A�g�f�[�^���o(A-2)
   *                    I/F�t�@�C���o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_office(
      ov_errbuf      OUT VARCHAR2  -- �G���[�E���b�Z�[�W                  -- # �Œ� #
    , ov_retcode     OUT VARCHAR2  -- ���^�[���E�R�[�h                    -- # �Œ� #
    , ov_errmsg      OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W        -- # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_office'; -- �v���O������
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
    -- �w�b�_�p
    cv_h_metadata             CONSTANT VARCHAR2(100) := 'METADATA';                                             -- METADATA
    cv_h_location             CONSTANT VARCHAR2(100) := 'Location';                                             -- Location
    cv_h_flex_pld             CONSTANT VARCHAR2(100) := 'FLEX:PER_LOCATIONS_DF';                                -- FLEX:PER_LOCATIONS_DF
    cv_h_purchasingflag       CONSTANT VARCHAR2(100) := 'purchasingFlag(PER_LOCATIONS_DF=SALES-BU_DEPT)';       -- �w���S���t���O
    cv_h_shippingflag         CONSTANT VARCHAR2(100) := 'shippingFlag(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- �o�גS���t���O
    cv_h_rsp_name1            CONSTANT VARCHAR2(100) := 'responsibilityName1(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��1
    cv_h_rsp_name2            CONSTANT VARCHAR2(100) := 'responsibilityName2(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��2
    cv_h_rsp_name3            CONSTANT VARCHAR2(100) := 'responsibilityName3(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��3
    cv_h_rsp_name4            CONSTANT VARCHAR2(100) := 'responsibilityName4(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��4
    cv_h_rsp_name5            CONSTANT VARCHAR2(100) := 'responsibilityName5(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��5
    cv_h_rsp_name6            CONSTANT VARCHAR2(100) := 'responsibilityName6(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��6
    cv_h_rsp_name7            CONSTANT VARCHAR2(100) := 'responsibilityName7(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��7
    cv_h_rsp_name8            CONSTANT VARCHAR2(100) := 'responsibilityName8(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��8
    cv_h_rsp_name9            CONSTANT VARCHAR2(100) := 'responsibilityName9(PER_LOCATIONS_DF=SALES-BU_DEPT)';  -- �S���E��9
    cv_h_rsp_name10           CONSTANT VARCHAR2(100) := 'responsibilityName10(PER_LOCATIONS_DF=SALES-BU_DEPT)'; -- �S���E��10
    cv_h_locations_name       CONSTANT VARCHAR2(100) := 'locationsName(PER_LOCATIONS_DF=SALES-BU_DEPT)';        -- �e���Ə�ID
    cv_h_incld_excld          CONSTANT VARCHAR2(100) := 'includeExclude(PER_LOCATIONS_DF=SALES-BU_DEPT)';       -- �����_�o�׈˗��쐬�ۋ敪
    cv_h_area                 CONSTANT VARCHAR2(100) := 'area(PER_LOCATIONS_DF=SALES-BU_DEPT)';                 -- �n�於
    cv_h_location_name        CONSTANT VARCHAR2(100) := 'locationName(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- ������
    cv_h_location_shortname   CONSTANT VARCHAR2(100) := 'locationShortName(PER_LOCATIONS_DF=SALES-BU_DEPT)';    -- ����
    cv_h_location_name_alt    CONSTANT VARCHAR2(100) := 'locationNameAlt(PER_LOCATIONS_DF=SALES-BU_DEPT)';      -- �J�i��
    cv_h_zip                  CONSTANT VARCHAR2(100) := 'zip(PER_LOCATIONS_DF=SALES-BU_DEPT)';                  -- �X�֔ԍ�
    cv_h_address              CONSTANT VARCHAR2(100) := 'addressLine1(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- �Z��
    cv_h_phone                CONSTANT VARCHAR2(100) := 'phone(PER_LOCATIONS_DF=SALES-BU_DEPT)';                -- �d�b�ԍ�
    cv_h_fax                  CONSTANT VARCHAR2(100) := 'fax(PER_LOCATIONS_DF=SALES-BU_DEPT)';                  -- FAX�ԍ�
    cv_h_division_code        CONSTANT VARCHAR2(100) := 'divisionCode(PER_LOCATIONS_DF=SALES-BU_DEPT)';         -- �{���R�[�h
    cv_h_location_id          CONSTANT VARCHAR2(100) := 'LocationId';                                           -- ���P�[�V��������ID
    cv_h_setcode              CONSTANT VARCHAR2(100) := 'SetCode';                                              -- �Z�b�g�R�[�h
    cv_h_active_status        CONSTANT VARCHAR2(100) := 'ActiveStatus';                                         -- �L���X�e�[�^�X
    cv_h_ship_to_site_flag    CONSTANT VARCHAR2(100) := 'ShipToSiteFlag';                                       -- �o�א�t���O
    cv_h_receiving_site_flag  CONSTANT VARCHAR2(100) := 'ReceivingSiteFlag';                                    -- �����t���O
    cv_h_bill_to_site_flag    CONSTANT VARCHAR2(100) := 'BillToSiteFlag';                                       -- ������t���O
    cv_h_office_site_flag     CONSTANT VARCHAR2(100) := 'OfficeSiteFlag';                                       -- �Г���t���O
    cv_h_location_code        CONSTANT VARCHAR2(100) := 'LocationCode';                                         -- ���Ə��R�[�h
    cv_h_location_name_d      CONSTANT VARCHAR2(100) := 'LocationName';                                         -- �E�v
    cv_h_description          CONSTANT VARCHAR2(100) := 'Description';                                          -- �E�v
    cv_h_address_l            CONSTANT VARCHAR2(100) := 'AddressLine1';                                         -- �Z��
    cv_h_country              CONSTANT VARCHAR2(100) := 'Country';                                              -- ��
    cv_h_postalcode           CONSTANT VARCHAR2(100) := 'PostalCode';                                           -- �X�֔ԍ�
    cv_h_eff_startdate        CONSTANT VARCHAR2(100) := 'EffectiveStartDate';                                   -- �L���J�n��
    cv_h_eff_enddate          CONSTANT VARCHAR2(100) := 'EffectiveEndDate';                                     -- �L���I����
-- Ver1.2 Add Start
    cv_h_src_sys_owner        CONSTANT VARCHAR2(100) := 'SourceSystemOwner';                                    -- �\�[�X�E�V�X�e�����L��
    cv_h_src_sys_id           CONSTANT VARCHAR2(100) := 'SourceSystemId';                                       -- �\�[�X�E�V�X�e��ID
    cv_h_ship_to_loc_code     CONSTANT VARCHAR2(100) := 'ShipToLocationCode';                                   -- �o�א掖�Ə��R�[�h
    cv_h_ship_to_loc_setcode  CONSTANT VARCHAR2(100) := 'ShipToLocationSetCode';                                -- �o�א掖�Ə��Z�b�g�E�R�[�h
-- Ver1.2 Add End
    -- I/F�t�@�C���o�͗p�Œ�l
-- Ver1.1 Mod Start
--  cv_null               CONSTANT VARCHAR2(100) := '#NULL';            -- NULL�p
    cv_null               CONSTANT VARCHAR2(100)     DEFAULT NULL;      -- NULL�p
    cv_metadata           CONSTANT VARCHAR2(100) := 'MERGE';            -- METADATA
    cv_location           CONSTANT VARCHAR2(100) := 'Location';         -- Location
    cv_flex_locations_df  CONSTANT VARCHAR2(100) := 'SALES-BU_DEPT';    -- FLEX:PER_LOCATIONS_DF
--  cv_location_id        CONSTANT VARCHAR2(100) := '#NULL';            -- ���P�[�V��������ID
-- Ver1.2 Del Start
--  cv_setcode            CONSTANT VARCHAR2(100) := 'ITO_SALES_DSET01'; -- �Z�b�g�R�[�h
-- Ver1.2 Del End
    cv_country            CONSTANT VARCHAR2(100) := 'JP';               -- ��
    cv_eff_startdate      CONSTANT VARCHAR2(100) := '1900/01/01';       -- �L���J�n��
--  cv_eff_enddate        CONSTANT VARCHAR2(100) := '#NULL';            -- �L���I����
-- Ver1.1 Mod End
-- Ver1.2 Add Start
    cv_src_sys_owner      CONSTANT VARCHAR2(100) := 'EBS';               -- �\�[�X�E�V�X�e�����L��
-- Ver1.2 Add End

--
    -- *** ���[�J���ϐ� ***
    lv_msg_prodate     VARCHAR2(3000)   DEFAULT NULL; -- ���������o�͗p���b�Z�[�W
    lv_head            VARCHAR2(30000)  DEFAULT NULL; -- �w�b�_�������ݗp
    lv_file_data       VARCHAR2(30000)  DEFAULT NULL; -- �t�@�C���������ݗp
-- Ver1.1 Add Start
    lv_nvl_conversion  VARCHAR2(100)    DEFAULT NULL; -- NVL�ϊ��l�p
-- Ver1.1 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �w�b�_�p��
    lv_head := cv_h_metadata;                                     -- METADATA
    lv_head := lv_head || cv_delimit || cv_h_location;            -- Location
    lv_head := lv_head || cv_delimit || cv_h_flex_pld;            -- FLEX:PER_LOCATIONS_DF
    lv_head := lv_head || cv_delimit || cv_h_purchasingflag;      -- �w���S���t���O
    lv_head := lv_head || cv_delimit || cv_h_shippingflag;        -- �o�גS���t���O
    lv_head := lv_head || cv_delimit || cv_h_rsp_name1;           -- �S���E��1
    lv_head := lv_head || cv_delimit || cv_h_rsp_name2;           -- �S���E��2
    lv_head := lv_head || cv_delimit || cv_h_rsp_name3;           -- �S���E��3
    lv_head := lv_head || cv_delimit || cv_h_rsp_name4;           -- �S���E��4
    lv_head := lv_head || cv_delimit || cv_h_rsp_name5;           -- �S���E��5
    lv_head := lv_head || cv_delimit || cv_h_rsp_name6;           -- �S���E��6
    lv_head := lv_head || cv_delimit || cv_h_rsp_name7;           -- �S���E��7
    lv_head := lv_head || cv_delimit || cv_h_rsp_name8;           -- �S���E��8
    lv_head := lv_head || cv_delimit || cv_h_rsp_name9;           -- �S���E��9
    lv_head := lv_head || cv_delimit || cv_h_rsp_name10;          -- �S���E��10
    lv_head := lv_head || cv_delimit || cv_h_locations_name;      -- �e���Ə�ID
    lv_head := lv_head || cv_delimit || cv_h_incld_excld;         -- �����_�o�׈˗��쐬�ۋ敪
    lv_head := lv_head || cv_delimit || cv_h_area;                -- �n�於
    lv_head := lv_head || cv_delimit || cv_h_location_name;       -- ������
    lv_head := lv_head || cv_delimit || cv_h_location_shortname;  -- ����
    lv_head := lv_head || cv_delimit || cv_h_location_name_alt;   -- �J�i��
    lv_head := lv_head || cv_delimit || cv_h_zip;                 -- �X�֔ԍ�
    lv_head := lv_head || cv_delimit || cv_h_address;             -- �Z��
    lv_head := lv_head || cv_delimit || cv_h_phone;               -- �d�b�ԍ�
    lv_head := lv_head || cv_delimit || cv_h_fax;                 -- FAX�ԍ�
    lv_head := lv_head || cv_delimit || cv_h_division_code;       -- �{���R�[�h
    lv_head := lv_head || cv_delimit || cv_h_location_id;         -- ���P�[�V��������ID
    lv_head := lv_head || cv_delimit || cv_h_setcode;             -- �Z�b�g�R�[�h
    lv_head := lv_head || cv_delimit || cv_h_active_status;       -- �L���X�e�[�^�X
    lv_head := lv_head || cv_delimit || cv_h_ship_to_site_flag;   -- �o�א�t���O
    lv_head := lv_head || cv_delimit || cv_h_receiving_site_flag; -- �����t���O
    lv_head := lv_head || cv_delimit || cv_h_bill_to_site_flag;   -- ������t���O
    lv_head := lv_head || cv_delimit || cv_h_office_site_flag;    -- �Г���t���O
    lv_head := lv_head || cv_delimit || cv_h_location_code;       -- ���Ə��R�[�h
    lv_head := lv_head || cv_delimit || cv_h_location_name_d;     -- �E�v
    lv_head := lv_head || cv_delimit || cv_h_description;         -- �E�v
    lv_head := lv_head || cv_delimit || cv_h_address_l;           -- �Z��
    lv_head := lv_head || cv_delimit || cv_h_country;             -- ��
    lv_head := lv_head || cv_delimit || cv_h_postalcode;          -- �X�֔ԍ�
    lv_head := lv_head || cv_delimit || cv_h_eff_startdate;       -- �L���J�n��
    lv_head := lv_head || cv_delimit || cv_h_eff_enddate;         -- �L���I����
-- Ver1.2 Add Start
    lv_head := lv_head || cv_delimit || cv_h_src_sys_owner;       -- �\�[�X�E�V�X�e�����L��
    lv_head := lv_head || cv_delimit || cv_h_src_sys_id;          -- �\�[�X�E�V�X�e��ID
    lv_head := lv_head || cv_delimit || cv_h_ship_to_loc_code;    -- �o�א掖�Ə��R�[�h
    lv_head := lv_head || cv_delimit || cv_h_ship_to_loc_setcode; -- �o�א掖�Ə��Z�b�g�E�R�[�h
-- Ver1.2 Add End
--
    --===============================
    --  �A�g�f�[�^���o(A-2)
    --===============================
    -- �J�[�\���I�[�v��
    OPEN get_office_cur;
    --
    --===============================
    --  I/F�t�@�C���o��(A-3)
    --===============================
    -- �f�[�^��������
    <<main_loop>>
    LOOP
      -- ���R�[�h�t�F�b�`
      FETCH get_office_cur INTO g_office_rec;
      EXIT WHEN get_office_cur%NOTFOUND;
      --
      -- �w�b�_�o��
      BEGIN
        IF ( gn_target_cnt = 0 ) THEN
          UTL_FILE.PUT_LINE(  gf_file_hand
                            , lv_head
                             );
      END IF;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                         , cv_msg_cfo_00030 )  -- �t�@�C���������݃G���[
                                , 1
                                , 5000);
          lv_errbuf := lv_errmsg || SQLERRM;
          -- �t�@�C�����N���[�Y
          UTL_FILE.FCLOSE( gf_file_hand );
          RAISE global_process_expt;
      END;
      --
      -- �Ώۃf�[�^�����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
      --
-- Ver1.1 Mod Start
      -- �ϐ��̏�����
      lv_file_data := NULL;
      lv_nvl_conversion := NULL;
      --
      --�ϐ��ݒ�
      lv_nvl_conversion := g_office_rec.nvl_conversion;  --NVL�ϊ��l
      -- �f�[�^�ҏW
      lv_file_data := cv_metadata;                                                                               -- METADATA
      lv_file_data := lv_file_data || cv_delimit || cv_location;                                                 -- Location
      lv_file_data := lv_file_data || cv_delimit || cv_flex_locations_df;                                        -- FLEX:PER_LOCATIONS_DF
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_purchasing_flag     ,lv_nvl_conversion); -- �w���S���t���O
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_shipping_flag       ,lv_nvl_conversion); -- �o�גS���t���O
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name1           ,lv_nvl_conversion); -- �S���E��1
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name2           ,lv_nvl_conversion); -- �S���E��2
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name3           ,lv_nvl_conversion); -- �S���E��3
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name4           ,lv_nvl_conversion); -- �S���E��4
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name5           ,lv_nvl_conversion); -- �S���E��5
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name6           ,lv_nvl_conversion); -- �S���E��6
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name7           ,lv_nvl_conversion); -- �S���E��7
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name8           ,lv_nvl_conversion); -- �S���E��8
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name9           ,lv_nvl_conversion); -- �S���E��9
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_rsp_name10          ,lv_nvl_conversion); -- �S���E��10
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_locations_name      ,lv_nvl_conversion); -- �e���Ə�ID
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_include_exclude     ,lv_nvl_conversion); -- �����_�o�׈˗��쐬�ۋ敪
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_area                ,lv_nvl_conversion); -- �n�於
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_location_name      ,lv_nvl_conversion); -- ������
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_location_shortname ,lv_nvl_conversion); -- ����
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_location_name_alt  ,lv_nvl_conversion); -- �J�i��
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_zip                ,lv_nvl_conversion); -- �X�֔ԍ�
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_address            ,lv_nvl_conversion); -- �Z��
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_phone              ,lv_nvl_conversion); -- �d�b�ԍ�
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_fax                ,lv_nvl_conversion); -- FAX
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_division_code      ,lv_nvl_conversion); -- �{���R�[�h 
      lv_file_data := lv_file_data || cv_delimit || --lv_nvl_conversion;                                         -- ���P�[�V��������ID
                                                    cv_null;
      lv_file_data := lv_file_data || cv_delimit || cv_setcode;                                                  -- �Z�b�g�R�[�h
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.active_status          ,lv_nvl_conversion); -- �L���X�e�[�^�X
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_ship_to_site_flag   ,lv_nvl_conversion); -- �o�א�t���O
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_receiving_site_flag ,lv_nvl_conversion); -- �����t���O
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_bill_to_site_flag   ,lv_nvl_conversion); -- ������t���O
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_office_site_flag    ,lv_nvl_conversion); -- �Г���t���O
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_location_code       ,lv_nvl_conversion); -- ���Ə��R�[�h
      lv_file_data := lv_file_data || cv_delimit || --NVL(g_office_rec.hl_description       ,lv_nvl_conversion); -- �E�v
                                                    SUBSTR( NVL(g_office_rec.hl_description ,g_office_rec.hl_location_code) ,1,60);
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.hl_description         ,lv_nvl_conversion); -- �E�v
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_address            ,lv_nvl_conversion); -- �Z��
      lv_file_data := lv_file_data || cv_delimit || cv_country;                                                  -- ��
      lv_file_data := lv_file_data || cv_delimit || NVL(g_office_rec.xla_zip                ,lv_nvl_conversion); -- �X�֔ԍ�
      lv_file_data := lv_file_data || cv_delimit || cv_eff_startdate;                                            -- �L���J�n��
      lv_file_data := lv_file_data || cv_delimit || --lv_nvl_conversion;                                         -- �L���I����
                                                    cv_null;
-- Ver1.1 Mod End
-- Ver1.2 Add Start
      lv_file_data := lv_file_data || cv_delimit || cv_src_sys_owner;                                            -- �\�[�X�E�V�X�e�����L��
      lv_file_data := lv_file_data || cv_delimit || g_office_rec.hl_location_id;                                 -- �\�[�X�E�V�X�e��ID
      lv_file_data := lv_file_data || cv_delimit || g_office_rec.ship_to_loc_code;                               -- �o�א掖�Ə��R�[�h
      lv_file_data := lv_file_data || cv_delimit || g_office_rec.ship_to_loc_setcode;                            -- �o�א掖�Ə��Z�b�g�E�R�[�h
-- Ver1.2 Add End
      -- �f�[�^�o��
      BEGIN
        UTL_FILE.PUT_LINE( gf_file_hand
                         , lv_file_data
                         );
        -- �o�͌����J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                         , cv_msg_cfo_00030 )  -- �t�@�C���������݃G���[
                                , 1
                                , 5000);
          lv_errbuf := lv_errmsg || SQLERRM;
          -- �t�@�C�����N���[�Y
          UTL_FILE.FCLOSE( gf_file_hand );
          RAISE global_process_expt;
      END;
      --
    END LOOP main_loop;
    --
    -- �J�[�\���N���[�Y
    CLOSE get_office_cur;
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
      -- �J�[�\���N���[�Y
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  -- # �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            -- # �C�� #
      -- �J�[�\���N���[�Y
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ( get_office_cur%ISOPEN ) THEN
        CLOSE get_office_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_office;
--
  /**********************************************************************************
   * Procedure Name   : upd_oipm
   * Description      : �Ǘ��e�[�u���o�^�E�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_oipm (
      ov_errbuf             OUT VARCHAR2   -- �G���[�E���b�Z�[�W                  -- # �Œ� #
    , ov_retcode            OUT VARCHAR2   -- ���^�[���E�R�[�h                    -- # �Œ� #
    , ov_errmsg             OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W        -- # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'upd_oipm'; -- �v���O������
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
    --==============================================================
    -- OIC�A�g�����Ǘ��e�[�u���̓o�^�E�X�V����
    --==============================================================
    -- ����(�ڍs)������
    IF ( gt_pre_prodate IS NULL ) THEN
      BEGIN
        INSERT INTO xxccp_oic_if_process_mng (
                 program_name
               , pre_process_date
               -- WHO�J����
               , created_by
               , creation_date
               , last_updated_by
               , last_update_date
               , last_update_login
               , request_id
               , program_application_id
               , program_id
               , program_update_date 
        )VALUES(
                 gt_ccrt_proname
               , gd_prodate
               , cn_created_by
               , cd_creation_date
               , cn_last_updated_by
               , cd_last_update_date
               , cn_last_update_login
               , cn_request_id
               , cn_program_application_id
               , cn_program_id
               , cd_program_update_date
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                        , cv_msg_cfo_00024 -- �o�^�G���[���b�Z�[�W
                                                        , cv_tkn_table     -- 'TABLE'
                                                        , cv_msg_cfo_60008 -- 'OIC�A�g�Ǘ��e�[�u��'
                                                        , cv_tkn_err_msg   -- 'ERRMSG'
                                                        , SQLERRM          -- �G���[���e
                                                       )
                               , 1
                               , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    ELSE
      -- ����ȍ~������
      BEGIN
        UPDATE xxccp_oic_if_process_mng     oipm
        SET     oipm.pre_process_date         = gd_prodate
              , oipm.last_updated_by          = cn_last_updated_by
              , oipm.last_update_date         = cd_last_update_date
              , oipm.last_update_login        = cn_last_update_login
              , oipm.request_id               = cn_request_id
              , oipm.program_application_id   = cn_program_application_id
              , oipm.program_id               = cn_program_id
              , oipm.program_update_date      = cd_program_update_date
        WHERE   oipm.program_name = gt_ccrt_proname
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                                        , cv_msg_cfo_00020 -- �X�V�G���[���b�Z�[�W
                                                        , cv_tkn_table     -- 'TABLE'
                                                        , cv_msg_cfo_60008 -- 'OIC�A�g�Ǘ��e�[�u��'
                                                        , cv_tkn_err_msg   -- 'ERRMSG'
                                                        , SQLERRM          -- �G���[���e
                                                       )
                               , 1
                               , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
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
  END upd_oipm;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_date_for_recovery       IN  VARCHAR2   -- 1.�Ɩ����t�i���J�o���p�j
    , ov_errbuf                       OUT VARCHAR2   -- �G���[�E���b�Z�[�W           -- # �Œ� #
    , ov_retcode                      OUT VARCHAR2   -- ���^�[���E�R�[�h             -- # �Œ� #
    , ov_errmsg                       OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
--
    --===============================
    -- ��������(A-1)
    --===============================
    init(
        iv_proc_date_for_recovery -- 1.�Ɩ����t�i���J�o���p�j
      , lv_errbuf                 -- �G���[�E���b�Z�[�W           -- # �Œ� #
      , lv_retcode                -- ���^�[���E�R�[�h             -- # �Œ� #
      , lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================
    -- �A�g�f�[�^���o(A-2)
    -- I/F�t�@�C���o��(A-3)
    --===============================
    output_office(
        lv_errbuf  -- �G���[�E���b�Z�[�W           -- # �Œ� #
      , lv_retcode -- ���^�[���E�R�[�h             -- # �Œ� #
      , lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================
    -- �Ǘ��e�[�u���o�^�X�V����(A-4)
    --===============================
     upd_oipm(
         lv_errbuf  -- �G���[�E���b�Z�[�W           -- # �Œ� #
       , lv_retcode -- ���^�[���E�R�[�h             -- # �Œ� #
       , lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
     );
     IF (lv_retcode = cv_status_error ) THEN
       RAISE global_process_expt;
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
      errbuf                      OUT VARCHAR2  -- �G���[�E���b�Z�[�W  -- # �Œ� #
    , retcode                     OUT VARCHAR2  -- ���^�[���E�R�[�h    -- # �Œ� #
    , iv_proc_date_for_recovery   IN  VARCHAR2) -- 1.�Ɩ����t�i���J�o���p�j
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
    lv_errbuf          VARCHAR2(5000);            -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);               -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);             -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
     , ov_errbuf  => lv_errbuf
     , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    --===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --===============================================
    submain(
       iv_proc_date_for_recovery                   -- 1.�Ɩ����t�i���J�o���p�j
     , lv_errbuf   -- �G���[�E���b�Z�[�W           -- # �Œ� #
     , lv_retcode  -- ���^�[���E�R�[�h             -- # �Œ� #
     , lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg -- �G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf -- ���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --====================================================
    -- �I������(A-5)
    --====================================================
    -- �t�@�C���N���[�Y
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand )) THEN
      UTL_FILE.FCLOSE( gf_file_hand );
    END IF;
--
    -- ���o�����o��
    gv_out_msg :=xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                          , cv_msg_cfo_60004 -- �����ΏہE�������b�Z�[�W
                                          , cv_tkn_target    -- 'TARGET'
                                          , cv_msg_cfo_60007 -- '���Ə��}�X�^���'
                                          , cv_tkn_count     -- 'COUNT'
                                          , gn_target_cnt    -- ��������
                                          );
    -- ���b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �o�͌����o��
    gv_out_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                           , cv_msg_cfo_60005 -- �t�@�C���o�͑ΏہE�������b�Z�[�W
                                           , cv_tkn_target    -- 'TARGET'
                                           , gv_file_name     -- �v���t�@�C���l�u���Ə��}�X�^�A�g�f�[�^�t�@�C�����v
                                           , cv_tkn_count     -- 'COUNT'
                                           , gn_normal_cnt    -- �o�͐�������
                                          );
    -- ���b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name     -- 'XXCCP'
                    , iv_name         => cv_target_rec_msg      -- �Ώی������b�Z�[�W
                    , iv_token_name1  => cv_cnt_token           -- �������b�Z�[�W�p�g�[�N����
                    , iv_token_value1 => TO_CHAR(gn_target_cnt) -- �Ώی���
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name     -- 'XXCCP'
                    , iv_name         => cv_success_rec_msg     -- �����������b�Z�[�W
                    , iv_token_name1  => cv_cnt_token           -- �������b�Z�[�W�p�g�[�N����
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt) -- ��������
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name     -- 'XXCCP'
                    , iv_name         => cv_error_rec_msg       -- �G���[�������b�Z�[�W
                    , iv_token_name1  => cv_cnt_token           -- �������b�Z�[�W�p�g�[�N����
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)  -- �G���[����
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(  iv_application  => cv_appl_short_name
                                           , iv_name         => lv_message_code
                                          );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
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
--###########################  �Œ蕔 END   #######################################################
  END main;
--
END XXCFO016A04C;
/
 