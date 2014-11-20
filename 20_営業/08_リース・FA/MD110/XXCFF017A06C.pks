CREATE OR REPLACE PACKAGE APPS.XXCFF017A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A06C (spec)
 * Description      : 資産精算勘定消込リスト
 * MD.050           : 資産精算勘定消込リスト (MD050_CFF_017A06)
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
 *  2014/06/17    1.0   T.Kobori         main新規作成
 *  2014/07/04    1.1   T.Kobori         項目追加  1.仕入先コード
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2      -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2      -- エラーコード     #固定#
   ,iv_asset_number                 IN     VARCHAR2      -- 1.資産番号
   ,iv_object_code                  IN     VARCHAR2      -- 2.物件コード
   ,iv_segment1                     IN     VARCHAR2      -- 3.会社コード
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN     VARCHAR2      -- 10.仕入先コード
 -- 2014/07/04 ADD END
   ,iv_description                  IN     VARCHAR2      -- 4.摘要
   ,iv_date_placed_in_service_from  IN     VARCHAR2      -- 5.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN     VARCHAR2      -- 6.事業供用日 TO
   ,iv_original_cost_from           IN     VARCHAR2      -- 7.取得価格 FROM
   ,iv_original_cost_to             IN     VARCHAR2      -- 8.取得価格 TO
   ,iv_segment3                     IN     VARCHAR2      -- 9.資産勘定
  );
END XXCFF017A06C;
/
