CREATE OR REPLACE PACKAGE XXCOP_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : 共通関数パッケージ(計画)
 * MD.050           : 共通関数    MD070_IPO_COP
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  get_charge_base_code     01.担当拠点取得関数
 *  get_case_quantity        02.ケース数換算関数
 *  delete_upload_table      03.ファイルアップロードテーブルデータ削除処理
 *  chk_date_format          04.日付型チェック関数
 *  chk_number_format        05.数値型チェック関数
 *  put_debug_message        06.デバッグメッセージ出力関数
 *  char_delim_partition     07.デリミタ文字分割関数
 *  get_upload_table_info    08.ファイルアップロードテーブル情報取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/04    1.0                   新規作成
 *  2009/03/25    1.1   S.Kayahara      最終行にスラッシュ追加
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  TYPE g_char_ttype IS TABLE OF VARCHAR2(256)   INDEX BY BINARY_INTEGER;    -- デリミタ文字格納用
--
/************************************************************************
 * Function Name   : get_charge_base_code
 * Description     : ユーザに紐づく拠点コードを取得する
 ************************************************************************/
  FUNCTION get_charge_base_code
  ( in_user_id      IN NUMBER             -- ユーザーID
  , id_target_date  IN DATE               -- 対象日
  )
  RETURN VARCHAR2;                        -- 拠点コード
/************************************************************************
 * Function Name   : get_case_quantity
 * Description     : 品目コード、数量(品目の基準単位とする）より、
 *                   OPM品目マスタを参照し、ケース入数からケース数を算出する
 ************************************************************************/
  PROCEDURE get_case_quantity
  ( iv_item_no                IN  VARCHAR2       -- 品目コード
  , in_individual_quantity    IN  NUMBER         -- バラ数量
  , in_trunc_digits           IN  NUMBER         -- 切捨て桁数
  , on_case_quantity          OUT NUMBER         -- ケース数量
  , ov_retcode                OUT VARCHAR2       -- リターンコード
  , ov_errbuf                 OUT VARCHAR2       -- エラー・メッセージ
  , ov_errmsg                 OUT VARCHAR2       -- ユーザー・エラー・メッセージ
  )
;
/************************************************************************
 * Procedure Name  : delete_upload_table
 * Description     : ファイルアップロードインターフェーステーブルの
 *                   データを削除する
 ************************************************************************/
  PROCEDURE delete_upload_table
  ( in_file_id    IN  NUMBER          -- ファイルＩＤ
  , ov_retcode    OUT VARCHAR2        -- リターンコード
  , ov_errbuf     OUT VARCHAR2        -- エラー・メッセージ
  , ov_errmsg     OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  );
/************************************************************************
 * Procedure Name  : chk_date_format
 * Description     : 日付型チェック関数
 ************************************************************************/
  FUNCTION chk_date_format
  ( iv_value      IN  VARCHAR2        -- 文字列
  , iv_format     IN  VARCHAR2        -- 書式
  )
  RETURN BOOLEAN;
/************************************************************************
 * Procedure Name  : chk_number_format
 * Description     : 数値型チェック関数
 ************************************************************************/
  FUNCTION chk_number_format
  ( iv_value      IN  VARCHAR2        -- 文字列
  )
  RETURN BOOLEAN;
/************************************************************************
 * Procedure Name  : put_debug_message
 * Description     : デバッグメッセージ出力関数
 ************************************************************************/
  PROCEDURE put_debug_message(
    iv_value       IN      VARCHAR2     -- 文字列
  , iov_debug_mode IN OUT  VARCHAR2     -- デバッグモード
  );
/************************************************************************
 * Procedure Name  : char_delim_partition
 * Description     : デリミタ文字分割関数
 ************************************************************************/
  PROCEDURE char_delim_partition(
    iv_char       IN  VARCHAR2        -- 対象文字列
  , iv_delim      IN  VARCHAR2        -- デリミタ
  , o_char_tab    OUT g_char_ttype    -- 分割結果
  , ov_retcode    OUT VARCHAR2        -- リターンコード
  , ov_errbuf     OUT VARCHAR2        -- エラー・メッセージ
  , ov_errmsg     OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  );
/************************************************************************
 * Procedure Name  : get_upload_table_info
 * Description     : ファイルアップロードテーブル情報取得
 ************************************************************************/
  PROCEDURE get_upload_table_info(
    in_file_id     IN  NUMBER          -- ファイルID
  , iv_format      IN  VARCHAR2        -- フォーマットパターン
  , ov_upload_name OUT VARCHAR2        -- ファイルアップロード名称
  , ov_file_name   OUT VARCHAR2        -- ファイル名
  , od_upload_date OUT DATE            -- アップロード日時
  , ov_retcode     OUT VARCHAR2        -- リターンコード
  , ov_errbuf      OUT VARCHAR2        -- エラー・メッセージ
  , ov_errmsg      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  );
END XXCOP_COMMON_PKG;
/
