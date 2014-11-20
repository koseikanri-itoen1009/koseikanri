CREATE OR REPLACE
PACKAGE BODY XXCOI006A12R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A12R(body)
 * Description      : パラメータで入力された年月およびテナント(ＨＨＴ運用なしの保管場所)
 *                    を元に月次在庫受払表に存在する品目及び、手持ち数量に存在する品目の一
 *                    覧を作成します。
 * MD.050           : 商品実地棚卸票    MD050_COI_006_A12
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  final_svf              SVF起動                    (A-4)
 *                         ワークテーブルデータ削除   (A-5)
 *  get_data               データ取得                 (A-2)
 *                         ワークテーブルデータ登録   (A-3)
 *  init                   初期処理                   (A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   Sai.u            新規作成
 *  2009/03/05    1.1   T.Nakamura       [障害COI_035] 件数出力の不具合対応
 *  2009/09/08    1.2   H.Sasaki         [0001266]OPM品目アドオンの版管理対応
 *  2009/09/09    1.3   N.Abe            [0001325]月首在庫の取得対応
 *  2010/01/07    1.4   N.Abe            [E_本稼動_00858]月首残高なしデータを出力しない
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
  ov_cost_errbuf              VARCHAR2(5000);               -- エラー・メッセージ
  ov_cost_retcode             VARCHAR2(1);                  -- リターンコード
  ov_cost_errmsg              VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(99) := 'XXCOI006A12R';     -- パッケージ名
  cv_xxcoi_sn        CONSTANT VARCHAR2(9)  := 'XXCOI';            -- SHORT_NAME_FOR_XXCOI
  cv_subinv_4        CONSTANT VARCHAR2(1)  := '4';                -- 保管場所区分(4:専門店)
  cv_inv_kbn2        CONSTANT VARCHAR2(3)  := '2';                -- 棚卸区分：月末
  cv_msg_00005       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
  cv_msg_00006       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';
  cv_msg_00008       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
  cv_msg_00011       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011';
  cv_msg_10084       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10084';
  cv_msg_10085       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10085';
  cv_msg_10086       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10086';
  cv_msg_10088       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10088';
  cv_protok_sn       CONSTANT VARCHAR2(20) := 'PRO_TOK';
  cv_orgcode_sn      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';
  cv_org_code_p      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
  cv_p_token1        CONSTANT VARCHAR2(30) := 'P_YEAR_MONTH';
  cv_p_token2        CONSTANT VARCHAR2(30) := 'P_TENANT';
  cv_yyyymmdd        CONSTANT VARCHAR2(10) := 'YYYYMMDD';
  cv_yyyymm          CONSTANT VARCHAR2(10) := 'YYYYMM';
  cv_yymm            CONSTANT VARCHAR2(10) := 'YYMM';
  cv_type_date       CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_type_month      CONSTANT VARCHAR2(10) := 'YYYY/MM';


--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  cv_inv_kbn         fnd_lookup_values.description%TYPE;    -- 棚卸区分
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_out_msg                  VARCHAR2(5000);               -- パラメータメッセージ
  gv_organization_code        VARCHAR2(30);                 -- 在庫組織コード
  gn_organization_id          NUMBER;                       -- 在庫組織ID
  gn_target_cnt               NUMBER;                       -- 対象件数
  gn_normal_cnt               NUMBER;                       -- 成功件数
  gn_error_cnt                NUMBER;                       -- エラー件数
  gn_warn_cnt                 NUMBER;                       -- スキップ件数
  gd_business_date            DATE;                         -- 業務日付
  gd_target_date              DATE;                         -- 対象日
--
  /**********************************************************************************
   * Procedure Name   : final_svf
   * Description      : SVF起動(A-4)
   ***********************************************************************************/
  PROCEDURE final_svf(
    ov_errbuf             OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'final_svf'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);     -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);        -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);     -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_frm_file      CONSTANT VARCHAR2(100) := 'XXCOI006A12S.xml';
    lv_vrq_file      CONSTANT VARCHAR2(100) := 'XXCOI006A12S.vrq';
    lv_output_mode   CONSTANT VARCHAR2(100) := '1';
--
    -- *** ローカル変数 ***
    lv_file_name              VARCHAR2(100);      -- 帳票ファイル名
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
    lv_file_name := cv_pkg_name
                 || TO_CHAR(SYSDATE, cv_yyyymmdd)
                 || TO_CHAR(cn_request_id)
                 || '.pdf';
    -- A-4.SVF起動
    xxccp_svfcommon_pkg.submit_svf_request(
         ov_retcode      => lv_retcode              -- リターンコード
        ,ov_errbuf       => lv_errbuf               -- エラーメッセージ
        ,ov_errmsg       => lv_errmsg               -- ユーザー・エラーメッセージ
        ,iv_conc_name    => cv_pkg_name             -- コンカレント名
        ,iv_file_name    => lv_file_name            -- 出力ファイル名
        ,iv_file_id      => cv_pkg_name             -- 帳票ID
        ,iv_output_mode  => lv_output_mode          -- 出力区分
        ,iv_frm_file     => lv_frm_file             -- フォーム様式ファイル名
        ,iv_vrq_file     => lv_vrq_file             -- クエリー様式ファイル名
        ,iv_org_id       =>  fnd_global.org_id      -- ORG_ID
        ,iv_user_name    =>  fnd_global.user_name   -- ログイン・ユーザ名
        ,iv_resp_name    =>  fnd_global.resp_name   -- ログイン・ユーザの職責名
        ,iv_doc_name     => NULL                    -- 文書名
        ,iv_printer_name => NULL                    -- プリンタ名
        ,iv_request_id   => cn_request_id           -- 要求ID
        ,iv_nodata_msg   => NULL);                  -- データなしメッセージ
    -- 戻り値判定
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10088
                       );
      lv_errbuf  := lv_errmsg;
      ov_retcode := lv_retcode;
      RAISE global_api_expt;
    END IF;
    -- A-5.ワークテーブルデータ削除
    DELETE
    FROM  xxcoi_rep_practice_inventory
    WHERE request_id = cn_request_id;
    IF (gn_target_cnt <> 0) THEN
      gn_normal_cnt := SQL%ROWCOUNT;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END final_svf;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    id_practice_month     IN  VARCHAR2,      -- 年月
    iv_practice_month     IN  VARCHAR2,      -- 年月(YYMM)
    iv_tenant             IN  VARCHAR2,      -- テナント
    iv_inv_name           IN  VARCHAR2,      -- 保管場所名
    iv_base_code          IN  VARCHAR2,      -- 拠点コード
    ov_errbuf             OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message                VARCHAR2(500) := NULL;   -- メッセージ
    ln_check_num              NUMBER        := 0;      -- 棚卸票ID
--
    -- *** ローカル・カーソル(A-2-2) ***
    CURSOR pickout_cur
    IS
-- == 2010/01/07 V1.4 Modified START ===============================================================
--      SELECT  msi.description                 description                   -- 保管場所名称
--             ,msi.attribute7                  base_code                     -- 拠点コード
--             ,sib.sp_supplier_code            sp_supplier_code              -- 専門店仕入先コード
--             ,sib.item_code                   item_code                     -- 品名コード
--             ,SUBSTR(
--                 (CASE  WHEN  TRUNC(TO_DATE(iib.attribute3, cv_type_date)) > TRUNC(gd_target_date)
--                        THEN  iib.attribute1                                -- 群コード(旧)
--                        ELSE  iib.attribute2                                -- 群コード(新)
--                  END
--                 ), 1, 3
--              )                               gun_code                      -- 群コード
--             ,imb.item_short_name             item_short_name               -- 略称
--             ,xirm.month_begin_quantity       month_begin_quantity          -- 月首残高（合計）
--      FROM    (SELECT   sub_xirm.subinventory_code              subinventory_code
--                       ,sub_xirm.inventory_item_id              inventory_item_id
--                       ,sub_xirm.organization_id                organization_id
---- == 2009/09/09 V1.3 Modified START ===============================================================
----                       ,SUM(sub_xirm.month_begin_quantity)      month_begin_quantity
--                       ,SUM(sub_xirm.inv_result)                month_begin_quantity
---- == 2009/09/09 V1.3 Modified END   ===============================================================
--               FROM     xxcoi_inv_reception_monthly     sub_xirm            -- 月次在庫受払表(月次)
--               WHERE    sub_xirm.subinventory_code      =   NVL(iv_tenant, sub_xirm.subinventory_code)
--               AND      sub_xirm.organization_id        =   gn_organization_id
--               AND      sub_xirm.subinventory_type      =   cv_subinv_4
--               AND      sub_xirm.practice_month         =   TO_CHAR(ADD_MONTHS(id_practice_month, -1), cv_yyyymm)
--               AND      sub_xirm.inventory_kbn          =   cv_inv_kbn2     -- 棚卸区分(月末)
--               GROUP BY sub_xirm.subinventory_code
--                       ,sub_xirm.inventory_item_id
--                       ,sub_xirm.organization_id
--              )                               xirm
--             ,mtl_secondary_inventories       msi                           -- 保管場所マスタ(INV)
--             ,mtl_system_items_b              msib                          -- Disc品目        (INV)
--             ,ic_item_mst_b                   iib                           -- OPM品目         (GMI)
--             ,xxcmn_item_mst_b                imb                           -- OPM品目アドオン (XXCMN)
--             ,xxcmm_system_items_b            sib                           -- Disc品目アドオン(XXCMM)
--      WHERE   xirm.subinventory_code      =   msi.secondary_inventory_name
--      AND     xirm.organization_id        =   msi.organization_id
--      AND     msi.attribute1              =   cv_subinv_4                   -- 保管場所区分(専門店)
--      AND     TRUNC(NVL(msi.disable_date, gd_target_date)) >= TRUNC(gd_target_date)
--      AND     xirm.inventory_item_id      =   msib.inventory_item_id
--      AND     xirm.organization_id        =   msib.organization_id
--      AND     msib.segment1               =   iib.item_no
--      AND     iib.item_id                 =   imb.item_id
--      AND     imb.item_id                 =   sib.item_id
---- == 2009/09/08 V1.2 Added START ===============================================================
--      AND     TRUNC(gd_target_date) BETWEEN imb.start_date_active
--                                    AND     NVL(imb.end_date_active, TRUNC(gd_target_date));
---- == 2009/09/08 V1.2 Added END   ===============================================================
      SELECT  msi.description                     description               -- 保管場所名称
             ,msi.attribute7                      base_code                 -- 拠点コード
             ,sib.sp_supplier_code                sp_supplier_code          -- 専門店仕入先コード
             ,sib.item_code                       item_code                 -- 品名コード
             ,SUBSTR(
                 (CASE  WHEN  TRUNC(TO_DATE(iib.attribute3, cv_type_date)) > TRUNC(gd_target_date)
                        THEN  iib.attribute1                                -- 群コード(旧)
                        ELSE  iib.attribute2                                -- 群コード(新)
                  END
                 ), 1, 3
              )                                   gun_code                  -- 群コード
             ,imb.item_short_name                 item_short_name           -- 略称
             ,(xirm.inv_result + inv_result_bad)  month_begin_quantity      -- 月首残高（合計）
      FROM    xxcoi_inv_reception_monthly     xirm                          -- 月次在庫受払表
             ,mtl_secondary_inventories       msi                           -- 保管場所マスタ(INV)
             ,mtl_system_items_b              msib                          -- Disc品目        (INV)
             ,ic_item_mst_b                   iib                           -- OPM品目         (GMI)
             ,xxcmn_item_mst_b                imb                           -- OPM品目アドオン (XXCMN)
             ,xxcmm_system_items_b            sib                           -- Disc品目アドオン(XXCMM)
      WHERE   xirm.subinventory_code      =   NVL(iv_tenant, xirm.subinventory_code)
      AND     xirm.organization_id        =   gn_organization_id
      AND     xirm.subinventory_type      =   cv_subinv_4
      AND     xirm.practice_month         =   TO_CHAR(ADD_MONTHS(id_practice_month, -1), cv_yyyymm)
      AND     xirm.inventory_kbn          =   cv_inv_kbn2                   -- 棚卸区分(月末)
      AND     (xirm.inv_result + inv_result_bad) <> 0                       -- 月首棚卸0以外
      AND     xirm.subinventory_code      =   msi.secondary_inventory_name
      AND     xirm.organization_id        =   msi.organization_id
      AND     msi.attribute1              =   cv_subinv_4                   -- 保管場所区分(専門店)
      AND     TRUNC(NVL(msi.disable_date, gd_target_date)) >= TRUNC(gd_target_date)
      AND     xirm.inventory_item_id      =   msib.inventory_item_id
      AND     xirm.organization_id        =   msib.organization_id
      AND     msib.segment1               =   iib.item_no
      AND     iib.item_id                 =   imb.item_id
      AND     imb.item_id                 =   sib.item_id
      AND     TRUNC(gd_target_date) BETWEEN imb.start_date_active
                                    AND     NVL(imb.end_date_active, TRUNC(gd_target_date));
-- == 2010/01/07 V1.4 Modified END   ===============================================================
-- == 2010/01/07 V1.4 Deleted START ===============================================================
--    --
--    CURSOR onhand_cur
--    IS
--      SELECT  msi.description                 description                   -- 保管場所名称
--             ,msi.attribute7                  base_code                     -- 拠点コード
--             ,sib.sp_supplier_code            sp_supplier_code              -- 専門店仕入先コード
--             ,sib.item_code                   item_code                     -- 品名コード
--             ,SUBSTR(
--                 (CASE  WHEN  TRUNC(TO_DATE(iib.attribute3, cv_type_date)) > TRUNC(gd_target_date)
--                        THEN  iib.attribute1                                -- 群コード(旧)
--                        ELSE  iib.attribute2                                -- 群コード(新)
--                  END
--                 ), 1, 3
--              )                               gun_code                      -- 群コード
--             ,imb.item_short_name             item_short_name               -- 略称
--             ,0                               month_begin_quantity          -- 月首残高（合計）
--      FROM    (SELECT DISTINCT
--                      sub_oqd.inventory_item_id
--                     ,sub_oqd.subinventory_code
--                     ,sub_oqd.organization_id
--               FROM   mtl_onhand_quantities_detail    sub_oqd               -- 手持数量        (INV)
--               WHERE  sub_oqd.subinventory_code   =   NVL(iv_tenant, sub_oqd.subinventory_code)
--               AND    sub_oqd.organization_id     =   gn_organization_id
--              )                               oqd                           -- 手持数量情報
--             ,mtl_secondary_inventories       msi                           -- 保管場所マスタ  (INV)
--             ,mtl_system_items_b              msib                          -- Disc品目        (INV)
--             ,ic_item_mst_b                   iib                           -- OPM品目         (GMI)
--             ,xxcmn_item_mst_b                imb                           -- OPM品目アドオン (XXCMN)
--             ,xxcmm_system_items_b            sib                           -- Disc品目アドオン(XXCMM)
--      WHERE   oqd.subinventory_code       =   msi.secondary_inventory_name
--      AND     oqd.organization_id         =   msi.organization_id
--      AND     msi.attribute1              =   cv_subinv_4                     -- 保管場所区分(専門店)
--      AND     TRUNC(NVL(msi.disable_date, gd_target_date)) >= TRUNC(gd_target_date)
--      AND     oqd.inventory_item_id       =   msib.inventory_item_id
--      AND     oqd.organization_id         =   msib.organization_id
--      AND     msib.segment1               =   iib.item_no
--      AND     iib.item_id                 =   imb.item_id
--      AND     imb.item_id                 =   sib.item_id
---- == 2009/09/08 V1.2 Added START ===============================================================
--      AND     TRUNC(gd_target_date) BETWEEN imb.start_date_active
--                                    AND     NVL(imb.end_date_active, TRUNC(gd_target_date))
---- == 2009/09/08 V1.2 Added END   ===============================================================
--      AND NOT EXISTS(
--                SELECT  1
--                FROM    xxcoi_rep_practice_inventory    xrpi
--                WHERE   xrpi.request_id         =   cn_request_id
--                AND     xrpi.base_code          =   msi.attribute7
--                AND     xrpi.subinventory_name  =   msi.description
--                AND     xrpi.item_code          =   sib.item_code
--      );
-- == 2010/01/07 V1.4 Deleted END   ===============================================================
    -- *** ローカル・レコード ***
    pickout_rec   pickout_cur%ROWTYPE;
-- == 2010/01/07 V1.4 Deleted START ===============================================================
--    onhand_rec    onhand_cur%ROWTYPE;
-- == 2010/01/07 V1.4 Deleted END   ===============================================================
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
--
  -- カーソルオープン
  OPEN pickout_cur;
  LOOP
    FETCH pickout_cur INTO pickout_rec;
    EXIT WHEN pickout_cur%NOTFOUND;
    -- 棚卸票IDをカウント
    ln_check_num  := ln_check_num  + 1;
    -- 対象件数をカウント
    gn_target_cnt := gn_target_cnt + 1;
    -- A-3.ワークテーブルデータ登録（月次在庫より）
    INSERT INTO xxcoi_rep_practice_inventory(
            slit_id                                                   -- 棚卸票ID
           ,inventory_year                                            -- 年
           ,inventory_month                                           -- 月
           ,base_code                                                 -- 拠点コード
           ,subinventory_name                                         -- 棚卸場所名
           ,stockplace_code                                           -- 仕入先コード
           ,gun_code                                                  -- 群コード
           ,item_code                                                 -- 品名コード
           ,item_name                                                 -- 品名
           ,first_inventory_qty                                       -- 月首残高
           ,message                                                   -- メッセージ
           ,last_update_date                                          -- 最終更新日
           ,last_updated_by                                           -- 最終更新者
           ,creation_date                                             -- 作成日
           ,created_by                                                -- 作成者
           ,last_update_login                                         -- 最終更新ユーザ
           ,request_id                                                -- 要求ID
           ,program_application_id                                    -- プログラムアプリケーションID
           ,program_id                                                -- プログラムID
           ,program_update_date)                                      -- プログラム更新日
    VALUES (ln_check_num                                              -- 棚卸票ID
           ,SUBSTR(iv_practice_month,1,2)                             -- 年
           ,SUBSTR(iv_practice_month,3,2)                             -- 月
           ,pickout_rec.base_code                                     -- 拠点コード
           ,pickout_rec.description                                   -- 棚卸場所名
           ,SUBSTR(pickout_rec.sp_supplier_code, 1, 4)                -- 仕入先コード
           ,pickout_rec.gun_code                                      -- 群コード
           ,SUBSTR(pickout_rec.item_code, 1, 7)                       -- 品名コード
           ,pickout_rec.item_short_name                               -- 品名
           ,pickout_rec.month_begin_quantity                          -- 月首残高
           ,NULL                                                      -- メッセージ
           ,SYSDATE                                                   -- 最終更新日
           ,cn_last_updated_by                                        -- 最終更新者
           ,SYSDATE                                                   -- 作成日
           ,cn_created_by                                             -- 作成者
           ,cn_last_update_login                                      -- 最終更新ユーザ
           ,cn_request_id                                             -- 要求ID
           ,cn_program_application_id                                 -- プログラムアプリケーションID
           ,cn_program_id                                             -- プログラムID
           ,SYSDATE);                                                 -- プログラム更新日
  --
  END LOOP;
  CLOSE pickout_cur;
  --
-- == 2010/01/07 V1.4 Deleted START ===============================================================
--  OPEN  onhand_cur;
--  LOOP
--    FETCH onhand_cur INTO onhand_rec;
--    EXIT WHEN onhand_cur%NOTFOUND;
--    -- 棚卸票IDをカウント
--    ln_check_num  := ln_check_num  + 1;
--    -- 対象件数をカウント
--    gn_target_cnt := gn_target_cnt + 1;
--    -- A-3.ワークテーブルデータ登録（手持数量より）
--    INSERT INTO xxcoi_rep_practice_inventory(
--            slit_id                                                   -- 棚卸票ID
--           ,inventory_year                                            -- 年
--           ,inventory_month                                           -- 月
--           ,base_code                                                 -- 拠点コード
--           ,subinventory_name                                         -- 棚卸場所名
--           ,stockplace_code                                           -- 仕入先コード
--           ,gun_code                                                  -- 群コード
--           ,item_code                                                 -- 品名コード
--           ,item_name                                                 -- 品名
--           ,first_inventory_qty                                       -- 月首残高
--           ,message                                                   -- メッセージ
--           ,last_update_date                                          -- 最終更新日
--           ,last_updated_by                                           -- 最終更新者
--           ,creation_date                                             -- 作成日
--           ,created_by                                                -- 作成者
--           ,last_update_login                                         -- 最終更新ユーザ
--           ,request_id                                                -- 要求ID
--           ,program_application_id                                    -- プログラムアプリケーションID
--           ,program_id                                                -- プログラムID
--           ,program_update_date)                                      -- プログラム更新日
--    VALUES (ln_check_num                                              -- 棚卸票ID
--           ,SUBSTR(iv_practice_month,1,2)                             -- 年
--           ,SUBSTR(iv_practice_month,3,2)                             -- 月
--           ,onhand_rec.base_code                                      -- 拠点コード
--           ,onhand_rec.description                                    -- 棚卸場所名
--           ,SUBSTR(onhand_rec.sp_supplier_code, 1, 4)                 -- 仕入先コード
--           ,onhand_rec.gun_code                                       -- 群コード
--           ,SUBSTR(onhand_rec.item_code, 1, 7)                        -- 品名コード
--           ,onhand_rec.item_short_name                                -- 品名
--           ,onhand_rec.month_begin_quantity                           -- 月首残高
--           ,NULL                                                      -- メッセージ
--           ,SYSDATE                                                   -- 最終更新日
--           ,cn_last_updated_by                                        -- 最終更新者
--           ,SYSDATE                                                   -- 作成日
--           ,cn_created_by                                             -- 作成者
--           ,cn_last_update_login                                      -- 最終更新ユーザ
--           ,cn_request_id                                             -- 要求ID
--           ,cn_program_application_id                                 -- プログラムアプリケーションID
--           ,cn_program_id                                             -- プログラムID
--           ,SYSDATE);                                                 -- プログラム更新日
--  --
--  END LOOP;
--  CLOSE onhand_cur;
--  --
-- == 2010/01/07 V1.4 Deleted END   ===============================================================
  -- 結果0件の場合
  IF (ln_check_num = 0) THEN
    -- 結果0件メッセージ取得
    lv_message := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_sn
                      ,iv_name         => cv_msg_00008
                     );
    -- 結果0件メッセージ出力
    INSERT INTO xxcoi_rep_practice_inventory(
            slit_id                                                   -- 棚卸票ID
           ,inventory_year                                            -- 年
           ,inventory_month                                           -- 月
           ,base_code                                                 -- 拠点コード
           ,subinventory_name                                         -- 棚卸場所名
           ,stockplace_code                                           -- 仕入先コード
           ,gun_code                                                  -- 群コード
           ,item_code                                                 -- 品名コード
           ,item_name                                                 -- 品名
           ,first_inventory_qty                                       -- 月首残高
           ,message                                                   -- メッセージ
           ,last_update_date                                          -- 最終更新日
           ,last_updated_by                                           -- 最終更新者
           ,creation_date                                             -- 作成日
           ,created_by                                                -- 作成者
           ,last_update_login                                         -- 最終更新ユーザ
           ,request_id                                                -- 要求ID
           ,program_application_id                                    -- プログラムアプリケーションID
           ,program_id                                                -- プログラムID
           ,program_update_date)                                      -- プログラム更新日
    VALUES (ln_check_num                                              -- 棚卸票ID
           ,SUBSTR(iv_practice_month,1,2)                             -- 年
           ,SUBSTR(iv_practice_month,3,2)                             -- 月
           ,iv_base_code                                              -- 拠点コード
           ,iv_inv_name                                               -- 棚卸場所名
           ,NULL                                                      -- 仕入先コード
           ,NULL                                                      -- 群コード
           ,NULL                                                      -- 品名コード
           ,NULL                                                      -- 品名
           ,NULL                                                      -- 月首残高
           ,lv_message                                                -- メッセージ
           ,SYSDATE                                                   -- 最終更新日
           ,cn_last_updated_by                                        -- 最終更新者
           ,SYSDATE                                                   -- 作成日
           ,cn_created_by                                             -- 作成者
           ,cn_last_update_login                                      -- 最終更新ユーザ
           ,cn_request_id                                             -- 要求ID
           ,cn_program_application_id                                 -- プログラムアプリケーションID
           ,cn_program_id                                             -- プログラムID
           ,SYSDATE);                                                 -- プログラム更新日
  END IF;
  -- コミット
  COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN                                 --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      IF (pickout_cur%ISOPEN) THEN
        CLOSE pickout_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF (pickout_cur%ISOPEN) THEN
        CLOSE pickout_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理
   **********************************************************************************/
  PROCEDURE init(
    iv_practice_month     IN  VARCHAR2,    -- 年月
    iv_tenant             IN  VARCHAR2,    -- テナント
    ov_practice_month     OUT VARCHAR2,    -- 年月(YYMM)
    od_practice_month     OUT DATE,        -- 年月(DATE)
    ov_inv_name           OUT VARCHAR2,    -- 棚卸場所名
    ov_base_code          OUT VARCHAR2,    -- 拠点コード
    ov_errbuf             OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    ld_practice_month    DATE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    BEGIN
      ld_practice_month := TO_DATE(iv_practice_month, cv_yyyymm);
      ov_practice_month := TO_CHAR(ld_practice_month, cv_yymm);
    EXCEPTION
      WHEN OTHERS THEN
        ld_practice_month := TO_DATE(iv_practice_month, cv_type_month);
        ov_practice_month := TO_CHAR(ld_practice_month, cv_yymm);
    END;
--
    -- A-1-1.コンカレント入力パラメータをログに出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_sn
                    ,iv_name         => cv_msg_10084
                    ,iv_token_name1  => cv_p_token1   -- 年月
                    ,iv_token_value1 => TO_CHAR(ld_practice_month, cv_type_month)
                    ,iv_token_name2  => cv_p_token2   -- テナント
                    ,iv_token_value2 => iv_tenant
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    od_practice_month := ld_practice_month;
    -- A-1-2.共通関数(在庫組織コード取得)を使用しプロファイルより在庫組織コードを取得します。
    gv_organization_code := FND_PROFILE.VALUE(cv_org_code_p);
    --
    IF (gv_organization_code IS NULL) THEN
      -- プロファイル:在庫組織コード( &PRO_TOK )の取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00005
                   ,iv_token_name1  => cv_protok_sn
                   ,iv_token_value1 => cv_org_code_p
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-3.上記2.で取得した在庫組織コードをもとに共通部品(在庫組織ID取得)より在庫組織ID取得します。
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
    --
    IF (gn_organization_id IS NULL) THEN
      -- 在庫組織コード( &ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00006
                   ,iv_token_name1  => cv_orgcode_sn
                   ,iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-4.共通関数(業務処理日付取得)より業務日付を取得します。
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_business_date IS NULL) THEN
      -- 業務日付の取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00011
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-5.起動パラメータチェック
    IF (TO_CHAR(ld_practice_month, cv_yyyymm) > TO_CHAR(gd_business_date, cv_yyyymm)) THEN
      -- 起動パラメータ.年月は未来日
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10085
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-6.対象日の設定
    IF (LAST_DAY(ld_practice_month) > gd_business_date) THEN
      gd_target_date := gd_business_date;
    ELSE
      gd_target_date := LAST_DAY(ld_practice_month);   -- 年月の末日
    END IF;
    -- A-1-7.棚卸場所名および拠点コードの取得
    BEGIN
      IF (iv_tenant IS NOT NULL) THEN
        SELECT description
              ,attribute7
        INTO   ov_inv_name
              ,ov_base_code
        FROM   mtl_secondary_inventories
        WHERE  organization_id          = gn_organization_id
        AND    secondary_inventory_name = iv_tenant
        AND    attribute1               = cv_subinv_4
        AND    TRUNC(NVL(disable_date,gd_target_date))
                                       >= TRUNC(gd_target_date)
        AND    ROWNUM = 1;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- テナント無効
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10086
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
    END;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_practice_month     IN  VARCHAR2,     -- 年月
    iv_tenant             IN  VARCHAR2,     -- テナント
    ov_errbuf             OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    ld_practice_month    DATE;                    -- 年月
    lv_practice_month    VARCHAR2(4)   := NULL;   -- 年月(YYMM)
    lv_inv_name          VARCHAR2(200) := NULL;   -- 棚卸場所名
    lv_base_code         VARCHAR2(200) := NULL;   -- 拠点コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
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
    -- ===============================
    -- 初期処理(init)
    -- ===============================
    init(
      iv_practice_month  => iv_practice_month     -- 年月
     ,iv_tenant          => iv_tenant             -- テナント
     ,ov_practice_month  => lv_practice_month     -- 年月(YYMM)
     ,od_practice_month  => ld_practice_month     -- 年月(DATE)
     ,ov_inv_name        => lv_inv_name           -- 棚卸場所名
     ,ov_base_code       => lv_base_code          -- 拠点コード
     ,ov_errbuf          => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- データ取得(get_data)
    -- ===============================
    get_data(
      id_practice_month  => ld_practice_month     -- 年月(DATE)
     ,iv_practice_month  => lv_practice_month     -- 年月(YYMM)
     ,iv_tenant          => iv_tenant             -- テナント
     ,iv_inv_name        => lv_inv_name           -- 棚卸場所名
     ,iv_base_code       => lv_base_code          -- 拠点コード
     ,ov_errbuf          => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      ov_retcode := lv_retcode;
    END IF;
    -- ===============================
    -- SVF起動処理を呼出し(final_svf)
    -- ===============================
    final_svf(
        ov_errbuf  => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode                  -- リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      ov_retcode := lv_retcode;
    END IF;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
    errbuf                OUT VARCHAR2,           -- エラーメッセージ #固定#
    retcode               OUT VARCHAR2,           -- エラーコード     #固定#
    iv_practice_month     IN  VARCHAR2,           -- 年月
    iv_tenant             IN  VARCHAR2            -- テナント
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
    cv_log_name        CONSTANT VARCHAR2(100) := 'LOG';               -- ヘッダメッセージ出力関数パラメータ
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);     -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);        -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);     -- ユーザー・エラー・メッセージ
    lv_message_code           VARCHAR2(100);
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_name
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
       iv_practice_month  => iv_practice_month    -- 年月
      ,iv_tenant          => iv_tenant            -- テナント
      ,ov_errbuf          => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
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
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOI006A12R;
/
