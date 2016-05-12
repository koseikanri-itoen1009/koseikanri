CREATE OR REPLACE PACKAGE BODY XXWSH920007C_OT
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920007C_OT(body)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD050_BPO_920
 * MD.070           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD070_BPO92A
 * Version          : 1.16
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
 *  2008/11/20   1.0   SCS 北寒寺        新規作成
 *  2008/12/01   1.2   SCS 宮田          ロック対応
 *  2008/12/20   1.3   SCS 北寒寺        本番障害#738
 *  2009/01/19   1.4   SCS 野村          本番障害#1038
 *  2009/01/27   1.5   SCS 二瓶          本番障害#332対応（条件：出庫元不備対応）
 *  2009/01/28   1.6   SCS 伊藤          本番障害#1028対応（パラメータに指示部署追加）
 *  2009/01/28   1.7   SCS 二瓶          本番障害#949対応（トレース取得用処理追加）
 *  2009/02/03   1.8   SCS 二瓶          本番障害#949対応（トレース取得用処理削除）
 *  2009/02/18   1.9   SCS 野村          本番障害#1176対応
 *  2009/02/19   1.10  SCS 野村          本番障害#1176対応（追加修正）
 *  2009/04/03   1.11  SCS 野村          本番障害#1367（1321）調査用対応
 *  2009/04/17   1.12  SCS 野村          本番障害#1367（1321）リトライ対応
 *  2009/05/01   1.13  SCS 野村          本番障害#1367（1321）子除外対応
 *  2009/05/19   1.14  SCS 伊藤          本番障害#1447対応
 *  2010/01/18   1.15  SCS 北寒寺        本番稼働障害#701対応 品目0005000はプロト版を
 *                                       実行するように修正
 *  2009/01/21   1.16  SCS 北寒寺        本番稼働障害#701対応 プロト版のテストが終わったため
 *                                       品目0005000はプロト版を実行しないように修正
 *  2016/05/11   1.16' SCSK菅原大輔      E_本稼動_13468対応 運用テストモジュールとして作成、
 *                                       XXWSH920008C_OTを呼び出す。v.1.16と本番環境で並存させる。
 *
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
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXPT920001C';       -- パッケージ名
  --メッセージ番号
  gv_msg_92a_002       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10033';    -- パラメータ未入力
  gv_msg_92a_003       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12857';    -- パラメータ書式
  gv_msg_92a_004       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12953';    -- FromTo逆転
  gv_msg_92a_009       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11222';    -- パラメータ書式
  gv_msg_xxcmn10135    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- 要求の発行失敗エラー
  --定数
  gv_mst_normal        CONSTANT VARCHAR2(10)  := '正常終了';
  gv_mst_warn          CONSTANT VARCHAR2(10)  := '警告終了';
  gv_mst_error         CONSTANT VARCHAR2(10)  := '異常終了';
  gv_cons_item_class   CONSTANT VARCHAR2(100) := '商品区分';
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- メッセージ区分XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- メッセージ区分XXCMN
  gv_cons_deliv_from   CONSTANT VARCHAR2(100) := '出庫日From';
  gv_cons_deliv_to     CONSTANT VARCHAR2(100) := '出庫日To';
  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '出荷依頼'
  gv_cons_biz_t_move   CONSTANT VARCHAR2(2)   := '20';                 -- '移動指示'(文書タイプ)
  gv_cons_biz_t_deliv  CONSTANT VARCHAR2(2)   := '10';                 -- '出荷依頼'
  gv_cons_input_param  CONSTANT VARCHAR2(100) := '入力パラメータ値';   -- '入力パラメータ値'
  gv_cons_flg_yes      CONSTANT VARCHAR2(1)   := 'Y';                  -- フラグ 'Y'
  gv_cons_flg_no       CONSTANT VARCHAR2(1)   := 'N';                  -- フラグ 'N'
  gv_cons_notif_status CONSTANT VARCHAR2(3)   := '40';                 -- 「確定通知済」
  gv_cons_status       CONSTANT VARCHAR2(2)   := '03';                 -- 「締め済み」
  gv_cons_lot_ctl      CONSTANT VARCHAR2(1)   := '1';                  -- 「ロット管理品」
  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- 「製品」
  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- 「積送あり」
  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- 「調整中」
  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- 「依頼済」
  gv_cons_order_lines  CONSTANT VARCHAR2(50)  := '受注明細アドオン';
  gv_cons_instr_lines  CONSTANT VARCHAR2(50)  := '移動依頼/指示明細(アドオン)';
  gv_cons_error        CONSTANT VARCHAR2(1)   := '1';                  -- 共通関数でのエラー
  gv_cons_no_judge     CONSTANT VARCHAR2(2)   := '10';                 -- 「未判定」
  gv_cons_am_auto      CONSTANT VARCHAR2(2)   := '10';                 -- 「自動引当」
  gv_cons_rec_type     CONSTANT VARCHAR2(2)   := '10';                 -- 「指示」
  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- 商品区分・ドリンク
  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- 商品区分・リーフ
  gv_cons_deliv_fm     CONSTANT VARCHAR2(50)  := '出荷元';             -- 出荷元
  gv_cons_deliv_tp     CONSTANT VARCHAR2(50)  := '出荷形態';           -- 出荷形態^
  gv_cons_number       CONSTANT VARCHAR2(50)  := '数値';               -- 数値^
  --トークン
  gv_tkn_parm_name     CONSTANT VARCHAR2(15)  := 'PARM_NAME';          -- パラメータ
  gv_tkn_param_name    CONSTANT VARCHAR2(15)  := 'PARAM_NAME';         -- パラメータ
  gv_tkn_parameter     CONSTANT VARCHAR2(15)  := 'PARAMETER';          -- パラメータ名
  gv_tkn_type          CONSTANT VARCHAR2(15)  := 'TYPE';               -- 書式タイプ
  gv_tkn_table         CONSTANT VARCHAR2(15)  := 'TABLE';              -- テーブル
  gv_tkn_err_code      CONSTANT VARCHAR2(15)  := 'ERR_CODE';           -- エラーコード
  gv_tkn_err_msg       CONSTANT VARCHAR2(15)  := 'ERR_MSG';            -- エラーメッセージ
  gv_tkn_ship_type     CONSTANT VARCHAR2(15)  := 'SHIP_TYPE';          -- 配送先
  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- 品目
  gv_tkn_lot           CONSTANT VARCHAR2(15)  := 'LOT';                -- ロットNo
  gv_tkn_request_type  CONSTANT VARCHAR2(15)  := 'REQUEST_TYPE';       -- 依頼No/移動番号_区分
  gv_tkn_p_date        CONSTANT VARCHAR2(15)  := 'P_DATE';             -- 製造日
  gv_tkn_use_by_date   CONSTANT VARCHAR2(15)  := 'USE_BY_DATE';        -- 賞味期限
  gv_tkn_fix_no        CONSTANT VARCHAR2(15)  := 'FIX_NO';             -- 固有記号
  gv_tkn_request_no    CONSTANT VARCHAR2(15)  := 'REQUEST_NO';         -- 依頼No
  gv_tkn_item_no       CONSTANT VARCHAR2(15)  := 'ITEM_NO';            -- 品目コード
  gv_tkn_reverse_date  CONSTANT VARCHAR2(15)  := 'REVDATE';            -- 逆転日付
  gv_tkn_arrival_date  CONSTANT VARCHAR2(15)  := 'ARRIVAL_DATE';       -- 着荷日付
  gv_tkn_ship_to       CONSTANT VARCHAR2(15)  := 'SHIP_TO';            -- 配送先
  gv_tkn_standard_date CONSTANT VARCHAR2(15)  := 'STANDARD_DATE';      -- 基準日付
  gv_request_name_ship CONSTANT VARCHAR2(15)  := '依頼No';             -- 依頼No
  gv_request_name_move CONSTANT VARCHAR2(15)  := '移動番号';           -- 移動番号
  gv_ship_name_ship    CONSTANT VARCHAR2(15)  := '配送先';             -- 配送先
  gv_ship_name_move    CONSTANT VARCHAR2(15)  := '入庫先';             -- 入庫先
-- Ver1.3 M.Hokkanji Start
  gv_req_nodata        CONSTANT VARCHAR2(15)  := '3';                  -- 対象データ無し
-- Ver1.3 M.Hokkanji End
  --プロファイル
  gv_action_type_ship  CONSTANT VARCHAR2(2)   := '1';                  -- 出荷
  gv_action_type_move  CONSTANT VARCHAR2(2)   := '3';                  -- 移動
  gv_base              CONSTANT VARCHAR2(1)   := '1'; -- 拠点
  gv_wzero             CONSTANT VARCHAR2(2)   := '00';
  gv_flg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_total_cnt         NUMBER :=0;       -- 対象件数
  gd_yyyymmdd_from     DATE;             -- 入力パラメータ出庫日From
  gd_yyyymmdd_to       DATE;             -- 入力パラメータ出庫日To
  gv_yyyymmdd_from     VARCHAR2(10);     -- 入力パラメータ出庫日From
  gv_yyyymmdd_to       VARCHAR2(10);     -- 入力パラメータ出庫日To
  gn_login_user        NUMBER;           -- ログインID
  gn_created_by        NUMBER;           -- ログインユーザID
  gn_conc_request_id   NUMBER;           -- 要求ID
  gn_prog_appl_id      NUMBER;           -- アプリケーションID
  gn_conc_program_id   NUMBER;           -- プログラムID
  gt_item_class        xxcmn_lot_status_v.prod_class_code%TYPE;  -- 商品区分
--
  -- 需要情報のデータを格納するレコード
  TYPE demand_rec IS RECORD(
     item_code         xxwsh_order_lines_all.shipping_item_code%TYPE -- 品目(コード) V
   , total_cnt         NUMBER                                        -- 件数
  );
  TYPE demand_tbl IS TABLE OF demand_rec INDEX BY PLS_INTEGER;
  gr_demand_tbl  demand_tbl;
-- Ver1.3 M.Hokkanji Start
  TYPE data_cnt_rec IS RECORD(
      error_cnt        NUMBER            -- その日のエラー件数
    , warn_cnt         NUMBER            -- その日の警告件数
    , nomal_cnt        NUMBER            -- その日の正常件数
    , ship_date        VARCHAR2(10)      -- 処理対象日付
  );
  TYPE data_cnt_tbl IS TABLE OF data_cnt_rec INDEX BY PLS_INTEGER;
  gr_data_cnt_tbl data_cnt_tbl;
-- Ver1.3 M.Hokkanji End
--
  /**********************************************************************************
  * Function Name    : check_sql_pattern
  * Description      : SQL条件パターンチェック関数
  ***********************************************************************************/
  FUNCTION check_sql_pattern(iv_kubun           IN  VARCHAR2,              -- 出荷・移動区分
                             iv_block1          IN  VARCHAR2 DEFAULT NULL, -- ブロック１
                             iv_block2          IN  VARCHAR2 DEFAULT NULL, -- ブロック２
                             iv_block3          IN  VARCHAR2 DEFAULT NULL, -- ブロック３
                             in_deliver_from_id IN  NUMBER   DEFAULT NULL, -- 出庫元
                             in_deliver_type    IN  NUMBER   DEFAULT NULL) -- 出庫形態
                             RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sql_pattern'; --プログラム名
--
    -- *** ローカル変数 ***
    ln_pattern1         NUMBER := 0;
    ln_return_pattern   NUMBER := 0;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
    --==============================================================
    -- 任意入力を判断(出荷の場合）
    --   1 = ブロック1～3 が全部NULL
    --   2 = 出荷元 がNULL
    --   3 = 受注タイプ がNULL
    -- これらの組み合わせでの条件およびリターン値は下記のようになる
    --   1<>, 2<>, 3<> → (1 or 2) and 3 ＝ 1
    --   1= , 2= , 3<> → 3              ＝ 2
    --   1= , 2<>, 3<> → 2 and 3        ＝ 3
    --   1<>, 2= , 3<> → 1 and 3        ＝ 4
    --   1<>, 2<>, 3=  → 1 or 2         ＝ 5
    --   1= , 2= , 3=  → なし           ＝ 6
    --   1= , 2<>, 3=  → 2              ＝ 7
    --   1<>, 2= , 3=  → 1              ＝ 8
    -- 任意入力を判断(移動の場合）===================================
    --   1 = ブロック1～3 が全部NULL
    --   2 = 出荷元 がNULL
    -- これらの組み合わせでの条件およびリターン値は下記のようになる
    --   1<>, 2<>      → (1 or 2)       ＝ 5
    --   1= , 2=       → なし           ＝ 6
    --   1= , 2<>      → 2              ＝ 7
    --   1<>, 2=       → 1              ＝ 8
    --==============================================================
--
    -- ブロック１～３全てがNULLか？
    IF (    ( iv_block1 IS NULL ) 
        AND ( iv_block2 IS NULL ) 
        AND ( iv_block3 IS NULL ) ) THEN
      ln_pattern1 := 1;
    END IF;
--
    -- 「出荷」の場合
    IF( iv_kubun = gv_cons_biz_t_deliv) THEN
      -- パターン１
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type    IS NOT NULL )) THEN
        RETURN 1;
      END IF;
--
      -- パターン２
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NOT NULL ) ) THEN
        RETURN 2;
      END IF;
--
      -- パターン３
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type    IS NOT NULL ) ) THEN
        RETURN 3;
      END IF;
--
      -- パターン４
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NOT NULL ) ) THEN
        RETURN 4;
      END IF;
--
      -- パターン５
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type    IS NULL     ) ) THEN
        RETURN 5;
      END IF;
--
      -- パターン６
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NULL ) ) THEN
        RETURN 6;
      END IF;
--
      -- パターン７
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) 
          AND ( in_deliver_type IS NULL        ) ) THEN
        RETURN 7;
      END IF;
--
      -- パターン８
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NULL ) 
          AND ( in_deliver_type    IS NULL ) ) THEN
        RETURN 8;
      END IF;
--
    -- 「移動」の場合
    ELSE
      -- パターン５
      IF (    ( ln_pattern1 <> 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) ) THEN
        RETURN 5;
      END IF;
--
      -- パターン６
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NULL ) ) THEN
        RETURN 6;
      END IF;
--
      -- パターン７
      IF (    ( ln_pattern1 = 1 ) 
          AND ( in_deliver_from_id IS NOT NULL ) ) THEN
        RETURN 7;
      END IF;
--
      -- パターン８
      IF (    (ln_pattern1 <> 1 ) 
          AND (in_deliver_from_id IS NULL ) ) THEN
        RETURN 8;
      END IF;
    END IF;
    RAISE process_exp;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_sql_pattern;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : A-1  入力パラメータチェック
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_item_class         IN   VARCHAR2,     -- 商品区分
    iv_deliver_date_from  IN   VARCHAR2,     -- 出庫日From
    iv_deliver_date_to    IN   VARCHAR2,     -- 出庫日To
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    -- ************************************
    -- ***  入力パラメータ必須チェック  ***
    -- ************************************
    -- 商品区分の入力がない場合はエラーとする
    IF (iv_item_class IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                    ,gv_msg_92a_002    -- 必須入力パラメータエラー
                                                    ,gv_tkn_param_name    -- トークン'PARAM_NAME'
                                                    ,gv_cons_item_class) -- '商品区分'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫日Fromの入力がない場合はエラーとする
    IF (iv_deliver_date_from IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                    ,gv_msg_92a_002    -- 必須入力パラメータエラー
                                                    ,gv_tkn_param_name    -- トークン'PARAM_NAME'
                                                    ,gv_cons_deliv_from) -- '出庫日From'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫日Toの入力がない場合はエラーとする
    IF (iv_deliver_date_to IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                    ,gv_msg_92a_002    -- 必須入力パラメータエラー
                                                    ,gv_tkn_param_name  -- トークン'PARAM_NAME'
                                                    ,gv_cons_deliv_to) -- '出庫日To'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  対象期間書式チェック  ***
    -- ******************************
    -- 出庫日FromをYYYY/MM/DDの型に変換(NULLが帰ってきたらエラー）
    gv_yyyymmdd_from := iv_deliver_date_from;
    gd_yyyymmdd_from := FND_DATE.STRING_TO_DATE(iv_deliver_date_from, 'YYYY/MM/DD');
    IF (gd_yyyymmdd_from IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_92a_003    -- 入力パラメータ書式エラー
                                                    ,gv_tkn_parm_name  -- トークン'PARM_NAME'
                                                    ,gv_cons_deliv_from) -- '出庫日From'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫日FromをYYYY/MM/DDの型に変換(NULLが帰ってきたらエラー）
    gv_yyyymmdd_to := iv_deliver_date_to;
    gd_yyyymmdd_to := FND_DATE.STRING_TO_DATE(iv_deliver_date_to, 'YYYY/MM/DD');
    IF (gd_yyyymmdd_to IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_92a_003    -- 入力パラメータ書式エラー
                                                    ,gv_tkn_parm_name  -- トークン'PARM_NAME'
                                                    ,gv_cons_deliv_to)   -- '出庫日To'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  対象期間逆転チェック  ***
    -- ******************************
    -- 出庫日Fromと出庫日Toが逆転していたらエラー
    IF (gd_yyyymmdd_from > gd_yyyymmdd_to) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_92a_004)    -- 入力パラメータ書式エラー
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
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
  END check_parameter;
--
  /**********************************************************************************
  * Function Name    : fwd_sql_create
  * Description      : A-2  SQL文作成関数
  ***********************************************************************************/
  FUNCTION fwd_sql_create(
    iv_action_type     IN  VARCHAR2               -- 処理種別
  , iv_block1          IN  VARCHAR2 DEFAULT NULL  -- ブロック１
  , iv_block2          IN  VARCHAR2 DEFAULT NULL  -- ブロック２
  , iv_block3          IN  VARCHAR2 DEFAULT NULL  -- ブロック３
  , in_deliver_from_id IN  NUMBER   DEFAULT NULL  -- 出庫元
  , in_deliver_type    IN  NUMBER   DEFAULT NULL  -- 出庫形態
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
  , iv_instruction_dept IN  VARCHAR2              -- 指示部署
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
  , iv_item_code        IN  VARCHAR2              -- 品目コード
-- 2009/05/19 H.Itou Add End
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fwd_sql_create'; --プログラム名
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
-- 
    -- *** ローカル変数 ***
    ln_pattern     NUMBER := 0;
    lv_fwd_sql     VARCHAR2(32767);   -- SQL文格納バッファ
--
  BEGIN
    -- SQL条件パターンチェック
    ln_pattern := check_sql_pattern(gv_cons_biz_t_deliv,
                                    iv_block1,
                                    iv_block2,
                                    iv_block3,
                                    in_deliver_from_id,
                                    in_deliver_type);
    -- ***********
    -- SQL文組み立て(固定部分)
    -- ***********
    lv_fwd_sql  := ' SELECT data.item_no item_code ' -- 品目コード
                || '      , SUM(data.cnt)  total_cnt ' -- 件数
                || ' FROM   ( ';
    -- 処理種別がNullまたは、出荷の場合
    IF ( ( iv_action_type IS NULL ) OR ( iv_action_type = gv_action_type_ship ) ) THEN
      -- ***********
      -- SQL文組み立て(出荷固定部分)
      -- ***********
      lv_fwd_sql  := lv_fwd_sql 
                    || ' SELECT  im2.item_no item_no '              -- 品目(コード)
                          || ' , COUNT(1)              cnt '          -- 件数
                    || ' FROM    xxcmn_item_locations2_v        il '  -- OPM保管場所マスタ
                          || ' , xxwsh_order_headers_all        oh '  -- 受注ヘッダアドオン
                          || ' , xxcmn_cust_accounts2_v         p  '  -- 顧客情報VIEW
                          || ' , xxwsh_oe_transaction_types2_v  tt '  -- 受注タイプ
                          || ' , xxwsh_order_lines_all          ol '  -- 受注明細アドオン
                          || ' , xxcmn_item_mst2_v              im '  -- OPM品目マスタ
                          || ' , xxcmn_item_mst2_v              im2 ' -- OPM品目マスタ
                          || ' , xxcmn_item_categories5_v       ic '  -- カテゴリ情報VIEW
                    || ' WHERE   il.inventory_location_id = oh.deliver_from_id '
                    || ' AND     oh.schedule_ship_date   >= TO_DATE( :para_yyyymmdd_from, ''YYYY/MM/DD'') ' 
                    || ' AND     oh.schedule_ship_date   <= TO_DATE( :para_yyyymmdd_to  , ''YYYY/MM/DD'') '
                    || ' AND     p.party_number           = oh.head_sales_branch ' 
                    || ' AND     p.start_date_active     <= oh.schedule_ship_date '
                    || ' AND     p.end_date_active       >= oh.schedule_ship_date '  
                    || ' AND     p.customer_class_code    = :para_base '
                    || ' AND     oh.order_type_id         = tt.transaction_type_id '
                    || ' AND     tt.shipping_shikyu_class = :para_cons_t_deliv '
                    || ' AND     oh.req_status            = :para_cons_status '
                    || ' AND     NVL(oh.notif_status, :para_wzero ) <> :para_cons_notif_status '
                    || ' AND     oh.latest_external_flag  = :para_cons_flg_yes '
                    || ' AND     ol.order_header_id       = oh.order_header_id ' 
                    || ' AND     NVL(ol.delete_flag, :para_flg_no ) <> :para_cons_flg_yes '
                    || ' AND     il.date_from            <= oh.schedule_ship_date '
                    || ' AND    ((il.date_to             >= oh.schedule_ship_date) OR (il.date_to IS NULL)) '
                    || ' AND     tt.start_date_active    <= oh.schedule_ship_date '
                    || ' AND    ((tt.end_date_active     >= oh.schedule_ship_date) OR (tt.end_date_active IS NULL)) '
                    || ' AND     im.start_date_active    <= oh.schedule_ship_date '
                    || ' AND    ((im.end_date_active     >= oh.schedule_ship_date) OR (im.end_date_active IS NULL)) '
                    || ' AND     ol.automanual_reserve_class IS NULL '
                    || ' AND     im.item_id              = ic.item_id '
                    || ' AND     im.item_no              = ol.shipping_item_code '
                    || ' AND     im.lot_ctl              = :para_cons_lot_ctl ' 
                    || ' AND     ic.item_class_code      = :para_cons_item_product ' 
                    || ' AND     ic.prod_class_code      = :para_item_class '
                    || ' AND     im.parent_item_id       = im2.item_id '
                    || ' AND     im2.start_date_active   <= oh.schedule_ship_date '
                    || ' AND    ((im2.end_date_active    >= oh.schedule_ship_date) OR (im2.end_date_active IS NULL)) ';
  --
      -- ***********
      -- SQL文組み立て(出荷変動部分)
      -- ***********
      CASE ln_pattern
        WHEN 1 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND (   ( il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                                  '''' || iv_block2 || '''' || ',' ||
                                                                                  '''' || iv_block3 || '''' || '))'
                                   || '      OR ( oh.deliver_from = ' || in_deliver_from_id || ' ) ) '
                                   || ' AND oh.order_type_id  =  '    || in_deliver_type;
        WHEN 2 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND oh.order_type_id  = '     || in_deliver_type ;
        WHEN 3 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND oh.deliver_from   = '     || in_deliver_from_id
                                   || ' AND oh.order_type_id  = '     || in_deliver_type ;
        WHEN 4 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                            '''' || iv_block2 || '''' || ',' ||
                                                                            '''' || iv_block3 || '''' || ') '
                                   || ' AND oh.order_type_id = '      || in_deliver_type ;
        WHEN 5 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND (   (il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                                 '''' || iv_block2 || '''' || ',' ||
                                                                                 '''' || iv_block3 || '''' || '))'
-- 2009/01/27 D.Nihei Mod Start 本番#332対応
--                                   || '      OR (oh.deliver_from = '  || in_deliver_from_id || ')) ';
                                   || '      OR (oh.deliver_from = '''  || in_deliver_from_id || ''')) ';
-- 2009/01/27 D.Nihei Mod End
        --WHEN 6 は条件追加なし
        WHEN 7 THEN
-- 2009/01/27 D.Nihei Mod Start 本番#332対応
--          lv_fwd_sql := lv_fwd_sql || ' AND oh.deliver_from   = '     || in_deliver_from_id ;
          lv_fwd_sql := lv_fwd_sql || ' AND oh.deliver_from   = '''     || in_deliver_from_id || '''';
-- 2009/01/27 D.Nihei Mod End
        WHEN 8 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                            '''' || iv_block2 || '''' || ',' ||
                                                                            '''' || iv_block3 || '''' || ') ';
        ELSE NULL;
      END CASE;
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
      IF (iv_instruction_dept IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND oh.instruction_dept = '''|| iv_instruction_dept ||'''';
      END IF;
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
      IF (iv_item_code IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND im2.item_no = '''|| iv_item_code ||'''';
      END IF;
-- 2009/05/19 H.Itou Add End
      -- ***********
      -- GROUP BY句(出荷)
      -- ***********
      lv_fwd_sql := lv_fwd_sql || ' GROUP BY im2.item_no ';
    END IF;
    -- 処理種別がNullの場合はUNION句をセット
    IF ( iv_action_type IS NULL ) THEN
     lv_fwd_sql := lv_fwd_sql || ' UNION ALL ';
    END IF;
    -- 処理種別がNullまたは、移動の場合
    IF ( ( iv_action_type IS NULL ) OR ( iv_action_type = gv_action_type_move ) ) THEN
      -- SQL条件パターンチェック
      ln_pattern := check_sql_pattern(gv_cons_biz_t_move,
                                      iv_block1,
                                      iv_block2,
                                      iv_block3,
                                      in_deliver_from_id,
                                      in_deliver_type);
      -- ***********
      -- SQL文組み立て(移動固定部分)
      -- ***********
      lv_fwd_sql  := lv_fwd_sql 
                    || ' SELECT im2.item_no item_no '             -- 品目(コード)
                          || ' , COUNT(1)              cnt '          -- 件数
                    || ' FROM   xxcmn_item_locations2_v       il '  -- OPM保管場所マスタ
                         || ' , xxinv_mov_req_instr_headers   ih '  -- 移動依頼/指示ヘッダアドオン
                         || ' , xxinv_mov_req_instr_lines     ml '  -- 移動依頼/指示明細アドオン
                         || ' , xxcmn_item_mst2_v             im '  -- OPM品目マスタ
                         || ' , xxcmn_item_mst2_v             im2'  -- OPM品目マスタ(親品目取得用)
                         || ' , xxcmn_item_categories5_v      ic '  -- カテゴリ情報VIEW
                    || ' WHERE  il.inventory_location_id = ih.shipped_locat_id '
                    || ' AND    ih.mov_type              = :para_cons_move_type '
                    || ' AND    ih.schedule_ship_date   >= TO_DATE( :para_yyyymmdd_from, ''YYYY/MM/DD'') '
                    || ' AND    ih.schedule_ship_date   <= TO_DATE( :para_yyyymmdd_to  , ''YYYY/MM/DD'') '
                    || ' AND   ((ih.status = :para_cons_mov_sts_c ) OR (ih.status = :para_cons_mov_sts_e )) '
                    || ' AND    NVL(ih.notif_status, :para_wzero ) <> :para_cons_notif_status '
                    || ' AND    ml.mov_hdr_id = ih.mov_hdr_id '
                    || ' AND    NVL(ml.delete_flg, :para_flg_no ) <> :para_cons_flg_yes '
                    || ' AND    il.date_from             <= ih.schedule_ship_date '
                    || ' AND   ((il.date_to              >= ih.schedule_ship_date) OR (il.date_to IS NULL)) '
                    || ' AND    im.start_date_active     <= ih.schedule_ship_date '
                    || ' AND   ((im.end_date_active      >= ih.schedule_ship_date) OR (im.end_date_active IS NULL)) '
                    || ' AND    ml.automanual_reserve_class IS NULL '
                    || ' AND    im.item_no         = ml.item_code '
                    || ' AND    im.item_id         = ic.item_id '
                    || ' AND    im.lot_ctl         = :para_cons_lot_ctl '
                    || ' AND    ic.item_class_code = :para_cons_item_product '
                    || ' AND    ic.prod_class_code = :para_item_class '
                    || ' AND    im.parent_item_id  = im2.item_id '
                    || ' AND    im2.start_date_active     <= ih.schedule_ship_date '
                    || ' AND   ((im2.end_date_active      >= ih.schedule_ship_date) OR (im2.end_date_active IS NULL)) ';
      -- ***********
      -- SQL文組み立て(移動変動部分)
      -- ***********
      CASE ln_pattern
        WHEN 5 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND (   (il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                                 '''' || iv_block2 || '''' || ',' ||
                                                                                 '''' || iv_block3 || '''' || '))'
-- 2009/01/27 D.Nihei Mod Start 本番#332対応
--                                   || '      OR (ih.shipped_locat_id = ' || in_deliver_from_id || ')) ';
                                   || '      OR (ih.shipped_locat_code = ''' || in_deliver_from_id || ''')) ';
-- 2009/01/27 D.Nihei Mod End
        --WHEN 6 は条件追加なし
        WHEN 7 THEN
-- 2009/01/27 D.Nihei Mod Start 本番#332対応
--          lv_fwd_sql := lv_fwd_sql || ' AND ih.shipped_locat_code   = ' || in_deliver_from_id ;
          lv_fwd_sql := lv_fwd_sql || ' AND ih.shipped_locat_code   = ''' || in_deliver_from_id || '''';
-- 2009/01/27 D.Nihei Mod End
        WHEN 8 THEN
          lv_fwd_sql := lv_fwd_sql || ' AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                                            '''' || iv_block2 || '''' || ',' ||
                                                                            '''' || iv_block3 || '''' || ') ';
        ELSE NULL;
      END CASE;
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
      IF (iv_instruction_dept IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND ih.instruction_post_code = '''|| iv_instruction_dept ||'''';
      END IF;
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
      IF (iv_item_code IS NOT NULL) THEN
        lv_fwd_sql := lv_fwd_sql || ' AND im2.item_no = '''|| iv_item_code ||'''';
      END IF;
-- 2009/05/19 H.Itou Add End
      -- ***********
      -- GROUP BY句(移動)
      -- ***********
      lv_fwd_sql := lv_fwd_sql || ' GROUP BY im2.item_no ';
    END IF;
    -- ***********
    -- SQL文組み立て(共通固定部分)
    -- ***********
    lv_fwd_sql  := lv_fwd_sql || ') data ';
    -- ***********
    -- GROUP BY句(共通)
    -- ***********
    lv_fwd_sql := lv_fwd_sql || ' GROUP BY data.item_no ';
    -- ***********
    -- ORDER BY句(共通)
    -- ***********
    lv_fwd_sql := lv_fwd_sql || ' ORDER BY total_cnt desc';
--
    -- 作成したSQL文を返す
    RETURN lv_fwd_sql;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END fwd_sql_create;
--
  /**********************************************************************************
   * Procedure Name   : get_demand_inf_fwd
   * Description      : A-3  品目コード取得
   ***********************************************************************************/
  PROCEDURE get_demand_inf_fwd(
    iv_action_type IN  VARCHAR2            -- 処理種別
-- Ver1.3 M.Hokkanji Start
   ,iv_loop_date   IN  VARCHAR2            -- 対象予定日
-- Ver1.3 M.Hokkanji End
  , iv_fwd_sql     IN  VARCHAR2            -- SQL文
  , ov_errbuf      OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
  , ov_retcode     OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
  , ov_errmsg      OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_demand_inf_fwd'; -- プログラム名
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
    TYPE cursor_type IS REF CURSOR;
    fwd_cur cursor_type;
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
    -- カーソルオープン
    IF ( iv_action_type = gv_action_type_ship) THEN
-- Ver1.3 M.Hokkanji Start
--      OPEN fwd_cur FOR iv_fwd_sql USING gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
      OPEN fwd_cur FOR iv_fwd_sql USING iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_base
                                      , gv_cons_t_deliv
                                      , gv_cons_status
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_cons_flg_yes
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class;
    ELSIF ( iv_action_type = gv_action_type_move) THEN
      OPEN fwd_cur FOR iv_fwd_sql USING
      -- Add Start
                                      gv_cons_move_type
      -- Add End
-- Ver1.3 M.Hokkanji Start
--                                      , gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
                                      , iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_cons_mov_sts_c
                                      , gv_cons_mov_sts_e
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class;
    ELSIF (iv_action_type IS NULL) THEN
-- Ver1.3 M.Hokkanji Start
--      OPEN fwd_cur FOR iv_fwd_sql USING gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
      OPEN fwd_cur FOR iv_fwd_sql USING iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_base
                                      , gv_cons_t_deliv
                                      , gv_cons_status
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_cons_flg_yes
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class
                                      , gv_cons_move_type
-- Ver1.3 M.Hokkanji Start
--                                      , gv_yyyymmdd_from
--                                      , gv_yyyymmdd_to
                                      , iv_loop_date
                                      , iv_loop_date
-- Ver1.3 M.Hokkanji End
                                      , gv_cons_mov_sts_c
                                      , gv_cons_mov_sts_e
                                      , gv_wzero
                                      , gv_cons_notif_status
                                      , gv_flg_no
                                      , gv_cons_flg_yes
                                      , gv_cons_lot_ctl
                                      , gv_cons_item_product
                                      , gt_item_class;
    END IF;
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
-- Ver1.3 M.Hokkanji Start
-- 対象データが存在しない場合は取得されない場合でも処理続行させるためret_codeに違う値を返すように変更
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_req_nodata;
      CLOSE fwd_cur;  -- カーソルクローズ
-- Ver1.3 M.Hokkanji End
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- カーソルクローズ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- カーソルクローズ
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- カーソルクローズ
--
--#####################################  固定部 END   ##########################################
--
  END get_demand_inf_fwd;
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
--
-- ##### 20090119 Ver.1.04 本番#1038対応 START #####
    ln_reqid        NUMBER;           -- 要求ID
    ln_ret          BOOLEAN;
    lv_phase2       VARCHAR2(1000);
    lv_status2      VARCHAR2(1000);
    lv_dev_phase2   VARCHAR2(1000);
    lv_dev_status2  VARCHAR2(1000);
    lv_message2     VARCHAR2(1000);
-- ##### 20090119 Ver.1.04 本番#1038対応 END   #####
--
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 start *----------*
    ln_retrial_cnt  NUMBER;                 -- リトライ回数
    cn_seckill_cnt  CONSTANT NUMBER := 5;   -- リトライ最大回数
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 end   *----------*
--
    -- *** ローカル・カーソル ***
-- ##### 20090119 Ver.1.04 本番#1038対応 START #####
--    CURSOR lock_cur
--    IS
--        SELECT
--            b.id1,
--            a.sid,
--            a.serial#,
--            b.type,
--            DECODE(b.lmode,1,'null', 2,'row share', 3,'row exclusive'
--             ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
--        FROM
--            v$session a,
--            v$lock b
--        WHERE
--            a.sid = b.sid
--            AND (b.id1, b.id2) in 
--                (SELECT d.id1, d.id2 FROM v$lock d 
--                 WHERE d.id1=b.id1
--                 AND d.id2=b.id2 AND d.request > 0) 
--            AND b.id1 IN (SELECT bb.id1
--                         FROM v$session aa, v$lock bb
--                         WHERE aa.lockwait = bb.kaddr 
--                         AND aa.module = 'XXWSH920008C')
--            AND b.lmode = 6;
--
-- ##### 20090218 Ver.1.9 本番#1176対応 START #####
    -- gv$sesson、gv$lockを参照するように修正
--    CURSOR lock_cur
--      IS
--        SELECT b.id1, a.sid, a.serial#, b.type , a.inst_id , a.module , a.action
--              ,decode(b.lmode 
--                     ,1,'null' , 2,'row share', 3,'row exclusive' 
--                     ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
--        FROM gv$session a
--           , gv$lock    b
--        WHERE a.sid = b.sid
--        AND a.module <> 'XXWSH920008C'
--        AND (b.id1, b.id2) in (SELECT d.id1
--                                     ,d.id2
--                               FROM gv$lock d 
--                               WHERE d.id1     =b.id1 
--                               AND   d.id2     =b.id2 
--                               AND   d.request > 0) 
--        AND   b.id1 IN (SELECT bb.id1
--                      FROM   gv$session aa
--                            , gv$lock bb
--                      WHERE  aa.lockwait = bb.kaddr 
--                      AND    aa.module   = 'XXWSH920008C')
--        AND b.lmode = 6;
    -- RAC構成対応SQL
    CURSOR lock_cur
      IS
        SELECT lok.id1            id1
             , lok_sess.inst_id   inst_id
             , lok_sess.sid       sid
             , lok_sess.serial#   serial#
             , lok.type           type
             , lok_sess.module    module
             , lok_sess.action    action
-- ##### 20090219 Ver.1.10 本番#1176対応（追加修正） START #####
             , lok.lmode          lmode
             , lok.request        request
             , lok.ctime          ctime
-- ##### 20090219 Ver.1.10 本番#1176対応（追加修正） END   #####
        FROM   gv$lock    lok
             , gv$session lok_sess
             , gv$lock    req
             , gv$session req_sess
        WHERE lok.inst_id = lok_sess.inst_id
          AND lok.sid     = lok_sess.sid
          AND lok.lmode   = 6
-- ##### 20090219 Ver.1.10 本番#1176対応（追加修正） START #####
          AND (lok.id1, lok.id2) IN (SELECT lok_not.id1, lok_not.id2
                                     FROM   gv$lock   lok_not
                                     WHERE  lok_not.id1 =lok.id1 
                                     AND    lok_not.id2 =lok.id2 
                                     AND    lok_not.request > 0) 
-- ##### 20090219 Ver.1.10 本番#1176対応（追加修正） END   #####
          AND req.inst_id = req_sess.inst_id
          AND req.sid     = req_sess.sid
          AND (   req.inst_id <> lok.inst_id
               OR req.sid     <> lok.sid)
          AND req.id1 = lok.id1
          AND req.id2 = lok.id2
-- 2016/05/11 D.Sugahara Ver1.16' Mod START
-- 運用テストモジュールとして、XXWSH920008C_OTを呼び出すため、ロック待ち確認も_OTに変更する。
---- *----------* 2009/05/01 Ver.1.13 本番障害#1367（1321）子除外対応 start *----------*
--          -- 子コンカレントのロック情報を除外する
--          AND lok_sess.module <> 'XXWSH920008C'
---- *----------* 2009/05/01 Ver.1.13 本番障害#1367（1321）子除外対応 end   *----------*
--          AND req_sess.module = 'XXWSH920008C'; 
---- *----------* 2009/05/01 Ver.1.13 本番障害#1367（1321）子除外対応 start *----------*
          -- 子コンカレントのロック情報を除外する
          AND lok_sess.module <> 'XXWSH920008C_OT'
-- *----------* 2009/05/01 Ver.1.13 本番障害#1367（1321）子除外対応 end   *----------*
          AND req_sess.module = 'XXWSH920008C_OT'; 
-- 2016/05/11 D.Sugahara Ver1.16' Mod End
--
-- ##### 20090218 Ver.1.9 本番#1176対応 END   #####
-- ##### 20090119 Ver.1.04 本番#1038対応 END   #####
--
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 start *----------*
    -- RAC構成対応SQL（SRバージョン）
    CURSOR lockSR_cur
      IS
        SELECT  ing.inst_id       ing_inst_id
              , ing.sid           ing_sid
              , ing.serial#       ing_serial
              , ing.username      ing_username
              , ing.event         ing_event
              , ing.module        ing_module
              , ing.action        ing_action
              , ed.inst_id        ed_inst_id
              , ed.sid            ed_sid
              , ed.serial#        ed_serial
              , ed.username       ed_username
              , ed.event          ed_event
              , ed.module         ed_module
              , ed.action         ed_action
              , ed_sql.sql_text   ed_sql_text
        FROM   gv$session ing       -- ブロックしているセッション
             , gv$session ed        -- ブロックされているセッション
             , gv$sqlarea ed_sql    -- ロック待ちしているSQL
        WHERE ed.blocking_instance  = ing.inst_id
        AND   ed.blocking_session   = ing.sid
        AND   ed.inst_id            = ed_sql.inst_id(+)
        AND   ed.sql_address        = ed_sql.address(+)
-- 2016/05/11 D.Sugahara Ver1.16' Mod START
-- 運用テストモジュールとして、XXWSH920008C_OTを呼び出すため、ロック待ち確認も_OTに変更する。
--        AND   ed.module             = 'XXWSH920008C';
        AND   ed.module             = 'XXWSH920008C_OT';
-- 2016/05/11 D.Sugahara Ver1.16' Mod End
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 end   *----------*
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 start *----------*
    -- セッション切断 確認回数初期化
    ln_retrial_cnt  := 0;
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 end   *----------*
--
  LOOP
-- ##### 20090119 Ver.1.04 本番#1038対応 START #####
--        EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
-- ##### 20090119 Ver.1.04 本番#1038対応 END   #####
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
-- ##### 20090119 Ver.1.04 本番#1038対応 START #####
        EXIT WHEN (lv_phase = 'Y');
-- ##### 20090119 Ver.1.04 本番#1038対応 END   #####
        FOR lock_rec IN lock_cur LOOP
--
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 start *----------*
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** ロック待ち・ロック中 セッション情報 ********** ');
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 end   *----------*
-- ##### 20090119 Ver.1.04 本番#1038対応 START #####
--          lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
--          EXECUTE IMMEDIATE lv_strsql;
--          lv_staus := '1';
--
-- ##### 20090219 Ver.1.10 本番#1176対応（追加修正） START #####
          -- 削除対象セッションログ出力
--          FND_FILE.PUT_LINE(FND_FILE.LOG, '【セッション切断】' || 
--                                          ' 自動仮引当： 要求ID[' || TO_CHAR(in_reqid) || '] ' ||
--                                          ' 切断対象セッション：' ||
--                                          ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
--                                          ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
--                                          ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
--                                          ' action['  || lock_rec.action           || '] ' ||
--                                          ' module['  || lock_rec.module           || '] '
--                                          );
          FND_FILE.PUT_LINE(FND_FILE.LOG, '【セッション切断】' || ' 要求ID[' || TO_CHAR(in_reqid) || '] ' ||
                                          ' 切断対象セッション：' ||
                                          ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
                                          ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
                                          ' serial#[' || TO_CHAR(lock_rec.serial#) || '] ' ||
                                          ' action['  || lock_rec.action           || '] ' ||
                                          ' module['  || lock_rec.module           || '] ' ||
                                          ' lmode['   || TO_CHAR(lock_rec.lmode)   || '] ' ||
                                          ' request[' || TO_CHAR(lock_rec.request) || '] ' ||
                                          ' ctime['   || TO_CHAR(lock_rec.ctime)   || '] '
                                          );
-- ##### 20090219 Ver.1.10 本番#1176対応（追加修正） END   #####
--
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 start *----------*
          -- ロックセッション確認SQL（SRバージョン）のチェック
          FOR lockSR_rec IN lockSR_cur LOOP
--
            -- ロックしているセッションの情報出力
            FND_FILE.PUT_LINE(FND_FILE.LOG, '  〔SR〕ロック待ち要求ID [' || TO_CHAR(in_reqid) || '] ' ||
                                            '     Locked Session：' ||
                                            ' inst_id[' || TO_CHAR(lockSR_rec.ing_inst_id) || '] ' ||
                                            ' sid['     || TO_CHAR(lockSR_rec.ing_sid)     || '] ' ||
                                            ' serial#[' || TO_CHAR(lockSR_rec.ing_serial)  || '] ' ||
                                            ' action['  || lockSR_rec.ing_action           || '] ' ||
                                            ' module['  || lockSR_rec.ing_module           || '] '
                                            );
--
            -- ロック待ちしているSQL出力
            FND_FILE.PUT_LINE(FND_FILE.LOG, '  〔SR〕 Lock Waiting Session SQL <<<<<' || lockSR_rec.ed_sql_text || '>>>>>' );
          END LOOP;
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 end   *----------*
--
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 start *----------*
          -- リトライカウント UP
          ln_retrial_cnt := ln_retrial_cnt + 1;
--
          -- リトライ最大回数分、ロック確認をする
          IF (ln_retrial_cnt <= cn_seckill_cnt) THEN
            -- ロック待ちしているSQL出力
            FND_FILE.PUT_LINE(FND_FILE.LOG, '   CONTINUE Retrial Count:' || TO_CHAR(ln_retrial_cnt) || ' Max Retrial Count:' || TO_CHAR(cn_seckill_cnt) );
            FND_FILE.PUT_LINE(FND_FILE.LOG, '');
--
            -- 次回のロック確認まで、5秒待つ
            DBMS_LOCK.SLEEP(5);
            -- ロック確認SQLをぬける
            EXIT;
          END IF;
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 end   *----------*
--
          -- =====================================
          -- セッション切断コンカレントを起動する
          -- =====================================
          ln_reqid := fnd_request.submit_request(
            Application => 'XXWSH',
            Program     => 'XXWSH000001C',
            Description => NULL,
            Start_Time  => SYSDATE,
            Sub_Request => FALSE,
            Argument1   => lock_rec.inst_id,
            Argument2   => lock_rec.sid    ,
            Argument3   => lock_rec.serial#
            );
          IF (ln_reqid > 0) THEN
            COMMIT;
          ELSE
            ROLLBACK;
            -- 発行に失敗した場合はエラーにしメッセージを出力するように修正
            -- エラーメッセージ取得
            lv_errmsg  := SUBSTRB('XXWSH000001H 起動エラー ' ||
                          ' inst_id[' || TO_CHAR(lock_rec.inst_id) || ']' ||
                          ' sid['     || TO_CHAR(lock_rec.sid)     || ']' ||
                          ' serial['  || TO_CHAR(lock_rec.serial#) || ']' || '<' || FND_MESSAGE.GET || '>'
                          ,1,5000);
            RAISE global_process_expt;
          END IF;
--
          -- ==============================================
          -- 起動したセッション切断コンカレントの終了を待つ
          -- ==============================================
          ln_ret := FND_CONCURRENT.WAIT_FOR_REQUEST(ln_reqid ,
                                                    0.05,
                                                    3600,
                                                    lv_phase2,
                                                    lv_status2,
                                                    lv_dev_phase2,
                                                    lv_dev_status2,
                                                    lv_message2);
          -- ステータス確認
          IF (ln_ret = FALSE) THEN
            -- エラーは無視して、ログのみ出力
            lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                         ' 要求ID['  || TO_CHAR(ln_reqid) || ']' ||
                         ' phase['   || lv_dev_phase2     || ']' ||
                         ' status['  || lv_dev_status2    || ']' ||
                         ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                         , 1 ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
          -- COMPLETE以外での終了
          ELSIF (lv_dev_phase2 <> 'COMPLETE') THEN
            -- エラーは無視して、ログのみ出力
            lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                         ' 要求ID['  || TO_CHAR(ln_reqid) || ']' ||
                         ' phase['   || lv_dev_phase2     || ']' ||
                         ' status['  || lv_dev_status2    || ']' ||
                         ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                         , 1 ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
          -- ステータスがNORMAL以外での終了
          ELSIF (lv_dev_status2 <> 'NORMAL') THEN
            -- エラーは無視して、ログのみ出力
            lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                         ' 要求ID['  || TO_CHAR(ln_reqid) || ']' ||
                         ' phase['   || lv_dev_phase2     || ']' ||
                         ' status['  || lv_dev_status2    || ']' ||
                         ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                         , 1 ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
          END IF;
--
-- ##### 20090119 Ver.1.04 本番#1038対応 END   #####
--
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 start *----------*
          -- セッション切断後、リトライ回数を初期化
          ln_retrial_cnt  := 0;
-- *----------* 2009/04/17 Ver.1.12 本番障害#1367（1321）リトライ対応 end   *----------*
--
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 start *----------*
          -- セッション切断の為、2秒待つ
          DBMS_LOCK.SLEEP(2);
-- *----------* 2009/04/03 Ver.1.11 本番障害#1367（1321）調査用対応 end   *----------*
--
        END LOOP;
--
-- ##### 20090119 Ver.1.04 本番#1038対応 START #####
    -- 確認後0.05秒待機する
    DBMS_LOCK.SLEEP(0.05);
-- ##### 20090119 Ver.1.04 本番#1038対応 END   #####
--
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
     iv_item_class         IN     VARCHAR2     -- 商品区分
   , iv_action_type        IN     VARCHAR2     -- 処理種別
   , iv_block1             IN     VARCHAR2     -- ブロック１
   , iv_block2             IN     VARCHAR2     -- ブロック２
   , iv_block3             IN     VARCHAR2     -- ブロック３
   , in_deliver_from_id    IN     NUMBER       -- 出庫元
   , in_deliver_type       IN     NUMBER       -- 出庫形態
   , iv_deliver_date_from  IN     VARCHAR2     -- 出庫日From
   , iv_deliver_date_to    IN     VARCHAR2     -- 出庫日To
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
   , iv_instruction_dept   IN     VARCHAR2     -- 指示部署
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
   , iv_item_code          IN     VARCHAR2     -- 品目コード
-- 2009/05/19 H.Itou Add End
   , ov_errbuf             OUT  NOCOPY   VARCHAR2     -- エラー・メッセージ           --# 固定 #
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
    lv_fwd_sql       VARCHAR2(5000);   -- 出荷用SQL文格納バッファ
    lv_mov_sql       VARCHAR2(5000);   -- 移動用SQL文格納バッファ
--
    ln_d_cnt         NUMBER := 0;      -- 需要情報ループカウンタ
    ln_s_cnt         NUMBER := 0;      -- 供給情報ループカウンタ
    ln_k_cnt         NUMBER := 0;
    ln_s_max         NUMBER := 0;
    ln_i_cnt         NUMBER := 0;      -- 需要情報合体用カウンタ
--
    lv_phase         VARCHAR2(100);
    lv_status        VARCHAR2(100);
    lv_dev_phase     VARCHAR2(100);
    lv_dev_status    VARCHAR2(100);
    lv_lot_biz_class VARCHAR2(1);      -- ロット逆転処理種別
    ln_result        NUMBER;           -- 処理結果(0:正常、1:異常)
    ld_standard_date DATE;             -- 基準日付
-- Ver1.3 M.Hokkanji Start
    ld_loop_date     DATE;             -- 処理対象日
    ln_loop_cnt      NUMBER := 0;      -- ループカウント
-- Ver1.3 M.Hokkanji End
-- Ver1.15 M.Hokkanji Start
    lv_child_pgm         VARCHAR2(20);     --子PGM名 ex)'XXWSH920008C'
-- 2016/05/11 D.Sugahara Ver1.16' Mod START
-- 運用テストモジュールとして、XXWSH920008C_OTを呼び出すように変更する。
--    cv_child_pgm_origin  CONSTANT VARCHAR2(20) := 'XXWSH920008C';     --子PGM名 自動引当（品目）通常
    cv_child_pgm_origin  CONSTANT VARCHAR2(20) := 'XXWSH920008C_OT';     --子PGM名 自動引当（品目）_OT
-- 2016/05/11 D.Sugahara Ver1.16' Mod End
    cv_child_pgm_trace   CONSTANT VARCHAR2(20) := 'XXWSH920008C_2';   --子PGM名 自動引当（品目）Trace用
-- Ver1.15 M.Hokkanji End
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
    gt_item_class := iv_item_class;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- A-1  入力パラメータチェック check_parameter
    -- ===============================================
    check_parameter(iv_item_class         -- 入力パラメータ商品区分
                  , iv_deliver_date_from  -- 入力パラメータ出庫日From
                  , iv_deliver_date_to    -- 入力パラメータ出庫日To
                  , lv_errbuf             -- エラー・メッセージ           --# 固定 #
                  , lv_retcode            -- リターン・コード             --# 固定 #
                  , lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理
    IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2  SQL作成
    -- ===============================================
    lv_fwd_sql := fwd_sql_create(iv_action_type     -- 処理種別
                               , iv_block1          -- ブロック１
                               , iv_block2          -- ブロック２
                               , iv_block3          -- ブロック３
                               , in_deliver_from_id -- 出庫元
                               , in_deliver_type    -- 出庫形態
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
                               , iv_instruction_dept   -- 指示部署
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
                               , iv_item_code       -- 品目コード
-- 2009/05/19 H.Itou Add End
                                 );
-- Ver1.3 M.Hokkanji Start
    ld_loop_date := TO_DATE(iv_deliver_date_from,'YYYY/MM/DD');
    gr_data_cnt_tbl.delete;
    ln_loop_cnt := 0;
    <<ship_date_loop>>
    LOOP
      -- 日付ごとに配列と対象件数を初期化
      gr_demand_tbl.delete;
      gn_total_cnt := 0;
      ln_loop_cnt := ln_loop_cnt + 1;
      gr_data_cnt_tbl(ln_loop_cnt).ship_date := TO_CHAR(ld_loop_date,'YYYY/MM/DD');
      gr_data_cnt_tbl(ln_loop_cnt).error_cnt := 0;
      gr_data_cnt_tbl(ln_loop_cnt).warn_cnt  := 0;
      gr_data_cnt_tbl(ln_loop_cnt).nomal_cnt := 0;
      i := 0;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'****************出荷予定日：' || TO_CHAR(ld_loop_date,'YYYY/MM/DD') || '*****************');
-- Ver1.3 M.Hokkanji End
      -- ===============================================
      -- A-3  品目コード取得
      -- ===============================================
      get_demand_inf_fwd(iv_action_type -- 処理種別
-- Ver1.3 M.Hokkanji Start
                       , TO_CHAR(ld_loop_date,'YYYY/MM/DD')
-- Ver1.3 M.Hokkanji End
                       , lv_fwd_sql     -- SQL文
                       , lv_errbuf      -- エラー・メッセージ           --# 固定 #
                       , lv_retcode     -- リターン・コード             --# 固定 #
                       , lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラー処理
-- Ver1.3 M.Hokkanji Start
      IF ( lv_retcode = gv_req_nodata) THEN
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'出荷予定日：' || TO_CHAR(ld_loop_date,'YYYY/MM/DD') || '処理対象データ無し');
        gn_total_cnt := 0;
      ELSIF ( lv_retcode = gv_status_error ) THEN
--      IF ( lv_retcode = gv_status_error ) THEN
-- Ver1.3 M.Hokkanji End
          gn_error_cnt := 1;
          RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- A-4  品目コードループ
      -- ===============================================
      <<demand_inf_loop>>
      FOR ln_d_cnt IN 1..gn_total_cnt LOOP
        i := i + 1;
        gn_target_cnt := gn_target_cnt + 1;
-- Ver1.15 M.Hokkanji Start
--トレース取得対応 品目が'0005000'０９Ｐお～い５００の場合はTrace用コンカレントを呼び出す
-- Ver1.16 M.Hokkanji Start
--        IF gr_demand_tbl(ln_d_cnt).item_code != '0005000' THEN
--          lv_child_pgm := cv_child_pgm_origin ; --09P500以外の場合、通常
--        ELSE
--         lv_child_pgm := cv_child_pgm_trace  ; --Trace用
--        END IF;
          lv_child_pgm := cv_child_pgm_origin ; --09P500以外の場合、通常
-- Ver1.16 M.Hokkanji End
-- Ver1.15 M.Hokkanji End
        reqid_rec(i) := FND_REQUEST.SUBMIT_REQUEST(
                           application       => 'XXWSH'                           -- アプリケーション短縮名
-- Ver1.15 M.Hokkanji Start
--                         , program           => 'XXWSH920008C'                    -- プログラム名
                         , program           => lv_child_pgm                    -- プログラム名
-- Ver1.15 M.Hokkanji End
                         , argument1         => iv_item_class                     -- 商品区分
                         , argument2         => iv_action_type                    -- 処理種別
                         , argument3         => iv_block1                         -- ブロック１
                         , argument4         => iv_block2                         -- ブロック２
                         , argument5         => iv_block3                         -- ブロック３
                         , argument6         => in_deliver_from_id                -- 出庫元
                         , argument7         => in_deliver_type                   -- 出庫形態
-- Ver1.3 M.hokkanji Start
                         , argument8         => TO_CHAR(ld_loop_date,'YYYY/MM/DD') -- 出庫日From
                         , argument9         => TO_CHAR(ld_loop_date,'YYYY/MM/DD') -- 出庫日To
--                         , argument8         => iv_deliver_date_from              -- 出庫日From
--                         , argument9         => iv_deliver_date_to                -- 出庫日To
-- Ver1.3 M.hokkanji End
                         , argument10        => gr_demand_tbl(ln_d_cnt).item_code -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
                         , argument11        => iv_instruction_dept               -- 指示部署
-- 2009/01/28 H.Itou Add End
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
-- Ver1.3 M.hokkanji Start
         -- エラー処理
--         IF ( lv_retcode = gv_status_error ) THEN
--             gn_error_cnt := 1;
--             RAISE global_process_expt;
--         END IF;
-- Ver1.3 M.hokkanji End
--
      END LOOP demand_inf_loop; -- 品目コードループ終わり
--
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
              FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'親品目:' || gr_demand_tbl(j).item_code || '、件数:' || TO_CHAR(gr_demand_tbl(j).total_cnt) || '件、要求ID：' || TO_CHAR(reqid_rec(j)) || '、処理結果：' || gv_msg_part || gv_mst_error);
              gn_error_cnt := gn_error_cnt + 1;
-- Ver1.3 M.Hokkanji Start
              gr_data_cnt_tbl(ln_loop_cnt).error_cnt := gr_data_cnt_tbl(ln_loop_cnt).error_cnt + 1;
-- Ver1.3 M.Hokkanji End
            -- ステータス:警告
            ELSIF ( lv_dev_status = cv_conc_s_w ) THEN
              IF ( ov_retcode < 1 ) THEN
                ov_retcode := gv_status_warn;
              END IF;
              FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'親品目:' || gr_demand_tbl(j).item_code || '、件数:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '件、要求ID：' || TO_CHAR(reqid_rec(j)) || '、処理結果：' || gv_msg_part || gv_mst_warn);
              gn_warn_cnt := gn_warn_cnt + 1;
-- Ver1.3 M.Hokkanji Start
              gr_data_cnt_tbl(ln_loop_cnt).warn_cnt := gr_data_cnt_tbl(ln_loop_cnt).warn_cnt + 1;
-- Ver1.3 M.Hokkanji End
            -- ステータス:正常
            ELSE
              FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'親品目:' || gr_demand_tbl(j).item_code || '、件数:'  || TO_CHAR(gr_demand_tbl(j).total_cnt) || '件、要求ID：' || TO_CHAR(reqid_rec(j)) || '、処理結果：' || gv_msg_part || gv_mst_normal);
              gn_normal_cnt := gn_normal_cnt + 1;
-- Ver1.3 M.Hokkanji Start
              gr_data_cnt_tbl(ln_loop_cnt).nomal_cnt := gr_data_cnt_tbl(ln_loop_cnt).nomal_cnt + 1;
-- Ver1.3 M.Hokkanji End
            END IF;
          END IF;
        ELSE
          ov_retcode := gv_status_error;
          FND_FILE.PUT_LINE (FND_FILE.OUTPUT,TO_CHAR(reqid_rec(j)) || gv_msg_part || gv_mst_error);
          gn_error_cnt := gn_error_cnt + 1;
        END IF;
--
      END LOOP chk_status;
-- Ver1.3 M.Hokkanji Start
      -- エラーが発生した場合その日で終了
      IF (gn_error_cnt > 0) THEN
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'出庫予定日:' || TO_CHAR(ld_loop_date,'YYYY/MM/DD') || 'の引当処理でエラーが発生したため処理を中断します。');
        EXIT;
      END IF;
      -- 処理対象日付が出荷日TO以上の場合ループ終了
      EXIT WHEN (ld_loop_date >= TO_DATE(iv_deliver_date_to,'YYYY/MM/DD'));
      -- ループ終了しない場合は処理対象日付+1
      ld_loop_date := ld_loop_date + 1;
    END LOOP ship_date_loop;
    -- 日付ごとの情報を出力
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'****************     日付ごとの処理結果     *****************');
    <<msg_info_loop>>
    FOR m IN 1 .. gr_data_cnt_tbl.count LOOP
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'出庫予定日:' || gr_data_cnt_tbl(m).ship_date
                                      || '、正常  件数：' || TO_CHAR(gr_data_cnt_tbl(m).nomal_cnt)
                                      || '、警告  件数：' || TO_CHAR(gr_data_cnt_tbl(m).warn_cnt)
                                      || '、エラー件数：' || TO_CHAR(gr_data_cnt_tbl(m).error_cnt));
    END LOOP msg_info_loop;
-- Ver1.3 M.Hokkanji End
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
    retcode               OUT NOCOPY   VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_item_class         IN           VARCHAR2,      -- 商品区分
    iv_action_type        IN           VARCHAR2,      -- 処理種別
    iv_block1             IN           VARCHAR2,      -- ブロック１
    iv_block2             IN           VARCHAR2,      -- ブロック２
    iv_block3             IN           VARCHAR2,      -- ブロック３
    iv_deliver_from_id    IN           VARCHAR2,      -- 出庫元
    iv_deliver_type       IN           VARCHAR2,      -- 出庫形態
    iv_deliver_date_from  IN           VARCHAR2,      -- 出庫日From
    iv_deliver_date_to    IN           VARCHAR2,      -- 出庫日To
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
    iv_instruction_dept   IN           VARCHAR2       -- 指示部署
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
   ,iv_item_code          IN           VARCHAR2       -- 品目コード
-- 2009/05/19 H.Itou Add End
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
    ln_deliver_from_id := TO_NUMBER(iv_deliver_from_id);
    lv_retcode         := gv_cons_flg_no;
    ln_deliver_type    := TO_NUMBER(iv_deliver_type);
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
    -- 入力パラメータ「商品区分」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02851', gv_tkn_item, iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「処理種別」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02852', 'AC_TYPE'  , iv_action_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック1」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02853', 'IN_BLOCK1', iv_block1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック2」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02854', 'IN_BLOCK2', iv_block2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック3」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02855', 'IN_BLOCK3', iv_block3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫元」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02856', 'FROM_ID'  , iv_deliver_from_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫形態」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02857', 'TYPE'     , iv_deliver_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫日From」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02858', 'D_FROM'   , iv_deliver_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫日To」出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh, 'APP-XXWSH-02859', 'D_TO'     , iv_deliver_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
    -- 入力パラメータ「指示部署」出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'指示部署：'|| iv_instruction_dept);
    -- 入力パラメータ「品目コード」出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'品目コード：'|| iv_item_code);
-- 2009/05/19 H.Itou Add End
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
      iv_item_class,        -- 商品区分
      iv_action_type,       -- 処理種別
      iv_block1,            -- ブロック１
      iv_block2,            -- ブロック２
      iv_block3,            -- ブロック３
      ln_deliver_from_id,   -- 出庫元
      ln_deliver_type,      -- 出庫形態
      iv_deliver_date_from, -- 出庫日From
      iv_deliver_date_to,   -- 出庫日To
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
      iv_instruction_dept,  -- 指示部署
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
      iv_item_code,         -- 品目
-- 2009/05/19 H.Itou Add End
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
    WHEN INVALID_NUMBER THEN
      -- メッセージのセット
      -- 出荷元に不正データあり
      IF (lv_retcode = gv_cons_flg_yes) THEN
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_92a_009      -- パラメータ書式エラー
                                                      ,gv_tkn_parameter    -- トークン'PARAMETER'
                                                      ,gv_cons_deliv_fm    -- '出荷元'
                                                      ,gv_tkn_type         -- トークン'TYPE'
                                                      ,gv_cons_number)     -- '数値'
                                                      ,1
                                                      ,5000);
      -- 出荷形態に不正データあり
      ELSE
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_92a_009      -- パラメータ書式エラー
                                                      ,gv_tkn_parameter    -- トークン'PARAMETER'
                                                      ,gv_cons_deliv_tp    -- '出荷形態'
                                                      ,gv_tkn_type         -- トークン'TYPE'
                                                      ,gv_cons_number)     -- '数値'
                                                      ,1
                                                      ,5000);
      END IF;
      errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      retcode := gv_status_error;                                            --# 任意 #
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
END XXWSH920007C_OT;
/
