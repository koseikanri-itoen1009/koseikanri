CREATE OR REPLACE PACKAGE BODY XXCMN960001C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960001C(body)
 * Description      : �󒍃A�h�I���p�[�W
 * MD.050           : T_MD050_BPO_96A_�󒍃A�h�I���p�[�W
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
 *  2012/10/15   1.00  Hiroshi.Ogawa     �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := '0'; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1';   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2';  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gn_del_cnt_header         NUMBER;                                             -- �폜�����i�󒍃w�b�_�i�A�h�I���j�j
  gn_del_cnt_line           NUMBER;                                             -- �폜�����i�󒍖��ׁi�A�h�I���j�j
  gn_del_cnt_lot            NUMBER;                                             -- �폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j
  gt_order_header_id        xxwsh_order_headers_all.order_header_id%TYPE;       -- �Ώێ󒍃w�b�_�A�h�I��ID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960001C'; -- �p�b�P�[�W��
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_get_priod_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- �p�[�W���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_profile_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_local_others_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11010';  -- �폜�����Ɏ��s���܂����B�y�󒍁i�A�h�I���j�z�󒍃w�b�_�A�h�I��ID�F ��KEY
    cv_token_profile       CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key           CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range  CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_purge_range   CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';
--
    cv_shipping            CONSTANT VARCHAR2(2)   := '04';
    cv_sikyu               CONSTANT VARCHAR2(2)   := '08';
    cv_mov_shipping        CONSTANT VARCHAR2(2)   := '10';
    cv_mov_sikyu           CONSTANT VARCHAR2(2)   := '30';
--
    cv_date_format         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
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
    cv_purge_type   CONSTANT VARCHAR2(1)  := '0';                               -- �p�[�W�^�C�v�i0:�p�[�W�������ԁj
    cv_purge_code   CONSTANT VARCHAR2(30) := '9601';                            -- �p�[�W��`�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_del_cnt_header_yet     NUMBER DEFAULT 0;                                 -- ���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j
    ln_del_cnt_line_yet       NUMBER DEFAULT 0;                                 -- ���R�~�b�g�폜�����i�󒍖��ׁi�A�h�I���j�j
    ln_del_cnt_lot_yet        NUMBER DEFAULT 0;                                 -- ���R�~�b�g�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j
    ln_purge_period           NUMBER;                                           -- �p�[�W����
    ld_standard_date          DATE;                                             -- ���
    ln_commit_range           NUMBER;                                           -- �����R�~�b�g��
    ln_purge_range            NUMBER;                                           -- �p�[�W�����W
    lv_process_part           VARCHAR2(1000);                                   -- ������
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    -- �󒍃w�b�_�i�A�h�I���j
    CURSOR �p�[�W�Ώێ󒍃w�b�_�i�A�h�I���j�擾
      id_���  IN DATE
      in_�p�[�W�����W IN NUMBER
    IS
      SELECT 
             �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I���h�c
      FROM �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
           ,    �󒍃w�b�_�i�A�h�I���j
      WHERE �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�X�e�[�^�X IN ('04','08')
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ד� >= id_��� - in_�p�[�W�����W
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ד� < id_���
      AND �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I��ID = �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃w�b�_�A�h�I��ID
      UNION ALL
      SELECT 
             �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I���h�c
      FROM �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
           ,    �󒍃w�b�_�i�A�h�I���j
      WHERE �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�X�e�[�^�X NOT IN ('04','08')
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ח\��� >= id_��� - in_�p�[�W�����W
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ח\��� < id_���
      AND �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I��ID = �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃w�b�_�A�h�I��ID
     */
    CURSOR purge_order_header_cur(
      id_standard_date           DATE
     ,in_purge_range             NUMBER
    )
    IS
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa xoha) INDEX(xohaa XXCMN_OHAA_N15) */
              xoha.order_header_id      AS order_header_id
      FROM    xxcmn_order_headers_all_arc  xohaa
             ,xxwsh_order_headers_all      xoha
      WHERE   xohaa.req_status    IN (cv_shipping, cv_sikyu)
      AND     xohaa.arrival_date  >= id_standard_date - in_purge_range
      AND     xohaa.arrival_date   < id_standard_date
      AND     xoha.order_header_id = xohaa.order_header_id
      UNION ALL
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa xoha) INDEX(xohaa XXCMN_OHAA_N14) */
              xoha.order_header_id      AS order_header_id
      FROM    xxcmn_order_headers_all_arc  xohaa
             ,xxwsh_order_headers_all      xoha
      WHERE   xohaa.req_status         NOT IN (cv_shipping, cv_sikyu)
      AND     xohaa.schedule_arrival_date  >= id_standard_date - in_purge_range
      AND     xohaa.schedule_arrival_date   < id_standard_date
      AND     xoha.order_header_id          = xohaa.order_header_id
    ;
    /*
    -- �󒍖��ׁi�A�h�I���j
    CURSOR �p�[�W�Ώێ󒍖��ׁi�A�h�I���j�擾
      it_�󒍃w�b�_�A�h�I���h�c IN �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I���h�c%TYPE
    IS
      SELECT
             �󒍖��ׁi�A�h�I���j�D�󒍖��׃A�h�I���h�c
      FROM �󒍖��ׁi�A�h�I���j
      WHERE �󒍖��ׁi�A�h�I���j�D�󒍃w�b�_�A�h�I���h�c = in_�󒍃w�b�_�A�h�I���h�c
      FOR UPDATE NOWAIT
     */
    CURSOR purge_order_line_cur(
      it_order_header_id         xxwsh_order_headers_all.order_header_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(xola XXWSH_OL_N01) */
              xola.order_line_id        AS order_line_id
      FROM    xxwsh_order_lines_all  xola
      WHERE   xola.order_header_id = it_order_header_id
      FOR UPDATE NOWAIT
    ;
    /*
    -- �ړ����b�g�ڍׁi�A�h�I���j
    CURSOR �p�[�W�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾
      it_�󒍖��׃A�h�I���h�c IN �󒍖��ׁi�A�h�I���j�D�󒍖��׃A�h�I���h�c%TYPE
    IS
      SELECT
             �ړ����b�g�ڍׁi�A�h�I���j�D���b�g�ڍׂh�c
      FROM �ړ����b�g�ڍׁi�A�h�I���j
      WHERE �ړ����b�g�ڍׁi�A�h�I���j�D���ׂh�c = in_�󒍖��׃A�h�I���h�c
      AND �ړ����b�g�ڍׁi�A�h�I���j�D�����^�C�v�R�[�h IN ('10','30')
      FOR UPDATE NOWAIT
     */
    CURSOR purge_mov_lot_dtl_cur(
      it_order_line_id           xxwsh_order_lines_all.order_line_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(xmld XXINV_MLD_N01) */
              xmld.mov_lot_dtl_id       AS mov_lot_dtl_id
      FROM    xxinv_mov_lot_details  xmld
      WHERE   xmld.mov_line_id        = it_order_line_id
      AND     xmld.document_type_code IN (cv_mov_shipping, cv_mov_sikyu)
      FOR UPDATE NOWAIT
    ;
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_del_cnt_header := 0;
    gn_del_cnt_line   := 0;
    gn_del_cnt_lot    := 0;
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
    ln_�p�[�W���� := �p�[�W���Ԏ擾���ʊ֐��icv_�p�[�W��`�R�[�h�j;
     */
    lv_process_part := '�p�[�W���Ԏ擾';
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_purge_period IS NULL ) THEN
--
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
    /*
    iv_proc_date��NULL�̏ꍇ
--
      ld_��� := �������擾���ʊ֐�����擾���������� - ln_�p�[�W����;
--
    iv_proc_date��NULL�łȂ��̏ꍇ
--
      ld_��� := TO_DATE(iv_proc_date) - ln_�p�[�W����;
     */
    lv_process_part := 'IN�p�����[�^�̊m�F';
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_purge_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_purge_period;
--
    END IF;
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��));
    ln_�p�[�W�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W�����W));
     */
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j';
    ln_commit_range := fnd_profile.value(cv_xxcmn_commit_range);
    IF ( ln_commit_range IS NULL ) THEN
--
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
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_purge_range || '�j';
    ln_purge_range  := fnd_profile.value(cv_xxcmn_purge_range);
    IF ( ln_purge_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_purge_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �p�[�W�Ώێ󒍃w�b�_�i�A�h�I���j�擾
    -- ===============================================
    /*
    FOR lr_header_rec IN �p�[�W�Ώێ󒍃w�b�_�i�A�h�I���j�擾�ild_����Cln_�p�[�W�����W�j LOOP
     */
    << purge_order_header_loop >>
    FOR lr_header_rec IN purge_order_header_cur(
                           ld_standard_date
                          ,ln_purge_range
                         )
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
        ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j > 0 ���� MOD(ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
         */
        IF (  (ln_del_cnt_header_yet > 0)
          AND (MOD(ln_del_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          ln_�폜�����i�󒍃w�b�_�i�A�h�I���j�j := ln_�폜�����i�󒍃w�b�_�i�A�h�I���j�j + ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j;
          ln_�폜�����i�󒍖��ׁi�A�h�I���j�j := ln_�폜�����i�󒍖��ׁi�A�h�I���j�j + ln_���R�~�b�g�폜�����i�󒍖��ׁi�A�h�I���j�j;
          ln_�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j := ln_�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j + ln_���R�~�b�g�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j;
          ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j := 0;
          ln_���R�~�b�g�폜�����i�󒍖��ׁi�A�h�I���j�j := 0;
          ln_���R�~�b�g�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j := 0;
          COMMIT;
           */
          gn_del_cnt_header     := gn_del_cnt_header + ln_del_cnt_header_yet;
          gn_del_cnt_line       := gn_del_cnt_line   + ln_del_cnt_line_yet;
          gn_del_cnt_lot        := gn_del_cnt_lot    + ln_del_cnt_lot_yet;
          ln_del_cnt_header_yet := 0;
          ln_del_cnt_line_yet   := 0;
          ln_del_cnt_lot_yet    := 0;
          COMMIT;
--
        END IF;
--
      END IF;
--
      /*
      ln_�Ώی��� := ln_�Ώی��� + 1;
      ln_�Ώێ󒍃w�b�_�A�h�I��ID := lr_header_rec�D�󒍃w�b�_�A�h�I��ID;
       */
      gn_target_cnt := gn_target_cnt + 1;
      gt_order_header_id := lr_header_rec.order_header_id;
--
      -- ===============================================
      -- �p�[�W�Ώێ󒍃w�b�_�i�A�h�I���j���b�N
      -- ===============================================
      /*
      SELECT
            �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I��ID
      FROM �󒍃w�b�_�i�A�h�I���j,
           �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
      WHERE �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I��ID = lr_header_rec�D�󒍃w�b�_�A�h�I��ID
        AND �󒍃w�b�_�i�A�h�I���j�D�󒍃w�b�_�A�h�I��ID = �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃w�b�_�A�h�I��ID
      FOR UPDATE NOWAIT
       */
      lv_process_part := '�p�[�W�Ώێ󒍃w�b�_�i�A�h�I���j���b�N';
      SELECT  xoha.order_header_id      AS order_header_id
      INTO    gt_order_header_id
      FROM    xxwsh_order_headers_all  xoha
             ,xxcmn_order_headers_all_arc xohaa
      WHERE   xoha.order_header_id = lr_header_rec.order_header_id
        AND   xoha.order_header_id = xohaa.order_header_id
      FOR UPDATE NOWAIT
      ;
--
      -- ===============================================
      -- �p�[�W�Ώێ󒍖��ׁi�A�h�I���j�擾
      -- ===============================================
      /*
      FOR lr_line_rec IN �p�[�W�Ώێ󒍖��ׁi�A�h�I���j�擾�ilr_header_rec�D�󒍃w�b�_�A�h�I��ID�j LOOP
       */
      lv_process_part := '�p�[�W�Ώێ󒍖��ׁi�A�h�I���j���b�N';
      << purge_order_line_loop >>
      FOR lr_line_rec IN purge_order_line_cur(
                           lr_header_rec.order_header_id
                         )
      LOOP
--
        -- ===============================================
        -- �p�[�W�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾
        -- ===============================================
        /*
        FOR lr_lot_rec IN �p�[�W�Ώۈړ����b�g�ڍׁi�A�h�I���j�擾�ilr_line_rec�D�󒍖��׃A�h�I��ID�j LOOP
         */
        lv_process_part := '�p�[�W�Ώۈړ����b�g�ڍׁi�A�h�I���j���b�N';
        << purge_mov_lot_dtl_loop >>
        FOR lr_lot_rec IN purge_mov_lot_dtl_cur(
                            lr_line_rec.order_line_id
                          )
        LOOP
--
          -- ===============================================
          -- �ړ����b�g�ڍׁi�A�h�I���j�p�[�W
          -- ===============================================
          /*
          DELETE �ړ����b�g�ڍׁi�A�h�I���j
          WHERE ���b�g�ڍ�ID = lr_lot_rec�D���b�g�ڍ�ID
           */
          lv_process_part := '�ړ����b�g�ڍׁi�A�h�I���j�p�[�W';
          DELETE xxinv_mov_lot_details
          WHERE  mov_lot_dtl_id = lr_lot_rec.mov_lot_dtl_id
          ;
--
          /*
          UPDATE �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
          SET �p�[�W���s�� = SYSDATE
              ,  �p�[�W�v��ID = �v��ID
          WHERE ���b�g�ڍ�ID = lr_lot_rec�D���b�g�ڍ�ID
           */
          lv_process_part := '�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v�X�V';
          UPDATE xxcmn_mov_lot_details_arc
          SET    purge_date       = SYSDATE
                ,purge_request_id = cn_request_id
          WHERE  mov_lot_dtl_id   = lr_lot_rec.mov_lot_dtl_id
          ;
--
          /*
          ln_���R�~�b�g�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j := ln_���R�~�b�g�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j + 1;
           */
          ln_del_cnt_lot_yet := ln_del_cnt_lot_yet + 1;
--
        END LOOP purge_mov_lot_dtl_loop;
--
        -- ===============================================
        -- �󒍖��ׁi�A�h�I���j�p�[�W
        -- ===============================================
        /*
        DELETE �󒍖��ׁi�A�h�I���j
        WHERE �󒍖��׃A�h�I��ID = lr_line_rec�D�󒍖��׃A�h�I��ID
         */
        lv_process_part := '�󒍖��ׁi�A�h�I���j�p�[�W';
        DELETE xxwsh_order_lines_all
        WHERE  order_line_id = lr_line_rec.order_line_id
        ;
--
        /*
        UPDATE �󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
        SET �p�[�W���s�� = SYSDATE
            ,  �p�[�W�v��ID = �v��ID
        WHERE �󒍖��׃A�h�I��ID = lr_line_rec�D�󒍖��׃A�h�I��ID
         */
        lv_process_part := '�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v�X�V';
        UPDATE xxcmn_order_lines_all_arc
        SET    purge_date       = SYSDATE
              ,purge_request_id = cn_request_id
        WHERE  order_line_id    = lr_line_rec.order_line_id
        ;
--
        /*
        ln_���R�~�b�g�폜�����i�󒍖��ׁi�A�h�I���j�j := ln_���R�~�b�g�폜�����i�󒍖��ׁi�A�h�I���j�j + 1;
         */
        ln_del_cnt_line_yet := ln_del_cnt_line_yet + 1;
--
      END LOOP purge_order_line_loop;
--
      -- ===============================================
      -- �󒍃w�b�_�i�A�h�I���j�p�[�W
      -- ===============================================
      /*
      DELETE �󒍃w�b�_�i�A�h�I���j
      WHERE �󒍃w�b�_�A�h�I��ID = lr_header_rec�D�󒍃w�b�_�A�h�I��ID
       */
      lv_process_part := '�󒍃w�b�_�i�A�h�I���j�p�[�W';
      DELETE xxwsh_order_headers_all
      WHERE  order_header_id = lr_header_rec.order_header_id
      ;
--
      /*
      UPDATE �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
      SET �p�[�W���s�� = SYSDATE
          ,  �p�[�W�v��ID = �v��ID
      WHERE �󒍃w�b�_�A�h�I��ID = lr_header_rec�D�󒍃w�b�_�A�h�I��ID
       */
      lv_process_part := '�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�X�V';
      UPDATE xxcmn_order_headers_all_arc
      SET    purge_date       = SYSDATE
            ,purge_request_id = cn_request_id
      WHERE  order_header_id  = lr_header_rec.order_header_id
      ;
--
      /*
      ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j := ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j + 1;
       */
      ln_del_cnt_header_yet := ln_del_cnt_header_yet + 1;
--
    END LOOP purge_order_header_loop;
--
    /*
    ln_�폜�����i�󒍃w�b�_�i�A�h�I���j�j := ln_�폜�����i�󒍃w�b�_�i�A�h�I���j�j + ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j;
    ln_�폜�����i�󒍖��ׁi�A�h�I���j�j := ln_�폜�����i�󒍖��ׁi�A�h�I���j�j + ln_���R�~�b�g�폜�����i�󒍖��ׁi�A�h�I���j�j;
    ln_�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j := ln_�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j + ln_���R�~�b�g�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j;
    ln_���R�~�b�g�폜�����i�󒍃w�b�_�i�A�h�I���j�j := 0;
    ln_���R�~�b�g�폜�����i�󒍖��ׁi�A�h�I���j�j := 0;
    ln_���R�~�b�g�폜�����i�ړ����b�g�ڍׁi�A�h�I���j�j := 0;
     */
    gn_del_cnt_header     := gn_del_cnt_header + ln_del_cnt_header_yet;
    gn_del_cnt_line       := gn_del_cnt_line   + ln_del_cnt_line_yet;
    gn_del_cnt_lot        := gn_del_cnt_lot    + ln_del_cnt_lot_yet;
    ln_del_cnt_header_yet := 0;
    ln_del_cnt_line_yet   := 0;
    ln_del_cnt_lot_yet    := 0;
--
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
      IF ( gt_order_header_id IS NOT NULL ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_order_header_id)
                     );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||cv_msg_part||SQLERRM;
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
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ��TBL_NAME ��SHORI �����F ��CNT ��
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- �������b�Z�[�W�p�g�[�N�����i�����j
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- �������b�Z�[�W�p�g�[�N�����i�e�[�u�����j
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- �������b�Z�[�W�p�g�[�N�����i�������j
    cv_table_cnt_xoha   CONSTANT VARCHAR2(100) := '�󒍃w�b�_(�A�h�I��)';        -- �������b�Z�[�W�p�e�[�u����
    cv_table_cnt_xola   CONSTANT VARCHAR2(100) := '�󒍖���(�A�h�I��)';          -- �������b�Z�[�W�p�e�[�u����
    cv_table_cnt_xmld   CONSTANT VARCHAR2(100) := '�ړ����b�g����(�A�h�I��)';    -- �������b�Z�[�W�p�e�[�u����
    cv_shori_cnt_delete CONSTANT VARCHAR2(100) := '�폜';                -- �������b�Z�[�W�p������
    cv_target_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11008';  -- �Ώی����F ��CNT ��
    cv_success_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- ���팏���F ��CNT ��
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- �G���[�����F ��CNT ��
    cv_proc_date_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- �������F ��PAR
    cv_par_token        CONSTANT VARCHAR2(100) := 'PAR';              -- ���������b�Z�[�W�p�g�[�N����
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
    --�������o��
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_proc_date -- 1.������
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- header�폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xoha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt_header)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --line�폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xola
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt_line)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --lot�폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmld
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt_lot)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���팏���o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_del_cnt_header)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    IF (lv_retcode = cv_status_error) THEN
--
      gn_error_cnt := 1;
--
    ELSE
--
      gn_error_cnt := 0;
--
    END IF;
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
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
END XXCMN960001C;
/
