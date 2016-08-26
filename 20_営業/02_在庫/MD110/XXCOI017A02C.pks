CREATE OR REPLACE PACKAGE APPS.XXCOI017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI017A02C(spec)
 * Description      : ロット別引当情報CSVをワークフロー形式で配信します。
 * MD.050           : ロット別出荷情報配信 <MD050_COI_017_A02>
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
 *  2016/07/22    1.0   K.Kiriu          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode               OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_login_base_code    IN     VARCHAR2,         -- 1.拠点コード
    iv_request_date_from  IN     VARCHAR2,         -- 2.着日（From）
    iv_request_date_to    IN     VARCHAR2          -- 3.着日（To）
  );
END XXCOI017A02C;
/
