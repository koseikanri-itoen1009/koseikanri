CREATE OR REPLACE PACKAGE BODY xxwsh_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwsh_common3_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  wf_whs_start            P          �ő�z���敪�Z�o�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/06/10   1.0   Oracle �쑺      �V�K�쐬
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
  no_data                   EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gn_status_normal CONSTANT NUMBER := 0;
  gn_status_error  CONSTANT NUMBER := 1;
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common3_pkg'; -- �p�b�P�[�W��
--
  gv_cnst_com_kbn     CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  -- ���b�Z�[�WID
  gv_cnst_msg_nodata  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10001'; -- �Ώۃf�[�^�Ȃ�
--
  -- �g�[�N��
  gv_tkn_table        CONSTANT VARCHAR2(10)  := 'TABLE';
  gv_tkn_key          CONSTANT VARCHAR2(10)  := 'KEY';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : get_outbound_info
   * Description      : �A�E�g�o�E���h�������擾�֐�
   ***********************************************************************************/
  PROCEDURE get_wsh_wf_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    or_wf_whs_rec       OUT NOCOPY wf_whs_rec,        -- �t�@�C�����
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_wsh_wf_info'; -- �v���O������
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
    cv_wf_noti        CONSTANT VARCHAR2(100) := 'XXCMN_WF_NOTIFICATION';  -- Workflow�ʒm��
    cv_wf_info        CONSTANT VARCHAR2(100) := 'XXCMN_WF_INFO';          -- Workflow���
    cv_prof_min_date  CONSTANT VARCHAR2(100) := 'XXCMN_MIN_DATE';
--
    -- *** ���[�J���ϐ� ***
    lr_wf_whs_rec   wf_whs_rec;   -- wf_whs_rec�֘A�f�[�^
    lv_table_name   VARCHAR2(100);
    lv_value        VARCHAR2(100);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      -- �ʒm�惆�[�U�[���擾
      SELECT  xlv.attribute1,     -- �Ώہi�p�����[�^�Ɠ����j
              xlv.attribute2,     -- ����i�p�����[�^�Ɠ����j
              xlv.attribute3,     -- ����P
              xlv.attribute4,     -- ����Q
              xlv.attribute5,     -- ����R
              xlv.attribute6,     -- ����S
              xlv.attribute7,     -- ����T
              xlv.attribute8,     -- ����U
              xlv.attribute9,     -- ����V
              xlv.attribute10,    -- ����W
              xlv.attribute11,    -- ����X
              xlv.attribute12     -- ����P�O
      INTO    lr_wf_whs_rec.wf_class,
              lr_wf_whs_rec.wf_notification,
              lr_wf_whs_rec.user_cd01,
              lr_wf_whs_rec.user_cd02,
              lr_wf_whs_rec.user_cd03,
              lr_wf_whs_rec.user_cd04,
              lr_wf_whs_rec.user_cd05,
              lr_wf_whs_rec.user_cd06,
              lr_wf_whs_rec.user_cd07,
              lr_wf_whs_rec.user_cd08,
              lr_wf_whs_rec.user_cd09,
              lr_wf_whs_rec.user_cd10
      FROM    xxcmn_lookup_values_v xlv
      WHERE  xlv.lookup_type  = cv_wf_noti          -- Workflow�ʒm��
      AND    xlv.attribute1   = iv_wf_class         -- �Ώ�
      AND    xlv.attribute2   = iv_wf_notification  -- ����
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ��ꍇ�́A�G���[
        lv_table_name := 'xxcmn_lookup_values_v';
        lv_value      :=  cv_wf_noti ||
                          ','         ||
                          iv_wf_class ||
                          ','         ||
                          iv_wf_notification;
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_nodata,
                                              gv_tkn_table,
                                              lv_table_name,
                                              gv_tkn_key,
                                              lv_value);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    BEGIN
      -- ���[�N�t���[�����擾
      SELECT  xlv.attribute4,     -- WF�v���Z�X
              xlv.attribute5,     -- WF�I�[�i�[
              xlv.attribute6,     -- �f�B���N�g��
              xlv.attribute7,     -- �t�@�C����
              xlv.attribute8      -- �\����
      INTO    lr_wf_whs_rec.wf_name,
              lr_wf_whs_rec.wf_owner,
              lr_wf_whs_rec.directory,
              lr_wf_whs_rec.file_name,
              lr_wf_whs_rec.file_display_name
      FROM    xxcmn_lookup_values_v xlv
      WHERE   xlv.lookup_type   = cv_wf_info          -- Workflow���
      AND     xlv.attribute1    = iv_wf_ope_div       -- �����敪
      AND     xlv.attribute2    = iv_wf_class         -- �Ώ�
      AND     xlv.attribute3    = iv_wf_notification  -- ����
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ��ꍇ�́A�G���[
        lv_table_name := 'xxcmn_lookup_values_v';
        lv_value      :=  cv_wf_info          ||
                          ','                 ||
                          iv_wf_ope_div       ||
                          ','                 ||
                          iv_wf_class         ||
                          ','                 ||
                          iv_wf_notification;
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_nodata,
                                              gv_tkn_table,
                                              lv_table_name,
                                              gv_tkn_key,
                                              lv_value);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    or_wf_whs_rec := lr_wf_whs_rec;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_wsh_wf_info;
--
  /**********************************************************************************
   * Procedure Name   : wf_start
   * Description      : ���[�N�t���[�N���֐�
   ***********************************************************************************/
  PROCEDURE wf_whs_start(
    ir_wf_whs_rec IN  wf_whs_rec,               -- ���[�N�t���[�֘A���
    iv_filename   IN  VARCHAR2,                 -- �t�@�C����
    ov_errbuf     OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wf_start'; -- �v���O������
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
    lv_itemkey      VARCHAR2(30);
    lr_wf_whs_rec   wf_whs_rec; -- WF�֘A�f�[�^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_wf_info_expt                  EXCEPTION;     -- ���[�N�t���[���ݒ�G���[
    wf_exec_expt                     EXCEPTION;     -- ���[�N�t���[���s�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --WF�^�C�v�ň�ӂƂȂ�WF�L�[���擾
    SELECT TO_CHAR(xxcmn_wf_key_s1.NEXTVAL)
    INTO   lv_itemkey
    FROM   DUAL;
--
    BEGIN
--
      --WF�v���Z�X���쐬
      WF_ENGINE.CREATEPROCESS(ir_wf_whs_rec.wf_name, lv_itemkey, ir_wf_whs_rec.wf_name);
      --WF�I�[�i�[��ݒ�
      WF_ENGINE.SETITEMOWNER(ir_wf_whs_rec.wf_name, lv_itemkey, ir_wf_whs_rec.wf_owner);
      --WF������ݒ�
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_NAME',
                                  ir_wf_whs_rec.directory|| ',' || iv_filename );
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD01',
                                  ir_wf_whs_rec.user_cd01);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD02',
                                  ir_wf_whs_rec.user_cd02);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD03',
                                  ir_wf_whs_rec.user_cd03);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD04',
                                  ir_wf_whs_rec.user_cd04);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD05',
                                  ir_wf_whs_rec.user_cd05);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD06',
                                  ir_wf_whs_rec.user_cd06);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD07',
                                  ir_wf_whs_rec.user_cd07);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD08',
                                  ir_wf_whs_rec.user_cd08);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD09',
                                  ir_wf_whs_rec.user_cd09);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD10',
                                  ir_wf_whs_rec.user_cd10);
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_DISP_NAME',
                                  ir_wf_whs_rec.file_display_name);
      -- 1.1�ǉ�
      WF_ENGINE.SETITEMATTRTEXT(ir_wf_whs_rec.wf_name,
                                  lv_itemkey,
                                  'WF_OWNER',
                                  ir_wf_whs_rec.wf_owner);
--
      --WF�v���Z�X���N��
      WF_ENGINE.STARTPROCESS(ir_wf_whs_rec.wf_name, lv_itemkey);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10117');
        RAISE wf_exec_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN no_wf_info_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
    WHEN wf_exec_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
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
  END wf_whs_start;
--
END xxwsh_common3_pkg;
/
