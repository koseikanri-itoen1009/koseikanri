CREATE OR REPLACE PACKAGE BODY xxwsh420002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh420002c(body)
 * Description      : �g���b�v/�X�g�b�v�̃C���^�t�F�[�X(�W��)�R�[���R���J�����g
 * MD.050           : �g���b�v/�X�g�b�v�̃C���^�t�F�[�X(�W��)�R�[�� T_MD050_BPO_420
 * MD.070           : �g���b�v/�X�g�b�v�̃C���^�t�F�[�X(�W��)�R�[�� T_MD070_BPO_42B
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/09/09    1.0   Y.Suzuki         �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_mst_normal    CONSTANT VARCHAR2(10) := '����I��';
  gv_mst_warn      CONSTANT VARCHAR2(10) := '�x���I��';
  gv_mst_error     CONSTANT VARCHAR2(10) := '�ُ�I��';
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
  -- ���b�Z�[�W�p�萔
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxwsh420002c';                           -- �p�b�P�[�W��
  gv_app_name       CONSTANT VARCHAR2(5)   := 'XXCMN';                                  -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10135 CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- �v���̔��s���s�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,                -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- �v���O������
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
--
    -- *** ���[�J���萔 ***
    cv_conc_p_c   CONSTANT VARCHAR2(100) := 'COMPLETE';
    cv_conc_s_w   CONSTANT VARCHAR2(100) := 'WARNING';
    cv_conc_s_e   CONSTANT VARCHAR2(100) := 'ERROR';
    cv_param_all  CONSTANT VARCHAR2(100) := 'ALL';
    cv_param_0    CONSTANT VARCHAR2(100) := '0';
    cv_param_1    CONSTANT VARCHAR2(100) := '1';
--
    -- *** ���[�J���ϐ� ***
    lv_phase      VARCHAR2(100);
    lv_status     VARCHAR2(100);
    lv_dev_phase  VARCHAR2(100);
    lv_dev_status VARCHAR2(100);
--
    i             INTEGER := 0;
    TYPE reqid_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    reqid_rec reqid_tab;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR get_org_cur IS
      SELECT DISTINCT TO_CHAR(wnd.organization_id) org_id
      FROM   wsh_new_deliveries wnd
            ,wsh_delivery_legs  wdl
            ,wsh_trip_stops     wts
      WHERE  wnd.delivery_id     = wdl.delivery_id
      AND    wdl.pick_up_stop_id = wts.stop_id
      AND    wts.pending_interface_flag = 'Y';
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FND_FILE.PUT_LINE (FND_FILE.LOG,'START');
--
    -- �u�g���b�v/�X�g�b�v�̃C���^�t�F�[�X�v���s
    <<call_conc>>
    FOR get_org_rec IN get_org_cur LOOP
      i := i + 1;
      reqid_rec(i) := FND_REQUEST.SUBMIT_REQUEST(
                        application       => 'WSH'                -- �A�v���P�[�V�����Z�k��
                       ,program           => 'WSHINTERFACES'      -- �v���O������
                       ,argument1         => cv_param_all         -- �C���^�t�F�[�X�E���[�h
                       ,argument2         => NULL                 -- �C���^�t�F�[�X����Ă���g���b�v/�X�g�b�v
                       ,argument3         => NULL                 -- �C���^�t�F�[�X���ꂽ����
                       ,argument4         => cv_param_0           -- �v���̃��O�E���x��
                       ,argument5         => NULL                 -- �o�b�`ID
                       ,argument6         => NULL                 -- �g���b�v�E�^�C�v
                       ,argument7         => get_org_rec.org_id   -- �g�D
                       ,argument8         => cv_param_1           -- �v����
                       ,argument9         => cv_param_1           -- �o�b�`����̃X�g�b�v
                        );
      -- �G���[�̏ꍇ
      IF (reqid_rec(i) = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application   => gv_app_name
                      ,iv_name          => gv_msg_xxcmn10135);
        RAISE global_api_expt;
      ELSE
        COMMIT;
      END IF;
--
    END LOOP call_conc;
--
    FND_FILE.PUT_LINE (FND_FILE.LOG,'CONC EXEC END');
--
    -- �R���J�����g�X�e�[�^�X�̃`�F�b�N
    <<chk_status>>
    FOR j IN 1 .. i LOOP
      IF (FND_CONCURRENT.WAIT_FOR_REQUEST(
            request_id => reqid_rec(j)
           ,interval   => 10
           ,max_wait   => 0
           ,phase      => lv_phase
           ,status     => lv_status
           ,dev_phase  => lv_dev_phase
           ,dev_status => lv_dev_status
           ,message    => lv_errbuf
           ))
      THEN
        -- �X�e�[�^�X���f
        -- �t�F�[�Y:����
        IF (lv_dev_phase = cv_conc_p_c) THEN
          -- �X�e�[�^�X:�ُ�
          IF (lv_dev_status = cv_conc_s_e) THEN
            ov_retcode := gv_status_error;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_error);
          -- �X�e�[�^�X:�x��
          ELSIF (lv_dev_status = cv_conc_s_w) THEN
            IF (ov_retcode < 1) THEN
              ov_retcode := gv_status_warn;
            END IF;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_warn);
          -- �X�e�[�^�X:����
          ELSE
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_normal);
          END IF;
        END IF;
      ELSE
        ov_retcode := gv_status_error;
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j))||gv_msg_part||gv_mst_error);
      END IF;
--
    END LOOP chk_status;
--
    FND_FILE.PUT_LINE (FND_FILE.LOG,'END');
--
  EXCEPTION
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
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    retcode             OUT    VARCHAR2)                -- ���^�[���E�R�[�h             --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      errbuf  := lv_errbuf;
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
END xxwsh420002c;
/
