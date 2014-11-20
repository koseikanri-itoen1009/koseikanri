CREATE OR REPLACE PACKAGE APPS.XXCOS002A07R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A07R(spec)
 * Description      : ベンダー売上・入金照合表
 * MD.050           : MD050_COS_002_A07_ベンダー売上・入金照合表
 * Version          : 1.0
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
 *  2012/10/15    1.0   K.Nakamura       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf              OUT VARCHAR2 -- エラーメッセージ #固定#
    , retcode             OUT VARCHAR2 -- エラーコード     #固定#
    , iv_manager_flag     IN  VARCHAR2 -- 管理者フラグ
    , iv_yymm_from        IN  VARCHAR2 -- 年月（From）
    , iv_yymm_to          IN  VARCHAR2 -- 年月（To）
    , iv_base_code        IN  VARCHAR2 -- 拠点コード
    , iv_dlv_by_code      IN  VARCHAR2 -- 営業員コード
    , iv_cust_code        IN  VARCHAR2 -- 顧客コード
    , iv_overs_and_shorts IN  VARCHAR2 -- 入金過不足
    , iv_counter_error    IN  VARCHAR2 -- カウンタ誤差
  );
END XXCOS002A07R;
/
