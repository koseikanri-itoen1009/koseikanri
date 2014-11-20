CREATE OR REPLACE PACKAGE APPS.XXCOS014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A03C (spec)
 * Description      : 納品確定情報データ作成(EDI)
 * MD.050           : 納品確定情報データ作成(EDI) MD050_COS_014_A03 
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
 *  2008/12/22    1.0   H.Noda           新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *  2009/02/16    1.3   T.Nakamura       [障害COS_079] プロファイル追加、カーソルcur_data_recordの改修等
 *  2009/02/17    1.4   T.Nakamura       [障害COS_094] CSV出力項目の修正
 *  2009/02/19    1.5   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.6   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/04/02    1.7   T.Kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/04/27    1.8   K.Kiriu          [T1_0112] 単位項目内容不正対応
 *  2009/06/16    1.9   T.Kitajima       [T1_1348] 行Noの結合条件変更
 *  2009/06/16    1.9   T.Kitajima       [T1_1358] 定番特売区分0→00,1→01,2→02
 *  2009/06/17    1.9   T.Kitajima       [T1_1158] 店舗コードNULL対応
 *  2009/07/01    1.9   M.Sano           [T1_1359] 数量換算対応
 *  2009/07/15    1.9   N.Maeda          [T1_1359] レビュー指摘対応(伝票計取得方法修正)
 *  2009/07/29    1.9   M.Sano           [T1_1359] レビュー指摘対応(INパラ：単位設定方法修正)
 *  2009/08/10    1.10  M.Sano           [0000442] 『返品確定情報データ作成』PTの考慮
 *  2009/08/13    1.11  M.Sano           [0001043] 売上区分混在チェック削除
 *  2009/09/09    1.12  M.Sano           [0001211] 税関連項目取得基準日修正
 *  2009/10/02    1.13  M.Sano           [0001306] 売上区分混在チェックのIF条件修正
 *  2010/02/16    1.14  K.Kiriu          [E_本稼動_01590] エラー明細出力対応（単位換算実行チェック追加）
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
    iv_shop_delivery_date_to     IN     VARCHAR2   -- 14.店舗納品日（TO）
  );
END XXCOS014A03C;
/
