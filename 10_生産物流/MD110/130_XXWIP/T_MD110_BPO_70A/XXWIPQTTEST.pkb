CREATE OR REPLACE PACKAGE BODY XXWIPQTTEST
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXWIPQTTEST(body)
 * Description      : xxwip_common_pkg.make_qt_inspection�e�X�g�p�R���J�����g
 * MD.050           : -
 * MD.070           : -
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2007/12/03     1.0   H.Itou            �V�K�쐬
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
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXWIPQTTEST'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_division          IN  VARCHAR2, -- IN  1.�敪         �K�{�i1:���Y 2:���� 3:���b�g��� 4:�O���o���� 5:�r�������j
    iv_disposal_div      IN  VARCHAR2, -- IN  2.�����敪     �K�{�i1:�ǉ� 2:�X�V 3:�폜�j
    iv_lot_id            IN  VARCHAR2, -- IN  3.���b�gID     �K�{
    iv_item_id           IN  VARCHAR2, -- IN  4.�i��ID       �K�{
    iv_qt_object         IN  VARCHAR2, -- IN  5.�Ώې�       �敪:5�̂ݕK�{�i1:�r���i�� 2:���Y���P 3:���Y���Q 4:���Y���R�j
    iv_batch_id          IN  VARCHAR2, -- IN  6.���Y�o�b�`ID �敪:1�̂ݕK�{
    iv_batch_po_id       IN  VARCHAR2, -- IN  7.���הԍ�     �敪:2�̂ݕK�{
    iv_qty               IN  VARCHAR2, -- IN  8.����         �敪:2�̂ݕK�{
    iv_prod_dely_date    IN  VARCHAR2, -- IN  9.�[����       �敪:2�̂ݕK�{
    iv_vendor_line       IN  VARCHAR2, -- IN 10.�d����R�[�h �敪:2�̂ݕK�{
    iv_qt_inspect_req_no IN  VARCHAR2  -- IN 11.�����˗�No   �����敪:2�A3�̂ݕK�{
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
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lt_qt_inspect_req_no xxwip_qt_inspection.qt_inspect_req_no%TYPE;  -- �����˗�No
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);

    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
--###########################  �Œ蕔 END   #############################
--
    -- ==================================
    -- �i�������˗����쐬���s
    -- ==================================
    xxwip_common_pkg.make_qt_inspection(
      it_division          => iv_division
     ,iv_disposal_div      => iv_disposal_div
     ,it_lot_id            => TO_NUMBER(iv_lot_id)
     ,it_item_id           => TO_NUMBER(iv_item_id)
     ,iv_qt_object         => iv_qt_object
     ,it_batch_id          => TO_NUMBER(iv_batch_id)
     ,it_batch_po_id       => TO_NUMBER(iv_batch_po_id)
     ,it_qty               => TO_NUMBER(iv_qty)
     ,it_prod_dely_date    => TO_DATE(iv_prod_dely_date,'YYYYMMDD')
     ,it_vendor_line       => iv_vendor_line
     ,it_qt_inspect_req_no => TO_NUMBER(iv_qt_inspect_req_no)
     ,ot_qt_inspect_req_no => lt_qt_inspect_req_no
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
      );
--
    -- ===================================
    -- OUT�p�����[�^�o��
    -- ===================================
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�����˗�No :' || lt_qt_inspect_req_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ov_errbuf  :' || lv_errbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ov_retcode :' || lv_retcode);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ov_errmsg  :' || lv_errmsg);
--
--###########################  �Œ蕔 START   #####################################################
--
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
END XXWIPQTTEST;
/
