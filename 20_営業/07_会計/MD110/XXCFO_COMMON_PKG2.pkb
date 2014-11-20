CREATE OR REPLACE PACKAGE BODY XXCFO_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg2(body)
 * Description      : 共通関数（会計）
 * MD.070           : MD070_IPO_CFO_001_共通関数定義書
 * Version          : 1.00
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  chk_electric_book_item    P          電子帳簿項目チェック関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/31   1.00   SCSK T.Osawa     新規作成
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCCP_COMMON_PKG2';  -- パッケージ名
--
  cv_msg_kbn_ccp         CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfo         CONSTANT VARCHAR2(5)   := 'XXCFO';
  -- メッセージ
  cv_msg_ccp_10113       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10113';  -- DATE型チェックエラーメッセージ
  cv_msg_ccp_10114       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10114';  -- NUMBER型チェックエラーメッセージ
  cv_msg_cfo_10011       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';  -- 桁数超過スキップメッセージ
  cv_msg_cfo_10018       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10018';  -- 半角文字列不備メッセージ
  cv_msg_cfo_10020       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10020';  -- 切捨てフラグエラーメッセージ
  cv_msg_cfo_10021       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10021';  -- 項目の長さ設定エラーメッセージ
  cv_msg_cfo_10022       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10022';  -- 項目の長さ（小数点以下）設定エラーメッセージ
  --トークン
  cv_tkn_value           CONSTANT VARCHAR2(10)  := 'VALUE';             -- トークン名(VALUE)
  cv_tkn_item            CONSTANT VARCHAR2(10)  := 'ITEM';              -- トークン名(ITEM)
  cv_tkn_key_data        CONSTANT VARCHAR2(10)  := 'KEY_DATA';          -- トークン名(KEY_DATA)
  --
  cv_msg_cont            CONSTANT VARCHAR2(3)   := '.';  
--
  /**********************************************************************************
   * Function Name    : chk_electric_book_item
   * Description      : 電子帳簿項目チェック関数
   ***********************************************************************************/
  PROCEDURE chk_electric_book_item(
      iv_item_name    IN  VARCHAR2 -- 項目名称
    , iv_item_value   IN  VARCHAR2 -- 項目の値
    , in_item_len     IN  NUMBER   -- 項目の長さ
    , in_item_decimal IN  NUMBER   -- 項目の長さ(小数点以下)
    , iv_item_nullflg IN  VARCHAR2 -- 必須フラグ
    , iv_item_attr    IN  VARCHAR2 -- 項目属性
    , iv_item_cutflg  IN  VARCHAR2 -- 切捨てフラグ
    , ov_item_value   OUT VARCHAR2 -- 項目の値
    , ov_errbuf       OUT VARCHAR2 -- エラーメッセージ
    , ov_retcode      OUT VARCHAR2 -- リターンコード
    , ov_errmsg       OUT VARCHAR2 -- ユーザー・エラーメッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'chk_electric_book_item'; -- プログラム名
    -- 必須フラグ
    cv_null_ok                CONSTANT VARCHAR2(7) := 'NULL_OK'; -- 任意項目
    cv_null_ng                CONSTANT VARCHAR2(7) := 'NULL_NG'; -- 必須項目
    -- 項目属性
    cv_attr_vc2               CONSTANT VARCHAR2(1) := '0';       -- VARCHAR2
    cv_attr_num               CONSTANT VARCHAR2(1) := '1';       -- NUMBER
    cv_attr_dat               CONSTANT VARCHAR2(1) := '2';       -- DATE
    cv_attr_cha               CONSTANT VARCHAR2(1) := '3';       -- CHAR
    -- 切捨てフラグ
    cv_cut_ok                 CONSTANT VARCHAR2(2) := 'OK';      -- 切捨てOK
    cv_cut_ng                 CONSTANT VARCHAR2(2) := 'NG';      -- 切捨てNG
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_line_feed              VARCHAR2(1);     -- 改行コード
    lv_item_value             VARCHAR2(5000);  -- 項目の値（関数呼び出し用）
    lv_item_attr              VARCHAR2(1);     -- 項目属性（関数呼び出し用）
    ln_number                 NUMBER;          -- 変換用（NUMBER）
    ln_decimal_place          NUMBER;          -- 小数点位置確認用
    ln_decimal                NUMBER;          -- 小数点以下の値確認用
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_warn_expt         EXCEPTION;
    process_error_expt        EXCEPTION;
--
  BEGIN
    --==============================================================
    -- 初期化
    --==============================================================
    lv_errbuf     := NULL;
    lv_retcode    := xxccp_common_pkg.set_status_normal;
    lv_errmsg     := NULL;
    lv_line_feed  := CHR(10);
    lv_item_value := NULL;
    lv_item_attr  := NULL;
    ln_number     := NULL;
    ln_decimal    := NULL;
    --
    --==============================================================
    -- INパラメータ（切捨てフラグ）チェック
    --==============================================================
    IF (  ( iv_item_cutflg IS NOT NULL )
      AND ( iv_item_cutflg NOT IN ( cv_cut_ok, cv_cut_ng ) ) ) THEN
      lv_errbuf := cv_msg_cfo_10020;
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                           , cv_msg_cfo_10020
                                           , cv_tkn_value
                                           , iv_item_cutflg);
      RAISE process_warn_expt;
    END IF;
    --
    --==============================================================
    -- 項目の長さ、項目の長さ（小数点以下）チェック
    --==============================================================
    -- 項目の長さがNULLかつ、項目属性がDATE以外の場合
    IF (  ( in_item_len IS NULL )
      AND ( iv_item_attr <> cv_attr_dat ) ) THEN
      lv_errbuf := cv_msg_cfo_10021;
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                           , cv_msg_cfo_10021
                                           , cv_tkn_item
                                           , iv_item_name);
      RAISE process_warn_expt;
    -- 項目の長さ（小数点以下）がNULLかつ、項目属性がNUMBERの場合
    ELSIF ( ( in_item_decimal IS NULL )
      AND   ( iv_item_attr = cv_attr_num ) ) THEN
      lv_errbuf := cv_msg_cfo_10022;
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                           , cv_msg_cfo_10022
                                           , cv_tkn_item
                                           , iv_item_name);
      RAISE process_warn_expt;
    -- 項目の長さがNULLでなく、項目属性がVARCHAR2またはCHARの場合
    ELSIF ( ( in_item_len IS NOT NULL )
      AND   ( iv_item_attr IN ( cv_attr_vc2, cv_attr_cha ) ) ) THEN
      -- 項目属性がCHARの場合
      IF ( iv_item_attr = cv_attr_cha ) THEN
        -- 半角チェック関数にてFALSEの場合
        IF ( xxccp_common_pkg.chk_single_byte(iv_item_value) =  FALSE )  THEN
          lv_errbuf := cv_msg_cfo_10018;
          lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                               , cv_msg_cfo_10018
                                               , cv_tkn_item
                                               , iv_item_name);
          RAISE process_warn_expt;
        END IF;
      END IF;
      -- 項目の値のサイズが項目の長さよりも大きいかつ、切捨てフラグがNGの場合
      IF (  ( LENGTHB(iv_item_value) > in_item_len )
        AND ( iv_item_cutflg =  cv_cut_ng ) ) THEN
        lv_errbuf := cv_msg_cfo_10011;
        lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                             , cv_msg_cfo_10011
                                             , cv_tkn_key_data
                                             , NULL);
        RAISE process_warn_expt;
      END IF;
    -- 項目の長さがNULLでなく、項目属性がNUMBERの場合
    ELSIF ( ( in_item_len IS NOT NULL )
      AND   ( iv_item_attr = cv_attr_num ) ) THEN
      -- 項目の値がNUMBER型に変換できない場合
      BEGIN
        ln_number := TO_NUMBER(iv_item_value);
      EXCEPTION 
        WHEN OTHERS THEN
          lv_errbuf := cv_msg_ccp_10114;
          lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_ccp
                                               , cv_msg_ccp_10114
                                               , cv_tkn_item
                                               , iv_item_name);
          RAISE process_warn_expt;
      END;
      -- 項目の長さ（小数点以下）が0の場合
      IF ( in_item_decimal = 0 ) THEN
        -- 項目のサイズが項目の長さよりも大きい場合
        IF ( LENGTHB(ABS(iv_item_value)) > in_item_len ) THEN
          lv_errbuf := cv_msg_cfo_10011;
          lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                               , cv_msg_cfo_10011
                                               , cv_tkn_key_data
                                               , NULL);
          RAISE process_warn_expt;
        END IF;
      -- 項目の長さ（小数点以下）が0でない場合
      ELSE
        -- 小数点の位置を取得
        ln_decimal_place := INSTRB(iv_item_value, cv_msg_cont);
        -- 小数点がある場合
        IF (ln_decimal_place > 0) THEN
          -- 項目の値のサイズが項目の長さよりも大きい場合（小数点の分＋１した値で判定）
          IF ( LENGTHB(ABS(iv_item_value)) > in_item_len + 1 ) THEN
            lv_errbuf := cv_msg_cfo_10011;
            lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                 , cv_msg_cfo_10011
                                                 , cv_tkn_key_data
                                                 , NULL);
            RAISE process_warn_expt;
          END IF;
        ELSE   
          -- 項目の値のサイズが項目の長さよりも大きい場合
          IF ( LENGTHB(ABS(iv_item_value)) > in_item_len ) THEN
            lv_errbuf := cv_msg_cfo_10011;
            lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                 , cv_msg_cfo_10011
                                                 , cv_tkn_key_data
                                                 , NULL);
            RAISE process_warn_expt;
          END IF;
        END IF;  
        --
        -- 小数点が存在する場合
        IF ( ln_decimal_place > 0 ) THEN
          -- 項目の値のサイズより小数点までの項目の値のサイズを引いた値（小数点より下の長さ）を取得
          ln_decimal := LENGTHB(iv_item_value) - INSTRB(iv_item_value, cv_msg_cont);
          -- 取得値が項目の長さ（小数点以下）よりも大きい場合
          IF ( ln_decimal > in_item_decimal ) THEN
            lv_errbuf := cv_msg_cfo_10011;
            lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                 , cv_msg_cfo_10011
                                                 , cv_tkn_key_data
                                                 , NULL);
            RAISE process_warn_expt;
          END IF;
        END IF;
      END IF;
    END IF;
    --
    -- 項目の長さに合わせる
    --文字の場合
    IF ( iv_item_attr IN ( cv_attr_vc2, cv_attr_cha ) ) THEN
      lv_item_value := SUBSTRB(iv_item_value, 1, in_item_len);
    --数値の場合
    ELSIF ( iv_item_attr = cv_attr_num ) THEN
      lv_item_value := ABS(iv_item_value);        --絶対値で渡す
    --上記以外の場合
    ELSE
      lv_item_value := iv_item_value;
    END IF;
    --
    -- 項目属性変更（CHAR⇒VARCHAR）
    IF ( iv_item_attr = cv_attr_cha ) THEN
      lv_item_attr := cv_attr_vc2;
    ELSE
      lv_item_attr := iv_item_attr;
    END IF;
    --
    -- アップロード項目チェック関数呼び出し
    xxccp_common_pkg2.upload_item_check(
        iv_item_name    => iv_item_name      -- 項目名称（項目の日本語名）  -- 必須
      , iv_item_value   => lv_item_value     -- 項目の値                    -- 任意
      , in_item_len     => in_item_len       -- 項目の長さ                  -- 必須
      , in_item_decimal => in_item_decimal   -- 項目の長さ（小数点以下）    -- 条件付必須
      , iv_item_nullflg => iv_item_nullflg   -- 必須フラグ（上記定数を設定）-- 必須
      , iv_item_attr    => lv_item_attr      -- 項目属性（上記定数を設定）  -- 必須
      , ov_errbuf       => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode      => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg       => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
    --
    IF (  ( lv_retcode <> xxccp_common_pkg.set_status_normal )
      AND ( lv_errmsg IS NOT NULL ) ) THEN
      RAISE  process_warn_expt;
    ELSIF ( ( lv_retcode <> xxccp_common_pkg.set_status_normal )
      AND   ( lv_errmsg IS NULL ) ) THEN
      RAISE  process_error_expt;
    END IF;
    -- 正常終了
    -- 数値の場合
    IF ( iv_item_attr = cv_attr_num ) THEN
      ov_item_value := iv_item_value;       --入力値を戻す
    ELSE
      ov_item_value := lv_item_value;
    END IF;
    ov_retcode    := xxccp_common_pkg.set_status_normal;
    ov_errbuf     := NULL;
    ov_errmsg     := NULL;
    --
  EXCEPTION
    -- 警告終了
    WHEN process_warn_expt THEN
      ov_item_value := NULL;
      ov_retcode    := xxccp_common_pkg.set_status_warn;
      ov_errbuf     := lv_errbuf;
      ov_errmsg     := RTRIM( lv_errmsg, lv_line_feed );
    -- 異常終了
    WHEN process_error_expt THEN
      ov_item_value := NULL;
      ov_retcode    := xxccp_common_pkg.set_status_error;
      ov_errbuf     := cv_prg_name || SQLERRM;
      ov_errmsg     := NULL;
    -- 異常終了
    WHEN OTHERS THEN
      ov_item_value := NULL;
      ov_retcode    := xxccp_common_pkg.set_status_error;
      ov_errbuf     := cv_prg_name || SQLERRM;
      ov_errmsg     := NULL;
  END chk_electric_book_item;
--
END XXCFO_COMMON_PKG2;
/
