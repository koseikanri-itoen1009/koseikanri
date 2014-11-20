CREATE OR REPLACE PACKAGE BODY XXCMM005A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A03C(body)
 * Description      : 拠点マスタIF出力（HHT）
 * MD.050           : 拠点マスタIF出力（HHT） MD050_CMM_005_A03
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_base_mst_if_data   処理対象データ抽出(A-3)
 *  output_csv_data        抽出情報出力(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/03    1.0   Masayuki.Sano    新規作成
 *  2009/02/26    1.1   Masayuki.Sano    結合テスト動作不正対応
 *  2009/03/09    1.2   Yutaka.Kuboshima ファイル出力先のプロファイルの変更
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM005A03C';                  -- パッケージ名
  -- ■ アプリケーション短縮名
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30)  := 'XXCMM';                      -- マスタ
  cv_app_name_xxccp   CONSTANT VARCHAR2(30)  := 'XXCCP';                      -- 共通・IF
  -- ■ カスタム・プロファイル・オプション(XXCMM:拠点マスタ（HHT）)
-- 2009/03/09 modify start by Yutaka.Kuboshima
--  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_005A03_OUT_FILE_DIR';  -- 連携用CSVファイル出力先
  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_HHT_OUT_DIR';          -- HHT(OUTBOUND)連携用CSVファイル出力先
-- 2009/03/09 modify end by Yutaka.Kuboshima
  cv_pro_out_file_fil CONSTANT VARCHAR2(50) := 'XXCMM1_005A03_OUT_FILE_FIL';  -- 連携用CSVファイル名
  -- ■ メッセージ・コード
  cv_msg_00038        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00038';            -- 入力パラメータメッセージ
  cv_msg_05132        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';            -- ファイル名出力メッセージ
  cv_msg_00031        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00031';            -- 期間指定エラー
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';            -- プロファイル取得エラー
  cv_msg_00010        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';            -- CSVファイル存在チェック
  cv_msg_00003        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';            -- ファイルパス不正エラー
  cv_msg_00009        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';            -- CSVデータ出力エラー
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';            -- 対象件数メッセージ
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';            -- 成功件数メッセージ
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';            -- エラー件数メッセージ
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';            -- 正常終了メッセージ
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';            -- エラー終了全ロールバック
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';            -- 対象データ無し
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';            -- システムエラー
-- 2009/02/26 ADD by M.Sano End
  -- ■ トークン
  cv_tok_param        CONSTANT VARCHAR2(5)  := 'PARAM';
  cv_tok_value        CONSTANT VARCHAR2(5)  := 'VALUE';
  cv_tok_filename     CONSTANT VARCHAR2(10) := 'FILE_NAME';                   -- ファイル名
  cv_tok_ng_profile   CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  cv_tok_ng_word      CONSTANT VARCHAR2(10) := 'NG_WORD';
  cv_tok_ng_data      CONSTANT VARCHAR2(10) := 'NG_DATA';
  cv_tok_count        CONSTANT VARCHAR2(10) := 'COUNT';
  -- ■ トークン値
  cv_tval_out_file_dir CONSTANT VARCHAR2(50)  := '拠点マスタ（HHT）連携用CSVファイル出力先';
  cv_tval_out_file_fil CONSTANT VARCHAR2(50)  := '拠点マスタ（HHT）連携用CSVファイル名';
  cv_tval_base_code    CONSTANT VARCHAR2(20)  := '拠点コード'; 
  cv_tval_update_from  CONSTANT VARCHAR2(20)  := '最終更新日(from)';
  cv_tval_update_to    CONSTANT VARCHAR2(20)  := '最終更新日(to)  ';
  cv_tval_para_auto    CONSTANT VARCHAR2(10)  := '自動取得値';          -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名_自動
  cv_tval_part         CONSTANT VARCHAR2(3)   := ' : ';
  cv_tval_backnet_st   CONSTANT VARCHAR2(1)   := '[';
  cv_tval_backnet_en   CONSTANT VARCHAR2(1)   := ']';
  -- ■ その他
  cv_date_format       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_datetime_format   CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
-- 
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 拠点マスタIF出力（HHT）レイアウト
  TYPE output_data_rtype IS RECORD
  (
     account_number           hz_cust_accounts.account_number%TYPE        -- 拠点コード
    ,account_name             hz_cust_accounts.account_name%TYPE          -- 略称
    ,address                  VARCHAR2(60)                               -- 住所
    ,address_lines_phonetic   hz_locations.address_lines_phonetic%TYPE    -- 電話番号
    ,attribute6               hz_cust_accounts.attribute6%TYPE            -- 拠点間倉替区分
    ,attribute5               hz_cust_accounts.attribute5%TYPE            -- 出荷元管理区分
    ,stop_approval_date       xxcmm_cust_accounts.stop_approval_date%TYPE -- 失効日
    ,hza_last_update_date     hz_cust_accounts.last_update_date%TYPE      -- 最終更新日
    ,xca_last_update_date     hz_cust_accounts.last_update_date%TYPE      -- 最終更新日
    ,hlo_last_update_date     hz_locations.last_update_date%TYPE          -- 最終更新日
  );
--
  -- 拠点マスタIF出力（HHT）レイアウト テーブルタイプ
  TYPE xxcmm005a03c_ttype IS TABLE OF output_data_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;             -- 業務日付
  -- 入力パラメータ
  gv_update_from        VARCHAR2(50);     -- 最終更新日(FROM)
  gv_update_to          VARCHAR2(50);     -- 最終更新日(TO)
  -- 処理用
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;  -- 拠点マスタ(HHT)連携用CSVファイル出力先
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;  -- 拠点マスタ(HHT)連携用CSVファイル名
  gf_file_handler       UTL_FILE.FILE_TYPE;                                   -- CSVファイル出力用ハンドラ
  gt_csv_output_tab     xxcmm005a03c_ttype;                                   -- 拠点マスタIF出力データ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    -- *** ローカル変数 ***
    lb_file_exists   BOOLEAN;        -- ファイル存在判断
    ln_file_length   NUMBER(30);     -- ファイルの文字列数
    lbi_block_size   BINARY_INTEGER; -- ブロックサイズ
    lv_update_from   VARCHAR2(10);   -- チェック用最終更新日(From)
    lv_update_to     VARCHAR2(10);   -- チェック用最終更新日(To)
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
    --１．プロファイルの取得を行います。
    --==============================================================
    -- XXCMM: 拠点マスタ（HHT）連携用CSVファイル出力先を取得
    gv_csv_file_dir    := FND_PROFILE.VALUE(cv_pro_out_file_dir);
    -- XXCMM: 拠点マスタ（HHT）連携用CSVファイル出力先の取得内容チェック
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tval_out_file_dir -- 値      :CSVファイル出力先
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCMM: 拠点マスタ（HHT）連携用CSVファイル名を取得
    gv_csv_file_name    := FND_PROFILE.VALUE(cv_pro_out_file_fil);
    -- XXCMM: 拠点マスタ（HHT）連携用CSVファイル名の取得内容チェック
    IF ( gv_csv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tval_out_file_fil -- 値      :CSVファイル名
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --２．CSVファイル存在チェックを行います。
    --==============================================================
    -- ファイル情報を取得
    UTL_FILE.FGETATTR(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- ファイル重複チェック(ファイル存在の有無)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00010         -- エラー:CSVファイル存在チェック
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --３．業務日付を取得します。
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    --==============================================================
    --４．パラメータチェックを行います。
    --==============================================================
    -- "最終更新日(From) > 最終更新日(To)"の場合、パラメータエラー
    lv_update_from := NVL(gv_update_from, TO_CHAR(gd_process_date, cv_date_format));
    lv_update_to   := NVL(gv_update_to,   TO_CHAR(gd_process_date, cv_date_format));
    IF ( lv_update_from > lv_update_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00031         -- エラー:期間指定エラー
                   );
      lv_errbuf := lv_errmsg;
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_base_master_if_data
   * Description      : 処理対象データ抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_base_mst_if_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_mst_if_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cv_time_min    VARCHAR2(10) := ' 00:00:00';
    cv_time_max    VARCHAR2(10) := ' 23:59:59';
    
    -- *** ローカル変数 ***
    ld_update_from DATE;
    ld_update_to   DATE;
--
    -- *** ローカルカーソル***
    CURSOR base_mst_if_cur(
       id_last_update_date_from DATE
      ,id_last_update_date_to   DATE)
    IS
      SELECT hza.account_number           account_number          -- 顧客コード
            ,hza.account_name             account_name            -- 略称(アカウント名)
-- 2009/02/26 UPD by M.Sano Start
--            ,hlo.state || hlo.city || 
--             hlo.address1 || hlo.address2 address                 -- 住所
            ,SUBSTRB(hlo.state || hlo.city || hlo.address1 || hlo.address2, 1, 60)
                                          address                 -- 住所
-- 2009/02/26 UPD by M.Sano End
            ,hlo.address_lines_phonetic   address_lines_phonetic  -- 電話番号
            ,hza.attribute6               attribute6              -- 倉替対象可否フラグ
            ,hza.attribute5               attribute5              -- 出荷元管理区分
            ,xca.stop_approval_date       stop_approval_date      -- 中止決済日
            ,hza.last_update_date         hza_last_update_date    -- 最終更新日
            ,xca.last_update_date         xca_last_update_date    -- 最終更新日
            ,hlo.last_update_date         hlo_last_update_date    -- 最終更新日
      FROM   hz_cust_accounts     hza
            ,xxcmm_cust_accounts  xca
            ,hz_party_sites       hps
            ,hz_locations         hlo
      WHERE  xca.customer_id = hza.cust_account_id
      AND    hza.party_id    = hps.party_id
      AND    hlo.location_id = hps.location_id
      AND    hza.customer_class_code  = '1'
      AND    hps.status      = 'A'
      AND    (  ( hza.last_update_date BETWEEN id_last_update_date_from AND id_last_update_date_to )
             OR ( xca.last_update_date BETWEEN id_last_update_date_from AND id_last_update_date_to )
             OR ( hlo.last_update_date BETWEEN id_last_update_date_from AND id_last_update_date_to ) )

      ORDER BY
             hza.account_number ASC
      ;
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
    -- 検索条件に挿入する日時を作成する。
    --==============================================================
    -- 最終更新日(From)を作成(YYYY/MM/DD 00:00:00)
    IF ( gv_update_from IS NULL ) THEN
      ld_update_from := TO_DATE(TO_CHAR(gd_process_date, cv_date_format) || cv_time_min, cv_datetime_format);
    ELSE
      ld_update_from := TO_DATE(gv_update_from || cv_time_min, cv_datetime_format);
    END IF;
    -- 最終更新日(To)を作成(YYYY/MM/DD 23:59:59)
    IF ( gv_update_to IS NULL ) THEN
      ld_update_to := TO_DATE(TO_CHAR(gd_process_date, cv_date_format) || cv_time_max, cv_datetime_format);
    ELSE
      ld_update_to := TO_DATE(gv_update_to || cv_time_max, cv_datetime_format);
    END IF;
--
    --==============================================================
    -- 拠点マスタIF情報を取得し、結果を配列に格納します。
    --==============================================================
    -- CSV出力データ取得カーソルのオープン
    OPEN base_mst_if_cur(ld_update_from, ld_update_to);
    -- CSV出力データ取得の取得
    <<base_mat_if_loop>>
    LOOP
      FETCH base_mst_if_cur BULK COLLECT INTO gt_csv_output_tab;
      EXIT WHEN base_mst_if_cur%NOTFOUND;
    END LOOP base_mat_if_loop;
    -- CSV出力データ取得カーソルのクローズ
    CLOSE base_mst_if_cur;
    -- 件数を取得
    gn_target_cnt := gt_csv_output_tab.COUNT;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_base_mst_if_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : 抽出情報出力(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cv_sep          CONSTANT VARCHAR2(1)   := ',';  -- 区切り文字
    cv_dqu          CONSTANT VARCHAR2(1)   := '"';  -- ダブルクォーテーション
    -- *** ローカル変数 ***
    ln_idx          NUMBER;         -- Loop時のカウント変数
    lv_output_val   VARCHAR2(100);  -- 出力内容(項目)
    lv_output_line  VARCHAR2(240);  -- 出力内容(行)
    ld_max_date     DATE;           -- 取得した最終更新日の最大値
    lv_base_code    hz_cust_accounts.account_number%TYPE;
                                    -- 拠点コード
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
    -- 取得した拠点マスタIFの情報を、CSVファイルへ出力
    --==============================================================
    <<output_csv_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      BEGIN
        -- ■ 初期設定
        lv_output_line := '';
        lv_base_code   := SUBSTRB(gt_csv_output_tab(ln_idx).account_number,1,4);
--
        -- ■ 出力データ作成
        -- 拠点コード
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).account_number,1,4);
        lv_output_line := cv_dqu || lv_output_val || cv_dqu;
        -- 略称
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).account_name,1,8);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- 住所
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).address,1,60);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- 電話番号
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).address_lines_phonetic,1,15);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- 拠点間倉替区分
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).attribute6,1,1);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- 出荷元管理区分
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).attribute5,1,1);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- 失効日
        lv_output_val  := TO_CHAR(gt_csv_output_tab(ln_idx).stop_approval_date, 'YYYYMMDD');
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- 取得した最終更新日から最大のものを算出
        ld_max_date := gt_csv_output_tab(ln_idx).hza_last_update_date;
        IF ( ld_max_date < gt_csv_output_tab(ln_idx).xca_last_update_date ) THEN
          ld_max_date := gt_csv_output_tab(ln_idx).xca_last_update_date;
        END IF;
        IF ( ld_max_date < gt_csv_output_tab(ln_idx).hlo_last_update_date ) THEN
          ld_max_date := gt_csv_output_tab(ln_idx).hlo_last_update_date;
        END IF;
        -- 算出した最終更新日
        lv_output_val  := TO_CHAR(ld_max_date, 'YYYY/MM/DD HH:MI:SS');
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
--
      -- ■ 出力データをcsvファイルに出力する。
        UTL_FILE.PUT_LINE(gf_file_handler, lv_output_line);
--
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm    -- マスタ
                         ,iv_name         => cv_msg_00009         -- エラー  :CSVデータ出力エラー
                         ,iv_token_name1  => cv_tok_ng_word       -- トークン:NG_WORD
                         ,iv_token_value1 => cv_tval_base_code    -- 値      :拠点コード
                         ,iv_token_name2  => cv_tok_ng_data       -- トークン:NG_DATA
                         ,iv_token_value2 => lv_base_code         -- 値      :拠点コード(データ)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      --成功件数を更新する。
      gn_normal_cnt := gn_normal_cnt + 1;
   END LOOP output_csv_loop;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
   -- ===============================
    -- ローカル変数
    -- ===============================
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- ファイルオープンモード(書き込みモード)
--
    -- *** ローカル変数 ***
    lv_tok_value        VARCHAR2(100);  -- トークンに格納する値
    lv_out_msg          VARCHAR2(5000); -- 出力用
--
BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================================
    -- A-1.初期処理
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode                      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- [入力パラメータを出力(最終更新日(From))]
    -- ・最終更新日(From)がNULL以外 ⇒ 最終更新日（From） ： [YYYY/MM/DD]
    -- ・最終更新日(From)がNULL     ⇒ 最終更新日（From） ： [] : 自動取得[YYYY/MM/DD]
    lv_tok_value := cv_tval_backnet_st || gv_update_from || cv_tval_backnet_en;
    IF ( gv_update_from IS NULL AND gd_process_date IS NOT NULL ) THEN
      lv_tok_value := lv_tok_value || cv_tval_part || cv_tval_para_auto ||
                       cv_tval_backnet_st || TO_CHAR(gd_process_date, cv_date_format) || cv_tval_backnet_en;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm
                    ,iv_name         => cv_msg_00038
                    ,iv_token_name1  => cv_tok_param
                    ,iv_token_value1 => cv_tval_update_from
                    ,iv_token_name2  => cv_tok_value
                    ,iv_token_value2 => lv_tok_value
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- [入力パラメータを出力(最終更新日(To))]
    -- ・最終更新日(To)がNULL以外 ⇒ 最終更新日（To） ： [YYYY/MM/DD]
    -- ・最終更新日(To)がNULL     ⇒ 最終更新日（To） ： [] : 自動取得[YYYY/MM/DD]
    lv_tok_value := cv_tval_backnet_st || gv_update_to || cv_tval_backnet_en;
    IF ( gv_update_to IS NULL AND gd_process_date IS NOT NULL ) THEN
      lv_tok_value := lv_tok_value || cv_tval_part || cv_tval_para_auto ||
                       cv_tval_backnet_st || TO_CHAR(gd_process_date, cv_date_format) || cv_tval_backnet_en;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm
                    ,iv_name         => cv_msg_00038
                    ,iv_token_name1  => cv_tok_param
                    ,iv_token_value1 => cv_tval_update_to
                    ,iv_token_name2  => cv_tok_value
                    ,iv_token_value2 => lv_tok_value
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- [ファイル名の出力]
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_05132
                    ,iv_token_name1  => cv_tok_filename
                    ,iv_token_value1 => gv_csv_file_name
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- [初期処理の実行結果チェック]
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2．ファイルオープン処理(書込モード)
    -- ===============================================
    BEGIN
      -- ファイルを開く
      gf_file_handler := UTL_FILE.FOPEN(
                            location   => gv_csv_file_dir     -- 出力先
                           ,filename   => gv_csv_file_name    -- ファイル名
                           ,open_mode  => cv_csv_mode_w       -- ファイルオープンモード
                        );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        -- メッセージを取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm  -- マスタ
                       ,iv_name         => cv_msg_00003       -- エラー:ファイルパス不正エラー
                     );
        lv_errbuf := lv_errmsg;
        -- 例外をスロー
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================================
    -- A-3．処理対象データ抽出
    -- ===============================================
    get_base_mst_if_data(
       ov_errbuf           => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-4．抽出情報出力
    -- ===============================================
    output_csv_data(
       ov_errbuf           => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- [処理結果チェック]
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    -- [処理件数が0件の場合、対象データ無しメッセージ出力]
    IF ( gn_target_cnt = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- マスタ
                       ,iv_name         => cv_msg_00001         -- エラー  :CSVデータ出力エラー
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
    END IF;
--
    -- ===============================================
    -- A-5．終了処理
    -- ===============================================
    UTL_FILE.FCLOSE(gf_file_handler);
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT    VARCHAR2,        --   エラーコード     #固定#
    iv_update_from        IN     VARCHAR2,        --   1.最終更新日(FROM)
    iv_update_to          IN     VARCHAR2)        --   2.最終更新日(TO)
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);     -- リターン・コード
    lv_errmsg           VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code     VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- 入力パラメータの取得
    -- ===============================================
    gv_update_from := iv_update_from;
    gv_update_to   := iv_update_to;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf           => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- ファイルが閉じられていない場合、ファイルを閉じる。
    IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
      UTL_FILE.FCLOSE(gf_file_handler);
    END IF;
--
    -- ===============================================
    -- エラーメッセージの出力
    -- ===============================================
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- 件数の出力
    -- ===============================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================================
    --終了メッセージ
    -- ===============================================
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMM005A03C;
/
