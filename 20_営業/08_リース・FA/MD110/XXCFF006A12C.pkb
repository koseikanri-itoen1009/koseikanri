CREATE OR REPLACE PACKAGE BODY XXCFF006A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF006A12C(body)
 * Description      : ���[�X�_����A�g
 * MD.050           : ���[�X�_����A�g MD050_CFF_006_A12
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-2�D���̓p�����[�^�l���O�o�͏���
 *  get_profile_value      A-3�D�v���t�@�C���擾
 *  chk_object_code        A-5�D�p�����[�^�͈͎w��`�F�b�N����
 *  get_lease_data         A-6. ���[�X�_����̎擾
 *  put_lease_data         A-7�D���[�X�_����f�[�^CSV�쐬����
 *  put_lease_data         A-8�D���[�X�_�񖾍׍X�V����
 *  submain                ���C�������v���V�[�W��
 *  main                   ���[�X�_����CSV�t�@�C���쐬
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/22    1.0   SCS����          main�V�K�쐬
 *  2009/03/04    1.1   SCS����          [��QCFF_069] ���_�񃊁[�X��(�Ŕ�)�s���o�͕s��Ή�
 *  2009/05/21    1.2   SCS�E��          [��QT1_1054] �s�v�ȃ��[�X�_������쐬���Ă��܂��B
 *  2009/05/28    1.3   SCS�E��          [��QT1_1224] �A�g�@�\���G���[�̍ۂ�CSV�t�@�C�����폜�����B
 *  2009/07/03    1.4   SCS����          [��Q00000136]�Ώی�����0���̏ꍇ�ACSV�捞���ɃG���[�ƂȂ�
 *  2009/08/28    1.5   SCS�n��          [�����e�X�g��Q0001059(PT�Ή�)]
 *  2016/01/26    1.6   SCSK�R��         E_�{�ғ�_13456�Ή�
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N(�r�W�[)�G���[
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFF006A12C';            -- �p�b�P�[�W��
  cv_appl_short_name    CONSTANT VARCHAR2(100) := 'XXCFF';                   -- �A�v���P�[�V�����Z�k��
  cv_log                CONSTANT VARCHAR2(100) := 'LOG';                     -- �R���J�����g���O�o�͐�
  cv_which              CONSTANT VARCHAR2(100) := 'OUTPUT';                  -- �R���J�����g���O�o�͐�
  -- ���b�Z�[�W�ԍ�
  cv_msg_xxcff00003     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00003';         --FROM �� TO �ƂȂ�悤�Ɏw�肵�Ă��������B
  cv_msg_xxcff00007     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007';         --���b�N�G���[
  cv_msg_xxcff00062     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00062';         --�Ώۃf�[�^����
  cv_msg_xxcff00020     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020';         --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_xxcff00168     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00168';         --�t�@�C���� : FILE_NAME
  cv_msg_xxcff00169     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00169';         --�t�@�C�������i�[�ꏊ�������ł�
  cv_msg_xxcff00170     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00170';         --�t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
  cv_msg_xxcff00171     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00171';         --�t�@�C���ɏ����݂ł��Ȃ����b�Z�[
  cv_msg_xxcff00172     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00172';         --�t�@�C�������݂��Ă��郁�b�Z�[�W
  cv_msg_xxcff50030     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50030';         --���[�X�_�񖾍׃e�[�u��
  --�v���t�@�C��
  cv_file_name_enter    CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_NAME_ENTER';   --XXCFF: ���[�X�_����t�@�C������
  cv_file_dir_enter     CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_DIR_ENTER';    --XXCFF: ���[�X�_����t�@�C���i�[�p�X
-- E_�{�ғ�_13456 2016/01/26 DEL START
--  cv_update_charge_code CONSTANT VARCHAR2(35) := 'XXCFF1_UPDATE_CHARGE_CODE';--XXCFF: �X�V�S���҃R�[�h
--  cv_update_post_code   CONSTANT VARCHAR2(35) := 'XXCFF1_UPDATE_POST_CODE';  --XXCFF: �S�������R�[�h
--  cv_update_program_id  CONSTANT VARCHAR2(35) := 'XXCFF1_UPDATE_PROGRAM_ID'; --XXCFF: �X�V�v���O����ID
-- E_�{�ғ�_13456 2016/01/26 DEL END
  -- �g�[�N��
  cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_prof           CONSTANT VARCHAR2(15) := 'PROF_NAME';                -- �v���t�@�C����
  cv_tkn_file           CONSTANT VARCHAR2(15) := 'FILE_NAME';                -- �t�@�C����
  cv_token_from         CONSTANT VARCHAR2(15) := 'FROM';
  cv_token_to           CONSTANT VARCHAR2(15) := 'TO';  
  cv_object_code_f      CONSTANT VARCHAR2(37) := xxccp_common_pkg.get_msg(cv_appl_short_name,'APP-XXCFF1-50139');--�����R�[�hFrom;
  cv_object_code_t      CONSTANT VARCHAR2(37) := xxccp_common_pkg.get_msg(cv_appl_short_name,'APP-XXCFF1-50140');--�����R�[�hTo;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_name_enter    VARCHAR2(100) ;   --XXCFF: ���[�X�_����t�@�C������
  gn_file_dir_enter     VARCHAR2(500) ;   --XXCFF: ���[�X�_����t�@�C���i�[�p�X
-- E_�{�ғ�_13456 2016/01/26 DEL START
--  gn_update_charge_code VARCHAR2(30)  ;   --XXCFF: ���[�X�X�V�S���҃R�[�h
--  gn_update_post_code   VARCHAR2(30)  ;   --XXCFF: ���[�X�S�������R�[�h
--  gn_update_program_id  VARCHAR2(30)  ;   --XXCFF: ���[�X�X�V�v���O����ID
-- E_�{�ғ�_13456 2016/01/26 DEL END
  gd_sysdateb           DATE;             -- �V�X�e�����t
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
    CURSOR get_lease_cur(i_object_code_from IN VARCHAR2,i_object_code_to IN VARCHAR2)
    IS
    SELECT
-- 0001059 2009/08/31 ADD START --
             /*+
               LEADING(XOH XCL1 XCH1 XCL0)
               INDEX(XOH  XXCFF_OBJECT_HEADERS_N03)
               INDEX(XCL1 XXCFF_CONTRACT_LINES_N03)
               INDEX(XCH1 XXCFF_CONTRACT_HEADERS_PK)
             */
-- 0001059 2009/08/31 ADD END --
             REPLACE(xoh.object_code,'-','')    AS object_code       --�����R�[�h
            ,xch1.lease_company                 AS lease_company     --���[�X�_��(��)���[�X���
            ,xch1.lease_start_date              AS lease_start_date  --���[�X�_��(��)���[�X�J�n��
            ,DECODE(xch1.lease_type,2,xcl1.gross_charge,1,xcl1.second_charge ) AS charge
            ,xcl0.contract_number               AS contract_number0  --�_��ԍ�(��)
            ,xcl0.contract_line_num             AS contract_line_num0--�_��}��(��)
-- E_�{�ғ�_13456 2016/01/26 DEL START
--            ,xch1.contract_date                 AS contract_date     --�_���
-- E_�{�ғ�_13456 2016/01/26 DEL END
            ,xch1.contract_number               AS contract_number1  --�_��ԍ�(��)
            ,xcl1.contract_line_num             AS contract_line_num1--�_��}��(��)
-- E_�{�ғ�_13456 2016/01/26 DEL START
--            ,xcl1.vd_if_date                    AS vd_if_date        --���[�X�_����A�g����
-- E_�{�ғ�_13456 2016/01/26 DEL END
            ,xcl1.contract_line_id              AS contract_line_id  --�_�񖾍ד���id
-- E_�{�ғ�_13456 2016/01/26 ADD START
            ,xch1.lease_type                    AS lease_type            --���[�X�敪
            ,xcl1.estimated_cash_price          AS estimated_cash_price  --���ό����w�����z
            ,xcl0.lease_start_date              AS lease_start_date0     --���[�X�_��(��)���[�X�J�n��
-- E_�{�ғ�_13456 2016/01/26 ADD END
    FROM     xxcff_object_headers   xoh                              --���[�X����
            ,xxcff_contract_headers xch1                             --���[�X�_�񃊁[�X�_��(��)
            ,xxcff_contract_lines   xcl1                             --���[�X�_�񖾍׃��[�X�_��(��)
-- T1_1054 2009/05/21 ADD START --
            ,csi_item_instances     cii                              --�C���X�g�[���x�[�X�}�X�^
-- T1_1054 2009/05/21 ADD END   --
            ,(
             SELECT
-- 0001059 2009/08/31 ADD START --
                     /*+
                       LEADING(XCH)
                       INDEX(XCH XXCFF_CONTRACT_HEADERS_N06)
                       INDEX(XCL XXCFF_CONTRACT_LINES_U01)
                     */
-- 0001059 2009/08/31 ADD END --
                     xch.contract_header_id AS contract_header_id
                    ,xcl.object_header_id   AS object_header_id
                    ,xch.contract_number    AS contract_number
                    ,xcl.contract_line_num  AS contract_line_num
-- E_�{�ғ�_13456 2016/01/26 ADD START
                    ,xch.lease_start_date   AS lease_start_date
-- E_�{�ғ�_13456 2016/01/26 ADD END
             FROM   xxcff_contract_headers  xch
                    ,xxcff_contract_lines   xcl                             --���[�X�_�񖾍׃��[�X�_��(��)
             WHERE  xch.contract_header_id = xcl.contract_header_id
-- 0001059 2009/08/31 ADD START --
             AND    xch.lease_type         =  1
-- 0001059 2009/08/31 ADD END --
             AND    xch.re_lease_times     =  0
             ) xcl0                                                  --���[�X�_�񃊁[�X�_��(��)
    WHERE    xch1.contract_header_id = xcl1.contract_header_id
    AND      xoh.object_header_id    = xcl0.object_header_id(+)
    AND      xoh.object_header_id    = xcl1.object_header_id
    AND      xoh.re_lease_times      = xch1.re_lease_times
    AND      xoh.lease_class      IN (SELECT lease_class_code
                                      FROM   xxcff_lease_class_v
                                      WHERE  vdsh_flag = 'Y')
    AND      xcl1.contract_status IN ('202','203')
    AND      (xcl1.last_update_date > xcl1.vd_if_date OR xcl1.vd_if_date IS NULL)
    AND      (i_object_code_from IS NULL OR xoh.object_code >= i_object_code_from)
    AND      (i_object_code_to   IS NULL OR xoh.object_code <= i_object_code_to  )
-- T1_1054 2009/05/21 ADD START --
    AND      xoh.object_code     =  cii.external_reference
    AND      (cii.attribute5  IS NULL OR cii.attribute5  = 'N')
-- T1_1054 2009/05/21 ADD END   --
    ORDER BY  xoh.object_code
    ;
    TYPE g_lease_ttype IS TABLE OF get_lease_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_lease_data      g_lease_ttype;
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);       -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    --
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    xxcff_common1_pkg.put_log_param
    (
     iv_which    => cv_which     -- �o�͋敪
    ,ov_retcode  => lv_retcode   --���^�[���R�[�h
    ,ov_errbuf   => lv_errbuf    --�G���[���b�Z�[�W
    ,ov_errmsg   => lv_errmsg    --���[�U�[�E�G���[���b�Z�[�W
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;
    xxcff_common1_pkg.put_log_param
    (
     iv_which    => cv_log       -- �o�͋敪
    ,ov_retcode  => lv_retcode   --���^�[���R�[�h
    ,ov_errbuf   => lv_errbuf    --�G���[���b�Z�[�W
    ,ov_errmsg   => lv_errmsg    --���[�U�[�E�G���[���b�Z�[�W
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_profile_value
   * Description      : A-3. �v���t�@�C���擾����
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    --
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- =====================================================
    -- �v���t�@�C������ XXCFF: ���[�X�_����f�[�^�t�@�C�����擾
    -- =====================================================
    gn_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    -- �擾�G���[��
    IF (gn_file_name_enter IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- �v���t�@�C���擾�G���[
      ,cv_tkn_prof         -- �g�[�N��'PROF_NAME'
      ,cv_file_name_enter  -- �t�@�C����
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================================
    -- �v���t�@�C������ XXCFF: ���[�X�_����f�[�^�t�@�C���i�[�p�X���擾
    -- =====================================================
    gn_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
    -- �擾�G���[��
    IF (gn_file_dir_enter IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- �v���t�@�C���擾�G���[
      ,cv_tkn_prof         -- �g�[�N��'PROF_NAME'
      ,cv_file_dir_enter   -- �p�X��
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- E_�{�ғ�_13456 2016/01/26 DEL START
--    -- =====================================================
--    -- �v���t�@�C������ XXCFF: �X�V�S���҃R�[�h�擾
--    -- =====================================================
--    gn_update_charge_code := FND_PROFILE.VALUE(cv_update_charge_code);
--    -- �擾�G���[��
--    IF (gn_update_charge_code IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
--      (
--       cv_appl_short_name    -- 'XXCFF'
--      ,cv_msg_xxcff00020     -- �v���t�@�C���擾�G���[
--      ,cv_tkn_prof           -- �g�[�N��'PROF_NAME'
--      ,cv_update_charge_code -- �X�V�S���҃R�[�h
--      )
--      ,1
--      ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    --
--    -- =====================================================
--    -- �v���t�@�C������ XXCFF: �S�������R�[�h�擾
--    -- =====================================================
--    gn_update_post_code := FND_PROFILE.VALUE(cv_update_post_code);
--    -- �擾�G���[��
--    IF (gn_update_post_code IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
--      (
--       cv_appl_short_name  -- 'XXCFF'
--      ,cv_msg_xxcff00020   -- �v���t�@�C���擾�G���[
--      ,cv_tkn_prof         -- �g�[�N��'PROF_NAME'
--      ,cv_update_post_code -- �S�������R�[�h
--      )
--      ,1
--      ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    --
--    -- =====================================================
--    -- �v���t�@�C������ XXCFF: �X�V�v���O����ID�擾
--    -- =====================================================
--    gn_update_program_id := FND_PROFILE.VALUE(cv_update_program_id);
--    -- �擾�G���[��
--    IF (gn_update_program_id IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
--      (
--       cv_appl_short_name   -- 'XXCFF'
--      ,cv_msg_xxcff00020    -- �v���t�@�C���擾�G���[
--      ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
--      ,cv_update_program_id -- �X�V�v���O����ID
--      )
--      ,1
--      ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- E_�{�ғ�_13456 2016/01/26 DEL END
    --
  EXCEPTION
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
  END get_profile_value;
  /**********************************************************************************
   * Procedure Name   : chk_object_code
   * Description      : A-5�D�p�����[�^�͈͎w��`�F�b�N���� 
   ***********************************************************************************/
  PROCEDURE chk_object_code(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2,     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_object_code_from     IN  VARCHAR2,     -- 1.�����R�[�h(FROM)
    iv_object_code_to       IN  VARCHAR2      -- 2.�����R�[�h(TO)
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object_code'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    --
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    IF   iv_object_code_from IS NOT NULL
    AND  iv_object_code_to   IS NOT NULL THEN
      IF iv_object_code_from > iv_object_code_to THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
        (
        cv_appl_short_name,        -- 'XXCFF'
        cv_msg_xxcff00003,         -- �t�]�G���[
        cv_token_from,             -- �g�[�N��'FROM'
        cv_object_code_f,          -- �����R�[�hFrom
        cv_token_to,               -- �g�[�N��'TO'
        cv_object_code_t           -- �����R�[�hTo
        )
        ,1
        ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    --
  EXCEPTION
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
  END chk_object_code;
  /**********************************************************************************
   * Procedure Name   : get_lease_data
   * Description      : A-6. ���[�X�_����̎擾
   ***********************************************************************************/
  PROCEDURE get_lease_data(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2,     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_object_code_from     IN  VARCHAR2,     -- 1.�����R�[�h(FROM)
    iv_object_code_to       IN  VARCHAR2      -- 2.�����R�[�h(TO)
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    --
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    OPEN get_lease_cur(iv_object_code_from,iv_object_code_to);
    FETCH get_lease_cur BULK COLLECT INTO gt_lease_data;
    gn_target_cnt := gt_lease_data.COUNT;
    CLOSE get_lease_cur;
    --
  EXCEPTION
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
  END get_lease_data;
  /**********************************************************************************
   * Procedure Name   : put_lease_data
   * Description      : A-7�D���[�X�_����f�[�^CSV�쐬����
   ***********************************************************************************/
  PROCEDURE put_lease_data(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'put_lease_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf           VARCHAR2(5000);                   -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);                      -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_open_mode_w      CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';     -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';     -- �P��͂ݕ���
    cv_z                CONSTANT VARCHAR2(2)  := '00';    -- �Œ�l
-- E_�{�ғ�_13456 2016/01/26 ADD START
    cv_minus            CONSTANT VARCHAR2(1)  := '-';     -- �Œ�l
    cv_1                CONSTANT VARCHAR2(1)  := '1';     -- �Œ�l
    cv_20               CONSTANT VARCHAR2(2)  := '20';    -- �Œ�l
-- E_�{�ғ�_13456 2016/01/26 ADD END
    cv_null             CONSTANT VARCHAR2(2)  := NULL;    -- �Œ�l
    -- *** ���[�J���ϐ� ***
    ln_target_cnt       NUMBER := 0;                      -- �Ώی���
    ln_loop_cnt         NUMBER;                           -- ���[�v�J�E���^
    in_contract_line_id NUMBER;
    in_charge           NUMBER;
-- E_�{�ғ�_13456 2016/01/26 ADD START
    ln_cash_price       NUMBER;                           -- �{�̉��i
    lv_lease_no         VARCHAR2(20);                     -- ���[�XNo
-- E_�{�ғ�_13456 2016/01/26 MOD END
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;              -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;                 -- �o�͂P�s��������ϐ�
    lb_fexists          BOOLEAN;                          -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                           -- �t�@�C���̒���
    ln_block_size       NUMBER;                           -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
    -- *** ���[�J���E�J�[�\�� ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    --
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
    (
    gn_file_dir_enter,
    gn_file_name_enter,
    cv_open_mode_w
    );
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    IF gn_target_cnt <> 0 THEN
        <<out_loop>>
        FOR ln_loop_cnt IN gt_lease_data.FIRST..gt_lease_data.LAST LOOP
          in_charge := NULL;
          IF         LENGTH(gt_lease_data(ln_loop_cnt).charge) <= 7 THEN
            in_charge := gt_lease_data(ln_loop_cnt).charge;
          ELSE
            in_charge := SUBSTRB(gt_lease_data(ln_loop_cnt).charge ,-7 );
          END IF;
-- E_�{�ғ�_13456 2016/01/26 ADD START
          -- �{�̉��i
          ln_cash_price := NVL( gt_lease_data(ln_loop_cnt).estimated_cash_price , 0 );
          IF ( LENGTH(ln_cash_price) > 7 ) THEN
            ln_cash_price := SUBSTRB( ln_cash_price , -7 );
          END IF;
          -- ���[�XNo
          lv_lease_no := NULL;
          IF ( gt_lease_data(ln_loop_cnt).lease_type = cv_1 ) THEN
            -- ���_��̏ꍇ
            lv_lease_no := gt_lease_data(ln_loop_cnt).contract_number0 || cv_minus || gt_lease_data(ln_loop_cnt).contract_line_num0;
          ELSE
            -- �ă��[�X�̏ꍇ
            lv_lease_no := gt_lease_data(ln_loop_cnt).contract_number1 || cv_minus || gt_lease_data(ln_loop_cnt).contract_line_num1;
          END IF;
-- E_�{�ғ�_13456 2016/01/26 ADD END
-- E_�{�ғ�_13456 2016/01/26 MOD START
--          --
--          -- �o�͕�����쐬
--          lv_csv_text := 
--             cv_enclosed ||  gt_lease_data(ln_loop_cnt).object_code       || cv_enclosed || cv_delimiter  -- �����R�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �@��
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �@��
--          || cv_null                                                                     || cv_delimiter  -- �@��敪
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ���[�J
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �N��
--          || cv_null                                                                     || cv_delimiter  -- �Z����
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ����@�P
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ����@�Q
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ����@�R
--          || cv_null                                                                     || cv_delimiter  -- ����ݒ��
--          || cv_null                                                                     || cv_delimiter  -- �J�E���^�[No
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �n��R�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ���_�i����j�R�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ��Ɖ�ЃR�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ���Ə��R�[�h
--          || cv_null                                                                     || cv_delimiter  -- �ŏI��Ɠ`�[No
--          || cv_null                                                                     || cv_delimiter  -- �ŏI��Ƌ敪
--          || cv_null                                                                     || cv_delimiter  -- �ŏI��Ɛi��
--          || cv_null                                                                     || cv_delimiter  -- �ŏI��Ɗ����\���
--          || cv_null                                                                     || cv_delimiter  -- �ŏI��Ɗ�����
--          || cv_null                                                                     || cv_delimiter  -- �ŏI�������e
--          || cv_null                                                                     || cv_delimiter  -- �ŏI�ݒu�`�[No
--          || cv_null                                                                     || cv_delimiter  -- �ŏI�ݒu�敪
--          || cv_null                                                                     || cv_delimiter  -- �ŏI�ݒu�\���
--          || cv_null                                                                     || cv_delimiter  -- �ŏI�ݒu�i��
--          || cv_null                                                                     || cv_delimiter  -- �@����1
--          || cv_null                                                                     || cv_delimiter  -- �@����2
--          || cv_null                                                                     || cv_delimiter  -- �@����3
--          || cv_null                                                                     || cv_delimiter  -- ���ɓ�
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ���g��ЃR�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- ���g���Ə��R�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu�於
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��S���Җ�
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��TEL1
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��TEL2
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��TEL3
--          || cv_null                                                                     || cv_delimiter  -- �ݒu��X�֔ԍ�
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��Z��1
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��Z��2
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��Z��3
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��Z��4
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �ݒu��Z��5
--          || cv_null                                                                     || cv_delimiter  -- �p�����ٓ�
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �]���p���Ǝ�
--          || cv_null                                                                     || cv_delimiter  -- �]���p���`�[No
--          || cv_enclosed || cv_z||gt_lease_data(ln_loop_cnt).lease_company||cv_enclosed  || cv_delimiter  -- ���L��
--          ||        TO_CHAR(gt_lease_data(ln_loop_cnt).lease_start_date,'YYYYMMDD')      || cv_delimiter  -- ���[�X�J�n��
--          ||                in_charge                                                    || cv_delimiter  -- ���[�X��
--          || cv_enclosed || gt_lease_data(ln_loop_cnt).contract_number0   || cv_enclosed || cv_delimiter  -- ���_��ԍ�
--          ||                gt_lease_data(ln_loop_cnt).contract_line_num0 ||                cv_delimiter  -- ���_��ԍ��}��
--          ||        TO_CHAR(gt_lease_data(ln_loop_cnt).contract_date   ,'YYYYMMDD')      || cv_delimiter  -- ���_���
--          || cv_enclosed || gt_lease_data(ln_loop_cnt).contract_number1   || cv_enclosed || cv_delimiter  -- ���_��ԍ�
--          ||                gt_lease_data(ln_loop_cnt).contract_line_num1                || cv_delimiter  -- ���_��ԍ��}��
--          || cv_null                                                                     || cv_delimiter  -- �]���p�Ə󋵃t���O
--          || cv_null                                                                     || cv_delimiter  -- �]�������敪
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �폜�t���O
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �쐬�S���҃R�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �쐬�����R�[�h
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- �쐬�v���O����ID
--          || cv_enclosed || gn_update_charge_code                         || cv_enclosed || cv_delimiter  -- �X�V�S���҃R�[�h
--          || cv_enclosed || gn_update_post_code                           || cv_enclosed || cv_delimiter  -- �X�V�����R�[�h
--          || cv_enclosed || gn_update_program_id                          || cv_enclosed || cv_delimiter  -- �X�V�v���O����ID
--          || cv_null                                                                     || cv_delimiter  -- �쐬�������b
--          || cv_null                                                                                      -- �X�V�������b
--          ;
          --
          -- �o�͕�����쐬
          lv_csv_text :=
             cv_enclosed || gt_lease_data(ln_loop_cnt).object_code                         || cv_enclosed || cv_delimiter  -- ���̋@CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �@��
          || cv_enclosed || gt_lease_data(ln_loop_cnt).lease_company                       || cv_enclosed || cv_delimiter  -- ذ���Ћ敪
          || cv_enclosed || cv_z                                                           || cv_enclosed || cv_delimiter  -- ذ��`�ԋ敪
          || cv_enclosed || cv_20                                                          || cv_enclosed || cv_delimiter  -- ذ������敪
          || cv_enclosed || TO_CHAR(gt_lease_data(ln_loop_cnt).lease_start_date0,'YYYYMM') || cv_enclosed || cv_delimiter  -- ذ��J�n��
          || cv_enclosed || lv_lease_no                                                    || cv_enclosed || cv_delimiter  -- ذ�NO
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ��t�ԍ�
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ��t�ԍ��}��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ���CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �x�XCD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �c�Ə�CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ��Ǝ�CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ���Ǝ�CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �����O�敪
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- Ұ��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �@��
          ||                ln_cash_price                                                                 || cv_delimiter  -- �{�̉��i
          || cv_enclosed || TO_CHAR(gt_lease_data(ln_loop_cnt).lease_start_date,'YYYYMM')  || cv_enclosed || cv_delimiter  -- �V�K�_��N��
          ||                cv_null                                                                       || cv_delimiter  -- ذ�����
          ||                in_charge                                                                     || cv_delimiter  -- ���zذ���
          ||                cv_null                                                                       || cv_delimiter  -- �Č_��ذ���
          ||                cv_null                                                                       || cv_delimiter  -- ���z���[�X�����i�ύX�O�j
          ||                cv_null                                                                       || cv_delimiter  -- ذ��c��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �Č_��N��
          ||                cv_null                                                                       || cv_delimiter  -- �Č_���
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ��ذ��J�n��
          ||                cv_null                                                                       || cv_delimiter  -- �O�N�ی����x�z
          ||                cv_null                                                                       || cv_delimiter  -- �ی����x�z
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �O�N�ی������
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ی������
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ����ݒu��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ����x�XCD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ����c�Ə�CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ���r���t���O
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ���r����
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �m���
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu�於�i�Ж��j
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu���
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��TEL
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��s���{��CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��s��SCD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��Z��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �p���t���O
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �d����
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ��CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �f�|CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �_���ԋ敪
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ���p�t���O
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��X�֔ԍ�
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��Z���P
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��Z���Q
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �ݒu��Z���R
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ���[�X�㗝�X��Ћ敪
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- �[���v�Z���@_������
          ||                cv_null                                                                       || cv_delimiter  -- ��������
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ں��ލ쐬��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ں��ލ쐬PG
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ں��ލ쐬��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ں��ލX�V��
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ں��ލX�VPG
          || cv_enclosed || cv_null                                                        || cv_enclosed                  -- ں��ލX�V��
          ;
-- E_�{�ғ�_13456 2016/01/26 MOD END
          -- ====================================================
          -- �t�@�C����������
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
          -- ====================================================
          -- ���������J�E���g�A�b�v
          -- ====================================================
          ln_target_cnt := ln_target_cnt + 1 ;
          -- ====================================================
          -- A-8�D���[�X�_�񖾍׍X�V����
          -- ====================================================
          SELECT   contract_line_id AS contract_line_id
          INTO     in_contract_line_id
          FROM     xxcff_contract_lines
          WHERE    contract_line_id = gt_lease_data(ln_loop_cnt).contract_line_id
          FOR UPDATE NOWAIT
          ;
          --
          UPDATE  xxcff_contract_lines
          SET     VD_IF_DATE             = gd_sysdateb
          WHERE   contract_line_id       = gt_lease_data(ln_loop_cnt).contract_line_id
          ;
          --
        END LOOP out_loop;
        --
    ELSE
        -- ====================================================
        -- �t�@�C����������
        -- ====================================================
-- 00000136 2009/07/03 DEL START 
--        UTL_FILE.PUT_LINE( lf_file_hand, cv_null ) ;
-- 00000136 2009/07/03 DEL END
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
        (
        cv_appl_short_name,    -- 'XXCFF'
        cv_msg_xxcff00062      -- �Ώۃf�[�^��0���G���[
        )
        ,1
        ,5000);
        lv_errbuf  := lv_errmsg;
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
        --
    END IF;
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
    --
    gn_normal_cnt := ln_target_cnt;
    --
  EXCEPTION
    -- ====================================================
    -- *** ���b�N(�r�W�[)�G���[
    -- ====================================================
    WHEN lock_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--      UTL_FILE.FREMOVE  (  gn_file_dir_enter , gn_file_name_enter);
-- T1_1224 2009/05/28 DEL END   --
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
      (
       cv_appl_short_name   -- 'XXCFF'
      ,cv_msg_xxcff00007    -- �e�[�u�����b�N�G���[
      ,cv_tkn_table         -- �g�[�N��'TABLE'
      ,cv_msg_xxcff50030    -- ���[�X�_�񖾍�
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** �t�@�C���̏ꏊ�������ł� ***
    -- ====================================================
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,    -- 'XXCFF'
      cv_msg_xxcff00169      -- �t�@�C���̏ꏊ������
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    -- ====================================================
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,    -- 'XXCFF'
      cv_msg_xxcff00170      -- �t�@�C�����I�[�v���ł��Ȃ�
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** �����ݑ��쒆�ɃI�y���[�e�B���O�E�V�X�e���̃G���[���������܂��� ***
    -- ====================================================
    WHEN UTL_FILE.WRITE_ERROR THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--      UTL_FILE.FREMOVE  (  gn_file_dir_enter , gn_file_name_enter);
-- T1_1224 2009/05/28 DEL END   --
      END IF;
      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,   -- 'XXCFF'
      cv_msg_xxcff00171     -- �t�@�C���ɏ����݂ł��Ȃ�
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END put_lease_data;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2,     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_object_code_from     IN  VARCHAR2,     --   1.�����R�[�h(FROM)
    iv_object_code_to       IN  VARCHAR2      --   2.�����R�[�h(TO)
    )    
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
    -- *** ���[�J���ϐ� ***
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
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- =====================================================
    --  A-1�D��������
    -- =====================================================
    gd_sysdateb := SYSDATE;
    -- =====================================================
    --  A-2�D���̓p�����[�^�l���O�o�͏���
    -- =====================================================
    init
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-3�D�v���t�@�C���擾
    -- =====================================================
    get_profile_value
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-4�D���[�X�_����f�[�^�t�@�C����񃍃O����
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
    (
     cv_appl_short_name     -- 'XXCFF'
    ,cv_msg_xxcff00168      -- �t�@�C�����o�̓��b�Z�[�W
    ,cv_tkn_file            -- �g�[�N��'FILE_NAME'
    ,gn_file_name_enter     -- �t�@�C����
    )
    ,1
    ,5000);
    --
    FND_FILE.PUT_LINE
    (
     FND_FILE.OUTPUT
    ,lv_errmsg
    );
    --�P�s���s
    FND_FILE.PUT_LINE
    (
     which  => FND_FILE.OUTPUT
    ,buff   => '' 
    );
    --
    -- =====================================================
    --  A-5�D�p�����[�^�͈͎w��`�F�b�N���� 
    -- =====================================================
    chk_object_code
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,iv_object_code_from   -- �����R�[�h(FROM)
    ,iv_object_code_to     -- �����R�[�h(TO)
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- =====================================================
    --  A-6. ���[�X�_����̎擾
    -- =====================================================
    get_lease_data
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,iv_object_code_from   -- �����R�[�h(FROM)
    ,iv_object_code_to     -- �����R�[�h(TO)
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-7�D���[�X�_����f�[�^CSV�쐬����
    -- =====================================================
    put_lease_data
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- ���팏���̐ݒ�
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
--
  EXCEPTION
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
    errbuf                OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_object_code_from   IN    VARCHAR2,        --   �����R�[�h(FROM)
    iv_object_code_to     IN    VARCHAR2         --   �����R�[�h(TO)
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���FXXCFF�̈�
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
    lv_errbuf          VARCHAR2(5000);                               -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                  -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);                               -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                -- ���b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header
    (
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
    submain
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,iv_object_code_from   -- 1.�����R�[�hFrom
    ,iv_object_code_to     -- 2.�����R�[�hTo
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --�G���[�o��
    IF (lv_retcode IN( cv_status_error,cv_status_warn)) THEN
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
END XXCFF006A12C;
/