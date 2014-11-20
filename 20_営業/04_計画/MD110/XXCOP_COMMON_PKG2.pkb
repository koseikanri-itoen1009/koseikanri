create or replace PACKAGE BODY XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : 共通関数パッケージ2(計画)
 * MD.050           : 共通関数    MD070_IPO_COP
 * Version          : 1.4
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.品目情報取得処理
 * get_org_info              11.組織情報取得処理
 * get_num_of_shipped        12.出荷実績取得処理
 * get_num_of_forcast        13.出荷予測取得処理
 * get_stock_plan            14.入庫予定取得処理
 * get_onhand_qty            15.手持在庫取得処理
 * get_deliv_lead_time       16.配送リードタイム取得処理
 * get_unit_delivery         17.配送単位取得処理
 * get_working_days          18.稼働日数取得処理
 * chk_item_exists           19.在庫品目チェック
 * get_scheduled_trans       20.入出庫予定取得処理
 * upd_assignment            21.割当セットAPI起動
 * get_loct_info             22.倉庫情報取得処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   新規作成
 *  2009/04/08    1.1  SCS.Kikuchi      T1_0272,T1_0279,T1_0282,T1_0284対応
 *  2009/05/08    1.2  SCS.Kikuchi      T1_0918,T1_0919対応
 *  2009/07/23    1.3  SCS.Fukada       0000670対応(共通課題：I_E_479)
 *  2009/11/24    1.4  SCS.Itou         本番障害#7 計画が稼動するまで割当セットAPI起動を起動しない。
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--20090508_Ver1.2_T1_0918_SCS.Kikuchi_ADD_START
  -- メッセージ・アプリケーション名（アドオン：販物・計画領域）
  cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP';
  -- メッセージ名
  cv_message_00002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00002';
  -- メッセージトークン
  cv_message_00002_token_1  CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_cmn_drink_cal_cd       CONSTANT VARCHAR2(100) := 'XXCMN_DRNK_WHSE_STD_CAL';        -- ドリンク基準カレンダ
  cv_cmn_drink_cal_cd_name  CONSTANT VARCHAR2(100) := 'XXCMN:ドリンク倉庫基準カレンダ'; -- ドリンク基準カレンダ
--20090508_Ver1.2_T1_0918_SCS.Kikuchi_ADD_END
--
--################################  固定部 END   ##################################
--
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'xxcop_common_pkg2';       -- パッケージ名
--
--
  -- ===============================
  -- ユーザー定義定数
  -- ===============================
  cd_sys_date               CONSTANT DATE        := SYSDATE;
  cn_zero                   CONSTANT NUMBER      := 0;
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  date_null_expt            EXCEPTION;
  date_from_to_expt         EXCEPTION;
  --
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : 品目情報取得処理
   ***********************************************************************************/
  PROCEDURE get_item_info(
    in_inventory_item_id IN  NUMBER,
    on_item_id           OUT  NUMBER,
    ov_item_no           OUT  VARCHAR2,
    ov_item_name         OUT  VARCHAR2,
    ov_prod_class_code   OUT  VARCHAR2,
    on_num_of_case       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_info'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_inactive_ind           CONSTANT NUMBER          := 1;          -- 無効チェックあり
    cv_inv_status_code_inactive CONSTANT VARCHAR2(100) := 'Inactive'; -- 無効
--
    -- *** ローカル変数 ***
    ln_item_id           ic_item_mst_b.item_id%TYPE;
    lv_item_no           ic_item_mst_b.item_no%TYPE;
    lv_item_name         VARCHAR2(50);
    lv_prod_class_code   VARCHAR2(50);
    lv_num_of_case       ic_item_mst_b.attribute11%type;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --品目情報取得
    --==============================================================
    SELECT xicv.item_id
          ,xicv.item_no
          ,xicv.item_short_name
          ,xicv.prod_class_code
          ,xicv.num_of_cases
    INTO   ln_item_id
          ,lv_item_no
          ,lv_item_name
          ,lv_prod_class_code
          ,lv_num_of_case
    FROM   xxcop_item_categories1_v      xicv
    WHERE  xicv.inventory_item_id           = in_inventory_item_id
    AND    xicv.start_date_active          <= cd_sys_date
    AND    xicv.end_date_active            >= cd_sys_date
    AND    xicv.inactive_ind               <> cn_inactive_ind
    AND    xicv.inventory_item_status_code <> cv_inv_status_code_inactive
    ;
    on_item_id           :=  ln_item_id;
    ov_item_no           :=  lv_item_no;
    ov_item_name         :=  lv_item_name;
    ov_prod_class_code   :=  lv_prod_class_code;
--20090408_Ver1.1_T1_0282_SCS.Kikuchi_MOD_START
--    on_num_of_case       :=  TO_NUMBER(lv_num_of_case);
    on_num_of_case       :=  NVL(TO_NUMBER(lv_num_of_case),1);
--20090408_Ver1.1_T1_0282_SCS.Kikuchi_MOD_END
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_item_id       := NULL;
      ov_item_no       := NULL;
      ov_item_name     := NULL;
      ov_prod_class_code := NULL;
      on_num_of_case     := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_item_id       := NULL;
      ov_item_no       := NULL;
      ov_item_name     := NULL;
      ov_prod_class_code := NULL;
      on_num_of_case     := NULL;
  END get_item_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_org_info
   * Description      : 組織情報取得処理
   ***********************************************************************************/
  PROCEDURE get_org_info(
    in_organization_id   IN  NUMBER,
    ov_organization_code OUT  VARCHAR2,
    ov_whse_name         OUT  VARCHAR2,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_org_info'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_del_mark_n             CONSTANT NUMBER        := 0;                        -- 有効
--
    -- *** ローカル変数 ***
    lv_organization_code mtl_parameters.organization_code%TYPE;
    lv_whse_name         ic_whse_mst.whse_name%TYPE;
    lv_loct_cnt          NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --組織情報取得
    --==============================================================
    SELECT mp.organization_code                --  組織コード
          ,iwm.whse_name                       --  倉庫名
    INTO   lv_organization_code
          ,lv_whse_name
    FROM   mtl_parameters              mp,      --  組織パラメータ
           ic_whse_mst                 iwm,     --  OPM倉庫マスタ
           hr_all_organization_units   haou     --  在庫組織マスタ
    WHERE  mp.organization_id       = haou.organization_id
    AND    haou.date_from          <= trunc(cd_sys_date)
    AND   (haou.date_to           >= trunc(cd_sys_date)
     OR    haou.date_to           IS NULL)
    AND    iwm.mtl_organization_id  = haou.organization_id
    AND    iwm.delete_mark          = cn_del_mark_n
    AND    haou.organization_id     = in_organization_id
    ;
    --
    --★2009/02/16　追加
    --==============================================================
    --倉庫存在チェック
    --==============================================================
    SELECT COUNT(ilm.location)                  --  倉庫コード（件数）
    INTO   lv_loct_cnt
    FROM   ic_loct_mst                 ilm      --  OPM保管マスタ
    WHERE  ilm.whse_code = lv_organization_code
    AND    ilm.delete_mark = cn_del_mark_n
    ;
    IF lv_loct_cnt = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;
    --★2009/02/16　追加
    --
    ov_organization_code :=  lv_organization_code;
    ov_whse_name         :=  lv_whse_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      ov_organization_code := NULL;
      ov_whse_name         := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      ov_organization_code := NULL;
      ov_whse_name         := NULL;
  END get_org_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : 出荷実績取得処理
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
    iv_organization_code IN  VARCHAR2,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_num_of_shipped'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_del_mark_n             CONSTANT NUMBER        := 0;                        -- 有効
--
    -- *** ローカル変数 ***
    ln_qty               NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --出荷実績取得
    --==============================================================
    SELECT NVL(SUM(xsr.quantity),0)
    INTO   ln_qty
    FROM   xxcop_shipment_results  xsr
    WHERE  xsr.shipment_date      >= TRUNC(id_plan_date_from)
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_START
--    AND    xsr.shipment_date      <= TRUNC(id_plan_date_to)
    AND    xsr.shipment_date      < TRUNC(id_plan_date_to)
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_END
    AND    xsr.item_no             = iv_item_no
    AND    xsr.latest_deliver_from IN (
      SELECT ilm.location
      FROM   ic_loct_mst  ilm
      WHERE  ilm.whse_code   = iv_organization_code
      AND    ilm.delete_mark = cn_del_mark_n
      )
    ;
    on_quantity :=  ln_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_num_of_shipped;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_forcast
   * Description      : 出荷予測取得処理
   ***********************************************************************************/
  PROCEDURE get_num_of_forcast(
    in_organization_id   IN  NUMBER,
    in_inventory_item_id IN  NUMBER,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_num_of_forcast'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_del_mark_n             CONSTANT NUMBER        := 0;   -- 有効
    cv_ship_plan_type         CONSTANT VARCHAR2(1)   := '1'; -- 基準計画分類（出荷予測）
    cn_schedule_level         CONSTANT NUMBER        := 2;   -- 基準計画レベル（レベル２）
--
    -- *** ローカル変数 ***
    ln_qty               NUMBER   := 0;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --出荷予測取得
    --==============================================================
    SELECT NVL(SUM(msdd.schedule_quantity),0)
    INTO   ln_qty
    FROM   mrp_schedule_dates       msdd
          ,mrp_schedule_designators msdh
    WHERE  msdh.schedule_designator = msdd.schedule_designator
    AND    msdh.organization_id     = in_organization_id
    AND    msdh.organization_id     = msdd.organization_id
    AND    msdh.attribute1          = cv_ship_plan_type
    AND    msdd.schedule_date      >= id_plan_date_from
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_START
--    AND    msdd.schedule_date      <= id_plan_date_to
    AND    msdd.schedule_date      <  id_plan_date_to
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_END
    AND    msdd.inventory_item_id   = in_inventory_item_id
    AND    msdd.schedule_level      = cn_schedule_level
    ;
    on_quantity :=  ln_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_num_of_forcast;
  --
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : 入庫予定取得処理
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_plan'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_xstv_status            CONSTANT VARCHAR2(1)       := '1';  -- 予定
--
    -- *** ローカル変数 ***
    ln_stock_qty              NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --入庫予定取得処理
    --==============================================================
    SELECT NVL(SUM(xstv.stock_quantity),0)     --入庫数
    INTO   ln_stock_qty
    FROM   xxcop_stc_trans_v	xstv
    WHERE  xstv.arrival_date        >= id_plan_date_from
--20090408_Ver1.1_T1_0279_SCS.Kikuchi_MOD_START
--    AND    xstv.arrival_date        <= id_plan_date_to
    AND    xstv.arrival_date        <  id_plan_date_to
--20090408_Ver1.1_T1_0279_SCS.Kikuchi_MOD_END
    AND    xstv.organization_id     =  in_organization_id
    AND    xstv.item_no             =  iv_item_no
    AND    xstv.status              =  cv_xstv_status    --1：予定
    ;
    on_quantity :=  ln_stock_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_stock_plan;
  --
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : 手持在庫取得処理
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    iv_organization_code IN  VARCHAR2,
    in_item_id           IN  NUMBER,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_onhand_qty'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_onhand_qty              NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --手持在庫取得
    --==============================================================
--20090508_Ver1.2_T1_0919_SCS.Kikuchi_MOD_START
--    SELECT NVL(SUM(ili.loct_onhand),0)
--    INTO  ln_onhand_qty
--    FROM  ic_loct_inv ili
--         ,ic_lots_mst ilm
--    WHERE ili.item_id     =  in_item_id
--    AND   ili.whse_code   =  iv_organization_code
--    AND   ili.item_id     =  ilm.item_id
--    AND   ili.lot_id      =  ilm.lot_id;
    SELECT SUM(NVL(LOCT_ONHAND,0) + NVL(STOCK_QTY,0))   -- 手持数量＋手持在庫数の集計値
    INTO   ln_onhand_qty
    FROM   xxcop_loct_inv_v xliv                        -- 計画_手持在庫ビュー
    WHERE  xliv.ORGANIZATION_CODE =  iv_organization_code
    AND    xliv.item_id           =  in_item_id
    ;
--20090508_Ver1.2_T1_0919_SCS.Kikuchi_MOD_END
    on_quantity :=  ln_onhand_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_onhand_qty;
  --
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : 配送リードタイム取得処理
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
    iv_from_org_code     IN  VARCHAR2,
    iv_to_org_code       IN  VARCHAR2,
    id_product_date      IN  DATE,
    on_delivery_lt       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lead_time'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_del_mark_n  CONSTANT NUMBER        := 0;                        -- 有効
    cv_code_class  CONSTANT VARCHAR2(1) := '4';  -- 倉庫
    ln_dlt_cnt     NUMBER := 0;
--
    -- *** ローカル変数 ***
    ln_delivery_lead_time      NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --配送リードタイム取得
    --==============================================================
    SELECT MAX(delivery_lead_time)
          ,COUNT(delivery_lead_time)
    INTO   ln_delivery_lead_time
          ,ln_dlt_cnt
    FROM   xxcmn_delivery_lt
    WHERE  code_class1 = cv_code_class      --倉庫
    AND    code_class2 = cv_code_class      --倉庫
    AND(
        (entering_despatching_code1 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_from_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
    AND  entering_despatching_code2 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_to_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
        )
    OR  (entering_despatching_code1 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_to_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
    AND  entering_despatching_code2 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_from_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
        )
      )
    AND start_date_active <= id_product_date
    AND end_date_active   >= id_product_date
    ;
    IF ln_dlt_cnt = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;
    on_delivery_lt := ln_delivery_lead_time;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
  END get_deliv_lead_time;
  --
  /**********************************************************************************
   * Procedure Name   : get_unit_delivery
   * Description      : 配送単位取得処理
   ***********************************************************************************/
  PROCEDURE get_unit_delivery(
    in_item_id              IN  NUMBER,              --   OPM品目ID
    id_ship_date            IN  DATE,                --   出荷日
    on_palette_max_cs_qty   OUT  NUMBER,       --   配数
    on_palette_max_step_qty OUT  NUMBER,       --   段数
    ov_errbuf               OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_unit_delivery'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_active                 CONSTANT VARCHAR2(1)     := 'Y';        -- 有効フラグ
--
    -- *** ローカル変数 ***
    ln_palette_max_cs_qty   xxcmn_item_mst_b.palette_max_cs_qty%TYPE;
    ln_palette_max_step_qty xxcmn_item_mst_b.palette_max_step_qty%TYPE;

--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --配送単位取得処理
    --==============================================================
    SELECT palette_max_cs_qty
          ,palette_max_step_qty
    INTO   ln_palette_max_cs_qty
          ,ln_palette_max_step_qty
    FROM   xxcmn_item_mst_b
    WHERE  item_id = in_item_id
    AND    start_date_active <= id_ship_date
    AND    NVL(end_date_active,id_ship_date) >=  id_ship_date
    AND    active_flag = cv_active
    ;
--20090408_Ver1.1_T1_0272_SCS.Kikuchi_MOD_START
--    on_palette_max_cs_qty    := ln_palette_max_cs_qty;
--    on_palette_max_step_qty  := ln_palette_max_step_qty;
    on_palette_max_cs_qty    := NVL(ln_palette_max_cs_qty,1);
    on_palette_max_step_qty  := NVL(ln_palette_max_step_qty,1);
--20090408_Ver1.1_T1_0272_SCS.Kikuchi_MOD_END
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_palette_max_cs_qty   := NULL;
      on_palette_max_step_qty := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_palette_max_cs_qty   := NULL;
      on_palette_max_step_qty := NULL;
  END get_unit_delivery;
--
  /**********************************************************************************
   * Function Name   : get_working_days
   * Description      : 稼働日数取得処理
   ***********************************************************************************/
  PROCEDURE get_working_days(
    in_organization_id   IN NUMBER,
    id_from_date     IN     DATE,           --   基点日付
    id_to_date       IN     DATE,           --   終点日付
    on_working_days  OUT    NUMBER,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_working_days'; -- プログラム名
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
--20090508_Ver1.2_T1_0918_SCS.Kikuchi_ADD_START
    cn_active     NUMBER := 0;
--20090508_Ver1.2_T1_0918_SCS.Kikuchi_ADD_END
--
    -- *** ローカル変数 ***
    ld_work_date  DATE := NULL;
    ld_from_date  DATE := NULL;
    ln_cnt_days   NUMBER := 0;
    lv_calendar_code mtl_parameters.calendar_code%TYPE := NULL;
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ===============================
    -- パラメータチェック
    -- ===============================
    IF id_from_date IS NULL OR id_to_date IS NULL THEN
      RAISE date_null_expt;
    END IF;
    IF id_from_date > id_to_date THEN
      RAISE date_from_to_expt;
    END IF;

--20090508_Ver1.2_T1_0918_SCS.Kikuchi_ADD_START
    -- ===============================
    -- カレンダーコード取得
    -- ===============================
    BEGIN
      SELECT attribute10
      INTO   lv_calendar_code
      FROM   mtl_item_locations   -- OPM保管場所マスタ
      WHERE  organization_id  =  in_organization_id
      AND    attribute10      IS NOT NULL
      GROUP
      BY     attribute10
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND
        OR TOO_MANY_ROWS THEN
          lv_calendar_code := NULL;
    END;

    -- 組織からカレンダーコードが取得出来ない場合、
    -- プロファイルのドリンク基準カレンダを設定する。
    IF  lv_calendar_code IS NULL THEN
      BEGIN
        lv_calendar_code := FND_PROFILE.VALUE( cv_cmn_drink_cal_cd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_calendar_code := NULL;
      END;
--
      -- プロファイルが取得出来ない場合、エラーとして戻す。
      IF ( lv_calendar_code IS NULL ) THEN
        ov_errbuf        := NULL;
        ov_errmsg        := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_application
                              ,iv_name         => cv_message_00002
                              ,iv_token_name1  => cv_message_00002_token_1
                              ,iv_token_value1 => cv_cmn_drink_cal_cd_name
                              );
        on_working_days  := NULL;
        ov_retcode       := cv_status_error;
        RETURN;
      END IF;
    END IF;

    -- ===============================
    -- 稼働日数取得
    -- ===============================
    SELECT  COUNT(*)
    INTO    ln_cnt_days
    FROM    mr_shcl_hdr msh    -- 製造カレンダヘッダ
    ,       mr_shcl_dtl msd    -- 製造カレンダ明細
    WHERE   msh.calendar_no   =  lv_calendar_code
    AND     msh.calendar_id   =  msd.calendar_id
    AND     msd.calendar_date BETWEEN id_from_date
                                  AND id_to_date - 1
    AND     msd.delete_mark   =  cn_active
    ;

    -- 戻り値の設定
    ov_errbuf        := NULL;
    ov_errmsg        := NULL;
    on_working_days  := ln_cnt_days;
--20090508_Ver1.2_T1_0918_SCS.Kikuchi_ADD_END
--20090508_Ver1.2_T1_0918_SCS.Kikuchi_DEL_START
--    -- ===============================
--    -- 稼働日数取得
--    -- ===============================
--    -- 変数初期化
--    ld_from_date := id_from_date;
--
--    --
--    SELECT calendar_code
--    INTO lv_calendar_code
--    FROM mtl_parameters
--    WHERE organization_id = in_organization_id;
--    <<loop_bomdays>>
--    LOOP
--      IF id_from_date = id_to_date THEN
--        on_working_days := 0;
--        EXIT;
--      END IF;
--      --稼働日の場合日付が戻り、非稼働日の場合NULLが戻る
--      ld_work_date := xxccp_common_pkg2.get_working_day(
--                       id_date            =>  ld_from_date
--                      ,in_working_day     =>  0
--                      ,iv_calendar_code   =>  lv_calendar_code
--                      );
--      --
--      IF ld_work_date IS NOT NULL THEN
--        --稼働日カウント
--        ln_cnt_days  := ln_cnt_days  + 1;
--      END IF;
--      --
--      ld_from_date  := ld_from_date + 1;
--      --
--      IF ld_from_date >= id_to_date THEN
--        on_working_days := ln_cnt_days;
--        EXIT;
--      END IF;
--      --
--    END LOOP;
--20090508_Ver1.2_T1_0918_SCS.Kikuchi_DEL_END
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_working_days  := NULL;
--
  END get_working_days;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_exists
   * Description      : 在庫品目チェック
   ***********************************************************************************/
  PROCEDURE chk_item_exists(
    in_inventory_item_id IN  NUMBER,
    in_organization_id   IN  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_exists'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --在庫品目チェック
    --==============================================================
    SELECT msib.inventory_item_id
    INTO   ln_inventory_item_id
    FROM   mtl_system_items_b msib
    WHERE  msib.inventory_item_id = in_inventory_item_id
    AND    msib.organization_id   = in_organization_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
  END chk_item_exists;
  --
  /**********************************************************************************
   * Procedure Name   : get_scheduled_trans
   * Description      : 入出庫予定取得処理
   ***********************************************************************************/
  PROCEDURE get_scheduled_trans(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_date_from         IN  DATE,
    id_date_to           IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_scheduled_trans'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_xstv_status            CONSTANT VARCHAR2(1)       := '1';  -- 予定
--
    -- *** ローカル変数 ***
    ln_stock_qty              NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --入庫予定取得処理
    --==============================================================
    SELECT NVL(SUM(xstv.stock_quantity),0) - NVL(SUM(xstv.leaving_quantity), 0)
    INTO   ln_stock_qty
    FROM   xxcop_stc_trans_v xstv
    WHERE  xstv.organization_id   =  in_organization_id
    AND    xstv.item_no           =  iv_item_no
    AND    xstv.status            =  cv_xstv_status
    AND    xstv.arrival_date BETWEEN id_date_from AND id_date_to
    ;
    on_quantity :=  ln_stock_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_scheduled_trans;
  --
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : 割当セットAPI起動
   ***********************************************************************************/
--20090723_Ver1.3_0000670_SCS.Fukada_DEL_START
--  PROCEDURE upd_assignment(
--    iv_ship_to_locat_code   IN  VARCHAR2,     -- 入庫先
--    iv_item_code            IN  VARCHAR2,     -- 品目
--    in_quantity             IN  NUMBER,       -- 移動数
--    iv_design_prod_date     IN  VARCHAR2,     -- 指定製造日
--    iv_sche_arriv_date      IN  VARCHAR2,     -- 着日
--    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name               CONSTANT VARCHAR2(100) := 'upd_assignment';   -- プロシージャ名
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ユーザー定義例外 ***
--    api_expt                  EXCEPTION;
----
--    -- *** ローカル定数 ***
--    -- API定数
--    cv_operation_update       CONSTANT VARCHAR2(6) := 'UPDATE';   -- 更新
--    cv_api_version            CONSTANT VARCHAR2(4) := '1.0';      -- バージョン
--    cv_msg_encoded            CONSTANT VARCHAR2(1) := 'F';        -- エラーメッセージエンコード
--    -- その他
--    cv_date_format            CONSTANT VARCHAR2(8) := 'YYYYMMDD';   -- システム日付
--    cv_slash                  CONSTANT VARCHAR2(1) := '/';          -- 日付の区切り記号
--    cv_attribute_category     CONSTANT VARCHAR2(1) := '2';          -- 割当セット区分(2:特別横持)
--    cv_assignment_type        CONSTANT VARCHAR2(1) := '6';          -- 割当先タイプ(6:品目・組織)
--    cv_sourcing_rule_type     CONSTANT VARCHAR2(1) := '1';          -- 物流構成表/ソースルールタイプ(1:ソースルール)
----
--    -- *** ローカル変数 ***
--    lv_message_code           VARCHAR2(100);
--    lv_param                  VARCHAR2(256);    -- パラメータ
--    lv_return_status          VARCHAR2(1);
--    ln_msg_count              NUMBER;
--    lv_msg_data               VARCHAR2(3000);
--    ln_msg_index_out          NUMBER;
--    ln_quantity               NUMBER;           -- 移動数
----
--    -- *** ローカル・カーソル ***
--    CURSOR l_assignments_set_cur IS
--      -- 割当セット明細の更新対象データ取得
--      SELECT mas.assignment_set_id      mas_assignment_set_id     -- 割当セットヘッダ.割当セットヘッダID
--            ,mas.assignment_set_name    assignment_set_name       -- 割当セットヘッダ.割当セット名
--            ,mas.creation_date          mas_creation_date         -- 割当セットヘッダ.作成日
--            ,mas.created_by             mas_created_by            -- 割当セットヘッダ.作成者
--            ,mas.description            description               -- 割当セットヘッダ.割当セット摘要
--            ,mas.attribute_category     mas_attribute_category    -- 割当セットヘッダ.Attribute_Category
--            ,mas.attribute1             mas_attribute1            -- 割当セットヘッダ.割当セット区分(DFF1)
--            ,mas.attribute2             mas_attribute2            -- 割当セットヘッダ.DFF2
--            ,mas.attribute3             mas_attribute3            -- 割当セットヘッダ.DFF3
--            ,mas.attribute4             mas_attribute4            -- 割当セットヘッダ.DFF4
--            ,mas.attribute5             mas_attribute5            -- 割当セットヘッダ.DFF5
--            ,mas.attribute6             mas_attribute6            -- 割当セットヘッダ.DFF6
--            ,mas.attribute7             mas_attribute7            -- 割当セットヘッダ.DFF7
--            ,mas.attribute8             mas_attribute8            -- 割当セットヘッダ.DFF8
--            ,mas.attribute9             mas_attribute9            -- 割当セットヘッダ.DFF9
--            ,mas.attribute10            mas_attribute10           -- 割当セットヘッダ.DFF10
--            ,mas.attribute11            mas_attribute11           -- 割当セットヘッダ.DFF11
--            ,mas.attribute12            mas_attribute12           -- 割当セットヘッダ.DFF12
--            ,mas.attribute13            mas_attribute13           -- 割当セットヘッダ.DFF13
--            ,mas.attribute14            mas_attribute14           -- 割当セットヘッダ.DFF14
--            ,mas.attribute15            mas_attribute15           -- 割当セットヘッダ.DFF15
--            ,mss.assignment_id          assignment_id             -- 割当セット明細.割当セット明細ID
--            ,mss.assignment_type        assignment_type           -- 割当セット明細.割当先タイプ
--            ,mss.sourcing_rule_id       sourcing_rule_id          -- 割当セット明細.ソースルールID
--            ,mss.sourcing_rule_type     sourcing_rule_type        -- 割当セット明細.物流構成表/ソースルールタイプ
--            ,mss.assignment_set_id      mss_assignment_set_id     -- 割当セット明細.割当セットヘッダID
--            ,mss.creation_date          mss_creation_date         -- 割当セット明細.作成日
--            ,mss.created_by             mss_created_by            -- 割当セット明細.作成者
--            ,mss.organization_id        organization_id           -- 割当セット明細.組織ID
--            ,mss.customer_id            customer_id               -- 割当セット明細.Customer_Id
--            ,mss.ship_to_site_id        ship_to_site_id           -- 割当セット明細.Ship_To_Site_Id
--            ,mss.category_id            category_id               -- 割当セット明細.Category_Id
--            ,mss.category_set_id        category_set_id           -- 割当セット明細.Category_Set_Id
--            ,mss.inventory_item_id      inventory_item_id         -- 割当セット明細.品目ID
--            ,mss.secondary_inventory    secondary_inventory       -- 割当セット明細.Secondary_Inventory
--            ,mss.attribute_category     mss_attribute_category    -- 割当セット明細.割当セット区分
--            ,mss.attribute1             mss_attribute1            -- 割当セット明細.開始製造年月日(DFF1)
--            ,mss.attribute2             mss_attribute2            -- 割当セット明細.有効開始日(DFF2)
--            ,mss.attribute3             mss_attribute3            -- 割当セット明細.有効終了日(DFF3)
--            ,mss.attribute4             mss_attribute4            -- 割当セット明細.設定数量(DFF4)
--            ,mss.attribute5             mss_attribute5            -- 割当セット明細.移動数(DFF5)
--            ,mss.attribute6             mss_attribute6            -- 割当セット明細.DFF6
--            ,mss.attribute7             mss_attribute7            -- 割当セット明細.DFF7
--            ,mss.attribute8             mss_attribute8            -- 割当セット明細.DFF8
--            ,mss.attribute9             mss_attribute9            -- 割当セット明細.DFF9
--            ,mss.attribute10            mss_attribute10           -- 割当セット明細.DFF10
--            ,mss.attribute11            mss_attribute11           -- 割当セット明細.DFF11
--            ,mss.attribute12            mss_attribute12           -- 割当セット明細.DFF12
--            ,mss.attribute13            mss_attribute13           -- 割当セット明細.DFF13
--            ,mss.attribute14            mss_attribute14           -- 割当セット明細.DFF14
--            ,mss.attribute15            mss_attribute15           -- 割当セット明細.DFF15
--      FROM   mrp_assignment_sets mas          -- 割当セットヘッダ
--            ,mrp_sr_assignments mss           -- 割当セット明細
--            ,mtl_item_locations mil           -- OPM保管場所マスタ
--            ,xxcop_item_categories1_v xicv    -- 計画_品目カテゴリビュー1
--      WHERE  mas.attribute1         = cv_attribute_category   -- 割当セット区分(2:特別横持)
--      AND    mas.assignment_set_id  = mss.assignment_set_id
--      AND    mss.assignment_type    = cv_assignment_type      -- 割当先タイプ(6:品目・組織)
--      AND    mss.sourcing_rule_type = cv_sourcing_rule_type   -- 物流構成表/ソースルールタイプ(1:ソースルール)
--      AND    mil.segment1           = iv_ship_to_locat_code   -- 入庫先
--      AND    mss.organization_id    = mil.organization_id
--      AND    xicv.item_no           = iv_item_code            -- 品目
--      AND    mss.inventory_item_id  = xicv.inventory_item_id
--      AND    NVL( REPLACE( mss.attribute1, cv_slash ), iv_design_prod_date ) <= iv_design_prod_date
--      AND    NVL( REPLACE( mss.attribute2, cv_slash ), iv_sche_arriv_date  ) <= iv_sche_arriv_date
--      AND    NVL( REPLACE( mss.attribute3, cv_slash ), iv_sche_arriv_date  ) >= iv_sche_arriv_date
--      ;
----
--    -- *** ローカル・レコード ***
--    l_in_mas_rec              MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;        -- 割当セットヘッダー
--    l_mas_val_rec             MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
--    l_out_mas_rec             MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;
--    l_out_mas_val_rec         MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
----
--    -- *** ローカル・PL/SQL表 ***
--    l_in_msa_tab              MRP_Src_Assignment_PUB.Assignment_Tbl_Type;            -- 割当セット明細
--    l_msa_val_tab             MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
--    l_out_msa_tab             MRP_Src_Assignment_PUB.Assignment_Tbl_Type;
--    l_out_msa_val_tab         MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
----
--  BEGIN
--    --==============================================================
--    --ステータス初期化
--    --==============================================================
--    ov_retcode := cv_status_normal;
----
--    -- ===============================================
--    -- 割当セット明細の更新対象データを取得する
--    -- ===============================================
--    OPEN l_assignments_set_cur;
--    FETCH l_assignments_set_cur INTO
--      l_in_mas_rec.assignment_set_id          -- 割当セットヘッダ.割当セットヘッダID
--     ,l_in_mas_rec.assignment_set_name        -- 割当セットヘッダ.割当セット名
--     ,l_in_mas_rec.creation_date              -- 割当セットヘッダ.作成日
--     ,l_in_mas_rec.created_by                 -- 割当セットヘッダ.作成者
--     ,l_in_mas_rec.description                -- 割当セットヘッダ.割当セット摘要
--     ,l_in_mas_rec.attribute_category         -- 割当セットヘッダ.Attribute_Category
--     ,l_in_mas_rec.attribute1                 -- 割当セットヘッダ.割当セット区分(DFF1)
--     ,l_in_mas_rec.attribute2                 -- 割当セットヘッダ.DFF2
--     ,l_in_mas_rec.attribute3                 -- 割当セットヘッダ.DFF3
--     ,l_in_mas_rec.attribute4                 -- 割当セットヘッダ.DFF4
--     ,l_in_mas_rec.attribute5                 -- 割当セットヘッダ.DFF5
--     ,l_in_mas_rec.attribute6                 -- 割当セットヘッダ.DFF6
--     ,l_in_mas_rec.attribute7                 -- 割当セットヘッダ.DFF7
--     ,l_in_mas_rec.attribute8                 -- 割当セットヘッダ.DFF8
--     ,l_in_mas_rec.attribute9                 -- 割当セットヘッダ.DFF9
--     ,l_in_mas_rec.attribute10                -- 割当セットヘッダ.DFF10
--     ,l_in_mas_rec.attribute11                -- 割当セットヘッダ.DFF11
--     ,l_in_mas_rec.attribute12                -- 割当セットヘッダ.DFF12
--     ,l_in_mas_rec.attribute13                -- 割当セットヘッダ.DFF13
--     ,l_in_mas_rec.attribute14                -- 割当セットヘッダ.DFF14
--     ,l_in_mas_rec.attribute15                -- 割当セットヘッダ.DFF15
--     ,l_in_msa_tab(1).assignment_id           -- 割当セット明細.割当セット明細ID
--     ,l_in_msa_tab(1).assignment_type         -- 割当セット明細.割当先タイプ
--     ,l_in_msa_tab(1).sourcing_rule_id        -- 割当セット明細.ソースルールID
--     ,l_in_msa_tab(1).sourcing_rule_type      -- 割当セット明細.物流構成表/ソースルールタイプ
--     ,l_in_msa_tab(1).assignment_set_id       -- 割当セット明細.割当セットヘッダID
--     ,l_in_msa_tab(1).creation_date           -- 割当セット明細.作成日
--     ,l_in_msa_tab(1).created_by              -- 割当セット明細.作成者
--     ,l_in_msa_tab(1).organization_id         -- 割当セット明細.組織ID
--     ,l_in_msa_tab(1).customer_id             -- 割当セット明細.Customer_Id
--     ,l_in_msa_tab(1).ship_to_site_id         -- 割当セット明細.Ship_To_Site_Id
--     ,l_in_msa_tab(1).category_id             -- 割当セット明細.Category_Id
--     ,l_in_msa_tab(1).category_set_id         -- 割当セット明細.Category_Set_Id
--     ,l_in_msa_tab(1).inventory_item_id       -- 割当セット明細.品目ID
--     ,l_in_msa_tab(1).secondary_inventory     -- 割当セット明細.Secondary_Inventory
--     ,l_in_msa_tab(1).attribute_category      -- 割当セット明細.割当セット区分
--     ,l_in_msa_tab(1).attribute1              -- 割当セット明細.開始製造年月日(DFF1)
--     ,l_in_msa_tab(1).attribute2              -- 割当セット明細.有効開始日(DFF2)
--     ,l_in_msa_tab(1).attribute3              -- 割当セット明細.有効終了日(DFF3)
--     ,l_in_msa_tab(1).attribute4              -- 割当セット明細.設定数量(DFF4)
--     ,l_in_msa_tab(1).attribute5              -- 割当セット明細.移動数(DFF5)
--     ,l_in_msa_tab(1).attribute6              -- 割当セット明細.DFF6
--     ,l_in_msa_tab(1).attribute7              -- 割当セット明細.DFF7
--     ,l_in_msa_tab(1).attribute8              -- 割当セット明細.DFF8
--     ,l_in_msa_tab(1).attribute9              -- 割当セット明細.DFF9
--     ,l_in_msa_tab(1).attribute10             -- 割当セット明細.DFF10
--     ,l_in_msa_tab(1).attribute11             -- 割当セット明細.DFF11
--     ,l_in_msa_tab(1).attribute12             -- 割当セット明細.DFF12
--     ,l_in_msa_tab(1).attribute13             -- 割当セット明細.DFF13
--     ,l_in_msa_tab(1).attribute14             -- 割当セット明細.DFF14
--     ,l_in_msa_tab(1).attribute15             -- 割当セット明細.DFF15
--    ;
--
--    -- 対象データが存在する場合
--    IF ( l_assignments_set_cur%FOUND ) THEN
--      -- ===============================================
--      -- 割当セット・API標準レコードタイプの準備
--      -- ===============================================
--      l_in_mas_rec.operation             := cv_operation_update;      -- 割当セットヘッダ.処理区分(UPDATE)
--      l_in_mas_rec.last_update_date      := cd_last_update_date;      -- 割当セットヘッダ.最終更新者
--      l_in_mas_rec.last_updated_by       := cn_last_updated_by;       -- 割当セットヘッダ.最終更新日
--      l_in_mas_rec.last_update_login     := cn_last_update_login;     -- 割当セットヘッダ.最終更新ログイン
----
--      -- ===============================================
--      -- 移動数の計算
--      -- ===============================================
--      ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) + in_quantity;
----
--      -- ===============================================
--      -- 割当セット明細PLSQL表の準備
--      -- ===============================================
--      l_in_msa_tab(1).attribute5         := TO_CHAR( ln_quantity );   -- 割当セット明細.移動数(DFF5)
--      l_in_msa_tab(1).operation          := cv_operation_update;      -- 割当セット明細.処理区分(UPDATE)
--      l_in_msa_tab(1).last_update_date   := cd_last_update_date;      -- 割当セット明細.最終更新者
--      l_in_msa_tab(1).last_updated_by    := cn_last_updated_by;       -- 割当セット明細.最終更新日
--      l_in_msa_tab(1).last_update_login  := cn_last_update_login;     -- 割当セット明細.最終更新ログイン
----
--      -- ===============================================
--      -- 割当セットヘッダ/明細の更新（API起動）
--      -- ===============================================
--      mrp_src_assignment_pub.process_assignment(
--         p_api_version_number          => cv_api_version
--        ,p_init_msg_list               => FND_API.G_TRUE
--        ,p_return_values               => FND_API.G_TRUE
--        ,p_commit                      => FND_API.G_FALSE
--        ,x_return_status               => lv_return_status
--        ,x_msg_count                   => ln_msg_count
--        ,x_msg_data                    => lv_msg_data
--        ,p_Assignment_Set_rec          => l_in_mas_rec
--        ,p_Assignment_Set_val_rec      => l_mas_val_rec
--        ,p_Assignment_tbl              => l_in_msa_tab
--        ,p_Assignment_val_tbl          => l_msa_val_tab
--        ,x_Assignment_Set_rec          => l_out_mas_rec
--        ,x_Assignment_Set_val_rec      => l_out_mas_val_rec
--        ,x_Assignment_tbl              => l_out_msa_tab
--        ,x_Assignment_val_tbl          => l_out_msa_val_tab
--      );
--
--      -- エラーが発生した場合
--      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
--        ov_errmsg := lv_msg_data;
--        RAISE api_expt;
--      END IF;
----
--      -- 移動数が０未満となった場合は警告終了する
--      IF ( l_in_msa_tab(1).attribute5 < 0 ) THEN
--        ov_retcode := cv_status_warn;
--      END IF;
--    END IF;
----
--    CLOSE l_assignments_set_cur;
----
--  EXCEPTION
--    -- API起動でエラー
--    WHEN api_expt THEN
--      IF ( l_assignments_set_cur%ISOPEN ) THEN
--        CLOSE l_assignments_set_cur;
--      END IF;
--      ov_retcode       := cv_status_error;
--    -- その他例外エラー
--    WHEN OTHERS THEN
--      IF ( l_assignments_set_cur%ISOPEN ) THEN
--        CLOSE l_assignments_set_cur;
--      END IF;
--      ov_retcode       := cv_status_error;
--      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--  END upd_assignment;
--  --
--20090723_Ver1.3_0000670_SCS.Fukada_DEL_END
--20090723_Ver1.3_0000670_SCS.Fukada_ADD_START
  PROCEDURE upd_assignment(
    iv_mov_num              IN  VARCHAR2,     -- 移動ヘッダID
    iv_process_type         IN  VARCHAR2,     -- 処理区分(0：加算、1：減算)
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'upd_assignment';   -- プロシージャ名
    -- メッセージ名
    cv_message_00003          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00003';

    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ユーザー定義例外 ***
    api_expt                  EXCEPTION;
    internal_process_expt     EXCEPTION;     -- 内部PROCEDURE/FUNCTIONエラーハンドリング用
--
    -- *** ローカル定数 ***
    cv_doc_type               CONSTANT VARCHAR2(2) := '20';    -- 文書タイプ(20：移動)
    cv_rec_type               CONSTANT VARCHAR2(2) := '10';    -- レコードタイプ(10：指示)
    cv_attribute_category     CONSTANT VARCHAR2(1) := '2';     -- 割当セット区分(2:特別横持)
    cv_assignment_type        CONSTANT VARCHAR2(1) := '6';     -- 割当先タイプ(6:品目・組織)
    cv_sourcing_rule_type     CONSTANT VARCHAR2(1) := '1';     -- 物流構成表/ソースルールタイプ(1:ソースルール)
    cv_lookup_type            CONSTANT VARCHAR2(22) := 'XXCOP1_ASSIGNMENT_NAME';  -- クイックコードタイプ名
    --
    cv_api_version            CONSTANT VARCHAR2(4) := '1.0';      -- バージョン
    cv_operation_update       CONSTANT VARCHAR2(6) := 'UPDATE';   -- 更新
    --
    cv_process_type_plus      CONSTANT VARCHAR2(1) := '0';     -- 処理区分 0：加算
    cv_process_type_minus     CONSTANT VARCHAR2(1) := '1';     -- 処理区分 1：減算
--
    -- *** ローカル変数 ***
    lv_errbuf                          VARCHAR2(5000);         -- エラー・メッセージ
    lv_retcode                         VARCHAR2(1);            -- リターン・コード
    lv_errmsg                          VARCHAR2(5000);         -- ユーザー・エラー・メッセージ
    --
    ln_quantity                        NUMBER;                 -- 移動数量
    ln_quantity_before                 NUMBER;                 -- 変更前移動数量
    --
    ln_case_qty                        NUMBER;                 -- ケース換算数量
    --
    ln_loop_cnt                        NUMBER := 0;            -- ループカウンタ
    lv_rowid                           ROWID;                  -- ロック取得用
    --
    lv_message_code                    VARCHAR2(100);
    lv_param                           VARCHAR2(256);                   -- パラメータ
    lv_return_status                   VARCHAR2(1);
    ln_msg_count                       NUMBER;
    lv_msg_data                        VARCHAR2(3000);
    ln_msg_index_out                   NUMBER;
--
    -- *** ローカル・カーソル ***
    -- 移動関連情報の取得
    CURSOR l_move_info_cur
    IS
      SELECT xmrih.shipped_locat_code    ship_from_code      -- 出荷元倉庫(出庫元保管場所)
            ,xmrih.ship_to_locat_code    ship_to_code        -- 入庫先倉庫(入庫先保管場所)
            ,TO_CHAR(xmrih.schedule_arrival_date,'YYYY/MM/DD') arrival_date        -- 着日(入庫予定日)
            ,xmril.item_code             item_code           -- 品目
            ,xmld.actual_quantity        quantity            -- 移動数量
            ,ilm.attribute1              prod_start_date     -- 製造年月日
            --
            ,xmrih.mov_hdr_id            mov_hdr_id          -- 移動ヘッダID
            ,xmrih.mov_num               mov_num             -- 移動番号
            ,xmril.mov_line_id           mov_line_id         -- 移動明細ID
            ,xmril.line_number           line_number         -- 明細番号
            ,xmril.delete_flg            delete_flg          -- 明細削除フラグ
            ,xmld.lot_id                 lot_id              -- ロットID
            ,xmld.lot_no                 lot_no              -- ロットNo
      FROM   xxinv_mov_req_instr_headers xmrih               -- 移動依頼/指示ヘッダ
            ,xxinv_mov_req_instr_lines   xmril               -- 移動依頼/指示明細
            ,xxinv_mov_lot_details       xmld                -- 移動ロット詳細
            ,ic_lots_mst                 ilm                 -- OPMロットマスタ
      WHERE
      -- テーブル結合条件
             xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmril.mov_line_id       = xmld.mov_line_id
      AND    xmld.document_type_code = cv_doc_type
      AND    xmld.record_type_code   = cv_rec_type
      AND    xmld.item_id            = ilm.item_id
      AND    xmld.lot_id             = ilm.lot_id
      -- 抽出条件
      AND    xmrih.mov_num           = iv_mov_num
      ;
    --
    -- 特別横持制御マスタ関連情報の取得
    CURSOR l_assignments_info_cur(
      prm_ship_from_code   VARCHAR2  -- 出荷元倉庫(出庫元保管場所)
     ,prm_ship_to_code     VARCHAR2  -- 入庫先倉庫(入庫先保管場所)
     ,prm_arrival_date     VARCHAR2  -- 着日(入庫予定日)
     ,prm_item_code        VARCHAR2  -- 品目
     ,prm_quantity         NUMBER    -- 移動数量
     ,prm_prod_start_date  VARCHAR2  -- 製造年月日
    ) IS
      SELECT mas.assignment_set_id    mas_assignment_set_id      -- 割当セットヘッダ.割当セットヘッダID
            ,mas.assignment_set_name  mas_assignment_set_name    -- 割当セットヘッダ.割当セット名
            ,mas.creation_date        mas_creation_date          -- 割当セットヘッダ.作成日
            ,mas.created_by           mas_created_by             -- 割当セットヘッダ.作成者
            ,mas.description          mas_desctiption            -- 割当セットヘッダ.割当セット摘要
            ,mas.attribute_category   mas_attribute_category     -- 割当セットヘッダ.Attribute_Category
            ,mas.attribute1           mas_attribute1             -- 割当セットヘッダ.割当セット区分(DFF1)
            ,mas.attribute2           mas_attribute2             -- 割当セットヘッダ.DFF2
            ,mas.attribute3           mas_attribute3             -- 割当セットヘッダ.DFF3
            ,mas.attribute4           mas_attribute4             -- 割当セットヘッダ.DFF4
            ,mas.attribute5           mas_attribute5             -- 割当セットヘッダ.DFF5
            ,mas.attribute6           mas_attribute6             -- 割当セットヘッダ.DFF6
            ,mas.attribute7           mas_attribute7             -- 割当セットヘッダ.DFF7
            ,mas.attribute8           mas_attribute8             -- 割当セットヘッダ.DFF8
            ,mas.attribute9           mas_attribute9             -- 割当セットヘッダ.DFF9
            ,mas.attribute10          mas_attribute10            -- 割当セットヘッダ.DFF10
            ,mas.attribute11          mas_attribute11            -- 割当セットヘッダ.DFF11
            ,mas.attribute12          mas_attribute12            -- 割当セットヘッダ.DFF12
            ,mas.attribute13          mas_attribute13            -- 割当セットヘッダ.DFF13
            ,mas.attribute14          mas_attribute14            -- 割当セットヘッダ.DFF14
            ,mas.attribute15          mas_attribute15            -- 割当セットヘッダ.DFF15
             --
            ,msa.assignment_id        msa_assignment_id          -- 割当セット明細.割当セット明細ID
            ,msa.assignment_type      msa_assignment_type        -- 割当セット明細.割当先タイプ
            ,msa.sourcing_rule_id     msa_sourcing_rule_id       -- 割当セット明細.ソースルールID
            ,msa.sourcing_rule_type   msa_sourcing_rule_type     -- 割当セット明細.物流構成表/ソースルールタイプ
            ,msa.assignment_set_id    msa_assignment_set_id      -- 割当セット明細.割当セットヘッダID
            ,msa.creation_date        msa_creation_date          -- 割当セット明細.作成日
            ,msa.created_by           msa_created_by             -- 割当セット明細.作成者
            ,msa.organization_id      msa_organization_id        -- 割当セット明細.組織ID
            ,msa.customer_id          msa_cutomer_id             -- 割当セット明細.Customer_Id
            ,msa.ship_to_site_id      msa_ship_to_site_id        -- 割当セット明細.Ship_To_Site_Id
            ,msa.category_id          msa_category_id            -- 割当セット明細.Category_Id
            ,msa.category_set_id      msa_category_set_id        -- 割当セット明細.Category_Set_Id
            ,msa.inventory_item_id    msa_inventory_item_id      -- 割当セット明細.品目ID
            ,msa.secondary_inventory  msa_secondary_inventory    -- 割当セット明細.Secondary_Inventory
            ,msa.attribute_category   msa_attribute_category     -- 割当セット明細.割当セット区分
            ,msa.attribute1           msa_attribute1             -- 割当セット明細.開始製造年月日(DFF1)
            ,msa.attribute2           msa_attribute2             -- 割当セット明細.有効開始日(DFF2)
            ,msa.attribute3           msa_attribute3             -- 割当セット明細.有効終了日(DFF3)
            ,msa.attribute4           msa_attribute4             -- 割当セット明細.設定数量(DFF4)
            ,msa.attribute5           msa_attribute5             -- 割当セット明細.移動数(DFF5)
            ,msa.attribute6           msa_attribute6             -- 割当セット明細.DFF6
            ,msa.attribute7           msa_attribute7             -- 割当セット明細.DFF7
            ,msa.attribute8           msa_attribute8             -- 割当セット明細.DFF8
            ,msa.attribute9           msa_attribute9             -- 割当セット明細.DFF9
            ,msa.attribute10          msa_attribute10            -- 割当セット明細.DFF10
            ,msa.attribute11          msa_attribute11            -- 割当セット明細.DFF11
            ,msa.attribute12          msa_attribute12            -- 割当セット明細.DFF12
            ,msa.attribute13          msa_attribute13            -- 割当セット明細.DFF13
            ,msa.attribute14          msa_attribute14            -- 割当セット明細.DFF14
            ,msa.attribute15          msa_attribute15            -- 割当セット明細.DFF15
      FROM   mrp_assignment_sets      mas                        -- 割当セットヘッダ
            ,mrp_sr_assignments       msa                        -- 割当セット明細
            ,mrp_sourcing_rules       msr                        -- ソースルール
            ,mrp_sr_receipt_org       msro                       --
            ,mtl_item_locations       mil_to                     -- OPM保管場所
            ,mrp_sr_source_org        msso                       --
            ,mtl_item_locations       mil_from                   -- OPM保管場所
            ,xxcop_item_categories1_v xicv                       -- 計画領域：品目マスタ
            ,fnd_lookup_values        flv                        -- クイックコード
      WHERE
      -- テーブル結合条件
            mas.assignment_set_id                = msa.assignment_set_id
      AND   msa.sourcing_rule_id                  = msr.sourcing_rule_id
      AND   msr.sourcing_rule_id                  = msro.sourcing_rule_id
      AND   SYSDATE                               BETWEEN NVL(msro.effective_date,SYSDATE)
                                                  AND     NVL(msro.disable_date  ,SYSDATE)
      AND   msro.receipt_organization_id          = mil_to.organization_id
      AND   msro.sr_receipt_id                    = msso.sr_receipt_id
      AND   msso.source_organization_id           = mil_from.organization_id
      AND   msa.inventory_item_id                 = xicv.inventory_item_id
      AND   flv.lookup_type                       = cv_lookup_type
      AND   flv.language                          = USERENV('LANG')
      AND   flv.enabled_flag                      = 'Y'
      AND   flv.lookup_code                       = mas.assignment_set_name
      -- データ抽出条件(特別横持のみ抽出)
      AND   msa.attribute_category                = cv_attribute_category
      AND   msa.assignment_type                   = cv_assignment_type
      AND   msa.sourcing_rule_type                = cv_sourcing_rule_type
      -- 抽出条件
      AND   mil_from.segment1                     = prm_ship_from_code
      AND   mil_to.segment1                       = prm_ship_to_code
      AND   xicv.item_no                          = prm_item_code
            -- 抽出条件：特別横持取得パターン１
      AND   (   (   prm_prod_start_date >= msa.attribute1
                AND prm_arrival_date    <= msa.attribute3
                AND (  (   iv_process_type            = cv_process_type_plus
                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- 抽出条件：特別横持取得パターン２
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date     BETWEEN msa.attribute2
                                         AND     msa.attribute3
                AND (  (   iv_process_type            = cv_process_type_plus
                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- 抽出条件：特別横持取得パターン３
            OR  (   prm_prod_start_date >= msa.attribute1
                AND msa.attribute3                IS NULL
                AND (  (   iv_process_type            = cv_process_type_plus
                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- 抽出条件：特別横持取得パターン４
            OR  (   prm_prod_start_date >= msa.attribute1
                AND msa.attribute2                IS NULL
                AND prm_arrival_date    <= msa.attribute3
                AND msa.attribute4                IS NULL
                )
            -- 抽出条件：特別横持取得パターン５
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date     BETWEEN msa.attribute2
                                         AND     msa.attribute3
                AND msa.attribute4                IS NULL
                )
            -- 抽出条件：特別横持取得パターン６
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date    >= msa.attribute2
                AND msa.attribute3                IS NULL
                AND (  (   iv_process_type            = cv_process_type_plus
                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
             )
      ;
--
    -- *** ローカル・レコード ***
    l_move_info_rec           l_move_info_cur%ROWTYPE;          -- 移動関連情報取得
    --
    l_in_mas_rec              mrp_src_assignment_pub.assignment_set_rec_type;        -- 割当セットヘッダー
    l_mas_val_rec             mrp_src_assignment_pub.assignment_set_val_rec_type;
    l_out_mas_rec             mrp_src_assignment_pub.assignment_set_rec_type;
    l_out_mas_val_rec         mrp_src_assignment_pub.assignment_set_val_rec_type;
--
    -- *** ローカル・PL/SQL表 ***
    l_in_msa_tab              mrp_src_assignment_pub.assignment_tbl_type;            -- 割当セット明細
    l_msa_val_tab             mrp_src_assignment_pub.assignment_val_tbl_type;
    l_out_msa_tab             mrp_src_assignment_pub.assignment_tbl_type;
    l_out_msa_val_tab         mrp_src_assignment_pub.assignment_val_tbl_type;
--
    -- *** ローカル・PL/SQL表 ***
--
  BEGIN
    --==============================================================
    -- ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
--
-- 2009/11/24 H.Itou Del Start 本番障害#7 計画が稼動するまで割当セットAPI起動を起動しない。
/*
    --==============================================================
    -- 関連移動情報の取得
    --==============================================================
    OPEN l_move_info_cur;
    LOOP
      FETCH l_move_info_cur INTO l_move_info_rec;
      EXIT WHEN l_move_info_cur%NOTFOUND;
      --
      -- カウントアップ
      ln_loop_cnt := ln_loop_cnt + 1;
      --
      -- 確定通知時(加算)の場合は移動明細削除を考慮しないので処理をスキップ
      IF iv_process_type = cv_process_type_plus AND l_move_info_rec.delete_flg = 'Y' THEN
        NULL;
      ELSE
        --
--
    --==============================================================
    -- 特別横持制御マスタ情報の取得
    --==============================================================
        OPEN l_assignments_info_cur (
           l_move_info_rec.ship_from_code
          ,l_move_info_rec.ship_to_code
          ,l_move_info_rec.arrival_date
          ,l_move_info_rec.item_code
          ,l_move_info_rec.quantity
          ,l_move_info_rec.prod_start_date
          );
        FETCH l_assignments_info_cur INTO
          l_in_mas_rec.assignment_set_id          -- 割当セットヘッダ.割当セットヘッダID
         ,l_in_mas_rec.assignment_set_name        -- 割当セットヘッダ.割当セット名
         ,l_in_mas_rec.creation_date              -- 割当セットヘッダ.作成日
         ,l_in_mas_rec.created_by                 -- 割当セットヘッダ.作成者
         ,l_in_mas_rec.description                -- 割当セットヘッダ.割当セット摘要
         ,l_in_mas_rec.attribute_category         -- 割当セットヘッダ.Attribute_Category
         ,l_in_mas_rec.attribute1                 -- 割当セットヘッダ.割当セット区分(DFF1)
         ,l_in_mas_rec.attribute2                 -- 割当セットヘッダ.DFF2
         ,l_in_mas_rec.attribute3                 -- 割当セットヘッダ.DFF3
         ,l_in_mas_rec.attribute4                 -- 割当セットヘッダ.DFF4
         ,l_in_mas_rec.attribute5                 -- 割当セットヘッダ.DFF5
         ,l_in_mas_rec.attribute6                 -- 割当セットヘッダ.DFF6
         ,l_in_mas_rec.attribute7                 -- 割当セットヘッダ.DFF7
         ,l_in_mas_rec.attribute8                 -- 割当セットヘッダ.DFF8
         ,l_in_mas_rec.attribute9                 -- 割当セットヘッダ.DFF9
         ,l_in_mas_rec.attribute10                -- 割当セットヘッダ.DFF10
         ,l_in_mas_rec.attribute11                -- 割当セットヘッダ.DFF11
         ,l_in_mas_rec.attribute12                -- 割当セットヘッダ.DFF12
         ,l_in_mas_rec.attribute13                -- 割当セットヘッダ.DFF13
         ,l_in_mas_rec.attribute14                -- 割当セットヘッダ.DFF14
         ,l_in_mas_rec.attribute15                -- 割当セットヘッダ.DFF15
         ,l_in_msa_tab(1).assignment_id           -- 割当セット明細.割当セット明細ID
         ,l_in_msa_tab(1).assignment_type         -- 割当セット明細.割当先タイプ
         ,l_in_msa_tab(1).sourcing_rule_id        -- 割当セット明細.ソースルールID
         ,l_in_msa_tab(1).sourcing_rule_type      -- 割当セット明細.物流構成表/ソースルールタイプ
         ,l_in_msa_tab(1).assignment_set_id       -- 割当セット明細.割当セットヘッダID
         ,l_in_msa_tab(1).creation_date           -- 割当セット明細.作成日
         ,l_in_msa_tab(1).created_by              -- 割当セット明細.作成者
         ,l_in_msa_tab(1).organization_id         -- 割当セット明細.組織ID
         ,l_in_msa_tab(1).customer_id             -- 割当セット明細.Customer_Id
         ,l_in_msa_tab(1).ship_to_site_id         -- 割当セット明細.Ship_To_Site_Id
         ,l_in_msa_tab(1).category_id             -- 割当セット明細.Category_Id
         ,l_in_msa_tab(1).category_set_id         -- 割当セット明細.Category_Set_Id
         ,l_in_msa_tab(1).inventory_item_id       -- 割当セット明細.品目ID
         ,l_in_msa_tab(1).secondary_inventory     -- 割当セット明細.Secondary_Inventory
         ,l_in_msa_tab(1).attribute_category      -- 割当セット明細.割当セット区分
         ,l_in_msa_tab(1).attribute1              -- 割当セット明細.開始製造年月日(DFF1)
         ,l_in_msa_tab(1).attribute2              -- 割当セット明細.有効開始日(DFF2)
         ,l_in_msa_tab(1).attribute3              -- 割当セット明細.有効終了日(DFF3)
         ,l_in_msa_tab(1).attribute4              -- 割当セット明細.設定数量(DFF4)
         ,l_in_msa_tab(1).attribute5              -- 割当セット明細.移動数(DFF5)
         ,l_in_msa_tab(1).attribute6              -- 割当セット明細.DFF6
         ,l_in_msa_tab(1).attribute7              -- 割当セット明細.DFF7
         ,l_in_msa_tab(1).attribute8              -- 割当セット明細.DFF8
         ,l_in_msa_tab(1).attribute9              -- 割当セット明細.DFF9
         ,l_in_msa_tab(1).attribute10             -- 割当セット明細.DFF10
         ,l_in_msa_tab(1).attribute11             -- 割当セット明細.DFF11
         ,l_in_msa_tab(1).attribute12             -- 割当セット明細.DFF12
         ,l_in_msa_tab(1).attribute13             -- 割当セット明細.DFF13
         ,l_in_msa_tab(1).attribute14             -- 割当セット明細.DFF14
         ,l_in_msa_tab(1).attribute15             -- 割当セット明細.DFF15
         ;
        --
        -- 対象データが存在する場合
        IF ( l_assignments_info_cur%FOUND ) THEN
          -- 割当セット・API標準レコードタイプの準備
          l_in_mas_rec.operation         := cv_operation_update;      -- 割当セットヘッダ.処理区分(UPDATE)
          l_in_mas_rec.last_update_date  := cd_last_update_date;      -- 割当セットヘッダ.最終更新者
          l_in_mas_rec.last_updated_by   := cn_last_updated_by;       -- 割当セットヘッダ.最終更新日
          l_in_mas_rec.last_update_login := cn_last_update_login;     -- 割当セットヘッダ.最終更新ログイン
          --
    --==============================================================
    -- 移動数量の計算
    --==============================================================
          --
          -- 処理区分によって加算、減算を制御
          IF ( iv_process_type = cv_process_type_plus ) THEN
            -- 加算の場合
            -- ケース換算
            xxcop_common_pkg.get_case_quantity(
              iv_item_no               => l_move_info_rec.item_code  -- 品目コード
             ,in_individual_quantity   => l_move_info_rec.quantity   -- バラ数量
             ,in_trunc_digits          => 0                          -- 切捨て桁数
             ,on_case_quantity         => ln_case_qty                -- ケース数量
             ,ov_retcode               => lv_retcode                 -- リターンコード
             ,ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
             ,ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE internal_process_expt;
            END IF;
            --
            ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) + ln_case_qty;
            --
          ELSIF ( iv_process_type = cv_process_type_minus ) THEN
            -- 減算の場合は特別横持制御マスタコントロールアドオンテーブルより変更前数量を取得
            BEGIN
              SELECT xac.mov_qty
              INTO   ln_quantity_before
              FROM   xxcop_assignment_controls xac    -- 特別横持制御マスタコントロール
              WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
              AND    xac.mov_line_id = l_move_info_rec.mov_line_id
              AND    xac.lot_id      = l_move_info_rec.lot_id
              ;
              -- ケース換算
              xxcop_common_pkg.get_case_quantity(
                iv_item_no               => l_move_info_rec.item_code  -- 品目コード
               ,in_individual_quantity   => ln_quantity_before         -- バラ数量
               ,in_trunc_digits          => 0                          -- 切捨て桁数
               ,on_case_quantity         => ln_case_qty                -- ケース数量
               ,ov_retcode               => lv_retcode                 -- リターンコード
               ,ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
               ,ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE internal_process_expt;
              END IF;
              --
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ln_quantity_before := 0;
                ln_case_qty := 0;
                --
            END;
            -- 移動数量を減算
            ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) - ln_case_qty;
            --
          END IF;
          --

    --==============================================================
    -- 割当セットAPI起動
    --==============================================================
          -- 割当セット明細PLSQL表の準備
          l_in_msa_tab(1).attribute5         := TO_CHAR( ln_quantity );    -- 割当セット明細.移動数(DFF5)
          l_in_msa_tab(1).operation          := cv_operation_update;       -- 割当セット明細.処理区分(UPDATE)
          l_in_msa_tab(1).last_update_date   := cd_last_update_date;       -- 割当セット明細.最終更新者
          l_in_msa_tab(1).last_updated_by    := cn_last_updated_by;        -- 割当セット明細.最終更新日
          l_in_msa_tab(1).last_update_login  := cn_last_update_login;      -- 割当セット明細.最終更新ログイン
          --
          -- 割当セットヘッダ/明細の更新（API起動）
          mrp_src_assignment_pub.process_assignment(
             p_api_version_number     => cv_api_version
            ,p_init_msg_list          => FND_API.G_TRUE
            ,p_return_values          => FND_API.G_TRUE
            ,p_commit                 => FND_API.G_FALSE
            ,x_return_status          => lv_return_status
            ,x_msg_count              => ln_msg_count
            ,x_msg_data               => lv_msg_data
            ,p_Assignment_Set_rec     => l_in_mas_rec
            ,p_Assignment_Set_val_rec => l_mas_val_rec
            ,p_Assignment_tbl         => l_in_msa_tab
            ,p_Assignment_val_tbl     => l_msa_val_tab
            ,x_Assignment_Set_rec     => l_out_mas_rec
            ,x_Assignment_Set_val_rec => l_out_mas_val_rec
            ,x_Assignment_tbl         => l_out_msa_tab
            ,x_Assignment_val_tbl     => l_out_msa_val_tab
          );
          --
          -- エラーが発生した場合
          IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
             ov_errmsg := lv_msg_data;
             RAISE api_expt;
          END IF;
          --

    --==============================================================
    -- 特別横持制御マスタコントロールテーブル反映
    --==============================================================
          -- 処理区分によって挿入、削除を制御
          IF ( iv_process_type = cv_process_type_plus ) THEN
            -- 処理区分が加算の場合はデータ登録
            INSERT INTO xxcop_assignment_controls (
              mov_hdr_id                -- 移動ヘッダID
             ,mov_num
             ,mov_line_id               -- 移動明細ID
             ,line_number
             ,lot_id                    -- ロットID
             ,lot_no
             ,item_code                 -- 品目コード
             ,arrival_date              -- 着日
             ,mov_qty                   -- 移動数量
             ,created_by                -- 作成者
             ,creation_date             -- 作成日
             ,last_updated_by           -- 最終更新者
             ,last_update_date          -- 最終更新日時
             ,last_update_login         -- 最終更新ログイン
             ,request_id                -- 要求ID
             ,program_application_id    -- コンカレント・プログラム・アプリケーションID
             ,program_id                -- コンカレント・プログラムID
             ,program_update_date       -- プログラム更新日
           )VALUES(
              l_move_info_rec.mov_hdr_id    -- 移動ヘッダID
             ,l_move_info_rec.mov_num
             ,l_move_info_rec.mov_line_id   -- 移動明細ID
             ,l_move_info_rec.line_number
             ,l_move_info_rec.lot_id        -- ロットID
             ,l_move_info_rec.lot_no
             ,l_move_info_rec.item_code     -- 品目コード
             ,TO_DATE(l_move_info_rec.arrival_date, 'YYYY/MM/DD')  -- 着日
             ,l_move_info_rec.quantity      -- 移動数量
             ,cn_created_by                 -- 作成者
             ,cd_creation_date              -- 作成日
             ,cn_last_updated_by            -- 最終更新者
             ,cd_last_update_date           -- 最終更新日時
             ,cn_last_update_login          -- 最終更新ログイン
             ,cn_request_id                 -- 要求ID
             ,cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                 -- コンカレント・プログラムID
             ,cd_program_update_date        -- プログラム更新日
           );
           --
          ELSIF ( iv_process_type = cv_process_type_minus ) THEN
            -- 処理区分が減算の場合はデータ削除
            BEGIN
              SELECT xac.ROWID
              INTO   lv_rowid
              FROM   xxcop_assignment_controls xac
              WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
              AND    xac.mov_line_id = l_move_info_rec.mov_line_id
              AND    xac.lot_id      = l_move_info_rec.lot_id
              FOR UPDATE NOWAIT
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
                --
            END;
            --
            DELETE xxcop_assignment_controls xac
            WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
            AND    xac.mov_line_id = l_move_info_rec.mov_line_id
            AND    xac.lot_id      = l_move_info_rec.lot_id
            ;
          END IF;
          --
        END IF;
        --
        -- カーソルクローズ
        CLOSE l_assignments_info_cur;
      --
      END IF;
      --
    END LOOP;
    --
    IF ( ln_loop_cnt < 1 ) THEN
      ov_errbuf        := NULL;
      ov_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_application
                            ,iv_name         => cv_message_00003
                            );
      ov_retcode       := cv_status_error;
      RETURN;
      -- カーソルクローズ
      CLOSE l_move_info_cur;
      --
    END IF;
    -- カーソルクローズ
    CLOSE l_move_info_cur;
*/
-- 2009/11/24 H.Itou Del End
--
  EXCEPTION
    WHEN internal_process_expt THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_errmsg  := NULL;
      ov_errbuf  := NVL(lv_errbuf,lv_errmsg);
      ov_retcode := cv_status_error;
      --
    -- API起動でエラー
    WHEN api_expt THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_retcode       := cv_status_error;
      --
    -- その他例外エラー
    WHEN OTHERS THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      --
--20090723_Ver1.3_0000670_SCS.Fukada_ADD_END
  END upd_assignment;
  --
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : 倉庫情報取得処理
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    iv_organization_code    IN  VARCHAR2,     -- 組織コード
    ov_loct_code            OUT VARCHAR2,     -- 倉庫コード
    ov_loct_name            OUT VARCHAR2,     -- 倉庫名
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_loct_info'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_del_mark_n  CONSTANT NUMBER        := 0;                        -- 有効
--
    -- *** ローカル変数 ***
    lv_loct_code ic_loct_mst.location%TYPE;
    lv_loct_name ic_loct_mst.loct_desc%TYPE;
    lv_whse_code ic_loct_mst.whse_code%TYPE;
    ln_rec_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --倉庫コード取得
    --==============================================================
    SELECT MIN(ilm.location)                   --  保管倉庫コード（最小値）
          ,MIN(ilm.whse_code)                  --  OPM倉庫コード（最小値）
          ,COUNT(ilm.location)                 --  倉庫コード（対象レコード数）
    INTO   lv_loct_code
          ,lv_whse_code
          ,ln_rec_cnt
    FROM   ic_loct_mst                 ilm     --  OPM保管マスタ
    WHERE  ilm.whse_code   = iv_organization_code
    AND    ilm.delete_mark = cn_del_mark_n
    ;
    --==============================================================
    --対象レコード無し判定
    --==============================================================
    IF ln_rec_cnt = 0 then
      RAISE NO_DATA_FOUND;
    End IF;
    --
    --==============================================================
    --倉庫名取得
    --==============================================================
    SELECT ilm.loct_desc                       --  倉庫名
    INTO   lv_loct_name
    FROM   ic_loct_mst                 ilm      --  OPM保管マスタ
    WHERE  ilm.location  = lv_loct_code
    AND    ilm.whse_code = lv_whse_code
    ;
    --
    ov_loct_code := lv_loct_code;
    ov_loct_name := lv_loct_name;
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode   := cv_status_warn;
      ov_errbuf    := NULL;
      ov_errmsg    := NULL;
      ov_loct_code := NULL;
      ov_loct_name := NULL;
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg    := NULL;
      ov_loct_code := NULL;
      ov_loct_name := NULL;
  END get_loct_info;
  --
END XXCOP_COMMON_PKG2;
/
