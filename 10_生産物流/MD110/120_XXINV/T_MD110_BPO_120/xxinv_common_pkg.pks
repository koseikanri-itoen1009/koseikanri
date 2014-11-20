CREATE OR REPLACE PACKAGE xxinv_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv_common_pkg(SPEC)
 * Description            : ���ʊ֐�(SPEC)
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
  -- ===============================
  -- �O���[�o���^
  -- ===============================
  TYPE outbound_rec IS RECORD(
--    wf_ope_div              xxcmn_outbound.wf_ope_div%TYPE,
    wf_class                xxcmn_outbound.wf_class%TYPE,
    wf_notification         xxcmn_outbound.wf_notification%TYPE,
    directory               varchar2(150),
    file_name               varchar2(150),
    file_last_update_date   xxcmn_outbound.file_last_update_date%TYPE,
    wf_name                 varchar2(150),
    wf_owner                varchar2(150),
    user_cd01               varchar2(150),
    user_cd02               varchar2(150),
    user_cd03               varchar2(150),
    user_cd04               varchar2(150),
    user_cd05               varchar2(150),
    user_cd06               varchar2(150),
    user_cd07               varchar2(150),
    user_cd08               varchar2(150),
    user_cd09               varchar2(150),
    user_cd10               varchar2(150)
  );
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  -- �t�H�[�~����NO�̔Ԋ֐�
  FUNCTION xxinv_get_formula_no(
-- del start 1.1
--    iv_from_item_no   IN ic_item_mst_b.item_no%TYPE,   -- �U�֌��i�ڃR�[�h
-- del end 1.1
    iv_to_item_no     IN ic_item_mst_b.item_no%TYPE)   -- �U�֐�i�ڃR�[�h
    RETURN VARCHAR2;                                   -- �t�H�[�~����NO
--
  -- ���V�sNO�̔Ԋ֐�
  FUNCTION xxinv_get_recipe_no(
    iv_to_item_no     IN ic_item_mst_b.item_no%TYPE)   -- �U�֐�i�ڃR�[�h
    RETURN VARCHAR2;                                   -- ���V�sNO
--
END xxinv_common_pkg;
/
