CREATE OR REPLACE PACKAGE BODY xxinv450001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv450001c(body)
 * Description      : ���ьv��σt���O�X�V����
 * MD.050           : ���ьv��σt���O�X�V T_MD050_BPO_450
 * MD.070           : ���ьv��σt���O�X�V����(45A)
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  initialize                ��������              (A-1)
 *  chk_param                 ���̓p�����[�^�`�F�b�N(A-2)
 *  get_prod_data             �Ώۃf�[�^�擾�i���Y�j(A-3)
 *  get_po_data               �Ώۃf�[�^�擾�i�����j(A-4)
 *  upd_actual_confirm_class  ���ьv��σt���O�X�V  (A-5)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/01    1.0   H.Itou           �V�K�쐬
 *  2010/03/17    1.1   M.Hokkanji       �{�ԉғ���Q#1612(�������[���Ɏ��ьv���
 *                                       �t���O���������X�V����Ȃ������C��)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                CONSTANT VARCHAR2(100) := 'xxinv450001c';    -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn                   CONSTANT VARCHAR2(100) := 'XXCMN';           -- ���W���[�������́FXXCMN
  gv_xxinv                   CONSTANT VARCHAR2(100) := 'XXINV';           -- ���W���[�������́FXXINV
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10002          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- �v���t�@�C���擾�G���[
  gv_msg_xxcmn05002          CONSTANT VARCHAR2(100) := 'APP-XXCMN-05002'; -- �������s
  gv_msg_xxcmn10019          CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- ���b�N�G���[
  gv_msg_xxinv10055          CONSTANT VARCHAR2(100) := 'APP-XXINV-10055'; -- ���t�t�]�G���[���b�Z�[�W
--
  -- �g�[�N��
  gv_tkn_table               CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_ship_date           CONSTANT VARCHAR2(100) := 'SHIP_DATE';
  gv_tkn_arrival_date        CONSTANT VARCHAR2(100) := 'ARRIVAL_DATE';
  gv_tkn_ng_profile          CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_process             CONSTANT VARCHAR2(100) := 'PROCESS';
--
  -- �g�[�N���l
  gv_table_name              CONSTANT VARCHAR2(100) := '�ړ����b�g�ڍ�';
  gv_date_from_name          CONSTANT VARCHAR2(100) := '�X�V���t(FROM)';
  gv_date_to_name            CONSTANT VARCHAR2(100) := '�X�V���t(TO)';
  gv_org_id_name             CONSTANT VARCHAR2(100) := '�g�DID';
  gv_get_process_date        CONSTANT VARCHAR2(100) := '�Ɩ����t�擾';
  gv_get_working_day         CONSTANT VARCHAR2(100) := '�c�Ɠ����t�擾';
--
  -- �f�[�^�t�H�[�}�b�g
  gv_datetime_fmt            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt                CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';
  gv_min_time                CONSTANT VARCHAR2(100) := ' 00:00:00';
  gv_max_time                CONSTANT VARCHAR2(100) := ' 23:59:59';
--
  -- �ړ����b�g�ڍׂ̌Œ�l
  gt_document_type_prod      CONSTANT xxinv_mov_lot_details.document_type_code  %TYPE := '40'; -- �����^�C�v ���Y
  gt_document_type_po        CONSTANT xxinv_mov_lot_details.document_type_code  %TYPE := '50'; -- �����^�C�v ����
  gt_actual_confirm_class_n  CONSTANT xxinv_mov_lot_details.actual_confirm_class%TYPE := 'N' ; -- ���ьv��σt���O ���v��
  gt_actual_confirm_class_y  CONSTANT xxinv_mov_lot_details.actual_confirm_class%TYPE := 'Y' ; -- ���ьv��σt���O �v���
--
  -- �ۗ��݌Ƀg�����U�N�V�����̌Œ�l
  gt_delete_y                CONSTANT ic_tran_pnd.delete_mark   %TYPE := 1;      -- �폜�t���O�F�폜
  gt_delete_n                CONSTANT ic_tran_pnd.delete_mark   %TYPE := 0;      -- �폜�t���O�F�폜����Ă��Ȃ�
  gt_complete_y              CONSTANT ic_tran_pnd.completed_ind %TYPE := 1;      -- EBS�Ɏ��є��f��
  gt_complete_n              CONSTANT ic_tran_pnd.completed_ind %TYPE := 0;      -- EBS�Ɏ��і����f
  gt_doc_type_prod           CONSTANT ic_tran_pnd.doc_type      %TYPE := 'PROD'; -- �����^�C�v�F���Y
--
  -- �����̌Œ�l
-- Ver1.1 M.Hokkanji Start
  gt_status_ukeari           CONSTANT po_headers_all.attribute1 %TYPE := '25'; -- �X�e�[�^�X�F����L
-- Ver1.1 M.Hokkanji End
  gt_status_suukaku          CONSTANT po_headers_all.attribute1 %TYPE := '30'; -- �X�e�[�^�X:���ʊm���
  gt_status_kinkaku          CONSTANT po_headers_all.attribute1 %TYPE := '35'; -- �X�e�[�^�X:���z�m���
  gt_aitesaki                CONSTANT po_headers_all.attribute11%TYPE := '3' ; -- �����敪:�����݌�
  gt_suukaku_y               CONSTANT po_lines_all.attribute13  %TYPE := 'Y' ; -- ���ʊm��σt���O�F�m��
  gt_suukaku_n               CONSTANT po_lines_all.attribute13  %TYPE := 'N' ; -- ���ʊm��σt���O�F���m��
  gt_cancel_y                CONSTANT po_lines_all.cancel_flag  %TYPE := 'Y' ; -- �폜�t���O�F�폜
  gt_cancel_n                CONSTANT po_lines_all.cancel_flag  %TYPE := 'N' ; -- �폜�t���O�F�폜����Ă��Ȃ�

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �ړ����b�g�ڍ�ID �e�[�u���^
  TYPE t_mov_lot_dtl_id IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_prod_cnt            NUMBER;            -- ���Y����
  gn_po_cnt              NUMBER;            -- ��������
--
  gn_user_id             NUMBER;            -- ���[�UID
  gn_login_id            NUMBER;            -- �ŏI�X�V���O�C��
  gn_conc_request_id     NUMBER;            -- �v��ID
  gn_prog_appl_id        NUMBER;            -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id     NUMBER;            -- �R���J�����g�E�v���O����ID
--
  gd_date_from           DATE;              -- ���̓p�����[�^.�X�V���t(FROM)
  gd_date_to             DATE;              -- ���̓p�����[�^.�X�V���t(TO)
--
  gn_pro_org_id          NUMBER;            -- �g�DID
  gd_process_date        DATE;              -- �Ɩ����t
  gd_prev_process_date   DATE;              -- �Ɩ����t�|�P���̒��߉c�Ɠ�
--
  /**********************************************************************************
   * Procedure Name   :  initialize
   * Description      :  �֘A�f�[�^�擾(A-1)
   ***********************************************************************************/
  PROCEDURE initialize(
    iv_date_from       IN  VARCHAR2          -- IN    �F�X�V���t(FROM)
   ,iv_date_to         IN  VARCHAR2          -- IN    �F�X�V���t(TO)
   ,ov_errbuf          OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'initialize'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    -- �v���t�@�C���I�v�V����
    cv_pro_sys_ctrl_cal CONSTANT VARCHAR2(26) := 'XXCMN_SYS_CAL_CODE'; -- �V�X�e���ғ����J�����_�R�[�h
    cv_pro_org_id       CONSTANT VARCHAR2(26) := 'ORG_ID';             -- �g�DID
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================================
    -- ���O�C�����擾
    -- =================================
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���O�C�����[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ���O�C��ID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �R���J�����g�v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��сE���ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- =================================
    -- �v���t�@�C���I�v�V�����擾
    -- =================================
    gn_pro_org_id       := TO_NUMBER(FND_PROFILE.VALUE(cv_pro_org_id)); -- �g�DID
--
    -- �g�DID���擾�ł��Ȃ��ꍇ�A�v���t�@�C���擾�G���[
    IF ( gn_pro_org_id IS NULL ) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,gv_msg_xxcmn10002
                    ,gv_tkn_ng_profile
                    ,gv_org_id_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =================================
    -- �X�V���t(FROM)�̌���
    -- =================================
    -- NULL�̏ꍇ�A�V�X�e�����t�|�P��
    IF (iv_date_from IS NULL) THEN
      gd_date_from  := TRUNC(SYSDATE) -1;
--
    -- NULL�łȂ��ꍇ�A�w�肵�����t���g�p
    ELSE
      gd_date_from  := TO_DATE(iv_date_from || gv_min_time, gv_datetime_fmt);
    END IF;
--
    -- =================================
    -- �X�V���t(TO)�̌���
    -- =================================
    -- NULL�̏ꍇ�A�V�X�e�����t
    IF (iv_date_from IS NULL) THEN
      gd_date_to  := TO_DATE(TO_CHAR(TRUNC(SYSDATE) -1, cv_date_fmt) || gv_max_time, gv_datetime_fmt);
--
    -- NULL�łȂ��ꍇ�A�w�肵�����t���g�p
    ELSE
      gd_date_to  := TO_DATE(iv_date_to   || gv_max_time, gv_datetime_fmt);
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END initialize;
--
  /**********************************************************************************
   * Procedure Name   :  chk_param
   * Description      :  �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf          OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================================
    -- �X�V���t��FROM��TO�̏ꍇ�A���t�t�]�G���[
    -- =================================
    IF (gd_date_from > gd_date_to) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxinv
                    ,gv_msg_xxinv10055   -- ���t�t�]�G���[���b�Z�[�W
                    ,gv_tkn_ship_date    -- �g�[�N��SHIP_DATE
                    ,gv_date_from_name   -- �g�[�N���l:�X�V���t(FROM)
                    ,gv_tkn_arrival_date -- �g�[�N��ARRIVL_DATE
                    ,gv_date_to_name     -- �g�[�N���l:�X�V���t(TO)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   :  get_prod_data
   * Description      :  �Ώۃf�[�^�擾�i���Y�j(A-3)
   ***********************************************************************************/
  PROCEDURE get_prod_data(
    ot_mov_lot_dtl_id  OUT t_mov_lot_dtl_id  --   �ړ����b�g�ڍ�ID �z��
   ,ov_errbuf          OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_prod_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================================
    -- ���ьv��σf�[�^�擾
    -- =================================
    BEGIN
      SELECT xmld.mov_lot_dtl_id         mov_lot_dtl_id                   -- �ړ����b�g�ڍ�ID
      BULK COLLECT INTO ot_mov_lot_dtl_id
      FROM   xxinv_mov_lot_details       xmld                             -- �ړ����b�g�ڍׁi�A�h�I���j
      WHERE  EXISTS(
               SELECT 1
               FROM   ic_tran_pnd             itp                         -- �ۗ��݌Ƀg�����U�N�V����
               WHERE  itp.line_id           = xmld.mov_line_id            -- 
               AND    itp.delete_mark       = gt_delete_n                 -- �폜����Ă��Ȃ�
               AND    itp.completed_ind     = gt_complete_y               -- EBS�Ɏ��є��f��
               AND    itp.doc_type          = gt_doc_type_prod            -- ���Y
               AND    itp.last_update_date >= gd_date_from                -- �ŏI�X�V�����p�����[�^.�X�V���t(FROM)����X�V���t(TO)�̊Ԃ̃f�[�^
               AND    itp.last_update_date <= gd_date_to                  -- 
             )
      AND    xmld.document_type_code        = gt_document_type_prod       -- �����^�C�v�F���Y
      AND    xmld.actual_confirm_class      = gt_actual_confirm_class_n   -- ���łɈړ����b�g�ڍׂ̎��ьv��σt���O��Y�̂��͍̂X�V�s�v�̂��ߎ擾���Ȃ��B
      FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT
      ;
--
    EXCEPTION
      -- ���Y�Ώۃf�[�^0���ł��������s
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,gv_msg_xxcmn10019   -- ���b�N�G���[
                    ,gv_tkn_table        -- �g�[�N��TABLE
                    ,gv_table_name       -- �g�[�N���l:�ړ����b�g�ڍ�
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_prod_data;
--
  /**********************************************************************************
   * Procedure Name   :  get_po_data
   * Description      :  �Ώۃf�[�^�擾�i�����j(A-4)
   ***********************************************************************************/
  PROCEDURE get_po_data(
    ot_mov_lot_dtl_id  OUT t_mov_lot_dtl_id  --   �ړ����b�g�ڍ�ID �z��
   ,ov_errbuf          OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_po_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================================
    -- ���ьv��σf�[�^�擾
    -- =================================
    BEGIN
      SELECT xmld.mov_lot_dtl_id         mov_lot_dtl_id                             -- �ړ����b�g�ڍ�ID
      BULK COLLECT INTO ot_mov_lot_dtl_id
      FROM   xxinv_mov_lot_details       xmld                                       -- �ړ����b�g�ڍׁi�A�h�I���j
            ,po_lines_all                pla                                        -- ��������
            ,po_headers_all              pha                                        -- �����w�b�_
      WHERE  pla.po_line_id               = xmld.mov_line_id
      AND    pla.po_header_id             = pha.po_header_id
      AND    xmld.document_type_code      = gt_document_type_po                     -- ����
      AND    xmld.actual_confirm_class    = gt_actual_confirm_class_n               -- ���łɈړ����b�g�ڍׂ̎��ьv��σt���O��Y�̂��͍̂X�V�s�v�̂��ߎ擾���Ȃ��B
      AND    pla.attribute13              = gt_suukaku_y                            -- ���ʊm���
      AND    pla.cancel_flag              = gt_cancel_n                             -- �폜����Ă��Ȃ�
      AND    pla.attribute12             IS NOT NULL                                -- �����݌ɓ��ɐ�
      AND    pha.org_id                   = gn_pro_org_id                           -- �g�DID
-- Ver1.1 M.Hokkanji Start
--      AND    pha.attribute1              IN (gt_status_suukaku,gt_status_kinkaku)   -- ���ʊm���,���z�m���
      AND    pha.attribute1              IN (gt_status_ukeari,gt_status_suukaku,gt_status_kinkaku)   -- ����L,���ʊm���,���z�m���
-- Ver1.1 M.Hokkanji End
      AND    pha.attribute11              = gt_aitesaki                             -- �����敪�F�����݌�
      AND    pla.last_update_date        >= gd_date_from                            -- �ŏI�X�V�����p�����[�^.�X�V���t(FROM)����X�V���t(TO)�̊Ԃ̃f�[�^
      AND    pla.last_update_date        <= gd_date_to                              -- 
      FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT
      ;
--
    EXCEPTION
      -- �����Ώۃf�[�^0���ł��������s
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_xxcmn
                    ,gv_msg_xxcmn10019   -- ���b�N�G���[
                    ,gv_tkn_table        -- �g�[�N��TABLE
                    ,gv_table_name       -- �g�[�N���l:�ړ����b�g�ڍ�
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_po_data;
--
  /**********************************************************************************
   * Procedure Name   :  upd_actual_confirm_class
   * Description      :  ���ьv��σt���O�X�V  (A-5)
   ***********************************************************************************/
  PROCEDURE upd_actual_confirm_class(
    it_mov_lot_dtl_id  IN  t_mov_lot_dtl_id  --   �ړ����b�g�ڍ�ID �z��
   ,ov_errbuf          OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_actual_confirm_class'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================================
    -- �ړ����b�g�ڍׂ̎��ьv��σt���O�X�V
    -- =================================
    FORALL ln_cnt IN it_mov_lot_dtl_id.FIRST .. it_mov_lot_dtl_id.LAST
      UPDATE xxinv_mov_lot_details       xmld                            -- �ړ����b�g�ڍ�
      SET    xmld.actual_confirm_class      = gt_actual_confirm_class_y  -- ���ьv��σt���O���uY:���ьv��ρv
            ,xmld.last_updated_by           = gn_user_id                 -- �ŏI�X�V��
            ,xmld.last_update_date          = SYSDATE                    -- �ŏI�X�V��
            ,xmld.last_update_login         = gn_login_id                -- �ŏI�X�V���O�C��
            ,xmld.request_id                = gn_conc_request_id         -- �v��ID
            ,xmld.program_application_id    = gn_prog_appl_id            -- �ݶ��āE��۸��сE���ع����ID
            ,xmld.program_id                = gn_conc_program_id         -- �R���J�����g�E�v���O����ID
            ,xmld.program_update_date       = SYSDATE                    -- �v���O�����X�V��
      WHERE  xmld.mov_lot_dtl_id            = it_mov_lot_dtl_id(ln_cnt)
      ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_actual_confirm_class;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_date_from  IN  VARCHAR2     --   �X�V���t(FROM)
   ,iv_date_to    IN  VARCHAR2     --   �X�V���t(TO)
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_prod_id  t_mov_lot_dtl_id;  --   ���Y �ړ����b�g�ڍ�ID �z��
    lt_po_id    t_mov_lot_dtl_id;  --   ���� �ړ����b�g�ڍ�ID �z��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_prod_cnt   := 0;
    gn_po_cnt     := 0;
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    initialize(
      iv_date_from          => iv_date_from                         -- IN    �F�X�V���t(FROM)
     ,iv_date_to            => iv_date_to                           -- IN    �F�X�V���t(TO)
     ,ov_errbuf             => lv_errbuf                            -- OUT   �F�G���[�E���b�Z�[�W
     ,ov_retcode            => lv_retcode                           -- OUT   �F���^�[���E�R�[�h
     ,ov_errmsg             => lv_errmsg                            -- OUT   �F���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�p�����[�^�`�F�b�N
    -- ===============================
    chk_param(
      ov_errbuf             => lv_errbuf                            -- OUT   �F�G���[�E���b�Z�[�W
     ,ov_retcode            => lv_retcode                           -- OUT   �F���^�[���E�R�[�h
     ,ov_errmsg             => lv_errmsg                            -- OUT   �F���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.�Ώۃf�[�^�擾�i���Y�j
    -- ===============================
    get_prod_data(
      ot_mov_lot_dtl_id     => lt_prod_id                           -- OUT   �F�ړ����b�g�ڍ�ID �z��
     ,ov_errbuf             => lv_errbuf                            -- OUT   �F�G���[�E���b�Z�[�W
     ,ov_retcode            => lv_retcode                           -- OUT   �F���^�[���E�R�[�h
     ,ov_errmsg             => lv_errmsg                            -- OUT   �F���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4.�Ώۃf�[�^�擾�i�����j
    -- ===============================
    get_po_data(
      ot_mov_lot_dtl_id     => lt_po_id                             -- OUT   �F�ړ����b�g�ڍ�ID �z��
     ,ov_errbuf             => lv_errbuf                            -- OUT   �F�G���[�E���b�Z�[�W
     ,ov_retcode            => lv_retcode                           -- OUT   �F���^�[���E�R�[�h
     ,ov_errmsg             => lv_errmsg                            -- OUT   �F���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-5.���ьv��σt���O�X�V
    -- ===============================
    -- ���Y�ɑΏۃf�[�^������ꍇ
    IF (lt_prod_id.COUNT <> 0) THEN
      upd_actual_confirm_class(
       it_mov_lot_dtl_id     => lt_prod_id            -- IN    �F�ړ����b�g�ڍ�ID �z��
      ,ov_errbuf             => lv_errbuf             -- OUT   �F�G���[�E���b�Z�[�W
      ,ov_retcode            => lv_retcode            -- OUT   �F���^�[���E�R�[�h
      ,ov_errmsg             => lv_errmsg             -- OUT   �F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
       --(�G���[����)
       RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �����ɑΏۃf�[�^������ꍇ
    IF (lt_po_id.COUNT <> 0) THEN
      upd_actual_confirm_class(
       it_mov_lot_dtl_id     => lt_po_id              -- IN    �F�ړ����b�g�ڍ�ID �z��
      ,ov_errbuf             => lv_errbuf             -- OUT   �F�G���[�E���b�Z�[�W
      ,ov_retcode            => lv_retcode            -- OUT   �F���^�[���E�R�[�h
      ,ov_errmsg             => lv_errmsg             -- OUT   �F���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
       --(�G���[����)
       RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- �X�V�����擾
    -- ===============================
    gn_normal_cnt := lt_prod_id.COUNT + lt_po_id.COUNT; -- �S��
    gn_prod_cnt   := lt_prod_id.COUNT;                  -- ���Y����
    gn_po_cnt     := lt_po_id.COUNT;                    -- ��������
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf               OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode              OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_date_from         IN  VARCHAR2      --   �X�V���t(FROM)
   ,iv_date_to           IN  VARCHAR2      --   �X�V���t(TO)
   )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_date_from --   �X�V���t(FROM)
     ,iv_date_to   --   �X�V���t(TO
     ,lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'���̓p�����[�^');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�@�X�V���t(FROM)�F'|| TO_CHAR(gd_date_from, 'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�@�X�V���t(TO)  �F'|| TO_CHAR(gd_date_to,   'YYYY/MM/DD HH24:MI:SS'));
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�ړ����b�g�ڍ׍X�V����(�S��)�F'|| TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�ړ����b�g�ڍ׍X�V����(���Y)�F'|| TO_CHAR(gn_prod_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'�ړ����b�g�ڍ׍X�V����(����)�F'|| TO_CHAR(gn_po_cnt));
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv450001c;
/
