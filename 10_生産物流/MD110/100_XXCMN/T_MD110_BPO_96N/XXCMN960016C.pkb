CREATE OR REPLACE PACKAGE BODY XXCMN960016C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960016C(body)
 * Description      : OPM�����g�����o�b�N�A�b�v�E�X�V
 * MD.050           : T_MD050_BPO_96N_OPM�����g�����o�b�N�A�b�v�E�X�V
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
 *  2012/12/03   1.00  K.Boku            �V�K�쐬
 *  2013/02/13   1.01  M.Kitajima        �����e�X�g�s�(IT_0018)�Ή�
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
  gn_arc_cnt       NUMBER;                                    -- �o�b�N�A�b�v�����i OPM�����݌Ƀg�����U�N�V�����i�W���j�j
  gn_upd_cnt       NUMBER;                                    -- �X�V�����i OPM�����݌Ƀg�����U�N�V�����i�W���j�j
  gt_tran_id       xxcmn_ic_tran_cmp_arc.trans_id%TYPE;       -- �Ώۊ����݌Ƀg�����U�N�V����ID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960002C'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_ic_tran_cmp_arc_ttype IS TABLE OF xxcmn_ic_tran_cmp_arc%ROWTYPE INDEX BY BINARY_INTEGER;
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
    cv_get_priod_arc_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';  -- �o�b�N�A�b�v���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_priod_purdge_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- �p�[�W���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_profile_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_local_others_arc_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11036';  -- �o�b�N�A�b�v�����Ɏ��s���܂����B�yOPM�����݌Ƀg�����U�N�V�����i�W���j�z�g�����U�N�V����ID�F ��KEY
    cv_local_others_upd_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11037';  -- �X�V�����Ɏ��s���܂����B�yOPM�����݌Ƀg�����U�N�V�����i�W���j�z�g�����U�N�V����ID�F ��KEY
    cv_token_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key                CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range       CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_archive_range      CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';
    cv_xxcmn_purdge_range       CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';
--
    cv_adji                     CONSTANT VARCHAR2(4)   := 'ADJI';
--
    cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
    cv_gl_post_fla             CONSTANT NUMBER  := 1;
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
    cv_purge_type_1   CONSTANT VARCHAR2(1)  := '1';                               -- �p�[�W�^�C�v�i1:�o�b�N�A�b�v�������ԁj
    cv_purge_type_0   CONSTANT VARCHAR2(1)  := '0';                               -- �p�[�W�^�C�v�i0:�p�[�W�������ԁj
    cv_purge_code     CONSTANT VARCHAR2(30) := '9601';                            -- �p�[�W��`�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_arc_cnt_yet            NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
    ln_upd_cnt_line_yet       NUMBER DEFAULT 0;                                 -- ���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
    ln_archive_period         NUMBER;                                           -- �o�b�N�A�b�v����
    ln_purge_period           NUMBER;                                           -- �p�[�W����
    ln_archive_range          NUMBER;                                           -- �o�b�N�A�b�v�����W
    ln_purge_range            NUMBER;                                           -- �p�[�W�����W
    ld_standard_date_arc      DATE;                                             -- ����i�o�b�N�A�b�v�j
    ld_standard_date_purdge   DATE;                                             -- ����i�p�[�W�j
    ln_commit_range           NUMBER;                                           -- �����R�~�b�g��
    lv_process_part           VARCHAR2(1000);                                   -- ������
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    -- �o�b�N�A�b�v�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾
    CURSOR �o�b�N�A�b�v�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾
      id_���  IN DATE
      in_�o�b�N�A�b�v IN NUMBER
    IS
      SELECT 
             OPM�����݌Ƀg�����U�N�V�����i�W���j�D�S�J����
      FROM OPM�W���[�i���}�X�^(�W��)
           ,    OPM�݌ɒ����W���[�i��(�W��)
           ,    OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE OPM�W���[�i���}�X�^(�W��)�DDFF1 IS NULL
      AND OPM�݌ɒ����W���[�i��(�W��)�D�W���[�i��ID = OPM�W���[�i���}�X�^(�W��)�D�W���[�i��ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = OPM�݌ɒ����W���[�i��(�W��)�D�����^�C�v
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D����ID = OPM�݌ɒ����W���[�i��(�W��)�D����ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D������הԍ� = OPM�݌ɒ����W���[�i��(�W��)�D������הԍ�
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = 'ADJI'
      AND OPM�����݌Ƀg�����U�N�V�����D����� �� ����|in_�o�b�N�A�b�v
      AND OPM�����݌Ƀg�����U�N�V�����D����� �� ���
      AND NOT EXISTS (
               SELECT 1
               FROM OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
               WHERE OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D�g�����U�N�V����ID = OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
               AND ROWNUM = 1
             )
     */
    CURSOR archive_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
    )
    IS
      SELECT  /*+ LEADING(itc) USE_NL(itc iaj ijm) */
              itc.trans_id                  AS  trans_id
             ,itc.item_id                   AS item_id
             ,itc.line_id                   AS line_id
             ,itc.co_code                   AS co_code
             ,itc.orgn_code                 AS orgn_code
             ,itc.whse_code                 AS whse_code
             ,itc.lot_id                    AS lot_id
             ,itc.location                  AS location
             ,itc.doc_id                    AS doc_id
             ,itc.doc_type                  AS doc_type
             ,itc.doc_line                  AS doc_line
             ,itc.line_type                 AS line_type
             ,itc.reason_code               AS reason_code
             ,itc.creation_date             AS creation_date
             ,itc.trans_date                AS trans_date
             ,itc.trans_qty                 AS trans_qty
             ,itc.trans_qty2                AS trans_qty2
             ,itc.qc_grade                  AS qc_grade
             ,itc.lot_status                AS lot_status
             ,itc.trans_stat                AS trans_stat
             ,itc.trans_um                  AS trans_um
             ,itc.trans_um2                 AS trans_um2
             ,itc.op_code                   AS op_code
             ,itc.gl_posted_ind             AS gl_posted_ind
             ,itc.event_id                  AS event_id
             ,itc.text_code                 AS text_code
             ,itc.last_update_date          AS last_update_date
             ,itc.created_by                AS created_by
             ,itc.last_updated_by           AS last_updated_by
             ,itc.last_update_login         AS last_update_login
             ,itc.program_application_id    AS program_application_id
             ,itc.program_id                AS program_id
             ,itc.program_update_date       AS program_update_date
             ,itc.request_id                AS request_id
             ,itc.movement_id               AS movement_id
             ,itc.mvt_stat_status           AS mvt_stat_status
             ,itc.line_detail_id            AS line_detail_id
             ,itc.invoiced_flag             AS invoiced_flag
             ,itc.staged_ind                AS staged_ind
             ,itc.intorder_posted_ind       AS intorder_posted_ind
             ,itc.lot_costed_ind            AS lot_costed_ind
      FROM    ic_jrnl_mst    ijm           -- OPM�W���[�i���}�X�^(�W��)
             ,ic_adjs_jnl    iaj           -- OPM�݌ɒ����W���[�i��(�W��)
             ,ic_tran_cmp    itc           -- OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE   ijm.attribute1 IS NULL
      AND     iaj.journal_id                = ijm.journal_id
      AND     itc.doc_type                  = iaj.trans_type
      AND     itc.doc_id                    = iaj.doc_id      
      AND     itc.doc_line                  = iaj.doc_line
      AND     itc.doc_type                  = cv_adji
      AND     itc.trans_date  >= id_standard_date - in_archive_range
      AND     itc.trans_date   < id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_cmp_arc  xitca
                WHERE   xitca.trans_id = itc.trans_id
                AND     ROWNUM                = 1
              )
    ;
    /*
    -- �X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j
    CURSOR �X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾
      id_���  IN DATE
      in_�p�[�W�����W IN NUMBER
    IS
      SELECT 
             OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
      FROM      OPM�W���[�i���}�X�^(�W��)
           ,    OPM�݌ɒ����W���[�i��(�W��)
           ,    OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
           ,    OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE  OPM�W���[�i���}�X�^(�W��)�DDFF1 IS NULL
      AND OPM�݌ɒ����W���[�i��(�W��)�D�W���[�i��ID = OPM�W���[�i���}�X�^(�W��)�D�W���[�i��ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�����^�C�v = OPM�݌ɒ����W���[�i��(�W��)�D�����^�C�v
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D����ID = OPM�݌ɒ����W���[�i��(�W��)�D����ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D������הԍ� = OPM�݌ɒ����W���[�i��(�W��)�D������הԍ�
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�����^�C�v = 'ADJI'
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D�g�����U�N�V����ID = OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�g�����U�N�V����ID
      AND OPM�����݌Ƀg�����U�N�V�����D����� �� ����|in_�p�[�W�����W
      AND OPM�����݌Ƀg�����U�N�V�����D����� �� ���
     */
    CURSOR upd_cur(
      id_standard_date          DATE
     ,in_purdge_range           NUMBER
    )
    IS
      SELECT /*+ LEADING(itc) USE_NL(itc xitca iaj ijm) */
              itc.trans_id             AS  trans_id
      FROM    ic_jrnl_mst              ijm     -- OPM�W���[�i���}�X�^(�W��)
             ,ic_adjs_jnl              iaj     -- OPM�݌ɒ����W���[�i��(�W��)
             ,xxcmn_ic_tran_cmp_arc    xitca   -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
             ,ic_tran_cmp              itc     -- OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE   ijm.attribute1 IS NULL
      AND     iaj.journal_id                = ijm.journal_id
      AND     itc.doc_type                  = iaj.trans_type
      AND     itc.doc_id                    = iaj.doc_id      
      AND     itc.doc_line                  = iaj.doc_line
      AND     itc.doc_type                  = cv_adji
      AND     itc.trans_id                  = xitca.trans_id
      AND     itc.trans_date  >= id_standard_date - in_purdge_range
      AND     itc.trans_date   < id_standard_date
    ;
    -- <�J�[�\����>���R�[�h�^
    lt_tran_cmp_arc_tbl       g_ic_tran_cmp_arc_ttype;           -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�e�[�u��
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
    gn_arc_cnt    := 0;
    gn_upd_cnt    := 0;
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
    ln_�o�b�N�A�b�v���� := �o�b�N�A�b�v���Ԏ擾���ʊ֐��icv_�p�[�W��`�R�[�h�j;
     */
    lv_process_part := '�o�b�N�A�b�v���Ԏ擾';
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type_1, cv_purge_code);
    IF ( ln_archive_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_arc_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �p�[�W���Ԏ擾
    -- ===============================================
    /*
    ln_�p�[�W���� := �p�[�W���Ԏ擾���ʊ֐��icv_�p�[�W��`�R�[�h�j;
     */
    lv_process_part := '�p�[�W���Ԏ擾';
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type_0, cv_purge_code);
    IF ( ln_purge_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_purdge_msg
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
      ld_���(�o�b�N�A�b�v) := �������擾���ʊ֐�����擾���������� - ln_�o�b�N�A�b�v����;
      ld_���(�p�[�W) := �������擾���ʊ֐�����擾���������� - ln_�p�[�W����;
--
    iv_proc_date��NULL�łȂ��̏ꍇ
--
      ld_���(�o�b�N�A�b�v) := TO_DATE(iv_proc_date) - ln_�o�b�N�A�b�v����;
      ld_���(�p�[�W) := TO_DATE(iv_proc_date) - ln_�p�[�W����;
     */
    lv_process_part := 'IN�p�����[�^�̊m�F';
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date_arc    := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
      ld_standard_date_purdge := xxcmn_common4_pkg.get_syori_date - ln_purge_period;
--
    ELSE
--
      ld_standard_date_arc    := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
      ld_standard_date_purdge := TO_DATE(iv_proc_date, cv_date_format) - ln_purge_period;
--
    END IF;
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��));
    ln_�o�b�N�A�b�v�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����W));
    ln_�p�[�W�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾�iXXCMN:�p�[�W�����W�j);					
     */
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j';
    ln_commit_range  := TO_NUMBER ( fnd_profile.value(cv_xxcmn_commit_range) );
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
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_archive_range || '�j';
    ln_archive_range := TO_NUMBER ( fnd_profile.value(cv_xxcmn_archive_range) );
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
--
    END IF;
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_purdge_range || '�j';
    ln_purge_range := TO_NUMBER ( fnd_profile.value(cv_xxcmn_purdge_range) );
    IF ( ln_purge_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_purdge_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �o�b�N�A�b�v�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾
    -- ===============================================
    /*
        FOR lr_trx_rec IN �o�b�N�A�b�v�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾�ild_���(�o�b�N�A�b�v)�Cln_�o�b�N�A�b�v�����W�j LOOP
     */
    << archive_loop >>
    FOR lr_archive_rec IN archive_cur(
                           ld_standard_date_arc
                          ,ln_archive_range
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
        ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j > 0
        ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
         */
        IF (  (ln_arc_cnt_yet > 0)
          AND (MOD(ln_arc_cnt_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
            INSERT INTO OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
            (
                �S�J����
              , �o�b�N�A�b�v�o�^��
              , �o�b�N�A�b�v�v��ID
            )
            VALUES
            (
                lt_OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�e�[�u���iln_idx�j�S�J����
              , SYSDATE
              , �v��ID
            )
          ;
           */
          lv_process_part := 'OPM�����݌Ƀg�����U�N�V�����i�W���j�o�^�P';
          FORALL ln_idx IN 1..ln_arc_cnt_yet
            INSERT INTO xxcmn_ic_tran_cmp_arc VALUES lt_tran_cmp_arc_tbl(ln_idx)
          ;
--
          /*
          lt_OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�e�[�u���DDELETE;
           */
          lt_tran_cmp_arc_tbl.DELETE;
--
          /*
          gn_�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := gn_�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
                                                                      + ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j;
          ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := 0;
          lt_OPM�����݌Ƀg�����U�N�V�����i�W���j�e�[�u���DDELETE;
           */
          gn_arc_cnt     := gn_arc_cnt + ln_arc_cnt_yet;
          ln_arc_cnt_yet := 0;
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
      /*
      ln_�Ώۊ����݌Ƀg�����U�N�V����ID := lr_trx_rec�D�g�����U�N�V����ID;
       */
      gt_tran_id := lr_archive_rec.trans_id;
--
      /*
      ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j�j := ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j�j + 1;
      lt_OPM�����݌Ƀg�����U�N�V�����i�W���j�e�[�u���iln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j�j := lr_archive_rec;
       */
      ln_arc_cnt_yet := ln_arc_cnt_yet + 1;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_id                     :=  lr_archive_rec.trans_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).item_id                      :=  lr_archive_rec.item_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).line_id                      :=  lr_archive_rec.line_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).co_code                      :=  lr_archive_rec.co_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).orgn_code                    :=  lr_archive_rec.orgn_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).whse_code                    :=  lr_archive_rec.whse_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).lot_id                       :=  lr_archive_rec.lot_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).location                     :=  lr_archive_rec.location;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).doc_id                       :=  lr_archive_rec.doc_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).doc_type                     :=  lr_archive_rec.doc_type;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).doc_line                     :=  lr_archive_rec.doc_line;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).line_type                    :=  lr_archive_rec.line_type;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).reason_code                  :=  lr_archive_rec.reason_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).creation_date                :=  lr_archive_rec.creation_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_date                   :=  lr_archive_rec.trans_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_qty                    :=  lr_archive_rec.trans_qty;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_qty2                   :=  lr_archive_rec.trans_qty2;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).qc_grade                     :=  lr_archive_rec.qc_grade;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).lot_status                   :=  lr_archive_rec.lot_status;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_stat                   :=  lr_archive_rec.trans_stat;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_um                     :=  lr_archive_rec.trans_um;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).trans_um2                    :=  lr_archive_rec.trans_um2;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).op_code                      :=  lr_archive_rec.op_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).gl_posted_ind                :=  lr_archive_rec.gl_posted_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).event_id                     :=  lr_archive_rec.event_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).text_code                    :=  lr_archive_rec.text_code;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).last_update_date             :=  lr_archive_rec.last_update_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).created_by                   :=  lr_archive_rec.created_by;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).last_updated_by              :=  lr_archive_rec.last_updated_by;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).last_update_login            :=  lr_archive_rec.last_update_login;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).program_application_id       :=  lr_archive_rec.program_application_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).program_id                   :=  lr_archive_rec.program_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).program_update_date          :=  lr_archive_rec.program_update_date;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).request_id                   :=  lr_archive_rec.request_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).movement_id                  :=  lr_archive_rec.movement_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).mvt_stat_status              :=  lr_archive_rec.mvt_stat_status;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).line_detail_id               :=  lr_archive_rec.line_detail_id;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).invoiced_flag                :=  lr_archive_rec.invoiced_flag;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).staged_ind                   :=  lr_archive_rec.staged_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).intorder_posted_ind          :=  lr_archive_rec.intorder_posted_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).lot_costed_ind               :=  lr_archive_rec.lot_costed_ind;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).archive_date                 :=  SYSDATE;
      lt_tran_cmp_arc_tbl(ln_arc_cnt_yet).archive_request_id           :=  cn_request_id;
--
    END LOOP archive_loop;
--
    /*
    FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
      INSERT INTO OPM�����݌Ƀg�����U�N�V�����i�A�h�I���j�o�b�N�A�b�v
      (
           �S�J����
        , �o�b�N�A�b�v�o�^��
        , �o�b�N�A�b�v�v��ID
      )
      VALUES
      (
          lt_OPM�����݌Ƀg�����U�N�V�����i�W���j�e�[�u���iln_idx�j�S�J����
        , SYSDATE
        , �v��ID
      )
    ;
     */
    lv_process_part := 'OPM�����݌Ƀg�����U�N�V�����i�W���j�o�^�Q';
    FORALL ln_idx IN 1..ln_arc_cnt_yet
      INSERT INTO xxcmn_ic_tran_cmp_arc VALUES lt_tran_cmp_arc_tbl(ln_idx)
    ;
--
    /*
    lt_OPM�����݌Ƀg�����U�N�V�����i�W���j�e�[�u���DDELETE;
     */
    lt_tran_cmp_arc_tbl.DELETE;
--
    /*
    gn_�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := gn_�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
                                                                 + ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j;
    ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := 0;
     */
    gn_arc_cnt     := gn_arc_cnt + ln_arc_cnt_yet;
    ln_arc_cnt_yet := 0;
    COMMIT;
--
    -- ===============================================
    -- �X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾
    -- ===============================================
    /*
        FOR lr_trx_rec IN �X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾�ild_���(�p�[�W)�Cln_�p�[�W�����W�j LOOP
     */
    << upd_loop >>
    FOR lr_upd_rec IN upd_cur(
                           ld_standard_date_purdge
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
        ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j > 0
        ���� MOD(ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
         */
        IF (  (ln_upd_cnt_line_yet > 0)
          AND (MOD(ln_upd_cnt_line_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          gn_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := gn_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j					
                                                                             + ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j;
          ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := 0;
           */
          gn_upd_cnt     := gn_upd_cnt + ln_upd_cnt_line_yet;
          ln_upd_cnt_line_yet := 0;
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
      /*
      ln_�Ώۊ����݌Ƀg�����U�N�V����ID := lr_trx_rec�D�g�����U�N�V����ID;
       */
      gt_tran_id := lr_upd_rec.trans_id;
--
      /*
      ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j�j := ln_���R�~�b�g�o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j�j + 1;
       */
      ln_upd_cnt_line_yet := ln_upd_cnt_line_yet + 1;
--
      -- ===================================================
      -- �X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�j���b�N
      -- ===================================================
      /*
      SELECT
            OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
      FROM OPM�����݌Ƀg�����U�N�V�����i�W���j
      WHERE OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID = lr_trx_rec�D�g�����U�N�V����ID
      FOR UPDATE NOWAIT
       */
      lv_process_part := '�X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�j���b�N';
      SELECT  /*+ INDEX(itc IC_TRAN_CMP_PK) */
              itc.trans_id      AS trans_id
      INTO    gt_tran_id
      FROM    ic_tran_cmp  itc
      WHERE   itc.trans_id = lr_upd_rec.trans_id
      FOR UPDATE NOWAIT
      ;
      -- ===============================================
      -- OPM�����݌Ƀg�����U�N�V�����i�W���j�X�V
      -- ===============================================
      /*
      UPDATE OPM�����݌Ƀg�����U�N�V�����i�W���j
      SET GL�]���σt���O = 1
         ,   �ŏI�X�V�� = SYSDATE
         ,   �ŏI�X�V�� = ���[�U�[ID
         ,   �ŏI�X�V���O�C�� = ���O�C��ID
         ,   �v���O�����A�v���P�[�V����ID = �v���O�����A�v���P�[�V����ID
         ,   �v���O����ID = �R���J�����g�v���O����ID
         ,   �v���O�����X�V�� = SYSDATE
         ,   ���N�G�X�gID = �R���J�����g���N�G�X�gID
      WHERE �g�����U�N�V����ID = lr_trx_rec�D�g�����U�N�V����ID
      ;
       */
      lv_process_part := 'OPM�����݌Ƀg�����U�N�V�����i�W���j�X�V';
      UPDATE ic_tran_cmp
      SET    gl_posted_ind            = cv_gl_post_fla
            ,last_update_date         = SYSDATE
            ,last_updated_by          = cn_last_updated_by
            ,last_update_login        = cn_last_update_login
            ,program_application_id   = cn_program_application_id
            ,program_id               = cn_program_id
            ,program_update_date      = SYSDATE
            ,request_id               = cn_request_id
      WHERE  trans_id = lr_upd_rec.trans_id
      ;
--
    END LOOP upd_loop;
--
    /*
    gn_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := gn_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
                                                                       + ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j;
    ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := 0;
     */
    gn_upd_cnt     := gn_upd_cnt + ln_upd_cnt_line_yet;
    ln_upd_cnt_line_yet := 0;
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
        IF ( SQL%BULK_EXCEPTIONS.COUNT > 0 ) THEN
--
          IF ( lt_tran_cmp_arc_tbl.COUNT > 0 ) THEN
            gt_tran_id := lt_tran_cmp_arc_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).trans_id;
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_arc_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(gt_tran_id)
                         );
          ELSE
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_upd_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(gt_tran_id)
                         );
          END IF;
        END IF;
        IF ( (ov_errmsg IS NULL) AND (gt_tran_id IS NOT NULL) ) THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_local_others_upd_msg
                          ,iv_token_name1  => cv_token_key
                          ,iv_token_value1 => TO_CHAR(gt_tran_id)
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_com_cnt_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';  -- �o�b�N�A�b�v�A�X�V������TBL_NAME ��SHORI �����F ��CNT ��
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- ���팏���F ��CNT ��
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- �G���[�����F ��CNT ��
    cv_proc_date_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- �������F ��PAR
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'CNT';              -- �������b�Z�[�W�p�g�[�N����
    cv_token_tbl_name  CONSTANT VARCHAR2(10)  := 'TBL_NAME';         -- �������b�Z�[�W�p�g�[�N����
    cv_token_shori     CONSTANT VARCHAR2(10)  := 'SHORI';            -- �������b�Z�[�W�p�g�[�N����
    cv_par_token       CONSTANT VARCHAR2(10)  := 'PAR';              -- ���������b�Z�[�W�p�g�[�N����
    cv_tbl_name_cmp    CONSTANT VARCHAR2(100) := 'OPM�����݌Ƀg�����U�N�V�����i�W���j';
    cv_upd             CONSTANT VARCHAR2(10)  := '�X�V';
    cv_arc             CONSTANT VARCHAR2(100) := '�o�b�N�A�b�v';
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
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
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
    --�o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_com_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_cmp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_arc
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�V�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_com_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_cmp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_upd
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_upd_cnt)
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
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt + gn_upd_cnt)
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
                    ,iv_token_name1  => cv_cnt_token
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
END XXCMN960016C;
/
