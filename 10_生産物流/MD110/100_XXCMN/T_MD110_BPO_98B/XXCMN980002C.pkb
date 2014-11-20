CREATE OR REPLACE PACKAGE BODY XXCMN980002C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980002C(body)
 * Description      : ���Y�����ڍ׃A�h�I���o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_98B_���Y�����ڍ׃A�h�I���o�b�N�A�b�v
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
 *  2012/12/07   1.00   Miyamoto         �V�K�쐬
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
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_conc_name     VARCHAR2(30);
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_arc_cnt_header         NUMBER;                                             -- �o�b�N�A�b�v����(�ړ��˗�/�w���w�b�_(�A�h�I��))
  gn_arc_cnt_line           NUMBER;                                             -- �o�b�N�A�b�v����(�ړ��˗�/�w������(�A�h�I��))
  gn_arc_cnt_lot            NUMBER;                                             -- �o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��))
  gt_batch_header_id        gme_batch_header.batch_id%TYPE;                     -- �Ώۃo�b�`�w�b�_ID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN980002C'; -- �p�b�P�[�W��
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
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    cv_appl_short_name          CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_get_priod_msg            CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';  -- �o�b�N�A�b�v���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_profile_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_local_others_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-11026';  -- ��SHORI �����Ɏ��s���܂����B�y ��KINOUMEI �z ��KEYNAME �F ��KEY
    cv_token_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_shori              CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_token_kinoumei           CONSTANT VARCHAR2(10)  := 'KINOUMEI';
    cv_token_keyname            CONSTANT VARCHAR2(10)  := 'KEYNAME';
    cv_token_key                CONSTANT VARCHAR2(10)  := 'KEY';
    cv_token_proc_date          CONSTANT VARCHAR2(100) := '������';
    cv_token_bkup               CONSTANT VARCHAR2(100) := '�o�b�N�A�b�v';
    cv_token_xmd                CONSTANT VARCHAR2(100) := '���Y�����ڍ�(�A�h�I��)';
    cv_token_xmld               CONSTANT VARCHAR2(100) := '�ړ����b�g�ڍ�(�A�h�I��)';
    cv_token_batch_id           CONSTANT VARCHAR2(100) := '�o�b�`ID';
    cv_token_param              CONSTANT VARCHAR2(50)  := 'ERROR_PARAM';
    cv_token_value              CONSTANT VARCHAR2(50)  := 'ERROR_VALUE';
--
    cv_xxcmn_commit_range       CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_archive_range      CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';
--
    cv_doc_type_40              CONSTANT VARCHAR2(2)   := '40';
--
    cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_sqlerrm VARCHAR2(5000);
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_purge_type   CONSTANT VARCHAR2(1)  := '1';                               -- �p�[�W�^�C�v(1:�o�b�N�A�b�v��������)
    cv_purge_code   CONSTANT VARCHAR2(30) := '9801';                            -- �p�[�W��`�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_arc_cnt_header_yet     NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v����(�ړ��˗�/�w���w�b�_(�A�h�I��))
    ln_arc_cnt_line_yet       NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v����(�ړ��˗�/�w������(�A�h�I��))
    ln_arc_cnt_lot_yet        NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��))
    ln_archive_period         NUMBER;                                           -- �o�b�N�A�b�v����
    ln_archive_range          NUMBER;                                           -- �o�b�N�A�b�v�����W
    ld_standard_date          DATE;                                             -- ���
    ln_commit_range           NUMBER;                                           -- �����R�~�b�g��
    lv_process_part           VARCHAR2(1000);                                   -- ������
    ln_key_id                 NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    CURSOR ���Y�o�b�`�w�b�_�擾
      id_���       IN DATE,
      in_�o�b�N�A�b�v�����W IN NUMBER
    IS
      SELECT ���Y�o�b�`�w�b�_.�o�b�`ID
      FROM   ���Y�o�b�`�w�b�_
      WHERE  ���Y�o�b�`�w�b�_.�v��J�n�� >= id_���  - in_�o�b�N�A�b�v�����W
      AND    ���Y�o�b�`�w�b�_.�v��J�n�� <  id_���
      ;
    */
    CURSOR batch_header_cur(
      id_standard_date      DATE
     ,in_purge_range        NUMBER
    )
    IS
      SELECT /*+ INDEX(gbh GME_GBH_N01) */
              gbh.batch_id            AS batch_id
      FROM    gme_batch_header           gbh                    --���Y�ޯ�ͯ��
      WHERE   gbh.plan_start_date     >= id_standard_date - in_purge_range
      AND     gbh.plan_start_date     <  id_standard_date
      ;
--
    /*
    CURSOR �o�b�N�A�b�v�Ώې��Y�����ڍ�(�A�h�I��)�擾
       it_�o�b�`ID  IN ���Y�o�b�`�w�b�_.�o�b�`ID%TYPE
    IS
      SELECT
             ���Y�����ڍ�(�A�h�I��).�S�J����
      FROM   ���Y�����ڍ�,
             ���Y�����ڍ�(�A�h�I��)
      WHERE  ���Y�����ڍ�.�o�b�`ID = in_�o�b�`ID
      AND    ���Y�����ڍ�.���Y�����ڍ�ID  = ���Y�����ڍ�(�A�h�I��).���Y�����ڍ�ID
      AND NOT EXISTS (
               SELECT  1
               FROM ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v
               WHERE ���Y�����ڍ�(�A�h�I��).���Y�����ڍ׃A�h�I��ID = ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v.���Y�����ڍ׃A�h�I���h�c
               AND ROWNUM = 1
             )
      ;
    */
    CURSOR mdtl_addn_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmd.mtl_detail_addon_id      AS  mtl_detail_addon_id
             ,xmd.batch_id                 AS  batch_id
             ,xmd.material_detail_id       AS  material_detail_id
             ,xmd.item_id                  AS  item_id
             ,xmd.lot_id                   AS  lot_id
             ,xmd.instructions_qty         AS  instructions_qty
             ,xmd.invested_qty             AS  invested_qty
             ,xmd.return_qty               AS  return_qty
             ,xmd.mtl_prod_qty             AS  mtl_prod_qty
             ,xmd.mtl_mfg_qty              AS  mtl_mfg_qty
             ,xmd.location_code            AS  location_code
             ,xmd.plan_type                AS  plan_type
             ,xmd.plan_number              AS  plan_number
             ,xmd.created_by               AS  created_by
             ,xmd.creation_date            AS  creation_date
             ,xmd.last_updated_by          AS  last_updated_by
             ,xmd.last_update_date         AS  last_update_date
             ,xmd.last_update_login        AS  last_update_login
             ,xmd.request_id               AS  request_id
             ,xmd.program_application_id   AS  program_application_id
             ,xmd.program_id               AS  program_id
             ,xmd.program_update_date      AS  program_update_date
      FROM    gme_material_details       gmd,                    --���Y�����ڍ�
              xxwip_material_detail      xmd                     --���Y�����ڍ�(��޵�)
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmd.material_detail_id
      AND NOT EXISTS (
               SELECT  1
               FROM xxcmn_material_detail_arc xmda
               WHERE xmd.material_detail_id = xmda.material_detail_id
               AND ROWNUM = 1
             )
      ;
--
    /*
    CURSOR �o�b�N�A�b�v�Ώۈړ����b�g�ڍ�(�A�h�I��)�擾
       it_�o�b�`ID  IN ���Y�o�b�`�w�b�_.�o�b�`ID%TYPE
    IS
      SELECT
             �ړ����b�g�ڍ�(�A�h�I��).�S�J����
      FROM   ���Y�����ڍ�,
             �ړ����b�g�ڍ�(�A�h�I��)
      WHERE  ���Y�����ڍ�.�o�b�`ID = in_�o�b�`ID
      AND    ���Y�����ڍ�.���Y�����ڍ�ID  = �ړ����b�g�ڍ�(�A�h�I��).����ID
      AND    �ړ����b�g�ڍ�(�A�h�I��).�����^�C�v = '40' 
      AND NOT EXISTS (
               SELECT  1
               FROM    �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
               WHERE  �ړ����b�g�ڍ�(�A�h�I��).���b�g�ڍ�ID = �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v.���b�g�ڍ�ID 
               AND ROWNUM = 1
             )
    */
    CURSOR mlot_dtl_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmld.mov_lot_dtl_id                 AS mov_lot_dtl_id
             ,xmld.mov_line_id                    AS mov_line_id
             ,xmld.document_type_code             AS document_type_code
             ,xmld.record_type_code               AS record_type_code
             ,xmld.item_id                        AS item_id
             ,xmld.item_code                      AS item_code
             ,xmld.lot_id                         AS lot_id
             ,xmld.lot_no                         AS lot_no
             ,xmld.actual_date                    AS actual_date
             ,xmld.actual_quantity                AS actual_quantity
             ,xmld.before_actual_quantity         AS before_actual_quantity
             ,xmld.automanual_reserve_class       AS automanual_reserve_class
             ,xmld.created_by                     AS created_by
             ,xmld.creation_date                  AS creation_date
             ,xmld.last_updated_by                AS last_updated_by
             ,xmld.last_update_date               AS last_update_date
             ,xmld.last_update_login              AS last_update_login
             ,xmld.request_id                     AS request_id
             ,xmld.program_application_id         AS program_application_id
             ,xmld.program_id                     AS program_id
             ,xmld.program_update_date            AS program_update_date
             ,xmld.actual_confirm_class           AS actual_confirm_class
      FROM    gme_material_details       gmd,                    --���Y�����ڍ�
              xxinv_mov_lot_details      xmld                    --�ړ����b�g�ڍ�(��޵�)
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmld.mov_line_id
      AND     xmld.document_type_code  = cv_doc_type_40
      AND NOT EXISTS (
               SELECT  /*+ INDEX(xmlda XXINV_MOV_LOT_DETAILS_PK) */
                       1
               FROM    xxcmn_mov_lot_details_arc xmlda
               WHERE   xmld.mov_lot_dtl_id = xmlda.mov_lot_dtl_id
               AND ROWNUM = 1
             )
      ;
    TYPE l_batch_header_ttype   IS TABLE OF gme_batch_header.batch_id%TYPE    INDEX BY BINARY_INTEGER;
    TYPE l_mat_line_ttype     IS TABLE OF xxcmn_material_detail_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
    TYPE l_mov_lot_dtl_ttype  IS TABLE OF xxcmn_mov_lot_details_arc%ROWTYPE   INDEX BY BINARY_INTEGER;
    -- <�J�[�\����>���R�[�h�^
    l_batch_header_tab       l_batch_header_ttype;                               -- ���Y�o�b�`�w�b�_
    l_mat_line_tab           l_mat_line_ttype;                                   -- ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v�e�[�u��
    l_mov_lot_dtl_tab        l_mov_lot_dtl_ttype;                                -- �ړ����b�g�ڍ�(�A�h�I��)�e�[�u��
    l_mov_lot_dtl_key_tab    l_batch_header_ttype;                               -- �ړ����b�g�ڍ�(�A�h�I��)�o�b�`ID�p�e�[�u��
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
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_arc_cnt_header := 0;
    gn_arc_cnt_line   := 0;
    gn_arc_cnt_lot    := 0;
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
    ln_�o�b�N�A�b�v���� := �o�b�N�A�b�v���Ԏ擾���ʊ֐�(cv_�p�[�W��`�R�[�h);
     */
    lv_process_part := '�o�b�N�A�b�v���Ԏ擾';
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_archive_period IS NULL ) THEN
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
    lv_process_part := '�������擾';
    /*
    iv_proc_date��NULL�̏ꍇ
      ld_��� := �������擾���ʊ֐�����擾���������� - ln_�o�b�N�A�b�v����;
--
    iv_proc_date��NULL�łȂ��ꍇ
      ld_��� := TO_DATE(iv_proc_date,'YYYY/MM/DD') - ln_�o�b�N�A�b�v����;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
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
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��));
    ln_�o�b�N�A�b�v�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����W));
     */
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾(' || cv_xxcmn_commit_range || ')';
    ln_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    END IF;

    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾(' || cv_xxcmn_archive_range || ')';
    ln_archive_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_archive_range));
    IF ( ln_archive_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_archive_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    -- ===============================================
    -- �又��
    -- ===============================================
    /*
    OPEN ���Y�o�b�`�w�b�_�擾(
                                    ld_���
                                    ,ln_�o�b�N�A�b�v�����W 
                                   );
    FETCH ���Y�o�b�`�w�b�_�擾 BULK COLLECT INTO l_���Y�o�b�`�w�b�_�e�[�u��;
     */
    OPEN batch_header_cur(
                                    ld_standard_date
                                   ,ln_archive_range
                                   );
    FETCH batch_header_cur BULK COLLECT INTO l_batch_header_tab;
    /*
    gn_��������(���Y�o�b�`�w�b�_) := l_���Y�o�b�`�w�b�_�e�[�u��.COUNT;
    IF gn_��������(���Y�o�b�`�w�b�_) > 0 THEN
      BEGIN
        << batch_header_loop >>
        FOR ln_main_idx in 1 .. l_���Y�o�b�`�w�b�_�e�[�u��.COUNT
        LOOP
    */
    gn_arc_cnt_header := l_batch_header_tab.COUNT;
    IF ( gn_arc_cnt_header ) > 0 THEN
      BEGIN
        << batch_header_loop >>
        FOR ln_main_idx in 1 .. l_batch_header_tab.COUNT
        LOOP
--
          /*
          gt_�Ώۃo�b�`�w�b�_ID := ���Y�o�b�`�w�b�_�e�[�u��.�ړ��w�b�_ID;
           */
          gt_batch_header_id := l_batch_header_tab(ln_main_idx);
          -- ===============================================
          -- �����R�~�b�g
          -- ===============================================
          /*
          NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
           */
          IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
            /*
            ln_���R�~�b�g�o�b�N�A�b�v����(���Y�o�b�`�w�b�_) > 0
            ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v����(���Y�o�b�`�w�b�_), ln_�����R�~�b�g��) = 0�̏ꍇ
             */
            IF (  (ln_arc_cnt_header_yet > 0)
              AND (MOD(ln_arc_cnt_header_yet, ln_commit_range) = 0)
               )
            THEN
--
              /*
              FORALL ln_idx1 IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��))
                INSERT INTO ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v
                (
                  �S�J����
                , �o�b�N�A�b�v�o�^��
                , �o�b�N�A�b�v�v��ID
                )
                VALUES
                (
                  lt_���Y�����ڍ�(�A�h�I��)�e�[�u��(ln_idx1)�S�J����
                , SYSDATE
                , �v��ID
                )
               */
              BEGIN
                lv_process_part := '���Y�����ڍ�(�A�h�I��)�o�^�P';
                FORALL ln_idx IN 1..ln_arc_cnt_line_yet
                  INSERT INTO xxcmn_material_detail_arc VALUES l_mat_line_tab(ln_idx)
                ;
              EXCEPTION
                WHEN OTHERS THEN
                  ln_key_id := l_mat_line_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).batch_id;
                  ov_errmsg := xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_appl_short_name
                                ,iv_name         => cv_local_others_msg
                                ,iv_token_name1  => cv_token_shori
                                ,iv_token_value1 => cv_token_bkup
                                ,iv_token_name2  => cv_token_kinoumei
                                ,iv_token_value2 => cv_token_xmd
                                ,iv_token_name3  => cv_token_keyname
                                ,iv_token_value3 => cv_token_batch_id
                                ,iv_token_name4  => cv_token_key
                                ,iv_token_value4 => TO_CHAR(ln_key_id)
                               );
                  lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
                  RAISE local_process_expt;
              END;
--
              /*
              FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��))
                INSERT INTO �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
                (
                    �S�J����
                  , �o�b�N�A�b�v�o�^��
                  , �o�b�N�A�b�v�v��ID
                )
                VALUES
                (
                    �ړ����b�g�ڍ�(�A�h�I��)�e�[�u��(ln_idx)�S�J����
                  , SYSDATE
                  , �v��ID
                )
               */
              BEGIN
                lv_process_part := '�ړ����b�g�ڍ�(�A�h�I��)�o�^�P';
                FORALL ln_idx IN 1..ln_arc_cnt_lot_yet
                  INSERT INTO xxcmn_mov_lot_details_arc VALUES l_mov_lot_dtl_tab(ln_idx)
                ;
              EXCEPTION
                WHEN OTHERS THEN
                  ln_key_id := l_mov_lot_dtl_key_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX);
                  ov_errmsg := xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_appl_short_name
                                ,iv_name         => cv_local_others_msg
                                ,iv_token_name1  => cv_token_shori
                                ,iv_token_value1 => cv_token_bkup
                                ,iv_token_name2  => cv_token_kinoumei
                                ,iv_token_value2 => cv_token_xmld
                                ,iv_token_name3  => cv_token_keyname
                                ,iv_token_value3 => cv_token_batch_id
                                ,iv_token_name4  => cv_token_key
                                ,iv_token_value4 => TO_CHAR(ln_key_id)
                               );
                  lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
                  RAISE local_process_expt;
              END;
--
              /*
              ln_���R�~�b�g����(���Y�o�b�`�w�b�_)   := 0;
              */
              ln_arc_cnt_header_yet := 0;
--
              /*
              gn_�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��)) := gn_�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��)) 
                                                              + ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��));
              ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��)) := 0;
              l_���Y�����ڍ�(�A�h�I��)�e�[�u��.DELETE;
              */
              gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
              ln_arc_cnt_line_yet := 0;
              l_mat_line_tab.DELETE;
--
              /*
              gn_�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)) := gn_�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)) 
                                                              + ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��));
              ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)) := 0;
              l_�ړ����b�g�ڍ�(�A�h�I��)�e�[�u��.DELETE;
               */
              gn_arc_cnt_lot     := gn_arc_cnt_lot + ln_arc_cnt_lot_yet;
              ln_arc_cnt_lot_yet := 0;
              l_mov_lot_dtl_tab.DELETE;
              l_mov_lot_dtl_key_tab.DELETE;
--
              /*
              COMMIT;
               */
              COMMIT;
--
            END IF;
--
          END IF;
--
--
          -- ===============================================
          -- �o�b�N�A�b�v�Ώې��Y�����ڍ�(�A�h�I��)�擾
          -- ===============================================
          /*
          FOR lr_mdtl_addn_rec IN �o�b�N�A�b�v�Ώې��Y�����ڍ�(�A�h�I��)�擾 (gt_�Ώۃo�b�`�w�b�_ID) LOOP
           */
          << archive_mov_line_loop >>
          FOR lr_mdtl_addn_rec IN mdtl_addn_cur(
                               gt_batch_header_id
                             )
          LOOP
            /*
            ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��)) := ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��)) + 1;
            lt_���Y�����ڍ�(�A�h�I��)�e�[�u��(ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��))) := lr_mdtl_addn_rec;
             */
            ln_arc_cnt_line_yet := ln_arc_cnt_line_yet + 1;
            l_mat_line_tab(ln_arc_cnt_line_yet).mtl_detail_addon_id     := lr_mdtl_addn_rec.mtl_detail_addon_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).batch_id                := lr_mdtl_addn_rec.batch_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).material_detail_id      := lr_mdtl_addn_rec.material_detail_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).item_id                 := lr_mdtl_addn_rec.item_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).lot_id                  := lr_mdtl_addn_rec.lot_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).instructions_qty        := lr_mdtl_addn_rec.instructions_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).invested_qty            := lr_mdtl_addn_rec.invested_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).return_qty              := lr_mdtl_addn_rec.return_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).mtl_prod_qty            := lr_mdtl_addn_rec.mtl_prod_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).mtl_mfg_qty             := lr_mdtl_addn_rec.mtl_mfg_qty;
            l_mat_line_tab(ln_arc_cnt_line_yet).location_code           := lr_mdtl_addn_rec.location_code;
            l_mat_line_tab(ln_arc_cnt_line_yet).plan_type               := lr_mdtl_addn_rec.plan_type;
            l_mat_line_tab(ln_arc_cnt_line_yet).plan_number             := lr_mdtl_addn_rec.plan_number;
            l_mat_line_tab(ln_arc_cnt_line_yet).created_by              := lr_mdtl_addn_rec.created_by;
            l_mat_line_tab(ln_arc_cnt_line_yet).creation_date           := lr_mdtl_addn_rec.creation_date;
            l_mat_line_tab(ln_arc_cnt_line_yet).last_updated_by         := lr_mdtl_addn_rec.last_updated_by;
            l_mat_line_tab(ln_arc_cnt_line_yet).last_update_date        := lr_mdtl_addn_rec.last_update_date;
            l_mat_line_tab(ln_arc_cnt_line_yet).last_update_login       := lr_mdtl_addn_rec.last_update_login;
            l_mat_line_tab(ln_arc_cnt_line_yet).request_id              := lr_mdtl_addn_rec.request_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).program_application_id  := lr_mdtl_addn_rec.program_application_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).program_id              := lr_mdtl_addn_rec.program_id;
            l_mat_line_tab(ln_arc_cnt_line_yet).program_update_date     := lr_mdtl_addn_rec.program_update_date;
            l_mat_line_tab(ln_arc_cnt_line_yet).archive_date               := SYSDATE;
            l_mat_line_tab(ln_arc_cnt_line_yet).archive_request_id         := cn_request_id;
--
          END LOOP archive_mov_line_loop;
          -- ===============================================
          -- �o�b�N�A�b�v�Ώۈړ����b�g�ڍ�(�A�h�I��)�擾
          -- ===============================================
          /*
          FOR lr_lot_rec IN �o�b�N�A�b�v�Ώۈړ����b�g�ڍ�(�A�h�I��)�擾(gt_�Ώۃo�b�`�w�b�_ID) LOOP
           */
          << archive_mov_lot_dtl_loop >>
          FOR lr_lot_rec IN mlot_dtl_cur(
                             gt_batch_header_id
                            )
          LOOP
--
            /*
            ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)) := ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)) + 1;
            l_�ړ����b�g�ڍ�(�A�h�I��)�e�[�u��(ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)) := lr_lot_rec;
             */
            ln_arc_cnt_lot_yet := ln_arc_cnt_lot_yet + 1;
            l_mov_lot_dtl_key_tab(ln_arc_cnt_lot_yet)                      := gt_batch_header_id;           --�R�t���o�b�`ID��ʃR���N�V�����Ɋi�[
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).mov_lot_dtl_id           := lr_lot_rec.mov_lot_dtl_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).mov_line_id              := lr_lot_rec.mov_line_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).document_type_code       := lr_lot_rec.document_type_code;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).record_type_code         := lr_lot_rec.record_type_code;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).item_id                  := lr_lot_rec.item_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).item_code                := lr_lot_rec.item_code;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).lot_id                   := lr_lot_rec.lot_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).lot_no                   := lr_lot_rec.lot_no;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).actual_date              := lr_lot_rec.actual_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).actual_quantity          := lr_lot_rec.actual_quantity;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).before_actual_quantity   := lr_lot_rec.before_actual_quantity;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).automanual_reserve_class := lr_lot_rec.automanual_reserve_class;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).created_by               := lr_lot_rec.created_by;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).creation_date            := lr_lot_rec.creation_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).last_updated_by          := lr_lot_rec.last_updated_by;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).last_update_date         := lr_lot_rec.last_update_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).last_update_login        := lr_lot_rec.last_update_login;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).request_id               := lr_lot_rec.request_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).program_application_id   := lr_lot_rec.program_application_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).program_id               := lr_lot_rec.program_id;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).program_update_date      := lr_lot_rec.program_update_date;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).actual_confirm_class     := lr_lot_rec.actual_confirm_class;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).archive_date             := SYSDATE;
            l_mov_lot_dtl_tab(ln_arc_cnt_lot_yet).archive_request_id       := cn_request_id;
--
          END LOOP archive_mov_lot_dtl_loop;
--
          /*
          ln_���R�~�b�g����(���Y�o�b�`�w�b�_) := ln_���R�~�b�g����(���Y�o�b�`�w�b�_) + 1;
          */
          ln_arc_cnt_header_yet := ln_arc_cnt_header_yet + 1;
--
        END LOOP archive_mov_header_loop;
        -- ===============================================
        -- �����R�~�b�g�ΏۊO�̎c�f�[�^ INSERT����
        -- ===============================================
        /*
        -- ���Y�����ڍ�(�A�h�I��)
        FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��))
            INSERT INTO ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v
            (
               �S�J����
             , �o�b�N�A�b�v�o�^��
             , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
              lt_���Y�����ڍ�(�A�h�I��)�e�[�u��(ln_idx)�S�J����
            , SYSDATE
            , �v��ID
            )
        */
        lv_process_part := '���Y�����ڍ�(�A�h�I��)�o�^�Q';
        BEGIN
          FORALL ln_idx IN 1..ln_arc_cnt_line_yet
            INSERT INTO xxcmn_material_detail_arc VALUES l_mat_line_tab(ln_idx)
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_key_id := l_mat_line_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).batch_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_msg
                          ,iv_token_name1  => cv_token_shori
                          ,iv_token_value1 => cv_token_bkup
                          ,iv_token_name2  => cv_token_kinoumei
                          ,iv_token_value2 => cv_token_xmd
                          ,iv_token_name3  => cv_token_keyname
                          ,iv_token_value3 => cv_token_batch_id
                          ,iv_token_name4  => cv_token_key
                          ,iv_token_value4 => TO_CHAR(ln_key_id)
                         );
            lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
            RAISE local_process_expt;
        END;
--
        /*
        --�ړ����b�g�ڍ�(�A�h�I��)
        FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��))
            INSERT INTO �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
            (
               �S�J����
             , �o�b�N�A�b�v�o�^��
             , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
              lt_�ړ����b�g�ڍ�(�A�h�I��)�e�[�u��(ln_idx)�S�J����
            , SYSDATE
            , �v��ID
            )
         */
        lv_process_part := '�ړ����b�g�ڍ�(�A�h�I��)�o�^�Q';
        BEGIN
          FORALL ln_idx IN 1..ln_arc_cnt_lot_yet
            INSERT INTO xxcmn_mov_lot_details_arc VALUES l_mov_lot_dtl_tab(ln_idx)
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ln_key_id := l_mov_lot_dtl_key_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX);
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_msg
                          ,iv_token_name1  => cv_token_shori
                          ,iv_token_value1 => cv_token_bkup
                          ,iv_token_name2  => cv_token_kinoumei
                          ,iv_token_value2 => cv_token_xmld
                          ,iv_token_name3  => cv_token_keyname
                          ,iv_token_value3 => cv_token_batch_id
                          ,iv_token_name4  => cv_token_key
                          ,iv_token_value4 => TO_CHAR(ln_key_id)
                         );
            lv_sqlerrm := SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
            RAISE local_process_expt;
        END;
        /*
        gn_�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��))  := gn_�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��))
                                                       + ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��));
        gn_�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)):= gn_�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��))
                                                       + ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��));
        ln_���R�~�b�g�o�b�N�A�b�v����(���Y�o�b�`�w�b�_)         := 0;
        ln_���R�~�b�g�o�b�N�A�b�v����(���Y�����ڍ�(�A�h�I��))   := 0;
        ln_���R�~�b�g�o�b�N�A�b�v����(�ړ����b�g�ڍ�(�A�h�I��)) := 0;
        lt_���Y�����ڍ�(�A�h�I��)�e�[�u��.DELETE;
        lt_�ړ����b�g�ڍ�(�A�h�I��)�e�[�u��.DELETE;
         */
        gn_arc_cnt_line     := gn_arc_cnt_line + ln_arc_cnt_line_yet;
        gn_arc_cnt_lot     := gn_arc_cnt_lot + ln_arc_cnt_lot_yet;
        ln_arc_cnt_header_yet := 0;
        ln_arc_cnt_line_yet := 0;
        ln_arc_cnt_lot_yet := 0;
        l_mat_line_tab.DELETE;
        l_mov_lot_dtl_tab.DELETE;
        l_mov_lot_dtl_key_tab.DELETE;
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE local_process_expt;
      END;
--
    END IF;
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN local_process_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_sqlerrm;
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
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCMN';                          -- �A�h�I���F���ʁEIF�̈�
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';                -- ��TBL_NAME ��SHORI �����F ��CNT ��
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                            -- �������b�Z�[�W�p�g�[�N����(����)
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                       -- �������b�Z�[�W�p�g�[�N����(�e�[�u����)
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                          -- �������b�Z�[�W�p�g�[�N����(������)
    cv_table_cnt_xmda   CONSTANT VARCHAR2(100) := '���Y�����ڍ�(�A�h�I��)';         -- �������b�Z�[�W�p�e�[�u����
    cv_table_cnt_xmld   CONSTANT VARCHAR2(100) := '�ړ����b�g����(�A�h�I��)';       -- �������b�Z�[�W�p�e�[�u����
    cv_shori_cnt_arc    CONSTANT VARCHAR2(100) := '�o�b�N�A�b�v';                   -- �������b�Z�[�W�p������
    cv_success_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';                -- ���팏���F ��CNT ��
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';                -- �G���[�����F ��CNT ��
    cv_proc_date_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';                -- �������F ��PAR
    cv_par_token        CONSTANT VARCHAR2(100) := 'PAR';                            -- ���������b�Z�[�W�p�g�[�N����
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
       iv_proc_date -- 1.������
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --line�o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmda
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_line)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --lot�o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmld
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_lot)
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
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_line)
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
END XXCMN980002C;
/
