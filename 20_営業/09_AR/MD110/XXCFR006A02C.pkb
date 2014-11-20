CREATE OR REPLACE PACKAGE BODY XXCFR006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR006A02C(body)
 * Description      : HHT入金処理
 * MD.050           : MD050_CFR_006_A02_HHT入金処理
 * MD.070           : MD050_CFR_006_A02_HHT入金処理
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 入力パラメータ値ログ出力処理            (A-1)
 *  get_receipt_methods    p 支払方法取得処理                        (A-3)
 *  start_api              p API起動                                 (A-4)
 *  delete_htt             p HHT入金データ論理削除処理               (A-5)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.00  SCS 濱中 亮一    初回作成
 *  2009/07/23    1.1   SCS T.KANEDA     T3時障害0000837対応
 *  2009/10/16    1.2   SCS T.KANEDA     T4時障害対応
 *  2011/02/23    1.3   SCS Y.Nishino    [E_本稼動_02246]対応
 *                                       AR入金情報に納品先拠点コードと納品先顧客コードを追加
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR006A02C';        -- パッケージ名
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
  cv_dict_cd         CONSTANT VARCHAR2(100) := 'CFR006A02001';        -- HHT入金テーブル
--
  -- メッセージ番号
  cv_msg_006a02_001  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00026';     -- 支払方法取得処理エラーメッセージ
  cv_msg_006a02_002  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00033';     -- 入金作成APIエラーメッセージ
  cv_msg_006a02_003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003';     -- ロックエラーメッセージ
  cv_msg_006a02_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017';     -- データ更新エラーメッセージ
  cv_msg_006a02_005  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00057';     -- データ更新エラーメッセージ
-- Add 2011.02.23 Ver1.3 Start
  cv_msg_006a02_006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004';     -- プロファイル取得エラーメッセージ
-- Add 2011.02.23 Ver1.3 End
--
-- トークン
  cv_tkn_account     CONSTANT VARCHAR2(15) := 'ACCOUNT_CODE';         -- 顧客コード
  cv_tkn_kyoten      CONSTANT VARCHAR2(15) := 'KYOTEN_CODE';          -- 拠点コード
  cv_tkn_class       CONSTANT VARCHAR2(15) := 'RECEIPT_CLASS';        -- 入金区分
  cv_tkn_date        CONSTANT VARCHAR2(15) := 'RECEIPT_DATE';         -- 入金日
  cv_tkn_amount      CONSTANT VARCHAR2(15) := 'AMOUNT';               -- 入金額
  cv_tkn_meathod     CONSTANT VARCHAR2(15) := 'RECEIPT_MEATHOD';      -- 支払方法
  cv_tkn_message     CONSTANT VARCHAR2(15) := 'MESSAGE';              -- X_MSG_DATA
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';                -- テーブル名
-- Add 2011.02.23 Ver1.3 Start
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';            -- プロファイル名
-- Add 2011.02.23 Ver1.3 End
--
-- Add 2011.02.23 Ver1.3 Start
  --プロファイル
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';               -- 営業単位
-- Add 2011.02.23 Ver1.3 End
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';               -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';                  -- ログ出力
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- Add 2011.02.23 Ver1.3 Start
  gn_org_id                   NUMBER;                                 -- 営業単位
-- Add 2011.02.23 Ver1.3 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf              OUT     VARCHAR2,         --    エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         --    リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         --    ユーザー・エラー・メッセージ --# 固定 #
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
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- コンカレントパラメータ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- メッセージ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- Add 2011.02.23 Ver1.3 Start
    --==============================================================
    -- プロファイル値の取得
    --==============================================================
    -- プロファイルから営業単位取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_006a02_006 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))  -- 営業単位
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
-- Add 2011.02.23 Ver1.3 End
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure  Name   : get_receipt_methods
   * Description      : 支払方法取得処理 (A-3)
   ***********************************************************************************/
  Procedure get_receipt_methods(
    iv_base_code            IN         VARCHAR2,            -- 拠点コード
    iv_customer_number      IN         VARCHAR2,            -- 顧客コード
    in_payment_amount       IN         NUMBER,              -- 入金額
    id_payment_date         IN         DATE,                -- 入金日
    iv_payment_class        IN         VARCHAR2,            -- 入金区分
    ov_receipt_method_id    OUT        VARCHAR2,            -- 支払方法ID
-- Modify 2009.07.23 Ver1.1 Start
    ov_receipt_name         OUT        VARCHAR2,            -- 支払方法名
-- Modify 2009.07.23 Ver1.1 End
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_methods'; -- プログラム名
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
    lt_receipt_method_id ar_receipt_methods.receipt_method_id%TYPE;  -- 支払方法ID
    lt_name              ar_receipt_methods.name%TYPE;               -- 名称
--
    -- *** ローカル・カーソル ***
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
    BEGIN
      -- 抽出
      SELECT ar.receipt_method_id receipt_method_id,
             ar.name              name
      INTO lt_receipt_method_id,
           lt_name
      FROM ar_receipt_methods ar
      WHERE ar.attribute1 = iv_base_code      -- 拠点コード
        AND ar.attribute2 = iv_payment_class  -- 入金区分
      ;
--
      -- 支払方法IDセット
      ov_receipt_method_id := lt_receipt_method_id;
-- Modify 2009.07.23 Ver1.1 Start
      ov_receipt_name := lt_name;
-- Modify 2009.07.23 Ver1.1 End
--
    EXCEPTION
      WHEN OTHERS THEN  -- 取得時エラー
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfr     -- 'XXCFR'
                                ,cv_msg_006a02_001
                                ,cv_tkn_account     -- トークン'ACCOUNT_CODE'
                                ,iv_customer_number
                                   -- 顧客コード
                                ,cv_tkn_kyoten      -- トークン'KYOTEN_CODE'
                                ,iv_base_code
                                   -- 拠点コード
                                ,cv_tkn_class       -- トークン'RECEIPT_CLASS'
                                ,iv_payment_class
                                   -- 入金区分
                                ,cv_tkn_date        -- トークン'RECEIPT_DATE'
                                ,TO_CHAR(id_payment_date, 'YYYY/MM/DD')
                                   -- 入金日
                                ,cv_tkn_amount      -- トークン'AMOUNT'
                                ,in_payment_amount
                              )    -- 入金額
                             ,1
                             ,5000
                            );
--
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        -- 警告セット
        ov_retcode := cv_status_warn;
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
  END get_receipt_methods;
--
  /**********************************************************************************
   * Procedure Name   : start_api
   * Description      : API起動 (A-4)
   ***********************************************************************************/
  PROCEDURE start_api(
    in_payment_amount  IN  NUMBER,     -- 入金額
    in_customer_number IN  VARCHAR2,   -- 顧客コード
    in_cust_account_id IN  NUMBER,     -- 顧客ID
    in_receipt_id      IN  NUMBER,     -- 支払方法ID
-- Modify 2009.07.23 Ver1.1 Start
    in_receipt_name    IN  VARCHAR2,   -- 支払方法ID
-- Modify 2009.07.23 Ver1.1 End
    id_payment_date    IN  DATE,       -- 入金日
-- Add 2011.02.23 Ver1.3 Start
    iv_base_code                 IN  VARCHAR2,  -- 拠点コード
    iv_delivery_customer_number  IN  VARCHAR2,  -- 納品先顧客コード
-- Add 2011.02.23 Ver1.3 End
    ov_errbuf          OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_api'; -- プログラム名
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
    ln_cr_id            NUMBER;
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
-- Add 2011.02.23 Ver1.3 Start
    l_attribute_rec     ar_receipt_api_pub.attribute_rec_type  :=  NULL;  -- attribute用
-- Add 2011.02.23 Ver1.3 End
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
    ov_errbuf  := lv_errbuf;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =====================================================
    --  API起動 (A-4)
    -- =====================================================
-- Add 2011.02.23 Ver1.3 Start
    -- 付加フレックスフィールドの設定
    l_attribute_rec.attribute_category := TO_CHAR(gn_org_id);           -- 営業単位
    l_attribute_rec.attribute2         := iv_base_code;                 -- 拠点コード
    l_attribute_rec.attribute3         := iv_delivery_customer_number;  -- 納品先顧客コード
-- Add 2011.02.23 Ver1.3 End
--
    --Call API
    ar_receipt_api_pub.create_cash( 
       p_api_version          =>  1.0
      ,p_init_msg_list        =>  fnd_api.g_true
      ,x_return_status        =>  lv_return_status
      ,x_msg_count            =>  ln_msg_count
      ,x_msg_data             =>  lv_msg_data
      ,p_amount               =>  in_payment_amount
      ,p_customer_id          =>  in_cust_account_id
      ,p_receipt_method_id    =>  in_receipt_id
      ,p_receipt_date         =>  id_payment_date
      ,p_gl_date              =>  id_payment_date
      ,p_cr_id                =>  ln_cr_id
-- Add 2011.02.23 Ver1.3 Start
      ,p_attribute_rec        =>  l_attribute_rec           -- 付加フレックス
-- Add 2011.02.23 Ver1.3 End
    );
--
    IF (lv_return_status <> 'S') THEN
      --エラー処理
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr     -- 'XXCFR'
                              ,cv_msg_006a02_002
                              ,cv_tkn_account     -- トークン'ACCOUNT_CODE'
                              ,in_customer_number
                                 -- 顧客コード
                              ,cv_tkn_meathod     -- トークン'RECEIPT_MEATHOD'
-- Modify 2009.07.23 Ver1.1 Start
--                              ,in_customer_number
                              ,in_receipt_name
-- Modify 2009.07.23 Ver1.1 End
                                 -- 支払方法
                              ,cv_tkn_date        -- トークン'RECEIPT_DATE'
                              ,TO_CHAR(id_payment_date, 'YYYY/MM/DD')
                                 -- 入金日
                              ,cv_tkn_amount      -- トークン'AMOUNT'
                              ,in_payment_amount
                            )    -- 入金額
                           ,1
                           ,5000
                          );
      -- 入金作成APIエラーメッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API標準エラーメッセージ出力
      IF (ln_msg_count = 1) THEN
        -- API標準エラーメッセージが１件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '・' || lv_msg_data
        );
--
      ELSE
        -- API標準エラーメッセージが複数件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                       ,1
                                       ,5000
                                     )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
          
          ln_msg_count := ln_msg_count - 1;
          
        END LOOP while_loop;
--
      END IF;
      -- 警告セット
      ov_retcode := cv_status_warn;
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
  END start_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_htt
   * Description      : HHT入金データ論理削除処理 (A-5)
   ***********************************************************************************/
  PROCEDURE delete_htt(
    iv_base_code            IN         VARCHAR2,            -- 拠点コード
    id_payment_date         IN         DATE,                -- 入金日
    iv_payment_class        IN         VARCHAR2,            -- 入金区分
-- Add 2011.02.23 Ver1.3 Start
    iv_delivery_to_base_code  IN       VARCHAR2,            -- 拠点コード
-- Add 2011.02.23 Ver1.3 End
    iv_customer_number      IN         VARCHAR2,            -- 顧客コード
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_htt'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR lock_payment_cur(lt_base_code       xxcos_payment.base_code%TYPE,
                            lt_payment_date    xxcos_payment.payment_date%TYPE,
                            lt_payment_class   xxcos_payment.payment_class%TYPE,
                            lt_customer_number xxcos_payment.customer_number%TYPE)
    IS
      SELECT 'X'
      FROM xxcos_payment pay
      WHERE pay.base_code       = lt_base_code        -- 拠点コード
        AND pay.payment_date    = lt_payment_date     -- 入金日
        AND pay.payment_class   = lt_payment_class    -- 入金区分
        AND pay.customer_number = lt_customer_number  -- 顧客コード
      FOR UPDATE NOWAIT
    ;
--
    lock_payment_rec lock_payment_cur%ROWTYPE;
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
    -- カーソルオープン
    OPEN lock_payment_cur( iv_base_code
                          ,id_payment_date
                          ,iv_payment_class
                          ,iv_customer_number
                         );
--
    -- データの取得
    FETCH lock_payment_cur INTO lock_payment_rec;
--
    -- カーソルクローズ
    CLOSE lock_payment_cur;
--
    -- HHT入金テーブル論理削除
    UPDATE xxcos_payment
    SET    delete_flag      = 'Y'
          ,last_updated_by  = cn_last_updated_by
          ,last_update_date = cd_last_update_date
    WHERE  base_code        = iv_base_code        -- 拠点コード
    AND    payment_date     = id_payment_date     -- 入金日
    AND    payment_class    = iv_payment_class    -- 入金区分
-- Modify 2011.02.23 Ver1.3 Start
---- Modify 2009.10.16 Ver1.2 Start
----    AND    customer_number  = iv_customer_number  -- 顧客コード
--    AND    customer_number  in ( SELECT xchv.ship_account_number  -- 顧客コード
--                                   FROM xxcfr_cust_hierarchy_v xchv
--                                  WHERE iv_customer_number = xchv.cash_account_number
--                                 UNION ALL
--                                 SELECT iv_customer_number  -- 顧客コード
--                                   FROM DUAL
--                                )
---- Modify 2009.10.16 Ver1.2 End
    AND    NVL( delivery_to_base_code , base_code )  = iv_delivery_to_base_code  -- 拠点コード
    AND    customer_number                           = iv_customer_number        -- 顧客コード
-- Modify 2011.02.23 Ver1.3 End
    AND    delete_flag      = 'N'                 -- 削除フラグ
    ;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                               cv_msg_kbn_cfr       -- 'XXCFR'
                              ,cv_msg_006a02_003    -- テーブルロックエラー
                              ,cv_tkn_table         -- トークン'TABLE'
                              ,xxcfr_common_pkg.lookup_dictionary(
                                 cv_msg_kbn_cfr
                                ,cv_dict_cd
                               )                    -- 'HHT入金テーブル'
                            )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      -- テーブルロック以外のエラー処理
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                               cv_msg_kbn_cfr       -- 'XXCFR'
                              ,cv_msg_006a02_004    -- テーブルロックエラー
                              ,cv_tkn_table         -- トークン'TABLE'
                              ,xxcfr_common_pkg.lookup_dictionary(
                                 cv_msg_kbn_cfr
                                ,cv_dict_cd
                               )                    -- 'HHT入金テーブル'
                            )
                          ,1
                          ,5000
                          );
      ov_errmsg  := lv_errmsg;
--
  END delete_htt;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    on_target_cnt          OUT     NUMBER,           -- 対象件数
    on_normal_cnt          OUT     NUMBER,           -- 成功件数
    on_error_cnt           OUT     NUMBER,           -- エラー件数
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
    lt_receipt_id  ar_receipt_methods.receipt_method_id%TYPE;  -- 支払方法ID
-- Modify 2009.07.23 Ver1.1 Start
    lt_receipt_name  ar_receipt_methods.name%TYPE;  -- 支払方法ID
-- Modify 2009.07.23 Ver1.1 End
    lv_warning_flg VARCHAR2(1) := 'N';                         -- 警告フラグ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 抽出
-- Modify 2009.10.16 Ver1.2 Start
--    CURSOR payment_cur
--    IS
--      SELECT hht.base_code           base_code,
--             hht.customer_number     customer_number,
--             SUM(hht.payment_amount) payment_amount,
--             hht.payment_date        payment_date,
--             hht.payment_class       payment_class,
--             cus.cust_account_id     cust_account_id
--      FROM xxcos_payment    hht,
--           hz_cust_accounts cus
--      WHERE hht.customer_number = cus.account_number(+)  -- 顧客コード
--        AND hht.delete_flag     = 'N'                    -- 削除フラグ
--      GROUP BY hht.base_code
--              ,hht.customer_number
--              ,hht.payment_date
--              ,hht.payment_class
--              ,cus.cust_account_id
--    ;
--
--
-- 入金先顧客が存在する場合は、入金先顧客を使用するよう変更
    CURSOR payment_cur
    IS
      SELECT hht.base_code           base_code,
             NVL(xchv.cash_account_number,hht.customer_number)  customer_number,
             SUM(hht.payment_amount) payment_amount,
             hht.payment_date        payment_date,
             hht.payment_class       payment_class,
             NVL(xchv.cash_account_id,cus.cust_account_id)     cust_account_id
-- Add 2011.02.23 Ver1.3 Start
            ,NVL( hht.delivery_to_base_code , hht.base_code )  delivery_to_base_code
            ,hht.customer_number                               delivery_customer_number
-- Add 2011.02.23 Ver1.3 End
      FROM xxcos_payment    hht,
           hz_cust_accounts cus,
           xxcfr_cust_hierarchy_v xchv
      WHERE hht.customer_number = cus.account_number(+)         -- 顧客コード
        AND hht.delete_flag     = 'N'                           -- 削除フラグ
        AND hht.customer_number = xchv.ship_account_number(+)   -- 顧客コード
      GROUP BY hht.base_code
              ,NVL(xchv.cash_account_number,hht.customer_number)
              ,hht.payment_date
              ,hht.payment_class
              ,NVL(xchv.cash_account_id,cus.cust_account_id)
-- Add 2011.02.23 Ver1.3 Start
              ,NVL( hht.delivery_to_base_code , hht.base_code )
              ,hht.customer_number
-- Add 2011.02.23 Ver1.3 End
    ;
-- Modify 2009.10.16 Ver1.2 End
--
    payment_rec payment_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
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
    -- =====================================================
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  HHT入金データ取得処理(A-2)
    -- =====================================================
--
    -- カーソルオープン
    OPEN payment_cur;
--
    <<payment_loop>>
    LOOP
      -- リターン値初期化
      lv_retcode  := cv_status_normal;
--
    -- データの取得
      FETCH payment_cur INTO payment_rec;
      EXIT WHEN payment_cur%NOTFOUND;
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 顧客マスタ存在チェック
      IF (payment_rec.cust_account_id) IS NULL THEN
        --(エラー処理)
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        lv_retcode  := cv_status_warn;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfr     -- 'XXCFR'
                                ,cv_msg_006a02_005
                                ,cv_tkn_account     -- トークン'ACCOUNT_CODE'
                                ,payment_rec.customer_number
                              )    -- 顧客コード
                             ,1
                             ,5000
                            );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
--
    -- =====================================================
    --  支払方法取得処理 (A-3)
    -- =====================================================
--
      -- 正常処理チェック
      IF (lv_retcode = cv_status_normal) THEN
        get_receipt_methods(
           payment_rec.base_code        -- 拠点コード
          ,payment_rec.customer_number  -- 顧客コード
          ,payment_rec.payment_amount   -- 入金額
          ,payment_rec.payment_date     -- 入金日
          ,payment_rec.payment_class    -- 入金区分
          ,lt_receipt_id                -- 支払方法ID
-- Modify 2009.07.23 Ver1.1 Start
          ,lt_receipt_name              -- 支払方法名
-- Modify 2009.07.23 Ver1.1 End
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
    -- =====================================================
    --  API起動 (A-4)
    -- =====================================================
--
        -- 正常処理チェック
        IF (lv_retcode = cv_status_normal) THEN
          start_api(
             payment_rec.payment_amount   -- 入金額
            ,payment_rec.customer_number  -- 顧客コード
            ,payment_rec.cust_account_id  -- 顧客ID
            ,lt_receipt_id                -- 支払方法ID
-- Modify 2009.07.23 Ver1.1 Start
            ,lt_receipt_name              -- 支払方法名
-- Modify 2009.07.23 Ver1.1 End
            ,payment_rec.payment_date     -- 入金日
-- Add 2011.02.23 Ver1.3 Start
            ,payment_rec.delivery_to_base_code     -- 拠点コード
            ,payment_rec.delivery_customer_number  -- 納品先顧客コード
-- Add 2011.02.23 Ver1.3 End
            ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                   -- リターン・コード             --# 固定 #
            ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
    -- =====================================================
    --  HHT入金データ論理削除処理 (A-5)
    -- =====================================================
--
          -- 正常処理チェック
          IF (lv_retcode = cv_status_normal) THEN
            delete_htt(
               payment_rec.base_code       -- 拠点コード
              ,payment_rec.payment_date    -- 入金日
              ,payment_rec.payment_class   -- 入金区分
-- Modify 2011.02.23 Ver1.3 Start
--              ,payment_rec.customer_number -- 顧客コード
              ,payment_rec.delivery_to_base_code     -- 納品先拠点コード
              ,payment_rec.delivery_customer_number  -- 納品先顧客コード
-- Modify 2011.02.23 Ver1.3 End
              ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
              ,lv_retcode                  -- リターン・コード             --# 固定 #
              ,lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              RAISE global_process_expt;
            END IF;
--
            -- 成功件数カウント
            gn_normal_cnt := gn_normal_cnt + 1;
--
          ELSE
            --(エラー処理)
            -- エラー件数カウント
            gn_error_cnt := gn_error_cnt + 1;
          END IF;
        ELSE
          --(エラー処理)
          -- エラー件数カウント
          gn_error_cnt := gn_error_cnt + 1;
        END IF;
      END IF;
--
    END LOOP payment_loop;
--
    -- カーソルクローズ
    CLOSE payment_cur;
--
    -- =====================================================
    --  終了処理 (A-6)
    -- =====================================================
   on_target_cnt := gn_target_cnt;  -- 対象件数カウント
   on_normal_cnt := gn_normal_cnt;  -- 成功件数カウント
   on_error_cnt  := gn_error_cnt;   -- エラー件数カウント
--
   -- 警告フラグ判定
   IF (gn_error_cnt > 0) THEN
     ov_retcode := cv_status_warn;
   END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka テンプレートを修正
      IF (payment_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE payment_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka テンプレートを修正
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka テンプレートを修正
      IF (payment_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE payment_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka テンプレートを修正
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka テンプレートを修正
      IF (payment_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE payment_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka テンプレートを修正
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
    errbuf                 OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                OUT     VARCHAR2)         --    エラーコード        --# 固定 #
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
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
       gn_target_cnt -- 対象件数
      ,gn_normal_cnt -- 成功件数
      ,gn_error_cnt  -- エラー件数
      ,lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    ELSE
      gn_warn_cnt   := 0;
    END IF;
--
--
--###########################  固定部 START   #####################################################
--
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
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
END XXCFR006A02C;
/
