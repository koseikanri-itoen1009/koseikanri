CREATE OR REPLACE PACKAGE APPS.XXCFF017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A02C (spec)
 * Description      : 自販機物件CSV出力
 * MD.050           : 自販機物件CSV出力 (MD050_CFF_017A02)
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
 *  2014/06/09    1.0   T.Kobori         main新規作成
 *  2014/07/09    1.1   T.Kobori         項目追加  1.仕入先コード
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2      -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2      -- エラーコード     #固定#
   ,iv_search_type                  IN     VARCHAR2      -- 1.検索区分 
   ,iv_machine_type                 IN     VARCHAR2      -- 2.機器区分
   ,iv_object_code                  IN     VARCHAR2      -- 3.物件コード
   ,iv_object_status                IN     VARCHAR2      -- 4.物件ステータス
   ,iv_department_code              IN     VARCHAR2      -- 5.管理部門
   ,iv_manufacturer_name            IN     VARCHAR2      -- 6.メーカ名
   ,iv_model                        IN     VARCHAR2      -- 7.機種
   ,iv_dclr_place                   IN     VARCHAR2      -- 8.申告地
   ,iv_date_placed_in_service_from  IN     VARCHAR2      -- 9.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN     VARCHAR2      -- 10.事業供用日 TO
   ,iv_date_retired_from            IN     VARCHAR2      -- 11.除売却日 FROM
   ,iv_date_retired_to              IN     VARCHAR2      -- 12.除売却日 TO
   ,iv_process_type                 IN     VARCHAR2      -- 13.履歴処理区分
   ,iv_process_date_from            IN     VARCHAR2      -- 14.履歴処理日 FROM
   ,iv_process_date_to              IN     VARCHAR2      -- 15.履歴処理日 TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN     VARCHAR2      -- 16.仕入先コード
 -- 2014/07/09 ADD END
  );
END XXCFF017A02C;
/
