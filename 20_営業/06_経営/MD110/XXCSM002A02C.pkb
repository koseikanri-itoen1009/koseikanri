CREATE OR REPLACE PACKAGE BODY XXCSM002A02C AS
/*******************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A02C(spec)
 * Description      : 商品計画群別計画資料出力
 * MD.050           : 商品計画群別計画資料出力 MD050_CSM_002_A02
 * Version          : 1.2
 *
 * Program List
 * -------------------- --------------------------------------------------------
 *  Name                 Description
 *
 * init                 【初期処理】：A-1
 *
 * do_check             【チェック処理】：A-2
 * 
 * deal_group4_data     【商品群4桁データの詳細処理】A-3,A-4,A-5
 *
 * deal_group3_data     【商品群3桁データの詳細処理】A-6,A-7,A-8
 * 
 * write_line_info      【商品群4桁単位でデータの出力】A-9
 * 
 * write_csv_file       【商品計画群別計画資料出力データをCSVファイルへ出力】A-9
 *  
 * final                【終了処理】A-10
 *  
 * submain              【実装処理】
 * 
 * main                 【メイン処理】
 * 
 * Change Record
 * ------------- ----- ---------------- ----------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ----------------------------------------
 *  2008/12/04    1.0   ohshikyo        新規作成
 *  2009/02/17    1.1   M.Ohtsuki      ［障害CT_023］分母0の不具合の対応
 *  2009/02/18    1.2   K.Sai          ［障害CT_026］粗利益額の小数点2桁表示不具合＆ヘッダ日付表示対応 
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM002A02C';           -- パッケージ名
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                      -- カンマ     
  cv_msg_hafu               CONSTANT VARCHAR2(3)   := '-';                      -- 
  cv_msg_space              CONSTANT VARCHAR2(2)   := '';                       -- 空白
  cv_msg_duble              CONSTANT VARCHAR2(3)   := '"';                      -- ダブルクォーテーション
  cv_msg_star               CONSTANT VARCHAR2(3)   := '*';                      -- 
  
    
  cv_msg_linespace          CONSTANT VARCHAR2(20)   := cv_msg_duble || cv_msg_space || cv_msg_duble|| cv_msg_comma ;
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                  -- アプリケーション短縮名        
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                  -- アドオン：共通・IF領域
  cv_unit                   CONSTANT NUMBER        := 1000;                     -- 出力単位：千円
-- 
  -- ===============================
  -- ユーザー定義グローバル変数 
  -- ===============================
--  
  gd_process_date           DATE;                                               -- 業務日付
  gn_index                  NUMBER := 0;                                        -- 登録順
  gv_kyotencd               VARCHAR2(32);                                       -- 拠点コード
  gn_taisyoym               NUMBER(4,0);                                        -- 対象年度
  gv_kyotennm               VARCHAR2(200);                                      -- 拠点名称
  
  
  -- ===============================
  -- 共用メッセージ番号
  -- ===============================
--  
  cv_ccp_msg_90000           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';         -- 対象件数メッセージ
  cv_ccp_msg_90001           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';         -- 成功件数メッセージ
  cv_ccp_msg_90002           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';         -- エラー件数メッセージ
  cv_ccp_msg_90003           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';         -- スキップ件数メッセージ
  cv_ccp_msg_90004           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';         -- 正常終了メッセージ
  cv_ccp_msg_90006           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';         -- エラー終了全ロールバックメッセージ
  cv_ccp1_msg_00111          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';         -- 想定外エラーメッセージ
--  
  -- ===============================  
  -- メッセージ番号
  -- ===============================
--  
  cv_csm_msg_00005           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';         -- プロファイル取得エラーメッセージ
  cv_csm_msg_00099           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00099';         -- 商品計画用対象データ無しメッセージ
  cv_csm_msg_00096           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00096';         -- 商品計画群別計画資料出力(商品別2ヵ年実績)ヘッダ用メッセージ
  cv_csm_msg_00024           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';         -- 拠点コードチェックエラーメッセージ
  cv_csm_msg_00048           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';         -- 入力パラメータ取得メッセージ(拠点コード)
  cv_csm_msg_10015           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10015';         -- 入力パラメータ取得メッセージ（対象年度）
--
  -- ===============================
  -- トークン定義
  -- ===============================
--  
  cv_tkn_year                      CONSTANT VARCHAR2(100) := 'TAISYOU_YM';       -- 対象年度
  cv_tkn_kyotencd                  CONSTANT VARCHAR2(100) := 'KYOTEN_CD';       -- 拠点コード
  cv_tkn_kyotennm                  CONSTANT VARCHAR2(100) := 'KYOTEN_NM';       -- 拠点名称
  cv_tkn_profile                   CONSTANT VARCHAR2(100) := 'PROF_NAME';       -- プロファイル名
  cv_tkn_sysdate                   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI'; -- 作成日時
  cv_cnt_token                     CONSTANT VARCHAR2(10)  := 'COUNT';           -- 件数
 

  -- =============================== 
  -- プロファイル
  -- ===============================
-- プロファイル・コード  
  lv_prf_cd_item                CONSTANT VARCHAR2(100) := 'XXCSM1_DEAL_CATEGORY';    -- XXCMN:政策群品目カテゴリ特定名
  lv_prf_cd_sale                CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_2';  -- XXCMN:売上
  lv_prf_cd_margin              CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6'; -- XXCMN:粗利益額
  lv_prf_cd_mrate               CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7'; -- XXCMN:粗利益率
  lv_prf_cd_make                CONSTANT VARCHAR2(100) := 'XXCSM1_PLANGUN_ITEM_1';   -- XXCMN:構成比
  lv_prf_cd_ext                 CONSTANT VARCHAR2(100) := 'XXCSM1_PLANGUN_ITEM_2';   -- XXCMN:前年伸長率
  lv_prf_cd_year                CONSTANT VARCHAR2(100) := 'XXCSM1_UNIT_ITEM_3';      -- XXCMN:年

  

-- プロファイル・名称
  lv_prf_cd_item_val              VARCHAR2(100) ;                                 -- XXCMN:政策群品目カテゴリ特定名
  lv_prf_cd_sale_val              VARCHAR2(100) ;                                 -- XXCMN:売上
  lv_prf_cd_margin_val            VARCHAR2(100) ;                                 -- XXCMN:粗利益額
  lv_prf_cd_mrate_val             VARCHAR2(100) ;                                 -- XXCMN:粗利益率
  lv_prf_cd_make_val              VARCHAR2(100) ;                                 -- XXCMN:構成比 
  lv_prf_cd_ext_val               VARCHAR2(100) ;                                 -- XXCMN:前年伸長率 
  lv_prf_cd_year_val              VARCHAR2(100) ;                                 -- XXCMN:年 
  
    
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
                     ,iv_name         => cv_csm_msg_00048                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- トークンコード1（拠点コード）
                     ,iv_token_value1 => gv_kyotencd                            -- トークン値1
                     );
    -- LOGに出力                 
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                     
                     ,buff   => CHR(10) || lv_pram_op_1 
                     );  
-- 対象年度(INパラメータの出力)
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                   -- 対象年度の出力
                      iv_application  => cv_xxcsm                               -- アプリケーション短縮名
                     ,iv_name         => cv_csm_msg_10015                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year                            -- トークンコード1（対象年度名称）
                     ,iv_token_value1 => gn_taisyoym                            -- トークン値1
                     );
                     
    -- LOGに出力                 
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                     
                     ,buff   => lv_pram_op_2 || CHR(10) 
                     ); 

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
                    name => lv_prf_cd_sale
                   ,val  => lv_prf_cd_sale_val
                   ); -- 売上
    FND_PROFILE.GET(
                    name => lv_prf_cd_margin
                   ,val  => lv_prf_cd_margin_val
                   ); -- 粗利益額
    FND_PROFILE.GET(
                    name => lv_prf_cd_mrate
                   ,val  => lv_prf_cd_mrate_val
                   ); -- 粗利益率
    FND_PROFILE.GET(
                    name => lv_prf_cd_make
                   ,val  => lv_prf_cd_make_val
                   ); -- 構成比
    FND_PROFILE.GET(
                    name => lv_prf_cd_ext
                   ,val  => lv_prf_cd_ext_val
                   ); -- 前年伸長率
    FND_PROFILE.GET(
                    name => lv_prf_cd_year
                   ,val  => lv_prf_cd_year_val
                   ); -- 年
    

    -- =========================================================================
    -- プロファイル値取得に失敗した場合
    -- =========================================================================
      -- 政策群品目カテゴリ特定名
    IF (lv_prf_cd_item_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_item;
        -- 売上
    ELSIF (lv_prf_cd_sale_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_sale;
        -- 粗利益額
    ELSIF (lv_prf_cd_margin_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_margin;
        -- 粗利益率
    ELSIF (lv_prf_cd_mrate_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_mrate;
        -- 構成比
    ELSIF (lv_prf_cd_make_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_make;
        -- 前年伸長率
    ELSIF (lv_prf_cd_ext_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_ext;
        -- 前年伸長率
    ELSIF (lv_prf_cd_year_val IS NULL) THEN
        lv_tkn_value := lv_prf_cd_year;
    END IF;
    
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                -- アプリケーション短縮名
                    ,iv_name         => cv_csm_msg_00005                        -- メッセージコード
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
                  ,iv_name         => cv_csm_msg_00024                           -- メッセージコード
                  ,iv_token_name1  => cv_tkn_kyotencd                         -- トークンコード1（拠点コード）
                  ,iv_token_value1 => gv_kyotencd                             -- トークン値1
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
            COUNT(1)
    INTO    
            ln_counts
    FROM    
            xxcsm_item_plan_result                  -- 年間販売計画用実績テーブル
    WHERE   
            (subject_year   = gn_taisyoym -1        -- 前年度
    OR      subject_year    = gn_taisyoym -2)       -- 前々年度
    AND     location_cd     = gv_kyotencd           -- 拠点コード
    AND     rownum          = 1;
    
    -- 件数が0の場合、処理は中止
   IF (ln_counts = 0) THEN
       lv_retcode := cv_status_error;
       lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm                              -- アプリケーション短縮名
                   ,iv_name         => cv_csm_msg_00099                         -- メッセージコード
                   ,iv_token_name1  => cv_tkn_kyotencd                       -- トークンコード1（拠点コード）
                   ,iv_token_value1 => gv_kyotencd                           -- トークン値1
                   ,iv_token_name2  => cv_tkn_year                           -- トークンコード2（対象年度）
                   ,iv_token_value2 => gn_taisyoym                           -- トークン値2
                  );
       lv_errbuf := lv_errmsg;
       RAISE global_api_others_expt;
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
                  ,iv_name         => cv_csm_msg_00024                           -- メッセージコード
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
   * Procedure Name   : deal_group4_data
   * Description      : 商品群コード4桁データの詳細処理
   *                    ①データの抽出
   *                    ②データの算出
   *                    ③データの登録
   *****************************************************************************/
   PROCEDURE deal_group4_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group4_data';      -- プログラム名

    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_group4_cd            VARCHAR2(32);               --商品群4桁コード
-- 年間    
    ln_y_sales              NUMBER  := 0;               --年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               --年間_粗利益額合計
    ln_y_margin_r           NUMBER  := 0;               --年間_粗利益率

--  一時変数  
    ln_year                 NUMBER  := 0;               --年度判断用変数
    lb_loop_end             BOOLEAN := FALSE;           --LOOP処理判断用
       
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################

--============================================
--  データの抽出【商品群4桁】カーソル
--============================================
    CURSOR   
        get_sales_group4_data_cur
    IS
      SELECT   
             xipr.subject_year                       AS  year            -- 対象年度
            ,xipr.month_no                           AS  month           -- 月
            ,SUM(NVL(xipr.sales_budget,0))           AS  sales           -- 売上金額
            ,SUM(NVL(xipr.amount_gross_margin,0))    AS  margin          -- 粗利益額
            ,xcgv.group4_cd                          AS  group_id        -- 商品群4桁コード
            ,xcgv.group4_nm                          AS  group_nm        -- 商品群4桁名称
      FROM     
             xxcsm_item_plan_result                 xipr                 -- 商品計画用販売実績テーブル
            ,xxcsm_commodity_group4_v               xcgv                 -- 政策群4ビュー
      WHERE    
          xcgv.item_cd                                   = xipr.item_no           -- 商品コード
      AND (xipr.subject_year                             = gn_taisyoym-2         -- 対象年度（前々年度）
      OR   xipr.subject_year                             = gn_taisyoym-1)        -- 対象年度（前年度）
      AND  xipr.location_cd                              = gv_kyotencd           -- 拠点コード
      GROUP BY
               xipr.subject_year                        -- 対象年度
              ,xipr.month_no                            -- 月
              ,xcgv.group4_cd                           -- 商品群4桁コード
              ,xcgv.group4_nm                           -- 商品群4桁名称
      ORDER BY 
               group_id  ASC
              ,year      ASC
              ,month     ASC
              ,group_nm  ASC;
--                  

--
  BEGIN
--

--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    <<deal_group4>>
    -- 商品群4桁データの抽出（LOOP処理）
    FOR rec_group4_data IN get_sales_group4_data_cur LOOP
        
        -- LOOP処理判断用
        lb_loop_end := TRUE;
        
        -- 初期化(累計値算出用)
        IF (lv_group4_cd IS NULL) THEN
            -- 商品群4桁コード
            lv_group4_cd      := rec_group4_data.group_id;
            
            -- 対象年度
            ln_year         := rec_group4_data.year;

            -- 年間_売上
            ln_y_sales      := rec_group4_data.sales;
            
            -- 年間_粗利益額
            ln_y_margin     := rec_group4_data.margin;
        
        -- 商品群4桁コードが変わった場合（次の商品群4桁コード）    
        ELSIF ((lv_group4_cd <> rec_group4_data.group_id) OR (ln_year <> rec_group4_data.year)) THEN
           
            -- 年間_粗利益率:【算出処理】
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--          IF (ln_y_margin = 0) THEN
            IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
                ln_y_margin_r := 0;
            ELSE
                -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            END IF;
            
            --==================================
            -- 算出した合計値をワークテーブルへ登録
            --==================================
            
            UPDATE
                    xxcsm_tmp_sales_plan_gun
            SET
                   y_sales          = ln_y_sales                                -- 年間売上
                  ,y_margin_rate    = ln_y_margin_r                             -- 年間粗利益率
                  ,y_margin         = ln_y_margin                               -- 年間粗利益額
            WHERE
                    group_cd_4      = lv_group4_cd                              -- 商品群4桁コード
            AND     year            = ln_year;                                  -- 対象年度
            
            --===================================
            -- 次のデータ
            --===================================
            -- 商品群4桁コード
            lv_group4_cd    := rec_group4_data.group_id;
            
            -- 対象年度
            ln_year         := rec_group4_data.year;

            -- 年間_売上
            ln_y_sales      := rec_group4_data.sales;
            
            -- 年間_粗利益額
            ln_y_margin     := rec_group4_data.margin;
        -- 年度と商品群コードは変わっていない場合、年間計を算出する
        ELSIF (ln_year = rec_group4_data.year) THEN
            --===================================
            -- 【同一年度の商品】年間累計を加算する
            --===================================
            -- 年間_売上
            ln_y_sales      := ln_y_sales + rec_group4_data.sales;
            
            -- 年間_粗利益額
            ln_y_margin     := ln_y_margin + rec_group4_data.margin;

        END IF;
        
        --===================================
        -- 【商品群4桁単位】データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_gun
          (
               toroku_no            -- 出力順
              ,group_cd_4           -- 商品群コード(4桁)
              ,group_nm_4           -- 商品群コード(4桁)
              ,group_cd_3           -- 商品群コード(3桁)
              ,group_nm_3           -- 商品群コード(3桁)
              ,year                 -- 年度
              ,month_no             -- 月
              ,m_sales              -- 月間_売上
              ,m_margin_rate        -- 月間_粗利益率=月間_粗利益額／月間_売上*100
              ,m_margin             -- 月間_粗利益額
          )
          VALUES (
               gn_index                                 -- 登録順
              ,rec_group4_data.group_id                 -- 商品群コード(3桁) || '*'
              ,rec_group4_data.group_nm                 -- 商品群名称(3桁) 
              ,NULL                                     -- 商品群コード(3桁)
              ,NULL                                     -- 商品群名称(3桁)
              ,rec_group4_data.year                     -- 年度
              ,rec_group4_data.month                    -- 月
              ,rec_group4_data.sales                    -- 月間_売上
              ,DECODE(rec_group4_data.sales,0,0,ROUND(rec_group4_data.margin / rec_group4_data.sales * 100,2))  -- 月間_粗利益率
              ,rec_group4_data.margin
          );
          
          gn_index := gn_index + 1;
    END LOOP deal_group4;
    
    -- 最後データの場合
    IF (lb_loop_end) THEN
        
        -- 年間_粗利益率:【算出処理】
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--      IF (ln_y_margin = 0) THEN
        IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
            ln_y_margin_r := 0;
        ELSE
            -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
        END IF;
        
        --==================================
        -- 算出した合計値をワークテーブルへ登録
        --==================================
        
        UPDATE
                xxcsm_tmp_sales_plan_gun
        SET
               y_sales          = ln_y_sales                                -- 年間売上
              ,y_margin_rate    = ln_y_margin_r                             -- 年間粗利益率
              ,y_margin         = ln_y_margin                               -- 年間粗利益額
        WHERE
                group_cd_4      = lv_group4_cd                              -- 商品群4桁コード
        AND     year            = ln_year;                                  -- 対象年度
        
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
      IF (get_sales_group4_data_cur%ISOPEN) THEN
        CLOSE get_sales_group4_data_cur;
      END IF;
      
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================

      IF (get_sales_group4_data_cur%ISOPEN) THEN
        CLOSE get_sales_group4_data_cur;
      END IF;
      

--
--#####################################  固定部 END   ###########################
--
  END deal_group4_data;
--


   /****************************************************************************
   * Procedure Name   : deal_group3_data
   * Description      : 商品群コード3桁データの詳細処理
   *                    ①データの抽出
   *                    ②データの算出
   *                    ③データの登録
   *****************************************************************************/
   PROCEDURE deal_group3_data(
         ov_errbuf     OUT NOCOPY VARCHAR2               --共通・エラー・メッセージ
        ,ov_retcode    OUT NOCOPY VARCHAR2               --リターン・コード
        ,ov_errmsg     OUT NOCOPY VARCHAR2)              --ユーザー・エラー・メッセージ
   IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'deal_group3_data';      -- プログラム名

    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_group3_cd            VARCHAR2(32);               -- 商品群3桁コード
   
    ln_y_sales              NUMBER  := 0;               -- 年間_売上金額合計
    ln_y_margin             NUMBER  := 0;               -- 年間_粗利益額合計
    ln_y_margin_r           NUMBER  := 0;               -- 年間_粗利益率
    ln_year                 NUMBER  := 0;               -- 年度判断用変数
    lb_loop_end             BOOLEAN := FALSE;           -- LOOP処理判断用変数
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################

--============================================
--  データの抽出【商品群4桁】カーソル
--============================================
    CURSOR   
        get_sales_group3_data_cur
    IS
      SELECT   
             xipr.subject_year                           as  year                -- 対象年度
            ,xipr.month_no                               as  month               -- 月
            ,sum(nvl(xipr.sales_budget,0))               as  sales               -- 売上金額
            ,sum(nvl(xipr.amount_gross_margin,0))        as  margin              -- 粗利益額
            ,xcgv.group3_cd                              as  group_id            -- 商品群3桁コード
            ,xcgv.group3_nm                              AS  group_nm            -- 商品群3桁名称
      FROM     
             xxcsm_item_plan_result                     xipr                     -- 商品計画用販売実績テーブル
            ,xxcsm_commodity_group3_v                   xcgv                     -- 政策群２ビュー
      WHERE    
          xcgv.item_cd                                   = xipr.item_no           -- 商品コード
      AND (xipr.subject_year                             = gn_taisyoym-2         -- 対象年度（前々年度）
      OR   xipr.subject_year                             = gn_taisyoym-1)        -- 対象年度（前年度）
      AND  xipr.location_cd                              = gv_kyotencd           -- 拠点コード
      GROUP BY
               xipr.subject_year                       -- 対象年度
              ,xipr.month_no                           -- 月
              ,xcgv.group3_cd                          -- 商品群3桁コード
              ,xcgv.group3_nm                          -- 商品群3桁名称
      ORDER BY 
               group_id  ASC
              ,year      ASC
              ,month     ASC
              ,group_nm  ASC;

--

--
  BEGIN
--

--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

    <<deal_group3>>
    -- 商品群3桁データの抽出（LOOP処理）
    FOR rec_group3_data IN get_sales_group3_data_cur LOOP
        
        -- 判断用
        lb_loop_end := TRUE;
        
        -- 初期化(合計算出用)
        IF (lv_group3_cd IS NULL) THEN
            -- 商品群3桁コード
            lv_group3_cd    := rec_group3_data.group_id;
            
            -- 対象年度
            ln_year         := rec_group3_data.year;

            -- 年間_売上
            ln_y_sales      := rec_group3_data.sales;
            
            -- 年間_粗利益額
            ln_y_margin     := rec_group3_data.margin;
        
        -- 商品群3桁コードが変わった場合（次の商品群3桁コード）    
        ELSIF ((lv_group3_cd <> rec_group3_data.group_id) OR (ln_year <> rec_group3_data.year)) THEN
           
            -- 年間_粗利益率:【算出処理】
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--          IF (ln_y_margin = 0) THEN
            IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
                ln_y_margin_r := 0;
            ELSE
                -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
                ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
            END IF;
            
            --==================================
            -- 算出した合計値をワークテーブルへ登録
            --==================================
            
            UPDATE
                    xxcsm_tmp_sales_plan_gun
            SET
                   y_sales          = ln_y_sales                                -- 年間_売上
                  ,y_margin_rate    = ln_y_margin_r                             -- 年間_粗利益率
                  ,y_margin         = ln_y_margin                               -- 年間_粗利益額
            WHERE
                    group_cd_4      = lv_group3_cd                              -- 商品群3桁コード 
            AND     year            = ln_year;                                  -- 対象年度
            
            --===================================
            -- 次のデータ
            --===================================
            -- 商品群3桁コード
            lv_group3_cd    := rec_group3_data.group_id;
            
            -- 対象年度
            ln_year         := rec_group3_data.year;

            -- 年間_売上
            ln_y_sales      := rec_group3_data.sales;
            
            -- 年間_粗利益額
            ln_y_margin     := rec_group3_data.margin;
        -- 年度と商品群コードは変わっていない場合、年間計を算出する
        ELSIF (ln_year = rec_group3_data.year) THEN
            -- 年間_売上
            ln_y_sales      := ln_y_sales + rec_group3_data.sales;
            
            -- 年間_粗利益額
            ln_y_margin     := ln_y_margin + rec_group3_data.margin;
            
        END IF;
        
        --===================================
        -- 【商品群3桁単位】データの登録
        --===================================
        INSERT INTO xxcsm_tmp_sales_plan_gun
          (
               toroku_no                -- 出力順
              ,group_cd_4               -- 商品群コード(4桁)
              ,group_nm_4               -- 商品群コード(4桁)
              ,group_cd_3               -- 商品群コード(3桁)
              ,group_nm_3               -- 商品群コード(3桁)
              ,year                     -- 年度
              ,month_no                 -- 月
              ,m_sales                  -- 月間_売上
              ,m_margin_rate            -- 月間_粗利益率=月間_粗利益額／月間_売上*100
              ,m_margin                 -- 月間_粗利益額
          )
          VALUES (
              gn_index                                          -- 出力順
              ,rec_group3_data.group_id                         -- 商品群コード(4桁) 
              ,rec_group3_data.group_nm                         -- 商品群名称(4桁) 
              ,SUBSTR(rec_group3_data.group_id,1,3)             -- 商品群コード(3桁)
              ,rec_group3_data.group_nm                         -- 商品群名称(3桁)
              ,rec_group3_data.year                             -- 年度
              ,rec_group3_data.month                            -- 月
              ,rec_group3_data.sales                            -- 月間_売上
              ,DECODE(rec_group3_data.sales,0,0,ROUND(rec_group3_data.margin / rec_group3_data.sales * 100,2))  -- 月間_粗利益率
              ,rec_group3_data.margin                           -- 月間_粗利益額
          );
          gn_index := gn_index + 1;
    END LOOP deal_group3;
    
    -- 最後データの場合
    IF (lb_loop_end) THEN
        -- 年間_粗利益率:【算出処理】
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--      IF (ln_y_margin = 0) THEN
        IF (ln_y_sales = 0) THEN
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
            ln_y_margin_r := 0;
        ELSE
            -- 年間_粗利益額÷(年間_売上)*100 【小数点3桁四捨五入】
            ln_y_margin_r := ROUND(ln_y_margin / ln_y_sales * 100,2);
        END IF;
        
        --==================================
        -- 算出した合計値をワークテーブルへ登録
        --==================================
        
        UPDATE
                xxcsm_tmp_sales_plan_gun
        SET
               y_sales          = ln_y_sales                                -- 年間_売上
              ,y_margin_rate    = ln_y_margin_r                             -- 年間_粗利益率
              ,y_margin         = ln_y_margin                               -- 年間_粗利益額
        WHERE
                group_cd_4      = lv_group3_cd                              -- 商品群3桁コード 
        AND     year            = ln_year;                                  -- 対象年度
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
      IF (get_sales_group3_data_cur%ISOPEN) THEN
        CLOSE get_sales_group3_data_cur;
      END IF;
      
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================

      IF (get_sales_group3_data_cur%ISOPEN) THEN
        CLOSE get_sales_group3_data_cur;
      END IF;
      

--
--#####################################  固定部 END   ###########################
--
  END deal_group3_data;
--



  /*****************************************************************************
   * Procedure Name   : write_Line_Info
   * Description      : 商品群4桁コード毎に情報を出力
   ****************************************************************************/
  PROCEDURE write_Line_Info(
        iv_group4_cd  IN  VARCHAR2                                                  -- 商品コード
       ,ov_errbuf     OUT NOCOPY VARCHAR2                                           -- エラー・メッセージ
       ,ov_retcode    OUT NOCOPY VARCHAR2                                           -- リターン・コード
       ,ov_errmsg     OUT NOCOPY VARCHAR2)                                          -- ユーザー・エラー・メッセージ
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
    
    -- 月間計：データ・検索文
    lv_month_sql                VARCHAR2(2000);
    
    -- 年間計：データ・検索文
    lv_sum_sql                  VARCHAR2(2000);
    
    -- ボディヘッダ情報（商品群CD｜商品群名称）
    lv_line_head                VARCHAR2(2000);
    
    -- 月情報（5月|6月|7月|8月|9月|10月|11月|12月|1月|2月|3月|04月）
    lv_line_info                VARCHAR2(4000);
    
    -- 項目名称
    lv_item_info                VARCHAR2(4000);
    
    -- LOOP処理用
    in_param                    NUMBER(1,0) := 0;               -- 項目0：売上
    lb_loop_end                 BOOLEAN := FALSE;               -- 判断用
    cn_count                    CONSTANT NUMBER := 4;           -- 判断用
    
    ln_taisyou_ym               NUMBER(4,0) := gn_taisyoym - 2; -- 前々年度
    
    -- テンプ変数
    lv_temp_month               VARCHAR2(4000);
    lv_temp_other               VARCHAR2(4000);
    lv_temp_sum                 VARCHAR2(4000);
    cv_all_zero                 CONSTANT VARCHAR2(100)     := '0,0,0,0,0,0,0,0,0,0,0,0,0' || CHR(10);
    cv_year_zero                CONSTANT VARCHAR2(10)      := '0' || CHR(10);
    
-- 月計カーソル
    CURSOR get_month_data_cur(
                        in_param IN NUMBER
                        ,in_year IN NUMBER
                        )
    IS 
        SELECT   DISTINCT
        DECODE(in_param
--//+UPD START 2009/02/18   CT026 K.Sai
--                   ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0) ), 0) / cv_unit,2) || cv_msg_comma               -- 売上【月】
--                      || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cv_unit,2) || cv_msg_comma
--                   ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma              -- 粗利益額【月】
--                      || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
--                      || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cv_unit,2) || cv_msg_comma
                   ,0,   ROUND(NVL(SUM(DECODE(month_no,5,m_sales,0) ), 0) / cv_unit,0) || cv_msg_comma               -- 売上【月】
                      || ROUND(NVL(SUM(DECODE(month_no,6,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,7,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,8,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,9,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,10,m_sales,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,11,m_sales,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,12,m_sales,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,1,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,2,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,3,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,4,m_sales,0)  ),0) / cv_unit,0) || cv_msg_comma
                   ,1,   ROUND(NVL(SUM(DECODE(month_no,5,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma              -- 粗利益額【月】
                      || ROUND(NVL(SUM(DECODE(month_no,6,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,7,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,8,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,9,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,10,m_margin,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,11,m_margin,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,12,m_margin,0) ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,1,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,2,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,3,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
                      || ROUND(NVL(SUM(DECODE(month_no,4,m_margin,0)  ),0) / cv_unit,0) || cv_msg_comma
--//+UPD END   2009/02/18   CT026 K.Sai
                   ,2,NVL(SUM(DECODE(month_no,5,m_margin_rate,0)  ),0) || cv_msg_comma         -- 粗利益率【月】
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
--//+UPD START 2009/02/17   CT023 M.Ohtsuki
--                   ,3,NVL(SUM(DECODE(month_no,5,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma        -- 構成比【月】
--                      || NVL(SUM(DECODE(month_no,6,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,7,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,8,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,9,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,10,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,11,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,12,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,1,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,2,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                      || NVL(SUM(DECODE(month_no,3,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--                     || NVL(SUM(DECODE(month_no,4,DECODE(m_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                   ,3,NVL(SUM(DECODE(month_no,5,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma        -- 構成比【月】
                      || NVL(SUM(DECODE(month_no,6,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,7,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,8,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,9,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,10,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,11,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,12,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0) ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,1,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,2,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,3,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
                      || NVL(SUM(DECODE(month_no,4,DECODE(y_sales,0,0,ROUND(m_sales/y_sales * 100,2)),0)  ),0) || cv_msg_comma
--//+UPD END   2009/02/17   CT023 M.Ohtsuki
                   ,NULL) AS month_data
        FROM  
           xxcsm_tmp_sales_plan_gun       -- 商品計画群別計画資料出力ワークテーブル
        WHERE
              year        = in_year         -- 年度
        AND   group_cd_4  = iv_group4_cd;   -- 商品群コード

-- 年計カーソル
    CURSOR  get_year_data_cur(
                        in_param IN NUMBER
                        ,in_year IN NUMBER
                        )
    IS
        SELECT   DISTINCT
                 DECODE(in_param
--//+UPD START 2009/02/18   CT026 K.Sai
--                      ,0,ROUND(NVL(y_sales,0) / cv_unit,2)         || CHR(10)                  -- 売上年計
--                      ,1,ROUND(NVL(y_margin,0) / cv_unit,2)        || CHR(10)                  -- 粗利益額年計
                      ,0,ROUND(NVL(y_sales,0) / cv_unit,0)         || CHR(10)                  -- 売上年計
                      ,1,ROUND(NVL(y_margin,0) / cv_unit,0)        || CHR(10)                  -- 粗利益額年計
--//+UPD END 2009/02/18   CT026 K.Sai
                      ,2,NVL(y_margin_rate,0)                      || CHR(10)                  -- 粗利益率年計
                      ,3,DECODE(NVL(y_sales,0),0,0,100)            || CHR(10)                  -- 構成比年計
                      ,NULL) AS year_data
        FROM  
              xxcsm_tmp_sales_plan_gun          -- 商品計画群別計画資料出力ワークテーブル
        WHERE
              year        = in_year            -- 年度
        AND   group_cd_4  = iv_group4_cd;      -- 商品群コード
        
        
-- 【前年伸長率】月間計 
    CURSOR  get_ext_month_cur
    IS
        SELECT DISTINCT
                NVL(SUM(DECODE( xwspg_a.month_no, 5,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma   -- 前年度伸長率【月】
              || NVL(SUM(DECODE(xwspg_a.month_no, 6,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 7,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 8,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 9,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no,10,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no,11,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no,12,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 1,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 2,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 3,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
              || NVL(SUM(DECODE(xwspg_a.month_no, 4,DECODE(xwspg_b.m_sales,0,0,ROUND((xwspg_a.m_sales / xwspg_b.m_sales - 1) * 100,2)),0)),0) || cv_msg_comma
                AS ext_month
        FROM
             xxcsm_tmp_sales_plan_gun xwspg_a                      -- 前年度
            ,xxcsm_tmp_sales_plan_gun xwspg_b                      -- 前々年度
        WHERE
            xwspg_a.group_cd_4    = xwspg_b.group_cd_4            -- 商品群4桁コード
        AND xwspg_a.month_no      = xwspg_b.month_no              -- 月
        AND xwspg_b.year          = gn_taisyoym - 2               -- 前々年度
        AND xwspg_a.year          = gn_taisyoym - 1               -- 前年度
        AND xwspg_b.group_cd_4    = iv_group4_cd;                 -- 商品群4桁コードで紐付け 
        
 -- 【前年伸長率】年間計
    CURSOR  
            get_ext_year_cur
    IS
        SELECT DISTINCT
                NVL(DECODE(xwspg_b.y_sales,0,0,ROUND((xwspg_a.y_sales / xwspg_b.y_sales - 1) * 100,2)),0) || CHR(10) -- 伸長率年計      
                AS ext_year
        FROM
             xxcsm_tmp_sales_plan_gun xwspg_a                      -- 前年度
            ,xxcsm_tmp_sales_plan_gun xwspg_b                      -- 前々年度
        WHERE
            xwspg_a.group_cd_4    = xwspg_b.group_cd_4            -- 商品群4桁コード
        AND xwspg_a.month_no      = xwspg_b.month_no              -- 月
        AND xwspg_b.year          = gn_taisyoym - 2               -- 前々年度
        AND xwspg_a.year          = gn_taisyoym - 1               -- 前年度
        AND xwspg_b.group_cd_4    = iv_group4_cd;                 -- 商品群4桁コードで紐付け    

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
    
    --  商品群コード||商品群名の抽出
    SELECT  DISTINCT
            cv_msg_duble || 
            group_cd_4   || 
            cv_msg_duble ||
            cv_msg_comma ||
            cv_msg_duble ||
            group_nm_4   ||
            cv_msg_duble ||
            CHR(10)
    INTO
            lv_line_head
    FROM     
            xxcsm_tmp_sales_plan_gun           -- 商品計画群別計画資料出力ワークテーブル
    WHERE
            group_cd_4 = iv_group4_cd;
    
    --  異常の場合
    IF (lv_line_head IS NULL) THEN
        RAISE global_api_others_expt;
    END IF;
    
    -- 先頭行(商品群コード||商品群名)
    lv_line_info := lv_line_head ;
    
    -- 年度のLOOP処理【前々年度~前年度】
    <<year_loop>>
    WHILE (ln_taisyou_ym < gn_taisyoym ) LOOP
    
        -- 初期化
        in_param := 0;
        
        <<item_loop>>
        -- 項目 のLOOP処理【 0:売上・1:粗利益率・2:粗利益額・3:構成比】
        WHILE (in_param < cn_count ) LOOP

            lb_loop_end := FALSE;
            
            -- 項目名称の設定
            IF (in_param = 0) THEN
                
                -- 売上【項目名】
                lv_item_info := cv_msg_duble || lv_prf_cd_sale_val || cv_msg_duble || cv_msg_comma;
            ELSIF (in_param = 1) THEN
                
                -- 粗利益額【項目名】
                lv_item_info := cv_msg_duble || lv_prf_cd_margin_val || cv_msg_duble || cv_msg_comma;
            ELSIF (in_param = 2) THEN
                
                -- 粗利益率【項目名】
                lv_item_info := cv_msg_duble || lv_prf_cd_mrate_val || cv_msg_duble || cv_msg_comma;
            ELSIF (in_param = 3) THEN
                
                -- 構成比【項目名】
                lv_item_info := cv_msg_duble || lv_prf_cd_make_val || cv_msg_duble || cv_msg_comma;
            END IF;
            
            -- 前年度（前々年度）
            lv_temp_other := cv_msg_duble || SUBSTR(ln_taisyou_ym,3,4) || lv_prf_cd_year_val || cv_msg_duble || cv_msg_comma;
            
            -- 空白||項目名称
            lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info || lv_temp_other;
            
            --==================================================================   
            --  データ抽出【0:売上・1:粗利益率・2:粗利益額・3:構成比・4:前年伸長率】
            --==================================================================
                
            --初期化
            lv_temp_month := NULL;
            lv_temp_sum   := NULL;
            
            
            -- 月間計
            <<get_month_data>>
            FOR rec IN get_month_data_cur(in_param,ln_taisyou_ym) LOOP
                lb_loop_end := TRUE;
                
                lv_temp_month := rec.month_data;
            END LOOP get_month_data;
            
            IF (lb_loop_end) THEN
                -- 年間計
                <<get_year_data>>
                FOR rec IN get_year_data_cur(in_param,ln_taisyou_ym) LOOP
                    lb_loop_end := FALSE;
                    lv_temp_sum := rec.year_data;
                END LOOP get_year_data;
                
                IF (lb_loop_end) THEN
                    lv_temp_sum := cv_year_zero;
                END IF;
                
                -- 1行のデータ：（空白）＋ （項目名称｜年度）＋（5月04月）＋（年間計）        
                lv_line_info := lv_line_info || lv_temp_month || lv_temp_sum;
            ELSE

                lv_line_info := lv_line_info || cv_all_zero;
            END IF;
            
            -- 次の項目
            in_param := in_param + 1;
        END LOOP item_loop;
        
        -- 空行
        lv_line_info := lv_line_info || CHR(10);
        
        ln_taisyou_ym := ln_taisyou_ym + 1;
    END LOOP year_loop;
    

    -- 前年伸長率【項目名】
    lv_item_info := cv_msg_duble || lv_prf_cd_ext_val || cv_msg_duble || cv_msg_comma;
    
    
    lv_line_info := lv_line_info || cv_msg_linespace || lv_item_info || lv_temp_other ;
    
    -- 初期化
    lb_loop_end := FALSE;
    lv_temp_month := NULL;
    lv_temp_sum   := NULL;
    
    -- 前年伸長率【月間計】抽出
    <<get_ext_month>>
    FOR rec IN get_ext_month_cur LOOP
        lb_loop_end := TRUE;
        lv_temp_month := rec.ext_month;
        
    END LOOP get_ext_month;
    
    -- 月間データが存在する場合
    IF (lb_loop_end) THEN

        <<get_ext_year>>
         -- 前年伸長率【年間計】抽出
        FOR rec IN get_ext_year_cur LOOP
            lb_loop_end := FALSE;
            lv_temp_sum := rec.ext_year;
        END LOOP get_ext_year;
        
        IF (lb_loop_end) THEN
            lv_temp_sum := cv_year_zero;
        END IF;
        
        lv_line_info := lv_line_info || lv_temp_month || lv_temp_sum;
    ELSE
        lv_line_info := lv_line_info || cv_all_zero;
    END IF;
    
    -- 出力
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
      
      IF (get_ext_month_cur%ISOPEN) THEN
         CLOSE get_ext_month_cur;
      END IF;
      
      IF (get_ext_year_cur%ISOPEN) THEN
         CLOSE get_ext_year_cur;
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
      
      IF (get_ext_month_cur%ISOPEN) THEN
         CLOSE get_ext_month_cur;
      END IF;
      
      IF (get_ext_year_cur%ISOPEN) THEN
         CLOSE get_ext_year_cur;
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
      
      IF (get_ext_month_cur%ISOPEN) THEN
         CLOSE get_ext_month_cur;
      END IF;
      
      IF (get_ext_year_cur%ISOPEN) THEN
         CLOSE get_ext_year_cur;
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
    lv_data_head                VARCHAR2(2000);
    
    -- 商品群4桁単位情報
    lv_data_line                VARCHAR2(4000);    
        
    -- 商品群3桁コード
    lv_group3_cd                  VARCHAR2(10);
    
    -- 商品群4桁コード
    lv_group4_cd                  VARCHAR2(10);

                                      
--============================================
--  商品群3桁コード抽出【カーソル】
--============================================ 
    CURSOR  
            get_group3_cd_cur
    IS
     SELECT DISTINCT
          group_cd_3
     FROM     
          xxcsm_tmp_sales_plan_gun         -- 商品計画群別計画資料出力ワークテーブル
     WHERE
          group_cd_3 IS NOT NULL
     ORDER BY group_cd_3 ASC
;
--

--============================================
--  商品群4桁コード抽出【カーソル】
--============================================ 
    CURSOR  
            get_group4_cd_cur(in_group_cd_3 IN VARCHAR2)
    IS
     SELECT  DISTINCT
             group_cd_4
     FROM     
             xxcsm_tmp_sales_plan_gun         -- 商品計画群別計画資料出力ワークテーブル
     WHERE
             group_cd_4 LIKE  in_group_cd_3 || '%' 
     AND     group_cd_3 IS NULL
     ORDER BY group_cd_4 ASC;


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
                     ,iv_name         => cv_csm_msg_00096                       -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- トークンコード1（拠点コード）
                     ,iv_token_value1 => gv_kyotencd                            -- トークン値1
                     ,iv_token_name2  => cv_tkn_kyotennm                        -- トークンコード2（拠点コード名称）
                     ,iv_token_value2 => gv_kyotennm                            -- トークン値2
                     ,iv_token_name3  => cv_tkn_year                            -- トークンコード3（対象年度）
                     ,iv_token_value3 => gn_taisyoym                            -- トークン値3
                     ,iv_token_name4  => cv_tkn_sysdate                         -- トークンコード4（業務日付）
--//+UPD START 2009/02/18   K.Sai
--                     ,iv_token_value4 => gd_process_date                        -- トークン値4
                     ,iv_token_value4 => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI')  -- トークン値4
--//+UPD END 2009/02/18   K.Sai
                     );
                     
    -- ヘッダ情報の出力
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     
                     ,buff   => lv_data_head || CHR(10)
                     ); 
                     
    -- ボディ情報の抽出
    <<group3_loop>>
    FOR rec3 IN get_group3_cd_cur LOOP
    
        -- 商品群3桁コード
        lv_group3_cd := rec3.group_cd_3;        
       
        <<group4_loop>>
        -- 商品群4桁コードの抽出
        FOR rec4 IN get_group4_cd_cur(lv_group3_cd) LOOP
            
            lv_group4_cd := rec4.group_cd_4;
            
            -- 対象件数【加算】
            gn_target_cnt := gn_target_cnt + 1;
            
            lv_data_line := NULL;
            
            -- 商品群4桁コード単位でボディ情報を出力（write_Line_Infoを呼び出す）        
            write_Line_Info(
                          lv_group4_cd
                          ,lv_errbuf
                          ,lv_retcode
                          ,lv_errmsg
                          );

            -- エラー件数 
            IF (lv_retcode = cv_status_error) THEN
                gn_error_cnt := gn_error_cnt + 1 ;

                -- メッセージを出力
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
            -- 正常件数【加算】 
            ELSIF (lv_retcode = cv_status_normal) THEN
                gn_normal_cnt := gn_normal_cnt + 1 ;
            END IF;
            
        END LOOP group4_loop;
            lv_group4_cd := rec3.group_cd_3 || '*';
            
            -- 対象件数【加算】
            gn_target_cnt := gn_target_cnt + 1;
            
            lv_data_line := NULL;
            
            -- 商品群4桁コード単位でボディ情報を出力（write_Line_Infoを呼び出す）        
            write_Line_Info(
                          lv_group4_cd
                          ,lv_errbuf
                          ,lv_retcode
                          ,lv_errmsg
                          );

            -- エラー件数 
            IF (lv_retcode = cv_status_error) THEN
                gn_error_cnt := gn_error_cnt + 1 ;

                -- メッセージを出力
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
            -- 正常件数【加算】 
            ELSIF (lv_retcode = cv_status_normal) THEN
                gn_normal_cnt := gn_normal_cnt + 1 ;
            END IF;
      
    END LOOP group3_loop;
    
                         
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
      IF (get_group3_cd_cur%ISOPEN) THEN
        CLOSE get_group3_cd_cur;
      END IF;
      
      IF (get_group4_cd_cur%ISOPEN) THEN
        CLOSE get_group4_cd_cur;
      END IF;
      

    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_group3_cd_cur%ISOPEN) THEN
        CLOSE get_group3_cd_cur;
      END IF;
      
      IF (get_group4_cd_cur%ISOPEN) THEN
        CLOSE get_group4_cd_cur;
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
    IF (lv_retcode = cv_status_error) THEN                                      -- 戻り値が異常の場合
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

-- 商品群4桁【抽出・算出・登録】
    deal_group4_data(                                                           -- deal_ResultDataをコール
       lv_errbuf                                                                -- エラー・メッセージ
      ,lv_retcode                                                               -- リターン・コード
      ,lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN                                      -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;

-- 商品群3桁【抽出・算出・登録】
    deal_group3_data(                                                             -- deal_PlanDataをコール
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
    cv_which_log        CONSTANT VARCHAR2(10)     := 'LOG';  -- 出力先    
--
  BEGIN
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

--##################  固定ステータス初期化部 START   ###################
--
    retcode := cv_status_normal;
--
--##################  固定部 END   #####################################


-- 入力パラメータ
    gv_kyotencd     := iv_kyoten_cd;                       --拠点コード
    gn_taisyoym     := TO_NUMBER(iv_taisyo_ym);            --対象年度

-- 実装処理
    submain(                                      -- submainをコール
        lv_errbuf                                 -- エラー・メッセージ
       ,lv_retcode                                -- リターン・コード
       ,lv_errmsg                                 -- ユーザー・エラー・メッセージ
     );
     
-- 想定外異常の場合     
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
                    ,iv_name         => cv_ccp_msg_90000
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
                    ,iv_name         => cv_ccp_msg_90001
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
                    ,iv_name         => cv_ccp_msg_90002
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
                    ,iv_name         => cv_ccp_msg_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
 
--終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_ccp_msg_90004;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_ccp_msg_90006;
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


END XXCSM002A02C;
/
