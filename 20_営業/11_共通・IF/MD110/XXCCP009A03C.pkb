CREATE OR REPLACE PACKAGE BODY APPS.XXCCP009A03C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP009A03C(body)
 * Description      : 請求書保留ステータス更新処理
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/30    1.0   SCSK K.Nakatsu  [E_本稼動_11000]新規作成
 *  2015/01/08    1.1   SCSK T.Ishiwata [E_本稼動_11000]再対応
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- アプリケーション短縮名
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP009A03C'; -- パッケージ名
  -- 実行モード
  cv_execmode_chk           CONSTANT VARCHAR2(1)  := '0'; -- ログ出力のみ
  cv_execmode_upd           CONSTANT VARCHAR2(1)  := '1'; -- ログ出力およびデータ更新
  -- 請求書保留ステータス 参照
  cv_invhold_lookuptype     CONSTANT VARCHAR2(25) := 'XX03_AR_INV_HOLD_STATUS';
  cv_invhold_lang           CONSTANT VARCHAR2(2)  := USERENV('LANG');
  cv_invhold_flag           CONSTANT VARCHAR2(1)  := 'Y';
  -- ログインユーザORG_ID
  cn_org_id                 CONSTANT NUMBER       := fnd_global.org_id;
  -- コンカレントプログラム表
  cv_concprg_lang           CONSTANT VARCHAR2(2)  := USERENV('LANG');
  -- 消込済
  cv_raa_stat               CONSTANT VARCHAR2(3)  := 'APP';
  cv_raa_disp               CONSTANT VARCHAR2(1)  := 'Y';
  -- 日付書式
  cv_date_format            CONSTANT VARCHAR2(21) := 'RRRR/MM/DD HH24:MI:SS';
  cv_date_format2           CONSTANT VARCHAR2(10) := 'RRRR/MM/DD';
--
--
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  TYPE request_ids_rtype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gv_exe_mode               VARCHAR2(30);
  gv_bill_cust_code         VARCHAR2(30);
  gd_target_date            DATE;
  gd_business_date          DATE;
  gn_request_id             request_ids_rtype;
  gv_status_from            VARCHAR2(30);
  gv_status_to              VARCHAR2(30);
--
  gv_status                 VARCHAR2(30);
--
  --==================================================
  -- グローバルカーソル
  --==================================================
  CURSOR target_cur(
      in_request_id NUMBER
  ) IS
    SELECT   rcta.attribute7             AS e_attribute7            -- 請求書保留ステータス
            ,rcta.trx_number             AS e_trx_number            -- 取引番号
            ,rcta.trx_date               AS e_trx_date              -- 取引日
            ,rctta.name                  AS e_name                  -- 取引タイプ
            ,rctta.attribute1            AS e_attribute1            -- 請求書出力対象区分
            ,(SELECT fcpt.user_concurrent_program_name
              FROM   fnd_concurrent_programs_tl   fcpt
              WHERE  1 = 1
              AND    fcpt.application_id        = rcta.program_application_id
              AND    fcpt.concurrent_program_id = rcta.program_id
              AND    fcpt.language              = cv_concprg_lang
             )                           AS e_conc_name             -- 最終更新プログラム名(請求明細データ作成が対象)
            ,rcta.request_id             AS e_request_id            -- 最終更新要求ID
            ,rcta.last_update_date       AS e_last_update_date      -- 最終更新日
            ,hca.account_number          AS e_account_number        -- 請求顧客番号
            ,hp.party_name               AS e_party_name            -- 請求顧客名
            ,apsa.amount_due_original    AS e_amount_due_original   -- 当初請求書金額
            ,apsa.amount_due_remaining   AS e_amount_due_remaining  -- 未回収残高
            ,apsa.amount_applied         AS e_amount_applied        -- 消込済残高
            ,apsa.amount_adjusted        AS e_amount_adjusted       -- 修正済残高
            ,apsa.amount_credited        AS e_amount_credited       -- クレジットメモ残高
            ,hp.status                   AS e_hp_status             -- 顧客パーティステータス
            ,hca.status                  AS e_hca_status            -- 顧客アカウントステータス
            ,rcta.customer_trx_id        AS e_customer_trx_id       -- 取引ID
    FROM     ra_customer_trx_all            rcta
            ,ra_cust_trx_types_all          rctta
            ,ar_payment_schedules_all       apsa
            ,hz_cust_accounts               hca
            ,hz_parties                     hp
    WHERE    1 = 1
    AND      hp.party_id            = hca.party_id
    AND      hca.cust_account_id    = rcta.bill_to_customer_id
    AND      rctta.cust_trx_type_id = rcta.cust_trx_type_id
    AND      apsa.customer_trx_id   = rcta.customer_trx_id
    AND      apsa.org_id            = rcta.org_id
    AND      rctta.org_id           = rcta.org_id
    AND NOT EXISTS (
        SELECT 1
        FROM   ar_receivable_applications_all raa
        WHERE  1 = 1
        AND    rcta.customer_trx_id = raa.applied_customer_trx_id
        AND    raa.status           = cv_raa_stat
        AND    raa.display          = cv_raa_disp
    )
    AND      hca.account_number     = gv_bill_cust_code             -- 請求先顧客
    AND      rcta.org_id            = cn_org_id                     -- ログインユーザ組織
    AND      rcta.request_id        = in_request_id                 -- 要求ID
-- 2015/01/08 Ver.1.1 Mod Start
--    AND      apsa.due_date          = gd_target_date                -- 締日
    AND EXISTS (
        SELECT /*+ INDEX_SS(xil XXCFR_INVOICE_LINES_N01) */
               'X'
        FROM   xxcfr_invoice_lines xil
        WHERE  xil.trx_id      = rcta.customer_trx_id
        AND    xil.cutoff_date = gd_target_date                     -- 締日
    )
-- 2015/01/08 Ver.1.1 Mod End
    AND      rcta.attribute7        = gv_status_from                -- 変更対象ステータス
    ORDER BY rcta.trx_date
-- 2015/01/08 Ver.1.1 Mod Start
--    FOR UPDATE NOWAIT
    FOR UPDATE OF rcta.customer_trx_id NOWAIT
-- 2015/01/08 Ver.1.1 Mod End
  ;
  target_rec target_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
    --ログ出力用（実行モード0のとき更新元、1のとき更新後ステータス）
    IF (gv_exe_mode = cv_execmode_chk) THEN
        gv_status := gv_status_from;
    ELSIF (gv_exe_mode = cv_execmode_upd) THEN
        gv_status := gv_status_to;
    END IF;
--
    --ログヘッダ行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 
            '"請求書保留ステータス",'           ||
            '"取引番号",'                       ||
            '"取引日",'                         ||
            '"取引タイプ",'                     ||
            '"請求書出力対象区分",'             ||
            '"最終更新プログラム名",'           ||
            '"最終更新要求ID",'                 ||
            '"最終更新日",'                     ||
            '"請求顧客番号",'                   ||
            '"請求顧客名",'                     ||
            '"当初請求書金額",'                 ||
            '"未回収残高",'                     ||
            '"消込済残高",'                     ||
            '"修正済残高",'                     ||
            '"クレジットメモ残高",'             ||
            '"顧客パーティステータス",'         ||
            '"顧客アカウントステータス"'
    );
--
    -- 要求IDごとに処理
    FOR i IN 1..gn_request_id.COUNT LOOP
--
        -- ロックされていたらエラーで落とす
        OPEN target_cur(
            in_request_id => gn_request_id(i)
        );
        --
        LOOP
            -- 対象データ取得カーソル
            FETCH target_cur INTO target_rec;
            --
            EXIT WHEN target_cur%NOTFOUND;
            --
            -- 処理モード＝更新
            IF (gv_exe_mode = cv_execmode_upd) THEN
                --
                UPDATE
                      ra_customer_trx_all     rcta
                SET
                      rcta.attribute7       = gv_status_to                   -- 請求書保留ステータス
                WHERE 1 = 1
                AND   rcta.customer_trx_id  = target_rec.e_customer_trx_id   -- 取引ID(対象顧客、対象締日、対象変更ステータス)
                ;
            END IF;
            --
            -- ログに対象情報出力
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
               ,buff   =>                                                         '"' ||
                    gv_status                                                || '","' || 
                    target_rec.e_trx_number                                  || '","' ||
                    TO_CHAR(target_rec.e_trx_date        , cv_date_format)   || '","' ||
                    target_rec.e_name                                        || '","' ||
                    target_rec.e_attribute1                                  || '","' ||
                    target_rec.e_conc_name                                   || '","' || 
                    target_rec.e_request_id                                  || '","' || 
                    TO_CHAR(target_rec.e_last_update_date, cv_date_format)   || '","' || 
                    target_rec.e_account_number                              || '","' || 
                    target_rec.e_party_name                                  || '","' || 
                    target_rec.e_amount_due_original                         || '","' || 
                    target_rec.e_amount_due_remaining                        || '","' || 
                    target_rec.e_amount_applied                              || '","' || 
                    target_rec.e_amount_adjusted                             || '","' || 
                    target_rec.e_amount_credited                             || '","' || 
                    target_rec.e_hp_status                                   || '","' || 
                    target_rec.e_hca_status                                  || '"' 
            ); 
            -- 処理件数カウントアップ
            gn_target_cnt := gn_target_cnt + 1;
            --
        END LOOP;
        --
        -- 処理対象カーソルクローズ
        CLOSE target_cur;
--
    END LOOP;
    --
    gn_normal_cnt := gn_target_cnt;
--
--###########################  固定部 END   ############################
--
--
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,       --   エラー・メッセージ  --# 固定 #
    retcode             OUT    VARCHAR2,       --   リターン・コード    --# 固定 #
    iv_exe_mode         IN     VARCHAR2,       --   実行モード
    iv_bill_cust_code   IN     VARCHAR2,       --   請求先顧客
    iv_target_date      IN     VARCHAR2,       --   締日
    iv_business_date    IN     VARCHAR2,       --   業務日付
    iv_request_id       IN     VARCHAR2,       --   要求ID
    iv_status_from      IN     VARCHAR2,       --   更新対象ステータス
    iv_status_to        IN     VARCHAR2        --   更新後ステータス
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        iv_which   => 'LOG'
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
--
--
    -- ===============================================
    -- 初期処理
    -- ===============================================
    --
    -- 1.変数初期化
    gn_request_id.DELETE;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- 2.パラメータ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '実行モード：'   || iv_exe_mode
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '請求先顧客：'   || iv_bill_cust_code
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '締日：'         || TO_CHAR( TO_DATE ( iv_target_date,   cv_date_format ), cv_date_format2 )
    );
    IF (iv_business_date IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => '業務日付：' || TO_CHAR( TO_DATE ( iv_business_date, cv_date_format ), cv_date_format2 )
        );
    ELSE
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => '要求ID：'   || iv_request_id
        );
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '更新対象ステータス：' || iv_status_from
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '更新後ステータス：'   || iv_status_to
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL --改行
    );
--
    -- 3.必須パラメータチェック
    IF (iv_business_date IS NULL AND iv_request_id IS NULL) THEN
       lv_errmsg := '必須パラメータが入力されていません。'       || chr(10) || '業務日付か要求IDを入力してください。';
        -- リターンコード更新
        lv_retcode := cv_status_error;
    ELSIF (iv_business_date IS NOT NULL AND iv_request_id IS NOT NULL) THEN
       lv_errmsg := '業務日付と要求IDの両方が入力されています。' || chr(10) || 'どちらか一方のみを入力してください。';
        -- リターンコード更新
        lv_retcode := cv_status_error;
    END IF;
--
    IF( lv_retcode = cv_status_normal ) THEN
      -- パラメータをグローバル変数に設定
      gv_exe_mode       := iv_exe_mode;                             -- 実行モード
      gv_bill_cust_code := iv_bill_cust_code;                       -- 請求先顧客
      gd_target_date    := TO_DATE(iv_target_date, cv_date_format); -- 締日
      --
      -- 業務日付指定の場合は請求明細の作成日から要求IDを導出する
      IF (iv_business_date IS NOT NULL) THEN
         --
         gd_business_date  := TO_DATE(iv_business_date, 'RRRR/MM/DD HH24:MI:SS');
         --
         SELECT            rcta.request_id AS request_id
         BULK COLLECT INTO gn_request_id
         FROM              ra_customer_trx_all rcta
                          ,xxcfr_invoice_lines xil
         WHERE             1 = 1
         AND               rcta.customer_trx_id  = xil.trx_id
         -- 業務日付 翌日 の00:00≦作成日≦06:00
         AND               xil.creation_date    >= NVL(TRUNC(gd_business_date) + 1       , xil.creation_date)
         AND               xil.creation_date    <= NVL(TRUNC(gd_business_date) + 1 + 6/24, xil.creation_date)
         GROUP BY          rcta.request_id
         ;
         --
         -- 指定した業務日付に請求明細が作成されていなかった場合
         IF (gn_request_id.COUNT = 0) THEN
           lv_errmsg :=  '指定された業務日付に対して1件も要求IDが抽出されませんでした。';
           -- リターンコード更新
           lv_retcode := cv_status_error;
         END IF;
      -- 要求ID
      ELSE
          gn_request_id(1) := TO_NUMBER(iv_request_id);
      END IF;
--
    END IF;
--
    IF( lv_retcode = cv_status_normal ) THEN
      -- 変更対象ステータス
      gv_status_from := iv_status_from;
      -- 変更後ステータス
      gv_status_to   := iv_status_to;
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
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      --対象件数クリア
      gn_target_cnt := 0;
      --成功件数クリア
      gn_normal_cnt := 0;
      --スキップ件数クリア
      gn_warn_cnt   := 0;
      --エラー件数
      gn_error_cnt  := 1;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := '処理がエラー終了しました。';
    END IF;
--
    FND_FILE.PUT_LINE(
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
END XXCCP009A03C;
/
