CREATE OR REPLACE PACKAGE BODY XXCMN970001C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN970001C(body)
 * Description      : �I�������݌Ƀe�[�u���p�[�W
 * MD.050           : T_MD050_BPO_97A_�I�������݌Ƀe�[�u���p�[�W
 * Version          : 1.00
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/11/28    1.00  Miyamoto         �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_request_id      CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_date_format_s   CONSTANT VARCHAR2(10) := 'YYYYMM';
--
  cv_purge_type      CONSTANT VARCHAR2(1)  := '0';                        --�߰������(0:�߰�ފ���)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9701';                     --�߰�ޒ�`����
--
  --=============
  --���b�Z�[�W
  --=============
  cv_appl_short_name  CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part         CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_purge_range      
                      CONSTANT VARCHAR2(50) := 'XXCMN_PURGE_RANGE_MONTH';        --XXCMN:�p�[�W�����W����
  cv_xxcmn_commit_range     
                      CONSTANT VARCHAR2(50)   := 'XXCMN_COMMIT_RANGE';   --XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��

--
  cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ��TBL_NAME ��SHORI �����F ��CNT ��
  cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- �������b�Z�[�W�p�g�[�N�����i�����j
  cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- �������b�Z�[�W�p�g�[�N�����i�e�[�u�����j
  cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- �������b�Z�[�W�p�g�[�N�����i�������j
  cv_table_cnt_xsims  CONSTANT VARCHAR2(100) := '�I�������݌�';                -- �������b�Z�[�W�p�e�[�u����
  cv_shori_cnt_target CONSTANT VARCHAR2(100) := '�Ώ�';                -- �������b�Z�[�W�p������
  cv_shori_cnt_delete CONSTANT VARCHAR2(100) := '�폜';                -- �������b�Z�[�W�p������
  cv_shori_cnt_normal CONSTANT VARCHAR2(100) := '����';                -- �������b�Z�[�W�p������
  cv_shori_cnt_error  CONSTANT VARCHAR2(100) := '�G���[';                -- �������b�Z�[�W�p������
  cv_get_priod_msg    CONSTANT VARCHAR2(50)   := 'APP-XXCMN-11011';      --�p�[�W���Ԏ擾���s
  cv_get_profile_msg  CONSTANT VARCHAR2(50)   := 'APP-XXCMN-10002';      --���̧�ْl�擾���s
  cv_get_param_msg    CONSTANT VARCHAR2(50)   := 'APP-XXCMN-10155';      --�p�����[�^�� ��ERROR_PARAM ( ��ERROR_VALUE )���s���ł�
  cv_token_profile    CONSTANT VARCHAR2(50)   := 'NG_PROFILE';           --���̧�َ擾MSG�pİ�ݖ�
  cv_proc_date_msg    CONSTANT VARCHAR2(50)   := 'APP-XXCMN-11014';      --�������o��
  cv_par_token        CONSTANT VARCHAR2(50)   := 'PAR';                  --������MSG�pİ�ݖ�
  cv_local_others_msg CONSTANT VARCHAR2(100)  := 'APP-XXCMN-11026';      -- ��SHORI �����Ɏ��s���܂����B�y ��KINOUMEI �z ��KEYNAME �F ��KEY
  cv_token_param      CONSTANT VARCHAR2(50)   := 'ERROR_PARAM';
  cv_token_value      CONSTANT VARCHAR2(50)   := 'ERROR_VALUE';
  cv_token_shori      CONSTANT VARCHAR2(50)   := 'SHORI';
  cv_token_kinoumei   CONSTANT VARCHAR2(50)   := 'KINOUMEI';
  cv_token_keyname    CONSTANT VARCHAR2(50)   := 'KEYNAME';
  cv_token_key        CONSTANT VARCHAR2(50)   := 'KEY';
  cv_token_proc_date  CONSTANT VARCHAR2(100)  := '������';
  cv_token_bkup       CONSTANT VARCHAR2(100)  := '�o�b�N�A�b�v';
  cv_token_sims       CONSTANT VARCHAR2(100)  := '�I�������݌Ƀe�[�u��';
  cv_token_stock_id   CONSTANT VARCHAR2(100)  := '�I�������݌�ID';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                       -- �Ώی���
  gn_normal_cnt             NUMBER;                                       -- ���팏��
  gn_error_cnt              NUMBER;                                       -- �G���[����
  gn_del_cnt                NUMBER;                                       -- �폜����
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN970001C';  -- �p�b�P�[�W��
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
    iv_proc_date  IN  VARCHAR2,     --   1.������
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
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf               VARCHAR2(5000);                      -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                         -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);                      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_del_cnt_yet                  NUMBER DEFAULT 0;                    -- ���R�~�b�g�폜����
    ln_purge_period                 NUMBER;                              -- �p�[�W����
    ln_commit_range                 NUMBER;                              -- �����R�~�b�g��
    ln_purge_range                  NUMBER;                              -- �p�[�W�����W
    lt_invent_monthly_stock_id      xxinv_stc_inventory_month_stck.invent_monthly_stock_id%TYPE;
    lt_standard_ym                  xxcmn_stc_inv_month_stck_arc.invent_ym%TYPE; -- ��N��
    lv_process_step                 VARCHAR2(100);

--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
/*
    -- �I�������݌Ɂi�A�h�I���j
    CURSOR �p�[�W�ΏےI�������݌Ɂi�A�h�I���j�擾
      it_��N��  IN �I�������݌Ɂi�A�h�I���j�o�b�N�A�b�v.�I���N��%TYPE
      in_�p�[�W�����W IN NUMBER
    IS
      SELECT 
             �I�������݌Ɂi�A�h�I���j�D�I�������݌ɂh�c
      FROM �I�������݌Ɂi�A�h�I���j�o�b�N�A�b�v
           ,   �I�������݌Ɂi�A�h�I���j
      WHERE �I�������݌Ɂi�A�h�I���j�o�b�N�A�b�v�D�I���N�� >= TO_CHAR(ADD_MONTHS(TO_DATE(it_��N���C'YYYYMM')�C(in_�p�[�W�����W * -1))�C'YYYYMM')
      AND �I�������݌Ɂi�A�h�I���j�o�b�N�A�b�v�D�I���N�� < iv_��N��
      AND �I�������݌Ɂi�A�h�I���j�D�I�������݌�ID = �I�������݌Ɂi�A�h�I���j�o�b�N�A�b�v�D�I�������݌�ID
*/
--
  CURSOR purge_stc_inv_month_stck_cur(
      it_standard_ym        xxcmn_stc_inv_month_stck_arc.invent_ym%TYPE
     ,in_purge_range        NUMBER
    )
    IS
      SELECT 
        xsims.invent_monthly_stock_id AS invent_monthly_stock_id
      FROM
        xxcmn_stc_inv_month_stck_arc       xsimsa
       ,xxinv_stc_inventory_month_stck     xsims
      WHERE
          xsimsa.invent_ym IS NOT NULL
        AND xsimsa.invent_ym >= TO_CHAR(ADD_MONTHS(TO_DATE(it_standard_ym, cv_date_format_s), (in_purge_range * -1)), cv_date_format_s)
        AND xsimsa.invent_ym  < it_standard_ym
        AND xsims.invent_monthly_stock_id = xsimsa.invent_monthly_stock_id
      ;
    -- <�J�[�\����>���R�[�h�^
    TYPE purge_stc_inv_month_stck_ttype IS TABLE OF purge_stc_inv_month_stck_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_purge_stc_inv_month_stck_tab       purge_stc_inv_month_stck_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode        := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_del_cnt        := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- �p�[�W���Ԏ擾
    -- ===============================================
    lv_process_step := '�p�[�W���Ԏ擾';
    /*
    ln_�p�[�W���� := �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐��icv_�p�[�W�^�C�v,cv_�p�[�W�R�[�h�j;
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
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �h�m�p�����[�^�̊m�F
    -- ===============================================
    lv_process_step := '�p�����[�^�m�F';
    BEGIN
      /*
      iv_proc_date��NULL�̏ꍇ
        lv_��N�� := TO_CHAR(ADD_MONTHS(�������擾���ʊ֐����擾�����������C(ln_�p�[�W���� * -1))�C'YYYYMM');
--
      iv_proc_date��NULL�łȂ��ꍇ
        lv_��N�� := TO_CHAR(ADD_MONTHS(TO_DATE(iv_proc_date, 'YYYY/MM/DD')�C(ln_�p�[�W���� * -1))�C'YYYYMM');
       */
      IF ( iv_proc_date IS NULL ) THEN
--
        lt_standard_ym := TO_CHAR(ADD_MONTHS(xxcmn_common4_pkg.get_syori_date, (ln_purge_period * -1)), cv_date_format_s);
--
      ELSE
--
        lt_standard_ym := TO_CHAR(ADD_MONTHS(TO_DATE(iv_proc_date, cv_date_format), (ln_purge_period * -1)), cv_date_format_s);
--
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_param_msg
                      ,iv_token_name1  => cv_token_param
                      ,iv_token_value1 => cv_token_proc_date
                      ,iv_token_name2  => cv_token_value
                      ,iv_token_value2 => iv_proc_date
                     );
        RAISE local_process_expt;
    END;
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    lv_process_step := '�v���t�@�C���擾';
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W�����R�~�b�g��);
    */
    BEGIN
      ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
--
      IF ( ln_commit_range IS NULL ) THEN
        -- �v���t�@�C��[ NG_PROFILE ]�̎擾�Ɏ��s���܂����B
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�����R�~�b�g��:' || TO_CHAR(ln_commit_range));
--
    /*
    ln_�p�[�W�����W   := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W�����W);
    */
    BEGIN
      ln_purge_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
--
      IF ( ln_purge_range IS NULL ) THEN
        -- �v���t�@�C��[ NG_PROFILE ]�̎擾�Ɏ��s���܂����B
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_purge_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_purge_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
--
    -- ===============================================
    -- �p�[�W�ΏےI�������݌Ɂi�A�h�I���j�擾
    -- ===============================================
    lv_process_step := '�o�b�N�A�b�v�ΏےI�������݌Ɏ擾';
    /*
    OPEN �p�[�W�ΏےI�������݌Ɂi�A�h�I���j�擾�ild_����Cln_�p�[�W�����W�j;
    FETCH �p�[�W�ΏےI�������݌Ɂi�A�h�I���j�擾  BULK COLLECT INTO lt_�I�������݌�;
    */
    OPEN purge_stc_inv_month_stck_cur(lt_standard_ym,ln_purge_range);
    FETCH purge_stc_inv_month_stck_cur BULK COLLECT INTO l_purge_stc_inv_month_stck_tab;
--
    /*
    �p�[�W�Ώی������擾����
    gn_�Ώی��� := �I�������݌�.COUNT
    */
    gn_target_cnt          := l_purge_stc_inv_month_stck_tab.COUNT;
--
    /*
    �t�F�b�`�s�����݂����ꍇ��
    FOR ln_main_idx in 1 .. lt_�I�������݌�.COUNT  LOOP  �p�[�W�ΏےI�������݌Ɂi�A�h�I���j�擾
    */
    IF ( l_purge_stc_inv_month_stck_tab.COUNT ) > 0 THEN
      << purge_stc_inv_month_stck >>
      FOR ln_main_idx in 1 .. l_purge_stc_inv_month_stck_tab.COUNT
      LOOP
--
        -- ===============================================
        -- �����R�~�b�g
        -- ===============================================
        /*
        NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
         */
        IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
          /*
          ln_���R�~�b�g�폜���� > 0 ����
           MOD(ln_���R�~�b�g�폜����, ln_�����R�~�b�g��) = 0�̏ꍇ
          */
          IF (  (ln_del_cnt_yet > 0)
            AND (MOD(ln_del_cnt_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            ln_�폜���� := ln_�폜���� + ln_���R�~�b�g�폜����;
            ln_���R�~�b�g�폜���� := 0;
            COMMIT;
            */
            gn_del_cnt     := gn_del_cnt + ln_del_cnt_yet;
            ln_del_cnt_yet := 0;
            COMMIT;
--
          END IF;
--
        END IF;
--
        /*
        lt_�I�������݌�ID := l_purge_stc_inv_month_stck_tab�D�I�������݌�ID;
        */
        lt_invent_monthly_stock_id      := l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id;
--
        -- ===============================================
        -- �p�[�W�ΏےI�������݌Ɂi�A�h�I���j�A�o�b�N�A�b�v���Ƀ��b�N
        -- ===============================================
        /*
        SELECT
              �I�������݌�(�A�h�I��).�I�������݌�ID
        FROM �I�������݌�(�A�h�I��)
             �I�������݌�(�A�h�I��)�o�b�N�A�b�v
        WHERE �I�������݌�(�A�h�I��).�I�������݌�ID =l_�I�������݌�_tab(ln_main_idx).�I�������݌�ID
        AND �I�������݌�(�A�h�I��).�I�������݌�ID = �I�������݌�(�A�h�I��)�o�b�N�A�b�v�D�I�������݌�ID
        FOR UPDATE NOWAIT
        ;
         */
        SELECT
          xsims.invent_monthly_stock_id    AS invent_monthly_stock_id
        INTO
          lt_invent_monthly_stock_id
        FROM
           xxinv_stc_inventory_month_stck     xsims
          ,xxcmn_stc_inv_month_stck_arc       xsimsa
        WHERE
          xsims.invent_monthly_stock_id = l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id
        AND xsims.invent_monthly_stock_id = xsimsa.invent_monthly_stock_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- �I�������݌Ɂi�A�h�I���j�p�[�W
        -- ===============================================
        /*
        DELETE �I�������݌Ɂi�A�h�I���j
        WHERE �I�������݌�ID = l_�I�������݌�_tab(ln_main_idx).�I�������݌�ID
         */
        DELETE FROM
          xxinv_stc_inventory_month_stck
        WHERE
          invent_monthly_stock_id = l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id
        ;
--
        /*
        UPDATE �I�������݌Ɂi�A�h�I���j�o�b�N�A�b�v
        SET �p�[�W���s�� = SYSDATE
            ,  �p�[�W�v��ID = �v��ID
        WHERE �I�������݌�ID = l_�I�������݌�_tab(ln_main_idx)�D�I�������݌�ID
         */
        UPDATE
          xxcmn_stc_inv_month_stck_arc
        SET
          purge_date          = SYSDATE
         ,purge_request_id    = cn_request_id
        WHERE
          invent_monthly_stock_id = l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id
        ;
--
        /*
        ln_���R�~�b�g�폜���� := ln_���R�~�b�g�폜���� + 1;
        */
        ln_del_cnt_yet := ln_del_cnt_yet + 1;
--
      /*
      END LOOP �p�[�W�ΏےI�������݌Ɂi�A�h�I���j�擾;
      */
      END LOOP purge_stc_inv_month_stck;
--
      /*
      ln_�폜���� := ln_�폜���� + ln_���R�~�b�g�폜����;
      ln_���R�~�b�g�폜���� := 0;
      */
      gn_del_cnt     := gn_del_cnt + ln_del_cnt_yet;
      ln_del_cnt_yet := 0;
    END IF;
--
  -- ===============================================
  -- ��O����
  -- ===============================================
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN local_process_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
      IF ( lt_invent_monthly_stock_id IS NOT NULL ) THEN
        --��SHORI �����Ɏ��s���܂����B�y ��KINOUMEI �z ��KEYNAME �F ��KEY
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_token_bkup
                      ,iv_token_name2  => cv_token_kinoumei
                      ,iv_token_value2 => cv_token_sims
                      ,iv_token_name3  => cv_token_keyname
                      ,iv_token_value3 => cv_token_stock_id
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(lt_invent_monthly_stock_id)
                     );
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
        ov_errmsg := lv_process_step||cv_msg_part||SQLERRM;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date  IN  VARCHAR2       --   1.������
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
    --
  BEGIN
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_proc_date -- 1.������
      ,lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- ���O�o�͏���
    -- ===============================================
    --�p�����[�^(�������F PAR)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �Ώی����o��(�Ώی����F CNT ��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xsims
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_target
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �폜�����o��(�폜�����F CNT ��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xsims
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
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
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xsims
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_normal
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt)      --�폜����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��(�G���[�����F CNT ��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xsims
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_error
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)
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
      --�G���[�o��(���O�̕\��)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
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
END XXCMN970001C;
/
