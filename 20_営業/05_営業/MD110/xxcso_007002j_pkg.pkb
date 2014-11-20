CREATE OR REPLACE PACKAGE BODY xxcso_007002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_007002j_pkg(body)
 * Description      : ���k��������͉�ʂōs��ꂽ���F�˗��ɑ΂��A�����㒷�����F�^�۔F��
 *                    �s���܂��B�����㒷�̏��F������ꂽ�ꍇ�A���k������̒ʒm�Ώێ҂֏�
 *                    �k������̒ʒm���s���܂��B�����㒷�����F���s�����ꍇ�́A���F�˗���
 *                    �s�������[�U�[�֏��F���ʂ𑗕t���܂��B�����㒷���۔F���s�����ꍇ�́A
 *                    ���F�˗����s�������[�U�[�֔۔F���ʂ𑗕t���܂��B
 * MD.050           : MD050_CSO_007_A02_���k������ʒm
 *
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_appr_rjct_comment   ���F�˗��ʒm(W-1)
 *  upd_line_notified_flag  ���k�����񗚗𖾍׍X�V(W-2)
 *  get_notify_user         �ʒm�Ҏ擾(W-4)
 *  upd_user_notified_flag  ���k������ʒm�҃��X�g�X�V(W-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-26    1.0   Kazuo.Satomura   �V�K�쐬
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
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
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER; -- �Ώی���
  gn_normal_cnt    NUMBER; -- ���팏��
  gn_error_cnt     NUMBER; -- �G���[����
  gn_warn_cnt      NUMBER; -- �X�L�b�v����
  --
  --################################  �Œ蕔 END   ##################################
  --
  --##########################  �Œ苤�ʗ�O�錾�� START  ###########################
  --
  --*** ���������ʗ�O ***
  global_process_expt EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --
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
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'xxcso_007002j_pkg'; -- �p�b�P�[�W��
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �c�Ɨp�A�v���P�[�V�����Z�k��
  cv_com_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';             -- ���ʗp�A�v���P�[�V�����Z�k��
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00161';  -- �۔F�R�����g���ݒ�G���[
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00074';  -- �����G���[1
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00337';  -- �f�[�^�X�V�G���[
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00236';  -- �����G���[���b�Z�[�W
  --
  -- �g�[�N���R�[�h
  cv_tkn_table         CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key           CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_column        CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_emsize        CONSTANT VARCHAR2(20) := 'EMSIZE';
  cv_tkn_onebyte       CONSTANT VARCHAR2(20) := 'ONEBYTE';
  cv_tkn_name          CONSTANT VARCHAR2(20) := 'NAME';
  cv_tkn_err_msg       CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_action        CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_error_message CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_errmsg        CONSTANT VARCHAR2(20) := 'ERRMSG';
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  /**********************************************************************************
   * Procedure Name   : chk_appr_rjct_comment
   * Description      : ���F�˗��ʒm(W-1)
   ***********************************************************************************/
  PROCEDURE chk_appr_rjct_comment(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_appr_rjct_comment'; -- �v���V�[�W����
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_aname_appr_rjct_comment  CONSTANT VARCHAR2(100) := 'XXCSO_APPR_RJCT_COMMENT';
    cv_aname_notify_header_id   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';
    cv_anama_result             CONSTANT VARCHAR2(100) := 'RESULT';
    cv_rjct_internal_name       CONSTANT VARCHAR2(100) := 'XXCSO007002L01C02'; -- �۔F����LOOKUP_CODE
    cn_appr_rjct_comment_length CONSTANT NUMBER        := 508; -- ���F�^�۔F�R�����g�ő���̓o�C�g�� + ���s�R�[�h(2) * 4�o�C�g
    --
    -- �g�[�N���p�萔
    cv_tkn_value_table       CONSTANT VARCHAR2(100) := '���F�^�۔F�X�e�[�^�X';
    cv_tkn_value_key         CONSTANT VARCHAR2(100) := 'ITEM_TYPE,ITEM_KEY,PROCESS_ACTIVITY';
    cv_tkn_value_comment     CONSTANT VARCHAR2(100) := '���F�^�۔F�R�����g';
    cv_tkn_value_emsize      CONSTANT VARCHAR2(100) := '500';
    cv_tkn_value_onebyte     CONSTANT VARCHAR2(100) := '250';
    cv_tkn_value_chk_comment CONSTANT VARCHAR2(100) := '���F�˗��ʒm';
    --
    -- *** ���[�J���ϐ� ***
    ln_nid                  NUMBER;         -- �ʒm�h�c
    lt_activity_result_code VARCHAR2(5000); -- ���F�^�۔F�X�e�[�^�X
    lv_appr_rjct_comment    VARCHAR2(5000); -- ���F�^�۔F�R�����g
    ln_notify_header_id     NUMBER;         -- ���k�����񗚗��w�b�_�h�c
    --
  BEGIN
    --
    -- ======================
    -- �ʒm�h�c�擾
    -- ======================
    ln_nid := wf_engine.context_nid;
    --
    -- ======================
    -- ���F�^�۔F�擾
    -- ======================
    lt_activity_result_code := wf_notification.getattrtext(
                                  nid   => ln_nid
                                 ,aname => cv_anama_result
                               );
    --
    -- ======================
    -- ���F�^�۔F�R�����g�擾
    -- ======================
    lv_appr_rjct_comment := wf_notification.getattrtext(
                               nid   => ln_nid
                              ,aname => cv_aname_appr_rjct_comment
                            );
    --
    IF (lv_appr_rjct_comment IS NULL) THEN
      -- ���F�^�۔F�R�����g�������͂̏ꍇ
      IF (lt_activity_result_code = cv_rjct_internal_name) THEN
        -- �۔F���̓R�����g�K�{
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_01);
        app_exception.raise_exception;
        --
      END IF;
      --
    ELSE
      -- ���F�^�۔F�R�����g�����͂���Ă���ꍇ
      IF (LENGTHB(lv_appr_rjct_comment) > cn_appr_rjct_comment_length) THEN
        -- 508�o�C�g�𒴂���ꍇ�̓G���[
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_02);
        fnd_message.set_token(cv_tkn_column, cv_tkn_value_comment);
        fnd_message.set_token(cv_tkn_emsize, cv_tkn_value_onebyte);
        fnd_message.set_token(cv_tkn_onebyte, cv_tkn_value_emsize);
        app_exception.raise_exception;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      RAISE;
      --
  END chk_appr_rjct_comment;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_line_notified_flag
   * Description      : ���k�����񗚗𖾍׍X�V(W-2)
   ***********************************************************************************/
  PROCEDURE upd_line_notified_flag(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_line_notified_flag'; -- �v���V�[�W����
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_aname_notify_header_id CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_sales_line    CONSTANT VARCHAR2(100) := '���k�����񗚗𖾍׃e�[�u��';
    cv_tkn_value_upd_line_flag CONSTANT VARCHAR2(100) := '���k�����񗚗𖾍׍X�V';
    --
    -- *** ���[�J���ϐ� ***
    ln_notify_header_id NUMBER; -- ���k�����񗚗��w�b�_�h�c
    --
  BEGIN
    --
    -- ==============================
    -- ���k�����񗚗��w�b�_�h�c�擾
    -- ==============================
    ln_notify_header_id := wf_engine.getitemattrnumber(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_notify_header_id
                           );
    --
    -- ========================
    -- �ʒm�t���O�X�V
    -- ========================
    BEGIN
      UPDATE xxcso_sales_lines_hist xlh -- ���k�����񗚗𖾍׃e�[�u��
      SET    xlh.notified_flag     = cv_flag_yes          -- �ʒm�t���O
            ,xlh.last_updated_by   = cn_last_updated_by   -- �ŏI�X�V��
            ,xlh.last_update_date  = cd_last_update_date  -- �ŏI�X�V��
            ,xlh.last_update_login = cn_last_update_login -- �ŏI�X�V���O�C��
      WHERE  xlh.header_history_id = ln_notify_header_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_03);
        fnd_message.set_token(cv_tkn_action, cv_tkn_value_sales_line);
        fnd_message.set_token(cv_tkn_error_message, SQLERRM);
        app_exception.raise_exception;
        --
    END;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      RAISE;
      --
  END upd_line_notified_flag;
  --
  --
  /**********************************************************************************
   * Procedure Name   : create_process
   * Description      : ���F�m�F�ʒm�v���Z�X�N��(W-4)
   ***********************************************************************************/
  -- ���F�m�F�ʒm�v���Z�X�N��
  PROCEDURE create_process(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'create_process'; -- �v���V�[�W����
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_aname_notify_header_id CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';       -- ���k�����񗚗��w�b�_�h�c
    cv_aname_req_appr_user_nm CONSTANT VARCHAR2(100) := 'XXCSO_REQUEST_APPR_USER_NAME'; -- ���F�˗���
    cv_anama_notify_user_nm   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_USER_NAME';       -- �ʒm��
    cv_aname_notify_subject   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_SUBJECT';         -- ����
    cv_aname_notify_confirm   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_CONFIRM';         -- �ʒm�m�F��ʂt�q�k
    cv_anama_notify_comment   CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_COMMENT';         -- �R�����g
    cv_amane_user_name        CONSTANT VARCHAR2(100) := 'XXCSO_NEXT_NOTIFY_USER';
    cv_process_name           CONSTANT VARCHAR2(100) := 'XXCSO007002P02';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_sales_notifies CONSTANT VARCHAR2(100) := '���k������ʒm�҃��X�g�e�[�u��';
    cv_tkn_value_create_process CONSTANT VARCHAR2(100) := '���F�m�F�ʒm�v���Z�X�N��';
    --
    -- *** ���[�J���ϐ� ***
    ln_notify_header_id NUMBER;         -- ���k������w�b�_�h�c
    lv_req_appr_user_nm VARCHAR2(100);  -- ���F�˗���
    lv_notify_subject   VARCHAR2(4000); -- ����
    lv_notify_confirm   VARCHAR2(4000); -- �ʒm�m�F��ʂt�q�k
    lv_notify_comment   VARCHAR2(4000); -- �R�����g
    lv_itemkey          VARCHAR2(100);  -- �A�C�e���L�[
    ln_loop_count       NUMBER := 0;    -- ���[�v����
    --
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʒm�Ҏ擾�J�[�\��
    CURSOR get_user_name_cur
    IS
      SELECT xsn.user_name -- ���[�U�[��
      FROM   xxcso_sales_notifies xsn -- ���k������ʒm�҃��X�g�e�[�u��
      WHERE  xsn.header_history_id = ln_notify_header_id
      AND    xsn.notified_flag     = cv_flag_no
      ;
    --
  BEGIN
    --
    -- ==========================
    -- ���k������w�b�_�h�c�擾
    -- ==========================
    ln_notify_header_id := wf_engine.getitemattrnumber(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_notify_header_id
                           );
    --
    -- ==========================
    -- ���F�˗��Ҏ擾
    -- ==========================
    lv_req_appr_user_nm := wf_engine.getitemattrtext(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_req_appr_user_nm
                           );
    --
    -- ==========================
    -- �����擾
    -- ==========================
    lv_notify_subject := wf_engine.getitemattrtext(
                             itemtype => itemtype
                            ,itemkey  => itemkey
                            ,aname    => cv_aname_notify_subject
                          );
    --
    -- ==========================
    -- �ʒm�m�F��ʂt�q�k�擾
    -- ==========================
    lv_notify_confirm := wf_engine.getitemattrtext(
                            itemtype => itemtype
                           ,itemkey  => itemkey
                           ,aname    => cv_aname_notify_confirm
                         );
    --
    -- ==========================
    -- �R�����g�擾
    -- ==========================
    lv_notify_comment := wf_engine.getitemattrtext(
                            itemtype => itemtype
                           ,itemkey  => itemkey
                           ,aname    => cv_anama_notify_comment
                         );
    --
    -- ========================
    -- ���ʒm�Ҏ擾
    -- ========================
    FOR lt_sales_notifies_rec IN get_user_name_cur LOOP
      ln_loop_count := ln_loop_count + 1;
      --
      IF (lt_sales_notifies_rec.user_name IS NOT NULL) THEN
        -- ==========================
        -- ���F�m�F�ʒm�v���Z�X���N��
        -- ==========================
        lv_itemkey  := 'XXCSO007' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || ln_loop_count;
        --
        wf_engine.createprocess(
           itemtype   => itemtype
          ,itemkey    => lv_itemkey
          ,process    => cv_process_name
          ,owner_role => fnd_global.user_name
        );
        --
        -- ���k�����񗚗��w�b�_�h�c
        wf_engine.setitemattrnumber(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_notify_header_id
         ,avalue     => ln_notify_header_id
        );
        --
        -- ���F�˗���
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_req_appr_user_nm
         ,avalue     => lv_req_appr_user_nm
        );
        --
        -- �ʒm��
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_anama_notify_user_nm
         ,avalue     => lt_sales_notifies_rec.user_name
        );
        --
        -- ����
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_notify_subject
         ,avalue     => lv_notify_subject
        );
        --
        -- �ʒm�m�F��ʂt�q�k
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_aname_notify_confirm
         ,avalue     => lv_notify_confirm
        );
        --
        -- �R�����g
        wf_engine.setitemattrtext(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
         ,aname      => cv_anama_notify_comment
         ,avalue     => lv_notify_comment
        );
        --
        wf_engine.startprocess(
          itemtype   => itemtype
         ,itemkey    => lv_itemkey
        );
      END IF;
      --
    END LOOP;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_04);
      fnd_message.set_token(cv_tkn_action, cv_tkn_value_create_process);
      fnd_message.set_token(cv_tkn_errmsg, SQLERRM);
      app_exception.raise_exception;
      --
  END create_process;
  --
  --
  /**********************************************************************************
   * Procedure Name   : upd_user_notified_flag
   * Description      : ���k������ʒm�҃��X�g�X�V(W-6)
   ***********************************************************************************/
  PROCEDURE upd_user_notified_flag(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  )
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_user_notified_flag'; -- �v���V�[�W����
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_aname_notify_header_id CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_HEADER_ID';
    cv_amane_user_name        CONSTANT VARCHAR2(100) := 'XXCSO_NOTIFY_USER_NAME';
    --
    -- �g�[�N���p�萔
    cv_tkn_value_sales_notifies CONSTANT VARCHAR2(100) := '���k������ʒm�҃��X�g�e�[�u��';
    cv_tkn_value_upd_user_flag  CONSTANT VARCHAR2(100) := '���k������ʒm�҃��X�g�X�V';
    --
    -- *** ���[�J���ϐ� ***
    ln_notify_header_id NUMBER;        -- ���k�����񗚗��w�b�_�h�c
    lt_user_name        VARCHAR2(100); -- ���[�U�[��
    --
  BEGIN
    --
    -- ==========================
    -- ���k������w�b�_�h�c�擾
    -- ==========================
    ln_notify_header_id := wf_engine.getitemattrnumber(
                              itemtype => itemtype
                             ,itemkey  => itemkey
                             ,aname    => cv_aname_notify_header_id
                           );
    --
    -- ========================
    -- �ʒm�҃��[�U�[���擾
    -- ========================
    lt_user_name := wf_engine.getitemattrtext(
                       itemtype => itemtype
                      ,itemkey  => itemkey
                      ,aname    => cv_amane_user_name
                    );
    --
    -- ========================
    -- �ʒm�t���O�X�V
    -- ========================
    BEGIN
      UPDATE xxcso_sales_notifies xsn -- ���k������ʒm�҃��X�g�e�[�u��
      SET    xsn.notified_flag     = cv_flag_yes          -- �ʒm�t���O
            ,xsn.last_updated_by   = cn_last_updated_by   -- �ŏI�X�V��
            ,xsn.last_update_date  = cd_last_update_date  -- �ŏI�X�V��
            ,xsn.last_update_login = cn_last_update_login -- �ŏI�X�V���O�C��
      WHERE  xsn.header_history_id = ln_notify_header_id
      AND    xsn.user_name         = lt_user_name
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_message.set_name(cv_sales_appl_short_name, cv_tkn_number_03);
        fnd_message.set_token(cv_tkn_action, cv_tkn_value_sales_notifies);
        fnd_message.set_token(cv_tkn_error_message, SQLERRM);
        app_exception.raise_exception;
        --
    END;
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.context(
         pkg_name  => cv_pkg_name
        ,proc_name => cv_prg_name
        ,arg1      => itemtype
        ,arg2      => itemkey
        ,arg3      => TO_CHAR(actid)
        ,arg4      => funcmode
      );
      --
      RAISE;
      --
  END upd_user_notified_flag;
  --
  --
END xxcso_007002j_pkg;
/
