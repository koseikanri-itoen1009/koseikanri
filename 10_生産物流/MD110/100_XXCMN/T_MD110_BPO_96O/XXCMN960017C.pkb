CREATE OR REPLACE PACKAGE BODY XXCMN960017C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2013. All rights reserved.
 *
 * Package Name     : XXCMN960017C(body)
 * Description      : OPM�莝�݌Ƀp�[�W
 * MD.050           : T_MD050_BPO_96O_OPM�莝�݌Ƀp�[�W���J�o��
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
 *  2013/04/08   1.00  D.Sugahara       �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal     CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn       CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error      CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  --=============
  --���b�Z�[�W
  --=============
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part          CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont          CONSTANT VARCHAR2(3)  := '.';
  cv_msg_slash         CONSTANT VARCHAR2(3)  := '/';
--
  --XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��
  cv_xxcmn_commit_range     
                       CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_normal_cnt_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';        --���팏�����b�Z�[�W
  cv_error_rec_msg     CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';        --�G���[�������b�Z�[�W
--
  cv_get_profile_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';        --���̧�ْl�擾���s
  cv_token_profile     CONSTANT VARCHAR2(50) := 'NG_PROFILE';             --���̧�َ擾MSG�pİ�ݖ�
--
  --TBL_NAME SHORI �����F CNT ��
  cv_cnt_token         CONSTANT VARCHAR2(10) := 'CNT';
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
  cv_shori             CONSTANT VARCHAR2(50) := '���J�o��';
  cv_kinou             CONSTANT VARCHAR2(90) := 'OPM�莝�݌Ƀp�[�W���J�o��';
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
  gn_normal_cnt        NUMBER;                                            --���팏��
  gn_error_cnt         NUMBER;                                            --�G���[����
  gn_restore_cnt       NUMBER;                                            --���X�g�A����
  gn_rst_cnt_all       NUMBER;                                            --���X�g�A�S����
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960017C'; -- �p�b�P�[�W��
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
    ln_rst_cnt_yet            NUMBER;                           --���R�~�b�g���X�g�A����
    ln_commit_range           NUMBER;                           --�����R�~�b�g��
    lv_process_part           VARCHAR2(1000);                   --������
    lb_ret_code               BOOLEAN;
--
    lt_item_id                ic_loct_inv.item_id%TYPE;
    lt_lot_id                 ic_loct_inv.lot_id%TYPE;
    lt_whse_code              ic_loct_inv.whse_code%TYPE;
    lt_location               ic_loct_inv.location%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    CURSOR OPM�莝�݌Ƀ��J�o���f�[�^�擾
    IS
    SELECT 
            OPM�莝�݌Ƀo�b�N�A�b�v.�S�J����
    FROM    OPM�莝�݌Ƀo�b�N�A�b�v
    WHERE 
      NOT EXISTS
           (-- OPM�莝�݌ɂɑ��݂��Ȃ�
            SELECT 'X'
            FROM   OPM�莝�݌�
            WHERE  OPM�莝�݌�.�i��ID       = OPM�莝�݌Ƀo�b�N�A�b�v.�i��ID
            AND    OPM�莝�݌�.���b�gID     = OPM�莝�݌Ƀo�b�N�A�b�v.���b�gID
            AND    OPM�莝�݌�.�q�ɃR�[�h   = OPM�莝�݌Ƀo�b�N�A�b�v.�q�ɃR�[�h
            AND    OPM�莝�݌�.���P�[�V���� = OPM�莝�݌�.���P�[�V����
            AND    ROWNUM = 1
           )
      ;
    */
    CURSOR recover_data_cur
    IS
      SELECT  /*+ INDEX(xili XXCMN_IC_LOCT_INV_ARC_N1) */
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
      FROM  xxcmn_ic_loct_inv_arc    xili                        --OPM�莝�݌Ƀo�b�N�A�b�v
      WHERE NOT EXISTS
              (SELECT /*+ INDEX(ili IC_LOCT_INV_PK ) */
                     'X'
               FROM  ic_loct_inv        ili       --OPM�莝�݌�
               WHERE ili.item_id       = xili.item_id
               AND   ili.lot_id        = xili.lot_id
               AND   ili.whse_code     = xili.whse_code
               AND   ili.location      = xili.location
               AND   ROWNUM = 1
              )
      ;
--
    -- <�J�[�\����>���R�[�h�^
    TYPE lt_loct_inv_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv_tab      lt_loct_inv_ttype;                  --OPM�莝�݌Ɂi�R�~�b�g�������j
--
    TYPE lt_loct_inv2_ttype IS TABLE OF xxcmn_ic_loct_inv_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    l_loct_inv2_tab      lt_loct_inv2_ttype;                --OPM�莝�݌Ɂi�S�����j
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
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_restore_cnt    := 0;
    gn_rst_cnt_all    := 0;
    ln_rst_cnt_yet    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
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
    -- OPM�莝�݌Ƀe�[�u�� ���X�g�A����
    -- ===============================================
    lv_process_part := 'OPM�莝�݌Ƀe�[�u�� ���X�g�A�����F';
--
    /*
    lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��.DELETE;
    */
    l_loct_inv_tab.DELETE;
--
    /*
    OPEN recover_data_cur LOOP;
    FETCH rst_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
    l_loct_inv2_tab.COUNT  > 0 �̏ꍇ
      gn_���X�g�A�����Ώی��� := l_loct_inv2_tab.COUNT;
    */
    OPEN recover_data_cur;
    FETCH recover_data_cur BULK COLLECT INTO l_loct_inv2_tab;
--
      IF ( l_loct_inv2_tab.COUNT ) > 0 THEN
--
        gn_rst_cnt_all := l_loct_inv2_tab.COUNT;
--
        /*
        FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
        LOOP
        */
        << loctinv_recov_loop >>
        FOR ln_idx in 1 .. l_loct_inv2_tab.COUNT
        LOOP
--
          /*
          gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����i��ID      := l_loct_inv2_tab.�i��ID;  
          gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����q�ɃR�[�h  := l_loct_inv2_tab.�q�ɃR�[�h;
          gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�������b�gID    := l_loct_inv2_tab.���b�gID;
          gt_�Ώ�OPM�莝�݌Ƀg�����U�N�V�����ۊǏꏊ    := l_loct_inv2_tab.�ۊǏꏊ;
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
                /*
                lb_ret_code = GMI_LOCT_INV_DB_PVT.INSERT_IC_LOCT_INV(l_loct_inv_tab(ln_idx1));
                */
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
                -- OPM�莝�݌Ƀe�[�u�����b�N�i�X�V�p�j
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
                SELECT /*+ INDEX(ili IC_LOCT_INV_PK ) */
                   ili.item_id      AS  item_id,
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
                -- API�œo�^����Ȃ��Ȃ�WHO�J�����X�V
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
              gn_restore_cnt := NVL( gn_restore_cnt ,0 ) + NVL( ln_rst_cnt_yet ,0 );
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
          ln_rst_cnt_yet := NVL( ln_rst_cnt_yet,0 ) + 1;
--
          /*
          lt_OPM�莝�݌Ƀg�����U�N�V�����e�[�u��(gn_���R�~�b�g�o�b�N�A�b�v���� 
                           (OPM�莝�݌Ƀg�����U�N�V����) := l_loct_inv2_tab(ln_idx).�S�J����;
          */
          l_loct_inv_tab(ln_rst_cnt_yet).item_id         := l_loct_inv2_tab(ln_idx).item_id;
          l_loct_inv_tab(ln_rst_cnt_yet).whse_code       := l_loct_inv2_tab(ln_idx).whse_code;
          l_loct_inv_tab(ln_rst_cnt_yet).lot_id          := l_loct_inv2_tab(ln_idx).lot_id;
          l_loct_inv_tab(ln_rst_cnt_yet).location        := l_loct_inv2_tab(ln_idx).location;
          l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand     := l_loct_inv2_tab(ln_idx).loct_onhand;
          l_loct_inv_tab(ln_rst_cnt_yet).loct_onhand2    := l_loct_inv2_tab(ln_idx).loct_onhand2;
          l_loct_inv_tab(ln_rst_cnt_yet).lot_status      := l_loct_inv2_tab(ln_idx).lot_status;
          l_loct_inv_tab(ln_rst_cnt_yet).qchold_res_code := l_loct_inv2_tab(ln_idx).qchold_res_code;
          l_loct_inv_tab(ln_rst_cnt_yet).delete_mark     := l_loct_inv2_tab(ln_idx).delete_mark;
          l_loct_inv_tab(ln_rst_cnt_yet).text_code       := l_loct_inv2_tab(ln_idx).text_code;
          l_loct_inv_tab(ln_rst_cnt_yet).last_updated_by := l_loct_inv2_tab(ln_idx).last_updated_by;
          l_loct_inv_tab(ln_rst_cnt_yet).created_by      := l_loct_inv2_tab(ln_idx).created_by;
          l_loct_inv_tab(ln_rst_cnt_yet).last_update_date 
                                                         := l_loct_inv2_tab(ln_idx).last_update_date;
          l_loct_inv_tab(ln_rst_cnt_yet).creation_date   := l_loct_inv2_tab(ln_idx).creation_date;
          l_loct_inv_tab(ln_rst_cnt_yet).last_update_login 
                                                         := l_loct_inv2_tab(ln_idx).last_update_login;
          l_loct_inv_tab(ln_rst_cnt_yet).program_application_id
                                                         := l_loct_inv2_tab(ln_idx).program_application_id;
          l_loct_inv_tab(ln_rst_cnt_yet).program_id      := l_loct_inv2_tab(ln_idx).program_id;
          l_loct_inv_tab(ln_rst_cnt_yet).program_update_date     
                                                         := l_loct_inv2_tab(ln_idx).program_update_date;
          l_loct_inv_tab(ln_rst_cnt_yet).request_id      := l_loct_inv2_tab(ln_idx).request_id;
--
        END LOOP loctinv_recov_loop;
--
      END IF;
--
    CLOSE recover_data_cur;
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
      -- OPM�莝�݌Ƀg�����U�N�V�������b�N�i�X�V�p�j
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
    gn_restore_cnt := NVL( gn_restore_cnt, 0 ) + NVL( ln_rst_cnt_yet ,0 );
    ln_rst_cnt_yet := 0;
    l_loct_inv_tab.DELETE;    
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
            --�p�[�W�����Ɏ��s���܂����B�yOPM�莝�݌Ƀp�[�W���J�o���z�i��ID �F KEY1 , 
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
            --�p�[�W�����Ɏ��s���܂����B�yOPM�莝�݌Ƀp�[�W���J�o���z�i��ID �F KEY1 ,
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
    ���팏���擾
    gn_���팏��(OPM�莝�݌Ƀg�����U�N�V����) := gn_���X�g�A����(OPM�莝�݌Ƀg�����U�N�V����);
    */
    gn_normal_cnt := gn_restore_cnt;
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
END XXCMN960017C;
/
