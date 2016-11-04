CREATE OR REPLACE PACKAGE BODY XXCCP002A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP002A01C(body)
 * Description      : 棚卸商品データCSVダウンロード
 * MD.070           : 棚卸商品データCSVダウンロード (MD070_IPO_CCP_002_A01)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/10/18    1.0   H.Sakihama      [E_本稼動_13895]新規作成
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
  gn_warn_cnt               NUMBER;                    -- 警告件数
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
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP002A01C';              -- パッケージ名
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_practice_month     IN  VARCHAR2      --   年月
   ,ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';                   -- プログラム名
    cv_org_code_p           CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
    -- メッセージコード
    cv_msg_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';          -- 在庫組織コード取得エラーメッセージ
    cv_msg_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';          -- 在庫組織ID取得エラーメッセージ
    cv_msg_00003            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';          -- 業務日付取得エラーメッセージ
    -- トークンコード
    cv_xxcoi_sn             CONSTANT VARCHAR2(9)   := 'XXCOI';                     -- SHORT_NAME_FOR_XXCOI
    cv_protok_sn            CONSTANT VARCHAR2(20)  := 'PRO_TOK';
    cv_orgcode_sn           CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf               VARCHAR2(5000);                                        -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                                           -- リターン・コード
    lv_errmsg               VARCHAR2(5000);                                        -- ユーザー・エラー・メッセージ
--
    -- ローカル変数
    ld_process_date         DATE;                                                  -- 業務日付
    ld_target_date          DATE;                                                  -- 対象日付
    ld_practice_month       DATE;                                                  -- 棚卸年月
    ln_organization_id      NUMBER;                                                -- 在庫組織ID
    lv_organization_code    VARCHAR2(30);                                          -- 在庫組織コード
    -- 出力用項目
    lv_out_data             VARCHAR2(3000);                                        -- 出力データ
    lv_description          mtl_secondary_inventories.description%TYPE;            -- 保管場所名称
    ln_page_num             NUMBER(5);                                             -- ページNo
    ln_line_num             NUMBER(2);                                             -- 行No
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 棚卸商品レコード取得
    CURSOR main_cur
    IS
      SELECT sub.practice_month   AS practice_month  -- 棚卸年月
            ,sub.base_code        AS base_code       -- 店舗コード
            ,sub.item_code        AS item_code       -- 品番コード
            ,sub.item_short_name  AS item_short_name -- 商品名
            ,sub.description      AS description     -- 保管場所名称
      FROM  (SELECT msi.description                     description               -- 保管場所名称
                   ,msi.attribute7                      base_code                 -- 拠点コード(店舗コード)
                   ,sib.sp_supplier_code                sp_supplier_code          -- 専門店仕入先コード
                   ,sib.item_code                       item_code                 -- 品名コード
                   ,SUBSTR(
                       (CASE  WHEN  TRUNC(TO_DATE(iib.attribute3, 'YYYY/MM/DD')) > TRUNC(ld_target_date)
                              THEN  iib.attribute1                                -- 群コード(旧)
                              ELSE  iib.attribute2                                -- 群コード(新)
                        END
                       ), 1, 3
                    )                                   gun_code                  -- 群コード
                   ,imb.item_short_name                 item_short_name           -- 略称
                   ,xirm.practice_month                 practice_month            -- 棚卸年月
             FROM   xxcoi_inv_reception_monthly     xirm                          -- 月次在庫受払表
                   ,mtl_secondary_inventories       msi                           -- 保管場所マスタ(INV)
                   ,mtl_system_items_b              msib                          -- Disc品目        (INV)
                   ,ic_item_mst_b                   iib                           -- OPM品目         (GMI)
                   ,xxcmn_item_mst_b                imb                           -- OPM品目アドオン (XXCMN)
                   ,xxcmm_system_items_b            sib                           -- Disc品目アドオン(XXCMM)
             WHERE  xirm.organization_id        = ln_organization_id
             AND    xirm.subinventory_type      = '4'                             -- 保管場所区分(専門店)
             AND    xirm.practice_month         = TO_CHAR(ADD_MONTHS(ld_practice_month, -1), 'YYYYMM')
             AND    xirm.inventory_kbn          = '2'                             -- 棚卸区分(月末)
             AND    xirm.inv_result + xirm.inv_result_bad <> 0                    -- 月首棚卸0以外
             AND    xirm.subinventory_code      = msi.secondary_inventory_name
             AND    xirm.organization_id        = msi.organization_id
             AND    msi.attribute1              = '4'                             -- 保管場所区分(専門店)
             AND    TRUNC(NVL(msi.disable_date, ld_target_date)) >= TRUNC(ld_target_date)
             AND    xirm.inventory_item_id      = msib.inventory_item_id
             AND    xirm.organization_id        = msib.organization_id
             AND    msib.segment1               = iib.item_no
             AND    iib.item_id                 = imb.item_id
             AND    imb.item_id                 = sib.item_id
             AND    TRUNC(ld_target_date) BETWEEN imb.start_date_active
                                              AND NVL(imb.end_date_active, TRUNC(ld_target_date))
           ) sub
      ORDER BY sub.base_code
              ,sub.description
              ,sub.sp_supplier_code
              ,sub.gun_code
              ,sub.item_code
      ;
    -- メインカーソルレコード型
    main_rec  main_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode    := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --==============================================================
    -- 入力パラメータ出力
    --==============================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '年月 : ' || iv_practice_month
    );
--
    --==================================================
    -- 棚卸年月設定
    --==================================================
    BEGIN
      ld_practice_month := TO_DATE(iv_practice_month, 'YYYYMM');
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf  := 'パラメータ「年月」には、日付として正しい年月を指定してください。';
        lv_retcode := cv_status_error;    -- 異常:2
        RAISE global_process_expt;
    END;
--
    --==================================================
    -- 在庫組織取得
    --==================================================
    -- 共通関数(在庫組織コード取得)を使用しプロファイルより在庫組織コードを取得します。
    lv_organization_code := FND_PROFILE.VALUE(cv_org_code_p);
    IF (lv_organization_code IS NULL) THEN
      -- プロファイル:在庫組織コード( &PRO_TOK )の取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00001
                   ,iv_token_name1  => cv_protok_sn
                   ,iv_token_value1 => cv_org_code_p
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      RAISE global_process_expt;
    END IF;
--
    -- 上記で取得した在庫組織コードをもとに共通部品(在庫組織ID取得)より在庫組織ID取得します。
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    --
    IF (ln_organization_id IS NULL) THEN
      -- 在庫組織コード( &ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00002
                   ,iv_token_name1  => cv_orgcode_sn
                   ,iv_token_value1 => lv_organization_code
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 対象日付取得
    --==================================================
    -- 業務日付取得
    ld_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00003
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      RAISE global_process_expt;
    END IF;
--
    -- 対象日付判定
    IF (LAST_DAY(ld_practice_month) > ld_process_date) THEN
      ld_target_date := ld_process_date;
    ELSE
      ld_target_date := LAST_DAY(ld_practice_month);
    END IF;
--
    --==================================================
    -- 入力パラメータチェック
    --==================================================
    IF (TO_CHAR(ld_practice_month, 'YYYYMM') > TO_CHAR(ld_process_date, 'YYYYMM')) THEN
      lv_errbuf  := 'パラメータ「年月」に未来月は設定できません。';
      lv_retcode := cv_status_error;    -- 異常:2
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- ヘッダ部作成
    --==================================================
    lv_out_data :=
              '"' || '棚卸年月'           || '"' -- 棚卸年月
    || ',' || '"' || '店舗コード'         || '"' -- 店舗コード
    || ',' || '"' || 'ページNo'           || '"' -- ページNo
    || ',' || '"' || '行No'               || '"' -- 行No
    || ',' || '"' || '品番コード'         || '"' -- 品番コード
    || ',' || '"' || '商品名'             || '"' -- 商品名
    ;
    --==================================================
    -- ヘッダ部出力
    --==================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_data
    );
    --==================================================
    -- 初期値設定
    --==================================================
    lv_description := 'XXXXX';                   -- 保管場所名
--
    --==================================================
    -- データ部取得
    --==================================================
    <<output_loop>>
    FOR main_rec IN main_cur LOOP
      -- 入力件数カウント
      gn_target_cnt  := gn_target_cnt + 1;
--
      --==================================================
      -- ページNo,行No設定
      --==================================================
      -- 保管場所名称が前レコードと変わった場合
      IF ( lv_description <> main_rec.description ) THEN
        lv_description := main_rec.description;  -- 保管場所名称を保持
        ln_page_num    := 1;                     -- ページNoの初期化
        ln_line_num    := 1;                     -- 行Noの初期化
      ELSIF (ln_line_num >= 16) THEN
        -- 行Noが最大値(16)以上の場合
        ln_page_num    := ln_page_num + 1;       -- ページNoの加算
        ln_line_num    := 1;                     -- 行Noの初期化
      ELSE
        ln_line_num    := ln_line_num + 1;       -- 行Noの加算
      END IF;
--
      --==================================================
      -- データ部を変数に格納
      --==================================================
      lv_out_data :=
                '"' || iv_practice_month        || '"' -- 棚卸年月
      || ',' || '"' || main_rec.base_code       || '"' -- 店舗コード
      || ',' || '"' || TO_CHAR(ln_page_num)     || '"' -- ページNo
      || ',' || '"' || TO_CHAR(ln_line_num)     || '"' -- 行No
      || ',' || '"' || main_rec.item_code       || '"' -- 品番コード
      || ',' || '"' || main_rec.item_short_name || '"' -- 商品名
      ;
--
      --==================================================
      -- データ部出力
      --==================================================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_data
      );
--
      -- 出力件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP output_loop;
    -- 対象件数=0であればメッセージ出力
    IF (gn_target_cnt = 0) THEN
     FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => CHR(10) || '対象データはありません。'
     );
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
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
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
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_practice_month     IN  VARCHAR2      --   年月
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_practice_month     -- 年月
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
    --
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP002A01C;
