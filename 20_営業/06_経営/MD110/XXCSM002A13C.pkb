CREATE OR REPLACE PACKAGE BODY      XXCSM002A13C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A13C(body)
 * Description      : 商品計画リスト(時系列_本数単位)出力
 * MD.050           : 商品計画リスト(時系列_本数単位)出力 MD050_CSM_002_A13
 * Version          : 1.13
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                【初期処理】A-1
 *
 *  do_check            【チェック処理】A-2~A-3
 *
 *  deal_item_data      【商品単位の処理】A-4~A-6
 *
 *  deal_group4_data    【商品群単位の処理】A-7~A-9
 *
 *  deal_group1_data    【商品区分単位の処理】A-10~A-12
 *
 *  deal_sum_data       【商品合計単位の処理】A-13~A-15
 *
 *  deal_down_data      【商品値引単位の処理】A-16~A-17
 *
 *  deal_kyoten_data    【拠点単位の処理】A-18~A-20
 *
 *  deal_all_data       【拠点リスト単位の処理】A-2~A-20
 *
 *  get_col_data        【各項目のデータを取得】【数量・売上・掛率・粗利益額】A-21
 *     
 *  deal_csv_data       【拠点単位】出力データの抽出 A-21
 *  
 *  write_csv_file      【出力処理】A-22
 *  
 *  submain             【実装処理】A-1~A-23
 *
 *  main                【コンカレント実行ファイル登録プロシージャ】A-1~A-23
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   ohshikyo        新規作成
 *  2009/02/06    1.1   Kenji.Sai       write_csv_file (A-22)のヘッダメッセージのSYSDATE表示
 *  2009/02/09    1.2   Kenji.Sai       do_check (A-2)の按分処理未完了メッセージ表示追加 
 *  2009/02/12    1.3   Kenji.Sai       テストレビュー後指摘事項修正 
 *  2009/02/23    1.4   S.Son           [障害CT_029] 件数のカウントに不具合対応
 *                                      [障害CT_031] 出力順の不具合対応
 *                                      [障害CT_042] 小数点出力の不具合対応
 *  2009/02/24    1.5   Kenji.Sai       [障害CT_054] 入金値引年計の不具合対応
 *  2009/02/25    1.6   T.Tsukino       [障害CT_062] CSVファイル商品群出力不具合対応
 *  2009/05/07    1.7   M.Ohtsuki       [障害T1_0858] 共通関数修正に伴うパラメータの追加
 *  2009/05/27    1.8   M.Ohtsuki       [障害T1_1199] 商品データの年間計の不具合の対応
 *  2010/03/24    1.9   N.Abe           [E_本稼動_01906] PT対応(ヒント句追加)
 *  2011/01/07    1.10  SCS OuKou       [E_本稼動_05803]
 *  2012/12/19    1.11  SCSK K.Taniguchi[E_本稼動_09949] 新旧原価選択可能対応
 *  2013/01/31    1.12  SCSK K.Taniguchi[E_本稼動_09949再] 年度開始日取得の不具合対応
 *  2018/11/14    1.13  SCSK Y.Sasaki   [E_本稼動_15333] 政策群追加による変更（出力対象政策群を参照表管理へ）
 *
 *****************************************************************************************/
--
-- 
 --#######################  固定グローバル定数宣言部 START   ######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;     -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;       -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;      -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                     -- CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                                -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                     -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                                -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                    -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;             -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;                -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;             -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                                -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
  cn_unit                   CONSTANT NUMBER        := 1000;                                   -- 出力単位：千円
  cv_all_zero               CONSTANT VARCHAR2(100) := '0,0,0,0,0,0,0,0,0,0,0,0,0' || CHR(10); -- 月間と年間データ:0
  cv_sum_zero               CONSTANT VARCHAR2(10)   := '0' || CHR(10);        -- 年間データ:0
  cn_base_price             CONSTANT NUMBER        := 10;                     -- 標準原価
  cn_bus_price              CONSTANT NUMBER        := 20;                     -- 営業原価
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
  gn_target_cnt             NUMBER;       -- 対象件数
  gn_normal_cnt             NUMBER;       -- 正常件数
  gn_error_cnt              NUMBER;       -- エラー件数
  gn_warn_cnt               NUMBER;       -- スキップ件数
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A13C';               -- パッケージ名
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                          -- カンマ     
  cv_msg_hafu               CONSTANT VARCHAR2(3)   := '-';                          -- 
  cv_msg_space              CONSTANT VARCHAR2(4)   := '';                           -- 空白
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                          -- ダブルクォーテーション
--
  cv_msg_linespace          CONSTANT VARCHAR2(20) := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma || cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
--
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                      -- アプリケーション短縮名    
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                      -- アドオン：共通・IF領域
  cv_group_A                CONSTANT VARCHAR2(10)  := 'A' ;                         -- 商品群A
  cv_group_C                CONSTANT VARCHAR2(10)  := 'C' ;                         -- 商品群C
  cv_group_D                CONSTANT VARCHAR2(10)  := 'D' ;                         -- 商品群D
  cv_group_N                CONSTANT VARCHAR2(10)  := 'N' ;                         -- 商品群N
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                          -- フラグY
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                          -- フラグN
  cv_whse_code              CONSTANT VARCHAR2(3)   := '000';                        -- 原価倉庫
  cv_new_cost               CONSTANT VARCHAR2(10)  := '10';                         -- パラメータ：新旧原価区分（新原価）
  cv_old_cost               CONSTANT VARCHAR2(10)  := '20';                         -- パラメータ：新旧原価区分（旧原価）
--//+ADD END E_本稼動_09949 K.Taniguchi
-- 
  -- ===============================
  -- ユーザー定義グローバル変数 
  -- ===============================
--  
  gd_process_date          DATE;                                               -- 業務日付
  gn_index                 NUMBER := 0;                                        -- 登録順
  gv_kyotencd              VARCHAR2(32);                                       -- 拠点コード  
  gn_taisyoym              NUMBER(4,0);                                        -- 対象年度
  gv_genkacd               VARCHAR2(200);                                      -- 原価種別
  gv_genkanm               VARCHAR2(200);                                      -- 原価種別名
  gv_kaisou                VARCHAR2(2);                                        -- 階層
--//+ADD START E_本稼動_09949 K.Taniguchi
  gv_new_old_cost_class    VARCHAR2(2);                                        -- 新旧原価区分(パラメータ格納用)
  gd_gl_start_date         DATE;                                               -- 起動時の年度開始日
--//+ADD END E_本稼動_09949 K.Taniguchi
--
  -- ===============================
  -- 共用メッセージ番号
  -- ===============================
--  
  cv_ccp1_msg_90000           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';         -- 対象件数メッセージ
  cv_ccp1_msg_90001           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';         -- 成功件数メッセージ
  cv_ccp1_msg_90002           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';         -- エラー件数メッセージ
  cv_ccp1_msg_90003           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';         -- スキップ件数メッセージ
  cv_ccp1_msg_90004           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';         -- 正常終了メッセージ
  cv_ccp1_msg_90005           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';         -- 警告終了メッセージ
  cv_ccp1_msg_90006           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';         -- エラー終了全ロールバックメッセージ
  cv_ccp1_msg_00111           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';         -- 想定外エラーメッセージ
--  
  -- ===============================  
  -- メッセージ番号
  -- ===============================
--  
  cv_csm1_msg_00005           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';         -- プロファイル取得エラーメッセージ
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_csm1_msg_10168           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10168';         -- 年度開始日取得エラー
--//+ADD END E_本稼動_09949 K.Taniguchi
  cv_csm1_msg_00092           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00092';         -- 商品計画リスト(時系列:本数単位)ヘッダ用メッセージ
  cv_csm1_msg_00048           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';         -- 入力パラメータ取得メッセージ(拠点コード)
  cv_csm1_msg_00087           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';         -- 商品計画未設定メッセージ
  cv_csm1_msg_00088           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';         -- 商品計画単品別按分処理未完了メッセージ
  cv_csm1_msg_00099           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00099';         -- データ無しメッセージ
  cv_csm1_msg_10001           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';         -- 取得データ0件エラーメッセージ
  cv_csm1_msg_10015           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10015';         -- 入力パラメータ取得メッセージ（対象年度）
  cv_csm1_msg_10016           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10016';         -- 入力パラメータ取得メッセージ（階層）
  cv_csm1_msg_10017           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10017';         -- 入力パラメータ取得メッセージ（原価種別名）
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_csm1_msg_10167           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10167';         -- 入力パラメータ取得メッセージ（新旧原価区分）
--//+ADD END E_本稼動_09949 K.Taniguchi
--
  -- ===============================
  -- トークン定義
  -- ===============================
--  
  cv_tkn_year                      CONSTANT VARCHAR2(100) := 'TAISYOU_YM';      -- 対象年度
  cv_tkn_kyotencd                  CONSTANT VARCHAR2(100) := 'KYOTEN_CD';       -- 拠点コード
  cv_tkn_genka_cd                  CONSTANT VARCHAR2(100) := 'GENKA_CD';        -- 原価種別
  cv_tkn_genka_nm                  CONSTANT VARCHAR2(100) := 'GENKA_NM';        -- 原価種別名
  cv_tkn_kaisou                    CONSTANT VARCHAR2(100) := 'KAISOU';          -- 階層コード
  cv_tkn_profile                   CONSTANT VARCHAR2(100) := 'PROF_NAME';       -- プロファイル名
  cv_tkn_count                     CONSTANT VARCHAR2(100) := 'COUNT';           -- 処理件数
  cv_tkn_sysdate                   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI'; -- 作成日時
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_tkn_new_old_cost_cls          CONSTANT VARCHAR2(100) := 'NEW_OLD_COST_CLASS';  -- 新旧原価区分
  cv_tkn_sobid                     CONSTANT VARCHAR2(100) := 'SET_OF_BOOKS_ID';     -- 会計帳簿ID
  cv_tkn_process_date              CONSTANT VARCHAR2(100) := 'PROCESS_DATE';        -- 業務日付
--//+ADD END E_本稼動_09949 K.Taniguchi
--
  -- =============================== 
  -- プロファイル
  -- ===============================
-- プロファイル・コード  
  lv_prf_cd_sales                   CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';     -- XXCMN:売上
  lv_prf_cd_rate                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';     -- XXCMN:掛率
  lv_prf_cd_amount                  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';     -- XXCMN:数量
  lv_prf_cd_margin                  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';    -- XXCMN:粗利益額
--  
  lv_prf_cd_sum                     CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';    -- XXCMN:商品合計
  lv_prf_cd_down_sales              CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';    -- XXCMN:売上値引
  lv_prf_cd_down_pay                CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';    -- XXCMN:入金値引
  lv_prf_cd_p_sum                   CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_5';     -- XXCMN:拠点計
  lv_prf_cd_price_e                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_6';     -- XXCMN:営業原価
  lv_prf_cd_price_h                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_7';     -- XXCMN:標準原価
  lv_prf_cd_unit_hon                CONSTANT VARCHAR2(100) := 'XXCSM1_UNIT_ITEM_1';         -- XXCMN:本
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_prf_gl_set_of_bks_id           CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';           -- 会計帳簿IDプロファイル名
--//+ADD END E_本稼動_09949 K.Taniguchi
--
-- プロファイル・名称
  lv_prf_cd_sales_val                   VARCHAR2(100) ;                                 -- XXCMN:売上
  lv_prf_cd_rate_val                    VARCHAR2(100) ;                                 -- XXCMN:掛率
  lv_prf_cd_amount_val                  VARCHAR2(100) ;                                 -- XXCMN:数量
  lv_prf_cd_margin_val                  VARCHAR2(100) ;                                 -- XXCMN:粗利益額
  lv_prf_cd_sum_val                     VARCHAR2(100) ;                                 -- XXCMN:商品合計
  lv_prf_cd_down_sales_val              VARCHAR2(100) ;                                 -- XXCMN:売上値引
  lv_prf_cd_down_pay_val                VARCHAR2(100) ;                                 -- XXCMN:入金値引
  lv_prf_cd_p_sum_val                   VARCHAR2(100) ;                                 -- XXCMN:拠点計
  lv_prf_cd_price_e_val                 VARCHAR2(100) ;                                 -- XXCMN:営業原価
  lv_prf_cd_price_h_val                 VARCHAR2(100) ;                                 -- XXCMN:標準原価
  lv_prf_cd_unit_hon_val                VARCHAR2(100) ;                                 -- XXCMN:本
--//+ADD START E_本稼動_09949 K.Taniguchi
  gv_prf_gl_set_of_bks_id               VARCHAR2(100) ;                                 -- 会計帳簿ID(Char)
  gn_prf_gl_set_of_bks_id               NUMBER;                                         -- 会計帳簿ID
--//+ADD END E_本稼動_09949 K.Taniguchi
--  2018/11/14 V1.13 Added START
  --  処理対象の政策群保持用タイプ
  TYPE g_group_rtype IS RECORD(
      target_group      fnd_lookup_values.lookup_code%TYPE            --  政策群コード
    , summary_type      fnd_lookup_values.lookup_code%TYPE            --  合計区分
    , summary_name      fnd_lookup_values.description%TYPE            --  合計区分名
    , summary_disp      VARCHAR2(1)                                   --  合計出力フラグ
  );
  TYPE g_group_ttype IS TABLE OF g_group_rtype INDEX BY BINARY_INTEGER ;
  --
  cv_lookup_summary     CONSTANT VARCHAR2(30) :=  'XXCSM1_ITEM_PLAN_LIST_SUMMARY';    --  商品計画リスト合計区分
  cv_lookup_group       CONSTANT VARCHAR2(30) :=  'XXCSM1_ITEM_PLAN_LIST_GROUP';      --  商品計画リスト出力対象商品群
  cv_summary_type_99    CONSTANT VARCHAR2(2)  :=  '99';                               --  合計区分99:その他合計
--  2018/11/14 V1.13 Added END
--
    /****************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)           
   ****************************************************************************/
   PROCEDURE init (    
         ov_errbuf     OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- パラメータメッセージ出力用
    lv_pram_op_1                VARCHAR2(100);
    lv_pram_op_2                VARCHAR2(100);
    lv_pram_op_3                VARCHAR2(100);
    lv_pram_op_4                VARCHAR2(100);
--//+ADD START E_本稼動_09949 K.Taniguchi
    lv_pram_op_5                VARCHAR2(100);
--//+ADD END E_本稼動_09949 K.Taniguchi
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value                VARCHAR2(100);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- 業務日付
    gd_process_date := xxccp_common_pkg2.get_process_date;                      -- 業務日付取得
    
    -- 対象年度(INパラメータの出力)
    lv_pram_op_1 := xxccp_common_pkg.get_msg(                                   -- 対象年度の出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10015                      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year                            -- トークンコード1（対象年度名称）
                     ,iv_token_value1 => gn_taisyoym                            -- トークン値1
                     );
    -- LOGに出力
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => CHR(10) || lv_pram_op_1  
                     );
    -- 拠点コード(INパラメータの出力)
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                   -- 拠点コードの出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_00048                      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- トークンコード1（拠点コード）
                     ,iv_token_value1 => gv_kyotencd                            -- トークン値1
                     );
    -- LOGに出力
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_pram_op_2 
                     );
    -- 原価種別(INパラメータの出力)
    lv_pram_op_3 := xxccp_common_pkg.get_msg(                                    -- 原価種別の出力
                      iv_application  => cv_xxcsm                                -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10017                       -- メッセージコード
                     ,iv_token_name1  => cv_tkn_genka_cd                         -- トークンコード1（原価種別）
                     ,iv_token_value1 => gv_genkacd                              -- トークン値1
                     );
    -- LOGに出力
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_pram_op_3  
                     );
    -- 階層(INパラメータの出力)
    lv_pram_op_4 := xxccp_common_pkg.get_msg(                                   -- 階層の出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10016                      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kaisou                          -- トークンコード1（階層）
                     ,iv_token_value1 => gv_kaisou                              -- トークン値1
                     );
    -- LOGに出力
    fnd_file.put_line(
                      which  => FND_FILE.LOG
--//+UPD START E_本稼動_09949 K.Taniguchi
--                   ,buff   => lv_pram_op_4 || CHR(10)
                     ,buff   => lv_pram_op_4
--//+UPD END E_本稼動_09949 K.Taniguchi
                     );
--//+ADD START E_本稼動_09949 K.Taniguchi
    -- 新旧原価区分(INパラメータの出力)
    lv_pram_op_5 := xxccp_common_pkg.get_msg(                                   -- 階層の出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10167                      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_new_old_cost_cls                -- トークンコード1（新旧原価区分）
                     ,iv_token_value1 => gv_new_old_cost_class                  -- トークン値1
                     );
    -- LOGに出力
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => lv_pram_op_5 || CHR(10)
                     );
--//+ADD END E_本稼動_09949 K.Taniguchi
--
    -- ===========================================================================
    -- プロファイル情報の取得
    -- ===========================================================================
    -- 変数初期化処理 
    lv_tkn_value := NULL;
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
                    name => lv_prf_cd_sales
                   ,val  => lv_prf_cd_sales_val
                   ); -- 売上
    FND_PROFILE.GET(
                    name => lv_prf_cd_rate
                   ,val  => lv_prf_cd_rate_val
                   ); -- 掛率
    FND_PROFILE.GET(
                    name => lv_prf_cd_amount
                   ,val  => lv_prf_cd_amount_val
                   ); -- 数量
    FND_PROFILE.GET(
                    name => lv_prf_cd_margin
                   ,val  => lv_prf_cd_margin_val
                   ); --粗利益額
    FND_PROFILE.GET(
                    name => lv_prf_cd_sum
                   ,val  => lv_prf_cd_sum_val
                   ); -- 商品合計
    FND_PROFILE.GET(
                    name => lv_prf_cd_down_sales
                   ,val  => lv_prf_cd_down_sales_val
                   ); -- 売上値引
    FND_PROFILE.GET(
                    name => lv_prf_cd_down_pay
                   ,val  => lv_prf_cd_down_pay_val
                   ); -- 入金値引
    FND_PROFILE.GET(
                    name => lv_prf_cd_p_sum
                   ,val  => lv_prf_cd_p_sum_val
                   ); -- 拠点計
    FND_PROFILE.GET(
                    name => lv_prf_cd_price_e
                   ,val  => lv_prf_cd_price_e_val
                   ); -- 営業原価                     
    FND_PROFILE.GET(
                    name => lv_prf_cd_price_h
                   ,val  => lv_prf_cd_price_h_val
                   ); -- 標準原価
    FND_PROFILE.GET(
                    name => lv_prf_cd_unit_hon
                   ,val  => lv_prf_cd_unit_hon_val
                   ); -- 単位：本
--//+ADD START E_本稼動_09949 K.Taniguchi
    FND_PROFILE.GET(
                    name => cv_prf_gl_set_of_bks_id
                   ,val  => gv_prf_gl_set_of_bks_id
                   ); -- 会計帳簿ID
    gn_prf_gl_set_of_bks_id := TO_NUMBER(gv_prf_gl_set_of_bks_id);
--//+ADD END E_本稼動_09949 K.Taniguchi
--
    -- =========================================================================
    -- プロファイル値取得に失敗した場合
    -- =========================================================================
    -- 売上
    IF (lv_prf_cd_sales_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_sales;
        -- 掛率
    ELSIF (lv_prf_cd_rate_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_rate;
        -- 数量
    ELSIF (lv_prf_cd_amount_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_amount;
        -- 粗利益額
    ELSIF (lv_prf_cd_margin_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_margin;
        -- 商品合計
    ELSIF (lv_prf_cd_sum_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_sum;
        -- 売上値引
    ELSIF (lv_prf_cd_down_sales_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_down_sales;
        -- 入金値引
    ELSIF (lv_prf_cd_down_pay_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_down_pay;
        -- 拠点計
    ELSIF (lv_prf_cd_p_sum_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_p_sum;
        -- 営業原価
    ELSIF (lv_prf_cd_price_e_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_price_e;
        -- 標準原価
    ELSIF (lv_prf_cd_price_h_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_price_h;
        -- 単位：本
    ELSIF (lv_prf_cd_unit_hon_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_unit_hon;
--//+ADD START E_本稼動_09949 K.Taniguchi
        -- 会計帳簿ID
    ELSIF (gn_prf_gl_set_of_bks_id IS NULL) THEN
      lv_tkn_value := cv_prf_gl_set_of_bks_id;
--//+ADD END E_本稼動_09949 K.Taniguchi
    END IF;
--
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                -- アプリケーション短縮名
                    ,iv_name         => cv_csm1_msg_00005                       -- メッセージコード
                    ,iv_token_name1  => cv_tkn_profile                          -- トークンコード1（プロファイル）
                    ,iv_token_value1 => lv_tkn_value                            -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 原価種別名称
   IF (gv_genkacd = cn_bus_price) THEN
       gv_genkanm := lv_prf_cd_price_e_val; -- 営業原価
   ELSIF (gv_genkacd = cn_base_price) THEN
       gv_genkanm := lv_prf_cd_price_h_val; -- 標準原価
   END IF;
--
--//+ADD START E_本稼動_09949 K.Taniguchi
    -- =====================
    -- 起動時の年度開始日取得
    -- =====================
    BEGIN
      -- 年度開始日
      SELECT  gp.start_date             AS start_date             -- 年度開始日
      INTO    gd_gl_start_date                                    -- 起動時の年度開始日
      FROM    gl_sets_of_books          gsob                      -- 会計帳簿マスタ
             ,gl_periods                gp                        -- 会計カレンダ
      WHERE   gsob.set_of_books_id      = gn_prf_gl_set_of_bks_id -- 会計帳簿ID
      AND     gp.period_set_name        = gsob.period_set_name    -- カレンダ名
      AND     gp.period_year            = (
                                            -- 起動時の年度
                                            SELECT  gp2.period_year           AS period_year            -- 年度
                                            FROM    gl_sets_of_books          gsob2                     -- 会計帳簿マスタ
                                                   ,gl_periods                gp2                       -- 会計カレンダ
                                            WHERE   gsob2.set_of_books_id     = gn_prf_gl_set_of_bks_id -- 会計帳簿ID
                                            AND     gp2.period_set_name       = gsob2.period_set_name   -- カレンダ名
--//+ADD START E_本稼動_09949再 K.Taniguchi
                                            AND     gp2.adjustment_period_flag = cv_flg_n               -- 調整会計期間外
--//+ADD END E_本稼動_09949再 K.Taniguchi
                                            AND     gd_process_date           BETWEEN gp2.start_date    -- 業務日付時点
                                                                              AND     gp2.end_date
                                          )
      AND     gp.adjustment_period_flag = cv_flg_n              -- 調整会計期間外
      AND     gp.period_num             = 1                     -- 年度開始月
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_csm1_msg_10168
                      ,iv_token_name1  => cv_tkn_sobid
                      ,iv_token_value1 => TO_CHAR(gn_prf_gl_set_of_bks_id)       -- 会計帳簿ID
                      ,iv_token_name2  => cv_tkn_process_date
                      ,iv_token_value2 => TO_CHAR(gd_process_date, 'YYYY/MM/DD') -- 業務日付
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--//+ADD END E_本稼動_09949 K.Taniguchi
--#################################  固定例外処理部  #############################
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
  END init;
--
   /****************************************************************************
   * Procedure Name   : do_check
   * Description      : チェック処理 (A-2~A-3)
   ****************************************************************************/
   PROCEDURE do_check (
         iv_kyoten_cd   IN  VARCHAR2                     -- 拠点コード
        ,ov_errbuf     OUT NOCOPY VARCHAR2               -- 共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               -- リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              -- ユーザー・エラー・メッセージ
   IS
--
--#####################  固定ローカル変数宣言部 START   ###########################
--
  lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
  lv_retcode VARCHAR2(1);     -- リターン・コード
  lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- ===============================
-- 固定ローカル定数
-- ===============================
   cv_prg_name         CONSTANT VARCHAR2(100)   := 'do_check'; -- プログラム名
--
-- ===============================
-- ユーザｰローカル変数
-- ===============================
   -- データ存在チェック用
   ln_counts                 NUMBER(1,0) := 0;
   lb_loop_end               BOOLEAN     := FALSE;
--
-- ===============================
-- ユーザｰローカル例外
-- ===============================
   check_skip_expt EXCEPTION;   -- スキップ処理例外
--
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 年間商品計画データ存在チェック
    SELECT
                  count(1)
    INTO  
                  ln_counts
    FROM  
                   xxcsm_item_plan_lines xipl                            -- 商品計画ヘッダテーブル
                  ,xxcsm_item_plan_headers xiph                          -- 商品計画明細テーブル
    WHERE 
              xipl.item_plan_header_id      = xiph.item_plan_header_id   -- 商品計画ヘッダID
    AND       xiph.plan_year                = gn_taisyoym                -- 対象年度
    AND       xiph.location_cd              = iv_kyoten_cd               -- 拠点コード
    AND       rownum                        = 1;                         -- 1行目   
--
    -- 件数が0の場合、ステータスは警告で、処理をスキップします。                                
    IF (ln_counts = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                          -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_00087                 -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year                       -- トークンコード1（対象年度）
                     ,iv_token_value1 => gn_taisyoym                       -- トークン値1
                     ,iv_token_name2  => cv_tkn_kyotencd                   -- トークンコード2（拠点コード）
                     ,iv_token_value2 => iv_kyoten_cd                      -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE check_skip_expt;
    END IF;
    -- 按分処理済データ存在チェック
    ln_counts := 0;
--
    SELECT
              count(1)
    INTO  
              ln_counts
    FROM  
               xxcsm_item_plan_lines xipl                         -- 商品計画ヘッダテーブル
              ,xxcsm_item_plan_headers xiph                       -- 商品計画明細テーブル         
    WHERE 
              xipl.item_plan_header_id    = xiph.item_plan_header_id   -- 商品計画ヘッダID
    AND       xiph.plan_year              = gn_taisyoym                -- 対象年度
    AND       xiph.location_cd            = iv_kyoten_cd               -- 拠点コード
    AND       xipl.item_kbn               <> '0'                       -- 商品群以外
    AND       rownum                      = 1;                         -- 1行目   
--
    -- 件数が0の場合、処理がスキップします。                                
    IF (ln_counts = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                              -- アプリケーション短縮名
                      ,iv_name         => cv_csm1_msg_00088                     -- メッセージコード
                      ,iv_token_name1  => cv_tkn_year                           -- トークンコード1（対象年度）
                      ,iv_token_value1 => gn_taisyoym                           -- トークン値1
                      ,iv_token_name2  => cv_tkn_kyotencd                       -- トークンコード2（拠点コード）
                      ,iv_token_value2 => iv_kyoten_cd                          -- トークン値2
                    );
      lv_errbuf := lv_errmsg;
      RAISE check_skip_expt;
    END IF;
--
  EXCEPTION
    -- *** 商品計画未設定、按分処理済データ存在チェック ***
    WHEN check_skip_expt THEN
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
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ###########################
--
  END do_check;
--
   /****************************************************************************
   * Procedure Name   : deal_group4_data (A-7~A-9)
   * Description      : 商品群データの詳細処理
   *                    �@データの抽出
   *                    �Aデータの算出
   *                    �Bデータの登録
   ****************************************************************************/
   PROCEDURE deal_group4_data(
         iv_group4_cd   IN  VARCHAR2                      --商品群コード
        ,ov_errbuf      OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode     OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg      OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group4_data';      -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               --年間_粗利益額合計
    ln_y_amount             NUMBER  := 0;               --年間_数量合計
    ln_y_psa                NUMBER  := 0;               --年間_数量*定価の合計
    ln_y_bsa                NUMBER  := 0;               --年間_数量*原価の合計
    ln_y_rate               NUMBER  := 0;               --年間_掛率
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP判断用
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--============================================
--  データの抽出【商品群】ローカル・カーソル
--============================================
--                  
    CURSOR   
        get_group4_data_cur
    IS
      SELECT   
         xwsph.group_cd_1                                 AS  group_cd_1                -- 商品群コード(1桁)
        ,xwsph.group_nm_1                                 AS  group_nm_1                -- 商品群名称(1桁)
        ,xwsph.group_cd_4                                 AS  group_cd_4                -- 商品群コード(4桁)
        ,xwsph.group_nm_4                                 AS  group_nm_4                -- 商品群名称(4桁)
        ,xwsph.month_no                                   AS  month                     -- 月
        ,SUM(NVL(xwsph.m_amount,0))                       AS  amount                    -- 数量
        ,SUM(NVL(xwsph.m_sales,0))                        AS  sales                     -- 売上金額
        ,SUM(NVL(xwsph.t_price,0))                        AS  t_price                   -- 数量*定価
        ,SUM(NVL(xwsph.g_price,0))                        AS  g_price                   -- 数量*原価
      FROM     
        xxcsm_tmp_sales_plan_hon    xwsph                -- 商品計画リスト出力ワークテーブル
      WHERE    
        xwsph.group_cd_4                                  = iv_group4_cd               -- 商品群コード(4桁)
      GROUP BY
       xwsph.group_cd_1                                                            -- 商品群コード(1桁)
      ,xwsph.group_cd_4                                                            -- 商品群コード(4桁)
      ,xwsph.group_nm_1                                                            -- 商品群名称(1桁)
      ,xwsph.group_nm_4                                                            -- 商品群名称(4桁)
      ,xwsph.month_no                                                              -- 月
      ORDER BY 
       group_cd_1  ASC
       ,month       ASC
;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    
    <<get_group4_data_loop>>
    -- 【商品群】データ取得
    FOR rec_group4 IN get_group4_data_cur LOOP
        lb_loop_end     := TRUE;
        -- =======================================
        -- 年間累計【加算】
        -- =======================================
--
        -- 年間売上
        ln_y_sales      := ln_y_sales + rec_group4.sales;
        -- 年間数量
        ln_y_amount     := ln_y_amount + rec_group4.amount ;
        ln_y_psa        := ln_y_psa + rec_group4.t_price;
        ln_y_bsa        := ln_y_bsa + rec_group4.g_price;
        -- 月間_掛率=月間_売上／（月間_数量*定価）*100
        IF (rec_group4.t_price = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(rec_group4.sales / rec_group4.t_price * 100,2);
        END IF;
--
        --===================================
        -- 【商品群-月間】データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_hon
          (
              toroku_no        --出力順
              ,group_cd_1      --商品群コード(1桁)
              ,group_nm_1      --商品群名称(1桁)
              ,group_cd_4      --商品群コード(4桁)
              ,group_nm_4      --商品群名称(4桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin        --月間_粗利益額
              ,t_price         -- 定価＊数量
              ,g_price         -- 原価＊数量
          )
          VALUES (
               gn_index
              ,rec_group4.group_cd_1
              ,rec_group4.group_nm_1
              ,NULL
              ,NULL
              ,rec_group4.group_cd_4
              ,rec_group4.group_nm_4
              ,rec_group4.month
              ,rec_group4.sales
              ,rec_group4.amount 
--              ,ROUND(rec_group4.sales / rec_group4.t_price * 100,2)
              ,ln_y_rate
              ,rec_group4.sales - rec_group4.g_price
              ,rec_group4.t_price
              ,rec_group4.g_price
          );
        -- 登録順の加算
        gn_index := gn_index + 1;
    END LOOP get_group4_data_loop;
--
    -- 【商品群】年間データの登録
    IF (lb_loop_end = TRUE) THEN
        -- 年間粗利益額
        ln_y_margin      := ln_y_sales - ln_y_bsa;
        -- 年間_掛率【算出処理】:年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
        IF (ln_y_psa = 0) THEN
          ln_y_rate      := 0;
        ELSE
          ln_y_rate      := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
        -- 更新処理
        UPDATE
                xxcsm_tmp_sales_plan_hon
        SET
               y_sales          = ln_y_sales      -- 年間売上
              ,y_amount         = ln_y_amount     -- 年間数量
              ,y_rate           = ln_y_rate       -- 年間掛率
              ,y_margin         = ln_y_margin     -- 年間粗利益額
        WHERE
               item_cd          = iv_group4_cd;   -- 商品コード
--
    END IF;
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
      IF (get_group4_data_cur%ISOPEN) THEN
        CLOSE get_group4_data_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
--
      IF (get_group4_data_cur%ISOPEN) THEN
        CLOSE get_group4_data_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END deal_group4_data;
--
  /*****************************************************************************
   * Procedure Name   : deal_group1_data (A-10~A-12)
   * Description      : 【商品区分】データの詳細処理
   ****************************************************************************/
  PROCEDURE deal_group1_data(
        iv_group1_cd    IN  VARCHAR2          -- 商品区分コード
       ,ov_errbuf       OUT NOCOPY VARCHAR2   -- エラー・メッセージ
       ,ov_retcode      OUT NOCOPY VARCHAR2   -- リターン・コード
       ,ov_errmsg       OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group1_data';      -- プログラム名
    
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               --年間_粗利益額合計
    ln_y_amount             NUMBER  := 0;               --年間_数量合計
    ln_y_psa                NUMBER  := 0;               --年間_数量*定価の合計
    ln_y_bsa                NUMBER  := 0;               --年間_数量*原価の合計
    ln_y_rate               NUMBER  := 0;               --年間_掛率
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP判断用
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--============================================
--  データの抽出【商品区分】カーソル
--============================================
--                  
    CURSOR   
        get_group1_data_cur
    IS
      SELECT   
             xwsph.group_cd_1                                 AS  group_cd_1                -- 商品群コード(1桁)
            ,xwsph.group_nm_1                                 AS  group_nm_1                -- 商品群名称(1桁)
            ,xwsph.month_no                                   AS  month                     -- 月
            ,SUM(NVL(xwsph.m_amount,0))                       AS  amount                    -- 数量
            ,SUM(NVL(xwsph.m_sales,0))                        AS  sales                     -- 売上金額
            ,SUM(NVL(xwsph.t_price,0))                        AS  t_price                   -- 数量*定価
            ,SUM(NVL(xwsph.g_price,0))                        AS  g_price                   -- 数量*原価
      FROM     
            xxcsm_tmp_sales_plan_hon                      xwsph -- 商品計画リスト出力ワークテーブル
      WHERE    
            xwsph.group_cd_4                                  IS NULL                      -- 商品群コード(1桁)
      AND   xwsph.group_cd_1                                  = iv_group1_cd               -- 商品群コード(1桁)
      GROUP BY
               xwsph.group_cd_1                                                            -- 商品群コード(1桁)
              ,xwsph.group_nm_1                                                            -- 商品群コード(1桁)
              ,xwsph.month_no                                                              -- 月
      ORDER BY 
               xwsph.month_no    ASC;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<get_group1_data_loop>>
    -- 【商品区分】データ取得
    FOR rec_group1 IN get_group1_data_cur LOOP
        lb_loop_end     := TRUE;
        -- =======================================
        -- 年間累計【加算】
        -- =======================================
        -- 年間売上
        ln_y_sales      := ln_y_sales + rec_group1.sales;
        -- 年間数量
        ln_y_amount     := ln_y_amount + rec_group1.amount ;
        ln_y_psa        := ln_y_psa + rec_group1.t_price;
        ln_y_bsa        := ln_y_bsa + rec_group1.g_price;
        -- 月間_掛率=月間_売上／（月間_数量*定価）*100
        IF (rec_group1.t_price = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(rec_group1.sales / rec_group1.t_price * 100,2);
        END IF;
--
        --===================================
        -- 【商品区分】月間データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_hon
          (
              toroku_no        --出力順
              ,group_cd_1      --商品群コード(1桁)
              ,group_nm_1      --商品群名称(1桁)
              ,group_cd_4      --商品群コード(4桁)
              ,group_nm_4      --商品群名称(4桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin        --月間_粗利益額
              ,t_price         -- 定価＊数量
              ,g_price         -- 原価＊数量
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,rec_group1.group_cd_1
              ,rec_group1.group_nm_1
              ,rec_group1.month
              ,rec_group1.sales
              ,rec_group1.amount 
--              ,ROUND(rec_group1.sales / rec_group1.t_price * 100,2)
              ,ln_y_rate
              ,rec_group1.sales - rec_group1.g_price
              ,rec_group1.t_price
              ,rec_group1.g_price
          );
        -- 登録順の加算
        gn_index := gn_index + 1;
    END LOOP get_group1_data_loop;
--
    -- 【商品区分】年間データの登録
    IF (lb_loop_end = TRUE) THEN
        -- 年間粗利益額
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        -- 年間_掛率【算出処理】:年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
        IF (ln_y_psa = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
--
        -- 更新処理
        UPDATE
                xxcsm_tmp_sales_plan_hon
        SET
               y_sales          = ln_y_sales     -- 年間売上
              ,y_amount         = ln_y_amount    -- 年間数量
              ,y_rate           = ln_y_rate      -- 年間掛率
              ,y_margin         = ln_y_margin    -- 年間粗利益額
        WHERE
               item_cd          = iv_group1_cd;  -- 商品区分コード
    END IF;
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
      IF (get_group1_data_cur%ISOPEN) THEN
        CLOSE get_group1_data_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_group1_data_cur%ISOPEN) THEN
        CLOSE get_group1_data_cur;
      END IF;
--
--
--#####################################  固定部 END   ###########################
--
  END deal_group1_data;
--
   /*****************************************************************************
   * Procedure Name   : deal_sum_data
   * Description      : 【商品合計】データの詳細処理
   ****************************************************************************/
  PROCEDURE deal_sum_data(
--  2018/11/14 V1.13 Added START
            it_summary_type   fnd_lookup_values.lookup_code%TYPE        --  合計区分
          , it_summary_name   fnd_lookup_values.description%TYPE        --  合計区分名
--  2018/11/14 V1.13 Added END
--  2018/11/14 V1.13 Modified START
--            ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
          , ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
--  2018/11/14 V1.13 Modified END
           ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
           ,ov_errmsg     OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_sum_data';      -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               --年間_粗利益額合計
    ln_y_amount             NUMBER  := 0;               --年間_数量合計
    ln_y_psa                NUMBER  := 0;               --年間_数量*定価の合計
    ln_y_bsa                NUMBER  := 0;               --年間_数量*原価の合計
    ln_y_rate               NUMBER  := 0;               --年間_掛率
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP判断用
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--============================================
--  データの抽出【商品合計】ローカル・カーソル
--============================================
--  2018/11/14 V1.13 Modified START
--                  
--    CURSOR   
--        get_sum_data_cur
--    IS
--      SELECT   
--             month_no                                   AS  month                     -- 月
--            ,SUM(NVL(m_amount,0))                       AS  amount                    -- 数量
--            ,SUM(NVL(m_sales,0))                        AS  sales                     -- 売上金額
--            ,SUM(NVL(t_price,0))                        AS  t_price                   -- 数量*定価
--            ,SUM(NVL(g_price,0))                        AS  g_price                   -- 数量*原価
--      FROM     
--            xxcsm_tmp_sales_plan_hon                      -- 商品計画リスト出力ワークテーブル
--      WHERE    
--            item_cd                                     IN ( 'A','C' )           -- 商品群(A+C)
--      GROUP BY
--            month_no                                                                  -- 月
--      ORDER BY 
--            month_no    ASC;
    CURSOR  get_sum_data_cur( it_summary_type IN  fnd_lookup_values.lookup_code%TYPE )
    IS
      SELECT  xtsph.month_no                            AS  "MONTH"           --  月
            , SUM( NVL( xtsph.m_amount,0 ) )            AS  "AMOUNT"          --  数量
            , SUM( NVL( xtsph.m_sales, 0 ) )            AS  "SALES"           --  売上金額
            , SUM( NVL( xtsph.t_price, 0 ) )            AS  "T_PRICE"         --  数量*定価
            , SUM( NVL( xtsph.g_price, 0 ) )            AS  "G_PRICE"         --  数量*原価
      FROM    xxcsm_tmp_sales_plan_hon     xtsph                     --  商品計画リスト出力ワークテーブル
            , fnd_lookup_values           flv                       --  参照表：商品計画リスト出力対象商品群
      WHERE   flv.lookup_type       =   cv_lookup_group
      AND     flv.language          =   USERENV( 'LANG' )
      AND     flv.enabled_flag      =   cv_flg_y
      AND     SYSDATE   >=  flv.start_date_active
      AND     SYSDATE   <=  NVL( flv.end_date_active, SYSDATE )
      AND     flv.attribute1        =   it_summary_type             --  合計区分ごとにサマリ
      AND     flv.lookup_code       =   xtsph.item_cd
      GROUP BY  xtsph.month_no
      ORDER BY  xtsph.month_no  ASC
      ;
--  2018/11/14 V1.13 Modified END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<get_sum_data_loop>>
    -- 【商品合計】データ取得
--  2018/11/14 V1.13 Modified START
--    FOR rec_sum IN get_sum_data_cur LOOP
    FOR rec_sum IN get_sum_data_cur( it_summary_type ) LOOP
--  2018/11/14 V1.13 Modified END
        lb_loop_end     := TRUE;
        -- =======================================
        -- 年間累計【加算】
        -- =======================================
--
        -- 年間売上
        ln_y_sales      := ln_y_sales + rec_sum.sales;
--
        -- 年間数量(CS)
        ln_y_amount     := ln_y_amount + rec_sum.amount ;
        ln_y_psa        := ln_y_psa + rec_sum.t_price;
        ln_y_bsa        := ln_y_bsa + rec_sum.g_price;
        -- 月間_掛率=月間_売上／（月間_数量*定価）*100
        IF (rec_sum.t_price = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(rec_sum.sales / rec_sum.t_price * 100,2);
        END IF;
        --===================================
        -- 【商品合計】月間データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_hon
          (
              toroku_no        --出力順
              ,group_cd_1      --商品群コード(1桁)
              ,group_nm_1      --商品群名称(1桁)
              ,group_cd_4      --商品群コード(4桁)
              ,group_nm_4      --商品群名称(4桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin        --月間_粗利益額
              ,t_price         -- 定価＊数量
              ,g_price         -- 原価＊数量
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,NULL
--  2018/11/14 V1.13 Modified START
--              ,lv_prf_cd_sum_val
              , it_summary_name
--  2018/11/14 V1.13 Modified END
              ,rec_sum.month
              ,rec_sum.sales
              ,rec_sum.amount
--              ,ROUND(rec_sum.sales / rec_sum.t_price * 100,2)
              ,ln_y_rate
              ,rec_sum.sales - rec_sum.g_price
              ,rec_sum.t_price
              ,rec_sum.g_price
          );
        -- 登録順の加算
        gn_index := gn_index + 1;
    END LOOP get_sum_data_loop;
    -- 【商品合計】年間データの登録
    IF (lb_loop_end = TRUE) THEN
        -- 年間粗利益額
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        -- 年間_掛率【算出処理】:年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
        IF (ln_y_psa = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
        -- 更新処理
        UPDATE
                xxcsm_tmp_sales_plan_hon
        SET
               y_sales          = ln_y_sales          -- 年間売上
              ,y_amount         = ln_y_amount         -- 年間数量
              ,y_rate           = ln_y_rate           -- 年間掛率
              ,y_margin         = ln_y_margin         -- 年間粗利益額
--  2018/11/14 V1.13 Modified START
--        WHERE
--               item_nm          = lv_prf_cd_sum_val;  -- 商品名称：商品合計
        WHERE   item_nm         =   it_summary_name
        ;
--  2018/11/14 V1.13 Modified END
    END IF;
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
      IF (get_sum_data_cur%ISOPEN) THEN
        CLOSE get_sum_data_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
--
      IF (get_sum_data_cur%ISOPEN) THEN
        CLOSE get_sum_data_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--  
  END deal_sum_data;
--
   /*****************************************************************************
   * Procedure Name   : deal_down_data (A-16~A-17)
   * Description      : 【売上値引・入金値引】データの詳細処理
   ****************************************************************************/
  PROCEDURE deal_down_data(
        iv_kyoten_cd    IN  VARCHAR2            -- 拠点コード
       ,ov_errbuf       OUT NOCOPY VARCHAR2     -- エラー・メッセージ
       ,ov_retcode      OUT NOCOPY VARCHAR2     -- リターン・コード
       ,ov_errmsg       OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_down_data';      -- プログラム名
    
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    ln_y_sales_d            NUMBER  := 0;               --年間_売上値引合計
    ln_y_sales_p            NUMBER  := 0;               --年間_入金値引合計
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP判断用
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--============================================
--  データの抽出【売上値引・入金値引】ローカル・カーソル
--============================================
--                  
    CURSOR   
        get_down_data_cur
    IS
      SELECT   
             xiplb.month_no                                AS  month                     -- 月
            ,SUM(NVL(xiplb.sales_discount,0))              AS  sales_d                   -- 売上値引
            ,SUM(NVL(xiplb.receipt_discount,0))            AS  receipt_d                 -- 入金値引
      FROM     
            xxcsm_item_plan_loc_bdgt                       xiplb             -- 商品計画拠点別予算テーブル   
           ,xxcsm_item_plan_headers                        xiph              -- 商品計画ヘッダテーブル
      WHERE    
            xiplb.item_plan_header_id                        = xiph.item_plan_header_id    -- 商品計画ヘッダID
      AND   xiph.plan_year                                   = gn_taisyoym                 -- 対象年度
      AND   xiph.location_cd                                 = iv_kyoten_cd                -- 拠点コード
      AND   EXISTS (
                    SELECT   
                         'X'
                    FROM     
                         xxcsm_item_plan_lines               xipl                            -- 商品計画明細テーブル
                    WHERE                           
                        xipl.item_plan_header_id             = xiplb.item_plan_header_id     -- 商品計画ヘッダID
                    AND xipl.item_kbn                         <> '0'                         -- 商品区分
                   )
      GROUP BY
            month_no                                        -- 月
      ORDER BY 
            month_no    ASC;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<get_down_data_loop>>
    -- 【売上値引・入金値引】データ取得
    FOR rec_down IN get_down_data_cur LOOP
        lb_loop_end     := TRUE;
        -- =======================================
        -- 年間累計【加算】
        -- =======================================
        -- 年間_売上値引
        ln_y_sales_d      := ln_y_sales_d + rec_down.sales_d;
        -- 年間_入金値引
        ln_y_sales_p     := ln_y_sales_p + rec_down.receipt_d;
--
        --===================================
        -- 【売上値引】月間データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_hon
          (
              toroku_no        --出力順
              ,group_cd_1      --商品群コード(1桁)
              ,group_nm_1      --商品群名称(1桁)
              ,group_cd_4      --商品群コード(4桁)
              ,group_nm_4      --商品群名称(4桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin        --月間_粗利益額
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,'N'
              ,lv_prf_cd_down_sales_val
              ,rec_down.month
              ,rec_down.sales_d
              ,0
              ,0
              ,rec_down.sales_d
          );
        -- 登録順の加算
        gn_index := gn_index + 1;
--
        --===================================
        -- 【入金値引】月間データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_hon
          (
              toroku_no        --出力順
              ,group_cd_1      --商品群コード(1桁)
              ,group_nm_1      --商品群名称(1桁)
              ,group_cd_4      --商品群コード(4桁)
              ,group_nm_4      --商品群名称(4桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin        --月間_粗利益額
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,'N'
              ,lv_prf_cd_down_pay_val
              ,rec_down.month
              ,rec_down.receipt_d
              ,0
              ,0
              ,rec_down.receipt_d
          );
        -- 登録順の加算
        gn_index := gn_index + 1;
    END LOOP get_down_data_loop;
    -- 年間データの登録
    IF (lb_loop_end = TRUE) THEN
--
        -- 年間_売上値引
        UPDATE
                xxcsm_tmp_sales_plan_hon
        SET
               y_sales          = ln_y_sales_d                                -- 年間売上
              ,y_margin         = ln_y_sales_d                                -- 年間粗利益額
        WHERE
               item_nm          = lv_prf_cd_down_sales_val;                   -- 商品名称：売上値引
        -- 年間_入金値引
        UPDATE
                xxcsm_tmp_sales_plan_hon
        SET
--//+UPD START 2009/02/23 CT054 K.Sai
--               y_sales          = ln_y_sales_d                                -- 年間売上
--              ,y_margin         = ln_y_sales_d                                -- 年間粗利益額
               y_sales          = ln_y_sales_p                                -- 年間売上
              ,y_margin         = ln_y_sales_p                                -- 年間粗利益額              
--//+UPD END 2009/02/23 CT054 K.Sai
        WHERE
               item_nm          = lv_prf_cd_down_pay_val;                     -- 商品名称：入金値引
    END IF;
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
      IF (get_down_data_cur%ISOPEN) THEN
        CLOSE get_down_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
--
      IF (get_down_data_cur%ISOPEN) THEN
        CLOSE get_down_data_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--  
  END deal_down_data;
--  
   /*****************************************************************************
   * Procedure Name   : deal_kyoten_data (A-18~A-20)
   * Description      : 【拠点計】データの詳細処理
   ****************************************************************************/
  PROCEDURE deal_kyoten_data(
            ov_errbuf     OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
           ,ov_retcode    OUT NOCOPY VARCHAR2                                   -- リターン・コード
           ,ov_errmsg     OUT NOCOPY VARCHAR2)                                  -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_kyoten_data';      -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    ln_y_sales              NUMBER  := 0;               --年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               --年間_粗利益額合計
    ln_y_amount             NUMBER  := 0;               --年間_数量合計
    ln_y_rate               NUMBER  := 0;               --年間_掛率
    ln_y_bsa                NUMBER  := 0;               --年間_数量*原価の合計
    ln_y_psa                NUMBER  := 0;               --年間_数量*定価の合計
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP判断用
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--============================================
--  データの抽出【拠点計】ローカル・カーソル
--============================================
--                  
    CURSOR   
        get_kyoten_data_cur
    IS
      SELECT   
             month_no                                   AS  month                     -- 月
            ,SUM(NVL(m_amount,0))                       AS  amount                    -- 数量
            ,SUM(NVL(m_sales,0))                        AS  sales                     -- 売上金額
            ,SUM(NVL(t_price,0))                        AS  t_price                   -- 数量*定価
            ,SUM(NVL(g_price,0))                        AS  g_price                   -- 数量*原価
--  2018/11/14 V1.13 Modified START
--      FROM     
--            xxcsm_tmp_sales_plan_hon                      -- 商品計画リスト出力ワークテーブル
--      WHERE    
--            item_cd                                     IN ( 'A','C','D','N' )        -- 商品群(A+C+D+N)
--      GROUP BY
--            month_no                                                                  -- 月
--      ORDER BY 
--            month_no    ASC;
      FROM    xxcsm_tmp_sales_plan_hon     xtsph             --  商品計画リスト出力ワークテーブル
            , fnd_lookup_values           flv               --  参照表：商品計画リスト出力対象商品群
      WHERE   flv.lookup_type       =   cv_lookup_group
      AND     flv.language          =   USERENV( 'LANG' )
      AND     flv.enabled_flag      =   cv_flg_y
      AND     SYSDATE   >=  flv.start_date_active
      AND     SYSDATE   <=  NVL( flv.end_date_active, SYSDATE )
      AND     flv.lookup_code       =   xtsph.item_cd
      GROUP BY  xtsph.month_no
      ORDER BY  xtsph.month_no
      ;
--  2018/11/14 V1.13 Modified END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<get_kyoten_data_loop>>
    -- 【拠点計】データ取得
    FOR rec_kyoten IN get_kyoten_data_cur LOOP
        lb_loop_end     := TRUE;
        -- =======================================
        -- 年間累計【加算】
        -- =======================================
        -- 年間売上
        ln_y_sales      := ln_y_sales + rec_kyoten.sales;
        -- 年間数量
        ln_y_amount     := ln_y_amount + rec_kyoten.amount;
        ln_y_psa        := ln_y_psa + rec_kyoten.t_price;
        ln_y_bsa        := ln_y_bsa + rec_kyoten.g_price;
        -- 月間_掛率=月間_売上／（月間_数量*定価）*100
        IF (rec_kyoten.t_price = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(rec_kyoten.sales / rec_kyoten.t_price * 100,2);
        END IF;
--
        --===================================
        -- 【拠点計】月間データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_hon
          (
              toroku_no        --出力順
              ,group_cd_1      --商品群コード(1桁)
              ,group_nm_1      --商品群名称(1桁)
              ,group_cd_4      --商品群コード(4桁)
              ,group_nm_4      --商品群名称(4桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin        --月間_粗利益額
          )
          VALUES (
               gn_index
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,NULL
              ,lv_prf_cd_p_sum_val
              ,rec_kyoten.month
              ,rec_kyoten.sales
              ,rec_kyoten.amount 
--              ,ROUND(rec_kyoten.sales / rec_kyoten.t_price * 100,2)
              ,ln_y_rate
              ,rec_kyoten.sales - rec_kyoten.g_price
          );
        -- 登録順の加算
        gn_index := gn_index + 1;
    END LOOP get_kyoten_data_loop;
--
    -- 【拠点計】年間データの登録
    IF (lb_loop_end = TRUE) THEN
        -- 年間粗利益額
        ln_y_margin     := ln_y_sales - ln_y_bsa;
--
        -- 年間_掛率【算出処理】:年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
        IF (ln_y_psa = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
--
        UPDATE
                xxcsm_tmp_sales_plan_hon
        SET
               y_sales          = ln_y_sales             -- 年間売上
              ,y_amount         = ln_y_amount            -- 年間数量
              ,y_rate           = ln_y_rate              -- 年間掛率
              ,y_margin         = ln_y_margin            -- 年間粗利益額
        WHERE
               item_nm          = lv_prf_cd_p_sum_val;   -- 商品名称：拠点計
    END IF;
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
      IF (get_kyoten_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_data_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
--
      IF (get_kyoten_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_data_cur;
      END IF;  
--
--#####################################  固定部 END   ###########################
-- 
  END deal_kyoten_data;
--  
   /****************************************************************************
   * Procedure Name   : deal_item_data
   * Description      : 【商品】データの詳細処理
   *****************************************************************************/
   PROCEDURE deal_item_data(
         iv_kyoten_cd      IN  VARCHAR2                      --拠点コード
        ,ov_errbuf         OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode        OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg         OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_item_data';        -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_item_cd              VARCHAR2(10);               -- 品目コード
    lv_group_cd_1           VARCHAR2(10);               -- 商品群コード(1桁)
    lv_group_cd_4           VARCHAR2(10);               -- 商品群コード(4桁)
    ln_y_sales              NUMBER  := 0;               -- 年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               -- 年間_粗利益額合計
    ln_y_amount             NUMBER  := 0;               -- 年間_数量合計
    ln_y_psa                NUMBER  := 0;               -- 年間_数量*定価の合計
    ln_y_bsa                NUMBER  := 0;               -- 年間_数量*原価の合計
    ln_y_rate               NUMBER  := 0;               -- 年間_掛率
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP判断用
--//+DEL START 2009/05/27 T1_1199 M.Ohtsuki
--    lv_month_no             VARCHAR2(10);               -- 月
--//+DEL END   2009/05/27 T1_1199 M.Ohtsuki
--
-- ===============================
-- ユーザｰローカル例外
-- ===============================
   data_not_exists_skip_expt EXCEPTION;   -- スキップ処理例外
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--//+UPD START E_本稼動_09949 K.Taniguchi
--// SELECT句でCASE式を使用⇒GROUP BY句での2重の記述をさけるため
--// FROM句でのインラインビュー化を行います。
--// またヒント句がない方が良い実行計画となるためヒント句は削除します。
----============================================
----  データの抽出【商品】カーソル
----============================================
--    CURSOR   
--        get_item_data_cur(
--                          iv_kyoten_cd      IN VARCHAR2                         -- 拠点コード
--                          )
--    IS
---- == 2010/03/24 V1.9 Modified START ===============================================================
----      SELECT   
--      SELECT /*+ LEADING(xiph xipl) */
---- == 2010/03/24 V1.9 Modified END   ===============================================================
--             xipl.month_no                          AS  month                    -- 月
--            ,SUM(NVL(xipl.amount,0))                AS  amount                   -- 数量
--            ,SUM(NVL(xipl.sales_budget,0))          AS  sales                    -- 売上金額
--            ,SUM(NVL(xipl.amount_gross_margin,0))   AS  margin                   -- 粗利益額
--            ,xcgv.group1_cd                         AS  group_cd_1               -- 商品群1桁コード
--            ,xcgv.group1_nm                         AS  group_nm_1               -- 商品群1桁名称
--            ,xcgv.group4_cd                         AS  group_cd_4               -- 商品群4桁コード
--            ,xcgv.group4_nm                         AS  group_nm_4               -- 商品群4桁名称
--            ,xcgv.item_cd                           AS  item_id                  -- 品目コード
--            ,xcgv.item_nm                           AS  item_nm                  -- 品目名称
--            ,DECODE(gv_genkacd
--                 ,cn_base_price,xcgv.now_item_cost
--                 ,cn_bus_price,xcgv.now_business_cost
--                 ,0)                                AS  base_price               -- 10:標準原価 20:営業原価
--            ,NVL(xcgv.now_unit_price,0)             AS  con_price                -- 定価
--      FROM     
--            xxcsm_item_plan_lines                   xipl                         -- 商品計画明細テーブル
--            ,xxcsm_item_plan_headers                xiph                         -- 商品計画ヘッダテーブル
--            ,xxcsm_commodity_group4_v               xcgv                         -- 政策群４ビュー
--      WHERE    
--             xipl.item_plan_header_id                = xiph.item_plan_header_id   -- 商品計画ヘッダID
--      AND   xcgv.item_cd                             = xipl.item_no               -- 商品コード
--      AND   xiph.plan_year                           = gn_taisyoym               -- 対象年度
--      AND   xiph.location_cd                         = iv_kyoten_cd              -- 拠点コード
--      AND   xipl.item_kbn                            <> '0'                      -- 商品区分(商品群以外)
---- START  DELETE  DATE:2010/12/20  AUTHOR:OUKOU  CONTENT:E_本稼動_05803
----      AND   xcgv.unit_of_issue                       = lv_prf_cd_unit_hon_val    -- 単位(本)
---- END    DELETE  DATE:2010/12/20  AUTHOR:OUKOU  CONTENT:E_本稼動_05803
--      GROUP BY
--               xipl.month_no                       -- 月
--              ,xcgv.group1_cd                      -- 商品群1桁コード
--              ,xcgv.group1_nm                      -- 商品群1桁名称
--              ,xcgv.group4_cd                      -- 商品群4桁コード
--              ,xcgv.group4_nm                      -- 商品群4桁名称
--              ,xcgv.item_cd                        -- 商品コード
--              ,xcgv.item_nm                        -- 商品名称
--              ,xcgv.now_unit_price                 -- 定価
--              ,xcgv.now_item_cost                  -- 標準原価
--              ,xcgv.now_business_cost              -- 標準原価
--      ORDER BY 
--                 group_cd_1         ASC            -- 商品群1桁コード
--                ,group_cd_4         ASC            -- 商品群4桁コード
--                ,item_cd            ASC            -- 商品コード
--    ;
--
--============================================
--  データの抽出【商品】カーソル
--============================================
    CURSOR   
        get_item_data_cur(
                          iv_kyoten_cd      IN VARCHAR2                         -- 拠点コード
                          )
    IS
      SELECT
             sub.month_no                           AS  month                    -- 月
            ,SUM(NVL(sub.amount,0))                 AS  amount                   -- 数量
            ,SUM(NVL(sub.sales_budget,0))           AS  sales                    -- 売上金額
            ,SUM(NVL(sub.amount_gross_margin,0))    AS  margin                   -- 粗利益額
            ,sub.group1_cd                          AS  group_cd_1               -- 商品群1桁コード
            ,sub.group1_nm                          AS  group_nm_1               -- 商品群1桁名称
            ,sub.group4_cd                          AS  group_cd_4               -- 商品群4桁コード
            ,sub.group4_nm                          AS  group_nm_4               -- 商品群4桁名称
            ,sub.item_cd                            AS  item_id                  -- 品目コード
            ,sub.item_nm                            AS  item_nm                  -- 品目名称
            ,DECODE(gv_genkacd
                 ,cn_base_price,sub.now_item_cost
                 ,cn_bus_price, sub.now_business_cost
                 ,0)                                AS  base_price               -- 10:標準原価 20:営業原価
            ,NVL(sub.now_unit_price,0)              AS  con_price                -- 定価
      FROM
      (
          SELECT
                 xipl.month_no                          AS  month_no                 -- 月
                ,xipl.amount                            AS  amount                   -- 数量
                ,xipl.sales_budget                      AS  sales_budget             -- 売上金額
                ,xipl.amount_gross_margin               AS  amount_gross_margin      -- 粗利益額
                ,xcgv.group1_cd                         AS  group1_cd                -- 商品群1桁コード
                ,xcgv.group1_nm                         AS  group1_nm                -- 商品群1桁名称
                ,xcgv.group4_cd                         AS  group4_cd                -- 商品群4桁コード
                ,xcgv.group4_nm                         AS  group4_nm                -- 商品群4桁名称
                ,xcgv.item_cd                           AS  item_cd                  -- 品目コード
                ,xcgv.item_nm                           AS  item_nm                  -- 品目名称
                 --
                 -- 標準原価
                 -- パラメータ：新旧原価区分
                ,CASE gv_new_old_cost_class
                   --
                   -- 10：新原価 選択時
                   WHEN cv_new_cost THEN
                     NVL(xcgv.now_item_cost, 0)
                   --
                   -- 20：旧原価 選択時
                   WHEN cv_old_cost THEN
                     NVL(
                           (
                             -- 標準原価マスタより前年度の標準原価を取得
                             SELECT SUM(ccmd.cmpnt_cost) AS cmpnt_cost                    -- 標準原価
                             FROM   cm_cmpt_dtl     ccmd                                  -- OPM標準原価マスタ
                                   ,cm_cldr_dtl     ccld                                  -- 原価カレンダ明細
                             WHERE  ccmd.calendar_code = ccld.calendar_code               -- 原価カレンダコード
                             AND    ccmd.period_code   = ccld.period_code                 -- 期間コード
                             AND    ccmd.item_id       = xcgv.opm_item_id                 -- 品目ID
                             AND    ccmd.whse_code     = cv_whse_code                     -- 原価倉庫
                             AND    ccld.start_date   <= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                             AND    ccld.end_date     >= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                           )
                       , 0
                     )
                 END                                    AS  now_item_cost            -- 標準原価
                 --
                 -- 営業原価
                 -- パラメータ：新旧原価区分
                ,CASE gv_new_old_cost_class
                   --
                   -- 10：新原価 選択時
                   WHEN cv_new_cost THEN
                     NVL(xcgv.now_business_cost, 0)
                   --
                   -- 20：旧原価 選択時
                   WHEN cv_old_cost THEN
                     NVL(
                           (
                             -- 前年度の営業原価を品目変更履歴から取得
                             SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- 営業原価
                             FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                             WHERE   xsibh.item_hst_id   =
                               (
                                 -- 前年度の品目変更履歴ID
                                 SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                 FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                 WHERE   xsibh2.item_code      =  xcgv.item_cd         -- 品目コード
                                 AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                 AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                 AND     xsibh2.discrete_cost  IS NOT NULL             -- 営業原価 IS NOT NULL
                               )
                           )
                       , 0
                     )
                 END                                    AS  now_business_cost        --営業原価
                 --
                 -- 定価
                 -- パラメータ：新旧原価区分
                ,CASE gv_new_old_cost_class
                   --
                   -- 10：新原価 選択時
                   WHEN cv_new_cost THEN
                     NVL(xcgv.now_unit_price, 0)
                   --
                   -- 20：旧原価 選択時
                   WHEN cv_old_cost THEN
                     NVL(
                           (
                             -- 前年度の定価を品目変更履歴から取得
                             SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- 定価
                             FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                             WHERE   xsibh.item_hst_id   =
                               (
                                 -- 前年度の品目変更履歴ID
                                 SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                                 FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                                 WHERE   xsibh2.item_code      =  xcgv.item_cd         -- 品目コード
                                 AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                                 AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                                 AND     xsibh2.fixed_price    IS NOT NULL             -- 定価 IS NOT NULL
                               )
                           )
                       , 0
                     )
                 END                                    AS  now_unit_price           -- 定価
          FROM
                 xxcsm_item_plan_lines                  xipl                         -- 商品計画明細テーブル
                ,xxcsm_item_plan_headers                xiph                         -- 商品計画ヘッダテーブル
                ,xxcsm_commodity_group4_v               xcgv                         -- 政策群４ビュー
          WHERE
                 xipl.item_plan_header_id               = xiph.item_plan_header_id   -- 商品計画ヘッダID
          AND    xcgv.item_cd                           = xipl.item_no               -- 商品コード
          AND    xiph.plan_year                         = gn_taisyoym                -- 対象年度
          AND    xiph.location_cd                       = iv_kyoten_cd               -- 拠点コード
          AND    xipl.item_kbn                          <> '0'                       -- 商品区分(商品群以外)
      ) sub
      GROUP BY
               sub.month_no                         -- 月
              ,sub.group1_cd                        -- 商品群1桁コード
              ,sub.group1_nm                        -- 商品群1桁名称
              ,sub.group4_cd                        -- 商品群4桁コード
              ,sub.group4_nm                        -- 商品群4桁名称
              ,sub.item_cd                          -- 商品コード
              ,sub.item_nm                          -- 商品名称
              ,sub.now_unit_price                   -- 定価
              ,sub.now_item_cost                    -- 標準原価
              ,sub.now_business_cost                -- 標準原価
      ORDER BY 
               group_cd_1         ASC               -- 商品群1桁コード
              ,group_cd_4         ASC               -- 商品群4桁コード
              ,item_cd            ASC               -- 商品コード
    ;
--//+UPD END E_本稼動_09949 K.Taniguchi
--
--============================================
--  商品群コードの抽出・カーソル
--============================================
    CURSOR   
        get_group4_code_cur
    IS
      SELECT  
        group_cd_4      AS group_cd4
      FROM
        xxcsm_tmp_sales_plan_hon
      GROUP BY group_cd_4;
--
--============================================
--  商品区分コードの抽出・カーソル
--============================================
    CURSOR   
        get_group1_code_cur
    IS
      SELECT  
        group_cd_1      AS group_cd1
      FROM
        xxcsm_tmp_sales_plan_hon
      GROUP BY group_cd_1;
--
--  2018/11/14 V1.13 Added START
    --  ======================================
    --    合計区分の抽出・カーソル
    --  ======================================
    CURSOR  cur_summary_type
    IS
      SELECT    flv.lookup_code       summary_type
              , flv.description       summary_name
      FROM      fnd_lookup_values     flv                           --  参照表：商品計画リスト合計区分
      WHERE     flv.lookup_type       =   cv_lookup_summary
      AND       flv.language          =   USERENV( 'LANG' )
      AND       flv.enabled_flag      =   cv_flg_y
      AND       SYSDATE   >=  flv.start_date_active
      AND       SYSDATE   <=  NVL( flv.end_date_active, SYSDATE )
      AND       flv.lookup_code       <>  cv_summary_type_99        --  その他合計は除く
    ;
    get_summary_type      cur_summary_type%ROWTYPE;
--  2018/11/14 V1.13 Added END
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- データの処理【商品】
    -- =======================================
    <<get_item_data_cur_loop>>
    FOR rec_item_data IN get_item_data_cur(iv_kyoten_cd) LOOP
        BEGIN
            -- ======================================================
            -- 売上が0の場合【スキップ処理】
            -- ======================================================
--//+DEL START 2009/05/27 T1_1199 M.Ohtsuki
/*
            IF (rec_item_data.sales = 0) THEN
                -- 商品コード
                lv_item_cd      := rec_item_data.item_id;
                -- 月
                lv_month_no     := rec_item_data.month;
                -- 次のデータに移動します
                RAISE global_skip_expt;
            END IF;
*/
--//+DEL END   2009/05/27 T1_1199 M.Ohtsuki
--
            IF (lb_loop_end = FALSE) THEN
                lb_loop_end := TRUE;
                -- 商品コード
                lv_item_cd      := rec_item_data.item_id;
                -- 年間_売上
                ln_y_sales      := 0;
                -- 年間_数量
                ln_y_amount     := 0;
                -- 年間_数量*定価
                ln_y_psa        := 0;
                -- 年間_数量*原価
                ln_y_bsa        := 0;
                -- 年間_粗利益額
                ln_y_margin     := 0;
            END IF;
--
            -- ==================================
            -- 【商品単位】集計
            -- ==================================
            IF (lv_item_cd <> rec_item_data.item_id ) THEN
              -- 年間_掛率【算出処理】:年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
              IF (ln_y_psa = 0) THEN
                ln_y_rate     := 0;
              ELSE
                ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
              END IF;
              -- 年間_粗利益額
              ln_y_margin     := ln_y_sales - ln_y_bsa;
              -- ==================================
              -- 算出した合計値をワークテーブルへ登録
              -- ==================================
              UPDATE
                      xxcsm_tmp_sales_plan_hon
              SET
                     y_sales          = ln_y_sales    -- 年間売上
                    ,y_amount         = ln_y_amount   -- 年間数量
                    ,y_rate           = ln_y_rate     -- 年間掛率
                    ,y_margin         = ln_y_margin   -- 年間粗利益額
              WHERE
                      item_cd         = lv_item_cd;   -- 商品コード
--
--//+ADD START 2009/05/27 T1_1199 M.Ohtsuki
-- MODIFY  START  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--              IF (rec_item_data.sales = 0) THEN
              IF rec_item_data.sales = 0 AND rec_item_data.amount = 0 THEN
-- MODIFY  END  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
                -- 商品コード
                lv_item_cd      := rec_item_data.item_id;
                -- 年間データ変数の初期化
                ln_y_sales      := 0;
                ln_y_amount     := 0;
                ln_y_psa        := 0;
                ln_y_bsa        := 0;
                ln_y_margin     := 0;
--
                RAISE global_skip_expt;
              END IF;
--//+ADD END   2009/05/27 T1_1199 M.Ohtsuki
              -- ===================================
              -- 次の商品の場合、再設定
              -- ===================================
              -- 商品コード
              lv_item_cd      := rec_item_data.item_id;
              -- 年間_売上
              ln_y_sales      := rec_item_data.sales;
              -- 年間_数量
              ln_y_amount     := rec_item_data.amount;
              -- 年間_数量*定価
              ln_y_psa        := rec_item_data.amount * rec_item_data.con_price;
              -- 年間_数量*原価
              ln_y_bsa        := rec_item_data.amount * rec_item_data.base_price;
            ELSE
--//+ADD START 2009/05/27 T1_1199 M.Ohtsuki
-- MODIFY  START  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--              IF (rec_item_data.sales = 0) THEN
              IF rec_item_data.sales = 0 AND rec_item_data.amount = 0 THEN
-- MODIFY  END  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
                  -- 商品コード
                  lv_item_cd      := rec_item_data.item_id;
                  RAISE global_skip_expt;
              END IF;
--//+ADD END   2009/05/27 T1_1199 M.Ohtsuki
                -- ===================================
                -- 【同一商品】年間累計を加算する
                -- ===================================
                -- 年間売上
                ln_y_sales      := ln_y_sales + rec_item_data.sales;
                -- 年間数量
                ln_y_amount     := ln_y_amount + rec_item_data.amount;
                -- 年間数量*定価
                ln_y_psa        := ln_y_psa + rec_item_data.amount * rec_item_data.con_price;
                -- 年間_数量*原価
                ln_y_bsa        := ln_y_bsa + rec_item_data.amount * rec_item_data.base_price;
                
            END IF;
            -- 月間_掛率=月間_売上／（月間_数量*定価）*100
            IF ((rec_item_data.amount * rec_item_data.con_price) = 0) THEN
              ln_y_rate     := 0;
            ELSE
              ln_y_rate     := ROUND(rec_item_data.sales / (rec_item_data.amount * rec_item_data.con_price) * 100,2);
            END IF;
            -- ===================================
            -- 【商品単位】月間データの登録
            -- ===================================
            INSERT INTO xxcsm_tmp_sales_plan_hon
              (
                  toroku_no        --出力順
                  ,group_cd_1      --商品群コード(1桁)
                  ,group_nm_1      --商品群名称(1桁)
                  ,group_cd_4      --商品群コード(4桁)
                  ,group_nm_4      --商品群名称(4桁)
                  ,item_cd         --商品コード
                  ,item_nm         --商品名称
                  ,month_no        --月
                  ,m_sales         --月間_売上
                  ,m_amount        --月間_数量=数量/入数
                  ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
                  ,m_margin        --月間_粗利益額
                  ,t_price         -- 数量*定価
                  ,g_price         -- 数量*原価
              )
              VALUES (
                   gn_index
                  ,rec_item_data.group_cd_1
                  ,rec_item_data.group_nm_1
                  ,rec_item_data.group_cd_4
                  ,rec_item_data.group_nm_4
                  ,rec_item_data.item_id
                  ,rec_item_data.item_nm
                  ,rec_item_data.month
                  ,rec_item_data.sales
                  ,rec_item_data.amount
--                  ,ROUND(rec_item_data.sales / (rec_item_data.amount * rec_item_data.con_price) * 100,2)
                  ,ln_y_rate
                  ,rec_item_data.sales - rec_item_data.amount * rec_item_data.base_price
                  ,rec_item_data.amount * rec_item_data.con_price
                  ,rec_item_data.amount * rec_item_data.base_price
              );
              -- 登録順【加算】
              gn_index := gn_index + 1;
        --
        --#################################  スキップ  START #############################
        --
        EXCEPTION
            WHEN global_skip_expt THEN
--
--//+UPD START 2009/02/23 CT029 S.Son
/*
                -- 対象件数を加算します
                gn_target_cnt := gn_target_cnt + 1 ;
                -- スキップ件数を加算します
                gn_warn_cnt := gn_warn_cnt + 1 ;
*/
                NULL;
--//+UPD END 2009/02/23 CT029 S.Son
        --
        --#################################  スキップ  END #############################
        --
        END;
    END LOOP get_item_data_cur_loop;
--
    -- 該当するデータが存在しない場合、データ無しメッセージを出力し、スキップ処理を行う
    IF (lb_loop_end = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                              -- アプリケーション短縮名
                      ,iv_name         => cv_csm1_msg_00099                     -- メッセージコード
                      ,iv_token_name1  => cv_tkn_year                           -- トークンコード1（対象年度）
                      ,iv_token_value1 => gn_taisyoym                           -- トークン値1
                      ,iv_token_name2  => cv_tkn_kyotencd                       -- トークンコード2（拠点コード）
                      ,iv_token_value2 => iv_kyoten_cd                          -- トークン値2
                    );
      lv_errbuf := lv_errmsg;
      RAISE data_not_exists_skip_expt;
    END IF;
--
    -- 最後のレコード
    IF (lb_loop_end = TRUE) THEN
        -- ================================================
        -- 【★商品単位★】
        -- ================================================
        -- 年間_掛率【算出処理】:年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
        IF (ln_y_psa = 0) THEN
          ln_y_rate     := 0;
        ELSE
          ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
        END IF;
        -- 年間_粗利益額
        ln_y_margin     := ln_y_sales - ln_y_bsa;
        --==================================
        -- 算出した合計値をワークテーブルへ登録
        --==================================
--
        UPDATE
                xxcsm_tmp_sales_plan_hon
        SET
               y_sales          = ln_y_sales      -- 年間売上
              ,y_amount         = ln_y_amount     -- 年間数量
              ,y_rate           = ln_y_rate       -- 年間掛率
              ,y_margin         = ln_y_margin     -- 年間粗利益額
        WHERE
                item_cd         = lv_item_cd;     -- 商品コード
--
        -- ================================================
        -- 【★★商品群単位★★】
        -- ================================================
        <<get_group4_data>>
        FOR rec_group4 IN get_group4_code_cur LOOP
            lv_group_cd_4:= rec_group4.group_cd4;
            deal_group4_data(
                       lv_group_cd_4                  -- 商品群コード（4桁）
                      ,lv_errbuf                      -- エラー・メッセージ
                      ,lv_retcode                     -- リターン・コード
                      ,lv_errmsg                      -- ユーザー・エラー・メッセージ
                      );
            IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
              RAISE global_process_expt;
            END IF;
        END LOOP get_group4_data;
--        
        -- ================================================
        -- 【★★★商品区分単位★★★】
        -- ================================================
        <<get_group1_data>>
        FOR rec_group1 IN get_group1_code_cur LOOP
            lv_group_cd_1:= rec_group1.group_cd1;
--
            deal_group1_data(
                       lv_group_cd_1                  -- 商品群コード（1桁）
                      ,lv_errbuf                      -- エラー・メッセージ
                      ,lv_retcode                     -- リターン・コード
                      ,lv_errmsg                      -- ユーザー・エラー・メッセージ
                      );
            IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
              RAISE global_process_expt;
            END IF;
        END LOOP get_group1_data;
--
--  2018/11/14 V1.13 Modified START
--        -- ================================================
--        -- 【★★★★商品合計★★★★】
--        -- ================================================
--        deal_sum_data(
--                   lv_errbuf                      -- エラー・メッセージ
--                  ,lv_retcode                     -- リターン・コード
--                  ,lv_errmsg                      -- ユーザー・エラー・メッセージ
--                  );
--        IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
--          RAISE global_process_expt;
--        END IF;
--        
        FOR rec_summary_type IN cur_summary_type LOOP
          --  ==========================================
          --    その他合計以外の合計行作成
          --  ==========================================
          deal_sum_data(
              it_summary_type       =>  rec_summary_type.summary_type     --  合計区分
            , it_summary_name       =>  rec_summary_type.summary_name     --  合計区分名
            , ov_errbuf             =>  lv_errbuf                         --  エラー・メッセージ
            , ov_retcode            =>  lv_retcode                        --  リターン・コード
            , ov_errmsg             =>  lv_errmsg                         --  ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP;
--  2018/11/14 V1.13 Modified END
    END IF;
--
    -- ================================================
    -- 【★★★★★売上値引／入金値引★★★★★】
    -- ================================================
    deal_down_data(
               iv_kyoten_cd                   -- 拠点コード（1桁）
              ,lv_errbuf                      -- エラー・メッセージ
              ,lv_retcode                     -- リターン・コード
              ,lv_errmsg                      -- ユーザー・エラー・メッセージ
              );
    IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
    -- ================================================
    -- 【★★★★★★拠点計★★★★★★】
    -- ================================================
    deal_kyoten_data(
               lv_errbuf                      -- エラー・メッセージ
              ,lv_retcode                     -- リターン・コード
              ,lv_errmsg                      -- ユーザー・エラー・メッセージ
              );
    IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
--
-- ===========================================================================  
--【データ処理-END(商品単位)】
-- ===========================================================================
--
  EXCEPTION
    -- *** 年間商品計画データが存在しない場合 ***
    WHEN data_not_exists_skip_expt THEN
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
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;
--
      IF (get_group4_code_cur%ISOPEN) THEN
        CLOSE get_group4_code_cur;
      END IF;
      
      IF (get_group1_code_cur%ISOPEN) THEN
        CLOSE get_group1_code_cur;
      END IF;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
--
      IF (get_item_data_cur%ISOPEN) THEN
        CLOSE get_item_data_cur;
      END IF;
--
      IF (get_group4_code_cur%ISOPEN) THEN
        CLOSE get_group4_code_cur;
      END IF;
--
      IF (get_group1_code_cur%ISOPEN) THEN
        CLOSE get_group1_code_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END deal_item_data;
--
   /*****************************************************************************
   * Procedure Name   : get_col_data (A-21)
   * Description      : 各項目のデータを取得【数量・売上・掛率・粗利益額】
   ****************************************************************************/
  PROCEDURE get_col_data(
        iv_parament    IN  VARCHAR2                 -- 設定可能値：【A,C,D,商品合計,売上値引,入金値引,拠点計】
       ,in_kind        IN  NUMBER                   -- 処理区分:【0:商品・商品群・商品区分 1:商品合計・売上値引・入金値引・拠点計】
       ,iv_head        IN  VARCHAR2                 -- 設定可能値：【コード|名称】或いは【空白|名称】
       ,iv_first       IN  BOOLEAN                  -- 設定可能値：【TRUE:拠点コードを含め行目 FALSE:普通の行目】
       ,ov_errbuf      OUT NOCOPY VARCHAR2          -- エラー・メッセージ
       ,ov_retcode     OUT NOCOPY VARCHAR2          -- リターン・コード
       ,ov_errmsg      OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ
       ,ov_col_data    OUT NOCOPY VARCHAR2)         --処理結果
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)  := 'get_col_data';        -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    in_param        NUMBER :=0 ;
    lv_item_col     VARCHAR2(100);
    lb_loop_end     BOOLEAN := FALSE;
    lv_col_data     VARCHAR2(6000);
-- ==========================================================
-- 月計【カーソル】
-- ==========================================================
    CURSOR get_month_data_cur0(
                         in_item_param      IN NUMBER       -- 処理項目区分【0:数量1:売上2:粗利益額3:掛率】
                        ,iv_param           IN VARCHAR2     -- 変数【設定可能値：A,C,D】
                        )
    IS 
      SELECT
             DECODE(in_item_param
                       ,0,NVL(SUM(DECODE(month_no,5,m_amount,0)  ),0) || cv_msg_comma              -- 数量【月】
                          || NVL(SUM(DECODE(month_no,6,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,m_amount,0)  ),0) || cv_msg_comma
--//+UPD START 2009/02/23 CT042 S.Son
/*
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma               -- 売上【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma              -- 粗利益額【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
*/
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit) || cv_msg_comma               -- 売上【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit) || cv_msg_comma              -- 粗利益額【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
--//+UPD END 2009/02/23 CT042 S.Son
                       ,3,NVL(SUM(DECODE(month_no,5,m_rate,0)  ),0) || cv_msg_comma                -- 掛率【月】
                          || NVL(SUM(DECODE(month_no,6,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,m_rate,0)  ),0) || cv_msg_comma
                       ,NULL) AS month_data
      FROM  
            xxcsm_tmp_sales_plan_hon       -- 商品計画リスト_本単位ワークテーブル
      WHERE
            item_cd  = iv_param          -- 商品・商品群・商品区分単位
;
-- ==========================================================
-- 月計【カーソル】
-- ==========================================================
    CURSOR get_month_data_cur1(
                         in_item_param      IN NUMBER       -- 処理項目区分【0:数量1:売上2:粗利益額3:掛率】
                        ,iv_param           IN VARCHAR2     -- 変数【設定可能値：商品合計,売上値引,入金値引,拠点計】
                        )
    IS 
      SELECT
             DECODE(in_item_param
                       ,0,NVL(SUM(DECODE(month_no,5,m_amount,0)  ),0) || cv_msg_comma              -- 数量【月】
                          || NVL(SUM(DECODE(month_no,6,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,m_amount,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,m_amount,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,m_amount,0)  ),0) || cv_msg_comma
--//+UPD START 2009/02/23 CT042 S.Son
/*
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma               -- 売上【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit,2) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma              -- 粗利益額【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit,2) || cv_msg_comma
*/
                       ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0) / cn_unit) || cv_msg_comma               -- 売上【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cn_unit) || cv_msg_comma
                       ,2,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cn_unit) || cv_msg_comma              -- 粗利益額【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cn_unit) || cv_msg_comma
--//+UPD END 2009/02/23 CT042 S.Son
                       ,3,NVL(SUM(DECODE(month_no,5,m_rate,0)  ),0) || cv_msg_comma                -- 掛率【月】
                          || NVL(SUM(DECODE(month_no,6,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,m_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,m_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,m_rate,0)  ),0) || cv_msg_comma
                       ,NULL) AS month_data
      FROM  
            xxcsm_tmp_sales_plan_hon       -- 商品計画リスト_本単位ワークテーブル
      WHERE
            item_nm  = iv_param          -- 商品合計・売上値引・入金値引・拠点計
;
-- ==========================================================
-- 年計【カーソル】
-- ==========================================================
    CURSOR  get_year_data_cur0(
                         in_item_param      IN NUMBER       -- 処理項目区分【0:数量1:売上2:粗利益額3:掛率】
                        ,iv_param           IN VARCHAR2     -- 変数【設定可能値：A,C,D】
                        )
    IS
      SELECT   DISTINCT
               DECODE(in_item_param
                    ,0,NVL(y_amount,0) || CHR(10)                                 -- 数量合計
--//+UPD START 2009/02/23 CT042 S.Son
/*
                    ,1,ROUND(NVL(y_sales,0) / cn_unit,2) || CHR(10)               -- 売上合計
                    ,2,ROUND(NVL(y_margin,0) / cn_unit,2)|| CHR(10)               -- 粗利益額合計
*/
                    ,1,ROUND(NVL(y_sales,0) / cn_unit) || CHR(10)               -- 売上合計
                    ,2,ROUND(NVL(y_margin,0) / cn_unit)|| CHR(10)               -- 粗利益額合計
--//+UPD END 2009/02/23 CT042 S.Son
                    ,3,NVL(y_rate,0) ||  CHR(10)                                  -- 掛率合計
                    ,NULL) AS year_data
      FROM  
            xxcsm_tmp_sales_plan_hon       -- 商品計画リスト_本単位ワークテーブル
      WHERE
            item_cd  = iv_param          -- 商品・商品群・商品区分単位
;   
-- ==========================================================
-- 年計【カーソル】
-- ==========================================================
    CURSOR  get_year_data_cur1(
                         in_item_param      IN NUMBER       -- 処理項目区分【0:数量1:売上2:粗利益額3:掛率】
                        ,iv_param           IN VARCHAR2     -- 変数【設定可能値：商品合計,売上値引,入金値引,拠点計】
                        )
    IS
      SELECT   DISTINCT
               DECODE(in_item_param
                    ,0,NVL(y_amount,0) || CHR(10)                                -- 数量合計
--//+UPD START 2009/02/23 CT042 S.Son
/*
                    ,1,ROUND(NVL(y_sales,0) / cn_unit,2) || CHR(10)              -- 売上合計
                    ,2,ROUND(NVL(y_margin,0) / cn_unit,2)|| CHR(10)              -- 粗利益額合計
*/
                    ,1,ROUND(NVL(y_sales,0) / cn_unit) || CHR(10)              -- 売上合計
                    ,2,ROUND(NVL(y_margin,0) / cn_unit)|| CHR(10)              -- 粗利益額合計
--//+UPD END 2009/02/23 CT042 S.Son
                    ,3,NVL(y_rate,0)                                             -- 掛率合計
                    ,NULL) AS year_data
      FROM  
            xxcsm_tmp_sales_plan_hon       -- 商品計画リスト_本単位ワークテーブル
      WHERE
            item_nm  = iv_param          -- 商品合計・売上値引・入金値引・拠点計
;   
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
--##################  固定部 END   #####################################
    -- 初期化
    in_param := 0;
--
    <<col_loop>>
    WHILE (in_param < 4 ) LOOP
      lb_loop_end := FALSE;
--
      IF (in_param = 0) THEN
          -- 数量【項目名】
          lv_item_col := cv_msg_duble || lv_prf_cd_amount_val || cv_msg_duble || cv_msg_comma;
      ELSIF (in_param = 1) THEN
          -- 売上【項目名】
          lv_item_col := cv_msg_duble || lv_prf_cd_sales_val || cv_msg_duble || cv_msg_comma;
      ELSIF (in_param = 2) THEN
          -- 粗利益額【項目名】
          lv_item_col := cv_msg_duble || lv_prf_cd_margin_val || cv_msg_duble || cv_msg_comma;
      ELSIF (in_param = 3) THEN
          -- 掛率【項目名】
          lv_item_col := cv_msg_duble || lv_prf_cd_rate_val || cv_msg_duble || cv_msg_comma; 
      END IF;    
--
      -- 第一行の設定
      IF (in_param = 0) THEN
            IF (iv_first) THEN
                -- 数量行且つ第一行の場合、拠点コード|拠点名称|商品コード|商品名称
                lv_col_data     := lv_col_data || iv_head || lv_item_col;
            ELSE
                -- 数量行の場合、空白|空白|コード|名称
                lv_col_data     := lv_col_data || cv_msg_linespace || iv_head || lv_item_col;
            END IF;
      ELSE
            -- 上記以外の場合、空白|空白|空白|空白
            lv_col_data     := lv_col_data || cv_msg_linespace || cv_msg_linespace || lv_item_col;
      END IF;
--
      -- 月間情報
      <<month_loop>>
      IF (in_kind = 0) THEN
          FOR rec_month IN get_month_data_cur0(in_param,iv_parament) LOOP
            lb_loop_end := TRUE;
            lv_col_data := lv_col_data || rec_month.month_data;
          END LOOP month_loop;
      ELSIF (in_kind = 1) THEN
         FOR rec_month IN get_month_data_cur1(in_param,iv_parament) LOOP
            lb_loop_end := TRUE;
            lv_col_data := lv_col_data || rec_month.month_data;
         END LOOP month_loop;
      END IF;
--
      -- 月間情報が存在する場合
      IF (lb_loop_end = TRUE) THEN
        -- 年間情報
        <<year_loop>>
        IF (in_kind = 0) THEN
            FOR rec_year IN get_year_data_cur0(in_param,iv_parament) LOOP
                lb_loop_end := FALSE;
                lv_col_data := lv_col_data || rec_year.year_data;
            END LOOP year_loop;
        ELSIF (in_kind = 1) THEN
            FOR rec_year IN get_year_data_cur1(in_param,iv_parament) LOOP
                lb_loop_end := FALSE;
                lv_col_data := lv_col_data || rec_year.year_data;
            END LOOP year_loop;
            -- 売上値引の年率後には改行を追加しない
            IF (iv_parament <> lv_prf_cd_down_sales_val) AND (in_param = 3) THEN
              lv_col_data := lv_col_data || CHR(10);
            END IF;
        END IF;
--
        IF (lb_loop_end = TRUE) THEN
            lv_col_data := lv_col_data || cv_sum_zero;
        END IF;
      -- 月間情報が存在しない場合
      ELSE
          lv_col_data := lv_col_data || cv_all_zero;
      END IF;
      -- 次の項目
      in_param := in_param + 1;
    END LOOP col_loop;
--
    ov_col_data := lv_col_data;
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- 
      IF (get_month_data_cur0%ISOPEN) THEN
         CLOSE get_month_data_cur0;
      END IF;
      -- 
      IF (get_year_data_cur0%ISOPEN) THEN
         CLOSE get_year_data_cur0;
      END IF;
      -- 
      IF (get_month_data_cur1%ISOPEN) THEN
         CLOSE get_month_data_cur1;
      END IF;
      -- 
      IF (get_year_data_cur1%ISOPEN) THEN
         CLOSE get_year_data_cur1;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- 
      IF (get_month_data_cur0%ISOPEN) THEN
         CLOSE get_month_data_cur0;
      END IF;
      -- 
      IF (get_year_data_cur0%ISOPEN) THEN
         CLOSE get_year_data_cur0;
      END IF;
      -- 
      IF (get_month_data_cur1%ISOPEN) THEN
         CLOSE get_month_data_cur1;
      END IF;
      -- 
      IF (get_year_data_cur1%ISOPEN) THEN
         CLOSE get_year_data_cur1;
      END IF;
--        
--#####################################  固定部 END   ###########################
--  
  END get_col_data;
--  
  /*****************************************************************************
   * Procedure Name   : deal_csv_data (A-21)
   * Description      : 【拠点単位】出力データの抽出
   ****************************************************************************/
  PROCEDURE deal_csv_data(
        iv_kyoten_cd      IN  VARCHAR2                                          -- 拠点コード
       ,iv_kyoten_nm      IN  VARCHAR2                                          -- 拠点名称
--  2018/11/14 V1.13 Added START
       ,it_target_group   IN  g_group_ttype                                     --  処理対象政策群
--  2018/11/14 V1.13 Added END
       ,ov_errbuf         OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
       ,ov_retcode        OUT NOCOPY VARCHAR2                                   -- リターン・コード
       ,ov_errmsg         OUT NOCOPY VARCHAR2)                                  -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deal_csv_data';    -- プログラム名 
    
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- ボディヘッダ情報（拠点コード｜拠点名称）
    lv_line_head                VARCHAR2(210);
    -- 月情報（5月|6月|7月|8月|9月|10月|11月|12月|1月|2月|3月|04月）
    lv_month_info               VARCHAR2(4000);
    -- 年間情報（合計）
    lv_year_info                VARCHAR2(4000);
    -- 項目名称
    lv_item_info                VARCHAR2(4000);
    -- テンプ変数
    lv_temp_item                VARCHAR2(6000);
    -- 商品情報
    lv_item_data                VARCHAR2(6000);
    -- 商品群情報
    lv_group4_data              VARCHAR2(6000);
    -- 商品区分情報
    lv_group1_data              VARCHAR2(6000);
    -- 商品コード
    lv_item_cd                  VARCHAR2(10);
    -- 商品群コード
    lv_group4_cd                VARCHAR2(10);
    -- 商品区分コード
    lv_group1_cd                VARCHAR2(10);
    -- 拠点情報
    lv_kyoten_data              VARCHAR2(2000);
    -- 拠点コード|拠点名称
    lv_kyoten_info              VARCHAR2(4000);
    -- 商品群集合
    lv_item_group               VARCHAR2(50);
    -- 判断用
    lb_loop_end                 BOOLEAN := FALSE;
    ln_counts                   NUMBER := 0;
    lv_first_rec                BOOLEAN := TRUE;
--//+ADD START 2009/02/23 CT031 S.Son
    lv_group4_nm                VARCHAR2(100);
--//+ADD END 2009/02/23 CT031 S.Son
--  2018/11/14 V1.13 Added START
    ln_num                      NUMBER;             --  テーブル型変数添え字
--  2018/11/14 V1.13 Added END
--
-- ==========================================================
-- 商品コード・商品群コード・商品区分を取得【カーソル】
-- ==========================================================
    CURSOR get_code_cur(iv_param  IN VARCHAR2)
    IS 
      SELECT DISTINCT
             item_cd                -- 商品コード 
            ,item_nm                -- 商品名称
            ,group_cd_4             -- 商品群コード
            ,group_nm_4             -- 商品群名称
            ,group_cd_1             -- 商品区分コード
            ,group_nm_1             -- 商品区分名称
      FROM  
            xxcsm_tmp_sales_plan_hon       -- 商品計画リスト_本単位ワークテーブル
      WHERE
            item_cd    IS NOT NULL -- 商品コード 
      AND   group_cd_4 IS NOT NULL -- 商品群コード
      AND   group_cd_1 = iv_param  -- 商品区分コード
      ORDER BY 
--//+UPD START 2009/02/25 CT062 T.Tsukino
--            item_cd       ASC
--            ,group_cd_4   ASC
              group_cd_4   ASC
             ,item_cd      ASC
--//+UPD END 2009/02/25 CT062 T.Tsukino
                ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- 初期化
    lv_item_data      := NULL;  -- 商品情報
    lv_group4_data    := NULL;  -- 商品群情報
    lv_group1_data    := NULL;  -- 商品区分情報
    lv_kyoten_data    := NULL;  -- 拠点情報
--  2018/11/14 V1.13 Modified START
--    -- 商品群A
--    lv_item_group   := cv_group_A;
--    
    --  処理対象の政策群を設定
    ln_num  :=  1;
    lv_item_group   := it_target_group( ln_num ).target_group;
--  2018/11/14 V1.13 Modified END
-- 
    lv_kyoten_data := cv_msg_duble || iv_kyoten_cd || cv_msg_duble || cv_msg_comma;
    lv_kyoten_data := lv_kyoten_data || cv_msg_duble || iv_kyoten_nm || cv_msg_duble || cv_msg_comma;
--    
    -- データ存在チェック
    SELECT
          count(1)
    INTO  
          ln_counts
    FROM  
          xxcsm_tmp_sales_plan_hon
    WHERE 
          rownum = 1;                         -- 1行目   
--
    -- 件数が0の場合、処理がスキップします。                                
    IF (ln_counts = 0) THEN
      RETURN;
    END IF;
--
    <<loop_ACD>>
    WHILE(lv_item_group IS NOT NULL) LOOP
        -- 初期化
        lv_item_cd      := NULL;  -- 商品
        lv_group4_cd    := NULL;  -- 商品群
        lv_group1_cd    := NULL;  -- 商品区分
--//+ADD START 2009/02/23 CT031 S.Son
        lv_group4_nm    := NULL;  -- 商品群名
--//+ADD END 2009/02/23 CT031 S.Son
--
        <<rec_code_loop>>
        FOR rec_code IN get_code_cur(lv_item_group) LOOP
            lb_loop_end := TRUE;
            lv_temp_item := NULL;
            lv_line_head := NULL;
--
--//+UPD START 2009/02/23 CT031 S.Son
/*
            -- ======================================================
            -- 【★商品★】
            -- ======================================================
            IF ((lv_item_cd IS NULL) OR (lv_item_cd <> rec_code.item_cd)) THEN
--//+DEL START 2009/02/23 CT029 S.Son
                -- 対象件数【加算】
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
--                
                IF (lv_first_rec) THEN
                    -- 拠点コード|拠点名称
                    lv_line_head := lv_kyoten_data;
                END IF;
--
                -- 商品コード|商品名称
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_nm || cv_msg_duble || cv_msg_comma;
--
                -- 商品情報（数量・売上・粗利益額・掛率）
                get_col_data(
                             rec_code.item_cd
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
                lv_first_rec := FALSE;
--                
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
                    -- エラー件数【加算】 
                    gn_error_cnt := gn_error_cnt + 1 ;
                    -- メッセージを出力
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
--//+DEL START 2009/02/23 CT029 S.Son
                    -- 正常件数【加算】 
                  --gn_normal_cnt := gn_normal_cnt + 1 ;
--//+DEL END 2009/02/23 CT029 S.Son
                END IF;
                -- 商品情報
                lv_item_data := lv_item_data || lv_temp_item;
                -- 商品コード
                lv_item_cd   := rec_code.item_cd;
            END IF;
*/
            -- ======================================================
            -- 【★商品群★】
            -- ======================================================
--//+UPD START 2009/02/23 CT031 S.Son
          --IF ((lv_group4_cd IS NULL) OR (lv_group4_cd <> rec_code.group_cd_4)) THEN
            IF ((lv_group4_cd IS NOT NULL) AND (lv_group4_cd <> rec_code.group_cd_4)) THEN
--//+UPD START 2009/02/23 CT031 S.Son
--//+DEL START 2009/02/23 CT029 S.Son
                -- 対象件数【加算】
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
                -- コード|名称
--//+UPD START 2009/02/23 CT031 S.Son
/*
                lv_line_head := cv_msg_duble || rec_code.group_cd_4 || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.group_nm_4 || cv_msg_duble || cv_msg_comma;
*/
                lv_line_head := cv_msg_duble || lv_group4_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_group4_nm || cv_msg_duble || cv_msg_comma;
--//+UPD END 2009/02/23 CT031 S.Son
--
                -- 商品群（数量・売上・粗利益額・掛率）
                get_col_data(
--//+UPD START 2009/02/23 CT031 S.Son
                           --rec_code.group_cd_4
                             lv_group4_cd
--//+UPD END 2009/02/23 CT031 S.Son
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
--
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
--//+UPD START 2009/02/23 CT029 S.Son
/*
                    -- エラー件数【加算】 
                    gn_error_cnt := gn_error_cnt + 1 ;
                    -- メッセージを出力
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- 正常件数【加算】 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
                    RAISE global_api_others_expt;
--//+UPD END 2009/02/23 CT029 S.Son
                END IF;
                -- 商品群情報
                lv_group4_data := lv_group4_data || lv_temp_item;
--//+ADD START 2009/02/23 CT031 S.Son
                IF (lv_group4_data IS NOT NULL) THEN                
                  -- 商品群情報の出力
                  fnd_file.put_line(
                                    which  => FND_FILE.OUTPUT
                                   ,buff   => lv_group4_data
                                   );
                  -- 初期化
                  lv_group4_data    := NULL;  -- 商品群情報
                END IF;
--//+ADD END 2009/02/23 CT031 S.Son
--//+DEL START 2009/02/23 CT031 S.Son
                -- 商品群コード
              --lv_group4_cd := rec_code.group_cd_4;
--//+DEL END 2009/02/23 CT031 S.Son
            END IF;
            -- ======================================================
            -- 【★商品★】
            -- ======================================================
            IF ((lv_item_cd IS NULL) OR (lv_item_cd <> rec_code.item_cd)) THEN
--//+DEL START 2009/02/23 CT029 S.Son
                -- 対象件数【加算】
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
--                
                IF (lv_first_rec) THEN
                    -- 拠点コード|拠点名称
                    lv_line_head := lv_kyoten_data;
--//+ADD START 2009/02/23 CT031 S.Son
                ELSE
                    lv_line_head := NULL;
--//+ADD END 2009/02/23 CT031 S.Son
                END IF;
--
                -- 商品コード|商品名称
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.item_nm || cv_msg_duble || cv_msg_comma;
--
                -- 商品情報（数量・売上・粗利益額・掛率）
                get_col_data(
                             rec_code.item_cd
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
                lv_first_rec := FALSE;
--                
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
--//+UPD START 2009/02/23 CT029 S.Son
/*
                    -- エラー件数【加算】 
                    gn_error_cnt := gn_error_cnt + 1 ;
                    -- メッセージを出力
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- 正常件数【加算】 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
                    RAISE global_api_others_expt;
--//+UPD END 2009/02/23 CT029 S.Son
                END IF;
                -- 商品情報
                lv_item_data := lv_item_data || lv_temp_item;
--//+ADD START 2009/02/23 CT031 S.Son
                IF (lv_item_data IS NOT NULL) THEN
                    -- 商品情報の出力
                    fnd_file.put_line(
                                      which  => FND_FILE.OUTPUT
                                     ,buff   => lv_item_data
                                     );
                    -- 初期化
                    lv_item_data      := NULL;  -- 商品情報
                END IF;
--//+ADD END 2009/02/23 CT031 S.Son
                -- 商品コード
                lv_item_cd   := rec_code.item_cd;
            END IF;
--//+UPD END 2009/02/23 CT031 S.Son
            -- ======================================================
            -- 【★商品区分★】
            -- ======================================================
            IF ((lv_group1_cd IS NULL) OR (lv_group1_cd <> rec_code.group_cd_1)) THEN
--//+DEL START 2009/02/23 CT029 S.Son
                -- 対象件数【加算】
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
                -- コード|名称
                lv_line_head := cv_msg_duble || rec_code.group_cd_1 || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || rec_code.group_nm_1 || cv_msg_duble || cv_msg_comma;
                -- 商品区分情報（数量・売上・粗利益額・掛率）
                get_col_data(
                             rec_code.group_cd_1
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
--
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
--//+UPD START 2009/02/23 CT029 S.Son
/*
                    -- エラー件数【加算】 
                    gn_error_cnt := gn_error_cnt + 1 ;
                    -- メッセージを出力
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- 正常件数【加算】 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
                    RAISE global_api_others_expt;
--//+UPD END 2009/02/23 CT029 S.Son
                END IF;
                -- 商品区分情報
                lv_group1_data := lv_group1_data || lv_temp_item;
                -- 商品区分コード(1桁)
                lv_group1_cd   := rec_code.group_cd_1;
            END IF;
--//+ADD START 2009/02/23 CT031 S.Son
            lv_group4_cd := rec_code.group_cd_4;
            lv_group4_nm := rec_code.group_nm_4;
--//+ADD END 2009/02/23 CT031 S.Son
        END LOOP rec_code_loop;
--
        IF (lb_loop_end = TRUE) THEN
--//+DEL START 2009/02/23 CT031 S.Son
/*
            IF (lv_item_data IS NOT NULL) THEN
                -- 商品情報の出力
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_item_data
                                 );
                -- 初期化
                lv_item_data      := NULL;  -- 商品情報
            END IF;
--
            IF (lv_group4_data IS NOT NULL) THEN                
                -- 商品群情報の出力
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_group4_data
                                 );
                -- 初期化
                lv_group4_data    := NULL;  -- 商品群情報
            END IF;
*/
--//+DEL END 2009/02/23 CT031 S.Son
--//+ADD START 2009/02/23 CT031 S.Son
            IF lv_group4_cd IS NOT NULL THEN
                lv_line_head := cv_msg_duble || lv_group4_cd || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_group4_nm || cv_msg_duble || cv_msg_comma;
--
                -- 商品群（数量・売上・粗利益額・掛率）
                get_col_data(
                             lv_group4_cd
                            ,0
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
--
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
                    RAISE global_api_others_expt;
                END IF;
                -- 商品群情報
                lv_group4_data := lv_group4_data || lv_temp_item;
                IF (lv_group4_data IS NOT NULL) THEN                
                  -- 商品群情報の出力
                  fnd_file.put_line(
                                    which  => FND_FILE.OUTPUT
                                   ,buff   => lv_group4_data
                                   );
                  -- 初期化
                  lv_group4_data    := NULL;  -- 商品群情報
                END IF;
            END IF;
--//+ADD END 2009/02/23 CT031 S.Son
--
            IF (lv_group1_data IS NOT NULL) THEN
                -- 商品区分情報の出力
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_group1_data
                                 );
                -- 初期化
                lv_group1_data    := NULL;  -- 商品区分情報
            END IF;
        END IF;
--
        -- 判断・設定・集計
--  2018/11/14 V1.13 Modified START
--        IF (lv_item_group = cv_group_A ) THEN
--            -- 【商品群A→商品群C】
--            lv_item_group := cv_group_C;
        IF ( it_target_group( ln_num ).summary_disp = cv_flg_n ) THEN
          --  合計出力フラグ N の場合、次の政策群を処理する
          ln_num  :=  ln_num + 1;
          lv_item_group :=  it_target_group( ln_num ).target_group;
--  2018/11/14 V1.13 Modified END
--  2018/11/14 V1.13 Modified START
--        ELSIF (lv_item_group = cv_group_C ) THEN
        ELSIF ( it_target_group( ln_num ).summary_disp = cv_flg_y AND it_target_group( ln_num ).summary_type <> cv_summary_type_99 ) THEN
          --  合計出力フラグ Y で、合計区分が「その他合計」以外の場合
--  2018/11/14 V1.13 Modified END
            IF (lb_loop_end = TRUE) THEN
                -- ======================================================
                -- 【★商品合計★】
                -- ======================================================
                -- 初期化
                lv_temp_item := NULL;
                lv_line_head := NULL;
--                
                -- 空白|名称
                lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
--  2018/11/14 V1.13 Modified START
--                lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_sum_val || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || it_target_group( ln_num ).summary_name || cv_msg_duble || cv_msg_comma;
--  2018/11/14 V1.13 Modified END
--              
--//+DEL START 2009/02/23 CT029 S.Son
                -- 対象件数【加算】
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
                -- 商品合計情報（数量・売上・粗利益額・掛率）
                get_col_data(
--  2018/11/14 V1.13 Modified START
--                             lv_prf_cd_sum_val
                            it_target_group( ln_num ).summary_name
--  2018/11/14 V1.13 Modified END
                            ,1
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
--//+UPD START 2009/02/23 CT029 S.Son
/*
                    -- エラー件数【加算】 
                    gn_error_cnt := gn_error_cnt + 1 ;
                    -- メッセージを出力
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- 正常件数【加算】 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
                    RAISE global_api_others_expt;
--//+UPD END 2009/02/23 CT029 S.Son
                END IF;
                -- 商品合計情報の出力
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT                                                     
                                 ,buff   => lv_temp_item
                                 );
            END IF;
--  2018/11/14 V1.13 Modified START
            -- 【商品群C→商品群D】
--            lv_item_group := cv_group_D;
--            
            --  次の商品群を処理
            ln_num  :=  ln_num + 1;
            lv_item_group :=  it_target_group( ln_num ).target_group;
--  2018/11/14 V1.13 Modified END
--  2018/11/14 V1.13 Modified START
--        ELSIF (lv_item_group = cv_group_D) THEN
        ELSIF ( it_target_group( ln_num ).summary_disp = cv_flg_y AND it_target_group( ln_num ).summary_type = cv_summary_type_99 ) THEN
--  2018/11/14 V1.13 Modified END
            -- ======================================================
            -- 【★売上値引★】
            -- ======================================================
            -- 初期化
            ln_counts := 0;
--
            -- 売上値引情報が存在するかどうか
            SELECT
                count(1)
            INTO
                ln_counts
            FROM
                xxcsm_tmp_sales_plan_hon
            WHERE
                item_cd  = cv_group_N
            AND ROWNUM   = 1; -- 1行目
--
            IF (ln_counts > 0) THEN
                -- 初期化
                lv_temp_item := NULL;
                lv_line_head := NULL;
                
                -- 空白|名称
                lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_down_sales_val || cv_msg_duble || cv_msg_comma;
--//+DEL START 2009/02/23 CT029 S.Son
                -- 対象件数【加算】
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
--
                -- 売上値引情報（数量・売上・粗利益額・掛率）
                get_col_data(
                             lv_prf_cd_down_sales_val
                            ,1
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
--
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
--//+UPD START 2009/02/23 CT029 S.Son
/*
                    -- エラー件数【加算】 
                    gn_error_cnt := gn_error_cnt + 1 ;
                    -- メッセージを出力
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- 正常件数【加算】 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
                    RAISE global_api_others_expt;
--//+UPD END 2009/02/23 CT029 S.Son
                END IF;
                -- 売上値引情報の出力
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT
                                 ,buff   => lv_temp_item
                                 );
                -- ======================================================
                -- 【★入金値引★】
                -- ======================================================
                -- 初期化
                lv_temp_item := NULL;
                lv_line_head := NULL;
--
                -- 空白|名称
                lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
                lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_down_pay_val || cv_msg_duble || cv_msg_comma;
--
--//+DEL START 2009/02/23 CT029 S.Son
                -- 対象件数【加算】
              --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
--
                -- 入金値引情報（数量・売上・粗利益額・掛率）
                get_col_data(
                             lv_prf_cd_down_pay_val
                            ,1
                            ,lv_line_head
                            ,lv_first_rec
                            ,lv_errbuf 
                            ,lv_retcode
                            ,lv_errmsg
                            ,lv_temp_item
                            );
--
                IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
--//+UPD START 2009/02/23 CT029 S.Son
/*
                    -- エラー件数【加算】 
                    gn_error_cnt := gn_error_cnt + 1 ;
--
                    -- メッセージを出力
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
                 
                ELSIF (lv_retcode = cv_status_normal) THEN
                    -- 正常件数【加算】 
                    gn_normal_cnt := gn_normal_cnt + 1 ;
*/
                    RAISE global_api_others_expt;
--//+UPD END 2009/02/23 CT029 S.Son
                END IF;
                
                -- 入金値引情報の出力
                fnd_file.put_line(
                                  which  => FND_FILE.OUTPUT                                                     
                                 ,buff   => lv_temp_item
                                 );
            END IF;
            -- ======================================================
            -- 【★拠点計★】
            -- ======================================================
            -- 初期化
            lv_temp_item := NULL;
            lv_line_head := NULL;
--
            -- 空白|名称
            lv_line_head := cv_msg_duble || cv_msg_space || cv_msg_duble || cv_msg_comma;
            lv_line_head := lv_line_head || cv_msg_duble || lv_prf_cd_p_sum_val || cv_msg_duble || cv_msg_comma;
--
--//+DEL START 2009/02/23 CT029 S.Son
            -- 対象件数【加算】
          --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
--
            -- 拠点計情報（数量・売上・粗利益額・掛率）
            get_col_data(
                         lv_prf_cd_p_sum_val
                        ,1
                        ,lv_line_head
                        ,lv_first_rec
                        ,lv_errbuf 
                        ,lv_retcode
                        ,lv_errmsg
                        ,lv_temp_item
                        );
            IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
--//+UPD START 2009/02/23 CT029 S.Son
/*
                -- エラー件数【加算】 
                gn_error_cnt := gn_error_cnt + 1 ;
--
                -- メッセージを出力
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
             
            ELSIF (lv_retcode = cv_status_normal) THEN
                -- 正常件数【加算】 
                gn_normal_cnt := gn_normal_cnt + 1 ;
*/
                RAISE global_api_others_expt;
--//+UPD END 2009/02/23 CT029 S.Son
            END IF;
            
            -- 拠点計情報の出力
            fnd_file.put_line(
                              which  => FND_FILE.OUTPUT                                                     
                             ,buff   => lv_temp_item || CHR(10)
                             );
            -- LOOP処理は終了
            lv_item_group := NULL;
        END IF;
        
    END LOOP loop_ACD;
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_code_cur%ISOPEN) THEN
         CLOSE get_code_cur;
      END IF;
      
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_code_cur%ISOPEN) THEN
         CLOSE get_code_cur;
      END IF;
      
--        
--#####################################  固定部 END   ###########################
--  
  END deal_csv_data;
--
   /*****************************************************************************
   * Procedure Name   : deal_all_data (A-2~A-20)
   * Description      : 拠点毎に処理を繰り返す
   ****************************************************************************/
  PROCEDURE deal_all_data(
        ov_errbuf      OUT NOCOPY VARCHAR2                                      -- エラー・メッセージ
       ,ov_retcode     OUT NOCOPY VARCHAR2                                      -- リターン・コード
       ,ov_errmsg      OUT NOCOPY VARCHAR2)                                     -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)  := 'deal_all_data';        -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_kyoten_cd              VARCHAR2(10);             -- 拠点コード
    lv_kyoten_nm              VARCHAR2(200);            -- 拠点名称
    lv_kyoten_data            VARCHAR2(4000);           -- 拠点のボディ情報
    ln_count                  NUMBER;                   -- 計数用
    
    lv_get_loc_tab            xxcsm_common_pkg.g_kyoten_ttype;  -- 拠点コードリスト
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
--  2018/11/14 V1.13 Added START
    ln_num                NUMBER;               --  テーブル型変数添え字
    lt_target_group       g_group_ttype;        --  処理対象政策群
    --
    --  処理対象政策群取得CURSOR
    CURSOR  cur_target_group
    IS
      SELECT  flv2.lookup_code        target_group            --  政策群
            , flv1.lookup_code        summary_type            --  合計区分
            , flv1.description        summary_name            --  合計区分名
      FROM    fnd_lookup_values   flv1                        --  参照表：商品計画リスト合計区分
            , fnd_lookup_values   flv2                        --  参照表：商品計画リスト出力対象商品群
      WHERE   flv1.lookup_type      =   cv_lookup_summary
      AND     flv1.language         =   USERENV( 'LANG' )
      AND     flv1.enabled_flag     =   cv_flg_y
      AND     SYSDATE   >=  flv1.start_date_active
      AND     SYSDATE   <=  NVL( flv1.end_date_active, SYSDATE )
      AND     flv2.lookup_type      =   cv_lookup_group
      AND     flv2.language         =   USERENV( 'LANG' )
      AND     flv2.enabled_flag     =   cv_flg_y
      AND     SYSDATE   >=  flv2.start_date_active
      AND     SYSDATE   <=  NVL( flv2.end_date_active, SYSDATE )
      AND     flv1.lookup_code      =   flv2.attribute1
      ORDER BY  flv1.lookup_code
              , flv2.lookup_code
    ;
    rec_target_group      cur_target_group%ROWTYPE;
--  2018/11/14 V1.13 Added END
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- ================================================
  -- 【拠点コードリスト】取得処理
  -- ================================================
  xxcsm_common_pkg.get_kyoten_cd_lv6(gv_kyotencd
                                     ,gv_kaisou
--//ADD START 2009/05/07 T1_0858 M.Ohtsuki
                                     ,gn_taisyoym
--//ADD END   2009/05/07 T1_0858 M.Ohtsuki
                                     ,lv_get_loc_tab
                                     ,lv_retcode
                                     ,lv_errbuf
                                     ,lv_errmsg
                                    );
-- 
    IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
        RAISE global_api_others_expt;
    END IF;
--
--  2018/11/14 V1.13 Added START
    --  ==============================================
    --    処理対象の政策群情報を保持
    --  ==============================================
    ln_num  :=  0;
    lt_target_group.DELETE;
    FOR rec_target_group IN cur_target_group LOOP
      ln_num  :=  ln_num + 1;
      lt_target_group( ln_num ).target_group  :=  rec_target_group.target_group;      --  政策群
      lt_target_group( ln_num ).summary_type  :=  rec_target_group.summary_type;      --  合計区分
      lt_target_group( ln_num ).summary_name  :=  rec_target_group.summary_name;      --  合計区分名
      lt_target_group( ln_num ).summary_disp  :=  cv_flg_n;                           --  合計出力フラグ
      --
      IF ( ln_num <> 1 AND lt_target_group( ln_num ).summary_type <> lt_target_group( ln_num - 1 ).summary_type ) THEN
        --  合計区分が変わったら、一つ前の情報の合計出力フラグを Y に変更
        lt_target_group( ln_num - 1 ).summary_disp  :=  cv_flg_y;
      END IF;
    END LOOP;
    --  最終データの合計出力フラグを Y に変更
    lt_target_group( ln_num ).summary_disp  :=  cv_flg_y;
--  2018/11/14 V1.13 Added END
  -- ================================================
  -- 【拠点コードリスト】拠点毎に下記処理を繰り返す
  -- ================================================
  <<kyoten_list_loop>>
  FOR ln_count IN 1..lv_get_loc_tab.COUNT LOOP
--
    BEGIN
--
        -- 拠点コード
        lv_kyoten_cd := lv_get_loc_tab(ln_count).kyoten_cd;
        -- 拠点名称
        lv_kyoten_nm := lv_get_loc_tab(ln_count).kyoten_nm;
--//+ADD START 2009/02/23 CT029 S.Son
        gn_target_cnt := gn_target_cnt + 1;
--//+ADD END 2009/02/23 CT029 S.Son
--
        -- ================================================
        -- 【チェック処理】
        -- ================================================
        do_check(
                 lv_kyoten_cd
                ,lv_errbuf
                ,lv_retcode
                ,lv_errmsg
                );
--
        IF (lv_retcode = cv_status_warn) THEN     -- 戻り値が警告の場合
            RAISE global_skip_expt;
        ELSIF (lv_retcode = cv_status_error) THEN -- 戻り値が異常の場合
            RAISE global_process_expt;
        END IF;
--
        -- ================================================
        -- 【拠点データ処理】
        -- ================================================
        deal_item_data(
                     lv_kyoten_cd
                    ,lv_errbuf
                    ,lv_retcode
                    ,lv_errmsg
                );
                
        IF (lv_retcode = cv_status_warn) THEN     -- 戻り値が警告の場合
            RAISE global_skip_expt;
        ELSIF (lv_retcode = cv_status_error) THEN -- 戻り値が異常の場合
            RAISE global_process_expt;
        END IF;
--//+ADD START 2009/02/23 CT029 S.Son
        --正常件数加算
        gn_normal_cnt := gn_normal_cnt + 1;
--//+ADD END 2009/02/23 CT029 S.Son
--
        -- ================================================
        -- 【情報出力】
        -- ================================================
        deal_csv_data(
                     lv_kyoten_cd
                    ,lv_kyoten_nm
--  2018/11/14 V1.13 Added START
                    , lt_target_group
--  2018/11/14 V1.13 Added END
                    ,lv_errbuf
                    ,lv_retcode
                    ,lv_errmsg
                    );
--
        IF (lv_retcode <> cv_status_normal) THEN  -- 戻り値が異常の場合
          RAISE global_process_expt;
        END IF;
--
        -- 再設定
        gn_index := 0;
--
        -- 前拠点のデータを削除する
        DELETE FROM xxcsm_tmp_sales_plan_hon;
    --  
    --#################################  スキップ例外処理部  START#############################
    --
    EXCEPTION
        WHEN global_skip_expt THEN 
          -- ステータスを警告にセット
          ov_retcode := cv_status_warn;
          -- LOGに出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg 
          );
--//+DEL START 2009/02/23 CT029 S.Son
          --対象件数を設定
        --gn_target_cnt := gn_target_cnt + 1;
--//+DEL END 2009/02/23 CT029 S.Son
--//+UPD START 2009/02/23 CT029 S.Son
          -- エラー件数カウント
        --gn_error_cnt := gn_error_cnt + 1;
          gn_warn_cnt := gn_warn_cnt + 1;
--//+UPD END 2009/02/23 CT029 S.Son
    --  
    --#################################  スキップ例外処理部  END#############################
    --
    END;
    --
  END LOOP kyoten_list_loop;
--  
--#################################  固定例外処理部  #############################
--
  EXCEPTION
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
  END deal_all_data;
--
   /****************************************************************************
   * Procedure Name   : write_csv_file (A-22)
   * Description      : データの出力            
   ****************************************************************************/
   PROCEDURE write_csv_file (  
         ov_errbuf     OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
        
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'write_csv_file';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- ヘッダ情報
    lv_data_head                VARCHAR2(4000);
    -- 該当抽出データ無しメッセージ
    lv_nodata_msg               VARCHAR2(4000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- ヘッダ情報の抽出
    lv_data_head := xxccp_common_pkg.get_msg(                                   -- 拠点コードの出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_00092                      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year                            -- トークンコード1（対象年度）
                     ,iv_token_value1 => gn_taisyoym                            -- トークン値1
                     ,iv_token_name2  => cv_tkn_genka_nm                        -- トークンコード2（原価）
                     ,iv_token_value2 => gv_genkanm                             -- トークン値2
                     ,iv_token_name3  => cv_tkn_sysdate                         -- トークンコード3（業務日付）
                     ,iv_token_value3 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI')  -- トークン値3
                     );
     -- ヘッダ情報の出力
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_data_head
                     );
--
    -- ボディ情報を取得（deal_all_dataを呼び出す）        
    deal_all_data(
                   lv_errbuf
                  ,lv_retcode
                  ,lv_errmsg
                  );
--
    -- 出力データがない場合、警告終了
    IF (gn_normal_cnt = 0) THEN
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcsm
                         ,iv_name         => cv_csm1_msg_10001
                        );
      -- データ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_nodata_msg
      );
      -- ステータスを警告にセットする
      lv_retcode := cv_status_warn;
    END IF;
--
    IF (lv_retcode = cv_status_warn) THEN      -- 戻り値が警告の場合
      ov_retcode := cv_status_warn; 
    ELSIF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
      ov_retcode := cv_status_error; 
    END IF;
--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
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
  END write_csv_file;
--
  /*****************************************************************************
   * Procedure Name   : submain
   * Description      : 実装処理
   ****************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2     -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2     -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- プログラム名
    
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
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
    gn_target_cnt := 0;                          -- 対象件数カウンタの初期化
    gn_normal_cnt := 0;                          -- 正常件数カウンタの初期化
    gn_error_cnt  := 0;                          -- エラー件数カウンタの初期化
    gn_warn_cnt   := 0;                          -- スキップ件数カウンタの初期化
-- 初期処理
    init(                                        -- initをコール
       lv_errbuf                                 -- エラー・メッセージ
      ,lv_retcode                                -- リターン・コード
      ,lv_errmsg                                 -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode <> cv_status_normal) THEN     -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
-- データの出力
    write_csv_file(                              -- write_csv_fileをコール
       lv_errbuf                                 -- エラー・メッセージ
      ,lv_retcode                                -- リターン・コード
      ,lv_errmsg                                 -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_warn) THEN        -- 戻り値が警告の場合
      ov_retcode := cv_status_warn; 
    ELSIF (lv_retcode = cv_status_error) THEN    -- 戻り値が異常の場合
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
   * Description      : 外部呼出メインプロシージャ
   ****************************************************************************/
  PROCEDURE main(
                errbuf           OUT    NOCOPY VARCHAR2,         --   エラーメッセージ
                retcode          OUT    NOCOPY VARCHAR2,         --   エラーコード
                iv_taisyo_ym     IN     VARCHAR2,                --   対象年度
                iv_kyoten_cd     IN     VARCHAR2,                --   拠点コード                
                iv_cost_kind     IN     VARCHAR2,                --   原価種別
--//+UPD START E_本稼動_09949 K.Taniguchi
--                iv_kyoten_kaisou IN     VARCHAR2                 --   階層
                iv_kyoten_kaisou IN     VARCHAR2,                --   階層
                iv_new_old_cost_class
                                 IN     VARCHAR2                 --   新旧原価区分
--//+UPD END E_本稼動_09949 K.Taniguchi
  ) AS
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################
--
-- 終了メッセージコード
    lv_message_code   VARCHAR2(100);     -- 終了コード
-- ===============================
-- 固定ローカル定数
-- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'main'; -- プログラム名
    cv_which_log        CONSTANT VARCHAR2(10)    := 'LOG';  -- 出力先  
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
-- 入力パラメータ
    gn_taisyoym     := TO_NUMBER(iv_taisyo_ym);         -- 対象年度
    gv_kyotencd     := iv_kyoten_cd;                    -- 拠点コード
    gv_genkacd      := iv_cost_kind;                    -- 原価種別
    gv_kaisou       := iv_kyoten_kaisou;                -- 階層
--//+ADD START E_本稼動_09949 K.Taniguchi
    gv_new_old_cost_class := iv_new_old_cost_class;     -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
-- 実装処理
    submain(                               -- submainをコール
        lv_errbuf                          -- エラー・メッセージ
       ,lv_retcode                         -- リターン・コード
       ,lv_errmsg                          -- ユーザー・エラー・メッセージ
     );
--
   IF(lv_retcode = cv_status_error) THEN
         IF (lv_errmsg IS NULL) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm
                       ,iv_name         => cv_ccp1_msg_00111
                       );
         END IF;
         -- エラー出力
         fnd_file.put_line(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg            -- ユーザー・エラーメッセージ
         );
         
         fnd_file.put_line(
            which  => FND_FILE.LOG
           ,buff   => lv_errbuf            -- エラーメッセージ
         );
        -- 件数カウンタの初期化
        gn_target_cnt := 0;               -- 対象件数カウンタの初期化
        gn_normal_cnt := 0;               -- 正常件数カウンタの初期化
        gn_error_cnt  := 1;               -- エラー件数カウンタの初期化
        gn_warn_cnt   := 0;               -- スキップ件数カウンタの初期化
   END IF;
    -- 空行の出力
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_ccp1_msg_90004;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_ccp1_msg_90005;  
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
END XXCSM002A13C;
/
