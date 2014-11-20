CREATE OR REPLACE PACKAGE XXCOI006A17R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A17R(spec)
 * Description      : 受払残高表（拠点別計）
 * MD.050           : 受払残高表（拠点別計） <MD050_XXCOI_006_A17>
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
 *  2008/11/13    1.0   H.Sasaki         初版作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,        -- エラーメッセージ #固定#
    retcode           OUT    VARCHAR2,        -- エラーコード     #固定#
    iv_reception_date IN  VARCHAR2,           -- 1.受払年月
    iv_cost_type      IN  VARCHAR2            -- 2.原価区分
  );
END XXCOI006A17R;
/
