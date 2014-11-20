CREATE OR REPLACE PACKAGE XXCOI006A19R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A19R(spec)
 * Description      : 払出明細表（拠点別計）
 * MD.050           : 払出明細表（拠点別計） <MD050_XXCOI_006_A19>
 * Version          : V1.0
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
 *  2008/11/14    1.0   H.Sasaki         初版作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_reception_date IN  VARCHAR2,      --   1.受払年月
    iv_cost_type      IN  VARCHAR2       --   2.原価区分
  );
END XXCOI006A19R;
/
