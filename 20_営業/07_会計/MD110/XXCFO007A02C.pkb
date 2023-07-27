CREATE OR REPLACE PACKAGE BODY APPS.XXCFO007A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO007A02C (body)
 * Description      : EBS APオープンインタフェースの登録されたデータを抽出、ERP CloudのAP標準テーブルに登録する。
 * MD.050           : T_MD050_CFO_007_A02_承認済仕入先請求書抽出_EBSコンカレント
 * Version          : 1.4
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_ap_data         I/Fファイル出力(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-12-27    1.0   Yamato.Fuku      新規作成
 *  2023-01-12    1.1   Yamato.Fuku      E132対応と摘要の切り捨てを対応
 *  2023-01-16    1.2   Yamato.Fuku      E133対応
 *  2023-01-16    1.3   Yamato.Fuku      E134対応
 *  2023-03-13    1.4   Y.Ooyama         シナリオテスト不具合No.0065対応
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
  global_dir_get_expt       EXCEPTION;                                     -- ディレクトリフルパス取得エラー
  -- ロックエラー例外
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCFO007A02C';      -- パッケージ名 
--
  --アプリケーション短縮名
  cv_msg_kbn_cff            CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo            CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';
  --
  cv_slash                  CONSTANT VARCHAR2(1)   := '/';
  --
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;              -- ファイルサイズ
  cv_delim_comma            CONSTANT VARCHAR2(1)    := ',';                -- カンマ
  cv_underbar               CONSTANT VARCHAR2(1)    := '_';                -- アンダーバー
  cv_open_mode_w            CONSTANT VARCHAR2(1)    := 'w';                -- ファイルオープンモード（上書き）
  cv_xx03_entry             CONSTANT VARCHAR2(15)   := 'XX03_ENTRY';       -- 部門入力
  cv_ers                    CONSTANT VARCHAR2(15)   := 'ERS';              -- 購買
  cv_mfg_account            CONSTANT VARCHAR2(15)   := 'MFG_ACCOUNT';      -- 工場会計
  cv_bm_system              CONSTANT VARCHAR2(15)   := 'BM_SYSTEM';        -- 問屋支払
  cv_sales_deduction        CONSTANT VARCHAR2(15)   := 'SALES_DEDUCTION';  -- 販売控除
  cv_xx03_entry_short       CONSTANT VARCHAR2(7)    := 'ENTRY';            -- 部門入力_短縮名
  cv_ers_short              CONSTANT VARCHAR2(7)    := 'ERS';              -- 購買_短縮名
  cv_mfg_account_short      CONSTANT VARCHAR2(7)    := 'MFG_ACT';          -- 工場会計_短縮名
  cv_bm_system_short        CONSTANT VARCHAR2(7)    := 'BM_SYS';           -- 問屋支払_短縮名
  cv_sales_deduction_short  CONSTANT VARCHAR2(7)    := 'SL_DDC';           -- 販売控除_短縮名
  cv_lf_str                 CONSTANT VARCHAR2(2)    := '\n';               -- LF置換単語
  cv_status                 CONSTANT VARCHAR2(9)    := 'PROCESSED';        -- ステータスPROCESSED
  cv_lookup_code_tax        CONSTANT VARCHAR2(3)    := 'TAX';              -- lookup_code:TAX
  cv_attribute_category     CONSTANT VARCHAR2(8)    := 'SALES-BU';         -- attribute_category:SALES-BU
  cv_date_format            CONSTANT VARCHAR2(10)   := 'YYYY/MM/DD';       -- 日付のフォーマット
  cn_zero                   CONSTANT NUMBER         := 0;                  -- 0
  cn_hundred                CONSTANT NUMBER         := 100;                -- 100
  cn_utf8_size              CONSTANT NUMBER         := 240;                -- 240
  cv_flag_y                 CONSTANT VARCHAR2(1)    := 'Y';                -- 文字列:Y  
  cv_flag_n                 CONSTANT VARCHAR2(1)    := 'N';                -- 文字列:N  
  --プロファイル
  -- XXCFO:OIC連携APデータファイル格納ディレクトリ名
  cv_oic_ap_out_file_dir    CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_AP_OUT_FILE_DIR';
  -- XXCFO:承認済仕入先請求書HEAD連携データファイル名（OIC連携）
  cv_head_filename          CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_AP_INV_H_OUT_FILE';
  -- XXCFO:承認済仕入先請求書LINE(本体)連携データファイル名（OIC連携）
  cv_line_filename          CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_AP_INV_L_OUT_FILE';
-- Ver1.1(E132) Add Start
  -- XXCFO:AP摘要切り捨てフラグ
  cv_desc_trim_flag         CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_DESC_TRIM_FLAG';
-- Ver1.1(E132) End Start
  --メッセージ
  cv_msg_cfo_00001          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';   -- プロファイル名取得エラーメッセージ
  cv_msg_cfo_00019          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';   -- ロックエラーメッセージ
  cv_msg_cfo_00020          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';   -- 更新エラーメッセージ
  cv_msg_cfo_00024          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';   -- 登録エラーメッセージ
  cv_msg_cfo_00027          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';   -- 同一ファイル存在エラーメッセージ
  cv_msg_cfo_00029          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';   -- ファイルオープンエラーメッセージ
  cv_msg_cfo_00030          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';   -- ファイル書込みエラーメッセージ
  cv_msg_coi_00029          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';   -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_60001          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60001';   -- パラメータ出力メッセージ
  cv_msg_cfo_60002          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60002';   -- IFファイル名出力メッセージ
  cv_msg_cfo_60004          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60004';   -- 検索対象・件数メッセージ
  cv_msg_cfo_60005          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60005';   -- ファイル出力対象・件数メッセージ
  cv_msg_cfo_60009          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60009';   -- パラメータ必須エラーメッセージ
  --トークンコード
  cv_tkn_param_val          CONSTANT VARCHAR2(20)  := 'PARAM_VAL';         -- パラメータ値
  cv_tkn_prof_name          CONSTANT VARCHAR2(20)  := 'PROF_NAME';         -- プロファイル名
  cv_tkn_dir_tok            CONSTANT VARCHAR2(20)  := 'DIR_TOK';           -- ディレクトリ名
  cv_tkn_file_name          CONSTANT VARCHAR2(20)  := 'FILE_NAME';         -- ファイル名
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';             -- テーブル名
  cv_tkn_errmsg             CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- SQLエラーメッセージ
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';           -- トークン名(SQLERRM)
  cv_tkn_param_name         CONSTANT VARCHAR2(30)  := 'PARAM_NAME';        -- パラメータ名
  cv_tkn_target             CONSTANT VARCHAR2(30)  := 'TARGET';            -- ターゲット
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';             -- カウント
  --メッセージ出力用文字列(トークン)
  cv_msgtkn_cfo_60021       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60021';  -- ソース
  cv_msgtkn_cfo_60022       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60022';  -- AP請求書OIF
  cv_msgtkn_cfo_60023       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60023';  -- AP請求書LINE
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- XXCFO:OIC連携APデータファイル格納ディレクトリ名
  gv_dir_name           VARCHAR2(1000);
  -- XXCFO:承認済仕入先請求書HEAD連携データファイル名（OIC連携）
  gv_if_file_name_head  VARCHAR2(1000);
  -- XXCFO:承認済仕入先請求書LINE(本体)連携データファイル名（OIC連携）
  gv_if_file_name_line  VARCHAR2(1000);
-- Ver1.1(E132) Add Start
  -- XXCFO:AP摘要切り捨てフラグ
  gv_desc_trim_flag     VARCHAR2(1000);
-- Ver1.1(E132) Add Start
  gt_directory_path all_directories.directory_path%TYPE;       -- ディレクトリパス
  gv_source_short_name  VARCHAR2(7);                           -- 短縮名
  gn_head_cnt           NUMBER;                                -- HEAD出力件数
  gn_line_cnt           NUMBER;                                -- LINE出力件数
-- Ver1.1(E132) Add Start
--
  /**********************************************************************************
   * Procedure Name   : get_utf8_size_char
   * Description      : SJIS→UTF8変換後の桁数を算出し、指定の桁数を超過した場合に
   *                    指定の桁数で格納できる様、SJISテキストを切り捨てした値を返します。
   ***********************************************************************************/
  FUNCTION get_utf8_size_char(
    in_number_of_digits IN NUMBER   -- 1.桁数
   ,iv_sjis_text        IN VARCHAR2 -- 2.SJISテキスト
  ) RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'XXCVRETS0021C.get_utf8_size_char'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    ln_digits_cnt  NUMBER;         -- 桁数
    lv_return_text VARCHAR2(2000); -- 戻り値を格納
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
    -- ===============================
    -- 初期値設定
    -- ===============================
    ln_digits_cnt  := in_number_of_digits; -- 桁数
    lv_return_text := iv_sjis_text;        -- 文字列
--
    -- ===============================
    -- 文字列切り捨て処理
    -- ===============================
    IF lv_return_text IS NOT NULL THEN
      <<truncation_loop>>
      LOOP
        -- UTF8変換後の文字列が桁数以下の場合
        IF (LENGTHB(CONVERT(lv_return_text,'UTF8')) <= in_number_of_digits ) THEN
          -- 桁数以下なのでLOOPを抜ける
          EXIT truncation_loop;
        ELSE
          -- 文字列から1バイト削除
          ln_digits_cnt  := ln_digits_cnt - 1;
          lv_return_text := SUBSTR(lv_return_text,1,ln_digits_cnt);
        END IF;
      END LOOP truncation_loop;
    END IF;
--
--
    -- 切り捨て後の値を戻す
    RETURN lv_return_text;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_utf8_size_char;
--
-- Ver1.1(E132) Add End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_source     IN  VARCHAR2,     --   ソース
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    )
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
--
    -- *** ローカル変数 ***
    lv_pd_param       VARCHAR2(100)   DEFAULT NULL;                     -- メッセージ取得用
    lv_msg            VARCHAR2(300)   DEFAULT NULL;                     -- メッセージ出力用
    -- ファイル存在チェック用
    lb_exists         BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length    NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size     BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
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
    -- パラメータ出力
    --==============================================================
    lv_pd_param := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- XXCFO
                                            , cv_msgtkn_cfo_60021 -- ソース
                                           );
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo            -- XXCFO
                                       , cv_msg_cfo_60001          -- パラメータ出力メッセージ
                                       , cv_tkn_param_name         -- PARAM_NAME
                                       , lv_pd_param               -- ソース
                                       , cv_tkn_param_val          -- PARAM_VAL
                                       , iv_source                 -- ソース
                                      );
    --メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    --ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    --==============================================================
    -- 1.入力パラメータの必須チェック
    --==============================================================
    IF ( iv_source IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo         -- XXCFO
                               , cv_msg_cfo_60009       -- パラメータ必須エラーメッセージ
                               , cv_tkn_param_name      -- トークン名：パラメータ名
                               , lv_pd_param            -- トークン値：XXCFO1_OIC_AP_OUT_FILE_DIR
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
    -- ==============================================================
    -- 2.プロファイルの取得
    -- ==============================================================
    -- OIC連携APデータファイル格納ディレクトリ名
    gv_dir_name := FND_PROFILE.VALUE( cv_oic_ap_out_file_dir );
--
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo         -- XXCFO
                               , cv_msg_cfo_00001       -- プロファイル名取得エラーメッセージ
                               , cv_tkn_prof_name       -- トークン名：プロファイル名
                               , cv_oic_ap_out_file_dir -- トークン値：XXCFO1_OIC_AP_OUT_FILE_DIR
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 承認済仕入先請求書HEAD連携データファイル名（OIC連携）
    gv_if_file_name_head := FND_PROFILE.VALUE ( cv_head_filename ) ;
--
    IF ( gv_if_file_name_head IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- プロファイル名取得エラーメッセージ
                               , cv_tkn_prof_name      -- トークン名：プロファイル名
                               , cv_head_filename      -- トークン値：XXCFO1_OIC_GL_JE_L_ERP_IN_FILE
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 承認済仕入先請求書LINE(本体)連携データファイル名（OIC連携）
    gv_if_file_name_line := FND_PROFILE.VALUE ( cv_line_filename ) ;
--
    IF ( gv_if_file_name_line IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- プロファイル名取得エラーメッセージ
                               , cv_tkn_prof_name      -- トークン名：プロファイル名
                               , cv_line_filename      -- トークン値：XXCFO1_OIC_AP_INV_L_OUT_FILE
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1(E132) Add Start
--
    -- XXCFO:AP摘要切り捨てフラグ
    gv_desc_trim_flag := FND_PROFILE.VALUE ( cv_desc_trim_flag ) ;
--
    IF ( gv_desc_trim_flag IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- プロファイル名取得エラーメッセージ
                               , cv_tkn_prof_name      -- トークン名：プロファイル名
                               , cv_desc_trim_flag     -- トークン値：XXCFO1_OIC_DESC_TRIM_FLAG
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1(E132) Add End
    -- ==============================================================
    -- 3.プロファイル値「XXCFO:OIC連携APデータファイル格納ディレクトリ名」からディレクトリパスを取得する。
    -- ==============================================================
    BEGIN
      SELECT 
        RTRIM( ad.directory_path , cv_slash ) AS directory_path
      INTO 
        gt_directory_path
      FROM 
        all_directories ad
      WHERE 
        ad.directory_name = gv_dir_name;
      -- レコードは存在するがディレクトリパスがnullの場合、エラー
      IF ( gt_directory_path IS NULL ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_coi          -- XXCOI
                               , cv_msg_coi_00029        -- ディレクトリフルパス取得エラーメッセージ
                               , cv_tkn_dir_tok          -- トークン名：ディレクトリ名
                               , gv_dir_name             -- トークン値：gv_dir_name
                              )
                             , 1
                             , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_dir_get_expt;
      END IF;
    -- レコードが取得できない場合、エラー
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                             (
                                cv_msg_kbn_coi          -- XXCOI
                              , cv_msg_coi_00029        -- ディレクトリフルパス取得エラーメッセージ
                              , cv_tkn_dir_tok          -- トークン名：ディレクトリ名
                              , gv_dir_name             -- トークン値：gv_dir_name
                             )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_dir_get_expt;
    END;
--
    -- ==============================================================
    -- 4.入力パラメータ「ソース」より、ファイル名に使用する短縮名を決定します。
    -- ==============================================================
    CASE WHEN cv_ers             = iv_source THEN
           gv_source_short_name := cv_ers_short;
         WHEN cv_bm_system       = iv_source THEN
           gv_source_short_name := cv_bm_system_short;
         WHEN cv_mfg_account     = iv_source THEN
           gv_source_short_name := cv_mfg_account_short;
         WHEN cv_xx03_entry      = iv_source THEN
           gv_source_short_name := cv_xx03_entry_short;
         WHEN cv_sales_deduction = iv_source THEN
           gv_source_short_name := cv_sales_deduction_short;
         ELSE
           NULL;
    END CASE;
--
  EXCEPTION
    WHEN global_dir_get_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_ap_data
   * Description      : I/Fファイル出力(A-2)
   ***********************************************************************************/
  PROCEDURE output_ap_data(
    iv_source     IN  VARCHAR2,     --   ソース
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_ap_data'; -- プログラム名
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
    lf_file_handle1    UTL_FILE.FILE_TYPE;                           -- CSVファイルハンドラ
    lv_data_filename1  VARCHAR2(100);                                -- HEADデータファイル名
    lf_file_handle2    UTL_FILE.FILE_TYPE;                           -- CSVファイルハンドラ
    lv_data_filename2  VARCHAR2(100);                                -- LINEデータファイル名
    lv_msgbuf          VARCHAR2(5000);                               -- ユーザー・メッセージ
    lv_csv_text        VARCHAR2(30000)DEFAULT NULL;                  -- 出力１行分文字列変数
    lt_attribute12     ap_invoice_lines_interface.attribute12%TYPE;  -- 電子帳簿部門入力請求書ID/明細番号上書き用変数
    -- ファイル出力関連
    lb_fexists          BOOLEAN;                                     -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                                      -- ファイルの長さ
    ln_block_size       NUMBER;                                      -- ファイルシステムのブロックサイズ
--
    -- *** ローカル・カーソル ***
    -- 承認済仕入先請求書HEADカーソル
    CURSOR ap_head_cur
      IS
        SELECT 
            aii.invoice_id
          , cv_attribute_category as operating_unit
          , aii.source
          , aii.invoice_num
          , aii.invoice_amount
          , TO_CHAR( aii.invoice_date , cv_date_format ) as invoice_date
-- Ver1.2(E133) Mod Start
--          , avv.vendor_number as vendor_num
--          , avsv.vendor_site_code
          , CASE WHEN aii.vendor_id IS NULL 
              THEN aii.vendor_num
              ELSE avv.vendor_number
            END as vendor_num
          , CASE WHEN aii.vendor_site_id IS NULL
              THEN aii.vendor_site_code
              ELSE avsv.vendor_site_code
            END as vendor_site_code
-- Ver1.2(E133) Mod End
          , aii.invoice_currency_code
          , aii.description
          , aii.invoice_type_lookup_code
-- Ver1.2(E133) Mod Start
--          , at.name as terms_name
          , CASE WHEN aii.terms_id IS NULL
              THEN aii.terms_name
              ELSE at.name
            END as terms_name
-- Ver1.2(E133) Mod End
          , TO_CHAR( aii.terms_date , cv_date_format ) as terms_date
          , TO_CHAR( aii.gl_date , cv_date_format ) as gl_date
          , aii.pay_group_lookup_code as payment_method_code
          , aii.prepay_num
          , TO_CHAR( aii.prepay_gl_date , cv_date_format ) as prepay_gl_date
          , aii.exchange_rate_type
          , '仕入先支払用ダミー' as pay_group
          , TO_CHAR( aii.exchange_date , cv_date_format ) as exchange_date
          , aii.exchange_rate
          , gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4 || '-' || 
              gcc.segment5 || '-' || gcc .segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 as accts_pay_code_concatenated
          , cv_attribute_category as attribute_category
          , aii.attribute1
          , aii.attribute2
          , aii.attribute3
          , aii.attribute4
          , aii.attribute5
          , aii.attribute6
          , aii.attribute7
          , aii.attribute8
          , aii.attribute9
          , aii.attribute10
          , aii.attribute11
          , aii.attribute12
          , aii.attribute13
          , aii.attribute14
          , aii.attribute15
        FROM 
            ap_invoices_interface aii
          , ap_vendors_v avv
          , ap_vendor_sites_v avsv
          , ap_terms at
          , gl_code_combinations gcc
        WHERE 
              aii.vendor_id = avv.vendor_id(+)
          AND aii.vendor_site_id = avsv.vendor_site_id(+)
          AND aii.terms_id = at.term_id(+)
          AND aii.accts_pay_code_combination_id = gcc.code_combination_id(+)
          AND (aii.status <> cv_status OR aii.status IS NULL)
          AND aii.source = iv_source
        FOR UPDATE OF aii.vendor_id NOWAIT
        ;
    ap_head_rec ap_head_cur%ROWTYPE;
--
    -- 承認済仕入先請求書LINEカーソル
    CURSOR ap_line_cur
      IS
        SELECT 
            rec.invoice_id
          , rec.line_number
          , rec.line_type_lookup_code
          , rec.amount
          , rec.description
          , rec.dist_code_concatenated
          , rec.tax_code as tax_classification_code
          , CASE
              WHEN ( rec.amount <> cn_zero AND rec.tax_rate = cn_zero ) THEN cn_hundred
              ELSE NULL
            END as tax_rate
          , rec.tax_code
          , CASE 
-- Ver1.4 Mod Start
--              WHEN sum_rec.sum_amount > cn_zero THEN cv_flag_y
              WHEN sum_rec.sum_amount <> cn_zero THEN cv_flag_y
-- Ver1.4 Mod End
              ELSE cv_flag_n
            END as prorate_across_flag
          , row_num.line_group_number
          , rec.attribute_category
          , rec.attribute1
          , rec.attribute2
          , rec.attribute3
          , rec.attribute4
          , rec.attribute5
          , rec.attribute6
          , rec.attribute7
          , rec.attribute8
          , rec.attribute9
          , rec.attribute10
          , rec.attribute11
          , rec.attribute12
          , rec.attribute13
          , rec.attribute14
          , rec.attribute15
        FROM (
          SELECT
              aili.invoice_id
            , aili.line_number
            , aili.line_type_lookup_code
            , aili.amount
            , aili.description
-- Ver1.1(E132) Mod Start
--            , CASE WHEN aili.dist_code_concatenated IS NOT NULL THEN aili.dist_code_concatenated
            , CASE WHEN aili.dist_code_concatenated IS NOT NULL THEN 
                   regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 1) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 2) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3)
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 4) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 5) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 6) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 7) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 8)
-- Ver1.1(E132) Add End
                ELSE gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4 
                  || '-' ||  gcc.segment5 || '-' || gcc.segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 
              END as dist_code_concatenated
            , aili.tax_code
            , NULL as tax_rate
            , cv_attribute_category as attribute_category
            , aili.attribute1
            , aili.attribute2
            , aili.attribute3
            , aili.attribute4
            , aili.attribute5
            , aili.attribute6
            , aili.attribute7
            , aili.attribute8
            , aili.attribute9
            , aili.attribute10
            , aili.tax_code as attribute11
            , aili.attribute12
            , aili.attribute13
            , aili.attribute14
            , aili.attribute15
          FROM
              ap_invoice_lines_interface aili
            , gl_code_combinations gcc
            , ap_invoices_interface aii
          WHERE
                aii.invoice_id = aili.invoice_id
            AND aili.dist_code_combination_id = gcc.code_combination_id(+)
            AND aili.line_type_lookup_code <> cv_lookup_code_tax
            AND (aii.status <> cv_status OR aii.status IS NULL)
            AND aii.source = iv_source
          UNION ALL
          SELECT
              aili.invoice_id
            , MIN(aili.line_number) as line_number
            , aili.line_type_lookup_code
            , SUM(aili.amount) as amount
            , MIN(aili.description) as description
            , CASE 
-- Ver1.1(E132) Mod Start
--                WHEN aili.dist_code_concatenated IS NOT NULL THEN aili.dist_code_concatenated
                WHEN aili.dist_code_concatenated IS NOT NULL THEN 
                     regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 1) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 2) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3)
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 4) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 5) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 6) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 7) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 8)
-- Ver1.1(E132) Mod End
                  ELSE gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4
                    || '-' || gcc.segment5 || '-' || gcc.segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 
              END as dist_code_concatenated
            , aili.tax_code
            , atca.tax_rate
            , cv_attribute_category as attribute_category
            , aili.attribute1
            , aili.attribute2
            , aili.attribute3
            , aili.attribute4
            , aili.attribute5
            , aili.attribute6
            , aili.attribute7
            , aili.attribute8
            , aili.attribute9
            , aili.attribute10
            , aili.tax_code as attribute11
            , aili.attribute12
            , aili.attribute13
            , aili.attribute14
            , aili.attribute15
          FROM
              ap_invoice_lines_interface aili
            , gl_code_combinations gcc
            , ap_invoices_interface aii
            , ap_tax_codes_all atca
            , hr_operating_units hou
          WHERE
                aii.invoice_id = aili.invoice_id
            AND aili.dist_code_combination_id = gcc.code_combination_id(+)
            AND aili.org_id = hou.organization_id
            AND hou.set_of_books_id = atca.set_of_books_id
            AND aili.tax_code = atca.name
            AND aili.line_type_lookup_code = cv_lookup_code_tax 
            AND (aii.status <> cv_status OR aii.status IS NULL)
            AND aii.source = iv_source
          GROUP BY 
              aili.invoice_id
            , aili.line_type_lookup_code
            , CASE 
-- Ver1.1(E132) Mod Start
--                WHEN aili.dist_code_concatenated IS NOT NULL THEN aili.dist_code_concatenated
                WHEN aili.dist_code_concatenated IS NOT NULL THEN 
                     regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 1) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 2) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3)
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 4) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 5) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 6) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 7) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 8)
-- Ver1.1(E132) Mod End
                  ELSE gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4 
                    || '-' || gcc.segment5 || '-' ||  gcc.segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 
              END
            , aili.tax_code
            , atca.tax_rate
            , cv_attribute_category
            , aili.attribute1
            , aili.attribute2
            , aili.attribute3
            , aili.attribute4
            , aili.attribute5
            , aili.attribute6
            , aili.attribute7
            , aili.attribute8
            , aili.attribute9
            , aili.attribute10
            , aili.tax_code
            , aili.attribute12
            , aili.attribute13
            , aili.attribute14
            , aili.attribute15
          ) rec ,
          (SELECT
               lgn.invoice_id
             , lgn.tax_code
             , ROW_NUMBER()OVER(PARTITION BY lgn.invoice_id ORDER BY lgn.line_number) as line_group_number 
           FROM 
             (SELECT DISTINCT
                  aili.invoice_id
                , aili.tax_code
                , MIN(aili.line_number) line_number
              FROM 
                  ap_invoice_lines_interface aili
              GROUP BY 
                  aili.invoice_id
                , aili.tax_code
             )lgn
          ) row_num,
          (SELECT
               aili.invoice_id
             , aili.tax_code
             , SUM(aili.amount) as sum_amount
           FROM 
             ap_invoice_lines_interface aili
           WHERE 
             aili.line_type_lookup_code <> cv_lookup_code_tax
           GROUP BY 
               aili.invoice_id
             , aili.tax_code
          ) sum_rec
        WHERE 
              rec.invoice_id = row_num.invoice_id
          AND rec.tax_code = row_num.tax_code
          AND rec.invoice_id = sum_rec.invoice_id
          AND rec.tax_code = sum_rec.tax_code
        ORDER BY 
            rec.invoice_id
          , rec.line_number
      ;
    ap_line_rec ap_line_cur%ROWTYPE;
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
--
    -- 変数の初期化
    lv_csv_text := NULL;
    gn_head_cnt := 0;
    gn_line_cnt := 0;
--
    -- 出力ファイルをすべてオープンする。
    gt_directory_path := gt_directory_path || cv_slash;
    lv_data_filename1 := xxccp_common_pkg.char_delim_partition( gv_if_file_name_head , cv_msg_cont , 1 ) || 
                           cv_underbar || gv_source_short_name || cv_msg_cont ||
                             xxccp_common_pkg.char_delim_partition( gv_if_file_name_head , cv_msg_cont , 2 );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo                          -- 'XXCFO'
                                     , cv_msg_cfo_60002                        -- IFファイル名出力メッセージ
                                     , cv_tkn_file_name                        -- トークン(FILE_NAME)
                                     , gt_directory_path || lv_data_filename1  -- ファイルパス/承認済仕入先請求書HEAD連携データファイル名
                                     );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
-- 
    -- 同一ファイル存在チェック
    UTL_FILE.FGETATTR( gt_directory_path
                 , lv_data_filename1                                  -- HEADデータファイル名
                 , lb_fexists
                 , ln_file_size
                 , ln_block_size );
--
    -- 同一ファイル存在エラーメッセージ
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo    -- 'XXCFO'
                                                     , cv_msg_cfo_00027  -- 同一ファイル存在エラーメッセージ
                                                    )
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ファイルオープン
    BEGIN
      lf_file_handle1 := UTL_FILE.FOPEN( gt_directory_path , lv_data_filename1 , cv_open_mode_w , cn_max_linesize );
    EXCEPTION
      -- ファイルオープンエラー 
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                         cv_msg_kbn_cfo      -- XXCFO
                                                       , cv_msg_cfo_00029    -- ファイルオープンエラーメッセージ
                                                      )
                              , 1
                              , 5000
                             );
        lv_errbuf := lv_errmsg;
        --例外表示は、上位モジュールで行う。
        RAISE global_process_expt;
    END;
--
    lv_data_filename2 := xxccp_common_pkg.char_delim_partition( gv_if_file_name_line , cv_msg_cont , 1 ) || 
                           cv_underbar || gv_source_short_name || cv_msg_cont ||
                             xxccp_common_pkg.char_delim_partition( gv_if_file_name_line , cv_msg_cont , 2 );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo                          -- 'XXCFO'
                                     , cv_msg_cfo_60002                        -- IFファイル名出力メッセージ
                                     , cv_tkn_file_name                        -- トークン(FILE_NAME)
                                     , gt_directory_path || lv_data_filename2  -- ファイルパス/承認済仕入先請求書LINE連携データファイル名
                                     );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    --空行挿入
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- 
    -- 同一ファイル存在チェック
    UTL_FILE.FGETATTR( gt_directory_path
                 , lv_data_filename2                                  -- LINEデータファイル名
                 , lb_fexists
                 , ln_file_size
                 , ln_block_size );
--
    -- 同一ファイル存在エラーメッセージ
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo    -- 'XXCFO'
                                                     , cv_msg_cfo_00027  -- 同一ファイル存在エラーメッセージ
                                                    )
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ファイルオープン
    BEGIN
      lf_file_handle2 := UTL_FILE.FOPEN( gt_directory_path , lv_data_filename2 , cv_open_mode_w , cn_max_linesize );
    EXCEPTION
      -- ファイルオープンエラー 
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                         cv_msg_kbn_cfo      -- XXCFO
                                                       , cv_msg_cfo_00029    -- ファイルオープンエラーメッセージ
                                                      )
                              , 1
                              , 5000
                             );
        lv_errbuf := lv_errmsg;
        --例外表示は、上位モジュールで行う。
        RAISE global_process_expt;
    END;
--
    -- 承認済仕入先請求書HEAD抽出
    BEGIN
      <<cur_ap_head_recode_loop>> 
      FOR ap_head_rec IN ap_head_cur LOOP
        lv_csv_text := NULL;
        -- HEADデータ行の作成
        lv_csv_text :=                ap_head_rec.invoice_id                  || cv_delim_comma;  -- 1:INVOICE_ID
        lv_csv_text := lv_csv_text || ap_head_rec.operating_unit              || cv_delim_comma;  -- 2:OPERATING_UNIT
        lv_csv_text := lv_csv_text || ap_head_rec.source                      || cv_delim_comma;  -- 3:SOURCE
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_num                 || cv_delim_comma;  -- 4:INVOICE_NUM
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_amount              || cv_delim_comma;  -- 5:INVOICE_AMOUNT
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_date                || cv_delim_comma;  -- 6:INVOICE_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 7:VENDOR_NAME
        lv_csv_text := lv_csv_text || ap_head_rec.vendor_num                  || cv_delim_comma;  -- 8:VENDOR_NUM
        lv_csv_text := lv_csv_text || ap_head_rec.vendor_site_code            || cv_delim_comma;  -- 9:VENDOR_SITE_CODE
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_currency_code       || cv_delim_comma;  -- 10:INVOICE_CURRENCY_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 11:PAYMENT_CURRENCY_CODE
-- Ver1.1(E132) Mod Start
--        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.description , cv_lf_str ) 
--               || cv_delim_comma;                                                               -- 12:DESCRIPTION
        IF ( gv_desc_trim_flag = cv_flag_y ) THEN
-- Ver1.3(E134) Mod Start
--          lv_csv_text := lv_csv_text || get_utf8_size_char( cn_utf8_size , xxccp_oiccommon_pkg.to_csv_string( 
--                 ap_head_rec.description , cv_lf_str )) || cv_delim_comma;                        -- 12:DESCRIPTION
          lv_csv_text := lv_csv_text || '"' || get_utf8_size_char( cn_utf8_size , 
            REPLACE( REPLACE( REPLACE( ap_head_rec.description , '"' , '""' ), CHR(13) , NULL ) , CHR(10) , '\n' )) 
             || '"' || cv_delim_comma;                                                            -- 12:DESCRIPTION
-- Ver1.3(E134) Mod End
        ELSE
          lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.description , cv_lf_str ) 
                 || cv_delim_comma;                                                               -- 12:DESCRIPTION
        END IF;
-- Ver1.1(E132) Mod End
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 13:GROUP_ID
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_type_lookup_code    || cv_delim_comma;  -- 14:INVOICE_TYPE_LOOKUP_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 15:LEGAL_ENTITY_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 16:CUST_REGISTRATION_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 17:CUST_REGISTRATION_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 18:FIRST_PARTY_REGISTRATION_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 19:THIRD_PARTY_REGISTRATION_NUM
        lv_csv_text := lv_csv_text || ap_head_rec.terms_name                  || cv_delim_comma;  -- 20:TERMS_NAME
        lv_csv_text := lv_csv_text || ap_head_rec.terms_date                  || cv_delim_comma;  -- 21:TERMS_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 22:GOODS_RECEIVED_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 23:INVOICE_RECEIVED_DATE
        lv_csv_text := lv_csv_text || ap_head_rec.gl_date                     || cv_delim_comma;  -- 24:GL_DATE
        lv_csv_text := lv_csv_text || ap_head_rec.payment_method_code         || cv_delim_comma;  -- 25:PAYMENT_METHOD_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 26:PAY_GROUP_LOOKUP_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 27:EXCLUSIVE_PAYMENT_FLAG
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 28:AMOUNT_APPLICABLE_TO_DISCOUNT
        lv_csv_text := lv_csv_text || ap_head_rec.prepay_num                  || cv_delim_comma;  -- 29:PREPAY_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 30:PREPAY_LINE_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 31:PREPAY_APPLY_AMOUNT
        lv_csv_text := lv_csv_text || ap_head_rec.prepay_gl_date              || cv_delim_comma;  -- 32:PREPAY_GL_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 33:INVOICE_INCLUDES_PREPAY_FLAG
        lv_csv_text := lv_csv_text || ap_head_rec.exchange_rate_type          || cv_delim_comma;  -- 34:EXCHANGE_RATE_TYPE
        lv_csv_text := lv_csv_text || ap_head_rec.exchange_date               || cv_delim_comma;  -- 35:EXCHANGE_DATE
        lv_csv_text := lv_csv_text || ap_head_rec.exchange_rate               || cv_delim_comma;  -- 36:EXCHANGE_RATE
        lv_csv_text := lv_csv_text || ap_head_rec.accts_pay_code_concatenated || cv_delim_comma;  -- 37:ACCTS_PAY_CODE_CONCATENATED
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 38:DOC_CATEGORY_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 39:VOUCHER_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 40:REQUESTER_FIRST_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 41:REQUESTER_LAST_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 42:REQUESTER_EMPLOYEE_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 43:DELIVERY_CHANNEL_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 44:BANK_CHARGE_BEARER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 45:REMIT_TO_SUPPLIER_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 46:REMIT_TO_SUPPLIER_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 47:REMIT_TO_ADDRESS_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 48:PAYMENT_PRIORITY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 49:SETTLEMENT_PRIORITY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 50:UNIQUE_REMITTANCE_IDENTIFIER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 51:URI_CHECK_DIGIT
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 52:PAYMENT_REASON_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 53:PAYMENT_REASON_COMMENTS
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 54:REMITTANCE_MESSAGE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 55:REMITTANCE_MESSAGE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 56:REMITTANCE_MESSAGE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 57:AWT_GROUP_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 58:SHIP_TO_LOCATION
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 59:TAXATION_COUNTRY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 60:DOCUMENT_SUB_TYPE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 61:TAX_INVOICE_INTERNAL_SEQ
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 62:SUPPLIER_TAX_INVOICE_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 63:TAX_INVOICE_RECORDING_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 64:SUPPLIER_TAX_INVOICE_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 65:SUPPLIER_TAX_EXCHANGE_RATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 66:PORT_OF_ENTRY_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 67:CORRECTION_YEAR
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 68:CORRECTION_PERIOD
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 69:IMPORT_DOCUMENT_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 70:IMPORT_DOCUMENT_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 71:CONTROL_AMOUNT
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 72:CALC_TAX_DURING_IMPORT_FLAG
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 73:ADD_TAX_TO_INV_AMT_FLAG
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute_category , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 74:ATTRIBUTE_CATEGORY
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute1         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 75:ATTRIBUTE1
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute2         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 76:ATTRIBUTE2
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute3         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 77:ATTRIBUTE3
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute4         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 78:ATTRIBUTE4
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute5         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 79:ATTRIBUTE5
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute6         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 80:ATTRIBUTE6
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute7         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 81:ATTRIBUTE7
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute8         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 82:ATTRIBUTE8
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute9         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 83:ATTRIBUTE9
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute10        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 84:ATTRIBUTE10
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute11        , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 85:ATTRIBUTE11
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute12        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 86:ATTRIBUTE12
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute13        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 87:ATTRIBUTE13
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute14        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 88:ATTRIBUTE14
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute15        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 89:ATTRIBUTE15
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 90:ATTRIBUTE_NUMBER1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 91:ATTRIBUTE_NUMBER2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 92:ATTRIBUTE_NUMBER3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 93:ATTRIBUTE_NUMBER4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 94:ATTRIBUTE_NUMBER5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 95:ATTRIBUTE_DATE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 96:ATTRIBUTE_DATE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 97:ATTRIBUTE_DATE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 98:ATTRIBUTE_DATE4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 99:ATTRIBUTE_DATE5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 100:GLOBAL_ATTRIBUTE_CATEGORY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 101:GLOBAL_ATTRIBUTE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 102:GLOBAL_ATTRIBUTE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 103:GLOBAL_ATTRIBUTE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 104:GLOBAL_ATTRIBUTE4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 105:GLOBAL_ATTRIBUTE5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 106:GLOBAL_ATTRIBUTE6
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 107:GLOBAL_ATTRIBUTE7
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 108:GLOBAL_ATTRIBUTE8
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 109:GLOBAL_ATTRIBUTE9
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 110:GLOBAL_ATTRIBUTE10
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 111:GLOBAL_ATTRIBUTE11
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 112:GLOBAL_ATTRIBUTE12
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 113:GLOBAL_ATTRIBUTE13
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 114:GLOBAL_ATTRIBUTE14
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 115:GLOBAL_ATTRIBUTE15
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 116:GLOBAL_ATTRIBUTE16
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 117:GLOBAL_ATTRIBUTE17
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 118:GLOBAL_ATTRIBUTE18
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 119:GLOBAL_ATTRIBUTE19
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 120:GLOBAL_ATTRIBUTE20
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 121:GLOBAL_ATTRIBUTE_NUMBER1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 122:GLOBAL_ATTRIBUTE_NUMBER2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 123:GLOBAL_ATTRIBUTE_NUMBER3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 124:GLOBAL_ATTRIBUTE_NUMBER4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 125:GLOBAL_ATTRIBUTE_NUMBER5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 126:GLOBAL_ATTRIBUTE_DATE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 127:GLOBAL_ATTRIBUTE_DATE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 128:GLOBAL_ATTRIBUTE_DATE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 129:GLOBAL_ATTRIBUTE_DATE4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 130:GLOBAL_ATTRIBUTE_DATE5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 131:IMAGE_DOCUMENT_URI
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 132:EXTERNAL_BANK_ACCOUNT_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 133:EXT_BANK_ACCOUNT_IBAN_NUMBER
        lv_csv_text := lv_csv_text || NULL;                                                       -- 134:REQUESTER_EMAIL_ADDRESS
        BEGIN
          -- データ行のファイル出力
          UTL_FILE.PUT_LINE( lf_file_handle1
                           , lv_csv_text
                           );
          --
          -- 出力件数カウントアップ
          gn_head_cnt := gn_head_cnt + 1;
        EXCEPTION
          WHEN OTHERS THEN
            gn_target_cnt := gn_target_cnt + gn_head_cnt;
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfo            -- XXCFO
                             , cv_msg_cfo_00030          -- メッセージ名：ファイル書き込みエラーメッセージ
                             , cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                             , SQLERRM                   -- トークン値1：SQLERRM
                             )
                         , 1
                         , 5000
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP cur_ap_head_recode_loop;
    EXCEPTION
      WHEN global_lock_expt THEN
        gn_target_cnt := gn_target_cnt + gn_head_cnt;
        lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo            -- XXCFO
                         , cv_msg_cfo_00019          -- メッセージ名：ロックエラーメッセージ
                         , cv_tkn_table              -- トークン名1：TABLE
                         , cv_msgtkn_cfo_60022       -- トークン値1：AP請求書OIF
                         )
                     , 1
                     , 5000
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ファイルクローズ
    UTL_FILE.FCLOSE( lf_file_handle1 );
    gn_target_cnt := gn_target_cnt + gn_head_cnt;
    gn_normal_cnt := gn_normal_cnt + gn_head_cnt;
    -- 出力件数を出力する
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60005                             -- メッセージ名：ファイル出力対象・件数メッセージ
                       , cv_tkn_target                                -- トークン名1：TARGET
                       , gt_directory_path || lv_data_filename1       -- トークン値1：ディレクトリパスとファイル名
                       , cv_tkn_count                                 -- トークン名2：COUNT
                       , gn_head_cnt                                  -- トークン値2：HEAD書込件数
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- HEADの抽出件数を出力する
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60004                             -- メッセージ名：検索対象・件数メッセージ
                       , cv_tkn_target                                -- トークン名1：TARGET
                       , cv_msgtkn_cfo_60022                          -- トークン値1：AP請求書OIF
                       , cv_tkn_count                                 -- トークン名2：COUNT
                       , gn_head_cnt                                  -- トークン値2：HEAD抽出件数
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- 承認済仕入先請求書LINE抽出
    <<cur_ap_line_recode_loop>>
    FOR ap_line_rec IN ap_line_cur LOOP
-- Ver1.4 Add Start
      -- TAX_CODEでのグループ化後の税合計金額が0円で、同じTAX_CODEを持つ本体合計が0円になる場合、税金レコードは作成しない。
      IF (
           ap_line_rec.line_type_lookup_code = cv_lookup_code_tax AND
           ap_line_rec.amount = 0 AND
           ap_line_rec.prorate_across_flag = cv_flag_n
         ) THEN
        --
        CONTINUE;
      END IF;
-- Ver1.4 Add End
      --
      -- 部門入力の場合、電子帳簿部門入力請求書ID/明細番号を上書き
      IF ( iv_source = cv_xx03_entry ) THEN
        BEGIN
          SELECT
            CASE
              WHEN ap_line_rec.line_type_lookup_code = cv_lookup_code_tax 
                THEN xps.invoice_id || '-' || (( ap_line_rec.line_number - 5 ) / 10 )
                ELSE xps.invoice_id || '-' || ( ap_line_rec.line_number / 10 )
            END as attribute12
          INTO
            lt_attribute12
          FROM
              ap_invoices_interface aii
            , xx03_payment_slips xps
          WHERE
                xps.invoice_num = aii.invoice_num
            AND aii.invoice_id = ap_line_rec.invoice_id
          ;
          ap_line_rec.attribute12 := lt_attribute12;
        END;
      END IF;
      lv_csv_text := NULL;
      -- LINEデータ行の作成
      lv_csv_text :=                ap_line_rec.invoice_id                  || cv_delim_comma; -- 1:INVOICE_ID
      lv_csv_text := lv_csv_text || ap_line_rec.line_number                 || cv_delim_comma; -- 2:LINE_NUMBER
      lv_csv_text := lv_csv_text || ap_line_rec.line_type_lookup_code       || cv_delim_comma; -- 3:LINE_TYPE_LOOKUP_CODE
      lv_csv_text := lv_csv_text || ap_line_rec.amount                      || cv_delim_comma; -- 4:AMOUNT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 5:QUANTITY_INVOICED
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 6:UNIT_PRICE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 7:UNIT_OF_MEAS_LOOKUP_CODE
-- Ver1.1(E132) Mod Start
--      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.description , cv_lf_str )
--             || cv_delim_comma;                                                                -- 8:DESCRIPTION
      IF ( gv_desc_trim_flag = cv_flag_y ) THEN
-- Ver1.3(E134) Mod Start
--        lv_csv_text := lv_csv_text || get_utf8_size_char( cn_utf8_size , xxccp_oiccommon_pkg.to_csv_string( 
--             ap_line_rec.description , cv_lf_str )) || cv_delim_comma;                         -- 8:DESCRIPTION
        lv_csv_text := lv_csv_text || '"' || get_utf8_size_char( cn_utf8_size ,  
          REPLACE( REPLACE ( REPLACE ( ap_line_rec.description , '"' , '""' ) , CHR(13) , NULL ) , CHR(10) ,'\n')) 
            || '"' || cv_delim_comma;                                                          -- 8:DESCRIPTION
-- Ver1.3(E134) Mod End
      ELSE
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.description , cv_lf_str )
             || cv_delim_comma;                                                                -- 8:DESCRIPTION
      END IF;
-- Ver1.1(E132) Mod End
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 9:PO_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 10:PO_LINE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 11:PO_SHIPMENT_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 12:PO_DISTRIBUTION_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 13:ITEM_DESCRIPTION
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 14:RELEASE_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 15:PURCHASING_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 16:RECEIPT_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 17:RECEIPT_LINE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 18:CONSUMPTION_ADVICE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 19:CONSUMPTION_ADVICE_LINE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 20:PACKING_SLIP
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 21:FINAL_MATCH_FLAG
      lv_csv_text := lv_csv_text || ap_line_rec.dist_code_concatenated      || cv_delim_comma; -- 22:DIST_CODE_CONCATENATED
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 23:DISTRIBUTION_SET_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 24:ACCOUNTING_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 25:ACCOUNT_SEGMENT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 26:BALANCING_SEGMENT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 27:COST_CENTER_SEGMENT
      lv_csv_text := lv_csv_text || ap_line_rec.tax_classification_code     || cv_delim_comma; -- 28:TAX_CLASSIFICATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 29:SHIP_TO_LOCATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 30:SHIP_FROM_LOCATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 31:FINAL_DISCHARGE_LOCATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 32:TRX_BUSINESS_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 33:PRODUCT_FISC_CLASSIFICATION
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 34:PRIMARY_INTENDED_USE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 35:USER_DEFINED_FISC_CLASS
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 36:PRODUCT_TYPE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 37:ASSESSABLE_VALUE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 38:PRODUCT_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 39:CONTROL_AMOUNT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 40:TAX_REGIME_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 41:TAX
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 42:TAX_STATUS_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 43:TAX_JURISDICTION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 44:TAX_RATE_CODE
      lv_csv_text := lv_csv_text || ap_line_rec.tax_rate                    || cv_delim_comma; -- 45:TAX_RATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 46:AWT_GROUP_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 47:TYPE_1099
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 48:INCOME_TAX_REGION
      lv_csv_text := lv_csv_text || ap_line_rec.prorate_across_flag         || cv_delim_comma; -- 49:PRORATE_ACROSS_FLAG
      lv_csv_text := lv_csv_text || ap_line_rec.line_group_number           || cv_delim_comma; -- 50:LINE_GROUP_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 51:COST_FACTOR_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 52:STAT_AMOUNT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 53:ASSETS_TRACKING_FLAG
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 54:ASSET_BOOK_TYPE_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 55:ASSET_CATEGORY_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 56:SERIAL_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 57:MANUFACTURER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 58:MODEL_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 59:WARRANTY_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 60:PRICE_CORRECTION_FLAG
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 61:PRICE_CORRECT_INV_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 62:PRICE_CORRECT_INV_LINE_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 63:REQUESTER_FIRST_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 64:REQUESTER_LAST_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 65:REQUESTER_EMPLOYEE_NUM
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute_category , cv_lf_str )  
             || cv_delim_comma;                                                                -- 66:ATTRIBUTE_CATEGORY
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute1 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 67:ATTRIBUTE1
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute2 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 68:ATTRIBUTE2
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute3 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 69:ATTRIBUTE3
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute4 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 70:ATTRIBUTE4
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute5 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 71:ATTRIBUTE5
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute6 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 72:ATTRIBUTE6
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute7 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 73:ATTRIBUTE7
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute8 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 74:ATTRIBUTE8
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute9 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 75:ATTRIBUTE9
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute10 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 76:ATTRIBUTE10
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute11 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 77:ATTRIBUTE11
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute12 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 78:ATTRIBUTE12
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute13 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 79:ATTRIBUTE13
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute14 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 80:ATTRIBUTE14
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute15 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 81:ATTRIBUTE15
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 82:ATTRIBUTE_NUMBER1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 83:ATTRIBUTE_NUMBER2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 84:ATTRIBUTE_NUMBER3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 85:ATTRIBUTE_NUMBER4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 86:ATTRIBUTE_NUMBER5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 87:ATTRIBUTE_DATE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 88:ATTRIBUTE_DATE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 89:ATTRIBUTE_DATE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 90:ATTRIBUTE_DATE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 91:ATTRIBUTE_DATE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 92:GLOBAL_ATTRIBUTE_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 93:GLOBAL_ATTRIBUTE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 94:GLOBAL_ATTRIBUTE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 95:GLOBAL_ATTRIBUTE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 96:GLOBAL_ATTRIBUTE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 97:GLOBAL_ATTRIBUTE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 98:GLOBAL_ATTRIBUTE6
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 99:GLOBAL_ATTRIBUTE7
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 100:GLOBAL_ATTRIBUTE8
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 101:GLOBAL_ATTRIBUTE9
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 102:GLOBAL_ATTRIBUTE10
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 103:GLOBAL_ATTRIBUTE11
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 104:GLOBAL_ATTRIBUTE12
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 105:GLOBAL_ATTRIBUTE13
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 106:GLOBAL_ATTRIBUTE14
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 107:GLOBAL_ATTRIBUTE15
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 108:GLOBAL_ATTRIBUTE16
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 109:GLOBAL_ATTRIBUTE17
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 110:GLOBAL_ATTRIBUTE18
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 111:GLOBAL_ATTRIBUTE19
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 112:GLOBAL_ATTRIBUTE20
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 113:GLOBAL_ATTRIBUTE_NUMBER1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 114:GLOBAL_ATTRIBUTE_NUMBER2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 115:GLOBAL_ATTRIBUTE_NUMBER3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 116:GLOBAL_ATTRIBUTE_NUMBER4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 117:GLOBAL_ATTRIBUTE_NUMBER5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 118:GLOBAL_ATTRIBUTE_DATE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 119:GLOBAL_ATTRIBUTE_DATE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 120:GLOBAL_ATTRIBUTE_DATE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 121:GLOBAL_ATTRIBUTE_DATE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 122:GLOBAL_ATTRIBUTE_DATE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 123:PJC_PROJECT_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 124:PJC_TASK_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 125:PJC_EXPENDITURE_TYPE_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 126:PJC_EXPENDITURE_ITEM_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 127:PJC_ORGANIZATION_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 128:PJC_PROJECT_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 129:PJC_TASK_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 130:PJC_EXPENDITURE_TYPE_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 131:PJC_ORGANIZATION_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 132:PJC_RESERVED_ATTRIBUTE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 133:PJC_RESERVED_ATTRIBUTE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 134:PJC_RESERVED_ATTRIBUTE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 135:PJC_RESERVED_ATTRIBUTE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 136:PJC_RESERVED_ATTRIBUTE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 137:PJC_RESERVED_ATTRIBUTE6
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 138:PJC_RESERVED_ATTRIBUTE7
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 139:PJC_RESERVED_ATTRIBUTE8
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 140:PJC_RESERVED_ATTRIBUTE9
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 141:PJC_RESERVED_ATTRIBUTE10
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 142:PJC_USER_DEF_ATTRIBUTE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 143:PJC_USER_DEF_ATTRIBUTE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 144:PJC_USER_DEF_ATTRIBUTE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 145:PJC_USER_DEF_ATTRIBUTE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 146:PJC_USER_DEF_ATTRIBUTE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 147:PJC_USER_DEF_ATTRIBUTE6
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 148:PJC_USER_DEF_ATTRIBUTE7
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 149:PJC_USER_DEF_ATTRIBUTE8
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 150:PJC_USER_DEF_ATTRIBUTE9
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 151:PJC_USER_DEF_ATTRIBUTE10
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 152:FISCAL_CHARGE_TYPE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 153:DEF_ACCTG_START_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 154:DEF_ACCTG_END_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 155:DEF_ACCRUAL_CODE_CONCATENATED
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 156:PJC_PROJECT_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 157:PJC_TASK_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 158:PJC_WORK_TYPE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 159:PJC_CONTRACT_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 160:PJC_CONTRACT_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 161:PJC_FUNDING_SOURCE_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 162:PJC_FUNDING_SOURCE_NUMBER
      lv_csv_text := lv_csv_text || NULL;                                                      -- 163:REQUESTER_EMAIL_ADDRESS
      BEGIN
        -- データ行のファイル出力
        UTL_FILE.PUT_LINE( lf_file_handle2
                         , lv_csv_text
                         );
        --
        -- 出力件数カウントアップ
        gn_line_cnt := gn_line_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          gn_target_cnt := gn_target_cnt + gn_line_cnt;
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                             cv_msg_kbn_cfo            -- XXCFO
                           , cv_msg_cfo_00030          -- メッセージ名：ファイル書き込みエラーメッセージ
                           , cv_tkn_sqlerrm            -- トークン名1：SQLERRM
                           , SQLERRM                   -- トークン値1：SQLERRM
                           )
                       , 1
                       , 5000
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP cur_ap_line_recode_loop;
    -- ファイルクローズ
    UTL_FILE.FCLOSE( lf_file_handle2 );
    gn_target_cnt := gn_target_cnt + gn_line_cnt;
    gn_normal_cnt := gn_normal_cnt + gn_line_cnt;
    -- 出力件数を出力する
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60005                             -- メッセージ名：ファイル出力対象・件数メッセージ
                       , cv_tkn_target                                -- トークン名1：TARGET
                       , gt_directory_path || lv_data_filename2       -- トークン値1：ディレクトリパスとファイル名
                       , cv_tkn_count                                 -- トークン名2：COUNT
                       , gn_line_cnt                                  -- トークン値2：LINE書込件数
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- LINEの検索対象件数を出力する
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60004                             -- メッセージ名：検索対象・件数メッセージ
                       , cv_tkn_target                                -- トークン名1：TARGET
                       , cv_msgtkn_cfo_60023                          -- トークン値1：ディレクトリパスとファイル名
                       , cv_tkn_count                                 -- トークン名2：COUNT
                       , gn_line_cnt                                  -- トークン値2：LINE抽出件数
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- AP請求書OIFの更新
    <<cur_ap_head_upd_loop>> 
    FOR ap_head_rec IN ap_head_cur LOOP
      BEGIN
        UPDATE 
          ap_invoices_interface aii
        SET
            aii.status = cv_status
          , aii.last_updated_by = cn_last_updated_by
          , aii.last_update_date = cd_last_update_date
          , aii.last_update_login = cn_last_update_login
          , aii.request_id = cn_request_id
        WHERE
          aii.invoice_id = ap_head_rec.invoice_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg 
                                 (
                                    cv_msg_kbn_cfo      -- XXCFO
                                  , cv_msg_cfo_00020    -- 更新エラー
                                  , cv_tkn_table        -- トークン名1：TABLE
                                  , cv_msgtkn_cfo_60022 -- トークン値1：AP請求書OIF
                                  , cv_tkn_errmsg       -- トークン名2：ERRMSG
                                  , SQLERRM             -- トークン値2：SQLERRM
                                 )
                                , 1
                                , 5000
                               );
          lv_errbuf := lv_errmsg;
          --例外表示は、上位モジュールで行う。
          RAISE global_process_expt;
      END;
    END LOOP cur_ap_head_upd_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_ap_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     --   ソース
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    )
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- <A-1．初期処理> 
    -- ===============================
    init(
      iv_source,         -- ソース
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <A-2．I/Fファイル出力> (処理結果によって後続処理を制御する場合)
    -- ===============================
    output_ap_data(
      iv_source,         -- ソース
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_source     IN  VARCHAR2       --   ソース
  )
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_source   -- ソース
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
END XXCFO007A02C;
/
