CREATE OR REPLACE PACKAGE BODY XXCOI006A08R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A08R(body)
 * Description      : 要求の発行画面から、品目毎の明細および棚卸数量を帳票に出力します。
 *                    帳票に出力した棚卸結果データには処理済フラグ"Y"を設定します。
 * MD.050           : 棚卸チェックリスト    MD050_COI_006_A08
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  final_svf              SVF起動                    (A-5)
 *                         ワークテーブルデータ削除   (A-6)
 *  get_data               データ取得                 (A-2)
 *                         ワークテーブルデータ登録   (A-3)
 *                         処理済フラグ更新           (A-4)
 *  init                   初期処理                   (A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.0   Sai.u            新規作成
 *  2009/02/16    1.1   N.Abe            [障害COI_006] 抽出条件の不備対応
 *  2009/02/18    1.2   N.Abe            [障害COI_019] 良品区分取得用コード修正対応
 *  2009/03/05    1.3   T.Nakamura       [障害COI_033] 件数出力の不具合対応
 *  2009/03/23    1.4   H.Sasaki         [障害T1_0107] 抽出条件の修正
 *  2009/04/30    1.5   T.Nakamura       最終行にバックスラッシュを追加
 *  2009/07/14    1.6   H.Sasaki         [0000461]帳票ワークテーブルに取込順を設定
 *  2009/08/07    1.7   N.Abe            [0000945]パフォーマンス改善
 *  2009/09/08    1.8   H.Sasaki         [0001266]OPM品目アドオンの版管理対応
 *  2009/09/15    1.9   N.Abe            [0001264]パフォーマンス改善
 *  2010/04/30    1.10  N.Abe            [E_本稼動_02076]取込順の取得方法変更
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
  cv_pkg_name        CONSTANT VARCHAR2(99) := 'XXCOI006A08R';     -- パッケージ名
  cv_xxcoi_sn        CONSTANT VARCHAR2(9)  := 'XXCOI';            -- SHORT_NAME_FOR_XXCOI
  cv_inv_kbn1        CONSTANT VARCHAR2(3)  := '1';                -- 棚卸区分：月中
  cv_inv_kbn2        CONSTANT VARCHAR2(3)  := '2';                -- 棚卸区分：月末
  cv_output_kbn      CONSTANT VARCHAR2(3)  := '0';                -- 出力区分：未出力
  cv_goods_kbn       CONSTANT VARCHAR2(3)  := '1';                -- 良品区分：不良品
  -- 保管場所区分（1:倉庫  2:営業車  3:預け先  4:専門店  5:自販機  8:直送）
  cv_subinv_1      CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2      CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3      CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4      CONSTANT VARCHAR2(1)  :=  '4';
  cv_subinv_5      CONSTANT VARCHAR2(1)  :=  '5';
  cv_subinv_8      CONSTANT VARCHAR2(1)  :=  '8';
  -- メッセージ関連
  cv_msg_00005       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
  cv_msg_00006       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';
  cv_msg_00008       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
  cv_msg_00011       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011';
  cv_msg_10088       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10088';
  cv_msg_10091       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10091';
  cv_msg_10092       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10092';
  cv_msg_10093       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10093';
  cv_msg_10362       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10362';
-- == 2009/09/15 V1.9 Added START ===============================================================
  cv_msg_10403       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10403';
  cv_msg_10404       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10404';
-- == 2009/09/15 V1.9 Added END   ===============================================================
  cv_protok_sn       CONSTANT VARCHAR2(20) := 'PRO_TOK';
  cv_orgcode_sn      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';
  cv_xxcoi_inv_kbn   CONSTANT VARCHAR2(30) := 'XXCOI1_INVENTORY_KBN';
  cv_xxcoi_inv_out   CONSTANT VARCHAR2(30) := 'XXCOI1_INVOUT_KBN';
  cv_org_code_p      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
  cv_p_token1        CONSTANT VARCHAR2(30) := 'P_INVENTORY_TYPE';
  cv_p_token2        CONSTANT VARCHAR2(30) := 'P_INV_DATE';
  cv_p_token3        CONSTANT VARCHAR2(30) := 'P_YEAR_MONTH';
  cv_p_token4        CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_p_token5        CONSTANT VARCHAR2(30) := 'P_INVENTORY_LOCATION';
  cv_p_token6        CONSTANT VARCHAR2(30) := 'P_OUT_TYPE';
  --参照タイプ
  cv_qual_good_dv    CONSTANT VARCHAR2(29) := 'XXCOI1_QUALITY_GOODS_DIVISION';
  cv_not_qual_goods  CONSTANT VARCHAR2(1)  := '1';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  cv_inv_kbn         fnd_lookup_values.description%TYPE;    -- 棚卸区分
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_out_msg                  VARCHAR2(5000);                 -- パラメータメッセージ
  gv_user_basecode            VARCHAR2(4);                    -- 所属拠点
  gv_organization_code        VARCHAR2(30);                   -- 在庫組織コード
  gn_organization_id          NUMBER;                         -- 在庫組織ID
  gn_target_cnt               NUMBER;                         -- 対象件数
  gn_normal_cnt               NUMBER;                         -- 成功件数
  gn_error_cnt                NUMBER;                         -- エラー件数
  gn_warn_cnt                 NUMBER;                         -- スキップ件数
  gd_business_date            DATE;                           -- 業務日付
  gd_target_date              DATE;                           -- 対象日
  gt_goods_name               fnd_lookup_values.meaning%TYPE; -- 良品区分名称(不良品)
--
  /**********************************************************************************
   * Procedure Name   : final_svf
   * Description      : SVF起動(A-5)
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
    lv_frm_file      CONSTANT VARCHAR2(100) := 'XXCOI006A08S.xml';
    lv_vrq_file      CONSTANT VARCHAR2(100) := 'XXCOI006A08S.vrq';
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
                 || TO_CHAR(SYSDATE,'YYYYMMDD')
                 || TO_CHAR(cn_request_id)
                 || '.pdf';
    -- A-5.SVF起動
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- A-6.ワークテーブルデータ削除
    DELETE
    FROM  xxcoi_rep_inv_checklist
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
      ov_retcode := cv_status_error;
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
    iv_inventory_kbn      IN  VARCHAR2,      -- 棚卸区分
    id_practice_date      IN  DATE,          -- 年月日
    iv_practice_month     IN  VARCHAR2,      -- 年月
    iv_base_code          IN  VARCHAR2,      -- 拠点
    iv_inventory_place    IN  VARCHAR2,      -- 棚卸場所
    iv_output_kbn         IN  VARCHAR2,      -- 出力区分
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
    lv_base_name              VARCHAR2(200) := NULL;   -- 拠点名
    lv_inv_name               VARCHAR2(200) := NULL;   -- 保管場所名
    lv_message                VARCHAR2(500) := NULL;   -- メッセージ
    ln_check_num              NUMBER        := 0;      -- チェックリストID
-- == 2009/09/15 V1.9 Added START ===============================================================
    lv_base_code              VARCHAR2(4);
    lv_dept_hht_div           xxcmm_cust_accounts.dept_hht_div%TYPE;
    lv_sql_str                VARCHAR2(4500);
    ln_cnt                    NUMBER;
-- == 2009/09/15 V1.9 Added END   ===============================================================
--
    -- *** ローカル・カーソル(A-2-2) ***
-- == 2009/03/23 V1.4 Modified START ===============================================================
--    CURSOR pickout_cur
--    IS
--    SELECT xir.ROWID                      xir_row_id                    -- ROWID
--          ,xir.base_code                  xir_base_code                 -- 拠点コード
--          ,biv.base_short_name            biv_base_short_name           -- 拠点略称
--          ,msi.secondary_inventory_name   msi_secondary_inventory_name  -- 保管場所コード
--          ,msi.description                msi_description               -- 保管場所名称
--          ,xir.inventory_date             xir_inventory_date            -- 棚卸日
--          ,xir.slip_no                    xir_slip_no                   -- 伝票No
--          ,xir.item_code                  xir_item_code                 -- 品目コード
--          ,imb.item_short_name            imb_item_short_name           -- 品名
--          ,xir.case_in_qty                xir_case_in_qty               -- 入数
--          ,xir.case_qty                   xir_case_qty                  -- ケース数
--          ,xir.quantity                   xir_quantity                  -- 本数
--          ,xir.quality_goods_kbn          xir_quality_goods_kbn         -- 良品区分
--          ,xir.input_order                xir_input_order               -- 取込み順
--    FROM   xxcoi_inv_result               xir                           -- HHT棚卸結果テーブル(XXCOI)
--          ,xxcoi_inv_control              xic                           -- 棚卸管理テーブル   (XXCOI)
--          ,mtl_secondary_inventories      msi                           -- 保管場所マスタ     (INV)
--          ,xxcmn_item_mst_b               imb                           -- OPM品目アドオン    (XXCMN)
--          ,ic_item_mst_b                  iib                           -- OPM品目マスタ      (GMI)
--          ,xxcoi_base_info2_v             biv                           -- 拠点情報ビュー     (XXCOI)
--    WHERE  xir.inventory_kbn            = iv_inventory_kbn              -- 棚卸区分
--    AND   (   (TO_CHAR(xir.inventory_date, 'YYYYMM') = iv_practice_month)
--           OR (TRUNC(xir.inventory_date)    = TRUNC(id_practice_date))
--          )
--    AND    biv.base_code                = xir.base_code
--    AND    biv.focus_base_code          = NVL(iv_base_code,gv_user_basecode)
--    AND    msi.organization_id          = gn_organization_id
--    AND    xic.inventory_seq            = xir.inventory_seq
--    AND    xic.subinventory_code        = NVL(iv_inventory_place, xic.subinventory_code)
--    AND    msi.secondary_inventory_name = xic.subinventory_code
--    AND    msi.attribute1              <> cv_subinv_5                   -- 保管場所区分≠自販機
--    AND    msi.attribute1              <> cv_subinv_8                   -- 保管場所区分≠直送
--    AND    msi.attribute7               = xir.base_code
--    AND    TRUNC(NVL(msi.disable_date, gd_target_date))  >=  TRUNC(gd_target_date)
--    AND    iib.item_no                  = xir.item_code
--    AND    iib.item_id                  = imb.item_id
--    AND    xir.process_flag             = DECODE(iv_output_kbn,'1','Y','N')
--
-- == 2009/09/15 V1.9 Modified START ===============================================================
--    CURSOR pickout_cur(iv_cur_base_code IN  VARCHAR2)
--    IS
--      SELECT  xir.ROWID                         xir_row_id                    -- ROWID
--             ,xir.base_code                     xir_base_code                 -- 拠点コード
--             ,SUBSTRB(hca.account_name, 1, 8)   biv_base_short_name           -- 拠点略称
--             ,msi.secondary_inventory_name      msi_secondary_inventory_name  -- 保管場所コード
--             ,msi.description                   msi_description               -- 保管場所名称
--             ,xir.inventory_date                xir_inventory_date            -- 棚卸日
--             ,xir.slip_no                       xir_slip_no                   -- 伝票No
--             ,xir.item_code                     xir_item_code                 -- 品目コード
--             ,imb.item_short_name               imb_item_short_name           -- 品名
--             ,xir.case_in_qty                   xir_case_in_qty               -- 入数
--             ,xir.case_qty                      xir_case_qty                  -- ケース数
--             ,xir.quantity                      xir_quantity                  -- 本数
--             ,xir.quality_goods_kbn             xir_quality_goods_kbn         -- 良品区分
---- == 2009/07/14 V1.6 Modified START ===============================================================
----             ,xir.input_order                   xir_input_order               -- 取込み順
--             ,ROW_NUMBER() OVER
--                        (PARTITION BY xir.base_code, msi.secondary_inventory_name
--                         ORDER BY     xir.creation_date, xir.input_order
--                        ) xir_input_order                                     --  取込み順
---- == 2009/07/14 V1.6 Modified END   ===============================================================
--      FROM    xxcoi_inv_result                  xir                           -- HHT棚卸結果テーブル(XXCOI)
--             ,xxcoi_inv_control                 xic                           -- 棚卸管理テーブル   (XXCOI)
--             ,mtl_secondary_inventories         msi                           -- 保管場所マスタ     (INV)
--             ,xxcmn_item_mst_b                  imb                           -- OPM品目アドオン    (XXCMN)
--             ,ic_item_mst_b                     iib                           -- OPM品目マスタ      (GMI)
--             ,(SELECT   xca.management_base_code    management_base_code
--                       ,NVL(xca.dept_hht_div, '2')  dept_hht_div
--                       ,hca.account_number          account_number
--               FROM     xxcmm_cust_accounts         xca
--                       ,hz_cust_accounts            hca
--               WHERE    xca.customer_id         =   hca.cust_account_id
--               AND      hca.account_number      =   iv_cur_base_code
--               AND      hca.customer_class_code =   '1'
--               AND      hca.status              =   'A'
--              )                                 cai                           -- 拠点情報
--             ,hz_cust_accounts                  hca                           -- 顧客マスタ
--      WHERE   xir.inventory_kbn                           = iv_inventory_kbn  -- 棚卸区分
--      AND     (   (TO_CHAR(xir.inventory_date, 'YYYYMM')  = iv_practice_month)
--               OR (TRUNC(xir.inventory_date)              = TRUNC(id_practice_date))
--              )
--      AND     (   (   (   (cai.dept_hht_div         = '1')
--                       OR (cai.management_base_code IS NULL)
--                      )
--                   AND  xir.base_code             = NVL(cai.management_base_code, iv_cur_base_code)
--                  )
--               OR (     cai.dept_hht_div         <> '1'
--                   AND  cai.management_base_code  = cai.account_number
--                   AND  xir.base_code            IN (SELECT  hca.account_number
--                                                     FROM    xxcmm_cust_accounts         xca
--                                                            ,hz_cust_accounts            hca
--                                                     WHERE   xca.customer_id          =  hca.cust_account_id
--                                                     AND     xca.management_base_code =  cai.management_base_code
--                                                     AND     hca.customer_class_code  =  '1'
--                                                     AND     hca.status               =  'A'
--                                                   )
--                  )
--               OR (     cai.dept_hht_div         <> '1'
--                   AND  cai.management_base_code <> cai.account_number
--                   AND  xir.base_code             = NVL(cai.account_number, iv_cur_base_code)
--                  )
--              )
--      AND     msi.organization_id          = gn_organization_id
--      AND     xic.inventory_seq            = xir.inventory_seq
--      AND     xic.subinventory_code        = NVL(iv_inventory_place, xic.subinventory_code)
--      AND     msi.secondary_inventory_name = xic.subinventory_code
--      AND     msi.attribute1              <> cv_subinv_5                   -- 保管場所区分≠自販機
--      AND     msi.attribute1              <> cv_subinv_8                   -- 保管場所区分≠直送
--      AND     (   (cai.management_base_code       = iv_cur_base_code)
--               OR (    (cai.management_base_code <> iv_cur_base_code)
--                   AND (msi.attribute7            = iv_cur_base_code)
--                  )
--               OR (    (cai.management_base_code IS NULL)
--                   AND (msi.attribute7            = iv_cur_base_code)
--                  )
--              )
--      AND     TRUNC(NVL(msi.disable_date, gd_target_date))  >=  TRUNC(gd_target_date)
--      AND     iib.item_no                  = xir.item_code
--      AND     iib.item_id                  = imb.item_id
---- == 2009/09/08 V1.8 Added START ===============================================================
--      AND     xir.inventory_date  BETWEEN imb.start_date_active
--                                  AND     NVL(imb.end_date_active, xir.inventory_date)
---- == 2009/09/08 V1.8 Added END   ===============================================================
--      AND     xir.process_flag             = DECODE(iv_output_kbn, '1', 'Y', 'N')
--      AND     (   (    cai.dept_hht_div             = '1'
--                   AND hca.account_number           = NVL(cai.management_base_code, iv_cur_base_code)
--                  )
--               OR (    cai.dept_hht_div            <> '1'
--                   AND hca.account_number           = xir.base_code
--                  )
--              )
--      FOR UPDATE OF
--             xir.process_flag NOWAIT
--      ORDER BY
--             xir.base_code                                  -- 拠点コード
--            ,msi.secondary_inventory_name                   -- 保管場所コード
--            ,xir.slip_no                                    -- 伝票No.
--            ,xir.input_order;                               -- 取り込み順
---- == 2009/03/23 V1.4 Modified END   ===============================================================
----
    -- 拠点抽出カーソル
    CURSOR acct_num_cur
    IS
    SELECT  hca.account_number              account_number
           ,SUBSTRB(hca.account_name,1,8)   base_short_name
    FROM    hz_cust_accounts      hca
           ,xxcmm_cust_accounts   xca
    WHERE   xca.management_base_code   = lv_base_code
    AND     hca.status                 = 'A'
    AND     hca.customer_class_code    = '1'
    AND     hca.cust_account_id        = xca.customer_id
    AND     NVL(xca.dept_hht_div, '2') <> '1'
    ;
--    -- *** ローカル・レコード ***
--    pickout_rec pickout_cur%ROWTYPE;
--
    acct_num_rec    acct_num_cur%ROWTYPE;
--
    TYPE  cur_type  IS  REF CURSOR;
    pickout_cur     cur_type;
--
    TYPE  rec_type  IS  RECORD(
      xir_row_id                    ROWID                                                     -- ROWID
     ,xir_base_code                 xxcoi_inv_result.base_code%TYPE                           -- 拠点コード
     ,biv_base_short_name           hz_cust_accounts.account_name%TYPE                                     -- 拠点名称
     ,msi_secondary_inventory_name  mtl_secondary_inventories.secondary_inventory_name%TYPE   -- 保管場所コード
     ,msi_description               mtl_secondary_inventories.description%TYPE                -- 保管場所名
     ,xir_inventory_date            xxcoi_inv_result.inventory_date%TYPE                      -- 棚卸日
     ,xir_slip_no                   xxcoi_inv_result.slip_no%TYPE                             -- 伝票№
     ,xir_item_code                 xxcoi_inv_result.item_code%TYPE                           -- 品目コード
     ,imb_item_short_name           xxcmn_item_mst_b.item_short_name%TYPE                     -- 商品名称
     ,xir_case_in_qty               xxcoi_inv_result.case_in_qty%TYPE                         -- 入数
     ,xir_case_qty                  xxcoi_inv_result.case_qty%TYPE                            -- ケース数
     ,xir_quantity                  xxcoi_inv_result.quantity%TYPE                            -- 本数
     ,xir_quality_goods_kbn         xxcoi_inv_result.quality_goods_kbn%TYPE                   -- 良品区分
     ,xir_input_order               NUMBER                                                    -- 取込順
    );
    pickout_rec     rec_type;
    --
    TYPE acct_num_type    IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER;
    lt_f_account_number   acct_num_type;      -- 処理対象拠点
    TYPE short_name_type  IS TABLE OF hz_cust_accounts.account_name%TYPE INDEX BY BINARY_INTEGER;
    lt_f_short_name       short_name_type;
--
-- == 2009/09/15 V1.9 Modified END   ===============================================================
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
-- == 2009/09/15 V1.9 Modified START ===============================================================
  --拠点コード設定
  lv_base_code  := NVL(iv_base_code, gv_user_basecode);
  --百貨店判別SQL
  BEGIN
    SELECT   xca.management_base_code       management_base_code
            ,NVL(xca.dept_hht_div, '2')     dept_hht_div
            ,SUBSTRB(hca.account_name,1,8)  base_short_name
    INTO     lt_f_account_number(1)
            ,lv_dept_hht_div
            ,lt_f_short_name(1)
    FROM     xxcmm_cust_accounts         xca
            ,hz_cust_accounts            hca
    WHERE    xca.customer_id         =   hca.cust_account_id
    AND      hca.account_number      =   lv_base_code
    AND      hca.customer_class_code =   '1'
    AND      hca.status              =   'A'
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lt_f_account_number.DELETE;
      lt_f_short_name.DELETE;
      lv_dept_hht_div := NULL;
  END;
  --
  IF (lv_dept_hht_div = '2') THEN
    -- 百貨店以外の場合、管轄拠点の取得を行なう。
    ln_cnt  :=  0;
    <<set_base_loop>>
    FOR acct_num_rec  IN  acct_num_cur LOOP
      -- パラメータ拠点が管理元拠点の場合、管理下の拠点全てを対象とする
      ln_cnt  :=  ln_cnt + 1;
      lt_f_account_number(ln_cnt)  :=  acct_num_rec.account_number;
      lt_f_short_name(ln_cnt)      :=  acct_num_rec.base_short_name;
    END LOOP set_base_loop;
    --
    IF (ln_cnt = 0) THEN
      -- 拠点が取得できない場合、管理元拠点ではないため入力or所属拠点が対象
      lt_f_account_number(1)  :=  lv_base_code;
      -- 名称は百貨店フラグ取得SQLにて取得した名称をそのまま使用
    END IF;
  END IF;
--
  lv_sql_str  :=  NULL;
  -- SQL設定
  lv_sql_str  :=    'SELECT '
                ||  'xir.ROWID  xir_row_id '
                ||  ',xir.base_code  xir_base_code '
                ||  ',:var1  biv_base_short_name '
                ||  ',msi.secondary_inventory_name  msi_secondary_inventory_name '
                ||  ',msi.description  msi_description '
                ||  ',xir.inventory_date  xir_inventory_date '
                ||  ',xir.slip_no  xir_slip_no '
                ||  ',xir.item_code  xir_item_code '
                ||  ',imb.item_short_name  imb_item_short_name '
                ||  ',xir.case_in_qty  xir_case_in_qty '
                ||  ',xir.case_qty  xir_case_qty '
                ||  ',xir.quantity  xir_quantity '
                ||  ',xir.quality_goods_kbn  xir_quality_goods_kbn '
-- == 2010/04/30 V1.10 Modified START ===============================================================
--                ||  ',ROW_NUMBER() OVER '
--                ||  '(PARTITION BY xir.base_code, msi.secondary_inventory_name '
--                ||  'ORDER BY  xir.creation_date, xir.input_order '
--                ||  ') xir_input_order ';
                ||  ',xir.input_order  xir_input_order ';
-- == 2010/04/30 V1.10 Modified END   ===============================================================
  -- FROM句
  lv_sql_str  :=    lv_sql_str
                ||  'FROM '
                ||  'xxcoi_inv_result  xir '
                ||  ',xxcoi_inv_control  xic '
                ||  ',mtl_secondary_inventories  msi '
                ||  ',xxcmn_item_mst_b  imb '
                ||  ',ic_item_mst_b  iib ';
  -- WHERE句
  lv_sql_str  :=    lv_sql_str
                ||  'WHERE  xir.inventory_kbn  = :var2 ';
  IF (iv_inventory_kbn = '1') THEN
    --月中の場合
    lv_sql_str  :=    lv_sql_str
                  ||  'AND  xir.inventory_date = TRUNC(:var_n1) ';
  ELSIF (iv_inventory_kbn = '2') THEN
    --月末の場合
    lv_sql_str  :=    lv_sql_str
                  ||  'AND  xir.inventory_date >= TRUNC(TO_DATE(:var_m1, :var_m2)) '
                  ||  'AND  xir.inventory_date <  TRUNC(LAST_DAY(TO_DATE(:var_m3, :var_m4)) + 1) ';
  END IF;
  lv_sql_str  :=    lv_sql_str
                ||  'AND  xir.base_code  = :var_sh1 '
                ||  'AND  msi.organization_id  = :var3 '
                ||  'AND  xic.inventory_seq  = xir.inventory_seq '
                ||  'AND  xic.subinventory_code = NVL(:var4, xic.subinventory_code) '
                ||  'AND  msi.secondary_inventory_name = xic.subinventory_code '
                ||  'AND  msi.attribute1  <> :var5 '
                ||  'AND  msi.attribute1  <> :var6 ';
  IF (lv_dept_hht_div = '1') THEN
    --百貨店の場合
    IF (lt_f_account_number(1) <> lv_base_code) THEN
      --パラメータで指定された拠点が管理元拠点ではない場合
      lv_sql_str  :=    lv_sql_str
                    ||  'AND msi.attribute7  = :var_h_m1 ';
    END IF;
  ELSIF (lv_dept_hht_div = '2') THEN
    --一般、専門店の場合
    lv_sql_str  :=    lv_sql_str
                  ||  'AND  msi.attribute7  = :var_s2 ';
  END IF;
  lv_sql_str  :=    lv_sql_str
                ||  'AND  TRUNC(NVL(msi.disable_date, :var7)) >= TRUNC(:var8) '
                ||  'AND  iib.item_no  = xir.item_code '
                ||  'AND  iib.item_id  = imb.item_id '
                ||  'AND  xir.inventory_date  BETWEEN imb.start_date_active '
                ||  'AND  NVL(imb.end_date_active, xir.inventory_date) '
                ||  'AND  xir.process_flag  = DECODE(:var9, :var10, :var11, :var12) '
                ||  'FOR UPDATE OF xir.process_flag NOWAIT ';
  -- ORDER BY句
  lv_sql_str  :=    lv_sql_str
                ||  'ORDER BY '
                ||  'xir.base_code '
                ||  ',msi.secondary_inventory_name '
                ||  ',xir.slip_no '
                ||  ',xir.input_order ';
--
  IF (lv_dept_hht_div IS NOT NULL) THEN
    --百貨店HHT区分が取得できない(顧客なし)の場合は以下の処理を実施しない
    <<main_loop>>   -- メインLOOP
    FOR ln_main_cnt IN  1 .. lt_f_account_number.LAST LOOP
--  -- カーソルオープン
---- == 2009/03/23 V1.4 Modified START ===============================================================
----  OPEN pickout_cur;
--  OPEN pickout_cur(NVL(iv_base_code, gv_user_basecode));
---- == 2009/03/23 V1.4 Modified END   ===============================================================
      -- カーソルOPEN
      IF   ((lv_dept_hht_div = '1')
        AND (iv_inventory_kbn = '1')
        AND (lt_f_account_number(1) <> lv_base_code))
      THEN
        -- 拠点が百貨店、棚卸区分が月中、パラメータが管理課ではない
        OPEN  pickout_cur FOR lv_sql_str USING IN lt_f_short_name(1)      -- var1.百貨店管理課(名称)
                                                 ,iv_inventory_kbn        -- var2.棚卸区分
                                                 ,id_practice_date        -- var_n1.年月日
                                                 ,lt_f_account_number(1)  -- var_sh1.管理元拠点
                                                 ,gn_organization_id      -- var3.在庫組織ID
                                                 ,iv_inventory_place      -- var4.棚卸場所
                                                 ,'5'                     -- var5.保管場所区分(自販機)
                                                 ,'8'                     -- var6.保管場所区分(直送)
                                                 ,lv_base_code            -- vhm1.パラメータ拠点コード
                                                 ,gd_target_date          -- var7.対象日
                                                 ,gd_target_date          -- var8.対象日
                                                 ,iv_output_kbn           -- var9.出力区分
                                                 ,'1'                     -- var10.出力済み(チェック)
                                                 ,'Y'                     -- var11.出力済み(フラグ)
                                                 ,'N';                    -- var12.未出力(フラグ)
      ELSIF ((lv_dept_hht_div = '1')
        AND  (iv_inventory_kbn = '2')
        AND  (lt_f_account_number(1) <> lv_base_code))
      THEN
        -- 拠点が百貨店、棚卸区分が月末、パラメータが管理課ではない
        OPEN  pickout_cur FOR lv_sql_str USING IN lt_f_short_name(1)      -- var1.百貨店管理課(名称)
                                                 ,iv_inventory_kbn        -- var2.棚卸区分
                                                 ,iv_practice_month       -- var_m1.年月
                                                 ,'YYYYMM'                -- var_m2.年月日型
                                                 ,iv_practice_month       -- var_m3.年月
                                                 ,'YYYYMM'                -- var_m4.年月日型
                                                 ,lt_f_account_number(1)  -- var_sh1.管理元拠点
                                                 ,gn_organization_id      -- var3.在庫組織ID
                                                 ,iv_inventory_place      -- var4.棚卸場所
                                                 ,'5'                     -- var5.保管場所区分(自販機)
                                                 ,'8'                     -- var6.保管場所区分(直送)
                                                 ,lv_base_code            -- var_h_m1.パラメータ拠点コード
                                                 ,gd_target_date          -- var7.対象日
                                                 ,gd_target_date          -- var8.対象日
                                                 ,iv_output_kbn           -- var9.出力区分
                                                 ,'1'                     -- var10.出力済み(チェック)
                                                 ,'Y'                     -- var11.出力済み(フラグ)
                                                 ,'N';                    -- var12.未出力(フラグ)
      ELSIF ((lv_dept_hht_div = '1')
        AND (iv_inventory_kbn = '1')
        AND (lt_f_account_number(1) = lv_base_code))
      THEN
        -- 拠点が百貨店、棚卸区分が月中、パラメータが管理課
        OPEN  pickout_cur FOR lv_sql_str USING IN lt_f_short_name(1)      -- var1.百貨店管理課(名称)
                                                 ,iv_inventory_kbn        -- var2.棚卸区分
                                                 ,id_practice_date        -- var_n1.年月日
                                                 ,lt_f_account_number(1)  -- var_sh1.管理元拠点
                                                 ,gn_organization_id      -- var3.在庫組織ID
                                                 ,iv_inventory_place      -- var4.棚卸場所
                                                 ,'5'                     -- var5.保管場所区分(自販機)
                                                 ,'8'                     -- var6.保管場所区分(直送)
                                                 ,gd_target_date          -- var7.対象日
                                                 ,gd_target_date          -- var8.対象日
                                                 ,iv_output_kbn           -- var9.出力区分
                                                 ,'1'                     -- var10.出力済み(チェック)
                                                 ,'Y'                     -- var11.出力済み(フラグ)
                                                 ,'N';                    -- var12.未出力(フラグ)
      ELSIF ((lv_dept_hht_div = '1')
        AND  (iv_inventory_kbn = '2')
        AND  (lt_f_account_number(1) = lv_base_code))
      THEN
        -- 拠点が百貨店、棚卸区分が月末、パラメータが管理課
        OPEN  pickout_cur FOR lv_sql_str USING IN lt_f_short_name(1)      -- var1.百貨店管理課(名称)
                                                 ,iv_inventory_kbn        -- var2.棚卸区分
                                                 ,iv_practice_month       -- var_m1.年月
                                                 ,'YYYYMM'                -- var_m2.年月日型
                                                 ,iv_practice_month       -- var_m3.年月
                                                 ,'YYYYMM'                -- var_m4.年月日型
                                                 ,lt_f_account_number(1)  -- var_sh1.管理元拠点
                                                 ,gn_organization_id      -- var3.在庫組織ID
                                                 ,iv_inventory_place      -- var4.棚卸場所
                                                 ,'5'                     -- var5.保管場所区分(自販機)
                                                 ,'8'                     -- var6.保管場所区分(直送)
                                                 ,gd_target_date          -- var7.対象日
                                                 ,gd_target_date          -- var8.対象日
                                                 ,iv_output_kbn           -- var9.出力区分
                                                 ,'1'                     -- var10.出力済み(チェック)
                                                 ,'Y'                     -- var11.出力済み(フラグ)
                                                 ,'N';                    -- var12.未出力(フラグ)
      ELSIF ((lv_dept_hht_div = '2')
        AND  (iv_inventory_kbn = '1'))
      THEN
        -- 拠点が一般・専門店、棚卸区分が月中
        OPEN  pickout_cur FOR lv_sql_str USING IN lt_f_short_name(ln_main_cnt)      -- var1.管轄拠点
                                                 ,iv_inventory_kbn                  -- var2.棚卸区分
                                                 ,id_practice_date                  -- var_n1.年月日
                                                 ,lt_f_account_number(ln_main_cnt)  -- var_sh1.拠点コード
                                                 ,gn_organization_id                -- var3.在庫組織ID
                                                 ,iv_inventory_place                -- var4.棚卸場所
                                                 ,'5'                               -- var5.保管場所区分(自販機)
                                                 ,'8'                               -- var6.保管場所区分(直送)
                                                 ,lt_f_account_number(ln_main_cnt)  -- var_s2.拠点コード
                                                 ,gd_target_date                    -- var7.対象日
                                                 ,gd_target_date                    -- var8.対象日
                                                 ,iv_output_kbn                     -- var9.出力区分
                                                 ,'1'                               -- var10.出力済み(チェック)
                                                 ,'Y'                               -- var11.出力済み(フラグ)
                                                 ,'N';                              -- var12.未出力(フラグ)
      ELSIF ((lv_dept_hht_div = '2')
        AND  (iv_inventory_kbn = '2'))
      THEN
        -- 拠点が一般・専門店、棚卸区分が月末
        OPEN  pickout_cur FOR lv_sql_str USING IN lt_f_short_name(ln_main_cnt)      -- var1.管轄拠点
                                                 ,iv_inventory_kbn                  -- var2.棚卸区分
                                                 ,iv_practice_month                 -- var_m1.年月
                                                 ,'YYYYMM'                          -- var_m2.年月日型
                                                 ,iv_practice_month                 -- var_m3.年月
                                                 ,'YYYYMM'                          -- var_m4.年月日型
                                                 ,lt_f_account_number(ln_main_cnt)  -- var_sh1.拠点コード
                                                 ,gn_organization_id                -- var3.在庫組織ID
                                                 ,iv_inventory_place                -- var4.棚卸場所
                                                 ,'5'                               -- var5.保管場所区分(自販機)
                                                 ,'8'                               -- var6.保管場所区分(直送)
                                                 ,lt_f_account_number(ln_main_cnt)  -- var_s2.拠点コード
                                                 ,gd_target_date                    -- var7.対象日
                                                 ,gd_target_date                    -- var8.対象日
                                                 ,iv_output_kbn                     -- var9.出力区分
                                                 ,'1'                               -- var10.出力済み(チェック)
                                                 ,'Y'                               -- var11.出力済み(フラグ)
                                                 ,'N';                              -- var12.未出力(フラグ)
      END IF;
-- == 2009/09/15 V1.9 Modified END   ===============================================================
      LOOP
        FETCH pickout_cur INTO pickout_rec;
        EXIT WHEN pickout_cur%NOTFOUND;
        -- チェックリストIDをカウント
        ln_check_num  := ln_check_num  + 1;
        -- 対象件数をカウント
        gn_target_cnt := gn_target_cnt + 1;
        -- A-3.ワークテーブルデータ登録
        INSERT INTO xxcoi_rep_inv_checklist(
                check_list_id
               ,check_year
               ,check_month
               ,inventory_kbn
    -- == 2009/07/14 V1.6 Added START ===============================================================
               ,input_order
    -- == 2009/07/14 V1.6 Added END   ===============================================================
               ,base_code
               ,base_name
               ,subinventory_code
               ,subinventory_name
               ,inventory_date
               ,inventory_slipno
               ,item_code
               ,item_name
               ,case_in_qty
               ,case_qty
               ,singly_qty
               ,inventory_qty
               ,quality_goods_kbn
               ,last_update_date
               ,last_updated_by
               ,creation_date
               ,created_by
               ,last_update_login
               ,request_id
               ,program_application_id
               ,program_id
               ,program_update_date
               ,message)
        VALUES (ln_check_num                                              -- チェックリストID
               ,TO_CHAR(pickout_rec.xir_inventory_date,'YYYY')            -- 年
               ,TO_CHAR(pickout_rec.xir_inventory_date,'MM')              -- 月
               ,cv_inv_kbn                                                -- 棚卸区分
    -- == 2009/07/14 V1.6 Added START ===============================================================
               ,pickout_rec.xir_input_order
    -- == 2009/07/14 V1.6 Added END   ===============================================================
               ,pickout_rec.xir_base_code                                 -- 拠点コード
               ,pickout_rec.biv_base_short_name                           -- 拠点名(略称)
               ,pickout_rec.msi_secondary_inventory_name                  -- 保管場所コード
               ,pickout_rec.msi_description                               -- 保管場所名
               ,pickout_rec.xir_inventory_date                            -- 棚卸日
               ,pickout_rec.xir_slip_no                                   -- 棚卸伝票No
               ,pickout_rec.xir_item_code                                 -- 品目コード
               ,pickout_rec.imb_item_short_name                           -- 品名
               ,pickout_rec.xir_case_in_qty                               -- 入数
               ,pickout_rec.xir_case_qty                                  -- ケース数
               ,pickout_rec.xir_quantity                                  -- バラ数
               ,pickout_rec.xir_case_in_qty * pickout_rec.xir_case_qty
                                            + pickout_rec.xir_quantity    -- 棚卸数
               ,DECODE(pickout_rec.xir_quality_goods_kbn,cv_goods_kbn
                                                        ,gt_goods_name,NULL)
                                                                          -- 良品区分
               ,SYSDATE                                                   -- 最終更新日
               ,cn_last_updated_by                                        -- 最終更新者
               ,SYSDATE                                                   -- 作成日
               ,cn_created_by                                             -- 作成者
               ,cn_last_update_login                                      -- 最終更新ユーザ
               ,cn_request_id                                             -- 要求ID
               ,cn_program_application_id                                 -- プログラムアプリケーションID
               ,cn_program_id                                             -- プログラムID
               ,SYSDATE                                                   -- プログラム更新日
               ,NULL);                                                    -- メッセージ
        -- A-4.処理済フラグ更新
        IF (iv_output_kbn = cv_output_kbn) THEN
          BEGIN
            UPDATE xxcoi_inv_result
            SET    process_flag           = 'Y'                           -- 処理済フラグ
                  ,last_update_date       = SYSDATE                       -- 最終更新日
                  ,last_updated_by        = cn_last_updated_by            -- 最終更新者
                  ,last_update_login      = cn_last_update_login          -- 最終更新ユーザ
                  ,request_id             = cn_request_id                 -- 要求ID
                  ,program_application_id = cn_program_application_id     -- プログラムアプリケーションID
                  ,program_id             = cn_program_id                 -- プログラムID
                  ,program_update_date    = SYSDATE                       -- プログラム更新日
            WHERE  ROWID                  = pickout_rec.xir_row_id;
          -- 更新例外処理
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcoi_sn
                          ,iv_name        => cv_msg_10091
                          );
              lv_errbuf := lv_errmsg;
              lv_retcode := cv_status_error;    -- 異常:2
              gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END;
        END IF;
      --
      END LOOP;
      CLOSE pickout_cur;
-- == 2009/09/15 V1.9 Added START ===============================================================
    END LOOP main_loop;
  END IF;
-- == 2009/09/15 V1.9 Added END   ===============================================================
  -- 結果0件の場合
  IF (ln_check_num = 0) THEN
    -- 拠点名取得
    IF (iv_base_code IS NOT NULL) THEN
      BEGIN
-- == 2009/08/07 V1.7 Modified START ===============================================================
--        SELECT base_short_name
--        INTO   lv_base_name
--        FROM   xxcoi_base_info2_v       -- 拠点情報ビュー
--        WHERE  base_code       = iv_base_code
--        AND    focus_base_code = gv_user_basecode;
        SELECT SUBSTRB(hca.account_name, 1, 8)
        INTO   lv_base_name
        FROM   hz_cust_accounts    hca
        WHERE  hca.account_number       =  iv_base_code
        AND    hca.status               =  'A'
        AND    hca.customer_class_code  =  '1'
        ;
-- == 2009/08/07 V1.7 Modified END   ===============================================================
      EXCEPTION
        WHEN OTHERS THEN
          lv_base_name := NULL;
      END;
    END IF;
    -- 保管場所名取得
    IF (iv_inventory_place IS NOT NULL) THEN
      BEGIN
        SELECT description
        INTO   lv_inv_name
        FROM   mtl_secondary_inventories
        WHERE  organization_id          = gn_organization_id
        AND    secondary_inventory_name = iv_inventory_place
        AND    TRUNC(NVL(disable_date,gd_target_date))
                                       >= TRUNC(gd_target_date)
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          lv_inv_name := NULL;
      END;
    END IF;
    -- 結果0件メッセージ取得
    lv_message := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_sn
                      ,iv_name         => cv_msg_00008
                     );
    -- 結果0件メッセージ出力
    INSERT INTO xxcoi_rep_inv_checklist(
                check_list_id
               ,check_year
               ,check_month
               ,inventory_kbn
               ,base_code
               ,base_name
               ,subinventory_code
               ,subinventory_name
               ,last_update_date
               ,last_updated_by
               ,creation_date
               ,created_by
               ,last_update_login
               ,request_id
               ,program_application_id
               ,program_id
               ,program_update_date
               ,message)
    VALUES     (ln_check_num                                          -- チェックリストID
               ,TO_CHAR(gd_target_date,'YYYY')                        -- 年
               ,TO_CHAR(gd_target_date,'MM')                          -- 月
               ,cv_inv_kbn                                            -- 棚卸区分
               ,iv_base_code                                          -- 拠点コード
               ,lv_base_name                                          -- 拠点名(略称)
               ,iv_inventory_place                                    -- 保管場所コード
               ,lv_inv_name                                           -- 保管場所名
               ,SYSDATE                                               -- 最終更新日
               ,cn_last_updated_by                                    -- 最終更新者
               ,SYSDATE                                               -- 作成日
               ,cn_created_by                                         -- 作成者
               ,cn_last_update_login                                  -- 最終更新ユーザ
               ,cn_request_id                                         -- 要求ID
               ,cn_program_application_id                             -- プログラムアプリケーションID
               ,cn_program_id                                         -- プログラムID
               ,SYSDATE                                               -- プログラム更新日
               ,lv_message);                                          -- メッセージ
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
    iv_inventory_kbn      IN  VARCHAR2,    -- 棚卸区分
    iv_practice_date      IN  VARCHAR2,    -- 年月日
    iv_practice_month     IN  VARCHAR2,    -- 年月
    iv_base_code          IN  VARCHAR2,    -- 拠点
    iv_inventory_place    IN  VARCHAR2,    -- 棚卸場所
    iv_output_kbn         IN  VARCHAR2,    -- 出力区分
    ov_practice_date      OUT DATE,        -- 年月日(DATE)
    ov_practice_month     OUT DATE,        -- 年月  (DATE)
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- == 2009/09/15 V1.9 Deleted START ===============================================================
--    ov_practice_date  := TO_DATE(iv_practice_date,'YYYYMMDD');
--    ov_practice_month := TO_DATE(iv_practice_month,'YYYYMM');
-- == 2009/09/15 V1.9 Deleted END   ===============================================================
    -- 棚卸区分内容を取得
    cv_inv_kbn := xxcoi_common_pkg.get_meaning(cv_xxcoi_inv_kbn,iv_inventory_kbn);
-- == 2009/09/15 V1.9 Added START ===============================================================
    -- A-1-5.共通関数(業務処理日付取得)より業務日付を取得します。
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
--
    -- 年月チェック
    IF (iv_inventory_kbn = cv_inv_kbn2) THEN
      -- NULLチェック
      IF (iv_practice_month IS NULL) THEN
        -- 年月Nullチェックエラーメッセージ(APP-XXCOI1-10103)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10404
                     ,iv_token_name1  => cv_p_token1   -- 棚卸区分
                     ,iv_token_value1 => cv_inv_kbn
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      ov_practice_month := TO_DATE(iv_practice_month,'YYYYMM');
    -- 年月日チェック
    ELSE
      -- NULLチェック
      IF (iv_practice_date IS NULL) THEN
        -- 年月日Nullチェックエラーメッセージ(APP-XXCOI1-10102)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10403
                     ,iv_token_name1  => cv_p_token1   -- 棚卸区分
                     ,iv_token_value1 => cv_inv_kbn
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      ov_practice_date  := TO_DATE(iv_practice_date,'YYYYMMDD');
    END IF;
-- == 2009/09/15 V1.9 Added END   ===============================================================
    -- A-1-1.コンカレント入力パラメータをログに出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_sn
                    ,iv_name         => cv_msg_10093
                    ,iv_token_name1  => cv_p_token1   -- 棚卸区分
                    ,iv_token_value1 => cv_inv_kbn
                    ,iv_token_name2  => cv_p_token2   -- 年月日
                    ,iv_token_value2 => TO_CHAR(ov_practice_date,'YYYY/MM/DD')
                    ,iv_token_name3  => cv_p_token3   -- 年月
                    ,iv_token_value3 => TO_CHAR(ov_practice_month,'YYYY/MM')
                    ,iv_token_name4  => cv_p_token4   -- 拠点
                    ,iv_token_value4 => iv_base_code
                    ,iv_token_name5  => cv_p_token5   -- 棚卸場所
                    ,iv_token_value5 => iv_inventory_place
                    ,iv_token_name6  => cv_p_token6   -- 出力区分
                    ,iv_token_value6 => xxcoi_common_pkg.get_meaning(cv_xxcoi_inv_out,iv_output_kbn)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- == 2009/09/15 V1.9 Deleted START ===============================================================
--    -- A-1-5.共通関数(業務処理日付取得)より業務日付を取得します。
--    gd_business_date := xxccp_common_pkg2.get_process_date;
--    --
--    IF (gd_business_date IS NULL) THEN
--      -- 業務日付の取得に失敗しました。
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcoi_sn
--                   ,iv_name         => cv_msg_00011
--                   );
--      lv_errbuf := lv_errmsg;
--      lv_retcode := cv_status_error;    -- 異常:2
--      gn_error_cnt := gn_error_cnt + 1;
--      RAISE global_process_expt;
--    END IF;
-- == 2009/09/15 V1.9 Deleted END   ===============================================================
    -- A-1-6.対象日を算出します。
    IF (iv_inventory_kbn = cv_inv_kbn1) THEN      -- 月中
      IF (ov_practice_date > gd_business_date) THEN
        gd_target_date := gd_business_date;
      ELSE
        gd_target_date := ov_practice_date;
      END IF;
    ELSIF (iv_inventory_kbn = cv_inv_kbn2) THEN   -- 月末
      IF (LAST_DAY(ov_practice_month) > gd_business_date) THEN
        gd_target_date := gd_business_date;
      ELSE
        gd_target_date := LAST_DAY(ov_practice_month);
      END IF;
    END IF;
    -- A-1-3.共通関数(在庫組織コード取得)を使用しプロファイルより在庫組織コードを取得します。
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
    -- A-1-4.上記3.で取得した在庫組織コードをもとに共通部品(在庫組織ID取得)より在庫組織ID取得します。
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
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
    -- A-2-1.所属拠点の取得
    gv_user_basecode := xxcoi_common_pkg.get_base_code(cn_created_by,gd_target_date);
    IF (gv_user_basecode IS NULL) THEN
      -- ユーザーの所属拠点データが取得できませんでした。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10092
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    --不良品名称の取得
    gt_goods_name  :=  xxcoi_common_pkg.get_meaning(
                      cv_qual_good_dv
                     ,cv_not_qual_goods
                   );
    IF (gt_goods_name IS NULL) THEN
      --良品区分名称取得失敗
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10362
                   );
      lv_errbuf := lv_errmsg;
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_inventory_kbn      IN  VARCHAR2,     -- 棚卸区分
    iv_practice_date      IN  VARCHAR2,     -- 年月日
    iv_practice_month     IN  VARCHAR2,     -- 年月
    iv_base_code          IN  VARCHAR2,     -- 拠点
    iv_inventory_place    IN  VARCHAR2,     -- 棚卸場所
    iv_output_kbn         IN  VARCHAR2,     -- 出力区分
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
    ld_practice_date          DATE;     -- 年月日
    ld_practice_month         DATE;     -- 年月
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
      iv_inventory_kbn   => iv_inventory_kbn      -- 棚卸区分
     ,iv_practice_date   => iv_practice_date      -- 年月日
     ,iv_practice_month  => iv_practice_month     -- 年月
     ,iv_base_code       => iv_base_code          -- 拠点
     ,iv_inventory_place => iv_inventory_place    -- 棚卸場所
     ,iv_output_kbn      => iv_output_kbn         -- 出力区分
     ,ov_practice_date   => ld_practice_date      -- 年月日(DATE)
     ,ov_practice_month  => ld_practice_month     -- 年月  (DATE)
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
      iv_inventory_kbn   => iv_inventory_kbn                     -- 棚卸区分
     ,id_practice_date   => ld_practice_date                     -- 年月日
     ,iv_practice_month  => TO_CHAR(ld_practice_month,'YYYYMM')  -- 年月
     ,iv_base_code       => iv_base_code                         -- 拠点
     ,iv_inventory_place => iv_inventory_place                   -- 棚卸場所
     ,iv_output_kbn      => iv_output_kbn                        -- 出力区分
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
    iv_inventory_kbn      IN  VARCHAR2,           -- 棚卸区分
    iv_practice_date      IN  VARCHAR2,           -- 年月日
    iv_practice_month     IN  VARCHAR2,           -- 年月
    iv_base_code          IN  VARCHAR2,           -- 拠点
    iv_inventory_place    IN  VARCHAR2,           -- 棚卸場所
    iv_output_kbn         IN  VARCHAR2            -- 出力区分
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
       iv_inventory_kbn   => iv_inventory_kbn     -- 棚卸区分
      ,iv_practice_date   => iv_practice_date     -- 年月日
      ,iv_practice_month  => iv_practice_month    -- 年月
      ,iv_base_code       => iv_base_code         -- 拠点
      ,iv_inventory_place => iv_inventory_place   -- 棚卸場所
      ,iv_output_kbn      => iv_output_kbn        -- 出力区分
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
END XXCOI006A08R;
/
