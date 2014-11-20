create or replace PACKAGE BODY xxpo_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name           : xxpo_common3_pkg(BODY)
 * Description            : ���ʊ֐�(�d�����э쐬�����Ǘ�Tbl�A�N�Z�X����)(BODY)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  check_result              F     V     �d�����я��`�F�b�N
 *  insert_result             F     V     �d�����я��o�^
 *  delete_result             P     -     �d�����я��폜
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2011/06/03   1.0   K.Kubo           �V�K�쐬
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo_common3_pkg'; -- �p�b�P�[�W��
--
  gn_zero          CONSTANT NUMBER := 0;
  gv_ret_succuess  CONSTANT VARCHAR2(1) := '1';
  gv_ret_err       CONSTANT VARCHAR2(1) := '0';

--
  /***********************************************************************************
   * Function Name    : check_result
   * Description      : �d�����я��̃`�F�b�N
   ***********************************************************************************/
  FUNCTION check_result(
    in_po_header_id       IN  NUMBER             -- (IN)�����w�b�_�h�c
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_result'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_result_count     NUMBER;
--
  BEGIN
--
    -- **************************************
    -- ***          �������̋L�q          ***
    -- **************************************
--
--  �d�����я��̃`�F�b�N
    SELECT COUNT(*)
    INTO   ln_result_count
    FROM   xxpo_stock_result_manegement xsrm
    WHERE  xsrm.po_header_id = in_po_header_id
    ;
--
    -- �d�����я�񂪂Ȃ��ꍇ�A����"0" ��Ԃ�
    IF ln_result_count = gn_zero THEN
      --�X�e�[�^�X�Z�b�g�i����F0�j
      RETURN gv_status_normal;
    ELSE
      --�X�e�[�^�X�Z�b�g�i�G���[�F2�j
      RETURN gv_status_error;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_result;
--
  /***********************************************************************************
   * Function Name    : insert_result
   * Description      : �d�����я��o�^
   ***********************************************************************************/
  FUNCTION insert_result(
    in_po_header_id       IN  NUMBER             -- (IN)�����w�b�_�h�c
   ,iv_po_header_number   IN  VARCHAR2           -- (IN)�����ԍ�
   ,in_created_by         IN  NUMBER             -- (IN)�쐬��
   ,id_creation_date      IN  DATE               -- (IN)�쐬��
   ,in_last_updated_by    IN  NUMBER             -- (IN)�ŏI�X�V��
   ,id_last_update_date   IN  DATE               -- (IN)�ŏI�X�V��
   ,in_last_update_login  IN  NUMBER             -- (IN)�ŏI�X�V���O�C��
  ) 
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_result'; -- �v���O������
--
  BEGIN
--
    -- **************************************
    -- ***          �������̋L�q          ***
    -- **************************************
--
    -- �d�����э쐬�����Ǘ�TBL�ւ�INSERT
    INSERT INTO xxpo_stock_result_manegement xsrm
    (
      xsrm.po_header_id              -- �����w�b�_�h�c
     ,xsrm.po_header_number          -- �����ԍ�
     ,xsrm.created_by                -- �쐬��
     ,xsrm.creation_date             -- �쐬��
     ,xsrm.last_updated_by           -- �ŏI�X�V��
     ,xsrm.last_update_date          -- �ŏI�X�V��
     ,xsrm.last_update_login         -- �ŏI�X�V���O�C��
    ) VALUES (
      in_po_header_id                -- �����w�b�_�h�c
     ,iv_po_header_number            -- �����ԍ�
     ,in_created_by                  -- �쐬��
     ,id_creation_date               -- �쐬��
     ,in_last_updated_by             -- �ŏI�X�V��
     ,id_last_update_date            -- �ŏI�X�V��
     ,in_last_update_login           -- �ŏI�X�V���O�C��
    )
    ;
--
    --�X�e�[�^�X�Z�b�g
    RETURN gv_ret_succuess;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gv_ret_err;
--
--#####################################  �Œ蕔 END   #############################################
--
  END insert_result;
--
  /***********************************************************************************
   * Procedure Name   : delete_result
   * Description      : �d�����я��폜
   ***********************************************************************************/
  PROCEDURE delete_result(
    in_po_header_id       IN  NUMBER             -- (IN)�����w�b�_ID
   ,ov_errbuf             OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'delete_result'; -- �v���O������
    cv_application     CONSTANT VARCHAR2(5)   := 'XXCMN';         -- �A�v���P�[�V������
    cv_table_name      CONSTANT VARCHAR2(30)  := '�d�����э�Ə����Ǘ��e�[�u��';
    cv_key             CONSTANT VARCHAR2(12)  := '�����w�b�_ID';
    cv_msg_xxcmn10001  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10001';
    cv_token_table     CONSTANT VARCHAR2(5)   := 'TABLE';
    cv_token_key       CONSTANT VARCHAR2(3)   := 'KEY';
--
    ln_count           NUMBER;          -- �d�����я��J�E���g�p
--
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************
    -- ***          �������̋L�q          ***
    -- **************************************
--
    -- �ϐ��̏�����
    ln_count := 0;
--
    -- �Ώۃf�[�^�����݂���ꍇ�́A�폜�����{
    -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�́A�G���[�ŕԂ�
    SELECT COUNT(1)
    INTO   ln_count
    FROM   xxpo_stock_result_manegement xsrm
    WHERE  xsrm.po_header_id = in_po_header_id;
--
    IF (ln_count > 0) THEN
      DELETE FROM xxpo_stock_result_manegement xsrm
      WHERE  xsrm.po_header_id = in_po_header_id
      ;
--
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                                       cv_application
                                      ,cv_msg_xxcmn10001
                                      ,cv_token_table
                                      ,cv_table_name
                                      ,cv_token_key
                                      ,cv_key);
--
      lv_retcode  := gv_status_error ;
--
      RAISE NO_DATA_FOUND;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--###########################  �Œ蕔 START   #####################################################
--
    -- --*** �l�擾�G���[��O ***
    WHEN NO_DATA_FOUND THEN
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_retcode := gv_status_error;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000);
      ov_errmsg  := SQLERRM;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_retcode :=  gv_status_error ;
      ov_errbuf  :=  SQLCODE ;
      ov_errmsg  :=  SQLERRM ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###########################  �Œ蕔 END   #######################################################
--
  END delete_result;
--
END xxpo_common3_pkg;
