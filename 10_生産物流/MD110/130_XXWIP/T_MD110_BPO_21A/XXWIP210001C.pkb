CREATE OR REPLACE PACKAGE BODY xxwip210001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip210001c(body)
 * Description      : ���Y�o�b�`�ꊇ�N���[�Y����
 * MD.050           : ���Y�N���[�Y T_MD050_BPO_210
 * MD.070           : ���Y�o�b�`�ꊇ�N���[�Y����(21A) T_MD070_BPO_21A
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  parameter_check        �p�����[�^�`�F�b�N����  (A-1)
 *  get_common_data        ���ʃf�[�^�擾����      (A-2)
 *  get_lock               ���b�N�擾����          (A-4)
 *  certify_batch_api      ���Y��������            (A-5)
 *  close_batch_api        ���Y�N���[�Y����        (A-6)
 *  save_batch_api         ���Y�Z�[�u����          (A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/11/12    1.0   H.Itou           �V�K�쐬
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
  parameter_expt         EXCEPTION;        -- �p�����[�^��O
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
  not_alloc_expt         EXCEPTION;        -- ��������O
  skip_expt              EXCEPTION;        -- �X�L�b�v��O
  api_expt               EXCEPTION;        -- API��O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'XXWIP210001C'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';        -- ���W���[�������́FXXCMN ����
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';        -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10010  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010'; -- ���b�Z�[�W�FAPP-XXCMN-10010 �p�����[�^�G���[
  gv_msg_xxcmn10012  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10012'; -- ���b�Z�[�W�FAPP-XXCMN-10012 ���t�s���G���[
  gv_msg_xxcmn10001  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- ���b�Z�[�W�FAPP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
  gv_msg_xxwip10055  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10055'; -- ���b�Z�[�W�FAPP-XXWIP-10055 �Ώی��`�F�b�N�G���[
  gv_msg_xxwip10002  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10002'; -- ���b�Z�[�W�FAPP-XXWIP-10002 ���t�召��r�G���[
  gv_msg_xxwip10004  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10004'; -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
  gv_msg_xxwip10027  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10027'; -- ���b�Z�[�W�FAPP-XXWIP-10027 �������G���[���b�Z�[�W
  gv_msg_xxwip10049  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10049'; -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
  gv_batch_no        CONSTANT VARCHAR2(100) := '�o�b�`No.';
--
  -- �g�[�N��
  gv_tkn_parameter   CONSTANT VARCHAR2(100) := 'PARAMETER';       -- �g�[�N���FPARAMETER
  gv_tkn_value       CONSTANT VARCHAR2(100) := 'VALUE';           -- �g�[�N���FVALUE
  gv_tkn_item        CONSTANT VARCHAR2(100) := 'ITEM';            -- �g�[�N���FITEM
  gv_tkn_date        CONSTANT VARCHAR2(100) := 'DATE';            -- �g�[�N���FDATE
  gv_tkn_from        CONSTANT VARCHAR2(100) := 'FROM';            -- �g�[�N���FFROM
  gv_tkn_to          CONSTANT VARCHAR2(100) := 'TO';              -- �g�[�N���FTO
  gv_tkn_table       CONSTANT VARCHAR2(100) := 'TABLE';           -- �g�[�N���FTABLE
  gv_tkn_key         CONSTANT VARCHAR2(100) := 'KEY';             -- �g�[�N���FKEY
  gv_tkn_batch_no    CONSTANT VARCHAR2(100) := 'BATCH_NO';        -- �g�[�N���FBATCH_NO
  gv_tkn_api_name    CONSTANT VARCHAR2(100) := 'API_NAME';        -- �g�[�N���FAPI_NAME
--
  -- ���C���^�C�v
  gt_line_type_goods   CONSTANT gme_material_details.line_type%TYPE := 1;    -- ���C���^�C�v�F1�i�����i�j
--
  -- �Ɩ��X�e�[�^�X
  gt_duty_status_com   CONSTANT gme_batch_header.attribute4%TYPE    := '7';  -- �Ɩ��X�e�[�^�X�F7�i�����j
  gt_duty_status_cls   CONSTANT gme_batch_header.attribute4%TYPE    := '8';  -- �Ɩ��X�e�[�^�X�F8�i�N���[�Y�j
--
  -- �o�b�`�X�e�[�^�X
  gt_batch_status_com  CONSTANT gme_batch_header.batch_status%TYPE  := 3;    -- �o�b�`�X�e�[�^�X�F3�i�����j
--
  -- �����t���O
  gt_alloc_ind_n       CONSTANT gme_material_details.alloc_ind%TYPE := 0;    -- �����t���O�F0�i�������j
--
  -- API���^�[���E�R�[�h
  gv_api_s             CONSTANT VARCHAR2(1) := 'S';   -- API���^�[���E�R�[�h�FS �i�����j
--
  -- xxcmn���ʊ֐����^�[���E�R�[�h
  gn_e                 CONSTANT NUMBER := 1;     -- xxcmn���ʊ֐����^�[���E�R�[�h�F1�i�G���[�j
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_close_date         DATE;                      -- �N���[�Y���t
  gr_gme_batch_header  gme_batch_header%ROWTYPE;   -- �X�V�p���Y�o�b�`���R�[�h
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N����(A-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_plant_code         IN     VARCHAR2,      -- 1.�v�����g�R�[�h
    iov_product_date_from IN OUT VARCHAR2,      -- 2.���Y���iFROM�j
    iov_product_date_to   IN OUT VARCHAR2,      -- 3.���Y���iTO�j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- �v���O������
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
    -- �p�����[�^��
    cv_product_date_from  VARCHAR2(20) := '���Y���iFROM�j';  -- �p�����[�^���F���Y���iFROM�j
    cv_product_date_to    VARCHAR2(20) := '���Y���iTO�j';    -- �p�����[�^���F���Y���iTO�j
--
    -- �e�[�u����
    cv_sy_orgn_mst_b      VARCHAR2(20) := 'OPM�v�����g�}�X�^';  -- �e�[�u�����FOPM�v�����g�}�X�^
--
    -- *** ���[�J���ϐ� ***
    ld_product_date_from  DATE;   -- ���Y���iFROM�j
    ld_product_date_to    DATE;   -- ���Y���iTO�j
    ln_temp               NUMBER; -- �ꎞ�i�[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***          �K�{�`�F�b�N           ***
    -- ***************************************
    -- ���Y���iTO�j
    IF (iov_product_date_to IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn               -- ���W���[�������́FXXCMN ����
                     ,gv_msg_xxcmn10010      -- ���b�Z�[�W�FAPP-XXCMN-10010 �p�����[�^�G���[
                     ,gv_tkn_parameter       -- �g�[�N���FPARAMETER
                     ,cv_product_date_to     -- �p�����[�^���F���Y���iTO�j
                     ,gv_tkn_value           -- �g�[�N���FVALUE
                     ,iov_product_date_to    -- IN�p�����[�^.���Y���iTO�j
                    ),1,5000);
      RAISE parameter_expt;
    END IF;
--
    -- ***************************************
    -- ***          ���t�`�F�b�N           ***
    -- ***************************************
    -- ���Y���iFROM�j
    -- ���͂�����ꍇ�̂݃`�F�b�N
    IF (iov_product_date_from IS NOT NULL) THEN
      IF (xxcmn_common_pkg.check_param_date_yyyymmdd(iov_product_date_from) = gn_e) THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[�������́FXXCMN ����
                       ,gv_msg_xxcmn10012      -- ���b�Z�[�W�FAPP-XXCMN-10012 ���t�s���G���[
                       ,gv_tkn_item            -- �g�[�N���FITEM
                       ,cv_product_date_from   -- �p�����[�^���F���Y���iFROM�j
                       ,gv_tkn_value           -- �g�[�N���FVALUE
                       ,iov_product_date_from  -- IN�p�����[�^.���Y���iFROM�j
                      ),1,5000);
        RAISE parameter_expt;
--
      ELSE
        ld_product_date_from := FND_DATE.STRING_TO_DATE(iov_product_date_from,'YYYY/MM/DD HH24:MI:SS');
      END IF;
--
    END IF;
--
    -- ���Y���iTO�j
    IF (xxcmn_common_pkg.check_param_date_yyyymmdd(iov_product_date_to) = gn_e) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn               -- ���W���[�������́FXXCMN ����
                     ,gv_msg_xxcmn10012      -- ���b�Z�[�W�FAPP-XXCMN-10012 ���t�s���G���[
                     ,gv_tkn_item            -- �g�[�N���FITEM
                     ,cv_product_date_to     -- �p�����[�^���F���Y���iTO�j
                     ,gv_tkn_value           -- �g�[�N���FVALUE
                     ,iov_product_date_to    -- IN�p�����[�^.���Y���iTO�j
                    ),1,5000);
      RAISE parameter_expt;
--
    ELSE
      ld_product_date_to := FND_DATE.STRING_TO_DATE(iov_product_date_to,'YYYY/MM/DD HH24:MI:SS');
    END IF;
--
    -- ********************************************
    -- ***  �Ώی��`�F�b�N�i�����ȍ~�̓G���[�j  ***
    -- ********************************************
    -- ���Y���iFROM�j
    -- ���͂�����ꍇ�̂݃`�F�b�N
    IF (iov_product_date_from IS NOT NULL) THEN
      IF (TO_CHAR(ld_product_date_from,'YYYYMM') >= TO_CHAR(SYSDATE,'YYYYMM')) THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxwip               -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                       ,gv_msg_xxwip10055      -- ���b�Z�[�W�FAPP-XXCMN-10012 ���t�s���G���[
                       ,gv_tkn_date            -- �g�[�N���FDATE
                       ,cv_product_date_from   -- �p�����[�^���F���Y���iFROM�j
                       ,gv_tkn_value           -- �g�[�N���FVALUE
                       ,iov_product_date_from  -- IN�p�����[�^.���Y���iFROM�j
                      ),1,5000);
        RAISE parameter_expt;
      END IF;
    END IF;
--
    -- ���Y���iTO�j
    IF (TO_CHAR(ld_product_date_to,'YYYYMM') >= TO_CHAR(SYSDATE,'YYYYMM')) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10055      -- ���b�Z�[�W�FAPP-XXCMN-10012 ���t�s���G���[
                     ,gv_tkn_date            -- �g�[�N���FDATE
                     ,cv_product_date_to     -- �p�����[�^���F���Y���iTO�j
                     ,gv_tkn_value           -- �g�[�N���FVALUE
                     ,iov_product_date_to    -- IN�p�����[�^.���Y���iTO�j
                    ),1,5000);
      RAISE parameter_expt;
    END IF;
--
    -- ********************************************
    -- ***  �Ó����`�F�b�N�iFROM > TO�̓G���[�j ***
    -- ********************************************
    -- ���Y���iFROM�j�ɓ��͂�����ꍇ�̂݃`�F�b�N
    IF (iov_product_date_from IS NOT NULL) THEN
      IF (ld_product_date_from > ld_product_date_to) THEN
         -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxwip               -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                       ,gv_msg_xxwip10002      -- ���b�Z�[�W�FAPP-XXWIP-10002 ���t�召��r�G���[
                       ,gv_tkn_from            -- �g�[�N���FFROM
                       ,cv_product_date_from || gv_msg_part || TO_CHAR(ld_product_date_from,'YYYY/MM/DD')
                                               -- IN�p�����[�^.���Y���iFROM�j
                       ,gv_tkn_to              -- �g�[�N���FTO
                       ,cv_product_date_to   || gv_msg_part || TO_CHAR(ld_product_date_to,'YYYY/MM/DD')
                                               -- IN�p�����[�^.���Y���iTO�j
                      ),1,5000);
        RAISE parameter_expt;
      END IF;
      -- OUT�p�����[�^�Z�b�g
      iov_product_date_from := TO_CHAR(ld_product_date_from,'YYYY/MM/DD');
      iov_product_date_to   := TO_CHAR(ld_product_date_to,  'YYYY/MM/DD');
    ELSE
      -- OUT�p�����[�^�Z�b�g
      iov_product_date_to   := TO_CHAR(ld_product_date_to,  'YYYY/MM/DD');
    END IF;
--
    -- ********************************************
    -- ***         �v�����g���݃`�F�b�N         ***
    -- ********************************************
    -- ���͂�����ꍇ�̂݃`�F�b�N
    IF (iv_plant_code IS NOT NULL) THEN
      SELECT COUNT(somb.orgn_code) cnt       -- ���݃J�E���g
      INTO   ln_temp                         -- ���݃J�E���g
      FROM   sy_orgn_mst_b somb              -- OPM�v�����g�}�X�^
      WHERE  somb.orgn_code = iv_plant_code  -- �I���O�R�[�h = IN�p�����[�^.�v�����g�R�[�h
      AND    ROWNUM = 1
      ;
--
      IF ln_temp = 0 THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- ���W���[�������́FXXCMN ����
                         ,gv_msg_xxcmn10001      -- ���b�Z�[�W�FAPP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                         ,gv_tkn_table           -- �g�[�N���FTABLE
                         ,cv_sy_orgn_mst_b       -- �e�[�u�����FOPM�v�����g�}�X�^
                         ,gv_tkn_key             -- �g�[�N���FKEY
                         ,iv_plant_code          -- IN�p�����[�^.�v�����g�R�[�h
                        ),1,5000);
          RAISE parameter_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_common_data
   * Description      : ���ʃf�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_common_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common_data'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �N���[�Y���t�擾         ***
    -- ***************************************
    gd_close_date := TRUNC(SYSDATE);
--
    -- ***************************************
    -- ***       WHO�J�����l�擾           ***
    -- ***************************************
    -- �X�V�p���Y�o�b�`�w�b�_���R�[�h�ɃZ�b�g����
    gr_gme_batch_header.last_updated_by   := fnd_global.user_id;    -- �ŏI�X�V��
    gr_gme_batch_header.last_update_date  := SYSDATE;               -- �ŏI�X�V��
    gr_gme_batch_header.last_update_login := fnd_global.login_id;   -- �ŏI�X�V���O�C��
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_common_data;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N�擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    -- �e�[�u����
    cv_gme_batch_header     VARCHAR2(20):= '���Y�o�b�`�w�b�_';  -- �e�[�u�����F���Y�o�b�`�w�b�_
--
    -- *** ���[�J���ϐ� ***
    lt_batch_id   gme_batch_header.batch_id%TYPE;  -- �o�b�`ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***           ���b�N�擾            ***
    -- ***************************************
--
    -- ���b�N�擾
    SELECT gbh.batch_id      batch_id   -- �o�b�`ID
    INTO   lt_batch_id                  -- �o�b�`ID batch_id
    FROM   gme_batch_header  gbh        -- ���Y�o�b�`�w�b�_
    WHERE  gbh.batch_id = gr_gme_batch_header.batch_id   -- �o�b�`ID
    FOR UPDATE NOWAIT
    ;
--
  EXCEPTION
    WHEN lock_expt THEN                   --*** ���b�N�擾��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10004      -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
                     ,gv_tkn_table           -- �g�[�N��TABLE
                     ,cv_gme_batch_header    -- �e�[�u�����F���Y�o�b�`�w�b�_
                    ),1,5000);
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;          -- �x��                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   :  certify_batch
   * Description      :  ���Y��������(A-5)
   ***********************************************************************************/
  PROCEDURE certify_batch_api(
    it_batch_no   IN  gme_batch_header.batch_no%TYPE,  -- 1.�o�b�`NO
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'certify_batch_api'; -- �v���O������
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
    cv_api_name   CONSTANT VARCHAR2(100) := '���Y�o�b�`�w�b�_����';
--
    -- *** ���[�J���ϐ� ***
    ln_message_count     NUMBER;         -- ���b�Z�[�W�J�E���g
    lv_message_list      VARCHAR2(200);  -- ���b�Z�[�W���X�g
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_gme_batch_header_temp  gme_batch_header%ROWTYPE;              -- ���Y��������API���s�߂�l�i�[
    lr_unallocated_materials  GME_API_PUB.UNALLOCATED_MATERIALS_TAB; -- ���Y��������API���s�߂�l�i�[
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **********************************************
    -- ***    ���Y�o�b�`�w�b�_ ���ъJ�n���X�V     ***
    -- **********************************************
    -- ���ъJ�n�� <> ���Y���̏ꍇ�A���ъJ�n���𐶎Y���ōX�V
    BEGIN
      UPDATE  gme_batch_header  -- ���Y�o�b�`�w�b�_
      SET     actual_start_date =   gr_gme_batch_header.actual_cmplt_date -- ���ъJ�n��
            , last_updated_by   =   gr_gme_batch_header.last_updated_by   -- �ŏI�X�V��
            , last_update_date  =   gr_gme_batch_header.last_update_date  -- �ŏI�X�V��
            , last_update_login =   gr_gme_batch_header.last_update_login -- �ŏI�X�V���O�C��
      WHERE   batch_id          =   gr_gme_batch_header.batch_id            -- �����F�o�b�`ID
      AND     actual_start_date <>  gr_gme_batch_header.actual_cmplt_date;  -- �����F���ъJ�n��<>���Y��
    END;
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ***************************************
    -- ***    ���Y�o�b�`�w�b�_�������s     ***
    -- ***************************************
    GME_API_PUB.CERTIFY_BATCH (
      p_api_version           => GME_API_PUB.API_VERSION   -- IN �Fp_api_version
     ,p_validation_level      => GME_API_PUB.MAX_ERRORS    -- IN �Fp_validation_level
     ,p_init_msg_list         => FALSE                     -- IN �Fp_init_msg_list
     ,p_commit                => FALSE                     -- IN �Fp_commit
     ,x_message_count         => ln_message_count          -- OUT�Fx_message_count
     ,x_message_list          => lv_message_list           -- OUT�Fx_message_list
     ,x_return_status         => lv_retcode                -- OUT�Fx_return_status
     ,p_del_incomplete_manual => TRUE                      -- IN �Fp_del_incomplete_manual
     ,p_ignore_shortages      => FALSE                     -- IN �Fp_ignore_shortages
     ,p_batch_header          => gr_gme_batch_header       -- IN �Fp_batch_header  �X�V����l���Z�b�g�������R�[�h
     ,x_batch_header          => lr_gme_batch_header_temp  -- OUT�Fx_batch_header
     ,x_unallocated_material  => lr_unallocated_materials  -- OUT�Fx_unallocated_material
    );
--
    -- ����I���ȊO�̏ꍇ�A�x��
    IF (lv_retcode <> gv_api_s) THEN
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API���F���Y�o�b�`�w�b�_����
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || it_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END certify_batch_api;
--
  /**********************************************************************************
   * Procedure Name   :  close_batch_api
   * Description      :  ���Y�N���[�Y����(A-6)
   ***********************************************************************************/
  PROCEDURE close_batch_api(
    it_batch_no   IN  gme_batch_header.batch_no%TYPE,  -- 1.�o�b�`NO
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_batch_api'; -- �v���O������
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
    cv_api_name   CONSTANT VARCHAR2(100) := '���Y�N���[�Y';
--
    -- *** ���[�J���ϐ� ***
    ln_message_count     NUMBER;         -- ���b�Z�[�W�J�E���g
    lv_message_list      VARCHAR2(200);  -- ���b�Z�[�W���X�g
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_gme_batch_header_temp  gme_batch_header%ROWTYPE;              -- ���Y��������API���s�߂�l�i�[
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�Z�[�W������API
    FND_MSG_PUB.INITIALIZE();
--
    -- ***************************************
    -- ***        �Ɩ��X�e�[�^�X�X�V       ***
    -- ***************************************
    UPDATE gme_batch_header  gbh    -- ���Y�o�b�`�w�b�_
       SET gbh.attribute4        = gt_duty_status_cls                    -- �Ɩ��X�e�[�^�X
          ,gbh.last_updated_by   = gr_gme_batch_header.last_updated_by   -- �ŏI�X�V��
          ,gbh.last_update_date  = gr_gme_batch_header.last_update_date  -- �ŏI�X�V��
          ,gbh.last_update_login = gr_gme_batch_header.last_update_login -- �ŏI�X�V���O�C��
     WHERE gbh.batch_id          = gr_gme_batch_header.batch_id          -- �o�b�`ID
    ;
--
    -- ***************************************
    -- ***        ���Y�N���[�Y���s         ***
    -- ***************************************
    GME_API_PUB.CLOSE_BATCH (
      p_api_version           => GME_API_PUB.API_VERSION   -- IN �Fp_api_version
     ,p_validation_level      => GME_API_PUB.MAX_ERRORS    -- IN �Fp_validation_level
     ,p_init_msg_list         => FALSE                     -- IN �Fp_init_msg_list
     ,p_commit                => FALSE                     -- IN �Fp_commit
     ,x_message_count         => ln_message_count          -- OUT�Fx_message_count
     ,x_message_list          => lv_message_list           -- OUT�Fx_message_list
     ,x_return_status         => lv_retcode                -- OUT�Fx_return_status
     ,p_batch_header          => gr_gme_batch_header       -- IN �Fp_batch_header  �X�V����l���Z�b�g�������R�[�h
     ,x_batch_header          => lr_gme_batch_header_temp  -- OUT�Fx_batch_header
    );
--
    -- ����I���ȊO�̏ꍇ�A�x��
    IF (lv_retcode <> gv_api_s) THEN
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API���F���Y�o�b�`�w�b�_����
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || it_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END close_batch_api;
--
  /**********************************************************************************
   * Procedure Name   :  save_batch_api
   * Description      :  ���Y�Z�[�u����(A-7)
   ***********************************************************************************/
  PROCEDURE save_batch_api(
    it_batch_no   IN  gme_batch_header.batch_no%TYPE,  -- 1.�o�b�`NO
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'save_batch_api'; -- �v���O������
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
    cv_api_name   CONSTANT VARCHAR2(100) := '���Y�o�b�`�Z�[�u';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
      -- ���b�Z�[�W������API
      FND_MSG_PUB.INITIALIZE();
--
    -- ***************************************
    -- ***       ���Y�o�b�`�Z�[�u���s      ***
    -- ***************************************
    GME_API_PUB.SAVE_BATCH(
      p_batch_header   => gr_gme_batch_header   -- IN �Fp_batch_header  �X�V����l���Z�b�g�������R�[�h
     ,x_return_status  => lv_retcode            -- OUT�Fx_return_status
     ,p_commit         => FALSE                 -- IN �Fp_commit
    );
--
    -- ����I���ȊO�̏ꍇ�A�x��
    IF (lv_retcode <> gv_api_s) THEN
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API��O ***
    WHEN api_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                     ,gv_msg_xxwip10049       -- ���b�Z�[�W�FAPP-XXWIP-10049 API�G���[���b�Z�[�W
                     ,gv_tkn_api_name         -- �g�[�N���FAPI_NAME
                     ,cv_api_name             -- API���F���Y�o�b�`�w�b�_����
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# �C�� #
      -- API���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || it_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
       ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
       ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
      );
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END save_batch_api;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_product_date_from IN  VARCHAR2,      -- 1.���Y���iFROM�j
    iv_product_date_to   IN  VARCHAR2,      -- 2.���Y���iTO�j
    iv_plant_code        IN  VARCHAR2,      -- 3.�v�����g�R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
--
    lv_product_date_from VARCHAR2(100);  -- IN�p�����[�^.���Y���iFROM�j�i�[�p
    lv_product_date_to   VARCHAR2(100);  -- IN�p�����[�^.���Y���iTO�j�i�[�p
    lv_plant_code        VARCHAR2(100);  -- IN�p�����[�^.�v�����g�i�[�p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���Y�o�b�`�w�b�_�J�[�\��
    CURSOR gme_batch_header_cur
    IS
      SELECT gbh.batch_no                          batch_no          -- �o�b�`No
            ,gbh.batch_id                          batch_id          -- �o�b�`ID
            ,FND_DATE.STRING_TO_DATE(gmd.attribute11,'YYYY/MM/DD')
                                                   product_date      -- ���Y��
            ,gbh.batch_status                      batch_status      -- �o�b�`�X�e�[�^�X
      FROM   gme_batch_header                      gbh               -- ���Y�o�b�`�w�b�_
            ,gme_material_details                  gmd               -- ���Y�����ڍ�
      WHERE  gbh.batch_id     = gmd.batch_id           -- �o�b�`ID�i���������j
      AND    gmd.line_type    = gt_line_type_goods     -- ���C���^�C�v   = 1�i�����i�j
      AND    gbh.attribute4   = gt_duty_status_com     -- �Ɩ��X�e�[�^�X = 7�i�����j
      AND  ((lv_product_date_from IS NULL)             -- ���Y���iFROM�j�ɓ��͂��Ȃ��ꍇ�A���Y���iFROM�j�������Ƃ��Ȃ�
        OR  (gmd.attribute11 >= lv_product_date_from)) -- ���Y���iFROM�j�ɓ��͂�����ꍇ�A���Y���iFROM�j�������ɉ�����
      AND    gmd.attribute11 <= lv_product_date_to     -- ���Y���iTO�j
      AND  ((lv_plant_code IS NULL)                    -- �v�����g�R�[�h�ɓ��͂��Ȃ��ꍇ�A�v�����g�R�[�h�������Ƃ��Ȃ�
        OR  (gbh.plant_code   = iv_plant_code))        -- �v�����g�R�[�h�ɓ��͂�����ꍇ�A�v�����g�R�[�h�������ɉ�����
    ;
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
    -- ===============================
    -- A-1.�p�����[�^�`�F�b�N����
    -- ===============================
    -- IN�p�����[�^�i�[
    lv_product_date_from := iv_product_date_from;
    lv_product_date_to   := iv_product_date_to;
    lv_plant_code        := iv_plant_code;
--
    parameter_check(
      iv_plant_code         => lv_plant_code         -- IN    �F1.�v�����g�R�[�h
     ,iov_product_date_from => lv_product_date_from  -- IN OUT�F2.���Y���iFROM�j
     ,iov_product_date_to   => lv_product_date_to    -- IN OUT�F3.���Y���iTO�j
     ,ov_errbuf             => lv_errbuf             -- OUT   �F�G���[�E���b�Z�[�W
     ,ov_retcode            => lv_retcode            -- OUT   �F���^�[���E�R�[�h
     ,ov_errmsg             => lv_errmsg             -- OUT   �F���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.���ʃf�[�^�擾����
    -- ===============================
    get_common_data(
      ov_errbuf     => lv_errbuf     --   OUT�F�G���[�E���b�Z�[�W
     ,ov_retcode    => lv_retcode    --   OUT�F���^�[���E�R�[�h
     ,ov_errmsg     => lv_errmsg     --   OUT�F���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.���Y�o�b�`�w�b�_�擾����
    -- ===============================
    <<gme_batch_header_loop>>
    FOR lr_gme_batch_header IN gme_batch_header_cur LOOP
      -- �X�V�p���Y�o�b�`�w�b�_���R�[�h������
      gr_gme_batch_header.actual_cmplt_date := NULL; -- ���ъ�����
      gr_gme_batch_header.batch_close_date  := NULL; -- �N���[�Y���t
--
      -- �X�V�p���Y�o�b�`�w�b�_���R�[�h�Ƀo�b�`ID���Z�b�g
      gr_gme_batch_header.batch_id   := lr_gme_batch_header.batch_id;    -- �o�b�`ID
--
      BEGIN
        -- ===============================
        -- A-4.���b�N����
        -- ===============================
        get_lock(
          ov_errbuf    => lv_errbuf     -- OUT�F�G���[�E���b�Z�[�W
         ,ov_retcode   => lv_retcode    -- OUT�F���^�[���E�R�[�h
         ,ov_errmsg    => lv_errmsg     -- OUT�F���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          -- �㑱�������X�L�b�v
          RAISE skip_expt;
        END IF;
--
        -- �o�b�`�X�e�[�^�X = �����̏ꍇ�͐��Y�����������s��Ȃ�
        IF (lr_gme_batch_header.batch_status <> gt_batch_status_com) THEN
          -- �X�V�p���Y�o�b�`�w�b�_���R�[�h�ɒl���Z�b�g
          gr_gme_batch_header.actual_cmplt_date := lr_gme_batch_header.product_date; -- ���ъ�����
--
          -- ===============================
          -- A-5.���Y��������
          -- ===============================
          certify_batch_api(
            it_batch_no  => lr_gme_batch_header.batch_no   -- IN �F1.�o�b�`No
           ,ov_errbuf    => lv_errbuf    -- OUT�F�G���[�E���b�Z�[�W
           ,ov_retcode   => lv_retcode   -- OUT�F���^�[���E�R�[�h
           ,ov_errmsg    => lv_errmsg    -- OUT�F���[�U�[�E�G���[�E���b�Z�[�W
          );
--
          -- �G���[�̏ꍇ
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
--
          -- �x���̏ꍇ
          ELSIF (lv_retcode = gv_status_warn) THEN
            -- �㑱�������X�L�b�v
            RAISE skip_expt;
          END IF;
        END IF;
--
        -- �X�V�p���Y�o�b�`�w�b�_���R�[�h�ɒl���Z�b�g
        gr_gme_batch_header.actual_cmplt_date := NULL; -- ���ъ�����
        gr_gme_batch_header.batch_close_date  := gd_close_date; -- �N���[�Y���t
--
        -- ===============================
        -- A-6.���Y�N���[�Y����
        -- ===============================
        close_batch_api(
          it_batch_no  => lr_gme_batch_header.batch_no   -- IN �F1.�o�b�`No
         ,ov_errbuf    => lv_errbuf    -- OUT�F�G���[�E���b�Z�[�W
         ,ov_retcode   => lv_retcode   -- OUT�F���^�[���E�R�[�h
         ,ov_errmsg    => lv_errmsg    -- OUT�F���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          -- �㑱�������X�L�b�v
          RAISE skip_expt;
        END IF;
--
        -- ===============================
        -- A-7.���Y�Z�[�u����
        -- ===============================
        save_batch_api(
          it_batch_no  => lr_gme_batch_header.batch_no   -- IN �F1.�o�b�`No
         ,ov_errbuf    => lv_errbuf    -- OUT�F�G���[�E���b�Z�[�W
         ,ov_retcode   => lv_retcode   -- OUT�F���^�[���E�R�[�h
         ,ov_errmsg    => lv_errmsg    -- OUT�F���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          -- �㑱�������X�L�b�v
          RAISE skip_expt;
--
        -- ����̏ꍇ
        ELSE
          -- �����J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
          -- COMMIT
          COMMIT;
        END IF;
--
      EXCEPTION
        WHEN skip_expt THEN        --*** �X�L�b�v ***
          -- �x���J�E���g
          gn_warn_cnt := gn_warn_cnt + 1;
          -- �x�����b�Z�[�W�o��
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
          ov_retcode := gv_status_warn;
          -- ROLLBACK
          ROLLBACK;
      END;
--
    END LOOP gme_batch_header_loop;
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
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf               OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode              OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_product_date_from IN  VARCHAR2,      -- 1.���Y���iFROM�j
    iv_product_date_to   IN  VARCHAR2,      -- 2.���Y���iTO�j
    iv_plant_code        IN  VARCHAR2)      -- 3.�v�����g�R�[�h

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
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_product_date_from,  -- 1.���Y���iFROM�j
      iv_product_date_to,    -- 2.���Y���iTO�j
      iv_plant_code,         -- 3.�v�����g�R�[�h
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- A-8.���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
END xxwip210001c;
/
