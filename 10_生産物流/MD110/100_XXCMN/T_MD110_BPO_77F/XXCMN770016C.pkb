CREATE OR REPLACE PACKAGE BODY xxcmn770016c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770016c(body)
 * Description      : �o�Ɏ��ѕ\
 * MD.050/070       : �����Y����(�o��)Issue1.0 (T_MD050_BPO_770)
 *                    �����Y����(�o��)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prc_check_param_info      PROCEDURE : �p�����[�^�`�F�b�N(F-1)
 *  prc_submit_request        PROCEDURE : ���[�R���J�����g���s(F-1)
 *  prc_param_init            PROCEDURE : �N���p�����[�^�ݒ�(F-1)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/17    1.0   Y.Itou           �V�K�쐬
 *  2008/05/16    1.1   T.Endou          �s�ID:77F-09�Ή�  �����N���p��YYYYM���͑Ή�
 *  2008/12/18    1.2   A.Shiina         �q�R���J�����g���N��������I��
 *
 *****************************************************************************************/
--
--##### �Œ�O���[�o���萔�錾�� START #############################################################
--
  -- ======================================================
  -- �R���J�����g�X�e�[�^�X
  -- ======================================================
  gv_status_normal    CONSTANT  VARCHAR2(1) := '0' ;
  gv_status_warn      CONSTANT  VARCHAR2(1) := '1' ;
  gv_status_error     CONSTANT  VARCHAR2(1) := '2' ;
--
  -- ======================================================
  -- �e���v���[�g�ݒ�p�iFND_REQUEST.ADD_LAYOUT�j
  -- ======================================================
  gc_temp_language    CONSTANT  VARCHAR2(2) := 'JA' ;    -- ����
  gc_temp_territory   CONSTANT  VARCHAR2(2) := 'JP' ;    -- �n��
  gc_output_format    CONSTANT  VARCHAR2(3) := 'PDF' ;   -- �o�̓t�H�[�}�b�g
--
  -- ======================================================
  -- ���b�Z�[�W�ҏW�p
  -- ======================================================
  gv_msg_part         CONSTANT  VARCHAR2(3) := ' : ' ;
  gv_msg_cont         CONSTANT  VARCHAR2(3) := '.';
--
--##### �Œ�O���[�o���萔�錾�� END   #############################################################
--
--##### �Œ�O���[�o���ϐ��錾�� START #############################################################
--
  -- ======================================================
  -- �e���v���[�g�ݒ�p�iFND_REQUEST.ADD_LAYOUT�j
  -- ======================================================
  gv_temp_appl_name             VARCHAR2(20) ;            -- �A�v���P�[�V�����Z�k��
  gv_temp_program_id            VARCHAR2(20) ;            -- �e���v���[�g��
--
  -- ======================================================
  -- �R���J�����g�N���p�iFND_REQUEST.SUBMIT_REQUEST�j
  -- ======================================================
  gv_conc_appl_name             VARCHAR2(20) ;              -- �A�v���P�[�V�����Z�k��
  gv_conc_program_id            VARCHAR2(20) ;              -- �v���O������
  gv_argument1                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�P
  gv_argument2                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�Q
  gv_argument3                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�R
  gv_argument4                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�S
  gv_argument5                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�T
  gv_argument6                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�U
  gv_argument7                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�V
  gv_argument8                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�W
  gv_argument9                  VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�O�X
  gv_argument10                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�O
  gv_argument11                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�P
  gv_argument12                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�Q
  gv_argument13                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�R
  gv_argument14                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�S
  gv_argument15                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�T
  gv_argument16                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�U
  gv_argument17                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�V
  gv_argument18                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�W
  gv_argument19                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�P�X
  gv_argument20                 VARCHAR2(100) := CHR(0) ;   -- �p�����[�^�Q�O
--
--##### �Œ�O���[�o���萔�錾�� END   #############################################################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gc_pkg_name         CONSTANT  VARCHAR2(20) := 'xxcmn770016c' ;   -- �p�b�P�[�W��
  gc_sub_pkg_name     CONSTANT  VARCHAR2(20) := 'xxcmn770026c' ;   -- �p�b�P�[�W��(��޺ݶ���)
  gc_appl_name        CONSTANT  VARCHAR2(20) := 'XXCMN' ;          -- ���b�Z�[�W�p
  gc_temp_appl_name   CONSTANT  VARCHAR2(20) := 'XXCMN' ;          -- �A�v���Z�k���iTemplate�j
  gc_conc_appl_name   CONSTANT  VARCHAR2(20) := 'XXCMN' ;          -- �A�v���Z�k���iConcurrent�j
--
  -- ===============================
  -- ���[�U�[�ϐ��O���[�o���萔
  -- ===============================
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD (
    proc_from                 VARCHAR2(6)       -- 01 : �����N��FROM
   ,proc_to                   VARCHAR2(6)       -- 02 : �����N��TO
   ,rcv_pay_div               VARCHAR2(5)       -- 03 : �󕥋敪
   ,rcv_pay_div_name          VARCHAR2(20)      --    : �󕥋敪��
   ,prod_div                  VARCHAR2(1)       -- 04 : ���i�敪
   ,prod_div_name             VARCHAR2(20)      --    : ���i�敪��
   ,item_div                  VARCHAR2(1)       -- 05 : �i�ڋ敪
   ,item_div_name             VARCHAR2(20)      --    : �i�ڋ敪��
   ,result_post               VARCHAR2(4)       -- 06 : ���ѕ���
   ,result_post_name          VARCHAR2(20)      --    : ���ѕ�����
   ,whse_code                 VARCHAR2(4)       -- 07 : �q�ɃR�[�h
   ,whse_code_name            VARCHAR2(20)      --    : �q�ɖ�
   ,party_code                VARCHAR2(4)       -- 08 : �o�א�R�[�h
   ,party_code_name           VARCHAR2(20)      --    : �o�א於
   ,crowd_type                VARCHAR2(1)       -- 09 : �S���
   ,crowd_code                VARCHAR2(4)       -- 10 : �S�R�[�h
   ,acnt_crowd_code           VARCHAR2(4)       -- 11 : �o���Q�R�[�h
  ) ;
--
--##### �Œ苤�ʗ�O�錾�� START ###################################################################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--##### �Œ苤�ʗ�O�錾�� END   ###################################################################
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : �p�����[�^�`�F�b�N(F-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info (
    ir_param           IN     rec_param_data   -- 01.���̓p�����[�^�Q
   ,ov_errbuf          OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    lc_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- �v���O������
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
    -- -------------------------------
    -- �G���[���b�Z�[�W�o�͗p
    -- -------------------------------
    -- �G���[�R�[�h
    lc_err_code_01        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010' ;
    -- �g�[�N����
    lc_token_name_01      CONSTANT VARCHAR2(100) := 'PARAMETER' ;
    lc_token_name_02      CONSTANT VARCHAR2(100) := 'VALUE' ;
    -- �g�[�N���l
    lc_token_value_01_01  CONSTANT VARCHAR2(100) := '�����N���iFROM�j' ;
    lc_token_value_01_02  CONSTANT VARCHAR2(100) := '�����N���iTO�j' ;
    -- ���t�t�H�[�}�b�g
    lc_char_m_format      CONSTANT VARCHAR2(100) := 'YYYYMM' ;
--
    -- *** ���[�J���ϐ� ***
    -- -------------------------------
    -- �G���[���b�Z�[�W�o�͗p
    -- -------------------------------
    lv_err_code                    VARCHAR2(100) ;
    lv_token_name_01               VARCHAR2(100) ;
    lv_token_name_02               VARCHAR2(100) ;
    lv_token_value_01              VARCHAR2(100) ;
    lv_token_value_02              VARCHAR2(100) ;
--
    -- -------------------------------
    -- �G���[�n���h�����O�p
    -- -------------------------------
    ld_work_date                   DATE; -- �ϊ��`�F�b�N�p
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt           EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �����N��FROM
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    ld_work_date :=  FND_DATE.STRING_TO_DATE( ir_param.proc_from, lc_char_m_format );
    IF ( ld_work_date IS NULL ) THEN
      lv_err_code       := lc_err_code_01 ;
      lv_token_name_01  := lc_token_name_01 ;
      lv_token_name_02  := lc_token_name_02 ;
      lv_token_value_01 := lc_token_value_01_01 ;
      lv_token_value_02 := ir_param.proc_from ;
      RAISE parameter_check_expt ;
    END IF ;
    -- ====================================================
    -- �����N��TO
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    ld_work_date :=  FND_DATE.STRING_TO_DATE( ir_param.proc_to, lc_char_m_format );
    IF ( ld_work_date IS NULL ) THEN
      lv_err_code       := lc_err_code_01 ;
      lv_token_name_01  := lc_token_name_01 ;
      lv_token_name_02  := lc_token_name_02 ;
      lv_token_value_01 := lc_token_value_01_02 ;
      lv_token_value_02 := ir_param.proc_to ;
      RAISE parameter_check_expt ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( iv_application   => gc_appl_name
                                            ,iv_name          => lv_err_code
                                            ,iv_token_name1   => lv_token_name_01
                                            ,iv_token_name2   => lv_token_name_02
                                            ,iv_token_value1  => lv_token_value_01
                                            ,iv_token_value2  => lv_token_value_02 ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_param_init
   * Description      : �N���p�����[�^�ݒ�(F-1)
   ***********************************************************************************/
  PROCEDURE prc_param_init (
    ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
   ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- =====================================================
    -- ���[�J���萔
    -- =====================================================
    lc_prg_name     CONSTANT  VARCHAR2(100) := 'prc_param_init' ;     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�J���ϐ�
    -- =====================================================
    -- -------------------------------
    -- ���ڕҏW�p
    -- -------------------------------
    lv_program_id             VARCHAR2(100)  ;      -- �v���O������
    lv_report_id              VARCHAR2(100)  ;      -- ���[��
--
  BEGIN
--
    -- ======================================================
    -- �e���v���[�g�ݒ�p�ϐ��̕ҏW�P
    -- ======================================================
    gv_temp_appl_name  := gc_temp_appl_name ;
--
    -- ======================================================
    -- �R���J�����g�N���p�ϐ��̕ҏW�P
    -- ======================================================
    gv_conc_appl_name  := gc_conc_appl_name ;
    gv_argument1       := ir_param.proc_from ;        -- 01 : �����N��FROM
    gv_argument2       := ir_param.proc_to ;          -- 02 : �����N��TO
    gv_argument3       := ir_param.rcv_pay_div ;      -- 03 : �󕥋敪
    gv_argument4       := ir_param.prod_div ;         -- 04 : ���i�敪
    gv_argument5       := ir_param.item_div ;         -- 05 : �i�ڋ敪
    gv_argument6       := ir_param.result_post ;      -- 06 : ���ѕ���
    gv_argument7       := ir_param.whse_code ;        -- 07 : �q�ɃR�[�h
    gv_argument8       := ir_param.party_code ;       -- 08 : �o�א�R�[�h
    gv_argument9       := ir_param.crowd_type ;       -- 09 : �S���
    gv_argument10      := ir_param.crowd_code ;       -- 10 : �S�R�[�h
    gv_argument11      := ir_param.acnt_crowd_code ;  -- 11 : �o���Q�R�[�h
--
    -- =====================================================
    -- �N���R���J�����g�̑I��
    -- =====================================================
--
    -- �W�v�p�^�[���P�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�q�ɁA4.�o�א�)
    IF  ( ir_param.result_post IS NULL )
    AND ( ir_param.whse_code   IS NULL )
    AND ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_01 ;
--
    -- �W�v�p�^�[���Q�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�q��)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_02 ;
--
    -- �W�v�p�^�[���R�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�o�א�)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_03 ;
--
    -- �W�v�p�^�[���S�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_04 ;
--
    -- �W�v�p�^�[���T�ݒ� (�W�v�F1.�i�ڋ敪�A2.�q�ɁA3.�o�א�)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_05 ;
--
    -- �W�v�p�^�[���U�ݒ� (�W�v�F1.�i�ڋ敪�A2.�q��)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_06 ;
--
    -- �W�v�p�^�[���V�ݒ� (�W�v�F1.�i�ڋ敪�A2.�o�א�)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_07 ;
--
    -- �W�v�p�^�[���W�ݒ� (�W�v�F1.�i�ڋ敪)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016c.gc_rtf_name_08 ;
    END IF;
--
    -- =====================================================
    -- �e���v���[�g�ݒ�p�ϐ��̕ҏW
    -- =====================================================
    gv_temp_program_id := gv_argument12 || 'C';
 --
   -- =====================================================
    -- �R���J�����g�ݒ�p�ϐ��̕ҏW
    -- =====================================================
    gv_conc_program_id := gc_sub_pkg_name;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END prc_param_init ;
--
--##### �Œ�v���V�[�W�� START #####################################################################
  /**********************************************************************************
   * Procedure Name   : prc_submit_request
   * Description      : ���[�R���J�����g���s(F-1)
   ***********************************************************************************/
  PROCEDURE prc_submit_request (
    ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- =====================================================
    -- �萔�錾
    -- =====================================================
    -- -------------------------------
    -- ���b�Z�[�W�o�͗p
    -- -------------------------------
    lc_prg_name             CONSTANT VARCHAR2(100) := 'prc_submit_request' ; -- �v���O������
    lc_err_code_template    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10134' ;
    lc_err_code_submit      CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135' ;
    lc_err_code_wait        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10136' ;
    -- -------------------------------
    -- �G���[�n���h�����O
    -- -------------------------------
    lc_dev_status_nomal     CONSTANT VARCHAR2(100) := 'NORMAL' ;
    lc_dev_status_warn      CONSTANT VARCHAR2(100) := 'WARNING' ;
    lc_dev_status_error     CONSTANT VARCHAR2(100) := 'ERROR' ;
--
    -- =====================================================
    -- �ϐ��錾
    -- =====================================================
    -- -------------------------------
    -- �I���X�e�[�^�X
    -- -------------------------------
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- -------------------------------
    -- �߂�l�E�A�E�g�p�����[�^
    -- -------------------------------
    lb_ret                  BOOLEAN ;
    ln_req_id               NUMBER ;
    lv_ret_phase            VARCHAR2(1000) ;
    lv_ret_status           VARCHAR2(1000) ;
    lv_ret_dev_phase        VARCHAR2(1000) ;
    lv_ret_dev_status       VARCHAR2(1000) ;
    lv_ret_message          VARCHAR2(1000) ;
--
  BEGIN
--
    -- =====================================================
    -- �o�͒��[�̎w��
    -- =====================================================
    lb_ret := FND_REQUEST.ADD_LAYOUT (
                template_appl_name  => gv_temp_appl_name        -- �A�v���P�[�V�����Z�k��
               ,template_code       => gv_temp_program_id       -- �e���v���[�g��
               ,template_language   => gc_temp_language         -- ����
               ,template_territory  => gc_temp_territory        -- �n��
               ,output_format       => gc_output_format         -- �o�̓t�H�[�}�b�g
              ) ;
    -- �G���[�̏ꍇ
    IF ( lb_ret = FALSE ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg (
                      iv_application   => gc_appl_name
                     ,iv_name          => lc_err_code_template
                   ) ;
      RAISE global_api_expt ;
    END IF ;
--
    -- =====================================================
    -- �T�u�R���J�����g�̌Ăяo��
    -- =====================================================
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                   application       => gv_conc_appl_name    -- �A�v���P�[�V�����Z�k��
                  ,program           => gv_conc_program_id   -- �v���O������
                  ,start_time        => SYSDATE              -- ���s��
                  ,argument1         => gv_argument1         -- �p�����[�^�O�P
                  ,argument2         => gv_argument2         -- �p�����[�^�O�Q
                  ,argument3         => gv_argument3         -- �p�����[�^�O�R
                  ,argument4         => gv_argument4         -- �p�����[�^�O�S
                  ,argument5         => gv_argument5         -- �p�����[�^�O�T
                  ,argument6         => gv_argument6         -- �p�����[�^�O�U
                  ,argument7         => gv_argument7         -- �p�����[�^�O�V
                  ,argument8         => gv_argument8         -- �p�����[�^�O�W
                  ,argument9         => gv_argument9         -- �p�����[�^�O�X
                  ,argument10        => gv_argument10        -- �p�����[�^�P�O
                  ,argument11        => gv_argument11        -- �p�����[�^�P�P
                  ,argument12        => gv_argument12        -- �p�����[�^�P�Q
                  ,argument13        => gv_argument13        -- �p�����[�^�P�R
                  ,argument14        => gv_argument14        -- �p�����[�^�P�S
                  ,argument15        => gv_argument15        -- �p�����[�^�P�T
                  ,argument16        => gv_argument16        -- �p�����[�^�P�U
                  ,argument17        => gv_argument17        -- �p�����[�^�P�V
                  ,argument18        => gv_argument18        -- �p�����[�^�P�W
                  ,argument19        => gv_argument19        -- �p�����[�^�P�X
                  ,argument20        => gv_argument20        -- �p�����[�^�Q�O
                 ) ;
    -- �G���[�̏ꍇ
    IF ( ln_req_id = 0 ) THEN
      ROLLBACK ;
      lv_errmsg := xxcmn_common_pkg.get_msg (
                     iv_application   => gc_appl_name
                    ,iv_name          => lc_err_code_submit
                   ) ;
      RAISE global_api_expt ;
    END IF ;
--
-- 2008/12/18 v1.2 DELETE START
/*
    COMMIT ;
--
    -- =====================================================
    -- �ҋ@����
    -- =====================================================
    lb_ret := FND_CONCURRENT.WAIT_FOR_REQUEST (
                request_id   => ln_req_id          -- �v���h�c
               ,interval     => 5                  -- �X���[�v����
               ,phase        => lv_ret_phase       -- OUT : �v���t�F�[�Y
               ,status       => lv_ret_status      -- OUT : �v���X�e�[�^�X
               ,dev_phase    => lv_ret_dev_phase   -- OUT : �v���t�F�[�Y�i�萔�j
               ,dev_status   => lv_ret_dev_status  -- OUT : �v���X�e�[�^�X�i�萔�j
               ,message      => lv_ret_message     -- OUT : �������b�Z�[�W
              ) ;
    -- �G���[�̏ꍇ
    IF ( lb_ret = FALSE ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg (
                     iv_application   => gc_appl_name
                    ,iv_name          => lc_err_code_wait
                   ) ;
      RAISE global_api_expt ;
    END IF;
--
    -- �T�u�R���J�����g���ُ�I�������ꍇ
    IF ( lv_ret_dev_status = lc_dev_status_error ) THEN
      ov_retcode := gv_status_error ;
--
    -- �T�u�R���J�����g���x���I�������ꍇ
    ELSIF ( lv_ret_dev_status = lc_dev_status_warn ) THEN
      ov_retcode := gv_status_warn ;
--
    END IF ;
--
*/
-- 2008/12/18 v1.2 DELETE END
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
  END prc_submit_request ;
--##### �Œ�v���V�[�W�� END   #####################################################################
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_from          IN    VARCHAR2  --   01 : �����N��FROM
     ,iv_proc_to            IN    VARCHAR2  --   02 : �����N��TO
     ,iv_rcv_pay_div        IN    VARCHAR2  --   03 : �󕥋敪
     ,iv_prod_div           IN    VARCHAR2  --   04 : ���i�敪
     ,iv_item_div           IN    VARCHAR2  --   05 : �i�ڋ敪
     ,iv_result_post        IN    VARCHAR2  --   06 : ���ѕ���
     ,iv_whse_code          IN    VARCHAR2  --   07 : �q�ɃR�[�h
     ,iv_party_code         IN    VARCHAR2  --   08 : �o�א�R�[�h
     ,iv_crowd_type         IN    VARCHAR2  --   09 : �S���
     ,iv_crowd_code         IN    VARCHAR2  --   10 : �S�R�[�h
     ,iv_acnt_crowd_code    IN    VARCHAR2  --   11 : �o���Q�R�[�h
     ,ov_errbuf            OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT    VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �p�����[�^�i�[
    -- =====================================================
    lr_param_rec.proc_from       := iv_proc_from;          -- �����N��FROM
    lr_param_rec.proc_to         := iv_proc_to;            -- �����N��TO
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;        -- �󕥋敪
    lr_param_rec.prod_div        := iv_prod_div;           -- ���i�敪
    lr_param_rec.item_div        := iv_item_div;           -- �i�ڋ敪
    lr_param_rec.result_post     := iv_result_post;        -- ���ѕ���
    lr_param_rec.whse_code       := iv_whse_code;          -- �q�ɃR�[�h
    lr_param_rec.party_code      := iv_party_code;         -- �o�א�R�[�h
    lr_param_rec.crowd_type      := iv_crowd_type;         -- �S���
    lr_param_rec.crowd_code      := iv_crowd_code;         -- �S�R�[�h
    lr_param_rec.acnt_crowd_code := iv_acnt_crowd_code;    -- �o���Q�R�[�h
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_check_param_info (
      ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
     ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �N���p�����[�^�ݒ�
    -- =====================================================
    prc_param_init (
      ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
     ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�R���J�����g���s
    -- =====================================================
    prc_submit_request (
      ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode            OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_proc_from       IN    VARCHAR2  --   01 : �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : �����N��TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : �󕥋敪
     ,iv_prod_div        IN    VARCHAR2  --   04 : ���i�敪
     ,iv_item_div        IN    VARCHAR2  --   05 : �i�ڋ敪
     ,iv_result_post     IN    VARCHAR2  --   06 : ���ѕ���
     ,iv_whse_code       IN    VARCHAR2  --   07 : �q�ɃR�[�h
     ,iv_party_code      IN    VARCHAR2  --   08 : �o�א�R�[�h
     ,iv_crowd_type      IN    VARCHAR2  --   09 : �S���
     ,iv_crowd_code      IN    VARCHAR2  --   10 : �S�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : �o���Q�R�[�h
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_proc_from        => iv_proc_from         --   01 : �����N��FROM
       ,iv_proc_to          => iv_proc_to           --   02 : �����N��TO
       ,iv_rcv_pay_div      => iv_rcv_pay_div       --   03 : �󕥋敪
       ,iv_prod_div         => iv_prod_div          --   04 : ���i�敪
       ,iv_item_div         => iv_item_div          --   05 : �i�ڋ敪
       ,iv_result_post      => iv_result_post       --   06 : ���ѕ���
       ,iv_whse_code        => iv_whse_code         --   07 : �q�ɃR�[�h
       ,iv_party_code       => iv_party_code        --   08 : �o�א�R�[�h
       ,iv_crowd_type       => iv_crowd_type        --   09 : �S���
       ,iv_crowd_code       => iv_crowd_code        --   10 : �S�R�[�h
       ,iv_acnt_crowd_code  => iv_acnt_crowd_code   --   11 : �o���Q�R�[�h
       ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn770016c ;
/
