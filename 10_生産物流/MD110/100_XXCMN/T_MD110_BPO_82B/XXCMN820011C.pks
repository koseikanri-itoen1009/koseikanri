CREATE OR REPLACE PACKAGE xxcmn820011c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXCMN820011(spec)
 * Description      : 原価差異表作成
 * MD.050/070       : 標準原価マスタIssue1.0(T_MD050_BPO_820)
 *                    原価差異表作成Issue1.0(T_MD070_BPO_82B/T_MD070_BPO_82C)
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/20    1.0   Masayuki Ikeda   新規作成
 *  2008/12/18    1.1   Akiyoshi Shiina  子コンカレントを起動したら終了
 *
 *****************************************************************************************/
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パラメータ．表形式
  rep_type_item       CONSTANT VARCHAR2(20) := '1' ;      -- 品目別取引先別
  rep_type_vend       CONSTANT VARCHAR2(20) := '2' ;      -- 取引先別品目別
--
  -- パラメータ．出力形式
  out_type_dtl        CONSTANT VARCHAR2(20) := '1' ;      -- 明細
  out_type_sum        CONSTANT VARCHAR2(20) := '2' ;      -- 合計
--
  -- パラメータ．部署コード
  dept_code_all       CONSTANT VARCHAR2(20) := 'ZZZZ' ;   -- 部署識別なし
--
  -- プログラム名（コンカレント・テンプレート）
  program_id_01       CONSTANT VARCHAR2(20) := 'XXCMN820021' ;    -- 明細：部門別品目別
  program_id_02       CONSTANT VARCHAR2(20) := 'XXCMN820022' ;    -- 合計：部門別品目別
  program_id_03       CONSTANT VARCHAR2(20) := 'XXCMN820023' ;    -- 明細：品目別
  program_id_04       CONSTANT VARCHAR2(20) := 'XXCMN820024' ;    -- 合計：品目別
  program_id_05       CONSTANT VARCHAR2(20) := 'XXCMN820025' ;    -- 明細：部門別取引先別
  program_id_06       CONSTANT VARCHAR2(20) := 'XXCMN820026' ;    -- 合計：部門別取引先別
  program_id_07       CONSTANT VARCHAR2(20) := 'XXCMN820027' ;    -- 明細：取引先別
  program_id_08       CONSTANT VARCHAR2(20) := 'XXCMN820028' ;    -- 合計：取引先別
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_report_type        IN     VARCHAR2         --   01 : 表形式
     ,iv_output_type        IN     VARCHAR2         --   02 : 出力形式
     ,iv_fiscal_ym          IN     VARCHAR2         --   03 : 対象年月
     ,iv_prod_div           IN     VARCHAR2         --   04 : 商品区分
     ,iv_item_div           IN     VARCHAR2         --   05 : 品目区分
     ,iv_dept_code          IN     VARCHAR2         --   06 : 所属部署
     ,iv_crowd_code_01      IN     VARCHAR2         --   07 : 群コード１
     ,iv_crowd_code_02      IN     VARCHAR2         --   08 : 群コード２
     ,iv_crowd_code_03      IN     VARCHAR2         --   09 : 群コード３
     ,iv_item_code_01       IN     VARCHAR2         --   10 : 品目コード１
     ,iv_item_code_02       IN     VARCHAR2         --   11 : 品目コード２
     ,iv_item_code_03       IN     VARCHAR2         --   12 : 品目コード３
     ,iv_item_code_04       IN     VARCHAR2         --   13 : 品目コード４
     ,iv_item_code_05       IN     VARCHAR2         --   14 : 品目コード５
     ,iv_vendor_id_01       IN     VARCHAR2         --   15 : 取引先ＩＤ１
     ,iv_vendor_id_02       IN     VARCHAR2         --   16 : 取引先ＩＤ２
     ,iv_vendor_id_03       IN     VARCHAR2         --   17 : 取引先ＩＤ３
     ,iv_vendor_id_04       IN     VARCHAR2         --   18 : 取引先ＩＤ４
     ,iv_vendor_id_05       IN     VARCHAR2         --   19 : 取引先ＩＤ５
    ) ;
END xxcmn820011c;
/
