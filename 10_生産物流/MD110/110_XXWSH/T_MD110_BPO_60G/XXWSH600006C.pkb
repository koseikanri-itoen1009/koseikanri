create or replace PACKAGE BODY xxwsh600006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600006c(body)
 * Description      : �����z�Ԕz���v��쐬�������b�N�Ή�
 * MD.050           : �z�Ԕz���v�� T_MD050_BPO_600
 * MD.070           : �����z�Ԕz���v��쐬���� T_MD070_BPO_60B
 * Version          : 1.3
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
 *  2008/11/29    1.0  MIYATA.          �V�K�쐬
 *  2008/12/20    1.1  M.Hokkanji       �{�ԏ�Q#738
 *  2009/01/16    1.2  M.Nomura         �{�ԏ�Q#900
 *  2009/01/27    1.3  H.Itou           �{�ԏ�Q#1028
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
-- Ver1.1 M.Hokkanji Start
  to_date_expt_m  EXCEPTION;  -- ���t�ϊ��G���[m
  to_date_expt_d  EXCEPTION;  -- ���t�ϊ��G���[d
  to_date_expt_y  EXCEPTION;  -- ���t�ϊ��G���[y
  
  PRAGMA EXCEPTION_INIT(to_date_expt_m, -1843); -- ���t�ϊ��G���[m
  PRAGMA EXCEPTION_INIT(to_date_expt_d, -1847); -- ���t�ϊ��G���[d
  PRAGMA EXCEPTION_INIT(to_date_expt_y, -1861); -- ���t�ϊ��G���[y
  gv_msg_xxwsh_13151    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13151';
                                                      -- ���b�Z�[�W�F�K�{�p�����[�^�����̓��b�Z�[�W
  gv_msg_xxwsh_11113    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11113';
                                                      -- ���b�Z�[�W�F���t�t�]�G���[���b�Z�[�W
  gv_msg_xxwsh_11809    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-11809';
                                                      -- ���b�Z�[�W�F���̓p�����[�^�����G���[
  gv_msg_xxwsh_13501    CONSTANT VARCHAR2(100)  :=  'APP-XXWSH-13501';
                                                      -- �R���J�����g���s�G���[
  gv_tkn_item           CONSTANT VARCHAR2(100)  :=  'ITEM';       -- �g�[�N���FITEM
  gv_tkn_from           CONSTANT VARCHAR2(100)  :=  'FROM';       -- �g�[�N���FFROM
  gv_tkn_to             CONSTANT VARCHAR2(100)  :=  'TO';         -- �g�[�N���FTO
  gv_tkn_parm_name      CONSTANT VARCHAR2(100)  :=  'PARM_NAME';  -- �g�[�N���FPARM_NAME
-- Ver1.1 M.Hokkanji End
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
-- ##### 20090116 Ver.1.2 �{��#900�Ή� START #####
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
    -- gv$sesson�Agv$lock���Q�Ƃ���悤�ɏC��
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
-- ##### 20090116 Ver.1.2 �{��#900�Ή� END   #####
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
-- ##### 20090116 Ver.1.2 �{��#900�Ή� START #####
--    EXIT WHEN (lv_phase = 'Y' OR lv_staus = '1');
    -- �R���J�����g����������܂ŏ������p������
    EXIT WHEN (lv_phase = 'Y');
-- ##### 20090116 Ver.1.2 �{��#900�Ή� END   #####
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
    --���b�N�����̊J�n
    FOR lock_rec IN lock_cur LOOP
--
      -- �폜�ΏۃZ�b�V�������O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, '�y�Z�b�V�����ؒf�z' || 
                                      ' �����z�ԁF �v��ID[' || TO_CHAR(in_reqid) || '] ' ||
                                      ' �ؒf�ΏۃZ�b�V�����F' ||
                                      ' inst_id[' || TO_CHAR(lock_rec.inst_id) || '] ' ||
                                      ' sid['     || TO_CHAR(lock_rec.sid)     || '] ' ||
                                      ' serial['  || TO_CHAR(lock_rec.serial#) || '] ' ||
                                      ' action['  || lock_rec.action           || '] ' ||
                                      ' module['  || lock_rec.module           || '] '
                                      );
--
-- ##### 20090116 Ver.1.2 �{��#900�Ή� START #####
--      lv_strsql := 'ALTER SYSTEM KILL SESSION ''' || lock_rec.sid || ',' || lock_rec.serial# || ''' IMMEDIATE';
--      EXECUTE IMMEDIATE lv_strsql;
--      lv_staus := '1';
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
-- ##### 20090116 Ver.1.2 �{��#900�Ή� END   #####
--
    END LOOP;
--
-- ##### 20090116 Ver.1.2 �{��#900�Ή� START #####
    -- �m�F���1�b�ҋ@����
    DBMS_LOCK.SLEEP(1);
-- ##### 20090116 Ver.1.2 �{��#900�Ή� END   #####
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
    errbuf        OUT NOCOPY VARCHAR2,            --  �G���[�E���b�Z�[�W
    retcode       OUT NOCOPY VARCHAR2,            --  ���^�[���E�R�[�h
    iv_prod_class           IN  VARCHAR2,         --  1.���i�敪
    iv_shipping_biz_type    IN  VARCHAR2,         --  2.�������
    iv_block_1              IN  VARCHAR2,         --  3.�u���b�N1
    iv_block_2              IN  VARCHAR2,         --  4.�u���b�N2
    iv_block_3              IN  VARCHAR2,         --  5.�u���b�N3
    iv_storage_code         IN  VARCHAR2,         --  6.�o�Ɍ�
    iv_transaction_type_id  IN  VARCHAR2,         --  7.�o�Ɍ`��ID
    iv_date_from            IN  VARCHAR2,         --  8.�o�ɓ�From
    iv_date_to              IN  VARCHAR2,         --  9.�o�ɓ�To
    iv_forwarder_id         IN  VARCHAR2,         -- 10.�^���Ǝ�ID
-- Ver1.3 H.Itou Add Start �{�ԏ�Q#1028�Ή�
    iv_instruction_dept     IN  VARCHAR2          -- 11.�w������
-- Ver1.3 H.Itou Add End
    )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
-- Ver1.1 M.Hokkanji Start
    cv_date_from  CONSTANT VARCHAR2(100)  :=  '�o�ɓ�FROM'; -- �o�ɓ�From
    cv_date_to    CONSTANT VARCHAR2(100)  :=  '�o�ɓ�TO';   -- �o�ɓ�To
    cv_status_g   CONSTANT VARCHAR2(10)   :=  'G';          -- �x��
    cv_status_e   CONSTANT VARCHAR2(10)   :=  'E';          -- �G���[
-- Ver1.1 M.Hokkanji End
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_reqid   NUMBER;           -- �v��ID
    lv_errbuf  VARCHAR2(5000);   -- �G���[�E���b�Z�[�W�i���[�J���j
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h�i���[�J���j
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver1.1 M.Hokkanji Start
    ld_date_from  DATE;                                     -- �o�ɓ�From
    ld_date_to    DATE;                                     -- �o�ɓ�To
    ld_loop_date  DATE;                                     -- ���[�v���t
    lv_dev_status VARCHAR2(10);                             -- �X�e�[�^�X
    lv_gen_retcode VARCHAR2(5000);                          -- ���s�R���J�����g�X�e�[�^�X
-- Ver1.1 M.Hokkanji End
  BEGIN
-- Ver1.1 M.hokkanji Start
    retcode := gv_status_normal;
    -- �o�ɓ�From������
    IF (iv_date_from IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_13151  -- ���b�Z�[�W�FAPP-XXWSH-13151 �K�{�p�����[�^�����̓G���[
                    , gv_tkn_item         -- �g�[�N���FITEM
                    , cv_date_from        -- �p�����[�^�D�o�ɓ�From
                   ),1,5000);
      RAISE global_process_expt;
    ELSE
      BEGIN
        -- �����`�F�b�N
        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_from)
        INTO  ld_date_from
        FROM  DUAL
        ;
      EXCEPTION
        WHEN to_date_expt_m THEN
          -- ��������
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11809  -- ���b�Z�[�W�FAPP-XXWSH-11809 ���̓p�����[�^�����G���[
                        , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                        , cv_date_from        -- �p�����[�^�D�o�ɓ�FROM
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_d THEN
          -- ��������
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11809  -- ���b�Z�[�W�FAPP-XXWSH-11809 ���̓p�����[�^�����G���[
                        , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                        , cv_date_from        -- �p�����[�^�D�o�ɓ�FROM
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_y THEN
          -- ���e�����ƕs��v
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11809  -- ���b�Z�[�W�FAPP-XXWSH-11809 ���̓p�����[�^�����G���[
                        , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                        , cv_date_from        -- �p�����[�^�D�o�ɓ�FROM
                       ),1,5000);
          RAISE global_process_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
    -- �o�ɓ�To������
    IF (iv_date_to IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_13151  -- ���b�Z�[�W�FAPP-XXWSH-13151 �K�{�p�����[�^�����̓G���[
                    , gv_tkn_item         -- �g�[�N���FITEM
                    , cv_date_to          -- �p�����[�^�D�o�ɓ�To
                   ),1,5000);
      RAISE global_process_expt;
    ELSE
      BEGIN
        -- �����`�F�b�N
        SELECT FND_DATE.CANONICAL_TO_DATE(iv_date_to)
        INTO  ld_date_to
        FROM  DUAL
        ;
      EXCEPTION
        WHEN to_date_expt_m THEN
          -- ��������
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11809  -- ���b�Z�[�W�FAPP-XXWSH-11809 ���̓p�����[�^�����G���[
                        , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                        , cv_date_to        -- �p�����[�^�D�o�ɓ�TO
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_d THEN
          -- ��������
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11809  -- ���b�Z�[�W�FAPP-XXWSH-11809 ���̓p�����[�^�����G���[
                        , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                        , cv_date_to          -- �p�����[�^�D�o�ɓ�TO
                       ),1,5000);
          RAISE global_process_expt;
        WHEN to_date_expt_y THEN
          -- ���e�����ƕs��v
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                        , gv_msg_xxwsh_11809  -- ���b�Z�[�W�FAPP-XXWSH-11809 ���̓p�����[�^�����G���[
                        , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                        , cv_date_to          -- �p�����[�^�D�o�ɓ�TO
                       ),1,5000);
          RAISE global_process_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
    END IF;
    -- ���t�t�]
    IF (ld_date_from > ld_date_to) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                    , gv_msg_xxwsh_11113  -- ���b�Z�[�W�FAPP-XXWSH-11113 ���t�t�]�G���[
                   ),1,5000);
      RAISE global_process_expt;
    END IF;
    ld_loop_date := ld_date_from;
    <<conc_loop>>
    LOOP
-- Ver1.1 M.hokkanji End
      -- ==================
      -- �q�R���J�����g�̋N��
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
-- Ver1.3 H.Itou Add Start �{�ԏ�Q#1028�Ή�
        Argument11  => iv_instruction_dept
-- Ver1.3 H.Itou Add End
        );
      if ln_reqid > 0 then
        commit;
      else
        rollback;
-- Ver1.1 M.Hokkanji Start
-- ���s�Ɏ��s�����ꍇ�̓G���[�ɂ����b�Z�[�W���o�͂���悤�ɏC��
--      retcode := '1';
--        return;
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_cnst_msg_kbn     -- ���W���[�������́FXXWSH �o�ׁE����/�z��
                      , gv_msg_xxwsh_13501  -- ���b�Z�[�W�FAPP-XXWSH-13501 ���t�t�]�G���[
                        , gv_tkn_parm_name    -- �g�[�N���FPARM_NAME
                        , TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                     ),1,5000);
        RAISE global_process_expt;
-- Ver1.1 M.Hokkanji End
      end if;
      -- ==================
      -- ���b�N�̉����̌Ăяo��
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
                                       || '�A�o�ח\����F' || TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                                       || '�A�X�e�[�^�X�F' || '�x���I��');
        lv_gen_retcode := gv_status_warn;
      ELSIF (lv_dev_status = cv_status_e) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�v��ID:' || TO_CHAR(ln_reqid)
                                       || '�A�o�ח\����F' || TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                                       || '�A�X�e�[�^�X�F' || '�G���[�I��');
        lv_gen_retcode := gv_status_error;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�v��ID:' || TO_CHAR(ln_reqid)
                                       || '�A�o�ח\����F' || TO_CHAR(ld_loop_date,'YYYY/MM/DD')
                                       || '�A�X�e�[�^�X�F' || '����I��');
        lv_gen_retcode := gv_status_normal;
      END IF;
      -- �G���[�Ō��݂̃X�e�[�^�X���擾�����X�e�[�^�X���傫���ꍇ�͎擾�X�e�[�^�X���Z�b�g
      IF  (lv_dev_status = cv_status_e)
      AND (lv_gen_retcode > retcode) THEN
        retcode := lv_gen_retcode;
      END IF;
      -- LOOP�I�����邩�̔��f
      EXIT WHEN (ld_loop_date >= ld_date_to );
      -- ���[�v���I�����Ȃ��ꍇ�͓��t��������炷
      ld_loop_date := ld_loop_date + 1;
    END LOOP conc_loop;
-- Ver1.1 M.Hokkanji End
      -- ======================
      -- �G���[�E���b�Z�[�W�o��
      -- ======================
      -- ==================================
      -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
      -- ==================================
-- Ver1.1 M.Hokkanji Start
--      retcode := lv_retcode;
--      errbuf := lv_errmsg;
-- Ver1.1 M.Hokkanji End
  EXCEPTION
-- Ver1.1 M.Hokkanji Start
    -- *** �������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      errbuf  := lv_errmsg;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- Ver1.1 M.Hokkanji End
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
-- Ver1.1 M.Hokkanji Start
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
-- Ver1.1 M.Hokkanji End
    -- *** OTHERS��O�n���h�� ***
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
