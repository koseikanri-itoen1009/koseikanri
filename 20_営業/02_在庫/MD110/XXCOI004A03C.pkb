CREATE OR REPLACE PACKAGE BODY XXCOI004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcoi004a03c(body)
 * Description      : �����X���C�h
 * MD.050           : �����X���C�h MD050_COI_004_A03
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������          (A-1)
 *  upd_vd_column_mst      VD�R�����}�X�^�X�V(A-4)
 *  submain                ���C�������v���V�[�W��(A-2,A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   SCS H.Wada       �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  lock_expt          EXCEPTION;     -- ���b�N�擾�G���[
--
  -- �v���O�}
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI004A03C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���b�Z�[�W
  -- ===============================
  -- �A�v���P�[�V�����Z�k��
  gv_msg_kbn_coi   CONSTANT VARCHAR2(5)  := 'XXCOI';
  gv_msg_kbn_ccp   CONSTANT VARCHAR2(5)  := 'XXCCP';
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_ccp_00    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
  gv_msg_ccp_01    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
  gv_msg_ccp_02    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
  gv_msg_ccp_04    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';   -- ����I�����b�Z�[�W
  gv_msg_ccp_06    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';   -- �G���[�I���S���[���o�b�N���b�Z�[�W
  gv_msg_ccp_08    CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';   -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
--
  gv_msg_coi_08    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- �Ώۃf�[�^�������b�Z�[�W
  gv_msg_coi_24    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10024';   -- ���b�N�G���[���b�Z�[�W
--
  -- �g�[�N��
  gv_tkn_count     CONSTANT VARCHAR2(5)  := 'COUNT';
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vd_column_mst
   * Description      : VD�R�����}�X�^�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_vd_column_mst(
    it_rowid     IN   ROWID       -- 1.ROWID
   ,ov_errbuf    OUT  VARCHAR2    -- 2.�G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode   OUT  VARCHAR2    -- 3.���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg    OUT  VARCHAR2)   -- 4.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vd_column_mst'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �X�V����
    UPDATE xxcoi_mst_vd_column                  xvcm
    SET    xvcm.last_month_item_id            = xvcm.item_id              -- 1.�O�����i��ID
          ,xvcm.last_month_inventory_quantity = xvcm.inventory_quantity   -- 2.�O������݌ɐ�
          ,xvcm.last_month_price              = xvcm.price                -- 3.�O�����P��
          ,xvcm.last_month_hot_cold           = xvcm.hot_cold             -- 4.�O����H/C
          ,xvcm.last_update_date              = gd_last_update_date       -- 5.�ŏI�X�V��
          ,xvcm.last_updated_by               = gn_last_updated_by        -- 6.�ŏI�X�V��
          ,xvcm.last_update_login             = gn_last_update_login      -- 7.�ŏI�X�V���[�U
          ,xvcm.request_id                    = gn_request_id             -- 8.�v��ID
          ,xvcm.program_application_id        = gn_program_application_id -- 9.�v���O�����A�v���P�[�V����ID
          ,xvcm.program_id                    = gn_program_id             -- 10.�v���O����ID
          ,xvcm.program_update_date           = gd_program_update_date    -- 11.�v���O�����X�V��
    WHERE  xvcm.rowid                         = it_rowid;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_vd_column_mst;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf    OUT  VARCHAR2    -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode   OUT  VARCHAR2    -- 2.���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg    OUT  VARCHAR2)   -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_message VARCHAR2(5000);  -- �o�̓��b�Z�[�W
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���̓p�����[�^�������b�Z�[�W
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_kbn_ccp
                   ,iv_name         => gv_msg_ccp_08
                  );
    -- �t�@�C���ɏo��
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_message
    );
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf    OUT  VARCHAR2    -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode   OUT  VARCHAR2    -- 2.���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg    OUT  VARCHAR2)   -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- VD�R�������J�[�\��
    CURSOR vd_column_info_cur
    IS
      SELECT xvcm.rowid         AS xvcm_rowid
      FROM   xxcoi_mst_vd_column   xvcm   -- 1.VD�R�����}�X�^
            ,hz_cust_accounts      hca    -- 2.�ڋq�A�J�E���g
            ,hz_parties            hp     -- 3.�p�[�e�B�}�X�^
      WHERE  xvcm.customer_id    = hca.cust_account_id
      AND    hca.party_id        = hp.party_id
      AND    hp.duns_number_c   IN (30, 40, 50, 80)
      FOR UPDATE NOWAIT;
--
    -- VD�R������񃌃R�[�h�^
    vd_column_info_rec vd_column_info_cur%ROWTYPE;
--
    -- ��O
    no_date_expt       EXCEPTION;     -- �Ώۃf�[�^�����G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      ov_errbuf  => lv_errbuf         -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode        -- 2.���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg);       -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = gv_status_normal) THEN
      null;
    ELSE
      RAISE global_api_expt;
    END IF;
--
    OPEN vd_column_info_cur;
--
    -- VD�R�������擾���[�v
    <<get_column_loop>>
    LOOP
      -- ===============================
      -- VD�R�������擾(A-2)
      -- ���b�N�擾(A-3)
      -- ===============================
      FETCH vd_column_info_cur INTO vd_column_info_rec;
      EXIT WHEN vd_column_info_cur%NOTFOUND;
--
      -- �Ώی����̃J�E���g�A�b�v
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- VD�R�����}�X�^�X�V(A-4)
      -- ===============================
      upd_vd_column_mst(
        it_rowid   => vd_column_info_rec.xvcm_rowid   -- 1.ROWID
       ,ov_errbuf  => lv_errbuf                       -- 2.�G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode                      -- 3.���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg);                     -- 4.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[�����̃J�E���g�A�b�v
        gn_error_cnt := gn_error_cnt + 1;
        -- ���������ʗ�O�n���h���֑J��
        RAISE global_process_expt;
      ELSIF (lv_retcode = gv_status_normal) THEN
        -- ���������̃J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    END LOOP get_column_loop;
--
    CLOSE vd_column_info_cur;
    -- �擾������0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �Ώۃf�[�^�����G���[�֑J��
      RAISE no_date_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�����G���[ ***
    WHEN no_date_expt THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_08);
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
    --*** ���b�N�擾�G���[ ***
    WHEN lock_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ
      IF (vd_column_info_cur%ISOPEN) THEN
        CLOSE vd_column_info_cur;
      END IF;
      -- �G���[�����̃J�E���g�A�b�v
      gn_error_cnt := gn_error_cnt + 1;
      -- ���b�N�G���[���b�Z�[�W
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_kbn_coi
                   ,iv_name         => gv_msg_coi_24
                  );
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5)
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf  OUT  VARCHAR2   -- 1.�G���[���b�Z�[�W #�Œ�#
   ,retcode OUT  VARCHAR2   -- 2.�G���[�R�[�h     #�Œ�#
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(16);    -- ���[�U�[�E���b�Z�[�W�E�R�[�h
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
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf  => lv_errbuf   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode  -- 2.���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg   -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    -- �������ʂ��G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      -- �Ώی����̏�����
      gn_target_cnt := 0;
      -- ���������̏�����
      gn_normal_cnt := 0;
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => gv_msg_ccp_00
                    ,iv_token_name1  => gv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => gv_msg_ccp_01
                    ,iv_token_name1  => gv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => gv_msg_ccp_02
                    ,iv_token_name1  => gv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --��s�o��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    --�I�����b�Z�[�W
    IF (lv_retcode = gv_status_normal) THEN
      lv_message_code := gv_msg_ccp_04;
    ELSIF(lv_retcode = gv_status_error) THEN
      lv_message_code := gv_msg_ccp_06;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOI004A03C;
/
