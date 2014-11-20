CREATE OR REPLACE PACKAGE BODY xxinv590001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv590001c(body)
 * Description      : OPM�݌ɉ�v���ԃI�[�v��
 * MD.050           : OPM�݌ɉ�v���ԃI�[�v��(�N���[�Y) T_MD050_BPO_590
 * MD.070           : OPM�݌ɉ�v���ԃI�[�v��(59A) T_MD070_BPO_59A
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/08/06    1.0   Y.Suzuki         �V�K�쐬
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
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  lock_expt              EXCEPTION;               -- ���b�N�擾��O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- ���b�Z�[�W�p�萔
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxinv590001c';                           -- �p�b�P�[�W��
  gv_app_name       CONSTANT VARCHAR2(5)   := 'XXCMN';                                  -- �A�v���P�[�V�����Z�k��
  gv_tkn_name       CONSTANT VARCHAR2(100) := '�݌ɑq�ɃX�e�[�^�X/�݌ɑq�ɃI�[�v���\';  -- �e�[�u����
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10019 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';   -- ���b�N�擾�G���[
--
  -- �g�[�N��
  gv_tkn_table      CONSTANT VARCHAR2(10) := 'TABLE';             -- �g�[�N���F�e�[�u����
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
  TYPE whse_code_typ IS TABLE OF ic_whse_sts.whse_code%TYPE INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- �Ώۑq�Ɏ擾�p���R�[�h
  TYPE whse_code_rec IS RECORD(
    whse_code ic_whse_sts.whse_code%TYPE
  );
--
  -- ***************************************
  -- ***      ���ڊi�[�e�[�u���^��`     ***
  -- ***************************************
--
  -- �Ώۑq�Ɏ擾�p���R�[�h
  TYPE whse_code_tbl IS TABLE OF whse_code_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �e�[�u���^�O���[�o���ϐ�
  gt_whse_code_tbl  whse_code_tbl;            -- �Ώۑq�Ɏ擾�p���R�[�h
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_sequence         IN     VARCHAR2,                -- �V�[�P���XID
    iv_fiscal_year      IN     VARCHAR2,                -- ��v�N�x
    iv_period           IN     VARCHAR2,                -- ����
    iv_period_id        IN     VARCHAR2,                -- ����ID
    iv_start_date       IN     VARCHAR2,                -- �J�n���t
    iv_end_date         IN     VARCHAR2,                -- �I�����t
    iv_op_code          IN     VARCHAR2,                -- Operators Identifier Number
    iv_orgn_code        IN     VARCHAR2,                -- ��ЃR�[�h
    iv_close_ind        IN     VARCHAR2,                -- �����敪(1:OPEN,2:�b��CLOSE,3:CLOSE)
    ov_errbuf           OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,                -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_user_id   NUMBER;
    ln_login_id  NUMBER;
--
    -- *** ���[�J���E���R�[�h ***
    lt_whse_code whse_code_typ;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'INPUT PARAMETERS');
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'SEQUENCE   - '||iv_sequence);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'FISCAL YEAR- '||iv_fiscal_year);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'PERIOD     - '||iv_period);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'PERIOD ID  - '||iv_period_id);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'START DATE - '||iv_start_date);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'END DATE   - '||iv_end_date);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'OP CODE    - '||iv_op_code);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'ORGN CODE  - '||iv_orgn_code);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'CLOSE IND  - '||iv_close_ind);
--
    ln_user_id  := FND_GLOBAL.USER_ID;
    ln_login_id := FND_GLOBAL.LOGIN_ID;
--
    -- A-1 �Ώۃf�[�^�̎擾
    SELECT iws.whse_code
    BULK COLLECT INTO gt_whse_code_tbl
    FROM   xxinv_open_warehouses xow
          ,ic_whse_sts iws
    WHERE  xow.inventory_open_id = TO_NUMBER(iv_sequence)
    AND    xow.whse_code         = iws.whse_code
    AND    iws.fiscal_year       = iv_fiscal_year
    AND    iws.period            = iv_period
    FOR UPDATE NOWAIT;
--
    IF (gt_whse_code_tbl IS NOT NULL) THEN
      -- ���[�v�����ɂāA�o���N�擾�����f�[�^�����ڒP�ʂ̃e�[�u���^�ֈڍs
      <<upd_loop>>
      FOR col_cnt IN 1 .. gt_whse_code_tbl.COUNT LOOP
        lt_whse_code(col_cnt)    := gt_whse_code_tbl(col_cnt).whse_code;
      END LOOP upd_loop;
--
      -- A-2 ic_whse_sts�\�̍X�V
      FORALL upd_cnt IN 1 .. lt_whse_code.COUNT
        UPDATE ic_whse_sts
        SET    log_end_date      = SYSDATE
              ,close_whse_ind    = iv_close_ind
              ,last_updated_by   = ln_user_id
              ,last_update_date  = SYSDATE
              ,last_update_login = ln_login_id
        WHERE  whse_code         = lt_whse_code(upd_cnt)
        AND    fiscal_year       = iv_fiscal_year
        AND    period            = iv_period;
--
      -- A-3 xxinv_open_warehouses�\�̍폜
      DELETE FROM xxinv_open_warehouses
      WHERE inventory_open_id = TO_NUMBER(iv_sequence);
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ���b�N�擾��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10019,  -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                            gv_tkn_table,       -- �g�[�N��TABLE
                            gv_tkn_name         -- �e�[�u����
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
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
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    retcode             OUT    VARCHAR2,                -- ���^�[���E�R�[�h             --# �Œ� #
    iv_sequence         IN     VARCHAR2,                -- �V�[�P���XID
    iv_fiscal_year      IN     VARCHAR2,                -- ��v�N�x
    iv_period           IN     VARCHAR2,                -- ����
    iv_period_id        IN     VARCHAR2,                -- ����ID
    iv_start_date       IN     VARCHAR2,                -- �J�n���t
    iv_end_date         IN     VARCHAR2,                -- �I�����t
    iv_op_code          IN     VARCHAR2,                -- Operators Identifier Number
    iv_orgn_code        IN     VARCHAR2,                -- ��ЃR�[�h
    iv_close_ind        IN     VARCHAR2)                -- �����敪(1:OPEN,2:�b��CLOSE,3:CLOSE
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                 -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_sequence,            -- �V�[�P���XID
      iv_fiscal_year,         -- ��v�N�x
      iv_period,              -- ����
      iv_period_id,           -- ����ID
      iv_start_date,          -- �J�n���t
      iv_end_date,            -- �I�����t
      iv_op_code,             -- Operators Identifier Number
      iv_orgn_code,           -- ��ЃR�[�h
      iv_close_ind,           -- �����敪(1:OPEN,2:�b��CLOSE,3:CLOSE)
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      errbuf := lv_errbuf;
      ROLLBACK;
    END IF;
--
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
--###########################  �Œ蕔 END   #######################################################
--
END xxinv590001c;
/
