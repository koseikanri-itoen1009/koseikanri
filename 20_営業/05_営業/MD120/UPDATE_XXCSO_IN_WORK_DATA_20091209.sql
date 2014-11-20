DECLARE
-----------------------------------------------------------------------------------------
-- XXCSO_IN_WORK_DATA の既存データを以下の通り更新します。
-- infos_interface_flag : 'Y'
-- infos_interface_date : TRUNC(last_update_date)
-----------------------------------------------------------------------------------------
--
  -- ===============================
  -- ローカル定数
  -- ===============================
  cv_yes             CONSTANT VARCHAR2(1) := 'Y';
  -- ===============================
  -- ローカル変数
  -- ===============================
  ln_target_cnt      NUMBER DEFAULT 0;     -- 処理対象件数
  ln_normal_cnt      NUMBER DEFAULT 0;     -- 成功件数
  -- ===============================
  -- ローカルカーソル
  -- ===============================
  CURSOR get_data_cur
  IS
    SELECT  xiwd.seq_no                     seq_no             -- シーケンス番号
           ,TRUNC(xiwd.last_update_date)    last_update_date   -- 最終更新日
    FROM   xxcso.xxcso_in_work_data  xiwd                         -- 作業データテーブル
    ORDER BY xiwd.seq_no;
  -- ===============================
  -- ローカルレコード
  -- ===============================
  l_get_data_rec      get_data_cur%ROWTYPE  DEFAULT NULL;
--
BEGIN
--
    OPEN get_data_cur;
--
    <<get_data_loop>>
    LOOP
      BEGIN
        FETCH get_data_cur INTO l_get_data_rec;
        -- 処理対象件数格納
        ln_target_cnt := get_data_cur%ROWCOUNT;
--
        EXIT WHEN get_data_cur%NOTFOUND
        OR  get_data_cur%ROWCOUNT = 0;
--
        --更新処理
        UPDATE xxcso.xxcso_in_work_data
        SET    infos_interface_flag  =  cv_yes                           -- 情報系連携済フラグ
              ,infos_interface_date  =  l_get_data_rec.last_update_date  -- 情報系連携日
        WHERE  seq_no = l_get_data_rec.seq_no;
--
        --成功件数カウント
        ln_normal_cnt := ln_normal_cnt + 1;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- カーソルクローズ
          CLOSE get_data_cur;
--
          dbms_output.put_line('* * update_error * *');
          dbms_output.put_line('ln_target_cnt : ' || ln_target_cnt );
          dbms_output.put_line('ln_normal_cnt : ' || ln_normal_cnt );
          ROLLBACK;
      END;
    END LOOP get_data_loop;
    -- カーソルクローズ
    CLOSE get_data_cur;
--
  -- メッセージ出力
  dbms_output.put_line('* * update_succeed * *');
  dbms_output.put_line('ln_target_cnt : ' || ln_target_cnt );
  dbms_output.put_line('ln_normal_cnt : ' || ln_normal_cnt );
--
EXCEPTION
  WHEN OTHERS THEN
    -- カーソルクローズ
    CLOSE get_data_cur;
--
    dbms_output.put_line('* * update_error * *');
    dbms_output.put_line('ln_target_cnt : ' || ln_target_cnt );
    dbms_output.put_line('ln_normal_cnt : ' || ln_normal_cnt );
    ROLLBACK;
END;
/
