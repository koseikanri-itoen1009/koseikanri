CREATE OR REPLACE PACKAGE BODY XXWSH420003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH420003C(body)
 * Description      : 出荷依頼/出荷実績作成処理起動処理
 * MD.050           : 出荷実績 T_MD050_BPO_420
 * MD.070           : 出荷依頼出荷実績作成処理 T_MD070_BPO_42C
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_sql_pattern      条件パターンチェック
 *  fwd_sql_create         A-2 SQL文作成
 *  get_demand_inf_fwd     A-3 移動用SQL文作成
 *  check_parameter        A-1  入力パラメータチェック
 *  release_lock           ロック解除処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15   1.0  SCS  北寒寺正夫   新規作成
 *  2008/12/25   1.1  SCS  菅原大輔     本番障害#845対応(子処理起動順変更、ディレイ追加) 
 *  2009/11/05   1.2  SCS  伊藤 ひとみ  本番#1648 顧客フラグ対応
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
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  lock_expt              EXCEPTION;     -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXWSH420003C';       -- パッケージ名
  --メッセージ番号
--  gv_msg_92a_002       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10033';    -- パラメータ未入力
--  gv_msg_92a_003       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12857';    -- パラメータ書式
--  gv_msg_92a_004       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12953';    -- FromTo逆転
--  gv_msg_92a_009       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11222';    -- パラメータ書式
  gv_msg_xxcmn10135    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- 要求の発行失敗エラー
  --定数
  gv_mst_normal        CONSTANT VARCHAR2(10)  := '正常終了';
  gv_mst_warn          CONSTANT VARCHAR2(10)  := '警告終了';
  gv_mst_error         CONSTANT VARCHAR2(10)  := '異常終了';
  gv_cons_item_class   CONSTANT VARCHAR2(100) := '商品区分';
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- メッセージ区分XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- メッセージ区分XXCMN
  -- クイックコード値
  gv_order_status_04   CONSTANT VARCHAR2(15)  := '04';                 -- 出荷実績計上済み(出荷)
  gv_order_status_08   CONSTANT VARCHAR2(15)  := '08';                 -- 出荷実績計上済み(支給)
  gv_yes               CONSTANT VARCHAR2(1)   := 'Y';                  -- YES_NO区分（YES)
  gv_no                CONSTANT VARCHAR2(1)   := 'N';                  -- YES_NO区分（NO)
  gv_document_type_10  CONSTANT VARCHAR2(15)  := '10';                 -- 出荷依頼
  gv_document_type_30  CONSTANT VARCHAR2(15)  := '30';                 -- 支給指示
  gv_record_type_20    CONSTANT VARCHAR2(15)  := '20';                 -- 出庫実績
  gv_ship_class_1      CONSTANT VARCHAR2(15)  := '1';                  -- 出荷依頼
  gv_ship_class_2      CONSTANT VARCHAR2(15)  := '2';                  -- 支給依頼
  gv_ship_class_3      CONSTANT VARCHAR2(15)  := '3';                  -- 倉替返品
  gv_cons_flg_yes      CONSTANT VARCHAR2(1)   := 'Y';                  -- フラグ 'Y'
  gv_cons_flg_no       CONSTANT VARCHAR2(1)   := 'N';                  -- フラグ 'N'
--  gv_cons_deliv_from   CONSTANT VARCHAR2(100) := '出庫日From';
--  gv_cons_deliv_to     CONSTANT VARCHAR2(100) := '出庫日To';
--  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '出荷依頼'
--  gv_cons_biz_t_move   CONSTANT VARCHAR2(2)   := '20';                 -- '移動指示'(文書タイプ)
--  gv_cons_biz_t_deliv  CONSTANT VARCHAR2(2)   := '10';                 -- '出荷依頼'
--  gv_cons_input_param  CONSTANT VARCHAR2(100) := '入力パラメータ値';   -- '入力パラメータ値'
--  gv_cons_notif_status CONSTANT VARCHAR2(3)   := '40';                 -- 「確定通知済」
--  gv_cons_status       CONSTANT VARCHAR2(2)   := '03';                 -- 「締め済み」
--  gv_cons_lot_ctl      CONSTANT VARCHAR2(1)   := '1';                  -- 「ロット管理品」
--  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- 「製品」
--  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- 「積送あり」
--  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- 「調整中」
--  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- 「依頼済」
--  gv_cons_order_lines  CONSTANT VARCHAR2(50)  := '受注明細アドオン';
--  gv_cons_instr_lines  CONSTANT VARCHAR2(50)  := '移動依頼/指示明細(アドオン)';
--  gv_cons_error        CONSTANT VARCHAR2(1)   := '1';                  -- 共通関数でのエラー
--  gv_cons_no_judge     CONSTANT VARCHAR2(2)   := '10';                 -- 「未判定」
--  gv_cons_am_auto      CONSTANT VARCHAR2(2)   := '10';                 -- 「自動引当」
--  gv_cons_rec_type     CONSTANT VARCHAR2(2)   := '10';                 -- 「指示」
--  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- 商品区分・ドリンク
--  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- 商品区分・リーフ
--  gv_cons_deliv_fm     CONSTANT VARCHAR2(50)  := '出荷元';             -- 出荷元
--  gv_cons_deliv_tp     CONSTANT VARCHAR2(50)  := '出荷形態';           -- 出荷形態^
--  gv_cons_number       CONSTANT VARCHAR2(50)  := '数値';               -- 数値^
  --トークン
--  gv_tkn_parm_name     CONSTANT VARCHAR2(15)  := 'PARM_NAME';          -- パラメータ
--  gv_tkn_param_name    CONSTANT VARCHAR2(15)  := 'PARAM_NAME';         -- パラメータ
--  gv_tkn_parameter     CONSTANT VARCHAR2(15)  := 'PARAMETER';          -- パラメータ名
--  gv_tkn_type          CONSTANT VARCHAR2(15)  := 'TYPE';               -- 書式タイプ
--  gv_tkn_table         CONSTANT VARCHAR2(15)  := 'TABLE';              -- テーブル
--  gv_tkn_err_code      CONSTANT VARCHAR2(15)  := 'ERR_CODE';           -- エラーコード
--  gv_tkn_err_msg       CONSTANT VARCHAR2(15)  := 'ERR_MSG';            -- エラーメッセージ
--  gv_tkn_ship_type     CONSTANT VARCHAR2(15)  := 'SHIP_TYPE';          -- 配送先
--  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- 品目
--  gv_tkn_lot           CONSTANT VARCHAR2(15)  := 'LOT';                -- ロットNo
--  gv_tkn_request_type  CONSTANT VARCHAR2(15)  := 'REQUEST_TYPE';       -- 依頼No/移動番号_区分
--  gv_tkn_p_date        CONSTANT VARCHAR2(15)  := 'P_DATE';             -- 製造日
--  gv_tkn_use_by_date   CONSTANT VARCHAR2(15)  := 'USE_BY_DATE';        -- 賞味期限
--  gv_tkn_fix_no        CONSTANT VARCHAR2(15)  := 'FIX_NO';             -- 固有記号
--  gv_tkn_request_no    CONSTANT VARCHAR2(15)  := 'REQUEST_NO';         -- 依頼No
--  gv_tkn_item_no       CONSTANT VARCHAR2(15)  := 'ITEM_NO';            -- 品目コード
--  gv_tkn_reverse_date  CONSTANT VARCHAR2(15)  := 'REVDATE';            -- 逆転日付
--  gv_tkn_arrival_date  CONSTANT VARCHAR2(15)  := 'ARRIVAL_DATE';       -- 着荷日付
--  gv_tkn_ship_to       CONSTANT VARCHAR2(15)  := 'SHIP_TO';            -- 配送先
--  gv_tkn_standard_date CONSTANT VARCHAR2(15)  := 'STANDARD_DATE';      -- 基準日付
--  gv_request_name_ship CONSTANT VARCHAR2(15)  := '依頼No';             -- 依頼No
--  gv_request_name_move CONSTANT VARCHAR2(15)  := '移動番号';           -- 移動番号
--  gv_ship_name_ship    CONSTANT VARCHAR2(15)  := '配送先';             -- 配送先
--  gv_ship_name_move    CONSTANT VARCHAR2(15)  := '入庫先';             -- 入庫先
  --プロファイル
--  gv_action_type_ship  CONSTANT VARCHAR2(2)   := '1';                  -- 出荷
--  gv_action_type_move  CONSTANT VARCHAR2(2)   := '3';                  -- 移動
--  gv_base              CONSTANT VARCHAR2(1)   := '1'; -- 拠点
--  gv_wzero             CONSTANT VARCHAR2(2)   := '00';
--  gv_flg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_total_cnt         NUMBER :=0;       -- 対象件数
--  gd_yyyymmdd_from     DATE;             -- 入力パラメータ出庫日From
--  gd_yyyymmdd_to       DATE;             -- 入力パラメータ出庫日To
--  gv_yyyymmdd_from     VARCHAR2(10);     -- 入力パラメータ出庫日From
--  gv_yyyymmdd_to       VARCHAR2(10);     -- 入力パラメータ出庫日To
  gn_login_user        NUMBER;           -- ログインID
  gn_created_by        NUMBER;           -- ログインユーザID
  gn_conc_request_id   NUMBER;           -- 要求ID
  gn_prog_appl_id      NUMBER;           -- アプリケーションID
  gn_conc_program_id   NUMBER;           -- プログラムID
--  gt_item_class        xxcmn_lot_status_v.prod_class_code%TYPE;  -- 商品区分
--
  -- 処理対象となる出庫元を格納する
  TYPE order_rec IS RECORD(
     deliver_from      xxwsh_order_headers_all.deliver_from%TYPE     -- 出庫元
   , total_cnt         NUMBER                                        -- 件数
  );
  TYPE order_tbl IS TABLE OF order_rec INDEX BY PLS_INTEGER;
  gr_demand_tbl  order_tbl;
--
  /***********************************************************************************
   * Procedure Name   : get_order_info
   * Description      : 受注アドオン情報取得
   ***********************************************************************************/
  PROCEDURE get_order_info(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_info'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_select1          VARCHAR2(32000) DEFAULT NULL;
    lv_select2          VARCHAR2(32000) DEFAULT NULL;
    lv_select_where     VARCHAR2(32000) DEFAULT NULL;
    lv_select_lock      VARCHAR2(32000) DEFAULT NULL;
    lv_select_order     VARCHAR2(32000) DEFAULT NULL;
    -- *** ローカル・カーソル ***
    TYPE cursor_type IS REF CURSOR;
    fwd_cur cursor_type;
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
    -- ***       受注アドオン情報取得      ***
    -- ***************************************
    lv_select2 := 'SELECT xoha.deliver_from, '
        ||       '        COUNT(xoha.order_header_id) '
        ||       ' FROM   xxwsh_order_headers_all      xoha,'
-- 2009/11/05 H.Itou Del Start 本番障害#1648 顧客ほ保管場所は不要な結合なので削除。
--        ||       '        xxcmn_cust_accounts_v        xcav,'
--        ||       '        xxwsh_oe_transaction_types_v  xottv1,'
        ||       '        xxwsh_oe_transaction_types_v  xottv1'
--        ||       '        xxcmn_item_locations_v        xilv'
-- 2009/11/05 H.Itou Del End
        ||       ' WHERE  xoha.req_status IN (''' || gv_order_status_04 || ''','''|| gv_order_status_08 || ''')'
-- 2009/11/05 H.Itou Del Start 本番障害#1648
--        ||       ' AND    xilv.segment1 = xoha.deliver_from'
--        ||       ' AND    xcav.party_id = xoha.customer_id'
-- 2009/11/05 H.Itou Del End
        ||       ' AND    xottv1.transaction_type_id = xoha.order_type_id'
        ||       ' AND    NVL(xoha.actual_confirm_class, '''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND    ((xoha.latest_external_flag = ''' || gv_yes || ''')'
        ||       ' OR      (xottv1.shipping_shikyu_class = ''' || gv_ship_class_3 || '''))';
--
    lv_select2 := lv_select2 
        ||       ' AND EXISTS ('
        ||       ' SELECT xola.order_header_id'
        ||       ' FROM   xxwsh_order_lines_all xola,'
        ||       '        xxcmn_item_mst_v      ximv'
        ||       ' WHERE xola.order_header_id = xoha.order_header_id'
        ||       ' AND   NVL(xola.delete_flag,'''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND   ximv.item_no  = xola.shipping_item_code )'
--2008/12/25 D.Sugahara #845 Mod Start 件数の多いものを先頭に集めるのをやめる（負荷分散）
        ||       ' GROUP BY xoha.deliver_from ';
--        ||       ' ORDER BY COUNT(xoha.order_header_id) DESC ';  
--2008/12/25 D.Sugahara #845 Mod End
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_select2);
    OPEN fwd_cur FOR lv_select2;
--
    -- データの一括取得
    FETCH fwd_cur BULK COLLECT INTO gr_demand_tbl;
--
    -- 処理件数のセット
    gn_total_cnt := gr_demand_tbl.COUNT;
--
    -- カーソルクローズ
    CLOSE fwd_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF fwd_cur%ISOPEN THEN
        CLOSE fwd_cur ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF fwd_cur%ISOPEN THEN
        CLOSE fwd_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF fwd_cur%ISOPEN THEN
        CLOSE fwd_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_order_info;
--
  /**********************************************************************************
  * Procedure Name   : release_lock
  * Description      : ロック解除
  ***********************************************************************************/
  PROCEDURE release_lock(
    in_reqid              IN NUMBER,                     -- 要求ID
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'release_lock';       -- プログラム名
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
    lv_strsql VARCHAR2(1000);
    lv_phase  VARCHAR2(5);
    lv_staus  VARCHAR2(1);
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
        SELECT
            b.id1,
            a.sid,
            a.serial#,
            b.type,
            DECODE(b.lmode,1,'null', 2,'row share', 3,'row exclusive'
             ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
        FROM
            v$session a,
            v$lock b
        WHERE
            a.sid = b.sid
            AND (b.id1, b.id2) in 
                (SELECT d.id1, d.id2 FROM v$lock d 
                 WHERE d.id1=b.id1
                 AND d.id2=b.id2 AND d.request > 0) 
            AND b.id1 IN (SELECT bb.id1
                         FROM v$session aa, v$lock bb
                         WHERE aa.lockwait = bb.kaddr 
                         AND aa.module = 'XXWSH420004C')
            AND b.lmode = 6;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
  LOOP
        EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
        BEGIN
            SELECT DECODE(fcr.phase_code,'C','Y','I','Y','N')
            INTO   lv_phase
            FROM   fnd_concurrent_requests fcr 
            WHERE  fcr.request_id = in_reqid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lv_phase := 'Y';
                NULL;
        END;
        FOR lock_rec IN lock_cur LOOP
          lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
          EXECUTE IMMEDIATE lv_strsql;
          lv_staus := '1';
        END LOOP;
  END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END release_lock;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf             OUT  NOCOPY   VARCHAR2     -- エラー・メッセージ           --# 固定 #
   , ov_retcode            OUT  NOCOPY   VARCHAR2     -- リターン・コード             --# 固定 #
   , ov_errmsg             OUT  NOCOPY   VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_conc_p_c   CONSTANT VARCHAR2(100) := 'COMPLETE';
    cv_conc_s_w   CONSTANT VARCHAR2(100) := 'WARNING';
    cv_conc_s_e   CONSTANT VARCHAR2(100) := 'ERROR';
    cv_param_all  CONSTANT VARCHAR2(100) := 'ALL';
    cv_param_0    CONSTANT VARCHAR2(100) := '0';
    cv_param_1    CONSTANT VARCHAR2(100) := '1';
--
    -- *** ローカル変数 ***
    lc_out_param     VARCHAR2(1000);   -- 入力パラメータの処理結果レポート出力用
--
    lv_phase         VARCHAR2(100);
    lv_status        VARCHAR2(100);
    lv_dev_phase     VARCHAR2(100);
    lv_dev_status    VARCHAR2(100);
--    lv_lot_biz_class VARCHAR2(1);      -- ロット逆転処理種別
--    ln_result        NUMBER;           -- 処理結果(0:正常、1:異常)
--    ld_standard_date DATE;             -- 基準日付
    i                INTEGER := 0;
    TYPE reqid_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    reqid_rec reqid_tab;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
--
    -- ===============================================
    --   処理対象データ取得
    -- ===============================================
    get_order_info(    lv_errbuf      -- エラー・メッセージ           --# 固定 #
                     , lv_retcode     -- リターン・コード             --# 固定 #
                     , lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理
    IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    --   出庫元ループ
    -- ===============================================
    <<demand_inf_loop>>
    FOR ln_d_cnt IN 1..gn_total_cnt LOOP
      i := i + 1;
      gn_target_cnt := gn_target_cnt + 1;
      reqid_rec(i) := FND_REQUEST.SUBMIT_REQUEST(
                         application       => 'XXWSH'                              -- アプリケーション短縮名
                       , program           => 'XXWSH420004C'                       -- プログラム名
                       , argument1         => NULL                                 -- ブロック
                       , argument2         => gr_demand_tbl(ln_d_cnt).deliver_from -- 出庫元
                       , argument3         => NULL                                 -- 依頼No
                         );
      -- エラーの場合
      IF ( reqid_rec(i) = 0 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application   => gv_cons_msg_kbn_cmn
                      ,iv_name          => gv_msg_xxcmn10135);
        RAISE global_api_others_expt;
      ELSE
        COMMIT;
      END IF;
       -- エラー処理
       IF ( lv_retcode = gv_status_error ) THEN
           gn_error_cnt := 1;
           RAISE global_process_expt;
       END IF;
--2008/12/25 D.Sugahara #845 Mod Start コンカレント発行間隔ディレイ（負荷分散）
      DBMS_LOCK.SLEEP(2);  --2秒間隔をあける
--2008/12/25 D.Sugahara #845 Mod End
--
    END LOOP demand_inf_loop; -- 出庫元ループ終わり
--
/*
    -- ===============================================
    -- ロック暫定対応
    -- ===============================================
    <<lock_loop>>
    FOR k IN 1 .. i LOOP
            -- 子要求についてロックで止まっているものを進める
            release_lock(reqid_rec(k)
                      , lv_errbuf
                      , lv_retcode
                      , lv_errmsg);
    END LOOP lock_loop; -- ロック開放ループ終わり
*/
--
    -- ===============================================
    -- A-5  コンカレントステータスのチェック
    -- ===============================================
    <<chk_status>>
    FOR j IN 1 .. i LOOP
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
             request_id => reqid_rec(j)
            ,interval   => 1
            ,max_wait   => 0
            ,phase      => lv_phase
            ,status     => lv_status
            ,dev_phase  => lv_dev_phase
            ,dev_status => lv_dev_status
            ,message    => lv_errbuf
            ) ) THEN
        -- ステータス反映
        -- フェーズ:完了
        IF ( lv_dev_phase = cv_conc_p_c ) THEN
          -- ステータス:異常
          IF ( lv_dev_status = cv_conc_s_e ) THEN
            ov_retcode := gv_status_error;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'出庫元:' || gr_demand_tbl(j).deliver_from || '、件数:' || TO_CHAR(gr_demand_tbl(j).total_cnt) || '件、要求ID：' || TO_CHAR(reqid_rec(j)) || '、処理結果：' || gv_msg_part || gv_mst_error);
            gn_error_cnt := gn_error_cnt + 1;
          -- ステータス:警告
          ELSIF ( lv_dev_status = cv_conc_s_w ) THEN
            IF ( ov_retcode < 1 ) THEN
              ov_retcode := gv_status_warn;
            END IF;
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'出庫元:' || gr_demand_tbl(j).deliver_from || '、件数:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '件、要求ID：' || TO_CHAR(reqid_rec(j)) || '、処理結果：' || gv_msg_part || gv_mst_warn);
            gn_warn_cnt := gn_warn_cnt + 1;
          -- ステータス:正常
          ELSE
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'出庫元:' || gr_demand_tbl(j).deliver_from || '、件数:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '件、要求ID：' || TO_CHAR(reqid_rec(j)) || '、処理結果：' || gv_msg_part || gv_mst_normal);
            gn_normal_cnt := gn_normal_cnt + 1;
          END IF;
        END IF;
      ELSE
        ov_retcode := gv_status_error;
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j)) || gv_msg_part || gv_mst_error);
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
--
    END LOOP chk_status;
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
    errbuf                OUT NOCOPY   VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode               OUT NOCOPY   VARCHAR2       -- リターン・コード    --# 固定 #
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
    ln_deliver_from_id   NUMBER; -- 出庫元
    ln_deliver_type      NUMBER; -- 出庫形態
--
  BEGIN
--
    -- 数値型に変換する
    lv_retcode         := gv_cons_flg_yes;
    lv_retcode         := gv_cons_flg_no;
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -----------------------------------------------
    -- 入力パラメータ出力                        --
    -----------------------------------------------
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    -- WHOカラム情報の取得
    gn_login_user       := FND_GLOBAL.LOGIN_ID;         -- ログインID
    gn_created_by       := FND_GLOBAL.USER_ID;          -- ログインユーザID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- コンカレント・プログラム・アプリケーションID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- コンカレント・プログラムID
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;   -- 対象件数
    gn_normal_cnt := 0;   -- 正常件数
    gn_warn_cnt   := 0;   -- 警告件数
    gn_error_cnt  := 0;   -- エラー件数
--
    submain(
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      IF ( lv_errmsg IS NULL ) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10030');
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00008', 'CNT', TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00009', 'CNT', TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00010', 'CNT', TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    --gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00011', 'CNT', TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'警告件数： ' || TO_CHAR(gn_warn_cnt) || ' 件');
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00012','STATUS',gv_conc_status);
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
END XXWSH420003C;
/
