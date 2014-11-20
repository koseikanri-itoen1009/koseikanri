create or replace PACKAGE BODY xxwsh400006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400006c(spec)
 * Description      : �o�׈˗��m�菈��
 * MD.050           : T_MD050_BPO_401_�o�׈˗�
 * MD.070           : �o�׈˗��m�菈�� T_MD070_EDO_BPO_40G
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  ship_set               �o�׈˗��m�菈��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/3/24     1.0   R.Matusita       �V�K�쐬
 *  2008/4/23     1.1   R.Matusita       �����ύX�v��#63
 *  2008/6/05     1.2   N.Yoshida        �z����R�[�h�˔z����ID�ϊ��Ή�(�����s�)
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
  lock_expt                 EXCEPTION;     -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxwsh400006c'; -- �p�b�P�[�W��
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';        -- ���W���[�����ȗ��FXXCMN�}�X�^����
  gv_cnst_msg_kbn   CONSTANT VARCHAR2(5)    := 'XXWSH';
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';
                                            -- ���b�Z�[�W�F���b�N�擾�G���[
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- ���b�Z�[�W�F�f�[�^�擾�G���[
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';
                                            -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
  gv_cnst_msg_null CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-11161';  -- �K�{�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_222  CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-11222';  --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_upd_cnt          NUMBER DEFAULT 0;      -- �X�V����
--
  gv_msg_kbn          CONSTANT VARCHAR2(5)  DEFAULT 'XXCMN';
  --���b�Z�[�W�ԍ�
  gv_msg_80a_016      CONSTANT VARCHAR2(15) DEFAULT 'APP-XXCMN-10018';  --API�G���[(�R���J�����g)
  --�g�[�N��
  gv_tkn_api_name     CONSTANT VARCHAR2(15) DEFAULT 'API_NAME';
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- ���i�敪
    iv_head_sales_branch     IN  VARCHAR2  DEFAULT NULL, -- �Ǌ����_
    iv_input_sales_branch    IN  VARCHAR2  DEFAULT NULL, -- ���͋��_
    iv_deliver_to_id         IN  VARCHAR2  DEFAULT NULL, -- �z����ID
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- �˗�No
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- �o�ɓ�
    id_schedule_arrival_date IN  DATE      DEFAULT NULL, -- ����
    iv_status_kbn            IN  VARCHAR2,               -- ���߃X�e�[�^�X�`�F�b�N�敪
    ov_errbuf                OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    gv_cnst_msg       CONSTANT VARCHAR2(30)  := '���߃X�e�[�^�X�`�F�b�N�敪';
    gv_cnst_del_to_id CONSTANT VARCHAR2(30)  := '�z����ID';
    lv_type           CONSTANT VARCHAR2(30)  := '���l';
    -- *** ���[�J���ϐ� ***
--
    ln_deliver_to_id   NUMBER ; -- �z����ID(���l�^)
    ivv_deliver_to_id  VARCHAR2(30) ; -- �z����ID(�ϊ���z����ID)
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- �u���߃X�e�[�^�X�`�F�b�N�敪�v�`�F�b�N(G-1)
    IF (iv_status_kbn IS NULL) THEN
      -- ���߃X�e�[�^�X�`�F�b�N�敪��NULL�`�F�b�N���s���܂�
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_null,
                                            'PARAMETER',
                                            gv_cnst_msg);
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- �z����R�[�h�˔z����ID�ϊ�����
    -- ==================================================
    IF (iv_deliver_to_id IS NOT NULL) THEN
      BEGIN
        SELECT party_site_id
          INTO   ivv_deliver_to_id
          FROM   xxcmn_cust_acct_sites2_v
          WHERE  ship_to_no  = iv_deliver_to_id
          GROUP BY party_site_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ivv_deliver_to_id := NULL;
        WHEN TOO_MANY_ROWS THEN
          RAISE global_process_expt;
      END;
    ELSE
      ivv_deliver_to_id := NULL;
    END IF;
    
    ln_deliver_to_id := TO_NUMBER(ivv_deliver_to_id);

--
    -- ==================================================
    -- �o�׈˗��m��֐��N��(G-2)
    -- ==================================================
    xxwsh400003c.ship_set(
      iv_prod_class,                  -- ���i�敪
      iv_head_sales_branch,           -- �Ǌ����_
      iv_input_sales_branch,          -- ���͋��_
      ln_deliver_to_id,               -- �z����ID
      iv_request_no,                  -- �˗�No
      id_schedule_ship_date,          -- �o�ɓ�
      id_schedule_arrival_date,       -- ����
      '1',                            -- �ďo���t���O
      iv_status_kbn,                  -- ���߃X�e�[�^�X�`�F�b�N�敪
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_warn) THEN
      -- ���[�j���O�̏ꍇ
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
    ELSIF (lv_retcode = gv_status_error) THEN
      -- main����ROLLBACK�������s���ׁAnormal����
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���l�ϊ��G���[�n���h�� ***
    WHEN INVALID_NUMBER THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_222,
                                              'PARAMETER',
                                              gv_cnst_del_to_id,
                                              'TYPE',
                                              lv_type);
      RAISE global_process_expt;
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
    errbuf                   OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT NOCOPY VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_prod_class            IN  VARCHAR2,                -- ���i�敪
    iv_head_sales_branch     IN  VARCHAR2,                -- �Ǌ����_
    iv_input_sales_branch    IN  VARCHAR2,                -- ���͋��_
    iv_deliver_to_id         IN  VARCHAR2,                -- �z����ID
    iv_request_no            IN  VARCHAR2,                -- �˗�No
    iv_schedule_ship_date    IN  VARCHAR2,                -- �o�ɓ�
    iv_schedule_arrival_date IN  VARCHAR2,                -- ����
    iv_status_kbn            IN  VARCHAR2                 -- ���߃X�e�[�^�X�`�F�b�N�敪
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_prod_class,                               -- ���i�敪
      iv_head_sales_branch,                        -- �Ǌ����_
      iv_input_sales_branch,                       -- ���͋��_
      iv_deliver_to_id,                            -- �z����ID
      iv_request_no,                               -- �˗�No
      FND_DATE.STRING_TO_DATE(iv_schedule_ship_date, 'YYYY/MM/DD'),    -- �o�ɓ�
      FND_DATE.STRING_TO_DATE(iv_schedule_arrival_date, 'YYYY/MM/DD'), -- ����
      iv_status_kbn,                               -- ���߃X�e�[�^�X�`�F�b�N�敪
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ======================
    -- ���[�j���O�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
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
END xxwsh400006c;
/
