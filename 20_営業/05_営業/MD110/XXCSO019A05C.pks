create or replace PACKAGE XXCSO019A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A05C(spec)
 * Description      : 要求の発行画面から、訪問売上計画管理表を帳票に出力します。
 * MD.050           : MD050_CSO_019_A05_訪問売上計画管理表_Draft2.0A
 * Version          : 1.1
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 * get_gvm_type          一般／自販機／ＭＣ取得
 * get_tgt_amt           売上計画取得
 * get_rslt_amt          売上実績取得
 * get_rslt_other_sales_amt  他拠点納品分売上実績取得
 * get_visit_sign        訪問記号取得
 * get_i_tgt_vis_num     訪問計画取得(一般用)
 * get_v_tgt_vis_num     訪問計画取得(自販機用)
 * get_i_rslt_vis_num    訪問実績取得(一般用)
 * get_v_rslt_vis_num    訪問実績取得(自販機用)
 * get_m_rslt_vis_num    訪問実績取得(MC用)
 * get_e_rslt_vis_num    訪問実績取得(有効訪問用)
 * main                  コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Seirin.Kin        新規作成
 *  2009-05-19    1.1   Hiroshi.Ogawa     障害番号：T1_1033
 *
 *****************************************************************************************/
 --
/* 20090519_Ogawa_T1_1033 START*/
  -- グループ名取得 ⇒ xxcso_util_common_pkgに移動
  FUNCTION get_group_name(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_group_number      IN  VARCHAR2     -- グループ番号
   ,id_standard_date     IN  DATE         -- 基準日
  ) RETURN VARCHAR2;
--
  -- 訪問予定回数取得 ⇒ xxcso_route_common_pkgに移動
  FUNCTION get_route_bit(
    iv_route_no          IN  VARCHAR2     -- ルートNo
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 一般／自販機／ＭＣ取得
  FUNCTION get_gvm_type(
    iv_customer_status   IN  VARCHAR2     -- 顧客ステータス
   ,iv_business_low_type IN  VARCHAR2     -- 業態コード（小分類）
  ) RETURN VARCHAR2;
--
  -- 売上計画取得
  FUNCTION get_tgt_amt(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 売上実績取得
  FUNCTION get_rslt_amt(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 他拠点納品分売上実績取得
  FUNCTION get_rslt_other_sales_amt(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 訪問記号取得
  FUNCTION get_visit_sign(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN VARCHAR2;
--
  -- 訪問計画取得(一般用)
  FUNCTION get_i_tgt_vis_num(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 訪問計画取得(自販機用)
  FUNCTION get_v_tgt_vis_num(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 訪問実績取得(一般用)
  FUNCTION get_i_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 訪問実績取得(自販機用)
  FUNCTION get_v_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 訪問実績取得(MC用)
  FUNCTION get_m_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
  -- 訪問実績取得(有効訪問用)
  FUNCTION get_e_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- 拠点コード
   ,iv_account_number    IN  VARCHAR2     -- 顧客コード
   ,iv_year_month        IN  VARCHAR2     -- 年月
   ,in_day_index         IN  NUMBER       -- 日
  ) RETURN NUMBER;
--
/* 20090519_Ogawa_T1_1033 END*/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2          -- エラーメッセージ #固定#
   ,retcode           OUT NOCOPY VARCHAR2          -- エラーコード     #固定#
   ,iv_year_month     IN         VARCHAR2          -- 基準年月
   ,iv_report_type    IN         VARCHAR2          -- 帳票種別
   ,iv_base_code      IN         VARCHAR2          -- 拠点コード
  );
END XXCSO019A05C;
/
