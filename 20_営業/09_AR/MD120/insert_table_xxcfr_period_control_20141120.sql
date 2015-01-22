-- 処理対象期間管理テーブルの登録（移行用初期データ）
INSERT INTO xxcfr.xxcfr_period_control(
    process_name              -- 機能名
  , effective_period_num      -- 有効会計期間番号
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
    'XXCFR001A03C'            -- 機能名
  , 20140011                  -- 有効会計期間番号(2015-01を処理済)
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