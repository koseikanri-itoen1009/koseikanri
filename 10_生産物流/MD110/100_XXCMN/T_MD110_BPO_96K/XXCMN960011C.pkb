CREATE OR REPLACE PACKAGE BODY XXCMN960011C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960011C(body)
 * Description      : OPM�莝�݌Ƀp�[�W
 * MD.050           : T_MD050_BPO_96K_OPM�莝�݌Ƀp�[�W
 * Version          : 1.00
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
 *  2012/12/06   1.00  T.Makuta          �V�K�쐬
 *  2013/01/31   1.1   N.Miyamoto        ��Q�Ǘ��[IT_0014�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal     CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn       CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error      CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  cv_date_format       CONSTANT VARCHAR2(6)  := 'YYYYMM';
  cv_purge_type        CONSTANT VARCHAR2(1)  := '0';                      --�߰������(0:�p�[�W����)
  cv_purge_code        CONSTANT VARCHAR2(10) := '9701';                   --�߰�ޒ�`����
  cv_app_name          CONSTANT VARCHAR2(10) := 'GMI';
  cv_app_name_xxcmn    CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_gmipebal          CONSTANT VARCHAR2(10) := 'GMIPEBAL';
  cv_description       CONSTANT VARCHAR2(50) := '��c���̃p�[�W';
--
  --=============
  --���b�Z�[�W
  --=============
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part          CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont          CONSTANT VARCHAR2(3)  := '.';
  cv_msg_slash         CONSTANT VARCHAR2(3)  := '/';
  cv_conc_p_c          CONSTANT VARCHAR2(20) := 'COMPLETE';
  cv_conc_s_n          CONSTANT VARCHAR2(20) := 'NORMAL';
  cv_conc_s_w          CONSTANT VARCHAR2(20) := 'WARNING';
  cv_conc_s_e          CONSTANT VARCHAR2(20) := 'ERROR';
  cv_conc_s_c          CONSTANT VARCHAR2(20) := 'CANCELLED';
  cv_conc_s_t          CONSTANT VARCHAR2(20) := 'TERMINATED';
--
  --XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��
  cv_xxcmn_commit_range     
                       CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_normal_cnt_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';        --���팏�����b�Z�[�W
  cv_error_rec_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';        --�G���[�������b�Z�[�W
--
  cv_proc_date_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-11043';        --�����N���o��
  cv_nengetu_token     CONSTANT VARCHAR2(10) := 'NENGETU';                --�����N��MSG�pİ�ݖ�
--
  cv_get_profile_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';        --���̧�ْl�擾���s
  cv_token_profile     CONSTANT VARCHAR2(50) := 'NG_PROFILE';             --���̧�َ擾MSG�pİ�ݖ�
--
  cv_get_priod_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-11011';        --�p�[�W���Ԏ擾���s
--
  cv_conc_err          CONSTANT VARCHAR2(50) := 'APP-XXCMN-10135';        --�v���̔��s���s�G���[
--
  cv_request_err_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11020';
  cv_request_err_token CONSTANT VARCHAR2(10) := 'REQUEST';
--
  --TBL_NAME SHORI �����F CNT ��
  cv_end_msg1          CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';        --�������e�o��
  cv_token_tblname     CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname           CONSTANT VARCHAR2(90) := 'OPM�莝�݌Ƀg�����U�N�V�����i�W���j';
  cv_token_shori_p     CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori_p           CONSTANT VARCHAR2(50) := '�폜';
  cv_cnt_token         CONSTANT VARCHAR2(10) := 'CNT';
--
  --��c���̃p�[�W(���N�G�X�gID)�F REQUEST_ID
  cv_end_msg2          CONSTANT VARCHAR2(50) := 'APP-XXCMN-11042';        --�������e�o��
  cv_req_id            CONSTANT VARCHAR2(10) := 'REQUEST_ID';
--
  --SHORI �����Ɏ��s���܂����B�y KINOUMEI �z KEYNAME1 �F KEY1 , KEYNAME2 �F KEY2 , 
  --                                         KEYNAME3 �F KEY3 , KEYNAME4 �F KEY4
  cv_others_err_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11041';
  cv_token_shori       CONSTANT VARCHAR2(10) := 'SHORI';
  cv_token_kinou       CONSTANT VARCHAR2(10) := 'KINOUMEI';
  cv_token_key_name1   CONSTANT VARCHAR2(10) := 'KEYNAME1';
  cv_token_key_name2   CONSTANT VARCHAR2(10) := 'KEYNAME2';
  cv_token_key_name3   CONSTANT VARCHAR2(10) := 'KEYNAME3';
  cv_token_key_name4   CONSTANT VARCHAR2(10) := 'KEYNAME4';
  cv_token_key1        CONSTANT VARCHAR2(10) := 'KEY1';
  cv_token_key2        CONSTANT VARCHAR2(10) := 'KEY2';
  cv_token_key3        CONSTANT VARCHAR2(10) := 'KEY3';
  cv_token_key4        CONSTANT VARCHAR2(10) := 'KEY4';
  cv_shori             CONSTANT VARCHAR2(50) := '�p�[�W';
  cv_kinou             CONSTANT VARCHAR2(90) := 'OPM�莝�݌Ƀp�[�W';
  cv_key_name1         CONSTANT VARCHAR2(50) := '�i��ID';
  cv_key_name2         CONSTANT VARCHAR2(50) := '�q�ɃR�[�h';
  cv_key_name3         CONSTANT VARCHAR2(50) := '���b�gID';
  cv_key_name4         CONSTANT VARCHAR2(50) := '�ۊǏꏊ';
--
  --API_NAME API�ŃG���[���������܂����B
  cv_api_err_msg       CONSTANT VARCHAR2(50) := 'APP-XXCMN-10018';
  cv_token_api         CONSTANT VARCHAR2(10) := 'API_NAME';
  cv_api_name          CONSTANT VARCHAR2(50) := 'GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV';

--
  cv_tbl_name          CONSTANT VARCHAR2(50) := 'XXCMN.XXCMN_IC_LOCT_INV_ARC';
  cv_0                 CONSTANT VARCHAR2(1)  :=  '0';
  cv_9                 CONSTANT VARCHAR2(1)  :=  '9';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg           VARCHAR2(2000);
  gv_sep_msg           VARCHAR2(2000);
  gv_exec_user         VARCHAR2(100);
  gv_conc_name         VARCHAR2(30);
  gv_conc_status       VARCHAR2(30);
  gn_normal_cnt        NUMBER;                                            --���팏��
  gn_error_cnt         NUMBER;                                            --�G���[����
  gn_del_cnt           NUMBER;                                            --�폜����
  gn_purge_cnt         NUMBER;                                            --��c���̃p�[�W��������
  gn_restore_cnt       NUMBER;                                            --���X�g�A����
  gn_rst_cnt_all       NUMBER;                                            --���X�g�A�S����
--
  gt_shori_ym          xxinv_stc_inventory_month_stck.invent_ym%TYPE;
  gn_request_id        NUMBER;
--
  gt_item_id           ic_loct_inv.item_id%TYPE;                          --�i��ID
  gt_whse_code         ic_loct_inv.whse_code%TYPE;                        --�q�ɃR�[�h
  gt_lot_id            ic_loct_inv.lot_id%TYPE;                           --���b�gID
  gt_location          ic_loct_inv.location%TYPE;                         --�ۊǏꏊ
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
  local_process_expt        EXCEPTION;
  local_api_others_expt     EXCEPTION;
  not_init_collection_expt  EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_init_collection_expt, -6531);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960011C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
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
    ln_purge_period           NUMBER;                           --�p�[�W����
    ln_bkp_cnt                NUMBER;                           --�o�b�N�A�b�v��������
    ln_arc_cnt_yet            NUMBER;                           --���R�~�b�g�o�b�N�A�b�v����
    ln_rst_cnt_yet            NUMBER;                           --���R�~�b�g���X�g�A����
    lv_standard_ym            VARCHAR2(6);                      --�����N��(YYYYMM)
    ln_commit_range           NUMBER;                           --�����R�~�b�g��
    lv_process_part           VARCHAR2(1000);                   --������
    lb_ret_code               BOOLEAN;
    ln_purge_cnt_b            NUMBER;                           --��c���̃p�[�W�i�����O�j����
    ln_purge_cnt_a            NUMBER;                           --��c���̃p�[�W�i������j����
--
    lt_item_id                ic_loct_inv.item_id%TYPE;
    lt_lot_id                 ic_loct_inv.lot_id%TYPE;
    lt_whse_code              ic_loct_inv.whse_code%TYPE;
    lt_location               ic_loct_inv.location%TYPE;
--
    --FND_REQUEST.SUBMIT_REQUEST�Ŏg�p����ϐ�
    lv_phase                  VARCHAR2(100);
    lv_status                 VARCHAR2(100);
    lv_dev_phase              VARCHAR2(100);
    lv_dev_status             VARCHAR2(100);
--
    lv_errbuf_wait            VARCHAR2(5000);
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    CURSOR �p�[�W�Ώ�OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v�擾
    IS
    SELECT 
            OPM�莝�݌Ƀg�����U�N�V����.�S�J����
    FROM    OPM�莝�݌Ƀg�����U�N�V����
    WHERE   OPM�莝�݌Ƀg�����U�N�V����.�莝���� = 0 ;
    */
    CURSOR bkp_data_cur
    IS
      SELECT
        ili.item_id                  AS  item_id,
        ili.whse_code                AS  whse_code,
        ili.lot_id                   AS  lot_id,
        ili.location                 AS  location,
        ili.loct_onhand              AS  loct_onhand,
        ili.loct_onhand2             AS  loct_onhand2,
        ili.lot_status               AS  lot_status,
        ili.qchold_res_code          AS  qchold_res_code,
        ili.delete_mark              AS  delete_mark,
        ili.text_code                AS  text_code,
        ili.last_updated_by          AS  last_updated_by,
        ili.created_by               AS  created_by,
        ili.last_update_date         AS  last_update_date,
        ili.creation_date            AS  creation_date,
        ili.last_update_login        AS  last_update_login,
        ili.program_application_id   AS  program_application_id,
        ili.program_id               AS  program_id,
        ili.program_update_date      AS  program_update_date,
        ili.request_id               AS  request_id
      FROM  ic_loct_inv              ili
      WHERE ili.loct_onhand          =   0;
--
    /*
    CURSOR �p�[�W�Ώ�OPM�莝�݌Ƀg�����U�N�V�������X�g�A�f�[�^�擾
      it_�����N��  IN �I�������݌�(�A�h�I��).�I���N��%TYPE
    IS
    SELECT 
            OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v.��������
            OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v.�S�J����
    FROM    OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v
    WHERE 
      EXISTS
           (-- �I�������݌ɂɎw�肵���ߋ��̃f�[�^�����݂���
            SELECT 'X'
            FROM   �I�������݌�
            WHERE  �I�������݌�.�i��ID    = OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v.�i��ID
            AND    �I�������݌�.���b�gID  = OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v.���b�gID
            AND    �I�������݌�.�q�ɃR�[�h= OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v.�q�ɃR�[�h
            AND    �I�������݌�(�A�h�I��).�I���N�� >= it_�����N��
            AND    ROWNUM = 1
           )
      GROUP BY
        OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v.�S�J����
      ;
    */
    CURSOR rst_data_cur(
      it_shori_ym  xxinv_stc_inventory_month_stck.invent_ym%TYPE
    )
    IS
-- 2013/01/31 v1.1 UPDATE START
--    SELECT
      SELECT  /*+ INDEX(xili XXCMN_IC_LOCT_INV_ARC_N1) */
-- 2009/01/31 v1.1 UPDATE END
        xili.item_id                 AS  item_id,
        xili.whse_code               AS  whse_code,
        xili.lot_id                  AS  lot_id,
        xili.location                AS  location,
        xili.loct_onhand             AS  loct_onhand,
        xili.loct_onhand2            AS  loct_onhand2,
        xili.lot_status              AS  lot_status,
        xili.qchold_res_code         AS  qchold_res_code,
        xili.delete_mark             AS  delete_mark,
        xili.text_code               AS  text_code,
        xili.last_updated_by         AS  last_updated_by,
        xili.created_by              AS  created_by,
        xili.last_update_date        AS  last_update_date,
        xili.creation_date           AS  creation_date,
        xili.last_update_login       AS  last_update_login,
        xili.program_application_id  AS  program_application_id,
        xili.program_id              AS  program_id,
        xili.program_update_date     AS  program_update_date,
        xili.request_id              AS  request_id
      FROM  xxcmn_ic_loct_inv_arc    xili                        --OPM�莝�݌���ݻ޸����ޯ�����
      WHERE EXISTS
-- 2013/01/31 v1.1 UPDATE START
--            (SELECT /*+ INDEX(xsim XXINV_SIMS_N03 ) */
              (SELECT /*+ INDEX(xsim XXINV_SIMS_N01 ) */
-- 2009/01/31 v1.1 UPDATE END
                     'X'
               FROM  xxinv_stc_inventory_month_stck   xsim       --�I�������݌�(��޵�)
               WHERE xsim.item_id       = xili.item_id
               AND   xsim.lot_id        = xili.lot_id
               AND   xsim.whse_code     = xili.whse_code
               AND   xsim.invent_ym    >= it_shori_ym
               AND   ROWNUM = 1
              )
      ;
--
    -- <�J�[�\����>���R�[�h�^
    TYPE lt_loct_inv_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv_tab      lt_loct_inv_ttype;                      --OPM�莝�݌�
--
    TYPE lt_loct_inv2_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv2_tab      lt_loct_inv2_ttype;                    --OPM�莝�݌�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_del_cnt        := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gt_shori_ym       := NULL;
    gn_purge_cnt      := 0;
    gn_restore_cnt    := 0;
    gn_rst_cnt_all    := 0;
    ln_arc_cnt_yet    := 0;
    ln_rst_cnt_yet    := 0;
    ln_bkp_cnt        := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- �p�[�W���Ԏ擾
    -- ===============================================
   /*
    ln_�p�[�W���� := �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐�(cv_�p�[�W�^�C�v,cv_�p�[�W�R�[�h);
     */
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
--
    /*
    ln_�p�[�W���Ԃ�NULL�̏ꍇ
      ov_�G���[���b�Z�[�W := xxcmn_common_pkg.get_msg(
                            iv_�A�v���P�[�V�����Z�k��  => cv_appl_short_name
                           ,iv_���b�Z�[�W�R�[�h        => cv_get_priod_msg
                          );
      ov_���^�[���R�[�h := cv_status_error;
      RAISE local_process_expt ��O����
     */
    IF ( ln_purge_period IS NULL ) THEN
--
      --�p�[�W���Ԃ̎擾�Ɏ��s���܂����B
      ov_errmsg  := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    /*
    -- �����N���擾
    gt_�����N�� := TO_CHAR(ADD_MONTHS(�������擾���ʊ֐����擾����������,
                                                           (ln_�p�[�W���� * -1)),'cv_�N��');
    */
    gt_shori_ym := TO_CHAR(ADD_MONTHS(xxcmn_common4_pkg.get_syori_date,
                                                       (ln_purge_period * -1)),cv_date_format);
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    lv_process_part   := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j�F';
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W�����R�~�b�g��);
    */
    ln_commit_range   := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
--
    /* ln_�����R�~�b�g����NULL�̏ꍇ
         ov_�G���[���b�Z�[�W := xxcmn_common_pkg.get_msg(
                     iv_�A�v���P�[�V�����Z�k��  => cv_appl_short_name
                    ,iv_���b�Z�[�W�R�[�h        => cv_get_profile_msg
                    ,iv_�g�[�N����1             => cv_token_profile
                    ,iv_�g�[�N���l1             => cv_xxcmn_commit_range
                   );
         ov_���^�[���R�[�h := cv_status_error;
         RAISE local_process_expt ��O����
    */
    IF ( ln_commit_range IS NULL ) THEN
--
      -- �v���t�@�C��[ NG_PROFILE ]�̎擾�Ɏ��s���܂����B
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_commit_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �o�b�N�A�b�v�e�[�u���g�����P�[�g
    -- ===============================================
    lv_process_part := '�o�b�N�A�b�v�e�[�u���g�����P�[�g�F';
--
    -- �o�b�N�A�b�v�e�[�u���g�����P�[�g
    /*
    EXECUTE IMMEDIATE 'TRUNCATE TABLE OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v';
    */
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || cv_tbl_name;
--
    -- ===============================================
    -- OPM�莝�݌Ƀg�����U�N�V���� �o�b�N�A�b�v����
    -- ===============================================
    lv_process_part := 'OPM�莝�݌Ƀg�����U�N�V���� �o�b�N�A�b�v�����F';
--
    /*
    FOR lr_loctinv_arc_rec IN �p�[�W�Ώ�OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v�擾 LOOP
--
      gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����i��ID     := lr_loctinv_arc_rec.�i��ID;  
      gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����q�ɃR�[�h := lr_loctinv_arc_rec.�q�ɃR�[�h;
      gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�������b�gID   := lr_loctinv_arc_rec.���b�gID;
      gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����ۊǏꏊ   := lr_loctinv_arc_rec.�ۊǏꏊ;
    */
    << loctinv_arc_loop >>
    FOR lr_loctinv_arc_rec IN bkp_data_cur LOOP
--
      gt_item_id   := lr_loctinv_arc_rec.item_id;  
      gt_whse_code := lr_loctinv_arc_rec.whse_code;
      gt_lot_id    := lr_loctinv_arc_rec.lot_id;
      gt_location  := lr_loctinv_arc_rec.location;
--
      -- ===============================================
      -- �����R�~�b�g(OPM�莝�݌Ƀg�����U�N�V����)
      -- ===============================================
      /*
      NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
      */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
          /*
           ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) > 0 ���� 
           MOD(ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����), ln_�����R�~�b�g��) = 0
           �̏ꍇ
          */
        IF (  (ln_arc_cnt_yet > 0)
          AND (MOD(ln_arc_cnt_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����)
            INSERT INTO OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v
            (
                �S�J����
            )
            VALUES
            (
                lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��(ln_idx)�S�J����
            );
          COMMIT;
          */
          FORALL ln_idx IN 1..ln_arc_cnt_yet
            INSERT INTO xxcmn_ic_loct_inv_arc VALUES l_loct_inv_tab(ln_idx);
--
          COMMIT;
--
          /*
          ln_�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) := 
                                        ln_�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) +
                                        ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����);
          ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) := 0;
          lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��.DELETE;
          */
--
          ln_bkp_cnt      := ln_bkp_cnt + ln_arc_cnt_yet;
          ln_arc_cnt_yet  := 0;
          l_loct_inv_tab.DELETE;
--
        END IF;
--
      END IF;
--
      /*
      ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) :=  
                            ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) + 1;
      */
      ln_arc_cnt_yet  := ln_arc_cnt_yet + 1;
      /*
      lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��(
               ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) := lr_loctinv_arc_rec;
      */
      l_loct_inv_tab(ln_arc_cnt_yet).item_id           := lr_loctinv_arc_rec.item_id;
      l_loct_inv_tab(ln_arc_cnt_yet).whse_code         := lr_loctinv_arc_rec.whse_code;
      l_loct_inv_tab(ln_arc_cnt_yet).lot_id            := lr_loctinv_arc_rec.lot_id;
      l_loct_inv_tab(ln_arc_cnt_yet).location          := lr_loctinv_arc_rec.location;
      l_loct_inv_tab(ln_arc_cnt_yet).loct_onhand       := lr_loctinv_arc_rec.loct_onhand;
      l_loct_inv_tab(ln_arc_cnt_yet).loct_onhand2      := lr_loctinv_arc_rec.loct_onhand2;
      l_loct_inv_tab(ln_arc_cnt_yet).lot_status        := lr_loctinv_arc_rec.lot_status;
      l_loct_inv_tab(ln_arc_cnt_yet).qchold_res_code   := lr_loctinv_arc_rec.qchold_res_code;
      l_loct_inv_tab(ln_arc_cnt_yet).delete_mark       := lr_loctinv_arc_rec.delete_mark;
      l_loct_inv_tab(ln_arc_cnt_yet).text_code         := lr_loctinv_arc_rec.text_code;
      l_loct_inv_tab(ln_arc_cnt_yet).last_updated_by   := lr_loctinv_arc_rec.last_updated_by;
      l_loct_inv_tab(ln_arc_cnt_yet).created_by        := lr_loctinv_arc_rec.created_by;
      l_loct_inv_tab(ln_arc_cnt_yet).last_update_date  := lr_loctinv_arc_rec.last_update_date;
      l_loct_inv_tab(ln_arc_cnt_yet).creation_date     := lr_loctinv_arc_rec.creation_date;
      l_loct_inv_tab(ln_arc_cnt_yet).last_update_login := lr_loctinv_arc_rec.last_update_login;
      l_loct_inv_tab(ln_arc_cnt_yet).program_application_id
                                                    := lr_loctinv_arc_rec.program_application_id;
      l_loct_inv_tab(ln_arc_cnt_yet).program_id        :=   lr_loctinv_arc_rec.program_id;
      l_loct_inv_tab(ln_arc_cnt_yet).program_update_date     
                                                    := lr_loctinv_arc_rec.program_update_date;
      l_loct_inv_tab(ln_arc_cnt_yet).request_id        := lr_loctinv_arc_rec.request_id;
--
    END LOOP loctinv_arc_loop;
--
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����)
      INSERT INTO OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v
      (
       �S�J����
      )
      VALUES
      (
       lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��(ln_idx)�S�J����
      );
    */
    FORALL ln_idx IN 1..ln_arc_cnt_yet
      INSERT INTO xxcmn_ic_loct_inv_arc VALUES l_loct_inv_tab(ln_idx);
--
    /*
    ln_�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) := 
                                        ln_�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) +
                                        ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����);
    ln_���R�~�b�g�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) := 0;
    COMMIT;
    */
    ln_bkp_cnt     := ln_bkp_cnt + ln_arc_cnt_yet;
    ln_arc_cnt_yet := 0;
    COMMIT;
--
    /*
    ln_�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) <> 0�̏ꍇ
    */
--
    IF (ln_bkp_cnt <> 0 ) THEN
--
      -- ===============================================
      -- �W���R���J�����g(��c���̃p�[�W�FGMIPEBAL)
      -- ===============================================
      lv_process_part := '�W���R���J�����g(��c���̃p�[�W�FGMIPEBAL)�F';
--
      --�R���J�����g���{�O�f�[�^�����J�E���g
      /*
      SELECT  COUNT(1)
      INTO    ln_��c���̃p�[�W(�����O)����
      FROM    OPM�莝�݌Ƀg�����U�N�V����; 
      */
--
      SELECT  COUNT(1)  AS cnt
      INTO    ln_purge_cnt_b
      FROM    ic_loct_inv;
--
      /*
      gn_request_id := FND_REQUEST.SUBMIT_REQUEST(
                     application       =>  cv_app_name          --�A�v���P�[�V�����Z�k��(GMI)
                    ,program           =>  cv_gmipebal          --�v���O������(GMIPEBAL)
                    ,description       =>  cv_description       --�E�v(��c���̃p�[�W)
                    ,start_time        =>  NULL                 --���s��
                    ,sub_request       =>  FALSE
                    ,argument1         =>  NULL                 --�i��:��
                    ,argument2         =>  NULL                 --�i��:��
                    ,argument3         =>  NULL                 --�q��:��
                    ,argument4         =>  NULL                 --�q��:��
                    ,argument5         =>  NULL                 --�݌ɋ敪
                    ,argument6         =>  NULL                 --���b�g�Ǘ��i��(0:NO,1:YES)
                    ,argument7         =>  cv_9                 --���x�̃p�[�W
                 ) ;
      */
      gn_request_id := FND_REQUEST.SUBMIT_REQUEST(
                     application       =>  cv_app_name          --�A�v���P�[�V�����Z�k��(GMI)
                    ,program           =>  cv_gmipebal          --�v���O������(GMIPEBAL)
                    ,description       =>  cv_description       --�E�v(��c���̃p�[�W)
                    ,start_time        =>  NULL                 --���s��
                    ,sub_request       =>  FALSE
                    ,argument1         =>  NULL                 --�i��:��
                    ,argument2         =>  NULL                 --�i��:��
                    ,argument3         =>  NULL                 --�q��:��
                    ,argument4         =>  NULL                 --�q��:��
                    ,argument5         =>  NULL                 --�݌ɋ敪
                    ,argument6         =>  NULL                 --���b�g�Ǘ��i��(0:NO,1:YES)
                    ,argument7         =>  cv_9                 --���x�̃p�[�W
                 ) ;
--
      /*
      -- �R���J�����g�N�����s�̏ꍇ�̓G���[����
      IF ( NVL(gn_request_id, 0) = 0 ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_app_name_xxcmn
                    ,iv_name          => cv_conc_err);
        RAISE global_api_others_expt;
      ELSE
        COMMIT;
      END IF;
      */
--
      IF ( NVL(gn_request_id, 0) = 0 ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_app_name_xxcmn
                    ,iv_name          => cv_conc_err);
        ov_retcode := cv_status_error;
        RAISE local_api_others_expt;
      ELSE
        COMMIT;
      END IF;
--
      -----------------------------------------
      --���s���ꂽ�R���J�����g�̏I���`�F�b�N
      -----------------------------------------
      --�R���J�����g���s���ʂ��擾
      /*
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(.
           request_id => gn_request_id.
          ,interval   => 1.
          ,max_wait   => 0.
          ,phase      => lv_phase.
          ,status     => lv_status.
          ,dev_phase  => lv_dev_phase.
          ,dev_status => lv_dev_status.
          ,message    => lv_errbuf_wait
          ) ) THEN
      */
      IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
           request_id => gn_request_id
          ,interval   => 1
          ,max_wait   => 0
          ,phase      => lv_phase
          ,status     => lv_status
          ,dev_phase  => lv_dev_phase
          ,dev_status => lv_dev_status
          ,message    => lv_errbuf_wait
         ) ) THEN
--
        -- �X�e�[�^�X���f
        -- �t�F�[�Y:����
        IF ( lv_dev_phase = cv_conc_p_c ) THEN
--
          /*
          lv_dev_status��'ERROR','CANCELLED','TERMINATED'�̏ꍇ�̓G���[�I��
          �e�[�^�X���G���[�ɂ��ďI��
          lv_dev_status��'WARNING'�̏ꍇ�͌x���I��
          �X�e�[�^�X���x���ɂ���
          lv_dev_status��'NORMAL'�̏ꍇ�͐��폈�����s
          lv_dev_status����L�ȊO�̏ꍇ�̓G���[�I��
          �X�e�[�^�X���G���[�ɂ��ďI��
          */
          --�X�e�[�^�X�R�[�h�ɂ��󋵔���
          CASE lv_dev_status
            --�G���[
            WHEN cv_conc_s_e THEN
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
--
            --�L�����Z��
            WHEN cv_conc_s_c THEN
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
--
            --�����I��
            WHEN cv_conc_s_t THEN
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
--
            --�x���I��
            WHEN cv_conc_s_w THEN
              --���܂Ő���̏ꍇ�̂݌x���X�e�[�^�X
              IF ( ov_retcode < 1 ) THEN
                ov_retcode := cv_status_warn;
              END IF;
--
            --����I��
            WHEN cv_conc_s_n THEN
              NULL;
--
            --���̒l�͗�O����
            ELSE
              --�v��[ REQUEST ]������ɏI�����܂���ł����B
              ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_gmipebal
                         );
              ov_retcode := cv_status_error;
              RAISE local_api_others_expt;
          END CASE;
--
        --�����܂ŏ�����҂��A�����X�e�[�^�X�ł͂Ȃ������ꍇ�̗�O�n���h��
        ELSE
          ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_gmipebal
                     );
          ov_retcode := cv_status_error;
          RAISE local_api_others_expt;
        END IF;
--
      --WAIT_FOR_REQUEST���ُ킾�����ꍇ�̗�O�n���h��
      ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_gmipebal
                     );
        ov_retcode := cv_status_error;
        RAISE local_api_others_expt;
      END IF;
--
      --�R���J�����g���{��f�[�^�����J�E���g
      /*
      SELECT  COUNT(1)
      INTO    ln_��c���̃p�[�W(������)����
      FROM    OPM�莝�݌Ƀg�����U�N�V����; 
      */
--
      SELECT  COUNT(1)  AS cnt
      INTO    ln_purge_cnt_a
      FROM    ic_loct_inv;
--
      /*
      gn_��c���̃p�[�W�������� := ln_��c���̃p�[�W(�����O)���� - ln_��c���̃p�[�W(������)����;
      */
      gn_purge_cnt := ln_purge_cnt_b - ln_purge_cnt_a;
--
      -- ===============================================
      -- �W���e�[�u�� ���X�g�A����
      -- ===============================================
      lv_process_part := '�W���e�[�u�� ���X�g�A�����F';
--
      /*
      lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��.DELETE;
      */
      l_loct_inv_tab.DELETE;
--
      /*
      OPEN rst_data_cur(gt_�����N��) LOOP;
      FETCH rst_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
      l_loct_inv2_tab.COUNT  > 0 �̏ꍇ
        gn_���X�g�A�����Ώی��� := l_loct_inv2_tab.COUNT;
--
      */
      OPEN rst_data_cur(gt_shori_ym);
      FETCH rst_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
        IF ( l_loct_inv2_tab.COUNT ) > 0 THEN
--
          gn_rst_cnt_all := l_loct_inv2_tab.COUNT;
--
          /*
          FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
          LOOP
          */
          << loctinv_rst_loop >>
          FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
          LOOP
--
            /*
            gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����i��ID      := lr_loctinv_rst_rec.�i��ID;  
            gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����q�ɃR�[�h  := lr_loctinv_rst_rec.�q�ɃR�[�h;
            gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�������b�gID    := lr_loctinv_rst_rec.���b�gID;
            gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����ۊǏꏊ    := lr_loctinv_rst_rec.�ۊǏꏊ;
            */
            gt_item_id   := l_loct_inv2_tab(ln_idx).item_id;  
            gt_whse_code := l_loct_inv2_tab(ln_idx).whse_code;
            gt_lot_id    := l_loct_inv2_tab(ln_idx).lot_id;
            gt_location  := l_loct_inv2_tab(ln_idx).location;
--
            -- ===============================================
            -- �����R�~�b�g(OPM�莝�݌Ƀg�����U�N�V����)
            -- ===============================================
            /*
            NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
            */
            IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
              /*
              ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����) > 0 ���� 
              MOD(ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����), ln_�����R�~�b�g��) = 0
              �̏ꍇ
              */
              IF (  (ln_rst_cnt_yet > 0)
                AND (MOD(ln_rst_cnt_yet, ln_commit_range) = 0)
                 )
              THEN
--
                /*
                FOR ln_idx1 IN 1..ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����)
                */
--
                FOR ln_idx1 IN 1..ln_rst_cnt_yet LOOP
--
                  -- IC_LOCT_INV �o�^����
                  lb_ret_code := GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV(l_loct_inv_tab(ln_idx1));
--
                  /*
                  IF (lb_ret_code = FALSE ) THEN
                    ov_errmsg := xxcmn_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err_msg
                      ,iv_token_name1  => cv_token_api
                      ,iv_token_value1 => cv_api_name
                    );
--                  ov_retcode := cv_status_error;
                    RAISE local_api_others_expt;
                  END IF;
                  */
                  IF (lb_ret_code = FALSE ) THEN
--
                    --API_NAME API�ŃG���[���������܂����B
                    ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err_msg
                      ,iv_token_name1  => cv_token_api
                      ,iv_token_value1 => cv_api_name
                     );
--
                    ov_retcode := cv_status_error;
                    RAISE local_api_others_expt;
                  END IF;
--
                  -- ==========================================================
                  -- OPM�莝�݌Ƀg�����U�N�V�������b�N
                  -- ==========================================================
                  /*
                  SELECT OPM�莝�݌Ƀg�����U�N�V����.�i��ID,
                    OPM�莝�݌Ƀg�����U�N�V����.���b�gID,
                    OPM�莝�݌Ƀg�����U�N�V����.�q�ɃR�[�h,
                    OPM�莝�݌Ƀg�����U�N�V����.�ۊǏꏊ
                  INTO lt_�i��ID,
                    lt_���b�gID,
                    lt_�q�ɃR�[�h,
                    lt_�ۊǏꏊ
                  FROM   OPM�莝�݌Ƀg�����U�N�V����
                  WHERE  �i��ID         = l_loct_inv_tab(ln_idx1).�i��ID
                  AND    ���b�gID       = l_loct_inv_tab(ln_idx1).���b�gID
                  AND    �q�ɃR�[�h     = l_loct_inv_tab(ln_idx1).�q�ɃR�[�h
                  AND    �ۊǏꏊ       = l_loct_inv_tab(ln_idx1).�ۊǏꏊ
                  FOR UPDATE NOWAIT;
                  */
--
                  SELECT ili.item_id  AS  item_id,
                     ili.lot_id       AS  lot_id,
                     ili.whse_code    AS  whse_code,
                     ili.location     AS  location
                  INTO   lt_item_id,
                     lt_lot_id,
                     lt_whse_code,
                     lt_location
                  FROM   ic_loct_inv      ili
                  WHERE  ili.item_id    = l_loct_inv_tab(ln_idx1).item_id
                  AND    ili.lot_id     = l_loct_inv_tab(ln_idx1).lot_id
                  AND    ili.whse_code  = l_loct_inv_tab(ln_idx1).whse_code
                  AND    ili.location   = l_loct_inv_tab(ln_idx1).location
                  FOR UPDATE NOWAIT;
--
                  ----------------------------------
                  -- API�œo�^���Ȃ�WHO�J�����X�V
                  ----------------------------------
                  /*
                  UPDATE OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v
                  SET    �ŏI�X�V���O�C�� = l_loct_inv_tab(ln_idx1).�ŏI�X�V���O�C��,
                         �v���O�����A�v���P�[�V����ID
                                          = l_loct_inv_tab(ln_idx1).�v���O�����A�v���P�[�V����ID,
                         �R���J�����g�v���O����ID 
                                          = l_loct_inv_tab(ln_idx1).�R���J�����g�v���O����ID
                         �v���O�����X�V�� = l_loct_inv_tab(ln_idx1).�v���O�����X�V��
                         �v��ID           = l_loct_inv_tab(ln_idx1).�v��ID
                  WHERE  �i��ID           = l_loct_inv_tab(ln_idx1).�i��ID
                  AND    ���b�gID         = l_loct_inv_tab(ln_idx1).���b�gID
                  AND    �q�ɃR�[�h       = l_loct_inv_tab(ln_idx1).�q�ɃR�[�h
                  AND    �ۊǏꏊ         = l_loct_inv_tab(ln_idx1).�ۊǏꏊ
                  );
                  */
                  UPDATE ic_loct_inv
                  SET  last_update_login      = l_loct_inv_tab(ln_idx1).last_update_login,
                       program_application_id = l_loct_inv_tab(ln_idx1).program_application_id,
                       program_id             = l_loct_inv_tab(ln_idx1).program_id,
                       program_update_date    = l_loct_inv_tab(ln_idx1).program_update_date,
                       request_id             = l_loct_inv_tab(ln_idx1).request_id
                  WHERE  item_id                = l_loct_inv_tab(ln_idx1).item_id
                  AND    lot_id                 = l_loct_inv_tab(ln_idx1).lot_id 
                  AND    whse_code              = l_loct_inv_tab(ln_idx1).whse_code 
                  AND    location               = l_loct_inv_tab(ln_idx1).location
                  ;
--
                END LOOP;
--
                /*
                COMMIT;
                */
                COMMIT;
--
                /*
                gn_���X�g�A�����iOPM�莝�݌Ƀg�����U�N�V����) := 
                                  gn_���X�g�A�����iOPM�莝�݌Ƀg�����U�N�V����) + 
                                  ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����);
                ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����) := 0;
                lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��.DELETE;
                */
                gn_restore_cnt := gn_restore_cnt + ln_rst_cnt_yet;
                ln_rst_cnt_yet := 0;
                l_loct_inv_tab.DELETE;
--
              END IF;
--
            END IF;
--
            /*
            ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����) :=  
                                      ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����) + 1;
            */
            ln_rst_cnt_yet := ln_rst_cnt_yet + 1;
--
            /*
            lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��(gn_���R�~�b�g�o�b�N�A�b�v���� 
                             (OPM�莝�݌Ƀg�����U�N�V����) := l_loct_inv2_tab(ln_idx).�S�J����;
            */
            l_loct_inv_tab(ln_rst_cnt_yet).item_id         := l_loct_inv2_tab(ln_idx).item_id;
            l_loct_inv_tab(ln_rst_cnt_yet).whse_code       := l_loct_inv2_tab(ln_idx).whse_code;
            l_loct_inv_tab(ln_rst_cnt_yet).lot_id          := l_loct_inv2_tab(ln_idx).lot_id;
            l_loct_inv_tab(ln_rst_cnt_yet).location        := l_loct_inv2_tab(ln_idx).location;
            l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand     
                                               := l_loct_inv2_tab(ln_idx).loct_onhand;
            l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand2    
                                               := l_loct_inv2_tab(ln_idx).loct_onhand2;
            l_loct_inv_tab(ln_rst_cnt_yet).lot_status      := l_loct_inv2_tab(ln_idx).lot_status;
            l_loct_inv_tab(ln_rst_cnt_yet).qchold_res_code 
                                               := l_loct_inv2_tab(ln_idx).qchold_res_code;
            l_loct_inv_tab(ln_rst_cnt_yet).delete_mark     
                                               := l_loct_inv2_tab(ln_idx).delete_mark;
            l_loct_inv_tab(ln_rst_cnt_yet).text_code       := l_loct_inv2_tab(ln_idx).text_code;
            l_loct_inv_tab(ln_rst_cnt_yet).last_updated_by 
                                               := l_loct_inv2_tab(ln_idx).last_updated_by;
            l_loct_inv_tab(ln_rst_cnt_yet).created_by      := l_loct_inv2_tab(ln_idx).created_by;
            l_loct_inv_tab(ln_rst_cnt_yet).last_update_date 
                                               := l_loct_inv2_tab(ln_idx).last_update_date;
            l_loct_inv_tab(ln_rst_cnt_yet).creation_date   
                                               := l_loct_inv2_tab(ln_idx).creation_date;
            l_loct_inv_tab(ln_rst_cnt_yet).last_update_login 
                                               := l_loct_inv2_tab(ln_idx).last_update_login;
            l_loct_inv_tab(ln_rst_cnt_yet).program_application_id
                                               := l_loct_inv2_tab(ln_idx).program_application_id;
            l_loct_inv_tab(ln_rst_cnt_yet).program_id      
                                               :=   l_loct_inv2_tab(ln_idx).program_id;
            l_loct_inv_tab(ln_rst_cnt_yet).program_update_date     
                                               := l_loct_inv2_tab(ln_idx).program_update_date;
            l_loct_inv_tab(ln_rst_cnt_yet).request_id      := l_loct_inv2_tab(ln_idx).request_id;
--
          END LOOP loctinv_rst_loop;
--
        END IF;
--
      CLOSE rst_data_cur;
--
      /*
      FOR ln_idx1 IN 1..ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����)
      */
--
      FOR ln_idx1 IN 1..ln_rst_cnt_yet LOOP
--
        -- IC_LOCT_INV �o�^����
        lb_ret_code := GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV(l_loct_inv_tab(ln_idx1));
--
        /*
        IF (lb_ret_code = FALSE ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(
               iv_application  => cv_appl_short_name
              ,iv_name         => cv_api_err_msg
              ,iv_token_name1  => cv_token_api
              ,iv_token_value1 => cv_api_name
              );
--
          ov_retcode := cv_status_error;
          RAISE local_api_others_expt;
        END IF;
        */
        IF (lb_ret_code = FALSE ) THEN
          --API_NAME API�ŃG���[���������܂����B
          ov_errmsg := xxcmn_common_pkg.get_msg(
             iv_application  => cv_appl_short_name
            ,iv_name         => cv_api_err_msg
            ,iv_token_name1  => cv_token_api
            ,iv_token_value1 => cv_api_name
            );
--
          ov_retcode := cv_status_error;
          RAISE local_api_others_expt;
--
        END IF;
--
        -- ==========================================================
        -- OPM�莝�݌Ƀg�����U�N�V�������b�N
        -- ==========================================================
        /*
        SELECT OPM�莝�݌Ƀg�����U�N�V����.�i��ID,
               OPM�莝�݌Ƀg�����U�N�V����.���b�gID,
               OPM�莝�݌Ƀg�����U�N�V����.�q�ɃR�[�h,
               OPM�莝�݌Ƀg�����U�N�V����.�ۊǏꏊ
        INTO   lt_�i��ID,
               lt_���b�gID,
               lt_�q�ɃR�[�h,
               lt_�ۊǏꏊ
        FROM   OPM�莝�݌Ƀg�����U�N�V����
        WHERE  �i��ID           = l_loct_inv_tab(ln_idx1).�i��ID
        AND    ���b�gID         = l_loct_inv_tab(ln_idx1).���b�gID
        AND    �q�ɃR�[�h       = l_loct_inv_tab(ln_idx1).�q�ɃR�[�h
        AND    �ۊǏꏊ         = l_loct_inv_tab(ln_idx1).�ۊǏꏊ
        FOR UPDATE NOWAIT;
        */
--
        SELECT ili.item_id      AS  item_id,
               ili.lot_id       AS  lot_id,
               ili.whse_code    AS  whse_code,
               ili.location     AS  location
        INTO   lt_item_id,
               lt_lot_id,
               lt_whse_code,
               lt_location
        FROM   ic_loct_inv        ili
        WHERE  ili.item_id      = l_loct_inv_tab(ln_idx1).item_id
        AND    ili.lot_id       = l_loct_inv_tab(ln_idx1).lot_id
        AND    ili.whse_code    = l_loct_inv_tab(ln_idx1).whse_code
        AND    ili.location     = l_loct_inv_tab(ln_idx1).location
        FOR UPDATE NOWAIT;
--
        ----------------------------------
        -- API�œo�^���Ȃ�WHO�J�����X�V
        ----------------------------------
        /*
        UPDATE OPM�莝�݌Ƀg�����U�N�V�����o�b�N�A�b�v
        SET    �ŏI�X�V���O�C�� = l_loct_inv_tab(ln_idx1).�ŏI�X�V���O�C��,
               �v���O�����A�v���P�[�V����ID
                                = l_loct_inv_tab(ln_idx1).�v���O�����A�v���P�[�V����ID,
               �R���J�����g�v���O����ID 
                                = l_loct_inv_tab(ln_idx1).�R���J�����g�v���O����ID
               �v���O�����X�V�� = l_loct_inv_tab(ln_idx1).�v���O�����X�V��
               �v��ID           = l_loct_inv_tab(ln_idx1).�v��ID
        WHERE  �i��ID           = l_loct_inv_tab(ln_idx1).�i��ID
        AND    ���b�gID         = l_loct_inv_tab(ln_idx1).���b�gID
        AND    �q�ɃR�[�h       = l_loct_inv_tab(ln_idx1).�q�ɃR�[�h
        AND    �ۊǏꏊ         = l_loct_inv_tab(ln_idx1).�ۊǏꏊ
        );
        */
        UPDATE ic_loct_inv
        SET    last_update_login      = l_loct_inv_tab(ln_idx1).last_update_login,
               program_application_id = l_loct_inv_tab(ln_idx1).program_application_id,
               program_id             = l_loct_inv_tab(ln_idx1).program_id,
               program_update_date    = l_loct_inv_tab(ln_idx1).program_update_date,
               request_id             = l_loct_inv_tab(ln_idx1).request_id
        WHERE  item_id                = l_loct_inv_tab(ln_idx1).item_id
        AND    lot_id                 = l_loct_inv_tab(ln_idx1).lot_id 
        AND    whse_code              = l_loct_inv_tab(ln_idx1).whse_code 
        AND    location               = l_loct_inv_tab(ln_idx1).location
        ;
--
      END LOOP;
--
      /*
      gn_���X�g�A�����iOPM�莝�݌Ƀg�����U�N�V����) := 
                                  gn_���X�g�A�����iOPM�莝�݌Ƀg�����U�N�V����) + 
                                  ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����);
      ln_���R�~�b�g���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����) := 0;
      lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��.DELETE;
      */
      gn_restore_cnt := gn_restore_cnt + ln_rst_cnt_yet;
      ln_rst_cnt_yet := 0;
--
    /*
    ln_�o�b�N�A�b�v����(OPM�莝�݌Ƀg�����U�N�V����) <> 0�̏ꍇ IF���I��
    */
    END IF;
--
  -- ===============================================
  -- ��O����
  -- ===============================================
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN local_process_expt    THEN
         NULL;
--
    WHEN local_api_others_expt THEN
         NULL;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      BEGIN
        IF ( SQL%BULK_EXCEPTIONS.COUNT > 0 ) THEN
--
          IF ( l_loct_inv_tab.COUNT > 0 ) THEN
--
            gt_item_id   := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).item_id;
            gt_whse_code := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).whse_code;
            gt_lot_id    := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).lot_id;
            gt_location  := l_loct_inv_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).location;
--
            --�p�[�W�����Ɏ��s���܂����B�yOPM�莝�݌Ƀp�[�W�z�i��ID �F KEY1 , 
            --�q�ɃR�[�h �F KEY2 , ���b�gID �F KEY3 , �ۊǏꏊ �F KEY4
            ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                       ,iv_name          => cv_others_err_msg
--
                       ,iv_token_name1   => cv_token_shori
                       ,iv_token_value1  => TO_CHAR(cv_shori)
--
                       ,iv_token_name2   => cv_token_kinou
                       ,iv_token_value2  => TO_CHAR(cv_kinou)
--
                       ,iv_token_name3   => cv_token_key_name1   --�i��ID
                       ,iv_token_value3  => TO_CHAR(cv_key_name1)
                       ,iv_token_name4   => cv_token_key1
                       ,iv_token_value4  => TO_CHAR(gt_item_id)
--
                       ,iv_token_name5   => cv_token_key_name2   --�q�ɃR�[�h
                       ,iv_token_value5  => TO_CHAR(cv_key_name2)
                       ,iv_token_name6   => cv_token_key2
                       ,iv_token_value6  => gt_whse_code
--
                       ,iv_token_name7   => cv_token_key_name3   --���b�gID
                       ,iv_token_value7  => TO_CHAR(cv_key_name3)
                       ,iv_token_name8   => cv_token_key3
                       ,iv_token_value8  => TO_CHAR(gt_lot_id)
--
                       ,iv_token_name9   => cv_token_key_name4   --�ۊǏꏊ
                       ,iv_token_value9  => TO_CHAR(cv_key_name4)
                       ,iv_token_name10  => cv_token_key4
                       ,iv_token_value10 => gt_location
                      );
          END IF;
--
        END IF;
--
      EXCEPTION
        WHEN not_init_collection_expt THEN
          NULL;
      END;
--
      IF ( (ov_errmsg    IS NULL)     AND (gt_item_id IS NOT NULL) AND
           (gt_whse_code IS NOT NULL) AND (gt_lot_id  IS NOT NULL) AND
           (gt_location  IS NOT NULL)
      ) THEN
            --�p�[�W�����Ɏ��s���܂����B�yOPM�莝�݌Ƀp�[�W�z�i��ID �F KEY1 ,
            --�q�ɃR�[�h �F KEY2 , ���b�gID �F KEY3 , �ۊǏꏊ �F KEY4
            ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                       ,iv_name          => cv_others_err_msg
--
                       ,iv_token_name1   => cv_token_shori
                       ,iv_token_value1  => TO_CHAR(cv_shori)
--
                       ,iv_token_name2   => cv_token_kinou
                       ,iv_token_value2  => TO_CHAR(cv_kinou)
--
                       ,iv_token_name3   => cv_token_key_name1   --�i��ID
                       ,iv_token_value3  => TO_CHAR(cv_key_name1)
                       ,iv_token_name4   => cv_token_key1
                       ,iv_token_value4  => TO_CHAR(gt_item_id)
--
                       ,iv_token_name5   => cv_token_key_name2   --�q�ɃR�[�h
                       ,iv_token_value5  => TO_CHAR(cv_key_name2)
                       ,iv_token_name6   => cv_token_key2
                       ,iv_token_value6  => gt_whse_code
--
                       ,iv_token_name7   => cv_token_key_name3   --���b�gID
                       ,iv_token_value7  => TO_CHAR(cv_key_name3)
                       ,iv_token_name8   => cv_token_key3
                       ,iv_token_value8  => TO_CHAR(gt_lot_id)
--
                       ,iv_token_name9   => cv_token_key_name4   --�ۊǏꏊ
                       ,iv_token_value9  => TO_CHAR(cv_key_name4)
                       ,iv_token_name10  => cv_token_key4
                       ,iv_token_value10 => gt_location
                      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||SQLERRM;
      ov_retcode := cv_status_error;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    lv_nengetu         VARCHAR2(50);
    --
  BEGIN
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
       lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- ���O�o�͏���
    -- ===============================================
    -- �G���[�����o��(�G���[�����F CNT ��)
    IF ( gt_shori_ym IS NULL ) THEN
      lv_nengetu  := NULL;
    ELSE
      lv_nengetu  := SUBSTRB(gt_shori_ym,1,4) || cv_msg_slash || SUBSTRB(gt_shori_ym,5,2);
    END IF;
--
    --�p�����[�^(�����N���F NENGETU)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_nengetu_token
                    ,iv_token_value1 => lv_nengetu
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --��c���̃p�[�W�i���N�G�X�gID�j�F REQUEST_ID
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg2
                      ,iv_token_name1  => cv_req_id
                      ,iv_token_value1 => TO_CHAR(gn_request_id)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    /*
    �G���[�����擾
    gn_�G���[����(OPM�莝�݌Ƀg�����U�N�V����) := 
                                       gn_���X�g�A�����Ώی���(OPM�莝�݌Ƀg�����U�N�V����) - 
                                       gn_���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����);
    */
    IF (lv_retcode = cv_status_error  AND gn_rst_cnt_all - gn_restore_cnt = 0) THEN
        gn_error_cnt  := 1;
    ELSE
      gn_error_cnt  := gn_rst_cnt_all - gn_restore_cnt;
    END IF;
--
    /*
    �폜�����擾
    gn_�폜����(OPM�莝�݌Ƀg�����U�N�V����) := 
                                       gn_��c���̃p�[�W��������(OPM�莝�݌Ƀg�����U�N�V����) - 
                                       gn_���X�g�A�����Ώی���(OPM�莝�݌Ƀg�����U�N�V����);
    */
    gn_del_cnt    := gn_purge_cnt - gn_restore_cnt;
--
    /*
    ���팏���擾
    gn_���팏��(OPM�莝�݌Ƀg�����U�N�V����) := 
                                       gn_��c���̃p�[�W��������(OPM�莝�݌Ƀg�����U�N�V����) - 
                                       gn_���X�g�A�����Ώی���(OPM�莝�݌Ƀg�����U�N�V����);
    */
    gn_normal_cnt := gn_purge_cnt - gn_rst_cnt_all;
--
    --OPM�莝�݌Ƀg�����U�N�V�����i�W���j �폜 �����F CNT ��
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg1
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname
                      ,iv_token_name2  => cv_token_shori_p
                      ,iv_token_value2 => cv_shori_p
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_del_cnt)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ���팏���o��(���팏���F CNT ��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_normal_cnt_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��(�G���[�����F CNT ��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- -----------------------
    --  ��������(submain)
    -- -----------------------
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��(�o�͂̕\��)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
--
    END IF;
--
    -- ===============================================
    -- �I������
    -- ===============================================
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  -- ===============================================
  -- ��O����
  -- ===============================================
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMN960011C;
/
