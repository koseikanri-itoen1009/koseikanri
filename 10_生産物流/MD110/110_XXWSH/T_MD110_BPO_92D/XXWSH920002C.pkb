CREATE OR REPLACE PACKAGE BODY xxwsh920002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920002C(body)
 * Description      : 引当解除処理
 * MD.050/070       : 生産物流共通(出荷･移動仮引当)(T_MD050_BPO_920)
 *                    引当解除処理                 (T_MD070_BPO_92D)
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  pro_param_chk          入力パラメータチェック           (G-1)
 *  pro_get_item_code_list 品目リスト取得                   (G-X)
 *  pro_get_h_o_all        出荷依頼対象データ抽出           (G-2)
 *  pro_get_mov_req        移動指示対象データ抽出           (G-3)
 *  pro_del_mov_lot        移動ロッド詳細(アドオン)削除     (G-4)
 *  pro_upd_o_lines        受注明細アドオン更新             (G-5)
 *  pro_upd_m_r_lines      移動依頼/指示明細(アドオン)更新  (G-6)
 *  pro_out_msg            メッセージ出力                   (G-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/18    1.0   Tatsuya Kurata    新規作成
 *  2008/06/03    1.1   Masao Hokkanji    結合テスト不具合対応
 *  2008/06/12    1.2   Masao Hokkanji    T_TE080_BPO920不具合ログNo24対応
 *  2008/06/13    1.3   Masao Hokkanji    抽出条件変更対応
 *  2008/12/01    1.4   SCS Miyata        ロック対応
 *  2009/01/27    1.5   SCS Itou          本番障害#1028対応
 *  2009/05/01    1.6   SCS Itou          本番障害#1447対応
 *  2009/12/10    1.7   SCS Itou          本稼動障害#383対応
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
--
--################################  固定部 END   ###############################
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力Ｐ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      item_class   VARCHAR2(2)   -- 商品区分
     ,action_type  VARCHAR2(5)   -- 処理種別
     ,block1       VARCHAR2(5)   -- ブロック１
     ,block2       VARCHAR2(5)   -- ブロック２
     ,block3       VARCHAR2(5)   -- ブロック３
     ,del_from_id  VARCHAR2(40)  -- 出庫元
     ,del_type     VARCHAR2(10)  -- 出庫形態
     ,del_d_from   VARCHAR2(10)  -- 出庫日From
     ,del_d_to     VARCHAR2(10)  -- 出庫日To
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
     ,instruction_dept xxwsh_order_headers_all.instruction_dept%TYPE -- 指示部署
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Mod Start 本番障害#1447対応
     ,item_code        xxcmn_item_mst_v.item_no%TYPE -- 品目コード
     ,item_code_list   VARCHAR2(4000)                -- 入力パラメータ.品目コードの親子リスト
-- 2009/05/01 H.Itou Add End
    );
--
  -- 出荷依頼対象データ格納用レコード変数
  TYPE rec_order_line IS RECORD
    (
      o_line_id   xxwsh_order_lines_all.order_line_id%TYPE  -- 受注明細アドオンID
    );
  TYPE tab_data_order_line IS TABLE OF rec_order_line INDEX BY PLS_INTEGER;
--
  -- 移動指示対象データ格納用レコード変数
  TYPE rec_mov_line IS RECORD
    (
      m_line_id   xxinv_mov_req_instr_lines.mov_line_id%TYPE  -- 移動明細ID
    );
  TYPE tab_data_mov_line IS TABLE OF rec_mov_line INDEX BY PLS_INTEGER;
--
  -- 受注明細アドオン登録用項目テーブル型
  TYPE l_order_line_id     IS TABLE OF
       xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;    -- 受注明細アドオンID
--
  -- 移動明細アドオン登録用項目テーブル型
  TYPE mod_line_id         IS TABLE OF
       xxinv_mov_req_instr_lines.mov_line_id%TYPE INDEX BY BINARY_INTEGER;  -- 移動明細ID
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;
  gn_normal_cnt    NUMBER;
  gn_error_cnt     NUMBER;
--
--################################  固定部 END   ###############################
--
  -- ==================================================
  -- ユーザー定義グローバル定数
  -- ==================================================
  gv_pkg_name       CONSTANT VARCHAR2(15) := 'xxwsh920002c';          -- パッケージ名
  -- エラーメッセージコード
  gv_application    CONSTANT VARCHAR2(5)  := 'XXWSH';                 -- アプリケーション
  gv_err_del_count  CONSTANT VARCHAR2(20) := 'APP-XXWSH-02951';
                                                     -- 削除件数メッセージ
  gv_err_para       CONSTANT VARCHAR2(20) := 'APP-XXWSH-12951';
                                                     -- 必須入力パラメータ未入力エラーメッセージ
  gv_err_format     CONSTANT VARCHAR2(20) := 'APP-XXWSH-12952';
                                                     -- 入力パラメータ書式エラーメッセージ
  gv_err_day_out    CONSTANT VARCHAR2(20) := 'APP-XXWSH-12953';
                                                     -- 対象期間逆転エラーメッセージ
  gv_err_lock       CONSTANT VARCHAR2(20) := 'APP-XXWSH-12954';
                                                     -- ロックエラーメッセージ
  -- トークン
  gv_tkn_count      CONSTANT VARCHAR2(5)  := 'COUNT';
  gv_tkn_prof_name  CONSTANT VARCHAR2(9)  := 'PROF_NAME';
  gv_tkn_parm_name  CONSTANT VARCHAR2(9)  := 'PARM_NAME';
  gv_tkn_table      CONSTANT VARCHAR2(5)  := 'TABLE';
  -- エラーリスト表示内容
  gv_msg_skbn       CONSTANT VARCHAR2(8)  := '商品区分';
  gv_msg_from       CONSTANT VARCHAR2(10) := '出庫日From';
  gv_msg_to         CONSTANT VARCHAR2(8)  := '出庫日To';
  gv_msg_lock_1     CONSTANT VARCHAR2(70) :=
                              '受注ヘッダアドオン、受注明細アドオン、移動ロット詳細(アドオン)';
  gv_msg_lock_2     CONSTANT VARCHAR2(90) :=
        '移動依頼/指示ヘッダ(アドオン)、移動依頼/指示明細(アドオン)、移動ロット詳細(アドオン)';
--
  gv_yes            CONSTANT VARCHAR2(1)  := 'Y';
  gv_s_req          CONSTANT VARCHAR2(1)  := '1';   -- 処理種別「出荷依頼」
  gv_m_req          CONSTANT VARCHAR2(1)  := '3';   -- 処理種別「移動指示依頼」
  gv_lot            CONSTANT VARCHAR2(1)  := '1';   -- ロット「ロット管理品」
  gv_product        CONSTANT VARCHAR2(1)  := '5';   -- 品目区分「製品」
  gv_kbn_ship       CONSTANT VARCHAR2(1)  := '1';   -- 出荷支給区分「出荷依頼」
  gv_mov_y          CONSTANT VARCHAR2(1)  := '1';   -- 移動タイプ「積送あり」
  gv_out            CONSTANT VARCHAR2(2)  := '03';  -- ステータス「締め済」
  gv_req            CONSTANT VARCHAR2(2)  := '02';  -- ステータス「依頼済」
  gv_adjust         CONSTANT VARCHAR2(2)  := '03';  -- ステータス「調整中」
  gv_n_notif        CONSTANT VARCHAR2(2)  := '10';  -- 通知ステータス「未通知」
  gv_re_notif       CONSTANT VARCHAR2(2)  := '20';  -- 通知ステータス「再通知要」
  gv_ship_req       CONSTANT VARCHAR2(2)  := '10';  -- 文書タイプ「出荷依頼」
  gv_move_req       CONSTANT VARCHAR2(2)  := '20';  -- 文書タイプ「移動指示」
  gv_auto           CONSTANT VARCHAR2(2)  := '10';  -- 自動手動引当区分「自動引当」
-- M.Hokkanji Ver1.2 START
  gv_record_type_10 CONSTANT VARCHAR2(2)  := '10';  -- レコードタイプ「指示」
-- M.Hokkanji Ver1.2 END
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate           DATE;                -- システム現在日付
  gd_del_from          DATE;                -- 出庫日From(Dateへ変換用)
  gd_del_to            DATE;                -- 出庫日To  (Dateへ変換用)
--
  -- ＷＨＯカラム取得用
  gn_last_upd_by       NUMBER;              -- 最終更新者
  gd_last_upd_date     DATE;                -- 最終更新日
  gn_last_upd_login    NUMBER;              -- 最終更新ログイン
  gn_request_id        NUMBER;              -- 要求ID
  gn_prog_appl_id      NUMBER;              -- プログラムアプリケーションID
  gn_prog_id           NUMBER;              -- プログラムID
-- M.Hokkanji Ver1.2 START
  gd_prog_upd_date     DATE;                -- プログラム更新日
-- M.Hokkanji Ver1.2 END
  gn_del_cut           NUMBER DEFAULT 0;    -- 削除件数用
  gn_l_id_cnt          NUMBER DEFAULT 0;    -- 出荷依頼対象レコード用カウント
  gn_m_id_cnt          NUMBER DEFAULT 0;    -- 移動指示対象レコード用カウント
--
  -- ＳＱＬ作成用
  gv_sql_sel           VARCHAR2(20000);     -- SQL組合せ用
  gv_sql_select        VARCHAR2(1000);      -- SELECT句
  gv_sql_from          VARCHAR2(3000);      -- FROM句
  gv_sql_where         VARCHAR2(9000);      -- WHERE句
  gv_sql_in_para_1     VARCHAR2(1000);      -- 入力Ｐ任意部分1(ブロック１～３のみ入力有)
  gv_sql_in_para_2     VARCHAR2(1000);      -- 入力Ｐ任意部分2(出庫元のみ入力有)
  gv_sql_in_para_3     VARCHAR2(1000);      -- 入力Ｐ任意部分3(ブロック１～３、出庫元入力有)
  gv_sql_in_para_4     VARCHAR2(1000);      -- 入力Ｐ任意部分4(出庫形態 入力有)
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
  gv_sql_in_para_5     VARCHAR2(1000);      -- 入力Ｐ任意部分5（指示部署 入力有）
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Add Start 本番障害#1447対応
  gv_sql_in_para_6     VARCHAR2(1000);      -- 入力Ｐ任意部分6（品目コード 入力有）
-- 2009/05/01 H.Itou Add End
--
  gr_param             rec_param_data;      -- 入力パラメータ
  gt_order_line        tab_data_order_line; -- 出荷依頼対象取得データ
  gt_mov_line          tab_data_mov_line;   -- 移動指示対象取得データ
  gt_l_order_line_id   l_order_line_id;     -- 受注明細アドオンID
  gt_mod_line_id       mod_line_id;         -- 移動明細ID
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_error_expt          EXCEPTION;     -- ロックエラー
--
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : pro_param_chk
   * Description      : 入力パラメータチェック   (G-1)
   ***********************************************************************************/
  PROCEDURE pro_param_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_param_chk'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 入力パラメータ必須チェック
    ------------------------------------------
    -- 入力Ｐ「商品区分」の必須チェック
    IF (gr_param.item_class IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_para          -- 必須入力Ｐ未設定エラー
                                    ,gv_tkn_parm_name     -- トークン
                                    ,gv_msg_skbn          -- 「商品区分」
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 入力Ｐ「出庫予定日From」の必須チェック
    IF (gr_param.del_d_from IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_para          -- 必須入力Ｐ未設定エラー
                                    ,gv_tkn_parm_name     -- トークン
                                    ,gv_msg_from          -- 「出庫日From」
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 入力Ｐ「出庫予定日To」の必須チェック
    IF (gr_param.del_d_to IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_para          -- 必須入力Ｐ未設定エラー
                                    ,gv_tkn_parm_name     -- トークン
                                    ,gv_msg_to            -- 「出庫日To」
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- 日付チェック
    ------------------------------------------
    -- 入力Ｐ「出庫予定日From」の書式変換(YYYY/MM/DD)
    gd_del_from := FND_DATE.STRING_TO_DATE(gr_param.del_d_from,'YYYY/MM/DD');
    -- 変換エラー時
    IF (gd_del_from IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application       -- 'XXWSH'
                                    ,gv_err_format        -- 入力Ｐ書式エラー
                                    ,gv_tkn_parm_name     -- トークン
                                    ,gv_msg_from          -- 「出庫日From」
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 入力Ｐ「出庫予定日To」の書式変換(YYYY/MM/DD)
    gd_del_to := FND_DATE.STRING_TO_DATE(gr_param.del_d_to,'YYYY/MM/DD');
    -- 変換エラー時
    IF (gd_del_to IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg
                                   (
                                     gv_application     -- 'XXWSH'
                                    ,gv_err_format      -- 入力Ｐ書式エラー
                                    ,gv_tkn_parm_name   -- トークン
                                    ,gv_msg_to          -- 「出庫日To」
                                   )
                                   ,1
                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- 妥当性チェック
    ------------------------------------------
    -- 出庫予定日Fromが出庫予定日Toより大きい場合、エラー
    IF (gd_del_from > gd_del_to) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                                                     gv_application    -- 'XXWSH'
                                                    ,gv_err_day_out    -- 対象期間逆転エラー
                                                   )
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_param_chk;
--
-- 2009/05/01 H.Itou Add Start 本番障害#1447
  /**********************************************************************************
   * Procedure Name   : pro_get_item_code_list
   * Description      : 品目リスト取得  (G-X)
   ***********************************************************************************/
  PROCEDURE pro_get_item_code_list(
    iv_item_code       IN  VARCHAR2,            -- 品目コード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_item_code_list'; -- プログラム名
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
    cn_max_cnt  CONSTANT NUMBER := 100; -- MAXCOUNT
    cn_cnt_0    CONSTANT NUMBER := 0;   -- 対象品目件数0
--
    -- *** ローカル変数 ***
    ln_cnt      NUMBER := 0;            -- 件数カウント用
--
    -- *** ローカル・カーソル ***
    CURSOR cur_item_list 
    IS
      SELECT ximv.item_no
      FROM   xxcmn_item_mst_v ximv
      WHERE  LEVEL           <= 2            -- 子階層まで抽出
      START WITH ximv.item_no = iv_item_code -- 親品目から検索
      CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id
    ;
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
    gr_param.item_code_list := NULL;
    FOR rec_item_list IN cur_item_list LOOP
      ln_cnt := ln_cnt + 1;
      IF ( gr_param.item_code_list IS NULL ) THEN
        gr_param.item_code_list := '''' || rec_item_list.item_no || '''';
      ELSE
        gr_param.item_code_list := gr_param.item_code_list || ',' || '''' || rec_item_list.item_no || '''';
      END IF;
    END LOOP;
--
    -- 対象品目が100件より大きい場合
    IF ( ln_cnt > cn_max_cnt ) THEN
      -- エラーメッセージ定義
      lv_errmsg := '品目対象件数が100件を超えています。';
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_item_code_list;
-- 2009/05/01 H.Itou Add End
  /**********************************************************************************
   * Procedure Name   : pro_get_h_o_all
   * Description      : 出荷依頼対象データ抽出  (G-2)
   ***********************************************************************************/
  PROCEDURE pro_get_h_o_all
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_h_o_all'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
-- 2009/12/10 H.Itou Del Start 本稼動障害#383 ロックはメインSQLで取得するため不要
--    -- *** ローカル・カーソル ***
--    -- ロック用カーソル
--    CURSOR cur_get_lock
--    IS
--      SELECT xoha.order_header_id
--      FROM  xxwsh_order_headers_all       xoha    -- 受注ヘッダアドオン
--           ,xxwsh_order_lines_all         xola    -- 受注明細アドオン
--           ,xxinv_mov_lot_details         xmld    -- 移動ロット詳細（アドオン）
--      WHERE xoha.order_header_id           = xola.order_header_id  -- 受注ヘッダアドオンID
--      AND   xoha.latest_external_flag      = gv_yes                -- 最新フラグ「Ｙ」
--      AND   xoha.req_status                = gv_out                -- ステータス「締め済」
--      AND ( xoha.notif_status              = gv_n_notif            -- 通知ステータス「未通知」
--         OR xoha.notif_status              = gv_re_notif)          -- 通知ステータス「再通知要」
--      AND   xola.delete_flag              <> gv_yes                -- 削除フラグ「Ｙ」以外
--      AND   xola.automanual_reserve_class  = gv_auto               -- 自動手動引当区分「自動引当」
--      AND   xola.order_line_id             = xmld.mov_line_id      -- 明細ID
--      AND   xmld.document_type_code        = gv_ship_req           -- 文書タイプ「出荷依頼」
--      FOR UPDATE 
--      ;
-- 2009/12/10 H.Itou Del End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2009/12/10 H.Itou Del Start 本稼動障害#383 ロックはメインSQLで取得するため不要
--    -- ロック用カーソルオープン
--    OPEN cur_get_lock;
--    -- ロック用カーソルクローズ
--    CLOSE cur_get_lock;
-- 2009/12/10 H.Itou Del End
--
    ---------------------------------------------------------
    -- 動的SQL作成
    ---------------------------------------------------------
    -- SELECT句
    gv_sql_select := 'SELECT xola.order_line_id          AS o_line_id';  -- 受注明細アドオンID
--
    -- FROM句
    gv_sql_from := ' FROM xxwsh_order_headers_all       xoha    -- 受注ヘッダアドオン
                        ,xxwsh_order_lines_all         xola    -- 受注明細アドオン
                        ,xxinv_mov_lot_details         xmld    -- 移動ロット詳細（アドオン）
                        ,xxwsh_oe_transaction_types_v  xottv   -- 受注タイプ情報VIEW
                        ,xxcmn_item_locations_v        xilv    -- OPM保管場所情報VIEW
                        ,xxcmn_item_mst_v              ximv    -- OPM品目情報VIEW
                        ,xxcmn_item_categories4_v      xicv    -- OPM品目カテゴリ割当情報VIEW4
                   ';
--
    -- WHERE句
    gv_sql_where :=
      ' WHERE xoha.schedule_ship_date      >= :para_del_from            -- 入力Ｐ「出庫予定日From」
        AND   xoha.schedule_ship_date      <= :para_del_to              -- 入力Ｐ「出庫予定日To」
-- 2009/12/10 H.Itou Mod Start 本稼動障害#383 IDで結合したほうがコストが下がるので、変更
--        AND   xoha.deliver_from             = xilv.segment1             -- 保管倉庫コード
        AND   xoha.deliver_from_id          = xilv.inventory_location_id  -- 保管倉庫ID
-- 2009/12/10 H.Itou Mod End
        AND   ximv.item_no                  = xola.shipping_item_code   -- 出荷品目
        AND   ximv.lot_ctl                  = :para_lot                 -- ロット（ロット管理品）
        AND   xicv.item_class_code          = :para_product             -- 品目区分（製品）
        AND   xicv.item_id                  = ximv.item_id              -- 品目ID
        AND   xicv.prod_class_code          = :para_item_class          -- 入力Ｐ「商品区分」
        AND   xoha.req_status               = :para_out                 -- ステータス「締め済」
        AND  (xoha.notif_status             = :para_n_notif             -- 通知ステータス「未通知」
          OR  xoha.notif_status             = :para_re_notif)           -- 通知ステータス「再通知要」
        AND   xoha.latest_external_flag     = :para_new                 -- 最新フラグ「Ｙ」
        AND   xoha.order_type_id            = xottv.transaction_type_id -- 受注タイプID
        AND   xottv.shipping_shikyu_class   = :para_kbn_ship            -- 出荷支給区分「出荷依頼」
        AND   NOT EXISTS ( SELECT xoha2.order_header_id
                             FROM xxwsh_order_headers_all xoha2,
                                  xxwsh_order_lines_all xola2
                            WHERE xoha2.order_header_id = xoha.order_header_id
                              AND xola2.order_header_id = xoha2.order_header_id
                              AND xola2.delete_flag  <> :para_delete2   -- 削除フラグ「Ｙ」以外
                              AND xola2.shipped_quantity IS NOT NULL

        )
        AND   xoha.order_header_id          = xola.order_header_id      -- 受注ヘッダアドオンID
        AND   xola.delete_flag             <> :para_delete              -- 削除フラグ「Ｙ」以外
        AND   xola.automanual_reserve_class = :para_auto                -- 自動手動引当区分「自動引当」
        AND   xola.order_line_id            = xmld.mov_line_id          -- 明細ID
        AND   xmld.document_type_code       = ''' || gv_ship_req  || '''  -- 文書タイプ「出荷依頼」
      ';
-- M.Hokkanji Ver1.3 START
-- ヘッダに紐付く明細に実績数量が入力されているデータが一件でもある場合対象外
--        AND   xola.shipped_quantity         IS NULL                     -- 出荷実績数量(NULLのみ対象)
-- M.Hokkanji Ver1.3 END
--
    -- 入力Ｐ任意部分1（入力Ｐ「ブロック」のうちいずれかに入力がある場合）
    gv_sql_in_para_1 := ' AND (xilv.distribution_block  = :para_block1  -- 物流ブロック
                            OR xilv.distribution_block  = :para_block2  -- 物流ブロック
                            OR xilv.distribution_block  = :para_block3) -- 物流ブロック
                        ';
--
    -- 入力Ｐ任意部分2（入力Ｐ「出庫元」に入力がありの場合)
    gv_sql_in_para_2 := ' AND xoha.deliver_from         = :para_del_from_id';  -- 出荷元
--
    -- 入力Ｐ任意部分3（入力Ｐ「ブロック」のうちいずれかに入力があり、出庫元も入力ありの場合）
    gv_sql_in_para_3 := ' AND ((xilv.distribution_block = :para_block1       -- 物流ブロック
                            OR xilv.distribution_block  = :para_block2       -- 物流ブロック
                            OR xilv.distribution_block  = :para_block3)      -- 物流ブロック
                          OR   xoha.deliver_from        = :para_del_from_id) -- 出荷元
                        ';
    -- 入力Ｐ任意部分4（出庫形態 入力有）
    gv_sql_in_para_4 := ' AND xoha.order_type_id            = :para_del_type';   -- 入力Ｐ「出庫形態」
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
    -- 入力Ｐ任意部分5（指示部署 入力有）
    gv_sql_in_para_5 := ' AND xoha.instruction_dept         = ''' || gr_param.instruction_dept || '''';   -- 入力Ｐ「指示部署」
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Add Start 本番障害#1028対応
    -- 入力Ｐ任意部分6（品目コード 入力有）
    gv_sql_in_para_6 := ' AND xola.shipping_item_code       IN (' || gr_param.item_code_list || ')';   -- 品目コードリスト
-- 2009/05/01 H.Itou Add End
--
    -------------------------------------------------------------
    -- データ抽出用SQL作成
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT句結合
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM句結合
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE句結合
--
    -- 任意入力Ｐの入力存在チェックをし、存在している場合は、条件句追加
    IF ((gr_param.block1 IS NOT NULL)
    OR  (gr_param.block2 IS NOT NULL)
    OR  (gr_param.block3 IS NOT NULL))
    THEN
      -- ブロックのいずれかに入力があり、出庫元にも入力がある場合
      IF (gr_param.del_from_id IS NOT NULL) THEN
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_3;  -- 入力Ｐ任意部分3結合
      -- ブロックのいずれかに入力があるが、出庫元はNULLの場合
      ELSE
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_1;  -- 入力Ｐ任意部分1結合
      END IF;
    -- ブロック全てがＮＵＬＬで、出庫元に入力がある場合
    ELSIF (gr_param.del_from_id IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_2;  -- 入力Ｐ任意部分2結合
    END IF;
--
    -- 入力Ｐ「出庫形態」の入力チェック
    IF (gr_param.del_type IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_4;  -- 入力Ｐ任意部分4結合
    END IF;
--
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
    -- 入力Ｐ「指示部署」の入力チェック
    IF (gr_param.instruction_dept IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_5;  -- 入力Ｐ任意部分5結合
    END IF;
-- 2009/01/27 H.Itou Add End
--
-- 2009/05/01 H.Itou Add Start 本番障害#1447対応
    -- 入力Ｐ「品目コード」の入力チェック
    IF (gr_param.item_code IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_6;  -- 入力Ｐ任意部分6結合
    END IF;
-- 2009/05/01 H.Itou Add End
-- 2009/12/10 H.Itou Add Start 本稼動障害#383 ロックはメインSQLで取得する。
    gv_sql_sel := gv_sql_sel || ' FOR UPDATE OF xoha.order_header_id, xola.order_line_id, xmld.mov_line_id ';        -- ロック取得
-- 2009/12/10 H.Itou Add End
    ---------------------------------
    -- 作成SQL文実行
    ---------------------------------
    -- 任意入力Ｐの入力存在チェック
    IF (gr_param.del_type IS NOT NULL) THEN
      -- 入力Ｐ「出庫形態」に入力がある場合
      IF ((gr_param.block1 IS NOT NULL)
      OR  (gr_param.block2 IS NOT NULL)
      OR  (gr_param.block3 IS NOT NULL))
      THEN
        -- ブロックのいずれかに入力があり、出庫元にも入力がある場合
        IF (gr_param.del_from_id IS NOT NULL) THEN
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ,gr_param.del_from_id
                                                                            ,gr_param.del_type
                                                                            ;
        -- ブロックのいずれかに入力があるが、出庫元はNULLの場合
        ELSE
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ,gr_param.del_type
                                                                            ;
        END IF;
      -- ブロック全てがNULLで、出庫元に入力がある場合
      ELSIF (gr_param.del_from_id IS NOT NULL) THEN
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ,gr_param.del_from_id
                                                                          ,gr_param.del_type
                                                                          ;
      -- 任意入力Ｐ全てNULLの場合
      ELSE
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ,gr_param.del_type
                                                                          ;
      END IF;
    ELSE
      -- 入力Ｐ「出庫形態」がNULLの場合
      IF ((gr_param.block1 IS NOT NULL)
      OR  (gr_param.block2 IS NOT NULL)
      OR  (gr_param.block3 IS NOT NULL))
      THEN
        -- ブロックのいずれかに入力があり、出庫元にも入力がある場合
        IF (gr_param.del_from_id IS NOT NULL) THEN
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ,gr_param.del_from_id
                                                                            ;
        -- ブロックのいずれかに入力があるが、出庫元はNULLの場合
        ELSE
          EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                            ,gd_del_to
                                                                            ,gv_lot
                                                                            ,gv_product
                                                                            ,gr_param.item_class
                                                                            ,gv_out
                                                                            ,gv_n_notif
                                                                            ,gv_re_notif
                                                                            ,gv_yes
                                                                            ,gv_kbn_ship
                                                                            ,gv_yes
                                                                            ,gv_yes
                                                                            ,gv_auto
                                                                            ,gr_param.block1
                                                                            ,gr_param.block2
                                                                            ,gr_param.block3
                                                                            ;
        END IF;
      -- ブロック全てがNULLで、出庫元に入力がある場合
      ELSIF (gr_param.del_from_id IS NOT NULL) THEN
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ,gr_param.del_from_id
                                                                          ;
      -- 任意入力Ｐ全てNULLの場合
      ELSE
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_order_line USING gd_del_from
                                                                          ,gd_del_to
                                                                          ,gv_lot
                                                                          ,gv_product
                                                                          ,gr_param.item_class
                                                                          ,gv_out
                                                                          ,gv_n_notif
                                                                          ,gv_re_notif
                                                                          ,gv_yes
                                                                          ,gv_kbn_ship
                                                                          ,gv_yes
                                                                          ,gv_yes
                                                                          ,gv_auto
                                                                          ;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN lock_error_expt THEN
-- 2009/12/10 H.Itou Del Start 本稼動障害#383 ロックはメインSQLで取得するため不要
--      -- カーソルオープン時、クローズへ
--      IF (cur_get_lock%ISOPEN) THEN
--        CLOSE cur_get_lock;
--      END IF;
-- 2009/12/10 H.Itou Del End
--
      ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXWSH'
                                                     ,gv_err_lock      -- ロックエラー
                                                     ,gv_tkn_table     -- トークン
                                                     ,gv_msg_lock_1    -- テーブル名
                                                    )
                                                    ,1
                                                    ,5000);
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ **
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_h_o_all;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_mov_req
   * Description      : 移動指示対象データ抽出  (G-3)
   ***********************************************************************************/
  PROCEDURE pro_get_mov_req
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_mov_req'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
-- 2009/12/10 H.Itou Del Start 本稼動障害#383 ロックはメインSQLで取得するため不要
--    -- *** ローカル・カーソル ***
--    -- ロック用カーソル
--    CURSOR cur_get_lock
--    IS
--      SELECT xmrih.mov_hdr_id
--      FROM xxinv_mov_req_instr_headers   xmrih   -- 移動依頼/指示ヘッダ（アドオン）
--          ,xxinv_mov_req_instr_lines     xmril   -- 移動依頼/指示明細（アドオン）
--          ,xxinv_mov_lot_details         xmld    -- 移動ロット詳細（アドオン）
--      WHERE xmrih.mov_type                 = gv_mov_y               -- 移動タイプ「積送あり」
--      AND   xmrih.mov_hdr_id               = xmril.mov_hdr_id       -- 移動ヘッダID
--      AND ( xmrih.status                   = gv_req                 -- ステータス「依頼済」
--         OR xmrih.status                   = gv_adjust)             -- ステータス「調整中」
--      AND ( xmrih.notif_status             = gv_n_notif             -- 通知ステータス「未通知」
--         OR xmrih.notif_status             = gv_re_notif)           -- 通知ステータス「再通知要」
--      AND   xmril.delete_flg              <> gv_yes                 -- 削除フラグ「Ｙ」以外
--      AND   xmril.automanual_reserve_class = gv_auto                -- 自動手動引当区分「自動引当」
--      AND   xmril.mov_line_id              = xmld.mov_line_id       -- 移動明細ID
--      AND   xmld.document_type_code        = gv_move_req            -- 文書タイプ「移動指示」
--      FOR UPDATE 
--      ;
-- 2009/12/10 H.Itou Del End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2009/12/10 H.Itou Del Start 本稼動障害#383 ロックはメインSQLで取得するため不要
--    -- ロック用カーソルオープン
--    OPEN cur_get_lock;
--    -- ロック用カーソルクローズ
--    CLOSE cur_get_lock;
-- 2009/12/10 H.Itou Del End
--
    ---------------------------------------------------------
    -- 動的SQL作成
    ---------------------------------------------------------
    -- SELECT句
    gv_sql_select := 'SELECT xmril.mov_line_id  AS m_line_id';    -- 移動明細ID
--
    -- FROM句
    gv_sql_from := ' FROM xxinv_mov_req_instr_headers   xmrih  -- 移動依頼/指示ヘッダ（アドオン）
                         ,xxinv_mov_req_instr_lines     xmril  -- 移動依頼/指示明細（アドオン）
                         ,xxinv_mov_lot_details         xmld   -- 移動ロット詳細（アドオン）
                         ,xxcmn_item_locations_v        xilv   -- OPM保管場所情報VIEW
                         ,xxcmn_item_mst_v              ximv   -- OPM品目情報VIEW
                         ,xxcmn_item_categories4_v      xicv   -- OPM品目カテゴリ割当情報VIEW4
                   ';
--
    -- WHERE句
    gv_sql_where :=
      ' WHERE xmrih.schedule_ship_date      >= :para_del_from      -- 入力Ｐ「出庫予定日From」
        AND   xmrih.schedule_ship_date      <= :para_del_to        -- 入力Ｐ「出庫予定日To」
-- 2009/12/10 H.Itou Mod Start 本稼動障害#383 IDで結合したほうがコストが下がるので、変更
--        AND   xmrih.shipped_locat_code       = xilv.segment1       -- 保管倉庫コード
        AND   xmrih.shipped_locat_id         = xilv.inventory_location_id  -- 保管倉庫ID
-- 2009/12/10 H.Itou Mod End
        AND   xmrih.mov_type                 = :para_mov_y         -- 移動タイプ「積送あり」
        AND   ximv.item_no                   = xmril.item_code     -- 品目
        AND   ximv.lot_ctl                   = :para_lot           -- ロット（ロット管理品）
        AND   xicv.item_class_code           = :para_product       -- 品目区分（製品）
        AND   xicv.item_id                   = ximv.item_id        -- 品目ID
        AND    xicv.prod_class_code          = :para_item_class    -- 入力Ｐ「商品区分」
        AND ( xmrih.status                   = :para_req           -- ステータス「依頼済」
          OR  xmrih.status                   = :para_adjust)       -- ステータス「調整中」
        AND ( xmrih.notif_status             = :para_n_notif       -- 通知ステータス「未通知」
          OR  xmrih.notif_status             = :para_re_notif)     -- 通知ステータス「再通知要」
        AND   NOT EXISTS ( SELECT xmrih2.mov_hdr_id
                             FROM xxinv_mov_req_instr_headers xmrih2,
                                  xxinv_mov_req_instr_lines xmril2
                            WHERE xmrih2.mov_hdr_id = xmrih.mov_hdr_id
                              AND xmril2.mov_hdr_id = xmrih2.mov_hdr_id
                              AND xmril2.delete_flg <> :para_delete2 -- 削除フラグ「Ｙ」以外
                              AND (xmril2.shipped_quantity IS NOT NULL
                                OR xmril2.ship_to_quantity IS NOT NULL)
        )
        AND   xmrih.mov_hdr_id               = xmril.mov_hdr_id    -- 移動ヘッダID
        AND   xmril.delete_flg              <> :para_delete        -- 削除フラグ「Ｙ」以外
        AND   xmril.automanual_reserve_class = :para_auto          -- 自動手動引当区分「自動引当」
        AND   xmril.mov_line_id              = xmld.mov_line_id    -- 移動明細ID
        AND   xmld.document_type_code        = ''' || gv_move_req || ''' -- 文書タイプ「移動指示」
      ';
-- M.Hokkanji Ver1.3 START
-- ヘッダに紐付く明細に実績数量が入力されているデータが一件でもある場合対象外
--        AND   xmril.shipped_quantity         IS NULL               -- 出庫実績数量(NULLのみ対象)
--        AND   xmril.ship_to_quantity         IS NULL               -- 入庫実績数量(NULLのみ対象)
-- M.Hokkanji Ver1.3 END
--
    -- 入力Ｐ任意部分1（入力Ｐ「ブロック」のうちいずれかに入力がある場合）
    gv_sql_in_para_1 := ' AND (xilv.distribution_block  = :para_block1  -- 物流ブロック
                            OR xilv.distribution_block  = :para_block2  -- 物流ブロック
                            OR xilv.distribution_block  = :para_block3) -- 物流ブロック
                        ';
--
    -- 入力Ｐ任意部分2（入力Ｐ「出庫元」に入力がありの場合）
-- 2008/06/03 START
--    gv_sql_in_para_2 := ' AND xoha.deliver_from         = :para_del_from_id';  -- 出荷元
    gv_sql_in_para_2 := ' AND xmrih.shipped_locat_code = :para_del_from_id';  -- 出荷元
-- 2008/06/03  END
--
    -- 入力Ｐ任意部分3（入力Ｐ「ブロック」のうちいずれかに入力があり、出庫元も入力ありの場合）
    gv_sql_in_para_3 := ' AND ((xilv.distribution_block = :para_block1       -- 物流ブロック
                            OR xilv.distribution_block  = :para_block2       -- 物流ブロック
                            OR xilv.distribution_block  = :para_block3)      -- 物流ブロック
                          OR   xmrih.shipped_locat_code = :para_del_from_id) -- 出庫元保管場所
                        ';
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
    -- 入力Ｐ任意部分5（指示部署 入力有）
    gv_sql_in_para_5 := ' AND xmrih.instruction_post_code = ''' || gr_param.instruction_dept || '''';   -- 入力Ｐ「指示部署」
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Add Start 本番障害#1028対応
    -- 入力Ｐ任意部分6（品目コード 入力有）
    gv_sql_in_para_6 := ' AND xmril.item_code            IN (' || gr_param.item_code_list || ')';   -- 品目コードリスト
-- 2009/05/01 H.Itou Add End
--
    -------------------------------------------------------------
    -- データ抽出用SQL作成
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT句結合
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM句結合
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE句結合
--
    -- 任意入力Ｐの入力存在チェックをし､存在している場合は､条件句追加
    IF ((gr_param.block1 IS NOT NULL)
    OR  (gr_param.block2 IS NOT NULL)
    OR  (gr_param.block3 IS NOT NULL))
    THEN
      -- ブロックのいずれかに入力があり､出庫元にも入力がある場合
      IF (gr_param.del_from_id IS NOT NULL) THEN
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_3;  -- 入力Ｐ任意部分3結合
      -- ブロックのいずれかに入力があるが､出庫元はNULLの場合
      ELSE
        gv_sql_sel := gv_sql_sel || gv_sql_in_para_1;  -- 入力Ｐ任意部分1結合
      END IF;
    -- ブロック全てがNULLで､出庫元に入力がある場合
    ELSIF (gr_param.del_from_id IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_2;  -- 入力Ｐ任意部分2結合
    END IF;
--
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
    -- 入力Ｐ「指示部署」の入力チェック
    IF (gr_param.instruction_dept IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_5;  -- 入力Ｐ任意部分5結合
    END IF;
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Add Start 本番障害#1447対応
    -- 入力Ｐ「品目コード」の入力チェック
    IF (gr_param.item_code IS NOT NULL) THEN
      gv_sql_sel := gv_sql_sel || gv_sql_in_para_6;  -- 入力Ｐ任意部分6結合
    END IF;
-- 2009/05/01 H.Itou Add End
-- 2009/12/10 H.Itou Add Start 本稼動障害#383 ロックはメインSQLで取得する。
    gv_sql_sel := gv_sql_sel || ' FOR UPDATE OF xmrih.mov_hdr_id, xmril.mov_line_id, xmld.mov_line_id ';        -- ロック取得
-- 2009/12/10 H.Itou Add End
--
    ---------------------------------
    -- 作成SQL文実行
    ---------------------------------
    -- 入力Ｐ「出庫形態」がNULLの場合
    IF ((gr_param.block1 IS NOT NULL)
    OR  (gr_param.block2 IS NOT NULL)
    OR  (gr_param.block3 IS NOT NULL))
    THEN
      -- ブロックのいずれかに入力があり､出庫元にも入力がある場合
      IF (gr_param.del_from_id IS NOT NULL) THEN
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                        ,gd_del_to
                                                                        ,gv_mov_y
                                                                        ,gv_lot
                                                                        ,gv_product
                                                                        ,gr_param.item_class
                                                                        ,gv_req
                                                                        ,gv_adjust
                                                                        ,gv_n_notif
                                                                        ,gv_re_notif
                                                                        ,gv_yes
                                                                        ,gv_yes
                                                                        ,gv_auto
                                                                        ,gr_param.block1
                                                                        ,gr_param.block2
                                                                        ,gr_param.block3
                                                                        ,gr_param.del_from_id
                                                                        ;
      -- ブロックのいずれかに入力があるが､出庫元はNULLの場合
      ELSE
        EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                        ,gd_del_to
                                                                        ,gv_mov_y
                                                                        ,gv_lot
                                                                        ,gv_product
                                                                        ,gr_param.item_class
                                                                        ,gv_req
                                                                        ,gv_adjust
                                                                        ,gv_n_notif
                                                                        ,gv_re_notif
                                                                        ,gv_yes
                                                                        ,gv_yes
                                                                        ,gv_auto
                                                                        ,gr_param.block1
                                                                        ,gr_param.block2
                                                                        ,gr_param.block3
                                                                        ;
      END IF;
    -- ブロック全てがNULLで､出庫元に入力がある場合
    ELSIF (gr_param.del_from_id IS NOT NULL) THEN
      EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                      ,gd_del_to
                                                                      ,gv_mov_y
                                                                      ,gv_lot
                                                                      ,gv_product
                                                                      ,gr_param.item_class
                                                                      ,gv_req
                                                                      ,gv_adjust
                                                                      ,gv_n_notif
                                                                      ,gv_re_notif
                                                                      ,gv_yes
                                                                      ,gv_yes
                                                                      ,gv_auto
                                                                      ,gr_param.del_from_id
                                                                      ;
    -- 任意入力Ｐ全てNULLの場合
    ELSE
      EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO gt_mov_line USING gd_del_from
                                                                      ,gd_del_to
                                                                      ,gv_mov_y
                                                                      ,gv_lot
                                                                      ,gv_product
                                                                      ,gr_param.item_class
                                                                      ,gv_req
                                                                      ,gv_adjust
                                                                      ,gv_n_notif
                                                                      ,gv_re_notif
                                                                      ,gv_yes
                                                                      ,gv_yes
                                                                      ,gv_auto
                                                                      ;
    END IF;
--
  EXCEPTION
    WHEN lock_error_expt THEN
-- 2009/12/10 H.Itou Del Start 本稼動障害#383 ロックはメインSQLで取得するため不要
--      -- カーソルオープン時、クローズへ
--      IF (cur_get_lock%ISOPEN) THEN
--        CLOSE cur_get_lock;
--      END IF;
-- 2009/12/10 H.Itou Del End
--
      ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXWSH'
                                                     ,gv_err_lock      -- ロックエラー
                                                     ,gv_tkn_table     -- トークン
                                                     ,gv_msg_lock_2    -- テーブル名
                                                    )
                                                    ,1
                                                    ,5000);
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_mov_req;
--
  /**********************************************************************************
   * Procedure Name   : pro_del_mov_lot
   * Description      : 移動ロッド詳細（アドオン）削除  (G-4)
   ***********************************************************************************/
  PROCEDURE pro_del_mov_lot
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_del_mov_lot'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    ln_cnt  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 入力Ｐ「処理種別」が『出荷依頼』か『指定なし(ALL)』の場合､実行
    IF ((gr_param.action_type = gv_s_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- 受注明細アドオンID格納
      <<o_line_id_data_loop>>
      FOR i IN 1..gt_order_line.COUNT LOOP
        -- LOOPカウント用変数へカウント数挿入
        gn_l_id_cnt := i;
--
        gt_l_order_line_id(gn_l_id_cnt) := gt_order_line(i). o_line_id;  -- 受注明細アドオンID
      END LOOP o_line_id_data_loop;
--
      -- 出荷依頼対象データ抽出で取得した受注明細アドオンIDに対応した移動ロッド詳細を一括削除
      FORALL o_id_cnt IN 1 .. gt_l_order_line_id.COUNT
        DELETE
        FROM xxinv_mov_lot_details  xmld    -- 移動ロット詳細（アドオン）
        WHERE xmld.mov_line_id        = gt_l_order_line_id(o_id_cnt)  -- 受注明細アドオンID
        AND   xmld.document_type_code = gv_ship_req                   -- 文書タイプ「出荷依頼」
-- M.Hokkanji Ver1.3 START
        AND   xmld.record_type_code = gv_record_type_10               -- レコードタイプ(指示)
-- M.Hokkanji Ver1.3 END
        ;
--
      -- 削除件数をカウント
-- 2008/06/03 START カーソルで処理されない場合SQL%rowcountは前のSQLの処理件数を
-- 表示するため上記カーソルが実行された場合のみ実行するように条件を追加
      -- 対象の受注明細アドオンIDが一件以上の場合削除件数を加算
      IF (gt_order_line.COUNT >= 1) THEN
        ln_cnt := SQL%rowcount;
        gn_del_cut := gn_del_cut + ln_cnt;
      END IF;
-- 2008/06/03 END
--
    END IF;
--
    -- 入力Ｐ「処理種別」が『移動指示依頼』か『指定なし(ALL)』の場合､実行
    IF ((gr_param.action_type = gv_m_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- 移動明細ID格納
      <<m_line_id_data_loop>>
      FOR i IN 1..gt_mov_line.COUNT LOOP
        -- LOOPカウント用変数へカウント数挿入
        gn_m_id_cnt := i;
--
        gt_mod_line_id(gn_m_id_cnt) := gt_mov_line(i).m_line_id;  -- 移動明細ID
      END LOOP m_line_id_data_loop;
--
      -- 移動指示対象データ抽出で取得した移動明細IDに対応した移動ロッド詳細を一括削除
      FORALL m_id_cnt IN 1 .. gt_mod_line_id.COUNT
        DELETE
        FROM xxinv_mov_lot_details  xmld    -- 移動ロット詳細（アドオン）
        WHERE xmld.mov_line_id        = gt_mod_line_id(m_id_cnt)  -- 受注明細アドオンID
        AND   xmld.document_type_code = gv_move_req               -- 文書タイプ「移動指示」
-- M.Hokkanji Ver1.3 START
        AND   xmld.record_type_code = gv_record_type_10               -- レコードタイプ(指示)
-- M.Hokkanji Ver1.3 END
        ;
--
      -- 削除件数をカウント
-- 2008/06/03 START カーソルで処理されない場合SQL%rowcountは前のSQLの処理件数を
-- 表示するため上記カーソルが実行された場合のみ実行するように条件を追加
      -- 対象の移動明細IDが一件以上の場合削除件数を加算
      IF (gt_mod_line_id.COUNT >= 1) THEN
        ln_cnt := SQL%rowcount;
        gn_del_cut := gn_del_cut + ln_cnt;
      END IF;
-- 2008/06/03 END
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_del_mov_lot;
--
  /**********************************************************************************
   * Procedure Name   : pro_upd_o_lines
   * Description      : 受注明細アドオン更新  (G-5)
   ***********************************************************************************/
  PROCEDURE pro_upd_o_lines
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_upd_o_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    ln_cnt  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
     -- 受注明細アドオンの更新を実施
     FORALL i IN 1 .. gt_l_order_line_id.COUNT
       UPDATE xxwsh_order_lines_all         xola    -- 受注明細アドオン
       SET xola.reserved_quantity        = 0                 -- 引当数
          ,xola.automanual_reserve_class = NULL              -- 自動手動引当区分
          ,xola.warning_class            = NULL              -- 警告区分
          ,xola.warning_date             = NULL              -- 警告日付
          ,xola.last_updated_by          = gn_last_upd_by    -- 最終更新者
          ,xola.last_update_date         = gd_last_upd_date  -- 最終更新日
          ,xola.last_update_login        = gn_last_upd_login -- 最終更新ログイン
          ,xola.request_id               = gn_request_id     -- 要求ID
          ,xola.program_application_id   = gn_prog_appl_id   -- コンカレント・プログラム・アプリID
          ,xola.program_id               = gn_prog_id        -- コンカレント・プログラムID
-- M.Hokkanji Ver1.2 START
          ,xola.program_update_date      = gd_prog_upd_date  -- プログラム更新日
-- M.Hokkanji Ver1.2 END
       WHERE xola.order_line_id   = gt_l_order_line_id(i)  -- 受注明細アドオンID
       ;
--
     -- 処理件数カウント
-- M.Hokkanji Ver1.3 START
-- 処理件数は移動ロット詳細の削除件数をカウントするように変更
--    IF ( gt_l_order_line_id.COUNT >= 1 ) THEN
--      ln_cnt        := SQL%rowcount;
--      gn_target_cnt := gn_target_cnt + ln_cnt;
--    END IF;
-- M.Hokkanji Ver1.3 END
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_upd_o_lines;
--
  /**********************************************************************************
   * Procedure Name   : pro_upd_m_r_lines
   * Description      : 移動依頼/指示明細（アドオン）更新 (G-6)
   ***********************************************************************************/
  PROCEDURE pro_upd_m_r_lines
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_upd_m_r_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    ln_cnt  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
   -- 移動依頼/指示明細（アドオン）の更新を実施
   FORALL i IN 1 .. gt_mod_line_id.COUNT
     UPDATE xxinv_mov_req_instr_lines     xmril   -- 移動依頼/指示明細（アドオン）
     SET xmril.reserved_quantity        = 0                 -- 引当数
        ,xmril.automanual_reserve_class = NULL              -- 自動手動引当区分
        ,xmril.warning_class            = NULL              -- 警告区分
        ,xmril.warning_date             = NULL              -- 警告日付
        ,xmril.last_updated_by          = gn_last_upd_by    -- 最終更新者
        ,xmril.last_update_date         = gd_last_upd_date  -- 最終更新日
        ,xmril.last_update_login        = gn_last_upd_login -- 最終更新ログイン
        ,xmril.request_id               = gn_request_id     -- 要求ID
        ,xmril.program_application_id   = gn_prog_appl_id   -- コンカレント・プログラム・アプリID
        ,xmril.program_id               = gn_prog_id        -- コンカレント・プログラムID
-- M.Hokkanji Ver1.2 START
        ,xmril.program_update_date      = gd_prog_upd_date  -- プログラム更新日
-- M.Hokkanji Ver1.2 END
     WHERE xmril.mov_line_id   = gt_mod_line_id(i)  -- 移動明細ID
     ;
--
     -- 処理件数カウント
-- M.Hokkanji Ver1.3 START
-- 処理件数は移動ロット詳細の削除件数をカウントするように変更
--    IF ( gt_mod_line_id.COUNT >= 1 ) THEN
--      ln_cnt        := SQL%rowcount;
--      gn_target_cnt := gn_target_cnt + ln_cnt;
--    END IF;
-- M.Hokkanji Ver1.3 END
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_upd_m_r_lines;
--
  /**********************************************************************************
   * Procedure Name   : pro_out_msg
   * Description      : メッセージ出力  (G-7)
   ***********************************************************************************/
  PROCEDURE pro_out_msg
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_out_msg'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 移動ロット詳細（アドオン）にて削除した件数をメッセージ出力
    gv_out_msg := xxcmn_common_pkg.get_msg( gv_application       -- 'XXWSH'
                                           ,gv_err_del_count     -- 削除件数メッセージ
                                           ,gv_tkn_count         -- トークン
                                           ,gn_del_cut           -- 削除件数
                                           );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_out_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_item_class          IN  VARCHAR2   -- 1.商品区分
     ,iv_action_type         IN  VARCHAR2   -- 2.処理種別
     ,iv_block1              IN  VARCHAR2   -- 3.ブロック１
     ,iv_block2              IN  VARCHAR2   -- 4.ブロック２
     ,iv_block3              IN  VARCHAR2   -- 5.ブロック３
     ,iv_deliver_from_id     IN  VARCHAR2   -- 6.出庫元
     ,iv_deliver_type        IN  VARCHAR2   -- 7.出庫形態
     ,iv_deliver_date_from   IN  VARCHAR2   -- 8.出庫日From
     ,iv_deliver_date_to     IN  VARCHAR2   -- 9.出庫日To
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
     ,iv_instruction_dept    IN  VARCHAR2   -- 10.指示部署
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Mod Start 本番障害#1447対応
     ,iv_item_code           IN  VARCHAR2   -- 11.品目コード
-- 2009/05/01 H.Itou Add End
     ,ov_errbuf              OUT VARCHAR2   --   エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT VARCHAR2   --   リターン・コード             --# 固定 #
     ,ov_errmsg              OUT VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
    )
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- パラメータ格納
    gr_param.item_class   := iv_item_class;              -- 商品区分
    gr_param.action_type  := iv_action_type;             -- 処理種別
    gr_param.block1       := iv_block1;                  -- ブロック１
    gr_param.block2       := iv_block2;                  -- ブロック２
    gr_param.block3       := iv_block3;                  -- ブロック３
    gr_param.del_from_id  := iv_deliver_from_id;         -- 出庫元
    gr_param.del_type     := iv_deliver_type;            -- 出庫形態
    gr_param.del_d_from   := iv_deliver_date_from;       -- 出庫日From
    gr_param.del_d_to     := iv_deliver_date_to;         -- 出庫日To
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
    gr_param.instruction_dept := iv_instruction_dept;    -- 指示部署
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Mod Start 本番障害#1447対応
    gr_param.item_code    := iv_item_code;               -- 品目コード
-- 2009/05/01 H.Itou Add End
--
    -- 開始時のシステム現在日付を代入
    gd_sysdate             := SYSDATE;
--
    -- ＷＨＯカラム取得
    gn_last_upd_by         := FND_GLOBAL.USER_ID;         -- 最終更新者
    gd_last_upd_date       := gd_sysdate;                 -- 最終更新日
    gn_last_upd_login      := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    gn_request_id          := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    gn_prog_appl_id        := FND_GLOBAL.PROG_APPL_ID;    -- プログラムアプリケーションID
    gn_prog_id             := FND_GLOBAL.CONC_PROGRAM_ID; -- プログラムID
-- M.Hokkanji Ver1.2 START
    gd_prog_upd_date       := gd_sysdate;                 -- プログラム更新日
-- M.Hokkanji Ver1.2 END
--
    -- 処理件数初期化
    gn_target_cnt          := 0;
--
    -- =====================================================
    --  入力パラメータチェック (G-1)
    -- =====================================================
    pro_param_chk
      (
        ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2009/05/01 H.Itou Add Start 本番障害#1447
    -- =====================================================
    --  品目リスト取得  (G-X)
    -- =====================================================
    pro_get_item_code_list
      (
        iv_item_code      => iv_item_code   -- 品目コード
       ,ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/05/01 H.Itou Add End
--
    -- 入力Ｐ「処理種別」が『出荷依頼』か『指定なし(ALL)』の場合､実行
    IF ((gr_param.action_type = gv_s_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  出荷依頼対象データ抽出 (G-2)
      -- =====================================================
      pro_get_h_o_all
        (
          ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 入力Ｐ「処理種別」が『移動指示依頼』か『指定なし(ALL)』の場合､実行
    IF ((gr_param.action_type = gv_m_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  移動指示対象データ抽出 (G-3)
      -- =====================================================
      pro_get_mov_req
        (
          ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    --  移動ロッド詳細（アドオン）削除 (G-4)
    -- =====================================================
    pro_del_mov_lot
      (
        ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 入力Ｐ「処理種別」が『出荷依頼』か『指定なし(ALL)』の場合､実行
    IF ((gr_param.action_type = gv_s_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  受注明細アドオン更新 (G-5)
      -- =====================================================
      pro_upd_o_lines
        (
          ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 入力Ｐ「処理種別」が『移動指示依頼』か『指定なし(ALL)』の場合､実行
    IF ((gr_param.action_type = gv_m_req)
    OR  (gr_param.action_type IS NULL))
    THEN
      -- =====================================================
      --  移動依頼/指示明細（アドオン）更新 (G-6)
      -- =====================================================
      pro_upd_m_r_lines
        (
          ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    --  メッセージ出力 (G-7)
    -- =====================================================
    pro_out_msg
      (
        ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
     ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
     ,iv_item_class         IN  VARCHAR2      -- 1.商品区分
     ,iv_action_type        IN  VARCHAR2      -- 2.処理種別
     ,iv_block1             IN  VARCHAR2      -- 3.ブロック１
     ,iv_block2             IN  VARCHAR2      -- 4.ブロック２
     ,iv_block3             IN  VARCHAR2      -- 5.ブロック３
     ,iv_deliver_from_id    IN  VARCHAR2      -- 6.出庫元
     ,iv_deliver_type       IN  VARCHAR2      -- 7.出庫形態
     ,iv_deliver_date_from  IN  VARCHAR2      -- 8.出庫日From
     ,iv_deliver_date_to    IN  VARCHAR2      -- 9.出庫日To
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
     ,iv_instruction_dept   IN  VARCHAR2      -- 10.指示部署
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Mod Start 本番障害#1447対応
     ,iv_item_code          IN  VARCHAR2      -- 11.品目コード
-- 2009/05/01 H.Itou Add End
    )
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
-- 2008/06/03 START
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
-- 2008/06/03 END
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -----------------------------------------------
    -- 入力パラメータ出力                        --
    -----------------------------------------------
    -- 入力パラメータ「商品区分」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12955','ITEM',iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「処理種別」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12956','AC_TYPE',iv_action_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック1」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12957','IN_BLOCK1',iv_block1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック2」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12958','IN_BLOCK2',iv_block2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック3」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12959','IN_BLOCK3',iv_block3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫元」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12960','FROM_ID',iv_deliver_from_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫形態」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12961','TYPE',iv_deliver_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫日From」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12962','D_FROM',iv_deliver_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫日To」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-12963','D_TO',iv_deliver_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
    -- 入力パラメータ「指示部署」出力
    gv_out_msg := '指示部署： ' || iv_instruction_dept;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
-- 2009/01/27 H.Itou Add End
--
-- 2009/05/01 H.Itou Mod Start 本番障害#1447対応
    -- 入力パラメータ「品目コード」出力
    gv_out_msg := '品目コード： ' || iv_item_code;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
-- 2009/05/01 H.Itou Add End
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain
      (
        iv_item_class        => iv_item_class         -- 1.商品区分
       ,iv_action_type       => iv_action_type        -- 2.処理種別
       ,iv_block1            => iv_block1             -- 3.ブロック１
       ,iv_block2            => iv_block2             -- 4.ブロック２
       ,iv_block3            => iv_block3             -- 5.ブロック３
       ,iv_deliver_from_id   => iv_deliver_from_id    -- 6.出庫元
       ,iv_deliver_type      => iv_deliver_type       -- 7.出庫形態
       ,iv_deliver_date_from => iv_deliver_date_from  -- 8.出庫日From
       ,iv_deliver_date_to   => iv_deliver_date_to    -- 9.出庫日To
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
       ,iv_instruction_dept  => iv_instruction_dept   -- 10.指示部署
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Mod Start 本番障害#1447対応
       ,iv_item_code         => iv_item_code          -- 11.品目コード
-- 2009/05/01 H.Itou Add End
       ,ov_errbuf            => lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           => lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg            => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
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
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --処理件数出力
-- M.Hokkanji Ver1.3 START
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_del_cut));
-- M.Hokkanji Ver1.3 END
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = USERENV('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type
                                                                     ,flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
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
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh920002c;
/
