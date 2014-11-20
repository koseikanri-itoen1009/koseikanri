CREATE OR REPLACE PACKAGE XXCOS002A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A05R(spec)
 * Description      : 納品書チェックリスト
 * MD.050           : 納品書チェックリスト MD050_COS_002_A05
 * Version          : 1.4
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
 *  2009/01/05    1.0   S.Miyakoshi      新規作成
 *  2009/02/17    1.1   S.Miyakoshi      get_msgのパッケージ名修正
 *  2009/02/26    1.2   S.Miyakoshi      従業員の履歴管理対応(xxcos_rs_info_v)
 *  2009/02/26    1.3   S.Miyakoshi      帳票コンカレント起動後のワークテーブル削除処理のコメント化を解除
 *  2009/02/27    1.4   S.Miyakoshi      [COS_150]販売実績データ抽出条件修正
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT VARCHAR2,         --  エラーメッセージ #固定#
    retcode               OUT VARCHAR2,         --  エラーコード     #固定#
    iv_delivery_date      IN  VARCHAR2,         --  納品日
    iv_delivery_base_code IN  VARCHAR2,         --  拠点
    iv_dlv_by_code        IN  VARCHAR2,         --  営業員
    iv_hht_invoice_no     IN  VARCHAR2          --  HHT伝票No
  );
END XXCOS002A05R;
/
