CREATE OR REPLACE PACKAGE BODY xxcfr_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcfr_common_pkg(body)
 * Description      : 
 * MD.050           : �Ȃ�
 * Version          : 1.3
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  get_user_dept             F    VAR    ���O�C�����[�U��������擾�֐�
 *  chk_invoice_all_dept      F    VAR    �������S�Џo�͌�������֐�
 *  put_log_param             P           ���̓p�����[�^�l���O�o�͏���
 *  get_table_comment         F    VAR    �e�[�u���R�����g�擾����
 *  get_user_profile_name     F    VAR    ���[�U�v���t�@�C�����擾����
 *  get_cust_account_name     F    VAR    �ڋq���̎擾�֐�
 *  get_col_comment           F    VAR    ���ڃR�����g�擾����
 *  lookup_dictionary         F    VAR    ���{�ꎫ���Q�Ɗ֐�����
 *  get_date_param_trans      F    VAR    ���t�p�����[�^�ϊ��֐�
 *  csv_out                   P           OUT�t�@�C���o�͏���
 *  get_base_target_tel_num   F    VAR    �������_�S���d�b�ԍ��擾�֐�
 *  get_receive_updatable     F    VAR    ������� �ڋq�ύX�\����
-- Modify 2010.07.09 Ver1.3 Start
 *  awi_ship_code             P           ARWebInquiry�p �[�i��ڋq�R�[�h�l���X�g
-- Modify 2010.07.09 Ver1.3 End
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-10-16   1.0    SCS ���b       �V�K�쐬
 *  2008-10-28   1.0    SCS ���� �א�    �ڋq���̎擾�֐��ǉ�
 *  2008-10-29   1.0    SCS ���� ��      ���̓p�����[�^�l���O�o�͊֐��֐��ǉ�
 *  2008-11-10   1.0    SCS ���� ��      ���̓p�����[�^�l���O�o�͊֐��C��
 *  2008-11-10   1.0    SCS ���� ��      ���ڃR�����g�擾�����֐��ǉ�
 *  2008-11-12   1.0    SCS ���� ��      ���{�ꎫ���Q�Ɗ֐������ǉ�
 *  2008-11-13   1.0    SCS ���� �א�    ���t�p�����[�^�ϊ��֐��ǉ�
 *  2008-11-18   1.0    SCS �g�� ���i    OUT�t�@�C���o�͏����ǉ�
 *  2008-12-22   1.0    SCS ���� �א�    �������_�S���d�b�ԍ��擾�֐��ǉ�
 *  2009-03-31   1.1    SCS ��� �b      [��QT1_0210] �������_�S���d�b�ԍ��擾�֐� �����g�D�Ή�
 *  2010-03-31   1.2    SCS ���� �q��    ��Q�uE_�{�ғ�_02092�v�Ή�
 *                                       �V�Kfunction�uget_receive_updatable�v��ǉ�
 *  2010-07-09   1.3    SCS �A�� �^���l  ��Q�uE_�{�ғ�_01990�v�Ή�
 *                                       �V�KPrucedure�uawi_ship_code�v��ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
  gv_conc_prefix     CONSTANT VARCHAR2(6)   := '$SRS$.';   -- �R���J�����g�Z�k���v���t�B�b�N�X
  gv_const_yes       CONSTANT VARCHAR2(1)   := 'Y';        -- �g�p�\='Y'
--
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR_COMMON_PKG'; -- �p�b�P�[�W��
  gv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  gv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
  -- ���b�Z�[�W�ԍ�
  gv_msg_cmn_001     CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; --�R���J�����g���̓p�����[�^�Ȃ�
  gv_msg_cmn_002     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00002'; --�p�����[�^��
-- �g�[�N��
  gv_tkn_parmn       CONSTANT VARCHAR2(15) := 'PARAM_NAME';       -- �p�����[�^��
  gv_tkn_parmv       CONSTANT VARCHAR2(15) := 'PARAM_VAL';        -- �p�����[�^�l
  gv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- �擾�f�[�^���ږ�
--
  /**********************************************************************************
   * Function Name    : get_user_dept
   * Description      : ���O�C�����[�U��������擾�֐�
   ***********************************************************************************/
  FUNCTION get_user_dept(
    in_user_id      IN NUMBER,          -- ���[�UID
    id_get_date     IN DATE  )          -- �擾���t
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_user_dept'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_get_date     DATE;                                     -- �擾���t
    lv_dept_code    FND_FLEX_VALUES.FLEX_VALUE%TYPE := NULL ; -- �擾���喼
--
  BEGIN
--
    -- ====================================================
    -- ���O�C�����[�U��������擾�֐��������W�b�N�̋L�q
    -- ===================================================
    -- �擾���t��ݒ�
      ld_get_date := TRUNC(id_get_date);
--
    -- ����������擾
    BEGIN
      SELECT papf.attribute28  attribute28                  -- ���O�C�����[�U��������
      INTO lv_dept_code
      FROM per_all_people_f  papf                           -- �]�ƈ��}�X�^
      WHERE TRUNC(papf.effective_start_date) <= ld_get_date -- �L���J�n��
        AND ld_get_date <= TRUNC(papf.effective_end_date)   -- �L���I����
        AND EXISTS( SELECT 'x'
                    FROM fnd_user fndu                      -- EBS���[�U�}�X�^
                    WHERE fndu.employee_id=papf.person_id   -- ��ٗp��ID
                      AND fndu.user_id = in_user_id)        -- �]�ƈ�ID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    RETURN lv_dept_code;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END get_user_dept;
--
--
/**********************************************************************************
   * Function Name    : chk_invoice_all_dept
   * Description      : �������S�Џo�͌�������֐�
   ***********************************************************************************/
  FUNCTION chk_invoice_all_dept(
    iv_user_dept_code IN VARCHAR2,        -- ��������R�[�h
    iv_invoice_type   IN VARCHAR2)        -- �������^�C�v
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.chk_invoice_all_dept'; -- �v���O������
    cv_lookup_type CONSTANT FND_LOOKUP_TYPES.LOOKUP_TYPE%TYPE := 'XXCFR1_INVOICE_ALL_OUTPUT_DEPT'; -- �Q�ƃ^�C�v��
    cv_return_type CONSTANT VARCHAR2(1)   := 'N'; -- ���^�[���R�[�h�i�����j
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_invoice_type VARCHAR2(1); --�������^�C�v
    lv_return_val   VARCHAR2(1) := cv_return_type;--���^�[���R�[�h
--
  BEGIN
--
    -- ====================================================
    -- �������S�Џo�͌�������֐��������W�b�N�̋L�q
    -- ===================================================
    -- �������^�C�v��ݒ�
    lv_invoice_type := iv_invoice_type;
--
    -- �������^�C�v���擾
    BEGIN
      SELECT CASE iv_invoice_type WHEN 'A' THEN flvv.attribute1 -- �������z�ꗗ�\
                                  WHEN 'G' THEN flvv.attribute2 -- �ėp������
                                  WHEN 'S' THEN flvv.attribute3 -- �W��������
                                  ELSE cv_return_type
             END                  invoice_type                  -- �������^�C�v
      INTO lv_return_val
      FROM fnd_lookup_values_vl flvv                            -- �Q�ƃ^�C�v�r���[
      WHERE flvv.lookup_type = cv_lookup_type                   -- �Q�ƃ^�C�v
        AND flvv.lookup_code = iv_user_dept_code                -- ��������
        AND flvv.enabled_flag = 'Y'                             -- �L���t���O
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  RETURN lv_return_val;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END chk_invoice_all_dept;
--
  /**********************************************************************************
   * Procedure Name   : put_log_param
   * Description      : ���̓p�����[�^�l���O�o�͏��� (A-1)
   ***********************************************************************************/
  PROCEDURE put_log_param(
    iv_which                IN  VARCHAR2 DEFAULT 'OUTPUT',  -- �o�͋敪
    iv_conc_param1          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�P
    iv_conc_param2          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�Q
    iv_conc_param3          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�R
    iv_conc_param4          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�S
    iv_conc_param5          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�T
    iv_conc_param6          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�U
    iv_conc_param7          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�V
    iv_conc_param8          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�W
    iv_conc_param9          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�X
    iv_conc_param10         IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�P�O
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_param'; -- �v���O������
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
    lv_which_out    VARCHAR2(10) := 'OUTPUT';   -- �t�@�C���o��
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt   NUMBER;         -- �d�����Ă��錏��
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
    lv_param_val    VARCHAR2(2000); -- �p�����[�^�l
    ln_which        NUMBER;         -- �t�@�C���o�͐�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �R���J�����g�p�����[�^�����o
    CURSOR conc_param_name_cur1
    IS
      SELECT fdfc.column_seq_num          column_seq_num,         -- �J�����m�n
             fdfc.end_user_column_name    end_user_column_name,   -- �J������
             fdfc.description             description             -- �E�v
      FROM fnd_concurrent_programs_vl  fcpv,
           fnd_descr_flex_col_usage_vl fdfc
      WHERE fdfc.application_id                = fnd_global.prog_appl_id  -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
        AND fdfc.descriptive_flexfield_name    = gv_conc_prefix || fcpv.concurrent_program_name
        AND fdfc.enabled_flag                  = gv_const_yes
        AND fdfc.application_id                = fcpv.application_id
        AND fcpv.concurrent_program_id         = fnd_global.conc_program_id  -- �R���J�����g�E�v���O�����̃v���O����ID 
      ORDER BY fdfc.column_seq_num
    ;
--
    TYPE conc_param_name_tbl1 IS TABLE OF conc_param_name_cur1%ROWTYPE INDEX BY PLS_INTEGER;
    lt_conc_param_name_data1    conc_param_name_tbl1;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C���o�͐�̑I��
    IF ( iv_which = lv_which_out ) THEN
      ln_which := FND_FILE.OUTPUT;
    ELSE
      ln_which := FND_FILE.LOG;
    END IF;
--
    -- �P�s�X�y�[�X
    FND_FILE.PUT_LINE(
       ln_which
      ,''
    );
    -- �J�[�\���I�[�v��
    OPEN conc_param_name_cur1;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH conc_param_name_cur1 BULK COLLECT INTO lt_conc_param_name_data1;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_conc_param_name_data1.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE conc_param_name_cur1;
--
    -- �p�����[�^��`����̏ꍇ�̓p�����[�^�����O�ɏo�͂���
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        -- �p�����[�^�l�����[�v�l�ɍ��킹�؂�ւ���
        lv_param_val :=
          CASE ln_loop_cnt
            WHEN 1 THEN iv_conc_param1
            WHEN 2 THEN iv_conc_param2
            WHEN 3 THEN iv_conc_param3
            WHEN 4 THEN iv_conc_param4
            WHEN 5 THEN iv_conc_param5
            WHEN 6 THEN iv_conc_param6
            WHEN 7 THEN iv_conc_param7
            WHEN 8 THEN iv_conc_param8
            WHEN 9 THEN iv_conc_param9
            WHEN 10 THEN iv_conc_param10
            ELSE NULL
          END;
--
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_cfr     -- 'XXCFR'
                                                      ,gv_msg_cmn_002
                                                      ,gv_tkn_parmn -- �g�[�N��'PARAM_NAME'
                                                      ,lt_conc_param_name_data1(ln_loop_cnt).description -- �p�����[�^��
                                                      ,gv_tkn_parmv -- �g�[�N��'PARAM_VAL'
                                                      ,lv_param_val) -- �p�����[�^�l
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(ln_which, lv_errmsg);
      END LOOP null_data_loop1;
--
    -- �p�����[�^��`�Ȃ��̏ꍇ�̓p�����[�^�Ȃ����b�Z�[�W�����O�ɏo�͂���
    ELSE
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_ccp     -- 'XXCCP'
                                                      ,gv_msg_cmn_001) -- �p�����[�^�l
                                                        -- �R���J�����g���̓p�����[�^�Ȃ�
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(ln_which, lv_errmsg);
--
    END IF;
--
    FND_FILE.PUT_LINE(
       ln_which
      ,''
    );
--
  EXCEPTION
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
  END put_log_param;
--
  /**********************************************************************************
   * Function Name    : get_table_comment
   * Description      : �e�[�u���R�����g�擾����
   ***********************************************************************************/
  FUNCTION get_table_comment(
    iv_table_name          IN  VARCHAR2 )       -- �e�[�u����
  RETURN VARCHAR2 IS -- �e�[�u���R�����g
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_table_comment'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt     NUMBER;         -- �Ώی���
    ln_loop_cnt       NUMBER;         -- ���[�v�J�E���^
    lv_table_name_jp  VARCHAR2(200);  -- �e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �e�[�u�������o
    CURSOR table_name_cur
    IS
      SELECT atc.comments     comments    -- �e�[�u���R�����g
      FROM all_tab_comments   atc
      WHERE atc.table_name           = iv_table_name
    ;
--
    TYPE table_name_tbl IS TABLE OF table_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_table_name_data    table_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN table_name_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH table_name_cur BULK COLLECT INTO lt_table_name_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_table_name_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE table_name_cur;
--
    -- �Ώۃf�[�^����̏ꍇ�̓e�[�u������߂�l�ɐݒ�
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_table_name_jp := lt_table_name_data(ln_loop_cnt).comments;
      END LOOP null_data_loop1;
      RETURN lv_table_name_jp;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ�́ANULL��߂�l�ɐݒ�
    ELSE
--
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_table_comment;
--
  /**********************************************************************************
   * Function Name    : get_user_profile_name
   * Description      : �v���t�@�C�����擾����
   ***********************************************************************************/
  FUNCTION get_user_profile_name(
    iv_profile_name          IN  VARCHAR2 )       -- �v���t�@�C����
  RETURN VARCHAR2 IS    -- ���[�U�v���t�@�C����
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_profile_name'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt       NUMBER;         -- �Ώی���
    ln_loop_cnt         NUMBER;         -- ���[�v�J�E���^
    lv_profile_name_jp  VARCHAR2(200);  -- �v���t�@�C����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �v���t�@�C�������o
    CURSOR profile_name_cur
    IS
      SELECT fpot.user_profile_option_name    user_profile_option_name,   -- �v���t�@�C����
             fpot.description                 description                 -- �E�v
      FROM fnd_profile_options_tl fpot
      WHERE profile_option_name = iv_profile_name
        AND language = userenv ( 'LANG' );
--
    TYPE profile_name_tbl IS TABLE OF profile_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_profile_name_data    profile_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN profile_name_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH profile_name_cur BULK COLLECT INTO lt_profile_name_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_profile_name_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE profile_name_cur;
--
    -- �Ώۃf�[�^����̏ꍇ�̓v���t�@�C������߂�l�ɐݒ�
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_profile_name_jp := lt_profile_name_data(ln_loop_cnt).user_profile_option_name;
      END LOOP null_data_loop1;
      RETURN lv_profile_name_jp;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ�́ANULL��߂�l�ɐݒ�
    ELSE
--
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_user_profile_name;
--
  /**********************************************************************************
   * Function Name    : get_cust_account_name
   * Description      : �ڋq���̎擾�֐�
   ***********************************************************************************/
  FUNCTION get_cust_account_name(
    iv_account_number      IN  VARCHAR2,      -- 1.�ڋq�R�[�h
    iv_kana_judge_type     IN  VARCHAR2       -- 2.�J�i�����f�敪(0:��������, 1:�J�i��)
                        )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_cust_account_name'; -- PRG��
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_party_name         hz_parties.party_name%TYPE := NULL                 ; -- �擾�ڋq��
    lv_party_kana_name    hz_parties.organization_name_phonetic%TYPE := NULL ; -- �擾�ڋq�J�i��
--
  BEGIN
--
    -- ====================================================
    -- �ڋq����(�J�i��)�擾�֐��������W�b�N�̋L�q
    -- ===================================================
    -- �ڋq����(�J�i��)���擾
    BEGIN
      SELECT hzpt.party_name                  party_name,
             hzpt.organization_name_phonetic  organization_name_phonetic
      INTO   lv_party_name
            ,lv_party_kana_name
      FROM   hz_parties       hzpt,
             hz_cust_accounts hzca
      WHERE  hzca.party_id = hzpt.party_id
      AND    hzca.account_number = iv_account_number
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL ;
    END ;
    
    IF iv_kana_judge_type = 1 THEN
      RETURN lv_party_kana_name;
    ELSE
      RETURN lv_party_name ;
    END IF;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END get_cust_account_name;
--
  /**********************************************************************************
   * Function Name    : get_col_comment
   * Description      : ���ڃR�����g�擾����
   ***********************************************************************************/
  FUNCTION get_col_comment(
    iv_table_name          IN  VARCHAR2,        -- �e�[�u����
    iv_column_name         IN  VARCHAR2 )       -- ���ږ�
  RETURN VARCHAR2 IS -- ���ڃR�����g
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_col_comment'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt     NUMBER;         -- �Ώی���
    ln_loop_cnt       NUMBER;         -- ���[�v�J�E���^
    lv_column_name_jp all_col_comments.comments%type; -- ���ږ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���ږ����o
    CURSOR column_name_cur
    IS
      SELECT acc.comments     comments      -- ���ڃR�����g
      FROM all_col_comments   acc
      WHERE acc.table_name           = iv_table_name
        AND acc.column_name          = iv_column_name
      ;
--
    TYPE column_name_tbl IS TABLE OF column_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_column_name_data    column_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN column_name_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH column_name_cur BULK COLLECT INTO lt_column_name_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_column_name_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE column_name_cur;
--
    -- �Ώۃf�[�^����̏ꍇ�͍��ږ���߂�l�ɐݒ�
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_column_name_jp := lt_column_name_data(ln_loop_cnt).comments;
      END LOOP null_data_loop1;
      RETURN lv_column_name_jp;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ�́ANULL��߂�l�ɐݒ�
    ELSE
--
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_col_comment;
--
  /**********************************************************************************
   * Function Name    : lookup_dictionary
   * Description      : ���{�ꎫ���Q��
   ***********************************************************************************/
  FUNCTION lookup_dictionary(
     iv_loopup_type_prefix  IN  VARCHAR2         -- �Q�ƃ^�C�v�̐ړ����i�A�v���P�[�V�����Z�k���Ɠ����j
    ,iv_keyword             IN  VARCHAR2         -- �L�[���[�h
  )
  RETURN VARCHAR2 IS -- ���{����e
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lookup_dictionary'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_lookup_type_const  CONSTANT VARCHAR2(100) := '1_ERR_MSG_TOKEN';  -- �Q�ƃ^�C�v���̐ړ����ȍ~
    cv_enabled_yes        CONSTANT VARCHAR2(1)   := 'Y';                -- �L���t���O�i�x�j
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt     NUMBER;         -- �Ώی���
    ln_loop_cnt       NUMBER;         -- ���[�v�J�E���^
    lv_meaning_jp     fnd_lookup_values_vl.meaning%type; -- ���{����e
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �e�[�u�������o
    CURSOR meaning_cur
    IS
      SELECT flvv.meaning         meaning       -- ���{�ꕶ��
      FROM fnd_lookup_values_vl   flvv
      WHERE flvv.lookup_type             = iv_loopup_type_prefix || cv_lookup_type_const   -- ���{�ꎫ���̎Q�ƃ^�C�v��
        AND flvv.lookup_code             = iv_keyword
        AND flvv.enabled_flag            = cv_enabled_yes
        AND ( flvv.start_date_active     IS NULL
           OR flvv.start_date_active     <= TRUNC ( SYSDATE ) )
        AND ( flvv.end_date_active       IS NULL
           OR flvv.end_date_active       >= TRUNC ( SYSDATE ) )
      ;
--
    TYPE l_meaning_ttype IS TABLE OF meaning_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_meaning_data      l_meaning_ttype;
--
  BEGIN
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN meaning_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH meaning_cur BULK COLLECT INTO lt_meaning_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_meaning_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE meaning_cur;
--
    -- �Ώۃf�[�^����̏ꍇ�͓��{����e��߂�l�ɐݒ�
    IF (ln_target_cnt > 0) THEN
      <<data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_meaning_jp := lt_meaning_data(ln_loop_cnt).meaning;
      END LOOP data_loop;
      RETURN lv_meaning_jp;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ�́ANULL��߂�l�ɐݒ�
    ELSE
--
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END lookup_dictionary;
--
  /**********************************************************************************
   * Function Name    : get_date_param_trans
   * Description      : ���t�p�����[�^�ϊ��֐�
   ***********************************************************************************/
  FUNCTION get_date_param_trans(
    iv_date_param             IN  VARCHAR2         -- ���t�l�p�����[�^(������^)
  )
  RETURN DATE IS -- ���t�l�p�����[�^(���t�^)
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_date_param_trans'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_date_format     CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';  -- �Q�ƃ^�C�v��
--
    -- *** ���[�J���ϐ� ***
    ld_date_param     DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
    -- �p�����[�^�ϊ�
      ld_date_param := TO_DATE(iv_date_param, cv_date_format);
--
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;
--
    RETURN ld_date_param;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_date_param_trans;
--
/************************************************************************
 * Procedure Name  : csv_out
 * Description     : OUT�t�@�C���o�͏���
 ************************************************************************/
  PROCEDURE  csv_out(
    in_request_id  IN  NUMBER,    -- 1.�v��ID
    iv_lookup_type IN  VARCHAR2,  -- 2.�Q�ƃ^�C�v
    in_rec_cnt     IN  NUMBER,    -- 3.���R�[�h����
    ov_errbuf      OUT VARCHAR2,  -- 4.�o�̓��b�Z�[�W
    ov_retcode     OUT VARCHAR2,  -- 5.���^�[���R�[�h
    ov_errmsg      OUT VARCHAR2 ) -- 6.���[�U���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'csv_out' ;          -- �v���O������
    cv_meg_cfr1_15   CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00015' ; -- �擾�f�[�^�Ȃ����b�Z�[�W
    cv_meg_cfr1_23   CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00023' ; -- �Ώۃf�[�^�Ȃ����b�Z�[�W
--
    --
    -- �񌩏o���E���蕶�����i�[
    -- ���R�[�h�^�C�v
    TYPE rt_flv_type IS RECORD (meaning     fnd_lookup_values.meaning%TYPE,
                                attribute1  fnd_lookup_values.attribute1%TYPE) ;
    -- �\�^�C�v
    TYPE tt_flv_type IS TABLE OF rt_flv_type INDEX BY BINARY_INTEGER ;
  
    -- �\�ϐ�
    tt_flv   tt_flv_type ;
  
    -- �񌩏o���E���蕶���擾�J�[�\��
    CURSOR  cur_flv(
      iv_lookup_type  VARCHAR2)
    IS
      SELECT  meaning          meaning,         -- �񌩏o��
              attribute1       attribute1       -- ���蕶������
      FROM    fnd_lookup_values_vl
      WHERE   lookup_type       =  iv_lookup_type
      AND     enabled_flag      =  'Y' 
      AND     NVL(start_date_active,TO_DATE('19000101','YYYYMMDD')) <= TRUNC(SYSDATE)
      AND     NVL(end_date_active,TO_DATE('22001231','YYYYMMDD'))   >= TRUNC(SYSDATE)
      ORDER BY TO_NUMBER( lookup_code );
    --
    -- �񌩏o���E���蕶���擾���R�[�h�ϐ�
    rec_flv   cur_flv%ROWTYPE ;
    --
    -- ���ISQL�p�Q�ƃJ�[�\���^�C�v
    TYPE cur_sql_type IS REF CURSOR ;
    --
    -- ���ISQL�p�Q�ƃJ�[�\��
    cur_sql cur_sql_type ;
    --
    ln_flv_cnt       NUMBER := 0 ;
    lv_buf           VARCHAR2(32767) ;
    lv_sql           VARCHAR2(32767) ;
    lv_errmsg        VARCHAR2(32767) ;
    lv_errbuf        VARCHAR2(32767) ;
    --
  BEGIN
  --
    -- ���^�[���R�[�h�E����l�ݒ�
    ov_retcode := gv_status_normal ;
  --
  ------------------------------------
  -- �P�D�񌩏o������ъ��蕶�����ʂ̎擾�Ɨ񌩏o���̏o��
  ------------------------------------
  --
    -- �Q�ƕ\���񌩏o���E���蔻�ʎ擾
    <<cur_flv_loop>>
    FOR rec_flv IN cur_flv( iv_lookup_type )
    LOOP
      ln_flv_cnt := ln_flv_cnt + 1 ;
      --
      tt_flv(ln_flv_cnt).meaning    := rec_flv.meaning ;     -- �񌩏o��
      tt_flv(ln_flv_cnt).attribute1 := rec_flv.attribute1 ;  -- ���蕶������
      
      IF (ln_flv_cnt = 1) THEN  -- ���o��1����
      --
        lv_buf := lv_buf||'"'||rec_flv.meaning||'"' ;
        --
      ELSE                    -- ���o��2���ڈȍ~
      --
        lv_buf := lv_buf||',"'||rec_flv.meaning||'"' ;
        --
      END IF ;
      --
    END LOOP cur_flv_loop ;
    --
    IF ( ln_flv_cnt = 0 ) THEN
    --
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_cfr,     -- 'XXCFR'
                                                     cv_meg_cfr1_15,     -- �擾�f�[�^�Ȃ�
                                                     gv_tkn_data,
                                                     xxcfr_common_pkg.lookup_dictionary('XXCFR','CFR000A00005'))  -- �g�[�N��'�񌩏o��'
                                                     ,1
                                                     ,5000) ;
      --
      RAISE global_api_expt ;
    END IF ;
    --
    -- CSV�o�́i�񌩏o���j
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT , lv_buf ) ;
    --
    -- �o�͕ϐ��N���A
    lv_buf := NULL ;
    --
    ------------------------------------
    -- �Q�D��������0���̏ꍇ
    ------------------------------------
    IF (in_rec_cnt = 0) THEN
    --
      lv_buf := SUBSTRB( xxccp_common_pkg.get_msg(gv_msg_kbn_cfr,     -- 'XXCFR'
                                                  cv_meg_cfr1_23)     -- �Ώۃf�[�^�Ȃ�
                                                  ,1
                                                  ,5000) ;
      --
      -- CSV�o�́i0�����b�Z�[�W�j
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT , lv_buf ) ;
      --
      -- �o�͕ϐ��N���A
      lv_buf := NULL ;
      --
    ------------------------------------
    -- 3�D�f�[�^�o��
    ------------------------------------
    ELSE
    --
      -- SELECT��
      lv_sql   := 'SELECT ' ;
      --
      -- �񍀖�
      <<i_loop>>
      FOR  i IN 1 .. ln_flv_cnt
      LOOP
        IF (i = 1) THEN  -- ��1
        --
          IF (tt_flv(i).attribute1 = 'Y') THEN  -- ���肠��
          --
            lv_sql := lv_sql||'''"''||col'||i||'||''"''' ;
            --
          ELSE                                   -- ����Ȃ�
          --
            lv_sql   := lv_sql||'col'||i ;
            --
          END IF ;
          --
        ELSE             -- ��2�ȍ~
        --
          IF (tt_flv(i).attribute1 = 'Y') THEN  -- ���肠��
          --
            lv_sql := lv_sql||'||'',"''||col'||i||'||''"''' ;
            --
          ELSE                                   -- ����Ȃ�
          --
            lv_sql := lv_sql||'||'',''||col'||i ;
            --
          END IF ;
          --
        END IF ;
        --
      END LOOP i_loop ;
      --
      -- FROM��
      lv_sql := lv_sql||' FROM xxcfr_csv_outs_temp ' ;
      --
      -- WHERE��F�v��ID
      lv_sql := lv_sql||' WHERE request_id = '||in_request_id ;
      --
      -- ORDER BY��
      lv_sql := lv_sql||' ORDER BY seq' ;
      --
      --
      --DBMS_OUTPUT.PUT_LINE(lv_sql) ;
      --
      -- ���ISQL�̃I�[�v���ƃt�F�b�`
      OPEN cur_sql FOR lv_sql ;
        LOOP
          FETCH  cur_sql INTO lv_buf ;
          EXIT WHEN cur_sql%NOTFOUND ;
          --
            -- 1�s����OUT�t�@�C���֏o��
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_buf) ;
            --
        END LOOP ;
        --
      CLOSE cur_sql ;
      --
    END IF ;
    --
    --
  EXCEPTION
  --
  --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      --
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END csv_out ;
  --
  /**********************************************************************************
   * Function Name    : get_base_target_tel_num
   * Description      : �������_�S���d�b�ԍ��擾�֐�
   ***********************************************************************************/
  FUNCTION get_base_target_tel_num(
    iv_bill_acct_code      IN  VARCHAR2       -- 1.������ڋq�R�[�h
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_base_target_tel_num'; -- PRG��
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_base_tel_num       hz_locations.address_lines_phonetic%TYPE := NULL; -- �������_�S���d�b�ԍ�
--
  BEGIN
--
    -- ====================================================
    -- �������_�S���d�b�ԍ��擾�֐��������W�b�N�̋L�q
    -- ===================================================
    -- �������_�S���d�b�ԍ����擾
    BEGIN
      SELECT base_hzlo.address_lines_phonetic  base_tel_num    --�d�b�ԍ�
      INTO   lv_base_tel_num
      FROM   hz_cust_accounts                  bill_hzca,      --�ڋq�}�X�^(������)
             xxcmm_cust_accounts               bill_hzad,      --�ڋq�ǉ����(������)
             hz_cust_accounts                  base_hzca,      --�ڋq�}�X�^(�������_)
-- Modify 2009.03.31 Ver1.1 Start
             hz_cust_acct_sites                base_hasa,      --�ڋq���ݒn�r���[(�������_)
--             hz_cust_acct_sites_all            base_hasa,      --�ڋq���ݒn(�������_)
-- Modify 2009.03.31 Ver1.1 End
             hz_locations                      base_hzlo,      --�ڋq���Ə�(�������_)
             hz_party_sites                    base_hzps       --�p�[�e�B�T�C�g(�������_)
      WHERE  bill_hzca.account_number = iv_bill_acct_code      --������ڋq�R�[�h
      AND    bill_hzca.cust_account_id = bill_hzad.customer_id    
      AND    base_hzca.account_number = bill_hzad.bill_base_code
      AND    base_hzca.cust_account_id = base_hasa.cust_account_id
      AND    base_hasa.party_site_id = base_hzps.party_site_id    
      AND    base_hzps.location_id = base_hzlo.location_id        
      AND    base_hzca.customer_class_code = '1'                    
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL ;
    END ;
    
    RETURN lv_base_tel_num;
    
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END get_base_target_tel_num;
--
  /**********************************************************************************
   * Function Name    : get_receive_updatable
   * Description      : ������� �ڋq�ύX�\����
   ***********************************************************************************/
  FUNCTION get_receive_updatable(
    in_cash_receipt_id IN NUMBER,
    iv_gl_date IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'xxcfr_common_pkg.get_receive_updatable'; -- PRG��
    cv_appl_short_name_ar      CONSTANT fnd_application.application_short_name%TYPE := 'AR'; -- AR�A�v���P�[�V�����Z�k��
    cv_prof_name_gl_bks_id     CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID'; -- �v���t�@�C������ID
    cv_date_format             CONSTANT VARCHAR2(100) := 'DD-MON-RRRR'; -- ������ ���t�t�H�[�}�b�g
    cv_return_value_y          CONSTANT VARCHAR2(1) := 'Y'; -- �߂�l'Y'
    cv_return_value_n          CONSTANT VARCHAR2(1) := 'N'; -- �߂�l'N'
    cv_receivable_status_unapp CONSTANT ar_receivable_applications_all.status%TYPE := 'UNAPP'; -- �������X�e�[�^�X
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_in_gl_date DATE;
    lv_closing_status gl_period_statuses.closing_status%TYPE;
    lv_return_value VARCHAR2(1);
    ln_receivable_app_cnt NUMBER;
    -- ===============================
    -- ���[�J���J�[�\��
    CURSOR cur_get_closing_status(
      id_gl_date IN DATE
    )
    IS
    SELECT gps.closing_status AS closing_status
    FROM fnd_application fap
        ,gl_period_statuses gps
    WHERE fap.application_short_name = cv_appl_short_name_ar
      AND gps.set_of_books_id = fnd_profile.value(cv_prof_name_gl_bks_id)
      AND ld_in_gl_date BETWEEN gps.start_date AND gps.end_date
      AND gps.adjustment_period_flag = 'N'
      AND fap.application_id = gps.application_id
    ;
--
  BEGIN
--
    ld_in_gl_date := TO_DATE(iv_gl_date,cv_date_format);
    OPEN cur_get_closing_status(ld_in_gl_date);
    FETCH cur_get_closing_status INTO lv_closing_status;
    IF iv_gl_date IS NULL THEN
      lv_return_value := cv_return_value_y;
    ELSIF cur_get_closing_status%NOTFOUND THEN
      lv_return_value := cv_return_value_y;
    ELSIF lv_closing_status = 'O' THEN
      lv_return_value := cv_return_value_y;
    ELSE 
      SELECT COUNT('X') AS cnt
      INTO ln_receivable_app_cnt
      FROM ar_receivable_applications_all araa
      WHERE araa.cash_receipt_id = in_cash_receipt_id
      AND araa.status = cv_receivable_status_unapp;
      IF ln_receivable_app_cnt = 0 THEN
        lv_return_value := cv_return_value_y;
      ELSE
        lv_return_value := cv_return_value_n;
      END IF;
    END IF;
    CLOSE cur_get_closing_status;
    RETURN lv_return_value;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END get_receive_updatable;
--
  /**********************************************************************************
   * Procedure Name    : awi_ship_code
   * Description      : ARWebInquiry�p �[�i��ڋq�R�[�h�l���X�g
   *                    ��xx03_glwi_lov_pkg.input_department�����p
   ***********************************************************************************/
   PROCEDURE awi_ship_code(
    p_sql_type         IN     VARCHAR2,
    p_sql              IN OUT VARCHAR2,
    p_list_filter_item IN     VARCHAR2,
    p_sort_item        IN     VARCHAR2,
    p_sort_method      IN     VARCHAR2,
    p_segment_id       IN     NUMBER,
    p_child_condition  IN     VARCHAR2,
    p_parent_condition IN     VARCHAR2 DEFAULT NULL)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    l_sql_rec                   xgv_common.sql_rtype;  -- SQL���ƃo�C���h�ϐ��i�[�p
--
  BEGIN
--
    --------------------------------------------------
    -- ���ISQL�̑g�ݗ��ĊJ�n
    --------------------------------------------------
-- �l���X�g���J���ۂɁA���������擾�B�����d���{�^������������ۂɒʂ郍�W�b�N�B
    IF  p_sql_type = 'COUNT'
    THEN
      l_sql_rec.text(1) := 'SELECT count(xtcv.name)';
      l_sql_rec.text(2) := 'FROM   xxcfr_awi_ship_code_v xtcv';
      l_sql_rec.text(3) := 'WHERE';
-- �l���X�g�̕\��\������ۂɃf�[�^���擾�B�����d���{�^������������ۂɒʂ郍�W�b�N�B
    ELSE
      l_sql_rec.text(1) := 'SELECT NULL,';
      l_sql_rec.text(2) := '       NULL,';
      l_sql_rec.text(3) := '       xtcv.name name,';
      l_sql_rec.text(4) := '       xtcv.description description';
      l_sql_rec.text(5) := 'FROM   xxcfr_awi_ship_code_v xtcv';
      l_sql_rec.text(6) := 'WHERE';
    END IF;
    -- �l���o�����Ɋ��Ɍ����������w�肳��Ă���ꍇ
    -- ����������WHERE��̏����ɕύX
    IF  p_child_condition IS NOT NULL
    THEN
-- �l���X�g���̌��� ��������=�l�̂Ƃ�
      IF  p_list_filter_item = 'VALUE'
      THEN
        xgv_common.get_where_clause(
          l_sql_rec, 'xtcv', 'name', p_child_condition);
-- �l���X�g���̌��� ��������=�E�v�̂Ƃ�
      ELSE
        xgv_common.set_bind_value(l_sql_rec, upper(p_child_condition));
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) :=
          'upper(xtcv.description) like :' || l_sql_rec.ph_name(l_sql_rec.num_ph);
      END IF;
-- �l���o�����Ɍ����������w�肳��Ă��Ȃ��ꍇ��WHERE�傪�Ȃ��̂�1=1��ǉ��B
    ELSE
      -- �Z�L�����e�B���[���p�ɕK���������������SQL�ɒǉ�
      l_sql_rec.text(l_sql_rec.text.COUNT + 1) := '       1 = 1';
    END IF;
    -- ���ISQL��ORDER BY��̒ǉ�
    IF  p_sql_type = 'LIST'
    THEN
-- �l���X�g��\������ۂɃ\�[�g����ǉ��B
      IF  p_sort_item = 'VALUE'
      THEN
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY xtcv.name ' || p_sort_method;
-- ���W�b�N�Ƃ��Ēʂ��Ă��Ȃ��͗l�B�O�̂��ߎc���Ă����B
      ELSE
        l_sql_rec.text(l_sql_rec.text.COUNT + 1) := 'ORDER BY xtcv.description ' || p_sort_method;
      END IF;
    END IF;
    --------------------------------------------------
    -- ���ISQL�̑g�ݗ��ďI��
    --------------------------------------------------
    -- ���ISQL�̃f�o�b�O�p�o�́iHTML�R�����g�Ƃ��ďo�́j
    xgv_common.show_sql_statement(l_sql_rec);
    -- xgv_common.sql_rtype�^�Ɋi�[����SQL�����A�ʏ�̕�����^��SQL���ɕϊ�
    xgv_common.get_plain_sql_statement(p_sql, l_sql_rec);
  END awi_ship_code;
--
END xxcfr_common_pkg;
/
