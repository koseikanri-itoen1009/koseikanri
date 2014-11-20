CREATE OR REPLACE PACKAGE BODY XXWSH400012C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2009. All rights reserved.
 *
 * Package Name     : XXWSH400001C(spec)
 * Description      : ����v�悩��̃��[�t�o�׈˗������쐬�N������
 * MD.050/070       : �o�׈˗�                                      (T_MD050_BPO_400)
 *                    ����v�悩��̃��[�t�o�׈˗������쐬�N������  (T_MD070_BPO_40M)
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  parameter_check          ���̓p�����[�^�`�F�b�N(M-1)
 *  get_target_sales_branch  �����Ώۋ��_�擾(M-2)
 *  submit_request_40a       �q�R���J�����g�ďo����(M-3)
 *  status_check             �R���J�����g�I���X�e�[�^�X�`�F�b�N(M-4)
 *  submain
 *  main
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/29    1.0   H.Itou           ����쐬
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
  no_target_expt            EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(100) := 'XXWSH400012C';      -- �p�b�P�[�W��
  --���b�Z�[�W�ԍ�
  gv_cons_msg_kbn_wsh       CONSTANT VARCHAR2(100) := 'XXWSH';             -- ���b�Z�[�W�敪XXWSH
  gv_cons_msg_kbn_cmn       CONSTANT VARCHAR2(100) := 'XXCMN';             -- ���b�Z�[�W�敪XXCMN
  gv_msg_xxcmn10135         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';   -- �v���̔��s���s�G���[
  gv_msg_xxwsh11001         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11001';   -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
  gv_msg_xxwsh11002         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11002';   -- �}�X�^�����G���[���b�Z�[�W
  gv_msg_xxwsh11004         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11004';   -- �K�{���͂o���ݒ�G���[���b�Z�[�W
  gv_msg_xxwsh11007         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11007';   -- �Ώ۔N�����b�Z�[�W
  gv_msg_xxwsh11008         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11008';   -- �Ǌ����_���b�Z�[�W
  gv_msg_xxwsh10002         CONSTANT VARCHAR2(100) := 'APP-XXWSH-10002';   -- �Ώۖ���
  --�萔
  gv_msg_normal             CONSTANT VARCHAR2(100) := '����I��';
  gv_msg_warn               CONSTANT VARCHAR2(100) := '�x���I��';
  gv_msg_error              CONSTANT VARCHAR2(100) := '�ُ�I��';
  --�g�[�N��
  gv_tkn_in_parm            CONSTANT VARCHAR2(100) := 'IN_PARAM';
  gv_tkn_yymm               CONSTANT VARCHAR2(100) := 'YYMM';
  gv_tkn_kyoten             CONSTANT VARCHAR2(100) := 'KYOTEN';
  gv_msg_yyyymm             CONSTANT VARCHAR2(100) := '�Ώ۔N��';
  gv_msg_sales_branch       CONSTANT VARCHAR2(100) := '�Ǌ����_';
  gv_msg_request_id         CONSTANT VARCHAR2(100) := '�v��ID';
  gv_msg_conc_result        CONSTANT VARCHAR2(100) := '��������';
--
  -- YES/NO
  gv_yes                    CONSTANT VARCHAR2(100) := 'Y'; -- YES
  gv_no                     CONSTANT VARCHAR2(100) := 'N'; -- NO
  -- �ڋq�敪
  gv_customer_class_code_b  CONSTANT VARCHAR2(100) := '1'; -- ���_
  -- �o�׎����쐬�敪
  gv_order_auto_code_on     CONSTANT VARCHAR2(100) := '1'; -- �����쐬
  -- ���i�敪
  gv_prod_code_leaf         CONSTANT VARCHAR2(100) := '1'; -- ���[�t
  -- �t�H�[�L���X�g���
  gv_h_plan                 CONSTANT VARCHAR2(100) := '01'; -- ����v��
--
  -- �R���J�����g�I���X�e�[�^�X
  gv_conc_p_c               CONSTANT VARCHAR2(100) := 'COMPLETE';
  gv_conc_s_w               CONSTANT VARCHAR2(100) := 'WARNING';
  gv_conc_s_e               CONSTANT VARCHAR2(100) := 'ERROR';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -------------------------------
  -- ���R�[�h�^�錾
  -------------------------------
  TYPE param_data_rec IS RECORD   -- ���͂o�i�[�p���R�[�h�^
    (
     yyyymm        VARCHAR2(6)    -- �Ώ۔N��
   , base          VARCHAR2(4)    -- �Ǌ����_
    );
--
  TYPE data_cnt_rec   IS RECORD   -- �������ʊi�[���R�[�h�^
    (
      error_cnt    NUMBER         -- ���̓��̃G���[����
    , warn_cnt     NUMBER         -- ���̓��̌x������
    , nomal_cnt    NUMBER         -- ���̓��̐��팏��
    , sales_branch mrp_forecast_designators.attribute3%TYPE  -- ���_
    );
--
  -------------------------------
  -- �e�[�u���^�錾
  -------------------------------
  TYPE sales_branch_tbl IS TABLE OF mrp_forecast_designators.attribute3%TYPE INDEX BY BINARY_INTEGER; -- �����Ώۋ��_         �e�[�u���^
  TYPE data_cnt_tbl     IS TABLE OF data_cnt_rec                             INDEX BY BINARY_INTEGER; -- �������ʊi�[���R�[�h �e�[�u���^
  TYPE number_tab       IS TABLE OF NUMBER                                   INDEX BY BINARY_INTEGER; -- NUMBER               �e�[�u���^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate           DATE;              -- �V�X�e�����ݓ��t
  gd_yyyymm            DATE;              -- �Ώ۔N��
--
  gr_param             param_data_rec;    -- ���̓p�����[�^���R�[�h
  gr_sales_branch_tbl  sales_branch_tbl;  -- �����Ώۋ��_�i�[�e�[�u��
  gr_data_cnt_tbl      data_cnt_tbl;      -- �������ʊi�[���R�[�h�e�[�u��
  gr_request_id_tbl    number_tab;        -- �v��ID�e�[�u��
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : ���̓p�����[�^�`�F�b�N(M-1)
   ***********************************************************************************/
  PROCEDURE parameter_check
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
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
    -- *** ���[�J���ϐ� ***
    ln_cnt    NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���͂o�u�Ώ۔N���v�̎擾
    ------------------------------------------
    -- �擾�G���[��
    IF (gr_param.yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_wsh    -- 'XXWSH'
                                                     ,gv_msg_xxwsh11004      -- �K�{���͂o���ݒ�G���[
                                                     ,gv_tkn_in_parm         -- �g�[�N��
                                                     ,gv_msg_yyyymm          -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���͂o�u�Ώ۔N���v�̏����ϊ�(YYYYMM)
    gd_yyyymm := FND_DATE.STRING_TO_DATE(gr_param.yyyymm,'YYYYMM');
    -- �ϊ��G���[��
    IF (gd_yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_wsh    -- 'XXWSH'
                                                     ,gv_msg_xxwsh11002      -- �}�X�^�����G���[
                                                     ,gv_tkn_yymm            -- �g�[�N��
                                                     ,gr_param.yyyymm        -- ���͂o[�Ώ۔N��]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- ���͂o�u�Ǌ����_�v�̎擾
    ------------------------------------------
    -- ���͂o�u�Ǌ����_�v�����͂���Ă�����
    IF (gr_param.base IS NOT NULL) THEN
--
      ------------------------------------------------------------------------
      -- �ڋq�}�X�^�E�p�[�e�B�}�X�^�ɋ��_���o�^����Ă��邩�ǂ����̔���
      ------------------------------------------------------------------------
      SELECT COUNT(account_number)
      INTO   ln_cnt
      FROM   xxcmn_parties_v                                 -- �p�[�e�B��� V
      WHERE  account_number      = gr_param.base             -- ���͂o[�Ǌ����_]
      AND    customer_class_code = gv_customer_class_code_b  -- '���_'�������u�R�[�h�敪�v
      AND    ROWNUM              = 1;
--
      -- ���͂o[�Ǌ����_]���ڋq�}�X�^�ɑ��݂��Ȃ��ꍇ
      IF (ln_cnt = 0) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                       ,gv_msg_xxwsh11001    -- �}�X�^�����G���[
                                                       ,gv_tkn_kyoten        -- �g�[�N��
                                                       ,gr_param.base        -- ���͂o[�Ǌ����_]
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_target_sales_branch
   * Description      : �����Ώۋ��_�擾(M-2)
   ***********************************************************************************/
  PROCEDURE get_target_sales_branch
    (
      ov_errbuf     OUT VARCHAR2                  --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_sales_branch'; -- �v���O������
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR cur_sales_branch
    IS
      SELECT mfds.attribute3                AS sales_branch        -- ���_
      FROM  mrp_forecast_designators  mfds   -- �t�H�[�L���X�g��        T
           ,mrp_forecast_dates        mfd    -- �t�H�[�L���X�g���t      T
           ,xxcmn_cust_accounts_v     xcav   -- �ڋq���                V
           ,xxcmn_cust_acct_sites_v   xcasv  -- �ڋq�T�C�g���          V
           ,xxcmn_item_categories5_v  xicv   -- OPM�i�ڃJ�e�S��������� V
           ,xxcmn_item_mst2_v         ximv   -- OPM�i�ڏ��             V
      WHERE mfds.attribute1                     = gv_h_plan                -- ����v�� '01'
      AND   mfds.forecast_designator            = mfd.forecast_designator  -- �t�H�[�L���X�g��
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gr_param.yyyymm          -- ���͂o[�Ώ۔N��]
      AND   mfd.organization_id                 = mfds.organization_id     -- �g�DID
      AND   ximv.inventory_item_id              = mfd.inventory_item_id    -- �i��ID
      AND   xcav.account_number                 = mfds.attribute3          -- ���_
      AND   xcav.customer_class_code            = gv_customer_class_code_b -- �ڋq�敪 '1'
      AND   xcav.order_auto_code                = gv_order_auto_code_on    -- �o�׈˗������쐬�敪 '1'
      AND   xcav.cust_account_id                = xcasv.cust_account_id    -- �ڋqID
      AND   xcasv.primary_flag                  = gv_yes                   -- ��t���O 'Y'
      AND   xcav.party_id                       = xcasv.party_id           -- �p�[�e�BID
      AND   xicv.item_id                        = ximv.item_id             -- �i��ID
      AND   xicv.prod_class_code                = gv_prod_code_leaf        -- '���[�t'
      AND   ximv.start_date_active             <= gd_sysdate
      AND   ximv.end_date_active               >= gd_sysdate
      GROUP BY mfds.attribute3             -- ���_
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
    -- �Ǌ����_�Ɏw�肪�Ȃ��ꍇ
    IF (gr_param.base IS NULL) THEN
      -- �J�[�\���I�[�v��
      OPEN cur_sales_branch;
      -- �o���N�t�F�b�`
      FETCH cur_sales_branch BULK COLLECT INTO gr_sales_branch_tbl;
      -- �J�[�\���N���[�Y
      CLOSE cur_sales_branch;
--
    -- �Ǌ����_�Ɏw�肪����ꍇ
    ELSE
      gr_sales_branch_tbl(1) := gr_param.base;
    END IF;
--
    -- ���������擾
    gn_target_cnt := gr_sales_branch_tbl.COUNT;
--
    -- �Ώۃf�[�^���Ȃ��ꍇ
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh
                                          , gv_msg_xxwsh10002);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_sales_branch%ISOPEN) THEN
        CLOSE cur_sales_branch;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_sales_branch%ISOPEN) THEN
        CLOSE cur_sales_branch;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_sales_branch%ISOPEN) THEN
        CLOSE cur_sales_branch;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_target_sales_branch;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_40a
   * Description      : �q�R���J�����g�ďo����(M-3)
   ***********************************************************************************/
  PROCEDURE submit_request_40a
    (
      ov_errbuf     OUT VARCHAR2                  --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_40a'; -- �v���O������
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
    -- ====================================
    -- �擾�������_�̐������R���J�����g���s
    -- ====================================
    <<target_loop>>
    FOR ln_cnt IN 1..gr_sales_branch_tbl.COUNT LOOP
      gr_request_id_tbl(ln_cnt) := FND_REQUEST.SUBMIT_REQUEST(
                                     APPLICATION  => 'XXWSH'                     -- �A�v���P�[�V�����Z�k��
                                   , PROGRAM      => 'XXWSH400001C'              -- �v���O������
                                   , ARGUMENT1    => gr_param.yyyymm             -- �Ώ۔N��
                                   , ARGUMENT2    => gr_sales_branch_tbl(ln_cnt) -- �������
                                   );
--
      -- �v��ID���擾�ł��Ȃ������ꍇ
      IF ( gr_request_id_tbl(ln_cnt) = 0 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application   => gv_cons_msg_kbn_cmn
                      ,iv_name          => gv_msg_xxcmn10135);
        RAISE global_api_expt;
--
      -- ����I���̏ꍇ
      ELSE
        COMMIT;
      END IF;
--
    END LOOP target_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submit_request_40a;
--
  /**********************************************************************************
   * Procedure Name   : status_check
   * Description      : �R���J�����g�I���X�e�[�^�X�`�F�b�N(M-4)
   ***********************************************************************************/
  PROCEDURE status_check
    (
      ov_errbuf     OUT VARCHAR2                  --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_check'; -- �v���O������
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
    lv_phase         VARCHAR2(100);
    lv_status        VARCHAR2(100);
    lv_dev_phase     VARCHAR2(100);
    lv_dev_status    VARCHAR2(100);
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
    <<status_check_loop>>
    FOR ln_cnt IN 1 .. gr_request_id_tbl.COUNT LOOP
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
             REQUEST_ID => gr_request_id_tbl(ln_cnt)
            ,INTERVAL   => 1
            ,MAX_WAIT   => 0
            ,PHASE      => lv_phase
            ,STATUS     => lv_status
            ,DEV_PHASE  => lv_dev_phase
            ,DEV_STATUS => lv_dev_status
            ,MESSAGE    => lv_errbuf
            ) ) THEN
        -- �X�e�[�^�X���f
        -- �t�F�[�Y:����
        IF ( lv_dev_phase = gv_conc_p_c ) THEN
          -- �X�e�[�^�X:�ُ�
          IF ( lv_dev_status = gv_conc_s_e ) THEN
            lv_errmsg  :=               gv_msg_yyyymm       || gv_msg_part || gr_param.yyyymm             -- �Ώ۔N��
                       || gv_msg_pnt || gv_msg_sales_branch || gv_msg_part || gr_sales_branch_tbl(ln_cnt) -- �Ǌ����_
                       || gv_msg_pnt || gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- �v��ID
                       || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_error                -- ��������
                       ;
            gn_error_cnt := gn_error_cnt + 1;
--
          -- �X�e�[�^�X:�x��
          ELSIF ( lv_dev_status = gv_conc_s_w ) THEN
            lv_errmsg  :=               gv_msg_yyyymm       || gv_msg_part || gr_param.yyyymm             -- �Ώ۔N��
                       || gv_msg_pnt || gv_msg_sales_branch || gv_msg_part || gr_sales_branch_tbl(ln_cnt) -- �Ǌ����_
                       || gv_msg_pnt || gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- �v��ID
                       || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_warn                 -- ��������
                       ;
            gn_warn_cnt := gn_warn_cnt + 1;
--
          -- �X�e�[�^�X:����
          ELSE
            lv_errmsg  :=               gv_msg_yyyymm       || gv_msg_part || gr_param.yyyymm             -- �Ώ۔N��
                       || gv_msg_pnt || gv_msg_sales_branch || gv_msg_part || gr_sales_branch_tbl(ln_cnt) -- �Ǌ����_
                       || gv_msg_pnt || gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- �v��ID
                       || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_normal               -- ��������
                       ;
            gn_normal_cnt := gn_normal_cnt + 1;
          END IF;
        END IF;
--
      ELSE
        lv_errmsg  :=               gv_msg_request_id   || gv_msg_part || gr_request_id_tbl(ln_cnt)   -- �v��ID
                   || gv_msg_pnt || gv_msg_conc_result  || gv_msg_part || gv_msg_error                -- ��������
                   ;
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    END LOOP status_check_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END status_check;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_yyyymm   IN   VARCHAR2     --  01.�Ώ۔N��
     ,iv_base     IN   VARCHAR2     --  02.�Ǌ����_
     ,ov_errbuf   OUT  VARCHAR2     --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  OUT  VARCHAR2     --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   OUT  VARCHAR2     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     )
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
    cv_param_1    CONSTANT VARCHAR2(100) := '1';
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt      NUMBER := 0;      -- ���[�v�J�E���g
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;   -- �Ώی���
    gn_normal_cnt := 0;   -- ���팏��
    gn_warn_cnt   := 0;   -- �x������
    gn_error_cnt  := 0;   -- �G���[����
--
    -- ===============================================
    -- �p�����[�^�i�[
    -- ===============================================
    gr_param.yyyymm  := iv_yyyymm;    -- �Ώ۔N��
    gr_param.base    := iv_base;      -- �Ǌ����_
--
    gd_sysdate       := TRUNC( SYSDATE );
--
    -- ===============================================
    -- ���̓p�����[�^�o��
    -- ===============================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ���̓p�����[�^�u�Ώ۔N���v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh
                                         , gv_msg_xxwsh11007
                                         , gv_tkn_yymm
                                         , gr_param.yyyymm);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�Ǌ����_�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh
                                         , gv_msg_xxwsh11008
                                         , gv_tkn_kyoten
                                         , gr_param.base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- =====================================================
    --  ���̓p�����[�^�`�F�b�N(M-1)
    -- =====================================================
    parameter_check
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �����Ώۋ��_�擾(M-2)
    -- =====================================================
    get_target_sales_branch
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    -- �ُ�I���̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE no_target_expt;
    END IF;
--
    -- =====================================================
    --  �q�R���J�����g�ďo����(M-3)
    -- =====================================================
    submit_request_40a
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �R���J�����g�I���X�e�[�^�X�`�F�b�N(M-4)
    -- =====================================================
    status_check
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �q�R���J�����g���s�ŃG���[�I��������ꍇ
    IF (gn_error_cnt <> 0) THEN
      ov_retcode := gv_status_error;
--
    -- �q�R���J�����g���s�Ōx���I��������ꍇ
    ELSIF (gn_warn_cnt <> 0) THEN
      ov_retcode := gv_status_warn;
--
    -- �q�R���J�����g���s�����ׂĐ���I���̏ꍇ
    ELSE
      ov_retcode := gv_status_normal;
    END IF;
--
  EXCEPTION
    WHEN no_target_expt THEN -- �Ώۃf�[�^�Ȃ�
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := gv_status_warn;
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
    errbuf     OUT    VARCHAR2     --  �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode    OUT    VARCHAR2     --  ���^�[���E�R�[�h    --# �Œ� #
   ,iv_yyyymm  IN     VARCHAR2     --  01.�Ώ۔N��
   ,iv_base    IN     VARCHAR2     --  02.�Ǌ����_
  )
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
    ln_deliver_from_id   NUMBER; -- �o�Ɍ�
    ln_deliver_type      NUMBER; -- �o�Ɍ`��
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain
      (
        iv_yyyymm   => iv_yyyymm   -- 01.�Ώ۔N��
       ,iv_base     => iv_base     -- 02.�Ǌ����_
       ,ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      IF ( lv_errmsg IS NULL ) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00008', 'CNT', TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00009', 'CNT', TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00010', 'CNT', TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    --gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn, 'APP-XXCMN-00011', 'CNT', TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�x�������F ' || TO_CHAR(gn_warn_cnt) || ' ��');
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn,'APP-XXCMN-00012','STATUS',gv_conc_status);
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
END XXWSH400012C;
/
