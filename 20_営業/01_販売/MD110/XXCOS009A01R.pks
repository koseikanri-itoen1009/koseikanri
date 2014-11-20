CREATE OR REPLACE PACKAGE APPS.XXCOS009A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A01R (spec)
 * Description      : 受注一覧リスト
 * MD.050           : 受注一覧リスト MD050_COS_009_A01
 * Version          : 1.12
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
 *  2009/05/08    1.4   T.Kitajima       [T1_0925]出荷先コード変更
 *  2009/06/19    1.5   N.Nishimura      [T1_1437]データパージ不具合対応
 *  2009/07/13    1.6   K.Kiriu          [0000063]情報区分の課題対応
 *  2009/07/29    1.7   T.Tominaga       [0000271]受注ソースがEDI受注とそれ以外とでカーソルを分ける（EDI受注のみロック）
 *  2009/10/02    1.8   N.Maeda          [0001338]execute_svfの独立トランザクション化
 *  2009/12/28    1.9   K.Kiriui         [E_本稼動_00407]EDI帳票再出力対応
 *                                       [E_本稼動_00409]帳票出力順序変更対応
 *                                       [E_本稼動_00583]伝票区分、分類区分出力対応
 *                                       [E_本稼動_00700]明細金額の端数処理変更対応
 *  2010/01/22    1.9   Y.Kikuchi        [E_本稼動_00408]伝票計出力対応
 *  2010/04/01    1.12  M.Sano           [E_本稼動_01811]受注ソース「出荷実績依頼」追加対応
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
/* 2009/12/28 Ver1.9 Mod Start */
--    iv_order_number                 IN     VARCHAR2          --   受注番号
    iv_order_number                 IN     VARCHAR2,         --   受注番号
    iv_output_type                  IN     VARCHAR2,         --   出力区分
    iv_chain_code                   IN     VARCHAR2,         --   チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,         --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   納品日(ヘッダ)(FROM)
/* 2010/04/01 Ver1.12 Mod Start */
--    iv_ordered_date_h_to            IN     VARCHAR2          --   納品日(ヘッダ)(TO)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   納品日(ヘッダ)(TO)
    iv_order_status                 IN     VARCHAR2          --   受注ステータス
/* 2010/04/01 Ver1.12 Mod End   */
/* 2009/12/28 Ver1.9 Mod End   */
  );
END XXCOS009A01R;
/
