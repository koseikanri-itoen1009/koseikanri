CREATE OR REPLACE PACKAGE BODY xxinv_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv_common_pkg(BODY)
 * Description            : 共通関数(BODY)
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
--#######################  固定グローバル定数宣言部 START   #######################
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
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  resource_busy_expt           EXCEPTION;     -- デッドロックエラー
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common_pkg'; -- パッケージ名
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- 正常
  gn_ret_error     CONSTANT NUMBER := 1; -- エラー
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Function Name   : xxinv_get_formula_no
   * Description     : フォーミュラNO採番関数
   ***********************************************************************************/
  FUNCTION xxinv_get_formula_no
    (
-- mod start 1.1
--      iv_from_item_no   IN   ic_item_mst_b.item_no%TYPE   -- 振替元品目コード
--     ,iv_to_item_no     IN   ic_item_mst_b.item_no%TYPE   -- 振替先品目コード
      iv_to_item_no     IN   ic_item_mst_b.item_no%TYPE   -- 振替先品目コード
-- mod end 1.1
    )
    RETURN VARCHAR2             -- フォーミュラNo
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxinv_get_formula_no'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- mod start 1.1
--    lv_for_head   CONSTANT   VARCHAR2(2) := 'ZZ';    -- 品目振替識別子_頭文字
    lv_kbn        CONSTANT   VARCHAR2(2) := '9';     -- 区分
    lv_hyphen     CONSTANT   VARCHAR2(1) := '-';     -- 品目振替識別子_接続文字
--    lv_for_footer CONSTANT   VARCHAR2(5) := '99999'; -- 品目振替識別子_末尾文字
-- mod end 1.1
--
    -- *** ローカル変数 ***
    lv_for_from_item_no   VARCHAR2(7);   -- 振替元品目コード
    lv_for_to_item_no     VARCHAR2(7);   -- 振替先品目コード
    lv_numbering_no       VARCHAR2(3);   -- 連番
    ln_numbering_no       NUMBER;        -- 連番
-- add start 1.1
    lv_formula_no         VARCHAR2(100);  -- フォーミュラNo(検索用)
    lv_sql                VARCHAR2(1000);
-- add end 1.1
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
-- del start 1.1
    -- 振替元品目コードを7桁で設定
--    lv_for_from_item_no := LPAD(iv_from_item_no, 7, '0');
-- del end 1.1
    -- 振替先品目コードを7桁で設定
    lv_for_to_item_no   := LPAD(iv_to_item_no, 7, '0');
--
-- add start 1.1
    lv_formula_no := lv_for_to_item_no || lv_hyphen || lv_kbn;
    -- フォーミュラNo存在チェック
    lv_sql := 'SELECT MAX(TO_NUMBER(SUBSTR(ffmb.formula_no,11)))+1';
    lv_sql := lv_sql || ' FROM   fm_form_mst_b ffmb';
    lv_sql := lv_sql || ' WHERE  ffmb.formula_no LIKE ''' || lv_formula_no  || '%''';
--
    EXECUTE IMMEDIATE lv_sql INTO ln_numbering_no;
--
    -- フォーミュラNoが存在しない場合
    IF (ln_numbering_no IS NULL) THEN
      -- フォーミュラNoを初期値で設定
      lv_numbering_no := '001';
    -- フォーミュラNoが1000の場合
    ELSIF (ln_numbering_no = 1000) THEN
      RETURN NULL;
    -- フォーミュラNoが存在した場合
    ELSE
      -- フォーミュラNoを3桁で設定
      lv_numbering_no := LPAD(ln_numbering_no, 3, '0');
    END IF;
-- add end 1.1
    -- フォーミュラNO
-- mod start 1.1
--    RETURN (lv_for_head || lv_for_from_item_no || lv_hyphen ||
--             lv_for_to_item_no || lv_hyphen || lv_for_footer);
    RETURN (lv_for_to_item_no || lv_hyphen ||
             lv_kbn || lv_hyphen || lv_numbering_no);
-- mod end 1.1
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
        RETURN NULL;
--
--###################################  固定部 END   #########################################
--
  END xxinv_get_formula_no;
--
  /**********************************************************************************
   * Function Name   : xxinv_get_recipe_no
   * Description     : レシピNO採番関数
   ***********************************************************************************/
  FUNCTION xxinv_get_recipe_no
    (
      iv_to_item_no     IN   ic_item_mst_b.item_no%TYPE   -- 振替先品目コード
    )
    RETURN VARCHAR2             -- フォーミュラNo
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxinv_get_recipe_no'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_kbn              CONSTANT   VARCHAR2(2) := '9'; -- 区分
    lv_hyphen           CONSTANT   VARCHAR2(1) := '-'; -- 品目振替識別子_接続文字
--
    -- *** ローカル変数 ***
    lv_for_to_item_no     VARCHAR2(7);   -- 振替先品目コード
    lv_dummy_routing_no   VARCHAR2(5);   -- ダミー工順コード(品目振替用)
    lv_numbering_no       VARCHAR2(3);   -- 連番
    ln_numbering_no       NUMBER;        -- 連番
    lv_recipe_no          VARCHAR2(100); -- レシピNo(検索用)
    lv_sql                VARCHAR2(1000);
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- 振替先品目コードを7桁で設定
    lv_for_to_item_no   := LPAD(iv_to_item_no, 7, '0');
--
    lv_recipe_no := lv_for_to_item_no || lv_hyphen || lv_kbn;
    -- レシピNo存在チェック
    lv_sql := 'SELECT MAX(TO_NUMBER(SUBSTR(greb.recipe_no,11)))+1';
    lv_sql := lv_sql || ' FROM   gmd_recipes_b greb';
    lv_sql := lv_sql || ' WHERE  greb.recipe_no LIKE ''' || lv_recipe_no  || '%''';
--
    EXECUTE IMMEDIATE lv_sql INTO ln_numbering_no;
--
    -- レシピNoが存在しない場合
    IF (ln_numbering_no IS NULL) THEN
      -- フォーミュラNoを初期値で設定
      lv_numbering_no := '001';
    -- レシピNoが1000の場合
    ELSIF (ln_numbering_no = 1000) THEN
      RETURN NULL;
    -- レシピNoが存在した場合
    ELSE
      -- レシピNoを3桁で設定
      lv_numbering_no := LPAD(ln_numbering_no, 3, '0');
    END IF;
--
    -- レシピNO
    RETURN (lv_for_to_item_no || lv_hyphen ||
             lv_kbn || lv_hyphen || lv_numbering_no);
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
        RETURN NULL;
--
--###################################  固定部 END   #########################################
--
  END xxinv_get_recipe_no;
--
END xxinv_common_pkg;
/
