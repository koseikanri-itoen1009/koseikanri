CREATE OR REPLACE PACKAGE APPS.xxcso_008001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_008001j_pkg(SPEC)
 * Description      : 週次活動状況照会共通関数
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_baseline_base_code    F    V      検索基準拠点コード取得関数
 *  get_plan_or_result        F    V      予定実績出力文言取得関数
 *  get_init_base_code        F    V      初期表示拠点コード取得関数
 *  get_init_base_name        F    V      初期表示拠点名称取得関数
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   N.Yanagitaira    新規作成
 *  2009/04/10    1.1   N.Yanagitaira    [ST障害T1_0422,T1_0477]get_plan_or_result追加
 *  2009/05/21    1.2   N.Yanagitaira    [ST障害T1_1104]get_baseline_base_code修正
 *                                                      get_init_base_code追加
 *                                                      get_init_base_name追加
 *
 * *****************************************************************************************/
--
  -- 検索基準拠点コード拠点コード取得関数
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2;
--
-- 20090410_N.Yanagitaira T1_0422,T1_0477 Add START
  -- 予定実績出力文言取得関数
  FUNCTION get_plan_or_result(
    in_task_status_id           NUMBER
   ,in_task_type_id             NUMBER
   ,id_actual_end_date          DATE
   ,id_scheduled_end_date       DATE
   ,iv_source_object_type_code  VARCHAR2
   ,iv_task_party_name          VARCHAR2
  ) RETURN VARCHAR2;
-- 20090410_N.Yanagitaira T1_0422,T1_0477 Add END
--
-- 20090521_N.Yanagitaira T1_1104 Add START
  -- 初期表示拠点コード取得関数
  FUNCTION get_init_base_code
  RETURN VARCHAR2;
--
  -- 初期表示拠点名称取得関数
  FUNCTION get_init_base_name
  RETURN VARCHAR2;
-- 20090521_N.Yanagitaira T1_1104 Add END
--
END xxcso_008001j_pkg;
/
