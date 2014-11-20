CREATE OR REPLACE PACKAGE APPS.XXCOS014A01C   --←<package_name>は大文字で記述して下さい。
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A01C (spec)
 * Description      : 帳票サーバにて納品書(EDI以外)データを出力するために対象となる
 *                    納品書(EDI以外)データを検索し、帳票サーバ向けのデータを作成します。
 * MD.050           : 納品書データ作成(MD050_COS_014_A01)
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
 *  2008/12/25    1.0   M.Takano         新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *                                       [障害COS_079] プロファイル追加、カーソルcur_data_recordの改修等
 *  2009/02/19    1.3   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.4   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/03/12    1.5   T.kitajima       [T1_0033] 重量/容積連携
 *  2009/04/02    1.6   T.kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/04/13    1.7   T.kitajima       [T1_0264] 帳票様式チェーン店コード追加対応
 *  2009/04/27    1.8   K.Kiriu          [T1_0112] 単位項目内容不正対応
 *  2009/05/15    1.9   M.Sano           [T1_0983] チェーン店指定時の納品拠点取得修正
 *  2009/05/21    1.10  M.Sano           [T1_0967] 取消済の受注明細を出力しない
 *                                       [T1_1088] 受注明細タイプ「30_値引」の出力時の項目不正対応
 *  2009/05/28    1.11  M.Sano           [T1_0968] 1明細目の伝票計不正対応
 *  2009/06/03    1.12  N.Maeda          [T1_1058] チェーン店セキュリティービューの結合方法変更
 *  2009/06/29    1.12  T.Kitajima       [T1_0975] 値引品目対応
 *  2009/07/02    1.12  N.Maeda          [T1_0975] 値引品目数量修正
 *  2009/07/13    1.13  K.Kiriu          [0000064] 受注ヘッダDFF項目漏れ対応
 *  2009/08/12    1.14  K.Kiriu          [0000037] PT対応
 *                                       [0000901] 顧客指定時の不具合対応
 *                                       [0001043] 売上区分混在チェック無効化対応
 *  2009/09/07    1.15  M.Sano           [0001211] 税関連項目取得基準日修正
 *                                       [0001216] 売上区分の外部結合化対応
 *  2009/09/15    1.15  M.Sano           [0001211] レビュー指摘対応
 *  2009/10/02    1.16  M.Sano           [0001306] 売上区分混在チェックのIF条件修正
 *  2009/10/14    1.17  M.Sano           [0001376] 納品書用データ作成済フラグの更新を明細単位へ変更
 *  2009/12/09    1.18  K.Nakamura       [本稼動_00171] 伝票計の計算を伝票単位へ変更
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
--******************************************* 2009/04/13 1.7 T.Kitajima ADD START *************************************
--    in_publish_flag_seq         IN     NUMBER     -- 16.納品書発行フラグ順番
    in_publish_flag_seq         IN     NUMBER,    -- 16.納品書発行フラグ順番
    iv_ssm_store_code           IN     VARCHAR2   -- 17.帳票様式チェーン店コード
--******************************************* 2009/04/13 1.7 T.Kitajima ADD  END  *************************************
  );
END XXCOS014A01C;
/
