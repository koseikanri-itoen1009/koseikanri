CREATE OR REPLACE PACKAGE BODY xxcmn_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxcmn_common3_pkg(BODY)
 * Description            : 共通関数(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数3（補足資料）.xls
 * Version                : 1.0
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  blob_to_varchar2       P         BLOBデータ変換
 *  upload_item_check      P         項目チェック
 *  delete_proc            P         ファイルアップロードインタフェースデータ削除
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/29   1.0   ohba             新規作成
 *  2008/01/30   1.0   nomura           項目チェック追加
 *  2008/02/01   1.0   nomura           ファイルアップロードインタフェースデータ削除追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
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
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common3_pkg'; -- パッケージ名
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- 正常
  gn_ret_error     CONSTANT NUMBER := 1; -- エラー
--
  gv_cnst_msg_kbn                 CONSTANT VARCHAR2(5)   := 'XXINV';
  gv_cnst_com_kbn                 CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  gv_cnst_msg_com3_001  CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ﾛｯｸｴﾗｰ
  gv_cnst_msg_com3_002  CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- 対象データなし
  -- 項目チェック
  gv_cnst_msg_com3_para CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10010';  -- パラメータエラー
  gv_cnst_msg_com3_date CONSTANT VARCHAR2(15)  := 'APP-XXINV-10001';  -- DATE型チェックエラーメッセージ
  gv_cnst_msg_com3_numb CONSTANT VARCHAR2(15)  := 'APP-XXINV-10002';  -- NUMBER型チェックエラーメッセージ
  gv_cnst_msg_com3_size CONSTANT VARCHAR2(15)  := 'APP-XXINV-10007';  -- サイズチェックエラーメッセージ
  gv_cnst_msg_com3_null CONSTANT VARCHAR2(15)  := 'APP-XXINV-10061';  -- 必須チェックエラーメッセージ
--
  gv_cnst_tkn_table               CONSTANT VARCHAR2(15)  := 'TABLE';
  gv_cnst_tkn_item                CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value               CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_file_id_name            CONSTANT VARCHAR2(7)   := 'FILE_ID';
  gv_cnst_tkn_para                CONSTANT VARCHAR2(9)   := 'PARAMETER';
  gv_cnst_xxinv_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                           := 'ファイルアップロードインタフェーステーブル';
-- 入力パラメータ名称
  gv_cnst_item_name       CONSTANT VARCHAR2(15)  := '項目名称';
  gv_cnst_item_value      CONSTANT VARCHAR2(15)  := '項目の値';
  gv_cnst_item_len        CONSTANT VARCHAR2(15)  := '項目の長さ';
  gv_cnst_item_decimal    CONSTANT VARCHAR2(50)  := '項目の長さ（小数点以下）';
--
  gv_cnst_file_type       CONSTANT VARCHAR2(30)  := 'フォーマットパターン';
  gv_cnst_target_date     CONSTANT VARCHAR2(30)  := '対象日付';
  gv_cnst_p_days          CONSTANT VARCHAR2(30)  := 'パージ対象期間';
--
  gv_cnst_item_null       CONSTANT VARCHAR2(15)  := '必須フラグ';
  gv_cnst_item_attr       CONSTANT VARCHAR2(15)  := '項目属性';
--
  gv_cnst_period          CONSTANT VARCHAR2(1)   := '.';        -- ピリオド
  gv_cnst_err_msg_space   CONSTANT VARCHAR2(6)   := '      ';   -- スペース
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  TYPE file_id_ttype IS TABLE OF  
    xxinv_mrp_file_ul_interface.file_id%TYPE INDEX BY BINARY_INTEGER;  -- バッチID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
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
    ov_retcode := gv_status_normal;
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
    FROM   xxinv_mrp_file_ul_interface xmf
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_001,
                                            gv_cnst_tkn_table,
                                            gv_cnst_xxinv_mrp_file_ul_name);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_002,
                                            gv_cnst_tkn_item,
                                            gv_cnst_file_id_name,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END blob_to_varchar2;
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
   * ov_retcode=gv_status_normal の場合：項目チェックの正常とする
   * ov_retcode=gv_status_warn   の場合：項目チェックの異常終了
   * ov_retcode=gv_status_error  の場合：項目チェックのシステムエラー
   * 
   ***********************************************************************************/
  PROCEDURE upload_item_check(
    iv_item_name      IN          VARCHAR2,         -- 項目名称（項目の日本語名）
    iv_item_value     IN          VARCHAR2,         -- 項目の値
    in_item_len       IN          NUMBER,           -- 項目の長さ
    in_item_decimal   IN          NUMBER,           -- 項目の長さ（小数点以下）
    in_item_nullflg   IN          VARCHAR2,         -- 必須フラグ（上記定数を設定）
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
    ov_retcode := gv_status_normal;
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_item_name,
                                            gv_cnst_tkn_value,
                                            iv_item_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「必須フラグ」チェック
    IF ((in_item_nullflg IS NULL) OR (in_item_nullflg NOT IN (gv_null_ok, gv_null_ng)) )THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_item_null,
                                            gv_cnst_tkn_value,
                                            in_item_nullflg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「項目属性」チェック
    IF ((iv_item_attr IS NULL) OR (iv_item_attr NOT IN (gv_attr_vc2, gv_attr_num, gv_attr_dat))) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_item_attr,
                                            gv_cnst_tkn_value,
                                            iv_item_attr);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 属性がVARCHAR2の場合、「項目の長さ」チェック 
    IF (iv_item_attr = gv_attr_vc2) THEN
      IF (in_item_len IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_com3_para,
                                              gv_cnst_tkn_para,
                                              gv_cnst_item_len,
                                              gv_cnst_tkn_value,
                                              iv_item_value);
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
        -- 項目の長さ」・「項目の長さ（小数点以下）」の値が両方NOT NULL でない場合はエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                              gv_cnst_msg_com3_para,
                                              gv_cnst_tkn_para,
                                              gv_cnst_item_len,
                                              gv_cnst_tkn_value,
                                              in_item_len);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- **************************************************
    -- *** 必須チェック
    -- **************************************************
    -- 必須項目の場合
    IF (in_item_nullflg = gv_null_ng) THEN
      IF (iv_item_value IS NULL) THEN
        lv_err_message := lv_err_message
                          || gv_cnst_err_msg_space
                          || gv_cnst_err_msg_space
                          || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
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
                              || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
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
                              || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
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
                              || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
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
                                || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
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
                                || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
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
                            || xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
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
      ov_retcode := gv_status_warn;
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
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upload_item_check;
--
  /**********************************************************************************
   * Procedure Name   : ファイルアップロードインタフェースデータ削除
   * Description      : delete_fileup_proc
   ***********************************************************************************/
  PROCEDURE delete_fileup_proc(
    iv_file_format IN         VARCHAR2,     --   フォーマットパターン
    id_now_date    IN         DATE,         --   対象日付
    in_purge_days  IN         NUMBER,       --   パージ対象期間
    ov_errbuf      OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_fileup_proc'; -- プログラム名
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
    -- *** ローカル変数 ***
    lt_file_id_del_tab      file_id_ttype;     -- バッチID
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- *** パラメータチェック
    -- **************************************************
    -- 「フォーマットパターン」チェック
    IF (iv_file_format IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_file_type,
                                            gv_cnst_tkn_value,
                                            iv_file_format);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 「対象日付」チェック
    IF (id_now_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_target_date,
                                            gv_cnst_tkn_value,
                                            id_now_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 「パージ対象期間」チェック
    IF (in_purge_days IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_com_kbn,
                                            gv_cnst_msg_com3_para,
                                            gv_cnst_tkn_para,
                                            gv_cnst_p_days,
                                            gv_cnst_tkn_value,
                                            in_purge_days);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** 対象データ削除処理
    -- **************************************************
    BEGIN
      -- FILE_ID取得処理（ロック処理）
      -- 時分秒(00:00:00)を考慮して、パージ対象期間より-1日した期間を対象日付から引き、作成日と比較を行う。
      SELECT xmf.file_id
      BULK COLLECT INTO lt_file_id_del_tab
      FROM   xxinv_mrp_file_ul_interface xmf
      WHERE  xmf.file_content_type  =  iv_file_format
      AND    xmf.creation_date      < (TRUNC(id_now_date) - (in_purge_days -1))
      FOR UPDATE OF xmf.file_id NOWAIT;
--
      -- 削除処理（バルク処理）
      FORALL item_cnt IN 1 .. lt_file_id_del_tab.COUNT
        DELETE FROM xxinv_mrp_file_ul_interface xmf
        WHERE xmf.file_id = lt_file_id_del_tab(item_cnt);
--
    EXCEPTION
      WHEN check_lock_expt THEN
        NULL;
--
    END;
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
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_fileup_proc;
--
END xxcmn_common3_pkg;
/
