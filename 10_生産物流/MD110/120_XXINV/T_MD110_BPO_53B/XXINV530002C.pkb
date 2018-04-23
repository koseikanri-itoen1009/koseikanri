CREATE OR REPLACE PACKAGE BODY xxinv530002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv530002c(body)
 * Description      : HHT棚卸データIFプログラム
 * MD.050/070       : 棚卸Issue1.0(T_MD050_BPO_530)
 *                  : 棚卸Issue1.0(T_MD050_BPO_53B)
 * Version          : 1.8
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  fnc_check_num               数値チェックします。
 *  proc_del_table_data_batch   データ削除処理(B-6)
 *  proc_ins_table_batch        一括登録処理(B-5)
 *  proc_upd_table_batch        一括更新処理(B-4)
 *  fnc_get_data_dump           データダンプを作成します。
 *  proc_put_dump_msg           データダンプ一括出力処理(B-4)
 *  proc_check                  妥当性チェック(B-3)
 *  get_ins_data                対象データ取得(B-2)
 *  proc_del_table_data         データパージ処理(B-1)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/03    1.0   T.Endou          新規作成
 *  2008/05/02    1.1   M.Inamine        修正(【BPO_530_棚卸】修正依頼事項 No2の対応)
 *                      M.Inamine        修正(MD.050_530の不具合について２.txtの対応)
 *  2008/05/07    1.2   T.Endou          修正(MD.050_530の不具合について４.txtの対応)
 *                      T.Endou          修正(MD.050_530の不具合について５.txtの対応)
 *  2008/05/08    1.3   T.Endou          修正(ロット管理しない場合はNULL)
 *  2008/05/09    1.4   M.Inamine        修正(2008/05/08 03 不具合対応：日付書式の誤り)
 *  2008/12/06    1.5   T.Miyata         修正(本番障害#510対応：日付は変換して比較)
 *  2009/02/09    1.6   A.Shiina         修正(本番障害#1117対応：在庫クローズチェック追加)
 *  2009/02/09    1.7   A.Shiina         修正(本番障害#1129対応：パラメータ追加)
 *  2018/03/30    1.8   Y.Sekine         E_本稼動_14953対応
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  global_user_expt       EXCEPTION;        -- ユーザーにて定義をした例外
  lock_expt              EXCEPTION;        -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxinv530002c'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn                CONSTANT VARCHAR2(100) := 'XXCMN';
  gv_xxinv                CONSTANT VARCHAR2(100) := 'XXINV';
  -- YES/NO
  gv_y                    CONSTANT VARCHAR2(1) := 'Y';
  gv_n                    CONSTANT VARCHAR2(1) := 'N';
  -- YES/NO
  gn_y                    CONSTANT NUMBER := 1;
  gn_n                    CONSTANT NUMBER := 0;
--
  gn_ret_nomal            CONSTANT NUMBER := 0; -- 正常
  gn_ret_error            CONSTANT NUMBER := 1; -- エラー
--
  -- WHO列情報
  gn_user_id              CONSTANT NUMBER := FND_GLOBAL.USER_ID;
  gd_sysdate              CONSTANT DATE   := SYSDATE;
  gn_last_update_login    CONSTANT NUMBER := FND_GLOBAL.LOGIN_ID;
  gn_request_id           CONSTANT NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
  gn_program_appl_id      CONSTANT NUMBER := FND_GLOBAL.PROG_APPL_ID;
  gn_program_id           CONSTANT NUMBER := FND_GLOBAL.CONC_PROGRAM_ID;
--
  -- 商品区分
  gv_goods_classe_reaf    CONSTANT VARCHAR2(1)  := '1';   -- 商品区分：1(リーフ)
  gv_goods_classe_drink   CONSTANT VARCHAR2(1)  := '2';   -- 商品区分：2(ドリンク)
  -- 製品区分
  gv_item_class_products  CONSTANT VARCHAR2(1)  := '5';   -- 品目区分：5(製品)
--
  gv_date                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';--2008/05/02
  gv_blank                CONSTANT VARCHAR2(2)  := '　';
  gn_zero                 CONSTANT NUMBER       := 0;
  gn_one                  CONSTANT NUMBER       := 1;
  gv_zero                 CONSTANT VARCHAR2(1) := '0';
--
  gv_profile_name         CONSTANT VARCHAR2(16) := '棚卸削除対象日付';
  gv_inv_hht_name         CONSTANT VARCHAR2(21) := 'HHT棚卸ワークテーブル';
  gv_inv_result_name      CONSTANT VARCHAR2(21) := '棚卸結果テーブル';
  gv_opm_item_name        CONSTANT VARCHAR2(21) := 'OPM品目マスタ';
  gv_opm_lot_name         CONSTANT VARCHAR2(21) := 'OPMロットマスタ';
  gv_invent_whse_name     CONSTANT VARCHAR2(21) := 'OPM倉庫マスタ';
  gv_report_post_name     CONSTANT VARCHAR2(21) := '事業所マスタ';
--
  gv_item_col             CONSTANT VARCHAR2(4)  := '品目';
  gv_inv_whse_code_col    CONSTANT VARCHAR2(8)  := '棚卸倉庫';
  gv_report_post_code_col CONSTANT VARCHAR2(8)  := '報告部署';
  gv_lot_no_col           CONSTANT VARCHAR2(8)  := 'ロットNo';
  gv_maker_date_col       CONSTANT VARCHAR2(8)  := '製造日';
  gv_limit_date_col       CONSTANT VARCHAR2(8)  := '賞味期限';
  gv_proper_mark_col      CONSTANT VARCHAR2(8)  := '固有記号';
  gv_case_amt_col         CONSTANT VARCHAR2(10) := '棚卸ケース';
  gv_content_col          CONSTANT VARCHAR2(4)  := '入数';
  gv_loose_amt_col        CONSTANT VARCHAR2(8)  := '棚卸バラ';
--
-- 2008/12/06 T.Miyata Add Start
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
-- 2008/12/06 T.Miyata Add End
--
-- 2009/02/09 v1.7 ADD START
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_inv_whse_section_col CONSTANT VARCHAR2(20) := '倉庫管理部署';
  gv_inv_whse_code        CONSTANT VARCHAR2(20) := '倉庫コード';
  gv_item_typ             CONSTANT VARCHAR2(10) := '品目区分';
--
-- 2009/02/09 v1.7 ADD END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- HHT棚卸ワークレコード
  TYPE gtbl_hht_work IS RECORD (
    invent_hht_if_id   xxinv_stc_inventory_hht_work.invent_hht_if_id%TYPE
   ,report_post_code   xxinv_stc_inventory_hht_work.report_post_code%TYPE
   ,invent_date        xxinv_stc_inventory_hht_work.invent_date%TYPE
   ,invent_whse_code   xxinv_stc_inventory_hht_work.invent_whse_code%TYPE
   ,invent_seq         xxinv_stc_inventory_hht_work.invent_seq%TYPE
   ,item_code          xxinv_stc_inventory_hht_work.item_code%TYPE
   ,lot_no             xxinv_stc_inventory_hht_work.lot_no%TYPE
   ,maker_date         xxinv_stc_inventory_hht_work.maker_date%TYPE
   ,limit_date         xxinv_stc_inventory_hht_work.limit_date%TYPE
   ,proper_mark        xxinv_stc_inventory_hht_work.proper_mark%TYPE
   ,case_amt           xxinv_stc_inventory_hht_work.case_amt%TYPE
   ,content            xxinv_stc_inventory_hht_work.content%TYPE
   ,loose_amt          xxinv_stc_inventory_hht_work.loose_amt%TYPE
   ,location           xxinv_stc_inventory_hht_work.location%TYPE
   ,rack_no1           xxinv_stc_inventory_hht_work.rack_no1%TYPE
   ,rack_no2           xxinv_stc_inventory_hht_work.rack_no2%TYPE
   ,rack_no3           xxinv_stc_inventory_hht_work.rack_no3%TYPE
   ,b_invent_seq       xxinv_stc_inventory_hht_work.invent_seq%TYPE  -- 製品重複チェック用
   ,c_invent_seq       xxinv_stc_inventory_hht_work.invent_seq%TYPE  -- 製品以外重複チェック用
   ,rowid_work         ROWID
   ,err_msg            VARCHAR2(5000)                                -- エラーメッセージ
   ,b3_item_id         xxcmn_item_mst_v.item_id%TYPE                 -- b3_品目ID
   ,b3_lot_ctl         xxcmn_item_mst_v.lot_ctl%TYPE                 -- b3_ロット管理区分
   ,b3_num_of_cases    xxcmn_item_mst_v.num_of_cases%TYPE            -- b3_ケース入数
   ,b3_item_class_code xxcmn_item_categories4_v.item_class_code%TYPE -- b3_品目区分
   ,b3_prod_class_code xxcmn_item_categories4_v.prod_class_code%TYPE -- b3_商品区分
   ,b3_lot_id          NUMBER                                        -- b3_ロットID
   ,b3_lot_no          xxinv_stc_inventory_hht_work.lot_no%TYPE      -- b3_ロットNO
   ,b3_maker_date      VARCHAR2(240)                                 -- b3_製造年月日
   ,b3_proper_mark     VARCHAR2(240)                                 -- b3_固有記号
   ,b3_limit_date      VARCHAR2(240));                               -- b3_賞味期限
  --
  TYPE gtbl_hht_work_type IS TABLE OF gtbl_hht_work INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gtbl_data       gtbl_hht_work_type; -- 元データ
  gtbl_normal     gtbl_hht_work_type; -- 正常データ
  gtbl_error      gtbl_hht_work_type; -- エラーデータ
  gtbl_reserve    gtbl_hht_work_type; -- 保留データ
  gtbl_normal_ins gtbl_hht_work_type; -- 正常データ挿入
--
  CURSOR gcur_xxinv_stc_inv_hht_work
  IS
    SELECT xsihw.ROWID
    FROM   xxinv_stc_inventory_hht_work xsihw
    FOR UPDATE NOWAIT;
--
-- 2008/12/07 T.MIYATA ADD START #510
--
  /**********************************************************************************
   * Function Name    : fnc_check_date
   * Description      : 日付チェックを行います。
   ***********************************************************************************/
  FUNCTION fnc_check_date(
    iv_date IN VARCHAR2
    ) RETURN VARCHAR2
  IS
  BEGIN
--
    RETURN to_char(to_date(iv_date, gc_char_d_format), gc_char_d_format);
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN null;
  END fnc_check_date;
--
-- 2008/12/07 T.MIYATA ADD END #510
--
  /**********************************************************************************
   * Function Name    : fnc_check_num
   * Description      : 数値チェックします。
   ***********************************************************************************/
  FUNCTION fnc_check_num(
    iv_check_num IN VARCHAR2,
    iv_format    IN VARCHAR2
    ) RETURN BOOLEAN
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_check_num'; -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    ln_num NUMBER;
--
  BEGIN
--
    ln_num := TO_NUMBER(iv_check_num,iv_format);
    RETURN(TRUE);
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN(FALSE);
  END fnc_check_num;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_table_data_batch
   * Description      : データ削除処理(B-6)
   ***********************************************************************************/
  PROCEDURE proc_del_table_data_batch(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_table_data_batch'; -- プログラム名
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
    ln_count_err NUMBER DEFAULT 0;
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ROWID PL/SQL表型
    TYPE ltbl_hht_work_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    ltbl_hht_work_rowid ltbl_hht_work_rowid_type;
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
    ltbl_hht_work_rowid.DELETE; -- 初期化
    -- 正常データROWID
    <<normal_loop>>
    FOR ln_count IN 1..gtbl_normal.COUNT LOOP
      ltbl_hht_work_rowid(ln_count) := gtbl_normal(ln_count).rowid_work;
      ln_count_err := ln_count;
    END LOOP normal_loop;
--
    -- エラーデータROWID
    <<error_loop>>
    FOR ln_count IN 1..gtbl_error.COUNT LOOP
      ln_count_err := ln_count_err + 1;
      ltbl_hht_work_rowid(ln_count_err) := gtbl_error(ln_count).rowid_work;
    END LOOP error_loop;
--
    -- ===============================
    -- HHT棚卸ワークテーブル削除
    -- ===============================
    FORALL ln_count IN 1..ltbl_hht_work_rowid.COUNT
      DELETE xxinv_stc_inventory_hht_work xsihw
      WHERE  ROWID = ltbl_hht_work_rowid(ln_count);
--
    -- ロック取得カーソルCLOSE
    CLOSE gcur_xxinv_stc_inv_hht_work;
--
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
  END proc_del_table_data_batch;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_table_batch
   * Description      : 一括登録処理(B-5)
   ***********************************************************************************/
  PROCEDURE proc_ins_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_table_batch'; -- プログラム名
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
    ln_val     NUMBER;  -- 棚卸結果IDの連番
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    -- 棚卸結果テーブルタイプ
    TYPE ltbl_xsir_type IS TABLE OF xxinv_stc_inventory_result%ROWTYPE INDEX BY BINARY_INTEGER;
    ltbl_xsir ltbl_xsir_type;
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
    -- ===============================
    -- 一括登録処理
    -- ===============================
    <<normal_ins_loop>>
    FOR ln_cnt_loop IN 1 .. gtbl_normal_ins.COUNT LOOP
      -- 棚卸結果IDの連番取得
      SELECT xxinv_stc_invt_rslt_s1.NEXTVAL
      INTO   ln_val
      FROM   dual;
      -- 棚卸結果ID
      ltbl_xsir(ln_cnt_loop).invent_result_id := ln_val;
      -- 報告部署
      ltbl_xsir(ln_cnt_loop).report_post_code := gtbl_normal_ins(ln_cnt_loop).report_post_code;
      -- 棚卸日
      ltbl_xsir(ln_cnt_loop).invent_date      := gtbl_normal_ins(ln_cnt_loop).invent_date;
      -- 棚卸倉庫
      ltbl_xsir(ln_cnt_loop).invent_whse_code := gtbl_normal_ins(ln_cnt_loop).invent_whse_code;
      -- 棚卸連番
      ltbl_xsir(ln_cnt_loop).invent_seq       := gtbl_normal_ins(ln_cnt_loop).invent_seq;
      -- 品目ID
      ltbl_xsir(ln_cnt_loop).item_id          := gtbl_normal_ins(ln_cnt_loop).b3_item_id;
      -- 品目
      ltbl_xsir(ln_cnt_loop).item_code        := gtbl_normal_ins(ln_cnt_loop).item_code;
      -- ロットID
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- 製品
          ltbl_xsir(ln_cnt_loop).lot_id := gtbl_normal_ins(ln_cnt_loop).b3_lot_id;
        ELSE
          -- 製品以外
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ロット管理
              ltbl_xsir(ln_cnt_loop).lot_id := gtbl_normal_ins(ln_cnt_loop).b3_lot_id;
            ELSE
              -- ロット管理対象外
              ltbl_xsir(ln_cnt_loop).lot_id := NULL;
          END CASE;
      END CASE;
      -- ロットNo
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- 製品
          ltbl_xsir(ln_cnt_loop).lot_no := gtbl_normal_ins(ln_cnt_loop).b3_lot_no;
        ELSE
          -- 製品以外
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ロット管理
              ltbl_xsir(ln_cnt_loop).lot_no := gtbl_normal_ins(ln_cnt_loop).lot_no;
            ELSE
              -- ロット管理対象外
              ltbl_xsir(ln_cnt_loop).lot_no := NULL;
          END CASE;
      END CASE;
      -- 製造日
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- 製品
          ltbl_xsir(ln_cnt_loop).maker_date := gtbl_normal_ins(ln_cnt_loop).maker_date;
        ELSE
          -- 製品以外
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ロット管理
              ltbl_xsir(ln_cnt_loop).maker_date := gtbl_normal_ins(ln_cnt_loop).b3_maker_date;
            ELSE
              -- ロット管理対象外
              ltbl_xsir(ln_cnt_loop).maker_date := NULL;
           END CASE;
      END CASE;
      -- 賞味期限
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- 製品
          ltbl_xsir(ln_cnt_loop).limit_date := gtbl_normal_ins(ln_cnt_loop).limit_date;
        ELSE
          -- 製品以外
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ロット管理
              ltbl_xsir(ln_cnt_loop).limit_date := gtbl_normal_ins(ln_cnt_loop).b3_limit_date;
            ELSE
              -- ロット管理対象外
              ltbl_xsir(ln_cnt_loop).limit_date := NULL;
          END CASE;
      END CASE;
      -- 固有記号
      CASE (gtbl_normal_ins(ln_cnt_loop).b3_item_class_code)
        WHEN (gv_item_class_products) THEN
          -- 製品
          ltbl_xsir(ln_cnt_loop).proper_mark := gtbl_normal_ins(ln_cnt_loop).proper_mark;
        ELSE
          -- 製品以外
          CASE (gtbl_normal_ins(ln_cnt_loop).b3_lot_ctl)
            WHEN (gn_y) THEN
              -- ロット管理
              ltbl_xsir(ln_cnt_loop).proper_mark := gtbl_normal_ins(ln_cnt_loop).b3_proper_mark;
            ELSE
              -- ロット管理対象外
              ltbl_xsir(ln_cnt_loop).proper_mark := NULL;
          END CASE;
      END CASE;
      -- 棚卸ケース数
      ltbl_xsir(ln_cnt_loop).case_amt         := gtbl_normal_ins(ln_cnt_loop).case_amt;
      -- 入数
      ltbl_xsir(ln_cnt_loop).content          := gtbl_normal_ins(ln_cnt_loop).content;
      -- 棚卸バラ
      ltbl_xsir(ln_cnt_loop).loose_amt        := gtbl_normal_ins(ln_cnt_loop).loose_amt;
      -- ロケーション
      ltbl_xsir(ln_cnt_loop).location         := gtbl_normal_ins(ln_cnt_loop).location;
      -- ラックNo１
      ltbl_xsir(ln_cnt_loop).rack_no1         := gtbl_normal_ins(ln_cnt_loop).rack_no1;
      -- ラックNo２
      ltbl_xsir(ln_cnt_loop).rack_no2         := gtbl_normal_ins(ln_cnt_loop).rack_no2;
      -- ラックNo３
      ltbl_xsir(ln_cnt_loop).rack_no3         := gtbl_normal_ins(ln_cnt_loop).rack_no3;
-- 2008/12/06 T.Miyata Add Start 本番障害#510 日付書式を合わせるため、一度TO_DATEする。
        -- 製造日
        IF (ltbl_xsir(ln_cnt_loop).maker_date <> '0') THEN
          ltbl_xsir(ln_cnt_loop).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_cnt_loop).maker_date, gc_char_d_format), gc_char_d_format);
        END IF;
--
        -- 賞味期限
        IF (ltbl_xsir(ln_cnt_loop).limit_date <> '0') THEN
          ltbl_xsir(ln_cnt_loop).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_cnt_loop).limit_date, gc_char_d_format), gc_char_d_format);
        END IF;
-- 2008/12/06 T.Miyata Add End
      -- WHO情報
      ltbl_xsir(ln_cnt_loop).created_by             := gn_user_id;
      ltbl_xsir(ln_cnt_loop).creation_date          := gd_sysdate;
      ltbl_xsir(ln_cnt_loop).last_updated_by        := gn_user_id;
      ltbl_xsir(ln_cnt_loop).last_update_date       := gd_sysdate;
      ltbl_xsir(ln_cnt_loop).last_update_login      := gn_user_id;
      ltbl_xsir(ln_cnt_loop).request_id             := gn_request_id;
      ltbl_xsir(ln_cnt_loop).program_application_id := gn_program_appl_id;
      ltbl_xsir(ln_cnt_loop).program_id             := gn_program_id;
      ltbl_xsir(ln_cnt_loop).program_update_date    := gd_sysdate;
    END LOOP normal_ins_loop;
--
    -- ===============================
    -- 棚卸結果テーブル一括更新
    -- ===============================
    FORALL ln_cnt_loop in 1..ltbl_xsir.COUNT
      INSERT INTO xxinv_stc_inventory_result VALUES ltbl_xsir(ln_cnt_loop);
--
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
  END proc_ins_table_batch;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_table_batch
   * Description      : 一括更新処理(B-4)
   ***********************************************************************************/
  PROCEDURE proc_upd_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_table_batch'; -- プログラム名
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
    ln_upd_cnt    NUMBER DEFAULT 0; -- 更新件数カウント
    ln_ins_cnt    NUMBER DEFAULT 0; -- 挿入件数カウント
    lr_rowid      ROWID;
--
    -- *** ローカル・カーソル ***
    -- 棚卸結果テーブル(品目区分が製品)
    CURSOR lcur_xxinv_stc_inv_res_pt(
      itbl_hht_work gtbl_hht_work)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
      WHERE  xsir.invent_seq       = itbl_hht_work.invent_seq       -- 棚卸連番
      AND    xsir.invent_whse_code = itbl_hht_work.invent_whse_code -- 棚卸倉庫
      AND    xsir.report_post_code = itbl_hht_work.report_post_code -- 報告部署
      AND    xsir.item_code        = itbl_hht_work.item_code        -- 品目
      AND    xsir.invent_date      = itbl_hht_work.invent_date      -- 棚卸日
-- 2008/12/06 T.Miyata Add Start
--      AND    xsir.maker_date       = itbl_hht_work.maker_date       -- 製造日
--      AND    xsir.limit_date       = itbl_hht_work.limit_date       -- 賞味期限
      AND    fnc_check_date(xsir.maker_date) = fnc_check_date(itbl_hht_work.maker_date) -- 製造日
--test      AND    fnc_check_date(xsir.limit_date) = fnc_check_date(itbl_hht_work.limit_date)  -- 賞味期限
-- 2008/12/06 T.Miyata Add End
      AND    xsir.proper_mark      = itbl_hht_work.proper_mark      -- 固有記号
      FOR UPDATE NOWAIT;
--
    -- 棚卸結果テーブル(品目区分が製品以外 かつ ロット管理対象)
    CURSOR lcur_xxinv_stc_inv_res_npt_lot(
      itbl_hht_work gtbl_hht_work)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
      WHERE  xsir.invent_seq       = itbl_hht_work.invent_seq       -- 棚卸連番
      AND    xsir.invent_whse_code = itbl_hht_work.invent_whse_code -- 棚卸倉庫
      AND    xsir.report_post_code = itbl_hht_work.report_post_code -- 報告部署
      AND    xsir.item_code        = itbl_hht_work.item_code        -- 品目
      AND    xsir.invent_date      = itbl_hht_work.invent_date      -- 棚卸日
      AND    xsir.lot_id           = itbl_hht_work.b3_lot_id        -- ロットID
      FOR UPDATE NOWAIT;
--
    -- 棚卸結果テーブル(品目区分が製品以外 かつ ロット管理対象外)
    CURSOR lcur_xxinv_stc_inv_res_npt(
      itbl_hht_work gtbl_hht_work)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
      WHERE  xsir.invent_seq       = itbl_hht_work.invent_seq       -- 棚卸連番
      AND    xsir.invent_whse_code = itbl_hht_work.invent_whse_code -- 棚卸倉庫
      AND    xsir.report_post_code = itbl_hht_work.report_post_code -- 報告部署
      AND    xsir.item_code        = itbl_hht_work.item_code        -- 品目
      AND    xsir.invent_date      = itbl_hht_work.invent_date      -- 棚卸日
      FOR UPDATE NOWAIT;
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
    -- ===============================
    -- １件ごと更新処理 ※ロックが１件単位でしか出来ないため、FORALLは使えません。
    -- ===============================
    <<upd_table_batch_loop>>
    FOR ln_cnt_loop IN 1 .. gtbl_normal.COUNT LOOP
--
      lr_rowid := NULL;
-- 2008/12/06 T.Miyata Add Start 本番障害#510 日付書式を合わせるため、一度TO_DATEする。
      -- 製造日
      IF (gtbl_normal(ln_cnt_loop).maker_date <> '0') THEN
        gtbl_normal(ln_cnt_loop).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(gtbl_normal(ln_cnt_loop).maker_date, gc_char_d_format), gc_char_d_format);
      END IF;
--
      -- 賞味期限
      IF (gtbl_normal(ln_cnt_loop).limit_date <> '0') THEN
        gtbl_normal(ln_cnt_loop).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(gtbl_normal(ln_cnt_loop).limit_date, gc_char_d_format), gc_char_d_format);
      END IF;
-- 2008/12/06 T.Miyata Add End
      BEGIN
        IF (gtbl_normal(ln_cnt_loop).b3_item_class_code = gv_item_class_products) THEN
          -- 品目区分が製品
          OPEN  lcur_xxinv_stc_inv_res_pt(
            gtbl_normal(ln_cnt_loop));        -- ロック取得カーソルOPEN
--
          FETCH lcur_xxinv_stc_inv_res_pt INTO lr_rowid;
--
          IF (lcur_xxinv_stc_inv_res_pt%NOTFOUND) THEN
            ln_ins_cnt := gtbl_normal_ins.COUNT + 1;
            gtbl_normal_ins(ln_ins_cnt) := gtbl_normal(ln_cnt_loop); -- 正常データ挿入
          ELSE
            ln_upd_cnt := ln_upd_cnt + 1;
            UPDATE xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
            SET    xsir.case_amt               = gtbl_normal(ln_cnt_loop).case_amt  -- 棚卸ケース数
                  ,xsir.content                = gtbl_normal(ln_cnt_loop).content   -- 入数
                  ,xsir.loose_amt              = gtbl_normal(ln_cnt_loop).loose_amt -- 棚卸バラ
                  ,xsir.location               = gtbl_normal(ln_cnt_loop).location  -- ロケーション
                  ,xsir.rack_no1               = gtbl_normal(ln_cnt_loop).rack_no1  -- ラックNo１
                  ,xsir.rack_no2               = gtbl_normal(ln_cnt_loop).rack_no2  -- ラックNo２
                  ,xsir.rack_no3               = gtbl_normal(ln_cnt_loop).rack_no3  -- ラックNo３
                   -- WHOカラム
                  ,xsir.last_updated_by        = gn_user_id
                  ,xsir.last_update_date       = gd_sysdate
                  ,xsir.last_update_login      = gn_user_id
                  ,xsir.request_id             = gn_request_id
                  ,xsir.program_application_id = gn_program_appl_id
                  ,xsir.program_id             = gn_program_id
                  ,xsir.program_update_date    = gd_sysdate
            WHERE  xsir.ROWID = lr_rowid;
          END IF;
--
          CLOSE lcur_xxinv_stc_inv_res_pt; -- ロック取得カーソルCLOSE
--
        ELSE
          -- 品目区分が製品以外
          IF (gtbl_normal(ln_cnt_loop).b3_lot_ctl = gn_y) THEN
            -- ロット管理対象
            OPEN  lcur_xxinv_stc_inv_res_npt_lot(
              gtbl_normal(ln_cnt_loop));        -- ロック取得カーソルOPEN
--
            FETCH lcur_xxinv_stc_inv_res_npt_lot INTO lr_rowid;
--
            IF (lcur_xxinv_stc_inv_res_npt_lot%NOTFOUND) THEN
              ln_ins_cnt := gtbl_normal_ins.COUNT + 1;
              gtbl_normal_ins(ln_ins_cnt) := gtbl_normal(ln_cnt_loop); -- 正常データ挿入
            ELSE
              ln_upd_cnt := ln_upd_cnt + 1;
              UPDATE xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
              SET
                 xsir.case_amt               = gtbl_normal(ln_cnt_loop).case_amt  -- 棚卸ケース数
                ,xsir.content                = gtbl_normal(ln_cnt_loop).content   -- 入数
                ,xsir.loose_amt              = gtbl_normal(ln_cnt_loop).loose_amt -- 棚卸バラ
                ,xsir.location               = gtbl_normal(ln_cnt_loop).location  -- ロケーション
                ,xsir.rack_no1               = gtbl_normal(ln_cnt_loop).rack_no1  -- ラックNo１
                ,xsir.rack_no2               = gtbl_normal(ln_cnt_loop).rack_no2  -- ラックNo２
                ,xsir.rack_no3               = gtbl_normal(ln_cnt_loop).rack_no3  -- ラックNo３
                 -- WHOカラム
                ,xsir.last_updated_by        = gn_user_id
                ,xsir.last_update_date       = gd_sysdate
                ,xsir.last_update_login      = gn_user_id
                ,xsir.request_id             = gn_request_id
                ,xsir.program_application_id = gn_program_appl_id
                ,xsir.program_id             = gn_program_id
                ,xsir.program_update_date    = gd_sysdate
              WHERE xsir.ROWID = lr_rowid;
            END IF;
--
            CLOSE lcur_xxinv_stc_inv_res_npt_lot; -- ロック取得カーソルCLOSE
--
          ELSE
            -- ロット管理対象外
            OPEN  lcur_xxinv_stc_inv_res_npt(
              gtbl_normal(ln_cnt_loop));        -- ロック取得カーソルOPEN
--
            FETCH lcur_xxinv_stc_inv_res_npt INTO lr_rowid;
--
            IF (lcur_xxinv_stc_inv_res_npt%NOTFOUND) THEN
              ln_ins_cnt := gtbl_normal_ins.COUNT + 1;
              gtbl_normal_ins(ln_ins_cnt) := gtbl_normal(ln_cnt_loop); -- 正常データ挿入
            ELSE
              ln_upd_cnt := ln_upd_cnt + 1;
              UPDATE xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
              SET
                 xsir.case_amt               = gtbl_normal(ln_cnt_loop).case_amt  -- 棚卸ケース数
                ,xsir.content                = gtbl_normal(ln_cnt_loop).content   -- 入数
                ,xsir.loose_amt              = gtbl_normal(ln_cnt_loop).loose_amt -- 棚卸バラ
                ,xsir.location               = gtbl_normal(ln_cnt_loop).location  -- ロケーション
                ,xsir.rack_no1               = gtbl_normal(ln_cnt_loop).rack_no1  -- ラックNo１
                ,xsir.rack_no2               = gtbl_normal(ln_cnt_loop).rack_no2  -- ラックNo２
                ,xsir.rack_no3               = gtbl_normal(ln_cnt_loop).rack_no3  -- ラックNo３
                 -- WHOカラム
                ,xsir.last_updated_by        = gn_user_id
                ,xsir.last_update_date       = gd_sysdate
                ,xsir.last_update_login      = gn_user_id
                ,xsir.request_id             = gn_request_id
                ,xsir.program_application_id = gn_program_appl_id
                ,xsir.program_id             = gn_program_id
                ,xsir.program_update_date    = gd_sysdate
              WHERE xsir.ROWID = lr_rowid;
            END IF;
--
            CLOSE lcur_xxinv_stc_inv_res_npt; -- ロック取得カーソルCLOSE
--
          END IF;
--
        END IF;
--
      EXCEPTION
        WHEN lock_expt THEN --*** ロック取得エラー ***
          -- カーソルをCLOSE(製品)
          IF (lcur_xxinv_stc_inv_res_pt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_res_pt;
          END IF;
          -- カーソルをCLOSE(製品以外 ロット対象)
          IF (lcur_xxinv_stc_inv_res_npt_lot%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_res_npt_lot;
          END IF;
          -- カーソルをCLOSE(製品以外 ロット対象外)
          IF (lcur_xxinv_stc_inv_res_npt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_res_npt;
          END IF;
          -- エラーメッセージ取得
          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                         gv_xxcmn
                        ,'APP-XXCMN-10019'
                        ,'TABLE'
                        ,gv_inv_result_name
                        ),1,5000);
          RAISE global_user_expt;
      END;
--
    END LOOP upd_table_batch_loop;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_upd_table_batch;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_data_dump
   * Description      : データダンプを作成します。
   ***********************************************************************************/
  FUNCTION fnc_get_data_dump(
    itbl__hht_work IN gtbl_hht_work -- データダンプ元レコード
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_data_dump'; -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_dump VARCHAR2(2000);
--
  BEGIN
--
    -- ===============================
    -- データダンプ作成
    -- ===============================
    lv_dump :=
      itbl__hht_work.invent_hht_if_id || gv_msg_comma || -- HHT棚卸IF_ID
      itbl__hht_work.report_post_code || gv_msg_comma || -- 報告部署
      itbl__hht_work.invent_date      || gv_msg_comma || -- 棚卸日
      itbl__hht_work.invent_whse_code || gv_msg_comma || -- 棚卸倉庫
      itbl__hht_work.invent_seq       || gv_msg_comma || -- 棚卸連番
      itbl__hht_work.item_code        || gv_msg_comma || -- 品目
      itbl__hht_work.lot_no           || gv_msg_comma || -- ロットNo.
      itbl__hht_work.maker_date       || gv_msg_comma || -- 製造日
      itbl__hht_work.limit_date       || gv_msg_comma || -- 賞味期限
      itbl__hht_work.proper_mark      || gv_msg_comma || -- 固有記号
      itbl__hht_work.case_amt         || gv_msg_comma || -- 棚卸ケース数
      itbl__hht_work.content          || gv_msg_comma || -- 入数
      itbl__hht_work.loose_amt        || gv_msg_comma || -- 棚卸バラ
      itbl__hht_work.location         || gv_msg_comma || -- ロケーション
      itbl__hht_work.rack_no1         || gv_msg_comma || -- ラックNo１
      itbl__hht_work.rack_no2         || gv_msg_comma || -- ラックNo２
      itbl__hht_work.rack_no3;                           -- ラックNo３
--
    RETURN(lv_dump) ;
--
  END fnc_get_data_dump;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_dump_msg
   * Description      : データダンプ一括出力処理(B-4)
   ***********************************************************************************/
  PROCEDURE proc_put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_dump_msg'; -- プログラム名
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
    lv_msg  VARCHAR2(5000);  -- メッセージ
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
    -- ===============================
    -- データダンプ一括出力
    -- ===============================
    IF ((gtbl_error.COUNT > 0)
      OR (gtbl_reserve.COUNT > 0)) THEN
--
      --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
      -- エラーデータ（見出し）
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                   gv_xxcmn
                  ,'APP-XXCMN-00006'
                  ),1,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
      -- エラーデータダンプ
      <<error_dump_loop>>
      FOR ln_cnt_loop IN 1 .. gtbl_error.COUNT LOOP
        -- ダンプ出力
        lv_msg := fnc_get_data_dump(gtbl_error(ln_cnt_loop));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
        -- エラーメッセージ出力
        lv_msg := gtbl_error(ln_cnt_loop).err_msg;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
      END LOOP error_dump_loop;
--
      -- 保留データダンプ
      <<reserve_dump_loop>>
      FOR ln_cnt_loop IN 1 .. gtbl_reserve.COUNT LOOP
        -- ダンプ出力
        lv_msg := fnc_get_data_dump(gtbl_reserve(ln_cnt_loop));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
        -- エラーメッセージ出力
        lv_msg := gtbl_reserve(ln_cnt_loop).err_msg;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
      END LOOP reserve_dump_loop;
--
    END IF;
--
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
  END proc_put_dump_msg;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_check
   * Description      : 妥当性チェック(B-3)
   ***********************************************************************************/
  PROCEDURE proc_check(
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check'; -- プログラム名
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
    cv_case_amt_format CONSTANT VARCHAR2(10) := '999999999D';  -- 棚卸ケース数、数値フォーマット
--
    -- *** ローカル変数 ***
--
    ln_item_id         xxcmn_item_mst_v.item_id%TYPE;                 -- 品目ID
    ln_lot_ctl         xxcmn_item_mst_v.lot_ctl%TYPE;                 -- ロット管理区分
    lv_num_of_cases    xxcmn_item_mst_v.num_of_cases%TYPE;            -- ケース入数
    lv_item_class_code xxcmn_item_categories4_v.item_class_code%TYPE; -- 品目区分
    lv_prod_class_code xxcmn_item_categories4_v.prod_class_code%TYPE; -- 商品区分
    ln_lot_id          NUMBER;        -- ロットID
    ln_lot_no          NUMBER;        -- ロットNO
    lv_maker_date      VARCHAR2(240); -- 製造年月日
    lv_proper_mark     VARCHAR2(240); -- 固有記号
    lv_limit_date      VARCHAR2(240); -- 賞味期限
    lv_errbuf_work     VARCHAR2(5000);
--
    lb_err_flag        BOOLEAN DEFAULT FALSE; -- エラーフラグ
    lb_warn_flag       BOOLEAN DEFAULT FALSE; -- 保留フラグ
--
    ln_normal_cnt      NUMBER DEFAULT 0;
    ln_error_cnt       NUMBER DEFAULT 0;
    ln_reserve_cnt     NUMBER DEFAULT 0;
--
    ln_whse_cnt        NUMBER DEFAULT 0;
    ln_location_cnt    NUMBER DEFAULT 0;
    ln_ret             NUMBER DEFAULT 0;
    --2008/05/02
    ld_maker_date      DATE  DEFAULT NULL;--製造日チェック用
    ld_limit_date      DATE  DEFAULT NULL;--賞味期限チェック用
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
--
    <<check_loop>>
    FOR ln_cnt_loop IN 1..gtbl_data.COUNT LOOP
      -- 初期化
      ln_lot_id      := NULL;  -- ロットID
      ln_lot_no      := NULL;  -- ロットNO
      lv_maker_date  := NULL;  -- 製造年月日
      lv_proper_mark := NULL;  -- 固有記号
      lv_limit_date  := NULL;  -- 賞味期限
      lb_err_flag    := FALSE; -- エラーフラグ
      lb_warn_flag   := FALSE; -- 保留フラグ
      -- ==============================================================
      -- 品目マスタチェック
      -- ==============================================================
      BEGIN
        SELECT
          ximv.item_id          AS item_id         -- 品目ID
         ,ximv.lot_ctl          AS lot_ctl         -- ロット管理区分
         ,ximv.num_of_cases     AS num_of_cases    -- ケース入数
         ,xic4v.item_class_code AS item_class_code -- 品目区分
         ,xic4v.prod_class_code AS prod_class_code -- 商品区分
        INTO
          ln_item_id
         ,ln_lot_ctl
         ,lv_num_of_cases
         ,lv_item_class_code
         ,lv_prod_class_code
        FROM   xxcmn_item_mst_v         ximv
              ,xxcmn_item_categories4_v xic4v
        WHERE  ximv.item_no  = gtbl_data(ln_cnt_loop).item_code
        AND    xic4v.item_id = ximv.item_id;
      EXCEPTION
        -- データがない場合は警告(エラー)
        WHEN NO_DATA_FOUND THEN
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10102',
                              iv_token_name1  => 'TABLE',
                              iv_token_value1 => gv_opm_item_name,
                              iv_token_name2  => 'OBJECT',
                              iv_token_value2 =>
                                gv_item_col || gv_msg_part || gtbl_data(ln_cnt_loop).item_code);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
          lb_err_flag := TRUE;
      END;
      -- 取得項目を保持します。
      gtbl_data(ln_cnt_loop).b3_item_id         := ln_item_id;         -- b3_品目ID
      gtbl_data(ln_cnt_loop).b3_lot_ctl         := ln_lot_ctl;         -- b3_ロット管理区分
      gtbl_data(ln_cnt_loop).b3_num_of_cases    := lv_num_of_cases;    -- b3_ケース入数
      gtbl_data(ln_cnt_loop).b3_item_class_code := lv_item_class_code; -- b3_品目区分
      gtbl_data(ln_cnt_loop).b3_prod_class_code := lv_prod_class_code; -- b3_商品区分
--
      -- ==============================================================
      -- 重複チェック
      -- ==============================================================
      IF (lv_item_class_code = gv_item_class_products) THEN
        -- 品目区分が製品
        IF (gtbl_data(ln_cnt_loop).b_invent_seq IS NOT NULL) THEN
          -- 棚卸連番・棚卸倉庫・報告部署・品目・製造日・賞味期限・固有記号で重複有り(エラー)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10101');
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
          lb_err_flag := TRUE;
        END IF;
      ELSE
        -- 品目区分が製品以外
        IF (gtbl_data(ln_cnt_loop).c_invent_seq IS NOT NULL) THEN
          -- 棚卸連番・棚卸倉庫・報告部署・品目・ロットNo・棚卸日で重複有り(エラー)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10101');
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
          lb_err_flag := TRUE;
        END IF;
      END IF;
  --
      -- ==============================================================
      -- 棚卸倉庫マスタチェック
      -- ==============================================================
      SELECT COUNT(xilv.whse_code) AS whse_cnt
      INTO ln_whse_cnt
      FROM xxcmn_item_locations_v xilv
      WHERE xilv.whse_code = gtbl_data(ln_cnt_loop).invent_whse_code;
--
      IF (ln_whse_cnt = 0) THEN
        -- 未登録の場合エラー(エラー)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10102',
                            iv_token_name1  => 'TABLE',
                            iv_token_value1 => gv_invent_whse_name,
                            iv_token_name2  => 'OBJECT',
                            iv_token_value2 => gv_inv_whse_code_col
                              || gv_msg_part || gtbl_data(ln_cnt_loop).invent_whse_code);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- 報告部署マスタチェック
      -- ==============================================================
      SELECT COUNT(xlv.location_code) AS location_cnt
      INTO ln_location_cnt
      FROM xxcmn_locations_v xlv
      WHERE xlv.location_code = gtbl_data(ln_cnt_loop).report_post_code;
--
      IF (ln_location_cnt = 0) THEN
        -- 未登録の場合エラー(エラー)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10102',
                            iv_token_name1  => 'TABLE',
                            iv_token_value1 => gv_report_post_name,
                            iv_token_name2  => 'OBJECT',
                            iv_token_value2 => gv_report_post_code_col
                              || gv_msg_part || gtbl_data(ln_cnt_loop).report_post_code);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- ロットNoマスタチェック
      -- ==============================================================
      IF (lv_item_class_code != gv_item_class_products) THEN
        -- 品目区分が製品以外
        IF (ln_lot_ctl = gn_y) THEN
          -- ロット管理対象
          IF (gtbl_data(ln_cnt_loop).lot_no = 0) THEN
            -- 0の場合エラー(エラー)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_lot_no_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          -- --------------------------------------------------------------
          -- OPMロットマスタ存在チェック
          -- --------------------------------------------------------------
          BEGIN
            SELECT
              ilm.lot_id     AS lot_id     -- ロットID
             ,ilm.attribute1 AS attribute1 -- 製造年月日
             ,ilm.attribute2 AS attribute2 -- 固有記号
             ,ilm.attribute3 AS attribute3 -- 賞味期限
            INTO
              ln_lot_id
             ,lv_maker_date
             ,lv_proper_mark
             ,lv_limit_date
            FROM   ic_lots_mst ilm
            WHERE  ilm.lot_no  = gtbl_data(ln_cnt_loop).lot_no
            AND    ilm.item_id = ln_item_id
            AND    ROWNUM      = 1;
          EXCEPTION
            -- データがない場合は警告(保留)
            WHEN NO_DATA_FOUND THEN
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10108',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_lot_no_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).lot_no ||
                                    gv_msg_comma ||
                                    gv_item_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).item_code);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
              lb_warn_flag := TRUE;
          END;
          -- 取得項目を保持します。
          gtbl_data(ln_cnt_loop).b3_lot_id      := NVL(ln_lot_id,gn_zero); -- b3_ロットID
          gtbl_data(ln_cnt_loop).b3_maker_date  := lv_maker_date;  -- b3_製造年月日
          gtbl_data(ln_cnt_loop).b3_proper_mark := lv_proper_mark; -- b3_固有記号
          gtbl_data(ln_cnt_loop).b3_limit_date  := lv_limit_date;  -- b3_賞味期限
        ELSE
          -- ロット管理対象外
          IF (gtbl_data(ln_cnt_loop).lot_no != 0) THEN
            -- 0以外の場合エラー(エラー)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10103',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_lot_no_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
        END IF;
      END IF;
--
      -- ==============================================================
      -- 製造日、賞味期限、固有記号
      -- ==============================================================
      IF (lv_item_class_code = gv_item_class_products) THEN
        -- 品目区分が製品
        IF (lv_prod_class_code = gv_goods_classe_drink) THEN
          -- 商品区分がドリンク
          -- a
          IF (gtbl_data(ln_cnt_loop).maker_date = gv_zero) THEN
            -- 製造日、0の場合エラー
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_maker_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          IF (gtbl_data(ln_cnt_loop).limit_date = gv_zero) THEN
            -- 賞味期限、0の場合エラー
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_limit_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          IF (gtbl_data(ln_cnt_loop).proper_mark = gv_zero) THEN
            -- 固有記号、0の場合エラー
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_proper_mark_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          -- 製造日の日付形式チェック(yyyy/mm/dd)
          ld_maker_date :=  FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).maker_date, gv_date);
          IF  (ld_maker_date IS NULL) THEN
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10105',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_maker_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
           -- 賞味期限の日付形式チェック(yyyy/mm/dd)
          ld_limit_date :=  FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).limit_date, gv_date);
          IF  (ld_limit_date IS NULL) THEN
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10105',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_limit_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          -- c
          -- --------------------------------------------------------------
          -- OPMロットマスタ存在チェック
          -- --------------------------------------------------------------
          BEGIN
            SELECT
              ilm.lot_id     AS lot_id     -- ロットID
             ,ilm.lot_no     AS lot_no     -- ロットNO
             ,ilm.attribute3 AS attribute3 -- 賞味期限
            INTO
              ln_lot_id
             ,ln_lot_no
             ,lv_limit_date
            FROM   ic_lots_mst ilm
            WHERE  ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gv_date) || ''--製造日2008/05/02
            AND    ilm.attribute2 = gtbl_data(ln_cnt_loop).proper_mark
            AND    ilm.item_id    = ln_item_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- OPMロットマスタに未登録(保留)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10108',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_maker_date_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).maker_date ||
                                    gv_msg_comma ||
                                    gv_proper_mark_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).proper_mark);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
              lb_warn_flag := TRUE;
            WHEN TOO_MANY_ROWS THEN
              -- OPMロットマスタに複数登録(保留)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10109',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_maker_date_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).maker_date ||
                                    gv_msg_comma ||
                                    gv_proper_mark_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).proper_mark);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
              lb_warn_flag := TRUE;
          END;
          -- 取得項目を保持します。
          gtbl_data(ln_cnt_loop).b3_lot_id      := NVL(ln_lot_id,gn_zero); -- b3_ロットID
          gtbl_data(ln_cnt_loop).b3_lot_no      := ln_lot_no;              -- b3_ロットNO
          gtbl_data(ln_cnt_loop).b3_limit_date  := lv_limit_date;          -- b3_賞味期限
--
          -- 賞味期限の一致チェック
          IF (lv_limit_date IS NOT NULL) THEN
            IF (FND_DATE.STRING_TO_DATE(lv_limit_date, gv_date) != ld_limit_date) THEN
              -- 賞味期限の不一致(保留)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10110',
                                  iv_token_name1  => 'OBEJCT',
                                  iv_token_value1 => gv_limit_date_col,
                                  iv_token_name2  => 'CONTENT',
                                  iv_token_value2 => gv_limit_date_col ||
                                    gv_msg_part || lv_limit_date);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
              lb_warn_flag := TRUE;
            END IF;
          END IF;
        ELSE
          -- 商品区分：リーフ
          -- a
          IF (gtbl_data(ln_cnt_loop).limit_date = gv_zero) THEN
            -- 賞味期限、0の場合エラー(エラー)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_limit_date_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          IF (gtbl_data(ln_cnt_loop).proper_mark = gv_zero) THEN
            -- 固有記号、0の場合エラー(エラー)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10104',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_proper_mark_col);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          -- b
          -- 賞味期限の日付形式チェック(yyyy/mm/dd)
          ld_limit_date :=  FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).limit_date, gv_date);
          IF  (ld_limit_date IS NULL) THEN
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxcmn,
                                iv_name         => 'APP-XXCMN-10012',
                                iv_token_name1  => 'ITEM',
                                iv_token_value1 => gv_limit_date_col,
                                iv_token_name2  => 'VALUE',
                                iv_token_value2 => gtbl_data(ln_cnt_loop).limit_date);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
          -- 製造日の日付形式変換(yyyy/mm/dd)
          ld_maker_date := FND_DATE.STRING_TO_DATE(gtbl_data(ln_cnt_loop).maker_date, gv_date);
          -- c
          -- --------------------------------------------------------------
          -- OPMロットマスタ存在チェック
          -- --------------------------------------------------------------
          BEGIN
            SELECT
              ilm.lot_id     AS lot_id     -- ロットID
             ,ilm.lot_no     AS lot_no     -- ロットNO
             ,ilm.attribute3 AS attribute3 -- 賞味期限
            INTO
              ln_lot_id
             ,ln_lot_no
             ,lv_limit_date
            FROM   ic_lots_mst ilm
            WHERE  ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gv_date) || ''--製造日2008/05/02
            AND    ilm.attribute2 = gtbl_data(ln_cnt_loop).proper_mark
            AND    ilm.item_id    = ln_item_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- --------------------------------------------------------------
              -- OPMロットマスタ存在チェック
              -- --------------------------------------------------------------
              BEGIN
                SELECT
                  ilm.lot_id     AS lot_id     -- ロットID
                 ,ilm.lot_no     AS lot_no     -- ロットNO
                 ,ilm.attribute1 AS attribute1 -- 製造年月日
                INTO
                  ln_lot_id
                 ,ln_lot_no
                 ,lv_maker_date
                FROM   ic_lots_mst ilm
                WHERE  ilm.attribute2 = gtbl_data(ln_cnt_loop).proper_mark
                AND    ilm.attribute3 = ''
                                     || TO_CHAR(ld_limit_date, gv_date) || ''--賞味期限2008/05/02
                AND    ilm.item_id    = ln_item_id;
-- 2009/01/08 H.Sakuma Add Start 本番障害#692 賞味期限・固有記号でロットマスタに存在している場合、マスタの製造年月日を設定
              gtbl_data(ln_cnt_loop).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(lv_maker_date, gc_char_d_format), gc_char_d_format);
-- 2009/01/08 H.Sakuma Add End   本番障害#692 賞味期限・固有記号でロットマスタに存在している場合、マスタの製造年月日を設定
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- OPMロットマスタに未登録(保留)
                  lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                      iv_application  => gv_xxinv,
                                      iv_name         => 'APP-XXINV-10108',
                                      iv_token_name1  => 'OBJECT',
                                      iv_token_value1 =>
                                        gv_proper_mark_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).proper_mark ||
                                        gv_msg_comma ||
                                        gv_limit_date_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).limit_date);
                  ln_reserve_cnt := gtbl_reserve.COUNT + 1;
                  gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
                  gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
                  lb_warn_flag := TRUE;
                WHEN TOO_MANY_ROWS THEN
                  -- OPMロットマスタに複数登録(保留)
                  lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                      iv_application  => gv_xxinv,
                                      iv_name         => 'APP-XXINV-10109',
                                      iv_token_name1  => 'OBJECT',
                                      iv_token_value1 =>
                                        gv_proper_mark_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).proper_mark ||
                                        gv_msg_comma ||
                                        gv_limit_date_col ||
                                        gv_msg_part || gtbl_data(ln_cnt_loop).limit_date);
                  ln_reserve_cnt := gtbl_reserve.COUNT + 1;
                  gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
                  gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
                  lb_warn_flag := TRUE;
              END;
--
            WHEN TOO_MANY_ROWS THEN
              -- OPMロットマスタに複数登録(保留)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10109',
                                  iv_token_name1  => 'OBJECT',
                                  iv_token_value1 =>
                                    gv_maker_date_col || gv_msg_part ||
                                    gtbl_data(ln_cnt_loop).maker_date ||
                                    gv_msg_comma ||
                                    gv_proper_mark_col ||
                                    gv_msg_part || gtbl_data(ln_cnt_loop).proper_mark);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
              lb_warn_flag := TRUE;
          END;
          -- 取得項目を保持します。
          gtbl_data(ln_cnt_loop).b3_lot_id     := NVL(ln_lot_id,gn_zero); -- b3_ロットID
          gtbl_data(ln_cnt_loop).b3_lot_no     := ln_lot_no;     -- b3_ロットNO
          gtbl_data(ln_cnt_loop).b3_limit_date := lv_limit_date; -- b3_賞味期限
          -- 賞味期限の一致チェック
          IF (lv_limit_date IS NOT NULL) THEN
            IF (FND_DATE.STRING_TO_DATE(lv_limit_date, gv_date) != ld_limit_date) THEN
              -- 賞味期限の不一致(保留)
              lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                  iv_application  => gv_xxinv,
                                  iv_name         => 'APP-XXINV-10110',
                                  iv_token_name1  => 'OBEJCT',
                                  iv_token_value1 => gv_limit_date_col,
                                  iv_token_name2  => 'CONTENT',
                                  iv_token_value2 => gv_limit_date_col ||
                                    gv_msg_part || lv_limit_date);
              ln_reserve_cnt := gtbl_reserve.COUNT + 1;
              gtbl_reserve(ln_reserve_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
              gtbl_reserve(ln_reserve_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
              lb_warn_flag := TRUE;
            END IF;
          END IF;
        END IF;
--
      ELSE
        -- 品目区分が製品以外
        IF (gtbl_data(ln_cnt_loop).maker_date != gv_zero) THEN
          -- 製造日、0以外の場合エラー(エラー)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_maker_date_col);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
          lb_err_flag := TRUE;
        END IF;
        IF (gtbl_data(ln_cnt_loop).limit_date != gv_zero) THEN
          -- 消費期限、0以外の場合エラー(エラー)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
          lb_err_flag := TRUE;
        END IF;
        IF (gtbl_data(ln_cnt_loop).proper_mark != gv_zero) THEN
          -- 固有記号、0以外の場合エラー(エラー)
          lv_errbuf_work := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
          ln_error_cnt := gtbl_error.COUNT + 1;
          gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
          gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
          lb_err_flag := TRUE;
        END IF;
--
      END IF;
--
      -- ==============================================================
      -- 棚卸ケース数値チェック
      -- ==============================================================
      IF (gtbl_data(ln_cnt_loop).case_amt < gn_zero) THEN
        -- 棚卸ケース、0未満の場合エラー(エラー)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10106',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_case_amt_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
        lb_err_flag := TRUE;
      END IF;
--
      IF (
          fnc_check_num(
            iv_check_num => gtbl_data(ln_cnt_loop).case_amt
           ,iv_format    => cv_case_amt_format) = FALSE
         ) THEN
        -- 棚卸ケース、数値変換エラー(エラー)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10107',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_case_amt_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- 棚卸バラ数値チェック
      -- ==============================================================
      IF (gtbl_data(ln_cnt_loop).loose_amt < gn_zero) THEN
        -- 棚卸バラ、0未満の場合エラー(エラー)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10106',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_loose_amt_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
        lb_err_flag := TRUE;
      END IF;
--
      -- ==============================================================
      -- 入数値チェック
      -- ==============================================================
      IF (gtbl_data(ln_cnt_loop).content < gn_zero) THEN
        -- 入数、0未満の場合エラー(エラー)
        lv_errbuf_work := xxcmn_common_pkg.get_msg(
                            iv_application  => gv_xxinv,
                            iv_name         => 'APP-XXINV-10106',
                            iv_token_name1  => 'OBJECT',
                            iv_token_value1 => gv_content_col);
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
        lb_err_flag := TRUE;
      ELSE
        IF (lv_item_class_code = gv_item_class_products) AND
           (lv_prod_class_code = gv_goods_classe_drink) THEN
          -- 品目区分が製品で かつ 商品区分がドリンク
          IF (lv_num_of_cases != gtbl_data(ln_cnt_loop).content) THEN
            -- 入数の不一致(エラー)
            lv_errbuf_work := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10110',
                                iv_token_name1  => 'OBEJCT',
                                iv_token_value1 => gv_content_col,
                                iv_token_name2  => 'CONTENT',
                                iv_token_value2 => gv_content_col ||
                                  gv_msg_part || gtbl_data(ln_cnt_loop).content);
            ln_error_cnt := gtbl_error.COUNT + 1;
            gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
            gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
            lb_err_flag := TRUE;
          END IF;
        END IF;
--
      END IF;
--
-- 2009/02/09 v1.6 ADD START
      -- ==============================================================
      -- 在庫クローズチェック
      -- ==============================================================
      -- 棚卸日が在庫カレンダーのオープンでない場合
      IF ( TO_CHAR(gtbl_data(ln_cnt_loop).invent_date, 'YYYYMM') <= xxcmn_common_pkg.get_opminv_close_period() ) THEN
        -- エラーメッセージを取得
        lv_errbuf_work := xxcmn_common_pkg.get_msg(gv_xxinv
                                                 , 'APP-XXINV-10003'
                                                 , 'ERR_MSG'
                                                 , TO_CHAR(gtbl_data(ln_cnt_loop).invent_date, gc_char_d_format));
        ln_error_cnt := gtbl_error.COUNT + 1;
        gtbl_error(ln_error_cnt) := gtbl_data(ln_cnt_loop); -- 入力データ退避
        gtbl_error(ln_error_cnt).err_msg := lv_errbuf_work; -- エラーメッセージセット
        lb_err_flag := TRUE;
      END IF;
--
-- 2009/02/09 v1.6 ADD END
      -- 正常データのセット
      IF ((lb_err_flag = FALSE)
        AND (lb_warn_flag = FALSE)) THEN
        -- エラーなしの場合
        ln_normal_cnt := gtbl_normal.COUNT + 1;
        gtbl_normal(ln_normal_cnt) := gtbl_data(ln_cnt_loop);
      ELSIF (lb_err_flag = TRUE) THEN -- エラーフラグ(エラー優先)
        -- エラー件数カウント
        gn_error_cnt  := gn_error_cnt + 1;
        -- エラー時、警告セット
        ov_retcode := gv_status_warn;
      ELSIF (lb_warn_flag = TRUE) THEN-- 保留フラグ
        -- 保留件数カウント
        gn_warn_cnt   := gn_warn_cnt + 1;
        -- エラー時、警告セット
        ov_retcode := gv_status_warn;
      END IF;
--
    END LOOP check_loop;
    -- 件数
    gn_normal_cnt := gtbl_normal.COUNT;                 -- 正常件数
--
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
  END proc_check;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_ins_data
   * Description      : 対象データ取得(B-2)
   ***********************************************************************************/
  PROCEDURE proc_get_ins_data(
-- 2009/02/09 v1.7 ADD START
    iv_report_post_code IN  xxinv_stc_inventory_interface.report_post_code%TYPE,  --報告部署
    iv_whse_code        IN  ic_whse_mst.whse_code                         %TYPE,  --倉庫コード
    iv_item_type        IN  xxcmn_categories2_v.segment1                  %TYPE,  --品目区分
-- 2009/02/09 v1.7 ADD END
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_ins_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =============================
    -- 対象データロック
    -- =============================
    BEGIN
      -- ロック取得カーソルOPEN
      OPEN gcur_xxinv_stc_inv_hht_work;
    EXCEPTION
      WHEN lock_expt THEN --*** ロック取得エラー ***
        -- カーソルをCLOSE
        IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
          CLOSE gcur_xxinv_stc_inv_hht_work;
        END IF;
        -- エラーメッセージ取得
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                       iv_application  => gv_xxcmn,
                       iv_name         => 'APP-XXCMN-10019',
                       iv_token_name1  => 'TABLE',
                       iv_token_value1 => gv_inv_hht_name),1,5000);
        RAISE global_user_expt;
    END;
--
    -- =============================
    -- 対象データ取得
    -- =============================
    gtbl_data.DELETE;
    BEGIN
      SELECT
        xsihw.invent_hht_if_id AS invent_hht_if_id
       ,xsihw.report_post_code AS report_post_code
       ,xsihw.invent_date      AS invent_date
       ,xsihw.invent_whse_code AS invent_whse_code
       ,xsihw.invent_seq       AS invent_seq
       ,xsihw.item_code        AS item_code
       ,xsihw.lot_no           AS lot_no
-- 2008/12/06 T.Miyata Update Start
--       ,xsihw.maker_date       AS maker_date
--       ,xsihw.limit_date       AS limit_date
       ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.maker_date, gc_char_d_format), gc_char_d_format)       AS maker_date
       ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.limit_date, gc_char_d_format), gc_char_d_format)       AS limit_date
-- 2008/12/06 T.Miyata Update End
       ,xsihw.proper_mark      AS proper_mark
       ,xsihw.case_amt         AS case_amt
       ,xsihw.content          AS content
       ,xsihw.loose_amt        AS loose_amt
       ,xsihw.location         AS location
       ,xsihw.rack_no1         AS rack_no1
       ,xsihw.rack_no2         AS rack_no2
       ,xsihw.rack_no3         AS rack_no3
       ,xsihw_b.invent_seq     AS b_invent_seq       -- 製品重複チェック用
       ,xsihw_c.invent_seq     AS c_invent_seq       -- 製品以外重複チェック用
       ,xsihw.ROWID            AS rowid_work
       ,''                     AS err_msg            -- エラーメッセージ
       ,gn_zero                AS b3_item_id         -- b3_品目ID
       ,NULL                   AS b3_lot_ctl         -- b3_ロット管理区分
       ,NULL                   AS b3_num_of_cases    -- b3_ケース入数
       ,NULL                   AS b3_item_class_code -- b3_品目区分
       ,NULL                   AS b3_prod_class_code -- b3_商品区分
       ,gn_zero                AS b3_lot_id          -- b3_ロットID
       ,NULL                   AS b3_lot_no          -- b3_ロットNO
       ,NULL                   AS b3_maker_date      -- b3_製造年月日
       ,NULL                   AS b3_proper_mark     -- b3_固有記号
       ,NULL                   AS b3_limit_date      -- b3_賞味期限
      BULK COLLECT INTO gtbl_data
      FROM
-- 2009/02/09 v1.7 ADD START
        ic_whse_mst                  iwm,
        xxcmn_item_mst_v             itm,
        xxcmn_item_categories5_v     ictm,
-- 2009/02/09 v1.7 ADD END
        -- HHT棚卸ワークテーブル
        xxinv_stc_inventory_hht_work xsihw
        -- HHT棚卸ワークテーブル 製品重複チェック用
       ,(
        SELECT
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
-- 2008/12/06 T.Miyata Update Start
--         ,xsihw.maker_date
--         ,xsihw.limit_date
         ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.maker_date, gc_char_d_format), gc_char_d_format)       AS maker_date
         ,TO_CHAR(FND_DATE.STRING_TO_DATE(xsihw.limit_date, gc_char_d_format), gc_char_d_format)       AS limit_date
-- 2008/12/06 T.Miyata Update End
         ,xsihw.proper_mark
         ,xsihw.invent_date --2008/05/02
        FROM xxinv_stc_inventory_hht_work xsihw
        GROUP BY
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
         ,xsihw.maker_date
         ,xsihw.limit_date
         ,xsihw.proper_mark
         ,xsihw.invent_date --2008/05/02
        HAVING COUNT(xsihw.invent_seq) > 1
        ) xsihw_b,
        -- HHT棚卸ワークテーブル 製品以外重複チェック用
        (
        SELECT
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
         ,xsihw.lot_no
         ,xsihw.invent_date
        FROM xxinv_stc_inventory_hht_work xsihw
        GROUP BY
          xsihw.invent_seq
         ,xsihw.invent_whse_code
         ,xsihw.report_post_code
         ,xsihw.item_code
         ,xsihw.lot_no
         ,xsihw.invent_date
        HAVING COUNT(xsihw.invent_seq) > 1
        ) xsihw_c
      WHERE
      -- HHT棚卸ワークテーブル 製品重複チェック用
          xsihw.invent_seq       = xsihw_b.invent_seq(+)
      AND xsihw.invent_whse_code = xsihw_b.invent_whse_code(+)
      AND xsihw.report_post_code = xsihw_b.report_post_code(+)
      AND xsihw.item_code        = xsihw_b.item_code(+)
      AND xsihw.maker_date       = xsihw_b.maker_date(+)
      AND xsihw.limit_date       = xsihw_b.limit_date(+)
      AND xsihw.proper_mark      = xsihw_b.proper_mark(+)
      AND xsihw.invent_date      = xsihw_b.invent_date(+) --2008/05/02
      -- HHT棚卸ワークテーブル 製品以外重複チェック用
      AND xsihw.invent_seq       = xsihw_c.invent_seq(+)
      AND xsihw.invent_whse_code = xsihw_c.invent_whse_code(+)
      AND xsihw.report_post_code = xsihw_c.report_post_code(+)
      AND xsihw.item_code        = xsihw_c.item_code(+)
      AND xsihw.lot_no           = xsihw_c.lot_no(+)
      AND xsihw.invent_date      = xsihw_c.invent_date(+)
-- 2009/02/09 v1.7 ADD START
      AND xsihw.report_post_code = iv_report_post_code
      AND xsihw.invent_whse_code = iwm.whse_code
      AND iwm.whse_code          = NVL(iv_whse_code, iwm.whse_code)
      AND xsihw.item_code        = itm.item_no
      AND itm.item_id            = ictm.item_id
      AND ictm.item_class_code   = NVL(iv_item_type, ictm.item_class_code)
-- 2009/02/09 v1.7 ADD END
      ORDER BY
        xsihw.invent_seq
       ,xsihw.invent_whse_code
       ,xsihw.report_post_code
       ,xsihw.item_code
       ,xsihw.maker_date
       ,xsihw.limit_date
       ,xsihw.proper_mark
       ,xsihw.lot_no
       ,xsihw.invent_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    -- 対象件数
    gn_target_cnt := gtbl_data.COUNT;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_get_ins_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_table_data
   * Description      : データパージ処理(B-1)
   ***********************************************************************************/
  PROCEDURE proc_del_table_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_table_data'; -- プログラム名
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
    cv_inv_del_date   CONSTANT VARCHAR2(100) := 'XXINV_INVENTORY_PURGE_TERM'; -- 棚卸削除対象日付
--
    -- *** ローカル変数 ***
    lv_inv_del_date   FND_PROFILE_OPTION_VALUES.PROFILE_OPTION_VALUE%TYPE;
    ld_del_date       DATE;
    lr_rowid          ROWID;
--
    -- *** ローカル・カーソル ***
--
    -- HHT棚卸ワークテーブルカーソル
    CURSOR xxinv_stc_inv_hht_work_lcur(
      cd_del_date DATE -- 削除日付
      )
    IS
      SELECT xsihw.ROWID
      FROM   xxinv_stc_inventory_hht_work xsihw
      WHERE  xsihw.creation_date < cd_del_date
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    TYPE ltbl_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    ltbl_rowid ltbl_rowid_type;
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
    -- ==============================================================
    -- プロファイルオプション取得
    -- ==============================================================
    -- プロファイル名（棚卸削除対象日付）
    lv_inv_del_date := FND_PROFILE.VALUE(cv_inv_del_date);
    -- プロファイルに未登録
    IF (lv_inv_del_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,'APP-XXCMN-10002'
                    ,'NG_PROFILE'
                    ,gv_profile_name),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- HHT棚卸ワークテーブルの削除
    -- ==============================================================
    BEGIN
      -- 削除日付の作成
      ld_del_date := (TRUNC(SYSDATE) - TO_NUMBER(lv_inv_del_date));
--
      --  ロック取得カーソルOPEN
      OPEN xxinv_stc_inv_hht_work_lcur(
        cd_del_date => ld_del_date);
--
      <<fetch_loop>>
      LOOP
        FETCH xxinv_stc_inv_hht_work_lcur INTO lr_rowid;
        EXIT WHEN xxinv_stc_inv_hht_work_lcur%NOTFOUND;
        -- 削除対象ROWIDのセット
        ltbl_rowid(ltbl_rowid.COUNT + 1) := lr_rowid;
      END LOOP fetch_loop;
--
      -- 一括削除処理
      FORALL ln_cnt_loop in 1..ltbl_rowid.COUNT
        DELETE xxinv_stc_inventory_hht_work xsihw
        WHERE  xsihw.ROWID = ltbl_rowid(ln_cnt_loop);
--
      -- ロック取得カーソルをCLOSE
      CLOSE xxinv_stc_inv_hht_work_lcur;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ロック取得エラー ***
        -- カーソルをCLOSE
        IF (xxinv_stc_inv_hht_work_lcur%ISOPEN) THEN
          CLOSE xxinv_stc_inv_hht_work_lcur;
        END IF;
        -- エラーメッセージ取得
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                       gv_xxcmn
                      ,'APP-XXCMN-10019'
                      ,'TABLE'
                      ,gv_inv_hht_name
                      ),1,5000);
        RAISE global_user_expt;
      WHEN OTHERS THEN
        -- カーソルをCLOSE
        IF (xxinv_stc_inv_hht_work_lcur%ISOPEN) THEN
          CLOSE xxinv_stc_inv_hht_work_lcur;
        END IF;
        RAISE global_user_expt;
--
    END;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_del_table_data;
--
--
--
-- 2009/02/09 v1.7 ADD START
   /**********************************************************************************
   * Procedure Name   : proc_check_param
   * Description      : パラメータチェック
   ***********************************************************************************/
  PROCEDURE proc_check_param(
    iv_report_post_code   IN      VARCHAR2,   -- 報告部署
    iv_whse_code          IN      VARCHAR2,   -- 倉庫コード
    iv_item_type          IN      VARCHAR2,   -- 品目区分
    ov_errbuf             OUT     VARCHAR2,   -- エラー・メッセージ
    ov_retcode            OUT     VARCHAR2,   -- リターン・コード
    ov_errmsg             OUT     VARCHAR2)   -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check_param'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_xxpo_date_type       CONSTANT  VARCHAR2(30) := 'XXPO_DATE_TYPE';       -- 日付タイプ
    cv_xxpo_commodity_type  CONSTANT  VARCHAR2(30) := 'XXPO_COMMODITY_TYPE';  -- 商品区分
    cv_xxpo_item_type       CONSTANT  VARCHAR2(30) := 'XXCMN_C01';            -- 品目区分
--
    -- *** ローカル変数 ***
    lv_lookup_code    xxcmn_lookup_values_v.lookup_code %TYPE  DEFAULT NULL;  -- ルックアップコード
    lv_location_code  xxcmn_locations_v.LOCATION_CODE   %TYPE  DEFAULT NULL;  --部署コード
    lv_whse_code      ic_whse_mst.whse_code             %TYPE  DEFAULT NULL;  --倉庫コード
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
    -- ==============================================================
    -- 報告部署が入力されているかチェックします。
    -- ==============================================================
    IF (iv_report_post_code IS NULL) THEN
      lv_errbuf  := xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxcmn,
                      iv_name         => 'APP-XXCMN-10010',
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_inv_whse_section_col,  -- '倉庫管理部署'
                      iv_token_name2  => 'VALUE',
                      iv_token_value2 => NULL
                    );
      RAISE global_api_expt;
    END IF;
    -- ==============================================================
    -- 報告部署がが事業所マスタに存在するかチェック
    -- ==============================================================
    BEGIN
      SELECT lc.location_code cd
      INTO   lv_location_code
      FROM   xxcmn_locations_v lc
      WHERE  lc.location_code = iv_report_post_code
      AND    ROWNUM      = 1;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
      lv_errbuf  := xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxcmn,
                      iv_name         => 'APP-XXCMN-10010',
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_inv_whse_section_col,  -- '倉庫管理部署'
                      iv_token_name2  => 'VALUE',
                      iv_token_value2 => iv_report_post_code
                    );
      RAISE global_api_expt;
      -- その他エラー
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- 倉庫コードが入力されている場合、倉庫マスタを存在チェックします。
    -- ==============================================================
    IF (iv_whse_code IS NOT NULL) THEN
      BEGIN
        SELECT icmt.whse_code
        INTO   lv_whse_code
        FROM   ic_whse_mst icmt
        WHERE  icmt.whse_code = iv_whse_code
-- [E_本稼動_14953] SCSK Y.Sekine Add Start
        AND    icmt.delete_mark = '0'
-- [E_本稼動_14953] SCSK Y.Sekine Add End
        AND    ROWNUM      = 1;
      EXCEPTION
      -- データがない場合はエラー
        WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => 'APP-XXCMN-10010',
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_inv_whse_code,      --倉庫コード
                        iv_token_name2  => 'VALUE',
                        iv_token_value2 => iv_whse_code
                      );
        RAISE global_api_expt;
        -- その他エラー
        WHEN OTHERS THEN
          RAISE;
      END;
    END IF;
--
    -- ==============================================================
    -- 品目区分がカテゴリ情報に存在するかチェック
    -- ==============================================================
    IF (iv_item_type IS NOT NULL) THEN
      BEGIN
        SELECT xcv.segment1
        INTO   lv_lookup_code
        FROM   xxcmn_categories_v xcv             -- 品目カテゴリ情報VIEW
        WHERE  xcv.category_set_name = gv_item_typ
        AND    xcv.segment1 = iv_item_type
        AND    ROWNUM                = 1;
      EXCEPTION
      -- データがない場合はエラー
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxcmn,
                          iv_name         => 'APP-XXCMN-10010',
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => gv_item_typ,  --品目区分
                          iv_token_name2  => 'VALUE',
                          iv_token_value2 => iv_item_type
                        );
          RAISE global_api_expt;
        -- その他エラー
        WHEN OTHERS THEN
          RAISE;
      END;
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
  END proc_check_param;
--
--
-- 2009/02/09 v1.7 ADD END
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- 2009/02/09 v1.7 ADD START
    iv_report_post_code   IN  VARCHAR2,   -- 報告部署
    iv_whse_code          IN  VARCHAR2,   -- 倉庫コード
    iv_item_type          IN  VARCHAR2,   -- 品目区分
-- 2009/02/09 v1.7 ADD END
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
    lb_check_warn BOOLEAN DEFAULT FALSE; -- エラーチェック時警告保持
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gtbl_data.DELETE;       -- 元データ
    gtbl_normal.DELETE;     -- 正常データ
    gtbl_error.DELETE;      -- エラーデータ
    gtbl_reserve.DELETE;    -- 保留データ
    gtbl_normal_ins.DELETE; -- 正常データ挿入
--
-- 2009/02/09 v1.7 ADD START
    -- ===============================
    -- パラメータチェック
    -- ===============================
    proc_check_param(
       iv_report_post_code =>  iv_report_post_code   -- 報告部署
      ,iv_whse_code        =>  iv_whse_code          -- 倉庫コード
      ,iv_item_type        =>  iv_item_type          -- 品目区分
      ,ov_errbuf           =>  lv_errbuf             -- エラー・メッセージ
      ,ov_retcode          =>  lv_retcode            -- リターン・コード
      ,ov_errmsg           =>  lv_errmsg);           -- ユーザー・エラー・メッセージ
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2009/02/09 v1.7 ADD END
    -- ===============================
    -- B-1.データパージ処理
    -- ===============================
    proc_del_table_data(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-2.対象データ取得
    -- ===============================
    proc_get_ins_data(
-- 2009/02/09 v1.7 ADD START
      iv_report_post_code =>  iv_report_post_code, --報告部署
      iv_whse_code        =>  iv_whse_code,        --倉庫コード
      iv_item_type        =>  iv_item_type,        --品目区分
-- 2009/02/09 v1.7 ADD END
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-3.妥当性チェック
    -- ===============================
    proc_check(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      -- エラーチェック時警告を保持
      lb_check_warn := TRUE;
    END IF;
--
    -- ===============================
    -- B-3.エラーダンプ一括出力
    -- ===============================
    proc_put_dump_msg(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-4.棚卸結果更新処理
    -- ===============================
    proc_upd_table_batch(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-5.棚卸結果登録処理
    -- ===============================
    proc_ins_table_batch(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-6.対象データ削除
    -- ===============================
    proc_del_table_data_batch(
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg);
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (lb_check_warn) THEN
      -- エラーチェック時警告を戻します。
      ov_retcode := gv_status_warn;
    END IF;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
        CLOSE gcur_xxinv_stc_inv_hht_work;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
        CLOSE gcur_xxinv_stc_inv_hht_work;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (gcur_xxinv_stc_inv_hht_work%ISOPEN) THEN
        CLOSE gcur_xxinv_stc_inv_hht_work;
      END IF;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
-- 2009/02/09 v1.7 UPDATE START
--    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_report_post_code   IN  VARCHAR2,   -- 報告部署
    iv_whse_code          IN  VARCHAR2,   -- 倉庫コード
    iv_item_type          IN  VARCHAR2    -- 品目区分
-- 2009/02/09 v1.7 UPDATE END
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
    gv_exec_user := FND_GLOBAL.USER_NAME;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = FND_GLOBAL.PROG_APPL_ID
    AND    fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
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
-- 2009/02/09 v1.7 ADD START
      iv_report_post_code, -- 報告部署
      iv_whse_code,        -- 倉庫コード
      iv_item_type,        -- 品目区分
-- 2009/02/09 v1.7 ADD END
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
      gn_normal_cnt := 0; -- 成功件数の初期化
    END IF;
    -- ==================================
    -- D-15.リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --保留件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flv.lookup_type,
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
END xxinv530002c;
/
