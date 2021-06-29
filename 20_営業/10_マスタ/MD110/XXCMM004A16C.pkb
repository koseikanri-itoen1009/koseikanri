CREATE OR REPLACE PACKAGE BODY XXCMM004A16C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCMM004A16C(spec)
 * Description      : 単位換算自動作成
 * MD.050           : 単位換算自動作成 MD050_CMM_004_A16
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  ins_uom_convert        単位換算登録処理(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/05/27    1.0   SCSK 西川 徹     初回作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';

--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
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
  cv_appl_xxcmm        CONSTANT VARCHAR2(10) := 'XXCMM';             -- アドオン：マスタ
  cv_appl_xxccp        CONSTANT VARCHAR2(10) := 'XXCCP';             -- アドオン：マスタ
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM004A16C';      -- パッケージ名
  cv_yes               CONSTANT VARCHAR2(1)  := 'Y';
--
  -- メッセージ番号(マスタ)
  cv_msg_xxcmm_00002   CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- プロファイル取得エラー
  cv_msg_xxcmm_00441   CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00441';  -- データ取得エラー
  cv_msg_xxcmm_10502   CONSTANT VARCHAR2(20) := 'APP-XXCMM1-10502';  -- 単位換算登録エラー
--
  -- プロファイル
  cv_pro_org_code      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';   -- 在庫組織コード
  -- 参照タイプ
  cv_lookup_uom_code   CONSTANT VARCHAR2(30) := 'XXCMM_UOM_CODE';      -- 自動作成対象単位
  -- トークン
  cv_tkn_val_org_code  CONSTANT VARCHAR2(30) := '在庫組織コード';      -- 在庫組織コード
  cv_process_date      CONSTANT VARCHAR2(30) := '業務日付';            -- 業務日付取得失敗時
  cv_tkn_val_uon_conv  CONSTANT VARCHAR2(30) := '単位換算';
  cv_tkn_ng_profile    CONSTANT VARCHAR2(20) := 'NG_PROFILE';          -- プロファイル名
  cv_tkn_data_info     CONSTANT VARCHAR2(20) := 'DATA_INFO';
  cv_from_uom          CONSTANT VARCHAR2(20) := 'FROM_UOM_CODE';
  cv_tkn_item_code     CONSTANT VARCHAR2(20) := 'ITEM_CODE';
  cv_tkn_err_msg       CONSTANT VARCHAR2(20) := 'ERR_MSG';
--
  -- 固定値
  cn_itm_status_regist         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;     -- 本登録
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
   gt_bus_org_code     mtl_parameters.organization_code%TYPE;        -- 在庫組織コード
   gd_process_date     DATE;                                         -- 業務日付
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    lv_msg_token               VARCHAR2(100);
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    get_profile_expt             EXCEPTION;             -- プロファイル取得エラー
    get_info_err_expt            EXCEPTION;             -- データ取得エラー
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
    -- 業務処理日付の取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- 取得エラー時
    IF ( gd_process_date IS NULL ) THEN
      lv_msg_token := cv_process_date;
      RAISE get_info_err_expt;       -- 取得エラー
    END IF;
--
    -- 在庫組織コードの取得
    gt_bus_org_code := fnd_profile.value(cv_pro_org_code);
    IF (gt_bus_org_code IS NULL) THEN
      lv_msg_token := cv_tkn_val_org_code;
      RAISE get_profile_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN get_profile_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_xxcmm         -- モジュール名略称:XXCMM
                                                      ,cv_msg_xxcmm_00002    -- メッセージ:APP-XXCMM1-00002
                                                      ,cv_tkn_ng_profile     -- トークンコード1
                                                      ,lv_msg_token )        -- トークン値1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    WHEN get_info_err_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_xxcmm         -- モジュール名略称:XXCMN
                                                      ,cv_msg_xxcmm_00441    -- メッセージ:APP-XXCMM1-00441
                                                      ,cv_tkn_data_info      -- トークンコード1
                                                      ,lv_msg_token )        -- トークン値1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_uom_convert
   * Description      : 単位換算登録処理(A-2)
   ***********************************************************************************/
  PROCEDURE ins_uom_convert(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================0
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_uom_convert'; -- プログラム名
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
    cv_uom_class_conv_to         CONSTANT VARCHAR2(10) := '本';
--
    -- *** ローカル変数 ***
--
    lv_err_msg                 VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- 処理対象品目マスタ取得カーソル
    CURSOR get_item_cur
    IS
      SELECT /*+ 
                LEADING( mp flvv msib xsib )
                USE_NL( mp )
                USE_NL( msib )
                USE_NL( xsib )
             */
             msib.inventory_item_id
            ,msib.primary_uom_code
            ,msib.segment1                 AS item_no
      FROM   mtl_system_items_b            msib     -- 品目マスタ
            ,mtl_parameters                mp       -- 在庫組織マスタ
            ,xxcmm_system_items_b          xsib     -- 品目アドオン
            ,fnd_lookup_values_vl          flvv     -- 参照表
      WHERE  msib.organization_id          = mp.organization_id
      AND    mp.organization_code          = gt_bus_org_code
      AND    xsib.item_code                = msib.segment1
      AND    xsib.item_status              = cn_itm_status_regist   -- 品目ステータスが「本登録」
      AND    msib.primary_uom_code         = flvv.meaning           -- 自動登録対象の単位
      AND    flvv.lookup_type              = cv_lookup_uom_code
      AND    flvv.enabled_flag             = cv_yes
      AND    gd_process_date              >= NVL( flvv.start_date_active, gd_process_date )
      AND    gd_process_date              <= NVL( flvv.end_date_active, gd_process_date )
      AND    NOT EXISTS ( SELECT /*+ USE_NL( mucc ) */
                                 1
                          FROM   mtl_uom_class_conversions   mucc
                          WHERE  mucc.from_uom_code       = msib.primary_uom_code
                          AND    mucc.to_uom_code         = cv_uom_class_conv_to
                          AND    mucc.inventory_item_id   = msib.inventory_item_id
                        )
      ;
--
    -- *** ローカル・レコード ***
    get_item_rec     get_item_cur%ROWTYPE;
    -- 単位換算用
    l_uom_class_conv_rec         xxcmm_004common_pkg.uom_class_conv_rtype;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    ins_uom_class_expt           EXCEPTION;             -- 単位換算登録エラー
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
    OPEN get_item_cur;
--
    <<get_item_loop>>
    LOOP
      FETCH get_item_cur  INTO get_item_rec;
        EXIT WHEN get_item_cur%NOTFOUND;
--
        -- 処理件数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
--
        l_uom_class_conv_rec.inventory_item_id := get_item_rec.inventory_item_id;
        l_uom_class_conv_rec.from_uom_code     := get_item_rec.primary_uom_code;
        l_uom_class_conv_rec.to_uom_code       := cv_uom_class_conv_to;                   -- 本
        l_uom_class_conv_rec.conversion_rate   := 1;
        --
        -- 単位換算登録API
        xxcmm_004common_pkg.proc_uom_class_ref(
          i_uom_class_conv_rec  =>  l_uom_class_conv_rec  -- 区分間換算反映用レコードタイプ
         ,ov_errbuf             =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
         ,ov_retcode            =>  lv_retcode            -- リターン・コード             --# 固定 #
         ,ov_errmsg             =>  lv_err_msg            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
--
          RAISE ins_uom_class_expt;
--
        END IF;
--
    END LOOP get_item_cur;
--
    CLOSE get_item_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN ins_uom_class_expt THEN
      IF ( get_item_cur%ISOPEN ) THEN
        CLOSE get_item_cur;
      END IF;
--
      -- エラーメッセージ取得
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_xxcmm                   -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_10502              -- メッセージコード
                     ,iv_token_name1  => cv_from_uom                     -- トークンコード1
                     ,iv_token_value1 => get_item_rec.primary_uom_code   -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_code                -- トークンコード2
                     ,iv_token_value2 => get_item_rec.item_no            -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                  -- トークンコード3
                     ,iv_token_value3 => lv_err_msg                      -- トークン値3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
      IF ( get_item_cur%ISOPEN ) THEN
        CLOSE get_item_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_uom_convert;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- 単位換算登録処理(A-2)
    -- ====================================
    ins_uom_convert(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
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
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
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
    -- メッセージ番号(共通・IF)
    cv_target_rec_msg  CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(30) := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    ELSE
      --対象件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxccp
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --当処理では警告終了なし
--    ELSIF(lv_retcode = cv_status_warn) THEN
--      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxccp
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
END XXCMM004A16C;
/
