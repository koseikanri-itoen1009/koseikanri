CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS003A07C (body)
 * Description      : �x���_�[�i���уp�[�W
 * MD.050           : �x���_�[�i���уp�[�W MD050_COS_003_A07
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  del_old_data           �ő�ێ����Ԃ��ߋ��f�[�^�폜(A-2)
 *  del_xxcos_vd_deliv     �x���_�[�i���і��׍폜(A-4)
 *  submain                ���C�������v���V�[�W��
 *                           �x���_�[�i���уf�[�^���o(A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/10/06    1.0   K.Nakamura       �V�K�쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  gn_target1_cnt   NUMBER;                    -- �w�b�_�Ώی���
  gn_target2_cnt   NUMBER;                    -- ���בΏی���
  gn_normal1_cnt   NUMBER;                    -- �w�b�_�폜����
  gn_normal2_cnt   NUMBER;                    -- ���׍폜����
  gn_skip1_cnt     NUMBER;                    -- �w�b�_�X�L�b�v����
  gn_skip2_cnt     NUMBER;                    -- ���׃X�L�b�v����
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �x������
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
  -- ���b�N��O
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  -- �x������O
  warn_expt                 EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS003A07C';    -- �p�b�P�[�W��
  cv_application            CONSTANT VARCHAR2(10)  := 'XXCOS';           -- �A�v���P�[�V������(�̔�)
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';           -- �A�h�I���F���ʁEIF�̈�
  -- ���b�Z�[�W
  cv_msg_no_data_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^�����G���[
  cv_msg_profile_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G��
  cv_msg_delete_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00012'; -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_process_date_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- �Ɩ��������擾�G���[
  cv_msg_lock_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14308'; -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_no_param           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ�
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE';          -- �v���t�@�C����
  cv_tkn_table_name         CONSTANT VARCHAR2(20) := 'TABLE_NAME';       -- �e�[�u����
  cv_tkn_key_data           CONSTANT VARCHAR2(20) := 'KEY_DATA';         -- �L�[����
  -- �v���t�@�C��
  cv_vd_deliv_hold_month    CONSTANT VARCHAR2(30) := 'XXCOS1_VD_DELIV_HOLD_MONTH';      -- XXCOS:�x���_�[�i���ѕێ�����
  cv_vd_deliv_hold_time     CONSTANT VARCHAR2(30) := 'XXCOS1_VD_DELIV_HOLD_TIME';       -- XXCOS:�x���_�[�i���ѕێ���
  cv_period_use_data        CONSTANT VARCHAR2(50) := 'XXCOI1_PERIOD_USE_DATA_FORECAST'; -- XXCOI:�̔��\���f�[�^���p����
  -- �Q�ƃR�[�h
  cv_lookup_type_gyotai     CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03';  -- �Ƒԁi�����ށj
  -- ���b�Z�[�W�o�͕���
  cv_profile_hold_month     CONSTANT VARCHAR2(50) := 'XXCOS:�x���_�[�i���ѕێ�����';           -- �v���t�@�C����
  cv_profile_hold_time      CONSTANT VARCHAR2(50) := 'XXCOS:�x���_�[�i���ѕێ���';           -- �v���t�@�C����
  cv_profile_use_data       CONSTANT VARCHAR2(50) := 'XXCOI:�̔��\���f�[�^���p����';           -- �v���t�@�C����
  cv_xxcos_vd_deliv         CONSTANT VARCHAR2(50) := '�x���_�[�i���сi�w�b�_�E���ׁj�e�[�u��'; -- �e�[�u����
  cv_xxcos_vd_deliv_headers CONSTANT VARCHAR2(50) := '�x���_�[�i���уw�b�_�e�[�u��';           -- �e�[�u����
  cv_xxcos_vd_deliv_lines   CONSTANT VARCHAR2(50) := '�x���_�[�i���і��׃e�[�u��';             -- �e�[�u����
  cv_customer_code          CONSTANT VARCHAR2(20) := '�ڋq�R�[�h';                             -- ���ږ�
  cv_delete_date            CONSTANT VARCHAR2(20) := '�폜���t';                               -- ���ږ�
  -- ����
  cv_date_format            CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; -- ���t����
  -- �t���O
  cv_flag_on                CONSTANT VARCHAR2(1)  := 'Y'; -- �L���t���O
  cv_forecast_use_flag      CONSTANT VARCHAR2(1)  := 'Y'; -- �̔��\�����p�t���O
  -- ����
  ct_language               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �x���_�[�i���э폜���
  gt_customer_number        xxcos_vd_deliv_headers.customer_number%TYPE; -- �ڋq�R�[�h
  gt_dlv_date               xxcos_vd_deliv_headers.dlv_date%TYPE;        -- �[�i���i�폜���t�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_vd_deliv_hold_month    NUMBER           DEFAULT NULL;      -- �x���_�[�i���ѕێ�����
  gn_vd_deliv_hold_time     NUMBER           DEFAULT NULL;      -- �x���_�[�i���ѕێ���
  gn_period_use_data        NUMBER           DEFAULT NULL;      -- �̔��\���f�[�^���p����
  gd_process_date           DATE             DEFAULT NULL;      -- �Ɩ����t
  gt_key_info               fnd_new_messages.message_text%TYPE; -- ���b�Z�[�W�o�͗p�L�[���
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => cv_msg_no_param
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- �Ɩ����������擾
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    -- �Ɩ��������擾�G���[�̏ꍇ
    IF ( gd_process_date IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_msg_process_date_err
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(�x���_�[�i���ѕێ�����)
    --==============================================================
    BEGIN
      gn_vd_deliv_hold_month := FND_PROFILE.VALUE(cv_vd_deliv_hold_month);
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => cv_profile_hold_month
                     );
        RAISE warn_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gn_vd_deliv_hold_month IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_hold_month
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(�x���_�[�i���ѕێ���)
    --==============================================================
    BEGIN
      gn_vd_deliv_hold_time := TO_NUMBER(FND_PROFILE.VALUE(cv_vd_deliv_hold_time));
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => cv_profile_hold_time
                     );
        RAISE warn_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gn_vd_deliv_hold_time IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_hold_time
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(�̔��\���f�[�^���p����)
    --==============================================================
    BEGIN
      gn_period_use_data := TO_NUMBER(FND_PROFILE.VALUE(cv_period_use_data));
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => cv_profile_use_data
                     );
        RAISE warn_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gn_period_use_data IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_use_data
                   );
      RAISE warn_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������x������O�n���h�� ***
    WHEN warn_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      -- �x�������J�E���g�A�b�v
      gn_warn_cnt := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
   * Procedure Name   : del_old_data
   * Description      : �ő�ێ����Ԃ��ߋ��f�[�^�폜(A-2)
   ***********************************************************************************/
  PROCEDURE del_old_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_old_data'; -- �v���O������
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
    ln_xvdh_cnt                      NUMBER  DEFAULT 0;     -- �x���_�[�i���уw�b�_����
    ln_xvdl_cnt                      NUMBER  DEFAULT 0;     -- �x���_�[�i���і��׌���
    ld_max_date                      DATE    DEFAULT NULL;  -- �ő�ێ����t
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �x���_�[�i���у��R�[�h���b�N�J�[�\��
    CURSOR old_data_lock_cur
    IS
      SELECT xvdh.rowid             xvdh_rowid                -- �x���_�[�i���уw�b�_����
           , xvdl.rowid             xvdl_rowid                -- �x���_�[�i���і��׌���
      FROM   xxcos_vd_deliv_headers xvdh                      -- �x���_�[�i���уw�b�_
           , xxcos_vd_deliv_lines   xvdl                      -- �x���_�[�i���і���
      WHERE  xvdh.customer_number   = xvdl.customer_number(+) -- �ڋq�R�[�h
      AND    xvdh.dlv_date          = xvdl.dlv_date(+)        -- �[�i��
      AND    xvdh.dlv_date          < ld_max_date             -- �[�i��
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ő�ێ����t�擾
    ld_max_date := ADD_MONTHS(gd_process_date, - (gn_period_use_data));
--
    -- �x���_�[�i���ь����擾
    SELECT xvdhv.xvdh_cnt                              -- �w�b�_����
         , xvdlv.xvdl_cnt                              -- ���׌���
    INTO   ln_xvdh_cnt
         , ln_xvdl_cnt
    FROM   (
             SELECT /*+ index_ffs(xvdh xxcos_vd_deliv_headers_pk) */
                    COUNT(xvdh.rowid)      xvdh_cnt    -- �w�b�_����
             FROM   xxcos_vd_deliv_headers xvdh        -- �x���_�[�i���уw�b�_
             WHERE  xvdh.dlv_date        < ld_max_date -- �[�i��
           ) xvdhv
         , (
             SELECT /*+ index_ffs(xvdl xxcos_vd_deliv_lines_pk) */
                    COUNT(xvdl.rowid)      xvdl_cnt    -- ���׌���
             FROM   xxcos_vd_deliv_lines   xvdl        -- �x���_�[�i���і���
             WHERE  xvdl.dlv_date        < ld_max_date -- �[�i��
           ) xvdlv
    ;
--
    -- �w�b�_�Ώی����J�E���g�A�b�v
    gn_target1_cnt := ln_xvdh_cnt;
    -- ���בΏی����J�E���g�A�b�v
    gn_target2_cnt := ln_xvdl_cnt;
--
    -- �Ώۃf�[�^�����݂���ꍇ
    IF ( ( gn_target1_cnt > 0)
      OR ( gn_target2_cnt > 0) ) THEN
      --
      -- ���b�N�擾
      OPEN old_data_lock_cur;
      CLOSE old_data_lock_cur;
      --
      -- �w�b�_�폜�Ώۂ����݂���ꍇ
      IF ( gn_target1_cnt > 0) THEN
        BEGIN
          -- �x���_�[�i���уw�b�_�폜
          DELETE FROM xxcos_vd_deliv_headers xvdh
          WHERE  xvdh.dlv_date < ld_max_date
          ;
          -- �폜�����J�E���g�A�b�v
          gn_normal1_cnt := SQL%ROWCOUNT;
        EXCEPTION
          WHEN OTHERS THEN
            -- �X�L�b�v�����J�E���g�A�b�v
            gn_skip1_cnt := gn_target1_cnt;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                            ,ov_retcode     => lv_retcode
                                            ,ov_errmsg      => lv_errmsg
                                            ,ov_key_info    => gt_key_info
                                            ,iv_item_name1  => cv_delete_date
                                            ,iv_data_value1 => TO_CHAR(ld_max_date,cv_date_format));
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_delete_err
                           ,iv_token_name1  => cv_tkn_table_name
                           ,iv_token_value1 => cv_xxcos_vd_deliv_headers
                           ,iv_token_name2  => cv_tkn_key_data
                           ,iv_token_value2 => gt_key_info
                         );
            lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
            ov_retcode := cv_status_warn;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
        END;
      END IF;
      --
      -- ���׍폜�Ώۂ����݂���ꍇ
      IF ( gn_target2_cnt > 0) THEN
        BEGIN
          -- �x���_�[�i���і��׍폜
          DELETE FROM xxcos_vd_deliv_lines xvdl
          WHERE  xvdl.dlv_date < ld_max_date
          ;
          -- �폜�����J�E���g�A�b�v
          gn_normal2_cnt := SQL%ROWCOUNT;
        EXCEPTION
          WHEN OTHERS THEN
            -- �X�L�b�v�����J�E���g�A�b�v
            gn_skip2_cnt := gn_target2_cnt;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                            ,ov_retcode     => lv_retcode
                                            ,ov_errmsg      => lv_errmsg
                                            ,ov_key_info    => gt_key_info
                                            ,iv_item_name1  => cv_delete_date
                                            ,iv_data_value1 => TO_CHAR(ld_max_date,cv_date_format));
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_delete_err
                           ,iv_token_name1  => cv_tkn_table_name
                           ,iv_token_value1 => cv_xxcos_vd_deliv_lines
                           ,iv_token_name2  => cv_tkn_key_data
                           ,iv_token_value2 => gt_key_info
                         );
            lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
            ov_retcode := cv_status_warn;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
        END;
      END IF;
    END IF;
--
  EXCEPTION
    -- ���b�N��O
    WHEN lock_expt THEN
      -- �X�L�b�v�����J�E���g�A�b�v
      gn_skip1_cnt := gn_target1_cnt;
      gn_skip2_cnt := gn_target2_cnt;
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                      ,ov_retcode     => lv_retcode
                                      ,ov_errmsg      => lv_errmsg
                                      ,ov_key_info    => gt_key_info
                                      ,iv_item_name1  => cv_delete_date
                                      ,iv_data_value1 => TO_CHAR(ld_max_date,cv_date_format));
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_lock_err
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => cv_xxcos_vd_deliv
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => gt_key_info
                   );
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
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
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_old_data;
--
  /**********************************************************************************
   * Procedure Name   : del_xxcos_vd_deliv
   * Description      : �x���_�[�i���э폜(A-4)
   ***********************************************************************************/
  PROCEDURE del_xxcos_vd_deliv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xxcos_vd_deliv'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_head_cnt                      NUMBER  DEFAULT 0;     -- �Ώۃw�b�_����
    ln_line_cnt                      NUMBER  DEFAULT 0;     -- �Ώۖ��׌���
    lb_lock_flag                     BOOLEAN DEFAULT FALSE; -- ���b�N�t���O
    lb_stop_del_flag                 BOOLEAN DEFAULT FALSE; -- �w�b�_�폜���~�t���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �x���_�[�i���у��R�[�h���b�N�J�[�\��
    CURSOR xxcos_vd_deliv_lock_cur
    IS
      SELECT xvdh.rowid             xvdh_rowid
           , xvdl.rowid             xvdl_rowid
      FROM   xxcos_vd_deliv_headers xvdh                      -- �x���_�[�i���уw�b�_
           , xxcos_vd_deliv_lines   xvdl                      -- �x���_�[�i���і���
      WHERE  xvdh.customer_number   = xvdl.customer_number(+) -- �ڋq�R�[�h
      AND    xvdh.dlv_date          = xvdl.dlv_date(+)        -- �[�i��
      AND    xvdh.customer_number   = gt_customer_number      -- �ڋq�R�[�h
      AND    xvdh.dlv_date          < gt_dlv_date             -- �[�i��
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    lv_errbuf          := NULL;
    lv_errmsg          := NULL;
    ln_head_cnt        := 0;
    ln_line_cnt        := 0;
    lb_lock_flag       := FALSE;
    lb_stop_del_flag   := FALSE;
    gt_key_info        := NULL;
--
    -- �x���_�[�i���ь����擾
    SELECT xvdhv.xvdh_cnt                                       -- �w�b�_����
         , xvdlv.xvdl_cnt                                       -- ���׌���
    INTO   ln_head_cnt
         , ln_line_cnt
    FROM   ( 
             SELECT COUNT(xvdh.rowid)      xvdh_cnt             -- �w�b�_����
             FROM   xxcos_vd_deliv_headers xvdh                 -- �x���_�[�i���уw�b�_
             WHERE  xvdh.customer_number   = gt_customer_number -- �ڋq�R�[�h
             AND    xvdh.dlv_date          < gt_dlv_date        -- �[�i��
           ) xvdhv
         , ( 
             SELECT COUNT(xvdl.rowid)      xvdl_cnt             -- ���׌���
             FROM   xxcos_vd_deliv_lines   xvdl                 -- �x���_�[�i���і���
             WHERE  xvdl.customer_number   = gt_customer_number -- �ڋq�R�[�h
             AND    xvdl.dlv_date          < gt_dlv_date        -- �[�i��
           ) xvdlv
    ;
    --
    -- �w�b�_�Ώی����J�E���g�A�b�v
    gn_target1_cnt := gn_target1_cnt + ln_head_cnt;
    -- ���בΏی����J�E���g�A�b�v
    gn_target2_cnt := gn_target2_cnt + ln_line_cnt;
    --
    -- �Ώۃf�[�^�����݂���ꍇ
    IF ( ( ln_head_cnt > 0)
      OR ( ln_line_cnt > 0) ) THEN
      --
      -- ���b�N�擾
      BEGIN
        OPEN xxcos_vd_deliv_lock_cur;
        CLOSE xxcos_vd_deliv_lock_cur;
      EXCEPTION
        WHEN lock_expt THEN
          -- �X�L�b�v�����J�E���g�A�b�v
          gn_skip1_cnt := gn_skip1_cnt + ln_head_cnt;
          gn_skip2_cnt := gn_skip2_cnt + ln_line_cnt;
          IF ( xxcos_vd_deliv_lock_cur%ISOPEN ) THEN
            CLOSE xxcos_vd_deliv_lock_cur;
          END IF;
          lb_lock_flag := TRUE;
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                          ,ov_retcode     => lv_retcode
                                          ,ov_errmsg      => lv_errmsg
                                          ,ov_key_info    => gt_key_info
                                          ,iv_item_name1  => cv_customer_code
                                          ,iv_data_value1 => gt_customer_number
                                          ,iv_item_name2  => cv_delete_date
                                          ,iv_data_value2 => TO_CHAR(gt_dlv_date,cv_date_format));
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_lock_err
                         ,iv_token_name1  => cv_tkn_table_name
                         ,iv_token_value1 => cv_xxcos_vd_deliv
                         ,iv_token_name2  => cv_tkn_key_data
                         ,iv_token_value2 => gt_key_info
                       );
          lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_warn;
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        WHEN OTHERS THEN
          IF ( xxcos_vd_deliv_lock_cur%ISOPEN ) THEN
            CLOSE xxcos_vd_deliv_lock_cur;
          END IF;
          RAISE;
      END;
      --
      -- ���b�N�擾���ł����ꍇ
      IF ( lb_lock_flag = FALSE ) THEN
        -- ���׍폜�Ώۂ����݂���ꍇ
        IF ( ln_line_cnt > 0 ) THEN
          --
          BEGIN
            -- �x���_�[�i���і��׍폜
            DELETE FROM xxcos_vd_deliv_lines xvdl
            WHERE  xvdl.customer_number = gt_customer_number -- �ڋq�R�[�h
            AND    xvdl.dlv_date        < gt_dlv_date        -- �[�i��
            ;
            -- �폜�����J�E���g�A�b�v
            gn_normal2_cnt := gn_normal2_cnt + SQL%ROWCOUNT;
          EXCEPTION
            WHEN OTHERS THEN
              -- �X�L�b�v�����J�E���g�A�b�v
              gn_skip1_cnt := gn_skip1_cnt + ln_head_cnt;
              gn_skip2_cnt := gn_skip2_cnt + ln_line_cnt;
              -- �w�b�_�폜���~�t���O
              lb_stop_del_flag := TRUE;
              xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                              ,ov_retcode     => lv_retcode
                                              ,ov_errmsg      => lv_errmsg
                                              ,ov_key_info    => gt_key_info
                                              ,iv_item_name1  => cv_customer_code
                                              ,iv_data_value1 => gt_customer_number
                                              ,iv_item_name2  => cv_delete_date
                                              ,iv_data_value2 => TO_CHAR(gt_dlv_date,cv_date_format));
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                             ,iv_name         => cv_msg_delete_err
                             ,iv_token_name1  => cv_tkn_table_name
                             ,iv_token_value1 => cv_xxcos_vd_deliv_lines
                             ,iv_token_name2  => cv_tkn_key_data
                             ,iv_token_value2 => gt_key_info
                           );
              lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_warn;
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
          END;
        END IF;
        --
        -- �w�b�_�폜�Ώۂ����݂���ꍇ�����ׂ��폜�ł����ꍇ
        IF (  ( ln_head_cnt > 0 )
          AND ( lb_stop_del_flag = FALSE ) ) THEN
          --
          BEGIN
            -- �x���_�[�i���уw�b�_�폜
            DELETE FROM xxcos_vd_deliv_headers xvdh
            WHERE  xvdh.customer_number = gt_customer_number -- �ڋq�R�[�h
            AND    xvdh.dlv_date        < gt_dlv_date        -- �[�i��
            ;
            -- �폜�����J�E���g�A�b�v
            gn_normal1_cnt := gn_normal1_cnt + SQL%ROWCOUNT;
          EXCEPTION
            WHEN OTHERS THEN
              -- �X�L�b�v�����J�E���g�A�b�v
              gn_skip1_cnt := gn_skip1_cnt + ln_head_cnt;
              xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                              ,ov_retcode     => lv_retcode
                                              ,ov_errmsg      => lv_errmsg
                                              ,ov_key_info    => gt_key_info
                                              ,iv_item_name1  => cv_customer_code
                                              ,iv_data_value1 => gt_customer_number
                                              ,iv_item_name2  => cv_delete_date
                                              ,iv_data_value2 => TO_CHAR(gt_dlv_date,cv_date_format));
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                             ,iv_name         => cv_msg_delete_err
                             ,iv_token_name1  => cv_tkn_table_name
                             ,iv_token_value1 => cv_xxcos_vd_deliv_headers
                             ,iv_token_name2  => cv_tkn_key_data
                             ,iv_token_value2 => gt_key_info
                           );
              lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_warn;
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
          END;
        END IF;
      END IF;
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
  END del_xxcos_vd_deliv;
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
    cv_dummy_char           CONSTANT VARCHAR2(1) := 'X'; -- �_�~�[����
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �x���_�[�i���уJ�[�\��
    CURSOR xxcos_vd_deliv_cur
    IS
      SELECT xvdhiv1.customer_number                                 customer_number -- �ڋqID
           , xvdhiv1.dlv_date                                        hold_time       -- �ێ����t�i�񐔁j
           , ADD_MONTHS(gd_process_date, - (gn_vd_deliv_hold_month)) hold_month      -- �ێ����t�i�����j
           , xvdhiv1.rownumber                                       rownumber       -- ����
      FROM
           (
             SELECT xvdhv2.customer_number                           customer_number -- �ڋqID
                  , xvdhv2.dlv_date                                  dlv_date        -- �[�i��
                  , ROW_NUMBER() OVER (PARTITION BY xvdhv2.customer_number ORDER BY xvdhv2.dlv_date DESC)
                                                                     rownumber       -- �ڋq���Ƃɔ[�i���Ń\�[�g���ď��ԕt��
             FROM
                  (
                    SELECT /*+ LEADING(flv xca xvdh) USE_NL(flv xca xvdh) */
                           xvdh.customer_number   customer_number                 -- �ڋq�R�[�h
                         , xvdh.dlv_date          dlv_date                        -- �[�i��
                    FROM   xxcos_vd_deliv_headers xvdh                            -- �x���_�[�i���уw�b�_
                         , xxcmm_cust_accounts    xca                             -- �ڋq�ǉ����
                         , fnd_lookup_values      flv                             -- �N�C�b�N�R�[�h
                    WHERE  xvdh.customer_number   = xca.customer_code             -- �ڋq�R�[�h
                    AND    xca.business_low_type  = flv.meaning                   -- �Ƒԁi�����ށj
                    AND    flv.lookup_type        = cv_lookup_type_gyotai         -- �^�C�v
                    AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                               AND NVL(flv.end_date_active, gd_process_date)
                                                                                  -- �L����
                    AND    flv.enabled_flag       = cv_flag_on                    -- �L���t���O
                    AND    flv.language           = ct_language                   -- ����
                    AND    xca.calendar_code IS NOT NULL                          -- �ғ����J�����_�R�[�h
                    AND EXISTS (
                                 SELECT cv_dummy_char      dummy_char
                                 FROM   bom_calendars      bc                     -- �ғ����J�����_
                                      , bom_calendar_dates bcd                    -- �ғ����J�����_���t
                                 WHERE  bc.calendar_code   = bcd.calendar_code    -- �J�����_�R�[�h
                                 AND    bc.calendar_code   = xca.calendar_code    -- �ғ����J�����_�R�[�h
                                 AND    bcd.calendar_date  = xvdh.dlv_date        -- �J�����_���t
                                 AND    bc.attribute1      = cv_forecast_use_flag -- �̔��\�����p�t���O�i�̔��\���J�����_�j
                                 AND    bcd.seq_num   IS NOT NULL                 -- ���ԁi��ғ��������O�j
                               )
                    UNION ALL
                    SELECT /*+ LEADING(flv xca xvdh) USE_NL(flv xca xvdh) */
                           xvdh.customer_number   customer_number              -- �ڋq�R�[�h
                         , xvdh.dlv_date          dlv_date                     -- �[�i��
                    FROM   xxcos_vd_deliv_headers xvdh                         -- �x���_�[�i���уw�b�_
                         , xxcmm_cust_accounts    xca                          -- �ڋq�ǉ����
                         , fnd_lookup_values      flv                          -- �N�C�b�N�R�[�h
                    WHERE  xvdh.customer_number   = xca.customer_code          -- �ڋq�R�[�h
                    AND    xca.business_low_type  = flv.meaning                -- �Ƒԁi�����ށj
                    AND    flv.lookup_type        = cv_lookup_type_gyotai      -- �^�C�v
                    AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                               AND NVL(flv.end_date_active, gd_process_date)
                                                                               -- �L����
                    AND    flv.enabled_flag       = cv_flag_on                 -- �L���t���O
                    AND    flv.language           = ct_language                -- ����
                    AND  (
                           ( xca.calendar_code IS NULL )                       -- �ғ����J�����_�R�[�h
                           OR
                           ( xca.calendar_code IS NOT NULL                     -- �ғ����J�����_�R�[�h
                           AND NOT EXISTS (
                                            SELECT cv_dummy_char      dummy_char
                                            FROM   bom_calendars      bc                     -- �ғ����J�����_
                                                 , bom_calendar_dates bcd                    -- �ғ����J�����_���t
                                            WHERE  bc.calendar_code   = bcd.calendar_code    -- �J�����_�R�[�h
                                            AND    bc.calendar_code   = xca.calendar_code    -- �ғ����J�����_�R�[�h
                                            AND    bc.attribute1      = cv_forecast_use_flag -- �̔��\�����p�t���O�i�̔��\���J�����_�j
                                          )
                           )
                         )
                  ) xvdhv2
           ) xvdhiv1
      WHERE  xvdhiv1.rownumber = gn_vd_deliv_hold_time -- �x���_�[�i���т̌ڋq���Ƃɕێ��񐔂̃f�[�^���擾
      ORDER BY xvdhiv1.customer_number                 -- �ڋq�R�[�h
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target1_cnt := 0;
    gn_target2_cnt := 0;
    gn_normal1_cnt := 0;
    gn_normal2_cnt := 0;
    gn_skip1_cnt   := 0;
    gn_skip2_cnt   := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �ő�ێ����Ԃ��ߋ��f�[�^�폜(A-2)
    -- ===============================
    del_old_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �x�����������Ă��p������
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �x���_�[�i���уf�[�^���o(A-3)
    -- ===============================
    <<del_vd_deliv_loop>>
    FOR l_xxcos_vd_deliv_rec IN xxcos_vd_deliv_cur LOOP
      -- ������
      gt_customer_number := NULL;
      gt_dlv_date        := NULL;
      -- �ڋq�R�[�h
      gt_customer_number := l_xxcos_vd_deliv_rec.customer_number;
      -- �폜���t
      IF ( l_xxcos_vd_deliv_rec.hold_time >= l_xxcos_vd_deliv_rec.hold_month ) THEN
        gt_dlv_date := l_xxcos_vd_deliv_rec.hold_month;
      ELSE
        gt_dlv_date := l_xxcos_vd_deliv_rec.hold_time;
      END IF;
      --
      -- ===============================
      -- �x���_�[�i���і��׍폜(A-4)
      -- ===============================
      del_xxcos_vd_deliv(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP xxcos_vd_deliv_loop;
--
    -- �Ώی���0���̏ꍇ
    IF (  ( gn_target1_cnt = 0 )
      AND ( gn_target2_cnt = 0 ) ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_no_data_err
                   );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
    END IF;
    --
    -- �X�L�b�v���������݂���ꍇ�A�x��
    IF ( ( gn_skip1_cnt > 0 )
      OR ( gn_skip2_cnt > 0 ) ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** �x����O�n���h�� ***
    WHEN warn_expt THEN
      ov_retcode := cv_status_warn;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_target1_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14301'; -- �w�b�_�Ώی������b�Z�[�W
    cv_target2_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14302'; -- ���בΏی������b�Z�[�W
    cv_delete1_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14303'; -- �w�b�_�폜�������b�Z�[�W
    cv_delete2_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14304'; -- ���׍폜�������b�Z�[�W
    cv_skip1_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14305'; -- �w�b�_�X�L�b�v�������b�Z�[�W
    cv_skip2_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14306'; -- ���׃X�L�b�v�������b�Z�[�W
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14307'; -- �x���������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    --
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target1_cnt := 0;
      gn_target2_cnt := 0;
      gn_normal1_cnt := 0;
      gn_normal2_cnt := 0;
      gn_skip1_cnt   := 0;
      gn_skip2_cnt   := 0;
      gn_warn_cnt    := 0;
      gn_error_cnt   := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ===============================
    -- �I������(A-4)
    -- ===============================
    --�w�b�_�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_target1_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target1_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���בΏی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_target2_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target2_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�w�b�_�폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_delete1_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal1_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���׍폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_delete2_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal2_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�w�b�_�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_skip1_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip1_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���׃X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_skip2_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip2_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
       which  => FND_FILE.OUTPUT
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
END XXCOS003A07C;
/
