CREATE OR REPLACE PACKAGE XXCOK015A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A03R(spec)
 * Description      : 支払先の顧客より問合せがあった場合、
 *                    取引条件別の金額が印字された支払案内書を印刷します。
 * MD.050           : 支払案内書印刷（明細） MD050_COK_015_A03
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
 *  2009/01/13    1.0   K.Yamaguchi      新規作成
 *  2018/07/06    1.1   K.Nara           [障害E_本稼動_15005] 事務センター案件（支払案内書、販売報告書一括出力）
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  , iv_base_code                   IN  VARCHAR2        -- 問合せ先
  , iv_target_ym                   IN  VARCHAR2        -- 案内書発行年月
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
-- Ver.1.1 [障害E_本稼動_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- 要求ID
  , in_output_num                  IN  NUMBER          -- 出力番号
-- Ver.1.1 [障害E_本稼動_15005] SCSK K.Nara ADD END
  );
END XXCOK015A03R;
/
