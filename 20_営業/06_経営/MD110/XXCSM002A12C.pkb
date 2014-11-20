CREATE OR REPLACE PACKAGE BODY XXCSM002A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A12C(body)
 * Description      : 商品計画リスト(時系列)出力
 * MD.050           : 商品計画リスト(時系列)出力 MD050_CSM_002_A12
 * Version          : 1.11
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                【初期処理】A-1
 *  get_all_location    【全拠点取得】A-2
 *  check_location      【チェック処理】A-3,A-4
 *  get_all_location    【商品計画データ取得】A-5
 *  count_item_kbn      【月別商品区分の処理】A-6,A-7
 *  count_sum_item      【月別商品合計の処理】A-8,A-9
 *  count_item_group    【月別商品群の処理】A-10,A-11
 *  count_discount      【月別値引の処理】A-12,A-13
 *  count_location      【月別拠点別の処理】A-14,A-15
 *  get_output_data     【商品計画リストデータ出力】A-16
 *  submain             【実装処理】
 *  main                【コンカレント実行ファイル登録プロシージャ】
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/14    1.0   M.Ohtsuki        新規作成
 *  2009/02/09    1.1   M.Ohtsuki       ［障害CT_002］SQL条件不備の修正
 *  2009/02/10    1.2   T.Shimoji       ［障害CT_009］類似機能動作統一による修正
 *  2009/02/13    1.3   S.Son           ［障害CT_016］新商品対応
 *  2009/02/17    1.4   M.Ohtsuki       ［障害CT_025］SQL条件不備の修正
 *  2009/02/20    1.5   T.Tsukino        [障害CT_052] CSV出力の日付フォーマット不正対応
 *  2009/05/07    1.6   M.Ohtsuki        [障害T1_0858] 共通関数修正に伴うパラメータの追加
 *  2009/05/25    1.7   A.Sakawa         [障害T1_1169] 商品群名称同一時の出力レイアウト不正対応
 *  2010/12/14    1.8   Y.Kanami         [E_本稼動_05803]
 *  2011/01/06    1.9   OuKou            [E_本稼動_05803]
 *  2011/01/17    1.10  Y.Kanami         [E_本稼動_05803]PT対応
 *  2011/12/14    1.11  SCSK K.Nakamura  [E_本稼動_08817]数量の出力判定修正
 *
 *****************************************************************************************/
--
--
 --#######################  固定グローバル定数宣言部 START   ######################
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
--
--################################  固定部 END   ###############################
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
--################################  固定部 END   ################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;  
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** スキップ例外 ***
  global_skip_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--  
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A12C';                               -- パッケージ名
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                                          -- カンマ
  cv_msg_space              CONSTANT VARCHAR2(4)   := '';                                           -- 空白
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                                          -- ダブルクォーテーション
--
  cv_msg_space4             CONSTANT VARCHAR2(20)  := cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble || cv_msg_comma ||
                                                      cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble || cv_msg_comma ||
                                                      cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble || cv_msg_comma ||
                                                      cv_msg_duble || cv_msg_space ||
                                                      cv_msg_duble;                                 -- "ブランク"×4
--
  cv_msg_space16            CONSTANT VARCHAR2(20)  := cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space || cv_msg_comma ||
                                                      cv_msg_space;                                 -- 空行
--
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                                      -- アプリケーション短縮名
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                                      -- アドオン：共通・IF領域
  cv_normal                 CONSTANT VARCHAR2(2)   := '10';                                         -- 原価種別(10 = 標準原価)
--//+DEL START 2009/02/13 CT016 S.Son
--cv_single_item            CONSTANT VARCHAR2(1)   := '1';                                          -- 商品単品
--//+DEL END 2009/02/13 CT016 S.Son
--//+ADD START 2009/02/13 CT016 S.Son
  cv_group_kbn              CONSTANT VARCHAR2(1)   := '0';                                          -- 商品群
--//+ADD END 2009/02/13 CT016 S.Son
  cn_year_total             CONSTANT NUMBER(10)    := 999999;                                       -- 年間計
--//+ADD START 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
  cv_whse_code                  CONSTANT VARCHAR2(3)   := '000';
  cv_sgun_code                  CONSTANT VARCHAR2(15)  := 'XXCMN_SGUN_CODE';          
  cv_item_group                 CONSTANT VARCHAR2(17)  := 'XXCSM1_ITEM_GROUP';
  cv_mcat                       CONSTANT VARCHAR2(4)   := 'MCAT';
  cn_appl_id                    CONSTANT NUMBER        := 401;
  cv_ja                         CONSTANT VARCHAR2(4)   := 'JA';
  cv_item_status_30             CONSTANT VARCHAR2(4)   := '30';
  cv_item_kbn                   CONSTANT VARCHAR2(4)   := '0';
  cv_percent                    CONSTANT VARCHAR2(1)   := '%';
  cv_flg_y                      CONSTANT VARCHAR2(1)   := 'Y';                       --フラグY

--//+ADD END 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--
  -- ===============================
  -- ユーザー定義グローバル変数 
  -- ===============================
--
  gd_process_date           DATE;                                                                   -- 業務日付
  gn_index                  NUMBER := 0;                                                            -- 登録順
  gn_taisyoyear             NUMBER(4,0);                                                            -- 対象年度
  gv_kyotencd               VARCHAR2(32);                                                           -- 拠点コード
  gv_genkacd                VARCHAR2(200);                                                          -- 原価種別
  gv_genkanm                VARCHAR2(200);                                                          -- 原価種別名
  gv_kaisou                 VARCHAR2(2);                                                            -- 階層
--
  -- ===============================
  -- 共用メッセージ番号
  -- ===============================
--
  cv_ccp1_msg_90000         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                           -- 対象件数メッセージ
  cv_ccp1_msg_90001         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                           -- 成功件数メッセージ
  cv_ccp1_msg_90002         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                           -- エラー件数メッセージ
  cv_ccp1_msg_90003         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                           -- スキップ件数メッセージ
  cv_ccp1_msg_90004         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                           -- 正常終了メッセージ
  cv_ccp1_msg_90006         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                           -- エラー終了全ロールバックメッセージ
  cv_ccp1_msg_00111         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- 想定外エラーメッセージ
--//+ADD START 2009/02/10 CT009 T.Shimoji
  cv_ccp1_msg_90005         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                           -- 警告終了メッセージ
--//+ADD END 2009/02/10 CT009 T.Shimoji
--  
  -- ===============================  
  -- メッセージ番号
  -- ===============================
--
  cv_csm1_msg_10003         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';                           -- 入力パラメータ取得メッセージ(対象年度)
  cv_csm1_msg_00048         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';                           -- 入力パラメータ取得メッセージ(拠点コード)
  cv_csm1_msg_10017         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10017';                           -- 入力パラメータ取得メッセージ（原価種別名）
  cv_csm1_msg_10016         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10004';                           -- 入力パラメータ取得メッセージ（階層）
  cv_csm1_msg_00005         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- プロファイル取得エラーメッセージ
  cv_csm1_msg_00087         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';                           -- 商品計画未設定メッセージ
  cv_csm1_msg_00088         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';                           -- 商品計画単品別按分処理未完了メッセージ
  cv_csm1_msg_00090         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00090';                           -- 商品計画リスト(時系列)ヘッダ用メッセージ
  cv_csm1_msg_10001         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';                           -- 対象データ0件メッセージ
--
  -- ===============================
  -- トークン定義
  -- ===============================
--  
  cv_tkn_year               CONSTANT VARCHAR2(100) := 'YYYY';                                       -- 対象年度
  cv_tkn_kyotencd           CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                                  -- 拠点コード
  cv_tkn_genka_nm           CONSTANT VARCHAR2(100) := 'GENKA_NM';                                   -- 原価種別名
  cv_tkn_genka_cd           CONSTANT VARCHAR2(100) := 'GENKA_CD';                                   -- 原価種別
  cv_tkn_kaisou             CONSTANT VARCHAR2(100) := 'HIERARCHY_LEVEL';                            -- 階層
  cv_tkn_prof_name          CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- プロファイル名
  cv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';                                      -- 処理件数
  cv_tkn_sakusei_date       CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';                            -- 作成日時
  cv_tkn_taisyou_ym         CONSTANT VARCHAR2(100) := 'TAISYOU_YM';                                 -- 対象年度
--
  -- ===============================
  -- プロファイル
  -- ===============================
-- プロファイル・名称
  gv_prf_amount             VARCHAR2(100);                                                          -- XXCSM:数量
  gv_prf_sales              VARCHAR2(100);                                                          -- XXCSM:売上
  gv_prf_cost_price         VARCHAR2(100);                                                          -- XXCSM:原価
  gv_prf_gross_margin       VARCHAR2(100);                                                          -- XXCSM:粗利益額
  gv_prf_rough_rate         VARCHAR2(100);                                                          -- XXCSM:粗利益率
  gv_prf_rate               VARCHAR2(100);                                                          -- XXCSM:掛率
  gv_prf_item_sum           VARCHAR2(100);                                                          -- XXCSM:商品合計
  gv_prf_item_discount      VARCHAR2(100);                                                          -- XXCSM:売上値引
  gv_prf_foothold_sum       VARCHAR2(100);                                                          -- XXCSM:拠点計
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
  gv_prf_down_pay           VARCHAR2(100);                                                          -- XXCSM:入金値引
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--
  gv_kyoten_cd              VARCHAR2(10);                                                           -- 拠点コード
  gv_kyoten_nm              VARCHAR2(200);                                                          -- 拠点名称
--
    /****************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理
   ****************************************************************************/
  PROCEDURE init(
              ov_errbuf     OUT NOCOPY VARCHAR2                                                     --共通・エラー・メッセージ
             ,ov_retcode    OUT NOCOPY VARCHAR2                                                     --リターン・コード
             ,ov_errmsg     OUT NOCOPY VARCHAR2                                                     --ユーザー・エラー・メッセージ
             )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';                                     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                                                            -- リターン・コード
    lv_errmsg               VARCHAR2(4000);                                                         -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    --
    cv_kind_of_cost         CONSTANT VARCHAR2(100) := 'XXCSM1_KIND_OF_COST';                        -- 原価種別
    -- プロファイル・コード
    cv_prf_amount           CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';                     -- XXCSM:数量
    cv_prf_sales            CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';                     -- XXCSM:売上
    cv_prf_cost_price       CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_8';                     -- XXCSM:原価
    cv_prf_gross_margin     CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';                    -- XXCSM:粗利益額
    cv_prf_rough_rate       CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7';                    -- XXCSM:粗利益率
    cv_prf_rate             CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';                     -- XXCSM:掛率
    cv_prf_item_sum         CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';                    -- XXCSM:商品合計
    cv_prf_item_discount    CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';                    -- XXCSM:売上値引
    cv_prf_foothold_sum     CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_5';                     -- XXCSM:拠点計
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
    cv_pref_down_pay        CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';                    -- XXCSM:入金値引
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
    -- パラメータメッセージ出力用
    lv_pram_op_1            VARCHAR2(100);
    lv_pram_op_2            VARCHAR2(100);
    lv_pram_op_3            VARCHAR2(100);
    lv_pram_op_4            VARCHAR2(100);
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value            VARCHAR2(100);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- =============================================================================================
    -- (A-1,①) 原価種別名の取得
    -- =============================================================================================
   SELECT  ffvv.description           genka_nm                                                      -- 原価種別名
   INTO    gv_genkanm
   FROM    fnd_flex_value_sets        ffvs                                                          -- 値セットヘッダ
          ,fnd_flex_values            ffv                                                           -- 値セット明細
          ,fnd_flex_values_vl         ffvv                                                          -- 値セット名称
   WHERE   ffvs.flex_value_set_id   = ffv.flex_value_set_id                                         -- バリューセットID
     AND   ffv.flex_value_set_id    = ffvv.flex_value_set_id                                        -- バリューセットID
     AND   ffv.flex_value_id        = ffvv.flex_value_id                                            -- バリューID
     AND   ffvs.flex_value_set_name = cv_kind_of_cost                                               -- 原価種別値セット
     AND   ffv.flex_value           = gv_genkacd;                                                   -- (= IN 原価種別)
    -- =============================================================================================
    -- (A-1,②) 入力パラメータの出力
    -- =============================================================================================
    lv_pram_op_1 := xxccp_common_pkg.get_msg(                                                       -- 拠点コードの出力
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10003                                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year                                                -- トークンコード1（対象年度）
                     ,iv_token_value1 => gn_taisyoyear                                              -- トークン値1
                     );
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                                       -- 対象年度の出力
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_00048                                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kyotencd                                            -- トークンコード1(拠点コード）
                     ,iv_token_value1 => gv_kyotencd                                                -- トークン値1
                     );
    lv_pram_op_3 := xxccp_common_pkg.get_msg(                                                       -- 原価種別の出力
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10017                                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_genka_cd                                            -- トークンコード1（原価種別）
                     ,iv_token_value1 => gv_genkacd                                                 -- トークン値1
                     );
    lv_pram_op_4 := xxccp_common_pkg.get_msg(                                                       -- 階層の出力
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10016                                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kaisou                                              -- トークンコード1（階層）
                     ,iv_token_value1 => gv_kaisou                                                  -- トークン値1
                     );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ログに表示
                     ,buff   => lv_pram_op_1  || CHR(10) ||
                                lv_pram_op_2  || CHR(10) ||
                                lv_pram_op_3  || CHR(10) ||
                                lv_pram_op_4  || CHR(10) ||
                                ''            || CHR(10)                                            -- 空行の挿入
                                );
--
    -- =============================================================================================
    -- (A-1,③) 業務処理日付の取得
    -- =============================================================================================
--
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- 業務日付を変数に格納
--
    -- =============================================================================================
    -- (A-1,④) プロファイル情報の取得
    -- =============================================================================================
    -- 変数初期化処理 
    lv_tkn_value := NULL;
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    gv_prf_amount        := FND_PROFILE.VALUE(cv_prf_amount);                                       -- XXCSM:数量
    gv_prf_sales         := FND_PROFILE.VALUE(cv_prf_sales);                                        -- XXCSM:売上
    gv_prf_cost_price    := FND_PROFILE.VALUE(cv_prf_cost_price);                                   -- XXCSM:原価
    gv_prf_gross_margin  := FND_PROFILE.VALUE(cv_prf_gross_margin);                                 -- XXCSM:粗利益額
    gv_prf_rough_rate    := FND_PROFILE.VALUE(cv_prf_rough_rate);                                   -- XXCSM:粗利益率
    gv_prf_rate          := FND_PROFILE.VALUE(cv_prf_rate);                                         -- XXCSM:掛率
    gv_prf_item_sum      := FND_PROFILE.VALUE(cv_prf_item_sum);                                     -- XXCSM:商品合計
    gv_prf_item_discount := FND_PROFILE.VALUE(cv_prf_item_discount);                                -- XXCSM:売上値引
    gv_prf_foothold_sum  := FND_PROFILE.VALUE(cv_prf_foothold_sum);                                 -- XXCSM:拠点計
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
    gv_prf_down_pay      := FND_PROFILE.VALUE(cv_pref_down_pay);                                    -- XXCSM:入金値引
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
    -- ===================================
    -- プロファイル値取得に失敗した場合
    -- ===================================
    IF (gv_prf_amount IS NULL) THEN                                                                 -- XXCSM:数量
      lv_tkn_value := cv_prf_amount;
    ELSIF (gv_prf_sales IS NULL) THEN                                                               -- XXCSM:売上
      lv_tkn_value := cv_prf_sales;
    ELSIF (gv_prf_cost_price IS NULL) THEN                                                          -- XXCSM:原価
      lv_tkn_value := cv_prf_cost_price;
    ELSIF (gv_prf_gross_margin IS NULL) THEN                                                        -- XXCSM:粗利益額
      lv_tkn_value := cv_prf_gross_margin;
    ELSIF (gv_prf_rough_rate IS NULL) THEN                                                          -- XXCSM:粗利益率
      lv_tkn_value := cv_prf_rough_rate;
    ELSIF (gv_prf_rate IS NULL) THEN                                                                -- XXCSM:掛率
      lv_tkn_value := cv_prf_rate;
    ELSIF (gv_prf_item_sum IS NULL) THEN                                                            -- XXCSM:商品合計
      lv_tkn_value := cv_prf_item_sum;
    ELSIF (gv_prf_item_discount IS NULL) THEN                                                       -- XXCSM:売上値引
      lv_tkn_value := cv_prf_item_discount;
    ELSIF (gv_prf_foothold_sum IS NULL) THEN                                                        -- XXCSM:拠点計
      lv_tkn_value := cv_prf_foothold_sum;
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
    ELSIF (gv_prf_down_pay IS NULL) THEN                                                            -- XXCSM:入金値引
      lv_tkn_value := cv_pref_down_pay;
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm1_msg_00005                                           -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name                                            -- トークンコード1（プロファイル）
                    ,iv_token_value1 => lv_tkn_value                                                -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
   /****************************************************************************
   * Procedure Name   : check_location
   * Description      : チェック処理
   ****************************************************************************/
  PROCEDURE check_location(
        ov_errbuf           OUT NOCOPY   VARCHAR2                                                   -- 共通・エラー・メッセージ
       ,ov_retcode          OUT NOCOPY   VARCHAR2                                                   -- リターン・コード
       ,ov_errmsg           OUT NOCOPY   VARCHAR2                                                   -- ユーザー・エラー・メッセージ
       )
  IS
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                                                            -- リターン・コード
    lv_errmsg               VARCHAR2(4000);                                                         -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- ===============================
-- 固定ローカル定数
-- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'check_location';                           -- プログラム名
-- ===============================
-- 固定ローカル変数
-- ===============================
    -- データ存在チェック用
    ln_counts               NUMBER;
-- ===============================
-- ローカル例外
-- ===============================
    location_check_expt     EXCEPTION;
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
  -- ===============================
  -- 変数の初期化
  -- ===============================
    ov_retcode := cv_status_normal;
    ln_counts  := 0;
--
--###########################  固定部 END   ############################
    -- =============================================================================================
    -- (A-3) 年間商品計画データ存在チェック
    -- =============================================================================================
    SELECT  COUNT(1)
    INTO    ln_counts
    FROM    xxcsm_item_plan_lines     xipl                                                          -- 商品計画ヘッダテーブル
           ,xxcsm_item_plan_headers   xiph                                                          -- 商品計画明細テーブル
    WHERE   xipl.item_plan_header_id  = xiph.item_plan_header_id                                    -- 商品計画ヘッダID
      AND   xiph.plan_year            = gn_taisyoyear                                               -- 対象年度
      AND   xiph.location_cd          = gv_kyoten_cd                                                -- 拠点コード
      AND   ROWNUM                    = 1;                                                          -- 1行目
    -- 件数が0の場合、エラーメッセージを出して、処理がスキップします。
    IF (ln_counts = 0) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm1_msg_00087                                           -- メッセージコード
                    ,iv_token_name1  => cv_tkn_kyotencd                                             -- トークンコード1（拠点コード）
                    ,iv_token_value1 => gv_kyoten_cd                                                -- トークン値1
                    ,iv_token_name2  => cv_tkn_taisyou_ym                                           -- トークンコード2（対象年度）
                    ,iv_token_value2 => gn_taisyoyear                                               -- トークン値2
                    );
      RAISE location_check_expt;
    END IF;
    -- =============================================================================================
    -- (A-4) 按分処理済データ存在チェック
    -- =============================================================================================
    ln_counts := 0;                                                                                 -- 変数の初期化
--
    SELECT  COUNT(1)
    INTO    ln_counts
    FROM    xxcsm_item_plan_lines    xipl                                                           -- 商品計画ヘッダテーブル
           ,xxcsm_item_plan_headers  xiph                                                           -- 商品計画明細テーブル
    WHERE   xipl.item_plan_header_id = xiph.item_plan_header_id                                     -- 商品計画ヘッダID
      AND   xiph.plan_year           = gn_taisyoyear                                                -- 対象年度
      AND   xiph.location_cd         = gv_kyoten_cd                                                 -- 拠点コード
--//+UPD START 2009/02/13 CT016 S.Son
    --AND   xipl.item_kbn            = cv_single_item                                               -- 商品区分(1 = 商品単品)
      AND   xipl.item_kbn            <> cv_group_kbn                                                -- 商品区分(1 = 商品単品、2 = 新商品)
--//+UPD END 2009/02/13 CT016 S.Son
      AND   ROWNUM                   = 1;                                                           -- 1行目
    -- 件数が0の場合、エラーメッセージを出して、処理が中止します。
    IF (ln_counts = 0) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- アプリケーション短縮名
                    ,iv_name         => cv_csm1_msg_00088                                           -- メッセージコード
                    ,iv_token_name1  => cv_tkn_kyotencd                                             -- トークンコード1（拠点コード）
                    ,iv_token_value1 => gv_kyoten_cd                                                -- トークン値1
                    ,iv_token_name2  => cv_tkn_taisyou_ym                                           -- トークンコード2（対象年度）
                    ,iv_token_value2 => gn_taisyoyear                                               -- トークン値2
                    );
      RAISE location_check_expt;
    END IF;
  EXCEPTION
    WHEN location_check_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部  #############################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ###########################
--
  END check_location;
--
   /****************************************************************************
   * Procedure Name   : count_item_kbn
   * Description      : (A-6),(A-7) 商品区分データ処理
   ****************************************************************************/
  PROCEDURE count_item_kbn (
         iv_group1_cd       IN  VARCHAR2                                                            -- 商品群コード1
        ,iv_group1_nm       IN  VARCHAR2                                                            -- 商品群コード1名称
        ,ov_errbuf          OUT NOCOPY    VARCHAR2                                                  -- 共通・エラー・メッセージ
        ,ov_retcode         OUT NOCOPY    VARCHAR2                                                  -- リターン・コード
        ,ov_errmsg          OUT NOCOPY    VARCHAR2                                                  -- ユーザー・エラー・メッセージ
        )
  IS
--
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                                                            -- リターン・コード
    lv_errmsg               VARCHAR2(4000);                                                         -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- ===============================
-- ローカル定数
-- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'count_item_kbn';                             -- プログラム名
    cv_percent              CONSTANT VARCHAR2(10)  := '%';
-- ===============================
-- ローカル変数
-- ===============================
--
    ln_m_amount             NUMBER;                                                                 -- 月別商品区分数量
    ln_m_sales              NUMBER;                                                                 -- 月別商品区分売上
    ln_m_cost               NUMBER;                                                                 -- 月別商品区分原価
    ln_m_margin             NUMBER;                                                                 -- 月別商品区分粗利益額
    ln_m_margin_rate        NUMBER;                                                                 -- 月別商品区分粗利益率
    ln_m_rate               NUMBER;                                                                 -- 月別商品区分掛率
    ln_m_price              NUMBER;                                                                 -- 月別商品区分定価
--
    ln_y_amount             NUMBER;                                                                 -- 年間商品区分数量
    ln_y_sales              NUMBER;                                                                 -- 年間商品区分売上
    ln_y_cost               NUMBER;                                                                 -- 年間商品区分原価
    ln_y_margin             NUMBER;                                                                 -- 年間商品区分粗利益額
    ln_y_margin_rate        NUMBER;                                                                 -- 年間商品区分粗利益率
    ln_y_rate               NUMBER;                                                                 -- 年間商品区分掛率
    ln_y_price              NUMBER;                                                                 -- 年間商品区分定価
--
    lv_group1_cd            VARCHAR2(100);                                                          -- パラメータ格納用
-- ============================================
--  商品区分月別集計・カーソル
-- ============================================
    CURSOR count_item_kbn_cur(iv_group_cd  VARCHAR2)
    IS
--//+UPD START 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
--                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- 商品区分別月別原価
--               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- 商品区分別月別計定価
--               ,SUM(xipl.sales_budget)                      sales_budget                            -- 商品区分別月別計売上金額
--               ,SUM(xipl.amount)                            amount                                  -- 商品区分別月別数量
--               ,xipl.year_month                                                                     -- 年月
--      FROM      xxcsm_item_plan_lines                       xipl                                    -- 商品計画明細テーブル
--               ,xxcsm_item_plan_headers                     xiph                                    -- 商品計画ヘッダテーブル
--               ,xxcsm_commodity_group4_v                    xcg4                                    -- 政策群４ビュー
--      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- ヘッダID
--        AND     xiph.plan_year            = gn_taisyoyear                                           -- 予算年度
--        AND     xiph.location_cd          = gv_kyoten_cd                                            -- 拠点コード
--        AND     xipl.item_group_no        LIKE  iv_group_cd                                         -- 商品群コード
----//+UPD START 2009/02/13 CT016 S.Son
--      --AND   xipl.item_kbn            = cv_single_item                                             -- 商品区分(1 = 商品単品)
--        AND   xipl.item_kbn            <> cv_group_kbn                                              -- 商品区分(1 = 商品単品、2 = 新商品)
----//+UPD END 2009/02/13 CT016 S.Son
--        AND     xipl.item_no              = xcg4.item_cd                                            -- 商品コード
--      GROUP BY  xipl.year_month                                                                     -- 年月
--      ORDER BY  xipl.year_month;                                                                    -- 年月
--
      SELECT
            sub.year_month                                                          year_month    -- 年月
          , DECODE(gv_genkacd, cv_normal, SUM(sub.now_item_cost * sub.amount)       
                                        , SUM(sub.now_business_cost * sub.amount)
                  )                                                                 cost          -- 商品区分別月別原価
          , SUM(sub.now_unit_price * sub.amount)                                    unit_price    -- 商品区分別月別計定価
          , SUM(sub.sales_budget)                                                   sales_budget  -- 商品区分別月別計売上金額
          , SUM(sub.amount)                                                         amount        -- 商品区分別月別数量
      FROM  (
              SELECT
                      xipl.year_month                                           year_month
                    , NVL(  (
                              SELECT SUM(ccmd.cmpnt_cost)  cmpnt_cost
                              FROM   cm_cmpt_dtl     ccmd
                                    ,cm_cldr_dtl     ccld
                              WHERE  ccmd.calendar_code = ccld.calendar_code
                              AND    ccmd.whse_code     = cv_whse_code
                              AND    ccmd.period_code   = ccld.period_code
                              AND    ccld.start_date   <= gd_process_date
                              AND    ccld.end_date     >= gd_process_date
                              AND    ccmd.item_id       = iimb.item_id
                            )
                          , NVL(iimb.attribute8, 0)
                      )                                                         now_item_cost
                    , NVL(iimb.attribute8, 0)                                   now_business_cost
                    , NVL(iimb.attribute5, 0)                                   now_unit_price
                    , xipl.amount                                               amount
                    , xipl.sales_budget                                         sales_budget
              FROM    mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_headers     xiph    -- 商品計画ヘッダテーブル
                    , xxcsm_item_plan_lines       xipl    -- 商品計画明細テーブル
              WHERE   mcsb2.structure_id              =   mcb2.structure_id
              AND     mcb2.enabled_flag               =   cv_flg_y
              AND     NVL(mcb2.disable_date, gd_process_date) <=  gd_process_date
              AND     fifs2.id_flex_structure_code    =   cv_sgun_code
              AND     fifs2.application_id            =   cn_appl_id 
              AND     fifs2.id_flex_code              =   cv_mcat
              AND     fifs2.id_flex_num               =   mcsb2.structure_id
              AND     gic.category_id                 =   mcb2.category_id
              AND     gic.category_set_id             =   mcsb2.category_set_id
              AND     gic.item_id                     =   iimb.item_id
              AND     iimb.item_id                    =   xsib.item_id
              AND     xsib.item_status                =   cv_item_status_30
              AND     xiph.item_plan_header_id        =   xipl.item_plan_header_id
              AND     xiph.plan_year                  =   gn_taisyoyear
              AND     xiph.location_cd                =   gv_kyoten_cd
              AND     xipl.item_kbn                   <>  cv_group_kbn
              AND     xipl.item_no                    =   iimb.item_no
              AND     SUBSTRB(mcb2.segment1, 1, 1)    =   iv_group_cd
              AND     EXISTS(
                            SELECT  /*+ LEADING(fifs mcsb mcb) */
                                    1
                            FROM    mtl_categories_b            mcb
                                  , mtl_category_sets_b         mcsb
                                  , fnd_id_flex_structures      fifs
                            WHERE   mcsb.structure_id             =   mcb.structure_id
                            AND     mcb.enabled_flag              =   cv_flg_y
                            AND     NVL(mcb.disable_date, gd_process_date) <=  gd_process_date
                            AND     fifs.id_flex_structure_code   =   cv_sgun_code
                            AND     fifs.application_id           =   cn_appl_id 
                            AND     fifs.id_flex_code             =   cv_mcat
                            AND     fifs.id_flex_num              =   mcsb.structure_id
                            AND     INSTR(mcb.segment1, '*', 1, 1)  =   2
                            AND SUBSTRB(mcb.segment1, 1, 1) = SUBSTRB(mcb2.segment1, 1, 1)
                          UNION ALL
                            SELECT  1
                            FROM    fnd_lookup_values       flv
                            WHERE   flv.lookup_type         =   cv_item_group
                            AND     flv.language            =   cv_ja
                            AND     flv.enabled_flag        =   cv_flg_y
                            AND     gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date)
                            AND     NVL(flv.end_date_active, gd_process_date)
                            AND     INSTR(flv.lookup_code, '*', 1, 1) = 2
                            AND     SUBSTRB(flv.lookup_code, 1, 1)  = SUBSTRB(mcb2.segment1, 1, 1)
                        )
      ) sub
      GROUP BY  sub.year_month
      ORDER BY  sub.year_month
      ;
--//+UPD END 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--
    count_item_kbn_rec    count_item_kbn_cur%ROWTYPE;
--
  BEGIN
--
--//UPD START 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--    lv_group1_cd     := iv_group1_cd || cv_percent;
      lv_group1_cd     := iv_group1_cd;
--//UPD END 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
      -- ===============================
      -- 変数の初期化
      -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--
    OPEN count_item_kbn_cur(iv_group_cd => lv_group1_cd);
    <<count_item_kbn_loop>>                                                                         -- 商品区分月別データ集計
    LOOP
      FETCH count_item_kbn_cur INTO count_item_kbn_rec;
      EXIT WHEN count_item_kbn_cur%NOTFOUND;                                                        -- 対象データ件数処理を繰り返す
      -- ===============================
      -- 変数の初期化
      -- ===============================
      ln_m_amount      := 0;
      ln_m_sales       := 0;
      ln_m_cost        := 0;
      ln_m_margin      := 0;
      ln_m_margin_rate := 0;
      ln_m_rate        := 0;
      ln_m_price       := 0;
    -- =============================================================================================
    -- (A-6) 商品区分集計
    -- =============================================================================================
      -- ===============================
      -- 月別データの取得
      -- ===============================
      --月別商品区分数量
      ln_m_amount        := count_item_kbn_rec.amount;                                              -- 数量
      --月別商品区分売上
      ln_m_sales         := count_item_kbn_rec.sales_budget;                                        -- 売上金額 
      --月別商品区分原価
      ln_m_cost          := count_item_kbn_rec.cost;                                                -- 原価
      --月別商品区分粗利益額
      ln_m_margin        := (ln_m_sales - ln_m_cost);                                               -- (売上金額 - 原価)
      --月別商品区分粗利益率
      IF (ln_m_sales = 0) THEN
        ln_m_margin_rate := 0;
      ELSE
        ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (粗利益額 / 売上金額 * 100)
      END IF;
      --月別商品区分掛率分母
      ln_m_price         := count_item_kbn_rec.unit_price;                                          -- 定価
      --月別商品区分掛率
      IF (ln_m_price = 0) THEN
        ln_m_rate        := 0;
      ELSE
        ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (売上金額 / 定価 * 100)
      END IF;
      -- ===============================
      -- 年間データの取得
      -- ===============================
      --年間商品区分数量
      ln_y_amount        := (ln_y_amount + ln_m_amount);
      --年間商品区分売上
      ln_y_sales         := (ln_y_sales + ln_m_sales);
      --年間商品区分原価
      ln_y_cost          := (ln_y_cost + ln_m_cost);
      --年間商品区分粗利益額
      ln_y_margin        := (ln_y_margin + ln_m_margin);
      --年間商品区分掛率分母
      ln_y_price         := (ln_y_price + ln_m_price);
    -- =============================================================================================
    -- (A-7) 商品区分データ登録処理(月別)
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
          output_order                                                                              -- 出力順
         ,location_cd                                                                               -- 拠点コード
         ,location_nm                                                                               -- 拠点名
         ,item_cd                                                                                   -- コード
         ,item_nm                                                                                   -- 名称
         ,year_month                                                                                -- 年月
         ,amount                                                                                    -- 数量
         ,sales                                                                                     -- 売上
         ,cost                                                                                      -- 原価
         ,margin                                                                                    -- 粗利益額
         ,margin_rate                                                                               -- 粗利益率
         ,rate                                                                                      -- 掛率
         ,discount                                                                                  -- 値引
         )
      VALUES(
          gn_index                                                                                  -- 出力順
         ,gv_kyoten_cd                                                                              -- 拠点コード
         ,gv_kyoten_nm                                                                              -- 拠点名
         ,iv_group1_cd                                                                              -- コード
         ,iv_group1_nm                                                                              -- 名称
         ,count_item_kbn_rec.year_month                                                             -- 年月
         ,ln_m_amount                                                                               -- 数量
         ,ROUND((ln_m_sales / 1000),0)                                                              -- 売上
         ,ROUND((ln_m_cost / 1000),0)                                                               -- 原価
         ,ROUND((ln_m_margin / 1000),0)                                                             -- 粗利益額
         ,ln_m_margin_rate                                                                          -- 粗利益率
         ,ln_m_rate                                                                                 -- 掛率
         ,NULL                                                                                      -- 値引
         );
--
      gn_index := gn_index + 1;                                                                     -- 登録順をインクリメント
--
    END LOOP count_item_kbn_loop;
    CLOSE count_item_kbn_cur;
    --年間商品区分粗利益率
    IF (ln_y_sales = 0) THEN
      ln_y_margin_rate := 0;
    ELSE
      ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);
    END IF;
    --年間商品区分掛率
    IF (ln_y_price = 0)THEN
      ln_y_rate        := 0;
    ELSE
      ln_y_rate        := ROUND((ln_y_sales / ln_y_price * 100),2);
    END IF;
    -- =============================================================================================
    -- (A-7) 商品区分データ登録処理(年間)
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
          output_order                                                                              -- 出力順
         ,location_cd                                                                               -- 拠点コード
         ,location_nm                                                                               -- 拠点名
         ,item_cd                                                                                   -- コード
         ,item_nm                                                                                   -- 名称
         ,year_month                                                                                -- 年月
         ,amount                                                                                    -- 数量
         ,sales                                                                                     -- 売上
         ,cost                                                                                      -- 原価
         ,margin                                                                                    -- 粗利益額
         ,margin_rate                                                                               -- 粗利益率
         ,rate                                                                                      -- 掛率
         ,discount                                                                                  -- 値引
         )
      VALUES(
          gn_index                                                                                  -- 出力順
         ,gv_kyoten_cd                                                                              -- 拠点コード
         ,gv_kyoten_nm                                                                              -- 拠点名
         ,iv_group1_cd                                                                              -- コード
         ,iv_group1_nm                                                                              -- 名称
         ,cn_year_total                                                                             -- 年月
         ,ln_y_amount                                                                               -- 数量
         ,ROUND((ln_y_sales / 1000),0)                                                              -- 売上
         ,ROUND((ln_y_cost / 1000),0)                                                               -- 原価
         ,ROUND((ln_y_margin / 1000),0)                                                             -- 粗利益額
         ,ln_y_margin_rate                                                                          -- 粗利益率
         ,ln_y_rate                                                                                 -- 掛率
         ,NULL                                                                                      -- 値引
         );
--
      gn_index := gn_index + 1;                                                                     -- 登録順をインクリメント
--
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
  -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ================================================
    -- カーソルのクローズ
    -- ================================================
      IF (count_item_kbn_cur%ISOPEN) THEN
        CLOSE count_item_kbn_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_item_kbn_cur%ISOPEN) THEN
        CLOSE count_item_kbn_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END count_item_kbn;
--
   /****************************************************************************
   * Procedure Name   : count_sum_item
   * Description      : (A-8),(A-9) 合計商品データ処理
   ****************************************************************************/
  PROCEDURE count_sum_item(
         ov_errbuf          OUT NOCOPY   VARCHAR2                                                   -- 共通・エラー・メッセージ
        ,ov_retcode         OUT NOCOPY   VARCHAR2                                                   -- リターン・コード
        ,ov_errmsg          OUT NOCOPY   VARCHAR2                                                   -- ユーザー・エラー・メッセージ
        )
  IS
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf               VARCHAR2(4000);                                                         -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                                                            -- リターン・コード
    lv_errmsg               VARCHAR2(4000);                                                         -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- ===============================
-- ローカル定数
-- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'count_sum_item';                             -- プログラム名
    cv_not_d                CONSTANT VARCHAR2(10)  := 'D%';                                         -- (D = その他)
-- ===============================
-- ローカル変数
-- ===============================
--
    ln_m_amount             NUMBER;                                                                 -- 月別合計商品数量
    ln_m_sales              NUMBER;                                                                 -- 月別合計商品売上
    ln_m_cost               NUMBER;                                                                 -- 月別合計商品原価
    ln_m_margin             NUMBER;                                                                 -- 月別合計商品粗利益額
    ln_m_margin_rate        NUMBER;                                                                 -- 月別合計商品粗利益率
    ln_m_rate               NUMBER;                                                                 -- 月別合計商品掛率
    ln_m_price              NUMBER;                                                                 -- 月別合計商品定価
--
    ln_y_amount             NUMBER;                                                                 -- 年間合計商品数量
    ln_y_sales              NUMBER;                                                                 -- 年間合計商品売上
    ln_y_cost               NUMBER;                                                                 -- 年間合計商品原価
    ln_y_margin             NUMBER;                                                                 -- 年間合計商品粗利益額
    ln_y_margin_rate        NUMBER;                                                                 -- 年間合計商品粗利益率
    ln_y_rate               NUMBER;                                                                 -- 年間合計商品掛率
    ln_y_price              NUMBER;                                                                 -- 年間合計商品定価
--
-- ============================================
--  月別商品合計の取得・カーソル
-- ============================================
    CURSOR count_sum_item_cur
    IS
--//+UPD SATRT 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
--                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- 合計商品月別原価
--               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- 合計商品月別計定価
--               ,SUM(xipl.sales_budget)                      sales_budget                            -- 合計商品月別計売上金額
--               ,SUM(xipl.amount)                            amount                                  -- 合計商品月別数量
--               ,xipl.year_month                                                                     -- 年月
--      FROM      xxcsm_item_plan_lines                       xipl                                    -- 商品計画明細テーブル
--               ,xxcsm_item_plan_headers                     xiph                                    -- 商品計画ヘッダテーブル
--               ,xxcsm_commodity_group4_v                    xcg4                                    -- 政策群４ビュー
--      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- ヘッダID
--        AND     xiph.plan_year            = gn_taisyoyear                                           -- 予算年度
--        AND     xiph.location_cd          = gv_kyoten_cd                                            -- 拠点コード
--        AND     xipl.item_group_no        NOT LIKE  cv_not_d                                        -- 商品群コード
----//+UPD START 2009/02/13 CT016 S.Son
--      --AND   xipl.item_kbn            = cv_single_item                                             -- 商品区分(1 = 商品単品)
--        AND   xipl.item_kbn            <> cv_group_kbn                                              -- 商品区分(1 = 商品単品、2 = 新商品)
----//+UPD END 2009/02/13 CT016 S.Son
--        AND     xipl.item_no              = xcg4.item_cd                                            -- 商品コード
--      GROUP BY  xipl.year_month                                                                     -- 年月
--      ORDER BY  xipl.year_month;                                                                    -- 年月
--
      SELECT  sub.year_month                                                          year_month    -- 年月
            , DECODE(gv_genkacd, cv_normal, SUM(sub.now_item_cost * sub.amount)                     
                                          , SUM(sub.now_business_cost * sub.amount))  cost          -- 合計商品月別原価
            , SUM(sub.now_unit_price * sub.amount)                                    unit_price    -- 合計商品月別計定価
            , SUM(sub.sales_budget)                                                   sales_budget  -- 合計商品月別計売上金額
            , SUM(sub.amount)                                                         amount        -- 合計商品月別数量
      FROM (
              SELECT  /*+ LEADING(fifs mcsb mcb) */
                      xipl.year_month                                           year_month
                    , NVL(  (
                              SELECT SUM(ccmd.cmpnt_cost)  cmpnt_cost
                              FROM   cm_cmpt_dtl     ccmd
                                    ,cm_cldr_dtl     ccld
                              WHERE  ccmd.calendar_code = ccld.calendar_code
                              AND    ccmd.whse_code     = cv_whse_code
                              AND    ccmd.period_code   = ccld.period_code
                              AND    ccld.start_date   <= gd_process_date
                              AND    ccld.end_date     >= gd_process_date
                              AND    ccmd.item_id       = iimb.item_id
                            )
                          , NVL(iimb.attribute8, 0)
                      )                                                         now_item_cost
                    , NVL(iimb.attribute8, 0)                                   now_business_cost
                    , NVL(iimb.attribute5, 0)                                   now_unit_price
                    , xipl.amount                                               amount
                    , xipl.sales_budget                                         sales_budget
                FROM    mtl_categories_b          mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_headers     xiph
                    , xxcsm_item_plan_lines       xipl
              WHERE   mcsb2.structure_id              =   mcb2.structure_id
              AND     mcb2.enabled_flag               =   cv_flg_y
              AND     NVL(mcb2.disable_date,gd_process_date)  <=  gd_process_date
              AND     fifs2.id_flex_structure_code    =   cv_sgun_code
              AND     fifs2.application_id            =   cn_appl_id 
              AND     fifs2.id_flex_code              =   cv_mcat
              AND     fifs2.id_flex_num               =   mcsb2.structure_id
              AND     gic.category_id                 =   mcb2.category_id
              AND     gic.category_set_id             =   mcsb2.category_set_id
              AND     gic.item_id                     =   iimb.item_id
              AND     iimb.item_id                    =   xsib.item_id
              AND     xsib.item_status                =   cv_item_status_30
              AND     xiph.item_plan_header_id        =   xipl.item_plan_header_id  -- ヘッダID
              AND     xiph.plan_year                  =   gn_taisyoyear             -- 予算年度
              AND     xiph.location_cd                =   gv_kyoten_cd              -- 拠点コード
              AND     xipl.item_group_no NOT LIKE cv_not_d                          -- 商品群コード
              AND     xipl.item_kbn                   <>  cv_group_kbn              -- 商品区分(1 = 商品単品、2 = 新商品)
              AND     xipl.item_no                    = iimb.item_no                -- 商品コード
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id             =   mcb.structure_id
                        AND     mcb.enabled_flag              =   cv_flg_y
                        AND     NVL(mcb.disable_date,gd_process_date) <=  gd_process_date
                        AND     fifs.id_flex_structure_code   =   cv_sgun_code
                        AND     fifs.application_id           =   cn_appl_id 
                        AND     fifs.id_flex_code             =   cv_mcat
                        AND     fifs.id_flex_num              =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, '*', 1, 1)  =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)     =   SUBSTRB(mcb2.segment1, 1, 1)
                      UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type         =   cv_item_group
                        AND     flv.language            =   cv_ja
                        AND     flv.enabled_flag        =   cv_flg_y
                        AND     gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date)
                                                 AND     NVL(flv.end_date_active, gd_process_date)
                        AND     INSTR(flv.lookup_code, '*', 1, 1) =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)    =   SUBSTRB(mcb2.segment1, 1, 1)
                    )
          ) sub
      GROUP BY  year_month                                                     -- 年月
      ORDER BY  year_month                                                     -- 年月
      ;
--//+UPD END 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
    count_sum_item_rec   count_sum_item_cur%ROWTYPE;
--
  BEGIN
      -- ===============================
      -- 変数の初期化
      -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--
    OPEN count_sum_item_cur;
    <<count_sum_item_loop>>                                                                         -- 合計商品月別データ集計
    LOOP
      FETCH count_sum_item_cur INTO count_sum_item_rec;
      EXIT WHEN count_sum_item_cur%NOTFOUND;                                                        -- 対象データ件数処理を繰り返す
      -- ===============================
      -- 変数の初期化
      -- ===============================
      ln_m_amount      := 0;
      ln_m_sales       := 0;
      ln_m_cost        := 0;
      ln_m_margin      := 0;
      ln_m_margin_rate := 0;
      ln_m_rate        := 0;
      ln_m_price       := 0;
    -- =============================================================================================
    -- (A-8) 商品合計集計
    -- =============================================================================================
      -- ===============================
      -- 月別データの取得
      -- ===============================
      --月別商品区分数量
      ln_m_amount        := count_sum_item_rec.amount;                                              -- 数量
      --月別商品区分売上
      ln_m_sales         := count_sum_item_rec.sales_budget;                                        -- 売上金額 
      --月別商品区分原価
      ln_m_cost          := count_sum_item_rec.cost;                                                -- 原価
      --月別商品区分粗利益額
      ln_m_margin        := (ln_m_sales - ln_m_cost);                                               -- (売上金額 - 原価)
      --月別商品区分粗利益率
      IF (ln_m_sales = 0) THEN
        ln_m_margin_rate := 0;
      ELSE
        ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (粗利益額 / 売上金額 * 100)
      END IF;
      --月別商品区分掛率分母
      ln_m_price         := count_sum_item_rec.unit_price;                                          -- 定価
      --月別商品区分掛率
      IF (ln_m_price = 0) THEN
        ln_m_rate        := 0;
      ELSE
        ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (売上金額 / 定価 * 100)
      END IF;
      -- ===============================
      -- 年間データの取得
      -- ===============================
      --年間商品区分数量
      ln_y_amount        := (ln_y_amount + ln_m_amount);
      --年間商品区分売上
      ln_y_sales         := (ln_y_sales + ln_m_sales);
      --年間商品区分原価
      ln_y_cost          := (ln_y_cost + ln_m_cost);
      --年間商品区分粗利益額
      ln_y_margin        := (ln_y_margin + ln_m_margin);
      --年間商品区分掛率分母
      ln_y_price         := (ln_y_price + ln_m_price);
    -- =============================================================================================
    -- (A-9) 商品合計データ登録処理
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
          output_order                                                                              -- 出力順
         ,location_cd                                                                               -- 拠点コード
         ,location_nm                                                                               -- 拠点名
         ,item_cd                                                                                   -- コード
         ,item_nm                                                                                   -- 名称
         ,year_month                                                                                -- 年月
         ,amount                                                                                    -- 数量
         ,sales                                                                                     -- 売上
         ,cost                                                                                      -- 原価
         ,margin                                                                                    -- 粗利益額
         ,margin_rate                                                                               -- 粗利益率
         ,rate                                                                                      -- 掛率
         ,discount                                                                                  -- 値引
         )
      VALUES(
          gn_index                                                                                  -- 出力順
         ,gv_kyoten_cd                                                                              -- 拠点コード
         ,gv_kyoten_nm                                                                              -- 拠点名
         ,NULL                                                                                      -- コード
         ,gv_prf_item_sum                                                                           -- 名称
         ,count_sum_item_rec.year_month                                                             -- 年月
         ,ln_m_amount                                                                               -- 数量
         ,ROUND((ln_m_sales / 1000),0)                                                              -- 売上
         ,ROUND((ln_m_cost / 1000),0)                                                               -- 原価
         ,ROUND((ln_m_margin / 1000),0)                                                             -- 粗利益額
         ,ln_m_margin_rate                                                                          -- 粗利益率
         ,ln_m_rate                                                                                 -- 掛率
         ,NULL                                                                                      -- 値引
         );
--
      gn_index := gn_index + 1;                                                                     -- 登録順をインクリメント
--
    END LOOP count_sum_item_loop;
    CLOSE count_sum_item_cur;
    --年間商品区分粗利益率
    IF (ln_y_sales = 0) THEN
      ln_y_margin_rate := 0;
    ELSE
      ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);
    END IF;
    --年間商品区分掛率
    IF (ln_y_price = 0) THEN
      ln_y_rate        := 0;
    ELSE
      ln_y_rate        := ROUND((ln_y_sales / ln_y_price * 100),2);
    END IF;
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
          output_order                                                                              -- 出力順
         ,location_cd                                                                               -- 拠点コード
         ,location_nm                                                                               -- 拠点名
         ,item_cd                                                                                   -- コード
         ,item_nm                                                                                   -- 名称
         ,year_month                                                                                -- 年月
         ,amount                                                                                    -- 数量
         ,sales                                                                                     -- 売上
         ,cost                                                                                      -- 原価
         ,margin                                                                                    -- 粗利益額
         ,margin_rate                                                                               -- 粗利益率
         ,rate                                                                                      -- 掛率
         ,discount                                                                                  -- 値引
         )
      VALUES(
          gn_index                                                                                  -- 出力順
         ,gv_kyoten_cd                                                                              -- 拠点コード
         ,gv_kyoten_nm                                                                              -- 拠点名
         ,NULL                                                                                      -- コード
         ,gv_prf_item_sum                                                                           -- 名称
         ,cn_year_total                                                                             -- 年月
         ,ln_y_amount                                                                               -- 数量
         ,ROUND((ln_y_sales / 1000),0)                                                              -- 売上
         ,ROUND((ln_y_cost / 1000),0)                                                               -- 原価
         ,ROUND((ln_y_margin / 1000),0)                                                             -- 粗利益額
         ,ln_y_margin_rate                                                                          -- 粗利益率
         ,ln_y_rate                                                                                 -- 掛率
         ,NULL                                                                                      -- 値引
         );
--
      gn_index := gn_index + 1;                                                                     -- 登録順をインクリメント
--
  EXCEPTION
--#################################  固定例外処理部  #############################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_sum_item_cur%ISOPEN) THEN
        CLOSE count_sum_item_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_sum_item_cur%ISOPEN) THEN
        CLOSE count_sum_item_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END count_sum_item;
--
   /****************************************************************************
   * Procedure Name   : count_item_group
   * Description      : (A-10),(A-11) 商品群データ処理
   ****************************************************************************/
  PROCEDURE count_item_group(
                     iv_item_cd        IN  VARCHAR2                                                 -- 商品群コード
                    ,iv_item_nm        IN  VARCHAR2                                                 -- 商品群名
                    ,in_cost           IN  NUMBER                                                   -- 商品群別年間計原価
                    ,in_unit_price     IN  NUMBER                                                   -- 商品群別年間計定価
                    ,in_sales_budget   IN  NUMBER                                                   -- 商品群別年間計売上金額
                    ,in_amount         IN  NUMBER                                                   -- 商品群別年間計数量
                    ,ov_retcode        OUT NOCOPY VARCHAR2                                          -- エラー・メッセージ
                    ,ov_errbuf         OUT NOCOPY VARCHAR2                                          -- リターン・コード
                    ,ov_errmsg         OUT NOCOPY VARCHAR2                                          -- ユーザー・エラー・メッセージ
                    )
  IS
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                                                         -- リターン・コード
    lv_errmsg  VARCHAR2(4000);                                                                      -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- ===============================
-- 固定ローカル定数
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'count_item_group';                             -- プログラム名
-- ===============================
-- 固定ローカル変数
-- ===============================
--
    ln_m_amount             NUMBER;                                                                 -- 月別商品群別数量
    ln_m_sales              NUMBER;                                                                 -- 月別商品群別売上
    ln_m_cost               NUMBER;                                                                 -- 月別商品群別原価
    ln_m_margin             NUMBER;                                                                 -- 月別商品群別粗利益額
    ln_m_margin_rate        NUMBER;                                                                 -- 月別商品群別粗利益率
    ln_m_rate               NUMBER;                                                                 -- 月別商品群別掛率
    ln_m_price              NUMBER;                                                                 -- 月別商品群別定価
--
    ln_y_amount             NUMBER;                                                                 -- 年間商品群別数量
    ln_y_sales              NUMBER;                                                                 -- 年間商品群別売上
    ln_y_cost               NUMBER;                                                                 -- 年間商品群別原価
    ln_y_margin             NUMBER;                                                                 -- 年間商品群別粗利益額
    ln_y_margin_rate        NUMBER;                                                                 -- 年間商品群別粗利益率
    ln_y_rate               NUMBER;                                                                 -- 年間商品群別掛率
    ln_y_price              NUMBER;                                                                 -- 年間商品群別定価
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    ln_chk_amount           NUMBER;                                                                 -- 数量(判定用)
    ln_chk_sales            NUMBER;                                                                 -- 売上(判定用)
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--
-- ============================================
--  商品群月別集計・カーソル
-- ============================================
    CURSOR count_item_group_cur
    IS
--//+UPD START 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
--                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- 商品群別月別原価
--               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- 商品群別月別計定価
--               ,SUM(xipl.sales_budget)                      sales_budget                            -- 商品群別月別計売上金額
--               ,SUM(xipl.amount)                            amount                                  -- 商品群別月別数量
--               ,xipl.year_month                                                                     -- 年月
--      FROM      xxcsm_item_plan_lines                       xipl                                    -- 商品計画明細テーブル
--               ,xxcsm_item_plan_headers                     xiph                                    -- 商品計画ヘッダテーブル
--               ,xxcsm_commodity_group4_v                    xcg4                                    -- 政策群４ビュー
--      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- ヘッダID
--        AND     xiph.plan_year            = gn_taisyoyear                                           -- 予算年度
--        AND     xiph.location_cd          = gv_kyoten_cd                                            -- 拠点コード
--        AND     xcg4.group4_cd            = iv_item_cd                                              -- 商品群コード
----//+UPD START 2009/02/13 CT016 S.Son
--      --AND   xipl.item_kbn            = cv_single_item                                             -- 商品区分(1 = 商品単品)
--        AND   xipl.item_kbn            <> cv_group_kbn                                              -- 商品区分(1 = 商品単品、2 = 新商品)
----//+UPD END 2009/02/13 CT016 S.Son
--        AND     xipl.item_no              = xcg4.item_cd                                            -- 商品コード
--      GROUP BY  xipl.year_month                                                                     -- 年月
--      ORDER BY  xipl.year_month;                                                                    -- 年月
--
      SELECT    sub.year_month                                                                    -- 年月
               ,DECODE(gv_genkacd, cv_normal, SUM(sub.now_item_cost * sub.amount)
                      ,SUM(sub.now_business_cost * sub.amount)) cost                              -- 商品群別月別原価
               ,SUM(sub.now_unit_price * sub.amount)        unit_price                            -- 商品群別月別計定価
               ,SUM(sub.sales_budget)                       sales_budget                          -- 商品群別月別計売上金額
               ,SUM(sub.amount)                             amount                                -- 商品群別月別数量
      FROM (
              SELECT  /*+ LEADING(fifs mcsb mcb) */
                      xipl.year_month                                           year_month
                    , NVL(  (
                              SELECT SUM(ccmd.cmpnt_cost)  cmpnt_cost
                              FROM   cm_cmpt_dtl     ccmd
                                    ,cm_cldr_dtl     ccld
                              WHERE  ccmd.calendar_code = ccld.calendar_code
                              AND    ccmd.whse_code     = cv_whse_code
                              AND    ccmd.period_code   = ccld.period_code
                              AND    ccld.start_date   <= gd_process_date
                              AND    ccld.end_date     >= gd_process_date
                              AND    ccmd.item_id       = iimb.item_id
                            )
                          , NVL(iimb.attribute8, 0)
                      )                                                         now_item_cost
                    , NVL(iimb.attribute8, 0)                                   now_business_cost
                    , NVL(iimb.attribute5, 0)                                   now_unit_price
                    , xipl.amount                                               amount
                    , xipl.sales_budget                                         sales_budget
                FROM    mtl_categories_b          mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_headers     xiph
                    , xxcsm_item_plan_lines       xipl
              WHERE   mcsb2.structure_id              =   mcb2.structure_id
              AND     mcb2.enabled_flag               =   cv_flg_y
              AND     NVL(mcb2.disable_date,gd_process_date)  <=  gd_process_date
              AND     fifs2.id_flex_structure_code    =   cv_sgun_code
              AND     fifs2.application_id            =   cn_appl_id 
              AND     fifs2.id_flex_code              =   cv_mcat
              AND     fifs2.id_flex_num               =   mcsb2.structure_id
              AND     gic.category_id                 =   mcb2.category_id
              AND     gic.category_set_id             =   mcsb2.category_set_id
              AND     gic.item_id                     =   iimb.item_id
              AND     iimb.item_id                    =   xsib.item_id
              AND     xsib.item_status                =   cv_item_status_30
              AND     xiph.item_plan_header_id        =   xipl.item_plan_header_id  -- ヘッダID
              AND     xiph.plan_year                  =   gn_taisyoyear             -- 予算年度
              AND     xiph.location_cd                =   gv_kyoten_cd              -- 拠点コード
              AND     mcb2.segment1                   =   iv_item_cd                -- 商品群コード
              AND     xipl.item_kbn                   <>  cv_group_kbn              -- 商品区分(1 = 商品単品、2 = 新商品)
              AND     xipl.item_no                    =   iimb.item_no              -- 商品コード
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id               =   mcb.structure_id
                        AND     mcb.enabled_flag                =   cv_flg_y
                        AND     NVL(mcb.disable_date,gd_process_date) <=  gd_process_date
                        AND     fifs.id_flex_structure_code     =   cv_sgun_code
                        AND     fifs.application_id             =   cn_appl_id 
                        AND     fifs.id_flex_code               =   cv_mcat
                        AND     fifs.id_flex_num                =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, '*', 1, 1)  =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)     =   SUBSTRB(mcb2.segment1, 1, 1)
                      UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type         =   cv_item_group
                        AND     flv.language            =   cv_ja
                        AND     flv.enabled_flag        =   cv_flg_y
                        AND     gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date)
                                                 AND     NVL(flv.end_date_active, gd_process_date)
                        AND     INSTR(flv.lookup_code, '*', 1, 1) =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)    =   SUBSTRB(mcb2.segment1, 1, 1)
                    )
          ) sub
      GROUP BY  year_month                                                     -- 年月
      ORDER BY  year_month                                                     -- 年月
      ;
--//+UPD END 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
    count_item_group_rec   count_item_group_cur%ROWTYPE;
--
  BEGIN
    -- ===============================
    -- 変数の初期化
    -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    ln_chk_amount    := 0;
    ln_chk_sales     := 0;
--
    OPEN count_item_group_cur;
    <<chk_amount_loop>>
    LOOP
      FETCH count_item_group_cur INTO count_item_group_rec;
      EXIT WHEN count_item_group_cur%NOTFOUND;
      ln_chk_amount := ln_chk_amount + ABS(count_item_group_rec.amount);       -- 数量(判定用)
      ln_chk_sales  := ln_chk_sales  + ABS(count_item_group_rec.sales_budget); -- 売上(判定用)
    END LOOP chk_amount_loop;
    CLOSE count_item_group_cur;
    --
    -- 売上(判定用)および数量(判定用)のどちらかが0以外の場合、登録処理
    IF (ln_chk_sales <> 0) OR (ln_chk_amount <> 0) THEN
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--
      OPEN count_item_group_cur;
      <<count_item_group_loop>>                                                                       -- 商品群月別データ集計
      LOOP
        FETCH count_item_group_cur INTO count_item_group_rec;
        EXIT WHEN count_item_group_cur%NOTFOUND;                                                      -- 対象データ件数処理を繰り返す
      -- =============================================================================================
      -- (A-10) 商品群集計
      -- =============================================================================================
        -- ===============================
        -- 変数の初期化
        -- ===============================
        ln_m_amount      := 0;
        ln_m_sales       := 0;
        ln_m_cost        := 0;
        ln_m_margin      := 0;
        ln_m_margin_rate := 0;
        ln_m_rate        := 0;
        ln_m_price       := 0;
        -- ===============================
        -- 月別データの取得
        -- ===============================
        --月別商品群別数量
        ln_m_amount        := count_item_group_rec.amount;                                            -- 数量
        --月別商品群別売上
        ln_m_sales         := count_item_group_rec.sales_budget;                                      -- 売上金額 
        --月別商品群別原価
        ln_m_cost          := count_item_group_rec.cost;                                              -- 原価
        --月別商品群別粗利益額
        ln_m_margin        := (ln_m_sales - ln_m_cost );                                              -- (売上金額 - 原価)
        --月別商品群別粗利益率
        IF (ln_m_sales = 0) THEN
          ln_m_margin_rate := 0;
        ELSE
          ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (粗利益額 / 売上金額 * 100)
        END IF;
        --月別商品群別掛率分母
        ln_m_price         := count_item_group_rec.unit_price;                                        -- 定価
        --月別商品群別掛率
        IF (ln_m_price = 0) THEN
          ln_m_rate        := 0;
        ELSE
          ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (売上金額 / 定価 * 100)
        END IF;
      -- =============================================================================================
      -- (A-11) 商品群データ登録処理(月別) 
      -- =============================================================================================
        INSERT INTO
          xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
            output_order                                                                              -- 出力順
           ,location_cd                                                                               -- 拠点コード
           ,location_nm                                                                               -- 拠点名
           ,item_cd                                                                                   -- コード
           ,item_nm                                                                                   -- 名称
           ,year_month                                                                                -- 年月
           ,amount                                                                                    -- 数量
           ,sales                                                                                     -- 売上
           ,cost                                                                                      -- 原価
           ,margin                                                                                    -- 粗利益額
           ,margin_rate                                                                               -- 粗利益率
           ,rate                                                                                      -- 掛率
           ,discount                                                                                  -- 値引
           )
        VALUES(
            gn_index                                                                                  -- 出力順
           ,gv_kyoten_cd                                                                              -- 拠点コード
           ,gv_kyoten_nm                                                                              -- 拠点名
           ,iv_item_cd                                                                                -- コード
           ,iv_item_nm                                                                                -- 名称
           ,count_item_group_rec.year_month                                                           -- 年月
           ,ln_m_amount                                                                               -- 数量
           ,ROUND((ln_m_sales / 1000),0)                                                              -- 売上
           ,ROUND((ln_m_cost / 1000),0)                                                               -- 原価
           ,ROUND((ln_m_margin / 1000),0)                                                             -- 粗利益額
           ,ln_m_margin_rate                                                                          -- 粗利益率
           ,ln_m_rate                                                                                 -- 掛率
           ,NULL                                                                                      -- 値引
           );
--
        gn_index := gn_index + 1;                                                                     -- 登録順をインクリメント
--
      END LOOP count_item_group_loop;
      CLOSE count_item_group_cur;
      -- ===============================
      -- 年間データの取得
      -- ===============================
      --年間商品群別数量
      ln_y_amount        := in_amount;                                                                -- 数量
      --年間商品群別売上
      ln_y_sales         := in_sales_budget;                                                          -- 売上金額 
      --年間商品群別原価
      ln_y_cost          := in_cost;                                                                  -- 原価
      --年間商品群別粗利益額
      ln_y_margin        := (ln_y_sales - ln_y_cost );                                                -- (売上金額 - 原価)
      --年間商品群別粗利益率
      IF (ln_y_sales = 0) THEN
        ln_y_margin_rate := 0;
      ELSE
        ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);                                -- (粗利益額 / 売上金額 * 100)
      END IF;
      --年間商品群別掛率
      IF (in_unit_price = 0) THEN
        ln_y_rate        := 0;
      ELSE
        ln_y_rate        := ROUND((ln_y_sales / in_unit_price * 100),2);                              -- (売上金額 / 定価 * 100)
      END IF;
      -- =============================================================================================
      -- (A-11) 商品群データ登録処理(年間計)
      -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                    -- 商品計画リスト_時系列ワークテーブル
          output_order                                                                                -- 出力順
         ,location_cd                                                                                 -- 拠点コード
         ,location_nm                                                                                 -- 拠点名
         ,item_cd                                                                                     -- コード
         ,item_nm                                                                                     -- 名称
         ,year_month                                                                                  -- 年月
         ,amount                                                                                      -- 数量
         ,sales                                                                                       -- 売上
         ,cost                                                                                        -- 原価
         ,margin                                                                                      -- 粗利益額
         ,margin_rate                                                                                 -- 粗利益率
         ,rate                                                                                        -- 掛率
         ,discount                                                                                    -- 値引
         )
      VALUES(
          gn_index                                                                                    -- 出力順
         ,gv_kyoten_cd                                                                                -- 拠点コード
         ,gv_kyoten_nm                                                                                -- 拠点名
         ,iv_item_cd                                                                                  -- コード
         ,iv_item_nm                                                                                  -- 名称
         ,cn_year_total                                                                               -- 年月
         ,ln_y_amount                                                                                 -- 数量
         ,ROUND((ln_y_sales / 1000),0)                                                                -- 売上
         ,ROUND((ln_y_cost / 1000),0)                                                                 -- 原価
         ,ROUND((ln_y_margin / 1000),0)                                                               -- 粗利益額
         ,ln_y_margin_rate                                                                            -- 粗利益率
         ,ln_y_rate                                                                                   -- 掛率
         ,NULL                                                                                        -- 値引
         );
--
      gn_index := gn_index + 1;                                                                       -- 登録順をインクリメント
--
--//+ADD START 2011/12/14 E_本稼動_08817 K.Nakamura
    END IF;
--//+ADD END   2011/12/14 E_本稼動_08817 K.Nakamura
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_item_group_cur%ISOPEN) THEN
        CLOSE count_item_group_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_item_group_cur%ISOPEN) THEN
        CLOSE count_item_group_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END count_item_group;
--
   /****************************************************************************
   * Procedure Name   : count_discount
   * Description      : (A-12),(A-13) 値引データ処理
   ****************************************************************************/
  PROCEDURE count_discount(
         ov_errbuf     OUT NOCOPY VARCHAR2                                                          -- 共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2                                                          -- リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                         -- ユーザー・エラー・メッセージ
  IS
--
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                                                         -- リターン・コード
    lv_errmsg  VARCHAR2(4000);                                                                      -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
-- ===============================
-- 固定ローカル定数
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'count_discount_cur';                           -- プログラム名
-- ===============================
-- 固定ローカル変数
-- ===============================
    -- データ存在チェック用
    ln_discount_total         NUMBER;                                                               -- 年間値引額取得用
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
    ln_down_pay_total         NUMBER;                                                               -- 年間入金値引額取得用
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
    ln_cnt                    NUMBER;
    ln_discount_cnt           NUMBER;
-- ============================================
--  値引月別データの取得・カーソル
-- ============================================
    CURSOR count_discount_cur
    IS
      SELECT    xipb.sales_discount                sales_discount                                   -- 売上値引
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
               ,xipb.receipt_discount              receipt_discount                                 -- 入金値引
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
               ,xipb.year_month                    year_month                                       -- 年月
      FROM      xxcsm_item_plan_headers            xiph                                             -- 商品計画ヘッダテーブル
               ,xxcsm_item_plan_loc_bdgt           xipb                                             -- 商品計画拠点別予算テーブル
      WHERE     xiph.item_plan_header_id  = xipb.item_plan_header_id                                -- ヘッダID
        AND     xiph.plan_year            = gn_taisyoyear                                           -- 予算年度
        AND     xiph.location_cd          = gv_kyoten_cd                                            -- 拠点コード
      ORDER BY  xipb.year_month;                                                                     -- 年月
--
    count_discount_rec   count_discount_cur%ROWTYPE;
--
  BEGIN
  -- ===============================
  -- 変数の初期化
  -- ===============================
    ln_discount_total := 0;
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
    ln_down_pay_total := 0;   -- 入金値引
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--
    SELECT    COUNT(1)
    INTO      ln_discount_cnt
    FROM      xxcsm_item_plan_headers            xiph                                               -- 商品計画ヘッダテーブル
             ,xxcsm_item_plan_loc_bdgt           xipb                                               -- 商品計画拠点別予算テーブル
    WHERE     xiph.item_plan_header_id  = xipb.item_plan_header_id                                  -- ヘッダID
      AND     xiph.plan_year            = gn_taisyoyear                                             -- 予算年度
      AND     xiph.location_cd          = gv_kyoten_cd;                                             -- 拠点コード
--
--//+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
    FOR i IN 1..2 LOOP
--//+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
      IF (ln_discount_cnt = 12) THEN                                                                  -- データ件数が正常の場合
        OPEN count_discount_cur;
        <<count_discount_loop>>                                                                       -- 値引月別データ集計
        LOOP
          FETCH count_discount_cur INTO count_discount_rec;
          EXIT WHEN count_discount_cur%NOTFOUND;                                                      -- 対象データ件数処理を繰り返す
      -- =============================================================================================
      -- (A-12) 値引集計
      -- =============================================================================================
--//+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
          IF i = 1 THEN
--//+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
            ln_discount_total := (ln_discount_total + count_discount_rec.sales_discount);               -- 値引額を加算
--//+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
          ELSE
            ln_down_pay_total := (ln_down_pay_total + count_discount_rec.receipt_discount);             -- 入金値引額を加算
          END IF;
--//+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
      -- =============================================================================================
      -- (A-13) 値引データ登録
      -- =============================================================================================
          INSERT INTO
            xxcsm_tmp_sales_plan_time(                                                                -- 商品計画リスト_時系列ワークテーブル
              output_order                                                                            -- 出力順
             ,location_cd                                                                             -- 拠点コード
             ,location_nm                                                                             -- 拠点名
             ,item_cd                                                                                 -- コード
             ,item_nm                                                                                 -- 名称
             ,year_month                                                                              -- 年月
             ,amount                                                                                  -- 数量
             ,sales                                                                                   -- 売上
             ,cost                                                                                    -- 原価
             ,margin                                                                                  -- 粗利益額
             ,margin_rate                                                                             -- 粗利益率
             ,rate                                                                                    -- 掛率
             ,discount                                                                                -- 値引
             )
          VALUES(
              gn_index                                                                                -- 出力順
             ,gv_kyoten_cd                                                                            -- 拠点コード
             ,gv_kyoten_nm                                                                            -- 拠点名
             ,NULL                                                                                    -- コード
-- //+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami
--             ,gv_prf_item_discount                                                                    -- 名称
             ,CASE WHEN i = 1 
                   THEN gv_prf_item_discount
                   ELSE gv_prf_down_pay
              END
-- //+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami
             ,count_discount_rec.year_month                                                           -- 年月
             ,NULL                                                                                    -- 数量
             ,NULL                                                                                    -- 売上
             ,NULL                                                                                    -- 原価
             ,NULL                                                                                    -- 粗利益額
             ,NULL                                                                                    -- 粗利益率
             ,NULL                                                                                    -- 掛率
-- //+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami
--             ,ROUND((count_discount_rec.sales_discount / 1000),0)                                     -- 値引
             ,CASE WHEN i = 1
                   THEN ROUND((count_discount_rec.sales_discount / 1000),0)
                   ELSE ROUND((count_discount_rec.receipt_discount / 1000),0)
              END
-- //+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami
             );
--
          gn_index := gn_index + 1;                                                                   -- 登録順をインクリメント
--
        END LOOP count_discount_loop;
--
-- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
        CLOSE count_discount_cur;
-- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--
        INSERT INTO
          xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
            output_order                                                                              -- 出力順
           ,location_cd                                                                               -- 拠点コード
           ,location_nm                                                                               -- 拠点名
           ,item_cd                                                                                   -- コード
           ,item_nm                                                                                   -- 名称
           ,year_month                                                                                -- 年月
           ,amount                                                                                    -- 数量
           ,sales                                                                                     -- 売上
           ,cost                                                                                      -- 原価
           ,margin                                                                                    -- 粗利益額
           ,margin_rate                                                                               -- 粗利益率
           ,rate                                                                                      -- 掛率
           ,discount                                                                                  -- 値引
           )
        VALUES(
            gn_index                                                                                  -- 出力順
           ,gv_kyoten_cd                                                                              -- 拠点コード
           ,gv_kyoten_nm                                                                              -- 拠点名
           ,NULL                                                                                      -- コード
--//+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami
--           ,gv_prf_item_discount                                                                      -- 名称
           ,CASE WHEN i = 1 
                 THEN gv_prf_item_discount
                 ELSE gv_prf_down_pay
            END
--//+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami
           ,cn_year_total                                                                             -- 年月
           ,NULL                                                                                      -- 数量
           ,NULL                                                                                      -- 売上
           ,NULL                                                                                      -- 原価
           ,NULL                                                                                      -- 粗利益額
           ,NULL                                                                                      -- 粗利益率
           ,NULL                                                                                      -- 掛率
--//+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami
--           ,ROUND((ln_discount_total / 1000),0)                                                       -- 値引
           ,CASE WHEN i = 1 
                 THEN ROUND((ln_discount_total / 1000),0)
                 ELSE ROUND((ln_down_pay_total / 1000),0)
            END
--//+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami
           );
--
          gn_index := gn_index + 1;                                                                   -- 登録順をインクリメント
--
     ELSE                                                                                             -- データ件数が不正な場合
       ln_cnt := 1;
       <<no_data_loop>>                                                                               -- (値引 = 0)のデータを登録
       LOOP
       EXIT WHEN ln_cnt > 13;
         INSERT INTO
           xxcsm_tmp_sales_plan_time(                                                                 -- 商品計画リスト_時系列ワークテーブル
           output_order                                                                               -- 出力順
          ,location_cd                                                                                -- 拠点コード
          ,location_nm                                                                                -- 拠点名
          ,item_cd                                                                                    -- コード
          ,item_nm                                                                                    -- 名称
          ,year_month                                                                                 -- 年月
          ,amount                                                                                     -- 数量
          ,sales                                                                                      -- 売上
          ,cost                                                                                       -- 原価
          ,margin                                                                                     -- 粗利益額
          ,margin_rate                                                                                -- 粗利益率
          ,rate                                                                                       -- 掛率
          ,discount                                                                                   -- 値引
          )
         VALUES(
           gn_index                                                                                   -- 出力順
          ,gv_kyoten_cd                                                                               -- 拠点コード
          ,gv_kyoten_nm                                                                               -- 拠点名
          ,NULL                                                                                       -- コード
--//+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami
--           ,gv_prf_item_discount                                                                      -- 名称
           ,CASE WHEN i = 1 
                 THEN gv_prf_item_discount
                 ELSE gv_prf_down_pay
            END
--//+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami
          ,gn_index                                                                                   -- 年月
          ,NULL                                                                                       -- 数量
          ,NULL                                                                                       -- 売上
          ,NULL                                                                                       -- 原価
          ,NULL                                                                                       -- 粗利益額
          ,NULL                                                                                       -- 粗利益率
          ,NULL                                                                                       -- 掛率
          ,0                                                                                          -- 値引
          );
--
         gn_index := gn_index + 1;                                                                    -- 登録順をインクリメント
         ln_cnt   := ln_cnt   + 1;
        END LOOP no_data_loop;
      END IF;
--//+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
    END LOOP;
--//+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_discount_cur%ISOPEN) THEN
        CLOSE count_discount_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_discount_cur%ISOPEN) THEN
        CLOSE count_discount_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END count_discount;
--
   /****************************************************************************
   * Procedure Name   : count_location
   * Description      : (A-14),(A-15) 拠点別データ処理
   ****************************************************************************/
  PROCEDURE count_location(
         ov_errbuf     OUT NOCOPY VARCHAR2                                                          -- 共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2                                                          -- リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                         -- ユーザー・エラー・メッセージ
  IS
--
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                                                         -- リターン・コード
    lv_errmsg  VARCHAR2(4000);                                                                      -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- ===============================
-- 固定ローカル定数
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'count_location';                               -- プログラム名
-- ===============================
-- 固定ローカル変数
-- ===============================
    ln_m_amount               NUMBER;                                                               -- 月別拠点別数量
    ln_m_sales                NUMBER;                                                               -- 月別拠点別売上
    ln_m_cost                 NUMBER;                                                               -- 月別拠点別原価
    ln_m_margin               NUMBER;                                                               -- 月別拠点別粗利益額
    ln_m_margin_rate          NUMBER;                                                               -- 月別拠点別粗利益率
    ln_m_rate                 NUMBER;                                                               -- 月別拠点別掛率
    ln_m_price                NUMBER;                                                               -- 月別拠点別定価
--
    ln_y_amount               NUMBER;                                                               -- 年間拠点別数量
    ln_y_sales                NUMBER;                                                               -- 年間拠点別売上
    ln_y_cost                 NUMBER;                                                               -- 年間拠点別原価
    ln_y_margin               NUMBER;                                                               -- 年間拠点別粗利益額
    ln_y_margin_rate          NUMBER;                                                               -- 年間拠点別粗利益率
    ln_y_rate                 NUMBER;                                                               -- 年間拠点別掛率
    ln_y_price                NUMBER;                                                               -- 年間拠点別定価
-- ============================================
--  拠点別月別データの取得・カーソル
-- ============================================
    CURSOR count_location_cur
    IS
--//+UPD START 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT    DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
--                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- 拠点別月別原価
--               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- 拠点別月別計定価
--               ,SUM(xipl.sales_budget)                      sales_budget                            -- 拠点別月別計売上金額
--               ,SUM(xipl.amount)                            amount                                  -- 拠点別月別数量
--               ,xipl.year_month                                                                     -- 年月
---- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
--               ,xipb.sales_discount                         sales_discount                          -- 売上値引
--               ,xipb.receipt_discount                       receipt_discount                        -- 入金値引
---- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--      FROM      xxcsm_item_plan_lines                       xipl                                    -- 商品計画明細テーブル
--               ,xxcsm_item_plan_headers                     xiph                                    -- 商品計画ヘッダテーブル
--               ,xxcsm_commodity_group4_v                    xcg4                                    -- 政策群４ビュー
---- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
--               ,xxcsm_item_plan_loc_bdgt                    xipb                                    -- 商品計画拠点別予算
---- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--      WHERE     xiph.item_plan_header_id  = xipl.item_plan_header_id                                -- ヘッダID
--        AND     xiph.plan_year            = gn_taisyoyear                                           -- 予算年度
--        AND     xiph.location_cd          = gv_kyoten_cd                                            -- 拠点コード
----//+UPD START 2009/02/13 CT016 S.Son
--      --AND   xipl.item_kbn            = cv_single_item                                             -- 商品区分(1 = 商品単品)
--        AND   xipl.item_kbn            <> cv_group_kbn                                              -- 商品区分(1 = 商品単品、2 = 新商品)
----//+UPD END 2009/02/13 CT016 S.Son
--        AND     xipl.item_no              = xcg4.item_cd                                            -- 商品コード
---- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
--        AND     xiph.item_plan_header_id = xipb.item_plan_header_id                                 -- ヘッダID
--        AND     xipl.month_no = xipb.month_no                                                       -- 月
---- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--      GROUP BY  xipl.year_month                                                                     -- 年月
---- //+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami
--               ,xipb.sales_discount                                                                 -- 売上値引
--               ,xipb.receipt_discount                                                               -- 入金値引
---- //+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
--      ORDER BY  xipl.year_month;                                                                    -- 年月
--
      SELECT    sub.year_month                                                                    -- 年月
               ,DECODE(gv_genkacd,cv_normal,SUM(sub.now_item_cost * sub.amount)
                      ,SUM(sub.now_business_cost * sub.amount)) cost                              -- 拠点別月別原価
               ,SUM(sub.now_unit_price * sub.amount)            unit_price                        -- 拠点別月別計定価
               ,SUM(sub.sales_budget)                           sales_budget                      -- 拠点別月別計売上金額
               ,SUM(sub.amount)                                 amount                            -- 拠点別月別数量
               ,sub.sales_discount                              sales_discount                    -- 売上値引
               ,sub.receipt_discount                            receipt_discount                  -- 入金値引
      FROM (
              SELECT  /*+ LEADING(fifs mcsb mcb) */
                      xipl.year_month                                           year_month
                    , NVL(  (
                              SELECT SUM(ccmd.cmpnt_cost)  cmpnt_cost
                              FROM   cm_cmpt_dtl     ccmd
                                    ,cm_cldr_dtl     ccld
                              WHERE  ccmd.calendar_code = ccld.calendar_code
                              AND    ccmd.whse_code     = cv_whse_code
                              AND    ccmd.period_code   = ccld.period_code
                              AND    ccld.start_date   <= gd_process_date
                              AND    ccld.end_date     >= gd_process_date
                              AND    ccmd.item_id       = iimb.item_id
                            )
                          , NVL(iimb.attribute8, 0)
                      )                                                         now_item_cost
                    , NVL(iimb.attribute8, 0)                                   now_business_cost
                    , NVL(iimb.attribute5, 0)                                   now_unit_price
                    , xipl.amount                                               amount
                    , xipl.sales_budget                                         sales_budget
                    , xipb.sales_discount                                       sales_discount
                    , xipb.receipt_discount                                     receipt_discount
                FROM  mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , fnd_id_flex_structures      fifs2
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_headers     xiph
                    , xxcsm_item_plan_lines       xipl
                    , xxcsm_item_plan_loc_bdgt    xipb
              WHERE   mcsb2.structure_id              =   mcb2.structure_id
              AND     mcb2.enabled_flag               =   cv_flg_y
              AND     NVL(mcb2.disable_date,gd_process_date)  <=  gd_process_date
              AND     fifs2.id_flex_structure_code    =   cv_sgun_code
              AND     fifs2.application_id            =   cn_appl_id 
              AND     fifs2.id_flex_code              =   cv_mcat
              AND     fifs2.id_flex_num               =   mcsb2.structure_id
              AND     gic.category_id                 =   mcb2.category_id
              AND     gic.category_set_id             =   mcsb2.category_set_id
              AND     gic.item_id                     =   iimb.item_id
              AND     iimb.item_id                    =   xsib.item_id
              AND     xsib.item_status                =   cv_item_status_30
              AND     xiph.item_plan_header_id        =   xipl.item_plan_header_id  -- ヘッダID
              AND     xiph.item_plan_header_id        =   xipb.item_plan_header_id
              AND     xiph.plan_year                  =   gn_taisyoyear             -- 予算年度
              AND     xiph.location_cd                =   gv_kyoten_cd              -- 拠点コード
              AND     xipl.item_kbn                   <>  cv_group_kbn              -- 商品区分(1 = 商品単品、2 = 新商品)
              AND     xipl.item_no                    =   iimb.item_no              -- 商品コード
              AND     xipl.month_no                   =   xipb.month_no
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id               =   mcb.structure_id
                        AND     mcb.enabled_flag                =   cv_flg_y
                        AND     NVL(mcb.disable_date, gd_process_date) <=  gd_process_date
                        AND     fifs.id_flex_structure_code     =   cv_sgun_code
                        AND     fifs.application_id             =   cn_appl_id 
                        AND     fifs.id_flex_code               =   cv_mcat
                        AND     fifs.id_flex_num                =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, '*', 1, 1)  =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)     =   SUBSTRB(mcb2.segment1, 1, 1)
                      UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type         =   cv_item_group
                        AND     flv.language            =   cv_ja
                        AND     flv.enabled_flag        =   cv_flg_y
                        AND     gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date)
                                                 AND     NVL(flv.end_date_active, gd_process_date)
                        AND     INSTR(flv.lookup_code, '*', 1, 1) =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)    =   SUBSTRB(mcb2.segment1, 1, 1)
                    )
          ) sub
      GROUP BY  year_month          -- 年月
              , sales_discount      -- 売上値引
              , receipt_discount    -- 入金値引
      ORDER BY  year_month          -- 年月
      ;

--//+UPD END 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
    count_location_rec   count_location_cur%ROWTYPE;
--
  BEGIN
      -- ===============================
      -- 変数の初期化
      -- ===============================
    ln_y_amount      := 0;
    ln_y_sales       := 0;
    ln_y_cost        := 0;
    ln_y_margin      := 0;
    ln_y_margin_rate := 0;
    ln_y_rate        := 0;
    ln_y_price       := 0;
--
    OPEN count_location_cur;
    <<count_location_loop>>                                                                         -- 拠点別月別データ集計
    LOOP
      FETCH count_location_cur INTO count_location_rec;
      EXIT WHEN count_location_cur%NOTFOUND;                                                        -- 対象データ件数処理を繰り返す
      -- ===============================
      -- 変数の初期化
      -- ===============================
      ln_m_amount      := 0;
      ln_m_sales       := 0;
      ln_m_cost        := 0;
      ln_m_margin      := 0;
      ln_m_margin_rate := 0;
      ln_m_rate        := 0;
      ln_m_price       := 0;
    -- =============================================================================================
    -- (A-14) 拠点別集計
    -- =============================================================================================
      -- ===============================
      -- 月別データの取得
      -- ===============================
      --月別商品区分数量
      ln_m_amount        := count_location_rec.amount;                                              -- 数量
      --月別商品区分売上
-- //+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami
--      ln_m_sales         := count_location_rec.sales_budget;                                        -- 売上金額 
      ln_m_sales         := count_location_rec.sales_budget + count_location_rec.sales_discount + count_location_rec.receipt_discount;
                                                                                                      -- 売上金額+売上値引+入金値引
-- //+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami
      --月別商品区分原価
      ln_m_cost          := count_location_rec.cost;                                                -- 原価
      --月別商品区分粗利益額
      ln_m_margin        := (ln_m_sales - ln_m_cost);                                               -- (売上金額 - 原価)
      --月別商品区分粗利益率
      IF (ln_m_sales = 0) THEN
        ln_m_margin_rate := 0;
      ELSE
        ln_m_margin_rate := ROUND((ln_m_margin / ln_m_sales * 100),2);                              -- (粗利益額 / 売上金額 * 100)
      END IF;
      --月別商品区分掛率分母
      ln_m_price         := count_location_rec.unit_price;                                          -- 定価
      --月別商品区分掛率
      IF (ln_m_price = 0) THEN
        ln_m_rate        := 0;
      ELSE
        ln_m_rate        := ROUND((ln_m_sales / ln_m_price * 100),2);                               -- (売上金額 / 定価 * 100)
      END IF;
      -- ===============================
      -- 年間データの取得
      -- ===============================
      --年間商品区分数量
      ln_y_amount        := (ln_y_amount + ln_m_amount);
      --年間商品区分売上
      ln_y_sales         := (ln_y_sales + ln_m_sales);
      --年間商品区分原価
      ln_y_cost          := (ln_y_cost + ln_m_cost);
      --年間商品区分粗利益額
      ln_y_margin        := (ln_y_margin + ln_m_margin);
      --年間商品区分掛率分母
      ln_y_price         := (ln_y_price + ln_m_price);
    -- =============================================================================================
    -- (A-15) 拠点別データ登録処理
    -- =============================================================================================
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
          output_order                                                                              -- 出力順
         ,location_cd                                                                               -- 拠点コード
         ,location_nm                                                                               -- 拠点名
         ,item_cd                                                                                   -- コード
         ,item_nm                                                                                   -- 名称
         ,year_month                                                                                -- 年月
         ,amount                                                                                    -- 数量
         ,sales                                                                                     -- 売上
         ,cost                                                                                      -- 原価
         ,margin                                                                                    -- 粗利益額
         ,margin_rate                                                                               -- 粗利益率
         ,rate                                                                                      -- 掛率
         ,discount                                                                                  -- 値引
         )
      VALUES(
          gn_index                                                                                  -- 出力順
         ,gv_kyoten_cd                                                                              -- 拠点コード
         ,gv_kyoten_nm                                                                              -- 拠点名
         ,NULL                                                                                      -- コード
         ,gv_prf_foothold_sum                                                                       -- 名称
         ,count_location_rec.year_month                                                             -- 年月
         ,ln_m_amount                                                                               -- 数量
         ,ROUND((ln_m_sales / 1000),0)                                                              -- 売上
         ,ROUND((ln_m_cost / 1000),0)                                                               -- 原価
         ,ROUND((ln_m_margin / 1000),0)                                                             -- 粗利益額
         ,ln_m_margin_rate                                                                          -- 粗利益率
         ,ln_m_rate                                                                                 -- 掛率
         ,NULL                                                                                      -- 値引
         );
--
      gn_index := gn_index + 1;                                                                     -- 登録順をインクリメント
--
    END LOOP count_location_loop;
    CLOSE count_location_cur;
    --年間商品区分粗利益率
    IF (ln_y_sales = 0) THEN
      ln_y_margin_rate := 0;
    ELSE
      ln_y_margin_rate := ROUND((ln_y_margin / ln_y_sales * 100),2);
    END IF;
    --年間商品区分掛率
    IF (ln_y_price = 0) THEN
      ln_y_rate        := 0;
    ELSE
      ln_y_rate        := ROUND((ln_y_sales / ln_y_price * 100),2);
    END IF;
      INSERT INTO
        xxcsm_tmp_sales_plan_time(                                                                  -- 商品計画リスト_時系列ワークテーブル
          output_order                                                                              -- 出力順
         ,location_cd                                                                               -- 拠点コード
         ,location_nm                                                                               -- 拠点名
         ,item_cd                                                                                   -- コード
         ,item_nm                                                                                   -- 名称
         ,year_month                                                                                -- 年月
         ,amount                                                                                    -- 数量
         ,sales                                                                                     -- 売上
         ,cost                                                                                      -- 原価
         ,margin                                                                                    -- 粗利益額
         ,margin_rate                                                                               -- 粗利益率
         ,rate                                                                                      -- 掛率
         ,discount                                                                                  -- 値引
         )
      VALUES(
          gn_index                                                                                  -- 出力順
         ,gv_kyoten_cd                                                                              -- 拠点コード
         ,gv_kyoten_nm                                                                              -- 拠点名
         ,NULL                                                                                      -- コード
         ,gv_prf_foothold_sum                                                                       -- 名称
         ,cn_year_total                                                                             -- 年月
         ,ln_y_amount                                                                               -- 数量
         ,ROUND((ln_y_sales / 1000),0)                                                              -- 売上
         ,ROUND((ln_y_cost / 1000),0)                                                               -- 原価
         ,ROUND((ln_y_margin / 1000),0)                                                             -- 粗利益額
         ,ln_y_margin_rate                                                                          -- 粗利益率
         ,ln_y_rate                                                                                 -- 掛率
         ,NULL                                                                                      -- 値引
         );
--
      gn_index := gn_index + 1;                                                                     -- 登録順をインクリメント
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_location_cur%ISOPEN) THEN
        CLOSE count_location_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (count_location_cur%ISOPEN) THEN
        CLOSE count_location_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END count_location;
--
   /****************************************************************************
   * Procedure Name   : get_item_group
   * Description      : 商品計画データ抽出
   *****************************************************************************/
  PROCEDURE get_item_group(
         ov_errbuf         OUT NOCOPY VARCHAR2                                                      -- 共通・エラー・メッセージ
        ,ov_retcode        OUT NOCOPY VARCHAR2                                                      -- リターン・コード
        ,ov_errmsg         OUT NOCOPY VARCHAR2)                                                     -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_item_group';                             -- プログラム名
    cv_others               CONSTANT VARCHAR2(1)   := 'D';                                          -- その他
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf              VARCHAR2(4000);                                                          -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);                                                             -- リターン・コード
    lv_errmsg              VARCHAR2(4000);                                                          -- ユーザー・エラー・メッセージ
    lv_warnmsg             VARCHAR2(4000);                                                          -- ユーザー・警告・メッセージ
    lv_group1_cd           VARCHAR2(100);                                                           -- 商品群コード1判定用
    lv_group1_nm           VARCHAR2(100);
--
--###########################  固定部 END   ####################################
    -- =============================================================================================
    -- (A-5) 商品計画データ抽出
    -- =============================================================================================
    CURSOR
        get_item_data_cur
    IS
--//+UPD START 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
--      SELECT    xcg4.group1_cd                              group1_cd                               -- 商品群コード1
--               ,xcg4.group1_nm                              group1_nm                               -- 商品群名称1
--               ,xcg4.group4_cd                              item_cd                                 -- 商品群コード
--               ,xcg4.group4_nm                              item_nm                                 -- 商品群名称
--               ,DECODE(gv_genkacd,cv_normal,SUM(xcg4.now_item_cost * xipl.amount)
--                      ,SUM(xcg4.now_business_cost * xipl.amount)) cost                              -- 商品群年間計画原価
--               ,SUM(xcg4.now_unit_price * xipl.amount)      unit_price                              -- 商品群別年間計定価
--               ,SUM(xipl.sales_budget)                      sales_budget                            -- 商品群別年間計売上金額
--               ,SUM(xipl.amount)                            amount                                  -- 商品群別年間計数量
--      FROM      xxcsm_item_plan_lines                       xipl                                    -- 商品計画明細テーブル
--               ,xxcsm_item_plan_headers                     xiph                                    -- 商品計画ヘッダテーブル
--               ,xxcsm_commodity_group4_v                    xcg4                                    -- 政策群４ビュー
--      WHERE     xiph.item_plan_header_id = xipl.item_plan_header_id                                 -- ヘッダID
--        AND     xiph.plan_year           = gn_taisyoyear                                            -- 予算年度
--        AND     xiph.location_cd         = gv_kyoten_cd                                             -- 拠点コード
----//+UPD START 2009/02/13 CT016 S.Son
--      --AND   xipl.item_kbn            = cv_single_item                                             -- 商品区分(1 = 商品単品)
--        AND   xipl.item_kbn            <> cv_group_kbn                                              -- 商品区分(1 = 商品単品、2 = 新商品)
----//+UPD END 2009/02/13 CT016 S.Son
--        AND     xipl.item_no             = xcg4.item_cd                                             -- 商品コード
--      GROUP BY  xcg4.group1_cd                                                                      -- 商品群コード1
--               ,xcg4.group1_nm                                                                      -- 商品群名称1
--               ,xcg4.group4_cd                                                                      -- 商品群コード
--               ,xcg4.group4_nm                                                                      -- 商品群名称
----//+DEL START 2009/02/17 CT025 M.Ohtsuki
----             ,xcg4.now_item_cost                                                                  -- 標準原価(現時点)
----             ,xcg4.now_business_cost                                                              -- 営業原価(現時点)
----             ,xcg4.now_unit_price                                                                 -- 定価(現時点)
----//+DEL END   2009/02/17 CT025 M.Ohtsuki
--      ORDER BY  xcg4.group1_cd                                                                      -- 商品群コード1
--               ,xcg4.group1_nm;                                                                     -- 商品群名称1
--
      SELECT    sub.group1_cd                                   group1_cd                           -- 商品群コード1
               ,sub.group1_nm                                   group1_nm                           -- 商品群名称1
               ,sub.group4_cd                                   item_cd                             -- 商品群コード
               ,sub.group4_nm                                   item_nm                             -- 商品群名称
               ,DECODE(gv_genkacd,cv_normal,SUM(sub.now_item_cost * sub.amount)
                      ,SUM(sub.now_business_cost * sub.amount)) cost                                -- 商品群年間計画原価
               ,SUM(sub.now_unit_price * sub.amount)            unit_price                          -- 商品群別年間計定価
               ,SUM(sub.sales_budget)                           sales_budget                        -- 商品群別年間計売上金額
               ,SUM(sub.amount)                                 amount                              -- 商品群別年間計数量
      FROM (
              SELECT  /*+ LEADING(fifs mcsb mcb) */
                      SUBSTRB(mcb2.segment1, 1, 1)              group1_cd -- "１桁群"
                    , ( SELECT  mct_g1.description    description
                        FROM    mtl_categories_b      mcb_g1
                              , mtl_categories_tl     mct_g1
                        WHERE   mcb_g1.category_id    = mct_g1.category_id
                        AND     mct_g1.language       = cv_ja
                        AND     mcb_g1.segment1       = SUBSTRB(mcb2.segment1, 1, 1)  ||  '***'
                        UNION
                        SELECT  flv.meaning           description
                        FROM    fnd_lookup_values     flv
                        WHERE   flv.lookup_type       =   cv_item_group
                        AND     flv.language          =   cv_ja
                        AND     flv.enabled_flag      =   cv_flg_y
                        AND     flv.lookup_code       =   SUBSTRB(mcb2.segment1, 1, 1)  ||  '***'
                        AND     gd_process_date  BETWEEN NVL(TRUNC(flv.start_date_active), gd_process_date)
                                                 AND     NVL(TRUNC(flv.end_date_active),   gd_process_date)
                      )                                         group1_nm -- １桁群（名称）
                    , mcb2.segment1                             group4_cd
                    , mct.description                           group4_nm
                    , NVL(  (
                              SELECT SUM(ccmd.cmpnt_cost)  cmpnt_cost
                              FROM   cm_cmpt_dtl     ccmd
                                    ,cm_cldr_dtl     ccld
                              WHERE  ccmd.calendar_code = ccld.calendar_code
                              AND    ccmd.whse_code     = cv_whse_code
                              AND    ccmd.period_code   = ccld.period_code
                              AND    ccld.start_date   <= gd_process_date
                              AND    ccld.end_date     >= gd_process_date
                              AND    ccmd.item_id       = iimb.item_id
                            )
                          , NVL(iimb.attribute8, 0)
                      )                                                         now_item_cost
                    , NVL(iimb.attribute8, 0)                                   now_business_cost
                    , NVL(iimb.attribute5, 0)                                   now_unit_price
                    , xipl.amount                                               amount
                    , xipl.sales_budget                                         sales_budget
              FROM    mtl_categories_b            mcb2
                    , mtl_category_sets_b         mcsb2
                    , mtl_categories_tl           mct
                    , fnd_id_flex_structures      fifs2
                    , gmi_item_categories         gic
                    , ic_item_mst_b               iimb
                    , xxcmm_system_items_b        xsib
                    , xxcsm_item_plan_headers     xiph
                    , xxcsm_item_plan_lines       xipl
              WHERE   mcsb2.structure_id              =   mcb2.structure_id
              AND     mcb2.enabled_flag               =   cv_flg_y
              AND     NVL(mcb2.disable_date,gd_process_date)  <=  gd_process_date
              AND     fifs2.id_flex_structure_code    =   cv_sgun_code
              AND     fifs2.application_id            =   cn_appl_id 
              AND     fifs2.id_flex_code              =   cv_mcat
              AND     fifs2.id_flex_num               =   mcsb2.structure_id
              AND     gic.category_id                 =   mcb2.category_id
              AND     gic.category_set_id             =   mcsb2.category_set_id
              AND     gic.item_id                     =   iimb.item_id
              AND     iimb.item_id                    =   xsib.item_id
              AND     xsib.item_status                =   cv_item_status_30
              AND     xiph.item_plan_header_id        =   xipl.item_plan_header_id  -- ヘッダID
              AND     xiph.plan_year                  =   gn_taisyoyear             -- 予算年度
              AND     xiph.location_cd                =   gv_kyoten_cd              -- 拠点コード
              AND     mcb2.category_id                =   mct.category_id
              AND     mct.language                    =   cv_ja
              AND     xipl.item_kbn                   <>  cv_group_kbn              -- 商品区分(1 = 商品単品、2 = 新商品)
              AND     xipl.item_no                    =   iimb.item_no                -- 商品コード
              AND EXISTS(
                        SELECT  /*+ LEADING(fifs mcsb mcb) */
                                1
                        FROM    mtl_categories_b            mcb
                              , mtl_category_sets_b         mcsb
                              , fnd_id_flex_structures      fifs
                        WHERE   mcsb.structure_id               =   mcb.structure_id
                        AND     mcb.enabled_flag                =   cv_flg_y
                        AND     NVL(mcb.disable_date,gd_process_date) <=  gd_process_date
                        AND     fifs.id_flex_structure_code     =   cv_sgun_code
                        AND     fifs.application_id             =   cn_appl_id 
                        AND     fifs.id_flex_code               =   cv_mcat
                        AND     fifs.id_flex_num                =   mcsb.structure_id
                        AND     INSTR(mcb.segment1, '*', 1, 1)  =   2
                        AND     SUBSTRB(mcb.segment1, 1, 1)     =   SUBSTRB(mcb2.segment1, 1, 1)
                      UNION ALL
                        SELECT  1
                        FROM    fnd_lookup_values       flv
                        WHERE   flv.lookup_type         =   cv_item_group
                        AND     flv.language            =   cv_ja
                        AND     flv.enabled_flag        =   cv_flg_y
                        AND     gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date)
                                                 AND     NVL(flv.end_date_active, gd_process_date)
                        AND     INSTR(flv.lookup_code, '*', 1, 1) =   2
                        AND     SUBSTRB(flv.lookup_code, 1, 1)    =   SUBSTRB(mcb2.segment1, 1, 1)
                    )
          ) sub
      GROUP BY  group1_cd                                                                      -- 商品群コード1
               ,group1_nm                                                                      -- 商品群名称1
               ,group4_cd                                                                      -- 商品群コード
               ,group4_nm                                                                      -- 商品群名称
      ORDER BY  group1_cd                                                                      -- 商品群コード1
               ,group1_nm                                                                      -- 商品群名称1
      ;
--//+UPD END 2011/01/17 E_本稼動_05803 PT対応 Y.Kanami
    get_item_data_rec   get_item_data_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- =======================================
    -- データの処理【商品】
    -- =======================================
    OPEN get_item_data_cur;
    <<get_item_data_loop>>                                                                          -- 商品群単位LOOP
    LOOP
      FETCH get_item_data_cur INTO get_item_data_rec;
      EXIT WHEN get_item_data_cur%NOTFOUND;                                                         -- 対象データ件数処理を繰り返す
      --
      IF (lv_group1_cd <> get_item_data_rec.group1_cd) THEN                                         -- 商品群コード1ブレイク時
    -- =============================================================================================
    -- (A-6) 商品区分月別集計 (A-7) 月別商品区分データ登録処理
    -- =============================================================================================
        count_item_kbn(
                       iv_group1_cd => lv_group1_cd                                                 -- 前回処理分の商品群コード1
                      ,iv_group1_nm => lv_group1_nm                                                 -- 前回処理分の商品群コード名称
                      ,ov_errbuf    => lv_errbuf                                                    -- エラー・メッセージ
                      ,ov_retcode   => lv_retcode                                                   -- リターン・コード
                      ,ov_errmsg    => lv_errmsg                                                    -- ユーザー・エラー・メッセージ
                      );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    -- =============================================================================================
    -- (A-10) 商品群月別集計  (A-11) 月別商品群区分データ登録処理
    -- =============================================================================================
-- DEL START 2011/12/14 E_本稼動_08817 K.Nakamura
---- MODIFY  START  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_0580300
----      IF (get_item_data_rec.sales_budget <> 0) THEN                                                 -- (売上金額 = 0)の場合処理はしない
--      IF get_item_data_rec.sales_budget <> 0 OR get_item_data_rec.amount <> 0 THEN                  -- (売上金額 = 0且つ数量 = 0)の場合処理はしない
---- MODIFY  END  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
-- DEL END   2011/12/14 E_本稼動_08817 K.Nakamura
      count_item_group(
                      iv_item_cd       => get_item_data_rec.item_cd                               -- 商品群コード
                     ,iv_item_nm       => get_item_data_rec.item_nm                               -- 商品群名称
                     ,in_cost          => get_item_data_rec.cost                                  -- 商品群別年間計原価
                     ,in_unit_price    => get_item_data_rec.unit_price                            -- 商品群別年間計定価
                     ,in_sales_budget  => get_item_data_rec.sales_budget                          -- 商品群別年間計売上金額
                     ,in_amount        => get_item_data_rec.amount                                -- 商品群別年間計数量
                     ,ov_errbuf        => lv_errbuf                                               -- エラー・メッセージ
                     ,ov_retcode       => lv_retcode                                              -- リターン・コード
                     ,ov_errmsg        => lv_errmsg                                               -- ユーザー・エラー・メッセージ
                     );
-- DEL START 2011/12/14 E_本稼動_08817 K.Nakamura
--      END IF;
-- DEL END   2011/12/14 E_本稼動_08817 K.Nakamura
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      lv_group1_cd := get_item_data_rec.group1_cd;                                                  -- 判断用商品群コード1を上書き
      lv_group1_nm := get_item_data_rec.group1_nm;
    END LOOP get_item_data_loop;
    CLOSE get_item_data_cur;
    -- =============================================================================================
    -- (A-6) 商品区分月別集計 (A-7) 月別商品区分データ登録処理
    -- =============================================================================================
    count_item_kbn(
                    iv_group1_cd => lv_group1_cd                                                    -- 前回処理分の商品群コード1
                   ,iv_group1_nm => lv_group1_nm                                                    -- 前回処理分の商品群コード名称
                   ,ov_errbuf    => lv_errbuf                                                       -- エラー・メッセージ
                   ,ov_retcode   => lv_retcode                                                      -- リターン・コード
                   ,ov_errmsg    => lv_errmsg                                                       -- ユーザー・エラー・メッセージ
                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================================
    -- (A-8) 商品合計月別集計 (A-9) 月別商品合計データ登録処理
    -- =============================================================================================
    count_sum_item(
                    ov_errbuf    => lv_errbuf                                                       -- エラー・メッセージ
                   ,ov_retcode   => lv_retcode                                                      -- リターン・コード
                   ,ov_errmsg    => lv_errmsg                                                       -- ユーザー・エラー・メッセージ
                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================================
    -- (A-12) 値引月別集計    (A-13) 月別値引データ登録処理
    -- =============================================================================================
    count_discount(
                   ov_errbuf    => lv_errbuf                                                        -- エラー・メッセージ
                  ,ov_retcode   => lv_retcode                                                       -- リターン・コード
                  ,ov_errmsg    => lv_errmsg                                                        -- ユーザー・エラー・メッセージ
                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================================
    -- (A-14) 拠点別月別集計  (A-15) 月別拠点別データ登録処理
    -- =============================================================================================
    count_location(
                   ov_errbuf    => lv_errbuf                                                        -- エラー・メッセージ
                  ,ov_retcode   => lv_retcode                                                       -- リターン・コード
                  ,ov_errmsg    => lv_errmsg                                                        -- ユーザー・エラー・メッセージ
                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;            
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;            
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END get_item_group;
--
   /*****************************************************************************
   * Procedure Name   : get_all_location
   * Description      : 拠点毎に処理を繰り返す
   ****************************************************************************/
  PROCEDURE get_all_location(
        ov_errbuf      OUT NOCOPY VARCHAR2                                                          -- エラー・メッセージ
       ,ov_retcode     OUT NOCOPY VARCHAR2                                                          -- リターン・コード
       ,ov_errmsg      OUT NOCOPY VARCHAR2)                                                         -- ユーザー・エラー・メッセージ
  IS
      -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)  := 'get_all_location';                         -- プログラム名

    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    ln_count                  NUMBER;                                                               -- 計数用
--
    lv_get_loc_tab            xxcsm_common_pkg.g_kyoten_ttype;                                      -- 拠点コードリスト格納用
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- =============================================================================================
    -- (A-2) 全拠点取得
    -- =============================================================================================
    xxcsm_common_pkg.get_kyoten_cd_lv6(                                                             -- 営業部門配下の拠点リスト取得
                                     iv_kyoten_cd      => gv_kyotencd                               -- 拠点(部門)コード
                                    ,iv_kaisou         => gv_kaisou                                 -- 階層
--//ADD START 2009/05/07 T1_0858 M.Ohtsuki
                                    ,iv_subject_year   => gn_taisyoyear                             -- 対象年度
--//ADD END   2009/05/07 T1_0858 M.Ohtsuki
                                    ,o_kyoten_list_tab => lv_get_loc_tab                            -- 拠点コードリスト
                                    ,ov_retcode        => lv_retcode                                -- エラー・メッセージ
                                    ,ov_errbuf         => lv_errbuf                                 -- リターン・コード
                                    ,ov_errmsg         => lv_errmsg                                 -- ユーザー・エラー・メッセージ
                                    );
--
    IF (lv_retcode <> cv_status_normal) THEN                                                        -- 戻り値が異常の場合
        RAISE global_api_others_expt;
    END IF;
  -- ================================================
  -- 【拠点コードリスト】拠点毎に下記処理を繰り返す
  -- ================================================
    <<kyoten_list_loop>>
    FOR ln_count IN 1..lv_get_loc_tab.COUNT LOOP                                                    -- 拠点単位LOOP
      BEGIN
        gv_kyoten_cd := lv_get_loc_tab(ln_count).kyoten_cd;                                         -- 拠点コード
        gv_kyoten_nm := lv_get_loc_tab(ln_count).kyoten_nm;                                         -- 拠点名称
        --
        -- ================================================
        -- 【チェック処理】
        -- ================================================
        check_location(
                       ov_errbuf    => lv_errbuf                                                    -- エラー・メッセージ
                      ,ov_retcode   => lv_retcode                                                   -- リターン・コード
                      ,ov_errmsg    => lv_errmsg                                                    -- ユーザー・エラー・メッセージ
                      );
        IF (lv_retcode = cv_status_warn) THEN                                                       -- 戻り値が警告の場合
            -- 次のデータに移動します
          RAISE global_skip_expt;
        ELSIF (lv_retcode = cv_status_error) THEN                                                   -- 戻り値が異常の場合
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- 【商品計画データ抽出処理】
        -- ================================================
        get_item_group(
                       ov_errbuf    => lv_errbuf                                                    -- エラー・メッセージ
                      ,ov_retcode   => lv_retcode                                                   -- リターン・コード
                      ,ov_errmsg    => lv_errmsg                                                    -- ユーザー・エラー・メッセージ
                      );
        IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
          RAISE global_process_expt;
        END IF;
    --  
    --#################################  スキップ例外処理部  START#############################
    --
      EXCEPTION
        WHEN global_skip_expt THEN
          gn_target_cnt := gn_target_cnt + 1 ;                                                      -- 対象件数を加算します
          gn_error_cnt := gn_error_cnt + 1 ;                                                        -- スキップ件数を加算します
--
          fnd_file.put_line(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errmsg
                           );
         --//+ADD START 2009/02/10 CT009 T.Shimoji
         -- 戻りステータス警告設定
         ov_retcode := cv_status_warn;
         --//+ADD END 2009/02/10 CT009 T.Shimoji
    --
    --#################################  スキップ例外処理部  END#############################
    --
      END;
      IF (lv_retcode = cv_status_normal) THEN
        gn_target_cnt := gn_target_cnt + 1;                                                         -- 対象件数を加算します
        gn_normal_cnt := gn_normal_cnt + 1;                                                         -- 正常処理件数を加算します
      ELSE
        lv_retcode := cv_status_normal;
      END IF;
--
    END LOOP kyoten_list_loop;
--  
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;      
--
--#####################################  固定部 END   ###########################
--
  END get_all_location;
--
   /****************************************************************************
   * Procedure Name   : get_output_data
   * Description      : 商品計画リストデータ出力
   *****************************************************************************/
  PROCEDURE get_output_data(
              ov_errbuf   OUT NOCOPY   VARCHAR2                                                     -- エラー・メッセージ
             ,ov_retcode  OUT NOCOPY   VARCHAR2                                                     -- リターン・コード
             ,ov_errmsg   OUT NOCOPY   VARCHAR2                                                     -- ユーザー・エラー・メッセージ
            )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_output_data';                            -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf              VARCHAR2(4000);                                                          -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);                                                             -- リターン・コード
    lv_errmsg              VARCHAR2(4000);                                                          -- ユーザー・エラー・メッセージ
    lv_warnmsg             VARCHAR2(4000);                                                          -- ユーザー・警告・メッセージ
    lv_location_cd         VARCHAR2(100);                                                           -- 判断用拠点コード
    lv_item_nm             VARCHAR2(100);                                                           -- 判断用名称
    --//+ADD START 2009/05/25 T1_1169 A.Sakawa
    lv_item_cd             VARCHAR2(100);                                                           -- 判断用商品群コード
    --//+ADD END 2009/05/25 T1_1169 A.Sakawa
    lv_data_head           VARCHAR2(4000);                                                          -- ヘッダーデータ格納用
--
    lv_out_amount          VARCHAR2(4000);                                                          -- 数量出力用
    lv_out_sales           VARCHAR2(4000);                                                          -- 売上金額出力用
    lv_out_cost            VARCHAR2(4000);                                                          -- 原価出力用
    lv_out_margin          VARCHAR2(4000);                                                          -- 粗利益額出力用
    lv_out_margin_rate     VARCHAR2(4000);                                                          -- 粗利益率出力用
    lv_out_rate            VARCHAR2(4000);                                                          -- 掛率出力用
    lv_out_discount        VARCHAR2(4000);                                                          -- 値引出力用
    lv_msg_no_data         VARCHAR2(100);                                                           -- 対象データ無しメッセージ
--###########################  固定部 END   ####################################
    CURSOR 
      get_output_data_cur
    IS
      SELECT    xwip.location_cd           location_cd                                              -- 拠点コード
               ,xwip.location_nm           location_nm                                              -- 拠点名
               ,xwip.item_cd               item_cd                                                  -- コード
               ,xwip.item_nm               item_nm                                                  -- 名称
               ,xwip.amount                amount                                                   -- 数量
               ,xwip.sales                 sales                                                    -- 売上金額
               ,xwip.cost                  cost                                                     -- 原価
               ,xwip.margin                margin                                                   -- 粗利益額
               ,xwip.margin_rate           margin_rate                                              -- 粗利益率
               ,xwip.rate                  rate                                                     -- 掛率
               ,xwip.discount              discount                                                 -- 値引
      FROM      xxcsm_tmp_sales_plan_time   xwip                                                    -- 商品計画リスト_時系列ワークテーブル
      ORDER BY  xwip.output_order;                                                                  -- 出力順
--
    get_output_data_rec  get_output_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =============================================================================================
    -- (A-16) チェックリストデータ出力
    -- =============================================================================================
    -- ヘッダ情報の抽出
    lv_data_head := xxccp_common_pkg.get_msg(                                                       -- 拠点コードの出力
             iv_application  => cv_xxcsm                                                            -- アプリケーション短縮名
            ,iv_name         => cv_csm1_msg_00090                                                   -- メッセージコード
            ,iv_token_name1  => cv_tkn_year                                                         -- トークンコード1（対象年度）
            ,iv_token_value1 => gn_taisyoyear                                                       -- トークン値1
            ,iv_token_name2  => cv_tkn_genka_nm                                                     -- トークンコード2（原価）
            ,iv_token_value2 => gv_genkanm                                                          -- トークン値2
            ,iv_token_name3  => cv_tkn_sakusei_date                                                 -- トークンコード3（業務日付）
 --//+UPD START 2009/02/20 CT052 T.Tsukino
--            ,iv_token_value3 => gd_process_date                                                     -- トークン値3
            ,iv_token_value3 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')                                  -- トークン値3
 --//+UPD END 2009/02/20 CT052 T.Tsukino
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
--
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT
                     ,buff   => lv_data_head
                     );
--変数を初期化
    lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                        || cv_msg_duble
                                        || gv_prf_sales
                                        || cv_msg_duble;                                            -- 出力区分(売上)を格納
    lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_cost_price
                                        || cv_msg_duble;                                            -- 出力区分(原価)を格納
    lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_gross_margin
                                        || cv_msg_duble;                                            -- 出力区分(粗利益額)を格納
    lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_rough_rate
                                        || cv_msg_duble;                                            -- 出力区分(粗利益率)を格納
    lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                        || cv_msg_duble
                                        || gv_prf_rate
                                        || cv_msg_duble;                                            -- 出力区分(掛率)を格納
--
    OPEN get_output_data_cur;
    <<get_output_data_loop>>                                                                        -- データ件数
    LOOP
      FETCH get_output_data_cur INTO get_output_data_rec;
      EXIT WHEN get_output_data_cur%NOTFOUND;                                                       -- 対象データ件数処理を繰り返す
--
      IF ((get_output_data_cur%ROWCOUNT = 1)                                                        -- 1件目 OR 拠点コードブレイク時
        OR (lv_location_cd <> get_output_data_rec.location_cd)) THEN
        IF (lv_location_cd <> get_output_data_rec.location_cd) THEN                                 -- 拠点コードブレイク時
          fnd_file.put_line(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_out_amount      || CHR(10) ||
                                      lv_out_sales       || CHR(10) ||
                                      lv_out_cost        || CHR(10) ||
                                      lv_out_margin      || CHR(10) ||
                                      lv_out_margin_rate || CHR(10) ||
                                      lv_out_rate        || CHR(10) ||
                                      cv_msg_space16
                           );
          --変数を初期化
          lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                              || cv_msg_duble
                                              || gv_prf_sales
                                              || cv_msg_duble;                                      -- 出力区分(売上)を格納
          lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_cost_price
                                              || cv_msg_duble;                                      -- 出力区分(原価)を格納
          lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_gross_margin
                                              || cv_msg_duble;                                      -- 出力区分(粗利益額)を格納
          lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_rough_rate
                                              || cv_msg_duble;                                      -- 出力区分(粗利益率)を格納
          lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                              || cv_msg_duble
                                              || gv_prf_rate
                                              || cv_msg_duble;                                      -- 出力区分(掛率)を格納
        END IF;
        --ヘッダーデータ作成(拠点コード，拠点名，コード，名称，数量)
        lv_out_amount := cv_msg_duble || get_output_data_rec.location_cd || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || get_output_data_rec.location_nm || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || get_output_data_rec.item_cd     || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || get_output_data_rec.item_nm     || cv_msg_duble
                      || cv_msg_comma
                      || cv_msg_duble || gv_prf_amount                   || cv_msg_duble;
--
      ELSE
        --//+UPD START 2009/05/25 T1_1169 A.Sakawa
        --IF (lv_item_nm <> get_output_data_rec.item_nm) THEN                                         -- 名称ブレイク時
        IF (lv_item_cd <> get_output_data_rec.item_cd)
          OR (get_output_data_rec.item_cd IS NULL AND get_output_data_rec.item_nm = gv_prf_item_discount AND lv_item_nm <> get_output_data_rec.item_nm )
--//+ADD START 2010/12/14 E_本稼動_05803 Y.Kanami 
          OR (get_output_data_rec.item_cd IS NULL AND get_output_data_rec.item_nm = gv_prf_down_pay AND lv_item_nm <> get_output_data_rec.item_nm )
--//+ADD END 2010/12/14 E_本稼動_05803 Y.Kanami
          OR (get_output_data_rec.item_cd IS NULL AND get_output_data_rec.item_nm = gv_prf_item_sum AND lv_item_nm <> get_output_data_rec.item_nm ) 
          OR (get_output_data_rec.item_cd IS NULL AND get_output_data_rec.item_nm = gv_prf_foothold_sum AND lv_item_nm <> get_output_data_rec.item_nm) THEN                                         -- 商品群コードブレイク時
        --//+UPD END 2009/05/25 T1_1169 A.Sakawa
--//+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami 
--          IF (lv_item_nm = gv_prf_item_discount) THEN  
          IF (lv_item_nm IN (gv_prf_item_discount, gv_prf_down_pay)) THEN  
--//+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => lv_out_discount
                             );
            --変数を初期化
            lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                                || cv_msg_duble
                                                || gv_prf_sales
                                                || cv_msg_duble;                                    -- 出力区分(売上)を格納
            lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_cost_price
                                                || cv_msg_duble;                                    -- 出力区分(原価)を格納
            lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_gross_margin
                                                || cv_msg_duble;                                    -- 出力区分(粗利益額)を格納
            lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rough_rate
                                                || cv_msg_duble;                                    -- 出力区分(粗利益率)を格納
            lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rate
                                                || cv_msg_duble;                                    -- 出力区分(掛率)を格納
          ELSE
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => lv_out_amount      || CHR(10) ||
                                        lv_out_sales       || CHR(10) ||
                                        lv_out_cost        || CHR(10) ||
                                        lv_out_margin      || CHR(10) ||
                                        lv_out_margin_rate || CHR(10) ||
                                        lv_out_rate        || CHR(10) ||
                                        cv_msg_space16
                             );
            --変数を初期化
            lv_out_sales       := cv_msg_space4 || cv_msg_comma 
                                                || cv_msg_duble
                                                || gv_prf_sales
                                                || cv_msg_duble;                                    -- 出力区分(売上)を格納
            lv_out_cost        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_cost_price
                                                || cv_msg_duble;                                    -- 出力区分(原価)を格納
            lv_out_margin      := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_gross_margin
                                                || cv_msg_duble;                                    -- 出力区分(粗利益額)を格納
            lv_out_margin_rate := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rough_rate
                                                || cv_msg_duble;                                    -- 出力区分(粗利益率)を格納
            lv_out_rate        := cv_msg_space4 || cv_msg_comma
                                                || cv_msg_duble
                                                || gv_prf_rate
                                                || cv_msg_duble;                                    -- 出力区分(掛率)を格納
          END IF;
          IF (get_output_data_rec.item_cd IS NOT NULL ) THEN                                        -- コードがNULL以外
             --ヘッダーデータ作成(ブランク，ブランク，コード，名称，数量)
             lv_out_amount := cv_msg_duble || cv_msg_space                || cv_msg_duble
                           || cv_msg_comma                     
                           || cv_msg_duble || cv_msg_space                || cv_msg_duble
                           || cv_msg_comma
                           || cv_msg_duble || get_output_data_rec.item_cd || cv_msg_duble
                           || cv_msg_comma
                           || cv_msg_duble || get_output_data_rec.item_nm || cv_msg_duble
                           || cv_msg_comma
                           || cv_msg_duble || gv_prf_amount               || cv_msg_duble;
--
          ELSE                                                                                      -- コードがNULL
--//+UPD START 2010/12/14 E_本稼動_05803 Y.Kanami 
--            IF (get_output_data_rec.item_nm = gv_prf_item_discount) THEN
            IF (get_output_data_rec.item_nm IN (gv_prf_item_discount, gv_prf_down_pay)) THEN
--//+UPD END 2010/12/14 E_本稼動_05803 Y.Kanami 
             --ヘッダーデータ作成(ブランク，ブランク，ブランク，売上値引，ブランク)
            lv_out_discount := cv_msg_duble || cv_msg_space                || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || cv_msg_space                || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || cv_msg_space                || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || get_output_data_rec.item_nm || cv_msg_duble
                            || cv_msg_comma
                            || cv_msg_duble || cv_msg_space                || cv_msg_duble;
            ELSE
             --ヘッダーデータ作成(ブランク，ブランク，コード，名称，数量)
            lv_out_amount := cv_msg_duble || cv_msg_space                || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || cv_msg_space                || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || cv_msg_space                || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || get_output_data_rec.item_nm || cv_msg_duble
                          || cv_msg_comma
                          || cv_msg_duble || gv_prf_amount               || cv_msg_duble;

            END IF;
          END IF;
        END IF;
      END IF;
      --出力用メッセージの作成
      lv_out_amount      := lv_out_amount      || cv_msg_comma || get_output_data_rec.amount;       -- 数量
      lv_out_sales       := lv_out_sales       || cv_msg_comma || get_output_data_rec.sales;        -- 売上金額
      lv_out_cost        := lv_out_cost        || cv_msg_comma || get_output_data_rec.cost;         -- 原価
      lv_out_margin      := lv_out_margin      || cv_msg_comma || get_output_data_rec.margin;       -- 粗利益額
      lv_out_margin_rate := lv_out_margin_rate || cv_msg_comma || get_output_data_rec.margin_rate;  -- 粗利益額
      lv_out_rate        := lv_out_rate        || cv_msg_comma || get_output_data_rec.rate;         -- 粗利益率
      lv_out_discount    := lv_out_discount    || cv_msg_comma || get_output_data_rec.discount;     -- 売上値引
--
      lv_location_cd  := get_output_data_rec.location_cd;                                           -- 判断用拠点コードを格納
      lv_item_nm      := get_output_data_rec.item_nm;                                               -- 判断用名称を格納
      --//+ADD START 2009/05/25 T1_1169 A.Sakawa
      lv_item_cd      := get_output_data_rec.item_cd;                                               -- 判断用商品群コードを格納
      --//+ADD END 2009/05/25 T1_1169 A.Sakawa
--
    END LOOP get_output_data_loop;
--
    IF (get_output_data_cur%ROWCOUNT = 0) THEN                                                      -- データ処理件数が0件の場合
      lv_msg_no_data := xxccp_common_pkg.get_msg(                                                   -- メッセージの取得
                        iv_application  => cv_xxcsm                                                 -- アプリケーション短縮名
                       ,iv_name         => cv_csm1_msg_10001                                        -- メッセージコード
                       );
      fnd_file.put_line(                                                                            -- 対象データ0件を出力
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_msg_no_data || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                                                 || cv_msg_comma
                       );
      --//+ADD START 2009/02/10 CT009 T.Shimoji
      -- 戻りステータス警告設定
      ov_retcode := cv_status_warn;
      --//+ADD END 2009/02/10 CT009 T.Shimoji
    ELSE
      fnd_file.put_line(                                                                            -- 最終データを出力
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_out_amount      || CHR(10) ||
                                  lv_out_sales       || CHR(10) ||
                                  lv_out_cost        || CHR(10) ||
                                  lv_out_margin      || CHR(10) ||
                                  lv_out_margin_rate || CHR(10) ||
                                  lv_out_rate
                       );
    END IF;
    CLOSE get_output_data_cur;
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_output_data_cur%ISOPEN) THEN
        CLOSE get_output_data_cur;
      END IF;            
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_output_data_cur%ISOPEN) THEN
        CLOSE get_output_data_cur;
      END IF;            
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_output_data_cur%ISOPEN) THEN
        CLOSE get_output_data_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END get_output_data;
--
  /*****************************************************************************
   * Procedure Name   : submain
   * Description      : 実装処理
   ****************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ユーザー・エラー・メッセージ
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                              -- プログラム名
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                                                         -- リターン・コード
    lv_errmsg  VARCHAR2(4000);                                                                      -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--##################  固定部 END   #####################################
-- 件数カウンタの初期化
    gn_target_cnt := 0;                                                                             -- 対象件数カウンタの初期化
    gn_normal_cnt := 0;                                                                             -- 正常件数カウンタの初期化
    gn_error_cnt  := 0;                                                                             -- エラー件数カウンタの初期化
    gn_warn_cnt   := 0;                                                                             -- スキップ件数カウンタの初期化
-- 初期処理
    init(                                                                                           -- initをコール
       ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode <> cv_status_normal) THEN                                                        -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
-- 全拠点取得処理
    get_all_location(
       ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ
      );
    --//+UPD START 2009/02/10 CT009 T.Shimoji
    --IF (lv_retcode <> cv_status_normal) THEN                                                        -- 戻り値が異常の場合
    --  RAISE global_process_expt;
    --END IF;
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が異常の場合
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
    --//+UPD END 2009/02/10 CT009 T.Shimoji
-- 商品計画リストデータ出力
    get_output_data(
       ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ
      );
    --//+UPD START 2009/02/10 CT009 T.Shimoji
    --IF (lv_retcode <> cv_status_normal) THEN                                                        -- 戻り値が異常の場合
    --  RAISE global_process_expt;
    --END IF;
    IF (lv_retcode = cv_status_error) THEN                                                          -- 戻り値が異常の場合
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
    --//+UPD END 2009/02/10 CT009 T.Shimoji
--
--#################################  固定例外処理部  #############################
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--#####################################  固定部 END   ###########################
--
  END submain;
--
  /*****************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   ****************************************************************************/
  PROCEDURE main(
                errbuf           OUT    NOCOPY VARCHAR2                                             -- エラーメッセージ
               ,retcode          OUT    NOCOPY VARCHAR2                                             -- エラーコード
               ,iv_taisyo_year   IN            VARCHAR2                                             -- 対象年度
               ,iv_kyoten_cd     IN            VARCHAR2                                             -- 拠点コード
               ,iv_cost_kind     IN            VARCHAR2                                             -- 原価種別
               ,iv_kyoten_kaisou IN            VARCHAR2                                             -- 階層
               )
  IS
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);                                                                      -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                                                         -- リターン・コード
    lv_errmsg  VARCHAR2(4000);                                                                      -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- 終了メッセージコード
    lv_message_code   VARCHAR2(100);                                                                -- 終了コード
-- ===============================
-- 固定ローカル定数
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'main';                                         -- プログラム名
    cv_which_log        CONSTANT VARCHAR2(10)    := 'LOG';                                          -- 出力先
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    retcode := cv_status_normal;
--
--##################  固定部 END   #####################################
--
--###########################  固定部 START   ###########################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_which_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
--空行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
      );
--
--###########################  固定部 END   #############################
-- 入力パラメータを変数を格納
    gn_taisyoyear   := TO_NUMBER(iv_taisyo_year);                                                   -- 対象年度
    gv_kyotencd     := iv_kyoten_cd;                                                                -- 拠点コード
    gv_genkacd      := iv_cost_kind;                                                                -- 原価種別
    gv_kaisou       := iv_kyoten_kaisou;                                                            -- 階層
-- 実装処理
    submain(                                                                                        -- submainをコール
            ov_retcode => lv_retcode                                                                -- エラー・メッセージ
           ,ov_errbuf  => lv_errbuf                                                                 -- リターン・コード
           ,ov_errmsg  => lv_errmsg                                                                 -- ユーザー・エラー・メッセージ
           );
--
    IF(lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm
                        ,iv_name         => cv_ccp1_msg_00111
                        );
      END IF;
--
      fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf            -- エラーメッセージ
       );
      --//+ADD START 2009/02/10 CT009 T.Shimoji
      fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg            -- ユーザー・エラーメッセージ
      );
      --//+ADD END 2009/02/10 CT009 T.Shimoji
     -- 件数カウンタの初期化
      gn_target_cnt := 0;                                                                           -- 対象件数カウンタの初期化
      gn_normal_cnt := 0;                                                                           -- 正常件数カウンタの初期化
      gn_error_cnt  := 1;                                                                           -- エラー件数カウンタの初期化
      gn_warn_cnt   := 0;                                                                           -- スキップ件数カウンタの初期化
    END IF;
--空行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
      );
--対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp1_msg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp1_msg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp1_msg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp1_msg_90003
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
--空行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
      );
--終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_ccp1_msg_90004;
--//+ADD START 2009/02/10 CT009 T.Shimoji
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_ccp1_msg_90005;
--//+ADD END 2009/02/10 CT009 T.Shimoji
    ELSE
      lv_message_code := cv_ccp1_msg_90006;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--ステータスセット
    retcode := lv_retcode;
--終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
--#####################  固定例外処理部 START   ########################
  EXCEPTION
  -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      retcode := cv_status_error;
    ROLLBACK;
  -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
    ROLLBACK;
--#####################  固定部 END   ###################################    
--
  END main;
--
--##############################################################################
--  
END XXCSM002A12C;
/
