-- 減価償却管理テーブルの登録（移行用初期データ）
INSERT INTO xxcfo_deprn_control(
    set_of_books_id           -- 会計帳簿ID
  , period_name               -- 会計期間
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
    2001                      -- 会計帳簿ID
  , '2012-12'                 -- 会計期間
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