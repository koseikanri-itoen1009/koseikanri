CREATE OR REPLACE PACKAGE xxcmn820005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820005c(spec)
 * Description      : 原価コピー処理
 * MD.050           : 標準原価マスタT_MD050_BPO_821
 * MD.070           : 原価コピー処理(82E) T_MD070_BPO_82E
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
 *  2008/07/01    1.0   H.Itou           新規作成
 *  2009/01/08    1.1   N.Yoshida        本番#968対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,retcode              OUT NOCOPY VARCHAR2    --   リターン・コード             --# 固定 #
   ,iv_calendar_code     IN  VARCHAR2    --   カレンダコード
   ,iv_prod_class_code   IN  VARCHAR2    --   商品区分
   ,iv_item_class_code   IN  VARCHAR2    --   品目区分
   ,iv_item_code         IN  VARCHAR2    --   品目
   ,iv_update_date_from  IN  VARCHAR2    --   更新日時FROM
   ,iv_update_date_to    IN  VARCHAR2    --   更新日時TO
  );
END xxcmn820005c;
/
