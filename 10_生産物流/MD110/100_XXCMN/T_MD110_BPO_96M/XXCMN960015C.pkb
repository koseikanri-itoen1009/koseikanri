CREATE OR REPLACE PACKAGE BODY XXCMN960015C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960015C(body)
 * Description      : OPM�ۗ��^�����݌Ƀg�����X�V
 * MD.050           : T_MD050_BPO_96M_OPM�ۗ��^�����݌Ƀg�����X�V
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
 *  2012/11/20   1.00   K.Boku           �V�K�쐬
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
  gn_upd_cnt_suspen       NUMBER;             -- �X�V����(OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j)
  gn_upd_cnt_complete     NUMBER;             -- �X�V����(OPM�����݌Ƀg�����U�N�V�����i�W���j)
  gt_trans_id_suspen     ic_tran_pnd.trans_id%TYPE;   --�g�����U�N�V����ID�i�ۗ��j
  gt_trans_id_complete   ic_tran_pnd.trans_id%TYPE;   --�g�����U�N�V����ID�i�����j
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960015C'; -- �p�b�P�[�W��
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
    cv_prg_name                CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_get_priod_msg           CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- �p�[�W���Ԃ̎擾�Ɏ��s���܂����B
    cv_get_profile_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- �v���t�@�C��[ ��NG_PROFILE ]�̎擾�Ɏ��s���܂����B
    cv_others_msg_suspen       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11038';  -- �X�V�����Ɏ��s���܂����B�i�ۗ��j
    cv_others_msg_cmp          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11039';  -- �X�V�����Ɏ��s���܂����B�i�����j
    cv_token_profile           CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key               CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range      CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_purge_range       CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';
    cv_org_id                  CONSTANT VARCHAR2(100) := 'ORG_ID';
--
    cv_order_04                CONSTANT VARCHAR2(2)   := '04';
    cv_order_08                CONSTANT VARCHAR2(2)   := '08';
    cv_mov_06                  CONSTANT VARCHAR2(2)   := '06';
    cv_doc_type                CONSTANT VARCHAR2(2)   := '20';
    cv_rec_type_20             CONSTANT VARCHAR2(2)   := '20';
    cv_rec_type_30             CONSTANT VARCHAR2(2)   := '30';
--
    cv_omso                    CONSTANT VARCHAR2(4)   := 'OMSO';
    cv_porc                    CONSTANT VARCHAR2(4)   := 'PORC';
    cv_xfer                    CONSTANT VARCHAR2(4)   := 'XFER';
    cv_trni                    CONSTANT VARCHAR2(4)   := 'TRNI';
    cv_order                   CONSTANT VARCHAR2(5)   := 'ORDER';
    cv_return                  CONSTANT VARCHAR2(6)   := 'RETURN';
    cv_adji                    CONSTANT VARCHAR2(4)   := 'ADJI';
--
    cv_move_actual             CONSTANT VARCHAR2(20)  := 'X122';
    cv_move_actual_upd         CONSTANT VARCHAR2(20)  := 'X123';
--
    cv_date_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
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
    cv_purge_type   CONSTANT VARCHAR2(1)  := '0';       -- �p�[�W�^�C�v�i0:�p�[�W�������ԁj
    cv_purge_code   CONSTANT VARCHAR2(30) := '9601';    -- �p�[�W��`�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_upd_cnt_suspen_yet     NUMBER DEFAULT 0;                   -- ���R�~�b�g�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j
    ln_upd_cnt_complete_yet   NUMBER DEFAULT 0;                   -- ���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
    ln_upd_cnt_suspen         NUMBER DEFAULT 0;                   -- ���������iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j
    ln_upd_cnt_complete       NUMBER DEFAULT 0;                   -- ���������iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
    ln_purge_period           NUMBER;                             -- �p�[�W����
    ld_standard_date          DATE;                               -- ���
    ln_commit_range           NUMBER;                             -- �����R�~�b�g��
    ln_purge_range            NUMBER;                             -- �p�[�W�����W
    lt_org_id                 oe_order_headers_all.org_id%TYPE;   -- �c�ƒP��
    lv_process_part           VARCHAR2(1000);                     -- ������
    ln_before_header_id       NUMBER;                             -- �w�b�_ID
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�i�󒍁j
    CURSOR �X�V�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�i�󒍁j�擾
      id_���  IN DATE
      in_�p�[�W�����W IN NUMBER
      in_�c�ƒP�ʂh�c IN �󒍃w�b�_�i�W���j�D�c�ƒP�ʂh�c%TYPE
    IS
      SELECT 
             OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
      FROM �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
           ,    �󒍃^�C�v�i�W���j
           ,    �󒍃w�b�_�i�W���j�o�b�N�A�b�v
           ,    �󒍖��ׁi�W���j�o�b�N�A�b�v
           ,    OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
           ,    OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j
      WHERE �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�X�e�[�^�X IN ('04','08')
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ד� >= id_��� - in_�p�[�W�����W
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ד� < id_���
      AND �󒍃^�C�v�i�W���j�D�󒍃^�C�vID = �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃^�C�vID
      AND �󒍃^�C�v�i�W���j�D�󒍃J�e�S���R�[�h = 'ORDER'
      AND �󒍃w�b�_�i�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID = �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃w�b�_ID
      AND �󒍃w�b�_�i�W���j�o�b�N�A�b�v�D�c�ƒP��ID = in_�c�ƒP��ID
      AND �󒍖��ׁi�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID = �󒍃w�b�_�i�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D������הԍ� = �󒍖��ׁi�W���j�o�b�N�A�b�v�D�󒍖���ID
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D�����^�C�v = 'OMSO'
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID = OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D�g�����U�N�V����ID
      UNION
      -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�i�ԕi�j
      SELECT 
             OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
      FROM �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
           ,    �󒍃^�C�v�i�W���j
           ,    �󒍃w�b�_�i�W���j�o�b�N�A�b�v
           ,    �󒍖��ׁi�W���j�o�b�N�A�b�v
           ,    ������ׁi�W���j�o�b�N�A�b�v
           ,    OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
           ,    OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j
      WHERE �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�X�e�[�^�X IN ('04','08')
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ד� >= id_��� - in_�p�[�W�����W
      AND �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D���ד� < id_���
      AND �󒍃^�C�v�i�W���j�D�󒍃^�C�vID = �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃^�C�vID
      AND �󒍃^�C�v�i�W���j�D�󒍃J�e�S���R�[�h = 'RETURN'
      AND �󒍃w�b�_�i�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID = �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v�D�󒍃w�b�_ID
      AND �󒍃w�b�_�i�W���j�o�b�N�A�b�v�D�c�ƒP��ID = in_�c�ƒP��ID
      AND �󒍖��ׁi�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID = �󒍃w�b�_�i�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID
      AND ������ׁi�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID = �󒍖��ׁi�W���j�o�b�N�A�b�v�D�󒍃w�b�_ID
      AND ������ׁi�W���j�o�b�N�A�b�v�D�󒍖���ID = �󒍖��ׁi�W���j�o�b�N�A�b�v�D�󒍖���ID
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D����ID = ������ׁi�W���j�o�b�N�A�b�v�D����w�b�_ID
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D������הԍ� = ������ׁi�W���j�o�b�N�A�b�v�D���הԍ�
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D�����^�C�v = 'PORC'
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID = OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D�g�����U�N�V����ID
      UNION
      -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�i�ړ��j
      SELECT 
             OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
      FROM �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v
           ,    �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v
           ,    OPM�݌ɓ]���}�X�^(�W��)
           ,    OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
           ,    OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D�X�e�[�^�X �� '06'
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D���Ɏ��ѓ� >= id_��� - in_�p�[�W�����W
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D���Ɏ��ѓ� < id_���
      AND �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v�D�ړ��w�b�_ID = �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D�ړ��w�b�_ID
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D����ID = OPM�݌ɓ]���}�X�^(�W��)�D�]��ID
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�����^�C�v = 'XFER'
      AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�D�g�����U�N�V����ID = OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�g�����U�N�V����ID
      AND EXISTS (
               SELECT 1
               FROM �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
               WHERE �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D����ID = �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v�D�ړ�����ID
               AND �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D�����^�C�v = '20'
               AND �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D���R�[�h�^�C�v IN ('20','30')
               AND OPM�݌ɓ]���}�X�^(�W��)�DDFF1 = �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D����ID
               AND OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D���b�gID = �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D���b�gID
               AND ROWNUM = 1
             )
      AND OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D���R�R�[�h = 'X122'�i�ړ����сj
     */
    CURSOR upd_suspen_tran_cur(
      id_standard_date           DATE
     ,in_purge_range             NUMBER
     ,it_org_id                  oe_order_headers_all.org_id%TYPE
    )
    IS
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa otta xoohaa xoolaa xitpa itp) INDEX(xohaa XXCMN_OHAA_N15) */
              0                 AS pre_sort_key
             ,xohaa.header_id   AS header_id
             ,itp.trans_id      AS trans_id
      FROM    xxcmn_order_headers_all_arc     xohaa          -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
             ,oe_transaction_types_all        otta           -- �󒍃^�C�v�i�W���j
             ,xxcmn_oe_order_headers_all_arc  xoohaa         -- �󒍃w�b�_�i�W���j�o�b�N�A�b�v
             ,xxcmn_oe_order_lines_all_arc    xoolaa         -- �󒍖��ׁi�W���j�o�b�N�A�b�v
             ,xxcmn_ic_tran_pnd_arc           xitpa          -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
             ,ic_tran_pnd                     itp            -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j
      WHERE   xohaa.req_status          IN (cv_order_04, cv_order_08)
      AND     xohaa.arrival_date        >= id_standard_date - in_purge_range
      AND     xohaa.arrival_date         < id_standard_date
      AND     otta.transaction_type_id   = xohaa.order_type_id
      AND     otta.order_category_code   = cv_order
      AND     xoohaa.header_id           = xohaa.header_id
      AND     xoohaa.org_id              = it_org_id
      AND     xoolaa.header_id           = xoohaa.header_id
      AND     xitpa.line_id              = xoolaa.line_id
      AND     xitpa.doc_type             = cv_omso
      AND     itp.trans_id               = xitpa.trans_id
      UNION
      -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)(�ԕi)
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa otta xoohaa xoolaa xrsla xitpa itp) INDEX(xohaa XXCMN_OHAA_N15) */
              1                 AS pre_sort_key
             ,xohaa.header_id   AS header_id
             ,itp.trans_id      AS trans_id
      FROM    xxcmn_order_headers_all_arc     xohaa          -- �󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
             ,oe_transaction_types_all        otta           -- �󒍃^�C�v�i�W���j
             ,xxcmn_oe_order_headers_all_arc  xoohaa         -- �󒍃w�b�_�i�W���j�o�b�N�A�b�v
             ,xxcmn_oe_order_lines_all_arc    xoolaa         -- �󒍖��ׁi�W���j�o�b�N�A�b�v
             ,xxcmn_rcv_shipment_lines_arc    xrsla          -- ������ׁi�W���j�o�b�N�A�b�v
             ,xxcmn_ic_tran_pnd_arc           xitpa          -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
             ,ic_tran_pnd                     itp            -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j
      WHERE   xohaa.req_status           IN (cv_order_04, cv_order_08)
      AND     xohaa.arrival_date         >= id_standard_date - in_purge_range
      AND     xohaa.arrival_date          < id_standard_date
      AND     otta.transaction_type_id    = xohaa.order_type_id
      AND     otta.order_category_code    = cv_return
      AND     xoohaa.header_id            = xohaa.header_id
      AND     xoohaa.org_id               = it_org_id
      AND     xoolaa.header_id            = xoohaa.header_id
      AND     xrsla.oe_order_header_id    = xoolaa.header_id
      AND     xrsla.oe_order_line_id      = xoolaa.line_id
      AND     xitpa.doc_id                = xrsla.shipment_header_id
      AND     xitpa.doc_line              = xrsla.line_num
      AND     xitpa.doc_type              = cv_porc
      AND     itp.trans_id                = xitpa.trans_id
      UNION
      -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�i�ړ��j
      SELECT  /*+ LEADING(xmriha) USE_NL(xmriha xmrila ixm xitpa itp) */
              2                       AS pre_sort_key
             ,xmriha.mov_hdr_id       AS header_id
             ,itp.trans_id            AS trans_id
      FROM    xxcmn_mov_req_instr_hdrs_arc     xmriha        -- �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v
             ,xxcmn_mov_req_instr_lines_arc    xmrila        -- �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v
             ,ic_xfer_mst                      ixm           -- OPM�݌ɓ]���}�X�^(�W��)
             ,xxcmn_ic_tran_pnd_arc            xitpa         -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
             ,ic_tran_pnd                      itp           -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)
      WHERE   xmriha.status                   = cv_mov_06
      AND     xmriha.actual_arrival_date     >= id_standard_date - in_purge_range
      AND     xmriha.actual_arrival_date      < id_standard_date
      AND     xmrila.mov_hdr_id               = xmriha.mov_hdr_id
      AND     ixm.attribute1                  = TO_CHAR(xmrila.mov_line_id)
      AND     xitpa.doc_id                    = ixm.transfer_id
      AND     xitpa.doc_type                  = cv_xfer 
      AND     itp.trans_id                    = xitpa.trans_id
      AND EXISTS (
               SELECT  1
               FROM    xxcmn_mov_lot_details_arc  xmlda
               WHERE   xmlda.mov_line_id        = xmrila.mov_line_id
               AND     xmlda.document_type_code = cv_doc_type
               AND     xmlda.record_type_code  IN (cv_rec_type_20, cv_rec_type_30) 
               AND     xmlda.lot_id             = xitpa.lot_id
               AND     ROWNUM                   = 1
             )
      AND xitpa.reason_code = cv_move_actual
      ORDER BY pre_sort_key,header_id
      ;
    /*
    -- OPM�����݌Ƀg�����U�N�V�����i�W���j�i�ړ��j
    CURSOR �X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�i�ړ��j�擾
      id_���  IN DATE
      in_�p�[�W�����W IN NUMBER
    IS
      SELECT 
             OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
      FROM �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v
           ,    �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v
           ,    �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
           ,    OPM�W���[�i���}�X�^(�W��)
           ,    OPM�݌ɒ����W���[�i��(�W��)
           ,    OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
           ,    OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D�X�e�[�^�X �� '06'
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D���Ɏ��ѓ� >= id_��� - in_�p�[�W�����W
      AND �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D���Ɏ��ѓ� < id_���
      AND �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v�D�ړ��w�b�_ID = �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v�D�ړ��w�b�_ID
      AND OPM�݌ɒ����W���[�i��(�W��)�D�W���[�i��ID = OPM�W���[�i���}�X�^(�W��)�D�W���[�i��ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�����^�C�v = OPM�݌ɒ����W���[�i��(�W��)�D�����^�C�v
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D����ID = OPM�݌ɒ����W���[�i��(�W��)�D����ID
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D������הԍ� = OPM�݌ɒ����W���[�i��(�W��)�D������הԍ�
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�����^�C�v = 'TRNI'
      AND OPM�����݌Ƀg�����U�N�V����(�W��)�D�g�����U�N�V����ID = OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�g�����U�N�V����ID
      AND EXISTS (
               SELECT 1
               FROM �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
               WHERE �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D����ID = �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v�D�ړ�����ID
               AND �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D�����^�C�v = '20'
               AND �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D���R�[�h�^�C�v IN ('20','30')
               AND OPM�W���[�i���}�X�^(�W��)�DDFF1 = �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D����ID
               AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D���b�gID = �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D���b�gID
               AND ROWNUM = 1
             )
      AND �i 
               (          OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�����^�C�v = 'ADJI'
                   AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D���b�gID = �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D���b�gID
                   AND OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D���R�R�[�h = 'X122'�i�ϑ��Ȃ��ړ��j
               )
             OR
               (          OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D�����^�C�v = 'TRNI'
                   AND OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v�D���b�gID = �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v�D���b�gID
                   AND OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v�D���R�R�[�h = 'X123'�i�ړ����ђ����j
               )
             )
     */
    CURSOR upd_complete_tran_cur(
      id_standard_date           DATE
     ,in_purge_range             NUMBER
    )
    IS
      SELECT  /*+ LEADING(xmriha) USE_NL(xmriha xmrila ijm iaj xitca itc) */
              xmriha.mov_hdr_id    AS header_id
             ,itc.trans_id         AS trans_id
      FROM    xxcmn_mov_req_instr_hdrs_arc     xmriha        -- �ړ��˗�/�w���w�b�_(�A�h�I��)�o�b�N�A�b�v
             ,xxcmn_mov_req_instr_lines_arc    xmrila        -- �ړ��˗�/�w������(�A�h�I��)�o�b�N�A�b�v
             ,ic_jrnl_mst                      ijm           -- OPM�W���[�i���}�X�^(�W��)
             ,ic_adjs_jnl                      iaj           -- OPM�݌ɒ����W���[�i��(�W��)
             ,xxcmn_ic_tran_cmp_arc            xitca         -- OPM�����݌Ƀg�����U�N�V����(�W��)�o�b�N�A�b�v
             ,ic_tran_cmp                      itc           -- OPM�����݌Ƀg�����U�N�V����(�W��)
      WHERE   xmriha.status                   = cv_mov_06
      AND     xmriha.actual_arrival_date     >= id_standard_date - in_purge_range
      AND     xmriha.actual_arrival_date      < id_standard_date
      AND     xmrila.mov_hdr_id               = xmriha.mov_hdr_id
      AND     ijm.attribute1                  = TO_CHAR(xmrila.mov_line_id)
      AND     iaj.journal_id                  = ijm.journal_id
      AND     xitca.doc_type                  = iaj.trans_type
      AND     xitca.doc_id                    = iaj.doc_id
      AND     xitca.doc_line                  = iaj.doc_line
      AND     itc.trans_id                    = xitca.trans_id
      AND EXISTS (
               SELECT  1
               FROM    xxcmn_mov_lot_details_arc  xmlda
               WHERE   xmlda.mov_line_id        = xmrila.mov_line_id
               AND     xmlda.document_type_code = cv_doc_type
               AND     xmlda.record_type_code  IN (cv_rec_type_20, cv_rec_type_30) 
               AND     xitca.lot_id             = xmlda.lot_id
               AND     ROWNUM                   = 1
             )
      AND     (
                (
                       xitca.doc_type         = cv_trni
                  AND xitca.reason_code       = cv_move_actual
                )
              OR
                (
                       xitca.doc_type         = cv_adji
                  AND xitca.reason_code       = cv_move_actual_upd
                )
              )
    ORDER BY header_id
    ;    
    -- <�J�[�\����>���R�[�h�^
    TYPE l_ic_tran_pnd_ttype  IS TABLE OF upd_suspen_tran_cur%ROWTYPE INDEX BY BINARY_INTEGER;    -- OPM�ۗ��݌�TRN(�W��)�e�[�u���^�C�v
    TYPE l_ic_tran_cmp_ttype  IS TABLE OF upd_complete_tran_cur%ROWTYPE INDEX BY BINARY_INTEGER;  -- OPM�����݌�TRN(�W��)�e�[�u���^�C�v
--
    TYPE l_xxcmn_ic_tran_pnd_arc_ttype  IS TABLE OF xxcmn_ic_tran_pnd_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM�ۗ��݌�TRN�o�b�N�A�b�v�e�[�u���^�C�v
    TYPE l_xxcmn_ic_tran_cmp_arc_ttype  IS TABLE OF xxcmn_ic_tran_cmp_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM�����݌�TRN�o�b�N�A�b�v�e�[�u���^�C�v
--
    l_ic_tran_pnd_tab     l_ic_tran_pnd_ttype;        -- OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�e�[�u��
    l_ic_tran_cmp_tab     l_ic_tran_cmp_ttype;        -- OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u��
--
    l_arc_ic_tran_pnd_tab     l_xxcmn_ic_tran_pnd_arc_ttype;         -- OPM�ۗ��݌�TRN�o�b�N�A�b�v�e�[�u��
    l_arc_ic_tran_cmp_tab     l_xxcmn_ic_tran_cmp_arc_ttype;         -- OPM�����݌�TRN�o�b�N�A�b�v�e�[�u��
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
    gn_upd_cnt_suspen := 0;
    gn_upd_cnt_complete   := 0;
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
    ln_�c�ƒP��ID := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾�iMO:�c�ƒP�ʁj);
     */
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j';
    ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    ln_purge_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
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
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_org_id || '�j';
    lt_org_id  := TO_NUMBER((fnd_profile.value(cv_org_id)));
    IF ( lt_org_id IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_org_id
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �X�V�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�擾
    -- ===============================================
    /*
    OPEN �X�V�Ώ�OPM�ۗ��݌Ƀg�����U�N�V����(�W��)�擾(
                                     ld_standard_date
                                    ,ln_archive_range
                                    ,lt_org_id
                                   );
    FETCH �X�V�Ώ�OPM�ۗ��݌Ƀg�����U�N�V����(�W��) BULK COLLECT INTO lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��;
     */
    OPEN upd_suspen_tran_cur(
      ld_standard_date
     ,ln_purge_range
     ,lt_org_id
    );
    FETCH upd_suspen_tran_cur BULK COLLECT INTO l_ic_tran_pnd_tab;
    IF ( l_ic_tran_pnd_tab.COUNT ) > 0 THEN
      /*
      FOR ln_main_idx IN 1 .. �X�V�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�e�[�u��.COUNT LOOP
       */
      << upd_suspen_tran_loop >>
      FOR ln_main_idx in 1 .. l_ic_tran_pnd_tab.COUNT
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
          ln_�O��w�b�_ID <> lt_OPM�ۗ��݌Ƀg�����U�N�V�����e�[�u��.�w�b�_ID�̏ꍇ�A�R�~�b�g�����W���J�E���g;
           */
          IF ( ln_before_header_id <> l_ic_tran_pnd_tab(ln_main_idx).header_id ) THEN
            ln_upd_cnt_suspen_yet := ln_upd_cnt_suspen_yet + 1;
          END IF;
          /*
          ln_���R�~�b�g�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j > 0 
          ���� MOD(ln_���R�~�b�g�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
           */
          IF (  (ln_upd_cnt_suspen_yet > 0)
            AND (MOD(ln_upd_cnt_suspen_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            ln_�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j := ln_�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j
                                                                               + ln_���������iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j;
            ln_���R�~�b�g�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j := 0;
            COMMIT;
             */
            gn_upd_cnt_suspen    := gn_upd_cnt_suspen + ln_upd_cnt_suspen;
            ln_upd_cnt_suspen    := 0;
            ln_upd_cnt_suspen_yet:= 0;
            COMMIT;
--
          END IF;
--
        END IF;
--
        /*
        ln_�������� := ln_�������� + 1;
         */
        ln_upd_cnt_suspen := ln_upd_cnt_suspen + 1;
        l_arc_ic_tran_pnd_tab(ln_upd_cnt_suspen).trans_id := l_ic_tran_pnd_tab(ln_main_idx).trans_id;
        /*
        ln_�Ώەۗ��݌Ƀg�����U�N�V����ID := l_ic_tran_pnd_tab(ln_main_idx)�D�g�����U�N�V����ID;
        ln_�Ώەۗ��݌Ƀw�b�_ID(�ꎞ) := l_ic_tran_pnd_tab(ln_main_idx).header_id;
         */
        gt_trans_id_suspen := l_ic_tran_pnd_tab(ln_main_idx).trans_id;
        ln_before_header_id := l_ic_tran_pnd_tab(ln_main_idx).header_id;
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===================================================
        -- �X�V�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j���b�N
        -- ===================================================
        /*
        SELECT
              OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
        FROM OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j
        WHERE OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID = l_ic_tran_pnd_tab(ln_main_idx)�D�g�����U�N�V����ID
        FOR UPDATE NOWAIT
         */
        lv_process_part := '�X�V�Ώ�OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j���b�N';
        SELECT  itp.trans_id      AS trans_id
        INTO    gt_trans_id_suspen
        FROM    ic_tran_pnd  itp
        WHERE   itp.trans_id = l_ic_tran_pnd_tab(ln_main_idx).trans_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�X�V
        -- ===============================================
        /*
        UPDATE OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j
        SET GL�]���σt���O = 1
           ,   �ŏI�X�V�� = ���[�U�[ID
           ,   �ŏI�X�V���O�C�� = ���O�C��ID
           ,   �v���O�����A�v���P�[�V����ID = �v���O�����A�v���P�[�V����ID
           ,   �v���O����ID = �R���J�����g�v���O����ID
           ,   �v���O�����X�V�� = SYSDATE
           ,   ���N�G�X�gID = �R���J�����g���N�G�X�gID
        WHERE �g�����U�N�V����ID = l_ic_tran_pnd_tab(ln_main_idx)�D�g�����U�N�V����ID
        ;
         */
        lv_process_part := 'OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�X�V';
        UPDATE ic_tran_pnd
        SET    gl_posted_ind            = cv_gl_post_fla
              ,last_updated_by          = cn_last_updated_by
              ,last_update_login        = cn_last_update_login
              ,program_application_id   = cn_program_application_id
              ,program_id               = cn_program_id
              ,program_update_date      = SYSDATE
              ,request_id               = cn_request_id
        WHERE  trans_id = l_ic_tran_pnd_tab(ln_main_idx).trans_id
        ;
--
      END LOOP upd_suspen_tran_loop;
--
      /*
      ln_�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j := ln_�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j
                                                             + ln_���������iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j;
      ln_���������iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j := 0;
      ln_���R�~�b�g�X�V�����iOPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j := 0;
      ln_�O��w�b�_ID := 0;
      lt_OPM�����݌Ƀg�����U�N�V����(�o�b�N�A�b�v)�e�[�u���DDELETE;
      lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u���DDELETE;
       */
      gn_upd_cnt_suspen := gn_upd_cnt_suspen + ln_upd_cnt_suspen;
      ln_upd_cnt_suspen := 0;
      ln_upd_cnt_suspen_yet := 0;
      ln_before_header_id := NULL;
      l_arc_ic_tran_pnd_tab.DELETE;
      l_ic_tran_pnd_tab.DELETE;
      COMMIT;
    END IF;
--
    -- =======================================================
    -- �X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�擾�i�ړ��j
    -- =======================================================
    /*
    OPEN�X�V�Ώ�OPM�����݌Ƀg�����U�N�V����(�W��)�擾(
                                     ld_standard_date
                                    ,ln_archive_range
                                   );
    FETCH �X�V�Ώ�OPM�����݌Ƀg�����U�N�V����(�W��) BULK COLLECT INTO lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��;
     */
    OPEN upd_complete_tran_cur(
      ld_standard_date
     ,ln_purge_range
    );
    FETCH upd_complete_tran_cur BULK COLLECT INTO l_ic_tran_cmp_tab;
    /*
    IF lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��.count > 0 THEN
      << upd_complete_tran_loop >>
      FOR ln_main_idx in 1 .. lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��.COUNT
      LOOP
    */
    IF ( l_ic_tran_cmp_tab.COUNT ) > 0 THEN
      << upd_complete_tran_loop >>
      FOR ln_main_idx in 1 .. l_ic_tran_cmp_tab.COUNT
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
          ln_�O��w�b�_ID <> lt_OPM�����݌Ƀg�����U�N�V�����e�[�u��.�w�b�_ID�̏ꍇ�A�R�~�b�g�����W���J�E���g;
           */
          IF ( ln_before_header_id <> l_ic_tran_cmp_tab(ln_main_idx).header_id ) THEN
            ln_upd_cnt_complete_yet := ln_upd_cnt_complete_yet + 1;
          END IF;
          /*
          ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j > 0 
          ���� MOD(ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j, ln_�����R�~�b�g��) = 0�̏ꍇ
           */
          IF (  (ln_upd_cnt_complete_yet > 0)
            AND (MOD(ln_upd_cnt_complete_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            ln_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := ln_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
                                                                               + ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j;
            ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := 0;
            COMMIT;
             */
            gn_upd_cnt_complete    := gn_upd_cnt_complete + ln_upd_cnt_complete;
            ln_upd_cnt_complete    := 0;
            ln_upd_cnt_complete_yet:= 0;
            COMMIT;
--
          END IF;
--
        END IF;
--
        /*
        ln_�������� := ln_�������� + 1;
        lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u���փo�b�N�A�b�v;
         */
        ln_upd_cnt_complete := ln_upd_cnt_complete + 1;
        l_arc_ic_tran_cmp_tab(ln_upd_cnt_complete).trans_id := l_ic_tran_cmp_tab(ln_main_idx).trans_id;
        /*
        ln_�Ώۊ����݌Ƀg�����U�N�V����ID := l_ic_tran_cmp_tab(ln_main_idx)�D�g�����U�N�V����ID;
        ln_�Ώەۗ��݌Ƀw�b�_ID(�ꎞ) := l_ic_tran_pnd_tab(ln_main_idx).header_id;
         */
        gt_trans_id_complete := l_ic_tran_cmp_tab(ln_main_idx).trans_id;
        ln_before_header_id := l_ic_tran_cmp_tab(ln_main_idx).header_id;
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===================================================
        -- �X�V����OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�j���b�N
        -- ===================================================
        /*
        SELECT
              OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID
        FROM OPM�����݌Ƀg�����U�N�V�����i�W���j
        WHERE OPM�����݌Ƀg�����U�N�V�����i�W���j�D�g�����U�N�V����ID = l_ic_tran_cmp_tab(ln_main_idx)�D�g�����U�N�V����ID
        FOR UPDATE NOWAIT
         */
        lv_process_part := '�X�V�Ώ�OPM�����݌Ƀg�����U�N�V�����i�W���j�j���b�N';
        SELECT  itc.trans_id      AS trans_id
        INTO    gt_trans_id_complete
        FROM    ic_tran_cmp  itc
        WHERE   itc.trans_id = l_ic_tran_cmp_tab(ln_main_idx).trans_id
        FOR UPDATE NOWAIT
        ;
--
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
        WHERE �g�����U�N�V����ID = l_ic_tran_cmp_tab(ln_main_idx)�D�g�����U�N�V����ID
        ;
         */
        lv_process_part := 'OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�X�V';
        UPDATE ic_tran_cmp
        SET    gl_posted_ind            = cv_gl_post_fla
              ,last_update_date         = SYSDATE
              ,last_updated_by          = cn_last_updated_by
              ,last_update_login        = cn_last_update_login
              ,program_application_id   = cn_program_application_id
              ,program_id               = cn_program_id
              ,program_update_date      = SYSDATE
              ,request_id               = cn_request_id
        WHERE  trans_id = l_ic_tran_cmp_tab(ln_main_idx).trans_id
        ;
--
      END LOOP upd_complete_tran_loop;
--      
    /*
    ln_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := ln_�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j
                                                                       + ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j;
    ln_���R�~�b�g�X�V�����iOPM�����݌Ƀg�����U�N�V�����i�W���j�j := 0;
    lt_OPM�����݌Ƀg�����U�N�V����(�W��)�e�[�u���DDELETE;
     */
    gn_upd_cnt_complete := gn_upd_cnt_complete + ln_upd_cnt_complete;
    ln_upd_cnt_complete := 0;
    ln_upd_cnt_complete_yet := 0;
    ln_before_header_id := NULL;
    l_ic_tran_cmp_tab.DELETE;
    l_arc_ic_tran_cmp_tab.DELETE;
    END IF;
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
      IF ( gt_trans_id_suspen IS NOT NULL AND gt_trans_id_complete IS NULL) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_msg_suspen
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_trans_id_suspen)
                     );
      ELSIF ( gt_trans_id_complete IS NOT NULL) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_msg_cmp
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_trans_id_complete)
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
    cv_prg_name           CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name    CONSTANT VARCHAR2(10)  := 'XXCMN';            -- �A�h�I���F���ʁEIF�̈�
    cv_upd_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';  -- �X�V�����F ��CNT ��
    cv_target_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11008';  -- �Ώی����F ��CNT ��
    cv_success_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- ���팏���F ��CNT ��
    cv_error_rec_msg      CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- �G���[�����F ��CNT ��
    cv_proc_date_msg      CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- �������F ��PAR
    cv_cnt_token          CONSTANT VARCHAR2(10)  := 'CNT';              -- �������b�Z�[�W�p�g�[�N����
    cv_par_token          CONSTANT VARCHAR2(10)  := 'PAR';              -- ���������b�Z�[�W�p�g�[�N����
    cv_token_tbl_name     CONSTANT VARCHAR2(10)  := 'TBL_NAME';
    cv_token_shori        CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_tbl_name_suspen    CONSTANT VARCHAR2(100) := 'OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j';
    cv_tbl_name_cmp       CONSTANT VARCHAR2(100) := 'OPM�����݌Ƀg�����U�N�V�����i�W���j';
    cv_shori              CONSTANT VARCHAR2(10)  := '�X�V';
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
    --�X�V�����P�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_upd_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_suspen
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_upd_cnt_suspen)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�V�����Q�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_upd_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_cmp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_upd_cnt_complete)
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
                    ,iv_token_name1  => cv_cnt_token
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
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_suspen + gn_upd_cnt_complete)
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
END XXCMN960015C;
/
