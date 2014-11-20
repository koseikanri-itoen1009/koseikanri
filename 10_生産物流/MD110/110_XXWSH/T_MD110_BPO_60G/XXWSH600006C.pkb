create or replace PACKAGE BODY xxwsh600006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600006c(body)
 * Description      : 自動配車配送計画作成処理ロック対応
 * MD.050           : 配車配送計画 T_MD050_BPO_600
 * MD.070           : 自動配車配送計画作成処理 T_MD070_BPO_60B
 * Version          : 1.3
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
 *  2008/11/29    1.0  MIYATA.          新規作成
 *  2008/12/20    1.1  M.Hokkanji       本番障害#738
 *  2009/01/16    1.2  M.Nomura         本番障害#900
 *  2009/01/27    1.3  H.Itou           本番障害#1028
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
-- Ver1.1 M.Hokkanji Start
  to_date_expt_m  EXCEPTION;  -- 日付変換エラーm
  to_date_expt_d  EXCEPTION;  -- 日付変換エラーd
  to_date_expt_y  EXCEPTION;  -- 日付変換エラーy
  
  PRAGMA EXCEPTION_INIT(to_date_expt_m, -1843); -- 日付変換エラーm
  PRAGMA EXCEPTION_INIT(to_date_expt_d, -1847); -- 日付変換エラーd
  PRAGMA EXCEPTION_INIT(to_date_expt_y, -1861); -- 日付変換エラーy
  gv_msg_xxwsh_13151    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13151';
                                                      -- メッセージ：必須パラメータ未入力メッセージ
  gv_msg_xxwsh_11113    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11113';
                                                      -- メッセージ：日付逆転エラーメッセージ
  gv_msg_xxwsh_11809    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11809';
                                                      -- メッセージ：入力パラメータ書式エラー
  gv_msg_xxwsh_13501    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13501';
                                                      -- コンカレント発行エラー
  gv_tkn_item           CONSTANT VARCHAR2(100)  :=  'ITEM';       -- トークン：ITEM
  gv_tkn_from           CONSTANT VARCHAR2(100)  :=  'FROM';       -- トークン：FROM
  gv_tkn_to             CONSTANT VARCHAR2(100)  :=  'TO';         -- トークン：TO
  gv_tkn_parm_name      CONSTANT VARCHAR2(100)  :=  'PARM_NAME';  -- トークン：PARM_NAME
-- Ver1.1 M.Hokkanji End
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
-- ##### 20090116 Ver.1.2 本番#900対応 START #####
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
--               (SELECT d.id1, d.id2 FROM gv$lock d 
--               WHERE d.id1=b.id1 AND d.id2=b.id2 AND d.request > 0) 
--               and b.id1 IN (SELECT bb.id1
--                             FROM v$session aa, v$lock bb
--                             WHERE aa.lockwait = bb.kaddr 
--                              and aa.module = 'XXWSH600001C')
--               and b.lmode = 6;
--
    -- gv$sesson、gv$lockを参照するように修正
    CURSOR lock_cur
      IS
        SELECT b.id1, a.sid, a.serial#, b.type , a.inst_id , a.module , a.action
              ,decode(b.lmode 
                     ,1,'null' , 2,'row share', 3,'row exclusive' 
                     ,4,'share', 5,'share row exclusive', 6,'exclusive') LMODE
        FROM gv$session a
           , gv$lock    b
        WHERE a.sid = b.sid
        AND a.module <> 'XXWSH600001C'
        AND (b.id1, b.id2) in (SELECT d.id1
                                     ,d.id2
                               FROM gv$lock d 
                               WHERE d.id1     =b.id1 
                               AND   d.id2     =b.id2 
                               AND   d.request > 0) 
        AND   b.id1 IN (SELECT bb.id1
                      FROM   gv$session aa
                            , gv$lock bb
                      WHERE  aa.lockwait = bb.kaddr 
                      AND    aa.module   = 'XXWSH600001C')
        AND b.lmode = 6;
--
-- ##### 20090116 Ver.1.2 本番#900対応 END   #####
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
-- ##### 20090116 Ver.1.2 本番#900対応 START #####
--    EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
    -- コンカレントが完了するまで処理を継続する
    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090116 Ver.1.2 本番#900対応 END   #####
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
    --ロック解除の開始
    FOR lock_rec IN lock_cur LOOP
--
      -- 削除対象セッションログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG, '【セッション切断】' || 
                                      ' 自動配車： 要求ID[' || TO_CHAR(in_reqid) || '] ' ||
                                      ' 切断対象セッション：' ||
                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
                                      ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
                                      ' action['  || lock_rec.action           || '] ' ||
                                      ' module['  || lock_rec.module           || '] '
                                      );
--
-- ##### 20090116 Ver.1.2 本番#900対応 START #####
--      lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
--      EXECUTE IMMEDIATE lv_strsql;
--      lv_staus := '1';
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
-- ##### 20090116 Ver.1.2 本番#900対応 END   #####
--
    END LOOP;
--
-- ##### 20090116 Ver.1.2 本番#900対応 START #####
    -- 確認後は1秒待機する
    DBMS_LOCK.SLEEP(1);
-- ##### 20090116 Ver.1.2 本番#900対応 END   #####
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
    errbuf        OUT NOCOPY VARCHAR2,            --  エラー・メッセージ
    retcode       OUT NOCOPY VARCHAR2,            --  リターン・コード
    iv_prod_class           IN  VARCHAR2,         --  1.商品区分
    iv_shipping_biz_type    IN  VARCHAR2,         --  2.処理種別
    iv_block_1              IN  VARCHAR2,         --  3.ブロック1
    iv_block_2              IN  VARCHAR2,         --  4.ブロック2
    iv_block_3              IN  VARCHAR2,         --  5.ブロック3
    iv_storage_code         IN  VARCHAR2,         --  6.出庫元
    iv_transaction_type_id  IN  VARCHAR2,         --  7.出庫形態ID
    iv_date_from            IN  VARCHAR2,         --  8.出庫日From
    iv_date_to              IN  VARCHAR2,         --  9.出庫日To
    iv_forwarder_id         IN  VARCHAR2,         -- 10.運送業者ID
-- Ver1.3 H.Itou Add Start 本番障害#1028対応
    iv_instruction_dept     IN  VARCHAR2          -- 11.指示部署
-- Ver1.3 H.Itou Add End
    )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
-- Ver1.1 M.Hokkanji Start
    cv_date_from  CONSTANT VARCHAR2(100)  :=  '出庫日FROM'; -- 出庫日From
    cv_date_to    CONSTANT VARCHAR2(100)  :=  '出庫日TO';   -- 出庫日To
    cv_status_g   CONSTANT VARCHAR2(10)   :=  'G';          -- 警告
    cv_status_e   CONSTANT VARCHAR2(10)   :=  'E';          -- エラー
-- Ver1.1 M.Hokkanji End
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_reqid   NUMBER;           -- 要求ID
    lv_errbuf  VARCHAR2(5000);   -- エラー・メッセージ（ローカル）
    lv_retcode VARCHAR2(1);     -- リターン・コード（ローカル）
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- Ver1.1 M.Hokkanji Start
    ld_date_from  DATE;                                     -- 出庫日From
    ld_date_to    DATE;                                     -- 出庫日To
    ld_loop_date  DATE;                                     -- ループ日付
    lv_dev_status VARCHAR2(10);                             -- ステータス
    lv_gen_retcode VARCHAR2(5000);                          -- 実行コンカレントステータス
-- Ver1.1 M.Hokkanji End
  BEGIN
-- Ver1.1 M.hokkanji Start
    retcode := gv_status_normal;
    -- 出庫日From未入力
    IF (iv_date_from IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                    , gv_msg_xxwsh_13151  -- メッセージ：APP-XXWSH-13151 必須パラメータ未入力エラー
                    , gv_tkn_item         -- トークン：ITEM
                    , cv_date_from        -- パラメータ．出庫日From
                   ),1,5000);
      RAISE global_process_expt;
    ELSE
      BEGIN
        -- 書式チェック
        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_from)
        INTO  ld_date_from
        FROM  DUAL
        ;
      EXCEPTION
        WHEN to_date_expt_m THEN
          -- 月が無効
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                        , gv_msg_xxwsh_11809  -- メッセージ：APP-XXWSH-11809 入力パラメータ書式エラー
                        , gv_tkn_parm_name    -- トークン：PARM_NAME
                        , cv_date_from        -- パラメータ．出庫日FROM
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_d THEN
          -- 日が無効
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                        , gv_msg_xxwsh_11809  -- メッセージ：APP-XXWSH-11809 入力パラメータ書式エラー
                        , gv_tkn_parm_name    -- トークン：PARM_NAME
                        , cv_date_from        -- パラメータ．出庫日FROM
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_y THEN
          -- リテラルと不一致
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                        , gv_msg_xxwsh_11809  -- メッセージ：APP-XXWSH-11809 入力パラメータ書式エラー
                        , gv_tkn_parm_name    -- トークン：PARM_NAME
                        , cv_date_from        -- パラメータ．出庫日FROM
                       ),1,5000);
          RAISE global_process_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
    -- 出庫日To未入力
    IF (iv_date_to IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                    , gv_msg_xxwsh_13151  -- メッセージ：APP-XXWSH-13151 必須パラメータ未入力エラー
                    , gv_tkn_item         -- トークン：ITEM
                    , cv_date_to          -- パラメータ．出庫日To
                   ),1,5000);
      RAISE global_process_expt;
    ELSE
      BEGIN
        -- 書式チェック
        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_to)
        INTO  ld_date_to
        FROM  DUAL
        ;
      EXCEPTION
        WHEN to_date_expt_m THEN
          -- 月が無効
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                        , gv_msg_xxwsh_11809  -- メッセージ：APP-XXWSH-11809 入力パラメータ書式エラー
                        , gv_tkn_parm_name    -- トークン：PARM_NAME
                        , cv_date_to        -- パラメータ．出庫日TO
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_d THEN
          -- 日が無効
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                        , gv_msg_xxwsh_11809  -- メッセージ：APP-XXWSH-11809 入力パラメータ書式エラー
                        , gv_tkn_parm_name    -- トークン：PARM_NAME
                        , cv_date_to          -- パラメータ．出庫日TO
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_y THEN
          -- リテラルと不一致
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                        , gv_msg_xxwsh_11809  -- メッセージ：APP-XXWSH-11809 入力パラメータ書式エラー
                        , gv_tkn_parm_name    -- トークン：PARM_NAME
                        , cv_date_to          -- パラメータ．出庫日TO
                       ),1,5000);
          RAISE global_process_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
    END IF;
    -- 日付逆転
    IF (ld_date_from > ld_date_to) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                    , gv_msg_xxwsh_11113  -- メッセージ：APP-XXWSH-11113 日付逆転エラー
                   ),1,5000);
      RAISE global_process_expt;
    END IF;
    ld_loop_date := ld_date_from;
    <<conc_loop>>
    LOOP
-- Ver1.1 M.hokkanji End
      -- ==================
      -- 子コンカレントの起動
      -- ==================
      ln_reqid := fnd_request.submit_request(
        Application => 'XXWSH',
        Program     => 'XXWSH600001C',
        Description => NULL,
        Start_Time  => SYSDATE,
        Sub_Request => FALSE,
        Argument1   => iv_prod_class,
        Argument2   => iv_shipping_biz_type,
        Argument3   => iv_block_1,
        Argument4   => iv_block_2,
        Argument5   => iv_block_3,
        Argument6   => iv_storage_code,
        Argument7   => iv_transaction_type_id,
-- Ver1.1 M.hokkanji Start
        Argument8   => TO_CHAR(ld_loop_date,'YYYY/MM/DD'),
        Argument9   => TO_CHAR(ld_loop_date,'YYYY/MM/DD'),
--        Argument8   => iv_date_from,
--        Argument9   => iv_date_to,
-- Ver1.1 M.hokkanji End
        Argument10  => iv_forwarder_id,
-- Ver1.3 H.Itou Add Start 本番障害#1028対応
        Argument11  => iv_instruction_dept
-- Ver1.3 H.Itou Add End
        );
      if ln_reqid > 0 then
        commit;
      else
        rollback;
-- Ver1.1 M.Hokkanji Start
-- 発行に失敗した場合はエラーにしメッセージを出力するように修正
--      retcode := '1';
--        return;
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_cnst_msg_kbn     -- モジュール名略称：XXWSH 出荷・引当/配車
                      , gv_msg_xxwsh_13501  -- メッセージ：APP-XXWSH-13501 日付逆転エラー
                        , gv_tkn_parm_name    -- トークン：PARM_NAME
                        , TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                     ),1,5000);
        RAISE global_process_expt;
-- Ver1.1 M.Hokkanji End
      end if;
      -- ==================
      -- ロックの解除の呼び出し
      -- ==================
      release_lock(
            ln_reqid,
            lv_errbuf,
            lv_retcode,
            lv_errmsg);
-- Ver1.1 M.Hokkanji Start
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
                                       || '、出荷予定日：' || TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                                       || '、ステータス：' || '警告終了');
        lv_gen_retcode := gv_status_warn;
      ELSIF (lv_dev_status = cv_status_e) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'要求ID:' || TO_CHAR(ln_reqid)
                                       || '、出荷予定日：' || TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                                       || '、ステータス：' || 'エラー終了');
        lv_gen_retcode := gv_status_error;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'要求ID:' || TO_CHAR(ln_reqid)
                                       || '、出荷予定日：' || TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                                       || '、ステータス：' || '正常終了');
        lv_gen_retcode := gv_status_normal;
      END IF;
      -- エラーで現在のステータスより取得したステータスが大きい場合は取得ステータスをセット
      IF  (lv_dev_status = cv_status_e)
      AND (lv_gen_retcode > retcode) THEN
        retcode := lv_gen_retcode;
      END IF;
      -- LOOP終了するかの判断
      EXIT WHEN (ld_loop_date >= ld_date_to );
      -- ループが終了しない場合は日付を一日ずらす
      ld_loop_date := ld_loop_date + 1;
    END LOOP conc_loop;
-- Ver1.1 M.Hokkanji End
      -- ======================
      -- エラー・メッセージ出力
      -- ======================
      -- ==================================
      -- リターン・コードのセット、終了処理
      -- ==================================
-- Ver1.1 M.Hokkanji Start
--      retcode := lv_retcode;
--      errbuf := lv_errmsg;
-- Ver1.1 M.Hokkanji End
  EXCEPTION
-- Ver1.1 M.Hokkanji Start
    -- *** 処理共通例外ハンドラ ***
    WHEN global_process_expt THEN
      errbuf  := lv_errmsg;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- Ver1.1 M.Hokkanji End
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
-- Ver1.1 M.Hokkanji Start
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
-- Ver1.1 M.Hokkanji End
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
-- Ver1.1 M.Hokkanji Start
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
-- Ver1.1 M.Hokkanji End
  END main;
--
END xxwsh600006c;
/
