CREATE OR REPLACE PACKAGE XXCOI006A18R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A18R(spec)
 * Description      : 払出明細表（拠点別・合計）
 * MD.050           : 払出明細表（拠点別・合計） <MD050_XXCOI_006_A18>
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
 *  2008/12/11    1.0   Y.Kobayashi      初版作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,        -- エラーメッセージ #固定#
    retcode           OUT    VARCHAR2,        -- エラーコード     #固定#
    iv_output_kbn     IN     VARCHAR2,        -- 1.出力区分
    iv_reception_date IN     VARCHAR2,        -- 2.受払年月
    iv_cost_type      IN     VARCHAR2,        -- 3.原価区分
    iv_base_code      IN     VARCHAR2         -- 4.拠点コード
  );
END XXCOI006A18R;
/
