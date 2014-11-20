CREATE OR REPLACE PACKAGE BODY XXCCP_COMMON_PKG
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
 *  char_delim_partition            F    VAR    デリミタ文字分割関数
 *  chk_single_byte                 F    BOOL   半角文字列チェック
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-01    1.0  Naoki.Watanabe   新規作成
 *  2009-02-23    1.1  Kanako.Kitagawa  仕様変更・バグによる修正（全角カタカナ、半角カタカナチェック)
 *  2009-02-25    1.2  Kazuhisa.Baba    バグによる修正（半角カタカナチェック)
 *****************************************************************************************/
  -- ===============================
  -- グローバル定数
  -- ===============================
  cv_msg_part CONSTANT VARCHAR2(3)  := ' : ';
  cv_pkg_name CONSTANT VARCHAR2(50) := 'XXCCP_COMMON_PKG';
  cv_period   CONSTANT VARCHAR2(1)  := '.';
--
  /**********************************************************************************
   * Function Name    : set_status_normal
   * Description      : 正常ステータス・セット関数
   ***********************************************************************************/
  FUNCTION set_status_normal
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_status_normal'; -- プログラム名
--
  BEGIN
    RETURN '0';
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END set_status_normal;
--
--
/**********************************************************************************
   * Function Name    : set_status_error
   * Description      : エラーステータス・セット関数
   ***********************************************************************************/
  FUNCTION set_status_error
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_status_error'; -- プログラム名
--
  BEGIN
    RETURN '2';
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END set_status_error;
--
--
/**********************************************************************************
   * Function Name    : set_status_warn
   * Description      : 警告ステータス・セット関数
   ***********************************************************************************/
  FUNCTION set_status_warn
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_status_warn'; -- プログラム名
--
  BEGIN
    RETURN '1';
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END set_status_warn;
--
--
/**********************************************************************************
   * Function Name    : chk_double_byte
   * Description      : 全角チェック
   ***********************************************************************************/
  FUNCTION chk_double_byte(
                           iv_chk_char IN VARCHAR2 --チェック対象文字列
                          )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_double_byte'; -- プログラム名
--
  BEGIN
    --NULLチェック
    IF (iv_chk_char IS NULL) THEN
      RETURN NULL;
    --全角チェック
    ELSIF (LENGTH(iv_chk_char) * 2 <> LENGTHB(iv_chk_char)) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      RETURN FALSE;
  END chk_double_byte;
--
--
/**********************************************************************************
   * Function Name    : char_byte_partition
   * Description      : バイト分割関数
   ***********************************************************************************/
  FUNCTION char_byte_partition(iv_char      IN VARCHAR2 --分割元文字列
                              ,iv_part_byte IN VARCHAR2 --分割byte数
                              ,in_part_num  IN NUMBER   --返却対象INDEX
                              )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'char_byte_partition'; -- プログラム名
--
    --変数定義
    lv_string      VARCHAR2(1000);
    lv_string2     VARCHAR2(1000);
    ln_count       NUMBER;
  BEGIN
--
    --NULLチェック
    IF  ((iv_char      IS NULL)
      OR (iv_part_byte IS NULL)
      OR (in_part_num  IS NULL)) THEN
      RETURN NULL;
    END IF;
--
    --分割元文字列と分割バイト数のサイズ比較チェック
    IF (LENGTHB(iv_char) < iv_part_byte) THEN
      RETURN NULL;
    END IF;
--
    --前処理
    lv_string     := iv_char;
    ln_count      := 0;
    --分割元文字列のbyte数がが分割byte数
    WHILE LENGTHB(lv_string) > iv_part_byte LOOP
--
      ln_count      := ln_count + 1;
      lv_string2    := SUBSTRB(lv_string
                         , 1, iv_part_byte);
      lv_string     := SUBSTRB(lv_string,iv_part_byte + 1);
--
      --特別終了条件
      IF (ln_count = in_part_num) THEN
          RETURN lv_string2;
      END IF;
    END LOOP;
--
    ln_count       := ln_count + 1;
    lv_string2     := lv_string;
--
    --RETURN値の判断
    IF (ln_count = in_part_num) THEN
      RETURN lv_string2;
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END char_byte_partition;
--
--
/**********************************************************************************
   * Function Name    : get_application
   * Description      : アプリケーションIDの取得
   ***********************************************************************************/
  FUNCTION get_application(
                           iv_application_name IN VARCHAR2 --アプリケーション短縮名
                          )
    RETURN NUMBER
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_application'; -- プログラム名
--
    --アプリケーションID取得カーソル定義
    CURSOR application_cur(iv_application_name VARCHAR2)
    IS
      SELECT a.application_id appli_id
      FROM   fnd_application a
      WHERE  application_short_name = iv_application_name
      ;
    application_val application_cur%ROWTYPE; --カーソル変数定義
--
  BEGIN
--
    OPEN application_cur(iv_application_name);
    --
    LOOP
      --
      FETCH application_cur INTO application_val;
      EXIT WHEN application_cur%NOTFOUND;
      --
    END LOOP;
    --アプリケーションIDを取得できなかった場合
    IF (application_cur%ROWCOUNT = 0) THEN
      RETURN NULL;
    END IF;
    --
    CLOSE application_cur;
    --
    RETURN application_val.appli_id;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_application;
--
--
/**********************************************************************************
   * Function Name    : chk_alphabet_kana
   * Description      : 半角英大文字／半角カナ大文字チェック
   ***********************************************************************************/
  FUNCTION chk_alphabet_kana(
                             iv_check_char IN VARCHAR2 --チェック対象文字列
                            )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'chk_alphabet_kana'; --プログラム名
    cn_check_char_a     CONSTANT NUMBER := 97;                         --aの文字コード
    cn_check_char_z     CONSTANT NUMBER := 122;                        --zの文字コード
    cn_check_char_kana1 CONSTANT NUMBER := 167;                        --ｧの文字コード
    cn_check_char_kana2 CONSTANT NUMBER := 175;                        --ｯの文字コード
--
    -- *** ローカル変数 ***
    lv_check_char       VARCHAR2(1);
--
  BEGIN
    -- NULLチェック
    IF (iv_check_char IS NULL) THEN
       RETURN NULL;
    END IF;
--
    -- 全角文字が入っているかどうかのチェック
    IF (LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
       RETURN FALSE;
    END IF;
--
    -- 文字を一つづつチェック
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      IF (((ASCII(lv_check_char) >= cn_check_char_a)
        AND (ASCII(lv_check_char) <= cn_check_char_z))
        OR
         ((ASCII(lv_check_char) >= cn_check_char_kana1)
        AND (ASCII(lv_check_char) <= cn_check_char_kana2)))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
--
    RETURN TRUE;
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END chk_alphabet_kana;
--
--
/**********************************************************************************
   * Function Name    : chk_alphabet_number_only
   * Description      : 半角英数字チェック ファンクション(記号不可)
   ***********************************************************************************/
  FUNCTION chk_alphabet_number_only(
                                    iv_check_char IN VARCHAR2 --チェック対象文字列
                                   )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'chk_alphabet_number_only'; -- プログラム名
    cv_check_char_0       CONSTANT VARCHAR2(1)   := '0';
    cv_check_char_9       CONSTANT VARCHAR2(1)   := '9';
    cv_check_char_A       CONSTANT VARCHAR2(1)   := 'A';
    cv_check_char_Z       CONSTANT VARCHAR2(1)   := 'Z';
    cv_check_char_small_a CONSTANT VARCHAR2(1)   := 'a';
    cv_check_char_small_z CONSTANT VARCHAR2(1)   := 'z';
--
    -- *** ローカル変数 ***
    lv_check_char   VARCHAR2(1);
--
  BEGIN
--
    -- NULLチェック
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    END IF;
--
    -- 全角文字が入っているかどうかのチェック
    IF (LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
--
    -- 文字を一つづつチェック
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      IF (NOT (
            ((lv_check_char >= cv_check_char_0) AND (lv_check_char <= cv_check_char_9))
            OR
            ((lv_check_char >= cv_check_char_A) AND (lv_check_char <= cv_check_char_Z))
            OR
            ((lv_check_char >= cv_check_char_small_a) AND (lv_check_char <= cv_check_char_small_z)) ))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
--
    RETURN TRUE;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END chk_alphabet_number_only;
--
--
/**********************************************************************************
   * Function Name    : chk_number
   * Description      : 半角数字チェック
   ***********************************************************************************/
  FUNCTION chk_number(
                      iv_check_char IN VARCHAR2 --チェック対象文字列
                     )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'chk_number'; -- プログラム名
    cv_check_char_period  CONSTANT VARCHAR2(1) := '.';
    cv_check_char_space   CONSTANT VARCHAR2(1) := ' ';
    cv_check_char_plus    CONSTANT VARCHAR2(1) := '+';
    cv_check_char_minus   CONSTANT VARCHAR2(1) := '-';
    -- *** ローカル変数 ***
    ln_convert_temp       NUMBER;   -- 変換チェック用一時領域
--
  BEGIN
--
    -- NULLチェック
    IF (iv_check_char IS NULL) THEN
       RETURN NULL;
    END IF;
--
    -- 数値変換を行い、例外が発生したら数値以外の文字が含まれていると判断する
    BEGIN
      ln_convert_temp := TO_NUMBER(iv_check_char);
    EXCEPTION
      WHEN OTHERS THEN  -- 基本的に「INVALID_NUMBER」が発生する
        RETURN FALSE;
    END;
--
    -- ピリオド、前後の空白、プラス、マイナスチェック
    IF  ((INSTR(iv_check_char,cv_check_char_period) > 0)
      OR (INSTR(iv_check_char,cv_check_char_space) > 0)
      OR (INSTR(iv_check_char,cv_check_char_plus) > 0)
      OR (INSTR(iv_check_char,cv_check_char_minus) > 0))
    THEN
      RETURN FALSE;
    END IF;
--
    RETURN TRUE;
--
    EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END chk_number;
--
  /**********************************************************************************
   * Procedure Name   : put_log_header
   * Description      : コンカレントヘッダメッセージ出力関数
   ***********************************************************************************/
  PROCEDURE put_log_header(
               iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT'  --出力区分
              ,ov_retcode  OUT VARCHAR2 --リターンコード
              ,ov_errbuf   OUT VARCHAR2 --エラーメッセージ
              ,ov_errmsg   OUT VARCHAR2 --ユーザー・エラーメッセージ
                          )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'put_log_header'; -- プログラム
    cv_xxccp1_request_id        CONSTANT VARCHAR2(100) := 'XXCCP1_REQUEST_ID';
    cv_xxccp1_concurrent_name   CONSTANT VARCHAR2(100) := 'XXCCP1_CONCURRENT_NAME';
    cv_xxccp1_user_name         CONSTANT VARCHAR2(100) := 'XXCCP1_USER_NAME';
    cv_xxccp1_resp_name         CONSTANT VARCHAR2(100) := 'XXCCP1_RESP_NAME';
    cv_xxccp1_actual_start_date CONSTANT VARCHAR2(100) := 'XXCCP1_ACTUAL_START_DATE';
    cv_language                 CONSTANT VARCHAR2(100) := USERENV('LANG');
    cv_massage_name1            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10001';
    cv_massage_name2            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10002';
    cv_massage_name3            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10003';
    cv_massage_name7            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10007';
    cv_application_short        CONSTANT VARCHAR2(100) := 'XXCCP';
    cv_colon                    CONSTANT VARCHAR2(100) := '  :  ';
    cv_null_line                CONSTANT VARCHAR2(1)   := ' ';                 -- 空行メッセージ用定数
    -- *** ローカル変数 ***
    lv_request_id          VARCHAR2(100) := fnd_global.conc_request_id;        -- 要求ID
    lv_user_name           VARCHAR2(100) := fnd_global.user_name;              -- ユーザ名
    lv_resp_id             VARCHAR2(100) := fnd_global.resp_id;                -- 職責ID
    lv_resp_appl_id        VARCHAR2(100) := fnd_global.resp_appl_id;           -- 職責アプリケーションID
    lv_responsibility_name VARCHAR2(100);                                      -- 職責名
    lv_message             VARCHAR2(1000);
    lv_message2            VARCHAR2(1000);
    lv_message3            VARCHAR2(1000);
    lv_message4            VARCHAR2(1000);
    lv_message5            VARCHAR2(1000);
    -- ============================================
    -- コンカレントの要求IDを取得するカーソルを定義
    -- ============================================
    CURSOR concurrent_cur
    IS
      --
      SELECT   fcpt.user_concurrent_program_name program_name                         --コンカレント名
              ,TO_CHAR(fcr.actual_start_date , 'YYYY/MM/DD HH24:MI:SS' ) start_date   --起動時間
      FROM     fnd_concurrent_requests    fcr    --要求管理マスタ
              ,fnd_concurrent_programs_tl fcpt   --要求マスタ
      WHERE    fcr.request_id = lv_request_id
      AND      fcr.program_application_id = fcpt.application_id
      AND      fcr.concurrent_program_id = fcpt.concurrent_program_id
      AND      fcpt.language = cv_language
      ;
      --
    concurrent_cur_v concurrent_cur%ROWTYPE;  --カーソル変数を定義
    --
    -- ================
    -- ユーザー定義例外
    -- ================
    no_data_expt  EXCEPTION; --コンカレント名、起動時間を正常に１件取得できなかった場合の例外
    no_data_expt2 EXCEPTION; --職責名を取得できなかった場合の例外
    iv_which_expt EXCEPTION; --出力区分が'OUTPUT','LOG'以外の場合の例外
--
  BEGIN
--
    OPEN concurrent_cur;
    --
    LOOP
      --
      FETCH concurrent_cur
      INTO  concurrent_cur_v;
      EXIT WHEN concurrent_cur%NOTFOUND;
      --
    END LOOP;
    --
    IF (concurrent_cur%ROWCOUNT = 0) THEN --コンカレント名、起動時間を正常に１件取得できなかった場合の例外
      RAISE no_data_expt;
    END IF;
    --
    CLOSE concurrent_cur;
    --
    BEGIN
      SELECT  frt.responsibility_name resp_name --職責名
      INTO    lv_responsibility_name
      FROM    fnd_responsibility_tl frt
      WHERE   frt.responsibility_id = lv_resp_id
      AND     frt.application_id = lv_resp_appl_id
      AND     frt.language = cv_language
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN --職責名を取得できなかった場合
        RAISE no_data_expt2;
    END;
    --
    lv_message  := FND_PROFILE.VALUE(cv_xxccp1_request_id) || cv_colon||lv_request_id;
    lv_message2 := FND_PROFILE.VALUE(cv_xxccp1_concurrent_name) ||cv_colon||
                   concurrent_cur_v.program_name;
    lv_message3 := FND_PROFILE.VALUE(cv_xxccp1_user_name) || cv_colon||lv_user_name;
    lv_message4 := FND_PROFILE.VALUE(cv_xxccp1_resp_name) || cv_colon||lv_responsibility_name;
    lv_message5 := FND_PROFILE.VALUE(cv_xxccp1_actual_start_date) || cv_colon||
                   concurrent_cur_v.start_date;
    --
    IF (iv_which = 'OUTPUT') THEN
      fnd_file.put_line(fnd_file.output,lv_message);
      fnd_file.put_line(fnd_file.output,lv_message2);
      fnd_file.put_line(fnd_file.output,lv_message3);
      fnd_file.put_line(fnd_file.output,lv_message4);
      fnd_file.put_line(fnd_file.output,lv_message5);
      fnd_file.put_line(fnd_file.output,cv_null_line);
    ELSIF (iv_which = 'LOG') THEN
      fnd_file.put_line(fnd_file.log,lv_message);
      fnd_file.put_line(fnd_file.log,lv_message2);
      fnd_file.put_line(fnd_file.log,lv_message3);
      fnd_file.put_line(fnd_file.log,lv_message4);
      fnd_file.put_line(fnd_file.log,lv_message5);
      fnd_file.put_line(fnd_file.log,cv_null_line);
    ELSE
      RAISE iv_which_expt;
    END IF;
    --
    ov_retcode := xxccp_common_pkg.set_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    --
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN no_data_expt  THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name1
                                            );
--
    WHEN no_data_expt2 THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name2
                                            );
--
    WHEN iv_which_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name7
                                            );
--
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := SUBSTR(cv_pkg_name||cv_period||cv_prg_name || SQLERRM , 1, 5000);
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name3
                                            );
--
--###################################  固定部 END   #########################################
--
  END put_log_header;
--
  /**********************************************************************************
   * Function Name    : chk_alphabet_number
   * Description      : 半角英数字(記号可)チェック ファンクション
   ***********************************************************************************/
--
  FUNCTION chk_alphabet_number(
                               iv_check_char IN VARCHAR2 --チェック対象文字列
                              )
    RETURN BOOLEAN               -- TRUE,FALSE,NULL
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_alphabet_number'; -- プログラム名
    cv_exclamation CONSTANT VARCHAR2(1) := '!';                     -- 感嘆符
    cv_tilde       CONSTANT VARCHAR2(1) := '~';                     -- チルダ
--
    -- *** ローカル変数 ***
    lv_check_char VARCHAR2(1);
--
  BEGIN
  --
--
    -- NULLチェック
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    END IF;
--
    -- 全角文字が入っているかどうかのチェック
    IF (LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
--
    -- 文字を一つづつチェック
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      IF (NOT ((lv_check_char >= cv_exclamation) AND (lv_check_char <= cv_tilde))) THEN
        RETURN FALSE;
      END IF;
    END LOOP;
--
    RETURN TRUE;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      RETURN FALSE;
--
  END chk_alphabet_number;
--
  /**********************************************************************************
   * Function Name    : chk_tel_format
   * Description      : 半角数字 ハイフンチェック ファンクション
   ***********************************************************************************/
--
  FUNCTION chk_tel_format(
                          iv_check_char VARCHAR2 --チェック対象文字列
                         )
    RETURN BOOLEAN               -- TRUE,FALSE,NULL
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_tel_format'; -- プログラム名
    cv_hyphen     CONSTANT VARCHAR2(1)   := '-';              -- ハイフン
--
    -- *** ローカル変数 ***
    lv_check_string    VARCHAR2(1000);   -- 変換後のチェック対象文字列
--
  BEGIN
--
    -- NULLチェック
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    END IF;
--
    --文字列がハイフンのみの場合TRUEを返却
    IF REPLACE(iv_check_char,cv_hyphen,'') IS NULL THEN
      RETURN TRUE;
    END IF;
--
    -- ハイフンのみ削除して、chk_numberを実行する
    RETURN xxccp_common_pkg.chk_number(iv_check_char => REPLACE(iv_check_char
                                                               ,cv_hyphen
                                                               ,''
                                                               )
                                      );
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      RETURN FALSE;
--
  END chk_tel_format;
--
--
  /**********************************************************************************
   * Function  Name   : chg_double_to_single_byte_sub
   * Description      : 全角カタカナ英数字半角変換プロシージャ（変換部）Internal
   ***********************************************************************************/
--
  FUNCTION chg_double_to_single_byte_sub(
                                     iv_check_char IN  VARCHAR2 --変換対象文字
                                    )
    RETURN VARCHAR2     -- 変換結果文字
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'chg_double_to_single_byte_sub';
    cv_dakuten           CONSTANT VARCHAR2(1)   := CHR(222);
    cv_handakuten        CONSTANT VARCHAR2(1)   := CHR(223);
    cn_string_code1_s    CONSTANT NUMBER        := 33600; --全角ァ（の文字コード）
    cn_string_code1_e    CONSTANT NUMBER        := 33609; --全角オ
    cn_string_code1_dif  CONSTANT NUMBER        := 33423; --変換前と変換後の文字コードの差（以下省略）
    cn_string_code2_s    CONSTANT NUMBER        := 33610; --全角カ
    cn_string_code2_e    CONSTANT NUMBER        := 33633; --全角ヂ
    cn_string_code2_dif  CONSTANT NUMBER        := 33428;
    cn_string_code3_s    CONSTANT NUMBER        := 33637; --全角テ
    cn_string_code3_e    CONSTANT NUMBER        := 33640; --全角ド
    cn_string_code3_dif  CONSTANT NUMBER        := 33442;
    cn_string_code4_s    CONSTANT NUMBER        := 33641; --全角ナ
    cn_string_code4_e    CONSTANT NUMBER        := 33645; --全角ノ
    cn_string_code4_dif  CONSTANT NUMBER        := 33444;
    cn_string_code5_s    CONSTANT NUMBER        := 33646; --全角ハ
    cn_string_code5_e    CONSTANT NUMBER        := 33660; --全角ポ
    cn_string_code5_dif  CONSTANT NUMBER        := 33444;
    cn_string_code6_s    CONSTANT NUMBER        := 167;   --全角ァ
    cn_string_code6_e    CONSTANT NUMBER        := 171;   --全角ォ
    cn_string_code6_dif  CONSTANT NUMBER        := 10;    
    cn_string_code7_s    CONSTANT NUMBER        := 33661; --全角マ
    cn_string_code7_e    CONSTANT NUMBER        := 33666; --全角モ
    cn_string_code7_dif  CONSTANT NUMBER        := 33454;
    cn_string_code8_s    CONSTANT NUMBER        := 33667; --全角ャ
    cn_string_code8_e    CONSTANT NUMBER        := 33672; --全角ヨ
    cn_string_code8_dif  CONSTANT NUMBER        := 33455;
    cn_string_code9_s    CONSTANT NUMBER        := 33673; --全角ラ
    cn_string_code9_e    CONSTANT NUMBER        := 33677; --全角ロ
    cn_string_code9_dif  CONSTANT NUMBER        := 33458;
    cn_string_code10_s   CONSTANT NUMBER        := 33089; --全角、
    cn_string_code10_e   CONSTANT NUMBER        := 33092; --全角．
    cn_string_code10_dif CONSTANT NUMBER        := 33043;
    cn_string_code11_s   CONSTANT NUMBER        := 33376; --全角Ａ
    cn_string_code11_e   CONSTANT NUMBER        := 33401; --全角Ｚ
    cn_string_code12_s   CONSTANT NUMBER        := 33409; --全角ａ
    cn_string_code12_e   CONSTANT NUMBER        := 33434; --全角ｚ
    cn_string_code13_s   CONSTANT NUMBER        := 33359; --全角０
    cn_string_code13_e   CONSTANT NUMBER        := 33368; --全角９
    cn_string_code14_b   CONSTANT NUMBER        := 33680; --全角ヰ
    cn_string_code14_a   CONSTANT NUMBER        := 178;   --半角ｲ
    cn_string_code15_b   CONSTANT NUMBER        := 33681; --全角ヱ
    cn_string_code15_a   CONSTANT NUMBER        := 180;   --半角ｴ
    cn_string_code16_b   CONSTANT NUMBER        := 33682; --全角ヲ
    cn_string_code16_a   CONSTANT NUMBER        := 181;   --半角ｵ
    cn_string_code17_b   CONSTANT NUMBER        := 33685; --全角ヵ
    cn_string_code17_a   CONSTANT NUMBER        := 182;   --半角ｶ
    cn_string_code18_b1  CONSTANT NUMBER        := 33634; --全角ッ
    cn_string_code18_b2  CONSTANT NUMBER        := 33635; --全角ツ
    cn_string_code18_b3  CONSTANT NUMBER        := 175;   --半角ｯ
    cn_string_code18_a   CONSTANT NUMBER        := 194;   --半角ﾂ
    cn_string_code19_b   CONSTANT NUMBER        := 33636; --全角ヅ
    cn_string_code19_a   CONSTANT NUMBER        := 194;   --半角ﾂ
    cn_string_code20_b1  CONSTANT NUMBER        := 33678; --全角ヮ
    cn_string_code20_b2  CONSTANT NUMBER        := 33679; --全角ワ
    cn_string_code20_a   CONSTANT NUMBER        := 220;   --半角ﾜ
    cn_string_code21_b   CONSTANT NUMBER        := 33683; --全角ン
    cn_string_code21_a   CONSTANT NUMBER        := 221;   --半角ﾝ
    cn_string_code22_b   CONSTANT NUMBER        := 33684; --全角ヴ
    cn_string_code22_a   CONSTANT NUMBER        := 179;   --半角ｳ
    cn_string_code23_b   CONSTANT NUMBER        := 33098; --全角゛
    cn_string_code23_a   CONSTANT NUMBER        := 222;   --半角ﾞ
    cn_string_code24_b   CONSTANT NUMBER        := 33099; --全角゜
    cn_string_code24_a   CONSTANT NUMBER        := 223;   --半角ﾟ
    cn_string_code25_b1  CONSTANT NUMBER        := 33115; --全角ー
    cn_string_code25_b2  CONSTANT NUMBER        := 33116; --全角―
    cn_string_code25_b3  CONSTANT NUMBER        := 176;   --半角ｰ
    cn_string_code25_b4  CONSTANT NUMBER        := 33117; --全角‐
    cn_string_code25_b5  CONSTANT NUMBER        := 33120; --全角～
    cn_string_code25_b6  CONSTANT NUMBER        := 33104; --全角￣
    cn_string_code25_a   CONSTANT NUMBER        := 45;    --半角-
    cn_string_code26_b1  CONSTANT NUMBER        := 164;   --半角､
    cn_string_code26_b2  CONSTANT NUMBER        := 44;    --半角,
    cn_string_code26_b3  CONSTANT NUMBER        := 161;   --半角｡
    cn_string_code26_a   CONSTANT NUMBER        := 46;    --半角.
    cn_string_code27_s   CONSTANT NUMBER        := 97;    --半角a
    cn_string_code27_e   CONSTANT NUMBER        := 122;   --半角z
    cn_string_code28     CONSTANT NUMBER        := 48;    --半角0
    cn_string_code29     CONSTANT NUMBER        := 57;    --半角9
    cn_string_code30     CONSTANT NUMBER        := 65;    --半角A
    cn_string_code31     CONSTANT NUMBER        := 90;    --半角Z
    cn_string_code32     CONSTANT NUMBER        := 177;   --半角ｱ
    cn_string_code33_b   CONSTANT NUMBER        := 33686;  --半角ｹ
    cn_string_code33_a   CONSTANT NUMBER        := 185;   --半角ｹ
                                                                                -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_converted_char VARCHAR2(2);  -- 変換結果文字
    ln_count          NUMBER;
    ln_count2         NUMBER;
    ln_loop_count     NUMBER;
--
  BEGIN
--
    IF (iv_check_char IN (' ','(',')','-','.')
      OR iv_check_char BETWEEN CHR(cn_string_code28) AND CHR(cn_string_code29)
      OR iv_check_char BETWEEN CHR(cn_string_code30) AND CHR(cn_string_code31)
      OR iv_check_char BETWEEN CHR(cn_string_code32) AND CHR(cn_string_code24_a))
    THEN
      lv_converted_char := iv_check_char;
    --全角ア(ァ)からオ(ォ)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code1_s AND cn_string_code1_e)
    THEN
      ln_count      := cn_string_code1_s;
      ln_count2     := cn_string_code1_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --全角カ(ガ)からチ(ヂ)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code2_s AND cn_string_code2_e)
    THEN
      ln_count      := cn_string_code2_s;
      ln_count2     := cn_string_code2_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          IF MOD(ln_loop_count,2) = 1 THEN
            RETURN CHR(ln_count - ln_count2)||cv_dakuten;
          END IF;
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --全角テ(デ)からト(ド)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code3_s AND cn_string_code3_e)
    THEN
      ln_count      := cn_string_code3_s;
      ln_count2     := cn_string_code3_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          IF MOD(ln_loop_count,2) = 1 THEN
            RETURN CHR(ln_count - ln_count2)||cv_dakuten;
          END IF;
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --全角ナからノ
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code4_s AND cn_string_code4_e)
    THEN
      ln_count      := cn_string_code4_s;
      ln_count2     := cn_string_code4_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        ln_count      := ln_count +1;
      END LOOP;
    --全角ハ(バ)(パ)からホ(ボ)(ポ)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code5_s AND cn_string_code5_e)
      THEN
        ln_count      := cn_string_code5_s;
        ln_count2     := cn_string_code5_dif;
        ln_loop_count := 0;
        LOOP
          IF ASCII(iv_check_char) = ln_count THEN
            IF (ln_loop_count IN (1,4,7,10,13)) THEN
              RETURN CHR(ln_count - ln_count2)||cv_dakuten;
            ELSIF (ln_loop_count IN (2,5,8,11,14)) THEN
              RETURN CHR(ln_count - ln_count2)||cv_handakuten;
            END IF;
            RETURN CHR(ln_count - ln_count2);
          END IF;
          ln_count      := ln_count +1;
          ln_loop_count := ln_loop_count + 1;
          IF (ln_loop_count NOT IN(3,6,9,12,15)) THEN
          ln_count2 := ln_count2 +1;
          END IF;
        END LOOP;
    --半角ｧからｫ
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code6_s AND cn_string_code6_e)
    THEN
      ln_count      := cn_string_code6_s;
      ln_count2     := cn_string_code6_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count + ln_count2);
        END IF;
        ln_count      := ln_count +1;
      END LOOP;
    --全角マからモ
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code7_s AND cn_string_code7_e)
    THEN
      ln_count      := cn_string_code7_s;
      ln_count2     := cn_string_code7_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF (ln_loop_count = 1) THEN
          ln_count      := ln_count +1;
          ln_count2     := ln_count2 +1;
        END IF;
          ln_count      := ln_count +1;
          ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --全角ヤ(ャ)からヨ(ョ)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code8_s AND cn_string_code8_e)
    THEN
      ln_count      := cn_string_code8_s;
      ln_count2     := cn_string_code8_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --全角ラからロ
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code9_s AND cn_string_code9_e)
    THEN
      ln_count      := cn_string_code9_s;
      ln_count2     := cn_string_code9_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        ln_count      := ln_count +1;
      END LOOP;
    --全角「、」から「．」
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code10_s AND cn_string_code10_e)
    THEN
      ln_count      := cn_string_code10_s;
      ln_count2     := cn_string_code10_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        ln_count      := ln_count + 1;
        ln_count2     := ln_count2 + 1;
      END LOOP;
    --全角ＡからＺ
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code10_s AND cn_string_code10_e)
      THEN
        RETURN TO_SINGLE_BYTE(iv_check_char);
    --全角ａからｚ
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code12_s AND cn_string_code12_e)
      THEN
        lv_converted_char := TO_SINGLE_BYTE(iv_check_char);
        RETURN UPPER(lv_converted_char);
    --半角aからz
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code27_s AND cn_string_code27_e)
      THEN
        RETURN UPPER(iv_check_char);
    --全角０から９
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code13_s AND cn_string_code13_e) THEN
      RETURN TO_SINGLE_BYTE(iv_check_char);
    --その他変換文字
    ELSIF(ASCII(iv_check_char) = cn_string_code14_b) THEN --ヰ
      lv_converted_char := CHR(cn_string_code14_a);          --ｲ
    ELSIF(ASCII(iv_check_char) = cn_string_code15_b) THEN --ヱ
      lv_converted_char := CHR(cn_string_code15_a);          --ｴ
    ELSIF(ASCII(iv_check_char) = cn_string_code16_b) THEN --ヲ
      lv_converted_char := CHR(cn_string_code16_a);          --ｵ
    ELSIF(ASCII(iv_check_char) = cn_string_code17_b) THEN --ヵ
      lv_converted_char := CHR(cn_string_code17_a);          --ｶ
    ELSIF(ASCII(iv_check_char) = cn_string_code33_b) THEN --ヶ
      lv_converted_char := CHR(cn_string_code33_a);          --ｹ
    ELSIF(ASCII(iv_check_char) = cn_string_code18_b1)      --ッ
      OR (ASCII(iv_check_char) = cn_string_code18_b2)      --ツ
      OR (ASCII(iv_check_char) = cn_string_code18_b3)      --ｯ
    THEN
      lv_converted_char := CHR(cn_string_code18_a);          --ﾂ
    ELSIF(ASCII(iv_check_char) = cn_string_code19_b) THEN --ヅ
      lv_converted_char := CHR(cn_string_code19_a)||cv_dakuten; --ﾂﾞ
    ELSIF(ASCII(iv_check_char) = cn_string_code20_b1)      --ヮ
      OR (ASCII(iv_check_char) = cn_string_code20_b2)      --ワ
    THEN
      lv_converted_char := CHR(cn_string_code20_a);          --ﾜ
    ELSIF(ASCII(iv_check_char) = cn_string_code21_b) THEN --ン
      lv_converted_char := CHR(cn_string_code21_a);          --ﾝ
    ELSIF(ASCII(iv_check_char) = cn_string_code22_b) THEN --ヴ
      lv_converted_char := CHR(cn_string_code22_a)||cv_dakuten; --ｳﾞ
    ELSIF(ASCII(iv_check_char) = cn_string_code23_b) THEN --「゛」
      lv_converted_char := CHR(cn_string_code23_a);          --「ﾞ」
    ELSIF(ASCII(iv_check_char) = cn_string_code24_b) THEN --「゜」
      lv_converted_char := CHR(cn_string_code24_a);          --「ﾟ」
    ELSIF(ASCII(iv_check_char) = cn_string_code25_b1)     --「ー」
      OR (ASCII(iv_check_char) = cn_string_code25_b2)     --「―」
      OR (ASCII(iv_check_char) = cn_string_code25_b3)     --「ｰ」
      OR (ASCII(iv_check_char) = cn_string_code25_b4)     --「‐」
      OR (ASCII(iv_check_char) = cn_string_code25_b5)     --「～」
      OR (ASCII(iv_check_char) = cn_string_code25_b6)     --「￣」
    THEN
      lv_converted_char := CHR(cn_string_code25_a);          --「-」
    ELSIF(ASCII(iv_check_char) = cn_string_code26_b1)     --「､」
      OR (ASCII(iv_check_char) = cn_string_code26_b2)     --「,」
      OR (ASCII(iv_check_char) = cn_string_code26_b3)     --「｡」
    THEN
      lv_converted_char := CHR(cn_string_code26_a);          --「.」
    ELSE
      lv_converted_char := TO_SINGLE_BYTE(iv_check_char);
    END IF;
--
    RETURN lv_converted_char;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
--
  END chg_double_to_single_byte_sub;
--
  /**********************************************************************************
   * Function  Name   : chg_double_to_single_byte
   * Description      : 全角カタカナ英数字半角変換プロシージャ（呼び出し部）
   ***********************************************************************************/
--
  FUNCTION chg_double_to_single_byte(
                                     iv_check_char IN  VARCHAR2 --変換対象文字列
                                    )
    RETURN VARCHAR2     -- 変換結果文字列
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chg_double_to_single_byte';
                                                                                -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_check_char   VARCHAR2(2);
    lv_checked_char VARCHAR2(2);
    lv_cvt_string   VARCHAR2(1000);
--
  BEGIN
--
    --NULLチェック
    IF (iv_check_char IS NULL) THEN
      RETURN iv_check_char;
    END IF;
--
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
       lv_check_char := SUBSTR(iv_check_char
                              ,ln_position
                              ,1
                              );
       lv_checked_char := xxccp_common_pkg.chg_double_to_single_byte_sub(lv_check_char);
       lv_cvt_string := lv_cvt_string||lv_checked_char;
    END LOOP;
  RETURN lv_cvt_string;
--
  EXCEPTION
--
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END chg_double_to_single_byte;
--
  --
  /**********************************************************************************
   * Function  Name   : chk_double_byte_kana
   * Description      : 全角カタカナチェック
   ***********************************************************************************/
--
  FUNCTION chk_double_byte_kana(
                                iv_check_char IN  VARCHAR2 --チェック対象文字列
                               )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_double_byte_kana'; -- プログラム名
    cn_string_code1 CONSTANT NUMBER        := 33600; --全角ァ
    cn_string_code2 CONSTANT NUMBER        := 33684; --全角ヴ
    cn_string_code3 CONSTANT NUMBER        := 33685; --全角ヵ
    cn_string_code4 CONSTANT NUMBER        := 33686; --全角ヶ
    cn_string_code5 CONSTANT NUMBER        := 33115; --全角ー
    cn_string_code6 CONSTANT NUMBER        := 33129; --全角（
    cn_string_code7 CONSTANT NUMBER        := 33130; --全角）
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_check_char   VARCHAR2(2);       --文字格納用
--
  BEGIN
    --NULLチェック
    IF(iv_check_char IS NULL) THEN
      RETURN NULL;
    --半角文字が存在する場合、FALSE
    ELSIF(LENGTH(iv_check_char) * 2 <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
-- 2009/02/23 K.Kitagawa START
    --LOOP処理開始
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
    --文字を一つづつ取り出す
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      --全角カタカナ、ァ、ヵ、（、）、ーではない場合、FALSEを返す
      IF (NOT(
              ((lv_check_char >= CHR(cn_string_code1)) AND (lv_check_char <= CHR(cn_string_code2)))
               OR
              ((lv_check_char = CHR(cn_string_code3)) OR (lv_check_char = CHR(cn_string_code4)))
               OR
              (lv_check_char IN (CHR(cn_string_code5),CHR(cn_string_code6),CHR(cn_string_code7)))
              ))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
    --上記に合致しない場合、TRUEを返却
    RETURN TRUE;
-- 2009/02/23 K.Kitagawa END
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
--
  END chk_double_byte_kana;
  --
  /**********************************************************************************
   * Function  Name   : chk_single_byte_kana
   * Description      : 半角カタカナチェック
   ***********************************************************************************/
--
  FUNCTION chk_single_byte_kana(
                                iv_check_char IN  VARCHAR2 --チェック対象文字列
                               )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_single_byte_kana';  -- プログラム名
    cn_string_code1 CONSTANT NUMBER        := 166; --半角ｦ
    cn_string_code2 CONSTANT NUMBER        := 175; --半角ｯ
    cn_string_code3 CONSTANT NUMBER        := 177; --半角ｱ
    cn_string_code4 CONSTANT NUMBER        := 221; --半角ﾝ
--  2009/02/25 Kazuhisa.Baba START
    cn_string_code5 CONSTANT NUMBER        := 222; --半角ﾞ
    cn_string_code6 CONSTANT NUMBER        := 223; --半角ﾟ
    cn_string_code7 CONSTANT NUMBER        := 176; --半角ｰ
--  2009/02/25 Kazuhisa.Baba END
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_check_char   VARCHAR2(1);       --文字格納用
--
  BEGIN
    --NULLチェック
    IF(iv_check_char IS NULL) THEN
      RETURN NULL;
    --半角チェック
    ELSIF(LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
--
-- 2009/02/23 K.Kitagawa START
    --LOOP処理開始
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      -- 文字を一つづつ取り出す
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
--
      --半角カタカナではない場合、FALSEを返す
      IF  (NOT(
              ((lv_check_char >= CHR(cn_string_code1)) AND (lv_check_char <= CHR(cn_string_code2)))
              OR 
              ((lv_check_char >= CHR(cn_string_code3)) AND (lv_check_char <= CHR(cn_string_code4)))
              OR 
              (lv_check_char IN (CHR(cn_string_code5),CHR(cn_string_code6),CHR(cn_string_code7)))
           ))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
    --上記に合致しない場合、TRUEを返却
    RETURN TRUE;
-- 2009/02/23 K.Kitagawa END
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
--
  END chk_single_byte_kana;
  --
  --
  /**********************************************************************************
   * Function  Name   : get_msg
   * Description      : メッセージ取得
   ***********************************************************************************/
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
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msg';
--
  -- *** ローカル変数 ***
    lv_start_search        NUMBER := 1;
    lv_start_pos           NUMBER;
    lv_end_pos             NUMBER;
    lv_token_end           NUMBER;
    lv_token_name          VARCHAR2(1000);
    lv_token_value         VARCHAR2(2000);
    lv_token_length        NUMBER;
    lv_token_value_length  NUMBER;
    ln_cnt                 NUMBER;
    lv_stringpplication    VARCHAR2(40);
--
  BEGIN
--
    -- スタックにメッセージをセット
    FND_MESSAGE.SET_NAME(
                         iv_application
                        ,iv_name
                        );
    -- スタックにトークンをセット
    IF (iv_token_name1 IS NOT NULL)
    THEN
      --カウント変数初期化
      ln_cnt := 0;
      <<TOKEN_SET>>
      LOOP
        ln_cnt := ln_cnt + 1;
        -- トークンの値が2000バイトを超える場合、切捨て
        IF (ln_cnt = 1) THEN
          lv_token_name := iv_token_name1;
          lv_token_value := SUBSTRB(iv_token_value1,1,2000);
        ELSIF (ln_cnt = 2) THEN
          lv_token_name := iv_token_name2;
          lv_token_value := SUBSTRB(iv_token_value2,1,2000);
        ELSIF (ln_cnt = 3) THEN
          lv_token_name := iv_token_name3;
          lv_token_value := SUBSTRB(iv_token_value3,1,2000);
        ELSIF (ln_cnt = 4) THEN
          lv_token_name := iv_token_name4;
          lv_token_value := SUBSTRB(iv_token_value4,1,2000);
        ELSIF (ln_cnt = 5) THEN
          lv_token_name := iv_token_name5;
          lv_token_value := SUBSTRB(iv_token_value5,1,2000);
        ELSIF (ln_cnt = 6) THEN
          lv_token_name := iv_token_name6;
          lv_token_value := SUBSTRB(iv_token_value6,1,2000);
        ELSIF (ln_cnt = 7) THEN
          lv_token_name := iv_token_name7;
          lv_token_value := SUBSTRB(iv_token_value7,1,2000);
        ELSIF (ln_cnt = 8) THEN
          lv_token_name := iv_token_name8;
          lv_token_value := SUBSTRB(iv_token_value8,1,2000);
        ELSIF (ln_cnt = 9) THEN
          lv_token_name := iv_token_name9;
          lv_token_value := SUBSTRB(iv_token_value9,1,2000);
        ELSIF (ln_cnt = 10) THEN
          lv_token_name := iv_token_name10;
          lv_token_value := SUBSTRB(iv_token_value10,1,2000);
        END IF;
        EXIT WHEN (lv_token_name IS NULL)
               OR (ln_cnt > 10);
        IF (LENGTHB(lv_token_value) > 30) THEN
          FND_MESSAGE.SET_TOKEN(
                                lv_token_name
                               ,lv_token_value
                               ,FALSE
                               );
        ELSE
          FND_MESSAGE.SET_TOKEN(
                                lv_token_name
                               ,lv_token_value
                               ,TRUE
                               );
        END IF;
      END LOOP TOKEN_SET;
    END IF;
    -- スタックの内容を取得
    RETURN FND_MESSAGE.GET(iv_name);
--
  EXCEPTION
--
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_msg;
  --
  --
  /**********************************************************************************
   * Function  Name   : char_delim_partition
   * Description      : デリミタ文字分割関数
   ***********************************************************************************/
--
  FUNCTION char_delim_partition(iv_char     IN VARCHAR2
                               ,iv_delim    IN VARCHAR2
                               ,in_part_num IN NUMBER
                               )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'char_delim_partition';
    cv_space      CONSTANT VARCHAR2(1) := ' ';
--
  BEGIN
--
    --NULLチェック
    IF  ((iv_char      IS NULL)
      OR (iv_delim     IS NULL)
      OR (in_part_num  IS NULL)) THEN
      RETURN NULL;
    END IF;
--
   --小数点チェック
   IF (INSTR(TO_CHAR(in_part_num),cv_period) > 0) THEN
     RETURN NULL;
   END IF;
--
    -- 返却対象INDEX範囲チェック
    IF   (in_part_num <= 0) 
      OR (LENGTH(REPLACE(iv_char,iv_delim,cv_space))
        - (LENGTH(REPLACE(iv_char,iv_delim,''))) + 2 <= in_part_num)
    THEN
      RETURN NULL;
    END IF;
--
  --デリミタ文字チェック
  IF INSTR(iv_char,iv_delim,1,1) = 0 THEN
    IF in_part_num = 1 THEN
      RETURN iv_char;
    ELSE
      RETURN NULL;
    END IF;
  ELSIF in_part_num = 1 THEN
    RETURN SUBSTR(iv_char,1,INSTR(iv_char,iv_delim,1,in_part_num ) - 1);
  ELSIF INSTR(iv_char,iv_delim,1,in_part_num) = 0 THEN
    --改行チェック
    IF INSTR(iv_char,CHR(10),LENGTH(iv_char),1) = LENGTH(iv_char) THEN
      RETURN SUBSTR(iv_char,INSTR(iv_char,iv_delim,1,in_part_num - 1) + LENGTH(iv_delim)
                           ,LENGTH(iv_char)
                           - INSTR(iv_char,iv_delim,1,in_part_num - 1) - LENGTH(iv_delim));
    ELSE
      RETURN SUBSTR(iv_char,INSTR(iv_char,iv_delim,1,in_part_num - 1) + LENGTH(iv_delim));
    END IF;
  ELSE
    RETURN SUBSTR(iv_char,INSTR(iv_char,iv_delim,1,in_part_num - 1) + LENGTH(iv_delim)
                         ,INSTR(iv_char,iv_delim ,1,in_part_num) 
                         - INSTR(iv_char,iv_delim ,1,in_part_num - 1) - LENGTH(iv_delim));
  END IF;
--
  EXCEPTION
--
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
--
  END char_delim_partition;
--
  /**********************************************************************************
   * Procedure Name   : chk_single_byte
   * Description      : 半角チェック
   **********************************************************************************/
  --
  FUNCTION chk_single_byte(
    iv_chk_char IN VARCHAR2             --チェック対象文字列
  )
  RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_single_byte'; -- プログラム名
--
  BEGIN
    --NULLチェック
    IF (iv_chk_char IS NULL) THEN
      RETURN NULL;
    --半角チェック
    ELSIF (LENGTH(iv_chk_char) <> LENGTHB(iv_chk_char)) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      RETURN FALSE;
  END chk_single_byte;
--
--
END XXCCP_COMMON_PKG;
/
