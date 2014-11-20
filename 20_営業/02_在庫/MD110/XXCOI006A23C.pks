CREATE OR REPLACE PACKAGE XXCOI006A23C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A23C(spec)
 * Description      : VD受払情報を元に、CSVデータを作成します。
 * MD.050           : VD受払CSV作成<MD050_COI_006_A23>
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
 *  2009/02/10    1.0   H.Sasaki         初版作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT VARCHAR2,       -- エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       -- リターン・コード    --# 固定 #
    iv_output_kbn       IN  VARCHAR2,       -- 【必須】出力区分
    iv_reception_date   IN  VARCHAR2,       -- 【必須】受払年月
    iv_cost_kbn         IN  VARCHAR2,       -- 【必須】原価区分
    iv_base_code        IN  VARCHAR2        -- 【任意】拠点
  );
END XXCOI006A23C;
/
