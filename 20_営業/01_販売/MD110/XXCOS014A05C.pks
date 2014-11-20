CREATE OR REPLACE PACKAGE APPS.XXCOS014A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A05C (spec)
 * Description      : 帳票発行画面(アドオン)で指定した条件を元にEDI経由で取り込んだ在庫情報
 *                    を、帳票サーバ向けにファイルを出力します。
 * MD.050           : 在庫情報データ作成(MD050_COS_014_A05)
 * Version          : 1.10
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
 *  2009/01/06    1.0   M.Takano         新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *  2009/02/16    1.3   T.Nakamura       [障害COS_079] プロファイル追加、納品拠点情報取得処理改修
 *  2009/02/17    1.4   T.Nakamura       [障害COS_094] CSV出力項目の修正
 *  2009/02/19    1.5   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.6   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/04/02    1.7   T.Kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/05/27    1.8   K.Tsuboi         [T1_1222] 単位の取得元変更
 *  2009/06/18    1.9   T.Kitajima       [T1_1158] 店舗コードNULL対応
 *  2010/03/08    1.10  T.Nakanao        [E_本稼動_01695] EDI取込日の変更
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_file_name                IN     VARCHAR2,  --  1.ファイル名
    iv_chain_code               IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code              IN     VARCHAR2,  --  3.帳票コード
    in_user_id                  IN     NUMBER,    --  4.ユーザID
    iv_chain_name               IN     VARCHAR2,  --  5.チェーン店名
    iv_store_code               IN     VARCHAR2,  --  6.店舗コード
    iv_base_code                IN     VARCHAR2,  --  7.拠点コード
    iv_base_name                IN     VARCHAR2,  --  8.拠点名
    iv_data_type_code           IN     VARCHAR2,  --  9.帳票種別コード
    iv_ebs_business_series_code IN     VARCHAR2,  -- 10.業務系列コード
    iv_info_class               IN     VARCHAR2,  -- 11.情報区分
    iv_report_name              IN     VARCHAR2,  -- 12.帳票様式
    iv_edi_date_from            IN     VARCHAR2,  -- 13.EDI取込日(FROM)
    iv_edi_date_to              IN     VARCHAR2,  -- 14.EDI取込日(TO)
    iv_item_class               IN     VARCHAR2   -- 15.商品区分
  );
END XXCOS014A05C;
/
