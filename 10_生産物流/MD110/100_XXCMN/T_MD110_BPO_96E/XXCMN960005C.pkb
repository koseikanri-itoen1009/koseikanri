CREATE OR REPLACE PACKAGE BODY XXCMN960005C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960005C(body)
 * Description      : OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_96E_OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
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
 *  2012/11/19   1.00   Miyamoto         �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
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
  gn_arc_cnt_pnd            NUMBER;                                             -- �o�b�N�A�b�v�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j
  gn_arc_cnt_cmp            NUMBER;                                             -- �o�b�N�A�b�v�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
  gn_pnd_trans_id           ic_tran_pnd.trans_id%TYPE;                          -- �Ώ�OPM�ۗ��݌Ƀg�����U�N�V����ID
  gn_cmp_trans_id           ic_tran_cmp.trans_id%TYPE;                          -- �Ώ�OPM�����݌Ƀg�����U�N�V����ID
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
  cv_pkg_name       CONSTANT VARCHAR2(100) := 'XXCMN960005C'; -- �p�b�P�[�W��
  cv_proc_date_msg  CONSTANT VARCHAR2(50)  := 'APP-XXCMN-11014';         --�������o��
  cv_par_token      CONSTANT VARCHAR2(10)  := 'PAR';                     --������MSG�pİ�ݖ�
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
    cv_purge_def_code         CONSTANT VARCHAR2(30)  := 'XXCMN960005';          -- �p�[�W��`�R�[�h
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCMN';                -- �A�h�I���F���ʁEIF�̈�
    cv_purge_type             CONSTANT VARCHAR2(1)   := '1';                    -- �p�[�W�^�C�v(1:�o�b�N�A�b�v��������)
    cv_purge_code             CONSTANT VARCHAR2(30)  := '9601';                 -- �p�[�W��`�R�[�h
--
    cv_get_priod_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';      -- �o�b�N�A�b�v���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_profile_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';      -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_local_others_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11026';      -- ��SHORI �����Ɏ��s���܂����B�y ��KINOUMEI �z ��KEYNAME �F ��KEY
    cv_token_profile          CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_shori            CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_token_kinoumei         CONSTANT VARCHAR2(10)  := 'KINOUMEI';
    cv_token_keyname          CONSTANT VARCHAR2(10)  := 'KEYNAME';
    cv_token_key              CONSTANT VARCHAR2(10)  := 'KEY';
    cv_token_bkup             CONSTANT VARCHAR2(100) := '�o�b�N�A�b�v';
    cv_token_opm_pnd          CONSTANT VARCHAR2(100) := 'OPM�ۗ��݌Ƀg�����U�N�V����';
    cv_token_opm_cmp          CONSTANT VARCHAR2(100) := 'OPM�����݌Ƀg�����U�N�V����';
    cv_token_trans_id         CONSTANT VARCHAR2(100) := '���ID';

--
    cv_xxcmn_commit_range     CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';   --XXCMN:�����R�~�b�g��
    cv_xxcmn_archive_range    CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';  --XXCMN:�o�b�N�A�b�v�����W
    cv_xxcmn_org_id           CONSTANT VARCHAR2(100) := 'ORG_ID';               --�c�ƒP��
--
    cv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
    cv_doc_type_omso          CONSTANT VARCHAR2(30)  := 'OMSO';
    cv_doc_type_porc          CONSTANT VARCHAR2(30)  := 'PORC';
    cv_doc_type_xfer          CONSTANT VARCHAR2(30)  := 'XFER';
    cv_doc_type_trni          CONSTANT VARCHAR2(30)  := 'TRNI';
    cv_doc_type_adji          CONSTANT VARCHAR2(30)  := 'ADJI';
    cv_order                  CONSTANT VARCHAR2(30)  := 'ORDER';
    cv_return                 CONSTANT VARCHAR2(30)  := 'RETURN';
    cv_closed                 CONSTANT VARCHAR2(30)  := 'CLOSED';
    cv_reason_code_x122       CONSTANT VARCHAR2(30)  := 'X122';
    cv_reason_code_x123       CONSTANT VARCHAR2(30)  := 'X123';
    cv_move                   CONSTANT  VARCHAR2(2)  := '20';
    cv_actual_move            CONSTANT VARCHAR2(30)  := '�ړ�����';
    cv_status_wsh_keijozumi   CONSTANT  VARCHAR2(2)  := '04';--04:�o�׎��ьv���
    cv_status_po_keijozumi    CONSTANT  VARCHAR2(2)  := '08';--08:�o�׎��ьv���
    cv_move_booked            CONSTANT  VARCHAR2(2)  := '06';
    cv_actual_ship            CONSTANT  VARCHAR2(2)  := '20';
    cv_actual_arrival         CONSTANT  VARCHAR2(2)  := '30';
--
    -- *** ���[�J���ϐ� ***
    ln_arc_cnt_pnd            NUMBER DEFAULT 0;                                 -- 
    ln_arc_cnt_cmp            NUMBER DEFAULT 0;                                 -- 
    ln_arc_cnt_pnd_yet        NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��))
    ln_arc_cnt_cmp_yet        NUMBER DEFAULT 0;                                 -- ���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��))
    ln_archive_period         NUMBER;                                           -- �o�b�N�A�b�v����
    ln_archive_range          NUMBER;                                           -- �o�b�N�A�b�v�����W
    ld_standard_date          DATE;                                             -- ���
    ln_commit_range           NUMBER;                                           -- �����R�~�b�g��
    ln_org_id                 NUMBER;                                           -- �c�ƒP��ID
    ln_transaction_id         NUMBER;
    ln_before_header_id       NUMBER;
    lv_token_kinoumei         VARCHAR2(100);
    lv_process_step           VARCHAR2(100);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    CURSOR �o�b�N�A�b�v�Ώ�OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�擾
      id_���  IN DATE
      in_�o�b�N�A�b�v�����W IN NUMBER
      in_�c�ƒP�ʂh�c IN �󒍃w�b�_(�W��)�D�c�ƒP�ʂh�c%TYPE
    IS
      -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)(��)
      SELECT 0
            ,�󒍃w�b�_(�A�h�I��).�w�b�_ID
            ,OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�S�J����
      FROM �󒍃w�b�_(�A�h�I��)
           ,    �󒍃^�C�v(�W��)
           ,    �󒍃w�b�_(�W��)
           ,    OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE �󒍃w�b�_(�A�h�I��)�D�X�e�[�^�X IN ('04','08')
      AND �󒍃w�b�_(�A�h�I��)�D���ד� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �󒍃w�b�_(�A�h�I��)�D���ד� < id_���
      AND �󒍃^�C�v(�W��)�D�󒍃^�C�vID = �󒍃w�b�_(�A�h�I��)�D�󒍃^�C�vID
      AND �󒍃^�C�v(�W��)�D�󒍃J�e�S���R�[�h = 'ORDER'
      AND �󒍃w�b�_(�W��).flow_status_code     = 'CLOSED'
      AND �󒍃w�b�_(�W��)�D�󒍃w�b�_ID = �󒍃w�b�_(�A�h�I��)�D�󒍃w�b�_ID
      AND �󒍃w�b�_(�W��)�D�c�ƒP��ID = in_�c�ƒP��ID
      AND �󒍖���(�W��)�D�󒍃w�b�_ID = �󒍃w�b�_(�W��)�D�󒍃w�b�_ID
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D����ID = �󒍖���(�W��)�D����ID
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = 'OMSO'
      AND NOT EXISTS (
                SELECT 1
                FROM OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
                WHERE OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�g�����U�N�V����ID = OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D�g�����U�N�V����ID
                AND ROWNUM = 1
             )
    UNION
      -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)(�ԕi)
      SELECT 1
            ,�󒍃w�b�_(�A�h�I��).�w�b�_ID
            ,OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�S�J����
      FROM �󒍃w�b�_(�A�h�I��)
           ,    �󒍃^�C�v(�W��)
           ,    �󒍃w�b�_(�W��)
           ,    �󒍖���(�W��)
           ,    �������(�W��)
           ,    OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE �󒍃w�b�_(�A�h�I��)�D�X�e�[�^�X IN ('04','08')
      AND �󒍃w�b�_(�A�h�I��)�D���ד� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �󒍃w�b�_(�A�h�I��)�D���ד� < id_���
      AND �󒍃^�C�v(�W��)�D�󒍃^�C�vID = �󒍃w�b�_(�A�h�I��)�D�󒍃^�C�vID
      AND �󒍃^�C�v(�W��)�D�󒍃J�e�S���R�[�h = 'RETURN'
      AND �󒍃w�b�_(�W��).flow_status_code     = 'CLOSED'
      AND �󒍃w�b�_(�W��)�D�󒍃w�b�_ID = �󒍃w�b�_(�A�h�I��)�D�󒍃w�b�_ID
      AND �󒍃w�b�_(�W��)�D�c�ƒP��ID = in_�c�ƒP��ID
      AND �󒍖���(�W��)�D�󒍃w�b�_ID = �󒍃w�b�_(�W��)�D�󒍃w�b�_ID
      AND �������(�W��)�D�󒍃w�b�_ID = �󒍖���(�W��)�D�󒍃w�b�_ID
      AND �������(�W��)�D�󒍖���ID = �󒍖���(�W��)�D�󒍖���ID
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D����ID = �������(�W��)�D����w�b�_ID
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D������הԍ� = �������(�W��)�D���הԍ�
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = 'PORC'
      AND NOT EXISTS (
                SELECT 1
                FROM OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
                WHERE OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�g�����U�N�V����ID = OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D�g�����U�N�V����ID
                AND ROWNUM = 1
             )
      UNION
      -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�i�ړ��j
      SELECT 2
            ,�ړ��˗�/�w���w�b�_(�A�h�I��)�D�ړ��w�b�_ID
            ,OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�S�J����
      FROM �ړ��˗�/�w���w�b�_(�A�h�I��)
           ,    �ړ��˗�/�w������(�A�h�I��)
           ,    OPM�݌ɓ]���}�X�^(�W��)
           ,    OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE �ړ��˗�/�w���w�b�_(�A�h�I��)�D�X�e�[�^�X �� '06'
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�D���Ɏ��ѓ� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�D���Ɏ��ѓ� < id_���
      AND �ړ��˗�/�w������(�A�h�I��)�D�ړ��w�b�_ID = �ړ��˗�/�w���w�b�_(�A�h�I��)�D�ړ��w�b�_ID
      AND OPM�݌ɓ]���}�X�^(�W��)�DDFF1 = �ړ��˗�/�w������(�A�h�I��)�D����ID
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D����ID = OPM�݌ɓ]���}�X�^(�W��)�D�]��ID
      AND ( OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = 'XFER'
      AND OPM�ۗ��݌Ƀg�����U�N�V�����D���R�R�[�h = '�ړ�����'�̎��R�R�[�h )
      AND EXISTS (
              SELECT  1
              FROM    �ړ����b�g�ڍ�(�A�h�I��)
              WHERE   �ړ����b�g�ڍ�(�A�h�I��)�D����ID = �ړ��˗�/�w������(�A�h�I��)�D�ړ�����ID
              AND �ړ����b�g�ڍ�(�A�h�I��)�D�����^�C�v = '20'
              AND �ړ����b�g�ڍ�(�A�h�I��)�D���R�[�h�^�C�v IN ('20','30')
              AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D���b�gID = �ړ����b�g�ڍ�(�A�h�I��)�D���b�gID
              And     ROWNUM                  = 1
              )
      AND NOT EXISTS (
                SELECT 1
                FROM OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                WHERE OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D�g�����U�N�V����ID = OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
                AND ROWNUM = 1
             )
     */
    CURSOR archive_tran_pnd_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
     ,in_org_id                  oe_order_headers_all.org_id%TYPE
    )
    IS
      -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)(��)
      SELECT  /*+ LEADING(xoha) USE_NL(xoha otta ooha oola itp) INDEX(xoha XXWSH_OH_N15) */
              0                           AS pre_sort_key
             ,xoha.header_id              AS header_id
             ,itp.trans_id                AS trans_id
             ,itp.item_id                 AS item_id
             ,itp.line_id                 AS line_id
             ,itp.co_code                 AS co_code
             ,itp.orgn_code               AS orgn_code
             ,itp.whse_code               AS whse_code
             ,itp.lot_id                  AS lot_id
             ,itp.location                AS location
             ,itp.doc_id                  AS doc_id
             ,itp.doc_type                AS doc_type
             ,itp.doc_line                AS doc_line
             ,itp.line_type               AS line_type
             ,itp.reason_code             AS reason_code
             ,itp.creation_date           AS creation_date
             ,itp.trans_date              AS trans_date
             ,itp.trans_qty               AS trans_qty
             ,itp.trans_qty2              AS trans_qty2
             ,itp.qc_grade                AS qc_grade
             ,itp.lot_status              AS lot_status
             ,itp.trans_stat              AS trans_stat
             ,itp.trans_um                AS trans_um
             ,itp.trans_um2               AS trans_um2
             ,itp.op_code                 AS op_code
             ,itp.completed_ind           AS completed_ind
             ,itp.staged_ind              AS staged_ind
             ,itp.gl_posted_ind           AS gl_posted_ind
             ,itp.event_id                AS event_id
             ,itp.delete_mark             AS delete_mark
             ,itp.text_code               AS text_code
             ,itp.last_update_date        AS last_update_date
             ,itp.created_by              AS created_by
             ,itp.last_updated_by         AS last_updated_by
             ,itp.last_update_login       AS last_update_login
             ,itp.program_application_id  AS program_application_id
             ,itp.program_id              AS program_id
             ,itp.program_update_date     AS program_update_date
             ,itp.request_id              AS request_id
             ,itp.reverse_id              AS reverse_id
             ,itp.pick_slip_number        AS pick_slip_number
             ,itp.mvt_stat_status         AS mvt_stat_status
             ,itp.movement_id             AS movement_id
             ,itp.line_detail_id          AS line_detail_id
             ,itp.invoiced_flag           AS invoiced_flag
             ,itp.intorder_posted_ind     AS intorder_posted_ind
             ,itp.lot_costed_ind          AS lot_costed_ind
      FROM    xxwsh_order_headers_all  xoha   --�󒍃w�b�_(�A�h�I��)
             ,oe_transaction_types_all otta   --�󒍃^�C�v(�W��)
             ,oe_order_headers_all     ooha   --�󒍃w�b�_(�W��)
             ,oe_order_lines_all       oola   --�󒍖���(�W��)
             ,ic_tran_pnd              itp    --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE   xoha.req_status          IN (cv_status_wsh_keijozumi, cv_status_po_keijozumi)
      AND     xoha.arrival_date        >= id_standard_date - in_archive_range
      AND     xoha.arrival_date         < id_standard_date
      AND     otta.transaction_type_id  = xoha.order_type_id
      AND     otta.order_category_code  = cv_order
      AND     ooha.flow_status_code     = cv_closed
      AND     ooha.header_id            = xoha.header_id
      AND     ooha.org_id               = in_org_id
      AND     oola.header_id            = ooha.header_id
      AND     itp.line_id               = oola.line_id
      AND     itp.doc_type              = cv_doc_type_omso
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_pnd_arc  xitpa --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
                WHERE   xitpa.trans_id = itp.trans_id
                AND     ROWNUM         = 1
              )
      UNION
      -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)(�ԕi)
      SELECT  /*+ LEADING(xoha) USE_NL(xoha otta ooha oola rsl itp) INDEX(xoha XXWSH_OH_N15) */
              1                           AS pre_sort_key
             ,xoha.header_id              AS header_id
             ,itp.trans_id                AS trans_id
             ,itp.item_id                 AS item_id
             ,itp.line_id                 AS line_id
             ,itp.co_code                 AS co_code
             ,itp.orgn_code               AS orgn_code
             ,itp.whse_code               AS whse_code
             ,itp.lot_id                  AS lot_id
             ,itp.location                AS location
             ,itp.doc_id                  AS doc_id
             ,itp.doc_type                AS doc_type
             ,itp.doc_line                AS doc_line
             ,itp.line_type               AS line_type
             ,itp.reason_code             AS reason_code
             ,itp.creation_date           AS creation_date
             ,itp.trans_date              AS trans_date
             ,itp.trans_qty               AS trans_qty
             ,itp.trans_qty2              AS trans_qty2
             ,itp.qc_grade                AS qc_grade
             ,itp.lot_status              AS lot_status
             ,itp.trans_stat              AS trans_stat
             ,itp.trans_um                AS trans_um
             ,itp.trans_um2               AS trans_um2
             ,itp.op_code                 AS op_code
             ,itp.completed_ind           AS completed_ind
             ,itp.staged_ind              AS staged_ind
             ,itp.gl_posted_ind           AS gl_posted_ind
             ,itp.event_id                AS event_id
             ,itp.delete_mark             AS delete_mark
             ,itp.text_code               AS text_code
             ,itp.last_update_date        AS last_update_date
             ,itp.created_by              AS created_by
             ,itp.last_updated_by         AS last_updated_by
             ,itp.last_update_login       AS last_update_login
             ,itp.program_application_id  AS program_application_id
             ,itp.program_id              AS program_id
             ,itp.program_update_date     AS program_update_date
             ,itp.request_id              AS request_id
             ,itp.reverse_id              AS reverse_id
             ,itp.pick_slip_number        AS pick_slip_number
             ,itp.mvt_stat_status         AS mvt_stat_status
             ,itp.movement_id             AS movement_id
             ,itp.line_detail_id          AS line_detail_id
             ,itp.invoiced_flag           AS invoiced_flag
             ,itp.intorder_posted_ind     AS intorder_posted_ind
             ,itp.lot_costed_ind          AS lot_costed_ind
      FROM    xxwsh_order_headers_all  xoha   --�󒍃w�b�_(�A�h�I��)
             ,oe_transaction_types_all otta   --�󒍃^�C�v(�W��)
             ,oe_order_headers_all     ooha   --�󒍃w�b�_(�W��)
             ,oe_order_lines_all       oola   --�󒍖���(�W��)
             ,rcv_shipment_lines       rsl    --�������(�W��)
             ,ic_tran_pnd              itp    --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE   xoha.req_status          IN (cv_status_wsh_keijozumi, cv_status_po_keijozumi)
      AND     xoha.arrival_date        >= id_standard_date - in_archive_range
      AND     xoha.arrival_date         < id_standard_date
      AND     otta.transaction_type_id  = xoha.order_type_id
      AND     otta.order_category_code  = cv_return
      AND     ooha.flow_status_code     = cv_closed
      AND     ooha.header_id            = xoha.header_id
      AND     ooha.org_id               = in_org_id
      AND     oola.header_id            = ooha.header_id
      AND     rsl.oe_order_header_id    = ooha.header_id
      AND     rsl.oe_order_line_id      = oola.line_id
      AND     itp.doc_id                = rsl.shipment_header_id
      AND     itp.doc_line              = rsl.line_num
      AND     itp.doc_type              = cv_doc_type_porc
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_pnd_arc  xitpa --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
                WHERE   xitpa.trans_id = itp.trans_id
                AND     ROWNUM         = 1
              )
      UNION
    -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�i�ړ��j
      SELECT  /*+ LEADING(xmrih) USE_NL(xmrih xmril ixm itp)*/
              2                           AS pre_sort_key
             ,xmrih.mov_hdr_id            AS header_id
             ,itp.trans_id                AS trans_id
             ,itp.item_id                 AS item_id
             ,itp.line_id                 AS line_id
             ,itp.co_code                 AS co_code
             ,itp.orgn_code               AS orgn_code
             ,itp.whse_code               AS whse_code
             ,itp.lot_id                  AS lot_id
             ,itp.location                AS location
             ,itp.doc_id                  AS doc_id
             ,itp.doc_type                AS doc_type
             ,itp.doc_line                AS doc_line
             ,itp.line_type               AS line_type
             ,itp.reason_code             AS reason_code
             ,itp.creation_date           AS creation_date
             ,itp.trans_date              AS trans_date
             ,itp.trans_qty               AS trans_qty
             ,itp.trans_qty2              AS trans_qty2
             ,itp.qc_grade                AS qc_grade
             ,itp.lot_status              AS lot_status
             ,itp.trans_stat              AS trans_stat
             ,itp.trans_um                AS trans_um
             ,itp.trans_um2               AS trans_um2
             ,itp.op_code                 AS op_code
             ,itp.completed_ind           AS completed_ind
             ,itp.staged_ind              AS staged_ind
             ,itp.gl_posted_ind           AS gl_posted_ind
             ,itp.event_id                AS event_id
             ,itp.delete_mark             AS delete_mark
             ,itp.text_code               AS text_code
             ,itp.last_update_date        AS last_update_date
             ,itp.created_by              AS created_by
             ,itp.last_updated_by         AS last_updated_by
             ,itp.last_update_login       AS last_update_login
             ,itp.program_application_id  AS program_application_id
             ,itp.program_id              AS program_id
             ,itp.program_update_date     AS program_update_date
             ,itp.request_id              AS request_id
             ,itp.reverse_id              AS reverse_id
             ,itp.pick_slip_number        AS pick_slip_number
             ,itp.mvt_stat_status         AS mvt_stat_status
             ,itp.movement_id             AS movement_id
             ,itp.line_detail_id          AS line_detail_id
             ,itp.invoiced_flag           AS invoiced_flag
             ,itp.intorder_posted_ind     AS intorder_posted_ind
             ,itp.lot_costed_ind          AS lot_costed_ind
      FROM    xxinv_mov_req_instr_headers   xmrih     --�ړ��˗�/�w���w�b�_(�A�h�I��)
             ,xxinv_mov_req_instr_lines     xmril     --�ړ��˗�/�w������(�A�h�I��)
             ,ic_xfer_mst                   ixm       --OPM�݌ɓ]���}�X�^
             ,ic_tran_pnd                   itp       --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE
              xmrih.status            = cv_move_booked  --�ړ��˗�/�w���w�b�_(�A�h�I��)�D�X�e�[�^�X = '06'
        AND   xmrih.actual_arrival_date  >= id_standard_date - in_archive_range
        AND   xmrih.actual_arrival_date   < id_standard_date
        AND   xmril.mov_hdr_id            = xmrih.mov_hdr_id
        AND   ixm.attribute1              = TO_CHAR(xmril.mov_line_id)
        AND   itp.doc_id                  = ixm.transfer_id
        AND   itp.doc_type                = cv_doc_type_xfer
        AND   itp.reason_code             = cv_reason_code_x122
      AND   EXISTS (
              SELECT  1
              FROM    xxinv_mov_lot_details  xmld             --�ړ����b�g�ڍ�(�A�h�I��)
              WHERE   xmld.mov_line_id        = xmril.mov_line_id
              AND     xmld.document_type_code = cv_move          --�ړ����b�g�ڍ�(�A�h�I��)�D�����^�C�v = '20'
              AND     xmld.record_type_code   IN (cv_actual_ship, cv_actual_arrival)  --�ړ����b�g�ڍ�(�A�h�I��)�D���R�[�h�^�C�v IN ('20','30')
              AND     xmld.lot_id             = itp.lot_id
              And     ROWNUM                  = 1
              )
      AND   NOT EXISTS (
              SELECT  1
              FROM    xxcmn_ic_tran_pnd_arc  xitpa          --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
              WHERE   xitpa.trans_id          = itp.trans_id
              AND     ROWNUM                  = 1
              )
      ORDER BY pre_sort_key,header_id
      ;
    /*
    -- OPM�����݌Ƀg�����U�N�V�����i�W���j�i�ړ��j
    CURSOR �o�b�N�A�b�v�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾
      id_���  IN DATE
      in_�o�b�N�A�b�v�����W IN NUMBER
    IS
      SELECT 
             �ړ��˗�/�w���w�b�_(�A�h�I��)�D�ړ��w�b�_ID
            ,OPM�����݌Ƀg�����U�N�V�����i�W���j�S�J����
      FROM �ړ��˗�/�w���w�b�_(�A�h�I��)
           ,    �ړ��˗�/�w������(�A�h�I��)
           ,    OPM�W���[�i���}�X�^(�W��)
           ,    OPM�݌ɒ����W���[�i��(�W��)
           ,    OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE �ړ��˗�/�w���w�b�_(�A�h�I��)�D�X�e�[�^�X �� '06'
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�D���Ɏ��ѓ� >= id_��� - in_�o�b�N�A�b�v�����W
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�D���Ɏ��ѓ� < id_���
      AND �ړ��˗�/�w������(�A�h�I��)�D�ړ��w�b�_ID = �ړ��˗�/�w���w�b�_(�A�h�I��)�D�ړ��w�b�_ID
      AND OPM�W���[�i���}�X�^(�W��)�DDFF1 = �ړ����b�g�ڍ�(�A�h�I��)�D����ID
      AND OPM�݌ɒ����W���[�i��(�W��)�D�W���[�i��ID = OPM�W���[�i���}�X�^(�W��)�D�W���[�i��ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = OPM�݌ɒ����W���[�i��(�W��)�D�����^�C�v
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D����ID = OPM�݌ɒ����W���[�i��(�W��)�D����ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D������הԍ� = OPM�݌ɒ����W���[�i��(�W��)�D������הԍ�
      AND ( ( OPM�����݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = 'TRNI'
      AND OPM�����݌Ƀg�����U�N�V�����D���R�R�[�h = '�ړ�����'�̎��R�R�[�h )
       OR   ( OPM�����݌Ƀg�����U�N�V����(�W��)�D�����^�C�v = 'ADJI'
      AND OPM�����݌Ƀg�����U�N�V�����D���R�R�[�h = '�ړ����ђ���'�̎��R�R�[�h )
      AND EXISTS (
                SELECT  1
                FROM    �ړ����b�g�ڍ�(�A�h�I��)
                WHERE   �ړ����b�g�ڍ�(�A�h�I��)�D����ID = �ړ��˗�/�w������(�A�h�I��)�D�ړ�����ID
                AND     �ړ����b�g�ڍ�(�A�h�I��)�D�����^�C�v = '20'
                AND     �ړ����b�g�ڍ�(�A�h�I��)�D���R�[�h�^�C�v IN ('20','30')
                AND     OPM�����݌Ƀg�����U�N�V����(�W��)�D���b�gID = �ړ����b�g�ڍ�(�A�h�I��)�D���b�gID
                And     ROWNUM                  = 1
                )
      AND NOT EXISTS (
                SELECT 1
                FROM OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                WHERE OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D�g�����U�N�V����ID = OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
                AND ROWNUM = 1
             )
     */
    CURSOR archive_ic_tran_cmp_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
    )
    IS
      SELECT  /*+ LEADING(xmrih) USE_NL(xmrih xmril ijm iaj itc INDEX(ijm GMI_IJM_N01)*/
              xmrih.mov_hdr_id            AS header_id
             ,itc.trans_id                AS trans_id
             ,itc.item_id                 AS item_id
             ,itc.line_id                 AS line_id
             ,itc.co_code                 AS co_code
             ,itc.orgn_code               AS orgn_code
             ,itc.whse_code               AS whse_code
             ,itc.lot_id                  AS lot_id
             ,itc.location                AS location
             ,itc.doc_id                  AS doc_id
             ,itc.doc_type                AS doc_type
             ,itc.doc_line                AS doc_line
             ,itc.line_type               AS line_type
             ,itc.reason_code             AS reason_code
             ,itc.creation_date           AS creation_date
             ,itc.trans_date              AS trans_date
             ,itc.trans_qty               AS trans_qty
             ,itc.trans_qty2              AS trans_qty2
             ,itc.qc_grade                AS qc_grade
             ,itc.lot_status              AS lot_status
             ,itc.trans_stat              AS trans_stat
             ,itc.trans_um                AS trans_um
             ,itc.trans_um2               AS trans_um2
             ,itc.op_code                 AS op_code
             ,itc.gl_posted_ind           AS gl_posted_ind
             ,itc.event_id                AS event_id
             ,itc.text_code               AS text_code
             ,itc.last_update_date        AS last_update_date
             ,itc.created_by              AS created_by
             ,itc.last_updated_by         AS last_updated_by
             ,itc.last_update_login       AS last_update_login
             ,itc.program_application_id  AS program_application_id
             ,itc.program_id              AS program_id
             ,itc.program_update_date     AS program_update_date
             ,itc.request_id              AS request_id
             ,itc.movement_id             AS movement_id
             ,itc.mvt_stat_status         AS mvt_stat_status
             ,itc.line_detail_id          AS line_detail_id
             ,itc.invoiced_flag           AS invoiced_flag
             ,itc.staged_ind              AS staged_ind
             ,itc.intorder_posted_ind     AS intorder_posted_ind
             ,itc.lot_costed_ind          AS lot_costed_ind
      FROM    xxinv_mov_req_instr_headers   xmrih     --�ړ��˗�/�w���w�b�_(�A�h�I��)
             ,xxinv_mov_req_instr_lines     xmril     --�ړ��˗�/�w������(�A�h�I��)
             ,ic_jrnl_mst                   ijm       --OPM�W���[�i���}�X�^(�W��)
             ,ic_adjs_jnl                   iaj       --OPM�݌ɒ����W���[�i��(�W��)
             ,ic_tran_cmp                   itc       --OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE
              xmrih.status            = cv_move_booked  --�ړ��˗�/�w���w�b�_(�A�h�I��)�D�X�e�[�^�X = '06'
        AND   xmrih.actual_arrival_date >= id_standard_date - in_archive_range
        AND   xmrih.actual_arrival_date  < id_standard_date
        AND   xmril.mov_hdr_id        = xmrih.mov_hdr_id
        AND   ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
        AND   iaj.journal_id         = ijm.journal_id
        AND   itc.doc_type        = iaj.trans_type
        AND   itc.doc_id          = iaj.doc_id
        AND   itc.doc_line        = iaj.doc_line
        AND   ( ( ( itc.doc_type        = cv_doc_type_trni )           --OPM�����݌Ƀg�����U�N�V����(�W��).�����^�C�v = 'TRNI'
          AND     ( itc.reason_code     = cv_reason_code_x122 ) )      --���R�R�[�h='�ړ�����'
           OR   ( ( itc.doc_type        = cv_doc_type_adji )           --OPM�����݌Ƀg�����U�N�V����(�W��).�����^�C�v = 'ADJI'
          AND     ( itc.reason_code     = cv_reason_code_x123 ) ) )    --���R�R�[�h='�ړ����ђ���'
        AND   EXISTS (
                SELECT  1
                FROM    xxinv_mov_lot_details  xmld             --�ړ����b�g�ڍ�(�A�h�I��)
                WHERE   xmld.mov_line_id        = xmril.mov_line_id
                AND     xmld.document_type_code = cv_move          --�ړ����b�g�ڍ�(�A�h�I��)�D�����^�C�v = '20'
                AND     xmld.record_type_code   IN (cv_actual_ship, cv_actual_arrival)  --�ړ����b�g�ڍ�(�A�h�I��)�D���R�[�h�^�C�v IN ('20','30')
                AND     xmld.lot_id             = itc.lot_id
                And     ROWNUM                  = 1
                )
        AND   NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_cmp_arc  xitca          --OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
                WHERE   xitca.trans_id = itc.trans_id
                AND     ROWNUM         = 1
              )
      ORDER BY header_id
      ;
--
    -- <�J�[�\����>���R�[�h�^
    TYPE ic_tran_pnd_ttype  IS TABLE OF archive_tran_pnd_cur%ROWTYPE INDEX BY BINARY_INTEGER;        -- OPM�ۗ��݌�TRN(�W��)(��)�e�[�u���^�C�v
    TYPE ic_tran_cmp_ttype   IS TABLE OF archive_ic_tran_cmp_cur%ROWTYPE INDEX BY BINARY_INTEGER;         -- OPM�����݌�TRN(�W��)(�ړ�)�e�[�u���^�C�v
--
    TYPE xxcmn_ic_tran_pnd_arc_ttype  IS TABLE OF xxcmn_ic_tran_pnd_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM�ۗ��݌�TRN�o�b�N�A�b�v�e�[�u���^�C�v
    TYPE xxcmn_ic_tran_cmp_arc_ttype  IS TABLE OF xxcmn_ic_tran_cmp_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM�����݌�TRN�o�b�N�A�b�v�e�[�u���^�C�v
--
    l_ic_tran_pnd_tab     ic_tran_pnd_ttype;                             -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)(��)�e�[�u��
    l_ic_tran_cmp_tab      ic_tran_cmp_ttype;                              -- OPM�����݌Ƀg�����U�N�V����(�W��)(�ړ�)�e�[�u��
--
    l_arc_ic_tran_pnd_tab     xxcmn_ic_tran_pnd_arc_ttype;                  -- OPM�ۗ��݌�TRN�o�b�N�A�b�v�e�[�u��
    l_arc_ic_tran_cmp_tab      xxcmn_ic_tran_cmp_arc_ttype;                  -- OPM�����݌�TRN�o�b�N�A�b�v�e�[�u��
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_arc_cnt_cmp    := 0;
    gn_arc_cnt_pnd    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- �o�b�N�A�b�v���Ԏ擾
    -- ===============================================
    lv_process_step := '�o�b�N�A�b�v���Ԏ擾';
    /*
    ln_�o�b�N�A�b�v���� := �o�b�N�A�b�v���Ԏ擾���ʊ֐��icv_�p�[�W��`�R�[�h�j;
     */
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
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�o�b�N�A�b�v����:' || TO_CHAR(ln_archive_period));
--
    -- ===============================================
    -- �h�m�p�����[�^�̊m�F
    -- ===============================================
    lv_process_step := '�p�����[�^�m�F';
    BEGIN
      /*
      iv_proc_date��NULL�̏ꍇ
--
        ld_��� := �������擾���ʊ֐�����擾���������� - ln_�o�b�N�A�b�v����;
--
      iv_proc_date��NULL�łȂ��̏ꍇ
--
        ld_��� := TO_DATE(iv_proc_date) - ln_�o�b�N�A�b�v����;
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
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        ov_errmsg := SQLERRM;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '���:' || TO_CHAR(ld_standard_date,cv_date_format));
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    lv_process_step := '�v���t�@�C���擾';
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����R�~�b�g��));
    ln_�o�b�N�A�b�v�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�o�b�N�A�b�v�����W));
    ln_�c�ƒP��ID = TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(MO:�c�ƒP��));
     */
    BEGIN
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
    BEGIN
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
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_archive_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�o�b�N�A�b�v�����W:' || TO_CHAR(ln_archive_range));
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�o�b�N�A�b�vFrom:' || TO_CHAR(ld_standard_date-ln_archive_range,cv_date_format));
--
    ln_org_id               := TO_NUMBER(fnd_profile.value(cv_xxcmn_org_id));
--
    -- ===============================================
    -- �o�b�N�A�b�v�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�擾
    -- ===============================================
    lv_process_step := '�o�b�N�A�b�v�Ώ�OPM�ۗ��݌�TRN�i�W���j�擾';
    /*
    OPEN�o�b�N�A�b�v��OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�擾(
                                     ld_standard_date
                                    ,ln_archive_range
                                    ,ln_org_id
                                   );
    FETCH �o�b�N�A�b�v�Ώ�OPM�ۗ��݌Ƀg�����U�N�V����(�W��) BULK COLLECT INTO lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��;
     */
    OPEN archive_tran_pnd_cur(
                                     ld_standard_date
                                    ,ln_archive_range
                                    ,ln_org_id
                                   );
    FETCH archive_tran_pnd_cur BULK COLLECT INTO l_ic_tran_pnd_tab;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�ۗ��g��������' || TO_CHAR(l_ic_tran_pnd_tab.COUNT));
    /*
    IF lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��.count > 1 THEN
        BEGIN
          << archive_ic_tran_pnd_loop >>
          FOR ln_main_idx in 1 .. lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��.COUNT
          LOOP
    */
    IF ( l_ic_tran_pnd_tab.COUNT ) > 0 THEN
      BEGIN
        << archive_ic_tran_pnd_loop >>
        FOR ln_main_idx in 1 .. l_ic_tran_pnd_tab.COUNT
        LOOP
          -- ===============================================
          -- �����R�~�b�g
          -- ===============================================
          /*
          NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
           */
          IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
            /*
            �O�񏈗������w�b�_ID�Ǝ擾�����w�b�_ID���قȂ�ꍇ�͖��R�~�b�g�o�b�N�A�b�v������+1
            */
            IF (ln_before_header_id != l_ic_tran_pnd_tab(ln_main_idx).header_id ) THEN
              ln_arc_cnt_pnd_yet := ln_arc_cnt_pnd_yet + 1;
            END IF;
            /*
            ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��)) > 0
            ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��)), ln_�����R�~�b�g��) = 0�̏ꍇ
             */
            IF (  (ln_arc_cnt_pnd_yet > 0)
              AND (MOD(ln_arc_cnt_pnd_yet, ln_commit_range) = 0)
               )
            THEN
--
              /*
              FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��))
                INSERT INTO OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
                (
                    �S�J����
                  , �o�b�N�A�b�v�o�^��
                  , �o�b�N�A�b�v�v��ID
                )
                VALUES
                (
                    lt_OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�e�[�u��(ln_idx)�S�J����
                  , SYSDATE
                  , �v��ID
                )
               */
              FORALL ln_idx IN 1..ln_arc_cnt_pnd
                INSERT INTO xxcmn_ic_tran_pnd_arc VALUES l_arc_ic_tran_pnd_tab(ln_idx);
--
              /*
              ln_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��)) := ln_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��))
                                                                         + ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��));
              ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��)) := 0;
              lt_OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�e�[�u���DDELETE;
               */
              gn_arc_cnt_pnd     := gn_arc_cnt_pnd + ln_arc_cnt_pnd;
              ln_arc_cnt_pnd     := 0;
              ln_arc_cnt_pnd_yet := 0;
              l_arc_ic_tran_pnd_tab.DELETE;
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
          ln_�J�[�\���t�F�b�`�J�E���g := ln_�J�[�\���t�F�b�`�J�E���g + 1;
          lt_OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�e�[�u��(ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��))
                                                                                   := lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��;
           */
          ln_arc_cnt_pnd := ln_arc_cnt_pnd + 1;
--
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_id               := l_ic_tran_pnd_tab(ln_main_idx).trans_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).item_id                := l_ic_tran_pnd_tab(ln_main_idx).item_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).line_id                := l_ic_tran_pnd_tab(ln_main_idx).line_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).co_code                := l_ic_tran_pnd_tab(ln_main_idx).co_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).orgn_code              := l_ic_tran_pnd_tab(ln_main_idx).orgn_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).whse_code              := l_ic_tran_pnd_tab(ln_main_idx).whse_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).lot_id                 := l_ic_tran_pnd_tab(ln_main_idx).lot_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).location               := l_ic_tran_pnd_tab(ln_main_idx).location;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).doc_id                 := l_ic_tran_pnd_tab(ln_main_idx).doc_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).doc_type               := l_ic_tran_pnd_tab(ln_main_idx).doc_type;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).doc_line               := l_ic_tran_pnd_tab(ln_main_idx).doc_line;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).line_type              := l_ic_tran_pnd_tab(ln_main_idx).line_type;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).reason_code            := l_ic_tran_pnd_tab(ln_main_idx).reason_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).creation_date          := l_ic_tran_pnd_tab(ln_main_idx).creation_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_date             := l_ic_tran_pnd_tab(ln_main_idx).trans_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_qty              := l_ic_tran_pnd_tab(ln_main_idx).trans_qty;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_qty2             := l_ic_tran_pnd_tab(ln_main_idx).trans_qty2;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).qc_grade               := l_ic_tran_pnd_tab(ln_main_idx).qc_grade;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).lot_status             := l_ic_tran_pnd_tab(ln_main_idx).lot_status;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_stat             := l_ic_tran_pnd_tab(ln_main_idx).trans_stat;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_um               := l_ic_tran_pnd_tab(ln_main_idx).trans_um;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_um2              := l_ic_tran_pnd_tab(ln_main_idx).trans_um2;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).op_code                := l_ic_tran_pnd_tab(ln_main_idx).op_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).completed_ind          := l_ic_tran_pnd_tab(ln_main_idx).completed_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).staged_ind             := l_ic_tran_pnd_tab(ln_main_idx).staged_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).gl_posted_ind          := l_ic_tran_pnd_tab(ln_main_idx).gl_posted_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).event_id               := l_ic_tran_pnd_tab(ln_main_idx).event_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).delete_mark            := l_ic_tran_pnd_tab(ln_main_idx).delete_mark;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).text_code              := l_ic_tran_pnd_tab(ln_main_idx).text_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).last_update_date       := l_ic_tran_pnd_tab(ln_main_idx).last_update_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).created_by             := l_ic_tran_pnd_tab(ln_main_idx).created_by;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).last_updated_by        := l_ic_tran_pnd_tab(ln_main_idx).last_updated_by;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).last_update_login      := l_ic_tran_pnd_tab(ln_main_idx).last_update_login;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).program_application_id := l_ic_tran_pnd_tab(ln_main_idx).program_application_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).program_id             := l_ic_tran_pnd_tab(ln_main_idx).program_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).program_update_date    := l_ic_tran_pnd_tab(ln_main_idx).program_update_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).request_id             := l_ic_tran_pnd_tab(ln_main_idx).request_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).reverse_id             := l_ic_tran_pnd_tab(ln_main_idx).reverse_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).pick_slip_number       := l_ic_tran_pnd_tab(ln_main_idx).pick_slip_number;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).mvt_stat_status        := l_ic_tran_pnd_tab(ln_main_idx).mvt_stat_status;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).movement_id            := l_ic_tran_pnd_tab(ln_main_idx).movement_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).line_detail_id         := l_ic_tran_pnd_tab(ln_main_idx).line_detail_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).invoiced_flag          := l_ic_tran_pnd_tab(ln_main_idx).invoiced_flag;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).intorder_posted_ind    := l_ic_tran_pnd_tab(ln_main_idx).intorder_posted_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).lot_costed_ind         := l_ic_tran_pnd_tab(ln_main_idx).lot_costed_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).archive_date           := SYSDATE;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).archive_request_id     := cn_request_id;
--
          /*
          ln_�O�w�b�_ID := lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��.�w�b�_ID;
          */
          ln_before_header_id := l_ic_tran_pnd_tab(ln_main_idx).header_id;
--
        END LOOP archive_ic_tran_pnd_loop;
--
        lv_process_step := '�o�b�N�A�b�v�Ώ�OPM�ۗ��݌�TRN�c����';
        /*
        FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��))
          INSERT INTO OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
          (
               �S�J����
            , �o�b�N�A�b�v�o�^��
            , �o�b�N�A�b�v�v��ID
          )
          VALUES
          (
              lt_OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�e�[�u��(ln_idx)�S�J����
            , SYSDATE
            , �v��ID
          )
         */
        FORALL ln_idx IN 1..ln_arc_cnt_pnd
          INSERT INTO xxcmn_ic_tran_pnd_arc VALUES l_arc_ic_tran_pnd_tab(ln_idx);
  --
        /*
        ln_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��)) := ln_�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��))
                                                                   + ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��));
        ln_���R�~�b�g�o�b�N�A�b�v����(OPM�ۗ��݌Ƀg�����U�N�V����(�W��)) := 0;
        lt_OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�e�[�u���DDELETE;
        --�ۗ��݌Ƀg�����U�N�V�����͐���ɏI�������̂ŃR�~�b�g����
        COMMIT;
         */
        gn_arc_cnt_pnd     := gn_arc_cnt_pnd + ln_arc_cnt_pnd;
        ln_arc_cnt_pnd     := 0;
        ln_arc_cnt_pnd_yet := 0;
        ln_before_header_id := NULL;
        l_arc_ic_tran_pnd_tab.DELETE;
        l_ic_tran_pnd_tab.DELETE;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          lv_token_kinoumei := cv_token_opm_pnd;
          FND_FILE.PUT_LINE (FND_FILE.LOG, SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
          ln_transaction_id := l_arc_ic_tran_pnd_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).trans_id;
          RAISE local_process_expt;
      END;
--
    END IF;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'OPM�ۗ��݌�TRN����:' || TO_CHAR(gn_arc_cnt_pnd));
--
    -- ===============================================
    -- �o�b�N�A�b�v�Ώ�OPM�����݌Ƀg�����U�N�V����(�W��)(�ړ�)�擾
    -- ===============================================
    lv_process_step := '�o�b�N�A�b�v�Ώ�OPM�����݌�TRN(�W��)�擾';
    /*
    OPEN�o�b�N�A�b�v��OPM�����݌Ƀg�����U�N�V����(�W��)�擾(
                                     ld_standard_date
                                    ,ln_archive_range
                                   );
    FETCH �o�b�N�A�b�v�Ώ�OPM�����݌Ƀg�����U�N�V����(�W��) BULK COLLECT INTO lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��;
     */
    OPEN archive_ic_tran_cmp_cur(
                                     ld_standard_date
                                    ,ln_archive_range
                                   );
    FETCH archive_ic_tran_cmp_cur BULK COLLECT INTO l_ic_tran_cmp_tab;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '�����g��������' || TO_CHAR(l_ic_tran_cmp_tab.COUNT));
    /*
    IF lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��.count > 1 THEN
        BEGIN
          << archive_ic_tran_cmp_loop >>
          FOR ln_main_idx in 1 .. lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��.COUNT
          LOOP
    */
    IF ( l_ic_tran_cmp_tab.COUNT ) > 0 THEN
      BEGIN
        << archive_ic_tran_cmp_loop >>
        FOR ln_main_idx in 1 .. l_ic_tran_cmp_tab.COUNT
        LOOP
          -- ===============================================
          -- �����R�~�b�g
          -- ===============================================
          /*
          NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
           */
          IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
            /*
            �O�񏈗������w�b�_ID�Ǝ擾�����w�b�_ID���قȂ�ꍇ�͖��R�~�b�g�o�b�N�A�b�v������+1
            */
            IF ( ln_before_header_id != l_ic_tran_cmp_tab(ln_main_idx).header_id ) THEN
              ln_arc_cnt_cmp_yet := ln_arc_cnt_cmp_yet + 1;
            END IF;
            /*
            ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌ɌɃg�����U�N�V����(�W��)) > 0
            ���� MOD(ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��)), ln_�����R�~�b�g��) = 0�̏ꍇ
             */
            IF (  (ln_arc_cnt_cmp_yet > 0)
              AND (MOD(ln_arc_cnt_cmp_yet, ln_commit_range) = 0)
               )
            THEN
--
              /*
              FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��))
                INSERT INTO OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
                (
                    �S�J����
                  , �o�b�N�A�b�v�o�^��
                  , �o�b�N�A�b�v�v��ID
                )
                VALUES
                (
                    lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u��(ln_idx)�S�J����
                  , SYSDATE
                  , �v��ID
                )
               */
              FORALL ln_idx IN 1..ln_arc_cnt_cmp
                INSERT INTO xxcmn_ic_tran_cmp_arc VALUES l_arc_ic_tran_cmp_tab(ln_idx);
--
              /*
              ln_�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��)) := ln_�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��))
                                                                         + ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��));
              ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��)) := 0;
              lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u���DDELETE;
               */
              gn_arc_cnt_cmp     := gn_arc_cnt_cmp + ln_arc_cnt_cmp;
              ln_arc_cnt_cmp     := 0;
              ln_arc_cnt_cmp_yet := 0;
              l_arc_ic_tran_cmp_tab.DELETE;
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
          ln_�J�[�\���t�F�b�`�J�E���g := ln_�J�[�\���t�F�b�`�J�E���g + 1;
          lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u��(ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��))
                                                                                   := lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��;
           */
          ln_arc_cnt_cmp := ln_arc_cnt_cmp + 1;
--
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_id               := l_ic_tran_cmp_tab(ln_main_idx).trans_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).item_id                := l_ic_tran_cmp_tab(ln_main_idx).item_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).line_id                := l_ic_tran_cmp_tab(ln_main_idx).line_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).co_code                := l_ic_tran_cmp_tab(ln_main_idx).co_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).orgn_code              := l_ic_tran_cmp_tab(ln_main_idx).orgn_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).whse_code              := l_ic_tran_cmp_tab(ln_main_idx).whse_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).lot_id                 := l_ic_tran_cmp_tab(ln_main_idx).lot_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).location               := l_ic_tran_cmp_tab(ln_main_idx).location;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).doc_id                 := l_ic_tran_cmp_tab(ln_main_idx).doc_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).doc_type               := l_ic_tran_cmp_tab(ln_main_idx).doc_type;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).doc_line               := l_ic_tran_cmp_tab(ln_main_idx).doc_line;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).line_type              := l_ic_tran_cmp_tab(ln_main_idx).line_type;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).reason_code            := l_ic_tran_cmp_tab(ln_main_idx).reason_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).creation_date          := l_ic_tran_cmp_tab(ln_main_idx).creation_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_date             := l_ic_tran_cmp_tab(ln_main_idx).trans_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_qty              := l_ic_tran_cmp_tab(ln_main_idx).trans_qty;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_qty2             := l_ic_tran_cmp_tab(ln_main_idx).trans_qty2;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).qc_grade               := l_ic_tran_cmp_tab(ln_main_idx).qc_grade;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).lot_status             := l_ic_tran_cmp_tab(ln_main_idx).lot_status;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_stat             := l_ic_tran_cmp_tab(ln_main_idx).trans_stat;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_um               := l_ic_tran_cmp_tab(ln_main_idx).trans_um;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_um2              := l_ic_tran_cmp_tab(ln_main_idx).trans_um2;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).op_code                := l_ic_tran_cmp_tab(ln_main_idx).op_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).gl_posted_ind          := l_ic_tran_cmp_tab(ln_main_idx).gl_posted_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).event_id               := l_ic_tran_cmp_tab(ln_main_idx).event_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).text_code              := l_ic_tran_cmp_tab(ln_main_idx).text_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).last_update_date       := l_ic_tran_cmp_tab(ln_main_idx).last_update_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).created_by             := l_ic_tran_cmp_tab(ln_main_idx).created_by;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).last_updated_by        := l_ic_tran_cmp_tab(ln_main_idx).last_updated_by;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).last_update_login      := l_ic_tran_cmp_tab(ln_main_idx).last_update_login;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).program_application_id := l_ic_tran_cmp_tab(ln_main_idx).program_application_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).program_id             := l_ic_tran_cmp_tab(ln_main_idx).program_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).program_update_date    := l_ic_tran_cmp_tab(ln_main_idx).program_update_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).request_id             := l_ic_tran_cmp_tab(ln_main_idx).request_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).movement_id            := l_ic_tran_cmp_tab(ln_main_idx).movement_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).mvt_stat_status        := l_ic_tran_cmp_tab(ln_main_idx).mvt_stat_status;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).line_detail_id         := l_ic_tran_cmp_tab(ln_main_idx).line_detail_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).invoiced_flag          := l_ic_tran_cmp_tab(ln_main_idx).invoiced_flag;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).intorder_posted_ind    := l_ic_tran_cmp_tab(ln_main_idx).intorder_posted_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).staged_ind             := l_ic_tran_cmp_tab(ln_main_idx).staged_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).lot_costed_ind         := l_ic_tran_cmp_tab(ln_main_idx).lot_costed_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).archive_date           := SYSDATE;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).archive_request_id     := cn_request_id;

          /*
          ln_�O�w�b�_ID := lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��.�w�b�_ID;
          */
          ln_before_header_id := l_ic_tran_cmp_tab(ln_main_idx).header_id;
--
        END LOOP archive_ic_tran_cmp_loop;
--
        lv_process_step := '�o�b�N�A�b�v�Ώ�OPM�����݌�TRN(�W��)�c����';
        /*
        FORALL ln_idx IN 1..ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��))
          INSERT INTO OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
          (
               �S�J����
            , �o�b�N�A�b�v�o�^��
            , �o�b�N�A�b�v�v��ID
          )
          VALUES
          (
              lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u��(ln_idx)�S�J����
            , SYSDATE
            , �v��ID
          )
         */
        FORALL ln_idx IN 1..ln_arc_cnt_cmp
          INSERT INTO xxcmn_ic_tran_cmp_arc VALUES l_arc_ic_tran_cmp_tab(ln_idx);
--
        /*
        ln_�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��)) := ln_�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��))
                                                                   + ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��));
        ln_���R�~�b�g�o�b�N�A�b�v����(OPM�����݌Ƀg�����U�N�V����(�W��)) := 0;
        lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u���DDELETE;
         */
        gn_arc_cnt_cmp     := gn_arc_cnt_cmp + ln_arc_cnt_cmp;
        ln_arc_cnt_cmp     := 0;
        ln_arc_cnt_cmp_yet := 0;
        l_arc_ic_tran_cmp_tab.DELETE;
        l_ic_tran_cmp_tab.DELETE;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_token_kinoumei := cv_token_opm_cmp;
          FND_FILE.PUT_LINE (FND_FILE.LOG, SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
          ln_transaction_id := l_arc_ic_tran_cmp_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).trans_id;
          RAISE local_process_expt;
      END;
--
    END IF;
--
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'OPM�����݌�TRN(�ړ�)����:' || TO_CHAR(gn_arc_cnt_cmp));

--�����܂�
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    WHEN local_process_expt THEN
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
      IF ( ln_transaction_id IS NOT NULL ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_token_bkup
                      ,iv_token_name2  => cv_token_kinoumei
                      ,iv_token_value2 => lv_token_kinoumei
                      ,iv_token_name3  => cv_token_keyname
                      ,iv_token_value3 => cv_token_trans_id
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(ln_transaction_id)
                     );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�

    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';             -- ���팏���F ��CNT ��
    cv_arc_cnt_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ��TBL_NAME ��SHORI �����F ��CNT ��
    cv_token_cnt       CONSTANT VARCHAR2(100) := 'CNT';                         -- �������b�Z�[�W�p�g�[�N�����i�����j
    cv_token_table     CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- �������b�Z�[�W�p�g�[�N�����i�e�[�u�����j
    cv_token_shori     CONSTANT VARCHAR2(100) := 'SHORI';                       -- �������b�Z�[�W�p�g�[�N�����i�������j
    cv_table_itp       CONSTANT VARCHAR2(100) := 'OPM�ۗ��݌Ƀg�����U�N�V����'; -- �������b�Z�[�W�p�e�[�u����
    cv_table_itc       CONSTANT VARCHAR2(100) := 'OPM�����݌Ƀg�����U�N�V����'; -- �������b�Z�[�W�p�e�[�u����
    cv_shori_name      CONSTANT VARCHAR2(100) := '�o�b�N�A�b�v';                -- �������b�Z�[�W�p������

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
    --OPM�ۗ��݌Ƀg�����U�N�V�����o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_arc_cnt_msg
                    ,iv_token_name1  => cv_token_table
                    ,iv_token_value1 => cv_table_itp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori_name
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_pnd)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --OPM�����݌Ƀg�����U�N�V�����o�b�N�A�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_arc_cnt_msg
                    ,iv_token_name1  => cv_token_table
                    ,iv_token_value1 => cv_table_itc
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori_name
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_cmp)
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
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_pnd + gn_arc_cnt_cmp)
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
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCMN960005C;
/
