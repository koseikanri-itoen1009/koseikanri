CREATE OR REPLACE PACKAGE BODY xxcmn820005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820005c(body)
 * Description      : 原価コピー処理
 * MD.050           : 標準原価マスタT_MD050_BPO_821
 * MD.070           : 原価コピー処理(82E) T_MD070_BPO_82E
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  parameter_check             パラメータチェック(E-2)
 *  get_other_data              関連データ取得処理(E-3)
 *  get_lock                    ロック取得処理(E-4)
 *  get_cmpntcls_mst            コンポーネント区分マスタ取得処理(E-5)
 *  get_unit_price_summary      単価合計取得処理(E-7)
 *  ins_cm_cmpt_dtl             品目原価マスタ登録処理(E-9)
 *  upd_cm_cmpt_dtl             品目原価マスタ更新処理(E-10)
 *  detail_rec_loop             明細レコード取得LOOP
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/07/01    1.0   H.Itou           新規作成
 *  2009/01/08    1.1   N.Yoshida        本番#968対応
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
  lock_expt              EXCEPTION;        -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxcmn820005c';
--
  -- モジュール名略称
  gv_xxcmn                    CONSTANT VARCHAR2(100) := 'XXCMN';        -- モジュール名略称：XXCMN
--
  -- メッセージ
  gv_msg_xxcmn10002           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
  gv_msg_xxcmn10019           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- メッセージ：APP-XXCMN-10019 ロックエラー
  gv_msg_xxcmn10600           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10600'; -- メッセージ：APP-XXCMN-10600 大小チェックエラー
  gv_msg_xxcmn10601           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10601'; -- メッセージ：APP-XXCMN-10601 大小チェックエラー
  gv_msg_xxcmn10018           CONSTANT VARCHAR2(100) := 'APP-XXCMN-10018'; -- メッセージ：APP-XXCMN-10018 APIエラー(コンカレント)
--
  -- トークン
  gv_tkn_ng_profile           CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_table                CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_api_name             CONSTANT VARCHAR2(100) := 'API_NAME';
--
  -- INパラメータ日本語名
  gv_calendar_code_name       CONSTANT VARCHAR2(100) := '会計年度（カレンダコード）';
  gv_param_prod_class_name    CONSTANT VARCHAR2(100) := '商品区分';
  gv_param_item_class_name    CONSTANT VARCHAR2(100) := '品目区分';
  gv_param_item_code_name     CONSTANT VARCHAR2(100) := '品目';
  gv_param_upd_date_from_name CONSTANT VARCHAR2(100) := '更新日時FROM';
  gv_param_upd_date_to_name   CONSTANT VARCHAR2(100) := '更新日時TO';
--
  -- 日付書式
  gv_yyyymmddhh24miss         CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
  gv_yyyymm                   CONSTANT VARCHAR2(100) := 'YYYYMM';
-- 2009/01/08 v1.1 N.Yoshida add start
  gc_f_time                   CONSTANT VARCHAR2(100) := ' 00:00:00';
  gc_e_time                   CONSTANT VARCHAR2(100) := ' 23:59:59';
-- 2009/01/08 v1.1 N.Yoshida add end
--
  -- プロファイル
  gv_prf_cost_price_whse_code CONSTANT VARCHAR2(100) := 'XXCMN_COST_PRICE_WHSE_CODE';
  gv_prf_cost_div             CONSTANT VARCHAR2(100) := 'XXCMN_COST_DIV';
  gv_prf_raw_material_cost    CONSTANT VARCHAR2(100) := 'XXCMN_RAW_MATERIAL_COST';
  gv_prf_agein_cost           CONSTANT VARCHAR2(100) := 'XXCMN_AGEIN_COST';
  gv_prf_material_cost        CONSTANT VARCHAR2(100) := 'XXCMN_MATERIAL_COST';
  gv_prf_pack_cost            CONSTANT VARCHAR2(100) := 'XXCMN_PACK_COST';
  gv_prf_out_order_cost       CONSTANT VARCHAR2(100) := 'XXCMN_OUT_ORDER_COST';
  gv_prf_safekeep_cost        CONSTANT VARCHAR2(100) := 'XXCMN_SAFEKEEP_COST';
  gv_prf_other_expense_cost   CONSTANT VARCHAR2(100) := 'XXCMN_OTHER_EXPENSE_COST';
  gv_prf_spare1               CONSTANT VARCHAR2(100) := 'XXCMN_SPARE1';
  gv_prf_spare2               CONSTANT VARCHAR2(100) := 'XXCMN_SPARE2';
  gv_prf_spare3               CONSTANT VARCHAR2(100) := 'XXCMN_SPARE3';
--
  -- プロファイル日本語名
  gv_prf_whse_code_name       CONSTANT VARCHAR2(100) := 'XXCMN:原価倉庫';
  gv_prf_cost_div_name        CONSTANT VARCHAR2(100) := 'XXCMN:原価方法';
  gv_prf_raw_mat_cost_name    CONSTANT VARCHAR2(100) := 'XXCMN:原料';
  gv_prf_agein_cost_name      CONSTANT VARCHAR2(100) := 'XXCMN:再製費';
  gv_prf_material_cost_name   CONSTANT VARCHAR2(100) := 'XXCMN:資材費';
  gv_prf_pack_cost_name       CONSTANT VARCHAR2(100) := 'XXCMN:包装費';
  gv_prf_out_order_cost_name  CONSTANT VARCHAR2(100) := 'XXCMN:外注加工費';
  gv_prf_safekeep_cost_name   CONSTANT VARCHAR2(100) := 'XXCMN:保管費';
  gv_prf_other_cost_name      CONSTANT VARCHAR2(100) := 'XXCMN:その他経費';
  gv_prf_spare1_name          CONSTANT VARCHAR2(100) := 'XXCMN:予備１';
  gv_prf_spare2_name          CONSTANT VARCHAR2(100) := 'XXCMN:予備２';
  gv_prf_spare3_name          CONSTANT VARCHAR2(100) := 'XXCMN:予備３';
--
  -- クイックコードタイプ
  gv_expense_item_type        CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE';  -- 費目区分
  gv_cmpntcls_type            CONSTANT VARCHAR2(100) := 'XXCMN_D19';               -- 原価内訳区分
--
  -- テーブル名
  gv_cm_cmpt_dtl              CONSTANT VARCHAR2(100) := '品目原価マスタ';
--
  -- マスタ区分
  gv_price_type_normal        CONSTANT VARCHAR2(100) := '2'; -- 2：標準
--
  -- 原価管理区分
  gv_cost_manage_code_normal  CONSTANT VARCHAR2(100) := '1'; -- 1：標準原価
--
  -- 品目区分
  gv_item_class_code_prod     CONSTANT VARCHAR2(100) := '5'; -- 5：製品
--
  -- API名
  gv_api_create_item_cost     CONSTANT VARCHAR2(100) := 'GMF_ITEMCOST_PUB.CREATE_ITEM_COST'; -- 品目原価マスタ登録API
  gv_api_update_item_cost     CONSTANT VARCHAR2(100) := 'GMF_ITEMCOST_PUB.UPDATE_ITEM_COST'; -- 品目原価マスタ更新API
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- コンポーネント区分マスタ用PL/SQL表
  TYPE cost_cmpntcls_id_ttype   IS TABLE OF  cm_cmpt_mst_tl.cost_cmpntcls_id  %TYPE INDEX BY BINARY_INTEGER;   -- コンポーネント区分ID
  TYPE cost_cmpntcls_desc_ttype IS TABLE OF  cm_cmpt_mst_tl.cost_cmpntcls_desc%TYPE INDEX BY BINARY_INTEGER;   -- コンポーネント区分名
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- コンポーネント区分マスタ用PL/SQL表
  cost_cmpntcls_id_tab          cost_cmpntcls_id_ttype;    -- コンポーネント区分ID
  cost_cmpntcls_desc_tab        cost_cmpntcls_desc_ttype;  -- コンポーネント区分名
--
  -- プロファイルオプション値
  gv_whse_code          VARCHAR2(100);  -- XXCMN:原価倉庫
  gv_cost_div           VARCHAR2(100);  -- XXCMN:原価方法
  gv_raw_material_cost  VARCHAR2(100);  -- XXCMN:原料
  gv_agein_cost         VARCHAR2(100);  -- XXCMN:再製費
  gv_material_cost      VARCHAR2(100);  -- XXCMN:資材費
  gv_pack_cost          VARCHAR2(100);  -- XXCMN:包装費
  gv_out_order_cost     VARCHAR2(100);  -- XXCMN:外注加工費
  gv_safekeep_cost      VARCHAR2(100);  -- XXCMN:保管費
  gv_other_expense_cost VARCHAR2(100);  -- XXCMN:その他経費
  gv_spare1             VARCHAR2(100);  -- XXCMN:予備１
  gv_spare2             VARCHAR2(100);  -- XXCMN:予備２
  gv_spare3             VARCHAR2(100);  -- XXCMN:予備３
--
  -- INパラメータ
  gv_calendar_code      VARCHAR2(100);  -- カレンダコード
  gv_prod_class_code    VARCHAR2(100);  -- 商品区分
  gv_item_class_code    VARCHAR2(100);  -- 品目区分
  gv_item_code          VARCHAR2(100);  -- 品目
  gd_update_date_from   DATE;           -- 更新日時FROM
  gd_update_date_to     DATE;           -- 更新日時TO
--
  gv_close_date         VARCHAR2(100);  -- 在庫クローズ年月
  gt_period_code        cm_cldr_dtl.period_code%TYPE;    -- 期間
  gt_start_date         cm_cldr_dtl.start_date %TYPE;    -- 開始日
  gt_end_date           cm_cldr_dtl.end_date   %TYPE;    -- 終了日
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(E-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    ov_errbuf  OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg  OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- プログラム名
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
    -- =========================================
    -- 更新日時FROM・更新日時TOチェック
    -- =========================================
    IF  (gd_update_date_from IS NOT NULL)
    AND (gd_update_date_to IS NOT NULL)
    AND (gd_update_date_from > gd_update_date_to) THEN -- 更新日時FROMが更新日時TOより大きい場合はエラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10600)           -- メッセージ:APP-XXCMN-10600 大小チェックエラー
                     ,1,5000);
      lv_errbuf := lv_errmsg;
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
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_other_data
   * Description      : 関連データ取得処理(E-3)
   ***********************************************************************************/
  PROCEDURE get_other_data(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_data'; -- プログラム名
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
    -- プロファイルオプション
--
    -- *** ローカル変数 ***
    lv_sysdate_yyyy VARCHAR2(4);  -- システム日付の年
    lv_sysdate_mm   VARCHAR2(2);  -- システム日付の月
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
    -- ===========================
    -- プロファイルオプション取得
    -- ===========================
    gv_whse_code          := FND_PROFILE.VALUE(gv_prf_cost_price_whse_code);  -- XXCMN:原価倉庫
    gv_cost_div           := FND_PROFILE.VALUE(gv_prf_cost_div);              -- XXCMN:原価方法
    gv_raw_material_cost  := FND_PROFILE.VALUE(gv_prf_raw_material_cost);     -- XXCMN:原料
    gv_agein_cost         := FND_PROFILE.VALUE(gv_prf_agein_cost);            -- XXCMN:再製費
    gv_material_cost      := FND_PROFILE.VALUE(gv_prf_material_cost);         -- XXCMN:資材費
    gv_pack_cost          := FND_PROFILE.VALUE(gv_prf_pack_cost);             -- XXCMN:包装費
    gv_out_order_cost     := FND_PROFILE.VALUE(gv_prf_out_order_cost);        -- XXCMN:外注加工費
    gv_safekeep_cost      := FND_PROFILE.VALUE(gv_prf_safekeep_cost);         -- XXCMN:保管費
    gv_other_expense_cost := FND_PROFILE.VALUE(gv_prf_other_expense_cost);    -- XXCMN:その他経費
    gv_spare1             := FND_PROFILE.VALUE(gv_prf_spare1);                -- XXCMN:予備１
    gv_spare2             := FND_PROFILE.VALUE(gv_prf_spare2);                -- XXCMN:予備２
    gv_spare3             := FND_PROFILE.VALUE(gv_prf_spare3);                -- XXCMN:予備３
--
    -- =========================================
    -- プロファイルオプション取得エラーチェック
    -- =========================================
    IF (gv_whse_code IS NULL) THEN  -- XXCMN:原価倉庫プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_whse_code_name)       -- XXCMN:原価倉庫
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_div IS NULL) THEN  -- XXCMN:原価方法プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_cost_div_name)        -- XXCMN:原価方法
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_raw_material_cost IS NULL) THEN  -- XXCMN:原料プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_raw_mat_cost_name)    -- XXCMN:原料
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_agein_cost IS NULL) THEN  --  XXCMN:再製費プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_agein_cost_name)      --  XXCMN:再製費
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_material_cost IS NULL) THEN  -- XXCMN:資材費プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_material_cost_name)   -- XXCMN:資材費
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_pack_cost IS NULL) THEN  -- XXCMN:包装費プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_pack_cost_name)       -- XXCMN:包装費
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_out_order_cost IS NULL) THEN  -- XXCMN:外注加工費プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_out_order_cost_name)  -- XXCMN:外注加工費
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_safekeep_cost IS NULL) THEN  -- XXCMN:保管費プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_safekeep_cost_name)   -- XXCMN:保管費
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_other_expense_cost IS NULL) THEN  -- XXCMN:その他経費プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_other_cost_name)      -- XXCMN:その他経費
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_spare1 IS NULL) THEN  -- XXCMN:予備１プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_spare1_name)          -- XXCMN:予備１
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_spare2 IS NULL) THEN  -- XXCMN:予備２プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_spare2_name)          -- XXCMN:予備２
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_spare3 IS NULL) THEN  -- XXCMN:予備３プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_prf_spare3_name)          -- XXCMN:予備３
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===========================
    -- 在庫クローズ年月取得
    -- ===========================
    gv_close_date := xxcmn_common_pkg.get_opminv_close_period;
--
    -- ===========================
    -- 原価カレンダ情報取得
    -- ===========================
    -- INパラメータ.カレンダコードに入力がある場合
    IF (gv_calendar_code IS NOT NULL) THEN
      -- カレンダコードを条件に原価カレンダ情報を取得
      SELECT ccd.calendar_code     calendar_code -- カレンダコード
            ,TRUNC(ccd.start_date) start_date    -- 開始日
            ,TRUNC(ccd.end_date)   end_date      -- 終了日
            ,ccd.period_code       period_code   -- 期間
      INTO   gv_calendar_code                -- カレンダコード
            ,gt_start_date                   -- 開始日
            ,gt_end_date                     -- 終了日
            ,gt_period_code                  -- 期間
      FROM   cm_cldr_dtl       ccd           -- 原価カレンダ
      WHERE  ccd.calendar_code = gv_calendar_code
      ;
--
    -- INパラメータ.カレンダコードに入力なしの場合
    ELSE
      -- SYSDATEを条件に原価カレンダ情報を取得
      SELECT ccd.calendar_code     calendar_code -- カレンダコード
            ,TRUNC(ccd.start_date) start_date    -- 開始日
            ,TRUNC(ccd.end_date)   end_date      -- 終了日
            ,ccd.period_code       period_code   -- 期間
      INTO   gv_calendar_code                -- カレンダコード
            ,gt_start_date                   -- 開始日
            ,gt_end_date                     -- 終了日
            ,gt_period_code                  -- 期間
      FROM   cm_cldr_dtl       ccd           -- 原価カレンダ
      WHERE  ccd.start_date <= TRUNC(SYSDATE)
      AND    ccd.end_date   >= TRUNC(SYSDATE)
      ;
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
  END get_other_data;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ロック取得処理(E-4)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf            OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg            OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- プログラム名
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
    -- 品目原価マスタ(CM_CMPT_DTL)
    CURSOR cm_cmpt_dtl_cur IS
      SELECT 1
      FROM   cm_cmpt_dtl ccd  -- 品目原価マスタ
      WHERE  EXISTS (
               SELECT 1
               FROM   xxpo_price_headers         xph     -- 仕入/標準単価ヘッダ
                     ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
               WHERE  xph.item_id    = ccd.item_id
               AND    xph.item_id    = xicv.item_id
               AND    xph.price_type = gv_price_type_normal            -- マスタ区分2：標準
               AND    ROWNUM = 1)
      AND    ccd.calendar_code  = gv_calendar_code      -- カレンダコード
      FOR UPDATE NOWAIT
    ;
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
    -- ===========================
    -- 品目原価マスタロック取得
    -- ===========================
    BEGIN
       <<lock_loop>>
      FOR lr_cm_cmpt_dtl IN cm_cmpt_dtl_cur
      LOOP
        EXIT;
      END LOOP lock_loop;
--
    EXCEPTION
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- モジュール名略称:XXCMN
                         ,gv_msg_xxcmn10019      -- メッセージ:APP-XXCMN-10019 ロックエラー
                         ,gv_tkn_table           -- トークンTABLE
                         ,gv_cm_cmpt_dtl)        -- 品目原価マスタ
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_lock;
--
  /***********************************************************************************
   * Procedure Name   : get_cmpntcls_mst
   * Description      : コンポーネント区分マスタ取得処理(E-5)
   ***********************************************************************************/
  PROCEDURE get_cmpntcls_mst(
    ov_errbuf          OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cmpntcls_mst'; -- プログラム名
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
    ln_cnt      NUMBER := 0;  -- ループカウント
--
    -- *** ローカル・カーソル ***
    -- コンポーネント区分カーソル
    CURSOR cmpnt_cur IS
      SELECT ccmt.cost_cmpntcls_id    cost_cmpntcls_id    -- コンポーネント区分ID
            ,ccmt.cost_cmpntcls_desc  cost_cmpntcls_desc  -- コンポーネント区分名
      FROM   cm_cmpt_mst_tl ccmt              -- コンポーネント区分マスタ翻訳
      WHERE  ccmt.language = userenv('LANG')  -- 言語
      AND    ccmt.cost_cmpntcls_desc IN (     -- コンポーネント区分名
               gv_raw_material_cost           -- XXCMN:原料
              ,gv_agein_cost                  -- XXCMN:再製費
              ,gv_material_cost               -- XXCMN:資材費
              ,gv_pack_cost                   -- XXCMN:包装費
              ,gv_out_order_cost              -- XXCMN:外注加工費
              ,gv_safekeep_cost               -- XXCMN:保管費
              ,gv_other_expense_cost          -- XXCMN:その他経費
              ,gv_spare1                      -- XXCMN:予備１
              ,gv_spare2                      -- XXCMN:予備２
              ,gv_spare3                      -- XXCMN:予備３
             )
    ;
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
    -- ===========================
    -- コンポーネント区分取得
    -- ===========================
    <<cmpnt_loop>>
    FOR lr_cmpnt IN cmpnt_cur
    LOOP
      ln_cnt := ln_cnt + 1;   -- カウント
--
      -- コンポーネント区分取得
      cost_cmpntcls_id_tab(ln_cnt)   := lr_cmpnt.cost_cmpntcls_id;
      cost_cmpntcls_desc_tab(ln_cnt) := lr_cmpnt.cost_cmpntcls_desc;
--
    END LOOP cmpnt_loop;
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
  END get_cmpntcls_mst;
--
  /***********************************************************************************
   * Procedure Name   : get_unit_price_summary
   * Description      : 単価合計取得処理(E-7)
   ***********************************************************************************/
  PROCEDURE get_unit_price_summary(
    it_price_header_id     IN  xxpo_price_headers.price_header_id%TYPE  -- ヘッダID
   ,it_cost_cmpntcls_desc  IN  cm_cmpt_mst_tl.cost_cmpntcls_desc%TYPE   -- コンポーネント名
   ,ot_cmpnt_cost_price    OUT NOCOPY xxpo_price_lines.unit_price%TYPE  -- 単価合計
   ,ov_errbuf          OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_unit_price_summary'; -- プログラム名
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
    -- コンポーネント区分ごとの単価合計値取得。取得できない場合は0。
    SELECT NVL(SUM(xpl.unit_price),0)   unit_price       -- 単価合計
    INTO   ot_cmpnt_cost_price
    FROM   xxpo_price_lines      xpl              -- 仕入/標準原価明細
          ,xxcmn_lookup_values_v xlvv1            -- クイックコード情報VIEW  費目区分情報
          ,xxcmn_lookup_values_v xlvv2            -- クイックコード情報VIEW  原価内訳区分情報
    WHERE  -- *** 結合条件 仕入/標準原価明細・費目区分情報 *** --
           xpl.expense_item_type = xlvv1.attribute1
           -- *** 結合条件 費目区分情報・原価内訳区分情報 *** --
    AND    xlvv1.attribute2 = xlvv2.lookup_code
           -- *** 抽出条件 *** --
    AND    xpl.price_header_id = it_price_header_id     -- ヘッダID
    AND    xlvv1.lookup_type   = gv_expense_item_type   -- 費目区分
    AND    xlvv2.lookup_type   = gv_cmpntcls_type       -- 原価内訳区分
    AND    xlvv2.meaning       = it_cost_cmpntcls_desc  -- コンポーネント区分名
    ;
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
  END get_unit_price_summary;
--
  /***********************************************************************************
   * Procedure Name   : ins_cm_cmpt_dtl
   * Description      : 品目原価マスタ登録処理(E-9)
   ***********************************************************************************/
  PROCEDURE ins_cm_cmpt_dtl(
    ir_head_rec        IN  GMF_ITEMCOST_PUB.HEADER_REC_TYPE          -- 品目原価マスタヘッダレコード
   ,ir_this_tbl        IN  GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE  -- 原価内訳レコード
   ,ov_errbuf          OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cm_cmpt_dtl'; -- プログラム名
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
    cv_api_ver        CONSTANT NUMBER := 2.0;
--
    -- *** ローカル変数 ***
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lr_ids_tbl        GMF_ITEMCOST_PUB.COSTCMPNT_IDS_TBL_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(5000);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
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
    -- 初期化
    FND_MSG_PUB.INITIALIZE(); -- APIメッセージ
--
    -- 品目原価マスタ登録API
    GMF_ITEMCOST_PUB.CREATE_ITEM_COST(
      P_API_VERSION         => cv_api_ver
     ,P_INIT_MSG_LIST       => FND_API.G_FALSE
     ,P_COMMIT              => FND_API.G_FALSE
     ,X_RETURN_STATUS       => lv_return_status
     ,X_MSG_COUNT           => ln_msg_count
     ,X_MSG_DATA            => lv_msg_data
     ,P_HEADER_REC          => ir_head_rec
     ,P_THIS_LEVEL_DTL_TBL  => ir_this_tbl
     ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
     ,X_COSTCMPNT_IDS       => lr_ids_tbl
    );
--
    -- 品目原価マスタ登録APIがエラーの場合
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      -- エラーログ出力
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     -- エラー・メッセージ
       ,ov_retcode    => lv_retcode    -- リターン・コード
       ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ
      );
--
      -- エラーログ出力に失敗した場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn            -- モジュール名略称
                       ,gv_msg_xxcmn10018   -- メッセージ：APP-XXCMN-10018 APIエラー(コンカレント)
                       ,gv_tkn_api_name     -- トークン
                       ,gv_api_create_item_cost) -- GMF_ITEMCOST_PUB.CREATE_ITEM_COST
                     ,1,5000);
      lv_errbuf := lv_errmsg;
--
      RAISE global_process_expt;
--
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
  END ins_cm_cmpt_dtl;
--
--
  /***********************************************************************************
   * Procedure Name   : upd_cm_cmpt_dtl
   * Description      : 品目原価マスタ更新処理(E-10)
   ***********************************************************************************/
  PROCEDURE upd_cm_cmpt_dtl(
    ir_head_rec        IN  GMF_ITEMCOST_PUB.HEADER_REC_TYPE          -- 品目原価マスタヘッダレコード
   ,ir_this_tbl        IN  GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE  -- 原価内訳レコード
   ,ov_errbuf          OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cm_cmpt_dtl'; -- プログラム名
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
    cv_api_ver        CONSTANT NUMBER := 2.0;
--
    -- *** ローカル変数 ***
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(5000);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
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
    -- 初期化
    FND_MSG_PUB.INITIALIZE(); -- APIメッセージ
--
    -- 品目原価マスタ更新API
    GMF_ITEMCOST_PUB.UPDATE_ITEM_COST(
      P_API_VERSION         => cv_api_ver
     ,P_INIT_MSG_LIST       => FND_API.G_FALSE
     ,P_COMMIT              => FND_API.G_FALSE
     ,X_RETURN_STATUS       => lv_return_status
     ,X_MSG_COUNT           => ln_msg_count
     ,X_MSG_DATA            => lv_msg_data
     ,P_HEADER_REC          => ir_head_rec
     ,P_THIS_LEVEL_DTL_TBL  => ir_this_tbl
     ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
    );
--
    -- 品目原価マスタ更新APIがエラーの場合
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      -- エラーログ出力
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     -- エラー・メッセージ
       ,ov_retcode    => lv_retcode    -- リターン・コード
       ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ
      );
--
      -- エラーログ出力に失敗した場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn            -- モジュール名略称
                       ,gv_msg_xxcmn10018   -- メッセージ：APP-XXCMN-10018 APIエラー(コンカレント)
                       ,gv_tkn_api_name     -- トークン
                       ,gv_api_update_item_cost)        -- GMF_ITEMCOST_PUB.UPDATE_ITEM_COST
                     ,1,5000);
      lv_errbuf := lv_errmsg;
--
      RAISE global_process_expt;
--
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
  END upd_cm_cmpt_dtl;
--
  /**********************************************************************************
   * Procedure Name   : detail_rec_loop
   * Description      : 明細レコード取得LOOP
   ***********************************************************************************/
  PROCEDURE detail_rec_loop(
    it_item_id           IN  xxcmn_item_mst_v.item_id%TYPE            -- 品目ID
   ,it_cost_manage_code  IN  xxcmn_item_mst_v.cost_manage_code%TYPE   -- 原価管理区分
   ,it_price_header_id   IN  xxpo_price_headers.price_header_id%TYPE  -- ヘッダID
   ,or_ins_this_tbl      OUT GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE -- 原価内訳レコード(登録)
   ,or_upd_this_tbl      OUT GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE -- 原価内訳レコード(更新)
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'detail_rec_loop'; -- プログラム名
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
    lr_ins_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- 原価内訳レコード(登録)
    lr_upd_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- 原価内訳レコード(更新)
    lt_master_receive_date cm_cmpt_dtl.attribute30%TYPE;   -- マスタ受信日
    lt_cmpntcost_id        cm_cmpt_dtl.cmpntcost_id%TYPE;  -- 原価詳細ID
    ln_unit_price_ttl      NUMBER;                         -- 単価合計
    ln_update_flg          NUMBER;                         -- 1の場合、更新。0の場合、登録。
    ln_ins_cnt             NUMBER;                         -- 登録件数カウント
    ln_upd_cnt             NUMBER;                         -- 更新件数カウント
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
    ln_ins_cnt := 0;
    ln_upd_cnt := 0;
    lr_ins_this_tbl.DELETE;
    lr_upd_this_tbl.DELETE;
--
    -- コンポーネント区分の数だけLOOP
    <<cmpntcls_loop>>
    FOR loop_cnt IN 1..cost_cmpntcls_id_tab.COUNT
    LOOP
      -- ===============================
      -- E-7.単価合計取得処理
      -- ===============================
      -- コンポーネント区分ごとに単価合計を取得
      get_unit_price_summary(
        it_price_header_id    => it_price_header_id                -- ヘッダID
       ,it_cost_cmpntcls_desc => cost_cmpntcls_desc_tab(loop_cnt)  -- コンポーネント名
       ,ot_cmpnt_cost_price   => ln_unit_price_ttl                 -- 単価合計
       ,ov_errbuf             => lv_errbuf                         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode                        -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg                         -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- E-8.登録・更新判定処理
      -- ===============================
      -- 品目原価マスタを検索
      BEGIN
        SELECT ccd.attribute30     master_receive_date   -- マスタ受信日
              ,ccd.cmpntcost_id    cmpntcost_id          -- 原価詳細ID
        INTO   lt_master_receive_date                    -- マスタ受信日
              ,lt_cmpntcost_id                           -- 原価詳細ID
        FROM   cm_cmpt_dtl         ccd                   -- 品目原価マスタ
        WHERE  ccd.item_id          = it_item_id         -- 品目ID
        AND    ccd.cost_cmpntcls_id = cost_cmpntcls_id_tab(loop_cnt) -- コンポーネント区分ID
        AND    ccd.period_code      = gt_period_code      -- 期間
        AND    ccd.whse_code        = gv_whse_code        -- 倉庫
        AND    ccd.calendar_code    = gv_calendar_code    -- カレンダ
        AND    ccd.cost_mthd_code   = gv_cost_div         -- 原価方法
        AND    ccd.delete_mark      = 0                   -- 削除フラグ
        AND    ROWNUM               = 1
        ;
--
        -- データがすでにあるので、更新
        ln_update_flg := 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データがないので、登録
          ln_update_flg := 0;
      END;
--
      -- 以下の場合、原価内訳レコード(登録)に値をセット
      -- キーで品目原価マスタを検索できない
      IF (ln_update_flg = 0) THEN
        -- 登録件数カウント
        ln_ins_cnt := ln_ins_cnt + 1;
--
        -- 原価内訳レコード(登録)に値をセット
        lr_ins_this_tbl(ln_ins_cnt).cost_cmpntcls_id   := cost_cmpntcls_id_tab(loop_cnt); -- コンポーネント区分ID
        lr_ins_this_tbl(ln_ins_cnt).cost_analysis_code := '0000'; -- 原価分析区分
        lr_ins_this_tbl(ln_ins_cnt).burden_ind         := 0; -- 
        lr_ins_this_tbl(ln_ins_cnt).delete_mark        := 0; -- 削除フラグ
        lr_ins_this_tbl(ln_ins_cnt).cmpnt_cost         := ln_unit_price_ttl; -- コンポーネント原価
--
      -- 以下の場合、原価内訳レコード(更新)に値をセット
      --   ・キーで品目原価マスタを検索できる
      --   ・マスタ受信日に値なし
      ELSIF (ln_update_flg = 1) 
      AND   (lt_master_receive_date IS NULL) THEN
        -- 以下の場合、警告。更新処理を行わずに処理をスキップする。
        --   ・原価管理区分が1：標準原価かつ、開始日の年月≦在庫クローズ日
        IF  ((it_cost_manage_code = gv_cost_manage_code_normal) AND (TO_CHAR(gt_start_date, gv_yyyymm) <= gv_close_date)) THEN
          -- 警告
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn            -- モジュール名略称
                           ,gv_msg_xxcmn10601)  -- メッセージ：APP-XXCMN-10161 在庫クローズエラー
                         ,1,5000);
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := lv_errmsg;
          ov_retcode := gv_status_warn;
--
        -- 上記以外の場合、更新処理
        ELSE
          -- 更新件数カウント
          ln_upd_cnt := ln_upd_cnt + 1;
--
          -- 原価内訳レコード(更新)に値をセット
          lr_upd_this_tbl(ln_upd_cnt).cmpntcost_id       := lt_cmpntcost_id;                         -- 原価詳細ID
          lr_upd_this_tbl(ln_upd_cnt).cost_cmpntcls_id   := cost_cmpntcls_id_tab(loop_cnt); -- コンポーネント区分ID
          lr_upd_this_tbl(ln_upd_cnt).cost_analysis_code := '0000'; -- 原価分析区分
          lr_upd_this_tbl(ln_upd_cnt).burden_ind         := 0; -- 
          lr_upd_this_tbl(ln_upd_cnt).delete_mark        := 0; -- 削除フラグ
          lr_upd_this_tbl(ln_upd_cnt).cmpnt_cost         := ln_unit_price_ttl; -- コンポーネント原価
--
        END IF;
--
      -- 以下の場合、本社インタフェースされた品目なので、処理対象外。
      --   ・キーで品目原価マスタを検索できる
      --   ・マスタ受信日に値あり
      ELSE
        NULL;
--
      END IF;
--
    END LOOP cmpntcls_loop;
--
   -- OUTパラメータにセット
   or_ins_this_tbl := lr_ins_this_tbl;
   or_upd_this_tbl := lr_upd_this_tbl;
--
  EXCEPTION
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
  END detail_rec_loop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf            OUT NOCOPY VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT NOCOPY VARCHAR2    --   リターン・コード             --# 固定 #
   ,ov_errmsg            OUT NOCOPY VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
   ,iv_calendar_code     IN  VARCHAR2    --   カレンダコード
   ,iv_prod_class_code   IN  VARCHAR2    --   商品区分
   ,iv_item_class_code   IN  VARCHAR2    --   品目区分
   ,iv_item_code         IN  VARCHAR2    --   品目
   ,iv_update_date_from  IN  VARCHAR2    --   更新日時FROM
   ,iv_update_date_to    IN  VARCHAR2    --   更新日時TO
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_head_rec            GMF_ITEMCOST_PUB.HEADER_REC_TYPE;         -- 品目原価マスタヘッダレコード
    lr_ins_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- 原価内訳レコード(登録)
    lr_upd_this_tbl        GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE; -- 原価内訳レコード(更新)

--
    -- *** ローカル・カーソル ***
    CURSOR main_cur IS
      SELECT xph.price_header_id         price_header_id   -- ヘッダID
            ,xph.item_id                 item_id           -- 品目ID
            ,ximv.cost_manage_code       cost_manage_code  -- 原価管理区分
      FROM   xxpo_price_headers          xph               -- 仕入/標準原価ヘッダ
            ,xxcmn_item_mst_v            ximv              -- OPM品目情報VIEW
            ,xxcmn_item_categories5_v    xicv              -- OPM品目カテゴリ割当情報VIEW
            ,(
             SELECT xph1.item_id                item_id
                   ,MAX(xph1.start_date_active) start_date_active
             FROM   xxpo_price_headers         xph1
             WHERE ((xph1.start_date_active BETWEEN gt_start_date AND gt_end_date)  -- 適用開始日が原価カレンダ開始日範囲内～原価カレンダ終了日範囲内
             OR     (xph1.end_date_active   BETWEEN gt_start_date AND gt_end_date)  -- 適用終了日が原価カレンダ開始日範囲内～原価カレンダ終了日範囲内
             OR     ((xph1.start_date_active < gt_start_date)                       -- 適用開始日が原価カレンダ開始日より前かつ、適用終了日が原価カレンダ終了日より後
               AND   (xph1.end_date_active   > gt_end_date)))
             AND    xph1.price_type = gv_price_type_normal  -- マスタ区分2：標準
             GROUP BY xph1.item_id)       subsql            -- 範囲内で最新のデータ
      WHERE  -- *** 結合条件 仕入/標準原価ヘッダ・OPM品目情報VIEW *** --
             xph.item_id = ximv.item_id
             -- *** 結合条件 仕入/標準原価ヘッダ・OPM品目カテゴリ割当情報VIEW *** --
      AND    xph.item_id = xicv.item_id
             -- *** 結合条件 仕入/標準原価ヘッダ・サブクエリ *** --
      AND    xph.item_id           = subsql.item_id
      AND    xph.start_date_active = subsql.start_date_active
             -- *** 抽出条件 *** --
      AND    xicv.prod_class_code   = NVL(gv_prod_class_code,  xicv.prod_class_code) -- 商品区分に入力がある場合、条件に追加
      AND    xicv.item_class_code   = NVL(gv_item_class_code,  xicv.item_class_code) -- 品目区分に入力がある場合、条件に追加
      AND    xph.item_code          = NVL(gv_item_code,        xph.item_code)        -- 品目に入力がある場合、条件に追加
      AND    xph.last_update_date  >= NVL(gd_update_date_from, xph.last_update_date) -- 更新日時FROMに入力がある場合、条件に追加
      AND    xph.last_update_date  <= NVL(gd_update_date_to,   xph.last_update_date) -- 更新日時TOに入力がある場合、条件に追加
      AND    xph.price_type         = gv_price_type_normal                           -- マスタ区分2：標準
      AND    ((xph.start_date_active BETWEEN gt_start_date AND gt_end_date)          -- 適用開始日が原価カレンダ開始日範囲内～原価カレンダ終了日範囲内
        OR    (xph.end_date_active   BETWEEN gt_start_date AND gt_end_date)          -- 適用終了日が原価カレンダ開始日範囲内～原価カレンダ終了日範囲内
        OR    ((xph.start_date_active < gt_start_date)                               -- 適用開始日が原価カレンダ開始日より前かつ、適用終了日が原価カレンダ終了日より後
          AND  (xph.end_date_active   > gt_end_date)))
    ;
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
    -- ===============================
    -- E-1.入力パラメータ出力処理
    -- ===============================
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_calendar_code_name       || gv_msg_part || iv_calendar_code);    -- カレンダコード
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_prod_class_name    || gv_msg_part || iv_prod_class_code);  -- 商品区分
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_item_class_name    || gv_msg_part || iv_item_class_code);  -- 品目区分
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_item_code_name     || gv_msg_part || iv_item_code);        -- 品目
-- 2009/01/08 v1.1 N.Yoshida mod start
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_from_name || gv_msg_part || iv_update_date_from); -- 更新日時FROM
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_to_name   || gv_msg_part || iv_update_date_to);   -- 更新日時TO
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_from_name || gv_msg_part || iv_update_date_from || gc_f_time); -- 更新日時FROM
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_param_upd_date_to_name   || gv_msg_part || iv_update_date_to || gc_e_time);   -- 更新日時TO
-- 2009/01/08 v1.1 N.Yoshida mod end
--
    gv_calendar_code    := iv_calendar_code;    -- カレンダコード
    gv_prod_class_code  := iv_prod_class_code;  -- 商品区分
    gv_item_class_code  := iv_item_class_code;  -- 品目区分
    gv_item_code        := iv_item_code;        -- 品目
-- 2009/01/08 v1.1 N.Yoshida mod start
--    gd_update_date_from := FND_DATE.STRING_TO_DATE(iv_update_date_from, gv_yyyymmddhh24miss); -- 更新日時FROM
--    gd_update_date_to   := FND_DATE.STRING_TO_DATE(iv_update_date_to, gv_yyyymmddhh24miss);   -- 更新日時TO
    gd_update_date_from := FND_DATE.STRING_TO_DATE(iv_update_date_from || gc_f_time, gv_yyyymmddhh24miss); -- 更新日時FROM
    gd_update_date_to   := FND_DATE.STRING_TO_DATE(iv_update_date_to || gc_e_time, gv_yyyymmddhh24miss);   -- 更新日時TO
-- 2009/01/08 v1.1 N.Yoshida mod end
--
    -- ===============================
    -- E-2.パラメータチェック
    -- ===============================
    parameter_check(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-3.関連データ取得処理
    -- ===============================
    get_other_data(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-4.ロック取得処理
    -- ===============================
    get_lock(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-5.コンポーネント区分取得処理
    -- ===============================
    get_cmpntcls_mst(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- E-6.対象データ取得処理
    -- ===============================
    <<main_loop>>
    FOR lr_main IN main_cur
    LOOP
      -- 明細レコード初期化
      lr_ins_this_tbl.DELETE;
      lr_upd_this_tbl.DELETE;
      --
      -- 品目原価マスタヘッダレコードに値をセット
      lr_head_rec.item_id        := lr_main.item_id;      -- 品目ID
      lr_head_rec.whse_code      := gv_whse_code;         -- XXCMN:原価倉庫
      lr_head_rec.period_code    := gt_period_code;       -- 期間
      lr_head_rec.calendar_code  := gv_calendar_code;     -- カレンダコード
      lr_head_rec.cost_mthd_code := gv_cost_div;          -- XXCMN:原価方法
      lr_head_rec.user_name      := FND_GLOBAL.USER_NAME; -- ユーザー名
--
      -- ===============================
      -- 明細レコード取得LOOP
      -- ===============================
      detail_rec_loop(
        it_item_id           => lr_main.item_id           -- 品目ID
       ,it_cost_manage_code  => lr_main.cost_manage_code  -- 原価管理区分
       ,it_price_header_id   => lr_main.price_header_id   -- ヘッダID
       ,or_ins_this_tbl      => lr_ins_this_tbl -- 原価内訳レコード(登録)
       ,or_upd_this_tbl      => lr_upd_this_tbl -- 原価内訳レコード(更新)
       ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- 警告終了の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- 警告カウント
        gn_warn_cnt := gn_warn_cnt + 1;
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
        -- OUTパラメータセット
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
      END IF;
--
      -- ===============================
      -- E-9.品目原価マスタ登録処理
      -- ===============================
      IF (lr_ins_this_tbl.COUNT > 0) THEN
        ins_cm_cmpt_dtl(
          ir_head_rec        => lr_head_rec      -- 品目原価マスタヘッダレコード
         ,ir_this_tbl        => lr_ins_this_tbl  -- 原価内訳レコード(登録)
         ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
         ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
     END IF;
--
      -- ===============================
      -- E-10.品目原価マスタ更新処理
      -- ===============================
      IF (lr_upd_this_tbl.COUNT > 0) THEN
        upd_cm_cmpt_dtl(
          ir_head_rec        => lr_head_rec      -- 品目原価マスタヘッダレコード
         ,ir_this_tbl        => lr_upd_this_tbl  -- 原価内訳レコード(更新)
         ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
         ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- 成功件数カウント
      IF ((lr_ins_this_tbl.COUNT > 0) OR (lr_upd_this_tbl.COUNT > 0)) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP main_loop;
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
    errbuf               OUT NOCOPY VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,retcode              OUT NOCOPY VARCHAR2    --   リターン・コード             --# 固定 #
   ,iv_calendar_code     IN  VARCHAR2    --   カレンダコード
   ,iv_prod_class_code   IN  VARCHAR2    --   商品区分
   ,iv_item_class_code   IN  VARCHAR2    --   品目区分
   ,iv_item_code         IN  VARCHAR2    --   品目
   ,iv_update_date_from  IN  VARCHAR2    --   更新日時FROM
   ,iv_update_date_to    IN  VARCHAR2    --   更新日時TO
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
      lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,lv_retcode           -- リターン・コード             --# 固定 #
     ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_calendar_code     --   カレンダコード
     ,iv_prod_class_code   --   商品区分
     ,iv_item_class_code   --   品目区分
     ,iv_item_code         --   品目
     ,iv_update_date_from  --   更新日時FROM
     ,iv_update_date_to    --   更新日時TO
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
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- E-15.リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
END xxcmn820005c;
/
