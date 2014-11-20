CREATE OR REPLACE PACKAGE BODY xxcmn820001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820001c(body)
 * Description      : 標準原価取込
 * MD.050           : 標準原価マスタ T_MD050_BPO_820
 * MD.070           : 標準原価取込   T_MD070_BPO_82A
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  disp_report            レポート用データ出力プロシージャ
 *  delete_standard_if     インタフェーステーブル削除プロシージャ(A-6)
 *  modify_end_date        適用終了日編集プロシージャ(A-5)
 *  insert_xp_lines        仕入／標準単価明細挿入プロシージャ(A-4)
 *  insert_xp_headers      仕入／標準単価ヘッダ挿入プロシージャ(A-4)
 *  get_price_line_id      仕入／標準単価明細ID取得プロシージャ(A-3)
 *  get_price_h_id         仕入／標準単価ヘッダID取得プロシージャ(A-3)
 *  check_data             抽出データチェック処理プロシージャ(A-2)
 *  get_standard_if_lock   ロック取得プロシージャ
 *  get_profile            プロファイル取得プロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/11    1.0   ORACLE 青木祐介  main新規作成
 *  2008/06/23    1.1   ORACLE 椎名昭圭  適用終了日更新不具合修正
 *  2008/07/09    1.2   Oracle 山根一浩  I_S_192対応
 *  2008/09/10    1.3   Oracle 山根一浩  PT 2-2_18 指摘62対応
 *  2009/04/09    1.4   SCS丸下          本番障害1395 年度切替対応
 *  2009/04/27    1.5   SCS 椎名         本番障害1407対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  check_sub_main_expt         EXCEPTION;     -- サブメインのエラー
  check_data_expt             EXCEPTION;     -- チェック処理エラー
  check_lock_expt             EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100) := 'xxcmn820001c'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  gv_msg_kbn            CONSTANT VARCHAR2(5)   := 'XXCMN';
  -- 処理状況をあらわすステータス
  gn_data_status_normal CONSTANT NUMBER := 0; -- 正常
  gn_data_status_error  CONSTANT NUMBER := 1; -- 失敗
  gn_data_status_warn   CONSTANT NUMBER := 2; -- 警告
  --プロファイル
  gv_prf_max_date       CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';
--
  --トークン
  gv_tkn_ng_profile     CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_item_value     CONSTANT VARCHAR2(15) := 'ITEM_VALUE';
  gv_tkn_item_code_p    CONSTANT VARCHAR2(15) := 'ITEM_CODE_P';
  gv_tkn_item_code_c    CONSTANT VARCHAR2(15) := 'ITEM_CODE_C';
--
  --メッセージ番号
  -- 成功データ(見出し)
  gv_msg_data_normal    CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';
  -- エラーデータ(見出し)
  gv_msg_data_error     CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';
  -- スキップデータ(見出し)
  gv_msg_data_warn      CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';
  -- プロファイル取得エラー
  gv_msg_no_profile     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';
  -- 存在チェックエラー
  gv_msg_ng_item        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10141';
  -- 品目区分チェックエラー
  gv_msg_ng_product     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10045';
  -- 適用開始日時点存在チェックエラー
  gv_msg_ng_s_time      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10142';
  -- 適用開始日チェックエラー1
  gv_msg_ng_s_date1     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10046';
  -- 適用開始日チェックエラー2
  gv_msg_ng_s_date2     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10047';
  -- 費目チェックエラー
  gv_msg_ng_exp_type    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10143';
  -- 項目チェックエラー
  gv_msg_ng_exp_de_type CONSTANT VARCHAR2(15) := 'APP-XXCMN-10144';
  -- 抽出データ重複チェックエラー
  gv_msg_ng_repetition  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10145';
  -- 登録済チェックエラー
  gv_msg_ng_registered  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10051';
  -- 単価チェックエラー
  gv_msg_ng_unit_price  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10048';
  -- 親品目取得エラー
  gv_msg_ng_itemcode_p  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10042';
  -- 子品目取得エラー1
  gv_msg_ng_itemcode_c1 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10043';
  -- 子品目取得エラー2
  gv_msg_ng_itemcode_c2 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10044';
  -- 親品目単価エラー
  gv_msg_ng_unitprice_p CONSTANT VARCHAR2(15) := 'APP-XXCMN-10049';
  -- ロック取得エラー
  gv_msg_ng_get_lock    CONSTANT VARCHAR2(15) := 'APP-XXCMN-10146';
--
  -- 対象DB名
  gv_xxcmn_standard_cost_if CONSTANT VARCHAR2(100) := '標準原価インタフェース';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- レポートの状態、出力メッセージを格納するレコード
  TYPE out_report_rec IS RECORD(
    -- 標準原価インタフェース.要求ID
    request_id         xxcmn_standard_cost_if.request_id%TYPE,
    -- 標準原価インタフェース.品目
    item_code          xxcmn_standard_cost_if.item_code%TYPE,
    -- 標準原価インタフェース.適用開始日
    s_date_active      xxcmn_standard_cost_if.start_date_active%TYPE,
    -- 標準原価インタフェース.費目
    e_item_type        xxcmn_standard_cost_if.expence_item_type%TYPE,
    -- 標準原価インタフェース.項目
    e_item_detail_type xxcmn_standard_cost_if.expence_item_detail_type%TYPE,
    -- 標準原価インタフェース.内訳品目
    item_code_detail   xxcmn_standard_cost_if.item_code_detail%TYPE,
    -- 標準原価インタフェース.単価
    unit_price         xxcmn_standard_cost_if.unit_price%TYPE,
--
    row_level_status NUMBER,         -- 0.正常,1.失敗,2.警告
    skip_message     VARCHAR2(1000), -- 表示用メッセージ
    message1         VARCHAR2(1000), -- 表示用メッセージ
    message2         VARCHAR2(1000), -- 表示用メッセージ
    message3         VARCHAR2(1000), -- 表示用メッセージ
    message4         VARCHAR2(1000), -- 表示用メッセージ
    message5         VARCHAR2(1000), -- 表示用メッセージ
    message6         VARCHAR2(1000), -- 表示用メッセージ
    message7         VARCHAR2(1000)  -- 表示用メッセージ
  );
--
  -- レポート情報を格納するテーブル型の定義
  TYPE out_report_tbl IS
    TABLE OF out_report_rec INDEX BY BINARY_INTEGER;
--
  -- 標準原価インタフェース 削除用 要求ID
  TYPE request_id_tbl    IS
    TABLE OF xxcmn_standard_cost_if.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価ヘッダ 挿入用 ヘッダID
  TYPE price_header_id_tbl IS
    TABLE OF xxpo_price_headers.price_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価ヘッダ 挿入用 品目ID
  TYPE item_id_tbl       IS
    TABLE OF xxpo_price_headers.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価ヘッダ 挿入用 品目
  TYPE item_code_tbl       IS
    TABLE OF xxpo_price_headers.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価ヘッダ 挿入用 適用開始日
  TYPE s_date_tbl          IS
    TABLE OF xxpo_price_headers.start_date_active%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価ヘッダ 挿入用 内訳合計
  TYPE total_amount_tbl    IS
    TABLE OF xxpo_price_headers.total_amount%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価明細 挿入用 明細ID
  TYPE price_line_id_tbl   IS
    TABLE OF xxpo_price_lines.price_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価明細 挿入用 ヘッダID
  TYPE price_header_line_id_tbl IS
    TABLE OF xxpo_price_lines.price_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価明細 挿入用 費目
  TYPE exp_item_tbl        IS
    TABLE OF xxpo_price_lines.expense_item_type%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価明細 挿入用 項目
  TYPE exp_item_det_tbl    IS
    TABLE OF xxpo_price_lines.expense_item_detail_type%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価明細 挿入用 内訳品目
  TYPE item_code_det_tbl   IS
    TABLE OF xxpo_price_lines.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入／標準単価明細 挿入用 単価
  TYPE unit_price_tbl      IS
    TABLE OF xxpo_price_lines.unit_price%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_max_date                 VARCHAR2(10); -- 最大日付
  gn_data_status              NUMBER := 0;  -- データチェックステータス
  gn_request_id_cnt           NUMBER := 0;  -- リクエストID数
  gt_out_report_tbl           out_report_tbl;
  gt_request_id_tbl           request_id_tbl;
  -- 仕入／標準単価ヘッダ 挿入用 ヘッダID
  gt_price_header_id_tbl      price_header_id_tbl;
  -- 仕入／標準単価ヘッダ 挿入用 品目ID
  gt_item_id_tbl            item_id_tbl;
  -- 仕入／標準単価ヘッダ 挿入用 品目
  gt_item_code_tbl            item_code_tbl;
  -- 仕入／標準単価ヘッダ 挿入用 適用開始日
  gt_s_date_tbl               s_date_tbl;
  -- 仕入／標準単価ヘッダ 挿入用 内訳合計
  gt_total_amount_tbl         total_amount_tbl;
  -- 仕入／標準単価明細 挿入用 ヘッダID
  gt_price_header_line_id_tbl price_header_line_id_tbl;
  -- 仕入／標準単価明細 挿入用 明細ID
  gt_price_line_id_tbl        price_line_id_tbl;
  -- 仕入／標準単価明細 挿入用 費目
  gt_exp_item_tbl             exp_item_tbl;
  -- 仕入／標準単価明細 挿入用 項目
  gt_exp_item_det_tbl         exp_item_det_tbl;
  -- 仕入／標準単価明細 挿入用 内訳品目
  gt_item_code_det_tbl        item_code_det_tbl;
  -- 仕入／標準単価明細 挿入用 単価
  gt_unit_price_tbl           unit_price_tbl;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : レポート用データ出力プロシージャ
   ***********************************************************************************/
  PROCEDURE disp_report(
    disp_kbn       IN         NUMBER,       -- 表示対象区分(0:正常,1:異常,2:警告)
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_report_rec out_report_rec;
    ln_disp_cnt   NUMBER;
    lv_dspbuf     VARCHAR2(5000);  -- エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ###############################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   ############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 正常
    IF (disp_kbn = gn_data_status_normal) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_normal);
--
    -- エラー
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_error);
--
    -- 警告
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_warn);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 設定されているレポートの出力
    <<disp_report_loop>>
    FOR ln_disp_cnt IN 1..gn_target_cnt LOOP
      lr_report_rec := gt_out_report_tbl(ln_disp_cnt);
--
      -- 対象
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
--
        --入力データの再構成
        lv_dspbuf := lr_report_rec.request_id
          || gv_msg_pnt || lr_report_rec.item_code
          || gv_msg_pnt || TO_CHAR(lr_report_rec.s_date_active,'YYYY/MM/DD')
          || gv_msg_pnt || lr_report_rec.e_item_type
          || gv_msg_pnt || lr_report_rec.e_item_detail_type
          || gv_msg_pnt || lr_report_rec.item_code_detail
          || gv_msg_pnt || lr_report_rec.unit_price;
--
        -- レポートデータの出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- メッセージデータの出力
        IF (lr_report_rec.message1 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message1);
        END IF;
        IF (lr_report_rec.message2 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message2);
        END IF;
        IF (lr_report_rec.message3 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message3);
        END IF;
        IF (lr_report_rec.message4 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message4);
        END IF;
        IF (lr_report_rec.message5 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message5);
        END IF;
        IF (lr_report_rec.message6 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message6);
        END IF;
        IF (lr_report_rec.message7 IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message7);
        END IF;
        IF (lr_report_rec.skip_message IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.skip_message);
        END IF;
--
      END IF;
--
    END LOOP disp_report_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
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
--#####################################  固定部 END   ############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : delete_standard_if
   * Description      : インタフェーステーブル削除プロシージャ(A-6)
   ***********************************************************************************/
  PROCEDURE delete_standard_if(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_standard_if'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    FORALL ln_count IN 1..gn_request_id_cnt
      DELETE xxcmn_standard_cost_if xsci             -- 標準原価インタフェース
      WHERE  xsci.request_id = gt_request_id_tbl(ln_count);  -- 要求ID
--
    -- ==============================================================
    -- メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    -- ==============================================================
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
  END delete_standard_if;
--
  /**********************************************************************************
   * Function Name    : modify_end_date
   * Description      : 適用終了日編集プロシージャ(A-5)
   ***********************************************************************************/
  PROCEDURE modify_end_date(
    in_insert_user_id         IN NUMBER,            -- 1.ユーザーID
    id_insert_date            IN DATE,              -- 2.更新日
    in_insert_login_id        IN NUMBER,            -- 3.ログインID
    in_insert_request_id      IN NUMBER,            -- 4.要求ID
    in_insert_program_appl_id IN NUMBER,            -- 5.コンカレント・プログラムアプリケーションID
    in_insert_program_id      IN NUMBER,            -- 6.コンカレント・プログラムID
    ov_errbuf                 OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'modify_end_date'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cd_max_date         CONSTANT DATE := FND_DATE.CANONICAL_TO_DATE( gv_max_date );   -- MAX日付
    cv_price_standard   CONSTANT VARCHAR2(1) := '2';    -- マスタ区分（標準）
--
    -- *** ローカル変数 ***
    ld_past_s_date_active DATE;   -- 前歴の適用開始日
--
    -- *** ローカル・カーソル ***
    CURSOR  get_insert_data_cur IS
    SELECT  xph.item_code                                                AS item_code
           ,xph.start_date_active                                        AS s_date_active
           ,MAX(xph.start_date_active) over (PARTITION BY xph.item_code) AS MAX_START_DATE_ACTIVE
    FROM    xxpo_price_headers      xph,    -- 仕入／標準単価ヘッダ
            xxcmn_standard_cost_if  xsci    -- 標準原価インタフェース
    WHERE   xph.item_code           =  xsci.item_code
    AND     xph.price_type          = cv_price_standard
    ORDER BY xph.item_code, xph.start_date_active DESC;
    -- *** ローカル・レコード ***
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
--
    <<get_parnet_price_loop>>
    FOR get_history_data IN  get_insert_data_cur  LOOP
      -- 適用開始日 = MAX_START_DATE_ACTIVEの場合はそのレコードの適用終了日を9999/12/31に更新する
      IF (get_history_data.s_date_active = get_history_data.MAX_START_DATE_ACTIVE) THEN
        UPDATE  xxpo_price_headers xph      -- 仕入／標準単価ヘッダ
        SET     xph.end_date_active         = cd_max_date
               ,xph.last_updated_by         = in_insert_user_id
               ,xph.last_update_date        = id_insert_date
               ,xph.last_update_login       = in_insert_login_id
               ,xph.request_id              = in_insert_request_id
               ,xph.program_application_id  = in_insert_program_appl_id
               ,xph.program_id              = in_insert_program_id
               ,xph.program_update_date     = id_insert_date
        WHERE   xph.item_code               = get_history_data.item_code
        AND     xph.start_date_active       = get_history_data.s_date_active
        AND     xph.price_type              = cv_price_standard;
--
      END IF;
--
      -- ローカル変数の初期化
      ld_past_s_date_active := NULL;  -- 前歴の適用開始日
--
      -- 前歴を取得する
      SELECT  MAX(xph.start_date_active)  AS s_date_active
      INTO    ld_past_s_date_active
      FROM    xxpo_price_headers xph      -- 仕入／標準単価ヘッダ
      WHERE   xph.item_code               = get_history_data.item_code
      AND     xph.start_date_active       < get_history_data.s_date_active
      AND     xph.price_type              = cv_price_standard;
--
      -- 前歴の適用開始日がNULLでない場合は前歴の適用終了日を更新する
      IF (ld_past_s_date_active IS NOT NULL) THEN
        UPDATE  xxpo_price_headers xph      -- 仕入／標準単価ヘッダ
        SET     xph.end_date_active         = get_history_data.s_date_active - 1
               ,xph.last_updated_by         = in_insert_user_id
               ,xph.last_update_date        = id_insert_date
               ,xph.last_update_login       = in_insert_login_id
               ,xph.request_id              = in_insert_request_id
               ,xph.program_application_id  = in_insert_program_appl_id
               ,xph.program_id              = in_insert_program_id
               ,xph.program_update_date     = id_insert_date
        WHERE   xph.item_code               = get_history_data.item_code
        AND     xph.start_date_active       = ld_past_s_date_active
        AND     xph.price_type              = cv_price_standard;
--
      END IF;
--
    END LOOP get_parnet_price_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END modify_end_date;
--
  /**********************************************************************************
   * Procedure Name   : insert_xp_lines
   * Description      : 仕入／標準単価明細挿入プロシージャ(A-4)
   ***********************************************************************************/
  PROCEDURE insert_xp_lines(
    in_insert_user_id         IN NUMBER,            -- 1.ユーザーID
    id_insert_date            IN DATE,              -- 2.更新日
    in_insert_login_id        IN NUMBER,            -- 3.ログインID
    in_insert_request_id      IN NUMBER,            -- 4.要求ID
    in_insert_program_appl_id IN NUMBER,            -- 5.コンカレント・プログラムアプリケーションID
    in_insert_program_id      IN NUMBER,            -- 6.コンカレント・プログラムID
    ov_errbuf                 OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xp_lines'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 登録処理
    FORALL ln_cnt_loop IN 1 .. gt_price_line_id_tbl.COUNT
      INSERT INTO xxpo_price_lines xpl(   -- 仕入／標準単価明細
        xpl.price_line_id            -- 明細ID
        ,xpl.price_header_id          -- ヘッダID
        ,xpl.item_code                -- 内訳品目
        ,xpl.expense_item_type        -- 費目区分
        ,xpl.expense_item_detail_type -- 項目区分
        ,xpl.unit_price               -- 単価
        ,xpl.created_by               -- 作成者
        ,xpl.creation_date            -- 作成日
        ,xpl.last_updated_by          -- 最終更新者
        ,xpl.last_update_date         -- 最終更新日
        ,xpl.last_update_login        -- 最終更新ログイン
        ,xpl.request_id               -- 要求ID
        ,xpl.program_application_id   -- コンカレント・プログラム・アプリケーションID
        ,xpl.program_id               -- コンカレント・プログラムID
        ,xpl.program_update_date)     -- プログラム更新日
      VALUES(
        gt_price_line_id_tbl(ln_cnt_loop)        -- 明細ID
        ,gt_price_header_line_id_tbl(ln_cnt_loop) -- ヘッダID
        ,gt_item_code_det_tbl(ln_cnt_loop)        -- 内訳品目
        ,gt_exp_item_tbl(ln_cnt_loop)             -- 費目区分
        ,gt_exp_item_det_tbl(ln_cnt_loop)         -- 項目区分
        ,gt_unit_price_tbl(ln_cnt_loop)           -- 単価
        ,in_insert_user_id                        -- 作成者
        ,id_insert_date                           -- 作成日
        ,in_insert_user_id                        -- 最終更新者
        ,id_insert_date                           -- 最終更新日
        ,in_insert_login_id                       -- 最終更新ログイン
        ,in_insert_request_id                     -- 要求ID
        ,in_insert_program_appl_id                -- コンカレント・プログラム・アプリケーションID
        ,in_insert_program_id                     -- コンカレント・プログラムID
        ,id_insert_date);                         -- プログラム更新日
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END insert_xp_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_xp_headers
   * Description      : 仕入／標準単価ヘッダ挿入プロシージャ(A-4)
   ***********************************************************************************/
  PROCEDURE insert_xp_headers(
    in_insert_user_id         IN NUMBER,            -- 1.ユーザーID
    id_insert_date            IN DATE,              -- 2.更新日
    in_insert_login_id        IN NUMBER,            -- 3.ログインID
    in_insert_request_id      IN NUMBER,            -- 4.要求ID
    in_insert_program_appl_id IN NUMBER,            -- 5.コンカレント・プログラムのアプリケーションID
    in_insert_program_id      IN NUMBER,            -- 6.コンカレント・プログラムID
    ov_errbuf                 OUT NOCOPY  VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xp_headers'; -- プログラム名
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
    cv_price_standard     CONSTANT VARCHAR2(1) := '2';    -- マスタ区分（標準）
    cv_not_change         CONSTANT VARCHAR2(1) := 'N';    -- 変更処理フラグ（変更なし）
--
    -- *** ローカル変数 ***
    ld_end_date DATE := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 登録処理
    FORALL ln_cnt_loop IN 1 .. gt_price_header_id_tbl.COUNT
      INSERT INTO xxpo_price_headers  xph(   -- 仕入／標準単価ヘッダ
        xph.price_header_id         -- ヘッダID
        ,xph.price_type             -- マスタ区分
        ,xph.item_id                -- 品目ID
        ,xph.item_code              -- 品目
        ,xph.start_date_active      -- 適用開始日
        ,xph.end_date_active        -- 適用終了日
        ,xph.total_amount           -- 内訳合計
        ,xph.record_change_flg      -- 変更処理フラグ
        ,xph.created_by             -- 作成者
        ,xph.creation_date          -- 作成日
        ,xph.last_updated_by        -- 最終更新者
        ,xph.last_update_date       -- 最終更新日
        ,xph.last_update_login      -- 最終更新ログイン
        ,xph.request_id             -- 要求ID
        ,xph.program_application_id -- コンカレント・プログラム・アプリケーションID
        ,xph.program_id             -- コンカレント・プログラムID
        ,xph.program_update_date)    -- プログラム更新日
      VALUES(
        gt_price_header_id_tbl(ln_cnt_loop)  -- ヘッダID
        ,cv_price_standard                   -- マスタ区分
        ,gt_item_id_tbl(ln_cnt_loop)         -- 品目ID
        ,gt_item_code_tbl(ln_cnt_loop)       -- 品目
        ,gt_s_date_tbl(ln_cnt_loop)          -- 適用開始日
        ,ld_end_date                         -- 適用終了日
        ,gt_total_amount_tbl(ln_cnt_loop)    -- 内訳合計
        ,cv_not_change                       -- 変更処理フラグ
        ,in_insert_user_id                   -- 作成者
        ,id_insert_date                      -- 作成日
        ,in_insert_user_id                   -- 最終更新者
        ,id_insert_date                      -- 最終更新日
        ,in_insert_login_id                  -- 最終更新ログイン
        ,in_insert_request_id                -- 要求ID
        ,in_insert_program_appl_id           -- コンカレント・プログラム・アプリケーションID
        ,in_insert_program_id                -- コンカレント・プログラムID
        ,id_insert_date);                    -- プログラム更新日
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END insert_xp_headers;
--
  /**********************************************************************************
   * Procedure Name   : get_price_line_id
   * Description      : 仕入／標準単価明細ID取得プロシージャ(A-3)
   ***********************************************************************************/
  PROCEDURE get_price_line_id(
    in_price_l_id IN OUT NOCOPY NUMBER,   -- 1.レコード
    ov_errbuf     OUT NOCOPY    VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY    VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY    VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price_line_id'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 仕入／標準単価明細IDをシーケンスより取得
    SELECT xxpo_price_lines_s1.NEXTVAL
    INTO in_price_l_id
    FROM dual;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END get_price_line_id;
--
  /**********************************************************************************
   * Procedure Name   : get_price_h_id
   * Description      : 仕入／標準単価ヘッダID取得プロシージャ(A-3)
   ***********************************************************************************/
  PROCEDURE get_price_h_id(
    in_price_h_id IN OUT NOCOPY NUMBER,   -- 1.レコード
    ov_errbuf     OUT NOCOPY    VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY    VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY    VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price_h_id'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 仕入／標準単価ヘッダIDをシーケンスより取得
    SELECT xxpo_price_headers_all_s1.NEXTVAL
    INTO in_price_h_id
    FROM dual;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END get_price_h_id;
--
/**********************************************************************************
   * Procedure Name   : check_data
   * Description      : 抽出データチェック処理プロシージャ(A-2)
   ***********************************************************************************/
  PROCEDURE check_data(
    ir_report_rec   IN OUT NOCOPY out_report_rec, -- 1.レコード
    in_total_amount IN OUT NOCOPY NUMBER,         -- 2.単価合計
    in_item_id      IN OUT NOCOPY NUMBER,         -- 3.品目ID
    ov_errbuf       OUT NOCOPY VARCHAR2,          --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,          --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)          --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- プログラム名
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
    cv_obsolete_handling   CONSTANT VARCHAR2(1) := '0';     -- 廃止区分（取扱中）
    cv_obsolete_abolition  CONSTANT VARCHAR2(1) := '1';     -- 廃止区分（廃止）
    cv_year_start_date     CONSTANT VARCHAR2(5) := '05/01'; -- 年度開始日
    cv_item_product        CONSTANT VARCHAR2(1) := '5';     -- 品目区分（製品）
    cv_price_standard      CONSTANT VARCHAR2(1) := '2';    -- マスタ区分（標準）
    -- 費目コードタイプ
    cv_expense_type        CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE';
    -- 項目コードタイプ
    cv_expense_detail_type CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_DETAIL_TYPE';
--
    -- *** ローカル変数 ***
    ln_count            NUMBER := 0;
    ln_price            NUMBER := 0;
    ln_price_trunc      NUMBER := 0;
    ln_parent_item_id   NUMBER;
    ln_parent_price     NUMBER;
    ld_start_date       DATE;
    lv_sys_year         VARCHAR2(4);
    lv_sys_date         VARCHAR2(20);
    lv_item_year        VARCHAR2(4);
    lv_item_date        VARCHAR2(20);
    lv_parent_item_code VARCHAR2(10);
--
    -- *** ローカル・カーソル ***
    -- 子単価取得カーソル xsli_request
    CURSOR parent_price_cur(iv_item_code VARCHAR2
                            ,in_parent_item_id NUMBER
                            ,id_start_date DATE)IS
      SELECT ximv.item_no item_code
            ,ximv.obsolete_class obsolete_class
      FROM xxcmn_item_mst2_v ximv -- OPM品目情報VIEW2
      WHERE ximv.parent_item_id = in_parent_item_id
        AND ximv.item_no <> iv_item_code
        AND ximv.start_date_active <= id_start_date
        AND ximv.end_date_active >= id_start_date;
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- 品目存在チェック 対象品目が登録されていること
    BEGIN
      SELECT ximv.item_id
      INTO in_item_id
      FROM xxcmn_item_mst2_v ximv    -- OPM品目情報VIEW2
      WHERE ximv.item_no = ir_report_rec.item_code
-- 2009/04/27 v1.5 DELETE START
--        AND ximv.obsolete_class = cv_obsolete_handling
--        AND ximv.obsolete_date IS NULL
-- 2009/04/27 v1.5 DELETE END
        AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 品目存在チェックNG
        ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
          gv_msg_kbn, gv_msg_ng_item,
          gv_tkn_item_value, ir_report_rec.item_code);
        RAISE check_data_expt;
    END;
--
    -- 内訳品目がNULLの場合には不要
    IF (ir_report_rec.item_code_detail IS NOT NULL) THEN
      -- 内訳品目存在チェック 対象内訳品目が登録されていること
      SELECT COUNT(ximv.item_id)
      INTO ln_count
      FROM xxcmn_item_mst2_v ximv    -- OPM品目情報VIEW2
      WHERE ximv.item_no = ir_report_rec.item_code_detail
-- 2009/04/27 v1.5 DELETE START
--        AND ximv.obsolete_class = cv_obsolete_handling
--        AND ximv.obsolete_date IS NULL
-- 2009/04/27 v1.5 DELETE END
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
        -- 内訳品目存在チェックNG
        ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
          gv_msg_kbn, gv_msg_ng_item,
          gv_tkn_item_value, ir_report_rec.item_code_detail);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- 品目区分チェック 品目区分が「製品」であること
    SELECT COUNT(ximv.item_id)
    INTO ln_count
    FROM xxcmn_item_mst2_v ximv    -- OPM品目情報VIEW2
        ,xxcmn_item_categories3_v xicv --OPMカテゴリ情報VIEW3
    WHERE ximv.item_no = ir_report_rec.item_code
      AND ximv.item_id = xicv.item_id
      AND xicv.item_class_code = cv_item_product
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- 品目区分チェックNG
      ir_report_rec.message1 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_product,
        gv_tkn_item_value, ir_report_rec.item_code);
    END IF;
--
    -- 適用開始日時点存在チェック 適用開始日時点で登録されていること
    SELECT COUNT(ximv.item_id)
    INTO ln_count
    FROM xxcmn_item_mst2_v ximv    -- OPM品目情報VIEW2
    WHERE ximv.item_no = ir_report_rec.item_code
      AND ximv.start_date_active <= ir_report_rec.s_date_active
      AND ximv.end_date_active >= ir_report_rec.s_date_active
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- 適用開始日時点存在チェックNG
      ir_report_rec.message2 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_s_time,
        gv_tkn_item_value, ir_report_rec.item_code);
    END IF;
--
    -- 内訳品目がNULLの場合には不要
    IF (ir_report_rec.item_code_detail IS NOT NULL) THEN
      -- 適用開始日時点存在チェック
      SELECT COUNT(ximv.item_id)
      INTO ln_count
      FROM xxcmn_item_mst2_v ximv    -- OPM品目情報VIEW
      WHERE ximv.item_no = ir_report_rec.item_code_detail
        AND ximv.start_date_active <= ir_report_rec.s_date_active
        AND ximv.end_date_active >= ir_report_rec.s_date_active
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
        -- 適用開始日時点存在チェックNG
        ir_report_rec.message3 := xxcmn_common_pkg.get_msg(
          gv_msg_kbn, gv_msg_ng_s_time,
          gv_tkn_item_value, ir_report_rec.item_code_detail);
      END IF;
    END IF;
--
    lv_sys_year := TO_CHAR(SYSDATE,'YYYY');
--
    lv_item_date := TO_CHAR(ir_report_rec.s_date_active,'MM/DD');
--
    ld_start_date :=
      FND_DATE.STRING_TO_DATE((lv_sys_year || '/' || cv_year_start_date),'YYYY/MM/DD');
--
-- 2009/04/09 DEL START
/*
    -- 適用開始日チェック1 適用開始日年度がシステム年度以降であること
    IF (ir_report_rec.s_date_active < ld_start_date) THEN
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_s_date1,
        gv_tkn_item_value, TO_CHAR(ir_report_rec.s_date_active, 'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
*/
-- 2009/04/09 DEL END
--
    -- 適用開始日チェック2 適用開始日が5月1日であること
    IF (lv_item_date <> cv_year_start_date) THEN
      ir_report_rec.message4 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_s_date2,
        gv_tkn_item_value, TO_CHAR(ir_report_rec.s_date_active, 'YYYY/MM/DD'));
    END IF;
--
    -- 費目チェック 費目が存在していること
    SELECT COUNT(xlvv.lookup_code)
    INTO ln_count
    FROM xxcmn_lookup_values_v xlvv -- クイックコード情報VIEW
    WHERE xlvv.lookup_type = cv_expense_type
      AND xlvv.attribute1 = ir_report_rec.e_item_type
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- 費目チェックNG
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_exp_type,
        gv_tkn_item_value, ir_report_rec.e_item_type);
      RAISE check_data_expt;
    END IF;
--
    -- 項目チェック 項目が存在していること
    SELECT COUNT(xlvv.lookup_code)
    INTO ln_count
    FROM xxcmn_lookup_values_v xlvv -- クイックコード情報VIEW
    WHERE xlvv.lookup_type = cv_expense_detail_type
      AND xlvv.attribute1 = ir_report_rec.e_item_detail_type
      AND xlvv.attribute2 = ir_report_rec.e_item_type
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
      -- 項目チェックNG
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_exp_de_type,
        gv_tkn_item_value, ir_report_rec.e_item_detail_type);
      RAISE check_data_expt;
    END IF;
--
    -- 抽出データ重複チェック 同一データが存在していないこと
    SELECT COUNT(xsci.item_code)
    INTO ln_count
    FROM xxcmn_standard_cost_if xsci -- 標準原価インタフェース
    WHERE xsci.start_date_active = ir_report_rec.s_date_active
      AND xsci.item_code = ir_report_rec.item_code
      AND xsci.expence_item_type = ir_report_rec.e_item_type
      AND xsci.expence_item_detail_type = ir_report_rec.e_item_detail_type
      AND xsci.item_code_detail = ir_report_rec.item_code_detail
      AND xsci.request_id = ir_report_rec.request_id;
--
    IF (ln_count >= 2) THEN
      -- 抽出データ重複チェックNG
      ir_report_rec.message5 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_repetition);
    END IF;
--
    -- 登録済チェック ヘッダに同一情報が登録されていないこと
    SELECT COUNT(xph.price_header_id)
    INTO ln_count
    FROM xxpo_price_headers xph -- 仕入／標準原価ヘッダ
    WHERE xph.price_type = cv_price_standard
      AND xph.item_code = ir_report_rec.item_code
      AND xph.start_date_active >= ir_report_rec.s_date_active
      AND ROWNUM = 1;
--
    IF (ln_count = 1) THEN
      -- 登録済チェックNG
      ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_registered,
        gv_tkn_item_value, ir_report_rec.item_code);
      RAISE check_data_expt;
    END IF;
--
    -- 単価チェック 単価に小数点が含まれていないこと
    SELECT SUM(xsci.unit_price)
    INTO ln_price
    FROM xxcmn_standard_cost_if xsci -- 標準原価インタフェース
    WHERE xsci.start_date_active = ir_report_rec.s_date_active
      AND xsci.item_code = ir_report_rec.item_code;
--
    ln_price_trunc := TRUNC(ln_price);
--
    IF (ln_price <> ln_price_trunc) THEN
      -- 単価チェックNG
      ir_report_rec.message6 := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_ng_unit_price,
        gv_tkn_item_value, ln_price);
    END IF;
    -- 単価合計格納
    in_total_amount := ln_price;
--
    -- 親子関係チェック
    BEGIN
      SELECT ximv1.item_no
            ,ximv2.parent_item_id
      INTO lv_parent_item_code
          ,ln_parent_item_id
      FROM xxcmn_item_mst2_v ximv1           -- OPM品目情報VIEW
          ,xxcmn_item_mst2_v ximv2           -- OPM品目情報VIEW
      WHERE ximv1.item_id = ximv2.parent_item_id
        AND ximv2.item_no = ir_report_rec.item_code
        AND ximv2.start_date_active <= ld_start_date
        AND ximv2.end_date_active >= ld_start_date
        AND ROWNUM = 1;
--
      -- 抽出データと親品目データが一致しない場合（親品目情報を取得）
      IF (lv_parent_item_code <> ir_report_rec.item_code) THEN
        SELECT COUNT(xsci.item_code)
        INTO ln_count
        FROM xxcmn_standard_cost_if xsci -- 標準原価インタフェース
        WHERE xsci.item_code = lv_parent_item_code;
        IF (ln_count = 0) THEN
          ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
            gv_msg_kbn, gv_msg_ng_itemcode_p,
            gv_tkn_item_code_p, lv_parent_item_code,
            gv_tkn_item_code_c, ir_report_rec.item_code);
          RAISE check_data_expt;
        END IF;
--
        SELECT SUM(xsci.unit_price)
        INTO ln_parent_price
        FROM xxcmn_standard_cost_if xsci -- 標準原価インタフェース
        WHERE xsci.item_code = lv_parent_item_code;
--
        -- 親品目単価と子品目単価が一致しない場合
        IF ((ln_price IS NULL) AND (ln_parent_price IS NOT NULL)) OR
            ((ln_price IS NOT NULL) AND (ln_parent_price IS NULL)) OR
            (ln_price <> ln_parent_price) THEN
          ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
            gv_msg_kbn, gv_msg_ng_unitprice_p,
            gv_tkn_item_code_p, lv_parent_item_code,
            gv_tkn_item_code_c, ir_report_rec.item_code);
          RAISE check_data_expt;
        END IF;
      -- 抽出データと親品目データが一致する場合（子品目情報を取得）
      ELSE
--
        <<get_parnet_price_loop>>
        FOR get_srl_data IN parent_price_cur(
          ir_report_rec.item_code,
          ln_parent_item_id,
          ld_start_date)  LOOP
          BEGIN
            SELECT SUM(xsci.unit_price)
            INTO ln_parent_price
            FROM xxcmn_standard_cost_if xsci -- 標準原価インタフェース
            WHERE xsci.item_code = get_srl_data.item_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_parent_price := NULL;
          END;
          -- 子品目情報が取得できない場合
          IF (ln_parent_price IS  NULL) THEN
            -- 廃止区分が「0（取扱中）」の場合
            IF (get_srl_data.obsolete_class = cv_obsolete_handling) THEN
              ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
                gv_msg_kbn, gv_msg_ng_itemcode_c1,
                gv_tkn_item_code_p, ir_report_rec.item_code,
                gv_tkn_item_code_c, get_srl_data.item_code);
              RAISE check_data_expt;
            -- 廃止区分が「1（廃止）」の場合
            ELSIF (get_srl_data.obsolete_class = cv_obsolete_abolition)THEN
              ir_report_rec.message7 := xxcmn_common_pkg.get_msg(
                gv_msg_kbn, gv_msg_ng_itemcode_c2,
                gv_tkn_item_code_p, ir_report_rec.item_code,
                gv_tkn_item_code_c, get_srl_data.item_code);
            END IF;
          ELSE
            -- 親品目単価と子品目単価が一致しない場合
            IF ((ln_price IS NULL) AND (ln_parent_price IS NOT NULL)) OR
                ((ln_price IS NOT NULL) AND (ln_parent_price IS NULL)) OR
                (ln_price <> ln_parent_price) THEN
              ir_report_rec.skip_message := xxcmn_common_pkg.get_msg(
                gv_msg_kbn, gv_msg_ng_unitprice_p,
                gv_tkn_item_code_p, ir_report_rec.item_code,
                gv_tkn_item_code_c, get_srl_data.item_code);
              RAISE check_data_expt;
            END IF;
          END IF;
        END LOOP get_parnet_price_loop;
--
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_parent_item_id := NULL;
        lv_parent_item_code := NULL;
    END;
--
    -- ステータスに正常を格納
    ir_report_rec.row_level_status := gn_data_status_normal;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN check_data_expt THEN
      -- レポートのステータスを警告と設定
      ir_report_rec.row_level_status  := gn_data_status_warn;
      -- チェック処理を警告と設定(挿入処理判定)
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;                                            --# 任意 #
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
  END check_data;
--
  /***********************************************************************************
   * Procedure Name   : get_standard_if_lock
   * Description      : ロック取得プロシージャ
   ***********************************************************************************/
  PROCEDURE get_standard_if_lock(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_standard_if_lock'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR get_standard_if_cur(in_request_id NUMBER) IS
      SELECT xsci.request_id
      FROM xxcmn_standard_cost_if xsci -- 標準原価インタフェース
      WHERE xsci.request_id = in_request_id
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
       <<request_id_loop>>
      FOR ln_count IN 1..gt_request_id_tbl.COUNT
      LOOP
        -- ロック取得処理
        OPEN get_standard_if_cur(gt_request_id_tbl(ln_count));
        CLOSE get_standard_if_cur;
      END LOOP request_id_loop;
    EXCEPTION
      -- ロック取得エラー
      WHEN check_lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_get_lock);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
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
--#####################################  固定部 END   ############################################
--
  END get_standard_if_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : プロファイル取得プロシージャ
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_max_pro_date CONSTANT VARCHAR2(20) := 'MAX日付';
--
    -- *** ローカル変数 ***
    lv_max_date  VARCHAR2(10);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --最大日付取得
    lv_max_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_max_date),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_msg_kbn, gv_msg_no_profile,
        gv_tkn_ng_profile, cv_max_pro_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gv_max_date := lv_max_date; -- 最大日付に設定
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
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
--#####################################  固定部 END   ############################################
--
  END get_profile;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lr_report_rec             out_report_rec;
    ln_request_id             NUMBER;
    -- 前レコードヘッダ比較用変数
    lv_former_item_code       VARCHAR2(10);
    ld_former_s_date          DATE;
    -- ヘッダ数カウント用変数
    ln_head_count             NUMBER := 0;
    -- ヘッダID取得用変数
    ln_head_id                NUMBER;
    -- 明細IDカウント用変数
    ln_line_count             NUMBER := 0;
    -- 明細ID取得用変数
    ln_line_id                NUMBER;
    -- 品目ID格納用変数
    ln_item_id                NUMBER;
    -- 単価合計格納用変数
    ln_total_amount           NUMBER := 0;
    -- 挿入,更新ユーザーデータ格納用
    ln_insert_user_id         NUMBER(15,0);
    ld_insert_date            DATE;
    ln_insert_login_id        NUMBER(15,0);
    ln_insert_request_id      NUMBER(15,0);
    ln_insert_prog_appl_id    NUMBER(15,0);
    ln_insert_program_id      NUMBER(15,0);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 標準原価インタフェース要求ID取得カーソル
-- 2008/09/10 Mod ↓
/*
    CURSOR get_request_id_cur IS
    SELECT fcr.request_id
    FROM fnd_concurrent_requests fcr
    WHERE EXISTS (
          SELECT 1
          FROM xxcmn_standard_cost_if xsci
          WHERE xsci.request_id = fcr.request_id
            AND ROWNUM = 1
        )
    ORDER BY fcr.request_id; -- 要求IDを昇順
*/
    CURSOR get_request_id_cur IS
    SELECT fcr.request_id
    FROM fnd_concurrent_requests fcr
    WHERE fcr.request_id IN (
          SELECT xsci.request_id
          FROM xxcmn_standard_cost_if xsci
        )
    ORDER BY fcr.request_id; -- 要求IDを昇順
-- 2008/09/10 Mod ↑
--
    -- 標準原価インタフェース取得カーソル
    CURSOR get_standard_if_cur(in_request_id NUMBER) IS
      SELECT xsci.request_id
            ,xsci.item_code
            ,xsci.start_date_active
            ,xsci.expence_item_type
            ,xsci.expence_item_detail_type
            ,xsci.item_code_detail
            ,xsci.unit_price
      FROM xxcmn_standard_cost_if xsci -- 標準原価インタフェース
      WHERE xsci.request_id = in_request_id
      ORDER BY xsci.request_id
              ,xsci.item_code
              ,xsci.start_date_active
              ,xsci.expence_item_type
              ,xsci.expence_item_detail_type
              ,xsci.item_code_detail;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ユーザーデータの格納
    ln_insert_user_id      := FND_GLOBAL.USER_ID;
    ld_insert_date         := SYSDATE;
    ln_insert_login_id     := FND_GLOBAL.LOGIN_ID;
    ln_insert_request_id   := FND_GLOBAL.CONC_REQUEST_ID;
    ln_insert_prog_appl_id := FND_GLOBAL.PROG_APPL_ID;
    ln_insert_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- プロファイル取得
    -- ===============================
    get_profile(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 例外処理
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- 処理対象要求ID取得
    -- ===============================
    <<get_request_id_loop>>
    FOR get_req_data IN get_request_id_cur  LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1;
      gt_request_id_tbl(gn_request_id_cnt) := get_req_data.request_id;
    END LOOP get_request_id_loop;
--
   -- ===============================
    -- ロック取得
    -- ===============================
    get_standard_if_lock(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 例外処理
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- インタフェースデータ抽出処理(A-1)
    -- ===============================
    <<get_req_count_loop>>
    FOR ln_req_count IN 1..gt_request_id_tbl.COUNT
    LOOP
      -- 前回取得ヘッダ用変数を初期化
      lv_former_item_code := NULL;
      ld_former_s_date := NULL;
      -- カウント初期化
      ln_head_count := 0;
      ln_line_count := 0;
--
-- 2009/04/27 v1.5 ADD START
      ----------------------
      -- 対象データ削除処理
      ----------------------
      -- 明細を削除
      DELETE
      FROM xxpo_price_lines xpl
      WHERE EXISTS
      (
        SELECT 'X'
        FROM  xxcmn_standard_cost_if xsci,
              xxpo_price_headers xph
        WHERE xsci.item_code        = xph.item_code
        AND   xph.price_type        = '2' -- 標準原価
        AND   xph.start_date_active = xsci.start_date_active
        AND   xph.price_header_id   = xpl.price_header_id
        AND   xsci.request_id       = gt_request_id_tbl(ln_req_count)
      );
--
      -- ヘッダを削除
      DELETE
      FROM  xxpo_price_headers xph
      WHERE xph.price_type = '2' -- 標準原価
      AND EXISTS
      (
        SELECT 'X'
        FROM  xxcmn_standard_cost_if xsci
        WHERE xsci.item_code         = xph.item_code
        AND   xsci.start_date_active = xph.start_date_active
        AND   xsci.request_id        = gt_request_id_tbl(ln_req_count)
      );
--
-- 2009/04/27 v1.5 ADD END
      <<get_standard_if_loop>>
      FOR get_stand_data IN get_standard_if_cur(gt_request_id_tbl(ln_req_count))
      LOOP
        -- 処理件数のカウントアップ
        gn_target_cnt := gn_target_cnt + 1;
        -- レコード変数に格納
        lr_report_rec.request_id := get_stand_data.request_id;
        lr_report_rec.item_code := get_stand_data.item_code;
        lr_report_rec.s_date_active := get_stand_data.start_date_active;
        lr_report_rec.e_item_type := get_stand_data.expence_item_type;
        lr_report_rec.e_item_detail_type := get_stand_data.expence_item_detail_type;
        lr_report_rec.item_code_detail := get_stand_data.item_code_detail;
        lr_report_rec.unit_price := get_stand_data.unit_price;
--
        -- レポート初期化
        lr_report_rec.message1 := NULL;
        lr_report_rec.message2 := NULL;
        lr_report_rec.message3 := NULL;
        lr_report_rec.message4 := NULL;
        lr_report_rec.message5 := NULL;
        lr_report_rec.message6 := NULL;
        lr_report_rec.message7 := NULL;
        lr_report_rec.skip_message := NULL;
--
        -- ===============================
        -- 抽出データチェック処理(A-2)
        -- ===============================
        check_data(
          lr_report_rec,          -- 1.レコード
          ln_total_amount,        -- 2.単価合計
          ln_item_id,             -- 3.品目ID
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- 例外処理
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        -- 正常、スキップ、エラー件数集計処理
        IF (lr_report_rec.row_level_status = gn_data_status_normal) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSIF (lr_report_rec.row_level_status = gn_data_status_warn) THEN
          gn_warn_cnt   := gn_warn_cnt + 1;
        ELSE
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
--
        -- レポート変数に格納
        gt_out_report_tbl(gn_target_cnt) := lr_report_rec;
--
        -- ===============================
        -- 登録対象データ編集処理(A-3)
        -- ===============================
        IF (gn_data_status = gn_data_status_normal) THEN
          IF ((lv_former_item_code IS NULL)
              OR (lv_former_item_code <> lr_report_rec.item_code)
            OR ((ld_former_s_date IS NULL)
              OR (ld_former_s_date <> lr_report_rec.s_date_active))) THEN
            -- ヘッダカウント処理
            ln_head_count := ln_head_count + 1;
--
            -- ===============================
            -- 登録対象ヘッダデータ編集処理
            -- ===============================
            get_price_h_id(
              ln_head_id,    -- 1.ヘッダID
              lv_errbuf,     -- エラー・メッセージ           --# 固定 #
              lv_retcode,    -- リターン・コード             --# 固定 #
              lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
--
            -- 例外処理
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
--
            -- ヘッダ情報をバルク変数に格納
            gt_price_header_id_tbl(ln_head_count) := ln_head_id;
            gt_item_id_tbl(ln_head_count) := ln_item_id;
            gt_item_code_tbl(ln_head_count) := lr_report_rec.item_code;
            gt_s_date_tbl(ln_head_count) := lr_report_rec.s_date_active;
            gt_total_amount_tbl(ln_head_count) := ln_total_amount;
            lv_former_item_code := lr_report_rec.item_code;
            ld_former_s_date := lr_report_rec.s_date_active;
--
          END IF;
          -- 明細カウント処理
          ln_line_count := ln_line_count + 1;
--
          -- ===============================
          -- 登録対象明細データ編集処理
          -- ===============================
          get_price_line_id(
            ln_line_id,    -- 1.明細ID
            lv_errbuf,     -- エラー・メッセージ           --# 固定 #
            lv_retcode,    -- リターン・コード             --# 固定 #
            lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- 例外処理
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          -- 明細情報をバルク変数に格納
          gt_price_header_line_id_tbl(ln_line_count) := ln_head_id;
          gt_price_line_id_tbl(ln_line_count) := ln_line_id;
          gt_exp_item_tbl(ln_line_count) := lr_report_rec.e_item_type;
          gt_exp_item_det_tbl(ln_line_count) := lr_report_rec.e_item_detail_type;
          gt_item_code_det_tbl(ln_line_count) := lr_report_rec.item_code_detail;
          gt_unit_price_tbl(ln_line_count) := lr_report_rec.unit_price;
--
        END IF;
--
      END LOOP get_standard_if_loop;
--
      IF (gn_data_status = gn_data_status_normal)
        AND ( gn_target_cnt > 0 )  THEN
        -- ===============================
        -- 標準単価ヘッダ登録処理(A-4)
        -- ===============================
        insert_xp_headers(
          ln_insert_user_id,      -- 1.ユーザーID
          ld_insert_date,         -- 2.更新日
          ln_insert_login_id,     -- 3.ログインID
          ln_insert_request_id,   -- 4.要求ID
          ln_insert_prog_appl_id, -- 5.コンカレント・プログラムのアプリケーションID
          ln_insert_program_id,   -- 6.コンカレント・プログラムID
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- 例外処理
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        -- ===============================
        -- 標準単価明細登録処理(A-4)
        -- ===============================
        insert_xp_lines(
          ln_insert_user_id,      -- 1.ユーザーID
          ld_insert_date,         -- 2.更新日
          ln_insert_login_id,     -- 3.ログインID
          ln_insert_request_id,   -- 4.要求ID
          ln_insert_prog_appl_id, -- 5.コンカレント・プログラムのアプリケーションID
          ln_insert_program_id,   -- 6.コンカレント・プログラムID
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- 例外処理
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
--
      END IF;
--
    END LOOP get_req_count_loop;
--
    -- 2008/07/09 Add ↓
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10036');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
    -- 2008/07/09 Add ↑
--
    -- 警告データが存在する場合
    IF (gn_data_status = gn_data_status_warn) THEN
      -- ロールバックを実行
      ROLLBACK;
--
      -- ===============================
      -- ロック取得
      -- ===============================
      get_standard_if_lock(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    -- ===============================
    -- 適用終了日編集
    -- ===============================
    ELSIF (gn_data_status = gn_data_status_normal)
      AND ( gn_target_cnt > 0 )  THEN
      modify_end_date(
        ln_insert_user_id,      -- 1.ユーザーID
        ld_insert_date,         -- 2.更新日
        ln_insert_login_id,     -- 3.ログインID
        ln_insert_request_id,   -- 4.要求ID
        ln_insert_prog_appl_id, -- 5.コンカレント・プログラムのアプリケーションID
        ln_insert_program_id,   -- 6.コンカレント・プログラムID
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- インタフェースデータ削除(A-5)
    -- ===============================
    IF ( gn_target_cnt > 0 )  THEN
      delete_standard_if(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- レポート用データ出力
    -- ===============================
    IF (gn_normal_cnt > 0) THEN
      -- ログ出力処理(成功:0)
      disp_report(gn_data_status_normal,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_error_cnt > 0) THEN
      -- ログ出力処理(失敗:1)
      disp_report(gn_data_status_error,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      -- ログ出力処理(警告:2)
      disp_report(gn_data_status_warn,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    IF (gn_data_status = gn_data_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
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
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2      --   リターン・コード    --# 固定 #
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxcmn820001c;
/
