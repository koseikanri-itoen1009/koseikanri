CREATE OR REPLACE PACKAGE BODY xxwsh920009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh920009c(body)
 * Description      : 引当解除処理ロック対応
 * MD.050           : 
 * MD.070           : 
 * Version          : 1.4
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  release_lock             P         ロック解除関数
 *  main                     P         メイン
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01   1.0   T.MIYATA         初回作成
 *  2009/01/19   1.1   M.Nomura         本番#1038対応
 *  2009/01/27   1.2   H.Itou           本番#1028対応
 *  2009/02/18   1.3   M.Nomura         本番#1176対応
 *  2009/02/19   1.4   M.Nomura         本番#1176対応（追加修正）
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
  gv_pkg_name           CONSTANT VARCHAR2(100)  :=  'xxwsh600006c'; -- パッケージ名
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
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
--
-- ##### 20090119 Ver.1.1 本番#1038対応 START #####
    ln_reqid        NUMBER;           -- 要求ID
    ln_ret          BOOLEAN;
    lv_phase2       VARCHAR2(1000);
    lv_status2      VARCHAR2(1000);
    lv_dev_phase2   VARCHAR2(1000);
    lv_dev_status2  VARCHAR2(1000);
    lv_message2     VARCHAR2(1000);
-- ##### 20090119 Ver.1.1 本番#1038対応 END   #####
--
-- ##### 20090119 Ver.1.1 本番#1038対応 START #####
    -- *** ローカル・カーソル session解除対象取得***
--    CURSOR lock_cur
--      IS
--        SELECT b.id1, a.sid, a.serial#, b.type  
--        ,decode(b.lmode 
--               ,1,'null', 2,'row share', 3,'row exclusive' 
--               ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
--               FROM v$session a, v$lock b
--               WHERE a.sid = b.sid
--               AND(b.id1, b.id2) in 
--               (SELECT d.id1, d.id2 FROM v$lock d 
--               WHERE d.id1=b.id1 AND d.id2=b.id2 AND d.request > 0) 
--               and b.id1 IN (SELECT bb.id1
--                             FROM v$session aa, v$lock bb
--                             WHERE aa.lockwait = bb.kaddr 
--                              and aa.module = 'XXWSH920002C')
--               and b.lmode = 6;
--
-- ##### 20090217 Ver.1.3 本番#1176対応 START #####
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
--        AND a.module <> 'XXWSH920002C'
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
--                      AND    aa.module   = 'XXWSH920002C')
--        AND b.lmode = 6;
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
-- ##### 20090219 Ver.1.4 本番#1176対応（追加修正） START #####
             , lok.lmode          lmode
             , lok.request        request
             , lok.ctime          ctime
-- ##### 20090219 Ver.1.4 本番#1176対応（追加修正） END   #####
        FROM   gv$lock    lok
             , gv$session lok_sess
             , gv$lock    req
             , gv$session req_sess
        WHERE lok.inst_id = lok_sess.inst_id
          AND lok.sid     = lok_sess.sid
          AND lok.lmode   = 6
-- ##### 20090219 Ver.1.4 本番#1176対応（追加修正） START #####
          AND (lok.id1, lok.id2) IN (SELECT lok_not.id1, lok_not.id2
                                     FROM   gv$lock   lok_not
                                     WHERE  lok_not.id1 =lok.id1 
                                     AND    lok_not.id2 =lok.id2 
                                     AND    lok_not.request > 0) 
-- ##### 20090219 Ver.1.4 本番#1176対応（追加修正） END   #####
          AND req.inst_id = req_sess.inst_id
          AND req.sid     = req_sess.sid
          AND (   req.inst_id <> lok.inst_id
               OR req.sid     <> lok.sid)
          AND req.id1 = lok.id1
          AND req.id2 = lok.id2
          AND req_sess.module = 'XXWSH920002C'; 
--
-- ##### 20090217 Ver.1.3 本番#1176対応 END   #####
--
-- ##### 20090119 Ver.1.1 本番#1038対応 END   #####
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
-- ##### 20090119 Ver.1.1 本番#1038対応 START #####
--    EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
-- ##### 20090119 Ver.1.1 本番#1038対応 END   #####
    --子コンカレント完了を取得
    BEGIN
      select decode(fcr.phase_code,'C','Y','I','Y','N')
      into lv_phase
      from   fnd_concurrent_requests fcr 
      where fcr.request_id = in_reqid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          lv_phase := 'Y';
        NULL;
    END;
-- ##### 20090119 Ver.1.1 本番#1038対応 START #####
    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090119 Ver.1.1 本番#1038対応 END   #####
    --ロック解除の開始
    FOR lock_rec IN lock_cur LOOP
--
-- ##### 20090119 Ver.1.1 本番#1038対応 START #####
--      lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
--      EXECUTE IMMEDIATE lv_strsql;
--      lv_staus := '1';
--
-- ##### 20090219 Ver.1.4 本番#1176対応（追加修正） START #####
      -- 削除対象セッションログ出力
--      FND_FILE.PUT_LINE(FND_FILE.LOG, '【セッション切断】' || 
--                                      ' 引当解除： 要求ID[' || TO_CHAR(in_reqid) || '] ' ||
--                                      ' 切断対象セッション：' ||
--                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
--                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
--                                      ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
--                                      ' action['  || lock_rec.action           || '] ' ||
--                                      ' module['  || lock_rec.module           || '] '
--                                      );
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
-- ##### 20090219 Ver.1.4 本番#1176対応（追加修正） END   #####
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
                                                0.05,
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
        lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                     ' 要求ID['  || TO_CHAR(ln_reqid) || ']' ||
                     ' phase['   || lv_dev_phase2     || ']' ||
                     ' status['  || lv_dev_status2    || ']' ||
                     ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      -- ステータスがNORMAL以外での終了
      ELSIF (lv_dev_status2 <> 'NORMAL') THEN
        -- エラーは無視して、ログのみ出力
        lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                     ' 要求ID['  || TO_CHAR(ln_reqid) || ']' ||
                     ' phase['   || lv_dev_phase2     || ']' ||
                     ' status['  || lv_dev_status2    || ']' ||
                     ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      END IF;
--
-- ##### 20090119 Ver.1.1 本番#1038対応 END   #####
    END LOOP;
--
-- ##### 20090119 Ver.1.1 本番#1038対応 START #####
    -- 確認後は1秒待機する
    DBMS_LOCK.SLEEP(0.05);
-- ##### 20090119 Ver.1.1 本番#1038対応 END   #####
--
  END LOOP;
--
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
     errbuf        OUT NOCOPY VARCHAR2       --  エラー・メッセージ
    ,retcode       OUT NOCOPY VARCHAR2       --  リターン・コード
    ,iv_item_class         IN  VARCHAR2      -- 1.商品区分
    ,iv_action_type        IN  VARCHAR2      -- 2.処理種別
    ,iv_block1             IN  VARCHAR2      -- 3.ブロック１
    ,iv_block2             IN  VARCHAR2      -- 4.ブロック２
    ,iv_block3             IN  VARCHAR2      -- 5.ブロック３
    ,iv_deliver_from_id    IN  VARCHAR2      -- 6.出庫元
    ,iv_deliver_type       IN  VARCHAR2      -- 7.出庫形態
    ,iv_deliver_date_from  IN  VARCHAR2      -- 8.出庫日From
    ,iv_deliver_date_to    IN  VARCHAR2      -- 9.出庫日To
-- ##### 20090127 Ver.1.2 本番#1038対応 START #####
    ,iv_instruction_dept   IN  VARCHAR2      -- 10.指示部署
-- ##### 20090127 Ver.1.2 本番#1038対応 END   #####
    )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_reqid   NUMBER;           -- 要求ID
    lv_errbuf  VARCHAR2(5000);   -- エラー・メッセージ（ローカル）
    lv_retcode VARCHAR2(1);     -- リターン・コード（ローカル）
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
  BEGIN
    -- ==================
    -- 子コンカレントの起動
    -- ==================
    ln_reqid := fnd_request.submit_request(
      Application => 'XXWSH',
      Program     => 'XXWSH920002C',
      Description => NULL,
      Start_Time  => SYSDATE,
      Sub_Request => FALSE,
      Argument1   => iv_item_class,
      Argument2   => iv_action_type,
      Argument3   => iv_block1,
      Argument4   => iv_block2,
      Argument5   => iv_block3,
      Argument6   => iv_deliver_from_id,
      Argument7   => iv_deliver_type,
      Argument8   => iv_deliver_date_from,
      Argument9   => iv_deliver_date_to,
-- ##### 20090127 Ver.1.2 本番#1038対応 START #####
      Argument10  => iv_instruction_dept
-- ##### 20090127 Ver.1.2 本番#1038対応 END   #####
      );
    if ln_reqid > 0 then
      commit;
    else
      rollback;
      retcode := '1';
      return;
    end if;
    -- ==================
    -- ロックの解除の呼び出し
    -- ==================
    release_lock(
          ln_reqid,
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    retcode := lv_retcode;
    errbuf := lv_errmsg;
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
END xxwsh920009c;
/
