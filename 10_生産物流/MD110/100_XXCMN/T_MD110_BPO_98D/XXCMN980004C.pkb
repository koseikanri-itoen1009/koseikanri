CREATE OR REPLACE PACKAGE BODY XXCMN980004C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980004C(body)
 * Description      : �ۗ��݌�TRN�i�W���j�o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_98D_�ۗ��݌�TRN�i�W���j�o�b�N�A�b�v
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
 *  2012/11/02   1.00  T.Makuta          �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  cn_request_id      CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
--
  cv_purge_type      CONSTANT VARCHAR2(1)  := '1';                        --�߰������(1:BUCKUP����)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9801';                     --�߰�ޒ�`����
  cv_doc_type_p      CONSTANT VARCHAR2(5)  := 'PROD';                     --�����^�C�v
  --=============
  --���b�Z�[�W
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_archive_range
                     CONSTANT VARCHAR2(50) := 'XXCMN_ARCHIVE_RANGE';      --XXCMN:�ޯ������ݼ�
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
  cv_others_err_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11026';          --�ޯ����ߏ������s
  cv_token_shori     CONSTANT VARCHAR2(10) := 'SHORI';                    --�ޯ����ߏ���MSG�pİ�ݖ�
  cv_token_kinou     CONSTANT VARCHAR2(10) := 'KINOUMEI';                 --�ޯ����ߏ���MSG�pİ�ݖ�
  cv_token_key_name  CONSTANT VARCHAR2(10) := 'KEYNAME';                  --�ޯ����ߏ���MSG�pİ�ݖ�
  cv_token_key       CONSTANT VARCHAR2(10) := 'KEY';                      --�ޯ����ߏ���MSG�pİ�ݖ�
  cv_shori           CONSTANT VARCHAR2(50) := '�o�b�N�A�b�v';
  cv_kinou           CONSTANT VARCHAR2(90) := '�ۗ��݌�TRN�i�W���j';
  cv_key_name        CONSTANT VARCHAR2(50) := '�o�b�`ID';
--
  --TBL_NAME SHORI �����F CNT ��
  cv_end_msg         CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';          --�������e�o��
  cv_token_tblname   CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname         CONSTANT VARCHAR2(90) := 'OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j';
  cv_token_shori2    CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori2          CONSTANT VARCHAR2(50) := '�o�b�N�A�b�v';
  cv_cnt_token       CONSTANT VARCHAR2(10) := 'CNT';
---
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_error_cnt       NUMBER;                                     --�G���[����
  gn_arc_cnt_ictran  NUMBER;                                     --�ޯ����ߌ���
  gn_cnt_header      NUMBER;                                     --��������(���Y�ޯ�ͯ��)
  gn_cnt_header_yet  NUMBER;                                     --���ЯČ���(���Y�ޯ�ͯ��)
  gn_arc_cnt_opm_yet NUMBER;                                     --���Я��ޯ����ߌ���
  gt_batch_id        gme_batch_header.batch_id%TYPE;
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN980004C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE ic_tran_pnd_ttype IS TABLE OF xxcmn_ic_tran_pnd_arc%ROWTYPE INDEX BY BINARY_INTEGER;
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
    ln_archive_period         NUMBER;                           --�o�b�N�A�b�v����
    ln_archive_range          NUMBER;                           --�o�b�N�A�b�v�����W
    ld_standard_date          DATE;                             --���
    ln_commit_range           NUMBER;                           --�����R�~�b�g��
    lv_process_part           VARCHAR2(1000);                   -- ������
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    CURSOR �����Ώې��Y�o�b�`�w�b�_�擾
      id_���       IN DATE,
      in_�o�b�N�A�b�v�����W IN NUMBER
    IS
      SELECT ���Y�o�b�`�w�b�_.�o�b�`ID
      FROM   ���Y�o�b�`�w�b�_
      WHERE  ���Y�o�b�`�w�b�_.�v��J�n�� >= id_���  - in_�o�b�N�A�b�v�����W
      AND    ���Y�o�b�`�w�b�_.�v��J�n�� <  id_���
      ;
    */
    CURSOR b_header_cur(
      id_standard_date      DATE
     ,in_archive_range      NUMBER
    )
    IS
      SELECT /*+ INDEX(gbh GME_GBH_N01) */
              gbh.batch_id            AS batch_id
      FROM    gme_batch_header           gbh                    --���Y�ޯ�ͯ��
      WHERE   gbh.plan_start_date     >= id_standard_date - in_archive_range
      AND     gbh.plan_start_date     <  id_standard_date
      ;
    /*
    CURSOR �o�b�N�A�b�v�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����擾
       it_�o�b�`ID  IN ���Y�o�b�`�w�b�_.�o�b�`ID%TYPE
    IS
      SELECT
            OPM�ۗ��݌Ƀg�����U�N�V����.�S�J����,
             �o�b�N�A�b�v�o�^��,
             �o�b�N�A�b�v�v��ID,
             NULL,                  --�p�[�W���s��
             NULL                   --�p�[�W�v��ID
      FROM  OPM�ۗ��݌Ƀg�����U�N�V����,
            ���Y�����ڍ�
      WHERE ���Y�����ڍ�.�o�b�`ID          =  it_�o�b�`ID
      AND   ���Y�����ڍ�.���Y�����ڍ�ID = OPM�ۗ��݌Ƀg�����U�N�V����.����ID
      AND   OPM�ۗ��݌Ƀg�����U�N�V����.�����^�C�v = 'PROD'
      AND NOT EXISTS (SELECT  1
                       FROM OPM�ۗ��݌Ƀg�����U�N�V�����o�b�N�A�b�v
                       WHERE OPM�ۗ��݌Ƀg�����U�N�V�����o�b�N�A�b�v.�g�����U�N�V����ID = 
                                                   OPM�ۗ��݌Ƀg�����U�N�V����.�g�����U�N�V����ID
                       AND ROWNUM = 1
                      );
    */
--
    CURSOR ic_tran_pnd_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              itp.trans_id                AS trans_id,                    --�g�����U�N�V����ID
              itp.item_id                 AS item_id,
              itp.line_id                 AS line_id,                     --����ID
              itp.co_code                 AS co_code,
              itp.orgn_code               AS orgn_code,
              itp.whse_code               AS whse_code,
              itp.lot_id                  AS lot_id,
              itp.location                AS location,
              itp.doc_id                  AS doc_id,                      --����ID
              itp.doc_type                AS doc_type,                    --�����^�C�v
              itp.doc_line                AS doc_line,                    --������הԍ�
              itp.line_type               AS line_type,
              itp.reason_code             AS reason_code,                 --���R�R�[�h
              itp.creation_date           AS creation_date,
              itp.trans_date              AS trans_date,
              itp.trans_qty               AS trans_qty,
              itp.trans_qty2              AS trans_qty2,
              itp.qc_grade                AS qc_grade,
              itp.lot_status              AS lot_status,
              itp.trans_stat              AS trans_stat,
              itp.trans_um                AS trans_um,
              itp.trans_um2               AS trans_um2,
              itp.op_code                 AS op_code,
              itp.completed_ind           AS completed_ind,               --�����t���O
              itp.staged_ind              AS staged_ind,
              itp.gl_posted_ind           AS gl_posted_ind,
              itp.event_id                AS event_id,
              itp.delete_mark             AS delete_mark,
              itp.text_code               AS text_code,
              itp.last_update_date        AS last_update_date,
              itp.created_by              AS created_by,
              itp.last_updated_by         AS last_updated_by,
              itp.last_update_login       AS last_update_login,
              itp.program_application_id  AS program_application_id,
              itp.program_id              AS program_id,
              itp.program_update_date     AS program_update_date,
              itp.request_id              AS request_id,
              itp.reverse_id              AS reverse_id,
              itp.pick_slip_number        AS pick_slip_number,
              itp.mvt_stat_status         AS mvt_stat_status,
              itp.movement_id             AS movement_id,
              itp.line_detail_id          AS line_detail_id,
              itp.invoiced_flag           AS invoiced_flag,
              itp.intorder_posted_ind     AS intorder_posted_ind,
              itp.lot_costed_ind          AS lot_costed_ind,
              SYSDATE                     AS archive_date,           --�o�b�N�A�b�v�o�^��
              cn_request_id               AS archive_request_id,     --�o�b�N�A�b�v�v��ID
              NULL                        AS purge_date,             --�p�[�W���s��
              NULL                        AS purge_request_id        --�p�[�W�v��ID
      FROM    ic_tran_pnd                 itp,                       --OPM�ۗ��݌���ݻ޸���
              gme_material_details        gmd                        --���Y�����ڍ�
      WHERE   gmd.batch_id             =  it_batch_id
      AND     gmd.material_detail_id   =  itp.line_id
      AND     itp.doc_type             =  cv_doc_type_p              --PROD
      AND NOT EXISTS(SELECT 1
                     FROM  xxcmn_ic_tran_pnd_arc xitp                --OPM�ۗ��݌���ݻ޸����ޯ�����
                     WHERE xitp.trans_id = itp.trans_id
                     AND   ROWNUM        = 1
                    );
--
    -- <�J�[�\����>���R�[�h�^
    lt_ict_pnd_tbl      ic_tran_pnd_ttype;                           --OPM�ۗ��݌���ݻ޸���ð���
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
    gn_error_cnt       := 0;
    gn_cnt_header      := 0;
    gn_arc_cnt_ictran  := 0;
    gn_cnt_header_yet  := 0;
    gn_arc_cnt_opm_yet := 0;
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
    ln_�o�b�N�A�b�v���� := �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐��icv_�p�[�W�^�C�v,cv_�p�[�W�R�[�h�j;
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
      ld_��� := �������擾���ʊ֐�����擾���������� - ln_�o�b�N�A�b�v����;
--
    iv_proc_date��NULL�łȂ��ꍇ
--
      ld_��� := TO_DATE(iv_proc_date)                - ln_�o�b�N�A�b�v����;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date      - ln_archive_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
--
    END IF;
--
     -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j�F';
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����R�~�b�g��));
     */
    ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_archive_range || '�j�F';
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
    FOR lr_b_header_rec IN �����Ώې��Y�o�b�`�w�b�_�擾(ld_���,ln_�o�b�N�A�b�v�����W) LOOP
    */
    << backup_main >>
    FOR lr_b_header_rec IN b_header_cur(ld_standard_date
                                       ,ln_archive_range ) LOOP
--
      /*
      gt_�Ώې��Y�o�b�`ID := lr_b_header_rec.���Y�o�b�`ID;
      */
      gt_batch_id         := lr_b_header_rec.batch_id;
--
      /*
      FOR lr_ict_pnd_rec IN �o�b�N�A�b�v�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����擾
                                                                 (lr_b_header_rec.�o�b�`ID) LOOP
      */
      << ic_tran_pnd_loop >>
      FOR lr_ict_pnd_rec IN ic_tran_pnd_cur(lr_b_header_rec.batch_id) LOOP
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
          gn_���R�~�b�g����(���Y�o�b�`�w�b�_) > 0 ���� 
          MOD(gn_���R�~�b�g����(���Y�o�b�`�w�b�_), ln_�����R�~�b�g��) = 0�̏ꍇ
          */
          IF (  (gn_cnt_header_yet > 0)
            AND (MOD(gn_cnt_header_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            FORALL ln_idx IN 1..gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����)
              INSERT INTO OPM�ۗ��݌Ƀg�����U�N�V�����o�b�N�A�b�v
              (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
              )
              VALUES
              (
                lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��(ln_idx)�S�J����
              , SYSDATE
              , �v��ID
              )
            */
            FORALL ln_idx IN 1..gn_arc_cnt_opm_yet
              INSERT INTO xxcmn_ic_tran_pnd_arc VALUES lt_ict_pnd_tbl(ln_idx);
--
            /*
            gn_��������(���Y�o�b�`�w�b�_) := gn_��������(���Y�o�b�`�w�b�_) + 
                                                     gn_���R�~�b�g����(���Y�o�b�`�w�b�_);
            gn_���R�~�b�g����(���Y�o�b�`�w�b�_)   := 0;
            */
--
            gn_cnt_header     := gn_cnt_header + gn_cnt_header_yet;
            gn_cnt_header_yet := 0;
--
            /*
            gn_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) := 
                                      gn_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) + 
                                      gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����);
            gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) := 0;
            lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��.DELETE;
--
            COMMIT;
            */
--
            gn_arc_cnt_ictran  := gn_arc_cnt_ictran + gn_arc_cnt_opm_yet;
            gn_arc_cnt_opm_yet := 0;
            lt_ict_pnd_tbl.DELETE;
--
            COMMIT;
--
          END IF;
--
        END IF;
--
        -- --------------------------------------
        -- OPM�ۗ��݌Ƀg�����U�N�V���� �ϐ��ݒ�
        -- --------------------------------------
        /*
        gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) := 
                                    gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) + 1;
        lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��(gn_���R�~�b�g�o�b�N�A�b�v����
                                               (OPM�ۗ��݌Ƀg�����U�N�V����) := lr_ict_pnd_rec;
        */
        gn_arc_cnt_opm_yet := gn_arc_cnt_opm_yet + 1;
--
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_id            := lr_ict_pnd_rec.trans_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).item_id             := lr_ict_pnd_rec.item_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).line_id             := lr_ict_pnd_rec.line_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).co_code             := lr_ict_pnd_rec.co_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).orgn_code           := lr_ict_pnd_rec.orgn_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).whse_code           := lr_ict_pnd_rec.whse_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).lot_id              := lr_ict_pnd_rec.lot_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).location            := lr_ict_pnd_rec.location;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).doc_id              := lr_ict_pnd_rec.doc_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).doc_type            := lr_ict_pnd_rec.doc_type;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).doc_line            := lr_ict_pnd_rec.doc_line;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).line_type           := lr_ict_pnd_rec.line_type;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).reason_code         := lr_ict_pnd_rec.reason_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).creation_date       := lr_ict_pnd_rec.creation_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_date          := lr_ict_pnd_rec.trans_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_qty           := lr_ict_pnd_rec.trans_qty;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_qty2          := lr_ict_pnd_rec.trans_qty2;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).qc_grade            := lr_ict_pnd_rec.qc_grade;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).lot_status          := lr_ict_pnd_rec.lot_status;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_stat          := lr_ict_pnd_rec.trans_stat;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_um            := lr_ict_pnd_rec.trans_um;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).trans_um2           := lr_ict_pnd_rec.trans_um2;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).op_code             := lr_ict_pnd_rec.op_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).completed_ind       := lr_ict_pnd_rec.completed_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).staged_ind          := lr_ict_pnd_rec.staged_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).gl_posted_ind       := lr_ict_pnd_rec.gl_posted_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).event_id            := lr_ict_pnd_rec.event_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).delete_mark         := lr_ict_pnd_rec.delete_mark;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).text_code           := lr_ict_pnd_rec.text_code;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).last_update_date    := lr_ict_pnd_rec.last_update_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).created_by          := lr_ict_pnd_rec.created_by;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).last_updated_by     := lr_ict_pnd_rec.last_updated_by;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).last_update_login   := lr_ict_pnd_rec.last_update_login;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).program_application_id := 
                                                            lr_ict_pnd_rec.program_application_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).program_id          := lr_ict_pnd_rec.program_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).program_update_date := 
                                                            lr_ict_pnd_rec.program_update_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).request_id          := lr_ict_pnd_rec.request_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).reverse_id          := lr_ict_pnd_rec.reverse_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).pick_slip_number    := lr_ict_pnd_rec.pick_slip_number;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).mvt_stat_status     := lr_ict_pnd_rec.mvt_stat_status;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).movement_id         := lr_ict_pnd_rec.movement_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).line_detail_id      := lr_ict_pnd_rec.line_detail_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).invoiced_flag       := lr_ict_pnd_rec.invoiced_flag;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).intorder_posted_ind := 
                                                            lr_ict_pnd_rec.intorder_posted_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).lot_costed_ind      := lr_ict_pnd_rec.lot_costed_ind;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).archive_date        := lr_ict_pnd_rec.archive_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).archive_request_id  := 
                                                            lr_ict_pnd_rec.archive_request_id;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).purge_date          := lr_ict_pnd_rec.purge_date;
        lt_ict_pnd_tbl(gn_arc_cnt_opm_yet).purge_request_id    := lr_ict_pnd_rec.purge_request_id;
--
      END LOOP ic_tran_pnd_loop;
--
      /*
      gn_���R�~�b�g����(���Y�o�b�`�w�b�_) := gn_���R�~�b�g����(���Y�o�b�`�w�b�_) + 1;
      */
      gn_cnt_header_yet := gn_cnt_header_yet + 1;
--
    END LOOP backup_main;
--
    -- --------------------------------------------------------------------
    -- �����R�~�b�g�ΏۊO�̎c�f�[�^ INSERT����(OPM�ۗ��݌Ƀg�����U�N�V����)
    -- --------------------------------------------------------------------
    /*
    FORALL ln_idx IN 1..gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����)
      INSERT INTO OPM�ۗ��݌Ƀg�����U�N�V�����o�b�N�A�b�v
      (
        �S�J����
      , �o�b�N�A�b�v�o�^��
      , �o�b�N�A�b�v�v��ID
      )
      VALUES
      (
        OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��(ln_idx)�S�J����
      , SYSDATE
      , �v��ID
      )
      ;
    */
--
    FORALL ln_idx IN 1..gn_arc_cnt_opm_yet
      INSERT INTO xxcmn_ic_tran_pnd_arc VALUES lt_ict_pnd_tbl(ln_idx);
--
    /*
    gn_��������(���Y�o�b�`�w�b�_)         := gn_��������(���Y�o�b�`�w�b�_) + 
                                             gn_���R�~�b�g����(���Y�o�b�`�w�b�_);
    gn_���R�~�b�g����(���Y�o�b�`�w�b�_)   := 0;
    */
    gn_cnt_header     := gn_cnt_header + gn_cnt_header_yet;
    gn_cnt_header_yet := 0;
--
    /*
    gn_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) := 
                                        gn_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) + 
                                        gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����);
    gn_���R�~�b�g����(���Y�o�b�`�w�b�_) := 0;
    gn_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����) := 0;
    lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��.DELETE;
    */
--
    gn_arc_cnt_ictran  := gn_arc_cnt_ictran + gn_arc_cnt_opm_yet;
    gn_arc_cnt_opm_yet := 0;
    lt_ict_pnd_tbl.DELETE;
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
          IF ( lt_ict_pnd_tbl.COUNT > 0 ) THEN
            --�o�b�N�A�b�v�����Ɏ��s���܂����B�yOPM�ۗ��݌Ƀg�����U�N�V�����z�o�b�`ID: KEY
            ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_shori
                      ,iv_token_name2  => cv_token_kinou
                      ,iv_token_value2 => cv_kinou
                      ,iv_token_name3  => cv_token_key_name
                      ,iv_token_value3 => cv_key_name
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(gt_batch_id)
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
      IF ( (ov_errmsg IS NULL) AND (gt_batch_id IS NOT NULL) ) THEN
        --�o�b�N�A�b�v�����Ɏ��s���܂����B�yOPM�ۗ��݌Ƀg�����U�N�V�����z�o�b�`ID: KEY
            ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_shori
                      ,iv_token_name2  => cv_token_kinou
                      ,iv_token_value2 => cv_kinou
                      ,iv_token_name3  => cv_token_key_name
                      ,iv_token_value3 => cv_key_name
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(gt_batch_id)
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
    -- �ُ�I�����̌�������
    IF (lv_retcode = cv_status_error) AND (gn_cnt_header  = 0 ) THEN
        gn_arc_cnt_ictran := 0;
    END IF;
--
    --�ۗ��݌�TRN�i�W���j �o�b�N�A�b�v �����F CNT ��
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname
                      ,iv_token_name2  => cv_token_shori2
                      ,iv_token_value2 => cv_shori2
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_arc_cnt_ictran)
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
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_ictran)
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
END XXCMN980004C;
/
