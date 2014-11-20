-- 修正管理テーブルの登録（移行用初期データ）
INSERT INTO xxcfo_ar_adj_control(
   business_date          -- 業務日付
  ,adjustment_id          -- 修正ID
  ,process_flag           -- 処理済フラグ
  ,created_by             -- 作成者
  ,creation_date          -- 作成日
  ,last_updated_by        -- 最終更新者
  ,last_update_date       -- 最終更新日
  ,last_update_login      -- 最終更新ログイン
  ,request_id             -- 要求ID
  ,program_application_id -- コンカレント・プログラム・アプリケーションID
  ,program_id             -- コンカレント・プログラムID
  ,program_update_date    -- プログラム更新日
) VALUES (
   SYSDATE
  ,1
  ,'Y'
  ,1
  ,SYSDATE
  ,1
  ,SYSDATE
  ,1
  ,1
  ,1
  ,1
  ,SYSDATE
);
--
COMMIT;
--
