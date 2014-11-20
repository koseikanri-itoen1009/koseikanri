CREATE OR REPLACE PACKAGE BODY xxwsh920009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh920009c(body)
 * Description      : ���������������b�N�Ή�
 * MD.050           : 
 * MD.070           : 
 * Version          : 1.4
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  release_lock             P         ���b�N�����֐�
 *  main                     P         ���C��
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01   1.0   T.MIYATA         ����쐬
 *  2009/01/19   1.1   M.Nomura         �{��#1038�Ή�
 *  2009/01/27   1.2   H.Itou           �{��#1028�Ή�
 *  2009/02/18   1.3   M.Nomura         �{��#1176�Ή�
 *  2009/02/19   1.4   M.Nomura         �{��#1176�Ή��i�ǉ��C���j
 *
 *****************************************************************************************/
--

--#######################  �Œ�O���[�o���萔�錾�� START   #######################
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
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  --*** ���������ʗ�O���[�j���O ***
  global_process_warn       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100)  :=  'xxwsh600006c'; -- �p�b�P�[�W��
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
--
   /**********************************************************************************
   * Procedure Name   : release_lock
   * Description      : ���b�N����
   ***********************************************************************************/
  PROCEDURE release_lock(
    in_reqid              IN  NUMBER,                     -- �v��ID
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'release_lock';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_strsql VARCHAR2(1000);
    lv_phase   VARCHAR2(5);
    lv_staus   VARCHAR2(1);
--
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� START #####
    ln_reqid        NUMBER;           -- �v��ID
    ln_ret          BOOLEAN;
    lv_phase2       VARCHAR2(1000);
    lv_status2      VARCHAR2(1000);
    lv_dev_phase2   VARCHAR2(1000);
    lv_dev_status2  VARCHAR2(1000);
    lv_message2     VARCHAR2(1000);
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� END   #####
--
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� START #####
    -- *** ���[�J���E�J�[�\�� session�����Ώێ擾***
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
-- ##### 20090217 Ver.1.3 �{��#1176�Ή� START #####
    -- gv$sesson�Agv$lock���Q�Ƃ���悤�ɏC��
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
    -- RAC�\���Ή�SQL
    CURSOR lock_cur
      IS
        SELECT lok.id1            id1
             , lok_sess.inst_id   inst_id
             , lok_sess.sid       sid
             , lok_sess.serial#   serial#
             , lok.type           type
             , lok_sess.module    module
             , lok_sess.action    action
-- ##### 20090219 Ver.1.4 �{��#1176�Ή��i�ǉ��C���j START #####
             , lok.lmode          lmode
             , lok.request        request
             , lok.ctime          ctime
-- ##### 20090219 Ver.1.4 �{��#1176�Ή��i�ǉ��C���j END   #####
        FROM   gv$lock    lok
             , gv$session lok_sess
             , gv$lock    req
             , gv$session req_sess
        WHERE lok.inst_id = lok_sess.inst_id
          AND lok.sid     = lok_sess.sid
          AND lok.lmode   = 6
-- ##### 20090219 Ver.1.4 �{��#1176�Ή��i�ǉ��C���j START #####
          AND (lok.id1, lok.id2) IN (SELECT lok_not.id1, lok_not.id2
                                     FROM   gv$lock   lok_not
                                     WHERE  lok_not.id1 =lok.id1 
                                     AND    lok_not.id2 =lok.id2 
                                     AND    lok_not.request > 0) 
-- ##### 20090219 Ver.1.4 �{��#1176�Ή��i�ǉ��C���j END   #####
          AND req.inst_id = req_sess.inst_id
          AND req.sid     = req_sess.sid
          AND (   req.inst_id <> lok.inst_id
               OR req.sid     <> lok.sid)
          AND req.id1 = lok.id1
          AND req.id2 = lok.id2
          AND req_sess.module = 'XXWSH920002C'; 
--
-- ##### 20090217 Ver.1.3 �{��#1176�Ή� END   #####
--
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� END   #####
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  LOOP
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� START #####
--    EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� END   #####
    --�q�R���J�����g�������擾
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
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� START #####
    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� END   #####
    --���b�N�����̊J�n
    FOR lock_rec IN lock_cur LOOP
--
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� START #####
--      lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
--      EXECUTE IMMEDIATE lv_strsql;
--      lv_staus := '1';
--
-- ##### 20090219 Ver.1.4 �{��#1176�Ή��i�ǉ��C���j START #####
      -- �폜�ΏۃZ�b�V�������O�o��
--      FND_FILE.PUT_LINE(FND_FILE.LOG, '�y�Z�b�V�����ؒf�z' || 
--                                      ' ���������F �v��ID[' || TO_CHAR(in_reqid) || '] ' ||
--                                      ' �ؒf�ΏۃZ�b�V�����F' ||
--                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
--                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
--                                      ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
--                                      ' action['  || lock_rec.action           || '] ' ||
--                                      ' module['  || lock_rec.module           || '] '
--                                      );
      FND_FILE.PUT_LINE(FND_FILE.LOG, '�y�Z�b�V�����ؒf�z' || ' �v��ID[' || TO_CHAR(in_reqid) || '] ' ||
                                      ' �ؒf�ΏۃZ�b�V�����F' ||
                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
                                      ' serial#[' || TO_CHAR(lock_rec.serial#) || '] ' ||
                                      ' action['  || lock_rec.action           || '] ' ||
                                      ' module['  || lock_rec.module           || '] ' ||
                                      ' lmode['   || TO_CHAR(lock_rec.lmode)   || '] ' ||
                                      ' request[' || TO_CHAR(lock_rec.request) || '] ' ||
                                      ' ctime['   || TO_CHAR(lock_rec.ctime)   || '] '
                                      );
-- ##### 20090219 Ver.1.4 �{��#1176�Ή��i�ǉ��C���j END   #####
--
      -- =====================================
      -- �Z�b�V�����ؒf�R���J�����g���N������
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
        -- ���s�Ɏ��s�����ꍇ�̓G���[�ɂ����b�Z�[�W���o�͂���悤�ɏC��
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB('XXWSH000001H �N���G���[ ' ||
                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || ']' ||
                      ' sid['     || TO_CHAR(lock_rec.sid)     || ']' ||
                      ' serial['  || TO_CHAR(lock_rec.serial#) || ']' || '<' || FND_MESSAGE.GET || '>'
                      ,1,5000);
        RAISE global_process_expt;
      END IF;
--
      -- ==============================================
      -- �N�������Z�b�V�����ؒf�R���J�����g�̏I����҂�
      -- ==============================================
      ln_ret := FND_CONCURRENT.WAIT_FOR_REQUEST(ln_reqid ,
                                                0.05,
                                                3600,
                                                lv_phase2,
                                                lv_status2,
                                                lv_dev_phase2,
                                                lv_dev_status2,
                                                lv_message2);
      -- �X�e�[�^�X�m�F
      IF (ln_ret = FALSE) THEN
        -- �G���[�͖������āA���O�̂ݏo��
        lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                     ' �v��ID['  || TO_CHAR(ln_reqid) || ']' ||
                     ' phase['   || lv_dev_phase2     || ']' ||
                     ' status['  || lv_dev_status2    || ']' ||
                     ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      -- COMPLETE�ȊO�ł̏I��
      ELSIF (lv_dev_phase2 <> 'COMPLETE') THEN
        -- �G���[�͖������āA���O�̂ݏo��
        lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                     ' �v��ID['  || TO_CHAR(ln_reqid) || ']' ||
                     ' phase['   || lv_dev_phase2     || ']' ||
                     ' status['  || lv_dev_status2    || ']' ||
                     ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      -- �X�e�[�^�X��NORMAL�ȊO�ł̏I��
      ELSIF (lv_dev_status2 <> 'NORMAL') THEN
        -- �G���[�͖������āA���O�̂ݏo��
        lv_errmsg := SUBSTRB('XXWSH000001H WAIT_FOR_REQUEST ERROR ' || 
                     ' �v��ID['  || TO_CHAR(ln_reqid) || ']' ||
                     ' phase['   || lv_dev_phase2     || ']' ||
                     ' status['  || lv_dev_status2    || ']' ||
                     ' message[' || lv_message2       || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      END IF;
--
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� END   #####
    END LOOP;
--
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� START #####
    -- �m�F���1�b�ҋ@����
    DBMS_LOCK.SLEEP(0.05);
-- ##### 20090119 Ver.1.1 �{��#1038�Ή� END   #####
--
  END LOOP;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
----
  END release_lock;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2       --  �G���[�E���b�Z�[�W
    ,retcode       OUT NOCOPY VARCHAR2       --  ���^�[���E�R�[�h
    ,iv_item_class         IN  VARCHAR2      -- 1.���i�敪
    ,iv_action_type        IN  VARCHAR2      -- 2.�������
    ,iv_block1             IN  VARCHAR2      -- 3.�u���b�N�P
    ,iv_block2             IN  VARCHAR2      -- 4.�u���b�N�Q
    ,iv_block3             IN  VARCHAR2      -- 5.�u���b�N�R
    ,iv_deliver_from_id    IN  VARCHAR2      -- 6.�o�Ɍ�
    ,iv_deliver_type       IN  VARCHAR2      -- 7.�o�Ɍ`��
    ,iv_deliver_date_from  IN  VARCHAR2      -- 8.�o�ɓ�From
    ,iv_deliver_date_to    IN  VARCHAR2      -- 9.�o�ɓ�To
-- ##### 20090127 Ver.1.2 �{��#1038�Ή� START #####
    ,iv_instruction_dept   IN  VARCHAR2      -- 10.�w������
-- ##### 20090127 Ver.1.2 �{��#1038�Ή� END   #####
    )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_reqid   NUMBER;           -- �v��ID
    lv_errbuf  VARCHAR2(5000);   -- �G���[�E���b�Z�[�W�i���[�J���j
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h�i���[�J���j
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
  BEGIN
    -- ==================
    -- �q�R���J�����g�̋N��
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
-- ##### 20090127 Ver.1.2 �{��#1038�Ή� START #####
      Argument10  => iv_instruction_dept
-- ##### 20090127 Ver.1.2 �{��#1038�Ή� END   #####
      );
    if ln_reqid > 0 then
      commit;
    else
      rollback;
      retcode := '1';
      return;
    end if;
    -- ==================
    -- ���b�N�̉����̌Ăяo��
    -- ==================
    release_lock(
          ln_reqid,
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    retcode := lv_retcode;
    errbuf := lv_errmsg;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
END xxwsh920009c;
/
