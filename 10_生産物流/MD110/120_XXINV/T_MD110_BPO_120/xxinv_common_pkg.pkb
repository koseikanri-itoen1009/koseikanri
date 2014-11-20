CREATE OR REPLACE PACKAGE BODY xxinv_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv_common_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_120_���ʊ֐��i�⑫�����j.xls
 * Version                : 1.1
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
 *  2008/10/10   1.1   Oracle �勴 �F�Y T_S_621�Ή�
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
-- mod start 1.1
--      iv_from_item_no   IN   ic_item_mst_b.item_no%TYPE   -- �U�֌��i�ڃR�[�h
--     ,iv_to_item_no     IN   ic_item_mst_b.item_no%TYPE   -- �U�֐�i�ڃR�[�h
      iv_to_item_no     IN   ic_item_mst_b.item_no%TYPE   -- �U�֐�i�ڃR�[�h
-- mod end 1.1
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
-- mod start 1.1
--    lv_for_head   CONSTANT   VARCHAR2(2) := 'ZZ';    -- �i�ڐU�֎��ʎq_������
    lv_kbn        CONSTANT   VARCHAR2(2) := '9';     -- �敪
    lv_hyphen     CONSTANT   VARCHAR2(1) := '-';     -- �i�ڐU�֎��ʎq_�ڑ�����
--    lv_for_footer CONSTANT   VARCHAR2(5) := '99999'; -- �i�ڐU�֎��ʎq_��������
-- mod end 1.1
--
    -- *** ���[�J���ϐ� ***
    lv_for_from_item_no   VARCHAR2(7);   -- �U�֌��i�ڃR�[�h
    lv_for_to_item_no     VARCHAR2(7);   -- �U�֐�i�ڃR�[�h
    lv_numbering_no       VARCHAR2(3);   -- �A��
    ln_numbering_no       NUMBER;        -- �A��
-- add start 1.1
    lv_formula_no         VARCHAR2(100);  -- �t�H�[�~����No(�����p)
    lv_sql                VARCHAR2(1000);
-- add end 1.1
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
-- del start 1.1
    -- �U�֌��i�ڃR�[�h��7���Őݒ�
--    lv_for_from_item_no := LPAD(iv_from_item_no, 7, '0');
-- del end 1.1
    -- �U�֐�i�ڃR�[�h��7���Őݒ�
    lv_for_to_item_no   := LPAD(iv_to_item_no, 7, '0');
--
-- add start 1.1
    lv_formula_no := lv_for_to_item_no || lv_hyphen || lv_kbn;
    -- �t�H�[�~����No���݃`�F�b�N
    lv_sql := 'SELECT MAX(TO_NUMBER(SUBSTR(ffmb.formula_no,11)))+1';
    lv_sql := lv_sql || ' FROM   fm_form_mst_b ffmb';
    lv_sql := lv_sql || ' WHERE  ffmb.formula_no LIKE ''' || lv_formula_no  || '%''';
--
    EXECUTE IMMEDIATE lv_sql INTO ln_numbering_no;
--
    -- �t�H�[�~����No�����݂��Ȃ��ꍇ
    IF (ln_numbering_no IS NULL) THEN
      -- �t�H�[�~����No�������l�Őݒ�
      lv_numbering_no := '001';
    -- �t�H�[�~����No��1000�̏ꍇ
    ELSIF (ln_numbering_no = 1000) THEN
      RETURN NULL;
    -- �t�H�[�~����No�����݂����ꍇ
    ELSE
      -- �t�H�[�~����No��3���Őݒ�
      lv_numbering_no := LPAD(ln_numbering_no, 3, '0');
    END IF;
-- add end 1.1
    -- �t�H�[�~����NO
-- mod start 1.1
--    RETURN (lv_for_head || lv_for_from_item_no || lv_hyphen ||
--             lv_for_to_item_no || lv_hyphen || lv_for_footer);
    RETURN (lv_for_to_item_no || lv_hyphen ||
             lv_kbn || lv_hyphen || lv_numbering_no);
-- mod end 1.1
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
  /**********************************************************************************
   * Function Name   : xxinv_get_recipe_no
   * Description     : ���V�sNO�̔Ԋ֐�
   ***********************************************************************************/
  FUNCTION xxinv_get_recipe_no
    (
      iv_to_item_no     IN   ic_item_mst_b.item_no%TYPE   -- �U�֐�i�ڃR�[�h
    )
    RETURN VARCHAR2             -- �t�H�[�~����No
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxinv_get_recipe_no'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_kbn              CONSTANT   VARCHAR2(2) := '9'; -- �敪
    lv_hyphen           CONSTANT   VARCHAR2(1) := '-'; -- �i�ڐU�֎��ʎq_�ڑ�����
--
    -- *** ���[�J���ϐ� ***
    lv_for_to_item_no     VARCHAR2(7);   -- �U�֐�i�ڃR�[�h
    lv_dummy_routing_no   VARCHAR2(5);   -- �_�~�[�H���R�[�h(�i�ڐU�֗p)
    lv_numbering_no       VARCHAR2(3);   -- �A��
    ln_numbering_no       NUMBER;        -- �A��
    lv_recipe_no          VARCHAR2(100); -- ���V�sNo(�����p)
    lv_sql                VARCHAR2(1000);
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- �U�֐�i�ڃR�[�h��7���Őݒ�
    lv_for_to_item_no   := LPAD(iv_to_item_no, 7, '0');
--
    lv_recipe_no := lv_for_to_item_no || lv_hyphen || lv_kbn;
    -- ���V�sNo���݃`�F�b�N
    lv_sql := 'SELECT MAX(TO_NUMBER(SUBSTR(greb.recipe_no,11)))+1';
    lv_sql := lv_sql || ' FROM   gmd_recipes_b greb';
    lv_sql := lv_sql || ' WHERE  greb.recipe_no LIKE ''' || lv_recipe_no  || '%''';
--
    EXECUTE IMMEDIATE lv_sql INTO ln_numbering_no;
--
    -- ���V�sNo�����݂��Ȃ��ꍇ
    IF (ln_numbering_no IS NULL) THEN
      -- �t�H�[�~����No�������l�Őݒ�
      lv_numbering_no := '001';
    -- ���V�sNo��1000�̏ꍇ
    ELSIF (ln_numbering_no = 1000) THEN
      RETURN NULL;
    -- ���V�sNo�����݂����ꍇ
    ELSE
      -- ���V�sNo��3���Őݒ�
      lv_numbering_no := LPAD(ln_numbering_no, 3, '0');
    END IF;
--
    -- ���V�sNO
    RETURN (lv_for_to_item_no || lv_hyphen ||
             lv_kbn || lv_hyphen || lv_numbering_no);
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
  END xxinv_get_recipe_no;
--
END xxinv_common_pkg;
/
