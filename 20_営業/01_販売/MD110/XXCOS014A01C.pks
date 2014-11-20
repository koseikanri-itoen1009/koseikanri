CREATE OR REPLACE PACKAGE XXCOS014A01C   --←<package_name>は大文字で記述して下さい。
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A01C (spec)
 * Description      : 帳票サーバにて納品書(EDI以外)データを出力するために対象となる
 *                    納品書(EDI以外)データを検索し、帳票サーバ向けのデータを作成します。
 * MD.050           : 納品書データ作成(MD050_COS_014_A01)
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
 *  2008/12/25    1.0   M.Takano         新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *                                       [障害COS_079] プロファイル追加、カーソルcur_data_recordの改修等
 *  2009/02/19    1.3   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.4   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/03/12    1.5   T.kitajima       [障害T1_0033] 重量/容積連携
 *
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
    iv_cust_code                IN     VARCHAR2,  --  7.顧客コード
    iv_base_code                IN     VARCHAR2,  --  8.拠点コード
    iv_base_name                IN     VARCHAR2,  --  9.拠点名
    iv_data_type_code           IN     VARCHAR2,  -- 10.帳票種別コード
    iv_ebs_business_series_code IN     VARCHAR2,  -- 11.業務系列コード
    iv_report_name              IN     VARCHAR2,  -- 12.帳票様式
    iv_shop_delivery_date_from  IN     VARCHAR2,  -- 13.店舗納品日(FROM）
    iv_shop_delivery_date_to    IN     VARCHAR2,  -- 14.店舗納品日（TO）
    iv_publish_div              IN     VARCHAR2,  -- 15.納品書発行区分
    in_publish_flag_seq         IN     NUMBER     -- 16.納品書発行フラグ順番
  );
END XXCOS014A01C;
/
