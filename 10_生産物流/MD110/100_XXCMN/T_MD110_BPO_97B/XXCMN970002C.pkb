CREATE OR REPLACE PACKAGE BODY XXCMN970002C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN970002C(body)
 * Description      : �I�������݌Ƀe�[�u���o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_97B_�I�������݌Ƀe�[�u���o�b�N�A�b�v
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
 *  2012/11/09   1.00  T.Makuta          �V�K�쐬
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
  cv_date_format1    CONSTANT VARCHAR2(6)  := 'YYYYMM';
  cv_date_format2    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
  cv_purge_type      CONSTANT VARCHAR2(1)  := '1';                        --�߰������(1:BUCKUP����)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9701';                     --�߰�ޒ�`����
--
  --=============
  --���b�Z�[�W
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_archive_range
                     CONSTANT VARCHAR2(50) := 'XXCMN_ARCHIVE_RANGE_MONTH'; --XXCMN:�ޯ������ݼ�
  --XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��
  cv_xxcmn_commit_range     
                     CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_target_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11008';          --�Ώی������b�Z�[�W
  cv_normal_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';          --���팏�����b�Z�[�W
  cv_error_rec_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';          --�G���[�������b�Z�[�W
--
  cv_proc_date_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11014';          --�������o��
  cv_par_token       CONSTANT VARCHAR2(10) := 'PAR';                      --������MSG�pİ�ݖ�
--
  cv_get_profile_msg CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';          --���̧�ْl�擾���s
  cv_token_profile   CONSTANT VARCHAR2(50) := 'NG_PROFILE';               --���̧�َ擾MSG�pİ�ݖ�
--
  cv_get_priod_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11012';          --�ޯ����ߊ��Ԏ擾���s
--
  cv_others_err_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11027';          --�ޯ����ߏ������s
  cv_token_key       CONSTANT VARCHAR2(10) := 'KEY';                      --�ޯ����ߏ���MSG�pİ�ݖ�
--
  --TBL_NAME SHORI �����F CNT ��
  cv_end_msg         CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';          --�������e�o��
  cv_token_tblname   CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname         CONSTANT VARCHAR2(90) := '�I�������݌�(�A�h�I��)';
  cv_token_shori     CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori           CONSTANT VARCHAR2(50) := '�o�b�N�A�b�v';
  cv_cnt_token       CONSTANT VARCHAR2(10) := 'CNT';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                                     --�Ώی���
  gn_normal_cnt      NUMBER;                                     --���팏��
  gn_error_cnt       NUMBER;                                     --�G���[����
  gn_arc_cnt         NUMBER;                                     --�ޯ����ߌ���
  gt_inv_month_stc_id xxinv_stc_inventory_month_stck.invent_monthly_stock_id%TYPE; 
                                                                 --�I�������݌�ID
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
  not_init_collection_expt  EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_init_collection_expt, -6531);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN970002C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE lt_month_stc_ttype IS TABLE OF xxcmn_stc_inv_month_stck_arc%ROWTYPE INDEX BY BINARY_INTEGER;
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
    ln_arc_cnt_yet            NUMBER;                           --���Я��ޯ����ߌ���
    ln_archive_period         NUMBER;                           --�o�b�N�A�b�v����
    ln_archive_range          NUMBER;                           --�o�b�N�A�b�v�����W
    lv_standard_ym            VARCHAR2(6);                      --��N��(YYYYMM)
    ln_proc_date              NUMBER;
    ln_commit_range           NUMBER;                           --�����R�~�b�g��
    lv_process_part           VARCHAR2(1000);                   --������
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    CURSOR �o�b�N�A�b�v�ΏےI�������݌�(�A�h�I��)�擾
      it_��N��  IN �I�������݌�(�A�h�I��).�I���N��%TYPE
      in_�o�b�N�A�b�v�����W IN NUMBER
    IS
      SELECT 
             �I�������݌�(�A�h�I��).�S�J����,
             �o�b�N�A�b�v�o�^��,
             �o�b�N�A�b�v�v��ID,
             NULL,                  --�p�[�W���s��
             NULL                   --�p�[�W�v��ID
      FROM   �I�������݌�(�A�h�I��)
      WHERE  �I�������݌�(�A�h�I��).�I���N�� >= TO_CHAR(ADD_MONTHS(TO_DATE(it_��N���C'YYYYMM')�C
                                                         (in_�o�b�N�A�b�v�����W * -1))�C'YYYYMM')
      AND    �I�������݌�(�A�h�I��).�I���N�� < it_��N��
      AND NOT EXISTS (SELECT 1
                      FROM   �I�������݌�(�A�h�I��)�o�b�N�A�b�v
                      WHERE  �I�������݌�(�A�h�I��)�o�b�N�A�b�v.�I�������݌ɂh�c = 
                             �I�������݌�(�A�h�I��).�I�������݌ɂh�c
                      AND ROWNUM = 1
                     );
    */
--
    CURSOR mstck_cur(
      it_standard_ym        xxinv_stc_inventory_month_stck.invent_monthly_stock_id%TYPE
     ,in_archive_range      NUMBER
    )
    IS
      SELECT /*+ INDEX(xsim XXINV_SIMS_N03) */
             xsim.invent_monthly_stock_id  AS  invent_monthly_stock_id,   --�I�������݌�ID
             xsim.whse_code                AS  whse_code,                 --�q�ɃR�[�h
             xsim.item_id                  AS  item_id,                   --�i��ID
             xsim.item_code                AS  item_code,                 --�i�ڃR�[�h
             xsim.lot_id                   AS  lot_id,                    --���b�gID
             xsim.lot_no                   AS  lot_no,                    --���b�gNo.
             xsim.monthly_stock            AS  monthly_stock,             --�����݌ɐ�
             xsim.cargo_stock              AS  cargo_stock,               --�ϑ����݌ɐ�
             xsim.invent_ym                AS  invent_ym,                 --�I���N��
             xsim.created_by               AS  created_by,                --�쐬��
             xsim.creation_date            AS  creation_date,             --�쐬��
             xsim.last_updated_by          AS  last_updated_by,           --�ŏI�X�V��
             xsim.last_update_date         AS  last_update_date,          --�ŏI�X�V��
             xsim.last_update_login        AS  last_update_login,         --�ŏI�X�V���O�C��
             xsim.request_id               AS  request_id,                --�v��ID
             xsim.program_application_id   AS  program_application_id,    --���ع����ID
             xsim.program_id               AS  program_id,                --�ݶ��ĥ��۸���ID
             xsim.program_update_date      AS  program_update_date,       --�v���O�����X�V��
             xsim.cargo_stock_not_stn      AS  cargo_stock_not_stn,       --�ϑ����݌ɐ�(�W���Ȃ�)
             SYSDATE                       AS  archive_date,              --�o�b�N�A�b�v�o�^��
             cn_request_id                 AS  archive_request_id,        --�o�b�N�A�b�v�v��ID
             NULL                          AS  purge_date,                --�p�[�W���s��
             NULL                          AS  purge_request_id           --�p�[�W�v��ID
      FROM   xxinv_stc_inventory_month_stck xsim                          --�I�������݌�(�A�h�I��)
      WHERE  xsim.invent_ym >= TO_CHAR(ADD_MONTHS(TO_DATE(it_standard_ym,cv_date_format1),
                                                         (ln_archive_range * -1)),cv_date_format1)
      AND    xsim.invent_ym <  it_standard_ym
      AND NOT EXISTS
              (SELECT 1
               FROM  xxcmn_stc_inv_month_stck_arc   xsima             --�I�������݌�(��޵�)�ޯ�����
               WHERE xsim.invent_monthly_stock_id = xsima.invent_monthly_stock_id
               AND   ROWNUM = 1
              );
--
    -- <�J�[�\����>���R�[�h�^
    lt_mstc_tbl      lt_month_stc_ttype;                              --�I�������݌�(��޵�)ð���
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
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_arc_cnt        := 0;
    ln_arc_cnt_yet    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- �o�b�N�A�b�v���Ԏ擾
    -- ===============================================
    /*
    ln_�o�b�N�A�b�v���� := �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐�(cv_�p�[�W�^�C�v,cv_�p�[�W�R�[�h);
     */
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
--
    /*
    ln_�o�b�N�A�b�v���Ԃ�NULL�̏ꍇ
      ov_�G���[���b�Z�[�W := xxcmn_common_pkg.get_msg(
                            iv_�A�v���P�[�V�����Z�k��  => cv_appl_short_name
                           ,iv_���b�Z�[�W�R�[�h        => cv_get_priod_msg
                          );
      ov_���^�[���R�[�h := cv_status_error;
      RAISE local_process_expt ��O����
    */
--
    IF ( ln_archive_period IS NULL ) THEN
--
      --�o�b�N�A�b�v���Ԃ̎擾�Ɏ��s���܂����B
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
    lv_process_part := 'IN�p�����[�^�̊m�F�F';
--
    /*
    iv_proc_date��NULL�̏ꍇ
--
      lv_��N�� := TO_CHAR(ADD_MONTHS(�������擾���ʊ֐����擾�����������C
                                                           (ln_�o�b�N�A�b�v���� * -1))�C'YYYYMM');
--
    iv_proc_date��NULL�łȂ��ꍇ
--
      lv_��N�� := TO_CHAR(ADD_MONTHS(TO_DATE(iv_proc_date),
                                                           (ln_�o�b�N�A�b�v���� * -1)),'YYYYMM');
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      lv_standard_ym := TO_CHAR(ADD_MONTHS(xxcmn_common4_pkg.get_syori_date,
                                           (ln_archive_period * -1)),cv_date_format1);
--
    ELSE
--
      ln_proc_date   := TO_NUMBER(REPLACE(iv_proc_date,'/',''));
      lv_standard_ym := TO_CHAR(ADD_MONTHS(TO_DATE(ln_proc_date,cv_date_format2),
                                                  (ln_archive_period * -1)),cv_date_format1);
--
    END IF;
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j�F';
--
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����R�~�b�g��));
     */
    ln_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_archive_range || '�j:';
--
    /*
    ln_�o�b�N�A�b�v�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����W));
    */
    ln_archive_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_archive_range));
--
    /*
    ln_�o�b�N�A�b�v�����W��NULL�̏ꍇ
    */
    IF ( ln_archive_range IS NULL ) THEN
--
      /*
      ov_�G���[���b�Z�[�W := xxcmn_common_pkg.get_msg(
                     iv_�A�v���P�[�V�����Z�k��  => cv_appl_short_name
                    ,iv_���b�Z�[�W�R�[�h        => cv_get_profile_msg
                    ,iv_�g�[�N����1             => cv_token_profile
                    ,iv_�g�[�N���l1             => cv_xxcmn_archive_range
                   );
      ov_���^�[���R�[�h := cv_status_error;
      RAISE local_process_expt ��O����
      */
--
      -- �v���t�@�C��[ NG_PROFILE ]�̎擾�Ɏ��s���܂����B
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_archive_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    lv_process_part := NULL;
--
    -- ===============================================
    -- �又��
    -- ===============================================
   /*
    FOR lr_mstck_rec IN �o�b�N�A�b�v�ΏےI�������݌�(�A�h�I��)�擾
                                                    (lv_��N���Cln_�o�b�N�A�b�v�����W) LOOP
   */
    << stc_inv_mstck_loop >>
    FOR lr_mstck_rec IN mstck_cur(lv_standard_ym
                                 ,ln_archive_range ) LOOP
--
      -- ===============================================
      -- �����R�~�b�g
      -- ===============================================
      /*
      NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
       */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
        /* ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) > 0
           ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)), ln_�����R�~�b�g��) = 0
           �̏ꍇ
        */
        IF (  (ln_arc_cnt_yet > 0)
          AND (MOD(ln_arc_cnt_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��))
            INSERT INTO �I�������݌�(�A�h�I��)�o�b�N�A�b�v
            (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
                lt_�I�������݌�(�A�h�I��)�e�[�u��(ln_idx)�S�J����
              , SYSDATE
              , �v��ID
            )
--
          COMMIT;
          */
--
          FORALL ln_idx IN 1..ln_arc_cnt_yet
            INSERT INTO xxcmn_stc_inv_month_stck_arc VALUES lt_mstc_tbl(ln_idx);
--
          COMMIT;
--
          /*
          gn_�o�b�N�A�b�v����(�I�������݌�(�A�h�I��))           := 
                                    gn_�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) + 
                                    ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��));
          ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) := 0;
          lt_�I�������݌�(�A�h�I��)�e�[�u��.DELETE;
          */
--
          gn_arc_cnt := gn_arc_cnt + ln_arc_cnt_yet;
          ln_arc_cnt_yet    := 0;
          lt_mstc_tbl.DELETE;
--
        END IF;
--
      END IF;
--
      -- ----------------------------------
      -- �I�������݌�(�A�h�I��) �ϐ��ݒ�
      -- ----------------------------------
      /*
      ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) := 
                                    ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) + 1;
      */
--
      ln_arc_cnt_yet := ln_arc_cnt_yet + 1;
--
      /*
      lt_�I�������݌�(�A�h�I��)�e�[�u��(ln_���R�~�b�g�o�b�N�A�b�v����
                                       (�I�������݌�(�A�h�I��)) := lr_mstck_rec;
      */
      lt_mstc_tbl(ln_arc_cnt_yet).invent_monthly_stock_id := lr_mstck_rec.invent_monthly_stock_id;
      lt_mstc_tbl(ln_arc_cnt_yet).whse_code               := lr_mstck_rec.whse_code;
      lt_mstc_tbl(ln_arc_cnt_yet).item_id                 := lr_mstck_rec.item_id;
      lt_mstc_tbl(ln_arc_cnt_yet).item_code               := lr_mstck_rec.item_code;
      lt_mstc_tbl(ln_arc_cnt_yet).lot_id                  := lr_mstck_rec.lot_id;
      lt_mstc_tbl(ln_arc_cnt_yet).lot_no                  := lr_mstck_rec.lot_no;
      lt_mstc_tbl(ln_arc_cnt_yet).monthly_stock           := lr_mstck_rec.monthly_stock;
      lt_mstc_tbl(ln_arc_cnt_yet).cargo_stock             := lr_mstck_rec.cargo_stock;
      lt_mstc_tbl(ln_arc_cnt_yet).invent_ym               := lr_mstck_rec.invent_ym;
      lt_mstc_tbl(ln_arc_cnt_yet).created_by              := lr_mstck_rec.created_by;
      lt_mstc_tbl(ln_arc_cnt_yet).creation_date           := lr_mstck_rec.creation_date;
      lt_mstc_tbl(ln_arc_cnt_yet).last_updated_by         := lr_mstck_rec.last_updated_by;
      lt_mstc_tbl(ln_arc_cnt_yet).last_update_date        := lr_mstck_rec.last_update_date;
      lt_mstc_tbl(ln_arc_cnt_yet).last_update_login       := lr_mstck_rec.last_update_login;
      lt_mstc_tbl(ln_arc_cnt_yet).request_id              := lr_mstck_rec.request_id;
      lt_mstc_tbl(ln_arc_cnt_yet).program_application_id  := lr_mstck_rec.program_application_id;
      lt_mstc_tbl(ln_arc_cnt_yet).program_id              := lr_mstck_rec.program_id;
      lt_mstc_tbl(ln_arc_cnt_yet).program_update_date     := lr_mstck_rec.program_update_date;
      lt_mstc_tbl(ln_arc_cnt_yet).cargo_stock_not_stn     := lr_mstck_rec.cargo_stock_not_stn;
      lt_mstc_tbl(ln_arc_cnt_yet).archive_date            := lr_mstck_rec.archive_date;
      lt_mstc_tbl(ln_arc_cnt_yet).archive_request_id      := lr_mstck_rec.archive_request_id;
      lt_mstc_tbl(ln_arc_cnt_yet).purge_date              := lr_mstck_rec.purge_date;
      lt_mstc_tbl(ln_arc_cnt_yet).purge_request_id        := lr_mstck_rec.purge_request_id;
--
    END LOOP stc_inv_mstck_loop;
--
    -- ---------------------------------------------------------
    -- �����R�~�b�g�ΏۊO�̎c�f�[�^ INSERT����(�I�������݌�(�A�h�I��))
    -- ---------------------------------------------------------
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��))
        INSERT INTO �I�������݌�(�A�h�I��)�o�b�N�A�b�v
        (
          �S�J����
        , �o�b�N�A�b�v�o�^��
        , �o�b�N�A�b�v�v��ID
        )
        VALUES
        (
          �I�������݌�(�A�h�I��)�e�[�u��(ln_idx)�S�J����
        , SYSDATE
        , �v��ID
        )
        ;
    */
--
    FORALL ln_idx IN 1..ln_arc_cnt_yet
      INSERT INTO xxcmn_stc_inv_month_stck_arc VALUES lt_mstc_tbl(ln_idx);
--
    /*
    gn_�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) := 
                                        gn_�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) + 
                                        ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��));
    ln_���R�~�b�g�o�b�N�A�b�v����(�I�������݌�(�A�h�I��)) := 0;
    lt_�I�������݌�(�A�h�I��)�e�[�u��.DELETE;
    */
--
    gn_arc_cnt := gn_arc_cnt + ln_arc_cnt_yet;
    ln_arc_cnt_yet    := 0;
    lt_mstc_tbl.DELETE;
--
  -- ===============================================
  -- ��O����
  -- ===============================================
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN local_process_expt THEN
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
          IF ( lt_mstc_tbl.COUNT > 0 ) THEN
            gt_inv_month_stc_id := 
                     lt_mstc_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).invent_monthly_stock_id;
            --�o�b�N�A�b�v�����Ɏ��s���܂����B�y�I�������݌�(�A�h�I��)�z�I�������݌�ID: KEY
             ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_others_err_msg
                       ,iv_token_name1  => cv_token_key
                       ,iv_token_value1 => TO_CHAR(gt_inv_month_stc_id)
                      );
          END IF;
        END IF;
--
      EXCEPTION
        WHEN not_init_collection_expt THEN
          NULL;
      END;
--
      IF ( (ov_errmsg IS NULL) AND (gt_inv_month_stc_id IS NOT NULL) ) THEN
           --�o�b�N�A�b�v�����Ɏ��s���܂����B�y�I�������݌�(�A�h�I��)�z�I�������݌�ID: KEY
           ov_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_others_err_msg
                       ,iv_token_name1  => cv_token_key
                       ,iv_token_value1 => TO_CHAR(gt_inv_month_stc_id)
                      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||SQLERRM;
      ov_retcode := cv_status_error;
--
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
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
    --�I�������݌�(�A�h�I��) �o�b�N�A�b�v �����F CNT ��
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_arc_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��(�G���[�����F CNT ��)
    IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := 1;
    ELSE
      gn_error_cnt   := 0;
    END IF;
--
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
END XXCMN970002C;
/
