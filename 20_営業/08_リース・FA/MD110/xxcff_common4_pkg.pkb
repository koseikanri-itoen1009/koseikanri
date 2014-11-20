create or replace PACKAGE BODY XXCFF_COMMON4_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcff_common4_pkg(body)
 * Description      : リース契約関連共通関数
 * MD.050           : なし
 * Version          : 1.1
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  insert_co_hed             P           リース契約登録関数
 *  insert_co_lin             P           リース契約明細登録関数
 *  insert_co_his             P           リース契約履歴登録関数
 *  update_co_hed             P           リース契約更新関数
 *  update_co_lin             P           リース契約明細更新関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-19    1.0   SCS礒崎祐次      新規作成
 *  2013-06-26    1.1   SCSK中野徹也     [E_本稼動_10871]消費税増税対応
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
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'xxcff_common4_pkg'; -- パッケージ名
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
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
   * Function Name    : insert_co_hed
   * Description      : リース契約登録
   ***********************************************************************************/
  PROCEDURE insert_co_hed(
    io_contract_data_rec   IN OUT NOCOPY cont_hed_data_rtype  -- 契約情報
   ,ov_errbuf              OUT NOCOPY VARCHAR2                -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2                -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_hed';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    -- ===============================
    -- ローカルテーブル型
    -- ===============================
    --
    -- ===============================
    -- ローカルテーブル型変数
    -- ===============================
    --
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.シーケンスの取得
    -- ***************************************************
    --
    SELECT    xxcff_contract_headers_s1.NEXTVAL
    INTO      io_contract_data_rec.contract_header_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.リース契約登録
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_headers(
       contract_header_id         -- 契約内部ID
     , contract_number            -- 契約番号
     , lease_class                -- リース種別
     , lease_type                 -- リース区分
     , lease_company              -- リース会社
     , re_lease_times             -- 再リース回数
     , comments                   -- 件名
     , contract_date              -- リース契約日
     , payment_frequency          -- 支払回数
     , payment_type               -- 頻度
     , payment_years              -- 年度
     , lease_start_date           -- リース開始日
     , lease_end_date             -- リース終了日
     , first_payment_date         -- 初回支払日
     , second_payment_date        -- ２回目支払日
     , third_payment_date         -- ３回目以降支払日
     , start_period_name          -- 費用計上会計会計期間   
     , lease_payment_flag         -- 支払計画完了フラグ
     , tax_code                   -- 税金コード
     , created_by                 -- 作成者
     , creation_date              -- 作成日
     , last_updated_by            -- 最終更新者
     , last_update_date           -- 最終更新日
     , last_update_login          -- 最終更新ﾛｸﾞｲﾝ
     , request_id                 -- 要求ID
     , program_application_id     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , program_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , program_update_date        -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
     VALUES(
       io_contract_data_rec.contract_header_id         -- 契約内部ID
     , io_contract_data_rec.contract_number            -- 契約番号
     , io_contract_data_rec.lease_class                -- リース種別
     , io_contract_data_rec.lease_type                 -- リース区分
     , io_contract_data_rec.lease_company              -- リース会社
     , io_contract_data_rec.re_lease_times             -- 再リース回数
     , io_contract_data_rec.comments                   -- 件名
     , io_contract_data_rec.contract_date              -- リース契約日
     , io_contract_data_rec.payment_frequency          -- 支払回数
     , io_contract_data_rec.payment_type               -- 頻度
     , io_contract_data_rec.payment_years              -- 年度
     , io_contract_data_rec.lease_start_date           -- リース開始日
     , io_contract_data_rec.lease_end_date             -- リース終了日
     , io_contract_data_rec.first_payment_date         -- 初回支払日
     , io_contract_data_rec.second_payment_date        -- ２回目支払日
     , io_contract_data_rec.third_payment_date         -- ３回目以降支払日
     , io_contract_data_rec.start_period_name          -- 費用計上会計会計期間   
     , io_contract_data_rec.lease_payment_flag         -- 支払計画完了フラグ
     , io_contract_data_rec.tax_code                   -- 税金コード
     , io_contract_data_rec.created_by                 -- 作成者
     , io_contract_data_rec.creation_date              -- 作成日
     , io_contract_data_rec.last_updated_by            -- 最終更新者
     , io_contract_data_rec.last_update_date           -- 最終更新日
     , io_contract_data_rec.last_update_login          -- 最終更新ﾛｸﾞｲﾝ
     , io_contract_data_rec.request_id                 -- 要求ID
     , io_contract_data_rec.program_application_id     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , io_contract_data_rec.program_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , io_contract_data_rec.program_update_date        -- ﾌﾟﾛｸﾞﾗﾑ更新日
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
  END insert_co_hed;
  --
  /**********************************************************************************
   * Function Name    : insert_co_lin
   * Description      : リース契約明細登録
   ***********************************************************************************/
  PROCEDURE insert_co_lin(
    io_contract_data_rec   IN OUT NOCOPY cont_lin_data_rtype  -- 契約明細情報
   ,ov_errbuf              OUT NOCOPY VARCHAR2                -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2                -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_lin';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    -- ===============================
    -- ローカルテーブル型
    -- ===============================
    --
    -- ===============================
    -- ローカルテーブル型変数
    -- ===============================
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.シーケンスの取得
    -- ***************************************************
    --
    SELECT    xxcff_contract_lines_s1.NEXTVAL
    INTO      io_contract_data_rec.contract_line_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.リース契約明細登録
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_lines(
       contract_line_id            -- 契約内部明細ID
     , contract_header_id          -- 契約内部ID
     , contract_line_num           -- 契約枝番
     , contract_status             -- 契約ステータス
     , first_charge                -- 初回月額リース料_リース料
     , first_tax_charge            -- 初回消費税額_リース料
     , first_total_charge          -- 初回計リース料
     , second_charge               -- ２回目月額リース料_リース料
     , second_tax_charge           -- ２回目消費税額_リース料
     , second_total_charge         -- ２回目計リース料
     , first_deduction             -- 初回月額リース料_控除額
     , first_tax_deduction         -- 初回消費税額_控除額
     , first_total_deduction       -- 初回計控除額
     , second_deduction            -- ２回目以降月額リース料_控除額
     , second_tax_deduction        -- ２回目以降消費税額_控除額
     , second_total_deduction      -- ２回目以降計控除額
     , gross_charge                -- 総額リース料_リース料
     , gross_tax_charge            -- 総額消費税額_リース料
     , gross_total_charge          -- 総額計_リース料
     , gross_deduction             -- 総額リース料_控除額
     , gross_tax_deduction         -- 総額消費税_控除額
     , gross_total_deduction       -- 総額計_控除額
     , lease_kind                  -- リース種類
     , estimated_cash_price        -- 見積現金購入金額
     , present_value_discount_rate -- 現金価値割引率
     , present_value               -- 現金価値
     , life_in_months              -- 法定耐用年数
     , original_cost               -- 取得価格
     , calc_interested_rate        -- 計算利子率
     , object_header_id            -- 物件内部id
     , asset_category              -- 資産種類
     , expiration_date             -- 満了日
     , cancellation_date           -- 中途解約日
     , vd_if_date                  -- リース契約情報連携日
     , info_sys_if_date            -- リース管理情報連携日
     , first_installation_address  -- 初回設置場所
     , first_installation_place    -- 初回設置先
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , tax_code                    -- 税金コード
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , created_by                  -- 作成者
     , creation_date               -- 作成日
     , last_updated_by             -- 最終更新者
     , last_update_date            -- 最終更新日
     , last_update_login           -- 最終更新ﾛｸﾞｲﾝ
     , request_id                  -- 要求ID
     , program_application_id      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , program_id                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , program_update_date         -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    VALUES(
       io_contract_data_rec.contract_line_id            -- 契約内部明細ID
     , io_contract_data_rec.contract_header_id          -- 契約内部ID
     , io_contract_data_rec.contract_line_num           -- 契約枝番
     , io_contract_data_rec.contract_status             -- 契約ステータス
     , io_contract_data_rec.first_charge                -- 初回月額リース料_リース料
     , io_contract_data_rec.first_tax_charge            -- 初回消費税額_リース料
     , io_contract_data_rec.first_total_charge          -- 初回計リース料
     , io_contract_data_rec.second_charge               -- ２回目月額リース料_リース料
     , io_contract_data_rec.second_tax_charge           -- ２回目消費税額_リース料
     , io_contract_data_rec.second_total_charge         -- ２回目計リース料
     , io_contract_data_rec.first_deduction             -- 初回月額リース料_控除額
     , io_contract_data_rec.first_tax_deduction         -- 初回消費税額_控除額
     , io_contract_data_rec.first_total_deduction       -- 初回計控除額
     , io_contract_data_rec.second_deduction            -- ２回目以降月額リース料_控除額
     , io_contract_data_rec.second_tax_deduction        -- ２回目以降消費税額_控除額
     , io_contract_data_rec.second_total_deduction      -- ２回目以降計控除額
     , io_contract_data_rec.gross_charge                -- 総額リース料_リース料
     , io_contract_data_rec.gross_tax_charge            -- 総額消費税額_リース料
     , io_contract_data_rec.gross_total_charge          -- 総額計_リース料
     , io_contract_data_rec.gross_deduction             -- 総額リース料_控除額
     , io_contract_data_rec.gross_tax_deduction         -- 総額消費税_控除額
     , io_contract_data_rec.gross_total_deduction       -- 総額計_控除額
     , io_contract_data_rec.lease_kind                  -- リース種類
     , io_contract_data_rec.estimated_cash_price        -- 見積現金購入金額
     , io_contract_data_rec.present_value_discount_rate -- 現金価値割引率
     , io_contract_data_rec.present_value               -- 現金価値
     , io_contract_data_rec.life_in_months              -- 法定耐用年数
     , io_contract_data_rec.original_cost               -- 取得価格
     , io_contract_data_rec.calc_interested_rate        -- 計算利子率
     , io_contract_data_rec.object_header_id            -- 物件内部id
     , io_contract_data_rec.asset_category              -- 資産種類
     , io_contract_data_rec.expiration_date             -- 満了日
     , io_contract_data_rec.cancellation_date           -- 中途解約日
     , io_contract_data_rec.vd_if_date                  -- リース契約情報連携日
     , io_contract_data_rec.info_sys_if_date            -- リース管理情報連携日
     , io_contract_data_rec.first_installation_address  -- 初回設置場所
     , io_contract_data_rec.first_installation_place    -- 初回設置先
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , io_contract_data_rec.tax_code                    -- 税金コード
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , io_contract_data_rec.created_by                  -- 作成者
     , io_contract_data_rec.creation_date               -- 作成日
     , io_contract_data_rec.last_updated_by             -- 最終更新者
     , io_contract_data_rec.last_update_date            -- 最終更新日
     , io_contract_data_rec.last_update_login           -- 最終更新ﾛｸﾞｲﾝ
     , io_contract_data_rec.request_id                  -- 要求ID
     , io_contract_data_rec.program_application_id      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , io_contract_data_rec.program_id                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , io_contract_data_rec.program_update_date         -- ﾌﾟﾛｸﾞﾗﾑ更新日
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
  END insert_co_lin;
  --
  /**********************************************************************************
   * Function Name    : insert_co_his
   * Description      : リース契約履歴登録
   ***********************************************************************************/
  PROCEDURE insert_co_his(
    io_contract_lin_data_rec IN OUT NOCOPY cont_lin_data_rtype  -- 契約明細情報
   ,io_contract_his_data_rec IN OUT NOCOPY cont_his_data_rtype  -- 契約履歴情報
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_his';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    ln_history_num  xxcff_contract_histories.history_num%TYPE; --変更履歴№
    --
    -- ===============================
    -- ローカルテーブル型
    -- ===============================
    --
    -- ===============================
    -- ローカルテーブル型変数
    -- ===============================
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.シーケンスの取得
    -- ***************************************************
    --
    SELECT    xxcff_contract_histories_s1.NEXTVAL
    INTO      ln_history_num
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.リース契約履歴登録
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_histories(
       contract_header_id          -- 契約内部ID
     , contract_line_id            -- 契約内部明細ID
     , history_num                 -- 変更履歴№
     , contract_status             -- 契約ステータス
     , first_charge                -- 初回月額リース料_リース料
     , first_tax_charge            -- 初回消費税額_リース料
     , first_total_charge          -- 初回計リース料
     , second_charge               -- ２回目月額リース料_リース料
     , second_tax_charge           -- ２回目消費税額_リース料
     , second_total_charge         -- ２回目計リース料
     , first_deduction             -- 初回月額リース料_控除額
     , first_tax_deduction         -- 初回消費税額_控除額
     , first_total_deduction       -- 初回計控除額
     , second_deduction            -- ２回目以降月額リース料_控除額
     , second_tax_deduction        -- ２回目以降消費税額_控除額
     , second_total_deduction      -- ２回目以降計控除額
     , gross_charge                -- 総額リース料_リース料
     , gross_tax_charge            -- 総額消費税額_リース料
     , gross_total_charge          -- 総額計_リース料
     , gross_deduction             -- 総額リース料_控除額
     , gross_tax_deduction         -- 総額消費税_控除額
     , gross_total_deduction       -- 総額計_控除額
     , lease_kind                  -- リース種類
     , estimated_cash_price        -- 見積現金購入金額
     , present_value_discount_rate -- 現金価値割引率
     , present_value               -- 現金価値
     , life_in_months              -- 法定耐用年数
     , original_cost               -- 取得価格
     , calc_interested_rate        -- 計算利子率
     , object_header_id            -- 物件内部id
     , asset_category              -- 資産種類
     , expiration_date             -- 満了日
     , cancellation_date           -- 中途解約日
     , vd_if_date                  -- リース契約情報連携日
     , info_sys_if_date            -- リース管理情報連携日
     , first_installation_address  -- 初回設置場所
     , first_installation_place    -- 初回設置先
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , tax_code                    -- 税金コード
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , accounting_date             -- 計上日
     , accounting_if_flag          -- 会計IFフラグ
     , description                 -- 摘要
     , created_by                  -- 作成者
     , creation_date               -- 作成日
     , last_updated_by             -- 最終更新者
     , last_update_date            -- 最終更新日
     , last_update_login           -- 最終更新ﾛｸﾞｲﾝ
     , request_id                  -- 要求ID
     , program_application_id      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , program_id                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , program_update_date         -- ﾌﾟﾛｸﾞﾗﾑ更新日
     )
    VALUES(
       io_contract_lin_data_rec.contract_header_id          -- 契約内部ID
     , io_contract_lin_data_rec.contract_line_id            -- 契約内部明細ID
     , ln_history_num                                       -- 変更履歴№
     , io_contract_lin_data_rec.contract_status             -- 契約ステータス
     , io_contract_lin_data_rec.first_charge                -- 初回月額リース料_リース料
     , io_contract_lin_data_rec.first_tax_charge            -- 初回消費税額_リース料
     , io_contract_lin_data_rec.first_total_charge          -- 初回計リース料
     , io_contract_lin_data_rec.second_charge               -- ２回目月額リース料_リース料
     , io_contract_lin_data_rec.second_tax_charge           -- ２回目消費税額_リース料
     , io_contract_lin_data_rec.second_total_charge         -- ２回目計リース料
     , io_contract_lin_data_rec.first_deduction             -- 初回月額リース料_控除額
     , io_contract_lin_data_rec.first_tax_deduction         -- 初回消費税額_控除額
     , io_contract_lin_data_rec.first_total_deduction       -- 初回計控除額
     , io_contract_lin_data_rec.second_deduction            -- ２回目以降月額リース料_控除額
     , io_contract_lin_data_rec.second_tax_deduction        -- ２回目以降消費税額_控除額
     , io_contract_lin_data_rec.second_total_deduction      -- ２回目以降計控除額
     , io_contract_lin_data_rec.gross_charge                -- 総額リース料_リース料
     , io_contract_lin_data_rec.gross_tax_charge            -- 総額消費税額_リース料
     , io_contract_lin_data_rec.gross_total_charge          -- 総額計_リース料
     , io_contract_lin_data_rec.gross_deduction             -- 総額リース料_控除額
     , io_contract_lin_data_rec.gross_tax_deduction         -- 総額消費税_控除額
     , io_contract_lin_data_rec.gross_total_deduction       -- 総額計_控除額
     , io_contract_lin_data_rec.lease_kind                  -- リース種類
     , io_contract_lin_data_rec.estimated_cash_price        -- 見積現金購入金額
     , io_contract_lin_data_rec.present_value_discount_rate -- 現金価値割引率
     , io_contract_lin_data_rec.present_value               -- 現金価値
     , io_contract_lin_data_rec.life_in_months              -- 法定耐用年数
     , io_contract_lin_data_rec.original_cost               -- 取得価格
     , io_contract_lin_data_rec.calc_interested_rate        -- 計算利子率
     , io_contract_lin_data_rec.object_header_id            -- 物件内部id
     , io_contract_lin_data_rec.asset_category              -- 資産種類
     , io_contract_lin_data_rec.expiration_date             -- 満了日
     , io_contract_lin_data_rec.cancellation_date           -- 中途解約日
     , io_contract_lin_data_rec.vd_if_date                  -- リース契約情報連携日
     , io_contract_lin_data_rec.info_sys_if_date            -- リース管理情報連携日
     , io_contract_lin_data_rec.first_installation_address  -- 初回設置場所
     , io_contract_lin_data_rec.first_installation_place    -- 初回設置先
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , io_contract_lin_data_rec.tax_code                    -- 税金コード
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , io_contract_his_data_rec.accounting_date             -- 計上日
     , io_contract_his_data_rec.accounting_if_flag          -- 会計IFフラグ
     , io_contract_his_data_rec.description                 -- 摘要
     , io_contract_lin_data_rec.created_by                  -- 作成者
     , io_contract_lin_data_rec.creation_date               -- 作成日
     , io_contract_lin_data_rec.last_updated_by             -- 最終更新者
     , io_contract_lin_data_rec.last_update_date            -- 最終更新日
     , io_contract_lin_data_rec.last_update_login           -- 最終更新ﾛｸﾞｲﾝ
     , io_contract_lin_data_rec.request_id                  -- 要求ID
     , io_contract_lin_data_rec.program_application_id      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
     , io_contract_lin_data_rec.program_id                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
     , io_contract_lin_data_rec.program_update_date         -- ﾌﾟﾛｸﾞﾗﾑ更新日
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
  END insert_co_his;
  --
  /**********************************************************************************
   * Function Name    : update_co_hed
   * Description      : リース契約更新
   ***********************************************************************************/
  PROCEDURE update_co_hed(
    io_contract_data_rec IN OUT NOCOPY cont_hed_data_rtype    -- 契約情報
   ,ov_errbuf               OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode              OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg               OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_co_hed';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    -- ===============================
    -- ローカルテーブル型
    -- ===============================
    --
    -- ===============================
    -- ローカルテーブル型変数
    -- ===============================
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.リース契約更新
    -- ***************************************************
    --
    UPDATE xxcff_contract_headers  xch  -- リース契約テーブル
    SET    xch.contract_number         = io_contract_data_rec.contract_number            -- 契約番号
         , xch.lease_class             = io_contract_data_rec.lease_class                -- リース種別
         , xch.lease_type              = io_contract_data_rec.lease_type                 -- リース区分
         , xch.lease_company           = io_contract_data_rec.lease_company              -- リース会社
         , xch.re_lease_times          = io_contract_data_rec.re_lease_times             -- 再リース回数
         , xch.comments                = io_contract_data_rec.comments                   -- 件名
         , xch.contract_date           = io_contract_data_rec.contract_date              -- リース契約日
         , xch.payment_frequency       = io_contract_data_rec.payment_frequency          -- 支払回数
         , xch.payment_type            = io_contract_data_rec.payment_type               -- 頻度
         , xch.payment_years           = io_contract_data_rec.payment_years              -- 年度
         , xch.lease_start_date        = io_contract_data_rec.lease_start_date           -- リース開始日
         , xch.lease_end_date          = io_contract_data_rec.lease_end_date             -- リース終了日
         , xch.first_payment_date      = io_contract_data_rec.first_payment_date         -- 初回支払日
         , xch.second_payment_date     = io_contract_data_rec.second_payment_date        -- ２回目支払日
         , xch.third_payment_date      = io_contract_data_rec.third_payment_date         -- ３回目以降支払日
         , xch.start_period_name       = io_contract_data_rec.start_period_name          -- 費用計上会計会計期間   
         , xch.lease_payment_flag      = io_contract_data_rec.lease_payment_flag         -- 支払計画完了フラグ
         , xch.tax_code                = io_contract_data_rec.tax_code                   -- 税コード
         , xch.created_by              = io_contract_data_rec.created_by                 -- 作成者
         , xch.creation_date           = io_contract_data_rec.creation_date              -- 作成日
         , xch.last_updated_by         = io_contract_data_rec.last_updated_by            -- 最終更新者
         , xch.last_update_date        = io_contract_data_rec.last_update_date           -- 最終更新日
         , xch.last_update_login       = io_contract_data_rec.last_update_login          -- 最終更新ﾛｸﾞｲﾝ
         , xch.request_id              = io_contract_data_rec.request_id                 -- 要求ID
         , xch.program_application_id  = io_contract_data_rec.program_application_id     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , xch.program_id              = io_contract_data_rec.program_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , xch.program_update_date     = io_contract_data_rec.program_update_date        -- ﾌﾟﾛｸﾞﾗﾑ更新日     
    WHERE  xch.contract_header_id      = io_contract_data_rec.contract_header_id         -- 契約内部ID
    ;
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
  END update_co_hed;
  --
  /**********************************************************************************
   * Function Name    : update_co_lin
   * Description      : リース契約明細更新
   ***********************************************************************************/
  PROCEDURE update_co_lin(
    io_contract_data_rec IN OUT NOCOPY cont_lin_data_rtype    -- 契約明細情報
   ,ov_errbuf               OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode              OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg               OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_co_lin';   -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ユーザー・エラー・メッセージ
    --
    -- ===============================
    -- ローカルテーブル型
    -- ===============================
    TYPE null_check_ttype IS TABLE OF VARCHAR2(5000);
    -- ===============================
    -- ローカルテーブル型変数
    -- ===============================
    l_null_check_tab   null_check_ttype := null_check_ttype();  -- 必須チェック
    --
  BEGIN
  --
    -- 初期化
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    -- ***************************************************
    -- 1.リース契約更新
    -- ***************************************************
    --
    UPDATE xxcff_contract_lines xcl  -- リース契約明細テーブル
    SET    xcl.contract_line_num           = io_contract_data_rec.contract_line_num           -- 契約枝番
         , xcl.contract_status             = io_contract_data_rec.contract_status             -- 契約ステータス
         , xcl.first_charge                = io_contract_data_rec.first_charge                -- 初回月額リース料_リース料
         , xcl.first_tax_charge            = io_contract_data_rec.first_tax_charge            -- 初回消費税額_リース料
         , xcl.first_total_charge          = io_contract_data_rec.first_total_charge          -- 初回計リース料
         , xcl.second_charge               = io_contract_data_rec.second_charge               -- ２回目月額リース料_リース料
         , xcl.second_tax_charge           = io_contract_data_rec.second_tax_charge           -- ２回目消費税額_リース料
         , xcl.second_total_charge         = io_contract_data_rec.second_total_charge         -- ２回目計リース料
         , xcl.first_deduction             = io_contract_data_rec.first_deduction             -- 初回月額リース料_控除額
         , xcl.first_tax_deduction         = io_contract_data_rec.first_tax_deduction         -- 初回消費税額_控除額
         , xcl.first_total_deduction       = io_contract_data_rec.first_total_deduction       -- 初回計控除額
         , xcl.second_deduction            = io_contract_data_rec.second_deduction            -- ２回目以降月額リース料_控除額
         , xcl.second_tax_deduction        = io_contract_data_rec.second_tax_deduction        -- ２回目以降消費税額_控除額
         , xcl.second_total_deduction      = io_contract_data_rec.second_total_deduction      -- ２回目以降計控除額
         , xcl.gross_charge                = io_contract_data_rec.gross_charge                -- 総額リース料_リース料
         , xcl.gross_tax_charge            = io_contract_data_rec.gross_tax_charge            -- 総額消費税額_リース料
         , xcl.gross_total_charge          = io_contract_data_rec.gross_total_charge          -- 総額計_リース料
         , xcl.gross_deduction             = io_contract_data_rec.gross_deduction             -- 総額リース料_控除額
         , xcl.gross_tax_deduction         = io_contract_data_rec.gross_tax_deduction         -- 総額消費税_控除額
         , xcl.gross_total_deduction       = io_contract_data_rec.gross_total_deduction       -- 総額計_控除額
         , xcl.lease_kind                  = io_contract_data_rec.lease_kind                  -- リース種類
         , xcl.estimated_cash_price        = io_contract_data_rec.estimated_cash_price        -- 見積現金購入金額
         , xcl.present_value_discount_rate = io_contract_data_rec.present_value_discount_rate -- 現金価値割引率
         , xcl.present_value               = io_contract_data_rec.present_value               -- 現金価値
         , xcl.life_in_months              = io_contract_data_rec.life_in_months              -- 法定耐用年数
         , xcl.original_cost               = io_contract_data_rec.original_cost               -- 取得価格
         , xcl.calc_interested_rate        = io_contract_data_rec.calc_interested_rate        -- 計算利子率
         , xcl.object_header_id            = io_contract_data_rec.object_header_id            -- 物件内部id
         , xcl.asset_category              = io_contract_data_rec.asset_category              -- 資産種類
         , xcl.expiration_date             = io_contract_data_rec.expiration_date             -- 満了日
         , xcl.cancellation_date           = io_contract_data_rec.cancellation_date           -- 中途解約日
         , xcl.vd_if_date                  = io_contract_data_rec.vd_if_date                  -- リース契約情報連携日
         , xcl.info_sys_if_date            = io_contract_data_rec.info_sys_if_date            -- リース管理情報連携日
         , xcl.first_installation_address  = io_contract_data_rec.first_installation_address  -- 初回設置場所
         , xcl.first_installation_place    = io_contract_data_rec.first_installation_place    -- 初回設置先
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
         , xcl.tax_code                    = io_contract_data_rec.tax_code                    -- 税金コード
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
         , xcl.created_by                  = io_contract_data_rec.created_by                  -- 作成者
         , xcl.creation_date               = io_contract_data_rec.creation_date               -- 作成日
         , xcl.last_updated_by             = io_contract_data_rec.last_updated_by             -- 最終更新者
         , xcl.last_update_date            = io_contract_data_rec.last_update_date            -- 最終更新日
         , xcl.last_update_login           = io_contract_data_rec.last_update_login           -- 最終更新ﾛｸﾞｲﾝ
         , xcl.request_id                  = io_contract_data_rec.request_id                  -- 要求ID
         , xcl.program_application_id      = io_contract_data_rec.program_application_id      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , xcl.program_id                  = io_contract_data_rec.program_id                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , xcl.program_update_date         = io_contract_data_rec.program_update_date         -- ﾌﾟﾛｸﾞﾗﾑ更新日
    WHERE  xcl.contract_header_id          = io_contract_data_rec.contract_header_id          -- 契約内部ID
      AND  xcl.contract_line_id            = io_contract_data_rec.contract_line_id            -- 契約明細内部ID
    ;
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
  END update_co_lin;
  --
END XXCFF_COMMON4_PKG;
/