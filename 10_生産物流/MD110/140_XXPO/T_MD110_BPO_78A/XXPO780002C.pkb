CREATE OR REPLACE PACKAGE BODY xxpo780002c
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : xxpo780002c(spec)
 * Description      : 請求書兼有償支給相殺確認書CSV出力
 * MD.050/070       : 月次〆切処理（有償支給相殺）Issue1.0  (T_MD050_BPO_780)
 *                    請求書兼有償支給相殺確認書CSV出力     (T_MD070_BPO_78B)
 * Version          : 1.0
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  init                       初期処理(A-1)
 *  get_proc_date              処理データ取得(A-2)
 *  data_output                データ出力(A-3)
 *  del_proc_date              処理データ削除(A-4)
 *  submain                    メイン処理プロシージャ
 *  main                       コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/09/10    1.0  N.Abe             新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
--
--################################  固定部 END   ###############################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo780002c';   -- パッケージ名
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO';             -- アプリケーション（XXPO）
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  ------------------------------
  -- グローバル変数
  ------------------------------
  gv_csv_head             fnd_new_messages.message_text%TYPE;   -- 見出し行
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- *** グローバル・カーソル
    CURSOR cur_main_data(
      in_request_id       NUMBER
    )
    IS
      SELECT xiw.vendor_name      AS  vendor_name       -- 取引先名
            ,xiw.zip              AS  zip               -- 郵便番号
            ,xiw.address          AS  address           -- 住所
            ,xiw.arrival_date     AS  arrival_date      -- 日付
            ,xiw.slip_num         AS  slip_num          -- 伝票No
            ,xiw.lot_no           AS  lot_no            -- ロットNo
            ,xiw.dept_name        AS  dept_name         -- 請求管理部署
            ,xiw.item_class_name  AS  item_class_name   -- 品目区分（名称）
            ,xiw.item_code        AS  item_code         -- 品目コード
            ,xiw.item_name        AS  item_name         -- 品目名称
            ,xiw.quantity         AS  quantity          -- 数量
            ,xiw.unit_price       AS  unit_price        -- 単価
            ,xiw.amount           AS  amount            -- 税抜金額
            ,xiw.tax              AS  tax               -- 消費税額
            ,xiw.tax_type         AS  tax_type          -- 税区分
            ,xiw.tax_include      AS  tax_include       -- 税込金額
            ,xiw.yusyo_year_month AS  yusyo_data        -- 有償年月
      FROM   xxpo_invoice_work  xiw
      WHERE  xiw.request_id = in_request_id
      ORDER BY xiw.vendor_code          -- 取引先コード
              ,xiw.item_class           -- 品目区分
              ,xiw.arrival_date         -- 着荷日
              ,xiw.item_code            -- 品目コード
    ;
--
    rec_main_date   cur_main_data%ROWTYPE;
--
  -- CSV出力用データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
    vendor_name       xxpo_invoice_work.vendor_name%TYPE      -- 取引先名
   ,zip               xxpo_invoice_work.zip%TYPE              -- 郵便番号
   ,address           xxpo_invoice_work.address%TYPE          -- 住所
   ,arrival_date      xxpo_invoice_work.arrival_date%TYPE     -- 日付
   ,slip_num          xxpo_invoice_work.slip_num%TYPE         -- 伝票No
   ,lot_no            xxpo_invoice_work.lot_no%TYPE           -- ロットNo
   ,dept_name         xxpo_invoice_work.dept_name%TYPE        -- 請求管理部門
   ,item_class_name   xxpo_invoice_work.item_class_name%TYPE  -- 品目区分（名称）
   ,item_code         xxpo_invoice_work.item_code%TYPE        -- 品目コード
   ,item_name         xxpo_invoice_work.item_name%TYPE        -- 品目名称
   ,quantity          xxpo_invoice_work.quantity%TYPE         -- 数量
   ,unit_price        xxpo_invoice_work.unit_price%TYPE       -- 単価
   ,amount            xxpo_invoice_work.amount%TYPE           -- 税抜金額
   ,tax               xxpo_invoice_work.tax%TYPE              -- 消費税額
   ,tax_type          xxpo_invoice_work.tax_type%TYPE         -- 税区分
   ,tax_include       xxpo_invoice_work.tax_include%TYPE      -- 税込金額
   ,yusyo_date        xxpo_invoice_work.yusyo_year_month%TYPE -- 有償年月
  ) ;
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  gt_main_data    tab_data_type_dtl;
--
--#####################  固定共通例外宣言部 START   ####################
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
--###########################  固定部 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    ln_data_cnt           NUMBER := 0;   -- データ件数取得用
    lv_err_code           VARCHAR2(100); -- エラーコード格納用
    lv_token_name1        VARCHAR2(100);      -- メッセージトークン名１
    lv_token_name2        VARCHAR2(100);      -- メッセージトークン名２
    lv_token_value1       VARCHAR2(100);      -- メッセージトークン値１
    lv_token_value2       VARCHAR2(100);      -- メッセージトークン値２
--
    -- *** ローカルカーソル ***
--
    -- *** ローカルレコード ***
--
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION;     -- 値取得エラー
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    --========================================
    -- 1.見出し行取得
    --========================================
    gv_csv_head := xxccp_common_pkg.get_msg(
                     iv_application  => gc_application_po         -- アプリケーション短縮名
                    ,iv_name         => 'APP-XXPO-40052'          -- メッセージコード
                   );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_proc_data
   * Description      : 処理データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_proc_data(
    in_request_id IN  NUMBER                    -- 01.要求ID
   ,ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_proc_data'; -- プログラム名
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
    -- *** ローカル・定数 ***
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_main_data(
      in_request_id    -- 要求ID
    );
    -- バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO gt_main_data;
    -- カーソルクローズ
    CLOSE cur_main_data;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_proc_data;
--
  /**********************************************************************************
   * Procedure Name   : data_output
   * Description      : データ出力(A-3)
   ***********************************************************************************/
  PROCEDURE data_output(
    ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_output'; -- プログラム名
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
    -- *** ローカル・定数 ***
    cv_delimit    CONSTANT VARCHAR2(10) := ',';                   -- 区切り文字
    cv_enclosed   CONSTANT VARCHAR2(2)  := '"';                   -- 単語囲み文字
--
    -- *** ローカル変数 ***
    lv_line_data           VARCHAR2(5000);                        -- OUTPUTデータ編集用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 見出しの出力
    ------------------------------------------
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_csv_head
    );
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      --データを編集
      lv_line_data :=     cv_enclosed || gt_main_data(i).vendor_name                            || cv_enclosed  -- 取引先名
         || cv_delimit || cv_enclosed || gt_main_data(i).zip                                    || cv_enclosed  -- 郵便番号
         || cv_delimit || cv_enclosed || gt_main_data(i).address                                || cv_enclosed  -- 住所
         || cv_delimit || cv_enclosed || TO_CHAR(gt_main_data(i).arrival_date, 'YYYY/MM/DD')    || cv_enclosed  -- 日付
         || cv_delimit || cv_enclosed || gt_main_data(i).yusyo_date                             || cv_enclosed  -- 有償年月
         || cv_delimit || cv_enclosed || gt_main_data(i).slip_num                               || cv_enclosed  -- 伝票No
         || cv_delimit || cv_enclosed || gt_main_data(i).lot_no                                 || cv_enclosed  -- ロットNo
         || cv_delimit || cv_enclosed || gt_main_data(i).dept_name                              || cv_enclosed  -- 請求管理部署
         || cv_delimit || cv_enclosed || gt_main_data(i).item_class_name                        || cv_enclosed  -- 品目区分（名称）
         || cv_delimit || cv_enclosed || gt_main_data(i).item_code                              || cv_enclosed  -- 品目コード
         || cv_delimit || cv_enclosed || gt_main_data(i).item_name                              || cv_enclosed  -- 品目名称
         || cv_delimit ||                gt_main_data(i).quantity                                               -- 数量
         || cv_delimit ||                gt_main_data(i).unit_price                                             -- 単価
         || cv_delimit ||                gt_main_data(i).amount                                                 -- 税抜金額
         || cv_delimit ||                gt_main_data(i).tax                                                    -- 消費税額
         || cv_delimit || cv_enclosed || gt_main_data(i).tax_type                               || cv_enclosed  -- 税区分
         || cv_delimit ||                gt_main_data(i).tax_include                                            -- 税込金額
      ;
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_output;
--
  /**********************************************************************************
   * Procedure Name   : del_proc_data
   * Description      : 処理データ削除(A-4)
   ***********************************************************************************/
  PROCEDURE del_proc_data(
    in_request_id IN  NUMBER                    -- 01.要求ID
   ,ov_errbuf     OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2                  -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2                  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_proc_data'; -- プログラム名
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
    -- *** ローカル・定数 ***
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- データ削除
    -- ====================================================
    DELETE xxpo_invoice_work
    WHERE  request_id = in_request_id
    ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_proc_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_request_id         IN     NUMBER           -- 01 : 要求ID
   ,ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT     VARCHAR2         -- リターン・コード             --# 固定 #
   ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000);                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1);                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000);                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- =====================================================
    -- A-1.初期処理
    -- =====================================================
    init(
      ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- A-2.処理データ取得
    -- =====================================================
    get_proc_data(
      in_request_id     => in_request_id      -- 01.要求ID
     ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- A-3.CSVデータ出力
    -- ==================================================
    data_output(
      ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- A-4.処理データ削除
    -- ==================================================
    del_proc_data(
      in_request_id     => in_request_id      -- 01.要求ID
     ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT    VARCHAR2         -- エラーメッセージ
   ,retcode               OUT    VARCHAR2         -- エラーコード
   ,in_request_id         IN     NUMBER           -- 01 : 要求ID
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000);      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1);         --   リターン・コード
    lv_errmsg               VARCHAR2(5000);      --   ユーザー・エラー・メッセージ
--
    lv_message_code         VARCHAR2(100);
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain(
      in_request_id     => in_request_id      -- 01 : 要求ID
     ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- 終了処理(A-5)
    -- ======================================================
    -- エラー・メッセージ出力
    IF ( lv_retcode = gv_status_error ) THEN
      -- エラー件数
      gn_error_cnt := 1;
--
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
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
    IF (lv_retcode = gv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = gv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = gv_status_error) THEN
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
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxpo780002c;
/