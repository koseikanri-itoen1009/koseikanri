create or replace PACKAGE BODY xxwip_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwip_common_pkg(BODY)
 * Description            : 共通関数(XXWIP)(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  check_lastmonth_close   P        前月運賃締後チェック
 *  get_ship_method         P        配送区分情報VIEW抽出
 *  get_delivery_distance   P        配送距離アドオンマスタ抽出 
 *  get_delivery_company    P        運賃用運送業者アドオンマスタ抽出
 *  get_delivery_charges    P        運賃アドオンマスタ抽出
 *  change_code_division    P        運賃コード区分変換
 *  deliv_rcv_ship_conv_qty F   NUM  運賃入出庫換算関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/11/13   1.0   H.Itou           新規作成
 *
 *****************************************************************************************/
--
--###############################  固定グローバル定数宣言部 START   ###############################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';   --正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';   --警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2';   --失敗
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';   --ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';   --ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';   --ステータス(失敗)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_prof_cost_price CONSTANT VARCHAR2(26) := 'XXCMN_COST_PRICE_WHSE_CODE';
--
--#####################################  固定部 END   #############################################
--
--###############################  固定グローバル変数宣言部 START   ###############################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 処理結果
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- 失敗件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
  gn_report_cnt    NUMBER;                    -- レポート件数
--
--#####################################  固定部 END   #############################################
--
--##################################  固定共通例外宣言部 START   ##################################
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
--#####################################  固定部 END   #############################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  check_lock_expt        EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt,   -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxwip_common3_pkg'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';            -- モジュール名略称：XXCMN 共通
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';            -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
  -- メッセージ
  gv_xxcom_nodata_err   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001';  -- 対象データ未取得エラー
  gv_xxcom_noprof_err   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  -- プロファイル取得エラー
  gv_xxcom_para_err     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010';  -- パラメータエラー
  -- トークン
  gv_tkn_table        CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_key          CONSTANT VARCHAR2(100) := 'KEY';
  gv_tkn_ng_profile   CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_para         CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_tkn_value        CONSTANT VARCHAR2(100) := 'VALUE';
--
  -- プロファイル
  gv_prf_grace_period   CONSTANT VARCHAR2(50) := 'XXWIP_GRACE_PERIOD';  -- プロファイル：運賃計算用猶予期間
--
  -- タイプ
  gv_type_y           CONSTANT VARCHAR2(1)   := 'Y';                -- タイプ：Y
  gv_type_n           CONSTANT VARCHAR2(1)   := 'N';                -- タイプ：N
--
  -- 名称
  gv_acct_periods     CONSTANT VARCHAR2(100) := '在庫会計期間';
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
   * Function Name    : check_lastmonth_close
   * Description      : 前月運賃締後チェック
   ***********************************************************************************/
  PROCEDURE check_lastmonth_close(
    ov_close_type   OUT NOCOPY VARCHAR2,    -- 締め区分（Y：締め前、N：締め後）
    ov_errbuf       OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_lastmonth_close' ; --プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_open_flag            org_acct_periods.open_flag%TYPE;          -- オープンフラグ
    ld_period_close_date    org_acct_periods.period_close_date%TYPE;  -- クローズ日付
    lv_orgn_code            sy_orgn_mst.orgn_code%TYPE;               -- 組織
    ln_grace_period         NUMBER;                                   -- 運賃計算用猶予期間
    ld_temp_date            DATE;                                     -- クローズ日付+猶予期間
--
  BEGIN
    -- ***********************************************
    -- プロファイル：原価倉庫 取得
    -- ***********************************************
    lv_orgn_code := FND_PROFILE.VALUE(gv_prof_cost_price);
    IF (lv_orgn_code IS NULL) THEN -- プロファイルが取得できない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            gv_prof_cost_price);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ***********************************************
    -- プロファイル：運賃計算用猶予期間 取得
    -- ***********************************************
    ln_grace_period := FND_PROFILE.VALUE(gv_prf_grace_period);
    IF (ln_grace_period IS NULL) THEN -- プロファイルが取得できない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            gv_prf_grace_period);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ***********************************************
    --  在庫会計期間 より
    --    オープンフラグ、クローズ日取得
    -- ***********************************************
    BEGIN
      SELECT  oap.open_flag            -- オープンフラグ
             ,oap.period_close_date    -- クローズ日付
      INTO    lv_open_flag
             ,ld_period_close_date
      FROM    org_acct_periods        oap -- 在庫会計期間
             ,ic_whse_mst             iwm -- OPM倉庫マスタ
      WHERE   oap.period_start_date  =
              TO_DATE(TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'YYYYMM') || '01', 'YYYYMMDD')  -- 前月の初日
      AND     oap.organization_id   = iwm.mtl_organization_id                          -- 在庫組織ID
      AND     iwm.whse_code = lv_orgn_code;                                            -- 倉庫コード
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN                       --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                              gv_xxcom_nodata_err,
                                              gv_tkn_table,
                                              gv_acct_periods,
                                              gv_tkn_key,
                                              lv_orgn_code);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ***********************************************
    -- 締め日判定
    -- ***********************************************
    -- OPEN_FLAGが「Y」の場合
    IF (lv_open_flag = gv_type_y) THEN
      -- 前月カレンダーはOPENなのでYを返す
      ov_close_type :=  gv_type_y;
--
    -- OPEN_FLAGが「N」の場合
    ELSE
      -- ***********************************************
      -- 営業日取得 呼出
      --   クローズ日付 + 猶予期間の営業日を取得
      -- ***********************************************
      xxwip_common_pkg.get_business_date(
        id_date           => ld_PERIOD_CLOSE_DATE   -- IN  クローズ日付
       ,in_period         => ln_grace_period        -- IN← プロファイルオプション 猶予期間
       ,od_business_date  => ld_temp_date           -- OUT クローズ日付+猶予期間
       ,ov_errbuf         => lv_errbuf              -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode             -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合、処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- クローズ日付 + 猶予期間がSYSDATE未満の場合
      IF (ld_temp_date <= SYSDATE) THEN
        -- OPENなのでYを返す
        ov_close_type := gv_type_y;
--
      -- クローズ日付+猶予期間がSYSDATEより未来の場合
      ELSE
        -- CLOSEなのでNを返す
        ov_close_type := gv_type_n;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END check_lastmonth_close;
--
  /**********************************************************************************
   * Function Name    : get_ship_method
   * Description      : 配送区分情報VIEW抽出
   ***********************************************************************************/
  PROCEDURE get_ship_method(
    iv_ship_method_code IN  xxwsh_ship_method2_v.ship_method_code%TYPE,           -- 配送区分
    id_target_date      IN  DATE,                                                 -- 判断日
    or_dlvry_dstn       OUT ship_method_rec,                                      -- 配送区分レコード
    ov_errbuf           OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY  VARCHAR2,    -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY  VARCHAR2)    -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_method' ; --プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
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
    -- ***********************************************
    -- 入力パラメータチェック
    -- ***********************************************
    -- 「配送区分」チェック
    IF (iv_ship_method_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'ship_method_code',
                                            gv_tkn_value,
                                            iv_ship_method_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「判定日」チェック
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** 配送区分情報取得
    -- **************************************************
    BEGIN
      SELECT  small_amount_class
            , mixed_class
      INTO    or_dlvry_dstn.small_amount_class    -- 小口区分
            , or_dlvry_dstn.mixed_class           -- 混載区分
      FROM    xxwsh_ship_method2_v
      WHERE   ship_method_code    = iv_ship_method_code     -- 配送区分
      AND     start_date_active  <= TRUNC(id_target_date)   -- 有効開始日
      AND     (                                             -- 有効終了日
                (end_date_active >= TRUNC(id_target_date)) 
                OR
                (end_date_active IS NULL)
              );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 存在なしを設定
        or_dlvry_dstn.small_amount_class := 0;    -- 小口区分
        or_dlvry_dstn.mixed_class := 0;           -- 混載区分
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END get_ship_method;
--
  /**********************************************************************************
   * Function Name    : get_delivery_distance
   * Description      : 配送距離アドオンマスタ抽出
   ***********************************************************************************/
  PROCEDURE get_delivery_distance(
    iv_goods_classe           IN  xxwip_delivery_distance.goods_classe%TYPE,          -- 商品区分
    iv_delivery_company_code  IN  xxwip_delivery_distance.delivery_company_code%TYPE, -- 運送業者
    iv_origin_shipment        IN  xxwip_delivery_distance.origin_shipment%TYPE,       -- 出庫倉庫
    iv_code_division          IN  xxwip_delivery_distance.code_division%TYPE,         -- コード区分
    iv_shipping_address_code  IN  xxwip_delivery_distance.shipping_address_code%TYPE, -- 配送先コード
    id_target_date            IN  DATE,                                               -- 判断日
    or_delivery_distance      OUT delivery_distance_rec,                              -- 配送距離レコード
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ                  --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- リターン・コード                    --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2)    -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_distance' ; --プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
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
    -- ***********************************************
    -- 入力パラメータチェック
    -- ***********************************************
    -- 「商品区分」チェック
    IF (iv_goods_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'goods_classe',
                                            gv_tkn_value,
                                            iv_goods_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「運送業者」チェック
    IF (iv_delivery_company_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_company_code',
                                            gv_tkn_value,
                                            iv_delivery_company_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「出庫倉庫」チェック
    IF (iv_origin_shipment IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'origin_shipment',
                                            gv_tkn_value,
                                            iv_origin_shipment);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「コード区分」チェック
    IF (iv_code_division IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'code_division',
                                            gv_tkn_value,
                                            iv_code_division);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「配送先コード」チェック
    IF (iv_shipping_address_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'shipping_address_code',
                                            gv_tkn_value,
                                            iv_shipping_address_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「判定日」チェック
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** 配送距離アドオンマスタ抽出
    -- **************************************************
    BEGIN
      SELECT  post_distance
            , small_distance
            , consolid_add_distance
            , actual_distance
      INTO    or_delivery_distance.post_distance            -- 車立距離
            , or_delivery_distance.small_distance           -- 小口距離
            , or_delivery_distance.consolid_add_distance    -- 混載割増距離
            , or_delivery_distance.actual_distance          -- 実際距離
      FROM    xxwip_delivery_distance
      WHERE   goods_classe           = iv_goods_classe           -- 商品区分
      AND     delivery_company_code  = iv_delivery_company_code  -- 運送業者
      AND     origin_shipment        = iv_origin_shipment        -- 出庫倉庫
      AND     code_division          = iv_code_division          -- コード区分
      AND     shipping_address_code  = iv_shipping_address_code  -- 配送先コード
      AND     start_date_active     <= TRUNC(id_target_date)     -- 適用開始日
      AND     end_date_active       >= TRUNC(id_target_date);    -- 適用終了日
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 存在なしを設定
        or_delivery_distance.post_distance          := 0; -- 車立距離
        or_delivery_distance.small_distance         := 0; -- 小口距離
        or_delivery_distance.consolid_add_distance  := 0; -- 混載割増距離
        or_delivery_distance.actual_distance        := 0; -- 実際距離
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END get_delivery_distance;
--
  /**********************************************************************************
   * Function Name    : get_delivery_company
   * Description      : 運賃用運送業者アドオンマスタ抽出
   ***********************************************************************************/
  PROCEDURE get_delivery_company(
    iv_goods_classe           IN  xxwip_delivery_company.goods_classe%TYPE,           -- 商品区分
    iv_delivery_company_code  IN  xxwip_delivery_company.delivery_company_code%TYPE,  -- 運送業者
    id_target_date            IN  DATE,                                               -- 判断日
    or_delivery_company       OUT delivery_company_rec,                               -- 運賃用運送業者レコード
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ          --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- リターン・コード            --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2)    -- ユーザー・エラー・メッセージ--# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_company' ; --プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
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
    -- ***********************************************
    -- 入力パラメータチェック
    -- ***********************************************
    -- 「商品区分」チェック
    IF (iv_goods_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'goods_classe',
                                            gv_tkn_value,
                                            iv_goods_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「運送業者」チェック
    IF (iv_delivery_company_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_company_code',
                                            gv_tkn_value,
                                            iv_delivery_company_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「判定日」チェック
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** 運賃用運送業者アドオンマスタ抽出
    -- **************************************************
    BEGIN
      SELECT  small_weight
            , pay_picking_amount
            , bill_picking_amount
      INTO    or_delivery_company.small_weight          -- 小口重量
            , or_delivery_company.pay_picking_amount    -- 支払ピッキング単価
            , or_delivery_company.bill_picking_amount   -- 請求ピッキング単価
      FROM    xxwip_delivery_company
      WHERE   goods_classe           = iv_goods_classe           -- 商品区分
      AND     delivery_company_code  = iv_delivery_company_code  -- 運送業者
      AND     start_date_active     <= TRUNC(id_target_date)     -- 適用開始日
      AND     end_date_active       >= TRUNC(id_target_date);    -- 適用終了日
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 存在なしを設定
        or_delivery_company.small_weight        := 0;  -- 小口重量
        or_delivery_company.pay_picking_amount  := 0;  -- 支払ピッキング単価
        or_delivery_company.bill_picking_amount := 0;  -- 請求ピッキング単価
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END get_delivery_company;
--
  /**********************************************************************************
   * Function Name    : get_delivery_charges
   * Description      : 運賃アドオンマスタ抽出
   ***********************************************************************************/
  PROCEDURE get_delivery_charges(
    iv_p_b_classe               IN  xxwip_delivery_charges.p_b_classe%TYPE,             -- 支払請求区分
    iv_goods_classe             IN  xxwip_delivery_charges.goods_classe%TYPE,           -- 商品区分
    iv_delivery_company_code    IN  xxwip_delivery_charges.delivery_company_code%TYPE,  -- 運送業者
    iv_shipping_address_classe  IN  xxwip_delivery_charges.shipping_address_classe%TYPE,-- 配送区分
    iv_delivery_distance        IN  xxwip_delivery_charges.delivery_distance%TYPE,      -- 運賃距離
    iv_delivery_weight          IN  xxwip_delivery_charges.delivery_weight%TYPE,        -- 重量
    id_target_date              IN  DATE,                                               -- 判断日
    or_delivery_charges         OUT delivery_charges_rec,                               -- 運賃アドオンレコード
    ov_errbuf                   OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ          --# 固定 #
    ov_retcode                  OUT NOCOPY  VARCHAR2,    -- リターン・コード            --# 固定 #
    ov_errmsg                   OUT NOCOPY  VARCHAR2)    -- ユーザー・エラー・メッセージ--# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_charges' ; --プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
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
    -- ***********************************************
    -- 入力パラメータチェック
    -- ***********************************************
    -- 「支払請求区分」チェック
    IF (iv_p_b_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            '_p_b_classe',
                                            gv_tkn_value,
                                            iv_p_b_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「商品区分」チェック
    IF (iv_goods_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'goods_classe',
                                            gv_tkn_value,
                                            iv_goods_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「運送業者」チェック
    IF (iv_delivery_company_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_company_code',
                                            gv_tkn_value,
                                            iv_delivery_company_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「配送区分」チェック
    IF (iv_shipping_address_classe IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'shipping_address_classe',
                                            gv_tkn_value,
                                            iv_shipping_address_classe);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「運賃距離」チェック
    IF (iv_delivery_distance IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_distance',
                                            gv_tkn_value,
                                            iv_delivery_distance);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「重量」チェック
    IF (iv_delivery_weight IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'delivery_weight',
                                            gv_tkn_value,
                                            iv_delivery_weight);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「判定日」チェック
    IF (id_target_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'target_date',
                                            gv_tkn_value,
                                            id_target_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** 運賃アドオンマスタ抽出 運送費
    -- **************************************************
    BEGIN
      SELECT xdc.shipping_expenses
      INTO   or_delivery_charges.shipping_expenses                         -- 運送費
      FROM  (SELECT  shipping_expenses
             FROM    xxwip_delivery_charges
             WHERE   p_b_classe              = iv_p_b_classe               -- 支払請求区分
             AND     goods_classe            = iv_goods_classe             -- 商品区分
             AND     delivery_company_code   = iv_delivery_company_code    -- 運送業者
             AND     shipping_address_classe = iv_shipping_address_classe  -- 配送区分
             AND     delivery_distance      >= iv_delivery_distance        -- 運賃距離
             AND     delivery_weight        >= iv_delivery_weight          -- 重量
             AND     start_date_active      <= TRUNC(id_target_date)       -- 適用開始日
             AND     end_date_active        >= TRUNC(id_target_date)       -- 適用終了日
             ORDER BY delivery_distance ASC, delivery_weight ASC) xdc
      WHERE  ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 存在なしを設定
        or_delivery_charges.shipping_expenses := 0;   -- 運送費
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** 運賃アドオンマスタ抽出 リーフ混載割増
    -- **************************************************
    BEGIN
      SELECT  leaf_consolid_add
      INTO    or_delivery_charges.leaf_consolid_add                 -- リーフ混載割増
      FROM    xxwip_delivery_charges
      WHERE   p_b_classe              = iv_p_b_classe               -- 支払請求区分
      AND     goods_classe            = iv_goods_classe             -- 商品区分
      AND     delivery_company_code   = iv_delivery_company_code    -- 運送業者
      AND     shipping_address_classe = iv_shipping_address_classe  -- 配送区分
      AND     delivery_distance       = 0                           -- 運賃距離（0固定）
      AND     delivery_weight         = 0                           -- 重量（0固定）
      AND     start_date_active      <= TRUNC(id_target_date)       -- 適用開始日
      AND     end_date_active        >= TRUNC(id_target_date);      -- 適用終了日
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 存在なしを設定
        or_delivery_charges.leaf_consolid_add := 0;   -- リーフ混載割増
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END get_delivery_charges;
--
  /**********************************************************************************
   * Function Name    : change_code_division
   * Description      : 運賃コード区分変換
   ***********************************************************************************/
  PROCEDURE change_code_division(
    iv_deliver_to_code_class  IN  xxwsh_carriers_schedule.deliver_to_code_class%TYPE, -- 配送先コード区分
    od_code_division          OUT xxwip_delivery_distance.code_division%TYPE,         -- コード区分（運賃用）
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ          --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- リターン・コード            --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2)    -- ユーザー・エラー・メッセージ--# 固定 #
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'change_code_division' ; --プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
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
    -- **************************************************
    -- *** 配送先コード区分 から コード区分へ変換
    -- **************************************************
    -- ４：倉庫の場合
    IF (iv_deliver_to_code_class = '4') THEN
      od_code_division := '1'; -- 倉庫
--
    -- １１：支給先の場合
    ELSIF (iv_deliver_to_code_class = '11') THEN
      od_code_division := '2'; -- 取引先
--
    -- １：拠点、９：配送の場合
    ELSIF (iv_deliver_to_code_class = '1') OR (iv_deliver_to_code_class = '9') THEN
      od_code_division := '3'; -- 配送先
--
    -- 上記以外の場合
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_para_err,
                                            gv_tkn_para,
                                            'deliver_to_code_class',
                                            gv_tkn_value,
                                            iv_deliver_to_code_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END change_code_division;
--
  /**********************************************************************************
   * Function Name    : deliv_rcv_ship_conv_qty
   * Description      : 運賃入出庫換算関数
   ***********************************************************************************/
  FUNCTION deliv_rcv_ship_conv_qty(
    in_item_cd    IN VARCHAR2,          -- 品目コード
    in_qty        IN NUMBER)            -- 変換対象の数量
    RETURN NUMBER                       -- 変換結果の数量
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deliv_rcv_ship_conv_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    lv_errmsg         VARCHAR2(5000); -- エラーメッセージ
--
    ln_num_of_cases   NUMBER;       -- ケース入り数
    lv_conv_unit      VARCHAR2(50); -- 入出庫換算単位
    ln_num_of_deliver NUMBER;       -- 出荷入数
--
    ln_converted_num  NUMBER; -- 換算結果
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    invalid_conv_unit_expt           EXCEPTION;     -- 不正な換算係数エラー
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_num_of_cases   := NULL;
    lv_conv_unit      := NULL;
    ln_num_of_deliver := NULL;
--
    ln_converted_num := NULL;
--
    -- 品目にひもづく換算係数を取得する。
    SELECT  TO_NUMBER(num_of_cases)       -- ケース入り数
          , conv_unit                     -- 入出庫換算単位
          , TO_NUMBER(num_of_deliver)  -- 出荷入数
    INTO    ln_num_of_cases
          , lv_conv_unit
          , ln_num_of_deliver
    FROM    xxcmn_item_mst_v ximv
    WHERE   ximv.item_no = in_item_cd;
--
    -- **************************************************
    -- 出荷入数が設定されている場合
    -- **************************************************
    IF (ln_num_of_deliver IS NOT NULL ) THEN
      -- 出荷入数 × 変換対象の数量
      ln_converted_num := CEIL(in_qty / ln_num_of_deliver);
--
    -- **************************************************
    -- 入出庫換算単位が設定されている場合
    -- **************************************************
    ELSIF (lv_conv_unit IS NOT NULL ) THEN
      -- 入出庫換算単位 が取得できない場合
      IF (ln_num_of_cases IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10133',
                                              'NUM_OF_CASES',
                                              TO_CHAR(ln_num_of_cases));
        RAISE invalid_conv_unit_expt;
      END IF;
--
      -- 変換対象の数量 ÷ ケース入り数
      ln_converted_num := CEIL(in_qty / ln_num_of_cases);
--
    -- **************************************************
    -- 上記以外の場合
    -- **************************************************
    ELSE
      -- 変換対象の数量そのまま
      ln_converted_num := in_qty;
    END IF;
--
    RETURN ln_converted_num;
--
  EXCEPTION
    WHEN invalid_conv_unit_expt THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END deliv_rcv_ship_conv_qty;
--
END xxwip_common3_pkg;
/
