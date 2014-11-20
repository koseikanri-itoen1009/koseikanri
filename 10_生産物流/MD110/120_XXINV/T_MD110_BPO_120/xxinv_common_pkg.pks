CREATE OR REPLACE PACKAGE xxinv_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv_common_pkg(SPEC)
 * Description            : 共通関数(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_120_共通関数（補足資料）.xls
 * Version                : 1.1
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  xxinv_get_formula_no   F   VAR   フォーミュラNO採番関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/02/14   1.0   marushita        新規作成
 *  2008/10/10   1.1   Oracle 大橋 孝郎 T_S_621対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル型
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
  -- プロシージャおよびファンクション
  -- ===============================
--
  -- フォーミュラNO採番関数
  FUNCTION xxinv_get_formula_no(
-- del start 1.1
--    iv_from_item_no   IN ic_item_mst_b.item_no%TYPE,   -- 振替元品目コード
-- del end 1.1
    iv_to_item_no     IN ic_item_mst_b.item_no%TYPE)   -- 振替先品目コード
    RETURN VARCHAR2;                                   -- フォーミュラNO
--
  -- レシピNO採番関数
  FUNCTION xxinv_get_recipe_no(
    iv_to_item_no     IN ic_item_mst_b.item_no%TYPE)   -- 振替先品目コード
    RETURN VARCHAR2;                                   -- レシピNO
--
END xxinv_common_pkg;
/
