CREATE OR REPLACE PACKAGE BODY XXCMN800015C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800015C(body)
 * Description      : ロット情報をCSVファイル出力し、ワークフロー形式で連携します。
 * MD.050           : ロット情報インタフェース<T_MD050_BPO_801>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                              (B-1)
 *  output_data            データ取得・CSV出力処理               (B-2)
 *  submain                メイン処理プロシージャ
 *                         終了処理                              (B-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/08/19    1.0   K.Kiriu          新規作成
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
  cv_msg_sla                CONSTANT VARCHAR2(3) := '／';
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCMN800015C';            -- パッケージ名
  -- システム日付
  cd_sysdate                  CONSTANT DATE          := SYSDATE;                   -- システム日付
  -- プロファイル
  cv_prof_unit_div            CONSTANT VARCHAR2(22)  := 'XXCMN_800015C_UNIT_DIV';  -- XXCMN:ロット情報インタフェース単位区分
  cv_prof_ntf_code            CONSTANT VARCHAR2(22)  := 'XXCMN_800015C_NTF_CODE';  -- XXCMN:ロット情報インタフェース宛先
  -- メッセージ関連
  cv_app_xxcmn                CONSTANT VARCHAR2(5)   := 'XXCMN';                   -- アプリケーション短縮名(生産:マスタ)
  cv_msg_xxcmn_10002          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-10002';         -- プロファイル取得エラー
  cv_msg_xxcmn_11048          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11048';         -- 対象データ未取得エラー
  cv_msg_xxcmn_11049          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11049';         -- ロット情報インタフェースパラメータ
  cv_msg_xxcmn_11050          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11050';         -- 取得エラー
  cv_msg_xxcmn_11053          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11053';         -- 在庫照会画面データソースパッケージエラー
  -- トークン用メッセージ
  cv_msg_xxcmn_11051          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11051';         -- OPM保管場所情報VIEW
  cv_msg_xxcmn_11052          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11052';         -- OPM品目マスタ
  cv_msg_xxcmn_11054          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11054';         -- OPM品目情報VIEW
  cv_msg_xxcmn_11056          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11056';         -- OPMロットマスタ
  --トークン
  cv_tkn_item_no              CONSTANT VARCHAR2(9)   := 'ITEM_CODE';               -- 入力パラメータ（品目コード）
  cv_tkn_item_div             CONSTANT VARCHAR2(8)   := 'ITEM_DIV';                -- 入力パラメータ（品目区分）
  cv_tkn_lot_no               CONSTANT VARCHAR2(8)   := 'LOT_NO';                  -- 入力パラメータ（ロットNo）
  cv_tkn_subinv_code          CONSTANT VARCHAR2(11)  := 'SUBINV_CODE';             -- 入力パラメータ（倉庫コード）
  cv_tkn_effective_date       CONSTANT VARCHAR2(14)  := 'EFFECTIVE_DATE';          -- 入力パラメータ（有効日）
  cv_tkn_prod_div             CONSTANT VARCHAR2(8)   := 'PROD_DIV';                -- 入力パラメータ（商品区分）
  cv_tkn_ng_profile           CONSTANT VARCHAR2(10)  := 'NG_PROFILE';              -- プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(5)   := 'TABLE';                   -- テーブル名
  cv_tkn_errmsg               CONSTANT VARCHAR2(6)   := 'ERRMSG';                  -- SQLエラー
  cv_tkn_item_id              CONSTANT VARCHAR2(7)   := 'ITEM_ID';                 -- 品目ID
  cv_tkn_location_id          CONSTANT VARCHAR2(11)  := 'LOCATION_ID';             -- 倉庫ID
  cv_tkn_cust_stock_whse      CONSTANT VARCHAR2(15)  := 'CUST_STOCK_WHSE';         -- 相手先在庫管理対象
  --フォーマット
  cv_fmt_date                 CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';
  cv_fmt_datetime             CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_datetime2            CONSTANT VARCHAR2(30)  := 'YYYYMMDDHH24MISS';
  -- WF関連
  cv_ope_div                  CONSTANT VARCHAR2(2)   := '11';                      -- 処理区分:11(ロット情報)
  cv_wf_class                 CONSTANT VARCHAR2(1)   := '6';                       -- 対象:6(職責)
  -- 出力項目
  cv_coop_name_itoen          CONSTANT VARCHAR2(5)   := 'ITOEN';                   -- 会社名:ITOEN
  cv_data_type                CONSTANT VARCHAR2(3)   := '900';                     -- データ種別:900(ロット情報)
  cv_branch_no                CONSTANT VARCHAR2(2)   := '97';                      -- 伝送用枝番:97(ロット情報)
  -- ファイル操作
  cv_file_mode                CONSTANT VARCHAR2(1)   := 'w';                       -- モード(上書)
  -- 品目区分
  cv_material_g               CONSTANT VARCHAR2(1)   := '1';                       -- 原料
  cv_semi_f_item              CONSTANT VARCHAR2(1)   := '4';                       -- 半製品
  cv_item                     CONSTANT VARCHAR2(1)   := '5';                       -- 製品
  -- その他
  cv_y                        CONSTANT VARCHAR2(1)   := 'Y';                       -- フラグ:'Y'
  cv_n                        CONSTANT VARCHAR2(1)   := 'N';                       -- フラグ:'N'
  cv_separate_code            CONSTANT VARCHAR2(1)   := ',';                       -- 区切り文字（カンマ）
  cv_extension                CONSTANT VARCHAR2(1)   := '.';                       -- 区切り文字（ファイル拡張子)
  cv_space                    CONSTANT VARCHAR2(1)   := ' ';                       -- 区切り文字（スペース)
  cv_underscore               CONSTANT VARCHAR2(1)   := '_';                       -- 区切り文字（アンダースコア)
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル格納用
  gv_unit_div           VARCHAR2(10);                                              -- 単位区分
  gt_ntf_code           fnd_lookup_values.attribute3%TYPE;                         -- 宛先
  -- パラメータ格納用
  gt_item_div           xxcmn_item_categories_v.segment1%TYPE;                     -- 品目区分
  gt_prod_div           xxcmn_item_categories_v.segment1%TYPE;                     -- 商品区分
  gt_lot_no             ic_lots_mst.lot_no%TYPE;                                   -- ロットNo
  gd_effective_date     DATE;                                                      -- 有効日
  -- マスタ取得用
  gt_item_id            ic_item_mst_b.item_id%TYPE;                                -- 品目ID
  gt_location_id        mtl_item_locations.inventory_location_id%TYPE;             -- ロケーションID
  gt_cust_stock_whse    ic_whse_mst.attribute1%TYPE;                               -- 相手先在庫管理対象
--
  -- ===============================
  -- カーソル定義
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (B-1)
   **********************************************************************************/
  PROCEDURE init(
    iv_item_code              IN  VARCHAR2  -- 1.品目コード
   ,iv_item_div               IN  VARCHAR2  -- 2.品目区分
   ,iv_lot_no                 IN  VARCHAR2  -- 3.ロットNo
   ,iv_subinventory_code      IN  VARCHAR2  -- 4.倉庫コード
   ,iv_effective_date         IN  VARCHAR2  -- 5.有効日
   ,iv_prod_div               IN  VARCHAR2  -- 6.商品区分
   ,ov_errbuf                 OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    lv_tkn_msg  VARCHAR2(100);  -- エラー時トークン取得用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    --==================================
    -- パラメータ出力
    --==================================
    lv_errmsg := xxcmn_common_pkg.get_msg(
                   iv_application        => cv_app_xxcmn
                  ,iv_name               => cv_msg_xxcmn_11049
                  ,iv_token_name1        => cv_tkn_item_no
                  ,iv_token_value1       => iv_item_code
                  ,iv_token_name2        => cv_tkn_item_div
                  ,iv_token_value2       => iv_item_div
                  ,iv_token_name3        => cv_tkn_lot_no
                  ,iv_token_value3       => iv_lot_no
                  ,iv_token_name4        => cv_tkn_subinv_code
                  ,iv_token_value4       => iv_subinventory_code
                  ,iv_token_name5        => cv_tkn_effective_date
                  ,iv_token_value5       => iv_effective_date
                  ,iv_token_name6        => cv_tkn_prod_div
                  ,iv_token_value6       => iv_prod_div
                 );
--
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => NULL
    );
--
    --==================================
    -- パラメータ格納
    --==================================
    -- 必須
    gt_item_div       := iv_item_div;
    gt_prod_div       := iv_prod_div;
    gd_effective_date := TO_DATE( iv_effective_date, cv_fmt_date );
    -- 任意
    IF ( iv_lot_no IS NOT NULL ) THEN
      gt_lot_no       := iv_lot_no;
    ELSE
      gt_lot_no       := NULL;
    END IF;
--
    --==================================
    -- プロファイル値取得
    --==================================
    -- XXCMN:ロット情報インタフェース単位区分
    gv_unit_div := FND_PROFILE.VALUE( cv_prof_unit_div );
    -- 取得できない場合
    IF ( gv_unit_div IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_xxcmn
                     ,iv_name         => cv_msg_xxcmn_10002
                     ,iv_token_name1  => cv_tkn_ng_profile
                     ,iv_token_value1 => cv_prof_unit_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCMN:ロット情報インタフェース宛先
    gt_ntf_code := FND_PROFILE.VALUE( cv_prof_ntf_code );
    -- 取得できない場合
    IF ( gt_ntf_code IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_app_xxcmn
                     ,iv_name         => cv_msg_xxcmn_10002
                     ,iv_token_name1  => cv_tkn_ng_profile
                     ,iv_token_value1 => cv_prof_ntf_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 各マスタより情報取得
    --==================================
    -- OPM保管場所情報VIEW
    BEGIN
      SELECT  xilv.inventory_location_id  inventory_location_id  -- 倉庫ID
             ,xilv.customer_stock_whse    customer_stock_whse    -- 相手先在庫管理対象
      INTO    gt_location_id
             ,gt_cust_stock_whse
      FROM    xxcmn_item_locations_v xilv
      WHERE   xilv.segment1 = iv_subinventory_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- トークンの取得(テーブル名)
        lv_tkn_msg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_app_xxcmn
                        ,iv_name         => cv_msg_xxcmn_11051
                      );
        -- メッセージ生成
        lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_app_xxcmn
                       ,iv_name         => cv_msg_xxcmn_11050
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_tkn_msg
                       ,iv_token_name2  => cv_tkn_errmsg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- パラメータ品目コードがNULLではない場合のみ
    IF ( iv_item_code IS NOT NULL ) THEN
      -- OPM品目マスタ
      BEGIN
        SELECT  iim.item_id  item_id  --品目ID
        INTO    gt_item_id
        FROM    ic_item_mst_b iim
        WHERE   iim.item_no = iv_item_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- トークンの取得(テーブル名)
          lv_tkn_msg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_app_xxcmn
                          ,iv_name         => cv_msg_xxcmn_11052
                        );
          -- メッセージ生成
          lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application  => cv_app_xxcmn
                         ,iv_name         => cv_msg_xxcmn_11050
                         ,iv_token_name1  => cv_tkn_table
                         ,iv_token_value1 => lv_tkn_msg
                         ,iv_token_name2  => cv_tkn_errmsg
                         ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    ELSE
      gt_item_id := NULL;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  #######################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : CSV出力処理 (B-2)
   **********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                 OUT VARCHAR2  -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode                OUT VARCHAR2  -- リターン・コード                    --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2  -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    cn_default_lot_id   CONSTANT NUMBER       := 0;      -- デフォルトロットID
    cv_default_lot_no   CONSTANT VARCHAR2(1)  := '0';    -- デフォルトロット時のロットNo
    cv_num_of_0         CONSTANT VARCHAR2(1)  := '0';    -- 入数（入数の値がNULLの場合)
--
    -- *** ローカル変数 ***
    lr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec;     -- ファイル情報格納レコード
    lf_file_hand        UTL_FILE.FILE_TYPE;               -- ファイル・ハンドル
    lv_save_file_name   VARCHAR2(150);                    -- ファイル名(通知後保持用)
    lv_csv_data         VARCHAR2(1000);                   -- CSV文字列
    lt_item_no_before   ic_item_mst_b.item_no%TYPE;       -- 品目コード(ブレーク判定用)
    lt_item_um          ic_item_mst_b.item_um%TYPE;       -- 単位名称
    lt_frequent_qty     ic_item_mst_b.attribute17%TYPE;   -- 代表入数
    lv_tkn_msg          VARCHAR2(100);                    -- エラー時トークン取得用
    lt_lot_no           ic_lots_mst.lot_no%TYPE;          -- ロットNo
    lt_num_of_lot       ic_lots_mst.attribute6%TYPE;      -- ロットマスタ在庫入数
    lt_num_of_item      ic_item_mst_b.attribute11%TYPE;   -- 品目マスタケース入数
    lv_num_of_case      VARCHAR2(240);                    -- 入数（CSV設定用）
--
    -- *** ローカルテーブル型 ***
    l_ilm_block_tab     xxinv540001.tbl_ilm_block;        --結果格納用配列
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    lv_csv_data        := NULL;
--
    --==================================
    -- ワークフロー情報の取得
    --==================================
    -- 共通関数「アウトバウンド処理取得関数」呼出
    xxwsh_common3_pkg.get_wsh_wf_info(
      iv_wf_ope_div       => cv_ope_div     -- 処理区分
     ,iv_wf_class         => cv_wf_class    -- 対象
     ,iv_wf_notification  => gt_ntf_code    -- 宛先
     ,or_wf_whs_rec       => lr_wf_whs_rec  -- ファイル情報
     ,ov_errbuf           => lv_errbuf      -- エラー・メッセージ
     ,ov_retcode          => lv_retcode     -- リターン・コード
     ,ov_errmsg           => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- WFオーナーを起動ユーザへ変更
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    -- ファイル名を変更する( ファイル名_YYYYMMDDHH24MISS.csv)
    lv_save_file_name := SUBSTRB( lr_wf_whs_rec.file_name, 1, INSTRB( lr_wf_whs_rec.file_name, cv_extension ) -1 ) ||
                         cv_underscore                                                                             ||
                         TO_CHAR( cd_sysdate, cv_fmt_datetime2 )                                                   ||
                         SUBSTRB( lr_wf_whs_rec.file_name, INSTRB( lr_wf_whs_rec.file_name, cv_extension ) )
                         ;
--
    --==================================
    -- ファイルオープン
    --==================================
    lf_file_hand := UTL_FILE.FOPEN(
                       lr_wf_whs_rec.directory -- ディレクトリ
                      ,lv_save_file_name        -- ファイル名
                      ,cv_file_mode            -- モード（上書）
                    );
--
    --==================================
    -- ロット情報を取得
    --==================================
    BEGIN
      -- 在庫照会画面データソースパッケージ「データ取得関数」呼出
      xxinv540001.blk_ilm_qry(
         ior_ilm_data             =>  l_ilm_block_tab     -- 結果格納用配列  tbl_ilm_block I/O
        ,in_item_id               =>  gt_item_id          -- 品目ID          xxcmn_item_mst_v.item_id%TYPE
        ,iv_parent_div            =>  cv_n                -- 親コード区分    VARCHAR2
        ,in_inventory_location_id =>  gt_location_id      -- 保管倉庫ID      xxcmn_item_locations_v.inventory_location_id%TYPE
        ,iv_deleg_house           =>  cv_n                -- 代表倉庫照会    VARCHAR2
        ,iv_ext_warehouse         =>  cv_n                -- 倉庫抽出フラグ  VARCHAR2
        ,iv_item_div_code         =>  gt_item_div         -- 品目区分コード  xxcmn_item_categories_v.segment1%TYPE
        ,iv_prod_div_code         =>  gt_prod_div         -- 商品区分コード  xxcmn_item_categories_v.segment1%TYPE
        ,iv_unit_div              =>  gv_unit_div         -- 単位区分        VARCHAR2
        ,iv_qt_status_code        =>  NULL                -- 品質判定結果    xxwip_qt_inspection.qt_effect1%TYPE
        ,id_manu_date_from        =>  NULL                -- 製造年月日From  DATE
        ,id_manu_date_to          =>  NULL                -- 製造年月日To    DATE
        ,iv_prop_sign             =>  NULL                -- 固有記号        ic_lots_mst.attribute2%TYPE
        ,id_consume_from          =>  NULL                -- 賞味期限From    DATE
        ,id_consume_to            =>  NULL                -- 賞味期限To      DATE
        ,iv_lot_no                =>  gt_lot_no           -- ロット№        ic_lots_mst.lot_no%TYPE
        ,iv_register_code         =>  gt_cust_stock_whse  -- 名義コード      xxcmn_item_locations_v.customer_stock_whse%TYPE,
        ,id_effective_date        =>  gd_effective_date   -- 有効日付        DATE
        ,iv_ext_show              =>  cv_y                -- 在庫有だけ表示  VARCHAR2
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- 在庫照会画面データソースパッケージエラーメッセージ
        lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_app_xxcmn
                       ,iv_name         => cv_msg_xxcmn_11053
                       ,iv_token_name1  => cv_tkn_item_id
                       ,iv_token_value1 => TO_CHAR( gt_item_id )
                       ,iv_token_name2  => cv_tkn_location_id
                       ,iv_token_value2 => TO_CHAR( gt_location_id )
                       ,iv_token_name3  => cv_tkn_cust_stock_whse
                       ,iv_token_value3 => gt_cust_stock_whse
                       ,iv_token_name4  => cv_tkn_errmsg
                       ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 対象件数カウント
    gn_target_cnt := l_ilm_block_tab.COUNT;
--
    --==================================
    -- CSV出力処理
    --==================================
    << csv_loop >>
    FOR i IN 1..gn_target_cnt LOOP
--
      -- 引当可能数、手持在庫数、入庫予定数、出庫予定数のいずれかが0以外のみ処理する
      IF (
           ( l_ilm_block_tab(i).subtractable <> 0 )
           OR
           ( l_ilm_block_tab(i).inv_stock_vol <> 0 )
           OR
           ( l_ilm_block_tab(i).supply_stock_plan <> 0 )
           OR
           ( l_ilm_block_tab(i).take_stock_plan <> 0 )
         )
      THEN
--
        -- 初期化
        lv_num_of_case := NULL;
--
        -- パラメータ品目区分が、原料・半製品・製品の場合
        IF ( gt_item_div IN ( cv_material_g, cv_semi_f_item, cv_item ) ) THEN
--
          -- 初期化
          lt_num_of_lot := NULL;
--
          --==================================
          -- ロットマスタの在庫入数取得
          --==================================
          BEGIN
            SELECT NVL( ilm.attribute6, cv_num_of_0 )  num_of_case
            INTO   lt_num_of_lot
            FROM   ic_lots_mst    ilm
            WHERE  ilm.lot_id = l_ilm_block_tab(i).ilm_lot_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- トークンの取得(テーブル名)
              lv_tkn_msg := xxcmn_common_pkg.get_msg(
                               iv_application  => cv_app_xxcmn
                              ,iv_name         => cv_msg_xxcmn_11056
                            );
              -- メッセージ生成
              lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => cv_app_xxcmn
                             ,iv_name         => cv_msg_xxcmn_11050
                             ,iv_token_name1  => cv_tkn_table
                             ,iv_token_value1 => lv_tkn_msg
                             ,iv_token_name2  => cv_tkn_errmsg
                             ,iv_token_value2 => SQLERRM
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
          END;
        END IF;
--
        -- ループ初回、もしくは、前出力対象レコードと品目が異なる場合のみ
        IF (
             ( lt_item_no_before IS NULL )
             OR
             ( lt_item_no_before <> l_ilm_block_tab(i).ximv_item_no )
           )
        THEN
--
          -- 初期化
          lt_item_um      := NULL;
          lt_frequent_qty := NULL;
          lt_num_of_item  := NULL;
--
          --==================================
          -- 単位名称・代表入数取得
          --==================================
          BEGIN
            SELECT /*+
                     USE_NL( ximv.iimb ximv.ximb ximv.msib )
                   */
                   ximv.item_um                            item_um       -- 単位名
                  ,ximv.frequent_qty                       frequent_qty  -- 代表入数
                  ,NVL( ximv.num_of_cases, cv_num_of_0 )   num_of_item   -- ケース入数
            INTO   lt_item_um
                  ,lt_frequent_qty
                  ,lt_num_of_item
            FROM   xxcmn_item_mst_v ximv
            WHERE  ximv.item_no      = l_ilm_block_tab(i).ximv_item_no
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- トークンの取得(テーブル名)
              lv_tkn_msg := xxcmn_common_pkg.get_msg(
                               iv_application  => cv_app_xxcmn
                              ,iv_name         => cv_msg_xxcmn_11054
                            );
              -- メッセージ生成
              lv_errmsg := xxcmn_common_pkg.get_msg(
                              iv_application  => cv_app_xxcmn
                             ,iv_name         => cv_msg_xxcmn_11050
                             ,iv_token_name1  => cv_tkn_table
                             ,iv_token_value1 => lv_tkn_msg
                             ,iv_token_name2  => cv_tkn_errmsg
                             ,iv_token_value2 => SQLERRM
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
          END;
--
        END IF;
--
        --==================================
        -- ロットNoの編集
        --==================================
        -- ロットがある（デフォルトロット以外）の場合
        IF ( l_ilm_block_tab(i).ilm_lot_id <> cn_default_lot_id ) THEN
          lt_lot_no := l_ilm_block_tab(i).ilm_lot_no;  -- 取得したロットNo
        -- ロットがない（デフォルトロット）の場合
        ELSE
          lt_lot_no := cv_default_lot_no;              -- デフォルトロット用のロットNo固定値
        END IF;
--
        --==================================
        -- 入数の編集
        --==================================
        -- パラメータ品目区分が、原料・半製品・製品の場合
        IF ( gt_item_div IN ( cv_material_g, cv_semi_f_item, cv_item ) ) THEN
          -- 取得したロットの入数が0、NULL以外の場合
          IF ( lt_num_of_lot <> cv_num_of_0 ) THEN
            lv_num_of_case := lt_num_of_lot;    -- ロットマスタの在庫入数
          -- 取得したロットの入数が0、NULLの場合
          ELSE
            lv_num_of_case := lt_frequent_qty;  -- 品目マスタの代表入数(NULLの場合はNULL)
          END IF;
        -- パラメータ品目区分が、資材の場合
        ELSE
          -- 取得した品目の入数が0、NULL以外の場合
          IF (  lt_num_of_item <> cv_num_of_0 ) THEN
            lv_num_of_case := lt_num_of_item;   -- 品目マスタのケース入数
          ELSE
            lv_num_of_case := lt_frequent_qty;  -- 品目マスタの代表入数(NULLの場合はNULL)
          END IF;
        END IF;
--
        --==================================
        -- CSV出力項目の編集
        --==================================
        lv_csv_data := cv_coop_name_itoen                                                   || cv_separate_code || -- 1.会社名
                       cv_data_type                                                         || cv_separate_code || -- 2.データ種別
                       cv_branch_no                                                         || cv_separate_code || -- 3.伝送用枝番
                       l_ilm_block_tab(i).ximv_item_no                                      || cv_separate_code || -- 4.ｺｰﾄﾞ1
                       lt_lot_no                                                            || cv_separate_code || -- 5.ｺｰﾄﾞ2
                       NULL                                                                 || cv_separate_code || -- 6.ｺｰﾄﾞ3
                       l_ilm_block_tab(i).xlvv_xl8_meaning                                  || cv_separate_code || -- 7.名称1
                       NULL                                                                 || cv_separate_code || -- 8.名称2
                       NULL                                                                 || cv_separate_code || -- 9.名称3
                       l_ilm_block_tab(i).xlvv_xl7_meaning                                  || cv_separate_code || -- 10.情報1
                       lv_num_of_case                                                       || cv_separate_code || -- 11.情報2
                       TO_CHAR( l_ilm_block_tab(i).ilm_attribute1, cv_fmt_date )            || cv_separate_code || -- 12.情報3
                       l_ilm_block_tab(i).ilm_attribute2                                    || cv_separate_code || -- 13.情報4
                       TO_CHAR( l_ilm_block_tab(i).ilm_attribute3, cv_fmt_date )            || cv_separate_code || -- 14.情報5
                       NULL                                                                 || cv_separate_code || -- 15.情報6
                       NULL                                                                 || cv_separate_code || -- 16.情報7
                       NULL                                                                 || cv_separate_code || -- 17.情報8
                       NULL                                                                 || cv_separate_code || -- 18.情報9
                       l_ilm_block_tab(i).ilm_attribute12                                   || cv_separate_code || -- 19.情報10
                       lt_item_um                                                           || cv_separate_code || -- 20.情報11
                       NULL                                                                 || cv_separate_code || -- 21.情報12
                       NULL                                                                 || cv_separate_code || -- 22.情報13
                       NULL                                                                 || cv_separate_code || -- 23.情報14
                       NULL                                                                 || cv_separate_code || -- 24.情報15
                       NULL                                                                 || cv_separate_code || -- 25.情報16
                       NULL                                                                 || cv_separate_code || -- 26.情報17
                       NULL                                                                 || cv_separate_code || -- 27.情報18
                       NULL                                                                 || cv_separate_code || -- 28.情報19
                       NULL                                                                 || cv_separate_code || -- 29.情報20
                       l_ilm_block_tab(i).ilm_attribute13                                   || cv_separate_code || -- 30.区分1
                       NULL                                                                 || cv_separate_code || -- 31.区分2
                       NULL                                                                 || cv_separate_code || -- 32.区分3
                       NULL                                                                 || cv_separate_code || -- 33.区分4
                       NULL                                                                 || cv_separate_code || -- 34.区分5
                       NULL                                                                 || cv_separate_code || -- 35.区分6
                       NULL                                                                 || cv_separate_code || -- 36.区分7
                       NULL                                                                 || cv_separate_code || -- 37.区分8
                       NULL                                                                 || cv_separate_code || -- 38.区分9
                       NULL                                                                 || cv_separate_code || -- 39.区分10
                       NULL                                                                 || cv_separate_code || -- 40.区分11
                       NULL                                                                 || cv_separate_code || -- 41.区分12
                       NULL                                                                 || cv_separate_code || -- 42.区分13
                       NULL                                                                 || cv_separate_code || -- 43.区分14
                       NULL                                                                 || cv_separate_code || -- 44.区分15
                       NULL                                                                 || cv_separate_code || -- 45.区分16
                       NULL                                                                 || cv_separate_code || -- 46.区分17
                       NULL                                                                 || cv_separate_code || -- 47.区分18
                       NULL                                                                 || cv_separate_code || -- 48.区分19
                       NULL                                                                 || cv_separate_code || -- 49.区分20
                       TO_CHAR( l_ilm_block_tab(i).ilm_creation_date, cv_fmt_date )         || cv_separate_code || -- 50.適用開始日
                       TO_CHAR( l_ilm_block_tab(i).ilm_last_update_date, cv_fmt_datetime )                         -- 51.更新日時
        ;
--
        --==================================
        -- ファイル出力
        --==================================
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
        -- 品目ブレーク用の変数に現レコードの値を格納
        lt_item_no_before := l_ilm_block_tab(i).ximv_item_no;
        -- 成功件数カウント
        gn_normal_cnt     := gn_normal_cnt + 1;
--
      END IF;
--
    END LOOP csv_loop;
--
    --==================================
    -- ファイルクローズ
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- 成功件数が0件以外(出力対象あり)の場合
    IF ( gn_normal_cnt <> 0 ) THEN
      --==================================
      -- ワークフロー通知
      --==================================
      xxwsh_common3_pkg.wf_whs_start(
        ir_wf_whs_rec => lr_wf_whs_rec            -- ワークフロー関連情報
       ,iv_filename   => lv_save_file_name        -- ファイル名
       ,ov_errbuf     => lv_errbuf                -- エラー・メッセージ
       ,ov_retcode    => lv_retcode               -- リターン・コード
       ,ov_errmsg     => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    -- 成功件数が0件(出力対象なし)の場合
    ELSE
      -- 対象データ未取得エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application => cv_app_xxcmn
                     ,iv_name        => cv_msg_xxcmn_11048
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      --1行空白
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => NULL
      );
--
      -- ステータス警告
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- ファイルがオープンしている場合
      IF ( UTL_FILE.IS_OPEN( lf_file_hand ) ) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルがオープンしている場合
      IF ( UTL_FILE.IS_OPEN( lf_file_hand ) ) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_item_code              IN  VARCHAR2  -- 1.品目コード
   ,iv_item_div               IN  VARCHAR2  -- 2.品目区分
   ,iv_lot_no                 IN  VARCHAR2  -- 3.ロットNo
   ,iv_subinventory_code      IN  VARCHAR2  -- 4.倉庫コード
   ,iv_effective_date         IN  VARCHAR2  -- 5.有効日
   ,iv_prod_div               IN  VARCHAR2  -- 6.商品区分
   ,ov_errbuf                 OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  初期処理(A-1)
    -- ===============================
    init(
      iv_item_code          =>  iv_item_code         -- 1.品目コード
     ,iv_item_div           =>  iv_item_div          -- 2.品目区分
     ,iv_lot_no             =>  iv_lot_no            -- 3.ロットNo
     ,iv_subinventory_code  =>  iv_subinventory_code -- 4.倉庫コード
     ,iv_effective_date     =>  iv_effective_date    -- 5.有効日
     ,iv_prod_div           =>  iv_prod_div          -- 6.商品区分
     ,ov_errbuf             =>  lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            =>  lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg             =>  lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- CSV出力処理(A-2)
    --==================================
    output_data(
      ov_errbuf               =>  lv_errbuf               -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              =>  lv_retcode              -- リターン・コード             --# 固定 #
     ,ov_errmsg               =>  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    errbuf                    OUT VARCHAR2        -- エラー・メッセージ  --# 固定 #
   ,retcode                   OUT VARCHAR2        -- リターン・コード    --# 固定 #
   ,iv_item_code              IN  VARCHAR2        -- 1.品目コード
   ,iv_item_div               IN  VARCHAR2        -- 2.品目区分
   ,iv_lot_no                 IN  VARCHAR2        -- 3.ロットNo
   ,iv_subinventory_code      IN  VARCHAR2        -- 4.倉庫コード
   ,iv_effective_date         IN  VARCHAR2        -- 5.有効日
   ,iv_prod_div               IN  VARCHAR2        -- 6.商品区分
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
    cv_sts_cd_normal   CONSTANT VARCHAR2(1)   := 'C';                -- ステータスコード:C(正常)
    cv_sts_cd_warn     CONSTANT VARCHAR2(1)   := 'G';                -- ステータスコード:G(警告)
    cv_sts_cd_error    CONSTANT VARCHAR2(1)   := 'E';                -- ステータスコード:E(エラー)
--
    cv_appl_name_xxcmn CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：生産(マスタ・経理・共通)
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00008';  -- 処理件数
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-00009';  -- 成功件数
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- エラー件数
    cv_out_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-00012';  -- 終了メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'CNT';              -- 件数メッセージ用トークン名
    cv_status_token    CONSTANT VARCHAR2(10)  := 'STATUS';           -- 処理ステータス用トークン名
    cv_cp_status_cd    CONSTANT VARCHAR2(100) := 'CP_STATUS_CODE';   -- ルックアップ
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_item_code          =>  iv_item_code          -- 1.品目コード
     ,iv_item_div           =>  iv_item_div           -- 2.品目区分
     ,iv_lot_no             =>  iv_lot_no             -- 3.ロットNo
     ,iv_subinventory_code  =>  iv_subinventory_code  -- 4.倉庫コード
     ,iv_effective_date     =>  iv_effective_date     -- 5.有効日
     ,iv_prod_div           =>  iv_prod_div           -- 6.商品区分
     ,ov_errbuf             =>  lv_errbuf             -- エラー・メッセージ             --# 固定 #
     ,ov_retcode            =>  lv_retcode            -- リターン・コード               --# 固定 #
     ,ov_errmsg             =>  lv_errmsg             -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
    -- ステータスがエラーの場合
      -- 件数設定
      gn_target_cnt := 0;  -- 処理件数
      gn_normal_cnt := 0;  -- 成功件数
      gn_error_cnt  := 1;  -- エラー件数
--
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    ELSIF ( lv_retcode = cv_status_warn ) THEN
    -- ステータスが警告の場合(対象データ無しの場合)
      -- 件数設定
      gn_normal_cnt := 0; -- 成功件数
      gn_error_cnt  := 0; -- エラー件数
    ELSE
    -- ステータスが正常の場合
      -- 件数設定
      gn_error_cnt  := 0;             -- エラー件数
    END IF;
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
--
    -- 終了ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_cp_status_cd
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            cv_status_normal,cv_sts_cd_normal,
                                            cv_status_warn,cv_sts_cd_warn,
                                            cv_sts_cd_error)
    AND    ROWNUM                  = 1
    ;
    gv_out_msg := xxcmn_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcmn
                   ,iv_name         => cv_out_msg
                   ,iv_token_name1  => cv_status_token
                   ,iv_token_value1 => gv_conc_status
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --終了ステータスセット
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
END XXCMN800015C;
/
