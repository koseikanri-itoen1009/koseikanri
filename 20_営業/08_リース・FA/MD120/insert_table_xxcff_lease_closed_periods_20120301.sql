--リース月次締め期間の初期データ登録
DECLARE
  -- 変数
  lv_period_name               VARCHAR2(7);  -- 会計期間
  --
  TYPE l_set_of_books_id_ttype IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  l_set_of_books_id_tab        l_set_of_books_id_ttype;
BEGIN
  -- 直近のクローズされたFA減価償却期間の取得
  SELECT MAX(fdp.period_name)
  INTO   lv_period_name
  FROM   apps.fa_deprn_periods fdp  -- 減価償却期間
  WHERE  fdp.book_type_code = 'FINリース台帳'
  AND    fdp.deprn_run      = 'Y'
  ;
  -- プロファイルオプション値の取得（サイトレベルと職責レベルの全ての値）
  SELECT DISTINCT
         fpov.profile_option_value      profile_option_value
  BULK COLLECT INTO
         l_set_of_books_id_tab
  FROM   apps.fnd_profile_options       fpo
        ,apps.fnd_profile_options_tl    fpot
        ,apps.fnd_profile_option_values fpov
        ,apps.fnd_application_tl        fat
  WHERE  fpo.profile_option_id   = fpov.profile_option_id
  AND    fpo.application_id      = fpov.application_id
  AND    fpo.profile_option_name = fpot.profile_option_name
  AND    fpo.application_id      = fat.application_id
  AND    fat.language            = 'JA'
  AND    fpot.language           = 'JA'
  AND    fpov.level_id           IN ( 10001, 10003 )     -- レベル
  AND    fpot.user_profile_option_name = 'GL会計帳簿ID'  -- プロファイル名称(論理名)
  ;
  --
  <<insert_loop>>
  FOR i IN 1 .. l_set_of_books_id_tab.COUNT LOOP
    -- リース月次締め期間の登録
    INSERT INTO apps.xxcff_lease_closed_periods(
       set_of_books_id
      ,period_name
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    ) VALUES (
       l_set_of_books_id_tab(i)  -- リース職責に紐付く会計帳簿ID
      ,lv_period_name            -- 会計期間
      ,-1
      ,SYSDATE
      ,-1
      ,SYSDATE
      ,NULL
      ,NULL
      ,NULL
      ,NULL
      ,NULL
    )
    ;
  END LOOP insert_loop;
  --
  COMMIT;
END;
