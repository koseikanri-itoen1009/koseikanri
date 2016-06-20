create or replace PACKAGE BODY xxinv530001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv5300001(body)
 * Description      : 棚卸結果インターフェース
 * MD.050           : 棚卸(T_MD050_BPO_530)
 * MD.070           : 結果インターフェース(T_MD070_BPO_53A)
 * Version          : 1.13
 *
 * Program List
 *  ----------------------------------------------------------------------------------------
 *   Name                         Type  Ret   Description
 *  ----------------------------------------------------------------------------------------
 *  proc_put_dump_msg               P         データダンプ一括出力処理            (A-4-5)
 *  proc_get_data_dump              P         データダンプ取得処理                (A-4-4)
 *  proc_duplication_chk            P         重複データチェック                  (A-4-3)
 *  proc_del_table_data             P         対象データ削除                      (A-7)
 *  proc_ins_table_batch            P         棚卸結果登録処理                    (A-6)
 *  proc_upd_table_batch            P         棚卸結果更新処理                    (A-5)
 *  proc_master_data_chk            P         妥当性チェック                      (A-4)
 *  proc_get_lock                   P         対象インターフェースデータ取得      (A-3)
 *  proc_del_inventory_if           P         データパージ処理                    (A-2)
 *  proc_check_param                P         パラメータチェック                  (A-1)
 *  submain                         P         メイン処理プロシージャ
 *  main                            P         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * -----------------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * -----------------------------------------------------------------------------------
 *  2008/03/14    1.0   M.Inamine        新規作成
 *  2008/05/02    1.1   M.Inamine        修正(【BPO_530_棚卸】修正依頼事項 No2の対応)
 *                                           (【BPO_530_棚卸】修正依頼事項 No4の対応)
 *  2008/05/07    1.2   M.Inamine        修正(20080507_03 No5の対応、ロット№は空白を出力)
 *  2008/05/08    1.3   M.Inamine        修正(仕様変更対応、ロット管理外の場合ロットIDはNULLへ)
 *  2008/05/09    1.4   M.Inamine        修正(2008/05/08 03 不具合対応：日付書式の誤り)
 *  2008/05/20    1.4   T.Ikehara        修正(不具合ID6対応：出力メッセージの誤り)
 *  2008/09/04    1.5   H.Itou           修正(PT 6-3_39指摘#12 動的SQLの変数をバインド変数化)
 *  2008/09/11    1.6   T.Ohashi         修正(PT 6-3_39指摘74 対応)
 *  2008/09/16    1.7   T.Ikehara        修正(不具合ID7対応：重複削除はエラーとしない)
 *  2008/10/15    1.8   T.Ikehara        修正(不具合ID8対応：重複削除対象データを
 *                                                           妥当性チェック対象外に修正 )
 *  2008/12/06    1.9   H.Itou           修正(本番障害#510対応：日付は変換して比較)
 *  2008/12/08    1.10  K.Kumamoto       修正(本番障害#570対応：棚卸連番をTO_NUMBER)
 *  2008/12/11    1.11  H.Itou           修正(本番障害#632対応：#570修正漏れ)
 *  2009/02/09    1.12  A.Shiina         修正(本番障害#1117対応：在庫クローズチェック追加)
 *  2016/06/15    1.13  Y.Shoji          E_本稼動_13563対応
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
  gv_out_msg       VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg       VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user     VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name     VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status   VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt    NUMBER         DEFAULT 0;   -- 対象件数
  gn_normal_cnt    NUMBER         DEFAULT 0;   -- 正常件数
  gn_error_cnt     NUMBER         DEFAULT 0;   -- エラー件数
  gn_warn_cnt      NUMBER         DEFAULT 0;   -- スキップ件数
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
  lock_expt               EXCEPTION;        -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);    -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxinv5300001c'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn                CONSTANT VARCHAR2(10) := 'XXCMN'; -- モジュール名略称：XXCMN 共通
  gv_xxinv                CONSTANT VARCHAR2(10) := 'XXINV'; -- モジュール名略称：XXINV
--
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- WHO列情報
  gn_user_id              CONSTANT NUMBER := FND_GLOBAL.USER_ID;
  gd_sysdate              CONSTANT DATE   := SYSDATE;
  gn_last_update_login    CONSTANT NUMBER := FND_GLOBAL.LOGIN_ID;
  gn_request_id           CONSTANT NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
  gn_program_appl_id      CONSTANT NUMBER := FND_GLOBAL.PROG_APPL_ID;
  gn_program_id           CONSTANT NUMBER := FND_GLOBAL.CONC_PROGRAM_ID;
--
  -- トークン
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_tkn_value            CONSTANT VARCHAR2(15) := 'VALUE';
  gv_tkn_item             CONSTANT VARCHAR2(15) := 'ITEM';
  gv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_profile       CONSTANT VARCHAR2(15) := 'NG_PROFILE';
--
  -- YES/NO
  gn_y                    CONSTANT NUMBER := 1;
  gn_n                    CONSTANT NUMBER := 0;
--
  -- 商品区分
  gv_goods_classe_reaf    CONSTANT VARCHAR2(1) := '1';   -- 商品区分：1(リーフ)
  gv_goods_classe_drink   CONSTANT VARCHAR2(1) := '2';   -- 商品区分：2(ドリンク)
  -- 製品区分
  gv_item_cls_prdct       CONSTANT VARCHAR2(1)  := '5';   -- 品目区分：5(製品)
--
  gv_date                 CONSTANT VARCHAR2(10) := 'yyyy/mm/dd';
  gv_blank                CONSTANT VARCHAR2(2)  := ' ';
  gn_zero                 CONSTANT NUMBER       := 0;
--
  gv_item_typ             CONSTANT VARCHAR2(10) := '品目区分';
  gv_prdct_typ            CONSTANT VARCHAR2(10) := '商品区分';
  gv_profile_name         CONSTANT VARCHAR2(16) := '棚卸削除対象日付';
  gv_inv_hht_name         CONSTANT VARCHAR2(30) := 'HHT棚卸ワークテーブル';
  gv_inv_result_name      CONSTANT VARCHAR2(30) := '棚卸結果テーブル';
  gv_opm_item_name        CONSTANT VARCHAR2(30) := 'OPM品目マスタ';
  gv_opm_lot_name         CONSTANT VARCHAR2(30) := 'OPMロットマスタ';
  gv_invent_whse_name     CONSTANT VARCHAR2(30) := 'OPM倉庫マスタ';
  gv_report_post_name     CONSTANT VARCHAR2(30) := '事業所マスタ';
--
  gv_item_col             CONSTANT VARCHAR2(4)  := '品目';
  gv_inv_whse_code_col    CONSTANT VARCHAR2(8)  := '棚卸倉庫';
  gv_report_post_code_col CONSTANT VARCHAR2(8)  := '報告部署';
  gv_inv_whse_section_col CONSTANT VARCHAR2(20) := '倉庫管理部署';
  gv_inv_whse_code        CONSTANT VARCHAR2(20) := '倉庫コード';
--
  gv_lot_no_col           CONSTANT VARCHAR2(8)  := 'ロットNo';
  gv_maker_date_col       CONSTANT VARCHAR2(8)  := '製造日';
  gv_limit_date_col       CONSTANT VARCHAR2(8)  := '賞味期限';
  gv_proper_mark_col      CONSTANT VARCHAR2(8)  := '固有記号';
  gv_case_amt_col         CONSTANT VARCHAR2(10) := '棚卸ケース';
  gv_content_col          CONSTANT VARCHAR2(4)  := '入数';
  gv_num_of_cases_col     CONSTANT VARCHAR2(10) := 'ケース入数';
  gv_loose_amt_col        CONSTANT VARCHAR2(8)  := '棚卸バラ';
  --妥当性ステータス
  gv_sts_ok               CONSTANT VARCHAR2(2)  := 'OK';   -- 正常
  gv_sts_ng               CONSTANT VARCHAR2(2)  := 'NG';   -- エラー
  gv_sts_hr               CONSTANT VARCHAR2(3)  := 'SKP';  -- 保留
  gv_sts_del              CONSTANT VARCHAR2(3)  := 'DEL';  -- 削除
  gv_sts_ins              CONSTANT VARCHAR2(3)  := 'INS';  -- 登録対象
--
  --テーブル名
  gv_xxcmn_del_table_name CONSTANT  VARCHAR2(50) := '棚卸データインターフェーステーブル';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- メッセージPL/SQL表型
  TYPE msg_ttype   IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- カウント
  gn_err_msg_cnt      NUMBER DEFAULT 0;   -- 警告エラーメッセージ表カウント
  gn_ins_tab_cnt      NUMBER DEFAULT 0;   -- 登録用PL/SQL表カウント
  gn_upd_tab_cnt      NUMBER DEFAULT 0;   -- 更新用PL/SQL表カウント
--
--
  -------------------------------------------------------------------------------------------------
  -- 「棚卸データインターフェーステーブル」構造体
  -------------------------------------------------------------------------------------------------
  TYPE xxinv_stc_inv_if_rec IS RECORD(
    invent_if_id      xxinv_stc_inventory_interface.invent_if_id    %TYPE,    --棚卸ＩＦ_ID
    report_post_code  xxinv_stc_inventory_interface.report_post_code%TYPE,    --報告部署
    invent_date       xxinv_stc_inventory_interface.invent_date     %TYPE,    --棚卸日
    invent_whse_code  xxinv_stc_inventory_interface.invent_whse_code%TYPE,    --棚卸倉庫
    invent_seq        xxinv_stc_inventory_interface.invent_seq      %TYPE,    --棚卸連番
    item_code         xxinv_stc_inventory_interface.item_code       %TYPE,    --品目
    lot_no            xxinv_stc_inventory_interface.lot_no          %TYPE,    --ロットNo.
    maker_date        xxinv_stc_inventory_interface.maker_date      %TYPE,    --製造日
    limit_date        xxinv_stc_inventory_interface.limit_date      %TYPE,    --賞味期限
    proper_mark       xxinv_stc_inventory_interface.proper_mark     %TYPE,    --固有記号
    case_amt          xxinv_stc_inventory_interface.case_amt        %TYPE,    --棚卸ケース数
    content           xxinv_stc_inventory_interface.content         %TYPE,    --入数
    loose_amt         xxinv_stc_inventory_interface.loose_amt       %TYPE,    --棚卸バラ
    location          xxinv_stc_inventory_interface.location        %TYPE,    --ロケーション
    rack_no1          xxinv_stc_inventory_interface.rack_no1        %TYPE,    --ラックNo１
    rack_no2          xxinv_stc_inventory_interface.rack_no2        %TYPE,    --ラックNo２
    rack_no3          xxinv_stc_inventory_interface.rack_no3        %TYPE,    --ラックNo３
    request_id        xxinv_stc_inventory_interface.request_id      %TYPE,    --要求ID
--  A-4取得分
    item_id           xxinv_stc_inventory_result.item_id            %TYPE,    --品目ID
    lot_ctl           xxcmn_item_mst_v.lot_ctl                      %TYPE,    --ロット管理区分
    num_of_cases      xxcmn_item_mst_v.num_of_cases                 %TYPE,    --ケース入数
    item_type         xxcmn_item_categories2_v.segment1             %TYPE,    --品目区分
    product_type      xxcmn_item_categories2_v.segment1             %TYPE,    --商品区分
--
    lot_id            ic_lots_mst.lot_id                            %TYPE,    --ロットID
    lot_no1           ic_lots_mst.lot_no                            %TYPE,    --ロットNo
    maker_date1       ic_lots_mst.attribute1                        %TYPE,    --製造年月日
    proper_mark1      ic_lots_mst.attribute2                        %TYPE,    --固有記号
    limit_date1       ic_lots_mst.attribute3                        %TYPE,    --賞味期限
    rowid_work        ROWID,                      -- ROWID
    sts               VARCHAR2(3));               --妥当性チェックステータス
  --レコード型生成
  TYPE xxinv_stc_inventory_if_tab IS TABLE OF xxinv_stc_inv_if_rec;
   inv_if_rec xxinv_stc_inventory_if_tab;
--
  -- ============================
  -- ユーザー定義グローバル変数 =
  -- ============================
  -- 警告データダンプPL/SQL表
  warn_dump_tab         msg_ttype;
--
  -- 正常データダンプPL/SQL表
  normal_dump_tab      msg_ttype;
--
  -- *** グローバル・カーソル ***
  TYPE cursor_rec IS REF CURSOR;--棚卸データインターフェーステーブルの対象データ取得用
--
  /***********************************************************************************
   * Procedure Name   : proc_put_dump_msg
   * Description      : データダンプ一括出力処理(A-4-5)
   ***********************************************************************************/
  PROCEDURE proc_put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'proc_put_dump_msg'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_msg      VARCHAR2(5000)  DEFAULT NULL;  -- メッセージ
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
    --区切り文字列出力
    IF (warn_dump_tab.COUNT != 0 ) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
  --
      -- エラーデータ（見出し）
      lv_msg  := SUBSTRB(XXCMN_COMMON_PKG.GET_MSG(
                   gv_xxcmn
                  ,'APP-XXCMN-00006'
                  ),1,5000);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- 警告データダンプ
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
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
  /**********************************************************************************
   * Procedure Name   : proc_get_data_dump
   * Description      : データダンプ取得処理(A-4-4)
   ***********************************************************************************/
  PROCEDURE proc_get_data_dump(
    if_rec        IN  xxinv_stc_inv_if_rec, -- 1.棚卸インターフェース
    ov_dump       OUT VARCHAR2,             -- 2.データダンプ文字列
    ov_errbuf     OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data_dump'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ユーザー・エラー・メッセージ
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
    -- ===============================
    -- データダンプ作成
    -- ===============================
    ov_dump := TO_CHAR(if_rec.invent_if_id)             || gv_msg_comma ||  --棚卸ＩＦ_ID
               if_rec.report_post_code                  || gv_msg_comma ||  --報告部署
               TO_CHAR(if_rec.invent_date, gv_date)     || gv_msg_comma ||  --棚卸日
               if_rec.invent_whse_code                  || gv_msg_comma ||  --棚卸倉庫
               if_rec.invent_seq                        || gv_msg_comma ||  --棚卸連番
               if_rec.item_code                         || gv_msg_comma ||  --品目
               if_rec.lot_no                            || gv_msg_comma ||  --ロットNo.
               if_rec.maker_date                        || gv_msg_comma ||  --製造日
               if_rec.limit_date                        || gv_msg_comma ||  --賞味期限
               if_rec.proper_mark                       || gv_msg_comma ||  --固有記号
               TO_CHAR(if_rec.case_amt)                 || gv_msg_comma ||  --棚卸ケース数
               TO_CHAR(if_rec.content)                  || gv_msg_comma ||  --入数
               TO_CHAR(if_rec.loose_amt)                || gv_msg_comma ||  --棚卸バラ
               if_rec.location                          || gv_msg_comma ||  --ロケーション
               if_rec.rack_no1                          || gv_msg_comma ||  --ラックNo１
               if_rec.rack_no2                          || gv_msg_comma ||  --ラックNo２
               if_rec.rack_no3;                                             --ラックNo３
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
  END proc_get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : proc_duplication_chk
   * Description      : 重複データチェック(A-4-3)
   * RETURN  true : OK(重複なし)  false : NG(重複あり)
   ***********************************************************************************/
  PROCEDURE proc_duplication_chk(
     if_rec        IN  xxinv_stc_inv_if_rec    -- 1.棚卸インターフェース
    ,iv_item_typ   IN  VARCHAR2                -- 2.品目区分
    ,ib_dup_sts    OUT BOOLEAN                 -- 3.重複チェック結果
    ,ib_dup_del_sts OUT BOOLEAN                -- 4.異なる要求IDで重複し、最新要求IDでない=TRUE
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_duplication_chk'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_sql        VARCHAR2(15000)   DEFAULT NULL;-- 動的SQL文字列
    ln_cnt        NUMBER            DEFAULT 0;   -- 重複件数
    ln_request_id xxinv_stc_inventory_interface.request_id%TYPE; -- 要求ID
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 結果初期化
    ib_dup_sts     := TRUE;
    ib_dup_del_sts := FALSE;
--
    -- 同要求ID配下での重複チェック
    lv_sql  :=  'SELECT COUNT(xsi.report_post_code) cnt '  -- カウント
      ||  'FROM  xxinv_stc_inventory_interface xsi '  -- 1.棚卸データインタフェース
-- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
--      ||  'WHERE xsi.request_id        = '    ||  if_rec.request_id                -- 要求ID
--      ||  '  AND xsi.report_post_code  = '''  ||  if_rec.report_post_code  || '''' -- 報告部署
--      ||  '  AND xsi.invent_whse_code  = '''  ||  if_rec.invent_whse_code  || '''' -- 棚卸倉庫
--      ||  '  AND xsi.invent_seq        = '''  ||  if_rec.invent_seq        || '''' -- 棚卸連番
--      ||  '  AND xsi.item_code         = '''  ||  if_rec.item_code         || '''';-- 品目
      ||  'WHERE xsi.request_id        = :request_id        ' -- 要求ID
      ||  '  AND xsi.report_post_code  = :report_post_code  ' -- 報告部署
      ||  '  AND xsi.invent_whse_code  = :invent_whse_code  ' -- 棚卸倉庫
--2008/12/08 mod start
--      ||  '  AND xsi.invent_seq        = :invent_seq        ' -- 棚卸連番
      ||  '  AND TO_NUMBER(xsi.invent_seq)        = TO_NUMBER(:invent_seq)        ' -- 棚卸連番
--2008/12/08 mod end
      ||  '  AND xsi.item_code         = :item_code         ';-- 品目
-- 2008/09/04 H.Itou Mod End
    --品目区分が製品の場合
    IF  (iv_item_typ   = gv_item_cls_prdct) THEN
      lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
---- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
----      ||  '  AND xsi.maker_date  = '''  ||  if_rec.maker_date   || ''''  --製造日
----      ||  '  AND xsi.limit_date  = '''  ||  if_rec.limit_date   || ''''  --賞味期限
----      ||  '  AND xsi.proper_mark = '''  ||  if_rec.proper_mark  || ''''  --固有記号
----      --2008/5/02(レビューNo2)
----      ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
----                          TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--棚卸日
--      ||  '  AND xsi.maker_date,  = :maker_date   '  -- 製造日
--      ||  '  AND xsi.limit_date  = :limit_date   '  -- 賞味期限
--      ||  '  AND xsi.proper_mark = :proper_mark  '  -- 固有記号
--      ||  '  AND xsi.invent_date = :invent_date  '; -- 棚卸日
---- 2008/09/04 H.Itou Mod End
      ||  '  AND CASE '
      ||  '         WHEN xsi.maker_date IS NULL   THEN ''*'''
      ||  '         WHEN xsi.maker_date = ''0''   THEN ''0'''
      ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
      ||  '      END = :maker_date ' -- 製造日
      ||  '  AND CASE '
      ||  '         WHEN xsi.limit_date IS NULL   THEN ''*'''
      ||  '         WHEN xsi.limit_date = ''0''   THEN ''0'''
      ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
      ||  '      END = :limit_date '-- 賞味期限
      ||  '  AND xsi.proper_mark = :proper_mark  ' -- 固有記号
      ||  '  AND xsi.invent_date = :invent_date  ' -- 棚卸日
      ;
-- 2008/12/06 H.Itou Mod End
    --品目区分が製品以外
    ELSE
      lv_sql  :=  lv_sql
-- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
--      ||  '  AND xsi.lot_no      = '''  ||  if_rec.lot_no  || '''' --ロットNo
--      ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
--                          TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--棚卸日
      ||  '  AND xsi.lot_no      = :lot_no       '  --ロットNo
      ||  '  AND xsi.invent_date = :invent_date  '; -- 棚卸日
-- 2008/09/04 H.Itou Mod End
    END IF;
--
    lv_sql  :=  lv_sql
      ||  ' GROUP BY '
      ||  ' xsi.report_post_code  '    -- 報告部署
      ||  ',xsi.invent_whse_code  '    -- 棚卸倉庫
--2008/12/08 mod start
--      ||  ',xsi.invent_seq  '          -- 棚卸連番
      ||  ',TO_NUMBER(xsi.invent_seq)  '          -- 棚卸連番
--2008/12/08 mod end
      ||  ',xsi.item_code  ';          -- 品目
--
    --品目区分が製品の場合
    IF  (iv_item_typ   = gv_item_cls_prdct) THEN
      lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
--      ||  ', xsi.maker_date  '     --製造日
--      ||  ', xsi.limit_date  '     --賞味期限
--      ||  ', xsi.proper_mark  '    --固有記号
--      ||  ', xsi.invent_date  ';   --棚卸日--2008/05/02
      ||  ', CASE '
      ||  '    WHEN xsi.maker_date IS NULL   THEN ''*'''
      ||  '    WHEN xsi.maker_date = ''0''   THEN ''0'''
      ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
      ||  '  END ' -- 製造日
      ||  ', CASE '
      ||  '    WHEN xsi.limit_date IS NULL   THEN ''*'''
      ||  '    WHEN xsi.limit_date = ''0''   THEN ''0'''
      ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
      ||  '  END ' -- 賞味期限
      ||  ', xsi.proper_mark  '                                                                                          -- 固有記号
      ||  ', xsi.invent_date  '                                                                                          -- 棚卸日--2008/05/02
      ;
-- 2008/12/06 H.Itou Mod End
    ELSE
      lv_sql  :=  lv_sql
      ||  ', xsi.lot_no  '         --ロットNo
      ||  ', xsi.invent_date  ';   --棚卸日
    END IF;
--
    BEGIN
-- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
--      EXECUTE  IMMEDIATE lv_sql INTO  ln_cnt;
      --品目区分が製品の場合
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        EXECUTE  IMMEDIATE lv_sql INTO  ln_cnt
        USING if_rec.request_id       -- 要求ID
             ,if_rec.report_post_code -- 報告部署
             ,if_rec.invent_whse_code -- 棚卸倉庫
             ,if_rec.invent_seq       -- 棚卸連番
             ,if_rec.item_code        -- 品目
-- 2008/12/06 H.Itou Mod Start
--             ,if_rec.maker_date       -- 製造日
--             ,if_rec.limit_date       -- 賞味期限
             ,CASE
                WHEN if_rec.maker_date IS NULL THEN '*'  -- NULLならダミーコード
                WHEN if_rec.maker_date = '0'   THEN '0'  -- 0なら0のまま
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.maker_date, gc_char_d_format), gc_char_d_format), if_rec.maker_date) -- 正しいフォーマットの場合、日付変換してチェック
              END -- 製造日
             ,CASE
                WHEN if_rec.limit_date IS NULL THEN '*'  -- NULLならダミーコード
                WHEN if_rec.limit_date = '0'   THEN '0'  -- 0なら0のまま
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.limit_date, gc_char_d_format), gc_char_d_format), if_rec.limit_date) -- 正しいフォーマットの場合、日付変換してチェック
              END -- 賞味期限
-- 2008/12/06 H.Itou Mod End
             ,if_rec.proper_mark      -- 固有記号
             ,if_rec.invent_date      -- 棚卸日
        ;
--
      --品目区分が製品以外
      ELSE
        EXECUTE  IMMEDIATE lv_sql INTO  ln_cnt
        USING if_rec.request_id       -- 要求ID
             ,if_rec.report_post_code -- 報告部署
             ,if_rec.invent_whse_code -- 棚卸倉庫
             ,if_rec.invent_seq       -- 棚卸連番
             ,if_rec.item_code        -- 品目
             ,if_rec.lot_no           -- ロットNo
             ,if_rec.invent_date      -- 棚卸日
        ;
      END IF;
-- 2008/09/04 H.Itou Mod End
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_cnt :=  0;
    END;
    IF  (ln_cnt  > 1)  THEN
      ib_dup_sts := FALSE;
    END IF;
--
    -- 異なる要求ID配下での重複チェック
    IF  (ib_dup_sts != FALSE) THEN
      lv_sql  :=
        'SELECT '
        ||  'MAX(xsi.request_id)  maxt_id, ' -- 最新要求ID
        ||  'COUNT(xsi.report_post_code) cnt '      -- カウント
        ||  'FROM  xxinv_stc_inventory_interface xsi '  -- 1.棚卸データインタフェース
        ||  'WHERE '
-- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
--        ||  '      xsi.report_post_code  = '''  ||  if_rec.report_post_code  || '''' -- 報告部署
--        ||  '  AND xsi.invent_whse_code  = '''  ||  if_rec.invent_whse_code  || '''' -- 棚卸倉庫
--        ||  '  AND xsi.invent_seq        = '''  ||  if_rec.invent_seq        || '''' -- 棚卸連番
--        ||  '  AND xsi.item_code         = '''  ||  if_rec.item_code         || '''';-- 品目
        ||  '      xsi.report_post_code  = :report_post_code  ' -- 報告部署
        ||  '  AND xsi.invent_whse_code  = :invent_whse_code  ' -- 棚卸倉庫
--2008/12/11 mod start
--        ||  '  AND xsi.invent_seq        = :invent_seq        ' -- 棚卸連番
        ||  '  AND TO_NUMBER(xsi.invent_seq) = TO_NUMBER(:invent_seq) ' -- 棚卸連番
--2008/12/11 mod end
        ||  '  AND xsi.item_code         = :item_code         ';-- 品目
-- 2008/09/04 H.Itou Mod End
--
      --品目区分が製品の場合
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
---- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
----        ||  '  AND xsi.maker_date  = '''  ||  if_rec.maker_date   || ''''  --製造日
----        ||  '  AND xsi.limit_date  = '''  ||  if_rec.limit_date   || ''''  --賞味期限
----        ||  '  AND xsi.proper_mark = '''  ||  if_rec.proper_mark  || ''''  --固有記号
----        --2008/5/02(レビューNo2)
----        ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
----                            TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--棚卸日
--        ||  '  AND xsi.maker_date,  = :maker_date   '  -- 製造日
--        ||  '  AND xsi.limit_date  = :limit_date   '  -- 賞味期限
--        ||  '  AND xsi.proper_mark = :proper_mark  '  -- 固有記号
--        ||  '  AND xsi.invent_date = :invent_date  '; -- 棚卸日
---- 2008/09/04 H.Itou Mod End
        ||  '  AND CASE '
        ||  '         WHEN xsi.maker_date IS NULL   THEN ''*'''
        ||  '         WHEN xsi.maker_date = ''0''   THEN ''0'''
        ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
        ||  '      END = :maker_date ' -- 製造日
        ||  '  AND CASE '
        ||  '         WHEN xsi.limit_date IS NULL   THEN ''*'''
        ||  '         WHEN xsi.limit_date = ''0''   THEN ''0'''
        ||  '         ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
        ||  '      END = :limit_date '-- 賞味期限
        ||  '  AND xsi.proper_mark = :proper_mark  '                                                                             -- 固有記号
        ||  '  AND xsi.invent_date = :invent_date  '                                                                             -- 棚卸日
        ;
-- 2008/12/06 H.Itou Mod End
      --品目区分が製品以外
      ELSE
        lv_sql  :=  lv_sql
-- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
--        ||  '  AND xsi.lot_no      = '''  ||  if_rec.lot_no  || '''' --ロットNo
--        ||  '  AND TO_CHAR(xsi.invent_date ,''' || gc_char_d_format || '' || ''')  = '''  ||
--                            TO_CHAR( if_rec.invent_date, gc_char_d_format) || '''';--棚卸日
        ||  '  AND xsi.lot_no      = :lot_no       '  --ロットNo
        ||  '  AND xsi.invent_date = :invent_date  '; -- 棚卸日
-- 2008/09/04 H.Itou Mod End
      END IF;
--
      lv_sql  :=  lv_sql
        ||  ' GROUP BY '
        ||  ' xsi.report_post_code  '    -- 報告部署
        ||  ',xsi.invent_whse_code  '    -- 棚卸倉庫
--2008/12/11 mod start
--        ||  ',xsi.invent_seq  '          -- 棚卸連番
        ||  ',TO_NUMBER(xsi.invent_seq)  ' -- 棚卸連番
--2008/12/11 mod end
        ||  ',xsi.item_code  ';          -- 品目
--
      --品目区分が製品の場合
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        lv_sql  :=  lv_sql
-- 2008/12/06 H.Itou Mod Start
--        ||  ', xsi.maker_date  '     --製造日
--        ||  ', xsi.limit_date  '     --賞味期限
--        ||  ', xsi.proper_mark  '     --固有記号
--        ||  ', xsi.invent_date  ';   --棚卸日--2008/05/02
        ||  ', CASE '
        ||  '    WHEN xsi.maker_date IS NULL   THEN ''*'''
        ||  '    WHEN xsi.maker_date = ''0''   THEN ''0'''
        ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.maker_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.maker_date) '
        ||  '  END ' -- 製造日
        ||  ', CASE '
        ||  '    WHEN xsi.limit_date IS NULL   THEN ''*'''
        ||  '    WHEN xsi.limit_date = ''0''   THEN ''0'''
        ||  '    ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(xsi.limit_date, ''' || gc_char_d_format || '''), ''' || gc_char_d_format || '''), xsi.limit_date) '
        ||  '  END ' -- 賞味期限
        ||  ', xsi.proper_mark  '                                                             -- 固有記号
        ||  ', xsi.invent_date  '                                                             -- 棚卸日--2008/05/02
        ;
-- 2008/12/06 H.Itou Mod End
      ELSE
        lv_sql  :=  lv_sql
        ||  ', xsi.lot_no  '         --ロットNo
        ||  ', xsi.invent_date  ';   --棚卸日
      END IF;
--
      BEGIN
-- 2008/09/04 H.Itou Mod Start PT 6-3_39指摘#12 バインド変数に変更
--        EXECUTE  IMMEDIATE lv_sql
--          INTO  ln_request_id, ln_cnt;
      --品目区分が製品の場合
      IF  (iv_item_typ   = gv_item_cls_prdct) THEN
        EXECUTE  IMMEDIATE lv_sql INTO  ln_request_id, ln_cnt
        USING if_rec.report_post_code -- 報告部署
             ,if_rec.invent_whse_code -- 棚卸倉庫
             ,if_rec.invent_seq       -- 棚卸連番
             ,if_rec.item_code        -- 品目
-- 2008/12/06 H.Itou Mod Start
--             ,if_rec.maker_date       -- 製造日
--             ,if_rec.limit_date       -- 賞味期限
             ,CASE
                WHEN if_rec.maker_date IS NULL THEN '*'  -- NULLならダミーコード
                WHEN if_rec.maker_date = '0'   THEN '0'  -- 0なら0のまま
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.maker_date, gc_char_d_format), gc_char_d_format), if_rec.maker_date) -- 正しいフォーマットの場合、日付変換してチェック
              END -- 製造日
             ,CASE
                WHEN if_rec.limit_date IS NULL THEN '*'  -- NULLならダミーコード
                WHEN if_rec.limit_date = '0'   THEN '0'  -- 0なら0のまま
                ELSE NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(if_rec.limit_date, gc_char_d_format), gc_char_d_format), if_rec.limit_date) -- 正しいフォーマットの場合、日付変換してチェック
              END -- 賞味期限
-- 2008/12/06 H.Itou Mod End
             ,if_rec.proper_mark      -- 固有記号
             ,if_rec.invent_date      -- 棚卸日
        ;
--
      --品目区分が製品以外
      ELSE
        EXECUTE  IMMEDIATE lv_sql INTO  ln_request_id, ln_cnt
        USING if_rec.report_post_code -- 報告部署
             ,if_rec.invent_whse_code -- 棚卸倉庫
             ,if_rec.invent_seq       -- 棚卸連番
             ,if_rec.item_code        -- 品目
             ,if_rec.lot_no           -- ロットNo
             ,if_rec.invent_date      -- 棚卸日
        ;
      END IF;
-- 2008/09/04 H.Itou Mod End
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_request_id :=  0;
          ln_cnt :=  0;
      END;
--
      IF  (ln_cnt  > 1)  THEN
        --（最新要求IDではない）削除対象となるがエラーとしない
        If  (if_rec.request_id  <  ln_request_id)  THEN
          ib_dup_sts     := FALSE;
          ib_dup_del_sts := TRUE;
        END IF;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
  END proc_duplication_chk;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_table_data
   * Description      : 対象データ削除(A-7)
   ***********************************************************************************/
  PROCEDURE proc_del_table_data(
    lrec_data     IN  cursor_rec,
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
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;     -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;-- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt  NUMBER  DEFAULT 0;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ROWID PL/SQL表型
    TYPE work_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    work_rowid work_rowid_type;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- deleteデータROWID取得
    <<delete_loop>>
    FOR i IN 1..inv_if_rec.COUNT LOOP
      --保留データ以外すべて抽出
      IF  (inv_if_rec(i).sts != gv_sts_hr)  THEN
        ln_cnt  := ln_cnt  + 1;
        work_rowid(ln_cnt) := inv_if_rec(i).rowid_work;
        CASE (inv_if_rec(i).sts)
          WHEN (gv_sts_ng) THEN
            gn_error_cnt := gn_error_cnt + 1;    -- エラー件数加算
          ELSE
            gn_normal_cnt := gn_normal_cnt + 1;  -- 正常データ件数加算
        END CASE;
      ELSE
        gn_warn_cnt := gn_warn_cnt + 1;   --保留データ件数加算
      END IF;
    END LOOP delete_loop;
--
    -- ========================================
    -- 棚卸データインターフェーステーブル削除 =
    -- ========================================
    FORALL i IN 1..work_rowid.COUNT
      DELETE xxinv_stc_inventory_interface xsihw
      WHERE  ROWID = work_rowid(i);
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
  END proc_del_table_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_table_batch
   * Description      : 棚卸結果登録処理(A-6)
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
--
    -- *** ローカル変数 ***
    ln_val        NUMBER DEFAULT 0;  -- 棚卸結果IDの連番
    ln_ins_cnt    NUMBER DEFAULT 0;  -- 登録件数カウント
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
    <<insert_loop>>
    FOR i IN 1 .. inv_if_rec.COUNT LOOP
      --ステータス＝登録（INS)のみ対象とする
      IF  (inv_if_rec(i).sts = gv_sts_ins)  THEN
        ln_ins_cnt  := ln_ins_cnt  + 1;
--
        -- 棚卸結果IDの連番取得
        SELECT xxinv_stc_invt_rslt_s1.NEXTVAL
        INTO   ln_val
        FROM   DUAL;
        -- 棚卸結果ID
        ltbl_xsir(ln_ins_cnt).invent_result_id := ln_val;
        -- 報告部署
        ltbl_xsir(ln_ins_cnt).report_post_code := inv_if_rec(i).report_post_code;
        -- 棚卸日
        ltbl_xsir(ln_ins_cnt).invent_date      := inv_if_rec(i).invent_date;
        -- 棚卸倉庫
        ltbl_xsir(ln_ins_cnt).invent_whse_code := inv_if_rec(i).invent_whse_code;
        -- 棚卸連番
        ltbl_xsir(ln_ins_cnt).invent_seq       := inv_if_rec(i).invent_seq;
        -- 品目ID
        ltbl_xsir(ln_ins_cnt).item_id          := inv_if_rec(i).item_id;
        -- 品目
        ltbl_xsir(ln_ins_cnt).item_code        := inv_if_rec(i).item_code;
        -- ロットID
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- 製品
            ltbl_xsir(ln_ins_cnt).lot_id := inv_if_rec(i).lot_id;
          ELSE
            -- 製品以外
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ロット管理
                ltbl_xsir(ln_ins_cnt).lot_id := inv_if_rec(i).lot_id;
              ELSE
                -- ロット管理対象外
                ltbl_xsir(ln_ins_cnt).lot_id := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- ロットNo
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- 製品
            ltbl_xsir(ln_ins_cnt).lot_no := inv_if_rec(i).lot_no1;
          ELSE
            -- 製品以外
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ロット管理
                ltbl_xsir(ln_ins_cnt).lot_no := inv_if_rec(i).lot_no;
              ELSE
                -- ロット管理対象外
                ltbl_xsir(ln_ins_cnt).lot_no := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- 製造日
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- 製品
-- 2008/12/06 H.Itou Add Start
--            ltbl_xsir(ln_ins_cnt).maker_date := inv_if_rec(i).maker_date;
            ltbl_xsir(ln_ins_cnt).maker_date := inv_if_rec(i).maker_date1;
-- 2008/12/06 H.Itou Add End
          ELSE
            -- 製品以外
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ロット管理
                ltbl_xsir(ln_ins_cnt).maker_date := inv_if_rec(i).maker_date1;
              ELSE
                -- ロット管理対象外
                ltbl_xsir(ln_ins_cnt).maker_date := NULL;--2008/05/08
             END CASE;
        END CASE;
        -- 賞味期限
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- 製品
            ltbl_xsir(ln_ins_cnt).limit_date := inv_if_rec(i).limit_date;
          ELSE
            -- 製品以外
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ロット管理
                ltbl_xsir(ln_ins_cnt).limit_date := inv_if_rec(i).limit_date1;
              ELSE
                -- ロット管理対象外
                ltbl_xsir(ln_ins_cnt).limit_date := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- 固有記号
        CASE (inv_if_rec(i).item_type)
          WHEN (gv_item_cls_prdct) THEN
            -- 製品
            ltbl_xsir(ln_ins_cnt).proper_mark :=  inv_if_rec(i).proper_mark;
          ELSE
            -- 製品以外
            CASE (inv_if_rec(i).lot_ctl)
              WHEN (gn_y) THEN
                -- ロット管理
                ltbl_xsir(ln_ins_cnt).proper_mark :=  inv_if_rec(i).proper_mark1;
              ELSE
                -- ロット管理対象外
                ltbl_xsir(ln_ins_cnt).proper_mark := NULL;--2008/05/08
            END CASE;
        END CASE;
        -- 棚卸ケース数
        ltbl_xsir(ln_ins_cnt).case_amt         := inv_if_rec(i).case_amt;
        -- 入数
        ltbl_xsir(ln_ins_cnt).content          := inv_if_rec(i).content;
        -- 棚卸バラ
        ltbl_xsir(ln_ins_cnt).loose_amt        := inv_if_rec(i).loose_amt;
        -- ロケーション
        ltbl_xsir(ln_ins_cnt).location         := inv_if_rec(i).location;
        -- ラックNo１
        ltbl_xsir(ln_ins_cnt).rack_no1         := inv_if_rec(i).rack_no1;
        -- ラックNo２
        ltbl_xsir(ln_ins_cnt).rack_no2         := inv_if_rec(i).rack_no2;
        -- ラックNo３
        ltbl_xsir(ln_ins_cnt).rack_no3         := inv_if_rec(i).rack_no3;
-- 2008/12/06 H.Itou Add Start 本番障害#510 日付書式を合わせるため、一度TO_DATEする。
        -- 製造日
        IF (ltbl_xsir(ln_ins_cnt).maker_date <> '0') THEN
          ltbl_xsir(ln_ins_cnt).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_ins_cnt).maker_date, gc_char_d_format), gc_char_d_format);
        END IF;
--
        -- 賞味期限
        IF (ltbl_xsir(ln_ins_cnt).limit_date <> '0') THEN
          ltbl_xsir(ln_ins_cnt).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(ltbl_xsir(ln_ins_cnt).limit_date, gc_char_d_format), gc_char_d_format);
        END IF;
-- 2008/12/06 H.Itou Add End
        -- WHO情報
        ltbl_xsir(ln_ins_cnt).created_by             := gn_user_id;
        ltbl_xsir(ln_ins_cnt).creation_date          := gd_sysdate;
        ltbl_xsir(ln_ins_cnt).last_updated_by        := gn_user_id;
        ltbl_xsir(ln_ins_cnt).last_update_date       := gd_sysdate;
        ltbl_xsir(ln_ins_cnt).last_update_login      := gn_user_id;
        ltbl_xsir(ln_ins_cnt).request_id             := gn_request_id;
        ltbl_xsir(ln_ins_cnt).program_application_id := gn_program_appl_id;
        ltbl_xsir(ln_ins_cnt).program_id             := gn_program_id;
        ltbl_xsir(ln_ins_cnt).program_update_date    := gd_sysdate;
      END IF;
    END LOOP  insert_loopl;
--
    -- ===============================
    -- 棚卸結果テーブル一括挿入
    -- ===============================
    FORALL i in 1..ltbl_xsir.COUNT
      INSERT INTO xxinv_stc_inventory_result VALUES ltbl_xsir(i);
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
  /**********************************************************************************
   * Procedure Name   : proc_upd_table_batch
   * Description      : 棚卸結果更新処理(A-5)
   ***********************************************************************************/
  PROCEDURE proc_upd_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_table_batch'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
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
    CURSOR lcur_xxinv_stc_inv_result_pt(
      if_rec xxinv_stc_inv_if_rec)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
      WHERE  xsir.invent_seq       = if_rec.invent_seq       -- 棚卸連番
      AND    xsir.invent_whse_code = if_rec.invent_whse_code -- 棚卸倉庫
      AND    xsir.report_post_code = if_rec.report_post_code -- 報告部署
      AND    xsir.item_code        = if_rec.item_code        -- 品目
      AND    xsir.invent_date      = if_rec.invent_date      -- 棚卸日
-- 2008/12/06 H.Itou Mod Start
--      AND    xsir.maker_date       = if_rec.maker_date       -- 製造日
--      AND    xsir.limit_date       = if_rec.limit_date       -- 賞味期限
      AND    NVL(xsir.maker_date, '*') = NVL(if_rec.maker_date1, '*') -- 製造日
      AND    NVL(xsir.limit_date, '*') = NVL(if_rec.limit_date, '*')  -- 賞味期限
-- 2008/12/06 H.Itou Mod End
      AND    xsir.proper_mark      = if_rec.proper_mark      -- 固有記号
      FOR UPDATE NOWAIT;
--
    -- 棚卸結果テーブル(品目区分が製品以外)ロット管理対象
    CURSOR lcur_xxinv_stc_inv_result_npt(
      if_rec xxinv_stc_inv_if_rec)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
      WHERE  xsir.invent_seq       = if_rec.invent_seq       -- 棚卸連番
      AND    xsir.invent_whse_code = if_rec.invent_whse_code -- 棚卸倉庫
      AND    xsir.report_post_code = if_rec.report_post_code -- 報告部署
      AND    xsir.item_code        = if_rec.item_code        -- 品目
      AND    xsir.invent_date      = if_rec.invent_date      -- 棚卸日
      AND    xsir.lot_id           = if_rec.lot_id           -- ロットID
      FOR UPDATE NOWAIT;
--
    -- 棚卸結果テーブル(品目区分が製品以外)ロット管理対象外
    CURSOR lcur_xxinv_stc_inv_result_nnpt(
      if_rec xxinv_stc_inv_if_rec)
    IS
      SELECT xsir.ROWID
      FROM   xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
      WHERE  xsir.invent_seq       = if_rec.invent_seq       -- 棚卸連番
      AND    xsir.invent_whse_code = if_rec.invent_whse_code -- 棚卸倉庫
      AND    xsir.report_post_code = if_rec.report_post_code -- 報告部署
      AND    xsir.item_code        = if_rec.item_code        -- 品目
      AND    xsir.invent_date      = if_rec.invent_date      -- 棚卸日
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
    FOR i IN 1 .. inv_if_rec.COUNT LOOP
--
      lr_rowid := NULL;
-- 2008/12/06 H.Itou Add Start 本番障害#510 日付書式を合わせるため、一度TO_DATEする。
      -- 製造日
      IF (inv_if_rec(i).maker_date <> '0') THEN
        inv_if_rec(i).maker_date := TO_CHAR(FND_DATE.STRING_TO_DATE(inv_if_rec(i).maker_date, gc_char_d_format), gc_char_d_format);
      END IF;
--
      -- 賞味期限
      IF (inv_if_rec(i).limit_date <> '0') THEN
        inv_if_rec(i).limit_date := TO_CHAR(FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format), gc_char_d_format);
      END IF;
-- 2008/12/06 H.Itou Add End
      BEGIN
        IF  (inv_if_rec(i).sts  = gv_sts_ok) THEN--正常データのみ
            -- 品目区分が製品
          IF (inv_if_rec(i).item_type = gv_item_cls_prdct) THEN
--
            OPEN  lcur_xxinv_stc_inv_result_pt(
              inv_if_rec(i));               -- ロック取得カーソルOPEN
            FETCH lcur_xxinv_stc_inv_result_pt INTO lr_rowid;
--
            IF (lcur_xxinv_stc_inv_result_pt%NOTFOUND) THEN
              inv_if_rec(i).sts := gv_sts_ins; -- 正常データ挿入
            ELSE
              ln_upd_cnt := ln_upd_cnt + 1;
              UPDATE xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
              SET    xsir.case_amt               = inv_if_rec(i).case_amt  -- 棚卸ケース数
                    ,xsir.content                = inv_if_rec(i).content   -- 入数
                    ,xsir.loose_amt              = inv_if_rec(i).loose_amt -- 棚卸バラ
                    ,xsir.location               = inv_if_rec(i).location  -- ロケーション
                    ,xsir.rack_no1               = inv_if_rec(i).rack_no1  -- ラックNo１
                    ,xsir.rack_no2               = inv_if_rec(i).rack_no2  -- ラックNo２
                    ,xsir.rack_no3               = inv_if_rec(i).rack_no3  -- ラックNo３
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
            CLOSE lcur_xxinv_stc_inv_result_pt; -- ロック取得カーソルCLOSE
--
            -- 品目区分が製品以外かつロット管理対象
          ELSE
            IF (inv_if_rec(i).lot_ctl = gn_y )  THEN
--
              OPEN  lcur_xxinv_stc_inv_result_npt(
                inv_if_rec(i));        -- ロック取得カーソルOPEN
--
              FETCH lcur_xxinv_stc_inv_result_npt INTO lr_rowid;
--
              IF (lcur_xxinv_stc_inv_result_npt%NOTFOUND) THEN
                inv_if_rec(i).sts := gv_sts_ins; -- 正常データ挿入
              ELSE
                ln_upd_cnt := ln_upd_cnt + 1;
                UPDATE xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
                SET    xsir.case_amt               = inv_if_rec(i).case_amt  -- 棚卸ケース数
                      ,xsir.content                = inv_if_rec(i).content   -- 入数
                      ,xsir.loose_amt              = inv_if_rec(i).loose_amt -- 棚卸バラ
                      ,xsir.location               = inv_if_rec(i).location  -- ロケーション
                      ,xsir.rack_no1               = inv_if_rec(i).rack_no1  -- ラックNo１
                      ,xsir.rack_no2               = inv_if_rec(i).rack_no2  -- ラックNo２
                      ,xsir.rack_no3               = inv_if_rec(i).rack_no3  -- ラックNo３
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
              CLOSE lcur_xxinv_stc_inv_result_npt; -- ロック取得カーソルCLOSE
            ELSE
              -- 品目区分が製品以外かつロット管理対象外
              OPEN  lcur_xxinv_stc_inv_result_nnpt(
                inv_if_rec(i));        -- ロック取得カーソルOPEN
--
              FETCH lcur_xxinv_stc_inv_result_nnpt INTO lr_rowid;
--
              IF (lcur_xxinv_stc_inv_result_nnpt%NOTFOUND) THEN
                inv_if_rec(i).sts := gv_sts_ins; -- 正常データ挿入
              ELSE
                ln_upd_cnt := ln_upd_cnt + 1;
                UPDATE xxinv_stc_inventory_result xsir -- 棚卸結果テーブル
                SET    xsir.case_amt               = inv_if_rec(i).case_amt  -- 棚卸ケース数
                      ,xsir.content                = inv_if_rec(i).content   -- 入数
                      ,xsir.loose_amt              = inv_if_rec(i).loose_amt -- 棚卸バラ
                      ,xsir.location               = inv_if_rec(i).location  -- ロケーション
                      ,xsir.rack_no1               = inv_if_rec(i).rack_no1  -- ラックNo１
                      ,xsir.rack_no2               = inv_if_rec(i).rack_no2  -- ラックNo２
                      ,xsir.rack_no3               = inv_if_rec(i).rack_no3  -- ラックNo３
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
              CLOSE lcur_xxinv_stc_inv_result_nnpt; -- ロック取得カーソルCLOSE
            END IF;
          END IF;
        END IF;
--
      EXCEPTION
        WHEN lock_expt THEN -- ロック取得エラー ***
          -- カーソルをCLOSE(製品)
          IF (lcur_xxinv_stc_inv_result_pt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_result_pt;
          END IF;
          -- カーソルをCLOSE(製品以外)
          IF (lcur_xxinv_stc_inv_result_npt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_result_npt;
          END IF;
          -- カーソルをCLOSE(製品以外)
          IF (lcur_xxinv_stc_inv_result_nnpt%ISOPEN) THEN
            CLOSE lcur_xxinv_stc_inv_result_nnpt;
          END IF;
          -- エラーメッセージ取得
          lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                         gv_xxcmn
                        ,'APP-XXCMN-10019'
                        ,'TABLE'
                        ,gv_inv_result_name
                        ),1,5000);
          RAISE global_api_expt;
      END;
--
    END LOOP upd_table_batch_loop;
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
      -- カーソルをCLOSE(製品)
      IF (lcur_xxinv_stc_inv_result_pt%ISOPEN) THEN
        CLOSE lcur_xxinv_stc_inv_result_pt;
      END IF;
      -- カーソルをCLOSE(製品以外)
      IF (lcur_xxinv_stc_inv_result_npt%ISOPEN) THEN
        CLOSE lcur_xxinv_stc_inv_result_npt;
      END IF;
      -- カーソルをCLOSE(製品以外)
      IF (lcur_xxinv_stc_inv_result_nnpt%ISOPEN) THEN
        CLOSE lcur_xxinv_stc_inv_result_nnpt;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : proc_master_data_chk
   * Description      : 妥当性チェック(A-4)
   ***********************************************************************************/
  PROCEDURE proc_master_data_chk(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ
    ov_retcode    OUT VARCHAR2,     --   リターン・コード
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_master_data_chk'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_dupretcd VARCHAR2(1)      DEFAULT NULL;  -- リターン・コード(重複チェック用)
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_item_id        xxcmn_item_mst_v.item_id          %TYPE DEFAULT NULL; --品目ID
    ln_lot_ctl        xxcmn_item_mst_v.lot_ctl          %TYPE DEFAULT 0;    --ロット
    lv_num_of_cases   xxcmn_item_mst_v.num_of_cases     %TYPE DEFAULT NULL; --ケース入数D
    ln_lot_id         ic_lots_mst.lot_id                %TYPE DEFAULT NULL; --ロットID
    lv_lot_no         ic_lots_mst.lot_no                %TYPE DEFAULT NULL; --ロット№
    lv_maker_date     ic_lots_mst.attribute1            %TYPE DEFAULT NULL; --製造日
    lv_proper_mark     ic_lots_mst.attribute2           %TYPE DEFAULT NULL; --固有期限
    lv_limit_date     ic_lots_mst.attribute3            %TYPE DEFAULT NULL; --賞味期限
    lv_item_type      xxcmn_item_categories2_v.segment1 %TYPE DEFAULT NULL; --品目区分
    lv_product_type   xxcmn_item_categories2_v.segment1 %TYPE DEFAULT NULL; --商品区分
    lv_whse_code      ic_whse_mst.whse_code             %TYPE DEFAULT NULL; --倉庫コード
    lb_dump_flag                                        BOOLEAN DEFAULT FALSE; -- エラーフラグ
    lv_dump                                             VARCHAR2(5000) DEFAULT NULL;--データダンプ
    lv_msg_col                                          VARCHAR2(100)  DEFAULT NULL;--項目名引数
    lb_dup_sts                                          BOOLEAN DEFAULT FALSE; -- 重複チェック結果
    lb_dup_del_sts                                   BOOLEAN DEFAULT FALSE; -- 重複削除チェック結果
    ld_maker_date                                       DATE  DEFAULT NULL;--製造日チェック用
    ld_limit_date                                       DATE  DEFAULT NULL;--賞味期限チェック用
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
    lv_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<process_loop>>
    FOR i IN 1..inv_if_rec.COUNT LOOP
      --データダンプフラグ初期化
      lb_dump_flag  := FALSE;
--
-- 2008/12/06 H.Itou Del Start 品目区分を取得してから重複チェックを行うので、最後に移動
--      -- ===========================================
--      -- 重複チェック                              =
--      -- ===========================================
--      proc_duplication_chk(
--        if_rec      => inv_if_rec(i)  -- 1.棚卸インターフェース
--       ,iv_item_typ => lv_item_type   -- 2.データダンプ文字列
--       ,ib_dup_sts  => lb_dup_sts     -- 3.重複チェック結果
--       ,ib_dup_del_sts => lb_dup_del_sts -- 4.重複削除チェック結果
--       ,ov_errbuf   => lv_errbuf
--       ,ov_retcode  => lv_dupretcd
--       ,ov_errmsg   => lv_errmsg);
--      -- エラーの場合
--      IF (lv_dupretcd = gv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
----
--      IF  (lb_dup_sts  = FALSE) THEN
--        IF (lb_dup_del_sts = TRUE) THEN
--          inv_if_rec(i).sts  :=  gv_sts_del;  --重複削除
--        ELSE
--          inv_if_rec(i).sts  :=  gv_sts_ng;  --重複エラー 4,6
--        END IF;
--        IF  ((lb_dump_flag  = FALSE) AND (lb_dup_del_sts = FALSE)) THEN -- 重複削除はエラーとしない
--          --データダンプ取得
--          proc_get_data_dump(
--            if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
--           ,ov_dump    => lv_dump        -- 2.データダンプ文字列
--           ,ov_errbuf  => lv_errbuf
--           ,ov_retcode => lv_retcode
--           ,ov_errmsg  => lv_errmsg);
--          -- エラーの場合
--          IF (lv_retcode = gv_status_error) THEN
--            RAISE global_api_expt;
--          ELSE
--            lv_retcode  := gv_status_warn;
--          END IF;
--          -- 警告データダンプPL/SQL表投入
--          gn_err_msg_cnt := gn_err_msg_cnt + 1;
--          warn_dump_tab(gn_err_msg_cnt) := lv_dump;
--          lb_dump_flag :=  TRUE;
--        END IF;
----
--        IF (lb_dup_del_sts = FALSE) THEN -- 重複削除はエラーとしない
--          -- 警告エラーメッセージ取得 (同一ファイル内に重複データが存在します。)
--          lv_errmsg := xxcmn_common_pkg.get_msg(
--                        iv_application  => gv_xxinv,
--                        iv_name         => 'APP-XXINV-10101');
----
--          -- 警告メッセージPL/SQL表投入
--          gn_err_msg_cnt := gn_err_msg_cnt + 1;
--          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--        END IF;
----
--      END IF;
-- 2008/12/06 H.Itou Del End
--
-- 2008/12/06 H.Itou Del Start
--      IF (lb_dup_del_sts != true) THEN
-- 2008/12/06 H.Itou Del End
        -- ===============================
        -- 品目マスタチェック(OPM品目マスタに存在するかチェックします。）
        -- ===============================
        BEGIN
--
          SELECT  itm.item_id item_id,
                  itm.lot_ctl lot_ctl,
                  itm.num_of_cases  num_of_cases,
                  icmt.item_class_code item_type,
                  icmt.prod_class_code product_type
          INTO    ln_item_id,       --品目ID
                  ln_lot_ctl,       --ロット
                  lv_num_of_cases,  --ケース入数
                  lv_item_type,     --品目区分
                  lv_product_type   --商品区分
--
          FROM  xxcmn_item_mst_v itm,                   -- 1.OPM品目マスタ(有効期限のみ)
                xxcmn_item_categories5_v icmt           -- 5.品目カテゴリ、セット
--
          WHERE itm.item_no = inv_if_rec(i).item_code
            AND icmt.item_id = itm.item_id;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_item_id      :=  NULL;   --品目ID
            ln_lot_ctl      :=  NULL;   --ロット
            lv_num_of_cases :=  NULL;   --ケース入数
            lv_item_type    :=  NULL;   --品目区分
            lv_product_type :=  NULL;   --商品区分
            lb_dump_flag    :=  TRUE;
            inv_if_rec(i).sts  :=  gv_sts_ng;  --品目マスタ未登録エラー 2
            --データダンプ取得
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
--
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
--
        -- 警告エラーメッセージ取得(該当データがマスタに存在しません。(マスタ：TABLE，項目：OBJECT)
            lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxinv,
                          iv_name         => 'APP-XXINV-10102',
                          iv_token_name1  => 'TABLE',
                          iv_token_value1 => gv_opm_item_name,
                          iv_token_name2  => 'OBJECT',
                          iv_token_value2 => inv_if_rec(i).item_code);
--
            -- 警告メッセージPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END;
--
        -- ============================================
        -- OPM倉庫マスタに存在するかチェックします。  =
        -- ============================================
        BEGIN
          SELECT  iwm.whse_code
          INTO    lv_whse_code  --倉庫コード
          FROM  ic_whse_mst iwm -- 1.OPM倉庫マスタ
          WHERE iwm.whse_code = inv_if_rec(i).invent_whse_code
            AND ROWNUM  = 1;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            inv_if_rec(i).sts  :=  gv_sts_ng;  --倉庫マスタ未登録エラー 8
            --データダンプ取得
            IF  (lb_dump_flag  = FALSE)  THEN
              proc_get_data_dump(
                if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
               ,ov_dump    => lv_dump        -- 2.データダンプ文字列
               ,ov_errbuf  => lv_errbuf
               ,ov_retcode => lv_retcode
               ,ov_errmsg  => lv_errmsg);
              -- エラーの場合
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_api_expt;
              ELSE
                lv_retcode  := gv_status_warn;
              END IF;
              -- 警告データダンプPL/SQL表投入
              gn_err_msg_cnt := gn_err_msg_cnt + 1;
              warn_dump_tab(gn_err_msg_cnt) := lv_dump;
              lb_dump_flag :=  TRUE;
            END IF;
--
        -- 警告エラーメッセージ取得(該当データがマスタに存在しません。(マスタ：TABLE，項目：OBJECT)
            lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxinv,
                          iv_name         => 'APP-XXINV-10102',
                          iv_token_name1  => 'TABLE',
                          iv_token_value1 => gv_invent_whse_name,
                          iv_token_name2  => 'OBJECT',
                          iv_token_value2 => inv_if_rec(i).invent_whse_code);
            -- 警告メッセージPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END;
--
--
    --  品目マスタが存在する場合のみチェックする(4-904-30)
        IF  (lv_item_type IS  NOT NULL) THEN
          -- ===============================
          -- ロット№マスタに存在するかチェック
          -- ===============================
      --
          --品目区分が製品以外の場合
          IF (lv_item_type != gv_item_cls_prdct) THEN
            --ロット管理対象の場合
            IF  (ln_lot_ctl  = 1) THEN
              -- ロット№が'0'はエラーとする。
              IF  (inv_if_rec(i).lot_no = '0' ) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --ロット№が'0'はエラーとする。10
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0以外を指定してください。(項目：OBJECT←ロット№）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_lot_no_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --ロットマスタチェック
              BEGIN
                SELECT  lot.lot_id lot_id           --ロットID
                        ,lot.attribute1 maker_date  --製造日
                        ,lot.attribute2 proper_mark --固有記号
                        ,lot.attribute3 limit_date  --賞味期限
                INTO     ln_lot_id
                        ,lv_maker_date
                        ,lv_proper_mark
                        ,lv_limit_date
                FROM  ic_lots_mst lot -- 1.OPMロットマスタ
                WHERE lot.lot_no = inv_if_rec(i).lot_no
                  AND lot.item_id = ln_item_id
                  AND ROWNUM  = 1;
--
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                    inv_if_rec(i).sts  :=  gv_sts_hr;  --ロットマスタ未登録エラー(保留)  12
                  END IF;
                  --データダンプ取得
                  IF  (lb_dump_flag  = FALSE)  THEN
                    proc_get_data_dump(
                      if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                     ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                     ,ov_errbuf  => lv_errbuf
                     ,ov_retcode => lv_retcode
                     ,ov_errmsg  => lv_errmsg);
                    -- エラーの場合
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_api_expt;
                    ELSE
                      lv_retcode  := gv_status_warn;
                    END IF;
                    -- 警告データダンプPL/SQL表投入
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                    lb_dump_flag :=  TRUE;
                  END IF;
--
            -- 警告エラーメッセージ取得(OPMロットマスタに該当データが存在しません。(項目：OBJECT))
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10108',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_lot_no_col);
                  -- 警告メッセージPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END;
            --ロット管理対象外の場合
            ELSIF (ln_lot_ctl  != 1)  THEN
              -- ロット№が'0'以外はエラーとする。
              IF  (inv_if_rec(i).lot_no != '0' ) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --ロット№が'0'以外はエラーとする。14
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 ( 0を指定してください。(項目：OBJECT) )
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_lot_no_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
            END IF;
          END IF;
--
          -- ==================================================
          -- 製造日、賞味期限、固有記号、ロットマスタチェック =
          -- ==================================================
--
          --品目区分が製品の場合
          IF (lv_item_type = gv_item_cls_prdct) THEN
            IF  (lv_product_type  = gv_goods_classe_drink)  THEN  --商品区分＝ドリンクの場合
              -- 製造日＝'0'の場合のエラー
              IF  (inv_if_rec(i).maker_date  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  -- 製造日＝'0'の場合のエラー 16
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0以外を指定してください。(項目：OBJECT←製造日）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_maker_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- 賞味期限＝'0'の場合のエラー
              IF  (inv_if_rec(i).limit_date  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  -- 賞味期限＝'0'の場合のエラー 17
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0以外を指定してください。(項目：OBJECT←賞味期限）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- 固有記号＝'0'の場合のエラー
              IF  (inv_if_rec(i).proper_mark  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  -- 固有記号＝'0'の場合のエラー 18
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0以外を指定してください。(項目：OBJECT←固有記号）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --製造日が日付型エラー
              ld_maker_date := FND_DATE.STRING_TO_DATE(inv_if_rec(i).maker_date, gc_char_d_format);
              IF  (ld_maker_date IS NULL) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --製造日が日付型エラー 20
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (日付形式エラー:製造日）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => gv_xxinv,
                               iv_name         => 'APP-XXINV-10105',
                               iv_token_name1  => 'OBJECT',
                               iv_token_value1 => gv_maker_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --賞味期限が日付型エラー
              ld_limit_date := FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format);
              IF  (ld_limit_date IS NULL) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --賞味期限が日付型エラー 21
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (日付形式エラー:賞味期限）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => gv_xxinv,
                               iv_name         => 'APP-XXINV-10105',
                               iv_token_name1  => 'OBJECT',
                               iv_token_value1 => gv_limit_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --OPMロットマスタチェック
              BEGIN
                ln_lot_id :=  NULL;
                lv_lot_no :=  NULL;
                lv_limit_date :=  NULL;
-- 2008/12/06 H.Itou Add Start
                lv_maker_date  := NULL; -- 製造日
                lv_proper_mark := NULL; -- 固有記号
-- 2008/12/06 H.Itou Add End
                SELECT
                  ilm.lot_id     AS lot_id     -- ロットID
                 ,ilm.lot_no     AS lot_no     -- ロットNO
                 ,ilm.attribute3 AS limit_date -- 賞味期限
-- 2008/12/06 H.Itou Add Start
                 ,ilm.attribute1 AS maker_date  -- 製造日
                 ,ilm.attribute2 AS proper_mark -- 固有記号
-- 2008/12/06 H.Itou Add End
                INTO
                  ln_lot_id
                 ,lv_lot_no
                 ,lv_limit_date
-- 2008/12/06 H.Itou Add Start
                 ,lv_maker_date  -- 製造日
                 ,lv_proper_mark -- 固有記号
-- 2008/12/06 H.Itou Add End
                FROM   ic_lots_mst ilm
-- 2008/12/06 H.Itou Add Start
--                WHERE ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gc_char_d_format) || ''--製造日
                WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date --製造日
-- 2008/12/06 H.Itou Add End
                AND    ilm.attribute2 = inv_if_rec(i).proper_mark--固有記号
                AND    ilm.item_id = ln_item_id --品目ID
-- 2016/06/15 Y.Shoji Mod Start
--                AND ROWNUM  = 1;
                ;
-- 2016/06/15 Y.Shoji Mod End
                --
                IF  (lv_limit_date IS NOT NULL) THEN
                  IF  (FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format) !=
                       FND_DATE.STRING_TO_DATE(lv_limit_date, gc_char_d_format))  THEN
                    IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                      inv_if_rec(i).sts  :=  gv_sts_hr;  --賞味期限が一致しない (保留)  25
                    END IF;
                    --データダンプ取得
                    IF  (lb_dump_flag  = FALSE)  THEN
                      proc_get_data_dump(
                        if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                       ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                       ,ov_errbuf  => lv_errbuf
                       ,ov_retcode => lv_retcode
                       ,ov_errmsg  => lv_errmsg);
                      -- エラーの場合
                      IF (lv_retcode = gv_status_error) THEN
                        RAISE global_api_expt;
                      ELSE
                        lv_retcode  := gv_status_warn;
                      END IF;
                      -- 警告データダンプPL/SQL表投入
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                      lb_dump_flag :=  TRUE;
                    END IF;
--
                  -- 警告エラーメッセージ取得(賞味期限が一致しません。(項目：CONTENT))
                      -- 賞味期限の不一致(保留)
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10110',
                                    iv_token_name1  => 'OBEJCT',
                                    iv_token_value1 => gv_limit_date_col,
                                    iv_token_name2  => 'CONTENT',
                                    iv_token_value2 => gv_limit_date_col ||
                                      gv_msg_part || lv_limit_date);
                    -- 警告メッセージPL/SQL表投入
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END IF;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                    inv_if_rec(i).sts  :=  gv_sts_hr;  --ロットマスタ未登録エラー(保留)  23
                  END IF;
                  --データダンプ取得
                  IF  (lb_dump_flag  = FALSE)  THEN
                    proc_get_data_dump(
                      if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                     ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                     ,ov_errbuf  => lv_errbuf
                     ,ov_retcode => lv_retcode
                     ,ov_errmsg  => lv_errmsg);
                    -- エラーの場合
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_api_expt;
                    ELSE
                      lv_retcode  := gv_status_warn;
                    END IF;
                    -- 警告データダンプPL/SQL表投入
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                    lb_dump_flag :=  TRUE;
                  END IF;
--
        -- 警告エラーメッセージ取得(OPMロットマスタに該当データが存在しません。(項目：OBJECT))
                  lv_msg_col  :=  gv_maker_date_col || '、' || gv_proper_mark_col;
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10108',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => lv_msg_col);
                  -- 警告メッセージPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
-- 2016/06/15 Y.Shoji Add Start
                WHEN TOO_MANY_ROWS THEN
                  BEGIN
                    SELECT
                      ilm.lot_id     AS lot_id      -- ロットID
                     ,ilm.lot_no     AS lot_no      -- ロットNO
                     ,ilm.attribute3 AS limit_date  -- 賞味期限
                     ,ilm.attribute1 AS maker_date  -- 製造日
                     ,ilm.attribute2 AS proper_mark -- 固有記号
                    INTO
                      ln_lot_id               -- ロットID
                     ,lv_lot_no               -- ロットNO
                     ,lv_limit_date           -- 賞味期限
                     ,lv_maker_date           -- 製造日
                     ,lv_proper_mark          -- 固有記号
                    FROM   ic_lots_mst ilm
                    WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date             -- 製造日
                    AND    ilm.attribute2                                            = inv_if_rec(i).proper_mark -- 固有記号
                    AND    ilm.item_id                                               = ln_item_id                -- 品目
                    AND    FND_DATE.STRING_TO_DATE(ilm.attribute3, gc_char_d_format) = ld_limit_date             -- 賞味期限
                    ;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --ロットマスタ未登録エラー(保留)
                      END IF;
                      --データダンプ取得
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                         ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- エラーの場合
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- 警告データダンプPL/SQL表投入
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
--
                      -- 警告エラーメッセージ取得(OPMロットマスタに該当データが存在しません。(項目：OBJECT))
                      lv_msg_col  :=  gv_maker_date_col || '、' || gv_proper_mark_col || '、' || gv_limit_date_col;
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10108',
                                    iv_token_name1  => 'OBJECT',
                                    iv_token_value1 => lv_msg_col);
                      -- 警告メッセージPL/SQL表投入
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END;
-- 2016/06/15 Y.Shoji Add End
              END;
            END IF;--ドリンク終了
--
            IF  (lv_product_type  = gv_goods_classe_reaf)  THEN  --商品区分＝リーフの場合
              -- 賞味期限＝'0'の場合のエラー
              IF  (inv_if_rec(i).limit_date  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --賞味期限＝'0'の場合のエラ 27
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0以外を指定してください。(項目：OBJECT←賞味期限）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- 固有記号＝'0'の場合のエラー
              IF  (inv_if_rec(i).proper_mark  = '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --固有記号＝'0'の場合のエラ 28
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0以外を指定してください。(項目：OBJECT←固有記号）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10104',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --賞味期限が日付型エラー
              ld_limit_date := FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format);
              IF  (ld_limit_date IS NULL) THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --賞味期限が日付型エラー  29
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (日付形式エラー:賞味期限）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => gv_xxinv,
                               iv_name         => 'APP-XXINV-10105',
                               iv_token_name1  => 'OBJECT',
                               iv_token_value1 => gv_limit_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              --OPMロットマスタチェック
              BEGIN
                ln_lot_id :=  NULL;
                lv_lot_no :=  NULL;
                lv_limit_date :=  NULL;
-- 2008/12/06 H.Itou Add Start
                lv_maker_date :=  NULL;
-- 2008/12/06 H.Itou Add End
                ld_maker_date :=
                          FND_DATE.STRING_TO_DATE(inv_if_rec(i).maker_date, gc_char_d_format);
                SELECT
                  ilm.lot_id     AS lot_id     -- ロットID
                 ,ilm.lot_no     AS lot_no     -- ロットNO
                 ,ilm.attribute3 AS limit_date -- 賞味期限
-- 2008/12/06 H.Itou Add Start
                 ,ilm.attribute1 AS maker_date -- 製造年月日
-- 2008/12/06 H.Itou Add End
                INTO
                  ln_lot_id
                 ,lv_lot_no
                 ,lv_limit_date
-- 2008/12/06 H.Itou Add Start
                 ,lv_maker_date           -- 製造年月日
-- 2008/12/06 H.Itou Add End
                FROM   ic_lots_mst ilm
-- 2008/12/06 H.Itou Add Start
--                WHERE ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gc_char_d_format) || ''--製造日
                WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date --製造日
-- 2008/12/06 H.Itou Add End
                AND    ilm.attribute2 = inv_if_rec(i).proper_mark --固有記号
                AND    ilm.item_id = ln_item_id
-- 2016/06/15 Y.Shoji Mod Start
--                AND ROWNUM  = 1;
                ;
-- 2016/06/15 Y.Shoji Mod End
                --ロットマスタが存在する場合に賞味期限が不一致の場合
                IF  (lv_limit_date IS NOT NULL) THEN
                  IF  (FND_DATE.STRING_TO_DATE(inv_if_rec(i).limit_date, gc_char_d_format) !=
                       FND_DATE.STRING_TO_DATE(lv_limit_date, gc_char_d_format))  THEN
                    IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                      inv_if_rec(i).sts  :=  gv_sts_hr;  --賞味期限が不一致  (保留) 32
                    END IF;
                    --データダンプ取得
                    IF  (lb_dump_flag  = FALSE)  THEN
                      proc_get_data_dump(
                        if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                       ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                       ,ov_errbuf  => lv_errbuf
                       ,ov_retcode => lv_retcode
                       ,ov_errmsg  => lv_errmsg);
                      -- エラーの場合
                      IF (lv_retcode = gv_status_error) THEN
                        RAISE global_api_expt;
                      ELSE
                        lv_retcode  := gv_status_warn;
                      END IF;
                      -- 警告データダンプPL/SQL表投入
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                      lb_dump_flag :=  TRUE;
                    END IF;
                  -- 警告エラーメッセージ取得(賞味期限が一致しません。(項目：CONTENT))
                      -- 賞味期限の不一致(保留)
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10110',
                                    iv_token_name1  => 'OBEJCT',
                                    iv_token_value1 => gv_limit_date_col,
                                    iv_token_name2  => 'CONTENT',
                                    iv_token_value2 => gv_limit_date_col ||
                                      gv_msg_part || lv_limit_date);
                    -- 警告メッセージPL/SQL表投入
                    gn_err_msg_cnt := gn_err_msg_cnt + 1;
                    warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END IF;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  BEGIN
                    SELECT
                      ilm.lot_id     AS lot_id     -- ロットID
                     ,ilm.lot_no     AS lot_no     -- ロットNO
                     ,ilm.attribute1 AS maker_date -- 製造日
                    INTO
                      ln_lot_id
                     ,lv_lot_no
                     ,lv_maker_date
                    FROM   ic_lots_mst ilm
-- 2008/12/06 H.Itou Add Start
--                    WHERE ilm.attribute1 = '' || TO_CHAR(ld_maker_date, gc_char_d_format) || ''--製造日
                    WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute3, gc_char_d_format) = ld_limit_date --賞味期限
-- 2008/12/06 H.Itou Add End
                    AND    ilm.attribute2 = inv_if_rec(i).proper_mark--固有記号
                    AND    ilm.item_id = ln_item_id; --品目ID
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --ロットマスタ未登録エラー(保留)  34
                      END IF;
                      --データダンプ取得
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                         ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- エラーの場合
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- 警告データダンプPL/SQL表投入
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
              -- 警告エラーメッセージ取得(OPMロットマスタに該当データが存在しません(項目：OBJECT))
                      lv_msg_col  :=  gv_limit_date_col || '、' || gv_proper_mark_col;
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10108',
                                    iv_token_name1  => 'OBJECT',
                                    iv_token_value1 => lv_msg_col);
                      -- 警告メッセージPL/SQL表投入
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                    WHEN TOO_MANY_ROWS THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --ロットマスタ未登録エラー(保留)  35
                      END IF;
                      --データダンプ取得
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                         ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- エラーの場合
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- 警告データダンプPL/SQL表投入
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
                      -- OPMロットマスタに複数登録(保留)
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                        iv_application  => gv_xxinv,
                                        iv_name         => 'APP-XXINV-10109',
                                        iv_token_name1  => 'OBJECT',
                                        iv_token_value1 =>
                                          gv_proper_mark_col ||
                                          gv_msg_part || inv_if_rec(i).proper_mark ||
                                          gv_msg_comma ||
                                          gv_limit_date_col ||
                                          gv_msg_part || inv_if_rec(i).limit_date);
                      -- 警告メッセージPL/SQL表投入
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END;
-- 2016/06/15 Y.Shoji Add Start
                WHEN TOO_MANY_ROWS THEN
                  BEGIN
                    SELECT
                      ilm.lot_id     AS lot_id     -- ロットID
                     ,ilm.lot_no     AS lot_no     -- ロットNO
                     ,ilm.attribute3 AS limit_date -- 賞味期限
                     ,ilm.attribute1 AS maker_date -- 製造年月日
                    INTO
                      ln_lot_id               -- ロットID
                     ,lv_lot_no               -- ロットNO
                     ,lv_limit_date           -- 賞味期限
                     ,lv_maker_date           -- 製造年月日
                    FROM   ic_lots_mst ilm
                    WHERE  FND_DATE.STRING_TO_DATE(ilm.attribute1, gc_char_d_format) = ld_maker_date             -- 製造日
                    AND    ilm.attribute2                                            = inv_if_rec(i).proper_mark -- 固有記号
                    AND    ilm.item_id                                               = ln_item_id                -- 品目
                    AND    FND_DATE.STRING_TO_DATE(ilm.attribute3, gc_char_d_format) = ld_limit_date             -- 賞味期限
                    ;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      IF  (inv_if_rec(i).sts != gv_sts_ng  )  THEN
                        inv_if_rec(i).sts  :=  gv_sts_hr;  --ロットマスタ未登録エラー(保留)
                      END IF;
                      --データダンプ取得
                      IF  (lb_dump_flag  = FALSE)  THEN
                        proc_get_data_dump(
                          if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                         ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                         ,ov_errbuf  => lv_errbuf
                         ,ov_retcode => lv_retcode
                         ,ov_errmsg  => lv_errmsg);
                        -- エラーの場合
                        IF (lv_retcode = gv_status_error) THEN
                          RAISE global_api_expt;
                        ELSE
                          lv_retcode  := gv_status_warn;
                        END IF;
                        -- 警告データダンプPL/SQL表投入
                        gn_err_msg_cnt := gn_err_msg_cnt + 1;
                        warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                        lb_dump_flag :=  TRUE;
                      END IF;
                      -- 警告エラーメッセージ取得(OPMロットマスタに該当データが存在しません(項目：OBJECT))
                      lv_msg_col  :=  gv_maker_date_col || '、' || gv_proper_mark_col || '、' || gv_limit_date_col;
                      lv_errmsg := xxcmn_common_pkg.get_msg(
                                    iv_application  => gv_xxinv,
                                    iv_name         => 'APP-XXINV-10108',
                                    iv_token_name1  => 'OBJECT',
                                    iv_token_value1 => lv_msg_col);
                      -- 警告メッセージPL/SQL表投入
                      gn_err_msg_cnt := gn_err_msg_cnt + 1;
                      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
                  END;
-- 2016/06/15 Y.Shoji Add End
              END;
            END IF;--リーフ終了
          END IF;
--
          --品目区分が製品以外の場合
          IF (lv_item_type != gv_item_cls_prdct) THEN
            --ロット管理対象外の場合
            IF  (ln_lot_ctl  != 1) THEN
              -- 製造日が'0'以外の場合のエラー
              IF  (inv_if_rec(i).maker_date  != '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --製造日が'0'以外の場合のエラー   38
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0を指定してください。(項目：OBJECT←製造日）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_maker_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- 賞味期限が'0'以外の場合のエラー
              IF  (inv_if_rec(i).limit_date  != '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --賞味期限が'0'以外の場合のエラー   39
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0を指定してください。(項目：OBJECT←賞味期限）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_limit_date_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
              -- 固有記号が'0'以外の場合のエラー
              IF  (inv_if_rec(i).proper_mark  != '0')  THEN
                inv_if_rec(i).sts  :=  gv_sts_ng;  --固有記号が'0'以外の場合のエラー   40
                IF  (lb_dump_flag  = FALSE)  THEN
                  --データダンプ取得
                  proc_get_data_dump(
                    if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
                   ,ov_dump    => lv_dump        -- 2.データダンプ文字列
                   ,ov_errbuf  => lv_errbuf
                   ,ov_retcode => lv_retcode
                   ,ov_errmsg  => lv_errmsg);
                  -- エラーの場合
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  ELSE
                    lv_retcode  := gv_status_warn;
                  END IF;
                  -- 警告データダンプPL/SQL表投入
                  gn_err_msg_cnt := gn_err_msg_cnt + 1;
                  warn_dump_tab(gn_err_msg_cnt) := lv_dump;
                  lb_dump_flag :=  TRUE;
                END IF;
                -- 警告エラーメッセージ取得 (0を指定してください。(項目：OBJECT←固有記号）
                lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => gv_xxinv,
                              iv_name         => 'APP-XXINV-10103',
                              iv_token_name1  => 'OBJECT',
                              iv_token_value1 => gv_proper_mark_col);
                -- 警告メッセージPL/SQL表投入
                gn_err_msg_cnt := gn_err_msg_cnt + 1;
                warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
              END IF;
            END IF;
          END IF;
--
        END IF;
--
        -- ======================
        -- 棚卸ケース数チェック =
        -- ======================
        --棚卸ケース数 が０未満の場合のエラー
        IF  (inv_if_rec(i).case_amt < 0 ) THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --棚卸ケース数 が０未満の場合のエラー  43
          IF  (lb_dump_flag  = FALSE)  THEN
            --データダンプ取得
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- 警告エラーメッセージ取得 (0以上の値を指定してください。(項目：OBJECT←棚卸ケース）
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10106',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_case_amt_col);
          -- 警告メッセージPL/SQL表投入
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        ELSIF
        --棚卸ケース数 が整数でない場合のエラー
          (inv_if_rec(i).case_amt  -
            TRUNC(inv_if_rec(i).case_amt)  !=0)  THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --棚卸ケース数 が整数でない場合のエラー 44
          IF  (lb_dump_flag  = FALSE)  THEN
            --データダンプ取得
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- 警告エラーメッセージ取得 (整数値を指定してください。(項目：OBJECT)T←棚卸ケース）
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10107',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_case_amt_col);
          -- 警告メッセージPL/SQL表投入
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END IF;
--
        -- ======================
        -- 棚卸バラ数チェック =
        -- ======================
        --棚卸バラ数 が０未満の場合のエラー
        IF  (inv_if_rec(i).loose_amt < 0 ) THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --棚卸バラ数 が０未満の場合のエラー  46
          IF  (lb_dump_flag  = FALSE)  THEN
            --データダンプ取得
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- 警告エラーメッセージ取得 (0以上の値を指定してください。(項目：OBJECT←棚卸バラ）
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10106',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_loose_amt_col);
          -- 警告メッセージPL/SQL表投入
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END IF;
        -- ======================
        -- 入数チェック =
        -- ======================
        --入数 が０未満の場合のエラー
        IF  (inv_if_rec(i).content < 0 ) THEN
          inv_if_rec(i).sts  :=  gv_sts_ng;  --入数 が０未満の場合のエラー 48
          IF  (lb_dump_flag  = FALSE)  THEN
            --データダンプ取得
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- 警告エラーメッセージ取得 (0以上の値を指定してください。(項目：OBJECT←入数)
          lv_errmsg := xxcmn_common_pkg.get_msg(
                                iv_application  => gv_xxinv,
                                iv_name         => 'APP-XXINV-10106',
                                iv_token_name1  => 'OBJECT',
                                iv_token_value1 => gv_content_col);
          -- 警告メッセージPL/SQL表投入
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
              --品目区分＝製品かつ商品区分＝ドリンクかつ入数≠ケース入数
        ELSIF (inv_if_rec(i).content != lv_num_of_cases) AND
              (lv_item_type = gv_item_cls_prdct)  AND          --品目区分＝製品     2008/05/02
              (lv_product_type  = gv_goods_classe_drink)  THEN  --商品区分＝ドリンク 2008/05/02
          inv_if_rec(i).sts  :=  gv_sts_ng;  --品目区分＝製品かつ入数≠ケース入数 50
          IF  (lb_dump_flag  = FALSE)  THEN
            --データダンプ取得
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
          -- 警告エラーメッセージ取得 (0以上の値を指定してください。(項目：OBJECT←入数）
          lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxinv,
                        iv_name         => 'APP-XXINV-10110',
                        iv_token_name1  => 'OBEJCT',
                        iv_token_value1 => gv_content_col,
                        iv_token_name2  => 'CONTENT',
                        iv_token_value2 => gv_num_of_cases_col ||
                          gv_msg_part || lv_num_of_cases);
          -- 警告メッセージPL/SQL表投入
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
        END IF;
--
-- 2008/12/06 H.Itou Add Start 上から移動
        -- ===========================================
        -- 重複チェック                              =
        -- ===========================================
        proc_duplication_chk(
          if_rec      => inv_if_rec(i)  -- 1.棚卸インターフェース
         ,iv_item_typ => lv_item_type   -- 2.データダンプ文字列
         ,ib_dup_sts  => lb_dup_sts     -- 3.重複チェック結果
         ,ib_dup_del_sts => lb_dup_del_sts -- 4.重複削除チェック結果
         ,ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_dupretcd
         ,ov_errmsg   => lv_errmsg);
        -- エラーの場合
        IF (lv_dupretcd = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        IF  (lb_dup_sts  = FALSE) THEN
          IF (lb_dup_del_sts = TRUE) THEN
            inv_if_rec(i).sts  :=  gv_sts_del;  --重複削除
          ELSE
            inv_if_rec(i).sts  :=  gv_sts_ng;  --重複エラー 4,6
          END IF;
          IF  ((lb_dump_flag  = FALSE) AND (lb_dup_del_sts = FALSE)) THEN -- 重複削除はエラーとしない
            --データダンプ取得
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
--
          IF (lb_dup_del_sts = FALSE) THEN -- 重複削除はエラーとしない
            -- 警告エラーメッセージ取得 (同一ファイル内に重複データが存在します。)
            lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => gv_xxinv,
                          iv_name         => 'APP-XXINV-10101');
--
            -- 警告メッセージPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
          END IF;
--
        END IF;
-- 2008/12/06 H.Itou Add End 上から移動
-- 2009/02/09 v1.12 ADD START
--
        -- ===========================================
        -- 在庫クローズチェック                      =
        -- ===========================================
        -- 棚卸日が在庫カレンダーのオープンでない場合
        IF ( TO_CHAR(inv_if_rec(i).invent_date, 'YYYYMM') <= xxcmn_common_pkg.get_opminv_close_period() ) THEN
          -- エラーメッセージを取得
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxinv
                                              , 'APP-XXINV-10003'
                                              , 'ERR_MSG'
                                              , TO_CHAR(inv_if_rec(i).invent_date, gc_char_d_format));
          -- 警告メッセージPL/SQL表投入
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
          inv_if_rec(i).sts  :=  gv_sts_ng;
--
          --データダンプ取得
          IF  (lb_dump_flag  = FALSE)  THEN
            proc_get_data_dump(
              if_rec     => inv_if_rec(i)  -- 1.棚卸インターフェース
             ,ov_dump    => lv_dump        -- 2.データダンプ文字列
             ,ov_errbuf  => lv_errbuf
             ,ov_retcode => lv_retcode
             ,ov_errmsg  => lv_errmsg);
            -- エラーの場合
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            ELSE
              lv_retcode  := gv_status_warn;
            END IF;
            -- 警告データダンプPL/SQL表投入
            gn_err_msg_cnt := gn_err_msg_cnt + 1;
            warn_dump_tab(gn_err_msg_cnt) := lv_dump;
            lb_dump_flag :=  TRUE;
          END IF;
        END IF;
--
-- 2009/02/09 v1.12 ADD END
        --マスタチェックで取得した項目を配列へ退避
        inv_if_rec(i).item_id      := ln_item_id;          --品目ID
        inv_if_rec(i).lot_ctl      := ln_lot_ctl;          --ロット管理区分
        inv_if_rec(i).num_of_cases := lv_num_of_cases;     --ケース入数
        inv_if_rec(i).item_type    := lv_item_type;        --品目区分
        inv_if_rec(i).product_type := lv_product_type ;    --商品区分
--
        inv_if_rec(i).lot_id       := ln_lot_id;           --ロットID
        inv_if_rec(i).lot_no1      := lv_lot_no;           --ロットNo
        inv_if_rec(i).maker_date1  := lv_maker_date;       --製造年月日
        inv_if_rec(i).proper_mark1 := lv_proper_mark;      --固有記号
        inv_if_rec(i).limit_date1  := lv_limit_date;       --賞味期限
--
-- 2008/12/06 H.Itou Del Start
--      END IF;
-- 2008/12/06 H.Itou Del En
--
    END LOOP process_loop;
--
    -- ===============================
    -- OUTパラメータセット
    -- ===============================
    ov_retcode := lv_retcode;
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
  END proc_master_data_chk;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_lock
   * Description      : 対象インターフェースデータ取得(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_lock(
    iv_report_post_code IN  xxinv_stc_inventory_interface.report_post_code%TYPE,  --報告部署
    iv_whse_code        IN  ic_whse_mst.whse_code                         %TYPE,  --倉庫コード
    iv_item_type        IN  xxcmn_categories2_v.segment1                  %TYPE,  --品目区分
    lrec_data           OUT cursor_rec,                                           --対象データ
    ov_errbuf           OUT VARCHAR2,         --   エラー・メッセージ
    ov_retcode          OUT VARCHAR2,         --   リターン・コード
    ov_errmsg           OUT VARCHAR2)         --   ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_lock'; -- プログラム名
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
    cv_xxwip_delivery_distance_if CONSTANT  VARCHAR2(50) := '棚卸データインターフェース';
--
    -- *** ローカル変数 ***
    lv_sql  VARCHAR2(15000) DEFAULT NULL;
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
    -- ==============================
    -- ＳＱＬ組立
    -- ==============================
    lv_sql  :=
      'SELECT '
      ||  'xsi.invent_if_id      invent_if_id, '      --棚卸ＩＦ_ID
      ||  'xsi.report_post_code  report_post_code, '  --報告部署
      ||  'xsi.invent_date       invent_date, '       --棚卸日
      ||  'xsi.invent_whse_code  invent_whse_code, '  --棚卸倉庫
--2008/12/08 mod start
--      ||  'xsi.invent_seq        invent_seq, '        --棚卸連番
      ||  'TO_NUMBER(xsi.invent_seq) invent_seq, '    --棚卸連番
--2008/12/08 mod end
      ||  'xsi.item_code         item_code, '         --品目
      ||  'xsi.lot_no            lot_no, '            --ロットNo.
      ||  'xsi.maker_date        maker_date, '        --製造日
      ||  'xsi.limit_date        limit_date, '        --賞味期限
      ||  'xsi.proper_mark       proper_mark, '       --固有記号
      ||  'xsi.case_amt          case_amt, '          --棚卸ケース数
      ||  'xsi.content           content, '           --入数
      ||  'xsi.loose_amt         loose_amt, '         --棚卸バラ
      ||  'xsi.location          location, '          --ロケーション
      ||  'xsi.rack_no1          rack_no1, '          --ラックNo１
      ||  'xsi.rack_no2          rack_no2, '          --ラックNo２
      ||  'xsi.rack_no3          rack_no3, '          --ラックNo３
      ||  'xsi.request_id        request_id, '        --要求ID
      ||  'NULL                  item_id, '           --品目ID
      ||  'NULL                  lot_ctl, '           --ロット管理区分
      ||  'NULL                  num_of_cases, '      --ケース入数
      ||  'NULL                  item_type, '         --品目区分
      ||  'NULL                  product_type, '      --商品区分
      ||  'NULL                  lot_id, '            --ロットID
      ||  'NULL                  lot_no1, '           --ロットNo
      ||  'NULL                  maker_date1, '       --製造年月日
      ||  'NULL                  proper_mark1, '      --固有記号
      ||  'NULL                  limit_date1, '       --賞味期限
      ||  'xsi.ROWID             rowid_work, '        --ROWID
      ||  '''OK''                sts '      ||        --妥当性チェックステータス
      'FROM '
      ||  'xxinv_stc_inventory_interface xsi '       -- 1.棚卸データインタフェース
      ||  ',xxcmn_locations_v xlv ';                  -- 2.事業所マスタ
--
    --入力パラ：倉庫コードが入力されている場合
    IF  (iv_whse_code IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ',ic_whse_mst iwm ';                        -- 3.OPM倉庫マスタ
    END IF;
--
    --入力パラ：品目区分が入力されている場合
    IF  (iv_item_type IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ',xxcmn_item_mst_v itm '                    -- 4.OPM品目マスタ(有効期限のみ)
      ||  ',xxcmn_item_categories5_v ictm ';          -- 5.OPM品目カテゴリVIW４
    END IF;
--
    lv_sql  :=  lv_sql  ||
    'WHERE '
      ||  'xsi.report_post_code = ''' || iv_report_post_code || ''''
      ||  ' AND '
      ||  'xlv.location_code  = xsi.report_post_code ';
--
    --入力パラ：倉庫コードが入力されている場合
    IF  (iv_whse_code IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ' AND '
      ||  'iwm.whse_code = '''  ||  iv_whse_code  || ''''
      ||  ' AND '
      ||  'iwm.whse_code = xsi.invent_whse_code ';
    END IF;
--
--
    --入力パラ：品目区分が入力されている場合 2008/4/4
    IF  (iv_item_type IS NOT NULL) THEN
      lv_sql  :=  lv_sql
      ||  ' AND '
      ||  'ictm.item_class_code = ''' ||  iv_item_type || '''' --入力パラ品目区分
      ||  ' AND '
      ||  'itm.item_no = xsi.item_code '
      ||  ' AND '
      ||  'ictm.item_id = itm.item_id ';
    END IF;
--
    lv_sql  :=  lv_sql  ||
    'ORDER BY '
      ||  ' xsi.invent_seq'       --棚卸連番
      ||  ',xsi.invent_whse_code' --棚卸倉庫
      ||  ',xsi.report_post_code' --報告部署
      ||  ',xsi.item_code'        --品目
      ||  ',xsi.maker_date'       --製造日
      ||  ',xsi.limit_date'       --賞味期限
      ||  ',xsi.proper_mark'      --固有記号
      ||  ',xsi.lot_no'           --ロットNo.
      ||  ',xsi.invent_date'      --棚卸日
      ||  ',xsi.request_id DESC '; --要求ID
--
     lv_sql  :=  lv_sql  || 'FOR UPDATE OF xsi.invent_if_id NOWAIT';
--
    -- ====================================================================
    -- 棚卸データインターフェーステーブルのロックを取得およびデータの取得 =
    -- ====================================================================
    BEGIN
      OPEN  lrec_data FOR lv_sql;
      FETCH lrec_data BULK COLLECT INTO inv_if_rec;
      CLOSE lrec_data;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ロック取得エラー ***
        -- カーソルをCLOSE
        IF (lrec_data%ISOPEN) THEN
          CLOSE lrec_data;
        END IF;
        -- エラーメッセージ取得
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                       gv_xxcmn               -- モジュール名略称：XXCMN 共通
                      ,'APP-XXCMN-10019'      -- ロック失敗
                      ,gv_tkn_table           -- トークンTABLE
                      ,gv_xxcmn_del_table_name-- 棚卸データインターフェーステーブル
                      ),1,5000);
        RAISE global_api_expt;
      WHEN OTHERS THEN
        -- カーソルをCLOSE
        IF (lrec_data%ISOPEN) THEN
          CLOSE lrec_data;
        END IF;
        RAISE;
--
    END;
--
--  件数＝０エラー
    IF  (inv_if_rec.COUNT = 0 ) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                       gv_xxinv
                      ,'APP-XXINV-10054'      --対象データなし
                      ,gv_tkn_table           -- トークンTABLE
                      ,gv_xxcmn_del_table_name-- 棚卸データインターフェーステーブル
                    );
      RAISE global_api_expt;
    END IF;
--
--  対象件数取得
    gn_target_cnt := inv_if_rec.COUNT;
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
  END proc_get_lock;
--
  /**********************************************************************************
   * Procedure Name   : proc_del_inventory_if
   * Description      : データパージ処理(A-2)
   ***********************************************************************************/
  PROCEDURE proc_del_inventory_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_inventory_if'; -- プログラム名
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
    -- プロファイルオプション：棚卸削除対象日付
    cv_xxcmn_del_date       CONSTANT  VARCHAR2(50) := 'XXINV_INVENTORY_PURGE_TERM';
    cv_xxcmn_del_date_name  CONSTANT  VARCHAR2(50) := '棚卸削除対象日付';
    -- *** ローカル変数 ***
    lv_inv_del_date fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;
    ld_del_date DATE  DEFAULT NULL;
    lr_rowid          ROWID;
--
    -- *** ローカル・カーソル ***
--
    -- 棚卸データインターフェーステーブル
    CURSOR xxinv_stc_inventory_if_cur(
      cd_del_date DATE -- 削除日付
      )
    IS
      SELECT stc.ROWID
      FROM   xxinv_stc_inventory_interface stc
      WHERE  stc.creation_date < cd_del_date
-- mod start ver1.6
--      FOR UPDATE NOWAIT
      FOR UPDATE
-- mod end ver1.6
    ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・レコード ***
    TYPE ltbl_rowid_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    ltbl_rowid ltbl_rowid_type;
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
    lv_inv_del_date := FND_PROFILE.VALUE(cv_xxcmn_del_date);
    -- 取得できなかった場合はエラー
    IF (lv_inv_del_date IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- モジュール名略称：XXCMN 共通
                   ,'APP-XXCMN-10002'      -- プロファイル取得エラー
                   ,gv_tkn_ng_profile      -- トークン：NGプロファイル名
                   ,cv_xxcmn_del_date_name -- '棚卸削除対象日付'
                   ),1,5000);
--
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 棚卸データインターフェーステーブルの削除  =
    -- ===========================================
    BEGIN
      -- 削除日付の作成
      ld_del_date := (TRUNC(SYSDATE) - TO_NUMBER(lv_inv_del_date));
--
      --  ロック取得カーソルOPEN
      OPEN xxinv_stc_inventory_if_cur(
        cd_del_date => ld_del_date);
--
      <<fetch_loop>>
      LOOP
        FETCH xxinv_stc_inventory_if_cur INTO lr_rowid;
        EXIT WHEN xxinv_stc_inventory_if_cur%NOTFOUND;
        -- 削除対象ROWIDのセット
        ltbl_rowid(ltbl_rowid.COUNT + 1) := lr_rowid;
      END LOOP fetch_loop;
--
      -- 一括削除処理
      FORALL i in 1..ltbl_rowid.COUNT
        DELETE xxinv_stc_inventory_interface stc
        WHERE  stc.ROWID = ltbl_rowid(i);
--
      -- ロック取得カーソルをCLOSE
      CLOSE xxinv_stc_inventory_if_cur;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ロック取得エラー ***
        -- カーソルをCLOSE
        IF (xxinv_stc_inventory_if_cur%ISOPEN) THEN
          CLOSE xxinv_stc_inventory_if_cur;
        END IF;
-- 2008/09/04 H.Itou Del Start PT 6-3_39指摘#12対応 同時実行した場合にパージデータのロックを取得できなくても処理を続行する。
--        -- エラーメッセージ取得
--        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
--                       gv_xxcmn               -- モジュール名略称：XXCMN 共通
--                      ,'APP-XXCMN-10019'      -- ロック失敗
--                      ,gv_tkn_table           -- トークンTABLE
--                      ,gv_xxcmn_del_table_name-- テーブル名：棚卸データインターフェーステーブル
--                      ),1,5000);
--        RAISE global_api_expt;
-- 2008/09/04 H.Itou Del Start PT 6-3_39指摘#12対応
      WHEN OTHERS THEN
        -- カーソルをCLOSE
        IF (xxinv_stc_inventory_if_cur%ISOPEN) THEN
          CLOSE xxinv_stc_inventory_if_cur;
        END IF;
        RAISE;
--
    END;
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
  END proc_del_inventory_if;
--
--
   /**********************************************************************************
   * Procedure Name   : proc_check_param
   * Description      : パラメータチェック(A-1)
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
                      iv_token_name2  => gv_tkn_value,
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
                      iv_token_name2  => gv_tkn_value,
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
        AND    ROWNUM      = 1;
      EXCEPTION
      -- データがない場合はエラー
        WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => 'APP-XXCMN-10010',
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_inv_whse_code,      --倉庫コード
                        iv_token_name2  => gv_tkn_value,
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
                          iv_token_name2  => gv_tkn_value,
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_report_post_code   IN  VARCHAR2,   -- 報告部署
    iv_whse_code          IN  VARCHAR2,   -- 倉庫コード
    iv_item_type          IN  VARCHAR2,   -- 品目区分
    ov_errbuf             OUT VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    ln_count  NUMBER  DEFAULT 0;
--
    -- *** ローカル・カーソル ***
    lrec_data cursor_rec;  -- 棚卸データインタフェースカーソル
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
    -- ===============================
    -- A-1.パラメータチェック
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
    -- ===============================
    -- A-2.データパージ処理
    -- ===============================
    proc_del_inventory_if(
      ov_errbuf            =>  lv_errbuf            -- エラー・メッセージ
      ,ov_retcode          =>  lv_retcode           -- リターン・コード
      ,ov_errmsg           =>  lv_errmsg);          -- ユーザー・エラー・メッセージ
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- A-3.対象インターフェースデータ取得 ==
    -- =====================================
    proc_get_lock(
       iv_report_post_code =>  iv_report_post_code --報告部署
      ,iv_whse_code        =>  iv_whse_code        --倉庫コード
      ,iv_item_type        =>  iv_item_type        --品目区分
      ,lrec_data           =>  lrec_data           --ロック取得中の対象データ
      ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ
      ,ov_retcode          =>  lv_retcode          -- リターン・コード
      ,ov_errmsg           =>  lv_errmsg);         -- ユーザー・エラー・メッセージ
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- A-4.妥当性チェック =
    -- ====================
    proc_master_data_chk(
      ov_errbuf     =>  lv_errbuf            -- エラー・メッセージ
      ,ov_retcode   =>  lv_retcode           -- リターン・コード
      ,ov_errmsg    =>  lv_errmsg);          -- ユーザー・エラー・メッセージ
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 警告の場合
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- エラーデータダンプ一括出力処理(A-4-5)
    -- ===============================
    proc_put_dump_msg(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 警告の場合
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- A-5.棚卸結果更新処理
    -- ===============================
    proc_upd_table_batch(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 警告の場合
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- A-6.棚卸結果登録処理
    -- ===============================
     proc_ins_table_batch(
       ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 警告の場合
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===============================
    -- A-7.データ削除処理
    -- ===============================
    proc_del_table_data(
      lrec_data     => lrec_data          --ロック継続中の対象データ
     ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
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
    errbuf                OUT VARCHAR2,       --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,       --   リターン・コード    --# 固定 #
    iv_report_post_code   IN  VARCHAR2,   -- 報告部署
    iv_whse_code          IN  VARCHAR2,   -- 倉庫コード
    iv_item_type          IN  VARCHAR2)   -- 品目区分
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
    lv_errbuf   VARCHAR2(5000)   DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)      DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)   DEFAULT NULL;  -- ユーザー・エラー・メッセージ
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',    --2008/05/09
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
      iv_report_post_code =>  iv_report_post_code, -- 報告部署
      iv_whse_code        =>  iv_whse_code,        -- 倉庫コード
      iv_item_type        =>  iv_item_type,        -- 品目区分
      ov_errbuf           =>  lv_errbuf,           -- エラー・メッセージ
      ov_retcode          =>  lv_retcode,          -- リターン・コード
      ov_errmsg           =>  lv_errmsg);          -- ユーザー・エラー・メッセージ
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
    -- D-15.リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
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
END xxinv530001c;
/
