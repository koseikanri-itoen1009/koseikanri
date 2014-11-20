CREATE OR REPLACE PACKAGE BODY APPS.XXCCP008A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A02C(body)
 * Description      : ���[�X�����f�[�^CSV�o��
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_input_param        ���̓p�����[�^�`�F�b�N����(A-2)
 *  output_csv             CSV�o�͏���(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/31    1.0   SCSK �J���\��    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10)  := 'XXCCP';                  -- �A�v���P�[�V�����Z�k��
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCCP008A02C';           -- �p�b�P�[�W��
  -- �����R�[�h�w��L���t���O �R�[�h�l
  cv_obj_code_param_off     CONSTANT VARCHAR2(1)   := '0';                      -- �����R�[�h�̎w�薳��
  cv_obj_code_param_on      CONSTANT VARCHAR2(1)   := '1';                      -- �����R�[�h�̎w��L��
  -- CSV�o�͗p
  cv_delimit                CONSTANT VARCHAR2(10)  := ',';                      -- ��؂蕶��
  cv_enclosed               CONSTANT VARCHAR2(10)  := '"';                      -- �P��͂ݕ���
  -- ����
  cv_date_format            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';  -- �W������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_obj_code_param         VARCHAR2(1);                                  -- �����R�[�h�w��L���t���O
  -- ���̓p�����[�^�i�[�p
  gv_contract_number        xxcff_contract_headers.contract_number%TYPE;  -- �p�����[�^�F1. �_��ԍ�
  gv_lease_company          xxcff_contract_headers.lease_company%TYPE;    -- �p�����[�^�F2. ���[�X���
  gv_object_code_01         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F3. �����R�[�h1
  gv_object_code_02         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F4. �����R�[�h2
  gv_object_code_03         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F5. �����R�[�h3
  gv_object_code_04         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F6. �����R�[�h4
  gv_object_code_05         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F7. �����R�[�h5
  gv_object_code_06         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F8. �����R�[�h6
  gv_object_code_07         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F9. �����R�[�h7
  gv_object_code_08         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F10.�����R�[�h8
  gv_object_code_09         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F11.�����R�[�h9
  gv_object_code_10         xxcff_object_headers.object_code%TYPE;        -- �p�����[�^�F12.�����R�[�h10
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_contract_number  IN  VARCHAR2    -- 1. �_��ԍ�
   ,iv_lease_company    IN  VARCHAR2    -- 2. ���[�X���
   ,iv_object_code_01   IN  VARCHAR2    -- 3. �����R�[�h1
   ,iv_object_code_02   IN  VARCHAR2    -- 4. �����R�[�h2
   ,iv_object_code_03   IN  VARCHAR2    -- 5. �����R�[�h3
   ,iv_object_code_04   IN  VARCHAR2    -- 6. �����R�[�h4
   ,iv_object_code_05   IN  VARCHAR2    -- 7. �����R�[�h5
   ,iv_object_code_06   IN  VARCHAR2    -- 8. �����R�[�h6
   ,iv_object_code_07   IN  VARCHAR2    -- 9. �����R�[�h7
   ,iv_object_code_08   IN  VARCHAR2    -- 10.�����R�[�h8
   ,iv_object_code_09   IN  VARCHAR2    -- 11.�����R�[�h9
   ,iv_object_code_10   IN  VARCHAR2    -- 12.�����R�[�h10
   ,ov_errbuf           OUT VARCHAR2    --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2    --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)   --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ============================================
    -- �p�����[�^���O���[�o���ϐ��Ɋi�[
    -- ============================================
    gv_contract_number := iv_contract_number;  -- 1. �_��ԍ�
    gv_lease_company   := iv_lease_company;    -- 2. ���[�X���
    gv_object_code_01  := iv_object_code_01;   -- 3. �����R�[�h1
    gv_object_code_02  := iv_object_code_02;   -- 4. �����R�[�h2
    gv_object_code_03  := iv_object_code_03;   -- 5. �����R�[�h3
    gv_object_code_04  := iv_object_code_04;   -- 6. �����R�[�h4
    gv_object_code_05  := iv_object_code_05;   -- 7. �����R�[�h5
    gv_object_code_06  := iv_object_code_06;   -- 8. �����R�[�h6
    gv_object_code_07  := iv_object_code_07;   -- 9. �����R�[�h7
    gv_object_code_08  := iv_object_code_08;   -- 10.�����R�[�h8
    gv_object_code_09  := iv_object_code_09;   -- 11.�����R�[�h9
    gv_object_code_10  := iv_object_code_10;   -- 12.�����R�[�h10
--
    -- ============================================
    -- �p�����[�^���O�o��
    -- ============================================
    -- 1. �_��ԍ�
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�_��ԍ��F' || gv_contract_number
    );
    -- 2. ���[�X���
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '���[�X��ЁF' || gv_lease_company
    );
    -- 3. �����R�[�h1
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h1�F' || gv_object_code_01
    );
    -- 4. �����R�[�h2
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h2�F' || gv_object_code_02
    );
    -- 5. �����R�[�h3
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h3�F' || gv_object_code_03
    );
    -- 6. �����R�[�h4
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h4�F' || gv_object_code_04
    );
    -- 7. �����R�[�h5
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h5�F' || gv_object_code_05
    );
    -- 8. �����R�[�h6
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h6�F' || gv_object_code_06
    );
    -- 9. �����R�[�h7
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h7�F' || gv_object_code_07
    );
    -- 10.�����R�[�h8
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h8�F' || gv_object_code_08
    );
    -- 11.�����R�[�h9
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h9�F' || gv_object_code_09
    );
    -- 12.�����R�[�h10
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h10�F' || gv_object_code_10
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_input_param
   * Description      : ���̓p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_input_param(
    ov_errbuf           OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_input_param'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ============================================
    -- �����R�[�h�w��L���t���O�ݒ�
    -- ============================================
    -- �p�����[�^.�����R�[�h1�`10�̓��A��ł��w�肳��Ă���ꍇ�͕����R�[�h�w��L���t���O��L��ɂ���
    gv_obj_code_param := cv_obj_code_param_off;
    IF ( gv_object_code_01 IS NOT NULL ) OR
       ( gv_object_code_02 IS NOT NULL ) OR
       ( gv_object_code_03 IS NOT NULL ) OR
       ( gv_object_code_04 IS NOT NULL ) OR
       ( gv_object_code_05 IS NOT NULL ) OR
       ( gv_object_code_06 IS NOT NULL ) OR
       ( gv_object_code_07 IS NOT NULL ) OR
       ( gv_object_code_08 IS NOT NULL ) OR
       ( gv_object_code_09 IS NOT NULL ) OR
       ( gv_object_code_10 IS NOT NULL )
    THEN
       gv_obj_code_param := cv_obj_code_param_on;
    END IF;
--
    -- ============================================
    -- �K�{�`�F�b�N
    -- ============================================
    -- �_��ԍ������͂���Ă���ꍇ
    IF ( gv_contract_number IS NOT NULL ) THEN
--
      -- �����R�[�h�A���[�X��Ђ��Ƃ��ɖ����͂̏ꍇ
      IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
         ( gv_lease_company IS NULL )
      THEN
        lv_errmsg   := '�����R�[�h�����w�莞�́A�_��ԍ��ƃ��[�X��Ђ��w�肵�ĉ������B';
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    -- �_��ԍ��������͂̏ꍇ
    ELSE
--
      -- �����R�[�h�������͂̏ꍇ
      IF ( gv_obj_code_param = cv_obj_code_param_off ) THEN
        lv_errmsg   := '�����R�[�h�����w�莞�́A�_��ԍ��ƃ��[�X��Ђ��w�肵�ĉ������B';
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_input_param;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�o�͏���(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    -- ���[�X�������擾�J�[�\���i�_��ԍ��w�肠��j
    CURSOR l_object_cont_num_cur
    IS
      SELECT
          -- VARCHAR2�ɕϊ��������[�X�����S�J����
          TO_CHAR(xoh.object_header_id)                     AS  object_header_id        -- ��������ID
         ,xoh.object_code                                   AS  object_code             -- �����R�[�h
         ,xoh.lease_class                                   AS  lease_class             -- ���[�X���
         ,xoh.lease_type                                    AS  lease_type              -- ���[�X�敪
         ,TO_CHAR(xoh.re_lease_times)                       AS  re_lease_times          -- �ă��[�X��
         ,xoh.po_number                                     AS  po_number               -- �����ԍ�
         ,xoh.registration_number                           AS  registration_number     -- �o�^�ԍ�
         ,xoh.age_type                                      AS  age_type                -- �N��
         ,xoh.model                                         AS  model                   -- �@��
         ,xoh.serial_number                                 AS  serial_number           -- �@��
         ,TO_CHAR(xoh.quantity)                             AS  quantity                -- ����
         ,xoh.manufacturer_name                             AS  manufacturer_name       -- ���[�J�[��
         ,xoh.department_code                               AS  department_code         -- �Ǘ�����R�[�h
         ,xoh.owner_company                                 AS  owner_company           -- �{�Ё^�H��
         ,xoh.installation_address                          AS  installation_address    -- ���ݒu�ꏊ
         ,xoh.installation_place                            AS  installation_place      -- ���ݒu��
         ,xoh.chassis_number                                AS  chassis_number          -- �ԑ�ԍ�
         ,xoh.re_lease_flag                                 AS  re_lease_flag           -- �ă��[�X�v�t���O
         ,xoh.cancellation_type                             AS  cancellation_type       -- ���敪
         ,TO_CHAR(xoh.cancellation_date, cv_date_format)    AS  cancellation_date       -- ���r����
         ,TO_CHAR(xoh.dissolution_date , cv_date_format)    AS  dissolution_date        -- ���r���L�����Z����
         ,xoh.bond_acceptance_flag                          AS  bond_acceptance_flag    -- �؏���̃t���O
         ,TO_CHAR(xoh.bond_acceptance_date, cv_date_format) AS  bond_acceptance_date    -- �؏���̓�
         ,TO_CHAR(xoh.expiration_date, cv_date_format)      AS  expiration_date         -- ������
         ,xoh.object_status                                 AS  object_status           -- �����X�e�[�^�X
         ,xoh.active_flag                                   AS  active_flag             -- �����L���t���O
         ,TO_CHAR(xoh.info_sys_if_date, cv_date_format)     AS  info_sys_if_date        -- ���[�X�Ǘ����A�g��
         ,TO_CHAR(xoh.generation_date, cv_date_format)      AS  generation_date         -- ������
         ,xoh.customer_code                                 AS  customer_code           -- �ڋq�R�[�h
         ,TO_CHAR(xoh.created_by)                           AS  created_by              -- �쐬��
         ,TO_CHAR(xoh.creation_date, cv_date_format)        AS  creation_date           -- �쐬��
         ,TO_CHAR(xoh.last_updated_by)                      AS  last_updated_by         -- �ŏI�X�V��
         ,TO_CHAR(xoh.last_update_date, cv_date_format)     AS  last_update_date        -- �ŏI�X�V��
         ,TO_CHAR(xoh.last_update_login)                    AS  last_update_login       -- �ŏI�X�V���O�C��
         ,TO_CHAR(xoh.request_id)                           AS  request_id              -- �v��ID
         ,TO_CHAR(xoh.program_application_id)               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,TO_CHAR(xoh.program_id)                           AS  program_id              -- �R���J�����g�E�v���O����ID
         ,TO_CHAR(xoh.program_update_date, cv_date_format)  AS  program_update_date     -- �v���O�����X�V��
      FROM
          xxcff_contract_headers      xch   --  ���[�X�_��w�b�_
         ,xxcff_contract_lines        xcl   --  ���[�X�_�񖾍�
         ,xxcff_object_headers        xoh   --  ���[�X����
         ,( 
            -- �_��ԍ��A���[�X��Ђ��Ƃ̍ő�ă��[�X��
            SELECT
                xch2.contract_number      AS contract_number      -- �_��ԍ�
               ,xch2.lease_company        AS lease_company        -- ���[�X���
               ,MAX(xch2.re_lease_times)  AS re_lease_times       -- �ă��[�X��
            FROM
                xxcff_contract_headers    xch2                    -- ���[�X�_��w�b�_
            WHERE
                xch2.contract_number      = gv_contract_number    -- �_��ԍ�
            GROUP BY
                xch2.contract_number      -- �_��ԍ�
               ,xch2.lease_company        -- ���[�X���
          )
          xch2_max
      WHERE
          xch.contract_header_id      = xcl.contract_header_id    -- �_�����ID
      AND xcl.object_header_id        = xoh.object_header_id      -- ��������ID
      --
      --  ���[�X�_��w�b�_���ă��[�X�񐔂��ő�̃��R�[�h�ɍi��
      AND xch.contract_number         = xch2_max.contract_number  -- �_��ԍ�
      AND xch.lease_company           = xch2_max.lease_company    -- ���[�X���
      AND xch.re_lease_times          = xch2_max.re_lease_times   -- �ă��[�X��
      --
      --  ���̓p�����[�^�D�_��ԍ�
      AND xch.contract_number         = gv_contract_number
      -- 
      --  ���̓p�����[�^�D���[�X���
      AND (   gv_lease_company        IS NULL
          OR  xch.lease_company       = gv_lease_company
          )
      --
      --  ���̓p�����[�^�D�����R�[�h
      AND (   gv_obj_code_param       = cv_obj_code_param_off     -- �����R�[�h������
          OR  xoh.object_code         IN  ( gv_object_code_01
                                          , gv_object_code_02
                                          , gv_object_code_03
                                          , gv_object_code_04
                                          , gv_object_code_05
                                          , gv_object_code_06
                                          , gv_object_code_07
                                          , gv_object_code_08
                                          , gv_object_code_09
                                          , gv_object_code_10
                                          )
          )
      --
      ORDER BY
          xch.contract_number     -- �_��ԍ�
         ,xoh.object_code         -- �����R�[�h
    ;
--
--
    -- ���[�X�������擾�J�[�\���i�_��ԍ��w��Ȃ��������R�[�h�w�肠��j
    CURSOR l_object_no_cont_num_cur
    IS
      SELECT
          -- VARCHAR2�ɕϊ��������[�X�����S�J����
          TO_CHAR(xoh.object_header_id)                     AS  object_header_id        -- ��������ID
         ,xoh.object_code                                   AS  object_code             -- �����R�[�h
         ,xoh.lease_class                                   AS  lease_class             -- ���[�X���
         ,xoh.lease_type                                    AS  lease_type              -- ���[�X�敪
         ,TO_CHAR(xoh.re_lease_times)                       AS  re_lease_times          -- �ă��[�X��
         ,xoh.po_number                                     AS  po_number               -- �����ԍ�
         ,xoh.registration_number                           AS  registration_number     -- �o�^�ԍ�
         ,xoh.age_type                                      AS  age_type                -- �N��
         ,xoh.model                                         AS  model                   -- �@��
         ,xoh.serial_number                                 AS  serial_number           -- �@��
         ,TO_CHAR(xoh.quantity)                             AS  quantity                -- ����
         ,xoh.manufacturer_name                             AS  manufacturer_name       -- ���[�J�[��
         ,xoh.department_code                               AS  department_code         -- �Ǘ�����R�[�h
         ,xoh.owner_company                                 AS  owner_company           -- �{�Ё^�H��
         ,xoh.installation_address                          AS  installation_address    -- ���ݒu�ꏊ
         ,xoh.installation_place                            AS  installation_place      -- ���ݒu��
         ,xoh.chassis_number                                AS  chassis_number          -- �ԑ�ԍ�
         ,xoh.re_lease_flag                                 AS  re_lease_flag           -- �ă��[�X�v�t���O
         ,xoh.cancellation_type                             AS  cancellation_type       -- ���敪
         ,TO_CHAR(xoh.cancellation_date, cv_date_format)    AS  cancellation_date       -- ���r����
         ,TO_CHAR(xoh.dissolution_date , cv_date_format)    AS  dissolution_date        -- ���r���L�����Z����
         ,xoh.bond_acceptance_flag                          AS  bond_acceptance_flag    -- �؏���̃t���O
         ,TO_CHAR(xoh.bond_acceptance_date, cv_date_format) AS  bond_acceptance_date    -- �؏���̓�
         ,TO_CHAR(xoh.expiration_date, cv_date_format)      AS  expiration_date         -- ������
         ,xoh.object_status                                 AS  object_status           -- �����X�e�[�^�X
         ,xoh.active_flag                                   AS  active_flag             -- �����L���t���O
         ,TO_CHAR(xoh.info_sys_if_date, cv_date_format)     AS  info_sys_if_date        -- ���[�X�Ǘ����A�g��
         ,TO_CHAR(xoh.generation_date, cv_date_format)      AS  generation_date         -- ������
         ,xoh.customer_code                                 AS  customer_code           -- �ڋq�R�[�h
         ,TO_CHAR(xoh.created_by)                           AS  created_by              -- �쐬��
         ,TO_CHAR(xoh.creation_date, cv_date_format)        AS  creation_date           -- �쐬��
         ,TO_CHAR(xoh.last_updated_by)                      AS  last_updated_by         -- �ŏI�X�V��
         ,TO_CHAR(xoh.last_update_date, cv_date_format)     AS  last_update_date        -- �ŏI�X�V��
         ,TO_CHAR(xoh.last_update_login)                    AS  last_update_login       -- �ŏI�X�V���O�C��
         ,TO_CHAR(xoh.request_id)                           AS  request_id              -- �v��ID
         ,TO_CHAR(xoh.program_application_id)               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,TO_CHAR(xoh.program_id)                           AS  program_id              -- �R���J�����g�E�v���O����ID
         ,TO_CHAR(xoh.program_update_date, cv_date_format)  AS  program_update_date     -- �v���O�����X�V��
      FROM
          xxcff_contract_headers      xch   --  ���[�X�_��w�b�_
         ,xxcff_contract_lines        xcl   --  ���[�X�_�񖾍�
         ,xxcff_object_headers        xoh   --  ���[�X����
      WHERE
          xch.contract_header_id      = xcl.contract_header_id    -- �_�����ID
      AND xcl.object_header_id        = xoh.object_header_id      -- ��������ID
      --
      --  �ă��[�X�񐔁i���o�Ώۂ��ŐV�_��݂̂Ƃ���j
      AND xch.re_lease_times          = xoh.re_lease_times        -- �ă��[�X��
      -- 
      --  ���̓p�����[�^�D���[�X���
      AND (   gv_lease_company        IS NULL
          OR  xch.lease_company       = gv_lease_company
          )
      --
      --  ���̓p�����[�^�D�����R�[�h�i�K�������ꂩ�Ɏw�肠��j
      AND xoh.object_code             IN  ( gv_object_code_01
                                          , gv_object_code_02
                                          , gv_object_code_03
                                          , gv_object_code_04
                                          , gv_object_code_05
                                          , gv_object_code_06
                                          , gv_object_code_07
                                          , gv_object_code_08
                                          , gv_object_code_09
                                          , gv_object_code_10
                                          )
      --
      ORDER BY
          xch.contract_number     -- �_��ԍ�
         ,xoh.object_code         -- �����R�[�h
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���EPL/SQL�\ ***
--
    -- ���[�X�������
    TYPE l_object_ttype IS TABLE OF l_object_cont_num_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_object_tab        l_object_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ���[�X�������擾
    -- ===============================================
    -- �_��ԍ������͂���Ă���ꍇ
    IF ( gv_contract_number IS NOT NULL ) THEN
      OPEN  l_object_cont_num_cur;
      FETCH l_object_cont_num_cur BULK COLLECT INTO l_object_tab;
      CLOSE l_object_cont_num_cur;
--
    -- �_��ԍ��������͂̏ꍇ�i�����R�[�h�͕K���w�肳��Ă���j
    ELSE
      OPEN  l_object_no_cont_num_cur;
      FETCH l_object_no_cont_num_cur BULK COLLECT INTO l_object_tab;
      CLOSE l_object_no_cont_num_cur;
    END IF;
--
    -- �Ώی����i�[
    gn_target_cnt := l_object_tab.COUNT;
--
    -- ===============================================
    -- CSV�o�͏���
    -- ===============================================
    -- ���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_enclosed || '���[�X����' || cv_enclosed
    );
--
    -- ���ږ�
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || '��������ID'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�����R�[�h'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X���'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�敪'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�ă��[�X��'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�����ԍ�'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '�o�^�ԍ�'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '�N��'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '�@��'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '�@��'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '����'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�J�[��'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�Ǘ�����R�[�h'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�{�Ё^�H��'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '���ݒu�ꏊ'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '���ݒu��'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '�ԑ�ԍ�'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '�ă��[�X�v�t���O'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '���敪'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '���r����'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '���r���L�����Z����'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '�؏���̃t���O'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�؏���̓�'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '������'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '�����X�e�[�^�X'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�����L���t���O'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�Ǘ����A�g��'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '������'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '�ڋq�R�[�h'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V���O�C��'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '�v��ID'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�E�v���O�����E�A�v���P�[�V����ID' || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�E�v���O����ID'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�v���O�����X�V��'                             || cv_enclosed
    );
--
    -- ������񃋁[�v
    <<object_loop>>
    FOR i IN 1 .. l_object_tab.COUNT LOOP
--
      -- ���ڒl
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>          cv_enclosed || l_object_tab( i ).object_header_id       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).object_code            || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).lease_class            || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).lease_type             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).re_lease_times         || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).po_number              || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).registration_number    || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).age_type               || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).model                  || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).serial_number          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).quantity               || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).manufacturer_name      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).department_code        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).owner_company          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).installation_address   || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).installation_place     || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).chassis_number         || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).re_lease_flag          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).cancellation_type      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).cancellation_date      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).dissolution_date       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).bond_acceptance_flag   || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).bond_acceptance_date   || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).expiration_date        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).object_status          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).active_flag            || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).info_sys_if_date       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).generation_date        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).customer_code          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).created_by             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).creation_date          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).last_updated_by        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).last_update_date       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).last_update_login      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).request_id             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).program_application_id || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).program_id             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).program_update_date    || cv_enclosed
      );
--
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP object_loop;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_contract_number  IN  VARCHAR2    --  1.�_��ԍ�
   ,iv_lease_company    IN  VARCHAR2    --  2.���[�X���
   ,iv_object_code_01   IN  VARCHAR2    --  3.�����R�[�h1
   ,iv_object_code_02   IN  VARCHAR2    --  4.�����R�[�h2
   ,iv_object_code_03   IN  VARCHAR2    --  5.�����R�[�h3
   ,iv_object_code_04   IN  VARCHAR2    --  6.�����R�[�h4
   ,iv_object_code_05   IN  VARCHAR2    --  7.�����R�[�h5
   ,iv_object_code_06   IN  VARCHAR2    --  8.�����R�[�h6
   ,iv_object_code_07   IN  VARCHAR2    --  9.�����R�[�h7
   ,iv_object_code_08   IN  VARCHAR2    -- 10.�����R�[�h8
   ,iv_object_code_09   IN  VARCHAR2    -- 11.�����R�[�h9
   ,iv_object_code_10   IN  VARCHAR2    -- 12.�����R�[�h10
   ,ov_errbuf           OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt   := 0;   -- �Ώی���
    gn_normal_cnt   := 0;   -- ���팏��
    gn_error_cnt    := 0;   -- �G���[����
    gn_warn_cnt     := 0;   -- �X�L�b�v����
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      iv_contract_number  =>  iv_contract_number  --  1.�_��ԍ�
     ,iv_lease_company    =>  iv_lease_company    --  2.���[�X���
     ,iv_object_code_01   =>  iv_object_code_01   --  3.�����R�[�h1
     ,iv_object_code_02   =>  iv_object_code_02   --  4.�����R�[�h2
     ,iv_object_code_03   =>  iv_object_code_03   --  5.�����R�[�h3
     ,iv_object_code_04   =>  iv_object_code_04   --  6.�����R�[�h4
     ,iv_object_code_05   =>  iv_object_code_05   --  7.�����R�[�h5
     ,iv_object_code_06   =>  iv_object_code_06   --  8.�����R�[�h6
     ,iv_object_code_07   =>  iv_object_code_07   --  9.�����R�[�h7
     ,iv_object_code_08   =>  iv_object_code_08   -- 10.�����R�[�h8
     ,iv_object_code_09   =>  iv_object_code_09   -- 11.�����R�[�h9
     ,iv_object_code_10   =>  iv_object_code_10   -- 12.�����R�[�h10
     ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���̓p�����[�^�`�F�b�N����(A-2)
    -- ===============================================
    chk_input_param(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- CSV�o�͏���(A-3)
    -- ===============================================
    output_csv(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی����O���̏ꍇ�A�I���X�e�[�^�X���u�x���v�ɂ���
    IF (gn_target_cnt = 0) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '�Ώۃf�[�^�����݂��܂���B'
      );
      ov_retcode := cv_status_warn;
    END IF;
--
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf              OUT VARCHAR2,       --     �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,       --     ���^�[���E�R�[�h    --# �Œ� #
    iv_contract_number  IN  VARCHAR2,       --  1. �_��ԍ�
    iv_lease_company    IN  VARCHAR2,       --  2. ���[�X���
    iv_object_code_01   IN  VARCHAR2,       --  3. �����R�[�h1
    iv_object_code_02   IN  VARCHAR2,       --  4. �����R�[�h2
    iv_object_code_03   IN  VARCHAR2,       --  5. �����R�[�h3
    iv_object_code_04   IN  VARCHAR2,       --  6. �����R�[�h4
    iv_object_code_05   IN  VARCHAR2,       --  7. �����R�[�h5
    iv_object_code_06   IN  VARCHAR2,       --  8. �����R�[�h6
    iv_object_code_07   IN  VARCHAR2,       --  9. �����R�[�h7
    iv_object_code_08   IN  VARCHAR2,       --  10.�����R�[�h8
    iv_object_code_09   IN  VARCHAR2,       --  11.�����R�[�h9
    iv_object_code_10   IN  VARCHAR2        --  12.�����R�[�h10
  )
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
      iv_contract_number  =>  iv_contract_number  -- 1. �_��ԍ�
     ,iv_lease_company    =>  iv_lease_company    -- 2. ���[�X���
     ,iv_object_code_01   =>  iv_object_code_01   -- 3. �����R�[�h1
     ,iv_object_code_02   =>  iv_object_code_02   -- 4. �����R�[�h2
     ,iv_object_code_03   =>  iv_object_code_03   -- 5. �����R�[�h3
     ,iv_object_code_04   =>  iv_object_code_04   -- 6. �����R�[�h4
     ,iv_object_code_05   =>  iv_object_code_05   -- 7. �����R�[�h5
     ,iv_object_code_06   =>  iv_object_code_06   -- 8. �����R�[�h6
     ,iv_object_code_07   =>  iv_object_code_07   -- 9. �����R�[�h7
     ,iv_object_code_08   =>  iv_object_code_08   -- 10.�����R�[�h8
     ,iv_object_code_09   =>  iv_object_code_09   -- 11.�����R�[�h9
     ,iv_object_code_10   =>  iv_object_code_10   -- 12.�����R�[�h10
     ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- �I������(A-4)
    -- ===============================================
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �����ݒ�
      gn_normal_cnt := 0;   -- ���������N���A
      gn_error_cnt  := 1;   -- �G���[�����ݒ�
    END IF;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCCP008A02C;
/
