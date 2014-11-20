CREATE OR REPLACE PACKAGE XXCOS009A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A01R (spec)
 * Description      : 受注一覧リスト
 * MD.050           : 受注一覧リスト MD050_COS_009_A01
 * Version          : 1.3
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
 *  2009/01/06    1.0   T.TYOU             新規作成
 *  2009/02/12    1.1   T.TYOU           [障害番号：064]保管場所の外部結合条件足りない
 *  2009/02/17    1.2   T.TYOU           get_msgのパッケージ名修正
 *  2009/04/14    1.3   T.Kiriu          [T1_0470]顧客発注番号取得元修正
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_order_source                 IN     VARCHAR2,         --   受注ソース
    iv_delivery_base_code           IN     VARCHAR2,         --   納品拠点コード
    iv_ordered_date_from            IN     VARCHAR2,         --   納品日(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   納品日(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   出荷予定日(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   出荷予定日(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   納品予定日(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   納品予定日(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   入力者コード
    iv_ship_to_code                 IN     VARCHAR2,         --   出荷先コード
    iv_subinventory                 IN     VARCHAR2,         --   保管場所
    iv_order_number                 IN     VARCHAR2          --   受注番号
  );
END XXCOS009A01R;
/
