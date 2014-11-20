-- 入金管理管理テーブルの登録（移行用初期データ）
-- 入金データ
INSERT INTO xxcfo_ar_cash_control(
    business_date             -- 業務日付
  , control_id                -- 管理ID
  , trx_type                  -- タイプ
  , process_flag              -- 処理済フラグ
  , created_by                -- 作成者
  , creation_date             -- 作成日
  , last_updated_by           -- 最終更新者
  , last_update_date          -- 最終更新日
  , last_update_login         -- 最終更新ログイン
  , request_id                -- 要求ID
  , program_application_id    -- コンカレント・プログラム・アプリケーションID
  , program_id                -- コンカレント・プログラムID
  , program_update_date       -- プログラム更新日
) VALUES (
    xxccp_common_pkg2.get_process_date
                              -- 業務日付
  , 1                         -- 管理ID
  , '入金'                    -- タイプ
  , 'Y'                       -- 処理済フラグ
  , -1                        -- 作成者
  , SYSDATE                   -- 作成日
  , -1                        -- 最終更新者
  , SYSDATE                   -- 最終更新日
  , NULL                      -- 最終更新ログイン
  , NULL                      -- 要求ID
  , NULL                      -- コンカレント・プログラム・アプリケーションID
  , NULL                      -- コンカレント・プログラムID
  , NULL                      -- プログラム更新日
);
-- 消込データ
INSERT INTO xxcfo_ar_cash_control(
    business_date             -- 業務日付
  , control_id                -- 管理ID
  , trx_type                  -- タイプ
  , process_flag              -- 処理済フラグ
  , created_by                -- 作成者
  , creation_date             -- 作成日
  , last_updated_by           -- 最終更新者
  , last_update_date          -- 最終更新日
  , last_update_login         -- 最終更新ログイン
  , request_id                -- 要求ID
  , program_application_id    -- コンカレント・プログラム・アプリケーションID
  , program_id                -- コンカレント・プログラムID
  , program_update_date       -- プログラム更新日
) VALUES (
    xxccp_common_pkg2.get_process_date
                              -- 業務日付
  , 1                         -- 管理ID
  , '消込'                    -- タイプ
  , 'Y'                       -- 処理済フラグ
  , -1                        -- 作成者
  , SYSDATE                   -- 作成日
  , -1                        -- 最終更新者
  , SYSDATE                   -- 最終更新日
  , NULL                      -- 最終更新ログイン
  , NULL                      -- 要求ID
  , NULL                      -- コンカレント・プログラム・アプリケーションID
  , NULL                      -- コンカレント・プログラムID
  , NULL                      -- プログラム更新日
);
--
COMMIT;
--