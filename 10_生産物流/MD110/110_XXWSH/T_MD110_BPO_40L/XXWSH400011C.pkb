create or replace PACKAGE BODY xxwsh400011c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400011c(spec)
 * Description      : �o�׈˗����ߋN������
 * MD.050           : T_MD050_BPO_401_�o�׈˗�
 * MD.070           : �o�׈˗����ߏ��� T_MD070_BPO_40H
 * Version          : 1.1
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  release_lock             P         ���b�N�����֐�
 *  main                     P         ���C��
 * ------------- ----------- --------- --------------------------------------------------
 *  Date         Ver.  Editor          Description
 * ------------- ----- --------------- --------------------------------------------------
 *  2009/01/16   1.0   T.Ohashi        �V�K�쐬
 *  2009/02/23   1.1   M.Nomura        �{��#1176�Ή��i�ǉ��C���j
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
  gv_pkg_name           CONSTANT VARCHAR2(100)  :=  'xxwsh400011c'; -- �p�b�P�[�W��
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
  to_date_expt_m  EXCEPTION;  -- ���t�ϊ��G���[m
  to_date_expt_d  EXCEPTION;  -- ���t�ϊ��G���[d
  to_date_expt_y  EXCEPTION;  -- ���t�ϊ��G���[y
  
  PRAGMA EXCEPTION_INIT(to_date_expt_m, -1843); -- ���t�ϊ��G���[m
  PRAGMA EXCEPTION_INIT(to_date_expt_d, -1847); -- ���t�ϊ��G���[d
  PRAGMA EXCEPTION_INIT(to_date_expt_y, -1861); -- ���t�ϊ��G���[y
  gv_msg_xxwsh_13501    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13501';
                                                      -- �R���J�����g���s�G���[
  gv_tkn_parm_name      CONSTANT VARCHAR2(100)  :=  'PARM_NAME';  -- �g�[�N���FPARM_NAME
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

-- ##### 20090116 Ver.1.2 �{��#900�Ή� START #####
    ln_reqid        NUMBER;           -- �v��ID
    ln_ret          BOOLEAN;
    lv_phase2       VARCHAR2(1000);
    lv_status2      VARCHAR2(1000);
    lv_dev_phase2   VARCHAR2(1000);
    lv_dev_status2  VARCHAR2(1000);
    lv_message2     VARCHAR2(1000);
-- ##### 20090116 Ver.1.2 �{��#900�Ή� END   #####
--
    -- *** ���[�J���E�J�[�\�� session�����Ώێ擾***
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j START #####
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
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j END   #####
--
--
    -- *** ���[�J���E���R�[�h ***
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
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j START #####
    -- �R���J�����g����������܂ŏ������p������
--    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j END   #####
    --�q�R���J�����g�������擾
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
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j START #####
    -- �R���J�����g����������܂ŏ������p������
    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j END   #####
--
    --���b�N�����̊J�n
    FOR lock_rec IN lock_cur LOOP
--
      -- �폜�ΏۃZ�b�V�������O�o��
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j START #####
-- ���O���e�ύX
--      FND_FILE.PUT_LINE(FND_FILE.LOG, '�y�Z�b�V�����ؒf�z' || 
--                                      ' �o�׈˗����ߏ����F �v��ID[' || TO_CHAR(in_reqid) || '] ' ||
--                                      ' �ؒf�ΏۃZ�b�V�����F' ||
--                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
--                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
--                                      ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
--                                      ' action['  || lock_rec.action           || '] ' ||
--                                      ' module['  || lock_rec.module           || '] '
--                                      );
--
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
--
-- ##### 20090223 Ver.1.1 �{��#1176�Ή��i�ǉ��C���j END   #####
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
                                                1,
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
        lv_errmsg := SUBSTRB('WAIT_FOR_REQUEST ERROR return reqid ' || TO_CHAR(ln_reqid) || 
                     ' phase['   || lv_dev_phase2  || ']' ||
                     ' status['  || lv_dev_status2 || ']' ||
                     ' message[' || lv_message2    || ']' || '<' || FND_MESSAGE.GET || '>'
                     , 1 ,5000);
        FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
--
      -- �X�e�[�^�X��NORMAL�ȊO�ł̏I��
      ELSIF (lv_dev_status2 <> 'NORMAL') THEN
        -- �G���[�͖������āA���O�̂ݏo��
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
    -- �m�F���1�b�ҋ@����
    DBMS_LOCK.SLEEP(1);
--
  END LOOP;
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
    errbuf        OUT NOCOPY VARCHAR2,                   --  �G���[�E���b�Z�[�W
    retcode       OUT NOCOPY VARCHAR2,                   --  ���^�[���E�R�[�h
    iv_order_type_id         IN  VARCHAR2,               --  1.�o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2,               --  2.�o�׌�
    iv_sales_base            IN  VARCHAR2,               --  3.���_
    iv_sales_base_category   IN  VARCHAR2,               --  4.���_�J�e�S��
    iv_lead_time_day         IN  VARCHAR2,               --  5.���Y����LT
    iv_schedule_ship_date    IN  VARCHAR2,               --  6.�o�ɓ�
    iv_base_record_class     IN  VARCHAR2,               --  7.����R�[�h�敪
    iv_request_no            IN  VARCHAR2,               --  8.�˗�No
    iv_tighten_class         IN  VARCHAR2,               --  9.���ߏ����敪
    iv_prod_class            IN  VARCHAR2,               -- 10.���i�敪
    iv_tightening_program_id IN  VARCHAR2,               -- 11.���߃R���J�����gID
    iv_instruction_dept      IN  VARCHAR2                -- 12.����
    )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    cv_status_g   CONSTANT VARCHAR2(10)   :=  'G';          -- �x��
    cv_status_e   CONSTANT VARCHAR2(10)   :=  'E';          -- �G���[
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_reqid   NUMBER;           -- �v��ID
    lv_errbuf  VARCHAR2(5000);   -- �G���[�E���b�Z�[�W�i���[�J���j
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h�i���[�J���j
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_dev_status VARCHAR2(10);                             -- �X�e�[�^�X
    lv_gen_retcode VARCHAR2(5000);                          -- ���s�R���J�����g�X�e�[�^�X
  BEGIN
    retcode := gv_status_normal;
    -- ==================
    -- �q�R���J�����g�̋N��
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
-- ���s�Ɏ��s�����ꍇ�̓G���[�ɂ����b�Z�[�W���o�͂���悤�ɏC��
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_13501  -- ���b�Z�[�W�FAPP-XXWSH-13501 �R���J�����g���s�G���[
                    , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                    , iv_schedule_ship_date
                   ),1,5000);
      RAISE global_process_expt;
    end if;
    -- ==================
    -- ���b�N�̉����̌Ăяo��
    -- ==================
    release_lock(
          ln_reqid,
          lv_errbuf,
          lv_retcode,
          lv_errmsg);
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- �w�肵�����t�̏����X�e�[�^�X���擾
    BEGIN
      SELECT status_code
        INTO lv_dev_status
        FROM FND_CONC_REQ_SUMMARY_V
       WHERE request_id = ln_reqid;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- ���t���Ƃ̏������e��\��
    lv_gen_retcode := NULL;
    -- �X�e�[�^�X���x���̏ꍇ
    IF (lv_dev_status = cv_status_g) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�v��ID:' || TO_CHAR(ln_reqid)
                                     || '�A�o�ɓ��F' || iv_schedule_ship_date
                                     || '�A�X�e�[�^�X�F' || '�x���I��');
      lv_gen_retcode := gv_status_warn;
    ELSIF (lv_dev_status = cv_status_e) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�v��ID:' || TO_CHAR(ln_reqid)
                                     || '�A�o�ɓ��F' || iv_schedule_ship_date
                                     || '�A�X�e�[�^�X�F' || '�G���[�I��');
      lv_gen_retcode := gv_status_error;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�v��ID:' || TO_CHAR(ln_reqid)
                                     || '�A�o�ɓ��F' || iv_schedule_ship_date
                                     || '�A�X�e�[�^�X�F' || '����I��');
      lv_gen_retcode := gv_status_normal;
    END IF;
    -- �G���[�Ō��݂̃X�e�[�^�X���擾�����X�e�[�^�X���傫���ꍇ�͎擾�X�e�[�^�X���Z�b�g
    IF  (lv_dev_status = cv_status_e)
    AND (lv_gen_retcode > retcode) THEN
      retcode := lv_gen_retcode;
    END IF;
      -- ======================
      -- �G���[�E���b�Z�[�W�o��
      -- ======================
      -- ==================================
      -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
      -- ==================================
  EXCEPTION
    -- *** �������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      errbuf  := lv_errmsg;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
  END main;
--
END xxwsh400011c;
/
