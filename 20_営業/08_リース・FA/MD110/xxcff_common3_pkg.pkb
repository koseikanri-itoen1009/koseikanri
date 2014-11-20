create or replace PACKAGE BODY XXCFF_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON3_PKG(body)
 * Description      : リース物件関連共通関数
 * MD.050           : なし
 * Version          : 1.7
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  insert_ob_hed             P           リース物件登録関数
 *  insert_ob_his             P           リース物件履歴登録関数
 *  update_ob_hed             P           リース物件更新関数
 *  update_ob_his             P           リース物件履歴更新関数
 *  create_contract_ass       P           契約関連操作
 *  create_ob_det             P           リース物件情報作成
 *  create_ob_bat             P           リース物件情報作成（バッチ）
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-13   1.0    SCS 廣瀬真佐人   新規作成
 *  2009-02-10   1.1    SCS 廣瀬真佐人   [障害CFF_023] create_ob_bat、条件分岐において、NULL値を考慮するように修正。
 *  2009-02-23   1.2    SCS 廣瀬真佐人   [障害CFF_048] create_ob_bat、移動時にWHO値をセット。
 *                                       [障害CFF_051] create_contract_ass、中途解約日を業務日付に修正。
 *  2009-05-14   1.3    SCS 松中 俊樹    [障害T1_0749] create_ob_bat、物件有効フラグ変更時に処理を起動するように修正
 *  2009-12-02   1.4    SCS 渡辺 学      [障害E_T4_00098]
 *                                           修正：create_ob_bat
 *                                           自販機リース物件の修正履歴作成時、更新前リース物件の情報を引継ぐように修正。
 *  2011-12-19   1.5    SCSK 中村 健一   [障害E_本稼動_08123] create_contract_assの中途解約日をパラメータでセットするように修正。
 *                                                            不要なcreate_contract_ass、create_pay_planningをコメントアウト。
 *  2012-10-23   1.6    SCSK 杉浦 尚武   [障害E_本稼動_10112] create_contract_assのリース契約明細履歴登録処理において、
 *                                                            登録対象であるリース契約明細履歴のすべての列を記述。
 *                                                            また、更新事由、会計期間をNULLで登録するように修正。
 *  2013-08-02   1.7    SCSK 中野 徹也   [障害E_本稼動_10871] 消費税増税対応 リース契約明細履歴登録処理に税金コードを追加
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'xxcff_common3_pkg'; -- パッケージ名
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
  -- 対象データがありませんでした。
  cv_msg_cff_00062   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00062';
  --
  -- 処理モード
  cv_exce_mode_ins   CONSTANT VARCHAR2(20) := 'INSERT';        -- 追加
  cv_exce_mode_adj   CONSTANT VARCHAR2(20) := 'ADJUSTMENT';    -- 修正
  cv_exce_mode_chg   CONSTANT VARCHAR2(20) := 'CHANGE';        -- 変更
  cv_exce_mode_mov   CONSTANT VARCHAR2(20) := 'MOVE';          -- 移動
  cv_exce_mode_dis   CONSTANT VARCHAR2(20) := 'DISSOLUTION';   -- 解約キャンセル
  cv_exce_mode_can   CONSTANT VARCHAR2(20) := 'CANCELLATION';  -- 解約確定
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
-- == 2011-12-19 V1.5 Deleted START ====================================================================================
--  /**********************************************************************************
--   * Function Name    : create_contract_ass
--   * Description      : 契約関連操作
--   ***********************************************************************************/
--  PROCEDURE create_contract_ass(
--    in_contract_line_id       IN        xxcff_contract_lines.contract_line_id%TYPE,       -- 契約明細内部ID
--    iv_contract_status        IN        xxcff_contract_lines.contract_status%TYPE,        -- 契約ステータス
--    in_created_by             IN        xxcff_contract_lines.created_by%TYPE,             -- 作成者
--    id_creation_date          IN        xxcff_contract_lines.creation_date%TYPE,          -- 作成日
--    in_last_updated_by        IN        xxcff_contract_lines.last_updated_by%TYPE,        -- 最終更新者
--    id_last_update_date       IN        xxcff_contract_lines.last_update_date%TYPE,       -- 最終更新日
--    in_last_update_login      IN        xxcff_contract_lines.last_update_login%TYPE,      -- 最終更新ﾛｸﾞｲﾝ
--    in_request_id             IN        xxcff_contract_lines.request_id%TYPE,             -- 要求ID
--    in_program_application_id IN        xxcff_contract_lines.program_application_id%TYPE, -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--    in_program_id             IN        xxcff_contract_lines.program_id%TYPE,             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--    id_program_update_date    IN        xxcff_contract_lines.program_update_date%TYPE,    -- ﾌﾟﾛｸﾞﾗﾑ更新日
--    ov_errbuf                OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
--    ov_retcode               OUT NOCOPY VARCHAR2,           -- リターン・コード
--    ov_errmsg                OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ
--  );
--  --
--  /**********************************************************************************
--   * Function Name    : create_pay_planning
--   * Description      : スタブ
--   ***********************************************************************************/
--   PROCEDURE create_pay_planning(
--      in_contract_line_id  IN        xxcff_contract_lines.contract_line_id%TYPE,  -- 契約明細内部ID
--      ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ
--      ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード
--      ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
--    )
--   IS
--   BEGIN
--     ov_errbuf  := NULL;
--     ov_retcode := cv_status_normal;
--     ov_errmsg  := NULL;
--   END;
-- == 2011-12-19 V1.5 Deleted END   ====================================================================================
  /**********************************************************************************
   * Function Name    : insert_ob_hed
   * Description      : リース物件登録
   ***********************************************************************************/
  PROCEDURE insert_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_ob_hed';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- シーケンスの取得
    -- ***************************************************
    --
    SELECT    xxcff_object_headers_s1.NEXTVAL
    INTO      io_object_data_rec.object_header_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- リース物件登録
    -- ***************************************************
    --
    INSERT INTO xxcff_object_headers(
       object_header_id        -- 物件内部ID
     , object_code             -- 物件コード
     , lease_class             -- リース種別
     , lease_type              -- リース区分
     , re_lease_times          -- 再リース回数
     , po_number               -- 発注番号
     , registration_number     -- 登録番号
     , age_type                -- 年式
     , model                   -- 機種
     , serial_number           -- 機番
     , quantity                -- 数量
     , manufacturer_name       -- メーカー名
     , department_code         -- 管理部門コード
     , owner_company           -- 本社／工場
     , installation_address    -- 現設置場所
     , installation_place      -- 現設置先
     , chassis_number          -- 車台番号
     , re_lease_flag           -- 再リース要フラグ
     , cancellation_type       -- 解約区分
     , cancellation_date       -- 中途解約日
     , dissolution_date        -- 中途解約キャンセル日
     , bond_acceptance_flag    -- 証書受領フラグ
     , bond_acceptance_date    -- 証書受領日
     , expiration_date         -- 満了日
     , object_status           -- 物件ステータス
     , active_flag             -- 物件有効フラグ
     , info_sys_if_date        -- リース管理情報連携日
     , generation_date         -- 発生日
     , customer_code           -- 顧客コード
     , created_by              -- 作成者
     , creation_date           -- 作成日
     , last_updated_by         -- 最終更新者
     , last_update_date        -- 最終更新日
     , last_update_login       -- 最終更新ﾛｸﾞｲﾝ
     , request_id              -- 要求ID
     , program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    VALUES(
       io_object_data_rec.object_header_id        -- 物件内部ID
     , io_object_data_rec.object_code             -- 物件コード
     , io_object_data_rec.lease_class             -- リース種別
     , io_object_data_rec.lease_type              -- リース区分
     , io_object_data_rec.re_lease_times          -- 再リース回数
     , io_object_data_rec.po_number               -- 発注番号
     , io_object_data_rec.registration_number     -- 登録番号
     , io_object_data_rec.age_type                -- 年式
     , io_object_data_rec.model                   -- 機種
     , io_object_data_rec.serial_number           -- 機番
     , io_object_data_rec.quantity                -- 数量
     , io_object_data_rec.manufacturer_name       -- メーカー名
     , io_object_data_rec.department_code         -- 管理部門コード
     , io_object_data_rec.owner_company           -- 本社／工場
     , io_object_data_rec.installation_address    -- 現設置場所
     , io_object_data_rec.installation_place      -- 現設置先
     , io_object_data_rec.chassis_number          -- 車台番号
     , io_object_data_rec.re_lease_flag           -- 再リース要フラグ
     , io_object_data_rec.cancellation_type       -- 解約区分
     , io_object_data_rec.cancellation_date       -- 中途解約日
     , io_object_data_rec.dissolution_date        -- 中途解約キャンセル日
     , io_object_data_rec.bond_acceptance_flag    -- 証書受領フラグ
     , io_object_data_rec.bond_acceptance_date    -- 証書受領日
     , io_object_data_rec.expiration_date         -- 満了日
     , io_object_data_rec.object_status           -- 物件ステータス
     , io_object_data_rec.active_flag             -- 物件有効フラグ
     , io_object_data_rec.info_sys_if_date        -- リース管理情報連携日
     , io_object_data_rec.generation_date         -- 発生日
     , io_object_data_rec.customer_code           -- 顧客コード
     , io_object_data_rec.created_by              -- 作成者
     , io_object_data_rec.creation_date           -- 作成日
     , io_object_data_rec.last_updated_by         -- 最終更新者
     , io_object_data_rec.last_update_date        -- 最終更新日
     , io_object_data_rec.last_update_login       -- 最終更新ﾛｸﾞｲﾝ
     , io_object_data_rec.request_id              -- 要求ID
     , io_object_data_rec.program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , io_object_data_rec.program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , io_object_data_rec.program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    ;
  --
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END insert_ob_hed;
--
  /**********************************************************************************
   * Function Name    : insert_ob_his
   * Description      : リース物件履歴登録
   ***********************************************************************************/
  PROCEDURE insert_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_ob_his';   -- プログラム名
    --
    cv_if_flag_no_send CONSTANT xxcff_object_histories.accounting_if_flag%TYPE := '1';  -- 会計IFフラグ(未送信)
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    ln_history_num  PLS_INTEGER;  -- 変更履歴NO
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- シーケンスの取得
    -- ***************************************************
    --
    SELECT    xxcff_object_histories_s1.NEXTVAL
    INTO      ln_history_num
    FROM      dual
    ;
    --
    -- ***************************************************
    -- リース物件履歴登録
    -- ***************************************************
    --
    INSERT INTO xxcff_object_histories(
       object_header_id         -- 物件内部ID
     , history_num              -- 変更履歴NO
     , object_code              -- 物件コード
     , lease_class              -- リース種別
     , lease_type               -- リース区分
     , re_lease_times           -- 再リース回数
     , po_number                -- 発注番号
     , registration_number      -- 登録番号
     , age_type                 -- 年式
     , model                    -- 機種
     , serial_number            -- 機番
     , quantity                 -- 数量
     , manufacturer_name        -- メーカー名
     , department_code          -- 管理部門コード
     , owner_company            -- 本社／工場
     , installation_address     -- 現設置場所
     , installation_place       -- 現設置先
     , chassis_number           -- 車台番号
     , re_lease_flag            -- 再リース要フラグ
     , cancellation_type        -- 解約区分
     , cancellation_date        -- 中途解約日
     , dissolution_date         -- 中途解約キャンセル日
     , bond_acceptance_flag     -- 証書受領フラグ
     , bond_acceptance_date     -- 証書受領日
     , expiration_date          -- 満了日
     , object_status            -- 物件ステータス
     , active_flag              -- 物件有効フラグ
     , info_sys_if_date         -- リース管理情報連携日
     , generation_date          -- 発生日
     , customer_code            -- 顧客コード
     , accounting_date          -- 計上日
     , accounting_if_flag       -- 会計ＩＦフラグ
     , m_owner_company          -- 移動元本社／工場
     , m_department_code        -- 移動元管理部門
     , m_installation_address   -- 移動元現設置場所
     , m_installation_place     -- 移動元現設置先
     , m_registration_number    -- 移動元登録番号
     , description              -- 摘要
     , created_by               -- 作成者
     , creation_date            -- 作成日
     , last_updated_by          -- 最終更新者
     , last_update_date         -- 最終更新日
     , last_update_login        -- 最終更新ﾛｸﾞｲﾝ
     , request_id               -- 要求ID
     , program_application_id   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , program_id               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , program_update_date      -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    VALUES(
       io_object_data_rec.object_header_id        -- 物件内部ID
     , ln_history_num                             -- 変更履歴NO
     , io_object_data_rec.object_code             -- 物件コード
     , io_object_data_rec.lease_class             -- リース種別
     , io_object_data_rec.lease_type              -- リース区分
     , io_object_data_rec.re_lease_times          -- 再リース回数
     , io_object_data_rec.po_number               -- 発注番号
     , io_object_data_rec.registration_number     -- 登録番号
     , io_object_data_rec.age_type                -- 年式
     , io_object_data_rec.model                   -- 機種
     , io_object_data_rec.serial_number           -- 機番
     , io_object_data_rec.quantity                -- 数量
     , io_object_data_rec.manufacturer_name       -- メーカー名
     , io_object_data_rec.department_code         -- 管理部門コード
     , io_object_data_rec.owner_company           -- 本社／工場
     , io_object_data_rec.installation_address    -- 現設置場所
     , io_object_data_rec.installation_place      -- 現設置先
     , io_object_data_rec.chassis_number          -- 車台番号
     , io_object_data_rec.re_lease_flag           -- 再リース要フラグ
     , io_object_data_rec.cancellation_type       -- 解約区分
     , io_object_data_rec.cancellation_date       -- 中途解約日
     , io_object_data_rec.dissolution_date        -- 中途解約キャンセル日
     , io_object_data_rec.bond_acceptance_flag    -- 証書受領フラグ
     , io_object_data_rec.bond_acceptance_date    -- 証書受領日
     , io_object_data_rec.expiration_date         -- 満了日
     , io_object_data_rec.object_status           -- 物件ステータス
     , io_object_data_rec.active_flag             -- 物件有効フラグ
     , io_object_data_rec.info_sys_if_date        -- リース管理情報連携日
     , io_object_data_rec.generation_date         -- 発生日
     , io_object_data_rec.customer_code           -- 顧客コード
     , xxccp_common_pkg2.get_process_date         -- 計上日
     , cv_if_flag_no_send                         -- 会計ＩＦフラグ(未送信)
     , io_object_data_rec.m_owner_company         -- 移動元本社／工場
     , io_object_data_rec.m_department_code       -- 移動元管理部門
     , io_object_data_rec.m_installation_address  -- 移動元現設置場所
     , io_object_data_rec.m_installation_place    -- 移動元現設置先
     , io_object_data_rec.m_registration_number   -- 移動元登録番号
     , io_object_data_rec.description             -- 摘要
     , io_object_data_rec.created_by              -- 作成者
     , io_object_data_rec.creation_date           -- 作成日
     , io_object_data_rec.last_updated_by         -- 最終更新者
     , io_object_data_rec.last_update_date        -- 最終更新日
     , io_object_data_rec.last_update_login       -- 最終更新ﾛｸﾞｲﾝ
     , io_object_data_rec.request_id              -- 要求ID
     , io_object_data_rec.program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , io_object_data_rec.program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , io_object_data_rec.program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    ;
  --
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END insert_ob_his;
--
  /**********************************************************************************
   * Function Name    : update_ob_hed
   * Description      : リース物件更新
   ***********************************************************************************/
  PROCEDURE update_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_ob_hed';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    lv_info         VARCHAR2(5000);  -- エラー内容
    --
  --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    lv_info    := NULL;
    --
    -- ***************************************************
    -- 対象ステータス取得
    -- ***************************************************
    --
    -- 物件ステータスが渡されてないときは、現状のステータスを取得
    IF ( io_object_data_rec.object_status IS NULL ) THEN
    --
      SELECT    xoh.object_status  AS object_status
      INTO      io_object_data_rec.object_status
      FROM      xxcff_object_headers  xoh  -- リース物件テーブル
      WHERE     xoh.object_header_id = io_object_data_rec.object_header_id  -- 物件内部ID
      ;
    --
    END IF;
    --
    -- ***************************************************
    -- リース物件更新
    -- ***************************************************
    --
    UPDATE xxcff_object_headers  xoh  -- リース物件テーブル
    SET    xoh.lease_class            = io_object_data_rec.lease_class             -- リース種別
         , xoh.po_number              = io_object_data_rec.po_number               -- 発注番号
         , xoh.registration_number    = io_object_data_rec.registration_number     -- 登録番号
         , xoh.age_type               = io_object_data_rec.age_type                -- 年式
         , xoh.model                  = io_object_data_rec.model                   -- 機種
         , xoh.serial_number          = io_object_data_rec.serial_number           -- 機番
         , xoh.quantity               = io_object_data_rec.quantity                -- 数量
         , xoh.manufacturer_name      = io_object_data_rec.manufacturer_name       -- メーカー名
         , xoh.department_code        = io_object_data_rec.department_code         -- 管理部門コード
         , xoh.owner_company          = io_object_data_rec.owner_company           -- 本社／工場
         , xoh.installation_address   = io_object_data_rec.installation_address    -- 現設置場所
         , xoh.installation_place     = io_object_data_rec.installation_place      -- 現設置先
         , xoh.chassis_number         = io_object_data_rec.chassis_number          -- 車台番号
         , xoh.re_lease_flag          = io_object_data_rec.re_lease_flag           -- 再リース要フラグ
         , xoh.cancellation_type      = io_object_data_rec.cancellation_type       -- 解約区分
         , xoh.cancellation_date      = io_object_data_rec.cancellation_date       -- 中途解約日
         , xoh.dissolution_date       = io_object_data_rec.dissolution_date        -- 中途解約キャンセル日
         , xoh.bond_acceptance_flag   = io_object_data_rec.bond_acceptance_flag    -- 証書受領フラグ
         , xoh.bond_acceptance_date   = io_object_data_rec.bond_acceptance_date    -- 証書受領日
         , xoh.object_status          = io_object_data_rec.object_status           -- 物件ステータス
         , xoh.active_flag            = io_object_data_rec.active_flag             -- 物件有効フラグ
         , xoh.generation_date        = io_object_data_rec.generation_date         -- 発生日
         , xoh.customer_code          = io_object_data_rec.customer_code           -- 顧客コード
         , xoh.last_updated_by        = io_object_data_rec.last_updated_by         -- 最終更新者
         , xoh.last_update_date       = io_object_data_rec.last_update_date        -- 最終更新日
         , xoh.last_update_login      = io_object_data_rec.last_update_login       -- 最終更新ﾛｸﾞｲﾝ
         , xoh.request_id             = io_object_data_rec.request_id              -- 要求ID
         , xoh.program_application_id = io_object_data_rec.program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , xoh.program_id             = io_object_data_rec.program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , xoh.program_update_date    = io_object_data_rec.program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
    WHERE  xoh.object_header_id = io_object_data_rec.object_header_id  -- 物件内部ID
    ;
    --
    -- 更新対象がなかった時
    IF ( SQL%ROWCOUNT = 0 ) THEN
      lv_info := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_kbn_cff
                  , iv_name         => cv_msg_cff_00062
                 );
      lv_errbuf  := lv_info;
      lv_errmsg  := lv_info;
      lv_retcode := cv_status_error;
      --
      RAISE global_process_expt;
      --
    END IF;
  --
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END update_ob_hed;
  --
  /**********************************************************************************
   * Function Name    : update_ob_his
   * Description      : リース物件履歴更新関数
   ***********************************************************************************/
  PROCEDURE update_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_ob_his';   -- プログラム名
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    lv_info         VARCHAR2(5000);  -- エラー内容
    --
    ln_history_num  PLS_INTEGER;  -- 変更履歴NO
  --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    lv_info    := NULL;
    --
    -- ***************************************************
    -- 最新履歴の取得
    -- ***************************************************
    SELECT    temp.history_num    AS history_num
            , NVL( io_object_data_rec.object_status
                 , temp.object_status
              )                   AS object_status
    INTO      ln_history_num
            , io_object_data_rec.object_status
    FROM     (SELECT    RANK() OVER( ORDER BY xohi.history_num DESC ) AS ranking        -- ランキング
                      , xohi.history_num                              AS history_num    -- 変更履歴NO
                      , xohi.object_status                            AS object_status  -- 物件ステータス
              FROM      xxcff_object_histories  xohi  -- リース物件履歴
              WHERE     xohi.object_header_id = io_object_data_rec.object_header_id  -- 物件内部ID
             )  temp
    WHERE     temp.ranking = 1
    ;
    --
    -- ***************************************************
    -- リース物件履歴更新
    -- ***************************************************
    --
    UPDATE xxcff_object_histories  xohi  -- リース物件履歴テーブル
    SET    xohi.lease_class            = io_object_data_rec.lease_class             -- リース種別
         , xohi.po_number              = io_object_data_rec.po_number               -- 発注番号
         , xohi.registration_number    = io_object_data_rec.registration_number     -- 登録番号
         , xohi.age_type               = io_object_data_rec.age_type                -- 年式
         , xohi.model                  = io_object_data_rec.model                   -- 機種
         , xohi.serial_number          = io_object_data_rec.serial_number           -- 機番
         , xohi.quantity               = io_object_data_rec.quantity                -- 数量
         , xohi.manufacturer_name      = io_object_data_rec.manufacturer_name       -- メーカー名
         , xohi.department_code        = io_object_data_rec.department_code         -- 管理部門コード
         , xohi.owner_company          = io_object_data_rec.owner_company           -- 本社／工場
         , xohi.installation_address   = io_object_data_rec.installation_address    -- 現設置場所
         , xohi.installation_place     = io_object_data_rec.installation_place      -- 現設置先
         , xohi.chassis_number         = io_object_data_rec.chassis_number          -- 車台番号
         , xohi.re_lease_flag          = io_object_data_rec.re_lease_flag           -- 再リース要フラグ
         , xohi.cancellation_type      = io_object_data_rec.cancellation_type       -- 解約区分
         , xohi.cancellation_date      = io_object_data_rec.cancellation_date       -- 中途解約日
         , xohi.dissolution_date       = io_object_data_rec.dissolution_date        -- 中途解約キャンセル日
         , xohi.bond_acceptance_flag   = io_object_data_rec.bond_acceptance_flag    -- 証書受領フラグ
         , xohi.bond_acceptance_date   = io_object_data_rec.bond_acceptance_date    -- 証書受領日
         , xohi.object_status          = io_object_data_rec.object_status           -- 物件ステータス
         , xohi.active_flag            = io_object_data_rec.active_flag             -- 物件有効フラグ
         , xohi.generation_date        = io_object_data_rec.generation_date         -- 発生日
         , xohi.customer_code          = io_object_data_rec.customer_code           -- 顧客コード
         , xohi.m_owner_company        = io_object_data_rec.m_owner_company         -- 移動元本社／工場
         , xohi.m_department_code      = io_object_data_rec.m_department_code       -- 移動元管理部門
         , xohi.m_installation_address = io_object_data_rec.m_installation_address  -- 移動元現設置場所
         , xohi.m_installation_place   = io_object_data_rec.m_installation_place    -- 移動元現設置先
         , xohi.m_registration_number  = io_object_data_rec.m_registration_number   -- 移動元登録番号
         , xohi.description            = io_object_data_rec.description             -- 摘要
         , xohi.last_updated_by        = io_object_data_rec.last_updated_by         -- 最終更新者
         , xohi.last_update_date       = io_object_data_rec.last_update_date        -- 最終更新日
         , xohi.last_update_login      = io_object_data_rec.last_update_login       -- 最終更新ﾛｸﾞｲﾝ
         , xohi.request_id             = io_object_data_rec.request_id              -- 要求ID
         , xohi.program_application_id = io_object_data_rec.program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , xohi.program_id             = io_object_data_rec.program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , xohi.program_update_date    = io_object_data_rec.program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
    WHERE  xohi.object_header_id = io_object_data_rec.object_header_id  -- 物件内部ID
    AND    xohi.history_num      = ln_history_num  -- 変更履歴NO
    ;
    --
    -- 更新対象がなかった時
    IF ( SQL%ROWCOUNT = 0 ) THEN
      lv_info := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_kbn_cff
                  , iv_name         => cv_msg_cff_00062
                 );
      lv_errbuf  := lv_info;
      lv_errmsg  := lv_info;
      lv_retcode := cv_status_error;
      --
      RAISE global_process_expt;
      --
    END IF;
  --
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END update_ob_his;
--
  /**********************************************************************************
   * Function Name    : create_contract_ass
   * Description      : 契約関連操作
   ***********************************************************************************/
  PROCEDURE create_contract_ass(
    in_contract_line_id       IN        xxcff_contract_lines.contract_line_id%TYPE,       -- 契約明細内部ID
    iv_contract_status        IN        xxcff_contract_lines.contract_status%TYPE,        -- 契約ステータス
-- == 2011-12-19 V1.5 Added START ======================================================================================
    id_cancellation_date      IN        xxcff_contract_lines.cancellation_date%TYPE,      -- 中途解約日
-- == 2011-12-19 V1.5 Added END   ======================================================================================
    in_created_by             IN        xxcff_contract_lines.created_by%TYPE,             -- 作成者
    id_creation_date          IN        xxcff_contract_lines.creation_date%TYPE,          -- 作成日
    in_last_updated_by        IN        xxcff_contract_lines.last_updated_by%TYPE,        -- 最終更新者
    id_last_update_date       IN        xxcff_contract_lines.last_update_date%TYPE,       -- 最終更新日
    in_last_update_login      IN        xxcff_contract_lines.last_update_login%TYPE,      -- 最終更新ﾛｸﾞｲﾝ
    in_request_id             IN        xxcff_contract_lines.request_id%TYPE,             -- 要求ID
    in_program_application_id IN        xxcff_contract_lines.program_application_id%TYPE, -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    in_program_id             IN        xxcff_contract_lines.program_id%TYPE,             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    id_program_update_date    IN        xxcff_contract_lines.program_update_date%TYPE,    -- ﾌﾟﾛｸﾞﾗﾑ更新日
    ov_errbuf                OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg                OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'create_contract_ass';   -- プログラム名
    --
    cv_if_flag_no_send CONSTANT xxcff_object_histories.accounting_if_flag%TYPE := '1';  -- 会計IFフラグ(未送信)
    -- 処理区分(中途解約)
    cv_shori_type3     CONSTANT VARCHAR2(1) := '3';  -- '中途解約'
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    ln_history_num  PLS_INTEGER;  -- 変更履歴NO
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- リース契約明細更新
    -- ***************************************************
    UPDATE    xxcff_contract_lines  xcl  -- リース契約明細
    SET       xcl.contract_status        = iv_contract_status                  -- 契約ステータス
-- == 2011-12-19 V1.5 Modified START ===================================================================================
--            , xcl.cancellation_date      = xxccp_common_pkg2.get_process_date  -- 中途解約日
            , xcl.cancellation_date      = id_cancellation_date                -- 中途解約日
-- == 2011-12-19 V1.5 Modified END   ===================================================================================
            , xcl.last_updated_by        = in_last_updated_by                  -- 最終更新者
            , xcl.last_update_date       = id_last_update_date                 -- 最終更新日
            , xcl.last_update_login      = in_last_update_login                -- 最終更新ﾛｸﾞｲﾝ
            , xcl.request_id             = in_request_id                       -- 要求ID
            , xcl.program_application_id = in_program_application_id           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
            , xcl.program_id             = in_program_id                       -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
            , xcl.program_update_date    = id_program_update_date              -- ﾌﾟﾛｸﾞﾗﾑ更新日
    WHERE     xcl.contract_line_id = in_contract_line_id  -- 契約明細内部ID
    ;
    --
    -- ***************************************************
    -- リース契約明細履歴登録
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_histories  -- 契約明細履歴テーブル
-- == 2012-10-23 V1.6 Added START ===================================================================================
            (
              contract_header_id           -- 契約内部ID
            , contract_line_id             -- 契約明細内部ID
            , history_num                  -- 変更履歴NO
            , contract_status              -- 契約ステータス
            , first_charge                 -- 初回月額リース料_リース料
            , first_tax_charge             -- 初回消費税額_リース料
            , first_total_charge           -- 初回計_リース料
            , second_charge                -- 2回目以降月額リース料_リース料
            , second_tax_charge            -- 2回目以降消費税額_リース料
            , second_total_charge          -- 2回目以降計_リース料
            , first_deduction              -- 初回月額リース料_控除額
            , first_tax_deduction          -- 初回月額消費税額_控除額
            , first_total_deduction        -- 初回計_控除額
            , second_deduction             -- 2回目以降月額リース料_控除額
            , second_tax_deduction         -- 2回目以降消費税額_控除額
            , second_total_deduction       -- 2回目以降計_控除額
            , gross_charge                 -- 総額リース料_リース料
            , gross_tax_charge             -- 総額消費税_リース料
            , gross_total_charge           -- 総額計_リース料
            , gross_deduction              -- 総額リース料_控除額
            , gross_tax_deduction          -- 総額消費税_控除額
            , gross_total_deduction        -- 総額計_控除額
            , lease_kind                   -- リース種類
            , estimated_cash_price         -- 見積現金購入価額
            , present_value_discount_rate  -- 現在価値割引率
            , present_value                -- 現在価値
            , life_in_months               -- 法定耐用年数
            , original_cost                -- 取得価額
            , calc_interested_rate         -- 計算利子率
            , object_header_id             -- 物件内部ID
            , asset_category               -- 資産種類
            , expiration_date              -- 満了日
            , cancellation_date            -- 中途解約日
            , vd_if_date                   -- リース契約情報連携日
            , info_sys_if_date             -- リース管理情報連携日
            , first_installation_address   -- 初回設置場所
            , first_installation_place     -- 初回設置先
-- == 2013-08-02 V1.7 Added START ===================================================================================
            , tax_code                     -- 税金コード
-- == 2013-08-02 V1.7 Added END ===================================================================================
            , accounting_date              -- 計上日
            , accounting_if_flag           -- 会計ＩＦフラグ
            , description                  -- 摘要
            , update_reason                -- 更新事由
            , period_name                  -- 会計期間
            , created_by                   -- 作成者
            , creation_date                -- 作成日
            , last_updated_by              -- 最終更新者
            , last_update_date             -- 最終更新日
            , last_update_login            -- 最終更新ログイン
            , request_id                   -- 要求ID
            , program_application_id       -- コンカレント・プログラム・アプリケーションID
            , program_id                   -- コンカレント・プログラムID
            , program_update_date          -- プログラム更新日
            )
-- == 2012-10-23 V1.6 Added END ===================================================================================
    SELECT    xcl.contract_header_id              -- 契約内部ID
            , xcl.contract_line_id                -- 契約明細内部ID
            , xxcff_contract_histories_s1.NEXTVAL -- 変更履歴NO
            , iv_contract_status                  -- 契約ステータス
            , xcl.first_charge                    -- 初回月額リース料_リース料
            , xcl.first_tax_charge                -- 初回消費税額_リース料
            , xcl.first_total_charge              -- 初回計_リース料
            , xcl.second_charge                   -- 2回目以降月額リース料_リース料
            , xcl.second_tax_charge               -- 2回目以降消費税額_リース料
            , xcl.second_total_charge             -- 2回目以降計_リース料
            , xcl.first_deduction                 -- 初回月額リース料_控除額
            , xcl.first_tax_deduction             -- 初回月額消費税額_控除額
            , xcl.first_total_deduction           -- 初回計_控除額
            , xcl.second_deduction                -- 2回目以降月額リース料_控除額
            , xcl.second_tax_deduction            -- 2回目以降消費税額_控除額
            , xcl.second_total_deduction          -- 2回目以降計_控除額
            , xcl.gross_charge                    -- 総額リース料_リース料
            , xcl.gross_tax_charge                -- 総額消費税_リース料
            , xcl.gross_total_charge              -- 総額計_リース料
            , xcl.gross_deduction                 -- 総額控除額_リース料
            , xcl.gross_tax_deduction             -- 総額消費税_控除額
            , xcl.gross_total_deduction           -- 総額計_控除額
            , xcl.lease_kind                      -- リース種類
            , xcl.estimated_cash_price            -- 見積現金購入価額
            , xcl.present_value_discount_rate     -- 現在価値割引率
            , xcl.present_value                   -- 現在価値
            , xcl.life_in_months                  -- 法定耐用年数
            , xcl.original_cost                   -- 取得価額
            , xcl.calc_interested_rate            -- 計算利子率
            , xcl.object_header_id                -- 物件内部ID
            , xcl.asset_category                  -- 資産種類
            , xcl.expiration_date                 -- 満了日
            , xcl.cancellation_date               -- 中途解約日
            , xcl.vd_if_date                      -- リース契約情報連携日
            , xcl.info_sys_if_date                -- リース管理情報連携
            , xcl.first_installation_address      -- 初回設置場所
            , xcl.first_installation_place        -- 初回設置先
-- == 2013-08-02 V1.7 Added START ===================================================================================
            , xcl.tax_code                        -- 税金コード
-- == 2013-08-02 V1.7 Added END ===================================================================================
            , xxccp_common_pkg2.get_process_date  -- 計上日
            , cv_if_flag_no_send                  -- 会計ＩＦフラグ
            , NULL                                -- 摘要
-- == 2012-10-23 V1.6 Added START ===================================================================================
            , NULL                                -- 更新事由
            , NULL                                -- 会計期間
-- == 2012-10-23 V1.6 Added END ===================================================================================
            , xcl.created_by                      -- 作成者
            , xcl.creation_date                   -- 作成日
            , in_last_updated_by                  -- 最終更新者
            , id_last_update_date                 -- 最終更新日
            , in_last_update_login                -- 最終更新ﾛｸﾞｲﾝ
            , in_request_id                       -- 要求ID
            , in_program_application_id           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
            , in_program_id                       -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
            , id_program_update_date              -- ﾌﾟﾛｸﾞﾗﾑ更新日
    FROM      xxcff_contract_lines  xcl  -- 契約明細テーブル
    WHERE     xcl.contract_line_id = in_contract_line_id  -- 契約明細内部ID
    ;
    --
    -- ***************************************************
    -- FA共通関数[支払計画作成]
    -- ***************************************************
    xxcff003a05c.main(
      iv_shori_type       => cv_shori_type3       -- 中途解約
     ,in_contract_line_id => in_contract_line_id  -- 契約明細内部ID
     ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ
     ,ov_retcode          => lv_retcode           -- リターン・コード
     ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ
    );
    --
    -- エラー終了時
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
  --
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END create_contract_ass;
  --
  /**********************************************************************************
   * Function Name    : create_ob_det
   * Description      : リース物件情報作成
   ***********************************************************************************/
  PROCEDURE create_ob_det(
    iv_exce_mode           IN        VARCHAR2,           -- 処理モード
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'create_ob_det';   -- プログラム名
    --
    -- 物件ステータス
    cv_ob_sts_cont_bef    CONSTANT xxcff_object_headers.object_status%TYPE   := '101';  -- 未契約
    cv_ob_sts_cont_aft    CONSTANT xxcff_object_headers.object_status%TYPE   := '102';  -- 契約済
    cv_ob_sts_re_cont_bef CONSTANT xxcff_object_headers.object_status%TYPE   := '103';  -- 再リース待
    cv_ob_sts_re_cont_aft CONSTANT xxcff_object_headers.object_status%TYPE   := '104';  -- 再リース契約済
    cv_ob_sts_move        CONSTANT xxcff_object_headers.object_status%TYPE   := '105';  -- 移動
    cv_ob_sts_change      CONSTANT xxcff_object_headers.object_status%TYPE   := '106';  -- 物件情報変更
    cv_ob_sts_cancel_can  CONSTANT xxcff_object_headers.object_status%TYPE   := '109';  -- 解約申請キャンセル
    cv_ob_sts_cancel_own  CONSTANT xxcff_object_headers.object_status%TYPE   := '110';  -- 解約確定(自己都合)
    cv_ob_sts_cancel_ins  CONSTANT xxcff_object_headers.object_status%TYPE   := '111';  -- 解約確定(保険対応)
    -- 契約ステータス
    cv_co_sts_cancel_own  CONSTANT xxcff_contract_lines.contract_status%TYPE := '206';  -- 解約確定(自己都合)
    cv_co_sts_cancel_ins  CONSTANT xxcff_contract_lines.contract_status%TYPE := '207';  -- 解約確定(保険対応)
    --
    -- リース区分
    cv_lease_type_ori  CONSTANT xxcff_contract_headers.lease_type%TYPE      := '1';  -- 原契約
    cv_lease_type_re   CONSTANT xxcff_contract_headers.lease_type%TYPE      := '2';  -- 再リース契約
    -- 解約区分
    cv_can_type_own    CONSTANT xxcff_object_headers.cancellation_type%TYPE := '1';  -- 自己都合
    cv_can_type_ins    CONSTANT xxcff_object_headers.cancellation_type%TYPE := '2';  -- 保険対応
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    ln_count        PLS_INTEGER;  -- カウンタ
    ln_return       PLS_INTEGER;  -- 戻り値
    --
    lv_contract_status     xxcff_contract_lines.contract_status%TYPE := NULL;  -- 契約ステータス
    ln_object_header_id    xxcff_object_headers.object_header_id%TYPE := NULL;  -- 物件内部ID
    ln_contract_header_id  xxcff_contract_headers.contract_header_id%TYPE := NULL;  -- 契約内部ID
    ln_contract_line_id    xxcff_contract_lines.contract_line_id%TYPE := NULL;  -- 契約明細内部ID
    --
    lv_temp_status      xxcff_object_headers.object_status%TYPE := NULL;   -- ステータス
    lv_temp_status_chg  xxcff_object_headers.object_status%TYPE := NULL;   -- ステータス
    --
  --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    ln_count   := 0;
    --
    -- 処理モード(追加)
    IF      ( iv_exce_mode = cv_exce_mode_ins ) THEN
      --
      -- ***************************************************
      -- 物件情報の登録更新処理
      -- ***************************************************
      -- 物件ステータスを「未契約」とします。
      io_object_data_rec.object_status := cv_ob_sts_cont_bef;
      --
      -- リース物件登録
      insert_ob_hed(
        io_object_data_rec => io_object_data_rec  -- 物件情報
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode         => lv_retcode          -- リターン・コード
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      -- エラー終了時
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
      -- リース物件履歴登録
      insert_ob_his(
        io_object_data_rec => io_object_data_rec  -- 物件情報
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode         => lv_retcode          -- リターン・コード
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      -- エラー終了時
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
    --
    -- 処理モード(追加)以外のときは契約情報を取得する。
    ELSE
    --
      --
      -- 処理モード(修正)
      IF    ( iv_exce_mode = cv_exce_mode_adj ) THEN
      --
        --
        -- 返却用にステータスを格納
        lv_temp_status := io_object_data_rec.object_status;
        -- 履歴用のステータスを保持しておく。
        lv_temp_status_chg := NVL( io_object_data_rec.object_status
                                 , cv_ob_sts_change
                              );
        -- ***************************************************
        -- 物件情報の登録更新処理
        -- ***************************************************
        -- リース物件更新
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- 履歴用にステータスを格納
        io_object_data_rec.object_status := lv_temp_status_chg;
        --
        -- リース物件履歴登録
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- 履歴の登録が終わったので元に戻す
        io_object_data_rec.object_status := lv_temp_status;
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- 処理モード(変更)
      ELSIF ( iv_exce_mode = cv_exce_mode_chg ) THEN
      --
        -- ***************************************************
        -- 物件情報の登録更新処理
        -- ***************************************************
        -- リース物件更新
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- リース物件履歴更新
        update_ob_his(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- 処理モード(移動)
      ELSIF ( iv_exce_mode = cv_exce_mode_mov ) THEN
        --
        -- ***************************************************
        -- 物件情報の登録更新処理
        -- ***************************************************
        lv_temp_status := io_object_data_rec.object_status;
        -- リース物件更新
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- 履歴用にステータスを格納
        io_object_data_rec.object_status := cv_ob_sts_move;
        --
        -- リース物件履歴登録
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- 履歴の登録が終わったので元に戻す
        io_object_data_rec.object_status := lv_temp_status;
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- 処理モード(解約キャンセル)
      ELSIF ( iv_exce_mode = cv_exce_mode_dis ) THEN
        --
        -- ***************************************************
        -- 物件情報の登録更新処理
        -- ***************************************************
        --
        -- デフォルト値を設定します。
        io_object_data_rec.cancellation_type := NULL; -- 解約区分
        --
        -- リース区分の判断
        -- 原契約のとき
        IF      ( io_object_data_rec.lease_type = cv_lease_type_ori ) THEN
          -- 物件ステータスを「契約済」とします。
          io_object_data_rec.object_status := cv_ob_sts_cont_aft;
        -- 再リース契約のとき
        ELSE
          -- 物件の契約状況を取得します。
          --
          -- 初期化
          ln_count := 0;
          --
          SELECT    COUNT( ROWNUM )  AS cnt  -- 件数取得
          INTO      ln_count
          FROM      xxcff_object_headers   xoh  -- リース物件
                   ,xxcff_contract_headers xch  -- リース契約
                   ,xxcff_contract_lines   xcl  -- リース契約明細
          WHERE     xch.contract_header_id = xcl.contract_header_id  -- 契約内部ID
          AND       xch.re_lease_times     = xoh.re_lease_times  -- 再リース回数
          AND       xcl.object_header_id   = xoh.object_header_id  -- 物件内部ID
          AND       xoh.object_code        = io_object_data_rec.object_code  -- 物件コード
          ;
          --
          -- 対象の契約が取得できないとき
          IF ( ln_count = 0 ) THEN
            -- 物件ステータスを「再リース待」とします。
            io_object_data_rec.object_status := cv_ob_sts_re_cont_bef;
          ELSE
            -- 物件ステータスを「再リース契約済」とします。
            io_object_data_rec.object_status := cv_ob_sts_re_cont_aft;
          END IF;
          --
        END IF;
        --
        -- リース物件更新
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- 履歴用にステータスを格納
        lv_temp_status := io_object_data_rec.object_status;
        io_object_data_rec.object_status := cv_ob_sts_cancel_can;
        --
        -- リース物件履歴登録
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- 履歴の登録が終わったので元に戻す
        io_object_data_rec.object_status := lv_temp_status;
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- 移動モード(解約確定)
      ELSIF ( iv_exce_mode = cv_exce_mode_can ) THEN
        --
        -- ***************************************************
        -- リースキー情報の取得
        -- ***************************************************
        xxcff_common2_pkg.get_lease_key(
          iv_objectcode  => io_object_data_rec.object_code       -- 物件コード
         ,on_object_id   => io_object_data_rec.object_header_id  -- 物件内部ID
         ,on_contact_id  => ln_contract_header_id                -- 契約内部ID
         ,on_line_id     => ln_contract_line_id                  -- 契約明細内部ID
         ,ov_errbuf      => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode     => lv_retcode          -- リターン・コード
         ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- ***************************************************
        -- 物件情報の登録更新処理
        -- ***************************************************
        -- 解約区分の判断
        -- 自己都合のとき
        IF      ( io_object_data_rec.cancellation_type = cv_can_type_own ) THEN
          -- 契約と物件のステータスを「中途解約(自己都合)」とします。
          io_object_data_rec.object_status := cv_ob_sts_cancel_own;  -- 物件
          lv_contract_status               := cv_co_sts_cancel_own;  -- 契約
        -- 保険対応のとき
        ELSIF ( io_object_data_rec.cancellation_type = cv_can_type_ins ) THEN
          -- 契約と物件のステータスを「中途解約(保険対応)」とします。
          io_object_data_rec.object_status := cv_ob_sts_cancel_ins;  -- 物件
          lv_contract_status               := cv_co_sts_cancel_ins;  -- 契約
        END IF;
-- == 2011-12-19 V1.5 Added START ======================================================================================
        -- 中途解約日の設定
        IF ( io_object_data_rec.cancellation_date IS NULL ) THEN
          io_object_data_rec.cancellation_date := xxccp_common_pkg2.get_process_date;  -- 中途解約日
        END IF;
-- == 2011-12-19 V1.5 Added END   ======================================================================================
        --
        -- リース物件更新
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- リース物件履歴登録
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- 契約が取れないときは、再リース待の物件なので、契約関連の操作は必要なし。
        IF NOT( ln_contract_line_id IS NULL ) THEN
          -- 契約関連操作
          create_contract_ass(
             in_contract_line_id       => ln_contract_line_id                       -- 契約明細内部ID
           , iv_contract_status        => lv_contract_status                        -- 契約ステータス
-- == 2011-12-19 V1.5 Added START ======================================================================================
           , id_cancellation_date      => io_object_data_rec.cancellation_date      -- 中途解約日
-- == 2011-12-19 V1.5 Added END   ======================================================================================
           , in_created_by             => io_object_data_rec.created_by             -- 作成者
           , id_creation_date          => io_object_data_rec.creation_date          -- 作成日
           , in_last_updated_by        => io_object_data_rec.last_updated_by        -- 最終更新者
           , id_last_update_date       => io_object_data_rec.last_update_date       -- 最終更新日
           , in_last_update_login      => io_object_data_rec.last_update_login      -- 最終更新ﾛｸﾞｲﾝ
           , in_request_id             => io_object_data_rec.request_id             -- 要求ID
           , in_program_application_id => io_object_data_rec.program_application_id -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
           , in_program_id             => io_object_data_rec.program_id             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
           , id_program_update_date    => io_object_data_rec.program_update_date    -- ﾌﾟﾛｸﾞﾗﾑ更新日
           , ov_errbuf                 => lv_errbuf           -- エラー・メッセージ
           , ov_retcode                => lv_retcode          -- リターン・コード
           , ov_errmsg                 => lv_errmsg           -- ユーザー・エラー・メッセージ
          );
          --
          -- エラー終了時
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    --
    END IF;
  --
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END create_ob_det;
--
  /**********************************************************************************
   * Function Name    : create_ob_bat
   * Description      : リース物件情報作成（バッチ）
   ***********************************************************************************/
  PROCEDURE create_ob_bat(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'create_ob_bat';   -- プログラム名
    -- ステータス
    cv_ob_sts_cont_bef  CONSTANT xxcff_object_headers.object_status%TYPE := '101';  -- 未契約
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    -- ===============================
    -- カーソル
    -- ===============================
    CURSOR object_data_cur(
             iv_object_header_id  xxcff_object_headers.object_header_id%TYPE
    )
    IS
      SELECT    xoh.object_header_id        AS object_header_id       -- 物件内部ID
              , xoh.object_code             AS object_code            -- 物件コード
              , xoh.lease_class             AS lease_class            -- リース種別
              , xoh.lease_type              AS lease_type             -- リース区分
              , xoh.re_lease_times          AS re_lease_times         -- 再リース回数
              , xoh.po_number               AS po_number              -- 発注番号
              , xoh.registration_number     AS registration_number    -- 登録番号
              , xoh.age_type                AS age_type               -- 年式
              , xoh.model                   AS model                  -- 機種
              , xoh.serial_number           AS serial_number          -- 機番
              , xoh.quantity                AS quantity               -- 数量
              , xoh.manufacturer_name       AS manufacturer_name      -- メーカー名
              , xoh.department_code         AS department_code        -- 管理部門コード
              , xoh.owner_company           AS owner_company          -- 本社／工場
              , xoh.installation_address    AS installation_address   -- 現設置場所
              , xoh.installation_place      AS installation_place     -- 現設置先
              , xoh.chassis_number          AS chassis_number         -- 車台番号
              , xoh.re_lease_flag           AS re_lease_flag          -- 再リース要フラグ
              , xoh.cancellation_type       AS cancellation_type      -- 解約区分
              , xoh.cancellation_date       AS cancellation_date      -- 中途解約日
              , xoh.dissolution_date        AS dissolution_date       -- 中途解約キャンセル日
              , xoh.bond_acceptance_flag    AS bond_acceptance_flag   -- 証書受領フラグ
              , xoh.bond_acceptance_date    AS bond_acceptance_date   -- 証書受領日
              , xoh.expiration_date         AS expiration_date        -- 満了日
              , xoh.object_status           AS object_status          -- 物件ステータス
              , xoh.active_flag             AS active_flag            -- 物件有効フラグ
              , xoh.info_sys_if_date        AS info_sys_if_date       -- リース管理情報連携日
              , xoh.generation_date         AS generation_date        -- 発生日
              , xoh.customer_code           AS customer_code          -- 顧客コード
              , xoh.created_by              AS created_by             -- 作成者
              , xoh.creation_date           AS creation_date          -- 作成日
              , xoh.last_updated_by         AS last_updated_by        -- 最終更新者
              , xoh.last_update_date        AS last_update_date       -- 最終更新日
              , xoh.last_update_login       AS last_update_login      -- 最終更新ﾛｸﾞｲﾝ
              , xoh.request_id              AS request_id             -- 要求ID
              , xoh.program_application_id  AS program_application_id -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
              , xoh.program_id              AS program_id             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
              , xoh.program_update_date     AS program_update_date    -- ﾌﾟﾛｸﾞﾗﾑ更新日
              , NULL                        AS m_owner_company        -- 移動元本社工場
              , NULL                        AS m_department_code      -- 移動元管理部門
              , NULL                        AS m_installation_address -- 移動元現設置場所
              , NULL                        AS m_installation_place   -- 移動元現設置先
              , NULL                        AS m_registration_number  -- 移動元登録番号
              , NULL                        AS description            -- 摘要
      FROM      xxcff_object_headers xoh  -- リース物件
      WHERE     xoh.object_header_id = iv_object_header_id  -- 物件内部ID
      ;
    --
    -- ===============================
    -- ローカルレコード型変数
    -- ===============================
    object_data_rec      object_data_cur%ROWTYPE;
  --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    object_data_rec := NULL;
    --
    -- 物件内部IDがセットされていなかったら、新規作成
    IF ( io_object_data_rec.object_header_id IS NULL ) THEN
      --
      -- ***************************************************
      -- リース物件情報作成
      -- ***************************************************
      -- リース物件情報作成
      create_ob_det(
        iv_exce_mode       => cv_exce_mode_ins    -- 処理モード(追加)
       ,io_object_data_rec => io_object_data_rec  -- 物件情報
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode         => lv_retcode          -- リターン・コード
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      -- エラー終了時
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
    ELSE
    --
      -- ***************************************************
      -- 物件情報の取得
      -- ***************************************************
      -- カーソルオープン
      -- 移動する前の情報を取得したい。また、取り込み対象のデータとDBのデータを比較して
      -- 変更がかかった項目を後でチェックしたい。
      OPEN object_data_cur(
             io_object_data_rec.object_header_id  -- 物件内部ID
      );
      --
      -- レコード型にデータ保持
      FETCH object_data_cur INTO object_data_rec;
      --
      -- カーソルクローズ
      CLOSE object_data_cur;
      --
      io_object_data_rec.m_owner_company        := object_data_rec.owner_company;         -- 本社工場
      io_object_data_rec.m_department_code      := object_data_rec.department_code;       -- 管理部門
      io_object_data_rec.m_installation_address := object_data_rec.installation_address;  -- 現設置場所
      io_object_data_rec.m_installation_place   := object_data_rec.installation_place;    -- 現設置先
      io_object_data_rec.m_registration_number  := object_data_rec.registration_number;   -- 登録番号
      --
      -- 物件ステータスが「未契約」であったとき
      IF ( object_data_rec.object_status = cv_ob_sts_cont_bef ) THEN
        --
        -- ***************************************************
        -- リース物件情報作成
        -- ***************************************************
        create_ob_det(
          iv_exce_mode       => cv_exce_mode_chg    -- 処理モード(変更)
         ,io_object_data_rec => io_object_data_rec  -- 物件情報
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        --
        -- エラー終了時
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- 物件ステータスが「未契約」以外のとき
      ELSE
        --
        -- 移動項目に変更があったとき
        IF ( (   io_object_data_rec.owner_company        <> object_data_rec.owner_company        )  -- 本社工場
          OR (   io_object_data_rec.department_code      <> object_data_rec.department_code      )  -- 管理部門
          OR ( ( ( object_data_rec.installation_address    IS NOT NULL )                            -- 現設置場所
             AND ( io_object_data_rec.installation_address IS     NULL )
               )
            OR ( ( object_data_rec.installation_address    IS NULL     )
             AND ( io_object_data_rec.installation_address IS NOT NULL )
               )
            OR ( io_object_data_rec.installation_address <> object_data_rec.installation_address )
             )
          OR ( ( ( object_data_rec.installation_place      IS NULL     )                            -- 現設置先
             AND ( io_object_data_rec.installation_place   IS NOT NULL )
               )
            OR ( ( object_data_rec.installation_place      IS NOT NULL )
             AND ( io_object_data_rec.installation_place   IS     NULL )
               )
            OR ( io_object_data_rec.installation_place   <> object_data_rec.installation_place   )
             )
          OR ( ( ( object_data_rec.registration_number     IS NULL     )                            -- 登録番号
             AND ( io_object_data_rec.registration_number  IS NOT NULL )
               )
            OR ( ( object_data_rec.registration_number     IS NOT NULL )
             AND ( io_object_data_rec.registration_number  IS     NULL )
               )
            OR ( io_object_data_rec.registration_number  <> object_data_rec.registration_number  )
             )
        ) THEN
          --
          object_data_rec.m_owner_company        := object_data_rec.owner_company;            -- 移動元本社工場
          object_data_rec.m_department_code      := object_data_rec.department_code;          -- 移動元管理部門
          object_data_rec.m_installation_address := object_data_rec.installation_address;     -- 移動元現設置場所
          object_data_rec.m_installation_place   := object_data_rec.installation_place;       -- 移動元現設置先
          object_data_rec.m_registration_number  := object_data_rec.registration_number;      -- 移動元登録番号
          object_data_rec.description            := io_object_data_rec.description;           -- 摘要
          object_data_rec.owner_company          := io_object_data_rec.owner_company;         -- 本社工場
          object_data_rec.department_code        := io_object_data_rec.department_code;       -- 管理部門
          object_data_rec.installation_address   := io_object_data_rec.installation_address;  -- 現設置場所
          object_data_rec.installation_place     := io_object_data_rec.installation_place;    -- 現設置先
          object_data_rec.registration_number    := io_object_data_rec.registration_number;   -- 登録番号
          -- WHO値
          object_data_rec.created_by             := io_object_data_rec.created_by;             -- 作成者
          object_data_rec.creation_date          := io_object_data_rec.creation_date;          -- 作成日
          object_data_rec.last_updated_by        := io_object_data_rec.last_updated_by;        -- 最終更新者
          object_data_rec.last_update_date       := io_object_data_rec.last_update_date;       -- 最終更新日
          object_data_rec.last_update_login      := io_object_data_rec.last_update_login;      -- 最終更新ﾛｸﾞｲﾝ
          object_data_rec.request_id             := io_object_data_rec.request_id;             -- 要求ID
          object_data_rec.program_application_id := io_object_data_rec.program_application_id; -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          object_data_rec.program_id             := io_object_data_rec.program_id;             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          object_data_rec.program_update_date    := io_object_data_rec.program_update_date;    -- ﾌﾟﾛｸﾞﾗﾑ更新日
          -- ***************************************************
          -- リース物件情報作成
          -- ***************************************************
          create_ob_det(
            iv_exce_mode       => cv_exce_mode_mov    -- 処理モード(移動)
           ,io_object_data_rec => object_data_rec     -- 物件情報
           ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
           ,ov_retcode         => lv_retcode          -- リターン・コード
           ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
          );
          --
          -- エラー終了時
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --
        END IF;
        --
        -- 修正項目に変更があったとき
        IF ( ( ( ( io_object_data_rec.po_number         IS     NULL ) AND ( object_data_rec.po_number         IS NOT NULL ) )
            OR ( ( io_object_data_rec.po_number         IS NOT NULL ) AND ( object_data_rec.po_number         IS     NULL ) )
            OR ( ( io_object_data_rec.po_number         <> object_data_rec.po_number         ) )
             )                                                                                  -- 発注番号
          OR ( ( ( io_object_data_rec.age_type          IS     NULL ) AND ( object_data_rec.age_type          IS NOT NULL ) )
            OR ( ( io_object_data_rec.age_type          IS NOT NULL ) AND ( object_data_rec.age_type          IS     NULL ) )
            OR ( ( io_object_data_rec.age_type          <> object_data_rec.age_type          ) )
             )                                                                                  -- 年式
          OR ( ( ( io_object_data_rec.model             IS     NULL ) AND ( object_data_rec.model             IS NOT NULL ) )
            OR ( ( io_object_data_rec.model             IS NOT NULL ) AND ( object_data_rec.model             IS     NULL ) )
            OR ( ( io_object_data_rec.model             <> object_data_rec.model             ) )
             )                                                                                  -- 機種
          OR ( ( ( io_object_data_rec.serial_number     IS     NULL ) AND ( object_data_rec.serial_number     IS NOT NULL ) )
            OR ( ( io_object_data_rec.serial_number     IS NOT NULL ) AND ( object_data_rec.serial_number     IS     NULL ) )
            OR ( ( io_object_data_rec.serial_number     <> object_data_rec.serial_number     ) )
             )                                                                                  -- 機番
          OR ( io_object_data_rec.quantity          <> object_data_rec.quantity          )  -- 数量
          OR ( ( ( io_object_data_rec.chassis_number    IS     NULL ) AND ( object_data_rec.chassis_number    IS NOT NULL ) )
            OR ( ( io_object_data_rec.chassis_number    IS NOT NULL ) AND ( object_data_rec.chassis_number    IS     NULL ) )
            OR ( ( io_object_data_rec.chassis_number    <> object_data_rec.chassis_number    ) )
             )                                                                                  -- 車台番号
          OR ( ( ( io_object_data_rec.manufacturer_name IS     NULL ) AND ( object_data_rec.manufacturer_name IS NOT NULL ) )
            OR ( ( io_object_data_rec.manufacturer_name IS NOT NULL ) AND ( object_data_rec.manufacturer_name IS     NULL ) )
            OR ( ( io_object_data_rec.manufacturer_name <> object_data_rec.manufacturer_name ) )
             )                                                                                  -- メーカー名
          OR ( ( ( io_object_data_rec.customer_code     IS     NULL ) AND ( object_data_rec.customer_code     IS NOT NULL ) )
            OR ( ( io_object_data_rec.customer_code     IS NOT NULL ) AND ( object_data_rec.customer_code     IS     NULL ) )
            OR ( ( io_object_data_rec.customer_code     <> object_data_rec.customer_code     ) )
             )                                                                                  -- 顧客コード
          --【T1_0749】ADD START Matsunaka
          OR ( ( ( io_object_data_rec.active_flag       IS     NULL ) AND ( object_data_rec.active_flag       IS NOT NULL ) )
            OR ( ( io_object_data_rec.active_flag       IS NOT NULL ) AND ( object_data_rec.active_flag       IS     NULL ) )
            OR ( ( io_object_data_rec.active_flag       <> object_data_rec.active_flag     ) )
             )                                                                                  -- 物件有効フラグ
          --【T1_0749】ADD END   Matsunaka
        ) THEN
          --
          io_object_data_rec.m_owner_company         := NULL;     -- 移動元本社工場
          io_object_data_rec.m_department_code       := NULL;     -- 移動元管理部門
          io_object_data_rec.m_installation_address  := NULL;     -- 移動元現設置場所
          io_object_data_rec.m_installation_place    := NULL;     -- 移動元現設置先
          io_object_data_rec.m_registration_number   := NULL;     -- 移動元登録番号
--
          -- E_T4_00098 2009/12/02 ADD START
          io_object_data_rec.lease_type              := object_data_rec.lease_type;     -- リース区分
          io_object_data_rec.re_lease_times          := object_data_rec.re_lease_times; -- 再リース回数
          io_object_data_rec.re_lease_flag           := object_data_rec.re_lease_flag;  -- 再リース要否フラグ
          -- E_T4_00098 2009/12/02 ADD END
--
          -- ***************************************************
          -- リース物件情報作成
          -- ***************************************************
          create_ob_det(
            iv_exce_mode       => cv_exce_mode_adj    -- 処理モード(修正)
           ,io_object_data_rec => io_object_data_rec  -- 物件情報
           ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
           ,ov_retcode         => lv_retcode          -- リターン・コード
           ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
          );
          --
          -- エラー終了時
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    END IF;
    --
  --
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  固定部 END   #########################################
--
  END create_ob_bat;
--
END XXCFF_COMMON3_PKG
;
/
