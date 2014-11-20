CREATE OR REPLACE PACKAGE apps.xxccp_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_common_pkg(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.2
 *
 * Program List
 *  --------------------          ---- ----- --------------------------------------------------
 *   Name                         Type  Ret   Description
 *  --------------------          ---- ----- --------------------------------------------------
 *  set_status_normal               F    VAR    正常ステータス・セット関数
 *  set_status_error                F    VAR    エラーステータス・セット関数
 *  set_status_warn                 F    VAR    警告ステータス・セット関数
 *  chk_double_byte                 F    BOOL   全角チェック
 *  char_byte_partition             F    VAR    バイト分割関数
 *  get_application                 F    NUM    アプリケーションID取得関数
 *  chk_alphabet_kana               F    BOOL   半角英大文字／半角カナ大文字チェック
 *  chk_alphabet_number_only        F    BOOL   半角英数字チェック ファンクション(記号不可)
 *  chk_number                      F    BOOL   半角数字チェック
 *  put_log_header                  P           コンカレントヘッダメッセージ出力関数
 *  chk_alphabet_number             F    BOOL   半角英数字チェック
 *  chk_tel_format                  F    BOOL   半角数字およびハイフンチェック
 *  chg_double_to_single_byte       F    BOOL   全角カタカナ英数字半角変換
 *  chg_double_to_single_byte_sub   F    VAR    全角カタカナ英数字半角変換(サブ)
 *  chk_double_byte_kana            F    BOOL   全角カタカナチェック
 *  chk_single_byte_kana            F    BOOL   半角カタカナチェック
 *  get_msg                         F    VAR    メッセージ取得
 *  chk_single_byte_kana            F    BOOL   半角カタカナチェック
 *  char_delim_partition            F    VAR    デリミタ文字分割関数
 *  chk_single_byte                 F    BOOL   半角文字列チェック
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-01    1.0  Naoki.Watanabe   新規作成
 *  2009-05-01    1.1  Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *  2009-06-15    1.2  Masayuki.Sano    [T1_1440]不要コメント分削除
 *****************************************************************************************/
--
  --正常ステータス・セット関数
  FUNCTION set_status_normal
    RETURN VARCHAR2;
  --
  --エラーステータス・セット関数
  FUNCTION set_status_error
    RETURN VARCHAR2;
  --
  --警告ステータス・セット関数
  FUNCTION set_status_warn
    RETURN VARCHAR2;
  --
  --全角チェック
  FUNCTION chk_double_byte(
                           iv_chk_char IN VARCHAR2 --チェック対象文字列
                          )
    RETURN BOOLEAN;
  --
  --バイト分割関数
  FUNCTION char_byte_partition(iv_char      IN VARCHAR2 --分割元文字
                              ,iv_part_byte IN VARCHAR2 --分割byte数
                              ,in_part_num  IN NUMBER   --返却対象INDEX
                              )
    RETURN VARCHAR2;
  --
  --アプリケーションID取得関数
  FUNCTION get_application(
                           iv_application_name IN VARCHAR2 --アプリケーション短縮名
                          )
    RETURN NUMBER;
  --
  --半角英大文字／半角カナ大文字チェック
  FUNCTION chk_alphabet_kana(
                             iv_check_char IN VARCHAR2 --チェック対象文字列
                            ) 
    RETURN BOOLEAN;
  --
  --半角英数字チェック ファンクション(記号不可)
  FUNCTION chk_alphabet_number_only(
                                    iv_check_char IN VARCHAR2 --チェック対象文字列
                                   )
    RETURN BOOLEAN;
  --
  --半角数字チェック
  FUNCTION chk_number(
                      iv_check_char IN VARCHAR2 --チェック対象文字列
                     )
    RETURN BOOLEAN;
  --
  --コンカレントヘッダメッセージ出力関数
  PROCEDURE put_log_header(
               iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT' --出力区分
              ,ov_retcode  OUT VARCHAR2 --リターンコード
              ,ov_errbuf   OUT VARCHAR2 --エラーメッセージ
              ,ov_errmsg   OUT VARCHAR2 --ユーザー・エラーメッセージ
              );
  --
  --半角英数字チェック
  FUNCTION chk_alphabet_number(
              iv_check_char IN VARCHAR2 --チェック対象文字列
           )
    RETURN BOOLEAN;
  --
  --半角数字およびハイフンチェック
  FUNCTION chk_tel_format(
              iv_check_char IN VARCHAR2 --チェック対象文字列
           )
    RETURN BOOLEAN;
  --
  --全角カタカナ英数字半角変換
  FUNCTION chg_double_to_single_byte(
              iv_check_char IN VARCHAR2 --チェック対象文字列
           )
    RETURN VARCHAR2;
  --
  --全角カタカナ英数字半角変換（サブ）
  FUNCTION chg_double_to_single_byte_sub(
              iv_check_char IN VARCHAR2 --チェック対象文字列
           )
    RETURN VARCHAR2;
  --
  --全角カタカナチェック
  FUNCTION chk_double_byte_kana(
              iv_check_char IN VARCHAR2 --チェック対象文字列
           )
    RETURN BOOLEAN;
  --
  --半角カタカナチェック
  FUNCTION chk_single_byte_kana(
              iv_check_char IN VARCHAR2 --チェック対象文字列
           )
    RETURN BOOLEAN;
  --
  --メッセージ取得
  FUNCTION get_msg(
                   iv_application    IN VARCHAR2 --アプリケーション短縮名
                  ,iv_name           IN VARCHAR2 --メッセージコード
                  ,iv_token_name1    IN VARCHAR2 DEFAULT NULL --トークンコード1
                  ,iv_token_value1   IN VARCHAR2 DEFAULT NULL --トークン値1
                  ,iv_token_name2    IN VARCHAR2 DEFAULT NULL --トークンコード2
                  ,iv_token_value2   IN VARCHAR2 DEFAULT NULL --トークン値2
                  ,iv_token_name3    IN VARCHAR2 DEFAULT NULL --トークンコード3
                  ,iv_token_value3   IN VARCHAR2 DEFAULT NULL --トークン値4
                  ,iv_token_name4    IN VARCHAR2 DEFAULT NULL --トークンコード4
                  ,iv_token_value4   IN VARCHAR2 DEFAULT NULL --トークン値4
                  ,iv_token_name5    IN VARCHAR2 DEFAULT NULL --トークンコード5
                  ,iv_token_value5   IN VARCHAR2 DEFAULT NULL --トークン値5
                  ,iv_token_name6    IN VARCHAR2 DEFAULT NULL --トークンコード6
                  ,iv_token_value6   IN VARCHAR2 DEFAULT NULL --トークン値6
                  ,iv_token_name7    IN VARCHAR2 DEFAULT NULL --トークンコード7
                  ,iv_token_value7   IN VARCHAR2 DEFAULT NULL --トークン値7
                  ,iv_token_name8    IN VARCHAR2 DEFAULT NULL --トークンコード8
                  ,iv_token_value8   IN VARCHAR2 DEFAULT NULL --トークン値8
                  ,iv_token_name9    IN VARCHAR2 DEFAULT NULL --トークンコード9
                  ,iv_token_value9   IN VARCHAR2 DEFAULT NULL --トークン値9
                  ,iv_token_name10   IN VARCHAR2 DEFAULT NULL --トークンコード10
                  ,iv_token_value10  IN VARCHAR2 DEFAULT NULL --トークン値10
                 )
    RETURN VARCHAR2;
  --
  --デリミタ文字分割関数
  FUNCTION char_delim_partition(iv_char     IN VARCHAR2
                               ,iv_delim    IN VARCHAR2
                               ,in_part_num IN NUMBER
                               )
    RETURN VARCHAR2;
  --
--
  -- 半角チェック
  FUNCTION chk_single_byte(
    iv_chk_char IN VARCHAR2             --チェック対象文字列
  )
  RETURN BOOLEAN;
--
END XXCCP_COMMON_PKG;
/
