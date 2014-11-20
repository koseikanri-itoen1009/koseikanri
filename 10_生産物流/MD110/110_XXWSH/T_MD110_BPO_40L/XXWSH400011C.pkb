create or replace PACKAGE BODY xxwsh400011c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400011c(spec)
 * Description      : 出荷依頼締め起動処理
 * MD.050           : T_MD050_BPO_401_出荷依頼
 * MD.070           : 出荷依頼締め処理 T_MD070_BPO_40H
 * Version          : 1.1
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  release_lock             P         ロック解除関数
 *  main                     P         メイン
 * ------------- ----------- --------- --------------------------------------------------
 *  Date         Ver.  Editor          Description
 * ------------- ----- --------------- --------------------------------------------------
 *  2009/01/16   1.0   T.Ohashi        新規作成
 *  2009/02/23   1.1   M.Nomura        本番#1176対応（追加修正）
 *
 *****************************************************************************************/
--

--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  --*** 処理部共通例外ワーニング ***
  global_process_warn       EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100)  :=  'xxwsh400011c'; -- パッケージ名
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
  to_date_expt_m  EXCEPTION;  -- 日付変換エラーm
  to_date_expt_d  EXCEPTION;  -- 日付変換エラーd
  to_date_expt_y  EXCEPTION;  -- 日付変換エラーy
  
  PRAGMA EXCEPTION_INIT(to_date_expt_m, -1843); -- 日付変換エラーm
  PRAGMA EXCEPTION_INIT(to_date_expt_d, -1847); -- 日付変換エラーd
  PRAGMA EXCEPTION_INIT(to_date_expt_y, -1861); -- 日付変換エラーy
  gv_msg_xxwsh_13501    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13501';
                                                      -- コンカレント発行エラー
  gv_tkn_parm_name      CONSTANT VARCHAR2(100)  :=  'PARM_NAME';  -- トークン：PARM_NAME
--
   /**********************************************************************************
   * Procedure Name   : release_lock
   * Description      : ロック解除
   ***********************************************************************************/
  PROCEDURE release_lock(
    in_reqid              IN  NUMBER,                     -- 要求ID
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'release_lock';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_strsql VARCHAR2(1000);
    lv_phase   VARCHAR2(5);
    lv_staus   VARCHAR2(1);

-- ##### 20090116 Ver.1.2 本番#900対応 START #####
    ln_reqid        NUMBER;           -- 要求ID
    ln_ret          BOOLEAN;
    lv_phase2       VARCHAR2(1000);
    lv_status2      VARCHAR2(1000);
    lv_dev_phase2   VARCHAR2(1000);
    lv_dev_status2  VARCHAR2(1000);
    lv_message2     VARCHAR2(1000);
-- ##### 20090116 Ver.1.2 本番#900対応 END   #####
--
    -- *** ローカル・カーソル session解除対象取得***
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） START #####
    -- gv$sesson、gv$lockを参照するように修正
--    CURSOR lock_cur
--      IS
--        SELECT b.id1, a.sid, a.serial#, b.type , a.inst_id , a.module , a.action
--              ,decode(b.lmode 
--                     ,1,'null' , 2,'row share', 3,'row exclusive' 
--                     ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
--        FROM gv$session a
--           , gv$lock    b
--        WHERE a.sid = b.sid
--        AND a.module <> 'XXWSH400007C'
--        AND (b.id1, b.id2) in (SELECT d.id1
--                                     ,d.id2
--                               FROM gv$lock d 
--                               WHERE d.id1     =b.id1 
--                               AND   d.id2     =b.id2 
--                               AND   d.request > 0) 
--        AND   b.id1 IN (SELECT bb.id1
--                      FROM   gv$session aa
--                            , gv$lock bb
--                      WHERE  aa.lockwait = bb.kaddr 
--                      AND    aa.module   = 'XXWSH400007C')
--        AND b.lmode = 6;
--
    -- RAC構成対応SQL
    CURSOR lock_cur
      IS
        SELECT lok.id1            id1
             , lok_sess.inst_id   inst_id
             , lok_sess.sid       sid
             , lok_sess.serial#   serial#
             , lok.type           type
             , lok_sess.module    module
             , lok_sess.action    action
             , lok.lmode          lmode
             , lok.request        request
             , lok.ctime          ctime
        FROM   gv$lock    lok
             , gv$session lok_sess
             , gv$lock    req
             , gv$session req_sess
        WHERE lok.inst_id = lok_sess.inst_id
          AND lok.sid     = lok_sess.sid
          AND lok.lmode   = 6
          AND (lok.id1, lok.id2) IN (SELECT lok_not.id1, lok_not.id2
                                     FROM   gv$lock   lok_not
                                     WHERE  lok_not.id1 =lok.id1 
                                     AND    lok_not.id2 =lok.id2 
                                     AND    lok_not.request > 0) 
          AND req.inst_id = req_sess.inst_id
          AND req.sid     = req_sess.sid
          AND (   req.inst_id <> lok.inst_id
               OR req.sid     <> lok.sid)
          AND req.id1 = lok.id1
          AND req.id2 = lok.id2
          AND req_sess.module = 'XXWSH400007C';
--
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） END   #####
--
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
  LOOP
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） START #####
    -- コンカレントが完了するまで処理を継続する
--    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） END   #####
    --子コンカレント完了を取得
    BEGIN
      SELECT DECODE(fcr.phase_code,'C','Y','I','Y','N')
      INTO lv_phase
      FROM   fnd_concurrent_requests fcr 
      WHERE fcr.request_id = in_reqid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          lv_phase := 'Y';
        NULL;
    END;
--
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） START #####
    -- コンカレントが完了するまで処理を継続する
    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） END   #####
--
    --ロック解除の開始
    FOR lock_rec IN lock_cur LOOP
--
      -- 削除対象セッションログ出力
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） START #####
-- ログ内容変更
--      FND_FILE.PUT_LINE(FND_FILE.LOG, '【セッション切断】' || 
--                                      ' 出荷依頼締め処理： 要求ID[' || TO_CHAR(in_reqid) || '] ' ||
--                                      ' 切断対象セッション：' ||
--                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
--                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
--                                      ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
--                                      ' action['  || lock_rec.action           || '] ' ||
--                                      ' module['  || lock_rec.module           || '] '
--                                      );
--
      FND_FILE.PUT_LINE(FND_FILE.LOG, '【セッション切断】' || ' 要求ID[' || TO_CHAR(in_reqid) || '] ' ||
                                      ' 切断対象セッション：' ||
                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
                                      ' serial#[' || TO_CHAR(lock_rec.serial#) || '] ' ||
                                      ' action['  || lock_rec.action           || '] ' ||
                                      ' module['  || lock_rec.module           || '] ' ||
                                      ' lmode['   || TO_CHAR(lock_rec.lmode)   || '] ' ||
                                      ' request[' || TO_CHAR(lock_rec.request) || '] ' ||
                                      ' ctime['   || TO_CHAR(lock_rec.ctime)   || '] '
                                      );
--
-- ##### 20090223 Ver.1.1 本番#1176対応（追加修正） END   #####
--
      -- =====================================
      -- セッション切断コンカレントを起動する
      -- =====================================
      ln_reqid := fnd_request.submit_request(
        Application => 'XXWSH',
        Program     => 'XXWSH000001C',
        Description => NULL,
        Start_Time  => SYSDATE,
        Sub_Request => FALSE,
        Argument1   => lock_rec.inst_id,
        Argument2   => lock_rec.sid    ,
        Argument3   => lock_rec.serial#
        );
      IF (ln_reqid > 0) THEN
        COMMIT;
      ELSE
        ROLLBACK;
        -- 発行に失敗した場合はエラーにしメッセージを出力するように修正
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB('XXWSH000001H 起動エラー ' ||
                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || ']' ||
                      ' sid['     || TO_CHAR(lock_rec.sid)     || ']' ||
                      ' serial['  || TO_CHAR(lock_rec.serial#) || ']' || '<' || FND_MESSAGE.GET || '>'
                      ,1,5000);
        RAISE global_process_expt;
      END IF;
--
      -- ==============================================
      -- 起動したセッション切断コンカレントの終了を待つ
      -- ==============================================
      ln_ret := FND_CONCURRENT.WAIT_FOR_REQUEST(ln_reqid ,
                                                1,
                                                3600,
                                                lv_phase2,
                                                lv_status2,
                                                lv_dev_phase2,
                                                lv_dev_status2,
                                                lv_message2);
      -- ステータス確認
      IF (ln_ret = FALSE) THEN
        -- エラーは無視して、ログのみ出力
        lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                     ' 要求ID['  || TO_CHAR(ln_reqid) || ']' ||
                     ' phase['   || lv_dev_phase2     || ']' ||
                     ' status['  || lv_dev_status2    || ']' ||
                     ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      -- COMPLETE以外での終了
      ELSIF (lv_dev_phase2 <> 'COMPLETE') THEN
        -- エラーは無視して、ログのみ出力
        lv_errmsg := SUBSTRB('WAIT_FOR_REQUEST ERROR return reqid ' || TO_CHAR(ln_reqid) || 
                     ' phase['   || lv_dev_phase2  || ']' ||
                     ' status['  || lv_dev_status2 || ']' ||
                     ' message[' || lv_message2    || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      -- ステータスがNORMAL以外での終了
      ELSIF (lv_dev_status2 <> 'NORMAL') THEN
        -- エラーは無視して、ログのみ出力
        lv_errmsg := SUBSTRB('WAIT_FOR_REQUEST ERROR return reqid ' || TO_CHAR(ln_reqid) || 
                     ' phase['   || lv_dev_phase2  || ']' ||
                     ' status['  || lv_dev_status2 || ']' ||
                     ' message[' || lv_message2    || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      END IF;
--
    END LOOP;
--
    -- 確認後は1秒待機する
    DBMS_LOCK.SLEEP(1);
--
  END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
----
  END release_lock;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2,                   --  エラー・メッセージ
    retcode       OUT NOCOPY VARCHAR2,                   --  リターン・コード
    iv_order_type_id         IN  VARCHAR2,               --  1.出庫形態ID
    iv_deliver_from          IN  VARCHAR2,               --  2.出荷元
    iv_sales_base            IN  VARCHAR2,               --  3.拠点
    iv_sales_base_category   IN  VARCHAR2,               --  4.拠点カテゴリ
    iv_lead_time_day         IN  VARCHAR2,               --  5.生産物流LT
    iv_schedule_ship_date    IN  VARCHAR2,               --  6.出庫日
    iv_base_record_class     IN  VARCHAR2,               --  7.基準レコード区分
    iv_request_no            IN  VARCHAR2,               --  8.依頼No
    iv_tighten_class         IN  VARCHAR2,               --  9.締め処理区分
    iv_prod_class            IN  VARCHAR2,               -- 10.商品区分
    iv_tightening_program_id IN  VARCHAR2,               -- 11.締めコンカレントID
    iv_instruction_dept      IN  VARCHAR2                -- 12.部署
    )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    cv_status_g   CONSTANT VARCHAR2(10)   :=  'G';          -- 警告
    cv_status_e   CONSTANT VARCHAR2(10)   :=  'E';          -- エラー
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_reqid   NUMBER;           -- 要求ID
    lv_errbuf  VARCHAR2(5000);   -- エラー・メッセージ（ローカル）
    lv_retcode VARCHAR2(1);     -- リターン・コード（ローカル）
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_dev_status VARCHAR2(10);                             -- ステータス
    lv_gen_retcode VARCHAR2(5000);                          -- 実行コンカレントステータス
  BEGIN
    retcode := gv_status_normal;
    -- ==================
    -- 子コンカレントの起動
    -- ==================
    ln_reqid := fnd_request.submit_request(
      Application => 'XXWSH',
      Program     => 'XXWSH400007C',
      Description => NULL,
      Start_Time  => SYSDATE,
      Sub_Request => FALSE,
      Argument1   => iv_order_type_id,
      Argument2   => iv_deliver_from,
      Argument3   => iv_sales_base,
      Argument4   => iv_sales_base_category,
      Argument5   => iv_lead_time_day,
      Argument6   => iv_schedule_ship_date,
      Argument7   => iv_base_record_class,
      Argument8   => iv_request_no,
      Argument9   => iv_tighten_class,
      Argument10  => iv_prod_class,
      Argument11  => iv_tightening_program_id,
      Argument12  => iv_instruction_dept
      );
    if ln_reqid > 0 then
      commit;
    else
      rollback;
-- 発行に失敗した場合はエラーにしメッセージを出力するように修正
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                    , gv_msg_xxwsh_13501  -- メッセージ：APP-XXWSH-13501 コンカレント実行エラー
                    , gv_tkn_parm_name    -- トークン：PARM_NAME
                    , iv_schedule_ship_date
                   ),1,5000);
      RAISE global_process_expt;
    end if;
    -- ==================
    -- ロックの解除の呼び出し
    -- ==================
    release_lock(
          ln_reqid,
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- 指定した日付の処理ステータスを取得
    BEGIN
      SELECT status_code
        INTO lv_dev_status
        FROM FND_CONC_REQ_SUMMARY_V
       WHERE request_id = ln_reqid;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- 日付ごとの処理内容を表示
    lv_gen_retcode := NULL;
    -- ステータスが警告の場合
    IF (lv_dev_status = cv_status_g) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'要求ID:' || TO_CHAR(ln_reqid)
                                     || '、出庫日：' || iv_schedule_ship_date
                                     || '、ステータス：' || '警告終了');
      lv_gen_retcode := gv_status_warn;
    ELSIF (lv_dev_status = cv_status_e) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'要求ID:' || TO_CHAR(ln_reqid)
                                     || '、出庫日：' || iv_schedule_ship_date
                                     || '、ステータス：' || 'エラー終了');
      lv_gen_retcode := gv_status_error;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'要求ID:' || TO_CHAR(ln_reqid)
                                     || '、出庫日：' || iv_schedule_ship_date
                                     || '、ステータス：' || '正常終了');
      lv_gen_retcode := gv_status_normal;
    END IF;
    -- エラーで現在のステータスより取得したステータスが大きい場合は取得ステータスをセット
    IF  (lv_dev_status = cv_status_e)
    AND (lv_gen_retcode > retcode) THEN
      retcode := lv_gen_retcode;
    END IF;
      -- ======================
      -- エラー・メッセージ出力
      -- ======================
      -- ==================================
      -- リターン・コードのセット、終了処理
      -- ==================================
  EXCEPTION
    -- *** 処理共通例外ハンドラ ***
    WHEN global_process_expt THEN
      errbuf  := lv_errmsg;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
  END main;
--
END xxwsh400011c;
/
