CREATE OR REPLACE PACKAGE APPS.XXCOS014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A02C (spec)
 * Description      : 納品書用データ作成(EDI)
 * MD.050           : 納品書用データ作成(EDI) MD050_COS_014_A02
 * Version          : 1.15
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
 *  2008/12/04    1.0   K.Kumamoto       新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *  2009/02/16    1.3   T.Nakamura       [障害COS_079] プロファイル追加、カーソルcur_data_recordの改修等
 *  2009/02/17    1.4   T.Nakamura       [障害COS_094] CSV出力項目の修正
 *  2009/02/19    1.5   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.6   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/04/01    1.7   T.Kitajima       [T1_0026] インパラに帳票様式チェーン店コード追加
 *                                                 処理中のインパラ.チェーン店コードを
 *                                                 インパラ.帳票様式チェーン店コードへ変更
 *  2009/04/02    1.8   T.Kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/04/27    1.9   K.Kiriu          [T1_0112] 単位項目内容不正対応
 *  2009/06/11    1.10  K.Kiriu          [T1_1352]納品書(受注情報)出力障害対応
 *  2009/06/18    1.10  N.Maeda          [T1_1158] 対象データ抽出条件変更
 *  2009/07/03    1.10  M.Sano           [T1_1158] 対象データ抽出条件変更(レビュー指摘修正)
 *  2009/08/12    1.11  N.Maeda          [0000441] PT対応
 *  2009/08/13    1.11  N.Maeda          [0000441] レビュー指摘対応
 *  2009/09/08    1.12  M.Sano           [0001211] 税関連項目取得基準日修正
 *  2009/09/15    1.12  M.Sano           [0001211] レビュー指摘対応
 *  2010/01/04    1.13  M.Sano           [E_本稼動_00738] 受注連携済フラグ「S(対象外)」追加に伴う修正
 *  2010/01/06    1.14  N.Maeda          [E_本稼動_00552] 取引先名(漢字)のスペース削除
 *  2010/03/05    1.15  T.Nakano         [E_本稼動_01695] EDI取込日の変更
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
    iv_edi_input_date            IN     VARCHAR2,  -- 15.EDI取込日
    iv_publish_div               IN     VARCHAR2,  -- 16.納品書発行区分
    in_publish_flag_seq          IN     NUMBER,    -- 17.納品書発行フラグ順番
--******************************************* 2009/03/31 1.7 T.Kitajima ADD START *************************************
    iv_ssm_store_code            IN     VARCHAR2   -- 18.帳票様式チェーン店コード
--******************************************* 2009/03/31 1.7 T.Kitajima ADD  END  *************************************
  );
END XXCOS014A02C;
/
