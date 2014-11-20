CREATE OR REPLACE PACKAGE BODY xxinv_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv_common_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_120_���ʊ֐��i�⑫�����j.xls
 * Version                : 1.0
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  xxinv_get_formula_no   F   VAR   �t�H�[�~����NO�̔Ԋ֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/02/14   1.0   marushita        �V�K�쐬
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
  resource_busy_expt           EXCEPTION;     -- �f�b�h���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common_pkg'; -- �p�b�P�[�W��
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- ����
  gn_ret_error     CONSTANT NUMBER := 1; -- �G���[
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
   * Function Name   : xxinv_get_formula_no
   * Description     : �t�H�[�~����NO�̔Ԋ֐�
   ***********************************************************************************/
  FUNCTION xxinv_get_formula_no
    (
      iv_from_item_no   IN   ic_item_mst_b.item_no%TYPE   -- �U�֌��i�ڃR�[�h
     ,iv_to_item_no     IN   ic_item_mst_b.item_no%TYPE   -- �U�֐�i�ڃR�[�h
    )
    RETURN VARCHAR2             -- �t�H�[�~����No
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxinv_get_formula_no'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_for_head   CONSTANT   VARCHAR2(2) := 'ZZ';    -- �i�ڐU�֎��ʎq_������
    lv_hyphen     CONSTANT   VARCHAR2(1) := '-';     -- �i�ڐU�֎��ʎq_�ڑ�����
    lv_for_footer CONSTANT   VARCHAR2(5) := '99999'; -- �i�ڐU�֎��ʎq_��������
    
--
    -- *** ���[�J���ϐ� ***
    lv_for_from_item_no   VARCHAR2(7);   -- �U�֌��i�ڃR�[�h
    lv_for_to_item_no     VARCHAR2(7);   -- �U�֐�i�ڃR�[�h
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- �U�֌��i�ڃR�[�h��7���Őݒ�
    lv_for_from_item_no := LPAD(iv_from_item_no, 7, '0');
    -- �U�֐�i�ڃR�[�h��7���Őݒ�
    lv_for_to_item_no   := LPAD(iv_to_item_no, 7, '0');
--
    -- �t�H�[�~����NO
    RETURN (lv_for_head || lv_for_from_item_no || lv_hyphen ||
             lv_for_to_item_no || lv_hyphen || lv_for_footer);
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
        RETURN NULL;
--
--###################################  �Œ蕔 END   #########################################
--
  END xxinv_get_formula_no;
--
END xxinv_common_pkg;
/
