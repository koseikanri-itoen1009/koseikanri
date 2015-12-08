CREATE OR REPLACE PACKAGE BODY xxwip_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip_common_pkg(BODY)
 * Description            : 共通関数(XXWIP)(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.24
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  update_duty_status     P          業務ステータス更新関数
 *  insert_material_line   P          原料明細追加関数
 *  update_material_line   P          原料明細更新関数
 *  delete_material_line   P          原料明細削除関数
 *  get_batch_no           F   VAR    バッチNo取得関数
 *  lot_execute            P          ロット追加・更新関数
 *  insert_line_allocation P          明細割当追加関数
 *  update_line_allocation P          明細割当更新関数
 *  delete_line_allocation P          明細割当削除関数
 *  update_lot_dff_api     P          ロットマスタDFF更新(生産バッチ用)
 *  update_inv_price       P          在庫単価更新関数
 *  update_trust_price     P          委託加工費更新関数
 *  qt_parameter_check     P          入力パラメータチェック(非公開)
 *  qt_check_and_lock      P          データチェック/ロック(非公開)
 *  qt_get_gme_data        P          生産情報取得(非公開)
 *  qt_get_po_data         P          発注情報取得(非公開)
 *  qt_get_lot_data        P          ロット情報取得(非公開)
 *  qt_get_vendor_supply_data
 *                         P          外注出来高情報取得(非公開)
 *  qt_get_namaha_prod_data
 *                         P          荒茶製造情報取得(非公開)
 *  qt_inspection_ins      P          品質検査依頼情報登録/更新(非公開)
 *  qt_update_lot_dff_api  P          ロットマスタ更新(非公開)
 *  get_business_date      P          営業日取得
 *  make_qt_inspection     P          品質検査依頼情報作成
 *  get_can_stock_qty      F          手持在庫数量算出API(投入実績用)
 *  change_trans_date_all  P          処理日付更新関数
 *
 * Change Record
 * ------------ ----- ------------------ -----------------------------------------------
 *  Date         Ver.  Editor             Description
 * ------------ ----- ------------------ -----------------------------------------------
 *  2007/11/13   1.0   H.Itou             新規作成
 *  2008/05/28   1.1   Oracle 二瓶 大輔   結合テスト不具合対応(委託加工費更新関数修正)
 *  2008/06/02   1.2   Oracle 二瓶 大輔   内部変更要求#130(委託加工費更新関数修正)
 *  2008/06/12   1.3   Oracle 二瓶 大輔   システムテスト不具合対応#78(委託加工費更新関数修正)
 *  2008/06/25   1.4   Oracle 二瓶 大輔   システムテスト不具合対応#75
 *  2008/06/27   1.5   Oracle 二瓶 大輔   結合テスト不具合対応(原料追加関数修正)
 *  2008/07/02   1.6   Oracle 伊藤ひとみ  システムテスト不具合対応#343(荒茶製造情報取得関数修正)
 *  2008/07/10   1.7   Oracle 二瓶 大輔   システムテスト不具合対応#315(在庫単価取得関数修正)
 *  2008/07/14   1.8   Oracle 伊藤ひとみ  結合不具合 指摘2対応  品質検査依頼情報作成で更新の場合、検査予定日・結果を更新しない。
 *  2008/08/25   1.9   Oracle 伊藤ひとみ  内部変更要求#189対応(品質検査依頼情報作成修正)更新・削除で検査依頼NoがNULLの場合、処理を行わない。
 *  2008/09/03   1.10  Oracle 二瓶 大輔   統合障害#46対応(処理日付更新関数修正)
 *  2008/09/10   1.11  Oracle 二瓶 大輔   統合障害#112対応(ロット追加・更新関数)
 *  2008/09/10   1.12  Oracle 二瓶 大輔   結合テスト指摘対応No30
 *  2008/10/09   1.13  Oracle 二瓶 大輔   統合障害#169対応(手持在庫数量算出API(投入実績用))
 *  2008/11/14   1.14  Oracle 二瓶 大輔   統合障害#649対応(委託加工費更新関数)
 *  2008/11/17   1.15  Oracle 二瓶 大輔   統合障害#678対応(処理日付更新関数)
 *  2008/12/22   1.16  Oracle 二瓶 大輔   本番障害#743対応(ロット追加・更新関数)
 *  2008/12/25   1.17  Oracle 二瓶 大輔   本番障害#851対応(手持在庫数量算出API(投入実績用))
 *  2009/01/15   1.18  Oracle 二瓶 大輔   本番障害#836恒久対応Ⅱ(業務ステータス更新関数)
 *  2009/01/30   1.19  Oracle 二瓶 大輔   本番障害#4対応(ランク3追加)
 *                                        本番障害#666対応(実績開始日修正)
 *  2009/02/16   1.20  Oracle 二瓶 大輔   本番障害#1198対応
 *  2009/02/16   1.21  Oracle 伊藤 ひとみ 本番障害#32,1096対応(品質検査依頼情報作成 数量加算 ロットステータス初期化)
 *  2009/02/27   1.22  Oracle 伊藤 ひとみ 本番障害#32再対応(品質検査依頼情報作成)
 *  2009/03/09   1.23  Oracle 伊藤 ひとみ 本番障害#32再対応(品質検査依頼情報作成)
 *  2015/10/29   1.24  SCSK   山下 翔太   E_本稼動_13238対応
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
  api_expt               EXCEPTION;     -- API例外
  skip_expt              EXCEPTION;     -- スキップ例外
  deadlock_detected      EXCEPTION;     -- デッドロックエラー
-- 2008/08/25 H.Itou Add Start 内部変更要求#189
  no_action_expt         EXCEPTION;     -- 処理不要例外
-- 2008/08/25 H.Itou Add End
--
  PRAGMA EXCEPTION_INIT(deadlock_detected, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxwip_common_pkg'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';            -- モジュール名略称：XXCMN 共通
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';            -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
  -- メッセージ
  gv_msg_xxwip10049  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10049';  -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
  gv_batch_no        CONSTANT VARCHAR2(100) := 'バッチNo.';
--
  -- トークン
  gv_tkn_batch_no    CONSTANT VARCHAR2(100) := 'BATCH_NO';         -- トークン：BATCH_NO
  gv_tkn_api_name    CONSTANT VARCHAR2(100) := 'API_NAME';         -- トークン：API_NAME
--
  -- APIリターン・コード
  gv_api_s           CONSTANT VARCHAR2(1)   := 'S';                -- APIリターン・コード：S （成功）
--
  gv_type_y          CONSTANT VARCHAR2(1)   := 'Y';                -- タイプ：Y
  gv_type_n          CONSTANT VARCHAR2(1)   := 'N';                -- タイプ：N
--
  -- ラインタイプ
  gn_prod            CONSTANT NUMBER        := 1;                  -- 完成品
  gn_co_prod         CONSTANT NUMBER        := 2;                  -- 副産物
  gn_material        CONSTANT NUMBER        := -1;                 -- 投入品
--
  gn_default_lot_id  CONSTANT NUMBER        := 0;                  -- デフォルトロットID
  gn_delete_mark_on  CONSTANT NUMBER        := 1;                  -- 削除フラグON
  gn_delete_mark_off CONSTANT NUMBER        := 0;                  -- 削除フラグOFF
  gv_cmpnt_code_gen  CONSTANT VARCHAR2(5)   := '01GEN';            -- 品目コンポーネント区分：01GEN
  -- xxcmn共通関数リターン・コード
  gn_e               CONSTANT NUMBER        := 1;                  -- xxcmn共通関数リターン・コード：1（エラー）
--
  -- 業務ステータス
  gt_duty_status_com   CONSTANT gme_batch_header.attribute4%TYPE := '7';  -- 業務ステータス：7（完了）
  gt_duty_status_cls   CONSTANT gme_batch_header.attribute4%TYPE := '8';  -- 業務ステータス：8（クローズ）
  gt_duty_status_can   CONSTANT gme_batch_header.attribute4%TYPE := '-1'; -- 業務ステータス：-1（取消）
  -- 区分
  gt_division_gme     CONSTANT xxwip_qt_inspection.division%TYPE := '1';  -- 区分  1:生産
  gt_division_po      CONSTANT xxwip_qt_inspection.division%TYPE := '2';  -- 区分  2:発注
  gt_division_lot     CONSTANT xxwip_qt_inspection.division%TYPE := '3';  -- 区分  3:ロット情報
  gt_division_spl     CONSTANT xxwip_qt_inspection.division%TYPE := '4';  -- 区分  4:外注出来高
  gt_division_tea     CONSTANT xxwip_qt_inspection.division%TYPE := '5';  -- 区分  5:荒茶製造
  -- 処理区分
  gv_disposal_div_ins CONSTANT VARCHAR2(1) := '1'; -- 処理区分  1:追加
  gv_disposal_div_upd CONSTANT VARCHAR2(1) := '2'; -- 処理区分  2:更新
  gv_disposal_div_del CONSTANT VARCHAR2(1) := '3'; -- 処理区分  3:削除
  -- 対象先
  gv_qt_object_tea    CONSTANT VARCHAR2(1) := '1'; -- 対象先  1:荒茶品目
  gv_qt_object_bp1    CONSTANT VARCHAR2(1) := '2'; -- 対象先  2:副産物１
  gv_qt_object_bp2    CONSTANT VARCHAR2(1) := '3'; -- 対象先  3:副産物２
  gv_qt_object_bp3    CONSTANT VARCHAR2(1) := '4'; -- 対象先  4:副産物３
  -- 生産原料詳細.ラインタイプ
  gt_line_type_goods  CONSTANT gme_material_details.line_type%TYPE := 1;    -- ラインタイプ：1（完成品）
  gt_line_type_sub    CONSTANT gme_material_details.line_type%TYPE := 2;    -- ラインタイプ：2（副産物）
  -- OPM保留在庫トランザクション.完了フラグ
  gt_completed_ind_com   CONSTANT ic_tran_pnd.completed_ind%TYPE         := '1';  -- 完了フラグ：1（完了）
  -- 品質検査結果
  gt_qt_status_mi        CONSTANT fnd_lookup_values.lookup_code%TYPE     := '10'; -- 品質検査結果 10:未判定
  -- 検査種別
  gt_inspect_class_gme   CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '1';  -- 検査種別：1（生産）
  gt_inspect_class_po    CONSTANT xxwip_qt_inspection.inspect_class%TYPE := '2';  -- 検査種別：2（発注仕入）
  -- 品目区分
  gv_item_type_mtl       CONSTANT VARCHAR2(1) := '1'; -- 品目区分  1:原料
  gv_item_type_shz       CONSTANT VARCHAR2(1) := '2'; -- 品目区分  2:資材
  gv_item_type_harf_prod CONSTANT VARCHAR2(1) := '4'; -- 品目区分  4:半製品
  gv_item_type_prod      CONSTANT VARCHAR2(1) := '5'; -- 品目区分  5:製品
  -- 委託計算区分
  gv_trust_calc_type_volume  CONSTANT VARCHAR2(1) := '1'; -- 委託計算区分  1:出来高
  gv_trust_calc_type_invest  CONSTANT VARCHAR2(1) := '2'; -- 委託計算区分  2:投入
  -- OPMロットマスタDFF更新APIバージョン
  gn_api_version      CONSTANT NUMBER(2,1) := 1.0;
--
  -- 外注出来高情報.処理タイプ
  gt_txns_type_aite CONSTANT XXPO_VENDOR_SUPPLY_TXNS.txns_type%TYPE := '1';  -- 処理タイプ：相手先在庫
  gt_txns_type_sok  CONSTANT XXPO_VENDOR_SUPPLY_TXNS.txns_type%TYPE := '2';  -- 処理タイプ：即時仕入
--
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
   * Procedure Name   : update_duty_status
   * Description      : 業務ステータス更新関数
   ***********************************************************************************/
  PROCEDURE update_duty_status(
    in_batch_id                   IN  NUMBER                -- 1.更新対象のバッチID
  , iv_duty_status                IN  VARCHAR2              -- 2.更新ステータス
  , ov_errbuf                     OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
  , ov_retcode                    OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
  , ov_errmsg                     OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                   CONSTANT VARCHAR2(100) := 'update_duty_status';           --プログラム名
    cv_api_name                   CONSTANT VARCHAR2(100) := '業務ステータス更新関数';
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode                    VARCHAR2(1);      -- リターン・コード
    lv_errmsg                     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_date                       DATE;
    ln_message_count              NUMBER;                             -- メッセージカウント
    lv_message_list               VARCHAR2(200);                      -- メッセージリスト
    lv_return_status              VARCHAR2(100);                      -- リターンステータス
    lt_batch_status               gme_batch_header.batch_status%TYPE; -- バッチステータス
    lt_batch_no                   gme_batch_header.batch_no%TYPE;     -- バッチNO
    lt_batch_id_dummy             gme_batch_header.batch_id%TYPE;     -- バッチID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_gme_batch_header           gme_batch_header%ROWTYPE;              --
    lr_gme_batch_header_temp      gme_batch_header%ROWTYPE;              --
    lr_unallocated_materials      GME_API_PUB.UNALLOCATED_MATERIALS_TAB; --
--
    -- ===============================
    -- ユーザー定義例外
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
    -- ***********************************************
    -- ***  生産バッチヘッダのロック
    -- ***********************************************
    BEGIN
      SELECT gbh.batch_id   batch_id   -- バッチID
      INTO   lt_batch_id_dummy
      FROM   gme_batch_header gbh      -- 生産バッチヘッダ
      WHERE  gbh.batch_id = in_batch_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN DEADLOCK_DETECTED THEN
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        null;
--
      WHEN TOO_MANY_ROWS THEN
        null;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  バッチNoを取得
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no( in_batch_id );
--
    -- ***********************************************
    -- ***  生産バッチヘッダの業務ステータスを更新
    -- ***********************************************
    UPDATE gme_batch_header gbh
    SET    gbh.attribute4       = iv_duty_status       -- 業務ステータス
      ,    gbh.last_update_date = SYSDATE              -- 最終更新日
      ,    gbh.last_updated_by  = FND_GLOBAL.USER_ID   -- 最終更新者
    WHERE  gbh.batch_id = in_batch_id
    ;
--
    -- *************************************************
    -- ***  生産バッチヘッダのバッチステータスを取得
    -- *************************************************
    SELECT gbh.batch_status batch_status -- バッチステータス
    INTO   lt_batch_status
    FROM   gme_batch_header gbh          -- 生産バッチヘッダ
    WHERE  gbh.batch_id = in_batch_id
    ;
--
    -- *************************************************
    -- ***  生産日を取得、NULLの場合はシステム日付を取得
    -- *************************************************
    SELECT NVL( FND_DATE.STRING_TO_DATE( gmd.attribute11, 'YYYY/MM/DD' ), TRUNC( SYSDATE ) )
    INTO   ld_date
    FROM   gme_material_details gmd     -- 生産原料詳細
    WHERE  gmd.batch_id  = in_batch_id
    AND    gmd.line_type = gn_prod
    AND    ROWNUM        = 1
    ;
--
    -- バッチステータスが保留中、更新ステータスが完了の場合、バッチステータスをWIPに更新
    IF (
             ( '1' = lt_batch_status )
         AND ( iv_duty_status = gt_duty_status_com )
    )
    THEN
--
      lr_gme_batch_header.batch_id          := in_batch_id;
      lr_gme_batch_header.actual_start_date := ld_date;
--
      -- 生産バッチリリース関数を実行
      GME_API_PUB.RELEASE_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS
      , p_init_msg_list                 =>  FALSE
      , p_commit                        =>  FALSE
      , x_message_count                 =>  ln_message_count
      , x_message_list                  =>  lv_message_list
      , x_return_status                 =>  lv_retcode
      , p_batch_header                  =>  lr_gme_batch_header
      , x_batch_header                  =>  lr_gme_batch_header_temp
      , p_ignore_shortages              =>  FALSE
      , p_consume_avail_plain_item      =>  FALSE
      , x_unallocated_material          =>  lr_unallocated_materials
      , p_ignore_unalloc                =>  TRUE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
    -- バッチステータスがクローズ、更新ステータスが完了の場合、バッチステータスをWIPに更新
    ELSIF (
             ( '4' = lt_batch_status )
         AND ( iv_duty_status = gt_duty_status_com )
    )
    THEN
      lr_gme_batch_header.batch_id          := in_batch_id;
      lr_gme_batch_header.actual_start_date := ld_date;
--
      -- バッチ再オープン関数を実行
      GME_API_PUB.REOPEN_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN         NUMBER  := gme_api_pub.api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN         NUMBER  := gme_api_pub.max_errors
      , p_init_msg_list                 =>  FALSE                     -- IN         BOOLEAN := FALSE
      , p_commit                        =>  FALSE                     -- IN         BOOLEAN := FALSE
      , x_message_count                 =>  ln_message_count          -- OUT NOCOPY NUMBER
      , x_message_list                  =>  lv_message_list           -- OUT NOCOPY VARCHAR2
      , x_return_status                 =>  lv_retcode                -- OUT NOCOPY VARCHAR2
      , p_batch_header                  =>  lr_gme_batch_header       -- IN         gme_batch_header%ROWTYPE
-- 変更 START 2008/05/07 Oikawa
      , p_reopen_steps                  =>  TRUE                      -- IN         BOOLEAN := FALSE
--      , p_reopen_steps                  =>  FALSE                     -- IN         BOOLEAN := FALSE
-- 変更 END
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT NOCOPY gme_batch_header%ROWTYPE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
      -- WIPに戻す関数を実行
      GME_API_PUB.UNCERTIFY_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN              NUMBER := gme_api_pub.api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN              NUMBER := gme_api_pub.max_errors
      , p_init_msg_list                 =>  FALSE                     -- IN              BOOLEAN := FALSE
      , p_commit                        =>  FALSE                     -- IN              BOOLEAN := FALSE
      , x_message_count                 =>  ln_message_count          -- OUT NOCOPY      NUMBER
      , x_message_list                  =>  lv_message_list           -- OUT NOCOPY      VARCHAR2
      , x_return_status                 =>  lv_retcode                -- OUT NOCOPY      VARCHAR2
      , p_batch_header                  =>  lr_gme_batch_header       -- IN              gme_batch_header%ROWTYPE
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT NOCOPY      gme_batch_header%ROWTYPE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
    -- 更新ステータスが取消の場合、バッチステータスを取消に更新
    ELSIF ( iv_duty_status = gt_duty_status_can ) THEN
      lr_gme_batch_header.batch_id := in_batch_id;
--
      -- 生産取消関数を実行
      GME_API_PUB.CANCEL_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN              NUMBER := gme_api_pub.api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN              NUMBER := gme_api_pub.max_errors
      , p_init_msg_list                 =>  FALSE                     -- IN              BOOLEAN := FALSE
      , p_commit                        =>  FALSE                     -- IN              BOOLEAN := FALSE
      , x_message_count                 =>  ln_message_count          -- OUT NOCOPY      NUMBER
      , x_message_list                  =>  lv_message_list           -- OUT NOCOPY      VARCHAR2
      , x_return_status                 =>  lv_retcode                -- OUT NOCOPY      VARCHAR2
      , p_batch_header                  =>  lr_gme_batch_header       -- IN              gme_batch_header%ROWTYPE
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT NOCOPY      gme_batch_header%ROWTYPE
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
-- 2009/01/15 D.Nihei ADD START 本番障害#836恒久対応Ⅱ
    -- 更新ステータスがクローズの場合、バッチステータスをクローズに更新
    ELSIF ( iv_duty_status = gt_duty_status_cls ) THEN
      lr_gme_batch_header.batch_id          := in_batch_id;
      lr_gme_batch_header.actual_start_date := ld_date;
--
      -- 生産完了関数を実行
      GME_API_PUB.CERTIFY_BATCH(
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN              NUMBER := gme_api_pub.api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN              NUMBER := gme_api_pub.max_errors
      , p_init_msg_list                 =>  FALSE                     -- IN              BOOLEAN := FALSE
      , p_commit                        =>  FALSE                     -- IN              BOOLEAN := FALSE
      , x_message_count                 =>  ln_message_count          -- OUT NOCOPY      NUMBER
      , x_message_list                  =>  lv_message_list           -- OUT NOCOPY      VARCHAR2
      , x_return_status                 =>  lv_retcode                -- OUT NOCOPY      VARCHAR2
      , p_del_incomplete_manual         =>  TRUE                      -- IN             ：p_del_incomplete_manual
      , p_ignore_shortages              =>  FALSE                     -- IN             ：p_ignore_shortages
      , p_batch_header                  =>  lr_gme_batch_header       -- IN              gme_batch_header%ROWTYPE
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT NOCOPY      gme_batch_header%ROWTYPE
      , x_unallocated_material          =>  lr_unallocated_materials  -- OUT            ：x_unallocated_material
      );
--
      IF ( lv_retcode <> gv_api_s ) THEN
        RAISE api_expt;
      END IF;
--
      lr_gme_batch_header.batch_id          := in_batch_id;
      lr_gme_batch_header.actual_start_date := NULL;
      lr_gme_batch_header.batch_close_date  := ld_date; -- クローズ日付
      -- 生産クローズ関数を実行
      GME_API_PUB.CLOSE_BATCH (
        p_api_version                   =>  GME_API_PUB.API_VERSION   -- IN ：p_api_version
      , p_validation_level              =>  GME_API_PUB.MAX_ERRORS    -- IN ：p_validation_level
      , p_init_msg_list                 =>  FALSE                     -- IN ：p_init_msg_list
      , p_commit                        =>  FALSE                     -- IN ：p_commit
      , x_message_count                 =>  ln_message_count          -- OUT：x_message_count
      , x_message_list                  =>  lv_message_list           -- OUT：x_message_list
      , x_return_status                 =>  lv_retcode                -- OUT：x_return_status
      , p_batch_header                  =>  lr_gme_batch_header       -- IN ：p_batch_header  更新する値をセットしたレコード
      , x_batch_header                  =>  lr_gme_batch_header_temp  -- OUT：x_batch_header
      );
--
-- 2009/01/15 D.Nihei ADD END
    END IF;
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名
                    ),1,5000);
-- 2009/01/30 D.Nihei MOD START 本番障害#666対応
--      ov_errmsg  := lv_errmsg || ':' || lv_message_list;
      ov_errmsg  := lv_errmsg || ':' || lt_batch_no || ':' || lv_message_list;
-- 2009/01/30 D.Nihei MOD END
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
      -- ログ初期化
      FND_MSG_PUB.INITIALIZE;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END update_duty_status;
--
  /**********************************************************************************
   * Function Name    : get_batch_no
   * Description      : バッチNo取得
   ***********************************************************************************/
  FUNCTION get_batch_no(
    it_batch_id gme_batch_header.batch_id%TYPE
  )
-- 2009/02/16 D.Nihei Mod Start 内部変更要求#189
--    RETURN NUMBER
    RETURN VARCHAR2
-- 2009/02/16 D.Nihei Mod End
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_batch_no' ; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lt_batch_no   gme_batch_header.batch_no%TYPE;            -- バッチNo
--
  BEGIN
--
    -- ***********************************************
    -- ***  バッチNoを取得します。***
    -- ***********************************************
    SELECT gbh.batch_no batch_no -- バッチNo
    INTO   lt_batch_no
    FROM   gme_batch_header gbh -- 生産バッチヘッダ
    WHERE  gbh.batch_id = it_batch_id
    ;
--
    RETURN lt_batch_no ;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
    RETURN NULL ;
  END get_batch_no ;
--
  /**********************************************************************************
   * Procedure Name   : insert_material_line
   * Description      : 原料明細追加関数
   ***********************************************************************************/
  PROCEDURE insert_material_line(
    ir_material_detail IN  gme_material_details%ROWTYPE,
    or_material_detail OUT NOCOPY gme_material_details%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_material_line'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '原料明細追加関数';
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
    ln_message_count       NUMBER;                       -- メッセージ件数
    lv_message_list        VARCHAR2(100);                -- メッセージリスト
    lv_return_status       VARCHAR2(100);                -- リターンステータス
    lr_material_detail_in  gme_material_details%ROWTYPE; -- 生産原料詳細IN
    lr_material_detail_out gme_material_details%ROWTYPE; -- 生産原料詳細OUT
    lt_batch_no            gme_batch_header.batch_no%TYPE;  -- バッチNO
    ln_batch_step_no       NUMBER;                          -- バッチステップNo
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
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
    -- INパラメータを設定します
    lr_material_detail_in := ir_material_detail;
--
    -- ***********************************************
    -- ***  バッチNoを取得します。***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_material_detail_in.batch_id);
--
    -- ***********************************************
    -- ***  行Noを取得します。               ***
    -- ***********************************************
    BEGIN
      SELECT NVL(MAX(gmd.line_no),0) + 1 line_no  -- 投入品の最大行No
      INTO   lr_material_detail_in.line_no
      FROM   gme_material_details gmd -- 生産原料詳細
      WHERE  gmd.batch_id  = lr_material_detail_in.batch_id
      AND    gmd.line_type = lr_material_detail_in.line_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE api_expt;
    END;
--
    -- 投入品の場合
    IF ( lr_material_detail_in.line_type = gn_material) THEN
      -- ***********************************************
      -- ***  各種情報を設定します。                 ***
      -- ***********************************************
      lr_material_detail_in.release_type            := 1;     -- リリースタイプ
      lr_material_detail_in.scrap_factor            := 0;     -- 廃棄係数
      lr_material_detail_in.scale_type              := 1;     -- スケールタイプ
      lr_material_detail_in.contribute_yield_ind    := 'Y';   -- コントリビュート収率
      lr_material_detail_in.contribute_step_qty_ind := 'Y';   -- コントリビュート払出先ステップ数量
      lr_material_detail_in.wip_plan_qty            := 0;     -- WIP計画数
      lr_material_detail_in.plan_qty                := 0;     -- 計画数
      lr_material_detail_in.actual_qty              := null;  -- 実績数量
      lr_material_detail_in.original_qty            := null;  -- オリジナル数量
      ln_batch_step_no := TO_NUMBER(lr_material_detail_in.attribute8);
--
      -- ***********************************************
      -- ***  投入品を追加します。                   ***
      -- ***********************************************
      GME_API_PUB.INSERT_MATERIAL_LINE(
        p_api_version           => GME_API_PUB.API_VERSION
       ,p_validation_level      => GME_API_PUB.MAX_ERRORS
       ,p_init_msg_list         => FALSE
       ,p_commit                => FALSE
       ,x_message_count         => ln_message_count
       ,x_message_list          => lv_message_list
       ,x_return_status         => lv_return_status
       ,p_material_detail       => lr_material_detail_in
       ,p_batchstep_no          => ln_batch_step_no
       ,x_material_detail       => lr_material_detail_out
      );
      IF (lv_return_status <> gv_api_s) THEN
        lv_errbuf := lv_message_list;
        RAISE api_expt;
      END IF;
--
    -- 副産物の場合
    ELSIF ( lr_material_detail_in.line_type = gn_co_prod ) THEN
--
-- 2008/06/27 D.Nihei DEL START
--      -- ***********************************************
--      -- ***  完成品の生産日、賞味期限を取得します。 ***
--      -- ***********************************************
--      BEGIN
--        SELECT gmd.attribute10 -- 賞味期限日
--              ,gmd.attribute11 -- 生産日
--              ,gmd.attribute17 -- 製造日
--        INTO   lr_material_detail_in.attribute10
--              ,lr_material_detail_in.attribute11
--              ,lr_material_detail_in.attribute17
--        FROM   gme_material_details gmd  -- 生産原料詳細
--        WHERE  gmd.line_type = gn_prod -- 完成品
--        AND    gmd.batch_id  = lr_material_detail_in.batch_id
--        AND    ROWNUM        = 1
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          lr_material_detail_in.attribute10 := NULL; -- 賞味期限日
--          lr_material_detail_in.attribute11 := NULL; -- 生産日
--          lr_material_detail_in.attribute17 := NULL; -- 製造日
--      END;
-- 2008/06/27 D.Nihei DEL START
--
      -- ***********************************************
      -- ***  各種情報を設定します。                 ***
      -- ***********************************************
      lr_material_detail_in.release_type            := 1;     -- リリースタイプ
      lr_material_detail_in.scrap_factor            := 0;     -- 廃棄係数
      lr_material_detail_in.scale_type              := 1;     -- スケールタイプ
      lr_material_detail_in.contribute_yield_ind    := 'Y';   -- コントリビュート収率
      lr_material_detail_in.contribute_step_qty_ind := 'Y';   -- コントリビュート払出先ステップ数量
      lr_material_detail_in.wip_plan_qty            := 0;     -- WIP計画数
      lr_material_detail_in.plan_qty                := 0;     -- 計画数
      lr_material_detail_in.actual_qty              := null;  -- 実績数量
      lr_material_detail_in.original_qty            := null;  -- オリジナル数量
      ln_batch_step_no := TO_NUMBER(lr_material_detail_in.attribute8);
--
      -- ***********************************************
      -- ***  副産物を追加します。                   ***
      -- ***********************************************
      GME_API_PUB.INSERT_MATERIAL_LINE(
        p_api_version           => GME_API_PUB.API_VERSION   -- IN ：p_api_version
       ,p_validation_level      => GME_API_PUB.MAX_ERRORS    -- IN ：p_validation_level
       ,p_init_msg_list         => FALSE                     -- IN ：p_init_msg_list
       ,p_commit                => FALSE                     -- IN ：p_commit
       ,x_message_count         => ln_message_count          -- OUT：x_message_count
       ,x_message_list          => lv_message_list           -- OUT：x_message_list
       ,x_return_status         => lv_return_status          -- OUT：x_return_status
       ,p_material_detail       => lr_material_detail_in     -- IN :p_material_detail
       ,p_batchstep_no          => ln_batch_step_no          -- IN :p_batchstep_no
       ,x_material_detail       => lr_material_detail_out    -- OUT:x_material_detail
      );
--
      IF (lv_return_status <> gv_api_s) THEN
        lv_errbuf := lv_message_list;
        RAISE api_expt;
      END IF;
--
    END IF;
    -- OUTパラメータを設定します
    or_material_detail := lr_material_detail_out;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END insert_material_line;
--
  /**********************************************************************************
   * Procedure Name   : update_material_line
   * Description      : 原料明細更新関数
   ***********************************************************************************/
  PROCEDURE update_material_line(
    ir_material_detail IN  gme_material_details%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ             --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- リターン・コード               --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_material_line'; --プログラム名
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
    ln_message_count        NUMBER;                       --
    lv_message_list         VARCHAR2(100);                --
    lv_return_status        VARCHAR2(100);                --
    lt_batch_id             gme_material_details.batch_id%TYPE;           -- バッチID
    lt_material_detail_id   gme_material_details.material_detail_id%TYPE; -- 生産原料詳細ID
    lt_expiration_date      gme_material_details.attribute10%TYPE;        -- 賞味期限日
    lt_prouct_date          gme_material_details.attribute11%TYPE;        -- 生産日
    lt_maker_date           gme_material_details.attribute17%TYPE;        -- 製造日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail           gme_material_details%ROWTYPE;        --
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
    lr_material_detail := ir_material_detail;
    -- ***********************************************
    -- ***  生産原料詳細のロックを取得します。     ***
    -- ***********************************************
    BEGIN
      SELECT gmd.batch_id            -- バッチID
            ,gmd.material_detail_id  -- 生産原料詳細ID
      INTO   lt_batch_id
            ,lt_material_detail_id
      FROM   gme_material_details gmd  -- 生産原料詳細
      WHERE  gmd.material_detail_id = lr_material_detail.material_detail_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN DEADLOCK_DETECTED THEN
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        null;
--
      WHEN TOO_MANY_ROWS THEN
        null;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 完成品の場合
    IF ( lr_material_detail.line_type = gn_prod ) THEN
      -- ***********************************************
      -- ***  完成品の生産日、賞味期限を取得します。 ***
      -- ***********************************************
      BEGIN
        SELECT gmd.attribute10 -- 賞味期限日
              ,gmd.attribute11 -- 生産日
              ,gmd.attribute17 -- 製造日
        INTO   lt_expiration_date
              ,lt_prouct_date
              ,lt_maker_date
        FROM   gme_material_details gmd  -- 生産原料詳細
        WHERE  gmd.line_type = gn_prod
        AND    gmd.batch_id  = lt_batch_id
        AND    ROWNUM        = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_expiration_date := NULL; -- 賞味期限日
          lt_prouct_date     := NULL; -- 生産日
          lt_maker_date      := NULL; -- 製造日
      END;
      -- ***********************************************
      -- ***  完成品の情報を更新します。             ***
      -- ***********************************************
      UPDATE gme_material_details gmd
      SET    gmd.attribute1  = lr_material_detail.attribute1
            ,gmd.attribute2  = lr_material_detail.attribute2
            ,gmd.attribute3  = lr_material_detail.attribute3
            ,gmd.attribute4  = lr_material_detail.attribute4
            ,gmd.attribute6  = lr_material_detail.attribute6
            ,gmd.attribute9  = lr_material_detail.attribute9
            ,gmd.attribute10 = lr_material_detail.attribute10
            ,gmd.attribute11 = lr_material_detail.attribute11
            ,gmd.attribute14 = lr_material_detail.attribute14
            ,gmd.attribute15 = lr_material_detail.attribute15
            ,gmd.attribute16 = lr_material_detail.attribute16
            ,gmd.attribute17 = lr_material_detail.attribute17
-- 2009/01/30 D.Nihei ADD START
            ,gmd.attribute26 = lr_material_detail.attribute26
-- 2009/01/30 D.Nihei ADD END
            ,gmd.last_updated_by   = FND_GLOBAL.USER_ID
            ,gmd.last_update_date  = SYSDATE
            ,gmd.last_update_login = FND_GLOBAL.LOGIN_ID
      WHERE  gmd.material_detail_id  = lr_material_detail.material_detail_id
      ;
--
      -- 生産日、製造日、賞味期限日のいずれかに変更が生じた場合
      IF (   (lr_material_detail.attribute10 <> lt_expiration_date)
          OR (lr_material_detail.attribute11 <> lt_prouct_date)
          OR (lr_material_detail.attribute17 <> lt_maker_date)     ) THEN
--
        -- *******************************************************
        -- ***  副産物の生産原料詳細のロックを取得します。     ***
        -- *******************************************************
        BEGIN
          SELECT gmd.batch_id            -- バッチID
          INTO   lt_batch_id
          FROM   gme_material_details gmd  -- 生産原料詳細
          WHERE  gmd.material_detail_id = lt_batch_id
          AND    line_type = gn_co_prod
          FOR UPDATE NOWAIT
          ;
        EXCEPTION
          WHEN DEADLOCK_DETECTED THEN
            RAISE global_api_expt;
--
          WHEN NO_DATA_FOUND THEN
            null;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        UPDATE gme_material_details gmd
        SET    gmd.attribute10 = lr_material_detail.attribute10
              ,gmd.attribute11 = lr_material_detail.attribute11
              ,gmd.attribute17 = lr_material_detail.attribute17
              ,gmd.last_updated_by   = FND_GLOBAL.USER_ID
              ,gmd.last_update_date  = SYSDATE
              ,gmd.last_update_login = FND_GLOBAL.LOGIN_ID
        WHERE  gmd.batch_id = lt_batch_id
        AND    line_type    = gn_co_prod
        ;
      END IF;
    -- 副産物の場合
    ELSIF ( lr_material_detail.line_type = gn_co_prod ) THEN
      -- ***********************************************
      -- ***  完成品の生産日、賞味期限を取得します。 ***
      -- ***********************************************
      BEGIN
        SELECT gmd.attribute10 -- 賞味期限日
              ,gmd.attribute11 -- 生産日
              ,gmd.attribute17 -- 製造日
        INTO   lr_material_detail.attribute10
              ,lr_material_detail.attribute11
              ,lr_material_detail.attribute17
        FROM   gme_material_details gmd  -- 生産原料詳細
        WHERE  gmd.line_type = gn_prod
        AND    gmd.batch_id  = lt_batch_id
        AND    ROWNUM        = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lr_material_detail.attribute10 := NULL; -- 賞味期限日
          lr_material_detail.attribute11 := NULL; -- 生産日
          lr_material_detail.attribute17 := NULL; -- 製造日
      END;
--
      -- ***********************************************
      -- ***  副産物の情報を更新します。             ***
      -- ***********************************************
      UPDATE gme_material_details gmd
      SET    gmd.attribute1        = lr_material_detail.attribute1
            ,gmd.attribute2        = lr_material_detail.attribute2
            ,gmd.attribute3        = lr_material_detail.attribute3
            ,gmd.attribute6        = lr_material_detail.attribute6
            ,gmd.attribute10       = lr_material_detail.attribute10
            ,gmd.attribute11       = lr_material_detail.attribute11
            ,gmd.attribute17       = lr_material_detail.attribute17
-- 2009/01/30 D.Nihei ADD START
            ,gmd.attribute26       = lr_material_detail.attribute26
-- 2009/01/30 D.Nihei ADD END
            ,gmd.last_updated_by   = FND_GLOBAL.USER_ID
            ,gmd.last_update_date  = SYSDATE
            ,gmd.last_update_login = FND_GLOBAL.LOGIN_ID
      WHERE  gmd.material_detail_id  = lr_material_detail.material_detail_id
      ;
--
    END IF;
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
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      ov_retcode := gv_status_error;                                            --# 任意 #
  END update_material_line;
--
  /**********************************************************************************
   * Procedure Name   : delete_material_line
   * Description      : 原料明細削除関数
   ***********************************************************************************/
  PROCEDURE delete_material_line(
    in_batch_id    IN  NUMBER,     -- 生産バッチID
    in_mtl_dtl_id  IN  NUMBER,     -- 生産原料詳細ID
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_material_line'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '原料明細削除関数';
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
    ln_message_count       NUMBER;                       --
    lv_message_list        VARCHAR2(100);                --
    lv_return_status       VARCHAR2(100);                --
    lt_batch_status        gme_batch_header.batch_status%TYPE; -- バッチステータス
    lt_batch_no            gme_batch_header.batch_no%TYPE;     -- バッチNO
--
    -- *** ローカル・カーソル ***
    -- OPM保留在庫トランザクションカーソル
    CURSOR cur_ic_tran_pnd
    IS
      SELECT itp.trans_id trans_id
            ,itp.trans_qty
            ,itp.line_type
      FROM   ic_tran_pnd itp -- OPM保留在庫トランザクション
      WHERE  itp.doc_id    = in_batch_id
      AND    itp.line_id   = in_mtl_dtl_id
      AND    itp.lot_id    = gn_default_lot_id
      ;
    -- 副産物用OPM保留在庫トランザクションカーソル
    CURSOR cur_ic_tran_pnd_co_prod
    IS
      SELECT itp.trans_id trans_id
      FROM   ic_tran_pnd itp -- OPM保留在庫トランザクション
      WHERE  itp.line_id     = in_mtl_dtl_id
      AND    itp.line_type   = gn_co_prod
      AND    itp.reverse_id  IS NULL
      AND    itp.delete_mark = gn_delete_mark_off
      AND    itp.lot_id      > gn_default_lot_id
      ;
--
    -- *** ローカル・レコード ***
    lr_material_detail_in  gme_material_details%ROWTYPE;
    lr_material_detail_out gme_material_details%ROWTYPE;
    lr_tran_row_in         gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out        gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def        gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    lr_material_detail_in.batch_id           := in_batch_id;
    lr_material_detail_in.material_detail_id := in_mtl_dtl_id;
--
    -- ***********************************************
    -- ***  バッチNoを取得します。***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_material_detail_in.batch_id);
--
    -- *************************************************
    -- ***  生産バッチヘッダのバッチステータスを取得します。***
    -- *************************************************
    BEGIN
      SELECT gbh.batch_status batch_status
      INTO   lt_batch_status
      FROM   gme_batch_header gbh
      WHERE  gbh.batch_id = lr_material_detail_in.batch_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- バッチステータスがWIPの場合
    IF (2 = lt_batch_status) THEN
      -- *************************************************
      -- ***  副産物の割当を削除します。   ***
      -- *************************************************
      <<co_prod_loop>>
      FOR rec_ic_tran_pnd_co_prod IN cur_ic_tran_pnd_co_prod LOOP
        -- *************************************************
        -- ***  割当削除関数を実行します。               ***
        -- *************************************************
        GME_API_PUB.DELETE_LINE_ALLOCATION (
          p_api_version        => GME_API_PUB.API_VERSION          -- IN         NUMBER := gme_api_pub.api_version
         ,p_validation_level   => GME_API_PUB.MAX_ERRORS           -- IN         NUMBER := gme_api_pub.max_errors
         ,p_init_msg_list      => FALSE                            -- IN         BOOLEAN := FALSE
         ,p_commit             => FALSE                            -- IN         BOOLEAN := FALSE
         ,p_trans_id           => rec_ic_tran_pnd_co_prod.trans_id -- IN         NUMBER
         ,p_scale_phantom      => FALSE                            -- IN         BOOLEAN DEFAULT FALSE
         ,x_material_detail    => lr_material_detail_out           -- OUT NOCOPY gme_material_details%ROWTYPE
         ,x_def_tran_row       => lr_tran_row_def                  -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
         ,x_message_count      => ln_message_count                 -- OUT NOCOPY NUMBER
         ,x_message_list       => lv_message_list                  -- OUT NOCOPY VARCHAR2
         ,x_return_status      => lv_return_status                 -- OUT NOCOPY VARCHAR2
        );
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          lv_errbuf := lv_message_list;
          RAISE api_expt;
        END IF;
      END LOOP;
      -- *************************************************
      -- ***  デフォルトロットの処理IDを取得します。   ***
      -- *************************************************
      <<ic_tran_pnd_loop>>
      FOR rec_ic_tran_pnd IN cur_ic_tran_pnd LOOP
        lr_tran_row_in.trans_id := rec_ic_tran_pnd.trans_id;
        IF (rec_ic_tran_pnd.trans_qty > 0) THEN
          -- *************************************************
          -- ***  処理数量に0を設定します。                ***
          -- *************************************************
          lr_tran_row_in.trans_qty := 0;
          -- *************************************************
          -- ***  割当更新関数を実行します。               ***
          -- *************************************************
          GME_API_PUB.UPDATE_LINE_ALLOCATION (
            p_api_version        => GME_API_PUB.API_VERSION -- IN         NUMBER := gme_api_pub.api_version
           ,p_validation_level   => GME_API_PUB.MAX_ERRORS  -- IN         NUMBER := gme_api_pub.max_errors
           ,p_init_msg_list      => FALSE                   -- IN         BOOLEAN := FALSE
           ,p_commit             => FALSE                   -- IN         BOOLEAN := FALSE
           ,p_tran_row           => lr_tran_row_in          -- IN         gme_inventory_txns_gtmp%ROWTYPE
           ,p_lot_no             => NULL                    -- IN         VARCHAR2 DEFAULT NULL
           ,p_sublot_no          => NULL                    -- IN         VARCHAR2 DEFAULT NULL
           ,p_create_lot         => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
           ,p_ignore_shortage    => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
           ,p_scale_phantom      => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
           ,x_material_detail    => lr_material_detail_out  -- OUT NOCOPY gme_material_details%ROWTYPE
           ,x_tran_row           => lr_tran_row_out         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
           ,x_def_tran_row       => lr_tran_row_def         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
           ,x_message_count      => ln_message_count        -- OUT NOCOPY NUMBER
           ,x_message_list       => lv_message_list         -- OUT NOCOPY VARCHAR2
           ,x_return_status      => lv_return_status        -- OUT NOCOPY VARCHAR2
          );
          IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            lv_errbuf := lv_message_list;
            RAISE api_expt;
          END IF;
        END IF;
        -- ********************************************
        -- ***  削除フラグを更新します。               ***
        -- ********************************************
        UPDATE gme_material_details gmd
        SET    gmd.attribute24        = gv_type_y,           -- 削除フラグ
               gmd.last_update_date   = SYSDATE,             -- 最終更新日
               gmd.last_updated_by    = FND_GLOBAL.USER_ID   -- 最終更新者
        WHERE  gmd.material_detail_id = lr_material_detail_in.material_detail_id
        ;
      END LOOP;
    ELSE
      -- *********************************************
      -- ***  原料削除関数を実行します。           ***
      -- *********************************************
      GME_API_PUB.DELETE_MATERIAL_LINE(
        p_api_version        => GME_API_PUB.API_VERSION -- IN         NUMBER := gme_api_pub.api_version
       ,p_validation_level   => GME_API_PUB.MAX_ERRORS  -- IN         NUMBER := gme_api_pub.max_errors
       ,p_init_msg_list      => FALSE                   -- IN         BOOLEAN := FALSE
       ,p_commit             => FALSE                   -- IN         BOOLEAN := FALSE
       ,x_message_count      => ln_message_count        -- OUT NOCOPY NUMBER
       ,x_message_list       => lv_message_list         -- OUT NOCOPY VARCHAR2
       ,x_return_status      => lv_return_status        -- OUT NOCOPY VARCHAR2
       ,p_material_detail    => lr_material_detail_in   -- IN         gme_material_details%ROWTYPE
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        lv_errbuf := lv_message_list;
        RAISE api_expt;
      END IF;
    END IF;
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名：生産バッチヘッダ完了
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END delete_material_line;
--
  /**********************************************************************************
   * Procedure Name   : update_lot_dff_api
   * Description      : ロットマスタ更新(生産バッチ用)
  /*********************************************************************************/
  PROCEDURE update_lot_dff_api(
    iv_update_type          IN  VARCHAR2,                   -- IN 1.Y:NULLでもUPDATE、N:NULLの場合はUPDATE対象外
    ir_ic_lots_mst_in       IN  ic_lots_mst%ROWTYPE,        -- IN 2.ic_lots_mstレコード型
    ir_ic_lots_mst_out      OUT NOCOPY ic_lots_mst%ROWTYPE, -- OUT 1.ic_lots_mstレコード型
    ov_errbuf               OUT NOCOPY VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_lot_dff_api'; -- プログラム名
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
    ln_message_count      NUMBER;         -- メッセージカウント
    lv_message_list       VARCHAR2(200);  -- メッセージリスト
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_ic_lots_mst          ic_lots_mst%ROWTYPE;          -- ロットマスタレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    -- ====================================
    -- OPMロットマスタレコードに値をセット
    -- ====================================
    lr_ic_lots_mst.last_updated_by        := FND_GLOBAL.USER_ID;                -- 最終更新者
    lr_ic_lots_mst.last_update_date       := SYSDATE;                           -- 最終更新日
--
    -- ===============================
    -- OPMロットマスタロック
    -- ===============================
    BEGIN
      SELECT ilm.item_id       item_id
            ,ilm.lot_id        lot_id
            ,ilm.lot_no        lot_no
            ,ilm.attribute1    attribute1
            ,ilm.attribute2    attribute2
            ,ilm.attribute3    attribute3
            ,ilm.attribute4    attribute4
            ,ilm.attribute5    attribute5
            ,ilm.attribute6    attribute6
            ,ilm.attribute7    attribute7
            ,ilm.attribute8    attribute8
            ,ilm.attribute9    attribute9
            ,ilm.attribute10   attribute10
            ,ilm.attribute11   attribute11
            ,ilm.attribute12   attribute12
            ,ilm.attribute13   attribute13
            ,ilm.attribute14   attribute14
            ,ilm.attribute15   attribute15
            ,ilm.attribute16   attribute16
            ,ilm.attribute17   attribute17
            ,ilm.attribute18   attribute18
            ,ilm.attribute19   attribute19
            ,ilm.attribute20   attribute20
            ,ilm.attribute21   attribute21
            ,ilm.attribute22   attribute22
            ,ilm.attribute23   attribute23
            ,ilm.attribute24   attribute24
            ,ilm.attribute25   attribute25
            ,ilm.attribute26   attribute26
            ,ilm.attribute27   attribute27
            ,ilm.attribute28   attribute28
            ,ilm.attribute29   attribute29
            ,ilm.attribute30   attribute30
      INTO   lr_ic_lots_mst.item_id
            ,lr_ic_lots_mst.lot_id
            ,lr_ic_lots_mst.lot_no
            ,lr_ic_lots_mst.attribute1
            ,lr_ic_lots_mst.attribute2
            ,lr_ic_lots_mst.attribute3
            ,lr_ic_lots_mst.attribute4
            ,lr_ic_lots_mst.attribute5
            ,lr_ic_lots_mst.attribute6
            ,lr_ic_lots_mst.attribute7
            ,lr_ic_lots_mst.attribute8
            ,lr_ic_lots_mst.attribute9
            ,lr_ic_lots_mst.attribute10
            ,lr_ic_lots_mst.attribute11
            ,lr_ic_lots_mst.attribute12
            ,lr_ic_lots_mst.attribute13
            ,lr_ic_lots_mst.attribute14
            ,lr_ic_lots_mst.attribute15
            ,lr_ic_lots_mst.attribute16
            ,lr_ic_lots_mst.attribute17
            ,lr_ic_lots_mst.attribute18
            ,lr_ic_lots_mst.attribute19
            ,lr_ic_lots_mst.attribute20
            ,lr_ic_lots_mst.attribute21
            ,lr_ic_lots_mst.attribute22
            ,lr_ic_lots_mst.attribute23
            ,lr_ic_lots_mst.attribute24
            ,lr_ic_lots_mst.attribute25
            ,lr_ic_lots_mst.attribute26
            ,lr_ic_lots_mst.attribute27
            ,lr_ic_lots_mst.attribute28
            ,lr_ic_lots_mst.attribute29
            ,lr_ic_lots_mst.attribute30
      FROM   ic_lots_mst   ilm -- OPMロットマスタ
      WHERE  ilm.item_id = ir_ic_lots_mst_in.item_id   -- 品目ID
      AND    ilm.lot_id  = ir_ic_lots_mst_in.lot_id    -- ロットID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN DEADLOCK_DETECTED THEN
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================
    -- 値の設定
    -- ===============================
    IF (ir_ic_lots_mst_in.attribute7 IS NOT NULL) THEN
      -- 在庫単価
      lr_ic_lots_mst.attribute7 := ir_ic_lots_mst_in.attribute7;
    ELSE
      -- 賞味期限
      lr_ic_lots_mst.attribute3 := ir_ic_lots_mst_in.attribute3;
      -- 在庫入数
      lr_ic_lots_mst.attribute6 := ir_ic_lots_mst_in.attribute6;
      IF (iv_update_type = gv_type_y) THEN
        -- 製造年月日
        IF (ir_ic_lots_mst_in.attribute1 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute1 := ir_ic_lots_mst_in.attribute1;
        END IF;
        -- タイプ
        IF (ir_ic_lots_mst_in.attribute13 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute13 := ir_ic_lots_mst_in.attribute13;
        END IF;
        -- ランク１
        IF (ir_ic_lots_mst_in.attribute14 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute14 := ir_ic_lots_mst_in.attribute14;
        END IF;
        -- ランク２
        IF (ir_ic_lots_mst_in.attribute15 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute15 := ir_ic_lots_mst_in.attribute15;
        END IF;
-- 2009/01/30 D.Nihei ADD START
        -- ランク３
        IF (ir_ic_lots_mst_in.attribute19 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute19 := ir_ic_lots_mst_in.attribute19;
        END IF;
-- 2009/01/30 D.Nihei ADD END
        -- 摘要
        IF (ir_ic_lots_mst_in.attribute18 IS NOT NULL) THEN
          lr_ic_lots_mst.attribute18 := ir_ic_lots_mst_in.attribute18;
        END IF;
      ELSE
        -- 製造年月日
        lr_ic_lots_mst.attribute1  := ir_ic_lots_mst_in.attribute1;
        -- タイプ
        lr_ic_lots_mst.attribute13 := ir_ic_lots_mst_in.attribute13;
        -- ランク１
        lr_ic_lots_mst.attribute14 := ir_ic_lots_mst_in.attribute14;
        -- ランク２
        lr_ic_lots_mst.attribute15 := ir_ic_lots_mst_in.attribute15;
-- 2009/01/30 D.Nihei ADD START
        -- ランク３
        lr_ic_lots_mst.attribute19 := ir_ic_lots_mst_in.attribute19;
-- 2009/01/30 D.Nihei ADD END
        -- 摘要
        lr_ic_lots_mst.attribute18 := ir_ic_lots_mst_in.attribute18;
      END IF;
    END IF;
--
    -- ===============================
    -- OPMロットマスタDFF更新
    -- ===============================
    GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF(
      p_api_version       => gn_api_version             -- IN  NUMBER
     ,p_init_msg_list     => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_commit            => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_validation_level  => FND_API.G_VALID_LEVEL_FULL -- IN  NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL
     ,x_return_status     => lv_retcode                 -- OUT NOCOPY       VARCHAR2
     ,x_msg_count         => ln_message_count           -- OUT NOCOPY       NUMBER
     ,x_msg_data          => lv_message_list            -- OUT NOCOPY       VARCHAR2
     ,p_lot_rec           => lr_ic_lots_mst             -- IN  ic_lots_mst%ROWTYPE
    );
    -- 成功以外の場合、エラー
    IF (lv_retcode <> FND_API.G_RET_STS_SUCCESS)THEN
      ov_errbuf  := lv_message_list;
      ov_errmsg  := 'ロット更新関数エラー';
      RAISE api_expt;
    END IF;
--
    -- ===============================
    -- OPMロットマスタDFFセット
    -- ===============================
    ir_ic_lots_mst_out.lot_id      := lr_ic_lots_mst.lot_id;
    ir_ic_lots_mst_out.lot_no      := lr_ic_lots_mst.lot_no;
    ir_ic_lots_mst_out.attribute1  := lr_ic_lots_mst.attribute1;
    ir_ic_lots_mst_out.attribute3  := lr_ic_lots_mst.attribute3;
    ir_ic_lots_mst_out.attribute6  := lr_ic_lots_mst.attribute6;
    ir_ic_lots_mst_out.attribute13 := lr_ic_lots_mst.attribute13;
    ir_ic_lots_mst_out.attribute14 := lr_ic_lots_mst.attribute14;
    ir_ic_lots_mst_out.attribute15 := lr_ic_lots_mst.attribute15;
    ir_ic_lots_mst_out.attribute18 := lr_ic_lots_mst.attribute18;
-- 2009/01/30 D.Nihei ADD START
    ir_ic_lots_mst_out.attribute19 := lr_ic_lots_mst.attribute19;
-- 2009/01/30 D.Nihei ADD END
    ir_ic_lots_mst_out.attribute22 := lr_ic_lots_mst.attribute22;
-- 2009/02/16 H.Itou ADD 本番障害#32対応 作成区分追加
    ir_ic_lots_mst_out.attribute24 := lr_ic_lots_mst.attribute24;
-- 2009/02/16 H.Itou ADD END
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END update_lot_dff_api;
--
  /**********************************************************************************
   * Procedure Name   : lot_execute
   * Description      : ロット追加・更新関数
   ***********************************************************************************/
  PROCEDURE lot_execute(
    ir_lot_mst         IN  ic_lots_mst%ROWTYPE,                 -- OPMロットマスタ
    it_item_no         IN  ic_item_mst_b.item_no%TYPE,          -- 品目コード
    it_line_type       IN  gme_material_details.line_type%TYPE, -- ラインタイプ
    it_item_class_code IN  mtl_categories_b.segment1%TYPE,      -- 品目区分
    it_lot_no_prod     IN  ic_lots_mst.lot_no%TYPE,             -- 完成品のロットNo
    or_lot_mst         OUT NOCOPY ic_lots_mst%ROWTYPE,          -- OPMロットマスタ
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lot_execute'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := 'ロット追加・更新関数';
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
    lt_sublot_no           ic_lots_mst.sublot_no%TYPE;   -- サブロットNo
    ln_return_status       NUMBER;                       -- リターンステータス
    ln_message_count       NUMBER;                       --
    lv_message_list        VARCHAR2(10000);              --
    lv_msg_data            VARCHAR2(10000);              --
    lv_return_status       VARCHAR2(100);                --
    lt_batch_status        gme_batch_header.batch_status%TYPE; -- バッチステータス
    lt_batch_no            gme_batch_header.batch_no%TYPE;     -- バッチNO
    ln_message_cnt_dummy   NUMBER;                       --
    lb_return_status       BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail_in  gme_material_details%ROWTYPE;
    lr_material_detail_out gme_material_details%ROWTYPE;
    lr_tran_row_in         gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out        gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def        gme_inventory_txns_gtmp%ROWTYPE;
    lr_lot_mst_base        ic_lots_mst%ROWTYPE;
    lr_lot_mst             ic_lots_mst%ROWTYPE;
    lr_create_lot          GMIGAPI.lot_rec_typ;
    lr_ic_lots_mst         ic_lots_mst%ROWTYPE;
    lr_ic_lots_cpg         ic_lots_cpg%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ロット情報を退避
    lr_lot_mst_base := ir_lot_mst;
    lr_lot_mst      := ir_lot_mst;
--
    lb_return_status :=GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
--
    -- ラインタイプが完成品の場合
    IF (it_line_type = gn_prod) THEN
--
      -- 製品の場合、存在チェックを行う。
      IF (it_item_class_code = gv_item_type_prod) THEN
        -- ***********************************************
        -- ***  存在チェックを行います。               ***
        -- ***********************************************
        BEGIN
          SELECT ilm.lot_id
                ,ilm.lot_no
          INTO   lr_lot_mst.lot_id
                ,lr_lot_mst.lot_no
          FROM   ic_lots_mst ilm  --OPMロットマスタ
          WHERE  ilm.item_id    = lr_lot_mst_base.item_id     --品目ID
          AND    ilm.attribute1 = lr_lot_mst_base.attribute1  --製造年月日
          AND    ilm.attribute2 = lr_lot_mst_base.attribute2  --固有記号
          AND    ROWNUM         = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lr_lot_mst.lot_id := NULL;
            lr_lot_mst.lot_no := NULL;
        END;
-- 2008/09/10 v1.11 D.Nihei MOD START
--      -- 半製品の場合
--      ELSIF (it_item_class_code = gv_item_type_harf_prod) THEN
      -- 原料、半製品の場合
      ELSIF ( it_item_class_code IN ( gv_item_type_mtl , gv_item_type_harf_prod) )  THEN
-- 2008/09/10 v1.11 D.Nihei MOD END
        lr_lot_mst.lot_no := it_lot_no_prod;
        IF ((lr_lot_mst.lot_id IS NULL) OR (lr_lot_mst.lot_no IS NULL)) THEN
          ov_errbuf  := '不正なデータです。';
          RAISE api_expt;
        END IF;
      END IF;
      -- ロットNoが存在しない場合
      IF (lr_lot_mst.lot_no IS NULL) THEN
        -- ***********************************************
        -- ***  ロットNoを取得します。                 ***
        -- ***********************************************
        GMI_AUTOLOT.GENERATE_LOT_NUMBER(
          p_item_id         => lr_lot_mst.item_id
         ,p_in_lot_no       => NULL
         ,p_orgn_code       => NULL
         ,p_doc_id          => NULL
         ,p_line_id         => NULL
         ,p_doc_type        => NULL
         ,p_out_lot_no      => lr_lot_mst.lot_no
         ,p_sublot_no       => lt_sublot_no
         ,p_return_status   => ln_return_status
        );
        -- 採番されていない場合
        IF (lr_lot_mst.lot_no IS NULL) THEN
          ov_errbuf  := 'ロット採番に失敗しました。';
          RAISE api_expt;
        END IF;
        -- *************************************************
        -- *** ロットを新規に作成します。                ***
        -- *************************************************
        lr_create_lot.item_no          := it_item_no;
        lr_create_lot.lot_no           := lr_lot_mst.lot_no;
        lr_create_lot.sublot_no        := NULL;
        lr_create_lot.lot_desc         := NULL;
        lr_create_lot.origination_type := 2;
        lr_create_lot.attribute1       := lr_lot_mst.attribute1;
        lr_create_lot.attribute2       := lr_lot_mst.attribute2;
        lr_create_lot.attribute3       := lr_lot_mst.attribute3;
        lr_create_lot.attribute6       := lr_lot_mst.attribute6;
        lr_create_lot.attribute13      := lr_lot_mst.attribute13;
        lr_create_lot.attribute14      := lr_lot_mst.attribute14;
        lr_create_lot.attribute15      := lr_lot_mst.attribute15;
        lr_create_lot.attribute16      := lr_lot_mst.attribute16;
        lr_create_lot.attribute17      := lr_lot_mst.attribute17;
        lr_create_lot.attribute18      := lr_lot_mst.attribute18;
-- 2009/01/30 D.Nihei ADD START
        lr_create_lot.attribute19      := lr_lot_mst.attribute19;
-- 2009/01/30 D.Nihei ADD END
        lr_create_lot.attribute23      := lr_lot_mst.attribute23;
        lr_create_lot.attribute24      := '5'; -- 生産出来高
        lr_create_lot.user_name        := FND_GLOBAL.USER_NAME;
        lr_create_lot.lot_created      := SYSDATE;
-- 2008/12/22 D.Nihei ADD START
        lr_create_lot.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD');
        lr_create_lot.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/22 D.Nihei ADD END
--
        --ロット作成API
        GMIPAPI.CREATE_LOT(
           p_api_version      => 3.0
          ,p_init_msg_list    => FND_API.G_FALSE
          ,p_commit           => FND_API.G_FALSE
          ,p_validation_level => FND_API.G_VALID_LEVEL_FULL
          ,p_lot_rec          => lr_create_lot
          ,x_ic_lots_mst_row  => or_lot_mst
          ,x_ic_lots_cpg_row  => lr_ic_lots_cpg
          ,x_return_status    => lv_return_status
          ,x_msg_count        => ln_message_count
          ,x_msg_data         => lv_msg_data
        );
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ov_errbuf  := lv_msg_data;
          ov_errmsg  := ov_errmsg || 'ロット作成に失敗しました。';
          RAISE api_expt;
        END IF;
      -- ロットNoが存在する場合(付け替えの場合)
      ELSIF (NVL(it_lot_no_prod, -1) <> lr_lot_mst.lot_no) THEN
        update_lot_dff_api(
          iv_update_type      => gv_type_y
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := 'ロット更新に失敗しました。：' || lv_errmsg;
          RAISE api_expt;
        END IF;
      -- ロットNoが存在する場合(ロット変更なしで通常の更新)
      ELSIF (it_lot_no_prod = lr_lot_mst.lot_no) THEN
        update_lot_dff_api(
          iv_update_type      => gv_type_n
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := 'ロット更新に失敗しました。：' || lv_errmsg;
          RAISE api_expt;
        END IF;
      END IF;
    -- ラインタイプが副産物の場合
    ELSE
      -- 完成品のロットNoと異なる場合
      IF (it_lot_no_prod <> NVL(lr_lot_mst_base.lot_no, -1)) THEN
        -- ***********************************************
        -- ***  存在チェックを行います。               ***
        -- ***********************************************
        BEGIN
          SELECT ilm.lot_id
                ,ilm.lot_no
          INTO   lr_lot_mst.lot_id
                ,lr_lot_mst.lot_no
          FROM   ic_lots_mst ilm  -- OPMロットマスタ
          WHERE  ilm.item_id = lr_lot_mst_base.item_id -- 品目ID
          AND    ilm.lot_no  = it_lot_no_prod          -- ロットNo
          AND    ROWNUM      = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lr_lot_mst.lot_id := NULL;
            lr_lot_mst.lot_no := NULL;
        END;
      END IF;
      -- ロットNoが存在しない場合
      IF (lr_lot_mst.lot_no IS NULL) THEN
        -- *************************************************
        -- *** 完成品のロットNoでロットを新規に作成します。*
        -- *************************************************
        lr_create_lot.item_no          := it_item_no;
        lr_create_lot.lot_no           := it_lot_no_prod;
        lr_create_lot.sublot_no        := NULL;
        lr_create_lot.lot_desc         := NULL;
        lr_create_lot.origination_type := 2;
        lr_create_lot.attribute1       := lr_lot_mst.attribute1;
        lr_create_lot.attribute2       := lr_lot_mst.attribute2;
        lr_create_lot.attribute3       := lr_lot_mst.attribute3;
        lr_create_lot.attribute6       := lr_lot_mst.attribute6;
        lr_create_lot.attribute13      := lr_lot_mst.attribute13;
        lr_create_lot.attribute14      := lr_lot_mst.attribute14;
        lr_create_lot.attribute15      := lr_lot_mst.attribute15;
        lr_create_lot.attribute16      := lr_lot_mst.attribute16;
        lr_create_lot.attribute17      := lr_lot_mst.attribute17;
-- 2009/01/30 D.Nihei ADD START
        lr_create_lot.attribute19      := lr_lot_mst.attribute19;
-- 2009/01/30 D.Nihei ADD END
        lr_create_lot.attribute23      := lr_lot_mst.attribute23;
        lr_create_lot.attribute24      := '5'; -- 生産出来高
        lr_create_lot.user_name        := FND_GLOBAL.USER_NAME;
        lr_create_lot.lot_created      := SYSDATE;
-- 2008/12/22 D.Nihei ADD START
        lr_create_lot.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD');
        lr_create_lot.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/22 D.Nihei ADD END
--
        --ロット作成API
        GMIPAPI.CREATE_LOT(
          p_api_version      => 3.0
         ,p_init_msg_list    => FND_API.G_FALSE
         ,p_commit           => FND_API.G_FALSE
         ,p_validation_level => FND_API.G_VALID_LEVEL_FULL
         ,p_lot_rec          => lr_create_lot
         ,x_ic_lots_mst_row  => or_lot_mst
         ,x_ic_lots_cpg_row  => lr_ic_lots_cpg
         ,x_return_status    => lv_return_status
         ,x_msg_count        => ln_message_count
         ,x_msg_data         => lv_msg_data
        );
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ov_errbuf  := lv_msg_data;
          ov_errmsg  := 'ロット更新に失敗しました。：' || lv_errmsg;
          RAISE api_expt;
        END IF;
      -- ロットNoが存在するが現在のロットNoと異なる場合(付け替え)
      ELSIF (lr_lot_mst.lot_no <> NVL(lr_lot_mst_base.lot_no, -1)) THEN
        -- *************************************************
        -- *** ロットを更新します。                      ***
        -- *************************************************
        update_lot_dff_api(
          iv_update_type      => gv_type_y
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := 'ロット更新に失敗しました。：' || lv_errmsg;
          RAISE api_expt;
        END IF;
      -- ロットNoが存在し現在のロットNoと同じ場合(通常更新)
      ELSIF (lr_lot_mst.lot_no = lr_lot_mst_base.lot_no) THEN
        -- *************************************************
        -- *** ロットを更新します。                      ***
        -- *************************************************
        update_lot_dff_api(
          iv_update_type      => gv_type_n
         ,ir_ic_lots_mst_in   => lr_lot_mst
         ,ir_ic_lots_mst_out  => or_lot_mst
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          ov_errbuf  := lv_errbuf;
          ov_errmsg  := 'ロット更新に失敗しました。：' || lv_errmsg;
          RAISE api_expt;
        END IF;
      ELSE
        ov_errmsg  := '予期せぬロジックを通過しました。:' || ov_errmsg;
        RAISE api_expt;
      END IF;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END lot_execute;
--
  /**********************************************************************************
   * Procedure Name   : insert_line_allocation
   * Description      : 明細割当追加関数
   ***********************************************************************************/
  PROCEDURE insert_line_allocation(
    ir_tran_row_in IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_line_allocation'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '明細割当追加関数';
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
    ln_message_cnt       NUMBER;
    lv_return_status     VARCHAR2(1);
    lv_message_list      VARCHAR2(200);
    lt_batch_no          gme_batch_header.batch_no%TYPE;     -- バッチNO
    lv_msg               VARCHAR2(2000);
    ln_dummy_cnt         NUMBER(10);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail   gme_material_details%ROWTYPE;
    lr_tran_row_in       gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out      gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row      gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
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
    -- INパラメータを設定します
    lr_tran_row_in := ir_tran_row_in;
--
    -- ***********************************************
    -- ***  バッチNoを取得します。***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_tran_row_in.doc_id);
--
    -- ***********************************************
    -- ***  APIを実行します。                      ***
    -- ***********************************************
    GME_API_PUB.INSERT_LINE_ALLOCATION (
      p_api_version       => GME_API_PUB.API_VERSION
     ,p_validation_level  => GME_API_PUB.MAX_ERRORS
     ,p_init_msg_list     => FALSE
     ,p_commit            => FALSE
     ,p_tran_row          => lr_tran_row_in
     ,p_lot_no            => NULL
     ,p_sublot_no         => NULL
     ,p_create_lot        => FALSE
     ,p_ignore_shortage   => TRUE
     ,p_scale_phantom     => FALSE
     ,x_material_detail   => lr_material_detail
     ,x_tran_row          => lr_tran_row_out
     ,x_def_tran_row      => lr_def_tran_row
     ,x_message_count     => ln_message_cnt
     ,x_message_list      => lv_message_list
     ,x_return_status     => lv_return_status
    );
    IF (lv_return_status <> gv_api_s) THEN
      lv_errbuf := SUBSTRB(lv_message_list,1,5000);
      FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
        -- メッセージ取得
        FND_MSG_PUB.GET(
               p_msg_index      => i
              ,p_encoded        => FND_API.G_FALSE
              ,p_data           => lv_msg
              ,p_msg_index_out  => ln_dummy_cnt
        );
        -- ログ出力
        lv_errmsg := lv_errmsg || lv_msg;
  --
      END LOOP count_msg_loop;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END insert_line_allocation;
--
  /**********************************************************************************
   * Procedure Name   : update_line_allocation
   * Description      : 明細割当更新関数
   ***********************************************************************************/
  PROCEDURE update_line_allocation(
    ir_tran_row_in IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_allocation'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '明細割当更新関数';
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
    ln_message_cnt       NUMBER;
    lv_return_status     VARCHAR2(1);
    lv_message_list      VARCHAR2(200);
    lt_batch_no          gme_batch_header.batch_no%TYPE;     -- バッチNO
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail   gme_material_details%ROWTYPE;
    lr_tran_row_in       gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out      gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row      gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
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
    -- INパラメータを設定します
    lr_tran_row_in := ir_tran_row_in;
--
    -- ***********************************************
    -- ***  バッチNoを取得します。***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_tran_row_in.doc_id);
--
    -- ***********************************************
    -- ***  APIを実行します。                      ***
    -- ***********************************************
    GME_API_PUB.UPDATE_LINE_ALLOCATION (
      p_api_version       => GME_API_PUB.API_VERSION
     ,p_validation_level  => GME_API_PUB.MAX_ERRORS
     ,p_init_msg_list     => FALSE
     ,p_commit            => FALSE
     ,p_tran_row          => lr_tran_row_in
     ,p_lot_no            => NULL
     ,p_sublot_no         => NULL
     ,p_create_lot        => FALSE
     ,p_ignore_shortage   => TRUE
     ,p_scale_phantom     => FALSE
     ,x_material_detail   => lr_material_detail
     ,x_tran_row          => lr_tran_row_out
     ,x_def_tran_row      => lr_def_tran_row
     ,x_message_count     => ln_message_cnt
     ,x_message_list      => lv_message_list
     ,x_return_status     => lv_return_status
    );
    IF (lv_return_status <> gv_api_s) THEN
      lv_errbuf := lv_message_list;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END update_line_allocation;
--
  /**********************************************************************************
   * Procedure Name   : delete_line_allocation
   * Description      : 明細割当削除関数
   ***********************************************************************************/
  PROCEDURE delete_line_allocation(
    ir_tran_row_in IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_allocation'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '明細割当削除関数';
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
    ln_message_cnt       NUMBER;
    lv_return_status     VARCHAR2(1);
    lv_message_list      VARCHAR2(200);
    lt_batch_no          gme_batch_header.batch_no%TYPE;     -- バッチNO
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_material_detail   gme_material_details%ROWTYPE;
    lr_tran_row          gme_inventory_txns_gtmp%ROWTYPE;
    lr_def_tran_row      gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
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
    -- INパラメータを設定します
    lr_tran_row := ir_tran_row_in;
--
    -- ***********************************************
    -- ***  バッチNoを取得します。***
    -- ***********************************************
    lt_batch_no := xxwip_common_pkg.get_batch_no(lr_tran_row.doc_id);
--
    -- ***********************************************
    -- ***  APIを実行します。                      ***
    -- ***********************************************
    GME_API_PUB.DELETE_LINE_ALLOCATION (
      p_api_version       => GME_API_PUB.API_VERSION
     ,p_validation_level  => GME_API_PUB.MAX_ERRORS
     ,p_init_msg_list     => FALSE
     ,p_commit            => FALSE
     ,p_trans_id          => lr_tran_row.trans_id
     ,p_scale_phantom     => FALSE
     ,x_material_detail   => lr_material_detail
     ,x_def_tran_row      => lr_def_tran_row
     ,x_message_count     => ln_message_cnt
     ,x_message_list      => lv_message_list
     ,x_return_status     => lv_return_status
     );
    IF (lv_return_status <> gv_api_s) THEN
      lv_errbuf := lv_message_list;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END delete_line_allocation;
--
  /**********************************************************************************
   * Procedure Name   : update_inv_price
   * Description      : 在庫単価更新関数
   ***********************************************************************************/
  PROCEDURE update_inv_price(
    it_batch_id        IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_inv_price'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '在庫単価更新関数';
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
    ln_invest_price       NUMBER;   -- 投入品計
    ln_co_prod_price      NUMBER;   -- 副産物計
    ln_prod_price         NUMBER;   -- 完成品計
    lb_return_status      BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_lot_mst             ic_lots_mst%ROWTYPE;
    lr_lot_mst_out         ic_lots_mst%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    lb_return_status :=GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    -- ***********************************************
    -- ***  投入品計取得                           ***
    -- ***********************************************
    BEGIN
      SELECT SUM(NVL(ilm.attribute7, 0) * itp.trans_qty * -1) invest_price -- 投入単価計
      INTO   ln_invest_price
      FROM   ic_tran_pnd itp -- OPM保留在庫トランザクション
            ,ic_lots_mst ilm -- ロットマスタ
      WHERE  itp.lot_id      = ilm.lot_id
      AND    itp.reverse_id  IS NULL
      AND    itp.delete_mark = gn_delete_mark_off
      AND    itp.lot_id      > gn_default_lot_id
      AND    itp.line_type   = gn_material
      AND    itp.doc_id      = it_batch_id
      AND    itp.completed_ind = gv_flg_on
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_invest_price      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        ln_invest_price      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- ***********************************************
    -- ***  副産物計取得                           ***
    -- ***********************************************
    BEGIN
      SELECT SUM(ccd.cmpnt_cost * itp.trans_qty) co_prod_price -- 副産物単価計
      INTO   ln_co_prod_price
      FROM   gme_material_details gmd  -- 生産原料詳細
            ,ic_tran_pnd          itp  -- OPM保留在庫トランザクション
-- 2008/07/10 D.Nihei MOD START
--            ,cm_cmpt_dtl          ccd  -- 品目原価マスタ
--            ,cm_cmpt_mst_b        ccmb -- コンポーネント区分マスタ
            ,(SELECT cc.calendar_code          calendar_code
                    ,cc.item_id                item_id
                    ,NVL(SUM(cc.cmpnt_cost),0) cmpnt_cost
              FROM  cm_cmpt_dtl cc
              WHERE cc.whse_code =   fnd_profile.value(gv_prof_cost_price)
              GROUP BY calendar_code,item_id ) ccd          -- 標準原価マスタ
-- 2008/07/10 D.Nihei MOD START
            ,cm_cldr_dtl          ccdt -- 原価カレンダ
      WHERE  gmd.material_detail_id  = itp.line_id
      AND    itp.reverse_id          IS NULL
      AND    itp.delete_mark         = gn_delete_mark_off
      AND    itp.lot_id              > gn_default_lot_id
      AND    itp.line_type           = gn_co_prod
-- 2008/07/10 D.Nihei DEL START
--      AND    ccd.cost_cmpntcls_id    = ccmb.cost_cmpntcls_id
--      AND    ccmb.cost_cmpntcls_code = gv_cmpnt_code_gen
-- 2008/07/10 D.Nihei DEL END
      AND    ccd.calendar_code       = ccdt.calendar_code
      AND    ccdt.start_date        <= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD') , TRUNC(SYSDATE))
      AND    ccdt.end_date          >= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD') , TRUNC(SYSDATE))
-- 2008/07/10 D.Nihei DEL START
--      AND    ccd.whse_code           = fnd_profile.value(gv_prof_cost_price)
-- 2008/07/10 D.Nihei DEL END
      AND    itp.item_id             = ccd.item_id
      AND    itp.doc_id              = it_batch_id
      AND    itp.completed_ind       = gv_flg_on
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_co_prod_price      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        ln_co_prod_price      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  完成品計取得                           ***
    -- ***********************************************
    BEGIN
      SELECT itp.item_id
            ,itp.lot_id lot_id -- ロットID
            ,itp.trans_qty prod_price -- 完成品単価計
      INTO   lr_lot_mst.item_id
            ,lr_lot_mst.lot_id
            ,ln_prod_price
      FROM   ic_tran_pnd     itp -- OPM保留在庫トランザクション
            ,ic_lots_mst     ilm -- ロットマスタ
      WHERE  itp.lot_id        = ilm.lot_id
      AND    itp.reverse_id    IS NULL
      AND    itp.delete_mark   = gn_delete_mark_off
      AND    itp.lot_id        > gn_default_lot_id
      AND    itp.line_type     = gn_prod
      AND    itp.doc_id        = it_batch_id
      AND    itp.completed_ind = gv_flg_on
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lr_lot_mst.item_id := null;
        lr_lot_mst.lot_id  := null;
        ln_prod_price      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        lr_lot_mst.item_id := null;
        lr_lot_mst.lot_id  := null;
        ln_prod_price      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  在庫単価計算                           ***
    -- ***********************************************
    IF (ln_prod_price = 0) THEN
      RAISE skip_expt;
    ELSE
-- 2008/07/10 D.Nihei MOD START
--      lr_lot_mst.attribute7 := NVL(TO_CHAR(ROUND((NVL(ln_invest_price, 0) + NVL(ln_co_prod_price, 0)) / NVL(ln_prod_price, 0), 2)), '0');
      -- 在庫単価 = 投入計 - 副産物 / 出来高数
      lr_lot_mst.attribute7 := NVL(TO_CHAR(ROUND((NVL(ln_invest_price, 0) - NVL(ln_co_prod_price, 0)) / NVL(ln_prod_price, 0), 2)), '0');
-- 2008/07/10 D.Nihei MOD END
    END IF;
--
    update_lot_dff_api(
      iv_update_type      => gv_type_n
     ,ir_ic_lots_mst_in   => lr_lot_mst
     ,ir_ic_lots_mst_out  => lr_lot_mst_out
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    IF (lv_retcode <> gv_status_normal) THEN
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := '在庫単価更新に失敗しました。:' || lv_errmsg;
      RAISE api_expt;
    END IF;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** 正常値 ***
    WHEN skip_expt THEN
      ov_retcode := gv_status_normal;                                           --# 任意 #
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END update_inv_price;
--
  /**********************************************************************************
   * Procedure Name   : UPDATE_TRUST_PRICE
   * Description      : 委託加工費更新関数
   ***********************************************************************************/
  PROCEDURE update_trust_price(
    it_batch_id        IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_trust_price'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '委託加工費更新関数';
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
    ln_invest_actual_qty     NUMBER;   -- 投入品計
    ln_volume_actual_qty     NUMBER;   -- 出来高総数
    ln_trust_price           NUMBER;   -- 委託加工単価
    ln_trust_price_total     NUMBER;   -- 委託加工費
    lb_return_status         BOOLEAN;
    lt_trust_calculate_type  xxpo_price_headers.calculate_type%TYPE;       -- 計算区分
    lt_material_detail_id    gme_material_details.material_detail_id%TYPE; -- 生産原料詳細ID
-- 2008/06/12 D.Nihei ADD START
    lt_vendor_code           xxpo_price_headers.vendor_code%TYPE;          -- 取引先コード
-- 2008/06/12 D.Nihei ADD END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***  投入品計取得                           ***
    -- ***********************************************
    BEGIN
-- 2008/06/02 D.Nihei MOD START
--      SELECT SUM(gmd.actual_qty) invest_actual_qty
--      INTO   ln_invest_actual_qty
--      FROM   gme_material_details      gmd
--            ,xxcmn_item_categories3_v  xicv -- 品目カテゴリ情報VIEW3
--      WHERE  gmd.batch_id          = it_batch_id
--      AND    gmd.item_id           = xicv.item_id
--      AND    gmd.line_type         = gn_material
--      AND    xicv.item_class_code  IN(gv_item_type_mtl
--                                     ,gv_item_type_harf_prod
--                                     ,gv_item_type_prod)
--      AND    gmd.attribute24       IS NULL
      SELECT SUM(xmd.invested_qty) invest_actual_qty
      INTO   ln_invest_actual_qty
      FROM   xxwip_material_detail     xmd  -- 生産原料詳細アドオン
            ,xxcmn_item_categories3_v  xicv -- 品目カテゴリ情報VIEW3
      WHERE  xmd.batch_id          = it_batch_id
      AND    xmd.item_id           = xicv.item_id
      AND    xicv.item_class_code  IN(gv_item_type_mtl
                                     ,gv_item_type_harf_prod
                                     ,gv_item_type_prod)
-- 2008/06/02 D.Nihei MOD END
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_invest_actual_qty      := 0;
--
      WHEN TOO_MANY_ROWS THEN
        ln_invest_actual_qty      := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
-- 2008/06/12 D.Nihei ADD START
    -- ***********************************************
    -- ***  取引先コード取得                       ***
    -- ***********************************************
    BEGIN
      SELECT som.attribute1 vendor_code
      INTO   lt_vendor_code
      FROM   gme_batch_header gbh -- 生産バッチヘッダ
            ,sy_orgn_mst      som -- プラントマスタ
      WHERE  gbh.plant_code = som.orgn_code
      AND    gbh.batch_id   = it_batch_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := '取引先コードが取得できません。';
        RAISE api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
-- 2008/06/12 D.Nihei ADD END
    -- ***********************************************************
    -- ***  委託計算区分・委託加工単価・出来高実績数抽出      ***
    -- ***********************************************************
    BEGIN
      SELECT gmd.material_detail_id            material_detail_id
-- 2008/05/28 D.Nihei MOD START
--            ,xph.calculate_type                trust_calculate_type
            ,NVL(xph.calculate_type, '1')      trust_calculate_type
-- 2008/05/28 D.Nihei MOD END
            ,NVL(TO_NUMBER(gmd.attribute9), 0) trust_price
            ,NVL(gmd.actual_qty, 0)            volume_actual_qty
      INTO   lt_material_detail_id
            ,lt_trust_calculate_type
            ,ln_trust_price
            ,ln_volume_actual_qty
      FROM   gme_material_details      gmd
            ,xxpo_price_headers        xph     -- 仕入・標準単価ヘッダ(アドオン)
-- 2008/05/28 D.Nihei MOD START
--      WHERE  gmd.item_id           = xph.item_id
--      AND    xph.start_date_active<= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
--      AND    xph.end_date_active  >= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
--      AND    xph.futai_code        = '9' -- 付帯コード9
      WHERE  gmd.item_id               = xph.item_id(+)
      AND    xph.start_date_active(+) <= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
      AND    xph.end_date_active(+)   >= NVL(FND_DATE.STRING_TO_DATE(gmd.attribute11, 'YYYY/MM/DD'), TRUNC(SYSDATE))
      AND    xph.futai_code(+)         = '9' -- 付帯コード9
-- 2008/05/28 D.Nihei MOD END
-- 2008/06/12 D.Nihei ADD START
      AND    xph.vendor_code(+)    = lt_vendor_code
-- 2008/11/14 v1.14 D.Nihei DEL START
--      AND    xph.factory_code(+)   = lt_vendor_code
-- 2008/11/14 v1.14 D.Nihei DEL END
-- 2008/06/12 D.Nihei ADD END
-- 2008/06/25 D.Nihei ADD START
      AND    xph.supply_to_code(+)    IS NULL
-- 2008/06/25 D.Nihei ADD END
      AND    gmd.batch_id          = it_batch_id
      AND    gmd.line_type         = gn_prod
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_trust_calculate_type := null;
        ln_trust_price          := 0;
        ln_volume_actual_qty    := 0;
        lv_errmsg               := SQLERRM;
--
      WHEN TOO_MANY_ROWS THEN
        lt_trust_calculate_type := null;
        ln_trust_price          := 0;
        ln_volume_actual_qty    := 0;
        lv_errmsg               := SQLERRM;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ***********************************************
    -- ***  委託加工費算出                         ***
    -- ***********************************************
    -- 委託計算区分がnullの場合
    IF (lt_trust_calculate_type IS NULL) THEN
      lv_errmsg  := lv_errmsg || ':委託加工費更新関数に失敗しました。';
      RAISE api_expt;
--
    -- 委託計算区分が'出来高'の場合
    ELSIF (lt_trust_calculate_type = gv_trust_calc_type_volume) THEN
      ln_trust_price_total := ln_trust_price * ln_volume_actual_qty;
--
    -- 委託計算区分が'投入'の場合
    ELSIF (lt_trust_calculate_type = gv_trust_calc_type_invest) THEN
      ln_trust_price_total := ln_trust_price * ln_invest_actual_qty;
--
    END IF;
--
    -- ***********************************************
    -- ***  委託加工費・委託計算区分更新           ***
    -- ***********************************************
    UPDATE gme_material_details gmd
    SET    gmd.attribute14        = lt_trust_calculate_type
          ,gmd.attribute15        = TO_CHAR(ln_trust_price_total ,'FM999999990.000')
          ,gmd.last_updated_by    = FND_GLOBAL.USER_ID
          ,gmd.last_update_date   = SYSDATE
          ,gmd.last_update_login  = FND_GLOBAL.LOGIN_ID
    WHERE  gmd.material_detail_id = lt_material_detail_id
    ;
--
    -- 正常終了
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** 正常値 ***
    WHEN skip_expt THEN
      ov_retcode := gv_status_normal;                                           --# 任意 #
    --*** API例外 ***
    WHEN api_expt THEN
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END update_trust_price;
--
  /**********************************************************************************
   * Procedure Name   : qt_parameter_check
   * Description      : 入力パラメータチェック(make_qt_inspection 品質検査依頼情報作成 A-1)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_parameter_check(
    it_division          IN  xxwip_qt_inspection.division%TYPE,         -- IN  1.区分
    iv_disposal_div      IN  VARCHAR2,                                  -- IN  2.処理区分
    it_lot_id            IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  3.ロットID
    it_item_id           IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  4.品目ID
    iv_qt_object         IN  VARCHAR2,                                  -- IN  5.対象先
    it_batch_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  6.生産バッチID
    it_batch_po_id       IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  7.明細番号
    it_qty               IN  xxwip_qt_inspection.qty%TYPE,              -- IN  8.数量
    it_prod_dely_date    IN  xxwip_qt_inspection.prod_dely_date%TYPE,   -- IN  9.納入日
    it_vendor_line       IN  xxwip_qt_inspection.vendor_line%TYPE,      -- IN 10.仕入先コード
    it_qt_inspect_req_no IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 11.検査依頼No
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_parameter_check'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    -- 1.区分
    IF (it_division IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 2.処理区分
    IF (iv_disposal_div IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 3.ロットID
    IF (it_lot_id IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 4.品目ID
    IF (it_item_id IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 処理区分が3:削除以外の場合
    IF (iv_disposal_div <> gv_disposal_div_del) THEN
      -- 区分が1:生産の場合のみ
      IF (it_division = gt_division_gme) THEN
        -- 6.生産バッチID
        IF it_batch_id IS NULL THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- 区分が2:発注の場合のみ
      IF (it_division = gt_division_po) THEN
        -- 8.数量
        IF (it_qty IS NULL) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 9.納入日
        IF (it_prod_dely_date IS NULL) THEN
          RAISE global_api_expt;
        END IF;
--
        -- 10.仕入先コード
        IF (it_vendor_line IS NULL) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
    END IF;
--
    -- 区分が5:荒茶製造の場合のみ
    IF (it_division = gt_division_tea) THEN
      -- 5.対象先
      IF (iv_qt_object IS NULL) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 処理区分が1:追加の場合
    IF (iv_disposal_div = gv_disposal_div_ins) THEN
      -- 11.検査依頼No
      IF (it_qt_inspect_req_no IS NOT NULL) THEN
        RAISE global_api_expt;
      END IF;
--
-- 2008/08/25 H.Itou Del Start 変更要求#189
--    -- 処理区分が2:更新、3:削除の場合
--    ELSE
--      -- 11.検査依頼No
--      IF (it_qt_inspect_req_no IS NULL) THEN
--        RAISE global_api_expt;
--      END IF;
-- 2008/08/25 H.Itou Del End
    END IF;
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
  END qt_parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : qt_check_and_lock
   * Description      : データチェック/ロック(make_qt_inspection 品質検査依頼情報作成 A-3)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_check_and_lock(
    iv_disposal_div         IN  VARCHAR2,                                  -- IN  1.処理区分
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  2.ロットID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  3.品目ID
    it_qt_inspect_req_no    IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN  4.検査依頼No
    it_division             IN  xxwip_qt_inspection.division%TYPE,         -- IN  5.区分
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,               -- OUT 1.xxwip_qt_inspectionレコード型
    ov_errbuf               OUT NOCOPY VARCHAR2,                                  -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                                  -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_check_and_lock'; -- プログラム名
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
    ln_temp        NUMBER;   -- カウント格納用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    -- 処理区分が1:追加の場合
    IF (iv_disposal_div = gv_disposal_div_ins) THEN
      --==============================
      -- 品質検査データチェック
      --==============================
      -- 同一キーが品質検査依頼情報アドオンに存在しないかチェック
      SELECT COUNT(xqi.qt_inspect_req_no) cnt
      INTO   ln_temp
      FROM   xxwip_qt_inspection  xqi  -- 品質検査依頼情報アドオン
      WHERE  xqi.lot_id  = it_lot_id   -- ロットID
      AND    xqi.item_id = it_item_id  -- 品目ID
      AND    ROWNUM      = 1
      ;
--
      IF (ln_temp <> 0) THEN
-- 2008/07/02 H.Itou ADD START
        lv_errmsg := 'エラー：処理区分が1:追加で、品質検査依頼情報に同一ロットID、品目IDのデータが存在します。' ||
                     'ロットID：' || it_lot_id ||
                     '品目ID：'   || it_item_id;
        lv_errbuf := lv_errmsg;
-- 2008/07/02 H.Itou ADD END
        -- エラー
        RAISE global_api_expt;
      END IF;
--
    -- 処理区分が2:更新、3:削除の場合
    ELSE
      --==============================
      -- 品質検査データチェック/ロック
      --==============================
      SELECT xqi.test_date1      test_date1     -- 検査日１
            ,xqi.test_date2      test_date2     -- 検査日２
            ,xqi.test_date3      test_date3     -- 検査日３
            ,xqi.use_by_date     use_by_date    -- 賞味期限
            ,xqi.prod_dely_date  prod_dely_date -- 生産/納入日
      INTO   lr_xxwip_qt_inspection.test_date1     -- test_date1
            ,lr_xxwip_qt_inspection.test_date2     -- test_date1
            ,lr_xxwip_qt_inspection.test_date3     -- test_date1
            ,lr_xxwip_qt_inspection.use_by_date    -- use_by_date
            ,lr_xxwip_qt_inspection.prod_dely_date -- prod_dely_date
      FROM   xxwip_qt_inspection  xqi                      -- 品質検査依頼情報アドオン
      WHERE  xqi.qt_inspect_req_no  = it_qt_inspect_req_no -- 検査依頼No
      FOR UPDATE NOWAIT
      ;
--
-- 2009/03/09 H.Itou Del Start 本番障害#32 生産以外は警告も正常終了なので、チェック不要。削除廃止のため、チェック不要。
--      -- 処理区分が2:更新かつ区分が1:生産以外の場合
--      IF (iv_disposal_div = gv_disposal_div_upd)
--      AND(it_division <> gt_division_gme)  THEN
--        -- 検査日のいづれかに入力があるかチェック
--        IF (lr_xxwip_qt_inspection.test_date1 IS NOT NULL)
--        OR (lr_xxwip_qt_inspection.test_date2 IS NOT NULL)
--        OR (lr_xxwip_qt_inspection.test_date3 IS NOT NULL) THEN
----
---- 2008/07/02 H.Itou ADD START
--          ov_errmsg := '警告：処理区分が2:更新かつ区分が1:生産以外で、検査日1 OR 検査日2 OR 検査日3 のいづれかに入力があります。';
--          ov_errbuf := ov_errmsg;
---- 2008/07/02 H.Itou ADD END
--          -- 警告
--          ov_retcode :=gv_status_warn;
--        END IF;
----
--      -- 処理区分が3:削除の場合
--      ELSIF (iv_disposal_div = gv_disposal_div_del) THEN
--        -- 検査日のいづれかに入力があるかチェック
--        IF (lr_xxwip_qt_inspection.test_date1 IS NOT NULL)
--        OR (lr_xxwip_qt_inspection.test_date2 IS NOT NULL)
--        OR (lr_xxwip_qt_inspection.test_date3 IS NOT NULL) THEN
----
---- 2008/07/02 H.Itou ADD START
--          lv_errmsg := 'エラー：処理区分が3:削除で、検査日1 OR 検査日2 OR 検査日3 のいづれかに入力があります。';
--          lv_errbuf := lv_errmsg;
---- 2008/07/02 H.Itou ADD END
--          -- エラー
--          RAISE global_api_expt;
----
--        END IF;
--      END IF;
-- 2009/03/09 H.Itou Del End
--
    -- ====================================
    -- OUTパラメータセット
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspectionレコード型
    END IF;
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
  END qt_check_and_lock;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_gme_data
   * Description      : 生産情報取得(make_qt_inspection 品質検査依頼情報作成 A-4)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_get_gme_data(
    it_batch_id             IN  xxwip_qt_inspection.batch_po_id%TYPE,   -- IN  1.生産バッチID
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,        -- IN  2.ロットID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,       -- IN  3.品目ID
    iv_disposal_div         IN  VARCHAR2,                               -- IN  4.処理区分
-- 2009/02/16 H.Itou Add Start 本番障害#32対応 生産は数量をINパラメータから取得する。
    it_qty                  IN  xxwip_qt_inspection.qty%TYPE,           -- IN  4.数量
-- 2009/02/16 H.Itou Add End
    ir_xxwip_qt_inspection  IN  xxwip_qt_inspection%ROWTYPE,            -- IN  5.xxwip_qt_inspectionレコード型
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,            -- OUT 1.xxwip_qt_inspectionレコード型
    ov_errbuf               OUT NOCOPY VARCHAR2,                               -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                               -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_gme_data'; -- プログラム名
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    --================================
    -- データ取得
    --================================
    SELECT grb.routing_no           vendor_line          -- 仕入先コード/ラインNo
-- 2009/02/16 H.Itou Del Start 本番障害#32対応 生産は数量をINパラメータから取得する。
--          ,gmd.actual_qty           qty                  -- 数量
-- 2009/02/16 H.Itou Del End
-- 2009/02/16 H.Itou Mod Start 本番障害#32対応 ロットマスタの製造日を参照する
--          ,FND_DATE.STRING_TO_DATE(gmd.attribute17,'YYYY/MM/DD')
          ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
-- 2009/02/16 H.Itou Mod End
                                    product_date         -- 製造日
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- 検査L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- 賞味期限
          ,ilm.attribute2           unique_sign          -- 固有記号
    INTO   lr_xxwip_qt_inspection.vendor_line            -- 仕入先コード/ラインNo
-- 2009/02/16 H.Itou Del Start 本番障害#32対応 生産は数量をINパラメータから取得する。
--          ,lr_xxwip_qt_inspection.qty                    -- 数量
-- 2009/02/16 H.Itou Del End
          ,lr_xxwip_qt_inspection.product_date           -- 製造日
          ,lr_xxwip_qt_inspection.inspect_period         -- 検査L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- 賞味期限
          ,lr_xxwip_qt_inspection.unique_sign            -- 固有記号
    FROM   gme_batch_header         gbh                  -- 生産バッチヘッダ
          ,gme_material_details     gmd                  -- 生産原料詳細
          ,ic_tran_pnd              itp                  -- OPM保留在庫トランザクション
          ,gmd_routings_b           grb                  -- 工順マスタ
          ,ic_lots_mst              ilm                  -- OPMロットマスタ
          ,xxcmn_item_mst_v         ximv                 -- OPM品目情報VIEW
    WHERE  gbh.batch_id           = it_batch_id          -- バッチID
    AND    gmd.item_id            = it_item_id           -- 品目ID
    AND    itp.lot_id             = it_lot_id            -- ロットID
    AND    gmd.line_type          IN (gt_line_type_goods
                                     ,gt_line_type_sub)  -- ラインタイプ   IN (1:完成品 2:副産物)
    AND    gbh.attribute4         = gt_duty_status_com   -- 業務ステータス = 7:完了
    AND    itp.completed_ind      = gt_completed_ind_com -- 完了フラグ     = 1:完了
    AND    itp.reverse_id         IS NULL                -- リバースID     = NULL
    AND    gbh.batch_id           = gmd.batch_id         -- バッチID（結合条件）生産バッチヘッダ AND 生産原料詳細
    AND    gmd.material_detail_id = itp.line_id          -- ラインID（結合条件）生産原料詳細 AND OPM保留在庫トランザクション
    AND    gbh.routing_id         = grb.routing_id       -- 工順ID（結合条件）  生産バッチヘッダ AND 工順マスタ
    AND    itp.item_id            = ilm.item_id          -- 品目ID（結合条件）  OPM保留在庫トランザクション AND OPMロットマスタ
    AND    itp.lot_id             = ilm.lot_id           -- ロットID（結合条件）OPM保留在庫トランザクション AND OPMロットマスタ
    AND    itp.item_id            = ximv.item_id         -- 品目ID（結合条件）  OPM保留在庫トランザクション AND OPM品目情報VIEW
    ;
--
    -- ====================================
    -- 品質検査依頼情報レコードに値をセット
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_gme;                 -- 検査種別：1（生産）
    lr_xxwip_qt_inspection.item_id        := it_item_id;                           -- 品目ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;                            -- ロットID
    lr_xxwip_qt_inspection.prod_dely_date := lr_xxwip_qt_inspection.product_date;  -- 生産/納入日
    lr_xxwip_qt_inspection.batch_po_id    := it_batch_id;                          -- 番号
-- 2009/02/16 H.Itou Add Start 本番障害#32対応 生産は数量をINパラメータから取得する。
    lr_xxwip_qt_inspection.qty            := it_qty;                               -- 数量
-- 2009/02/16 H.Itou Add End
--
    -- 処理区分が2:更新の場合
    -- 登録済の品質検査依頼情報の検査日のいづれかに入力がある場合
    IF (iv_disposal_div = gv_disposal_div_upd)
    AND((ir_xxwip_qt_inspection.test_date1 IS NOT NULL)
      OR(ir_xxwip_qt_inspection.test_date2 IS NOT NULL)
      OR(ir_xxwip_qt_inspection.test_date3 IS NOT NULL))THEN
      -- 生産/納入日,賞味期限一致チェック
      IF (ir_xxwip_qt_inspection.prod_dely_date <> lr_xxwip_qt_inspection.prod_dely_date)
      OR (ir_xxwip_qt_inspection.use_by_date    <> lr_xxwip_qt_inspection.use_by_date) THEN
--
-- 2008/07/02 H.Itou ADD START
        ov_errmsg := '警告：処理区分が2:更新かつ区分が1:生産で、検査日1 OR 検査日2 OR 検査日3 のいづれかに入力があり、生産/納入日 OR 賞味期限が変更されています。';
        ov_errbuf := ov_errmsg;
-- 2008/07/02 H.Itou ADD END
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
--
    -- ====================================
    -- OUTパラメータセット
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspectionレコード型
--
  EXCEPTION
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
  END qt_get_gme_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_po_data
   * Description      : 発注情報取得(make_qt_inspection 品質検査依頼情報作成 A-5)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_get_po_data(
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,        -- IN  1.ロットID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,       -- IN  2.品目ID
    it_batch_po_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,   -- IN  3.明細番号
    it_qty                  IN  xxwip_qt_inspection.qty%TYPE,           -- IN  4.数量
    it_prod_dely_date       IN  xxwip_qt_inspection.prod_dely_date%TYPE,-- IN  5.納入日
    it_vendor_line          IN  xxwip_qt_inspection.vendor_line%TYPE,   -- IN  6.仕入先コード
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,            -- OUT 1.xxwip_qt_inspectionレコード型
    ov_errbuf               OUT NOCOPY VARCHAR2,                               -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                               -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_po_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    --================================
    -- データ取得
    --================================
    SELECT FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    product_date         -- 製造日
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- 検査L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- 賞味期限
          ,ilm.attribute2           unique_sign          -- 固有記号
    INTO   lr_xxwip_qt_inspection.product_date           -- 製造日
          ,lr_xxwip_qt_inspection.inspect_period         -- 検査L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- 賞味期限
          ,lr_xxwip_qt_inspection.unique_sign            -- 固有記号
    FROM   ic_lots_mst              ilm                  -- OPMロットマスタ
          ,xxcmn_item_mst_v         ximv                 -- OPM品目情報VIEW
    WHERE  ximv.item_id           = it_item_id           -- 品目ID
    AND    ilm.lot_id             = it_lot_id            -- ロットID
    AND    ilm.item_id            = ximv.item_id         -- 品目ID（結合条件）OPMロットマスタ AND OPM品目マスタVIEW
    ;
--
    -- ====================================
    -- 品質検査依頼情報レコードに値をセット
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;   -- 検査種別：2（発注仕入）
    lr_xxwip_qt_inspection.item_id        := it_item_id;            -- 品目ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;             -- ロットID
    lr_xxwip_qt_inspection.prod_dely_date := it_prod_dely_date;     -- 生産/納入日
    lr_xxwip_qt_inspection.vendor_line    := it_vendor_line;        -- 仕入先コード/ラインNo
    lr_xxwip_qt_inspection.qty            := it_qty;                -- 数量
    lr_xxwip_qt_inspection.batch_po_id    := it_batch_po_id;        -- 番号
--
    -- ====================================
    -- OUTパラメータセット
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspectionレコード型
--
  EXCEPTION
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
  END qt_get_po_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_lot_data
   * Description      : ロット情報取得(make_qt_inspection 品質検査依頼情報作成 A-6)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_get_lot_data(
    it_lot_id                IN  xxwip_qt_inspection.lot_id%TYPE,  -- IN  1.ロットID
    it_item_id               IN  xxwip_qt_inspection.item_id%TYPE, -- IN  2.品目ID
    it_qty                   IN  xxwip_qt_inspection.qty%TYPE,            -- IN  3.数量
    or_xxwip_qt_inspection   OUT NOCOPY xxwip_qt_inspection%ROWTYPE,      -- OUT 1.xxwip_qt_inspectionレコード型
    ov_errbuf                OUT NOCOPY VARCHAR2,                         -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,                         -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2                          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_lot_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    --================================
    -- データ取得
    --================================
    SELECT ilm.attribute8           vendor_line          -- 仕入先コード/ラインNo
          ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    product_date         -- 製造日
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- 検査L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- 賞味期限
          ,ilm.attribute2           unique_sign          -- 固有記号
    INTO   lr_xxwip_qt_inspection.vendor_line            -- 仕入先コード/ラインNo
          ,lr_xxwip_qt_inspection.product_date           -- 製造日
          ,lr_xxwip_qt_inspection.inspect_period         -- 検査L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- 賞味期限
          ,lr_xxwip_qt_inspection.unique_sign            -- 固有記号
    FROM   ic_lots_mst              ilm                  -- OPMロットマスタ
          ,xxcmn_item_mst_v         ximv                 -- OPM品目情報VIEW
    WHERE  ximv.item_id           = it_item_id           -- 品目ID
    AND    ilm.lot_id             = it_lot_id            -- ロットID
    AND    ilm.item_id            = ximv.item_id         -- 品目ID（結合条件）OPMロットマスタ AND OPM品目マスタVIEW
    ;
--
    -- ====================================
    -- 品質検査依頼情報レコードに値をセット
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;                     -- 検査種別：2（発注仕入）
    lr_xxwip_qt_inspection.item_id        := it_item_id;                              -- 品目ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;                               -- ロットID
    lr_xxwip_qt_inspection.prod_dely_date := lr_xxwip_qt_inspection.product_date;     -- 生産/納入日
    lr_xxwip_qt_inspection.qty            := it_qty;                                  -- 数量
    lr_xxwip_qt_inspection.batch_po_id    := NULL;                                    -- 番号
--
    -- ====================================
    -- OUTパラメータセット
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspectionレコード型
--
  EXCEPTION
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
  END qt_get_lot_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_vendor_supply_data
   * Description      : 外注出来高情報取得(make_qt_inspection 品質検査依頼情報作成 A-7)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_get_vendor_supply_data(
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,   -- IN  1.ロットID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE,  -- IN  2.品目ID
-- 2009/02/27 H.Itou Add Start 本番障害#32再対応
    it_qty                  IN  xxwip_qt_inspection.qty%TYPE,      -- IN  3.数量
-- 2009/02/27 H.Itou Add End
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,       -- OUT 1.xxwip_qt_inspectionレコード型
    ov_errbuf               OUT NOCOPY VARCHAR2,                          -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                          -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                           -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_vendor_supply_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    --================================
    -- データ取得
    --================================
    SELECT xvst.vendor_code        vendor_line          -- 仕入先コード/ラインNo
-- 2009/02/27 H.Itou Del Start 本番障害#32再対応
--          ,DECODE (
--             xvst.txns_type
--            ,gt_txns_type_aite , xvst.quantity            -- 処理タイプ：1（相手先在庫）の場合 数量
--            ,gt_txns_type_sok  , xvst.corrected_quantity  -- 処理タイプ：2（即時仕入）の場合 訂正数量
--           )                        qty                 -- 数量
-- 2009/02/27 H.Itou Del End
          ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    prod_dely_date      -- 生産/納入日
          ,xvst.producted_date      producted_date      -- 製造日
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period      -- 検査L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date         -- 賞味期限
          ,ilm.attribute2           unique_sign         -- 固有記号
    INTO   lr_xxwip_qt_inspection.vendor_line           -- 仕入先コード/ラインNo
-- 2009/02/27 H.Itou Del Start 本番障害#32再対応
--          ,lr_xxwip_qt_inspection.qty                   -- 数量
-- 2009/02/27 H.Itou Del End
          ,lr_xxwip_qt_inspection.prod_dely_date        -- 生産/納入日
          ,lr_xxwip_qt_inspection.product_date          -- 製造日
          ,lr_xxwip_qt_inspection.inspect_period        -- 検査L/T
          ,lr_xxwip_qt_inspection.use_by_date           -- 賞味期限
          ,lr_xxwip_qt_inspection.unique_sign           -- 固有記号
    FROM   xxpo_vendor_supply_txns     xvst             -- 外注出来高実績アドオン
          ,ic_lots_mst                 ilm              -- OPMロットマスタ
          ,xxcmn_item_mst_v            ximv             -- OPM品目情報VIEW
    WHERE  xvst.item_id           = it_item_id          -- 品目ID
    AND    xvst.lot_id            = it_lot_id           -- ロットID
    AND    xvst.item_id           = ximv.item_id        -- 品目ID（結合条件）外注出来高実績アドオン AND OPM品目マスタVIEW
    AND    xvst.lot_id            = ilm.lot_id          -- 品目ID（結合条件）外注出来高実績アドオン AND OPMロットマスタ
    AND    xvst.item_id           = ilm.item_id         -- 品目ID（結合条件）外注出来高実績アドオン AND OPMロットマスタ
-- 2015/10/29 S.Yamashita Add Start E_本稼動_13238対応
    AND    ROWNUM                 = 1                   -- 1件に絞るため
-- 2015/10/29 S.Yamashita Add End
    ;
--
    -- ====================================
    -- 品質検査依頼情報レコードに値をセット
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;                     -- 検査種別：2（発注仕入）
    lr_xxwip_qt_inspection.item_id        := it_item_id;                              -- 品目ID
    lr_xxwip_qt_inspection.lot_id         := it_lot_id;                               -- ロットID
    lr_xxwip_qt_inspection.batch_po_id    := NULL;                                    -- 番号
-- 2009/02/27 H.Itou Add Start 本番障害#32再対応
    lr_xxwip_qt_inspection.qty            := it_qty;                                  -- 数量
-- 2009/02/27 H.Itou Add End
--
    -- ====================================
    -- OUTパラメータセット
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspectionレコード型
--
  EXCEPTION
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
  END qt_get_vendor_supply_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_get_namaha_prod_data
   * Description      : 荒茶製造情報取得(make_qt_inspection 品質検査依頼情報作成 A-2)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_get_namaha_prod_data(
    it_lot_id               IN  xxwip_qt_inspection.lot_id%TYPE,  -- IN  1.ロットID
    it_item_id              IN  xxwip_qt_inspection.item_id%TYPE, -- IN  2.品目ID
    iv_qt_object            IN  VARCHAR2,                         -- IN  3.対象先
-- 2009/02/27 H.Itou Add Start 本番障害#32再対応
    it_qty                  IN  xxwip_qt_inspection.qty%TYPE,     -- IN  4.数量
-- 2009/02/27 H.Itou Add End
    or_xxwip_qt_inspection  OUT NOCOPY xxwip_qt_inspection%ROWTYPE,      -- OUT 1.xxwip_qt_inspectionレコード型
    ov_errbuf               OUT NOCOPY VARCHAR2,                         -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                         -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_get_namaha_prod_data'; -- プログラム名
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
    lr_xxwip_qt_inspection       xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
    lr_xxwip_qt_inspection_temp  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    --================================
    -- 荒茶データ取得
    --================================
    SELECT DECODE (
             iv_qt_object
            ,gv_qt_object_tea , xnpt.aracha_item_id      -- 対象先：1（荒茶）の場合 荒茶品目ID
            ,gv_qt_object_bp1 , xnpt.byproduct1_item_id  -- 対象先：2（副産物１）の場合 副産物１品目ID
            ,gv_qt_object_bp2 , xnpt.byproduct2_item_id  -- 対象先：3（副産物２）の場合 副産物２品目ID
            ,gv_qt_object_bp3 , xnpt.byproduct3_item_id  -- 対象先：4（副産物３）の場合 副産物３品目ID
           )                                   item_id    -- 品目ID
          ,DECODE (
             iv_qt_object
            ,gv_qt_object_tea , xnpt.aracha_lot_id      -- 対象先：1（荒茶）の場合 荒茶ロットID
            ,gv_qt_object_bp1 , xnpt.byproduct1_lot_id  -- 対象先：2（副産物１）の場合 副産物１ロットID
            ,gv_qt_object_bp2 , xnpt.byproduct2_lot_id  -- 対象先：3（副産物２）の場合 副産物２ロットID
            ,gv_qt_object_bp3 , xnpt.byproduct3_lot_id  -- 対象先：4（副産物３）の場合 副産物３ロットID
           )                                   lot_id     -- ロットID
-- 2009/02/27 H.Itou Del Start 本番障害#32再対応
--          ,DECODE (
--             iv_qt_object
--            ,gv_qt_object_tea , xnpt.aracha_quantity      -- 対象先：1（荒茶）の場合 荒茶数量
--            ,gv_qt_object_bp1 , xnpt.byproduct1_quantity  -- 対象先：2（副産物１）の場合 副産物１数量
--            ,gv_qt_object_bp2 , xnpt.byproduct2_quantity  -- 対象先：3（副産物２）の場合 副産物２数量
--            ,gv_qt_object_bp3 , xnpt.byproduct3_quantity  -- 対象先：4（副産物３）の場合 副産物３数量
--           )                                   qty        -- 数量
-- 2009/02/27 H.Itou Del End
    INTO   lr_xxwip_qt_inspection.item_id        -- 品目ID
          ,lr_xxwip_qt_inspection.lot_id         -- ロットID
-- 2009/02/27 H.Itou Del Start 本番障害#32再対応
--          ,lr_xxwip_qt_inspection.qty            -- 数量
-- 2009/02/27 H.Itou Del End
    FROM   xxpo_namaha_prod_txns      xnpt       -- 生葉実績アドオン
    WHERE  xnpt.aracha_item_id = it_item_id      -- 品目ID
    AND    xnpt.aracha_lot_id  = it_lot_id       -- ロットID
    ;
--
    --================================
    -- ロットデータ取得
    --================================
    SELECT ilm.attribute8           vendor_line          -- 仕入先コード/ラインNo
          ,FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                    product_date         -- 製造日
          ,TO_NUMBER(ximv.inspect_lot)
                                    inspect_period       -- 検査L/T
          ,FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                    use_by_date          -- 賞味期限
          ,ilm.attribute2           unique_sign          -- 固有記号
    INTO   lr_xxwip_qt_inspection.vendor_line            -- 仕入先コード/ラインNo
          ,lr_xxwip_qt_inspection.product_date           -- 製造日
          ,lr_xxwip_qt_inspection.inspect_period         -- 検査L/T
          ,lr_xxwip_qt_inspection.use_by_date            -- 賞味期限
          ,lr_xxwip_qt_inspection.unique_sign            -- 固有記号
    FROM   ic_lots_mst              ilm                  -- OPMロットマスタ
          ,xxcmn_item_mst_v         ximv                 -- OPM品目情報VIEW
-- 2008/07/02 H.Itou DEL START
--    WHERE  ximv.item_id           = it_item_id           -- 品目ID
--    AND    ilm.lot_id             = it_lot_id            -- ロットID
-- 2008/07/02 H.Itou DEL END
-- 2008/07/02 H.Itou ADD START
    WHERE  ximv.item_id           = lr_xxwip_qt_inspection.item_id   -- 品目ID
    AND    ilm.lot_id             = lr_xxwip_qt_inspection.lot_id    -- ロットID
-- 2008/07/02 H.Itou ADD END
    AND    ilm.item_id            = ximv.item_id         -- 品目ID（結合条件）OPMロットマスタ AND OPM品目マスタVIEW
    ;
--
    -- ====================================
    -- 品質検査依頼情報レコードに値をセット
    -- ====================================
    lr_xxwip_qt_inspection.inspect_class  := gt_inspect_class_po;                     -- 検査種別：2（発注仕入）
    lr_xxwip_qt_inspection.prod_dely_date := lr_xxwip_qt_inspection.product_date;     -- 生産/納入日
    lr_xxwip_qt_inspection.batch_po_id    := NULL;                                    -- 番号
-- 2009/02/27 H.Itou Add Start 本番障害#32再対応
    lr_xxwip_qt_inspection.qty            := it_qty;                                  -- 数量
-- 2009/02/27 H.Itou Add End
--
    -- ====================================
    -- OUTパラメータセット
    -- ====================================
    or_xxwip_qt_inspection := lr_xxwip_qt_inspection;  -- xxwip_qt_inspectionレコード型
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
  END qt_get_namaha_prod_data;
--
  /**********************************************************************************
   * Procedure Name   : qt_inspection_ins
   * Description      : 品質検査依頼情報登録/更新(make_qt_inspection 品質検査依頼情報作成 A-9)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_inspection_ins(
    it_division             IN  xxwip_qt_inspection.division%TYPE,         -- IN 1.区分
    iv_disposal_div         IN  VARCHAR2,                                  -- IN 2.処理区分
    it_qt_inspect_req_no    IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 3.検査依頼No
    ior_xxwip_qt_inspection IN  OUT xxwip_qt_inspection%ROWTYPE,           -- IN OUT 4.xxwip_qt_inspectionレコード型
    ov_errbuf               OUT NOCOPY VARCHAR2,                          -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                          -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                           -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_inspection_ins'; -- プログラム名
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
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    lr_xxwip_qt_inspection := ior_xxwip_qt_inspection;  -- IN パラメータレコードセット
--
    -- ====================================
    -- 品質検査依頼情報レコードに値をセット
    -- ====================================
    lr_xxwip_qt_inspection.qt_effect1             := gt_qt_status_mi;                   -- 結果１ 10:未判定
    lr_xxwip_qt_inspection.qt_effect2             := gt_qt_status_mi;                   -- 結果２ 10:未判定
    lr_xxwip_qt_inspection.qt_effect3             := gt_qt_status_mi;                   -- 結果３ 10:未判定
    lr_xxwip_qt_inspection.division               := it_division;                       -- 区分
    lr_xxwip_qt_inspection.last_updated_by        := FND_GLOBAL.USER_ID;                -- 最終更新者
    lr_xxwip_qt_inspection.last_update_date       := SYSDATE;                           -- 最終更新日
    lr_xxwip_qt_inspection.last_update_login      := FND_GLOBAL.LOGIN_ID;               -- 最終更新ログイン
    lr_xxwip_qt_inspection.request_id             := FND_GLOBAL.CONC_REQUEST_ID;        -- 要求ID
    lr_xxwip_qt_inspection.program_application_id := FND_GLOBAL.PROG_APPL_ID;           -- コンカレント・プログラム・アプリケーションID
    lr_xxwip_qt_inspection.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;        -- コンカレント・プログラムID
    lr_xxwip_qt_inspection.program_update_date    := SYSDATE;                           -- プログラム更新日
--
    -- 処理区分：1（追加）の場合
    IF (iv_disposal_div = gv_disposal_div_ins) THEN
      -- ====================================
      -- 品質検査依頼情報レコードに値をセット
      -- ====================================
      SELECT xxwip_qt_inspect_req_no_s1.NEXTVAL  qt_inspect_req_no -- 検査依頼No
      INTO   lr_xxwip_qt_inspection.qt_inspect_req_no
      FROM   DUAL;
      lr_xxwip_qt_inspection.created_by     := FND_GLOBAL.USER_ID; -- 作成者
      lr_xxwip_qt_inspection.creation_date  := SYSDATE;            -- 作成日
--
      -- ==================================
      -- 登録処理
      -- ==================================
      INSERT INTO xxwip_qt_inspection xqi(  -- 品質検査依頼情報アドオン
         xqi.qt_inspect_req_no    -- 検査依頼No
        ,xqi.inspect_class        -- 検査種別
        ,xqi.item_id              -- 品目ID
        ,xqi.lot_id               -- ロットID
        ,xqi.vendor_line          -- 仕入先コード/ラインNo
        ,xqi.product_date         -- 製造日
        ,xqi.qty                  -- 数量
        ,xqi.prod_dely_date       -- 生産/納入日
        ,xqi.inspect_due_date1    -- 検査予定日１
        ,xqi.qt_effect1           -- 結果１
        ,xqi.inspect_due_date2    -- 検査予定日２
        ,xqi.qt_effect2           -- 結果２
        ,xqi.inspect_due_date3    -- 検査予定日３
        ,xqi.qt_effect3           -- 結果３
        ,xqi.inspect_period       -- 検査期間
        ,xqi.use_by_date          -- 賞味期限
        ,xqi.unique_sign          -- 固有記号
        ,xqi.division             -- 区分
        ,xqi.batch_po_id          -- 番号
        ,xqi.created_by           -- 作成者
        ,xqi.creation_date        -- 作成日
        ,xqi.last_updated_by      -- 最終更新者
        ,xqi.last_update_date     -- 最終更新日
        ,xqi.last_update_login    -- 最終更新ログイン
        ,xqi.request_id           -- 要求ID
        ,xqi.program_application_id  -- コンカレント・プログラム・アプリケーションID
        ,xqi.program_id              -- コンカレント・プログラムID
        ,xqi.program_update_date     -- プログラム更新日
        )
      VALUES(
         lr_xxwip_qt_inspection.qt_inspect_req_no    -- 検査依頼No
        ,lr_xxwip_qt_inspection.inspect_class        -- 検査種別
        ,lr_xxwip_qt_inspection.item_id              -- 品目ID
        ,lr_xxwip_qt_inspection.lot_id               -- ロットID
        ,lr_xxwip_qt_inspection.vendor_line          -- 仕入先コード/ラインNo
        ,lr_xxwip_qt_inspection.product_date         -- 製造日
        ,lr_xxwip_qt_inspection.qty                  -- 数量
        ,lr_xxwip_qt_inspection.prod_dely_date       -- 生産/納入日
        ,lr_xxwip_qt_inspection.inspect_due_date1    -- 検査予定日１
        ,lr_xxwip_qt_inspection.qt_effect1           -- 結果１
        ,lr_xxwip_qt_inspection.inspect_due_date2    -- 検査予定日２
        ,lr_xxwip_qt_inspection.qt_effect2           -- 結果２
        ,lr_xxwip_qt_inspection.inspect_due_date3    -- 検査予定日３
        ,lr_xxwip_qt_inspection.qt_effect3           -- 結果３
        ,lr_xxwip_qt_inspection.inspect_period       -- 検査期間
        ,lr_xxwip_qt_inspection.use_by_date          -- 賞味期限
        ,lr_xxwip_qt_inspection.unique_sign          -- 固有記号
        ,lr_xxwip_qt_inspection.division             -- 区分
        ,lr_xxwip_qt_inspection.batch_po_id          -- 番号
        ,lr_xxwip_qt_inspection.created_by           -- 作成者
        ,lr_xxwip_qt_inspection.creation_date        -- 作成日
        ,lr_xxwip_qt_inspection.last_updated_by      -- 最終更新者
        ,lr_xxwip_qt_inspection.last_update_date     -- 最終更新日
        ,lr_xxwip_qt_inspection.last_update_login    -- 最終更新ログイン
        ,lr_xxwip_qt_inspection.request_id           -- 要求ID
        ,lr_xxwip_qt_inspection.program_application_id  -- コンカレント・プログラム・アプリケーションID
        ,lr_xxwip_qt_inspection.program_id              -- コンカレント・プログラムID
        ,lr_xxwip_qt_inspection.program_update_date     -- プログラム更新日
      );
--
    -- 処理区分：2（更新）の場合
    ELSIF (iv_disposal_div = gv_disposal_div_upd) THEN
      -- ====================================
      -- 品質検査依頼情報レコードに値をセット
      -- ====================================
      lr_xxwip_qt_inspection.qt_inspect_req_no := it_qt_inspect_req_no; -- 検査依頼No
--
      -- ==================================
      -- 更新処理
      -- ==================================
      UPDATE xxwip_qt_inspection    xqi -- 品質検査依頼情報アドオン
      SET    xqi.inspect_class           = lr_xxwip_qt_inspection.inspect_class          -- 検査種別
            ,xqi.item_id                 = lr_xxwip_qt_inspection.item_id                -- 品目ID
            ,xqi.lot_id                  = lr_xxwip_qt_inspection.lot_id                 -- ロットID
            ,xqi.vendor_line             = lr_xxwip_qt_inspection.vendor_line            -- 仕入先コード/ラインNo
            ,xqi.product_date            = lr_xxwip_qt_inspection.product_date           -- 製造日
-- 2009/02/27 H.Itou Mod Start 本番障害#32再対応 すべての場合で数量を加算する。
---- 2009/02/16 H.Itou Mod Start 本番障害#32対応
----            ,xqi.qty                     = lr_xxwip_qt_inspection.qty                    -- 数量
--            ,xqi.qty
--               = CASE
--                   --  1:生産、2:発注、3:ロット情報の場合は、前回登録との差分が渡されるので、数量加算
--                   WHEN (it_division IN (gt_division_gme, gt_division_po, gt_division_lot)) THEN
--                     xqi.qty + lr_xxwip_qt_inspection.qty          -- 前回数量＋今回数量
----
--                   -- 上記以外は実数が渡されるので、そのまま更新
--                   ELSE
--                     lr_xxwip_qt_inspection.qty                    -- 今回数量
--                 END
---- 2009/02/16 H.Itou Mod End
             -- 数量 ＝ 前回数量＋今回数量（検査ロットの場合は数量がNULLだが、NVLせず、NULLのままでOK。品質検査画面で表示できなくなるため）
            ,xqi.qty                     = xqi.qty + lr_xxwip_qt_inspection.qty
-- 2009/02/27 H.Itou Mod End
            ,xqi.prod_dely_date          = lr_xxwip_qt_inspection.prod_dely_date         -- 生産/納入日
-- 2008/07/14 H.Itou DEL START 検査予定日・結果は更新不要
--            ,xqi.inspect_due_date1       = lr_xxwip_qt_inspection.inspect_due_date1      -- 検査予定日１
--            ,xqi.qt_effect1              = lr_xxwip_qt_inspection.qt_effect1             -- 結果１
--            ,xqi.inspect_due_date2       = lr_xxwip_qt_inspection.inspect_due_date2      -- 検査予定日２
--            ,xqi.qt_effect2              = lr_xxwip_qt_inspection.qt_effect2             -- 結果２
--            ,xqi.inspect_due_date3       = lr_xxwip_qt_inspection.inspect_due_date3      -- 検査予定日３
--            ,xqi.qt_effect3              = lr_xxwip_qt_inspection.qt_effect3             -- 結果３
--            ,xqi.inspect_period          = lr_xxwip_qt_inspection.inspect_period         -- 検査期間
-- 2008/07/14 H.Itou DEL END 検査予定日・結果は更新不要
            ,xqi.use_by_date             = lr_xxwip_qt_inspection.use_by_date            -- 賞味期限
            ,xqi.unique_sign             = lr_xxwip_qt_inspection.unique_sign            -- 固有記号
            ,xqi.division                = lr_xxwip_qt_inspection.division               -- 区分
            ,xqi.batch_po_id             = lr_xxwip_qt_inspection.batch_po_id            -- 番号
            ,xqi.last_updated_by         = lr_xxwip_qt_inspection.last_updated_by        -- 最終更新者
            ,xqi.last_update_date        = lr_xxwip_qt_inspection.last_update_date       -- 最終更新日
            ,xqi.last_update_login       = lr_xxwip_qt_inspection.last_update_login      -- 最終更新ログイン
            ,xqi.request_id              = lr_xxwip_qt_inspection.request_id             -- 要求ID
            ,xqi.program_application_id  = lr_xxwip_qt_inspection.program_application_id -- コンカレント・プログラム・アプリケーションID
            ,xqi.program_id              = lr_xxwip_qt_inspection.program_id             -- コンカレント・プログラムID
            ,xqi.program_update_date     = lr_xxwip_qt_inspection.program_update_date    -- プログラム更新日
      WHERE xqi.qt_inspect_req_no        = lr_xxwip_qt_inspection.qt_inspect_req_no      -- 検査依頼No
      ;
    END IF;
--
    -- ====================================
    -- OUTパラメータセット
    -- ====================================
    ior_xxwip_qt_inspection := lr_xxwip_qt_inspection;
--
  EXCEPTION
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
  END qt_inspection_ins;
--
  /**********************************************************************************
   * Procedure Name   : qt_update_lot_dff_api
   * Description      : ロットマスタ更新(make_qt_inspection 品質検査依頼情報作成 A-11)(非公開)
  /*********************************************************************************/
  PROCEDURE qt_update_lot_dff_api(
    ir_xxwip_qt_inspection  IN xxwip_qt_inspection%ROWTYPE, -- IN 1.xxwip_qt_inspectionレコード型
-- 2009/02/16 H.Itou Add Start 本番障害#1096対応 ロットステータスを初期化するかを判断するため、処理区分をパラメータに追加
    iv_disposal_div         IN  VARCHAR2,                                  -- IN 2.処理区分
-- 2009/02/16 H.Itou Add End
    ov_errbuf               OUT NOCOPY VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qt_update_lot_dff_api'; -- プログラム名
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
    ln_message_count      NUMBER;         -- メッセージカウント
    lv_message_list       VARCHAR2(200);  -- メッセージリスト

--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_xxwip_qt_inspection  xxwip_qt_inspection%ROWTYPE;  -- xxwip_qt_inspectionレコード型
    lr_ic_lots_mst          ic_lots_mst%ROWTYPE;          -- ロットマスタレコード型
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    lr_xxwip_qt_inspection := ir_xxwip_qt_inspection;  -- IN パラメータレコードセット
--
    -- ====================================
    -- OPMロットマスタレコードに値をセット
    -- ====================================
    lr_ic_lots_mst.last_updated_by        := FND_GLOBAL.USER_ID;                -- 最終更新者
    lr_ic_lots_mst.last_update_date       := SYSDATE;                           -- 最終更新日
    lr_ic_lots_mst.last_update_login      := FND_GLOBAL.LOGIN_ID;               -- 最終更新ログイン
    lr_ic_lots_mst.request_id             := FND_GLOBAL.CONC_REQUEST_ID;        -- 要求ID
    lr_ic_lots_mst.program_application_id := FND_GLOBAL.PROG_APPL_ID;           -- コンカレント・プログラム・アプリケーションID
    lr_ic_lots_mst.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;        -- コンカレント・プログラムID
    lr_ic_lots_mst.program_update_date    := SYSDATE;                           -- プログラム更新日
--
    -- ===============================
    -- OPMロットマスタロック
    -- ===============================
    SELECT ilm.item_id                               item_id
          ,ilm.lot_id                                lot_id
          ,ilm.vendor_lot_no                         vendor_lot_no
          ,ilm.expire_date                           expire_date
          ,ilm.attribute1                            attribute1
          ,ilm.attribute2                            attribute2
          ,ilm.attribute3                            attribute3
          ,ilm.attribute4                            attribute4
          ,ilm.attribute5                            attribute5
          ,ilm.attribute6                            attribute6
          ,ilm.attribute7                            attribute7
          ,ilm.attribute8                            attribute8
          ,ilm.attribute9                            attribute9
          ,ilm.attribute10                           attribute10
          ,ilm.attribute11                           attribute11
          ,ilm.attribute12                           attribute12
          ,ilm.attribute13                           attribute13
          ,ilm.attribute14                           attribute14
          ,ilm.attribute15                           attribute15
          ,ilm.attribute16                           attribute16
          ,ilm.attribute17                           attribute17
          ,ilm.attribute18                           attribute18
          ,ilm.attribute19                           attribute19
          ,ilm.attribute20                           attribute20
          ,ilm.attribute21                           attribute21
          ,lr_xxwip_qt_inspection.qt_inspect_req_no  attribute22
-- 2009/02/16 H.Itou Mod Start 本番障害#1096対応 新規の場合、ロットステータスを10:未判定に初期化。
--          ,ilm.attribute23                           attribute23
          ,CASE
             -- 新規の場合･･･ロットステータスを未判定に初期化
             WHEN (iv_disposal_div = gv_disposal_div_ins) THEN
               gt_qt_status_mi
--
             -- 新規でない場合･･･変更しない。
             ELSE
               ilm.attribute23
           END                                       attribute23
-- 2009/02/16 H.Itou Mod End
          ,ilm.attribute24                           attribute24
          ,ilm.attribute25                           attribute25
          ,ilm.attribute26                           attribute26
          ,ilm.attribute27                           attribute27
          ,ilm.attribute28                           attribute28
          ,ilm.attribute29                           attribute29
          ,ilm.attribute30                           attribute30
    INTO   lr_ic_lots_mst.item_id
          ,lr_ic_lots_mst.lot_id
          ,lr_ic_lots_mst.vendor_lot_no
          ,lr_ic_lots_mst.expire_date
          ,lr_ic_lots_mst.attribute1
          ,lr_ic_lots_mst.attribute2
          ,lr_ic_lots_mst.attribute3
          ,lr_ic_lots_mst.attribute4
          ,lr_ic_lots_mst.attribute5
          ,lr_ic_lots_mst.attribute6
          ,lr_ic_lots_mst.attribute7
          ,lr_ic_lots_mst.attribute8
          ,lr_ic_lots_mst.attribute9
          ,lr_ic_lots_mst.attribute10
          ,lr_ic_lots_mst.attribute11
          ,lr_ic_lots_mst.attribute12
          ,lr_ic_lots_mst.attribute13
          ,lr_ic_lots_mst.attribute14
          ,lr_ic_lots_mst.attribute15
          ,lr_ic_lots_mst.attribute16
          ,lr_ic_lots_mst.attribute17
          ,lr_ic_lots_mst.attribute18
          ,lr_ic_lots_mst.attribute19
          ,lr_ic_lots_mst.attribute20
          ,lr_ic_lots_mst.attribute21
          ,lr_ic_lots_mst.attribute22
          ,lr_ic_lots_mst.attribute23
          ,lr_ic_lots_mst.attribute24
          ,lr_ic_lots_mst.attribute25
          ,lr_ic_lots_mst.attribute26
          ,lr_ic_lots_mst.attribute27
          ,lr_ic_lots_mst.attribute28
          ,lr_ic_lots_mst.attribute29
          ,lr_ic_lots_mst.attribute30
    FROM   ic_lots_mst                   ilm              -- OPMロットマスタ
    WHERE  ilm.item_id = lr_xxwip_qt_inspection.item_id   -- 品目ID
    AND    ilm.lot_id  = lr_xxwip_qt_inspection.lot_id    -- ロットID
    FOR UPDATE NOWAIT
    ;
--
    -- ===============================
    -- OPMロットマスタDFF更新
    -- ===============================
    GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF(
      p_api_version       => gn_api_version             -- IN  NUMBER
     ,p_init_msg_list     => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_commit            => FND_API.G_FALSE            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
     ,p_validation_level  => FND_API.G_VALID_LEVEL_FULL -- IN  NUMBER   DEFAULT FND_API.G_VALID_LEVEL_FULL
     ,x_return_status     => lv_retcode                 -- OUT NOCOPY       VARCHAR2
     ,x_msg_count         => ln_message_count           -- OUT NOCOPY       NUMBER
     ,x_msg_data          => lv_message_list            -- OUT NOCOPY       VARCHAR2
     ,p_lot_rec           => lr_ic_lots_mst             -- IN  ic_lots_mst%ROWTYPE
    );
--
    -- 成功以外の場合、エラー
    IF (lv_retcode <> FND_API.G_RET_STS_SUCCESS)THEN
      ov_retcode := gv_status_error;
    END IF;
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
  END qt_update_lot_dff_api;
--
  /**********************************************************************************
   * Procedure Name   : get_business_date
   * Description      : 営業日取得
  /*********************************************************************************/
  PROCEDURE get_business_date(
    id_date               IN  DATE,        -- IN  1.日付 必須
    in_period             IN  NUMBER,      -- IN  2.期間 必須 マイナスはエラー。
    od_business_date      OUT NOCOPY DATE,        -- OUT 1.日付の○○営業日後の日付
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_business_date'; -- プログラム名
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
    cv_gmems_default_orgn  VARCHAR2(30) := 'GEMMS_DEFAULT_ORGN';  -- プロファイルオプション(GMA: デフォルト組織)
--
    -- *** ローカル変数 ***
    lv_orgn_code      fnd_profile_option_values.profile_option_value%TYPE;  -- 組織コード
    ln_cnt            NUMBER := 0;   -- カウント
    ld_business_date  DATE;          -- 日付の○○営業日後の日付
    lv_errm           VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
    CURSOR mr_shcl_dtl_cur IS
      SELECT msd.calendar_date -- カレンダ日付
      FROM   mr_shcl_dtl msd   -- 製造カレンダー明細
            ,sy_orgn_mst som   -- OPMプラントマスタ
      WHERE  som.orgn_code      = lv_orgn_code               -- オルグコード
      AND    msd.calendar_id    = som.mfg_calendar_id        -- カレンダーID（結合条件）
      AND    msd.delete_mark    = 0                          -- 削除マーク = 0 (稼働日)
-- 2009/02/27 H.Itou Mod Start
--      AND    msd.calendar_date >= id_date                    -- カレンダ日付
      AND    msd.calendar_date >= TRUNC(id_date)             -- カレンダ日付
-- 2009/02/27 H.Itou Mod End
      ORDER BY calendar_date asc
    ;
--
    -- *** ローカル・レコード ***
--
  BEGIN
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
    -- ================================
    -- 入力エラーチェック
    -- ================================
    IF (id_date IS NULL) THEN -- 日付NULLはエラー
-- 2008/07/02 H.Itou ADD START
      lv_errmsg := 'エラー：生産/納入日がNULLです。';
      lv_errbuf := lv_errmsg;
-- 2008/07/02 H.Itou ADD END
      RAISE global_api_expt;
    END IF;
--
    IF (in_period IS NULL) OR (in_period < 0) THEN -- 期間未入力または0未満はエラー
-- 2008/07/02 H.Itou ADD START
      lv_errmsg := 'エラー：検査期間がNULLかマイナス値です。';
      lv_errbuf := lv_errmsg;
-- 2008/07/02 H.Itou ADD END
      RAISE global_api_expt;
    END IF;
--
    -- ================================
    -- プロファイル取得
    -- ================================
    lv_orgn_code := FND_PROFILE.VALUE(cv_gmems_default_orgn);
--
    IF (lv_orgn_code IS NULL) THEN -- プロファイルが取得できない場合はエラー
-- 2008/07/02 H.Itou ADD START
      lv_errmsg := 'エラー：プロファイル「GEMMS_DEFAULT_ORGN(GMA: デフォルト組織)」を取得できません。';
      lv_errbuf := lv_errmsg;
-- 2008/07/02 H.Itou ADD END
      RAISE global_api_expt;
    END IF;
--
    --================================
    -- データ取得
    --================================
    <<mr_shcl_dtl_loop>>
    FOR mr_shcl_dtl_rec IN mr_shcl_dtl_cur LOOP
      IF ln_cnt = in_period THEN
        ld_business_date := mr_shcl_dtl_rec.calendar_date;
        EXIT;
      END If;
      ln_cnt := ln_cnt + 1;
    END LOOP mr_shcl_dtl_loop;
--
    IF (ld_business_date IS NULL) THEN -- 日付が取れなかった場合はエラー
-- 2008/07/02 H.Itou ADD START
      lv_errmsg := 'エラー：mr_shcl_dtl(製造カレンダー明細)からデータを取得できません。' ||
                   'orgn_code：' || lv_orgn_code ||
                   'calendar_date：' || id_date;
      lv_errbuf := lv_errmsg;
-- 2008/07/02 H.Itou ADD END
      RAISE global_api_expt;
    END IF;
--
   od_business_date := ld_business_date;
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
  END get_business_date;
--
  /**********************************************************************************
   * Function Name    : make_qt_inspection
   * Description      : 品質検査依頼情報作成
   ***********************************************************************************/
  -- 品質検査依頼情報作成
  PROCEDURE make_qt_inspection(
    it_division          IN  xxwip_qt_inspection.division%TYPE,         -- IN  1.区分         必須（1:生産 2:発注 3:ロット情報 4:外注出来高 5:荒茶製造）
    iv_disposal_div      IN  VARCHAR2,                                  -- IN  2.処理区分     必須（1:追加 2:更新 3:削除）
    it_lot_id            IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  3.ロットID     必須
    it_item_id           IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  4.品目ID       必須
    iv_qt_object         IN  VARCHAR2,                                  -- IN  5.対象先       区分:5のみ必須（1:荒茶品目 2:副産物１ 3:副産物２ 4:副産物３）
    it_batch_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  6.生産バッチID 処理区分3以外かつ区分:1のみ必須
    it_batch_po_id       IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  7.明細番号     処理区分3以外かつ区分:2のみ必須
    it_qty               IN  xxwip_qt_inspection.qty%TYPE,              -- IN  8.数量         処理区分3以外かつ区分:1,2必須
    it_prod_dely_date    IN  xxwip_qt_inspection.prod_dely_date%TYPE,   -- IN  9.納入日       処理区分3以外かつ区分:2のみ必須
    it_vendor_line       IN  xxwip_qt_inspection.vendor_line%TYPE,      -- IN 10.仕入先コード 処理区分3以外かつ区分:2のみ必須
    it_qt_inspect_req_no IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 11.検査依頼No   処理区分:2、3のみ必須
    ot_qt_inspect_req_no OUT NOCOPY xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- OUT 1.検査依頼No
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_qt_inspection'; --プログラム名
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
    lt_temp_date    xxwip_qt_inspection.prod_dely_date%TYPE; -- TEMP日付(検査予定日算出用)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_xxwip_qt_inspection      xxwip_qt_inspection%ROWTYPE;  -- 品質検査依頼情報アドオンレコード型
    lr_xxwip_qt_inspection_now  xxwip_qt_inspection%ROWTYPE;  -- 品質検査依頼情報アドオンレコード型
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    err_expt  EXCEPTION;  -- エラー例外
--
  BEGIN
--
    -- リターンコードセット
    ov_retcode := gv_status_normal;
--
-- 2008/08/25 H.Itou Add Start 変更要求#189
    -- 処理区分が2:更新、3:削除で、検査依頼NoがNULLの場合、処理を行わずに正常終了
    IF  (iv_disposal_div IN (gv_disposal_div_upd, gv_disposal_div_del)
    AND (NVL(it_qt_inspect_req_no, 0) = 0)) THEN
      RAISE no_action_expt;
    END IF;
-- 2008/08/25 H.Itou Add End
--
    -- =============================
    -- A-1.入力パラメータチェック
    -- =============================
    qt_parameter_check(
      it_division          => it_division          -- IN  1.区分
     ,iv_disposal_div      => iv_disposal_div      -- IN  2.処理区分
     ,it_lot_id            => it_lot_id            -- IN  3.ロットID
     ,it_item_id           => it_item_id           -- IN  4.品目ID
     ,iv_qt_object         => iv_qt_object         -- IN  5.対象先
     ,it_batch_id          => it_batch_id          -- IN  6.生産バッチID
     ,it_batch_po_id       => it_batch_po_id       -- IN  7.明細番号
     ,it_qty               => it_qty               -- IN  8.数量
     ,it_prod_dely_date    => it_prod_dely_date    -- IN  9.納入日
     ,it_vendor_line       => it_vendor_line       -- IN 10.仕入先コード
     ,it_qt_inspect_req_no => it_qt_inspect_req_no -- IN 11.検査依頼No
     ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
    END IF;
--
    -- 区分が5:荒茶製造の場合
    IF (it_division = gt_division_tea) THEN
      -- =============================
      -- A-2.荒茶製造情報取得
      -- =============================
      qt_get_namaha_prod_data(
        it_lot_id                => it_lot_id              -- IN  1.ロットID
       ,it_item_id               => it_item_id             -- IN  2.品目ID
       ,iv_qt_object             => iv_qt_object           -- IN  3.対象先
-- 2009/02/16 H.Itou Add Start 本番障害#32対応 生産は数量をINパラメータから取得する。
       ,it_qty                   => it_qty                 -- IN  4.数量
-- 2009/02/16 H.Itou Add End
       ,or_xxwip_qt_inspection   => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspectionレコード型
       ,ov_errbuf                => lv_errbuf              -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode             -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    -- 区分が5:荒茶製造以外の場合
    ELSE
      -- データチェック用ロットID、品目ID取得
      lr_xxwip_qt_inspection.lot_id  := it_lot_id;  -- データチェック用ロットID
      lr_xxwip_qt_inspection.item_id := it_item_id; -- データチェック用品目ID
--
    END IF;
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
    END IF;
--
    -- =============================
    -- A-3.データチェック/ロック
    -- =============================
    qt_check_and_lock(
      iv_disposal_div        => iv_disposal_div                -- IN  1.処理区分
     ,it_lot_id              => lr_xxwip_qt_inspection.lot_id  -- IN  2.ロットID
     ,it_item_id             => lr_xxwip_qt_inspection.item_id -- IN  3.品目ID
     ,it_qt_inspect_req_no   => it_qt_inspect_req_no           -- IN  4.検査依頼No
     ,it_division            => it_division                    -- IN  5.区分
     ,or_xxwip_qt_inspection => lr_xxwip_qt_inspection_now     -- OUT 1.xxwip_qt_inspectionレコード型
     ,ov_errbuf              => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             => lv_retcode                     -- リターン・コード             --# 固定 #
     ,ov_errmsg              => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
--
    -- 警告の場合、リターンコードをセットし、処理続行
    ELSIF (lv_retcode = gv_status_warn) THEN
      -- リターンコードをセット
      ov_retcode := lv_retcode;
    END IF;
--
    -- 処理区分が3:削除以外の場合
    IF (iv_disposal_div <> gv_disposal_div_del) THEN
      -- 区分が1:生産の場合
      IF (it_division = gt_division_gme) THEN
        -- =============================
        -- A-4.生産情報取得
        -- =============================
        qt_get_gme_data(
          it_batch_id             => it_batch_id                -- IN  1.生産バッチID
         ,it_lot_id               => it_lot_id                  -- IN  2.ロットID
         ,it_item_id              => it_item_id                 -- IN  3.品目ID
         ,iv_disposal_div         => iv_disposal_div            -- IN  4.処理区分
-- 2009/02/16 H.Itou Add Start 本番障害#32対応 生産は数量をINパラメータから取得する。
         ,it_qty                  => it_qty                     -- IN  4.数量
-- 2009/02/16 H.Itou Add End
         ,ir_xxwip_qt_inspection  => lr_xxwip_qt_inspection_now -- IN  5.xxwip_qt_inspectionレコード型
         ,or_xxwip_qt_inspection  => lr_xxwip_qt_inspection     -- OUT 1.xxwip_qt_inspectionレコード型
         ,ov_errbuf               => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
         ,ov_retcode              => lv_retcode                 -- リターン・コード             --# 固定 #
         ,ov_errmsg               => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
      -- 区分が2:発注の場合
      ELSIF (it_division = gt_division_po) THEN
        -- =============================
        -- A-5.発注情報取得
        -- =============================
        qt_get_po_data(
          it_lot_id               => it_lot_id              -- IN  1.ロットID
         ,it_item_id              => it_item_id             -- IN  2.品目ID
         ,it_batch_po_id          => it_batch_po_id         -- IN  3.明細番号
         ,it_qty                  => it_qty                 -- IN  4.数量
         ,it_prod_dely_date       => it_prod_dely_date      -- IN  5.納入日
         ,it_vendor_line          => it_vendor_line         -- IN  6.仕入先コード
         ,or_xxwip_qt_inspection  => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspectionレコード型
         ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ           --# 固定 #
         ,ov_retcode              => lv_retcode             -- リターン・コード             --# 固定 #
         ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
      -- 区分が3:ロット情報の場合
      ELSIF (it_division = gt_division_lot) THEN
        -- =============================
        -- A-6.ロット情報取得
        -- =============================
        qt_get_lot_data(
          it_lot_id                => it_lot_id              -- IN  1.ロットID
         ,it_item_id               => it_item_id             -- IN  2.品目ID
         ,it_qty                   => it_qty                 -- IN  3.数量
         ,or_xxwip_qt_inspection   => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspectionレコード型
         ,ov_errbuf                => lv_errbuf              -- エラー・メッセージ           --# 固定 #
         ,ov_retcode               => lv_retcode             -- リターン・コード             --# 固定 #
         ,ov_errmsg                => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
      -- 区分が4:外注出来高の場合
      ELSIF (it_division = gt_division_spl) THEN
        -- =============================
        -- A-7.外注出来高情報取得
        -- =============================
        qt_get_vendor_supply_data(
          it_lot_id               => it_lot_id              -- IN  1.ロットID
         ,it_item_id              => it_item_id             -- IN  2.品目ID
-- 2009/02/16 H.Itou Add Start 本番障害#32対応 生産は数量をINパラメータから取得する。
         ,it_qty                  => it_qty                 -- IN  3.数量
-- 2009/02/16 H.Itou Add End
         ,or_xxwip_qt_inspection  => lr_xxwip_qt_inspection -- OUT 1.xxwip_qt_inspectionレコード型
         ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ           --# 固定 #
         ,ov_retcode              => lv_retcode             -- リターン・コード             --# 固定 #
         ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
      END IF;
--
      -- エラーの場合、処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE err_expt;
--
      -- 警告の場合、リターンコードをセットし、処理続行
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- リターンコードをセット
        ov_retcode := lv_retcode;
      END IF;
--
      -- =============================
      -- A-8.検査予定日算出
      -- =============================
      -- 区分が4:外注出来高以外の場合
      IF (it_division <> gt_division_spl) THEN
        -- 検査予定日算出日付確定
        -- 区分が3:ロット情報の場合
        IF (it_division = gt_division_lot) THEN
          -- 生産/納入日がNULLの場合はSYSDATE
          lt_temp_date := NVL(lr_xxwip_qt_inspection.prod_dely_date, TRUNC(SYSDATE));
--
        -- 区分が3:ロット情報以外の場合
        ELSE
          -- 生産/納入日
          lt_temp_date := lr_xxwip_qt_inspection.prod_dely_date;
        END IF;
--
        get_business_date(
          id_date           => lt_temp_date                              -- IN  1.日付 必須
         ,in_period         => lr_xxwip_qt_inspection.inspect_period     -- IN  2.期間 必須 マイナスはエラー。
         ,od_business_date  => lr_xxwip_qt_inspection.inspect_due_date1  -- OUT 1.検査予定日１
         ,ov_errbuf         => lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode                                -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合、処理終了
        IF (lv_retcode = gv_status_error) THEN
          RAISE err_expt;
        END IF;
--
        -- 品質検査依頼情報レコードに値をセット
        lr_xxwip_qt_inspection.inspect_due_date2 := lr_xxwip_qt_inspection.inspect_due_date1;  -- 検査予定日２
        lr_xxwip_qt_inspection.inspect_due_date3 := lr_xxwip_qt_inspection.inspect_due_date1;  -- 検査予定日３
      END IF;
--
      -- =============================
      -- A-9.品質検査依頼情報登録/更新
      -- =============================
      qt_inspection_ins(
        it_division             => it_division            -- IN 1.区分
       ,iv_disposal_div         => iv_disposal_div        -- IN 2.処理区分
       ,it_qt_inspect_req_no    => it_qt_inspect_req_no   -- IN 3.検査依頼No
       ,ior_xxwip_qt_inspection => lr_xxwip_qt_inspection -- IN OUT 4.xxwip_qt_inspectionレコード型
       ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ           --# 固定 #
       ,ov_retcode              => lv_retcode             -- リターン・コード             --# 固定 #
       ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合、処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE err_expt;
      END IF;
--
    -- 処理区分が3:削除の場合
    ELSE
-- 2009/02/16 H.Itou Mod Start 本番障害#32対応 削除は廃止する。
--      -- =============================
--      -- A-10.品質検査依頼情報削除
--      -- =============================
----
--      DELETE xxwip_qt_inspection   xqi   -- 品質検査依頼情報
--      WHERE  xqi.qt_inspect_req_no  = it_qt_inspect_req_no    -- 検査依頼No
--      ;
      lr_xxwip_qt_inspection.qt_inspect_req_no := it_qt_inspect_req_no;  -- 検査依頼No;
-- 2009/02/16 H.Itou Mod End
--
    END IF;
--
    -- =============================
    -- A-11.ロットマスタ更新
    -- =============================
    qt_update_lot_dff_api(
      ir_xxwip_qt_inspection  => lr_xxwip_qt_inspection -- IN 1.xxwip_qt_inspectionレコード型
-- 2009/02/16 H.Itou Add Start 本番障害#1096対応 ロットステータスを初期化するかを判断するため、処理区分をパラメータに追加
     ,iv_disposal_div         => iv_disposal_div        -- IN  2.処理区分
-- 2009/02/16 H.Itou Add End
     ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE err_expt;
    END IF;
--
    -- =============================
    -- A-12.OUTパラメータ設定
    -- =============================
    -- 処理区分が3:削除以外の場合
    IF (iv_disposal_div <> gv_disposal_div_del) THEN
      ot_qt_inspect_req_no := lr_xxwip_qt_inspection.qt_inspect_req_no;  -- 検査依頼No
--
    -- 処理区分が3:削除の場合
    ELSE
      ot_qt_inspect_req_no := it_qt_inspect_req_no;  -- 検査依頼No
    END IF;
--
  EXCEPTION
    -- エラー発生時
    WHEN err_expt THEN
      -- =============================
      -- A-12.OUTパラメータ設定
      -- =============================
      ot_qt_inspect_req_no := it_qt_inspect_req_no;
      ov_retcode           := gv_status_error;
      ov_errmsg            := lv_errmsg;
      ov_errbuf            := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
-- 2008/08/25 H.Itou Add Start 変更要求#189
    -- 処理区分が2:更新、3:削除で、検査依頼NoがNULLの場合、処理を行わずに正常終了
    WHEN no_action_expt THEN
      -- =============================
      -- A-12.OUTパラメータ設定
      -- =============================
      ot_qt_inspect_req_no := NULL;
      ov_retcode           := gv_status_normal;
      ov_errmsg            := NULL;
      ov_errbuf            := NULL;
-- 2008/08/25 H.Itou Add End
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
  END make_qt_inspection;
--
  /**********************************************************************************
   * Function Name    : get_can_stock_qty
   * Description      : 手持在庫数量算出API(投入実績用)
   ***********************************************************************************/
  FUNCTION get_can_stock_qty(
    in_batch_id         IN NUMBER,                    -- バッチID
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_stock_qty'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    ln_total_qty NUMBER;
    ln_other_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    ln_total_qty := xxcmn_common_pkg.get_stock_qty(in_whse_id, in_item_id, in_lot_id);
--
-- 2008/12/25 D.Nihei DEL START
--    -- **************************************************
--    -- ***  他の生産バッチで使用されている数量を取得  ***
--    -- **************************************************
----
--    BEGIN
--      SELECT NVL(SUM(itp.trans_qty), 0) total
--      INTO   ln_other_qty
--      FROM   ic_tran_pnd            itp
--            ,xxcmn_item_locations_v xilv
---- 2008/10/09 v1.13 D.Nihei MOD START
----      WHERE  itp.whse_code     = xilv.whse_code
--      WHERE  itp.location     = xilv.segment1
---- 2008/10/09 v1.13 D.Nihei MOD END
--      AND    itp.doc_id        <>in_batch_id
--      AND    itp.item_id       = in_item_id
---- 2008/10/09 v1.13 D.Nihei MOD START
----      AND    itp.lot_id        = in_lot_id
--      AND    itp.lot_id        = NVL(in_lot_id, 0)
--      AND    itp.doc_type      = 'PROD'
---- 2008/10/09 v1.13 D.Nihei MOD END
--      AND    itp.completed_ind = 0
--      AND    itp.reverse_id    IS NULL
--      AND    xilv.inventory_location_id = in_whse_id
---- 2008/06/25 D.Nihei ADD START
--      AND    itp.line_type    = gn_material
---- 2008/06/25 D.Nihei ADD END
---- 2008/09/10 D.Nihei ADD START
--      AND    itp.delete_mark  = 0
---- 2008/09/10 D.Nihei ADD END
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        ln_other_qty := 0 ;
--    END ;
--    ln_total_qty := ln_other_qty + ln_total_qty;
---- 2008/12/25 D.Nihei DEL END
--
    RETURN ln_total_qty;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
    RETURN 0;
  END get_can_stock_qty;
--
  /**********************************************************************************
   * Procedure Name   : change_trans_date_all
   * Description      : 処理日付更新関数
   ***********************************************************************************/
  PROCEDURE change_trans_date_all(
    in_batch_id    IN  NUMBER,            -- 生産バッチID
    ov_errbuf      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'change_trans_date_all'; --プログラム名
    -- *** ローカル定数 ***
    cv_api_name   CONSTANT VARCHAR2(100) := '処理日付更新関数';
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
    ln_message_count       NUMBER;                       --
    lv_message_list        VARCHAR2(100);                --
    lv_return_status       VARCHAR2(100);                --
    lt_batch_no            gme_batch_header.batch_no%TYPE;  -- バッチNO
    lt_trans_date          ic_tran_pnd.trans_date%TYPE;     -- 処理日付
--
    -- *** ローカル・カーソル ***
    -- OPM保留在庫トランザクションカーソル
    CURSOR cur_ic_tran_pnd
    IS
      SELECT itp.trans_id   trans_id
            ,itp.trans_date trans_date
      FROM   ic_tran_pnd itp -- OPM保留在庫トランザクション
      WHERE  itp.reverse_id  IS NULL
-- 2008/09/03 D.Nihei ADD START 生産バッチのデータのみを取得する
      AND    itp.doc_type    = 'PROD'
-- 2008/09/03 D.Nihei ADD END
-- 2008/11/17 D.Nihei ADD START 原料と副産物のみにする
      AND    itp.line_type   IN (gn_material, gn_co_prod)
-- 2008/11/17 D.Nihei ADD END
      AND    itp.delete_mark = gn_delete_mark_off
      AND    itp.doc_id      = in_batch_id
      ;
--
    -- *** ローカル・レコード ***
    lr_material_detail_out gme_material_details%ROWTYPE;
    lr_tran_row_in         gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out        gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def        gme_inventory_txns_gtmp%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***  バッチNoと生産日を取得します。         ***
    -- ***********************************************
    SELECT gbh.batch_no -- バッチNo
          ,FND_DATE.STRING_TO_DATE( gmd.attribute11, 'YYYY/MM/DD' )  -- 生産日
    INTO   lt_batch_no
          ,lt_trans_date
    FROM   gme_batch_header     gbh -- 生産バッチヘッダ
          ,gme_material_details gmd -- 生産原料詳細
    WHERE  gbh.batch_id = gmd.batch_id
    AND    line_type    = gn_prod
    AND    gbh.batch_id = in_batch_id
    AND    ROWNUM       = 1
    ;
--
    -- *************************************************
    -- ***  デフォルトロットの処理IDを取得します。   ***
    -- *************************************************
    <<ic_tran_pnd_loop>>
    FOR rec_ic_tran_pnd IN cur_ic_tran_pnd LOOP
--
      -- 処理日付が、完成品の日付と異なる場合
      IF (lt_trans_date <> rec_ic_tran_pnd.trans_date) THEN
--
        -- *************************************************
        -- ***  処理日付に生産日を設定します。           ***
        -- *************************************************
        lr_tran_row_in.trans_id     := rec_ic_tran_pnd.trans_id;
        lr_tran_row_in.trans_date   := lt_trans_date;
--
        -- *************************************************
        -- ***  割当更新関数を実行します。               ***
        -- *************************************************
        GME_API_PUB.UPDATE_LINE_ALLOCATION (
          p_api_version        => GME_API_PUB.API_VERSION -- IN         NUMBER := gme_api_pub.api_version
         ,p_validation_level   => GME_API_PUB.MAX_ERRORS  -- IN         NUMBER := gme_api_pub.max_errors
         ,p_init_msg_list      => FALSE                   -- IN         BOOLEAN := FALSE
         ,p_commit             => FALSE                   -- IN         BOOLEAN := FALSE
         ,p_tran_row           => lr_tran_row_in          -- IN         gme_inventory_txns_gtmp%ROWTYPE
         ,p_lot_no             => NULL                    -- IN         VARCHAR2 DEFAULT NULL
         ,p_sublot_no          => NULL                    -- IN         VARCHAR2 DEFAULT NULL
         ,p_create_lot         => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
         ,p_ignore_shortage    => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
         ,p_scale_phantom      => FALSE                   -- IN         BOOLEAN DEFAULT FALSE
         ,x_material_detail    => lr_material_detail_out  -- OUT NOCOPY gme_material_details%ROWTYPE
         ,x_tran_row           => lr_tran_row_out         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
         ,x_def_tran_row       => lr_tran_row_def         -- OUT NOCOPY gme_inventory_txns_gtmp%ROWTYPE
         ,x_message_count      => ln_message_count        -- OUT NOCOPY NUMBER
         ,x_message_list       => lv_message_list         -- OUT NOCOPY VARCHAR2
         ,x_return_status      => lv_return_status        -- OUT NOCOPY VARCHAR2
        );
--
        IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          lv_errbuf := lv_message_list;
          RAISE api_expt;
        END IF;
      END IF;
    END LOOP;
--
    -- *************************************************
    -- ***  移動ロット詳細の実績日を更新します。     ***
    -- *************************************************
    UPDATE xxinv_mov_lot_details xmld
    SET    xmld.actual_date       = lt_trans_date
          ,xmld.last_updated_by   = FND_GLOBAL.USER_ID
          ,xmld.last_update_date  = SYSDATE
          ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID
    WHERE  xmld.record_type_code   = '40' -- レコードタイプ
    AND    xmld.document_type_code = '40' -- 文書タイプ
    AND    xmld.actual_date       <> lt_trans_date
    AND    EXISTS ( SELECT 'X'
                    FROM   gme_material_details gmd
                    WHERE  gmd.material_detail_id = xmld.mov_line_id
                    AND    gmd.batch_id = in_batch_id );
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名：生産バッチヘッダ完了
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || lt_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END change_trans_date_all;
--
END xxwip_common_pkg;
/
