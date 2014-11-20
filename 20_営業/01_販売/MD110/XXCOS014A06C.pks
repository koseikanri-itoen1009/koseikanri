CREATE OR REPLACE PACKAGE APPS.XXCOS014A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A06C (spec)
 * Description      : 納品予定プルーフリスト作成
 * MD.050           : 納品予定プルーフリスト作成 MD050_COS_014_A06 
 * Version          : 1.14
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
 *  2009/01/05    1.0   H.Noda           新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *  2009/02/16    1.3   T.Nakamura       [障害COS_079] プロファイル追加、カーソルcur_data_recordの改修等
 *  2009/02/17    1.4   T.Nakamura       [障害COS_094] CSV出力項目の修正
 *  2009/02/18    1.5   T.Nakamura       [障害COS_095] 入力パラメータ、センター納品日をカーソルcur_data_recordの抽出条件に追加
 *  2009/02/19    1.6   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.7   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *                                       [障害COS_114] CSV出力レコード抽出条件に手書伝票伝送区分を追加
 *  2009/02/24    1.8   T.Nakamura       [障害COS_119] CSV出力レコード抽出条件の在庫組織IDを修正
 *  2009/04/02    1.9   T.Kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/04/27    1.10  K.Kiriu          [T1_0112] 単位項目内容不正対応
 *  2009/06/17    1.11  M.Sano           [T1_1348] 行Noの結合条件変更
 *                                       [T1_1358] 定番特売区分0→00,1→01,2→02変更
 *  2009/06/22          M.Sano           [T1_1158] 店舗コードNULL対応
 *  2009/07/01          N.Maeda          [T1_1359] 数量出力項目の編集追加(共通関数による処理)
 *  2009/07/03          N.Maeda          [T1_1158] 店舗コードNULL対応(ログイン拠点出力)
 *  2009/07/06          N.Maeda          [0000063] 対象データ抽出条件追加
 *                                       [0000064] 伝票区分、大分類の取得先変更
 *  2009/07/22          N.Maeda          [0000644] 端数処理対応
 *  2009/07/23          N.Maeda          [T1_1359] レビュー指摘対応
 *  2009/08/18    1.12  N.Maeda          [0000888] 特売区分取得値修正(EDI受注時)
 *  2009/08/20          N.Maeda          [0000888] 抽出条件修正(EDI受注時)
 *  2009/08/27    1.13  N.Maeda          [0000443] PT対応
 *                                       [0001306] 伝票計集約条件、売上区分チェック条件修正
 *  2009/10/06    1.14  N.Maeda          [0001464] 受注明細分割による影響対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_file_name                 IN     VARCHAR2,  --  1.ファイル名
    iv_chain_code                IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code               IN     VARCHAR2,  --  3.帳票コード
    in_user_id                   IN     NUMBER,    --  4.ユーザID
    iv_chain_name                IN     VARCHAR2,  --  5.チェーン店名
    iv_store_code                IN     VARCHAR2,  --  6.店舗コード
    iv_base_code                 IN     VARCHAR2,  --  7.拠点コード
    iv_base_name                 IN     VARCHAR2,  --  8.拠点名
    iv_data_type_code            IN     VARCHAR2,  --  9.帳票種別コード
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 10.業務系列コード
    iv_info_div                  IN     VARCHAR2,  -- 11.情報区分
    iv_report_name               IN     VARCHAR2,  -- 12.帳票様式
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 13.店舗納品日(FROM）
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 14.店舗納品日（TO）
    iv_center_delivery_date_from IN     VARCHAR2,  -- 15.センター納品日（FROM）
    iv_center_delivery_date_to   IN     VARCHAR2,  -- 16.センター納品日（TO）
    iv_bargain_class             IN     VARCHAR2   -- 17.定番特売区分
  );
END XXCOS014A06C;
/
