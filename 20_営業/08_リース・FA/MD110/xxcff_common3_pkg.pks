CREATE OR REPLACE PACKAGE XXCFF_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON3_PKG(spec)
 * Description      : リース物件関連共通関数
 * MD.050           : なし
 * Version          : 1.0
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
 *
 *****************************************************************************************/
--
--#######################  レコード型宣言部 START   #######################
--
  -- 物件情報
  TYPE object_data_rtype IS RECORD(
     object_header_id        xxcff_object_headers.object_header_id%TYPE           -- 物件内部ID
   , object_code             xxcff_object_headers.object_code%TYPE                -- 物件コード
   , lease_class             xxcff_object_headers.lease_class%TYPE                -- リース種別
   , lease_type              xxcff_object_headers.lease_type%TYPE DEFAULT 1       -- リース区分
   , re_lease_times          xxcff_object_headers.re_lease_times%TYPE DEFAULT 0   -- 再リース回数
   , po_number               xxcff_object_headers.po_number%TYPE                  -- 発注番号
   , registration_number     xxcff_object_headers.registration_number%TYPE        -- 登録番号
   , age_type                xxcff_object_headers.age_type%TYPE                   -- 年式
   , model                   xxcff_object_headers.model%TYPE                      -- 機種
   , serial_number           xxcff_object_headers.serial_number%TYPE              -- 機番
   , quantity                xxcff_object_headers.quantity%TYPE                   -- 数量
   , manufacturer_name       xxcff_object_headers.manufacturer_name%TYPE          -- メーカー名
   , department_code         xxcff_object_headers.department_code%TYPE            -- 管理部門コード
   , owner_company           xxcff_object_headers.owner_company%TYPE              -- 本社／工場
   , installation_address    xxcff_object_headers.installation_address%TYPE       -- 現設置場所
   , installation_place      xxcff_object_headers.installation_place%TYPE         -- 現設置先
   , chassis_number          xxcff_object_headers.chassis_number%TYPE             -- 車台番号
   , re_lease_flag           xxcff_object_headers.re_lease_flag%TYPE DEFAULT 0    -- 再リース要フラグ
   , cancellation_type       xxcff_object_headers.cancellation_type%TYPE          -- 解約区分
   , cancellation_date       xxcff_object_headers.cancellation_date%TYPE          -- 中途解約日
   , dissolution_date        xxcff_object_headers.dissolution_date%TYPE           -- 中途解約キャンセル日
   , bond_acceptance_flag    xxcff_object_headers.bond_acceptance_flag%TYPE DEFAULT 0 -- 証書受領フラグ
   , bond_acceptance_date    xxcff_object_headers.bond_acceptance_date%TYPE       -- 証書受領日
   , expiration_date         xxcff_object_headers.expiration_date%TYPE            -- 満了日
   , object_status           xxcff_object_headers.object_status%TYPE              -- 物件ステータス
   , active_flag             xxcff_object_headers.active_flag%TYPE DEFAULT 'Y'    -- 物件有効フラグ
   , info_sys_if_date        xxcff_object_headers.info_sys_if_date%TYPE           -- リース管理情報連携日
   , generation_date         xxcff_object_headers.generation_date%TYPE            -- 発生日
   , customer_code           xxcff_object_headers.customer_code%TYPE DEFAULT NULL -- 顧客コード
   , created_by              xxcff_object_headers.created_by%TYPE                 -- 作成者
   , creation_date           xxcff_object_headers.creation_date%TYPE              -- 作成日
   , last_updated_by         xxcff_object_headers.last_updated_by%TYPE            -- 最終更新者
   , last_update_date        xxcff_object_headers.last_update_date%TYPE           -- 最終更新日
   , last_update_login       xxcff_object_headers.last_update_login%TYPE          -- 最終更新ﾛｸﾞｲﾝ
   , request_id              xxcff_object_headers.request_id%TYPE                 -- 要求ID
   , program_application_id  xxcff_object_headers.program_application_id%TYPE     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
   , program_id              xxcff_object_headers.program_id%TYPE                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
   , program_update_date     xxcff_object_headers.program_update_date%TYPE        -- ﾌﾟﾛｸﾞﾗﾑ更新日
   , m_owner_company         xxcff_object_histories.m_owner_company%TYPE          -- 移動元本社工場
   , m_department_code       xxcff_object_histories.m_department_code%TYPE        -- 移動元管理部門
   , m_installation_address  xxcff_object_histories.m_installation_address%TYPE   -- 移動元現設置場所
   , m_installation_place    xxcff_object_histories.m_installation_place%TYPE     -- 移動元現設置先
   , m_registration_number   xxcff_object_histories.m_registration_number%TYPE    -- 移動元登録番号
   , description             xxcff_object_histories.description%TYPE              -- 摘要
  );
  --
  --#######################  テーブル型宣言部 START   #######################
  --
  --#######################  プロシージャ宣言部 START   #######################
  --
  --
  -- リース物件登録関数
  PROCEDURE insert_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  );
  --
  -- リース物件履歴登録関数
  PROCEDURE insert_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  );
  --
  -- リース物件更新関数
  PROCEDURE update_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  );
  --
  -- リース物件履歴更新関数
  PROCEDURE update_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  );
  --
  -- リース物件情報作成
  PROCEDURE create_ob_det(
    iv_exce_mode           IN        VARCHAR2,           -- 処理モード
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  );
  --
  -- リース物件情報作成（バッチ）
  PROCEDURE create_ob_bat(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- 物件情報
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- エラー・メッセージ
    ov_retcode            OUT NOCOPY VARCHAR2,           -- リターン・コード
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ユーザー・エラー・メッセージ
  );
  --
--
END XXCFF_COMMON3_PKG
;
/
