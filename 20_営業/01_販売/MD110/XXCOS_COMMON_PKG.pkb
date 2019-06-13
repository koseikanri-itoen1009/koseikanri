CREATE OR REPLACE PACKAGE BODY XXCOS_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON_PKG(body)
 * Description      : 共通関数パッケージ(販売)
 * MD.070           : 共通関数    MD070_IPO_COS
 * Version          : 1.4
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  get_key_info                P                 キー情報編集
 *  get_uom_cnv                 P                 単位換算取得
 *  get_delivered_from          P                 納品形態取得
 *  get_sales_calendar_code     P                 販売用カレンダーコード取得
 *  check_sales_operation_day   F      NUMBER     販売用稼働日チェック
 *  get_period_year             P                 当年度会計期間取得
 *  get_account_period          P                 会計期間情報取得
 *  get_specific_master         F      VARCHAR2   特定マスタ取得(クイックコード)
 *  get_tax_rate_info           P                 品目別消費税率取得関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/21    1.0   SCS              新規作成
 *  2009/04/30    1.1   T.Kitajima       [T1_0710]get_delivered_from 出荷拠点コード取得方法変更
 *  2009/05/14    1.2   N.Maeda          [T1_0997]納品形態区分の導出方法修正
 *  2009/08/03    1.3   N.Maeda          [0000433]get_account_period,get_specific_masterの
 *                                                参照タイプコード取得時の不要なテーブル結合の削除
 *  2019/06/04    1.4   S.Kuwako         [E_本稼動_15472]軽減税率用の消費税率取得関数の追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
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
  global_get_profile_expt   EXCEPTION;     -- プロファイル
  global_nothing_expt       EXCEPTION;     -- 入力なし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS_COMMON_PKG';                -- パッケージ名
--
  --アプリケーション短縮名
  ct_xxcos_appl_short_name        CONSTANT  fnd_application.application_short_name%TYPE
                                            := 'XXCOS';                         -- 販物短縮アプリ名
  ct_xxcoi_appl_short_name        CONSTANT  fnd_application.application_short_name%TYPE
                                            := 'XXCOI';                         -- 在庫短縮アプリ名
  --プロファイルID
  ct_prof_organization_code       CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                            := 'XXCOI1_ORGANIZATION_CODE';      -- 組織コード
  ct_prof_gl_set_of_bks_id        CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                            := 'GL_SET_OF_BKS_ID';              -- GL会計帳簿ID
  --販物メッセージ
  ct_msg_get_profile_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00004';              -- プロファイル取得エラー
  ct_msg_require_param_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00006';              -- 必須入力パラメータ未設定エラー
  ct_msg_select_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00013';              -- データ抽出エラー
  ct_msg_call_api_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00017';              -- API呼出エラー
  ct_msg_in_param_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00019';              -- 入力パラメータ不正エラー
  ct_msg_prof_organization_code   CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00048';              -- XXCOI:在庫組織コード
  ct_msg_mtl_system_items         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00050';              -- 品目マスタ
  ct_msg_item_code                CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00054';              -- 品目コード
  ct_msg_mtl_uom_class_conv       CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00061';              -- 単位換算マスタ
  ct_msg_uom_code                 CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00062';              -- 単位コード
  --トークン
  cv_tkn_profile                  CONSTANT  VARCHAR2(100) := 'PROFILE';         -- プロファイル
  cv_tkn_in_param                 CONSTANT  VARCHAR2(100) := 'IN_PARAM';        -- 入力パラメータ
  cv_tkn_api_name                 CONSTANT  VARCHAR2(100) := 'API_NAME';        -- API名
  cv_tkn_table_name               CONSTANT  VARCHAR2(100) := 'TABLE_NAME';      -- テーブル名
  cv_tkn_key_data                 CONSTANT  VARCHAR2(100) := 'KEY_DATA';        -- キーデータ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_name_value_rtype
  IS
    RECORD(
      item_name                   VARCHAR2(5000),
      data_value                  VARCHAR2(5000)
    );
  --
  TYPE g_name_value_ttype
  IS
    TABLE OF
      g_name_value_rtype
    INDEX BY BINARY_INTEGER
    ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  --==================================
  -- プライベート･ファンクション
  --==================================
  -- 在庫組織コードの取得
  FUNCTION get_organization_code(
    in_organization_id        IN            NUMBER
  ) RETURN mtl_parameters.organization_code%TYPE
  IS
    lv_organization_code                mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
  BEGIN
    lv_organization_code                := NULL;
    --
    SELECT
      mp.organization_code              organization_code
    INTO
      lv_organization_code
    FROM
      mtl_parameters                    mp
    WHERE
      mp.organization_id                = in_organization_id
    ;
    --
    RETURN lv_organization_code;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;
--
  /**********************************************************************************
   * Procedure Name   : makeup_key_info
   * Description      : キー情報編集
   ***********************************************************************************/
  PROCEDURE makeup_key_info(
    iv_item_name1             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１
    iv_item_name2             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称２
    iv_item_name3             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称３
    iv_item_name4             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称４
    iv_item_name5             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称５
    iv_item_name6             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称６
    iv_item_name7             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称７
    iv_item_name8             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称８
    iv_item_name9             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称９
    iv_item_name10            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１０
    iv_item_name11            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１１
    iv_item_name12            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１２
    iv_item_name13            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１３
    iv_item_name14            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１４
    iv_item_name15            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１５
    iv_item_name16            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１６
    iv_item_name17            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１７
    iv_item_name18            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１８
    iv_item_name19            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１９
    iv_item_name20            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称２０
    iv_data_value1            IN            VARCHAR2  DEFAULT NULL,         -- データの値１
    iv_data_value2            IN            VARCHAR2  DEFAULT NULL,         -- データの値２
    iv_data_value3            IN            VARCHAR2  DEFAULT NULL,         -- データの値３
    iv_data_value4            IN            VARCHAR2  DEFAULT NULL,         -- データの値４
    iv_data_value5            IN            VARCHAR2  DEFAULT NULL,         -- データの値５
    iv_data_value6            IN            VARCHAR2  DEFAULT NULL,         -- データの値６
    iv_data_value7            IN            VARCHAR2  DEFAULT NULL,         -- データの値７
    iv_data_value8            IN            VARCHAR2  DEFAULT NULL,         -- データの値８
    iv_data_value9            IN            VARCHAR2  DEFAULT NULL,         -- データの値９
    iv_data_value10           IN            VARCHAR2  DEFAULT NULL,         -- データの値１０
    iv_data_value11           IN            VARCHAR2  DEFAULT NULL,         -- データの値１１
    iv_data_value12           IN            VARCHAR2  DEFAULT NULL,         -- データの値１２
    iv_data_value13           IN            VARCHAR2  DEFAULT NULL,         -- データの値１３
    iv_data_value14           IN            VARCHAR2  DEFAULT NULL,         -- データの値１４
    iv_data_value15           IN            VARCHAR2  DEFAULT NULL,         -- データの値１５
    iv_data_value16           IN            VARCHAR2  DEFAULT NULL,         -- データの値１６
    iv_data_value17           IN            VARCHAR2  DEFAULT NULL,         -- データの値１７
    iv_data_value18           IN            VARCHAR2  DEFAULT NULL,         -- データの値１８
    iv_data_value19           IN            VARCHAR2  DEFAULT NULL,         -- データの値１９
    iv_data_value20           IN            VARCHAR2  DEFAULT NULL,         -- データの値２０
    ov_key_info               OUT    NOCOPY VARCHAR2,                       -- キー情報
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ユーザー・エラー・メッセージ   #固定#
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'makeup_key_info'; -- プログラム名
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
    cn_param_count                  CONSTANT  NUMBER        := 20;              -- パラメータ項目数
    --
    cv_separator                    CONSTANT  VARCHAR2(10)  := ' : ';           -- セパレータ
    cv_paragraph                    CONSTANT  VARCHAR2(10)  := CHR(10);         -- 改行
    ct_msg_item_name                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13566';            -- 項目名称
--
    -- *** ローカル変数 ***
    l_name_value_tab                          g_name_value_ttype;
    lv_key_info                               VARCHAR2(5000);
    ln_idx1                                   PLS_INTEGER;
    --メッセージ用文字列
    lt_str_item_name                          fnd_new_messages.message_text%TYPE;
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
    --==============================================================
    --1.パラメータセット
    --==============================================================
    ln_idx1 := 0;
    <<loop_set_param>>
    LOOP
      --
      ln_idx1 := ln_idx1 + 1;
      --
      EXIT WHEN ln_idx1 > cn_param_count;
      --
      IF ( ln_idx1 = 1 ) THEN
        IF ( iv_item_name1 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name1;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value1;
        END IF;
      ELSIF ( ln_idx1 = 2 ) THEN
        IF ( iv_item_name2 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name2;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value2;
        END IF;
      ELSIF ( ln_idx1 = 3 ) THEN
        IF ( iv_item_name3 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name3;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value3;
        END IF;
      ELSIF ( ln_idx1 = 4 ) THEN
        IF ( iv_item_name4 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name4;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value4;
        END IF;
      ELSIF ( ln_idx1 = 5 ) THEN
        IF ( iv_item_name5 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name5;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value5;
        END IF;
      ELSIF ( ln_idx1 = 6 ) THEN
        IF ( iv_item_name6 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name6;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value6;
        END IF;
      ELSIF ( ln_idx1 = 7 ) THEN
        IF ( iv_item_name7 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name7;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value7;
        END IF;
      ELSIF ( ln_idx1 = 8 ) THEN
        IF ( iv_item_name8 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name8;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value8;
        END IF;
      ELSIF ( ln_idx1 = 9 ) THEN
        IF ( iv_item_name9 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name9;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value9;
        END IF;
      ELSIF ( ln_idx1 = 10 ) THEN
        IF ( iv_item_name10 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name10;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value10;
        END IF;
      ELSIF ( ln_idx1 = 11 ) THEN
        IF ( iv_item_name11 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name11;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value11;
        END IF;
      ELSIF ( ln_idx1 = 12 ) THEN
        IF ( iv_item_name12 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name12;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value12;
        END IF;
      ELSIF ( ln_idx1 = 13 ) THEN
        IF ( iv_item_name13 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name13;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value13;
        END IF;
      ELSIF ( ln_idx1 = 14 ) THEN
        IF ( iv_item_name14 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name14;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value14;
        END IF;
      ELSIF ( ln_idx1 = 15 ) THEN
        IF ( iv_item_name15 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name15;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value15;
        END IF;
      ELSIF ( ln_idx1 = 16 ) THEN
        IF ( iv_item_name16 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name16;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value16;
        END IF;
      ELSIF ( ln_idx1 = 17 ) THEN
        IF ( iv_item_name17 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name17;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value17;
        END IF;
      ELSIF ( ln_idx1 = 18 ) THEN
        IF ( iv_item_name18 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name18;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value18;
        END IF;
      ELSIF ( ln_idx1 = 19 ) THEN
        IF ( iv_item_name19 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name19;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value19;
        END IF;
      ELSIF ( ln_idx1 = 20 ) THEN
        IF ( iv_item_name20 IS NULL ) THEN
          ln_idx1 := cn_param_count;
        ELSE
          l_name_value_tab(ln_idx1).item_name     := iv_item_name20;
          l_name_value_tab(ln_idx1).data_value    := iv_data_value20;
        END IF;
      END IF;
--
    END LOOP loop_set_param;
--
    --==============================================================
    --2.パラメータチェック
    --==============================================================
    IF ( l_name_value_tab.COUNT = cn_param_count) THEN
      --
      ln_idx1 := l_name_value_tab.COUNT;
      --
      <<loop_check_param>>
      LOOP
        --
        ln_idx1 := ln_idx1 + 1;
        --
        EXIT WHEN ln_idx1 > cn_param_count;
        --
        IF ( ( ln_idx1 = 1 ) AND ( iv_item_name1 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 2 ) AND ( iv_item_name2 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 3 ) AND ( iv_item_name3 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 4 ) AND ( iv_item_name4 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 5 ) AND ( iv_item_name5 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 6 ) AND ( iv_item_name6 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 7 ) AND ( iv_item_name7 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 8 ) AND ( iv_item_name8 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 9 ) AND ( iv_item_name9 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 10 ) AND ( iv_item_name10 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 11 ) AND ( iv_item_name11 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 12 ) AND ( iv_item_name12 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 13 ) AND ( iv_item_name13 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 14 ) AND ( iv_item_name14 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 15 ) AND ( iv_item_name15 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 16 ) AND ( iv_item_name16 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 17 ) AND ( iv_item_name17 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 18 ) AND ( iv_item_name18 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 19 ) AND ( iv_item_name19 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        ELSIF ( ( ln_idx1 = 20 ) AND ( iv_item_name20 IS NOT NULL ) ) THEN
          lv_retcode := cv_status_error;
        END IF;
        --判定
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application        => ct_xxcos_appl_short_name,
                         iv_name               => ct_msg_in_param_err,
                         iv_token_name1        => cv_tkn_in_param,
                         iv_token_value1       => lt_str_item_name ||
                                                  cv_separator ||
                                                  TO_CHAR( ln_idx1 )
                       );
          ln_idx1 := cn_param_count;
        END IF;
--
      END LOOP loop_check_param;
--
    END IF;
--
    --エラーの場合、中断させる。
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --3.キー情報編集
    --==============================================================
    lv_key_info := NULL;
    --編集処理
    <<loop_makeup_key_info>>
    FOR i IN 1..l_name_value_tab.COUNT
    LOOP
      --改行の付加
      IF ( lv_key_info IS NOT NULL ) THEN
        lv_key_info := lv_key_info || cv_paragraph;
      END IF;
      --パラメータ編集
      lv_key_info := lv_key_info ||
                     l_name_value_tab(i).item_name ||
                     cv_separator ||
                     l_name_value_tab(i).data_value;
    END LOOP loop_makeup_key_info;
--
    --==============================================================
    --4.終了処理
    --==============================================================
    --キー情報返却
    ov_key_info := lv_key_info;
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
  END makeup_key_info;
--
--
  /************************************************************************
   * Procedure Name  : get_uom_cnv
   * Description     : 単位換算取得
   ************************************************************************/
  PROCEDURE get_uom_cnv(
    iv_before_uom_code        IN            VARCHAR2,                       -- 換算前単位コード
    in_before_quantity        IN            NUMBER,                         -- 換算前数量
    iov_item_code             IN OUT NOCOPY VARCHAR2,                       -- 品目コード
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- 在庫組織コード
    ion_inventory_item_id     IN OUT        NUMBER,                         -- 品目ＩＤ
    ion_organization_id       IN OUT        NUMBER,                         -- 在庫組織ＩＤ
    iov_after_uom_code        IN OUT NOCOPY VARCHAR2,                       -- 換算後単位コード
    on_after_quantity         OUT    NOCOPY NUMBER,                         -- 換算後数量
    on_content                OUT    NOCOPY NUMBER,                         -- 入数
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ユーザー・エラー・メッセージ   #固定#
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uom_cnv'; -- プログラム名
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
    --販物メッセージ
    ct_msg_get_organization_id      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13559';            -- 在庫組織ID取得
    ct_msg_organization_id          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13560';            -- 在庫組織ID
    ct_msg_mtl_parameters           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13561';            -- 在庫組織パラメータ
    ct_msg_organization_code        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13552';            -- 在庫組織コード
    ct_msg_before_uom_code          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13562';            -- 換算前単位コード
    ct_msg_item_cd_item_id          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13567';            -- 品目コードまたは品目ＩＤ
    ct_msg_uom_mst_err              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13588';            -- 単位マスタ未登録
    --
    -- トークン
    cv_tkn_uom_code                 CONSTANT  VARCHAR2(100) := 'UOM_CODE';
    -- 定数
    cn_0                            CONSTANT  NUMBER        := 0;
--
    -- *** ローカル変数 ***
    lt_primary_uom_code                       mtl_system_items_b.primary_uom_code%TYPE;          -- 基準単位
    lt_conversion_rate                        mtl_uom_class_conversions.conversion_rate%TYPE;    -- 換算率
    lt_pre_conversion_rate                    mtl_uom_class_conversions.conversion_rate%TYPE;    -- 換算率
    lt_aft_conversion_rate                    mtl_uom_class_conversions.conversion_rate%TYPE;    -- 換算率
    lt_base_conversion_rate                   mtl_uom_class_conversions.conversion_rate%TYPE;    -- 換算率(品目単位)
    lv_uom_class                              mtl_units_of_measure.uom_class%TYPE;
    lv_base_uom_flag                          mtl_units_of_measure.base_uom_flag%TYPE;
    lv_base_uom_code                          mtl_units_of_measure.uom_code%TYPE;
    lv_before_uom_class                       mtl_units_of_measure.uom_class%TYPE;
    lv_before_uom_code                        mtl_units_of_measure.uom_code%TYPE;
    lv_after_uom_class                        mtl_units_of_measure.uom_class%TYPE;
    lv_after_uom_code                         mtl_units_of_measure.uom_code%TYPE;
    ln_quantity                               NUMBER;
    ln_content                                NUMBER;
    lv_key_info                               VARCHAR2(5000);
    --
    lv_no_data_flag                           VARCHAR2(1);
    --メッセージ用文字列
    lt_str_prof_organization_code             fnd_new_messages.message_text%TYPE;
    lt_str_get_organization_id                fnd_new_messages.message_text%TYPE;
    lt_str_organization_id                    fnd_new_messages.message_text%TYPE;
    lt_str_mtl_parameters                     fnd_new_messages.message_text%TYPE;
    lt_str_organization_code                  fnd_new_messages.message_text%TYPE;
    lt_str_before_uom_code                    fnd_new_messages.message_text%TYPE;
    lt_str_item_cd_item_id                    fnd_new_messages.message_text%TYPE;
    lt_str_mtl_system_items                   fnd_new_messages.message_text%TYPE;
    lt_str_item_code                          fnd_new_messages.message_text%TYPE;
    lt_str_mtl_uom_class_conv                 fnd_new_messages.message_text%TYPE;
    lt_str_uom_code                           fnd_new_messages.message_text%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    --==============================================================
    --1.引数チェック
    --==============================================================
    --==================================
    --1-1.換算前単位コードが
    --    NULLの場合エラー
    --==================================
    IF ( iv_before_uom_code IS NULL ) THEN
      lt_str_before_uom_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_before_uom_code
                                           );                      -- 換算前単位コード
      lv_errmsg                         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_require_param_err,
                                             iv_token_name1        => cv_tkn_in_param,
                                             iv_token_value1       => lt_str_before_uom_code
                                           );
      lv_errbuf                         := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --==================================
    --1-2.換算前数量がNULLの場合「0」に変換
    --==================================
    ln_quantity := NVL( in_before_quantity, 0 );
    --==================================
    --1-3.在庫組織コードおよび在庫組織ＩＤが
    --    NULLの場合、在庫組織コードを取得
    --==================================
    IF ( ( iov_organization_code IS NULL )
      AND ( ion_organization_id IS NULL ) )
    THEN
      --==================================
      -- 1-3-1. 在庫組織コードの取得
      --==================================
      iov_organization_code             := FND_PROFILE.VALUE( ct_prof_organization_code );
      --
      IF ( iov_organization_code        IS NULL ) THEN
        lt_str_prof_organization_code   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_prof_organization_code
                                           );                      -- XXCOI:在庫組織コード
        lv_errmsg                       := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_profile_err,
                                             iv_token_name1        => cv_tkn_profile,
                                             iv_token_value1       => lt_str_prof_organization_code
                                           );
        lv_errbuf                       := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- 1-3-2. 在庫組織ＩＤの取得
      --==================================
      ion_organization_id               := xxcoi_common_pkg.get_organization_id(
                                             iov_organization_code
                                           );
      --
      IF ( ion_organization_id IS NULL ) THEN
        lt_str_get_organization_id      := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- 在庫組織ID取得
        lv_errmsg                       := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
    ELSE
      IF ( iov_organization_code IS NULL ) THEN
        --==================================
        -- 1-3-3. 在庫組織コードの取得
        --==================================
        iov_organization_code           := get_organization_code(
                                              ion_organization_id
                                            );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lt_str_organization_id        := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_id
                                           );                      -- 在庫組織ID
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,             -- エラー・メッセージ
            ov_retcode                  => lv_retcode,            -- リターンコード
            ov_errmsg                   => lv_errmsg,             -- ユーザ・エラー・メッセージ
            ov_key_info                 => lv_key_info,           -- 編集されたキー情報
            iv_item_name1               => lt_str_organization_id,
            iv_data_value1              => TO_CHAR( ion_organization_id )
          );
          --
          lt_str_mtl_parameters         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_parameters
                                           );                      -- 在庫組織パラメータ
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_parameters,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      ELSE
        --==================================
        -- 1-3-4. 在庫組織ＩＤの取得
        --==================================
        ion_organization_id             := xxcoi_common_pkg.get_organization_id(
                                             iov_organization_code
                                           );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lt_str_get_organization_id    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- 在庫組織ID取得
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      END IF;
    END IF;
    --==================================
    --1-4.品目コードおよび品目ＩＤが
    --    NULLの場合エラー
    --==================================
    IF ( ( iov_item_code IS NULL )
      AND ( ion_inventory_item_id IS NULL ) )
    THEN
      lt_str_item_cd_item_id            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_cd_item_id
                                           );                      -- 品目コードまたは品目ＩＤ
      lv_errmsg                         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_require_param_err,
                                             iv_token_name1        => cv_tkn_in_param,
                                             iv_token_value1       => lt_str_item_cd_item_id
                                           );
      lv_errbuf                         := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      IF (iov_item_code IS NULL ) THEN
        --==================================
        -- 1-4-1. 品目コードの取得
        --==================================
        BEGIN
          SELECT
            msib.segment1               item_code,                   -- 品目コード
            msib.primary_uom_code       primary_uom_code,            -- 品目基準単位
            muom.uom_class              uom_class,                   -- 単位区分
            muom.base_uom_flag          base_uom_flag                -- 基準単位フラグ
          INTO
            iov_item_code,
            lt_primary_uom_code,
            lv_uom_class,
            lv_base_uom_flag
          FROM
            mtl_system_items_b          msib,
            mtl_units_of_measure_tl     muom
          WHERE  msib.organization_id      = ion_organization_id
          AND    msib.inventory_item_id    = ion_inventory_item_id
          AND    msib.primary_uom_code     = muom.uom_code
          AND    muom.language             = userenv('lang')
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_str_organization_code    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_code
                                           );                      -- 在庫組織コード
            lt_str_item_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- 品目コード
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                 => lv_errbuf,              -- エラー・メッセージ
              ov_retcode                => lv_retcode,             -- リターンコード
              ov_errmsg                 => lv_errmsg,              -- ユーザ・エラー・メッセージ
              ov_key_info               => lv_key_info,            -- 編集されたキー情報
              iv_item_name1             => lt_str_organization_code,
              iv_data_value1            => iov_organization_code,
              iv_item_name2             => lt_str_item_code,
              iv_data_value2            => iov_item_code
            );
            --
            lt_str_mtl_system_items     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_system_items
                                           );                      -- 品目マスタ
            lv_errmsg                   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_system_items,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
            lv_errbuf                   := lv_errmsg;
            RAISE global_api_expt;
        END;
      ELSE
        --==================================
        -- 1-4-2. 品目ＩＤの取得
        --==================================
        BEGIN
          SELECT
            msib.inventory_item_id      inventory_item_id,
            msib.primary_uom_code       primary_uom_code,
            muom.uom_class              uom_class,                   -- 単位区分
            muom.base_uom_flag          base_uom_flag                -- 基準単位フラグ
          INTO
            ion_inventory_item_id,
            lt_primary_uom_code,
            lv_uom_class,
            lv_base_uom_flag
          FROM
            mtl_system_items_b          msib,
            mtl_units_of_measure_tl     muom
          WHERE  msib.organization_id      = ion_organization_id
          AND    msib.segment1             = iov_item_code
          AND    msib.primary_uom_code     = muom.uom_code
          AND    muom.language             = userenv('lang')
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lt_str_organization_code    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_code
                                           );                      -- 在庫組織コード
            lt_str_item_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- 品目コード
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                 => lv_errbuf,              -- エラー・メッセージ
              ov_retcode                => lv_retcode,             -- リターンコード
              ov_errmsg                 => lv_errmsg,              -- ユーザ・エラー・メッセージ
              ov_key_info               => lv_key_info,            -- 編集されたキー情報
              iv_item_name1             => lt_str_organization_code,
              iv_data_value1            => iov_organization_code,
              iv_item_name2             => lt_str_item_code,
              iv_data_value2            => iov_item_code
            );
            --
            lt_str_mtl_system_items     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_system_items
                                           );                      -- 品目マスタ
            lv_errmsg                   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_system_items,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
            lv_errbuf                   := lv_errmsg;
            RAISE global_api_expt;
        END;
      END IF;
    END IF;
    --==============================================================
    --2.換算処理
    --==============================================================
    --==================================
    --2-1.基準単位コードと換算前コード単位の比較
    --==================================
    IF ( lt_primary_uom_code = iv_before_uom_code ) THEN
      --==================================
      --2-1-1.同じ場合
      --==================================
      ln_content := 1;
    ELSE
      --==================================
      --2-1-2.異なる場合
      --==================================
      lt_conversion_rate := NULL;
      --
      BEGIN
        SELECT
          mucc.conversion_rate          conversion_rate  -- 換算レート
        INTO
          lt_conversion_rate
        FROM
          mtl_uom_class_conversions     mucc             -- 区分間単位換算
        WHERE
          mucc.inventory_item_id        = ion_inventory_item_id    -- 品目ID
        AND mucc.to_uom_code            = iv_before_uom_code       -- 換算先単位コード(基準単位からの換算先)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 区分間単位換算テーブルにない場合
          lv_no_data_flag := 'Y';
        WHEN OTHERS THEN
          lt_str_item_code              := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- 品目コード
          lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_uom_code
                                           );                      -- 単位コード
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
            ov_retcode                  => lv_retcode,             -- リターンコード
            ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
            ov_key_info                 => lv_key_info,            -- 編集されたキー情報
            iv_item_name1               => lt_str_item_code,
            iv_data_value1              => iov_item_code,
            iv_item_name2               => lt_str_uom_code,
            iv_data_value2              => iv_before_uom_code
          );
          --
          lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_uom_class_conv
                                           );                      -- 単位換算マスタ
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_uom_class_conv,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
      END;
      --
      -- 区分間単位換算テーブルにない場合
      IF ( lv_no_data_flag = 'Y' ) THEN
        -- 2008/12/25 区分間単位換算テーブルの振り分け
        -- 換算前単位コードの単位区分
        BEGIN
          SELECT  muom.uom_class            uom_class          -- 単位区分
          INTO    lv_before_uom_class
          FROM    mtl_units_of_measure_tl  muom
          WHERE   muom.uom_code   =  iv_before_uom_code
          AND     muom.language   =  userenv('lang');
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            lv_errmsg                     := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_uom_mst_err,
                                               iv_token_name1        => cv_tkn_uom_code,
                                               iv_token_value1       => iv_before_uom_code
                                             );
            lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
          WHEN  OTHERS THEN
            RAISE  global_api_others_expt;
        END;
        --
        -- 単位区分の比較
        IF ( lv_uom_class = lv_before_uom_class ) THEN
          -- 同一単位区分の場合、換算前単位と品目基準単位との換算レートを算出する
          -- (1) 換算前単位と基準単位との換算レートを取得する
          BEGIN
            SELECT  muc.conversion_rate          conversion_rate
            INTO    lt_pre_conversion_rate
            FROM    mtl_uom_conversions     muc
            WHERE   muc.uom_code          = iv_before_uom_code
              AND   muc.inventory_item_id = cn_0
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_item_code
                                               );                      -- 品目コード
              lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_code
                                               );                      -- 単位コード
              --
              xxcos_common_pkg.makeup_key_info(
                ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
                ov_retcode                  => lv_retcode,             -- リターンコード
                ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
                ov_key_info                 => lv_key_info,            -- 編集されたキー情報
                iv_item_name1               => lt_str_item_code,
                iv_data_value1              => iov_item_code,
                iv_item_name2               => lt_str_uom_code,
                iv_data_value2              => iv_before_uom_code
              );
              --
              lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_mtl_uom_class_conv
                                               );                      -- 単位換算マスタ
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_select_err,
                                                 iv_token_name1        => cv_tkn_table_name,
                                                 iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                 iv_token_name2        => cv_tkn_key_data,
                                                 iv_token_value2       => lv_key_info
                                               );
              lv_errbuf                     := lv_errmsg;
              RAISE  global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          --
          -- (2) 品目の主単位と基準単位との換算レートを取得する
          BEGIN
            SELECT  muc.conversion_rate          conversion_rate
            INTO    lt_base_conversion_rate
            FROM    mtl_uom_conversions     muc
            WHERE   muc.uom_code          = lt_primary_uom_code
              AND   muc.inventory_item_id = cn_0
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_item_code
                                               );                      -- 品目コード
              lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_code
                                               );                      -- 単位コード
              --
              xxcos_common_pkg.makeup_key_info(
                ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
                ov_retcode                  => lv_retcode,             -- リターンコード
                ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
                ov_key_info                 => lv_key_info,            -- 編集されたキー情報
                iv_item_name1               => lt_str_item_code,
                iv_data_value1              => iov_item_code,
                iv_item_name2               => lt_str_uom_code,
                iv_data_value2              => iv_before_uom_code
              );
              --
              lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_mtl_uom_class_conv
                                               );                      -- 単位換算マスタ
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_select_err,
                                                 iv_token_name1        => cv_tkn_table_name,
                                                 iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                 iv_token_name2        => cv_tkn_key_data,
                                                 iv_token_value2       => lv_key_info
                                               );
              lv_errbuf                     := lv_errmsg;
              RAISE  global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          --
          -- (1)と(2)の結果を割り、換算レートを求める
          lt_conversion_rate     := lt_pre_conversion_rate / lt_base_conversion_rate;
        ELSE
          lt_str_item_code              := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- 品目コード
          lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_uom_code
                                           );                      -- 単位コード
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
            ov_retcode                  => lv_retcode,             -- リターンコード
            ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
            ov_key_info                 => lv_key_info,            -- 編集されたキー情報
            iv_item_name1               => lt_str_item_code,
            iv_data_value1              => iov_item_code,
            iv_item_name2               => lt_str_uom_code,
            iv_data_value2              => iv_before_uom_code
          );
          --
          lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_uom_class_conv
                                           );                      -- 単位換算マスタ
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_uom_class_conv,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      END IF;
      --
      ln_quantity             := ln_quantity * lt_conversion_rate;
      ln_content              := lt_conversion_rate;
    END IF;
    --==================================
    --2-2.換算後単位コードがNULLか否か
    --==================================
    IF ( iov_after_uom_code IS NULL ) THEN
      --==================================
      --2-2-1.NULLの場合
      --==================================
      -- 基準単位(バラ)へ換算
      iov_after_uom_code      := lt_primary_uom_code;
      on_after_quantity       := ln_quantity;
      on_content              := ln_content;
    ELSE
      IF ( lt_primary_uom_code = iov_after_uom_code ) THEN
        --==================================
        --2-2-2-1.NULLでなく、基準単位と同じ場合
        --==================================
        iov_after_uom_code      := lt_primary_uom_code;
        on_after_quantity       := ln_quantity;
        on_content              := ln_content;
      ELSE
        --==================================
        --2-2-2-2.NULLでなく、基準単位と異なる場合
        --==================================
        lt_conversion_rate      := NULL;
        --
        BEGIN
          SELECT
            mucc.conversion_rate        conversion_rate
          INTO
            lt_conversion_rate
          FROM
            mtl_uom_class_conversions   mucc
          WHERE
            mucc.inventory_item_id      = ion_inventory_item_id
          AND mucc.to_uom_code          = iov_after_uom_code
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 区分間単位換算テーブルにない場合
            lv_no_data_flag := 'Y';
          WHEN OTHERS THEN
            lt_str_item_code            := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_item_code
                                           );                      -- 品目コード
            lt_str_uom_code             := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_uom_code
                                           );                      -- 単位コード
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                 => lv_errbuf,              -- エラー・メッセージ
              ov_retcode                => lv_retcode,             -- リターンコード
              ov_errmsg                 => lv_errmsg,              -- ユーザ・エラー・メッセージ
              ov_key_info               => lv_key_info,            -- 編集されたキー情報
              iv_item_name1             => lt_str_item_code,
              iv_data_value1            => iov_item_code,
              iv_item_name2             => lt_str_uom_code,
              iv_data_value2            => iov_after_uom_code
            );
            --
            lt_str_mtl_uom_class_conv   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_uom_class_conv
                                           );                      -- 単位換算マスタ
            lv_errmsg                   := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_uom_class_conv,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
            lv_errbuf                   := lv_errmsg;
            RAISE global_api_expt;
        END;
        --
        IF ( lv_no_data_flag = 'Y' ) THEN
          -- 2008/12/25 単位換算テーブルの振り分け
          -- 換算前単位コードの単位区分
          BEGIN
            SELECT  muom.uom_class            uom_class          -- 単位区分
            INTO    lv_before_uom_class
            FROM    mtl_units_of_measure_tl  muom
            WHERE   muom.uom_code   =  iv_before_uom_code
            AND     muom.language   =  userenv('lang');
          EXCEPTION
          WHEN  NO_DATA_FOUND THEN
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_mst_err,
                                                 iv_token_name1        => cv_tkn_uom_code,
                                                 iv_token_value1       => iv_before_uom_code
                                               );
              lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          --
          -- 換算後単位コードの単位区分
          BEGIN
            SELECT  muom.uom_class            uom_class          -- 単位区分
            INTO    lv_after_uom_class
            FROM    mtl_units_of_measure_tl  muom
            WHERE   muom.uom_code   =  iov_after_uom_code
            AND     muom.language   =  userenv('lang');
          EXCEPTION
          WHEN  NO_DATA_FOUND THEN
              lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                 iv_application        => ct_xxcos_appl_short_name,
                                                 iv_name               => ct_msg_uom_mst_err,
                                                 iv_token_name1        => cv_tkn_uom_code,
                                                 iv_token_value1       => iov_after_uom_code
                                               );
              lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
            WHEN  OTHERS THEN
              RAISE  global_api_others_expt;
          END;
          -- 単位区分の比較
          IF ( lv_before_uom_class = lv_after_uom_class ) THEN
            -- 同一単位区分の場合、換算前単位と換算後単位との換算レートを算出する
            -- (2) 換算後単位と基準単位との換算レートを取得する
            BEGIN
              SELECT  muc.conversion_rate          conversion_rate
              INTO    lt_aft_conversion_rate
              FROM    mtl_uom_conversions     muc
              WHERE   muc.uom_code          = iov_after_uom_code
                AND   muc.inventory_item_id = cn_0
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_item_code
                                                 );                      -- 品目コード
                lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_uom_code
                                                 );                      -- 単位コード
                --
                xxcos_common_pkg.makeup_key_info(
                  ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
                  ov_retcode                  => lv_retcode,             -- リターンコード
                  ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
                  ov_key_info                 => lv_key_info,            -- 編集されたキー情報
                  iv_item_name1               => lt_str_item_code,
                  iv_data_value1              => iov_item_code,
                  iv_item_name2               => lt_str_uom_code,
                  iv_data_value2              => iov_after_uom_code
                );
                --
                lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_mtl_uom_class_conv
                                                 );                      -- 単位換算マスタ
                lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                   iv_application        => ct_xxcos_appl_short_name,
                                                   iv_name               => ct_msg_select_err,
                                                   iv_token_name1        => cv_tkn_table_name,
                                                   iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                   iv_token_name2        => cv_tkn_key_data,
                                                   iv_token_value2       => lv_key_info
                                                 );
                lv_errbuf                     := lv_errmsg;
                RAISE  global_api_expt;
              WHEN  OTHERS THEN
                RAISE  global_api_others_expt;
            END;
            --
            --
            IF ( lt_base_conversion_rate IS NULL ) THEN
              -- 品目の主単位と基準単位との換算レートがNULLならば取得する
              BEGIN
                SELECT  muc.conversion_rate          conversion_rate
                INTO    lt_base_conversion_rate
                FROM    mtl_uom_conversions     muc
                WHERE   muc.uom_code          = lt_primary_uom_code
                  AND   muc.inventory_item_id = cn_0
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lt_str_item_code              := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_item_code
                                                   );                      -- 品目コード
                  lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_uom_code
                                                   );                      -- 単位コード
                  --
                  xxcos_common_pkg.makeup_key_info(
                    ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
                    ov_retcode                  => lv_retcode,             -- リターンコード
                    ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
                    ov_key_info                 => lv_key_info,            -- 編集されたキー情報
                    iv_item_name1               => lt_str_item_code,
                    iv_data_value1              => iov_item_code,
                    iv_item_name2               => lt_str_uom_code,
                    iv_data_value2              => iv_before_uom_code
                  );
                  --
                  lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_mtl_uom_class_conv
                                                   );                      -- 単位換算マスタ
                  lv_errmsg                     := xxccp_common_pkg.get_msg(
                                                     iv_application        => ct_xxcos_appl_short_name,
                                                     iv_name               => ct_msg_select_err,
                                                     iv_token_name1        => cv_tkn_table_name,
                                                     iv_token_value1       => lt_str_mtl_uom_class_conv,
                                                     iv_token_name2        => cv_tkn_key_data,
                                                     iv_token_value2       => lv_key_info
                                                   );
                  lv_errbuf                     := lv_errmsg;
                  RAISE  global_api_expt;
                WHEN  OTHERS THEN
                  RAISE  global_api_others_expt;
              END;
            END IF;
            --
            -- (1)と(2)の結果を割り、換算レートを求める
            lt_conversion_rate := lt_aft_conversion_rate / lt_base_conversion_rate;
            --
          ELSE
            lt_str_item_code              := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_item_code
                                             );                      -- 品目コード
            lt_str_uom_code               := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_uom_code
                                             );                      -- 単位コード
            --
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
              ov_retcode                  => lv_retcode,             -- リターンコード
              ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
              ov_key_info                 => lv_key_info,            -- 編集されたキー情報
              iv_item_name1               => lt_str_item_code,
              iv_data_value1              => iov_item_code,
              iv_item_name2               => lt_str_uom_code,
              iv_data_value2              => iov_after_uom_code
            );
            --
            lt_str_mtl_uom_class_conv     := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_mtl_uom_class_conv
                                             );                      -- 単位換算マスタ
            lv_errmsg                     := xxccp_common_pkg.get_msg(
                                               iv_application        => ct_xxcos_appl_short_name,
                                               iv_name               => ct_msg_select_err,
                                               iv_token_name1        => cv_tkn_table_name,
                                               iv_token_value1       => lt_str_mtl_uom_class_conv,
                                               iv_token_name2        => cv_tkn_key_data,
                                               iv_token_value2       => lv_key_info
                                             );
            lv_errbuf                     := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
        --
        --
        on_after_quantity       := ln_quantity / lt_conversion_rate;
        on_content              := lt_conversion_rate;
      END IF;
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
  END get_uom_cnv;
--
  /************************************************************************
   * Procedure Name  : get_delivered_from
   * Description     : 納品形態取得
   ************************************************************************/
  PROCEDURE get_delivered_from(
    iv_subinventory_code      IN            VARCHAR2,                       -- 保管場所コード,
    iv_sales_base_code        IN            VARCHAR2,                       -- 売上拠点コード,
    iv_ship_base_code         IN            VARCHAR2,                       -- 出荷拠点コード,
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- 在庫組織コード
    ion_organization_id       IN OUT        NUMBER,                         -- 在庫組織ＩＤ
    ov_delivered_from         OUT    NOCOPY VARCHAR2,                       -- 納品形態
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ユーザー・エラー・メッセージ   #固定#
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivered_from'; -- プログラム名
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
  --販物メッセージ
    cv_msg_mem13559_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13559';   -- 在庫組織ID取得
    cv_msg_mem13560_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13560';   -- 在庫組織ID
    cv_msg_mem13561_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13561';   -- 在庫組織パラメータ
    cv_msg_mem13562_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13562';   -- 在庫組織コード
    cv_msg_mem13563_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00052';   -- 保管場所マスタ
    cv_msg_mem13564_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13563';   -- 保管場所コード
    cv_msg_mem13565_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13564';   -- 売上拠点
    cv_msg_mem13566_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13565';   -- 出荷拠点
  --メッセージ用文字列
    cv_str_get_organization_id  CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13559_date
                                                         );                    -- 在庫組織ID取得
    cv_str_organization_id      CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13560_date
                                                         );                    -- 在庫組織ID
    cv_str_mtl_parameters       CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13561_date
                                                         );                    -- 在庫組織パラメータ
    cv_str_organization_code    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13562_date
                                                         );                    -- 在庫組織コード
    cv_str_mtl_secondary_inv    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13563_date
                                                         );                    -- 保管場所マスタ
    cv_str_subinventory_code    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13564_date
                                                         );                    -- 保管場所コード
    cv_str_sales_base           CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13565_date
                                                         );                    -- 売上拠点
    cv_str_ship_base            CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                            iv_application        =>  ct_xxcos_appl_short_name
                                                           ,iv_name               =>  cv_msg_mem13566_date
                                                         );                    -- 出荷拠点
    --クイックコードタイプ
    ct_qct_delivered_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_DELIVERED_MST';           -- 納品形態区分特定マスタ
    --クイックコード
    ct_qcc_car                  CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'CAR';                           -- 営業車
    ct_qcc_direct               CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'DIRECT';                        -- 工場直送
    ct_qcc_main                 CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'MAIN';                          -- メイン倉庫
    ct_qcc_other                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'OTHER';                         -- 他倉庫
    ct_qcc_sales                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          :=  'SALES';                         -- 他拠点倉庫売上
    --メイン倉庫フラグ
    ct_main_subinv_flag_yes   CONSTANT  mtl_secondary_inventories.attribute6%TYPE
                                        :=  'Y';                                           --メイン倉庫である
    --保管場所分類
    ct_subinv_type_sales_car  CONSTANT  mtl_secondary_inventories.attribute13%TYPE
                                        :=  '5';                                           --営業車
    ct_subinv_type_direct     CONSTANT  mtl_secondary_inventories.attribute13%TYPE
                                        :=  '11';                                          --直送
    --納品形態
    cv_delivered_from_car     CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_car
                                                          );                               --営業車
    cv_delivered_from_direct  CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_direct
                                                          );                               --工場直送
    cv_delivered_from_main    CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_main
                                                          );                               --メイン倉庫
    cv_delivered_from_other   CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_other
                                                          );                               --他倉庫
    cv_delivered_from_sales   CONSTANT   VARCHAR2(1)  :=  xxcos_common_pkg.get_specific_master(
                                                             it_lookup_type        => ct_qct_delivered_type
                                                            ,it_lookup_code        => ct_qcc_sales
                                                          );                               --他拠点倉庫売上
--
    -- *** ローカル変数 ***
    lt_main_subinv_flag                 mtl_secondary_inventories.attribute6%TYPE;         -- メイン倉庫
    lt_subinv_type                      mtl_secondary_inventories.attribute13%TYPE;        -- 保管場所分類
--****************************** 2009/04/30 1.1 T.Kitajima ADD START ******************************--
    lt_ship_base_code                   mtl_secondary_inventories.attribute7%TYPE;         -- 出荷拠点コード
--****************************** 2009/04/30 1.1 T.Kitajima ADD  END  ******************************--
    lv_key_info                         VARCHAR2(5000);
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
    --==============================================================
    --0.初期化
    --==============================================================
    ov_delivered_from         :=  NULL;
--
    --==============================================================
    --1.引数チェック
    --==============================================================
    --==================================
    --1-1.パラメータチェック
    --==================================
    --==================================
    --1-1-1.保管場所コードチェック
    --==================================
    IF ( iv_subinventory_code IS NULL ) THEN
      lv_key_info := cv_str_subinventory_code;
      RAISE global_nothing_expt;
    END IF;
    --==================================
    --1-1-2.売上拠点チェック
    --==================================
    IF ( iv_sales_base_code IS NULL ) THEN
      lv_key_info := cv_str_sales_base;
      RAISE global_nothing_expt;
    END IF;
--****************************** 2009/04/30 1.1 T.Kitajima DEL START ******************************--
--    --==================================
--    --1-1-3.出荷拠点チェック
--    --==================================
--    IF ( iv_ship_base_code IS NULL ) THEN
--      lv_key_info := cv_str_ship_base;
--      RAISE global_nothing_expt;
--    END IF;
--****************************** 2009/04/30 1.1 T.Kitajima DEL  END  ******************************--
    --==================================
    --1-2.在庫組織コードおよび在庫組織ＩＤが
    --    NULLの場合、在庫組織コードを取得
    --==================================
    IF ( ( iov_organization_code IS NULL )
      AND ( ion_organization_id  IS NULL ) ) THEN
        --==================================
        -- 1-2-1. 在庫組織コードの取得
        --==================================
        iov_organization_code           :=  FND_PROFILE.VALUE( ct_prof_organization_code );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_get_profile_err,
                                    iv_token_name1        =>  cv_tkn_profile,
                                    iv_token_value1       =>  ct_prof_organization_code
                                  );
          RAISE global_api_expt;
        END IF;
        --==================================
        -- 1-2-2. 在庫組織ＩＤの取得
        --==================================
        ion_organization_id             :=  xxcoi_common_pkg.get_organization_id(
                                              iov_organization_code
                                            );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_call_api_err,
                                    iv_token_name1        =>  cv_tkn_api_name,
                                    iv_token_value1       =>  cv_str_get_organization_id
                                  );
          RAISE global_api_expt;
        END IF;
        --
    ELSE
      IF ( iov_organization_code IS NULL ) THEN
        --==================================
        -- 1-2-3. 在庫組織コードの取得
        --==================================
        iov_organization_code           :=  get_organization_code(
                                              ion_organization_id
                                            );
        --
        IF ( iov_organization_code IS NULL ) THEN
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf         =>  lv_errbuf,         --エラー・メッセージ
            ov_retcode        =>  lv_retcode,        --リターンコード
            ov_errmsg         =>  lv_errmsg,         --ユーザ・エラー・メッセージ
            ov_key_info       =>  lv_key_info,       --編集されたキー情報
            iv_item_name1     =>  cv_str_organization_id,
            iv_data_value1    =>  TO_CHAR( ion_organization_id )
          );
          --
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_select_err,
                                    iv_token_name1        =>  cv_tkn_table_name,
                                    iv_token_value1       =>  cv_str_mtl_parameters,
                                    iv_token_name2        =>  cv_tkn_key_data,
                                    iv_token_value2       =>  lv_key_info
                                  );
          RAISE global_api_expt;
        END IF;
        --
      ELSE
        --==================================
        -- 1-2-4. 在庫組織ＩＤの取得
        --==================================
        ion_organization_id             :=  xxcoi_common_pkg.get_organization_id(
                                              iov_organization_code
                                            );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                    iv_application        =>  ct_xxcos_appl_short_name,
                                    iv_name               =>  ct_msg_call_api_err,
                                    iv_token_name1        =>  cv_tkn_api_name,
                                    iv_token_value1       =>  cv_str_get_organization_id
                                  );
          RAISE global_api_expt;
        END IF;
        --
      END IF;
    END IF;
--
    --==============================================================
    --2.保管場所情報取得
    --==============================================================
    BEGIN
--****************************** 2009/04/30 1.1 T.Kitajima MOD START ******************************--
--      SELECT msi.attribute6                main_subinv_class,
--             msi.attribute13               subinv_type
--             msi.attribute13               subinv_type,
--      INTO   lt_main_subinv_flag,
--             lt_subinv_type
--      FROM   mtl_secondary_inventories     msi
--      WHERE  msi.secondary_inventory_name  =   iv_subinventory_code
--      AND    msi.organization_id           =   ion_organization_id
--
      SELECT msi.attribute6                main_subinv_class,
             msi.attribute13               subinv_type,
             msi.attribute7                ship_base_code
      INTO   lt_main_subinv_flag,
             lt_subinv_type,
             lt_ship_base_code
      FROM   mtl_secondary_inventories     msi
      WHERE  msi.secondary_inventory_name  =   iv_subinventory_code
      AND    msi.organization_id           =   ion_organization_id
--****************************** 2009/04/30 1.1 T.Kitajima MOD  END  ******************************--
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        xxcos_common_pkg.makeup_key_info(
          ov_errbuf         =>  lv_errbuf,         --エラー・メッセージ
          ov_retcode        =>  lv_retcode,        --リターンコード
          ov_errmsg         =>  lv_errmsg,         --ユーザ・エラー・メッセージ
          ov_key_info       =>  lv_key_info,       --編集されたキー情報
          iv_item_name1     =>  cv_str_subinventory_code,
          iv_data_value1    =>  iv_subinventory_code,
          iv_item_name2     =>  cv_str_organization_code,
          iv_data_value2    =>  iov_organization_code
        );
        --
        lv_errmsg           :=  xxccp_common_pkg.get_msg(
                                  iv_application        =>  ct_xxcos_appl_short_name,
                                  iv_name               =>  ct_msg_select_err,
                                  iv_token_name1        =>  cv_tkn_table_name,
                                  iv_token_value1       =>  cv_str_mtl_secondary_inv,
                                  iv_token_name2        =>  cv_tkn_key_data,
                                  iv_token_value2       =>  lv_key_info
                                );
        RAISE global_api_expt;
    END;
--
--****************************** 2009/05/14 1.2 N.Maeda MOD START ******************************--
--    --==============================================================
--    --3.納品形態返却
--    --==============================================================
--    IF ( lt_main_subinv_flag = ct_main_subinv_flag_yes ) THEN
--        ov_delivered_from     :=  cv_delivered_from_main;             --メイン倉庫
--    ELSE
--      IF ( lt_subinv_type = ct_subinv_type_sales_car ) THEN
--        ov_delivered_from     :=  cv_delivered_from_car;              --営業車
--      ELSIF ( lt_subinv_type = ct_subinv_type_direct ) THEN
--        ov_delivered_from     :=  cv_delivered_from_direct;           --工場直送
----****************************** 2009/04/30 1.1 T.Kitajima MOD START ******************************--
----      ELSIF ( iv_sales_base_code != iv_ship_base_code ) THEN
--      ELSIF ( iv_sales_base_code != lt_ship_base_code ) THEN
----****************************** 2009/04/30 1.1 T.Kitajima MOD  END  ******************************--
--        ov_delivered_from     :=  cv_delivered_from_sales;            --他拠点倉庫売上
--      ELSE
--        ov_delivered_from     :=  cv_delivered_from_other;            --他倉庫
--      END IF;
--    END IF;
    --==============================================================
    --3.納品形態返却
    --==============================================================
    -- 売上拠点 = 保管場所の拠点の場合
    IF ( iv_sales_base_code = lt_ship_base_code )  THEN
      --メイン倉庫の場合
      IF ( lt_main_subinv_flag = ct_main_subinv_flag_yes ) THEN
        ov_delivered_from  :=  cv_delivered_from_main;      --メイン倉庫
      --営業車の場合
      ELSIF ( lt_subinv_type = ct_subinv_type_sales_car ) THEN
        ov_delivered_from  :=  cv_delivered_from_car;       --営業車
      ELSE
        ov_delivered_from  :=  cv_delivered_from_other;     --他倉庫
      END IF;
    -- 売上拠点 <> 保管場所の拠点の場合
    ELSE
      --直送の場合
      IF ( lt_subinv_type = ct_subinv_type_direct ) THEN
        ov_delivered_from  :=  cv_delivered_from_direct;    --工場直送
      ELSE
        ov_delivered_from  :=  cv_delivered_from_sales;    --他拠点倉庫売上
      END IF;
    END IF;
--****************************** 2009/05/14 1.2 N.Maeda MOD  END  ******************************--
--
  EXCEPTION
    -- 必須エラー
    WHEN global_nothing_expt        THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_require_param_err,
        iv_token_name1        =>  cv_tkn_in_param,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_delivered_from;
--
  /************************************************************************
   * Procedure Name  : get_sales_calendar_code
   * Description     : 販売用カレンダコード取得
   ************************************************************************/
  PROCEDURE get_sales_calendar_code(
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- 在庫組織コード
    ion_organization_id       IN OUT        NUMBER,                         -- 在庫組織ＩＤ
    ov_calendar_code          OUT    NOCOPY VARCHAR2,                       -- カレンダコード
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ユーザー・エラー・メッセージ   #固定#
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_calendar_code';      -- プログラム名
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
    ct_msg_get_organization_id      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13559';        -- 在庫組織ID取得
    ct_msg_organization_id          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13560';        -- 在庫組織ID
    ct_msg_mtl_parameters           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13561';        -- 在庫組織パラメータ
    ct_msg_organization_code        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13552';        -- 在庫組織コード
--
    -- *** ローカル変数 ***
    lv_key_info                               VARCHAR2(5000);
    --メッセージ用文字列
    lt_str_prof_organization_code             fnd_new_messages.message_text%TYPE;
    lt_str_get_organization_id                fnd_new_messages.message_text%TYPE;
    lt_str_organization_id                    fnd_new_messages.message_text%TYPE;
    lt_str_mtl_parameters                     fnd_new_messages.message_text%TYPE;
    lt_str_organization_code                  fnd_new_messages.message_text%TYPE;
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
    --==============================================================
    --0.初期化
    --==============================================================
    ov_calendar_code          :=  NULL;
--
    --==============================================================
    --1.引数チェック
    --==============================================================
    --==================================
    --1-1.在庫組織コードおよび在庫組織ＩＤが
    --    NULLの場合、在庫組織コードを取得
    --==================================
    IF ( ( iov_organization_code IS NULL )
      AND ( ion_organization_id  IS NULL ) ) THEN
        --==================================
        -- 1-1-1. 在庫組織コードの取得
        --==================================
        iov_organization_code           :=  FND_PROFILE.VALUE( ct_prof_organization_code );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lt_str_prof_organization_code := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_prof_organization_code
                                           );                      -- XXCOI:在庫組織コード
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_profile_err,
                                             iv_token_name1        => cv_tkn_profile,
                                             iv_token_value1       => lt_str_prof_organization_code
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --==================================
        -- 1-1-2. 在庫組織ＩＤの取得
        --==================================
        ion_organization_id   := xxcoi_common_pkg.get_organization_id(
                                   iov_organization_code
                                 );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lt_str_get_organization_id    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- 在庫組織ID取得
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
    ELSE
      IF ( iov_organization_code IS NULL ) THEN
        --==================================
        -- 1-1-3. 在庫組織コードの取得
        --==================================
        iov_organization_code           := get_organization_code(
                                             ion_organization_id
                                           );
        --
        IF ( iov_organization_code IS NULL ) THEN
          lt_str_organization_id        := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_id
                                           );                      -- 在庫組織ID
          --
          xxcos_common_pkg.makeup_key_info(
            ov_errbuf                   => lv_errbuf,              -- エラー・メッセージ
            ov_retcode                  => lv_retcode,             -- リターンコード
            ov_errmsg                   => lv_errmsg,              -- ユーザ・エラー・メッセージ
            ov_key_info                 => lv_key_info,            -- 編集されたキー情報
            iv_item_name1               => lt_str_organization_id,
            iv_data_value1              => TO_CHAR( ion_organization_id )
          );
          --
          lt_str_mtl_parameters         := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_parameters
                                           );                      -- 在庫組織パラメータ
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_parameters,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      ELSE
        --==================================
        -- 1-1-4. 在庫組織ＩＤの取得
        --==================================
        ion_organization_id             := xxcoi_common_pkg.get_organization_id(
                                             iov_organization_code
                                           );
        --
        IF ( ion_organization_id IS NULL ) THEN
          lt_str_get_organization_id    := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_get_organization_id
                                           );                      -- 在庫組織ID取得
          lv_errmsg                     := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_call_api_err,
                                             iv_token_name1        => cv_tkn_api_name,
                                             iv_token_value1       => lt_str_get_organization_id
                                           );
          lv_errbuf                     := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
      END IF;
    END IF;
--
    --==============================================================
    --2.カレンダコード取得
    --==============================================================
    BEGIN
      SELECT
        mp.calendar_code                calendar_code
      INTO
        ov_calendar_code
      FROM
        mtl_parameters                  mp
      WHERE
        mp.organization_id              = ion_organization_id
      ;
    EXCEPTION
      WHEN OTHERS   THEN
        lt_str_organization_code        := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_organization_code
                                           );                      -- 在庫組織コード
        --
        xxcos_common_pkg.makeup_key_info(
          ov_errbuf                     => lv_errbuf,              -- エラー・メッセージ
          ov_retcode                    => lv_retcode,             -- リターンコード
          ov_errmsg                     => lv_errmsg,              -- ユーザ・エラー・メッセージ
          ov_key_info                   => lv_key_info,            -- 編集されたキー情報
          iv_item_name1                 => lt_str_organization_code,
          iv_data_value1                => iov_organization_code
        );
        --
        lt_str_mtl_parameters           := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_mtl_parameters
                                           );                      -- 在庫組織パラメータ
        lv_errmsg                       := xxccp_common_pkg.get_msg(
                                             iv_application        => ct_xxcos_appl_short_name,
                                             iv_name               => ct_msg_select_err,
                                             iv_token_name1        => cv_tkn_table_name,
                                             iv_token_value1       => lt_str_mtl_parameters,
                                             iv_token_name2        => cv_tkn_key_data,
                                             iv_token_value2       => lv_key_info
                                           );
        lv_errbuf                       := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_sales_calendar_code;
--
  /************************************************************************
   * Function Name   : check_sales_oprtn_day
   * Description     : 販売用稼働日チェック
   ************************************************************************/
  FUNCTION check_sales_oprtn_day(
    id_check_target_date      IN            DATE,                           -- チェック対象日付
    iv_calendar_code          IN            VARCHAR2                        -- カレンダコード
  ) RETURN  NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sales_oprtn_day'; -- プログラム名
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
    --稼働日区分
    cn_sales_oprtn_day_normal   CONSTANT NUMBER := 0;                 --稼働日
    cn_sales_oprtn_day_non      CONSTANT NUMBER := 1;                 --非稼働日
    cn_sales_oprtn_day_error    CONSTANT NUMBER := 2;                 --エラー
--
    -- *** ローカル変数 ***
    lt_seq_num                           bom_calendar_dates.seq_num%TYPE;                  --連番
    lt_calendar_date                     bom_calendar_dates.calendar_date%TYPE;            --カレンダ日付
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
    --==============================================================
    --0.初期化
    --==============================================================
    lt_calendar_date := TRUNC( id_check_target_date );
--
    --==============================================================
    --1.稼働日カレンダチェック
    --==============================================================
    SELECT
      bcd.seq_num                       seq_num
    INTO
      lt_seq_num
    FROM
      bom_calendar_dates                bcd
    WHERE
      bcd.calendar_code                 = iv_calendar_code
    AND bcd.calendar_date               = lt_calendar_date
    ;
--
    --==============================================================
    --2.返却
    --==============================================================
    IF ( lt_seq_num IS NOT NULL ) THEN
      RETURN cn_sales_oprtn_day_normal;
    ELSE
      RETURN cn_sales_oprtn_day_non;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
    WHEN OTHERS THEN
     RETURN cn_sales_oprtn_day_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_sales_oprtn_day;
--
  /**********************************************************************************
   * Procedure Name   : get_period_year
   * Description      : 当年度会計期間取得
   ***********************************************************************************/
  PROCEDURE get_period_year(
    id_base_date              IN         DATE,           -- 基準日
    od_start_date             OUT NOCOPY DATE,           -- 当年度会計開始日
    od_end_date               OUT NOCOPY DATE,           -- 当年度会計終了日
    ov_errbuf                 OUT NOCOPY VARCHAR2,       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT NOCOPY VARCHAR2,       -- リターン・コード               #固定#
    ov_errmsg                 OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ   #固定#
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_year'; -- プログラム名
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
  --販物メッセージ
    cv_msg_mem1_date    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13558';   -- 基準日
    cv_msg_mem2_date    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00060';   -- GL会計帳簿ID
  --メッセージ用文字列
    cv_str_base_date    CONSTANT VARCHAR2(50) := xxccp_common_pkg.get_msg(
                                                    iv_application        =>  ct_xxcos_appl_short_name
                                                   ,iv_name               =>  cv_msg_mem1_date
                                                 );                    -- 基準日
    cv_str_gl_set_of_bks_id CONSTANT VARCHAR2(50)
                                              := xxccp_common_pkg.get_msg(
                                                    iv_application        =>  ct_xxcos_appl_short_name
                                                   ,iv_name               =>  cv_msg_mem2_date
                                                 );                    -- GL会計帳簿ID
    cv_yes_no_flg_n     CONSTANT VARCHAR2(1)  := 'N';                  -- N
    -- *** ローカル変数 ***
--
    ln_id_key           NUMBER;          --プロファイル値
    ld_period_date      DATE;            --当年度会計開始年月日
    lv_key_info         VARCHAR2(5000);  --key情報
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
    --==============================================================
    --引数チェック
    --==============================================================
    IF ( id_base_date IS NULL ) THEN
      RAISE global_nothing_expt;
    END IF;
--
    --==============================================================
    --プロファイル情報を取得します
    --==============================================================
    ln_id_key := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
    --GL会計帳簿ID
    IF ( ln_id_key IS NULL ) THEN
      lv_key_info      := cv_str_gl_set_of_bks_id;
      --メッセージ
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_profile_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --GL:会計帳簿マスタ、GL:ピリオドマスタから会計開始年度を取得します。
    --==============================================================
    SELECT glp.year_start_date
    INTO   ld_period_date
    FROM   gl_sets_of_books glb,
           gl_periods       glp
    WHERE  glb.set_of_books_id         = ln_id_key
    AND    glb.period_set_name         = glp.period_set_name
    AND    glb.accounted_period_type   = glp.period_type
    AND    glp.adjustment_period_flag  = cv_yes_no_flg_n
    AND    glp.start_date             <= id_base_date
    AND    glp.end_date               >= id_base_date
    ;
--
    od_start_date :=ld_period_date;
    od_end_date   :=ADD_MONTHS( ld_period_date, 12 ) - 1;
--
  EXCEPTION
    -- 必須エラー
    WHEN global_nothing_expt        THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_require_param_err,
        iv_token_name1        =>  cv_tkn_in_param,
        iv_token_value1       =>  cv_str_base_date
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- プロファイル取得エラー
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_period_year;
--
  /************************************************************************
   * Procedure Name  : get_account_period
   * Description     : 会計期間情報取得
   ************************************************************************/
  PROCEDURE get_account_period(
    iv_account_period         IN            VARCHAR2,                       -- 会計区分
    id_base_date              IN            DATE,                           -- 基準日
    ov_status                 OUT    NOCOPY VARCHAR2,                       -- ステータス
    od_start_date             OUT    NOCOPY DATE,                           -- 会計(FROM)
    od_end_date               OUT    NOCOPY DATE,                           -- 会計(TO)
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                       -- ユーザー・エラー・メッセージ   #固定#
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_account_period'; -- プログラム名
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
    cv_acc_period_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13551';         -- トークン値[会計期間区分]
    cv_org_code_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13552';         -- トークン値[在庫組織コード]
    cv_inv_prd_err1_msg CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13553';         -- 在庫会計期間取得エラー(日付未指定)
    cv_inv_prd_err2_msg CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13554';         -- 在庫会計期間取得エラー(日付指定)
    cv_set_of_bks_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13555';         -- トークン値[GL会計帳簿]
    cv_ar_prd_err1_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13556';         -- AR会計期間取得エラー(日付未指定)
    cv_ar_prd_err2_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13557';         -- AR会計期間取得エラー(日付指定)
    cv_org_id_err_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';         -- 在庫組織ID取得エラーメッセージ
    cv_acc_lookup_type  CONSTANT VARCHAR2(30) := 'XXCOS1_ACCOUNT_PERIOD';    -- 会計期間区分
    cv_tkn_ja           CONSTANT VARCHAR2(2)  := 'JA';                       -- JA
    cv_acc_period_inv   CONSTANT VARCHAR2(2)  := '01';                       -- INV会計期間
    cv_acc_period_ar    CONSTANT VARCHAR2(2)  := '02';                       -- AR会計期間
    cv_open_flag_y      CONSTANT VARCHAR2(1)  := 'Y';                        -- OPENフラグ[Y]
    cv_status_close     CONSTANT VARCHAR2(5)  := 'CLOSE';                    -- ステータス[CLOSE]
    cv_status_open      CONSTANT VARCHAR2(5)  := 'OPEN';                     -- ステータス[OPEN]
    cv_app_short_nm_ar  CONSTANT VARCHAR2(2)  := 'AR';                       -- アプリケーション短縮名(AR)
    cv_closing_sts_opn  CONSTANT VARCHAR2(1)  := 'O';                        -- AR会計期間クローズステータス(O)
    cv_ad_period_flag   CONSTANT VARCHAR2(1)  := 'N';                        -- AR会計期間フラグ(N)
    cv_yyyymm_fmt       CONSTANT VARCHAR2(6)  := 'YYYYMM';                   -- 年月フォーマット
--
    cv_tkn_profile      CONSTANT VARCHAR2(20) := 'PROFILE';                  -- プロファイル
    cv_tkn_in_param     CONSTANT VARCHAR2(20) := 'IN_PARAM';                 -- 入力パラメータ
    cv_tkn_pro_tok      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';             -- 在庫組織コード
    cv_tkn_org_id       CONSTANT VARCHAR2(20) := 'ORG_ID';                   -- 在庫組織ID
    cv_tkn_open_flag    CONSTANT VARCHAR2(20) := 'OPEN_FLAG';                -- オープンフラグ
    cv_tkn_close_flag   CONSTANT VARCHAR2(20) := 'CLOSE_FLAG';               -- クローズフラグ
    cv_tkn_base_date    CONSTANT VARCHAR2(20) := 'BASE_DATE';                -- 基準日
    cv_tkn_book_id      CONSTANT VARCHAR2(20) := 'BOOK_ID';                  -- GL会計帳簿ID
--
    -- *** ローカル変数 ***
--
    ln_id_key           NUMBER;
    ld_period_date      DATE;
    ln_lookup_cnt       NUMBER;                                    -- 会計期間区分チェック結果件数
    lv_tkn1             VARCHAR2(50);                              -- トークン値
    lv_tkn2             VARCHAR2(50);                              -- トークン値
    lv_organization_cd  mtl_parameters.organization_code%TYPE;     -- 在庫組織コード
    ln_organization_id  mtl_parameters.organization_id%TYPE;       -- 在庫組織ID
    lv_status           VARCHAR2(6);                               -- ステータス
    lv_open_flag        org_acct_periods.open_flag%TYPE;           -- オープンフラグ
    lv_close_flag       gl_period_statuses.closing_status%TYPE;    -- クローズフラグ
    ld_start_date       org_acct_periods.period_start_date%TYPE;   -- 会計(FROM)
    ld_end_date         org_acct_periods.schedule_close_date%TYPE; -- 会計(TO)
    ld_set_of_books_id  gl_period_statuses.set_of_books_id%TYPE;   -- GL会計帳簿ID
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
    --==============================================================
    -- パラメータ[会計区分]チェック
    --==============================================================
    -- 会計区分 設定チェック
    IF ( iv_account_period IS NULL ) THEN
      lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
      lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_require_param_err, cv_tkn_in_param, lv_tkn1 );
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
--
    -- 会計区分 値チェック
    BEGIN
-- ******************** 2009/08/03 1.3 N.Maeda MOD START ******************************--
--      SELECT  COUNT(1)
--      INTO    ln_lookup_cnt
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = cv_tkn_ja
--      AND     look_val.language = cv_tkn_ja
--      AND     appl.language     = cv_tkn_ja
--      AND     app.application_short_name = ct_xxcos_appl_short_name
--      AND     look_val.lookup_type       = cv_acc_lookup_type
--      AND     look_val.meaning           = iv_account_period
--      AND     ROWNUM = 1
--      ;
--
      SELECT  COUNT(1)
      INTO    ln_lookup_cnt
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language     = cv_tkn_ja
      AND     look_val.lookup_type  = cv_acc_lookup_type
      AND     look_val.meaning      = iv_account_period
      ;
-- ******************** 2009/08/03 1.3 N.Maeda MOD  END  ******************************--
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 会計区分 値不正エラー
        lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
        lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_in_param_err, cv_tkn_in_param, lv_tkn1 );
        lv_errmsg := lv_errbuf;
        RAISE global_api_expt;
    END;
--
    IF ( ln_lookup_cnt < 1 ) THEN
      -- 会計区分 値不正エラー
      lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
      lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_in_param_err, cv_tkn_in_param, lv_tkn1 );
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- パラメータ[会計期間区分]による処理振り分け
    --==============================================================
    --==============================================================
    -- AR会計期間の場合
    --==============================================================
    IF ( iv_account_period = cv_acc_period_ar ) THEN
--
      -- プロファイルからGL会計帳簿IDを取得
      ld_set_of_books_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
      -- GL会計帳簿ID取得エラーの場合
      IF ( ld_set_of_books_id IS NULL ) THEN
        lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_set_of_bks_msg );
        lv_errmsg := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_get_profile_err, cv_tkn_profile, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- パラメータの基準日が設定されていない場合
      IF ( id_base_date IS NULL ) THEN
--
        BEGIN
--
          -- オープンしている一番古いAR会計期間の会計(FROM)と会計(TO)を取得する
          SELECT  gps.start_date   start_date,
                  gps.end_date     close_date
          INTO    ld_start_date,
                  ld_end_date
          FROM    gl_period_statuses  gps,
                  fnd_application_vl  fav,
                  ( SELECT  MIN( gps.period_name ) min_period_name
                    FROM    gl_period_statuses  gps,
                            fnd_application_vl  fav
                    WHERE   gps.application_id  = fav.application_id
                    AND     gps.set_of_books_id = ld_set_of_books_id
                    AND     gps.closing_status  = cv_closing_sts_opn
                    AND     gps.adjustment_period_flag = cv_ad_period_flag
                    AND     fav.application_short_name = cv_app_short_nm_ar
                  ) min_ar_prd
          WHERE   gps.application_id  = fav.application_id
          AND     gps.set_of_books_id = ld_set_of_books_id
          AND     gps.closing_status  = cv_closing_sts_opn
          AND     gps.adjustment_period_flag = cv_ad_period_flag
          AND     fav.application_short_name = cv_app_short_nm_ar
          AND     gps.period_name = min_ar_prd.min_period_name
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- AR会計期間取得エラー
            lv_tkn1   := ld_set_of_books_id;
            lv_tkn2   := cv_closing_sts_opn;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_ar_prd_err1_msg
                           , cv_tkn_book_id
                           , lv_tkn1
                           , cv_tkn_close_flag
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- ステータスに[OPEN]を設定
        lv_status := cv_status_open;  -- [OPEN]
--
      -- パラメータの基準日が設定されている場合
      ELSE
--
        BEGIN
--
          -- 基準日のAR会計期間のオープンフラグと会計(FROM)と会計(TO)を取得する
          SELECT  gps.closing_status,
                  gps.start_date,
                  gps.end_date
          INTO    lv_close_flag,
                  ld_start_date,
                  ld_end_date
          FROM    gl_period_statuses  gps,
                  fnd_application_vl  fav
          WHERE	  gps.application_id = fav.application_id
          AND     gps.set_of_books_id = ld_set_of_books_id
          AND     gps.adjustment_period_flag = cv_ad_period_flag
          AND     fav.application_short_name = cv_app_short_nm_ar
          AND     gps.start_date   <= id_base_date
          AND     gps.end_date     >= id_base_date
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- AR会計期間取得エラー
            lv_tkn1   := ld_set_of_books_id;
            lv_tkn2   := id_base_date;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_ar_prd_err2_msg
                           , cv_tkn_book_id
                           , lv_tkn1
                           , cv_tkn_base_date
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- ステータスを設定
        IF ( lv_close_flag = cv_closing_sts_opn ) THEN
          lv_status := cv_status_open;  -- [OPEN]
        ELSE
          lv_status := cv_status_close; -- [CLOSE]
        END IF;
--
      END IF;
--
    --==============================================================
    -- INV会計期間の場合
    --==============================================================
    ELSIF ( iv_account_period = cv_acc_period_inv ) THEN
      -- 在庫組織コードをプロファイルから取得
      lv_organization_cd := FND_PROFILE.VALUE( ct_prof_organization_code );
--
      -- 在庫組織コード取得エラーの場合
      IF ( lv_organization_cd IS NULL ) THEN
        lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_org_code_msg );
        lv_errmsg := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_get_profile_err, cv_tkn_profile, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        NULL;
      END IF;
--
      -- 在庫組織IDを取得
      ln_organization_id := XXCOI_COMMON_PKG.get_organization_id( lv_organization_cd );
      -- 在庫組織ID取得エラーの場合
      IF ( ln_organization_id IS NULL ) THEN
        lv_tkn1   := lv_organization_cd;
        lv_errmsg := xxccp_common_pkg.get_msg( ct_xxcoi_appl_short_name, cv_org_id_err_msg, cv_tkn_pro_tok, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        NULL;
      END IF;
--
      -- パラメータの基準日が設定されていない場合
      IF ( id_base_date IS NULL ) THEN
--
        BEGIN
--
          -- オープンしている一番古いINV会計期間の会計(FROM)と会計(TO)を取得する
          SELECT  inv_prd.period_start_date    period_start_date,
                  inv_prd.schedule_close_date  schedule_close_date
          INTO    ld_start_date,
                  ld_end_date
          FROM    org_acct_periods  inv_prd,
                  ( SELECT  min( inv_prd.period_name )  min_period_name
                    FROM    org_acct_periods  inv_prd
                    WHERE   inv_prd.organization_id = ln_organization_id
                    AND     inv_prd.open_flag = cv_open_flag_y
                  ) min_inv_prd
          WHERE   inv_prd.organization_id = ln_organization_id
          AND     inv_prd.open_flag = cv_open_flag_y
          AND     min_inv_prd.min_period_name = inv_prd.period_name
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 在庫会計期間取得エラー
            lv_tkn1   := ln_organization_id;
            lv_tkn2   := cv_open_flag_y;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_inv_prd_err1_msg
                           , cv_tkn_org_id
                           , lv_tkn1
                           , cv_tkn_open_flag
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- ステータスに[OPEN]を設定
        lv_status := cv_status_open; -- [OPEN]
--
      -- パラメータの基準日が設定されている場合
      ELSE
--
        BEGIN
--
          -- 基準日のINV会計期間のオープンフラグと会計(FROM)と会計(TO)を取得する
          SELECT  inv_prd.open_flag            open_flag,
                  inv_prd.period_start_date    period_start_date,
                  inv_prd.schedule_close_date  schedule_close_date
          INTO    lv_open_flag,
                  ld_start_date,
                  ld_end_date
          FROM    org_acct_periods  inv_prd
          WHERE   inv_prd.organization_id = ln_organization_id
          AND     inv_prd.period_start_date   <= id_base_date
          AND     inv_prd.schedule_close_date >= id_base_date
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 在庫会計期間取得エラー
            lv_tkn1   := ln_organization_id;
            lv_tkn2   := id_base_date;
            lv_errmsg := xxccp_common_pkg.get_msg(
                             ct_xxcos_appl_short_name
                           , cv_inv_prd_err2_msg
                           , cv_tkn_org_id
                           , lv_tkn1
                           , cv_tkn_base_date
                           , lv_tkn2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- ステータスを設定
        IF ( lv_open_flag = cv_open_flag_y ) THEN
          lv_status := cv_status_open;  -- [OPEN]
        ELSE
          lv_status := cv_status_close; -- [CLOSE]
        END IF;
--
      END IF;
--
    ELSE
      -- 会計区分 値不正エラー
      lv_tkn1   := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, cv_acc_period_msg );
      lv_errbuf := xxccp_common_pkg.get_msg( ct_xxcos_appl_short_name, ct_msg_in_param_err, cv_tkn_in_param, lv_tkn1 );
      lv_errmsg := lv_errbuf;
      RAISE global_api_expt;
    END IF;
--
    -- 戻り値に設定
    ov_status     := lv_status;
    od_start_date := ld_start_date;
    od_end_date   := ld_end_date;
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
      -- 戻り値に設定
      ov_status     := NULL;
      od_start_date := NULL;
      od_end_date   := NULL;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- 戻り値に設定
      ov_status     := NULL;
      od_start_date := NULL;
      od_end_date   := NULL;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- 戻り値に設定
      ov_status     := NULL;
      od_start_date := NULL;
      od_end_date   := NULL;
--
--#####################################  固定部 END   ##########################################
--
  END get_account_period;
--
  /************************************************************************
   * Function Name   : get_specific_master
   * Description     : 特定マスタ取得(クイックコード)
   ************************************************************************/
  FUNCTION get_specific_master(
    it_lookup_type            IN            fnd_lookup_types.lookup_type%TYPE, -- ルックアップタイプ
    it_lookup_code            IN            fnd_lookup_values.lookup_code%TYPE -- ルックアップコード
  ) RETURN  VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_specific_master'; -- プログラム名
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
    cv_japan   CONSTANT VARCHAR2(2) := 'JA';
--
    -- *** ローカル変数 ***
    lt_meaning                           fnd_lookup_values_vl.meaning%type;                  --内容
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
    --==============================================================
    --0.初期化
    --==============================================================
    lt_meaning          :=  NULL;
--
    --==============================================================
    --1.特定マスタ取得
    --==============================================================
-- *************** 2009/08/03 N.Maeda 1.3 MOD START ******************** --
--    SELECT flv.meaning
--    INTO   lt_meaning
--    FROM   fnd_lookup_values_vl  flv,
--           fnd_lookup_types_vl   flt,
--           fnd_application_tl    fat
--    WHERE  fat.application_id = flt.application_id
--    AND    fat.language       = cv_japan
--    AND    flt.lookup_type    = flv.lookup_type
--    AND    flv.lookup_type    = it_lookup_type
--    AND    flv.lookup_code    = it_lookup_code
--    ;
--
    SELECT flv.meaning
    INTO   lt_meaning
    FROM   fnd_lookup_values_vl  flv
    WHERE  flv.lookup_type    = it_lookup_type
    AND    flv.lookup_code    = it_lookup_code
    ;
--
-- *************** 2009/08/03 N.Maeda 1.3 MOD  END  ******************** --
--
    --==============================================================
    --2.返却
    --==============================================================
    RETURN lt_meaning;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
    WHEN OTHERS THEN
     RETURN lt_meaning;
--
--#####################################  固定部 END   ##########################################
--
  END get_specific_master;
--
  /************************************************************************
   * Procedure Name  : get_tax_rate_info
   * Description     : 品目別消費税率取得関数
   ************************************************************************/
  PROCEDURE get_tax_rate_info(
    iv_item_code                   IN         VARCHAR2,                      -- 品目コード
    id_base_date                   IN         DATE,                          -- 基準日
    ov_class_for_variable_tax      OUT NOCOPY VARCHAR2,                      -- 軽減税率用税種別
    ov_tax_name                    OUT NOCOPY VARCHAR2,                      -- 税率キー名称
    ov_tax_description             OUT NOCOPY VARCHAR2,                      -- 摘要
    ov_tax_histories_code          OUT NOCOPY VARCHAR2,                      -- 消費税履歴コード
    ov_tax_histories_description   OUT NOCOPY VARCHAR2,                      -- 消費税履歴名称
    od_start_date                  OUT NOCOPY DATE,                          -- 税率キー_開始日
    od_end_date                    OUT NOCOPY DATE,                          -- 税率キー_終了日
    od_start_date_histories        OUT NOCOPY DATE,                          -- 消費税履歴_開始日
    od_end_date_histories          OUT NOCOPY DATE,                          -- 消費税履歴_終了日
    on_tax_rate                    OUT NOCOPY NUMBER,                        -- 税率
    ov_tax_class_suppliers_outside OUT NOCOPY VARCHAR2,                      -- 税区分_仕入外税
    ov_tax_class_suppliers_inside  OUT NOCOPY VARCHAR2,                      -- 税区分_仕入内税
    ov_tax_class_sales_outside     OUT NOCOPY VARCHAR2,                      -- 税区分_売上外税
    ov_tax_class_sales_inside      OUT NOCOPY VARCHAR2,                      -- 税区分_売上内税
    ov_errbuf                      OUT NOCOPY VARCHAR2,                      -- エラー・メッセージエラー       #固定#
    ov_retcode                     OUT NOCOPY VARCHAR2,                      -- リターン・コード               #固定#
    ov_errmsg                      OUT NOCOPY VARCHAR2                       -- ユーザー・エラー・メッセージ   #固定#
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tax_rate_info'; -- プログラム名
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
    cv_date_format                CONSTANT VARCHAR2(10)   := 'YYYY/MM/DD';
    cn_tax_rate_warn              CONSTANT NUMBER         := '0';
    cv_param_check_flag_err0      CONSTANT VARCHAR2(1)    := '0';                          -- エラーなし
    cv_param_check_flag_err1      CONSTANT VARCHAR2(1)    := '1';                          -- 品目コードエラー
    cv_param_check_flag_err2      CONSTANT VARCHAR2(1)    := '2';                          -- 基準日エラー
    cv_param_check_flag_err3      CONSTANT VARCHAR2(1)    := '3';                          -- 双方(品目コード/基準日)エラー
--
    -- メッセージ
    cv_msg_no_data_err            CONSTANT VARCHAR2(20)   := 'APP-XXCOS1-00003';           -- 対象データはありません。
    cv_msg_many_data_err          CONSTANT VARCHAR2(20)   := 'APP-XXCOI1-00025';           -- 取得件数が複数件存在します。
    cv_msg_base_date              CONSTANT VARCHAR2(20)   := 'APP-XXCOS1-13558';           -- 基準日
--
    -- トークン
    cv_tkn_data                   CONSTANT VARCHAR2(100)  := 'DATA';
--
    -- メッセージ用文字列
      -- 品目コード
    cv_msgtxt_item_code           CONSTANT VARCHAR2(5000) := xxccp_common_pkg.get_msg(
                                                               iv_application    =>  ct_xxcos_appl_short_name
                                                              ,iv_name           =>  ct_msg_item_code
                                                             );
      -- 基準日
    cv_msgtxt_base_date           CONSTANT VARCHAR2(5000) := xxccp_common_pkg.get_msg(
                                                               iv_application    =>  ct_xxcos_appl_short_name
                                                              ,iv_name           =>  cv_msg_base_date
                                                             );
      -- 品目コード/基準日
    cv_msgtxt_two_err             CONSTANT VARCHAR2(5000) := cv_msgtxt_item_code || '/' || cv_msgtxt_base_date;
--
    -- *** ローカル変数 ***
    lv_class_for_variable_tax      VARCHAR2(4);                   -- 軽減税率用税種別
    lv_tax_name                    VARCHAR2(80);                  -- 税率キ名称
    lv_tax_description             VARCHAR2(240);                 -- 摘要
    lv_tax_histories_code          VARCHAR2(80);                  -- 消費税履歴コード
    lv_tax_histories_description   VARCHAR2(240);                 -- 消費税履歴名称
    ld_start_date                  DATE;                          -- 税率キー_開始日
    ld_end_date                    DATE;                          -- 税率キー_終了日
    ld_start_date_histories        DATE;                          -- 消費税履歴_開始日
    ld_end_date_histories          DATE;                          -- 消費税履歴_終了日
    ln_tax_rate                    NUMBER;                        -- 税率
    lv_tax_class_suppliers_outside VARCHAR2(150);                 -- 税区分_仕入外税
    lv_tax_class_suppliers_inside  VARCHAR2(150);                 -- 税区分_仕入内税
    lv_tax_class_sales_outside     VARCHAR2(150);                 -- 税区分_売上外税
    lv_tax_class_sales_inside      VARCHAR2(150);                 -- 税区分_売上内税
    ln_param_check_flag            VARCHAR2(1);                   -- 引数チェックフラグ
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
    --==============================================================
    -- 初期化
    --==============================================================
    ov_class_for_variable_tax       := NULL;
    ov_tax_name                     := NULL;
    ov_tax_description              := NULL;
    ov_tax_histories_code           := NULL;
    ov_tax_histories_description    := NULL;
    od_start_date                   := NULL;
    od_end_date                     := NULL;
    od_start_date_histories         := NULL;
    od_end_date_histories           := NULL;
    on_tax_rate                     := NULL;
    ov_tax_class_suppliers_outside  := NULL;
    ov_tax_class_suppliers_inside   := NULL;
    ov_tax_class_sales_outside      := NULL;
    ov_tax_class_sales_inside       := NULL;
    ln_param_check_flag             := cv_param_check_flag_err0;
--
    --==============================================================
    -- 引数チェック
    --==============================================================
    -- 品目コードチェック
    IF ( iv_item_code    IS NULL ) THEN
      ln_param_check_flag  := cv_param_check_flag_err1;            -- 品目コードエラー
    END IF;
    
    -- 基準日チェック
    IF ( id_base_date    IS NULL ) THEN
      IF ( ln_param_check_flag = cv_param_check_flag_err1 ) THEN
        ln_param_check_flag   := cv_param_check_flag_err3;         -- 双方(品目コード/基準日)エラー
      ELSE
        ln_param_check_flag   := cv_param_check_flag_err2;         -- 基準日エラー
      END IF;
    END IF;
    
    -- チェック結果判定
    CASE ln_param_check_flag WHEN cv_param_check_flag_err1 THEN
                               lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => ct_xxcos_appl_short_name
                                             ,iv_name         => ct_msg_require_param_err
                                             ,iv_token_name1  => cv_tkn_in_param
                                             ,iv_token_value1 => cv_msgtxt_item_code
                                            );
                                            
                               lv_errbuf := lv_errmsg;
                               RAISE global_api_expt;
                               
                             WHEN cv_param_check_flag_err2 THEN
                               lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => ct_xxcos_appl_short_name
                                             ,iv_name         => ct_msg_require_param_err
                                             ,iv_token_name1  => cv_tkn_in_param
                                             ,iv_token_value1 => cv_msgtxt_base_date
                                            );
                               lv_errbuf := lv_errmsg;
                               RAISE global_api_expt;
                               
                             WHEN cv_param_check_flag_err3 THEN
                               lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => ct_xxcos_appl_short_name
                                             ,iv_name         => ct_msg_require_param_err
                                             ,iv_token_name1  => cv_tkn_in_param
                                             ,iv_token_value1 => cv_msgtxt_two_err
                                            );
                               lv_errbuf := lv_errmsg;
                               RAISE global_api_expt;
                               
                             ELSE NULL;
                             
    END CASE;
--
    --==============================================================
    -- 消費税率取得処理
    --==============================================================
    BEGIN
      --消費税率取得SQL
      SELECT  xrtrv.class_for_variable_tax        class_for_variable_tax       -- 軽減税率用税種別
             ,xrtrv.tax_name                      tax_name                     -- 税率キー名称
             ,xrtrv.tax_description               tax_description              -- 摘要
             ,xrtrv.tax_histories_code            tax_histories_code           -- 消費税履歴コード
             ,xrtrv.tax_histories_description     tax_histories_description    -- 消費税履歴名称
             ,xrtrv.start_date                    start_date                   -- 税率キー_開始日
             ,xrtrv.end_date                      end_date                     -- 税率キー_終了日
             ,xrtrv.start_date_histories          start_date_histories         -- 消費税履歴_開始日
             ,xrtrv.end_date_histories            end_date_histories           -- 消費税履歴_終了日
             ,xrtrv.tax_rate                      tax_rate                     -- 税率
             ,xrtrv.tax_class_suppliers_outside   tax_class_suppliers_outside  -- 税区分_仕入外税
             ,xrtrv.tax_class_suppliers_inside    tax_class_suppliers_inside   -- 税区分_仕入内税
             ,xrtrv.tax_class_sales_outside       tax_class_sales_outside      -- 税区分_売上外税
             ,xrtrv.tax_class_sales_inside        tax_class_sales_inside       -- 税区分_売上内税
      INTO    lv_class_for_variable_tax
             ,lv_tax_name
             ,lv_tax_description
             ,lv_tax_histories_code
             ,lv_tax_histories_description
             ,ld_start_date
             ,ld_end_date
             ,ld_start_date_histories
             ,ld_end_date_histories
             ,ln_tax_rate
             ,lv_tax_class_suppliers_outside
             ,lv_tax_class_suppliers_inside
             ,lv_tax_class_sales_outside
             ,lv_tax_class_sales_inside
      FROM    xxcos_reduced_tax_rate_v  xrtrv                     -- 品目別消費税率view
      WHERE   xrtrv.item_code = iv_item_code
      AND     id_base_date   >= xrtrv.start_date
      AND    ( id_base_date  <= xrtrv.end_date
               OR      xrtrv.end_date  IS NULL
             )
      AND     id_base_date   >= xrtrv.start_date_histories
      AND    ( id_base_date  <= xrtrv.end_date_histories
               OR      xrtrv.end_date_histories IS NULL
             )
      ;
--
      --戻り値設定
      ov_class_for_variable_tax       := lv_class_for_variable_tax;
      ov_tax_name                     := lv_tax_name;
      ov_tax_description              := lv_tax_description;
      ov_tax_histories_code           := lv_tax_histories_code;
      ov_tax_histories_description    := lv_tax_histories_description;
      od_start_date                   := ld_start_date;
      od_end_date                     := ld_end_date;
      od_start_date_histories         := ld_start_date_histories;
      od_end_date_histories           := ld_end_date_histories;
      on_tax_rate                     := ln_tax_rate;
      ov_tax_class_suppliers_outside  := lv_tax_class_suppliers_outside;
      ov_tax_class_suppliers_inside   := lv_tax_class_suppliers_inside;
      ov_tax_class_sales_outside      := lv_tax_class_sales_outside;
      ov_tax_class_sales_inside       := lv_tax_class_sales_inside;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
        -- 消費税率「0」を設定
        on_tax_rate := cn_tax_rate_warn;
        
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name
                        ,iv_name        => cv_msg_no_data_err
                       );
        ov_errmsg   := lv_errmsg;
        ov_errbuf   := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode  := cv_status_warn;
--
      WHEN TOO_MANY_ROWS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application => ct_xxcoi_appl_short_name
                       ,iv_name        => cv_msg_many_data_err
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
--
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
--
    END;
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
  END get_tax_rate_info;
--
END XXCOS_COMMON_PKG;
/

