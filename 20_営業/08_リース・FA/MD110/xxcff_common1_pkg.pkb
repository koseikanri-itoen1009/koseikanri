CREATE OR REPLACE PACKAGE BODY XXCFF_COMMON1_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON1_PKG(body)
 * Description      : リース・FA領域共通関数１
 * MD.050           : なし
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ---- ----- ----------------------------------------------
 *  Name                        Type  Ret   Description
 * ---------------------------- ---- ----- ----------------------------------------------
 *  init                         P    -     初期処理
 *  put_log_param                P    -     コンカレントパラメータ出力処理
 *  chk_fa_location              P    -     事業所マスタチェック
 *  chk_discount_rate            P    -     現在価値割引率取得チェック
 *  chk_fa_category              P    -     資産カテゴリチェック
 *  chk_life                     P    -     耐用年数チェック
 *  作成順に記述していくこと
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/17    1.0   SCS山岸謙一      新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF_COMMON1_PKG'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCFF';            -- アドオン：FA・リース領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE init(
    or_init_rec   OUT NOCOPY init_rtype,   --   戻り値
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
    cv_init_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00152'; -- 初期処理エラー
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
    ln_set_of_book_id         NUMBER(15);
    lv_currency_code          VARCHAR2(15);
    ln_chart_of_account_id    NUMBER(15);
    lv_application_short_name VARCHAR2(50);
    lv_id_flex_code           VARCHAR2(4);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    or_init_rec := NULL;
    -- 会計帳簿ID
    ln_set_of_book_id := TO_NUMBER(fnd_profile.value('GL_SET_OF_BKS_ID'));
    -- 機能通貨、科目体系
    SELECT currency_code
          ,chart_of_accounts_id
      INTO lv_currency_code
          ,ln_chart_of_account_id
      FROM gl_sets_of_books
     WHERE set_of_books_id = ln_set_of_book_id;
    -- GLアプリケーション短縮名、キーフレックスコード
    SELECT a.application_short_name
          ,s.id_flex_code
      INTO lv_application_short_name
          ,lv_id_flex_code
      FROM fnd_application a
          ,fnd_id_flex_structures_vl s
          ,fa_system_controls f
     WHERE a.application_id = f.gl_application_id
       AND s.application_id = f.gl_application_id
       AND s.id_flex_num = ln_chart_of_account_id;
--
    -- 業務日付
    or_init_rec.process_date           := xxccp_common_pkg2.get_process_date;
    -- 会計帳簿ID
    or_init_rec.set_of_books_id        := ln_set_of_book_id;
    -- 機能通貨
    or_init_rec.currency_code          := lv_currency_code;
    -- 営業単位
    or_init_rec.org_id                 := fnd_profile.value('ORG_ID');
    -- GLアプリケーション短縮名
    or_init_rec.gl_application_short_name := lv_application_short_name;
    -- 科目体系ID
    or_init_rec.chart_of_accounts_id   := ln_chart_of_account_id;
    -- キーフレックスコード
    or_init_rec.id_flex_code           := lv_id_flex_code;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--    WHEN global_api_expt THEN                           --*** 処理エラー ***
--      -- *** 任意で例外処理を記述する ****
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_init_err_msg
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : put_log_param
   * Description      : コンカレントパラメータ出力処理
   ***********************************************************************************/
  PROCEDURE put_log_param(
    iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT',  -- 出力区分
    ov_errbuf   OUT NOCOPY VARCHAR2,            --エラーメッセージ
    ov_retcode  OUT NOCOPY VARCHAR2,            --リターンコード
    ov_errmsg   OUT NOCOPY VARCHAR2             --ユーザー・エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_param'; -- プログラム名
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
    lv_request_id          VARCHAR2(100) := fnd_global.conc_request_id;        -- 要求ID
--
    -- *** ローカル・カーソル ***
    CURSOR concurrent_cur
    IS
      SELECT fcr.request_id
            ,fcr.argument1
            ,fcr.argument2
            ,fcr.argument3
            ,fcr.argument4
            ,fcr.argument5
            ,fcr.argument6
            ,fcr.argument7
            ,fcr.argument8
            ,fcr.argument9
            ,fcr.argument10
      FROM   fnd_concurrent_requests    fcr    --要求管理マスタ
            ,fnd_concurrent_programs_tl fcpt   --要求マスタ
      WHERE  fcr.request_id = TO_NUMBER(lv_request_id)
      AND    fcr.program_application_id = fcpt.application_id
      AND    fcr.concurrent_program_id = fcpt.concurrent_program_id
      AND    fcpt.language = 'JA'
      ;
--
    -- *** ローカル・レコード ***
    concurrent_cur_v concurrent_cur%ROWTYPE;  --カーソル変数を定義
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- コンカレントパラメータ取得
    OPEN concurrent_cur;
    FETCH concurrent_cur INTO concurrent_cur_v;
    CLOSE concurrent_cur;
--
    -- 会計チーム共通関数でパラメータ出力
    xxcfr_common_pkg.put_log_param(
       iv_which       => iv_which                      -- 出力区分
      ,iv_conc_param1 => concurrent_cur_v.argument1    -- コンカレントパラメータ１
      ,iv_conc_param2 => concurrent_cur_v.argument2    -- コンカレントパラメータ２
      ,iv_conc_param3 => concurrent_cur_v.argument3    -- コンカレントパラメータ３
      ,iv_conc_param4 => concurrent_cur_v.argument4    -- コンカレントパラメータ４
      ,iv_conc_param5 => concurrent_cur_v.argument5    -- コンカレントパラメータ５
      ,iv_conc_param6 => concurrent_cur_v.argument6    -- コンカレントパラメータ６
      ,iv_conc_param7 => concurrent_cur_v.argument7    -- コンカレントパラメータ７
      ,iv_conc_param8 => concurrent_cur_v.argument8    -- コンカレントパラメータ８
      ,iv_conc_param9 => concurrent_cur_v.argument9    -- コンカレントパラメータ９
      ,iv_conc_param10=> concurrent_cur_v.argument10   -- コンカレントパラメータ１０
      ,ov_errbuf      => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_log_param;
--
  /**********************************************************************************
   * Procedure Name   : chk_fa_location
   * Description      : 事業所マスタチェック
   ***********************************************************************************/
  PROCEDURE chk_fa_location(
    iv_segment1    IN  VARCHAR2 DEFAULT NULL, -- 申告地
    iv_segment2    IN  VARCHAR2,              -- 管理部門
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- 事業所
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- 場所
    iv_segment5    IN  VARCHAR2,              -- 本社／工場
    on_location_id OUT NOCOPY NUMBER,         -- 事業所ID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_fa_location'; -- プログラム名
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
    lv_application_short_name    VARCHAR2(100);
    lv_key_flex_code             VARCHAR2(100) := 'LOC#';
    ln_structure_no              NUMBER(15);
    l_segments_tab               fnd_flex_ext.segmentarray;
    ln_combination_id            NUMBER(15);
    lb_ret                       BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ｱﾌﾟﾘｹｰｼｮﾝ短縮名、ｽﾄﾗｸﾁｬ番号取得
    BEGIN
      SELECT a.application_short_name
            ,f.location_flex_structure
        INTO lv_application_short_name
            ,ln_structure_no
        FROM fnd_application a
            ,fa_system_controls f
      WHERE a.application_id = f.fa_application_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    -- 事業所情報格納
    l_segments_tab(1) := NVL(iv_segment1,fnd_profile.value('XXCFF1_DCLR_PLACE_NO_REPORT'));
    l_segments_tab(2) := iv_segment2;
    l_segments_tab(3) := NVL(iv_segment3,fnd_profile.value('XXCFF1_MNG_PLACE_DAMMY'));
    l_segments_tab(4) := NVL(iv_segment4,fnd_profile.value('XXCFF1_PLACE_DAMMY'));
    l_segments_tab(5) := iv_segment5;
--
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name => lv_application_short_name
                ,key_flex_code          => lv_key_flex_code
                ,structure_number       => ln_structure_no
                ,validation_date        => SYSDATE
                ,n_segments             => 5
                ,segments               => l_segments_tab
                ,combination_id         => ln_combination_id
                );
    IF NOT lb_ret THEN
      lv_errbuf := fnd_flex_ext.get_message;
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
    -- 戻り値設定
    on_location_id := ln_combination_id;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_fa_location;
--
  /**********************************************************************************
   * Procedure Name   : chk_fa_category
   * Description      : 資産カテゴリチェック
   ***********************************************************************************/
  PROCEDURE chk_fa_category(
    iv_segment1    IN  VARCHAR2,              -- 種類
    iv_segment2    IN  VARCHAR2 DEFAULT NULL, -- 申告償却
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- 資産勘定
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- 償却科目
    iv_segment5    IN  VARCHAR2,              -- 耐用年数
    iv_segment6    IN  VARCHAR2 DEFAULT NULL, -- 償却方法
    iv_segment7    IN  VARCHAR2,              -- リース種別
    on_category_id OUT NOCOPY NUMBER,         -- 資産カテゴリID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_fa_category'; -- プログラム名
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
    cv_param_err     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00101'; -- エラーメッセージ名
    cv_tkn_name1     CONSTANT VARCHAR2(100) := 'TABLE_NAME';
    cv_tkn_name2     CONSTANT VARCHAR2(100) := 'INFO';
    cv_tkn_val1      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50071'; -- フレックスフィールド体系情報
    cv_tkn_val2      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50041'; -- リース種別
    cv_itm_equal     CONSTANT VARCHAR2(100) := '=';                --
--
    -- *** ローカル変数 ***
    lv_application_short_name    VARCHAR2(100);
    lv_key_flex_code             VARCHAR2(100) := 'CAT#';
    ln_structure_no              NUMBER(15);
    l_segments_tab               fnd_flex_ext.segmentarray;
    ln_combination_id            NUMBER(15);
    lb_ret                       BOOLEAN;
    lv_les_asset_acct            xxcff_lease_class_v.les_asset_acct%TYPE;
    lv_deprn_acct                xxcff_lease_class_v.deprn_acct%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ｱﾌﾟﾘｹｰｼｮﾝ短縮名、ｽﾄﾗｸﾁｬ番号取得
    BEGIN
      SELECT
             a.application_short_name
            ,f.location_flex_structure
        INTO
             lv_application_short_name
            ,ln_structure_no
        FROM
             fnd_application a
            ,fa_system_controls f
      WHERE
             a.application_id = f.fa_application_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_param_err
                                             ,cv_tkn_name1,       cv_tkn_val1
                                             ,cv_tkn_name2,       SQLERRM);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;

    IF ((iv_segment3 IS NULL)
        OR (iv_segment4 IS NULL)) THEN
      BEGIN
        SELECT
          les_asset_acct
         ,deprn_acct
        INTO
          lv_les_asset_acct
         ,lv_deprn_acct
        FROM
          xxcff_lease_class_v
        WHERE
          lease_class_code = iv_segment7;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_tkn_val2);
          lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_param_err
                                               ,cv_tkn_name1,       cv_tkn_val2
                                               ,cv_tkn_name2,       lv_errmsg||cv_itm_equal||iv_segment7);
          RAISE global_api_expt;
      END;
    END IF;
    -- カテゴリ情報格納
    l_segments_tab(1) := iv_segment1;
    l_segments_tab(2) := NVL(iv_segment2, fnd_profile.value('XXCFF1_DCLR_DPRN_NO_TGT'));
    l_segments_tab(3) := NVL(iv_segment3, lv_les_asset_acct);
    l_segments_tab(4) := NVL(iv_segment4, lv_deprn_acct);
    l_segments_tab(5) := iv_segment5;
    l_segments_tab(6) := NVL(iv_segment6, fnd_profile.value('XXCFF1_CAT_DPRN_LEASE'));
    l_segments_tab(7) := iv_segment7;
--
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name => lv_application_short_name
                ,key_flex_code          => lv_key_flex_code
                ,structure_number       => ln_structure_no
                ,validation_date        => SYSDATE
                ,n_segments             => 7
                ,segments               => l_segments_tab
                ,combination_id         => ln_combination_id
                );
    IF (NOT lb_ret) THEN
      lv_errbuf := fnd_flex_ext.get_message;
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
    -- 戻り値設定
    on_category_id := ln_combination_id;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_fa_category;
--
  /**********************************************************************************
   * Procedure Name   : chk_life
   * Description      : 耐用年数チェック
   ***********************************************************************************/
  PROCEDURE chk_life(
    iv_category    IN  VARCHAR2,           --   資産種類
    iv_life        IN  VARCHAR2,           --   耐用年数
    ov_errbuf      OUT NOCOPY VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_life'; -- プログラム名
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
    ln_check_count   NUMBER(1);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --種類と耐用年数の組み合わせ確認のためデータ取得
    --==============================================================
    SELECT
           COUNT(ffvv.flex_value_id)
    INTO
           ln_check_count
    FROM
           fnd_flex_values_vl  ffvv
          ,fnd_flex_value_sets ffvs
    WHERE
           ffvs.flex_value_set_name   = 'XXCFF_LIFE'
    AND    ffvv.flex_value_set_id     = ffvs.flex_value_set_id
    AND    ffvv.parent_flex_value_low = iv_category
    AND    ffvv.flex_value            = iv_life
    AND    ffvv.enabled_flag          = 'Y'
    AND    NVL(ffvv.start_date_active,SYSDATE) <= SYSDATE
    AND    NVL(ffvv.end_date_active,SYSDATE)   >= SYSDATE;
    --==============================================================
    --0件取得ではチェックエラーとする
    --==============================================================
    IF (ln_check_count = 0) THEN
      ov_retcode := cv_status_warn;                                            --# 任意 #
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_life;
--
END XXCFF_COMMON1_PKG;
/
