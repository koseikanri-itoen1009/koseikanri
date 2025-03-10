CREATE OR REPLACE PACKAGE APPS.XXCOS005A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A08C (spec)
 * Description      : CSVファイルの受注取込
 * MD.050           : CSVファイルの受注取込 MD050_COS_005_A08_
 * Version          : 1.18
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
 *  2008/11/25    1.0   S.Kitaura        新規作成
 *  2009/2/3      1.1   K.Atsushiba      COS_001 対応
 *                                         ・(A-7)5.納品日稼働日チェックの稼働日導出関数のパラメータ「保管倉庫コード」
 *                                           をNULL、「リードタイム」を0に修正。
 *                                         ・(A-7)7.出荷予定日算出の稼働日導出関数のパラメータ「保管倉庫コード」を
 *                                           NULLに修正。
 *  2009/2/3      1.2   T.Miyata         COS_008,010 対応
 *                                         ・「2-1.品目アドオンマスタのチェック」
 *                                              Disc品目とDisc品目アドオンの結合条件訂正
 *                                         ・「set_order_data    データ設定処理」
 *                                              国際の場合の単位をNULL⇒プロファイルから取得した単位(CS)へ修正
 *                                         ・「set_order_data    データ設定処理」
 *                                              要求日に受注日ではなく納品日を設定
 *                                         ・「set_order_data    データ設定処理」
 *                                              ヘッダ，明細のコンテキストに各受注タイプを設定
 *  2009/02/19    1.3   T.kitajima       受注インポート呼び出し対応
 *                                       get_msgのパッケージ名修正
 *  2009/2/20     1.4   T.Miyashita      パラメータのログファイル出力対応
 *  2009/04/06    1.5   T.Kitajima       [T1_0313]配送先番号のデータ型修正
 *                                       [T1_0314]出荷元保管場所取得修正
 *  2009/05/19    1.6   T.Kitajima       [T1_0242]品目取得時、OPM品目マスタ.発売（製造）開始日条件追加
 *                                       [T1_0243]品目取得時、子品目対象外条件追加
 *  2009/07/10    1.7   T.Tominaga       [0000137]Interval,Max_waitをFND_PROFILEより取得
 *  2009/07/14    1.8   T.Miyata         [0000478]顧客所在地の抽出条件に有効フラグを追加
 *  2009/07/15    1.9   T.Miyata         [0000066]起動するコンカレントを変更：受注インポート⇒受注インポートエラー検知
 *  2009/07/17    1.10  K.Kiriu          [0000469]オーダーNoデータ型不正対応
 *  2009/07/21    1.11  T.Miyata         [0000478指摘対応]TOO_MANY_ROWS例外取得
 *  2009/08/21    1.12  M.Sano           [0000302]JANコードからの品目取得を顧客品目経由に変更
 *  2009/10/30    1.13  N.Maeda          [0001113]XXCMN_CUST_ACCT_SITES2_Vの絞込み時のOU切替処理を追加(org_id)
 *  2009/11/18    1.14  N.Maeda          [E_T4_00203]国際CSV「出荷依頼No.」追加に伴う修正
 *  2009/12/04    1.15  N.Maeda          [E_本稼動_00330]
 *                                       国際CSV取込時「締め時間」「オーダーNo」「出荷日」の任意項目化、配送先コード取得処理の削除
 *  2009/12/07          N.Maeda          [E_本稼動_00086] 出荷予定日の導出条件修正
 *  2009/12/16    1.16  N.Maeda          [E_本稼動_00495] 締め時間のNULL判定用IF文設定箇所修正
 *  2009/12/28    1.17  N.Maeda          [E_本稼動_00683]出荷予定日取得関数による翌稼働日算出の追加。
 *  2010/01/12    1.18  M.Uehara         [E_本稼動_01011]問屋CSV取込時「出荷日」が登録されている場合、受注の出荷予定日に登録。
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT VARCHAR2, -- エラーメッセージ #固定#
    retcode           OUT VARCHAR2, -- エラーコード     #固定#
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2  -- 2.<フォーマットパターン>
  );
--
END XXCOS005A08C;
/
