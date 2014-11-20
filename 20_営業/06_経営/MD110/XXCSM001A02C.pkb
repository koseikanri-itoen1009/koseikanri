create or replace PACKAGE BODY XXCSM001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM001A02C(body)
 * Description      : EBS(ファイルアップロードIF)に取込まれた年間計画データを
 *                  : 販売計画テーブル(アドオン)に取込みます。
 * MD.050           : 予算データチェック取込    MD050_CSM_001_A02
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_if_data            ファイルアップロードIFデータ取得(A-2)
 *  check_location         拠点データ妥当性チェック(A-5)
 *  check_item             項目妥当性チェック(A-6)
 *  insert_data            登録処理(A-7)
 *  loop_main              LOOP年間計画データ取得、セーブポイントの設定(A-3,A-4)
 *                            ・check_location
 *                            ・check_item
 *                            ・insert_data
 *  final                  終了処理(A-8)
 *  submain                メイン処理プロシージャ
 *                            ・init  
 *                            ・get_if_data
 *                            ・loop_main
 *                            ・final
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                            ・main
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/17    1.0   SCS M.Ohtsuki    新規作成
 *  2009/02/10    1.1   SCS K.Yamada     [障害CT004]取込項目順の変更対応
 *  2009/02/12    1.1   SCS K.Yamada     [障害CT012]不要なログ出力を削除
 *  2009/03/16    1.2   SCS M.Ohtsuki    [障害T1_0011]メッセージ不正の対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;           -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;             -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;            -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                           -- CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                                      -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                           -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                                      -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;                   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;                      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;                   -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                                      -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- 想定外エラーメッセージ
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- 対象件数
  gn_normal_cnt             NUMBER;                                                                 -- 正常件数
  gn_error_cnt              NUMBER;                                                                 -- エラー件数
  gn_warn_cnt               NUMBER;                                                                 -- スキップ件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM001A02C';                               -- パッケージ名
  cv_param_msg_1            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00101';                           -- パラメータ出力用メッセージ
  cv_param_msg_2            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00102';                           -- パラメータ出力用メッセージ
  cv_file_name              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';                           -- ファイル名
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                                          -- カンマ
  --エラーメッセージコード
  cv_csm_msg_004            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';                           -- 予算年度重複チェックエラーメッセージ
  cv_csm_msg_005            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- プロファイル取得エラーメッセージ
  cv_csm_msg_022            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00022';                           -- ファイルアップロードIFテーブルロック取得エラーメッセージ
  cv_csm_msg_024            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';                           -- 部門マスタチェックエラーメッセージ
  cv_csm_msg_025            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00025';                           -- 予算年度不一致チェックエラーメッセージ
  cv_csm_msg_026            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00026';                           -- 予算年月重複チェックエラーメッセージ
  cv_csm_msg_027            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00027';                           -- 年間計画データ存在チェックエラーメッセージ
  cv_csm_msg_028            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00028';                           -- 年間計画データフォーマットチェックエラーメッセージ
  cv_csm_msg_029            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00029';                           -- 項目チェックエラーメッセージ
  cv_csm_msg_040            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00040';                           -- 年間計画年月チェックエラーメッセージ
  cv_csm_msg_043            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00043';                           -- 販売計画テーブルロック取得エラーメッセージ
  cv_csm_msg_108            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00108';                           -- ファイルアップロード名称
--//+DEL START 2009/02/12 CT012 K.Yamada
--  cv_csm_msg_109            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00109';                           -- CSVファイル名
--//+DEL END   2009/02/12 CT012 K.Yamada
  --トークンコード
  cv_tkn_item               CONSTANT VARCHAR2(100) := 'ITEM';                                       -- 項目名称
  cv_tkn_plan_ym            CONSTANT VARCHAR2(100) := 'YOSAN_NENGETSU';                             -- 予算年月
  cv_tkn_loca_cd            CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                                  -- 拠点コード
  cv_tkn_prf_nm             CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- プロファイル名
  cv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';                                      -- 処理件数
  cv_tkn_count_2            CONSTANT VARCHAR2(100) := 'COUNT_2';                                    -- 行数
  cv_tkn_pl_year            CONSTANT VARCHAR2(100) := 'YOSAN_NENDO';                                -- 予算年度
  cv_tkn_err_msg            CONSTANT VARCHAR2(100) := 'ERR_MSG';                                    -- エラーメッセージ
  cv_tkn_file_id            CONSTANT VARCHAR2(100) := 'FILE_ID';                                    -- ファイルID
  cv_tkn_format             CONSTANT VARCHAR2(100) := 'FORMAT';                                     -- フォーマット
  cv_tkn_file_name          CONSTANT VARCHAR2(100) := 'FILE_NAME';                                  -- ファイル名
  cv_tkn_up_name            CONSTANT VARCHAR2(100) := 'UPLOAD_NAME';                                -- ファイルアップロード名称
  --アプリケーション短縮名
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                                      -- アプリケーション短縮名
  cv_chk_warning            CONSTANT VARCHAR2(1)   := '1';                                          -- 警告
  cv_chk_normal             CONSTANT VARCHAR2(1)   := '0';                                          -- 正常
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  TYPE gr_def_info_rtype IS RECORD                                                                  -- レコード型を宣言
      (meaning    VARCHAR2(100)                                                                     -- 項目名
      ,attribute  VARCHAR2(100)                                                                     -- 項目属性
      ,essential  VARCHAR2(100)                                                                     -- 必須フラグ
      ,figures    NUMBER                                                                            -- 項目の長さ
      );
  TYPE gt_def_info_ttype IS TABLE OF gr_def_info_rtype                                              -- テーブル型の宣言
    INDEX BY BINARY_INTEGER;
--
  TYPE gt_check_data_ttype IS TABLE OF VARCHAR2(4000)                                               -- テーブル型の宣言
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  --テーブル型変数の宣言
  gt_def_info_tab           gt_def_info_ttype;                                                      -- テーブル型変数の宣言
  gn_counter                NUMBER;                                                                 -- 処理件数カウンター
  gn_file_id                NUMBER;                                                                 -- パラメータ格納用変数
  gn_item_num               NUMBER;                                                                 -- 年間計画データ項目数格納用
  gv_format                 VARCHAR2(100);                                                          -- パラメータ格納用変数
  gv_calender_name          VARCHAR2(100);                                                          -- 年間販売計画カレンダー名格納用
  gn_object_year            NUMBER;                                                                 -- 対象年度
  gv_check_flag             VARCHAR2(1);                                                            -- チェックフラグ
  gd_process_date           DATE;                                                                   -- 業務日付
  gv_warnig_flg             VARCHAR2(1);
--  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    ov_errbuf               OUT NOCOPY VARCHAR2                                                     -- エラー・メッセージ
   ,ov_retcode              OUT NOCOPY VARCHAR2                                                     -- リターン・コード
   ,ov_errmsg               OUT NOCOPY VARCHAR2                                                     -- ユーザー・エラー・メッセージ
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';                                       -- プログラム名
    cv_calender_name        CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER';                   -- 年間販売計画カレンダー名
    cv_item_num             CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_ITEM_NUM';                   -- 年間計画データ項目数
    cv_csv_file_name        CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_FILE_NAME';                  -- CSVファイル名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode              VARCHAR2(1);                                                            -- リターン・コード
    lv_errbuf               VARCHAR2(4000);                                                         -- エラー・メッセージ
    lv_errmsg               VARCHAR2(4000);                                                         -- ユーザー・エラー・メッセージ
    lv_tkn_value            VARCHAR2(4000);                                                         -- トークン値
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_upload_obj           CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';                     -- ファイルアップロードオブジェクト
    cv_sales_pl_item        CONSTANT VARCHAR2(100) := 'XXCSM1_SALES_PLAN_ITEM';                     -- 販売項目データ項目定義
    cv_null_ok              CONSTANT VARCHAR2(100) := 'NULL_OK';                                    -- 任意項目
    cv_null_ng              CONSTANT VARCHAR2(100) := 'NULL_NG';                                    -- 必須項目
    cv_varchar              CONSTANT VARCHAR2(100) := 'VARCHAR2';                                   -- 文字列
    cv_number               CONSTANT VARCHAR2(100) := 'NUMBER';                                     -- 数値
    cv_date                 CONSTANT VARCHAR2(100) := 'DATE';                                       -- 日付
    cv_varchar_cd           CONSTANT VARCHAR2(100) := '0';                                          -- 文字列項目
    cv_number_cd            CONSTANT VARCHAR2(100) := '1';                                          -- 数値項目
    cv_date_cd              CONSTANT VARCHAR2(100) := '2';                                          -- 日付項目
    cv_not_null             CONSTANT VARCHAR2(100) := '1';                                          -- 必須
--
    -- *** ローカル変数 ***
    ln_cnt                  NUMBER;                                                                 -- カウンタ
    ln_calender_cnt         NUMBER;                                                                 -- カレンダー件数格納用
    ln_result               VARCHAR2(100);                                                          -- 処理結果
    lv_up_name              VARCHAR2(1000);                                                         -- アップロード名称出力用
    lv_file_name            VARCHAR2(1000);                                                         -- ファイル名出力用
    lv_in_file_id           VARCHAR2(1000);                                                         -- ファイルＩＤ出力用
    lv_in_format            VARCHAR2(1000);                                                         -- フォーマット出力用
--//+DEL START 2009/02/12 CT012 K.Yamada
--    lv_csv_file_name        VARCHAR2(100);                                                          -- CSVファイル名
--//+DEL END   2009/02/12 CT012 K.Yamada
    lv_upload_obj           VARCHAR2(100);                                                          -- ファイルアップロード名称
--
    get_err_expt            EXCEPTION;
    -- *** ローカル・カーソル ***
    CURSOR   get_def_info_cur                                                                       -- データ項目定義取得用カーソル
    IS
      SELECT   flv.meaning                                               meaning                    -- 内容
              ,DECODE(flv.attribute1,cv_varchar,cv_varchar_cd
                                    ,cv_number,cv_number_cd,cv_date_cd)  attribute                  -- 項目属性
              ,DECODE(flv.attribute2,cv_not_null,cv_null_ng,cv_null_ok)  essential                  -- 必須フラグ
              ,TO_NUMBER(flv.attribute3)  figures                                                   -- 項目の長さ
      FROM     fnd_lookup_values  flv                                                               -- クイックコード値
      WHERE    flv.lookup_type        = cv_sales_pl_item                                            -- 販売計画データ項目定義
        AND    flv.language           = USERENV('LANG')                                             -- 言語('JA')
        AND    flv.enabled_flag       = 'Y'                                                         -- 使用可能フラグ
        AND    flv.start_date_active <= gd_process_date                                             -- 適用開始日
        AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date                                -- 適用終了日
      ORDER BY flv.lookup_code   ASC;
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
    --A-1 業務日付の取得
    --==============================================================
--
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- 業務日付取得
--
    --==============================================================
    --A-1 プロファイル値取得
    --==============================================================
--
    gv_calender_name := FND_PROFILE.VALUE(cv_calender_name);
    gn_item_num      := FND_PROFILE.VALUE(cv_item_num);
--//+DEL START 2009/02/12 CT012 K.Yamada
--    lv_csv_file_name := FND_PROFILE.VALUE(cv_csv_file_name);
--//+DEL END   2009/02/12 CT012 K.Yamada
--
    IF (gv_calender_name IS NULL) THEN                                                              -- カレンダ名取得失敗の場合
      lv_tkn_value    := cv_calender_name;
    ELSIF (gn_item_num IS NULL) THEN                                                                -- 項目数取得失敗の場合
      lv_tkn_value    := cv_item_num;
--//+DEL START 2009/02/12 CT012 K.Yamada
--    ELSIF (lv_csv_file_name IS NULL) THEN                                                           -- CSVファイル名取得失敗の場合
--      lv_tkn_value    := cv_csv_file_name;
--//+DEL END   2009/02/12 CT012 K.Yamada
    END IF;
--
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm                             -- アプリケーション短縮名
                                           ,iv_name         => cv_csm_msg_005                       -- メッセージコード
                                           ,iv_token_name1  => cv_tkn_prf_nm                        -- トークンコード1
                                           ,iv_token_value1 => lv_tkn_value                         -- トークン値1
                                           );
      lv_errbuf := lv_errmsg;
      RAISE get_err_expt;
    END IF;
--
    --==============================================================
    --A-1  年間販売計画カレンダー有効年度取得
    --==============================================================
--
    xxcsm_common_pkg.get_yearplan_calender(
                                  id_comparison_date => cd_creation_date                            -- システム日付
                                 ,ov_status          => ln_result                                   -- 処理結果
                                 ,on_active_year     => gn_object_year                              -- 対象年度
                                 ,ov_retcode         => lv_retcode
                                 ,ov_errbuf          => lv_errbuf
                                 ,ov_errmsg          => lv_errmsg
                                 );
    IF (lv_retcode <> cv_status_normal ) THEN                                                        -- 処理結果が(異常 = 1)の場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application     => cv_xxcsm                                    -- アプリケーション短縮名
                                 ,iv_name            => cv_csm_msg_004                              -- メッセージコード
                                 ,iv_token_name1     => cv_tkn_item                                 -- トークンコード1
                                 ,iv_token_value1    => gv_calender_name                            -- トークン値1
                                 );
      lv_errbuf := lv_errmsg;
      RAISE get_err_expt;
     END IF;
    --==============================================================
    --A-1  販売計画テーブル定義情報取得
    --==============================================================
--
    ln_cnt := 0;                                                                                    -- 変数の初期化
    <<def_info_loop>>                                                                               -- テーブル定義取得LOOP
    FOR rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_def_info_tab(ln_cnt).meaning   := rec.meaning;                                             -- 項目名
      gt_def_info_tab(ln_cnt).attribute := rec.attribute;                                           -- 項目属性
      gt_def_info_tab(ln_cnt).essential := rec.essential;                                           -- 必須フラグ
      gt_def_info_tab(ln_cnt).figures   := rec.figures;                                             -- 項目の長さ
    END LOOP def_info_loop;
--
    --==============================================================
    --A-1  ファイルアップロード名称の取得
    --==============================================================
--
    SELECT   flv.meaning  meaning
    INTO     lv_upload_obj
    FROM     fnd_lookup_values flv
    WHERE    flv.lookup_type        = cv_upload_obj                                                 -- ファイルアップロードオブジェクト
      AND    flv.lookup_code        = TO_CHAR(gv_format)
      AND    flv.language           = USERENV('LANG')                                               -- 言語('JA')
      AND    flv.enabled_flag       = 'Y'                                                           -- 使用可能フラグ
      AND    flv.start_date_active <= gd_process_date                                               -- 適用開始日
      AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date;                                 -- 適用終了日
--
    --==============================================================
    --A-1 INパラメータの出力
    --==============================================================
--
    lv_up_name    := xxccp_common_pkg.get_msg(                                                      -- アップロード名称の出力
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_csm_msg_108                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_up_name                                            -- トークンコード1
                      ,iv_token_value1 => lv_upload_obj                                             -- トークン値1
                      );
--//+DEL START 2009/02/12 CT012 K.Yamada
--    lv_file_name  := xxccp_common_pkg.get_msg(                                                      -- CSVファイル名の出力
--                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
--                      ,iv_name         => cv_csm_msg_109                                            -- メッセージコード
--                      ,iv_token_name1  => cv_tkn_file_name                                          -- トークンコード1
--                      ,iv_token_value1 => lv_csv_file_name                                          -- トークン値1
--                      );
--//+DEL END   2009/02/12 CT012 K.Yamada
    lv_in_file_id := xxccp_common_pkg.get_msg(                                                      -- ファイルIDの出力
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_param_msg_1                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_id                                            -- トークンコード1
                      ,iv_token_value1 => gn_file_id                                                -- トークン値1
                      );
    lv_in_format  := xxccp_common_pkg.get_msg(                                                      -- フォーマットの出力
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_param_msg_2                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_format                                             -- トークンコード1
                      ,iv_token_value1 => gv_format                                                 -- トークン値1
                      );
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- 出力に表示
                     ,buff   => lv_up_name    || CHR(10) ||
--//+DEL START 2009/02/12 CT012 K.Yamada
--                                lv_file_name  || CHR(10) ||
--//+DEL END   2009/02/12 CT012 K.Yamada
                                lv_in_file_id || CHR(10) ||
--//+UPD START 2009/02/12 CT012 K.Yamada
--                                lv_in_format  || CHR(10)
                                lv_in_format
--//+UPD END   2009/02/12 CT012 K.Yamada
                                );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ログに表示
                     ,buff   => lv_up_name    || CHR(10) ||
--//+DEL START 2009/02/12 CT012 K.Yamada
--                                lv_file_name  || CHR(10) ||
--//+DEL END   2009/02/12 CT012 K.Yamada
                                lv_in_file_id || CHR(10) ||
--//+UPD START 2009/02/12 CT012 K.Yamada
--                                lv_in_format  || CHR(10) ||
--                                ''            || CHR(10)
                                lv_in_format
--//+UPD END   2009/02/12 CT012 K.Yamada
                                );
--
  EXCEPTION
    WHEN get_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_if_data(
    ov_errbuf     OUT NOCOPY   VARCHAR2                                                             -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY   VARCHAR2                                                             -- リターン・コード
   ,ov_errmsg     OUT NOCOPY   VARCHAR2)                                                            -- ユーザー・エラー・メッセージ
  IS
--
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';                                      -- プログラム名
--
    lv_errbuf         VARCHAR2(4000);                                                               -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);                                                                  -- リターン・コード
    lv_errmsg         VARCHAR2(4000);                                                               -- ユーザー・エラー・メッセージ
--
    ln_cnt_a          NUMBER;                                                                       -- カウンタを宣言
    ln_cnt_b          NUMBER;                                                                       -- カウンタを宣言
    ln_item_cnt       NUMBER;                                                                       -- カウンタを宣言
    lv_file_name      VARCHAR2(100);                                                                -- ファイル名格納用
    lv_created_by     VARCHAR2(100);                                                                -- 作成者格納用
    lv_creation_date  VARCHAR2(100);                                                                -- 作成日格納用
    lv_fname_op       VARCHAR2(100);                                                                -- ファイル名出力用
--
    lt_plan_item_tab  gt_check_data_ttype;                                                          --  テーブル型変数を宣言
    lt_if_data_tab    xxccp_common_pkg2.g_file_data_tbl;                                            --  テーブル型変数を宣言
--
    get_if_data_expt  EXCEPTION;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --A-2 対象データロックの取得
    --==============================================================
--
    BEGIN
      SELECT   fui.file_name         file_name                                                      -- ファイル名
              ,fui.created_by        created_by                                                     -- 作成者
              ,fui.creation_date     creation_date                                                  -- 作成日
      INTO     lv_file_name   
              ,lv_created_by
              ,lv_creation_date
      FROM     xxccp_mrp_file_ul_interface  fui                                                     -- ファイルアップロードIFテーブル
      WHERE    fui.file_id = gn_file_id                                                             -- ファイルID
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN                                                                              -- ロックに失敗した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm                           --アプリケーション短縮名
                                             ,iv_name         => cv_csm_msg_022                     --メッセージコード
                                             );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
    END;
--
    lv_fname_op := xxccp_common_pkg.get_msg(                                                        -- ファイル名の出力
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_file_name                                               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_file_name                                           -- トークンコード1
                     ,iv_token_value1 => lv_file_name                                               -- トークン値1
                     );
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- 出力に表示
                     ,buff   => lv_fname_op || CHR(10)
                     );
--//+ADD START 2009/02/12 CT012 K.Yamada
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ログに表示
                     ,buff   => lv_fname_op || CHR(10)
                     );
--//+ADD END   2009/02/12 CT012 K.Yamada
--
    xxccp_common_pkg2.blob_to_varchar2(                                                             -- BLOBデータ変換共通関数
                                   in_file_id    => gn_file_id                                      -- INパラメータ
                                   ,ov_file_data => lt_if_data_tab
                                   ,ov_errbuf    => lv_errbuf 
                                   ,ov_retcode   => lv_retcode
                                   ,ov_errmsg    => lv_errmsg 
                                   );
--
    gn_target_cnt := lt_if_data_tab.COUNT;                                                          -- 処理対象件数を格納
    ln_cnt_a      := 0;                                                                             -- カウンタを初期化
--
    <<ins_wk_loop>>                                                                                 -- ワークテーブル登録LOOP
    LOOP
      EXIT WHEN ln_cnt_a >= gn_target_cnt;
      ln_cnt_a := ln_cnt_a + 1;                                                                     -- 処理カウンタをインクリメント
      --項目数のチェック
      ln_item_cnt := (LENGTHB(lt_if_data_tab(ln_cnt_a)) -
                     (LENGTHB(REPLACE(lt_if_data_tab(ln_cnt_a),cv_msg_comma,''))) + 1);             -- データ項目数を格納
      --
      IF (gn_item_num <> ln_item_cnt) THEN                                                          -- 項目数が一致しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm                            -- アプリケーション短縮名
                                            ,iv_name         => cv_csm_msg_028                      -- メッセージコード
                                            ,iv_token_name1  => cv_tkn_count                        -- トークンコード1
                                            ,iv_token_name2  => cv_tkn_count_2                      -- トークンコード2
                                            ,iv_token_value1 => ln_item_cnt                         -- トークン値1
                                            ,iv_token_value2 => ln_cnt_a                            -- トークン値2
                                            );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
      END IF;
      --
      ln_cnt_b := 0;                                                                                -- カウンタを初期化
--
      <<get_column_loop>>                                                                           -- 項目値取得LOOP
      LOOP
        EXIT WHEN ln_cnt_b >= gn_item_num;
        ln_cnt_b := ln_cnt_b + 1;                                                                   -- カウンタをインクリメント
        lt_plan_item_tab(ln_cnt_b) := xxccp_common_pkg.char_delim_partition(                        -- デリミタ文字変換共通関数
                                                       iv_char     =>  lt_if_data_tab(ln_cnt_a)
                                                      ,iv_delim    =>  cv_msg_comma
                                                      ,in_part_num =>  (ln_cnt_b)
                                                       );                                           -- 変数に項目の値を格納
--
      END LOOP get_column_loop;
      INSERT INTO  
        xxcsm_wk_sales_plan(                                                                        -- 販売計画ワークテーブル
          plan_year                                                                                 -- 予算年度
         ,plan_ym                                                                                   -- 年月
         ,location_cd                                                                               -- 拠点コード
         ,act_work_date                                                                             -- 実働日
         ,plan_staff                                                                                -- 計画人員
         ,sale_plan_depart                                                                          -- 量販店売上計画
         ,sale_plan_cvs                                                                             -- CVS売上計画
         ,sale_plan_dealer                                                                          -- 問屋売上計画
         ,sale_plan_vendor                                                                          -- ベンダー売上計画
         ,sale_plan_others                                                                          -- その他売上計画
         ,sale_plan_total                                                                           -- 売上計画合計
         ,sale_plan_spare_1                                                                         -- 業態別売上計画（予備１）
         ,sale_plan_spare_2                                                                         -- 業態別売上計画（予備２）
         ,sale_plan_spare_3                                                                         -- 業態別売上計画（予備３）
         ,ly_revision_depart                                                                        -- 前年実績修正（量販店）
         ,ly_revision_cvs                                                                           -- 前年実績修正（CVS）
         ,ly_revision_dealer                                                                        -- 前年実績修正（問屋）
         ,ly_revision_others                                                                        -- 前年実績修正（その他）
         ,ly_revision_vendor                                                                        -- 前年実績修正（ベンダー）
         ,ly_revision_spare_1                                                                       -- 前年実績修正（予備１）
         ,ly_revision_spare_2                                                                       -- 前年実績修正（予備２）
         ,ly_revision_spare_3                                                                       -- 前年実績修正（予備３）
         ,ly_exist_total                                                                            -- 昨年売上計画_既存客（全体）
         ,ly_newly_total                                                                            -- 昨年売上計画_新規客（全体）
         ,ty_first_total                                                                            -- 本年売上計画_新規初回（全体）
         ,ty_turn_total                                                                             -- 本年売上計画_新規回転（全体）
         ,discount_total                                                                            -- 入金値引（全体）
         ,ly_exist_vd_charge                                                                        -- 昨年売上計画_既存客（VD）担当ベース
         ,ly_newly_vd_charge                                                                        -- 昨年売上計画_新規客（VD）担当ベース
         ,ty_first_vd_charge                                                                        -- 本年売上計画_新規初回（VD）担当ベース
         ,ty_turn_vd_charge                                                                         -- 本年売上計画_新規回転（VD）担当ベース
         ,ty_first_vd_get                                                                           -- 本年売上計画_新規初回（VD）獲得ベース
         ,ty_turn_vd_get                                                                            -- 本年売上計画_新規回転（VD）獲得ベース
         ,st_mon_get_total                                                                          -- 月初顧客数（全体）獲得ベース
         ,newly_get_total                                                                           -- 新規軒数（全体）獲得ベース
         ,cancel_get_total                                                                          -- 中止軒数（全体）獲得ベース
         ,newly_charge_total                                                                        -- 新規軒数（全体）担当ベース
         ,st_mon_get_vd                                                                             -- 月初顧客数（VD）獲得ベース
         ,newly_get_vd                                                                              -- 新規軒数（VD）獲得ベース
         ,cancel_get_vd                                                                             -- 中止軒数（VD）獲得ベース
         ,newly_charge_vd_own                                                                       -- 自力新規軒数（VD）担当ベース
         ,newly_charge_vd_help                                                                      -- 他力新規軒数（VD）担当ベース
         ,cancel_charge_vd                                                                          -- 中止軒数（VD）担当ベース
         ,patrol_visit_cnt                                                                          -- 巡回訪問顧客数
         ,patrol_def_visit_cnt                                                                      -- 巡回延訪問軒数
         ,vendor_visit_cnt                                                                          -- ベンダー訪問顧客数
         ,vendor_def_visit_cnt                                                                      -- ベンダー延訪問軒数
         ,public_visit_cnt                                                                          -- 一般訪問顧客数
         ,public_def_visit_cnt                                                                      -- 一般延訪問軒数
         ,def_cnt_total                                                                             -- 延訪問軒数合計
         ,vend_machine_sales_plan                                                                   -- 自販機売上計画
         ,vend_machine_margin                                                                       -- 自販機計画粗利益
         ,vend_machine_bm                                                                           -- 自販機手数料（BM）
         ,vend_machine_elect                                                                        -- 自販機手数料（電気代）
         ,vend_machine_lease                                                                        -- 自販機リース料
         ,vend_machine_manage                                                                       -- 自販機維持管理料
         ,vend_machine_sup_money                                                                    -- 自販機計画協賛金
         ,vend_machine_total                                                                        -- 自販機計画費用合計
         ,vend_machine_profit                                                                       -- 拠点自販機利益
         ,deficit_num                                                                               -- 赤字台数
         ,par_machine                                                                               -- パーマシン
         ,possession_num                                                                            -- 保有台数
         ,stock_num                                                                                 -- 在庫台数
         ,operation_num                                                                             -- 稼働台数
         ,increase                                                                                  -- 純増
         ,new_setting_own                                                                           -- 新規設置台数（自力）
         ,new_setting_help                                                                          -- 新規設置台数（他力）
         ,new_setting_total                                                                         -- 新規設置台数合計
         ,withdraw_num                                                                              -- 単独引揚台数
         ,new_num_newly                                                                             -- 新台台数（新規）
         ,new_num_replace                                                                           -- 新台台数（台替）
         ,new_num_total                                                                             -- 新台台数合計
         ,old_num_newly                                                                             -- 旧台台数（新規）
         ,old_num_replace                                                                           -- 旧台台数（台替・移設）
         ,disposal_num                                                                              -- 廃棄台数
         ,enter_num                                                                                 -- 拠点間移入台数
         ,appear_num                                                                                -- 拠点間移出台数
         ,vend_machine_plan_spare_1                                                                 -- 自動販売機計画（予備１）
         ,vend_machine_plan_spare_2                                                                 -- 自動販売機計画（予備２）
         ,vend_machine_plan_spare_3                                                                 -- 自動販売機計画（予備３）
         ,spare_1                                                                                   -- 予備１
         ,spare_2                                                                                   -- 予備２
         ,spare_3                                                                                   -- 予備３
         ,spare_4                                                                                   -- 予備４
         ,spare_5                                                                                   -- 予備５
         ,spare_6                                                                                   -- 予備６
         ,spare_7                                                                                   -- 予備７
         ,spare_8                                                                                   -- 予備８
         ,spare_9                                                                                   -- 予備９
         ,spare_10                                                                                  -- 予備１０
         )
        VALUES(
          lt_plan_item_tab(1)                                                                       -- 予算年度
         ,lt_plan_item_tab(2)                                                                       -- 年月
         ,lt_plan_item_tab(3)                                                                       -- 拠点コード
         ,lt_plan_item_tab(4)                                                                       -- 実働日
         ,lt_plan_item_tab(5)                                                                       -- 計画人員
         ,lt_plan_item_tab(6)                                                                       -- 量販店売上計画
         ,lt_plan_item_tab(7)                                                                       -- CVS売上計画
         ,lt_plan_item_tab(8)                                                                       -- 問屋売上計画
--//+UPD START 2009/02/10 CT004 K.Yamada
--         ,lt_plan_item_tab(9)                                                                       -- その他売上計画
--         ,lt_plan_item_tab(10)                                                                      -- ベンダー売上計画
         -- CSVファイルの順（その他、ベンダー）
         ,lt_plan_item_tab(10)                                                                      -- ベンダー売上計画
         ,lt_plan_item_tab(9)                                                                       -- その他売上計画
--//+UPD END   2009/02/10 CT004 K.Yamada
         ,lt_plan_item_tab(11)                                                                      -- 売上計画合計
         ,lt_plan_item_tab(12)                                                                      -- 業態別売上計画（予備１）
         ,lt_plan_item_tab(13)                                                                      -- 業態別売上計画（予備２）
         ,lt_plan_item_tab(14)                                                                      -- 業態別売上計画（予備３）
         ,lt_plan_item_tab(15)                                                                      -- 前年実績修正（量販店）
         ,lt_plan_item_tab(16)                                                                      -- 前年実績修正（CVS）
         ,lt_plan_item_tab(17)                                                                      -- 前年実績修正（問屋）
         ,lt_plan_item_tab(18)                                                                      -- 前年実績修正（その他）
         ,lt_plan_item_tab(19)                                                                      -- 前年実績修正（ベンダー）
         ,lt_plan_item_tab(20)                                                                      -- 前年実績修正（予備１）
         ,lt_plan_item_tab(21)                                                                      -- 前年実績修正（予備２）
         ,lt_plan_item_tab(22)                                                                      -- 前年実績修正（予備３）
         ,lt_plan_item_tab(23)                                                                      -- 昨年売上計画_既存客（全体）
         ,lt_plan_item_tab(24)                                                                      -- 昨年売上計画_新規客（全体）
         ,lt_plan_item_tab(25)                                                                      -- 本年売上計画_新規初回（全体）
         ,lt_plan_item_tab(26)                                                                      -- 本年売上計画_新規回転（全体）
         ,lt_plan_item_tab(27)                                                                      -- 入金値引（全体）
         ,lt_plan_item_tab(28)                                                                      -- 昨年売上計画_既存客（VD）担当ベース
         ,lt_plan_item_tab(29)                                                                      -- 昨年売上計画_新規客（VD）担当ベース
         ,lt_plan_item_tab(30)                                                                      -- 本年売上計画_新規初回（VD）担当ベース
         ,lt_plan_item_tab(31)                                                                      -- 本年売上計画_新規回転（VD）担当ベース
         ,lt_plan_item_tab(32)                                                                      -- 本年売上計画_新規初回（VD）獲得ベース
         ,lt_plan_item_tab(33)                                                                      -- 本年売上計画_新規回転（VD）獲得ベース
         ,lt_plan_item_tab(34)                                                                      -- 月初顧客数（全体）獲得ベース
         ,lt_plan_item_tab(35)                                                                      -- 新規軒数（全体）獲得ベース
         ,lt_plan_item_tab(36)                                                                      -- 中止軒数（全体）獲得ベース
         ,lt_plan_item_tab(37)                                                                      -- 新規軒数（全体）担当ベース
         ,lt_plan_item_tab(38)                                                                      -- 月初顧客数（VD）獲得ベース
         ,lt_plan_item_tab(39)                                                                      -- 新規軒数（VD）獲得ベース
         ,lt_plan_item_tab(40)                                                                      -- 中止軒数（VD）獲得ベース
         ,lt_plan_item_tab(41)                                                                      -- 自力新規軒数（VD）担当ベース
         ,lt_plan_item_tab(42)                                                                      -- 他力新規軒数（VD）担当ベース
         ,lt_plan_item_tab(43)                                                                      -- 中止軒数（VD）担当ベース
         ,lt_plan_item_tab(44)                                                                      -- 巡回訪問顧客数
         ,lt_plan_item_tab(45)                                                                      -- 巡回延訪問軒数
         ,lt_plan_item_tab(46)                                                                      -- ベンダー訪問顧客数
         ,lt_plan_item_tab(47)                                                                      -- ベンダー延訪問軒数
         ,lt_plan_item_tab(48)                                                                      -- 一般訪問顧客数
         ,lt_plan_item_tab(49)                                                                      -- 一般延訪問軒数
         ,lt_plan_item_tab(50)                                                                      -- 延訪問軒数合計
         ,lt_plan_item_tab(51)                                                                      -- 自販機売上計画
         ,lt_plan_item_tab(52)                                                                      -- 自販機計画粗利益
         ,lt_plan_item_tab(53)                                                                      -- 自販機手数料（BM）
         ,lt_plan_item_tab(54)                                                                      -- 自販機手数料（電気代）
         ,lt_plan_item_tab(55)                                                                      -- 自販機リース料
         ,lt_plan_item_tab(56)                                                                      -- 自販機維持管理料
         ,lt_plan_item_tab(57)                                                                      -- 自販機計画協賛金
         ,lt_plan_item_tab(58)                                                                      -- 自販機計画費用合計
         ,lt_plan_item_tab(59)                                                                      -- 拠点自販機利益
         ,lt_plan_item_tab(60)                                                                      -- 赤字台数
         ,lt_plan_item_tab(61)                                                                      -- パーマシン
         ,lt_plan_item_tab(62)                                                                      -- 保有台数
         ,lt_plan_item_tab(63)                                                                      -- 在庫台数
         ,lt_plan_item_tab(64)                                                                      -- 稼働台数
         ,lt_plan_item_tab(65)                                                                      -- 純増
         ,lt_plan_item_tab(66)                                                                      -- 新規設置台数（自力）
         ,lt_plan_item_tab(67)                                                                      -- 新規設置台数（他力）
         ,lt_plan_item_tab(68)                                                                      -- 新規設置台数合計
         ,lt_plan_item_tab(69)                                                                      -- 単独引揚台数
         ,lt_plan_item_tab(70)                                                                      -- 新台台数（新規）
         ,lt_plan_item_tab(71)                                                                      -- 新台台数（台替）
         ,lt_plan_item_tab(72)                                                                      -- 新台台数合計
         ,lt_plan_item_tab(73)                                                                      -- 旧台台数（新規）
         ,lt_plan_item_tab(74)                                                                      -- 旧台台数（台替・移設）
         ,lt_plan_item_tab(75)                                                                      -- 廃棄台数
         ,lt_plan_item_tab(76)                                                                      -- 拠点間移入台数
         ,lt_plan_item_tab(77)                                                                      -- 拠点間移出台数
         ,lt_plan_item_tab(78)                                                                      -- 自動販売機計画（予備１）
         ,lt_plan_item_tab(79)                                                                      -- 自動販売機計画（予備２）
         ,lt_plan_item_tab(80)                                                                      -- 自動販売機計画（予備３）
         ,lt_plan_item_tab(81)                                                                      -- 予備１
         ,lt_plan_item_tab(82)                                                                      -- 予備２
         ,lt_plan_item_tab(83)                                                                      -- 予備３
         ,lt_plan_item_tab(84)                                                                      -- 予備４
         ,lt_plan_item_tab(85)                                                                      -- 予備５
         ,lt_plan_item_tab(86)                                                                      -- 予備６
         ,lt_plan_item_tab(87)                                                                      -- 予備７
         ,lt_plan_item_tab(88)                                                                      -- 予備８
         ,lt_plan_item_tab(89)                                                                      -- 予備９
         ,lt_plan_item_tab(90)                                                                      -- 予備１０
        );
    END LOOP ins_wk_loop;
--
  EXCEPTION
    WHEN get_if_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END  get_if_data;
--
  /**********************************************************************************
   * Procedure Name   :  check_location
   * Description      :  拠点データ妥当性チェック(A-5)
   ***********************************************************************************/
--
  PROCEDURE check_location(
    iv_plan_year    IN  VARCHAR2                                                                    -- 対象年度
   ,iv_location_cd  IN  VARCHAR2                                                                    -- 拠点コード
   ,ov_errbuf       OUT NOCOPY VARCHAR2                                                             -- エラー・メッセージ
   ,ov_retcode      OUT NOCOPY VARCHAR2                                                             -- リターン・コード
   ,ov_errmsg       OUT NOCOPY VARCHAR2)                                                            -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'check_location';                                     -- プログラム名
    cv_cust_cd_1    CONSTANT VARCHAR2(1)   := '1';                                                  -- 顧客区分（1）
    cv_month_1      CONSTANT VARCHAR2(10)  := '01';                                                 -- 1月
    cv_month_2      CONSTANT VARCHAR2(10)  := '02';                                                 -- 2月
    cv_month_3      CONSTANT VARCHAR2(10)  := '03';                                                 -- 3月
    cv_month_4      CONSTANT VARCHAR2(10)  := '04';                                                 -- 4月
    cv_month_5      CONSTANT VARCHAR2(10)  := '05';                                                 -- 5月
    cv_month_6      CONSTANT VARCHAR2(10)  := '06';                                                 -- 6月
    cv_month_7      CONSTANT VARCHAR2(10)  := '07';                                                 -- 7月
    cv_month_8      CONSTANT VARCHAR2(10)  := '08';                                                 -- 8月
    cv_month_9      CONSTANT VARCHAR2(10)  := '09';                                                 -- 9月
    cv_month_10     CONSTANT VARCHAR2(10)  := '10';                                                 -- 10月
    cv_month_11     CONSTANT VARCHAR2(10)  := '11';                                                 -- 11月
    cv_month_12     CONSTANT VARCHAR2(10)  := '12';                                                 -- 12月
    cn_cnt_12       CONSTANT NUMBER(10)    := '12';                                                 -- 12ヶ月チェック
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf       VARCHAR2(4000);                                                                 -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);                                                                    -- リターン・コード
    lv_errmsg       VARCHAR2(4000);                                                                 -- ユーザー・エラー・メッセージ
    lv_plan_ym      VARCHAR2(1000);
    lv_year         VARCHAR2(1000);
    lv_month        VARCHAR2(1000);
    lv_data_cnt     VARCHAR2(1000);
    lv_planyear     VARCHAR2(1000);
    lv_location_cd  VARCHAR2(1000);
    ln_check_12     NUMBER;                                                                         -- 12ヶ月分データ格納用
    ln_location_cnt NUMBER;                                                                         -- 拠点コード件数格納用
--  
    CURSOR data_lock_cur                                                                            -- ロック取得カーソル
    IS
      SELECT      xsp.plan_year        plan_year                                                    -- 予算年度
                 ,xsp.location_cd      location_cd                                                  -- 拠点コード
      INTO        lv_planyear
                 ,lv_location_cd
      FROM        xxcsm_sales_plan  xsp                                                             -- 販売計画テーブル
      WHERE       xsp.plan_year     =  iv_plan_year                                                 -- 予算年度
        AND       xsp.location_cd   =  iv_location_cd                                               -- 拠点コード
      FOR UPDATE  NOWAIT;
--
    chk_warning_expt  EXCEPTION;
  BEGIN
--
    ov_retcode      := cv_status_normal;                                                            -- 変数の初期化
    ln_check_12     := 0;
    ln_location_cnt := 0;
--
      --==============================================================
      --  年間データ存在チェック(12ヶ月分のデータチェック)
      --==============================================================
--
    IF (iv_plan_year IS NOT NULL AND iv_location_cd IS NOT NULL) THEN                               -- 予算年度、拠点コードがNULL以外の場合
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- 販売計画ワークテーブル
      WHERE   wsp.plan_year   = iv_plan_year
      AND     wsp.location_cd = iv_location_cd;                                                      -- 予算年度、拠点コードが一致
    END IF;
--
/***************************************************************************************************
  --以下の記述ははエラー時の件数をカウントする為のSQLです。
****************************************************************************************************/
    IF (iv_plan_year IS NOT NULL AND iv_location_cd IS  NULL) THEN                                  -- 予算年度がNULL以外、拠点コードがNULLの場合
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- 販売計画ワークテーブル
      WHERE   wsp.plan_year   = iv_plan_year
      AND     wsp.location_cd IS NULL;                                                              -- 予算年度が一致、拠点コードがNULL
    END IF;
--
    IF (iv_plan_year IS  NULL AND iv_location_cd IS NOT NULL) THEN                                  -- 予算年度がNULL、拠点コードがNULL以外の場合
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- 販売計画ワークテーブル
      WHERE   wsp.plan_year IS NULL
      AND     wsp.location_cd =iv_location_cd;                                                      -- 予算年度がNULL、拠点コードが一致
    END IF;
--
    IF (iv_plan_year IS  NULL AND iv_location_cd IS  NULL) THEN                                     -- 予算年度、拠点コードがNULLの場合
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- 販売計画ワークテーブル
      WHERE   wsp.plan_year IS NULL
      AND     wsp.location_cd IS NULL;                                                              -- 予算年度、拠点コードがNULL
    END IF;
/***************************************************************************************************
****************************************************************************************************/
--
    gn_counter := ln_check_12;                                                                      -- 変数に対象件数を格納
--
    IF (ln_check_12 <> cn_cnt_12) THEN                                                              -- 対象件数が12以外の場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    --アプリケーション短縮名
                    ,iv_name         => cv_csm_msg_027                                              --メッセージコード
                    ,iv_token_name1  => cv_tkn_loca_cd                                              --トークンコード1
                    ,iv_token_value1 => iv_location_cd                                              --トークン値1
                     );
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- 出力に表示
                       ,buff   => lv_errmsg                                                         -- ユーザー・エラーメッセージ
                       );
      gv_check_flag := cv_chk_warning;                                                              -- チェックフラグ→ON
      RAISE chk_warning_expt;
    END IF;
--
      --==============================================================
      --  A-5  拠点情報存在チェック
      --==============================================================
--
    SELECT COUNT(1)
    INTO   ln_location_cnt
    FROM   hz_cust_accounts  hca                                                                    -- 顧客マスタ
    WHERE  hca.customer_class_code = cv_cust_cd_1                                                   -- 顧客区分
      AND  hca.account_number = iv_location_cd;                                                     -- 顧客コード
--
    IF (ln_location_cnt = 0) THEN                                                                   -- 拠点コードが存在しない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm                             -- アプリケーション短縮名
                                           ,iv_name         => cv_csm_msg_024                       -- メッセージコード
                                           ,iv_token_name1  => cv_tkn_loca_cd                       -- トークンコード1
                                           ,iv_token_value1 => iv_location_cd                       -- トークン値1
                                           ); 
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- 出力に表示
                       ,buff   => lv_errmsg                                                         -- ユーザー・エラーメッセージ
                       );
      gv_check_flag := cv_chk_warning;                                                              -- チェックフラグ→ON
      RAISE chk_warning_expt;
    END IF;
--
      --==============================================================
      --  A-5  予算年度チェック
      --==============================================================
--
    IF (iv_plan_year <> gn_object_year) THEN                                                        -- 予算年度が不一致の場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm_msg_025                                              -- メッセージコード
                    ,iv_token_name1  => cv_tkn_pl_year                                              -- トークンコード1
                    ,iv_token_name2  => cv_tkn_loca_cd                                              -- トークンコード2
                    ,iv_token_value1 => iv_plan_year                                                -- トークン値1
                    ,iv_token_value2 => iv_location_cd                                              -- トークン値2
                    );
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- 出力に表示
                       ,buff   => lv_errmsg                                                         -- ユーザー・エラーメッセージ
                       );
      gv_check_flag := cv_chk_warning;                                                              -- チェックフラグ→ON
      RAISE chk_warning_expt;
    END IF;
--
      --==============================================================
      --  A-5  年間データ存在チェック
      --==============================================================
--
    BEGIN
      SELECT   spv.plan_ym                                   plan_ym                                -- 年月
              ,spv.year                                      year                                   -- 年
              ,spv.month                                     month                                  -- 月
              ,spv.data_cnt                                  data_cnt                               -- 対象月データ存在件数
      INTO     lv_plan_ym
              ,lv_year
              ,lv_month
              ,lv_data_cnt
      FROM     (SELECT    wsp.plan_ym                        plan_ym                                -- 年月
                         ,SUBSTRB(wsp.plan_ym,1,4)           year                                   -- 年
                         ,NVL(SUBSTRB(wsp.plan_ym,5,2),'00') month                                  -- 月
                         ,COUNT(1)                           data_cnt                               -- 対象月データ存在件数
                FROM      xxcsm_wk_sales_plan                wsp                                    -- 販売計画ワークテーブル
                WHERE     wsp.plan_year         = iv_plan_year                                      -- 予算年度
                  AND     wsp.location_cd       = iv_location_cd                                    -- 拠点コード
                GROUP BY  wsp.plan_ym                                                               -- 年月
               )  spv                                                                               -- 販売計画月別件数ビュー
      WHERE    (spv.data_cnt <> 1                                                                   -- データ存在件数が1件以外
         OR    (spv.year = iv_plan_year                                                             -- 年 = 予算年度
               AND spv.month NOT IN (cv_month_5                                                     -- 5月
                                    ,cv_month_6                                                     -- 6月
                                    ,cv_month_7                                                     -- 7月
                                    ,cv_month_8                                                     -- 8月
                                    ,cv_month_9                                                     -- 9月
                                    ,cv_month_10                                                    -- 10月
                                    ,cv_month_11                                                    -- 11月
                                    ,cv_month_12                                                    -- 12月
                                    ))
         OR    (spv.year = TO_CHAR(TO_NUMBER(iv_plan_year) + 1)                                     -- 年 = 予算年度 + 1
               AND spv.month NOT IN (cv_month_1                                                     -- 1月
                                    ,cv_month_2                                                     -- 2月
                                    ,cv_month_3                                                     -- 3月
                                    ,cv_month_4                                                     -- 4月
                                    ))
         OR    spv.year NOT IN  (iv_plan_year,TO_CHAR(TO_NUMBER(iv_plan_year) + 1)))
        AND    ROWNUM = 1;
--
      IF (lv_data_cnt > 1) THEN                                                                     -- 重複データが存在する場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_csm_msg_026                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_plan_ym                                            -- トークンコード1
                      ,iv_token_name2  => cv_tkn_loca_cd                                              -- トークンコード2
                      ,iv_token_value1 => lv_plan_ym                                                -- トークン値1
                      ,iv_token_value2 => iv_location_cd                                            -- トークン値2
                      );
        fnd_file.put_line(
                          which  => FND_FILE.OUTPUT                                                 -- 出力に表示
                         ,buff   => lv_errmsg                                                       -- ユーザー・エラーメッセージ
                         );
        lv_errbuf := lv_errmsg;
        gv_check_flag := cv_chk_warning;                                                            -- チェックフラグ→ON
        RAISE chk_warning_expt;
      ELSE                                                                                          -- 年月に不正な値が設定されていた場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_csm_msg_040                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_plan_ym                                            -- トークンコード1
                      ,iv_token_name2  => cv_tkn_loca_cd                                            -- トークンコード2
                      ,iv_token_value1 => lv_plan_ym                                                -- トークン値1
                      ,iv_token_value2 => iv_location_cd                                            -- トークン値2
                      );
        fnd_file.put_line(
                          which  => FND_FILE.OUTPUT                                                 -- 出力に表示
                         ,buff   => lv_errmsg                                                       -- ユーザー・エラーメッセージ
                         );
        gv_check_flag := cv_chk_warning;                                                            -- チェックフラグ→ON
        RAISE chk_warning_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      NULL;
    END;
--
      --==============================================================
      --  A-5   販売計画テーブル既存データのロック
      --==============================================================
--
    BEGIN
      OPEN  data_lock_cur;
      CLOSE data_lock_cur;
    EXCEPTION
      WHEN OTHERS THEN                                                                              -- ロックの取得に失敗した場合
        IF (data_lock_cur%ISOPEN) THEN
          CLOSE data_lock_cur;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- アプリケーション短縮名
                      ,iv_name         => cv_csm_msg_043                                            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_pl_year                                            -- トークンコード1
                      ,iv_token_name2  => cv_tkn_loca_cd                                            -- トークンコード2
                      ,iv_token_value1 => iv_plan_year                                              -- トークン値1
                      ,iv_token_value2 => iv_location_cd                                            -- トークン値2
                      );
        fnd_file.put_line(
                       which  => FND_FILE.OUTPUT                                                    -- 出力に表示
                      ,buff   => lv_errmsg                                                          -- ユーザー・エラーメッセージ
                       );
        gv_check_flag := cv_chk_warning;                                                            -- チェックフラグ→ON
        RAISE chk_warning_expt;
    END;
--
      --==============================================================
      --  A-5   販売計画テーブル同一データの削除
      --==============================================================
--
    DELETE   FROM  xxcsm_sales_plan   xsp                                                           -- 販売計画テーブル
    WHERE    xsp.plan_year    = iv_plan_year                                                        -- 予算年度
      AND    xsp.location_cd  = iv_location_cd;                                                     -- 拠点コード
--
  EXCEPTION
--
    -- *** 共通関数例外ハンドラ ***
    WHEN chk_warning_expt THEN
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_location;
--
  /**********************************************************************************
   * Procedure Name   : check_item
   * Description      : 項目妥当性チェック(A-6)
   ***********************************************************************************/
--
  PROCEDURE check_item(
    ir_plan_rec   IN  xxcsm_wk_sales_plan%ROWTYPE                                                   -- 対象レコード
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item';                                           -- プログラム名
    cn_zero       CONSTANT NUMBER        := 0;
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
    ln_check_cnt  NUMBER;
--
    lt_check_data_tab gt_check_data_ttype;                                                          -- テーブル型変数の宣言
    chk_warning_expt  EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;                                                                 -- 変数の初期化
--
    lt_check_data_tab(1)  := ir_plan_rec.plan_year;                                                 -- 予算年度
    lt_check_data_tab(2)  := ir_plan_rec.plan_ym;                                                   -- 年月
    lt_check_data_tab(3)  := ir_plan_rec.location_cd;                                               -- 拠点コード
    lt_check_data_tab(4)  := ir_plan_rec.act_work_date;                                             -- 実働日
    lt_check_data_tab(5)  := ir_plan_rec.plan_staff;                                                -- 計画人員
    lt_check_data_tab(6)  := ir_plan_rec.sale_plan_depart;                                          -- 量販店売上計画
    lt_check_data_tab(7)  := ir_plan_rec.sale_plan_cvs;                                             -- CVS売上計画
    lt_check_data_tab(8)  := ir_plan_rec.sale_plan_dealer;                                          -- 問屋売上計画
    -- 参照タイプのコード順（ベンダー、その他）
    lt_check_data_tab(9)  := ir_plan_rec.sale_plan_vendor;                                          -- ベンダー売上計画
    lt_check_data_tab(10) := ir_plan_rec.sale_plan_others;                                          -- その他売上計画
    lt_check_data_tab(11) := ir_plan_rec.sale_plan_total;                                           -- 売上計画合計
    lt_check_data_tab(12) := ir_plan_rec.sale_plan_spare_1;                                         -- 業態別売上計画（予備１）
    lt_check_data_tab(13) := ir_plan_rec.sale_plan_spare_2;                                         -- 業態別売上計画（予備２）
    lt_check_data_tab(14) := ir_plan_rec.sale_plan_spare_3;                                         -- 業態別売上計画（予備３）
    lt_check_data_tab(15) := ir_plan_rec.ly_revision_depart;                                        -- 前年実績修正（量販店）
    lt_check_data_tab(16) := ir_plan_rec.ly_revision_cvs;                                           -- 前年実績修正（CVS）
    lt_check_data_tab(17) := ir_plan_rec.ly_revision_dealer;                                        -- 前年実績修正（問屋）
    lt_check_data_tab(18) := ir_plan_rec.ly_revision_others;                                        -- 前年実績修正（その他）
    lt_check_data_tab(19) := ir_plan_rec.ly_revision_vendor;                                        -- 前年実績修正（ベンダー）
    lt_check_data_tab(20) := ir_plan_rec.ly_revision_spare_1;                                       -- 前年実績修正（予備１）
    lt_check_data_tab(21) := ir_plan_rec.ly_revision_spare_2;                                       -- 前年実績修正（予備２）
    lt_check_data_tab(22) := ir_plan_rec.ly_revision_spare_3;                                       -- 前年実績修正（予備３）
    lt_check_data_tab(23) := ir_plan_rec.ly_exist_total;                                            -- 昨年売上計画_既存客（全体）
    lt_check_data_tab(24) := ir_plan_rec.ly_newly_total;                                            -- 昨年売上計画_新規客（全体）
    lt_check_data_tab(25) := ir_plan_rec.ty_first_total;                                            -- 本年売上計画_新規初回（全体）
    lt_check_data_tab(26) := ir_plan_rec.ty_turn_total;                                             -- 本年売上計画_新規回転（全体）
    lt_check_data_tab(27) := ir_plan_rec.discount_total;                                            -- 入金値引（全体）
    lt_check_data_tab(28) := ir_plan_rec.ly_exist_vd_charge;                                        -- 昨年売上計画_既存客（VD）担当
    lt_check_data_tab(29) := ir_plan_rec.ly_newly_vd_charge;                                        -- 昨年売上計画_新規客（VD）担当
    lt_check_data_tab(30) := ir_plan_rec.ty_first_vd_charge;                                        -- 本年売上計画_新規初回（VD）担
    lt_check_data_tab(31) := ir_plan_rec.ty_turn_vd_charge;                                         -- 本年売上計画_新規回転（VD）担
    lt_check_data_tab(32) := ir_plan_rec.ty_first_vd_get;                                           -- 本年売上計画_新規初回（VD）獲
    lt_check_data_tab(33) := ir_plan_rec.ty_turn_vd_get;                                            -- 本年売上計画_新規回転（VD）獲
    lt_check_data_tab(34) := ir_plan_rec.st_mon_get_total;                                          -- 月初顧客数（全体）獲得ベース
    lt_check_data_tab(35) := ir_plan_rec.newly_get_total;                                           -- 新規軒数（全体）獲得ベース
    lt_check_data_tab(36) := ir_plan_rec.cancel_get_total;                                          -- 中止軒数（全体）獲得ベース
    lt_check_data_tab(37) := ir_plan_rec.newly_charge_total;                                        -- 新規軒数（全体）担当ベース
    lt_check_data_tab(38) := ir_plan_rec.st_mon_get_vd;                                             -- 月初顧客数（VD）獲得ベース
    lt_check_data_tab(39) := ir_plan_rec.newly_get_vd;                                              -- 新規軒数（VD）獲得ベース
    lt_check_data_tab(40) := ir_plan_rec.cancel_get_vd;                                             -- 中止軒数（VD）獲得ベース
    lt_check_data_tab(41) := ir_plan_rec.newly_charge_vd_own;                                       -- 自力新規軒数（VD）担当ベース
    lt_check_data_tab(42) := ir_plan_rec.newly_charge_vd_help;                                      -- 他力新規軒数（VD）担当ベース
    lt_check_data_tab(43) := ir_plan_rec.cancel_charge_vd;                                          -- 中止軒数（VD）担当ベース
    lt_check_data_tab(44) := ir_plan_rec.patrol_visit_cnt;                                          -- 巡回訪問顧客数
    lt_check_data_tab(45) := ir_plan_rec.patrol_def_visit_cnt;                                      -- 巡回延訪問軒数
    lt_check_data_tab(46) := ir_plan_rec.vendor_visit_cnt;                                          -- ベンダー訪問顧客数
    lt_check_data_tab(47) := ir_plan_rec.vendor_def_visit_cnt;                                      -- ベンダー延訪問軒数
    lt_check_data_tab(48) := ir_plan_rec.public_visit_cnt;                                          -- 一般訪問顧客数
    lt_check_data_tab(49) := ir_plan_rec.public_def_visit_cnt;                                      -- 一般延訪問軒数
    lt_check_data_tab(50) := ir_plan_rec.def_cnt_total;                                             -- 延訪問軒数合計
    lt_check_data_tab(51) := ir_plan_rec.vend_machine_sales_plan;                                   -- 自販機売上計画
    lt_check_data_tab(52) := ir_plan_rec.vend_machine_margin;                                       -- 自販機計画粗利益
    lt_check_data_tab(53) := ir_plan_rec.vend_machine_bm;                                           -- 自販機手数料（BM）
    lt_check_data_tab(54) := ir_plan_rec.vend_machine_elect;                                        -- 自販機手数料（電気代）
    lt_check_data_tab(55) := ir_plan_rec.vend_machine_lease;                                        -- 自販機リース料
    lt_check_data_tab(56) := ir_plan_rec.vend_machine_manage;                                       -- 自販機維持管理料
    lt_check_data_tab(57) := ir_plan_rec.vend_machine_sup_money;                                    -- 自販機計画協賛金
    lt_check_data_tab(58) := ir_plan_rec.vend_machine_total;                                        -- 自販機計画費用合計
    lt_check_data_tab(59) := ir_plan_rec.vend_machine_profit;                                       -- 拠点自販機利益
    lt_check_data_tab(60) := ir_plan_rec.deficit_num;                                               -- 赤字台数
    lt_check_data_tab(61) := ir_plan_rec.par_machine;                                               -- パーマシン
    lt_check_data_tab(62) := ir_plan_rec.possession_num;                                            -- 保有台数
    lt_check_data_tab(63) := ir_plan_rec.stock_num;                                                 -- 在庫台数
    lt_check_data_tab(64) := ir_plan_rec.operation_num;                                             -- 稼働台数
    lt_check_data_tab(65) := ir_plan_rec.increase;                                                  -- 純増
    lt_check_data_tab(66) := ir_plan_rec.new_setting_own;                                           -- 新規設置台数（自力）
    lt_check_data_tab(67) := ir_plan_rec.new_setting_help;                                          -- 新規設置台数（他力）
    lt_check_data_tab(68) := ir_plan_rec.new_setting_total;                                         -- 新規設置台数合計
    lt_check_data_tab(69) := ir_plan_rec.withdraw_num;                                              -- 単独引揚台数
    lt_check_data_tab(70) := ir_plan_rec.new_num_newly;                                             -- 新台台数（新規）
    lt_check_data_tab(71) := ir_plan_rec.new_num_replace;                                           -- 新台台数（台替）
    lt_check_data_tab(72) := ir_plan_rec.new_num_total;                                             -- 新台台数合計
    lt_check_data_tab(73) := ir_plan_rec.old_num_newly;                                             -- 旧台台数（新規）
    lt_check_data_tab(74) := ir_plan_rec.old_num_replace;                                           -- 旧台台数（台替・移設）
    lt_check_data_tab(75) := ir_plan_rec.disposal_num;                                              -- 廃棄台数
    lt_check_data_tab(76) := ir_plan_rec.enter_num;                                                 -- 拠点間移入台数
    lt_check_data_tab(77) := ir_plan_rec.appear_num;                                                -- 拠点間移出台数
    lt_check_data_tab(78) := ir_plan_rec.vend_machine_plan_spare_1;                                 -- 自動販売機計画（予備１）
    lt_check_data_tab(79) := ir_plan_rec.vend_machine_plan_spare_2;                                 -- 自動販売機計画（予備２）
    lt_check_data_tab(80) := ir_plan_rec.vend_machine_plan_spare_3;                                 -- 自動販売機計画（予備３）
    lt_check_data_tab(81) := ir_plan_rec.spare_1;                                                   -- 予備１
    lt_check_data_tab(82) := ir_plan_rec.spare_2;                                                   -- 予備２
    lt_check_data_tab(83) := ir_plan_rec.spare_3;                                                   -- 予備３
    lt_check_data_tab(84) := ir_plan_rec.spare_4;                                                   -- 予備４
    lt_check_data_tab(85) := ir_plan_rec.spare_5;                                                   -- 予備５
    lt_check_data_tab(86) := ir_plan_rec.spare_6;                                                   -- 予備６
    lt_check_data_tab(87) := ir_plan_rec.spare_7;                                                   -- 予備７
    lt_check_data_tab(88) := ir_plan_rec.spare_8;                                                   -- 予備８
    lt_check_data_tab(89) := ir_plan_rec.spare_9;                                                   -- 予備９
    lt_check_data_tab(90) := ir_plan_rec.spare_10;                                                  -- 予備１０
--
    ln_check_cnt := 0;                                                                              -- カウンタの初期化
--
    <<chk_column_loop>>                                                                             -- 項目妥当性チェックLOOP
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      ln_check_cnt := ln_check_cnt + 1;                                                             -- カウンタを加算
      xxccp_common_pkg2.upload_item_check(
                        iv_item_name    => gt_def_info_tab(ln_check_cnt).meaning                    -- 項目名称
                       ,iv_item_value   => lt_check_data_tab(ln_check_cnt)                          -- 項目の値
                       ,in_item_len     => gt_def_info_tab(ln_check_cnt).figures                    -- 項目の長さ(整数部分)
                       ,in_item_decimal => cn_zero                                                  -- 項目の長さ(小数点以下)
                       ,iv_item_nullflg => gt_def_info_tab(ln_check_cnt).essential                  -- 必須フラグ
                       ,iv_item_attr    => gt_def_info_tab(ln_check_cnt).attribute                  -- 項目の属性
                       ,ov_errbuf       => lv_errbuf 
                       ,ov_retcode      => lv_retcode
                       ,ov_errmsg       => lv_errmsg 
                       );
      IF (lv_retcode <> cv_status_normal) THEN                                                      -- 戻り値が異常の場合
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm                                                 -- アプリケーション短縮名
                       ,iv_name         => cv_csm_msg_029                                           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_plan_ym                                           -- トークンコード1
                       ,iv_token_name2  => cv_tkn_loca_cd                                           -- トークンコード2
--//+UPD START 2009/03/16 T1_0011 M.Ohtsuki
--                       ,iv_token_name3  => cv_tkn_item                                              -- トークンコード3
--                       ,iv_token_name4  => cv_tkn_err_msg                                           -- トークンコード4
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                       ,iv_token_name3  => cv_tkn_err_msg                                           -- トークンコード3
--//+UPD END   2009/03/16 T1_0011 M.Ohtsuki
                       ,iv_token_value1 => ir_plan_rec.plan_year                                    -- トークン値1
                       ,iv_token_value2 => ir_plan_rec.location_cd                                  -- トークン値2
--//+UPD START 2009/03/16 T1_0011 M.Ohtsuki
--                       ,iv_token_value3 => gt_def_info_tab(ln_check_cnt).meaning                    -- トークン値3
--                       ,iv_token_value4 => lv_errmsg                                                -- トークン値4
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                       ,iv_token_value3 => lv_errmsg                                                -- トークン値3
--//+UPD END   2009/03/16 T1_0011 M.Ohtsuki
                       );
         fnd_file.put_line(
                           which  => FND_FILE.OUTPUT                                                -- 出力に表示
                          ,buff   => lv_errmsg                                                      -- ユーザー・エラーメッセージ
                          );
        gv_check_flag := cv_chk_warning;                                                            -- チェックフラグ→ON
        RAISE chk_warning_expt;
      END IF;
    END LOOP chk_column_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN chk_warning_expt THEN
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_item;
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : データ登録 (A-7)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_plan_rec   IN  xxcsm_wk_sales_plan%ROWTYPE                                                   -- 対象レコード
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data';                                          -- プログラム名
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
/***************************************************************************************************
  ↓↓当プログラムは項目の妥当性チェックを行うため、インサート時は暗黙変換が行われる。
****************************************************************************************************/
    INSERT INTO  
      xxcsm_sales_plan(
        plan_year                                                                                   -- 予算年度
       ,plan_ym                                                                                     -- 年月
       ,location_cd                                                                                 -- 拠点コード
       ,act_work_date                                                                               -- 実働日
       ,plan_staff                                                                                  -- 計画人員
       ,sale_plan_depart                                                                            -- 量販店売上計画
       ,sale_plan_cvs                                                                               -- CVS売上計画
       ,sale_plan_dealer                                                                            -- 問屋売上計画
       ,sale_plan_vendor                                                                            -- ベンダー売上計画
       ,sale_plan_others                                                                            -- その他売上計画
       ,sale_plan_total                                                                             -- 売上計画合計
       ,sale_plan_spare_1                                                                           -- 業態別売上計画（予備１）
       ,sale_plan_spare_2                                                                           -- 業態別売上計画（予備２）
       ,sale_plan_spare_3                                                                           -- 業態別売上計画（予備３）
       ,ly_revision_depart                                                                          -- 前年実績修正（量販店）
       ,ly_revision_cvs                                                                             -- 前年実績修正（CVS）
       ,ly_revision_dealer                                                                          -- 前年実績修正（問屋）
       ,ly_revision_others                                                                          -- 前年実績修正（その他）
       ,ly_revision_vendor                                                                          -- 前年実績修正（ベンダー）
       ,ly_revision_spare_1                                                                         -- 前年実績修正（予備１）
       ,ly_revision_spare_2                                                                         -- 前年実績修正（予備２）
       ,ly_revision_spare_3                                                                         -- 前年実績修正（予備３）
       ,ly_exist_total                                                                              -- 昨年売上計画_既存客（全体）
       ,ly_newly_total                                                                              -- 昨年売上計画_新規客（全体）
       ,ty_first_total                                                                              -- 本年売上計画_新規初回（全体）
       ,ty_turn_total                                                                               -- 本年売上計画_新規回転（全体）
       ,discount_total                                                                              -- 入金値引（全体）
       ,ly_exist_vd_charge                                                                          -- 昨年売上計画_既存客（VD）担当ベース
       ,ly_newly_vd_charge                                                                          -- 昨年売上計画_新規客（VD）担当ベース
       ,ty_first_vd_charge                                                                          -- 本年売上計画_新規初回（VD）担当ベース
       ,ty_turn_vd_charge                                                                           -- 本年売上計画_新規回転（VD）担当ベース
       ,ty_first_vd_get                                                                             -- 本年売上計画_新規初回（VD）獲得ベース
       ,ty_turn_vd_get                                                                              -- 本年売上計画_新規回転（VD）獲得ベース
       ,st_mon_get_total                                                                            -- 月初顧客数（全体）獲得ベース
       ,newly_get_total                                                                             -- 新規軒数（全体）獲得ベース
       ,cancel_get_total                                                                            -- 中止軒数（全体）獲得ベース
       ,newly_charge_total                                                                          -- 新規軒数（全体）担当ベース
       ,st_mon_get_vd                                                                               -- 月初顧客数（VD）獲得ベース
       ,newly_get_vd                                                                                -- 新規軒数（VD）獲得ベース
       ,cancel_get_vd                                                                               -- 中止軒数（VD）獲得ベース
       ,newly_charge_vd_own                                                                         -- 自力新規軒数（VD）担当ベース
       ,newly_charge_vd_help                                                                        -- 他力新規軒数（VD）担当ベース
       ,cancel_charge_vd                                                                            -- 中止軒数（VD）担当ベース
       ,patrol_visit_cnt                                                                            -- 巡回訪問顧客数
       ,patrol_def_visit_cnt                                                                        -- 巡回延訪問軒数
       ,vendor_visit_cnt                                                                            -- ベンダー訪問顧客数
       ,vendor_def_visit_cnt                                                                        -- ベンダー延訪問軒数
       ,public_visit_cnt                                                                            -- 一般訪問顧客数
       ,public_def_visit_cnt                                                                        -- 一般延訪問軒数
       ,def_cnt_total                                                                               -- 延訪問軒数合計
       ,vend_machine_sales_plan                                                                     -- 自販機売上計画
       ,vend_machine_margin                                                                         -- 自販機計画粗利益
       ,vend_machine_bm                                                                             -- 自販機手数料（BM）
       ,vend_machine_elect                                                                          -- 自販機手数料（電気代）
       ,vend_machine_lease                                                                          -- 自販機リース料
       ,vend_machine_manage                                                                         -- 自販機維持管理料
       ,vend_machine_sup_money                                                                      -- 自販機計画協賛金
       ,vend_machine_total                                                                          -- 自販機計画費用合計
       ,vend_machine_profit                                                                         -- 拠点自販機利益
       ,deficit_num                                                                                 -- 赤字台数
       ,par_machine                                                                                 -- パーマシン
       ,possession_num                                                                              -- 保有台数
       ,stock_num                                                                                   -- 在庫台数
       ,operation_num                                                                               -- 稼働台数
       ,increase                                                                                    -- 純増
       ,new_setting_own                                                                             -- 新規設置台数（自力）
       ,new_setting_help                                                                            -- 新規設置台数（他力）
       ,new_setting_total                                                                           -- 新規設置台数合計
       ,withdraw_num                                                                                -- 単独引揚台数
       ,new_num_newly                                                                               -- 新台台数（新規）
       ,new_num_replace                                                                             -- 新台台数（台替）
       ,new_num_total                                                                               -- 新台台数合計
       ,old_num_newly                                                                               -- 旧台台数（新規）
       ,old_num_replace                                                                             -- 旧台台数（台替・移設）
       ,disposal_num                                                                                -- 廃棄台数
       ,enter_num                                                                                   -- 拠点間移入台数
       ,appear_num                                                                                  -- 拠点間移出台数
       ,vend_machine_plan_spare_1                                                                   -- 自動販売機計画（予備１）
       ,vend_machine_plan_spare_2                                                                   -- 自動販売機計画（予備２）
       ,vend_machine_plan_spare_3                                                                   -- 自動販売機計画（予備３）
       ,spare_1                                                                                     -- 予備１
       ,spare_2                                                                                     -- 予備２
       ,spare_3                                                                                     -- 予備３
       ,spare_4                                                                                     -- 予備４
       ,spare_5                                                                                     -- 予備５
       ,spare_6                                                                                     -- 予備６
       ,spare_7                                                                                     -- 予備７
       ,spare_8                                                                                     -- 予備８
       ,spare_9                                                                                     -- 予備９
       ,spare_10                                                                                    -- 予備１０
       ,created_by                                                                                  -- 作成者
       ,creation_date                                                                               -- 作成日
       ,last_updated_by                                                                             -- 最終更新者
       ,last_update_date                                                                            -- 最終更新日
       ,last_update_login                                                                           -- 最終更新ログイン
       ,request_id                                                                                  -- 要求ID
       ,program_application_id                                                                      -- プログラムアプリケーションID
       ,program_id                                                                                  -- プログラムID
       ,program_update_date                                                                         -- プログラム更新日
       )
      VALUES(
        ir_plan_rec.plan_year                                                                       -- 予算年度
       ,ir_plan_rec.plan_ym                                                                         -- 年月
       ,ir_plan_rec.location_cd                                                                     -- 拠点コード
       ,ir_plan_rec.act_work_date                                                                   -- 実働日
       ,ir_plan_rec.plan_staff                                                                      -- 計画人員
       ,ir_plan_rec.sale_plan_depart                                                                -- 量販店売上計画
       ,ir_plan_rec.sale_plan_cvs                                                                   -- CVS売上計画
       ,ir_plan_rec.sale_plan_dealer                                                                -- 問屋売上計画
       ,ir_plan_rec.sale_plan_vendor                                                                -- ベンダー売上計画
       ,ir_plan_rec.sale_plan_others                                                                -- その他売上計画
       ,ir_plan_rec.sale_plan_total                                                                 -- 売上計画合計
       ,ir_plan_rec.sale_plan_spare_1                                                               -- 業態別売上計画（予備１）
       ,ir_plan_rec.sale_plan_spare_2                                                               -- 業態別売上計画（予備２）
       ,ir_plan_rec.sale_plan_spare_3                                                               -- 業態別売上計画（予備３）
       ,ir_plan_rec.ly_revision_depart                                                              -- 前年実績修正（量販店）
       ,ir_plan_rec.ly_revision_cvs                                                                 -- 前年実績修正（CVS）
       ,ir_plan_rec.ly_revision_dealer                                                              -- 前年実績修正（問屋）
       ,ir_plan_rec.ly_revision_others                                                              -- 前年実績修正（その他）
       ,ir_plan_rec.ly_revision_vendor                                                              -- 前年実績修正（ベンダー）
       ,ir_plan_rec.ly_revision_spare_1                                                             -- 前年実績修正（予備１）
       ,ir_plan_rec.ly_revision_spare_2                                                             -- 前年実績修正（予備２）
       ,ir_plan_rec.ly_revision_spare_3                                                             -- 前年実績修正（予備３）
       ,ir_plan_rec.ly_exist_total                                                                  -- 昨年売上計画_既存客（全体）
       ,ir_plan_rec.ly_newly_total                                                                  -- 昨年売上計画_新規客（全体）
       ,ir_plan_rec.ty_first_total                                                                  -- 本年売上計画_新規初回（全体）
       ,ir_plan_rec.ty_turn_total                                                                   -- 本年売上計画_新規回転（全体）
       ,ir_plan_rec.discount_total                                                                  -- 入金値引（全体）
       ,ir_plan_rec.ly_exist_vd_charge                                                              -- 昨年売上計画_既存客（VD）担当ベース
       ,ir_plan_rec.ly_newly_vd_charge                                                              -- 昨年売上計画_新規客（VD）担当ベース
       ,ir_plan_rec.ty_first_vd_charge                                                              -- 本年売上計画_新規初回（VD）担当ベース
       ,ir_plan_rec.ty_turn_vd_charge                                                               -- 本年売上計画_新規回転（VD）担当ベース
       ,ir_plan_rec.ty_first_vd_get                                                                 -- 本年売上計画_新規初回（VD）獲得ベース
       ,ir_plan_rec.ty_turn_vd_get                                                                  -- 本年売上計画_新規回転（VD）獲得ベース
       ,ir_plan_rec.st_mon_get_total                                                                -- 月初顧客数（全体）獲得ベース
       ,ir_plan_rec.newly_get_total                                                                 -- 新規軒数（全体）獲得ベース
       ,ir_plan_rec.cancel_get_total                                                                -- 中止軒数（全体）獲得ベース
       ,ir_plan_rec.newly_charge_total                                                              -- 新規軒数（全体）担当ベース
       ,ir_plan_rec.st_mon_get_vd                                                                   -- 月初顧客数（VD）獲得ベース
       ,ir_plan_rec.newly_get_vd                                                                    -- 新規軒数（VD）獲得ベース
       ,ir_plan_rec.cancel_get_vd                                                                   -- 中止軒数（VD）獲得ベース
       ,ir_plan_rec.newly_charge_vd_own                                                             -- 自力新規軒数（VD）担当ベース
       ,ir_plan_rec.newly_charge_vd_help                                                            -- 他力新規軒数（VD）担当ベース
       ,ir_plan_rec.cancel_charge_vd                                                                -- 中止軒数（VD）担当ベース
       ,ir_plan_rec.patrol_visit_cnt                                                                -- 巡回訪問顧客数
       ,ir_plan_rec.patrol_def_visit_cnt                                                            -- 巡回延訪問軒数
       ,ir_plan_rec.vendor_visit_cnt                                                                -- ベンダー訪問顧客数
       ,ir_plan_rec.vendor_def_visit_cnt                                                            -- ベンダー延訪問軒数
       ,ir_plan_rec.public_visit_cnt                                                                -- 一般訪問顧客数
       ,ir_plan_rec.public_def_visit_cnt                                                            -- 一般延訪問軒数
       ,ir_plan_rec.def_cnt_total                                                                   -- 延訪問軒数合計
       ,ir_plan_rec.vend_machine_sales_plan                                                         -- 自販機売上計画
       ,ir_plan_rec.vend_machine_margin                                                             -- 自販機計画粗利益
       ,ir_plan_rec.vend_machine_bm                                                                 -- 自販機手数料（BM）
       ,ir_plan_rec.vend_machine_elect                                                              -- 自販機手数料（電気代）
       ,ir_plan_rec.vend_machine_lease                                                              -- 自販機リース料
       ,ir_plan_rec.vend_machine_manage                                                             -- 自販機維持管理料
       ,ir_plan_rec.vend_machine_sup_money                                                          -- 自販機計画協賛金
       ,ir_plan_rec.vend_machine_total                                                              -- 自販機計画費用合計
       ,ir_plan_rec.vend_machine_profit                                                             -- 拠点自販機利益
       ,ir_plan_rec.deficit_num                                                                     -- 赤字台数
       ,ir_plan_rec.par_machine                                                                     -- パーマシン
       ,ir_plan_rec.possession_num                                                                  -- 保有台数
       ,ir_plan_rec.stock_num                                                                       -- 在庫台数
       ,ir_plan_rec.operation_num                                                                   -- 稼働台数
       ,ir_plan_rec.increase                                                                        -- 純増
       ,ir_plan_rec.new_setting_own                                                                 -- 新規設置台数（自力）
       ,ir_plan_rec.new_setting_help                                                                -- 新規設置台数（他力）
       ,ir_plan_rec.new_setting_total                                                               -- 新規設置台数合計
       ,ir_plan_rec.withdraw_num                                                                    -- 単独引揚台数
       ,ir_plan_rec.new_num_newly                                                                   -- 新台台数（新規）
       ,ir_plan_rec.new_num_replace                                                                 -- 新台台数（台替）
       ,ir_plan_rec.new_num_total                                                                   -- 新台台数合計
       ,ir_plan_rec.old_num_newly                                                                   -- 旧台台数（新規）
       ,ir_plan_rec.old_num_replace                                                                 -- 旧台台数（台替・移設）
       ,ir_plan_rec.disposal_num                                                                    -- 廃棄台数
       ,ir_plan_rec.enter_num                                                                       -- 拠点間移入台数
       ,ir_plan_rec.appear_num                                                                      -- 拠点間移出台数
       ,ir_plan_rec.vend_machine_plan_spare_1                                                       -- 自動販売機計画（予備１）
       ,ir_plan_rec.vend_machine_plan_spare_2                                                       -- 自動販売機計画（予備２）
       ,ir_plan_rec.vend_machine_plan_spare_3                                                       -- 自動販売機計画（予備３）
       ,ir_plan_rec.spare_1                                                                         -- 予備１
       ,ir_plan_rec.spare_2                                                                         -- 予備２
       ,ir_plan_rec.spare_3                                                                         -- 予備３
       ,ir_plan_rec.spare_4                                                                         -- 予備４
       ,ir_plan_rec.spare_5                                                                         -- 予備５
       ,ir_plan_rec.spare_6                                                                         -- 予備６
       ,ir_plan_rec.spare_7                                                                         -- 予備７
       ,ir_plan_rec.spare_8                                                                         -- 予備８
       ,ir_plan_rec.spare_9                                                                         -- 予備９
       ,ir_plan_rec.spare_10                                                                        -- 予備１０
       ,cn_created_by                                                                               -- 作成者
       ,cd_creation_date                                                                            -- 作成日
       ,cn_last_updated_by                                                                          -- 最終更新者
       ,cd_last_update_date                                                                         -- 最終更新日
       ,cn_last_update_login                                                                        -- 最終更新ログイン
       ,cn_request_id                                                                               -- 要求ID
       ,cn_program_application_id                                                                   -- プログラムアプリケーションID
       ,cn_program_id                                                                               -- プログラムID
       ,cd_program_update_date                                                                      -- プログラム更新日
       );
/***************************************************************************************************
****************************************************************************************************/
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 年間計画データ取得、セーブポイントの設定 (A-3,A-4)
   ***********************************************************************************/
--
  PROCEDURE loop_main(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
--
    cv_prg_name          CONSTANT VARCHAR2(100) := 'loop_main';                                     -- プログラム名
    sub_proc_other_expt  EXCEPTION;
--
    lv_errbuf         VARCHAR2(4000);                                                               -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);                                                                  -- リターン・コード
    lv_errmsg         VARCHAR2(4000);                                                               -- ユーザー・エラー・メッセージ
    lv_location_cd    VARCHAR2(100);                                                                -- 拠点コード格納用
    lv_plan_year      VARCHAR2(100);                                                                -- 予算年度格納用
    lr_plan_rec       xxcsm_wk_sales_plan%ROWTYPE;                                                  -- テーブル型変数を宣言
--
    CURSOR get_data_cur                                                                             -- 年間計画データ取得カーソル
    IS
      SELECT     wsp.plan_year                                   plan_year                          -- 予算年度
                ,wsp.plan_ym                                     plan_ym                            -- 年月
                ,wsp.location_cd                                 location_cd                        -- 拠点コード
                ,NVL(wsp.act_work_date                   ,0)     act_work_date                      -- 実働日
                ,NVL(wsp.plan_staff                      ,0)     plan_staff                         -- 計画人員
                ,NVL((wsp.sale_plan_depart        * 1000),0)     sale_plan_depart                   -- 量販店売上計画
                ,NVL((wsp.sale_plan_cvs           * 1000),0)     sale_plan_cvs                      -- CVS売上計画
                ,NVL((wsp.sale_plan_dealer        * 1000),0)     sale_plan_dealer                   -- 問屋売上計画
                ,NVL((wsp.sale_plan_vendor        * 1000),0)     sale_plan_vendor                   -- ベンダー売上計画
                ,NVL((wsp.sale_plan_others        * 1000),0)     sale_plan_others                   -- その他売上計画
                ,NVL((wsp.sale_plan_total         * 1000),0)     sale_plan_total                    -- 売上計画合計
                ,NVL(wsp.sale_plan_spare_1               ,0)     sale_plan_spare_1                  -- 業態別売上計画（予備１）
                ,NVL(wsp.sale_plan_spare_2               ,0)     sale_plan_spare_2                  -- 業態別売上計画（予備２）
                ,NVL(wsp.sale_plan_spare_3               ,0)     sale_plan_spare_3                  -- 業態別売上計画（予備３）
                ,NVL((wsp.ly_revision_depart      * 1000),0)     ly_revision_depart                 -- 前年実績修正（量販店）
                ,NVL((wsp.ly_revision_cvs         * 1000),0)     ly_revision_cvs                    -- 前年実績修正（CVS）
                ,NVL((wsp.ly_revision_dealer      * 1000),0)     ly_revision_dealer                 -- 前年実績修正（問屋）
                ,NVL((wsp.ly_revision_others      * 1000),0)     ly_revision_others                 -- 前年実績修正（その他）
                ,NVL((wsp.ly_revision_vendor      * 1000),0)     ly_revision_vendor                 -- 前年実績修正（ベンダー）
                ,NVL(wsp.ly_revision_spare_1             ,0)     ly_revision_spare_1                -- 前年実績修正（予備１）
                ,NVL(wsp.ly_revision_spare_2             ,0)     ly_revision_spare_2                -- 前年実績修正（予備２）
                ,NVL(wsp.ly_revision_spare_3             ,0)     ly_revision_spare_3                -- 前年実績修正（予備３）
                ,NVL((wsp.ly_exist_total          * 1000),0)     ly_exist_total                     -- 昨年売上計画_既存客（全体）
                ,NVL((wsp.ly_newly_total          * 1000),0)     ly_newly_total                     -- 昨年売上計画_新規客（全体）
                ,NVL((wsp.ty_first_total          * 1000),0)     ty_first_total                     -- 本年売上計画_新規初回（全体）
                ,NVL((wsp.ty_turn_total           * 1000),0)     ty_turn_total                      -- 本年売上計画_新規回転（全体）
                ,NVL((wsp.discount_total          * 1000),0)     discount_total                     -- 入金値引（全体）
                ,NVL((wsp.ly_exist_vd_charge      * 1000),0)     ly_exist_vd_charge                 -- 昨年売上計画_既存客（VD）担当ベース
                ,NVL((wsp.ly_newly_vd_charge      * 1000),0)     ly_newly_vd_charge                 -- 昨年売上計画_新規客（VD）担当ベース
                ,NVL((wsp.ty_first_vd_charge      * 1000),0)     ty_first_vd_charge                 -- 本年売上計画_新規初回（VD）担当ベース
                ,NVL((wsp.ty_turn_vd_charge       * 1000),0)     ty_turn_vd_charge                  -- 本年売上計画_新規回転（VD）担当ベース
                ,NVL((wsp.ty_first_vd_get         * 1000),0)     ty_first_vd_get                    -- 本年売上計画_新規初回（VD）獲得ベース
                ,NVL((wsp.ty_turn_vd_get          * 1000),0)     ty_turn_vd_get                     -- 本年売上計画_新規回転（VD）獲得ベース
                ,NVL(wsp.st_mon_get_total                ,0)     st_mon_get_total                   -- 月初顧客数（全体）獲得ベース
                ,NVL(wsp.newly_get_total                 ,0)     newly_get_total                    -- 新規軒数（全体）獲得ベース
                ,NVL(wsp.cancel_get_total                ,0)     cancel_get_total                   -- 中止軒数（全体）獲得ベース
                ,NVL(wsp.newly_charge_total              ,0)     newly_charge_total                 -- 新規軒数（全体）担当ベース
                ,NVL(wsp.st_mon_get_vd                   ,0)     st_mon_get_vd                      -- 月初顧客数（VD）獲得ベース
                ,NVL(wsp.newly_get_vd                    ,0)     newly_get_vd                       -- 新規軒数（VD）獲得ベース
                ,NVL(wsp.cancel_get_vd                   ,0)     cancel_get_vd                      -- 中止軒数（VD）獲得ベース
                ,NVL(wsp.newly_charge_vd_own             ,0)     newly_charge_vd_own                -- 自力新規軒数（VD）担当ベース
                ,NVL(wsp.newly_charge_vd_help            ,0)     newly_charge_vd_help               -- 他力新規軒数（VD）担当ベース
                ,NVL(wsp.cancel_charge_vd                ,0)     cancel_charge_vd                   -- 中止軒数（VD）担当ベース
                ,NVL(wsp.patrol_visit_cnt                ,0)     patrol_visit_cnt                   -- 巡回訪問顧客数
                ,NVL(wsp.patrol_def_visit_cnt            ,0)     patrol_def_visit_cnt               -- 巡回延訪問軒数
                ,NVL(wsp.vendor_visit_cnt                ,0)     vendor_visit_cnt                   -- ベンダー訪問顧客数
                ,NVL(wsp.vendor_def_visit_cnt            ,0)     vendor_def_visit_cnt               -- ベンダー延訪問軒数
                ,NVL(wsp.public_visit_cnt                ,0)     public_visit_cnt                   -- 一般訪問顧客数
                ,NVL(wsp.public_def_visit_cnt            ,0)     public_def_visit_cnt               -- 一般延訪問軒数
                ,NVL(wsp.def_cnt_total                   ,0)     def_cnt_total                      -- 延訪問軒数合計
                ,NVL((wsp.vend_machine_sales_plan * 1000),0)     vend_machine_sales_plan            -- 自販機売上計画
                ,NVL((wsp.vend_machine_margin     * 1000),0)     vend_machine_margin                -- 自販機計画粗利益
                ,NVL((wsp.vend_machine_bm         * 1000),0)     vend_machine_bm                    -- 自販機手数料（BM）
                ,NVL((wsp.vend_machine_elect      * 1000),0)     vend_machine_elect                 -- 自販機手数料（電気代）
                ,NVL((wsp.vend_machine_lease      * 1000),0)     vend_machine_lease                 -- 自販機リース料
                ,NVL((wsp.vend_machine_manage     * 1000),0)     vend_machine_manage                -- 自販機維持管理料
                ,NVL((wsp.vend_machine_sup_money  * 1000),0)     vend_machine_sup_money             -- 自販機計画協賛金
                ,NVL((wsp.vend_machine_total      * 1000),0)     vend_machine_total                 -- 自販機計画費用合計
                ,NVL((wsp.vend_machine_profit     * 1000),0)     vend_machine_profit                -- 拠点自販機利益
                ,NVL(wsp.deficit_num                     ,0)     deficit_num                        -- 赤字台数
                ,NVL(wsp.par_machine                     ,0)     par_machine                        -- パーマシン
                ,NVL(wsp.possession_num                  ,0)     possession_num                     -- 保有台数
                ,NVL(wsp.stock_num                       ,0)     stock_num                          -- 在庫台数
                ,NVL(wsp.operation_num                   ,0)     operation_num                      -- 稼働台数
                ,NVL(wsp.increase                        ,0)     increase                           -- 純増
                ,NVL(wsp.new_setting_own                 ,0)     new_setting_own                    -- 新規設置台数（自力）
                ,NVL(wsp.new_setting_help                ,0)     new_setting_help                   -- 新規設置台数（他力）
                ,NVL(wsp.new_setting_total               ,0)     new_setting_total                  -- 新規設置台数合計
                ,NVL(wsp.withdraw_num                    ,0)     withdraw_num                       -- 単独引揚台数
                ,NVL(wsp.new_num_newly                   ,0)     new_num_newly                      -- 新台台数（新規）
                ,NVL(wsp.new_num_replace                 ,0)     new_num_replace                    -- 新台台数（台替）
                ,NVL(wsp.new_num_total                   ,0)     new_num_total                      -- 新台台数合計
                ,NVL(wsp.old_num_newly                   ,0)     old_num_newly                      -- 旧台台数（新規）
                ,NVL(wsp.old_num_replace                 ,0)     old_num_replace                    -- 旧台台数（台替・移設）
                ,NVL(wsp.disposal_num                    ,0)     disposal_num                       -- 廃棄台数
                ,NVL(wsp.enter_num                       ,0)     enter_num                          -- 拠点間移入台数
                ,NVL(wsp.appear_num                      ,0)     appear_num                         -- 拠点間移出台数
                ,NVL(wsp.vend_machine_plan_spare_1       ,0)     vend_machine_plan_spare_1          -- 自動販売機計画（予備１）
                ,NVL(wsp.vend_machine_plan_spare_2       ,0)     vend_machine_plan_spare_2          -- 自動販売機計画（予備２）
                ,NVL(wsp.vend_machine_plan_spare_3       ,0)     vend_machine_plan_spare_3          -- 自動販売機計画（予備３）
                ,NVL(wsp.spare_1                         ,0)     spare_1                            -- 予備１
                ,NVL(wsp.spare_2                         ,0)     spare_2                            -- 予備２
                ,NVL(wsp.spare_3                         ,0)     spare_3                            -- 予備３
                ,NVL(wsp.spare_4                         ,0)     spare_4                            -- 予備４
                ,NVL(wsp.spare_5                         ,0)     spare_5                            -- 予備５
                ,NVL(wsp.spare_6                         ,0)     spare_6                            -- 予備６
                ,NVL(wsp.spare_7                         ,0)     spare_7                            -- 予備７
                ,NVL(wsp.spare_8                         ,0)     spare_8                            -- 予備８
                ,NVL(wsp.spare_9                         ,0)     spare_9                            -- 予備９
                ,NVL(wsp.spare_10                        ,0)     spare_10                           -- 予備１０
      FROM      xxcsm_wk_sales_plan                       wsp                                       -- 販売計画ワークテーブル
      ORDER BY  wsp.plan_year                             ASC                                       -- 予算年月
               ,wsp.location_cd                           ASC                                       -- 拠点コード
               ,wsp.plan_ym                               ASC;                                      -- 年月
--
    get_data_rec  get_data_cur%ROWTYPE;                                                             -- 年間計画データ取得 レコード型
  BEGIN
--
    ov_retcode    := cv_status_normal;                                                              -- 変数の初期化
--
    gn_normal_cnt := 0;                                                                             -- 正常件数の初期化
    gn_warn_cnt   := 0;                                                                             -- スキップ件数の初期化
    gn_counter    := 0;
    gv_check_flag := cv_chk_normal;
--
    OPEN get_data_cur;
    <<main_loop>>                                                                                   -- メイン処理LOOP
    LOOP
      FETCH get_data_cur INTO get_data_rec;
      EXIT WHEN get_data_cur%NOTFOUND;                                                              -- 対象データ件数処理を繰り返す
--
      IF ((get_data_cur%ROWCOUNT = 1)                                                               -- 1件目
         OR (lv_plan_year <> get_data_rec.plan_year)                                                -- 予算年度ブレイク時
         OR (lv_location_cd <> get_data_rec.location_cd)                                            -- 拠点コードブレイク時
         OR (get_data_rec.plan_year IS NULL
             AND lv_plan_year IS NOT NULL)                                                          -- 年度がNULLに代わった時
         OR (get_data_rec.location_cd IS NULL 
             AND lv_location_cd IS NOT NULL)) THEN                                                  -- 拠点コードがNULLに代わった時
--
        IF (gv_check_flag = cv_chk_normal)THEN                                                      -- チェックフラグが（正常 = 0)の場合
          gn_normal_cnt := (gn_normal_cnt + gn_counter);                                            -- 正常処理件数を加算
        ELSIF (gv_check_flag = cv_chk_warning) THEN                                                 -- チェックフラグが（エラー = 1)の場合
          gn_error_cnt := (gn_error_cnt + gn_counter);                                              -- スキップ件数を加算
        END IF;
--
        gv_check_flag  := cv_chk_normal;                                                            -- チェックフラグの初期化
        gn_counter := 0;                                                                            -- 処理件数を初期化
--
    --==============================================================
    -- A-4 セーブポイントの設定
    --==============================================================
--
        SAVEPOINT check_warning;                                                                    -- セーブポイントの設定
--
        IF (gv_check_flag = cv_chk_normal) THEN                                                     -- チェックフラグが(正常=0)の場合
          check_location(                                                                           -- check_locationをコール
             iv_plan_year   => get_data_rec.plan_year                                               -- 予算年度
            ,iv_location_cd => get_data_rec.location_cd                                             -- 拠点コード
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
            );
--
          IF (lv_retcode = cv_status_error) THEN                                                    -- 戻り値がエラーの場合
            RAISE sub_proc_other_expt;
          END IF;
--
          IF (lv_retcode = cv_status_warn) THEN                                                     -- 戻り値が警告の場合
            gv_warnig_flg := cv_status_warn;
            ROLLBACK TO check_warning;                                                              -- セーブポイントへロールバック
          END IF;
        END IF;
      END IF;
      lv_location_cd := get_data_rec.location_cd;                                                   -- 拠点コードを変数に保持
      lv_plan_year   := get_data_rec.plan_year;                                                     -- 予算年度を変数に保持
--
      IF (gv_check_flag = cv_chk_normal) THEN                                                       -- チェックフラグが(正常=0)の場合
        lr_plan_rec.plan_year                 := get_data_rec.plan_year;                            -- 予算年度
        lr_plan_rec.plan_ym                   := get_data_rec.plan_ym;                              -- 年月
        lr_plan_rec.location_cd               := get_data_rec.location_cd;                          -- 拠点コード
        lr_plan_rec.act_work_date             := get_data_rec.act_work_date;                        -- 実働日
        lr_plan_rec.plan_staff                := get_data_rec.plan_staff;                           -- 計画人員
        lr_plan_rec.sale_plan_depart          := get_data_rec.sale_plan_depart;                     -- 量販店売上計画
        lr_plan_rec.sale_plan_cvs             := get_data_rec.sale_plan_cvs;                        -- CVS売上計画
        lr_plan_rec.sale_plan_dealer          := get_data_rec.sale_plan_dealer;                     -- 問屋売上計画
        lr_plan_rec.sale_plan_vendor          := get_data_rec.sale_plan_vendor;                     -- ベンダー売上計画
        lr_plan_rec.sale_plan_others          := get_data_rec.sale_plan_others;                     -- その他売上計画
        lr_plan_rec.sale_plan_total           := get_data_rec.sale_plan_total;                      -- 売上計画合計
        lr_plan_rec.sale_plan_spare_1         := get_data_rec.sale_plan_spare_1;                    -- 業態別売上計画（予備１）
        lr_plan_rec.sale_plan_spare_2         := get_data_rec.sale_plan_spare_2;                    -- 業態別売上計画（予備２）
        lr_plan_rec.sale_plan_spare_3         := get_data_rec.sale_plan_spare_3;                    -- 業態別売上計画（予備３）
        lr_plan_rec.ly_revision_depart        := get_data_rec.ly_revision_depart;                   -- 前年実績修正（量販店）
        lr_plan_rec.ly_revision_cvs           := get_data_rec.ly_revision_cvs;                      -- 前年実績修正（CVS）
        lr_plan_rec.ly_revision_dealer        := get_data_rec.ly_revision_dealer;                   -- 前年実績修正（問屋）
        lr_plan_rec.ly_revision_others        := get_data_rec.ly_revision_others;                   -- 前年実績修正（その他）
        lr_plan_rec.ly_revision_vendor        := get_data_rec.ly_revision_vendor;                   -- 前年実績修正（ベンダー）
        lr_plan_rec.ly_revision_spare_1       := get_data_rec.ly_revision_spare_1;                  -- 前年実績修正（予備１）
        lr_plan_rec.ly_revision_spare_2       := get_data_rec.ly_revision_spare_2;                  -- 前年実績修正（予備２）
        lr_plan_rec.ly_revision_spare_3       := get_data_rec.ly_revision_spare_3;                  -- 前年実績修正（予備３）
        lr_plan_rec.ly_exist_total            := get_data_rec.ly_exist_total;                       -- 昨年売上計画_既存客（全体）
        lr_plan_rec.ly_newly_total            := get_data_rec.ly_newly_total;                       -- 昨年売上計画_新規客（全体）
        lr_plan_rec.ty_first_total            := get_data_rec.ty_first_total;                       -- 本年売上計画_新規初回（全体）
        lr_plan_rec.ty_turn_total             := get_data_rec.ty_turn_total;                        -- 本年売上計画_新規回転（全体）
        lr_plan_rec.discount_total            := get_data_rec.discount_total;                       -- 入金値引（全体）
        lr_plan_rec.ly_exist_vd_charge        := get_data_rec.ly_exist_vd_charge;                   -- 昨年売上計画_既存客（VD）担当
        lr_plan_rec.ly_newly_vd_charge        := get_data_rec.ly_newly_vd_charge;                   -- 昨年売上計画_新規客（VD）担当
        lr_plan_rec.ty_first_vd_charge        := get_data_rec.ty_first_vd_charge;                   -- 本年売上計画_新規初回（VD）担当
        lr_plan_rec.ty_turn_vd_charge         := get_data_rec.ty_turn_vd_charge;                    -- 本年売上計画_新規回転（VD）担当
        lr_plan_rec.ty_first_vd_get           := get_data_rec.ty_first_vd_get;                      -- 本年売上計画_新規初回（VD）獲得
        lr_plan_rec.ty_turn_vd_get            := get_data_rec.ty_turn_vd_get;                       -- 本年売上計画_新規回転（VD）獲得
        lr_plan_rec.st_mon_get_total          := get_data_rec.st_mon_get_total;                     -- 月初顧客数（全体）獲得ベース
        lr_plan_rec.newly_get_total           := get_data_rec.newly_get_total;                      -- 新規軒数（全体）獲得ベース
        lr_plan_rec.cancel_get_total          := get_data_rec.cancel_get_total;                     -- 中止軒数（全体）獲得ベース
        lr_plan_rec.newly_charge_total        := get_data_rec.newly_charge_total;                   -- 新規軒数（全体）担当ベース
        lr_plan_rec.st_mon_get_vd             := get_data_rec.st_mon_get_vd;                        -- 月初顧客数（VD）獲得ベース
        lr_plan_rec.newly_get_vd              := get_data_rec.newly_get_vd;                         -- 新規軒数（VD）獲得ベース
        lr_plan_rec.cancel_get_vd             := get_data_rec.cancel_get_vd;                        -- 中止軒数（VD）獲得ベース
        lr_plan_rec.newly_charge_vd_own       := get_data_rec.newly_charge_vd_own;                  -- 自力新規軒数（VD）担当ベース
        lr_plan_rec.newly_charge_vd_help      := get_data_rec.newly_charge_vd_help;                 -- 他力新規軒数（VD）担当ベース
        lr_plan_rec.cancel_charge_vd          := get_data_rec.cancel_charge_vd;                     -- 中止軒数（VD）担当ベース
        lr_plan_rec.patrol_visit_cnt          := get_data_rec.patrol_visit_cnt;                     -- 巡回訪問顧客数
        lr_plan_rec.patrol_def_visit_cnt      := get_data_rec.patrol_def_visit_cnt;                 -- 巡回延訪問軒数
        lr_plan_rec.vendor_visit_cnt          := get_data_rec.vendor_visit_cnt;                     -- ベンダー訪問顧客数
        lr_plan_rec.vendor_def_visit_cnt      := get_data_rec.vendor_def_visit_cnt;                 -- ベンダー延訪問軒数
        lr_plan_rec.public_visit_cnt          := get_data_rec.public_visit_cnt;                     -- 一般訪問顧客数
        lr_plan_rec.public_def_visit_cnt      := get_data_rec.public_def_visit_cnt;                 -- 一般延訪問軒数
        lr_plan_rec.def_cnt_total             := get_data_rec.def_cnt_total;                        -- 延訪問軒数合計
        lr_plan_rec.vend_machine_sales_plan   := get_data_rec.vend_machine_sales_plan;              -- 自販機売上計画
        lr_plan_rec.vend_machine_margin       := get_data_rec.vend_machine_margin;                  -- 自販機計画粗利益
        lr_plan_rec.vend_machine_bm           := get_data_rec.vend_machine_bm;                      -- 自販機手数料（BM）
        lr_plan_rec.vend_machine_elect        := get_data_rec.vend_machine_elect;                   -- 自販機手数料（電気代）
        lr_plan_rec.vend_machine_lease        := get_data_rec.vend_machine_lease;                   -- 自販機リース料
        lr_plan_rec.vend_machine_manage       := get_data_rec.vend_machine_manage;                  -- 自販機維持管理料
        lr_plan_rec.vend_machine_sup_money    := get_data_rec.vend_machine_sup_money;               -- 自販機計画協賛金
        lr_plan_rec.vend_machine_total        := get_data_rec.vend_machine_total;                   -- 自販機計画費用合計
        lr_plan_rec.vend_machine_profit       := get_data_rec.vend_machine_profit;                  -- 拠点自販機利益
        lr_plan_rec.deficit_num               := get_data_rec.deficit_num;                          -- 赤字台数
        lr_plan_rec.par_machine               := get_data_rec.par_machine;                          -- パーマシン
        lr_plan_rec.possession_num            := get_data_rec.possession_num;                       -- 保有台数
        lr_plan_rec.stock_num                 := get_data_rec.stock_num;                            -- 在庫台数
        lr_plan_rec.operation_num             := get_data_rec.operation_num;                        -- 稼働台数
        lr_plan_rec.increase                  := get_data_rec.increase;                             -- 純増
        lr_plan_rec.new_setting_own           := get_data_rec.new_setting_own;                      -- 新規設置台数（自力）
        lr_plan_rec.new_setting_help          := get_data_rec.new_setting_help;                     -- 新規設置台数（他力）
        lr_plan_rec.new_setting_total         := get_data_rec.new_setting_total;                    -- 新規設置台数合計
        lr_plan_rec.withdraw_num              := get_data_rec.withdraw_num;                         -- 単独引揚台数
        lr_plan_rec.new_num_newly             := get_data_rec.new_num_newly;                        -- 新台台数（新規）
        lr_plan_rec.new_num_replace           := get_data_rec.new_num_replace;                      -- 新台台数（台替）
        lr_plan_rec.new_num_total             := get_data_rec.new_num_total;                        -- 新台台数合計
        lr_plan_rec.old_num_newly             := get_data_rec.old_num_newly;                        -- 旧台台数（新規）
        lr_plan_rec.old_num_replace           := get_data_rec.old_num_replace;                      -- 旧台台数（台替・移設）
        lr_plan_rec.disposal_num              := get_data_rec.disposal_num;                         -- 廃棄台数
        lr_plan_rec.enter_num                 := get_data_rec.enter_num;                            -- 拠点間移入台数
        lr_plan_rec.appear_num                := get_data_rec.appear_num;                           -- 拠点間移出台数
        lr_plan_rec.vend_machine_plan_spare_1 := get_data_rec.vend_machine_plan_spare_1;            -- 自動販売機計画（予備１）
        lr_plan_rec.vend_machine_plan_spare_2 := get_data_rec.vend_machine_plan_spare_2;            -- 自動販売機計画（予備２）
        lr_plan_rec.vend_machine_plan_spare_3 := get_data_rec.vend_machine_plan_spare_3;            -- 自動販売機計画（予備３）
        lr_plan_rec.spare_1                   := get_data_rec.spare_1;                              -- 予備１
        lr_plan_rec.spare_2                   := get_data_rec.spare_2;                              -- 予備２
        lr_plan_rec.spare_3                   := get_data_rec.spare_3;                              -- 予備３
        lr_plan_rec.spare_4                   := get_data_rec.spare_4;                              -- 予備４
        lr_plan_rec.spare_5                   := get_data_rec.spare_5;                              -- 予備５
        lr_plan_rec.spare_6                   := get_data_rec.spare_6;                              -- 予備６
        lr_plan_rec.spare_7                   := get_data_rec.spare_7;                              -- 予備７
        lr_plan_rec.spare_8                   := get_data_rec.spare_8;                              -- 予備８
        lr_plan_rec.spare_9                   := get_data_rec.spare_9;                              -- 予備９
        lr_plan_rec.spare_10                  := get_data_rec.spare_10;                             -- 予備１０
--
        check_item(                                                                                 -- check_itemをコール
           ir_plan_rec => lr_plan_rec
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
          );
--
        IF (lv_retcode = cv_status_error) THEN                                                      -- 戻り値がエラーの場合
          RAISE sub_proc_other_expt;
        END IF;
--
        IF (lv_retcode = cv_status_warn) THEN                                                       -- 戻り値が警告の場合
          gv_warnig_flg := cv_status_warn;
          ROLLBACK TO check_warning;                                                                -- セーブポイントへロールバック
        END IF;
--
        IF (gv_check_flag = cv_chk_normal) THEN                                                     -- チェックフラグが(正常=0)の場合
          insert_data(                                                                              -- insert_dataをコール
            ir_plan_rec => lr_plan_rec
           ,ov_errbuf   => lv_errbuf
           ,ov_retcode  => lv_retcode
           ,ov_errmsg   => lv_errmsg
           );
--
          IF (lv_retcode = cv_status_error) THEN                                                    -- 戻り値がエラーの場合
            RAISE sub_proc_other_expt;
          END IF;
        END IF;
      END IF;
    END LOOP main_loop;
--
    IF (gv_check_flag = cv_chk_normal)THEN                                                          -- チェックフラグが（正常 = 0)の場合
      gn_normal_cnt := (gn_normal_cnt + gn_counter);                                                -- 正常処理件数を加算
    ELSIF (gv_check_flag = cv_chk_warning) THEN                                                     -- チェックフラグが（エラー = 1)の場合
      gn_error_cnt := (gn_error_cnt + gn_counter);                                                  -- スキップ件数を加算
    END IF;
--
    CLOSE  get_data_cur;
--
    IF (gn_error_cnt >= 1) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_other_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode    := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : final
   * Description      : 終了処理 (A-8)
   ***********************************************************************************/
  PROCEDURE final(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'final';                                                -- プログラム名
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
      --==============================================================
      --  A-8    販売計画ワークテーブルデータ削除
      --==============================================================
--
    DELETE  FROM    xxcsm_wk_sales_plan;                                                            -- 販売計画ワークテーブル
--
      --==============================================================
      --  A-8    ファイルアップロードIFテーブルデータ削除
      --==============================================================
--
    DELETE  FROM    xxccp_mrp_file_ul_interface  fui                                                -- ファイルアップロードIFテーブル
    WHERE   fui.file_id = gn_file_id;                                                               -- ファイルID
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END final;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                              -- プログラム名
    lv_errbuf     VARCHAR2(4000);                                                                   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);                                                                      -- リターン・コード
    lv_errmsg     VARCHAR2(4000);                                                                   -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode := cv_status_normal;                                                                 -- リターンコードを初期化
--
    gn_target_cnt := 0;                                                                             -- 件数カウンタの初期化
    gn_normal_cnt := 0;                                                                             -- 件数カウンタの初期化
    gn_error_cnt  := 0;                                                                             -- 件数カウンタの初期化
    gn_warn_cnt   := 0;                                                                             -- 件数カウンタの初期化
--
    init(                                                                                           -- initをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
--
    get_if_data(                                                                                    -- get_if_dataをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
--
    loop_main(                                                                                      -- loop_mainをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
--
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
--
    final(                                                                                          -- finalをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
    ov_retcode := lv_retcode;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,retcode       OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,iv_file_id    IN         VARCHAR2                                                               -- ファイルID
   ,iv_format     IN         VARCHAR2                                                               -- フォーマットパターン
    )
--
  IS
--
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- エラー終了全ロールバック
--
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(5000);                                                              -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);                                                               -- 終了メッセージコード
    --
  BEGIN
--
    xxccp_common_pkg.put_log_header(                                                                -- ヘッダー情報の出力
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    gn_file_id := TO_NUMBER(iv_file_id);                                                            -- INパラメータを格納
    gv_format  := iv_format;                                                                        -- INパラメータを格納
--
    submain(                                                                                        -- submainをコール
       lv_errbuf                                                                                    -- エラー・メッセージ
      ,lv_retcode                                                                                   -- リターン・コード
      ,lv_errmsg                                                                                    -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- 空行の挿入
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    IF (gv_warnig_flg = cv_status_warn
      AND lv_retcode = cv_status_normal) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- 空行の挿入
    );
--
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
    fnd_file.put_line(
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
END XXCSM001A02C;
/
