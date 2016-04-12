create or replace PACKAGE BODY apps.xxccp_common_pkg2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_common_pkg2(body)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.9
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_process_date          F    DATE   業務処理日取得関数
 *  get_working_day           F    DATE   営業日日付取得関数
 *  chk_moji                  F    BOOL   禁則文字チェック
 *  blob_to_varchar2          P           BLOBデータ変換
 *  upload_item_check         P           項目チェック
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-24    1.0  Naoki.Watanabe   新規作成
 *  2008-11-11    1.1  Yutaka.Kuboshima 禁則文字チェック,BLOBデータ変換,項目チェック関数追加
 *  2009-01-30    1.2  Yutaka.Kuboshima 禁則文字チェックの半角スペース,アンダーバーを
 *                                      禁則文字から除外
 *  2009-02-11    1.3  K.Kanada         [業務処理日取得関数]テスト実施用にプロファイル値で
 *                                      業務日付を指定可能なように変更
 *  2009-05-01    1.4  Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *  2009-05-11    1.5  Masayuki.Sano    障害番号T1_0376対応(ダミー日付の日付変換時、書式指定)
 *  2009-06-25    1.6  Yuuki.Nakamura   障害番号T1_1425対応(文字化けチェック削除)
 *  2009-08-17    1.7  Yutaka.Kuboshima 障害番号0000818対応(BLOB変換関数修正)
 *  2016-02-05    1.8  K.Kiriu          E_本稼動_13456対応(禁則文字チェック修正)
 *  2016-04-04    1.9  K.Kiriu          E_本稼動_13456追加対応(禁則文字チェック修正)
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル変数
  -- ===============================
  gv_msg_part VARCHAR2(100) := ' : ';
  gv_msg_cont CONSTANT VARCHAR2(3) := '.';
--
  -- ===============================
  -- 共通例外
  -- ===============================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCCP_COMMON_PKG2';  -- パッケージ名
--
  gv_cnst_msg_kbn        CONSTANT VARCHAR2(5)   := 'XXCCP';
--
  gv_cnst_msg_com3_001   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10111';  -- ﾛｯｸｴﾗｰ
  gv_cnst_msg_com3_002   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10112';  -- 対象データなし
-- 2009/08/17 Ver1.7 add start by Yutaka.Kuboshima
  gv_cnst_msg_com3_003   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10122';  -- 文字列変換不可エラー
-- 2009/08/17 Ver1.7 add end by Yutaka.Kuboshima
  -- 項目チェック
  gv_cnst_msg_com3_para1 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10117';  -- パラメータエラー(項目名称)
  gv_cnst_msg_com3_para2 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10118';  -- パラメータエラー(必須フラグ)
  gv_cnst_msg_com3_para3 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10119';  -- パラメータエラー(項目属性)
  gv_cnst_msg_com3_para4 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10120';  -- パラメータエラー(項目の長さ)
  gv_cnst_msg_com3_para5 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10121';  -- パラメータエラー(項目の長さ)
  gv_cnst_msg_com3_date  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10113';  -- DATE型チェックエラーメッセージ
  gv_cnst_msg_com3_numb  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10114';  -- NUMBER型チェックエラーメッセージ
  gv_cnst_msg_com3_size  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10115';  -- サイズチェックエラーメッセージ
  gv_cnst_msg_com3_null  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10116';  -- 必須チェックエラーメッセージ
--
  gv_cnst_tkn_item       CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value      CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_tkn_value1     CONSTANT VARCHAR2(15)  := 'VALUE1';
  gv_cnst_tkn_value2     CONSTANT VARCHAR2(15)  := 'VALUE2';
--
  gv_cnst_period         CONSTANT VARCHAR2(1)   := '.';                 -- ピリオド
  gv_cnst_err_msg_space  CONSTANT VARCHAR2(6)   := '      ';            -- スペース
--
   /**********************************************************************************
   * Function Name    : get_process_date
   * Description      : 業務日付取得関数
   ***********************************************************************************/
  FUNCTION get_process_date
    RETURN DATE
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_process_date';    -- プログラム名
    cv_profile_name  CONSTANT VARCHAR2(100) := 'XXCCP1_DUMMY_PROCESS_DATE';  -- プロファイル値
--
    --**ローカル変数**
    ld_prdate     DATE;           -- 業務日付
    lv_profile    VARCHAR2(100);  -- プロファイル値
  BEGIN
    lv_profile := FND_PROFILE.VALUE(cv_profile_name);
    IF (lv_profile IS NULL) THEN
      SELECT process_date
      INTO   ld_prdate
      FROM   XXCCP_PROCESS_DATES
      ;
    ELSE
-- 2009-05-11 UPDATE Ver.1.5 By Masayuki.Sano Start
--      ld_prdate := to_date(lv_profile) ;
      ld_prdate := TO_DATE(lv_profile, 'DD-MM-YYYY');
-- 2009-05-11 UPDATE Ver.1.5 By Masayuki.Sano End
    END IF;
    RETURN TRUNC(ld_prdate,'DD');
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR
--        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      RETURN NULL;
  END get_process_date;
--

  /**********************************************************************************
   * Function  Name   : get_working_day
   * Description      : 営業日日付取得関数
   ***********************************************************************************/
  FUNCTION get_working_day(
              id_date          IN DATE
             ,in_working_day   IN NUMBER
             ,iv_calendar_code IN VARCHAR2 DEFAULT NULL
           )
    RETURN DATE
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_working_day'; -- プログラム名
    cv_profile_name CONSTANT VARCHAR2(100) := 'XXCCP1_WORKING_CALENDAR';
    --
    --**ローカル変数**
    ld_date      DATE;
    ln_count     NUMBER;
    ln_seq       NUMBER;
    lv_profile   VARCHAR2(100);
  BEGIN
    IF (iv_calendar_code IS NULL) THEN
    --プロファイル取得
      lv_profile := FND_PROFILE.VALUE(cv_profile_name);
    ELSE
      lv_profile := iv_calendar_code;
    END IF;
    --
    IF (lv_profile IS NULL) THEN
      RETURN NULL;
    END IF;
    ld_date    := TRUNC(id_date,'DD');
    --パラメータ：営業日数が0の場合
    IF (in_working_day = 0) THEN
      BEGIN
        --
        SELECT bcd.seq_num seq_num
        INTO   ln_seq
        FROM   bom_calendar_dates bcd
        WHERE  bcd.calendar_code = lv_profile
        AND    bcd.calendar_date = ld_date;
        --SEQ_NUMがNULLの場合
        IF (ln_seq IS NULL) THEN
          RETURN NULL;
        END IF;
        RETURN ld_date;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      END;
    END IF;
    --前処理
    ln_count   := 0;
    --ループ
    WHILE ABS(in_working_day) > ln_count LOOP
      --パラメータ：営業日数が正の数の場合
      IF (in_working_day > 0) THEN
        ld_date := ld_date + 1;
      --パラメータ：営業日数が負の数の場合
      ELSIF (in_working_day < 0) THEN
        ld_date := ld_date - 1;
      END IF;
      BEGIN
        SELECT bcd.seq_num       seq_num
        INTO   ln_seq
        FROM   bom_calendar_dates bcd
        WHERE  bcd.calendar_code = lv_profile
        AND    bcd.calendar_date = ld_date
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      END;
      --SEQ_NUMがNULLでない場合
      IF (ln_seq IS NOT NULL) THEN
        ln_count := ln_count + 1;
      END IF;
    END LOOP;
    RETURN ld_date;
--
  EXCEPTION
--
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_working_day;
  --
  /**********************************************************************************
   * Function  Name   : chk_moji
   * Description      : 禁則文字チェック
   ***********************************************************************************/
  FUNCTION chk_moji(
    iv_check_char  IN VARCHAR2,
    iv_check_scope IN VARCHAR2)
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100) := 'xxccp_common_pkg2.chk_moji'; -- プログラム名
  --チェック範囲
    cv_chk_scope_machine     CONSTANT VARCHAR2(100) := 'VENDING_MACHINE_SYSTEM';     -- 自販機システムチェック
    cv_chk_scope_garbled     CONSTANT VARCHAR2(100) := 'GARBLED';                    -- 文字化けチェック
  --自販機システムチェック
  --半角文字
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu Start
--    cn_chr_code_tab          CONSTANT NUMBER        := 9;                            -- '	'の文字コード
--    cn_chr_code_exmark       CONSTANT NUMBER        := 33;                           -- '!'の文字コード
--    cn_chr_code_plus         CONSTANT NUMBER        := 43;                           -- '+'の文字コード
--    cn_chr_code_colon        CONSTANT NUMBER        := 58;                           -- ':'の文字コード
--    cn_chr_code_atmark       CONSTANT NUMBER        := 64;                           -- '@'の文字コード
--    cn_chr_code_bracket      CONSTANT NUMBER        := 91;                           -- '['の文字コード
--    cn_chr_code_caret        CONSTANT NUMBER        := 94;                           -- '^'の文字コード
--    cn_chr_code_acsan        CONSTANT NUMBER        := 96;                           -- '`'の文字コード
--    cn_chr_code_brace        CONSTANT NUMBER        := 123;                          -- '{'の文字コード
--    cn_chr_code_tilde        CONSTANT NUMBER        := 126;                          -- '~'の文字コード
--  --全角文字
--    cn_chr_code_wavy_line    CONSTANT NUMBER        := 33120;                        -- '0'の文字コード
--    cn_chr_code_union        CONSTANT NUMBER        := 33214;                        -- '∪'の文字コード
--    cn_chr_code_intersection CONSTANT NUMBER        := 33215;                        -- '∩'の文字コード
--    cn_chr_code_corner       CONSTANT NUMBER        := 33242;                        -- '∠'の文字コード
--    cn_chr_code_vertical     CONSTANT NUMBER        := 33243;                        -- '⊥'の文字コード
--    cn_chr_code_combination  CONSTANT NUMBER        := 33247;                        -- '≡'の文字コード
--    cn_chr_code_route        CONSTANT NUMBER        := 33251;                        -- '√'の文字コード
--    cn_chr_code_because      CONSTANT NUMBER        := 33254;                        -- '∵'の文字コード^
--    cn_chr_code_integration  CONSTANT NUMBER        := 33255;                        -- '∫'の文字コード
--    cn_chr_code_maruone      CONSTANT NUMBER        := 34624;                        -- '①'の文字コード
--    cn_chr_code_some         CONSTANT NUMBER        := 33248;                        -- '≒'の文字コード
--    cn_chr_code_difference   CONSTANT NUMBER        := 34713;                        -- '⊿'の文字コード
-- 2016-04-04 DELETE Ver.1.9 By K.Kiriu Start
--    cn_ampersand             CONSTANT NUMBER        := 38;                           -- '&'の文字コード
-- 2016-04-04 DELETE Ver.1.9 By K.Kiriu End
    cn_less_than_sign        CONSTANT NUMBER        := 60;                           -- '<'の文字コード
    cn_greater_than_sign     CONSTANT NUMBER        := 62;                           -- '>'の文字コード
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu End
  --文字化けチェック
  --半角文字
    cn_chr_code_yen_mark     CONSTANT NUMBER        := 92;                           -- '\'の文字コード
  --全角文字
    cn_chr_code_over_line    CONSTANT NUMBER        := 33104;                        -- '￣'の文字コード
    cn_chr_code_darshi       CONSTANT NUMBER        := 33116;                        -- '―'の文字コード
    cn_chr_code_backslash    CONSTANT NUMBER        := 33119;                        -- '＼'の文字コード
    cn_chr_code_parallel     CONSTANT NUMBER        := 33121;                        -- '∥'の文字コード
    cn_chr_code_three_reader CONSTANT NUMBER        := 33123;                        -- '…'の文字コード
    cn_chr_code_two_darshi   CONSTANT NUMBER        := 33148;                        -- '－'の文字コード
    cn_chr_code_yen_mark_b   CONSTANT NUMBER        := 33167;                        -- '￥'の文字コード
    cn_chr_code_cent         CONSTANT NUMBER        := 33169;                        -- '￠'の文字コード
    cn_chr_code_pound        CONSTANT NUMBER        := 33170;                        -- '￡'の文字コード
    cn_chr_code_not          CONSTANT NUMBER        := 33226;                        -- '￢'の文字コード
--
    -- *** ローカル定数 ***
--
    lv_check_char VARCHAR2(2); -- チェック対象文字
    ln_check_char NUMBER;      -- チェック対象文字コード
  BEGIN
--
    --チェック対象文字列NULLチェック
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    --チェック範囲NULLチェック
    ELSIF (iv_check_scope IS NULL) THEN
      RETURN NULL;
    --チェック範囲不正チェック
    ELSIF (iv_check_scope NOT IN (cv_chk_scope_machine,cv_chk_scope_garbled)) THEN
      RETURN NULL;
    END IF;
    --チェック対象文字列を1文字づつチェック
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      --チェック対象文字列を1文字づつに切り取り
      lv_check_char := SUBSTR(iv_check_char,ln_position,1);
      --チェック対象文字を文字コードに変換
      ln_check_char := ASCII(lv_check_char);
      --自販機システムチェックの場合
      IF (iv_check_scope = cv_chk_scope_machine) THEN
        --禁則文字チェック
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu Start
--        IF ((ln_check_char BETWEEN cn_chr_code_colon AND cn_chr_code_atmark)
--          OR (ln_check_char BETWEEN cn_chr_code_exmark AND cn_chr_code_plus)
--          OR (ln_check_char BETWEEN cn_chr_code_bracket AND cn_chr_code_caret)
--          OR (ln_check_char BETWEEN cn_chr_code_brace AND cn_chr_code_tilde)
--          OR (ln_check_char IN (cn_chr_code_tab,cn_chr_code_acsan))
--          OR (ln_check_char BETWEEN cn_chr_code_maruone AND cn_chr_code_difference)
--          OR (ln_check_char IN (cn_chr_code_some,cn_chr_code_combination,cn_chr_code_integration,
--            cn_chr_code_route,cn_chr_code_vertical,cn_chr_code_corner,cn_chr_code_because,
--              cn_chr_code_intersection,cn_chr_code_union,cn_chr_code_wavy_line)))
-- 2016-04-04 UPDATE Ver.1.9 By K.Kiriu Start
--        IF (ln_check_char IN (cn_ampersand,cn_less_than_sign,cn_greater_than_sign) )
        IF (ln_check_char IN (cn_less_than_sign,cn_greater_than_sign) )
-- 2016-04-04 UPDATE Ver.1.9 By K.Kiriu End
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu End
        THEN
          RETURN FALSE;
        END IF;
      --文字化けチェックの場合
      ELSIF (iv_check_scope = cv_chk_scope_garbled) THEN
-- 2009-06-25 MOD Ver.1.6 By Yuuki.Nakamura Start
/*        --禁則文字チェック
        IF ((ln_check_char IN (cn_chr_code_tilde,cn_chr_code_yen_mark))
          OR (ln_check_char = cn_chr_code_yen_mark)
          OR (ln_check_char BETWEEN cn_chr_code_backslash AND cn_chr_code_parallel)
          OR (ln_check_char IN (cn_chr_code_over_line,cn_chr_code_darshi,cn_chr_code_three_reader,
            cn_chr_code_two_darshi,cn_chr_code_yen_mark_b,cn_chr_code_cent,cn_chr_code_pound,cn_chr_code_not)))
        THEN
          RETURN FALSE;
        END IF;*/
        --常にTRUEを返す
        RETURN TRUE;
-- 2009-06-25 MOD Ver.1.6 By Yuuki.Nakamura End
      END IF;
    END LOOP;
--
    RETURN TRUE;
--
  EXCEPTION
--
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END chk_moji;
  --
  /**********************************************************************************
   * Procedure Name   : BLOBデータ変換
   * Description      : blob_to_varchar2
   ***********************************************************************************/
-- 2009/08/17 Ver1.7 modify start by Yutaka.Kuboshima
-- ===============================
-- 全面改修
-- ===============================
--
-- エラー内容：32000バイト以上かつ、2バイト文字が存在する場合、文字化けエラーが発生する可能性がある。
--
-- ■対応内容
-- 修正前：最初にBLOBから32000バイトを取り出し、 文字列に変換していき、BLOBが32000バイト以上の場合は
--         BLOBがなくなるまで10000バイトずつ取り出して文字列に変換していく。 
--
-- 修正後：BLOBから改行コードまでを取り出し、文字列に変換していく。(1レコードずつ取り出して文字列に変換) 
--         BLOBがなくなるまで上記を繰り返す。
--
/*
  PROCEDURE blob_to_varchar2(
    in_file_id   IN         NUMBER,          -- ファイルＩＤ
    ov_file_data OUT NOCOPY g_file_data_tbl, -- 変換後VARCHAR2データ
    ov_errbuf    OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode   OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg    OUT NOCOPY VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'blob_to_varchar2'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    lv_line_feed                     VARCHAR2(1);                  -- 改行コード
    lb_src_lob                       BLOB;                         -- 読み込み対象BLOB
    lr_bufb                          RAW(32767);                   -- 格納バッファ
    lv_str                           VARCHAR2(32767);              -- キャスト退避
    li_amt                           INTEGER;                      -- 読み取りサイズ
    li_pos                           INTEGER;                      -- 読み取り開始位置
    ln_index                         NUMBER;                       -- 行
    lb_index                         BOOLEAN;                      -- 行作成継続
    ln_length                        NUMBER;                       -- 長さ保管用
    ln_ieof                          NUMBER;                       -- EOFフラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ファイルアップロードインタフェースデータ取得
    -- 行ロック処理
    SELECT xmf.file_data -- ファイルデータ
    INTO   lb_src_lob
    FROM   xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- 初期化
    ov_file_data.delete;
    lv_line_feed := CHR(13); -- 改行コード
    li_amt := 32000;         -- 読み取りサイズ
    li_pos := 1;             -- 読み取り開始位置
    ln_ieof := 0;            -- EOFフラグ
    ln_index := 0;           -- 行
    lb_index := TRUE;        -- 行作成継続
--
    -- バッファ取得
    DBMS_LOB.READ(lb_src_lob, --読み込み対象BLOB
                  li_amt,     --読み取りサイズ
                  li_pos,     --読み取り開始位置
                  lr_bufb);   --格納バッファ
--
    -- VARCHAR2に変換
    lv_str := UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
--
    -- 次回バッファ計算
    li_pos := li_pos + li_amt;
    li_amt := 10000;
--
    -- 改行コード毎に分解
    <<line_loop>>
    LOOP
--
      -- lv_strが少なくなったら、追加バッファ読み込みを行う
      IF ((LENGTH(lv_str) <= 2000) AND (ln_ieof = 0)) THEN
        BEGIN
          -- バッファの読み取り
          DBMS_LOB.READ(lb_src_lob,--読み込み対象BLOB
                        li_amt,    --読み取りサイズ
                        li_pos,    --読み取り開始位置
                        lr_bufb);  --格納バッファ
--
          -- VARCHAR2に変換
          lv_str := lv_str || UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
--
          -- 次回バッファの取得位置計算
          li_pos := li_pos + li_amt;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          ln_ieof := -1;
        END;
      END IF;
--
      -- データ終了
      EXIT WHEN ((lb_index = FALSE) OR (lv_str IS NULL));
--
      -- 行番号をカウントアップ（初期値は１）
      ln_index := ln_index + 1;
--
      -- 改行コードの位置を取得
      ln_length := instr(lv_str,lv_line_feed);
--
      -- 改行コード無しの場合
      IF (ln_length = 0) THEN
        ln_length := LENGTH(lv_str);
        lb_index := FALSE;
      END IF;
--
      -- １行分の情報を保管
      IF (lb_index) THEN
        -- 改行コードはのぞくため、ln_length-1
        ov_file_data(ln_index) := SUBSTR(lv_str,1,ln_length - 1);
      ELSE
        ov_file_data(ln_index) := SUBSTR(lv_str,1,ln_length);
      END IF;
--
      --lv_strは今回取得した行を除く（改行コードCRLFはのぞくため、ln_length + 2）
      lv_str := SUBSTR(lv_str,ln_length + 2);
--
    END LOOP line_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_002,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END blob_to_varchar2;
--
*/
  /**********************************************************************************
   * Procedure Name   : BLOBデータ変換
   * Description      : blob_to_varchar2
   ***********************************************************************************/
  PROCEDURE blob_to_varchar2(
    in_file_id   IN         NUMBER,          -- ファイルＩＤ
    ov_file_data OUT NOCOPY g_file_data_tbl, -- 変換後VARCHAR2データ
    ov_errbuf    OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode   OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg    OUT NOCOPY VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'blob_to_varchar2'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cr_line_feed                     CONSTANT RAW(10)     := UTL_RAW.CAST_TO_RAW(CHR(10)); -- 改行コード
--
    -- *** ローカル変数 ***
    lb_src_lob                       BLOB;                         -- 読み込み対象BLOB
    lr_bufb                          RAW(32767);                   -- 格納バッファ
    lv_str                           VARCHAR2(32767);              -- キャスト退避
    li_amt                           INTEGER;                      -- 読み取りサイズ
    li_pos                           INTEGER;                      -- 読み取り開始位置
    li_index                         INTEGER;                      -- 行
    li_save_pos_line_feed            INTEGER;                      -- 改行コード位置退避用
    li_pos_line_feed                 INTEGER;                      -- 改行コード位置
    li_blob_length                   INTEGER;                      -- BLOB値の長さ
    lb_eof_flag                      BOOLEAN;                      -- EOFフラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    not_cast_varchar2_expt           EXCEPTION;                    -- 文字列変換不可エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 変数初期化
    ov_file_data.delete;
    li_amt                := 0;      -- 読み取りサイズ
    li_pos                := 0;      -- 読み取り開始位置
    li_index              := 1;      -- 行
    li_pos_line_feed      := 0;      -- 改行コード位置
    li_save_pos_line_feed := 0;      -- 改行コード位置退避用
    lb_eof_flag           := FALSE;  -- EOFフラグ
--
    -- ファイルアップロードインタフェースデータ取得
    -- 行ロック処理
    SELECT xmf.file_data -- ファイルデータ
    INTO   lb_src_lob
    FROM   xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
    --
    -- BLOB値の長さ取得
    li_blob_length := DBMS_LOB.GETLENGTH(lb_src_lob);
--
    -- 1レコード毎に処理
    <<line_loop>>
    LOOP
--
      -- 改行コードの位置を取得します
      li_pos_line_feed := DBMS_LOB.INSTR(lb_src_lob,                -- 読み込み対象BLOB
                                         cr_line_feed,              -- 検索文字(改行コード)
                                         li_save_pos_line_feed + 1, -- 開始位置(前改行コード + 1)
                                         1);                        -- 出現番号
      -- 改行コードが存在しない場合
      IF (li_pos_line_feed = 0) THEN
        -- 読み取りサイズ設定(BLOB値の長さ - 前回の改行コード位置)
        li_amt := li_blob_length - li_save_pos_line_feed;
        -- EOFフラグ設定
        lb_eof_flag := TRUE;
      ELSE
        -- 読み取りサイズ設定(改行コードは読取らないため、-2(前回の改行コード + 今回の改行コード)をしています)
        li_amt := li_pos_line_feed - li_save_pos_line_feed - 2;
        -- BLOBの最後の文字が改行コードの場合
        IF (li_pos_line_feed = li_blob_length) THEN
          -- EOFフラグ設定
          lb_eof_flag := TRUE;
        END IF;
      END IF;
      -- 読み取りサイズが32767バイトより大きい場合
      IF (li_amt > 32767) THEN
        -- 文字列変換が不可能なためエラー終了
        RAISE not_cast_varchar2_expt;
      END IF;
      -- バッファ読み取り開始位置設定(前回の改行コード位置の次バイトから読み取り開始)
      li_pos := li_save_pos_line_feed + 1;
      -- バッファ取得
      DBMS_LOB.READ(lb_src_lob  --読み込み対象BLOB
                   ,li_amt      --読み取りサイズ
                   ,li_pos      --読み取り開始位置
                   ,lr_bufb);   --格納バッファ
      -- VARCHAR2に変換
      lv_str := UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
      -- 1行分の情報を保管
      ov_file_data(li_index) := lv_str;
      -- 終了条件：EOFフラグがTRUEになるまで
      EXIT WHEN (lb_eof_flag = TRUE);
      -- 行番号をカウントアップ（初期値は１）
      li_index := li_index + 1;
      -- 改行コードの位置を退避させます
      li_save_pos_line_feed := li_pos_line_feed;
--
    END LOOP line_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_002,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    WHEN not_cast_varchar2_expt THEN                    --*** 文字列変換不可エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_003,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
      -- 変換後VARCHAR2データを削除します
      ov_file_data.delete;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END blob_to_varchar2;
--
-- 2009/08/17 Ver1.7 modify end by Yutaka.Kuboshima
--
  /**********************************************************************************
   * Procedure Name   : 項目チェック
   * Description      : upload_item_check
   *
   * （補足）
   *  ＜入力項目＞
   *  項目名称（項目の日本語名）    ：必須：項目の日本語名称を設定
   *  項目の値                      ：必須：項目の値を設定
   *  項目の長さ                    ：任意：項目属性がVARCHAR2  の場合、最大桁数を設定
   *                                        項目属性がDATE      の場合、NULLを設定
   *                                        項目属性がNUMBERで桁数指定がある場合、小数点以下も含めた桁数を設定
   *                                                                    ない場合、NULLを設定
   *  項目の長さ（小数点以下）      ：任意：項目属性がNUMBER以外の場合、NULLを設定
   *                                        項目属性がNUMBERで桁数指定がある場合、小数点以下の桁数を設定。
   *                                        （整数桁のみ指定の場合は0を設定）
   *                                                                    ない場合、NULLを設定
   *  必須フラグ（上記定数を設定）  ：必須：必須フラグを設定
   *  項目属性（上記定数を設定）    ：必須：項目属性を設定
   *
   * ＜リターンコード＞
   * ov_retcode=set_status_normal の場合：項目チェックの正常とする
   * ov_retcode=xxccp_common_pkg.set_status_warn   の場合：項目チェックの異常終了
   * ov_retcode=xxccp_common_pkg.set_status_error  の場合：項目チェックのシステムエラー
   *
   ***********************************************************************************/
  PROCEDURE upload_item_check(
    iv_item_name      IN          VARCHAR2,         -- 項目名称（項目の日本語名）
    iv_item_value     IN          VARCHAR2,         -- 項目の値
    in_item_len       IN          NUMBER,           -- 項目の長さ
    in_item_decimal   IN          NUMBER,           -- 項目の長さ（小数点以下）
    iv_item_nullflg   IN          VARCHAR2,         -- 必須フラグ（上記定数を設定）
    iv_item_attr      IN          VARCHAR2,         -- 項目属性（上記定数を設定）
    ov_errbuf         OUT NOCOPY  VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY  VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY  VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                   CONSTANT VARCHAR2(100)  := 'upload_item_check'; -- プログラム名
    cn_number_max_l               CONSTANT NUMBER         := 38;                  -- NUMBER型最大桁数
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_line_feed                     VARCHAR2(1);                  -- 改行コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル変数 ***
    lv_err_message      VARCHAR2(32767);  -- エラーメッセージ
    ln_period_col       NUMBER;           -- ピリオド位置
    ln_tonumber         NUMBER;           -- NUMBER型チェック用
    ld_todate           DATE;             -- DATE型チェック用
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数初期化
    lv_err_message := NULL;     -- メッセージ領域初期化
    lv_line_feed := CHR(10);    -- 改行コード
--
    -- **************************************************
    -- *** パラメータチェック
    -- **************************************************
    -- 「項目名称」チェック
    IF (iv_item_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_para1,
                                            gv_cnst_tkn_value,
                                            iv_item_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「必須フラグ」チェック
    IF ((iv_item_nullflg IS NULL) OR (iv_item_nullflg NOT IN (gv_null_ok, gv_null_ng)) )THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_para2,
                                            gv_cnst_tkn_value,
                                            iv_item_nullflg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「項目属性」チェック
    IF ((iv_item_attr IS NULL) OR (iv_item_attr NOT IN (gv_attr_vc2, gv_attr_num, gv_attr_dat))) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_para3,
                                            gv_cnst_tkn_value,
                                            iv_item_attr);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 属性がVARCHAR2の場合、「項目の長さ」チェック
    IF (iv_item_attr = gv_attr_vc2) THEN
      IF (in_item_len IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_com3_para4,
                                              gv_cnst_tkn_value,
                                              in_item_len);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 属性がNUMBERの場合、「項目の長さ」・「項目の長さ（小数点以下）」チェック
    IF (iv_item_attr = gv_attr_num) THEN
--
--    「項目の長さ」と「項目の長さ（小数点以下）」の整合性チェック
      IF (((in_item_len IS NULL) AND (in_item_decimal IS NULL))
        OR ((in_item_len IS NOT NULL) AND (in_item_decimal IS NOT NULL)))
      THEN
        NULL;
      ELSE
        -- 項目の長さ」・「項目の長さ（小数点以下）」の値が両方NULL、又は
        -- 項目の長さ」・「項目の長さ（小数点以下）」の値が両方NOT NULL でない以外の場合はエラー
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_com3_para5,
                                              gv_cnst_tkn_value1,
                                              in_item_len,
                                              gv_cnst_tkn_value2,
                                              in_item_decimal);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- **************************************************
    -- *** 必須チェック
    -- **************************************************
    -- 必須項目の場合
    IF (iv_item_nullflg = gv_null_ng) THEN
      IF (iv_item_value IS NULL) THEN
        lv_err_message := lv_err_message
                          || gv_cnst_err_msg_space
                          || gv_cnst_err_msg_space
                          || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                      gv_cnst_msg_com3_null,
                                                      gv_cnst_tkn_item,
                                                      iv_item_name)
                          || lv_line_feed;
      END IF;
    END IF;
--
    --項目の値が設定されている場合
    IF (iv_item_value IS NOT NULL) THEN
      -- **************************************************
      -- *** VARCHAR2型（フリー）チェック
      -- **************************************************
      IF (iv_item_attr = gv_attr_vc2) THEN
        -- サイズチェック
        IF (LENGTHB(iv_item_value) > in_item_len) THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_size,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** ＮＵＭＢＥＲ型チェック
      -- **************************************************
      IF (iv_item_attr = gv_attr_num) THEN
        BEGIN
          -- TO_NUMBERできなければエラー
          ln_tonumber := TO_NUMBER(iv_item_value);
--
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_numb,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
        END;
--
        -- 桁数指定がない場合
        IF in_item_len IS NULL THEN
          -- ピリオドを除いた桁数が38桁をオーバーした場合エラー
          IF (LENGTHB(REPLACE(iv_item_value,gv_cnst_period,NULL))) > cn_number_max_l THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_size,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
          END IF;
        ELSE
          -- ピリオドの位置を取得
          ln_period_col := INSTRB(iv_item_value, gv_cnst_period);
          -- ピリオド無しの場合
          IF (ln_period_col = 0) THEN
            -- 整数部の桁数をオーバーしていればエラー
            IF (LENGTHB(iv_item_value) > (in_item_len - in_item_decimal)) THEN
              lv_err_message := lv_err_message
                                || gv_cnst_err_msg_space
                                || gv_cnst_err_msg_space
                                || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                            gv_cnst_msg_com3_size,
                                                            gv_cnst_tkn_item,
                                                            iv_item_name)
                                || lv_line_feed;
            END IF;
          -- ピリオド有りの場合
          --   整数部が桁数オーバー又は小数点以下が桁数オーバーしていればエラー
          ELSIF ((ln_period_col -1 > (in_item_len - in_item_decimal))
            OR (LENGTHB(SUBSTRB(iv_item_value, ln_period_col + 1))) > in_item_decimal) THEN
              lv_err_message := lv_err_message
                                || gv_cnst_err_msg_space
                                || gv_cnst_err_msg_space
                                || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                            gv_cnst_msg_com3_size,
                                                            gv_cnst_tkn_item,
                                                            iv_item_name)
                                || lv_line_feed;
          END IF;
--
        END IF;
--
      END IF;
--
      -- **************************************************
      -- *** ＤＡＴＥ型チェック
      -- **************************************************
      IF (iv_item_attr = gv_attr_dat) THEN
        ld_todate := FND_DATE.STRING_TO_DATE(iv_item_value, 'RR/MM/DD');
        IF (ld_todate IS NULL) THEN
          lv_err_message := lv_err_message
                            || gv_cnst_err_msg_space
                            || gv_cnst_err_msg_space
                            || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                        gv_cnst_msg_com3_date,
                                                        gv_cnst_tkn_item,
                                                        iv_item_name)
                            || lv_line_feed;
        END IF;
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** メッセージの整形
    -- **************************************************
    -- メッセージが登録されている場合
    IF (lv_err_message IS NOT NULL) THEN
      -- 最後の改行コードを削除しOUTパラメータに設定
      ov_errmsg := RTRIM(lv_err_message, lv_line_feed);
      -- ワーニングとして終了
      ov_retcode := xxccp_common_pkg.set_status_warn;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upload_item_check;
  --
END xxccp_common_pkg2;
/
