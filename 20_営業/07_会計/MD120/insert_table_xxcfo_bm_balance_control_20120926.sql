DECLARE
  --==============================================================
  -- 自販機販売手数料管理テーブル初期データ投入
  --==============================================================
  lt_bm_balance_id            xxcok_backmargin_balance.bm_balance_id%TYPE;
  --
BEGIN
  BEGIN
    SELECT    MAX(xbb.bm_balance_id)    bm_balance_id
    INTO      lt_bm_balance_id
    FROM      xxcok_backmargin_balance  xbb
    ;
  END;
  -- 販売実績管理テーブルの登録（移行用初期データ）
  INSERT INTO xxcfo_bm_balance_control(
      business_date             -- 業務日付
    , bm_balance_id             -- 販手残高ID
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
    , lt_bm_balance_id          -- 販手残高ID
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
END ;
/
--
