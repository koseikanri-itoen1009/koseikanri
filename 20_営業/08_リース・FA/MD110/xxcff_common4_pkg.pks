create or replace PACKAGE XXCFF_COMMON4_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcff_common4_pkg(spec)
 * Description      : リース契約関連共通関数
 * MD.050           : なし
 * Version          : 1.2
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
 *  Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-19    1.0   SCS礒崎祐次       新規作成
 *  2008-12-22    1.1   SCS礒崎祐次       税金コードを追加
 *  2013-06-25    1.2   SCSK中野徹也      [E_本稼動_10871]消費税増税対応
 *
 *****************************************************************************************/
--
--#######################  レコード型宣言部 START   #######################
--
  -- リース契約情報
  TYPE cont_hed_data_rtype IS RECORD(
     contract_header_id         xxcff_contract_headers.contract_header_id%TYPE         -- 契約内部ID
   , contract_number            xxcff_contract_headers.contract_number%TYPE            -- 契約番号
   , lease_class                xxcff_contract_headers.lease_class%TYPE                -- リース種別
   , lease_type                 xxcff_contract_headers.lease_type%TYPE                 -- リース区分
   , lease_company              xxcff_contract_headers.lease_company%TYPE              -- リース会社
   , re_lease_times             xxcff_contract_headers.re_lease_times%TYPE DEFAULT 0   -- 再リース回数
   , comments                   xxcff_contract_headers.comments%TYPE                   -- 件名
   , contract_date              xxcff_contract_headers.contract_date%TYPE              -- リース契約日
   , payment_frequency          xxcff_contract_headers.payment_frequency%TYPE          -- 支払回数
   , payment_type               xxcff_contract_headers.payment_type%TYPE               -- 頻度
   , payment_years              xxcff_contract_headers.payment_years%TYPE              -- 年度
   , lease_start_date           xxcff_contract_headers.lease_start_date%TYPE           -- リース開始日
   , lease_end_date             xxcff_contract_headers.lease_end_date%TYPE             -- リース終了日
   , first_payment_date         xxcff_contract_headers.first_payment_date%TYPE         -- 初回支払日
   , second_payment_date        xxcff_contract_headers.second_payment_date%TYPE        -- ２回目支払日
   , third_payment_date         xxcff_contract_headers.third_payment_date%TYPE         -- ３回目以降支払日
   , start_period_name          xxcff_contract_headers.start_period_name%TYPE          -- 費用計上会計会計期間   
   , lease_payment_flag         xxcff_contract_headers.lease_payment_flag%TYPE         -- 支払計画完了フラグ
   , tax_code                   xxcff_contract_headers.tax_code%TYPE                   -- 税コード
   , created_by                 xxcff_contract_headers.created_by%TYPE                 -- 作成者
   , creation_date              xxcff_contract_headers.creation_date%TYPE              -- 作成日
   , last_updated_by            xxcff_contract_headers.last_updated_by%TYPE            -- 最終更新者
   , last_update_date           xxcff_contract_headers.last_update_date%TYPE           -- 最終更新日
   , last_update_login          xxcff_contract_headers.last_update_login%TYPE          -- 最終更新ﾛｸﾞｲﾝ
   , request_id                 xxcff_contract_headers.request_id%TYPE                 -- 要求ID
   , program_application_id     xxcff_contract_headers.program_application_id%TYPE     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
   , program_id                 xxcff_contract_headers.program_id%TYPE                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
   , program_update_date        xxcff_contract_headers.program_update_date%TYPE        -- ﾌﾟﾛｸﾞﾗﾑ更新日
  );
  --    
  -- リース契約明細情報
  TYPE cont_lin_data_rtype IS RECORD(
     contract_line_id           xxcff_contract_lines.contract_line_id%TYPE             -- 契約内部明細ID
   , contract_header_id         xxcff_contract_lines.contract_header_id%TYPE           -- 契約内部ID
   , contract_line_num          xxcff_contract_lines.contract_line_num%TYPE            -- 契約枝番
-- 2013/06/25 Ver.1.2 T.Nakano ADD Start
   , tax_code                   xxcff_contract_lines.tax_code%TYPE                     -- 税金コード
-- 2013/06/25 Ver.1.2 T.Nakano ADD End
   , contract_status            xxcff_contract_lines.contract_status%TYPE              -- 契約ステータス
   , first_charge               xxcff_contract_lines.first_charge%TYPE                 -- 初回月額リース料_リース料
   , first_tax_charge           xxcff_contract_lines.first_tax_charge%TYPE             -- 初回消費税額_リース料
   , first_total_charge         xxcff_contract_lines.first_total_charge%TYPE           -- 初回計リース料
   , second_charge              xxcff_contract_lines.second_charge%TYPE                -- ２回目月額リース料_リース料
   , second_tax_charge          xxcff_contract_lines.second_tax_charge%TYPE            -- ２回目消費税額_リース料
   , second_total_charge        xxcff_contract_lines.second_total_charge%TYPE          -- ２回目計リース料
   , first_deduction            xxcff_contract_lines.first_deduction%TYPE              -- 初回月額リース料_控除額
   , first_tax_deduction        xxcff_contract_lines.first_tax_deduction%TYPE          -- 初回消費税額_控除額
   , first_total_deduction      xxcff_contract_lines.first_total_deduction%TYPE        -- 初回計控除額
   , second_deduction           xxcff_contract_lines.second_deduction%TYPE             -- ２回目以降月額リース料_控除額
   , second_tax_deduction       xxcff_contract_lines.second_tax_deduction%TYPE         -- ２回目以降消費税額_控除額
   , second_total_deduction     xxcff_contract_lines.second_total_deduction%TYPE       -- ２回目以降計控除額
   , gross_charge               xxcff_contract_lines.gross_charge%TYPE                 -- 総額リース料_リース料
   , gross_tax_charge           xxcff_contract_lines.gross_tax_charge%TYPE             -- 総額消費税額_リース料
   , gross_total_charge         xxcff_contract_lines.gross_total_charge%TYPE           -- 総額計_リース料
   , gross_deduction            xxcff_contract_lines.gross_deduction%TYPE              -- 総額リース料_控除額
   , gross_tax_deduction        xxcff_contract_lines.gross_tax_deduction%TYPE          -- 総額消費税_控除額
   , gross_total_deduction      xxcff_contract_lines.gross_total_deduction%TYPE        -- 総額計_控除額
   , lease_kind                 xxcff_contract_lines.lease_kind%TYPE                   -- リース種類
   , estimated_cash_price       xxcff_contract_lines.estimated_cash_price%TYPE         -- 見積現金購入金額
   , present_value_discount_rate xxcff_contract_lines.present_value_discount_rate%TYPE -- 現金価値割引率
   , present_value              xxcff_contract_lines.present_value%TYPE                -- 現金価値
   , life_in_months             xxcff_contract_lines.life_in_months%TYPE               -- 法定耐用年数
   , original_cost              xxcff_contract_lines.original_cost%TYPE                -- 取得価格
   , calc_interested_rate       xxcff_contract_lines.calc_interested_rate%TYPE         -- 計算利子率
   , object_header_id           xxcff_contract_lines.object_header_id%TYPE             -- 物件内部id
   , asset_category             xxcff_contract_lines.asset_category%TYPE               -- 資産種類
   , expiration_date            xxcff_contract_lines.expiration_date%TYPE              -- 満了日
   , cancellation_date          xxcff_contract_lines.cancellation_date%TYPE            -- 中途解約日
   , vd_if_date                 xxcff_contract_lines.vd_if_date%TYPE                   -- リース契約情報連携日
   , info_sys_if_date           xxcff_contract_lines.info_sys_if_date%TYPE             -- リース管理情報連携日
   , first_installation_address xxcff_contract_lines.first_installation_address%TYPE   -- 初回設置場所
   , first_installation_place   xxcff_contract_lines.first_installation_place%TYPE     -- 初回設置先
   , created_by                 xxcff_contract_lines.created_by%TYPE                   -- 作成者
   , creation_date              xxcff_contract_lines.creation_date%TYPE                -- 作成日
   , last_updated_by            xxcff_contract_lines.last_updated_by%TYPE              -- 最終更新者
   , last_update_date           xxcff_contract_lines.last_update_date%TYPE             -- 最終更新日
   , last_update_login          xxcff_contract_lines.last_update_login%TYPE            -- 最終更新ﾛｸﾞｲﾝ
   , request_id                 xxcff_contract_lines.request_id%TYPE                   -- 要求ID
   , program_application_id     xxcff_contract_lines.program_application_id%TYPE       -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
   , program_id                 xxcff_contract_lines.program_id%TYPE                   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
   , program_update_date        xxcff_contract_lines.program_update_date%TYPE          -- ﾌﾟﾛｸﾞﾗﾑ更新日
  );
  --
  -- リース契約履歴情報
  TYPE cont_his_data_rtype IS RECORD(
     accounting_date            xxcff_contract_histories.accounting_date%TYPE          -- 計上日
   , accounting_if_flag         xxcff_contract_histories.accounting_if_flag%TYPE       -- 会計IFフラグ
   , description                xxcff_contract_histories.description%TYPE              -- 摘要
  );
  --
  --#######################  プロシージャ宣言部 START   #######################
  --
  --
  -- リース契約登録関数
  PROCEDURE insert_co_hed(
    io_contract_data_rec    IN OUT NOCOPY cont_hed_data_rtype    -- 契約情報
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  );
  --
  -- リース契約明細登録関数
  PROCEDURE insert_co_lin(
    io_contract_data_rec    IN OUT NOCOPY cont_lin_data_rtype    -- 契約明細情報
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  );
 --
  -- リース契約履歴登録関数
  PROCEDURE insert_co_his(
    io_contract_lin_data_rec IN OUT NOCOPY cont_lin_data_rtype   -- 契約明細情報
   ,io_contract_his_data_rec IN OUT NOCOPY cont_his_data_rtype   -- 契約履歴情報
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  );
  --
  -- リース契約更新関数
  PROCEDURE update_co_hed(
    io_contract_data_rec    IN OUT NOCOPY cont_hed_data_rtype    -- 契約情報
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  );
  --
  -- リース契約明細更新関数
  PROCEDURE update_co_lin(
    io_contract_data_rec    IN OUT NOCOPY cont_lin_data_rtype    -- 契約明細情報
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ
  );
  --
  --
END XXCFF_COMMON4_PKG
;
/