CREATE OR REPLACE PACKAGE BODY XXCSM002A03C AS
/*******************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A03C(spec)
 * Description      : 商品計画参考資料出力
 * MD.050           : 商品計画参考資料出力 MD050_CSM_002_A03
 * Version          : 1.7
 *
 * Program List
 * -------------------- --------------------------------------------------------
 *  Name                 Description
 *
 *  init                【初期処理】A-1
 *
 *  do_check            【チェック処理】A-2
 *
 *  deal_result_data    【実績データの詳細処理】A-3,A-4,A-5,A-6,A-7
 *
 *  deal_plan_data      【計画データの詳細処理】A-3,A-4,A-8,A-9,A-10
 *
 *  write_line_info     【商品単位でのデータ出力】A-11
 *
 *  write_csv_file      【商品計画参考資料データをCSVファイルへ出力】A-11
 *
 *  submain             【実装処理】A-1~A-11
 *
 *  main                【コンカレント実行ファイル登録プロシージャ】A-1~A-12
 *
 * 
 * Change Record
 * ------------- ----- ---------------- ----------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ----------------------------------------
 *  2008/12/04    1.0   SCS ohshikyo     新規作成
 *  2009/02/16    1.1   SCS K.Yamada     [障害CT024]分母0の不具合の対応
 *  2009/02/18    1.2   SCS K.Sai        [障害CT027]粗利益額の小数点2桁表示不具合＆ヘッダ日付表示対応
 *  2009/05/25    1.3   SCS M.Ohtsuki    [障害T1_1020]
 *  2009/06/10    1.4   SCS M.Ohtsuki    [障害T1_1399]
 *  2009/07/10    1.5   SCS T.Tsukino    [障害0000637]PT(政策群２ビューへのヒント句追加）
 *  2010/12/13    1.6   SCS Y.Kanami     [E_本稼動_05803]
 *  2011/03/31    1.7   SCS H.Sasaki     [E_本稼動_06952]一時表からの対象品目取得SQL修正
 *
 ******************************************************************************/
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
  gn_target_cnt             NUMBER;                                             -- 対象件数
  gn_normal_cnt             NUMBER;                                             -- 正常件数
  gn_error_cnt              NUMBER;                                             -- エラー件数
  gn_warn_cnt               NUMBER;                                             -- スキップ件数
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--  
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A03C';           -- パッケージ名
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                      -- カンマ     
  cv_msg_hafu               CONSTANT VARCHAR2(3)   := '-';                      -- 
  cv_msg_space              CONSTANT VARCHAR2(4)   := '';                     -- 空白
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                      -- ダブルクォーテーション
    
  cv_msg_linespace          CONSTANT VARCHAR2(20) := cv_msg_duble|| cv_msg_space ||cv_msg_duble|| cv_msg_comma || cv_msg_duble ||cv_msg_space || cv_msg_duble || cv_msg_comma;
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                  -- アプリケーション短縮名    
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                  -- アドオン：共通・IF領域
  
-- 
  -- ===============================
  -- ユーザー定義グローバル変数 
  -- ===============================
--  
  gd_process_date           DATE;                                               -- 業務日付
  gn_index                  NUMBER := 0;                                        -- 登録順
  gv_kyotenCD               VARCHAR2(32);                                       -- 拠点コード
  gv_taisyoYm               NUMBER(4,0);                                        -- 対象年度
--//+UPD START 2009/06/10 T1_1399 M.Ohtsuki
--  gv_kakuteiym              VARCHAR2(6);                                        -- 確定年月
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
  gv_kakuteiym              NUMBER(6);                                          -- 確定年月
--//+UPD END   2009/06/10 T1_1399 M.Ohtsuki
  gv_planYm                 NUMBER(4,0);                                        -- 計画年度
  gv_kyotennm               VARCHAR2(200);                                      -- 拠点名称
  
  
  
  -- ===============================
  -- 共用メッセージ番号
  -- ===============================
--  
  cv_ccp1_msg_90000           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';         -- 対象件数メッセージ
  cv_ccp1_msg_90001           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';         -- 成功件数メッセージ
  cv_ccp1_msg_90002           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';         -- エラー件数メッセージ
  cv_ccp1_msg_90003           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';         -- スキップ件数メッセージ
  cv_ccp1_msg_90004           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';         -- 正常終了メッセージ
  cv_ccp1_msg_90006           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';         -- エラー終了全ロールバックメッセージ
  cv_ccp1_msg_00111           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';         -- 想定外エラーメッセージ
--  
  -- ===============================  
  -- メッセージ番号
  -- ===============================
--  
  cv_csm1_msg_00005           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';         -- プロファイル取得エラーメッセージ
  cv_csm1_msg_00099           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00099';         -- 商品計画用対象データ無しメッセージ
  cv_csm1_msg_00107           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00107';         -- 商品計画参考資料(商品別2ヵ年実績)ヘッダ用メッセージ
  cv_csm1_msg_00024           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';         -- 拠点コードチェックエラーメッセージ
  cv_csm1_msg_00048           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';         -- 入力パラメータ取得メッセージ(拠点コード)
  cv_csm1_msg_10015           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10015';         -- 入力パラメータ取得メッセージ（対象年度）
  
--
  -- ===============================
  -- トークン定義
  -- ===============================
--  
  cv_tkn_year                      CONSTANT VARCHAR2(100) := 'TAISYOU_YM';      -- 対象年度
  cv_tkn_kyotencd                  CONSTANT VARCHAR2(100) := 'KYOTEN_CD';       -- 拠点コード
  cv_tkn_kyotennm                  CONSTANT VARCHAR2(100) := 'KYOTEN_NM';       -- 拠点名称
  cv_tkn_profile                   CONSTANT VARCHAR2(100) := 'PROF_NAME';       -- プロファイル名
  cv_tkn_count                     CONSTANT VARCHAR2(100) := 'COUNT';           -- 処理件数
  cv_tkn_sysdate                   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI'; -- 作成日時
  cv_tkn_kakuteiym                 CONSTANT VARCHAR2(100) := 'KAKUTEI_YM';      -- 確定年月
  cv_tkn_planym                    CONSTANT VARCHAR2(100) := 'KEIKAKU_YM';      -- 計画年月
  cv_cnt_token                     CONSTANT VARCHAR2(10)  := 'COUNT';           -- 件数メッセージ
 

  -- =============================== 
  -- プロファイル
  -- ===============================
-- プロファイル・コード  
  lv_prf_cd_item                    CONSTANT VARCHAR2(100) := 'XXCSM1_DEAL_CATEGORY';    -- XXCMN:政策群品目カテゴリ特定名
  lv_prf_cd_sales                   CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';  -- XXCMN:売上
  lv_prf_cd_rate                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_4';   -- XXCMN:掛率
  lv_prf_cd_amount                  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_1';  -- XXCMN:数量
  lv_prf_cd_margin                  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6'; -- XXCMN:粗利益額
  lv_prf_cd_margin_rate             CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7'; -- XXCMN:粗利益率
  lv_prf_cd_make                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANGUN_ITEM_1';   -- XXCMN:構成比
  lv_prf_cd_result                  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_1';   -- XXCMN:年実績
  lv_prf_cd_plan                    CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_2';   -- XXCMN:年計画
  lv_prf_cd_g2_make                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_3';   -- XXCMN:群2桁構成比
  lv_prf_cd_kyoten_make             CONSTANT VARCHAR2(100) := 'XXCSM1_PLANREF_ITEM_4';   -- XXCMN:拠点計構成比

  

-- プロファイル・名称
  lv_prf_cd_item_val                     VARCHAR2(100) ;                                 -- XXCMN:政策群品目カテゴリ特定名
  lv_prf_cd_sales_val                    VARCHAR2(100) ;                                 -- XXCMN:売上
  lv_prf_cd_rate_val                     VARCHAR2(100) ;                                 -- XXCMN:掛率
  lv_prf_cd_amount_val                   VARCHAR2(100) ;                                 -- XXCMN:数量
  lv_prf_cd_margin_val                   VARCHAR2(100) ;                                 -- XXCMN:粗利益額
  lv_prf_cd_margin_rate_val              VARCHAR2(100) ;                                 -- XXCMN:粗利益率
  lv_prf_cd_make_val                     VARCHAR2(100) ;                                 -- XXCMN:構成比
  lv_prf_cd_result_val                   VARCHAR2(100) ;                                 -- XXCMN:年実績
  lv_prf_cd_plan_val                     VARCHAR2(100) ;                                 -- XXCMN:年計画
  lv_prf_cd_g2_make_val                  VARCHAR2(100) ;                                 -- XXCMN:群2桁構成比  
  lv_prf_cd_kyoten_make_val              VARCHAR2(100) ;                                 -- XXCMN:拠点計構成比 
  
    
    /****************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理            
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
    
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value                VARCHAR2(1000);
    
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
    

-- 拠点コード(INパラメータの出力)
    lv_pram_op_1 := xxccp_common_pkg.get_msg(                                   -- 拠点コードの出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_00048                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- トークンコード1（拠点コード）
                     ,iv_token_value1 => gv_kyotenCD                            -- トークン値1
                     );
                     
    -- LOGに出力
    fnd_file.put_line(
                      which  => FND_FILE.LOG
                     ,buff   => CHR(10) || lv_pram_op_1 
                     );
-- 対象年度(INパラメータの出力)
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                   -- 対象年度の出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10015                      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year                            -- トークンコード1（対象年度名称）
                     ,iv_token_value1 => gv_taisyoYm                            -- トークン値1
                     );
                     
    -- LOGに出力
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                     
                     ,buff   => lv_pram_op_2 || CHR(10)
                     );                     
-- 計画年度
    gv_planYm := gv_taisyoYm - 1 ;
                   
-- 確定年月

    SELECT
--//+UPD START 2009/06/10 T1_1399 M.Ohtsuki
--        TO_CHAR(ADD_MONTHS(gd_process_date,-1),'MM')
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
        TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_process_date,-1),'MM'))
--//+UPD END   2009/06/10 T1_1399 M.Ohtsuki
    INTO
        gv_kakuteiym
    FROM
        DUAL;
    
    IF (gv_kakuteiym IS NULL) THEN
        RAISE global_api_expt;
    END IF;
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
                    name => lv_prf_cd_item
                   ,val  => lv_prf_cd_item_val
                   ); --政策群品目カテゴリ特定名
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
                    name => lv_prf_cd_margin_rate
                   ,val  => lv_prf_cd_margin_rate_val
                   ); -- 粗利益率
    FND_PROFILE.GET(
                    name => lv_prf_cd_make
                   ,val  => lv_prf_cd_make_val
                   ); -- 構成比
    FND_PROFILE.GET(
                    name => lv_prf_cd_result
                   ,val  => lv_prf_cd_result_val
                   ); -- 年実績
    FND_PROFILE.GET(
                    name => lv_prf_cd_plan
                   ,val  => lv_prf_cd_plan_val
                   ); --年計画  
    FND_PROFILE.GET(
                    name => lv_prf_cd_g2_make
                   ,val  => lv_prf_cd_g2_make_val
                   ); --群2桁構成比  
    FND_PROFILE.GET(
                    name => lv_prf_cd_kyoten_make
                   ,val  => lv_prf_cd_kyoten_make_val
                   ); --拠点計構成比                    
    
    -- =========================================================================
    -- プロファイル値取得に失敗した場合
    -- =========================================================================
    -- 政策群品目カテゴリ特定名
    IF (lv_prf_cd_item_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_item;
    -- 売上
    ELSIF (lv_prf_cd_sales_val IS NULL) THEN
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
        -- 粗利益率
    ELSIF (lv_prf_cd_margin_rate_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_margin_rate;
        -- 構成比
    ELSIF (lv_prf_cd_make_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_make;
        -- 年実績
    ELSIF (lv_prf_cd_result_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_result;
        -- 年計画
    ELSIF (lv_prf_cd_plan_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_plan;
        -- 群2桁構成比
    ELSIF (lv_prf_cd_g2_make_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_g2_make;
        -- 拠点計構成比
    ELSIF (lv_prf_cd_kyoten_make_val IS NULL) THEN
      lv_tkn_value := lv_prf_cd_kyoten_make;
    END IF;
    
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
  END init;
--

   /****************************************************************************
   * Procedure Name   : do_check
   * Description      : チェック処理            
   ****************************************************************************/
   PROCEDURE do_check (
         ov_errbuf     OUT NOCOPY VARCHAR2               -- 共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               -- リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              -- ユーザー・エラー・メッセージ
   IS

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
    
-- ===============================
-- 固定ローカル変数
-- ===============================
    -- 拠点コード
    lv_kyoten_cd              VARCHAR2(32); 
    
    -- データ存在チェック用
    ln_counts                 NUMBER(1,0) := 0;
    
  
--##################  固定ステータス初期化部 START   ###################
  BEGIN
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################


-- 拠点の存在チェック

  SELECT  
          base_name                               -- 部門名称
          ,base_code                              -- 部門コード
  INTO    
          gv_kyotennm
         ,lv_kyoten_cd
  FROM    
          xxcsm_loc_name_list_v                   -- 部門名称ビュー
  WHERE   
          base_code = gv_kyotencd;                -- 拠点コード
    
  --存在しない場合、エラーメッセージを出して、処理が中止します。                                
  IF (lv_kyoten_cd IS NULL ) THEN
    lv_retcode := cv_status_error;
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcsm                                -- アプリケーション短縮名
                  ,iv_name         => cv_csm1_msg_00024                           -- メッセージコード
                  ,iv_token_name1  => cv_tkn_kyotencd                         -- トークンコード1（拠点コード）
                  ,iv_token_value1 => gv_kyotenCD                             -- トークン値1
                 );
      lv_errbuf := lv_errmsg;
    RAISE global_api_others_expt;
  END IF;


-- =============================================================================
-- 実績データの存在チェック
-- =============================================================================
    --初期化
    ln_counts := 0;

    --実績データの抽出
    SELECT  
            count(1)
    INTO    
            ln_counts
    FROM    
            xxcsm_item_plan_result                  -- 年間販売計画用実績テーブル
    WHERE   
            (subject_year   = gv_taisyoYm -1        -- 前年度
    OR      subject_year    = gv_taisyoYm -2)       -- 前々年度
    AND     location_cd     = gv_kyotenCD           -- 拠点コード
    AND     rownum          = 1;                    -- 1行目
    
    -- 件数が0の場合、計画データの存在チェックを行います。                                
    IF (ln_counts = 0) THEN
--      
    -- =========================================================================
    -- 計画データの存在チェック
    -- =========================================================================
      -- 再設定
      ln_counts := 0;
  
      -- 計画データの抽出
      SELECT
                      count(1)
      INTO  
                      ln_counts
      FROM  
                      xxcsm_item_plan_lines plan_lines                          -- 商品計画ヘッダテーブル
                      ,xxcsm_item_plan_headers plan_headers                     -- 商品計画明細テーブル         
      WHERE 
               plan_lines.item_plan_header_id    = 
                                  plan_headers.item_plan_header_id              -- 商品計画ヘッダID
      AND       plan_headers.plan_year           = gv_taisyoYm -1               -- 前年度
      AND       plan_headers.location_cd         = gv_kyotenCD                  -- 拠点コード
      AND       rownum                           = 1;                           -- 1行目   
      
      -- 件数が0の場合、エラーメッセージを出して、処理が中止します。                                
      IF (ln_counts = 0) THEN
          lv_retcode := cv_status_error;
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                              -- アプリケーション短縮名
                      ,iv_name         => cv_csm1_msg_00099                         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_kyotencd                       -- トークンコード1（拠点コード）
                      ,iv_token_value1 => gv_kyotenCD                           -- トークン値1
                      ,iv_token_name2  => cv_tkn_year                           -- トークンコード2（対象年度）
                      ,iv_token_value2 => gv_taisyoYm                           -- トークン値2
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
      END IF;
      --    
    END IF;
--

--
--#################################  固定例外処理部  #############################
--
  EXCEPTION
    -- *** 拠点コードが存在しない場合 ***
    WHEN NO_DATA_FOUND THEN
      lv_retcode := cv_status_error;
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcsm                                -- アプリケーション短縮名
                  ,iv_name         => cv_csm1_msg_00024                           -- メッセージコード
                  ,iv_token_name1  => cv_tkn_kyotencd                         -- トークンコード1（拠点コード）
                  ,iv_token_value1 => gv_kyotenCD                             -- トークン値1
                 );
      lv_errbuf  := lv_errmsg;
      
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
  END do_check;
--

   /****************************************************************************
   * Procedure Name   : deal_plan_data
   * Description      : 計画データの詳細処理
   *                    ①データの抽出
   *                    ②データの算出
   *                    ③データの登録
   *****************************************************************************/
   PROCEDURE deal_plan_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_plan_data';        -- プログラム名
    cn_month                CONSTANT NUMBER         := 5;                       -- 初月(販売実績カレンダー)

    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_item_cd              VARCHAR2(10);               --品目コード
    lv_group_id             VARCHAR2(10);               --商品群コード
-- 年間    
    ln_y_sales              NUMBER  := 0;               --年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               --年間_粗利益額合計
    ln_y_amount             NUMBER  := 0;               --年間_数量合計
    ln_y_psa                NUMBER  := 0;               --年間_数量*定価の合計
    ln_y_rate               NUMBER  := 0;               --年間_掛率
    ln_y_margin_r           NUMBER  := 0;               --年間_粗利益率
    ln_h_rate               NUMBER  := 0;               --時期間_掛率
    ln_h_margin_r           NUMBER  := 0;               --時期間_粗利益率
    ln_y_make               NUMBER  := 0;               -- 年間_構成比
    ln_h_make               NUMBER  := 0;               -- 時期間_構成比
    
-- 時期間    
    ln_h_sales              NUMBER  := 0;               --時期間_売上金額合計
    ln_h_margin             NUMBER  := 0;               --時期間_粗利益額合計
    ln_h_amount             NUMBER  := 0;               --時期間_数量合計
    ln_h_psa                NUMBER  := 0;               --時期間_数量*定価の合計  
    
-- 群2桁・拠点      
    ln_yg_make              NUMBER  := 0;               --年間_群2桁_構成比
    ln_yk_make              NUMBER  := 0;               --年間_拠点_構成比
    ln_hg_make              NUMBER  := 0;               --時期間_群2桁_構成比
    ln_hk_make              NUMBER  := 0;               --時期間_拠点_構成比
    ln_g_sum                NUMBER  := 0;               --群2桁_売上合計
    ln_k_sum                NUMBER  := 0;               --拠点_売上合計    
    
--  一時変数  
    ln_year                 NUMBER  := 0;               --年度判断用変数
    ln_month                NUMBER  := 0;               --月判断用変数
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP判断用
       
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################

--============================================
--  データの抽出【計画】カーソル
--============================================
    CURSOR   
        get_sales_plan_data_cur
    IS
--//+DEL START 2009/07/10 障害0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 障害0000637 T.Tsukino
--//+ADD START 2009/07/10 障害0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 障害0000637 T.Tsukino
                 xiph.plan_year                         AS  year                     -- 対象年度
                ,xipl.month_no                          AS  month                    -- 月
                ,SUM(NVL(xipl.amount,0))                AS  amount                   -- 数量
                ,SUM(NVL(xipl.sales_budget,0))          AS  sales                    -- 売上金額
                ,SUM(NVL(xipl.amount_gross_margin,0))   AS  margin                   -- 粗利益額
                ,xipl.item_group_no                     AS  group_id                 -- 商品群コード
                ,xcgv.item_cd                           AS  item_id                  -- 品目コード
                ,xcgv.item_nm                           AS  item_nm                  -- 品目名称
                ,NVL(xcgv.now_unit_price,0)                  AS  price                    -- 定価
          FROM     
                xxcsm_item_plan_lines           xipl                                 -- 商品計画明細テーブル
                ,xxcsm_item_plan_headers        xiph                                 -- 商品計画ヘッダテーブル
                ,xxcsm_commodity_group2_v       xcgv                                 -- 政策群２ビュー
          WHERE    
                 xipl.item_plan_header_id          = xiph.item_plan_header_id        -- 商品計画ヘッダID
          AND   xcgv.item_cd                       = xipl.item_no                    -- 商品コード
          AND   xiph.plan_year                     = gv_taisyoYm - 1                 -- 前年度
          AND   xiph.location_cd                   = gv_kyotenCD                     -- 拠点コード
          GROUP BY
                   xiph.plan_year                      -- 対象年度
                  ,xipl.month_no                       -- 月
                  ,xipl.item_group_no                  -- 商品群コード
                  ,xcgv.item_cd                        -- 商品コード
                  ,xcgv.item_nm                        -- 商品名称
                  ,xcgv.now_unit_price                 -- 定価
          ORDER BY 
                    item_id    ASC                   -- 商品コード
                    ,year        ASC                  -- 対象年度
                    ,month      ASC                   -- 月
                    ,group_id   ASC                   -- 商品群コード
    ;

-- 群2桁計：売上合計
    CURSOR   
        get_group2_plan_data_cur(
                                in_year IN NUMBER
                                ,in_group_id IN VARCHAR2)
    IS
--//+DEL START 2009/07/10 障害0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 障害0000637 T.Tsukino
--//+ADD START 2009/07/10 障害0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 障害0000637 T.Tsukino
                SUM(NVL(xipl.sales_budget,0))      AS g2_sales                        -- 年間売上
            FROM     
                xxcsm_item_plan_lines             xipl                                -- 商品計画明細テーブル
                ,xxcsm_item_plan_headers          xiph                                -- 商品計画ヘッダテーブル
                ,xxcsm_commodity_group2_v         xcgv                                -- 政策群２ビュー
            WHERE    
                    xipl.item_plan_header_id         = xiph.item_plan_header_id       -- 商品計画ヘッダID
            AND     xiph.plan_year                   = in_year                        -- 対象年度
            AND     xipl.item_no                     = xcgv.item_cd                   -- 商品コード
            AND     xiph.location_cd                 = gv_kyotenCD                    -- 拠点コード
            AND     SUBSTR(xcgv.group2_cd,1,2)       = SUBSTR(in_group_id,1,2);
            
            
-- 拠点計：売上合計
    CURSOR   
        get_kyoten_plan_data_cur(in_year IN NUMBER)
    IS
            SELECT   
                  SUM(NVL(xipl.sales_budget,0))    AS kyoten_sales                       -- 年間売上
            FROM     
                  xxcsm_item_plan_lines       xipl                                     -- 商品計画明細テーブル
                  ,xxcsm_item_plan_headers    xiph                                     -- 商品計画ヘッダテーブル
            WHERE    
                  xipl.item_plan_header_id     = xiph.item_plan_header_id                -- 商品計画ヘッダID
            AND   xiph.plan_year               = in_year                                 -- 対象年度
            AND   xiph.location_cd             = gv_kyotenCD;                            -- 拠点コード            

--
  BEGIN
--

--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

-- ===========================================================================  
--【計画データ処理-START】
-- ===========================================================================
    lv_item_cd := NULL;
    
    <<get_sales_plan_data_cur_loop>>
    FOR rec_plan_data IN get_sales_plan_data_cur LOOP
        
        lb_loop_end := TRUE;
        
        -- 初期化(合計算出用)
        IF (lv_item_cd IS NULL) THEN
            -- 商品コード
            lv_item_cd      := rec_plan_data.item_id;
            
            -- 商品群コード
            lv_group_id     := rec_plan_data.group_id;
            
            -- 対象年度
            ln_year         := rec_plan_data.year;
--
            -- 年間売上
            ln_y_sales      := rec_plan_data.sales;
            -- 年間粗利益額
            ln_y_margin     := rec_plan_data.margin;
            -- 年間数量
            ln_y_amount     := rec_plan_data.amount;
            -- 年間数量*定価
            ln_y_psa        := rec_plan_data.amount * rec_plan_data.price;
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_plan_data.month <= gv_kakuteiym) AND (rec_plan_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_plan_data.month >= cn_month) OR (rec_plan_data.month <= gv_kakuteiym)) ) THEN
                -- 時期間売上
                ln_h_sales      := rec_plan_data.sales;
                -- 時期間粗利益額
                ln_h_margin     := rec_plan_data.margin;
                -- 時期間数量
                ln_h_amount     := rec_plan_data.amount;
                -- 時期間数量*定価
                ln_h_psa        := rec_plan_data.amount * rec_plan_data.price;
            END IF;
        
        -- 商品コードが変わった場合（次の商品）    
        ELSIF ((lv_item_cd <> rec_plan_data.item_id) OR (ln_year <> rec_plan_data.year)) THEN
        
            -- 群2桁計：売上合計
            <<get_group2_plan>>
            FOR rec IN get_group2_plan_data_cur(ln_year,lv_group_id) LOOP
                ln_g_sum := rec.g2_sales;
                
            END LOOP get_group2_plan;

            --年間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yg_make := 0;
            ELSE
                -- 商品_年間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
                ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
            END IF;

            
            --時期間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_h_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hg_make := 0;
            ELSE
                -- 商品_時期間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
                ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
            END IF;


            -- 拠点計：売上合計
            <<get_kyoten_plan>>
            FOR rec IN get_kyoten_plan_data_cur (ln_year) LOOP
                ln_k_sum := rec.kyoten_sales;
                
            END LOOP get_kyoten_plan;
        
            --年間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yk_make := 0;
            ELSE
                -- 商品_年間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
                ln_yk_make  := ROUND(ln_y_sales / ln_k_sum * 100,2);
            END IF;
             

            --時期間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hk_make := 0;
            ELSE
                -- 商品_時期間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
                ln_hk_make  := ROUND(ln_h_sales / ln_k_sum * 100,2);
            END IF;


            -- 年間_掛率/年間_粗利益率/年間_構成比:【算出処理】
            IF (ln_y_sales = 0) THEN
                ln_y_rate     := 0;
                ln_y_margin_r := 0;
                ln_y_make     := 0;
            ELSE
                -- 年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
                IF (ln_y_psa = 0) THEN
                  ln_y_rate     := 0;
                ELSE
                  ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
                
                -- 年間_構成比
                ln_y_make     := 100;
            END IF;
            
            -- 時期間_掛率/時期間_粗利益率/時期間_構成比:【算出処理】
            IF (ln_h_sales = 0) THEN
                ln_h_rate     := 0;
                ln_h_margin_r := 0;
                ln_h_make     := 0;
            ELSE
                -- 時期間_売上÷(時期間_数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
                IF (ln_h_psa = 0) THEN
                  ln_h_rate     := 0;
                ELSE
                  ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- 時期間_粗利益額÷(時期間_売上)*100 【小数点3桁四捨五入】
                ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
                
                -- 時期間_構成比
                ln_h_make     := 100;
            END IF;
            
            --==================================
            -- 算出した合計値をワークテーブルへ登録
            --==================================
            
            UPDATE
                    xxcsm_tmp_sales_plan_ref
            SET
-- 月間
                   y_sales          = ln_y_sales                                -- 年間売上
                  ,y_amount         = ln_y_amount                               -- 年間数量
                  ,y_rate           = ln_y_rate                                 -- 年間掛率
                  ,y_margin_rate    = ln_y_margin_r                             -- 年間粗利益率
                  ,y_margin         = ln_y_margin                               -- 年間粗利益額
-- 年間
                  ,h_sales          = ln_h_sales                                -- 時期間売上
                  ,h_amount         = ln_h_amount                               -- 時期間数量
                  ,h_rate           = ln_h_rate                                 -- 時期間掛率
                  ,h_margin_rate    = ln_h_margin_r                             -- 時期間粗利益率
                  ,h_margin         = ln_h_margin                               -- 時期間粗利益額
-- 時期間
                  ,yg_make          = ln_yg_make                                -- 年間群別構成比
                  ,yk_make          = ln_yk_make                                -- 年間拠点構成比
                  ,hg_make          = ln_hg_make                                -- 年間群別構成比
                  ,hk_make          = ln_hk_make                                -- 年間拠点構成比
                  ,g_sum            = ln_g_sum                                  -- 群別の合計
                  ,k_sum            = ln_k_sum                                  -- 拠点の合計
                  ,y_make           = ln_y_make                                 -- 年間構成比
                  ,h_make           = ln_h_make                                 -- 時期構成比
            WHERE
                    item_cd         = lv_item_cd                                -- 商品コード
            AND     year            = ln_year                                   -- 対象年度
            AND     flag            = 1;                                        -- 計画
            
            --===================================
            -- 次の商品にして、合計算出基準値を再設定
            --===================================
            -- 商品コード
            lv_item_cd      := rec_plan_data.item_id;
            
            -- 商品群コード
            lv_group_id     := rec_plan_data.group_id;
            
            -- 対象年度
            ln_year         := rec_plan_data.year;
  --
            -- 年間売上
            ln_y_sales      := rec_plan_data.sales;
            -- 年間粗利益額
            ln_y_margin     := rec_plan_data.margin;
            -- 年間数量
            ln_y_amount     := rec_plan_data.amount;
            -- 年間数量*定価
            ln_y_psa        := rec_plan_data.amount * rec_plan_data.price;
            
            
            -- 時期間売上
            ln_h_sales      := 0;
            -- 時期間粗利益額
            ln_h_margin     := 0;
            -- 時期間数量
            ln_h_amount     := 0;
            -- 時期間数量*定価
            ln_h_psa        := 0;
  --
            IF ((gv_kakuteiym >= cn_month) AND (rec_plan_data.month <= gv_kakuteiym) AND (rec_plan_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_plan_data.month >= cn_month) OR (rec_plan_data.month <= gv_kakuteiym)) ) THEN
                -- 時期間売上
                ln_h_sales      := rec_plan_data.sales;
                -- 時期間粗利益額
                ln_h_margin     := rec_plan_data.margin;
                -- 時期間数量
                ln_h_amount     := rec_plan_data.amount;
                -- 時期間数量*定価
                ln_h_psa        := rec_plan_data.amount * rec_plan_data.price;
            END IF;
            
        ELSIF ((lv_item_cd = rec_plan_data.item_id) AND (ln_year = rec_plan_data.year)) THEN
            --===================================
            -- 【同一年度の商品】年間累計を加算する
            --===================================
            -- 年間売上
            ln_y_sales      := ln_y_sales + rec_plan_data.sales;
            -- 年間粗利益額
            ln_y_margin     := ln_y_margin + rec_plan_data.margin;
            -- 年間数量
            ln_y_amount     := ln_y_amount + rec_plan_data.amount;
            -- 年間数量*定価
            ln_y_psa        := ln_y_psa + rec_plan_data.amount * rec_plan_data.price;
                    
            --===================================
            -- 【同一年度の商品】時期間累計を加算する
            --===================================
            IF ((gv_kakuteiym >= cn_month) AND (rec_plan_data.month <= gv_kakuteiym) AND (rec_plan_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_plan_data.month >= cn_month) OR (rec_plan_data.month <= gv_kakuteiym)) ) THEN
                    
                -- 時期間売上
                ln_h_sales      := ln_h_sales + rec_plan_data.sales;
                -- 時期間粗利益額
                ln_h_margin     := ln_h_margin + rec_plan_data.margin;
                -- 時期間数量
                ln_h_amount     := ln_h_amount + rec_plan_data.amount;
                -- 時期間数量*定価
                ln_h_psa        := ln_h_psa + rec_plan_data.amount * rec_plan_data.price;
            
            END IF;
        END IF;
        
        --===================================
        -- 【商品単位】月間データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_ref
          (
              toroku_no  --出力順
              ,group_cd        --商品群コード(2桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,year            --年度
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin_rate   --月間_粗利益率=月間_売上／月間_粗利益額*100
              ,m_margin        --月間_粗利益額
              ,flag            --データ区分
          )
          VALUES (
              gn_index
              ,rec_plan_data.group_id
              ,rec_plan_data.item_id
              ,rec_plan_data.item_nm
              ,rec_plan_data.year
              ,rec_plan_data.month
              ,rec_plan_data.sales
              ,rec_plan_data.amount
--//+UPD START 2009/02/16 CT024 K.Yamada
--              ,DECODE(rec_plan_data.sales,0,0,ROUND(rec_plan_data.sales / (rec_plan_data.amount * rec_plan_data.price) * 100,2))
              ,DECODE((rec_plan_data.amount * rec_plan_data.price), 0, 0,
                 ROUND(rec_plan_data.sales / (rec_plan_data.amount * rec_plan_data.price) * 100, 2))
--//+UPD END   2009/02/16 CT024 K.Yamada
              ,DECODE(rec_plan_data.sales,0,0,ROUND(rec_plan_data.margin / rec_plan_data.sales * 100,2))
              ,rec_plan_data.margin
              ,1
          );
          
          gn_index := gn_index + 1;
          
    END LOOP get_sales_plan_data_cur_loop;
    
    IF (lb_loop_end) THEN
        
        -- 群2桁計：売上合計
        <<get_group2_plan>>
        FOR rec IN get_group2_plan_data_cur(ln_year,lv_group_id) LOOP
            ln_g_sum := rec.g2_sales;
            
        END LOOP get_group2_plan;

        --年間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yg_make := 0;
        ELSE
            -- 商品_年間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
            ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
        END IF;

        
        --時期間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_h_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hg_make := 0;
        ELSE
            -- 商品_時期間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
            ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
        END IF;
                

        -- 拠点計：売上合計
        <<get_kyoten_plan>>
        FOR rec IN get_kyoten_plan_data_cur (ln_year) LOOP
            ln_k_sum := rec.kyoten_sales;
            
        END LOOP get_kyoten_plan;

        --年間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yk_make := 0;
        ELSE
            -- 商品_年間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
            ln_yk_make  := ROUND(ln_y_sales / ln_k_sum * 100,2);
        END IF;
         

          
        --時期間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hk_make := 0;
        ELSE
            -- 商品_時期間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
            ln_hk_make  := ROUND(ln_h_sales / ln_k_sum * 100,2);
        END IF;
                
                

        -- 年間_掛率/年間_粗利益率/年間_構成比:【算出処理】
        IF (ln_y_sales = 0) THEN
            ln_y_rate     := 0;
            ln_y_margin_r := 0;
            ln_y_make     := 0;
        ELSE
            -- 年間_売上÷(年間数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
            IF (ln_y_psa = 0) THEN
              ln_y_rate     := 0;
            ELSE
              ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            
            -- 年間_構成比
            ln_y_make     := 100;
        END IF;
        
        -- 時期間_掛率/時期間_粗利益率/時期間_構成比:【算出処理】
        IF (ln_h_sales = 0) THEN
            ln_h_rate     := 0;
            ln_h_margin_r := 0;
            ln_h_make     := 0;
        ELSE
            -- 時期間_売上÷(時期間_数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
            IF (ln_h_psa = 0) THEN
              ln_h_rate     := 0;
            ELSE
              ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- 時期間_粗利益額÷(時期間_売上)*100 【小数点3桁四捨五入】
            ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
            
            -- 時期間_構成比
            ln_h_make     := 100;
        END IF;
        
        --==================================
        -- 算出した合計値をワークテーブルへ登録
        --==================================
        
        UPDATE
                xxcsm_tmp_sales_plan_ref
        SET
-- 月間
               y_sales          = ln_y_sales                                -- 年間売上
              ,y_amount         = ln_y_amount                               -- 年間数量
              ,y_rate           = ln_y_rate                                 -- 年間掛率
              ,y_margin_rate    = ln_y_margin_r                             -- 年間粗利益率
              ,y_margin         = ln_y_margin                               -- 年間粗利益額
-- 年間
              ,h_sales          = ln_h_sales                                -- 時期間売上
              ,h_amount         = ln_h_amount                               -- 時期間数量
              ,h_rate           = ln_h_rate                                 -- 時期間掛率
              ,h_margin_rate    = ln_h_margin_r                             -- 時期間粗利益率
              ,h_margin         = ln_h_margin                               -- 時期間粗利益額
-- 時期間
              ,yg_make          = ln_yg_make                                -- 年間群別構成比
              ,yk_make          = ln_yk_make                                -- 年間拠点構成比
              ,hg_make          = ln_hg_make                                -- 年間群別構成比
              ,hk_make          = ln_hk_make                                -- 年間拠点構成比
              ,g_sum            = ln_g_sum                                  -- 群別の合計
              ,k_sum            = ln_k_sum                                  -- 拠点の合計
              ,y_make           = ln_y_make                                 -- 年間構成比
              ,h_make           = ln_h_make                                 -- 時期構成比
        WHERE
                item_cd         = lv_item_cd                                -- 商品コード
        AND     year            = ln_year                                   -- 対象年度
        AND     flag            = 1;                                        -- 計画
    END IF;

-- ===========================================================================  
--【計画データ処理-END】
-- ===========================================================================
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
      IF (get_sales_plan_data_cur%ISOPEN) THEN
        CLOSE get_sales_plan_data_cur;
      END IF;
      
      IF (get_group2_plan_data_cur%ISOPEN) THEN
        CLOSE get_group2_plan_data_cur;
      END IF;
      
      IF (get_kyoten_plan_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_plan_data_cur;
      END IF;
      
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================

      IF (get_sales_plan_data_cur%ISOPEN) THEN
        CLOSE get_sales_plan_data_cur;
      END IF;
      
      IF (get_group2_plan_data_cur%ISOPEN) THEN
        CLOSE get_group2_plan_data_cur;
      END IF;
      
      IF (get_kyoten_plan_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_plan_data_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END deal_plan_data;
--

   /****************************************************************************
   * Procedure Name   : deal_result_data
   * Description      : 実績データの詳細処理
   *                    ①データの抽出
   *                    ②データの算出
   *                    ③データの登録
   ****************************************************************************/
   PROCEDURE deal_result_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_result_data';      -- プログラム名
    cn_month                CONSTANT NUMBER         := 5;                       -- 初月(販売実績カレンダー側)

    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_item_cd              VARCHAR2(10);               -- 品目コード
    lv_group_id             VARCHAR2(10);               -- 商品群コード
    
    str_temp                VARCHAR2(2000);
-- 年間    
    ln_y_sales              NUMBER  := 0;               -- 1年間の売上金額合計
    ln_y_margin             NUMBER  := 0;               -- 1年間の粗利益額合計
    ln_y_amount             NUMBER  := 0;               -- 1年間の数量合計
    ln_y_psa                NUMBER  := 0;               -- 1年間の数量*定価の合計
    ln_y_rate               NUMBER  := 0;               -- 年間_掛率
    ln_y_margin_r           NUMBER  := 0;               -- 年間_粗利益率
    ln_y_make               NUMBER  := 0;               -- 年間_構成比
    ln_h_make               NUMBER  := 0;               -- 時期間_構成比

-- 時期間    
    ln_h_sales              NUMBER  := 0;               -- 時期間の売上金額合計
    ln_h_margin             NUMBER  := 0;               -- 時期間の粗利益額合計
    ln_h_amount             NUMBER  := 0;               -- 時期間の数量合計
    ln_h_psa                NUMBER  := 0;               -- 時期間の数量*定価の合計
    ln_h_rate               NUMBER  := 0;               -- 時期間_掛率
    ln_h_margin_r           NUMBER  := 0;               -- 時期間_粗利益率

-- 群2桁・拠点    
    ln_yg_make              NUMBER  := 0;               -- 年間群2桁構成比
    ln_yk_make              NUMBER  := 0;               -- 年間拠点構成比
    ln_hg_make              NUMBER  := 0;               -- 時期間群2桁構成比
    ln_hk_make              NUMBER  := 0;               -- 時期間拠点構成比
    ln_g_sum                NUMBER  := 0;               -- 群2桁売上合計
    ln_k_sum                NUMBER  := 0;               -- 拠点売上合計    
 
-- 一時変数     
    ln_year                 NUMBER  := 0;               -- 年度判断用変数
    ln_month                NUMBER  := 0;               -- 月判断用変数
    lb_loop_end             BOOLEAN := FALSE;            -- LOOP判断用

    
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################

--============================================
--  データの抽出【実績】ローカル・カーソル
--============================================
--                  
    CURSOR   
        get_sales_result_data_cur
    IS
--//+DEL START 2009/07/10 障害0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 障害0000637 T.Tsukino
--//+ADD START 2009/07/10 障害0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 障害0000637 T.Tsukino
             xipr.subject_year                      AS  year                        -- 対象年度
            ,xipr.month_no                          AS  month                       -- 月
            ,SUM(NVL(xipr.amount,0))                AS  amount                      -- 数量
            ,SUM(NVL(xipr.sales_budget,0))          AS  sales                       -- 売上金額
            ,SUM(NVL(xipr.amount_gross_margin,0))   AS  margin                      -- 粗利益額
            ,xipr.item_group_no                     AS  group_id                    -- 商品群コード
            ,xcgv.item_cd                           AS  item_id                     -- 品目コード
            ,xcgv.item_nm                           AS  item_nm                     -- 品目名称
            ,NVL(xcgv.now_unit_price,0)             AS  price                       -- 定価
        FROM     
            xxcsm_item_plan_result          xipr                                    -- 商品計画用販売実績テーブル
            ,xxcsm_commodity_group2_v       xcgv                                    -- 政策群２ビュー
        WHERE    
             xcgv.item_cd                               = xipr.item_no              -- 商品コード
        AND (xipr.subject_year                          = gv_taisyoYm-2             -- 前々年度
        OR   xipr.subject_year                          = gv_taisyoYm-1)             -- 前年度
        AND xipr.location_cd                            = gv_kyotenCD               -- 拠点コード
        GROUP BY
              xipr.subject_year                        -- 対象年度
              ,xipr.month_no                           -- 月
              ,xipr.item_group_no                      -- 商品群コード
              ,xcgv.item_cd                            -- 商品コード
              ,xcgv.item_nm                            -- 商品名称
              ,xcgv.now_unit_price                     -- 定価
        ORDER BY 
              item_id       ASC
              ,year         ASC
              ,month        ASC
              ,group_id     ASC
              ;

-- 群2桁計：売上合計
    CURSOR   
        get_group2_result_data_cur(
                                    in_year IN NUMBER
                                    ,in_group_id IN VARCHAR2)
    IS
--//+DEL START 2009/07/10 障害0000637 T.Tsukino
--          SELECT
--//+DEL END 2009/07/10 障害0000637 T.Tsukino
--//+ADD START 2009/07/10 障害0000637 T.Tsukino
          SELECT /*+ INDEX(xcgv.xsib XXCMM_SYSTEM_ITEMS_B_U01) */ 
--//+ADD END 2009/07/10 障害0000637 T.Tsukino
              SUM(NVL(xipr.sales_budget,0))       AS g2_sales                    -- 年間売上
        FROM     
              xxcsm_item_plan_result        xipr                                     -- 商品計画用販売実績テーブル
              ,xxcsm_commodity_group2_v     xcgv                                     -- 政策群２ビュー
        WHERE    
            xipr.item_no                 = xcgv.item_cd                          -- 商品コード
        AND xipr.subject_year            = in_year                               -- 対象年度
        AND xipr.location_cd             = gv_kyotenCD                           -- 拠点コード
        AND SUBSTR(xcgv.group2_cd,1,2)   = SUBSTR(in_group_id,1,2);              -- 商品群2桁コード



-- 拠点計：売上合計
    CURSOR   
        get_kyoten_result_data_cur(in_year IN NUMBER)
    IS
            SELECT   
                SUM(NVL(xipr.sales_budget,0))   AS kyoten_sales                       -- 年間売上
            FROM     
                xxcsm_item_plan_result            xipr                                 -- 商品計画用販売実績テーブル
            WHERE    
                 xipr.subject_year                = in_year                             -- 対象年度
            AND  xipr.location_cd                 = gv_kyotenCD;                        -- 拠点コード

            

--
  BEGIN
--

--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

-- ===========================================================================  
--【実績データ処理-START】
-- ===========================================================================
    lv_item_cd := NULL;
    <<get_sales_result_data_cur_loop>>
    -- 実績データ取得
    FOR rec_result_data IN get_sales_result_data_cur LOOP
        
        -- 判断用
        lb_loop_end := TRUE;
        
        -- 初期化
        IF (lv_item_cd IS NULL) THEN
            -- 商品コード
            lv_item_cd      := rec_result_data.item_id;
            
            -- 商品群コード
            lv_group_id     := rec_result_data.group_id;
            
            -- 対象年度
            ln_year         := rec_result_data.year;
--
            -- 年間売上
            ln_y_sales      := rec_result_data.sales;
            -- 年間粗利益額
            ln_y_margin     := rec_result_data.margin;
            -- 年間数量
            ln_y_amount     := rec_result_data.amount;
            -- 年間数量*定価
            ln_y_psa        := rec_result_data.amount * rec_result_data.price;
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_result_data.month <= gv_kakuteiym) AND (rec_result_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_result_data.month >= cn_month) OR (rec_result_data.month <= gv_kakuteiym)) ) THEN
                -- 時期間売上
                ln_h_sales      := rec_result_data.sales;
                -- 時期間粗利益額
                ln_h_margin     := rec_result_data.margin;
                -- 時期間数量
                ln_h_amount     := rec_result_data.amount;
                -- 時期間数量*定価
                ln_h_psa        := rec_result_data.amount * rec_result_data.price;
            END IF;
            
            -- 商品コードが変わった場合（次の商品）
        ELSIF ((lv_item_cd <> rec_result_data.item_id) OR (ln_year <> rec_result_data.year)) THEN
           
            -- 群2桁計：売上合計
            <<get_group2_result>>
            FOR rec IN get_group2_result_data_cur(ln_year,lv_group_id) LOOP
                ln_g_sum := rec.g2_sales;
                
            END LOOP get_group2_result;

            --年間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yg_make := 0;
            ELSE
                -- 商品_年間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
                ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
            END IF;

            
            -- 時期間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_h_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hg_make := 0;
            ELSE
                -- 商品_時期間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
                ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
            END IF;

            -- 拠点計：売上合計
            <<get_kyoten_result>>
            FOR rec IN get_kyoten_result_data_cur(ln_year) LOOP
                ln_k_sum := rec.kyoten_sales;
                
            END LOOP get_kyoten_result;


            -- 年間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_y_sales = 0) THEN
            IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_yk_make := 0;
            ELSE
            -- 商品_年間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
            ln_yk_make    := ROUND(ln_y_sales / ln_k_sum * 100);
            END IF;

            --時期間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--            IF (ln_h_sales = 0) THEN
            IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
                ln_hk_make    := 0;
            ELSE
                -- 商品_時期間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
                ln_hk_make    := ROUND(ln_h_sales / ln_k_sum * 100);
            END IF;
              
            
            -- 年間_掛率/年間_粗利益率/年間_構成比:【算出処理】
            IF (ln_y_sales = 0) THEN
                ln_y_rate     := 0;
                ln_y_margin_r := 0;
                ln_y_make     := 0;
            ELSE
                -- 年間_売上÷(年間_数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
                IF (ln_y_psa = 0) THEN
                  ln_y_rate     := 0;
                ELSE
                  ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
                
                -- 年間_構成比
                ln_y_make     := 100;
            END IF;
            
            -- 時期間_掛率/時期間_粗利益率/時期間_構成比:【算出処理】
            IF (ln_h_sales = 0) THEN
                ln_h_rate     := 0;
                ln_h_margin_r := 0;
                ln_h_make     := 0;
            ELSE
                -- 時期間_売上÷(時期間数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--                ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
                IF (ln_h_psa = 0) THEN
                  ln_h_rate     := 0;
                ELSE
                  ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
                END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
                
                -- 時期間_粗利益額÷(時期間_売上)*100 【小数点3桁四捨五入】
                ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
                
                -- 時期間_構成比
                ln_h_make     := 100;
            END IF;
            
            --==================================
            -- 算出した合計値をワークテーブルへ登録
            --==================================
            UPDATE
                    xxcsm_tmp_sales_plan_ref
            SET
-- 年間計
                  y_sales           = ln_y_sales                                -- 年間売上
                  ,y_amount         = ln_y_amount                               -- 年間数量
                  ,y_rate           = ln_y_rate                                 -- 年間掛率
                  ,y_margin_rate    = ln_y_margin_r                             -- 年間粗利益率
                  ,y_margin         = ln_y_margin                               -- 年間粗利益額

-- 時期計
                  ,h_sales          = ln_h_sales                                -- 時期間売上
                  ,h_amount         = ln_h_amount                               -- 時期間数量
                  ,h_rate           = ln_h_rate                                 -- 時期間掛率
                  ,h_margin_rate    = ln_h_margin_r                             -- 時期間粗利益率
                  ,h_margin         = ln_h_margin                               -- 時期間粗利益額
-- 群別・拠点計
                  ,hg_make          = ln_hg_make                                -- 時期間群別構成比
                  ,hk_make          = ln_hk_make                                -- 時期間拠点構成比
                  ,g_sum            = ln_g_sum                                  -- 群別の売上合計
                  ,k_sum            = ln_k_sum                                  -- 拠点別の売上合計
                  ,yg_make          = ln_yg_make                                -- 年間群別構成比
                  ,yk_make          = ln_yk_make                                -- 年間拠点構成比
                  ,y_make           = ln_y_make                                 -- 年間構成比
                  ,h_make           = ln_h_make                                 -- 時期間構成比
            WHERE
                    item_cd         = lv_item_cd                                -- 商品コード
            AND     year            = ln_year                                   -- 対象年度
            AND     flag            = 0;                                        -- 実績
            

            --===================================
            -- 次の商品にして、合計算出基準値を再設定
            --===================================
            -- 商品コード
            lv_item_cd      := rec_result_data.item_id;
            
            -- 商品群コード
            lv_group_id     := rec_result_data.group_id;
            
            -- 対象年度
            ln_year         := rec_result_data.year;
--
            -- 年間売上
            ln_y_sales      := rec_result_data.sales;
            -- 年間粗利益額
            ln_y_margin     := rec_result_data.margin;
            -- 年間数量
            ln_y_amount     := rec_result_data.amount;
            -- 年間数量*定価
            ln_y_psa        := rec_result_data.amount * rec_result_data.price;
            
            -- 時期間売上
            ln_h_sales      := 0;
            -- 時期間粗利益額
            ln_h_margin     := 0;
            -- 時期間数量
            ln_h_amount     := 0;
            -- 時期間数量*定価
            ln_h_psa        := 0;
            
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_result_data.month <= gv_kakuteiym) AND (rec_result_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_result_data.month >= cn_month) OR (rec_result_data.month <= gv_kakuteiym)) ) THEN
                -- 時期間売上
                ln_h_sales      := rec_result_data.sales;
                -- 時期間粗利益額
                ln_h_margin     := rec_result_data.margin;
                -- 時期間数量
                ln_h_amount     := rec_result_data.amount;
                -- 時期間数量*定価
                ln_h_psa        := rec_result_data.amount * rec_result_data.price;
            END IF;
            
        ELSIF (ln_year = rec_result_data.year) THEN
            --===================================
            -- 【同一年度の商品】年間累計を加算する
            --=================================== 
--
            -- 年間売上
            ln_y_sales      := ln_y_sales + rec_result_data.sales;
            -- 年間粗利益額
            ln_y_margin     := ln_y_margin + rec_result_data.margin;
            -- 年間数量
            ln_y_amount     := ln_y_amount + rec_result_data.amount;
            -- 年間数量*定価
            ln_y_psa        := ln_y_psa + rec_result_data.amount * rec_result_data.price;
                    
            --===================================
            -- 【同一年度の商品】時期間累計を加算する
            --===================================
--
            IF ((gv_kakuteiym >= cn_month) AND (rec_result_data.month <= gv_kakuteiym) AND (rec_result_data.month >= cn_month))
                    OR ((gv_kakuteiym < cn_month) AND ((rec_result_data.month >= cn_month) OR (rec_result_data.month <= gv_kakuteiym)) ) THEN
                    
                -- 時期間売上
                ln_h_sales      := ln_h_sales + rec_result_data.sales;
                -- 時期間粗利益額
                ln_h_margin     := ln_h_margin + rec_result_data.margin;
                -- 時期間数量
                ln_h_amount     := ln_h_amount + rec_result_data.amount;
                -- 時期間数量*定価
                ln_h_psa        := ln_h_psa + rec_result_data.amount * rec_result_data.price;
            
            END IF;
        END IF;
        
        --===================================
        --商品単位の月間データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_ref
          (
              toroku_no        --出力順
              ,group_cd        --商品群コード(2桁)
              ,item_cd         --商品コード
              ,item_nm         --商品名称
              ,year            --年度
              ,month_no        --月
              ,m_sales         --月間_売上
              ,m_amount        --月間_数量
              ,m_rate          --月間_掛率=月間_売上／（月間_数量*定価）*100
              ,m_margin_rate   --月間_粗利益率=月間_粗利益額／月間_売上*100
              ,m_margin        --月間_粗利益額
              ,flag            --データ区分
          )
          VALUES (
              gn_index
              ,rec_result_data.group_id
              ,rec_result_data.item_id
              ,rec_result_data.item_nm
              ,rec_result_data.year
              ,rec_result_data.month
              ,rec_result_data.sales
              ,rec_result_data.amount
              ,DECODE((rec_result_data.amount * rec_result_data.price),0,0,ROUND(rec_result_data.sales / (rec_result_data.amount * rec_result_data.price) * 100,2))
              ,DECODE(rec_result_data.sales,0,0,ROUND(rec_result_data.margin / rec_result_data.sales * 100,2))
              ,rec_result_data.margin
              ,0
          );
          gn_index := gn_index + 1;
          
    END LOOP get_sales_result_data_cur_loop;
    
    -- 最後データの場合
    IF (lb_loop_end) THEN
    
        -- 群2桁計：売上合計
        <<get_group2_result>>
        FOR rec IN get_group2_result_data_cur(ln_year,lv_group_id) LOOP
            ln_g_sum := rec.g2_sales;
            
        END LOOP get_group2_result;


        --年間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yg_make := 0;
        ELSE
            -- 商品_年間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
            ln_yg_make  := ROUND(ln_y_sales / ln_g_sum * 100,2);
        END IF;

        
        -- 時期間群2桁構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_h_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_g_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hg_make := 0;
        ELSE
            -- 商品_時期間売上÷群2桁_売上合計*100 【小数点3桁四捨五入】
            ln_hg_make  := ROUND(ln_h_sales / ln_g_sum * 100,2);
        END IF;


        -- 拠点計：売上合計
        <<get_kyoten_result>>
        FOR rec IN get_kyoten_result_data_cur(ln_year) LOOP
            ln_k_sum := rec.kyoten_sales;
            
        END LOOP get_kyoten_result;


        -- 年間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_y_sales = 0) THEN
        IF ((ln_y_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_yk_make := 0;
        ELSE
            -- 商品_年間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
            ln_yk_make    := ROUND(ln_y_sales / ln_k_sum * 100);
        END IF;

        --時期間拠点構成比
--//+UPD START 2009/02/16 CT024 K.Yamada
--        IF (ln_h_sales = 0) THEN
        IF ((ln_h_sales = 0) OR (ln_k_sum = 0)) THEN
--//+UPD END   2009/02/16 CT024 K.Yamada
            ln_hk_make    := 0;
        ELSE
            -- 商品_時期間売上÷拠点_売上合計*100 【小数点3桁四捨五入】
            ln_hk_make    := ROUND(ln_h_sales / ln_k_sum * 100);
        END IF;
          
        
        -- 年間_掛率/年間_粗利益率/年間_構成比:【算出処理】
        IF (ln_y_sales = 0) THEN
            ln_y_rate     := 0;
            ln_y_margin_r := 0;
            ln_y_make     := 0;
        ELSE
            -- 年間_売上÷(年間_数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100,2);
            IF (ln_y_psa = 0) THEN
              ln_y_rate     := 0;
            ELSE
              ln_y_rate     := ROUND(ln_y_sales / ln_y_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            
            -- 年間_構成比
            ln_y_make     := 100;
        END IF;
        
        -- 時期間_掛率/時期間_粗利益率/時期間_構成比:【算出処理】
        IF (ln_h_sales = 0) THEN
            ln_h_rate     := 0;
            ln_h_margin_r := 0;
            ln_h_make     := 0;
        ELSE
            -- 時期間_売上÷(時期間数量*定価)*100 【小数点3桁四捨五入】
--//+UPD START 2009/02/16 CT024 K.Yamada
--            ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100,2);
            IF (ln_h_psa = 0) THEN
              ln_h_rate     := 0;
            ELSE
              ln_h_rate     := ROUND(ln_h_sales / ln_h_psa * 100, 2);
            END IF;
--//+UPD END   2009/02/16 CT024 K.Yamada
            
            -- 時期間_粗利益額÷(時期間_売上)*100 【小数点3桁四捨五入】
            ln_h_margin_r := ROUND(ln_h_margin / ln_h_sales * 100,2);
            
            -- 時期間_構成比
            ln_h_make     := 100;
        END IF;
        
        UPDATE
                xxcsm_tmp_sales_plan_ref
        SET
    -- 年間計
              y_sales           = ln_y_sales                                -- 年間売上
              ,y_amount         = ln_y_amount                               -- 年間数量
              ,y_rate           = ln_y_rate                                 -- 年間掛率
              ,y_margin_rate    = ln_y_margin_r                             -- 年間粗利益率
              ,y_margin         = ln_y_margin                               -- 年間粗利益額

    -- 時期計
              ,h_sales          = ln_h_sales                                -- 時期間売上
              ,h_amount         = ln_h_amount                               -- 時期間数量
              ,h_rate           = ln_h_rate                                 -- 時期間掛率
              ,h_margin_rate    = ln_h_margin_r                             -- 時期間粗利益率
              ,h_margin         = ln_h_margin                               -- 時期間粗利益額
    -- 群別・拠点計
              ,hg_make          = ln_hg_make                                -- 時期間群別構成比
              ,hk_make          = ln_hk_make                                -- 時期間拠点構成比
              ,g_sum            = ln_g_sum                                  -- 群別の売上合計
              ,k_sum            = ln_k_sum                                  -- 拠点別の売上合計
              ,yg_make          = ln_yg_make                                -- 年間群別構成比
              ,yk_make          = ln_yk_make                                -- 年間拠点構成比
              ,y_make           = ln_y_make                                 -- 年間構成比
              ,h_make           = ln_h_make                                 -- 時期間構成比
        WHERE
                item_cd         = lv_item_cd                                -- 商品コード
        AND     year            = ln_year                                   -- 対象年度
        AND     flag            = 0;                                        -- 実績
    END IF;

-- ===========================================================================  
--【実績データ処理-END】
-- ===========================================================================
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
      IF (get_sales_result_data_cur%ISOPEN) THEN
        CLOSE get_sales_result_data_cur;
      END IF;
      
      IF (get_group2_result_data_cur%ISOPEN) THEN
        CLOSE get_group2_result_data_cur;
      END IF;
      
      IF (get_kyoten_result_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_result_data_cur;
      END IF;
      

    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================

      IF (get_sales_result_data_cur%ISOPEN) THEN
        CLOSE get_sales_result_data_cur;
      END IF;
      
      IF (get_group2_result_data_cur%ISOPEN) THEN
        CLOSE get_group2_result_data_cur;
      END IF;
      
      IF (get_kyoten_result_data_cur%ISOPEN) THEN
        CLOSE get_kyoten_result_data_cur;
      END IF;
--
--#####################################  固定部 END   ###########################
--
  END deal_result_data;
--


  /*****************************************************************************
   * Procedure Name   : write_Line_Info
   * Description      : 商品コード毎に情報を出力
   ****************************************************************************/
  PROCEDURE write_Line_Info(
    in_item_cd    IN  VARCHAR2                                                  -- 商品コード
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                           -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                           -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                           -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    
    cv_prg_name   CONSTANT VARCHAR2(100) := 'write_Line_Info';    -- プログラム名 
    
--#####################  固定ローカル変数宣言部 START   ###########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   #####################################

    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    
    -- 月間：データ・検索文
    lv_month_sql                VARCHAR2(2000);
    
    -- 合計（年間、時期間）：データ・検索文
    lv_sum_sql                  VARCHAR2(2000);
    
    -- ボディヘッダ情報（商品CD-商品群CD｜商品名称）
    lv_line_head                VARCHAR2(2000);
    
    -- 月情報（5月|6月|7月|8月|9月|10月|11月|12月|1月|2月|3月|04月）
    lv_line_info                VARCHAR2(4000);
    
    -- 項目名称
    lv_item_info                VARCHAR2(4000);
    
    -- LOOP処理用
    in_param                    NUMBER := 0;
    lb_loop_end                 BOOLEAN := FALSE;
--//+ADD START 2009/05/25 T1_1020  M.Ohtsuki
    ln_cnt                      NUMBER;
    ln_flag                     NUMBER;
--//+ADD END   2009/05/25 T1_1020  M.Ohtsuki
    
    -- テンプ変数
    lv_temp_month               VARCHAR2(4000);
    lv_temp_sum                 VARCHAR2(4000);
    
    cv_all_zero         CONSTANT VARCHAR2(100)     := '0,0,0,0,0,0,0,0,0,0,0,0,0,0' || CHR(10);
    cv_year_zz_r        CONSTANT VARCHAR2(100)     := SUBSTR(TO_CHAR(gv_taisyoYm-2),3,4) || lv_prf_cd_result_val;
    cv_year_z_r         CONSTANT VARCHAR2(100)     := SUBSTR(TO_CHAR(gv_taisyoYm-1),3,4) || lv_prf_cd_result_val;
    cv_year_z_p         CONSTANT VARCHAR2(100)     := SUBSTR(TO_CHAR(gv_taisyoYm-1),3,4) || lv_prf_cd_plan_val;
    cv_year_zero        CONSTANT VARCHAR2(10)      := '0,0' || CHR(10);
-- 月計カーソル
    CURSOR get_month_data_cur(
                        in_param IN NUMBER
                        ,in_taisyo_ym IN NUMBER
                        ,in_item_cd IN VARCHAR2
                        ,in_flag IN NUMBER
                        )
    IS 
      SELECT
            DECODE(in_param
--//+UPD START 2009/02/18   CT027 K.Sai
--                       ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0)/1000,2) || cv_msg_comma               -- 売上【月】
--                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0)/1000,2) || cv_msg_comma
                       ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0)  ),0)/1000,0) || cv_msg_comma               -- 売上【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0)/1000,0) || cv_msg_comma
--//+UPD END 2009/02/18   CT027 K.Sai
                       ,1,NVL(SUM(DECODE(month_no,5,m_rate,0)  ),0) || cv_msg_comma                -- 掛率【月】
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
                       ,2,NVL(SUM(DECODE(month_no,5,m_amount,0)  ),0) || cv_msg_comma              -- 数量【月】
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
                       ,3,NVL(SUM(DECODE(month_no,5,m_margin_rate,0)  ),0) || cv_msg_comma         -- 粗利益率【月】
                          || NVL(SUM(DECODE(month_no,6,m_margin_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,m_margin_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,m_margin_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,m_margin_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,m_margin_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,m_margin_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,m_margin_rate,0) ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,m_margin_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,m_margin_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,m_margin_rate,0)  ),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,m_margin_rate,0)  ),0) || cv_msg_comma
--//+UPD START 2009/02/18   CT027 K.Sai
--                       ,4,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0)/1000,2) || cv_msg_comma              -- 粗利益額【月】
--                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0)/1000,2) || cv_msg_comma
--                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0)/1000,2) || cv_msg_comma
                       ,4,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0)/1000,0) || cv_msg_comma              -- 粗利益額【月】
                          || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0)/1000,0) || cv_msg_comma
                          || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0)/1000,0) || cv_msg_comma
--//+UPD END 2009/02/18   CT027 K.Sai
--//+UPD START 2009/02/16 CT024 K.Yamada
--                       ,5,NVL(SUM(DECODE(month_no,5,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma        -- 構成比【月】
--                          || NVL(SUM(DECODE(month_no,6,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,7,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,8,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,9,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,10,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,11,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,12,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,1,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,2,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,3,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,4,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                       ,5,NVL(SUM(DECODE(month_no,5,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma        -- 構成比【月】
                          || NVL(SUM(DECODE(month_no,6,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,DECODE(y_sales,0,0,ROUND(m_sales / y_sales * 100,2)),0)),0)  || cv_msg_comma
--//+UPD END   2009/02/16 CT024 K.Yamada
--//+UPD START 2009/02/16 CT024 K.Yamada
--                       ,6,NVL(SUM(DECODE(month_no,5, DECODE(m_sales,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma               -- 群2桁構成比【月】
--                          || NVL(SUM(DECODE(month_no,6, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,7, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,8, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,9, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,10,DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,11,DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,12,DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,1, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,2, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,3, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,4, DECODE(M_SALES,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                       ,6,NVL(SUM(DECODE(month_no,5, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma               -- 群2桁構成比【月】
                          || NVL(SUM(DECODE(month_no,6, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4, DECODE(g_sum,0,0,ROUND(m_sales / g_sum * 100,2)),0)),0) || cv_msg_comma
--//+UPD END   2009/02/16 CT024 K.Yamada
--//+UPD START 2009/02/16 CT024 K.Yamada
--                       ,7,NVL(SUM(DECODE(month_no,5,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma                -- 拠点構成比【月】
--                          || NVL(SUM(DECODE(month_no,6,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,7,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,8,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,9,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,10,DECODE(m_saleS,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,11,DECODE(m_saleS,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,12,DECODE(m_saleS,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,1,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,2,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,3,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--                          || NVL(SUM(DECODE(month_no,4,DECODE(m_sales,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                       ,7,NVL(SUM(DECODE(month_no,5,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma                -- 拠点構成比【月】
                          || NVL(SUM(DECODE(month_no,6,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,7,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,8,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,9,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,10,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,11,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,12,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,1,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,2,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,3,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
                          || NVL(SUM(DECODE(month_no,4,DECODE(k_sum,0,0,ROUND(m_sales / k_sum * 100,2)),0)),0) || cv_msg_comma
--//+UPD END   2009/02/16 CT024 K.Yamada
                       ,NULL) AS month_data
      FROM  
            xxcsm_tmp_sales_plan_ref       -- 商品計画参考資料ワークテーブル
      WHERE
            year        = in_taisyo_ym    -- 対象度
      AND   item_cd     = in_item_cd      -- 商品コード
      AND   flag        = in_flag;
      
-- 年計カーソル
    CURSOR  get_year_data_cur(
                        in_param IN NUMBER
                        ,in_taisyo_ym IN NUMBER
                        ,in_item_cd IN VARCHAR2
                        ,in_flag IN NUMBER
                        )
    IS
      SELECT   DISTINCT
               DECODE(in_param
--//+UPD START 2009/02/18   CT027 K.Sai
--                    ,0,ROUND(y_sales/1000,2) || cv_msg_comma || ROUND(h_sales/1000,2) || CHR(10)                    -- 売上合計
                    ,0,ROUND(y_sales/1000,0) || cv_msg_comma || ROUND(h_sales/1000,0) || CHR(10)                    -- 売上合計
--//+UPD END 2009/02/18   CT027 K.Sai
                    ,1,y_rate || cv_msg_comma || h_rate || CHR(10)                      -- 掛率合計
                    ,2,y_amount || cv_msg_comma || h_amount || CHR(10)                  -- 数量合計
                    ,3,y_margin_rate || cv_msg_comma || h_margin_rate || CHR(10)        -- 粗利益率合計
--//+UPD START 2009/02/18   CT027 K.Sai
--                    ,4,ROUND(y_margin/1000,2) || cv_msg_comma || ROUND(h_margin/1000,2) || CHR(10)                  -- 粗利益額合計
                    ,4,ROUND(y_margin/1000,0) || cv_msg_comma || ROUND(h_margin/1000,0) || CHR(10)                  -- 粗利益額合計
--//+UPD END 2009/02/18   CT027 K.Sai
                    ,5,y_make || cv_msg_comma || h_make || CHR(10)                            -- 構成比合計
--//+UPD START 2009/02/16 CT024 K.Yamada
--                    ,6,DECODE(y_sales,0,0,ROUND(y_sales / g_sum * 100,2)) || cv_msg_comma     -- 群2桁構成比合計
--                      || DECODE(h_sales,0,0,ROUND(h_sales / g_sum * 100,2)) || CHR(10)
--                    ,7,DECODE(y_sales,0,0,ROUND(y_sales / k_sum * 100,2)) || cv_msg_comma     -- 拠点構成比合計
--                      || DECODE(h_sales,0,0,ROUND(h_sales / k_sum * 100,2)) || CHR(10)
                    ,6,DECODE(g_sum,0,0,ROUND(y_sales / g_sum * 100,2)) || cv_msg_comma     -- 群2桁構成比合計
                      || DECODE(g_sum,0,0,ROUND(h_sales / g_sum * 100,2)) || CHR(10)
                    ,7,DECODE(k_sum,0,0,ROUND(y_sales / k_sum * 100,2)) || cv_msg_comma     -- 拠点構成比合計
                      || DECODE(k_sum,0,0,ROUND(h_sales / k_sum * 100,2)) || CHR(10)
--//+UPD END   2009/02/16 CT024 K.Yamada
                    ,NULL) AS year_data
      FROM  
            xxcsm_tmp_sales_plan_ref       -- 商品計画参考資料ワークテーブル
      WHERE
            year        = in_taisyo_ym    -- 対象度
      AND   item_cd     = in_item_cd      -- 商品コード
      AND   flag        = in_flag;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- 初期化
    lv_line_head := NULL;
    lv_line_info := NULL;
    lv_item_info := NULL;
--//+ADD START 2009/05/25 T1_1020 M.Ohtsuki
    ln_cnt  := 0;
    ln_flag := 0;
--************************************************************************************
--*****ワークテーブルのデータが実績、計画で商品群コードの持ち方に差異がある為   ******
--*****実績データが存在する場合は実績の商品群コード(4桁),                       ******
--*****計画データのみ存在する場合は、計画データの商品群コード(3桁)を出力します。******
--************************************************************************************
    SELECT COUNT(1)                                                                                 -- 実績データ件数
    INTO   ln_cnt
    FROM   xxcsm_tmp_sales_plan_ref                                                                 -- 商品計画参考資料ワークテーブル
    WHERE  item_cd = in_item_cd                                                                     -- 品目コード
    AND    flag = 0                                                                                 -- ( 0 = 実績データ)
    AND    ROWNUM = 1;
--
    IF (ln_cnt = 1) THEN                                                                            --実績データが存在する場合
      ln_flag := 0;
    ELSE                                                                                            --計画データのみ存在する場合
      ln_flag := 1;
    END IF;
--//+ADD END   2009/05/25 T1_1020  M.Ohtsuki
    --  商品コード-商品群コード|商品名の抽出
    SELECT DISTINCT
            cv_msg_duble || 
--//+UPD START 2010/12/13 E_本稼動_05803 Y.Kanami
--            item_cd      || 
--            cv_msg_hafu  || 
--            group_cd     || 
            group_cd     || 
            cv_msg_hafu  || 
            item_cd      || 
--//+UPD END 2010/12/13 E_本稼動_05803 Y.Kanami
            cv_msg_duble || 
            cv_msg_comma || 
            cv_msg_duble || 
            item_nm      || 
            cv_msg_duble || 
            cv_msg_comma 
    INTO
            lv_line_head
    FROM     
            xxcsm_tmp_sales_plan_ref           -- 商品計画参考資料ワークテーブル
    WHERE
            item_cd = in_item_cd
--//+ADD START 2009/05/25 T1_1020 M.Ohtsuki
    AND     flag = ln_flag;                                                                         -- (実績=0、計画=1)
--//+ADD END   2009/05/25 T1_1020 M.Ohtsuki
--========================================================================= 
--  0:売上・1:掛率・2:数量・3:粗利益率・4:粗利益額・5:構成比・6:群2桁構成比・7:拠点計構成比
--=========================================================================
      <<line_loop>>
      WHILE (in_param < 8 ) LOOP
              
          IF (in_param = 0) THEN
              
              -- 売上【項目名】
              lv_item_info := cv_msg_duble || lv_prf_cd_sales_val || cv_msg_duble || cv_msg_comma;
                      
          ELSIF (in_param = 1) THEN
              
              -- 掛率【項目名】
              lv_item_info := cv_msg_duble || lv_prf_cd_rate_val || cv_msg_duble || cv_msg_comma;    
                      
          ELSIF (in_param = 2) THEN
              
              -- 数量【項目名】
              lv_item_info := cv_msg_duble || lv_prf_cd_amount_val || cv_msg_duble || cv_msg_comma;
                          
          ELSIF (in_param = 3) THEN
              
              -- 粗利益率【項目名】
              lv_item_info := cv_msg_duble || lv_prf_cd_margin_rate_val || cv_msg_duble || cv_msg_comma;
                          
          ELSIF (in_param = 4) THEN
              
              -- 粗利益額【項目名】
              lv_item_info := cv_msg_duble || lv_prf_cd_margin_val || cv_msg_duble || cv_msg_comma;
                          
          ELSIF (in_param = 5) THEN
              
              -- 構成比【項目名】
              lv_item_info := cv_msg_duble || lv_prf_cd_make_val || cv_msg_duble || cv_msg_comma;
                                              
                -- 群2桁構成比・拠点計構成比
          ELSIF (in_param = 6) THEN
                
                -- 群2桁構成比【項目名】
                lv_item_info := cv_msg_duble || lv_prf_cd_g2_make_val || cv_msg_duble || cv_msg_comma;
                        
          ELSIF (in_param = 7) THEN
                
                -- 拠点計構成比【項目名】
                lv_item_info := cv_msg_duble || lv_prf_cd_kyoten_make_val || cv_msg_duble || cv_msg_comma;
          END IF;    
          
          IF (in_param = 0) THEN
                -- 第一行の場合、商品コード_商品群コード|商品名
                lv_line_info := lv_line_info || lv_line_head || lv_item_info;
          ELSE
                -- 第一行以外の場合、空白|空白|商品名
                lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info;
          END IF;
          
          --=========================================================================   
          --  前々年度実績【0:売上・1:掛率・2:数量・3:粗利益率・4:粗利益額・5:構成比】
          --=========================================================================
          IF (in_param < 6) THEN
              
              --初期化
              lv_temp_month := NULL;
              lv_temp_sum   := NULL;
              
              <<zzm_result_loop>>  -- 前々年度実績（月計）
              FOR rec IN get_month_data_cur(in_param,gv_taisyoYm - 2,in_item_cd,0) LOOP
                  lb_loop_end := TRUE;
                  
                  lv_temp_month := rec.month_data;
                  
              END LOOP zzm_result_loop;

              IF (lb_loop_end) THEN
                 
                 
                 <<zzy_result_loop>>  -- 前々年度実績(年計)
                  FOR rec IN get_year_data_cur(in_param,gv_taisyoYm - 2,in_item_cd,0) LOOP
                      lb_loop_end := FALSE;
                      
                      lv_temp_sum := rec.year_data;
                  END LOOP zzy_result_loop;                  

                  IF (lb_loop_end) THEN
                      lv_temp_sum := cv_year_zero;
                  END IF;
                  
                  -- 1行のデータ：（商品CD_商品群CD｜商品名|項目名称）＋ （年度実績）＋（5月04月）＋（年間計｜時期計）        
                  lv_line_info := lv_line_info || cv_msg_duble || cv_year_zz_r || cv_msg_duble || cv_msg_comma || lv_temp_month || lv_temp_sum;
                  
              ELSE
                    lv_line_info := lv_line_info ||  cv_all_zero;
              END IF;
          --=========================================================================   
          --  前年度計画【0:売上・1:掛率・2:数量・3:粗利益率・4:粗利益額・5:構成比】
          --=========================================================================
          
              --初期化
              lv_temp_month := NULL;
              lv_temp_sum   := NULL;
              lb_loop_end   := FALSE;
              
              -- 第一行以外の場合、空白|空白|商品名
              lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info;
        
              
              <<zm_plan_loop>>  -- 前年度計画(月計)
              FOR rec IN get_month_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,1) LOOP
                  lb_loop_end := TRUE;
                  
                  lv_temp_month := rec.month_data;
                  
              END LOOP zm_plan_loop;

              IF (lb_loop_end) THEN
                 
                 <<zy_plan_loop>>  -- 前年度計画(年計)
                  FOR rec IN get_year_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,1) LOOP
                      lb_loop_end := FALSE;
                      
                      lv_temp_sum := rec.year_data;
                  END LOOP zy_plan_loop;

                  IF (lb_loop_end) THEN
                      lv_temp_sum := cv_year_zero;
                  END IF;
                  
                  -- 1行のデータ：（商品CD_商品群CD｜商品名|項目名称）＋ （年度実績）＋（5月04月）＋（年間計｜時期計）        
                  lv_line_info := lv_line_info || cv_msg_duble || cv_year_z_p || cv_msg_duble || cv_msg_comma || lv_temp_month || lv_temp_sum;
                  
              ELSE
                    lv_line_info := lv_line_info ||  cv_all_zero;
              END IF;
          END IF;
          --=========================================================================   
          --  前年度実績【0:売上・1:掛率・2:数量・3:粗利益率・4:粗利益額・5:構成比・6:群2桁構成比・7:拠点計構成比】
          --=========================================================================
          --初期化
          lv_temp_month := NULL;
          lv_temp_sum   := NULL;
          lb_loop_end   := FALSE;
          
          IF (in_param < 6) THEN
              -- 第一行以外の場合、空白|空白|商品名
              lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info;
          END IF;

          <<zm_result_loop>>  -- 前年度実績(月計)
          FOR rec IN get_month_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,0) LOOP
              lb_loop_end := TRUE;
              
              lv_temp_month := rec.month_data;
              
          END LOOP zm_result_loop;

          IF (lb_loop_end) THEN
            
             <<zy_result_loop>>  -- 前年度実績(年計)
              FOR rec IN get_year_data_cur(in_param,gv_taisyoYm - 1,in_item_cd,0) LOOP
                  lb_loop_end := FALSE;
                  
                  lv_temp_sum := rec.year_data;
              END LOOP zy_result_loop;                  

              IF (lb_loop_end) THEN
                  lv_temp_sum := cv_year_zero;
              END IF;
              
              -- 1行のデータ：（商品CD_商品群CD｜商品名|項目名称）＋ （年度実績）＋（5月04月）＋（年間計｜時期計）        
              lv_line_info := lv_line_info || cv_msg_duble || cv_year_z_r || cv_msg_duble || cv_msg_comma || lv_temp_month || lv_temp_sum;
              
          ELSE
                lv_line_info := lv_line_info ||  cv_all_zero;
          END IF;
              -- 次の項目
          in_param := in_param + 1;
              
     END LOOP line_loop;
    
    -- ボディ情報の出力
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_line_info
                     );

--#################################  固定例外処理部  #############################
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_month_data_cur%ISOPEN) THEN
         CLOSE get_month_data_cur;
      END IF;
      
      IF (get_year_data_cur%ISOPEN) THEN
         CLOSE get_year_data_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_month_data_cur%ISOPEN) THEN
         CLOSE get_month_data_cur;
      END IF;
      
      IF (get_year_data_cur%ISOPEN) THEN
         CLOSE get_year_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      
      IF (get_month_data_cur%ISOPEN) THEN
         CLOSE get_month_data_cur;
      END IF;
      
      IF (get_year_data_cur%ISOPEN) THEN
         CLOSE get_year_data_cur;
      END IF;
        
--#####################################  固定部 END   ###########################
  END write_Line_Info;
--

   /****************************************************************************
   * Procedure Name   : write_csv_file
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
    
    -- ヘッダ情報
    lv_data_head                VARCHAR2(4000);
    
    -- 商品群4桁単位情報
    lv_data_line                VARCHAR2(4000);
        
    -- 商品コード
    lv_item_cd                  VARCHAR2(10);
                                      
--============================================
--  商品コード抽出【カーソル】
--============================================ 
    CURSOR  
            get_item_cd_cur
        IS
--//+UPD START 2011/03/29 Ver1.7
--          SELECT
----//+UPD START 2010/12/13 E_本稼動_05803 Y.Kanami
----                  DISTINCT(item_cd)
--                  DISTINCT group_cd
--                         , item_cd
----//+UPD END 2010/12/13 E_本稼動_05803 Y.Kanami
--          FROM     
--                  xxcsm_tmp_sales_plan_ref         -- 商品計画参考資料ワークテーブル
----//+UPD START 2010/12/13 E_本稼動_05803 Y.Kanami
----          ORDER BY item_cd ASC;
--          ORDER BY group_cd ASC
--                 , item_cd ASC;
----//+UPD END 2010/12/13 E_本稼動_05803 Y.Kanami
      SELECT  DISTINCT
              CASE  WHEN  nic.attribute3 IS NOT NULL  THEN  tspr.group_cd
                    ELSE  cgv4.group4_cd
              END                 group_code
            , tspr.item_cd        item_cd
      FROM    xxcsm_tmp_sales_plan_ref      tspr
            , xxcsm_commodity_group4_v      cgv4
            , ( SELECT  DISTINCT  icv.attribute3
                FROM    xxcsm_item_category_v   icv
                WHERE   icv.attribute3  IS NOT NULL
              )   nic
      WHERE   tspr.item_cd        =   cgv4.item_cd
      AND     tspr.item_cd        =   nic.attribute3(+)
      ORDER BY
              group_code        ASC
            , tspr.item_cd      ASC;
--//+UPD END   2011/03/29 Ver1.7
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
                     ,iv_name         => cv_csm1_msg_00107                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- トークンコード1（拠点コード）
                     ,iv_token_value1 => gv_kyotenCD                            -- トークン値1
                     ,iv_token_name2  => cv_tkn_kyotennm                        -- トークンコード2（拠点コード名称）
                     ,iv_token_value2 => gv_kyotennm                            -- トークン値2
                     ,iv_token_name3  => cv_tkn_year                            -- トークンコード3（対象年度）
                     ,iv_token_value3 => gv_taisyoYm                            -- トークン値3
                     ,iv_token_name4  => cv_tkn_sysdate                         -- トークンコード4（業務日付）
--//+UPD START 2009/02/18   K.Sai
--                     ,iv_token_value4 => gd_process_date                        -- トークン値4
                     ,iv_token_value4  => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI')   -- トークン値4
--//+UPD END 2009/02/18   K.Sai
                     ,iv_token_name5  => cv_tkn_planym                          -- トークンコード5（計画年度）
                     ,iv_token_value5 => gv_planYm                              -- トークン値5
                     ,iv_token_name6  => cv_tkn_kakuteiym                       -- トークンコード6（確定年月）
                     ,iv_token_value6 => gv_kakuteiym                           -- トークン値6
                     );
     -- ヘッダ情報の出力
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_data_head || CHR(10)
                     );
    -- =========================================================================
    -- ボディ情報の出力
    -- =========================================================================
    <<csv_loop>>
    FOR rec IN get_item_cd_cur LOOP
    
        -- 商品コード
        lv_item_cd := rec.ITEM_CD;
        
        -- 対象件数【加算】
        gn_target_cnt := gn_target_cnt + 1;
        
        lv_data_line := NULL;
        
        -- 商品コード単位でボディ情報を出力（write_Line_Infoを呼び出す）        
        write_Line_Info(
                      lv_item_cd
                      ,lv_errbuf
                      ,lv_retcode
                      ,lv_errmsg
                      );
         
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          
          -- メッセージを出力
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
        -- 正常件数【加算】  
        ELSIF (lv_retcode = cv_status_normal) THEN
          gn_normal_cnt := gn_normal_cnt + 1 ;            
        END IF;
      
    END LOOP csv_loop;

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
      IF (get_item_cd_cur%ISOPEN) THEN
        CLOSE get_item_cd_cur;
      END IF;
      

    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_item_cd_cur%ISOPEN) THEN
        CLOSE get_item_cd_cur;
      END IF;

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
    ov_errbuf     OUT NOCOPY VARCHAR2                                           -- エラー・メッセージ
   ,ov_retcode    OUT NOCOPY VARCHAR2                                           -- リターン・コード
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                          -- ユーザー・エラー・メッセージ
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
    gn_target_cnt := 0;                                                         -- 対象件数カウンタの初期化
    gn_normal_cnt := 0;                                                         -- 正常件数カウンタの初期化
    gn_error_cnt  := 0;                                                         -- エラー件数カウンタの初期化
    gn_warn_cnt   := 0;                                                         -- スキップ件数カウンタの初期化

-- 初期処理
    init(                                                                       -- initをコール
       lv_errbuf                                                                -- エラー・メッセージ
      ,lv_retcode                                                               -- リターン・コード
      ,lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode <> cv_status_normal) THEN                                      -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
    
-- チェック処理
    do_check(                                                                   -- do_checkをコール
       lv_errbuf                                                                -- エラー・メッセージ
      ,lv_retcode                                                               -- リターン・コード
      ,lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;

-- 実績データ【抽出・算出・登録】
    deal_result_data(                                                           -- deal_ResultDataをコール
       lv_errbuf                                                                -- エラー・メッセージ
      ,lv_retcode                                                               -- リターン・コード
      ,lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;

-- 計画データ【抽出・算出・登録】
    deal_Plan_Data(                                                             -- deal_PlanDataをコール
       lv_errbuf                                                                -- エラー・メッセージ
      ,lv_retcode                                                               -- リターン・コード
      ,lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;

-- データの出力
    write_csv_file(                                                             -- write_csv_fileをコール
       lv_errbuf                                                                -- エラー・メッセージ
      ,lv_retcode                                                               -- リターン・コード
      ,lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
    
    
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
   * Description      : 外部呼出メインプロシージャ
   ****************************************************************************/
  PROCEDURE main(
    errbuf           OUT    NOCOPY VARCHAR2,         --   エラーメッセージ
    retcode          OUT    NOCOPY VARCHAR2,         --   エラーコード
    iv_taisyo_ym     IN     VARCHAR2,                --   対象年度
    iv_kyoten_cd     IN     VARCHAR2                 --   拠点コード
  ) AS

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
    gv_kyotenCD     := iv_kyoten_cd;                       --拠点コード
    gv_taisyoYm     := TO_NUMBER(iv_taisyo_ym);            --対象年度


-- 実装処理
    submain(                                      -- submainをコール
        lv_errbuf                                 -- エラー・メッセージ
       ,lv_retcode                                -- リターン・コード
       ,lv_errmsg                                 -- ユーザー・エラー・メッセージ
     );

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
        gn_target_cnt := 0;                                                         -- 対象件数カウンタの初期化
        gn_normal_cnt := 0;                                                         -- 正常件数カウンタの初期化
        gn_error_cnt  := 1;                                                         -- エラー件数カウンタの初期化
        gn_warn_cnt   := 0;                                                         -- スキップ件数カウンタの初期化
   END IF;
   
--対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_ccp1_msg_90000
                    ,iv_token_name1  => cv_cnt_token
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
                    ,iv_token_name1  => cv_cnt_token
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
                    ,iv_token_name1  => cv_cnt_token
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
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
 
--終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_ccp1_msg_90004;
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
END XXCSM002A03C;
/
